# Standard — Forge's Own CI

<!-- Audit: G.1 (g1-forge-ci) -->
<!-- Scope: meta | Priority: medium -->
<!-- Triggers: forge-ci, self-ci, branch protection, dog-fooding, summary status, ludeeus, shellcheck -->

> Authoritative reference for `.github/workflows/forge-ci.yml` —
> the workflow that runs Forge's gates on every Forge PR and
> push to `main`. Distinct from `infra/ci-workflows.md` (which
> governs the four reference workflows shipped to scaffolded
> archetype projects). Audience here : Forge maintainers.
> Audience there : adopters.

## Workflow shape

`forge-ci.yml` declares **five jobs** in a single workflow file :

| Job        | Role                                                                                                |
|------------|-----------------------------------------------------------------------------------------------------|
| `harness`  | Runs the 4 shell test harnesses (`foundations.test.sh`, `scaffolder.test.sh --level 1,2`, `workflow.test.sh --level 1,2`, `delivery.test.sh`). |
| `gates`    | Runs `verify.sh` then `constitution-linter.sh` against the repo root.                                |
| `cli`      | In `cli/` : `npm ci`, `npm run lint`, `npm test`, `npm run bundle`. Node version pinned via `cli/.nvmrc`. |
| `lint`     | Runs `ludeeus/action-shellcheck@2.0.0` against `.forge/scripts/` and `bin/` (two invocations, severity: warning). |
| `summary`  | Depends on the four above, **always runs**, inspects each `needs.<job>.result` and exits non-zero if any is not `'success'`. Emits a single GitHub Actions notice annotation. |

The `summary` job is the **single required status** for branch
protection (`forge-ci / summary`). Branch protection rules
reference exactly this status — extending the gate to a 6th worker
job only requires adding an entry to `summary.needs`.

Shape constraints :

- Triggers : `pull_request` (branches: [main]) + `push` (branches:
  [main]). No other triggers.
- Permissions : top-level `contents: read` only ; no per-job
  overrides.
- Concurrency : `group: forge-ci-${{ github.ref }}` ;
  `cancel-in-progress: ${{ github.event_name == 'pull_request' }}`
  — PRs cancel superseded runs, main pushes do not.
- No `continue-on-error: true` anywhere.
- Every `uses:` reference pinned to a tag (no `@main` / `@master`
  / `@HEAD` / `:latest`).
- Workflow file ≤ 340 lines (NFR-CI-002 ; bumped 250→300 on 2026-05-12, then 300→340 on 2026-06-23 for b7-7-example's second example-tree RAG gate, to accommodate the linear growth of harness entries across T5/B.7). The budget is asserted in four harnesses (c1, g1, t5-1, t5-otel-live-run) — bump them in lock-step.

## What's intentionally different from infra/ci-workflows.md

The four reference workflows shipped by `b1-delivery` to
scaffolded archetype projects (`forge-backend.yml`,
`forge-frontend.yml`, `forge-infra.yml`, `forge-integration.yml`)
follow conventions that **don't apply to Forge itself**. The
deviations are deliberate :

| Convention in `infra/ci-workflows.md`                    | Why Forge `forge-ci.yml` deviates                                                                                                                                |
|----------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `dorny/paths-filter@v4` per-layer scoping                | Forge is a flat repo with no `backend/` / `frontend/` / `infra/` layers. Every PR potentially touches gates or harnesses. Path-filtering would always match the whole repo and add complexity for no win. |
| Per-layer split (one workflow per layer)                 | Single `forge-ci.yml` is the right grain. ADR-001 of `g1-forge-ci`.                                                                                                |
| Integration workflow on push:main + cron, never on PR    | Forge's gates are fast enough (~3 min warm) to run on every PR. No nightly-only workflow needed.                                                                  |
| `forge-backend.yml` runs `cargo *` ; `forge-frontend.yml` runs `flutter *` | Forge has no application code in `cargo` or `flutter` ; the equivalents are the 4 shell harnesses + the Vitest CLI.                                                |
| Scaffolded projects extend with project-specific E2E      | Forge does not extend its own workflow with project-specific suites — every test is part of the framework contract.                                              |

What's the same :

- Tool version pinning (every action `@<version>`, no `:latest`).
- No `continue-on-error: true`.
- Concurrency policy (PR cancel, main no-cancel).
- Minimal permissions.
- Caching strategy (lockfile-keyed for `cli/`, no caching needed
  for the harnesses since they're shell + Python only).
- Failure semantics (default short-circuiting on first failure,
  `if: always()` only on terminal aggregator steps).

## Branch protection

Forge's `main` branch MUST require the status check **`forge-ci /
summary`** to pass before merge. The maintainer configures this
manually via the GitHub UI :

1. Repository → **Settings** → **Branches** → **Branch protection
   rules** → **Add rule** for `main`.
2. Enable **Require status checks to pass before merging**.
3. Search for and select **`forge-ci / summary`**.
4. Recommended additional protections (NOT mandates) :
   - **Require linear history** — keeps the audit trail clean.
   - **Require signed commits** — supply-chain hygiene.
   - **Dismiss stale pull request approvals when new commits are
     pushed** — forces re-review on push.
   - **Restrict who can push to matching branches** — limits
     direct push access on `main`.

Branch protection is **deliberately not automated** by Forge. The
GitHub Actions workflow does NOT call the GitHub API to update
repository settings, principle of least privilege (Aegis pass).
Granting CI write access to repo settings is a strictly larger
attack surface than the manual one-time UI configuration step.

## Maintainer obligations

- Bumping `cli/.nvmrc`, the workflow's `actions/*` versions, the
  `ludeeus/action-shellcheck` version, or any other pinned
  reference in `forge-ci.yml` goes through a **dedicated Forge
  change cycle**. Never bundled with feature work.
- A new gate job (e.g. mutation testing, license scan) is added
  by extending `forge-ci.yml` AND `summary.needs` simultaneously
  — never one without the other.
- The harness `g1.test.sh` MUST be updated whenever
  `forge-ci.yml` shape changes ; the test harness is the gate's
  contract.

## See also

- `.forge/standards/infra/ci-workflows.md` — the equivalent
  authoritative reference for the four archetype workflows
  shipped to adopters.
- `.forge/changes/g1-forge-ci/design.md` — ADR-001..010
  documenting the design decisions behind this workflow.
