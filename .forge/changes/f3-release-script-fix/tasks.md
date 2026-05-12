# Tasks: f3-release-script-fix
<!-- Status: archived -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail
  (RED), write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-F3-XXX]` (Article V.1, enforced
  by `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- ADRs from `design.md` (ADR-F3-001..004) are honored verbatim ;
  deviations require a new ADR.

---

## Phase 1 — RED harness + CI registration

Goal : `f3.test.sh` exists with **10 L1 + 1 L2 stubs** ; L1
stubs FAIL (full RED witness for the 10 L1 anchors) ; L2 returns
0 (skip-pass by default per ADR-F3-004 gating pattern) ; CI
registration done.

### T-HAR — Harness skeleton

- [x] **T-HAR-001** — Create `.forge/scripts/tests/f3.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`), source `_helpers.sh`, PASS/FAIL
      counters reset, `--level` parsing for `1|2|1,2|all`,
      audit comment `# Audit: F.3 (f3-release-script-fix)`,
      `print_summary` close-out. Mirror the I.5 / I.6 layout.
      [Story: FR-F3-080 / FR-F3-081 / FR-F3-084]
- [x] **T-HAR-002** — Define the path variables at the top of
      the harness :
      - `RELEASE_SCRIPT` → `scripts/release.sh`
      - `OLD_RELEASE_SCRIPT` → `scripts/release-v0.3.0.sh`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      - `GOVERNANCE_MD` → `GOVERNANCE.md`
      [Story: FR-F3-080]
- [x] **T-HAR-003** — Add **10 L1 test stubs** all returning
      `_not_implemented` covering the 10 anchor IDs in
      `design.md` § "L1 unit-level" table.
      [Story: FR-F3-082]
- [x] **T-HAR-004** [P] — Add **1 L2 test stub**
      (`_test_f3_l2_dry_run_otp_forward`) that returns 0 by
      default (skip-pass per ADR-F3-004 gate pattern) but
      actually emits the gated `[INFO: ...]` lines per
      FR-F3-083.
      [Story: FR-F3-083]
- [x] **T-HAR-005** — Add the test runner — iterate through the
      10 L1 functions, call `run_test`, gate L2 on `--level`
      containing `2` or `all`, call `print_summary`. Exit 0 if
      `FAIL == 0`, else 1. [Story: FR-F3-085]
- [x] **T-HAR-006** [P] — Register `f3.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `i5.test.sh` with `--level 1`. Keep
      the file under 300 lines (NFR-CI-002 / NFR-F3-006).
      [Story: FR-F3-090]
- [x] **T-HAR-007** — RED gate — confirm
      `bash .forge/scripts/tests/f3.test.sh --level 1` exits 1
      with `Failed: 10 / Passed: 0`. [Story: FR-F3-085]

### Phase 1 exit gate

`f3.test.sh --level 1` exits 1 with FAIL = 10. `forge-ci.yml`
matrix updated, still under 300 lines. `verify.sh` overall PASS
unchanged. `constitution-linter.sh` OVERALL PASS unchanged.

---

## Phase 2 — Script rename + refactor (production code)

Goal : the new `scripts/release.sh` ships with the fixes ; the
old `scripts/release-v0.3.0.sh` is removed. After this phase,
9 of 10 L1 tests flip GREEN (the 10th — CHANGELOG entry — waits
for Phase 3).

### T-SCR — Script rename + refactor

- [x] **T-SCR-001** — RED witness — confirm the 9 script-related
      L1 tests still FAIL.
      [Story: FR-F3-001..064]
- [x] **T-SCR-002** — `git mv scripts/release-v0.3.0.sh
      scripts/release.sh` (preserves blame).
      [Story: FR-F3-001 / FR-F3-004]
- [x] **T-SCR-003** — Update the audit comment to
      `# <!-- Audit: F.3 (f3-release-script-fix) -->` within
      the first 10 lines of `scripts/release.sh`.
      [Story: FR-F3-002]
- [x] **T-SCR-004** — Update the header comment block (lines
      2-22) to describe :
      - Purpose : generic release helper for any v0.3.x version
        (and future versions following the same workflow).
      - Standard invocation form
        `bash scripts/release.sh --version X.Y.Z [--otp 123456]
        [--dry-run] [--skip-npm] [--skip-gh]`.
      - Flag list with semantics.
      - OTP fallback chain : `--otp` → TTY prompt → `NPM_OTP`.
      - Exit codes 0 / 1 / 2 / 3.
      [Story: FR-F3-006]
- [x] **T-SCR-005** — Refactor the argument-parsing `while`
      loop to add `--version` (required, regex
      `^[0-9]+\.[0-9]+\.[0-9]+$`) + `--otp` (regex
      `^[0-9]{6}$`). Support both space-separated and `=`-form
      variants.
      [Story: FR-F3-020..023 / FR-F3-040 / FR-F3-041]
- [x] **T-SCR-006** — Derive `TAG="v$VERSION"` +
      `EXPECTED_VERSION="$VERSION"` from the validated
      `--version`.
      [Story: FR-F3-023]
- [x] **T-SCR-007** — Remove the date pin from the CHANGELOG
      sanity check (original line 112) ; replace with version-
      only match `^## \[$EXPECTED_VERSION\]`.
      [Story: FR-F3-026]
- [x] **T-SCR-008** — Refactor the `run()` helper :
      - Wrap `eval "$@"` in a subshell `( eval "$@" )`.
      - Add OTP redaction in the dry-run trace.
      [Story: FR-F3-060 / FR-F3-045]
- [x] **T-SCR-009** — Add an OTP-resolution block immediately
      before the publish step (after `npm whoami` check). The
      block implements the flag → TTY → `NPM_OTP` chain per
      ADR-F3-004. Exit 2 with a clear message if all three are
      absent AND `--skip-npm` is absent AND `--dry-run` is
      absent.
      [Story: FR-F3-040..047]
- [x] **T-SCR-010** — Rewrite the publish block (original line
      144-168) :
      - The `npm install` / `bundle` / `test` steps stay
        inside `run()` (which now wraps them in a subshell
        per T-SCR-008).
      - The `npm publish` step becomes :
        ```bash
        if [ "$DRY_RUN" = "1" ]; then
          echo "    [dry-run] cd cli && npm publish --access public --otp=<redacted>"
        else
          ( cd cli && npm publish --access public --otp="$OTP" )
        fi
        ```
      [Story: FR-F3-044 / FR-F3-061]
- [x] **T-SCR-011** — Audit pass : grep the new script for any
      remaining bare `eval cd` or top-level `cd` other than the
      anchor `cd "$REPO_ROOT"` (line ~47). Remove / wrap any
      stragglers in `(...)` parens.
      [Story: FR-F3-062 / FR-F3-063]
- [x] **T-SCR-012** — Help text : update the `--help` /
      `-h` handler (original line 38-41) to print the new
      header (lines 2-22) verbatim. The `sed -n '2,18p'`
      range may need to widen to cover the longer header.
      [Story: FR-F3-006]
- [x] **T-SCR-013** — Run
      `bash .forge/scripts/tests/f3.test.sh --level 1` ;
      expect 9 of 10 L1 tests flip GREEN (the CHANGELOG-entry
      test stays RED until Phase 3).
      [Story: FR-F3-001..064]
- [x] **T-SCR-014** [P] — If `shellcheck` is available on the
      maintainer's machine, run `shellcheck scripts/release.sh`
      and resolve any warnings (or document explicit
      `# shellcheck disable=…` with rationale). If unavailable
      locally, defer to CI (the `forge-ci.yml::lint` job runs
      shellcheck at `severity: warning` on `./.forge/scripts`
      and `./bin` — note that `scripts/` is NOT scanned by
      that job ; see ADDENDUM in Phase 4 notes).
      [Story: NFR-F3-005]

### Phase 2 exit gate

9 of 10 L1 tests GREEN. `scripts/release-v0.3.0.sh` removed.
`scripts/release.sh` shellcheck-clean (or documented).
`verify.sh` overall PASS unchanged. `constitution-linter.sh`
OVERALL PASS unchanged.

---

## Phase 3 — Doc + governance + CHANGELOG + roadmap

### T-DOC — GOVERNANCE.md update

- [x] **T-DOC-001** — Edit `GOVERNANCE.md § Release Process`
      (lines 134-154) to :
      - Replace `scripts/release-v0.3.0.sh` references with
        `scripts/release.sh`.
      - Document `--version <X.Y.Z>` requirement.
      - Document `--otp <6-digits>` flag + the
        flag → TTY → `NPM_OTP` fallback chain.
      - Add a one-line note that this maintainer script is
        not currently shipped to adopters (`forge init`).
      [Story: FR-F3-110]

### T-LOG — CHANGELOG entry

- [x] **T-LOG-001** — Edit `CHANGELOG.md [Unreleased]` to add
      (immediately after the existing I.5 entry, before the
      T.5 OTel live-run entry) a
      `### Changed — scripts/release.sh (renamed + OTP support)
      (f3-release-script-fix)` block citing :
      - The rename from `scripts/release-v0.3.0.sh` →
        `scripts/release.sh`.
      - The subshell-isolation fix (bug 1).
      - The `--otp` flag + the OTP fallback chain (bug 2).
      - The four ADRs (ADR-F3-001..004) resolving the
        design questions.
      [Story: FR-F3-120]
- [x] **T-LOG-002** — GREEN witness — run
      `bash .forge/scripts/tests/f3.test.sh --level 1` ;
      expect the CHANGELOG-entry test flips GREEN.
      [Story: FR-F3-120]

### T-INV — Roadmap + plan inventory delta

- [x] **T-INV-001** [P] — Update `.forge/product/roadmap.md` :
      - Line 192 F.3 row : `⏸️ Pending` → `**Done 2026-05-12**
        via f3-release-script-fix` + brief delivery
        description.
      - Line 173 T8 row : remove the trailing `, F.3` from the
        module list ; add an inline note acknowledging the
        early F.3 delivery.
      - Line 470 (`### Modules toujours en attente`) : drop
        `F.3` from the trailing module list.
      - Inventaire table near line ~472 : new row for
        `f3-release-script-fix`.
      - v0.3.x deliveries table near line ~123 : new row for
        F.3.
      [Story: FR-F3-125 / FR-F3-127]
- [x] **T-INV-002** [P] — Update `docs/new-archetypes-plan.md` :
      - Line 470 reference to F.3 in "Modules toujours en
        attente".
      - Line 1120 T8 row module list + inline note.
      [Story: FR-F3-126]

### Phase 3 exit gate

10 of 10 L1 tests GREEN. L2 stays gated (skip-pass).
`verify.sh` overall PASS preserved. `constitution-linter.sh`
OVERALL PASS preserved. `forge-ci.yml` ≤ 300 lines.

---

## Phase 4 — Final gates + archive

### T-GAT — Final gates

- [x] **T-GAT-001** — `bash .forge/scripts/verify.sh` —
      overall PASS (additive ; no regression).
      [Story: NFR-F3-004]
- [x] **T-GAT-002** — `bash .forge/scripts/constitution-linter.sh`
      — OVERALL PASS (no `[NEEDS CLARIFICATION:]` inline ;
      no new Article touched). [Story: NFR-F3-004]
- [x] **T-GAT-003** — `bash .forge/scripts/tests/f3.test.sh
      --level 1` — 10/10 GREEN, exit 0.
      [Story: FR-F3-085]
- [x] **T-GAT-004** — `wc -l .github/workflows/forge-ci.yml`
      under 300 (NFR-CI-002 / NFR-F3-006).
- [x] **T-GAT-005** — Best-effort `shellcheck scripts/release.sh`
      if the tool is available. If unavailable locally, document
      in `.notes/blockers.md` and rely on CI.
      [Story: NFR-F3-005]
- [x] **T-GAT-006** — Status flip in `.forge.yaml` from
      `planned` / `implemented` to `archived`. Timeline
      populated with `proposed`, `specified`, `designed`,
      `planned`, `implemented`, `archived` dates all =
      2026-05-12.

### Phase 4 exit gate

All gates GREEN. Status `archived`. The change is ready for a
single archive commit.

### ADDENDUM — `forge-ci.yml::lint` job scope

The `lint` job in `.github/workflows/forge-ci.yml` (line 174-
188) scans only `./.forge/scripts` and `./bin` with
shellcheck. The new `scripts/release.sh` is therefore NOT
covered by CI shellcheck. NFR-F3-005 asks for shellcheck-
clean ; we honor it at authoring time (best-effort locally
+ careful coding) but accept that CI does not enforce it.
Extending CI scope to `scripts/` is out of scope for F.3.

---

## Task summary

| Phase | Tasks | Notes                                                                                              |
|-------|-------|----------------------------------------------------------------------------------------------------|
| 1     | 7     | RED foundation : harness skeleton + 10 L1 stubs + 1 L2 stub + CI registration. All FAIL.            |
| 2     | 14    | Script rename + refactor : 9 L1 tests flip GREEN.                                                   |
| 3     | 4     | GOVERNANCE + CHANGELOG + roadmap + plan : last L1 test GREEN.                                      |
| 4     | 6     | Final gates : verify / constitution-linter PASS ; status archived.                                   |
| **Total** | **31** | TDD discipline preserved ; immutable RED→GREEN→REFACTOR cycle ; 10 L1 GREEN tests at end.        |
