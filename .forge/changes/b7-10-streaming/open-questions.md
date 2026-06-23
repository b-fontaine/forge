# Open Questions: b7-10-streaming

<!-- Anti-hallucination ledger (Constitution Article III.4). Items here are NOT -->
<!-- guessed in the spec/design; they are surfaced for maintainer resolution. -->

## Resolved at implement (2026-06-23)

### Q-1 — WebTransport depth in this brick — RESOLVED: option (a) documented-only

**Decision (maintainer/orchestrator, 2026-06-23): option (a) — documented forward
alternative with a clearly-marked non-default scaffold note (ADR-B7-10-005).** A
native WebTransport channel (option b) is NOT built in this brick; if ever wanted
it is a separate follow-up change. Original question was:
> For B.7.10, is WebTransport to be (a) documented-only as a forward alternative
> with a clearly-marked non-default scaffold note — the proposed default,
> ADR-B7-10-005 — or (b) scaffolded as a real, opt-in native-browser WebTransport
> channel parallel to Connect server-streaming?

- **Why it is open**: Connect-ES v2 is fetch/HTTP-based and **does not transport
  over WebTransport** (Context7 `/connectrpc/connect-es`, 2026-06-22). So the
  default streaming path is Connect server-streaming (SSE-class, consumed via
  `for await`). A native WebTransport channel would be a *separate, non-Connect*
  client + a separate backend endpoint — a materially larger surface than the
  audit item ("Templates Qwik streaming patterns: SSE, WebTransport,
  cancel-on-unmount, retry exponentiel", `M` effort) implies.
- **Recommendation**: (a) documented forward alternative. Rationale: keeps the
  brick `M`-sized and honest (no half-built second transport), matches the
  flagship README deferral note, and leaves a full WebTransport channel as a clean
  future change. The audit's "WebTransport" is satisfied as a documented pattern +
  upgrade path.
- **Impact if (b)**: adds a native `WebTransport` client in Qwik + a backend
  WebTransport (HTTP/3) endpoint outside Connect → new infra/transport surface,
  likely a `buf`-independent path, and probably its own pin(s) — would warrant
  splitting into a follow-up brick.

## Carried to design (NOT blocking — proposed answers ratified, maintainer may revise)

### Q-2 — Mid-stream upstream-failure policy (XI.5)
Proposed (ADR-B7-10-003): **terminate-with-fallback-marker** — keep partial tokens
already streamed, emit a final `fallback_used=true`, `done=true` chunk + a
fallback-marked close audit. Alternatives: restart-as-fallback (discard partial),
or keep-partial+append-degradation-notice. Affects `QueryChunk` semantics + the
audit record. Maintainer confirm.

### Q-3 — Backend streaming seam + new crate
`tokio_stream::Stream` returned directly vs a `tokio::sync::mpsc` bounded channel
behind the Connect server-streaming handler. Determines whether a *new* crate
(`tokio-stream` / `async-stream`) is needed beyond the b7-2 ledger
(`tokio` + `async-openai` streaming API + `futures`). **Verify-then-pin LIVE at
IMPLEMENT** (`cargo add --dry-run`); pin ONLY in `Cargo.toml.tmpl` if required
(ADR-B7-10-004). No pin asserted at planning.

### Q-4 — `buf breaking` config
Confirm that adding `QueryStream` + `QueryChunk` is non-breaking against the b7-2
`rag.proto` baseline under the archetype's `buf.yaml` breaking rules (expected: yes
— adding an RPC/message is backward-compatible). Verified at L2 render when `buf` is
present (FR-B7-10-003).

## Cross-brick collision risk (informational — for the orchestrator)

### Q-5 — Shared-file overlap with sibling B.7 bricks
b7-10 edits, in the `ai-native-rag/1.0.0` tree:
`shared/protos/v1/rag/rag.proto.tmpl`,
`backend/llm_gateway/src/{handler,lib,fallback,audit}.rs.tmpl`,
`backend/rag/src/{lib,retrieval,worker}.rs.tmpl`,
`frontend/web-public/src/lib/connect-client.ts.tmpl`,
`frontend/web-public/src/routes/index.tsx.tmpl`,
`frontend/web-public/README.md.tmpl`,
`.forge/templates/archetypes/ai-native-rag/scaffold-plan.yaml`,
plus net-new `.forge/scripts/tests/b7-10.test.sh` and `forge-ci.yml`.

- **Highest collision risk: `b7-7-example` (#8)** — its streaming demo *consumes*
  exactly this streaming surface (proto `QueryStream`, Qwik `queryStream`). It
  should land **after** b7-10 (it depends on b7-10's contract). If parallelised,
  both may touch `rag.proto` / `index.tsx` → sequence b7-10 before b7-7, or
  coordinate the proto edit.
- **`b7-9-janus-ai` (#5)** — runtime AI refusal rules; touches gateway *policy*,
  not the streaming transport. Low overlap, but both may edit `llm_gateway`.
- **`b7-5-ai-act` (#6)** — AI-Act/DORA artefacts; may want a streaming-disclosure
  hook in the audit record — coordinate if it edits `llm_gateway/src/audit.rs`.
- **`b7-6-harness` (#9, gate)** — owns promotion + `buf generate`/`cargo fetch`
  live wiring + the ≥35-test suite; b7-10's streaming tests should be *additive* to
  what b7-6 aggregates. No edit conflict expected (b7-6 reads, doesn't rewrite).
- **`forge-ci.yml`** — append-only registration of `b7-10.test.sh` after
  `b7-2.test.sh`; any sibling also appending to the same matrix block is a trivial
  merge (orchestrator-owned).

**Mitigation**: b7-10 is additive (adds an RPC + functions + a UI mode; touches no
existing test assertion). The only true serialization constraint is **b7-7-example
must follow b7-10**. The orchestrator owns all git/branch/merge sequencing.
