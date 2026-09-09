# Design — `t5-helpers-sigpipe`

## The change

```diff
-  if ! printf '%s' "$haystack" | grep -Fq -- "$needle"; then
+  if ! grep -Fq -- "$needle" <<<"$haystack"; then
     echo "    ${msg}: needle='${needle}' not in haystack" >&2
-    echo "    haystack preview: $(printf '%s' "$haystack" | head -5)" >&2
+    echo "    haystack preview: $(head -5 <<<"$haystack")" >&2
```

and the same substitution in `assert_not_contains`. Three lines.

A here-string materialises the whole value before `grep` starts, so there is no
writer left running when `grep` exits. Identical bytes reach `grep`; only the
delivery mechanism changes (FR-T5HSP-005).

## How the diagnosis was reached, and what it overturned

Each step was executed, because the standing explanation was plausible and wrong.

1. **`b8-12` in isolation: 6/6 green** — yet red inside a sweep. So the cause is not
   in `b8-12`.
2. **Tree-mutation check.** Ran nine b8 harnesses in sequence, hashing
   `git status --porcelain` after each. **Never mutated.** That retires the
   shared-tree hypothesis outright — no file is being rebuilt under anyone.
3. **A failing run prints no `FAIL` line**, only a non-zero exit. That is a coupling
   guard failing, not a test — which pointed at the chain rather than the harness.
4. **Followed the chain** b8-15 → b8-14 → b8-13 → b8-12 → {b8-1, b8-10}. Leaves
   probed 8× each: `b8-1` = `0 0 1 1 1 0 0 0`, `b8-10` = `0 0 0 0 0 0 0 0`.
5. **`b8-1`'s failing assertion**: `matrix pin postgres:16-alpine (live drift)` —
   reporting a needle absent that is in the file.
6. **First hypothesis was SIGPIPE at ≥ 64 KiB**, from the existing project note.
   Measured the streams: 9 507 B and 23 723 B — both well under. 200 iterations
   against the 9 KB one: always 0. **Hypothesis apparently refuted.**
7. **Re-tested against the 23 KB stream** with the pin that matches at offset 1735:
   **57 non-zero exits per 500**. The mechanism was right; the 64 KiB threshold in
   the note was wrong. A closed pipe gives EPIPE regardless of what would have fit —
   the buffer size makes the failure *certain*, not *possible*.

Step 6 is the one worth keeping: a correct mechanism was nearly discarded because
the note attached a wrong precondition to it.

## Why the guards are two, not one

| Guard | Proves | Blind to |
|---|---|---|
| static — no `\| grep`/`head` in `_helpers.sh` | the code changed | whether the race is actually gone |
| behavioural — 300 × `assert_contains`, zero failures | the race is gone | a future pipe added elsewhere |

The behavioural one carries a **positive control**: an absent needle must still
fail, and `assert_not_contains` must still fire on a present needle. Without it, a
helper that returned 0 unconditionally would pass the determinism loop perfectly.

Its haystack is shaped like the real failure, not arbitrarily: sentinel at offset 0
of ~43 KB, which maximises unwritten bytes at reader exit. Against the unfixed
helper it fails **185/300** — a margin wide enough that the guard cannot go quiet
through timing luck on a faster machine.

## Placement

Both guards live in `foundations.test.sh` rather than beside any consumer.
`_helpers.sh` is sourced by every harness in the directory — 11 of them use these
assertions across 122 sites — so it is foundational infrastructure, and
`foundations.test.sh` is already CI-registered.

## Ordering (TDD)

1. Both guards → run against the **unfixed** helper → confirm RED **for the stated
   reason**. (First attempt failed on `command not found`: the block had landed
   inside `main()`. A test red for the wrong reason is not a RED.)
2. Fix the three lines.
3. GREEN.
4. Mutation-probe both guards; semantics probe on both helpers.
5. `b8-1` ×15, then `b8-12`/`b8-13`/`b8-14`/`b8-15` ×10 each.
6. Two full CI sweeps, comparing red sets — one green sweep does not settle a 7 %
   failure rate.
7. Correct the two memory notes that recorded the wrong mechanism.
