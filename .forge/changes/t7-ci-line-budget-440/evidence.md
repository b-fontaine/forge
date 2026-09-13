# Evidence — `t7-ci-line-budget-440`

2026-09-13.

---

## P-1 — the documented lock-step list was wrong

`forge-self-ci.md:45`: *"The budget is asserted in four harnesses (c1, g1, t5-1,
t5-otel-live-run) — bump them in lock-step."*

`b6-8.test.sh:73`: `CI_LINE_BUDGET=420`.

A brick following the standard would have bumped four of five and shipped a red CI.

## P-2 — the set, measured

One line written over the cap, ten candidates run, restore verified by sha256:

```
probe: forge-ci.yml at 421 lines (over the 420 cap)

  c1                   FIRED  forge-ci.yml is 421 lines (> 420 NFR-CI-002 budget)
  g1                   FIRED  workflow 421 lines > 420 (NFR-CI-002)
  t5-1                 FIRED  forge-ci.yml is 421 lines, exceeds NFR-CI-002 / NFR-T51-005 budget of 420
  t5-otel-live-run     FIRED  forge-ci.yml is 421 lines, exceeds NFR-CI-002 budget of 420
  b6-8                 FIRED  forge-ci.yml is 421 lines (> 420 budget)
  b9-2                 silent
  b8-12                silent
  b8-15                silent
  f1                   silent
  d5                   silent
```

## P-3 — after the bump, the same probe

```
at 421 lines, 0 guard(s) fired
```

Five before, zero after. And `grep -rn "420" .forge/scripts/tests/*.sh` outside comments
returns nothing — no assertion was missed.

## P-4 — the growth is a curve, not a run of accidents

250 → 300 (2026-05-12) → 340 → 380 (2026-06-23) → 400 → 420 (2026-07-12) → 440
(2026-09-13). Four bumps in four months.

The `harnesses=(...)` array is **102 of the file's 420 lines** and costs one line per
harness. The 2026-05-31 loop refactor removed the *second* line per harness and left the
first, which is why the curve continued.

Measured cost of the remedy that would end it: **30 harnesses read `forge-ci.yml`**, and
at least seven grep it for their own registration — `b4`, `b6-8`, `b7-7`, `f1`, `f2`,
`f4`, `d5`. Recorded in both the spec and the standard so the fifth bump meets the
argument rather than rediscovering it.

## P-5 — regression

Five budget harnesses green (c1 30/0, g1 14/0, b6-8 23/0, t5-1 17/0,
t5-otel-live-run 8/0) · full CI matrix 81/81 · `verify.sh` + `constitution-linter.sh`
after the status flip · shellcheck clean · `forge-ci.yml` byte-unchanged.
