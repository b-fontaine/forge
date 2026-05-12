# Tasks: i3-t3-forbidden-linter
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail
  (RED), write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-I3-T3F-XXX]` (Article V.1,
  enforced by `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in
  the **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/i3.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms
  expected counter movement.
- ADRs from `design.md` (ADR-I3-001..004) are honored
  verbatim ; deviations require a new ADR.

---

## Phase 1 — Foundation : RED harness skeleton

Goal : `i3.test.sh` exists with **14 L1 + 4 L2** stubs all
FAIL ; CI registration done ; full RED state captured.

### T-PHA — i3.test.sh skeleton

- [x] **T-PHA-001** : Create `.forge/scripts/tests/i3.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`, source `_helpers.sh`), PASS/FAIL
      counters reset, `--level 1,2` parsing, `print_summary`
      close-out. Mirror the K.3 / I.2 layout.
      [Story: FR-I3-T3F-060]
- [x] **T-PHA-002** : Add **14 L1 test stubs** returning
      `_not_implemented` covering the 14 anchor IDs
      enumerated in `design.md` § "L1 unit-level" table.
      [Story: FR-I3-T3F-061]
- [x] **T-PHA-003** [P] : Add **4 L2 fixture stubs**
      (`_test_i3_l2_t3_pubspec`, `_test_i3_l2_t3_cargo`,
      `_test_i3_l2_t1_warn_only`, `_test_i3_l2_no_tier_na`)
      using `mk_tmpdir_with_trap`. [Story: FR-I3-T3F-062]
- [x] **T-PHA-004** [P] : Register `i3.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `i2.test.sh` with `--level 1,2`.
      Confirm file ≤ 300 lines after addition.
      [Story: FR-I3-T3F-100 / 101 / NFR-I3-T3F-009]
- [x] **T-PHA-005** : RED gate confirmed —
      `bash .forge/scripts/tests/i3.test.sh --level 1,2`
      exits 1 with `Failed: 18 / Passed: 0`.
      [Story: FR-I3-T3F-061]

**Phase 1 exit gate** : `i3.test.sh --level 1,2` exits 1
with `FAIL ≥ 18`, `forge-ci.yml` matrix updated.
constitution-linter.sh OVERALL PASS unchanged.

---

## Phase 2 — I.3.a : Linter section in `constitution-linter.sh`

Goal : new section ships with tier discovery + standards
walk + forbidden-token scan + violation emission. After this
phase, 7 L1 tests flip GREEN
(`_test_i3_001..007`) AND the 4 L2 fixtures flip GREEN.

### T-LIN — Linter section implementation

- [x] **T-LIN-001** : RED witness — convert
      `_test_i3_001_linter_section_anchor` +
      `_test_i3_002_linter_section_echo`.
      [Story: FR-I3-T3F-001]
- [x] **T-LIN-002** : Add the new section to
      `.forge/scripts/constitution-linter.sh` per ADR-I3-001
      placement (after ADR-006 NSMA, before Article III.4).
      Section header :
      ```
      # ── ADR-I3-001: T3-Forbidden Components — generic forbidden discovery ──
      # I.3 (i3-t3-forbidden-linter). Generic enforcement of standards'
      # forbidden: blocks, tier-scaled per ADR-I3-003. Opt-out via
      # FORGE_LINTER_SKIP_T3_FORBIDDEN=1.
      echo ""
      echo "T3-Forbidden Components (I.3 — generic forbidden enforcement):"
      ```
      [Story: FR-I3-T3F-001 / 002 / ADR-I3-001]
- [x] **T-LIN-003** : Implement opt-out branch — when
      `FORGE_LINTER_SKIP_T3_FORBIDDEN=1`, emit
      `not_applicable "  skipped via FORGE_LINTER_SKIP_T3_FORBIDDEN"`
      and return. [Story: FR-I3-T3F-002 / NFR-I3-T3F-004]
- [x] **T-LIN-004** : Implement tier discovery — read
      `.forge/.forge-tier` ; fallback to `FORGE_EU_TIER`
      env ; both absent → `not_applicable` per FR-I3-T3F-126.
      [Story: FR-I3-T3F-003 / 126]
- [x] **T-LIN-005** : Implement standards discovery —
      Python 3 inline walks `.forge/standards/**/*.yaml`
      and `.forge/standards/**/*.md` ; parses `forbidden:`
      block (YAML inline list OR block list) ; skips
      `forbidden: []` (empty). Honour NSMA interlock per
      NFR-I3-T3F-001 : exclude `state-management.yaml`
      when ADR-006 section is active.
      [Story: FR-I3-T3F-004 / 005 / NFR-I3-T3F-001]
- [x] **T-LIN-006** [P] : Implement working-tree scan —
      for each `(standard, token, tier)` triple :
      - manifest scan : `pubspec.yaml`, `package.json`,
        `Cargo.toml`, `requirements.txt`, `go.mod`
        (exact-key match per ecosystem).
      - doc-body scan : `docs/**/*.md` and
        `.forge/changes/**/*.md` (whole-word boundary
        regex per NFR-I3-T3F-007 ; self-exclusion of
        `.forge/changes/i3-t3-forbidden-linter/` per
        FR-I3-T3F-022).
      - standards self-scan : `.forge/standards/**/*.md`
        excluding the standard owning the token and
        `forbidden-components-rules.md` (T3-RULE-006).
      Honour `examples/` exclusion per FR-I3-T3F-026.
      [Story: FR-I3-T3F-020..026]
- [x] **T-LIN-007** : Implement violation emission —
      tier-scaled per FR-I3-T3F-006 :
      - T1 / T2 → `warn "  [REFUSAL: T3-RULE-NNN: ...]"`.
      - T3 → `fail "  [REFUSAL: T3-RULE-NNN: ...]"`.
      Rule-ID mapping per Cluster 9 :
      `identity.yaml` → T3-RULE-001, `observability.yaml`
      → T3-RULE-002, `orchestration.yaml` → T3-RULE-003,
      `state-management.yaml` → T3-RULE-004 (NSMA interlock),
      `compliance-tiers.md` → T3-RULE-005, cross-standard
      mention → T3-RULE-006.
      Remediation hint per token from a small inline map.
      [Story: FR-I3-T3F-006 / 007 / 120..125]
- [x] **T-LIN-008** [P] : Implement clean-tree pass message
      per FR-I3-T3F-008 : `pass "  no forbidden components
      detected at <tier> across <N> standards / <M> scanned
      files"`. [Story: FR-I3-T3F-008]
- [x] **T-LIN-009** : Run `i3.test.sh --level 1,2` ; expect
      7 L1 tests (001..007) + 4 L2 tests flip GREEN.
      [Story: FR-I3-T3F-001..008 / 020..026 / 120..126]

**Phase 2 exit gate** : 7 L1 + 4 L2 = 11 tests GREEN
(cumulative 11/18). `verify.sh` aggregate preserved (new
section adds zero FAIL on the Forge repo since no tier is
declared by default — N/A). `constitution-linter.sh`
OVERALL PASS preserved.

---

## Phase 3 — I.3.b : Rule-catalogue standard

Goal : new MD standard ships + index registration + REVIEW
birth entry + compliance-tiers.md delta. After this phase,
5 L1 tests flip GREEN (`_test_i3_008..012`).

### T-STD — `forbidden-components-rules.md` standard

- [x] **T-STD-001** : RED witness — convert
      `_test_i3_008_standard_exists`. [Story: FR-I3-T3F-040 / 041]
- [x] **T-STD-002** : Create
      `.forge/standards/global/forbidden-components-rules.md`
      with frontmatter per FR-I3-T3F-041 (version 1.0.0,
      `linter_rule: t3-forbidden-components`, `enforcement: ci`,
      `forbidden: []`) and 6 H2 sections per FR-I3-T3F-042 :
      - Purpose (cite I.3 audit + Article XII §enforce).
      - Rule catalogue (T3-RULE-001..007 table per
        FR-I3-T3F-043).
      - Severity scaling (T1/T2/T3 matrix per ADR-I3-003).
      - Adoption path (mirror `data-stewardship-rules.md`
        adoption path shape).
      - Extending the catalogue (per ADR-J8-004
        inheritance ; future T3-RULE-008+ slots ;
        forward-pointers to T6 standards refactor for the
        `persistence.yaml::forbidden_for_eu_strict:` gap
        per ADR-I3-004).
      - Opt-out env vars (`FORGE_LINTER_SKIP_T3_FORBIDDEN`,
        interlock with `FORGE_LINTER_SKIP_NSMA`).
      Audit footer citing the upstream sources per
      FR-I3-T3F-082. [Story: FR-I3-T3F-040..043 / 082 /
      ADR-I3-002 / 003 / 004]
- [x] **T-STD-003** : Run `i3.test.sh` ; expect standard
      L1 tests flip GREEN. [Story: FR-I3-T3F-040..043]

### T-IDX — Standards index + REVIEW birth

- [x] **T-IDX-001** : RED witness — convert
      `_test_i3_011_index_entry` + `_test_i3_012_review_entry`.
      [Story: FR-I3-T3F-044 / 045]
- [x] **T-IDX-002** : Edit `.forge/standards/index.yml` to
      add a new entry under the I.2 section :
      ```yaml
      - id: global/forbidden-components-rules
        path: standards/global/forbidden-components-rules.md
        triggers: [forbidden, t3-forbidden, t3-rule, linter, t1, t2, t3, eu-tier, ci-enforcement, forbidden-components]
        scope: all
        priority: high
      ```
      [Story: FR-I3-T3F-044]
- [x] **T-IDX-003** : Edit `.forge/standards/REVIEW.md` to
      append :
      ```markdown
      ## 2026-05-12 — Initial ratification (i3-t3-forbidden-linter)

      - **Reviewer**: @bfontaine
      - **Reviewed standards**:
        | Standard                            | Version | Decision | Next review due |
        |-------------------------------------|---------|----------|-----------------|
        | global/forbidden-components-rules.md | 1.0.0   | KEEP     | 2027-05-12      |
      - **Decision**: KEEP — new standard ratified under
        Constitution v1.1.0 via change `i3-t3-forbidden-linter`.
      ```
      [Story: FR-I3-T3F-045]
- [x] **T-IDX-004** : Run `i3.test.sh` ; expect index + REVIEW
      L1 tests flip GREEN. [Story: FR-I3-T3F-044 / 045]

### T-CTM — compliance-tiers.md delta (Article IV.1)

- [x] **T-CTM-001** : RED witness — convert
      `_test_i3_013_compliance_tiers_flip`.
      [Story: FR-I3-T3F-046]
- [x] **T-CTM-002** : Edit
      `.forge/standards/global/compliance-tiers.md` :
      - Frontmatter : `enforcement: review` →
        `enforcement: ci`.
      - "Status note" block (lines 20-26) : update the
        prose from "the I.3 linter rule that has not
        shipped yet" to "I.3 linter rule shipped
        2026-05-12 via i3-t3-forbidden-linter".
      Article IV.1 delta — preserve every other byte of
      the file. [Story: FR-I3-T3F-046 / ADR-I3-001]
- [x] **T-CTM-003** : Run `i2.test.sh --level 1` ; expect
      14/14 still GREEN (the i2 harness asserts
      `linter_rule: t3-forbidden-components` is present —
      the flip preserves it). Run `i3.test.sh` ; expect
      the flip L1 test flip GREEN. [Story: FR-I3-T3F-046]

**Phase 3 exit gate** : 5 L1 tests GREEN (cumulative
16/18). `i2.test.sh` 14/14 preserved (no regression).
`verify.sh` aggregate ≥ baseline (new standard +1 PASS).
`constitution-linter.sh` OVERALL PASS preserved.

---

## Phase 4 — I.3.c : Docs + open-questions flip

Goal : `docs/LINTING.md` H2 + CHANGELOG entry + roadmap
update + plan-doc row I.3 marked done. After this phase,
the remaining L1 test flips GREEN
(`_test_i3_014`).

### T-DOC — Documentation

- [x] **T-DOC-001** : RED witness — convert
      `_test_i3_014_linting_md_section`.
      [Story: FR-I3-T3F-080]
- [x] **T-DOC-002** : Add a new H2 section
      `## ADR-I3-001 — T3-Forbidden Components (I.3)` to
      `docs/LINTING.md` covering : what the rule
      enforces, 7-rule catalogue cross-link, opt-out env
      var, severity matrix, Article XII §enforce
      cross-reference. [Story: FR-I3-T3F-080]
- [x] **T-DOC-003** [P] : Add `## [Unreleased]` entry in
      `CHANGELOG.md` covering the linter section + the
      new standard + CI registration.
      [Story: FR-I3-T3F-081]
- [x] **T-DOC-004** [P] : Update
      `docs/new-archetypes-plan.md` row I.3 in §7.1 with a
      "Done 2026-05-12 via i3-t3-forbidden-linter" marker
      mirroring the I.2 row pattern. [Story: FR-I3-T3F-083]
- [x] **T-DOC-005** [P] : Update `.forge/product/roadmap.md`
      T5 row + Status row to reflect I.3 as
      "Done 2026-05-12 via i3-t3-forbidden-linter".
      [Story: FR-I3-T3F-084]
- [x] **T-DOC-006** : Run `i3.test.sh --level 1,2` ;
      expect 18/18 GREEN. [Story: FR-I3-T3F-080 / 061..062]

**Phase 4 exit gate** : `i3.test.sh --level 1,2` 18/18
GREEN (14 L1 + 4 L2). All ADRs honored. `verify.sh`
aggregate ≥ baseline. `constitution-linter.sh` OVERALL
PASS.

---

## Phase 5 — Quality : final gates + open-questions flip + archive

### T-OQ — Open-questions flip

- [x] **T-OQ-001** : Verify
      `.forge/changes/i3-t3-forbidden-linter/open-questions.md`
      has Q-001 / Q-002 / Q-003 with `Status: answered`
      and `### Resolution` blocks citing ADR-I3-002 /
      ADR-I3-003 / ADR-I3-004 verbatim. (Already authored
      at design time.) [Story: Article III.4]

### T-REV — Quality review gate

- [x] **T-REV-001** : Run
      `bash .forge/scripts/tests/i3.test.sh --level 1,2` ;
      expect 18 PASS / 0 FAIL. [Story: NFR-I3-T3F-005]
- [x] **T-REV-002** : Run
      `bash .forge/scripts/constitution-linter.sh` ;
      expect OVERALL PASS, the new section either
      `not_applicable` (no tier declared on the Forge
      repo) or `pass` (clean tree). [Story: Article XII]
- [x] **T-REV-003** : Run `bash .forge/scripts/verify.sh` ;
      expect RESULT: PASS, FAIL = 0. [Story: NFR-I3-T3F-002]
- [x] **T-REV-004** : Run `bash .forge/scripts/tests/i2.test.sh
      --level 1` ; expect 14/14 PASS (no regression).
      [Story: NFR-I3-T3F-002]
- [x] **T-REV-005** : Run `bash .forge/scripts/tests/k3.test.sh
      --level 1` ; expect 20/20 PASS (no regression).
      [Story: NFR-I3-T3F-002]
- [x] **T-REV-006** : Run `bash .forge/scripts/tests/j8.test.sh
      --level 1` ; expect 18/18 PASS (no regression).
      [Story: NFR-I3-T3F-002]
- [x] **T-REV-007** : Verify `.github/workflows/forge-ci.yml`
      ≤ 300 lines. [Story: NFR-I3-T3F-009]

### T-ARC — Archive

- [x] **T-ARC-001** : Flip
      `.forge/changes/i3-t3-forbidden-linter/.forge.yaml`
      `status: planned` → `status: implemented` and
      add `implemented:` timeline entry.

**Phase 5 exit gate (= change archival readiness)** :

- `i3.test.sh --level 1,2` 18/18 PASS / 0 FAIL.
- `verify.sh` RESULT: PASS / FAIL: 0.
- `constitution-linter.sh` OVERALL PASS (no new FAIL ; new
  section is N/A on the Forge repo without a tier ledger).
- `i2.test.sh` 14/14 preserved (frontmatter flip preserves
  `linter_rule: t3-forbidden-components` anchor).
- `j8.test.sh` 18/18 preserved.
- `k3.test.sh` 20/20 preserved.
- `forge-ci.yml` ≤ 300 lines.
- 3 BDD scenarios reproducible from L2 fixtures.
- All FR-I3-T3F-001..126 + NFR-I3-T3F-001..009 tasks
  checked.
- `CHANGELOG.md` entry under `## [Unreleased]`.
- `docs/LINTING.md` ADR-I3-001 H2 added.
- `docs/new-archetypes-plan.md` row I.3 marked done.
- `.forge/product/roadmap.md` T5 row updated.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 5     | 2                    | 18 stubs      |
| 2     | 9     | 2                    | 7 (per cluster) |
| 3     | 10    | 0                    | 4 (per cluster) |
| 4     | 6     | 3                    | 1 (per cluster) |
| 5     | 8     | 0                    | 0 (validation only) |
| **Total** | **38** | **7** | **30 RED witnesses** |
