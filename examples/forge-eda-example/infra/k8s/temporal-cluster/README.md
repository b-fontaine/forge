<!-- Audit: B.6.6 (b6-6-helm, FR-B6-HELM-001, FR-B6-HELM-040) -->
# Temporal cluster (production Helm) for `forge-eda-example`

This directory is the **production** Temporal deployment for the
`event-driven-eu` backend: the four Temporal server roles —
**history / matching / frontend / worker** — on a **Postgres-backed** persistence
+ visibility store, deployed on Kubernetes via the upstream Temporal Helm chart.

It is the K8s counterpart to the **dev-only** overlay
`infra/temporal/docker-compose.temporal.yml` (`temporalio/auto-setup`, ephemeral
SQLite) — do NOT use the dev overlay for staging/production. Standard:
`.forge/standards/infra/temporal.md` (Constitution §VIII.2 — Temporal is the Rust
orchestrator).

## Delivery model — chart-referenced hybrid (ADR-B6-HELM-001)

Temporal is **Atlas-installed from the upstream chart**; this tree vendors only
the Forge **values overlay** (`values-forge.yaml`) + this doc — no raw K8s
manifests, no `Chart.yaml`. The upstream chart owns the four server Deployments,
the schema-setup Job, `admintools`, and the Web UI (mirrors the B.8.7 Zitadel and
B.8.4 Envoy Gateway posture).

| Plane | What | How |
|-------|------|-----|
| **Control + data plane** | frontend/history/matching/worker Deployments, schema-setup Job, admintools, Web UI | Upstream Helm chart `temporal/temporal` (Atlas-provided install — below) |
| **Forge overlay** | 4-role replica/resources, Postgres datastores, `numHistoryShards`, secret refs, provenance labels | `values-forge.yaml.tmpl` (this dir) |

## Resources (verify-then-pin LIVE 2026-07-10)

| Resource | Pin | Provenance |
|----------|-----|------------|
| Helm chart `temporal/temporal` | `1.5.0` | `helm show chart temporal/temporal` (chart-tested pair) |
| Server image `temporalio/server` | `1.31.1` | chart `1.5.0` appVersion |
| admintools `temporalio/admin-tools` | `1.31.1` | chart default (appVersion pair) |
| Web UI `temporalio/ui` | `2.51.1` | chart default |

> **Client vs server**: the backend `saga` crate uses the CLIENT SDK
> `temporalio-sdk` / `temporalio-client` **`0.5.0`** (pinned in
> `backend/Cargo.toml`, feature-gated OFF). That is a *different layer* from this
> **server** cluster (`1.31.1`) — the crate pin is NOT restated here and MUST NOT
> be re-pinned in this overlay (single source of truth = `backend/Cargo.toml`).

## Control-plane install (Atlas-provided)

```sh
helm repo add temporal https://go.temporal.io/helm-charts
helm repo update
helm install forge-eda-example-temporal temporal/temporal \
  --version 1.5.0 \
  -f values-forge.yaml \
  --namespace forge-eda-example --create-namespace
```

The chart's schema-setup Job (Helm hook) runs **before** the server pods start
and creates/migrates the `temporal` + `temporal_visibility` Postgres schemas
(`schema.useHelmHooks: true` in the overlay). For Flux/ArgoCD/Terraform, set
`schema.useHelmHooks: false` and run `temporal-sql-tool setup-schema` /
`update-schema` from `admintools` out of band.

## Postgres backing (ADR-B6-HELM-002)

Temporal needs **two** databases on a PostgreSQL 12+ instance — `temporal`
(default store) and `temporal_visibility` (visibility store). The
event-driven-eu backend already ships a Postgres 17 event store
(`infra/postgres/`); production Temporal SHOULD use a **dedicated** Postgres
instance/database (isolate workflow state from the event store), reachable at the
overlay's `connectAddr` (`forge-eda-example-temporal-db:5432`).

- The Cassandra sub-chart was **removed upstream** (v1.0.0-rc.2); persistence is
  configured purely under `server.config.persistence.datastores.<name>.sql` with
  `pluginName: postgres12`. There is no `cassandra:` key.
- `numHistoryShards: 512` — **immutable after the first deployment**; changing it
  later corrupts routing. Pick the production value up front.

### Secret (never committed — NFR-B6-HELM-003)

The DB password is a K8s Secret referenced by NAME (`existingSecret`). Create it
at deploy time (placeholder command — the password VALUE is never templated):

```sh
kubectl -n forge-eda-example create secret generic forge-eda-example-temporal-db \
  --from-literal=password="<db-password>"
```

## Scaling the four roles

| Role | Overlay default | Scale on |
|------|-----------------|----------|
| `frontend` | 2 | client / gRPC request volume |
| `history`  | 3 | workflow state throughput (owns the history shards) |
| `matching` | 2 | task-queue backlog / dispatch rate |
| `worker`   | 2 | internal system workflows (archival, scavenger) |

Application task-queue workers (your Rust `saga` workers) run **in the backend
Deployment**, not in this chart — this chart is the Temporal *server* cluster
they connect to at `forge-eda-example-temporal:7233`.

## Compliance posture — T1 / T2 / T3 (FR-B6-HELM-040)

Per `.forge/standards/global/compliance-tiers.md` (Temporal Cloud row, verbatim):

| Tier | Posture | Verdict |
|------|---------|---------|
| **T1** | Temporal **Cloud** (managed SaaS, with a DPA) | ⚠️ T1 |
| **T2** | Temporal **self-hosted** on EU infrastructure (this chart) | ✅ self-host T2 |
| **T3** | Temporal self-hosted on EU + SecNumCloud (OVHcloud / Scaleway / Outscale) | ✅ self-host EU (self-host obligatoire) |

> `compliance-tiers.md:151` — *"Temporal Cloud | ⚠️ T1 | ✅ self-host T2 | ✅
> self-host EU | self-host pour T3"*

This chart **is** the self-host path: a T2/T3 EU deployment runs Temporal on your
own EU K8s (no Temporal Cloud dependency). For T3, run it on a SecNumCloud-qualified
cluster and enable Postgres TLS (`...sql.tls.enabled: true` + a `caFile`). See
`docs/COMPLIANCE.md` for tier selection.

## Scope out (this brick)
- **App task-queue workers** (Rust `saga` worker wiring) — backend concern.
- **mTLS between Temporal internode/frontend** — commented scaffold in the chart
  values; wire per your PKI at deploy (T3).
- **Namespace/retention provisioning** (`server.config.namespaces`) — adopter
  choice; the backend uses `${TEMPORAL_TASK_QUEUE}` on the `default` namespace.
