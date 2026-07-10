# Design: b6-10-janus-rule

<!-- Audit: B.6.10 (b6-10-janus-rule) -->

B.6.10 — Janus refusal rules for the `event-driven-eu` archetype's event
broker. Refuse Confluent Cloud (US-managed Kafka SaaS) as the event broker
regardless of tier ; at `--eu-tier T3` refuse any US-managed Kafka SaaS.
Sanctioned default = self-hosted NATS JetStream / Redpanda (EU-deployable).
The **direct sibling** of J.8.c (`b7-9-janus-ai`) — same
`forbidden_combinations:` registry, same `_refuse_if_forbidden_combination`
helper (REUSED, not re-created), same exit-3 / `[REFUSAL:]` convention, same
I.3 review-time token coupling.

This design covers the three resolved Open Questions (Q-001..Q-003), the
component design, the data flows, the testing strategy, and the
**sibling-harness coupling** with the archived `b7-9-janus-ai` numbering guard.

---

## Architecture Decisions

### ADR-B6-JR-001 — Rule-ID namespace : reuse `J8-RULE-NNN` (resolves Q-001)

B.6.10 is an **extension of J.8**, not a new audit module. ADR-J8-004 fixed
the `<MODULE>-RULE-NNN` format ; the event-broker refusals are the same
policy family (EU-sovereign scaffold-time refusals) as J.8.a
(`J8-RULE-001..003`) and J.8.c (`J8-RULE-004..006`), so they stay in the
`J8-RULE-NNN` namespace rather than minting a `B610-RULE-NNN` prefix.

The live catalogue ends at `J8-RULE-006` (verified : grep of `.claude/`,
`.forge/standards/`, `.forge/scaffolding/` returns exactly
`J8-RULE-001..006`). This change allocates the next free sequential block :

- `J8-RULE-007` — Confluent Cloud refused as event broker (any tier).
- `J8-RULE-008` — `--eu-tier T3` ⇒ US-managed Kafka SaaS refused.

IDs are NEVER reused (ADR-J8-004 numbering invariant). The b6-10 harness
grep (NFR-B6-JR-003) asserts 007/008 are allocated with no `J8-RULE-009+`.

**Q-001 RESOLVED** : two rules, IDs `J8-RULE-007/008`.

### ADR-B6-JR-002 — Registry + helper : reuse the b7-9 machinery (resolves Q-001 placement)

`b7-9-janus-ai` already landed the `forbidden_combinations:` sibling list
(7-key shape) AND the `_refuse_if_forbidden_combination "<archetype>"
"<provider>"` helper (`bin/_forge-init-helpers.sh`, exit 3, `[REFUSAL:]`).
Those are **generic** — keyed on `archetype` + `provider`, not hard-coded to
`ai-native-rag`. B.6.10 therefore :

- **APPENDS** two entries to the existing `forbidden_combinations:` list
  (under a B.6.10 audit sub-comment) — it does NOT create a new list.
- **REUSES** `_refuse_if_forbidden_combination` verbatim — it does NOT add,
  modify, or duplicate any helper (NFR-B6-JR-001 ; the task explicitly
  requires reuse).

Entry shape (identical 7 keys) :
```yaml
  # ── B.6.10 (b6-10-janus-rule) — event-driven-eu Kafka-SaaS refusals ──
  - archetype: event-driven-eu
    provider: confluent-cloud
    tier: any            # fires regardless of declared tier (never a valid default)
    reason: "Confluent Cloud = US-managed Kafka SaaS ; Schrems II / CLOUD Act incompatible with the event-driven-eu EU-sovereign posture (schema event_specifics.eu_sovereignty.no_kafka_saas_us)"
    since: "0.6.0"
    alternative: "self-hosted NATS JetStream (the archetype default) or Redpanda (Kafka-API-compatible, self-hostable, EU-deployable) on EU infrastructure"
    rule_id: J8-RULE-007
  - archetype: event-driven-eu
    provider: us-managed-kafka
    tier: T3
    reason: "T3 (SecNumCloud / EUCS High) requires 100% EU jurisdiction ; any US-managed Kafka SaaS (Confluent Cloud / AWS MSK / Azure Event Hubs) is CLOUD Act exposure"
    since: "0.6.0"
    alternative: "self-hosted NATS JetStream or Redpanda on EU infrastructure (SecNumCloud / OVHcloud / Scaleway)"
    rule_id: J8-RULE-008
```
The `provider:` token `confluent-cloud` is the canonical refusal key ; it
doubles as the I.3 `compliance-tiers.md::forbidden:` token (FR-B6-JR-062).
`us-managed-kafka` is a synthetic category token (like J.8.c's
`us-managed-inference`) — it is NOT added to `forbidden:` (a synthetic
category never appears verbatim in a manifest ; parity with b7-9 which added
`vertex-ai`/`bedrock` but not `us-managed-inference`).

**Q-001 placement RESOLVED** : reuse, do not re-create.

### ADR-B6-JR-003 — Tier-scoping : follow the J.8.c convention (resolves Q-002)

The task asks whether the refusal is any-tier or T3-only, and to follow the
J.8's tier-scoping convention. J.8.c's convention, read verbatim :

- **Named US-managed providers** (`vertex-ai` J8-RULE-004, `bedrock`
  J8-RULE-005) → `tier: any` — they are **never a valid default** at ANY
  tier, so the refusal is unconditional.
- **Generic US-managed category** (`us-managed-inference` J8-RULE-006) →
  `tier: T3` — the catch-all is scoped to the strictest tier where 100% EU
  jurisdiction is mandatory.

B.6.10 mirrors this exactly :

- **`J8-RULE-007` — Confluent Cloud** (the plan's explicitly-named example,
  a pure-play US Kafka SaaS) → `tier: any`. Confluent Cloud is never a valid
  default event broker for an EU-sovereign archetype ; the schema flag
  `no_kafka_saas_us: true` is unconditional (not tier-scaled).
- **`J8-RULE-008` — `us-managed-kafka`** (the generic "by extension"
  catch-all covering AWS MSK, Azure Event Hubs, and any other US-jurisdiction
  managed Kafka) → `tier: T3`. This honours the task's "don't over-invent a
  long list" — instead of naming every hyperscaler Kafka product, one
  category token scoped to T3 covers them, exactly as J8-RULE-006 covered
  "Vertex / Bedrock / OpenAI-direct / Anthropic-direct" under one
  `us-managed-inference` T3 token.

Two rules is the right scope (not one, not five) : it is symmetric with
J.8.c's "two named any-tier + one generic T3" and the plan names only
Confluent Cloud explicitly.

**Q-002 RESOLVED** : Confluent Cloud = any-tier ; generic US-managed Kafka =
T3.

### ADR-B6-JR-004 — I.3 coupling reuses `T3-RULE-005` (resolves Q-003)

The review-time surface exists on two enforcement surfaces, deliberately,
identical to ADR-B7-9-005 :

1. **Scaffold-time (Janus, this brick's core)** — `J8-RULE-007/008`, exit 3,
   blocking, fired by `_refuse_if_forbidden_combination` from the wrapper.
   Refuses the *declared* broker before scaffolding.
2. **Review-time (I.3 linter)** — the **generic `T3-RULE-005`** (matrix-row
   `forbidden:` token enforcement), tier-scaled WARN at T1/T2, FAIL at T3,
   fired by `constitution-linter.sh` against working-tree manifests. Catches
   a `confluent-cloud` token that slipped past the scaffold-time gate (an
   adopter who hand-edited the broker config post-scaffold).

**No new `T3-RULE-NNN` ID is minted.** This is a deliberate collision-avoidance
decision : `forbidden-components-rules.md` (line ~171) **reserves
`T3-RULE-008` for Persistence `forbidden_for_eu_strict:` enforcement**.
Minting a new T3-RULE for the event broker would either collide with that
reserved slot or fragment the catalogue. Instead — verbatim the b7-9
precedent — `confluent-cloud` is added to `compliance-tiers.md::forbidden:`
so the EXISTING generic `T3-RULE-005` (which enforces every `forbidden:`
token in that standard) catches it. No linter-rule ID is consumed. The task's
"new rule number" phrasing is honoured in substance : the enforcement extends
via the generic matrix-row rule that b7-9 already established as the pattern
for provider tokens.

Both surfaces quote the SAME `compliance-tiers.md` §10.2 CLOUD Act gradient
+ the schema `no_kafka_saas_us` posture (NFR-B6-JR-005) — they never
contradict. This mirrors how `J8-RULE-004/005` + `vertex-ai`/`bedrock`
already co-exist.

**Q-003 RESOLVED** : reuse `T3-RULE-005` via `confluent-cloud` token ; do NOT
mint a new T3-RULE (reserved-slot collision).

### ADR-B6-JR-005 — Forward-looking guard, grounded in the schema (Article III.4)

Is B.6.10 about an ALTERNATE Kafka-compatible mode some adopters configure,
or a forward-looking guard? The schema resolves the ambiguity authoritatively :

```yaml
# .forge/schemas/event-driven-eu/1.0.0.yaml
event_specifics:
  eu_sovereignty:
    no_kafka_saas_us: true          # Confluent Cloud forbidden (the enforcement rule list is B.6.10)
    acceptable: [nats-jetstream, redpanda]
```

The archetype's **primary/default** broker is **NATS JetStream** (the B.6.2
scaffolder wires `async-nats` / JetStream — verified in
`backend/Cargo.toml.tmpl`, `bin-server/src/main.rs.tmpl`,
`infra/nats/jetstream.conf.tmpl`). **Redpanda** is listed as an
`acceptable:` Kafka-API-compatible alternative (self-hostable,
EU-deployable — plan §6.1 B.6.10 frames it as CNCF-adjacent). **Confluent
Cloud** (US-managed Kafka SaaS) is `no_kafka_saas_us: true` forbidden, and
that comment **explicitly names B.6.10 as its enforcement rule list**.

Therefore B.6.10 is a **forward-looking guard** : the archetype does not
today expose a Kafka-SaaS configuration knob (it defaults to NATS JetStream,
which is never refused), but the rule guards the case where a future
Kafka-compatible option is configured (via `FORGE_EDE_EVENT_BROKER` or a
post-promotion broker field) so an adopter cannot pick a US-managed Kafka
SaaS. The sanctioned choices are exactly the schema `acceptable:` list. No
provider specifics are fabricated (Article III.4) — every claim traces to the
schema flag, the plan text, or the §10.2 matrix. **No `[NEEDS CLARIFICATION]`
remains.**

**Q-003b RESOLVED** : forward-looking guard grounded in the schema flag.

### ADR-B6-JR-006 — Sibling-harness coupling : relax the b7-9 numbering guard

`b7-9.test.sh::_test_b7_9_005_rule_004_is_next_free` (an ARCHIVED brick's
harness) asserts, as its numbering-invariant guard, that NO `J8-RULE-007+`
exists :

```bash
if grep -qrhoE "J8-RULE-0(0[7-9]|[1-9][0-9])" "$JANUS_AGENT" "$DISPATCH_TABLE"; then
  echo "    a J8-RULE-007+ ID exists — 004..006 are NOT the next free block (collision)" >&2; return 1
fi
```

That guard was correct **when 006 was the last rule**. Allocating
`J8-RULE-007/008` legitimately (the next free block) invalidates the upper
bound — the guard would fire a FALSE collision and turn main CI red the
moment B.6.10 merges. The fix (FR-B6-JR-090) relaxes the regex to
`J8-RULE-0(09|[1-9][0-9])` : it still asserts 004/005/006 exist and still
catches a `J8-RULE-009+` collision, but permits the b6-10-owned 007/008. A
comment records the b6-10 coupling.

This is the identical discipline `b7-9-janus-ai` applied when its additive
edits invalidated over-strict sibling gates (`i2.test.sh::_test_i2_005`,
`i3.test.sh::_test_i3_008` relaxed to frontmatter-validity checks —
open-questions.md Q-003 "Option B"). It is also the documented project lesson
"a shared surface bump must update every sibling harness that hard-pins it,
else CI rots silently on main". Editing an archived brick's harness is
justified because B.6.10 is the change that allocates 007/008.

**Q-003c RESOLVED** : relax, with a coupling comment.

---

## Component Design

```
                 forge init --archetype event-driven-eu [--eu-tier T3]
                                       │
                                       ▼
          ┌────────────────────────────────────────────────────────┐
          │ cli/src/commands/init-archetype.ts (TS dispatcher)       │
          │  versioned-schema gate — candidate/scaffoldable:false    │
          │  ⇒ exit 3 (B.6.1/B.6.2) WHILE CANDIDATE                  │
          └────────────────────────────────────────────────────────┘
                                       │ (post-promotion : reaches wrapper)
                                       ▼
          ┌────────────────────────────────────────────────────────┐
          │ bin/forge-init-event-driven-eu.sh (gated wrapper, B.6.2) │
          │  source bin/_forge-init-helpers.sh                       │
          │  _refuse_if_forbidden            "event-driven-eu" (J.8.a)│
          │  [scaffoldability gate — exit 3 while candidate]         │
          │  _refuse_if_forbidden_combination "event-driven-eu" \    │
          │                   "$FORGE_EDE_EVENT_BROKER" (B.6.10)      │ ◀── NEW call site (reused helper)
          └────────────────────────────────────────────────────────┘
                                       │
                                       ▼
          ┌────────────────────────────────────────────────────────┐
          │ _refuse_if_forbidden_combination (EXISTING, b7-9 —       │
          │  _forge-init-helpers.sh — REUSED verbatim)               │
          │  • resolve tier : $FORGE_EU_TIER → .forge/.forge-tier → ∅│
          │  • PyYAML parse dispatch-table.yml::forbidden_combinations│
          │  • match archetype+provider+(tier==any|tier==resolved)   │
          │  • on match → stderr [REFUSAL: …] + exit 3 (ADR-J8-003)  │
          │  • else / unreachable table → return 0 (fail-open)       │
          └────────────────────────────────────────────────────────┘

   Registry        .forge/scaffolding/dispatch-table.yml
                     forbidden_combinations: (b7-9 — 3 entries, unchanged)
                       + B.6.10 — 2 seed entries (confluent-cloud/any, us-managed-kafka/T3) ◀── NEW

   Narrative       .claude/agents/cross-layer-orchestrator.md
                     ## Forbidden archetypes & combinations
                       ### LLM-provider rules (ai-native-rag)  (J.8.c, unchanged)
                       ### Event-broker rules (event-driven-eu)  ◀── NEW H3
                         #### J8-RULE-007 / 008

   Standard        .forge/standards/global/janus-orchestration-rules.md
                     rule-catalogue table += 2 rows ; "Refusal semantics" prose updated ◀── EDIT

   Review-time     .forge/standards/global/compliance-tiers.md::forbidden: += confluent-cloud ◀── EDIT (1.1.0→1.2.0)
   (I.3 coupling)  .forge/scripts/constitution-linter.sh::REMEDIATION += confluent-cloud entry ◀── EDIT
                     ⇒ generic T3-RULE-005 catches the token in working-tree manifests

   Regression      .forge/scripts/tests/b7-9.test.sh::_test_b7_9_005 upper bound relaxed 006→008 ◀── EDIT
```

---

## Data Flow — `event-driven-eu` + Confluent Cloud broker (any tier)

```mermaid
sequenceDiagram
    participant U as Adopter
    participant W as forge-init-event-driven-eu.sh
    participant H as _refuse_if_forbidden_combination (reused)
    participant T as dispatch-table.yml
    U->>W: scaffold event-driven-eu, FORGE_EDE_EVENT_BROKER=confluent-cloud
    W->>H: _refuse_if_forbidden_combination("event-driven-eu","confluent-cloud")
    H->>H: resolve tier (FORGE_EU_TIER / .forge-tier / ∅)
    H->>T: parse forbidden_combinations
    T-->>H: {event-driven-eu, confluent-cloud, tier:any, J8-RULE-007}
    H->>H: archetype✓ provider✓ tier:any✓ ⇒ MATCH
    H-->>U: stderr [REFUSAL: event-driven-eu/confluent-cloud@<tier>: J8-RULE-007: … ; alternative: NATS JetStream / Redpanda self-host]
    H->>W: exit 3
    Note over W: no scaffold side-effect
```

## Data Flow — `--eu-tier T3` + US-managed Kafka SaaS

```mermaid
sequenceDiagram
    participant U as Adopter
    participant W as forge-init-event-driven-eu.sh
    participant H as _refuse_if_forbidden_combination (reused)
    participant T as dispatch-table.yml
    U->>W: --eu-tier T3 ; FORGE_EDE_EVENT_BROKER=us-managed-kafka
    W->>H: _refuse_if_forbidden_combination("event-driven-eu","us-managed-kafka")
    H->>H: tier = T3 (from FORGE_EU_TIER / ledger)
    H->>T: parse forbidden_combinations
    T-->>H: {event-driven-eu, us-managed-kafka, tier:T3, J8-RULE-008}
    H->>H: archetype✓ provider✓ tier T3 == T3 ✓ ⇒ MATCH
    H-->>U: stderr [REFUSAL: …@T3: J8-RULE-008: … ; alternative: NATS JetStream / Redpanda self-host EU]
    H->>W: exit 3
```

## Data Flow — NATS JetStream default (NOT refused)

```mermaid
sequenceDiagram
    participant U as Adopter
    participant W as forge-init-event-driven-eu.sh
    participant H as _refuse_if_forbidden_combination (reused)
    participant T as dispatch-table.yml
    U->>W: --eu-tier T3 ; broker defaults to nats-jetstream
    W->>H: _refuse_if_forbidden_combination("event-driven-eu","nats-jetstream")
    H->>H: tier = T3
    H->>T: parse forbidden_combinations
    T-->>H: no entry matches provider=nats-jetstream
    H->>W: return 0 (no refusal — sovereign default)
    Note over W: scaffold proceeds
```

---

## Testing Strategy

`.forge/scripts/tests/b6-10.test.sh` mirrors `b7-9.test.sh` (`--level`
parse, `_helpers.sh` source, MANIFEST block, PASS/FAIL counters, the
`_mk_combo_fixture` + `_run_combo_helper` L2 pattern reused verbatim, `--level
1,2` registration in `forge-ci.yml`).

### L1 — grep-level (hermetic, 9 tests, FR-B6-JR-081)

| Test | Asserts | FR |
|------|---------|----|
| `_test_b6_10_001_agent_h3_section` | new H3 "Event-broker rules" + `<!-- Audit: B.6.10 (b6-10-janus-rule) -->` in the agent file | FR-B6-JR-001/005 |
| `_test_b6_10_002_rule_007` | `J8-RULE-007` anchor in agent file | FR-B6-JR-002 |
| `_test_b6_10_003_rule_008` | `J8-RULE-008` anchor in agent file | FR-B6-JR-003 |
| `_test_b6_10_004_rule_007_is_next_free` | 007/008 allocated, no `J8-RULE-009+` collision | NFR-B6-JR-003 |
| `_test_b6_10_020_combinations_entries` | `confluent-cloud` + `us-managed-kafka` + `event-driven-eu` in the `forbidden_combinations:` block | FR-B6-JR-020/021 |
| `_test_b6_10_021_seed_rule_ids` | `rule_id: J8-RULE-007` + `rule_id: J8-RULE-008` in the block | FR-B6-JR-021 |
| `_test_b6_10_041_wrapper_invokes` | wrapper sources helper + calls `_refuse_if_forbidden_combination "event-driven-eu"` | FR-B6-JR-041 |
| `_test_b6_10_060_std_rows` | two new rows (`J8-RULE-007/008`) in `janus-orchestration-rules.md` | FR-B6-JR-060 |
| `_test_b6_10_062_token` | `confluent-cloud` in `compliance-tiers.md::forbidden:` + `REMEDIATION` map | FR-B6-JR-062/063 |

### L2 — fixture-level (3 tests, FR-B6-JR-082)

- `_test_b6_10_l2_refuse_confluent` — invoke the reused helper with
  `event-driven-eu` + `confluent-cloud` (tier unset) ⇒ exit 3 + `[REFUSAL:`
  with `J8-RULE-007`.
- `_test_b6_10_l2_refuse_t3_kafka` — `.forge/.forge-tier`=`T3` +
  `us-managed-kafka` ⇒ exit 3 + `[REFUSAL:` with `J8-RULE-008`.
- `_test_b6_10_l2_nats_no_refuse` — `.forge/.forge-tier`=`T3` +
  `nats-jetstream` ⇒ exit 0, no `[REFUSAL:` (sovereign default). Mirrors
  `b7-9.test.sh::_test_b7_9_l2_t1_no_refuse`.

### Performance (NFR-B6-JR-002)

L1 ≤ 5 s (pure grep) ; full `--level 1,2` ≤ 15 s (three `mktemp` fixtures +
one PyYAML parse each), within the b7-9 envelope.

---

## Standards Applied

- `global/janus-orchestration-rules.md` (J.8) — the rule catalogue this
  change follows (and updates).
- `global/compliance-tiers.md` (I.2) — §10.2 matrix : the VERIFIED source of
  the `AWS / GCP / Azure` CLOUD Act row + the tier gradient.
- `global/forbidden-components-rules.md` (I.3) — the `T3-RULE-005` generic
  `forbidden:` token enforcement + tier-scaled severity + the `REMEDIATION`
  map the review-time coupling reuses.
- `global/standards-lifecycle.md` (T.4) — the SemVer + `REVIEW.md`
  append-only discipline for the two standard edits.
- The `event-driven-eu` schema (`event_specifics.eu_sovereignty`) — the
  authoritative source of the `no_kafka_saas_us` posture + the sanctioned
  `acceptable: [nats-jetstream, redpanda]` list.

---

## Constitutional Compliance Gate

- **Article I (TDD)** — `b6-10.test.sh` written RED first ; implementation
  turns each cluster GREEN.
- **Article II (BDD)** — Gherkin scenarios (specs.md) cover the three
  scaffold-time behaviours.
- **Article III / III.4** — `FR-B6-JR-*` specs precede code ; the sanctioned
  alternatives + the forward-looking-guard classification are verified
  against the schema flag (ADR-B6-JR-005), no fabrication, no open
  `[NEEDS CLARIFICATION]`.
- **Article V (compliance gate)** — `[Story: FR-B6-JR-XXX]` task tags ;
  `J8-RULE-NNN` machine-parseable stderr.
- **Article XII (governance)** — additions per `janus-orchestration-rules.md`
  "Extending the catalogue" are NOT amendments ; the standard edits are
  SemVer-minor with `REVIEW.md` entries ; no `[T1,T2,T3]` enum change.

---

## Open Questions remaining post-design

All three design-phase questions resolved (Q-001 → ADR-B6-JR-001/002,
Q-002 → ADR-B6-JR-003, Q-003 → ADR-B6-JR-004/005/006). No inline
`[NEEDS CLARIFICATION]` remains. See `open-questions.md`.
