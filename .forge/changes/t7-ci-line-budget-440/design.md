# Design — `t7-ci-line-budget-440`

## Measure the lock-step set, do not read it

The repository's own guidance was wrong. `forge-self-ci.md` named four harnesses;
`b6-8.test.sh` had quietly become a fifth. A brick that followed the documentation
would have bumped four and pushed a red CI.

The method that works takes one probe: write one line over the cap into
`forge-ci.yml`, run every plausible harness, record which fire, restore. Ten candidates
tested, five fired, five stayed silent. That set is now what both documents state, and
the method is prescribed alongside it so the next author measures rather than reads.

## Why 440 and not more

Twenty lines is B.3's harness plus margin. A larger jump would postpone the structural
question further, and the structural question is the actual problem: the array grows one
line per harness and has been bumped four times in four months.

## What the documents now carry

Not just a number. Both the spec and the standard record:

- the growth mechanism (one line per harness, 102 of 420 lines today);
- that the 2026-05-31 loop refactor is spent — it removed the second line per harness,
  not the first;
- the remedy that ends it, with its measured cost: 30 harnesses read `forge-ci.yml`,
  ≥7 grep it for their own registration.

So the next bump meets a written argument instead of rediscovering it. That is the
difference between a ceiling raised five times and a decision deferred with its terms
intact.
