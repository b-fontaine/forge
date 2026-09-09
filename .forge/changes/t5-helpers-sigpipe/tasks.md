# Tasks — `t5-helpers-sigpipe`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — RED

- [x] **T1.1** Add `_test_fnd_helpers_no_pipe_into_grep` to `foundations.test.sh`:
      static guard that `_helpers.sh` contains no `printf … | grep` / `| head`.
      [Story: FR-T5HSP-003]
- [x] **T1.2** Add `_test_fnd_helpers_assert_is_deterministic`: call
      `assert_contains` N times against an early-match multi-KB haystack, require
      zero failures.
      [Story: FR-T5HSP-004]
- [x] **T1.3** Run both against the **unfixed** helper. **Confirm RED**, and confirm
      the probabilistic one fails on the race rather than on a typo in the fixture —
      a fixture that never matches would also go red, for the wrong reason.
      [Story: FR-T5HSP-003, FR-T5HSP-004]

## T2 — GREEN

- [x] **T2.1** `assert_contains` → `grep -Fq -- "$needle" <<<"$haystack"`.
      [Story: FR-T5HSP-001]
- [x] **T2.2** `assert_not_contains` → same form.
      [Story: FR-T5HSP-001]
- [x] **T2.3** The preview line → `head -5 <<<"$haystack"`.
      [Story: FR-T5HSP-002]
- [x] **T2.4** Run the two new tests. **Confirm GREEN.**
      [Story: FR-T5HSP-003, FR-T5HSP-004]

## T3 — prove the tests are not vacuous

- [x] **T3.1** Mutation-probe the static guard: reintroduce one piped form, confirm
      RED naming the line.
      [Story: FR-T5HSP-003]
- [x] **T3.2** Mutation-probe the probabilistic guard: restore the piped
      `assert_contains` body, confirm it goes RED. If it stays green, the iteration
      count or the haystack shape is wrong and the test is decoration.
      [Story: FR-T5HSP-004]
- [x] **T3.3** Semantics probe: a needle genuinely absent must still fail, and
      `assert_not_contains` must still fail on a present needle. The fix must not
      turn assertions into no-ops.
      [Story: FR-T5HSP-005]

## T4 — the collateral harnesses

- [x] **T4.1** `b8-1.test.sh --level 1` × 15 consecutive runs, all exit 0.
      Before the fix it was `0 0 1 1 1 0 0 0`.
      [Story: NFR-T5HSP-001]
- [x] **T4.2** `b8-12`, `b8-13`, `b8-14`, `b8-15` × 10 each, all exit 0.
      [Story: NFR-T5HSP-001]
- [x] **T4.3** Full 80-entry CI matrix sweep. **Result: 80 GREEN / 0 RED.**
      Two earlier sweeps had reported 78/2 (`scaffolder`, `workflow`) — that was the
      sweep script, not the harnesses: run from zsh, `bash "$h" $args` passes
      `" --level 1,2"` as ONE word, which those two reject and the other 78 silently
      ignore while falling back to their default level. Re-run under `bash` with
      `set -- $e`: zero red, at the levels CI actually registers.
      See `open-questions.md` Q-004 — the same helper had two earlier defects this
      session, and all three made results look better than they were.
      [Story: NFR-T5HSP-001]

## T5 — records that were wrong

- [x] **T5.1** Correct the project memory: the "shared-tree snapshot race" note
      names the wrong mechanism; the 64 KiB threshold note is too narrow.
      [Story: FR-T5HSP-001]
- [x] **T5.2** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-T5HSP-001]
- [x] **T5.3** Record the coupling-guard chain somewhere a reader will find it, so a
      future red `b8-14` is traced to its leaf instead of re-investigated.
      [Story: NFR-T5HSP-001]

## T6 — regression

- [x] **T6.1** `shellcheck --severity=warning` over `.forge/scripts` and `bin`.
      [Story: NFR-T5HSP-002]
- [x] **T6.2** `verify.sh` + `constitution-linter.sh` **after** the status flip.
      [Story: NFR-T5HSP-002]

## Negative scope guard

- [x] **T7.1** `git diff --stat`: only `_helpers.sh`, `foundations.test.sh`, the
      change dir, `CHANGELOG.md`. No harness body, no template, no `overlay.sh`.
      [Story: NFR-T5HSP-002]
