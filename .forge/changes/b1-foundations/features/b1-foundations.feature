# <!-- Audit: B.1 (b1-foundations) -->
# Structural checks for the full-stack-monorepo foundation artifacts.
# These scenarios are the AC blocks from specs.md materialized as a
# machine-readable .feature file. They are exercised by the shell test
# harness `.forge/scripts/tests/foundations.test.sh`, which acts as the
# step runner — no cucumber / bdd_widget_test needed (this is infra
# tooling, not user-facing UI).

Feature: b1-foundations — structural validator for the full-stack-monorepo archetype

  As a Forge framework maintainer
  I want a deterministic validator that certifies the foundation artifacts
  So that b1-scaffolder / b1-workflow / b1-delivery can be built on a stable contract

  Background:
    Given the Forge repo is at or after commit `b1-foundations`
    And `python3` with `PyYAML >= 6.0` is available on PATH
    And `.forge/scripts/validate-foundations.sh` is executable

  # ─── FR-GL-001 — schema ────────────────────────────────────────

  Scenario: AC-001 schema exists and is valid
    Given the repo head is post-b1-foundations
    When a developer runs `bash .forge/scripts/verify.sh`
    Then stdout contains "PASS: FR-GL-001 — schema"
    And the exit code is 0

  Scenario: AC-002 schema rejects a non-SemVer version
    Given a fixture with `.forge/schemas/full-stack-monorepo/schema.yaml` where `version: "draft"`
    When the foundations validator is invoked
    Then stdout contains "FAIL: FR-GL-001 — version does not match SemVer"
    And the exit code is non-zero

  # ─── FR-GL-002, FR-GL-003, FR-GL-004 — standards ──────────────

  Scenario: AC-003 the three new standards exist with their canonical sections
    Given the repo head is post-b1-foundations
    When a developer lists the .forge/standards tree
    Then `global/monorepo-layout.md` is present with sections Arborescence, Interdictions, CLAUDE.md imbriqués, Préfixes FR-ID
    And `global/proto-contracts.md` is present with its five canonical sections
    And `infra/docker-compose.md` is present with its five canonical sections
    And the validator emits PASS for FR-GL-002, FR-GL-003, FR-GL-004

  # ─── FR-GL-005 — scoped commits ───────────────────────────────

  Scenario: AC-004 scoped commits enforced in monorepo mode
    Given a project using schema `full-stack-monorepo`
    And the pre-commit hook (delivered in b1-delivery) is installed
    When a contributor proposes a commit `feat(payment): add Stripe`
    Then the hook rejects the commit
    And the error message lists the valid scopes {backend, frontend, infra, protos, forge, docs, ci}
    # Note: the hook itself is delivered by b1-delivery / G.2. This change
    # validates only that the closed scope list is DECLARED in the standard.

  # ─── FR-GL-006 — versioning models ────────────────────────────

  Scenario: AC-005 docs/VERSIONING exposes both monorepo models
    Given the repo head is post-b1-foundations
    When a contributor searches docs/VERSIONING.md for "release-train" and "release-please"
    Then both headings exist: "### Release-train" and "### Per-package via release-please"
    And a decision matrix table is present
    And the Forge default recommendation is documented

  # ─── FR-GL-007 — index.yml ────────────────────────────────────

  Scenario: AC-006 standards index references the three new standards
    Given `.forge/standards/index.yml` is parsed
    Then three entries exist: global/monorepo-layout, global/proto-contracts, infra/docker-compose
    And each entry has the expected scope and priority from specs.md
    And no pre-existing entry has been modified

  # ─── FR-GL-008 — TDD RED→GREEN cycle ──────────────────────────

  Scenario: AC-007a RED state fails deterministically before deliverables exist
    Given a fixture with the Forge skeleton but none of the 7 deliverables
    When `bash .forge/scripts/validate-foundations.sh` runs against that fixture
    Then stdout contains at least one FAIL per FR-GL-00[1-7]
    And the exit code is 1

  Scenario: AC-007b GREEN state passes deterministically after all deliverables land
    Given a fixture populated with all 7 b1-foundations deliverables
    When `bash .forge/scripts/validate-foundations.sh` runs against that fixture
    Then stdout contains PASS for every FR-GL-00[1-7]
    And the exit code is 0

  # ─── NFR-001 — idempotence ────────────────────────────────────

  Scenario: NFR-001 validator is idempotent
    Given a fully-populated fixture
    When the validator is invoked twice in succession
    Then both runs produce byte-identical stdout
    And both runs return the same exit code

  # ─── NFR-002 — performance ────────────────────────────────────

  Scenario: NFR-002 validator completes within the budget
    Given the real Forge repo (fully populated)
    When `bash .forge/scripts/validate-foundations.sh` is timed
    Then the wall-clock duration is less than 2 seconds on a standard dev machine
