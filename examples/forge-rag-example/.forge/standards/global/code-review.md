# Code Review Checklist

Code review is a quality gate, not a ceremony. Every item on this checklist is a real failure mode that has reached production in real systems. Check them because they matter.

---

## How to Review

1. **Read the PR description first.** Understand the why before the how.
2. **Review the tests first.** Tests are the specification. If the tests are wrong, the code is wrong.
3. **Trace the data flow.** From the triggering event to the final output.
4. **Look for what is missing.** Error paths, edge cases, missing tests, missing accessibility.
5. **Comment with intent.** Is this a blocking issue? A suggestion? A question? Say so.

Comment prefixes:
- `[blocking]` — Must be fixed before merge
- `[suggestion]` — Worth considering, not mandatory
- `[question]` — Seeking understanding, not necessarily a problem
- `[nit]` — Minor style preference, non-blocking

---

## Architecture

### Layer Integrity

- [ ] **Domain layer has zero external dependencies.** No Flutter imports, no Dio, no Hive, no JSON codegen in `domain/`.
- [ ] **Use cases depend on interfaces, not implementations.** `AuthRepository` not `AuthRepositoryImpl`.
- [ ] **Data layer does not import from presentation.** No BLoC imports in repositories or data sources.
- [ ] **Presentation accesses domain through use cases only.** BLoC calls use cases, not repositories.
- [ ] **Features do not import from each other.** Cross-feature navigation uses the router. Shared logic lives in `core/` or `shared/`.
- [ ] **New dependencies are intentional.** Check `pubspec.yaml` / `Cargo.toml` diff. Is this dependency necessary? Actively maintained? License compatible?

### Patterns

- [ ] **SRP respected.** Each class has one reason to change.
- [ ] **No business logic in widgets or controllers.** Business rules belong in entities or use cases.
- [ ] **Repository pattern used correctly.** Repositories return domain entities, not JSON maps or database models.
- [ ] **Aggregates enforce their invariants.** No external code bypasses aggregate methods to mutate state.
- [ ] **Value objects are immutable and self-validating.** Construction fails on invalid input — it does not return null.
- [ ] **Domain events named in past tense.** `OrderConfirmed`, not `ConfirmOrder`.

### Dependency Injection

- [ ] **Concrete types are not constructed inside domain/application code.** Use injection.
- [ ] **No service locator pattern in domain or data layers.** `GetIt.instance.get<X>()` belongs only in the DI module or widget tree.
- [ ] **BLoC is provided at the correct scope.** Feature-scoped BLoC lives on the feature's page widget, not in `main.dart`.

---

## Quality

### Tests

- [ ] **Every new behavior has a test.** If a use case was added, its happy path and error paths are tested.
- [ ] **Tests are in the right layer.** Domain logic → unit test. BLoC → bloc_test. Widget → widget test. User flow → BDD scenario.
- [ ] **Tests test behavior, not implementation.** Tests do not assert on private fields or call private methods.
- [ ] **Mocks are reset between tests.** `setUp` creates fresh mocks. No shared mutable mock state.
- [ ] **BDD scenarios cover the new feature.** If a new user-facing behavior was added, a Gherkin scenario exists.
- [ ] **Golden tests updated** when UI changes. Not just deleted.

### Coverage

- [ ] **Overall coverage has not decreased.**
- [ ] **Domain layer is at 100%.** Any gap is a blocking issue.
- [ ] **Error paths are tested**, not just the happy path.

### Code Quality

- [ ] **No compiler warnings.** `flutter analyze --fatal-warnings` passes. `cargo clippy -- -D warnings` passes.
- [ ] **No `print`, `debugPrint` (unless gated), `dbg!` in production code.** Logging uses the structured logger.
- [ ] **No `TODO` comments without a task reference.** `// TODO(FORGE-123): fix this` is acceptable. `// TODO: fix this later` is not.
- [ ] **No dead code.** Unused imports, variables, and functions are removed.
- [ ] **No force-unwrap in Rust without justification.** `unwrap()` and `expect()` in non-test code require a comment explaining why the value is guaranteed to be `Some`/`Ok`.
- [ ] **No `!` (bang) operator in Dart without justification.** Non-null assertions that can fail at runtime require a comment.

### Documentation

- [ ] **Public API is documented.** Public functions, classes, and traits have doc comments.
- [ ] **Ubiquitous language is used.** Names match the domain glossary.
- [ ] **Complex algorithms have explanatory comments.** The comment explains WHY, not WHAT (the code shows what).

---

## Accessibility

- [ ] **Interactive widgets have Semantics labels.** Buttons, icons, images, and custom controls are wrapped with `Semantics` or use `semanticLabel`.
- [ ] **Color is not the only differentiator.** Error states, status indicators, and interactive states are also communicated through shape, text, or icon — not just color.
- [ ] **Contrast ratio meets WCAG AA.** Text on background: 4.5:1 minimum. Large text (18pt+ or 14pt bold): 3:1 minimum.
- [ ] **Touch targets meet minimum size.** 44×44 logical pixels minimum. Use `SizedBox` or `ConstrainedBox` to enforce.
- [ ] **Focus traversal is logical.** Tab order follows reading order. `FocusTraversalGroup` used when default order is wrong.
- [ ] **Text scales correctly.** Test at 200% font scale. No overflow. No truncation of critical content.
- [ ] **Screen reader flow makes sense.** Read the Semantics tree. Does it tell a coherent story?

---

## Performance

### Widget Layer

- [ ] **`const` constructors used wherever possible.** `const Text('...')`, `const SizedBox(...)`, `const Padding(...)`.
- [ ] **Widgets that don't need to rebuild are not rebuilding.** `BlocSelector` instead of `BlocBuilder` when only a slice of state is needed.
- [ ] **`ListView.builder` used for long lists**, not `Column` with mapped children.
- [ ] **`CachedNetworkImage` used for remote images**, not `Image.network`.
- [ ] **`RepaintBoundary` used to isolate expensive subtrees.** Animations, maps, video players.

### I/O

- [ ] **No I/O on the main thread for heavy work.** `compute()` or `Isolate.spawn()` for CPU-intensive work.
- [ ] **Debounce on search/filter inputs.** No API call on every keystroke.
- [ ] **Pagination implemented for lists.** No "load all" queries.
- [ ] **Repository results are cached where appropriate.** Repeat reads of stable data do not hit the network.

### Startup

- [ ] **Feature modules are lazy-loaded (web).** Deferred imports for non-critical features.
- [ ] **`@lazySingleton` used for services that are not always needed.**
- [ ] **No synchronous I/O at startup.** Database connections, file reads, and network calls are async.

---

## Security

### Secrets and Sensitive Data

- [ ] **No secrets in code or comments.** API keys, tokens, passwords, private keys — none in source.
- [ ] **Sensitive data uses `FlutterSecureStorage`**, not `SharedPreferences`.
- [ ] **Secrets injected via environment variables or CI secrets**, not committed to repository.
- [ ] **No PII logged.** Email addresses, names, phone numbers, and IDs are not in log output.

### Input Validation

- [ ] **All user input is validated at the domain boundary.** Value objects reject invalid input. Use cases validate commands.
- [ ] **SQL / NoSQL injection prevented.** Parameterized queries or ORMs with safe query builders. No string interpolation in queries.
- [ ] **No `eval` equivalent.** User input is never executed as code.
- [ ] **File upload type and size validated.** Extension allowlisting, not blocklisting. Size limit enforced.

### Authentication and Authorization

- [ ] **Auth state checked before accessing protected resources.** Route guards enforce authentication.
- [ ] **Token storage is secure.** JWTs stored in `FlutterSecureStorage`, never in `SharedPreferences` or local storage (web).
- [ ] **Token refresh is implemented correctly.** Expired tokens trigger refresh, not silent failure.
- [ ] **Authorization is enforced server-side.** Client-side checks are UX only — the backend enforces access control.

### Transport

- [ ] **All API calls use HTTPS.** No `http://` in production configuration.
- [ ] **Certificate pinning implemented for high-value endpoints** (if applicable).
- [ ] **No sensitive data in URL query parameters.** Use request body or headers.

---

## Reviewer Sign-Off

All blocking items are resolved before approval. Non-blocking items (suggestions, nits, questions) may be resolved after merge at the author's discretion.

A PR with unresolved blocking issues should not be merged even with an approving review.
