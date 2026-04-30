# Specs: demo-002-greeting-screen

<!-- Audit: C.1 (illustrative demo) -->
<!-- Layers: [frontend] -->
<!-- Format: ADDED-only delta. -->

## ADDED Requirements

### FR-FE-001: `GreetingCubit` state machine

- **MUST** — `frontend/lib/features/greeting/presentation/cubit/greeting_cubit.dart`
  declares `GreetingCubit extends Cubit<GreetingState>`.
- **MUST** — three sealed-class states : `GreetingInitial`,
  `GreetingLoading`, `GreetingSuccess(String message)`.
- **MUST** — method `Future<void> sayHello(String name)` emits
  `GreetingLoading` then `GreetingSuccess` with the rendered
  greeting message.
- **SHALL** — depends on `GreetingRepository` port (FR-FE-002),
  injected via the constructor.

**Constitution reference:** Article VI.3, Article VI.4 (DI).
**Testable:** yes — `bloc_test` exercises the state transitions.

### FR-FE-002: `GreetingRepository` port + fake adapter

- **MUST** — `frontend/lib/features/greeting/domain/repository/greeting_repository.dart`
  declares the abstract interface
  `Future<String> greet(String name)`.
- **MUST** — `frontend/lib/features/greeting/data/repository/greeting_repository_impl.dart`
  implements the port with a fake : returns
  `"Hello, $name!"` (or `"Hello, world!"` if name is empty),
  matching demo-001's contract.
- **MUST** — Article VI.2 dependency rule : the domain port
  has zero dependency on Flutter ; only the data adapter imports
  Flutter.

**Constitution reference:** Article VI.2. **Testable:** yes.

### FR-FE-003: `GreetingScreen` widget

- **MUST** — `frontend/lib/features/greeting/presentation/screen/greeting_screen.dart`
  declares a `StatelessWidget` consuming `GreetingCubit` via
  `BlocBuilder`.
- **MUST** — renders, in order : a `TextField` for the name
  (with semantic label "Audience name"), an `ElevatedButton`
  (label "Say hello", semantic label "Submit greeting"), and a
  text region rendering the greeting message when the state is
  `GreetingSuccess`.
- **MUST** — passes Flutter's a11y checker (semantic labels for
  all interactive elements, contrast ≥ WCAG AA).
- **MUST** — the widget is responsive : on screen widths < 600
  the controls stack vertically ; on wider screens they sit in
  a row (Article VI.7).

**Constitution reference:** Articles VI.2, VI.7, VI.9.
**Testable:** yes — widget test + golden test.

## Acceptance Criteria (BDD)

```gherkin
Feature: Greeting screen
  As a Flutter app user
  I want to enter a name and tap a button
  So that I see a polite greeting

  Scenario: User enters a name and gets a personalized greeting
    Given the GreetingScreen is displayed
    When I enter "Alice" in the audience field
    And I tap "Say hello"
    Then I see "Hello, Alice!" in the greeting region

  Scenario: User submits without a name and sees the default greeting
    Given the GreetingScreen is displayed
    When I leave the audience field empty
    And I tap "Say hello"
    Then I see "Hello, world!" in the greeting region
```
