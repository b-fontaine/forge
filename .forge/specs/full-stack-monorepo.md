# Spec: full-stack-monorepo

<!-- Audit: Module B.1 — flagship archetype of the Forge Framework.            -->
<!-- This file accumulates archived requirements for the archetype.            -->
<!-- Each entry is traced back to its originating change in .forge/changes/.   -->

This spec is the consolidated contract for Forge projects adopting the
`full-stack-monorepo` archetype (Flutter frontend + Rust backend + Infra,
with protos as single source of truth). It is populated incrementally as
changes land. Order of sections reflects the FR-ID, not chronology.

---

## Archived changes

| Change | Date | Phase | FRs added |
|---|---|---|---|
| [`b1-foundations`](../changes/b1-foundations/) | 2026-04-21 | Foundations (contract layer) | FR-GL-001..008 + NFR-001..004 |
| [`b1-scaffolder`](../changes/b1-scaffolder/) | 2026-04-22 | Scaffolder (generator layer) | FR-GL-009..014 + FR-BE-001 + FR-FE-001 + FR-IN-001 + NFR-005..008 |
| [`b1-workflow`](../changes/b1-workflow/) | 2026-04-23 | Workflow (multi-layer orchestration) | FR-GL-015..023 + FR-BE-002 + FR-FE-002 + NFR-009..012 ; MODIFIED FR-GL-008 |

## Schema evolution

| Event | Stage | Version | Trigger |
|---|---|---|---|
| 2026-04-21 — b1-foundations archived | `draft` | `0.1.0` | Schema first declared, no consumer yet |
| 2026-04-22 — b1-scaffolder archived | `candidate` | `1.0.0-rc.1` | Scaffolder successfully consumes the schema end-to-end (21/21 test scenarios + manual smoke) — promotion rule from b1-foundations ADR-004 |
| 2026-04-23 — b1-workflow archived | `candidate` | `1.0.0-rc.1` | No schema shape change ; multi-layer orchestration layered on top (Janus agent + per-change `layers:` metadata + multi-root scripts). Promotion to `stable / 1.0.0` deferred to `b1-delivery`. |

---

## Requirements

### FR-GL-001: Schema `full-stack-monorepo` declares the monorepo contract

<!-- From change: b1-foundations (2026-04-21) -->

- **MUST** — a file `.forge/schemas/full-stack-monorepo/schema.yaml` exists
  and parses as valid YAML (via `yaml.safe_load`).
- **MUST** — the schema contains top-level keys `name`, `version`,
  `description`, `tdd_enforced`, `bdd_required_for_user_facing`,
  `coverage_threshold`, `phases`, `layers`, `stage`.
- **MUST** — `name` is exactly `full-stack-monorepo`.
- **MUST** — `version` matches SemVer `^\d+\.\d+\.\d+(-[\w.-]+)?$`.
- **MUST** — `layers` is a non-empty list containing at least `backend`,
  `frontend`, `infra` by `id`, each object with `id`, `path`,
  `fr_id_prefix`, `primary_agent`, `standards_scope`.
- **MUST** — `stage` is one of `draft` | `candidate` | `stable`. If
  `stage == stable`, `version` is at least `1.0.0` without prerelease.
- **MUST** — `phases` extends the phases of `default/schema.yaml`
  (proposal, specs, design, tasks, implementation, review, archive).
- **MUST** — `cross_layer.agent` references `Janus` (the agent itself is
  delivered by `b1-workflow`).

**Constitution reference:** Article III.2 (specs-as-code), Article VI
(Flutter architecture), Article VII (Rust architecture), Article VIII
(infra). **Testable:** yes — enforced by
`.forge/scripts/validate-foundations.sh` `check_schema_full_stack_monorepo`.

### FR-GL-002: Standard `global/monorepo-layout.md` engraves the canonical tree

<!-- From change: b1-foundations (2026-04-21) -->

- **MUST** — file `.forge/standards/global/monorepo-layout.md` exists and
  contains four H2 sections: `## Arborescence`, `## Interdictions`,
  `## CLAUDE.md imbriqués`, `## Préfixes FR-ID`.
- **MUST** — the standard forbids cross-imports `frontend/` ↔ `backend/`
  outside generated protos in `shared/protos/`.
- **MUST** — FR-ID prefixes per layer are defined: `FR-BE-` (backend),
  `FR-FE-` (frontend), `FR-IN-` (infra), `FR-GL-` (global / cross-layer).
- **SHALL** — the standard cites Articles VI.2 (Clean Architecture Flutter)
  and VII.3 (Hexagonal Rust) as applicable in their respective subtrees.

**Constitution reference:** Articles VI, VII, VIII. **Testable:** yes —
`check_standard_monorepo_layout` greps for the four H2 headings.

### FR-GL-003: Standard `global/proto-contracts.md` formalizes protos as single source of truth

<!-- From change: b1-foundations (2026-04-21) -->

- **MUST** — file `.forge/standards/global/proto-contracts.md` exists and
  contains five H2 sections: `## Arborescence shared/protos`,
  `## Versioning (v1, v2, deprecation)`, `## Gates CI (buf lint + buf breaking)`,
  `## Génération des stubs (tonic-build, protoc_plugin)`, `## Interdictions`.
- **MUST** — the standard imposes `buf lint` and `buf breaking` as blocking
  gates in CI before any merge touching `shared/protos/`.
- **MUST** — the standard defines the proto versioning strategy: namespaced
  directories `v1/`, `v2/`; new namespace required for every breaking
  change; minimum two-version deprecation window.
- **MUST** — the standard documents stub generation: `tonic-build` for Rust,
  `protoc_plugin` for Dart.
- **SHALL** — the standard forbids manual edits to generated stubs.

**Constitution reference:** Article IV (delta specs), Article IX.4 (contracts
as security surface). **Testable:** yes — `check_standard_proto_contracts`.

### FR-GL-004: Standard `infra/docker-compose.md` scopes local orchestration

<!-- From change: b1-foundations (2026-04-21) -->

- **MUST** — file `.forge/standards/infra/docker-compose.md` exists and
  contains five H2 sections: `## Service naming (fsm-*)`,
  `## Réseau unique (fsm-dev)`, `## Healthchecks obligatoires`,
  `## Variables d'env (.env.example versionné)`,
  `## Interdiction docker-compose.yml non suffixé`.
- **MUST** — all services are prefixed `fsm-`; three canonical services
  MUST exist: `fsm-backend`, `fsm-kong`, `fsm-db`.
- **MUST** — a named network `fsm-dev` is attached to every service; no
  default `bridge` network.
- **MUST** — every service declares a healthcheck; `depends_on` uses
  `condition: service_healthy`.
- **MUST** — `.env.example` is committed; `.env` is gitignored.
- **MUST** — a bare `docker-compose.yml` at the repo root is forbidden
  (explicit suffix required: `docker-compose.dev.yml`,
  `docker-compose.e2e.yml`, etc.).

**Constitution reference:** Article VIII. **Testable:** yes —
`check_standard_docker_compose`.

### FR-GL-005: `global/git-workflow.md` declares scoped Conventional Commits (monorepo-only)

<!-- From change: b1-foundations (2026-04-21) -->

- **MUST** — standard `.forge/standards/global/git-workflow.md` contains
  a section titled exactly `## Scoped Conventional Commits (monorepo-only)`.
- **MUST** — the section declares a closed list of scopes:
  `{backend, frontend, infra, protos, forge, docs, ci}`. Any scope outside
  this list MUST be rejected by the pre-commit hook (hook delivered in
  `b1-delivery`).
- **MUST** — the closed list rule activates only when the project's root
  `.forge.yaml` declares `schema: full-stack-monorepo`. Other schemas
  continue to use free-form scopes.
- **SHALL** — the standard provides at least three examples per scope
  (canonical + anti-pattern).

**Constitution reference:** Article X (quality), Article X.4 (git hygiene).
**Testable:** yes — `check_git_workflow_scoped_commits`.

### FR-GL-006: `docs/VERSIONING.md` documents monorepo versioning models

<!-- From change: b1-foundations (2026-04-21) -->

- **MUST** — document `docs/VERSIONING.md` contains a section titled
  `## Monorepo Versioning Models`, placed between `## Release Artifacts`
  and `## Who Bumps the Version`.
- **MUST** — the section documents two models via the subsections
  `### Release-train` and `### Per-package via release-please`.
- **MUST** — the section states the Forge default (release-train for
  ≤ 15 contributors) and the criteria for switching to per-package.
- **SHALL** — a decision matrix is provided (team size, cadence, coupling,
  compliance, etc.).

**Constitution reference:** Article A6 (SemVer), Article X (quality).
**Testable:** yes — `check_versioning_monorepo_section`.

### FR-GL-007: `.forge/standards/index.yml` references the three new standards

<!-- From change: b1-foundations (2026-04-21) -->

- **MUST** — the standards index contains three new entries, each with
  `id`, `path`, `scope`, `priority`, `triggers`:
    - `global/monorepo-layout` — `scope: monorepo`, `priority: high`.
    - `global/proto-contracts` — `scope: protos`, `priority: high`.
    - `infra/docker-compose` — `scope: infra`, `priority: medium`.
- **SHALL** — the delta is strictly additive; no pre-existing entry is
  modified.

**Constitution reference:** Article V (JIT standards loading via index).
**Testable:** yes — `check_index_new_entries`.

### FR-GL-008: Deterministic validator enforces the foundations contract

<!-- From change: b1-foundations (2026-04-21) -->
<!-- MODIFIED by change: b1-workflow (2026-04-22) — validator now also exposes
     `check_multi_layer_change_metadata` (FR-GL-017) and
     `check_standard_multi_layer_workflow` (FR-GL-018 validator side) alongside
     the original FR-GL-001..007 checks. Conditional dispatch unchanged. -->

- **MUST** — a script `.forge/scripts/validate-foundations.sh` implements
  the structural checks for FR-GL-001..007. Each check emits
  `PASS: FR-GL-XXX — <message>` or `FAIL: FR-GL-XXX — <message>` on stdout.
- **MUST** — the script exits 0 iff every check passes; exits 1 if any
  check fails.
- **MUST** — the script is idempotent (NFR-001): running twice on the same
  FORGE_ROOT produces byte-identical output and the same exit code.
- **SHALL** — the wall-clock duration is < 2 seconds on a standard dev
  machine (NFR-002).
- **SHALL** — the script is invoked conditionally from
  `.forge/scripts/verify.sh` when `.forge/schemas/full-stack-monorepo/`
  exists. Non-monorepo projects see an explicit
  `(validate-foundations skipped — not a monorepo)` message.
- **SHALL** — the test harness `.forge/scripts/tests/foundations.test.sh`
  exercises each check via fixtures (absent file / malformed content /
  complete content) and the whole validator end-to-end (RED state →
  GREEN state meta-tests).

**Constitution reference:** Article I (TDD), Article V (deterministic
gates). **Testable:** yes — self-tested via
`.forge/scripts/tests/foundations.test.sh` (21 scenarios covering all FRs).

---

### FR-GL-009: Archetype template tree under `.forge/templates/archetypes/full-stack-monorepo/`

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — the directory
  `.forge/templates/archetypes/full-stack-monorepo/` holds the complete
  static template set for the archetype : root files (CLAUDE.md,
  Taskfile.yml, docker-compose.dev.yml, .env.example, .gitignore,
  .forge.yaml, README.md), nested `CLAUDE.md` per layer, backend
  workspace manifest + toolchain, proto seed (`buf.yaml`, `buf.gen.yaml`,
  `v1/example/example.proto`), infra stubs (`kong.yml.example`,
  `Dockerfile.backend.example`), and `.gitkeep` markers for layer
  sub-directories. Minimum 20 entries (AC-007).
- **MUST** — every `.tmpl` file carries `<!-- Audit: B.1.X -->` or
  equivalent (NFR-004).
- **MUST** — templates use only three placeholders : `<project-name>`,
  `<reverse-domain>`, `<root-module>`. Single-pass literal replacement
  at scaffold time, no DSL.

**Constitution reference:** Articles VI, VII, VIII, X. **Testable:** yes
— L1 `test_plan_templates_sources_exist` + `test_plan_templates_count_minimum`.

### FR-GL-010: Machine-readable scaffold plan (`scaffold-plan.yaml`)

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — `.forge/templates/archetypes/full-stack-monorepo/scaffold-plan.yaml`
  declares every template with `source`, `target`, `substitute` per entry
  ; the official scaffolder invocations in `official_scaffolders[]` with
  `cmd` and optional `required`; and post-scaffold actions in
  `post_steps[]` (minimum : `write_scaffold_manifest`, `run_validate_foundations`).
- **MUST** — plan version is SemVer, initially `"0.1.0"`, aligned with
  the archetype schema stage governance (ADR-004).
- **SHALL** — the plan is parseable by `yaml.safe_load`.

**Constitution reference:** Article V (deterministic gates), III.2.
**Testable:** yes — L1 7-test suite covers schema, key presence, version
regex, source existence, official_scaffolders shape, minimum count.

### FR-GL-011: `/forge:init --archetype full-stack-monorepo` slash command branch

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — the slash command delegates to
  `.forge/scripts/scaffolder/init.sh` which executes a non-negotiable
  7-step sequence : (1) validate positional `<project-name>` and `--org`
  arguments via regex ; (2) validate external tools on PATH (flutter
  ≥ 3.24, cargo ≥ 1.80, buf ≥ 1.30) ; (3) copy framework assets
  (`.forge/`, `.claude/`, `.mcp.json`, `docs/`) from source, stripping
  runtime state ; (4) `flutter create frontend` ; (5) invoke `overlay.sh`
  to render archetype templates (writes `scaffold-manifest.yaml` with
  tool versions) ; (6) `cargo new` for each of the 5 crates
  (auto-joining the pre-written workspace Cargo.toml) ; (7) run
  `validate-foundations.sh` on the scaffolded target, abort exit 7 on
  FAIL (target preserved for inspection).
- **MUST** — `--force` allows overwriting overlay paths ; NEVER touches
  flutter-create or cargo-new output.
- **SHALL** — `--dry-run` prints the sequence without executing.

**Constitution reference:** Articles I, III, V, VI, VII, VIII, X.
**Testable:** yes — L3 `test_e2e_happy_path`, `test_e2e_missing_flutter_aborts`.

### FR-BE-001: Backend Cargo workspace with 5 hexagonal crates

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — `backend/Cargo.toml` is a workspace manifest with
  `resolver = "2"` and `members = ["crates/domain", "crates/application",
  "crates/grpc-api", "crates/infrastructure", "bin-server"]` in that
  order. Written BEFORE `cargo new` runs, so each crate auto-joins
  (design ADR-002).
- **MUST** — `backend/rust-toolchain.toml` pins `channel = "stable"`
  with `rustfmt` + `clippy` components; no patch pin.
- **MUST** — `backend/CLAUDE.md` declares Rust scope: loads only
  `rust/*` + `global/*` standards, excludes `flutter/*` and `infra/*`;
  primary agent Vulcan; cross-ref to Article VII.3.

**Constitution reference:** Article VII.3 (Hexagonal Rust).
**Testable:** yes — L3 happy path asserts 5-crate workspace + each
crate's `Cargo.toml`.

### FR-FE-001: Frontend produced exclusively by `flutter create`

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — the scaffolder invokes `flutter create frontend --org
  <reverse-domain> --platforms android,ios,web --project-name
  <project_name_snake>_frontend` exactly once.
- **MUST** — the Forge overlay under `frontend/` adds only
  `CLAUDE.md` and 4 `.gitkeep` markers (`lib/core`, `lib/shared`,
  `lib/features`, `lib/generated/protos`). NO modification to any file
  produced by `flutter create`.
- **MUST** — `frontend/CLAUDE.md` scopes Flutter standards only
  (14 entries from index.yml), explicitly excludes `rust/*`, `infra/*`,
  and `global/proto-contracts`. Primary agent Hera.

**Constitution reference:** Article VI.2, audit rule B.5.6 (scaffolder
officiel d'abord). **Testable:** yes — L3 happy path +
`test_e2e_idempotence_with_force`.

### FR-IN-001: Infra stubs are `.example`-suffixed placeholders

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — `infra/kong/kong.yml.example` and
  `infra/docker/Dockerfile.backend.example` ship with `.example` suffix.
  Adopters rename on consumption.
- **MUST** — `infra/k8s/base/` and `infra/k8s/overlays/` are empty
  directories with `.gitkeep` only.
- **MUST** — `Dockerfile.backend.example` is multi-stage with a
  distroless final stage (Article VIII.3).
- **MUST** — `infra/CLAUDE.md` scopes infra standards only, primary
  agent Atlas.

**Constitution reference:** Article VIII, Article VIII.3.
**Testable:** yes — content verified by L3 happy path file-existence
assertions.

### FR-GL-012: Canonical `Taskfile.yml` targets

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — the scaffolded `Taskfile.yml` exposes the canonical
  targets `dev`, `test`, `lint`, `proto`, `release` plus per-layer
  aliases `test:backend`/`test:frontend`/`test:infra`,
  `lint:backend`/`lint:frontend`/`lint:infra`/`lint:proto`,
  `dev:up`/`dev:down`.
- **MUST** — `task dev` invokes
  `docker-compose -f docker-compose.dev.yml up -d` (never a bare
  `docker-compose up`, per FR-GL-004).
- **MUST** — `task proto` regenerates Rust (`tonic-build`) + Dart
  (`protoc_plugin`) stubs in a single command.

**Constitution reference:** Article X (quality, reproducibility).
**Testable:** yes — L3 happy path asserts Taskfile exists; content
pattern covered by L2 substitution tests.

### FR-GL-013: Proto skeleton passes `buf lint` out of the box

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — `shared/protos/buf.yaml` is v2 config, `lint.use:
  [STANDARD]`, `breaking.use: [FILE]`, `service_suffix: Service`,
  `enum_zero_value_suffix: _UNSPECIFIED`. `PACKAGE_DIRECTORY_MATCH` is
  excluded with documented justification (proto-contracts.md standard
  reconciliation carry-over).
- **MUST** — `shared/protos/buf.gen.yaml` declares 3 plugins :
  `neoeinstein-tonic`, `neoeinstein-prost` (both Rust, output to
  `../../backend/crates/grpc-api/src/generated`), and
  `protocolbuffers/dart` (output to `../../frontend/lib/generated/protos`).
- **MUST** — `shared/protos/v1/example/example.proto` declares
  `package example.v1`, `service ExampleService`, RPC
  `Ping(PingRequest) returns (PingResponse)`, with one-field
  PingRequest / PingResponse messages.
- **SHALL** — the proto file compiles under `buf lint` with zero
  warnings.

**Constitution reference:** Article IV, Article IX.4. **Testable:** yes
— L3 `test_e2e_buf_lint_passes`.

### FR-GL-014: Integration test harness for the scaffolder

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — `.forge/scripts/tests/scaffolder.test.sh` exercises the
  scaffolder at three levels :
  * **L1** — plan shape (YAML parse, required keys, source existence,
    count ≥ 20). 7 scenarios. Zero external deps.
  * **L2** — overlay rendering (substitution, `--force` semantics,
    idempotence via `SOURCE_DATE_EPOCH`, manifest write, regex
    validation of `<project-name>` and `<reverse-domain>`). 7 scenarios.
    Zero external deps.
  * **L3** — end-to-end happy path + missing-tool abort + `buf lint` +
    contract-drift detection + performance budget + idempotence.
    7 scenarios. Requires flutter + cargo + buf on PATH (auto-skipped
    otherwise unless `--require-external-tools` is passed).
- **MUST** — the harness shares helpers with `foundations.test.sh` via
  `.forge/scripts/tests/_helpers.sh` (no duplicated assertion code).
- **MUST** — `verify.sh` invokes the harness at `--level 2` (hermetic)
  on every run; L3 is CI-opt-in only.

**Constitution reference:** Article I (TDD), Article V (gates).
**Testable:** self-testing — 21/21 scenarios PASS on the full suite.

### FR-GL-015: Janus agent — cross-layer orchestrator

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — a file `.claude/agents/cross-layer-orchestrator.md` exists and declares the
  Janus agent with the standard Forge persona pattern (Roman mythological
  name, role, style, 12-step workflow, quality gates).
- **MUST** — Janus is classified as an **orchestrator** : it NEVER writes
  application code. Its role is to dispatch per-layer specialists (Hera
  for `frontend/`, Vulcan for `backend/`, Atlas for `infra/`, Hermes-API
  for `shared/protos/`), aggregate their outputs, and enforce cross-layer
  contract alignment.
- **MUST** — Janus is invoked by `/forge:design`, `/forge:implement`,
  `/forge:review` when the change's `.forge.yaml` declares `layers:` with
  ≥ 2 entries.
- **MUST** — Janus's workflow emits `[NEEDS CLARIFICATION: ...]` markers
  (Article V.3) when per-layer deliverables disagree ; it NEVER silently
  resolves a conflict.
- **SHALL** — Janus's routing table references the sub-specialists by name
  (Hera / Vulcan / Atlas / Hermes-API / Nemesis / Tribune / Aegis) with a
  one-line rationale per invocation rule.

**Constitution reference:** Article V (gates), Articles VI.2, VII.3, VIII.
**Testable:** yes — `test_janus_agent_file_has_required_sections` in
`workflow.test.sh`.

### FR-GL-016: `.forge.yaml` per-change gains optional multi-layer fields

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — the `.forge/templates/change.yaml` template exposes three new
  optional top-level fields : `layers:` (list of layer ids, subset of
  `backend`/`frontend`/`infra`), `designs_per_layer:` (map of `layer-id →
  filename`), `tasks_per_layer:` (map of `layer-id → filename`).
- **MUST** — `designs_per_layer:` and `tasks_per_layer:` are required only
  when `layers:` has ≥ 2 entries. With exactly 1 layer, the existing
  `design.md` / `tasks.md` convention applies (backwards compatible). When
  `layers:` is absent, the change is treated as single-layer.
- **SHOULD** — the template carries an inline comment block documenting
  the schema + the one-sentence rule "≥ 2 layers triggers Janus
  orchestration and per-layer deliverables".

**Constitution reference:** Article III.2, Article IV. **Testable:** yes —
`test_change_yaml_template_has_optional_layers_fields`.

### FR-GL-017: Validator check for multi-layer change metadata

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — `.forge/scripts/validate-foundations.sh` exposes a new check
  `check_multi_layer_change_metadata` that inspects every
  `.forge/changes/*/.forge.yaml`.
- **MUST** — when `layers:` has ≥ 2 entries, the check REQUIRES
  `designs_per_layer:` and `tasks_per_layer:` present and non-empty, every
  referenced file exists in the change directory, and every layer id is a
  subset of the archetype schema's `layers[].id`.
- **SHALL** — single-layer and no-layer changes PASS with an explicit
  rationale line. Non-monorepo projects see the check SKIPPED (not N/A).

**Constitution reference:** Article III, Article V. **Testable:** yes — 4
fixture tests in `workflow.test.sh` (valid single, valid multi, missing
per-layer, unknown layer).

### FR-GL-018: Standard `global/multi-layer-workflow.md` formalizes the routing policy

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — `.forge/standards/global/multi-layer-workflow.md` exists and
  contains these canonical H2 sections : Routing Policy, `.forge.yaml`
  Multi-Layer Schema, Per-Layer Design Convention, Per-Layer Tasks
  Convention, Cross-Layer Contract Alignment, Interdictions.
- **MUST** — cites Articles V, VI.2, VII.3, VIII, IX.4, and
  cross-references `global/monorepo-layout.md`.
- **SHALL** — includes one worked example of a hypothetical cross-layer
  change (backend + frontend) with its resulting `.forge/changes/<name>/`
  tree.

**Constitution reference:** Articles V, VI, VII, VIII, X. **Testable:**
yes — `check_standard_multi_layer_workflow` in validator +
`test_standard_multi_layer_workflow_sections` in harness.

### FR-GL-019: Index references `global/multi-layer-workflow.md`

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — `.forge/standards/index.yml` contains one new entry with
  `id: global/multi-layer-workflow`, `scope: monorepo`, `priority: high`,
  triggers including `multi-layer`, `janus`, `cross-layer`, `layers:`,
  `layers count`.
- **SHALL** — purely additive ; no pre-existing entry is modified.

**Constitution reference:** Article V (JIT loading). **Testable:** yes —
`test_index_has_multi_layer_workflow_entry`.

### FR-GL-020: Per-layer design and tasks templates

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — two new templates under `.forge/templates/` :
  `design-per-layer.md` (same sections as `design.md` scoped to ONE layer,
  header `<!-- Layer: <layer-id> -->`) and `tasks-per-layer.md` (phase
  numbering uses a layer-prefix convention like "Backend Phase 1").
- **MUST** — both templates carry `<!-- Audit: B.1.6 -->` header.
- **SHOULD** — both include a leading `## Cross-Layer References` section
  for FR-GL-* traceability.

**Constitution reference:** Article III.2, Article X.3. **Testable:** yes
— section-presence checks in harness.

### FR-BE-002: Layer-scoped Rust checks in `verify.sh`

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — `verify.sh` detects the `full-stack-monorepo` schema at the
  target's `.forge.yaml` and, when matched, runs a Backend section scoped
  to `<FORGE_ROOT>/$backend_path/` : `cargo clippy --all-features -- -D
  warnings`, `cargo fmt --check`, `cargo test --all-features`, domain-
  purity check (no `sqlx`/`reqwest`/`hyper`/`tonic` in `crates/domain/`),
  no `unwrap()`/`panic!()` in production code.
- **MUST** — emitted lines prefixed `[backend] ...`.
- **MUST** — SKIPPED when `backend/` absent OR schema mismatch.

**Constitution reference:** Article VII.3. **Testable:** yes — L3 fixture
`test_verify_backend_scoped_emits_prefixed_lines`.

### FR-FE-002: Layer-scoped Flutter checks in `verify.sh`

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — same shape as FR-BE-002 but for the Flutter layer : `flutter
  analyze --fatal-infos`, `dart format --set-exit-if-changed`, `flutter
  test --coverage`, coverage 80 % threshold, layer-boundary check (no
  `package:flutter` under `frontend/lib/features/*/domain/`).
- **MUST** — lines prefixed `[frontend] ...` ; SKIPPED when absent.

**Constitution reference:** Article VI.2. **Testable:** yes — L3 fixture
`test_verify_frontend_scoped_emits_prefixed_lines`.

### FR-GL-021: Layer-scoped protos + infra checks in `verify.sh`

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — Protos section (prefix `[protos]`) runs `buf lint` + `buf
  breaking --against '.git#branch=main'` when `shared/protos/` exists.
- **MUST** — Infra section (prefix `[infra]`) validates
  `docker-compose.dev.yml` via `docker compose ... config`, parses every
  `infra/kong/*.yml` and `infra/k8s/**/kustomization.yaml` with
  `yaml.safe_load`.
- **MUST** — both sections SKIP gracefully (WARN, not FAIL) when subtree
  or tool absent.

**Constitution reference:** Articles IV, VIII, IX.4. **Testable:** yes —
L3 `test_verify_protos_scoped_buf_lint` + `test_verify_infra_scoped_compose_syntax`.

### FR-GL-022: Layer-scoped `constitution-linter.sh` activation

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — `constitution-linter.sh` detects the `full-stack-monorepo`
  schema at the target root and, when matched, scopes Article VI checks
  to `$frontend_path/` and Article VII checks to `$backend_path/`.
- **MUST** — when schema is other, the existing single-root behavior is
  preserved byte-for-byte (NFR-010).
- **SHALL** — emits `[scoped: frontend]` / `[scoped: backend]` header
  suffixes when scoping is active.

**Constitution reference:** Articles VI, VII. **Testable:** yes — L3
fixture + NFR-010 regression scenario.

### FR-GL-023: Workflow test harness (`workflow.test.sh`)

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — `.forge/scripts/tests/workflow.test.sh` exercises L1
  (structural invariants : Janus file, standard, templates, change.yaml
  extension), L2 (fixture-based validator for FR-GL-017 + FR-GL-018 +
  FR-GL-019), and L3 (multi-root `verify.sh` fixtures for FR-BE-002, FR-
  FE-002, FR-GL-021 + NFR-010 regression).
- **MUST** — uses `.forge/scripts/tests/_helpers.sh` for shared helpers.
- **MUST** — invoked by `verify.sh` Section 7 at `--level 2` (hermetic).
- **MUST** — L3 auto-skips when `flutter`/`cargo`/`buf` are absent unless
  `--require-external-tools` is set.

**Constitution reference:** Article I (TDD), Article V. **Testable:**
self-testing — 16/16 scenarios PASS on the full suite at archive time.

---

## Non-Functional Requirements

### NFR-001: Validator idempotence

<!-- From change: b1-foundations (2026-04-21) -->

Running `validate-foundations.sh` twice on the same `FORGE_ROOT` MUST
produce byte-identical stdout and the same exit code. Exercised by
`test_idempotence()` in the foundations harness.

### NFR-002: Validator performance

<!-- From change: b1-foundations (2026-04-21) -->

The wall-clock execution of `validate-foundations.sh` on a fully-populated
Forge repository SHALL complete in less than **2000 ms** on a standard dev
machine. Measured by `test_performance_under_two_seconds()`; hard ceiling
at 5000 ms. Baseline at archive time: **364 ms** (18 % of budget).

### NFR-003: Documentation quality

<!-- From change: b1-foundations (2026-04-21) -->

All Markdown deliverables MUST pass `pymarkdown` lint with the Forge
default ruleset (MD013 line-length disabled for prose, MD024 duplicate
headings allowed for delta-spec pattern). Line length SHALL remain under
100 columns in standards prose.

### NFR-004: Audit-ID traceability

<!-- From change: b1-foundations (2026-04-21) -->

Every file created or modified by a change MUST carry an
`<!-- Audit: B.X.Y (part of <change-name>) -->` HTML comment in its first
five lines, or the YAML/Shell equivalent. Enables mechanical tracing of
every artifact back to its audit module.

### NFR-005: Scaffolder idempotence under `--force`

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — running the overlay twice on the same target with `--force`
  and a pinned `SOURCE_DATE_EPOCH` produces a byte-identical tree for
  every overlay-owned file (files generated by `flutter create` /
  `cargo new` are NOT in the plan and are not re-touched). Exercised by
  L3 `test_e2e_idempotence_with_force`.

### NFR-006: Scaffolder performance

<!-- From change: b1-scaffolder (2026-04-22) -->

- **SHALL** — the full scaffold sequence completes in less than
  **30 seconds** on a warm machine (SDK cached, tmpdir fresh). Hard
  ceiling : 60 seconds. Baseline at archive time : **~3 seconds** on
  macOS 14.5 / Flutter 3.41.7 / Cargo 1.91.0 / Buf 1.68.3.

### NFR-007: Integration test reproducibility

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — `scaffolder.test.sh` uses `mk_tmpdir_with_trap` for every
  fixture (14 invocations, 14 traps), and cleans up on exit regardless
  of test outcome. Never touches the real repo. L1 + L2 are hermetic ;
  L3 auto-detects external tools and gracefully skips when absent
  (unless `--require-external-tools` is passed).

### NFR-008: External tool version policy

<!-- From change: b1-scaffolder (2026-04-22) -->

- **MUST** — the scaffolder checks `flutter --version`, `cargo --version`,
  `buf --version` against minimums (3.24 / 1.80 / 1.30) via
  `version_ge()` awk helper, and records actual versions in the
  scaffolded project's `.forge/scaffold-manifest.yaml`. Manifest also
  records `archetype`, `archetype_version`, `scaffold_plan_sha`,
  `template_set_sha`, `scaffold_date`, `project_name`, `reverse_domain`,
  `root_module` — the complete audit trail for `forge upgrade`
  (delivered by `b1-delivery`).

### NFR-009: Multi-root verify.sh performance

<!-- From change: b1-workflow (2026-04-23) -->

- **SHALL** — on a scaffolded project with no real domain code,
  `verify.sh` completes in less than **30 seconds** on a standard dev
  machine (warm caches). Hard ceiling : 60 seconds. The archetype's own
  invocations must remain fast on an empty scaffold.

### NFR-010: Backwards compatibility of single-root scripts

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — when a target's `.forge.yaml` declares a schema OTHER than
  `full-stack-monorepo`, `verify.sh` + `constitution-linter.sh` produce
  byte-identical stdout + same exit code as the pre-b1-workflow scripts.
  Exercised by `test_verify_non_monorepo_no_scoped_output` in
  `workflow.test.sh` L3.

### NFR-011: Janus agent pattern consistency

<!-- From change: b1-workflow (2026-04-23) -->

- **SHALL** — the Janus agent file follows the same Markdown structure as
  `forge-master.md`, `flutter/orchestrator.md`, and `rust/orchestrator.md`
  (identical section headings, 12-step convention, quality-gate invocation
  pattern). Enforced by the L1 structural check in `workflow.test.sh`.

### NFR-012: Multi-layer metadata documentation

<!-- From change: b1-workflow (2026-04-23) -->

- **MUST** — `global/multi-layer-workflow.md` documents every optional
  field of the new `.forge.yaml` extension with a realistic example and a
  one-sentence purpose.

---

## Scope

**In scope for the archetype `full-stack-monorepo` (delivered so far):**

- The canonical contract, schema (at `candidate` stage, `1.0.0-rc.1`),
  and standards declared by FR-GL-001..007 — **b1-foundations**.
- The deterministic validator (FR-GL-008) — **b1-foundations**.
- The scaffolder `/forge:init --archetype full-stack-monorepo` with
  its archetype template tree, machine-readable plan, 3-level test
  harness, and reproducible-build manifest
  (FR-GL-009..014 + FR-BE-001 + FR-FE-001 + FR-IN-001) —
  **b1-scaffolder**.

**Deferred to future changes (explicitly out of scope here):**
- Multi-layer change workflow + agent `Janus` + multi-root `verify.sh` /
  `constitution-linter.sh` — `b1-workflow`.
- GitHub Actions reference workflow + `forge upgrade` + env matrix —
  `b1-delivery`.
- Reference project (`C.1`) and migration paths — later.
