Feature: MCP search tool
  As an MCP-capable host (IDE, agent)
  I want to call the search tool over the RAG corpus
  So that I retrieve grounding documents under a least-privilege contract

  Background:
    Given an MCP search server over a bounded, read-only document index

  Scenario: search returns a matching hit
    Given the index contains "doc-1" with content "The quick brown Fox"
    And the index contains "doc-2" with content "lazy dog"
    When the search tool is called with query "fox"
    Then exactly one hit is returned
    And the hit document_id is "doc-1"

  Scenario: search respects the hard cap (least privilege)
    Given the index contains 100 documents that all match "match"
    When the search tool is called with query "match" and limit 1000
    Then at most MAX_SEARCH_LIMIT hits are returned

  Scenario: the tool advertises a schema-validated contract
    When an MCP host inspects the search tool's JSON Schema
    Then the schema names the "query" parameter
    And the schema names the "limit" parameter
