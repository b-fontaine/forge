# Spec: otel-stack

<!-- Audit: T.5 (t5-otel-stack) — Phase 1 ARCHITECTURE-TARGET ADR-008 infra side. -->
<!-- Source change : `.forge/changes/t5-otel-stack/` (archived 2026-05-10). -->

**Namespace** : `FR-OTEL-*` / `NFR-OTEL-*`.
**Constitution** : v1.1.0. Pas d'amendement requis (additive
realisation of `observability.yaml` v1.0.0 → v1.1.0).

**Standard ratified** : `.forge/standards/observability.yaml` v1.1.0
(MINOR bump, additive `versions:` block per ADR-OTEL-003).

**Templates** :
`.forge/templates/archetypes/full-stack-monorepo/infra/...`.
**Example mirror** : `examples/forge-fsm-example/infra/...`.
**Harness** : `.forge/scripts/tests/t5-otel.test.sh` (14 L1 tests).

---

## Functional Requirements

### Cluster 1 — OBI eBPF DaemonSet manifest

#### FR-OTEL-001 — Manifest file exists

`infra/k8s/base/obi-daemonset.yaml.tmpl` MUST exist as a
Kubernetes DaemonSet manifest realising
`observability.yaml::ebpf_complement: opentelemetry-obi`.

#### FR-OTEL-002 — `kind: DaemonSet`

Per-node attachment for eBPF probes.

#### FR-OTEL-003 — Unprivileged with capabilities

Per ADR-OTEL-004 : `securityContext.capabilities.add: [BPF, SYS_PTRACE,
NET_RAW, CHECKPOINT_RESTORE, DAC_READ_SEARCH, PERFMON, NET_ADMIN,
SYS_ADMIN]` ; `drop: [ALL]`. Privileged form is documented opt-in
fallback for runtimes without reliable BPF capability.

#### FR-OTEL-004 — `hostPID: true` + `hostNetwork: true`

Required for cross-cgroup tracing + host packet visibility.

#### FR-OTEL-005 — Kernel ≥ 5.8 nodeSelector

`nodeSelector: forge.dev/kernel-min-58: "true"` per ADR-OTEL-007
(opt-in node label, applied manually via `kubectl label node ...`).

#### FR-OTEL-006 — OTel exporter target

`OTEL_EXPORTER_OTLP_ENDPOINT` env var pointing at the local OTel
collector (HTTP `:4318`).

#### FR-OTEL-007 — Image pin

`image: grafana/beyla:2.0.1` (ADR-OTEL-002, Context7-verified
2026-05-08, > 30 days old). `:latest` forbidden.

#### FR-OTEL-008 — RBAC

Dedicated `ServiceAccount` + `ClusterRole` (read-only on
`pods` / `nodes` / `replicasets`) + `ClusterRoleBinding`. No
`cluster-admin`.

#### FR-OTEL-009 — Resource limits

`resources.requests` + `resources.limits` present (default :
100m/128Mi → 500m/256Mi).

#### FR-OTEL-010 — Aegis audit annotation

`metadata.annotations["forge.dev/aegis-audit"]: "required"`
surfaces the deployment-time review duty per
`observability.yaml::deployment_constraints.aegis_audit_required_for_prod`.

---

### Cluster 2 — Coroot deployment manifest

#### FR-OTEL-020 — Manifest exists

`infra/k8s/base/coroot-deployment.yaml.tmpl` exists as multi-doc
YAML (per ADR-OTEL-006 : Deployment + Service + ConfigMap in a
single file).

#### FR-OTEL-021 — Image pin

`image: coroot/coroot:1.4.4` (ADR-OTEL-002).

#### FR-OTEL-022 — Service + ConfigMap

ClusterIP `Service` named `<project-name>-coroot`, ports
`8080` (UI) / `4317` (OTLP gRPC) / `4318` (OTLP HTTP). ConfigMap
named `<project-name>-coroot-config` with key `config.yaml`
carrying the Coroot config.

#### FR-OTEL-023 — OTel collector wiring

ConfigMap config points its trace ingestion at the local OTel
collector via `integrations.collector_endpoint:
http://<project-name>-otel-collector:4317`.

---

### Cluster 3 — Sampler `parentbased_traceidratio` config

#### FR-OTEL-030 — Sampler in collector pipeline

`infra/observability/otel-collector-config.yaml.tmpl` MUST carry a
`processors.probabilistic_sampler` block (ADR-OTEL-001 — collector-side
mechanism), wired into the `traces` pipeline only.

#### FR-OTEL-031 — Default ratio

Base template `sampling_percentage: 100` (dev default).

#### FR-OTEL-032 — Prod overlay

`infra/k8s/overlays/prod/sampler-patch.yaml.tmpl` overrides to
`sampling_percentage: 10` per `observability.yaml::ratios.prod = 0.1`.

#### FR-OTEL-033 — Staging overlay

`infra/k8s/overlays/staging/sampler-patch.yaml.tmpl` →
`sampling_percentage: 100` per `ratios.staging = 1.0`.

#### FR-OTEL-034 — Dev overlay (explicit)

`infra/k8s/overlays/dev/sampler-patch.yaml.tmpl` →
`sampling_percentage: 100`. Shipped explicitly per ADR-OTEL-005
(option a) for symmetry across the three overlays.

#### FR-OTEL-035 — Sampler type

`mode: proportional`, `attribute_source: traceID`,
`hash_seed: 22` — closest collector-side analogue of
`observability.yaml::sampler: parentbased_traceidratio`.

---

### Cluster 4 — Aegis privileged DaemonSet documentation

#### FR-OTEL-040 — `infra/CLAUDE.md.tmpl` Aegis section

H2 section "Privileged DaemonSet — Aegis audit required" enumerating
the elevated privileges, the audit duty, the opt-out path for T1
environments, and the privileged-form Kustomize fallback for
runtimes without reliable BPF capability.

#### FR-OTEL-041 — README prerequisites checklist

`infra/k8s/base/README.md.tmpl` H2 "Deployment prerequisites"
checklist : kernel ≥ 5.8, Aegis review, kernel-min node label,
Coroot persistence, OTel collector wiring.

---

### Cluster 5 — Example mirror

#### FR-OTEL-050 — `examples/forge-fsm-example/` parity

Six rendered files mirror the templated ones :
- `infra/k8s/base/obi-daemonset.yaml`
- `infra/k8s/base/coroot-deployment.yaml`
- `infra/observability/otel-collector-config.yaml`
- `infra/k8s/overlays/{dev,staging,prod}/sampler-patch.yaml`

`<project-name>` placeholder substituted with `forge-fsm-example`.

---

### Cluster 6 — Test harness `t5-otel.test.sh`

#### FR-OTEL-060 — Harness exists

`.forge/scripts/tests/t5-otel.test.sh` mirrors the J.7 / T.5 layout.

#### FR-OTEL-061 — L1 coverage ≥ 12 tests

14 L1 tests shipped (12 anchor tests + 1 example mirror parity + 1
standard bump).

#### FR-OTEL-062 — L2 fixtures

None in this change. `kustomize build` + `kubeconform` lint deferred
to a follow-up change.

---

### Cluster 7 — CI registration

#### FR-OTEL-070 — `forge-ci.yml` matrix entry

`t5-otel.test.sh --level 1` registered immediately after
`j7.test.sh`.

---

### Cluster 8 — Documentation

#### FR-OTEL-080 — `observability.yaml` realisation note + bump

`observability.yaml` 1.0.0 → 1.1.0 (additive) with new `versions:`
block recording `beyla: "2.0.1"` + `coroot: "1.4.4"`. Header comment
extended with audit trail. REVIEW.md `Updated` ledger entry dated
2026-05-09 (Decision : KEEP-WITH-CHANGES, `Next review due:
2027-05-04` unchanged).

#### FR-OTEL-081 — `docs/ARCHETYPES.md` flagship row

Stack column updated to mention OBI eBPF + Coroot + sampler
overlays.

#### FR-OTEL-082 — `CHANGELOG.md` entry

Entry under `## [Unreleased]` summarising the manifests, sampler
config, overlays, standard bump, Aegis docs.

---

## Non-Functional Requirements

### NFR-OTEL-001 — Snapshot tarball budget

`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
≤ 600 KB gzipped. **Measured** : 520 KB (87 % of budget).

### NFR-OTEL-002 — Backward compatibility

`forge upgrade` (A.7) 3-way-merges new manifests into adopter trees
that scaffolded under `1.0.0` pre-T5-OTEL. **Confirmed** : `a7.test.sh`
29/0 PASS post-snapshot regen.

### NFR-OTEL-003 — Article V audit trail

Every task in `tasks.md` carries `[Story: FR-OTEL-XXX]` tag.

### NFR-OTEL-004 — No new app-side dependency

Pure infra-side templates. No new Rust crate, npm package, or Dart
package. Phase B (SDK instrumentation) is a follow-up change.

### NFR-OTEL-005 — Performance budget

Harness `t5-otel.test.sh --level 1` ≤ 5 s wall-clock. **Measured** :
< 1 s (no K8s spin-up at L1, pure file presence + grep).

---

## ADRs (T5-OTEL design)

| ID         | Decision summary                                                                                                                                                                                                       |
|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ADR-OTEL-001 | Sampler mechanism : `processors.probabilistic_sampler` collector-side (`mode: proportional`, `attribute_source: traceID`, `hash_seed: 22`). Env-tier overlays patch `sampling_percentage` only.                       |
| ADR-OTEL-002 | Image pins : `grafana/beyla:2.0.1` + `coroot/coroot:1.4.4`. Both > 30 days old at design time, Context7-verified, no waiver needed. **Amended 2026-05-25 by `b8-coroot-rehost` (B.8.8) — Coroot pin refreshed to `ghcr.io/coroot/coroot:1.20.2` (host migration `docker.io → GHCR`, docker.io public access denied 2026-05-24). `observability.yaml` bumped v1.1.0 → v1.2.0 additive. Beyla pin deferred to sibling `b8-obi-refresh`. Full chain : `.forge/changes/b8-coroot-rehost/{specs.md,design.md,evidence.md}` + `ADR-B8-COR-001..004`.** |
| ADR-OTEL-003 | `observability.yaml` 1.0.0 → 1.1.0 MINOR additive bump with new `versions:` block. Symmetric with T.5 `transport.yaml` 1.0.0 → 1.1.0 codegen pinning.                                                                |
| ADR-OTEL-004 | OBI DaemonSet : unprivileged with capabilities default. Privileged form opt-in fallback for runtimes without reliable BPF capability.                                                                                  |
| ADR-OTEL-005 | Kustomize layout : 2 new manifests in `base/` + 3 overlay sampler-patches in `overlays/{dev,staging,prod}/`. Dev patch shipped explicitly for symmetry.                                                              |
| ADR-OTEL-006 | Coroot single-replica multi-doc YAML (Deployment + Service + ConfigMap in one file, `---` separators).                                                                                                                |
| ADR-OTEL-007 | `forge.dev/kernel-min-58: "true"` opt-in node label. NFD integration deferred.                                                                                                                                        |

Full design rationale + Mermaid diagrams + Open Questions resolution :
`.forge/changes/t5-otel-stack/design.md`.
