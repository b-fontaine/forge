# Open Questions: t5-cargo-pin-refresh
<!-- Created: 2026-05-16 -->
<!-- Audit: T5.1.E (docs/new-archetypes-plan.md §0.1 extension — Option B) -->

Questions raised during `/forge:propose`. All MUST be resolved
(status `answered` or `wontfix`) before `/forge:plan` runs, per
`verify.sh` Open Questions Gate.

---

## Q-001 — Pin target for `buffa` / `buffa-types`

**Status** : answered (ADR-T5CPR-001)

**Raised by** : proposal.md § Solution

**Question** : the original pin `=0.3.3` does not resolve on
crates.io because `buffa` series 0.3.x stops at 0.3.0. Three
options to correct :

- **A.** `=0.3.0` (minimum edit, exact match of the only resolvable
  version of the 0.3 series).
- **B.** Modernise : bump `connectrpc = "=0.4.2"` + `buffa = "=0.6.0"`
  (latest stable).
- **C.** Relax to `buffa = "^0.3"` (caret, let Cargo pick).

**Affects** : MR-T5CPR-001 / MR-T5CPR-002 ; scope/risk balance.

**Resolution** : **ADR-T5CPR-001 — Option A (`=0.3.0`)**. Modernisation
deferred to B.8 (T6). Caret relaxation rejected (ADR-T5-002 intent
preserved : exact pins for reproducible builds).

---

## Q-002 — `transport.yaml` version bump strategy

**Status** : answered (ADR-T5CPR-002)

**Raised by** : proposal.md § Solution (item 3)

**Question** : pin correction changes the observable contract of
`transport.yaml::codegen.versions`. How to version-bump ?

- **A.** v1.1.0 → **v1.2.0** (additive minor, corrective).
- **B.** Edit in place (no bump).
- **C.** v1.1.0 → **v2.0.0** (declare breaking).

**Affects** : MR-T5CPR-003 ; standards-lifecycle invariant ;
REVIEW.md ledger format ; downstream automation triggers.

**Resolution** : **ADR-T5CPR-002 — Option A (v1.2.0)**. Standards-
lifecycle mandates a bump for any observable change. Corrective is
not breaking (adopters with =0.3.3 already could not build).

---

## Q-003 — WAIVER comment block phrasing

**Status** : answered (ADR-T5CPR-003)

**Raised by** : proposal.md § Solution (item 4)

**Question** : the existing comment block (`transport.yaml` lines
55-63) justifies the `=0.3.3` pins via pedigree arguments
(conformance suite, Anthropic OSS, 30-day rule). Those arguments
still apply to `connectrpc` and `connectrpc-build` (still at
=0.3.3, real versions). But they do not apply to `buffa` /
`buffa-types` — those pins were error-of-fact, not pedigree-
justified WAIVERs.

- **A.** Append a 2026-05-16 amendment note to the existing block.
- **B.** Full rewrite, separating WAIVER (connectrpc family) from
  CORRECTION (buffa family).

**Affects** : MR-T5CPR-004 ; audit-trail clarity for future
re-reviewers.

**Resolution** : **ADR-T5CPR-003 — Option B (full rewrite)**. Mixing
WAIVER and CORRECTION semantics in one block muddles the trail.

---

## Resolution summary

| ID    | Status   | Resolution                                                                                      |
|-------|----------|-------------------------------------------------------------------------------------------------|
| Q-001 | answered | **ADR-T5CPR-001** — `buffa = "=0.3.0"` + `buffa-types = "=0.3.0"` (minimum edit, no modernisation in this change) |
| Q-002 | answered | **ADR-T5CPR-002** — `transport.yaml` v1.1.0 → v1.2.0 (additive correction, not breaking)          |
| Q-003 | answered | **ADR-T5CPR-003** — Full rewrite of the WAIVER comment block ; separate WAIVER (connectrpc family) from CORRECTION (buffa family) |
