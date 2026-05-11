# Tasks: i2-compliance-tiers
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail
  (RED), write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-I2-CT-XXX]` (Article V.1, enforced
  by `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/i2.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms expected
  counter movement.
- ADRs from `design.md` (ADR-I2-CT-001..003) are honored verbatim
  ; deviations require a new ADR.

---

## Phase 1 — Foundation : RED harness + CI registration

Goal : `i2.test.sh` exists with **12 L1 stubs** all FAIL ; full
RED state captured ; CI registration done.

### T-HAR — `i2.test.sh` skeleton

- [ ] **T-HAR-001** : Create `.forge/scripts/tests/i2.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`, source `_helpers.sh`), PASS/FAIL
      counters reset, `--level 1` parsing, audit comment
      `<!-- Audit: I.2 (i2-compliance-tiers) -->`, `print_summary`
      close-out. Mirror the K.3 / J.8 layout.
      [Story: FR-I2-CT-100 / FR-I2-CT-101]
- [ ] **T-HAR-002** : Define the 8 path variables at the top of
      the harness (STD_FILE, INDEX_YML, REVIEW_MD, COMPLIANCE_DOC,
      CHANGELOG_MD, SCHEMA_FILE, DEMETER_AGENT, FORGE_ROOT_REAL)
      mirroring the K.3 / J.8 layout.
      [Story: FR-I2-CT-100]
- [ ] **T-HAR-003** : Add **12 L1 test stubs** all returning
      `_not_implemented` covering the 12 anchor IDs enumerated in
      `design.md` § "L1 unit-level" table. Plus the 2 optional
      tests (`_test_i2_013_compliance_doc`,
      `_test_i2_014_changelog_entry`) for a 14-total.
      [Story: FR-I2-CT-102 / FR-I2-CT-103 / FR-I2-CT-104]
- [ ] **T-HAR-004** [P] : Add the test runner — iterate through
      the 14 functions, call `run_test` on each, call
      `print_summary`. Exit 0 if FAIL == 0, else 1.
      [Story: FR-I2-CT-111]
- [ ] **T-HAR-005** [P] : Register `i2.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `k3.test.sh` with `--level 1`.
      [Story: FR-I2-CT-110]
- [ ] **T-HAR-006** : RED gate confirmed —
      `bash .forge/scripts/tests/i2.test.sh --level 1` exits 1
      with `Failed: 14 / Passed: 0`. [Story: FR-I2-CT-101]

### Phase 1 exit gate

`i2.test.sh --level 1` exits 1 with FAIL = 14. `forge-ci.yml`
matrix updated. `verify.sh` overall PASS unchanged.
`constitution-linter.sh` overall PASS unchanged.

---

## Phase 2 — Standard file authoring

Goal : `.forge/standards/global/compliance-tiers.md` ships with
all required H2 sections + frontmatter + matrix + Interdictions.
After this phase, 10 of the 14 L1 tests flip GREEN (everything
except the index-entry, REVIEW-entry, COMPLIANCE.md doc, and
CHANGELOG entry tests).

### T-STD — Standard file skeleton

- [ ] **T-STD-001** : RED witness — confirm
      `_test_i2_001..010` (10 tests) are still FAIL.
      [Story: FR-I2-CT-001..030]
- [ ] **T-STD-002** : Create
      `.forge/standards/global/compliance-tiers.md` with :
      - First 5 lines : audit comment
        `<!-- Audit: I.2 (i2-compliance-tiers) -->` + trigger
        comment `<!-- Trigger: compliance, t1, t2, t3, eu-tier,
        dpa, schrems, cloud-act, tier-classification -->`.
      - H1 : `# Standard — Compliance Tiers (T1 / T2 / T3)`.
      - Frontmatter narrative block (version, last_reviewed,
        expires_at, exception_constitutional, linter_rule,
        enforcement, forbidden, rationale).
      [Story: FR-I2-CT-001..010]

### T-PUR — Purpose H2

- [ ] **T-PUR-001** : Add `## Purpose` H2 citing :
      - K.3 / I.4 audit source.
      - The schema (`compliance-tier.schema.json` v1.0.0) as
        single source of truth.
      - The architecture doc (`docs/ARCHITECTURE-TARGET.md` §10).
      - Downstream items I.3 / I.5 / I.6.
      [Story: FR-I2-CT-021]

### T-DEF — Tier definitions H2 (verbatim citation)

- [ ] **T-DEF-001** : Add `## Tier definitions` H2 with **verbatim
      blockquoted** three strings from
      `compliance-tier.schema.json::x-tier-descriptions` :
      ```
      > **T1** — "RGPD-compliant via DPA — SaaS hors EU acceptable
      > si DPA + SCC + protections complémentaires (chiffrement,
      > BYOK), assume risque résiduel CLOUD Act."
      ```
      Same shape for T2 and T3. Cite the schema path + version
      explicitly under the third blockquote.
      [Story: FR-I2-CT-022 / NFR-I2-CT-004]

### T-MAT — Component eligibility matrix H2

- [ ] **T-MAT-001** : Add `## Component eligibility matrix` H2
      with the 15-row Markdown table per `design.md` § ADR-I2-CT-002.
      Header row : `| Composant | T1 | T2 | T3 | Forçage tier |`.
      All 15 component rows + the 4 source-citation footnotes
      (DBOS, Zitadel, Outscale, CLOUD Act).
      [Story: FR-I2-CT-023 / NFR-I2-CT-005]

### T-DEM — Demeter integration H2

- [ ] **T-DEM-001** : Add `## Demeter integration` H2 with :
      - Cross-link to `.claude/agents/demeter.md` (relative path).
      - Cross-link to
        `.forge/standards/global/data-stewardship-rules.md`.
      - Citation of FR-K3-DEM-068 (severity scaling : T1 →
        Informational, T2 → High, T3 → Critical).
      - Reference to K3-RULE-001..006 catalogue (with anchor
        URLs into `data-stewardship-rules.md`).
      - Reference to the `.forge/.forge-tier` ledger format
        (one line, content in `{T1, T2, T3}` + trailing newline).
      [Story: FR-I2-CT-024]

### T-ADP — Adoption path H2

- [ ] **T-ADP-001** : Add `## Adoption path` H2 with two tiers :
      - **Minimum viable adoption** : declare tier in
        `.forge/.forge-tier` ; run Demeter at PR time.
      - **Full adoption** : add `.forge/.forge-dpa-declared`
        when ⚠️-T1 components in scope ; wire Demeter into Janus
        Step 9 ; await Themis (K.5, T7+).
      [Story: FR-I2-CT-025]

### T-EXT — Extending the matrix H2

- [ ] **T-EXT-001** : Add `## Extending the matrix` H2 with
      two-phase governance :
      - **Phase A — BDFL interim** : SemVer minor bump for new
        component / tier shift ; SemVer major bump for
        `x-tier-descriptions` semantics change (requires Article
        XII Constitution amendment).
      - **Phase B — Themis (T7+)** : 6-month rolling review
        cadence per `data-stewardship-rules.md::Regeneration cadence`.
      [Story: FR-I2-CT-026]

### T-INT — Interdictions H2

- [ ] **T-INT-001** : Add `## Interdictions` H2 with ≥ 3 RFC-2119
      "MUST NOT" clauses :
      1. MUST NOT paraphrase the schema (verbatim citation
         invariant).
      2. MUST NOT add a new compliance tier without Article XII
         Constitution amendment.
      3. MUST NOT silently downgrade a declared T3 project to T1
         (explicit ledger edit required).
      Optional 4th : MUST NOT couple the standard to any cloud
      provider certification scheme beyond SecNumCloud / HDS /
      EUCS High as named in T3.
      [Story: FR-I2-CT-027 / FR-I2-CT-028]

### T-CC — Constitutional Compliance H2 (optional)

- [ ] **T-CC-001** [P] : Add `## Constitutional Compliance` H2
      listing Article III.4 (anti-hallucination), Article V (audit
      trail), Article XI (agent-native), Article XII (governance).
      Clarify : the standard does not amend any Article.
      [Story: FR-I2-CT-029]

### Phase 2 exit gate

10 of 14 L1 tests flip GREEN. `i2.test.sh --level 1` exits 1 with
`Failed: 4 / Passed: 10`. `verify.sh` overall PASS unchanged.
`constitution-linter.sh` overall PASS unchanged. The 4 remaining
RED tests : `_test_i2_011_index_entry`,
`_test_i2_012_review_entry`, `_test_i2_013_compliance_doc`,
`_test_i2_014_changelog_entry`.

---

## Phase 3 — Standards index + REVIEW + adopter doc

Goal : the 4 remaining RED tests flip GREEN.

### T-IDX — Standards index entry

- [ ] **T-IDX-001** : Edit `.forge/standards/index.yml` to append
      a new entry under the "K.3 — Demeter data stewardship"
      section :
      ```yaml
        - id: global/compliance-tiers
          path: standards/global/compliance-tiers.md
          triggers: [compliance, t1, t2, t3, eu-tier, dpa, schrems, cloud-act, tier-classification]
          scope: all
          priority: high
      ```
      Place after the existing `global/data-stewardship-rules`
      entry. [Story: FR-I2-CT-040..045]
- [ ] **T-IDX-002** : Run `i2.test.sh --level 1` ; expect
      `_test_i2_011_index_entry` flips GREEN. `verify.sh` must
      remain PASS (the new entry MUST point to an existing file,
      which it does after Phase 2). [Story: FR-I2-CT-040]

### T-RVW — REVIEW.md append-only entry

- [ ] **T-RVW-001** : Edit `.forge/standards/REVIEW.md` to append
      a new H2 section after the existing last entry :
      ```markdown
      ## 2026-05-11 — Initial ratification (i2-compliance-tiers)

      - **Reviewer**: @bfontaine
      - **Reviewed standards**:

        | Standard                      | Version | Decision | Next review due | Notes                                                                              |
        |-------------------------------|---------|----------|-----------------|------------------------------------------------------------------------------------|
        | global/compliance-tiers.md    | 1.0.0   | KEEP     | 2027-05-11      | Initial ratification. Codifies EU compliance gradient T1/T2/T3 from ARCH-TARGET §10. |

      - **Decision**: KEEP
      - **Next review due**: 2027-05-11
      - **Notes**: Resolves the Demeter forward-pointer (K.3,
        2026-05-10) and unblocks I.3 (T3-forbidden linter), I.5
        (forge-compliance.yml), I.6 (regulatory artefacts).
        Schema source-of-truth pin : compliance-tier.schema.json
        v1.0.0. Matrix mirrors ARCHITECTURE-TARGET §10.2 verbatim
        (ADR-I2-CT-002).
      ```
      [Story: FR-I2-CT-050..052]
- [ ] **T-RVW-002** : Run `i2.test.sh --level 1` ; expect
      `_test_i2_012_review_entry` flips GREEN.
      [Story: FR-I2-CT-050]

### T-DOC — `docs/COMPLIANCE.md` adopter intro

- [ ] **T-DOC-001** : Create `docs/COMPLIANCE.md` with :
      - H1 : `# Forge Compliance — EU Tier Adoption Guide`.
      - H2 `## Quick start` (declare tier in `.forge/.forge-tier`
        ; run `bash bin/forge-demeter-scan.sh --target $(pwd)
        --tier T2`).
      - H2 `## Tier picker` (decision tree pointing to the
        standard ; cite the three x-tier-descriptions
        verbatim — or refer the reader to the standard for the
        verbatim).
      - H2 `## Cross-references` (pointers to
        `docs/ARCHITECTURE-TARGET.md §10`,
        `.forge/standards/global/compliance-tiers.md`,
        `.forge/standards/global/data-stewardship-rules.md`,
        `.claude/agents/demeter.md`).
      - At least one cross-link to
        `.forge/standards/global/compliance-tiers.md`.
      [Story: FR-I2-CT-090..093]
- [ ] **T-DOC-002** : Run `i2.test.sh --level 1` ; expect
      `_test_i2_013_compliance_doc` flips GREEN.
      [Story: FR-I2-CT-090..092]

### Phase 3 exit gate

3 more L1 tests flip GREEN. `i2.test.sh --level 1` exits 1 with
`Failed: 1 / Passed: 13` (only CHANGELOG entry remaining).
`verify.sh` PASS. `constitution-linter.sh` PASS.

---

## Phase 4 — CHANGELOG + final verification

### T-LOG — CHANGELOG entry

- [ ] **T-LOG-001** : Edit `CHANGELOG.md` `## [Unreleased]`
      to add (immediately after the existing K.3 Demeter entry) :
      ```markdown
      ### Added — I.2 compliance-tiers standard (`i2-compliance-tiers`)

      Single human-readable standard codifying the EU compliance
      gradient T1 / T2 / T3 from `compliance-tier.schema.json`
      v1.0.0 (T.4) and `docs/ARCHITECTURE-TARGET.md` §10.

      - **`.forge/standards/global/compliance-tiers.md` v1.0.0**
        — 6+ H2 sections (Purpose / Tier definitions / Component
        eligibility matrix / Demeter integration / Adoption path /
        Extending the matrix / Interdictions), verbatim citation
        of the schema's `x-tier-descriptions` block, 15-row matrix
        mirroring §10.2 byte-for-byte, ≥ 3 RFC-2119 MUST NOT
        clauses (no paraphrase, no new tier without Article XII
        amendment, no silent T3 downgrade). Frontmatter pins
        `linter_rule: t3-forbidden-components` (forward-pointer
        to I.3 ; the matching `constitution-linter.sh` section
        anchor ships with I.3).
      - **`.forge/standards/index.yml` entry** — id
        `global/compliance-tiers`, 9 triggers (compliance, t1,
        t2, t3, eu-tier, dpa, schrems, cloud-act,
        tier-classification), scope all, priority high.
      - **`.forge/standards/REVIEW.md` append-only entry** dated
        2026-05-11, Initial ratification.
      - **`docs/COMPLIANCE.md`** — adopter-facing intro with 3
        H2 sections (Quick start / Tier picker /
        Cross-references).
      - **`.forge/scripts/tests/i2.test.sh`** — 14 L1 tests
        (12 minimum per FR-I2-CT-102 + 2 optional doc / CHANGELOG
        assertions). Registered in `forge-ci.yml` `harness`
        matrix after `k3.test.sh`.

      Three ADRs resolve the design open questions :
      `linter_rule` kebab-case forward-pointer (ADR-I2-CT-001) ;
      verbatim 15-row matrix (ADR-I2-CT-002) ; root
      `docs/COMPLIANCE.md` placement (ADR-I2-CT-003).

      Unblocks I.3 (T3-forbidden linter rule), I.5
      (forge-compliance.yml workflow), I.6 (regulatory artefacts
      — NIS2 / DORA / CRA / AI Act) per
      `docs/new-archetypes-plan.md` §7.1 + §10.

      No constitutional amendment required ; Articles III.4, V,
      XI, XII compliance preserved.
      ```
      [Story: FR-I2-CT-080..081]
- [ ] **T-LOG-002** : Run `i2.test.sh --level 1` ; expect
      `_test_i2_014_changelog_entry` flips GREEN. All 14 L1 tests
      GREEN. Exit 0. [Story: FR-I2-CT-080]

### T-GAT — Final gates

- [ ] **T-GAT-001** : `bash .forge/scripts/verify.sh` — overall
      PASS (additive change ; no regression).
      [Story: NFR-I2-CT-002]
- [ ] **T-GAT-002** : `bash .forge/scripts/constitution-linter.sh`
      — overall PASS (no `[NEEDS CLARIFICATION:]` inline in
      implemented changes ; no new Article touched).
      [Story: NFR-I2-CT-002]
- [ ] **T-GAT-003** : `bash bin/validate-standards-yaml.sh` —
      GREEN (the new standard is MD, not YAML — out of scope ;
      live tree baseline preserved per NFR-J7-002).
      [Story: FR-I2-CT-112]
- [ ] **T-GAT-004** : Status flip in `.forge.yaml` from `designed`
      / `planned` to `implemented`. Timeline updated.

### Phase 4 exit gate

All 14 L1 tests GREEN. All three gate scripts PASS. Status
flipped to `implemented`. The change is ready for `/forge:archive`
on user trigger.

---

## Task summary

| Phase | Tasks | Notes                                                                                     |
|-------|-------|-------------------------------------------------------------------------------------------|
| 1     | 6     | RED foundation : harness skeleton + 14 stubs + CI registration. All FAIL after Phase 1.  |
| 2     | 9     | Standard file authoring : 10 L1 tests flip GREEN after Phase 2.                          |
| 3     | 6     | Index + REVIEW + adopter doc : 3 more L1 tests flip GREEN.                               |
| 4     | 6     | CHANGELOG + final gates : final L1 test flips GREEN. All gates PASS. Status `implemented`. |
| **Total** | **27** | TDD discipline preserved ; immutable RED→GREEN→REFACTOR cycle ; 14 GREEN L1 tests at end. |
