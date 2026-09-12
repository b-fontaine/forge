# Open questions — `t7-forbidden-archetypes-wiring`

## Q-001 — archetypes refuse CLI-side, combinations refuse wrapper-side

After this change the asymmetry is explicit: `forbidden_archetypes` is enforced by the
CLI dispatcher, and `forbidden_combinations` by `_refuse_if_forbidden_combination` in
`bin/_forge-init-helpers.sh`, called from the permitted wrappers.

Both work. But an adopter who bypasses the CLI and runs a wrapper directly gets
combination refusals and **not** archetype refusals; one who uses the CLI gets archetype
refusals and reaches combination refusals only because the wrapper it invokes performs
them. The defense-in-depth story is real and the coverage is uneven.

Not resolved here (`ADR-T7FA-002`): teaching the CLI `forbidden_combinations` would
create a second implementation of `ai-native-rag`'s provider × tier refusals, which is
J.8.c's contract. The question is whether the two lists should be enforced at the same
layer, and it belongs to whoever owns J.8.

## Q-002 — `parseDispatchTable` is a hand-rolled subset parser with no unit tests

`NFR-IW-002` forbids a third-party YAML dependency, which is defensible for a file this
narrow. But `cli/test/domain/` has no `dispatch-table.test.ts`: the parser's only
coverage is indirect, through suites that consume its output.

Three defects lived in it undetected — a missing block, a leaking field, an unstripped
comment — and two were found by printing its output by hand. A focused unit suite
(`archetypes:` variants, block boundaries, quoted and commented scalars) would be
cheap and is the obvious next step. Not done here because the brick's deliverable is
the refusal, and a parser suite written in the same pass as the parser fix tests what
the author just had in mind rather than what the grammar admits.

## Q-003 — nothing asserts the scaffolder path resolves

The fall-through this brick removes was survivable only because it ended in `exec` of a
literal `<removed>`. Nothing checks that a dispatch entry's `scaffolder:` names a file
that exists before it is run — an entry with a typo behaves exactly as
`flutter-firebase` did: exit 127 and a shell error.

`b9.test.sh` T-008 checks it for `mobile-pwa-first` alone. A table-wide check belongs in
`t5-1`'s cross-reference battery, which already walks every entry.
