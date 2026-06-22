# Tasks: b7-pythia

<!-- Status: implemented -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED), write the
  artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-K2-PYT-XXX]` (Article V.1, enforced by
  `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/b7-pythia.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms expected counter
  movement.
- ADRs from `design.md` (ADR-K2-001..005) are honored verbatim ; deviations
  require a new ADR.
- **BLOCKING PRECONDITION** : ADR-K2-001 (persona name, Q-001) MUST be ratified
  by the maintainer **before Phase 2** (the persona file is authored). Phase 1
  (RED harness) is name-agnostic and may proceed ; Phase 2+ cannot start until
  the name is locked. The harness resolves `PYTHIA_AGENT` from one variable
  (NFR-K2-PYT-007) so Phase 1 does not depend on the name.
- **DIVERGENCE FROM PRECEDENT** : per ADR-K2-003, this brick ships **NO scanner**
  (`bin/forge-*.sh`), **NO data file**, **NO new standard**. Tasks that would
  build those in the `k3-demeter` precedent are intentionally absent. NFR-K2-PYT-002
  is guarded by an explicit negative test (`_test_b7p_018_no_scanner`).

---

## Phase 1 — Foundation : RED harness (name-agnostic)

Goal : `b7-pythia.test.sh` exists with **18 L1 + 1 L2** stubs all FAIL ; full RED
state captured ; CI registration done. No persona name required yet.

### T-PHA — harness skeleton

- [x] **T-PHA-001** : Create `.forge/scripts/tests/b7-pythia.test.sh` with bash
      header (`#!/usr/bin/env bash`, `set -uo pipefail`, source `_helpers.sh`),
      PASS/FAIL counters, `--level 1,2` parsing, `print_summary` close-out.
      Mirror the `k3.test.sh` layout. Resolve `PYTHIA_AGENT` from a single
      variable defaulting to the ADR-K2-001 recommended path
      (`.claude/agents/delphi.md`) overridable by env, so the suite is
      name-agnostic. [Story: FR-K2-PYT-001 / NFR-K2-PYT-007]
- [x] **T-PHA-002** : Add **18 L1 test stubs** returning `_not_implemented`
      covering the 18 anchor IDs in `design.md` § "L1 anchor-level" table.
      [Story: FR-K2-PYT-001..086]
- [x] **T-PHA-003** [P] : Add **1 L2 fixture stub** (`_test_b7p_l2_anchor_integrity`)
      using `mk_tmpdir_with_trap`. [Story: NFR-K2-PYT-007]
- [x] **T-PHA-004** [P] : Register `b7-pythia.test.sh --level 1,2` in
      `.github/workflows/forge-ci.yml` `harnesses=(...)` array immediately after
      `"b7-2.test.sh --level 1"`. [Story: FR-K2-PYT (CI) / NFR-K2-PYT-005]
- [x] **T-PHA-005** : RED gate confirmed —
      `bash .forge/scripts/tests/b7-pythia.test.sh --level 1,2 > /tmp/b7p-red.log 2>&1` ;
      exit 1 ; `Failed: 19 / Passed: 0`. [Story: Article I]

**Phase 1 exit gate** : `b7-pythia.test.sh --level 1,2` exits 1 with `FAIL ≥ 19`,
`forge-ci.yml` matrix updated, `constitution-linter.sh` OVERALL PASS.

---

## Phase 0.5 — GATE : Q-001 maintainer ratification (BLOCKING)

- [x] **T-Q01-001** : Surface ADR-K2-001 + `open-questions.md` Q-001 to the
      maintainer. Obtain a ratified persona name + file path (recommended
      default : Option B — name the K.2 agent **Delphi**, keep
      Product-Analyst-Pythia). [Story: FR-K2-PYT-001 / Article III.4]
- [x] **T-Q01-002** : Once ratified, edit `open-questions.md` to flip Q-001 to
      `Status: answered` with a `### Resolution` block citing the maintainer
      decision + ADR-K2-001. Lock `PYTHIA_AGENT` in the harness to the ratified
      path (single-line edit, T-PHA-001 variable). [Story: Article III.4]

**Gate** : Phase 2 MUST NOT begin until T-Q01-002 is complete. If the maintainer
rejects Option B (e.g. picks Option A — rename the Product Analyst), an
**additional task family T-RENAME-*** is appended here to rename
`product-analyst.md` + the 4 referencing files (`forge-master.md` ×2,
`onboard.md`, `propose.md`) and update their dispatch rows — scoped at
ratification time, not pre-committed.

---

## Phase 2 — K.2.a : Pythia persona file

Goal : `.claude/agents/<pythia-name>.md` ships with all mandatory H2 sections +
audit comments + 4 checklist H3 + 6 K2-RULE entries. After this phase, 11 L1
tests flip GREEN (`_test_b7p_001..011`).

### T-PER — persona skeleton

- [x] **T-PER-001** : RED witness — convert `_test_b7p_001_persona_exists` +
      `_test_b7p_002_audit_comment` + `_test_b7p_003_persona_h2`.
      [Story: FR-K2-PYT-001..003 / 010]
- [x] **T-PER-002** : Create `.claude/agents/<pythia-name>.md` (ratified path)
      with :
      - `<!-- Audit: K.2 (b7-pythia) -->` + `<!-- Audit: B.7.4 (b7-pythia) -->`
        HTML comments at top.
      - H1 `# Agent: AI/RAG Specialist (<Pythia-Name>)`.
      - H2 `## Persona` per FR-K2-PYT-002 (Name / Role / Style — eval-driven).
      - H2 `## Purpose` per FR-K2-PYT-003 (cite K.2 + B.7.4 + the 3 b7-standards ;
        state `ai-native-rag`-scoped).
      [Story: FR-K2-PYT-001..003 / 010 / ADR-K2-001]
- [x] **T-PER-003** : Run harness ; expect 3 persona-skeleton L1 tests GREEN.
      [Story: FR-K2-PYT-001..003]

### T-CHK — checklists section

- [x] **T-CHK-001** : RED witness — convert `_test_b7p_004_checklists_h2` +
      `_test_b7p_005_checklists_items`. [Story: FR-K2-PYT-004]
- [x] **T-CHK-002** : Add `## Checklists` H2 with 4 H3 sub-sections (≥ 5 `[ ]`
      items each, Aegis/Demeter style with Verify/Check/Exception) :
      - **Embeddings & Retrieval** — chunking + tier-gated embedding model +
        hybrid retrieval + distance-op match (FR-K2-PYT-020..022).
      - **pgvector HNSW Tuning** — `ef_search` recall/latency eval-gated +
        `iterative_scan` + opclass match (FR-K2-PYT-023) + re-ranking
        (FR-K2-PYT-024).
      - **MCP Server Hardening** — least-privilege + input validation + no-exec +
        OAuth 2.1→Zitadel (FR-K2-PYT-025).
      - **Prompt Audit & Fallback** — prompt-audit span IX.6 (FR-K2-PYT-026) +
        budgets/kill-switch + mandatory fallback XI.5 (FR-K2-PYT-027) + PII XI.6.
      Cite the consumed b7-standard in each H3. [Story: FR-K2-PYT-004 / 020..027]
- [x] **T-CHK-003** : Run harness ; expect 2 checklist L1 tests GREEN.
      [Story: FR-K2-PYT-004]

### T-OUT — RAG Readiness Report shape

- [x] **T-OUT-001** : RED witness — convert `_test_b7p_006_output_h2`.
      [Story: FR-K2-PYT-005]
- [x] **T-OUT-002** : Add `## Output: RAG Readiness Report` H2 (advisory, mirrors
      Demeter report shape) : Summary table (Blocking/Concern/Advisory/Cleared
      counts) + Findings template (`[SEVERITY] <K2-RULE-NNN>:` + Category /
      Location / Evidence / Recommendation / Verification) + Cleared Items +
      overall status line (BLOCKED only on K2-RULE-006 / TUNING-NEEDED on any
      Concern / READY otherwise). [Story: FR-K2-PYT-005]
- [x] **T-OUT-003** : Run harness ; expect 1 output-shape L1 test GREEN.
      [Story: FR-K2-PYT-005]

### T-CAT — recommendation catalogue (K2-RULE-001..006)

- [x] **T-CAT-001** : RED witness — convert `_test_b7p_007_rule_catalogue` +
      `_test_b7p_008_fallback_blocking`. [Story: FR-K2-PYT-006 / 120..125]
- [x] **T-CAT-002** : Add `## Recommendation Catalogue` H2 with a table
      enumerating K2-RULE-001..006 per FR-K2-PYT-120..125. Each row : trigger,
      severity (Advisory/Concern/Blocking), evidence pattern, recommendation,
      b7-standard / Article cross-link. K2-RULE-006 MUST be `Blocking` and cite
      XI.5. Document the severity vocabulary + the ADR-J8-004 numbering invariant.
      [Story: FR-K2-PYT-006 / 120..125 / ADR-K2-002]
- [x] **T-CAT-003** : Run harness ; expect rule-catalogue + fallback-blocking L1
      tests GREEN. [Story: FR-K2-PYT-006 / 125]

### T-INT — integration + anti-hallucination + standards-consumed + footer

- [x] **T-INT-001** : RED witness — convert `_test_b7p_009_integration` +
      `_test_b7p_010_anti_halluc` + `_test_b7p_011_standards_consumed`.
      [Story: FR-K2-PYT-007 / 008 / 003]
- [x] **T-INT-002** : Add `## Integration` H2 documenting : Janus Step 3 dispatch
      for `ai-native-rag` (cross-link to `cross-layer-orchestrator.md` Step 3 as
      modified by ADR-K2-004) ; relationship to Oracle (brainstorm vs tune) ;
      relationship to Demeter (disjoint surfaces) ; relationship to Vulcan/Hera
      (advise vs implement). Reference all three b7-standards by name (satisfies
      `_test_b7p_011`). [Story: FR-K2-PYT-007 / ADR-K2-004]
- [x] **T-INT-003** : Add `## Anti-Hallucination Protocol` H2 — Article III.4
      contract : emit `[NEEDS CLARIFICATION:]` and STOP when a tuning target is
      unspecified (no eval set for `ef_search`, undeclared embedding model,
      undeclared tier) ; never fabricate `ef_search` / chunk-size / recall@k.
      [Story: FR-K2-PYT-008 / 121 / NFR (anti-halluc)]
- [x] **T-INT-004** : Add file footer with the audit cross-references per
      FR-K2-PYT-011 (new-archetypes-plan §9 / §6.2 / §0.12 + ARCHITECTURE-TARGET
      §9.2 + the 3 b7-standards). [Story: FR-K2-PYT-011]
- [x] **T-INT-005** : Run harness ; expect integration + anti-halluc +
      standards-consumed L1 tests GREEN. [Story: FR-K2-PYT-007 / 008 / 003]

**Phase 2 exit gate** : 11 L1 tests GREEN (`_test_b7p_001..011`). `verify.sh`
aggregate unchanged. `constitution-linter.sh` OVERALL PASS.

---

## Phase 3 — K.2.b/c : Standards-index + Janus + CLAUDE.md integration

Goal : additive `index.yml` triggers, Janus delta-edited (Dispatch Table + Step 3
note + Quality Gates bullet), CLAUDE.md row added, negative guards pass. After
this phase, the remaining 7 L1 tests flip GREEN (`_test_b7p_012..018`).

### T-IDX — standards-index additive triggers (ADR-K2-005)

- [x] **T-IDX-001** : RED witness — convert `_test_b7p_012_index_triggers` +
      `_test_b7p_013_no_new_standard`. [Story: FR-K2-PYT-080 / 081]
- [x] **T-IDX-002** : Edit `.forge/standards/index.yml` — extend the `triggers:`
      arrays of `global/rag-patterns`, `global/llm-gateway`, `global/mcp-servers`
      (the B.7.3 block) with the ratified persona-name keyword (e.g. `pythia` or
      `delphi`) ; add `ef-search` + `embeddings-tuning` to `rag-patterns`. NO new
      index entry, NO new standard file. [Story: FR-K2-PYT-080 / ADR-K2-005]
- [x] **T-IDX-003** : Run harness + `validate-standards-yaml.sh` ; expect index
      triggers + no-new-standard L1 tests GREEN and J.7 still PASS.
      [Story: FR-K2-PYT-080 / 081 / NFR-K2-PYT-004 / 005]

### T-JAN — Janus delta edit (ADR-K2-004, Article IV.1)

- [x] **T-JAN-001** : RED witness — convert `_test_b7p_014_janus_dispatch_row` +
      `_test_b7p_015_janus_step3_note`. [Story: FR-K2-PYT-082 / 083 / ADR-K2-004]
- [x] **T-JAN-002** : Edit `.claude/agents/cross-layer-orchestrator.md` Dispatch
      Table — insert the `<Pythia-Name>` AI/RAG row AFTER the Demeter row (line
      32) and BEFORE the closing `---` (line 34) per the verbatim block in
      ADR-K2-004. Do NOT modify any other row ; do NOT touch the Step 9 narrative
      or the Forbidden-archetypes catalogue (b7-9-janus-ai territory).
      [Story: FR-K2-PYT-082 / ADR-K2-004 / NFR-K2-PYT-006]
- [x] **T-JAN-003** : Edit `### Step 3 — Parallel Design Dispatch` — append the
      `ai-native-rag` Pythia AI-pipeline design-pass paragraph per ADR-K2-004.
      Add a one-bullet "AI/RAG readiness gate" entry to the **Quality Gates** H2.
      Leave Step 9 (Aegis + Demeter) UNCHANGED. [Story: FR-K2-PYT-083 / ADR-K2-004]
- [x] **T-JAN-004** [P] : Edit Janus **Constitution compliance** H2 — add one
      bullet citing AI-First (Article XI.5 + IX.6) reviewed by `<Pythia-Name>` for
      `ai-native-rag`. [Story: FR-K2-PYT-083 / ADR-K2-004]
- [x] **T-JAN-005** : Run harness ; expect 2 Janus L1 tests GREEN ; assert Step 9
      Demeter narrative byte-unchanged (k3.test.sh `_test_k3_018` still GREEN).
      [Story: FR-K2-PYT-082..083 / NFR-K2-PYT-005 / 006]

### T-CLM — CLAUDE.md trigger row

- [x] **T-CLM-001** : RED witness — convert `_test_b7p_016_claude_md_trigger`.
      [Story: FR-K2-PYT-084]
- [x] **T-CLM-002** : Edit repo `CLAUDE.md` agent-delegation table (lines ~61-71)
      — insert a row routing AI/RAG tuning work to `<Pythia-Name>` (AI/RAG
      Specialist), adjacent to the `AI features | Oracle` row. Exact row text per
      the ratified name (ADR-K2-001). [Story: FR-K2-PYT-084]
- [x] **T-CLM-003** : Run harness ; expect CLAUDE.md L1 test GREEN.
      [Story: FR-K2-PYT-084]

### T-NSC — namespace + no-scanner guards

- [x] **T-NSC-001** : RED witness — convert `_test_b7p_017_no_namespace_collision`
      + `_test_b7p_018_no_scanner`. [Story: FR-K2-PYT-086 / NFR-K2-PYT-002]
- [x] **T-NSC-002** : Verify (no edit needed if invariants hold) :
      `grep -r "K2-RULE" .claude/agents/cross-layer-orchestrator.md
      .forge/standards/global/janus-orchestration-rules.md
      .claude/agents/demeter.md` returns empty (the J8/K3 surfaces never reference
      K2-RULE) AND `grep -rE "J8-RULE|K3-RULE" <PYTHIA_AGENT>` returns empty
      except as cross-link acknowledgement ; AND no `bin/forge-pythia*.sh` /
      `.forge/data/pythia*.yml` exist. [Story: FR-K2-PYT-086 / NFR-K2-PYT-002 /
      ADR-K2-003]
- [x] **T-NSC-003** : Run harness `--level 1,2` ; expect ALL 19 tests (18 L1 + 1
      L2) GREEN. [Story: FR-K2-PYT-086 / 101 / NFR-K2-PYT-007]

### T-L2 — L2 fixture

- [x] **T-L2-001** : RED witness — convert `_test_b7p_l2_anchor_integrity`.
      [Story: NFR-K2-PYT-007]
- [x] **T-L2-002** : Implement the L2 fixture — copy `$PYTHIA_AGENT` into a
      tmpdir, re-run the L1 anchor greps (H2/H3 + K2-RULE-001..006) against the
      isolated copy ; assert all present (proves the persona is self-contained,
      no scanner needed). [Story: NFR-K2-PYT-007 / ADR-K2-003]
- [x] **T-L2-003** : Run harness `--level 1,2` ; expect 19/19 GREEN ≤ 5 s.
      [Story: NFR-K2-PYT-007]

**Phase 3 exit gate** : `b7-pythia.test.sh --level 1,2` 19/19 GREEN (18 L1 + 1
L2). `verify.sh` aggregate unchanged or +1. `constitution-linter.sh` OVERALL
PASS. `validate-standards-yaml.sh` / `j7` / `j8` / `k3` GREEN (no regression).

---

## Phase 4 — Quality : docs + CHANGELOG + open-questions flip + review

### T-OQ — open-questions flip

- [x] **T-OQ-001** : Edit `open-questions.md` to flip Q-002 + Q-003 from
      `Status: open` to `Status: answered` with `### Resolution` blocks citing
      ADR-K2-002 / ADR-K2-003. **Q-001 stays `open` (BLOCKING) until the
      maintainer ratifies ADR-K2-001 (T-Q01-002)** — the archival gate checks
      Q-001 is `answered`, so this change cannot archive until ratification.
      [Story: Article III.4]

### T-DOC — documentation

- [x] **T-DOC-001** [P] : Add an agent-catalogue entry for `<Pythia-Name>` (AI/RAG
      Specialist) to the agents doc located at impl time (likely a section in
      `docs/` or the `forge-master.md` roster — locked at impl). Summarise
      persona + 4 responsibilities + Janus Step 3 dispatch. [Story: FR-K2-PYT-007]
- [x] **T-DOC-002** [P] : Add a `## [Unreleased]` entry in `CHANGELOG.md`
      covering the K.2 Pythia/`<Pythia-Name>` AI/RAG specialist (persona + Janus
      delta + standards-index triggers + harness). Note the Q-001 rename if
      Option A was chosen. [Story: FR-K2-PYT (docs)]
- [ ] **T-DOC-003** [P] : Resync `docs/new-archetypes-plan.md` §0.12 brick table
      line 2022 (brick #4 ⏳ pending → ✅ archived) + §9 K.2 row status. (Separate
      maintainer resync task per the b7-2-scaffolder NFR-B7-2-001 precedent —
      committed separately if the repo convention requires.) [Story: audit trail]

### T-REV — quality review gate

- [ ] **T-REV-001** : Run `/forge:review b7-pythia` driving the constitutional
      gate : Articles I (TDD), III + III.4 (Q-001 BLOCKING check), IV (delta), V
      (audit trail), IX.6 (prompt audit enforced), XI.1/3/5/6 (AI-First
      enforced), XII (governance — no new standard, no amendment). Block if any
      returns VIOLATION. [Story: Article V]
- [x] **T-REV-002** : Run full `verify.sh` + all sibling harnesses (`j7` / `j8` /
      `k3` / `b7-1` / `b7-2a` / `b7-3` / `b7-2`) on a clean checkout ; confirm no
      regression (NFR-K2-PYT-005). [Story: NFR-K2-PYT-005]
- [ ] **T-REV-003** : Verify `bin/forge-questions.sh --change b7-pythia --status
      open` returns ONLY Q-001 (BLOCKING) until maintainer ratification ; empty
      after T-Q01-002. The change MUST NOT archive while Q-001 is open.
      [Story: Article III.4]
- [x] **T-REV-004** : Smoke the 3 BDD scenarios from specs.md as a manual reviewer
      read-through of the persona (dispatch wiring / K2-RULE-006 Blocking gate /
      `ef_search` NEEDS-CLARIFICATION) — no executable to run (advisory agent).
      [Story: Article II]
- [x] **T-REV-005** : Confirm the Janus Step 3 note + Dispatch Table row read
      cleanly and the Step 9 Demeter narrative + Forbidden-archetypes catalogue
      are untouched (collision guard vs b7-9-janus-ai). [Story: NFR-K2-PYT-006]

**Phase 4 exit gate (= change archival readiness)** :

- `b7-pythia.test.sh --level 1,2` 19/19 PASS / 0 FAIL / ≤ 5 s.
- `verify.sh` aggregate ≥ baseline / RESULT: PASS.
- `constitution-linter.sh` OVERALL PASS (no new WARN).
- `j7` / `j8` / `k3` / `b7-1` / `b7-2a` / `b7-3` / `b7-2` unchanged.
- `validate-standards-yaml.sh` exits 0 (index.yml edit is additive ; no new
  standard).
- **Q-001 ratified by the maintainer + flipped to `answered`** (BLOCKING — the
  change cannot archive otherwise) ; Q-002 + Q-003 `answered`.
- All FR-K2-PYT-001..125 + NFR-K2-PYT-001..007 tasks checked.
- `CHANGELOG.md` `## [Unreleased]` entry.

---

## Constitutional task review (per Article V)

| Task family | TDD order                                  | Spec link                       | Architecture                   |
|-------------|--------------------------------------------|---------------------------------|--------------------------------|
| T-PHA-*     | RED phase (intentional)                    | FR-K2-PYT-001..086              | name-agnostic harness          |
| T-Q01-*     | BLOCKING gate (maintainer ratification)    | FR-K2-PYT-001 / Article III.4   | ADR-K2-001                     |
| T-PER-*     | RED witness then persona skeleton          | FR-K2-PYT-001..003 / 010        | ADR-K2-001                     |
| T-CHK-*     | RED witness then 4 checklist H3            | FR-K2-PYT-004 / 020..027        | Aegis/Demeter pattern          |
| T-OUT-*     | RED witness then report H2                 | FR-K2-PYT-005                   | Demeter report template (advisory) |
| T-CAT-*     | RED witness then rule table                | FR-K2-PYT-006 / 120..125        | ADR-K2-002                     |
| T-INT-*     | RED witness then integration + anti-halluc | FR-K2-PYT-007..008 / 011 / 003  | ADR-K2-004                     |
| T-IDX-*     | RED witness then additive triggers         | FR-K2-PYT-080..081              | ADR-K2-005 (NO new standard)   |
| T-JAN-*     | RED witness then Janus delta-edit          | FR-K2-PYT-082..083              | ADR-K2-004 + Article IV.1      |
| T-CLM-*     | RED witness then CLAUDE.md row             | FR-K2-PYT-084                   | Forge agent dispatch convention|
| T-NSC-*     | RED witness then verify (guards)           | FR-K2-PYT-086 / NFR-K2-PYT-002  | ADR-K2-003 (no scanner)        |
| T-L2-*      | RED witness then anchor-integrity fixture  | NFR-K2-PYT-007                  | ADR-K2-003 (no scanner L2)     |
| T-OQ-*      | Open-questions flip (Q-001 stays BLOCKING) | Article III.4                   | k3-demeter precedent           |
| T-DOC-*     | No code, doc-only                          | FR-K2-PYT (docs)                | CHANGELOG + plan-resync conventions |
| T-REV-*     | Final gate, no production code             | Article V / II / III.4          | All articles                   |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement` **after Q-001
ratification (T-Q01)**.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 5     | 2                    | 19 stubs      |
| 0.5   | 2     | 0                    | 0 (gate)      |
| 2     | 16    | 0                    | 11 (per cluster) |
| 3     | 14    | 1                    | 8 (per cluster) |
| 4     | 9     | 4                    | 0 (validation only) |
| **Total** | **46** | **7** | **38 RED witnesses** |

Estimated wall-clock at single-developer pace : Phase 1 ≈ 1 h, Q-001 gate ≈
maintainer-latency-bound, Phase 2 ≈ 3–4 h, Phase 3 ≈ 2–3 h, Phase 4 ≈ 1 h. Total
≈ 1.5–2 working days (smaller than k3-demeter's 2–2.5 days because there is no
scanner / Python engine / data file), consistent with the **M** complexity
estimate in `proposal.md` (`new-archetypes-plan` §9 row K.2 effort = `M`).
