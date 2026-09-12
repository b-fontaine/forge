# Proposal — `b9-11-promotion-gate`

Promote `mobile-pwa-first / 2.0.0` from `candidate` to `stable` / `scaffoldable: true`,
behind a new `b9.test.sh` gate — and complete the cascade that flip forces.

## The flip is not a two-line edit, and the repository already proved it

§5.2 describes this brick as *"Harness `b9.test.sh` : 25–30 tests L1 + 5 L2 fixture"*.
§0.14 records the other half: the `candidate → stable` flip breaks every sibling that
asserts `candidate`.

The precedent is `b7-6-harness`, which promoted `ai-native-rag` three months ago and
needed a follow-up commit (`d21dda1`) to finish what the flip started. Its message is
the most useful document in this repository for the work at hand:

> *"The cli Vitest job (npm test) — which my shell-only repro had missed — failed:
> `cli/test/e2e/archetypes-smoke.test.ts` hard-asserts `forge init --archetype
> ai-native-rag` REFUSES exit 3, a candidate-precondition the B.7.6 schema flip
> inverts."*

That e2e is **data-driven off the dispatch `status` field**: `scaffoldable = status !=
candidate` (needs a fixture), `candidates = status == candidate` (asserts the exit-3
refusal). So a scaffoldable schema left at `status: candidate` is internally
inconsistent, and — the sentence worth keeping — **there is no green state that keeps
`status: candidate`**. The flip is atomic or it is red.

## What the flip touches, mapped before anything moved

| | |
|---|---|
| `.forge/schemas/mobile-pwa-first/2.0.0.yaml` | `stage`, `scaffoldable`, and the header block documenting candidate semantics |
| `.forge/scaffolding/dispatch-table.yml` | `status: candidate` → `stable` |
| `cli/test/e2e/archetype-fixtures/mobile-pwa-first.yml` | **NEW** — `FR-T51-055` requires one per scaffoldable archetype |
| `b9-1.test.sh` T-003, T-006 | assert `stage == candidate` and the candidate header |
| `b9-2.test.sh` T-011, T-022, T-L2-001 | wrapper refuses exit 3; schema still candidate; `forge init` exits 3 |
| `b9-3.test.sh` T-023 | schema **and** dispatch still candidate |
| `docs/ARCHETYPES.md` | no row — and `b5`'s derived guard demands one the moment the status leaves `candidate` |
| `docs/MIGRATION-PATHS.md` | its Status paragraph says `candidate`, pinned by `T-028` |
| `.github/workflows/forge-ci.yml` | register `b9.test.sh` |

Two of those were planted deliberately by earlier bricks in this series so that this one
could not forget them: `b9-4` made `b5.test.sh` derive its expected rows from
`dispatch-table.yml` excluding candidates, and `b9-10` recorded in Q-003 that `T-028`
pins a paragraph the promotion falsifies. Both were verified by simulating the flip at
the time.

`bin/forge-init-mobile-pwa-first.sh` needs **no** edit: its gate reads `stage` and
`scaffoldable` out of the schema, so the flip makes it scaffold on its own. The
`FORGE_MPF_FORCE_SCAFFOLD` override becomes inert rather than wrong.

## The line budget fits, exactly

`forge-ci.yml` is **419 lines against a 420 cap** (NFR-CI-002, asserted in `c1`,
`t5-1` and `b6-8`). Registering `b9.test.sh` is one array entry: **420/420**. No
lock-step bump across four harnesses and two docs — the budget was reserved for this,
and it is now spent.

## Scope

**In:** the new `b9.test.sh` promotion gate; the schema and dispatch flips; the CLI
fixture; the inversion of every held candidate-guard; the `docs/ARCHETYPES.md` row and
the `MIGRATION-PATHS.md` status paragraph with `T-028`'s battery; CI registration;
CHANGELOG and resync.

**Out:** any template, snapshot or scaffold-plan change — the archetype's content is
finished, and this brick promotes it rather than extending it. No `pubspec` pin bump
(`b9-5` Q-001 remains a maintainer call).

## Negative scope

MUST NOT weaken a sibling guard to make the flip pass: each held guard is **inverted**
to assert the promoted state, never deleted. MUST NOT flip the schema without the
dispatch status in the same change — there is no green state in between. MUST reproduce
CI faithfully **including `cd cli && npm test`**, which is precisely what the `b7-6`
author's shell-only repro missed.
