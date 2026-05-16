# Tasks: t5-cargo-pin-refresh
<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: T5.1.E (docs/new-archetypes-plan.md §0.1 extension — Option B) -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-T5CPR-XXX]` (Article V.1) on every task.
- `[P]` marks tasks parallelizable in the same phase.
- ADRs from `design.md` (ADR-T5CPR-001..003) honored verbatim.

The RED witness is already acquired in the wild : `task
smoke-with-toolchains` (cli-trust-harness FORGE_E2E_TOOLCHAINS=1)
fails as of 2026-05-16 with the exact error this change fixes. The
harness phase below reproduces this RED at the structural-test
level.

---

## Phase 1 — RED harness + CI registration

Goal : `t5-cargo.test.sh` exists with **10 L1 + 1 L2 stubs** ; L1
stubs FAIL ; L2 returns 0 (skip-pass by default) ; CI registration
done.

### T-HAR — Harness skeleton

- [ ] **T-HAR-001** — Create `.forge/scripts/tests/t5-cargo.test.sh`
      with bash header (`#!/usr/bin/env bash`, `set -uo pipefail`),
      source `_helpers.sh`, PASS/FAIL counters reset, `--level`
      parsing, audit comment `# Audit: T5.1.E (t5-cargo-pin-refresh)`,
      `print_summary` close-out.
      [Story: FR-T5CPR-070 / FR-T5CPR-071 / FR-T5CPR-072]
- [ ] **T-HAR-002** — Define path constants :
      - `TEMPLATE` → `.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/Cargo.toml.tmpl`
      - `MIRROR` → `cli/assets/.forge/templates/.../Cargo.toml.tmpl`
      - `STANDARD` → `.forge/standards/transport.yaml`
      - `REVIEW_MD` → `.forge/standards/REVIEW.md`
      - `SNAPSHOT` → `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      - `SNAPSHOT_MIRROR` → `cli/assets/.forge/scaffold-snapshots/.../1.0.0.tar.gz`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      - `CI_WORKFLOW` → `.github/workflows/forge-ci.yml`
      [Story: FR-T5CPR-070]
- [ ] **T-HAR-003** — Add 10 L1 stubs returning `_not_implemented`
      per the table in `design.md` § Harness L1 anchor list.
      [Story: FR-T5CPR-073]
- [ ] **T-HAR-004** [P] — Add 1 L2 stub
      `_test_t5c_l2_resolve_against_crates_io` returning 0 unless
      `FORGE_T5C_LIVE=1`. Body documents the three crates.io
      assertions per design.md § L2 fixture.
      [Story: FR-T5CPR-074]
- [ ] **T-HAR-005** — Test runner : iterate 10 L1 + 1 L2 (L2 gated
      on `--level`). `print_summary` close-out.
      [Story: FR-T5CPR-073 / FR-T5CPR-074]
- [ ] **T-HAR-006** [P] — Register `t5-cargo.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job immediately
      after `t5-1.test.sh`. Stay ≤ 300 lines (NFR-T5CPR-003).
      [Story: FR-T5CPR-075]
- [ ] **T-HAR-007** — RED gate — confirm
      `bash .forge/scripts/tests/t5-cargo.test.sh --level 1` exits
      1 with `Failed: 10 / Passed: 0`. [Story: FR-T5CPR-073]

### Phase 1 exit gate

`t5-cargo.test.sh --level 1` exits 1 (10 FAIL). `forge-ci.yml`
under 300 lines. Existing verify.sh + constitution-linter OVERALL
PASS unchanged.

---

## Phase 2 — Template pin correction

Goal : two pins fixed in source + bundled mirror. After this
phase, L1 anchors 1, 2, 3 GREEN.

### T-TPL — Cargo.toml.tmpl pins

- [ ] **T-TPL-001** — RED witness — L1 anchors 1, 2, 3 still FAIL.
      [Story: FR-T5CPR-001 / FR-T5CPR-002 / FR-T5CPR-005]
- [ ] **T-TPL-002** — Edit source template line 27 :
      ```diff
      -buffa        = "=0.3.3"
      +buffa        = "=0.3.0"
      ```
      [Story: FR-T5CPR-001]
- [ ] **T-TPL-003** — Edit source template line 28 :
      ```diff
      -buffa-types  = "=0.3.3"
      +buffa-types  = "=0.3.0"
      ```
      [Story: FR-T5CPR-002]
- [ ] **T-TPL-004** [P] — Apply the same two edits to the bundled
      mirror at `cli/assets/.forge/templates/.../Cargo.toml.tmpl`.
      Verify `diff -q` between source + mirror returns 0.
      [Story: FR-T5CPR-005]
- [ ] **T-TPL-005** — Live smoke : run
      `FORGE_E2E_TOOLCHAINS=1 task smoke-with-toolchains` and
      confirm `full-stack-monorepo` `cargo check --workspace` exits
      0. (Skip-pass if `cargo` absent — but the maintainer should
      have it on PATH at archive time.)
      [Story: FR-T5CPR-001..005 (live verification)]
- [ ] **T-TPL-006** — GREEN gate — L1 anchors 1, 2, 3 flip GREEN.
      Harness reports `Failed: 7 / Passed: 3`.

### Phase 2 exit gate

`grep buffa $TEMPLATE` shows `=0.3.0`. `task smoke-with-toolchains`
GREEN on cargo check leg. Pre-existing T5.1 harness still GREEN.

---

## Phase 3 — Standard bump + REVIEW.md entry

Goal : `transport.yaml` bumped, pins corrected, WAIVER comment
rewritten, REVIEW.md ledger updated. After this phase, L1 anchors
4, 5, 6, 7 GREEN.

### T-STD — `transport.yaml` v1.2.0

- [ ] **T-STD-001** — RED witness — L1 anchors 4, 5, 6, 7 still
      FAIL. [Story: FR-T5CPR-020..024]
- [ ] **T-STD-002** — Bump line 15 :
      ```diff
      -version: "1.1.0"
      +version: "1.2.0"
      ```
      [Story: FR-T5CPR-020 / MR-T5CPR-003]
- [ ] **T-STD-003** — Correct line 71 :
      ```diff
      -    buffa: "=0.3.3"              # WAIVER
      +    buffa: "=0.3.0"              # see Amend 2026-05-16 below
      ```
      [Story: FR-T5CPR-021 / MR-T5CPR-001]
- [ ] **T-STD-004** — Correct line 72 :
      ```diff
      -    buffa-types: "=0.3.3"        # WAIVER
      +    buffa-types: "=0.3.0"        # see Amend 2026-05-16 below
      ```
      [Story: FR-T5CPR-022 / MR-T5CPR-002]
- [ ] **T-STD-005** — Replace the WAIVER comment block (lines 55-63)
      with the rewritten version per ADR-T5CPR-003 / design.md.
      Must separate WAIVER (connectrpc / connectrpc-build at
      =0.3.3, pedigree-justified) from CORRECTION (buffa /
      buffa-types at =0.3.0, error-of-fact fix). Include audit
      date 2026-05-16 + change ID.
      [Story: FR-T5CPR-023 / MR-T5CPR-004 / ADR-T5CPR-003]
- [ ] **T-STD-006** [P] — Verify standards YAML validator GREEN :
      `bash bin/validate-standards-yaml.sh` exits 0 ; transport.yaml
      schema check passes.
      [Story: NFR-T5CPR-005]
- [ ] **T-STD-007** [P] — Append entry to `.forge/standards/REVIEW.md`
      per FR-T5CPR-024 exact format (Updated row).
      [Story: FR-T5CPR-024]
- [ ] **T-STD-008** — GREEN gate — L1 anchors 4, 5, 6, 7 flip GREEN.
      Harness reports `Failed: 3 / Passed: 7`.

### Phase 3 exit gate

`transport.yaml` v1.2.0, two pins at `=0.3.0`, WAIVER block
rewritten per ADR-T5CPR-003. REVIEW.md ledger has the Updated
entry. `bin/validate-standards-yaml.sh` GREEN.

---

## Phase 4 — Snapshot regeneration

Goal : both snapshot tarballs contain the corrected template.
After this phase, L1 anchors 8, 9 GREEN.

### T-SNP — Snapshot tarballs

- [ ] **T-SNP-001** — RED witness — L1 anchors 8, 9 still FAIL
      (snapshots still embed `=0.3.3`).
      [Story: FR-T5CPR-050..053]
- [ ] **T-SNP-002** — Investigate snapshot helper :
      `find bin/ .forge/scripts/ -name "*snapshot*"` to locate
      the existing helper if any (b1-scaffolder or a7-forge-upgrade
      may have shipped one). Document its invocation form.
      If no helper exists, fall back to the plain `tar -czf`
      recipe in `design.md` § Snapshot regeneration.
      [Story: FR-T5CPR-050]
- [ ] **T-SNP-003** — Regenerate
      `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      from the post-fix template tree (Phase 2 output). Whichever
      mechanism is used must produce a tarball whose extracted
      `grpc-api/Cargo.toml.tmpl` contains `=0.3.0` for both buffa
      pins (verified by extracting and grepping).
      [Story: FR-T5CPR-050 / FR-T5CPR-052]
- [ ] **T-SNP-004** [P] — Refresh the bundled mirror via
      `cd cli && npm run bundle`. Verify
      `diff -q .forge/scaffold-snapshots/.../1.0.0.tar.gz
              cli/assets/.forge/scaffold-snapshots/.../1.0.0.tar.gz`
      returns 0 (byte-identical).
      [Story: FR-T5CPR-051 / FR-T5CPR-053]
- [ ] **T-SNP-005** — Verify A.7 `forge upgrade` BASE-recovery
      backward compat : run `bash .forge/scripts/tests/a7.test.sh
      --level 1,2`. Expected 29/29 GREEN preserved. If the snapshot
      shape change breaks any test, investigate before proceeding.
      [Story: NFR-T5CPR-005]
- [ ] **T-SNP-006** — GREEN gate — L1 anchors 8, 9 flip GREEN.
      Harness reports `Failed: 1 / Passed: 9`.

### Phase 4 exit gate

Both snapshot tarballs extracted → embedded Cargo.toml.tmpl shows
`=0.3.0`. Source + mirror byte-identical. A.7 harness 29/29 GREEN.

---

## Phase 5 — Documentation + audit-trail flips + final gates

Goal : CHANGELOG, roadmap, plan flips. All 10 L1 GREEN.

### T-DOC — Documentation

- [ ] **T-DOC-001** — RED witness — L1 anchor 10 still FAIL.
      [Story: FR-T5CPR-100]
- [ ] **T-DOC-002** — Add a `### Fixed — Cargo pin refresh
      (T5.1.E, t5-cargo-pin-refresh)` block to `CHANGELOG.md`
      `[Unreleased]` per FR-T5CPR-100. Cite :
      - The two pin corrections (`=0.3.3` → `=0.3.0`)
      - Standard bump v1.1.0 → v1.2.0
      - Snapshot tarball regeneration
      - WAIVER comment block rewrite (ADR-T5CPR-003 reference)
      - RED witness was `task validate` 2026-05-16
      [Story: FR-T5CPR-100]
- [ ] **T-DOC-003** [P] — Flip `docs/new-archetypes-plan.md` §0.1
      extension : T5.1.E "*(nouveau change)*" → "**Done 2026-05-XX**
      via `t5-cargo-pin-refresh`". Same flips in §1.4 + §11.
      [Story: FR-T5CPR-102]
- [ ] **T-DOC-004** [P] — Append inventory row to plan §0.0 :
      ```
      | `t5-cargo-pin-refresh`       | archived               | T5.1.E (cargo pin correction)                  |
      ```
      Bump archived count 25 → 26.
      [Story: FR-T5CPR-101]
- [ ] **T-DOC-005** [P] — Roadmap T5.1 row : flip `**Partial**` →
      `**Done**` once both `cli-trust-harness` AND
      `t5-cargo-pin-refresh` are archived. Update the row body
      accordingly. Add an inventory mention if the roadmap carries
      one (it does not at present).
      [Story: FR-T5CPR-103]
- [ ] **T-DOC-006** — GREEN gate — L1 anchor 10 flips GREEN. All
      10 L1 GREEN. Harness reports `Failed: 0 / Passed: 10`.

### T-VER — Verification + final gates

- [ ] **T-VER-001** — Run
      `bash .forge/scripts/tests/t5-cargo.test.sh --level 1` and
      confirm `Failed: 0 / Passed: 10`.
      [Story: FR-T5CPR-073]
- [ ] **T-VER-002** — Run
      `FORGE_T5C_LIVE=1 bash .forge/scripts/tests/t5-cargo.test.sh
      --level 2`. Expect L2 fixture GREEN against live crates.io.
      [Story: FR-T5CPR-074]
- [ ] **T-VER-003** [P] — Run `bash .forge/scripts/verify.sh`.
      Expected RESULT: PASS preserved.
      [Story: NFR-T5CPR-005]
- [ ] **T-VER-004** [P] — Run `bash .forge/scripts/constitution-linter.sh`.
      Expected OVERALL: PASS preserved.
      [Story: NFR-T5CPR-005]
- [ ] **T-VER-005** [P] — Run
      `bash bin/validate-standards-yaml.sh`. Expected STD-PASS.
      [Story: J.7]
- [ ] **T-VER-006** [P] — Run
      `bash .forge/scripts/validate-change-yaml.sh
      .forge/changes/t5-cargo-pin-refresh/.forge.yaml`. Expected
      exit 0.
      [Story: F.2]
- [ ] **T-VER-007** — Inline `[NEEDS CLARIFICATION:]` gate :
      `grep -n '\[NEEDS CLARIFICATION:' .forge/changes/t5-cargo-pin-refresh/*.md`
      must return zero matches (Article III.4).
      [Story: Article III.4]
- [ ] **T-VER-008** [P] — Final smoke : `task validate` end-to-end
      must pass (build + gates + harness + vitest +
      smoke-with-toolchains). Confirmation that the originating
      RED is closed.
      [Story: T5.1.E end-to-end]
- [ ] **T-VER-009** — Update `.forge.yaml` timeline :
      `specified: 2026-05-16`, `designed: 2026-05-16`,
      `planned: 2026-05-16`, `implemented: 2026-05-XX`.
      [Story: F.2]

### Phase 5 exit gate

- All 10 L1 GREEN.
- `verify.sh` OVERALL PASS preserved (+1 PASS for new harness
  registration, +1 PASS for transport.yaml validate).
- `constitution-linter.sh` OVERALL PASS preserved.
- `validate-standards-yaml.sh` STD-PASS preserved.
- No `[NEEDS CLARIFICATION:]` markers.
- `task validate` end-to-end GREEN.

---

## Sequencing summary

```
Phase 1 (RED + CI)            → 10 L1 stubs FAIL ; 1 L2 skip-pass ; CI registered
Phase 2 (template fix)        → L1 anchors 1, 2, 3 GREEN ; 7 still FAIL
Phase 3 (standard bump)       → L1 anchors 4, 5, 6, 7 GREEN ; 3 still FAIL
Phase 4 (snapshot regen)      → L1 anchors 8, 9 GREEN ; 1 still FAIL
Phase 5 (docs + final gates)  → L1 anchor 10 GREEN ; ALL 10 L1 GREEN
```

---

## Post-archive release wiring

After this change is archived AND `cli-trust-harness` is archived :

1. Bump VERSION 0.3.2 → 0.3.3.
2. Bump `cli/package.json::version` 0.3.2 → 0.3.3.
3. Seal CHANGELOG `## [Unreleased]` → `## [0.3.3] — 2026-05-XX`.
4. Open PR optim → main (or main direct, given T5.1 is additive
   per `no_pr_before_t2_p1_p2.md`).
5. Once merged, run
   `bash scripts/release.sh --version 0.3.3 --otp <6-digits>`.
   The `prepublishOnly` gate (T5.1.C) exercises the smoke on the
   actual tarball. Both Cargo pins should resolve cleanly during
   that gate.

If `prepublishOnly` aborts, do NOT use `FORGE_SKIP_PREPUBLISH=1`
(ADR-T51-005 reserved for emergencies, this is the first real
release). Investigate the failure ; fix-forward as a new change ;
re-run.
