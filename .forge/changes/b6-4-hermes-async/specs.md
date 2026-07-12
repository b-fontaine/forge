# Specifications: b6-4-hermes-async

<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-B6-HA-*` / `NFR-B6-HA-*` / `ADR-K1-*`. Recommendation-rule
namespace : `K1-RULE-*`. **Constitution** : v2.0.0. No amendment required (K.1
introduces a new advisory specialist agent ; existing articles unchanged ; it
ENFORCES Articles VIII.2 + XI.1, does not amend them).

## Source Documents

| Field             | Value                                                                                                                                                          |
|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Audit base**    | `K.1` (`docs/new-archetypes-plan.md` §9 line 2668 — K-modules table) + `B.6.4` (`docs/new-archetypes-plan.md` §6.1 line 2556 — Hermes-Async agent for event-driven-eu) |
| **Precedent**     | `.forge/changes/b7-pythia/` (K.2 Sibyl — advisory persona + `K2-RULE-*` catalogue + harness + CLAUDE.md row, NO scanner) ; `.claude/agents/sibyl.md` (closest sibling) |
| **Plan ref**      | `docs/new-archetypes-plan.md` §0.12 brick table line 2845 (K row) ; §6.1 line 2556 (B.6.4) ; §9 line 2668 (K.1) ; `docs/ARCHITECTURE-TARGET.md` §9.2 line 731 (agent introduction) |
| **Standards consumed** | `global/event-driven.md` (B.6.3) ; `global/asyncapi-contracts.md` (B.6.3) ; `infra/nats-jetstream.md` (B.6.3) — authored by the sibling `b6-3-standards` lane ; referenced BY PATH, not depended on for this change to land |
| **Schema ref**    | `.forge/schemas/event-driven-eu/1.0.0.yaml` (b6-1-schema — `event_specifics` {event_versioning / idempotency_keys / saga_compensation / exactly_once} + `event-design` / `saga-orchestration` phases) |
| **Scaffold ref**  | `b6-2-scaffolder` (archived 2026-07-10) — `backend/events/src/{envelope,publisher,consumer}.rs`, `backend/saga/src/compensation.rs`, `shared/asyncapi/asyncapi.yaml` — the code shapes Hermes-Async disciplines |
| **Pattern reuse** | `j8-janus-rules` ADR-J8-004 (`<MODULE>-RULE-NNN` rule-ID format) ; `b7-pythia` ADR-K2-002 (incremental rule growth) ; `b7-pythia` ADR-K2-003 (advisory agent, no scanner) |
| **Constitution**  | Article VIII.2 (Temporal orchestration — durable retry requires idempotent steps) ; Article XI.1 (agent-native — idempotent actions enabling safe retry) |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Hermes-Async persona file (FR-B6-HA-001 → 008)

##### FR-B6-HA-001 — Persona file location

A new persona file MUST exist at `.claude/agents/hermes-async.md`, following the
`.claude/agents/<name>.md` flat-layout convention used by all top-level Forge
specialists (e.g. `sibyl.md`, `demeter.md`, `themis.md`).

##### FR-B6-HA-002 — Persona section

The file MUST start with an H1 `# Agent: Event-Driven Messenger (Hermes-Async)` and
a `## Persona` H2 declaring:
- **Name** : Hermes-Async.
- **Role** : event-driven messenger for the `event-driven-eu` archetype — maintains
  AsyncAPI 3.1 contracts, generates NATS/Kafka bindings, enforces idempotency keys
  and event versioning. Advises at design/review time ; writes no application code.
- **Style** : contract-first, idempotency-mandatory, evidence-driven. Mirrors the
  Sibyl/Demeter stylistic pattern (every recommendation carries a severity, specific
  evidence, and an actionable step).
- **Disambiguation** : distinct from **Hermes** (Flutter performance sub-agent) and
  **Hermes-API** (Connect/gRPC + OpenAPI codegen). Hermes-Async owns the
  *asynchronous event contract* surface only.

##### FR-B6-HA-003 — Purpose section

A `## Purpose` H2 MUST describe Hermes-Async's four responsibilities and explicitly
cite the source audit items (K.1 + B.6.4) and the three B.6.3 standards it consumes
(`event-driven.md`, `asyncapi-contracts.md`, `nats-jetstream.md`). It MUST state that
Hermes-Async is `event-driven-eu`-scoped (not invoked on other archetypes).

##### FR-B6-HA-004 — Checklists section

A `## Checklists` H2 MUST host at least four H3 sub-sections, each in the
Sibyl/Demeter greppable `[ ]`-item style with `Verify:` / `Check:` / `Exception:`
annotations (≥ 5 `[ ]` items per sub-section):
- **AsyncAPI Contract Maintenance** — consumes `asyncapi-contracts.md`.
- **NATS/Kafka Binding Generation** — consumes `nats-jetstream.md`.
- **Idempotency-Key Enforcement** — consumes `event-driven.md`.
- **Event Versioning & Compatibility** — consumes `event-driven.md` +
  `asyncapi-contracts.md`.

##### FR-B6-HA-005 — Output report format

An `## Output: Event Contract Readiness Report` H2 MUST declare the report shape,
mirroring the RAG Readiness Report template but for event contracts (advisory, not
policy-refusal):
- A `Summary` table with severity counts (`Blocking` / `Concern` / `Advisory` /
  `Cleared`).
- A `Findings` section with per-finding entries citing `[SEVERITY] <K1-RULE-NNN>:
  <title>`, `Category`, `Location`, `Evidence`, `Recommendation`, `Verification`.
- A `Cleared Items` section.
- An overall status line: `BLOCKED` / `NEEDS-REVISION` / `READY`
  (`BLOCKED` only when the VIII.2 idempotency gate fails — the single
  Blocking-severity case ; `NEEDS-REVISION` on any Concern ; `READY` otherwise).

##### FR-B6-HA-006 — Recommendation catalogue section

A `## Recommendation Catalogue` H2 MUST enumerate the seed `K1-RULE-*` rules
(≥ 6 rules, see Cluster 5). Each rule MUST cite: (a) trigger, (b) severity
(`Advisory` / `Concern` / `Blocking`), (c) evidence pattern, (d) recommendation,
(e) cross-link to the relevant B.6.3 standard or constitutional article.

##### FR-B6-HA-007 — Integration section

A `## Integration` H2 MUST describe:
- How Janus routes `event-driven-eu` cross-layer changes to Hermes-Async
  (cross-link to `cross-layer-orchestrator.md` + the schema `cross_layer.agent:
  Janus` + the `event-design` / `saga-orchestration` phase gates).
- The relationship to **Hermes-API**: Hermes-API owns the *synchronous* Connect/gRPC
  + OpenAPI 3.1 contract surface ; Hermes-Async owns the *asynchronous* AsyncAPI 3.1
  event-contract surface. Disjoint transports.
- The relationship to **Vulcan** (Rust backend orchestrator): Hermes-Async
  *advises* ; Vulcan (with Ferris/Centurion) *implements* the `events` / `eventstore`
  / `saga` crates. Hermes-Async writes no application code.
- The relationship to **Atlas** (infra): Atlas provisions the NATS JetStream
  cluster (Helm, B.6.6) ; Hermes-Async specifies the subject/consumer contract Atlas
  must honour. Disjoint surfaces.

##### FR-B6-HA-008 — Anti-hallucination protocol

A `## Anti-Hallucination Protocol` H2 MUST state the Article III.4 contract AND the
CLAUDE.md rule-6 LIVE-verification mandate: when a target is unspecified (undeclared
broker/protocol, undeclared compatibility policy) Hermes-Async MUST emit
`[NEEDS CLARIFICATION: <specific question>]` and STOP ; and it MUST NOT fabricate
AsyncAPI 3.1 / NATS / Temporal API details from training data — those MUST be
resolved LIVE via Context7 / the official spec before being asserted (API surfaces
change between versions).

---

#### Cluster 2 — Audit anchors + citations (FR-B6-HA-010 → 011)

##### FR-B6-HA-010 — Audit comment

The persona file MUST carry a top-of-file `<!-- Audit: K.1 (b6-4-hermes-async) -->`
HTML comment. A second `<!-- Audit: B.6.4 (b6-4-hermes-async) -->` comment MUST be
added (B.6.4 is the §6.1 plan item that mandates the agent). Both MUST appear within
the first 6 lines.

##### FR-B6-HA-011 — Source citations

The persona footer MUST cite the upstream sources that justify Hermes-Async's
existence, with section + line refs (same convention as the `sibyl.md` / `demeter.md`
footers):
- `docs/ARCHITECTURE-TARGET.md` §9.2 line 731 (agent introduction)
- `docs/new-archetypes-plan.md` §9 line 2668 (K.1 row)
- `docs/new-archetypes-plan.md` §6.1 line 2556 (B.6.4)
- `docs/new-archetypes-plan.md` §0.12 brick table line 2845 (K row)
- `.forge/schemas/event-driven-eu/1.0.0.yaml` (B.6.1 — the served schema)
- the three B.6.3 standards consumed.

---

#### Cluster 3 — Domain coverage (FR-B6-HA-020 → 027)

These FRs pin *what* the checklists must cover, grounded in the real scaffolded code
shapes and the B.6.3 standards. Hermes-Async MUST NOT redefine or contradict the
standards — it operationalises them as review-time checks.

##### FR-B6-HA-020 — AsyncAPI contract-sync coverage

The AsyncAPI Contract Maintenance checklist MUST cover: the AsyncAPI **3.1.0**
document as the event single source of truth (`shared/asyncapi/asyncapi.yaml`),
channels/operations/messages kept in sync with the emitted `event_type`s, the
`EventHeaders` schema declaring `Nats-Msg-Id` required, and validation before merge
— per `asyncapi-contracts.md`.

##### FR-B6-HA-021 — Subject-namespacing coverage

The checklist MUST assert NATS subjects are namespaced `events.v<version>.<EventType>`
(matching `EventEnvelope::subject()` in `backend/events/src/envelope.rs`) so that
`event_version` is encoded in the subject and consumers select the right deserializer
by `(event_type, event_version)` — per `nats-jetstream.md` + `event-driven.md`.

##### FR-B6-HA-022 — NATS/Kafka binding coverage

The NATS/Kafka Binding Generation checklist MUST cover generating protocol bindings
from the AsyncAPI contract for NATS JetStream (the default) and Kafka-API-compatible
brokers (Redpanda), and MUST reference the EU-sovereignty constraint (Confluent
Cloud / Kafka SaaS US forbidden ; NATS JetStream + Redpanda acceptable) per the
schema `event_specifics.eu_sovereignty` + `nats-jetstream.md`.

##### FR-B6-HA-023 — Publish-dedup coverage

The Idempotency-Key Enforcement checklist MUST assert the publish path sets the
JetStream `Nats-Msg-Id` header to the envelope idempotency key (matching
`JetStreamPublisher` in `backend/events/src/publisher.rs`) so the server deduplicates
re-published events within its dedup window — per `event-driven.md` + `nats-jetstream.md`.

##### FR-B6-HA-024 — Consume-dedup (inbox) coverage

The checklist MUST assert consumers deduplicate at-least-once redelivery via an inbox
guard keyed by `idempotency_key` (matching `InboxDedup` in
`backend/events/src/consumer.rs` ; production-backed by a Postgres `inbox` table) —
per `event-driven.md` § inbox pattern.

##### FR-B6-HA-025 — Idempotent-handler / saga-step coverage (VIII.2)

The checklist MUST assert every event handler AND every saga step (both `execute` and
`compensate`, matching `SagaStep` in `backend/saga/src/compensation.rs`) is
idempotent so Temporal can safely retry them — per `event-driven.md` + Article VIII.2.
This is the enforcement surface of the archetype's `exactly_once:
via_temporal_and_idempotency_keys` guarantee.

##### FR-B6-HA-026 — Event-versioning discipline coverage

The Event Versioning & Compatibility checklist MUST cover: `event_version` carried in
the envelope, additive/backward-compatible schema evolution, a version bump on any
breaking payload change, and a matching AsyncAPI message/version update — per
`asyncapi-contracts.md` (versioning) + `event-driven.md`.

##### FR-B6-HA-027 — Outbox coverage

The checklist MUST cover the transactional outbox pattern (persist-then-publish so an
event is never lost between the event-store append and the JetStream publish) as the
recommended posture (`event_specifics.outbox_inbox_pattern: recommended`) — per
`event-driven.md` § outbox.

---

#### Cluster 4 — CLAUDE.md + GUIDE.md + guards (FR-B6-HA-080 → 086)

##### FR-B6-HA-080 — CLAUDE.md trigger registration

The repo-level `CLAUDE.md` "Agent Delegation System" table MUST gain a new row
routing event-driven / AsyncAPI work to Hermes-Async, placed adjacent to the
`AI/RAG tuning | Sibyl` K.2 row. The row text MUST be
`| Event-driven / AsyncAPI | **Hermes-Async** | Event-Driven Messenger |`. No other
row is modified.

##### FR-B6-HA-081 — GUIDE.md trigger registration

`docs/GUIDE.md`'s "Agents Transversaux" table MUST gain a Hermes-Async row (same
pattern as the Iris-Web / Themis additions there), naming the four responsibilities
and disambiguating from Hermes (Flutter perf).

##### FR-B6-HA-082 — No new standard file

This change MUST NOT create any new `.forge/standards/**/*.md` file. The three
event-driven pattern standards are authored by the sibling `b6-3-standards` lane.
Asserted as a guard so reviewers can confirm Hermes-Async's ownership is
by-reference, not by re-authoring.

##### FR-B6-HA-083 — Janus + standards-index NOT edited

`.claude/agents/cross-layer-orchestrator.md` and `.forge/standards/index.yml` MUST
NOT be edited by this change (task-boundary guard ; divergence from b7-pythia). The
persona references Janus routing descriptively but wires no Dispatch-Table row.

##### FR-B6-HA-084 — No scanner / no data file

This change MUST NOT create any `bin/forge-hermes*.sh` scanner or `.forge/data/
hermes*.yml` data file. Hermes-Async is advisory (ADR-K1-003). Asserted as a guard.

##### FR-B6-HA-085 — Real code-shape grounding

The persona MUST reference the real scaffolded code shapes so its checklists cite
existing code, not generic advice: `EventEnvelope`, the `Nats-Msg-Id` header, the
`idempotency_key` field, and the `events.v<version>.` subject namespacing MUST all be
named in the persona.

##### FR-B6-HA-086 — No RULE-namespace collision

The `K1-RULE-*` namespace MUST NOT collide with `J8-RULE-*`, `K2-RULE-*`,
`K3-RULE-*`, or any other `<MODULE>-RULE-*` namespace. `K1-RULE` MUST NOT leak into
the Janus agent, the J.8 standard, the Demeter persona, or the Sibyl persona ; and
those other namespaces MUST NOT be over-cited in the Hermes-Async persona (≤ 2
cross-link acknowledgements each).

---

#### Cluster 5 — Seed K1-RULE catalogue (FR-B6-HA-120 → 125)

Incremental, 6 seed rules per ADR-K1-002 (mirrors `b7-pythia` ADR-K2-002). Severity
vocabulary: `Advisory` (suggestion), `Concern` (should-fix before production),
`Blocking` (the VIII.2 idempotency gate only).

##### FR-B6-HA-120 — K1-RULE-001 — AsyncAPI contract drift

**Trigger**: the code emits an `event_type` absent from `shared/asyncapi/asyncapi.yaml`
(or vice-versa). **Severity**: `Concern`. **Recommendation**: reconcile the AsyncAPI
contract with the emitted events before merge per `asyncapi-contracts.md`.

##### FR-B6-HA-121 — K1-RULE-002 — Breaking change without version bump

**Trigger**: a payload/message changes shape incompatibly without an `event_version`
bump + matching AsyncAPI message-version update. **Severity**: `Concern`.
**Recommendation**: bump `event_version`, keep the old version deserializable, update
the AsyncAPI contract per `asyncapi-contracts.md` + `event-driven.md`.

##### FR-B6-HA-122 — K1-RULE-003 — Publish path not deduplicated

**Trigger**: an event is published without `Nats-Msg-Id` set to the idempotency key.
**Severity**: `Concern`. **Recommendation**: set `Nats-Msg-Id` to the envelope
idempotency key (as `JetStreamPublisher` does) so JetStream dedups re-publishes per
`nats-jetstream.md`.

##### FR-B6-HA-123 — K1-RULE-004 — Consumer lacks inbox dedup

**Trigger**: a consumer processes events with no inbox guard, so an at-least-once
redelivery is handled twice. **Severity**: `Concern`. **Recommendation**: add an
inbox dedup keyed by `idempotency_key` (as `InboxDedup` does ; back it with a Postgres
`inbox` table) per `event-driven.md`.

##### FR-B6-HA-124 — K1-RULE-005 — Forbidden broker (Kafka SaaS US)

**Trigger**: the event backbone is declared as Confluent Cloud / a US Kafka SaaS.
**Severity**: `Advisory` (cross-links the B.6.10 Janus forbidden-broker rule, the
*blocking* scaffold-time enforcement ; Hermes-Async flags it at design time).
**Recommendation**: use NATS JetStream or Redpanda (EU-deployable, CNCF) per the
schema `event_specifics.eu_sovereignty` + `nats-jetstream.md`.

##### FR-B6-HA-125 — K1-RULE-006 — Idempotency/exactly-once not enforced (VIII.2)

**Trigger**: an event handler or saga step (`execute`/`compensate`) is not idempotent,
OR an event carries no stable idempotency key wired to dedup — breaking the
archetype's `exactly_once` guarantee and Temporal's safe-retry contract. **Severity**:
`Blocking` (the only Blocking rule). **Recommendation**: make handlers + saga steps
idempotent and wire the idempotency key end-to-end (publish `Nats-Msg-Id` + consume
inbox) per `event-driven.md` + Article VIII.2. A pipeline that cannot be safely
retried is not considered complete.

---

### Non-Functional Requirements

#### NFR-B6-HA-001 — Backward compatibility

Purely additive. Adopters not invoking Hermes-Async (no `event-driven-eu` project)
MUST observe ZERO behavioural change. No existing persona's behaviour changes.

#### NFR-B6-HA-002 — No application code, no scanner, no pins

Hermes-Async is a `.claude/agents/` Markdown persona only. This change MUST NOT create
any `bin/forge-*.sh`, any `.forge/data/*.yml`, any `cli/src/**.ts`, any version pin,
any template, or any Rust/Dart/TS source (guard against scanner task-creep,
ADR-K1-003).

#### NFR-B6-HA-003 — Article V audit trail

Every task tagged `[Story: FR-B6-HA-XXX]` (Article V.1). Every Hermes-Async finding
carries a `K1-RULE-NNN` ID in the report's structured shape.

#### NFR-B6-HA-004 — Standards consumed, not amended

Hermes-Async consumes `event-driven.md` / `asyncapi-contracts.md` / `nats-jetstream.md`
by reference and MUST NOT edit, contradict, re-author, or depend on their content
existing on disk for this change to land (they arrive via the sibling `b6-3-standards`
lane).

#### NFR-B6-HA-005 — No regression in sibling harnesses

`verify.sh`, `constitution-linter.sh`, `b6-1`, `b6-2`, `b7-pythia`, `k3`, `k5`,
`j8` MUST remain GREEN. This change adds one new harness + additive doc rows only.

#### NFR-B6-HA-006 — Shared-file edit disjointness

The `CLAUDE.md` / `docs/GUIDE.md` / `CHANGELOG.md` / `forge-ci.yml` edits MUST be
single additive rows/lines, disjoint from the concurrent B.6 lanes' edits. Whichever
brick lands second rebases its surgical delta.

#### NFR-B6-HA-007 — Name-resolution variable in harness

The harness MUST resolve the persona path from a single `HERMES_AGENT` variable
(default `.claude/agents/hermes-async.md`), overridable by env, mirroring the
`b7-pythia.test.sh` `PYTHIA_AGENT` convention.

---

## BDD Acceptance Criteria

### Scenario 1 — Janus routes an event-driven-eu cross-layer change to Hermes-Async

```gherkin
Given a project whose root .forge.yaml declares schema: event-driven-eu
And a change touching backend/ (events) and infra/ (NATS) — 2 layers
When Janus processes the cross-layer change
Then Hermes-Async advises the AsyncAPI/binding/idempotency design pass
And Hermes-Async returns an Event Contract Readiness Report with an overall status line
And the report's status is BLOCKED if and only if the VIII.2 idempotency gate (K1-RULE-006) fails
```

### Scenario 2 — Non-idempotent saga step blocks the change (VIII.2)

```gherkin
Given an event-driven-eu feature whose saga step is not idempotent on retry
When Hermes-Async runs its Idempotency-Key Enforcement checklist
Then the report contains 1 finding with rule_id "K1-RULE-006" and severity "Blocking"
And the overall status is "BLOCKED"
And the recommendation cites "make handlers + saga steps idempotent per Article VIII.2"
```

### Scenario 3 — Uncertain AsyncAPI binding detail emits NEEDS CLARIFICATION (III.4 + rule 6)

```gherkin
Given a change requires a NATS binding keyword whose AsyncAPI 3.1 shape is uncertain
When Hermes-Async is asked to assert the binding
Then it emits "[NEEDS CLARIFICATION: AsyncAPI 3.1 binding shape unverified — resolve via Context7 before asserting]"
And it does NOT fabricate the binding keyword from training data
```

---

## Anti-Hallucination Pass

For each FR:

- **Testable** : every FR is asserted by at least one test in `b6-4.test.sh`
  (mapping captured in `tasks.md` `[Story: FR-B6-HA-XXX]` tags).
- **Unambiguous** : 3 open questions flagged — Q-001 (name-adjacency), Q-002 (rule
  seed size), Q-003 (advisory-vs-scanner). All non-blocking, resolved at design.
- **Constitution-compliant** : Articles I (TDD), II (BDD), III + III.4 (specs first +
  ambiguity), V (audit trail), VIII.2 (idempotency — Hermes-Async enforces), XI.1
  (agent-native idempotent actions), XII (governance — authors no new standard).

## Open Questions

No inline `[NEEDS CLARIFICATION:]` markers in this `specs.md`. Q-001 + Q-002 + Q-003
tracked in `open-questions.md`, resolved during `/forge:design` via ADR-K1-001..003.
None is blocking.

## Counts

- **FR-B6-HA-*** : 29 (8 persona 001-008, 2 audit/citations 010-011, 8 domain
  coverage 020-027, 7 integration/guards 080-086, 6 seed rules 120-125)
- **NFR-B6-HA-*** : 7 (001-007)
- **BDD Scenarios** : 3
- **Open Questions** : 3 (Q-001 + Q-002 + Q-003, all non-blocking)
- **ADRs (design phase)** : 3 (ADR-K1-001..003)
