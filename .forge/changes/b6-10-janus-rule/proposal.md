# Proposal: b6-10-janus-rule
<!-- Created: 2026-07-10 -->
<!-- Schema: default -->

## Problem

`docs/new-archetypes-plan.md` §6.1 row **B.6.10** mandates a **standard
interdiction** for the `event-driven-eu` archetype :

> **B.6.10.** Standard interdiction : pas de Kafka SaaS US (Confluent
> Cloud), Redpanda acceptable (Cloud Native Computing Foundation, EU
> deployable). Effort : `S`.

The archetype's own 1.0.0 schema already **declares** this posture but
does **not enforce** it :

```yaml
# .forge/schemas/event-driven-eu/1.0.0.yaml
event_specifics:
  eu_sovereignty:
    no_kafka_saas_us: true          # Confluent Cloud forbidden (the enforcement rule list is B.6.10)
    acceptable: [nats-jetstream, redpanda]
```

and the shipped templates forward-point to it in prose
(`infra/CLAUDE.md.tmpl`, `infra/nats/README.md.tmpl` : *"NATS JetStream /
Redpanda only — no Kafka SaaS US (Confluent Cloud). The enforcement rule
list is B.6.10."*). Today the sovereignty rule lives in **schema flag +
prose only** — there is **no scaffold-time refusal** if an adopter
configures a US-managed Kafka SaaS (Confluent Cloud) as the event broker.

This is the **direct sibling** of `b7-9-janus-ai` (J.8.c), which did the
analogous refusal work for `ai-native-rag`'s LLM providers (refuse Vertex
AI / AWS Bedrock as default providers, refuse US-managed inference at T3).
The machinery that brick landed is **reused verbatim** :

1. `b7-9-janus-ai` shipped the sibling `forbidden_combinations:` list in
   `.forge/scaffolding/dispatch-table.yml` (7-key shape :
   `archetype`/`provider`/`tier`/`reason`/`since`/`alternative`/`rule_id`)
   and the additive `_refuse_if_forbidden_combination` helper
   (`bin/_forge-init-helpers.sh`, exit 3, `[REFUSAL:]` stderr). This
   change **appends entries** to that existing list and **reuses** that
   existing helper — nothing new is invented.
2. The live `J8-RULE-NNN` catalogue ends at `J8-RULE-006` (b7-9-janus-ai).
   This change allocates the next free sequential block **`J8-RULE-007`**
   (Confluent Cloud, any-tier default refusal) + **`J8-RULE-008`**
   (`--eu-tier T3` ⇒ any US-managed Kafka SaaS refused).
3. The complementary review-time surface (I.3) is honoured exactly as
   b7-9 did it for `vertex-ai`/`bedrock` : the `confluent-cloud` token is
   added to `global/compliance-tiers.md::forbidden:` (so the generic
   `T3-RULE-005` linter catches it in working-tree manifests) with a
   matching `REMEDIATION` hint in `constitution-linter.sh`.

The gap is a **scaffold-time decision** (Janus orchestration). It closes
by extending the J.8 machinery to the `event-driven-eu` event broker.

## Solution

One coordinated change extending the J.8 Janus refusal machinery to the
`event-driven-eu` archetype's event broker — the **B.6.10** standard
interdiction.

### B.6.10.1 — New Janus rules for `event-driven-eu` event broker

- **`.claude/agents/cross-layer-orchestrator.md`** "Forbidden archetypes
  & combinations" H2 gains a NEW H3 sub-section
  `### Event-broker rules (\`event-driven-eu\`)` (placed AFTER the J.8.c
  `### LLM-provider rules (\`ai-native-rag\`)` H3 and BEFORE the
  `### Refusal semantics` H3) with two new `J8-RULE-NNN` H4s :
  - **`J8-RULE-007`** — Confluent Cloud refused as the event broker for
    `event-driven-eu` (US-managed Kafka SaaS — Schrems II / CLOUD Act),
    fires regardless of declared tier (never a valid default) ;
  - **`J8-RULE-008`** — at `--eu-tier T3`, any US-managed Kafka SaaS
    (Confluent Cloud + AWS MSK + Azure Event Hubs + any US-jurisdiction
    managed Kafka) refused, forcing self-hosted NATS JetStream / Redpanda
    on EU infrastructure.
  Each rule cites its rationale (the schema `no_kafka_saas_us` flag + plan
  §6.1 B.6.10 + `compliance-tiers.md` §10.2 `AWS / GCP / Azure` CLOUD Act
  row) + an actionable alternative, mirroring the `J8-RULE-004..006` shape
  verbatim.
- Audit anchor `<!-- Audit: B.6.10 (b6-10-janus-rule) -->` on the new H3.

### B.6.10.2 — `forbidden_combinations:` seed entries

- **`.forge/scaffolding/dispatch-table.yml`** — TWO new entries appended
  to the EXISTING `forbidden_combinations:` list (added by b7-9-janus-ai),
  under a B.6.10 audit sub-comment :
  - `archetype: event-driven-eu` / `provider: confluent-cloud` /
    `tier: any` / `rule_id: J8-RULE-007` ;
  - `archetype: event-driven-eu` / `provider: us-managed-kafka` /
    `tier: T3` / `rule_id: J8-RULE-008`.
  `since: "0.6.0"` on each (the event-driven-eu MINOR per the
  dispatch-table registry `since:`).

### B.6.10.3 — Wrapper invokes the (existing) combination helper

- **`bin/forge-init-event-driven-eu.sh`** (the gated wrapper shipped by
  B.6.2) already sources `_forge-init-helpers.sh` and calls
  `_refuse_if_forbidden "event-driven-eu"`. This change adds a
  `_refuse_if_forbidden_combination "event-driven-eu"
  "${FORGE_EDE_EVENT_BROKER:-nats-jetstream}"` invocation (positioned
  AFTER the scaffoldability gate, mirroring the ai-native-rag wrapper), so
  the check fires post-promotion for the configured broker. The helper is
  **REUSED** — not duplicated (b7-9 shipped it ; this brick only adds the
  call site). The scaffold's sovereign default (`nats-jetstream`) is never
  refused.

### B.6.10.4 — Standards updates

- **`.forge/standards/global/janus-orchestration-rules.md`** — the
  rule-catalogue table gains the `J8-RULE-007` / `J8-RULE-008` rows ; the
  "Refusal vs warning semantics" section notes the two new refusals
  (007 = default-provider any tier ; 008 = T3-only). (No `version:`
  frontmatter — `.md`-pattern standard ; content review recorded in
  `REVIEW.md`.)
- **`.forge/standards/global/compliance-tiers.md`** — frontmatter
  `forbidden:` (`[vertex-ai, bedrock]`) gains `confluent-cloud` so the
  generic I.3 `T3-RULE-005` review-time linter catches it. SemVer minor
  bump `1.1.0 → 1.2.0` + `REVIEW.md` entry.
- **`.forge/scripts/constitution-linter.sh`** — the `REMEDIATION` map
  gains a `confluent-cloud` entry (pointing at NATS JetStream / Redpanda
  self-host EU).
- **`.forge/standards/global/forbidden-components-rules.md`** — a new
  "Event-broker `forbidden:` coupling (b6-10-janus-rule / B.6.10)"
  subsection mirroring the existing "LLM-provider `forbidden:` coupling"
  one ; documents that `confluent-cloud` is now a `T3-RULE-005` token
  (NO new `T3-RULE-NNN` ID consumed — the reserved `T3-RULE-008` slot for
  Persistence `forbidden_for_eu_strict:` is untouched). SemVer minor bump
  `1.1.0 → 1.2.0` + `REVIEW.md` entry.

### B.6.10.5 — Test harness

- New **`.forge/scripts/tests/b6-10.test.sh`** (grep-based, mirroring
  `b7-9.test.sh`) :
  - **L1 (hermetic grep)** : new `J8-RULE-007/008` anchors + H3
    sub-section + audit anchor in the agent file ; the two seed entries in
    `dispatch-table.yml::forbidden_combinations`; the wrapper sources +
    invokes `_refuse_if_forbidden_combination`; the two catalogue rows in
    `janus-orchestration-rules.md`; the `confluent-cloud` token in
    `compliance-tiers.md::forbidden:` + `REMEDIATION` map ; the numbering
    invariant (007/008 next free, no 009+).
  - **L2 (fixture)** : a synthetic forge-root tree exercising the reused
    helper against the live registry — Confluent-Cloud-at-any-tier ⇒ exit
    3 + `J8-RULE-007` ; `us-managed-kafka`-at-T3 ⇒ exit 3 + `J8-RULE-008` ;
    `nats-jetstream`-at-T3 ⇒ exit 0 (sanctioned default, no refusal).
- Registered in `.github/workflows/forge-ci.yml` `harnesses=( … )` array
  as `"b6-10.test.sh --level 1,2"`.

### B.6.10.6 — Sibling-harness coupling (regression fix)

- **`.forge/scripts/tests/b7-9.test.sh`** — `_test_b7_9_005_rule_004_is_next_free`
  currently asserts NO `J8-RULE-007+` exists (it was the numbering-invariant
  guard when 006 was the last rule). Adding `J8-RULE-007/008` legitimately
  invalidates that upper bound. The guard's regex is relaxed to permit
  007/008 but still catch a `J8-RULE-009+` collision — the exact
  sibling-harness coupling discipline b7-9 itself applied when it relaxed
  `i2.test.sh` / `i3.test.sh` (open-questions.md Q-003 "Option B"). Without
  this fix, main CI goes red the moment B.6.10 merges.

## Scope In

- New `J8-RULE-007` / `J8-RULE-008` H4s in a new
  `### Event-broker rules (\`event-driven-eu\`)` H3 of
  `.claude/agents/cross-layer-orchestrator.md`.
- Two new entries in the EXISTING
  `.forge/scaffolding/dispatch-table.yml::forbidden_combinations:` list.
- `bin/forge-init-event-driven-eu.sh` invokes the EXISTING
  `_refuse_if_forbidden_combination` helper (reuse, no new helper).
- `.forge/standards/global/janus-orchestration-rules.md` catalogue + prose.
- `.forge/standards/global/compliance-tiers.md::forbidden:` `confluent-cloud`
  token + SemVer bump ; `constitution-linter.sh` `REMEDIATION` entry ;
  `forbidden-components-rules.md` event-broker coupling subsection + bump.
- New harness `.forge/scripts/tests/b6-10.test.sh` + `forge-ci.yml`
  registration.
- Regression fix to `.forge/scripts/tests/b7-9.test.sh` numbering guard.
- Doc updates : `docs/ARCHETYPES.md` (event-broker refusal note) +
  `CHANGELOG.md`.
- Consolidated-spec append : the B.6.10 block APPENDED to
  `.forge/specs/janus-rules.md` at archive time.

## Scope Out (Explicit Exclusions)

- **NOT** the `event-driven` / `asyncapi-contracts` / `nats-jetstream`
  standards (B.6.3 — sibling lane). This brick only adds the refusal rule +
  the wrapper hook, not the broader event-driven standards.
- **NOT** the Hermes-Async agent (B.6.4 — sibling lane).
- **NOT** any change to the `event-driven-eu` schema, templates, or the
  B.6.2 scaffolder backbone — the schema already declares
  `no_kafka_saas_us: true` ; this brick ENFORCES it, it does not restate it.
- **NOT** promotion of `event-driven-eu` to `stable` / `scaffoldable:
  true` — that is gated on B.6.7. The wrapper stays gated (exit 3 while
  candidate) ; the combination check is additive defense-in-depth for when
  it promotes.
- **NOT** a new `T3-RULE-NNN` ID — the reserved `T3-RULE-008` slot
  (Persistence `forbidden_for_eu_strict:`) is untouched ; `confluent-cloud`
  reuses the generic `T3-RULE-005` matrix-row enforcement (verbatim b7-9
  precedent).
- **NOT** runtime detection of the broker from a deployed cluster — Janus
  refuses what the adopter *declares*, not what the cluster *is*.
- **NOT** a new compliance tier or any `[T1, T2, T3]` enum change.

## Impact

- **Users affected** :
  - Adopters configuring `event-driven-eu` with a Confluent Cloud broker
    get a clear Schrems II / CLOUD Act refusal pointing to NATS JetStream /
    Redpanda self-host, instead of a silently-accepted US-managed Kafka SaaS.
  - Adopters at `--eu-tier T3` get a hard refusal on any US-managed Kafka
    SaaS at scaffold time + a complementary review-time linter finding
    (`T3-RULE-005`) on working-tree manifests pinning `confluent-cloud`.
  - Adopters using the sovereign default (NATS JetStream) or the sanctioned
    Redpanda alternative see no behaviour change.
- **Technical impact** : 6 new files (harness + 5 change-dir spec files) +
  ≈ 9 modified (agent file, dispatch-table, wrapper, three standards, the
  linter, the b7-9 harness guard, CI matrix, CHANGELOG, ARCHETYPES.md, the
  consolidated spec at archive). All additive ; no existing rule renumbered
  or removed (ADR-J8-004 numbering invariant). **Effort `S`** (plan §6.1
  B.6.10 = `S`).
- **Dependencies** :
  - `j8-janus-rules` ✅ archived — `J8-RULE-NNN` namespace, exit-3 /
    `[REFUSAL:]` convention.
  - `b7-9-janus-ai` ✅ archived — the `forbidden_combinations:` list, the
    `_refuse_if_forbidden_combination` helper, the I.3 token-coupling
    pattern, and the numbering-guard-relaxation precedent this brick reuses.
  - `i2-compliance-tiers` / `i3-t3-forbidden-linter` ✅ archived — §10.2
    matrix + generic `forbidden:` token enforcement + `REMEDIATION` map.
  - `b6-1-schema` / `b6-2-scaffolder` ✅ archived — the `event-driven-eu`
    schema (`no_kafka_saas_us` flag) + the `bin/forge-init-event-driven-eu.sh`
    wrapper this brick hooks the combination check into.
  - Independent of sibling B.6 lanes (B.6.3 / B.6.4 / B.6.5 / B.6.6 /
    B.6.9) except for the flagged shared-file merge conflicts
    (`CHANGELOG.md`, `forge-ci.yml`, `dispatch-table.yml`,
    `cross-layer-orchestrator.md`) handled centrally at merge.
  - No new external dependency ; reuses the bash + PyYAML helper pattern.
- **Risk level** : **Low**. All deltas additive ; the existing helper +
  `_refuse_if_forbidden` contracts are preserved (call-site added, not a
  modification) ; the wrapper is already gated (exit 3 while candidate) so
  the combination check has no behaviour-changing effect on a fresh `forge
  init` today. The one behaviour-affecting edit outside additions is the
  b7-9 numbering-guard relaxation, which is mandatory to keep main CI green.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. The `b6-10.test.sh` harness is written
with real assertions FIRST and run against the absent implementation to
witness RED, then each cluster is implemented to GREEN.

### Article II — BDD

User-facing CLI behaviours (the new scaffold-time refusals) get Gherkin
scenarios in `specs.md` :
- `Given an event-driven-eu scaffold configured with Confluent Cloud as the event broker, When the wrapper runs the combination check, Then it exits 3 with the CLOUD Act rationale and the NATS/Redpanda alternative.`
- `Given --eu-tier T3 + a US-managed Kafka SaaS, When the wrapper runs, Then it exits 3 forcing self-hosted NATS JetStream / Redpanda.`
- `Given the sovereign default NATS JetStream, When the wrapper runs, Then no refusal fires.`

### Article III — Specs Before Code

`/forge:specify` writes the `FR-B6-JR-*` namespace into `specs.md` before
any implementation ; the B.6.10 block is APPENDED to
`.forge/specs/janus-rules.md` at archive time.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

The sanctioned alternatives (NATS JetStream, Redpanda) are **verified**
against the schema's `event_specifics.eu_sovereignty.acceptable:
[nats-jetstream, redpanda]` and the plan §6.1 B.6.10 text — no fabrication.
The "alternate Kafka mode vs forward-looking guard" ambiguity is resolved
by the schema flag `no_kafka_saas_us: true` (whose comment explicitly names
B.6.10 as its enforcement) : this is a forward-looking guard, documented in
design.md. No open `[NEEDS CLARIFICATION]` remains.

### Article V — Constitutional Compliance Gate

Each task tagged `[Story: FR-B6-JR-XXX]`. Refusal stderr lines carry the
new `J8-RULE-NNN` IDs (ADR-J8-004 namespace), machine-parseable.

### Article XII — Governance

The new Janus rules ENFORCE the Schrems II / CLOUD Act positioning already
encoded in the archetype schema + `compliance-tiers.md` §10.2 +
`docs/ARCHITECTURE-TARGET.md`. They do **not amend** any constitutional
article. The `forbidden_combinations:` additions + new rule IDs proceed via
the normal change pipeline per `janus-orchestration-rules.md` "Extending
the catalogue" (additions are not amendments). Adding `confluent-cloud` to
`compliance-tiers.md::forbidden:` is a SemVer minor bump with a `REVIEW.md`
entry.

## Open Questions

No inline `[NEEDS CLARIFICATION:]` markers remain. Open questions
Q-001..Q-003 raised at this phase, all tracked in `open-questions.md` and
resolved during `/forge:design`.
