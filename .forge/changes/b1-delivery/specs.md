# Spec: b1-delivery
<!-- Delta format: ADDED, MODIFIED, REMOVED sections only -->
<!-- Audit: B.1.9 + B.1.12 + B.1.14 -->
<!-- Depends on spec: full-stack-monorepo.md (FR-GL-001..023 + FR-BE-001..002 + FR-FE-001..002 + FR-IN-001 + NFR-001..012) -->
<!-- Closes B.1: promotes archetype schema candidate / 1.0.0-rc.1 → stable / 1.0.0 -->

## Glossary

- **Reference workflow** — a CI pipeline shipped under
  `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/`
  that scaffolded projects inherit verbatim. Authoritative rather
  than illustrative : it is the version the constitution-linter is
  designed to dovetail with.
- **Per-layer workflow** — a reference workflow whose `paths:`
  filter is restricted to a single archetype layer subtree
  (`backend/**`, `frontend/**`, `infra/**`), optionally with
  `shared/protos/**` when the layer consumes protos.
- **Integration workflow** — the cross-layer reference workflow
  that exercises the full stack end-to-end. Triggered on `main`
  pushes and on a nightly schedule, never per-PR.
- **Overlay** — a Kustomize subtree under `infra/k8s/overlays/<env>/`
  that patches the shared `infra/k8s/base/`. Three canonical
  overlays in this change : `dev`, `staging`, `prod`.
- **Local observability stack** — the OTel collector + SigNoz
  bundle wired into the archetype's `docker-compose.dev.yml.tmpl`,
  giving every freshly-scaffolded project working trace + metric
  pipelines on `task dev` with no extra setup.
- **Schema promotion** — the act of moving the archetype schema
  header from `status: candidate` + `version: 1.0.0-rc.1` to
  `status: stable` + `version: 1.0.0`, recorded in the spec's
  Schema Evolution table. Mechanical YAML edit ; the contract
  itself is unchanged.

---

## ADDED Requirements

### FR-IN-002: Reference per-layer backend workflow

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — a template
  `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-backend.yml.tmpl`
  exists and declares a GitHub Actions workflow that triggers on
  `pull_request` and `push` to the default branch.
- **MUST** — the workflow uses `dorny/paths-filter@v3` (or a later
  v3.x) and runs only when at least one of the touched paths
  matches `backend/**` OR `shared/protos/**`. Outside that scope,
  every job emits `skipped`.
- **MUST** — when the filter matches, the workflow executes, in
  order : `cargo fmt --check`, `cargo clippy --workspace
  --all-targets -- -D warnings`, `cargo test --workspace`, then
  `bash .forge/scripts/verify.sh` and
  `bash .forge/scripts/constitution-linter.sh` against the
  scaffolded project root.
- **MUST** — any non-zero exit code from any of these steps fails
  the workflow (no `continue-on-error: true`).
- **SHALL** — the workflow caches `~/.cargo/registry`,
  `~/.cargo/git`, and `target/` keyed on
  `Cargo.lock` for build reuse.
- **SHALL** — the file is a `.tmpl` so the scaffolder substitutes
  the project name into `concurrency.group` to scope the GitHub
  concurrency control.

**Constitution reference:** Article V (gates), Article VII (Rust
architecture), Article X (quality). **Testable:** yes —
`test_workflow_backend_paths_filter_and_steps` in
`delivery.test.sh` parses the YAML and asserts the trigger paths,
job ordering, and the absence of `continue-on-error`.

---

### FR-IN-003: Reference per-layer frontend workflow

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — a template
  `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-frontend.yml.tmpl`
  exists with `dorny/paths-filter@v3` configured to match `frontend/**`
  OR `shared/protos/**`.
- **MUST** — when the filter matches, the workflow executes :
  `flutter pub get`, `dart format --set-exit-if-changed .`,
  `flutter analyze --fatal-infos --fatal-warnings`,
  `flutter test --coverage`, then the Forge gates
  (`verify.sh` + `constitution-linter.sh`).
- **MUST** — Flutter SDK version is read from a single source of
  truth at `.flutter-version` at the project root (a file the
  scaffolder also writes). The workflow uses `subosito/flutter-action`
  with `flutter-version-file: .flutter-version`.
- **SHALL** — the workflow caches the pub cache
  (`~/.pub-cache`) keyed on `pubspec.lock`.
- **MAY** — the workflow uploads `coverage/lcov.info` as an
  artifact when running on `push: main` for downstream coverage
  reporting. Optional — coverage tooling is project-owned, not
  Forge-mandated.

**Constitution reference:** Article V, Article VI (Flutter
architecture), Article X. **Testable:** yes —
`test_workflow_frontend_paths_filter_and_steps` in
`delivery.test.sh`.

---

### FR-IN-004: Reference per-layer infra workflow

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — a template
  `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-infra.yml.tmpl`
  exists with `dorny/paths-filter@v3` configured to match `infra/**`.
- **MUST** — when the filter matches, the workflow executes :
  `kustomize build infra/k8s/overlays/dev > /tmp/dev.yaml`, same
  for `staging` and `prod`. Each build MUST exit 0.
- **MUST** — the workflow runs `kubeconform -summary -strict -schema-location
  default -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{`{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json`}}'`
  against each rendered overlay. Schema violations fail the workflow.
- **MUST** — the Forge gates (`verify.sh` + `constitution-linter.sh`)
  run last, after the Kubernetes-specific checks.
- **SHALL** — Kustomize version is pinned via the workflow's tool
  setup step (no implicit `:latest`).

**Constitution reference:** Article V, Article VIII (infrastructure),
Article X. **Testable:** yes —
`test_workflow_infra_paths_filter_and_steps` in `delivery.test.sh`.

---

### FR-IN-005: Cross-layer integration workflow

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — a template
  `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/forge-integration.yml.tmpl`
  exists and triggers on `push: main` and on a nightly cron
  (`schedule: [{cron: '0 3 * * *'}]`, UTC). It MUST NOT trigger
  on `pull_request`.
- **MUST** — the workflow boots the local stack via `docker compose
  -f docker-compose.dev.yml up -d --wait` (`--wait` blocks until
  every service with a healthcheck reports healthy).
- **MUST** — once the stack is up, the workflow runs the
  cross-layer test suite : backend integration tests
  (`cargo test --features integration --workspace`) followed by
  Flutter end-to-end tests via Patrol on a headless Android
  emulator, configured to point at the local backend through the
  compose network.
- **MUST** — teardown (`docker compose down -v`) runs in an
  `if: always()` step so failures do not leak resources.
- **SHALL** — the workflow exposes a `workflow_dispatch:` trigger
  for manual re-runs from the Actions UI.
- **MAY** — failure of the nightly run posts a structured comment
  to a tracking issue. Off by default ; opt-in via secret
  `FORGE_INTEGRATION_TRACKING_ISSUE`.

**Constitution reference:** Article V, Article X. **Testable:** yes
— `test_workflow_integration_triggers_and_lifecycle` in
`delivery.test.sh`.

---

### FR-IN-006: Canonical Kustomize overlays for dev/staging/prod

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — under
  `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/`,
  the following template tree exists :
    - `base/kustomization.yaml.tmpl`
    - `base/deployment.yaml.tmpl` (one Deployment for the backend service)
    - `base/service.yaml.tmpl`
    - `base/serviceaccount.yaml.tmpl`
    - `base/ingress.yaml.tmpl`
    - `overlays/dev/kustomization.yaml.tmpl`
    - `overlays/staging/kustomization.yaml.tmpl`
    - `overlays/prod/kustomization.yaml.tmpl`
- **MUST** — every overlay declares its own `namespace:` field
  (`<project>-dev`, `<project>-staging`, `<project>-prod` —
  substituted by the scaffolder).
- **MUST** — image tag policies per environment :
    - `dev` overlays the image to `:dev-latest` from a local
      registry stub.
    - `staging` overlays the image to `:sha-{{`{{.GitSha}}`}}` —
      digest-pinned.
    - `prod` overlays the image to a tag-pinned reference
      (`:v{{`{{.Version}}`}}`).
- **MUST** — replicas per environment : `dev: 1`, `staging: 2`,
  `prod: 3`. The `prod` overlay MUST also include an
  `HorizontalPodAutoscaler` template with min=3, max=10, CPU
  target 70%.
- **MUST** — resource requests/limits per environment match the
  table in `standards/infra/k8s-overlays.md` (FR-IN-011). Dev is
  intentionally lower than staging/prod.
- **MUST** — `kustomize build` MUST exit 0 against every overlay
  out of the box (no manual edits required) and the rendered YAML
  MUST pass `kubeconform --strict`.
- **SHALL** — each overlay declares a `commonAnnotations` block
  carrying `forge.io/managed-by: forge`,
  `forge.io/overlay: <env>`, and the rendered project name.

**Constitution reference:** Article VIII (infrastructure),
Article X. **Testable:** yes — `test_overlay_kustomize_build_and_kubeconform`
in `delivery.test.sh`.

---

### FR-IN-007: OTel collector service in `docker-compose.dev.yml.tmpl`

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — the existing
  `.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
  gains a service `otel-collector` based on
  `otel/opentelemetry-collector-contrib`. The image tag MUST be
  pinned to a specific minor version (e.g. `:0.96.0`), never
  `:latest`.
- **MUST** — the collector exposes OTLP receivers on `4317/tcp`
  (gRPC) and `4318/tcp` (HTTP), and a health endpoint on
  `13133/tcp`.
- **MUST** — the collector has a healthcheck of the form
  `wget --spider --quiet http://localhost:13133/` so the
  integration workflow's `--wait` flag observes readiness.
- **MUST** — the collector mounts
  `infra/observability/otel-collector-config.yaml` (also a
  template — see FR-IN-009) at `/etc/otelcol-contrib/config.yaml`.
- **MUST** — the collector joins the existing `fsm-dev` Docker
  network used by the backend and frontend services.
- **SHALL** — the collector exports to the SigNoz query service
  (FR-IN-008) and to a `debug` exporter writing to stdout for
  local inspection.

**Constitution reference:** Article IX (observability),
Article VIII. **Testable:** yes —
`test_compose_otel_service_shape` in `delivery.test.sh` parses
the merged compose file via `docker compose config` and asserts
the service definition.

---

### FR-IN-008: SigNoz services in `docker-compose.dev.yml.tmpl`

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — the compose template gains three services :
  `signoz-clickhouse` (storage backend), `signoz-query-service`
  (HTTP API), and `signoz-frontend` (web UI on port 3301). All
  three images MUST be pinned to a specific version (current
  SigNoz release at the time of the change ; recorded in
  `standards/infra/observability-local.md`).
- **MUST** — `signoz-frontend` exposes port `3301` to the host.
  Other ports (Clickhouse 9000, query service 8080) MUST be
  internal-only (no `ports:` mapping to the host).
- **MUST** — every SigNoz service has a healthcheck and a
  restart policy of `unless-stopped`.
- **MUST** — `signoz-query-service` depends on
  `signoz-clickhouse` with `condition: service_healthy`.
  `signoz-frontend` depends on `signoz-query-service` with
  `condition: service_healthy`.
- **SHALL** — the SigNoz stack uses a named volume
  `signoz-clickhouse-data` for persistence between
  `task dev` invocations.
- **SHOULD** — the `Taskfile.yml.tmpl` gains a target
  `task observe` that opens `http://localhost:3301` in the
  default browser using `open` (macOS) or `xdg-open` (Linux).

**Constitution reference:** Article IX. **Testable:** yes —
`test_compose_signoz_services_shape` in `delivery.test.sh`.

---

### FR-IN-009: OTel exporter env defaults shipped to apps

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — two new templates exist :
    - `.forge/templates/archetypes/full-stack-monorepo/backend/.env.dev.tmpl`
    - `.forge/templates/archetypes/full-stack-monorepo/frontend/.env.dev.tmpl`
- **MUST** — both files declare
  `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317`
  and `OTEL_SERVICE_NAME=<project-name>-<layer>` (substituted
  by the scaffolder).
- **MUST** — both files declare
  `OTEL_TRACES_EXPORTER=otlp`,
  `OTEL_METRICS_EXPORTER=otlp`,
  `OTEL_LOGS_EXPORTER=otlp`.
- **MUST** — the backend `.env.dev` declares
  `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` and the frontend declares
  `http/protobuf` (Flutter SDK constraint — gRPC is unsupported
  in the official Dart OTel SDK at the time of this change).
- **SHALL** — both files contain a header comment block warning
  that they are committed to the repo (no secrets) and that any
  secret-containing file MUST go in `.env.local` (gitignored
  by the scaffolder's `.gitignore` template).

**Constitution reference:** Article IX, Article VIII (no secrets in
shared config). **Testable:** yes —
`test_env_dev_files_export_otel_defaults` in `delivery.test.sh`.

---

### FR-IN-010: Standard `infra/ci-workflows.md`

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — a file `.forge/standards/infra/ci-workflows.md` exists
  with the canonical H2 sections :
    - `## Per-layer paths filter`
    - `## Gate ordering` (language-specific checks before Forge
      gates ; documented rationale)
    - `## Integration workflow scope` (main + nightly only ; never
      per-PR)
    - `## Concurrency policy`
    - `## Caching strategy`
    - `## Tool version pinning`
    - `## Failure semantics`
- **MUST** — the standard names every reference workflow shipped
  by FR-IN-002..005 and links to its `.tmpl` path.
- **SHALL** — the standard documents how a downstream project
  may add layer-specific extensions (additional steps before the
  Forge gates) without breaking the contract.

**Constitution reference:** Article V, Article X. **Testable:** yes
— `test_standard_ci_workflows_has_required_sections` in
`delivery.test.sh`.

---

### FR-IN-011: Standard `infra/k8s-overlays.md`

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — a file `.forge/standards/infra/k8s-overlays.md` exists
  with the canonical H2 sections :
    - `## Three-environment promotion model`
    - `## Per-overlay diff conventions` (what is allowed to differ
      between dev/staging/prod and what MUST stay shared)
    - `## Image tag policy by environment`
    - `## Resource budget table` (CPU/memory requests/limits per env)
    - `## Secret management` (which Kustomize patterns are allowed —
      Sealed Secrets, External Secrets, etc. — and which are
      explicitly forbidden — plain `Secret` with base64 values)
    - `## Promotion gating` (how the Forge change lifecycle maps
      to environment promotion)
- **MUST** — the standard explicitly forbids hand-editing the
  rendered output of `kustomize build`.

**Constitution reference:** Article VIII, Article X. **Testable:**
yes — `test_standard_k8s_overlays_has_required_sections` in
`delivery.test.sh`.

---

### FR-IN-012: Standard `infra/observability-local.md`

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — a file `.forge/standards/infra/observability-local.md`
  exists with the canonical H2 sections :
    - `## Local OTel + SigNoz topology`
    - `## App-side OTLP configuration` (env vars per layer)
    - `## Versioning policy` (how pinned versions are tracked and
      bumped)
    - `## Trace sampling defaults`
    - `## Migration to production observability` (explicit out-of-scope
      pointer + migration runbook)
- **MUST** — the standard records the exact pinned image versions
  for `otel-collector`, `signoz-clickhouse`,
  `signoz-query-service`, `signoz-frontend` (single source of
  truth — the compose template references the standard's
  versions, not vice versa).

**Constitution reference:** Article IX. **Testable:** yes —
`test_standard_observability_local_has_required_sections` in
`delivery.test.sh`.

---

### FR-GL-024: Schema promotion to stable / 1.0.0

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — once `b1-delivery` is archived, the file
  `.forge/schemas/full-stack-monorepo/schema.yaml` MUST declare,
  in its top-level metadata block :
    - `status: stable`
    - `version: "1.0.0"`
    - `promoted_from: "1.0.0-rc.1"`
    - `promoted_in: b1-delivery`
    - `promoted_on: "<archive-date>"`
- **MUST** — the corresponding spec
  `.forge/specs/full-stack-monorepo.md` MUST gain a row in the
  Schema Evolution table recording the promotion (`1.0.0-rc.1 →
  1.0.0`, change `b1-delivery`, archive date, rationale "B.1
  archetype contract fully delivered : foundations + scaffolder +
  workflow + delivery").
- **MUST** — no other field of the schema (layers, contracts,
  cross-layer agent name) MUST change as part of the promotion.
  Promotion is **purely a status + version edit**.

**Constitution reference:** Article IV (semantic deltas), Article V.
**Testable:** yes — `test_schema_header_post_archive` in
`delivery.test.sh` (gated on the change's status being `archived`).

---

### FR-GL-025: Test harness `delivery.test.sh`

<!-- From change: b1-delivery (2026-04-29) -->

- **MUST** — a file `.forge/scripts/tests/delivery.test.sh` exists
  and is executable.
- **MUST** — the harness sources the existing test framework used
  by `foundations.test.sh` and `workflow.test.sh` (no new
  framework, no duplication).
- **MUST** — every test asserted as Testable in FR-IN-002..012 and
  FR-GL-024 has at least one corresponding test function in this
  file.
- **MUST** — running `bash .forge/scripts/tests/delivery.test.sh`
  exits 0 when every fixture passes and non-zero on the first
  failure, with a clear `[FAIL] <test-name>: <reason>` line.
- **SHALL** — the harness uses `act` (or a documented equivalent)
  to dry-run the workflow YAML where YAML parsing alone is
  insufficient. Where `act` is unavailable on the runner, the
  test MUST gracefully `[SKIP]` rather than fail.

**Constitution reference:** Article I (TDD harness), Article V.
**Testable:** yes — meta-test : the harness's own self-check
asserts that every FR ID listed above has a matching
`test_*` function (lookup by string match on a manifest header
in the harness file).

---

## MODIFIED Requirements

### FR-GL-001: Schema `full-stack-monorepo` declares the monorepo contract

<!-- Modified by: b1-delivery (2026-04-29) -->

**Previously** — the schema header declared `status: candidate`
and `version: "1.0.0-rc.1"` because the archetype was not yet
end-to-end runnable (no CI, no overlays, no local observability).

**Now** — once `b1-delivery` is archived, the schema header MUST
declare `status: stable` and `version: "1.0.0"`, with traceability
fields `promoted_from`, `promoted_in`, `promoted_on` populated
per FR-GL-024. The contract surface (layers, contracts, agent
references) is unchanged ; only the gate on whether the archetype
is fit for general adoption flips.

**Reason** — the archetype's documented deliverables (foundations
contract + scaffolder + workflow + delivery surface) are all
realised by the closure of `b1-delivery`. Holding the schema at
`candidate` after that point would be inaccurate.

---

## REMOVED Requirements

*None.* This change is purely additive ; no prior requirement is
deprecated or removed.

---

## Acceptance Criteria

### AC-001 — Links FR-IN-002 : backend workflow ignores out-of-scope changes

```gherkin
Given a project freshly scaffolded via `/forge:init --archetype full-stack-monorepo`
And a pull request that touches only `frontend/lib/main.dart`
When the pull request is opened
Then the `forge-backend.yml` workflow runs
But every job in `forge-backend.yml` reports `skipped` because the dorny/paths-filter
  did not match `backend/**` nor `shared/protos/**`
```

### AC-002 — Links FR-IN-002 : backend workflow blocks merge on a clippy warning

```gherkin
Given the same scaffolded project
And a pull request that introduces a `clippy::needless_clone` warning in `backend/crates/domain/src/lib.rs`
When the pull request is opened
Then the `forge-backend.yml` workflow runs
And the `cargo clippy` step fails with a non-zero exit code
And the pull request is reported as failing the required `forge-backend.yml` check
```

### AC-003 — Links FR-IN-003 : frontend workflow blocks merge on a flutter analyze error

```gherkin
Given the same scaffolded project
And a pull request that introduces an unused import in `frontend/lib/features/home.dart`
When the pull request is opened
Then `forge-frontend.yml` runs and `flutter analyze --fatal-infos --fatal-warnings` fails
```

### AC-004 — Links FR-IN-004 : infra workflow blocks merge on an invalid Kubernetes manifest

```gherkin
Given the same scaffolded project
And a pull request that adds an invalid `apiVersion` to a manifest under `infra/k8s/base/`
When the pull request is opened
Then `forge-infra.yml` runs `kustomize build` successfully
But `kubeconform --strict` fails with a schema validation error
And the workflow exits non-zero
```

### AC-005 — Links FR-IN-005 : nightly integration boots the full stack

```gherkin
Given the same scaffolded project
When the cron-scheduled `forge-integration.yml` workflow fires
Then `docker compose up -d --wait` reports every service healthy within 10 minutes
And the backend integration test suite executes against the live stack
And the Patrol end-to-end suite executes against the headless Android emulator
And teardown via `docker compose down -v` runs even if the test stage fails
```

### AC-006 — Links FR-IN-006 : Kustomize overlays render and validate

```gherkin
Given the same scaffolded project
When `kustomize build infra/k8s/overlays/dev` is executed
Then the command exits 0
And the rendered YAML declares the namespace `<project>-dev`
And the rendered YAML pins the image to a tag matching `:dev-latest`
And `kubeconform --strict` against the rendered YAML exits 0

When the same is repeated for `overlays/staging` and `overlays/prod`
Then both also exit 0
And `staging` pins the image to a `sha-` tag
And `prod` pins the image to a `v` tag
And `prod` includes a HorizontalPodAutoscaler resource
```

### AC-007 — Links FR-IN-007, FR-IN-008 : `task dev` boots the observability stack

```gherkin
Given the same scaffolded project on a clean machine
When `task dev` is executed
Then `docker compose -f docker-compose.dev.yml up -d --wait` reports every service healthy
And `otel-collector` is reachable on `localhost:4317` (gRPC) and `localhost:4318` (HTTP)
And `signoz-frontend` is reachable on `http://localhost:3301`
And the OTel collector logs show successful export to the SigNoz query service
```

### AC-008 — Links FR-IN-009 : the scaffolded apps trace to the local stack out of the box

```gherkin
Given the same scaffolded project running under `task dev`
When the backend is hit by a sample request (`curl http://localhost:8080/health`)
Then a span appears in the SigNoz UI under the service name `<project>-backend` within 30 seconds
And the span's `service.name` resource attribute equals `<project>-backend`
```

### AC-009 — Links FR-GL-024 : schema promotion is recorded and traceable

```gherkin
Given the change `b1-delivery` is archived
When `.forge/schemas/full-stack-monorepo/schema.yaml` is inspected
Then the header declares `status: stable`
And the header declares `version: "1.0.0"`
And the header declares `promoted_from: "1.0.0-rc.1"`
And the header declares `promoted_in: b1-delivery`
And the spec `.forge/specs/full-stack-monorepo.md` Schema Evolution table contains a row for the promotion
```

### AC-010 — Links FR-GL-025 : test harness self-consistency

```gherkin
Given the file `.forge/scripts/tests/delivery.test.sh` exists
When `bash .forge/scripts/tests/delivery.test.sh` is executed in a clean shell
Then the harness exit code is 0
And every FR ID in this spec marked Testable has a matching `test_*` function in the harness
And the harness manifest header lists every test function it expects to find
```

---

## Non-Functional Requirements

### NFR-013: Per-layer workflow runtime budget

- **MUST** — the per-layer workflows (`forge-backend.yml`,
  `forge-frontend.yml`, `forge-infra.yml`) MUST complete in ≤ 8
  minutes wall-clock on the standard `ubuntu-latest` runner with a
  warm cache, measured on the reference scaffolded project.
- **SHALL** — cold-cache runs MUST complete in ≤ 15 minutes.
- **Rationale** — beyond ~10 min on PRs, contributors disengage ;
  the gate must stay fast enough to be developer-friendly.
- **Testable** — the harness records elapsed time per workflow on
  a fixture run and compares against a numeric threshold.

### NFR-014: Integration workflow runtime budget

- **MUST** — `forge-integration.yml` MUST complete (success or
  failure) in ≤ 30 minutes wall-clock on `ubuntu-latest`.
- **SHALL** — a workflow exceeding 25 minutes emits a warning
  annotation in the GitHub Actions UI.
- **Rationale** — nightlies that bleed past 30 min collide with
  the next day's morning and frustrate triage.

### NFR-015: Local observability stack startup time

- **MUST** — `docker compose -f docker-compose.dev.yml up -d --wait`
  MUST report all observability services (otel-collector,
  signoz-clickhouse, signoz-query-service, signoz-frontend)
  healthy within 90 seconds on a developer-class machine
  (defined as : 8 CPU cores, 16 GB RAM, SSD).
- **Rationale** — > 90 s breaks the "task dev and go" promise of
  the archetype.

### NFR-016: Reference workflow file size

- **SHOULD** — each reference workflow file MUST be ≤ 250 lines
  (including comments) to stay legible to a human reviewer.
- **Rationale** — workflows that grow beyond a screenful become
  bug magnets ; complex logic should be extracted into reusable
  composite actions, not inlined.

### NFR-017: Overlay diffability

- **SHOULD** — the YAML diff between `kustomize build
  overlays/dev` and `kustomize build overlays/prod` MUST be ≤ 4 KB
  (uncompressed) for the reference scaffolded project. Deltas
  larger than that signal that the base is too thin and the
  overlays have absorbed responsibilities they should share.
- **Rationale** — Kustomize's value is the *shape* of the diff ;
  bloated overlays defeat the model.

### NFR-018: Image version pinning audit trail

- **MUST** — every container image referenced by the reference
  templates (workflows, compose, overlays) MUST be pinned to a
  specific version tag. Tag `:latest` is forbidden.
- **MUST** — the version pinning is documented in
  `standards/infra/observability-local.md` (for the OTel + SigNoz
  stack) and in inline comments for application image references.

---

## Out of Scope

- **GitHub App "Forge Guardian"** (G.3) — the per-layer workflows
  do enough constitutional gating for v1.0.0. A higher-fidelity
  GitHub App is a future module.
- **Helm chart parity with the Kustomize overlays** — Kustomize is
  the canonical choice for v1.0.0. A future change can add Helm
  parity if demand emerges.
- **Production observability** — managed collector, retention
  policy, alerting rules, RBAC. Local dev only here ; production
  observability is intentionally deferred and explicitly pointed
  to in `standards/infra/observability-local.md` § Migration to
  production observability.
- **Coverage reporting upload to a third-party service** — the
  frontend workflow MAY upload `lcov.info` as a build artifact,
  but no Codecov / Coveralls integration is prescribed. Project-owned.
- **Release workflow for the scaffolded project itself** — Forge
  scaffolds projects ; it does not prescribe how those projects
  release. Adopters use whatever release tooling they prefer
  (`release-please`, manual tagging, etc.).
- **iOS CI** — `ubuntu-latest` cannot host an iOS toolchain. The
  reference workflows cover Android E2E only. iOS in CI is the
  domain of the `mobile-only` archetype (B.4) and out of scope here.
- **Updates to existing scaffolded projects in the wild** — there
  are none yet (archetype was `candidate`). The path forward for
  future adopters lagging behind a schema bump is `forge upgrade`
  (A.7) — separate change.

---

## Open Questions

*None blocking.* Every implementation choice that surfaced during
spec authoring resolved cleanly to a documented standard or to an
explicit Out of Scope item :

- *(resolved)* `kubeval` vs `kubeconform` for manifest validation →
  `kubeconform` only (faster, actively maintained, supports CRDs
  via the Datree catalog). Recorded in FR-IN-004.
- *(resolved)* SigNoz `:latest` vs pinned version → pinned, with
  the version recorded in `standards/infra/observability-local.md`
  per FR-IN-012 and NFR-018.
- *(resolved)* Whether to ship a Patrol-based E2E or a simpler
  smoke test → Patrol is the canonical Flutter E2E, already
  declared in `b1-foundations` for the integration_test/ directory.
  The integration workflow consumes whatever the scaffolder writes.
- *(resolved)* Scope of `task observe` — only opens the SigNoz
  UI ; it does NOT boot the stack itself (`task dev` does). One
  responsibility per task.

If new clarification arises during `/forge:design b1-delivery`,
record it here as `[NEEDS CLARIFICATION: ...]` and STOP.
