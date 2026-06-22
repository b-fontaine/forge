# Proposal: b7-2-scaffolder

<!-- Created: 2026-06-21 -->
<!-- Schema: default -->
<!-- Audit: B.7.2 (docs/new-archetypes-plan.md §6.2 — ai-native-rag scaffolder, full) -->
<!-- Input: .forge/_memory/b7-ai-native-rag-exploration.md §5 brick #3 (ratified 2026-06-11) -->

## Problem

The `ai-native-rag` archetype is **registered but inert**. Three bricks have
landed (`.forge/specs/ai-native-rag.md`):

- **B.7.1** (`b7-1-schema`, 2026-06-11) — `.forge/schemas/ai-native-rag/1.0.0.yaml`,
  `stage: candidate` / `scaffoldable: false`.
- **B.7.2a** (`b7-2a-dispatch-register`, 2026-06-12) — dispatch-table entry +
  refusing wrapper `bin/forge-init-ai-native-rag.sh` (exit 3, zero writes).
- **B.7.3** (`b7-standards`, 2026-06-13) — `global/{rag-patterns,llm-gateway,mcp-servers}.md`
  pattern docs, **no version pins** (pins deferred to "the consuming `Cargo.toml.tmpl`").

So `forge init --archetype ai-native-rag` refuses cleanly (exit 3, "registered, no
scaffoldable version"). **There are no templates** (`templates/ai-native-rag/` does
not exist), the wrapper is a stub, and the three pattern standards describe code
that has nowhere to be rendered. Nothing downstream (example project, promotion
harness, AI-Act artefacts) can proceed until a scaffold backbone exists.

This brick (#3 of the 9-brick B.7 chain, the hard dependency `1→2→3`) ships that
backbone: the `templates/ai-native-rag/1.0.0/*` tree + the real scaffolder body +
the **verify-then-pin** of the Rust crates the standards reference but deliberately
left unpinned.

**Ground truth (re-read 2026-06-21, Article III.4):**

- `templates/ai-native-rag/1.0.0/` — **absent**. The full-stack flagship lives at
  `templates/full-stack-monorepo/2.0.0/` and is the structural precedent
  (backend Rust axum + Temporal + Connect + frontend Qwik + infra).
- Substrate already shipped by B.8 and reused, **not re-created** (memo §3):
  pgvector (`pgvector:0.8.2-pg17`, B.8.5), Temporal Rust workers (`temporalio-sdk
  0.4.0`, B8O — DBOS cancelled for Rust), Qwik web surface (B.8.9), Zitadel OIDC
  (B.8.7 + Envoy JWT B.8.12), Connect transport (B.8.6), OTel app SDK (`t5-otel-app`).
- Net-new is confined to **three layers** (memo §3): the in-repo Rust **LLM gateway
  proxy** (decision A: thin axum proxy, OpenAI-compatible → Mistral-Scaleway/vLLM,
  tier-aware), **MCP servers** (rmcp, axum-native), and the **RAG pipeline**
  (chunking → embeddings → hybrid retrieval → re-ranking).
- Verify-then-pin candidates, **NOT yet confirmed LIVE** (memo §2, b7-standards
  research baseline 2026-06-13): `rmcp` (README 0.16.0 vs Context7 0.5.0 vs LIVE
  1.7.0 — three-way drift, ADR-B7-3-003), `pgvector` crate (≈0.4.2), `async-openai`
  (≈0.41.0). All must be re-verified with `cargo add` at implementation and pinned
  **in the rendered `Cargo.toml.tmpl`**, never from a note (coroot/Q-004 lesson).

## Solution

Render the `ai-native-rag/1.0.0` scaffold as a template tree that mirrors the
flagship 2.0.0 structure and conforms to the B.7.3 pattern standards, then wire the
real scaffolder so `forge init --archetype ai-native-rag` produces a building
project. Concretely:

1. **Backend templates** (`templates/ai-native-rag/1.0.0/backend/`, Rust/Vulcan):
   axum service consuming the existing Connect + Temporal + Zitadel/OTel substrate,
   plus the three net-new layers as scaffolded modules:
   - `llm_gateway/` — thin axum proxy (decision A), OpenAI-compatible client,
     tier-aware refusal hooks (refs I.3 forbidden-components + compliance-tiers;
     runtime Janus AI rules stay in `b7-9-janus-ai`), prompt-audit span (IX.6),
     token budget + kill switch (XI.5).
   - `mcp/` — rmcp server stub(s) (stdio + streamable-HTTP/axum), least-privilege,
     OAuth 2.1 → Zitadel/Envoy-OIDC per `mcp-servers.md`.
   - `rag/` — pipeline modules (chunking/embeddings, hybrid retrieval vector+BM25+RRF,
     coarse→exact re-ranking, pgvector HNSW) per `rag-patterns.md`; Temporal
     activity-only workers (SDK pre-alpha caveat, memo §6).
2. **Frontend + infra templates** (`templates/ai-native-rag/1.0.0/{frontend,infra}/`):
   Qwik streaming-UI shell (Apollo/Hera) reusing B.8.9; pgvector HNSW indexes +
   Temporal + Zitadel + observability manifests (Atlas) reusing B.8 base. Streaming
   transport *detail* (SSE/WebTransport) is **out** (brick `b7-10-streaming`).
3. **Verify-then-pin**: `cargo add` LIVE for `rmcp` / `pgvector` / `async-openai`,
   pinned in the rendered `Cargo.toml.tmpl`; record the resolved versions in the
   change and bump the relevant pin ledger if a standard needs a version block.
4. **Scaffolder body**: replace the refusing stub in `bin/forge-init-ai-native-rag.sh`
   with a real init body (full-stack `forge-init-fsm-2.0.0.sh` precedent); bundle the
   schema + templates into `cli/assets` (`npm run bundle`); keep CLI e2e couplings
   green (`help-snapshots`, `archetypes-smoke` — the candidate-partition added in
   B.7.2a is revisited at promotion).

## Scope In

- `templates/ai-native-rag/1.0.0/{backend,frontend,infra}/*` scaffold tree.
- Net-new Rust layers as scaffolded modules: LLM gateway proxy, MCP server stub,
  RAG pipeline (chunking/embeddings/retrieval/re-ranking, pgvector HNSW, Temporal
  activity workers).
- Verify-then-pin LIVE of `rmcp` / `pgvector` (Rust crate) / `async-openai`, pinned
  in the rendered `Cargo.toml.tmpl`.
- Real scaffolder body in `bin/forge-init-ai-native-rag.sh` + `cli/assets` bundle.
- A scaffold-time validation sufficient to prove the rendered project is well-formed
  (the comprehensive `b7.test.sh ≥35` suite stays in brick `b7-6-harness`).

## Scope Out (Explicit Exclusions)

- **Candidate → stable / scaffoldable: true promotion** — gated on a green
  `b7-6-harness` (ADR-B7-1-002, B.8.14-C2 pattern). Whether a minimal promotion can
  ride here or must wait for `b7-6` is an **open question for design**.
- **Qwik streaming transport** SSE/WebTransport detail → `b7-10-streaming` (#7).
- **`examples/forge-rag-example/`** (3 demos) → `b7-7-example` (#8).
- **Full promotion harness** `b7.test.sh ≥35` + snapshot tarball → `b7-6-harness` (#9).
- **Pythia agent (K.2)** → `b7-pythia` (#4).
- **Runtime Janus AI refusal rules (J.8.c)** — Vertex/Bedrock refusal, T3⇒Mistral-EU/vLLM
  → `b7-9-janus-ai` (#5). This brick only scaffolds the tier-aware *hooks*.
- **AI-Act / DORA compliance artefacts** → `b7-5-ai-act` (#6) / Themis K.5.
- No edit to `archetype.schema.json` enum (already contains `ai-native-rag`, memo §1).

## Impact

- **Users affected**: adopters wanting an AI-native RAG scaffold — still cannot
  `init` to a *stable* archetype after this brick, but the backbone becomes
  reviewable/testable. No impact on existing archetypes.
- **Technical impact**: net-new `templates/ai-native-rag/1.0.0/` tree (largest
  surface of the B.7 chain); edits confined to the wrapper body, `cli/assets`
  bundle, CI matrix, and tested CLI couplings. Decision B (memo §4): this `XL` brick
  **may be split into reviewable/revertable sub-slices** (e.g. backend / frontend+infra)
  rather than landing as a monolith — to be settled in design.
- **Dependencies**: B.7.1 (schema), B.7.2a (dispatch entry), B.7.3 (standards) — all
  archived. Reuses B.8.5/B.8.6/B.8.7/B.8.9/B.8.12 + B8O + `t5-otel-app` substrate.

## Constitution Compliance (v2.0.0)

- **Article I (TDD)**: RED→GREEN→REFACTOR on the scaffolder body and any rendered-tree
  validation; template fixtures assert structure before the wrapper is wired.
- **Article II (BDD)**: the user-facing capability (`forge init --archetype
  ai-native-rag` produces a building project) gets Given/When/Then scenarios.
- **Article III (Specs Before Code)**: this proposal → specs → design → tasks before
  any template is rendered. **III.4 anti-hallucination**: every external version is
  verify-then-pinned LIVE; no pin is copied from the exploration note.
- **Article VII (Rust architecture)**: backbone follows the flagship 2.0.0 Rust
  layering (Vulcan ownership; axum + Connect + Temporal + OTel).
- **Article VIII (§VIII.1 Envoy / §VIII.2 Temporal)**: consumed as-is from the 2.0.0
  substrate, not re-decided.
- **Article IX.6 (prompt audit)** + **Article XI (AI-First: XI.5 fallback mandatory,
  XI.6 PII explicit consent)**: materialised in the LLM gateway + RAG pipeline
  scaffold per the B.7.3 standards and the `1.0.0.yaml` `ai_specifics` block.

## Open Questions (to resolve at specify/design)

- **Q-1** — Can/should a minimal candidate→stable promotion ride in this brick, or
  must it wait for `b7-6-harness` (ADR-B7-1-002)? Affects whether `forge init` becomes
  non-refusing here.
- **Q-2** — Slice granularity (Decision B): single `b7-2-scaffolder` change vs split
  into `b7-2b` (backend) / `b7-2c` (frontend+infra).
- **Q-3** — Embeddings provider for the scaffold default (Mistral-EU API vs local
  Candle/fastembed; T3 ⇒ self-host) — deferred D from memo §4.
- **Q-4** — MCP stub transport (stdio subprocess vs HTTP axum) — deferred E from memo §4.

---

**Gate**: Proposal created at `.forge/changes/b7-2-scaffolder/proposal.md`. Review and
confirm before proceeding to → `/forge:specify b7-2-scaffolder`.
