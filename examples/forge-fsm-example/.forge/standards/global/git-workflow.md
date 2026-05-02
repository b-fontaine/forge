# Git Workflow

## Branch Strategy

### Permanent Branches

| Branch | Purpose | Who merges |
|--------|---------|-----------|
| `main` | Production-ready code. Always deployable. | CI/CD only via PR |
| `develop` | Integration branch. Staging environment. | PR from feature branches |

### Working Branches

All working branches branch from `develop` (or `main` for hotfixes) and merge back via PR.

```
main ─────────────────────────────────────────────────── production
        ↑ PR (release)
develop ──────────────────────────────────────────────── staging
    ↑ PR       ↑ PR          ↑ PR
  feat/A     fix/B        feat/C
```

### Branch Naming

Format: `type/short-description-in-kebab-case`

```bash
# Features
git checkout -b feat/user-authentication develop
git checkout -b feat/product-search-filters develop
git checkout -b feat/stripe-payment-integration develop

# Bug fixes
git checkout -b fix/cart-total-rounding-error develop
git checkout -b fix/auth-token-refresh-race-condition develop

# Hotfixes (branch from main, merge to both main AND develop)
git checkout -b hotfix/critical-auth-bypass main

# Refactors
git checkout -b refactor/order-aggregate-cleanup develop

# Chores
git checkout -b chore/upgrade-flutter-3-22 develop
git checkout -b chore/update-ci-pipeline develop

# Tests
git checkout -b test/order-bdd-scenarios develop

# Documentation
git checkout -b docs/api-authentication-guide develop

# Performance
git checkout -b perf/product-list-lazy-loading develop
```

---

## Conventional Commits

Every commit message follows the Conventional Commits specification. No exceptions.

### Format

```
type(scope): description

[optional body — blank line separator]

[optional footer(s)]
```

### Types

| Type | When to use |
|------|------------|
| `feat` | New feature visible to the user or API consumer |
| `fix` | Bug fix |
| `refactor` | Code change with no behavior change, no bug fix |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Build system, dependencies, CI, tooling |
| `perf` | Performance improvement |
| `style` | Formatting, lint fixes, no logic change |
| `revert` | Reverts a previous commit |
| `build` | Changes affecting the build system |
| `ci` | CI configuration changes |

### Scope

Optional. Use the feature name or module. Lowercase, no spaces.

```
feat(auth): ...
fix(cart): ...
refactor(order): ...
chore(deps): ...
```

### Description Rules

- Lowercase first letter
- Imperative mood: "add", "fix", "change" — not "added", "fixing", "changes"
- No period at the end
- 72 characters maximum
- Describes WHAT, not HOW

### Body Rules

- Separated from subject by a blank line
- Explains WHY, not what (the diff shows what)
- Wrap at 72 characters
- Use bullet points for multiple points

### Examples

```bash
# Simple feature
git commit -m "feat(auth): add sign in with Apple"

# Bug fix with context
git commit -m "fix(cart): correct total when multiple discounts applied

Previous implementation summed discount amounts before applying,
causing over-discounting when two percentage discounts combined.
Now applies discounts sequentially as designed in spec FORGE-201."

# Breaking change
git commit -m "feat(order)!: change order ID type from integer to UUID

BREAKING CHANGE: OrderId is now a UUID string.
Consumers must update API calls and database queries.
Migration script: scripts/migrate_order_ids.sh

Closes FORGE-142"

# Dependency update
git commit -m "chore(deps): upgrade flutter to 3.22.0 and dart to 3.4.0"

# Test addition
git commit -m "test(auth): add BDD scenarios for biometric sign in"

# Refactor
git commit -m "refactor(domain): extract Money value object from Order entity"

# Performance
git commit -m "perf(products): add cursor-based pagination to product list

Reduces p95 latency from 800ms to 45ms on lists > 1000 items."
```

---

## Pull Request Rules

### Before Opening a PR

1. Branch is up to date with `develop`
2. All tests pass locally
3. Coverage has not decreased
4. No uncommitted changes
5. Commit history is clean (squash WIP commits)

```bash
# Update branch before PR
git fetch origin
git rebase origin/develop

# Verify tests
flutter test --coverage
# or
cargo nextest run --all-features

# Check coverage
flutter pub run dart_coverage --min-coverage 80
# or
cargo tarpaulin --fail-under 80
```

### PR Structure

**Title**: Must follow Conventional Commits format.

```
feat(auth): add sign in with Apple
fix(cart): correct total when multiple discounts applied
```

**Description** must include:

```markdown
## What

Brief description of what changed.

## Why

The business reason for this change.

## How

Key implementation decisions, architecture choices, trade-offs.

## Testing

- [ ] Unit tests added/updated
- [ ] Widget tests added/updated (if UI changes)
- [ ] BDD scenarios added/updated (if behavior changes)
- [ ] Golden tests updated (if UI changes)
- [ ] Integration tests pass

## Screenshots / Recordings

(For UI changes — before and after)

## Checklist

- [ ] Tests pass
- [ ] Coverage maintained (≥80%)
- [ ] No new lint warnings
- [ ] Domain layer has no external dependencies
- [ ] BLoC has no UI imports
- [ ] API is documented (if public)
```

### PR Size

- Aim for PRs under 400 lines of change.
- Large PRs are split into a stack: PR-1 (domain) → PR-2 (data) → PR-3 (presentation).
- Each PR in a stack is independently reviewable and mergeable.

### Review Process

- Minimum 1 approving review before merge
- CI must pass (tests, coverage, lint, build)
- No `console.log`, `print`, `dbg!` left in production code
- Author resolves all review comments or discusses before merging
- Squash merge into `develop` (keeps history clean)

---

## Forge Integration

### Branch Per Change

Forge creates one branch per task. Task ID is embedded in the branch name when working with Forge-managed tasks.

```bash
# Forge-generated branch names
feat/FORGE-142-order-uuid-migration
fix/FORGE-201-cart-discount-stacking
test/FORGE-89-biometric-auth-bdd
```

### Commits Reference Task IDs

Every commit in a Forge task references the task ID in the footer.

```bash
git commit -m "feat(auth): implement biometric sign in

Adds FaceID and TouchID support via local_auth package.
Falls back gracefully to PIN on unsupported devices.

Implements FORGE-89"
```

### Automated Checks

Forge CI enforces:

```yaml
# .forge/ci/checks.yml
checks:
  - name: conventional-commits
    tool: commitlint
    config: .commitlintrc.yml

  - name: test-coverage
    minimum: 80
    domain-minimum: 100

  - name: lint
    flutter: flutter analyze --fatal-warnings
    rust: cargo clippy -- -D warnings

  - name: format
    flutter: dart format --set-exit-if-changed .
    rust: cargo fmt --check

  - name: build
    flutter: flutter build apk --debug
    rust: cargo build --all-features
```

---

## Scoped Conventional Commits (monorepo-only)

This section applies ONLY when the project's root `.forge.yaml` declares `schema: full-stack-monorepo`. For any other schema value (`default`, `tdd-flutter`, `tdd-rust`, `rapid`, `ai-first`), commits follow the standard Conventional Commits rules documented earlier in this file — free-form scopes are allowed and the scope field remains optional. When `schema: full-stack-monorepo` is active, scopes become a **closed list** enforced at commit time: any scope not in the list MUST be rejected. This enforcement is delivered by the pre-commit hook specified in the `b1-delivery` change (audit module G.2).

### Closed Scope List

The following and ONLY the following scopes are valid in monorepo mode:

```text
{backend, frontend, infra, protos, forge, docs, ci}
```

Any scope outside this list SHALL cause the pre-commit hook to abort the commit with an explicit error message. The hook reads the scope token from the commit message header and performs an exact membership test against the list above.

### Per-Scope Semantics

Each scope maps to a well-defined layer of the repository:

- `backend` — changes under `backend/` (Rust workspace crates, unit/integration tests, `Cargo.toml`, build configuration)
- `frontend` — changes under `frontend/` (Flutter `lib/`, `test/`, `pubspec.yaml`, asset files, generated code under `frontend/`)
- `infra` — changes under `infra/` (Kong gateway config, Kubernetes manifests, Temporal workflow workers, Docker Compose files, Terraform modules)
- `protos` — changes under `shared/protos/` (`.proto` definitions, `buf.yaml`, `buf.gen.yaml`, generated stubs committed to the repo)
- `forge` — changes to `.forge/` or `.claude/` (framework standards, change specs, skills, constitution, CI check configs owned by Forge)
- `docs` — changes under `docs/`, or to repo-root files `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`
- `ci` — changes under `.github/workflows/`, or to CI-adjacent files: `Taskfile.yml`, `Dockerfile*`, `.dockerignore`, `Makefile`

### Examples

#### `backend`

- ✅ `feat(backend): add gRPC reflection endpoint`
- ✅ `fix(backend): retry on transient DB connection failures`
- ❌ `feat: add backend reflection endpoint` — bare `feat:` without scope is rejected by the hook in monorepo mode.

#### `frontend`

- ✅ `feat(frontend): add biometric sign-in screen`
- ✅ `fix(frontend): correct cart total display when discount applied`
- ❌ `feat(ui): add biometric sign-in screen` — `ui` is not in the closed list; use `frontend` and describe the layer in the subject.

#### `infra`

- ✅ `chore(infra): add Kong rate-limit plugin for payment routes`
- ✅ `fix(infra): correct Temporal worker replica count in staging manifest`
- ❌ `chore(k8s): add Kong rate-limit plugin` — `k8s` is not a valid scope; use `infra`.

#### `protos`

- ✅ `feat(protos): add OrderService.Cancel RPC definition`
- ✅ `fix(protos): correct field number collision in PaymentEvent`
- ❌ `feat(grpc): add OrderService.Cancel RPC` — `grpc` is not a valid scope; use `protos`.

#### `forge`

- ✅ `chore(forge): update TDD standard to require mutation testing`
- ✅ `docs(forge): add b1-delivery change spec`
- ❌ `chore(.forge): update TDD standard` — `.forge` with a leading dot is not a valid scope token; use `forge`.

#### `docs`

- ✅ `docs(docs): document gRPC authentication flow`
- ✅ `docs(docs): add CONTRIBUTING guide for external contributors`
- ❌ `docs: update contributing guide` — bare `docs:` without scope is rejected by the hook in monorepo mode.

#### `ci`

- ✅ `ci(ci): add Rust coverage step to pull-request workflow`
- ✅ `fix(ci): pin flutter-action to v3.10.5 to avoid upstream breakage`
- ❌ `chore(github-actions): add Rust coverage step` — `github-actions` is not a valid scope; use `ci`.

### Anti-Patterns

The following patterns MUST NOT appear in monorepo commits and SHALL be rejected by the pre-commit hook or blocked in code review:

- **Free-form domain scopes** such as `feat(payment): ...`, `feat(auth): ...`, `fix(user): ...` are REJECTED. The scope MUST identify the architectural layer, not the business domain. Move the domain context into the subject line: `feat(backend): add payment service`, `fix(backend): resolve auth token refresh race condition`.

- **Multi-scope commits** such as `feat(backend,frontend): ...` or `feat(backend+infra): ...` are REJECTED. If a change genuinely spans two layers, it MUST be split into two separate commits that share the same PR. Each commit carries exactly one scope token.

- **Cross-layer refactors** that touch `backend/`, `frontend/`, AND `infra/` simultaneously present a special case: use scope `forge` ONLY if the change is a framework-level concern (e.g., updating a shared code-generation config that affects all layers). Otherwise the refactor MUST be split into per-layer commits. Scope `forge` SHALL NOT be used as a catch-all for large multi-layer changes.

- **Missing scope** in monorepo mode — a bare `feat:` or `fix:` commit (with no parenthetical scope) is REJECTED. Every commit in monorepo mode MUST carry one of the seven approved scope tokens.

### Cross-References

The pre-commit hook that enforces the closed scope list is specified and delivered in the **`b1-delivery`** change, audit module G.2. That hook reads the first line of the commit message, extracts the scope token between parentheses, and rejects any value not present in `{backend, frontend, infra, protos, forge, docs, ci}`.

Scope tokens align with the FR-ID prefix convention defined in `.forge/standards/global/monorepo-layout.md`: `FR-BE-` (backend), `FR-FE-` (frontend), `FR-IN-` (infra), `FR-GL-` (global/forge). When filing a change spec or referencing a requirement, use the matching FR-ID prefix for the layer touched by the commit.
