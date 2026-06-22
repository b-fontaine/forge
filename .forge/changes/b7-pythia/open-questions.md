# Open Questions — b7-pythia

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: Pythia name collision — K.2 AI/RAG agent vs existing Product Analyst

- **Status**: answered
- **Raised in**: proposal.md § "Naming collision" ; specs.md FR-K2-PYT-001
  (persona name + file path)
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine (via b7-pythia planning)

### Question

`docs/new-archetypes-plan.md` §9 line 2665 + §6.2 line 2585 mandate the K.2
AI/RAG specialist agent be named **Pythia**. But the name is **already taken**:
`.claude/agents/product-analyst.md` declares `# Agent: Product Analyst (Pythia)`
— the Delphic-oracle persona used for product analysis / PRFAQ / Working
Backwards, invoked at `/forge:explore` and `/forge:propose`.

Bindings of "Pythia" → Product Analyst that exist on disk today:

- `.claude/agents/product-analyst.md` (lines 1, 4 — the persona itself).
- `.claude/agents/forge-master.md` (line 39 dispatch row, line 143 roster).
- `.claude/commands/forge/onboard.md` (line 54).
- `.claude/commands/forge/propose.md` (line 31).

Name-based dispatch (`SendMessage to: "Pythia"`, the CLAUDE.md trigger table
keyed by persona name, the Janus Dispatch Table) cannot disambiguate two agents
sharing a name. This is a genuine requirements conflict the roadmap author did
not anticipate (the K.2 "Pythia" was chosen in `ARCHITECTURE-TARGET §9.2`
apparently without noticing the Product Analyst already owns the name).

Three resolution options:

- **Option A — Keep "Pythia" for K.2 (AI/RAG), rename the Product Analyst.**
  The roadmap explicitly names the AI/RAG agent "Pythia"; the Product-Analyst
  "Pythia" is an internal naming choice with no roadmap mandate. Rename the
  Product Analyst to a non-colliding oracle/strategy name (candidates:
  **Cassandra**, **Sibyl**, **Tiresias** — all Greek seers/oracles, none used
  in the current roster). Cost: edit 1 persona + 4 referencing files (mechanical,
  in `.claude/**` which CLAUDE.md permits as direct writes).
- **Option B — Keep "Pythia" for the Product Analyst, rename the K.2 agent.**
  The Product Analyst shipped first; renaming it churns existing references.
  Pick a new name for the AI/RAG specialist (candidates: **Delphi** — the RAG
  oracle's seat; **Mnemosyne** — memory/retrieval; **Sophia** — wisdom/knowledge
  retrieval). The roadmap's "Pythia (AI/RAG)" becomes a documentary alias; the
  brick name `b7-pythia` stays (it names the brick, not the persona).
- **Option C — Defer K.2 naming to the maintainer entirely**; ship the persona
  with a placeholder name and a `[NEEDS CLARIFICATION]` in the file until the
  maintainer decides. (Weakest — leaves an unnamed agent on disk.)

### Recommendation (for design / maintainer ratification)

Lean **Option B — rename the K.2 AI/RAG agent, keep Product-Analyst-Pythia.**
Rationale: (1) the Product Analyst is *already shipped* and woven into 4 files +
two slash commands — renaming a shipped, referenced persona is higher churn and
higher regression risk than naming a brand-new one; (2) the AI/RAG agent does
not exist yet, so naming it freshly is zero-churn; (3) the roadmap's "Pythia"
for K.2 is a label, not a contract — the brick name `b7-pythia` is preserved as
the documentary link to the roadmap row regardless of the persona's final name.

Recommended new name for the K.2 AI/RAG specialist: **Delphi** (the oracle's
seat — the place retrieval happens; thematically apt for a
retrieval-augmented-generation specialist). The brick stays `b7-pythia`; the
persona file becomes `.claude/agents/delphi.md` and the persona is
`# Agent: AI/RAG Specialist (Delphi)`.

**This is a maintainer decision** — it touches an already-shipped persona's
identity and the roadmap's stated name. Article III.4 forbids guessing. Design
encodes the recommendation as a *parameterised* default (ADR-K2-001) but the
spec FRs reference the persona via `<pythia-name>` placeholder until ratified.
The harness asserts the *file* + *anchors*, not the literal name, so the test
suite is name-resolution-agnostic until the ADR locks it.

### Resolution

**Resolved 2026-06-22 by @bfontaine (maintainer ratification).** Chosen:
**Option B — keep "Pythia" for the Product Analyst, name the new K.2 AI/RAG
specialist agent `Sibyl`.** The maintainer selected **Sibyl** (a Greek
prophetess/seer — thematically consistent with the oracle motif) over the
design's recommended "Delphi"; both options keep the shipped
Product-Analyst-Pythia untouched (zero churn to the 4 existing references).

Binding for `/forge:implement`:
- `<pythia-name>` placeholder throughout proposal/specs/design/tasks resolves to
  **Sibyl**.
- Persona file: `.claude/agents/sibyl.md`; header `# Agent: AI/RAG Specialist (Sibyl)`.
- Brick name stays `b7-pythia` (it names the brick / the roadmap row, not the
  persona).
- The existing `.claude/agents/product-analyst.md` (Pythia) and its 4 references
  (`forge-master.md` ×2, `onboard.md`, `propose.md`) are **not** modified.
- ADR-K2-001 in design.md to be updated to record `Sibyl` as the ratified name
  (superseding its "Delphi" recommendation).

This question no longer blocks the flip to `implemented`.

---

## Q-002: K2-RULE namespace — pre-allocate or grow incrementally?

- **Status**: open
- **Raised in**: proposal.md § Solution K.2.a ; specs.md FR-K2-PYT-006 /
  120-cluster
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

`j8-janus-rules` ADR-J8-004 set the `<MODULE>-RULE-NNN` rule-ID format;
`k3-demeter` inherited it as `K3-RULE-NNN` and chose (ADR-K3-005) **incremental
growth** (5 seed rules, not pre-allocated). K.2 inherits the format as
`K2-RULE-NNN`. Two strategies:

- **Option A — pre-allocate** ~10 `K2-RULE-001..010` covering all four
  responsibility areas now, even if only some carry detailed remediation.
- **Option B — grow incrementally** — seed the catalogue with the rules the
  checklists actually need (one or two per responsibility area), append later.

Note: Pythia's rules are **advisory recommendations**, not policy refusals
(unlike J8-RULE which exits 3 at scaffold time, and unlike K3-RULE which scales
to BLOCKED). So the rule semantics are softer — `K2-RULE-NNN` flags a *tuning
recommendation* or a *fallback gate*, severity `Advisory` / `Concern` /
`Blocking` (Blocking reserved for the XI.5 fallback gate).

### Recommendation

Lean **Option B — incremental**, consistent with the K3-RULE ADR-K3-005
decision. Seed catalogue of ~6 rules: one per checklist area plus the XI.5
fallback gate (the only Blocking-severity rule). Resolvable at design via an ADR
mirroring ADR-K3-005. Per ADR-J8-004 inheritance, IDs are never reused.

### Resolution

_(pending — to be resolved by ADR-K2-002 in design.md.)_

---

## Q-003: Advisory agent vs scanner — does Pythia ship a scanner script?

- **Status**: open
- **Raised in**: proposal.md § Solution + § Scope Out ; specs.md (overall shape)
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

The `k3-demeter` precedent (the brick's stated "patron") ships a **deterministic
scanner** (`bin/forge-demeter-scan.sh` + Python engine + `.forge/data/
cloud-act-publishers.yml` deny-list + JSON-report exit-code contract). Should
`b7-pythia` mirror that scanner machinery, or is Pythia a pure
advisory/checklist agent (like Panoptes the observability specialist)?

The plan §9 K.2 row scopes Pythia to: *"Embeddings, pgvector tuning (HNSW
`ef_search`), MCP servers, prompt audit"* — all **tuning / audit / advisory**
verbs. There is no deny-list to scan, no deterministic jurisdiction
classification, no reproducible byte-stable report mandated. Tuning `ef_search`
against a labelled eval set is inherently workload-specific and judgement-based
— it cannot be reduced to a deterministic grep the way Demeter's CLOUD Act
deny-list can.

- **Option A — scanner** (full k3-demeter mirror): `bin/forge-pythia-scan.sh`
  + data file + exit codes. Cost: large surface for a check that is inherently
  non-deterministic (HNSW tuning depends on the adopter's eval set, which the
  scanner cannot synthesise).
- **Option B — advisory agent** (Panoptes mirror): persona checklists + RAG
  Readiness Report + `K2-RULE-*` recommendation catalogue, NO scanner script,
  NO data file, NO exit-code contract. Pythia advises at design/review time;
  the adopter (and the layer orchestrators Vulcan/Hera) act on the advice.

### Recommendation

Lean **Option B — advisory agent, no scanner.** Rationale: (1) the plan verbs
are advisory; (2) HNSW/embeddings tuning is workload-specific and not
deterministically scannable; (3) the prompt-audit + fallback checks are
design/review-time gates Janus already dispatches, not a standalone CLI; (4) a
scanner that cannot run the adopter's eval set would produce false confidence.
This is the principal *justified divergence* from the k3-demeter precedent and
will be recorded as **ADR-K2-003** in design. The harness therefore has **no L2
scanner-exit-code fixture**; its single L2 fixture asserts persona-anchor
integrity across a fresh checkout instead.

### Resolution

_(pending — to be resolved by ADR-K2-003 in design.md.)_
