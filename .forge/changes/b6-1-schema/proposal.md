# Proposal: b6-1-schema

<!-- Created: 2026-07-10 -->
<!-- Schema: default -->
<!-- Audit: B.6.1 (docs/new-archetypes-plan.md §6.1 — event-driven-eu/1.0.0.yaml archetype scaffold schema) -->

## Problem

T7 opens the two new archetypes (plan §6, §11). `event-driven-eu` is the
EU-sovereign event-driven archetype — NATS JetStream (event backbone) + Temporal
(saga / process-manager orchestration) + AsyncAPI 3.1 (event contracts) on a Rust
axum/tonic/Connect backend with a Postgres event store. It is the sibling of
`ai-native-rag` (B.7, fully shipped), built the same incremental B.8-grain way;
this change is **link #1**: the archetype scaffold schema that every downstream
B.6 brick (scaffolder, standards, Hermes-Async agent, CI pipelines, Helm charts,
harness, example) validates against.

**Ground truth (re-read 2026-07-10, Article III.4):**

- **There are two distinct schema families** under `.forge/schemas/`:
  - *workflow/process schemas* (`default/`, `rapid/`, `tdd-rust/`, `tdd-flutter/`,
    `ai-first/`, `mobile-only/`) — `schema.yaml` with `extends:` + `phases`, **no
    `layers`/`components`**. They define a change's dev *process*.
  - *archetype scaffold schemas* (`full-stack-monorepo/{schema,2.0.0}.yaml`,
    `ai-native-rag/1.0.0.yaml`) — `name`/`version`/`stage`/`scaffoldable`/`layers`/
    `components`/`phases`, **no functional `extends:`**. They define what
    `forge init --archetype <name>` produces.
  Plan §6.1 says the file "étend `tdd-rust`". As with B.7.1's `ai-first` case, the
  file lives at the *scaffold* path but the plan wants the *process* semantics of
  `tdd-rust`. **Recorded, not normalized** (→ ADR-B6-1-001).

- **`extends:` is resolved by NO scaffold-schema loader.** Confirmed live for B.7.1
  and re-confirmed here: `parseSchemaMeta` (`cli/src/domain/schema-version.ts`)
  line-parses only `version`/`stage`/`scaffoldable`; `check_versioned_schema_siblings`
  (`validate-foundations.sh`) reads `layers`/`phases` **directly from the versioned
  file**. An `extends: tdd-rust` would NOT inherit phases — the validator would fail
  `phases missing or empty`. ⇒ the tdd-rust phases MUST be **inlined** (→ ADR-B6-1-001).

- **The versioned-schema validator already gates this file ON LANDING**
  (`check_versioned_schema_siblings`, generic across all archetype dirs). For
  `<archetype>/<X.Y.Z>.yaml` it enforces: `name` == dir name; `version` valid SemVer
  **and** == filename stem; `layers` non-empty list **including backend/frontend/infra**,
  each with `id`/`path`/`fr_id_prefix`/`primary_agent`; `stage` ∈ {draft,candidate,stable};
  **`stage: candidate` ⇒ `scaffoldable: false`**; `phases` non-empty.
  `event-driven-eu/1.0.0.yaml` is validated immediately — it MUST satisfy every
  invariant the moment it lands. (Note: the validator requires a `frontend` layer
  even though this archetype is backend-centric — modelled per ADR-B6-1-004.)

- **CLI selection** (`selectScaffoldableVersion`, schema-version.ts): picks the
  highest `stage: stable` + `scaffoldable: true`. A dir whose only version is
  `candidate`/`scaffoldable:false` returns `null`. Per the verified B.7.1 flow,
  `init.ts` checks the dispatch-table FIRST, so an archetype not registered there
  refuses with **exit 2** (unknown archetype); the null → **exit 3** path is reached
  only once the archetype is registered in `dispatch-table.yml` (B.6.2 does that,
  mirroring B.7.2a). Correct for B.6.1 either way: no templates yet ⇒ not
  scaffoldable ⇒ init refuses cleanly.

- **Component standards — partial gap.** Temporal→`orchestration.yaml`
  (v1.2.0, `default_by_language.rust: temporal`), Postgres→`persistence.yaml`,
  Connect→`transport.yaml` (which already lists `asyncapi-3.1` under
  `derived_outputs`), Zitadel→`identity.yaml`, observability→`observability.yaml`
  all exist. But **`nats-jetstream`, `event-driven` (saga/outbox/inbox), and
  `asyncapi-contracts` standards do NOT exist** — they are B.6.3
  (`standards/global/event-driven.md`, `global/asyncapi-contracts.md`,
  `infra/nats-jetstream.md`). Mirrors the B.7.1 llm-gateway/MCP/rag gap exactly.
  **Recorded, not fabricated** (→ ADR-B6-1-003).

## Solution

Author the **specification for** `.forge/schemas/event-driven-eu/1.0.0.yaml` — its
required content, the tdd-rust process it materialises + the two B.6.1 phase
additions, the component set it references, and the candidate/non-scaffoldable
rules. Like B.7.1, this change is **propose + specify + design + plan** and the
schema file itself + its harness are built at the implementation phase; it ships
**no scaffolder, no template, no version pin, and edits no existing
schema/standard/constitution**.

The `1.0.0.yaml`, when built, MUST:

1. Use the *archetype scaffold schema* shape (parity with
   `ai-native-rag/1.0.0.yaml` / `full-stack-monorepo/2.0.0.yaml`): `name`,
   `version`, `stage`, `scaffoldable`, `description`, `tdd_enforced`,
   `bdd_required_for_user_facing`, `coverage_threshold`, `layers`,
   `fr_id_prefix_cross_layer`, `cross_layer`, `phases`.
2. Declare `name: event-driven-eu`, `version: "1.0.0"`, `stage: candidate`,
   `scaffoldable: false`.
3. Declare the minimum `layers` triple backend/frontend/infra (validator
   contract), modelling the event-driven topology — Rust backend (NATS producers/
   consumers + Postgres event store + Temporal saga activities), a (deferred)
   frontend ops surface, infra (NATS JetStream cluster / Temporal / Postgres /
   observability).
4. **Inline** the tdd-rust phases (materialised from `tdd-rust/schema.yaml`, NOT via
   `extends`): proposal → specs → features → design → tasks → implementation →
   review → archive, PLUS the two B.6.1 additions: **`event-design`** (AsyncAPI 3.1
   event contracts specified before design) and **`saga-orchestration`** (a gate on
   Temporal saga/workflow design review). Carry an `event_specifics` block (event
   versioning, idempotency keys, saga compensation, outbox/inbox, EU sovereignty).
5. Declare the component SET **reference-only** (no inline pins, ADR-B8-3-002 /
   ADR-B7-1-003 precedent): Temporal→`orchestration.yaml`, Postgres→`persistence.yaml`,
   Connect→`transport.yaml`, Zitadel→`identity.yaml`, observability→`observability.yaml`;
   and **reference the deferred standards** for NATS JetStream, event-driven
   patterns, and AsyncAPI contracts (delivered by B.6.3) — recorded as a gap, never
   fabricated.
6. Carry a header block documenting candidate semantics: not scaffoldable while no
   templates exist; promotion to `stable` + `scaffoldable: true` happens at the
   later B.6 promotion brick (B.6.7 harness, analogous to B.7.6 / B.8.14),
   additive (no existing archetype affected).

Decisions reserved for `/forge:design` (ADRs); leanings stated:

- **ADR-B6-1-001 — phases: inline (materialised) vs `extends: tdd-rust`.** Lean:
  **inline** the tdd-rust phases + add `event-design`/`saga-orchestration`, because
  no scaffold-schema loader resolves `extends`. Keep `extends: tdd-rust` as
  documentary provenance only.
- **ADR-B6-1-002 — stage/scaffoldable for the first cut.** Lean: `candidate` +
  `scaffoldable: false`. Promotion to `stable` deferred to the B.6.7 harness brick
  (mirrors B.7.6 / B.8.14).
- **ADR-B6-1-003 — components reference-only + deferred-standard gap.** Lean:
  reference-only. nats-jetstream / event-driven / asyncapi-contracts standards do
  not exist yet → reference them as `delivered_by: B.6.3` with no inline pin.
- **ADR-B6-1-004 — layer modelling for a backend-centric archetype.** Lean:
  backend/frontend/infra triple (validator contract). The frontend layer is
  declared with a deferred/optional ops-console surface; the archetype's value is
  the backend event stack. Exact `layers[]` shape decided at design.

Release vehicle: maintainer-set (additive spec artifact; no runtime change).

## Scope In

- `proposal.md`, `specs.md`, `design.md`, `tasks.md`, `.forge.yaml` for
  `b6-1-schema` (this change).
- Requirements `FR-B6-1-*` / `NFR-B6-1-*` defining WHAT the schema file must
  contain and the candidate/non-scaffoldable rules.
- ADRs `ADR-B6-1-001..004` (phases-inline, stage, components, layers).
- At impl: `.forge/schemas/event-driven-eu/1.0.0.yaml` + `.forge/scripts/tests/b6-1.test.sh`.

## Scope Out (Explicit Exclusions)

- **Scaffolder + templates** `templates/archetypes/event-driven-eu/**` + dispatch
  registration — B.6.2 (`b6-2-scaffolder`).
- **Standards** `event-driven.md` / `asyncapi-contracts.md` / `nats-jetstream.md` —
  B.6.3. This change references them as deferred; it creates none.
- **Agent Hermes-Async (K.1 / B.6.4)** — separate brick.
- **CI pipeline templates (B.6.5), Helm Temporal cluster (B.6.6), snapshot harness
  + promotion flip (B.6.7), example project (B.6.8), compliance hooks (B.6.9),
  Kafka-SaaS interdiction (B.6.10)** — later bricks/lanes.
- **Constitution amendment** — none. `event-driven-eu` consumes §VIII.1 (Envoy /
  Connect) + §VIII.2 (Temporal) as-is.
- **Component version pins** — owned by the referenced standards; never inlined.

## Impact

- **Users affected**: B.6 archetype authors (the schema is the shared contract
  gating the rest of the B.6 chain). **Zero** effect on existing adopters: no
  current archetype is touched; `event-driven-eu` is not scaffoldable yet, so
  `forge init --archetype event-driven-eu` refuses cleanly (exit 2 today — unknown
  archetype; exit 3 once B.6.2 registers it) rather than emitting a broken scaffold.
- **Technical impact**: spec artifacts only in this change. At impl the schema file
  is a new sibling validated on landing by `check_versioned_schema_siblings`.
- **Dependencies**: B.8.3.b (generic versioned-schema validator) + B.8.14 (CLI
  selection/refusal path). Gates B.6.2, B.6.3 and the rest of the B.6 chain.

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: propose+specify+design+plan gate;
  the schema file is built only after design.
- **Article III.4 (Anti-Hallucination)**: the two schema families, `extends`
  non-resolution, the versioned validator contract, and the missing
  nats/event/asyncapi standards are re-read from live files; recorded, not
  normalised. No library pin is committed here.
- **Article IV (Delta-based)**: purely additive — no existing schema/standard edited.
- **Article VIII (Infra)**: §VIII.1 (Envoy/Connect) + §VIII.2 (Temporal) consumed
  as-is; the `saga-orchestration` phase materialises §VIII.2's "no ad-hoc saga
  implementations in application code".
- **Article V (Compliance gate)**: each open question maps to a design-phase ADR;
  no work proceeds around an unresolved question.
- **Article XII (Governance)**: no amendment.

## Open Questions (seed)

- **Q-001** — phases inline-materialised vs `extends: tdd-rust` (→ ADR-B6-1-001;
  leaning inline).
- **Q-002** — candidate→stable/scaffoldable promotion trigger + which B.6 brick
  owns the flip (→ ADR-B6-1-002; leaning B.6.7 harness).
- **Q-003** — component reference-only + deferred-standard gap handling
  (→ ADR-B6-1-003; leaning reference-only).
- **Q-004** — layer modelling for a backend-centric archetype + frontend surface
  (→ ADR-B6-1-004).
