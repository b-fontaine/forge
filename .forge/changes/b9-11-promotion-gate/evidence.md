# Evidence — `b9-11-promotion-gate`

All probes 2026-09-12.

---

## P-1 — the cascade, mapped from the precedent rather than guessed

`b7-6-harness` promoted `ai-native-rag` on 2026-06-23 and needed a follow-up commit,
`d21dda1`, whose message is the most useful document in this repository for this brick:

> *"The cli Vitest job (npm test) — which my shell-only repro had missed — failed:
> `cli/test/e2e/archetypes-smoke.test.ts` hard-asserts `forge init --archetype
> ai-native-rag` REFUSES exit 3 … There is no green state that keeps
> `status: candidate`."*

Read before touching anything. It named the two things that make this flip dangerous:
the atomicity of schema-and-dispatch, and the fact that the failure surfaces in a job
no shell harness reaches.

Sweep of what actually asserts `candidate` for this archetype — five live guards in
`b9-1`, `b9-2`, `b9-3`; `b5`, `b8-3b`, `b7-1` and `delivery` mention the word only in
comments. `bin/forge-init-mobile-pwa-first.sh` needs no edit: `is_scaffoldable()` greps
`stage` and `scaffoldable` out of the schema, so the flip changes its behaviour with no
source change.

## P-2 — RED before GREEN

`b9.test.sh` written first, run against the unpromoted tree: **12 of 28 RED**, each
naming the field it expects. Exactly the flip-dependent cells.

A thirteenth failed for the wrong reason and is recorded in P-6.

## P-3 — the flip, and what it moved

| step | result |
|---|---|
| schema `stage`/`scaffoldable` + header, dispatch `status`, one edit | `b9.test.sh` 21/28; **the wrapper scaffolds with no override** |
| the CLI trust fixture | 25/28 |
| the two planted tripwires (docs) | 28/28 |

The wrapper cells are the ones worth naming: T-016 renders **without**
`FORGE_MPF_FORCE_SCAFFOLD` and T-018 proves the override is now inert rather than
harmful. Neither assumes the gate is data-driven — they execute it.

## P-4 — the two tripwires fired on their own

Both were planted by earlier bricks in this series precisely so this one could not
forget them, and both were verified by simulating the flip when they were written.

`b5.test.sh`, rewritten by `b9-4` to derive its expected rows from `dispatch-table.yml`
excluding candidates, the moment the dispatch status flipped:

```
    matrix has no row for `mobile-pwa-first`, which dispatch-table.yml registers as available (FR-B94-007)
```

`b9-2.test.sh::T-028`, whose needle battery `b9-10` Q-003 recorded as pinning a
paragraph this promotion falsifies:

```
    FAIL T-028: the section does not state 'candidate' — the target schema is not scaffoldable yet (FR-B910-004)
```

Two guards written days apart, each turning red at exactly the right moment, each
naming the requirement it was protecting. That is the whole argument for planting
tripwires instead of writing a checklist.

## P-5 — the cli Vitest job caught what 81 green shell harnesses did not

```
  harnesses: 81 green / 0 red (of 81)

  FAIL test/e2e/archetypes-smoke.test.ts > scaffolds mobile-pwa-first + file matrix
  archetype 'mobile-pwa-first': required path missing:
    android/app/src/main/kotlin/com/example/promo/PlayIntegrityService.kt
```

The fixture listed a Kotlin path containing **`com/example/promo`** — the reverse
domain of the probe I read the tree off. The smoke test renders with
`--org dev.forge.test`, so the package directory is `dev/forge/test` (ADR-B9-2-006
relocation).

`b9.test.sh` T-021 checks the fixture against a real render and **passed**, because it
rendered with the same org the fixture was built from. Two artefacts agreeing on a
wrong answer because they shared a wrong input.

Two fixes, because one would have left the trap armed:
- the path is removed from the fixture — no flat path can name an org-derived
  directory, which is why `mobile-only.yml` omits it too; `b9-2::T-009` covers the
  relocation against a render whose org it controls;
- `b9.test.sh`'s `PROBE_DOMAIN` is now `dev.forge.test`, the smoke test's, so T-021 and
  the Vitest job can no longer agree on a wrong answer.

`cd cli && npm test` after: **16 files, 90 tests, 0 failed.**

This is the failure `d21dda1` warned about, in a different disguise, found because the
warning was read first.

## P-6 — a negative assertion fired on its own explanation, twice

`b9.test.sh` T-028 was `grep -qF '@connectrpc/'` over the web-pwa `package.json.tmpl`.
It went red on a correct tree: line 11 of that file says *"NO @connectrpc/* dependency:
mobile-pwa-first is layer_profile client-only and…"*. The template documents what it
excludes and the grep read the documentation as the violation.

Rewritten to parse the JSON and assert on `dependencies` / `devDependencies` /
`peerDependencies`, which is exactly what `b9-2::T-013` already does and says it does.

Then again, in the doc: T-023 asserts the matrix row does not say `candidate`, and my
first row read *"Promoted candidate → stable at B.9.11"*. Reworded to *"Promoted to
stable"* — a decision-matrix cell does not need the word, and weakening the guard to
accommodate prose would have been the wrong trade.

Fifth and sixth instances in four days of an assertion matching something other than
what it names.

## P-7 — mutation probes

Each mutates a real file, runs the gate, restores, and verifies the restore by sha256.

| probe | result |
|---|---|
| schema demoted to `candidate` | RED (5 cells) |
| `scaffoldable` reverted to false | RED (6) |
| dispatch status reverted | RED (2) |
| fixture archetype name wrong | RED (1) |
| matrix row removed | RED (2) |
| `mobile-only`'s `target:` orphaned | RED (1) |
| the B.9.4 decision tree renamed away | RED (1) |

**7/7.** The coherence cells are visible in the counts: demoting only the schema trips
five, because T-003, T-012 and T-013 assert the schema and dispatch agree in both
directions — the half-state `d21dda1` had to repair cannot return silently.

## P-8 — the line budget, spent exactly

`forge-ci.yml` was 419 lines against the 420 cap of NFR-CI-002. Registering
`b9.test.sh` is one array entry:

```
registered; forge-ci.yml is now 420 lines (budget 420)
```

`c1` 30/0 and `t5-1` 17/0 — the budget guards — both green. No lock-step bump.

## P-9 — regression

- Full CI matrix, now **81 entries: 81/81**.
- `cd cli && npm test`: **90/90**.
- `b9-1` 23/0, `b9-2` 33/0, `b9-3` 27/0 — with their held guards inverted, not deleted.
- `b5` 17/0, `b4`, `b8-2` (frozen trees).
- `shellcheck --severity=warning` clean.
- `verify.sh` + `constitution-linter.sh` after the status flip: `tasks.md` T6.

## P-10 — negative scope

Nothing under `.forge/templates/` or `.forge/scaffold-snapshots/`; no `bin/` source
change. The archetype's content was finished by B.9.5 and this brick promotes it —
a promotion that also changed content would make a later bisect ambiguous.
