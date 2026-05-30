# Open Questions — b8-3-schema-candidate

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
Author phase: leanings recorded; resolutions are made at /forge:design by an
INDEPENDENT reviewer + the maintainer, not self-approved here.

## Resolution log

- **Q-001** resolved by maintainer 2026-05-30 → option (a). ADR-B8-3-001 finalized.
- **Q-002** resolved by maintainer 2026-05-30 → reference-only. ADR-B8-3-002 finalized.
- Propose + specify artifacts passed independent code-reviewer APPROVE (no CRITICAL / HIGH / MEDIUM findings) 2026-05-30.
- **Q-003** resolved by maintainer 2026-05-30 → option (a). ADR-B8-3-003 finalized at /forge:design.
- **Q-004** resolved by maintainer 2026-05-30 → option (a). ADR-B8-3-004 finalized at /forge:design.
-->

## Q-001: On-disk naming (`2.0.0.yaml`) vs single `schema.yaml` + validator wiring

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B8-3-001 seed), `specs.md` Source Documents + FR-B8-3-004
- **Raised on**: 2026-05-30
- **Raised by**: author (b8-3 specify pass)

### Question

Plan §4.2 B.8.3 names the artifact `.forge/schemas/full-stack-monorepo/2.0.0.yaml`.
But the live convention is a single `schema.yaml` per archetype dir, and **every
validator reads that literal filename**: `validate-foundations.sh:92`
(FR-GL-001), `verify.sh:83`, `constitution-linter.sh:69`. A sibling `2.0.0.yaml`
would be **invisible** to all gates — neither validated nor enforced.

`[NEEDS CLARIFICATION: For B.8.3, should the 2.0.0 candidate be authored at a
versioned path `…/full-stack-monorepo/2.0.0.yaml` (leaving the frozen
`schema.yaml` byte-stable but unvalidated by current gates), and is the
validator-rewiring to discover/validate versioned schema filenames an
explicit SEPARATE brick (validator change) outside B.8.3 — or does the
maintainer want a different coexistence scheme (e.g. `1.0.0.yaml` +
`2.0.0.yaml` + a `schema.yaml` symlink/pointer)?]`

- (a) **Versioned sibling `2.0.0.yaml`, validator rewiring deferred** — frozen
  `schema.yaml` stays byte-stable (honors B.8.2). Candidate exists on disk,
  guarded by a NEW gate (`b8-3.test.sh`) delivered as part of B.8.3 impl. The
  three existing validators (validate-foundations.sh / verify.sh /
  constitution-linter.sh) remain intentionally unaware of it; rewiring them to
  discover versioned schema filenames is a **separate downstream brick B.8.3.b**.
  **Decided** — only freeze-safe option; avoids sibling-harness coupling by
  deferring the shared-validator edit to its own brick.
- (b) **Rename to versioned pair** `1.0.0.yaml` + `2.0.0.yaml`, retire
  `schema.yaml` — cleanest long-term but **edits the frozen 1.0.0 surface**
  (removes `schema.yaml`) → violates B.8.2 freeze + breaks all three gates today;
  needs a coordinated validator change. Rejected for B.8.3 scope.
- (c) **Overwrite `schema.yaml` with 2.0.0** — rejected outright (destroys the
  frozen 1.0.0 contract; the B.8.2 sha guard + FR-GL-001 both fail).

### Resolution

- **Resolved on**: 2026-05-30 (maintainer decision)
- **Decision**: Option (a) — author the candidate at `.forge/schemas/full-stack-monorepo/2.0.0.yaml`; frozen `schema.yaml` (1.0.0 stable) is byte-untouched. The candidate is **intentionally invisible** to the three existing gates for now. B.8.3 validates it via its own dedicated harness `b8-3.test.sh`. Rewiring the shared validators to discover versioned schema filenames is explicitly **B.8.3.b** (separate brick, out of B.8.3 scope).
- **Rationale**: Only freeze-safe option (honors B.8.2 byte-identity constraint). Avoids sibling-harness coupling by not touching validate-foundations.sh / verify.sh / constitution-linter.sh until a dedicated brick can do it properly.

---

## Q-002: Inline version pins vs source-standard references in the 2.0.0 schema

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B8-3-002 seed), `specs.md` FR-B8-3-011/012
- **Raised on**: 2026-05-30
- **Raised by**: author (b8-3 specify pass)

### Question

Does the 2.0.0 candidate carry component version pins inline, or only declare the
component SET + topology + breaking-deltas and reference the owning standard for
each pin?

Observed: DBOS/Postgres/Zitadel/Connect pins already live in
`orchestration.yaml` / `persistence.yaml` / `identity.yaml` / `transport.yaml`.
**No `*.yaml` standard pins a gateway** — Envoy has no standard source today
(only `infra/kong.md` markdown); its pin is delivered by B.8.4.

- (a) **Reference-only** — schema points each component at its standard; never
  re-pins; Envoy pin deferred to B.8.4. **Decided** — single source of truth,
  no drift, B.8.3 ships no pins (matches the brick boundary).
- (b) **Inline pins** — schema duplicates versions inline. Creates a second
  source of truth that can drift from the standards; and the Envoy pin would
  have to be invented (no source) → violates Article III.4. Rejected.

### Resolution

- **Resolved on**: 2026-05-30 (maintainer decision)
- **Decision**: Option (a) — reference-only. The 2.0.0 candidate declares the component SET + layer topology + breaking-deltas and points each pinnable component at its owning standard yaml (`orchestration/persistence/identity/transport`). No version numbers are inlined.
- **Rationale**: Article III.4 — the Envoy gateway pin has no `*.yaml` standard source today (only `infra/kong.md` markdown), so inlining would force fabrication of an external pin. Pins arrive with B.8.4–B.8.7; the schema is the shared contract, not the pin registry.

---

## Q-003: `candidate` semantics, scaffoldability, and promotion trigger

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B8-3-003 seed), `specs.md` FR-B8-3-005/041/042
- **Raised on**: 2026-05-30
- **Raised by**: author (b8-3 specify pass)

### Question

The existing `schema.yaml` defines stage semantics (draft/candidate/stable,
ADR-004) for the 1.0.0 line, where `candidate` meant the `1.0.0-rc.1` step. There
is **no** defined meaning for a `candidate` 2.0.0 schema **coexisting with a
frozen `stable` 1.0.0 sibling**, and the validator
(`validate-foundations.sh:132-139`) has no scaffoldability gate keyed on stage.
What does `candidate` mean here, and how must the validator/scaffolder treat it?

- (a) **Candidate = ratified target, not scaffoldable by default, promoted at
  B.8.14 after B.8.12 zero-regression** — `forge init` keeps scaffolding 1.0.0;
  2.0.0 is opt-in only. **Lean here.** (Enforcing non-scaffoldability may need a
  validator/scaffolder change → couples to Q-001; that enforcement is a separate
  brick, not B.8.3.)
- (b) **Candidate = freely scaffoldable preview** — risks adopters scaffolding an
  unfinished 2.0.0 before B.8.4–B.8.9 land. Disfavored (premature exposure of the
  point-of-no-return target).

### Resolution

- **Resolved on**: 2026-05-30 (maintainer decision, finalized at /forge:design)
- **Decision**: Option (a) — `candidate` = ratified 2.0.0 target, NOT scaffoldable by default. `forge init` keeps scaffolding 1.0.0; 2.0.0 is opt-in only. Promotion candidate→stable happens at B.8.14 after B.8.12 proves zero-regression on the 4 demos. B.8.3 declares `scaffoldable: false` as a top-level boolean field in `2.0.0.yaml` (ADR-B8-3-005) and asserts it via `b8-3.test.sh`. Enforcing non-scaffoldability in the scaffolder/validator is deferred to B.8.3.b.
- **Rationale**: The `scaffoldable: false` field is machine-readable now and forward-stable (B.8.14 flips it to `true`). Scaffolder enforcement couples to the validator rewiring in B.8.3.b — correct separation of concerns.

---

## Q-004: Web layer modeling — `web-public` (Qwik) + `web-backoffice` (Flutter Web)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B8-3-004 seed), `specs.md` FR-B8-3-021
- **Raised on**: 2026-05-30
- **Raised by**: author (b8-3 specify pass)

### Question

Plan §4.2 B.8.9 adds a Qwik `web-public/` layer while Flutter Web stays in
`web-backoffice/`, with Janus arbitrating both. How should the 2.0.0 schema model
this — as new `layers[]` entries, or as sub-paths/structure under the existing
`frontend` layer?

- (a) **Sub-paths under `frontend`** — `frontend` keeps `id/path/fr_id_prefix/
  primary_agent`, with `web-public` + `web-backoffice` as declared sub-surfaces.
  Keeps the validator's required triple trivially satisfied. Lean here.
- (b) **New top-level `layers[]` entries** — explicit `web-public` /
  `web-backoffice` layers with their own `fr_id_prefix` + `primary_agent`. More
  expressive; must keep `backend/frontend/infra` present so FR-GL-001 holds, and
  defines new FR-ID prefixes + agent routing (couples to Janus triggers).

### Resolution

- **Resolved on**: 2026-05-30 (maintainer decision, finalized at /forge:design)
- **Decision**: Option (a) — model as `surfaces:` sub-map under the existing `frontend` layer entry. `frontend` keeps its top-level `id/path/fr_id_prefix/primary_agent` (Hera). Two named surfaces: `web-backoffice` (Flutter Web, path `web-backoffice/`) and `web-public` (Qwik, path `web-public/`, new in 2.0.0 per plan §4.2 B.8.9). Paths confirmed from plan §4.2 B.8.9: "web-public/" and "Flutter Web reste en `web-backoffice/`". No new top-level `layers[]` entries; FR-GL-001 backend/frontend/infra triple trivially satisfied. Janus `layers_count_ge: 2` trigger unaffected (intra-frontend surfaces do not add new layer count).
- **Rationale**: Avoids new FR-ID prefixes and Janus routing churn. Keeps the validator's required triple satisfied without B.8.3.b. B.8.9 populates the surface templates; this schema records the topology contract.
