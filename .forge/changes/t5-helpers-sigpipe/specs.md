# Specs — `t5-helpers-sigpipe`

**Namespace** : `FR-T5HSP-*`, `NFR-T5HSP-*`, `ADR-T5HSP-*`.

---

## Functional Requirements

### FR-T5HSP-001 — the shared assertions do not pipe into `grep`

`.forge/scripts/tests/_helpers.sh` MUST NOT feed a haystack to `grep` (or any
early-exiting reader) through a pipe. `assert_contains` and `assert_not_contains`
MUST use a here-string.

Rationale is mechanical, not stylistic: under `set -o pipefail` — which every
harness sets — an early-exiting reader closes the pipe, the writer takes SIGPIPE,
and the pipeline yields 141. The assertion then reports the opposite of the truth.

### FR-T5HSP-002 — the failure-preview line too

`assert_contains`'s diagnostic at `:48` is
`$(printf '%s' "$haystack" | head -5)`. `head` exits after five lines, so it has the
same shape. Its exit status is currently unchecked, so it does not *cause* a
failure today — but it is the same defect one refactor away from mattering, and
leaving one instance in place invites the pattern back.

### FR-T5HSP-003 — a guard against reintroduction

A test MUST fail if `_helpers.sh` regains a `printf … | grep` / `| head` form.
Static and cheap; this is a pattern that reads as normal shell and will otherwise
return.

### FR-T5HSP-004 — a probabilistic guard proving the mechanism

A test MUST exercise `assert_contains` many times against a haystack shaped like the
one that fails — an early match in a multi-kilobyte string — and require **zero**
non-zero results.

A static grep for the pattern proves the code changed. It does not prove the race is
gone. This does, and it is the test that would have caught the original defect.

### FR-T5HSP-005 — assertion semantics unchanged

`assert_contains` / `assert_not_contains` MUST keep their current contract exactly:
same arguments, same return codes for genuine match / non-match, same stderr shape.
A here-string and a pipe deliver identical bytes to `grep`; nothing else may change.

---

## Non-Functional Requirements

### NFR-T5HSP-001 — the four collateral harnesses stop flaking

After the fix, `b8-1`, `b8-12`, `b8-13`, `b8-14` and `b8-15` MUST each exit 0 on a
**repeated** run (≥ 10 consecutive invocations). A single green run proves nothing
about a ~7 % failure rate — that is how this survived.

### NFR-T5HSP-002 — no harness body is touched

122 call sites across 11 harnesses keep working unchanged. The fix is confined to
the helper they all source.

### NFR-T5HSP-003 — budget

`_helpers.sh` is sourced by every harness; the change must not add measurable
runtime. A here-string is strictly cheaper than forking `printf` into a pipe.

---

## ADRs

### ADR-T5HSP-001 — here-string, not `set +o pipefail`

**Context.** Three ways to stop a SIGPIPE from failing the assertion: disable
`pipefail` around the pipeline, ignore grep's pipeline status, or remove the pipe.

**Decision.** Remove the pipe: `grep -Fq -- "$needle" <<<"$haystack"`.

**Rejected.** Toggling `pipefail` inside a helper leaks a shell option into every
caller's scope if the restore path is ever skipped, and silently weakens genuine
pipeline-failure detection for the duration. Ignoring the status means the assertion
can no longer distinguish "no match" from "grep could not run at all".

The here-string removes the *cause* rather than masking the symptom, and is what the
existing project note already prescribes — the note simply had not been applied to
the shared helper.

### ADR-T5HSP-002 — the "shared-tree race" explanation is retired, not amended

The standing explanation named the wrong mechanism, the wrong files and the wrong
harnesses. Amending it would leave a plausible-but-false story in circulation. The
record states what was measured — the tree is never mutated — and names the real
chain, so the next person to see `b8-14` red does not go looking at
`docker-compose.dev.yml` again.
