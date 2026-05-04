# Forge Versioning Policy

Forge follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)
(`MAJOR.MINOR.PATCH`) and couples its version to the [Constitution](../.forge/constitution.md).

The canonical version lives in the `VERSION` file at the repo root. All
tooling (CLI, installer, Docker image, CHANGELOG) reads it from there.

## Versioning Rules

### MAJOR

A MAJOR bump is required when **any** of the following changes:

- The Constitution is amended in a way that breaks compatibility (e.g. an
  article is added, renumbered, or its normative requirements are
  tightened in a way that existing projects would fail to satisfy).
- A template contract changes (fields of `proposal.md`, `spec.md`,
  `design.md`, `tasks.md`, `.forge.yaml`, `index.yml`) in a way that makes
  older projects unreadable by the current tooling.
- A scaffolded layout produced by `/forge:init` moves or removes files in a
  way existing upgrades cannot transparently reconcile.
- The CLI removes a command or a flag, or changes the meaning of an exit code.

### MINOR

A MINOR bump is required when:

- New commands, agents, standards, schemas, skills, or templates are added.
- Existing templates grow **optional** fields (backwards-compatible).
- New archetypes are introduced.
- New deterministic scripts or Docker image tags are added.
- Constitution text receives clarifications or non-normative notes.

### PATCH

A PATCH bump is required for:

- Typos, wording, or formatting fixes in docs, agents, or standards.
- Bug fixes in deterministic scripts (`verify.sh`, `constitution-linter.sh`).
- CLI fixes that do not change observable behavior.
- NOTICE/attribution updates.

## Constitution Coupling

Forge `MAJOR` tracks Constitution `MAJOR`. Concretely:

| Constitution | Framework range |
|--------------|-----------------|
| v1.x         | Forge 1.y.z     |
| v2.x         | Forge 2.y.z     |
| v3.x         | Forge 3.y.z     |

A Constitution bump from v1.y → v1.(y+1) is backwards-compatible and
triggers a framework MINOR bump. A Constitution bump from v1.x → v2.0 is
breaking and triggers a framework MAJOR bump in lockstep.

The current Constitution is **v1.0.0**. The current framework is **0.1.0**
because the framework is still in pre-GA: public distribution, installer,
and archetypes are not yet stabilized. Forge **1.0.0** will ship once
Modules A (licensing & distribution) and B (archetypes) are complete.

## Pre-1.0 Rules

While the framework is on `0.y.z`:

- Minor bumps **may** include breaking changes, but they MUST be announced
  in `CHANGELOG.md` under a `### BREAKING` subsection.
- Migration notes MUST be published in `docs/UPGRADING.md` (file will be
  added when the first breaking change lands).
- The Constitution itself is **not** pre-1.0 — it is ratified at v1.0.0
  and breaking changes to it still require a Constitution MAJOR bump,
  reflected in a framework MAJOR bump **as soon as** the framework goes GA.

## Release Artifacts

A release is considered published when **all** of the following exist for
a version `X.Y.Z`:

1. A git tag `vX.Y.Z` on `main`.
2. The `VERSION` file at HEAD of `main` contains `X.Y.Z`.
3. A `## [X.Y.Z] — YYYY-MM-DD` entry in `CHANGELOG.md`.
4. If the CLI changed: the `@sdd-forge/cli` npm tarball is published with the
   same version.
5. If deterministic scripts changed: the `forge/linter:X.Y.Z` Docker image
   is pushed with the same tag, and `forge/linter:latest` points to it.

## Monorepo Versioning Models

This section applies to projects using the `full-stack-monorepo` archetype
(schema `full-stack-monorepo`). For single-package projects, the root `VERSION`
/ `CHANGELOG.md` pair from the "Release Artifacts" section above is the
canonical approach. For multi-package monorepos (Flutter + Rust + Infra, with
protos as cross-layer contracts), two versioning models compete. This section
documents both, their trade-offs, and the Forge default.

### Release-train

The release-train model uses a single version number shared across all packages:

- ONE `VERSION` file at the repo root.
- ONE `CHANGELOG.md` at the repo root, using the Keep a Changelog format
  already in use by Forge.
- ALL packages (backend crates, frontend Flutter app, proto namespaces) ship
  at the same version number — e.g., `v1.4.0` means `backend v1.4.0`,
  `frontend v1.4.0`, `protos v1.4.0`.
- Releases are coordinated: a release PR bumps `VERSION`, generates the
  CHANGELOG entry, and tags `vX.Y.Z` on `main`.
- Best for: small teams (≤ ~15 contributors), tightly coupled layers,
  deployment in lockstep (e.g., backend + frontend always deployed together).
- Tooling: minimal — Taskfile target `task release` + manual CHANGELOG edit,
  or `release-plz` with root-only config.

Sample root-level `CHANGELOG.md` entry spanning all layers:

```markdown
## [1.4.0] — 2026-04-21

### Added

- **backend**: gRPC endpoint for user preferences (crate `svc-preferences`)
- **frontend**: Preferences screen wired to the new gRPC endpoint
- **protos**: `UserPreferences` message and `PreferencesService` definition

### Fixed

- **backend**: Panic on empty JWT claim in auth middleware
- **frontend**: Bottom nav bar overlap on notched devices
```

### Per-package via release-please

The per-package model gives each package its own independent version and
changelog:

- One `VERSION` and one `CHANGELOG.md` per package (e.g., `backend/VERSION`,
  `frontend/VERSION`, `shared/protos/VERSION`).
- `release-please` automates version bumping and changelog generation per
  package, based on Conventional Commit scopes (`feat(backend):`,
  `fix(frontend):`, `chore(infra):`, `feat(protos):`).
- release-please opens one "release PR" per package when changes accumulate;
  merging the PR tags and releases that single package independently.
- Best for: larger teams (≥ ~15 contributors), loosely coupled layers,
  independent deployment cadence (e.g., backend shipping weekly, frontend
  shipping bi-weekly, protos slow-moving).
- Tooling: release-please GitHub Action + a `release-please-manifest.json` at
  the repo root mapping each package path to its current version. Refer to the
  release-please GitHub Action documentation for configuration details.

Sample `release-please-manifest.json` shape:

```json
{
  ".": "0.1.0",
  "backend": "0.3.1",
  "frontend": "0.2.0",
  "shared/protos": "0.1.4"
}
```

### Decision Matrix

| Criterion                   | Release-train             | Per-package                                                            |
|-----------------------------|---------------------------|------------------------------------------------------------------------|
| Team size                   | ≤ 15 contributors         | ≥ 15                                                                   |
| Layer coupling              | tight (deploy together)   | loose (independent cadence)                                            |
| Release cadence             | lockstep                  | asynchronous per layer                                                 |
| CHANGELOG authoring         | centralized, manual       | automated per package                                                  |
| Contract (protos) evolution | folded into release train | separate cadence, safer for API stability                              |
| Compliance (audit trail)    | single release artifact   | per-package artifacts, finer granularity                               |
| Initial setup cost          | near zero                 | moderate (release-please + manifest + per-package CHANGELOG bootstrap) |

Teams can start with release-train and migrate to per-package later as the
team grows or coupling decreases. The reverse migration — from per-package back
to release-train — is painful (changelog history is fragmented, tags are
incoherent), so defaulting to release-train for new projects preserves
optionality without locking you in.

### Forge Default Recommendation

The Forge default is **release-train**. The scaffolder `/forge:init --archetype
full-stack-monorepo` (delivered in `b1-scaffolder`) initializes a root
`VERSION` and root `CHANGELOG.md` by default. Teams can opt into per-package
by passing `--versioning per-package` to `/forge:init`, or by editing
`.forge.yaml` post-init with `versioning_model: per-package` — either trigger
causes the scaffolder to emit `release-please-manifest.json` and per-package
`CHANGELOG.md` files instead. Post-init migration between models is documented
in `docs/ARCHETYPES.md` and `docs/MIGRATION-PATHS.md` (both forthcoming from
`b1-scaffolder` and Module B.5 respectively).

## Who Bumps the Version

- **PATCH**: any maintainer may bump during a routine fix commit.
- **MINOR**: requires a PR tagged `release:minor` and at least one
  maintainer review.
- **MAJOR**: requires a PR tagged `release:major`, a migration note, and
  a Constitution amendment reference if applicable.

## Supported Versions

Until Forge reaches `1.0.0`, only the latest `0.y.z` is supported.

From `1.0.0` onwards, the two most recent `MAJOR` lines are supported for
security fixes. See [SECURITY.md](../SECURITY.md) for the current matrix.
