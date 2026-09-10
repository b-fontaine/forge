# Tasks — `b9-8-snapshot`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — the snapshot the plan asks for

- [x] **T1.1** `forge-snapshot.sh build mobile-pwa-first 2.0.0` — 553 files,
      1 138 222 bytes, zero AppleDouble (Linux + Python tarfile path).
      [Story: FR-B98-001]
- [x] **T1.2** Write `2.0.0.sha256`; verify with `sha256sum -c`.
      [Story: FR-B98-002]

## T2 — the freeze ADR-B8-2-004 assigned to B.9

- [x] **T2.1** Establish that a rebuild is inadmissible: extract the archive and
      compare its 219 real files to today's tree. **50 differ** — era state.
      [Story: FR-B98-003, NFR-B98-002]
- [x] **T2.2** Repack member-by-member: drop the 299 `._*` members and the Apple pax
      headers, preserve original metadata on everything else.
      [Story: FR-B98-003]
- [x] **T2.3** Prove it: 219/219 real files present, 0 content changed, no pax
      header, no AppleDouble. Run twice → byte-identical.
      [Story: FR-B98-003, NFR-B98-003]
- [x] **T2.4** Install the repacked archive; write `1.0.0.sha256`; verify.
      [Story: FR-B98-002]

## T3 — guards

- [x] **T3.1** `b4.test.sh::_test_b4_snapshot_frozen_and_clean` — manifest present,
      sha matches, no AppleDouble.
      [Story: FR-B98-004]
- [x] **T3.2** `b9-2.test.sh::T-023` — 2.0.0 snapshot present, manifest matches,
      no AppleDouble.
      [Story: FR-B98-001, FR-B98-004]
- [x] **T3.3** Hosted in already-registered harnesses: `forge-ci.yml` is at 419/420
      and a new harness would consume the last line.
      [Story: FR-B98-004]
- [x] **T3.4** Mutation-probe all three assertions. The manifest-mismatch probe
      needed two attempts — the first `sed` was a no-op on a hash already starting
      with the substituted character, which left the guard green and looked like the
      guard failing.
      [Story: FR-B98-004]

## T4 — records

- [x] **T4.1** `upgrade-policy.md`: frozen-versions table, what a snapshot actually
      contains, and the one permitted pre-freeze repack with its rationale.
      Closes ADR-B8-2-004's forward pointer.
      [Story: FR-B98-005]
- [x] **T4.2** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-B98-006]
- [x] **T4.3** Plan §0.14 / §5.2 / §11 and roadmap: B.9 4/11 → 5/11.
      [Story: FR-B98-006]

## T5 — regression

- [x] **T5.1** `a7` (owns upgrade-policy.md sections), `b4`, `b9-2`, `b8-2`
      (flagship freeze must not drift), `b8-15` — all GREEN.
      [Story: NFR-B98-001]
- [x] **T5.2** Full 80-entry CI matrix sweep, run under `bash` with proper word
      splitting.
      [Story: NFR-B98-001]
- [x] **T5.3** `verify.sh` + `constitution-linter.sh` **after** the status flip.
      [Story: NFR-B98-001]

## Negative scope guard

- [x] **T6.1** `full-stack-monorepo/1.0.0.tar.gz` and its `.sha256` byte-unchanged;
      no archetype template touched.
      [Story: NFR-B98-001]
