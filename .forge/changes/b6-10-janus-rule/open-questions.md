# Open Questions — b6-10-janus-rule

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: Rule-ID allocation + registry/helper placement

- **Status**: answered
- **Raised in**: proposal.md ; specs.md "Rule-ID allocation"
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

B.6.10 must allocate NEW `J8-RULE-NNN` IDs (ADR-J8-004 — never reuse). How
many rules, which IDs, and do the refusals get a new registry/helper or reuse
the `b7-9-janus-ai` `forbidden_combinations:` + `_refuse_if_forbidden_combination`
machinery?

### Resolution

- **Resolved on**: 2026-07-10 (via `design.md` ADR-B6-JR-001/002)
- **Decision**: **two rules**, IDs **`J8-RULE-007`** (Confluent Cloud) +
  **`J8-RULE-008`** (T3 US-managed Kafka SaaS) — the next free sequential
  block (verified : the live catalogue ends at `J8-RULE-006`). **REUSE** the
  b7-9 `forbidden_combinations:` list (append two entries) and the existing
  generic `_refuse_if_forbidden_combination` helper (add a call site in the
  event-driven-eu wrapper) — NO new registry, NO new/duplicated helper (the
  task explicitly requires reuse ; the helper is keyed on archetype+provider,
  not hard-coded to ai-native-rag).

---

## Q-002: Tier-scoping — any-tier or T3-only?

- **Status**: answered
- **Raised in**: proposal.md B.6.10.1 ; specs.md FR-B6-JR-002/003
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

The task asks whether the event-broker refusal fires at any tier or at T3
specifically, per how J.8's tier-scoping convention works (J8-RULE-004..006).

### Resolution

- **Resolved on**: 2026-07-10 (via `design.md` ADR-B6-JR-003)
- **Decision**: mirror the J.8.c convention verbatim. **Named US-managed
  providers** are `tier: any` (never a valid default) — so **Confluent Cloud**
  (the plan's explicitly-named example, a pure-play US Kafka SaaS) →
  `J8-RULE-007` `tier: any`. **Generic US-managed category** is `tier: T3`
  (strictest tier catch-all) — so **`us-managed-kafka`** (covering AWS MSK,
  Azure Event Hubs, any US-jurisdiction managed Kafka) → `J8-RULE-008`
  `tier: T3`. This matches J8-RULE-004/005 (named, any-tier) + J8-RULE-006
  (generic `us-managed-inference`, T3), honours "don't over-invent a long
  list", and the plan names only Confluent Cloud explicitly.

---

## Q-003: I.3 coupling — new T3-RULE or reuse T3-RULE-005? + alternate-mode vs guard?

- **Status**: answered
- **Raised in**: proposal.md B.6.10.4 ; specs.md FR-B6-JR-062..064 ;
  task scope items 2 + 4
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

(a) The task scope item 4 says "extend the `T3-RULE-*` catalogue (new rule
number)". But `b7-9-janus-ai` (the mirror) did NOT mint a new T3-RULE — it
added tokens to `compliance-tiers.md::forbidden:` so the generic `T3-RULE-005`
catches them. Which approach?

(b) Task scope item 2 asks whether B.6.10 is about an ALTERNATE
Kafka-compatible mode adopters configure, or a forward-looking guard — with a
`[NEEDS CLARIFICATION]` allowed if genuinely ambiguous.

### Resolution

- **Resolved on**: 2026-07-10 (via `design.md` ADR-B6-JR-004/005)
- **Decision (a)**: **reuse the generic `T3-RULE-005`** via a `confluent-cloud`
  token in `compliance-tiers.md::forbidden:` — do NOT mint a new `T3-RULE-NNN`.
  Rationale : `forbidden-components-rules.md` **reserves `T3-RULE-008` for
  Persistence `forbidden_for_eu_strict:`** — minting a new T3-RULE here would
  collide with a reserved slot or fragment the catalogue. Reusing `T3-RULE-005`
  is the exact `b7-9-janus-ai` precedent (which added `vertex-ai`/`bedrock`
  tokens, consuming NO new linter-rule ID). The task's "new rule number"
  phrasing is honoured in substance : enforcement extends via the established
  generic matrix-row rule. Only the named any-tier token (`confluent-cloud`)
  is added to `forbidden:` (the synthetic `us-managed-kafka` category token is
  not — parity with b7-9 not adding `us-managed-inference`).
- **Decision (b)**: **forward-looking guard**, NOT alternate-mode enforcement —
  and NOT ambiguous, so **no `[NEEDS CLARIFICATION]`**. The event-driven-eu
  schema authoritatively declares
  `event_specifics.eu_sovereignty.no_kafka_saas_us: true` (comment: "the
  enforcement rule list is B.6.10") + `acceptable: [nats-jetstream, redpanda]`.
  The archetype defaults to NATS JetStream (never refused) ; Redpanda is the
  sanctioned Kafka-API-compatible alternative ; the rule guards against a
  future/configured Kafka-SaaS choice landing on a US-managed provider. All
  claims trace to the schema flag, plan §6.1 B.6.10, and §10.2 — no
  fabrication (Article III.4).

---

## Verified (no clarification needed)

- **NATS JetStream + Redpanda** are the sanctioned EU-deployable event brokers
  — confirmed verbatim against `.forge/schemas/event-driven-eu/1.0.0.yaml`
  `event_specifics.eu_sovereignty.acceptable: [nats-jetstream, redpanda]` and
  the shipped templates (`infra/CLAUDE.md.tmpl`, `infra/nats/README.md.tmpl`).
  No broker specifics fabricated (Article III.4).
- **Confluent Cloud** is the plan §6.1 B.6.10 explicitly-named forbidden US
  Kafka SaaS ; the schema comment names B.6.10 as its enforcement rule list.
- **`forbidden_combinations:` list + `_refuse_if_forbidden_combination`
  helper** exist (`b7-9-janus-ai`, archived) and are generic (keyed on
  archetype+provider). The `bin/forge-init-event-driven-eu.sh` wrapper (B.6.2,
  already sources `_forge-init-helpers.sh`) is the hook point.
- **Exit code 3 + `[REFUSAL:]` stderr format** — inherited verbatim from J.8
  (ADR-J8-003 / FR-J8-021). No new convention invented.
- **`b7-9.test.sh` numbering guard** hard-pins 006 as the last J8-RULE ;
  allocating 007/008 requires relaxing its upper bound (ADR-B6-JR-006 —
  sibling-harness coupling, same discipline b7-9 applied to i2/i3).
