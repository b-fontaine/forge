# <!-- Audit: B.7.10 (b7-10-streaming, Phase 4) — BDD scenarios (Article II) -->
# These scenarios mirror the five `specs.md` BDD acceptance criteria one-to-one.
# Each scenario cross-references the executable check that ENFORCES it — a
# `.forge/scripts/tests/b7-10.test.sh` harness test (T-xxx) and/or a Rust
# `#[cfg(test)]` unit test in the rendered streaming module — so the BDD is
# executable-backed, not decorative. The harness runs:
#   L1 (hermetic, grep/structure) — T-001..007
#   L2 (toolchain-gated, skip-graceful) — T-L2-001..004
# The rendered Rust streaming-fallback tests run via `cargo test --workspace` on
# the tree produced by overlaying scaffold-plan.yaml (L2 T-L2-002, observed GREEN).
# b7-10 is ADDITIVE to the b7-2 unary surface (the unary Query/process_query/
# query() are retained as the documented XI.5 degradation target).

Feature: ai-native-rag streaming RAG answer (candidate, pre-promotion)

  As a developer evaluating Forge's AI-native RAG archetype
  I want the streaming answer surface (server-streaming proto + streaming gateway
    + progressive Qwik UI) to be reviewable and testable while the archetype is
    still a candidate
  So that the streaming RAG UX promotion (B.7.6) rides a green, trusted streaming
    backbone rather than unverified templates

  Background:
    Given the ai-native-rag/1.0.0 template tree and scaffold-plan exist
    And the ai-native-rag schema is stage:candidate / scaffoldable:false
    And the b7-2 unary surface (Query / process_query / query()) is retained

  # ─── Scenario 1 — server-streaming RPC alongside the unary one ───
  # Enforced by: b7-10.test.sh T-001 (_test_b710_l1_001_proto_streaming_rpc) +
  #              T-002 (_test_b710_l1_002_querychunk_shape) ; T-L2-003 runs
  #              buf lint + buf breaking on the rendered proto when buf is present.
  # FR-B7-10-001 / FR-B7-10-002 / FR-B7-10-003 ; ADR-B7-10-001.
  Scenario: the proto exposes a server-streaming RPC alongside the unary one
    Given the ai-native-rag/1.0.0 shared/protos rag.proto
    When the proto is inspected
    Then a server-streaming QueryStream(QueryRequest) returns (stream QueryChunk) exists
    And the QueryChunk message carries token_delta, a one-shot sources frame, done and fallback_used
    And the unary Query RPC is still present (non-streaming fallback)
    And buf lint passes and buf breaking reports no breaking change

  # ─── Scenario 2 — progressive render + cancel ───────────────────
  # Enforced by: b7-10.test.sh T-005 (_test_b710_l1_005_qwik_streaming_markers:
  #              queryStream + for await + AbortController + cleanup/unmount + Stop)
  #              and the rendered streaming Rust test
  #              streaming::tests::healthy_upstream_streams_sources_then_tokens_then_done
  #              (one-shot sources frame → token deltas → done). FR-B7-10-021/022.
  Scenario: the answer renders progressively in the Qwik UI
    Given a rendered ai-native-rag web-public surface
    When the user submits a question and the backend streams answer chunks
    Then token deltas append to the answer area as they arrive (no full-response block)
    And the Stop control cancels the in-flight stream
    And navigating away cancels the stream on unmount

  # ─── Scenario 3 — stream degrades to the non-AI fallback ─────────
  # Enforced by: the rendered streaming Rust tests
  #              streaming::tests::pre_stream_upstream_failure_degrades_to_fallback_marked_chunk
  #              and ...::mid_stream_upstream_failure_terminates_with_fallback_marker,
  #              plus T-003/T-004 (close-time audit + cancellation flag markers).
  #              FR-B7-10-014 / FR-B7-10-015 ; Article XI.5 / IX.6 ; ADR-B7-10-003.
  Scenario: the stream degrades to the non-AI fallback when the AI is unavailable
    Given the scaffolded streaming gateway
    When the upstream LLM is unavailable before the first token
    Then the stream emits a fallback-marked terminal chunk (Article XI.5)
    And the prompt-audit record at stream close marks fallback_invoked

  # ─── Scenario 4 — UI degrades from streaming to unary ───────────
  # Enforced by: b7-10.test.sh T-005 (exponential-backoff retry helper +
  #              degrade-to-unary markers: DEFAULT_RETRY_POLICY / exponentialBackoffMs
  #              in connect-client.ts, retries-exhausted → query() in index.tsx).
  #              FR-B7-10-023 ; Article XI.5 (UI-layer fallback).
  Scenario: the UI degrades from streaming to unary on repeated stream errors
    Given the streaming UI with exponential-backoff retry
    When transient stream errors exhaust the bounded retry attempts
    Then the UI falls back to the unary query() path (UI-layer XI.5 fallback)

  # ─── Scenario 5 — the CLI still refuses init for the candidate ───
  # Enforced by: b7-2.test.sh T-006 (_test_b72_l1_006_wrapper_refuses_while_candidate)
  #              at the wrapper layer + the cli archetypes-smoke test at the CLI
  #              layer — b7-10 is additive and does NOT flip the schema stage.
  #              ADR-B7-10-006 ; b8-3b candidate ⇒ scaffoldable:false invariant.
  Scenario: the CLI still refuses init for the candidate archetype
    Given the schema is stage:candidate / scaffoldable:false
    When a user runs forge init --archetype ai-native-rag
    Then the CLI refuses with exit 3 and writes nothing
