# Tasks: k5-themis
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-K5-THE-XXX]` (Article V.1, enforced by
  `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable within the same phase.
- Each phase ends with a gate task running
  `bash .forge/scripts/tests/k5.test.sh` and confirming counter
  movement.
- ADRs from `design.md` (ADR-K5-001..006) are honored verbatim.

---

## Phase 1 — Foundation : RED harness + CI registration

Goal : `k5.test.sh` exists with **25 L1 + 2 L2** stubs all FAIL ; full
RED captured ; harness registered in `forge-ci.yml`.

- [ ] **T-PHA-001** : Create `.forge/scripts/tests/k5.test.sh` (bash
      header, source `_helpers.sh`, PASS/FAIL reset, `--level 1,2`
      parsing, `print_summary`). Mirror `k3.test.sh`.
      [Story: FR-K5-THE-100]
- [ ] **T-PHA-002** : Add 25 L1 stubs + 2 L2 stubs returning
      `_not_implemented`. [Story: FR-K5-THE-101 / 102]
- [ ] **T-PHA-003** [P] : Register `k5.test.sh --level 1,2` in
      `.github/workflows/forge-ci.yml` `harnesses=(...)` array after
      `k3.test.sh`. [Story: FR-K5-THE-100]
- [ ] **T-PHA-004** : RED gate — `bash k5.test.sh --level 1,2` exits 1,
      `Failed: 27 / Passed: 0`. [Story: FR-K5-THE-101]

---

## Phase 2 — K.5.a : Themis persona file

Goal : `.claude/agents/themis.md` ships with all mandatory H2 sections.
10 L1 tests flip GREEN (`_test_k5_001..010`).

- [ ] **T-PER-001** : RED witness — convert `_test_k5_001..004`.
      [Story: FR-K5-THE-001..004 / 010]
- [ ] **T-PER-002** : Create `.claude/agents/themis.md` :
      - `<!-- Audit: K.5 (k5-themis) -->` comment.
      - H1 `# Agent: Compliance Officer EU (Themis)`.
      - `## Persona` (Name / Role / Style per FR-K5-THE-002).
      - `## Purpose` (cite K.5 + upstream surfaces per FR-K5-THE-003).
      - `## Boundary — Themis vs Demeter` (scaffold-time vs
        repo-lifecycle-time per FR-K5-THE-004).
      [Story: FR-K5-THE-001..004 / 010 / ADR-K5-001]
- [ ] **T-PER-003** : Add `## Checklists` (3 H3, ≥ 5 `[ ]` each) +
      `## Output: Standards Review Report` (Summary table) +
      `## Rule Catalogue` (K5-RULE-001..005) + `## Integration` +
      `## Anti-Hallucination Protocol` + audit-cross-reference footer.
      [Story: FR-K5-THE-005..009 / 011 / 070..074 / 112]
- [ ] **T-PER-004** : Run `k5.test.sh` ; expect `_test_k5_001..010`
      GREEN. [Story: FR-K5-THE-001..009]

---

## Phase 3 — K.5.b : `forge review-standards` CLI

Goal : `bin/forge-review-standards.sh` + Python engine ship. 5 L1
tests flip GREEN (`_test_k5_011..015`) AND the 2 L2 fixtures flip
GREEN.

- [ ] **T-CLI-001** : RED witness — convert `_test_k5_011..015`.
      [Story: FR-K5-THE-020 / 027 / 035 / 036]
- [ ] **T-CLI-002** : Create `bin/forge-review-standards.sh` bash thin
      (header, `set -uo pipefail`, `case` arg loop for `--target` /
      `--window` / `--output` / `--format` / `--bundle` / `--strict` /
      `--help`, bogus arg exit 2, empty-tree exit 2). Mirror
      `forge-demeter-scan.sh`. [Story: FR-K5-THE-020..021 / 035 / 036 /
      ADR-K5-002]
- [ ] **T-CLI-003** : Implement Python engine phase 1 (discover) —
      `os.walk(.forge/standards)`, collect `*.yaml` + `*.md`, exclude
      `REVIEW.md` + `index.yml`. [Story: FR-K5-THE-022]
- [ ] **T-CLI-004** [P] : Implement phase 2 (parse frontmatter) —
      YAML top-level key scan + MD fenced ```yaml block scan.
      [Story: FR-K5-THE-022 / ADR-K5-002]
- [ ] **T-CLI-005** : Implement phase 3 (classify) — FRESH / DUE-SOON /
      EXPIRED / STRUCTURAL ; K5-RULE-001..005 findings ; two-tier
      missing-frontmatter severity (ADR-K5-004) ; structural skip.
      [Story: FR-K5-THE-023..026 / 070..074 / ADR-K5-004 / 005]
- [ ] **T-CLI-006** [P] : Embed the verbatim regulatory calendar +
      horizon check (K5-RULE-004). [Story: FR-K5-THE-027 / 028 / 073 /
      NFR-K5-THE-009]
- [ ] **T-CLI-007** : Implement phase 4 (emit) — JSON per
      FR-K5-THE-029 (sort_keys, deterministic) + MD per FR-K5-THE-030 ;
      exit-code mapping 0/1/2/3 ; `--strict` blocking.
      [Story: FR-K5-THE-029..033 / NFR-K5-THE-005]
- [ ] **T-CLI-008** [P] : Implement `--bundle` — write
      `forge-regulatory-deadlines.md` + drive
      `.forge/scripts/compliance/bundle.sh` (propagate
      `SOURCE_DATE_EPOCH`) ; graceful degradation if absent.
      [Story: FR-K5-THE-032 / ADR-K5-006]
- [ ] **T-CLI-009** : Run `k5.test.sh --level 1` ; expect CLI L1 tests
      GREEN. [Story: FR-K5-THE-020..036]
- [ ] **T-L2-001** : RED witness — convert `_test_k5_l2_expired` +
      `_test_k5_l2_clean_deterministic`. [Story: FR-K5-THE-102]
- [ ] **T-L2-002** : Implement both L2 fixtures per design.md L2 table.
      [Story: FR-K5-THE-102 / NFR-K5-THE-005]
- [ ] **T-L2-003** : Run `k5.test.sh --level 1,2` ; expect L2 GREEN,
      ≤ 20 s. [Story: NFR-K5-THE-001]

---

## Phase 4 — K.5.c : standard + index + lifecycle + workflow + dispatch

Goal : remaining L1 tests flip GREEN (`_test_k5_016..025`).

- [ ] **T-STD-001** : RED witness — convert `_test_k5_016` +
      `_test_k5_017`. [Story: FR-K5-THE-050 / 051]
- [ ] **T-STD-002** : Create
      `.forge/standards/global/standards-review-rules.md` (≥ 5 H2 :
      Purpose, Rule catalogue, Regulatory-deadline calendar, Review
      cadence automation, Extending the catalogue). Verbatim
      regulatory dates. [Story: FR-K5-THE-050 / 027]
- [ ] **T-STD-003** : Add `global/standards-review-rules` entry to
      `.forge/standards/index.yml` per FR-K5-THE-051.
      [Story: FR-K5-THE-051]
- [ ] **T-LC-001** : RED witness — convert `_test_k5_018`.
      [Story: FR-K5-THE-052]
- [ ] **T-LC-002** : Delta-edit
      `.forge/standards/global/standards-lifecycle.md` "Themis hook
      (deferred — T7)" section → "shipped (K.5)" + reference
      `bin/forge-review-standards.sh` + `forge-standards-review.yml`.
      Keep the structural-exception table intact (t4.test.sh).
      [Story: FR-K5-THE-052 / Article IV.1]
- [ ] **T-WF-001** : RED witness — convert `_test_k5_019` +
      `_test_k5_020`. [Story: FR-K5-THE-060..063]
- [ ] **T-WF-002** : Create
      `.github/workflows/forge-standards-review.yml` (`on: schedule:`
      monthly cron + `workflow_call:` ; `permissions: contents: read` ;
      step invoking `bin/forge-review-standards.sh` with
      `continue-on-error: true`). [Story: FR-K5-THE-060..063 /
      ADR-K5-005]
- [ ] **T-REG-001** : RED witness — convert `_test_k5_021` +
      `_test_k5_022` + `_test_k5_023`. [Story: FR-K5-THE-053..055]
- [ ] **T-REG-002** : Edit `CLAUDE.md` agent-delegation table (Themis
      row) + `docs/GUIDE.md` "Agents Transversaux" (Themis row) +
      `docs/COMPLIANCE.md` (`## Standards review cadence (Themis)` H2).
      [Story: FR-K5-THE-053..055]
- [ ] **T-NSC-001** : RED witness — convert `_test_k5_024`.
      [Story: FR-K5-THE-086]
- [ ] **T-NSC-002** : Verify K5-RULE / K3-RULE namespace separation
      holds (no edit expected). [Story: FR-K5-THE-086 / ADR-K5-003]
- [ ] **T-DOC-001** : RED witness — convert `_test_k5_025`. Add
      `## [Unreleased]` → `### Added` CHANGELOG entry referencing
      `k5-themis`. [Story: FR-K5-THE-111]
- [ ] **T-P4-GATE** : Run `k5.test.sh --level 1,2` ; expect 27/27
      GREEN. [Story: FR-K5-THE-101 / 102]

---

## Phase 5 — Quality : REVIEW.md + open-questions flip + verification

- [ ] **T-REV-001** : Append `.forge/standards/REVIEW.md` birth entry
      for `standards-review-rules.md` (dated 2026-07-10, KEEP, next
      review 2027-07-10). [Story: Article V]
- [ ] **T-OQ-001** : Confirm `open-questions.md` Q-K5-001..003 are
      `Status: answered`. [Story: Article III.4]
- [ ] **T-REV-002** : Run sibling harnesses green : `i5.test.sh`,
      `i6.test.sh`, `k3.test.sh`, `t4.test.sh`, `j7.test.sh`.
      [Story: NFR-K5-THE-006]
- [ ] **T-REV-003** : Smoke the 3 BDD scenarios against the live tree +
      synthetic fixtures. [Story: Article II]
- [ ] **T-REV-004** : Flip `.forge.yaml` status to `implemented` then
      `archived` at archive time. [Story: Article IV.4]

**Phase 5 exit gate (archival readiness)** :
- `k5.test.sh --level 1,2` 27/27 PASS / 0 FAIL / ≤ 20 s.
- `k3.test.sh` / `i5.test.sh` / `i6.test.sh` / `t4.test.sh` /
  `j7.test.sh` unchanged GREEN (NFR-K5-THE-006).
- `bin/forge-review-standards.sh` runs clean on the live tree.
- CHANGELOG `## [Unreleased]` entry present.
- REVIEW.md birth entry appended.

---

## Task counts by phase

| Phase | Tasks | RED witnesses |
|-------|-------|---------------|
| 1 | 4 | 27 stubs |
| 2 | 4 | 10 |
| 3 | 12 | 7 |
| 4 | 13 | 10 |
| 5 | 5 | 0 (validation) |
| **Total** | **38** | **27 witnesses** |

Estimated wall-clock ≈ 2 working days, consistent with the **M**
complexity estimate (`new-archetypes-plan` §9 row K.5).
