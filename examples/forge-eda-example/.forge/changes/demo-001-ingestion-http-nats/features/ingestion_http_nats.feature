Feature: HTTP ingestion publishes to NATS JetStream
  As an operator of the forge-eda-example backend
  I want an HTTP command to be published as a versioned, idempotent event
  So that the event backbone receives it exactly once

  Background:
    Given the events pipeline is configured with an in-memory publisher fake

  Scenario: Ingest publishes a versioned event to JetStream
    Given an ingestion command for stream "order-1" of type "OrderPlaced" version 2
    When the command is ingested
    Then a versioned, idempotent EventEnvelope is built
    And it is published to the JetStream subject "events.v2.OrderPlaced"
    And the response carries the assigned event_id

  Scenario: Idempotent re-publish is deduplicated
    Given a command with idempotency_key "order-42" has already been published
    When the same command is submitted again
    Then the Nats-Msg-Id dedup suppresses the duplicate
    And the response reports deduplicated is true
