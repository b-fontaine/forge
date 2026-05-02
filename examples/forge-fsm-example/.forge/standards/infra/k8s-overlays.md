# Standard — Kubernetes Overlays (dev / staging / prod)

<!-- Audit: B.1.12 (b1-delivery, FR-IN-011) -->
<!-- Scope: infra | Priority: high -->
<!-- Triggers: kustomize, overlay, kubernetes, k8s, deployment, namespace, replicas, hpa, ingress -->

> Authoritative reference for the three-environment Kustomize
> promotion model shipped by the `full-stack-monorepo` archetype.
> Templates live under `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/`.
> NEVER hand-edit the rendered output of `kustomize build` (ADR-004).

## Three-environment promotion model

The archetype ships **three** canonical environments and only
three :

- `dev` — developer-shared cluster or local kind/minikube.
  Single replica, mutable image tag, lowest resource budget.
- `staging` — pre-production, immutable SHA-pinned image from
  `main`. Two replicas. Mirrors prod topology except for HPA.
- `prod` — production, tag-pinned image from a release. Three
  replicas baseline + `HorizontalPodAutoscaler` (3..10, 70% CPU).

Adopters MUST NOT add a fourth environment to the archetype tree.
A project that needs additional environments (e.g. `qa`, `uat`)
adds them in its own repo, **outside** `infra/k8s/overlays/` so
the Forge sweep does not consider them part of the contract.

## Per-overlay diff conventions

Each overlay's `kustomization.yaml` patches a strict, enumerated
set of fields against `base/` :

| Field                       | dev                                  | staging                  | prod                              |
|-----------------------------|--------------------------------------|--------------------------|-----------------------------------|
| `namespace`                 | `<project-name>-dev`                 | `<project-name>-staging` | `<project-name>-prod`             |
| `images[].newTag`           | `dev-latest`                         | `sha-<commit>`           | `v<semver>`                       |
| `replicas[].count`          | 1                                    | 2                        | 3                                 |
| `commonAnnotations`         | `forge.io/overlay: dev`              | `…: staging`             | `…: prod`                         |
| `configMapGenerator`        | OTLP endpoint + `APP_ENV=dev`        | `…=staging`              | `…=prod`                          |
| `resources` patches         | optional (lower than base defaults)  | optional                 | optional                          |
| Additional resources        | none                                 | none                     | `hpa.yaml` (HorizontalPodAutoscaler) |

Any **other** field that varies between overlays is a smell —
either it belongs in `base/`, or the overlay is taking on
responsibilities it shouldn't. NFR-017 caps the rendered diff
between dev and prod at ≤ 4 KB.

## Image tag policy by environment

| Environment | Tag shape                              | Mutability    | Producer                |
|-------------|----------------------------------------|---------------|-------------------------|
| dev         | `dev-latest` (or `dev-<branch>`)        | mutable       | dev push to local registry stub |
| staging     | `sha-<git-sha-7>`                       | immutable     | CI on `main` push                |
| prod        | `v<major>.<minor>.<patch>`              | immutable     | release tooling on tag push      |

The `:latest` tag is **forbidden in every overlay** (NFR-018,
ADR-008). The harness `delivery.test.sh` enforces this with a
grep guard.

## Resource budget table

CPU and memory targets per environment :

| Container       | dev requests | dev limits | staging requests | staging limits | prod requests | prod limits |
|-----------------|--------------|------------|------------------|----------------|---------------|-------------|
| backend         | 100m / 128Mi | 500m / 512Mi | 200m / 256Mi   | 1000m / 1Gi    | 500m / 512Mi  | 2000m / 2Gi |

Base defaults to the dev row. Overlays may patch the row up
toward production but **never down** — a staging overlay that
requests less than dev is a misconfiguration the cluster will
not catch automatically.

## Secret management

**Allowed** :
- **Sealed Secrets** (Bitnami) — encrypted-at-rest in Git, decrypted
  by the controller in-cluster.
- **External Secrets Operator** — backed by Vault, AWS Secrets
  Manager, or GCP Secret Manager.

**Forbidden** :
- Plain `kind: Secret` resources with `data:` containing base64
  values committed to Git. Even if base64-encoded, this is
  effectively plaintext.
- Secrets injected via `configMapGenerator` `literals:` (Forge
  overlays may use `configMapGenerator` for **non-secret** env
  vars only).
- Hardcoded credentials in `Dockerfile`, `kong.yml`, or any other
  template.

The base ServiceAccount declares `automountServiceAccountToken:
false` to keep the default token off the Pod filesystem.

Auth on observability services (SigNoz, Grafana, etc.) :
**dev = disabled, staging/prod = MUST be enabled**. The local dev
compose stack ships with auth off (FR-IN-008) ; the equivalent
Helm/Kustomize manifests for staging and prod MUST flip auth on.

## Promotion gating

The Forge change lifecycle gates which environments a change is
eligible to deploy to :

| Forge change status | Eligible environments        |
|---------------------|------------------------------|
| `proposed`          | none (spec not yet written)  |
| `specified`         | none                         |
| `designed`          | `dev` only                   |
| `planned`           | `dev` only                   |
| `implemented`       | `dev` + `staging`            |
| `archived`          | `dev` + `staging` + `prod`   |

A change cannot ship to staging before it has been implemented
and tests pass in dev ; a change cannot ship to prod before it
has been archived (= reviewed, gated, and the spec delta is
recorded).

This mapping is enforced **socially** (review discipline + the
Forge change's `status:` field as the single source of truth) ;
no automation blocks deploys yet. A future module (G.3 Forge
Guardian) will mechanise the check.
