# Tasks: t5-otel-stack
<!-- Status: archived -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-OTEL-XXX]` (Article V.1) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/t5-otel.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms expected
  counter movement.
- ADRs from `design.md` are honored verbatim ; deviations require
  a new ADR.
- Concrete pins (`grafana/beyla:2.0.1`, `coroot/coroot:1.4.4`)
  resolved in `design.md` ADR-OTEL-002 ; impl Phase 1 only
  re-confirms drift.

---

## Phase 1 — Foundation : version drift + RED harness + standard prep

Goal : pins re-confirmed (no drift since 2026-05-08), `t5-otel.test.sh`
exists with **14 L1 stubs all FAIL**, full RED state captured,
`observability.yaml` bump prep ready.

### T-VER — Toolchain version resolution (ADR-OTEL-002 / FR-OTEL-007 / FR-OTEL-021)

> **Versions resolved at design phase 2026-05-08/09** post-Context7
> investigation. Phase 1 re-confirms drift the same day for the same
> pins → mathematically a no-op, marked [x] on archive day if the
> archive runs same-day. If `/forge:implement` re-runs after a
> non-trivial gap, T-VER tasks become real drift checks.

- [x] **T-VER-001** : `grafana/beyla:2.0.1` confirmed (Context7
      `/grafana/beyla` 2026-05-08, > 30 days old per ADR-T5-002 #1).
      Same-day at archive → no-op. [Story: FR-OTEL-007]
- [x] **T-VER-002** [P] : `coroot/coroot:1.4.4` confirmed (Context7
      `/coroot/coroot` 2026-05-08, > 30 days old). Same-day at
      archive → no-op. [Story: FR-OTEL-021]

### T-PHA — t5-otel.test.sh skeleton (RED for the whole change)

- [x] **T-PHA-001** : Create `.forge/scripts/tests/t5-otel.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`, source `_helpers.sh`), PASS/FAIL counters
      reset, `--level 1,2` parsing, `print_summary` close-out.
      Mirror the j7.test.sh layout. [Story: FR-OTEL-060]
- [x] **T-PHA-002** : Add **14 L1 test stubs** returning
      `_not_implemented` covering the 12 FR-OTEL checkpoints +
      example-mirror + standard-bump :
      - 7 OBI DaemonSet (FR-OTEL-001..010 collapsed into 7 anchors)
      - 2 Coroot manifests (FR-OTEL-020/021)
      - 2 Sampler base + prod overlay (FR-OTEL-030/032/035)
      - 1 Aegis warning (FR-OTEL-040/041)
      - 1 example mirror (FR-OTEL-050)
      - 1 standard bump + REVIEW.md ledger (FR-OTEL-080)
      [Story: FR-OTEL-061]
- [x] **T-PHA-003** [P] : Register `t5-otel.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `j7.test.sh` with `--level 1`.
      [Story: FR-OTEL-070]
- [x] **T-PHA-004** : RED gate confirmed —
      `bash .forge/scripts/tests/t5-otel.test.sh > /tmp/t5-otel-red.log 2>&1` ;
      `bash exit: 1` ; `Failed: 14 / Passed: 0` ; all stubs report
      `not implemented (RED witness)`. [Story: FR-OTEL-061]

**Phase 1 exit gate** : `t5-otel.test.sh` exits 1 with `FAIL ≥ 14`,
`forge-ci.yml` matrix updated, no production code shipped yet.
constitution-linter.sh OVERALL PASS.

---

## Phase 2 — Core : OBI + Coroot manifests + standard bump

Goal : the two K8s manifests + the standard bump ship. After this
phase, 7 OBI tests + 2 Coroot tests + 1 standard test flip GREEN.

### T-OBI — OBI eBPF DaemonSet (FR-OTEL-001..010)

- [x] **T-OBI-001** : RED witness — convert `_test_otel_001_obi_exists`
      to assert file presence at the template path. Capture
      `/tmp/t5-otel-red-obi.log`. [Story: FR-OTEL-001]
- [x] **T-OBI-002** : Create
      `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl`
      with the **unprivileged-with-capabilities** form per
      ADR-OTEL-004 :
      - `kind: DaemonSet` (FR-OTEL-002)
      - `hostPID: true` + `hostNetwork: true` (FR-OTEL-004)
      - `nodeSelector: forge.dev/kernel-min-58: "true"`
        (FR-OTEL-005, ADR-OTEL-007)
      - `image: grafana/beyla:2.0.1` (FR-OTEL-007)
      - `imagePullPolicy: IfNotPresent`
      - `securityContext.runAsUser: 0` +
        `readOnlyRootFilesystem: true` +
        `capabilities.add: [BPF, SYS_PTRACE, NET_RAW,
        CHECKPOINT_RESTORE, DAC_READ_SEARCH, PERFMON, NET_ADMIN,
        SYS_ADMIN]` (FR-OTEL-003)
      - `env.OTEL_EXPORTER_OTLP_ENDPOINT:
        "http://fsm-otel-collector:4318"` (FR-OTEL-006)
      - `env.BEYLA_KUBE_METADATA_ENABLE: "autodetect"`
      - `resources.requests` + `resources.limits` (FR-OTEL-009 ;
        defaults from Beyla docs)
      - `metadata.annotations["forge.dev/aegis-audit"]: "required"`
        (FR-OTEL-010)
      - `volumeMounts` for `/sys/fs/cgroup` (read-only) + ephemeral
        `/var/run/beyla`
      - `tolerations: [{operator: Exists}]` so the DaemonSet runs
        on all schedulable nodes that match the kernel-min label.
      [Story: FR-OTEL-001..010]
- [x] **T-OBI-003** [P] : Create the dedicated
      `ServiceAccount` + `ClusterRole` + `ClusterRoleBinding` for
      `fsm-obi` (FR-OTEL-008). Multi-doc YAML inside the same file
      (`---` separators), or a sibling
      `obi-rbac.yaml.tmpl` — pick at impl time, prefer single-file
      grouping for visual proximity. Permissions :
      `pods` (get/list/watch) + `nodes` (get/list/watch) +
      `replicasets` (get/list/watch).
      [Story: FR-OTEL-008]
- [x] **T-OBI-004** : Register the new manifest in
      `infra/k8s/base/kustomization.yaml.tmpl` `resources:` list.
      [Story: FR-OTEL-001 / ADR-OTEL-005]
- [x] **T-OBI-005** : Run `t5-otel.test.sh` ; expect 7 OBI tests
      flip GREEN (file presence + kind + caps + host* + nodeSelector
      + image + Aegis annotation). [Story: FR-OTEL-001..010]

### T-COR — Coroot deployment (FR-OTEL-020..023)

- [x] **T-COR-001** : RED witness — convert
      `_test_otel_020_coroot_exists`. [Story: FR-OTEL-020]
- [x] **T-COR-002** : Create
      `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl`
      as **multi-doc YAML** (per ADR-OTEL-006) :
      - `kind: Deployment`, single replica, `image:
        coroot/coroot:1.4.4` (FR-OTEL-021)
      - `kind: Service`, `ClusterIP`, name `fsm-coroot`,
        port `8080` (FR-OTEL-022)
      - `kind: ConfigMap`, name `fsm-coroot-config`, key
        `config.yaml`, OTLP gRPC endpoint pointing to
        `fsm-otel-collector:4317` (FR-OTEL-023)
      - Coroot config minimal : `listen: 0.0.0.0:8080`,
        `data_dir: /data`, OTel ingestion settings.
      - `volumes` + `volumeMounts` for the ConfigMap and a
        `PersistentVolumeClaim` placeholder for `/data` (or
        `emptyDir` for local-dev — choose `emptyDir` to keep the
        template HA-agnostic, with a comment pointing to the PVC
        upgrade path).
      [Story: FR-OTEL-020..023]
- [x] **T-COR-003** : Register the new manifest in
      `infra/k8s/base/kustomization.yaml.tmpl` `resources:`.
      [Story: FR-OTEL-020 / ADR-OTEL-005]
- [x] **T-COR-004** : Run `t5-otel.test.sh` ; expect 2 Coroot tests
      flip GREEN. [Story: FR-OTEL-020..023]

### T-STD — observability.yaml 1.0.0 → 1.1.0 + REVIEW.md (FR-OTEL-080)

- [x] **T-STD-001** : RED witness — convert
      `_test_otel_080_standard_bumped` to assert
      `version: "1.1.0"` AND `versions.beyla: "2.0.1"` AND
      `versions.coroot: "1.4.4"` AND a matching `Updated` row in
      `REVIEW.md` (table-row regex per FR-J7-023 / ADR-J7-003).
      [Story: FR-OTEL-080]
- [x] **T-STD-002** : Edit `.forge/standards/observability.yaml` :
      bump `version: "1.0.0"` → `"1.1.0"`. Append header comment
      block extending the audit trail (T.5 reference + change
      summary). Add `versions:` block under `forbidden:` with the
      two pins. Keep `last_reviewed` and `expires_at` unchanged
      (additive bump per ADR-OTEL-003).
      [Story: FR-OTEL-080 / ADR-OTEL-003]
- [x] **T-STD-003** : Append `Updated` entry to
      `.forge/standards/REVIEW.md` for `observability.yaml` v1.1.0
      dated 2026-05-09, schema canonical (Reviewer / Reviewed
      standards table / Decision = `KEEP-WITH-CHANGES` /
      `Next review due: 2027-05-04` unchanged / Notes referencing
      ADR-OTEL-002 + ADR-OTEL-003). 2026-05-04 baseline preserved
      (append-only).
      [Story: FR-OTEL-080]
- [x] **T-STD-004** : Run **j7.test.sh** to confirm the new
      `observability.yaml` v1.1.0 still validates against the J.7
      schema (FR-J7-001..010 + FR-J7-023 ledger drift) without
      regression. Expect 21/21 PASS unchanged.
      [Story: FR-OTEL-080 / NFR-OTEL-002]
- [x] **T-STD-005** : Run `t5-otel.test.sh` ; expect 1 standard
      test flip GREEN. [Story: FR-OTEL-080]

**Phase 2 exit gate** : `t5-otel.test.sh` `Passed: ≥ 10 / Failed: ≤ 4`
(7 OBI + 2 Coroot + 1 standard ; sampler + overlay + Aegis docs +
example mirror still RED). `verify.sh` aggregate up by ≈ 6 PASS
(2 new manifests in standards-yaml-schema gate + 4 verify side-effects).
constitution-linter.sh OVERALL PASS. j7.test.sh 21/21 PASS preserved.

---

## Phase 3 — Integration : sampler + overlays + example mirror

Goal : OTel collector sampler stanza ships, 3 overlay patches ship,
example mirror parity validated. After this phase, 4 remaining L1
tests flip GREEN (sampler base + prod overlay + Aegis docs + example
mirror).

### T-SAM — Sampler in OTel collector base (FR-OTEL-030/031/035)

- [x] **T-SAM-001** : RED witness — convert
      `_test_otel_030_sampler_base`. [Story: FR-OTEL-030]
- [x] **T-SAM-002** : Edit
      `.forge/templates/archetypes/full-stack-monorepo/infra/observability/otel-collector-config.yaml.tmpl`
      to insert `processors.probabilistic_sampler` block per
      ADR-OTEL-001 :

      ```yaml
      processors:
        memory_limiter:
          ...
        probabilistic_sampler:
          sampling_percentage: 100
          mode: proportional
          attribute_source: traceID
          hash_seed: 22
        batch:
          ...
      ```

      Insert the new processor between `memory_limiter` and `batch`
      (canonical pipeline order : limit → sample → batch). Update
      the `service.pipelines.traces.processors` list to include it
      after `memory_limiter` and before `batch`. Header comment
      block extended with the ADR-OTEL-001 reference. Other
      pipelines (metrics, logs) unchanged — sampling applies to
      traces only.
      [Story: FR-OTEL-030 / FR-OTEL-031 / FR-OTEL-035 / ADR-OTEL-001]
- [x] **T-SAM-003** : Run `t5-otel.test.sh` ; expect sampler base
      L1 test flip GREEN. [Story: FR-OTEL-030/031/035]

### T-OVL — Env-tier overlay patches (FR-OTEL-032..034)

- [x] **T-OVL-001** : RED witness — convert
      `_test_otel_032_overlay_prod`. [Story: FR-OTEL-032]
- [x] **T-OVL-002** [P] : Create
      `infra/k8s/overlays/prod/sampler-patch.yaml.tmpl` (strategic
      merge patch on the OTel collector ConfigMap) setting
      `sampling_percentage: 10`. Register the patch in the prod
      `kustomization.yaml.tmpl` under `patches:` (or `patchesStrategicMerge:`
      per upstream Kustomize naming).
      [Story: FR-OTEL-032]
- [x] **T-OVL-003** [P] : Create
      `infra/k8s/overlays/staging/sampler-patch.yaml.tmpl` setting
      `sampling_percentage: 100`. Register in staging
      `kustomization.yaml.tmpl`.
      [Story: FR-OTEL-033]
- [x] **T-OVL-004** [P] : Create
      `infra/k8s/overlays/dev/sampler-patch.yaml.tmpl` setting
      `sampling_percentage: 100` (explicit per ADR-OTEL-005, FR-OTEL-034
      option a). Register in dev `kustomization.yaml.tmpl`.
      [Story: FR-OTEL-034]
- [x] **T-OVL-005** : Run `t5-otel.test.sh` ; expect prod overlay
      L1 test flip GREEN. [Story: FR-OTEL-032]

### T-AEG — Aegis privileged DaemonSet documentation (FR-OTEL-040..041)

- [x] **T-AEG-001** : RED witness — convert
      `_test_otel_040_aegis_doc`. [Story: FR-OTEL-040]
- [x] **T-AEG-002** : Append `## Privileged DaemonSet — Aegis audit
      required` H2 section to
      `.forge/templates/archetypes/full-stack-monorepo/infra/CLAUDE.md.tmpl`
      enumerating : (1) the OBI DaemonSet's
      `hostPID + hostNetwork + capabilities` requirements,
      (2) `observability.yaml::deployment_constraints.aegis_audit_required_for_prod: true`,
      (3) opt-out path for T1 environments (skip OBI by removing
      from base kustomization), (4) opt-in privileged-form Kustomize
      patch for environments where the BPF capability is not
      reliable (kernel < 5.8 or older runtimes).
      [Story: FR-OTEL-040 / ADR-OTEL-004]
- [x] **T-AEG-003** [P] : Append `## Deployment prerequisites`
      checklist to
      `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/README.md.tmpl` :
      - Kernel ≥ 5.8 on all worker nodes.
      - Aegis security review for `obi-daemonset.yaml` before any
        production rollout.
      - `kubectl label node <name> forge.dev/kernel-min-58=true`
        on eligible nodes.
      [Story: FR-OTEL-041 / ADR-OTEL-007]
- [x] **T-AEG-004** : Run `t5-otel.test.sh` ; expect Aegis docs L1
      test flip GREEN. [Story: FR-OTEL-040/041]

### T-EX — Example mirror parity (FR-OTEL-050)

- [x] **T-EX-001** : RED witness — convert
      `_test_otel_050_example_mirror`. [Story: FR-OTEL-050]
- [x] **T-EX-002** [P] : Mirror `obi-daemonset.yaml.tmpl` (rendered
      form, no `.tmpl` suffix) into
      `examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`.
      [Story: FR-OTEL-050]
- [x] **T-EX-003** [P] : Mirror `coroot-deployment.yaml.tmpl` into
      `examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml`.
      [Story: FR-OTEL-050]
- [x] **T-EX-004** [P] : Mirror the modified
      `otel-collector-config.yaml.tmpl` into
      `examples/forge-fsm-example/infra/observability/otel-collector-config.yaml`
      (probabilistic_sampler stanza included).
      [Story: FR-OTEL-050]
- [x] **T-EX-005** [P] : Mirror the 3 overlay sampler-patch files
      into `examples/forge-fsm-example/infra/k8s/overlays/{dev,staging,prod}/sampler-patch.yaml`.
      [Story: FR-OTEL-050]
- [x] **T-EX-006** : Update the example's
      `infra/k8s/base/kustomization.yaml` + per-overlay
      `kustomization.yaml` files to register the new resources +
      patches. [Story: FR-OTEL-050]
- [x] **T-EX-007** : Run `t5-otel.test.sh` ; expect example mirror
      L1 test flip GREEN. [Story: FR-OTEL-050]

**Phase 3 exit gate** : `t5-otel.test.sh` 14/14 GREEN, 0 FAIL,
≤ 5 s wall-clock (NFR-OTEL-005). `verify.sh` aggregate increased
without any new FAIL. `constitution-linter.sh` OVERALL PASS.
`j7.test.sh` 21/21 unchanged. `validate-standards-yaml.sh`
exits 0 on the live tree (the bumped `observability.yaml` v1.1.0
is in REVIEW.md ledger).

---

## Phase 4 — Quality : docs (broader) + snapshot + CI gate + review

### T-DOC — Documentation (FR-OTEL-081..082)

- [x] **T-DOC-001** [P] : Update the flagship row in
      `docs/ARCHETYPES.md` to mention the OBI + Coroot manifests
      shipping with the observability stack.
      [Story: FR-OTEL-081]
- [x] **T-DOC-002** [P] : Add an entry under `## [Unreleased]` in
      `CHANGELOG.md` flagging :
      - OBI eBPF DaemonSet (`grafana/beyla:2.0.1`).
      - Coroot deployment (`coroot/coroot:1.4.4`).
      - OTel collector `probabilistic_sampler` (proportional, traceID
        anchor, hash_seed 22).
      - 3 env-tier sampler-patch overlays (dev/staging/prod).
      - `observability.yaml` 1.0.0 → 1.1.0 with `versions:` pins.
      - `infra/CLAUDE.md` Privileged DaemonSet — Aegis audit section.
      [Story: FR-OTEL-082]

### T-SNP — Snapshot tarball regeneration (NFR-OTEL-001)

- [x] **T-SNP-001** : Run the existing snapshot regeneration script
      (`bin/forge-snapshot.sh full-stack-monorepo 1.0.0` or
      equivalent per project conventions) to refresh
      `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      with the new templates. [Story: NFR-OTEL-001]
- [x] **T-SNP-002** : Verify size ≤ 600 KB gzipped (T.5 baseline ≈
      470 KB + ~ 80 KB this change). Capture `du -h` output as
      evidence. [Story: NFR-OTEL-001]
- [x] **T-SNP-003** : Run `a7.test.sh` to confirm `forge upgrade`
      3-way merge still works against the regenerated snapshot.
      Expect no regression. [Story: NFR-OTEL-002]

### T-CI — CI registration finalisation

- [x] **T-CI-001** : Confirm `t5-otel.test.sh` is in the
      `forge-ci.yml` `harness` job matrix (registered in T-PHA-003).
      [Story: FR-OTEL-070]
- [x] **T-CI-002** : Run `verify.sh` locally ; expect aggregate
      counter to grow without regression vs the j7-merged baseline
      (138 PASS post-J.7 merge ; this change adds ~ 6 PASS).
      [Story: NFR-OTEL-002]
- [x] **T-CI-003** : Run `constitution-linter.sh` ; expect OVERALL
      PASS (the 5 pre-existing T.5 transport-codegen-coverage WARN
      are acceptable per ADR-T5-005 ; no new WARN expected).
      [Story: NFR-OTEL-002]

### T-REV — Quality review gate

- [x] **T-REV-001** : Run `/forge:review t5-otel-stack` driving
      the constitutional gate review : Articles I (TDD), III + III.4
      (specs first + open questions resolved), IV (delta — additive
      bump 1.0.0 → 1.1.0), V (audit trail), VIII (infra), IX
      (observability — three signals realised), X (gate coverage),
      XII (governance — amendment-versioning preserved). Block if
      any returns VIOLATION. [Story: Article V]
- [x] **T-REV-002** : Run the full `verify.sh` once more on a clean
      checkout to confirm reproducibility. [Story: NFR-OTEL-002]
- [x] **T-REV-003** : Verify
      `bin/forge-questions.sh --change t5-otel-stack --status open`
      returns empty (Q-001..Q-003 all answered post-design).
      [Story: Article III.4]

**Phase 4 exit gate (= change archival readiness)** :

- `t5-otel.test.sh --level 1` : 14/14 PASS, 0 FAIL, ≤ 5 s.
- `verify.sh` aggregate ≥ baseline + 6 PASS / 0 FAIL / RESULT: PASS.
- `constitution-linter.sh` OVERALL PASS (no new WARN).
- `j7.test.sh` 21/21 PASS unchanged.
- `validate-standards-yaml.sh` against the live tree exits 0
  (bumped `observability.yaml` v1.1.0 validated, REVIEW.md ledger
  drift gate satisfied).
- `forge-questions.sh --status open --change t5-otel-stack` empty.
- Snapshot tarball ≤ 600 KB.
- All FR-OTEL-001..082 + NFR-OTEL-001..005 tasks checked.
- `CHANGELOG.md` entry under `## [Unreleased]`.
- `docs/ARCHETYPES.md` flagship row updated.

---

## Constitutional task review (per Article V)

For each task family, verifying TDD compliance + spec linkage +
architecture preservation :

| Task family | TDD order                                    | Spec link                          | Architecture                                  |
|-------------|----------------------------------------------|------------------------------------|-----------------------------------------------|
| T-VER-*     | N/A (resolution work, no code)               | FR-OTEL-007 / FR-OTEL-021          | ADR-OTEL-002                                  |
| T-PHA-*     | RED phase (intentional)                      | FR-OTEL-060..061 / FR-OTEL-070     | N/A                                           |
| T-OBI-*     | RED witness before each manifest field       | FR-OTEL-001..010                   | ADR-OTEL-004 (unprivileged) + ADR-OTEL-007    |
| T-COR-*     | RED witness then multi-doc YAML              | FR-OTEL-020..023                   | ADR-OTEL-006 (multi-doc structure)            |
| T-STD-*     | RED witness then standard bump               | FR-OTEL-080                        | ADR-OTEL-003 (1.0.0 → 1.1.0 additive)         |
| T-SAM-*     | RED witness then sampler stanza              | FR-OTEL-030/031/035                | ADR-OTEL-001 (probabilistic_sampler)          |
| T-OVL-*     | RED witness then per-overlay patch           | FR-OTEL-032..034                   | ADR-OTEL-005 (overlay structure)              |
| T-AEG-*     | RED witness then docs section                | FR-OTEL-040..041                   | ADR-OTEL-004 (Aegis duty surfaced)            |
| T-EX-*      | RED witness then example mirror parity       | FR-OTEL-050                        | C.1 example convention preserved              |
| T-DOC-*     | No code, doc-only                            | FR-OTEL-081..082                   | docs/ARCHETYPES.md + CHANGELOG conventions    |
| T-SNP-*     | RED witness then snapshot regen              | NFR-OTEL-001..002                  | upgrade-policy standard (A.7)                 |
| T-CI-*      | Validation only                              | FR-OTEL-070 / NFR-OTEL-002         | forge-self-ci standard (G.1)                  |
| T-REV-*     | Final gate, no production code               | Article V / III.4 / VIII / IX / XII | All articles                                 |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement`.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 6     | 2                    | 14 stubs      |
| 2     | 14    | 2                    | 4 (per cluster) |
| 3     | 17    | 8                    | 4 (per cluster) |
| 4     | 9     | 2                    | 0 (validation only) |
| **Total** | **46** | **14** | **22 RED witnesses** |

Estimated wall-clock at single-developer pace : Phase 1 ≈ 1 h,
Phase 2 ≈ 2–3 h, Phase 3 ≈ 2–3 h, Phase 4 ≈ 1 h. Total ≈ 6–8 h
of focused work, consistent with the **M** complexity estimate in
`proposal.md`.
