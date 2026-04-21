# Spec: b1-scaffolder
<!-- Delta format: ADDED, MODIFIED, REMOVED sections only -->
<!-- Audit: B.1.2 + B.1.3 + B.1.4 + B.1.13 -->
<!-- Depends on spec: full-stack-monorepo.md (FR-GL-001..008 + NFR-001..004) -->

## ADDED Requirements

### FR-GL-009: Archetype template tree at `.forge/templates/archetypes/full-stack-monorepo/`

- **MUST** — the directory
  `.forge/templates/archetypes/full-stack-monorepo/` exists and holds the
  complete static template set for the archetype.
- **MUST** — every template file carries the `<!-- Audit: B.1.X -->`
  header (or YAML / Shell equivalent) per NFR-004.
- **MUST** — template files use the placeholders `<project-name>`,
  `<reverse-domain>`, `<root-module>` and no others. Substitution is a
  single-pass literal replacement at scaffold time, no Jinja / Mustache
  DSL.
- **MUST** — the template set includes at minimum :
    - Root : `CLAUDE.md.tmpl`, `Taskfile.yml.tmpl`,
      `docker-compose.dev.yml.tmpl`, `.env.example.tmpl`,
      `.gitignore.tmpl`, `.forge.yaml.tmpl`, `README.md.tmpl`.
    - Nested : `frontend/CLAUDE.md.tmpl`, `backend/CLAUDE.md.tmpl`,
      `infra/CLAUDE.md.tmpl`.
    - Protos : `shared/protos/buf.yaml.tmpl`,
      `shared/protos/buf.gen.yaml.tmpl`,
      `shared/protos/v1/example/example.proto.tmpl`.
    - Backend workspace : `backend/Cargo.toml.tmpl`,
      `backend/rust-toolchain.toml.tmpl`.
    - Infra stubs : `infra/kong/kong.yml.example.tmpl`,
      `infra/docker/Dockerfile.backend.example.tmpl`,
      `infra/k8s/base/.gitkeep`, `infra/k8s/overlays/.gitkeep`.
    - `.github/workflows/.gitkeep` (CI comes with `b1-delivery`).

**Constitution reference:** Articles VI, VII, VIII, X.

**Testable:** yes — integration test lists the files the scaffolder
produced and asserts every expected template has its counterpart in the
scaffolded project.

---

### FR-GL-010: Machine-readable scaffold plan

- **MUST** — a file
  `.forge/templates/archetypes/full-stack-monorepo/scaffold-plan.yaml`
  declares every template file, its target path in a scaffolded project,
  and its substitution keys. The slash command reads this plan as its
  single source of truth for "what gets generated".
- **MUST** — the plan schema has top-level keys `archetype`,
  `version`, `official_scaffolders`, `templates`, `post_steps`.
  `official_scaffolders` is an ordered list of shell invocations
  (`flutter create`, `cargo new`) that the slash command runs BEFORE
  overlay ; each entry has `cmd` and optional `required: true`.
  `templates` is a list, each entry with `source` (repo-relative path),
  `target` (scaffolded-project-relative path), and optional
  `substitute: true`. `post_steps` lists non-negotiable final actions
  (e.g. run `validate-foundations.sh` on the target).
- **MUST** — the plan version is `"0.1.0"` initially, aligned with the
  archetype schema stage `draft`. Bumps follow the same
  `stage: draft → candidate → stable` policy from FR-GL-001.
- **SHALL** — the plan is parseable by `yaml.safe_load` (consistent
  with ADR-002 of `b1-foundations`).

**Constitution reference:** Article V (deterministic gates), Article III.2
(specs-as-code).

**Testable:** yes — validator extension (deferred to Phase 3 of this
change) parses the plan and asserts schema conformance.

---

### FR-GL-011: `/forge:init --archetype full-stack-monorepo` slash command branch

- **MUST** — the file `.claude/commands/forge/init.md` contains an
  explicit section documenting the `--archetype full-stack-monorepo`
  branch, with the exact sequence listed below.
- **MUST** — the sequence is : (1) validate positional argument
  `<project-name>` is provided and points to a non-existent directory
  (unless `--force` is passed) ; (2) validate external tools are
  available on PATH : `flutter` ≥ 3.24, `cargo` ≥ 1.80, `buf` ≥ 1.30 ;
  (3) `flutter create frontend --org <reverse-domain> --platforms
  android,ios,web --project-name <project_name>_frontend` ;
  (4) `cargo new --vcs none backend` then per-crate
  `cargo new --lib` invocations ; (5) overlay templates from the
  archetype plan ; (6) `buf lint` on `shared/protos/` (WARN on fail,
  not FATAL, on seed commit) ; (7) run
  `./.forge/scripts/validate-foundations.sh` against the target ;
  FATAL on any FAIL.
- **MUST** — the slash command respects Article V.3 : any error is
  surfaced as a `[NEEDS CLARIFICATION: ...]` block when ambiguous,
  and the command STOPS. No silent fallback.
- **MUST** — the slash command honors `--force` only to allow
  overwriting template files in an existing directory ; it NEVER
  overwrites files produced by `flutter create` or `cargo new` unless
  the template explicitly declares the override in its header comment
  (per B.5.6 non-negotiable rule from the audit plan).
- **SHALL** — a dry-run mode `--dry-run` prints the sequence that
  would execute without running it. Useful for reviewing the plan
  before committing to a scaffold.

**Constitution reference:** Articles I, III, V, VI, VII, VIII, X.

**Testable:** yes — integration test invokes the slash-command logic
(extracted into a shell script or reproduced inline in the test) and
asserts the target tree matches expectations.

---

### FR-BE-001: Backend workspace template matches Hexagonal Architecture

- **MUST** — the generated `backend/` is a Cargo workspace with the
  crates `domain`, `application`, `grpc-api`, `infrastructure`,
  `bin-server` ; each crate is created by `cargo new --lib` (except
  `bin-server` which is a binary).
- **MUST** — `backend/Cargo.toml` is a workspace manifest with an
  explicit `members` list enumerating the five crates.
- **MUST** — `backend/rust-toolchain.toml` pins an edition (2024 by
  default) but does NOT pin a Rust version patch, to let the adopter
  upgrade with confidence.
- **MUST** — `backend/CLAUDE.md` declares this crate lives under
  Article VII.3 (Hexagonal Rust) and cross-references
  `standards/rust/architecture.md`.
- **SHALL** — the initial `domain`, `application`, `grpc-api`,
  `infrastructure`, `bin-server` sources are empty except for a
  one-line doc comment pointing to the relevant constitutional
  article.

**Constitution reference:** Article VII.3.

**Testable:** yes — scaffolder integration test asserts each crate
directory + `Cargo.toml` `[workspace]` `members` list.

---

### FR-FE-001: Frontend is produced by `flutter create` (never hand-rolled)

- **MUST** — the scaffolder invokes `flutter create frontend --org
  <reverse-domain> --platforms android,ios,web --project-name
  <project_name>_frontend` exactly once. If `flutter` is absent, the
  scaffolder aborts before creating any file.
- **MUST** — the Forge overlay on `frontend/` adds only :
  `frontend/CLAUDE.md` (nested), `frontend/lib/core/.gitkeep`,
  `frontend/lib/shared/.gitkeep`, `frontend/lib/features/.gitkeep`,
  `frontend/lib/generated/protos/.gitkeep` (proto stubs output path).
  It does NOT edit any file produced by `flutter create`.
- **MUST** — `frontend/CLAUDE.md` scopes Flutter standards only
  (Article VI.2, `standards/flutter/architecture.md`,
  `standards/flutter/state-management.md`, `standards/flutter/testing.md`).
- **SHALL** — the overlay preserves the files `flutter create`
  produced verbatim so that a re-run of `flutter create` would be a
  no-op.

**Constitution reference:** Article VI.2, audit rule B.4.6 (renumbered
to B.5.6 in the audit plan — "official scaffolder first").

**Testable:** yes — diff after overlay shows no modification to files
generated by `flutter create`.

---

### FR-IN-001: Infra stubs are placeholders, never half-complete

- **MUST** — `infra/kong/kong.yml.example`,
  `infra/docker/Dockerfile.backend.example` ship as `.example` files —
  explicitly not live configs. The adopter MUST rename them once they
  populate the values.
- **MUST** — `infra/k8s/base/` and `infra/k8s/overlays/` are empty
  directories with `.gitkeep` only. No half-written deployment
  manifests.
- **MUST** — `infra/CLAUDE.md` scopes infra standards only
  (`standards/infra/docker.md`, `standards/infra/kubernetes.md`,
  `standards/infra/kong.md`, `standards/infra/docker-compose.md`).
- **SHALL** — the `Dockerfile.backend.example` is multi-stage with a
  distroless final stage per Article VIII.3.

**Constitution reference:** Article VIII, Article VIII.3.

**Testable:** yes — integration test asserts the `.example` suffixes
and the `.gitkeep` files.

---

### FR-GL-012: Canonical `Taskfile.yml` targets

- **MUST** — the scaffolded `Taskfile.yml` exposes these top-level
  targets (minimum set) : `dev`, `test`, `lint`, `proto`, `release`.
- **MUST** — per-layer aliases exist : `test:backend`, `test:frontend`,
  `test:infra` ; `lint:backend`, `lint:frontend`, `lint:infra`.
- **MUST** — `task dev` starts the compose stack via
  `docker-compose -f docker-compose.dev.yml up -d` ; `task dev:down`
  tears it down ; never a bare `docker-compose up` (per
  `infra/docker-compose.md` FR-GL-004).
- **MUST** — `task proto` regenerates Rust stubs (`tonic-build` via
  `cargo build -p grpc-api`) and Dart stubs (`protoc_plugin` via
  `dart run build_runner build --delete-conflicting-outputs` or the
  direct `protoc` invocation).
- **SHALL** — `task release` is a stub that prints "release-train
  workflow — see docs/VERSIONING.md" until a future change wires it to
  `release-plz` or equivalent.

**Constitution reference:** Article X (quality, reproducibility).

**Testable:** yes — integration test parses `Taskfile.yml` and asserts
the required targets.

---

### FR-GL-013: Proto skeleton passes `buf lint` out of the box

- **MUST** — `shared/protos/buf.yaml` declares a Buf module with
  `lint.use` at least `STANDARD` and `breaking.use: FILE` — consistent
  with FR-GL-003 from `b1-foundations`.
- **MUST** — `shared/protos/buf.gen.yaml` declares two plugins :
  `buf.build/community/neoeinstein-tonic` targeting
  `backend/crates/grpc-api/src/generated/` and `protoc_plugin`
  targeting `frontend/lib/generated/protos/`.
- **MUST** — `shared/protos/v1/example/example.proto` defines the
  package `example.v1`, a service `ExampleService` with a single
  `Ping(PingRequest) returns (PingResponse)` RPC, and the `PingRequest`
  / `PingResponse` messages.
- **SHALL** — the proto file compiles under `buf lint` with ZERO
  warnings.

**Constitution reference:** Article IV, Article IX.4 (contracts as
security surface).

**Testable:** yes — integration test runs `buf lint shared/protos/` on
the scaffolded project and asserts exit 0.

---

### FR-GL-014: Integration test harness for the scaffolder

- **MUST** — a file `.forge/scripts/tests/scaffolder.test.sh` exists
  and exercises the end-to-end scaffold sequence against a temporary
  directory.
- **MUST** — the test asserts every file listed in the archetype
  scaffold plan exists at its target relative path after scaffolding.
- **MUST** — the test runs `.forge/scripts/validate-foundations.sh`
  against the scaffolded project and asserts exit 0 with 7 PASS lines
  for FR-GL-001..007.
- **MUST** — the test asserts the presence of markers from the
  official scaffolders (`frontend/pubspec.yaml`,
  `backend/Cargo.toml` members list, `.metadata` from
  `flutter create`) and that these markers are byte-identical to what
  the tools produced (no Forge mutation).
- **SHALL** — the test skips (emits WARN, exit 0) if `flutter` or
  `cargo` is absent on PATH, to keep CI portable. A dedicated
  `--require-external-tools` flag makes the skip FATAL.
- **SHALL** — the test is wired into the existing
  `foundations.test.sh` runner as a new invocation, OR lives as an
  independent top-level harness (ADR in `/forge:design`).

**Constitution reference:** Article I (TDD), Article V (deterministic
gates).

**Testable:** yes, auto-testing — the script is itself tested by
verifying its behavior on (a) a tmpdir before scaffolding (must FAIL
the file-existence check), (b) a tmpdir after scaffolding (must PASS).

---

## MODIFIED Requirements

<!-- None. This change is purely additive with respect to the archived
     full-stack-monorepo.md spec. Existing FR-GL-001..008 from
     b1-foundations remain unchanged. -->

## REMOVED Requirements

<!-- None. -->

---

## Acceptance Criteria

### AC-001 — Links FR-GL-011 : happy-path scaffold succeeds

```gherkin
Given Flutter >= 3.24 and Cargo >= 1.80 and buf >= 1.30 are on PATH
And the directory /tmp/demo-app does not exist
When a developer runs `/forge:init --archetype full-stack-monorepo demo-app --org com.example`
Then the scaffolder creates /tmp/demo-app/
And /tmp/demo-app/frontend/pubspec.yaml exists (from flutter create)
And /tmp/demo-app/backend/Cargo.toml declares the 5-crate workspace
And /tmp/demo-app/shared/protos/v1/example/example.proto exists
And /tmp/demo-app/Taskfile.yml exposes task dev/test/lint/proto/release
And `bash /tmp/demo-app/.forge/scripts/validate-foundations.sh` exits 0
And every output line is `PASS: FR-GL-00[1-7] — ...`
```

### AC-002 — Links FR-GL-011 : missing external tool aborts early

```gherkin
Given Flutter is NOT on PATH
When a developer runs `/forge:init --archetype full-stack-monorepo demo-app`
Then the scaffolder aborts before creating any file
And the error message contains "flutter not found on PATH"
And /tmp/demo-app/ does not exist
```

### AC-003 — Links FR-FE-001 : flutter create output is never mutated

```gherkin
Given a scaffolded /tmp/demo-app/
When a developer runs `flutter create frontend --org com.example` inside /tmp/demo-app
Then git diff on /tmp/demo-app/frontend reports zero changes outside the Forge overlay paths
  (i.e. only CLAUDE.md and lib/core/.gitkeep etc.)
```

### AC-004 — Links FR-GL-013 : buf lint passes out of the box

```gherkin
Given a scaffolded /tmp/demo-app/
When a developer runs `cd /tmp/demo-app/shared/protos && buf lint`
Then exit code is 0 and stdout is empty
```

### AC-005 — Links FR-GL-014 : integration test detects missing file

```gherkin
Given a scaffolded /tmp/demo-app/
And the file /tmp/demo-app/backend/Cargo.toml is deleted
When `bash .forge/scripts/tests/scaffolder.test.sh --target /tmp/demo-app` runs
Then exit code is non-zero
And stdout contains "FAIL: missing backend/Cargo.toml"
```

### AC-006 — Links FR-GL-014 : integration test detects contract drift

```gherkin
Given a scaffolded /tmp/demo-app/
And the file /tmp/demo-app/.forge.yaml is modified to declare `schema: default`
When `bash .forge/scripts/tests/scaffolder.test.sh --target /tmp/demo-app` runs
Then exit code is non-zero
And stdout contains "FAIL: validate-foundations mismatch"
```

### AC-007 — Links FR-GL-010 : scaffold plan is parseable and describes every file

```gherkin
Given the file `.forge/templates/archetypes/full-stack-monorepo/scaffold-plan.yaml`
When `python3 -c 'import yaml; yaml.safe_load(open(...))'` runs
Then parsing succeeds
And `templates:` list length >= 20
And every `templates[].source` points at an existing file in the archetype tree
```

---

## Non-Functional Requirements

### NFR-005 : Scaffolder idempotence under `--force`

- **MUST** — running the scaffolder twice on the same target directory
  with `--force` produces a byte-identical tree on the second run
  (excluding files produced by external scaffolders, which by design
  must not be touched on re-run).

### NFR-006 : Scaffolder performance

- **SHALL** — the scaffold sequence completes in less than **30
  seconds** on a standard dev machine (excluding the first
  `flutter create` which can legitimately download SDK deps).
  A warm run (SDK cached, target tmpdir fresh) SHOULD complete in
  under 10 seconds.

### NFR-007 : Integration test reproducibility

- **MUST** — `scaffolder.test.sh` uses `mktemp -d` for isolation ;
  cleans up on exit via `trap` ; never touches the real repo.

### NFR-008 : External tool version policy

- **MUST** — the scaffolder checks `flutter --version`, `cargo
  --version`, `buf --version` and records them in a
  `.forge/scaffold-manifest.yaml` inside the generated project for
  auditability. The manifest includes : scaffold date, archetype
  version, tool versions, template set SHA.

---

## Out of Scope

<!-- Explicitly excluded — repeated from proposal for clarity. -->

- Agent `Janus` (B.1.7) — `b1-workflow`.
- Multi-root `verify.sh` / `constitution-linter.sh` (B.1.8) — `b1-workflow`.
- GitHub Actions CI workflows (B.1.9) — `b1-delivery`.
- `forge upgrade` (A.7) — separate change.
- Env overlays for dev/staging/prod (B.1.12) — `b1-delivery`.
- Observability integration (B.1.14) — `b1-delivery`.
- `@sdd-forge/cli` extension with `--archetype` flag — future change.
- Any amendment to the Constitution.
- Taskfile targets beyond the canonical five (`dev`, `test`, `lint`,
  `proto`, `release`).

---

## Open Questions

These questions are carried over from `proposal.md` and pinned here
so `/forge:design` addresses them explicitly.

- `[NEEDS CLARIFICATION: should `backend/Cargo.toml` be a workspace
  manifest with 5 crates enumerated from the start, or generated
  empty and let `cargo new --lib` auto-append to `members`?]`
  Proposed : generate minimal `[workspace]` with empty `members`,
  then rely on `cargo new` auto-append (Cargo ≥ 1.75 behavior).
  Fall back to explicit `members` list if auto-append fails.

- `[NEEDS CLARIFICATION: should `scaffolder.test.sh` live as an
  independent top-level harness or be wired into
  `foundations.test.sh`?]` Proposed : independent top-level harness
  invoked from `verify.sh` section 6 (new section, conditional on
  presence of a scaffolded project marker). Reason : external-tool
  dependencies make the test optional in many contexts — keeping it
  out of `foundations.test.sh` preserves the "always green" property
  of the foundations harness.

- `[NEEDS CLARIFICATION: example.proto package convention — `example.v1`
  or `<project_name>.example.v1`?]` Proposed : `example.v1` (project-
  agnostic). Keeps the template reusable across projects and makes it
  immediately clear that the proto is a seed, not a real service.

These questions do not block spec approval — they will be decided
during `/forge:design b1-scaffolder` with explicit ADRs.
