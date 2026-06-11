# Open Questions — b7-1-schema

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
Author phase: leanings recorded; resolutions are made at /forge:design by an
INDEPENDENT reviewer + the maintainer, not self-approved here.

## Resolution log
- **Q-001** resolved at /forge:design 2026-06-11 → option (a) inline-materialise. ADR-B7-1-001 finalized. Code-grounded (no scaffold-schema loader resolves `extends`).
- **Q-002** resolved at /forge:design 2026-06-11 → option (a) candidate+scaffoldable:false, promotion deferred to B.7 scaffolder-flip brick. ADR-B7-1-002 finalized.
- **Q-003** resolved at /forge:design 2026-06-11 → option (a) reference-only + delivered_by:B.7.3. ADR-B7-1-003 finalized.
- **Q-004** resolved at /forge:design 2026-06-11 → option (a) Qwik under frontend.surfaces; primary_agent be:Vulcan/fe:Hera/infra:Atlas. ADR-B7-1-004 finalized.
- NOTE: resolutions authored at design; **maintainer ratification + independent code-reviewer APPROVE pending** at /forge:review (not self-approved — Article V).
-->

## Q-001: AI-First phases — inline-materialised vs `extends: ai-first`

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-11)
- **Raised in**: `proposal.md` (ADR-B7-1-001 seed), `specs.md` FR-B7-1-020/021
- **Raised on**: 2026-06-11
- **Raised by**: author (b7-1 specify pass)

### Question

Plan §6.2 says `ai-native-rag/1.0.0.yaml` "étend `ai-first` avec phases
`embeddings-pipeline` et `prompt-audit`". But `ai-first/schema.yaml` is a
*workflow* schema (extends default + phases, no layers) while the file lives at
the *archetype scaffold* path (needs layers/components). **No scaffold-schema
loader resolves `extends`** (`parseSchemaMeta` reads only version/stage/
scaffoldable; `check_versioned_schema_siblings` reads `phases` from the file
itself; `grep -rn extends cli/src .forge/scripts` → only Dart hits). So an
`extends: ai-first` would NOT supply phases and the validator would fail
`phases missing or empty`.

`[NEEDS CLARIFICATION: materialise the ai-first phases inline into 1.0.0.yaml
(adding embeddings-pipeline + prompt-audit), keeping extends: ai-first as a
documentary pointer only — or invest in a loader that resolves extends for
scaffold schemas (larger, cross-cutting, out of B.7.1 scope)?]`

- (a) **Inline-materialise + documentary `extends`** *(leaning)* — copy the
  ai-first phase list into `1.0.0.yaml`, add the two B.7.1 phases, retain
  `extends: ai-first` (or a header comment) for provenance. Self-contained,
  validates on landing, no loader change. Cost: phase duplication between
  `ai-first/schema.yaml` and this file (drift risk — mitigated by b7-1.test.sh
  asserting the AI-First phase set is present).
- (b) **Build an `extends` resolver for scaffold schemas** — single source of
  truth, no duplication. Cost: new cross-cutting loader behaviour touching the CLI
  + the bash validators; large, out of an effort-S brick; would block B.7.1 on a
  framework change. Rejected for B.7.1 scope (could be a later G.* tooling brick).

## Q-002: candidate → stable/scaffoldable promotion trigger

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-11)
- **Raised in**: `proposal.md` (ADR-B7-1-002), `specs.md` FR-B7-1-005
- **Raised on**: 2026-06-11

### Question

The first cut is `candidate` + `scaffoldable: false` (no templates). What promotes
it to `stable` + `scaffoldable: true`, and which B.7 brick owns the flip?

`[NEEDS CLARIFICATION: confirm the promotion mirrors B.8.14 — flip to
stable+scaffoldable in the B.7 brick that ships the scaffold-plan + templates +
green b7-6 harness; and name that brick when the B.7 chain is sequenced.]`

- (a) **Flip in the scaffolder-completion brick, gated on b7-6 harness**
  *(leaning)* — analogous to B.8.14 C2 (scaffoldable:false→true once a real
  scaffold is proven green). Keeps init refusing until the archetype actually
  produces a working tree.
- (b) Flip earlier (at b7-2 backbone) — rejected: would advertise a scaffoldable
  archetype before the example/harness prove it, risking a broken `forge init`.

## Q-003: component reference-only + deferred-standard gap

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-11)
- **Raised in**: `proposal.md` (ADR-B7-1-003), `specs.md` FR-B7-1-031/032
- **Raised on**: 2026-06-11

### Question

pgvector/Temporal/Zitadel/Connect/Qwik/observability standards exist; LLM
gateway / MCP / RAG-patterns do not (they are B.7.3). How does the schema
reference the missing ones without fabricating?

`[NEEDS CLARIFICATION: reference existing standards by filename and mark the three
missing ones delivered_by: B.7.3 with no inline pin — mirroring the B.8.3
Envoy-pin-deferred-to-B.8.4 precedent?]`

- (a) **Reference-only + delivered_by: B.7.3 for the gaps** *(leaning)* — mirrors
  ADR-B8-3-002 + the Envoy gap. No fabrication (Article III.4). No verify-then-pin
  candidate (`rmcp`, pgvector crate) committed in the schema.
- (b) Inline pins now — rejected: second source of truth that drifts, and would
  require fabricating standards/versions that don't exist yet.

## Q-004: layer / RAG-surface modelling + AI-frontend primary_agent

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-11)
- **Raised in**: `proposal.md` (ADR-B7-1-004), `specs.md` FR-B7-1-011/012
- **Raised on**: 2026-06-11

### Question

The validator requires backend/frontend/infra. How are the Qwik streaming surface
and the RAG/MCP backend roles modelled, and which agent owns the AI frontend?

`[NEEDS CLARIFICATION: model the Qwik streaming UI under frontend.surfaces (as
full-stack 2.0.0 does for web-public), backend primary_agent Vulcan, infra Atlas
— and decide the frontend primary_agent (Hera vs a web-specific agent) at
design?]`

- (a) **Qwik surface under `frontend.surfaces`, Vulcan/Atlas for backend/infra**
  *(leaning)* — reuses the full-stack 2.0.0 surface precedent; exact surface
  fields + frontend primary_agent finalised at design.
- (b) New top-level `web-public` layer — rejected: breaks the required-triple
  invariant shape and diverges from the flagship precedent.
