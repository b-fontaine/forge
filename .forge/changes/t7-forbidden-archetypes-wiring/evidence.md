# Evidence — `t7-forbidden-archetypes-wiring`

All probes 2026-09-12.

---

## P-1 — one reported defect, three broken links

`b9-4` Q-001 recorded that `parseDispatchTable` never reads `forbidden_archetypes`.
Fixing that exposed a second link, and probing the parser exposed a third defect of the
same root:

| link | state before | how it surfaced |
|---|---|---|
| `parseDispatchTable` returns `{ archetypes }` | the refusal's data never arrives | reported by `b9-4` |
| `cli.ts` catch does `return 1` | the refusal fires and reports the wrong code | only **after** link 1 was fixed |
| no block tracking ⇒ later `since:` leak into the last archetype | `flutter-firebase.since` is a sentence | found by printing the parser's output |

A fix that stopped at the parser would have shipped a refusal reporting exit 1, and
`ADR-J8-003` makes exit 3 part of the contract.

## P-2 — before

```
$ node cli/dist/index.js init ffprobe --archetype flutter-firebase --org dev.forge.test
bash: /home/bfontaine/github/forge/cli/assets/<removed>: Aucun fichier ou dossier de ce nom
real exit = 127
```

The dispatcher falls through to the archetype entry, whose `scaffolder` is the literal
string `<removed>`, and execs it. A locale-dependent shell error where the standard
specifies a structured line.

## P-3 — the `since` leak, measured before deciding scope

```
default                since="0.1.0"
full-stack-monorepo    since="1.0.0"
mobile-only            since="1.2.0"
mobile-pwa-first       since="0.5.0"
ai-native-rag          since="0.5.0"
event-driven-eu        since="0.5.0"
flutter-firebase       since="\"0.5.0\"   # realigned 2026-09-08 with the event-driven-eu entry — single 0.5.0 cut"
```

YAML declares `0.0.0`. **One field corrupted, six correct** — `flutter-firebase` is the
last `archetypes:` entry, so every four-space `since:` in the blocks that follow
overwrote it, the last one winning, comment included (`stripQuotes` returns the whole
string when the closing quote is not the final character).

The blast radius was measured before the fix was scoped, rather than the fix being
widened on a hunch.

## P-4 — RED before GREEN

`cli/test/e2e/forbidden-archetype.test.ts` against the unfixed tree: **3 of 4 RED**,
including `expected 3, received 127`.

After the parser fix: the refusal fires with the exact structured line, and the test
still fails — `expected 3, received 1`. That is P-1's third link, found by running the
suite rather than by reading the code.

After honouring the carried exit code: **4/4**.

## P-5 — after, live and unpiped

```
$ node cli/dist/index.js init ffprobe --archetype flutter-firebase --org dev.forge.test
exit = 3
[REFUSAL: flutter-firebase: J8-RULE-001: Schrems II + CLOUD Act incompatibles avec positionnement EU/premium Forge ; alternative: default archetype + add Firebase as adopter-managed overlay (out of Forge scope)]
tree created: no
```

Exit 3, the structured line `ADR-J8-003` specifies, nothing rendered. What
`docs/ARCHETYPES.md:103` has promised since May now happens.

`flutter-firebase.since` re-probed after the fix: **`"0.0.0"`**.

## P-6 — mutation probes on the drift guard

| probe | result |
|---|---|
| `alternative:` emptied | RED — "would render as 'undefined' inside the [REFUSAL: …] line" |
| `rule_id` changed to an undocumented one | RED — "absent from docs/ARCHETYPES.md" |

2/2, dispatch-table restored byte-identical. The RED→GREEN transition in P-4 is the
mutation proof for the behaviour cells: they failed on the real defect and passed on the
real fix.

## P-7 — this brick falsifies a claim its predecessor made

`docs/ARCHETYPES.md`'s `flutter-firebase` row, written by `b9-4` on 2026-09-11, states
that attempting the archetype **does not** produce the refusal and records exit 127.
True when written; false as of this commit. Corrected with the date rather than quietly
rewritten — the row now says what happens and what used to.

## P-8 — regression

- `cd cli && npm test`: **17 files, 94 tests, 0 failed** (was 16/90; the four new ones
  are this brick's).
- `j8.test.sh --level 1,2`: **22/0**.
- `b9` 28/0, `b5` 17/0 after the doc correction.
- Full 81-entry CI matrix, `shellcheck`, `verify.sh` + `constitution-linter.sh`:
  `tasks.md` T6.

## P-9 — negative scope

The refusal's exit code, message format and position in `runArchetypeInit` are
unchanged — the fix is that they became reachable. `dispatch-table.yml`'s data is
untouched. `forbidden_combinations:` is not parsed (`ADR-T7FA-002`): it is **not** dead
code, `_refuse_if_forbidden_combination` reads it wrapper-side and fires. The `--help`
goldens did not move; no flag and no usage text changed.
