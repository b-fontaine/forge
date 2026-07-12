# Proposal: b6-4-hermes-async

<!-- Created: 2026-07-10 -->
<!-- Schema: default -->
<!-- Audit: K.1 (docs/new-archetypes-plan.md §9 line 2668 — Hermes-Async event-driven agent) -->
<!-- Audit: B.6.4 (docs/new-archetypes-plan.md §6.1 line 2556 — Hermes-Async agent for event-driven-eu) -->
<!-- Precedent: .forge/changes/b7-pythia/ (K.2 Sibyl — specialist persona + advisory catalogue + harness + CLAUDE.md row, NO scanner) -->

## Problem

`docs/new-archetypes-plan.md` mandates a new Forge specialist agent for the
`event-driven-eu` archetype:

- §9 line 2668 (K-modules table): **K.1 — Hermes-Async (event-driven)** —
  *"AsyncAPI 3.1, NATS/Kafka bindings, idempotency keys"* — archetype
  `event-driven-eu`, effort `M`.
- §6.1 line 2556 (B.6.4): *"Nouvel agent **Hermes-Async** (K.1) : maintient
  AsyncAPI specs, génère bindings NATS/Kafka, pose les idempotency keys.
  Effort : `M`."*
- §0.12 brick table line 2845: the K row lists
  `.claude/agents/{hermes-async,pythia,demeter,iris-web,themis}.md`.
- `docs/ARCHITECTURE-TARGET.md` §9.2 line 731 introduces **Hermes-Async**
  ("Messager event-driven") — *"Maintient AsyncAPI 3.1 specs, NATS/Kafka
  bindings, idempotency keys"*, archetype `event-driven-eu`.

The `event-driven-eu` archetype already has a scaffolder backbone (`b6-2-scaffolder`,
archived 2026-07-10 — the Rust `events`/`eventstore`/`saga`/`bin-server` crates,
`shared/asyncapi/` AsyncAPI 3.1.0 contract, NATS JetStream + Postgres infra) and a
candidate schema (`b6-1-schema`, archived 2026-07-10). The B.6.3 pattern standards
(`global/event-driven.md`, `global/asyncapi-contracts.md`, `infra/nats-jetstream.md`)
are being authored in parallel (`b6-3-standards`). What the archetype does **not**
have is a **specialist agent** to drive the event-contract work the scaffolded
templates leave to the adopter: keeping the AsyncAPI 3.1 contract in sync with the
emitted events, generating NATS/Kafka protocol bindings, enforcing idempotency keys
end-to-end (publish dedup + consume dedup), and disciplining event versioning as the
domain evolves.

Today none of this exists as an agent:

- No `.claude/agents/hermes-async.md` persona is on disk. The roadmap references the
  agent by name (§9 + §6.1 + §0.12 + ARCHITECTURE-TARGET §9.2) but no agent file
  backs the prose.
- The scaffolded code shapes (`backend/events/src/envelope.rs`,
  `publisher.rs`, `consumer.rs`, `backend/saga/src/compensation.rs`,
  `shared/asyncapi/asyncapi.yaml`) encode the *mechanism* (a versioned/idempotent
  `EventEnvelope`, `Nats-Msg-Id` publish dedup, an `InboxDedup` consumer guard, a
  reverse-order saga compensator) but name no agent that *owns the discipline* of
  keeping them correct as the domain grows.
- The repo `CLAUDE.md` and `docs/GUIDE.md` agent tables have no row routing
  event-driven / AsyncAPI work to a specialist.

This is the B.6 sibling of K.2 Pythia/Sibyl (built as `b7-pythia` for
`ai-native-rag`). It follows the same advisory-specialist shape.

## Solution

A single coordinated specialist-agent change mirroring the `b7-pythia` (Sibyl)
precedent: an **advisory / review-time** specialist (like Panoptes the observability
specialist and Sibyl the AI/RAG specialist), **not** a deterministic-scanner agent
(like Demeter). The plan §9 K.1 verbs are advisory — *maintain*, *generate*,
*enforce* at design/review time — not a reproducible deny-list scan.

### K.1.a — Hermes-Async persona (`.claude/agents/hermes-async.md`)

A new agent file authored in the existing Forge specialist style (compare
`sibyl.md` / Sibyl, `demeter.md` / Demeter, `themis.md` / Themis). The file
declares:

- **Persona** — name (Hermes-Async, the messenger god's event-driven aspect),
  role (event-driven messenger for `event-driven-eu` — maintains AsyncAPI 3.1
  contracts, generates NATS/Kafka bindings, enforces idempotency keys + event
  versioning), style (contract-first, idempotency-mandatory, evidence-driven).
  Disambiguation from the two *other* Hermes-* roster entries: **Hermes** (Flutter
  performance sub-agent) and **Hermes-API** (Connect/gRPC codegen).
- **Purpose** — four responsibilities cited from the plan K.1 row, each mapped to
  the B.6.3 standard it consumes and the real scaffolded code shape it disciplines.
- **Checklists** — one H3 per responsibility area in the Sibyl/Demeter greppable
  `[ ]`-item style: **AsyncAPI Contract Maintenance**, **NATS/Kafka Binding
  Generation**, **Idempotency-Key Enforcement**, **Event Versioning & Compatibility**.
- **Output: Event Contract Readiness Report** — a structured advisory report
  (`READY` / `NEEDS-REVISION` / `BLOCKED`) mirroring the RAG Readiness Report shape.
- **Recommendation catalogue** — `K1-RULE-NNN` namespace (per the `<MODULE>-RULE-NNN`
  format ADR-J8-004 established and K2-RULE-*/K3-RULE-* inherited), 6 seed rules.
- **Integration** — Janus routing for `event-driven-eu` cross-layer changes;
  relationship to Hermes-API (async event contracts vs sync RPC contracts),
  Vulcan (advises vs implements), Atlas (contract vs cluster provisioning).
- **Anti-hallucination protocol** — `[NEEDS CLARIFICATION:]` emission when a target
  is unspecified, and the LIVE-verification rule: never fabricate AsyncAPI 3.1 /
  NATS / Temporal API details from training data — resolve via Context7 / the
  official spec first (Article III.4 + CLAUDE.md rule 6).

### K.1.b — CLAUDE.md + GUIDE.md registration

- The repo `CLAUDE.md` "Agent Delegation System" table gains **one** new row routing
  event-driven / AsyncAPI work to Hermes-Async (adjacent to the Sibyl K.2 row — the
  two archetype specialists). No other row is touched.
- `docs/GUIDE.md`'s "Agents Transversaux" table gains one row (same pattern as the
  Iris-Web and Themis additions already there), noting the disambiguation from
  Hermes (Flutter perf).

### K.1.c — Test harness

`.forge/scripts/tests/b6-4.test.sh` — grep-based L1 + 1 L2 fixture, mirroring the
`b7-pythia.test.sh` layout (name-resolution variable, PASS/FAIL counters,
`--level 1,2`, `print_summary`) **minus the scanner machinery**. Registered in
`.github/workflows/forge-ci.yml` in the B.6 block after `b6-2.test.sh`.

## Scope In

- New persona file `.claude/agents/hermes-async.md` (~200–280 LOC, same density as
  `sibyl.md` / `demeter.md`).
- New `K1-RULE-NNN` recommendation catalogue (namespace per ADR-J8-004; disjoint
  from J8-RULE-* / K2-RULE-* / K3-RULE-*).
- One-line repo `CLAUDE.md` agent-table row.
- One-line `docs/GUIDE.md` agent-table row.
- Test harness `.forge/scripts/tests/b6-4.test.sh` (L1 + 1 L2), registered in
  `forge-ci.yml`.
- Doc updates: `CHANGELOG.md` `## [Unreleased]` entry.

## Scope Out (Explicit Exclusions)

- **NOT** a scanner script. Hermes-Async is advisory (plan §9 K.1 verbs). No
  `bin/forge-hermes-*.sh`, no `.forge/data/*.yml`, no JSON-report exit-code contract.
- **NOT** a new standard file. The three B.6.3 pattern standards
  (`event-driven.md`, `asyncapi-contracts.md`, `nats-jetstream.md`) are authored by
  the sibling `b6-3-standards` lane. Hermes-Async **consumes them by reference** at
  their conventional paths; it does not author or edit them.
- **NOT** an edit to `.claude/agents/cross-layer-orchestrator.md` (Janus) nor
  `.forge/standards/index.yml`. The persona references how Janus routes
  `event-driven-eu` cross-layer changes descriptively (via the schema's
  `cross_layer.agent: Janus` + the `event-design` / `saga-orchestration` phase
  gates), but this change wires no Dispatch-Table row. (Divergence from b7-pythia,
  which DID edit Janus — scoped down here per the task boundary; a later brick may
  wire the Janus dispatch row if required.)
- **NOT** the B.6.10 forbidden-broker Janus rule (no Kafka SaaS US / Confluent
  Cloud). Hermes-Async *references* the EU-sovereignty posture (`nats-jetstream.md`
  + the schema `event_specifics.eu_sovereignty`) as an Advisory rule (K1-RULE-005);
  the blocking scaffold-time enforcement is sibling brick B.6.10.
- **NOT** the scaffolder templates, the schema, the CI pipeline templates (B.6.5),
  the Helm charts (B.6.6), the compliance hooks (B.6.9), or the example project
  (B.6.8). Hermes-Async advises on the shapes those bricks ship; it edits none.
- **NOT** the Temporal saga *implementation*. Hermes-Async's remit is event
  contracts / bindings / idempotency; saga orchestration is Vulcan + Ferris
  (Temporal, Article VIII.2). Hermes-Async asserts the *idempotency* of saga steps
  (its enforcement surface) but does not design the workflow.

## Impact

- **Users affected**:
  - Adopters of `event-driven-eu` gain a named specialist that drives AsyncAPI 3.1
    maintenance, NATS/Kafka binding generation, idempotency enforcement, and event
    versioning — the work the `b6-2-scaffolder` templates left as `#[cfg(test)]`
    scaffolded seed shapes.
  - No change for adopters of other archetypes (Hermes-Async is
    `event-driven-eu`-scoped).
- **Technical impact**: 1 new persona file + 1 new harness + 3 modified
  (`CLAUDE.md` row, `docs/GUIDE.md` row, `forge-ci.yml` matrix) + `CHANGELOG.md`.
  No scanner, no data file, no new standard, no Janus/index edit. **Effort `M`**.
- **Dependencies**:
  - `b6-1-schema` (archived 2026-07-10) — the schema Hermes-Async serves
    (`event_specifics`, `event-design` / `saga-orchestration` phases).
  - `b6-2-scaffolder` (archived 2026-07-10) — the code shapes Hermes-Async
    disciplines (`EventEnvelope`, `Nats-Msg-Id` dedup, `InboxDedup`, `Saga`).
  - `b6-3-standards` (parallel lane, `b6-3-standards` branch) — the three standards
    Hermes-Async owns/consumes by reference. Referenced by path; content not
    depended on for this change to land.
  - `b7-pythia` (archived 2026-06-22) — precedent for the advisory-specialist
    persona + harness + CLAUDE.md/GUIDE.md-row layout; source of the
    `<MODULE>-RULE-NNN` namespace convention `K1-RULE-*` inherits.
- **Risk level**: **Low**. The persona file is pure documentation. No blocking name
  collision (unlike b7-pythia's Q-001): "Hermes-Async" is a distinct roster name,
  mandated verbatim by the roadmap, disambiguated from Hermes / Hermes-API.
- **Shared-file collision risk** (sibling bricks): `CLAUDE.md`, `docs/GUIDE.md`,
  `CHANGELOG.md`, and `forge-ci.yml` are co-edited by the five concurrent B.6 lanes
  (B.6.3, B.6.5, B.6.6, B.6.9, B.6.10). Each Hermes-Async edit is a single additive
  row/line; conflicts are resolved centrally after the 6 PRs land.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. `b6-4.test.sh` is authored with real assertions and
run to confirm RED (persona + doc rows absent) before the persona is authored; the
persona + rows flip it GREEN.

### Article II — BDD

The user-facing flow (Janus routes an `event-driven-eu` cross-layer change to
Hermes-Async and receives an Event Contract Readiness Report) gets Given/When/Then
scenarios in `specs.md`. Hermes-Async is advisory, so the scenarios assert report
shape + rule firing, not a CLI exit code.

### Article III — Specs Before Code

`proposal.md` → `specs.md` (`FR-B6-HA-*`) → `design.md` → `tasks.md` precede the
persona + harness.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

No blocking ambiguity. Three non-blocking open questions (Q-001 name-adjacency,
Q-002 rule seed size, Q-003 advisory-vs-scanner) are tracked in `open-questions.md`
and answered at design. The persona itself embeds the Article III.4 contract for its
*runtime* advice, extended with the CLAUDE.md rule-6 LIVE-verification mandate for
AsyncAPI / NATS / Temporal API details.

### Article VIII — Infrastructure

- **VIII.2 (Temporal orchestration)** — Hermes-Async ENFORCES that saga steps and
  event handlers are idempotent so Temporal can safely retry them (the archetype's
  `exactly_once: via_temporal_and_idempotency_keys` guarantee). This is the single
  Blocking-severity check Hermes-Async owns (K1-RULE-006). It does not design the
  workflow (Vulcan/Ferris territory).

### Article XI — AI-First Design

- **XI.1 (Agent-Native / idempotent actions)** — the archetype's idempotency posture
  ("Actions are idempotent where possible, enabling agent retry without side
  effects") is exactly what Hermes-Async enforces at the event layer.

### Article XII — Governance

Hermes-Async ENFORCES the event-driven + EU-sovereignty posture encoded in the
B.6.3 standards + the schema. It does **not amend** any constitutional article and
authors no new standard (consumes the B.6.3 standards by reference).

## Open Questions

Three non-blocking open questions tracked in `open-questions.md`:

- **Q-001** (non-blocking) — Hermes-* name-adjacency: confirm "Hermes-Async" is
  distinct from "Hermes" (Flutter perf) and "Hermes-API" (Connect codegen).
- **Q-002** (non-blocking) — `K1-RULE-NNN` seed catalogue size (pre-allocate vs
  incremental).
- **Q-003** (non-blocking) — advisory agent vs Demeter-style scanner.

All three are resolvable at design; none blocks the flip to `implemented`.
