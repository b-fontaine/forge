# <!-- Audit: B.6.2 (b6-2-scaffolder) — BDD scenarios (Article II) -->
# Each scenario cross-references the enforcing test in b6-2.test.sh /
# archetypes-smoke.test.ts / the rendered backend cargo tests.

Feature: event-driven-eu scaffold backbone (candidate, pre-promotion)
  As a Forge adopter
  I want the event-driven-eu backbone to render a building event-driven service
  So that the archetype is reviewable/testable before its B.6.7 promotion

  # Enforced by b6-2.test.sh T-L2-001 (render-clean + byte-stable) + T-002 (plan↔tree).
  Scenario: rendering the scaffold-plan produces a clean tree
    Given the event-driven-eu/1.0.0 template tree and scaffold-plan
    When overlay.sh renders the plan into an empty target directory
    Then the target contains backend/, infra/, shared/asyncapi/, shared/protos/
    And no file retains a .tmpl suffix
    And no unsubstituted <placeholder> remains

  # Enforced by b6-2.test.sh T-L2-002 (cargo check on rendered backend) + the
  # rendered `cargo test --workspace` (16 unit tests across the four crates).
  Scenario: the rendered backend builds and tests
    Given a freshly rendered event-driven-eu target
    When cargo test runs on the backend workspace
    Then it completes without error
    And the events, eventstore, saga and bin-server crates ship tests

  # Enforced by b6-2.test.sh T-006 (wrapper) + archetypes-smoke.test.ts candidate
  # partition (built CLI → exit 3, no dir).
  Scenario: the CLI still refuses init for the candidate archetype
    Given the schema is stage:candidate / scaffoldable:false
    When a user runs forge init --archetype event-driven-eu
    Then the CLI refuses with exit 3 and writes nothing

  # Enforced by saga::compensation::tests::failure_compensates_completed_steps_in_reverse
  # (rendered `cargo test`).
  Scenario: a saga compensates completed steps in reverse on failure
    Given a saga with steps a, b, then a failing step c
    When the saga runs
    Then a and b execute, c fails, and b then a are compensated in reverse order
