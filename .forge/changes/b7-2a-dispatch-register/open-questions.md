# Open Questions — b7-2a-dispatch-register

<!--
Q-NNN sequential, never reused. Author-phase leanings recorded; resolutions at
/forge:design by an independent reviewer + maintainer (Article V).

## Resolution log
- **Q-001** resolved at /forge:design 2026-06-12 → (a) `since: "0.5.0"` (VERSIONING.md:31 — new archetypes ⇒ MINOR). ADR-B7-2A-004.
- **Q-002** resolved at /forge:design 2026-06-12 → (a) documentary `status: candidate`, no b5.test.sh change. ADR-B7-2A-005.
- Resolutions authored at design; independent reviewer + maintainer ratification pending at /forge:review (Article V).
- **Q-003** raised + resolved at /forge:review 2026-06-12 → (a) candidate stays discoverable in --help + refusal-asserted in smoke; CLI help text/snapshot + archetypes-smoke partition fixed. `cd cli && npm test` 87 passed / 1 skipped.
- Independent code-reviewer verdict: **APPROVE** (2026-06-12, after one fix iteration on the CRITICAL/HIGH CLI-e2e regression).
- **MAINTAINER RATIFICATION 2026-06-12**: BDFL ratified ADR-B7-2A-001..005 + Q-001/Q-002/Q-003. All decisions final. Cleared for archive.
-->

## Q-001: `since:` value for the ai-native-rag dispatch entry

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-12)
- **Raised in**: proposal.md (Ground truth), specs.md FR-B7-2A-001
- **Raised on**: 2026-06-12

### Question

The dispatch `since:` field is the framework version that registered the
archetype. The framework is at 0.4.0 (released); this change lands in
`[Unreleased]`. Is the next cut 0.5.0 (minor — a new archetype is a feature) or
0.4.1 (patch)?

`[NEEDS CLARIFICATION: confirm against docs/VERSIONING.md whether registering a
new (non-scaffoldable) archetype is a minor (0.5.0) or patch (0.4.1) on the 0.y
pre-GA track.]`

- (a) **`since: "0.5.0"`** *(leaning)* — a new archetype is an additive feature;
  minor bump on the 0.y track. Most consistent with full-stack (1.0.0) /
  mobile-only (1.2.0) being feature-introducing versions.
- (b) `since: "0.4.1"` — treat a not-yet-scaffoldable registration as a patch.
  Weaker: it still adds a user-visible archetype to `forge init`.

Resolve by reading `docs/VERSIONING.md` at design; non-blocking for the logic.

## Q-002: does the entry carry a `status:` marker?

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-12)
- **Raised in**: proposal.md (Solution step 1), specs.md FR-B7-2A-001
- **Raised on**: 2026-06-12

### Question

`mobile-only` carries `status: legacy_alias`; `flutter-firebase` carries
`status: removed_from_roadmap`. Should ai-native-rag carry a documentary
`status:` (e.g. `candidate` / `not_scaffoldable`) for human clarity?

`[NEEDS CLARIFICATION: add a documentary status: marker, or keep the entry plain
and let the candidate/scaffoldable:false schema + the refusing wrapper speak for
themselves?]`

- (a) **Add `status: candidate`** *(leaning)* — cheap human signal that the
  archetype is registered-but-not-scaffoldable. The dispatch parser tolerates
  `status`. **No `b5.test.sh` change needed** (the wrapper file exists, so the
  scaffolder-exists gate passes regardless of status). If chosen, a b7-2a L1 test
  asserts the marker.
- (b) Keep plain — the schema stage + the wrapper already encode the state.
  Avoids inventing a status enum value not used elsewhere.

## Q-003: CLI e2e coupling of an active dispatch-table archetype

- **Status**: answered → resolved (independent review HIGH/CRITICAL, fixed)
- **Raised in**: independent review of commit 5525f05, 2026-06-12
- **Raised by**: independent code-reviewer

### Question

Registering an **active** (`status !== removed_from_roadmap`) archetype couples to
two pre-existing T5.1 CLI e2e tests that the first author pass missed:
- `help-snapshots.test.ts` asserts every active archetype appears in `forge init
  --help` (hardcoded text at `cli/src/cli.ts:77` + the `init.snap.txt` snapshot);
- `archetypes-smoke.test.ts` treats every active archetype as scaffoldable —
  requires a fixture (`ENOENT` crash otherwise) and asserts scaffold exit 0,
  incompatible with the `candidate` archetype's exit-3 refusal.
So `cd cli && npm test` would FAIL in CI even though `verify.sh`, the linter, and
the shell harnesses are all green.

`[NEEDS CLARIFICATION: keep candidates discoverable in --help but excluded from the
scaffold matrix (and assert their refusal instead), or exclude candidates from
"active" everywhere?]`

- (a) **Discoverable + refusal-asserted** *(chosen)* — a candidate stays in
  `--help` (it IS a known archetype) and is exercised by a NEW smoke test that
  asserts exit 3 + no scaffold; it is partitioned OUT of the fixture/scaffold
  matrix until promotion. Fixes: `cli/src/cli.ts:77` help text + regen
  `init.snap.txt`; `archetypes-smoke.test.ts` partitions `status === "candidate"`.
  `cd cli && npm test` → 87 passed / 1 skipped. Keeps coverage on the new
  behaviour; the candidate rejoins the scaffold matrix at promotion (B.7.2).

### Q-003 addendum — a THIRD coupled test surfaced in CI (2026-06-13)

The fix above covered the two TS e2e tests, but CI then failed on a third,
SHELL-side enumerator the local gate run had not exercised:
`.forge/scripts/tests/t5-1.test.sh::_test_t51_l1_016_dispatch_xref` (FR-T51-055)
— the bash mirror of the smoke fixture cross-reference. It required a fixture for
every active archetype, excluding only `default`/`removed_from_roadmap`/`<removed>`,
not `candidate`. Fixed identically: exclude `status: candidate` from the fixture
requirement (both flush branches + the comment). Re-ran the **full** dispatch-coupled
set live — `t5-1` 17/0, `b5` 17/0, `j8` 18/0, `b8-15` 9/0, `b7-2a` 3/0, `b7-1` 18/0,
`cd cli && npm test` 87/1-skip — plus a repo-wide sweep for any other
active-archetype enumerator (`init.test.ts` uses its own table + `"made-up"`;
`b8-15` hardcodes the fsm fixture; `j8` is the forbidden list — all safe).
**Reinforced lesson (III.4):** the coupling was THREE tests, not two; the
ground-truth pass must grep every `FIXTURES_DIR` / active-archetype enumerator
(shell AND TS), and the gate run must execute the full harness array, not a
subset. B.7.2-full re-checks all three at promotion.
- (b) Exclude candidates from "active" everywhere — rejected: it would hide the
  archetype from `--help` despite it being a real, registered choice, and lose the
  refusal assertion.

### Lesson (Article III.4)

The proposal's ground-truth pass traced `init.ts`/`resolveScaffolder`/`b5.test.sh`
but did NOT enumerate the e2e tests that cross-reference the dispatch table. The
author's gate run also omitted `cd cli && npm test`. Both fixed; NFR-B7-2A-001
blast-radius corrected. Recorded so B.7.2-full (promotion) re-checks the same
e2e couplings when it flips the candidate to scaffoldable.
