# Tasks: b1-delivery
<!-- TDD order mandatory: tests BEFORE implementation, always (Article I) -->
<!-- Format: - [ ] Task [Story: FR-XXX] [P] -->
<!-- [P] = parallelizable with other [P] tasks in the same sub-section -->
<!-- Parent audit items: B.1.9 + B.1.12 + B.1.14 -->
<!-- Depends on: b1-foundations + b1-scaffolder + b1-workflow (all archived) -->
<!-- Closes B.1: drives schema promotion candidate / 1.0.0-rc.1 → stable / 1.0.0 -->

## Phase 1: Foundation — harness skeleton + placeholder files

### 1.1 Delivery test harness skeleton
- [ ] Create `.forge/scripts/tests/delivery.test.sh` with shebang, `set -euo pipefail`, manifest header listing every `test_*` function name, sourcing of the shared `_helpers.sh` (or copy-paste the helper block from `workflow.test.sh` per ADR-010), stub `main()` that loops the manifest [Story: FR-GL-025, design ADR-010]
- [ ] Verify: `bash delivery.test.sh` exits 1 (RED baseline — manifest declares tests that do not yet exist) [Story: FR-GL-025]

### 1.2 Placeholder template files with audit headers
- [ ] Create `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-backend.yml.tmpl` placeholder (header comment only) [Story: FR-IN-002] [P]
- [ ] Create `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-frontend.yml.tmpl` placeholder [Story: FR-IN-003] [P]
- [ ] Create `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-infra.yml.tmpl` placeholder [Story: FR-IN-004] [P]
- [ ] Create `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-integration.yml.tmpl` placeholder [Story: FR-IN-005] [P]
- [ ] Create `.forge/templates/archetypes/full-stack-monorepo/infra/observability/otel-collector-config.yaml.tmpl` placeholder [Story: FR-IN-007] [P]
- [ ] Create `.forge/templates/archetypes/full-stack-monorepo/infra/observability/signoz-config.yaml.tmpl` placeholder [Story: FR-IN-008] [P]
- [ ] Create `.forge/templates/archetypes/full-stack-monorepo/backend/.env.dev.tmpl` placeholder [Story: FR-IN-009] [P]
- [ ] Create `.forge/templates/archetypes/full-stack-monorepo/frontend/.env.dev.tmpl` placeholder [Story: FR-IN-009] [P]
- [ ] Create `.forge/standards/infra/ci-workflows.md` placeholder [Story: FR-IN-010] [P]
- [ ] Create `.forge/standards/infra/k8s-overlays.md` placeholder [Story: FR-IN-011] [P]
- [ ] Create `.forge/standards/infra/observability-local.md` placeholder [Story: FR-IN-012] [P]
- [ ] Remove `.forge/templates/archetypes/full-stack-monorepo/infra/k8s_base.gitkeep` and `k8s_overlays.gitkeep` (replaced by populated tree in Phase 3) [Story: FR-IN-006]

## Phase 2: Reference CI workflows — TDD per FR

### 2.1 FR-IN-002 — `forge-backend.yml.tmpl`
- [ ] RED: `test_workflow_backend_paths_filter_and_steps()` — parse YAML via `yq`, assert `dorny/paths-filter@v3` ref, `paths:` includes `backend/**` and `shared/protos/**`, step ordering (fmt → clippy → test → verify.sh → linter.sh), `concurrency.group` placeholder present, no `continue-on-error: true` anywhere [Story: FR-IN-002, ADR-002]
- [ ] Verify RED — fails because placeholder file has no `jobs:` section [Story: FR-IN-002]
- [ ] GREEN: write the full workflow template — checkout, paths-filter setup, conditional Rust toolchain via `dtolnay/rust-toolchain@stable`, cache step keyed on `Cargo.lock`, the 5 ordered steps, concurrency block with `<project-name>` placeholder [Story: FR-IN-002, ADR-002, ADR-011]
- [ ] Verify GREEN — `delivery.test.sh` flips to PASS [Story: FR-IN-002]

### 2.2 FR-IN-003 — `forge-frontend.yml.tmpl`
- [ ] RED: `test_workflow_frontend_paths_filter_and_steps()` — same shape as 2.1 but for Flutter (paths include `frontend/**` + `shared/protos/**`, steps `pub get → dart format --set-exit-if-changed → flutter analyze --fatal-infos --fatal-warnings → flutter test → verify.sh → linter.sh`), `subosito/flutter-action` with `flutter-version-file: .flutter-version` [Story: FR-IN-003, ADR-002, ADR-011]
- [ ] Verify RED [Story: FR-IN-003]
- [ ] GREEN: write the full workflow template — pub cache step keyed on `pubspec.lock`, optional coverage upload guarded on `if: github.event_name == 'push' && github.ref == 'refs/heads/main'` [Story: FR-IN-003]
- [ ] Verify GREEN [Story: FR-IN-003]

### 2.3 FR-IN-004 — `forge-infra.yml.tmpl`
- [ ] RED: `test_workflow_infra_paths_filter_and_steps()` — paths-filter on `infra/**`, three `kustomize build` steps (dev / staging / prod), `kubeconform --strict` per overlay, then verify.sh + linter.sh, kustomize tool setup pinned [Story: FR-IN-004, ADR-003]
- [ ] Verify RED [Story: FR-IN-004]
- [ ] GREEN: write the workflow template — `imranismail/setup-kustomize@v2` with explicit version, `yokawasa/action-setup-kube-tools` for kubeconform, three rendered overlays piped through kubeconform, exit non-zero on any failure [Story: FR-IN-004, ADR-003]
- [ ] Verify GREEN [Story: FR-IN-004]

### 2.4 FR-IN-005 — `forge-integration.yml.tmpl`
- [ ] RED: `test_workflow_integration_triggers_and_lifecycle()` — triggers MUST include `push: branches: [main]` AND `schedule: cron`, MUST exclude `pull_request`, MUST include `workflow_dispatch`. Steps assert `docker compose up -d --wait`, `cargo test --features integration`, Patrol step, teardown with `if: always()` [Story: FR-IN-005, ADR-012]
- [ ] Verify RED [Story: FR-IN-005]
- [ ] GREEN: write the integration workflow — checkout, docker compose up, wait for backend healthcheck, run cargo integration tests, run Patrol on `reactivecircus/android-emulator-runner@v2`, teardown step `if: always()` with `docker compose down -v`, optional issue-comment step gated on `secrets.FORGE_INTEGRATION_TRACKING_ISSUE` [Story: FR-IN-005, ADR-012]
- [ ] Verify GREEN [Story: FR-IN-005]

## Phase 3: Kustomize overlays — TDD

### 3.1 FR-IN-006 base/ tree
- [ ] RED: `test_kustomize_base_renders()` — `kustomize build .forge/templates/archetypes/full-stack-monorepo/infra/k8s/base` (after `.tmpl` substitution into a tmp fixture) MUST exit 0 and produce non-empty YAML [Story: FR-IN-006]
- [ ] Verify RED [Story: FR-IN-006]
- [ ] GREEN: write `base/kustomization.yaml.tmpl` (resources list), `base/deployment.yaml.tmpl` (one Deployment for the backend service, image placeholder, healthcheck probes, `commonAnnotations` block), `base/service.yaml.tmpl` (ClusterIP), `base/serviceaccount.yaml.tmpl`, `base/ingress.yaml.tmpl`, `base/README.md.tmpl` (doc-only) [Story: FR-IN-006, ADR-004]
- [ ] Verify GREEN — kustomize build PASSES on the rendered fixture [Story: FR-IN-006]

### 3.2 FR-IN-006 overlays/dev [P]
- [ ] RED: `test_overlay_dev_renders_and_validates()` — kustomize build PASS, namespace == `<project>-dev`, image tag matches `:dev-latest`, replicas == 1, kubeconform --strict PASS [Story: FR-IN-006]
- [ ] Verify RED [Story: FR-IN-006]
- [ ] GREEN: write `overlays/dev/kustomization.yaml.tmpl` — namespace, image transformer, replicas patch, ConfigMap generator for env defaults, commonAnnotations [Story: FR-IN-006, ADR-004]
- [ ] Verify GREEN [Story: FR-IN-006]

### 3.3 FR-IN-006 overlays/staging [P]
- [ ] RED: `test_overlay_staging_renders_and_validates()` — namespace, image tag matches `:sha-`, replicas == 2 [Story: FR-IN-006]
- [ ] Verify RED [Story: FR-IN-006]
- [ ] GREEN: write `overlays/staging/kustomization.yaml.tmpl` [Story: FR-IN-006]
- [ ] Verify GREEN [Story: FR-IN-006]

### 3.4 FR-IN-006 overlays/prod [P]
- [ ] RED: `test_overlay_prod_renders_and_validates()` — namespace, image tag matches `:v`, replicas == 3, HPA resource present (min=3, max=10, CPU target 70%), kubeconform PASS [Story: FR-IN-006]
- [ ] Verify RED [Story: FR-IN-006]
- [ ] GREEN: write `overlays/prod/kustomization.yaml.tmpl` + `overlays/prod/hpa.yaml.tmpl` + replica patch [Story: FR-IN-006, ADR-004]
- [ ] Verify GREEN [Story: FR-IN-006]

### 3.5 FR-IN-006 + NFR-017 — overlay diffability
- [ ] RED: `test_overlay_diff_size_under_4kb()` — diff between rendered dev and prod ≤ 4 KB uncompressed [Story: NFR-017]
- [ ] Verify RED if diff exceeds budget — refactor base / overlays until under [Story: NFR-017]
- [ ] REFACTOR: factor any common patches back into base [Story: NFR-017]
- [ ] Verify GREEN [Story: NFR-017]

## Phase 4: Local observability stack — TDD

### 4.1 FR-IN-007 — OTel collector service in compose
- [ ] RED: `test_compose_otel_service_shape()` — `docker compose -f <fixture>/docker-compose.dev.yml config` parses ; `services.fsm-otel-collector` declares image pinned to specific minor (regex `:[0-9]+\.[0-9]+\.[0-9]+`), ports 4317 + 4318 + 13133, healthcheck on :13133, network `fsm-dev`, mounts `infra/observability/otel-collector-config.yaml` [Story: FR-IN-007, ADR-007, ADR-008]
- [ ] Verify RED [Story: FR-IN-007]
- [ ] GREEN: extend `docker-compose.dev.yml.tmpl` — add `fsm-otel-collector` service block ; write `infra/observability/otel-collector-config.yaml.tmpl` (OTLP gRPC + HTTP receivers, batch + memory_limiter processors, OTLP exporter to fsm-signoz-query, debug exporter, three pipelines traces/metrics/logs) [Story: FR-IN-007, ADR-005, ADR-006]
- [ ] Verify GREEN [Story: FR-IN-007]

### 4.2 FR-IN-008 — SigNoz services in compose
- [ ] RED: `test_compose_signoz_services_shape()` — three services `fsm-signoz-clickhouse`, `fsm-signoz-query`, `fsm-signoz-frontend` ; only `fsm-signoz-frontend` exposes port 3301 to host ; healthchecks on every service ; `restart: unless-stopped` ; named volume `signoz-clickhouse-data` ; depends_on chain validated [Story: FR-IN-008, ADR-005, ADR-008]
- [ ] Verify RED [Story: FR-IN-008]
- [ ] GREEN: extend `docker-compose.dev.yml.tmpl` with the three SigNoz services + named volume ; write `infra/observability/signoz-config.yaml.tmpl` (query service config, auth disabled in dev with TODO marker for staging/prod) [Story: FR-IN-008]
- [ ] Verify GREEN [Story: FR-IN-008]

### 4.3 FR-IN-008 SHOULD — `task observe` target
- [ ] RED: `test_taskfile_has_observe_target()` — Taskfile.yml.tmpl declares an `observe:` task whose command opens `http://localhost:3301` via `open` (macOS) or `xdg-open` (Linux) [Story: FR-IN-008]
- [ ] Verify RED [Story: FR-IN-008]
- [ ] GREEN: append the `observe` task to `Taskfile.yml.tmpl` with OS detection [Story: FR-IN-008]
- [ ] Verify GREEN [Story: FR-IN-008]

### 4.4 FR-IN-009 — `.env.dev` files
- [ ] RED: `test_env_dev_files_export_otel_defaults()` — both `backend/.env.dev.tmpl` and `frontend/.env.dev.tmpl` declare `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317`, `OTEL_SERVICE_NAME=<project-name>-<layer>`, `OTEL_TRACES_EXPORTER=otlp`, `OTEL_METRICS_EXPORTER=otlp`, `OTEL_LOGS_EXPORTER=otlp` ; backend declares `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` ; frontend declares `http/protobuf` ; both have header warning comment [Story: FR-IN-009]
- [ ] Verify RED [Story: FR-IN-009]
- [ ] GREEN: write both `.env.dev.tmpl` files with the required env vars and the header comment block [Story: FR-IN-009]
- [ ] Verify GREEN [Story: FR-IN-009]

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
