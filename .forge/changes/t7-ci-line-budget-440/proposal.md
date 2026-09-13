# Proposal — `t7-ci-line-budget-440`

Raise `NFR-CI-002` from 420 to 440 so B.3 can register its harness, and correct the
lock-step list, which was wrong.

## Why now

`forge-ci.yml` sits at exactly **420/420**. B.9.11 spent the last reserved line
registering `b9.test.sh`. B.3 — a 14-brick module — cannot register `b3-1.test.sh`
without a bump, and the alternative used by B.9.9/B.9.10/B.9.4/B.9.5 (host the guards
in a sibling's harness) does not scale to a new archetype module.

Maintainer decision 2026-09-13: raise the cap. The structural fix is acknowledged and
deferred — see below.

## The lock-step list was stale, and the measurement caught it

`forge-self-ci.md:45` said *"asserted in four harnesses (c1, g1, t5-1,
t5-otel-live-run) — bump them in lock-step"*. `b6-8.test.sh:73` had added a
`CI_LINE_BUDGET=420` of its own without updating that list.

Rather than trust the count, the set was measured: push the workflow one line over the
cap and record which harnesses fire.

```
  c1                   FIRED    b9-2   silent
  g1                   FIRED    b8-12  silent
  t5-1                 FIRED    b8-15  silent
  t5-otel-live-run     FIRED    f1     silent
  b6-8                 FIRED    d5     silent
```

**Five, not four.** A brick following the standard's list would have bumped four and
shipped a red CI.

## What is not fixed

The per-harness cost. The `harnesses=(...)` array is **102 of the file's 420 lines** and
grows by one per harness — four bumps in four months is a curve, not a run of accidents.
The 2026-05-31 loop refactor removed the ~2-lines-per-harness cost and left one.

Externalising the array into a file the workflow reads would free ~80 lines and end the
growth. Measured obstacle: **30 harnesses read `forge-ci.yml`**, and at least seven grep
it for their own registration (`b4`, `b6-8`, `b7-7`, `f1`, `f2`, `f4`, `d5`). That is a
brick of its own, and it is now written into the spec and the standard so the next bump
meets the argument rather than rediscovering it.

## Scope

**In:** the five harness assertions, `NFR-CI-002`'s definition in
`.forge/specs/forge-ci.md`, the clause in `.forge/standards/global/forge-self-ci.md`,
and the correction of both documents' "four" to "five".

**Out:** the workflow itself — this brick adds no line to `forge-ci.yml`. B.3.1 spends
the first one.

## Negative scope

MUST NOT change any job, step or harness entry. MUST NOT externalise the array here.
