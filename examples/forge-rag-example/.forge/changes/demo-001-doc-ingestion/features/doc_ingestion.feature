Feature: Document ingestion and RAG query
  As an operator of the forge-rag-example backend
  I want to ingest documents and query them
  So that I receive a grounded answer with cited sources

  Background:
    Given the rag pipeline is configured with an in-memory pgvector fixture
    And the compliance tier is T1

  Scenario: Ingest then query returns a grounded answer
    Given a document "doc-1" with text "Forge enforces TDD and BDD as non-negotiable"
    When the document is chunked, embedded, and upserted
    And I query "what does Forge enforce?"
    Then the hybrid retriever fuses the vector and BM25 legs via RRF
    And the answer cites source chunk "doc-1"
    And fallback_used is false

  Scenario: T3 forces the local embedder with zero egress
    Given the compliance tier is T3
    When the embedder backend is selected
    Then the in-process LocalEmbedder is chosen
    And no cloud embedding provider is contacted

  Scenario: Embedder fallback degrades to the local path
    Given the cloud embedder is unavailable
    When a document is embedded
    Then the pipeline degrades to the local in-process embedder
    And the query still returns ranked source chunks as the answer
    And fallback_used is true
