# Design — `b9-11-promotion-gate`

## Order of operations

The flip has no green intermediate, so the sequence is chosen to keep each step
*diagnosable*, not to keep the tree green throughout:

```
1. write b9.test.sh asserting the PROMOTED state      → RED, every cell, for the right reason
2. flip the schema + the dispatch status together     → b9.test.sh goes GREEN
                                                       → six sibling guards go RED (expected)
3. invert those six                                   → siblings GREEN
4. add the CLI fixture                                → cli npm test GREEN
5. discharge the two planted tripwires (docs)         → b5 + T-028 GREEN
6. register b9.test.sh in forge-ci.yml (419 → 420)
7. full regression, cli/ included
```

Step 1 before step 2 is the RED that matters: a gate harness written after the flip
would pass on first run and prove nothing.

## `b9.test.sh` — what it asserts

Twenty-eight L1 cells plus two L2, grouped by the surface each protects. It asserts the
**promoted state** as a standing invariant, not that a promotion occurred
(`ADR-B911-002`).

| group | cells | protects against |
|---|---|---|
| schema | 6 | a half-reverted flip: stage, scaffoldable, the two agreeing, the header no longer describing a candidate, `layer_profile`, the two layers |
| dispatch | 5 | status drift, the `mobile-only` alias still pointing here, the wrapper path, signals, `since` |
| coherence | 4 | schema ↔ dispatch agreement in **both** directions — the inconsistency `d21dda1` was written to fix |
| wrapper | 3 | it scaffolds **without** `FORGE_MPF_FORCE_SCAFFOLD`; the override is inert; a render produces both surfaces |
| CLI trust | 3 | the fixture exists, names the archetype, and lists paths the render actually produces |
| docs | 4 | the matrix row, its status cell, the MIGRATION-PATHS status paragraph, the decision-tree section still present |
| tooling | 3 | the migration script and the bloc generator still run against the promoted archetype |
| L2 | 2 | a real `forge init` renders; the rendered tree matches the fixture |

The overlap with `b9-1`/`b9-2`/`b9-3` is deliberate. Those own their brick's
deliverables; this one owns the coherence of the promoted whole.

## The two planted tripwires

Neither is discovered here — both were installed earlier in the series specifically so
this brick could not forget them, and both were verified by simulating the flip at the
time they were written.

**`b5.test.sh`** (from `b9-4`) derives its expected matrix rows from
`dispatch-table.yml`, excluding `candidate` and `removed_from_roadmap`. The moment
`FR-B911-003` lands, `mobile-pwa-first` enters the derived set and the guard reports
`matrix has no row for mobile-pwa-first`. The row is written in response to a red test,
which is the right way round.

**`T-028`** (from `b9-10`) pins `MIGRATION-PATHS.md`'s needles including `candidate`,
`B.9.11` and `exit 3`. Those describe a state the flip ends. The battery's rows change
with the paragraph, and its anti-vacuity count moves with them — `b9-10` Q-003 wrote
down exactly this obligation.

## The CLI fixture

`cli/test/e2e/archetypes-smoke.test.ts` runs `forge init <slug> --archetype
mobile-pwa-first --org dev.forge.test` and checks `required_paths` / `forbidden_paths`.
The slug is derived as `smoke_${name.replace(/-/g, '_')}`, so
`smoke_mobile_pwa_first` — which the Flutter scaffolder's `[a-z][a-z0-9_]+` rule
accepts.

Built from `mobile-only.yml` plus the `web-pwa/` surface, because a migrated tree is
byte-identical to a native render of this archetype (`b9-9` P-5) and the native render
is exactly what the smoke test produces. `has_rust_backend: false`,
`has_flutter_frontend: true`.

## What is NOT touched, and why it matters

`bin/forge-init-mobile-pwa-first.sh` is data-driven off the schema (`is_scaffoldable()`
greps `stage` and `scaffoldable`), so the flip makes it scaffold with no source change.
A test proves that rather than assuming it — the difference between "the wrapper should
work now" and "the wrapper works now".

No template, snapshot or scaffold-plan edit. The archetype's content was finished by
B.9.5; a promotion that also changed content would make a later bisect ambiguous.

## Reproducing CI

`b7-6` shipped this exact flip red because its author's repro was shell-only and the
failure was in `cli/`'s Vitest job. The regression here runs the full 80-entry harness
matrix **and** `cd cli && npm test`, and the latter is the one that matters: the smoke
test is the only thing in the repository that partitions archetypes off the dispatch
`status` field.
