# Specs: b7-10-streaming

<!-- Specified: 2026-06-22 -->
<!-- Namespace: FR-B7-10-* / NFR-B7-10-* / ADR-B7-10-* -->
<!-- Source: proposal.md + b7-2-scaffolder templates (the unary surface extended) -->
<!--         + global/{rag-patterns,llm-gateway,mcp-servers}.md (B.7.3 streaming semantics) -->
<!--         + web-frontend.yaml / transport.yaml (Qwik + Connect-ES v2 pins, reference-only) -->

**Constitution** : v2.0.0 (no bump — additive; consumes §VIII.1 Envoy + §VIII.2
Temporal + Article XI AI-First + IX.6 + XI.4/XI.5 as ratified).

**Format** : ADDED requirements only (a new streaming RPC + streaming modules +
streaming UI, layered on the b7-2 unary surface). No existing requirement is
MODIFIED or REMOVED. On archive these requirements append to
`.forge/specs/ai-native-rag.md` (B.7 spec-accumulation convention).

**Ground truth (re-read 2026-06-22, Article III.4)**:
- The unary RAG surface (b7-2) exists and is GREEN: `rag.proto` `Query`, Qwik
  `index.tsx`/`connect-client.ts` unary `query()`, `llm_gateway` `process_query`,
  `b7-2.test.sh` L1 7 / L2 3. b7-10 is **purely additive** to it.
- `candidate ⇒ scaffoldable:false` is invariant (b8-3b
  `check_versioned_schema_siblings`). Promotion stays in `b7-6`; the CLI keeps
  refusing `forge init --archetype ai-native-rag` (exit 3). The streaming surface
  is validated by a fixture that renders the templates directly (overlay.sh), NOT
  through the CLI scaffoldable gate.
- Connect-ES v2 server-streaming is consumed in-browser via `for await (… of
  client.method(…))` over `@connectrpc/connect-web` (Context7 confirmed). The
  Connect/HTTP framing is the SSE-class wire. Connect-ES does NOT speak
  WebTransport → WebTransport is a documented forward alternative (Q-1).
- `buf generate` + Connect handler registration + `cargo fetch` remain a `b7-6`
  TODO (b7-2 deferral). b7-10 scaffolds the streaming *shape* + asserts it via the
  hermetic/render harness; the one expected un-generated `rag_pb` import error is
  inherited from b7-2, unchanged.

---

## Resolved scope decisions (from proposal open questions)

- **Q-1 (WebTransport depth)** → carried to `design.md` (ADR-B7-10-005 proposes
  *documented forward alternative, NOT default-wired*; recorded `[NEEDS
  CLARIFICATION]` in `open-questions.md` for maintainer confirmation).
- **Q-2 (mid-stream failure policy)** → carried to `design.md`
  (ADR-B7-10-003 proposes terminate-with-fallback-marker).
- **Q-3 (backend stream seam)** + **Q-4 (`buf breaking`)** → `design.md`
  (do not block specs; the FRs are testable without resolving the seam choice).

---

## ADDED Requirements

### Streaming proto contract

- **FR-B7-10-001** — `shared/protos/v1/rag/rag.proto.tmpl` MUST add a
  **server-streaming** RPC `rpc QueryStream(QueryRequest) returns (stream
  QueryChunk);` alongside the existing unary `Query`. The unary `Query` RPC MUST
  be retained unchanged (it is the documented non-streaming fallback path and
  preserves the b7-2 contract).
- **FR-B7-10-002** — A `QueryChunk` message MUST be defined carrying, at minimum:
  an incremental answer delta (e.g. `string token_delta`), an optional
  one-shot `repeated SourceChunk sources` frame, a terminal `bool done` marker,
  and a `bool fallback_used` flag so the Article XI.5 non-AI fallback is
  observable within the stream. `SourceChunk` MUST be reused from the b7-2 proto
  (no duplicate type).
- **FR-B7-10-003** — The proto change MUST remain backward-compatible (adding an
  RPC + message): `buf lint` MUST pass and `buf breaking` MUST NOT report a
  breaking change against the b7-2 proto baseline (verified at render/L2 when the
  toolchain is present; the seam is asserted structurally at L1).

### Backend streaming pipeline (`FR-BE-`, Vulcan/Rust)

- **FR-B7-10-010** — A **streaming gateway entrypoint** MUST be scaffolded in
  `backend/llm_gateway/` (e.g. `process_query_stream(...)`) that yields
  incremental answer chunks rather than a single materialised answer. It MUST
  reuse the existing `decide_route` guard composition (kill-switch / tier-refusal /
  budget) so a refused route degrades to the streamed fallback before any upstream
  call. The unary `process_query` MUST remain present and unchanged
  (NFR-B7-10-002).
- **FR-B7-10-011** — A **streaming `Upstream` port** MUST be scaffolded (e.g.
  `generate_stream(...)` yielding `Result<token, UpstreamError>` items), abstracted
  as a trait so a failing / mid-stream-failing upstream can be injected to exercise
  the Article XI.5 fallback branch in unit tests (mirrors b7-2's `Upstream`
  trait + `FailingUpstream` pattern).
- **FR-B7-10-012** — **Backpressure**: the streaming path MUST use a bounded
  buffering primitive (bounded channel or demand-respecting `Stream`) so a slow
  consumer cannot force unbounded producer memory growth. The bound MUST be a
  named, documented constant (not a magic literal).
- **FR-B7-10-013** — **Cancellation**: the streaming path MUST support cooperative
  cancellation (client disconnect / a `CancellationToken`-equivalent) that aborts
  the upstream call and stops producing chunks. A cancelled stream MUST still emit
  the close-time prompt-audit record (FR-B7-10-015) marking the cancellation.
- **FR-B7-10-014** — **Mandatory fallback (Article XI.5)**: if the upstream is
  unavailable/errors **before** the first token, the stream MUST degrade to the
  non-AI fallback (ranked `sources`, `fallback_used=true`, `done=true`) exactly as
  the unary path does. If the upstream errors **mid-stream** (after partial
  tokens), a defined degradation policy MUST apply (default: terminate the stream
  with a final fallback-marked chunk — ADR-B7-10-003). Both branches MUST be unit
  tested with the upstream mocked to fail (pre-stream and mid-stream).
- **FR-B7-10-015** — **Prompt audit (Article IX.6)**: the streaming path MUST emit
  a prompt-audit record at stream close carrying final prompt/completion token
  counts, the `fallback_invoked` flag, and a cancellation flag. PII redaction
  (`redact_pii`, Article XI.6) MUST apply to any prompt text on the audit/log path,
  exactly as the unary path enforces.

### Frontend streaming UI (`FR-FE-`, Hera)

- **FR-B7-10-020** — `frontend/web-public/src/lib/connect-client.ts.tmpl` MUST add
  a `queryStream(question, topK?)` function returning an **async iterable** of
  answer deltas, wired to the Connect-ES v2 server-streaming client
  (`for await (const chunk of ragClient.queryStream(...))`) over the existing
  `@connectrpc/connect-web` transport (pins owned by `transport.yaml`, NOT
  re-pinned). The existing unary `query()` MUST be retained.
- **FR-B7-10-021** — `frontend/web-public/src/routes/index.tsx.tmpl` MUST render
  the streamed answer **progressively** (append `token_delta` to a Qwik signal as
  chunks arrive — Article XI.4 event-driven UI, no blocking synchronous AI call),
  surfacing the existing `fallbackUsed` indicator when the stream reports the
  XI.5 fallback.
- **FR-B7-10-022** — The UI MUST provide a **Stop/cancel** control that aborts the
  in-flight stream (via an `AbortController`/`AbortSignal` threaded into the
  Connect call), and MUST cancel the stream **on unmount** (Qwik cleanup —
  `cancel-on-unmount`, per the audit item). No orphaned stream may survive
  navigation away from the route.
- **FR-B7-10-023** — The UI MUST implement **exponential-backoff retry** on
  transient stream errors (bounded attempts, documented base/max), and on
  exhausting retries MUST **degrade to the unary `query()`** path (the UI-layer
  Article XI.5 fallback: SSE-class → unary → non-AI fallback answer). The retry
  policy MUST be a named, documented helper (not inline magic numbers).

### WebTransport (forward alternative)

- **FR-B7-10-030** — WebTransport MUST be documented as the **forward
  alternative** transport in the `frontend/web-public/README.md.tmpl` (and a
  clearly-marked, **non-default** scaffold note), recording that Connect-ES does
  not transport over WebTransport and that the default streaming transport is
  Connect server-streaming (SSE-class). WebTransport MUST NOT be wired as the
  default path in this brick (ADR-B7-10-005; depth pending Q-1).

### Harness

- **FR-B7-10-040** — A dedicated harness `.forge/scripts/tests/b7-10.test.sh` MUST
  be added (mirroring `b7-2.test.sh`'s grep/fixture style) and registered in
  `.github/workflows/forge-ci.yml` after `b7-2.test.sh`, with:
  - **L1** (hermetic, grep/structure): streaming RPC + `QueryChunk` present in the
    proto with unary `Query` retained (FR-B7-10-001/002); backend streaming
    markers — streaming entrypoint, bounded-channel/backpressure constant,
    cancellation, mid-stream-fallback, stream-close audit (FR-B7-10-010..015);
    Qwik markers — `queryStream` + `for await` + Stop/cancel + cancel-on-unmount +
    exponential-retry + unary-degradation (FR-B7-10-020..023); WebTransport
    documented-not-default (FR-B7-10-030); the b7-2 unary baseline still present
    (NFR-B7-10-002); pins still only in `Cargo.toml.tmpl` (no inline pin in the
    streaming templates).
  - **L2** (toolchain-gated, skip when absent): render the scaffold-plan via
    `overlay.sh` → no `.tmpl`/no `{{placeholder}}` survive; `buf lint` +
    `buf breaking` clean on the rendered proto (if `buf` present); Qwik
    `tsc --noEmit` clean except the one inherited un-generated `rag_pb` import
    (b7-2 parity); `cargo check` on the rendered backend (if `cargo` present).

## Non-Functional

- **NFR-B7-10-001** — Additive: no edit to the constitution,
  `archetype.schema.json`, `ai-native-rag/1.0.0.yaml` (stays
  candidate/scaffoldable:false), the B.7.3 standards (stay pin-free),
  `web-frontend.yaml`/`transport.yaml` pins, or other archetypes' templates.
  Existing-file edits confined to: the `ai-native-rag/1.0.0` template tree
  (proto + llm_gateway + rag + frontend/web-public), `scaffold-plan.yaml`, the new
  harness, and the CI matrix.
- **NFR-B7-10-002** — No regression: the b7-2 unary surface MUST stay intact —
  `b7-2.test.sh` (L1 7 / L2 3), `b7-1.test.sh`, `b7-2a.test.sh`, `b7-3.test.sh`,
  `verify.sh`, `constitution-linter.sh`, `validate-foundations.sh` all stay GREEN.
- **NFR-B7-10-003** — Rendered streaming modules MUST ship `#[cfg(test)]`
  scaffolding (TDD-ready per Article I + `coverage_threshold: 80` intent): the
  streaming fallback branch (pre-stream + mid-stream) MUST be tested with a failing
  upstream, not left as a bare stub.
- **NFR-B7-10-004** — Determinism: render of a fixed plan into a fixed target is
  byte-stable across runs (no timestamps/uuids beyond documented placeholders) —
  consistent with b7-2 NFR-B7-2-004.
- **NFR-B7-10-005** — Pin discipline (Article III.4 / ADR-B7-2-003): any new
  streaming crate is verify-then-pinned LIVE and pinned ONLY in the consuming
  `backend/Cargo.toml.tmpl`; no pin appears in any `global/*.md` standard or in the
  frontend templates (Connect-ES/Qwik/Vite pins stay owned by
  `transport.yaml`/`web-frontend.yaml`).

## BDD Acceptance Criteria

```gherkin
Feature: ai-native-rag streaming RAG answer (candidate, pre-promotion)

  Scenario: the proto exposes a server-streaming RPC alongside the unary one
    Given the ai-native-rag/1.0.0 shared/protos rag.proto
    When the proto is inspected
    Then a server-streaming QueryStream(QueryRequest) returns (stream QueryChunk) exists
    And the unary Query RPC is still present (non-streaming fallback)
    And buf lint passes and buf breaking reports no breaking change

  Scenario: the answer renders progressively in the Qwik UI
    Given a rendered ai-native-rag web-public surface
    When the user submits a question and the backend streams answer chunks
    Then token deltas append to the answer area as they arrive (no full-response block)
    And the Stop control cancels the in-flight stream
    And navigating away cancels the stream on unmount

  Scenario: the stream degrades to the non-AI fallback when the AI is unavailable
    Given the scaffolded streaming gateway
    When the upstream LLM is unavailable before the first token
    Then the stream emits a fallback-marked terminal chunk (Article XI.5)
    And the prompt-audit record at stream close marks fallback_invoked

  Scenario: the UI degrades from streaming to unary on repeated stream errors
    Given the streaming UI with exponential-backoff retry
    When transient stream errors exhaust the bounded retry attempts
    Then the UI falls back to the unary query() path (UI-layer XI.5 fallback)

  Scenario: the CLI still refuses init for the candidate archetype
    Given the schema is stage:candidate / scaffoldable:false
    When a user runs forge init --archetype ai-native-rag
    Then the CLI refuses with exit 3 and writes nothing
```

## ADRs (proposed — to ratify at design)

- **ADR-B7-10-001** — **Add a server-streaming RPC; keep the unary RPC.**
  `QueryStream` (server-streaming) is added; `Query` (unary) is retained as the
  documented non-streaming fallback. Rationale: additive + backward-compatible
  (no `buf breaking`), and the unary path is the UI-layer XI.5 degradation target.
- **ADR-B7-10-002** — **Default streaming transport = Connect server-streaming
  (SSE-class), not WebTransport.** Connect-ES v2 supports server-streaming over
  `@connectrpc/connect-web` (Context7-confirmed) and reuses the existing transport
  + ingress; WebTransport is not a Connect-ES transport. (Ties to ADR-B7-10-005.)
- **ADR-B7-10-003** — **Mid-stream failure policy = terminate-with-fallback-marker.**
  On upstream error after partial tokens, emit a final `fallback_used=true`,
  `done=true` chunk and a fallback-marked audit record (proposed; Q-2 — maintainer
  confirm). Pre-stream failure degrades exactly as the unary path.
- **ADR-B7-10-004** — **Streaming pins live only in `Cargo.toml.tmpl`; frontend
  pins stay owned by `transport.yaml`/`web-frontend.yaml`.** Any new backend
  streaming crate (e.g. `tokio-stream`) is verify-then-pinned LIVE at IMPLEMENT
  (b7-2 ADR-B7-2-003 precedent); standards stay pin-free.
- **ADR-B7-10-005** — **WebTransport = documented forward alternative, not
  default-wired** in this brick (depth pending Q-1). Recorded as a README + marked
  non-default scaffold note; a full native-WebTransport channel, if ever wanted, is
  a separate change.

## Open Questions (for design)

- **Q-1** — WebTransport depth (documented-only vs native stub) — `[NEEDS
  CLARIFICATION]`, see `open-questions.md`.
- **Q-2** — Mid-stream failure policy (ADR-B7-10-003 default) — maintainer confirm.
- **Q-3** — Backend stream seam (`tokio_stream::Stream` vs `mpsc` channel) +
  whether a new crate is needed → verify-then-pin at IMPLEMENT.
- **Q-4** — `buf.yaml` breaking-config: confirm adding `QueryStream` is clean
  against the b7-2 proto baseline.

## Anti-Hallucination Pass

- Connect-ES v2 server-streaming consumption (`for await`) is **Context7-confirmed**
  (`/connectrpc/connect-es`, 2026-06-22); WebTransport's non-applicability to
  Connect-ES is stated as fact and its scaffold depth deferred as `[NEEDS
  CLARIFICATION]`, not guessed.
- **No new version pin is asserted** at planning. Existing pins
  (Connect-ES ^2.0.0 / Qwik ^1.20.0 / Vite 7.3.5 / the b7-2 Cargo ledger) are
  reused by reference; any new streaming crate is a verify-then-pin LIVE candidate
  recorded in `design.md`, pinned at IMPLEMENT only.
- The streaming surface is layered on the **real** b7-2 templates (proto/Qwik/
  gateway) re-read 2026-06-22; no fabricated symbol or path.
- `[NEEDS CLARIFICATION]`: Q-1 (WebTransport depth) — non-blocking for specs (the
  FRs hold regardless of the answer).

---

**Gate**: Specs written. Review `specs.md`. Next: `/forge:design b7-10-streaming`.
