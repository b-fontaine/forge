# Standard: Test Strategy

## Scope
Test architecture decisions: test pyramid ratios, mutation testing, flaky test management, test data, contract testing, performance testing. Applies to all projects with production code.

## Rules

### Test Pyramid
- **Flutter**: 70% unit / 20% widget / 8% integration / 2% E2E
- **Rust**: 70% unit / 20% integration / 8% contract / 2% E2E
- Ratio violations are flagged in reviews but not blocking. Trends matter more than snapshots.

### Mutation Testing
- Mandatory on domain layer (>70% mutation kill rate)
- Flutter: `mutation_test` package
- Rust: `cargo-mutants`
- Run in CI on critical paths, not on every PR (too slow)

### Flaky Tests
- Detection: run suite 3x, flag intermittent failures
- Quarantine: tag + move to quarantine directory + open issue
- Fix within 2 sprints or delete with documented justification
- Never remove without investigation

### Test Data
- Deterministic: no `Random()`, no `DateTime.now()` without seeding
- No production data in tests
- No hardcoded IDs that could collide
- Use builder/factory pattern for test objects

### Contract Testing
- Consumer-driven: Flutter defines expectations, Rust verifies
- REST: Pact contracts
- gRPC: `buf breaking` for proto compatibility
- Run on both consumer and provider PRs

### Coverage
- Minimum 80% overall (Article X.1)
- Domain layer: target 100%
- Measure line coverage at minimum; branch coverage recommended

## Anti-patterns
- **Tests coupled to implementation**: testing private methods, asserting on internal state. Test behavior, not structure.
- **Tests that pass when code is deleted**: the test doesn't exercise the behavior. Write meaningful assertions.
- **Shared mutable state between tests**: tests depend on execution order. Isolate test state.
- **Testing the framework**: verifying Flutter renders a `Text` widget. Test your logic, not the framework.
- **Mocking everything**: mock only external boundaries (DB, HTTP, time). Don't mock domain collaborators.
- **Tests with no assertions**: runs code but never checks results. Every test must assert something.
- **Auto-generated golden baselines never reviewed**: golden tests only catch regressions if baselines are intentional.
