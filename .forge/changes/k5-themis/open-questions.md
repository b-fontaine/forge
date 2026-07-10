# Open Questions — k5-themis

<!--
Tracking file per Article III.4 mechanisation.
Q-K5-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-K5-001: Workflow placement — additive step in `forge-compliance.yml` vs sibling `forge-standards-review.yml`?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md Cluster 5 (FR-K5-THE-060..063)
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

`new-archetypes-plan.md` §0.11 lines 449-451 says `forge-compliance.yml`
(I.5) is "forward-stable pour les artefacts réglementaires
Themis-territory … additive step additions per FR-I5-CW-083" — so an
additive step is sanctioned. But the compliance workflow is a per-PR
BLOCKING gate keyed on `eu-tier`, while Themis's cadence is monthly and
WARN-only. Two options :

- **Option A — additive step** in `forge-compliance.yml`.
- **Option B — sibling workflow** `forge-standards-review.yml` with
  `on: schedule:` (monthly) + `workflow_call:`.

### Resolution

**Resolved by ADR-K5-005**. Decision : **Option B — sibling workflow**.
Three reasons : (1) trigger mismatch — Themis is time-triggered
(monthly), which does not fit a `workflow_call`-only reusable gate ;
(2) blocking-posture mismatch — the compliance gate BLOCKS while Themis
is WARN-only per `standards-lifecycle.md` ; (3) sibling-harness safety —
`i5.test.sh::_test_i5_007` exact-pins the compliance workflow's step
set, so an additive step would break a sibling harness
(NFR-K5-THE-006). The sibling workflow sidesteps all three. A future
change may unify the surfaces via an optional `workflow_call` job.

---

## Q-K5-002: Regulatory-deadline source of truth — copy verbatim from the plan doc vs re-derive from primary regulatory texts?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-K5-THE-027 / NFR-K5-THE-009
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

Themis tracks NIS2 / DORA / CRA / AI Act deadlines. The dates could be
(A) copied verbatim from `new-archetypes-plan.md` §7.1's I.6 bullet
(which itself cites `ARCHITECTURE-TARGET.md` §10.4 with dated
`[source: ...]` footnotes), or (B) re-derived from the primary EU
regulatory texts.

### Resolution

**Resolved: Option A — verbatim from the plan doc**. Per Article III.4
(anti-hallucination) and NFR-K5-THE-009, Forge does not invent or
re-derive legal specifics. The four calendar entries are copied
byte-for-byte from `new-archetypes-plan.md` §7.1 I.6 bullet (lines
2629-2634) :

```
- NIS2 reporting 24h/72h
- DORA RoI ESA submission 30 avr 2026
- CRA reporting 11 sept 2026, full requirements 11 déc 2027
- AI Act phases 2025–2027 par catégorie de risque
```

These trace to `ARCHITECTURE-TARGET.md` §10.4 lines 788-794 with the
original `[source: ...]` citations. The deep legal determinations the
repo cannot ground (exact AI Act risk-category phase dates, DORA
notification windows) remain `[NEEDS CLARIFICATION]` Phase-B work items
per `ai-act-dora-artefacts.md` — Themis surfaces the calendar, it does
not adjudicate the law.

---

## Q-K5-003: CLI blocking posture — hard-fail on expiry vs WARN-only?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-K5-THE-021 / 033 / NFR-K5-THE-008
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

Should `forge review-standards` BLOCK (non-zero fatal exit) when a
standard is past its review window, or WARN only?

### Resolution

**Resolved by ADR-K5-003 + the WARN doctrine**. Decision : **WARN-only
default, `--strict` opt-in blocking**. `standards-lifecycle.md` states
"WARN n'est jamais bloquant : une expiration n'arrête pas la
production. Le but est de signaler une dette de revue, pas de geler le
pipeline." Themis honours this : the default exit is `1` (REVIEW-DUE,
non-blocking — the sibling workflow tolerates it via
`continue-on-error: true`). Adopters who want a hard gate pass
`--strict`, which flips an expired non-structural standard to exit `3`
(BLOCKED). Structural exceptions (`expires_at: never` +
`exception_constitutional: true`) never trigger blocking under either
posture.
