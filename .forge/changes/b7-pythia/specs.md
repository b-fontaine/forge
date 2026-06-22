# Specifications: b7-pythia

<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-K2-PYT-*` / `NFR-K2-PYT-*` / `ADR-K2-*`. **Constitution** :
v2.0.0. No amendment required (K.2 introduces a new advisory specialist agent ;
existing articles unchanged ; it ENFORCES Articles IX.6 + XI, does not amend
them).

> **Persona-name placeholder** : throughout this spec the persona is referenced
> as `<pythia-name>` (file) / `<Pythia-Name>` (display). The literal name is
> BLOCKED on Q-001 (name collision with the existing Product-Analyst-Pythia) and
> is locked by ADR-K2-001 at design after maintainer ratification. The harness
> asserts file + anchors, not the literal name, so the FRs are
> name-resolution-agnostic until the ADR locks the value.

## Source Documents

| Field             | Value                                                                                                                                                                  |
|-------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Audit base**    | `K.2` (`docs/new-archetypes-plan.md` §9 line 2665 — K-modules table) + `B.7.4` (`docs/new-archetypes-plan.md` §6.2 line 2585 — Pythia agent for ai-native-rag)        |
| **Precedent**     | `.forge/changes/k3-demeter/` (K.3 Demeter — persona + Janus delta + standard + harness + CLAUDE.md row layout) ; `.claude/agents/observability-specialist.md` (Panoptes — advisory-specialist shape, NO scanner) |
| **Plan ref**      | `docs/new-archetypes-plan.md` §0.12 brick table line 2022 (brick #4) ; §6.2 line 2585 (B.7.4) ; §9 line 2665 (K.2) ; `docs/ARCHITECTURE-TARGET.md` §9.2 (agent introduction) |
| **Standards owned/consumed** | `global/rag-patterns.md` (b7-standards) ; `global/llm-gateway.md` (b7-standards) ; `global/mcp-servers.md` (b7-standards) ; references `global/compliance-tiers.md` (I.2) + `global/forbidden-components-rules.md` (I.3) for the tier-aware posture |
| **Pattern reuse** | `j8-janus-rules` ADR-J8-004 (`<MODULE>-RULE-NNN` rule-ID format) ; `k3-demeter` ADR-K3-005 (incremental rule growth) ; `k3-demeter` ADR-K3-007 (Janus delta-based modification per Article IV.1) |
| **Schema ref**    | `.forge/schemas/ai-native-rag/1.0.0.yaml` (b7-1-schema — `embeddings-pipeline` + `prompt-audit` phases ; `ai_specifics.fallback_mandatory` ; the pipeline Pythia tunes) |
| **Scaffold ref**  | `b7-2-scaffolder` (archived 2026-06-21 — RAG pipeline / in-repo LLM gateway proxy / MCP server templates Pythia advises on) |
| **Collision**     | `.claude/agents/product-analyst.md` (existing `Pythia` — Q-001) ; `b7-9-janus-ai` sibling brick co-edits `cross-layer-orchestrator.md` + `CLAUDE.md` (disjoint sections — design § collision) |
| **Constitution**  | Article IX.6 (AI feature observability — prompt audit) ; Article XI.1/XI.3/XI.5/XI.6 (AI-First — agent-native, schema-driven, mandatory fallback, PII minimisation) |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Pythia persona file (FR-K2-PYT-001 → 008)

##### FR-K2-PYT-001 — Persona file location

A new persona file MUST exist under `.claude/agents/<pythia-name>.md` at the path
locked by ADR-K2-001 (design phase, after Q-001 resolves). The file follows the
`.claude/agents/<name>.md` flat-layout convention used by all top-level Forge
specialists (e.g. `observability-specialist.md`, `security-auditor.md`,
`demeter.md`). The filename and the persona's display name are BLOCKED on Q-001.

##### FR-K2-PYT-002 — Persona section

The file MUST start with an H1 `# Agent: AI/RAG Specialist (<Pythia-Name>)` and a
`## Persona` H2 declaring:
- **Name** : `<Pythia-Name>` (locked by ADR-K2-001).
- **Role** : AI/RAG specialist for the `ai-native-rag` archetype — drives
  embeddings/retrieval tuning, pgvector HNSW tuning, MCP server hardening, and
  prompt-audit/fallback wiring.
- **Style** : Eval-driven, evidence-first, fallback-mandatory. Mirrors the
  Aegis/Demeter stylistic pattern (every recommendation carries a severity,
  specific evidence, and an actionable tuning step). Gates changes on a labelled
  eval set, not vibes (per `rag-patterns.md` § Evaluation).

##### FR-K2-PYT-003 — Purpose section

A `## Purpose` H2 MUST describe Pythia's four responsibilities and explicitly
cite the source audit items (K.2 + B.7.4) and the three b7-standards Pythia
consumes (`rag-patterns.md`, `llm-gateway.md`, `mcp-servers.md`). It MUST state
that Pythia is `ai-native-rag`-scoped (not invoked on other archetypes).

##### FR-K2-PYT-004 — Checklists section

A `## Checklists` H2 MUST host at least four H3 sub-sections, each in the
Aegis/Demeter greppable `[ ]`-item style with `Verify:` / `Check:` / `Exception:`
annotations (≥ 5 `[ ]` items per sub-section):
- **Embeddings & Retrieval** (chunking strategy, embedding model tier-gating,
  hybrid vector + BM25 + RRF, distance-op matching) — consumes `rag-patterns.md`.
- **pgvector HNSW Tuning** (`ef_search` recall/latency trade-off,
  `iterative_scan` for filtered queries, opclass↔distance-op match, eval-gated
  tuning) — consumes `rag-patterns.md` § pgvector HNSW tuning.
- **MCP Server Hardening** (least-privilege tools, input validation, no arbitrary
  execution, OAuth 2.1 → Zitadel/Envoy) — consumes `mcp-servers.md`.
- **Prompt Audit & Fallback** (prompt-audit span per IX.6, tenant budgets, kill
  switch, mandatory non-AI fallback XI.5, PII minimisation XI.6) — consumes
  `llm-gateway.md`.

##### FR-K2-PYT-005 — Output report format

An `## Output: RAG Readiness Report` H2 MUST declare the report shape, mirroring
the Demeter/Aegis report template but **advisory** (not policy-refusal):
- A `Summary` table with severity counts (`Blocking` / `Concern` / `Advisory` /
  `Cleared`).
- A `Findings` section with per-finding entries citing `[SEVERITY] <K2-RULE-NNN>:
  <title>`, `Category`, `Location`, `Evidence`, `Recommendation`, `Verification`.
- A `Cleared Items` section.
- An overall status line: `BLOCKED` / `TUNING-NEEDED` / `READY`
  (`BLOCKED` only when the XI.5 mandatory-fallback gate fails — the single
  Blocking-severity case ; `TUNING-NEEDED` on any Concern ; `READY` otherwise).

##### FR-K2-PYT-006 — Recommendation catalogue section

A `## Recommendation Catalogue` H2 MUST enumerate the seed `K2-RULE-*` rules
(≥ 5 rules, see Cluster 5). Each rule MUST cite: (a) trigger condition, (b)
severity (`Advisory` / `Concern` / `Blocking`), (c) evidence pattern, (d) tuning
recommendation, (e) cross-link to the relevant b7-standard or constitutional
article.

##### FR-K2-PYT-007 — Integration section

A `## Integration` H2 MUST describe:
- How Janus dispatches Pythia for `ai-native-rag` cross-layer changes (cross-link
  to `cross-layer-orchestrator.md` — exact pass locked by ADR-K2-004).
- The relationship to **Oracle** (AI-First Brainstorm): Oracle defines the AI
  capability + the mandatory fallback at proposal/brainstorm time; Pythia tunes
  the *realised* pipeline at design/review time. Disjoint phases.
- The relationship to **Demeter** (K.3): Demeter owns dependency-jurisdiction +
  DPA + tier classification; Pythia owns AI-pipeline tuning + prompt-audit +
  fallback. Disjoint surfaces (Demeter does NOT tune `ef_search`; Pythia does NOT
  scan `Cargo.lock` jurisdiction).
- The relationship to **Vulcan / Hera** (layer orchestrators): Pythia *advises*;
  Vulcan (Rust backend: RAG pipeline, LLM gateway, MCP) and Hera (Qwik frontend)
  *implement*. Pythia writes no application code.

##### FR-K2-PYT-008 — Anti-hallucination protocol

A `## Anti-Hallucination Protocol` H2 MUST state the Article III.4 contract:
when a tuning target is unspecified (no labelled eval set to tune `ef_search`
against, an undeclared embedding model, an undeclared compliance tier that gates
the provider), Pythia MUST emit `[NEEDS CLARIFICATION: <specific question>]` and
STOP — never guess a tuning value. It MUST NOT fabricate `ef_search` numbers,
chunk sizes, or recall@k targets absent an eval set.

---

#### Cluster 2 — Audit anchors + citations (FR-K2-PYT-010 → 011)

##### FR-K2-PYT-010 — Audit comment

The persona file MUST carry a top-of-file `<!-- Audit: K.2 (b7-pythia) -->`
HTML comment per the Forge audit-trail convention. A second
`<!-- Audit: B.7.4 (b7-pythia) -->` comment MUST be added (B.7.4 is the §6.2
plan item that mandates the agent).

##### FR-K2-PYT-011 — Source citations

The persona footer MUST cite the upstream sources that justify Pythia's
existence, with section + line refs (same convention as `demeter.md` footer):
- `docs/new-archetypes-plan.md` §9 line 2665 (K.2 row)
- `docs/new-archetypes-plan.md` §6.2 line 2585 (B.7.4)
- `docs/new-archetypes-plan.md` §0.12 brick table line 2022 (brick #4)
- `docs/ARCHITECTURE-TARGET.md` §9.2 (agent introduction)
- the three b7-standards owned/consumed.

---

#### Cluster 3 — Tuning-domain coverage (FR-K2-PYT-020 → 027)

These FRs pin *what* the checklists must cover, sourced verbatim from the
b7-standards Pythia consumes. Pythia MUST NOT redefine or contradict the
standards — it operationalises them as review-time checks.

##### FR-K2-PYT-020 — Chunking & embeddings coverage

The Embeddings & Retrieval checklist MUST cover: semantic-unit chunking with
token-budgeted overlap (≈10–20%), provenance metadata storage for citation, and
embedding normalisation matched to the distance op — per `rag-patterns.md` §
Chunking & embeddings.

##### FR-K2-PYT-021 — Embedding-model tier-gating

The checklist MUST assert the embedding-model choice is tier-gated: T3
(EU-strict) MUST use a self-hosted model or an EU-sovereign provider (Mistral on
Scaleway); OpenAI-direct embeddings are forbidden at T3 — per `rag-patterns.md`
§ EU sovereignty + `llm-gateway.md` § Tier-aware refusal. Pythia REFERENCES the
tier matrix (`compliance-tiers.md`) ; it does NOT restate it.

##### FR-K2-PYT-022 — Hybrid retrieval coverage

The checklist MUST cover hybrid search (pgvector similarity + Postgres full-text
BM25-like `ts_rank`, fused via Reciprocal Rank Fusion) and matching the distance
operator (`<->` L2 / `<=>` cosine / `<#>` inner product) to the embedding space
— per `rag-patterns.md` § Retrieval.

##### FR-K2-PYT-023 — pgvector HNSW `ef_search` tuning

The pgvector HNSW Tuning checklist MUST cover `SET hnsw.ef_search = N` (recall
vs latency), tuned per workload **against a labelled eval set** (recall@k /
nDCG), and `hnsw.iterative_scan` (`strict_order` / `relaxed_order` / `off`) for
filtered queries — per `rag-patterns.md` § pgvector HNSW tuning. This is the K.2
headline responsibility (plan §9 names "`ef_search`" explicitly).

##### FR-K2-PYT-024 — Re-ranking coverage

The checklist MUST cover coarse→exact two-stage re-ranking (binary-quantized
Hamming wide pass → exact distance re-order, optional cross-encoder) — per
`rag-patterns.md` § Re-ranking.

##### FR-K2-PYT-025 — MCP least-privilege + auth coverage

The MCP Server Hardening checklist MUST cover: one-capability-per-tool least
privilege, derived-`JsonSchema` + explicit-bounds input validation, no arbitrary
execution / no shell-out / path allow-listing, and OAuth 2.1 + PKCE → Zitadel
issuer with Envoy JWT edge validation — per `mcp-servers.md` § Security + §
Authentication.

##### FR-K2-PYT-026 — Prompt-audit span coverage (IX.6)

The Prompt Audit & Fallback checklist MUST assert the gateway emits a
prompt-audit record per LLM call (model / tenant / tier / prompt+completion token
counts / latency / provider / fallback-invocation flag) — per `llm-gateway.md` §
Prompt audit & observability + Article IX.6. PII MUST be redacted before logging
(XI.6).

##### FR-K2-PYT-027 — Mandatory-fallback gate coverage (XI.5)

The checklist MUST assert every LLM-backed feature has a defined, **tested**
non-AI fallback (e.g. RAG returns ranked source documents when generation is
unavailable), and a tenant-scoped budget + kill switch that degrade to the
fallback rather than hard-fail — per `llm-gateway.md` § Budgets/kill switch/
fallback + Article XI.5. This is the **only Blocking-severity** check Pythia
owns (a feature with no tested fallback is "not considered complete" per XI.5).

---

#### Cluster 4 — Standards-index + Janus + CLAUDE.md integration (FR-K2-PYT-080 → 086)

##### FR-K2-PYT-080 — Standards-index trigger additivity (NO new standard)

`.forge/standards/index.yml` MUST be edited **additively** to make Pythia
discoverable: the existing `global/rag-patterns`, `global/llm-gateway`, and
`global/mcp-servers` entries (the B.7.3 block, lines ~439-455) gain a `pythia`
trigger keyword (and `ef-search` / `embeddings-tuning` where apt). NO new index
entry is created — Pythia authors no new standard (it owns the three existing
ones). Exact keyword set locked by ADR-K2-005.

##### FR-K2-PYT-081 — No new standard file

This change MUST NOT create any new `.forge/standards/global/*.md` file. The
RAG/LLM/MCP pattern standards already exist (`b7-standards`). Asserted as a guard
so reviewers can confirm Pythia's "ownership" is by-reference, not by
re-authoring (diverges from K.3 which DID author `data-stewardship-rules.md`).

##### FR-K2-PYT-082 — Janus Dispatch-Table row

`.claude/agents/cross-layer-orchestrator.md` MUST gain a single new row in its
**Dispatch Table** (the H2 table at lines ~23-32 today), routing AI/RAG
specialist work to Pythia. The row MUST be placed **after** the Demeter row and
**before** the closing `---` of the table (the same insertion site convention
K.3 used for the Demeter row). Exact row text locked by ADR-K2-004.

##### FR-K2-PYT-083 — Janus workflow-pass integration

`.claude/agents/cross-layer-orchestrator.md` MUST integrate Pythia into the
relevant workflow pass via a **delta-based modification** (Article IV.1, mirrors
ADR-K3-007). The integration site is locked by ADR-K2-004 — candidate sites:
the **Step 3 design dispatch** (Pythia advises the per-layer RAG design for
`ai-native-rag` projects) or a dedicated note in the **Quality Gates** H2. The
delta MUST be surgical and MUST NOT touch the Step 9 Security &
Data-Stewardship narrative (that is Aegis + Demeter territory) nor the Forbidden
archetypes / J8-RULE catalogue (that is `b7-9-janus-ai` territory — see
collision note FR-K2-PYT-086).

##### FR-K2-PYT-084 — CLAUDE.md trigger registration

The repo-level `CLAUDE.md` agent-delegation table (lines ~61-71) MUST gain a new
row routing AI/RAG tuning work to the K.2 specialist. The row text is locked by
ADR-K2-001 (depends on the persona name). Placement: within the existing
delegation table, adjacent to the `AI features | Oracle` row (Pythia and Oracle
are the two AI-domain agents). The CLAUDE.md `## About Forge` / agent-table
already lists Oracle for AI features; this row adds the AI/RAG *tuning*
specialist as distinct from Oracle's *brainstorm* role.

##### FR-K2-PYT-085 — Scaffolding dispatch-table NOT edited

`.forge/scaffolding/dispatch-table.yml` MUST NOT be edited. Pythia is a
Janus-time / review-time advisory agent, not a scaffold-time init dispatcher (same
posture as Demeter per FR-K3-DEM-085). Asserted as a guard.

##### FR-K2-PYT-086 — No RULE-namespace collision

The `K2-RULE-*` namespace MUST NOT collide with `J8-RULE-*` (Janus forbidden
catalogue), `K3-RULE-*` (Demeter), or any other `<MODULE>-RULE-*` namespace. The
`<MODULE>-RULE-NNN` format (ADR-J8-004) makes collision syntactically impossible;
the spec asserts the invariant so reviewers can grep for it. **Sibling-brick
collision**: `b7-9-janus-ai` (J.8.c) will add `J8-RULE-*` AI refusal rules to the
Janus *Forbidden archetypes* catalogue — Pythia's `K2-RULE-*` are advisory
recommendations in the *persona file*, a disjoint surface. The two never share a
section nor a namespace.

---

#### Cluster 5 — Seed K2-RULE catalogue (FR-K2-PYT-120 → 125)

The seed K.2 recommendation catalogue per ADR-K2-002 (design — incremental, ~6
rules). Severity vocabulary: `Advisory` (tuning suggestion), `Concern`
(should-fix before production), `Blocking` (XI.5 fallback gate only).

##### FR-K2-PYT-120 — K2-RULE-001 — Embedding model not tier-gated

**Trigger**: the declared embedding provider is OpenAI-direct (or
Vertex/Bedrock) at compliance tier T3. **Severity**: `Concern` (cross-links to
the I.3 `forbidden-components` linter which is the *blocking* enforcement; Pythia
flags it at design time so it is caught before the linter fails CI).
**Recommendation**: switch to a self-hosted model or Mistral-on-Scaleway per
`rag-patterns.md` § EU sovereignty.

##### FR-K2-PYT-121 — K2-RULE-002 — HNSW `ef_search` untuned / no eval set

**Trigger**: pgvector HNSW index in use but `ef_search` left at default AND no
labelled eval set is present to tune against. **Severity**: `Advisory` (no eval
set) → emits `[NEEDS CLARIFICATION:]` rather than a fabricated number.
**Recommendation**: build a labelled retrieval eval set; tune `ef_search` for
recall@k vs latency per `rag-patterns.md` § pgvector HNSW tuning.

##### FR-K2-PYT-122 — K2-RULE-003 — Pure-vector retrieval (no hybrid)

**Trigger**: retrieval uses pgvector similarity only, no Postgres full-text /
BM1-like fusion. **Severity**: `Advisory`. **Recommendation**: add hybrid search
+ RRF for keyword-heavy / out-of-distribution recall per `rag-patterns.md` §
Retrieval.

##### FR-K2-PYT-123 — K2-RULE-004 — MCP tool over-privileged

**Trigger**: an MCP tool exposes more than one capability, shells out, evals, or
uses a path argument verbatim (no allow-list). **Severity**: `Concern`.
**Recommendation**: split into one-capability tools; validate inputs against the
derived `JsonSchema`; resolve paths against an allow-list per `mcp-servers.md` §
Security.

##### FR-K2-PYT-124 — K2-RULE-005 — Prompt-audit span missing (IX.6)

**Trigger**: an LLM gateway call path emits no prompt-audit record (model /
tenant / tier / token counts / latency / fallback flag). **Severity**: `Concern`.
**Recommendation**: emit the prompt-audit span per `llm-gateway.md` § Prompt
audit + Article IX.6; redact PII (XI.6).

##### FR-K2-PYT-125 — K2-RULE-006 — Mandatory fallback missing/untested (XI.5)

**Trigger**: an LLM-backed feature has no defined non-AI fallback, OR a fallback
exists but no test exercises it with the AI mocked to fail. **Severity**:
`Blocking` (the only Blocking rule — XI.5 says a feature with no tested fallback
"is not considered complete"). **Recommendation**: define + test the non-AI
fallback (RAG returns ranked source documents); wire the kill switch + budget to
degrade to it, not hard-fail.

---

### Non-Functional Requirements

#### NFR-K2-PYT-001 — Backward compatibility

This change is purely additive. Adopters not invoking Pythia (no `ai-native-rag`
project, no Janus AI-pass dispatch) MUST observe ZERO behavioural change. No
existing persona's behaviour changes — EXCEPT the Q-001 rename, which is a
maintainer-ratified identity edit tracked separately and gated by ADR-K2-001.

#### NFR-K2-PYT-002 — No application code, no scanner, no pins

Pythia is a `.claude/agents/` Markdown persona only. This change MUST NOT create
any `bin/forge-*.sh`, any `.forge/data/*.yml`, any `cli/src/**.ts`, any version
pin, any template, or any Rust/Dart/TS source. Asserted as a guard against
task-creep toward the scanner shape (which ADR-K2-003 explicitly rejects).

#### NFR-K2-PYT-003 — Article V audit trail

Every task tagged `[Story: FR-K2-PYT-XXX]` (Article V.1, enforced by
`f4-linter-extension`). Every Pythia finding carries a `K2-RULE-NNN` ID in the
report's structured shape.

#### NFR-K2-PYT-004 — Standards consumed, not amended

Pythia consumes `rag-patterns.md` / `llm-gateway.md` / `mcp-servers.md` verbatim
and MUST NOT edit, contradict, or re-author them. The only standards-layer touch
is the additive `triggers:` keyword in `index.yml` (FR-K2-PYT-080). No standard's
*content* changes.

#### NFR-K2-PYT-005 — No regression in sibling harnesses

`verify.sh`, `constitution-linter.sh`, `validate-standards-yaml.sh`, `j7`, `j8`,
`k3`, `b7-1`, `b7-2a`, `b7-3`, `b7-2` MUST remain GREEN. The `index.yml` edit is
additive (extends `triggers:` arrays) so `validate-standards-yaml.sh` /
`j7.test.sh` do not regress.

#### NFR-K2-PYT-006 — Shared-file edit disjointness

The edits to `cross-layer-orchestrator.md` and `CLAUDE.md` MUST be confined to
sections disjoint from `b7-9-janus-ai`'s edits (Pythia → Dispatch Table +
design/quality pass + delegation row ; b7-9 → Forbidden archetypes / J8-RULE
catalogue + Janus-compat note). Whichever brick lands second rebases its
surgical delta onto the first. Detailed in `design.md` § collision.

#### NFR-K2-PYT-007 — Name-resolution agnostic harness

The test harness MUST assert the persona *file presence* + *H2/H3 anchors* +
*K2-RULE anchors*, NOT the literal persona name, so the suite passes regardless
of how Q-001 resolves (the harness resolves the agent path from a single
variable locked at implementation once ADR-K2-001 fixes the name).

---

## BDD Acceptance Criteria

### Scenario 1 — Janus dispatches Pythia for an ai-native-rag cross-layer change

```gherkin
Given a project whose root .forge.yaml declares schema: ai-native-rag
And a change touching backend/ (RAG pipeline) and frontend/ (Qwik UI) — 2 layers
When Janus processes the cross-layer change
Then Janus dispatches to <Pythia-Name> for the AI/RAG specialist pass
And <Pythia-Name> returns a RAG Readiness Report with an overall status line
And the report's status is BLOCKED if and only if the XI.5 mandatory-fallback gate (K2-RULE-006) fails
```

### Scenario 2 — Mandatory-fallback gate blocks an untested feature (XI.5)

```gherkin
Given an ai-native-rag feature calls the LLM gateway for generation
And no test exercises a non-AI fallback with the AI mocked to fail
When <Pythia-Name> runs its Prompt Audit & Fallback checklist
Then the report contains 1 finding with rule_id "K2-RULE-006" and severity "Blocking"
And the overall status is "BLOCKED"
And the recommendation cites "define + test the non-AI fallback per Article XI.5"
```

### Scenario 3 — Untuned ef_search with no eval set emits NEEDS CLARIFICATION (III.4)

```gherkin
Given an ai-native-rag project uses a pgvector HNSW index with default ef_search
And no labelled retrieval eval set is present in the project
When <Pythia-Name> runs its pgvector HNSW Tuning checklist
Then it emits "[NEEDS CLARIFICATION: no labelled eval set — cannot tune ef_search without recall@k targets]"
And it does NOT fabricate an ef_search value
And the finding is recorded under rule_id "K2-RULE-002" severity "Advisory"
```

---

## Anti-Hallucination Pass

For each FR:

- **Testable** : every FR is asserted by at least one test in
  `b7-pythia.test.sh` (mapping captured in `tasks.md` `[Story: FR-K2-PYT-XXX]`
  tags during `/forge:plan`).
- **Unambiguous** : 3 open questions flagged — Q-001 (name collision, BLOCKING),
  Q-002 (RULE seed size), Q-003 (advisory-vs-scanner). Q-002 + Q-003 resolvable
  at design via ADR-K2-002 / ADR-K2-003. **Q-001 is a genuine blocking ambiguity
  requiring maintainer ratification** — the spec is parameterised on
  `<pythia-name>` precisely so the FRs remain unambiguous about *structure* while
  the *name* is deferred (Article III.4 — never guess).
- **Constitution-compliant** : Articles I (TDD), II (BDD), III + III.4 (specs
  first + ambiguity protocol), IV.1 (Janus delta-based modification), V (audit
  trail), IX.6 (prompt audit — Pythia enforces), XI.1/3/5/6 (AI-First — Pythia
  enforces), XII (governance — enforces, does not amend ; authors no new
  standard).

---

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers in this `specs.md` : none (the name
ambiguity is parameterised via `<pythia-name>`, not left as an inline marker, so
the FRs read cleanly). Three open questions Q-001 (BLOCKING) + Q-002 + Q-003
tracked in `open-questions.md`, slated for resolution during `/forge:design` via
ADR-K2-001..005 (Q-001 additionally requires maintainer ratification).

## Counts

- **FR-K2-PYT-*** : 31 (8 persona 001-008, 2 audit/citations 010-011, 8 tuning
  coverage 020-027, 7 integration 080-086, 6 seed rules 120-125)
- **NFR-K2-PYT-*** : 7 (001-007)
- **BDD Scenarios** : 3
- **Open Questions** : 3 (Q-001 BLOCKING + Q-002 + Q-003, all status `open`)
- **ADRs (planned, design phase)** : 5 (ADR-K2-001..005)
