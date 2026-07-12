# Design (infra layer): demo-003-order-saga

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layer: infra (FR-IN-*). Multi-layer change → per-layer design (FR-GL-016). -->

This is the **infra-layer** design for the order-fulfillment saga
(FR-IN-001): the Temporal cluster the backend saga worker targets. The
backend-layer design (the saga crate) is in `designs/design-backend.md`;
Janus coordinates the two.

## Architecture Decisions

### ADR-IN-001: Temporal cluster consumed by reference (B8O substrate)

**Context.** FR-IN-001 needs a Temporal cluster for the activity-only
worker, but the archetype already ships one (b6-6-helm + the B8O
`infra/temporal.md` substrate). This demo must not re-decide cluster
topology.

**Decision.** Point the saga worker at the archetype's existing Temporal
cluster:
- **Dev**: `infra/temporal/docker-compose.temporal.yml` (single-node
  Temporal + its Postgres) for `task dev:up`.
- **Prod**: `infra/k8s/temporal-cluster/values-forge.yaml` (the Helm
  overlay on the upstream chart — history / matching / frontend / worker
  services with Postgres backing).

The cluster is referenced, not re-provisioned; the saga worker's task
queue + namespace are the only new wiring (documented, not re-decided
here).

**Consequences.** ✅ No infra duplication — one Temporal cluster serves
all sagas. ✅ EU-sovereign self-host posture (T2/T3) inherited from
b6-6-helm. ⚠️ The worker's task-queue/namespace binding is config the
adopter sets per environment (documented in `infra/temporal/README.md`).

### ADR-IN-002: Structural-only validation in the example CI gate

**Context.** The Forge `example` CI job is parse-only (ADR-B6-8-004) — it
does not stand up a Temporal cluster.

**Decision.** The infra layer's CI contribution is a structural YAML
parse of the rendered `infra/**/*.yaml` (the EDA `example` gate globs it).
Standing up the cluster + running the worker against it is a
toolchain-gated integration concern, out of the parse-only example job.

**Consequences.** ✅ The example job stays fast + dependency-free. ⚠️ A
live cluster smoke test lives in the adopter's own CI, not the framework
example job.

## Standards Applied

| Standard | How |
|---|---|
| `infra/temporal` | cluster topology + activity-only worker guidance (B8O substrate) |
| `infra/nats-jetstream` | the event broker the saga's activities publish through |

## Constitutional compliance gate

| Article | Gate-blocked? | Justification |
|---|---|---|
| VIII — Infrastructure | NO | Temporal cluster reused by reference; no re-decision |
| V — Conformance | NO | rendered infra YAML parses in the example gate |
