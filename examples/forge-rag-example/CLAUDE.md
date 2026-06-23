<!-- Audit: B.7.2 (b7-2-scaffolder, Phase 1) — ai-native-rag/1.0.0 root CLAUDE.md -->
<!-- Structural precedent: full-stack-monorepo/2.0.0/CLAUDE.md.tmpl -->

# CLAUDE.md — forge-rag-example

# Forge Framework — AI-Native RAG

This project uses the `ai-native-rag` archetype. The archetype schema is shipped
by `forge init` and located at `.forge/schemas/ai-native-rag/1.0.0.yaml`.

Canonical layer layout:

| Directory               | Stack                                              |
|-------------------------|----------------------------------------------------|
| `backend/`              | Rust Cargo workspace (RAG + LLM gateway + MCP)     |
| `frontend/web-public/`  | Qwik streaming web surface                         |
| `infra/`                | pgvector HNSW / Temporal / Zitadel / observability |
| `shared/protos/`        | Protobuf contracts (all layers)                    |

## Routing Policy

Claude Code MUST load the nearest `CLAUDE.md` whenever it navigates into a
subtree. This root file is routing-only; stack-specific standards are
intentionally absent.

| Working path             | Load                            | Route to                              |
|--------------------------|---------------------------------|---------------------------------------|
| `backend/**`             | `backend/CLAUDE.md`             | **Vulcan** — Rust Team Orchestrator   |
| `frontend/web-public/**` | `frontend/web-public/CLAUDE.md` | **Hera** — Flutter/Web Orchestrator   |
| `infra/**`               | `infra/CLAUDE.md`               | **Atlas** — Infra Architect           |
| `shared/protos/**`       | `global/proto-contracts.md`     | **Hermes-API** — Contract changes     |

**Cross-layer changes** (touching 2 or more layers) MUST be routed to **Janus**
— the cross-layer orchestrator. A change is cross-layer when it introduces or
modifies a `FR-GL-XXX` requirement that delegates child requirements to two or
more layer prefixes (`FR-BE-`, `FR-FE-`, `FR-IN-`).

## Non-Negotiable Rules

1. **TDD is mandatory** (Article I). The RED → GREEN → REFACTOR cycle is
   immutable and has no exceptions. NEVER write production code without a
   failing test first.

2. **BDD is required for every user-facing feature** (Article II). Scenarios
   MUST be written in Given/When/Then form before implementation begins.

3. **AI features MUST have a non-AI fallback** (Article XI.5). The LLM gateway
   and the embeddings pipeline both ship a degraded / local fallback path.
   PII is handled with explicit consent (Article XI.6); prompts are audited and
   token budgets enforced (Article IX.6).

4. **No cross-imports between `frontend/` and `backend/`** outside the generated
   stubs under `shared/protos/`. The Connect/gRPC contract is the only
   sanctioned communication channel between the two stacks.

5. **Commit messages MUST use scoped Conventional Commits** with a scope drawn
   from the following closed list:

   ```
   backend | frontend | infra | protos | forge | docs | ci
   ```

6. **Protos are the single source of truth**. Generated stubs MUST NOT be edited
   by hand. Regenerate with `task proto`.

## Commands

All operations go through the Taskfile at the repo root. Do not call build tools
directly.

| Command        | Action                                  |
|----------------|-----------------------------------------|
| `task dev:up`  | Start local stack via Docker Compose    |
| `task test`    | Run all tests across all layers         |
| `task lint`    | Run all linters across all layers       |
| `task proto`   | Regenerate proto stubs                   |
| `task release` | Execute the release train               |

## Standards

All Forge standards live under `.forge/standards/`. The standards index is at
`.forge/standards/index.yml`.

**WARNING — this root file does NOT import stack-specific standards.** Rust,
Qwik, and infra standards are loaded exclusively by the nested `CLAUDE.md` files.
Loading them here would saturate the context window with irrelevant rules.

Archetype-specific standards in effect for AI work:

- `.forge/standards/global/rag-patterns.md` — RAG pipeline patterns
- `.forge/standards/global/llm-gateway.md` — in-repo LLM gateway proxy
- `.forge/standards/global/mcp-servers.md` — MCP servers (rmcp)
- `.forge/constitution.md` — binding authority; violations block progress
