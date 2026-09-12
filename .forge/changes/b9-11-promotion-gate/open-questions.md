# Open questions — `b9-11-promotion-gate`

## Q-001 — `FR-B910-004` is superseded, and its change record still states it

`b9-10`'s `FR-B910-004` requires `docs/MIGRATION-PATHS.md` to carry the `candidate`
caveat. This brick removes that caveat, and updated `T-028`'s battery accordingly —
the needle now asserts `stage: stable` and cites `FR-B911-006`.

`b9-10/specs.md` is left unedited. Its status is `implemented`, and rewriting a
delivered change's requirements to match a later one erases the record of what was true
when it shipped. The supersession is stated in the harness comment, where anyone
reading the assertion will see it.

If the repository later wants superseded requirements marked in place, that is a
convention change affecting every archived change, not something to invent here.

## Q-002 — `forge-ci.yml` is now at 420/420

The budget reserved for this registration is spent. The next harness needs a bump, and
NFR-CI-002's 420 is asserted in **three** harnesses (`c1.test.sh:746`,
`t5-1.test.sh:406`, `b6-8.test.sh:73`) plus the docs that cite it — a lock-step edit.

Worth deciding before the next brick needs it, rather than under pressure: either raise
the cap with the same justification the 400→420 bump used, or restructure the matrix so
new harnesses do not each cost a line. The second is the better answer and the larger
change.

## Q-003 — the L2 cells are skip-pass without a built CLI

`b9.test.sh` T-L2-001 and T-L2-002 render through `cli/dist/index.js` and skip when it
is absent. CI's `cli` job builds it, but the harness job does not, so in practice the
shell matrix never runs them.

Not a defect of this brick — it is the convention every L2 cell in this repository
follows — but it means the *only* thing exercising `forge init --archetype
mobile-pwa-first` end to end in CI is `cli/test/e2e/archetypes-smoke.test.ts`. That is
adequate, and it is worth knowing that the coverage lives there rather than here.

## Q-004 — B.9 is complete; the archetype is not finished

The promotion closes B.9, but three measured gaps recorded by its own bricks remain
open and none is scheduled:

- `b9-10` Q-001 — `.forge/framework-owned-paths.yml` names nothing under `web-pwa/`,
  so `forge upgrade` never merges framework changes into the Qwik surface, for
  migrated and freshly-initialised projects alike.
- `b9-5` Q-001 — `state-management.yaml` pins `flutter_bloc: ^9.0.0`; both Flutter
  archetypes ship `^8.1.6`, and nothing catches it.
- `b9-4` Q-001 — `parseDispatchTable` never reads `forbidden_archetypes`, so
  `J8-RULE-001` is dead code and `forge init --archetype flutter-firebase` exits 127
  with a shell error instead of refusing cleanly.

The first is the one an adopter feels: they own `web-pwa/` outright now, which is
defensible, but it was never decided — it was inherited.
