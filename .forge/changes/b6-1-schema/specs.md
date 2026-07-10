# Specifications: b6-1-schema

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.6.1 (docs/new-archetypes-plan.md §6.1 — event-driven-eu/1.0.0 archetype scaffold schema) -->

**Namespace** : `FR-B6-1-*` / `NFR-B6-1-*` / `ADR-B6-1-*`.
**Constitution** : v2.0.0, unchanged. This change authors the requirements + ADRs
for the `event-driven-eu / 1.0.0` **candidate** archetype scaffold schema. It ships
**no scaffolder, no template, no version pin, and edits no existing
schema/standard**. The schema file + harness are built at the impl phase (after
design); scaffolder + standards arrive in B.6.2 / B.6.3.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-Hallucination),
IV (delta-based / additive), VII (Rust hexagonal), VIII.1 (Envoy/Connect) + VIII.2
(Temporal — no ad-hoc saga), X.1 (80% coverage).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §6.1 B.6.1 (`event-driven-eu/1.0.0.yaml`, extends `tdd-rust` + phases `event-design`/`saga-orchestration`, effort S), §11 (T7) |
| **Sibling precedent** | `.forge/changes/b7-1-schema/` (ai-native-rag/1.0.0 candidate schema — the shape + rigor this change mirrors) |
| **Two schema families (observed)** | *workflow* schemas (`tdd-rust/schema.yaml`: `extends: default` + phases, no layers) vs *archetype scaffold* schemas (`ai-native-rag/1.0.0.yaml`, `full-stack-monorepo/2.0.0.yaml`: layers/components/phases). §6.1 conflates them (→ ADR-B6-1-001). |
| **`extends` resolution (observed gap)** | No scaffold-schema loader resolves `extends`: `parseSchemaMeta` (schema-version.ts) reads version/stage/scaffoldable only; `check_versioned_schema_siblings` reads layers/phases from the file itself. ⇒ phases MUST be inlined. |
| **Versioned validator (observed)** | `validate-foundations.sh check_versioned_schema_siblings` (B.8.3.b) — generic over all archetype dirs; enforces name==dir, version==filename+SemVer, layers ⊇ {backend,frontend,infra} (each id/path/fr_id_prefix/primary_agent), stage∈{draft,candidate,stable}, candidate⇒scaffoldable:false, phases non-empty. **Gates this file on landing.** |
| **CLI selection (observed)** | `selectScaffoldableVersion` picks highest stable+scaffoldable; candidate/scaffoldable:false ⇒ null. `init.ts` checks the dispatch-table FIRST ⇒ unregistered archetype refuses exit 2; exit 3 (null) is the gate once B.6.2 registers it (mirrors B.7.1 Q-005 / B.7.2a). |
| **Component standards (observed)** | EXIST: `orchestration.yaml` v1.2.0 (default_by_language.rust: temporal), `persistence.yaml` (postgres-17), `transport.yaml` v1.3.0 (connect-rpc; derived_outputs incl. asyncapi-3.1), `identity.yaml` (zitadel), `observability.yaml` (SigNoz/OBI/Coroot). ABSENT: `nats-jetstream` / `event-driven` / `asyncapi-contracts` → B.6.3 (gap, ADR-B6-1-003). |
| **tdd-rust phases (observed)** | `tdd-rust/schema.yaml`: proposal→specs(Clio)→features(Centurion, gate scenarios_cover_all_fr)→design(Ferris)→tasks(tdd_order_enforced)→implementation(Vulcan; team Centurion/Ferris/Sentinel)→review(Tribune/Aegis)→archive; `rust_specifics`{architecture: hexagonal, async_runtime: tokio, grpc: tonic+prost, error_handling: thiserror+anyhow}. |
| **Temporal caveat (observed)** | `orchestration.yaml` + `infra/temporal.md`: `temporalio-sdk` is Public Preview / pre-alpha ("API will continue to evolve"); prefer **activity-only** workers; pin exactly + verify-then-pin LIVE at scaffold time (NOT in this schema). |
| **Downstream gated by this** | B.6.2 (`b6-2-scaffolder`), B.6.3 (standards), B.6.4 (Hermes-Async), B.6.5..B.6.10 |
| **Release target** | maintainer-set |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Schema identity & shape (FR-B6-1-001 → 005)

##### FR-B6-1-001 — archetype-scaffold-schema shape (not a workflow schema)
The file, when authored, MUST use the archetype scaffold schema top-level key set
(parity with `ai-native-rag/1.0.0.yaml`): `name`, `version`, `stage`,
`scaffoldable`, `description`, `tdd_enforced`, `bdd_required_for_user_facing`,
`coverage_threshold`, `layers`, `fr_id_prefix_cross_layer`, `cross_layer`,
`phases`. It MUST NOT be a bare workflow schema (no layers).

##### FR-B6-1-002 — identity fields + filename↔version invariant
MUST declare `name: event-driven-eu`, `version: "1.0.0"`, `stage: candidate`. The
file MUST be `.forge/schemas/event-driven-eu/1.0.0.yaml` so the b8-3b
filename↔version invariant holds.

##### FR-B6-1-003 — non-scaffoldable candidate
MUST declare `scaffoldable: false` (b8-3b enforces candidate⇒scaffoldable:false).
Consequence (NFR-B6-1-002): `forge init --archetype event-driven-eu` refuses
cleanly, never a broken scaffold — exit 2 today (unknown archetype), exit 3 once
B.6.2 registers it while the schema stays candidate.

##### FR-B6-1-004 — TDD/BDD/coverage flags
MUST carry `tdd_enforced: true`, `bdd_required_for_user_facing: true`,
`coverage_threshold: 80` (Articles I, II, X.1 not relaxed).

##### FR-B6-1-005 — candidate header block
MUST carry a header comment block stating, for THIS file: what `candidate` means
while no templates exist (not scaffoldable), the promotion trigger to `stable` +
`scaffoldable: true` (the B.6.7 harness brick, mirroring B.7.6/B.8.14 —
ADR-B6-1-002), and that it is additive (no existing archetype affected).

#### Cluster 2 — Layers & event-driven topology (FR-B6-1-010 → 013)

##### FR-B6-1-010 — minimum layer triple
`layers` MUST be a non-empty list including `backend`, `frontend`, `infra`, each
with `id`/`path`/`fr_id_prefix`/`primary_agent` (b8-3b validator contract).

##### FR-B6-1-011 — event-driven layer roles
The layers MUST model the event-driven topology: backend = Rust (NATS JetStream
producers/consumers + Postgres event store + Temporal saga activities;
`primary_agent: Vulcan`); frontend = ops surface (`primary_agent: Hera`); infra =
NATS JetStream cluster / Temporal / Postgres event store / observability
(`primary_agent: Atlas`).

##### FR-B6-1-012 — frontend surface (deferred/optional)
Because this archetype is backend-centric, the `frontend` layer MAY carry a single
deferred/optional ops-console surface (modelled under `frontend.surfaces`,
mirroring `ai-native-rag`'s web-public shape). No frontend scaffold is required by
this archetype's first cut; the surface entry documents it as deferred (ADR-B6-1-004).

##### FR-B6-1-013 — cross-layer routing parity
MUST declare `fr_id_prefix_cross_layer: FR-GL-` and a `cross_layer` block routing
≥2-layer changes to Janus (parity with the flagship + ai-native-rag schema).

#### Cluster 3 — Phases & event-driven process (FR-B6-1-020 → 024)

##### FR-B6-1-020 — phases inlined, not inherited
`phases` MUST be a non-empty list authored **inline**. The schema MUST NOT rely on
`extends: tdd-rust` to supply phases. An `extends: tdd-rust` key MAY be retained as
documentary provenance only (ADR-B6-1-001).

##### FR-B6-1-021 — tdd-rust phases materialised
The inlined phases MUST materialise the `tdd-rust/schema.yaml` flow: proposal →
specs → features → design → tasks → implementation → review → archive.

##### FR-B6-1-022 — `event-design` phase (B.6.1 addition)
MUST add an `event-design` phase (per §6.1) that requires AsyncAPI 3.1 event
contracts to be specified **before** the design phase (placed after `specs`).

##### FR-B6-1-023 — `saga-orchestration` phase/gate (B.6.1 addition)
MUST add a `saga-orchestration` phase (per §6.1) gating the Temporal saga/workflow
design review (placed after `design`) — wiring Article VIII.2 (no ad-hoc saga
implementations; Temporal for multi-step workflows).

##### FR-B6-1-024 — event_specifics carried
MUST carry an `event_specifics` block: `event_versioning` (required),
`idempotency_keys` (required), `saga_compensation` (required),
`outbox_inbox_pattern` (recommended), and an `eu_sovereignty` note (no Kafka-SaaS
US; Redpanda acceptable — the enforcement list itself is B.6.10, referenced not
built here).

#### Cluster 4 — Component set (reference-only) (FR-B6-1-030 → 032)

##### FR-B6-1-030 — declare the component SET by name
MUST declare the components by name + role: NATS JetStream (event backbone),
Temporal (orchestration/saga), Postgres (event store), Connect-RPC (transport),
AsyncAPI (event contracts), Zitadel (identity), SigNoz/OBI/Coroot (observability).

##### FR-B6-1-031 — reference source standards, no inline pins
For each component with an existing standard the schema MUST reference it (no
inline pin, ADR-B8-3-002 precedent): temporal→`orchestration.yaml`,
postgres→`persistence.yaml`, connect-rpc→`transport.yaml`, zitadel→`identity.yaml`,
observability→`observability.yaml`.

##### FR-B6-1-032 — deferred-standard gap recorded, not fabricated
For NATS JetStream / event-driven patterns / AsyncAPI contracts (no standard
today) the schema MUST reference them as `delivered_by: B.6.3` with **no** inline
version pin and **no** fabricated standard filename presented as existing (Article
III.4). The verify-then-pin candidates (`async-nats`, `temporalio-sdk`, `sqlx`)
MUST NOT be pinned in this schema.

### Non-Functional Requirements

##### NFR-B6-1-001 — additive only / zero edit to existing surfaces
The change MUST NOT modify any existing schema, standard, the constitution, the
CLI, or any template. `git diff --name-only` MUST show only new files under
`.forge/changes/b6-1-schema/` (+ the schema file + its harness + the CI-matrix
line at impl phase).

##### NFR-B6-1-002 — clean non-scaffoldable behaviour (no broken init)
After the schema lands, `forge init --archetype event-driven-eu` MUST refuse
cleanly and emit no partial scaffold. Today the refusal is exit 2 (unknown
archetype); it shifts to exit 3 (`selectScaffoldableVersion` null) once B.6.2
registers the archetype while keeping the schema candidate/scaffoldable:false. No
other archetype's init behaviour changes.

##### NFR-B6-1-003 — validators stay GREEN on landing
After the schema file lands (impl phase), `validate-foundations.sh`
(`check_versioned_schema_siblings`) MUST emit
`FR-GL-001-versioned:event-driven-eu/1.0.0.yaml` PASS, and `verify.sh` +
`constitution-linter.sh` MUST stay GREEN (no regression). The schema MUST satisfy
every b8-3b invariant the moment it is committed.

##### NFR-B6-1-004 — dedicated harness
The impl phase MUST add `.forge/scripts/tests/b6-1.test.sh` asserting the
event-specific content not covered by the generic validator: the inlined tdd-rust
phases incl. `event-design`/`saga-orchestration`, the `event_specifics` block, the
reference-only component set, and the deferred-standard gap. Registered in
`forge-ci.yml`. (Authored at impl; specified here.)

---

## ADRs (seeded — resolved at /forge:design)

- **ADR-B6-1-001** — phases inline-materialised (lean) vs `extends: tdd-rust`.
  Grounded: no scaffold-schema loader resolves `extends`. Resolves §6.1 conflation.
- **ADR-B6-1-002** — `candidate` + `scaffoldable: false` (lean); promotion to
  stable deferred to the B.6.7 harness brick (mirrors B.7.6 / B.8.14).
- **ADR-B6-1-003** — components reference-only (lean); nats-jetstream /
  event-driven / asyncapi-contracts referenced as `delivered_by: B.6.3`, gap
  recorded, no fabrication.
- **ADR-B6-1-004** — layer modelling for a backend-centric archetype: the required
  backend/frontend/infra triple with the frontend hosting a deferred ops surface.

## Acceptance Criteria (for the impl phase, summarised)

1. `.forge/schemas/event-driven-eu/1.0.0.yaml` exists; `name`/`version`/`stage`/
   `scaffoldable` = event-driven-eu/1.0.0/candidate/false.
2. `validate-foundations.sh` → `FR-GL-001-versioned:event-driven-eu/1.0.0.yaml` PASS.
3. `forge init <name> --archetype event-driven-eu --org <rd>` → refuses (exit 2
   today; exit 3 once B.6.2 registers it).
4. `layers` ⊇ {backend,frontend,infra}.
5. Inlined phases include `event-design` + `saga-orchestration`; `event_specifics`
   present.
6. Components reference-only; no inline pin; nats/event/asyncapi marked
   `delivered_by: B.6.3`.
7. `b6-1.test.sh` GREEN; `verify.sh` + `constitution-linter.sh` no regression.
8. No existing schema/standard/constitution/CLI/template modified.
