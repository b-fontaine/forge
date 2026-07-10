# Tasks: k4-iris-web
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-K4-IW-XXX]` (Article V.1, enforced by
  `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the same
  phase.
- Each phase ends with a gate task that runs
  `bash .forge/scripts/tests/k4.test.sh` and confirms expected counter
  movement.
- ADRs from `design.md` (ADR-K4-001..004) are honored verbatim.

---

## Phase 1 — Foundation : RED harness

Goal : `k4.test.sh` exists with **20 L1 + 2 L2** stubs all FAIL ; full
RED state captured ; CI registration done.

### T-PHA — k4.test.sh skeleton

- [ ] **T-PHA-001** : Create `.forge/scripts/tests/k4.test.sh` with
      bash header (`#!/usr/bin/env bash`, `set -uo pipefail`, source
      `_helpers.sh`), PASS/FAIL counters reset, `--level 1,2` parsing,
      `print_summary` close-out. Mirror the K.3 layout.
      [Story: FR-K4-IW-100]
- [ ] **T-PHA-002** : Add **20 L1 test stubs** covering the 20 anchor
      IDs enumerated in `design.md` § "L1 unit-level" table.
      [Story: FR-K4-IW-101]
- [ ] **T-PHA-003** [P] : Add **2 L2 cross-surface stubs**
      (`_test_k4_l2_catalogue_sync`, `_test_k4_l2_no_pin_duplication`).
      [Story: FR-K4-IW-102]
- [ ] **T-PHA-004** [P] : Register `k4.test.sh --level 1,2` in
      `.github/workflows/forge-ci.yml` `harness` matrix at the end of
      the list (after `b7-6.test.sh`). [Story: FR-K4-IW-100]
- [ ] **T-PHA-005** : RED gate confirmed —
      `bash .forge/scripts/tests/k4.test.sh --level 1,2` exits 1 with
      `Failed: 21 / Passed: 1`. The single green test is
      `_test_k4_019_hera_scope_intact` — a regression-guard invariant
      that asserts Hera's Flutter scope stays intact (green from the
      start because it protects a pre-existing invariant that MUST
      never be broken ; mirrors the K.3 namespace-collision guard).
      [Story: FR-K4-IW-101]

**Phase 1 exit gate** : `k4.test.sh --level 1,2` exits 1 with
`FAIL == 21`, `PASS == 1` (Hera-intact invariant guard),
`forge-ci.yml` matrix updated.

---

## Phase 2 — K.4.a : Iris-Web persona file

Goal : `.claude/agents/iris-web.md` ships with all mandatory H2
sections + audit comment + K4-RULE catalogue. After this phase, the
persona L1 tests flip GREEN (`_test_k4_001..010`).

### T-PER — Persona skeleton

- [ ] **T-PER-001** : RED witness — confirm
      `_test_k4_001_persona_exists` + `_test_k4_002_audit_comment` +
      `_test_k4_003_persona_h2` FAIL. [Story: FR-K4-IW-001..003 / 010]
- [ ] **T-PER-002** : Create `.claude/agents/iris-web.md` with :
      - `<!-- Audit: K.4 (k4-iris-web) -->` comment at top.
      - H1 `# Agent: Frontend Web Specialist (Iris-Web)`.
      - H2 `## Persona` (Name / Role / Style + sibling-to-Hera scope
        boundary + archetype scope + anti-hallucination paragraph).
      - H2 `## Purpose` (cite K.4 + the B.8.9 / B.7.10 surfaces).
      [Story: FR-K4-IW-001..003 / 009 / 010 / ADR-K4-004]
- [ ] **T-PER-003** : Run `k4.test.sh` ; expect persona-skeleton tests
      flip GREEN. [Story: FR-K4-IW-001..003]

### T-CHK — Checklists section

- [ ] **T-CHK-001** : RED witness — confirm
      `_test_k4_004_checklists_h2` + `_test_k4_005_checklists_items`
      FAIL. [Story: FR-K4-IW-004]
- [ ] **T-CHK-002** : Add `## Checklists` H2 with 4 H3 sub-sections
      (Resumability & Rendering / Routing & SSR-SSG Boundaries /
      Connect-ES & Streaming / Components & Vitest Testing), each with
      ≥ 5 `[ ]` items in the Aegis/Demeter style.
      [Story: FR-K4-IW-004 / 020..026]
- [ ] **T-CHK-003** : Run `k4.test.sh` ; expect checklist tests flip
      GREEN. [Story: FR-K4-IW-004]

### T-OUT — Output report + Rule catalogue + Integration + Anti-Halluc + Audit xrefs

- [ ] **T-OUT-001** : RED witness — confirm `_test_k4_006_output_h2` +
      `_test_k4_007_rule_catalogue` + `_test_k4_008_integration` +
      `_test_k4_009_anti_halluc` + `_test_k4_010_audit_xrefs` FAIL.
      [Story: FR-K4-IW-005..008 / 011]
- [ ] **T-OUT-002** : Add `## Output: Web Frontend Readiness Report`
      (Summary `| Severity | Count |` table + Findings template +
      Cleared Items + overall status BLOCKED/CONCERNS/READY).
      [Story: FR-K4-IW-005]
- [ ] **T-OUT-003** : Add `## Rule Catalogue` H2 enumerating
      K4-RULE-001..006 per FR-K4-IW-120..125 (trigger / severity /
      evidence / recommendation / cross-link), advisory ladder per
      ADR-K4-001. [Story: FR-K4-IW-006 / 120..125 / ADR-K4-001/003]
- [ ] **T-OUT-004** : Add `## Integration` H2 (Janus arbitration Qwik
      vs Flutter per ARCHITECTURE-TARGET §9.2 line 743 ; Hera boundary ;
      Apollo ; Sibyl). [Story: FR-K4-IW-007 / ADR-K4-004]
- [ ] **T-OUT-005** [P] : Add `## Anti-Hallucination Protocol` H2 +
      `## Audit cross-references` footer. [Story: FR-K4-IW-008 / 011]
- [ ] **T-OUT-006** : Run `k4.test.sh` ; expect output + catalogue +
      integration + anti-halluc + xrefs tests flip GREEN.
      [Story: FR-K4-IW-005..011]

**Phase 2 exit gate** : 10 persona L1 tests GREEN.

---

## Phase 3 — K.4.b : Qwik frontend patterns standard

Goal : the conventions standard ships. After this phase, the standard
L1 tests flip GREEN (`_test_k4_011..015`) and both L2 tests flip GREEN.

### T-STD — `qwik-frontend-patterns.md`

- [ ] **T-STD-001** : RED witness — confirm
      `_test_k4_011_standard_exists` +
      `_test_k4_012_standard_resumability_routes_ssr` +
      `_test_k4_013_standard_connect_streaming` +
      `_test_k4_014_standard_components_vitest` +
      `_test_k4_015_standard_pins_reference` FAIL.
      [Story: FR-K4-IW-080..081 / 020..026]
- [ ] **T-STD-002** : Create
      `.forge/standards/global/qwik-frontend-patterns.md` with ≥ 5 H2
      sections : Purpose ; Resumability & rendering ; `routes/`
      conventions ; SSR/SSG boundaries ; Connect-ES client usage ;
      Streaming UI + cancel-on-unmount ; Component conventions ; Vitest
      testing conventions ; Rule catalogue (K4-RULE table) ; Adoption
      path + forward stability (`mobile-pwa-first`). Reference
      `web-frontend.yaml` for pins ; reproduce NO version number
      (ADR-K4-002 / NFR-K4-IW-003). [Story: FR-K4-IW-020..026 / 080..081]
- [ ] **T-STD-003** : Run `k4.test.sh` ; expect standard L1 + both L2
      tests flip GREEN. [Story: FR-K4-IW-080..081 / 102]

**Phase 3 exit gate** : 5 standard L1 + 2 L2 tests GREEN.

---

## Phase 4 — K.4.c : Standards index + Janus + CLAUDE.md integration

Goal : index registered, Janus delta-edited (additive), CLAUDE.md
trigger row added. After this phase, the remaining L1 tests flip GREEN
(`_test_k4_016..020`).

### T-IDX — Standards index registration

- [ ] **T-IDX-001** : RED witness — confirm
      `_test_k4_016_index_registered` FAIL. [Story: FR-K4-IW-082]
- [ ] **T-IDX-002** : Add the `global/qwik-frontend-patterns` entry to
      `.forge/standards/index.yml` per FR-K4-IW-082 (triggers incl.
      `iris-web, qwik, qwik-city, sveltekit, resumability, routes, ssr,
      ssg, connect-es, streaming-ui, vitest, web-frontend-patterns,
      k4-rule`). Insert adjacent to the K.3 entry for coherence.
      [Story: FR-K4-IW-082]
- [ ] **T-IDX-003** : Run `k4.test.sh` ; expect index test flip GREEN.
      [Story: FR-K4-IW-082]

### T-JAN — Janus additive dispatch row (ADR-K4-004)

- [ ] **T-JAN-001** : RED witness — confirm
      `_test_k4_017_janus_dispatch_row` +
      `_test_k4_019_hera_scope_intact` FAIL. [Story: FR-K4-IW-083 / 085]
- [ ] **T-JAN-002** : Edit `.claude/agents/cross-layer-orchestrator.md`
      Dispatch Table — insert the Iris-Web row AFTER the Hera row and
      BEFORE the Vulcan row per the verbatim block in ADR-K4-004. Do
      NOT modify Hera's row. [Story: FR-K4-IW-083 / ADR-K4-004]
- [ ] **T-JAN-003** : Run `k4.test.sh` ; expect Janus + Hera-intact
      tests flip GREEN. [Story: FR-K4-IW-083 / 085]

### T-CLM — CLAUDE.md trigger row

- [ ] **T-CLM-001** : RED witness — confirm
      `_test_k4_018_claude_md_trigger` FAIL. [Story: FR-K4-IW-084]
- [ ] **T-CLM-002** : Edit repo `CLAUDE.md` agent-delegation table —
      insert `| Qwik / SvelteKit web frontend | **Iris-Web** | Frontend
      Web Specialist |` additively (Hera's `Flutter code → Hera` row
      unchanged). [Story: FR-K4-IW-084 / NFR-K4-IW-006]
- [ ] **T-CLM-003** : Run `k4.test.sh` ; expect CLAUDE.md test flip
      GREEN. [Story: FR-K4-IW-084]

### T-NSC — Namespace + forward-stability guard

- [ ] **T-NSC-001** : RED witness — confirm
      `_test_k4_020_namespace_forward` FAIL. [Story: FR-K4-IW-085]
- [ ] **T-NSC-002** : Verify no `J8-RULE` / `K3-RULE` leaks into the
      K.4 surfaces (persona + standard) except as cross-link
      acknowledgement, and that the persona/standard name
      `mobile-pwa-first` as a forward consumer (NFR-K4-IW-005).
      [Story: FR-K4-IW-085 / NFR-K4-IW-005]
- [ ] **T-NSC-003** : Run `k4.test.sh --level 1,2` ; expect ALL 22
      tests GREEN. [Story: FR-K4-IW-085 / 101..102]

**Phase 4 exit gate** : `k4.test.sh --level 1,2` 22/22 GREEN.

---

## Phase 5 — Quality : docs + CHANGELOG + open-questions flip + review

### T-OQ — Open-questions flip

- [ ] **T-OQ-001** : Flip Q-001 / Q-002 / Q-003 in `open-questions.md`
      from `open` to `answered` with `### Resolution` blocks citing
      ADR-K4-001 / 002 / 003. [Story: Article III.4 / FR-K4-IW-008]

### T-DOC — Documentation

- [ ] **T-DOC-001** [P] : Add `## [Unreleased]` entry in `CHANGELOG.md`
      covering the 3 sub-modules (K.4.a persona + K.4.b standard +
      K.4.c integration). [Story: FR-K4-IW-110]
- [ ] **T-DOC-002** [P] : Add a one-line Iris-Web mention to the
      `docs/GUIDE.md` agent catalogue. [Story: FR-K4-IW-111]

### T-REV — Quality review gate

- [ ] **T-REV-001** : Run the constitutional gate review : Articles I
      (TDD), III + III.4, IV (delta — additive rows), V (audit trail),
      XI (AI-First), XII (governance). Block if any VIOLATION.
      [Story: Article V]
- [ ] **T-REV-002** : Run the full harness suite (mirror forge-ci loop)
      to confirm no sibling harness regressed. [Story: NFR-K4-IW-001]
- [ ] **T-REV-003** : Confirm Hera's Flutter scope reads intact in
      both `cross-layer-orchestrator.md` and `CLAUDE.md` (manual
      reviewer pass). [Story: NFR-K4-IW-006]

**Phase 5 exit gate (= archival readiness)** :

- `k4.test.sh --level 1,2` 22/22 PASS / 0 FAIL.
- `constitution-linter.sh` OVERALL PASS (no new WARN).
- Sibling harnesses (`k3`, `j8`, `b8-9`, `b7-10`) unchanged.
- `CHANGELOG.md` entry under `## [Unreleased]`.
- `docs/GUIDE.md` Iris-Web line added.
- All FR-K4-IW-001..125 + NFR-K4-IW-001..006 tasks checked.

---

## Constitutional task review (per Article V)

| Task family | TDD order                                | Spec link                       | Architecture         |
|-------------|------------------------------------------|---------------------------------|----------------------|
| T-PHA-*     | RED phase (intentional)                  | FR-K4-IW-100..102               | N/A                  |
| T-PER-*     | RED witness then persona skeleton        | FR-K4-IW-001..003 / 009 / 010   | ADR-K4-004           |
| T-CHK-*     | RED witness then checklist sub-sections  | FR-K4-IW-004 / 020..026         | Aegis/Demeter pattern|
| T-OUT-*     | RED witness then output + catalogue + integration | FR-K4-IW-005..011 / 120..125 | ADR-K4-001/003/004 |
| T-STD-*     | RED witness then standard MD             | FR-K4-IW-020..026 / 080..081    | ADR-K4-002           |
| T-IDX-*     | RED witness then index entry             | FR-K4-IW-082                    | standards-lifecycle  |
| T-JAN-*     | RED witness then Janus additive edit     | FR-K4-IW-083 / 085              | ADR-K4-004 + IV.1    |
| T-CLM-*     | RED witness then CLAUDE.md row           | FR-K4-IW-084                    | Forge agent dispatch |
| T-NSC-*     | RED witness then verify                  | FR-K4-IW-085 / NFR-005          | ADR-J8-004 inheritance|
| T-OQ-*      | Open-questions flip                      | Article III.4                   | J.8/K.3 precedent    |
| T-DOC-*     | No code, doc-only                        | FR-K4-IW-110..111               | CHANGELOG/GUIDE      |
| T-REV-*     | Final gate                               | Article V                       | All articles         |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement`.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 5     | 2                    | 22 stubs      |
| 2     | 12    | 1                    | 10 (per cluster) |
| 3     | 3     | 0                    | 7 (5 L1 + 2 L2)  |
| 4     | 11    | 0                    | 5 (per cluster) |
| 5     | 7     | 2                    | 0 (validation only) |
| **Total** | **38** | **5** | **44 RED witnesses** |
