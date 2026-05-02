# Spec: g1-forge-ci
<!-- Delta format: ADDED, MODIFIED, REMOVED sections only -->
<!-- Audit: G.1 -->
<!-- Depends on: b1-delivery (archived) — workflow conventions inherited from .forge/standards/infra/ci-workflows.md -->
<!-- New FR namespace: FR-CI-* (Forge's own CI, distinct from FR-GL-* archetype work) -->

## Glossary

- **`forge-ci.yml`** — the single GitHub Actions workflow shipped
  by this change at `.github/workflows/forge-ci.yml`. The
  authoritative quality gate for every Forge PR and every push
  to `main`.
- **Required status `forge-ci`** — the GitHub branch-protection
  status name that must report success before a PR can merge.
  Materialised as the `summary` job's GitHub Actions outcome.
- **Test harness** — one of the 4 shell scripts under
  `.forge/scripts/tests/` that exercise the framework
  contract : `foundations.test.sh`, `scaffolder.test.sh`,
  `workflow.test.sh`, `delivery.test.sh`.
- **Gate scripts** — `.forge/scripts/verify.sh` and
  `.forge/scripts/constitution-linter.sh` — the two deterministic
  Forge-content validators that complement the LLM gates.
- **L1+L2 harness mode** — the test levels each harness runs by
  default (structural invariants + fixture-based, no external
  language toolchain). L3 (full E2E, requires flutter / cargo /
  buf) is explicitly out of scope for `forge-ci.yml`.
- **`.nvmrc`** — the standard Node.js version pinning file that
  `actions/setup-node@v4` reads when given
  `node-version-file: cli/.nvmrc`.

---

## ADDED Requirements

### FR-CI-001: Reference CI workflow `forge-ci.yml`

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — a file `.github/workflows/forge-ci.yml` exists and
  parses as valid YAML.
- **MUST** — the workflow triggers on `pull_request` (target
  branch `main`) and on `push` to `main`. No other triggers.
- **MUST** — the workflow declares a top-level `concurrency:`
  block with `group: forge-ci-${{ github.ref }}`. PR runs cancel
  in-progress (`cancel-in-progress: true`). Push-to-main runs
  do NOT cancel in-progress (`cancel-in-progress: false`) — a
  separate workflow per ref handles that asymmetry, OR the
  asymmetry is conditional on `github.ref` ; design phase picks
  the cleaner of the two patterns.
- **MUST** — the workflow declares `permissions:` minimally :
  `contents: read` only (no write permissions, no `id-token`,
  no `pull-requests: write`).
- **MUST** — the workflow declares **exactly five top-level
  jobs** : `harness`, `gates`, `cli`, `lint`, `summary`. The
  first four run in parallel ; `summary` declares
  `needs: [harness, gates, cli, lint]`.
- **MUST** — every job sets `runs-on: ubuntu-latest`. No
  matrix, no other runners (Scope Out per proposal).
- **MUST** — no `continue-on-error: true` anywhere in the
  workflow.

**Constitution reference:** Article V (gates), Article VIII (CI
infrastructure), Article X (quality). **Testable:** yes —
`test_forge_ci_workflow_shape` in `g1.test.sh`.

---

### FR-CI-002: Harness job runs 4 test harnesses at L1+L2

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `jobs.harness` runs the four shell test harnesses
  in the following order : `foundations.test.sh`,
  `scaffolder.test.sh --level 1,2`, `workflow.test.sh
  --level 1,2`, `delivery.test.sh`.
- **MUST** — each harness is invoked under `bash` explicitly
  (e.g. `bash .forge/scripts/tests/foundations.test.sh`) — never
  via `./script.sh` (avoids reliance on the executable bit
  surviving git operations).
- **MUST** — the job installs Python 3 with PyYAML
  (`pip install pyyaml`) before invoking the harnesses. This is
  the only external dependency the L1+L2 levels require.
- **MUST** — exit-code propagation : if any harness invocation
  exits non-zero, the job fails immediately (default
  short-circuiting ; no `|| true`, no `set +e`).
- **SHOULD** — the job emits an `actions/upload-artifact@v4`
  step on failure capturing the harness stdout/stderr for
  triage. Optional ; deferred to design phase if scope.

**Constitution reference:** Article I (TDD harness),
Article V. **Testable:** yes —
`test_forge_ci_harness_job_invokes_four_harnesses`.

---

### FR-CI-003: Gates job runs `verify.sh` and `constitution-linter.sh`

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `jobs.gates` runs, in order :
  `bash .forge/scripts/verify.sh` then
  `bash .forge/scripts/constitution-linter.sh`. Both must exit 0.
- **MUST** — both scripts run against the Forge repo root (the
  current working directory of the job — `$GITHUB_WORKSPACE`),
  matching local invocation semantics.
- **MUST** — the job installs Python 3 with PyYAML (same as
  FR-CI-002). It does NOT need `flutter`, `cargo`, or `buf`
  because those are not declared by Forge's own schema (Forge
  has `schema: default`, not `full-stack-monorepo`).
- **SHALL** — the job uses `actions/checkout@v4` with default
  `fetch-depth: 1` ; the gates do not require git history.

**Constitution reference:** Article V, Article X. **Testable:**
yes — `test_forge_ci_gates_job_invokes_both_scripts`.

---

### FR-CI-004: CLI job runs Vitest + lint + bundle

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `jobs.cli` runs, in order, from the `cli/`
  working directory : `npm ci`, `npm run lint`, `npm test`,
  `npm run bundle`.
- **MUST** — Node version pinned via
  `actions/setup-node@v4` with
  `node-version-file: cli/.nvmrc` (FR-CI-008 establishes
  `.nvmrc` itself).
- **MUST** — `actions/cache@v4` caches `~/.npm` keyed on
  `${{ hashFiles('cli/package-lock.json') }}` to satisfy
  NFR-CI-001's runtime budget.
- **MUST** — exit-code propagation strict (no `continue-on-error`).

**Constitution reference:** Article V, Article X. **Testable:**
yes — `test_forge_ci_cli_job_runs_npm_pipeline`.

---

### FR-CI-005: Lint job runs `shellcheck` on Forge shell scripts

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `jobs.lint` runs `shellcheck` against every
  `*.sh` file under `.forge/scripts/` and `bin/` recursively.
- **MUST** — `shellcheck` is invoked with the strict severity
  `--severity=warning` (or stricter) and `--format=gcc` for
  GitHub-friendly output.
- **MUST** — the job uses an action that pins the shellcheck
  version (e.g. `ludeeus/action-shellcheck@2.0.0` or
  equivalent). Tag pinning, never `master` / `main`.
- **MUST** — any shellcheck warning fails the job. No
  `--exclude=...` blanket suppressions ; targeted suppressions
  via `# shellcheck disable=...` directives in the source files
  are allowed when justified inline.
- **MAY** — the job runs in parallel with the other three to
  surface lint issues independently of harness/gate/CLI failures.

**Constitution reference:** Article X. **Testable:** yes —
`test_forge_ci_lint_job_invokes_shellcheck_on_target_dirs`.

---

### FR-CI-006: Summary job aggregates the four into one required status

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `jobs.summary` declares
  `needs: [harness, gates, cli, lint]`.
- **MUST** — the job's first step inspects each `needs.<job>.result`
  and FAILS the job if any of the four is not exactly `'success'`.
  A `skipped` or `cancelled` result MUST cause the summary to fail.
- **MUST** — when all four succeed, the summary emits a one-line
  GitHub Actions notice annotation summarising the result
  (e.g. "forge-ci: 4/4 jobs PASS").
- **MUST** — the GitHub Actions status name produced by this job
  is exactly `forge-ci / summary` so branch-protection rules can
  reference it as a single required check.

**Constitution reference:** Article V (single gate aggregation
point). **Testable:** yes —
`test_forge_ci_summary_job_aggregates_needs`.

---

### FR-CI-007: Concurrency policy

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — top-level `concurrency:` is declared with
  `group: forge-ci-${{ github.ref }}`.
- **MUST** — `cancel-in-progress` is `true` for `pull_request`
  events and `false` for `push: main` events. Implementation
  may use the conditional `cancel-in-progress: ${{
  github.event_name == 'pull_request' }}` (compact) or two
  separate workflows (split). Decision in design phase.

**Constitution reference:** Article X (developer experience).
**Testable:** yes — `test_forge_ci_concurrency_policy`.

---

### FR-CI-008: `cli/.nvmrc` pins Node version

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — a file `cli/.nvmrc` exists, contains a single line
  matching `^20\.[0-9]+\.[0-9]+$` (Node 20.x patch-pinned).
- **MUST** — the version chosen MUST satisfy the
  `cli/package.json` `engines.node: ">=20"` declaration.
- **MUST** — local maintainer tooling (e.g. `nvm use`) and CI
  (`actions/setup-node@v4`) read this same file, ensuring
  byte-identical Node across environments.
- **SHOULD** — bumps to `.nvmrc` happen in their own change
  cycle (separate Forge change), never bundled with feature
  work.

**Constitution reference:** Article X (reproducibility).
**Testable:** yes — `test_forge_ci_nvmrc_present_and_pinned`.

---

### FR-CI-009: Action and tool version pinning audit

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — every `uses:` reference in `forge-ci.yml` pins to
  a version (e.g. `@v4`, `@2.0.0`, or a SHA). Bare action names
  or `@main` / `@master` are forbidden.
- **MUST** — no `:latest` tag appears anywhere in the workflow
  (mirrors NFR-018 of `b1-delivery`).
- **MUST** — when an action has a major version tag, the
  workflow uses the major (e.g. `actions/checkout@v4`). When an
  action has a minor or patch version tag, the workflow uses
  the most specific available (defense in depth).

**Constitution reference:** Article X (supply-chain hygiene).
**Testable:** yes — `test_forge_ci_no_unpinned_uses`.

---

### FR-CI-010: Test harness `g1.test.sh`

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — a file `.forge/scripts/tests/g1.test.sh` exists,
  is executable, sources `_helpers.sh`, and declares one
  `test_*` function per Testable FR in this spec.
- **MUST** — the harness validates `forge-ci.yml`'s YAML
  structure : 5 jobs, summary's `needs:`, no
  `continue-on-error: true`, paths-filter NOT used,
  `permissions: contents: read` only, every `uses:` pinned.
- **MUST** — the harness validates `cli/.nvmrc` (FR-CI-008)
  shape and content.
- **MUST** — `bash .forge/scripts/tests/g1.test.sh` exits 0
  when every assertion passes ; non-zero with clear `[FAIL]
  <test-name>: <reason>` lines on the first failure.
- **SHALL** — the harness follows the existing manifest pattern
  (`# MANIFEST: test_* — FR-CI-NNN` lines) so a meta-test can
  enforce manifest ↔ implementation consistency.

**Constitution reference:** Article I, Article V. **Testable:**
yes — meta self-check via the manifest pattern.

---

### FR-CI-011: Branch-protection guidance documented

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `docs/CONTRIBUTING.md` is updated with a section
  (under H2 "CI" or equivalent) stating that the GitHub branch
  protection rule for `main` MUST require the status check
  `forge-ci / summary` to pass before merge.
- **MUST** — the section explains that the maintainer
  configures the rule via the GitHub UI (Settings → Branches →
  Branch protection rules) — this is NOT automated by Forge.
  Rationale : avoids granting CI write access to repository
  settings, principle of least privilege.
- **SHOULD** — the section links to GitHub's branch-protection
  documentation and lists the additional protections Forge
  recommends (require linear history, require signed commits,
  dismiss stale reviews on push). These are RECOMMENDATIONS,
  not mandates.

**Constitution reference:** Article V (gates documented),
Article X (project hygiene). **Testable:** yes —
`test_contributing_documents_branch_protection`.

---

## MODIFIED Requirements

*None.* This change introduces a brand-new FR namespace
(`FR-CI-*`). No prior requirement is amended.

---

## REMOVED Requirements

*None.* No deprecation in this change.

---

## Acceptance Criteria

### AC-001 — Links FR-CI-001..006 : clean PR passes all jobs

```gherkin
Given the Forge repo's main branch is in a clean, gate-passing state
And a contributor opens a PR that touches docs only (no harness, gate, or CLI changes)
When the PR is opened
Then `forge-ci.yml` runs on `ubuntu-latest`
And `jobs.harness` exits 0 (foundations 21/21, scaffolder 14/14, workflow 16/16, delivery 24/24)
And `jobs.gates` exits 0 (verify.sh 50 PASS / 0 FAIL, constitution-linter 4 PASS / 0 FAIL / 6 N/A)
And `jobs.cli` exits 0 (npm ci, lint, test, bundle all succeed)
And `jobs.lint` exits 0 (shellcheck clean on .forge/scripts/ and bin/)
And `jobs.summary` reports "forge-ci: 4/4 jobs PASS"
And the required status check `forge-ci / summary` is green
And the PR is mergeable per branch protection
```

### AC-002 — Links FR-CI-002, FR-CI-006 : breaking a harness blocks merge

```gherkin
Given the Forge repo's main branch is clean
And a contributor opens a PR that introduces a regression in `delivery.test.sh`
  (e.g. removes a required H2 section from `standards/infra/ci-workflows.md`)
When the PR is opened
Then `jobs.harness` runs `delivery.test.sh` which exits non-zero on the regression
And `jobs.harness` fails
And `jobs.summary` fails because `needs.harness.result != 'success'`
And the required status check `forge-ci / summary` is red
And the PR is NOT mergeable
```

### AC-003 — Links FR-CI-004 : breaking the CLI build blocks merge

```gherkin
Given the Forge repo's main branch is clean
And a contributor opens a PR that introduces a TypeScript type error in `cli/src/`
When the PR is opened
Then `jobs.cli` runs `npm run lint` which fails on the type error
And `jobs.cli` fails before reaching `npm test`
And `jobs.summary` fails
And the PR is NOT mergeable
```

### AC-004 — Links FR-CI-005 : a shellcheck warning blocks merge

```gherkin
Given the Forge repo's main branch is clean
And a contributor opens a PR that introduces an unquoted variable expansion in a `.sh` script
When the PR is opened
Then `jobs.lint` runs shellcheck which emits a `--severity=warning` finding
And `jobs.lint` fails
And `jobs.summary` fails
And the PR is NOT mergeable
```

### AC-005 — Links FR-CI-003 : a constitution violation blocks merge

```gherkin
Given the Forge repo's main branch is clean
And a contributor opens a PR that removes the FR-GL-001 entry from `.forge/specs/full-stack-monorepo.md`
  (Article IV violation : silent removal without an explicit REMOVED section)
When the PR is opened
Then `jobs.gates` runs `constitution-linter.sh` which detects the violation
And `jobs.gates` fails
And `jobs.summary` fails
And the PR is NOT mergeable
```

### AC-006 — Links FR-CI-007 : superseded PR run is cancelled

```gherkin
Given a PR has an in-progress `forge-ci.yml` run on commit SHA `<X>`
When the PR is force-pushed with a new commit SHA `<Y>`
Then GitHub Actions cancels the in-progress run on `<X>` (`cancel-in-progress: true`)
And a new run starts on `<Y>`
And only the run on `<Y>` reports the final status

When the same scenario plays out on `push: main` (rapid sequential merges)
Then the in-progress main run does NOT cancel (`cancel-in-progress: false`)
And both runs complete independently
```

### AC-007 — Links FR-CI-001, NFR-CI-001 : workflow runtime is bounded

```gherkin
Given a clean PR with warm GitHub Actions cache
When `forge-ci.yml` runs end-to-end
Then total wall-clock time from "queued" to "summary completed" is ≤ 5 minutes
And `jobs.summary` runs within 30 seconds after the last `needs` job completes

Given a cold cache (cache miss on `npm ci`)
Then total wall-clock time is ≤ 8 minutes
```

---

## Non-Functional Requirements

### NFR-CI-001: Workflow runtime budget

- **MUST** — total wall-clock from `queued` to `summary
  completed` MUST be ≤ 5 minutes on a warm GitHub Actions
  cache.
- **SHALL** — cold-cache runs MUST complete in ≤ 8 minutes.
- **Rationale** — beyond ~5 min on every PR, contributors
  disengage. The 5-min budget mirrors the spirit of NFR-013
  (per-layer workflow ≤ 8 min) but tighter because Forge has
  no language-specific compilation step (no `cargo`, no
  `flutter`).

### NFR-CI-002: Workflow file size

- **SHOULD** — `forge-ci.yml` MUST be ≤ 250 lines (mirrors
  NFR-016 of `b1-delivery`). Beyond 250 lines, refactor
  repeated step blocks into composite actions or matrix
  strategies.

### NFR-CI-003: Failure semantics

- **MUST** — no `continue-on-error: true` anywhere in the
  workflow. Failures must surface, never silently pass.
  Mirrors the `b1-delivery` `infra/ci-workflows.md` § Failure
  semantics rule.
- **MUST** — `if: always()` is permitted ONLY for log-upload
  steps inside a job that has already completed its primary
  work (e.g. uploading harness stdout on FR-CI-002 failure).
  Forbidden as a general short-circuit.

### NFR-CI-004: Cache hit rate

- **SHOULD** — `npm ci` cache hit rate ≥ 95% across PRs that
  do not modify `cli/package-lock.json`. Measured by
  inspecting workflow run logs for the `Cache restored
  successfully` message frequency.
- **Rationale** — caching is the primary lever to keep
  NFR-CI-001 satisfied. A degraded cache hit rate
  immediately surfaces in the runtime budget breach.

### NFR-CI-005: Permissions hygiene

- **MUST** — the workflow's `permissions:` MUST be the minimal
  set needed for the work : `contents: read` only. No
  `pull-requests: write`, `id-token: write`, or other
  privileges. If a future requirement needs more, it goes
  through a Forge change.
- **Rationale** — supply-chain hygiene. A compromised
  third-party action with broad permissions is the dominant
  attack vector ; minimizing the permission surface is the
  cheapest mitigation.

### NFR-CI-006: Backwards compatibility on existing harnesses

- **MUST** — invoking the four test harnesses from CI MUST NOT
  require any modification to the harnesses themselves. The
  harnesses already accept their input via the working
  directory + `FORGE_ROOT` env. CI passes `bash <path>`
  directly — no wrappers, no flags except those already
  documented in the harness `--help`.
- **Rationale** — preserves the local-development invariant
  that `bash .forge/scripts/tests/<harness>.test.sh` produces
  the same result on a contributor's machine and in CI.

---

## Out of Scope

- **No matrix builds.** ubuntu-latest only. macOS / Windows
  runners are out of scope ; re-evaluate if a contributor
  reports a platform-specific bug.
- **No L3 harness execution.** L3 levels of `scaffolder.test.sh`
  and `workflow.test.sh` require flutter + cargo + buf —
  heavyweight installs that triple the runtime budget.
  Deferred to a separate `forge-ci-nightly.yml` (future
  change).
- **No release workflow.** Cutting versions, publishing to
  npm, building Docker images — none are in scope. `forge-ci.yml`
  is purely a quality gate.
- **No Codecov / coverage upload.** Vitest coverage stays
  local for now.
- **No Forge Guardian GitHub App** (audit module G.3). G.1 is
  the lightweight workflow-only path.
- **No automatic version bump or CHANGELOG enforcement.**
  Separate change cycle.
- **No branch-protection API call.** Documentation-only ; the
  maintainer enables the rule via the GitHub UI.
- **No Dependabot configuration.** Action version updates are
  handled by manual Forge change cycles (per ADR-008 of
  `b1-delivery`). Dependabot can be added in a future change
  if the maintenance overhead becomes a bottleneck.

---

## Open Questions

*None blocking.* The deferred decisions are all design-phase
choices, not unresolved spec ambiguities :

- *(design phase)* `concurrency.cancel-in-progress` asymmetry
  between PR and main : conditional expression
  (`${{ github.event_name == 'pull_request' }}`) vs split into
  two workflows. Both satisfy FR-CI-007 ; the design phase
  picks the cleaner of the two patterns.
- *(design phase)* Whether to ship a § "Forge's own CI" inside
  the existing `infra/ci-workflows.md` standard or write a new
  `global/forge-self-ci.md`. The Atlas / design-phase decision
  ; both options satisfy the editorial discipline.
- *(design phase)* Whether `g1.test.sh` is a fifth standalone
  harness or a new section in `delivery.test.sh`. ADR-010 of
  `b1-delivery` favored standalone harnesses with shared
  `_helpers.sh` ; this change likely follows that convention,
  but the design phase confirms.

If new clarification arises during `/forge:design g1-forge-ci`,
record it here as `[NEEDS CLARIFICATION: ...]` and STOP.
