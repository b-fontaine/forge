# Open Questions — i3-t3-forbidden-linter

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: T2 severity — `warn` (Phase A) or `fail` (block from day 1)?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I3-T3F-006 (severity scaling)
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The Demeter precedent (FR-K3-DEM-068) scales severity by tier
`T1 → Informational, T2 → High, T3 → Critical`. The
`state-management.yaml::ci_blocking: false` shipped by T.4
chose warn-only Phase A → fail Phase B (flip at B.8 / T6).

For the I.3 linter, T2 severity is the ambiguous middle :
- **Option A** — `warn` Phase A (mirror NSMA) until B.8 / T6.
- **Option B** — `fail` from day 1.

Option A minimises adopter friction during rollout but allows
T2 adopters to slip forbidden tokens past CI. Option B is
stricter but risks rollout friction.

### Resolution

**Resolved by ADR-I3-003** in `design.md`. Decision : **Option
A — warn-only at T1 + T2 Phase A**, **fail at T3**. The Phase
A → B flip is automatic at B.8 / T6 via a SemVer minor bump
of the new `forbidden-components-rules.md` standard (1.0.0 →
1.1.0).

T3 enforcement is **immediate** (no graduated rollout — T3
declares "100% EU jurisdiction", forbidden component is by
definition unacceptable). Symmetric with the J.8 `--eu-tier
T3` refusal pattern.

---

## Q-002: `persistence.yaml::forbidden_for_eu_strict:` — should the linter read it?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I3-T3F-005 (forbidden parsing)
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

`persistence.yaml` declares `forbidden_for_eu_strict:
[dynamodb, firestore, cosmosdb]` (a T.4-era variant) instead
of `forbidden:`. All other standards use `forbidden:`.

Should the I.3 linter read BOTH `forbidden:` AND
`forbidden_for_eu_strict:` in v1.0.0, or only `forbidden:`?

### Resolution

**Resolved by ADR-I3-004** in `design.md`. Decision : **read
only `forbidden:` in v1.0.0**. The
`forbidden_for_eu_strict:` block is documented as a forward-
pointer to be normalised in a future T6 standards-refactor.

Adopters who want immediate `dynamodb` / `firestore` /
`cosmosdb` enforcement at T3 can extend
`compliance-tiers.md::forbidden:` (currently `[]`) with the
tokens — T3-RULE-005 (matrix-row enforcement) picks them up
via the generic forbidden-discovery surface.

---

## Q-003: T3-RULE namespace — pre-allocate 10 rules now, or grow incrementally?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I3-T3F-120..126
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

`j8-janus-rules` ADR-J8-004 set the `<MODULE>-RULE-NNN`
format and seeded `J8-RULE-001..003`. `k3-demeter`
ADR-K3-005 chose Option B (5 seed rules, incremental growth).

For I.3, two strategies :
- **Option A** — pre-allocate 10 rules T3-RULE-001..010.
- **Option B** — 5 rules now, grow incrementally.

### Resolution

**Resolved by ADR-I3-002** in `design.md`. Decision : **7
seed rules T3-RULE-001..007** (Option B + 2).

The 4 rules T3-RULE-001..004 are 1:1 with the 4 existing
standards declaring non-empty `forbidden:` lists
(identity / observability / orchestration / state-management).
T3-RULE-005 reserves the matrix-row enforcement slot for
`compliance-tiers.md::forbidden:` extension. T3-RULE-006
catches cross-standard drift (capped at WARN). T3-RULE-007
documents the tier-discovery anti-hallucination surface
(N/A, not a violation).

3 candidate rules T3-RULE-008..010 are deferred and
documented in `design.md::ADR-I3-002::Future T3-RULE-008+`.
Per ADR-J8-004, IDs are NEVER reused.
