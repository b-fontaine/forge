# Open questions — `t7-ci-line-budget-440`

## Q-001 — the per-harness cost is still there, and 440 is ~18 harnesses away

This brick raises a ceiling. The array still grows one line per harness, and B.3 alone
is a 14-brick module — it will not need 14 harness entries, but it will need more than
one.

The remedy and its measured obstacle are now written into `.forge/specs/forge-ci.md`
and `forge-self-ci.md`, which is the most this brick can honestly do. Externalising the
array is a brick of its own: 30 harnesses read `forge-ci.yml`, and the seven that grep
it for their own registration would each need repointing at the new file, in lock-step,
in one commit — the same "no green state in between" shape as B.9.11's promotion.

## Q-002 — nothing asserts that the lock-step list is complete

The list is now correct and the method for checking it is prescribed. Neither is
enforced: a sixth harness could add a budget constant tomorrow and both documents would
go stale again, exactly as they did for `b6-8`.

A guard is possible — sweep the harnesses for a line-budget assertion and compare the
set against the documented list — and it is the kind of derived check `b9-4` built for
the archetype matrix. Not done here because this brick's deliverable is 20 lines of
headroom, and a guard over five files is larger than the change it would protect. Worth
folding into the externalisation brick, which touches all of them anyway.
