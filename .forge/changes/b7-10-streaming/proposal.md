# Proposal: b7-10-streaming

<!-- Created: 2026-06-22 -->
<!-- Schema: default -->
<!-- Audit: B.7.10 (docs/new-archetypes-plan.md §6.2 — Qwik streaming patterns: SSE, WebTransport, cancel-on-unmount, retry exponentiel) -->
<!-- Input: b7-2-scaffolder (the unary RAG surface this brick extends) + b8-9-qwik-web-public (Qwik City + Connect-ES v2 precedent) -->

## Problem

The `ai-native-rag` archetype scaffolds a **non-streaming** RAG query surface.
B.7.2 (`b7-2-scaffolder`, archived 2026-06-21) shipped:

- `shared/protos/v1/rag/rag.proto.tmpl` — `RagService.Query(QueryRequest)
  returns (QueryResponse)`, a single **unary** RPC; its doc-comment explicitly
  says *"A non-streaming request/response baseline — streaming (SSE /
  WebTransport) ships in B.7.10."*
- `frontend/web-public/src/routes/index.tsx.tmpl` — a Qwik landing route that
  does one `await query(...)` and renders the whole answer at once; its header
  says *"SSE / WebTransport ships in b7-10-streaming (ADR-B7-2-006)."*
- `frontend/web-public/src/lib/connect-client.ts.tmpl` — a Connect-ES v2 client
  with one unary `query()`; header: *"Streaming (SSE / WebTransport) is OUT of
  scope here (→ b7-10-streaming)."*
- `backend/llm_gateway/src/handler.rs.tmpl` — `process_query(...) ->
  GatewayAnswer` returns a fully-materialised answer (`Generated(String)` or
  `Fallback(FallbackAnswer)`); the upstream port `Upstream::generate(...) ->
  Result<String, UpstreamError>` returns a *whole* completion.

So an adopter scaffolding `ai-native-rag` gets a RAG UI that blocks until the
full LLM completion is ready — no token-by-token rendering, no early
time-to-first-token, no cancellation. For an LLM/RAG product this is the wrong
default UX: generation is inherently incremental and latency-bound, and the
public web surface is exactly where progressive rendering matters most (SEO/LCP
rationale already drove the Qwik choice — `web-frontend.yaml`).

The full-stack flagship records the same deferral
(`full-stack-monorepo/2.0.0/frontend/web-public/README.md.tmpl`:
*"Streaming patterns (SSE / WebTransport / cancel-on-unmount) → B.7.10"*), and
`mcp-servers.md` already documents the SSE side of rmcp's `StreamableHttpService`
— but no archetype template renders a streaming RAG answer path today.

This brick (#7 of the 9-brick B.7 chain; parallelisable after the hard
`1→2→3` dependency) ships that path: a **server-streaming** RAG RPC on the
backend, a **token/event stream** through the LLM gateway, and a **Qwik
streaming UI** (SSE-class transport via Connect-ES server-streaming, with
WebTransport recorded as the forward alternative), all with the constitutionally
mandatory backpressure / cancellation / fallback coverage (Article XI.5).

**Ground truth (re-read 2026-06-22, Article III.4):**

- The unary surface above **exists and is GREEN** (b7-2 L1 7 / L2 3, rendered
  `cargo test` 35/0). b7-10 is **additive** to it: it adds a *second*
  (streaming) RPC + a streaming UI mode; it MUST NOT break the unary baseline or
  the `b7-2.test.sh` assertions.
- Connect-ES v2 supports server-streaming consumed in the browser via
  `for await (const res of client.method(...))` over
  `createConnectTransport` / `createGrpcWebTransport` (`@connectrpc/connect-web`,
  Context7 `/connectrpc/connect-es` confirmed 2026-06-22). The Connect protocol's
  HTTP framing is the SSE-class wire; **Connect-ES does not transport over
  WebTransport** (it is fetch/HTTP-based) — WebTransport is therefore a *forward
  native-browser* path, not a Connect-ES drop-in (see open question).
- Backend Connect server-streaming on the Rust side is **not yet wired**: b7-2
  left `buf generate` + the Connect handler registration as a documented TODO for
  `b7-6` (the Qwik `rag_pb` import is the one expected un-generated error). b7-10
  therefore scaffolds the *streaming method signature, port, and pipeline* and
  asserts them via the hermetic/render harness; live end-to-end codegen wiring
  stays gated with the rest of the archetype's promotion (`b7-6`).
- Pins: **no new runtime pin is invented at planning.** Connect-ES (`^2.0.0`),
  Qwik (`^1.20.0`), Vite (`7.3.5`) are already owned by `transport.yaml` /
  `web-frontend.yaml`; the backend streaming crates ride the existing
  `backend/Cargo.toml.tmpl` ledger (`async-openai`, `tokio`, `futures`/`tokio-stream`
  for `Stream`). Any *new* crate (e.g. `tokio-stream`, `async-stream`) is a
  **verify-then-pin LIVE candidate** recorded here, pinned only at IMPLEMENT in
  the consuming `Cargo.toml.tmpl` (Article III.4 / ADR-B7-2-003).

## Solution

Extend the `ai-native-rag/1.0.0` template tree (and only it) with a streaming RAG
answer path, conforming to the B.7.3 pattern standards and mirroring the
established b7-2 module shapes. Concretely:

1. **Proto** (`shared/protos/v1/rag/rag.proto.tmpl`): add a **server-streaming**
   RPC `QueryStream(QueryRequest) returns (stream QueryChunk)` alongside the
   existing unary `Query` (which stays — it is the non-streaming fallback path and
   keeps the b7-2 contract). `QueryChunk` carries an incremental token delta, an
   optional `sources` frame (emitted once), a terminal `done` marker, and a
   `fallback_used` flag so XI.5 is observable mid-stream.
2. **Backend streaming pipeline** (`backend/llm_gateway/`, `backend/rag/`,
   Vulcan/Rust): a streaming gateway entrypoint (`process_query_stream(...) ->
   impl Stream<Item = QueryChunk>` or a `mpsc`/`tokio-stream` channel) and a
   streaming `Upstream` port (`generate_stream(...) -> Stream<Result<Token, _>>`)
   so the XI.5 fallback branch is unit-testable with a failing upstream. Adds:
   - **Backpressure** — bounded channel; the producer respects consumer demand.
   - **Cancellation** — client disconnect / `CancellationToken` aborts upstream +
     emits a terminal audit record.
   - **Fallback (XI.5)** — if the upstream errors *before or during* the stream,
     the stream degrades to the non-AI fallback (ranked sources) and sets
     `fallback_used`; if it errors mid-stream after partial tokens, a defined
     mid-stream-degradation policy applies (terminate-with-fallback-marker).
   - **Prompt-audit (IX.6)** — the audit record is emitted at stream *close* with
     final token counts + fallback flag; `redact_pii` still applies (XI.6).
3. **Qwik streaming UI** (`frontend/web-public/`, Hera): a streaming render mode —
   `connect-client.ts` gains a `queryStream(question)` returning an async iterable
   consumed by the route with `for await`, appending token deltas to a Qwik signal
   (progressive render), a Stop/cancel control wired to the stream's
   `AbortController` (**cancel-on-unmount** via Qwik cleanup), and **exponential
   retry** on transient stream errors before falling back to the unary `query()`
   (the SSE-class → unary graceful degradation = the UI-layer XI.5 fallback).
4. **WebTransport (forward alternative)**: documented and scaffolded as an
   *opt-in, behind a clearly-marked TODO/feature note* — NOT wired as the default,
   because Connect-ES does not speak WebTransport. The default streaming transport
   is Connect server-streaming (SSE-class). The README documents the upgrade path.
5. **Harness** `.forge/scripts/tests/b7-10.test.sh` (mirror `b7-2.test.sh`'s
   grep/fixture style): L1 structural + standards-conformance greps (streaming RPC
   present in proto, `queryStream`/`for await`/cancel/retry markers in Qwik,
   streaming gateway + backpressure + cancel + mid-stream-fallback markers in
   Rust, unary baseline still present), L2 toolchain-gated render-clean + Qwik
   typecheck / `cargo check` on the rendered tree. Registered in
   `.github/workflows/forge-ci.yml` (`--level 1`, after `b7-2.test.sh`).

## Scope In

- `shared/protos/v1/rag/rag.proto.tmpl` — add server-streaming `QueryStream` +
  `QueryChunk` (unary `Query` retained).
- `backend/llm_gateway/` + `backend/rag/` — streaming gateway entrypoint +
  streaming `Upstream` port + backpressure/cancellation/mid-stream-fallback +
  stream-close prompt-audit; `#[cfg(test)]` scaffolding (TDD-ready, NFR).
- `frontend/web-public/` — `queryStream` client + progressive-render route +
  Stop/cancel + cancel-on-unmount + exponential-retry → unary degradation.
- WebTransport recorded as a documented forward alternative (README + a marked,
  non-default scaffold note), not the default path.
- `scaffold-plan.yaml` — register any new `.tmpl` files (no orphan/dangling).
- `.forge/scripts/tests/b7-10.test.sh` (L1 + L2) + CI registration.
- Verify-then-pin LIVE of any *new* streaming crate, pinned only in the consuming
  `Cargo.toml.tmpl` (recorded as candidates here).

## Scope Out (Explicit Exclusions)

- **Promotion** candidate → stable / scaffoldable:true — stays gated on a green
  `b7-6-harness` (ADR-B7-1-002, b8-3b invariant). This brick keeps the schema
  `candidate`; the CLI keeps refusing `forge init --archetype ai-native-rag`
  (exit 3). Validated via direct overlay/render fixture, NOT the CLI gate.
- **Live end-to-end `buf generate` + Connect handler registration + `cargo
  fetch`** — already a documented `b7-6` TODO (b7-2); b7-10 scaffolds the
  streaming *shape*, the comprehensive live wiring + ≥35-test promotion suite stay
  in `b7-6`.
- **MCP streaming** — rmcp's `StreamableHttpService` SSE is already documented in
  `mcp-servers.md` + scaffolded by b7-2 (`mcp/transport/http.rs`); b7-10 does NOT
  re-touch the MCP transport. (Cross-referenced only.)
- **AI-Act / DORA streaming-disclosure artefacts** → `b7-5-ai-act` (#6).
- **Runtime Janus AI refusal rules (J.8.c)** → `b7-9-janus-ai` (#5).
- **`examples/forge-rag-example/` streaming demo** → `b7-7-example` (#8) — that
  brick *consumes* the streaming surface b7-10 ships (see collision note).
- No edit to the constitution, `archetype.schema.json`, the B.7.3 standards
  (pin-free invariant), `web-frontend.yaml`/`transport.yaml` pins, or other
  archetypes' templates.

## Impact

- **Users affected**: adopters of `ai-native-rag` get a streaming RAG UX by
  default once the archetype is promoted (`b7-6`); no impact on existing
  archetypes or the unary baseline. No CLI behaviour change (still refuses exit 3
  while candidate).
- **Technical impact**: additive edits to the `ai-native-rag/1.0.0` template tree
  (proto + gateway + rag + Qwik), `scaffold-plan.yaml`, a new harness, and CI
  matrix. The unary path is preserved as the documented XI.5/degradation fallback.
- **Dependencies**: B.7.1 (schema), B.7.2 (the surface extended), B.7.3
  (standards) — all archived. Reuses the B.8 substrate by reference (Envoy/Connect
  transport, Zitadel, OTel) exactly as b7-2 does.

## Constitution Compliance (v2.0.0)

- **Article I (TDD)**: RED→GREEN→REFACTOR on every streaming module; modules ship
  `#[cfg(test)]` scaffolding (streaming fallback branch tested with a failing
  upstream), not bare stubs.
- **Article II (BDD)**: the user-facing capability (progressive streaming render +
  cancel + degrade-to-fallback) gets Given/When/Then scenarios.
- **Article III (Specs Before Code)**: proposal → specs → design → tasks before any
  template is touched. **III.4 anti-hallucination**: streaming protocol specifics
  are grounded in Context7-confirmed Connect-ES server-streaming; WebTransport's
  non-applicability to Connect-ES is recorded as an open question, not guessed; no
  new pin is committed at planning.
- **Article VII (Rust)**: streaming follows `tokio` async + `Stream`; no second
  runtime; fallible streaming functions return `Result`/typed stream errors
  (no `unwrap` in production paths).
- **Article VIII**: Envoy + Connect transport consumed as-is (Connect
  server-streaming rides the existing ingress; no second gateway).
- **Article IX.6 (prompt audit)**: streaming records emit at close with final
  token counts + fallback flag. **Article XI.4 (event-driven frontend integration)**:
  the Qwik UI subscribes to a stream of answer events — no blocking synchronous AI
  call in the UI thread. **Article XI.5 (mandatory fallback)**: every streaming
  path has a tested non-AI degradation (mid-stream + pre-stream); the SSE→unary
  fallback is the UI-layer fallback.

## Open Questions (to resolve at specify/design)

- **Q-1** — WebTransport: default-off forward alternative (Connect-ES is
  fetch/HTTP, not WebTransport) — confirm "documented + marked scaffold note, NOT
  wired" is the right depth for this brick, vs a fuller native-WebTransport stub.
  Recorded in `open-questions.md` as `[NEEDS CLARIFICATION]`.
- **Q-2** — Mid-stream upstream failure (after N tokens already streamed): the
  XI.5 policy — terminate-with-fallback-marker vs restart-as-fallback vs
  keep-partial+append-degradation-notice. Affects `QueryChunk` shape + audit.
- **Q-3** — Streaming transport seam on the backend: emit `tokio_stream::Stream`
  vs a `tokio::sync::mpsc` channel behind the Connect server-streaming handler;
  whether a *new* crate (`tokio-stream` / `async-stream`) is needed → verify-then-pin.
- **Q-4** — Does the streaming proto change require a `buf breaking` exception
  (adding an RPC is backward-compatible, but confirm against the b7-2 proto's
  `buf.yaml` lint/breaking config).
- **Q-5** — Shared-file collision with `b7-7-example` (which demos streaming) and
  any sibling editing `rag.proto` / Qwik `index.tsx` — see Finish note.

---

**Gate**: Proposal created at `.forge/changes/b7-10-streaming/proposal.md`. Review and
confirm before proceeding to → `/forge:specify b7-10-streaming`.
