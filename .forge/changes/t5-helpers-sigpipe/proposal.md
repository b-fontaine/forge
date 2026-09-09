# Proposal — `t5-helpers-sigpipe`

**The intermittent CI reds are one race, in one shared helper, three lines long.**

## What was believed

Project memory and several change records attribute the flakiness to a *shared-tree
snapshot race*: `b8-obi` / `b8-signoz` rebuilding `docker-compose.dev.yml` while
`b8-1` reads it, with `b8-12` / `b8-13` / `b8-14` / `b8-15` "inheriting" it.

**That is wrong**, and it is worth saying plainly because it has been the standing
explanation for months. Measured this session:

- Running each of `b8-1`, `b8-obi`, `b8-signoz`, `b8-coroot`, `b8-12`, `b8-13`,
  `b8-14`, `b8-15`, `b8o` in sequence and hashing `git status --porcelain` after
  each: **the tree is never mutated**. No harness writes into the repo.
- `examples/forge-fsm-example/docker-compose.dev.yml` has an mtime of 2026-06-06 and
  is byte-identical to HEAD.

## What it actually is

`_helpers.sh::assert_contains` is:

```bash
if ! printf '%s' "$haystack" | grep -Fq -- "$needle"; then
```

Every harness runs under `set -uo pipefail`. `grep -Fq` exits the instant it
matches, closing the pipe. `printf` still has the rest of the haystack to write, and
if grep's exit wins the race, `printf` takes SIGPIPE. With `pipefail` the pipeline
yields **141**, so `assert_contains` reports `needle not in haystack` — for a needle
that is right there.

Reproduced directly on the real data, 500 iterations of the exact pipeline:

| form | non-zero exits / 500 |
|---|---|
| `printf … \| grep -Fq` (current) | **57** |
| `grep -Fq … <<<"$haystack"` (fix) | **0** |

The failing needle is `postgres:16-alpine`, at offset **1735** of a **23 723**-byte
haystack — matched early, with ~22 KB left to write. That is the worst case for this
race and explains why this one assertion, out of 122 call sites, is the one that
shows.

### The 64 KiB rule was too narrow

The existing memory note says this fires "once the stream passes 64 KiB" — the pipe
buffer. That makes it *certain*; it is not *necessary*. At 23 KB it still fires 7–11 %
of the time, because a closed pipe gives EPIPE regardless of how much would have fit.
Corrected here and in the memory note.

## Why four harnesses go red for one bad line

`b8-1` is the flaky leaf. The rest is a **coupling-guard chain**, each harness running
its siblings as subprocesses:

```
b8-15::_test_b815_006_coupling
  └─ b8-14::_test_b814_015_coupling_guards
       └─ b8-13::_test_b813_018_coupling_guards
            └─ b8-12::_test_b812_023_coupling_guards
                 └─ b8-1  ← 0 0 1 1 1 0 0 0 over eight runs
                 └─ b8-10 ← 0 0 0 0 0 0 0 0 (stable)
```

So a single ~7 % leaf failure surfaces as four different harnesses going red in an
unpredictable combination — which is exactly what made it look like an
environment-dependent race rather than a deterministic bug in shared code.

## Scope

**In:** the three piped forms in `.forge/scripts/tests/_helpers.sh`
(`assert_contains` at :46 and its preview at :48, `assert_not_contains` at :58); a
guard so the pattern cannot come back; the corrected memory note.

**Out:** the ~60 harnesses that carry `printf | grep -q` in their *own* bodies. The
repo-wide sweep is already a tracked item; this change fixes the shared helper that
11 harnesses and 122 call sites route through, which is where the observed damage
is (`open-questions.md` Q-001).

## Negative scope

MUST NOT change any assertion's *semantics* — a here-string and a pipe feed grep the
same bytes. MUST NOT touch the harnesses' own bodies, `overlay.sh`, or any template.
