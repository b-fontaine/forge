# <!-- Audit: B.1.6 + B.1.7 + B.1.8 (b1-workflow) -->
# BDD scenarios for the multi-layer workflow: Janus orchestration,
# per-change metadata validation, and multi-root verify.sh +
# constitution-linter.sh scoping. Mirrors AC-001..007 from specs.md
# one-to-one. Executed by `.forge/scripts/tests/workflow.test.sh`.

Feature: b1-workflow — cross-layer orchestration + multi-root deterministic scripts

  As a contributor to a Forge `full-stack-monorepo` project
  I want cross-layer changes to be coordinated by Janus
  And verify.sh / constitution-linter.sh to scope their checks per layer
  So that quality gates run for real on the right subtree

  Background:
    Given the target project declares `schema: full-stack-monorepo` in its root `.forge.yaml`
    And the archetype schema at `.forge/schemas/full-stack-monorepo/schema.yaml` declares `layers: [backend, frontend, infra]`

  # ─── AC-001 : Janus agent file structure ─────────────────────

  Scenario: AC-001 Janus agent exposes the required structure
    Given the repository at post-b1-workflow HEAD
    When a reviewer opens `.claude/agents/cross-layer-orchestrator.md`
    Then the file contains section `## Persona`
    And contains section `## Dispatch Table`
    And contains section `## 12-Step Workflow`
    And contains section `## Quality Gates`
    And contains section `## Routing Rules`
    And the Persona section states "Janus NEVER writes application code"
    And the Dispatch Table references Hera, Vulcan, Atlas, Hermes-API, Nemesis, Tribune, Aegis

  # ─── AC-002 : multi-layer metadata validation ────────────────

  Scenario: AC-002a single-layer change passes metadata check
    Given a change `.forge.yaml` with `layers: [backend]` and no per-layer files
    When `validate-foundations.sh` runs
    Then the validator emits `PASS: FR-GL-017 — <N> change(s) inspected, metadata consistent`

  Scenario: AC-002b multi-layer change with complete per-layer files passes
    Given a change with `layers: [backend, frontend]`, `designs_per_layer:` + `tasks_per_layer:` present, and every referenced file exists
    When the validator runs
    Then exit code is 0 and FR-GL-017 PASSes

  Scenario: AC-002c multi-layer change without per-layer map fails
    Given a change with `layers: [backend, frontend]` but `designs_per_layer:` absent
    When the validator runs
    Then output contains "FAIL: FR-GL-017" and "designs_per_layer"

  Scenario: AC-002d unknown layer id fails
    Given a change with `layers: [backend, unicorn]`
    When the validator runs
    Then output contains "FAIL: FR-GL-017" and "unicorn"

  # ─── AC-003 : multi-layer-workflow standard sections ─────────

  Scenario: AC-003 the standard file has all 6 canonical sections
    Given `.forge/standards/global/multi-layer-workflow.md` exists
    When the validator section-presence check runs
    Then all 6 H2 headings are detected and FR-GL-018 PASSes

  # ─── AC-004 : multi-root scoped verify.sh ────────────────────

  Scenario: AC-004 scoped sections emit layer-prefixed lines
    Given a scaffolded `full-stack-monorepo` project at `/tmp/demo-app`
    When `FORGE_ROOT=/tmp/demo-app bash verify.sh` runs
    Then stdout contains `── Backend (scoped) ──` followed by `[backend] ...` lines
    And stdout contains `── Frontend (scoped) ──` followed by `[frontend] ...` lines
    And stdout contains `── Protos (scoped) ──` with `[protos] buf lint`
    And stdout contains `── Infra (scoped) ──` with `[infra] ...` lines

  # ─── AC-005 : single-root backwards compatibility ────────────

  Scenario: AC-005 non-monorepo target sees no new output
    Given a project whose `.forge.yaml` declares `schema: default`
    When `verify.sh` runs at that target
    Then stdout contains NO `── Backend (scoped) ──` / `── Frontend (scoped) ──` / `── Protos (scoped) ──` / `── Infra (scoped) ──` section
    And stdout contains NO `[backend]` / `[frontend]` / `[protos]` / `[infra]` prefix
    And the output is byte-identical to the pre-b1-workflow behaviour

  # ─── AC-006 : workflow harness self-consistency ──────────────

  Scenario: AC-006 full harness at L1+L2 exits 0 on the Forge repo
    Given the repo at post-b1-workflow HEAD
    When `bash workflow.test.sh --level 1,2` runs
    Then exit code is 0
    And 5 L1 scenarios PASS (Janus, standard, per-layer templates, change.yaml)
    And 6 L2 scenarios PASS (4 metadata + standard-real-repo + index entry)

  # ─── AC-007 : Janus never writes application code ───────────

  Scenario: AC-007 Janus dispatches without writing code itself
    Given Janus is invoked on a cross-layer change design phase
    When Janus executes its 12-step workflow
    Then Janus dispatches to Hera, Vulcan, Atlas, Hermes-API at the appropriate steps
    And Janus produces only (a) routing decisions, (b) aggregated reports, or (c) [NEEDS CLARIFICATION] markers
    And no file under `frontend/`, `backend/`, `infra/`, or `shared/protos/` was written by Janus
