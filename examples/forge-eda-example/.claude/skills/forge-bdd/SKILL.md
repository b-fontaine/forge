---
name: forge-bdd
description: BDD enforcement skill for Forge framework - ensures Given/When/Then scenarios for all user-facing features
globs: ["**/*.feature", "**/*.md", "**/*.dart", "**/*.rs"]
alwaysApply: false
---

# Forge BDD Skill

## Activation Triggers
Activate when:
- Writing user-facing features
- Working with `.feature` files
- Planning acceptance criteria
- Implementing behaviors visible to end users

## Gherkin Format

```gherkin
Feature: [User-facing capability name]
  As a [user type]
  I want to [goal]
  So that [benefit]

  Background:
    Given [common context for all scenarios]

  Scenario: [Happy path]
    Given [initial state]
    When [user action]
    Then [observable outcome]
    And [additional assertion]

  Scenario: [Edge case]
    Given [different initial state]
    When [same or different action]
    Then [different outcome]

  Scenario Outline: [Parameterized scenarios]
    Given a user with <role>
    When they access <resource>
    Then they <outcome>

    Examples:
      | role  | resource | outcome          |
      | admin | settings | can view settings|
      | guest | settings | sees 403 error   |
```

## Flutter BDD (bdd_widget_test)

Feature file location: `test/features/<feature-name>.feature`

```dart
// test/steps/user_steps.dart
import 'package:bdd_widget_test/bdd_widget_test.dart';

Future<void> iAmOnTheLoginScreen(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: LoginPage()));
  await tester.pumpAndSettle();
}

Future<void> iEnterMyEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('email-field')), email);
}

Future<void> iSeeAWelcomeMessage(WidgetTester tester) async {
  expect(find.text('Welcome back!'), findsOneWidget);
}
```

```gherkin
# test/features/login.feature
Feature: User Login
  Scenario: Successful login with valid credentials
    Given I am on the login screen
    When I enter my email 'user@example.com'
    And I enter my password 'correct-password'
    And I tap the login button
    Then I see a welcome message
    And I am on the home screen
```

## Rust BDD (cucumber-rs)

Feature file location: `features/<feature-name>.feature`

```rust
// tests/bdd.rs
use cucumber::{given, then, when, World};

#[derive(Debug, Default, World)]
pub struct AppWorld {
    pub order: Option<Order>,
    pub result: Option<Result<Order, DomainError>>,
}

#[given(expr = "a new order for {int} items")]
async fn a_new_order(world: &mut AppWorld, quantity: u32) {
    world.order = Some(Order::new(quantity));
}

#[when("the order is confirmed")]
async fn order_is_confirmed(world: &mut AppWorld) {
    let order = world.order.take().unwrap();
    world.result = Some(order.confirm());
}

#[then("the order status should be confirmed")]
async fn order_status_confirmed(world: &mut AppWorld) {
    let result = world.result.take().unwrap();
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, OrderStatus::Confirmed);
}

#[tokio::main]
async fn main() {
    AppWorld::run("features/").await;
}
```

## BDD Rules
1. Scenarios written BEFORE implementation (they are the spec)
2. Every FR in specs.md with a user-facing AC gets a .feature file
3. Scenarios must be readable by non-developers (no code in Gherkin)
4. Each scenario tests ONE behavior
5. Background for shared setup, not for test logic
6. Tag critical paths: @smoke, @regression, @wip
