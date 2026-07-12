Feature: Order-fulfillment saga with reverse-order compensation
  As an operator of the forge-eda-example backend
  I want a durable 3-step order saga that compensates on failure
  So that a partially-completed order never leaves inconsistent state

  Background:
    Given an order saga with steps "reserve-stock", "charge-payment", "confirm-shipment"

  Scenario: Happy path completes all three steps
    Given every step succeeds
    When the saga runs
    Then reserve-stock, charge-payment and confirm-shipment execute in order
    And no compensation runs

  Scenario: A mid-saga failure compensates completed steps in reverse
    Given "confirm-shipment" will fail
    When the saga runs
    Then reserve-stock and charge-payment execute
    And confirm-shipment fails
    And charge-payment then reserve-stock are compensated in reverse order
    And the original failure is returned
