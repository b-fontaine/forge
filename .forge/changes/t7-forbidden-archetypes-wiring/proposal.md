# Proposal — `t7-forbidden-archetypes-wiring`

Make J.8's `forbidden_archetypes` refusal reachable. It has been specified, coded,
documented in two places and asserted nowhere since 2026-05.

## The defect, measured

`cli/src/commands/init-archetype.ts:159-171` implements the refusal exactly as
`FR-J8-020` / `ADR-J8-003` specify — exit 3, and the structured stderr line
`[REFUSAL: <archetype>: <rule_id>: <reason> ; alternative: <alt>]`.

`cli/src/domain/dispatch-table.ts:115` returns `{ archetypes }`. It never parses the
top-level `forbidden_archetypes:` block, so `opts.dispatchTable.forbidden_archetypes`
is always `undefined`, `?? []` yields the empty list, and the `find` never matches.
**The refusal is unreachable code.**

What an adopter actually gets (measured 2026-09-11, unpiped):

```
$ node cli/dist/index.js init ffprobe --archetype flutter-firebase --org com.example.t
bash: /home/bfontaine/github/forge/cli/assets/<removed>: Aucun fichier ou dossier de ce nom
real exit = 127
```

The dispatcher falls through to the archetype entry, whose `scaffolder` is the literal
string `<removed>`, and execs it. Exit 127 with a shell error, in a language that
depends on the user's locale.

Two documents promise otherwise: `docs/ARCHETYPES.md:103` lists `J8-RULE-001` as a live
refusal, and `.forge/standards/global/janus-orchestration-rules.md` is the rule
catalogue. `b9-4` recorded the measurement in its Q-001 rather than fix it, because a
CLI behavioural change does not belong in a documentation brick.

## Why this is worth a brick rather than a one-line patch

The one-line patch is real — parse the block, return it. What makes it a brick is that
**nothing would have caught this and nothing will catch the next one**. J.8 shipped a
refusal path with no test that exercises it end to end; `b9-4` found it by running the
binary, not by reading a red suite.

So the deliverable is the parse **plus** the coverage that makes the refusal a tested
path: a Vitest case that runs `forge init --archetype flutter-firebase` and asserts
exit 3 with the structured line, and a shell guard asserting every
`forbidden_archetypes` entry is reachable through the parser.

## Scope

**In:** `parseDispatchTable` learns the `forbidden_archetypes:` block; a Vitest case
for the refusal; a shell guard that the parsed set matches the YAML; CHANGELOG.

**Out:** `forbidden_combinations:` — the sibling list consumed wrapper-side by
`_refuse_if_forbidden_combination`, which **is** wired and does fire. Widening the
parser to it would change `ai-native-rag`'s provider refusals, which are another
module's contract.

## Negative scope

MUST NOT change the refusal's exit code, message format, or position in
`runArchetypeInit` — all three are `ADR-J8-003`'s contract and the fix is that they
become reachable, not different. MUST NOT touch `dispatch-table.yml`'s data. MUST NOT
regress the `--help` golden snapshots.
