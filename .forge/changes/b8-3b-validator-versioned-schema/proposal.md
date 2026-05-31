# Proposal: b8-3b-validator-versioned-schema

<!-- Created: 2026-05-31 -->
<!-- Schema: default -->
<!-- Audit: B.8.3.b (docs/new-archetypes-plan.md §4.2 — validator versioned-schema discovery; proposed by b8-3 design, ratified here) -->

## Problem

B.8.3 shipped `.forge/schemas/full-stack-monorepo/2.0.0.yaml`
(`stage: candidate`, `scaffoldable: false`) as the ratified 2.0.0 target of the
flagship archetype. By the deliberate freeze-safe decision recorded in
ADR-B8-3-001, that candidate is **intentionally invisible** to the three shared
Forge validators, which each read the canonical schema by a **literal
filename** `schema.yaml` — never a glob over versioned siblings:

**Ground truth (re-read 2026-05-31, Article III.4):**

- `.forge/scripts/validate-foundations.sh:92` — `check_schema_full_stack_monorepo()`
  hard-codes `local path="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/schema.yaml"`.
  Its embedded `python3` block (lines ~107-145) validates: root is a mapping;
  `name == 'full-stack-monorepo'`; `version` matches the SemVer regex
  `^\d+\.\d+\.\d+(-[\w.-]+)?$` (line 114); `layers` is a non-empty list whose ids
  ⊇ `{backend, frontend, infra}` and each layer carries `id/path/fr_id_prefix/primary_agent`;
  `stage ∈ {draft, candidate, stable}` (line 133); `stage == 'stable' ⇒
  version ≥ 1.0.0 with no prerelease` (lines 136-139); `phases` non-empty. Emits
  `OK: schema <v> stage=<s> layers=[...]` (line 145).
- `.forge/scripts/validate-foundations.sh:273-281` — `check_multi_layer_change_metadata()`
  reads the **same literal** `…/full-stack-monorepo/schema.yaml` path to harvest
  the known layer-id set for cross-change metadata validation (FR-GL-017). This
  is a change-metadata check, **not** an env.example check (see Anti-Hallucination
  Pass — the b8-3 design's framing that this region is an "env.example check" is
  incorrect).
- `.forge/scripts/verify.sh:83` — `resolve_layer_path()` hard-codes
  `local schema="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/schema.yaml"`.
  `verify.sh:379` gates the whole "Monorepo Foundations" section on the
  **directory** `…/full-stack-monorepo/` existing, then delegates FR-GL-001 to
  `validate-foundations.sh`.
- `.forge/scripts/constitution-linter.sh:69` — `resolve_monorepo_path()`
  hard-codes the same literal `schema.yaml` path.
- On disk today (`find .forge/schemas -name '*.[0-9].[0-9].[0-9].yaml'`) the
  **only** versioned schema sibling anywhere is
  `.forge/schemas/full-stack-monorepo/2.0.0.yaml`. The other six archetype dirs
  (`default`, `ai-first`, `mobile-only`, `rapid`, `tdd-flutter`, `tdd-rust`)
  contain **only** a single canonical schema file and no `X.Y.Z.yaml` sibling.
  Two of them (`mobile-only`) don't even use the `name/version/stage` shape —
  `mobile-only/schema.yaml` uses `archetype:` / `schema_version:`. The shared
  validators only ever validate `full-stack-monorepo` today; the other
  archetypes are not validated by these three scripts.

**Consequence**: the 2.0.0 candidate is on disk, gated only by its own dedicated
harness `b8-3.test.sh` (17 L1 assertions). The three shared gates that run on the
framework repo **and** on every scaffolded target project neither see nor enforce
it. A malformed versioned schema — wrong `name`, non-SemVer `version`, illegal
`stage`, a `candidate` that forgot `scaffoldable: false`, or a filename that
disagrees with its declared `version` — would pass CI silently. As more archetypes
gain versioned candidates (plan §4.2 B.9.1 names
`mobile-pwa-first/2.0.0.yaml`), this invisibility scales into a structural gap.

**Plan status**: `docs/new-archetypes-plan.md:2267` lists B.8.3.b as a
**forward-pointer only** — "Validator versioned-schema discovery — rewire
`validate-foundations.sh` / `verify.sh` / `constitution-linter.sh` to discover +
validate versioned schema filenames … **Proposed — not yet committed.**" This
change **ratifies** B.8.3.b: it promotes the brick from proposed to a real,
specified change and updates the plan/roadmap accordingly.

## Solution

Make versioned candidate schemas **gate-visible** and **enforce candidate
semantics**, as a strict superset of today's single-`schema.yaml` behavior.

The three shared validators MUST discover sibling schema files matching
`<archetype>/<MAJOR.MINOR.PATCH>.yaml` **alongside** the canonical `schema.yaml`,
and validate each discovered file with the **same rules already applied to
`schema.yaml`** (mapping root; `name == <archetype dir name>`; SemVer `version`;
`stage ∈ {draft, candidate, stable}`; `stage == stable ⇒ version ≥ 1.0.0` no
prerelease; required layer triple + per-layer fields; non-empty `phases`), plus
three NEW invariants for the versioned regime:

1. **Filename ↔ version invariant** — a versioned file `X.Y.Z.yaml` MUST declare
   `version: "X.Y.Z"` (filename and content agree).
2. **Candidate invariant** — any schema with `stage: candidate` MUST carry
   `scaffoldable: false`. The frozen 1.0.0 `schema.yaml` (stage `stable`, no
   `scaffoldable` field) MUST keep validating — `scaffoldable` is NOT required on
   stable schemas.
3. **Backward-compat invariant (dominant NFR)** — every archetype that has only
   a single `schema.yaml` and no versioned siblings MUST keep passing exactly as
   before; the frozen `schema.yaml` MUST keep validating byte-untouched.

The candidate is **gated**, not **scaffolded**: the scaffolder (`cli`'s
`init.ts` / `init.sh`) only ever reads `schema.yaml` and cannot select a
versioned file. There is **no scaffolder code change** in B.8.3.b. Today the
non-scaffoldability of a `candidate` is enforced purely as a **validator
invariant** (a candidate must declare `scaffoldable: false`); the **runtime
selection guard** (preventing `forge init` from materializing a non-scaffoldable
schema) lands with **B.8.14**, when 2.0.0 is promoted to `stable` and the
scaffolder gains versioned-schema selection (ADR-B83B-004).

Deliverables (implementation phase, authored after design):
- Versioned-schema discovery wired into `validate-foundations.sh`,
  `verify.sh`, and `constitution-linter.sh` (the same discovery, applied per
  validator; shared helper or duplicated discovery TBD at design).
- The 3 new invariants enforced on every discovered versioned file.
- A new `b8-3b.test.sh` harness (or extension of `b8-3.test.sh`) asserting
  discovery + the 3 invariants + backward-compat (other archetypes still OK, the
  frozen `schema.yaml` still OK), registered as a **one-line** entry in the
  `forge-ci.yml` declarative `harnesses=( … )` array.
- Plan §4.2 + roadmap promotion of B.8.3.b from proposed to a committed brick.

Decisions reserved for `/forge:design` (ADRs), leanings stated, open where
genuinely undecided (see `open-questions.md`):

- **ADR-B83B-001 — discovery mechanism + scope.** Lean: glob each archetype dir
  for files matching the SemVer-filename pattern `X.Y.Z.yaml`, validate the
  canonical `schema.yaml` first (unchanged), then each versioned sibling. The
  three validators each only operate on `full-stack-monorepo/` today; whether
  B.8.3.b widens discovery to all archetype dirs or stays scoped to
  `full-stack-monorepo/` is decided at design (Q-001).
- **ADR-B83B-002 — shared vs per-validator discovery.** Lean: factor a single
  discovery + per-file validation helper to avoid three drifting copies (the
  shared-standard sibling-harness coupling lesson). Whether the helper is a new
  sourced script or duplicated inline `python3` is a design call (Q-002).
- **ADR-B83B-003 — filename↔version + candidate invariants placement.** Lean:
  enforce both new invariants inside the same per-file validation path that
  already runs the SemVer/stage checks, so a discovered versioned file is held to
  a strict superset of the `schema.yaml` rule-set.
- **ADR-B83B-004 — scaffolder guard deferral.** Decided non-goal: no scaffolder
  code change in B.8.3.b. Enforcement today = validator invariant
  (`candidate ⇒ scaffoldable: false`); runtime selection guard lands with B.8.14
  (Q-003 — confirm the scaffolder genuinely cannot select a versioned file).

Release vehicle: maintainer-set (touches SHARED validators — high blast radius;
release gated on the full CI matrix being GREEN, per the
shared-standard/sibling-harness lesson).

## Scope In

- `proposal.md`, `specs.md`, `.forge.yaml`, `open-questions.md` for
  `b8-3b-validator-versioned-schema` (this change): requirements + ADRs + open
  questions for versioned-schema discovery and candidate enforcement.
- Requirement set (`FR-B83B-*` / `NFR-B83B-*`) defining: discovery of
  `<archetype>/<X.Y.Z>.yaml` siblings; per-file validation as a strict superset
  of today's `schema.yaml` rules; the filename↔version invariant; the
  `candidate ⇒ scaffoldable: false` invariant; the backward-compat constraint;
  the `b8-3b.test.sh` harness + its one-line CI registration; the plan/roadmap
  ratification of B.8.3.b.
- ADRs `ADR-B83B-001..004` capturing discovery mechanism/scope, shared vs
  per-validator helper, invariant placement, and the scaffolder-guard deferral.

## Scope Out (Explicit Exclusions)

- **Implementing the validator rewiring** — design + implementation phases of
  this change, authored AFTER design from these specs. NOT done now (this change
  is propose + specify only).
- **Editing `full-stack-monorepo/2.0.0.yaml`** — it is the B.8.3 deliverable.
  B.8.3.b only **reads and validates** it; it MUST NOT edit it.
- **Editing the frozen 1.0.0 `schema.yaml`** — frozen by B.8.2; byte-untouched.
- **Any scaffolder code change** (`init.ts` / `init.sh`) — explicit non-goal
  (ADR-B83B-004). The runtime selection guard is B.8.14.
- **Authoring any new versioned schema file** (e.g. `mobile-pwa-first/2.0.0.yaml`)
  — that is B.9.1 territory; B.8.3.b only makes whatever versioned siblings exist
  gate-visible.
- **Promoting 2.0.0 to stable / flipping `scaffoldable: true`** — B.8.14.
- **Any `.forge/standards/**` or `.forge/templates/**` edit** — none required.
- **A Constitution amendment** — none here; the VIII.1/VIII.2 amendment lands
  with the actual bump at B.8.14.

## Impact

- **Users affected**: every Forge framework CI run **and every scaffolded target
  project** that runs `verify.sh` / `validate-foundations.sh` /
  `constitution-linter.sh`. This is the dominant risk surface — the three
  validators are SHARED infra (see NFR-B83B-001 / NFR-B83B-002).
- **Backward compatibility (dominant constraint)**: the change MUST be a strict
  superset. Archetypes with only a `schema.yaml` (all six non-flagship dirs) and
  the frozen `full-stack-monorepo/schema.yaml` MUST keep passing unchanged. A
  prior lesson (shared-standard sibling-harness coupling) is explicit: bumping
  shared infra must update ALL sibling harnesses or CI rots silently on `main` —
  so the full CI matrix MUST be GREEN before any flip/merge.
- **Technical impact**: spec artifacts only in this change. Downstream, three
  shared scripts gain discovery + 3 invariants; one new harness + one CI array
  line; the candidate `2.0.0.yaml` becomes gate-enforced (today it has
  `scaffoldable: false` and would pass the candidate invariant).
- **Dependencies**: depends on B.8.3 (the `2.0.0.yaml` candidate this makes
  visible). Unblocks enforcement of `scaffoldable: false` and any future
  versioned candidate (B.9.1 `mobile-pwa-first/2.0.0.yaml`).

## Constitution Compliance

- **Article I (TDD)**: implementation MUST be RED-first — `b8-3b.test.sh` (or the
  b8-3 extension) commits its discovery + invariant + backward-compat assertions
  and fails RED before the validator rewiring exists, then turns GREEN. Recorded
  as a spec obligation here (no code in this propose+specify change).
- **Article II (BDD)**: no new user-facing runtime feature; the acceptance
  criteria are recorded as a Gherkin scenario in `specs.md` for traceability; no
  `.feature` file required.
- **Article III.1/III.2 (Specs before code)**: this is the propose+specify gate;
  no implementation precedes it. The validator edits are authored only after
  design.
- **Article III.4 (Anti-Hallucination)**: every validator path, line number, and
  rule cited above is re-read from the live scripts. The b8-3 design's framing
  that `validate-foundations.sh` ~271-281 performs an "env.example check" is
  **recorded as incorrect** (it is the FR-GL-017 multi-layer change-metadata
  check) rather than propagated.
- **Article IV (Delta-based)**: the validators are evolved additively
  (discovery + invariants added; the existing `schema.yaml` path stays); the
  candidate `2.0.0.yaml` is not rewritten; nothing is deprecated.
- **Article V (Compliance gate)**: ADRs map each open question to a design-phase
  resolution; no work proceeds around the unresolved discovery-scope question.
- **Article XII (Governance)**: no Constitution amendment here. The VIII.1
  (Kong→Envoy) / VIII.2 (Temporal→DBOS) amendment, if any, lands with the actual
  bump at B.8.14.

## Open Questions (seed)

- **Q-001** — discovery scope: all archetype dirs vs only `full-stack-monorepo/`
  (→ ADR-B83B-001; open, resolved at `/forge:design`).
- **Q-002** — shared discovery helper vs duplicated inline `python3` across the
  three validators (→ ADR-B83B-002; open).
- **Q-003** — confirm the scaffolder (`init.ts`/`init.sh`) genuinely cannot
  select a versioned schema today, justifying the deferral to B.8.14
  (→ ADR-B83B-004; open).
