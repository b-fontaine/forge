Feature: Forge upgrade — non-destructive framework merge
  As a Forge adopter
  I want forge upgrade to pull in framework updates without my
  customizations getting lost
  So that I can follow Constitution bumps without manual chores

  Scenario: Clean upgrade with no local edits
    Given a project scaffolded at archetype_version "1.0.0"
    And the framework has bumped to "1.1.0" with one new standard added
    And the adopter has not modified any framework-owned file
    When the adopter runs "forge upgrade"
    Then the new standard appears in .forge/standards/
    And the project's archetype_version is now "1.1.0"
    And upgrade_history has one entry recording the bump
    And the command exits 0
    And the structured summary reports "files upgraded" with at least 1

  Scenario: User customization is preserved
    Given a project scaffolded at archetype_version "1.0.0"
    And the adopter has edited .forge/standards/global/naming.md locally
    And the framework has not modified that file in 1.1.0
    When the adopter runs "forge upgrade"
    Then .forge/standards/global/naming.md retains the local edits
    And the structured summary reports "files preserved: 1"
    And no .merge-conflicts file is created
    And the command exits 0

  Scenario: Conflict produces git-style markers and a companion file
    Given a project scaffolded at archetype_version "1.0.0"
    And the adopter has edited .forge/standards/rust/error-handling.md
    And the framework's 1.1.0 also modifies that same file
    When the adopter runs "forge upgrade"
    Then .forge/standards/rust/error-handling.md contains git-style conflict markers
    And .merge-conflicts at the project root lists that path with "[CONFLICT]" prefix
    And the structured summary reports "files conflicted: 1"
    And the command exits 8

  Scenario: Dry-run prints the plan without writing
    Given a project scaffolded at archetype_version "1.0.0"
    And the framework has bumped to "1.1.0"
    When the adopter runs "forge upgrade --dry-run"
    Then the structured summary is printed
    And no file in the project is modified
    And .forge/scaffold-manifest.yaml retains "1.0.0" as archetype_version
    And no .merge-conflicts file is created
    And the command exits 0

  Scenario: Re-running after a clean upgrade is idempotent
    Given a project at archetype_version "1.0.0" with framework at "1.1.0"
    And the adopter has run "forge upgrade" successfully
    When the adopter runs "forge upgrade" a second time
    Then the structured summary reports "files unchanged" equal to the total owned count
    And no project file is mutated byte-for-byte
    And upgrade_history gains one new entry with all-zero counts on the second run
    And the command exits 0

  Scenario: Major-version bump aborts with NEEDS MIGRATION
    Given a project at archetype_version "1.5.2"
    And the framework's current version is "2.0.0"
    When the adopter runs "forge upgrade"
    Then the command exits 7
    And the output contains "[NEEDS MIGRATION: from 1.5.2 to 2.0.0]"
    And no file in the project is modified

  Scenario: --force on dirty Git working tree aborts
    Given a project at archetype_version "1.0.0" with framework at "1.1.0"
    And the adopter has uncommitted modifications in the project
    When the adopter runs "forge upgrade --force"
    Then the command exits 7
    And the output explicitly mentions "clean Git working tree"
    And no file in the project is modified
