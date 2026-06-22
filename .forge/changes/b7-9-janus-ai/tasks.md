# Tasks: b7-9-janus-ai

<!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) -->

## Convention

- TDD is mandatory (Article I) : every Phase writes/extends the RED
  witness FIRST (`b7-9.test.sh` stubs returning `_not_implemented`),
  confirms RED, then implements to GREEN, then refactors.
- Audit trail tag `[Story: FR-B7-9-XXX]` (Article V.1) on every task.
- Rule IDs `J8-RULE-004/005/006` are the next free block (ADR-B7-9-001) ;
  NEVER reuse (ADR-J8-004 invariant).
- Collision discipline (ADR-B7-9-004) : every edit to
  `cross-layer-orchestrator.md` stays INSIDE the existing "Forbidden
  archetypes & combinations" H2 — never touch the "Dispatch Table" H2
  (that is `b7-pythia`'s region).
- All deltas additive (NFR-B7-9-001) : do NOT modify
  `_refuse_if_forbidden`, do NOT renumber `J8-RULE-001..003`, do NOT
  edit the ai-native-rag schema/templates.

> NOTE — this is the PLAN. No test bodies or production code are written
> by the planning brick. The tasks below are the implementation
> roadmap for `/forge:implement`.

---

## Phase 1 — Foundation : RED harness skeleton

### T-PHA — `b7-9.test.sh` skeleton  — [x] done (2026-06-22)

- Create `.forge/scripts/tests/b7-9.test.sh` mirroring `j8.test.sh` /
  `i3.test.sh` : `--level` parse, `source _helpers.sh`, file-path
  vars (agent, dispatch-table, helper, ai-native-rag wrapper, the three
  standards, the linter), MANIFEST block, PASS/FAIL counters.
  [Story: FR-B7-9-080]
- Stub all L1 tests (table in `design.md` § "L1 grep-level") returning
  `_not_implemented`. [Story: FR-B7-9-081]
- Stub the two L2 fixture tests using `mk_tmpdir_with_trap`.
  [Story: FR-B7-9-082]
- Run `bash .forge/scripts/tests/b7-9.test.sh --level 1,2` — confirm RED
  (`Failed: 13 / Passed: 0`, exit 1). [Story: FR-B7-9-080..082]

---

## Phase 2 — J.8.c.1 : Janus agent new rules

### T-JAN — new H3 sub-section + `J8-RULE-004..006`  — [x] done (2026-06-22)

- Confirm RED on `_test_b7_9_001_agent_h3_section`,
  `_test_b7_9_002_rule_004`, `_test_b7_9_003_rule_005`,
  `_test_b7_9_004_rule_006`, `_test_b7_9_005_rule_004_is_next_free`.
  [Story: FR-B7-9-001..006]
- In `.claude/agents/cross-layer-orchestrator.md`, INSIDE the existing
  `## Forbidden archetypes & combinations` H2, between the `J8-RULE-003`
  H4 and the `### Refusal semantics` H3, insert a NEW
  `### LLM-provider rules (\`ai-native-rag\`)` H3 with the audit anchor
  `<!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) -->`.
  [Story: FR-B7-9-001/006 / ADR-B7-9-004]
- Author `#### J8-RULE-004` (Vertex AI), `#### J8-RULE-005` (Bedrock),
  `#### J8-RULE-006` (T3 US-managed inference), each with the four
  sub-bullets (Rationale / Reference / Alternative / tier applicability)
  per the `J8-RULE-001..003` shape. Cite `compliance-tiers.md` §10.2 rows
  verbatim (ADR-B7-9-006). [Story: FR-B7-9-002..005 / ADR-B7-9-001/006]
- Re-run L1 — those tests flip GREEN. [Story: FR-B7-9-001..006]

### T-DT — `forbidden_combinations:` registry  — [x] done (2026-06-22)

- Confirm RED on `_test_b7_9_020_combinations_key`,
  `_test_b7_9_021_entry_shape`, `_test_b7_9_022_seed_entries`.
  [Story: FR-B7-9-020..022]
- In `.forge/scaffolding/dispatch-table.yml`, append a NEW top-level
  `forbidden_combinations:` list (sibling to `forbidden_archetypes:`)
  with a documenting comment header + the three seed entries
  (7 keys each : archetype/provider/tier/reason/since/alternative/rule_id),
  `since: "0.5.0"`. [Story: FR-B7-9-020..023 / ADR-B7-9-002]
- Re-run L1 — flip GREEN. [Story: FR-B7-9-020..022]

---

## Phase 3 — J.8.c.3 : combination-refusal helper + wrapper

### T-HLP — `_refuse_if_forbidden_combination`  — [x] done (2026-06-22)

- Confirm RED on `_test_b7_9_040_helper_fn`,
  `_test_b7_9_043_refusal_format`. [Story: FR-B7-9-040/043]
- In `bin/_forge-init-helpers.sh`, add the NEW function
  `_refuse_if_forbidden_combination "<archetype>" "<provider>"` ALONGSIDE
  (never replacing) `_refuse_if_forbidden`. Reuse the forge-root
  discovery + PyYAML inline parse. Tier resolution :
  `$FORGE_EU_TIER` → `.forge/.forge-tier` first line → empty (empty ⇒
  only `tier: any` matches — no guessed default, Article III.4).
  [Story: FR-B7-9-040..042 / ADR-B7-9-003 / ADR-J8-005]
- Match predicate + emit `[REFUSAL: <archetype>/<provider>@<tier>:
  <rule_id>: <reason> ; alternative: <alt>]` to stderr + `exit 3` ;
  no-match / unreachable table → `return 0` (fail-open).
  [Story: FR-B7-9-042..044 / ADR-J8-003]
- Re-run L1 — flip GREEN. [Story: FR-B7-9-040..044]

### T-WRP — wrapper sources + invokes helper  — [x] done (2026-06-22)

- Confirm RED on `_test_b7_9_045_wrapper_invokes`. [Story: FR-B7-9-045]
- In `bin/forge-init-ai-native-rag.sh`, source `_forge-init-helpers.sh`
  (if not already) and invoke `_refuse_if_forbidden_combination
  "ai-native-rag" "<configured-provider>"` for the scaffold's LLM-gateway
  provider, positioned so it fires post-promotion. Leave any existing
  `_refuse_if_forbidden "ai-native-rag"` call intact ; keep the
  exit-3-while-candidate gate (ADR-B7-2-001) untouched.
  [Story: FR-B7-9-045 / NFR-B7-9-001]
- Re-run L1 — flip GREEN. [Story: FR-B7-9-045]

---

## Phase 4 — J.8.c.4 : standards updates

### T-STD-JAN — `janus-orchestration-rules.md`  — [x] done (2026-06-22)

- Confirm RED on `_test_b7_9_060_std_rows`. [Story: FR-B7-9-060]
- Add three rows (`J8-RULE-004/005/006`) to the rule-catalogue table ;
  update "Extending the catalogue" step 1 prose ("now exists") ; note
  the new refusals in "Refusal vs warning semantics" ; bump `version:`
  (SemVer minor) + append `REVIEW.md` entry.
  [Story: FR-B7-9-060/061]
- Re-run L1 — flip GREEN. [Story: FR-B7-9-060]

### T-STD-I3 — I.3 review-time coupling (Q-003-gated)  — [x] done (2026-06-22, in-brick per Q-003)

> Only if Q-003 resolves "in-brick" (the design default). If the
> maintainer defers, this task moves to a follow-up change and the
> `_test_b7_9_062_tokens` test is removed from the harness.

- Confirm RED on `_test_b7_9_062_tokens`. [Story: FR-B7-9-062/063]
- Add `vertex-ai` + `bedrock` to
  `global/compliance-tiers.md::forbidden:` (was `[]`) ; SemVer minor
  bump + `REVIEW.md` entry + sync note re §10.2. [Story: FR-B7-9-062]
- Add `REMEDIATION` entries for the two tokens in
  `constitution-linter.sh::ADR-I3-001`. [Story: FR-B7-9-063]
- Add the LLM-provider interim-gap note to
  `global/forbidden-components-rules.md`. [Story: FR-B7-9-064]
- Re-run L1 + `i3.test.sh` + `constitution-linter.sh` — GREEN, no
  regression. [Story: FR-B7-9-062..064 / NFR-B7-9-002/005]

---

## Phase 5 — L2 fixtures + CI registration

### T-L2 — fixture tests  — [x] done (2026-06-22)

- Implement `_test_b7_9_l2_refuse_t3` (T3 + us-managed-inference ⇒
  exit 3 + `J8-RULE-006`) and `_test_b7_9_l2_t1_no_refuse` (T1 +
  openai-via-eu-gateway ⇒ exit 0, no `[REFUSAL:`).
  [Story: FR-B7-9-082 / NFR-B7-9-005]
- Run `--level 1,2` — all GREEN, ≤ 15 s. [Story: FR-B7-9-080..082]

### T-CI — register harness  — [x] done (2026-06-22)

- Append `"b7-9.test.sh --level 1,2"` to the `harnesses=( … )` array in
  `.github/workflows/forge-ci.yml` after the `b7-2.test.sh` entry.
  [Story: FR-B7-9-083]

---

## Phase 6 — Docs + regression + spec append

### T-DOC — documentation  — [x] done (2026-06-22)

- `docs/ARCHETYPES.md` : add the "LLM-provider refusals" note
  (`J8-RULE-004..006` + Mistral-EU / vLLM alternative).
  [Story: FR-B7-9-100]
- `CHANGELOG.md` : `## [Unreleased]` entry for the J.8.c sub-module.
  [Story: FR-B7-9-101]

### T-REG — regression gate  — [x] done (2026-06-22 ; Tribune/Janus review pass left to orchestrator)

- Run `verify.sh`, `constitution-linter.sh`, `validate-standards-yaml.sh`,
  `j7`, `j8.test.sh`, `i3.test.sh`, `b5`, `b7-1`, `b7-2a`, `b7-2`, `b7-3`
  — confirm GREEN / no regression. Confirm a fresh
  `forge init --archetype ai-native-rag` still refuses exit 3 (candidate).
  [Story: NFR-B7-9-002]
- Run the Rust quality gate (Tribune) + Janus review on the agent-file
  edit if dispatched. [Story: NFR-B7-9-001]

### T-SPEC — consolidated-spec append (at archive)  — [ ] deferred to ARCHIVE-time (not done in implement)

- APPEND the J.8.c ADDED-requirements block to
  `.forge/specs/janus-rules.md` (do NOT overwrite the J.8.a/b/d blocks).
  Update `.forge.yaml` `archived_to:` + `timeline:`. [Story: NFR-B7-9-006]

---

## Story coverage map

| FR cluster | Phase | Tasks |
|------------|-------|-------|
| Cluster 1 (FR-B7-9-001..006) — agent rules | 2 | T-JAN |
| Cluster 2 (FR-B7-9-020..023) — registry | 2 | T-DT |
| Cluster 3 (FR-B7-9-040..045) — helper + wrapper | 3 | T-HLP, T-WRP |
| Cluster 4 (FR-B7-9-060..064) — standards | 4 | T-STD-JAN, T-STD-I3 |
| Cluster 5 (FR-B7-9-080..083) — harness + CI | 1, 5 | T-PHA, T-L2, T-CI |
| Cluster 6 (FR-B7-9-100..101) — docs | 6 | T-DOC |
| NFRs | all | T-REG, T-SPEC |
