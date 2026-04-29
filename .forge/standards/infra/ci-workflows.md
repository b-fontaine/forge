# Standard — CI Workflows (Reference)

<!-- Audit: B.1.9 (b1-delivery, FR-IN-010) -->
<!-- Scope: infra | Priority: high -->
<!-- Triggers: ci, github actions, workflow, paths-filter, dorny, gate, integration, nightly -->

> Authoritative reference for the four GitHub Actions workflows
> shipped by the `full-stack-monorepo` archetype. Templates live
> under `.forge/templates/archetypes/full-stack-monorepo/.github/workflows/`
> and are scaffolded into a project's `.github/workflows/`. This
> standard is the contract those templates materialise.

## Per-layer paths filter

Three of the four reference workflows are **per-layer** :

| Workflow                | Trigger paths                              |
|-------------------------|--------------------------------------------|
| `forge-backend.yml`     | `backend/**` OR `shared/protos/**`         |
| `forge-frontend.yml`    | `frontend/**` OR `shared/protos/**`        |
| `forge-infra.yml`       | `infra/**`                                 |

Filtering is implemented with **`dorny/paths-filter@v3`** (ADR-002).
The native GitHub `on.<event>.paths` mechanism is rejected because
it skips the workflow entirely (no required-status appears for
branch-protection rules) ; with `dorny/paths-filter`, the workflow
**always runs** but jobs gated by the filter output skip with
SUCCESS, satisfying branch protection while keeping CI cheap.

The integration workflow (`forge-integration.yml`) is **not**
filtered — it runs the full stack regardless of touched paths.

## Gate ordering

Inside each per-layer workflow, steps run in this **non-negotiable**
order :

1. **Language-specific format check** — `cargo fmt --check`,
   `dart format --set-exit-if-changed`, etc. Fail fast on cosmetic
   diffs before burning CPU on heavier checks.
2. **Static analysis** — `cargo clippy -- -D warnings`,
   `flutter analyze --fatal-infos --fatal-warnings`. Zero
   tolerance for warnings (Article X).
3. **Unit + integration tests** — `cargo test --workspace`,
   `flutter test`, etc.
4. **Forge gates** — `bash .forge/scripts/verify.sh` followed
   by `bash .forge/scripts/constitution-linter.sh`. Run last
   so they validate against the post-test state, and never
   short-circuit a missing language check.

The infra workflow swaps step 3 for `kustomize build` × 3 overlays
piped through `kubeconform --strict`.

## Integration workflow scope

`forge-integration.yml` is the cross-layer end-to-end gate. Strict
scoping rules :

- **Triggers**: `push` to `main`, nightly cron (`'0 3 * * *'` UTC),
  `workflow_dispatch`. NEVER `pull_request` — the workflow's 30-min
  budget (NFR-014) would bottleneck PR turnaround.
- **Body**: `docker compose up -d --wait` (ADR-012) → backend
  integration tests against the live stack →
  Patrol Android E2E → teardown gated on `if: always()`.
- **Failure handling**: opt-in issue comment via the
  `FORGE_INTEGRATION_TRACKING_ISSUE` secret. Off by default.

A scaffolded project may extend the integration workflow with
project-specific E2E suites — but MUST NOT lower the
`timeout-minutes: 35` ceiling (NFR-014).

## Concurrency policy

Every reference workflow declares :

```yaml
concurrency:
  group: forge-<layer>-<project-name>-${{ github.ref }}
  cancel-in-progress: true   # per-layer
  cancel-in-progress: false  # integration only
```

Per-layer workflows cancel superseded runs on the same ref —
saves cache + CPU. The integration workflow does NOT cancel
in-progress nightlies when a new push:main lands — partial
nightly results are valuable and the next push will re-trigger
naturally.

## Caching strategy

Per-language caches keyed on lockfile hashes (ADR-011) :

| Layer    | Cache paths                                         | Cache key                                           |
|----------|-----------------------------------------------------|-----------------------------------------------------|
| Backend  | `~/.cargo/registry`, `~/.cargo/git`, `backend/target` | `${{ runner.os }}-cargo-${{ hashFiles('backend/Cargo.lock') }}` |
| Frontend | `~/.pub-cache`                                       | `${{ runner.os }}-pub-${{ hashFiles('frontend/pubspec.lock') }}` |
| Infra    | none — `kustomize` and `kubeconform` are static binaries downloaded fresh (~2s overhead) | n/a |

Cache hit on PRs that don't touch the lockfile satisfies NFR-013
(per-layer warm-cache runtime ≤ 8 min).

## Tool version pinning

All third-party actions and CLI tools used by the reference
workflows are **pinned** (ADR-008) :

| Tool                  | Pinned version reference                                |
|-----------------------|---------------------------------------------------------|
| dorny/paths-filter    | `@v3`                                                   |
| dtolnay/rust-toolchain | `@stable` (rolling, but the action is pinned to v1)     |
| subosito/flutter-action | `@v2` + `flutter-version-file: .flutter-version`     |
| imranismail/setup-kustomize | `@v2`, version `5.4.2`                            |
| kubeconform           | `0.6.7` via upstream tarball                            |
| reactivecircus/android-emulator-runner | `@v2`, API level 34                    |
| actions/checkout      | `@v4`                                                   |
| actions/cache         | `@v4`                                                   |

Bumps go through a normal Forge change cycle — never auto-merged.

## Failure semantics

- **`continue-on-error: true` is FORBIDDEN** anywhere in the
  reference workflows. Failures must surface, never silently
  pass. The harness `delivery.test.sh` enforces this with a regex
  guard.
- **`if: always()`** is permitted ONLY for teardown steps in the
  integration workflow (e.g. `docker compose down -v`). Otherwise,
  default short-circuiting on first failure stays in effect.
- A scaffolded project that needs to allow a flaky check MUST
  document the deviation in its own `docs/CI-EXCEPTIONS.md` and
  cite a Forge change that approved it.

## Extending the reference workflows

Adopters MAY extend a reference workflow with additional steps
**before** the Forge gates (steps 1-3 above). Adding steps **after**
`constitution-linter.sh` is forbidden — the linter is the last
word.

A project's deviation budget : at most 2 additional steps per
workflow before the Forge gates. Above that, write a Forge change
proposing the new step as a constitutional commitment.
