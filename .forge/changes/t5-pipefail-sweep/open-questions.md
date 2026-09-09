# Open questions — `t5-pipefail-sweep`

## Q-001 — 176 sites remain, by decision

The transform converts only unambiguous shapes. What is left: multi-line `||`
continuations, pipelines with more than two stages, and writers the transform
declined to reorder. All are listed with file:line in `skipped.json`.

None is in the proven-broken class — that set is empty. They sit on the risk curve
where the writer produces few lines, which is where measured failure is 0/200. That
is a weaker guarantee than "fixed", and it is stated as such rather than implied.

Converting them means either hand-editing 176 sites across 60 files, or a transform
that understands multi-line shell — which is a parser, not a regex. Neither is
justified by the current evidence.

## Q-002 — `bin/**` and `cli/**` are out of scope

`bin/forge-*.sh` also pipe into readers. They are not under the harness `pipefail`
convention and were not measured. Whether the same defect exists there is untested,
and saying "probably not" would repeat the mistake that classified the harness sites
as latent.

## Q-003 — `_test_b811_013` is a working-tree assertion, not an invariant

It fails for anyone who edits `constitution-linter.sh` until they commit, which
looked like a regression from this sweep for several minutes. Its intent (B.8.11 adds
no bash to the linter) was scoped to that change's own development; post-archive it
is a tripwire on an unrelated file. Worth re-scoping, in a change that owns b8-11.
