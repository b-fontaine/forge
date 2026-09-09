# Open questions — `t5-helpers-sigpipe`

## Q-001 — ~60 harnesses still carry the pattern in their own bodies (OUT, tracked)

This change fixes `_helpers.sh`, which 11 harnesses and 122 call sites route
through — where all the observed damage was. It does **not** touch the harnesses'
own bodies, which `b9-3`'s evidence P-4 already counted at roughly 40 sites, most of
them `find … | grep -q .`.

Those were assessed as latent rather than broken because their streams are small.
**That reasoning is now known to be unsafe**: the failure is a race at any size, and
the risk rises with how *early* the match lands, not with absolute bytes. A
`find | grep -q .` that matches on the first path is a worse shape than a 20 KB
stream matching at the end.

The sweep stays a brick of its own — 60 edits with no shared abstraction to hide
behind — but it should no longer be justified by "the streams are too small".

## Q-002 — should the coupling-guard chain exist at all?

Four harnesses re-running each other as subprocesses turned one leaf defect into
four red harnesses and a multi-minute sweep. The guards do buy something real
(a change to `b8-1`'s invariants surfaces immediately in the bricks that depend on
them), but the cost is paid on every run by every consumer, and the diagnosis cost
was high: the failure surfaced four levels away from its cause with no failing test
named.

Not decided here. Worth weighing against running the siblings once in CI rather than
transitively from inside each harness.

## Q-003 — `assert_contains`'s preview line was never load-bearing

`$(printf '%s' "$haystack" | head -5)` has the same shape, but its exit status is
unchecked, so a SIGPIPE there was invisible. Fixed anyway (FR-T5HSP-002).

Recorded because it is the kind of instance a future sweep might skip as harmless.
It is harmless *today*, purely because nobody reads its status — one refactor from
mattering, and it teaches the pattern to whoever reads the helper next.


## Q-004 — RESOLVED: `scaffolder` / `workflow` were never failing; my sweep was

Both sweeps reported them red, reproducibly, while they exited 0 in isolation. That
looked like a second phenomenon the b8 noise had been masking. It was not.

Captured output:

```
scaffolder.test.sh: unknown flag ' --level 1,2' (try --help)
```

The argument arrived as **one word**, not three. The sweep loop did
`bash "$harness" $args` from an interactive **zsh**, and zsh does not word-split
unquoted parameter expansions. So every entry got `" --level 1,2"` as a single
argument. 78 harnesses parse `--level` by looping over `"$@"` and silently ignore a
non-matching word, falling back to their default level; `scaffolder` and `workflow`
reject unknown flags outright and exit 2.

Two consequences, the second worse than the first:

1. The two reds were an artefact of the measuring instrument.
2. **Every sweep run this session under-tested.** Entries registered as
   `--level 1,2` ran at their default level, so opt-in L2 legs never executed while
   the sweep was reported as covering the CI matrix.

Fixed by running the loop under `bash` with `set -- $e`. This is the third
methodology defect in the same sweep helper this session — after matching only
entries with `--level` (70 of 80), and after probing `scaffolder`/`workflow` with a
bare invocation instead of the CI one. A throwaway measuring script accreted three
silent errors, each of which made results look better or cleaner than they were.
