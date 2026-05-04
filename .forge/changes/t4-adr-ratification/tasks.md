# Tasks: t4-adr-ratification
<!-- Status: implemented -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail, write the
  artefact, watch it pass, refactor.
- Audit trail tag `[Story: FR-T4-XXX]` (Article V.1) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the same phase.
- Each phase ends with a **gate task** that runs `bash .forge/scripts/verify.sh`
  + `bash .forge/scripts/constitution-linter.sh` and verifies OVERALL PASS.

---

## Phase 1 — Foundation : test harness skeleton

Goal : `t4.test.sh` exists with all 30 test functions returning FAIL. Full
RED state for the entire change. No artefact present yet.

- [x] **T-PHA-001** : Create `.forge/scripts/harnesses/t4.test.sh` with
      bash header (`#!/usr/bin/env bash` + `set -euo pipefail` + source
      `_helpers.sh`) and PASS/FAIL/SKIP counters wired. [Story: FR-T4-TST-001]
- [x] **T-PHA-002** : Add 25 L1 test stubs (one per FR-T4-TST-002 enumerated
      coverage point), each calling `_fail "not implemented"`. [Story: FR-T4-TST-002]
- [x] **T-PHA-003** : Add `setup_l2()` and `teardown_l2()` functions that
      create / remove `tmp/t4-fixtures/`. [Story: FR-T4-TST-005]
- [x] **T-PHA-004** : Add 5 L2 fixture-test stubs returning FAIL.
      [Story: FR-T4-TST-005]
- [x] **T-PHA-005** : Add final report block that prints
      `PASS=N FAIL=N SKIP=N OVERALL=...` and exits non-zero on any FAIL.
      [Story: FR-T4-TST-001]
- [x] **T-PHA-006** [P] : Register `t4.test.sh` in `verify.sh`
      aggregated runner (after `f4.test.sh`). [Story: FR-T4-TST-001]
- [x] **T-PHA-007** [P] : Register `t4.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix.
      [Story: FR-T4-TST-001]
- [x] **T-PHA-008** : RED gate — run `bash .forge/scripts/harnesses/t4.test.sh`
      ; expect exit code non-zero ; expect `FAIL=30` in report ; capture log.
      [Story: FR-T4-TST-002]

**Phase 1 exit gate** : `t4.test.sh` exits non-zero with `FAIL=30`. Constitution
linter still OVERALL PASS (no new artefacts yet, so no regression).

---

## Phase 2 — Core : six versioned standards (TDD per file)

Goal : six `.forge/standards/*.yaml` shipped. After each standard, the matching
parse-test and frontmatter-test flip GREEN.

### T-STD-001 — `transport.yaml`

- [x] **T-STD-001-1** : Verify the test `test_transport_yaml_parses` is FAIL
      (RED witness). [Story: FR-T4-STD-001]
- [x] **T-STD-001-2** : Create `.forge/standards/transport.yaml` with the
      verbatim content from `design.md` §2.2.1 (12 fields including
      `protocol: connect-rpc`, `codegen.tools: [...]`,
      `breaking_change_check: ...`, `exception_constitutional: true`,
      `expires_at: never`). [Story: FR-T4-STD-001]
- [x] **T-STD-001-3** : Run `t4.test.sh` ; expect
      `test_transport_yaml_parses` PASS, `test_transport_yaml_frontmatter`
      PASS, `test_transport_exception_constitutional_true` PASS.
      [Story: FR-T4-STD-001]

### T-STD-002 — `state-management.yaml`

- [x] **T-STD-002-1** : Verify
      `test_state_management_yaml_parses` is FAIL. [Story: FR-T4-STD-002]
- [x] **T-STD-002-2** : Create `.forge/standards/state-management.yaml`
      with `flutter.standard: flutter_bloc`, the **8-element forbidden:**
      array (flutter_riverpod, riverpod, provider, get, getx, mobx,
      flutter_mobx, states_rebuilder) verbatim from `design.md` §2.2.2,
      `enforcement.ci_blocking: false`,
      `enforcement.activation_planned: "B.8 (T6)"`,
      `exception_constitutional: true`. [Story: FR-T4-STD-002]
- [x] **T-STD-002-3** : Run `t4.test.sh` ; expect 3 tests PASS
      (`parses`, `frontmatter`, `forbidden_non_empty`,
      `exception_constitutional_true`). [Story: FR-T4-STD-002]

### T-STD-003 — `observability.yaml` [P]

- [x] **T-STD-003-1** [P] : Verify `test_observability_yaml_parses` is FAIL.
      [Story: FR-T4-STD-003]
- [x] **T-STD-003-2** [P] : Create `.forge/standards/observability.yaml`
      verbatim from `design.md` §2.2.3 (sdk: opentelemetry,
      ebpf_complement: opentelemetry-obi, service_map: coroot,
      backend: signoz, kernel_min: "5.8", forbidden: [datadog]).
      [Story: FR-T4-STD-003]
- [x] **T-STD-003-3** [P] : Run `t4.test.sh` ; expect 2 tests PASS.
      [Story: FR-T4-STD-003]

### T-STD-004 — `orchestration.yaml` [P]

- [x] **T-STD-004-1** [P] : Verify
      `test_orchestration_yaml_parses` is FAIL. [Story: FR-T4-STD-004]
- [x] **T-STD-004-2** [P] : Create `.forge/standards/orchestration.yaml`
      verbatim from `design.md` §2.2.4 (default: dbos, fallback: temporal,
      fallback_trigger: "...", forbidden: [inngest]).
      [Story: FR-T4-STD-004]
- [x] **T-STD-004-3** [P] : Run `t4.test.sh` ; expect 2 tests PASS.
      [Story: FR-T4-STD-004]

### T-STD-005 — `identity.yaml` [P]

- [x] **T-STD-005-1** [P] : Verify `test_identity_yaml_parses` is FAIL.
      [Story: FR-T4-STD-005]
- [x] **T-STD-005-2** [P] : Create `.forge/standards/identity.yaml`
      verbatim from `design.md` §2.2.5 (default: zitadel,
      alternatives: [keycloak, authentik],
      forbidden: [firebase-auth, auth0-saas-us],
      compliance_tier_aware: true). [Story: FR-T4-STD-005]
- [x] **T-STD-005-3** [P] : Run `t4.test.sh` ; expect 3 tests PASS
      (parses, frontmatter, forbidden_non_empty). [Story: FR-T4-STD-005]

### T-STD-006 — `persistence.yaml` [P]

- [x] **T-STD-006-1** [P] : Verify `test_persistence_yaml_parses` is FAIL.
      [Story: FR-T4-STD-006]
- [x] **T-STD-006-2** [P] : Create `.forge/standards/persistence.yaml`
      verbatim from `design.md` §2.2.6 (default: postgres-17,
      extensions: [pgvector-0.8, postgis, timescaledb], sharding: citus,
      forbidden_for_eu_strict: [dynamodb, firestore, cosmosdb]).
      [Story: FR-T4-STD-006]
- [x] **T-STD-006-3** [P] : Run `t4.test.sh` ; expect 3 tests PASS
      (parses, frontmatter, forbidden_non_empty). [Story: FR-T4-STD-006]

**Phase 2 exit gate** : `t4.test.sh` reports 18 PASS / 12 FAIL / 0 SKIP.
`bash .forge/scripts/constitution-linter.sh` OVERALL PASS.
`bash .forge/scripts/validate-change-yaml.sh` exit 0 on every archived change
(NFR-T4-003 backward compatibility).

---

## Phase 3 — JSON schemas + lifecycle artefacts

### T-SCH-001 — `compliance-tier.schema.json`

- [x] **T-SCH-001-1** : Verify `test_compliance_tier_schema_valid` is FAIL.
      [Story: FR-T4-SCH-001]
- [x] **T-SCH-001-2** : Create `.forge/schemas/compliance-tier.schema.json`
      verbatim from `design.md` §2.4.1 (Draft 2020-12, enum [T1, T2, T3],
      `x-tier-descriptions` map). [Story: FR-T4-SCH-001]
- [x] **T-SCH-001-3** : Run `t4.test.sh` ; expect
      `test_compliance_tier_schema_valid` PASS,
      `test_compliance_tier_schema_accepts_T1_T2_T3_only` PASS.
      [Story: FR-T4-SCH-001]

### T-SCH-002 — bump `archetype.schema.json` v1 → v2

- [x] **T-SCH-002-1** : Read current `.forge/schemas/archetype.schema.json`
      content (capture v1 for git history audit). [Story: FR-T4-SCH-002]
- [x] **T-SCH-002-2** : Verify `test_archetype_schema_v2_accepts_5_canonical_plus_legacy`
      is FAIL (RED witness — current v1 doesn't have the new enum).
      [Story: FR-T4-SCH-002]
- [x] **T-SCH-002-3** : Overwrite `.forge/schemas/archetype.schema.json`
      with the v2 content from `design.md` §2.4.2 (6-value enum +
      `x-archetype-descriptions` map, `mobile-only` flagged DEPRECATED).
      [Story: FR-T4-SCH-002]
- [x] **T-SCH-002-4** : Run `t4.test.sh` ; expect 3 schema tests PASS
      (`v2_valid`, `accepts_5_canonical_plus_legacy`,
      `rejects_flutter_firebase`). [Story: FR-T4-SCH-002]

### T-LC-001 — `standards-lifecycle.md`

- [x] **T-LC-001-1** : Verify `test_standards_lifecycle_lists_structural_exceptions`
      is FAIL. [Story: FR-T4-LC-001, FR-T4-LC-002]
- [x] **T-LC-001-2** : Create `.forge/standards/global/standards-lifecycle.md`
      with 6 H2 sections (Purpose, Frontmatter, 12-month review window,
      Structural exception, Themis hook deferred, Linter integration with
      `expires_at`). The structural-exception section MUST list
      `transport.yaml` and `state-management.yaml` by name with
      `exception_constitutional: true` cross-reference.
      [Story: FR-T4-LC-001, FR-T4-LC-002, FR-T4-LC-004]
- [x] **T-LC-001-3** : Run `t4.test.sh` ; expect lifecycle test PASS.
      [Story: FR-T4-LC-002]

### T-LC-002 — `REVIEW.md` ledger seed

- [x] **T-LC-002-1** : Verify `test_review_md_has_6_seed_entries` is FAIL.
      [Story: FR-T4-LC-003]
- [x] **T-LC-002-2** : Create `.forge/standards/REVIEW.md` from the
      seed template in `design.md` §2.3.1 (6 entries, all
      `Reviewed on: 2026-05-04`, reviewer `@bfontaine`).
      [Story: FR-T4-LC-003]
- [x] **T-LC-002-3** : Run `t4.test.sh` ; expect review test PASS.
      [Story: FR-T4-LC-003]

**Phase 3 exit gate** : `t4.test.sh` reports 25 PASS / 5 FAIL / 0 SKIP. The
remaining 5 FAILs are L2 fixture tests + drift gate.

---

## Phase 4 — Drift detector + linter rule

### T-DRF-001 — Drift detector (FR-T4-LNT-002)

- [x] **T-DRF-001-1** : Verify `test_architecture_doc_hash_unchanged` FAIL
      (no hash recorded yet because we haven't filled `specs.md` Source
      Document table — wait, we did that already in Phase 0/specify).
      Actually : the hash IS in `specs.md`, so this test should already
      PASS. Verify and confirm. If unexpectedly FAIL, debug. [Story: FR-T4-LNT-002]
- [x] **T-DRF-001-2** : If T-DRF-001-1 passes, verify
      `test_l2_drift_detector_fails_on_byte_change` FAIL (RED witness :
      simulate a byte change in a fixture copy of the doc).
      [Story: FR-T4-LNT-002]
- [x] **T-DRF-001-3** : Implement the L2 logic in `t4.test.sh` —
      `setup_l2` copies `docs/ARCHITECTURE-TARGET.md` to
      `tmp/t4-fixtures/edited.md`, mutates one byte (append a space), runs
      a hash comparison and asserts it FAILs. [Story: FR-T4-LNT-002]
- [x] **T-DRF-001-4** : Implement
      `test_l2_drift_detector_passes_after_rehash` — `setup_l2` copies the
      doc, doesn't mutate, asserts hash matches. [Story: FR-T4-LNT-002]
- [x] **T-DRF-001-5** : Run `t4.test.sh` ; expect 2 drift tests PASS.
      [Story: FR-T4-LNT-002]

### T-DRF-002 — Rehash escape hatch script

- [x] **T-DRF-002-1** : Create `bin/forge-rehash-architecture-doc.sh`
      with bash heredoc that : (a) recomputes sha256 of
      `docs/ARCHITECTURE-TARGET.md`, (b) edits the
      `specs.md::Source Document` line `| **sha256** | …`, (c) appends
      a dated entry to `.forge/changes/t4-adr-ratification/REHASH-LOG.md`
      (created on first run), (d) prints diff old→new. [Story: FR-T4-DOC-002]
- [x] **T-DRF-002-2** : Add a dry-run smoke test to `t4.test.sh`
      that invokes the script with `--dry-run` and asserts non-zero changes
      reported (since hash is identical, dry-run reports `no change`
      and exits 0). [Story: FR-T4-DOC-002]

### T-LNT-001 — `no-state-management-alternatives` linter rule (warn-only)

- [x] **T-LNT-001-1** : Verify
      `test_l2_lint_state_management_warn_when_riverpod_present` FAIL
      (linter not yet wired). [Story: FR-T4-LNT-001]
- [x] **T-LNT-001-2** : Verify
      `test_l2_lint_state_management_pass_when_only_bloc` FAIL.
      [Story: FR-T4-LNT-001]
- [x] **T-LNT-001-3** : Add function `lint_state_management()` in
      `.forge/scripts/constitution-linter.sh` — reads
      `.forge/standards/state-management.yaml` for forbidden + ci_blocking,
      walks Flutter `pubspec.yaml` files (excluding `examples/`), emits
      WARN/FAIL accordingly. Add new section header
      `Section: state-management discipline (ADR-006)`. Honour
      `FORGE_LINTER_SKIP_NSMA=1` opt-out. [Story: FR-T4-LNT-001]
- [x] **T-LNT-001-4** : Add WARN counter increment on detection (re-uses
      F.4 `warn` helper). [Story: FR-T4-LNT-001]
- [x] **T-LNT-001-5** : Implement `setup_l2` for these tests :
      - Fixture A : `tmp/t4-fixtures/proj-a/frontend/pubspec.yaml`
        contains `flutter_riverpod: ^2.5.0` → expect 1 WARN.
      - Fixture B : `tmp/t4-fixtures/proj-b/frontend/pubspec.yaml`
        contains only `flutter_bloc: ^9.0.0` → expect 0 WARN.
      [Story: FR-T4-LNT-001]
- [x] **T-LNT-001-6** : Run `t4.test.sh` ; expect 2 linter tests PASS,
      `verify.sh` aggregate WARN counter increments by exactly 1 on
      fixture A and stays unchanged on fixture B. [Story: FR-T4-LNT-001]

### T-LC-003 — `expires_at` warn integration

- [x] **T-LC-003-1** : Verify `test_l2_no_expired_standards_warns_when_past_due`
      FAIL. [Story: FR-T4-LC-005]
- [x] **T-LC-003-2** : Add function `lint_standards_expiry()` in
      `constitution-linter.sh` — walks `.forge/standards/*.yaml`,
      reads `expires_at`, emits WARN if past today's date AND
      `exception_constitutional` ≠ true. [Story: FR-T4-LC-005]
- [x] **T-LC-003-3** : `setup_l2` writes a synthetic
      `tmp/t4-fixtures/expired-std.yaml` with
      `expires_at: 2020-01-01` and `exception_constitutional: false` ;
      assert WARN emitted, exit 0. [Story: FR-T4-LC-005]
- [x] **T-LC-003-4** : Run `t4.test.sh` ; expect lifecycle expiry test PASS.
      [Story: FR-T4-LC-005]

**Phase 4 exit gate** : `t4.test.sh` reports 30 PASS / 0 FAIL / 0 SKIP.
`time bash t4.test.sh` ≤ 3 s (NFR-T4-001).
`constitution-linter.sh` OVERALL PASS with new WARN counters wired.

---

## Phase 5 — Documentation, index, dispatch table, CHANGELOG

- [x] **T-DOC-001** [P] : Create `docs/STANDARDS-LIFECYCLE.md` (public-
      facing) summarising the 12-month rule, the structural exceptions,
      and pointing to `.forge/standards/REVIEW.md`. [Story: FR-T4-DOC-001]
- [x] **T-DOC-002** [P] : Create
      `.forge/standards/global/source-document-pinning.md` documenting
      the sha256-pinning convention (FR-T4-LNT-002 + Q-003 resolution) +
      `bin/forge-rehash-architecture-doc.sh` workflow.
      [Story: FR-T4-DOC-002]
- [x] **T-DOC-003** [P] : Update `CHANGELOG.md` `## [Unreleased]` section
      with the 5 bullet points from `specs.md::FR-T4-DOC-003`.
      [Story: FR-T4-DOC-003]
- [x] **T-IDX-001** : Update `.forge/standards/index.yml` — append 7
      entries (6 new YAML standards + `global/standards-lifecycle.md`).
      Verify `verify.sh` aggregate still PASS. [Story: FR-T4-IDX-001, FR-T4-IDX-002]
- [x] **T-IDX-002** : Update `.forge/framework-owned-paths.yml` — append
      6 entries (the 6 standards) + `REVIEW.md` + lifecycle.md +
      source-document-pinning.md + `compliance-tier.schema.json` +
      `forge-rehash-architecture-doc.sh`. Verify `a7.test.sh` continues to
      pass (smoke test against `examples/forge-fsm-example/`).
      [Story: FR-T4-IDX-001]
- [x] **T-DSP-001** : Update `.forge/scaffolding/dispatch-table.yml` —
      annotate `flutter-firebase` placeholder with
      `status: removed_from_roadmap` + reason ;
      annotate `mobile-only` with `status: legacy_alias` + `target: mobile-pwa-first`
      + `migration: B.9 (T8)`. Verify `b5.test.sh` continues to pass
      (NFR-IW-004 backward compat). [Story: FR-T4-DSP-001]
- [x] **T-DOC-004** : Update `docs/ARCHETYPES.md` — add a header note
      pointing to `docs/STANDARDS-LIFECYCLE.md` and
      `docs/new-archetypes-plan.md` (NFR-T4-007). [Story: FR-T4-DOC-001]

**Phase 5 exit gate** : All 13 archived changes still validate ;
`b5.test.sh` 17/17 PASS ; `a7.test.sh` 29/29 PASS ; `f2.test.sh` 18/18 PASS ;
`f4.test.sh` 23/23 PASS ; `t4.test.sh` 30/30 PASS. `verify.sh`
aggregate WARN remains at the value pre-t4 + 0 (no real Riverpod usage in
the repo, the linter rule fires only on fixtures during L2 tests which
clean up after themselves).

---

## Phase 6 — Wrap-up

- [x] **T-WRP-001** : Run full `bash .forge/scripts/verify.sh` ; capture
      output ; expect OVERALL PASS, no new FAIL. [Story: NFR-T4-003]
- [x] **T-WRP-002** : Run `bash .forge/scripts/constitution-linter.sh` ;
      expect OVERALL PASS. [Story: NFR-T4-003]
- [x] **T-WRP-003** : Run all 14 harnesses (foundations, scaffolder,
      workflow, delivery, g1, c1, a7, b5, d5, b4, f1, f2, f4, **t4**) ;
      expect every harness PASS, total ≥ 322 tests (292 pre-t4 + 30 t4).
      [Story: NFR-T4-003]
- [x] **T-WRP-004** : `time bash .forge/scripts/harnesses/t4.test.sh` ;
      capture wall-clock ; assert ≤ 3 s. [Story: NFR-T4-001]
- [x] **T-WRP-005** : Verify `wc -l` of created files vs NFR-T4-002 budget
      (≤ 18 NEW + ≤ 6 modified). [Story: NFR-T4-002]
- [x] **T-WRP-006** : Verify `grep -rL` confirms zero edit under `cli/src/`,
      `frontend/`, `backend/`, `infra/`, `examples/forge-fsm-example/`
      (NFR-T4-005). [Story: NFR-T4-005]
- [x] **T-WRP-007** : Verify `.forge/constitution.md` SHA1 unchanged from
      pre-t4 commit (NFR-T4-004 — no Constitution amendment).
      [Story: NFR-T4-004]
- [x] **T-WRP-008** : Update `.forge.yaml` `status: implemented` +
      `timeline.implemented: 2026-05-04`. [Story: FR-T4-IDX-001]
- [x] **T-WRP-009** : Run final `validate-change-yaml.sh` on this change ;
      expect exit 0. [Story: NFR-T4-003]
- [x] **T-WRP-010** : Open-questions gate — verify
      `.forge/changes/t4-adr-ratification/open-questions.md` has 0
      `Status: open` lines (3/3 answered). [Story: F.1 gate]

**Phase 6 exit gate** : Ready for `/forge:archive t4-adr-ratification`.

---

## Constitutional compliance gate (per task)

For every task above, the following has been verified at planning time :

- **Article I (TDD)** : every artefact-creating task is preceded by a
  test-FAIL verification task (RED witness) and followed by a
  test-PASS task. No task creates production-equivalent content without
  a witnessing test.
- **Article III (specs before code)** : every task carries a `[Story: FR-T4-XXX]`
  audit trail to `specs.md`. No task is "discretionary".
- **Article IV (delta specs)** : `specs.md` already opened with the
  `## ADDED / ## MODIFIED / ## REMOVED` headers ; tasks here are pure
  implementation, no spec change.
- **Article V (constitution gate)** : Phase exit gates explicitly call
  the linter ; CI fail blocks the change advance.
- **Articles II / VI / VII / VIII / XI** : N/A (methodology change).
- **Article IX (security)** : `forbidden:` lists in YAML standards are
  the security boundaries ; tasks copy them verbatim from `design.md`
  ; no violation possible by construction.
- **Article X (quality)** : `[Story: FR-T4-XXX]` linkage on every task
  satisfies Article V.1 (verified post-t4 by F.4 linter rule).
- **Article XII (governance)** : Constitution unchanged ; T-WRP-007
  enforces this.

No `[TASK VIOLATION]` markers. Plan proceeds to `/forge:implement`.

---

## Summary

- **Total tasks**: 51 (8 + 18 + 9 + 14 + 7 + 10 - some overlap merged) effectively organized in 6 phases.
- **Parallelizable blocks** : phase 2 standards 003-006 (4 standards in
  parallel after 001 + 002 are GREEN), phase 5 docs T-DOC-001/002/003.
- **Critical path** : Phase 1 (foundation) → Phase 2 STD-001 →
  STD-002 (sequential, since Section header structure pattern is established)
  → Phase 3 schemas → Phase 4 linter (depends on STD-002) → Phase 5 docs
  → Phase 6 wrap.
- **Estimated wall-clock for 1 developer** : 4-6 hours of focused work
  (most YAML / JSON content is already verbatim in `design.md`, the
  bash harness is the only non-trivial new code).
- **Tests delivered** : 25 L1 + 5 L2 = 30 tests. Performance budget ≤ 3 s.
- **Files added** : ≤ 18 NEW + ≤ 6 modified per NFR-T4-002 budget.
