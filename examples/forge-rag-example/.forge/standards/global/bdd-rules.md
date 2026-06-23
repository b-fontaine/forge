# BDD Rules

## What BDD Is

Behavior-Driven Development bridges the gap between business requirements and executable tests. A scenario written in Gherkin is simultaneously:
- A specification that a product owner can read and validate
- An acceptance test that a CI pipeline executes
- Living documentation that reflects the current state of the system

If a scenario cannot be read by a non-technical stakeholder, it is written wrong.

---

## Gherkin Format

### Structure

```gherkin
Feature: <one-line description of the feature>
  <optional free-text description — the "As a / I want / So that" narrative>

  Background:
    <steps that run before every scenario in this feature>

  @tag1 @tag2
  Scenario: <concrete example of one behavior>
    Given <precondition — the world is in this state>
    When <action — the actor does something>
    Then <outcome — observable result>
    And <additional outcome>

  Scenario Outline: <parameterized behavior>
    Given I have <count> items in the cart
    When I apply discount "<code>"
    Then the total is "<total>"

    Examples:
      | count | code       | total  |
      | 1     | SAVE10     | $9.00  |
      | 3     | SAVE10     | $27.00 |
      | 0     | SAVE10     | error  |
```

### Rules

1. **Feature file = one feature**. Do not bundle unrelated behaviors.
2. **Scenario = one behavior**. One When, one observable outcome.
3. **Steps are declarative, not imperative**. "I sign in" not "I click the email field, type X, click the password field, type Y, click submit".
4. **No implementation details in steps**. Steps describe intent, not mechanism.
5. **Background for shared preconditions only**. If fewer than two scenarios share a precondition, inline it.
6. **Scenario Outline for data variation**. Never copy-paste scenarios with different data.
7. **Tags for organization**: `@smoke`, `@regression`, `@wip`, `@slow`.
8. **Scenarios are independent**. Any scenario can run in any order. No shared mutable state between scenarios.

### Good vs Bad

```gherkin
# BAD — implementation details, imperative style
Scenario: User logs in
  Given I open the app
  When I tap the email text field
  And I type "user@example.com"
  And I tap the password text field
  And I type "password123"
  And I tap the button with label "Sign In"
  Then the home screen is visible

# GOOD — declarative, business-readable
Scenario: Authenticated user sees their dashboard
  Given I am a registered user with email "user@example.com"
  When I sign in with valid credentials
  Then I see my personal dashboard
```

---

## Flutter BDD with bdd_widget_test

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bdd_widget_test: ^1.6.0
  mocktail: ^1.0.0
```

### Directory Structure

```
test/
  features/
    auth/
      sign_in.feature
      sign_out.feature
    cart/
      add_to_cart.feature
      checkout.feature
  step/
    given/
      i_am_on_sign_in_page.dart
      i_am_a_registered_user.dart
    when/
      i_sign_in_with_valid_credentials.dart
      i_tap_sign_in_button.dart
    then/
      i_see_my_dashboard.dart
      i_see_error_message.dart
```

### Feature File

```gherkin
# test/features/auth/sign_in.feature

Feature: Sign In
  As a registered user
  I want to sign in to the application
  So that I can access my personal data

  Background:
    Given the app is running

  Scenario: Successful sign in with valid credentials
    Given I am on the sign in page
    When I sign in as "user@example.com" with password "secure123"
    Then I see my personal dashboard

  Scenario: Sign in fails with invalid credentials
    Given I am on the sign in page
    When I sign in as "bad@example.com" with password "wrong"
    Then I see the error message "Invalid email or password"

  Scenario: Sign in is blocked after 5 failed attempts
    Given I have failed to sign in 4 times
    When I sign in as "user@example.com" with password "wrong"
    Then I see the error message "Account temporarily locked"
    And the sign in button is disabled
```

### Step Definitions

```dart
// test/step/given/i_am_on_sign_in_page.dart

import 'package:bdd_widget_test/bdd_widget_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

// Shared test context passed between steps
class FeatureContext {
  late MockAuthBloc authBloc;
}

Future<void> iAmOnTheSignInPage(WidgetTester tester) async {
  final bloc = MockAuthBloc();
  when(() => bloc.state).thenReturn(const AuthState.initial());
  when(() => bloc.stream).thenAnswer((_) => Stream.empty());

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const SignInPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

```dart
// test/step/when/i_sign_in_as_with_password.dart

Future<void> iSignInAsWithPassword(
  WidgetTester tester,
  String email,
  String password,
) async {
  await tester.enterText(
    find.byKey(const Key('signIn_emailField')),
    email,
  );
  await tester.enterText(
    find.byKey(const Key('signIn_passwordField')),
    password,
  );
  await tester.tap(find.byKey(const Key('signIn_submitButton')));
  await tester.pumpAndSettle();
}
```

```dart
// test/step/then/i_see_my_personal_dashboard.dart

Future<void> iSeeMyPersonalDashboard(WidgetTester tester) async {
  expect(find.byType(DashboardPage), findsOneWidget);
}
```

```dart
// test/step/then/i_see_the_error_message.dart

Future<void> iSeeTheErrorMessage(WidgetTester tester, String message) async {
  expect(find.text(message), findsOneWidget);
}
```

### Generated Test File

`bdd_widget_test` generates test files from feature files. The generator is run with:

```bash
flutter pub run build_runner build
```

The generated `sign_in_test.dart` maps Gherkin steps to the step definition functions above.

---

## Rust BDD with cucumber-rs

### Setup

```toml
# Cargo.toml
[dev-dependencies]
cucumber = "0.21"
tokio = { version = "1", features = ["macros", "rt-multi-thread"] }
```

### Directory Structure

```
tests/
  features/
    order/
      create_order.feature
      cancel_order.feature
    auth/
      authenticate.feature
  steps/
    order_steps.rs
    auth_steps.rs
  world.rs
  integration_test.rs
```

### Feature File

```gherkin
# tests/features/order/create_order.feature

Feature: Create Order
  As a customer
  I want to create an order
  So that I can purchase products

  Background:
    Given a customer with id "cust-1" exists

  Scenario: Create order with valid items
    Given the product "prod-1" is in stock with price $10.00
    When I create an order with 2 units of "prod-1"
    Then the order is created successfully
    And the order total is $20.00
    And the order status is "pending"

  Scenario: Cannot create order with out-of-stock product
    Given the product "prod-1" is out of stock
    When I create an order with 1 unit of "prod-1"
    Then the order creation fails with error "Product out of stock"
```

### World Struct

```rust
// tests/world.rs

use cucumber::World;
use std::sync::Arc;
use tokio::sync::Mutex;

#[derive(Debug, World)]
#[world(init = Self::new)]
pub struct OrderWorld {
    pub customer_id: Option<CustomerId>,
    pub last_order: Option<Order>,
    pub last_error: Option<DomainError>,
    pub product_repository: Arc<dyn ProductRepository>,
    pub order_repository: Arc<dyn OrderRepository>,
    pub order_service: Arc<CreateOrderService>,
}

impl OrderWorld {
    async fn new() -> Self {
        let product_repo = Arc::new(InMemoryProductRepository::default());
        let order_repo = Arc::new(InMemoryOrderRepository::default());
        let order_service = Arc::new(CreateOrderService::new(
            product_repo.clone(),
            order_repo.clone(),
        ));

        Self {
            customer_id: None,
            last_order: None,
            last_error: None,
            product_repository: product_repo,
            order_repository: order_repo,
            order_service,
        }
    }
}
```

### Step Implementations

```rust
// tests/steps/order_steps.rs

use cucumber::{given, when, then};
use crate::world::OrderWorld;
use rust_decimal::Decimal;

#[given(expr = "a customer with id {string} exists")]
async fn customer_exists(world: &mut OrderWorld, customer_id: String) {
    world.customer_id = Some(CustomerId::new(customer_id));
}

#[given(expr = "the product {string} is in stock with price ${float}")]
async fn product_in_stock(world: &mut OrderWorld, product_id: String, price: f64) {
    let product = Product::builder()
        .id(ProductId::new(product_id))
        .price(Money::new(Decimal::from_f64(price).unwrap(), Currency::Usd))
        .stock(Quantity::new(100))
        .build();
    world.product_repository.save(product).await.unwrap();
}

#[given(expr = "the product {string} is out of stock")]
async fn product_out_of_stock(world: &mut OrderWorld, product_id: String) {
    let product = Product::builder()
        .id(ProductId::new(product_id))
        .price(Money::new(Decimal::from(10), Currency::Usd))
        .stock(Quantity::new(0))
        .build();
    world.product_repository.save(product).await.unwrap();
}

#[when(expr = "I create an order with {int} units of {string}")]
async fn create_order(world: &mut OrderWorld, quantity: u32, product_id: String) {
    let command = CreateOrderCommand {
        customer_id: world.customer_id.clone().expect("customer must be set"),
        items: vec![OrderItemCommand {
            product_id: ProductId::new(product_id),
            quantity: Quantity::new(quantity),
        }],
    };

    match world.order_service.execute(command).await {
        Ok(order) => world.last_order = Some(order),
        Err(e) => world.last_error = Some(e),
    }
}

#[then("the order is created successfully")]
async fn order_created(world: &mut OrderWorld) {
    assert!(world.last_order.is_some(), "Expected order to be created");
    assert!(world.last_error.is_none(), "Expected no error");
}

#[then(expr = "the order total is ${float}")]
async fn order_total(world: &mut OrderWorld, expected: f64) {
    let order = world.last_order.as_ref().expect("order must exist");
    let expected = Money::new(Decimal::from_f64(expected).unwrap(), Currency::Usd);
    assert_eq!(order.total(), &expected);
}

#[then(expr = "the order creation fails with error {string}")]
async fn order_fails(world: &mut OrderWorld, error_message: String) {
    let error = world.last_error.as_ref().expect("expected an error");
    assert_eq!(error.to_string(), error_message);
    assert!(world.last_order.is_none());
}
```

### Test Entry Point

```rust
// tests/integration_test.rs

mod world;
mod steps {
    pub mod order_steps;
    pub mod auth_steps;
}

use cucumber::World;
use world::OrderWorld;

#[tokio::main]
async fn main() {
    OrderWorld::run("tests/features").await;
}
```

```toml
# Cargo.toml
[[test]]
name = "integration_test"
harness = false
```

### Running BDD Tests

```bash
# Run all cucumber tests
cargo test --test integration_test

# Run with verbose output (shows each step)
RUST_LOG=debug cargo test --test integration_test -- --format pretty

# Run only scenarios with specific tag
cargo test --test integration_test -- --tags @smoke
```
