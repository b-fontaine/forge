# Tasks: b6-10-janus-rule

<!-- Audit: B.6.10 (b6-10-janus-rule) -->

## Convention

- TDD is mandatory (Article I) : the `b6-10.test.sh` harness is written with
  real assertions FIRST, run against the absent implementation to witness RED,
  then each cluster is implemented to GREEN, then refactored.
- Audit trail tag `[Story: FR-B6-JR-XXX]` (Article V.1) on every task.
- Rule IDs `J8-RULE-007/008` are the next free block (ADR-B6-JR-001) ; NEVER
  reuse (ADR-J8-004 invariant).
- All deltas additive (NFR-B6-JR-001) : REUSE `_refuse_if_forbidden_combination`
  (do NOT modify/duplicate), do NOT renumber `J8-RULE-001..006`, do NOT edit
  the event-driven-eu schema/templates.
- Collision discipline : every edit to `cross-layer-orchestrator.md` stays
  INSIDE the existing "Forbidden archetypes & combinations" H2 (new H3
  sub-section only), never the "Dispatch Table" H2.

---

## Phase 1 — Foundation : RED harness

### T-PHA — `b6-10.test.sh` (RED)

- Create `.forge/scripts/tests/b6-10.test.sh` mirroring `b7-9.test.sh` :
  `--level` parse, `source _helpers.sh`, file-path vars, MANIFEST block,
  PASS/FAIL counters, the `_mk_combo_fixture` + `_run_combo_helper` L2 helpers.
  [Story: FR-B6-JR-080]
- Write real L1 + L2 assertions (design.md § Testing Strategy).
  [Story: FR-B6-JR-081/082]
- Run `bash .forge/scripts/tests/b6-10.test.sh --level 1,2` — confirm RED
  (all fail against absent implementation). [Story: FR-B6-JR-080..082]

---

## Phase 2 — B.6.10.2 : dispatch-table entries

### T-DT — `forbidden_combinations:` seed entries

- Append TWO entries (confluent-cloud/any/J8-RULE-007 ;
  us-managed-kafka/T3/J8-RULE-008) to the EXISTING `forbidden_combinations:`
  list under a B.6.10 audit sub-comment, `since: "0.6.0"`.
  [Story: FR-B6-JR-020/021 / ADR-B6-JR-002/003]
- Re-run L1 — `_test_b6_10_020/021` flip GREEN.

---

## Phase 3 — B.6.10.1 : Janus agent new rules

### T-JAN — new H3 sub-section + `J8-RULE-007..008`

- In `.claude/agents/cross-layer-orchestrator.md`, INSIDE the existing
  `## Forbidden archetypes & combinations` H2, between the J.8.c
  `### LLM-provider rules` H3 and the `### Refusal semantics` H3, insert a NEW
  `### Event-broker rules (\`event-driven-eu\`)` H3 with the audit anchor
  `<!-- Audit: B.6.10 (b6-10-janus-rule) -->`.
  [Story: FR-B6-JR-001/005]
- Author `#### J8-RULE-007` (Confluent Cloud) + `#### J8-RULE-008` (T3
  US-managed Kafka), each with the four sub-bullets (Rationale / Reference /
  Alternative / tier applicability) per the `J8-RULE-004..006` shape.
  [Story: FR-B6-JR-002..004 / ADR-B6-JR-003]
- Re-run L1 — `_test_b6_10_001/002/003/004` flip GREEN.

---

## Phase 4 — B.6.10.3 : wrapper invokes the reused helper

### T-WRP — wrapper call site

- In `bin/forge-init-event-driven-eu.sh`, AFTER the scaffoldability gate, add
  a `declare -f`-guarded `_refuse_if_forbidden_combination "event-driven-eu"
  "${FORGE_EDE_EVENT_BROKER:-nats-jetstream}"` invocation (mirroring the
  ai-native-rag wrapper). Leave the existing `_refuse_if_forbidden` call + the
  exit-3-while-candidate gate intact. [Story: FR-B6-JR-040/041 / NFR-B6-JR-001]
- Re-run L1 — `_test_b6_10_041` flips GREEN. Run the L2 fixtures — all GREEN.

---

## Phase 5 — B.6.10.4 : standards updates

### T-STD-JAN — `janus-orchestration-rules.md`

- Add two rows (`J8-RULE-007/008`) to the rule-catalogue table ; update
  "Refusal vs warning semantics". [Story: FR-B6-JR-060/061]
- Re-run L1 — `_test_b6_10_060` flips GREEN.

### T-STD-I3 — I.3 review-time coupling

- Add `confluent-cloud` to `global/compliance-tiers.md::forbidden:` ; SemVer
  minor bump `1.1.0 → 1.2.0` (dates → 2026-07-10 / 2027-07-10) + status note.
  [Story: FR-B6-JR-062]
- Add a `confluent-cloud` `REMEDIATION` entry in
  `constitution-linter.sh::ADR-I3-001`. [Story: FR-B6-JR-063]
- Add the event-broker interim-gap subsection to
  `global/forbidden-components-rules.md` ; SemVer minor bump `1.1.0 → 1.2.0`.
  [Story: FR-B6-JR-064]
- Re-run L1 + `i2.test.sh` + `i3.test.sh` + `constitution-linter.sh` — GREEN,
  no regression. [Story: FR-B6-JR-062..064 / NFR-B6-JR-002/005]

---

## Phase 6 — B.6.10.6 : sibling coupling + CI + docs

### T-B79 — relax b7-9 numbering guard

- Relax `.forge/scripts/tests/b7-9.test.sh::_test_b7_9_005_rule_004_is_next_free`
  upper-bound regex `J8-RULE-0(0[7-9]|[1-9][0-9])` → `J8-RULE-0(09|[1-9][0-9])`
  + a coupling comment. Re-run `b7-9.test.sh --level 1,2` — GREEN.
  [Story: FR-B6-JR-090 / ADR-B6-JR-006]

### T-CI — register harness

- Append `"b6-10.test.sh --level 1,2"` to the `harnesses=( … )` array in
  `.github/workflows/forge-ci.yml`. [Story: FR-B6-JR-083]

### T-DOC — documentation

- `docs/ARCHETYPES.md` : add `J8-RULE-007/008` table rows + the "Event-broker
  refusals" note + the `--eu-tier` T3 note. [Story: FR-B6-JR-100]
- `CHANGELOG.md` : `## [Unreleased]` → `### Added` entry. [Story: FR-B6-JR-101]

### T-REG — regression gate

- Run `verify.sh`, `constitution-linter.sh`, `validate-standards-yaml.sh`,
  `j7`, `j8.test.sh`, `b7-9.test.sh`, `i2.test.sh`, `i3.test.sh`, `b6-10.test.sh`
  — confirm GREEN / no regression. Confirm a fresh `forge init --archetype
  event-driven-eu` still refuses exit 3 (candidate). [Story: NFR-B6-JR-002]

### T-SPEC — consolidated-spec append (at archive)

- APPEND the B.6.10 ADDED-requirements block to `.forge/specs/janus-rules.md`
  (do NOT overwrite the J.8.a/b/c/d blocks). Update `.forge.yaml`
  `archived_to:` + `timeline:`. [Story: NFR-B6-JR-006]

---

## Story coverage map

| FR cluster | Phase | Tasks |
|------------|-------|-------|
| Cluster 1 (FR-B6-JR-001..005) — agent rules | 3 | T-JAN |
| Cluster 2 (FR-B6-JR-020..021) — registry | 2 | T-DT |
| Cluster 3 (FR-B6-JR-040..041) — wrapper | 4 | T-WRP |
| Cluster 4 (FR-B6-JR-060..064) — standards | 5 | T-STD-JAN, T-STD-I3 |
| Cluster 5 (FR-B6-JR-080..083) — harness + CI | 1, 6 | T-PHA, T-CI |
| Cluster 6 (FR-B6-JR-090/100/101) — coupling + docs | 6 | T-B79, T-DOC |
| NFRs | all | T-REG, T-SPEC |
