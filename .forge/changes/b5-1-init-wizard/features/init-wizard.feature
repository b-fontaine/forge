Feature: Forge init — multi-archetype dispatcher
  As a Forge adopter starting a new project
  I want forge init to pick the right archetype reliably
  So that I scaffold the canonical structure without manual chores

  Scenario: Explicit archetype dispatches the wrapper
    Given a clean target directory
    When the adopter runs "forge init --archetype full-stack-monorepo my-app --org io.acme.myapp --target <dir>"
    Then bin/forge-init-fsm.sh is invoked with --target <dir> --project-name my-app --reverse-domain io.acme.myapp
    And the command exits with the wrapper's exit code
    And no wizard prompt appears on stdout

  Scenario: Auto-detection of full-stack-monorepo from co-presence
    Given a target directory containing both pubspec.yaml and Cargo.toml
    When the adopter runs "forge init --auto --target <dir>"
    Then the dispatcher resolves the archetype to "full-stack-monorepo"
    And the dispatcher prompts for the project name + --org if missing on TTY
    And aborts with usage on non-TTY when --org is missing

  Scenario: Ambiguous auto-detection aborts strictly
    Given a target directory containing pubspec.yaml but not Cargo.toml
    When the adopter runs "forge init --auto --target <dir>"
    Then the command exits 2
    And the output contains "[NEEDS DECISION:" with the candidate list
    And the output suggests "--archetype default" as the workaround

  Scenario: Interactive wizard prompts and writes
    Given an interactive terminal session
    And no init flags are passed
    When the adopter runs "forge init"
    Then the wizard prints a numbered archetype menu drawn from dispatch-table.yml
    And accepts user input "2" for full-stack-monorepo
    And prompts for "Project name" and "Reverse domain"
    And prints a one-line confirmation summary before invoking the dispatcher
    And invokes the same code path as --archetype full-stack-monorepo

  Scenario: Non-TTY without flags falls back to default
    Given a non-interactive environment (no TTY on stdin)
    And no --archetype flag is passed
    When the adopter runs "forge init --target <tmp>"
    Then the dispatcher silently selects the "default" archetype
    And the file-copy scaffold runs byte-equivalent to pre-b5.1 behavior
    And the command exits 0

  Scenario: Mutual exclusion of selection flags
    Given any environment
    When the adopter runs "forge init --archetype default --auto"
    Then the command exits 2
    And the output explains that --archetype, --auto, --wizard are mutually exclusive
