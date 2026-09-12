# Design — `t7-forbidden-archetypes-wiring`

## The chain, and why it had three broken links rather than one

The brick opened on one defect and found a chain. Each link was individually plausible
and none was covered:

```
dispatch-table.yml          forbidden_archetypes:  ✓ data present since 2026-05
        ↓
parseDispatchTable          return { archetypes }  ✗ never read the block
        ↓
runArchetypeInit            (…?? []).find(…)       ✓ correct, never matched
        ↓ throw err, err.exitCode = 3
cli.ts catch                return 1               ✗ discarded the carried code
```

Link 2 was known (`b9-4` Q-001). Link 3 surfaced only after link 2 was fixed: the
refusal fired with the exact structured line and the process still exited **1**. A fix
that stopped at the parser would have shipped a refusal reporting the wrong code, and
`ADR-J8-003` specifies the code as part of the contract.

A fourth defect fell out of the same root. With no block tracking, every four-space
`since:` in the top-level blocks *after* `archetypes:` matched against the last
`currentName`. `flutter-firebase` — the last entry — parsed as
`"0.5.0"   # realigned 2026-09-08 …`: a wrong value **and** a trailing comment, taken
from `forbidden_combinations:`'s final row. Six other archetypes parse correctly
because each is followed by another entry that flushes.

## The parser change

Three pieces, smallest that closes the class:

| | |
|---|---|
| `type Block` + a `topLevel` match | any top-level key flushes and switches. This alone closes the `since` leak. |
| a `forbidden_archetypes` branch | `  - name:` opens an entry, `    key:` continues it, anything else in the block is ignored |
| `stripComment` | a `#` outside a quoted scalar ends the value |

`stripComment` is hardening rather than a fix on its own — once blocks are tracked, no
value inside `archetypes:` carries a comment today. It is there so that adding one
tomorrow cannot silently become part of a value, which is exactly how
`flutter-firebase.since` came to hold a sentence.

The return stays `{ archetypes }` when there is nothing forbidden, so no existing
caller sees a shape change.

## Coverage, in three layers

| layer | covers | why it is not enough alone |
|---|---|---|
| `cli/test/e2e/forbidden-archetype.test.ts` | the real parser and the real binary: exit 3, the structured line, nothing rendered | runs only in CI's `cli` job |
| `j8.test.sh` T-090 (L1) | the **data**: five keys per entry, every `rule_id` documented in `docs/ARCHETYPES.md` | asserts paperwork, not behaviour |
| `j8.test.sh` T-L2-090 | the behaviour against the built CLI | skip-pass without `cli/dist` |

The Vitest file is the primary guard. The shell cells catch the *next* forbidden
archetype being added without its paperwork — a different failure from the one this
brick fixes, and the one most likely to recur.

## What this brick falsifies in its own predecessor

`docs/ARCHETYPES.md`'s `flutter-firebase` row, written by `b9-4` two days ago, states
that the refusal *does not* fire and records exit 127. True when written, false now.
Corrected here, with the date, because a matrix cell describing a state that no longer
holds is the defect `b9-4` itself was opened to fix.

## Traps carried forward

- **Negative assertions never grep prose.** T-090 reads the YAML as data.
- **Needles anchored and unique.** The `rule_id` check greps the doc for a specific
  identifier, not for a word that recurs.
- **Anti-vacuity.** T-090 fails if the `forbidden_archetypes` list is empty rather than
  passing over nothing.
