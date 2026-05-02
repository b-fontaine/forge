# Proposal: g1-forge-ci
<!-- Created: 2026-04-29 -->
<!-- Schema: default -->
<!-- Parent audit module: G.1 — GitHub Actions reference workflow (T1 carry-over, expanded) -->
<!-- Depends on: b1-delivery (archived) — workflow conventions established by .forge/standards/infra/ci-workflows.md -->

## Problem

Forge ships four test harnesses (`foundations.test.sh`,
`scaffolder.test.sh`, `workflow.test.sh`, `delivery.test.sh`),
two deterministic gates (`verify.sh`, `constitution-linter.sh`),
a TypeScript CLI with Vitest tests, and 11 articles of
constitutional discipline that govern its own development. Yet
**the Forge repository itself has no CI workflow** — `.github/workflows/`
is empty (just a placeholder dir). Every B.1 commit landed because
the maintainer ran the gates locally ; nothing in the repo state
prevents a PR from merging with red harnesses, broken `cli/` build,
or a constitution violation.

This is the only outstanding T1 item from the audit roadmap (carry-over
to T2). It is also a **dog-fooding embarrassment** : Forge tells
adopters that constitutional gates must run in CI (`b1-delivery`
ships four reference workflows that prescribe this), while Forge
itself runs none. Until G.1 lands, every claim Forge makes about
spec-driven, gate-enforced development is undermined by the fact
that its own house is not in order.

Three concrete consequences :

1. **No mechanical safety net.** A PR that breaks
   `delivery.test.sh` or introduces a `[NEEDS CLARIFICATION]` in a
   spec can land if the maintainer forgets to run the gates locally.
2. **No regression detection.** The `cli/` package has 30+ Vitest
   tests covering scaffold + bundle paths. They run on the
   maintainer's machine ; they don't block a PR. A regression in
   the scaffolder is invisible until the next manual `npm test`.
3. **Adopters cannot verify Forge before adopting.** The PR badge
   on a Forge release is empty. Teams evaluating the framework see
   no green build, no covered scenario count, no proof-of-life.

## Solution

A single GitHub Actions workflow `.github/workflows/forge-ci.yml`
that runs **on every pull request** and **on every push to `main`**,
exercising the four gates Forge already has on disk :

1. **Test harnesses** — invoke `foundations.test.sh`,
   `scaffolder.test.sh`, `workflow.test.sh`, `delivery.test.sh`
   in their default L1+L2 modes (no flutter / cargo / buf required ;
   L3 fixture-based jobs run nightly in a separate workflow if
   the maintainer adds one later).
2. **Constitutional gates** — `bash .forge/scripts/verify.sh` then
   `bash .forge/scripts/constitution-linter.sh` against the repo
   root. Both must exit 0.
3. **CLI package** — in `cli/`, `npm ci`, `npm run lint` (TypeScript
   strict no-emit), `npm test` (Vitest run mode), then `npm run
   bundle` to confirm the npm-publishable tarball still builds.
4. **Shellcheck** — every `*.sh` file under `.forge/scripts/` and
   `bin/` passes `shellcheck`. A frequent class of bugs in our
   shell harnesses (unquoted variables, subshell exit-code
   surprises) is exactly what shellcheck catches.

Workflow conventions follow the standard documented in
`.forge/standards/infra/ci-workflows.md` (delivered by `b1-delivery`),
adapted for the fact that **Forge is not a `full-stack-monorepo`
project**. Differences :

- **No `dorny/paths-filter`.** Forge is a flat repository ; every
  PR potentially touches gates or harnesses. Path-filtering would
  add complexity for no win — the full job set runs in ~3 minutes.
- **One workflow, multiple jobs.** Per ADR-001 of `b1-delivery`,
  Forge does **not** ship the archetype's per-layer workflows on
  itself. A single `forge-ci.yml` with three parallel jobs
  (`harness`, `cli`, `lint`) is the right grain.

The workflow caches `~/.npm` and `~/.cache/shellcheck-py` keyed on
`cli/package-lock.json` and the shellcheck version pin respectively.
Tools are pinned per ADR-008 of `b1-delivery` :
`actions/checkout@v4`, `actions/setup-node@v4`, `actions/cache@v4`.

## Scope In

- Single workflow `.github/workflows/forge-ci.yml` with three
  parallel jobs and one `summary` job that depends on all three.
- **Job `harness`** — runs the 4 shell test harnesses at
  L1+L2 levels, asserts an aggregated 75/75 PASS (or higher as
  future changes add tests).
- **Job `gates`** — runs `verify.sh` + `constitution-linter.sh`
  against the Forge repo, asserts both exit 0.
- **Job `cli`** — `cd cli && npm ci && npm run lint && npm test
  && npm run bundle`. Pinned Node 20.x via
  `actions/setup-node@v4` with `node-version-file: cli/.nvmrc`
  (creating `.nvmrc` as part of this change).
- **Job `lint`** — `shellcheck` on every `*.sh` under
  `.forge/scripts/` and `bin/`.
- **Job `summary`** — depends on all four ; emits a single
  required status `forge-ci` for branch protection. Posts a
  one-line summary as a workflow annotation.
- **Concurrency control** — `concurrency.group: forge-ci-${{
  github.ref }}`, `cancel-in-progress: true` for PRs ;
  `cancel-in-progress: false` for `main` (parallel commits run
  to completion).
- **`cli/.nvmrc`** — pins Node 20.x as the canonical version for
  Forge development. Documents the engine constraint already
  declared in `cli/package.json` (`"node": ">=20"`).
- **Branch protection guidance** — `docs/CONTRIBUTING.md` section
  documenting that the `forge-ci / summary` status is required to
  merge. Maintainer applies the GitHub branch protection rule
  manually (this proposal does not include the API call).
- **One new standard (or extension)** — either extend
  `.forge/standards/infra/ci-workflows.md` with a § "Forge's own
  CI" or write a new `.forge/standards/global/forge-self-ci.md`.
  Decision deferred to design phase.
- **Test harness extension** — a new `g1.test.sh` (or a section in
  `delivery.test.sh`) that asserts the workflow file exists, has
  the four jobs, the summary job depends on the others, no
  `:latest` tags, no `continue-on-error: true`. Validates the
  contract ; not a smoke test of the actual workflow execution.

## Scope Out (Explicit Exclusions)

- **No matrix build.** Forge gates are platform-agnostic shell ;
  ubuntu-latest is sufficient. macOS and Windows runners would
  triple cost for marginal coverage. Re-evaluate if a contributor
  reports a platform-specific bug.
- **No `act` integration.** Running the workflow locally via `act`
  is documented elsewhere ; this change only ships the workflow.
- **No L3 harness execution in CI.** L3 levels of
  `scaffolder.test.sh` and `workflow.test.sh` require flutter +
  cargo + buf, which are heavy to install. Deferred to a separate
  nightly workflow (`forge-ci-nightly.yml`) — out of scope here.
- **No release workflow.** Cutting `0.3.0` (or any other version),
  publishing to npm, building Docker images — none are in scope.
  `forge-ci.yml` is purely a quality gate ; release tooling is a
  separate concern.
- **No coverage upload to a third-party service** (Codecov,
  Coveralls). Vitest's coverage stays local for now.
- **No GitHub App** (Forge Guardian, audit module G.3). G.1 is
  the lightweight workflow-only path ; the App is a future module
  that posts structured per-article PR comments.
- **No automatic version bump or CHANGELOG enforcement.** PR
  hygiene is a separate audit item.
- **No branch-protection API call.** The workflow becomes a
  required check **only after** the maintainer enables the rule
  in GitHub's UI. We document the step ; we don't automate it
  (avoids an unauthorized GitHub API write from CI).

## Impact

- **Users affected** : Forge maintainers (gain a mechanical safety
  net for every PR), external contributors (gain a public proof
  that PRs are gated), adopters evaluating Forge (gain a green
  build badge on every release).
- **Technical impact** : Low. Single new workflow file (~120 lines),
  one new `.nvmrc`, optional new standard or section. No code
  changes to Forge gates or harnesses. No schema bumps.
- **Dependencies** : `b1-delivery` archived (workflow conventions
  documented). Runtime : GitHub Actions on `ubuntu-latest`, Node
  20.x, Python 3 + PyYAML (already required by harnesses).
- **Risk level** : Very low. The workflow exercises gates that
  already exist and pass on disk ; if it fails on first run the
  fix is mechanical (typically a missing dependency in the GitHub
  runner image). Reverting via `git revert` is a one-commit operation.

## Constitution Compliance

### Article I — TDD

The deliverable is a YAML workflow file, not application code, but
TDD applies :

- **RED** — write `g1.test.sh` (or extend `delivery.test.sh`) with
  assertions about the workflow file (4 jobs declared, summary
  job depends on the others, no `:latest`, `concurrency.group`
  declared, paths-filter NOT used). Run ; tests FAIL because the
  workflow does not exist yet.
- **GREEN** — write `forge-ci.yml` to satisfy the assertions.
- **REFACTOR** — ensure caching is keyed on lockfiles, comments
  document the dog-fooding rationale.

### Article II — BDD

User-facing surface : a contributor opens a PR and sees a single
required status `forge-ci`. One BDD scenario in
`.forge/changes/g1-forge-ci/features/` covers happy path (PR with
clean repo state → all 4 jobs pass → summary green → mergeable)
and red path (PR breaking `delivery.test.sh` → harness job fails
→ summary red → not mergeable).

### Article III — Specs Before Code

Confirmed. No `forge-ci.yml`, `g1.test.sh`, `.nvmrc`, or standard
extension is written until `/forge:specify g1-forge-ci` produces
`specs.md` and `/forge:design g1-forge-ci` produces `design.md`.

### Article IV — Semantic Deltas

This change does not amend an existing spec — there is no
consolidated spec for "Forge's own CI" yet (none has been needed
before). The specs.md will declare new FRs (FR-CI-001..NNN) on
its own, and the archive will create
`.forge/specs/forge-ci.md` (or extend an existing global spec).
Decision deferred to specify phase.

### Article V — Conformance Gate

This change *is* the gate. Once landed, every future PR runs
through it. The gate-on-the-gate (validating `forge-ci.yml`'s
shape) lives in `g1.test.sh`.

### Article VIII — Infrastructure

CI is infrastructure. Atlas leads design. Conventions inherited
from `.forge/standards/infra/ci-workflows.md` (b1-delivery) :
gate ordering, tool version pinning, no `continue-on-error: true`,
concurrency policy.

### Article X — Quality

Zero-warning gates : `tsc --noEmit` strict, Vitest run mode (any
failed test fails the job), `shellcheck` strict, all four
harnesses must report 100% PASS. No `continue-on-error: true`
anywhere.

### Articles VI, VII, IX, XI

Not directly relevant. No Flutter app code (Article VI), no Rust
app code (Article VII), no observability deliverables here
(Article IX is satisfied indirectly because the harness workflow
preserves the existing observability assertions in
`delivery.test.sh`), no AI features (Article XI).
