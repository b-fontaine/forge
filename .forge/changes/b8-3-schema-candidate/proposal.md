# Proposal: b8-3-schema-candidate

<!-- Created: 2026-05-30 -->
<!-- Schema: default -->
<!-- Audit: B.8.3 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0 migration, 2.0.0 candidate schema) -->

## Problem

B.8 migrates `full-stack-monorepo / 1.0.0` → `2.0.0` (the point of no
return, plan §4). The strategy is **additive-first, breaking-second** (§4.1):
Envoy alongside Kong (B.8.4), DBOS alongside Temporal-intent (B.8.5),
Connect-RPC alongside REST-bridge (B.8.6), Zitadel alongside implicit auth
(B.8.7), Qwik `web-public/` alongside Flutter `web-backoffice/` (B.8.9), the
observability trio (B.8.8, **already closed** — `observability.yaml` v2.1.0).
The actual `1.0.0 → 2.0.0` version bump + Kong/Temporal/REST removal happens
at **B.8.14**, NOT here.

Today there is no declared, machine-readable description of the 2.0.0 TARGET
architecture. Each of B.8.4–B.8.9 would otherwise invent its own slice of the
target with no shared contract to validate against, and B.8.12 (zero-regression
gate) would have nothing canonical to assert the migrated flagship converges
to. The 1.0.0 `schema.yaml` is now in **maintenance-freeze** (B.8.2,
`global/upgrade-policy.md`); it MUST NOT be edited to describe 2.0.0.

**Ground truth (re-read 2026-05-30, Article III.4):**

- The existing stable schema lives at a single hard-coded path
  `.forge/schemas/full-stack-monorepo/schema.yaml` (`name`, `version: "1.0.0"`,
  `stage: stable`, `layers[backend/frontend/infra]`, `fr_id_prefix_cross_layer:
  FR-GL-`, `cross_layer` Janus routing, `phases`). Its stage semantics
  (draft/candidate/stable, ADR-004 in the schema header) are the basis B.8.3
  evolves.
- **The validator reads `schema.yaml` by literal filename, not a glob.**
  `.forge/scripts/validate-foundations.sh:92` (FR-GL-001), `verify.sh:83`, and
  `constitution-linter.sh:69` all hard-code `…/full-stack-monorepo/schema.yaml`.
  A sibling `2.0.0.yaml` would be **invisible** to every existing gate — it
  would neither be validated nor enforced. This directly contradicts the plan's
  `2.0.0.yaml` filename (§4.2 B.8.3) versus the live single-`schema.yaml`
  convention. **Recorded, not normalized** (→ ADR-B8-3-001).
- The 2.0.0 component decisions are **already ratified in the standards**, not
  invented here: `orchestration.yaml` v1.0.0 (`default: dbos`, `fallback:
  temporal`), `persistence.yaml` v1.0.0 (`default: postgres-17`, `extensions:
  [pgvector-0.8, postgis, timescaledb]`), `identity.yaml` v1.0.0 (`default:
  zitadel`), `transport.yaml` v1.2.0 (`protocol: connect-rpc`, `fallback:
  grpc-web`, concrete `codegen.versions` pins). **No gateway/Envoy version pin
  exists in any `*.yaml` standard** — only a markdown standard `infra/kong.md`
  (and `infra/kong` in `index.yml`). So the Envoy pin has no standard source
  today; it is delivered by B.8.4. **Recorded, not normalized** (→ ADR-B8-3-002,
  Q-002).
- The validator accepts `stage` ∈ {draft, candidate, stable} and enforces
  `stage == stable ⇒ version ≥ 1.0.0 without prerelease`
  (`validate-foundations.sh:132-139`). There is **no** rule today for a
  `candidate` schema coexisting with a frozen `stable` sibling — undefined
  behavior the candidate must define (→ ADR-B8-3-003).

## Solution

Author the **specification for** the 2.0.0 candidate schema — its required
content, the breaking-deltas it declares, and the rules governing its
coexistence with the frozen 1.0.0 `schema.yaml`. **B.8.3 ships NO runnable
templates and NO component version pins as code**; the candidate schema file
itself is built in the implementation phase, and the per-component pins
(Envoy/DBOS/Connect/Zitadel) are delivered by the bricks that ship each
template (B.8.4–B.8.7). This change is propose + specify only.

The 2.0.0 candidate schema, when built, MUST:

1. **Evolve the existing shape** of `schema.yaml`, not rewrite it: same top-level
   keys (`name`, `version`, `stage`, `description`, `tdd_enforced`,
   `bdd_required_for_user_facing`, `coverage_threshold`, `layers`,
   `fr_id_prefix_cross_layer`, `cross_layer`, `phases`), evolved values.
2. Declare `name: full-stack-monorepo`, `version: "2.0.0"`, `stage: candidate`.
3. Declare the 2.0.0 **layer topology**: the existing backend/frontend/infra
   layers PLUS the split of the web surface into `web-public/` (Qwik, B.8.9) and
   `web-backoffice/` (Flutter Web, B.8.9) — see ADR-B8-3-004 for whether these
   are new `layers[]` entries or sub-paths of `frontend`.
4. Declare the 2.0.0 **component SET** by name (Envoy Gateway, DBOS embedded,
   Connect-RPC, Zitadel, Postgres 17 + pgvector, SigNoz/OBI/Coroot) with each
   component **pointing at its source standard** rather than re-pinning a
   version inline (ADR-B8-3-002), and explicitly flagging the Postgres 16→17 +
   pgvector delta from the baseline (B8-BASELINE §2) as a migration-crossing
   delta, never a silent bump.
5. Declare the **breaking-deltas** 1.0.0 → 2.0.0 (Kong→Envoy, Temporal-intent→
   DBOS, REST-bridge→Connect, implicit→Zitadel) so B.8.12 has a canonical target
   to assert against and B.8.14 has the authoritative bump contract.
6. Carry **candidate semantics**: a documented header block (mirroring the
   existing ADR-004 stage block) stating what `candidate` MEANS while a frozen
   `stable` 1.0.0 sibling exists — specifically that the candidate is **NOT
   scaffoldable by default** and what promotes it to stable (ADR-B8-3-003).

Decisions reserved for `/forge:design` (ADRs), leanings stated, open where
genuinely undecided (see `open-questions.md`):

- **ADR-B8-3-001 — on-disk naming.** Plan says `2.0.0.yaml`; live convention +
  every validator is hard-coded to `schema.yaml`. **Decided (maintainer 2026-05-30,
  option a):** author the candidate at `.forge/schemas/full-stack-monorepo/2.0.0.yaml`;
  frozen `schema.yaml` (1.0.0 stable) stays byte-untouched. The candidate is
  intentionally invisible to the three existing gates (validate-foundations.sh /
  verify.sh / constitution-linter.sh); B.8.3 validates it via its own dedicated
  harness `b8-3.test.sh`. Rewiring the shared validators to discover versioned
  schema filenames is explicitly **B.8.3.b** (separate downstream brick, out of
  B.8.3 scope). Overwriting or renaming `schema.yaml` is rejected — it edits the
  frozen 1.0.0 surface (violates B.8.2 freeze) and breaks FR-GL-001 today.
- **ADR-B8-3-002 — pins vs component-set.** **Decided (maintainer 2026-05-30,
  reference-only):** the 2.0.0.yaml declares the component SET + layer topology +
  breaking-deltas and **references the source standard** for each pinnable
  component (DBOS→`orchestration.yaml`, Postgres/pgvector→`persistence.yaml`,
  Zitadel→`identity.yaml`, Connect→`transport.yaml`); it does **not** inline
  version numbers. The Envoy pin has **no standard yaml today** (gap recorded,
  Article III.4 — fabrication prohibited), so the schema references the gateway
  decision and **defers the Envoy pin to B.8.4**. Inline pins are rejected
  (second source of truth that drifts; Envoy pin would require fabrication).
- **ADR-B8-3-003 — candidate semantics + coexistence.** Lean: `candidate` means
  "the ratified 2.0.0 target, gating B.8.4–B.8.9, **not scaffoldable by default**
  (opt-in only), promoted to `stable` at **B.8.14** after B.8.12 proves zero
  regression on the 4 demos". The validator MUST treat a `candidate` 2.0.0
  schema as non-scaffoldable; whether that needs a validator change is flagged
  (couples to ADR-B8-3-001).
- **ADR-B8-3-004 — web layer modeling.** Lean: model `web-public` (Qwik) and
  `web-backoffice` (Flutter Web) as a `frontend` evolution (sub-paths /
  additional layer entries) per B.8.9, with Janus arbitrating both; exact
  `layers[]` shape decided at design.

Release vehicle: maintainer-set (additive spec artifact; no runtime change).

## Scope In

- `proposal.md`, `specs.md`, `.forge.yaml`, `open-questions.md` for
  `b8-3-schema-candidate` (this change), authoring requirements + ADRs +
  open questions for the 2.0.0 candidate schema.
- Requirement set (`FR-B8-3-*` / `NFR-B8-3-*`) defining WHAT the candidate
  schema must contain and the coexistence/scaffolding rules.
- ADRs `ADR-B8-3-001..004` capturing the naming, pins-vs-set, candidate
  semantics, and web-layer decisions.

## Scope Out (Explicit Exclusions)

- **Building the `2.0.0` schema file itself** — implementation phase of B.8.3,
  authored AFTER design from these specs. NOT created now.
- **Editing `schema.yaml` (1.0.0)** — frozen by B.8.2 maintenance-freeze. Never
  touched by this change.
- **Component version pins** — Envoy (B.8.4), DBOS (B.8.5), Connect codegen
  (B.8.6), Zitadel (B.8.7) deliver their own pins. B.8.3 declares the SET and
  references source standards, it does not pin.
- **Templates** — `templates/full-stack-monorepo/2.0.0/**` is B.8.4–B.8.9.
- **Validator changes** — wiring a gate to read versioned schema filenames or to
  reject scaffolding a `candidate` is a **separate brick** (flagged in
  ADR-B8-3-001/003), not done here.
- **The schema bump 1.0.0 → 2.0.0** + Constitution amendment — B.8.14.
- **`mobile-only/2.0.0` schema** — B.9 territory.
- **Any standard yaml edit** — the component decisions already exist in
  `orchestration/persistence/identity/transport.yaml`; this change adds no
  standard and bumps none.

## Impact

- **Users affected**: B.8 migration architects (the candidate schema is the
  shared contract gating B.8.4–B.8.9) and B.8.12/B.8.14 (target-of-record). No
  effect on current 1.0.0 adopters — the frozen `schema.yaml` is untouched and
  the candidate is not scaffoldable.
- **Technical impact**: spec artifacts only in this change. Downstream the
  candidate schema file is a new sibling; whether it needs a validator change to
  be seen/guarded is the open question (ADR-B8-3-001).
- **Dependencies**: depends on B.8.1 (baseline reality to delta against) +
  B.8.2 (frozen 1.0.0 surface this must not edit). Gates B.8.4–B.8.9, B.8.12,
  B.8.14.

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: this is the propose+specify gate;
  no implementation precedes it. The candidate schema file is built only after
  design.
- **Article III.4 (Anti-Hallucination)**: every claim about the validator path,
  the standards' pins, and the stage rules is re-read from the live files
  (`validate-foundations.sh`, `orchestration/persistence/identity/transport.yaml`,
  `schema.yaml`); the `2.0.0.yaml`-vs-`schema.yaml` and the missing-Envoy-pin
  contradictions are recorded, not normalized; genuinely undecided points are
  `[NEEDS CLARIFICATION]` in `open-questions.md`, not guessed.
- **Article IV (Delta-based)**: the candidate evolves the existing schema shape;
  it does not rewrite or deprecate `schema.yaml` — both coexist.
- **Article V (Compliance gate)**: ADRs map each open question to a design-phase
  resolution; no work proceeds around the unresolved naming/pin questions.
- **Article XII (Governance)**: no Constitution amendment here. The amendment, if
  any, lands with the actual bump at B.8.14.

## Open Questions (seed)

- **Q-001** — `2.0.0.yaml` vs `schema.yaml` on-disk naming + validator wiring
  (→ ADR-B8-3-001; **resolved 2026-05-30** → option (a), see `open-questions.md`).
- **Q-002** — does 2.0.0.yaml carry inline pins or reference standards
  (→ ADR-B8-3-002; **resolved 2026-05-30** → reference-only, see `open-questions.md`).
- **Q-003** — candidate→stable promotion trigger + scaffoldability
  (→ ADR-B8-3-003; open, resolved at /forge:design).
- **Q-004** — web-public/web-backoffice layer modeling (→ ADR-B8-3-004;
  open, resolved at /forge:design).
