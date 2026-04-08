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
