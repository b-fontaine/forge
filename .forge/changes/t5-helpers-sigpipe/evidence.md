# Evidence — `t5-helpers-sigpipe`

All probes 2026-09-09.

---

## P-1 — the standing explanation, refuted by measurement

The recorded cause was a shared-tree snapshot race: `b8-obi`/`b8-signoz` rebuilding
`docker-compose.dev.yml` while `b8-1` read it.

Ran `b8-1`, `b8-obi`, `b8-signoz`, `b8-coroot`, `b8-12`, `b8-13`, `b8-14`, `b8-15`,
`b8o` in sequence, hashing `git status --porcelain` after each:

```
  b8-1         exit=0  tree clean
  b8-obi       exit=0  tree clean
  b8-signoz    exit=0  tree clean
  b8-coroot    exit=0  tree clean
  b8-12        exit=0  tree clean
  b8-13        exit=0  tree clean
  b8-14        exit=1  tree clean
  b8-15        exit=1  tree clean
  b8o          exit=0  tree clean
```

**No harness mutates the repository.** `examples/forge-fsm-example/docker-compose.dev.yml`:
mtime 2026-06-06, byte-identical to HEAD, and it *does* contain `postgres:16-alpine`.
The hypothesis is not merely unproven — it is contradicted.

## P-2 — a failing run reports no failing test

`b8-15` failing runs print `Failed: 0` in the body and exit non-zero. That is a
**coupling guard**, not a test — which redirected the search from the harness to
what it invokes.

## P-3 — the chain, and the leaf

```
b8-15::_test_b815_006_coupling
  └─ b8-14::_test_b814_015_coupling_guards
       └─ b8-13::_test_b813_018_coupling_guards
            └─ b8-12::_test_b812_023_coupling_guards
                 ├─ b8-1   → 0 0 1 1 1 0 0 0   (8 runs)
                 └─ b8-10  → 0 0 0 0 0 0 0 0   (8 runs)
```

`b8-1` is the only flaky leaf. One ~7 % failure, four harnesses red in shifting
combinations — which is precisely why it read as environmental.

## P-4 — the failing assertion

```
matrix pin postgres:16-alpine (live drift — doc disagrees with source):
  needle='postgres:16-alpine' not in haystack
```

`b8-1::_test_b81_l1_002_component_matrix`, asserting a pin that is present in the
file it just read.

## P-5 — the first hypothesis, apparently refuted, then confirmed

The project note said this fires "once the stream passes 64 KiB". Measured the
streams: `$body` 9 507 B, `$live` 23 723 B — both under. 200 iterations of the exact
pipeline against the 9 KB stream: **always 0**. On that evidence the mechanism looked
wrong.

Re-tested against the 23 KB stream with the pin that matches at offset **1735**:

```
  live length: 23723
  offset of first match: 1735
  non-zero pipeline exits over 500 runs: 36     (57 on a later run)
```

The mechanism was right; the note's precondition was wrong. **A closed pipe gives
EPIPE regardless of how much would have fit** — the 64 KiB buffer makes the failure
*certain*, not *possible*. Recorded, because a correct diagnosis was nearly discarded
on a wrong threshold.

## P-6 — the fix, measured against the defect

```
  pipe form      (current): 57 failures / 500
  here-string fix         : 0 failures / 500
```

## P-7 — RED before GREEN, and a first RED that did not count

Both guards written first. Initial run: RED with `command not found` — the block had
been inserted **inside `main()`**. A test red for the wrong reason is not a RED; the
block was moved above `main()` and re-run:

```
  _helpers.sh pipes into an early-exiting reader (FR-T5HSP-001/002)
  assert_contains failed 185/300 times on a needle that IS present
```

After the three-line fix: `foundations.test.sh` **24/24 GREEN**.

## P-8 — both guards mutation-probed

Reintroducing one piped form into `_helpers.sh` reds **both**: the static guard
naming the line, and the behavioural guard at **247/300**. The wide margin matters —
a guard that only just fails could go quiet on faster hardware.

Semantics unchanged (FR-T5HSP-005), all four cases:

| case | result |
|---|---|
| `assert_contains`, present needle | 0 ✓ |
| `assert_contains`, absent needle | non-zero ✓ |
| `assert_not_contains`, absent needle | 0 ✓ |
| `assert_not_contains`, present needle | non-zero ✓ |

The behavioural guard carries the last two as an internal positive control: without
them, a helper returning 0 unconditionally would pass the determinism loop perfectly.

## P-9 — the collateral harnesses, repeated

| harness | runs | result | before |
|---|---|---|---|
| `b8-1` | 15 | all 0 | `0 0 1 1 1 0 0 0` |
| `b8-12` | 10 | all 0 | intermittent |
| `b8-13` | 10 | all 0 | intermittent |
| `b8-14` | 10 | all 0 | `0 0 1`, and `1 1 1 1` on a pristine worktree |
| `b8-15` | 10 | all 0 | `0 0 0 1 1` |

Repeated runs, not single ones — a 7 % failure rate passes a single green run 93 %
of the time, which is how this survived.

## P-10 — regression

- `verify.sh` **611 / 0**; `constitution-linter.sh` **90 PASS / 0 FAIL, OVERALL
  PASS** — after the status flip.
- `shellcheck --severity=warning` over `.forge/scripts` and `bin` — clean. It first
  flagged **SC2155 in my own new test** (`local helpers="$(dirname …)"`), which
  would have turned the `Shell lint` job red; split into declare-then-assign.
- Full 80-entry CI matrix sweep: **80 GREEN / 0 RED**.

The sweep number needed three corrections before it meant anything (Q-004): it
matched only entries carrying `--level` (70 of 80), it probed two harnesses with a
bare invocation instead of the registered one, and it passed the arguments as a
single unsplit word from zsh. Each error made the picture cleaner than reality.
