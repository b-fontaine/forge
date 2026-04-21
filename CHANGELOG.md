# Changelog

All notable changes to the Forge Framework are documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(see [docs/VERSIONING.md](docs/VERSIONING.md) for our exact policy and its
coupling to the Constitution version).

While Forge is on the `0.y.z` pre-GA track, breaking changes may land in a
minor bump and will be called out under a `### BREAKING` subsection.

## [Unreleased]

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
