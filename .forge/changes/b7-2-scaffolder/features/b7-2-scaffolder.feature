# <!-- Audit: B.7.2 (b7-2-scaffolder, Phase 5) — BDD scenarios (Article II) -->
# These scenarios mirror the four `specs.md` BDD acceptance criteria one-to-one.
# Each scenario cross-references the executable check that ENFORCES it — a
# `.forge/scripts/tests/b7-2.test.sh` harness test (T-xxx) and/or a Rust
# `#[cfg(test)]` unit test in the rendered backend workspace — so the BDD is
# executable-backed, not decorative. The harness runs:
#   L1 (hermetic, grep/structure) — T-001..006
#   L2 (toolchain-gated, skip-graceful) — T-L2-001..003
# The rendered Rust unit tests run via `cargo test --workspace` on the tree
# produced by overlaying scaffold-plan.yaml (Phase 2 verified 35 GREEN).

Feature: ai-native-rag scaffold backbone (candidate, pre-promotion)

  As a developer evaluating Forge's AI-native RAG archetype
  I want the scaffold backbone (templates + backend + wrapper) to be reviewable
    and testable while the archetype is still a candidate
  So that promotion to a scaffoldable archetype (B.7.6) rides a green, trusted
    backbone rather than unverified templates

  Background:
    Given the ai-native-rag/1.0.0 template tree and scaffold-plan exist
    And the ai-native-rag schema is stage:candidate / scaffoldable:false

  # ─── Scenario 1 — render-clean ───────────────────────────────────
  # Enforced by: b7-2.test.sh T-L2-001 (_test_b72_l2_001_render_clean) +
  #              T-002 (_test_b72_l1_002_plan_coverage, no orphan/dangling).
  # FR-B7-2-001 / FR-B7-2-002 / FR-B7-2-003 ; NFR-B7-2-004 (byte-stable re-render).
  Scenario: rendering the scaffold-plan produces a clean tree
    Given the ai-native-rag/1.0.0 template tree and scaffold-plan
    When overlay.sh renders the plan into an empty target directory
    Then the target contains backend/, frontend/web-public/, infra/, shared/protos/
    And no file retains a .tmpl suffix
    And no unsubstituted {{placeholder}} remains
    And a second render into a fresh target is byte-identical (determinism)

  # ─── Scenario 2 — the rendered backend builds ───────────────────
  # Enforced by: b7-2.test.sh T-L2-002 (_test_b72_l2_002_cargo_check, default
  #              features, skips gracefully when cargo absent) + the rendered
  #              Rust unit tests `cargo test --workspace` (rag 16 / llm_gateway 15
  #              / mcp 4). FR-B7-2-010 / FR-B7-2-012 / FR-B7-2-013 / FR-B7-2-014.
  Scenario: the rendered backend builds
    Given a freshly rendered ai-native-rag target
    When cargo check runs on the backend workspace (default features)
    Then it completes without error
    And the llm_gateway, mcp and rag modules are present with test scaffolding
    And the heavy local-embeddings (fastembed/ONNX) path is feature-gated OFF by default

  # ─── Scenario 3 — the CLI still refuses init for the candidate ───
  # Enforced by: cli archetypes-smoke.test.ts ("refuses ai-native-rag (candidate)
  #              with exit 3 + no scaffold") at the CLI layer, AND b7-2.test.sh
  #              T-006 (_test_b72_l1_006_wrapper_refuses_while_candidate) at the
  #              wrapper layer. FR-B7-2-051 ; ADR-B7-2-001 / ADR-B7-2-007.
  Scenario: the CLI still refuses init for the candidate archetype
    Given the schema is stage:candidate / scaffoldable:false
    When a user runs forge init --archetype ai-native-rag
    Then the CLI refuses with exit 3 and writes nothing
    And a [REFUSAL ...] message names the archetype as not yet scaffoldable
    And invoking bin/forge-init-ai-native-rag.sh directly refuses identically (exit 3, zero writes)

  # ─── Scenario 4 — a non-AI fallback exists for the gateway ───────
  # Enforced by: the rendered Rust unit test
  #              llm_gateway::handler::tests::upstream_down_degrades_to_non_ai_fallback
  #              (plus kill_switch_serves_fallback... and over_budget_degrades...).
  #              FR-B7-2-012 ; Article XI.5 ; global/llm-gateway.md.
  Scenario: a non-AI fallback exists for the gateway
    Given the scaffolded LLM gateway module
    When the AI upstream is unavailable
    Then a non-AI fallback path is exercised (Article XI.5)
    And the fallback returns the ranked source chunks instead of failing open
    And the prompt-audit record flags fallback_invoked = true (Article IX.6)
