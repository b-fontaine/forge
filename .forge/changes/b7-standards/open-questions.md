# Open Questions — b7-standards

<!--
Q-NNN sequential, never reused. Author-phase leanings; resolutions at
/forge:design by an independent reviewer + maintainer (Article V).

## Resolution log
- **Q-001** resolved at /forge:design 2026-06-13 → (a) pure guidance; T3 enforcement already in forbidden-components (I.3) + Demeter; runtime Janus AI rules → b7-9. ADR-B7-3-002.
- **Q-002** resolved at /forge:design 2026-06-13 → (a) keep `rag-patterns.md` + document the component↔standard mapping in headers; no schema edit. ADR-B7-3-004.
- Resolutions authored at design; independent reviewer + maintainer ratification pending at /forge:review (Article V).
- Independent code-reviewer verdict: **APPROVE** (2026-06-13, first pass — 0 CRITICAL/HIGH/MEDIUM; 2 LOW by-design nits, no fix). Gates re-run + harness mutation-tested + claims Context7-verified by the reviewer.
- **MAINTAINER RATIFICATION 2026-06-13**: BDFL ratified ADR-B7-3-001..004 + Q-001/Q-002. All decisions final. Cleared for archive.
-->

## Q-001: enforcement hook vs pure guidance for the three .md standards

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-13)
- **Raised in**: proposal.md (ADR-B7-3-002), specs.md FR-B7-3-011
- **Raised on**: 2026-06-13

### Question

`.md` standards can be pure guidance, or carry a `linter_rule:`-style enforcement
pointer (like `compliance-tiers.md` → `t3-forbidden-components`). Should the three
B.7.3 standards wire a new enforcement hook now?

`[NEEDS CLARIFICATION: pure guidance now (T3 enforcement already covered by the
existing forbidden-components linter), or add a new linter rule for gateway/MCP
violations in this change?]`

- (a) **Pure guidance now** *(leaning)* — the T3 OpenAI/Vertex/Bedrock refusal is
  ALREADY enforced by `forbidden-components-rules.md` (I.3) + Demeter; the runtime
  Janus AI refusal is `b7-9-janus-ai` (J.8.c). Adding a new linter here would
  duplicate/pre-empt b7-9. The standards reference existing enforcement.
- (b) Add a new linter rule now — rejected: duplicates I.3 / pre-empts J.8.c, and
  there is no scaffolder yet (B.7.2-full) to enforce against.

## Q-002: schema component names vs standard filenames

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-13)
- **Raised in**: proposal.md, specs.md FR-B7-3-024
- **Raised on**: 2026-06-13

### Question

The b7-1 schema names components `mcp-servers`, `llm-gateway`, `rag-pipeline`; the
plan names the standards `mcp-servers.md`, `llm-gateway.md`, `rag-patterns.md`.
`rag-pipeline` (component) ≠ `rag-patterns` (standard filename). Reconcile?

`[NEEDS CLARIFICATION: keep the plan's `rag-patterns.md` filename and document the
component→standard mapping in the header, or rename to `rag-pipeline.md` to match
the schema component verbatim?]`

- (a) **Keep `rag-patterns.md` + document the mapping** *(leaning)* — the plan
  §6.2 names it `rag-patterns.md`; the component is the *pipeline*, the standard
  documents its *patterns*. A header note (FR-B7-3-024) makes the mapping explicit;
  B.7.2-full (or a schema follow-up) can align the `delivered_by` reference text
  if desired. Avoids editing the b7-1 schema (additive).
- (b) Rename standard to `rag-pipeline.md` — rejected: diverges from plan §6.2 and
  buys nothing (the mapping note suffices).
