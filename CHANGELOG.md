# Changelog

All notable changes to the Forge Framework are documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(see [docs/VERSIONING.md](docs/VERSIONING.md) for our exact policy and its
coupling to the Constitution version).

While Forge is on the `0.y.z` pre-GA track, breaking changes may land in a
minor bump and will be called out under a `### BREAKING` subsection.

## [Unreleased]

**Module B.1 closed — flagship archetype `full-stack-monorepo`
delivered end-to-end.** Four changes accumulated since v0.2.1
(`b1-foundations` → `b1-scaffolder` → `b1-workflow` → `b1-delivery`)
combine to ship a contract-conformant Flutter + Rust + Infra
monorepo with multi-layer change orchestration, 4 reference CI
workflows, Kustomize base + 3 deployment overlays, and a local
OTel + SigNoz observability stack — scaffoldable in ~3 seconds via
`/forge:init --archetype full-stack-monorepo`. The schema is
promoted from `draft / 0.1.0` (foundations) → `candidate /
1.0.0-rc.1` (scaffolder) → **`stable / 1.0.0`** (delivery), with
`promoted_from / promoted_in / promoted_on` traceability fields.
75/75 test scenarios PASS across 4 harnesses.

### Added — `b1-delivery` (2026-04-29)

Final B.1 brick — runtime delivery surface (CI + deployment +
observability). Templates live under
`.forge/templates/archetypes/full-stack-monorepo/`, inert until a
project is scaffolded. Zero scaffolder code change ;
`scaffold-plan.yaml` gains 18 entries and removes 3 obsolete
`.gitkeep` placeholders.

- **4 reference GitHub Actions workflows** under `.github/workflows/`
  (FR-IN-002..005) :
    - `forge-backend.yml` — `dorny/paths-filter@v3` on `backend/**`
      OR `shared/protos/**` ; `cargo fmt → clippy -D warnings →
      test → verify.sh → constitution-linter.sh`. Two-job split
      (filter + build gated on output) for clean PASS-with-skip
      semantics on out-of-scope PRs ; `actions/cache@v4` keyed on
      `Cargo.lock` per ADR-011.
    - `forge-frontend.yml` — same shape on `frontend/**` ; Flutter
      SDK pinned via `.flutter-version` consumed by
      `subosito/flutter-action@v2` ; `pub get → dart format
      --set-exit-if-changed → flutter analyze --fatal-infos
      --fatal-warnings → flutter test --coverage → Forge gates`.
    - `forge-infra.yml` — `dorny/paths-filter@v3` on `infra/**` ;
      `kustomize build × 3 overlays → kubeconform --summary
      --strict × 3 → Forge gates`. `imranismail/setup-kustomize@v2`
      pinned to 5.4.2, kubeconform 0.6.7 from upstream tarball
      (ADR-008).
    - `forge-integration.yml` — triggers ONLY on `push: main` +
      nightly cron `'0 3 * * *'` UTC + `workflow_dispatch` (NFR-014
      protection). `docker compose up -d --wait` (ADR-012) → cargo
      integration tests → Patrol Android E2E on
      `reactivecircus/android-emulator-runner@v2` API 34 →
      `if: always()` teardown.

- **Kustomize base + 3 overlays** under `infra/k8s/` (FR-IN-006) :
    - `base/` — Deployment (gRPC :50051 + HTTP :8080, /healthz +
      /readyz probes, OTLP env from optional ConfigMap, resource
      requests/limits) + Service (ClusterIP, named ports) +
      ServiceAccount (`automountServiceAccountToken: false`) +
      Ingress (host placeholder).
    - `overlays/dev` — namespace `<project>-dev`, image
      `dev-latest`, replicas: 1, ConfigMapGenerator with
      `OTEL_EXPORTER_OTLP_ENDPOINT` + `APP_ENV=dev`,
      commonAnnotations `forge.io/managed-by`, `forge.io/overlay`,
      `forge.io/project`.
    - `overlays/staging` — namespace `<project>-staging`, image
      `sha-replace-at-deploy`, replicas: 2.
    - `overlays/prod` — namespace `<project>-prod`, image
      `v0.0.0-replace-at-release`, replicas: 3 baseline +
      `HorizontalPodAutoscaler` (autoscaling/v2, min=3, max=10,
      CPU averageUtilization 70%).

- **Local OTel + SigNoz observability stack** in
  `docker-compose.dev.yml.tmpl` (FR-IN-007 + FR-IN-008) — 4 new
  services on the existing `fsm-dev` network with the existing
  `fsm-` prefix convention :
    - `fsm-otel-collector` —
      `otel/opentelemetry-collector-contrib:0.96.0`. OTLP gRPC
      :4317 + OTLP HTTP :4318 + health :13133. Config in
      `infra/observability/otel-collector-config.yaml` declares
      `memory_limiter` (256 MiB cap) → `batch` processors and
      `traces / metrics / logs` pipelines (Article IX three
      signals).
    - `fsm-signoz-clickhouse` —
      `clickhouse/clickhouse-server:24.1.2-alpine`. Internal-only.
      Named volume `signoz-clickhouse-data` for persistence.
    - `fsm-signoz-query` — `signoz/query-service:0.55.1`.
      Internal-only. Auth disabled in dev (with explicit
      MUST-flip-on comment for staging/prod).
    - `fsm-signoz-frontend` — `signoz/frontend:0.55.1`. Only
      observability service host-exposing a port (3301).
      `depends_on` chain : `query → clickhouse: service_healthy`,
      `frontend → query: service_healthy`. `restart:
      unless-stopped` on every SigNoz service.

- **App-side OTLP defaults** (FR-IN-009) — `backend/.env.dev` and
  `frontend/.env.dev` ship 7 `OTEL_*` env vars. Backend uses
  gRPC :4317 ; frontend uses HTTP/protobuf :4318 (Dart SDK
  constraint documented inline). Both files header-flagged "no
  secrets — use `.env.local`" (gitignored by scaffolder).

- **`task observe`** target in `Taskfile.yml.tmpl` (FR-IN-008) —
  opens `http://localhost:3301` in the default browser via `open`
  (macOS) or `xdg-open` (Linux), echo fallback otherwise.

- **3 new infra standards** (FR-IN-010..012) :
    - `standards/infra/ci-workflows.md` (~180 lines) — 7 canonical
      H2 sections (paths filter, gate ordering, integration scope,
      concurrency, caching, tool pinning, failure semantics) +
      tables + extension budget (max 2 extra steps before Forge
      gates).
    - `standards/infra/k8s-overlays.md` (~150 lines) — 6 canonical
      H2 sections, per-overlay diff table, image tag policy table,
      resource budget table, secret management Allowed/Forbidden,
      promotion-gating mapping (Forge change status → eligible
      environments).
    - `standards/infra/observability-local.md` (~150 lines) — 5
      canonical H2 sections, version table as single source of
      truth for the 4 pinned images, 5-step migration runbook to
      production-grade observability (managed collector → tail
      sampling → auth flip → retention → alerts).
    - `.forge/standards/index.yml` extended with 3 entries
      (scope: infra, priority: high).

- **Schema promotion** (FR-GL-001 MODIFIED + FR-GL-024) —
  `.forge/schemas/full-stack-monorepo/schema.yaml` flips
  `stage: candidate / version: "1.0.0-rc.1"` →
  `stage: stable / version: "1.0.0"` and gains
  `promoted_from: "1.0.0-rc.1"`, `promoted_in: b1-delivery`,
  `promoted_on: "2026-04-29"`. Spec `Schema evolution` table
  records the event.

- **`delivery.test.sh` harness** (FR-GL-025) — 24 tests across L1
  structural / L2 fixture / L3 long-mode levels, sharing
  `_helpers.sh` with the prior 3 harnesses (ADR-010). Manifest
  comment block declares every `test_*` ;
  `test_manifest_self_consistency` is the meta self-check.
  `test_schema_header_post_archive` is gated on
  `.forge.yaml status: archived` per ADR-009 (SKIPS during
  implementation, PASSES post-archive).

- **6 NFRs** (NFR-013..018) — per-layer workflow runtime budgets
  (≤8min warm / ≤15min cold), integration ≤30min, observability
  stack startup ≤90s, workflow file ≤250 lines, overlay diff
  ≤4KB, image pinning audit trail (no `:latest` anywhere,
  enforced by `test_no_latest_tag_anywhere`).

- **BDD feature file** at `.forge/changes/b1-delivery/features/`
  with 5 scenarios mirroring AC-001/002/006/007/008.

### Added — `b1-workflow` (2026-04-23)

Multi-layer change workflow + cross-layer orchestration. Adds the
ability for a single change to span backend + frontend + infra
with per-layer designs and tasks, coordinated by a new agent.

- **Janus agent** (`.claude/agents/cross-layer-orchestrator.md`,
  FR-GL-015) — Roman mythology persona for the cross-layer
  orchestrator. Pure orchestrator (NEVER writes application code,
  ADR-001) ; dispatches Hera (frontend), Vulcan (backend), Atlas
  (infra), Hermes-API (protos contracts) ; aggregates outputs ;
  enforces cross-layer contract alignment ; surfaces conflicts as
  `[NEEDS CLARIFICATION]` rather than silently resolving them.
  12-step workflow.

- **Multi-layer change metadata** (FR-GL-016) —
  `.forge/templates/change.yaml` gains 3 optional top-level fields :
  `layers:` (subset of archetype schema's `layers[].id`),
  `designs_per_layer:` (map layer-id → filename),
  `tasks_per_layer:` (same shape). Required when `layers:` has ≥ 2
  entries ; backwards-compatible when single-layer or absent.

- **Validator multi-layer check** (FR-GL-017) —
  `validate-foundations.sh` gains `check_multi_layer_change_metadata`
  inspecting every `.forge/changes/*/.forge.yaml`. Validates layer
  ids against schema, requires per-layer files when multi-layer,
  rejects unknown layer ids. Skips cleanly on non-monorepo
  projects.

- **Standard `global/multi-layer-workflow.md`** (FR-GL-018) — 6
  canonical H2 sections covering routing policy (single-layer vs
  multi-layer), per-layer deliverable conventions, cross-layer
  contract alignment rules, Hermes-API delegation (ADR-003).

- **Multi-root `verify.sh` and `constitution-linter.sh`**
  (FR-BE-002, FR-FE-002, FR-GL-021, FR-GL-022) — when the target
  declares the `full-stack-monorepo` schema, the scripts walk
  `frontend/`, `backend/`, `shared/protos/`, `infra/` separately
  and prefix every output line with `[backend]`, `[frontend]`,
  `[protos]`, `[infra]`. Layer paths read dynamically from the
  schema's `layers[].path` (ADR-004), preserving single-root mode
  on non-monorepo projects (NFR-010 backwards compatibility).

- **Per-layer templates** (FR-GL-020) —
  `.forge/templates/{design,tasks}-per-layer.md` with cross-layer
  references first, layer-prefixed phase numbering (ADR-010).

- **Index extension** — `global/multi-layer-workflow` added to
  `.forge/standards/index.yml` (scope: monorepo, priority: high).

- **`workflow.test.sh` harness** (FR-GL-023) — 16 tests across L1
  structural + L2 fixture-based + L3 multi-root E2E levels.

- **Spec change** : MODIFIED FR-GL-008 — validator gains the
  Section 7 dispatch for multi-layer checks. 11 ADDED FRs, 4
  ADDED NFRs (NFR-009..012).

### Added — `b1-scaffolder` (2026-04-22)

- `.forge/templates/archetypes/full-stack-monorepo/` — complete
  archetype template tree : root (CLAUDE.md, Taskfile.yml,
  docker-compose.dev.yml, .env.example, .gitignore, .forge.yaml,
  README.md), nested `CLAUDE.md` per layer (Flutter/Rust/infra scope
  declarations), backend workspace (Cargo.toml + rust-toolchain),
  proto seed (buf.yaml + buf.gen.yaml + example.proto), infra stubs
  (kong.yml.example + distroless Dockerfile.backend.example),
  `.gitkeep` markers — 25 templates, ~1400 lines.
- `.forge/templates/archetypes/full-stack-monorepo/scaffold-plan.yaml`
  — single source of truth consumed by the overlay renderer and the
  init orchestrator. Declares the 7 official scaffolder invocations,
  the 24 template entries (source → target, substitute yes/no), and
  2 post-steps (write manifest, run validator).
- `.forge/scripts/scaffolder/overlay.sh` — template overlay renderer.
  Python 3 + PyYAML. Regex-validates `<project-name>` and
  `<reverse-domain>` before any interpolation. Writes
  `.forge/scaffold-manifest.yaml` with SHA of plan + SHA of template
  set + scaffold date (honors `SOURCE_DATE_EPOCH` for reproducible
  builds).
- `.forge/scripts/scaffolder/init.sh` — end-to-end orchestrator. 7
  non-negotiable steps : validate args + tool versions (flutter ≥ 3.24,
  cargo ≥ 1.80, buf ≥ 1.30), copy framework assets, `flutter create
  frontend`, overlay templates, `cargo new` for 5 crates (auto-joining
  the pre-written workspace manifest), `buf lint` (WARN), run
  `validate-foundations.sh`. Exit 7 with tree preserved if the
  scaffolded target fails the contract.
- `.forge/scripts/tests/scaffolder.test.sh` — three-level test harness.
  L1 = plan shape (7 scenarios, hermetic). L2 = overlay rendering with
  substitution/force/idempotence/manifest/regex checks (7 scenarios,
  hermetic). L3 = E2E (7 scenarios, requires flutter + cargo + buf on
  PATH — auto-skipped otherwise unless `--require-external-tools`).
- `.forge/scripts/tests/_helpers.sh` — shared helpers
  (`assert_eq`/`assert_contains`/`run_test`/`print_summary`/`mk_tmpdir_with_trap`)
  sourced by both foundations and scaffolder harnesses. Eliminates
  duplication.
- `.forge/changes/b1-scaffolder/features/b1-scaffolder.feature` —
  9 Gherkin scenarios (7 AC + NFR-005 idempotence + NFR-006 perf).

### Changed

- `.forge/schemas/full-stack-monorepo/schema.yaml` — promoted from
  `draft / 0.1.0` to **`candidate / 1.0.0-rc.1`**. Promotion trigger
  per `b1-foundations` ADR-004 : successful end-to-end scaffold via
  b1-scaffolder (21/21 tests + manual smoke). Further promotion to
  `stable / 1.0.0` requires 3 external adopters publicly scaffolded
  (audit C.1).
- `.claude/commands/forge/init.md` — new `## Archetype Branch`
  section documenting `--archetype full-stack-monorepo` usage,
  prerequisites, the 7-step sequence, flags, exit codes, and testing
  matrix.
- `.forge/scripts/verify.sh` — new conditional section
  `## 6. Scaffolder (conditional)` invokes the scaffolder harness at
  `--level 2` (hermetic) when the archetype template tree exists ;
  aggregates PASS/FAIL into verify.sh totals.
- `.forge/scripts/tests/foundations.test.sh` — now sources the shared
  `_helpers.sh` (Phase 1.1 refactor of b1-scaffolder). Zero regression
  (21/21 tests still green).
- `.forge/specs/full-stack-monorepo.md` — 9 new FRs appended
  (FR-GL-009..014 + FR-BE-001 + FR-FE-001 + FR-IN-001) + 4 new NFRs
  (NFR-005..008). Archived-changes table and schema-evolution log
  updated.

### Fixed

- `.forge/scripts/tests/scaffolder.test.sh` L3 revealed that the
  scaffolded project was missing `docs/VERSIONING.md`, which caused
  FR-GL-006 to FAIL on the scaffolded-target validator. Fix : `init.sh`
  now copies the entire `docs/` directory from the source Forge repo
  into the scaffolded project. Adopters replace the content with
  project-specific docs over time.
- Rogue `.omc/state/` artifact cleaned out of the archetype template
  directory (sub-agent orchestration metadata that had leaked during
  the Phase 3 parallel write).

### Known carry-overs

- **proto-contracts.md ↔ Buf STANDARD reconciliation** — the Forge
  standard prescribes version-first directory layout (`v1/<svc>/`) ;
  Buf STANDARD lint expects service-first (`<svc>/v1/`). `buf.yaml`
  excludes `PACKAGE_DIRECTORY_MATCH` with documented justification
  pointing to a future Forge change that reconciles the two.
- **`_scaffolder_lib.sh` extraction** — still deferred after
  `b1-workflow` and `b1-delivery` archive. Per `b1-delivery`
  ADR-010, the 4 test harnesses (`foundations`, `scaffolder`,
  `workflow`, `delivery`) all source the existing shared
  `_helpers.sh` and otherwise duplicate ~50 lines of harness
  scaffolding ; pulling the duplication into a `_scaffolder_lib.sh`
  remains a future cleanup, re-evaluated if a fifth harness lands
  with material overlap.

### Performance baseline

Full scaffold of a demo project on macOS 14.5 / Flutter 3.41.7 /
Cargo 1.91.0 / Buf 1.68.3 : **~3 seconds** (NFR-006 warm budget : 30s,
hard ceiling : 60s). Validator performance unchanged : ~360 ms (NFR-002
budget : 2000 ms).

---

### Added — `b1-foundations` (2026-04-21)

First delivery of the flagship archetype `full-stack-monorepo` — the
foundation layer (contract + validator + standards). Scaffolder, workflow,
and delivery layers are tracked separately and will follow in
`b1-scaffolder`, `b1-workflow`, `b1-delivery` respectively.

Template set :

- `.forge/schemas/full-stack-monorepo/schema.yaml` — monorepo schema
  declaring the 3 canonical layers (`backend`/`frontend`/`infra`), their
  agent routing (Vulcan/Hera/Atlas), cross-layer orchestration via `Janus`
  (agent to be delivered by `b1-workflow`), FR-ID prefixes, and the
  `stage: draft → candidate → stable` bump policy. Stage `draft`,
  `version: 0.1.0`.
- `.forge/standards/global/monorepo-layout.md` — canonical directory tree,
  isolation rules between layers, nested `CLAUDE.md` pattern for JIT
  context scoping, FR-ID prefix convention (180 lines).
- `.forge/standards/global/proto-contracts.md` — Protobuf as single
  source of truth for cross-layer contracts: `shared/protos/` layout,
  versioning via namespaced `v1/`/`v2/`, blocking `buf lint` +
  `buf breaking` gates, stub generation via `tonic-build` (Rust) +
  `protoc_plugin` (Dart) (169 lines).
- `.forge/standards/infra/docker-compose.md` — local-dev orchestration
  discipline: `fsm-` service prefix, single named network `fsm-dev`,
  mandatory healthchecks, `.env.example` hygiene, ban on unsuffixed
  `docker-compose.yml` (239 lines).
- `.forge/scripts/validate-foundations.sh` — deterministic structural
  validator for the archetype contract (Python 3 + PyYAML). Exits 0/1,
  emits `PASS: FR-GL-XXX — msg` / `FAIL: FR-GL-XXX — msg` lines.
  Runs in ~360 ms on the real repo (NFR-002 budget: 2000 ms).
- `.forge/scripts/tests/foundations.test.sh` — shell test harness with
  21 scenarios (unit checks + RED/GREEN meta-tests + idempotence +
  performance).
- `.forge/specs/full-stack-monorepo.md` — archived requirements (8 FRs +
  4 NFRs) for the archetype, accumulating across future B.1 changes.
- `.forge/changes/b1-foundations/features/b1-foundations.feature` —
  10 Gherkin scenarios materialising the spec acceptance criteria
  (satisfies Article II check in `constitution-linter.sh`).

### Changed — `b1-foundations`

- `.forge/standards/global/git-workflow.md` — new section
  `## Scoped Conventional Commits (monorepo-only)` defining the closed
  scope list `{backend, frontend, infra, protos, forge, docs, ci}`,
  activated only when the root `.forge.yaml` uses
  `schema: full-stack-monorepo`. Other schemas keep free-form scopes.
  +89 lines, non-breaking.
- `docs/VERSIONING.md` — new section `## Monorepo Versioning Models`
  documenting the two supported models (release-train vs per-package
  via `release-please`), the decision matrix, and the Forge default
  recommendation (release-train for teams ≤ 15 contributors). +101 lines.
- `.forge/standards/index.yml` — three new entries for the monorepo
  standards with new scopes `monorepo`, `protos`, `infra`.
- `.forge/scripts/verify.sh` — new conditional section
  `## 5. Monorepo Foundations` that invokes `validate-foundations.sh`
  on monorepo projects and aggregates its PASS/FAIL counters; emits
  `(validate-foundations skipped — not a monorepo)` on other projects.
  `FORGE_ROOT` is now overridable via environment variable (enables
  fixture-based testing).

### Fixed — `b1-foundations`

- `.forge/standards/index.yml` line 82 — quoted `@injectable`,
  `@singleton`, `@lazySingleton` triggers. The unquoted `@` was a latent
  YAML invalidity (reserved character in flow context) that blocked any
  strict parser from reading the index.

### Documentation — `b1-foundations`

- `.forge/product/roadmap.md` — Module B.1 marked **In Progress** with
  `b1-foundations` called out as the first delivery; remaining sub-changes
  (`b1-scaffolder`, `b1-workflow`, `b1-delivery`) enumerated.

## [0.2.1] — 2026-04-21

Packaging patch: the CLI is now actually usable when installed from npm.
The previous publish shipped a three-file tarball that could not scaffold
anything. Also completes the npm-scope rename started in `8fea01e`.

### Fixed

- **`forge init` from a published tarball now scaffolds the framework.**
  `@sdd-forge/cli@0.2.0` only embedded `dist/`, `VERSION`, and `README.md`
  in its npm tarball, so `npx @sdd-forge/cli init` produced an empty-ish
  project (three files, no `.forge/`, no `.claude/`, no `bin/`). The CLI
  now bundles all scaffoldable repo assets into `cli/assets/` via a
  `prepack` hook, and `init` resolves its default `--source` to that
  directory when it exists (falling back to the repo root for local dev).

### Added

- `cli/src/domain/bundle.ts` — pure `bundlePlan` function with five unit
  tests covering the exclusion rules (`cli/` itself, dev/build/editor
  dirs, `.claude/settings.local.json`, `.forge` runtime state
  `product/`, `_memory/`, `changes/`, `specs/`).
- `cli/scripts/bundle-assets.mjs` — walker that applies `bundlePlan` and
  copies the result into `cli/assets/`. Wired as `npm run bundle`,
  `prepack`, and `prepublishOnly` so published tarballs always contain
  fresh assets.
- `cli/src/cli.ts` now exposes an internal `assetsRoot()` resolver:
  `<pkg>/assets/` when present (published mode), `<pkg>/..` otherwise
  (repo-local dev mode).
- New e2e suite `published-tarball layout (bundled assets/)` that runs
  the bundle script, invokes `forge init` without `--source`, and
  asserts that `.forge/constitution.md`, `.claude/settings.json`,
  `bin/forge-install.sh`, `.mcp.json`, `LICENSE`, and `NOTICE` are
  scaffolded, with `cli/` and `settings.local.json` confirmed absent.
- `cli/.gitignore` — ignores the generated `assets/` directory.

### Changed

- **npm package renamed from `@forge/cli` to `@sdd-forge/cli`.** The
  `@forge` scope on npm is already taken. All references updated across
  `package.json`, lockfile, READMEs, `CHANGELOG`, `SECURITY`,
  `docs/VERSIONING`, the roadmap, and the bug-report template. Users
  must `npm uninstall -g @forge/cli` (if installed) and install the new
  package: `npm i -g @sdd-forge/cli`.
- `cli/package.json` — `files` now includes `assets/`; added `bundle`,
  `prepack`, and updated `prepublishOnly` so `npm publish` always
  rebuilds and re-bundles before shipping.
- `cli/README.md` — Development section documents the new `bundle`
  step and the generated `assets/` layout.

### Packaging

- Published tarball grows from 3 files / ~5 kB to 158 files / 290 kB
  compressed (896 kB unpacked) — the first figure that actually
  contains a functional Forge install.

## [0.2.0] — 2026-04-21

T1 milestone: packaging, distribution, and governance. Forge becomes
installable via three independent channels (shell, npm, Docker) and ships
the minimum governance paperwork required for open contribution.

### Added

- `VERSION` file at the repo root, SemVer-bound to the Constitution (A6).
- `docs/VERSIONING.md` — versioning policy, Constitution coupling, release
  artifact checklist (A6).
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1, enforcement routed to
  benoit.fontaine@septeo.com (D1).
- `SECURITY.md` — supported versions, private reporting channels, SLAs,
  coordinated disclosure, safe harbour (D2).
- `CHANGELOG.md` — this file, backfilled with T0 (D3).
- `.github/ISSUE_TEMPLATE/` — bug, feature, and spec-clarification issue
  forms plus `config.yml` pointing security reports at the private
  advisory channel (D4).
- `.github/pull_request_template.md` — Constitution / TDD / Context7
  compliance checklist (D4).
- `bin/forge-install.sh` — idempotent installer that copies `.forge/`,
  `.claude/`, `.mcp.json`, `CLAUDE.md`, `VERSION` into a target project
  and scaffolds `.forge/product/*` from `.forge/templates/product/*`.
  Implements A3.0 — the source repo's own `.forge/product/` content is
  never copied. Never copies `.claude/settings.local.json` (A3).
- `Dockerfile.linter` — multi-stage Alpine image bundling `verify.sh` and
  `constitution-linter.sh` for CI (`forge/linter:latest`). Satisfies
  Article VIII.3 (multi-stage with minimal runtime). Entry point
  `bin/forge-lint` aggregates both scripts' exit codes (A5).
- `bin/forge-lint` — thin wrapper that runs both deterministic scripts and
  aggregates their exit codes. Usable locally and from the Docker image.
- `.forge/templates/product/tech-stack.md` — missing template added so the
  installer can scaffold all three product artifacts (gap revealed by the
  A3 smoke test).
- `cli/` — TypeScript CLI package `@sdd-forge/cli` with `init`, `verify`,
  and `version` commands. Node ≥ 20, strict TypeScript, commander parser,
  24 Vitest tests (domain + integration + e2e). Built via
  `npm run build`; binary installed as `forge` (A4).

### Changed

- `README.md` — quickstart replaced the single `cp -r forge/` recipe with
  three install channels (shell, npm, Docker). License footer updated to
  Apache-2.0 (was still claiming proprietary). Added governance links.

### Fixed

- Installer smoke-test revealed that `.forge/templates/product/` was
  missing `tech-stack.md` despite `.forge/product/tech-stack.md` existing
  in the source. The template is now in place so scaffolded projects get
  all three product documents.

## [0.1.0-t0] — 2026-04-18

T0 milestone: Forge moves from a private reference implementation to an
openly-licensed framework and begins dog-fooding itself.

### Added

- `LICENSE` — Apache License 2.0, replacing the prior "all rights reserved"
  proprietary text.
- `NOTICE` — attribution to upstream sources (BMAD Method, GitHub SpecKit,
  OpenSpec, Agent OS v3, Superpowers, oh-my-claudecode, Context7).
- `.forge/product/mission.md` — real mission, replacing the empty
  HTML-comment template.
- `.forge/product/roadmap.md` — public roadmap aligned with the T0–T4+
  modules of the audit.
- `.forge/templates/product/{mission,roadmap}.md` — the original empty
  templates, preserved so `/forge:init` and the installer can scaffold a
  fresh product file for each target project without leaking Forge's own
  product content (A3.0).

### Changed

- `.claude/settings.json` — removed the project-level
  `defaultMode: plan` override (it was a user preference, not a framework
  rule). Fulfils audit item F7.

## [0.0.0] — 2026-04-09

Initial framework drop. Constitution v1.0.0 ratified, 19 commands, 28
agents, 39 standards, 5 schemas, 4 templates, 3 skills, 2 deterministic
scripts. Private license at the time.

[Unreleased]: https://github.com/b-fontaine/forge/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/b-fontaine/forge/compare/v0.1.0-t0...v0.2.0
[0.1.0-t0]: https://github.com/b-fontaine/forge/releases/tag/v0.1.0-t0
[0.0.0]: https://github.com/b-fontaine/forge/releases/tag/v0.0.0
