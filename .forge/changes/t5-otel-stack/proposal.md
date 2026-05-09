# Proposal: t5-otel-stack
<!-- Created: 2026-05-08 -->
<!-- Schema: default -->

## Problem

`observability.yaml` (T.4 baseline, ratifying ADR-008) prescribes the
**SigNoz + OBI eBPF + Coroot** observability triplet for the
`full-stack-monorepo` flagship, with a `parentbased_traceidratio`
sampler pinned to `prod 0.1 / staging 1.0 / dev 1.0`. The standard
also flags the OBI DaemonSet as `privileged_daemonset_required: true`,
requiring an Aegis audit at deployment time.

Today, the flagship template ships only **two of the four** stack
components :

- ✅ `infra/observability/signoz-config.yaml.tmpl` (29 lines) —
  SigNoz local config (B.1.14).
- ✅ `infra/observability/otel-collector-config.yaml.tmpl` (53 lines) —
  OTLP receivers + memory_limiter + batch + signoz exporter, **but
  no sampler config**.
- ❌ **OBI eBPF DaemonSet** manifest — missing entirely. Adopters who
  follow ADR-008 must hand-roll the privileged DaemonSet without a
  Forge-blessed reference.
- ❌ **Coroot deploy** manifest — missing entirely. Service-map
  enrichment + RED metrics rely on Coroot per ADR-008 §3.
- ❌ **Sampler `parentbased_traceidratio` config** — the existing
  collector config has zero sampler stanza, so adopters get the
  upstream default (always-sample) which violates the standard's
  `prod 0.1` ratio mandate.
- ❌ **Aegis audit annotation** — no warning surfaced in
  `infra/CLAUDE.md` or `README.md` about the privileged DaemonSet.

The traceparent W3C E2E validation deferred from T.5 (
`_test_t5_l2_traceparent_dual` in `t5-connect-codegen/tasks.md`)
**cannot land** until the OBI DaemonSet + Coroot are templated and
the sampler is configured. The B.8 flagship migration (T6) will not
ship a credible observability story without these manifests.

## Solution

Land the **infra-side** of the OTel + OBI + Coroot stack as a
self-contained additive change on the `full-stack-monorepo / 1.0.0`
schema. Strict scope :

1. New template
   `infra/k8s/base/obi-daemonset.yaml.tmpl` — privileged eBPF agent
   per OBI's upstream Helm chart (kernel ≥ 5.8 nodeSelector, hostPID,
   hostNetwork, capabilities `SYS_ADMIN` + `BPF` + `PERFMON`).
2. New template
   `infra/k8s/base/coroot-deployment.yaml.tmpl` — Coroot CE deploy
   + Service + ConfigMap for service-map ingestion.
3. **Extend** `infra/observability/otel-collector-config.yaml.tmpl`
   with a `processors.tail_sampling` (or equivalent — locked at
   design time) wiring `parentbased_traceidratio` per-env via the
   ratios in `observability.yaml`. The collector config gains an
   env-tier overlay knob (`prod` / `staging` / `dev`) consumed by
   Kustomize overlays.
4. New `infra/k8s/overlays/{prod,staging,dev}/sampler-patch.yaml.tmpl`
   trio applying the env-specific ratio.
5. **Aegis audit warning** in `infra/CLAUDE.md.tmpl` (privileged
   DaemonSet section) + `infra/k8s/base/README.md.tmpl` (deployment
   prerequisites checklist).
6. **`forge-fsm-example/`** mirrors all six template files (no
   `.tmpl` extension on the rendered side).
7. New harness `.forge/scripts/tests/t5-otel.test.sh` (≈ 12 L1)
   asserting the new template files exist + parse + carry the right
   sampler/OBI/Coroot anchors. Registered in `forge-ci.yml` matrix.
8. New consolidated spec `.forge/specs/otel-stack.md` (`FR-OTEL-*` /
   `NFR-OTEL-*`).
9. `transport.yaml` is **NOT** touched ; this change targets
   `observability.yaml` (no version bump — additive K8s manifests
   don't change the standard's contract, just realise it).

## Scope In

- 6 new / extended infra templates under
  `.forge/templates/archetypes/full-stack-monorepo/infra/`.
- Identical mirror in `examples/forge-fsm-example/`.
- Sampler env-tier overlay mechanism (Kustomize patches).
- Aegis privileged DaemonSet warning in `CLAUDE.md` +
  `README.md` infra docs.
- Test harness `t5-otel.test.sh` (≈ 12 L1, no L2 — fixture-level
  validation belongs to a future E2E change).
- CI registration in `.github/workflows/forge-ci.yml`.
- New consolidated spec `.forge/specs/otel-stack.md`.
- `CHANGELOG.md` entry under `## [Unreleased]`.

## Scope Out (Explicit Exclusions)

- **NOT** instrumenting backend Rust code (`tracing-opentelemetry`
  setup, span creation, traceparent context propagation) — that is a
  follow-up Phase B change.
- **NOT** instrumenting frontend Dart code (OTel SDK init,
  traceparent header injection on Connect/HTTP calls) — Phase B.
- **NOT** the W3C traceparent E2E test (
  `_test_t5_l2_traceparent_dual`) — Phase C, requires both A
  (this change) and B to land first.
- **NOT** touching the existing `signoz-config.yaml.tmpl` (already
  GREEN at B.1.14, no need to modify).
- **NOT** modifying the `observability.yaml` standard — additive
  realisation, no version bump needed.
- **NOT** Aegis audit automation — only documentation surfacing of
  the requirement. Aegis automation is a deployment-time concern,
  not template-level.
- **NOT** SigNoz cluster-mode / HA — local-dev defaults preserved
  per B.1.14 ; production HA is a deployment-time concern.
- **NOT** B.8 migration triggers (Envoy / DBOS / Connect 2.0.0
  schema bump). This change ships under schema `1.0.0`.
- **NOT** AsyncAPI 3.1 derivation (deferred to B.6 event-driven
  archetype).
- **NOT** Datadog / Honeycomb / New Relic exporters (forbidden by
  `observability.yaml` `forbidden: [datadog]` + EU CLOUD Act
  positioning).

## Impact

- **Users affected** : flagship `full-stack-monorepo / 1.0.0`
  adopters scaffolding new projects via `forge init --archetype
  full-stack-monorepo` (post-this-change). Existing adopters can
  pull the new manifests via `forge upgrade` (A.7) — additive,
  3-way merge friendly. Demo `examples/forge-fsm-example/` gains
  the manifests for documentation completeness.
- **Technical impact** : ~6 new template files + 3 modified
  (`otel-collector-config.yaml.tmpl`, `infra/CLAUDE.md.tmpl`,
  `infra/k8s/base/README.md.tmpl`) + same mirror in example +
  1 new harness + 1 new spec + 1 doc/CHANGELOG entry. **Effort `M`**.
- **Dependencies** :
  - T.4 `observability.yaml` v1.0.0 ✅ shipped.
  - T.5 `t5-connect-codegen` archived ✅ — not strictly required
    but aligns the snapshot baseline.
  - J.7 `j7-validate-standards-yaml` (PR #4 open). Independent —
    OTel templates do not touch standards YAML.
  - No new external SDK dep — the OBI + Coroot manifests use
    upstream Docker images (pinned via `versions:` block in the
    spec).
- **Risk level** : **Low–Medium**. Low because all template
  changes are additive on schema `1.0.0` and `forge upgrade`
  (A.7) handles the merge. Medium because the OBI DaemonSet
  carries `hostPID + hostNetwork + privileged` which adopters
  must accept ; mitigated by the Aegis audit warning + a clear
  opt-out path documented in `CLAUDE.md` (deploy without OBI
  in T1 environments where eBPF kernel ≥ 5.8 is not guaranteed).

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 writes `t5-otel.test.sh`
with ~12 L1 stubs returning `_not_implemented` (full RED witness).
Phase 2 implements the manifests one cluster at a time, each
preceded by a RED witness on the affected test cluster. Same
cadence as `f2-yaml-schema`, `t5-connect-codegen`,
`j7-validate-standards-yaml`.

### Article II — BDD

Not user-facing at the runtime level. Stack templates are deployment
artefacts. **No BDD scenarios required**. The harness's L1 layer
(template-presence + parse + key-anchor assertions) is the
test-strategy equivalent.

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-OTEL-*`
namespace before any template ships. `/forge:design` ratifies the
sampler-overlay mechanism + OBI / Coroot pin versions before
`/forge:implement`.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Open questions captured below ; resolved before status flips to
`implemented`.

### Article V — Audit Trail

Each task tagged `[Story: FR-OTEL-XXX]` (Article V.1). Standard
`observability.yaml` realised by these manifests, not amended.

### Article VIII — Infrastructure

The privileged DaemonSet is a **first-class Article VIII concern**
(infrastructure code under spec). The Aegis audit annotation
discharges the security review duty at deployment time ; the
template itself ships with `privileged: true` only on OBI, never
on application pods.

### Article IX — Observability

This is the change that **realises** Article IX (three signals :
traces, metrics, logs) at the manifest level on the flagship.
SigNoz already there ; this change adds OBI + Coroot to complete
the triplet.

### Article XII — Governance

`observability.yaml` v1.0.0 unchanged — REVIEW.md ledger needs
**no new entry** (additive realisation does not constitute a
review event per the standard's lifecycle rules). Future bumps
to `observability.yaml` (e.g. when OBI graduates or Coroot
forks) will trigger a review entry per `global/standards-lifecycle.md`.

## Open Questions

[NEEDS CLARIFICATION: Sampler configuration mechanism — should the
`parentbased_traceidratio` ratio live in the OTel collector
`processors.tail_sampling` block (post-collection sampling, more
flexible) or in the SDK init (head-based sampling, lower
collector-side cost) ? `observability.yaml` doesn't mandate a
location. Lean toward **collector-side via tail_sampling** because
it preserves the head-based default of `parentbased` while letting
the env-tier ratio be patched by Kustomize without touching app
images. Resolve at `/forge:design`.]

[NEEDS CLARIFICATION: Image pin policy — should OBI and Coroot
images be pinned to a specific upstream tag in the templates, or
left as `:latest` with a note in `CLAUDE.md` to override per
deployment ? Lean toward **exact pin** with the version recorded in
`observability.yaml::versions` (analogous to T.5's
`transport.yaml::codegen.versions`). Resolve at `/forge:design`
after Context7 + upstream Helm chart inspection.]

[NEEDS CLARIFICATION: Should this change also bump
`observability.yaml` to `1.1.0` to record the OBI / Coroot image
pins, or leave the standard at `1.0.0` and pin via Kustomize patches
only ? Lean toward **bump to 1.1.0** for symmetry with T.5's
`transport.yaml` 1.0.0 → 1.1.0 pattern (codegen pinning was the
T.5 trigger ; image pinning is the analogue here). Adds a REVIEW.md
`Updated` ledger entry. Resolve at `/forge:design`.]
