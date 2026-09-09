# Tasks — `t5-pipefail-sweep`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — establish that it is broken, not latent

- [x] **T1.1** Measure the failure curve by lines-remaining, not bytes. The
      byte-only probe read 0/200 at 256 KB and was misleading.
      [Story: FR-T5PFS-001]
- [x] **T1.2** Prove `find <tree> | grep -q .` fails 200/200 under `pipefail`.
      [Story: FR-T5PFS-001]
- [x] **T1.3** Prove the consequence on `constitution-linter.sh:597` with a 3 000-file
      tree: branch taken 0/50.
      [Story: FR-T5PFS-001]

## T2 — the transform

- [x] **T2.1** Classify all 407 sites by whether the pipeline status is consumed.
      [Story: FR-T5PFS-002]
- [x] **T2.2** Write the transform; **dry-run on copies first** and inspect the diff.
      Two drafts produced invalid shell; neither reached the real tree.
      [Story: FR-T5PFS-002, NFR-T5PFS-002]
- [x] **T2.3** Apply: 107 automatic conversions across 43 files.
      [Story: FR-T5PFS-002]
- [x] **T2.4** Hand-convert the 5 multi-line `find … | grep -q . \` sites the
      transform refused.
      [Story: FR-T5PFS-001]
- [x] **T2.5** `bash -n` on every touched file — 0 errors.
      [Story: NFR-T5PFS-002]

## T3 — the guard

- [x] **T3.1** `test_no_find_piped_into_grep_q` in `foundations.test.sh`, scoped to
      the measured-100 % shape.
      [Story: FR-T5PFS-004]
- [x] **T3.2** Mutation-probe it: reintroduce the shape, confirm RED.
      [Story: FR-T5PFS-004]

## T4 — what was left

- [x] **T4.1** Enumerate the 176 unconverted sites with file:line and reason
      (`skipped.json`, summarised in `evidence.md` P-6).
      [Story: FR-T5PFS-003]

## T5 — regression

- [x] **T5.1** Full 80-entry CI matrix sweep, twice, in the **committed** state —
      `_test_b811_013` is a working-tree guard and fires on any uncommitted linter
      edit, which cost one false alarm before it was understood.
      [Story: FR-T5PFS-005, NFR-T5PFS-001]
- [x] **T5.2** `shellcheck --severity=warning` over `.forge/scripts` and `bin`.
      [Story: NFR-T5PFS-001]
- [x] **T5.3** `verify.sh` + `constitution-linter.sh` after the status flip.
      [Story: NFR-T5PFS-001]
