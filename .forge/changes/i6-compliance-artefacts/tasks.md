# Tasks: i6-compliance-artefacts
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail
  (RED), write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-I6-CA-XXX]` (Article V.1, enforced
  by `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/i6.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms expected
  counter movement.
- ADRs from `design.md` (ADR-I6-CA-001..003) are honored verbatim
  ; deviations require a new ADR.

---

## Phase 1 — Foundation : RED harness + CI registration

Goal : `i6.test.sh` exists with **14 L1 + 2 L2 stubs** all FAIL
; full RED state captured ; CI registration done.

### T-HAR — `i6.test.sh` skeleton

- [ ] **T-HAR-001** : Create `.forge/scripts/tests/i6.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`), source `_helpers.sh`, PASS/FAIL
      counters reset, `--level` parsing for `1|2|1,2|all`,
      audit comment `# Audit: I.6 (i6-compliance-artefacts)`,
      `print_summary` close-out. Mirror the I.2 / J.8 layout.
      [Story: FR-I6-CA-100 / FR-I6-CA-101 / FR-I6-CA-112]
- [ ] **T-HAR-002** : Define the path variables at the top of the
      harness :
      - `BUNDLE_SCRIPT` → `.forge/scripts/compliance/bundle.sh`
      - `DPA_TEMPLATE` → `.forge/templates/compliance/forge-dpa-declared.template`
      - `STD_FILE` → `.forge/standards/global/compliance-artefacts-bundle.md`
      - `INDEX_YML` → `.forge/standards/index.yml`
      - `REVIEW_MD` → `.forge/standards/REVIEW.md`
      - `COMPLIANCE_DOC` → `docs/COMPLIANCE.md`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      - `SBOM_SCRIPT` → `bin/forge-sbom.sh`
      [Story: FR-I6-CA-100]
- [ ] **T-HAR-003** : Add **14 L1 test stubs** all returning
      `_not_implemented` covering the 14 anchor IDs in
      `design.md` § "L1 unit-level" table.
      [Story: FR-I6-CA-102]
- [ ] **T-HAR-004** [P] : Add **2 L2 test stubs**
      (`_test_i6_l2_bundle_good`, `_test_i6_l2_bundle_determinism`)
      all returning `_not_implemented`.
      [Story: FR-I6-CA-103]
- [ ] **T-HAR-005** : Add the test runner — iterate through the
      14 L1 functions, call `run_test`, gate L2 on `--level`
      containing `2` or `all`, call `print_summary`. Exit 0 if
      `FAIL == 0`, else 1. [Story: FR-I6-CA-111]
- [ ] **T-HAR-006** [P] : Register `i6.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `i2.test.sh` with `--level 1,2`. Keep
      the file under 300 lines (NFR-CI-002).
      [Story: FR-I6-CA-110]
- [ ] **T-HAR-007** : RED gate — confirm
      `bash .forge/scripts/tests/i6.test.sh --level 1,2` exits 1
      with `Failed: 16 / Passed: 0`. [Story: FR-I6-CA-111]

### Phase 1 exit gate

`i6.test.sh --level 1,2` exits 1 with FAIL = 16. `forge-ci.yml`
matrix updated, still under 300 lines. `verify.sh` overall PASS
unchanged. `constitution-linter.sh` overall PASS unchanged.

---

## Phase 2 — Script + template (production code)

Goal : the bundle script + DPA template ship. After this phase, 6
of 16 tests flip GREEN (script-presence / help / args / template
tests).

### T-SCR — Bundle script

- [ ] **T-SCR-001** : RED witness — confirm the 4 script-related
      L1 tests + the 2 L2 tests still FAIL.
      [Story: FR-I6-CA-001..020 / FR-I6-CA-l2-*]
- [ ] **T-SCR-002** : Create directory
      `.forge/scripts/compliance/`.
      [Story: FR-I6-CA-001 / ADR-I6-CA-003]
- [ ] **T-SCR-003** : Create
      `.forge/scripts/compliance/bundle.sh` with bash header
      (`#!/usr/bin/env bash`, `set -uo pipefail`), audit comment
      `# <!-- Audit: I.6 (i6-compliance-artefacts) -->`, usage
      block, while-case arg parser accepting `--output`,
      `--target`, `--help`/`-h`. Bogus arg → stderr + exit 2.
      [Story: FR-I6-CA-001..006]
- [ ] **T-SCR-004** : Add source-artefact validation block (the 4
      paths from FR-I6-CA-007) ; emit `forge-compliance-bundle:
      missing source artefact: <path>` + exit 1 on miss.
      [Story: FR-I6-CA-007]
- [ ] **T-SCR-005** : Add Python 3 inline heredoc
      (`python3 - "$TARGET" "$OUTPUT" <<'PY' ... PY`) that :
      1. Imports `tarfile`, `gzip`, `io`, `hashlib`, `json`,
         `datetime`, `os`, `sys`, `pathlib`, `yaml` (PyYAML).
      2. Reads the 6 source artefacts.
      3. Builds the audit ledger snapshot (JSON + Markdown)
         per FR-I6-CA-013..017.
      4. Invokes `bash bin/forge-sbom.sh --target <target>
         --output <tmpfile>` and captures the SBOM bytes.
      5. Builds the 6 bundle members in memory, sorted by member
         path.
      6. Generates `MANIFEST` per FR-I6-CA-009.
      7. Writes the `.tgz` using the two-step idiom (BytesIO +
         gzip.GzipFile with `mtime=epoch`).
      [Story: FR-I6-CA-008..020 / NFR-I6-CA-004..006 / ADR-I6-CA-001]
- [ ] **T-SCR-006** : Make `bundle.sh` executable
      (`chmod +x .forge/scripts/compliance/bundle.sh`).
      [Story: FR-I6-CA-001]
- [ ] **T-SCR-007** : GREEN witness — run
      `bash .forge/scripts/tests/i6.test.sh --level 1` ; expect
      `_test_i6_001..004` flip GREEN. [Story: FR-I6-CA-001..006]

### T-TPL — DPA template

- [ ] **T-TPL-001** : RED witness — confirm
      `_test_i6_010_template_presence` + `_test_i6_011_template_example`
      still FAIL. [Story: FR-I6-CA-030..035]
- [ ] **T-TPL-002** : Create directory
      `.forge/templates/compliance/`.
      [Story: FR-I6-CA-030]
- [ ] **T-TPL-003** [P] : Create
      `.forge/templates/compliance/forge-dpa-declared.template`
      with :
      - `# <!-- Audit: I.6 (i6-compliance-artefacts) -->` within
        first 5 lines.
      - Cross-references to `ADR-K3-002`,
        `global/data-stewardship-rules.md`, `K3-RULE-002`,
        `K3-RULE-002a` (staleness), and the 13-month + 1-month
        grace window.
      - The canonical example line
        `T1: 2026-04-15 LegalOps-Confluence-DPA-2026-Q2`
        prefixed by `# Example:` comment.
      [Story: FR-I6-CA-030..035]
- [ ] **T-TPL-004** : GREEN witness — run
      `bash .forge/scripts/tests/i6.test.sh --level 1` ; expect
      `_test_i6_010..011` flip GREEN. [Story: FR-I6-CA-030..035]

### Phase 2 exit gate

6 of 16 tests GREEN (4 script + 2 template). `i6.test.sh --level
1,2` exits 1 with `Failed: 10 / Passed: 6`. `verify.sh` overall
PASS unchanged. `constitution-linter.sh` overall PASS unchanged.

---

## Phase 3 — Standard + index + REVIEW + docs

Goal : standard + index entry + REVIEW.md entry + docs/COMPLIANCE.md
update + new-archetypes-plan + roadmap. After this phase, 12 of 16
tests flip GREEN.

### T-STD — Standard file

- [ ] **T-STD-001** : RED witness — confirm `_test_i6_020..023`
      still FAIL. [Story: FR-I6-CA-040..055]
- [ ] **T-STD-002** : Create
      `.forge/standards/global/compliance-artefacts-bundle.md`
      with :
      - First 5 lines : audit comment
        `<!-- Audit: I.6 (i6-compliance-artefacts) -->` +
        trigger comment `<!-- Trigger: compliance, bundle,
        auditor, dpa, audit-ledger, nis2, dora, cra, ai-act,
        regulatory-handoff -->`.
      - H1 : `# Standard — Compliance Artefacts Bundle`.
      - Frontmatter narrative block (version 1.0.0,
        last_reviewed 2026-05-12, expires_at 2027-05-12,
        exception_constitutional false, linter_rule null,
        enforcement, rationale).
      - 6 H2 sections : Purpose & EU compliance rationale ;
        Bundle content schema (6-row table) ; Determinism
        guarantee (SOURCE_DATE_EPOCH) ; Consumption protocol
        (I.5 forward reference) ; Regeneration cadence (per
        release + on demand + reproducibly) ; Interdictions (≥
        3 MUST NOT).
      - Demeter cross-link, forward-compatibility note for
        Themis-territory expansion.
      [Story: FR-I6-CA-040..055]
- [ ] **T-STD-003** : GREEN witness — run
      `bash .forge/scripts/tests/i6.test.sh --level 1` ; expect
      `_test_i6_020..023` flip GREEN.
      [Story: FR-I6-CA-040..055]

### T-IDX — Standards index entry

- [ ] **T-IDX-001** : Edit `.forge/standards/index.yml` to append
      a new entry under a new comment section header `# ─── I.6
      — Compliance artefacts bundle (i6-compliance-artefacts)
      ─────────────────────` mirroring the existing I.2 header :
      ```yaml
        - id: global/compliance-artefacts-bundle
          path: standards/global/compliance-artefacts-bundle.md
          triggers: [compliance, bundle, auditor, dpa, audit-ledger, nis2, dora, cra, ai-act, regulatory-handoff]
          scope: all
          priority: high
      ```
      Place after the existing `global/compliance-tiers` entry.
      [Story: FR-I6-CA-060..064]
- [ ] **T-IDX-002** : GREEN witness — run
      `bash .forge/scripts/tests/i6.test.sh --level 1` ; expect
      `_test_i6_030_index_entry` flips GREEN. [Story: FR-I6-CA-060]

### T-RVW — REVIEW.md entry

- [ ] **T-RVW-001** : Edit `.forge/standards/REVIEW.md` to append
      a new H2 section after the last entry :
      ```markdown
      ## 2026-05-12 — Initial ratification (i6-compliance-artefacts)

      - **Reviewer**: @bfontaine
      - **Reviewed standards**:

        | Standard                              | Version | Decision | Next review due | Notes                                                                                       |
        |---------------------------------------|---------|----------|-----------------|---------------------------------------------------------------------------------------------|
        | global/compliance-artefacts-bundle.md | 1.0.0   | KEEP     | 2027-05-12      | Initial ratification. Documents the deterministic .tgz hand-off bundle for EU regulators.   |

      - **Decision**: KEEP
      - **Next review due**: 2027-05-12
      - **Notes**: New standard at `global/compliance-artefacts-bundle.md`
        cross-linking the bundle script
        (`.forge/scripts/compliance/bundle.sh`), the DPA template
        (`.forge/templates/compliance/forge-dpa-declared.template`),
        and the audit-ledger snapshot generator (inline inside
        the bundle script). Consumes I.2 (tier matrix), K.3 (DPA
        ledger format), J.8 (`bin/forge-sbom.sh`). Forward-stable
        for Themis-territory artefacts (NIS2 / DORA / CRA / AI Act)
        per FR-I6-CA-053. Three ADRs (ADR-I6-CA-001..003) resolve
        archive format + ledger placement + script location. No
        constitutional amendment required.
      ```
      [Story: FR-I6-CA-070..071]
- [ ] **T-RVW-002** : GREEN witness — run
      `bash .forge/scripts/tests/i6.test.sh --level 1` ; expect
      `_test_i6_031_review_entry` flips GREEN.
      [Story: FR-I6-CA-070]

### T-DOC — `docs/COMPLIANCE.md` update

- [ ] **T-DOC-001** : Edit `docs/COMPLIANCE.md` to append a fourth
      H2 section `## Auditor hand-off bundle` after the existing
      `## Cross-references` H2, cross-linking the bundle script +
      the standard, mentioning `SOURCE_DATE_EPOCH` as the
      determinism input. [Story: FR-I6-CA-080..082]
- [ ] **T-DOC-002** : GREEN witness — run
      `bash .forge/scripts/tests/i6.test.sh --level 1` ; expect
      `_test_i6_040_compliance_doc_h2` flips GREEN.
      [Story: FR-I6-CA-080..082]

### Phase 3 exit gate

12 of 16 tests GREEN. `i6.test.sh --level 1,2` exits 1 with
`Failed: 4 / Passed: 12`. `verify.sh` overall PASS unchanged.
`constitution-linter.sh` overall PASS unchanged. The 4 remaining
RED tests : `_test_i6_041_changelog_entry`,
`_test_i6_l2_bundle_good`, `_test_i6_l2_bundle_determinism`, and
the inventory delta tests are folded into the same final phase.

---

## Phase 4 — Roadmap + plan + CHANGELOG

### T-LOG — CHANGELOG entry

- [ ] **T-LOG-001** : Edit `CHANGELOG.md` `## [Unreleased]` to
      add (immediately after the existing I.2 entry) :
      ```markdown
      ### Added — I.6 compliance artefacts bundle (`i6-compliance-artefacts`)

      Deterministic `.tgz` regulatory hand-off bundle generator
      for EU auditor counter-parties.

      - **`.forge/scripts/compliance/bundle.sh`** — bash thin +
        Python 3 inline (mirrors `bin/forge-sbom.sh` pattern).
        Six members : MANIFEST + tier-matrix +
        forge-dpa-declared template + audit-ledger (JSON + MD)
        + SBOM. Determinism via `SOURCE_DATE_EPOCH`.
      - **`.forge/templates/compliance/forge-dpa-declared.template`**
        — canonical DPA declaration template mirroring K.3
        ADR-K3-002 format. Cross-references K3-RULE-002 +
        K3-RULE-002a staleness window.
      - **`.forge/standards/global/compliance-artefacts-bundle.md`
        v1.0.0** — 6 H2 sections (Purpose / Bundle content
        schema / Determinism guarantee / Consumption protocol /
        Regeneration cadence / Interdictions) + ≥ 3 MUST NOT
        clauses + Constitutional Compliance section. Frontmatter
        pins `version: 1.0.0`, `last_reviewed: 2026-05-12`,
        `expires_at: 2027-05-12`, `linter_rule: null`.
      - **`.forge/standards/index.yml` entry** — id
        `global/compliance-artefacts-bundle`, 10 triggers,
        scope all, priority high.
      - **`.forge/standards/REVIEW.md` birth entry** dated
        2026-05-12, Initial ratification.
      - **`docs/COMPLIANCE.md`** — new H2 `## Auditor hand-off
        bundle` with cross-links.
      - **`.forge/scripts/tests/i6.test.sh`** — 14 L1 + 2 L2
        tests (bundle-good fixture + determinism via
        `SOURCE_DATE_EPOCH=0` × 2 invocations + `diff -q`).
        Registered in `forge-ci.yml` `harness` matrix.

      Three ADRs resolve the design open questions :
      `.tgz` gzip POSIX tar format (ADR-I6-CA-001) ; `audit/`
      subdirectory layout (ADR-I6-CA-002) ; script location
      `.forge/scripts/compliance/bundle.sh` (ADR-I6-CA-003).

      Forward-stable for Themis-territory artefacts (NIS2 / DORA /
      CRA / AI Act) — additive expansion per FR-I6-CA-053.

      No constitutional amendment required ; Articles III.4, V,
      XI, XII compliance preserved.
      ```
      [Story: FR-I6-CA-092]
- [ ] **T-LOG-002** : GREEN witness — run
      `bash .forge/scripts/tests/i6.test.sh --level 1` ; expect
      `_test_i6_041_changelog_entry` flips GREEN.
      [Story: FR-I6-CA-092]

### T-INV — Plan + roadmap inventory delta

- [ ] **T-INV-001** [P] : Update `docs/new-archetypes-plan.md`
      row I.6 (line ~398 + line ~548 + line ~1067 + line ~1234)
      to record **I.6 Done 2026-05-12** with the change name
      citation. [Story: FR-I6-CA-090]
- [ ] **T-INV-002** [P] : Update `.forge/product/roadmap.md`
      inventory line 129 + line 166 + line 186 + line 225 to
      record the I.6 delivery, mirroring the existing "I.2
      done" line style. [Story: FR-I6-CA-091]

### Phase 4 exit gate

13 of 16 tests GREEN (CHANGELOG flipped). L2 tests still RED.
Inventory and plan updates done.

---

## Phase 5 — L2 fixtures + final gates

Goal : the two L2 fixture tests flip GREEN ; final gates pass ;
status flipped to `implemented`.

### T-L2 — L2 fixture tests

- [ ] **T-L2-001** : Replace
      `_test_i6_l2_bundle_good`'s `_not_implemented` body with
      the real fixture-based test :
      1. `_setup_l2` creates a tmpdir with the minimum
         compliance source tree.
      2. Run `bash .forge/scripts/compliance/bundle.sh --target
         <tmpdir> --output <tmpdir>/bundle.tgz`.
      3. Assert exit 0 + `bundle.tgz` present + 6 members
         (`tar -tzf bundle.tgz | wc -l == 6`) + `MANIFEST`
         entry present + sorted.
      [Story: FR-I6-CA-103 / FR-I6-CA-008..020]
- [ ] **T-L2-002** : Replace
      `_test_i6_l2_bundle_determinism`'s `_not_implemented`
      body :
      1. `_setup_l2` (same tmpdir layout).
      2. Run bundle twice with `SOURCE_DATE_EPOCH=0`, outputs
         `bundle1.tgz` and `bundle2.tgz`.
      3. Assert both runs exit 0 + `diff -q bundle1.tgz
         bundle2.tgz` exit 0.
      [Story: NFR-I6-CA-005]
- [ ] **T-L2-003** : Run `bash .forge/scripts/tests/i6.test.sh
      --level 1,2` — expect all 16 GREEN. Exit 0.
      [Story: FR-I6-CA-111]

### T-GAT — Final gates

- [ ] **T-GAT-001** : `bash .forge/scripts/verify.sh` — overall
      PASS (additive ; no regression ; Passed ≥ 185, Failed = 0).
      [Story: NFR-I6-CA-002 / NFR-I6-CA-009]
- [ ] **T-GAT-002** : `bash .forge/scripts/constitution-linter.sh`
      — OVERALL PASS (no `[NEEDS CLARIFICATION:]` inline ; no
      new Article touched). [Story: NFR-I6-CA-009]
- [ ] **T-GAT-003** : `bash bin/validate-standards-yaml.sh` —
      GREEN (the new standard is MD, not YAML — out of scope ;
      live tree baseline preserved per NFR-J7-002 / NFR-I2-CT-007).
- [ ] **T-GAT-004** : Status flip in `.forge.yaml` from
      `designed` / `planned` to `implemented`. Timeline
      populated with `specified`, `designed`, `planned`,
      `implemented` dates all = 2026-05-12.
- [ ] **T-GAT-005** : `wc -l .github/workflows/forge-ci.yml`
      under 300 (NFR-CI-002 / NFR-I6-CA-007).

### Phase 5 exit gate

All 16 tests GREEN. All three gate scripts PASS. Status flipped
to `implemented`. The change is ready for `/forge:archive` on
user trigger.

---

## Task summary

| Phase | Tasks | Notes                                                                                              |
|-------|-------|----------------------------------------------------------------------------------------------------|
| 1     | 7     | RED foundation : harness skeleton + 16 stubs + CI registration. All FAIL after Phase 1.            |
| 2     | 11    | Script + template : 6 L1 tests flip GREEN after Phase 2.                                           |
| 3     | 9     | Standard + index + REVIEW + docs : 6 more L1 tests flip GREEN.                                     |
| 4     | 4     | CHANGELOG + plan + roadmap inventory : 1 more L1 test GREEN ; inventory delta recorded.            |
| 5     | 8     | L2 fixtures + final gates : last 2 tests GREEN ; verify / constitution-linter PASS ; status flipped. |
| **Total** | **39** | TDD discipline preserved ; immutable RED→GREEN→REFACTOR cycle ; 16 GREEN tests at end.        |
