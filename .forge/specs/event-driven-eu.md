# Spec: event-driven-eu

<!-- Audit: B.6.1 (b6-1-schema) — event-driven-eu/1.0.0 archetype scaffold schema. -->
<!-- This file accumulates the archived requirements for the event-driven-eu     -->
<!-- archetype (plan §6.1, T7). Source change: `.forge/changes/b6-1-schema/`      -->
<!-- (archived 2026-07-10). First brick of the B.6 chain; B.6.2 (scaffolder),     -->
<!-- B.6.3 (standards), B.6.4 (Hermes-Async), etc. APPEND to this file as they    -->
<!-- archive.                                                                     -->

**Namespace** : `FR-B6-1-*` / `NFR-B6-1-*` / `ADR-B6-1-*` (+ `FR-B6-2-*` from B.6.2,
`FR-B6-CI-*` from B.6.5).

**Constitution** : v2.0.0 (no bump — additive; consumes §VIII.1 Envoy/Connect +
§VIII.2 Temporal as-is; the `saga-orchestration` phase materialises §VIII.2's "no
ad-hoc saga implementations in application code").

**Position** : T7, first of the B.6 incremental chain (sibling of the B.7
`ai-native-rag` chain). Ships the `event-driven-eu / 1.0.0` **candidate** archetype
scaffold schema — the shared contract every downstream B.6 brick validates against.

## B.6.1 — archetype scaffold schema (archived 2026-07-10)

The schema `.forge/schemas/event-driven-eu/1.0.0.yaml` MUST:

- Use the archetype-scaffold-schema shape (FR-B6-1-001): `name`/`version`/`stage`/
  `scaffoldable`/`description`/`tdd_enforced`/`bdd_required_for_user_facing`/
  `coverage_threshold`/`layers`/`fr_id_prefix_cross_layer`/`cross_layer`/`phases`.
- Declare `name: event-driven-eu`, `version: "1.0.0"`, `stage: candidate`,
  `scaffoldable: false` (FR-B6-1-002/003; b8-3b candidate⇒scaffoldable:false).
- Carry `tdd_enforced: true`, `bdd_required_for_user_facing: true`,
  `coverage_threshold: 80` (FR-B6-1-004) + a candidate header block documenting the
  promotion trigger (B.6.7) + additivity (FR-B6-1-005).
- Declare the backend/frontend/infra layer triple, each with
  id/path/fr_id_prefix/primary_agent (FR-B6-1-010; the frontend hosts a **deferred**
  ops-console surface — ADR-B6-1-004, the archetype is backend-centric).
- Inline the tdd-rust phases (NOT via `extends`; ADR-B6-1-001) + the two B.6.1
  additions: `event-design` (AsyncAPI 3.1 contracts before design, FR-B6-1-022) and
  `saga-orchestration` (Temporal saga design gate, FR-B6-1-023, VIII.2).
- Carry an `event_specifics` block (event_versioning / idempotency_keys /
  saga_compensation / outbox_inbox_pattern / eu_sovereignty; FR-B6-1-024).
- Declare the component SET reference-only (FR-B6-1-030/031): temporal→orchestration.yaml,
  postgres→persistence.yaml, connect-rpc→transport.yaml, zitadel→identity.yaml,
  observability→observability.yaml; and mark `nats-jetstream`/`asyncapi`/`event-patterns`
  `delivered_by: B.6.3` with no inline pin (FR-B6-1-032, ADR-B6-1-003).

**ADRs**: ADR-B6-1-001 (phases inlined) · ADR-B6-1-002 (candidate; promotion→B.6.7)
· ADR-B6-1-003 (components reference-only; nats/event/asyncapi deferred to B.6.3) ·
ADR-B6-1-004 (backend/frontend/infra triple; frontend = deferred ops surface).

**Verification (archived state)**: `b6-1.test.sh` 18/18 L1 GREEN;
`validate-foundations.sh` → `FR-GL-001-versioned:event-driven-eu/1.0.0.yaml` PASS;
`verify.sh` + `constitution-linter.sh` no regression;
`forge init --archetype event-driven-eu` refuses cleanly (exit 2 pre-registration;
exit 3 once B.6.2 registers it while the schema stays candidate).

## B.6.2 — scaffolder backbone (archived 2026-07-10)

Ships `.forge/templates/archetypes/event-driven-eu/1.0.0/` (backend + infra +
shared) + `scaffold-plan.yaml` + the gated `bin/forge-init-event-driven-eu.sh`
wrapper + the `dispatch-table.yml` registration (`status: candidate`, `since: 0.6.0`).

- **Backend** (Rust workspace, FR-B6-2-010..014): `events` (NATS JetStream —
  versioned/idempotent `EventEnvelope`, `EventPublisher` port + `JetStreamPublisher`
  dedup via `Nats-Msg-Id`, `InboxDedup`), `eventstore` (append-only Postgres
  `PgEventStore` + `InMemoryEventStore` + `Projection`), `saga` (Temporal
  activity-only: `Activity` marker traits + `Saga`/`SagaStep` compensation
  coordinator; native SDK behind OFF-by-default `temporal-sdk` feature),
  `bin-server` (axum entrypoint + DI). Verify-then-pin LIVE (FR-B6-2-040):
  `async-nats 0.49.1`, `sqlx 0.9.0`, `temporalio-sdk 0.5.0`, `temporalio-client
  0.5.0` — pins ONLY in `backend/Cargo.toml` (FR-B6-2-041).
- **Infra** (FR-B6-2-020): dev NATS JetStream config, Postgres event-store schema
  (`init-eventstore.sql`), optional local-dev Temporal overlay,
  `docker-compose.dev.yml` (NATS + Postgres).
- **Event contracts/transport** (FR-B6-2-030/031): AsyncAPI **3.1.0** contract
  (`shared/asyncapi/`, validated against the official schema) + `shared/protos/`
  (buf SSoT; Connect consumed by reference).
- **CLI** (FR-B6-2-050..052): `forge init --archetype event-driven-eu` refuses
  exit 3 + writes nothing (schema stays candidate; promotion → B.6.7).

**ADRs**: ADR-B6-2-001 (promotion→B.6.7) · ADR-B6-2-002 (Connect by reference) ·
ADR-B6-2-003 (no frontend first cut) · ADR-B6-2-004 (Temporal activity-only +
feature-gated) · ADR-B6-2-005 (pins only in Cargo.toml).

**Verification (archived state)**: rendered `cargo test --workspace` 16/0 +
`clippy -D warnings` + `fmt --check` clean; `b6-2.test.sh` L1 10/10, L1,2 13/13
(render-clean + rendered cargo check + gated wrapper render); built CLI
`forge init --archetype event-driven-eu` → exit 3, no scaffold dir; `cd cli &&
npm test` 88/89 (the 1 failure is the pre-existing ai-native-rag scaffold fixture,
B.7 scope, reproduced on the b6-2-reverted baseline).

## B.6.4 — Hermes-Async event-driven messenger agent (archived 2026-07-10)

<!-- Namespace: FR-B6-HA-* / NFR-B6-HA-* / ADR-K1-* ; rule namespace K1-RULE-*. -->

Source change: `.forge/changes/b6-4-hermes-async/`. Adds the K.1 specialist agent
(`docs/new-archetypes-plan.md` §9 line 2668 + §6.1 line 2556 ; ARCHITECTURE-TARGET
§9.2 line 731). Advisory specialist in the b7-pythia (Sibyl) mould — **no scanner, no
data file, no new standard** (consumes the B.6.3 standards by reference).

- **K.1.a — persona** (`.claude/agents/hermes-async.md`, FR-B6-HA-001..027 / 120..125):
  H1 `# Agent: Event-Driven Messenger (Hermes-Async)` + `K.1` / `B.6.4` audit
  comments ; `## Persona` (contract-first, idempotency-mandatory ; disambiguated from
  **Hermes** (Flutter perf) + **Hermes-API** (Connect codegen)) ; `## Purpose` (four
  responsibilities cited from K.1 + B.6.4 + the 3 B.6.3 standards ; `event-driven-eu`-
  scoped) ; `## Checklists` with four H3 (**AsyncAPI Contract Maintenance** /
  **NATS/Kafka Binding Generation** / **Idempotency-Key Enforcement** / **Event
  Versioning & Compatibility**, ≥ 5 `[ ]` items each), grounded in the real b6-2
  code shapes (`EventEnvelope`, `Nats-Msg-Id` publish dedup, `InboxDedup`, `SagaStep`,
  `events.v<version>.<EventType>` subjects) ; `## Output: Event Contract Readiness
  Report` (Summary table + Findings + Cleared Items ; status BLOCKED / NEEDS-REVISION
  / READY) ; `## Recommendation Catalogue` (`K1-RULE-001..006`, advisory ladder
  `Advisory` < `Concern` < `Blocking` ; the single Blocking rule K1-RULE-006 is the
  Article VIII.2 end-to-end idempotency / exactly-once gate) ; `## Integration` (Janus
  routing at the `event-design` / `saga-orchestration` phase gates ; Hermes-API vs
  Hermes-Async transport disjointness ; Vulcan implements / Atlas provisions) ;
  `## Anti-Hallucination Protocol` (III.4 + CLAUDE.md rule-6 LIVE verification via
  Context7 for AsyncAPI/NATS/Temporal API details) ; audit footer.
- **K.1.b — registration** (FR-B6-HA-080..081): one additive row in the repo
  `CLAUDE.md` agent-delegation table (`| Event-driven / AsyncAPI | **Hermes-Async** |
  Event-Driven Messenger |`) + one in `docs/GUIDE.md` "Agents Transversaux".
- **K.1.c — harness** (`.forge/scripts/tests/b6-4.test.sh`): 18 L1 + 1 L2
  anchor-integrity fixture (grep-only, no cargo/no network), registered in
  `forge-ci.yml` after `b6-2.test.sh`.

**ADRs**: ADR-K1-001 (keep roadmap name "Hermes-Async" ; no collision — distinct from
Hermes / Hermes-API) · ADR-K1-002 (`K1-RULE-*` incremental, 6 seed rules, mirroring
b7-pythia ADR-K2-002) · ADR-K1-003 (advisory agent, NO scanner ; edits no Janus file
and no standards index — task-scoped divergence from b7-pythia).

**Verification (archived state)**: `b6-4.test.sh --level 1,2` 19/19 GREEN ≤ 5 s ;
`verify.sh` + `constitution-linter.sh` no regression ; sibling harnesses (`b6-1`,
`b6-2`, `b7-pythia`, `k3`, `k5`) unchanged. Q-001 (Hermes-* name-adjacency) + Q-002
(rule seed size) + Q-003 (advisory vs scanner) all NON-BLOCKING, answered via
ADR-K1-001..003.

## B.6.5 — per-layer CI templates (archived 2026-07-10)

Ships three GitHub Actions workflow templates under
`.forge/templates/archetypes/event-driven-eu/1.0.0/.github/workflows/`, scaffolded
into an adopter's `.github/workflows/` and registered in `scaffold-plan.yaml`
(`substitute: true`; FR-B6-CI-050). Mirrors the `full-stack-monorepo` per-layer
convention, adapted to the event-driven layer decomposition.

- **`forge-events.yml`** (FR-B6-CI-010): gates the `events` + `eventstore` crates.
  `dorny/paths-filter@v3` on `backend/events/**` / `backend/eventstore/**` /
  `backend/Cargo.*` / `shared/protos/**` → `task backend:lint` (workspace clippy
  `-D warnings` + `fmt --check`) → crate-scoped `cargo build/test -p events -p
  eventstore` → Forge gates.
- **`forge-workflows.yml`** (FR-B6-CI-020/021): gates the `saga` crate. Blocking
  job runs `task backend:lint` + `cargo build/test -p saga` with **default
  features** (the pre-alpha `temporal-sdk` stays OFF). A separate
  `saga-temporal-sdk` job runs `cargo test -p saga --features temporal-sdk` ONLY
  on `workflow_dispatch` — clearly NON-BLOCKING, no `continue-on-error`
  (ADR-B6-CI-002; honours ADR-B6-2-004 + §VIII.2).
- **`forge-infra.yml`** (FR-B6-CI-030/031/032): NATS JetStream config lint
  (`nats-server -c infra/nats/jetstream.conf -t`), AsyncAPI 3.1 validation
  (`task asyncapi:validate` → official schema), Postgres migration check
  (`init-eventstore.sql` applied twice against `postgres:17-alpine` — validity +
  idempotency) → Forge gates.
- **Cross-cutting** (FR-B6-CI-002/040/041, NFR-B6-CI-003): each workflow has
  `concurrency` + `permissions: contents: read`, ends in `verify.sh` →
  `constitution-linter.sh`, uses no `continue-on-error`/`if: always()`, and pins
  all actions + the archetype's `nats:2.10-alpine` / `postgres:17-alpine` images.

**ADRs**: ADR-B6-CI-001 (crate-scoped tests + workspace lint) · ADR-B6-CI-002
(non-blocking temporal-sdk via `workflow_dispatch`) · ADR-B6-CI-003 (Postgres
migration applied twice) · ADR-B6-CI-004 (no `forge-integration` analogue this cut).

**Verification (archived state)**: `b6-5.test.sh` L1 9/9, L1,2 10/10 (render-clean
via `overlay.sh`, valid YAML); `b6-2.test.sh` L1,2 13/13 (plan↔tree coverage stays
green after the three new `.tmpl` entries); `b6-1.test.sh` 19/19; `verify.sh`
518/0 PASS; `constitution-linter.sh` OVERALL PASS. Additive — the schema stays
candidate/`scaffoldable:false` (promotion → B.6.7).

## B.6.9 — compliance hooks (NIS2 + DORA) (archived 2026-07-10)

<!-- Source change: `.forge/changes/b6-9-compliance/` — namespace FR-B69-* / NFR-B69-* / ADR-B69-*. -->

Ships the regulatory layer for the `event-driven-eu` archetype (profile "NIS2 +
DORA (si finance) + CRA", `ARCHITECTURE-TARGET.md` §10.3), the B.6 sibling of the
B.7.5/B.7.8 AI-Act work. Every regulatory specific is **grounded-or-deferred**
(Article III.4; the `b6-9.test.sh::_test_b69_030` negative-grep is the backstop).

- **NIS2 artefacts** (`.forge/compliance/nis2/`, FR-B69-NIS2-001..030):
  `incident-reporting.md` (the significant-incident obligation citing the grounded
  **24h/72h** reporting windows verbatim — §10.4 + §7.1 — and the "< 24h" charter
  figure — §9.2 — scoped to the NATS JetStream / Temporal / Postgres event-store
  operational surface, mapped to the I.6 audit-ledger + IX.4 Rust OTel evidence
  surfaces); `incident-report.template.yaml` (adopter-fillable 24h/72h notification
  skeleton); `obligations-index.yaml` (`regulation: nis2` — `incident-reporting` +
  `supply-chain-security` satisfied, ungrounded pillars `needs-clarification` /
  `themis_owner: K.5`). Audit anchor `B.6.9 (b6-9-compliance)` on every member.
- **DORA RoI submission helper** (`.forge/scripts/compliance/dora-roi-helper.sh`,
  FR-B69-DORA-001..020): drives (reads, never forks) the b7-5
  `dora/roi-register.template.yaml` base and specialises it for the archetype's
  ICT third-party stack (NATS JetStream / Temporal / Postgres), citing the
  grounded "30 avr 2026" ESA deadline; the authoritative ESA field schema is a
  `[NEEDS CLARIFICATION]` (Themis K.5).
- **SBOM CycloneDX auto-generation wiring** (FR-B69-SBOM-001..010): grounded that
  event-driven-eu (Rust) SBOM rides the existing `bin/forge-sbom.sh`
  (`Cargo.lock` → CycloneDX 1.5) + the I.6 bundle `sbom/sbom.cdx.json` member — no
  new generator; mapped as the NIS2 supply-chain-transparency evidence surface.
- **Bundle wiring** (FR-B69-BD-001..015): `bundle.sh` walk tuple gains `"nis2"`
  (additive `regulatory/nis2/*`; graceful absence preserved); the I.6 bundle
  contract `global/compliance-artefacts-bundle.md` bumped **1.1.0 → 1.2.0** (NIS2
  reserved → shipped, CRA still reserved). `forge-compliance.yml` unchanged.
- **Standard** `global/nis2-dora-eda-artefacts.md` v1.0.0 (6 H2 + 5 MUST NOT +
  Phase A/B BDFL→Themis governance) + `index.yml` + `REVIEW.md` (birth + I.6
  1.1.0→1.2.0 amendment). New harness `b6-9.test.sh` (17 L1 + 3 L2), registered in
  `forge-ci.yml` after `b7-5.test.sh` (compliance family).

**ADRs**: ADR-B69-001 (create `nis2/`; `cra/` reserved) · ADR-B69-002 (wire nis2
into the bundle; 1.1.0→1.2.0 lock-step) · ADR-B69-003 (new standard) · ADR-B69-004
(DORA helper is a script driving the b7-5 base, not a `dora/` file) · ADR-B69-005
(harness after `b7-5.test.sh`) · ADR-B69-006 (`b7-5.test.sh` `nis2/`-reserved
assertion dropped in lock-step; cra kept) · ADR-B69-007 (no `forge-compliance.yml`
step).

**Lock-step amendments** (shared-reservation discipline): `b7-5.test.sh` dropped
its `_test_b75_001` `nis2/`-reserved assertion and relaxed its `_test_b75_051`
I.6-version pin to semver-validity (Option B precedent); `i6.test.sh::_test_i6_021`
frontmatter pins updated to 1.2.0 / 2026-07-10; `ai-act-dora-artefacts.md` +
`docs/COMPLIANCE.md` stale "NIS2 reserved" prose corrected (NIS2 shipped, CRA
reserved).

**Verification (archived state)**: `b6-9.test.sh --level 1,2` 20/20 GREEN;
`b7-5.test.sh --level 1,2` 19/19 GREEN (lock-step, no regression); `i6.test.sh
--level 1,2` 16/16 GREEN; `verify.sh` 514 PASS / 0 FAIL / 1 WARN (pre-existing) →
RESULT PASS; `constitution-linter.sh` OVERALL PASS (0 FAIL); `validate-standards-yaml.sh`
STD-PASS (new standard is MD, out of J.7 scope); `forge-ci.yml` 375 lines (< 400).
