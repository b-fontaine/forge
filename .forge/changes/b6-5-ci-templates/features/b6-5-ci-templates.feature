# <!-- Audit: B.6.5 (b6-5-ci-templates) — BDD scenarios (Article II) -->
# Each scenario cross-references the enforcing test in b6-5.test.sh.

Feature: event-driven-eu per-layer CI templates
  As a Forge adopter of the event-driven-eu archetype
  I want per-layer GitHub Actions workflows scaffolded with my project
  So that my events, workflows/saga and infra layers are gated on every PR

  # Enforced by b6-5.test.sh T-001 (files exist) + T-L2-001 (render-clean YAML).
  Scenario: the three per-layer workflow templates exist and render clean
    Given the event-driven-eu/1.0.0 template tree
    When overlay.sh renders the scaffold-plan into an empty target
    Then .github/workflows/ contains forge-events.yml, forge-workflows.yml and forge-infra.yml
    And none retains a .tmpl suffix or an unsubstituted <placeholder>
    And each parses as valid YAML

  # Enforced by b6-5.test.sh T-003 (Task-target references).
  Scenario: each workflow invokes the archetype's Task targets
    Given the rendered workflows
    When their steps are inspected
    Then forge-events and forge-workflows run "task backend:lint"
    And forge-infra runs "task asyncapi:validate"

  # Enforced by b6-5.test.sh T-004 (temporal-sdk opt-in + non-blocking).
  Scenario: the default saga gate does not compile the pre-alpha Temporal SDK
    Given forge-workflows.yml
    When it runs on a pull_request
    Then the blocking saga job runs "cargo test -p saga" with default features
    And the "--features temporal-sdk" job runs only on workflow_dispatch

  # Enforced by b6-5.test.sh T-006 (scaffold-plan registration) + b6-2.test.sh T-002.
  Scenario: the three templates are registered in the scaffold-plan
    Given scaffold-plan.yaml
    When its templates list is inspected
    Then each of the three workflow .tmpl files is present with substitute: true
    And b6-2.test.sh plan-to-tree coverage stays green
