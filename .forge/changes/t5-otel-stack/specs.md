# Specifications: t5-otel-stack
<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-OTEL-*` / `NFR-OTEL-*`. **Constitution** : v1.1.0.
Pas d'amendement requis.

## Source Documents

| Field             | Value                                                                                                                                            |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| **ADR base**      | `t4-adr-ratification` archived 2026-05-04 (FR-T4-ADR-008 ratifying ADR-008 + FR-T4-STD-003 ratifying `observability.yaml` v1.0.0)                |
| **Plan ref**      | `docs/new-archetypes-plan.md` §15 item #2 ("Lancer Phase 1 OTel + OBI + Coroot stack — templates K8s/compose")                                   |
| **Roadmap ref**   | `.forge/product/roadmap.md` Phase 3 / T5 row § "Still pending in T5 : OTel + OBI + Coroot stack templates"                                       |
| **Standard ref**  | `.forge/standards/observability.yaml` v1.0.0 (sdk + ebpf_complement + service_map + backend + sampler + ratios + kernel_min + deployment_constraints) |
| **Pattern reuse** | `b1-delivery` archived 2026-04-29 (existing `signoz-config.yaml.tmpl` + `otel-collector-config.yaml.tmpl` + Kustomize base/overlays layout)        |
| **Deferred test** | `t5-connect-codegen/tasks.md` § "DEFERRED 2026-05-06" — `_test_t5_l2_traceparent_dual` waiting on this stack to land before re-enabling          |

No new external standard or document is pinned. The OBI / Coroot
upstream Helm charts are referenced via Context7 lookup at design
time (Q-002 below).

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — OBI eBPF DaemonSet manifest (FR-OTEL-001 → 010)

##### FR-OTEL-001 — Manifest file exists

`.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl`
MUST exist as a Kubernetes `DaemonSet` manifest.

##### FR-OTEL-002 — `kind: DaemonSet`

`spec.template.spec` MUST carry the privileged eBPF agent
container ; `kind: DaemonSet` not `Deployment` (eBPF requires
per-node attachment).

##### FR-OTEL-003 — Privileged security context

`securityContext.privileged: true` set on the OBI container ; OR
explicit Linux capabilities `add: [SYS_ADMIN, BPF, PERFMON]` (the
non-privileged form preferred when kernel ≥ 5.8 supports BPF
capability).

##### FR-OTEL-004 — `hostPID: true` + `hostNetwork: true`

Pod-level. Required for cross-cgroup tracing.

##### FR-OTEL-005 — Kernel min nodeSelector

`nodeSelector` or `affinity` MUST gate scheduling on
`kubernetes.io/os: linux` AND a label expressing kernel ≥ 5.8 (e.g.
`forge.dev/kernel-min-58: "true"` — node-side label opt-in).

##### FR-OTEL-006 — OTel exporter target

OBI exporter env var (`OTEL_EXPORTER_OTLP_ENDPOINT` or upstream
equivalent) MUST point to the local OTel collector
(`fsm-otel-collector:4317` per the existing collector service
naming).

##### FR-OTEL-007 — Image pin

Container image MUST be pinned to an exact upstream tag
(Q-002 resolution at design time). `:latest` is **forbidden**.

##### FR-OTEL-008 — RBAC ServiceAccount

The DaemonSet MUST bind a dedicated `ServiceAccount` (e.g.
`fsm-obi`) ; cluster-scoped permissions MUST be the minimum needed
(read pods + nodes), not `cluster-admin`.

##### FR-OTEL-009 — Resource limits

`resources.requests` + `resources.limits` MUST be present. Defaults
informed by upstream OBI Helm chart at design time.

##### FR-OTEL-010 — Annotation for Aegis audit

`metadata.annotations["forge.dev/aegis-audit"]: "required"` set on
the DaemonSet, surfacing the privileged review duty to deployment
tooling.

---

#### Cluster 2 — Coroot deployment manifest (FR-OTEL-020 → 023)

##### FR-OTEL-020 — Manifest file exists

`.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl`
MUST exist with `kind: Deployment` (not DaemonSet — Coroot is a
single-replica service-map ingester).

##### FR-OTEL-021 — Image pin

Container image MUST be pinned to an exact upstream tag
(Q-002 resolution).

##### FR-OTEL-022 — Service + ConfigMap

A sibling `Service` (ClusterIP, name `fsm-coroot`, port 8080) AND
a `ConfigMap` carrying the Coroot config MUST be templated alongside
the Deployment. May live in the same file (multi-doc YAML) or
separate files at design discretion.

##### FR-OTEL-023 — OTel collector wiring

The Coroot config MUST point its trace ingestion endpoint at the
local OTel collector (`fsm-otel-collector:4317`).

---

#### Cluster 3 — Sampler `parentbased_traceidratio` config (FR-OTEL-030 → 035)

##### FR-OTEL-030 — Sampler in OTel collector pipeline

`infra/observability/otel-collector-config.yaml.tmpl` MUST gain a
sampler stage. The exact mechanism (collector-side
`processors.tail_sampling` vs SDK-side `--sampler` flag) is locked
at design time (Q-001).

##### FR-OTEL-031 — Default ratio in template

The base template MUST set the sampler ratio to `1.0` (always
sample) so `dev` is the implicit default. Env-tier overlays override
for `staging` / `prod`.

##### FR-OTEL-032 — Prod overlay patch

`infra/k8s/overlays/prod/sampler-patch.yaml.tmpl` MUST exist and
patch the OTel collector ConfigMap to set the sampler ratio to
`0.1` per `observability.yaml::ratios.prod`.

##### FR-OTEL-033 — Staging overlay patch

`infra/k8s/overlays/staging/sampler-patch.yaml.tmpl` MUST exist and
patch to ratio `1.0` per `observability.yaml::ratios.staging`.
(Same as dev, but the patch is shipped explicitly so the overlay
intent is documented.)

##### FR-OTEL-034 — Dev overlay no-op or matching patch

`infra/k8s/overlays/dev/sampler-patch.yaml.tmpl` MUST either : (a)
exist as an explicit `1.0` patch for symmetry, OR (b) be **omitted**
because the base template already defaults to `1.0`. Locked at
design time. Symmetry preferred unless it duplicates literal YAML.

##### FR-OTEL-035 — Sampler type is `parentbased_traceidratio`

Whichever mechanism is chosen (collector vs SDK), the configured
sampler type MUST be exactly `parentbased_traceidratio` per
`observability.yaml::sampler`. No deviation (e.g. `traceidratio`
without parent-context semantics) accepted.

---

#### Cluster 4 — Aegis privileged DaemonSet documentation (FR-OTEL-040 → 041)

##### FR-OTEL-040 — `infra/CLAUDE.md.tmpl` warning section

`.forge/templates/archetypes/full-stack-monorepo/infra/CLAUDE.md.tmpl`
MUST gain a `## Privileged DaemonSet — Aegis audit required` H2
section enumerating : (1) the OBI DaemonSet's `privileged: true` /
`hostPID` / `hostNetwork` requirements, (2) `observability.yaml::deployment_constraints.aegis_audit_required_for_prod: true`,
(3) a one-line opt-out path (skip OBI for T1 environments where
eBPF kernel ≥ 5.8 is not guaranteed).

##### FR-OTEL-041 — `infra/k8s/base/README.md.tmpl` checklist

`.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/README.md.tmpl`
MUST gain a `## Deployment prerequisites` checklist mentioning :
- Kernel ≥ 5.8 on all worker nodes.
- Aegis security review for `obi-daemonset.yaml` before any
  production rollout.
- `forge.dev/kernel-min-58: "true"` node label set on eligible
  nodes.

---

#### Cluster 5 — Example mirror (FR-OTEL-050)

##### FR-OTEL-050 — `examples/forge-fsm-example/` parity

The same six template-rendered files (`obi-daemonset.yaml`,
`coroot-deployment.yaml`, the modified
`otel-collector-config.yaml`, the three overlay patches) MUST be
mirrored under `examples/forge-fsm-example/infra/` (without `.tmpl`
extension, fully rendered with example placeholder values per the
existing mirror convention from B.1.14 + C.1).

---

#### Cluster 6 — Test harness `t5-otel.test.sh` (FR-OTEL-060 → 062)

##### FR-OTEL-060 — Harness exists

`.forge/scripts/tests/t5-otel.test.sh` MUST exist mirroring the
J.7 / T.5 harness layout (bash header, `_helpers.sh` source,
PASS/FAIL counters, `--level 1,2` parsing, `print_summary`).

##### FR-OTEL-061 — L1 coverage ≥ 12 tests

Minimum 12 L1 tests covering :
- 4 OBI DaemonSet shape tests (file exists + parses + privileged
  context + nodeSelector kernel-min + image pinned).
- 3 Coroot manifest tests (deployment + service + image pinned).
- 3 sampler tests (sampler stanza in collector base + 2-or-3
  overlay patches with correct ratios + sampler type
  `parentbased_traceidratio`).
- 1 Aegis warning test (`infra/CLAUDE.md.tmpl` H2 section
  present).
- 1 example mirror test (parity check : every `.tmpl` has a
  matching rendered file under `examples/forge-fsm-example/`).

##### FR-OTEL-062 — L2 fixtures (none in this change)

Fixture-level testing of `kustomize build` + actual Kubernetes
manifest validation (e.g. `kubeconform` lint) is **deferred** to a
follow-up change. This change ships L1 only ; the harness L2 phase
is intentionally empty (signposted in the manifest comment).

---

#### Cluster 7 — CI registration (FR-OTEL-070)

##### FR-OTEL-070 — `forge-ci.yml` matrix entry

`.github/workflows/forge-ci.yml` `harness` job MUST register
`t5-otel.test.sh` immediately after `j7.test.sh` with `--level 1`.

---

#### Cluster 8 — Documentation (FR-OTEL-080 → 082)

##### FR-OTEL-080 — `observability.yaml` realisation note

`.forge/standards/observability.yaml` body comment MUST gain a
trailing `# Realisation: t5-otel-stack (2026-05-08) — OBI/Coroot
manifests + sampler overlays.` line. **Whether** the standard's
`version` bumps from 1.0.0 to 1.1.0 is locked at design time
(Q-003).

##### FR-OTEL-081 — `docs/ARCHETYPES.md` row update

The flagship row in `docs/ARCHETYPES.md` MUST gain a one-line
mention that the observability stack ships OBI + Coroot
manifests in addition to the SigNoz config already shipped at
B.1.14.

##### FR-OTEL-082 — `CHANGELOG.md` entry

`CHANGELOG.md` MUST gain an entry under `## [Unreleased]`
flagging : OBI DaemonSet, Coroot deployment, sampler env-tier
overlays, Aegis audit annotations.

---

### Non-Functional Requirements

#### NFR-OTEL-001 — Snapshot tarball budget

After regenerating
`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
post-impl, the size MUST stay ≤ 600 KB gzipped (current baseline
422 KB, T.5 raised it to ~ 470 KB ; this change adds ≈ 80 KB of
manifests, conservative budget 600 KB).

#### NFR-OTEL-002 — Backward compatibility (forge upgrade)

`forge upgrade` (A.7) MUST 3-way-merge the new manifests cleanly
into adopter trees that scaffolded under `1.0.0` pre-T5-OTEL.
Adopters who already hand-rolled their own observability tree
get conflict markers on the changed paths but no destructive
overwrite.

#### NFR-OTEL-003 — Article V audit trail

Every task in `tasks.md` MUST carry a `[Story: FR-OTEL-XXX]` tag.

#### NFR-OTEL-004 — No new app-side dependency

This change MUST NOT introduce any new Rust crate, npm package, or
Dart package. Pure infra-side templates. SDK instrumentation is a
future Phase B change.

#### NFR-OTEL-005 — Performance budget

Harness `t5-otel.test.sh --level 1` MUST complete in ≤ 5 s
wall-clock. No K8s cluster spin-up at L1 — pure file presence +
YAML-parse + key-anchor checks.

---

## BDD Acceptance Criteria

Stack templates are deployment artefacts (not user-runtime). No
runtime BDD scenarios. The L1 harness assertions ARE the
acceptance criteria — each FR has a matching test described in
`tasks.md` with `[Story: FR-OTEL-XXX]` linkage.

---

## Anti-Hallucination Pass

For each FR :

- **Testable** : every FR is asserted by at least one test in
  `t5-otel.test.sh` (mapping captured in `tasks.md` during
  `/forge:plan`).
- **Unambiguous** : 3 ambiguities flagged below as
  `[NEEDS CLARIFICATION:]` for `/forge:design` resolution.
- **Constitution-compliant** : Articles I (TDD), III (specs first),
  V (audit trail), VIII (infra-as-code), IX (observability), XII
  (governance) — all honored. No violation.

---

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`specs.md`. Three open questions Q-001 + Q-002 + Q-003 raised at
the proposal phase, all tracked in `open-questions.md` and resolved
during `/forge:design` :

- **Q-001** (FR-OTEL-030, sampler location) → ADR-OTEL-001 locks
  collector-side `processors.probabilistic_sampler` (`mode:
  proportional`, `attribute_source: traceID`, `hash_seed: 22`)
  after Context7 review of
  `/open-telemetry/opentelemetry-collector-contrib`.
- **Q-002** (FR-OTEL-007 / FR-OTEL-021, image pins) → ADR-OTEL-002
  locks `grafana/beyla:2.0.1` + `coroot/coroot:1.4.4` after Context7
  review of `/grafana/beyla` + `/coroot/coroot`, both > 30 days
  old at design time (no waiver needed).
- **Q-003** (FR-OTEL-080, standard bump) → ADR-OTEL-003 locks
  `observability.yaml` 1.0.0 → 1.1.0 (additive, `versions:` block,
  symmetric with T.5 `transport.yaml` 1.0.0 → 1.1.0). REVIEW.md
  ledger entry shipped.
