# Proposal: b7-pythia

<!-- Created: 2026-06-22 -->
<!-- Schema: default -->
<!-- Audit: K.2 (docs/new-archetypes-plan.md §9 line 2665 + §6.2 B.7.4 line 2585 — Pythia AI/RAG specialist agent) -->
<!-- Audit: B.7.4 (docs/new-archetypes-plan.md §6.2 — Pythia agent for ai-native-rag) -->
<!-- Precedent: .forge/changes/k3-demeter/ (K.3 Demeter — specialist persona + Janus delta + standard + harness + CLAUDE.md row) -->

## Problem

`docs/new-archetypes-plan.md` mandates a new Forge specialist agent for the
`ai-native-rag` archetype:

- §9 line 2665 (K-modules table): **K.2 — Pythia (AI/RAG)** — *"Embeddings,
  pgvector tuning (HNSW `ef_search`), MCP servers, prompt audit"* — archetype
  `ai-native-rag`, effort `M`.
- §6.2 line 2585 (B.7.4): *"Nouvel agent **Pythia** (K.2) : pilote embeddings
  pipeline, tune pgvector (HNSW `ef_search`), MCP servers, prompt audit."*
- §0.12 brick table line 2022: brick **#4 `b7-pythia` — agent K.2 (patron
  `k3-demeter`) — ⏳ pending**.

The `ai-native-rag` archetype now has a scaffolder backbone (`b7-2-scaffolder`,
archived 2026-06-21 — 56 templates: RAG pipeline, in-repo LLM gateway proxy, MCP
servers, Qwik UI) and three pattern standards (`b7-standards`, archived
2026-06-13 — `global/{rag-patterns,llm-gateway,mcp-servers}.md`). What it does
**not** have is a **specialist agent** to drive the AI-specific tuning and audit
work those templates leave to the adopter: choosing chunk sizes, tuning pgvector
HNSW `ef_search` against a labelled eval set, sizing the context window, wiring
the prompt-audit span, hardening MCP tools to least-privilege, and gating the
mandatory non-AI fallback (Article XI.5).

Today none of this exists as an agent:

- No `.claude/agents/<pythia>.md` persona for the AI/RAG specialist is on disk.
  The roadmap references the agent by name (§9 + §6.2) but no agent file backs
  the prose.
- The three `b7-standards` (`rag-patterns.md`, `llm-gateway.md`,
  `mcp-servers.md`) are **pattern documents** — they describe the patterns but
  name no agent that *owns* them. Compare: Demeter owns
  `data-stewardship-rules.md`; Panoptes owns observability; no agent owns the
  RAG/LLM/MCP standards.
- Janus (`cross-layer-orchestrator.md`) has no dispatch path for an AI/RAG
  review of a `≥ 2`-layer `ai-native-rag` change. Aegis (security) and Demeter
  (data-stewardship) run at Step 9; nothing runs an AI-specific pass.
- The repo `CLAUDE.md` agent-delegation table has no row routing AI/RAG tuning
  work to a specialist.

### Naming collision (BLOCKING — see Q-001)

**The name "Pythia" is already taken in the Forge agent roster.**
`.claude/agents/product-analyst.md` declares `# Agent: Product Analyst
(Pythia)` — the Greek oracle of Delphi, used for the product-analysis /
PRFAQ / Working-Backwards persona invoked during `/forge:explore` and
`/forge:propose`. The repo `CLAUDE.md` does NOT list Product-Analyst-Pythia
(it lists Oracle for AI features), but `forge-master.md` (lines 39, 143),
`product-analyst.md`, `commands/forge/onboard.md` (line 54), and
`commands/forge/propose.md` (line 31) all bind "Pythia" to the Product
Analyst.

Two distinct agents cannot share a name in a roster where dispatch is
name-based (`SendMessage to: "Pythia"` would be ambiguous; the CLAUDE.md
trigger table is keyed by persona name). This is a genuine requirements
ambiguity that the roadmap did not anticipate (the roadmap author picked
"Pythia" for K.2 in `ARCHITECTURE-TARGET §9.2` apparently unaware the name was
already consumed by the Product Analyst). Per Article III.4 this MUST NOT be
silently resolved — it is logged as **Q-001** in `open-questions.md` and is the
single blocking open question of this change.

This change closes the agent gap **at the spec layer only**. The persona file,
the Janus delta, the standards-index touch, the CLAUDE.md row, and the test
harness are reserved for the follow-up `/forge:implement b7-pythia` invocation.

## Solution

A single coordinated specialist-agent change, mirroring the `k3-demeter`
precedent layout but **without** a scanner script: Pythia (K.2) is an
**advisory / tuning** specialist (like Panoptes the observability specialist),
not a deterministic-scanner agent (like Demeter). The plan §9 K.2 row scopes
Pythia to *tuning* + *audit*, not to a reproducible deny-list scan. No
`bin/forge-*-scan.sh`, no `.forge/data/*.yml` deny-list, no JSON-report exit-code
contract.

### K.2.a — Pythia persona (`.claude/agents/<name>.md`)

A new agent file authored in the existing Forge specialist style (compare
`observability-specialist.md` / Panoptes, `security-auditor.md` / Aegis,
`demeter.md` / Demeter). The persona name is **parameterised pending Q-001**
(recommended default: keep the roadmap name **Pythia** for the K.2 AI/RAG agent
and **rename the existing Product-Analyst persona** to a non-colliding oracle
name — see Q-001 resolution recommendation). The file declares:

- **Persona** — name (pending Q-001), role (AI/RAG specialist for
  `ai-native-rag`), style (eval-driven, evidence-first, fallback-mandatory).
- **Purpose** — embeddings pipeline tuning, pgvector HNSW tuning, MCP server
  hardening, prompt-audit wiring; cites K.2 + B.7.4 + the three b7-standards it
  consumes.
- **Checklists** — one H3 per responsibility area, mirroring the Aegis/Demeter
  greppable `[ ]`-item style: **Embeddings & Retrieval**, **pgvector HNSW
  Tuning**, **MCP Server Hardening**, **Prompt Audit & Fallback**.
- **Output: RAG Readiness Report** — a structured advisory report (status
  `READY` / `TUNING-NEEDED` / `BLOCKED`) mirroring the Demeter/Aegis report
  shape (Summary table + findings + cleared items), but advisory not
  policy-refusal.
- **Recommendation catalogue** — `K2-RULE-NNN` namespace (per the `<MODULE>-RULE-NNN`
  format ADR-J8-004 established and K3-RULE-* inherited), seed catalogue
  covering the tuning/audit checks.
- **Integration** — how Janus dispatches Pythia for `ai-native-rag` cross-layer
  changes; relationship to Oracle (AI-First brainstorm — Oracle defines the
  capability/fallback at proposal time, Pythia tunes the realised pipeline at
  design/review time); relationship to Demeter (Demeter owns dependency
  jurisdiction + DPA; Pythia owns AI-pipeline tuning — disjoint); relationship
  to Vulcan/Hera (Pythia advises, the layer orchestrators implement).
- **Anti-hallucination protocol** — `[NEEDS CLARIFICATION:]` emission when a
  tuning target is unspecified (no labelled eval set, undeclared embedding
  model, missing tier) consistent with Article III.4.

### K.2.b — Standards-index ownership touch (NO new standard)

Unlike K.3 (which authored a brand-new `data-stewardship-rules.md`), Pythia does
**NOT** author a new standard — the three pattern standards it owns already
exist (`b7-standards`, archived 2026-06-13). The K.2.b deliverable is the
minimal touch to make Pythia discoverable through the standards-injection
mechanism:

- Extend the `triggers:` lists of the existing `global/{rag-patterns,
  llm-gateway,mcp-servers}` entries in `.forge/standards/index.yml` with a
  `pythia` keyword (and `ef-search`, `embeddings-tuning` as relevant) so the
  agent is reachable via trigger. This is an **additive edit** to existing
  entries, NOT a new index entry. Locked at design (ADR).

### K.2.c — Janus + CLAUDE.md dispatch integration

- `.claude/agents/cross-layer-orchestrator.md` (Janus) gains a one-line
  **Dispatch Table** row routing AI/RAG-specialist work to Pythia, plus a
  surgical integration into the relevant workflow pass. **Collision note**:
  this file is co-edited by sibling brick `b7-9-janus-ai` (J.8.c — runtime AI
  refusal rules). The deltas MUST be disjoint (see `design.md` collision
  section): Pythia touches the **Dispatch Table** + a **design/tuning** pass;
  `b7-9-janus-ai` touches the **Forbidden archetypes & combinations** J8-RULE
  catalogue (scaffold-time refusal). They do not overlap by section.
- The repo `CLAUDE.md` agent-delegation table gains one new row for the AI/RAG
  specialist. **Collision note**: `b7-9-janus-ai` may also touch `CLAUDE.md`
  (Janus compatibility note). Keep the Pythia delta a single table row in the
  delegation table; flag the file overlap in design.

## Scope In

- New persona file `.claude/agents/<pythia-name>.md` (≈ 200–280 LOC, same
  density as `observability-specialist.md` / `demeter.md`). Exact filename and
  persona name locked at design after Q-001 resolves.
- New `K2-RULE-NNN` recommendation catalogue (namespace allocation per the
  ADR-J8-004 `<MODULE>-RULE-NNN` extension protocol; disjoint from J8-RULE-*,
  K3-RULE-*).
- Additive `triggers:` edits to the three existing `global/{rag-patterns,
  llm-gateway,mcp-servers}` entries in `.forge/standards/index.yml`.
- One-line Janus Dispatch-Table row + a surgical workflow-pass integration in
  `.claude/agents/cross-layer-orchestrator.md`.
- One-line repo `CLAUDE.md` agent-table row.
- Test harness `.forge/scripts/tests/b7-pythia.test.sh` (grep-based L1 + 1 L2
  fixture, mirrors `k3.test.sh` layout), registered in `.github/workflows/forge-ci.yml`.
- Doc updates: `CHANGELOG.md` `## [Unreleased]` entry; agent-catalogue doc entry
  if one exists (located at design).

## Scope Out (Explicit Exclusions)

- **NOT** a scanner script. Pythia is advisory/tuning (plan §9 K.2 — "tune
  pgvector", "MCP servers", "prompt audit"), not a deterministic deny-list
  scanner. No `bin/forge-pythia-*.sh`, no `.forge/data/*.yml`, no JSON-report
  exit-code contract. (This is the principal divergence from the `k3-demeter`
  precedent and is justified by ADR at design.)
- **NOT** a new standard file. The three RAG/LLM/MCP pattern standards already
  exist (`b7-standards`). Pythia consumes them; it does not re-author them.
- **NOT** the runtime Janus AI refusal rules (J.8.c — Vertex/Bedrock refusal,
  T3 ⇒ Mistral-EU/vLLM). Those are sibling brick `b7-9-janus-ai` (#5). Pythia
  REFERENCES the tier-aware posture (`compliance-tiers.md` / `llm-gateway.md`)
  but ships no J8-RULE.
- **NOT** the AI-Act / DORA compliance artefacts (`b7-5-ai-act`, #6 / Themis
  K.5). Pythia's prompt-audit checklist references IX.6 transparency but ships
  no regulatory artefact.
- **NOT** the scaffolder templates or the candidate→stable promotion
  (`b7-2-scaffolder` archived; `b7-6-harness` for promotion). Pythia does not
  edit `templates/ai-native-rag/`, the schema, or the wrapper.
- **NOT** the Qwik streaming transport (`b7-10-streaming`) or the example
  project (`b7-7-example`).
- **NOT** a rename of the existing Product-Analyst-Pythia in *this* change
  unless Q-001 resolves that way at design. The persona name is parameterised;
  the change name `b7-pythia` is stable regardless (it names the brick, not the
  persona).
- **NOT** the `.claude/agents/<name>.md` file itself in this PR. **This change
  is spec-only.** The persona file is the GREEN state of `/forge:implement
  b7-pythia`, not of `/forge:specify` / `/forge:design` / `/forge:plan`.

## Impact

- **Users affected**:
  - Adopters of the `ai-native-rag` archetype gain a named specialist that
    drives embeddings/retrieval tuning, pgvector HNSW tuning, MCP hardening, and
    prompt-audit/fallback wiring — the work the `b7-2-scaffolder` templates left
    as `#[cfg(test)]`-scaffolded TODO.
  - Janus gains an AI/RAG dispatch path for `ai-native-rag` cross-layer changes.
  - No change for adopters of other archetypes (Pythia is `ai-native-rag`-scoped).
- **Technical impact**: ≈ 1 new file (persona) + 1 new harness + ≈ 4 modified
  (Janus dispatch + workflow pass, standards index triggers, repo CLAUDE.md row,
  CHANGELOG, forge-ci.yml matrix). No scanner, no data file, no new standard.
  **Effort `M`** per `new-archetypes-plan` §1.4 / §9 row K.2.
- **Dependencies**:
  - `b7-standards` (archived 2026-06-13) — ships the three pattern standards
    Pythia owns/consumes.
  - `b7-2-scaffolder` (archived 2026-06-21) — ships the templates whose tuning
    Pythia drives (RAG pipeline / LLM gateway / MCP servers).
  - `k3-demeter` (archived 2026-05-12) — precedent for the persona + Janus delta
    + harness + CLAUDE.md row layout; source of the `<MODULE>-RULE-NNN`
    namespace convention Pythia's `K2-RULE-*` inherits.
  - `j8-janus-rules` — ADR-J8-004 rule-ID format.
  - No new external dependency. No code, no pins.
- **Risk level**: **Low → Medium**. The persona file is pure documentation. The
  only meaningful risk is the **Q-001 name collision** — shipping a second
  "Pythia" would break name-based dispatch. Mitigated by treating Q-001 as a
  blocking gate (status cannot flip to `implemented` until resolved) and by
  parameterising the persona name through specs/design.
- **Shared-file collision risk** (sibling bricks): `cross-layer-orchestrator.md`
  and repo `CLAUDE.md` are co-edited by `b7-9-janus-ai`. Mitigated by disjoint
  sectioning (Pythia → Dispatch Table + design pass; b7-9 → J8-RULE forbidden
  catalogue). Detailed in `design.md` § "Shared-file collision with sibling
  bricks".

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. `tasks.md` Phase 1 writes
`b7-pythia.test.sh` with all L1 + L2 stubs returning `_not_implemented` (full
RED witness) before any persona content is authored. Phase 2+ implements one
cluster at a time, flipping tests GREEN.

### Article II — BDD

The user-facing flow (Janus dispatches Pythia for an `ai-native-rag`
cross-layer change and receives a RAG Readiness Report) gets a Given/When/Then
scenario in `specs.md`. Pythia is an advisory agent, so the scenarios assert
report shape + dispatch wiring, not a CLI exit code.

### Article III — Specs Before Code

Confirmed: `/forge:specify` writes `specs.md` with the `FR-K2-PYT-*` namespace
before any implementation. This change is spec-only.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

The **name collision (Q-001)** is the canonical Article III.4 case: a genuine
requirements ambiguity the roadmap did not resolve. It is logged in
`open-questions.md` and BLOCKS the flip to `implemented`. Q-002 (RULE namespace
seed size) and Q-003 (advisory-vs-scanner shape) are also tracked; both are
resolvable at design.

### Article IX.6 — AI Feature Observability

Pythia ENFORCES IX.6 at design/review time: its Prompt Audit checklist asserts
the gateway emits the prompt-audit span (model / tenant / tier / token counts /
latency / fallback flag) per `llm-gateway.md`. Pythia does not itself emit OTel
(it is a design/review-time agent, not a runtime component).

### Article XI — AI-First Design

- **XI.1 (Agent-Native)** — Pythia is a first-class agent persona file.
- **XI.3 (Schema-Driven)** — Pythia's output is a structured advisory report;
  it consumes the schema-driven RAG/MCP patterns, recommends no opaque
  AI-generated artefact.
- **XI.5 (Mandatory Fallback)** — Pythia's Prompt Audit & Fallback checklist
  asserts every LLM-backed feature has a tested non-AI fallback (RAG returns
  ranked source documents). This is the single most important gate Pythia owns.
- **XI.6 (Privacy / Data Minimisation)** — Pythia's Embeddings checklist asserts
  PII minimisation before chunks reach an embedding/LLM provider.

### Article XII — Governance

Pythia ENFORCES the AI-First posture (Article XI) + the EU sovereignty posture
encoded in `compliance-tiers.md` + `llm-gateway.md`. It does **not amend** any
constitutional article. It authors no new standard (consumes existing
`b7-standards`).

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers in this `proposal.md`: the name
collision is surfaced narratively above and formalised in `open-questions.md`.
Three open questions raised at this phase, all tracked in `open-questions.md`:

- **Q-001 (BLOCKING)** — Pythia name collision: the K.2 AI/RAG agent and the
  existing Product Analyst both want the name "Pythia". Which agent keeps it,
  and what is the other named? Resolution recommendation drafted; final call is
  the maintainer's (it touches an already-shipped persona + 4 referencing
  files).
- **Q-002** — `K2-RULE-NNN` seed catalogue size: pre-allocate vs grow
  incrementally (mirror the K3-RULE Q-003 decision — incremental). Resolvable at
  design.
- **Q-003** — Advisory-report shape vs Demeter-style scanner: confirm Pythia
  ships NO scanner (advisory only, like Panoptes), diverging from the
  scanner-heavy `k3-demeter` precedent. Resolvable at design via ADR.
