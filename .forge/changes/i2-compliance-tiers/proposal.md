# Proposal: i2-compliance-tiers
<!-- Created: 2026-05-11 -->
<!-- Schema: default -->

## Problem

`docs/new-archetypes-plan.md` §7.1 line 727-729 lists item **I.2**
as a planned standard :

> **I.2.** Standard `global/compliance-tiers.md` documente les
> définitions T1/T2/T3 (RGPD via DPA / self-hostable / EU strict
> SecNumCloud) et les composants éligibles par tier (matrice
> §10.2). Effort : `M`.

Today the EU compliance gradient T1 / T2 / T3 exists as :

1. **A JSON Schema** : `.forge/schemas/compliance-tier.schema.json`
   v1.0.0 (shipped by `t4-adr-ratification`, 2026-05-04). It locks
   the `enum: [T1, T2, T3]` value and the `x-tier-descriptions`
   prose verbatim. It is the **single machine source of truth**.
2. **A prose section** : `docs/ARCHITECTURE-TARGET.md` §10
   lines 731-779. It carries the §10.2 component-eligibility matrix
   (15 rows × 4 columns) and the §10.3 archetype-profile matrix.
3. **Two cross-cutting cites** : the Demeter persona
   (`.claude/agents/demeter.md`, K.3 — shipped 2026-05-10) cites the
   schema verbatim as the single source of truth for its severity
   scaling (FR-K3-DEM-068). The Janus refusal rules
   (`.forge/standards/global/janus-orchestration-rules.md`, J.8 —
   shipped 2026-05-10) enforce J8-RULE-002 + J8-RULE-003 against T3
   declarations.

Three concrete gaps make this insufficient :

1. **No standards-layer human-readable contract**. The
   `.forge/standards/` directory carries the canonical narrative
   contract for every other Forge concept (transport,
   state-management, observability, identity, persistence, SBOM
   policy, data stewardship, janus orchestration). There is no
   equivalent for compliance tiers. Adopters reading the standards
   index for `[t1, t2, t3, eu-tier]` triggers find nothing. The
   schema description is one line ; the
   `docs/ARCHITECTURE-TARGET.md` §10 prose is buried in a 1000-line
   architecture document.
2. **Demeter's forward-pointer is unresolved**. The Demeter persona
   file references `global/compliance-tiers.md` as a sibling
   standard but the file does not exist on disk. When a reviewer
   reads Demeter and clicks through to the tier definitions, they
   land in the schema (one line per tier) or in the architecture
   document (buried). The K.3 implementation explicitly noted I.2
   as future work in its `tasks.md` (out of scope, ships later).
3. **I.3 / I.5 / I.6 are blocked**. The downstream items in the
   I-module roadmap depend on a canonical human-readable standard
   to cite :
   - **I.3** — T3-forbidden linter rule needs the standard to point
     at when refusing Firebase / Datadog / AWS-managed at T3.
     Without it, the linter cites the schema (terse) or the
     architecture document (sprawling).
   - **I.5** — `forge-compliance.yml` GitHub workflow needs the
     standard so the workflow comments cite a stable in-repo
     surface, not a moving architecture document section.
   - **I.6** — regulatory deadlines artefacts (NIS2 / DORA / CRA /
     AI Act schedules) need the standard so each artefact's intro
     can cross-link to a tier-definitions H2 anchor.

This change closes the three gaps by shipping the canonical
human-readable standard at **standards/global/compliance-tiers.md**,
v1.0.0, citing the schema verbatim and rendering the §10.2 matrix
in-standard so adopters and Demeter share a single reference.

## Solution

A single standard file at
`.forge/standards/global/compliance-tiers.md`, authored in the
existing Forge standard style (compare
`global/data-stewardship-rules.md` / K.3,
`global/janus-orchestration-rules.md` / J.8,
`global/sbom-policy.md` / J.8.d). The standard ships :

- **Frontmatter** per `.forge/schemas/standard.schema.json` (J.7) :
  `version: 1.0.0`, `last_reviewed: 2026-05-11`,
  `expires_at: 2027-05-11`, `exception_constitutional: false`,
  `linter_rule: t3-forbidden-components` (forward-pointer to I.3 ;
  no constitution-linter section yet — `enforcement: review`),
  `enforcement: {ci_blocking: false, pre_commit_hook: false}`,
  `forbidden: []` (this standard **documents**, it doesn't forbid —
  I.3 enforces),
  `rationale: "Codifies the EU compliance gradient T1/T2/T3 from
  docs/ARCHITECTURE-TARGET.md §10 so adopters and Demeter share a
  single human-readable reference."`.
- **RFC-2119 prose body** with ≥ 6 H2 sections :
  1. **Purpose** — why the standard exists, who consumes it.
  2. **Tier definitions** — T1 / T2 / T3 verbatim from
     `compliance-tier.schema.json::x-tier-descriptions`. No
     paraphrase, no extension (FR-K3-DEM-020 precedent).
  3. **Component eligibility matrix** — Markdown table mirroring
     `ARCHITECTURE-TARGET.md` §10.2 with all 15 component rows.
     Each row carries the four `T1 / T2 / T3 / Forçage tier` cells
     plus a source citation.
  4. **Demeter integration** — K.3 cross-link, severity scaling
     per FR-K3-DEM-068, K3-RULE-001..006 catalogue pointer, the
     `.forge/.forge-tier` ledger format.
  5. **Adoption path** — minimum-viable adoption (declare tier in
     `.forge/.forge-tier`) up to full adoption (DPA ledger + Janus
     dispatch wiring).
  6. **Extending the matrix** — BDFL interim governance (Phase A)
     and Themis-post-T7 (Phase B), the SemVer bump policy when a
     new component or a tier-shift edit lands.
  7. **Interdictions** — ≥ 3 explicit "MUST NOT" clauses in the
     RFC-2119 sense (e.g. MUST NOT paraphrase the schema ; MUST
     NOT add a new compliance tier without a Constitution
     amendment per Article XII ; MUST NOT silently downgrade a
     declared T3 project to T1 without an explicit ledger edit).
- **Standards index registration** : new entry in
  `.forge/standards/index.yml` with id `global/compliance-tiers`,
  triggers `[compliance, t1, t2, t3, eu-tier, dpa, schrems,
  cloud-act, tier-classification]`, scope `all`, priority `high`.
- **REVIEW ledger entry** : append-only entry in
  `.forge/standards/REVIEW.md` recording the 2026-05-11 birth +
  the 2027-05-11 next review due date.
- **Adopter intro** at `docs/COMPLIANCE.md` (new file) — three H2
  sections : "Quick start" (declare tier in `.forge-tier` ; run
  Demeter) ; "Tier picker" (decision tree pointing readers to the
  standard) ; "Cross-references" (architecture document, Demeter
  persona, Janus rules).
- **CHANGELOG entry** : `## [Unreleased]` → "Added — I.2
  compliance-tiers standard (`i2-compliance-tiers`)" listing the
  new standard + the index registration + the REVIEW entry + the
  docs/COMPLIANCE.md intro.
- **Test harness** : `.forge/scripts/tests/i2.test.sh` with ≥ 12
  L1 tests covering the frontmatter contract, the H2 sections, the
  matrix row count, the Demeter cross-link, the schema-verbatim
  invariant, the standards/index.yml registration, the REVIEW.md
  entry. Registered in `.github/workflows/forge-ci.yml` `harness`
  matrix after `k3.test.sh`.

## Scope In

- New standard `.forge/standards/global/compliance-tiers.md`
  v1.0.0 (≥ 6 H2 sections, all 15 matrix rows reproduced, ≥ 3
  Interdictions).
- New `.forge/standards/index.yml` entry for the standard.
- New `.forge/standards/REVIEW.md` append-only entry.
- New `docs/COMPLIANCE.md` adopter intro (≥ 3 H2 sections).
- New `.forge/scripts/tests/i2.test.sh` (≥ 12 L1 tests).
- New `forge-ci.yml` matrix row registering `i2.test.sh`.
- New `CHANGELOG.md` `[Unreleased]` entry.
- New Forge artefacts under `.forge/changes/i2-compliance-tiers/` :
  `.forge.yaml`, `proposal.md`, `specs.md`, `design.md`,
  `tasks.md`, `open-questions.md`.

## Scope Out (Explicit Exclusions)

- **NOT** the I.3 T3-forbidden linter rule — separate change.
  This standard's `linter_rule: t3-forbidden-components` is a
  **forward-pointer** ; the section in `constitution-linter.sh`
  ships with I.3.
- **NOT** the I.5 `forge-compliance.yml` GitHub workflow —
  separate change.
- **NOT** the I.6 regulatory artefacts (NIS2 / DORA / CRA / AI
  Act schedules) — separate change ; Themis territory (K.5, T7+).
- **NOT** any edit to `compliance-tier.schema.json`. The schema
  is the single source of truth, consumed verbatim. Re-asserting
  the schema in prose form does not bump the schema's version.
- **NOT** any edit to `.claude/agents/demeter.md`. K.3 shipped the
  persona file with the forward-pointer to this standard ; the
  standard ships **to** the pointer's target, not the other way.
- **NOT** any edit to `.forge/scaffolding/dispatch-table.yml`.
  Janus already refuses forbidden combinations via J.8 ; the
  standard documents the gradient but does not enforce.
- **NOT** any edit to existing standards
  (`identity.yaml` / `observability.yaml` / `persistence.yaml` /
  `state-management.yaml`). They already carry `forbidden:` blocks
  per ADR-007 / ADR-008 / ADR-010. The compliance-tiers standard
  cross-links to them but does not duplicate their constraints.
- **NOT** the constitution. Article XII governance preserved.
- **NOT** K.3 deliverables. They shipped 2026-05-10.

## Impact

- **Users affected** :
  - Adopters reading the standards index for `[t1, t2, t3,
    eu-tier]` triggers now find a canonical human-readable
    standard.
  - Demeter's forward-pointer resolves ; reviewers clicking
    through from the persona land on a coherent narrative.
  - I.3 / I.5 / I.6 are unblocked ; the standard becomes the
    citation anchor for downstream regulatory work.
- **Technical impact** : 1 new standard file + 1 new adopter doc
  + 1 new test harness + 4 edits (standards/index.yml,
  REVIEW.md, CHANGELOG.md, forge-ci.yml). Test harness ≥ 12 L1
  tests. **Effort `M`** per `new-archetypes-plan` §7.1 line 729.
- **Dependencies** :
  - T.4 `compliance-tier.schema.json` v1.0.0 — shipped 2026-05-04.
    The standard cites the schema's `x-tier-descriptions` verbatim.
  - K.3 `k3-demeter` — shipped 2026-05-10. The Demeter persona
    file's forward-pointer to this standard resolves at archive
    time.
  - J.8 `j8-janus-rules` — shipped 2026-05-10. The standard
    cross-links to `global/janus-orchestration-rules.md` for the
    refusal-rules layer.
  - No new external dependency. The standard is pure Markdown ;
    the test harness is bash + grep.
- **Risk level** : **Low**. The standard is documentation-only ;
  no executable surface, no schema bump, no CLI flag, no API.
  The only "live" enforcement is the J.7 validator (the standard
  is MD, not YAML — J.7 does not apply to MD standards per
  J.7 scope). The 12 L1 tests are structural (grep-based) and
  reproducible by construction.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`i2.test.sh` with ≥ 12 L1 stubs returning `_not_implemented`
(full RED witness). Phase 2 writes the standard file. Phase 3
edits the index / REVIEW / docs. Phase 4 adds the test rows in
`forge-ci.yml` and finalises the CHANGELOG.

### Article II — BDD

User-facing flows (reviewer reads the standard ; adopter onboards
via `docs/COMPLIANCE.md`) get Gherkin scenarios in `specs.md` :

```gherkin
Given an adopter reading .forge/standards/index.yml
When they search triggers for "t3" or "eu-tier"
Then global/compliance-tiers.md is listed

Given a reviewer clicking through from Demeter persona
When they land on global/compliance-tiers.md
Then the T1/T2/T3 definitions are cited verbatim from the schema

Given an adopter running bash .forge/scripts/tests/i2.test.sh
When the harness exits
Then exit code is 0 and PASS = FAIL count threshold satisfied
```

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-I2-CT-*`
+ `NFR-I2-CT-*` namespace before any standard authoring.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Three open questions Q-001 / Q-002 / Q-003 raised at this phase,
all tracked in `open-questions.md` and slated for resolution
during `/forge:design`.

### Article V — Audit Trail

Each task tagged `[Story: FR-I2-CT-XXX]` (Article V.1, enforced
by `f4-linter-extension`). The standard file carries
`<!-- Audit: I.2 (i2-compliance-tiers) -->` at the top.

### Article VIII — Infrastructure

N/A. No infrastructure surface — the standard is pure Markdown.
The CI workflow gains one matrix row for the test harness, no
new services / images / secrets.

### Article XI — AI-First Design

The standard is consumed by Demeter (XI.1 agent-native — Demeter
reads the standard at review time as part of its Anti-Hallucination
Protocol when classifying components). The standard cites the
schema verbatim ; no opaque LLM-generated content is injected
into the contract (XI.3 schema-driven preserved).

### Article XII — Governance

The standard ENFORCES the tier semantics encoded in T.4 ADRs
(ADR-007 / ADR-008 / ADR-010). It does **not amend** any
constitutional article. The new standard is MD, not YAML — it does
not carry the J.7 frontmatter contract structurally, but its
audit header + version + last_reviewed / expires_at are mirrored
in the YAML-like frontmatter block at the top of the MD file per
the existing pattern (`standards-lifecycle.md`,
`data-stewardship-rules.md`, `janus-orchestration-rules.md`).
Extending the matrix (adding a new component row, shifting a
T-cell) is a minor SemVer bump under BDFL governance until
Themis ships (K.5, T7+) ; structural changes (adding a tier T4,
amending the `x-tier-descriptions` semantics) require Article XII
Constitution amendment — locked here as an Interdiction.

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`proposal.md`. Three open questions Q-001 + Q-002 + Q-003
raised at this phase, all tracked in `open-questions.md` and
resolved during `/forge:design` :

- **Q-001** — `linter_rule:` value : kebab-case forward-pointer
  string (`t3-forbidden-components`) or null until I.3 ships?
- **Q-002** — matrix encoding : verbatim Markdown table mirroring
  `ARCHITECTURE-TARGET §10.2` (15 rows × 5 columns) or a condensed
  one (group "self-host compatible everywhere" rows)?
- **Q-003** — `docs/COMPLIANCE.md` placement : root `docs/` vs
  `docs/compliance/` subdirectory grouping with future
  I.6 / Themis artefacts?
