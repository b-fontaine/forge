# Changelog

All notable changes to the Forge Framework are documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(see [docs/VERSIONING.md](docs/VERSIONING.md) for our exact policy and its
coupling to the Constitution version).

While Forge is on the `0.y.z` pre-GA track, breaking changes may land in a
minor bump and will be called out under a `### BREAKING` subsection.

## [Unreleased]

Second delivery of the flagship archetype `full-stack-monorepo` — the
scaffolder layer. Combined with the foundations delivery (below), a
user can now run `/forge:init --archetype full-stack-monorepo <name>
--org <reverse-dns>` and get a contract-conformant Flutter + Rust +
Infra monorepo in ~3 seconds. The schema is promoted from `draft /
0.1.0` to `candidate / 1.0.0-rc.1` per the promotion rule from
`b1-foundations` ADR-004.

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
- **`_scaffolder_lib.sh` extraction** — deferred. Only 2 scaffolder
  scripts today with minimal overlap. Re-evaluate when a third script
  lands (likely in `b1-workflow` or `b1-delivery`).

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
