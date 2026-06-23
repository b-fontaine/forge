# Proposal: b7-7-example

<!-- Created: 2026-06-22 -->
<!-- Schema: default -->
<!-- Audit: B.7.7 (docs/new-archetypes-plan.md §0.12 T7 brick #8) — examples/forge-rag-example/ (3 demos) -->
<!-- Input: .forge/_memory/b7-ai-native-rag-exploration.md §5 brick #8 -->
<!-- Precedent: c1-reference-project (examples/forge-fsm-example/) + .forge/specs/example-reference.md -->

## Problem

The `ai-native-rag` archetype now has a **complete, reviewable
backbone** — `b7-1-schema` (the `1.0.0` candidate schema),
`b7-2a-dispatch-register` (CLI dispatch entry, refusal exit 3),
`b7-standards` (`global/{rag-patterns,llm-gateway,mcp-servers}.md`),
and `b7-2-scaffolder` (56 templates + scaffold-plan + verify-then-pin'd
Rust backbone, archived 2026-06-21). But an adopter evaluating the
RAG archetype has **no concrete artefact** to inspect, exactly as the
audit roadmap flagged for the flagship before `c1-reference-project`:

> Le nouvel utilisateur n'a aucun moyen de voir à quoi ressemble une
> **bonne** proposal, un **bon** specs.md delta, un **bon** design avec
> ADRs — *pour l'archétype RAG spécifiquement*.

`examples/forge-fsm-example/` (delivered by `c1-reference-project`)
demonstrates the **full-stack-monorepo** archetype. It does NOT
demonstrate the RAG-specific surfaces that are the whole point of
`ai-native-rag`:

1. The **RAG pipeline** (chunking → embeddings → hybrid retrieval
   vector+BM25+RRF → re-ranking → pgvector HNSW) — `rag/` module.
2. The **MCP server** (rmcp `search` tool, dual transport stdio/HTTP,
   OAuth→Zitadel) — `mcp/` module.
3. The **LLM gateway** proxy (prompt-audit IX.6, token budget +
   kill-switch, Article XI.5 non-AI fallback, tier-aware refusal hooks)
   + the **Qwik web-public** **streaming** RAG query UI (progressive
   token render via `b7-10-streaming`'s `QueryStream`/`queryStream`
   contract, degrading to unary `Query` on fallback) with the
   `fallbackUsed` indicator.

Without a RAG reference, every claim the archetype makes (Article XI
AI-First materialisation, the EU-sovereign tier-aware embeddings, the
`embeddings-pipeline` + `prompt-audit` phases) is abstract. The
archetype's 56 templates and 35 cargo tests are **internal**
validation; external validation needs a project an adopter can clone,
read, and reproduce — the RAG sibling of `forge-fsm-example`.

This brick (#8 of the 9-brick B.7 chain) closes that gap: a
`forge-rag-example/` reference project with **3 archived demo
application changes** illustrating the RAG pipeline end-to-end.

## Solution

Build a **reference project** under `examples/forge-rag-example/`,
scaffolded from the `ai-native-rag/1.0.0` templates (rendered via
`overlay.sh` — the renderer `b7-2-scaffolder` established for this
archetype, ADR-B7-2-007), with **3 archived demo application changes**
that demonstrate every RAG-specific surface and the AI-First pipeline.

This change **mirrors `c1-reference-project`'s shape** for the RAG
archetype, reusing the example-tree machinery c1 already shipped:

- The `examples/` directory, its meta-`README.md`, the skip-guards in
  `verify.sh` / `constitution-linter.sh`, the `.gitignore` example
  entries, and the `example` CI job already exist (FR-EX-001..010,
  FR-GL-026..028, FR-CI-012). **b7-7 reuses them** — it does NOT
  re-create the machinery, only adds a second example tree under it.

### Why `examples/` inside the Forge repo (settled by c1, ADR-001)

`c1-reference-project` already resolved the hosting decision: examples
live as committed trees under `examples/` in the Forge repo (Option B),
co-located with the framework so archetype evolution and example
content stay in lock-step. `examples/README.md` was explicitly
designed (FR-EX-003) to list **multiple** examples as a table — it
already says "one example today" pending sibling archetypes. b7-7 adds
the second row. No hosting decision is re-litigated.

### What ships

1. **`examples/forge-rag-example/`** — a fully-rendered
   `ai-native-rag/1.0.0` project tree, produced by `overlay.sh` against
   the `b7-2-scaffolder` scaffold-plan, then committed verbatim.
   Includes: `.forge/` (with `scaffold-manifest.yaml`), `.claude/`,
   `backend/` (Rust workspace — `rag/`, `mcp/`, `llm_gateway/`,
   `bin-server/`), `frontend/web-public/` (Qwik), `infra/`
   (k8s + pgvector + observability), `shared/protos/v1/rag/`,
   `Taskfile.yml`, `docker-compose.dev.yml`, `CLAUDE.md`, `README.md`,
   `.gitignore`, `.forge.yaml` declaring `schema: ai-native-rag`.

2. **3 archived demo application changes** under
   `examples/forge-rag-example/.forge/changes/`:
   - **`demo-001-doc-ingestion`** (single-layer backend) — document
     ingestion + RAG query: chunking, embeddings via the `Embedder`
     trait, pgvector HNSW upsert, hybrid retrieval (vector+BM25+RRF),
     re-ranking. Full TDD cycle + cucumber-rs BDD (ingest → query →
     grounded answer). **Demonstrates**: the `rag/` pipeline, the
     `embeddings-pipeline` phase, Rust hexagonal layering, proto-first
     `RagService.Query`.
   - **`demo-002-mcp-search-tool`** (single-layer backend) — expose
     the RAG retriever as an MCP `search` tool (rmcp `#[tool_router]`,
     stdio + streamable-HTTP transports, schema-validated input,
     least-privilege). Widget-free; cucumber-rs BDD over the tool
     invocation. **Demonstrates**: the `mcp/` module, dual transport,
     OAuth→Zitadel wiring, MCP security posture from `mcp-servers.md`.
   - **`demo-003-rag-query-ui`** (multi-layer frontend + backend) — a
     Qwik web-public **streaming** RAG query screen consuming
     `b7-10-streaming`'s `RagService.QueryStream` server-stream through
     the LLM gateway, **progressively rendering answer tokens** via the
     `queryStream` client helper, alongside the grounding sources and
     the Article XI.5 `fallbackUsed` indicator. When the AI upstream is
     unavailable or the budget is exceeded, the stream **degrades to the
     unary `RagService.Query` path** (consistent with b7-10's
     ADR-B7-10-001 — "unary retained as degradation target"). Triggers
     the **Janus** cross-layer orchestrator (≥ 2 layers).
     **Demonstrates**: multi-layer change with `layers: [backend,
     frontend]`, per-layer designs / tasks, the streaming gateway
     prompt-audit + fallback path, the AI-First `prompt-audit` gate, BDD
     via Qwik component test. **Requires `b7-10-streaming` to have
     landed** (hard dependency — see Impact + design ADR-B7-7-002).

3. **`examples/forge-rag-example/README.md`** — top-of-tree navigation
   (same 4 H2 sections as `forge-fsm-example/README.md` per FR-EX-002):
   How this example was built / What's in here / Demo changes /
   Reproducing this example. Documents the `candidate` /
   `scaffoldable: false` caveat (rendered via `overlay.sh`, not the
   refusing CLI) and the "no Flutter surface" known-gap (ADR-B7-2-006).

4. **`examples/README.md` second row** — append `forge-rag-example`
   to the existing examples table (FR-EX-003 was designed for multiple
   rows).

5. **`example` CI job extension** — the existing `example` job in
   `forge-ci.yml` (FR-CI-012) keeps its `examples/**` paths-filter but
   gains a second tree to gate: run `examples/forge-rag-example/`'s own
   `verify.sh` + `constitution-linter.sh`, and structurally parse the
   RAG archetype's templates. Mirrors the FSM steps already present.

6. **Test harness `b7-7.test.sh`** — validates the RAG example
   structure (scaffold-manifest present + `archetype: ai-native-rag`,
   3 demos follow naming + each has the 5 artefacts, demo-003 is
   multi-layer, the `example` CI job gates the RAG tree, the size
   budget holds). Mirrors `c1.test.sh`'s manifest pattern; registered
   in `forge-ci.yml`'s harness loop.

## Scope In

- The fully-rendered `examples/forge-rag-example/` tree (rendered via
  `overlay.sh` against the `ai-native-rag/1.0.0` scaffold-plan, then
  committed verbatim).
- 3 archived demo changes (`demo-001-doc-ingestion`,
  `demo-002-mcp-search-tool`, `demo-003-rag-query-ui` — the latter a
  **streaming** UI demo consuming `b7-10-streaming`'s
  `QueryStream`/`queryStream` contract) with all lifecycle artefacts
  (proposal, specs, design, tasks, features).
- `examples/forge-rag-example/README.md` (4 canonical H2 sections).
- One appended row in `examples/README.md`.
- Extension of the existing `example` job in `forge-ci.yml` to gate
  the RAG tree (paths-filter already covers `examples/**`).
- A `.forge/changes/MANIFEST.md` inside the RAG example listing the
  3 demos.
- Test harness `.forge/scripts/tests/b7-7.test.sh` + its forge-ci.yml
  harness-loop registration.
- A size-budget NFR for the RAG example tree (mirror NFR-EX-002).
- Append `b7-7` requirements to `.forge/specs/example-reference.md`
  (the consolidated `FR-EX-*` spec) at archive time.

## Scope Out (Explicit Exclusions)

- **No new example-tree machinery**. The skip-guards (FR-GL-026/027),
  the `.gitignore` entries (FR-GL-028), the `examples/README.md` file,
  and the `example` CI job (FR-CI-012) already exist from c1 — b7-7
  reuses them. Only the `example` job's per-tree steps are extended.
- **No archetype promotion**. `ai-native-rag` stays `candidate` /
  `scaffoldable: false`; promotion rides `b7-6-harness` (ADR-B7-1-002).
  The example is rendered via `overlay.sh`, not the refusing CLI.
- **The Qwik streaming transport itself** (SSE/WebTransport +
  `QueryStream`/`queryStream`) is delivered by `b7-10-streaming` (#7),
  NOT by b7-7. b7-7 **consumes** that contract in demo-003 (which is
  why b7-7 is a hard dependent of b7-10 — it lands AFTER b7-10). b7-7
  ships no new transport; it demonstrates the one b7-10 provides.
- **No Flutter mobile surface** — the archetype is web-public only
  (ADR-B7-2-006); no Flutter demo.
- **No AI-Act / DORA compliance demo** — those artefacts arrive in
  `b7-5-ai-act` (#6). The example references `compliance-tiers` where
  the gateway's tier-aware hooks appear, but ships no compliance demo.
- **No Pythia agent demo** (K.2 → `b7-pythia`).
- **No live LLM upstream calls in CI**. demo-001/002/003 exercise the
  pipeline with the local/fake embedder + a stubbed gateway upstream;
  the `example` CI job runs structural + own-gate checks only (no
  network, no `cargo build`, no `buf generate`), mirroring c1's
  parse-only `example` job (c1 ADR-006).
- **No 4th `specified`-only demo**. c1 shipped 3 archived + 1
  specified to demonstrate the in-flight `[NEEDS CLARIFICATION]` state;
  the §0.12 brick spec for b7-7 says **3 demos**. b7-7 ships 3 archived
  demos. Whether to add a 4th `specified` demo (to mirror c1's
  in-flight illustration) is recorded as an open question for design.

## Impact

- **Users affected**: every adopter evaluating the `ai-native-rag`
  archetype (major onboarding uplift); Forge maintainers (a second
  example to maintain alongside the archetype's evolution toward
  promotion in b7-6).
- **Technical impact**: Large. ~40-60 new files under
  `examples/forge-rag-example/` (the rendered tree), ~15-20 new files
  under the example's `.forge/changes/` (3 demos × 5 artefacts), 1 new
  harness `b7-7.test.sh`, 1 `example`-job extension + 1 harness-loop
  entry in `forge-ci.yml`, 1 appended row in `examples/README.md`.
  No archetype template, schema, standard, or CLI code is edited.
- **Dependencies**: `b7-1-schema`, `b7-2a-dispatch-register`,
  `b7-standards`, `b7-2-scaffolder` (all archived — provide the
  archetype templates + scaffold-plan + standards). `c1-reference-project`
  (archived — provides the example-tree machinery this brick reuses).
  **`b7-10-streaming` is a HARD dependency** (maintainer-ratified
  2026-06-22): demo-003's streaming UI consumes b7-10's
  `RagService.QueryStream` / `queryStream` contract, and the example
  tree must be rendered from the b7-10-extended templates — so **b7-7
  lands AFTER b7-10**. Soft relationship to `b7-6-harness` (promotion;
  b7-7 renders via overlay.sh and does not require promotion).
- **Risk level**: **Medium**.
  - The example tree is large; review burden non-trivial (mitigated by
    the c1 precedent — reviewers know the shape).
  - **Shared-file edit to `forge-ci.yml`** (the `example` job +
    harness loop) touches the same regions `b7-10-streaming` edits.
    Because b7-7 now lands **after** b7-10 (hard dep), **b7-10 merges
    first** and b7-7 rebases onto it. Mitigation: keep b7-7's edit
    additive and minimal (one extra gate block + one loop entry); the
    orchestrator owns the rebase order.
  - `ai-native-rag` is `candidate` — the example demonstrates a
    not-yet-`stable` archetype. Mitigation: the README states the
    candidate caveat explicitly; b7-6 promotion does not invalidate the
    rendered tree (the manifest records the scaffold-time version).

## Constitution Compliance (v2.0.0)

### Article I — TDD

The `b7-7.test.sh` harness follows the manifest pattern (RED first
against an empty `examples/forge-rag-example/`, GREEN once the tree +
demos exist). Each demo's product code ships TDD-conformant (every Rust
module has tests; the Qwik component has a component test). Each demo
archives its own RED→GREEN cycle.

### Article II — BDD

Every demo ships a `features/<demo>.feature` with realistic Gherkin:
demo-001 covers ingest → query → grounded-answer + the XI.5
fallback path; demo-002 covers the MCP `search` tool happy + bounded
paths; demo-003 covers the streaming Qwik query UI happy path
(progressive token render via `queryStream`) + the `fallbackUsed`
path (stream degrades to unary `Query`).

### Article III — Specs Before Code

Every demo has a complete proposal → specs → design → tasks pipeline.
The example **is** the demonstration of Article III for the RAG
archetype. `[NEEDS CLARIFICATION]` markers (III.4) are used wherever a
genuine ambiguity exists in a demo's spec.

### Article IV — Semantic Deltas

Each demo's specs.md uses ADDED / MODIFIED / REMOVED delta format.
demo-003 (multi-layer) demonstrates per-layer delta semantics with FR
IDs prefixed by layer (`FR-BE-*`, `FR-FE-*`).

### Article V — Conformance Gate

The example's own gates (its `verify.sh`, `constitution-linter.sh`) all
pass; the extended `example` job in `forge-ci.yml` enforces this on PRs
touching `examples/**`.

### Article VII — Rust Architecture

demo-001 + demo-002 follow the archetype's Rust layering (axum +
Connect + the `rag`/`mcp`/`llm_gateway` modules). `unwrap()`/`panic!()`
prohibited in production paths.

### Article IX.6 — Prompt Audit

demo-003 exercises the LLM gateway's prompt-audit span across the
streaming path (each `QueryStream` exchange is audited). The AI-First
`prompt-audit` gate (FR-B7-1-023) is visible in the demo's lifecycle.

### Article XI — AI-First

This is the **first example to materialise Article XI** (c1 deferred
it). demo-001 exercises XI.5 (the non-AI/degraded embeddings fallback)
+ XI.6 (local in-process path keeps text in-process); demo-003 surfaces
the XI.5 `fallbackUsed` indicator in the UI, where the streaming
`QueryStream` path degrades to the unary `Query` path. The `ai_brainstorm` →
`embeddings-pipeline` → `prompt-audit` phases (the archetype's
AI-First flow) are demonstrated across the three demos.

---

## Open Questions for the design phase

1. **Build-now-via-overlay vs sequence-after-b7-6 promotion.** The
   archetype is `candidate` / `scaffoldable: false`, so the CLI refuses
   (exit 3). `b7-2-scaffolder` established that the archetype renders
   via `overlay.sh` directly (its L2 harness does exactly this).
   Recommendation: build the example **now via `overlay.sh`** (not
   gated on b7-6), exactly as `b7-2` validated the templates. To be
   ratified as an ADR. See `open-questions.md` Q-1.

2. **3 archived demos vs 3 archived + 1 specified.** §0.12 says "3
   demos". c1 shipped 3 archived + 1 specified to illustrate the
   in-flight state. Recommendation: ship **3 archived** to honour the
   brick spec; record a future `b7-7-followup` option for a specified
   demo. See `open-questions.md` Q-2.

3. **Which demo is the multi-layer (Janus) one.** Recommendation:
   demo-003-rag-query-ui (`[backend, frontend]`) — it naturally spans
   the gateway (backend) + the Qwik UI (frontend). See `open-questions.md` Q-3.

---

**Gate**: Proposal created at `.forge/changes/b7-7-example/proposal.md`.
Review and confirm before proceeding to → `/forge:specify b7-7-example`.
