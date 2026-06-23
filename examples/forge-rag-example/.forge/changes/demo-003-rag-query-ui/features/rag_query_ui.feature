Feature: Streaming RAG query UI
  As a human using the forge-rag-example web surface
  I want to ask a question and watch the answer stream in
  So that I get a low-latency, grounded, fallback-aware response

  Background:
    Given the Qwik query screen is loaded
    And the backend exposes RagService.QueryStream through the LLM gateway

  Scenario: streaming happy path renders progressively
    Given the gateway upstream streams the tokens "Forge" " enforces" " TDD"
    And the retriever grounds the answer in source "doc-1"
    When the user submits the question "what does Forge enforce?"
    Then the grounding source "doc-1" renders first
    And the answer renders progressively as "Forge enforces TDD"
    And the fallbackUsed indicator is not shown

  Scenario: pre-stream outage degrades to the unary fallback
    Given the streaming upstream is unavailable
    When the user submits a question
    And the bounded stream retries are exhausted
    Then the UI degrades to the unary query path
    And the answer is served by the non-AI fallback
    And the fallbackUsed indicator is shown

  Scenario: Stop cancels the in-flight stream
    Given a stream is in flight
    When the user clicks Stop
    Then the in-flight stream is aborted
    And no further tokens are appended to the answer
