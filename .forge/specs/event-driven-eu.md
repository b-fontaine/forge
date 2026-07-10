# Spec: event-driven-eu

<!-- Audit: B.6.1 (b6-1-schema) — event-driven-eu/1.0.0 archetype scaffold schema. -->
<!-- This file accumulates the archived requirements for the event-driven-eu     -->
<!-- archetype (plan §6.1, T7). Source change: `.forge/changes/b6-1-schema/`      -->
<!-- (archived 2026-07-10). First brick of the B.6 chain; B.6.2 (scaffolder),     -->
<!-- B.6.3 (standards), B.6.4 (Hermes-Async), etc. APPEND to this file as they    -->
<!-- archive.                                                                     -->

**Namespace** : `FR-B6-1-*` / `NFR-B6-1-*` / `ADR-B6-1-*` (+ `FR-B6-2-*` from B.6.2).

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
