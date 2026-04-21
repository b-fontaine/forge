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
| [`b1-foundations`](../changes/b1-foundations/) | 2026-04-21 | Foundations (contract layer) | FR-GL-001..008 |

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

---

## Scope

**In scope for the archetype `full-stack-monorepo`:**

- The canonical contract (this file) and the schema / standards declared
  by FR-GL-001..007.
- The deterministic validator (FR-GL-008).

**Deferred to future changes (explicitly out of scope here):**

- Scaffolder `/forge:init --archetype full-stack-monorepo` — `b1-scaffolder`.
- Multi-layer change workflow + agent `Janus` + multi-root `verify.sh` /
  `constitution-linter.sh` — `b1-workflow`.
- GitHub Actions reference workflow + `forge upgrade` + env matrix —
  `b1-delivery`.
- Reference project (`C.1`) and migration paths — later.
