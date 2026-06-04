# Tasks: b8-13-rollback-runbook

**Status**: planned → 2026-06-04 · Constitution 1.1.0
TDD order is mandatory: harness assertions (RED) precede the docs they verify.
Doc-only brick → the "test" is the L1 grep/diff/shasum harness; "production
code" is the documentation it asserts.

## Phase 1: Harness first (RED)

- [x] T-001 Write `.forge/scripts/tests/b8-13.test.sh` skeleton (set -uo pipefail,
      hermetic git-identity export per the b8-12 lesson, path vars, manifest,
      `--level` parse, source `_helpers.sh`, PASS/FAIL accounting). [Story: NFR-001]
- [x] T-002 Implement L1 assertions for Group 1–4 (runbook present/titled/audit
      comment 001; two scenarios 002; five steps 003; thresholds 010/020;
      detection-cites-B.8.12 011; Kong route-weights 012; OTel-overlay-only 021;
      `--rollback`+snapshot+`--phase` 030; no-DBOS-criterion 031; runbook↔script
      consistency 032). [Story: FR-B813-001..032]
- [x] T-003 Implement Group 5–8 assertions (arch-doc sha256==pinned 040;
      Supersession-note enumerates 7 refs 041; MIGRATIONS re-point 050;
      no-committed-latency 060; frozen-1.0.0 061; no standards/schema/constitution/
      t4-spec diff 062; forge-ci reg 066; CHANGELOG anchor 067; coupling guards
      b8-12+b8-10+t4 068). [Story: FR-B813-040..068]
- [x] T-004 **Verify RED**: run `bash .forge/scripts/tests/b8-13.test.sh --level 1`
      → MUST fail (docs/ROLLBACK.md absent, MIGRATIONS not re-pointed, CHANGELOG/CI
      not registered). Record the failing test list.

## Phase 2: Author docs (GREEN)

- [x] T-010 Author `docs/ROLLBACK.md`: title + audit comment; decision tree;
      Scenario A (Detect/Decide/Execute/Verify/Re-attempt, p99>20%, Kong route
      weights, B.8.12 methodology); Scenario B (traceparent>1%, OTel SDK overlay
      only); last-resort `--rollback` section; explicit no-DBOS/CPU note; criteria
      byte-consistent with `forge-migrate-flagship.sh:394-396`. [Story: FR-001..032]
- [x] T-011 Author the **Supersession note** in `docs/ROLLBACK.md` enumerating the
      seven obsolete-per-B8O arch-doc refs (§11 ×6 + §12.1) → orchestration.yaml
      v1.2.0 + B8O change. No absolute latency figure anywhere. [Story: FR-041/060]
- [x] T-012 Re-point `docs/MIGRATIONS.md:144` at `docs/ROLLBACK.md` (keep criteria
      summary; verify :172/:182 stay threshold-consistent). Do NOT touch
      `docs/ARCHITECTURE-TARGET.md`. [Story: FR-050/040]
- [x] T-013 Add `[Unreleased]` `b8-13` entry to `CHANGELOG.md` (whole-file anchor).
      [Story: FR-067]
- [x] T-014 Register `b8-13.test.sh --level 1` in `.github/workflows/forge-ci.yml`.
      [Story: FR-066]
- [x] T-015 **Verify GREEN**: run `bash .forge/scripts/tests/b8-13.test.sh
      --level 1` → all PASS. [Story: all]

## Phase 3: Integration + invariants

- [x] T-020 Run coupling guards (b8-12, b8-10, t4) — confirm each green by exit
      code; confirm `t4.test.sh::_test_t4_023` green (arch-doc untouched).
      [Story: FR-068/040]
- [x] T-021 Full hermetic suite (~52 harnesses incl. b8-13) ALL_GREEN +
      `verify.sh` + `constitution-linter.sh` OVERALL PASS (full-suite-before-push
      lesson). [Story: NFR-001/003]
- [x] T-022 Confirm frozen 1.0.0 byte-identity (b8-2 sha256) + no
      standards/schema/constitution/t4-spec diff in `git diff --stat`.
      [Story: FR-061/062]

## Phase 4: Quality gate + archive

- [x] T-030 Independent code-review pass (separate context) on the implemented
      docs + harness — re-verify no fabricated latency, no arch-doc edit, the
      seven-ref enumeration, runbook↔script consistency. APPROVE required.
- [x] T-031 Neutralize any spec markers; flip `.forge.yaml` status → implemented
      (timeline.implemented).
- [x] T-032 Archive: merge ADDED reqs into `.forge/specs/` (new
      `rollback-runbook.md` spec), status → archived, update plan §0.0 inventory +
      §4.2 Done marker + "Next B.8 step", roadmap T6 sentence.
- [x] T-033 Commit `feat(b8-13)` + `chore(release)` prep (CHANGELOG seal at
      maintainer discretion — rc.15).

## Constitutional compliance (per-task gate)
- No task edits `docs/ARCHITECTURE-TARGET.md` (T-012 explicit) → t4 pin safe.
- No task mutates constitution/standard/schema/snapshot/t4-spec (T-022 asserts).
- TDD order enforced: T-004 RED before T-010 GREEN.
- No committed latency figure (T-011 + FR-060 harness).
