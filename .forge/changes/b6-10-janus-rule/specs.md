# Spec: b6-10-janus-rule

<!-- Audit: B.6.10 (b6-10-janus-rule) — Janus refusal rules for the        -->
<!-- event-driven-eu archetype's event broker : refuse Confluent Cloud     -->
<!-- (US-managed Kafka SaaS) as event broker regardless of tier ; at        -->
<!-- --eu-tier T3 refuse any US-managed Kafka SaaS. Sanctioned default =    -->
<!-- self-hosted NATS JetStream / Redpanda (EU-deployable).                 -->
<!-- Source plan : docs/new-archetypes-plan.md §6.1 (B.6.10).               -->

**Namespace** : `FR-B6-JR-*` / `NFR-B6-JR-*` / `ADR-B6-JR-*`.
**Constitution** : v2.0.0. No amendment required (B.6.10 ENFORCES the
EU-sovereign event-broker posture already encoded in the archetype schema
`event_specifics.eu_sovereignty` + `compliance-tiers.md` §10.2 ; it does not
modify any article).

**Rule-ID allocation** : NEW `J8-RULE-NNN` entries in the existing J.8
namespace (ADR-J8-004 — IDs NEVER reused). The live catalogue ends at
`J8-RULE-006` (`b7-9-janus-ai`, verified) ; this change allocates the next
sequential block **`J8-RULE-007`** (Confluent Cloud any-tier default refusal)
+ **`J8-RULE-008`** (`--eu-tier T3` ⇒ US-managed Kafka SaaS refused).

**Relationship to J.8 / B.7.9** : this is the **direct sibling** of J.8.c
(`b7-9-janus-ai`) — same `forbidden_combinations:` registry, same
`_refuse_if_forbidden_combination` helper (REUSED, not re-created), same
exit-3 / `[REFUSAL:]` convention, same I.3 review-time token coupling. At
archive time, the ADDED block below is APPENDED to `.forge/specs/janus-rules.md`.

---

## Functional Requirements

### Cluster 1 — Janus agent new rules (`J8-RULE-007..008`)

#### FR-B6-JR-001 — Rules land in a new H3 inside the existing H2 section

The new rules are authored **inside** the existing
`.claude/agents/cross-layer-orchestrator.md` H2 section "Forbidden
archetypes & combinations", under a new H3 sub-section
`### Event-broker rules (\`event-driven-eu\`)` placed AFTER the J.8.c
`### LLM-provider rules (\`ai-native-rag\`)` H3 and BEFORE the
`### Refusal semantics` H3. No new H2 section is created.

#### FR-B6-JR-002 — `J8-RULE-007` (Confluent Cloud default refusal)

H4 sub-heading `#### J8-RULE-007 — Confluent Cloud refused as event broker
(event-driven-eu)`. Cites : Schrems II / CLOUD Act (US-managed Kafka SaaS) ;
the schema `event_specifics.eu_sovereignty.no_kafka_saas_us: true` flag ;
plan §6.1 B.6.10 ; `compliance-tiers.md` §10.2 `AWS / GCP / Azure` row
(`CLOUD Act force max T1`). Alternative : self-hosted NATS JetStream or
Redpanda on EU infrastructure.

#### FR-B6-JR-003 — `J8-RULE-008` (T3 US-managed Kafka SaaS refusal)

H4 sub-heading `#### J8-RULE-008 — \`--eu-tier T3\` ⇒ NATS JetStream /
Redpanda self-host (US-managed Kafka SaaS refused)`. At T3, any US-managed
Kafka SaaS (Confluent Cloud + AWS MSK + Azure Event Hubs + any
US-jurisdiction managed Kafka) is refused. Cites the schema flag + plan
§6.1 B.6.10 + §10.2 `AWS / GCP / Azure` CLOUD Act row. Mirrors the
`J8-RULE-006` T3-enforcement shape.

#### FR-B6-JR-004 — Rule body shape parity

Each new rule carries the same four sub-bullets as `J8-RULE-004..006` :
**Rationale**, **Reference** (schema flag / plan row / matrix row),
**Alternative** (actionable next step — mandatory per
`janus-orchestration-rules.md`), and the tier applicability
(`J8-RULE-007` = default-refusal any tier ; `J8-RULE-008` = T3 only).

#### FR-B6-JR-005 — Audit anchor

The new H3 sub-section carries `<!-- Audit: B.6.10 (b6-10-janus-rule) -->`
so the B.6.10 deltas are traceable separately from the J.8.a
`<!-- Audit: J.8 -->` and J.8.c `<!-- Audit: B.7.9 + J.8.c -->` anchors.

---

### Cluster 2 — `forbidden_combinations:` seed entries

#### FR-B6-JR-020 — Entries appended to the existing list

`.forge/scaffolding/dispatch-table.yml::forbidden_combinations:` (the list
added by `b7-9-janus-ai`) gains TWO new entries, under a B.6.10 audit
sub-comment. The top-level key is NOT re-created ; the existing 7-key entry
shape (`archetype`/`provider`/`tier`/`reason`/`since`/`alternative`/`rule_id`)
is reused.

#### FR-B6-JR-021 — Seed entries

Two seed entries :
- `archetype: event-driven-eu` / `provider: confluent-cloud` / `tier: any` /
  `rule_id: J8-RULE-007`.
- `archetype: event-driven-eu` / `provider: us-managed-kafka` / `tier: T3` /
  `rule_id: J8-RULE-008`.
`since: "0.6.0"` on each (the event-driven-eu MINOR per the dispatch-table
`archetypes:` registry `since:`).

---

### Cluster 3 — Wrapper invokes the (existing) combination helper

#### FR-B6-JR-040 — Reuse the existing helper

`bin/_forge-init-helpers.sh::_refuse_if_forbidden_combination` (shipped by
`b7-9-janus-ai`, FR-B7-9-040) is REUSED verbatim. This change does NOT add,
modify, or duplicate any helper function.

#### FR-B6-JR-041 — Wrapper sources + invokes the helper

`bin/forge-init-event-driven-eu.sh` (which already sources
`_forge-init-helpers.sh` and calls `_refuse_if_forbidden "event-driven-eu"`)
gains a `_refuse_if_forbidden_combination "event-driven-eu"
"${FORGE_EDE_EVENT_BROKER:-nats-jetstream}"` invocation, guarded by
`declare -f _refuse_if_forbidden_combination`, positioned AFTER the
scaffoldability gate (mirroring `bin/forge-init-ai-native-rag.sh`
FR-B7-9-045). The existing `_refuse_if_forbidden` call and the
exit-3-while-candidate gate are left intact (NFR-B6-JR-001). The scaffold's
sovereign default (`nats-jetstream`) matches no forbidden entry ⇒ no refusal.

---

### Cluster 4 — Standards updates

#### FR-B6-JR-060 — `janus-orchestration-rules.md` catalogue rows

The rule-catalogue table gains two rows for `J8-RULE-007` / `J8-RULE-008`
(Trigger / Refusal target / Reference columns) consistent with the existing
`J8-RULE-001..006` rows.

#### FR-B6-JR-061 — `janus-orchestration-rules.md` prose update

The "Refusal vs warning semantics" section notes `J8-RULE-007` is a
default-provider refusal (fires any tier) and `J8-RULE-008` is a T3-only
refusal — all eight rules (`J8-RULE-001..008`) remain refusals (no
warning-class rule shipped). (No `version:` frontmatter — `.md`-pattern
standard ; content review recorded in `REVIEW.md`.)

#### FR-B6-JR-062 — `compliance-tiers.md::forbidden:` token addition

`global/compliance-tiers.md` frontmatter `forbidden:` (`[vertex-ai,
bedrock]`) gains `confluent-cloud` so the generic I.3 `T3-RULE-005`
review-time linter catches it in working-tree manifests — complementary to
the scaffold-time Janus refusal. SemVer minor bump `1.1.0 → 1.2.0`
(`last_reviewed`/`expires_at` → 2026-07-10 / 2027-07-10) + `REVIEW.md` entry.

#### FR-B6-JR-063 — `constitution-linter.sh` REMEDIATION entry

`constitution-linter.sh::ADR-I3-001` `REMEDIATION` map gains a
`confluent-cloud` entry ("replace with self-hosted NATS JetStream or
Redpanda on EU infrastructure ; no US-managed Kafka SaaS"). No new
`RULE_ID_BY_STANDARD` mapping is needed (the token lives in
`compliance-tiers.md` which already maps to `T3-RULE-005`).

#### FR-B6-JR-064 — `forbidden-components-rules.md` event-broker coupling note

`global/forbidden-components-rules.md` gains an "Event-broker `forbidden:`
coupling (b6-10-janus-rule / B.6.10)" subsection mirroring the existing
"LLM-provider `forbidden:` coupling" one — documents that `confluent-cloud`
is now a `T3-RULE-005` token and that NO new `T3-RULE-NNN` ID is consumed
(the reserved `T3-RULE-008` Persistence slot is untouched). SemVer minor
bump `1.1.0 → 1.2.0` + `REVIEW.md` entry.

---

### Cluster 5 — Test harness + CI

#### FR-B6-JR-080 — Harness exists

`.forge/scripts/tests/b6-10.test.sh` mirrors `b7-9.test.sh` layout
(`--level` parse, `_helpers.sh` source, MANIFEST block, PASS/FAIL counters,
the `_mk_combo_fixture` + `_run_combo_helper` L2 pattern).

#### FR-B6-JR-081 — L1 grep coverage

L1 hermetic grep tests assert : new `J8-RULE-007/008` anchors + the new H3
sub-section + audit anchor in the agent file ; the two seed entries
(`confluent-cloud` + `us-managed-kafka` + `J8-RULE-007/008`) in
`dispatch-table.yml::forbidden_combinations`; the wrapper sources + invokes
`_refuse_if_forbidden_combination` with `event-driven-eu`; the two catalogue
rows in `janus-orchestration-rules.md`; the `confluent-cloud` token in
`compliance-tiers.md::forbidden:` + the `REMEDIATION` map ; the numbering
invariant (007/008 next free, no `J8-RULE-009+`).

#### FR-B6-JR-082 — L2 fixture coverage

Three L2 fixtures exercising the REUSED helper against the live registry :
- **refuse-confluent** : `confluent-cloud` (tier unset or any) ⇒ exit 3 +
  `[REFUSAL:` carrying `J8-RULE-007`.
- **refuse-t3-kafka** : `.forge/.forge-tier`=`T3` + `us-managed-kafka` ⇒
  exit 3 + `[REFUSAL:` carrying `J8-RULE-008`.
- **nats-no-refuse** : `.forge/.forge-tier`=`T3` + `nats-jetstream` ⇒ exit 0,
  no `[REFUSAL:` (sanctioned default). Mirrors
  `b7-9.test.sh::_test_b7_9_l2_t1_no_refuse`.

#### FR-B6-JR-083 — CI registration

`b6-10.test.sh --level 1,2` is appended to the `harnesses=( … )` array in
`.github/workflows/forge-ci.yml`.

---

### Cluster 6 — Sibling-harness coupling + Documentation

#### FR-B6-JR-090 — `b7-9.test.sh` numbering-guard relaxation

`.forge/scripts/tests/b7-9.test.sh::_test_b7_9_005_rule_004_is_next_free`
upper-bound regex is relaxed from `J8-RULE-0(0[7-9]|[1-9][0-9])` to
`J8-RULE-0(09|[1-9][0-9])` so it permits the legitimately-allocated
`J8-RULE-007/008` (b6-10) but still catches a `J8-RULE-009+` collision. A
comment records the b6-10 coupling (mirroring the b7-9 relaxation of
`i2.test.sh` / `i3.test.sh`). The four existing 004/005/006-anchor
assertions are untouched.

#### FR-B6-JR-100 — `docs/ARCHETYPES.md`

The "Forbidden combinations" table gains `J8-RULE-007` / `J8-RULE-008` rows ;
a new "Event-broker refusals (`event-driven-eu`, B.6.10)" note enumerates
the two rules + the NATS JetStream / Redpanda alternative ; the `--eu-tier`
T3 row notes the new T3 event-broker refusal.

#### FR-B6-JR-101 — `CHANGELOG.md`

Entry under `## [Unreleased]` → `### Added` summarising the B.6.10
sub-module (new Janus rules `J8-RULE-007/008` for the `event-driven-eu`
event broker).

---

## Non-Functional Requirements

### NFR-B6-JR-001 — Additive only

No existing `J8-RULE-NNN` renumbered or removed ;
`_refuse_if_forbidden_combination` and `_refuse_if_forbidden` unchanged
(reuse, no edit) ; the `event-driven-eu` schema / templates / scaffolder
backbone untouched. Existing-file edits confined to : the agent file (new H3
sub-section), dispatch-table (two appended entries), the wrapper (source
already present + one guarded call), three standards + the linter token map,
the b7-9 numbering guard, CI matrix, CHANGELOG, ARCHETYPES.md, and the
consolidated-spec append.

### NFR-B6-JR-002 — No regression

`verify.sh` / `constitution-linter.sh` / `validate-standards-yaml.sh` /
`j7` / `j8.test.sh` / `b7-9.test.sh` / `i2.test.sh` / `i3.test.sh` GREEN
after the change (b7-9's numbering guard relaxed per FR-B6-JR-090 so it stays
GREEN). The candidate `event-driven-eu` keeps refusing `forge init` with exit
3 (no behaviour change for a fresh init — the combination check is dormant
until promotion + a real broker config other than the NATS/Redpanda defaults).

### NFR-B6-JR-003 — Rule-ID numbering invariant

`J8-RULE-007..008` allocated sequentially after the live `J8-RULE-006` ; IDs
never reused (ADR-J8-004). A grep asserting 007/008 are the next free block
(no `J8-RULE-009+`) guards against collision.

### NFR-B6-JR-004 — Pattern alignment

The harness mirrors `b7-9.test.sh` verbatim (same helper-reuse L2 pattern).
No new helper function, no new external dependency (the reused helper's bash
+ PyYAML pattern is preserved).

### NFR-B6-JR-005 — Tier-scaled severity coherence

The scaffold-time refusal (Janus, exit 3, blocking : `J8-RULE-007` any-tier
default + `J8-RULE-008` T3) and the review-time linter finding (I.3
`T3-RULE-005`, WARN at T1/T2, FAIL at T3) MUST quote the same
`compliance-tiers.md` §10.2 CLOUD Act gradient + the schema
`no_kafka_saas_us` posture — the two surfaces never contradict.

### NFR-B6-JR-006 — Article V audit trail

Every task tagged `[Story: FR-B6-JR-XXX]` ; refusal stderr lines carry
`J8-RULE-NNN` IDs (ADR-J8-004) ; the B.6.10 spec block is APPENDED to
`.forge/specs/janus-rules.md` at archive (no overwrite of the J.8.a/b/c/d
blocks).

---

## BDD Scenarios (Article II)

```gherkin
Feature: Janus refuses US-managed Kafka SaaS for event-driven-eu (B.6.10)

  Scenario: Confluent Cloud refused as event broker (any tier)
    Given an event-driven-eu scaffold configured with Confluent Cloud as the event broker
    When the forge-init-event-driven-eu.sh wrapper runs the combination check
    Then it exits 3
    And stderr carries "[REFUSAL: event-driven-eu/confluent-cloud@..." with rule_id J8-RULE-007
    And the message names the self-hosted NATS JetStream / Redpanda alternative

  Scenario: T3 refuses any US-managed Kafka SaaS
    Given .forge/.forge-tier declares T3
    And the scaffold points the event broker at a US-managed Kafka SaaS
    When the wrapper runs the combination check
    Then it exits 3 with rule_id J8-RULE-008
    And the message forces self-hosted NATS JetStream or Redpanda on EU infrastructure

  Scenario: Sovereign default NATS JetStream is not refused
    Given .forge/.forge-tier declares T3
    And the scaffold uses the default NATS JetStream event broker
    When the wrapper runs the combination check
    Then no refusal fires
    And the exit code is 0
```

---

## ADRs (b6-10-janus-rule design)

| ID          | Decision                                                                                                                                                                          |
|-------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ADR-B6-JR-001 | Reuse the `J8-RULE-NNN` namespace (ADR-J8-004) — B.6.10 is a J.8 extension, not a new audit module. Allocate the next free block `J8-RULE-007..008` ; never reuse IDs.          |
| ADR-B6-JR-002 | Reuse the `forbidden_combinations:` sibling registry + the `_refuse_if_forbidden_combination` helper shipped by `b7-9-janus-ai` — append entries + a call site only, no new registry or helper. |
| ADR-B6-JR-003 | `J8-RULE-007` (Confluent Cloud, named US SaaS) = `tier: any` (never a valid default, mirrors J8-RULE-004/005) ; `J8-RULE-008` (`us-managed-kafka`, generic category) = `tier: T3` (mirrors J8-RULE-006). Tier-scoping judgment follows the J.8.c convention verbatim. |
| ADR-B6-JR-004 | I.3 coupling reuses generic `T3-RULE-005` via a `confluent-cloud` token — NO new `T3-RULE-NNN` ID (the reserved `T3-RULE-008` Persistence slot is untouched). Only the named any-tier token is added to `forbidden:` (parity with b7-9 adding `vertex-ai`/`bedrock` but not the synthetic `us-managed-inference`). |
| ADR-B6-JR-005 | The rule is a **forward-looking guard**, not an alternate-mode enforcement — grounded in the schema's already-declared `event_specifics.eu_sovereignty.no_kafka_saas_us: true` flag (whose comment names B.6.10 as its enforcement). NATS JetStream is the sovereign default ; Redpanda the sanctioned Kafka-API-compatible alternative ; Confluent Cloud forbidden. |
| ADR-B6-JR-006 | Relax `b7-9.test.sh::_test_b7_9_005` numbering guard to permit 007/008 (sibling-harness coupling) — the same discipline b7-9 applied to `i2`/`i3`. Mandatory to keep main CI green. |

Full design rationale + tier-scoping analysis + Open Questions resolution :
`.forge/changes/b6-10-janus-rule/design.md`.
