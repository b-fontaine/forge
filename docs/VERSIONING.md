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
