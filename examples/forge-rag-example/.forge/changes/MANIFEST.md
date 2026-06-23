# Demo changes — manifest

<!-- Audit: B.7.7 (b7-7-example FR-RAGEX-006) -->

This file is the **chronological index** of demo changes shipped under
`examples/forge-rag-example/.forge/changes/`. Listed in archive order so
adopters reading the directory get a narrative of the RAG discipline.

| Demo | Status | One-line summary |
|---|---|---|
| [`demo-001-doc-ingestion`](demo-001-doc-ingestion/) | archived (2026-06-23) | Single-layer backend — document ingestion + RAG query across the `rag/` pipeline (chunking → `Embedder` → pgvector HNSW upsert → hybrid retrieval vector+BM25+RRF → re-rank); XI.5 embedder fallback + XI.6 in-process local path; cucumber-rs BDD. |
| [`demo-002-mcp-search-tool`](demo-002-mcp-search-tool/) | archived (2026-06-23) | Single-layer backend — the `mcp/` server: an rmcp `#[tool_router]` `search` tool over the retriever, dual transport (stdio + streamable-HTTP), schema-validated input, least-privilege cap, OAuth 2.1 → Zitadel hook; cucumber-rs BDD. |
| [`demo-003-rag-query-ui`](demo-003-rag-query-ui/) | archived (2026-06-23) | Multi-layer (backend + frontend, Janus) — streaming Qwik query UI consuming `RagService.QueryStream` via the gateway: progressive token render through `queryStream`, prompt-audit span (IX.6) across the stream, and the XI.5 `fallbackUsed` indicator (stream degrades to the unary `Query` path). Per-layer designs/ + tasks/. |

Each demo's change directory contains the canonical artefacts:
`.forge.yaml`, `proposal.md`, `specs.md`, `design.md` (or per-layer
`designs/design-<layer>.md`), `tasks.md` (or per-layer
`tasks/tasks-<layer>.md`), and `features/<demo>.feature` for the BDD
scenarios.

For the example tree's top-level navigation see `../../README.md`; for
the `examples/` directory README in the Forge framework repo see
`../../../README.md`.
