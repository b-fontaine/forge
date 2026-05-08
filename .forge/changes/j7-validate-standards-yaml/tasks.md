# Tasks: j7-validate-standards-yaml
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-J7-XXX]` (Article V.1) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/j7.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms the expected
  counter movement.
- ADRs from `design.md` are honored verbatim ; deviations require a
  new ADR in this file.
- F.2 (`validate-change-yaml.sh`) is the **template** ; if a stretch
  of code can be lifted, lift it (cite the F.2 line numbers in the
  commit message).

---

## Phase 1 — Foundation : RED harness + schema skeleton

Goal : `j7.test.sh` exists with **≥ 16 L1 + 3 L2** stubs all FAIL ;
empty `standard.schema.json` exists ; full RED state captured.

### T-PHA — j7.test.sh skeleton

- [ ] **T-PHA-001** : Create `.forge/scripts/tests/j7.test.sh` with
      bash header (`#!/usr/bin/env bash`, `set -uo pipefail`, source
      `_helpers.sh`), PASS/FAIL counters reset, `--level 1,2` parsing
      mirrored from `t5.test.sh`, `print_summary` call. [Story: FR-J7-080]
- [ ] **T-PHA-002** : Add **16 L1 test stubs** (`_test_j7_001` →
      `_test_j7_050`, the 16 IDs enumerated in `design.md` §Testing
      Strategy table). Each stub returns `_not_implemented` (RED
      witness). [Story: FR-J7-081]
- [ ] **T-PHA-003** : `_setup_l2()` / `_teardown_l2()` use
      `mk_tmpdir_with_trap` per `_helpers.sh`. Trap on RETURN.
      [Story: FR-J7-082]
- [ ] **T-PHA-004** : Add **3 L2 fixture stubs** : `_test_j7_l2_good_fixture`,
      `_test_j7_l2_bad_fixture_six_modes`, `_test_j7_l2_drift_fixture`.
      Each returns `_not_implemented` until Phase 3. [Story: FR-J7-082]
- [ ] **T-PHA-005** : Add **NFR-J7-002 production-tree guard** as
      `_test_j7_017_live_tree_green` — runs the validator (once
      it exists) against the real `.forge/standards/` directory and
      asserts exit 0 + zero `[STD-FAIL]`. Stub returns
      `_not_implemented` for now. [Story: NFR-J7-002]
- [ ] **T-PHA-006** : Add **NFR-J7-001 perf guard** as
      `_test_j7_l2_perf_budget` (4th L2) wrapping the live-tree run
      in `time` and asserting ≤ 2 s wall-clock. Stub returns
      `_not_implemented`. [Story: NFR-J7-001]
- [ ] **T-PHA-007** : Confirm verify.sh is **NOT modified** at this
      phase (convention check : harness registration belongs in
      `forge-ci.yml`, not `verify.sh` ; same precedent as t5).
      [Story: FR-J7-080]
- [ ] **T-PHA-008** [P] : Register `j7.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `t5.test.sh` with `--level 1,2`.
      [Story: FR-J7-090]

### T-SCH-SKEL — schema file skeleton

- [ ] **T-SCH-SKEL-001** [P] : Create
      `.forge/schemas/standard.schema.json` with the minimum viable
      shape : `$schema: "https://json-schema.org/draft/2020-12/schema"`,
      `$id: "https://forge.dev/schemas/standard.schema.json"`,
      `type: "object"`, empty `properties: {}`, `required: []`.
      Empty contract — Phase 2 fills the fields. [Story: FR-J7-001]

### Phase 1 gate

- [ ] **T-PHA-009** : RED gate confirmed —
      `bash .forge/scripts/tests/j7.test.sh > /tmp/j7-red.log 2>&1` ;
      `bash exit: 1` ; `Failed: 17 / Passed: 0` (16 L1 + 1 production-
      tree guard + 0 L2 fixtures fired pre-validator) ; all stubs
      report `not implemented (RED witness)`. Phase 1 RED gate
      satisfied. [Story: FR-J7-081]

**Phase 1 exit gate** : `j7.test.sh` exits 1 with `FAIL ≥ 16`,
`standard.schema.json` exists with valid `$schema` declaration,
`forge-ci.yml` matrix updated. constitution-linter.sh OVERALL PASS
(no new artefacts trip rules yet).

---

## Phase 2 — Core : schema fields + Python engine + bash wrapper

Goal : the 8 frontmatter contract + `enforcement` sub-shape are in
`standard.schema.json` ; Python 3 inline engine validates Phase 1
(schema only) ; bash wrapper iterates files. After this phase,
L1 tests `_test_j7_001` → `_test_j7_010` flip GREEN.

### T-SCH — Schema fields (FR-J7-002 → 010)

> RED order : flip the test from `_not_implemented` to a real
> `_yq_eval` / `assert_eq` assertion, capture the FAIL log, then
> implement the schema field.

- [ ] **T-SCH-001** : RED witness — convert `_test_j7_001_required_version`
      to assert exit-1 + presence of `version` error string. Capture
      `/tmp/j7-red-sch-001.log`. [Story: FR-J7-002]
- [ ] **T-SCH-002** : Add `properties.version` (`type: string`,
      `pattern: "^[0-9]+\\.[0-9]+\\.[0-9]+$"`) and append `version`
      to `required` in `standard.schema.json`. [Story: FR-J7-002 / FR-J7-003]
- [ ] **T-SCH-003** [P] : Add `properties.last_reviewed`
      (`type: string`, `pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"`)
      + required. [Story: FR-J7-004]
- [ ] **T-SCH-004** [P] : Add `properties.expires_at` polymorphic
      (`oneOf: [{type:string, pattern: ISO-8601}, {const: "never"}]`)
      + required. [Story: FR-J7-005]
- [ ] **T-SCH-005** [P] : Add `properties.exception_constitutional`
      (`type: boolean`) + required. [Story: FR-J7-006]
- [ ] **T-SCH-006** [P] : Add `properties.linter_rule`
      (`type: ["string", "null"]`, when string `pattern: "^[a-z][a-z0-9-]*$"`).
      Use `if/then` schema construct or `oneOf` for the conditional
      pattern (locked at impl time). [Story: FR-J7-007]
- [ ] **T-SCH-007** [P] : Add `properties.enforcement` object with
      `required: [ci_blocking, pre_commit_hook]`,
      sub-properties booleans, `additionalProperties: false`.
      [Story: FR-J7-008]
- [ ] **T-SCH-008** [P] : Add `properties.forbidden`
      (`type: array`, `items: {type: string}`, allow empty `[]`).
      [Story: FR-J7-009]
- [ ] **T-SCH-009** [P] : Add `properties.rationale`
      (`type: string`, `minLength: 1`). [Story: FR-J7-010]
- [ ] **T-SCH-010** : Set root-level `additionalProperties: true`
      (per ADR-J7-004) so domain bodies (`protocol`, `codegen`, etc.)
      do not trip the schema. Add an inline `$comment:` referencing
      ADR-J7-004 for future readers. [Story: FR-J7-001 / ADR-J7-004]

### T-VAL — Validator script + Python engine (FR-J7-060 → 064)

- [ ] **T-VAL-001** : RED witness — convert
      `_test_j7_010_rationale_empty` to assert specific output ;
      capture `/tmp/j7-red-val-001.log`. [Story: FR-J7-010 / FR-J7-064]
- [ ] **T-VAL-002** : Create `bin/validate-standards-yaml.sh` —
      executable bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`), parse args (`[<dir>]`, default
      `.forge/standards/`), exit 2 on usage error, glob
      `*.yaml` (top-level only ; `global/` excluded ; `index.yml`
      excluded by name). [Story: FR-J7-060 / FR-J7-061]
- [ ] **T-VAL-003** : Embed the Python 3 inline engine via
      `python3 -c '<heredoc>'` invocation, **lifting the F.2 skeleton**
      from `.forge/scripts/validate-change-yaml.sh` lines 1–~150
      (PyYAML load + date coercion + Phase 1 schema walk).
      Parametrise on schema path + yaml path. [Story: FR-J7-062 / FR-J7-063 / NFR-J7-004]
- [ ] **T-VAL-004** : Implement Phase 1 schema validation : walk
      `properties` + `required` + `oneOf` + `additionalProperties`
      manually (no `jsonschema` lib per NFR-J7-006). Mirror F.2's
      `_validate_field` helper signature. Accumulate errors in a
      list, never short-circuit. [Story: FR-J7-062 / NFR-J7-006]
- [ ] **T-VAL-005** : Implement the deterministic error format —
      stdout `[STD-PASS] <relative-path>` for clean files, stderr
      `[STD-FAIL: <relative-path>:<field>: <reason>]` for
      violations (per ADR-J7-005). Exit 0 (all pass) / 1 (any
      fail) / 2 (usage error). [Story: FR-J7-064 / ADR-J7-005]
- [ ] **T-VAL-006** : Run `j7.test.sh` ; assert L1 tests
      `_test_j7_001` → `_test_j7_010` (10 tests covering the 8
      schema fields + 2 type-mismatch cases) flip GREEN.
      Phase 1 schema validation working. [Story: FR-J7-002..010]

### Phase 2 gate

- [ ] **T-VAL-007** : `j7.test.sh` `Passed: ≥ 10 / Failed: ≤ 7`,
      no regression in `verify.sh` aggregate
      (run `bash .forge/scripts/verify.sh` ; expect existing 108+
      PASS unchanged), `constitution-linter.sh` OVERALL PASS.
      [Story: FR-J7-002..010 / NFR-J7-004]

**Phase 2 exit gate** : Phase 1 schema validation GREEN against
synthetic single-file fixtures ; `validate-standards-yaml.sh` parses
args, iterates yamls, emits deterministic output ; F.2 helpers
reused (cite line numbers in commit). Lifecycle invariants and
cross-references still RED.

---

## Phase 3 — Integration : invariants + cross-references + verify.sh + L2 fixtures

Goal : Phase 2 of the engine implemented (FR-J7-020..023, 030,
040..041, 050..051) ; verify.sh new section ships ; the 3 L2
fixtures + production-tree guard + perf guard all flip GREEN.

### T-INV — Phase 2 invariants engine (FR-J7-020 → 023)

- [ ] **T-INV-001** : RED witness — convert
      `_test_j7_020_xii_coupling` ; capture log. [Story: FR-J7-020]
- [ ] **T-INV-002** : Implement bidirectional Article XII coupling :
      `expires_at == "never" ⇔ exception_constitutional is True`.
      Emit `[STD-FAIL: ...:expires_at: never requires exception_constitutional: true (Article XII)]`
      OR the symmetric error when the boolean is true but expiry is
      dated. [Story: FR-J7-020]
- [ ] **T-INV-003** [P] : Implement `expires_at > last_reviewed`
      strict ordering when both are dated. Use `datetime.date`
      comparison (post-coercion). [Story: FR-J7-021]
- [ ] **T-INV-004** [P] : Implement non-blocking 12-month cycle
      check : if `expires_at - last_reviewed > 13 months`, emit
      `[STD-INFO: ...:expires_at: cycle exceeds 12 months]`. INFO
      lines are stdout, do NOT affect exit code. [Story: FR-J7-022 / ADR-J7-005]
- [ ] **T-INV-005** : Implement REVIEW.md drift check (full ledger
      scan per ADR-J7-003) — read `.forge/standards/REVIEW.md`
      once per validator run, regex
      `\|\s*{basename}\s*\|\s*{version}\s*\|` (multiline). On
      miss → `[STD-FAIL: ...:version: declared {V} not present in REVIEW.md ledger]`.
      [Story: FR-J7-023 / ADR-J7-003]
- [ ] **T-INV-006** : Run `j7.test.sh` ; expect
      `_test_j7_020`, `_test_j7_021`, `_test_j7_023` GREEN.
      [Story: FR-J7-020..023]

### T-XREF — Cross-references (FR-J7-030 + 050..051)

- [ ] **T-XREF-001** : RED witness — convert
      `_test_j7_030_linter_rule_miss`. [Story: FR-J7-030]
- [ ] **T-XREF-002** : Implement `linter_rule` cross-reference per
      ADR-J7-002 — read `.forge/scripts/constitution-linter.sh`
      once, regex `^\s*(echo|#).*\b{rule}\b` (Python `re.M`). On
      miss when `linter_rule` is non-null →
      `[STD-FAIL: ...:linter_rule: rule "{rule}" not found as section header or comment in constitution-linter.sh]`.
      [Story: FR-J7-030 / ADR-J7-002]
- [ ] **T-XREF-003** [P] : RED + impl
      `_test_j7_050_index_dangling` — read
      `.forge/standards/index.yml` (PyYAML), iterate any node
      with a `path:` key under `.forge/standards/**`, assert file
      exists. On miss →
      `[STD-FAIL: index.yml:trigger: dangling path {p} (file does not exist)]`.
      [Story: FR-J7-050]
- [ ] **T-XREF-004** [P] : Implement reverse coverage as
      non-blocking : list standard yamls not referenced by any
      `index.yml` trigger ; emit `[STD-INFO: ...:index: orphan]`.
      [Story: FR-J7-051]

### T-FBD — `forbidden` list shape (FR-J7-040 → 041)

- [ ] **T-FBD-001** [P] : RED + impl `_test_j7_041_forbidden_dup` —
      assert each entry is a non-empty trimmed string ; assert no
      duplicates within a single list. Two distinct error messages.
      [Story: FR-J7-040 / FR-J7-041]

### T-VFY — verify.sh integration (FR-J7-070 → 072)

- [ ] **T-VFY-001** : RED witness — extend
      `_test_j7_017_live_tree_green` to also assert
      `verify.sh` exits 0 with the new section present. (Test
      runs verify.sh in a sub-shell with `FORGE_VERIFY_FAST=1` if
      such a knob exists, otherwise full run.) [Story: FR-J7-070..072]
- [ ] **T-VFY-002** : Edit `.forge/scripts/verify.sh` — add new
      section header `=== Standards YAML Schema ===`
      **immediately after** the existing `=== Change YAML Schema ===`
      section. Iterate `.forge/standards/*.yaml` (top-level), call
      `bin/validate-standards-yaml.sh <file>` per file, accumulate
      PASS/FAIL into the global counters (do not mint new totals).
      [Story: FR-J7-070 / FR-J7-071]
- [ ] **T-VFY-003** : Honor `examples/` skip-guard convention from
      F.2 — any `examples/**/.forge/standards/*.yaml` is skipped
      without count. [Story: FR-J7-072]
- [ ] **T-VFY-004** : Run `verify.sh` end-to-end against the live
      tree ; assert aggregate counter grew by **6** PASS
      (one per existing standard) without any new FAIL.
      [Story: FR-J7-070..072 / NFR-J7-002]

### T-L2 — L2 fixtures (FR-J7-082)

- [ ] **T-L2-001** : Implement `_test_j7_l2_good_fixture` — temp dir
      with miniature `transport.yaml` + `state-management.yaml`
      mirroring real frontmatter ; assert validator exit 0 + 2
      `[STD-PASS]` lines. [Story: FR-J7-082]
- [ ] **T-L2-002** : Implement `_test_j7_l2_bad_fixture_six_modes` —
      6 standards each with one failure mode (missing field, bad
      semver, bad date, broken Article XII coupling, unknown
      `linter_rule`, dangling `index.yml` trigger). Assert exit 1
      + 6 `[STD-FAIL]` lines, each with the exact deterministic
      reason string. [Story: FR-J7-082]
- [ ] **T-L2-003** : Implement `_test_j7_l2_drift_fixture` —
      synthetic standard at v1.2.0, synthetic REVIEW.md only
      mentioning v1.1.0. Assert exit 1 + exactly one drift
      `[STD-FAIL]` line. [Story: FR-J7-082]
- [ ] **T-L2-004** : Implement `_test_j7_l2_perf_budget` — wrap
      live-tree run in `time` (or Python `time.perf_counter`) ;
      assert ≤ 2 s. [Story: NFR-J7-001]

### Phase 3 gate

- [ ] **T-INT-001** : Run `j7.test.sh --level 1,2` end-to-end ;
      expect `Passed: ≥ 20 / Failed: 0`, wall-clock ≤ 8 s.
      `verify.sh` aggregate +6 PASS, 0 FAIL.
      `constitution-linter.sh` OVERALL PASS.
      [Story: NFR-J7-001 / NFR-J7-002 / NFR-J7-004]

**Phase 3 exit gate** : full L1 + L2 + production-tree GREEN ;
verify.sh integration shipping ; live-tree perf ≤ 2 s. Standard
documentation and CHANGELOG still pending.

---

## Phase 4 — Quality : standard + docs + CI gate + review

### T-STD — standards-lifecycle.md cross-reference (FR-J7-100)

- [ ] **T-STD-001** [P] : Add a section "Automated enforcement" to
      `.forge/standards/global/standards-lifecycle.md` referencing
      `bin/validate-standards-yaml.sh` and `j7.test.sh`. List the
      five invariants the validator enforces (FR-J7-020..023, 030,
      050) and the two non-blocking informational rules (022, 051).
      Cross-link `docs/SCHEMA.md`. [Story: FR-J7-100]

### T-DOC — Documentation (FR-J7-101 → 102)

- [ ] **T-DOC-001** [P] : Add a new section "Standard YAML schema"
      to `docs/SCHEMA.md` mirroring the existing "Change YAML
      schema" section : frontmatter contract, lifecycle invariants,
      common errors with one-line fix recipe each. Cross-link
      `global/standards-lifecycle.md` + `j7.test.sh`.
      [Story: FR-J7-101]
- [ ] **T-DOC-002** [P] : Add an entry to `CHANGELOG.md` under
      `## [Unreleased]` flagging : new linter
      `bin/validate-standards-yaml.sh`, new schema
      `.forge/schemas/standard.schema.json`, `verify.sh` extended
      with "Standards YAML Schema" section, harness `j7.test.sh`
      registered in `forge-ci.yml`. [Story: FR-J7-102]

### T-CI — CI registration finalisation

- [ ] **T-CI-001** : Confirm `j7.test.sh` is in the `forge-ci.yml`
      `harness` job matrix (registered in T-PHA-008). Trigger a
      local dry-run if `act` is available ; otherwise rely on the
      first PR push. [Story: FR-J7-090]
- [ ] **T-CI-002** : Run `verify.sh` locally ; expect aggregate
      counter ≥ baseline + 6 PASS without regression in the
      existing 108 PASS / 0 FAIL baseline (see roadmap v0.3.0
      release entry). [Story: NFR-J7-002]
- [ ] **T-CI-003** : Run `constitution-linter.sh` ; expect OVERALL
      PASS (5 existing T.5 WARN are acceptable per ADR-T5-005 —
      no new WARN expected). [Story: NFR-J7-002]

### T-REV — Quality review gate

- [ ] **T-REV-001** : Run `/forge:review j7-validate-standards-yaml`
      driving the constitutional gate review : Articles I (TDD),
      III + III.4, IV (delta), V (audit trail), X (gate coverage),
      XII (governance). Block if any returns VIOLATION.
      [Story: Article V]
- [ ] **T-REV-002** : Run the full `verify.sh` once more on a
      clean checkout to confirm reproducibility. Expect identical
      counter movement as T-VFY-004. [Story: NFR-J7-002]
- [ ] **T-REV-003** : Verify `bin/forge-questions.sh
      --change j7-validate-standards-yaml --status open` returns
      empty (Q-001..Q-004 all answered post-design).
      [Story: Article III.4]

**Phase 4 exit gate (= change archival readiness)** :

- `j7.test.sh --level 1,2` ≥ 20 PASS / 0 FAIL / ≤ 8 s wall-clock.
- `verify.sh` aggregate ≥ baseline + 6 PASS / 0 FAIL.
- `constitution-linter.sh` OVERALL PASS (no new WARN).
- `bin/forge-questions.sh --change j7-validate-standards-yaml --status open`
  returns empty.
- `bin/validate-standards-yaml.sh` against the live tree exits 0,
  ≤ 2 s wall-clock.
- All FR-J7-001..102 + NFR-J7-001..006 tasks checked.
- `CHANGELOG.md` entry under `## [Unreleased]`.
- `docs/SCHEMA.md` and `global/standards-lifecycle.md` updated.
- Snapshot tarballs : NOT regenerated (J.7 doesn't ship template
  changes — verify by `git diff main -- .forge/templates/` returns
  empty).

---

## Constitutional task review (per Article V)

For each task family, verifying TDD compliance + spec linkage +
architecture preservation :

| Task family | TDD order                            | Spec link                          | Architecture                                |
|-------------|--------------------------------------|------------------------------------|---------------------------------------------|
| T-PHA-*     | RED phase (intentional)              | FR-J7-080..082, 090                | N/A                                         |
| T-SCH-SKEL-*| RED witness via T-PHA harness        | FR-J7-001                          | ADR-J7-004 (schema location)                |
| T-SCH-*     | RED witness before each schema field | FR-J7-002..010                     | ADR-J7-004                                  |
| T-VAL-*     | RED witness then minimal impl        | FR-J7-060..064 / NFR-J7-004..006   | ADR-J7-001 (F.2 reuse), ADR-J7-005 (errors) |
| T-INV-*     | RED witness then engine extension    | FR-J7-020..023                     | ADR-J7-003 (REVIEW scan)                    |
| T-XREF-*    | RED witness then cross-ref impl      | FR-J7-030 / 050..051               | ADR-J7-002 (linter_rule grep)               |
| T-FBD-*     | RED witness then list checks         | FR-J7-040..041                     | N/A                                         |
| T-VFY-*     | RED witness then verify.sh edit      | FR-J7-070..072 / NFR-J7-002        | F.2 pattern reuse                           |
| T-L2-*      | RED witness then fixture impl        | FR-J7-082 / NFR-J7-001             | Eris fixture convention                     |
| T-INT-*     | Validation only                      | NFR-J7-001/002/004                 | All ADRs satisfied                          |
| T-STD-*     | No code, doc-only                    | FR-J7-100                          | global/standards-lifecycle.md cross-link    |
| T-DOC-*     | No code, doc-only                    | FR-J7-101..102                     | docs/SCHEMA.md symmetry with F.2            |
| T-CI-*      | Validation only                      | FR-J7-090 / NFR-J7-002             | forge-self-ci standard                      |
| T-REV-*     | Final gate, no production code       | Article V / III.4 / X / XII        | All articles                                |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement`.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 9     | 2                    | 16 stubs      |
| 2     | 17    | 7                    | 10 (per FR)   |
| 3     | 17    | 4                    | 7 (per FR)    |
| 4     | 9     | 3                    | 0 (validation only) |
| **Total** | **52** | **16** | **33 RED witnesses** |

Estimated wall-clock at single-developer pace : Phase 1 ≈ 1–2 h,
Phase 2 ≈ 3–4 h, Phase 3 ≈ 2–3 h, Phase 4 ≈ 1 h. Total ≈ 1 working
day, consistent with the **S** complexity estimate in `proposal.md`.
