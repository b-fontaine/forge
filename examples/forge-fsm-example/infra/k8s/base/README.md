# Kubernetes manifests for `<project-name>`

<!-- Audit: B.1.12 (b1-delivery, FR-IN-006) -->

This tree follows the Kustomize **base + overlays** topology
prescribed by `.forge/standards/infra/k8s-overlays.md` :

- `base/` — shared shape (Deployment, Service, ServiceAccount,
  Ingress) for the backend service. Hand-edits here affect every
  environment.
- `overlays/{dev,staging,prod}/` — per-environment patches :
  namespace, image tag policy, replicas, resources. Production
  overlays additionally declare a `HorizontalPodAutoscaler`.

## Render and validate

```sh
kustomize build infra/k8s/overlays/dev
kustomize build infra/k8s/overlays/staging
kustomize build infra/k8s/overlays/prod

# Strict schema validation
kustomize build infra/k8s/overlays/prod | kubeconform --summary --strict
```

## Promotion lifecycle

A change moves through environments in lockstep with its Forge
lifecycle :

| Forge change status | Eligible environment |
|---------------------|----------------------|
| `proposed`          | none                 |
| `specified`         | none                 |
| `designed`          | `dev` only           |
| `planned`           | `dev` only           |
| `implemented`       | `dev` + `staging`    |
| `archived`          | `dev` + `staging` + `prod` |

See `.forge/standards/infra/k8s-overlays.md` § Promotion gating
for the full rationale.

## Deployment prerequisites

Before applying the base manifests to any cluster — especially the
T.5 OTel stack additions (OBI eBPF DaemonSet + Coroot deploy) — verify :

- [ ] **Kernel ≥ 5.8** on all worker nodes intended to host OBI pods
      (`observability.yaml::kernel_min: "5.8"`). Older kernels lack
      reliable BPF capability support and will drop spans silently.
- [ ] **Aegis security review** completed for `obi-daemonset.yaml`
      before any production rollout. The DaemonSet carries
      `hostPID + hostNetwork + capabilities` ; required posture per
      `observability.yaml::deployment_constraints.aegis_audit_required_for_prod: true`.
      See `infra/CLAUDE.md` § "Privileged DaemonSet — Aegis audit
      required" for the full duty list.
- [ ] **Kernel-min node label** applied on eligible nodes :
      `kubectl label node <name> forge.dev/kernel-min-58=true`. The
      DaemonSet `nodeSelector` will skip nodes without it (safe default).
- [ ] **Coroot persistence** : if deploying to staging/prod, swap the
      `coroot-deployment.yaml` `emptyDir` for a PersistentVolumeClaim
      (see `infra/CLAUDE.md` § "Coroot persistence").
- [ ] **OTel collector deployment** : Phase A ships the collector
      *config* (`infra/observability/otel-collector-config.yaml`) but
      not its K8s Service. Wire the collector via `configMapGenerator`
      + a Deployment manifest as part of Phase B work, or via a custom
      adopter overlay in the meantime.
