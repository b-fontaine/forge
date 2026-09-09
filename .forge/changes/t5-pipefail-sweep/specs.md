# Specs — `t5-pipefail-sweep`

**Namespace** : `FR-T5PFS-*`, `NFR-T5PFS-*`, `ADR-T5PFS-*`.

---

## Functional Requirements

### FR-T5PFS-001 — no proven-broken shape remains

No file under `.forge/scripts/` may contain a `find …` or `grep -r …` piped into an
early-exiting reader whose status is consumed. This is the shape measured at **100 %
failure** on a large tree — it is not a risk, it is a permanently wrong answer.

Verified by `grep -rnE '(find|grep\s+-r)[^|]*\|\s*grep\s+-\w*q'` returning nothing
outside comments.

### FR-T5PFS-002 — the mechanical majority is converted

Every site where the writer is a `printf`/`echo` of a shell variable, or a
single-line command, and the reader is the last stage, MUST be converted:

- `printf '%s' "$V" | READER` → `READER <<<"$V"`
- `CMD | READER` → `READER < <(CMD)`

### FR-T5PFS-003 — what is not converted is listed, not forgotten

Sites left in place — multi-line constructs and shapes the transform declined to
guess at — MUST be enumerated with file:line in `evidence.md`, with the reason.

A sweep that silently converts what it can and says nothing about the rest reads as
complete when it is not.

### FR-T5PFS-004 — a guard against the proven-broken shape

A test MUST fail if any `.forge/scripts/**/*.sh` regains a `find`/`grep -r` piped
into a `grep -q`. Scoped to the shape that is *always* wrong rather than to every
pipe, so the guard states a fact rather than a style preference.

### FR-T5PFS-005 — semantics preserved

Every converted site MUST feed the reader the same bytes and yield the same status
for genuine match / non-match. Verified by the 80-entry CI matrix staying 80/80, run
more than once, plus `bash -n` on every touched file.

---

## Non-Functional Requirements

### NFR-T5PFS-001 — no behaviour change is acceptable

This is a mechanical sweep of test infrastructure. Any harness whose PASS/FAIL counts
change is a defect in the sweep, not a discovery — the sweep must be reverted for
that file and the site done by hand.

### NFR-T5PFS-002 — syntactic proof before behavioural proof

`bash -n` on every touched file, before running anything. The first draft of the
transform produced syntactically invalid shell in three distinct ways; a suite run is
not the place to discover that.

---

## ADRs

### ADR-T5PFS-001 — two transforms, chosen by writer, and nothing guessed at

**Context.** 288 candidate sites. A single uniform rewrite does not fit: the writer is
a shell builtin printing a variable in some, an external command in others, and a
multi-line `||` continuation in many.

**Decision.** Convert only two unambiguous shapes — variable-writer → here-string,
single-line command-writer → process substitution — and leave everything else
untouched and listed.

**Rejected: converting everything.** The first attempt tried, and produced
`if grep -q .; then < <(find …)` — syntactically invalid, semantically nonsense —
because a greedy reader pattern swallowed `; then`. A second attempt orphaned a `||`
continuation onto its own line. **Two independent classes of breakage on the first
two tries** is the argument: 60 files is too many to hand-verify, and a transform
that guesses is worse than a site left alone with a note.

**Consequence.** 112 of 288 sites converted; 176 recorded. The proven-broken class is
empty, which is the property that mattered.

### ADR-T5PFS-002 — the guard is scoped to the proven shape, not to all pipes

Guarding every `| grep -q` would flag 176 sites the sweep deliberately left, turning
the guard into noise that gets disabled. It is scoped to `find`/`grep -r` writers —
measured at 100 % failure — so a violation is a defect, not a preference.
