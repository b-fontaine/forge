<!-- Audit: B.1.3 (part of b1-scaffolder, infra nested CLAUDE.md) -->
<!-- Scope: infra/ subtree only — infra standards -->

# CLAUDE.md — <project-name>/infra

## Scope

This nested CLAUDE.md is automatically loaded by Claude Code when navigating any file under
`infra/`. It scopes which Forge standards apply and which agent orchestrator owns work in
this subtree. The root `CLAUDE.md` carries cross-cutting policies only; infrastructure-specific
standards must be injected at this level, not globally. Standards from OTHER scopes — Flutter
and Rust — MUST NOT be loaded here. Loading them would pollute the context window with
irrelevant rules and risk cross-layer enforcement bleeding into infrastructure decisions (e.g.,
Rust borrow-checker patterns applied to Docker configuration, or Flutter widget rules applied
to Kubernetes manifests). JIT loading by subdirectory guarantees this isolation; this file is
its enforcement point.

## Load These Standards (infra scope)

The following standards MUST be injected when Claude Code operates under `infra/`. Every `id`
below exists in `.forge/standards/index.yml`.

- **global/tdd-rules** : always active — Article I of the Constitution; RED-GREEN-REFACTOR
  cycle is non-negotiable, including for infrastructure-as-code validation scripts.
- **infra/docker** : activate for any Dockerfile or container image work — multi-stage builds
  mandatory, distroless (or Alpine-minimal) final stage, `HEALTHCHECK` instructions required
  (Article VIII.3).
- **infra/docker-compose** : activate for local dev orchestration work — `fsm-` prefix on all
  services, named `fsm-dev` network, healthchecks mandatory, `depends_on` with
  `condition: service_healthy`. This standard is consumed at the repo root level by
  `docker-compose.dev.yml`; infra changes that affect compose topology MUST also update the
  root compose file and its `.env.example`.
- **infra/kubernetes** : activate for any K8s manifest or Kustomize work — `base/` +
  `overlays/{dev,staging,prod}/` structure, HPAs, PDBs, resource limits and requests on every
  container.
- **infra/kong** : activate when modifying API gateway configuration — declarative config ONLY
  (`kong.yml`); no admin API mutations; gRPC transcoding rules, rate-limit plugins, CORS plugin
  per environment.
- **infra/temporal** : activate when touching Temporal namespace definitions or worker
  deployment manifests — workflow and activity logic lives in `backend/crates/`; this folder
  owns only Temporal infrastructure (namespace YAML, worker deployment).
- **observability/opentelemetry** : activate when the OTel collector configuration lands
  (b1-delivery) — collector config, OTLP receiver and exporter settings, sampling strategies.

## DO NOT Load (explicit exclusions)

The following standards MUST NOT be loaded when working under `infra/`. If any agent or tool
attempts to inject them from this subtree, surface it immediately as:
`[NEEDS CLARIFICATION: why is <standard> being loaded under infra/?]`

- Any `flutter/*` standard — frontend concern; route to `frontend/CLAUDE.md` and Hera.
- Any `rust/*` standard — backend concern; route to `backend/CLAUDE.md` and Vulcan.
- `global/proto-contracts` — cross-layer contract concern; proto changes go through
  `shared/protos/` and are owned by Hermes-API; infra only consumes generated descriptors for
  Kong gRPC transcoding and MUST NOT drive proto authoring.

Loading any of the above from this file is a scope leak and a constitutional violation
(Article V.2 — layer isolation is non-negotiable).

## Primary Agent

- **Atlas** — Infrastructure Architect. All container, orchestration, gateway, and deployment
  decisions under `infra/` are routed to Atlas.
- Atlas coordinates with sub-specialists as needed:
  - **Panoptes** — Observability (OTel collector configuration, SigNoz deployment, metrics
    pipelines)
  - **Heracles** — DevOps / CI (GitHub Actions infra jobs, deployment automation, task aliases)
  - **Aegis** — Security audit (image scanning, RBAC manifests, secret management, network
    policies)
- For changes that touch more than one layer (e.g., a Kong route change that also modifies a
  backend gRPC handler), defer to **Janus** via the root `CLAUDE.md` (b1-workflow). A
  `FR-GL-XXX` requirement MUST be raised before work begins.

## Architecture Non-Negotiables

These rules derive from Article VIII of the Constitution, `infra/docker`, `infra/kubernetes`,
`infra/kong`, and `infra/docker-compose`. Violations block merge.

- **Distroless final stages** : all Dockerfiles MUST use a multi-stage build with a distroless
  (or Alpine-minimal) final stage (Article VIII.3). Build tools MUST NOT be present in the
  final image. `gcr.io/distroless/cc-debian12:nonroot` is the canonical choice for Rust
  binaries. The final stage MUST run as a non-root user (Article IX.2).
- **Docker Compose conventions** : all services carry the `fsm-` prefix; every service is
  attached to the named `fsm-dev` network (no implicit default bridge); every service declares
  a `healthcheck` block; `depends_on` uses the extended `condition: service_healthy` form.
  A bare `docker-compose.yml` at the repo root is forbidden — use explicit suffixes
  (`docker-compose.dev.yml`, `docker-compose.e2e.yml`, etc.).
- **K8s Kustomize layout** : manifests are organized as `infra/k8s/base/` for base resources
  and `infra/k8s/overlays/{dev,staging,prod}/` for environment-specific patches. If the team
  prefers Helm, document the decision in this file before the first manifest lands; mixed
  Kustomize + Helm in the same layer is forbidden. Environment overlays are generated by
  `b1-delivery` — `infra/k8s/overlays/` is currently empty (`.gitkeep` only).
- **Kong declarative config only** : all Kong configuration lives in `infra/kong/kong.yml`.
  Admin API mutations at runtime are FORBIDDEN. DB-less mode (`KONG_DATABASE=off` +
  `KONG_DECLARATIVE_CONFIG=/kong/kong.yml`) is the only supported operating mode in this
  archetype.
- **Temporal topology** : Temporal workflow and activity logic lives in `backend/crates/` as
  library code; the worker binary lives in `backend/src/bin-server`. This `infra/` folder
  holds only Temporal namespace definitions (YAML) and worker deployment manifests (K8s).
  Temporal SDK code MUST NOT live here.

## Cross-layer Concerns

- **Changes touching `infra/` and `backend/`** : route to Janus (root `CLAUDE.md`). Raise a
  `FR-GL-XXX` requirement. Atlas and Vulcan co-own the review.
- **Kong route changes reflecting proto RPCs** : route to Hermes-API (proto authoring) + Atlas
  (gateway config). Kong `grpc-gateway` transcoding rules MUST match the proto service
  definitions exactly. Divergence is a contract violation.
- **Observability changes crossing layers** : route to Panoptes (collector config) + Argus
  (frontend OTel, `opentelemetry_dart`) + Sentinel (backend OTel, `tracing-opentelemetry`).
  Span naming conventions MUST be agreed across all three layers before any OTel config lands.

**Full multi-layer routing policy** : see `.forge/standards/global/multi-layer-workflow.md`
and the Janus agent definition at `.claude/agents/cross-layer-orchestrator.md`. When a change declares
`layers:` with ≥ 2 entries, Janus orchestrates; infra-only work stays under Atlas.

## Privileged DaemonSet — Aegis audit required

The OBI eBPF DaemonSet (`infra/k8s/base/obi-daemonset.yaml`) is shipped
under T.5 `t5-otel-stack` as the realisation leg of `observability.yaml`
v1.1.0 (ADR-008 + ADR-OTEL-004 in `.forge/changes/t5-otel-stack/design.md`).

It carries elevated privileges that **MUST** be audited by Aegis before
any production rollout :

- `hostPID: true` — required for Beyla to discover host processes.
- `hostNetwork: true` — required to monitor network packets at the host
  level.
- Linux capabilities `add: [BPF, SYS_PTRACE, NET_RAW, CHECKPOINT_RESTORE,
  DAC_READ_SEARCH, PERFMON, NET_ADMIN, SYS_ADMIN]` — drop ALL otherwise.
- `securityContext.runAsUser: 0` + `readOnlyRootFilesystem: true`.
- `metadata.annotations["forge.dev/aegis-audit"]: "required"` — surfaces
  the duty to deployment tooling.
- `nodeSelector: forge.dev/kernel-min-58: "true"` — gates scheduling on
  eBPF-capable kernels (`observability.yaml::kernel_min: "5.8"`). Operators
  apply the label manually : `kubectl label node <name>
  forge.dev/kernel-min-58=true`.

**Aegis duty** stems from `observability.yaml::deployment_constraints
.aegis_audit_required_for_prod: true`. The audit MUST verify : minimal
capability set, no `privileged: true` blanket, kernel ≥ 5.8 fleet-wide,
RBAC scoped to read-only on pods+nodes+replicasets.

**Opt-out path** for T1 environments where eBPF kernel ≥ 5.8 is not
guaranteed : remove `obi-daemonset.yaml` from the observability
kustomization. The OTel + SigNoz + Coroot trio still ships ; OBI is the
zero-instrumentation layer adopters can defer.

**Privileged form (legacy fallback)** for runtimes where the BPF
capability is not reliable (older containerd / Docker shim, kernel < 5.8) :
Kustomize patch swapping the `capabilities` block for
`securityContext.privileged: true`. Documented but **not preferred** —
Aegis approval is harder to obtain for the privileged form.

## Sampler overlay mechanism (T.5 `t5-otel-stack`)

`infra/observability/otel-collector-config.yaml` ships with a
`processors.probabilistic_sampler` block (ADR-OTEL-001) defaulting to
`sampling_percentage: 100` (dev). Per-env-tier override files live at
`infra/k8s/overlays/{dev,staging,prod}/sampler-patch.yaml` carrying only
the override fragment :

```yaml
processors:
  probabilistic_sampler:
    sampling_percentage: 10   # prod ratio per observability.yaml::ratios.prod
```

The patch is applied at deployment time via `configMapGenerator.behavior:
merge` in the env-tier kustomization (Phase B wires the actual ConfigMap
when the OTel collector ships as a K8s Service). Until then, the per-env
ratio lives as documentation of the intended override and is consumed by
local-dev `docker-compose` workflows manually.

## Coroot persistence

`coroot-deployment.yaml` ships a single replica with `emptyDir` for
`/data` — adequate for local-dev. **Production rollouts** SHOULD swap
`emptyDir: {}` for a `PersistentVolumeClaim` referencing a storage class
appropriate for the cluster (block storage minimum 10 GiB, retention
matching the trace retention budget).
