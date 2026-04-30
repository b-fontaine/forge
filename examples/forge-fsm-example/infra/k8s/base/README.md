# Kubernetes manifests for `forge-fsm-example`

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
