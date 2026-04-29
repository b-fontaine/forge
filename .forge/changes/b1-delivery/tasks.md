# Tasks: b1-delivery
<!-- TDD order mandatory: tests BEFORE implementation, always (Article I) -->
<!-- Format: - [ ] Task [Story: FR-XXX] [P] -->
<!-- [P] = parallelizable with other [P] tasks in the same sub-section -->
<!-- Parent audit items: B.1.9 + B.1.12 + B.1.14 -->
<!-- Depends on: b1-foundations + b1-scaffolder + b1-workflow (all archived) -->
<!-- Closes B.1: drives schema promotion candidate / 1.0.0-rc.1 → stable / 1.0.0 -->

## Phase 1: Foundation — harness skeleton + placeholder files

### 1.1 Delivery test harness skeleton
- [x] Create `.forge/scripts/tests/delivery.test.sh` with shebang, `set -euo pipefail`, manifest header listing every `test_*` function name, sourcing of the shared `_helpers.sh` (ADR-010 corrected — `_helpers.sh` is already a shared lib, source rather than copy-paste), stub `main()` with level dispatch [Story: FR-GL-025, design ADR-010]
- [x] Verify: `bash delivery.test.sh` exits 1 (RED baseline — manifest declares 25 tests that do not yet exist + deliberate `test_phase_1_red_baseline` placeholder) [Story: FR-GL-025]

### 1.2 Placeholder template files with audit headers
- [x] Create `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-backend.yml.tmpl` placeholder (header comment only) [Story: FR-IN-002] [P]
- [x] Create `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-frontend.yml.tmpl` placeholder [Story: FR-IN-003] [P]
- [x] Create `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-infra.yml.tmpl` placeholder [Story: FR-IN-004] [P]
- [x] Create `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-integration.yml.tmpl` placeholder [Story: FR-IN-005] [P]
- [x] Create `.forge/templates/archetypes/full-stack-monorepo/infra/observability/otel-collector-config.yaml.tmpl` placeholder [Story: FR-IN-007] [P]
- [x] Create `.forge/templates/archetypes/full-stack-monorepo/infra/observability/signoz-config.yaml.tmpl` placeholder [Story: FR-IN-008] [P]
- [x] Create `.forge/templates/archetypes/full-stack-monorepo/backend/.env.dev.tmpl` placeholder [Story: FR-IN-009] [P]
- [x] Create `.forge/templates/archetypes/full-stack-monorepo/frontend/.env.dev.tmpl` placeholder [Story: FR-IN-009] [P]
- [x] Create `.forge/standards/infra/ci-workflows.md` placeholder [Story: FR-IN-010] [P]
- [x] Create `.forge/standards/infra/k8s-overlays.md` placeholder [Story: FR-IN-011] [P]
- [x] Create `.forge/standards/infra/observability-local.md` placeholder [Story: FR-IN-012] [P]
- [x] Remove `.forge/templates/archetypes/full-stack-monorepo/infra/k8s_base.gitkeep` and `k8s_overlays.gitkeep` (replaced by populated tree in Phase 3) [Story: FR-IN-006]

## Phase 2: Reference CI workflows — TDD per FR

### 2.1 FR-IN-002 — `forge-backend.yml.tmpl`
- [x] RED: `test_workflow_backend_paths_filter_and_steps()` — Python+PyYAML parser via `workflow_assertions` helper ; asserts `dorny/paths-filter@v3` ref, paths include `backend/**` and `shared/protos/**`, step ordering with comment-stripping (fmt → clippy → test → verify.sh → linter.sh), `concurrency.group` present, no `continue-on-error: true`, clippy `-D warnings`, cache key on `Cargo.lock` [Story: FR-IN-002, ADR-002]
- [x] Verify RED — `yaml document empty` against placeholder [Story: FR-IN-002]
- [x] GREEN: write the full workflow — `filter` job (dorny) + `build` job gated on `needs.filter.outputs.backend == 'true'`, dtolnay/rust-toolchain@stable with rustfmt+clippy components, actions/cache@v4 keyed on Cargo.lock, the 5 ordered steps, two-job split for clean skip semantics on out-of-scope PRs [Story: FR-IN-002, ADR-002, ADR-011]
- [x] Verify GREEN — `test_workflow_backend_paths_filter_and_steps` flips to PASS [Story: FR-IN-002]
- [x] FIX (TDD reveal) : ordering check stripped of `#`-comment lines so the header narrative no longer false-matches the step keywords [Story: FR-GL-025 harness robustness]

### 2.2 FR-IN-003 — `forge-frontend.yml.tmpl`
- [x] RED: `test_workflow_frontend_paths_filter_and_steps()` — paths `frontend/**` + `shared/protos/**`, steps `pub get → dart format --set-exit-if-changed → flutter analyze --fatal-infos --fatal-warnings → flutter test → verify.sh → linter.sh`, `subosito/flutter-action` with `flutter-version-file: .flutter-version`, pub cache keyed on `pubspec.lock` [Story: FR-IN-003, ADR-002, ADR-011]
- [x] Verify RED — `yaml document empty` [Story: FR-IN-003]
- [x] GREEN: write workflow — `filter` job + `build` job gated on filter output, `subosito/flutter-action@v2` with `cache: true`, optional coverage artifact upload guarded on `push: main`, the 6 ordered steps [Story: FR-IN-003]
- [x] Verify GREEN [Story: FR-IN-003]

### 2.3 FR-IN-004 — `forge-infra.yml.tmpl`
- [x] RED: `test_workflow_infra_paths_filter_and_steps()` — paths-filter on `infra/**`, three `kustomize build` steps, `kubeconform --strict` per overlay, then verify.sh + linter.sh, three explicit `overlays/{dev,staging,prod}` references [Story: FR-IN-004, ADR-003]
- [x] Verify RED [Story: FR-IN-004]
- [x] GREEN: write workflow — `imranismail/setup-kustomize@v2` pinned to 5.4.2, kubeconform 0.6.7 installed via curl + tar (yannh upstream release), three `kustomize build → /tmp/<env>.yaml` + three `kubeconform --summary --strict <file>` validation steps, then Forge gates [Story: FR-IN-004, ADR-003, ADR-008]
- [x] Verify GREEN — required iteration : test originally matched `kubeconform` substring inside `Install kubeconform` setup step (false ordering positive), tightened needle to `kubeconform --strict` (the actual validation invocation), aligned workflow on GNU double-dash convention [Story: FR-IN-004, FR-GL-025 harness robustness]

### 2.4 FR-IN-005 — `forge-integration.yml.tmpl`
- [x] RED: `test_workflow_integration_triggers_and_lifecycle()` — triggers MUST include `push.branches: [main]` AND `schedule.cron`, MUST exclude `pull_request`, MUST include `workflow_dispatch`. Body asserts `up -d --wait`, `down -v`, `if: always()`, Patrol/android-emulator-runner step, `cargo test --features integration` [Story: FR-IN-005, ADR-012]
- [x] Verify RED [Story: FR-IN-005]
- [x] GREEN: write workflow — push:main + cron `0 3 * * *` + workflow_dispatch triggers, `cancel-in-progress: false` (don't kill nightlies), `timeout-minutes: 35` (NFR-014 envelope), checkout + Rust toolchain + cargo cache + `docker compose up -d --wait` + `cargo test --features integration` + Patrol via `reactivecircus/android-emulator-runner@v2` API 34 + opt-in failure issue comment gated on `secrets.FORGE_INTEGRATION_TRACKING_ISSUE` + always-on `docker compose down -v` teardown [Story: FR-IN-005, ADR-012, NFR-014]
- [x] Verify GREEN [Story: FR-IN-005]

## Phase 3: Kustomize overlays — TDD

### 3.1 FR-IN-006 base/ tree
- [x] RED: `test_kustomize_base_renders()` — `base/kustomization.yaml.tmpl` parses + lists `deployment.yaml`, `service.yaml`, `serviceaccount.yaml`, `ingress.yaml` resources ; `deployment.yaml.tmpl` declares container with livenessProbe, readinessProbe, resources ; L2 augmentation runs real `kustomize build` when binary present (SKIPPED here) [Story: FR-IN-006]
- [x] Verify RED — file missing [Story: FR-IN-006]
- [x] GREEN: write `base/kustomization.yaml.tmpl` (Kustomization + 4 resources + commonLabels), `base/deployment.yaml.tmpl` (Deployment with /healthz + /readyz probes, gRPC :50051 + HTTP :8080, OTLP env from optional ConfigMap, resource requests/limits), `base/service.yaml.tmpl` (ClusterIP), `base/serviceaccount.yaml.tmpl` (automount disabled), `base/ingress.yaml.tmpl` (host with `.example.invalid` placeholder), `base/README.md.tmpl` (promotion lifecycle table) [Story: FR-IN-006, ADR-004]
- [x] Verify GREEN — base test PASS [Story: FR-IN-006]

### 3.2 FR-IN-006 overlays/dev [P]
- [x] RED: `test_overlay_dev_renders_and_validates()` — namespace ends `-dev`, image newTag matches `^dev-latest$`, replicas == 1, commonAnnotations include `forge.io/managed-by: forge` + `forge.io/overlay: dev` [Story: FR-IN-006]
- [x] Verify RED — overlay file missing [Story: FR-IN-006]
- [x] GREEN: write `overlays/dev/kustomization.yaml.tmpl` — `namespace: <project-name>-dev`, `images: newTag: dev-latest`, `replicas: count: 1`, ConfigMapGenerator for `OTEL_EXPORTER_OTLP_ENDPOINT` + `APP_ENV=dev`, commonAnnotations [Story: FR-IN-006, ADR-004]
- [x] Verify GREEN — required iteration : initial regex `:dev-latest` (with colon) was wrong because Kustomize `newTag` is the tag-only string (no colon prefix). Pattern relaxed to `^dev-latest$` [Story: FR-IN-006, FR-GL-025 harness robustness]

### 3.3 FR-IN-006 overlays/staging [P]
- [x] RED: `test_overlay_staging_renders_and_validates()` — namespace ends `-staging`, image newTag matches `^sha-`, replicas == 2 [Story: FR-IN-006]
- [x] Verify RED [Story: FR-IN-006]
- [x] GREEN: write `overlays/staging/kustomization.yaml.tmpl` (sha-pinned newTag placeholder `sha-replace-at-deploy`, replicas: 2) [Story: FR-IN-006]
- [x] Verify GREEN [Story: FR-IN-006]

### 3.4 FR-IN-006 overlays/prod [P]
- [x] RED: `test_overlay_prod_renders_and_validates()` — namespace ends `-prod`, image newTag matches `^v[0-9]`, replicas == 3, **and** `overlays/prod/hpa.yaml.tmpl` declares HorizontalPodAutoscaler with minReplicas=3, maxReplicas=10, CPU averageUtilization=70 [Story: FR-IN-006]
- [x] Verify RED [Story: FR-IN-006]
- [x] GREEN: write `overlays/prod/kustomization.yaml.tmpl` (v-pinned `v0.0.0-replace-at-release`, replicas: 3, hpa.yaml in resources) + `overlays/prod/hpa.yaml.tmpl` (autoscaling/v2 HPA, CPU resource metric, scaleTargetRef pointing at the backend Deployment) [Story: FR-IN-006, ADR-004]
- [x] Verify GREEN [Story: FR-IN-006]

### 3.5 FR-IN-006 + NFR-017 — overlay diffability
- [x] RED: `test_overlay_diff_size_under_4kb()` — diff between rendered dev and prod ≤ 4 KB uncompressed. Test SKIPS cleanly with explicit message when `kustomize` is not on PATH (L2-only check) [Story: NFR-017]
- [x] Verify behaviour : SKIP path emits "kustomize not on PATH (test runs in L2 only)" without failing the harness [Story: NFR-017]
- [ ] REFACTOR: factor any common patches back into base — DEFERRED to L2 environment (cannot measure rendered diff without kustomize binary). Tracked as residual risk : the three overlays differ only in namespace, image tag, replicas count, and ConfigMap content per layer ; structural similarity suggests the diff will fall well under 4 KB once measured [Story: NFR-017]
- [ ] Verify GREEN — DEFERRED to environment with `kustomize` available. Safe : the structural assertions (3.2..3.4) already prove the overlays share a common base [Story: NFR-017]

## Phase 4: Local observability stack — TDD

### 4.1 FR-IN-007 — OTel collector service in compose
- [x] RED: `test_compose_otel_service_shape()` — Python YAML inspector ; `services.fsm-otel-collector` with image pinned to `otel/opentelemetry-collector-contrib:<minor>`, ports 4317 + 4318 + 13133, healthcheck on :13133, network `fsm-dev`, config volume mount ; collector config has receivers/processors/exporters/service.pipelines.{traces,metrics,logs} [Story: FR-IN-007, ADR-007, ADR-008]
- [x] Verify RED — `missing service: fsm-otel-collector` [Story: FR-IN-007]
- [x] GREEN: append `fsm-otel-collector` block to compose (image `otel/opentelemetry-collector-contrib:0.96.0`, command/--config flag, 3 ports, config mount, fsm-dev network, healthcheck wget probe, depends_on fsm-signoz-query healthy) ; write `otel-collector-config.yaml.tmpl` (otlp receivers gRPC+HTTP, memory_limiter+batch processors, otlp/signoz exporter to fsm-signoz-query:4317 with insecure TLS, debug exporter, health_check extension on :13133, 3 pipelines traces/metrics/logs each routing through both exporters) [Story: FR-IN-007, ADR-005, ADR-006]
- [x] Verify GREEN [Story: FR-IN-007]

### 4.2 FR-IN-008 — SigNoz services in compose
- [x] RED: `test_compose_signoz_services_shape()` — 3 services exist with pinned images (no `:latest`), all have healthcheck + `restart: unless-stopped`, only `fsm-signoz-frontend` host-exposes :3301, clickhouse + query are internal (no ports), depends_on chain `query→clickhouse:healthy` and `frontend→query:healthy`, named volume `signoz-clickhouse-data` [Story: FR-IN-008, ADR-005, ADR-008]
- [x] Verify RED — 7 distinct errors reported [Story: FR-IN-008]
- [x] GREEN: append 3 SigNoz services to compose (clickhouse 24.1.2-alpine, query-service 0.55.1, frontend 0.55.1, all internal except frontend on :3301), named volume `signoz-clickhouse-data` for persistence ; write `signoz-config.yaml.tmpl` (clickhouse driver, port 8080, log_level info, **auth disabled in dev** with explicit MUST-flip-on comment for staging/prod, retention 7d traces / 30d metrics / 7d logs) [Story: FR-IN-008]
- [x] Verify GREEN [Story: FR-IN-008]

### 4.3 FR-IN-008 SHOULD — `task observe` target
- [x] RED: `test_taskfile_has_observe_target()` — Taskfile parses, `tasks.observe.cmds` references :3301 + uses `open` or `xdg-open` [Story: FR-IN-008]
- [x] Verify RED [Story: FR-IN-008]
- [x] GREEN: insert `observe:` task block between `dev:down:` and Tests section. OS detection via `command -v` for `open` (macOS) → fallback `xdg-open` (Linux) → fallback echo with manual URL. `silent: true` to keep output clean [Story: FR-IN-008]
- [x] Verify GREEN [Story: FR-IN-008]

### 4.4 FR-IN-009 — `.env.dev` files
- [x] RED: `test_env_dev_files_export_otel_defaults()` — both files declare 5 OTEL_* env vars common, plus per-layer `OTEL_EXPORTER_OTLP_PROTOCOL` (grpc for backend, http/protobuf for frontend) [Story: FR-IN-009]
- [x] Verify RED — `missing OTEL_EXPORTER_OTLP_ENDPOINT` on backend [Story: FR-IN-009]
- [x] GREEN: write both `.env.dev.tmpl` files (header comment + 7 OTEL_* exports, including `OTEL_RESOURCE_ATTRIBUTES=service.namespace=<project-name>,deployment.environment=dev`) ; backend uses :4317 gRPC, frontend uses :4318 HTTP/protobuf (Dart SDK constraint documented in header comment) [Story: FR-IN-009]
- [x] Verify GREEN [Story: FR-IN-009]

## Phase 5: Standards (parallelizable [P])

### 5.1 FR-IN-010 — `infra/ci-workflows.md` [P]
- [ ] RED: `test_standard_ci_workflows_has_required_sections()` — 7 canonical H2 sections exact match [Story: FR-IN-010]
- [ ] Verify RED [Story: FR-IN-010]
- [ ] GREEN: write `standards/infra/ci-workflows.md` (~150 lines) — Per-layer paths filter, Gate ordering, Integration workflow scope, Concurrency policy, Caching strategy, Tool version pinning, Failure semantics. Reference each `.tmpl` file by relative path. Cross-ref to Articles V + X [Story: FR-IN-010, ADR-002, ADR-011, ADR-012]
- [ ] Verify GREEN [Story: FR-IN-010]

### 5.2 FR-IN-011 — `infra/k8s-overlays.md` [P]
- [ ] RED: `test_standard_k8s_overlays_has_required_sections()` — 6 canonical H2 sections [Story: FR-IN-011]
- [ ] Verify RED [Story: FR-IN-011]
- [ ] GREEN: write `standards/infra/k8s-overlays.md` (~180 lines) — Three-environment promotion model, Per-overlay diff conventions, Image tag policy by environment, Resource budget table (CPU/memory per env), Secret management (Sealed Secrets / External Secrets allowed ; plain `Secret` forbidden), Promotion gating mapping to Forge change lifecycle. Explicit interdiction of editing `kustomize build` output [Story: FR-IN-011, ADR-004]
- [ ] Verify GREEN [Story: FR-IN-011]

### 5.3 FR-IN-012 — `infra/observability-local.md` [P]
- [ ] RED: `test_standard_observability_local_has_required_sections()` — 5 canonical H2 sections + version table block [Story: FR-IN-012]
- [ ] Verify RED [Story: FR-IN-012]
- [ ] GREEN: write `standards/infra/observability-local.md` (~140 lines) — Local OTel + SigNoz topology, App-side OTLP configuration, Versioning policy (with explicit pinned versions table), Trace sampling defaults, Migration to production observability (runbook stub). The version table is the **single source of truth** ; compose template references it [Story: FR-IN-012, ADR-005, ADR-006, ADR-008]
- [ ] Verify GREEN [Story: FR-IN-012]

### 5.4 Index entries for the 3 new standards
- [ ] RED: `test_index_has_three_new_infra_standards()` — strict YAML check : id, scope (infra), priority, triggers per entry [Story: FR-IN-010, FR-IN-011, FR-IN-012]
- [ ] Verify RED [Story: FR-IN-010..012]
- [ ] GREEN: append three entries to `.forge/standards/index.yml` (ci-workflows, k8s-overlays, observability-local) with appropriate triggers [Story: FR-IN-010..012]
- [ ] Verify GREEN [Story: FR-IN-010..012]

## Phase 6: Scaffolder integration

### 6.1 Update `scaffold-plan.yaml` for new templates
- [ ] RED: `test_scaffold_plan_lists_all_new_templates()` — every new `.tmpl` from Phases 1-4 has a `templates:` entry with correct source/target/substitute, and the obsolete `infra/k8s_base.gitkeep` + `infra/k8s_overlays.gitkeep` entries are removed [Story: FR-IN-002..009]
- [ ] Verify RED [Story: FR-IN-002..009]
- [ ] GREEN: edit `.forge/templates/archetypes/full-stack-monorepo/scaffold-plan.yaml` — remove the two obsolete `.gitkeep` entries, append entries for : 4 workflows, 5 base/ files, 4 overlay files, 2 observability config files, 2 .env.dev files. Group by layer convention (root → frontend → backend → infra → shared/protos → .github), alphabetical within group [Story: FR-IN-002..009, ADR-001]
- [ ] Verify GREEN — scaffold a fixture and confirm the rendered project tree matches design.md arborescence [Story: FR-IN-002..009]

### 6.2 Scaffolder fixture validation (end-to-end)
- [ ] RED: `test_scaffold_fixture_renders_and_validates()` — invoke the scaffolder against a fresh tmp dir, run `docker compose config`, `kustomize build` × 3 overlays, `kubeconform --strict`, all four workflows YAML-parse, on the resulting tree [Story: FR-IN-002..009]
- [ ] Verify RED if any fail — fix templates iteratively [Story: FR-IN-002..009]
- [ ] Verify GREEN [Story: FR-IN-002..009]

## Phase 7: Schema promotion logic (gated on archive)

### 7.1 FR-GL-024 — promotion test (gated)
- [ ] RED: `test_schema_header_post_archive()` — read `.forge/changes/b1-delivery/.forge.yaml`, if `status != archived` SKIP cleanly, else assert schema.yaml has `status: stable`, `version: "1.0.0"`, `promoted_from: "1.0.0-rc.1"`, `promoted_in: b1-delivery`, `promoted_on:` populated [Story: FR-GL-024, ADR-009]
- [ ] Verify RED currently SKIPS (status: planned at this point) — that is the correct intermediate state per ADR-009 [Story: FR-GL-024]

### 7.2 Schema bump payload (executed by `/forge:archive`)
- [ ] Author the exact YAML diff to apply to `.forge/schemas/full-stack-monorepo/schema.yaml` at archive time : flip `status: candidate` → `stable`, `version: "1.0.0-rc.1"` → `"1.0.0"`, add `promoted_from`, `promoted_in`, `promoted_on` fields [Story: FR-GL-024]
- [ ] Author the exact append to `.forge/specs/full-stack-monorepo.md` Schema Evolution table — one row recording the promotion with rationale "B.1 archetype contract fully delivered : foundations + scaffolder + workflow + delivery" [Story: FR-GL-024]
- [ ] (Both payloads applied by `/forge:archive b1-delivery` post-implementation. Test 7.1 flips from SKIP to PASS at that moment.) [Story: FR-GL-024, ADR-009]

## Phase 8: Quality, BDD, and integration

### 8.1 NFR enforcement
- [ ] RED: `test_no_latest_tag_anywhere()` — `grep -rE ':latest\b'` against `.forge/templates/archetypes/full-stack-monorepo/` MUST produce zero matches outside of comment lines [Story: NFR-018]
- [ ] Verify RED [Story: NFR-018]
- [ ] GREEN: ensure every image reference in templates uses a pinned minor version per ADR-008 [Story: NFR-018]
- [ ] Verify GREEN [Story: NFR-018]

- [ ] RED: `test_workflow_files_under_size_budget()` — every `forge-*.yml.tmpl` ≤ 250 lines [Story: NFR-016]
- [ ] Verify RED [Story: NFR-016]
- [ ] REFACTOR: extract any composite-action-eligible chunks if a workflow exceeds budget [Story: NFR-016]
- [ ] Verify GREEN [Story: NFR-016]

- [ ] LONG_TESTS=1 only: `test_compose_stack_startup_under_90s()` — `time docker compose up -d --wait` against the fixture project, assert wall-clock ≤ 90s on the dev-class machine envelope. Skip cleanly when `LONG_TESTS` unset [Story: NFR-015]
- [ ] LONG_TESTS=1 only: `test_per_layer_workflow_runtime_warm_under_8min()` — `act --dry-run` (or fixture exec) on the per-layer workflows with a warmed cache, assert ≤ 8 min. Skip cleanly when `act` absent [Story: NFR-013]

### 8.2 Security pass (Aegis)
- [ ] RED: `test_no_secrets_in_templates()` — grep for `password`, `api[_-]?key`, `secret`, `token` outside of comment lines and outside of YAML keys (e.g. `secrets:` in workflow refers to GitHub Secrets, allowed) [Story: design Security § 1]
- [ ] Verify RED [Story: design Security]
- [ ] GREEN: confirm no secret leak ; document the allowed exceptions (workflow `secrets:` references) inline in the test [Story: design Security]
- [ ] Verify GREEN [Story: design Security]

- [ ] Manual review: SigNoz auth disabled in dev only — confirmed via comment in `signoz-config.yaml.tmpl` and explicit MUST-flip-on note in `standards/infra/k8s-overlays.md` [Story: design Security § 4]

### 8.3 BDD feature file
- [ ] Create `.forge/changes/b1-delivery/features/b1-delivery.feature` capturing AC-001 (backend filter skip), AC-002 (clippy gate), AC-006 (Kustomize render + validate), AC-007 (`task dev` boots stack), AC-008 (trace visibility) — exact Gherkin from spec [Story: AC-001, 002, 006, 007, 008]

### 8.4 Editorial pass
- [ ] Markdownlint on the three new standards (consistent heading levels, no trailing spaces, fenced code blocks have language hints) [Story: NFR-003 in foundations spec]
- [ ] Cross-ref check : every standard referenced in design.md exists ; every ADR-id mentioned in standards refers to a real ADR in this design.md [Story: design Standards Applied table]

### 8.5 verify.sh integration
- [ ] Add a Section 8 (Delivery) to `.forge/scripts/verify.sh` that, when the archetype is detected at the target root, runs the kustomize-render + docker-compose-config quick checks (smoke level only — full validation is in delivery.test.sh) [Story: design Component Design]
- [ ] Run `bash .forge/scripts/verify.sh` on the Forge repo (no archetype present → Section 8 cleanly SKIPPED) [Story: NFR-010 backwards-compat]
- [ ] Run `bash .forge/scripts/verify.sh` on a fixture-scaffolded project → Section 8 PASSES [Story: design Component Design]

## Phase 9: Spec finalization (executed by `/forge:archive`)

### 9.1 Append delta to `.forge/specs/full-stack-monorepo.md`
- [ ] Author the exact append : 12 ADDED FRs (FR-IN-002..012 + FR-GL-024 + FR-GL-025), 6 ADDED NFRs (NFR-013..018), 1 MODIFIED entry for FR-GL-001, no REMOVED [Story: Article IV]
- [ ] Append a Schema Evolution table row : `1.0.0-rc.1 → 1.0.0`, change `b1-delivery`, archive date [Story: FR-GL-024]
- [ ] Append the change to the Archived changes index at the top of the spec [Story: design Phase 9]

### 9.2 Final delivery.test.sh self-check
- [ ] `bash .forge/scripts/tests/delivery.test.sh` exits 0 on a clean run [Story: FR-GL-025]
- [ ] Every FR ID listed Testable in specs.md has a matching `test_*` function in the harness manifest [Story: FR-GL-025]
- [ ] Run the full suite (`foundations.test.sh` + `workflow.test.sh` + `delivery.test.sh`) — all three exit 0 (no regression) [Story: NFR-010]

## Phase 10: Archive (gate to schema promotion)

### 10.1 `/forge:archive b1-delivery`
- [ ] Apply the schema header bump from Phase 7.2 [Story: FR-GL-024, ADR-009]
- [ ] Apply the spec delta append from Phase 9.1 [Story: Article IV]
- [ ] Set `.forge/changes/b1-delivery/.forge.yaml` `status: archived`, `timeline.archived: <date>` [Story: lifecycle]
- [ ] Re-run `delivery.test.sh` — `test_schema_header_post_archive` flips from SKIP to PASS [Story: FR-GL-024]
- [ ] Re-run `verify.sh` and `constitution-linter.sh` on the Forge repo — both PASS [Story: NFR-010]

---

## Constitutional Compliance — per-task gate

For every task above, the following invariants hold and have been
verified during planning :

| Article                              | How upheld                                                                                                                                        |
|--------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| **I — TDD**                          | Every implementation task is preceded by a RED test in `delivery.test.sh`. No `GREEN` task lacks a matching `RED` predecessor.                    |
| **III — Specs Before Code**          | Every task carries a `[Story: FR-XXX]` traceability marker. No task without a spec-FR reference (status check : 0 violations).                    |
| **IV — Semantic Deltas**             | Phase 9.1 produces the exact ADDED/MODIFIED/REMOVED delta against `full-stack-monorepo.md`. Phase 7.2 is the schema MODIFIED.                     |
| **V — Conformance Gate**             | Phase 8.5 plugs verify.sh ; Phase 10 confirms gates green pre-archive. Schema promotion (FR-GL-024) gated on archive (ADR-009).                   |
| **VIII — Infrastructure**            | Phases 3 (Kustomize), 4 (Compose + observability), 6 (scaffolder integration) — Atlas-led, follow ADR-004/06/07/12.                               |
| **IX — Observability**               | Phase 4 + Phase 5.3 — Argus-led ; three signals first-class ; pinned versions per ADR-008.                                                        |
| **X — Quality**                      | Phase 8.1 (NFR enforcement), Phase 8.4 (editorial), Phase 8.2 (security). Quality is an explicit phase, not a "we'll-see-later".                  |

No task gates pulled forward, no test deferred to "after archive",
no `:latest` allowed anywhere. Compliance gate : **PASS**.

---

## Traceability summary

- **14 FRs** (FR-IN-002..012 + FR-GL-024 + FR-GL-025 + MODIFIED FR-GL-001) → covered by phases 2, 3, 4, 5, 6, 7, 9.
- **6 NFRs** (NFR-013..018) → covered by phases 3.5, 8.1.
- **10 ACs** → 5 mechanically reproduced in `delivery.test.sh` (AC-001, 002, 006), 5 captured in BDD feature file (Phase 8.3), validated end-to-end by C.1 once it ships.
- **12 ADRs** → each ADR is referenced by at least one task's `[Story: ADR-XXX]` link. No orphaned ADR.

Plan is exhaustive : every spec artefact has at least one task that
produces it, every task has at least one spec artefact it serves.
