# Design: b6-6-helm

<!-- Status: designed -->
<!-- Schema: default -->
<!-- Audit: B.6.6 (docs/new-archetypes-plan.md §6.1 — production Helm Temporal cluster + Postgres backing, NATS JetStream cluster, T2/T3 self-host EU docs) -->

**Agents**: Atlas (K8s topology / Helm delivery framing) + Centurion (harness/TDD).
**Verify-then-pin**: chart pins resolved LIVE at implement (`helm show chart`),
overlays `helm template`-validated LIVE — see § Validation. No pin from memory.

---

## Architecture Decisions

### ADR-B6-HELM-001 — Chart-referenced hybrid (values overlay + docs), NOT a vendored chart

**Context**: the plan says "Templates Helm …". This repo ships **zero**
self-authored Helm charts (no `Chart.yaml` / `templates/*.yaml` / `values.yaml`
anywhere under `.forge/templates/`). The single production-service precedent —
B.8.7 Zitadel — installs from the **upstream** chart and vendors only a Forge
`values-forge.yaml.tmpl` overlay + docs, explicitly *"no raw K8s manifests, no
`kustomization.yaml.tmpl`"*, because the upstream chart carries operator-grade
machinery (Jobs, StatefulSets) that would need re-implementation if vendored.
B.8.4 Envoy uses the same "control plane via upstream chart (Atlas-provided)"
split under an `infra/k8s/<component>/` dir.

**Decision**: B.6.6 follows the Zitadel chart-referenced-hybrid convention.
Under `event-driven-eu/1.0.0/infra/k8s/` (the Envoy `infra/k8s/<component>/`
layout) each component ships a Forge **`values-forge.yaml.tmpl`** (the substantive
deliverable — the production tuning of the upstream chart) + a **`README.md.tmpl`**
(the Atlas-provided `helm install` recipe, ops, and T1/T2/T3 posture). No
`Chart.yaml`, no vendored raw manifests. An `infra/k8s/README.md.tmpl` indexes the
two components.

**Consequences**: faithful to the one production-service precedent; the
`values-forge.yaml` IS "the Helm chart" in this repo's idiom; zero re-implementation
of upstream Deployments/Jobs; the pin lives in the `helm install --version` line
(README) + the pinned `image.tag` in the overlay.

### ADR-B6-HELM-002 — Temporal on Postgres (chart 1.5.0 shape), not Cassandra

**Context**: LIVE `helm template` against `temporal/temporal 1.5.0` rejected two
legacy shapes with explicit validation errors:
- `'cassandra' is no longer a supported top-level key. The Cassandra sub-chart was
  removed in v1.0.0-rc.2. Configure Cassandra under
  server.config.persistence.datastores.`
- `'server.config.persistence.default' is no longer supported. Migrate to
  'server.config.persistence.datastores.<name>'.`

**Decision**: the overlay configures persistence purely under
`server.config.persistence.datastores.{default,visibility}.sql` with
`pluginName: postgres12`, `connectAddr: "<project-name>-temporal-db:5432"`,
`user: temporal_user`, `existingSecret: <project-name>-temporal-db` (password by
Secret, never inlined), plus `defaultStore: default` / `visibilityStore:
visibility` and `numHistoryShards: 512` (documented as immutable post-deploy). NO
top-level `cassandra:` key; NO `persistence.default` path.

**Consequences**: matches the plan's "Postgres backing"; renders clean on the
pinned chart; the two removed shapes are actively guarded in `b6-6.test.sh` T-005.

### ADR-B6-HELM-003 — NATS 3-node RAFT + JetStream file-store PVC; consumers are runtime

**Context**: LIVE `helm show values nats/nats 2.14.2` exposes
`config.cluster.{enabled,replicas}` (note: *"must be 2 or higher when jetstream is
enabled"*), `config.jetstream.{enabled,fileStore.{enabled,pvc.{enabled,size}}}`,
and `config.monitor.{enabled,port}`. JetStream **streams + durable consumers**
(incl. queue/work-queue groups for horizontal consumer scaling) are created at
**runtime** by the app / `nats` CLI — there is no static chart key for them.

**Decision**: enable `config.cluster` with `replicas: 3` (RAFT quorum),
`config.jetstream.fileStore.pvc` (persistence surviving restarts, RAFT-replicated
across the 3 nodes), and `config.monitor` (8222 `/healthz`). The README documents
durable-consumer / queue-group provisioning and cross-refs
`backend/events/src/consumer.rs`. No fabricated consumer chart key.

**Consequences**: satisfies "clustering, RAFT, persistence, consumer groups"
(plan §6.1 B.6.3/B.6.6) with real chart keys only; renders a 3-replica StatefulSet
with a JetStream PVC.

### ADR-B6-HELM-004 — Server pin ⟂ client-crate pin; no re-pin

**Context**: `backend/Cargo.toml.tmpl` pins `temporalio-sdk = "0.5.0"` /
`temporalio-client = "0.5.0"` — the **client** libraries the `saga` crate calls
(feature-gated OFF). The Helm chart pins the **server** (chart `1.5.0` / server
image `1.31.1`). These are orthogonal layers.

**Decision**: B.6.6 references the server pins only (chart `--version` + pinned
`server.image.tag`). No B.6.6 file introduces a `temporalio-sdk` /
`temporalio-client` / `async-nats` crate pin. The README notes the relationship
(client 0.5.0 in Cargo.toml talks to server 1.31.1) without re-pinning.
`b6-6.test.sh` T-007 guards both directions: Cargo.toml still pins `0.5.0`, and no
crate pin leaks into `infra/k8s/`.

---

## Deliverable Tree (impl)

```
event-driven-eu/1.0.0/infra/k8s/
├── README.md.tmpl                         # index + T2/T3 self-host EU intro (FR-B6-HELM-041)
├── temporal-cluster/
│   ├── values-forge.yaml.tmpl             # 4 roles + Postgres datastores (FR-B6-HELM-002/003/004/005)
│   └── README.md.tmpl                     # helm install + ops + T1/T2/T3 posture (FR-B6-HELM-001/040)
└── nats-jetstream/
    ├── values-forge.yaml.tmpl             # 3-node RAFT + JetStream PVC (FR-B6-HELM-021/022/023)
    └── README.md.tmpl                     # helm install + consumers/queue-groups + T1/T2/T3 (FR-B6-HELM-020/024/040)
```

All files: `.tmpl` extension, `<project-name>` placeholder, leading
`# <!-- Audit: B.6.6 (b6-6-helm, FR-B6-HELM-NNN) -->` (markdown READMEs use
`<!-- Audit: … -->`). All are `substitute: true` (they use `<project-name>`).

**Registrations**: 5 new rows in `event-driven-eu/scaffold-plan.yaml`
`templates:`; 1 line in `forge-ci.yml` (`"b6-6.test.sh --level 1"` after
`b6-2.test.sh`); accurate forward-reference wording in `infra/README.md.tmpl` +
`infra/CLAUDE.md.tmpl`; a CHANGELOG `[Unreleased] → ### Added` entry.

## Validation (LIVE at implement — Article III.4)

- `helm show chart temporal/temporal` → chart `1.5.0`, appVersion `1.31.1`.
- `helm show chart nats/nats` → chart `2.14.2`, appVersion `2.14.2`.
- `helm template t temporal/temporal -f <substituted temporal overlay>` → exit 0;
  6 Deployments (frontend/history/matching/worker server-deployments +
  admintools + web) with per-role replicas + a schema-setup Job; Postgres
  datastores rendered.
- `helm template n nats/nats -f <substituted nats overlay>` → exit 0; a
  StatefulSet `replicas: 3` + `volumeClaimTemplates` (JetStream PVC) + JetStream
  ConfigMap with 3 RAFT routes.

The `b6-6.test.sh` L2 (`--level 2`) re-runs these `helm template` renders when
`helm` is on PATH + the upstream repos are added; otherwise skip-pass (mirrors
`b8-4.test.sh` T-005). L1 is hermetic (structure/grep + a `yaml.safe_load` on the
substituted overlays), the CI level.

## `b6-6.test.sh` Test Strategy

**File**: `.forge/scripts/tests/b6-6.test.sh`. **Structure**: `--level` flag +
`_helpers.sh` `run_test` / `print_summary`, mirroring `b8-4.test.sh` / `b6-2.test.sh`.

| # | FR / NFR | Assertion |
|---|----------|-----------|
| T-001 | FR-B6-HELM-001/020/041 | `infra/k8s/` tree has the 5 expected `.tmpl` files (index README + 2 dirs × {values,README}) |
| T-002 | FR-B6-HELM-002 | Temporal overlay enables all four roles (`server.{frontend,history,matching,worker}`) |
| T-003 | FR-B6-HELM-003 | Temporal overlay: Postgres datastores (`persistence.datastores.default` + `visibility`, `pluginName: postgres12`, `existingSecret`) |
| T-004 | FR-B6-HELM-004/005 | `numHistoryShards` set + schema setup referenced (schema/admintools) |
| T-005 | ADR-B6-HELM-002 | Temporal overlay does NOT use removed shapes: no top-level `cassandra:` key, no `persistence.default:` path |
| T-006 | FR-B6-HELM-021/022/023 | NATS overlay: `config.cluster.enabled: true` + `replicas: 3`; `config.jetstream.enabled: true` + fileStore PVC; `config.monitor.enabled: true` |
| T-007 | NFR-B6-HELM-002 | No re-pin: no `temporalio-sdk`/`temporalio-client`/`async-nats` `= "X"` under `infra/k8s/`; AND `backend/Cargo.toml.tmpl` still pins `temporalio-sdk = "0.5.0"` |
| T-008 | NFR-B6-HELM-001 | Live pins single-sourced: temporal README carries chart `1.5.0` + server `1.31.1`; nats README carries chart+app `2.14.2` |
| T-009 | FR-B6-HELM-040/024 | Each README has a T1/T2/T3 posture section (grep `T2`,`T3`,`self-host`); nats README documents durable/queue-group consumers |
| T-010 | FR-B6-HELM-050 | scaffold-plan registers all 5 new sources; tree↔plan bijection intact (re-assert b6-2 T-002 logic locally) |
| T-011 | NFR-B6-HELM-003 | Secrets never committed: no plaintext `password:`/`token:` VALUE in the overlays (only `existingSecret`/`secretKeyRef` refs) |
| T-012 | NFR-B6-HELM-004 | Each `values-forge.yaml.tmpl`, `<project-name>`-substituted, is valid YAML (`yaml.safe_load`) |
| T-013 | NFR-B6-HELM-005 + coupling | schema stays `candidate`/`scaffoldable:false` AND `b6-2.test.sh --level 1` stays GREEN (exit-code coupling guard) |
| T-L2-001 | NFR-B6-HELM-001 | (L2, skip-pass) `helm template` each overlay against the upstream chart renders exit 0 when `helm` + repos present |

### TDD Order (Article I)
1. **RED**: commit `b6-6.test.sh` (13 L1 + 1 L2) before any template. T-001/002/…
   fail (no tree, no plan rows).
2. **GREEN**: author the overlays + READMEs + index, register in scaffold-plan +
   forge-ci, fix forward-references. Re-run → all GREEN; `b6-2` stays GREEN.
3. **REFACTOR**: tighten; confirm L2 render; confirm additive git diff.

## Constitutional Compliance Gate

- **I (TDD)**: harness RED-first before templates. ✅
- **III.1/2 (Specs before code)**: proposal→specs→design→tasks precede code. ✅
- **III.4 (Anti-Hallucination)**: pins verify-then-pin LIVE; every values key from
  `helm show values`; overlays `helm template`-validated; removed
  cassandra/persistence.default shapes avoided. ✅
- **IV (Delta)**: additive under `infra/k8s/`; dev backbone + Cargo.toml
  byte-unchanged (bar accurate forward-ref wording). ✅
- **VIII.2 (Temporal)**: production Temporal cluster realizes §VIII.2 for
  event-driven-eu. ✅
- **VIII.3/VIII.5 (containers/IaC)**: version-controlled infra; runtime posture is
  the upstream chart's distroless/hardened images. ✅
- **X (quality)**: harness gates the brick; no TODO/secret leakage. ✅

**No violations. Gate PASS** (independent review before merge — not self-approved).

## Open Items / [NEEDS CLARIFICATION]
- **None blocking.** Chart pins verified LIVE; both overlays render clean. Storage
  class + replica counts + resource requests are deployment-specific and left as
  documented, overridable values (production sizing is the adopter's cluster
  decision), not fabricated absolutes.
