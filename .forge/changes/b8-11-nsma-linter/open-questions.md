# Open Questions — b8-11-nsma-linter

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
Resolutions are made at /forge:design by an INDEPENDENT reviewer + the
maintainer, NOT self-approved. All author-phase leanings are recorded below
as candidate positions only; they do not constitute decisions.
-->

## Resolution Log (/forge:design, 2026-06-03)

Q-002, Q-003, and Q-004 resolved at /forge:design (maintainer decisions, encoded
in `design.md` ADR-B811-002..004). Q-001 is a RECOMMENDATION ONLY — it is
**PENDING independent-reviewer ratification** and is NOT marked answered here.
The independent reviewer adjudicates Q-001 as their first act before ratifying
this design. Until Q-001 is ruled (a) or (b), `/forge:plan` and `/forge:implement`
are BLOCKED.

| Q | Decision / Status | ADR |
|---|-------------------|-----|
| Q-001 | **STATUS: PENDING independent-reviewer ratification.** Author RECOMMENDS (a) no new amendment — VI.3 + ADR-006 already mandate blocking; B.8.11 is the scheduled activation executing F.4 §2-4 against a §1 already satisfied by existing ratification. Reviewer adjudicates; if (b), B.8.11 halts and routes to Article XII. | ADR-B811-001 |
| Q-002 | **(a) keep `pre_commit_hook: false`** — no dep-linting runner artifact exists; runner is G.2 territory; flipping `true` without a runner claims a phantom gate (Article III.4). `pre_commit_hook: false` remains with an inline comment documenting the intent. | ADR-B811-002 |
| Q-003 | **(a) 1.0.0 → 1.1.0 minor bump** — additive enforcement activation; `forbidden:`, `flutter:`, `linter_rule:`, `rationale:`, and structural-exception pair (`expires_at: never` ⇔ `exception_constitutional: true`) byte-unchanged; mirrors b8-7 identity.yaml precedent. REVIEW.md `KEEP-WITH-CHANGES`, `Next review due: never (structural)`. | ADR-B811-003 |
| Q-004 | **(a) `activated_by: "b8-11-nsma-linter (B.8.11, 2026-06-03)"` field** — replaces `activation_planned: "B.8 (T6)"` with a machine-readable audit-trail sibling; schema-legal (`enforcement.additionalProperties: true`, evidence.md P-19). Not silent delete; not comment-only. | ADR-B811-004 |

### specs.md `[NEEDS CLARIFICATION]` / Q→ADR anchor map

The design-deferred anchors in `specs.md` map to the ADRs below. `specs.md` is NOT
edited now — the marker-neutralisation happens at `/forge:implement` before the status
flip (b8-9/b8-10 precedent). This table records the mapping for the implementer.

| specs.md anchor | FR / location | Resolved by |
|-----------------|---------------|-------------|
| `[NEEDS CLARIFICATION: adjudicated by independent reviewer at /forge:design (Q-001 → ADR-B811-001)]` | Anti-Halluc. pass, Q-001 note | ADR-B811-001 — PENDING reviewer ruling |
| `[NEEDS CLARIFICATION: Q-002 → ADR-B811-002 at /forge:design]` | FR-B811-005, Q-002 note | ADR-B811-002 — keep false |
| `[NEEDS CLARIFICATION: Q-003 → ADR-B811-003 at /forge:design]` | FR-B811-010, Q-003 note | ADR-B811-003 — 1.1.0 minor |
| `[NEEDS CLARIFICATION: Q-004 → ADR-B811-004 at /forge:design]` | FR-B811-002, Q-004 note | ADR-B811-004 — activated_by field |

---

## Q-001: F.4 §1 amendment necessity — is the warn→fail flip a "tightening" requiring a fresh Article XII Constitution amendment?

- **Status**: **ANSWERED — (a) ratified by independent reviewer 2026-06-03** → ADR-B811-001
- **Raised in**: `proposal.md` (ADR-B811-001 seed), `specs.md` Anti-Hallucination Pass
- **Raised on**: 2026-06-03
- **Raised by**: author (b8-11 specify pass)
- **Resolved at**: `/forge:design` → ADR-B811-001 (independent reviewer ruling)
- **RULING (independent reviewer, 2026-06-03)**: **(a) — NO fresh Article XII
  amendment required.** Article VI.3 already mandates flutter_bloc exclusively
  and forbids alternatives "without explicit constitutional amendment" — the
  amendment clause guards *loosening* the rule, not *enforcing* it; machine-
  enforcing an existing SHALL is not a new prohibition. ADR-006 ratifies the
  *blocking CI gate* itself (`ci_blocking: true` is the ratified end-state).
  `activation_planned: "B.8 (T6)"` was a temporary scheduled deferral; the
  shipped linter WARN already says "ci_blocking flips at B.8/T6". F.4 §1's
  "Constitution amendment" precondition is satisfied by the pre-existing
  VI.3 + ADR-006 ratification; B.8.11 supplies §2 (F.x change) + §3
  (backward-compat, re-verified: 0 scannable pubspec) + §4 (linting-rules.md
  update). Article XII changes no constitutional principle here (VI.3 stays
  byte-identical) — nothing to amend. Reading (b) would make the ratified
  `activation_planned` schedule un-executable by its own terms.

### Context

`global/linting-rules.md` §"Adding a new rule" (L173-190, evidence.md P-13) states:
> "A rule MUST NOT be tightened (lower threshold, stricter heuristic) without
> going through the same process."
The §1 process requires: (1) Constitution amendment, (2) F.x change, (3)
backward-compat audit, (4) update of this standard.

The warn→fail flip is literally a tightening of the NSMA rule. However:
- Article VI.3 (evidence.md P-11) already mandates `flutter_bloc` exclusively and forbids
  alternatives "without explicit constitutional amendment."
- ADR-006 (evidence.md P-12) prescribes `ci_blocking: true` as the target.
- `state-management.yaml` was born with `activation_planned: "B.8 (T6)"` —
  an explicitly-temporary deferral that named B.8 as the scheduled activation.
- B.8.11 is the F.x change (§2), includes a backward-compat audit (§3, evidence.md P-21
  + FR-B811-030..032), and updates the governance standard (§4, FR-B811-020..023).

The question is whether the §1 "Constitution amendment" precondition is:
- **(a)** Already satisfied (VI.3 + ADR-006 mandate blocking; no new amendment
  is needed because the blocking requirement pre-exists B.8.11), OR
- **(b)** Still required despite VI.3 (the §1 process is a gate that re-runs on
  every tightening, regardless of pre-existing constitutional mandate).

### Options

- **(a) No new amendment required (author recommendation)**: VI.3 + ADR-006 already mandate
  the blocking gate. The `activation_planned` deferral was a temporary Q-001
  Option A at v0.4.0-rc.1. B.8.11 is the scheduled activation of a
  ratified-blocking rule — not a net-new rule creation or a tightening beyond
  what the Constitution prescribes. The §1 "Constitution amendment" precondition
  is satisfied by the existing VI.3 mandate; B.8.11 executes §2-4 only.
  **Independent reviewer ratifies this interpretation.**
- **(b) Fresh Article XII amendment required**: Even though VI.3 mandates
  blocking, the linting-rules.md §1 protocol is a procedural gate that applies
  whenever a rule is tightened, regardless of the underlying constitutional
  mandate. An Article XII amendment must be filed and ratified (7-day public
  discussion + BDFL ratification) before the flip. B.8.11 would become a
  follow-on change to that amendment.

**Author recommendation**: **(a) no new amendment** — VI.3 + ADR-006
already mandate the gate; B.8.11 is the scheduled activation. **The reviewer
adjudicates; this is a recommendation, not a decision.**

**If reviewer rules (b)**: record here, flip `.forge.yaml` back to `specified`,
initiate the Article XII amendment process. B.8.11 becomes a follow-on
implementation after the amendment is ratified.

---

## Q-002: `pre_commit_hook` — keep `false` or flip to `true`?

- **Status**: answered (2026-06-03, /forge:design)
- **Raised in**: `proposal.md` (ADR-B811-002 seed), `specs.md` FR-B811-005
- **Raised on**: 2026-06-03
- **Raised by**: author (b8-11 specify pass)
- **Resolves at**: `/forge:design` → ADR-B811-002

### Context

`state-management.yaml::enforcement.pre_commit_hook` is currently `false`.
B.8.11 flips `ci_blocking` to `true`; the question is whether `pre_commit_hook`
should also be flipped to `true` as part of the same activation.

No dep-linting pre-commit runner artifact exists in the repo. Flipping
`pre_commit_hook: true` without a shipped runner would declare a contract that
cannot be fulfilled — a documented gate that does nothing (Article III.4).

### Resolution

**(a) Keep `false`**: `pre_commit_hook` remains `false` with an inline comment:
`# runner is G.2 territory; flip to true when dep-linting hook ships`. Only
`ci_blocking` flips. No phantom gate is claimed. → **ADR-B811-002 DECIDED.**

---

## Q-003: Version bump magnitude — `1.0.0 → 1.1.0` minor vs larger bump?

- **Status**: answered (2026-06-03, /forge:design)
- **Raised in**: `proposal.md` (ADR-B811-003 seed), `specs.md` FR-B811-010
- **Raised on**: 2026-06-03
- **Raised by**: author (b8-11 specify pass)
- **Resolves at**: `/forge:design` → ADR-B811-003

### Context

`state-management.yaml` is at `version: "1.0.0"`. B.8.11 changes only enforcement
fields. The `forbidden:`, `flutter:`, `linter_rule:`, `rationale:`, and
structural-exception pair are byte-unchanged. Forge SemVer convention: additive or
enforcement changes take a minor bump. b8-7 identity.yaml precedent: 1.0.0 → 1.1.0
for enforcement activation.

### Resolution

**(a) 1.0.0 → 1.1.0 minor**: additive enforcement activation; structural-exception
pair intact; REVIEW.md `KEEP-WITH-CHANGES`, `Next review due: never (structural)`.
In-file version-history comment added. → **ADR-B811-003 DECIDED.**

---

## Q-004: `activation_planned` resolution form — `activated_by:` field vs comment vs delete?

- **Status**: answered (2026-06-03, /forge:design)
- **Raised in**: `proposal.md` (ADR-B811-004 seed), `specs.md` FR-B811-002
- **Raised on**: 2026-06-03
- **Raised by**: author (b8-11 specify pass)
- **Resolves at**: `/forge:design` → ADR-B811-004

### Context

`state-management.yaml` has `activation_planned: "B.8 (T6)"`. B.8.11 resolves this
marker. The `enforcement` object has `additionalProperties: true` (evidence.md P-19),
so an `activated_by:` sibling is schema-legal.

### Resolution

**(a) `activated_by: "b8-11-nsma-linter (B.8.11, 2026-06-03)"` field**: replaces
`activation_planned` with a machine-readable audit-trail field. Not silent delete
(preserves audit trail without relying on git history alone). Not comment-only
(machine-readable). → **ADR-B811-004 DECIDED.**
