# Specifications: b6-6-helm

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.6.6 (docs/new-archetypes-plan.md §6.1 — production Helm Temporal cluster + Postgres backing, NATS JetStream cluster, T2/T3 self-host EU docs) -->

**Namespace**: `FR-B6-HELM-*` / `NFR-B6-HELM-*` / `ADR-B6-HELM-*`.
**Constitution**: v2.0.0 (unchanged; no amendment). §VIII.2 (Temporal),
§VIII.3/VIII.5 (containerization / IaC), III.4 (Anti-Hallucination), IV (delta).
**Governing convention**: the B.8.7 Zitadel **chart-referenced hybrid** (upstream
chart + Forge `values-forge.yaml` overlay + docs, no vendored raw manifests /
`Chart.yaml`).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §6.1 B.6.6: *"Templates Helm Temporal cluster (history/matching/frontend/worker) avec Postgres backing. Documentation T2/T3 (self-host EU). Effort: M."* |
| **Backbone (observed)** | `event-driven-eu/1.0.0/`: dev `docker-compose.dev.yml.tmpl`, `infra/nats/jetstream.conf.tmpl` (single-node dev), `infra/temporal/docker-compose.temporal.yml.tmpl` (auto-setup dev), `infra/postgres/init-eventstore.sql.tmpl`. All forward-reference B.6.6 for production. |
| **Crate pin (observed, MUST NOT contradict)** | `backend/Cargo.toml.tmpl`: `temporalio-sdk = "0.5.0"`, `temporalio-client = "0.5.0"`, `async-nats = "0.49.1"` — CLIENT libraries, feature-gated OFF (`temporal-sdk`). |
| **Convention precedent** | B.8.7 Zitadel `full-stack-monorepo/2.0.0/infra/zitadel/{values-forge.yaml.tmpl, README.md.tmpl, bootstrap.md.tmpl}` — upstream chart + values overlay + T1/T2/T3 posture table citing `compliance-tiers.md`. B.8.4 Envoy `infra/k8s/envoy-gateway/` — `infra/k8s/<component>/` layout + `README.md.tmpl` Atlas-provided install. |
| **Compliance rows (observed)** | `.forge/standards/global/compliance-tiers.md`: `Temporal Cloud \| ⚠️ T1 \| ✅ self-host T2 \| ✅ self-host EU \| self-host pour T3` and `NATS JetStream \| ✅ \| ✅ \| ✅ \| self-host T2/T3`. |
| **Live pins (verify-then-pin, 2026-07-10)** | `temporal/temporal` chart `1.5.0` / appVersion `1.31.1` (`https://go.temporal.io/helm-charts`); `nats/nats` chart `2.14.2` / appVersion `2.14.2` (`https://nats-io.github.io/k8s/helm/charts/`). |
| **Coupling** | `b6-2.test.sh` T-002 (scaffold-plan ↔ tree bijection) + T-L2-001 (overlay render-clean). New files MUST be registered in `scaffold-plan.yaml`. |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Temporal cluster chart (FR-B6-HELM-001 → 019)

##### FR-B6-HELM-001 — production Temporal chart tree
The brick MUST create
`event-driven-eu/1.0.0/infra/k8s/temporal-cluster/` containing at least a
`values-forge.yaml.tmpl` (Forge Helm values overlay) and a `README.md.tmpl`
(install + ops + compliance doc), following the Zitadel chart-referenced-hybrid
convention (upstream chart + overlay; no vendored `Chart.yaml` / raw manifests).

##### FR-B6-HELM-002 — four server roles deployed
The Temporal values overlay MUST enable and configure the four Temporal server
roles — **frontend**, **history**, **matching**, **worker** — as separately
scalable services (`server.<role>.enabled: true` + a per-role or global
`replicaCount`), consistent with the plan's "history/matching/frontend/worker".

##### FR-B6-HELM-003 — Postgres-backed persistence
The overlay MUST configure a **Postgres**-backed persistence store AND visibility
store via `server.config.persistence.datastores.{default,visibility}.sql`
(`pluginName: postgres12`), with the DB password supplied by a K8s Secret
(`existingSecret`), NOT inlined. It MUST NOT rely on a bundled Cassandra
(the top-level `cassandra:` key was removed in the chart's v1.0.0-rc.2 and MUST
NOT appear), and MUST NOT use the removed `server.config.persistence.default`
path (must use `...persistence.datastores.<name>`).

##### FR-B6-HELM-004 — numHistoryShards fixed + documented
The overlay MUST set `server.config.numHistoryShards` and document (comment) that
it cannot be changed after the initial deployment (upstream constraint).

##### FR-B6-HELM-005 — schema setup wired
The overlay/doc MUST make the Temporal schema-setup step explicit (the chart's
schema Job / `admintools`), so the Postgres databases are created/migrated before
the server pods start.

#### Cluster 2 — NATS JetStream cluster chart (FR-B6-HELM-020 → 039)

##### FR-B6-HELM-020 — production NATS chart tree
The brick MUST create `event-driven-eu/1.0.0/infra/k8s/nats-jetstream/`
containing at least a `values-forge.yaml.tmpl` and a `README.md.tmpl`, same
convention.

##### FR-B6-HELM-021 — clustered with RAFT quorum
The NATS overlay MUST enable clustering (`config.cluster.enabled: true`) with a
**RAFT quorum** replica count ≥ 3 (`config.cluster.replicas: 3`; upstream note:
"must be 2 or higher when jetstream is enabled").

##### FR-B6-HELM-022 — JetStream persistence via PVC
The overlay MUST enable JetStream (`config.jetstream.enabled: true`) with a
**file store** backed by a **persistent volume claim**
(`config.jetstream.fileStore.enabled: true` + `...pvc.enabled: true` + a `size`),
so streams survive pod restarts (RAFT replicated across the 3 nodes).

##### FR-B6-HELM-023 — monitoring endpoint
The overlay MUST enable the NATS monitoring endpoint (`config.monitor.enabled:
true`, port 8222) used for `/healthz` probes (consistent with the dev overlay's
`http_port: 8222`).

##### FR-B6-HELM-024 — durable-consumer / queue-group provisioning documented
The `README.md.tmpl` MUST document durable-consumer + **queue-group** (work-queue)
provisioning (the horizontal consumer-scaling mechanism) and cross-reference the
backend `events` crate consumer, since JetStream consumers are provisioned at
runtime, not as a static chart value (no fabricated chart key).

#### Cluster 3 — Compliance documentation (FR-B6-HELM-040 → 049)

##### FR-B6-HELM-040 — T2 / T3 self-host EU posture per chart
Each chart `README.md.tmpl` MUST carry a **"Compliance posture — T1 / T2 / T3"**
section (Zitadel FR-B87-060 pattern) citing the relevant
`.forge/standards/global/compliance-tiers.md` row (Temporal Cloud / NATS
JetStream) and stating the self-host-EU posture for T2 and T3.

##### FR-B6-HELM-041 — infra/k8s index doc
The brick MUST add an `infra/k8s/README.md.tmpl` index introducing the production
charts dir, distinguishing it from the dev `docker-compose` backbone, and linking
to `docs/COMPLIANCE.md` + each chart's README.

#### Cluster 4 — Registration & coexistence (FR-B6-HELM-050 → 059)

##### FR-B6-HELM-050 — scaffold-plan coverage
Every new `.tmpl` file MUST be registered in
`event-driven-eu/scaffold-plan.yaml`'s `templates:` list (`source`/`target`/
`substitute`), preserving the `b6-2.test.sh` T-002 tree↔plan bijection. Files
using `<project-name>` are `substitute: true`.

##### FR-B6-HELM-051 — dev backbone untouched (additive)
The B.6.2 dev backbone (`docker-compose.dev.yml`, `infra/nats/`,
`infra/temporal/`, `infra/postgres/`, `backend/`) MUST be byte-unchanged except
for accurate forward-reference wording in `infra/README.md.tmpl` /
`infra/CLAUDE.md.tmpl` (now pointing at the shipped `infra/k8s/` charts). The
`backend/Cargo.toml.tmpl` pins MUST be byte-unchanged.

##### FR-B6-HELM-052 — CI harness registration
`.forge/scripts/tests/b6-6.test.sh` MUST be registered in
`.github/workflows/forge-ci.yml` `harnesses=( … )` (after `b6-2.test.sh`).

### Non-Functional Requirements

##### NFR-B6-HELM-001 — verify-then-pin, never fabricated
The chart + appVersion pins MUST be verified LIVE (`helm show chart`) at
implement and the overlays MUST be `helm template`-rendered LIVE (no fabricated
values keys). A pin written from memory is an Article III.4 violation.

##### NFR-B6-HELM-002 — no re-pin of the client SDK
No B.6.6 file may introduce a `temporalio-sdk = "X"` / `temporalio-client = "X"`
/ `async-nats = "X"` crate pin. Those live ONLY in `backend/Cargo.toml.tmpl`
(single source of truth); the charts pin the **server** (chart/appVersion),
which is orthogonal and MUST NOT contradict the crate pin.

##### NFR-B6-HELM-003 — secrets never committed
No DB password, TLS key, or token VALUE may be templated into the repo. The
overlays reference K8s Secrets by NAME only (`existingSecret`, `secretKeyRef`).

##### NFR-B6-HELM-004 — well-formed YAML + render-clean
Each `values-forge.yaml.tmpl`, once `<project-name>` is substituted, MUST be
valid YAML (`yaml.safe_load`) and MUST survive the B.6.2 overlay render
(`b6-2.test.sh` T-L2-001: no surviving `.tmpl`, no unsubstituted
`<project-name|reverse-domain|root-module>`).

##### NFR-B6-HELM-005 — schema stays candidate
The `event-driven-eu/1.0.0` schema MUST stay `candidate` / `scaffoldable:
false`; B.6.6 MUST NOT promote it (promotion is B.6.7).

## Architecture Decision Records (finalized in design.md)

- **ADR-B6-HELM-001** — chart-referenced hybrid (values overlay + docs), not a
  vendored self-authored chart. Zitadel/Envoy precedent; anti re-implementation.
- **ADR-B6-HELM-002** — Postgres (not Cassandra) datastore, via
  `persistence.datastores.{default,visibility}.sql` (chart 1.5.0 shape).
- **ADR-B6-HELM-003** — NATS: 3-node RAFT + JetStream file-store PVC; durable
  consumers/queue-groups are runtime (documented, not a chart key).
- **ADR-B6-HELM-004** — server pin (chart/appVersion) is orthogonal to the
  `temporalio-sdk` client crate pin; no re-pin.

## BDD Acceptance Criteria

```gherkin
Feature: Production Helm charts for the event-driven-eu Temporal + NATS clusters
  As a Forge event-driven-eu adopter
  I want production Kubernetes Helm charts for the Temporal cluster and NATS JetStream
  So that I can self-host the event backbone on an EU K8s cluster (T2/T3), not just run it locally

  Scenario: The production Temporal + NATS charts are shipped additively
    Given the B.6.2 dev backbone (single-node docker-compose NATS/Postgres + optional dev Temporal)
    And backend/Cargo.toml pinning temporalio-sdk = "0.5.0" (the client SDK)
    When the B.6.6 production Helm charts are authored under infra/k8s/
    Then infra/k8s/temporal-cluster/ ships a values overlay deploying frontend/history/matching/worker on a Postgres-backed store
    And infra/k8s/nats-jetstream/ ships a values overlay for a 3-node RAFT cluster with JetStream file-store PVCs
    And both overlays render via `helm template` against the live upstream charts (temporal 1.5.0, nats 2.14.2)
    And each README documents the T1/T2/T3 self-host EU posture citing compliance-tiers.md
    And no B.6.6 file re-pins temporalio-sdk / temporalio-client / async-nats (Cargo.toml stays the single source)
    And the dev backbone and backend/Cargo.toml remain byte-unchanged (additive)
    And every new .tmpl is registered in scaffold-plan.yaml (b6-2 tree↔plan bijection stays GREEN)
```

## Anti-Hallucination Pass

- **Chart shape** — read from the LIVE `helm show values temporal/temporal` and
  `helm show values nats/nats`; the removed top-level `cassandra:` key and the
  removed `server.config.persistence.default` path were caught by LIVE `helm
  template` validation errors and avoided. No values key is invented.
- **Pins** — chart `1.5.0`/`1.31.1` and `2.14.2`/`2.14.2` verified LIVE
  2026-07-10 (`helm show chart`), NOT from training data.
- **temporalio-sdk 0.5.0** — re-read from `backend/Cargo.toml.tmpl`; the charts
  pin the SERVER, never the crate; no re-pin (NFR-B6-HELM-002).
- **Compliance rows** — quoted verbatim from `compliance-tiers.md:151` (Temporal)
  and `:153` (NATS JetStream).
- **Convention** — the "values overlay, no vendored chart" model is read from the
  Zitadel README ("this tree vendors only the Forge values overlay + docs").
