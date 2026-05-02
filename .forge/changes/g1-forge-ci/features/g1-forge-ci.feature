# <!-- Audit: G.1 (g1-forge-ci, Phase 3.5) -->
# BDD acceptance criteria for Forge's own CI workflow. Mirrors
# AC-001..007 from .forge/changes/g1-forge-ci/specs.md.

Feature: Forge's own CI gate
  As a Forge maintainer or external contributor
  I want every Forge PR to be gated by a single required status
    that runs the four shell harnesses, the two deterministic gates,
    the CLI Vitest suite, and shellcheck on the shell scripts
  So that no PR can land with broken gates, type errors in the CLI,
    or shellcheck warnings — and so that adopters see a green build
    badge as proof-of-life on every release.

  Background:
    Given the Forge repository main branch is in a clean,
      gate-passing state
    And `.github/workflows/forge-ci.yml` is committed
    And the GitHub branch protection rule for `main` requires the
      status check `forge-ci / summary`

  Scenario: AC-001 — clean PR passes all jobs
    Given a contributor opens a PR that touches docs only (no harness,
      gate, or CLI changes)
    When the PR is opened
    Then `forge-ci.yml` runs on `ubuntu-latest`
    And `jobs.harness` exits 0 (foundations 21/21, scaffolder 14/14,
      workflow 11/11 at L1+L2, delivery 24/24)
    And `jobs.gates` exits 0 (verify.sh PASS, constitution-linter PASS)
    And `jobs.cli` exits 0 (npm ci, lint, test, bundle all succeed)
    And `jobs.lint` exits 0 (shellcheck clean on .forge/scripts/ and bin/)
    And `jobs.summary` emits "::notice::forge-ci: 4/4 jobs PASS"
    And the required status check `forge-ci / summary` is green
    And the PR is mergeable per branch protection

  Scenario: AC-002 — breaking a harness blocks merge
    Given a contributor opens a PR that introduces a regression in
      `delivery.test.sh` (e.g. removes a required H2 section from
      `standards/infra/ci-workflows.md`)
    When the PR is opened
    Then `jobs.harness` runs `delivery.test.sh` which exits non-zero
    And `jobs.harness` fails
    And `jobs.summary` emits "::error::forge-ci: harness=failure FAILED"
    And `jobs.summary` exits 1
    And the required status check `forge-ci / summary` is red
    And the PR is NOT mergeable

  Scenario: AC-003 — breaking the CLI build blocks merge
    Given a contributor opens a PR that introduces a TypeScript type
      error in `cli/src/`
    When the PR is opened
    Then `jobs.cli` runs `npm run lint` which fails on the type error
    And `jobs.cli` fails before reaching `npm test`
    And `jobs.summary` fails because needs.cli.result != 'success'
    And the PR is NOT mergeable

  Scenario: AC-004 — a shellcheck warning blocks merge
    Given a contributor opens a PR that introduces an unquoted variable
      expansion in a `.sh` script under `.forge/scripts/`
    When the PR is opened
    Then `jobs.lint` runs `ludeeus/action-shellcheck@2.0.0` with severity warning
    And shellcheck reports the unquoted variable
    And `jobs.lint` fails
    And `jobs.summary` fails because needs.lint.result != 'success'
    And the PR is NOT mergeable

  Scenario: AC-005 — a constitution violation blocks merge
    Given a contributor opens a PR that removes the FR-GL-001 entry from
      `.forge/specs/full-stack-monorepo.md` (silent removal — Article IV
      violation)
    When the PR is opened
    Then `jobs.gates` runs `constitution-linter.sh` which detects the violation
    And `jobs.gates` fails
    And `jobs.summary` fails because needs.gates.result != 'success'
    And the PR is NOT mergeable

  Scenario: AC-006 — superseded PR run is cancelled
    Given a PR has an in-progress `forge-ci.yml` run on commit SHA `<X>`
    When the PR is force-pushed with a new commit SHA `<Y>`
    Then GitHub Actions cancels the in-progress run on `<X>` because
      `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` evaluates true
    And a new run starts on `<Y>`
    And only the run on `<Y>` reports the final status

    When the same scenario plays out on `push: main` (rapid sequential merges)
    Then the in-progress main run does NOT cancel because the conditional evaluates false
    And both runs complete independently

  Scenario: AC-007 — workflow runtime is bounded
    Given a clean PR with warm GitHub Actions cache
    When `forge-ci.yml` runs end-to-end
    Then total wall-clock time from "queued" to "summary completed" is ≤ 5 minutes
    And `jobs.summary` runs within 30 seconds after the last `needs` job completes

    Given a cold cache (cache miss on `npm ci`)
    Then total wall-clock time is ≤ 8 minutes
