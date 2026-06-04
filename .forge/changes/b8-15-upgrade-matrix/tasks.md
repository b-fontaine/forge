# Tasks: b8-15-upgrade-matrix

**Status**: planned → 2026-06-04 · Constitution 1.1.0
T5.1 Layer D upgrade-matrix harness. TDD RED→GREEN, hermetic L1 + opt-in L2.
Direct new cells (cross-major negative, --force-dirty, flagship-on-c1) +
a7-coupling for the same-major/ledger/.merge-conflicts machinery.

## Phase 1: Harness first (RED)
- [x] T-001 `.forge/scripts/tests/b8-15.test.sh` skeleton (set -uo pipefail, hermetic
      GIT_AUTHOR_*/COMMITTER_* export, path vars incl C1_EXAMPLE + UPGRADE_SH +
      MIGRATE_SH + FIXTURE, manifest, `--level`, `_helpers.sh`, counters). [Story: NFR-001]
- [x] T-002 Direct L1 cells: negative exit-7 `[NEEDS MIGRATION:]` (synth 1.5.2
      manifest tmpdir); `--force` dirty-git refused (same-major target → assert
      dirty-git stderr, exit 7); static additive no-`rm` guard on migrate-flagship.sh;
      flagship `--dry-run` on a c1 copy (targets 1.0.0→2.0.0, c1 unmutated);
      flip-gated skip-pass guard. [Story: FR-010/011/041/040/050]
- [x] T-003 Coupling + CI cells: re-run a7 + b8-10 + b8-14 by exit code (FR-020/021/
      030-generic/031/062); CHANGELOG anchor (061); forge-ci reg (060); frozen 1.0.0
      snapshot sha (063). [Story: FR-020..063]
- [x] T-004 L2 (FORGE_B8_15_LIVE) cell: real migrate-flagship overlay on a c1 copy →
      assert upgrade_history flagship entry (from=1.0.0/to=2.0.0 + `kind`), Kong-present
      tree (`fsm-kong` + kong.yml REST routes), T5.1.B fixture matrix (required/forbidden
      paths) on the overlaid tree; skip-pass if c1/fixture absent. [Story: FR-040/041/042]
- [x] T-005 **Verify RED**: `b8-15.test.sh --level 1` fails before cells wired; record.

## Phase 2: Wire to GREEN (iterate empirically on forge-upgrade behavior)
- [x] T-010 Implement the negative exit-7 cell; run → confirm exit 7 + exact marker.
- [x] T-011 Implement --force-dirty cell; iterate target version so exit-7 is the
      force-clean gate (not version-compat); assert dirty-git stderr.
- [x] T-012 Implement static additive guard + flagship dry-run on c1 + flip-gated guard.
- [x] T-013 Wire coupling (a7/b8-10/b8-14) + CHANGELOG + forge-ci + frozen-sha.
- [x] T-014 **Verify GREEN L1**: all L1 cells pass. Optionally run L2 locally
      (FORGE_B8_15_LIVE=1) to confirm the flagship overlay cell.

## Phase 3: Integration
- [x] T-020 Coupling green (a7,b8-10,b8-14); full suite (~53 incl b8-15) + verify.sh +
      constitution-linter OVERALL PASS.
- [x] T-021 Held-state: `git status` shows no standard/schema/constitution/scaffolder/
      template/frozen mutation (only forge-ci + CHANGELOG + new change-dir/harness). [Story: FR-063]

## Phase 4: Quality gate + archive
- [x] T-030 Independent implementation review (re-execute harness incl L2; verify c1
      base, additive guard, flip-gated skip-pass, no fabrication). APPROVE.
- [x] T-031 Flip → implemented; post-flip gate.
- [x] T-032 Archive: spec → .forge/specs/upgrade-matrix.md; status archived; plan §0.0 +
      §4.2 (B.8.15 done) + Next step; roadmap T6 (B.8 buildable bricks complete).
- [x] T-033 Commit feat(b8-15) + push.

## Constitutional compliance
- No standard/schema/constitution/scaffolder/template/frozen mutation (T-021).
- TDD: T-005 RED before T-010 GREEN.
- Anti-fabrication: positive 2.0.0 front-door is flip-gated skip-pass, NOT asserted passing.
