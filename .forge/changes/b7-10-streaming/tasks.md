# Tasks: b7-10-streaming

<!-- Planned: 2026-06-22 -->
<!-- TDD-ordered (Article I). Tests = b7-10.test.sh assertions (RED before template, -->
<!-- GREEN after) AND rendered-code #[cfg(test)] validated by L2 cargo check + Qwik tsc. -->
<!-- [P] = parallelizable within its phase. Status: PLANNED (no code written yet). -->

## Phase 0: Verify-then-pin + harness skeleton

- [x] Create `.forge/scripts/tests/b7-10.test.sh` skeleton (mirror `b7-2.test.sh`:
      arg-parsed `--level`, `_helpers.sh` source, `run_test`/`print_summary`) —
      confirm RED (streaming markers absent on the b7-2 baseline). **CI
      registration DEFERRED to end of Phase 4** (a RED test on main breaks CI).
      [Story: FR-B7-10-040] — RED confirmed: T-001..006 failed on baseline.
- [x] **Verify-then-pin LIVE** any *new* backend streaming crate (Q-3): run
      `cargo add --dry-run tokio-stream` / `async-stream` against the b7-2 ledger;
      determine whether `async-openai`'s streaming API + `futures`/`tokio` already
      present suffice (likely no new crate). Record the resolved decision + any pin
      in `.forge/research/b7-10-verify-then-pin.md`. NO pin committed until the
      consuming `Cargo.toml.tmpl` is edited (Article III.4 / ADR-B7-10-004).
      [Story: FR-B7-10-010] [NFR-B7-10-005] — ONE new crate: `tokio-stream = "0.1.18"`
      (LIVE), pinned only in `backend/Cargo.toml.tmpl`.
- [x] Confirm `buf.yaml`/`buf.gen.yaml` breaking-config: adding `QueryStream`
      + `QueryChunk` is non-breaking (Q-4). Record. [Story: FR-B7-10-003] —
      `breaking: use: [FILE]`; adding an RPC/message is additive → non-breaking.

## Phase 1: Streaming proto contract (RED→GREEN)

- [x] RED: `b7-10.test.sh` T-001 (streaming RPC present) / T-002 (`QueryChunk`
      shape) fail on the b7-2 proto. [Story: FR-B7-10-001/002]
- [x] GREEN: add `rpc QueryStream(QueryRequest) returns (stream QueryChunk);` to
      `shared/protos/v1/rag/rag.proto.tmpl`; retain unary `Query` unchanged.
      [Story: FR-B7-10-001] [ADR-B7-10-001]
- [x] GREEN: define `QueryChunk { string token_delta; repeated SourceChunk sources;
      bool done; bool fallback_used; }` reusing the existing `SourceChunk` (no
      duplicate type). [Story: FR-B7-10-002]
- [x] GREEN (L2, gated): `buf lint` + `buf breaking` clean on the rendered proto
      vs the b7-2 baseline (skip if `buf` absent). [Story: FR-B7-10-003] — `buf`
      absent here → SKIP graceful (T-L2-003); structural seam asserted at L1.
- [x] Update `scaffold-plan.yaml` if any new `.tmpl` is added (no orphan/dangling;
      mirror b7-2 plan↔tree coverage). [Story: FR-B7-10-040] — registered
      `backend/llm_gateway/src/streaming.rs.tmpl`; b7-2 T-002 plan-coverage GREEN.

## Phase 2: Backend streaming pipeline (Rust, Vulcan/Ferris — all TDD)

- [x] RED: streaming-gateway unit tests (`process_query_stream`) — pre-stream
      fallback, mid-stream fallback, kill-switch/tier/budget → streamed fallback,
      backpressure, cancel, close-audit — fail (no streaming entrypoint yet).
      [Story: FR-B7-10-010..015] — RED via T-003/T-004 on baseline.
- [x] GREEN: streaming `Upstream::generate_stream(...)` trait method yielding
      token items; `FailingUpstream` (pre-stream) +
      `MidStreamFailingUpstream` test doubles (mirror b7-2 `FailingUpstream`).
      [Story: FR-B7-10-011] [ADR-B7-10-001] — `StreamingUpstream` trait in
      `llm_gateway/src/streaming.rs`.
- [x] GREEN: `process_query_stream(...)` — reuse `decide_route`; bounded channel
      (named constant `STREAM_CHANNEL_CAPACITY`) for **backpressure**;
      `JoinHandle::abort` + closed-channel for **cancellation**; pre-stream +
      mid-stream **XI.5 fallback** (terminate-with-marker, ADR-B7-10-003); unary
      `process_query` retained. [Story: FR-B7-10-010/012/013/014] [llm-gateway.md]
- [x] GREEN: **close-time prompt-audit** (IX.6) with final token counts +
      `fallback_invoked` + `cancelled` (new `PromptAudit.cancelled` field);
      `redact_pii` (XI.6) on the prompt path. [Story: FR-B7-10-015]
- [x] GREEN: `backend/rag/` — sources retrieved once and emitted as the one-shot
      `sources` frame before tokens (preserves the b7-2 hybrid-retrieval pipeline,
      rag-patterns.md). [Story: FR-B7-10-014] — one-shot `QueryChunk::sources_frame`
      emitted before token deltas in `process_query_stream`.
- [x] GREEN (L2, gated): `cargo check`/`cargo test` clean on the rendered backend
      workspace (skip if cargo/registry absent; b7-2 L2 convention).
      [Story: NFR-B7-10-002/003] — `cargo test --workspace` GREEN on rendered tree
      (T-L2-002), streaming-fallback tests pass.
- [x] Pins (if any new crate): ONLY in `backend/.../Cargo.toml.tmpl`; b7-3 T-007
      no-inline-pin guard stays GREEN. [Story: NFR-B7-10-005] [ADR-B7-10-004] —
      `tokio-stream = "0.1.18"` in `backend/Cargo.toml.tmpl` only; b7-3 T-007 GREEN.

## Phase 3: Frontend streaming UI (Qwik, Hera/Apollo — TDD via render+tsc)

- [x] RED: `b7-10.test.sh` Qwik markers (`queryStream`/`for await`/cancel/
      cancel-on-unmount/exp-retry/unary-degrade) fail on the b7-2 frontend.
      [Story: FR-B7-10-020..023] — RED via T-005/T-006 on baseline.
- [x] GREEN: `connect-client.ts.tmpl` adds `queryStream(question, topK?, signal?)`
      async iterable over the Connect-ES v2 server-streaming client (`for await`),
      transport reused (pins owned by transport.yaml); unary `query()` retained.
      [Story: FR-B7-10-020] [ADR-B7-10-002]
- [x] GREEN: `routes/index.tsx.tmpl` progressive render — append `token_delta` to a
      `useSignal` as chunks arrive (Article XI.4); surface `fallbackUsed`.
      [Story: FR-B7-10-021]
- [x] GREEN: Stop/cancel control (`AbortController` → Connect signal) + **cancel-on-
      unmount** (Qwik `useVisibleTask$` cleanup); no orphaned stream on navigation.
      [Story: FR-B7-10-022]
- [x] GREEN: named **exponential-backoff retry** helper (`DEFAULT_RETRY_POLICY` /
      `exponentialBackoffMs`, bounded attempts, documented base/max) → on
      exhaustion **degrade to unary `query()`** (UI-layer XI.5). [Story: FR-B7-10-023]
- [x] GREEN: `frontend/web-public/README.md.tmpl` — WebTransport documented as the
      **forward alternative**, NOT default-wired; marked non-default scaffold note.
      [Story: FR-B7-10-030] [ADR-B7-10-005]
- [x] GREEN (L2, gated): Qwik `tsc --noEmit` clean except the inherited un-generated
      `rag_pb` import (b7-2 parity). [Story: NFR-B7-10-002] — `tsc` absent here →
      SKIP graceful (T-L2-004); Qwik typecheck rides b7-6 (toolchain present there).

## Phase 4: Harness finalize + BDD + no-regression

- [x] Finalize `b7-10.test.sh`: L1 (proto streaming + unary-retained, backend
      markers, Qwik markers, WebTransport-documented, baseline-intact, no-inline-pin)
      + L2 (overlay render-clean + byte-stable, buf lint/breaking, Qwik tsc, cargo
      check). Register in `forge-ci.yml` (`--level 1`, after `b7-2.test.sh`).
      [Story: FR-B7-10-040] — L1 7/7, L2 11/11 (2 graceful SKIP buf/tsc); CI
      registered after `b7-2.test.sh --level 1`.
- [x] `features/b7-10-streaming.feature` — 5 scenarios (streaming-RPC-present,
      progressive-render+cancel, pre-stream-fallback, unary-degradation,
      CLI-refuses); each cross-references the enforcing test. [Story: Article II]
- [x] No-regression sweep: `b7-2.test.sh` (L1 7/L2 3 → observed L1 7/L2 3), `b7-1`
      (19), `b7-2a` (4), `b7-3` (7), `verify.sh` (469/0), `constitution-linter.sh`
      (69/0), `validate-foundations.sh` all GREEN. [Story: NFR-B7-10-001/002]
- [x] (Wrapper/CLI surface NOT touched.) Schema stays `candidate`; CLI keeps
      refusing `forge init --archetype ai-native-rag` exit 3. NO `npm run bundle`
      change (cli/assets is a gitignored build artifact; bundle rides b7-6
      promotion). [Story: ADR-B7-10-006]

## Phase 5: Independent review

- [ ] Independent review pass (separate agent/context) — verify no fabricated pin,
      streaming fallback (pre + mid) actually tested, unary baseline intact,
      additive-only, schema unchanged (candidate). Promotion NOT done here (→ b7-6).
      [Story: ADR-B7-10-006]

## Constitutional Compliance Gate (per phase)

No task requires violating TDD (every impl task is RED→GREEN), bypassing specs
(all tasks cite FR/ADR), or breaking architecture articles. No `[TASK VIOLATION]`.
Open: Q-1 (WebTransport depth) `[NEEDS CLARIFICATION]` — resolve at the proposal/
design gate before Phase 3's README task hardens.

---

**Gate**: Tasks generated. Review `tasks.md`. Next: `/forge:implement b7-10-streaming`
(after maintainer resolves Q-1; the rest is unblocked).
