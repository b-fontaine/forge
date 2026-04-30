# Spec: forge-ci

<!-- Audit: Module G.1 — GitHub Actions reference workflow for Forge itself. -->
<!-- Distinct from .forge/specs/full-stack-monorepo.md which governs the     -->
<!-- archetype workflows shipped to scaffolded projects. Audience here :     -->
<!-- Forge maintainers. Audience there : adopters scaffolding archetype      -->
<!-- projects.                                                               -->

This spec is the consolidated contract for **Forge's own CI workflow**
at `.github/workflows/forge-ci.yml`. It accumulates archived
requirements for the dog-fooding gate that runs Forge's own
test harnesses, deterministic gates, CLI Vitest suite, and shell
linter on every PR and push to `main`.

The full standard governing this spec is
`.forge/standards/global/forge-self-ci.md`.

---

## Archived changes

| Change | Date | Phase | FRs added |
|---|---|---|---|
| [`g1-forge-ci`](../changes/g1-forge-ci/) | 2026-04-29 | Forge's own CI workflow | FR-CI-001..011 + NFR-CI-001..006 |
| [`c1-reference-project`](../changes/c1-reference-project/) | 2026-04-30 | Reference project — example tree CI | ADDED FR-CI-012..013 ; MODIFIED FR-CI-001 (5 → 6 jobs, adds `example`) ; MODIFIED FR-CI-006 (4 → 5 needs, treats `example=skipped` as success) |

---

## Requirements

### FR-CI-001: Reference CI workflow `forge-ci.yml`

<!-- From change: g1-forge-ci (2026-04-29) -->
<!-- Modified in c1-reference-project (2026-04-30) — workflow now declares 6 top-level jobs (added `example`); summary's needs list extended accordingly. -->

- **MUST** — a file `.github/workflows/forge-ci.yml` exists and
  parses as valid YAML.
- **MUST** — the workflow triggers on `pull_request` (target
  branch `main`) and on `push` to `main`. No other triggers.
- **MUST** — the workflow declares a top-level `concurrency:`
  block with `group: forge-ci-${{ github.ref }}`. PR runs cancel
  in-progress (`cancel-in-progress: true`). Push-to-main runs
  do NOT cancel in-progress (`cancel-in-progress: false`).
  Implemented via the conditional expression
  `${{ github.event_name == 'pull_request' }}`.
- **MUST** — the workflow declares `permissions:` minimally :
  `contents: read` only. No write permissions, no `id-token`,
  no `pull-requests: write`.
- **MUST** — the workflow declares **exactly six top-level
  jobs** *(modified in c1-reference-project)* : `harness`,
  `gates`, `cli`, `lint`, `example`, `summary`. The first five
  run in parallel ; `summary` declares
  `needs: [harness, gates, cli, lint, example]`. The `example`
  job is conditionally active via `dorny/paths-filter@v3` on
  `examples/**` (FR-CI-012) and is **always** counted in the
  summary aggregation (a `skipped` result from `example` is
  treated as success — paths-filter mismatch is not a failure).
- **MUST** — every job sets `runs-on: ubuntu-latest`. No
  matrix, no other runners.
- **MUST** — no `continue-on-error: true` anywhere in the
  workflow.

<!-- Previously (g1-forge-ci): "exactly five top-level jobs:
     harness, gates, cli, lint, summary" with summary needing
     [harness, gates, cli, lint]. Superseded by the 6-job shape
     above per c1-reference-project. -->

**Constitution reference:** Article V (gates), Article VIII (CI
infrastructure), Article X (quality). **Testable:** yes —
`test_forge_ci_workflow_shape` (g1.test.sh, asserts 6 jobs) +
`test_forge_ci_workflow_shape_six_jobs` (c1.test.sh).

### FR-CI-002: Harness job runs 4 test harnesses at L1+L2

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `jobs.harness` runs the four shell test harnesses
  in the following order : `foundations.test.sh`,
  `scaffolder.test.sh --level 1,2`, `workflow.test.sh
  --level 1,2`, `delivery.test.sh`.
- **MUST** — each harness is invoked under `bash` explicitly
  (e.g. `bash .forge/scripts/tests/foundations.test.sh`).
- **MUST** — the job installs Python 3.11 via
  `actions/setup-python@v5` then `pip install pyyaml`.
- **MUST** — exit-code propagation : if any harness exits
  non-zero, the job fails immediately. No `|| true`, no `set
  +e`.

**Constitution reference:** Article I (TDD harness), Article V.
**Testable:** yes —
`test_forge_ci_harness_job_invokes_four_harnesses`.

### FR-CI-003: Gates job runs `verify.sh` and `constitution-linter.sh`

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `jobs.gates` runs, in order :
  `bash .forge/scripts/verify.sh` then
  `bash .forge/scripts/constitution-linter.sh`. Both must exit 0.
- **MUST** — both scripts run against the Forge repo root
  (`$GITHUB_WORKSPACE`).
- **MUST** — the job installs Python 3.11 + PyYAML.

**Constitution reference:** Article V, Article X. **Testable:**
yes — `test_forge_ci_gates_job_invokes_both_scripts`.

### FR-CI-004: CLI job runs Vitest + lint + bundle

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `jobs.cli` runs, in order, from the `cli/`
  working directory : `npm ci`, `npm run lint`, `npm test`,
  `npm run bundle`.
- **MUST** — Node version pinned via
  `actions/setup-node@v4` with
  `node-version-file: cli/.nvmrc`.
- **MUST** — `actions/setup-node@v4` built-in cache enabled :
  `cache: 'npm'`,
  `cache-dependency-path: cli/package-lock.json`.
- **MUST** — exit-code propagation strict (no
  `continue-on-error`).

**Constitution reference:** Article V, Article X. **Testable:**
yes — `test_forge_ci_cli_job_runs_npm_pipeline`.

### FR-CI-005: Lint job runs `shellcheck`

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `jobs.lint` runs `ludeeus/action-shellcheck@2.0.0`
  twice : once with `scandir: ./.forge/scripts`, once with
  `scandir: ./bin`. Both invocations use `severity: warning`.
- **MUST** — the action reference is pinned to a tag (e.g.
  `@2.0.0`). Tag-pinning, never `master`/`main`.
- **MUST** — any shellcheck warning at severity `warning` or
  stricter fails the job. No blanket `--exclude` ; targeted
  inline `# shellcheck disable=` directives are allowed when
  justified.

**Constitution reference:** Article X. **Testable:** yes —
`test_forge_ci_lint_job_invokes_shellcheck_on_target_dirs`.

### FR-CI-006: Summary job aggregates the five into one required status

<!-- From change: g1-forge-ci (2026-04-29) -->
<!-- Modified in c1-reference-project (2026-04-30) — summary's needs list extended to include the new `example` job; example=skipped is treated as success. -->

- **MUST** — `jobs.summary` declares `needs: [harness, gates,
  cli, lint, example]` *(modified in c1-reference-project)*.
- **MUST** — the summary job ALWAYS runs (`if: always()`). Its
  bash step inspects each `needs.<job>.result` (read via
  `env:` indirection from `${{ needs.<job>.result }}`).
  Exit semantics : the four core jobs (`harness`, `gates`,
  `cli`, `lint`) MUST exit `'success'` ; the `example` job MUST
  exit `'success'` OR `'skipped'` (paths-filter miss is not a
  failure). Any other result on any job — `failure`,
  `cancelled`, or `skipped` on the four core jobs — causes the
  summary to exit 1.
- **MUST** — when all five succeed (or `example` is `skipped`),
  the summary emits `::notice::forge-ci: 5/5 jobs PASS`. On
  any failure, emits
  `::error::forge-ci: <job>=<result> FAILED`.
- **MUST** — the GitHub Actions status name produced by this
  job is exactly `forge-ci / summary` so branch-protection
  rules can reference it as a single required check.

<!-- Previously (g1-forge-ci): summary needed only the four
     core jobs ([harness, gates, cli, lint]) and any non-success
     result was a failure. Superseded by the 5-need + example-
     skip-as-success semantics above per c1-reference-project. -->

**Constitution reference:** Article V. **Testable:** yes —
`test_forge_ci_summary_job_aggregates_needs` (g1.test.sh,
asserts 5 needs) + `test_forge_ci_summary_aggregates_five_needs`
+ `test_forge_ci_summary_treats_example_skip_as_success`
(c1.test.sh).

### FR-CI-007: Concurrency policy

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — top-level `concurrency:` declared with
  `group: forge-ci-${{ github.ref }}`.
- **MUST** — `cancel-in-progress` is the conditional expression
  `${{ github.event_name == 'pull_request' }}` : `true` for
  PRs, `false` for `push: main`.

**Constitution reference:** Article X (developer experience).
**Testable:** yes — `test_forge_ci_concurrency_policy`.

### FR-CI-008: `cli/.nvmrc` pins Node version

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — a file `cli/.nvmrc` exists, single line matching
  `^20\.[0-9]+\.[0-9]+$` (Node 20.x patch-pinned).
- **MUST** — the version satisfies the `cli/package.json`
  `engines.node: ">=20"` declaration.
- **MUST** — local maintainer tooling (`nvm use`) and CI
  (`actions/setup-node@v4`) read this same file, ensuring
  byte-identical Node across environments.

**Constitution reference:** Article X (reproducibility).
**Testable:** yes — `test_forge_ci_nvmrc_present_and_pinned`.

### FR-CI-009: Action and tool version pinning audit

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — every `uses:` reference in `forge-ci.yml` pins to
  a version. Bare action names or `@main` / `@master` /
  `@HEAD` are forbidden.
- **MUST** — no `:latest` tag appears anywhere in the workflow.

**Constitution reference:** Article X (supply-chain hygiene).
**Testable:** yes — `test_forge_ci_no_unpinned_uses`.

### FR-CI-010: Test harness `g1.test.sh`

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `.forge/scripts/tests/g1.test.sh` exists, is
  executable, sources `_helpers.sh`, declares one `test_*`
  per Testable FR.
- **MUST** — the harness validates `forge-ci.yml`'s YAML
  shape (5 jobs, summary's `needs:`, no `continue-on-error:
  true`, paths-filter NOT used, `permissions: contents: read`
  only, every `uses:` pinned).
- **MUST** — the harness validates `cli/.nvmrc` shape and
  content.
- **MUST** — `bash g1.test.sh` exits 0 when every assertion
  passes ; non-zero with `[FAIL] <test-name>: <reason>` lines
  on first failure.
- **SHALL** — the harness follows the manifest pattern
  (`# MANIFEST: test_* — FR-CI-NNN` lines) so a meta-test
  enforces manifest ↔ implementation parity.

**Constitution reference:** Article I, Article V. **Testable:**
self-testing — 14/14 scenarios PASS at archive time.

### FR-CI-011: Branch-protection guidance documented

<!-- From change: g1-forge-ci (2026-04-29) -->

- **MUST** — `docs/CONTRIBUTING.md` is updated with a section
  (under H2 "Continuous Integration", "CI", or "Branch
  protection") stating that the GitHub branch protection rule
  for `main` MUST require the status check `forge-ci / summary`
  to pass before merge.
- **MUST** — the section explains that the maintainer
  configures the rule via the GitHub UI (Settings → Branches
  → Branch protection rules) — NOT automated by Forge.
- **SHOULD** — the section lists the additional protections
  Forge recommends (linear history, signed commits, dismiss
  stale reviews on push). These are RECOMMENDATIONS, not
  mandates.

**Constitution reference:** Article V (gates documented),
Article X. **Testable:** yes —
`test_contributing_documents_branch_protection`.

### FR-CI-012: New `example` job in `forge-ci.yml`

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — `.github/workflows/forge-ci.yml` declares a sixth
  top-level job `example` running `runs-on: ubuntu-latest` with
  `permissions: contents: read` only.
- **MUST** — the `example` job runs **only** when the PR or
  push touches `examples/**` (gated by `dorny/paths-filter@v3`,
  pinned to the same major version as the archetype reference
  workflows of FR-IN-002..005). On a paths-filter miss, the job
  emits `skipped` and exits 0 — paths-filter mismatch is success,
  not failure (per the modified FR-CI-006).
- **MUST** — when the filter matches, the job executes, in
  order : (1) `actions/checkout@v4`, (2) `dorny/paths-filter@v3`
  with `id: examples-filter` and `filters: examples: ['examples/**']`,
  (3) `actions/setup-python@v5` + PyYAML install (gated on the
  filter output), (4) `cd examples/forge-fsm-example && bash
  .forge/scripts/verify.sh`, (5) `bash .forge/scripts/constitution-linter.sh`,
  (6) a Python `yaml.safe_load` over every
  `.github/workflows/*.yml.tmpl` in the example tree (fail on
  parse error). Steps 3-6 are gated on
  `if: steps.examples-filter.outputs.examples == 'true'`.
- **MUST** — no `continue-on-error: true` anywhere in the job ;
  consistent with `NFR-CI-003`.

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_forge_ci_example_job_present`,
`test_forge_ci_example_job_paths_filter`,
`test_forge_ci_example_job_steps` in `c1.test.sh`.

### FR-CI-013: Example workflow file size budget

<!-- From change: c1-reference-project (2026-04-30) -->

- **SHOULD** — adding the `example` job MUST keep `forge-ci.yml`
  ≤ 250 lines (the size budget from `NFR-CI-002`). Beyond that,
  the job MUST be extracted into a composite action under
  `.github/actions/forge-ci-example/action.yml`.

**Constitution reference:** Article X. **Testable:** yes —
`test_forge_ci_under_size_budget` (c1.test.sh) — at archive
time of c1, `forge-ci.yml` is well under the 250-line cap.

---

## Non-Functional Requirements

### NFR-CI-001: Workflow runtime budget

- **MUST** — total wall-clock from `queued` to `summary
  completed` MUST be ≤ 5 minutes on a warm GitHub Actions
  cache.
- **SHALL** — cold-cache runs MUST complete in ≤ 8 minutes.

### NFR-CI-002: Workflow file size

- **SHOULD** — `forge-ci.yml` MUST be ≤ 250 lines. Beyond
  that, refactor into composite actions or matrix
  strategies. Enforced by `test_forge_ci_under_size_budget`.

### NFR-CI-003: Failure semantics

- **MUST** — no `continue-on-error: true` anywhere. Failures
  must surface, never silently pass.
- **MUST** — `if: always()` is permitted ONLY for log-upload
  steps inside an already-completed job (e.g. uploading
  harness stdout on FR-CI-002 failure) and on the `summary`
  job (which by design must always run).

### NFR-CI-004: Cache hit rate

- **SHOULD** — `npm ci` cache hit rate ≥ 95% across PRs that
  do not modify `cli/package-lock.json`. Caching is the
  primary lever to keep NFR-CI-001 satisfied.

### NFR-CI-005: Permissions hygiene

- **MUST** — the workflow's `permissions:` MUST be the minimal
  set : `contents: read` only. No `pull-requests: write`,
  `id-token: write`, or other privileges. Future requirements
  needing more go through a Forge change.

### NFR-CI-006: Backwards compatibility on existing harnesses

- **MUST** — invoking the four test harnesses from CI MUST NOT
  require any modification to the harnesses themselves.
  CI passes `bash <path>` directly. Preserves the
  local-development invariant.

---

## Scope

**In scope for the `forge-ci` workflow (delivered so far):**

- The `forge-ci.yml` workflow with 6 jobs (harness, gates, cli,
  lint, example, summary), conditional concurrency, minimal
  permissions, pinned actions — **g1-forge-ci** for the original
  5 ; **c1-reference-project** for the 6th (`example`).
- `cli/.nvmrc` Node version pin — **g1-forge-ci**.
- Standard `global/forge-self-ci.md` — **g1-forge-ci**.
- Branch-protection guidance in `docs/CONTRIBUTING.md` —
  **g1-forge-ci**.
- Test harness `g1.test.sh` (14 tests, L1 structural) —
  **g1-forge-ci** ; updated in c1 to assert the 6-job + 5-needs
  shape.
- `example` job validating `examples/forge-fsm-example/` on PRs
  touching `examples/**` (FR-CI-012) — **c1-reference-project**.

**Deferred to future modules (out of scope for G.1):**

- `forge-ci-nightly.yml` running L3 levels of `scaffolder.test.sh`
  and `workflow.test.sh` (requires `flutter` + `cargo` + `buf`
  on the runner).
- Matrix builds across macOS / Windows.
- Coverage upload to Codecov / Coveralls.
- GitHub App "Forge Guardian" (audit module G.3) — heavier
  approach posting structured per-article PR comments.
- Dependabot configuration for action version updates.
- Automated branch-protection setup via GitHub API (deliberately
  manual per Aegis least-privilege principle).
