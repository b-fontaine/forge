# Proposal: b6-6-helm

<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: B.6.6 (docs/new-archetypes-plan.md §6.1 — "Templates Helm Temporal cluster (history/matching/frontend/worker) avec Postgres backing. Documentation T2/T3 (self-host EU).") -->

## Problem

The already-merged B.6.2 scaffolder gave the `event-driven-eu` archetype only a
**local-dev** infra backbone: a single-node `docker-compose.dev.yml` (NATS +
Postgres), a minimal single-node `infra/nats/jetstream.conf`, and an OPTIONAL
local-dev Temporal overlay (`infra/temporal/docker-compose.temporal.yml`, the
`temporalio/auto-setup` all-in-one dev server with an ephemeral SQLite store).
Every one of those files explicitly forward-references B.6.6:

- `infra/nats/jetstream.conf.tmpl`: *"The PRODUCTION clustered config (3-node
  RAFT, persistence tuning, consumer groups) is `infra/nats-jetstream.md` (B.6.3)
  + the Helm chart (B.6.6) — NOT this file."*
- `infra/temporal/docker-compose.temporal.yml.tmpl`: *"The PRODUCTION Temporal
  cluster (history/matching/frontend/worker + Postgres backing, Helm) is B.6.6 —
  NOT this overlay."*
- `infra/README.md.tmpl` / `infra/CLAUDE.md.tmpl`: *"Production topology
  (clustered NATS JetStream, Temporal history/matching/frontend/worker, Postgres
  backing) ships as Helm charts in B.6.6 — not in this backbone."*

There is today **no** production Kubernetes deployment artifact for either the
Temporal cluster or a clustered NATS JetStream. An adopter who runs `task
dev:up` locally has nothing to deploy to an EU K8s cluster.

## Proposed Solution

Ship the **production Kubernetes Helm charts** B.6.6 promises, authored under
`.forge/templates/archetypes/event-driven-eu/1.0.0/infra/k8s/`:

1. **`infra/k8s/temporal-cluster/`** — a Forge Helm **values overlay**
   (`values-forge.yaml.tmpl`) + install/ops doc (`README.md.tmpl`) for the
   upstream **`temporalio` Helm chart** (`temporal/temporal`), deploying the four
   Temporal server roles (**history / matching / frontend / worker**) with a
   **Postgres-backed** persistence + visibility store (no bundled Cassandra).

2. **`infra/k8s/nats-jetstream/`** — a Forge Helm values overlay
   (`values-forge.yaml.tmpl`) + doc (`README.md.tmpl`) for the upstream
   **`nats` Helm chart** (`nats/nats`), deploying a **3-node clustered** NATS
   with **JetStream** enabled (RAFT quorum, file-store **persistent volume
   claims**), and documenting **durable-consumer / queue-group** provisioning.

3. **T2 / T3 self-host EU compliance documentation** — a per-chart posture
   section + an `infra/k8s/README.md.tmpl` index, following the exact pattern the
   B.8.7 Zitadel brick used (a "Compliance posture — T1 / T2 / T3" table citing
   `.forge/standards/global/compliance-tiers.md`).

### Delivery model — chart-referenced hybrid (Zitadel/Envoy precedent)

This repo does **not** vendor self-authored Helm charts (`Chart.yaml` /
`templates/*.yaml` / `values.yaml`). The single existing production-service
precedent — B.8.7 Zitadel (`full-stack-monorepo/2.0.0/infra/zitadel/`) — installs
the service from the **upstream** chart and vendors only a Forge **values
overlay** + docs ("no raw K8s manifests, no `kustomization.yaml.tmpl`"). B.8.4
Envoy Gateway uses the same "control plane via the upstream OCI Helm chart
(Atlas-provided install)" split. Temporal and NATS are exactly this shape:
operator-grade upstream charts (StatefulSets, schema-setup Jobs, RAFT) that would
require large re-implementation if vendored as raw manifests. **B.6.6 therefore
follows the Zitadel chart-referenced-hybrid convention.** The `values-forge.yaml`
IS the deliverable "Helm chart" content in this repo's convention.

### Verify-then-pin (LIVE, Article III.4)

The upstream chart + appVersion pins are resolved LIVE at implement (not
fabricated, not from training data):

| Chart | Repo | Chart version | appVersion (server) |
|-------|------|---------------|---------------------|
| `temporal/temporal` | `https://go.temporal.io/helm-charts` | `1.5.0` | `1.31.1` |
| `nats/nats` | `https://nats-io.github.io/k8s/helm/charts/` | `2.14.2` | `2.14.2` |

Both overlays were `helm template`-rendered LIVE against these charts at implement
(design.md § Validation): Temporal renders all four server Deployments +
schema-setup Job with Postgres datastores; NATS renders a 3-replica StatefulSet
with a JetStream file-store PVC.

## Out of Scope

- **Re-pinning the `temporalio-sdk` Rust crate.** `backend/Cargo.toml.tmpl`
  already pins `temporalio-sdk = "0.5.0"` / `temporalio-client = "0.5.0"` (the
  **client** SDK the `saga` crate uses). That is orthogonal to the Temporal
  **server** cluster version (Helm chart `1.5.0` / server `1.31.1`). B.6.6 MUST
  NOT re-pin or contradict the Cargo pin.
- **The `infra/nats-jetstream.md` standard** (B.6.3, a parallel lane) — B.6.6
  authors charts *consistent with* clustering/RAFT/persistence but does not
  depend on B.6.3's content and does not author the standard.
- **Promotion / snapshot tarball / `b6.test.sh` (≥ 35 tests)** — that is B.6.7.
  The archetype schema stays `candidate` / `scaffoldable: false`.
- **Migrations / secret values** — the DB password and TLS secrets are K8s
  Secrets created at deploy time; no secret value is committed (Zitadel posture).

## Constitution Compliance

- **Article I (TDD)**: `.forge/scripts/tests/b6-6.test.sh` is committed RED-first,
  before any template exists.
- **Article III.1/III.2 (Specs before code)**: this proposal → specs → design →
  tasks precede the templates.
- **Article III.4 (Anti-Hallucination)**: chart/app versions are verify-then-pin
  LIVE; every values key is taken from the actual `helm show values` output and
  the overlays are `helm template`-validated (no fabricated keys — the removed
  top-level `cassandra:` key and the removed `server.config.persistence.default`
  path were caught LIVE and avoided).
- **Article IV (Delta-based)**: additive — the B.6.2 dev backbone
  (`docker-compose.dev.yml`, `infra/nats/`, `infra/temporal/`, `infra/postgres/`)
  is byte-untouched; only NEW paths under `infra/k8s/` are added (plus the
  scaffold-plan coverage rows and CI harness registration).
- **Article VIII.2 (Temporal)**: the production Temporal cluster realizes the
  §VIII.2 orchestration mandate for the `event-driven-eu` archetype.
- **Article VIII.3 / VIII.5 (containerization / IaC)**: the charts are
  version-controlled infra; distroless/runtime posture is the upstream chart's.
- EU sovereignty (`event_specifics.eu_sovereignty`): NATS JetStream (CNCF, EU
  self-hostable) — no Kafka SaaS US; consistent with B.6.10.
