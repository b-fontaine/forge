# TDD Rules

## The RED-GREEN-REFACTOR Cycle

Test-Driven Development is a discipline, not an option. Every feature, every fix, every change starts with a failing test. No exceptions.

### RED — Write a Failing Test First

Before writing any production code, write a test that:
- Expresses the exact behavior you intend to implement
- Fails for the right reason (not compilation errors — actual assertion failure)
- Is readable: another engineer should understand the intent without reading the implementation

The failing test is your specification. It defines the contract. If you cannot write the test first, it means you have not yet understood the requirement. Stop. Think. Then write the test.

```
[RED] Test fails — no production code exists yet
       ↓
       The test is your design tool. Writing it reveals:
       - What the API should look like
       - What dependencies are needed
       - What edge cases exist
```

### GREEN — Write the Minimum Code to Pass

Write the simplest possible code that makes the test pass. Do not gold-plate. Do not anticipate. Do not write code that is not exercised by the current failing test.

```
[GREEN] Test passes — production code does exactly what the test requires
        ↓
        Resist the urge to write "just a bit more".
        The next test will drive the next behavior.
```

### REFACTOR — Improve Without Breaking

With the safety net of passing tests, improve the code:
- Remove duplication
- Improve naming
- Extract abstractions
- Apply SOLID principles
- Improve readability

All tests must still pass after refactoring. If a test breaks during refactoring, you changed behavior — that is not refactoring.

```
[REFACTOR] Code improved — all tests still green
            ↓
            Back to RED for the next behavior
```

The cycle is short: minutes, not hours. If a RED-GREEN-REFACTOR cycle takes more than 30 minutes, the step is too large. Decompose.

---

## The Anti-Rationalization Table

Every excuse to skip writing the test first has been heard before. Every single one is wrong.

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. Write it. |
| "I'll test after" | Tests written after pass immediately and prove nothing. Refused. |
| "The framework handles it" | The framework has bugs. Your integration has bugs. Test your code. |
| "It's just a refactor" | Refactors that break things aren't refactors. Tests catch this. |
| "Mocking is too complex" | Complex mocking = bad design. Simplify the dependency graph. |
| "It's a prototype" | Prototypes become production. Start right. |
| "TDD is too slow" | Debugging is slower. Manual testing is slower. TDD is fastest. |
| "I'll keep the test as reference" | You'll adapt it. That's testing after. Delete the code. Write test first. |
| "The deadline is tight" | Bugs blow deadlines. TDD prevents bugs. TDD saves time. |
| "It's a one-liner" | One-liners have edge cases. Test the edge cases. |
| "The compiler catches it" | Compilers check types, not business logic. Test the logic. |
| "TDD is dogmatic" | TDD IS pragmatic. "Pragmatic shortcuts" = debug in production = slower. |

---

## Coverage Rules

- **Minimum: 80% line coverage, measured, not estimated**
- Domain layer: 100%. No exceptions. Domain logic is the heart of the application.
- Use cases / application services: 100%.
- Data layer: ≥90% (repositories, mappers, data sources).
- Presentation layer: ≥80% (BLoC/Cubit states and transitions, widget smoke tests).
- Infrastructure adapters: ≥70% (integration tests preferred over unit tests).

Coverage is a floor, not a target. If the domain is fully covered and the overall number is below 80%, fix it. If you are at 80% with untested domain logic, fix it.

Coverage is measured in CI. PRs that drop coverage below threshold are blocked.

---

## Flutter Testing

### Tools

| Tool | Purpose |
|------|---------|
| `flutter_test` | Core test framework — unit + widget tests |
| `bdd_widget_test` | BDD-style widget tests with Gherkin feature files |
| `mocktail` | Mocking — preferred over mockito (no codegen) |
| `bloc_test` | BLoC/Cubit state transition testing |
| `golden_toolkit` | Golden image regression tests |

### Unit Test — Use Case

```dart
// test/features/auth/domain/usecases/sign_in_use_case_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInUseCase useCase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    useCase = SignInUseCase(repository);
  });

  group('SignInUseCase', () {
    const email = 'user@example.com';
    const password = 'secure_password';
    final params = SignInParams(email: email, password: password);

    test('returns User on successful sign in', () async {
      // Arrange
      final user = User(id: '1', email: email);
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => Right(user));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, Right(user));
      verify(() => repository.signIn(email: email, password: password))
          .called(1);
    });

    test('returns Failure when credentials are invalid', () async {
      // Arrange
      when(() => repository.signIn(email: email, password: password))
          .thenAnswer((_) async => Left(AuthFailure.invalidCredentials()));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, isA<Left<Failure, User>>());
    });
  });
}
```

### BLoC Test

```dart
// test/features/auth/presentation/bloc/auth_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}

void main() {
  late AuthBloc bloc;
  late MockSignInUseCase signIn;

  setUp(() {
    signIn = MockSignInUseCase();
    bloc = AuthBloc(signIn: signIn);
  });

  tearDown(() => bloc.close());

  group('AuthBloc - SignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] on success',
      build: () {
        when(() => signIn(any()))
            .thenAnswer((_) async => Right(fakeUser));
        return bloc;
      },
      act: (bloc) => bloc.add(
        SignInRequested(email: 'user@example.com', password: 'password'),
      ),
      expect: () => [
        const AuthState.loading(),
        AuthState.authenticated(user: fakeUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] on failure',
      build: () {
        when(() => signIn(any()))
            .thenAnswer((_) async => Left(AuthFailure.invalidCredentials()));
        return bloc;
      },
      act: (bloc) => bloc.add(
        SignInRequested(email: 'bad@example.com', password: 'wrong'),
      ),
      expect: () => [
        const AuthState.loading(),
        isA<AuthStateError>(),
      ],
    );
  });
}
```

### Widget Test

```dart
// test/features/auth/presentation/widgets/sign_in_form_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthState.initial());
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const SignInPage(),
      ),
    );
  }

  testWidgets('renders email and password fields', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.byKey(const Key('signIn_emailField')), findsOneWidget);
    expect(find.byKey(const Key('signIn_passwordField')), findsOneWidget);
    expect(find.byKey(const Key('signIn_submitButton')), findsOneWidget);
  });

  testWidgets('dispatches SignInRequested on submit', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.enterText(
      find.byKey(const Key('signIn_emailField')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signIn_passwordField')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('signIn_submitButton')));

    verify(() => authBloc.add(
      SignInRequested(email: 'user@example.com', password: 'password123'),
    )).called(1);
  });
}
```

### BDD Widget Test

```gherkin
# test/features/auth/sign_in.feature

Feature: Sign In
  As a user
  I want to sign in with my credentials
  So that I can access my account

  Scenario: Successful sign in
    Given I am on the sign in page
    When I enter "user@example.com" as email
    And I enter "secure_password" as password
    And I tap the sign in button
    Then I see the home page

  Scenario: Invalid credentials
    Given I am on the sign in page
    When I enter "bad@example.com" as email
    And I enter "wrong" as password
    And I tap the sign in button
    Then I see an error message "Invalid credentials"
```

---

## Rust Testing

### Tools

| Tool | Purpose |
|------|---------|
| `#[test]` / `cargo test` | Core unit testing |
| `cucumber-rs` | BDD acceptance tests |
| `proptest` | Property-based testing |
| `mockall` | Mock trait implementations |
| `cargo tarpaulin` | Coverage measurement |
| `cargo nextest` | Faster test runner |

### Unit Test

```rust
// src/domain/use_cases/create_order.rs

#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;
    use crate::domain::repositories::MockOrderRepository;

    #[tokio::test]
    async fn creates_order_successfully() {
        // Arrange
        let mut repo = MockOrderRepository::new();
        repo.expect_save()
            .with(predicate::always())
            .times(1)
            .returning(|order| Ok(order.clone()));

        let use_case = CreateOrderUseCase::new(Arc::new(repo));
        let command = CreateOrderCommand {
            customer_id: CustomerId::new("cust-1"),
            items: vec![OrderItem::new(ProductId::new("prod-1"), Quantity::new(2))],
        };

        // Act
        let result = use_case.execute(command).await;

        // Assert
        assert!(result.is_ok());
        let order = result.unwrap();
        assert_eq!(order.customer_id().value(), "cust-1");
        assert_eq!(order.items().len(), 1);
    }

    #[tokio::test]
    async fn returns_error_when_items_empty() {
        let mut repo = MockOrderRepository::new();
        repo.expect_save().times(0); // Must not be called

        let use_case = CreateOrderUseCase::new(Arc::new(repo));
        let command = CreateOrderCommand {
            customer_id: CustomerId::new("cust-1"),
            items: vec![],
        };

        let result = use_case.execute(command).await;

        assert!(matches!(result, Err(DomainError::EmptyOrder)));
    }
}
```

### Property-Based Test

```rust
// src/domain/value_objects/email.rs

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn valid_email_always_parses(
            local in "[a-z]{1,20}",
            domain in "[a-z]{1,10}",
        ) {
            let email_str = format!("{local}@{domain}.com");
            let result = Email::new(&email_str);
            prop_assert!(result.is_ok(), "Expected Ok for {email_str}");
        }

        #[test]
        fn email_without_at_always_fails(s in "[a-zA-Z0-9]{1,50}") {
            // Ensure no '@' in the string
            let s = s.replace('@', "X");
            let result = Email::new(&s);
            prop_assert!(result.is_err());
        }
    }

    #[test]
    fn email_is_normalized_to_lowercase() {
        let email = Email::new("User@Example.COM").unwrap();
        assert_eq!(email.value(), "user@example.com");
    }
}
```

### Measuring Coverage

```bash
# Install tarpaulin
cargo install cargo-tarpaulin

# Run with coverage, excluding test files
cargo tarpaulin \
  --exclude-files "src/main.rs" \
  --exclude-files "*/tests/*" \
  --out Html \
  --output-dir target/coverage \
  --timeout 120

# Fail if below 80%
cargo tarpaulin --fail-under 80
```

```bash
# Using nextest for faster parallel execution
cargo install cargo-nextest
cargo nextest run --all-features
```
