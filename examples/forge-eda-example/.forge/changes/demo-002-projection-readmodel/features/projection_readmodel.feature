Feature: Event store projection into a read model
  As an operator of the forge-eda-example backend
  I want the persisted event stream folded into a read model
  So that queries are served from a deterministic, rebuildable view

  Background:
    Given the eventstore is configured with an in-memory event store

  Scenario: Fold the event stream into a read model
    Given events "A", "A", "B" are appended for stream "s"
    When the CountByType projection folds the read stream
    Then the read model reports "A" is 2
    And the read model reports "B" is 1

  Scenario: Projection replay is deterministic
    Given a read model built from the event store
    When the projection is rebuilt from the same event log
    Then the resulting view is identical

  Scenario: Redelivered event is deduplicated by the inbox
    Given an event with idempotency_key "k1" has already been processed
    When the same event is redelivered
    Then the inbox marks it a duplicate
    And the projection is folded only once
