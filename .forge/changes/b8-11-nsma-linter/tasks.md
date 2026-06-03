<!-- Audit: B.8.11 (b8-11-nsma-linter) -->
# Tasks: b8-11-nsma-linter

TDD-ordered. Pure governance/data flip: `state-management.yaml` `ci_blocking:
false → true` + version `1.0.0 → 1.1.0` + `activated_by` audit field +
`linting-rules.md` NSMA section + `FORGE_LINTER_SKIP_NSMA` opt-out row +
harness `b8-11.test.sh` (~14 L1 + 2 L2) + forge-ci.yml + CHANGELOG. No new
bash in `constitution-linter.sh` (FR-B811-043). ADR-B811-001..004 encoded.
Q-001 ratified (a) by independent reviewer 2026-06-03. Three reviewer LOWs
folded: LOW-1 (evidence P-21 reword, T-003), LOW-2 (design/evidence precedent
citation fix to transport.yaml, T-004/T-005), LOW-3 (FR-B811-057 backward-compat
assertion gets its own harness test id T-015, separate from T-012 no-new-bash
guard). Sibling scan: `t4.test.sh` L2 fixture `_test_t4_l2_lint_warn_riverpod`
uses a broad grep that matches both WARN and FAIL text — survives the flip
without change. Full ~50-harness suite GREEN before push (NFR-B811-002).
POST-flip gates re-run (b8-coroot lesson). Independent review required before
`/forge:archive` (NFR-B811-007, t5-2 lesson).

---

## Phase 0 — Verify-then-pin LIVE + carry-fixes (Article III.4 + b8-coroot lesson)

Re-read each artefact live before any file is edited. Falsification surfaces as
`[NEEDS CLARIFICATION: <detail>]` + STOP. Append every result to `evidence.md`
with file:line provenance (source-document-pinning.md). Then apply the three
reviewer LOW carry-fixes (LOW-1, LOW-2) to `evidence.md` and `design.md`.

- [x] **T-001** Re-read `constitution-linter.sh:665-731` live. Confirm:
  (a) The FAIL/WARN branch at L715-719 is still keyed entirely on
  `nsma_blocking` (set at L683 from `grep -qE '^[[:space:]]+ci_blocking:
  [[:space:]]+true'`). No refactor has altered this branch.
  (b) `FORGE_LINTER_FIXTURE_ROOT` override at L681
  (`nsma_search_root="${FORGE_LINTER_FIXTURE_ROOT:-$FORGE_ROOT}"`) is still
  present — this is the L2 harness injection point (FR-B811-054).
  (c) The I.3 interlock boundary: `ADR-I3-001: T3-Forbidden Components` header
  at L732 immediately follows the NSMA block. `EXCLUDE_STANDARDS` or its
  equivalent still excludes `state-management.yaml` from the T3-Forbidden walk.
  (d) `FORGE_LINTER_SKIP_NSMA` opt-out at L674 is still present.
  Record exact line numbers + quoted text as evidence (P-01..P-06 recheck).
  If any of these have changed, emit `[NEEDS CLARIFICATION: constitution-linter.sh
  NSMA block refactored — ADR-B811-001..004 require re-evaluation]` and STOP.
  [Story: FR-B811-001, FR-B811-043, FR-B811-042, FR-B811-054, Article III.4]

- [x] **T-002** Re-read `state-management.yaml` live. Confirm:
  (a) `version: "1.0.0"` (L6) — the pre-flip state.
  (b) `enforcement.ci_blocking: false` (L12) — the flag to flip.
  (c) `enforcement.activation_planned: "B.8 (T6)"` (L14) — to be replaced.
  (d) `expires_at: never` + `exception_constitutional: true` pair (L8-L9) —
  structural-exception pair that MUST survive the bump byte-unchanged (FR-B811-004).
  (e) `forbidden:` list still contains exactly 8 packages (FR-B811-003).
  Re-read `REVIEW.md` — confirm no concurrent b8-11 entry has been added (P-23
  recheck). Re-read `forge-ci.yml` — confirm `b8-10.test.sh --level 1` at L115
  is still the insertion point for `b8-11.test.sh`.
  Record all as evidence (P-07/P-22/P-23 recheck).
  If any field has changed from the designed state, emit
  `[NEEDS CLARIFICATION: state-management.yaml pre-flip state differs from P-07
  — ADR-B811-003/004 require re-evaluation]` and STOP.
  [Story: FR-B811-001, FR-B811-002, FR-B811-003, FR-B811-004, FR-B811-010,
   Article III.4]

- [x] **T-003** Re-read `global/linting-rules.md:160-190` (opt-out matrix +
  §"Adding a new rule"). Confirm:
  (a) The opt-out matrix at L160-166 does NOT yet contain `FORGE_LINTER_SKIP_NSMA`
  (FR-B811-021 pre-condition).
  (b) The §"Adding a new rule" tightening clause (L173-190) matches P-13.
  Re-read `I.3 EXCLUDE_STANDARDS` in `constitution-linter.sh` — confirm
  `state-management.yaml` is still listed in `EXCLUDE_STANDARDS` (NFR-B811-008).
  **LOW-1 carry-fix** (reviewer finding): `evidence.md` P-21 currently reads
  "zero pubspec.yaml" without qualification. Reword the P-21 row in `evidence.md`
  to: "zero SCANNABLE pubspec.yaml after `/.forge/` + `/examples/` exclusions
  (2 real pubspec.yaml files exist under `examples/`, excluded by the structural
  `grep -v \"/examples/\"` filter — they never reach the NSMA scan)." Update the
  Backward-Compat Finding prose in `evidence.md` accordingly.
  Record confirmation as evidence (P-13/P-14 recheck).
  [Story: FR-B811-020, FR-B811-021, FR-B811-042, NFR-B811-008, Article III.4,
   LOW-1]

- [x] **T-004** Re-read `.forge/standards/REVIEW.md:25-47` (b8-7 / transport.yaml
  row format). Confirm the H2 date-header + table format for `1.1.0` entries.
  **LOW-2 carry-fix** (reviewer finding): `design.md:139` and `evidence.md P-18`
  currently cite "b8-7 identity.yaml" as the version-bump precedent.
  The correct precedent is **`transport.yaml v1.1.0` (t5-connect-codegen,
  REVIEW.md:51-58)** — identity.yaml is still at v1.0.0.
  Fix `design.md` ADR-B811-003 "Findings" item 3: replace
  `"b8-7 identity.yaml used a 1.0.0 → 1.1.0 minor bump"` with
  `"b8-7 transport.yaml (t5-connect-codegen) used a 1.0.0 → 1.1.0 minor bump
  (REVIEW.md:51-58)"`.
  Fix `evidence.md` P-18: replace `"b8-7 identity row format"` with
  `"b8-7 transport.yaml 1.1.0 row format (t5-connect-codegen)"` and update the
  source citation to `".forge/standards/REVIEW.md:51-58"`.
  Record the confirmed live REVIEW.md row format as evidence (P-18 recheck).
  [Story: FR-B811-012, ADR-B811-003, LOW-2]

- [x] **T-005** Re-read `schema enforcement.additionalProperties: true` (P-19
  recheck at `.forge/schemas/standard.schema.json:38-47`). Confirm the schema
  still permits the `activated_by:` field alongside `ci_blocking` and
  `pre_commit_hook` (ADR-B811-004 grounds). Re-read `bin/validate-standards-yaml.sh`
  to confirm the J.7 FR-J7-023 version↔REVIEW coupling check — understand the
  exact assertion format so the REVIEW.md row and `state-management.yaml` version
  field pass validation.
  Confirm LOW-2 fix is complete: verify `design.md` ADR-B811-003 now cites
  transport.yaml, not identity.yaml.
  Record schema confirmation as evidence (P-19 recheck). If the schema has been
  changed to `additionalProperties: false` on `enforcement`, emit
  `[NEEDS CLARIFICATION: enforcement.additionalProperties changed — ADR-B811-004
  activated_by field may be schema-illegal]` and STOP.
  [Story: FR-B811-002, FR-B811-013, ADR-B811-004, NFR-B811-004, LOW-2]

---

## Phase 1 — Harness RED

Author `b8-11.test.sh` with all 14 L1 assertions + 2 L2 stubs before any
standard, governance doc, CHANGELOG, or CI file is edited. Run to confirm RED
baseline. T-012 (no-new-bash git diff) and T-015 (live-tree backward-compat)
may partially pass pre-flip — note expected baseline carefully.

- [x] **T-006** Author `.forge/scripts/tests/b8-11.test.sh`. The file MUST:
  (a) Open with the audit header (FR-B811-050):
      ```
      #!/usr/bin/env bash
      # Forge — B.8.11 NSMA linter activation test harness (b8-11-nsma-linter)
      # <!-- Audit: B.8.11 (b8-11-nsma-linter) -->
      ```
  (b) `set -uo pipefail` as first executable statement.
  (c) `--level` flag parse loop (mirror i3.test.sh:22-27); `HARNESS_DIR` +
      `FORGE_ROOT_REAL` resolution pattern (mirror i3.test.sh:29-31).
  (d) Define path variables:
      `SM_YAML="$FORGE_ROOT_REAL/.forge/standards/state-management.yaml"`,
      `REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"`,
      `RULES_MD="$FORGE_ROOT_REAL/.forge/standards/global/linting-rules.md"`,
      `CHANGELOG="$FORGE_ROOT_REAL/CHANGELOG.md"`,
      `FORGE_CI="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"`,
      `LINTER_SH="$FORGE_ROOT_REAL/.forge/scripts/constitution-linter.sh"`.
  (e) `source "$HARNESS_DIR/_helpers.sh"`; `PASS=0; FAIL=0; FAIL_NAMES=()`.
  (f) Named test functions for all 14 L1 tests (see T-007).
  (g) Named stubs for 2 L2 tests (see T-008).
  (h) `main()` with `run_test` + `print_summary`; `case "$LEVEL" in 1) L1 only;;
      1,2|all) L1 + L2;; *) echo "unknown level" >&2; exit 2;; esac`.
  Make executable: `chmod +x .forge/scripts/tests/b8-11.test.sh`.
  [Story: FR-B811-050, FR-B811-051, FR-B811-052, FR-B811-053, FR-B811-054,
   Article I RED]

- [x] **T-007** Implement all 14 L1 test functions (hermetic grep/stat/exit-code,
  ≤ 2 s wall-clock total, NFR-B811-001):

  **T-001** `_test_b811_001_ci_blocking_true` — FR-B811-001:
  `grep -qE '^[[:space:]]+ci_blocking:[[:space:]]+true' "$SM_YAML"` → exit 0.
  Also assert `grep -qE 'ci_blocking:[[:space:]]+false' "$SM_YAML"` → exit 1
  (old value gone). FAIL if either assertion fails.

  **T-002** `_test_b811_002_version_1_1_0` — FR-B811-010:
  `grep -qF 'version: "1.1.0"' "$SM_YAML"` → exit 0;
  `grep -qF 'version: "1.0.0"' "$SM_YAML"` → exit 1. FAIL if either fails.

  **T-003** `_test_b811_003_activation_planned_gone` — FR-B811-002:
  `grep -q "activation_planned" "$SM_YAML"` → exit 1 (must be absent). FAIL if
  `activation_planned` is still present.

  **T-004** `_test_b811_004_activated_by_audit_trail` — FR-B811-002:
  `grep -qE "b8-11|B\.8\.11" "$SM_YAML"` → exit 0 (audit trail present). FAIL
  if no `b8-11` / `B.8.11` reference in the file.

  **T-005** `_test_b811_005_structural_exception_pair` — FR-B811-004:
  `grep -qF "expires_at: never" "$SM_YAML"` → exit 0;
  `grep -qE "^exception_constitutional:[[:space:]]+true" "$SM_YAML"` → exit 0.
  FAIL if either is absent.

  **T-006** `_test_b811_006_pre_commit_hook_false` — FR-B811-005:
  `grep -qF "pre_commit_hook: true" "$SM_YAML"` → exit 1 (must NOT be true).
  FAIL if `pre_commit_hook: true` is present.

  **T-007** `_test_b811_007_review_md_row` — FR-B811-012:
  `grep -qF "state-management.yaml" "$REVIEW_MD"` → exit 0;
  `grep -qF "1.1.0" "$REVIEW_MD"` → exit 0;
  `grep -qF "b8-11-nsma-linter" "$REVIEW_MD"` → exit 0.
  FAIL if any of the three greps fails.

  **T-008** `_test_b811_008_linting_rules_nsma_section` — FR-B811-020/022/023:
  `grep -qF "no-state-management-alternatives" "$RULES_MD"` → exit 0;
  `grep -qF "ADR-006" "$RULES_MD"` → exit 0;
  `grep -qE "VI\.3|Article VI" "$RULES_MD"` → exit 0.
  FAIL if any of the three greps fails.

  **T-009** `_test_b811_009_skip_nsma_opt_out_row` — FR-B811-021:
  `grep -qF "FORGE_LINTER_SKIP_NSMA" "$RULES_MD"` → exit 0. FAIL if absent.

  **T-010** `_test_b811_010_changelog_anchor` — FR-B811-056:
  `grep -qF "b8-11-nsma-linter" "$CHANGELOG"` → exit 0 (whole-file grep, not
  section-scoped — changelog-test [Unreleased] coupling lesson). FAIL if absent.

  **T-011** `_test_b811_011_forge_ci_registration` — FR-B811-055:
  `grep -qF "b8-11.test.sh" "$FORGE_CI"` → exit 0. FAIL if absent.

  **T-012** `_test_b811_012_no_new_bash_in_linter` — FR-B811-043/NFR-B811-003:
  ```bash
  local additions
  additions="$(git -C "$FORGE_ROOT_REAL" diff HEAD -- \
    .forge/scripts/constitution-linter.sh \
    | grep '^+' | grep -v '^+++' | grep -v '^+[[:space:]]*#' || true)"
  [ -z "$additions" ]
  ```
  FAIL if any non-comment additions are found in `constitution-linter.sh`.

  **T-013** `_test_b811_013_coupling_b8_3` — FR-B811-053/FR-B811-013:
  `bash "$HARNESS_DIR/b8-3.test.sh" --level 1 >/dev/null 2>&1` → exit 0.
  FAIL if `b8-3.test.sh --level 1` exits non-zero (schema invariants broken).

  **T-014** `_test_b811_014_coupling_i3` — FR-B811-053/FR-B811-042:
  `bash "$HARNESS_DIR/i3.test.sh" --level 1 >/dev/null 2>&1` → exit 0.
  FAIL if `i3.test.sh --level 1` exits non-zero (I.3 interlock broken).

  **T-015** `_test_b811_015_live_tree_backward_compat` — FR-B811-057 (LOW-3:
  dedicated test id, NOT overloaded onto T-012):
  Assert the live Forge tree has zero scannable forbidden pubspec.yaml files:
  ```bash
  local found
  found="$(find "$FORGE_ROOT_REAL" -type f -name pubspec.yaml \
    | grep -v "/.forge/" | grep -v "/examples/" | grep -v "/.dart_tool/" \
    | xargs grep -lE \
      'flutter_riverpod|^[[:space:]]+riverpod:|^[[:space:]]+provider:|^[[:space:]]+get:|^[[:space:]]+getx:|^[[:space:]]+mobx:|^[[:space:]]+flutter_mobx:|^[[:space:]]+states_rebuilder:' \
      2>/dev/null || true)"
  [ -z "$found" ]
  ```
  FAIL if any scannable pubspec.yaml contains a forbidden pkg (would mean a
  live-tree dep violation that must be resolved before the flip). This is the
  backward-compat assertion (FR-B811-057) independent of T-012. When
  `ci_blocking: true` is active, this test proves the live tree stays GREEN.
  [Story: FR-B811-052, FR-B811-057, NFR-B811-001, LOW-3]

- [x] **T-008** Implement 2 L2 test stubs gated on `FORGE_LINTER_FIXTURE_ROOT`
  (FR-B811-054). L2 runs only at level `1,2` or `all`.

  **L2-01** `_test_b811_l2_forbidden_pubspec` — FR-B811-040:
  ```bash
  if [ -z "${FORGE_LINTER_FIXTURE_ROOT:-}" ]; then
    echo "    SKIP: FORGE_LINTER_FIXTURE_ROOT not set"; return 0
  fi
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap "rm -rf '$tmpdir'" RETURN
  cat > "$tmpdir/pubspec.yaml" <<'PUBSPEC'
  name: b811_l2_forbidden
  dependencies:
    riverpod: ^2.0.0
  PUBSPEC
  local out
  out="$(FORGE_LINTER_FIXTURE_ROOT="$tmpdir" bash "$LINTER_SH" 2>&1 || true)"
  if ! printf '%s' "$out" | grep -qE "FAIL.*riverpod.*ci_blocking=true|forbidden state-mgmt dep.*riverpod.*ci_blocking=true"; then
    echo "    expected FAIL line with ci_blocking=true not found" >&2
    printf '%s\n' "$out" | grep -i "riverpod\|nsma\|state-mgmt" >&2 || true
    return 1
  fi
  ```
  When `FORGE_LINTER_FIXTURE_ROOT` is unset: emit SKIP, return 0 (not a FAIL).

  **L2-02** `_test_b811_l2_clean_pubspec` — FR-B811-041:
  Same gate on `FORGE_LINTER_FIXTURE_ROOT`. Create pubspec with only
  `flutter_bloc: ^9.0.0`. Assert NSMA section emits a PASS line
  (`no forbidden state-mgmt deps detected`). Assert no FAIL line for
  `ci_blocking=true` in the output.
  [Story: FR-B811-054, FR-B811-040, FR-B811-041]

- [x] **T-009** Run `bash .forge/scripts/tests/b8-11.test.sh --level 1` →
  confirm RED baseline. RESULT (2026-06-03): L1 7 PASS / 9 FAIL. RED (data-flip
  dependent): 001 ci_blocking, 002 version, 003 activation_planned, 004 audit-trail,
  008 REVIEW, 009 NSMA-section, 010 opt-out, 011 CHANGELOG, 012 forge-ci. Pre-flip
  PASS: 005 struct-pair, 006 pre_commit_hook, 007 forbidden-list, 013 no-new-bash,
  014 b8-3 coupling, 015 i3 coupling, 016 live-tree backward-compat. L2: SKIP-pass
  when FORGE_LINTER_FIXTURE_ROOT unset; with fixture set pre-flip, L2 forbidden
  RED (WARN not FAIL — correct), L2 clean PASS. T-016 (016) GREEN pre-flip = live
  tree has zero scannable forbidden deps, OK to proceed. Expected result: T-001..T-011 FAIL (ci_blocking still
  false; version still 1.0.0; no REVIEW.md 1.1.0 row; no NSMA section in
  linting-rules.md; no CHANGELOG entry; no forge-ci.yml b8-11 line).
  Expected pre-flip PASS (may vary): T-012 (no bash additions — passes since
  constitution-linter.sh untouched), T-013 (b8-3 coupling — passes if b8-3 is
  already GREEN), T-014 (i3 coupling — passes if i3 is already GREEN), T-015
  (backward-compat — passes since live tree has zero scannable forbidden deps).
  Record exact pass/fail counts. If T-015 is RED (live-tree forbidden dep
  exists), STOP and resolve before proceeding.
  [Story: FR-B811-052, Article I RED]

---

## Phase 2 — Standard flip GREEN

Edit `state-management.yaml` per ADR-B811-001..004. Makes T-001..T-006 green.

- [x] **T-010** Edit `.forge/standards/state-management.yaml`:
  (a) `version: "1.0.0"` → `version: "1.1.0"` (ADR-B811-003, FR-B811-010).
  (b) Update `last_reviewed:` to `2026-06-03` (FR-B811-006).
  (c) Add in-file version-history comment immediately below the `version:` line
      (FR-B811-011, ADR-B811-003):
      ```yaml
      # Version history:
      #   1.0.0 (T.4, 2026-05-04) — initial ratification; enforcement deferred (ci_blocking: false)
      #   1.1.0 (b8-11-nsma-linter, 2026-06-03) — ci_blocking activated; enforcement now CI-blocking
      ```
  (d) `enforcement.ci_blocking: false` → `true` with inline comment
      (ADR-B811-001/004, FR-B811-001):
      `ci_blocking: true   # activated B.8.11 (b8-11-nsma-linter, 2026-06-03) — formerly warn-only`
  (e) Replace `activation_planned: "B.8 (T6)"` with
      `activated_by: "b8-11-nsma-linter (B.8.11, 2026-06-03)"` (ADR-B811-004,
      FR-B811-002).
  (f) Add comment to `pre_commit_hook: false` line (ADR-B811-002, FR-B811-005):
      `pre_commit_hook: false  # runner is G.2 territory; flip to true when dep-linting hook ships`
  (g) Verify `forbidden:` list (8 entries), `flutter:` block, `linter_rule:`,
      and `rationale:` are BYTE-UNCHANGED (FR-B811-003).
  (h) Verify `expires_at: never` + `exception_constitutional: true` pair intact
      (FR-B811-004, NFR-B811-005).
  [Story: FR-B811-001, FR-B811-002, FR-B811-003, FR-B811-004, FR-B811-005,
   FR-B811-006, FR-B811-010, FR-B811-011, ADR-B811-002, ADR-B811-003,
   ADR-B811-004]

- [x] **T-011** Append a new H2 entry to `.forge/standards/REVIEW.md`
  (FR-B811-012, ADR-B811-003). Format mirrors transport.yaml v1.1.0 row at
  REVIEW.md:51-58 (LOW-2 corrected precedent):
  ```markdown
  ## 2026-06-03 — Updated state-management.yaml to v1.1.0 (b8-11-nsma-linter)

  | Standard | Version | Decision | Next review due | Notes |
  |----------|---------|----------|-----------------|-------|
  | state-management.yaml | 1.1.0 | KEEP-WITH-CHANGES | never (structural) | ci_blocking activated (B.8.11); enforcement now CI-blocking per ADR-006 + Article VI.3; structural-exception pair intact (expires_at: never + exception_constitutional: true) |

  - **Decision**: KEEP-WITH-CHANGES — `ci_blocking: false → true` activates
    the ratified-blocking gate. `activation_planned: "B.8 (T6)"` replaced with
    `activated_by: "b8-11-nsma-linter (B.8.11, 2026-06-03)"`. Version bumped
    1.0.0 → 1.1.0 (additive minor: enforcement fields only; `forbidden:`,
    `flutter:`, `linter_rule:`, `rationale:`, and structural-exception pair
    byte-unchanged). Satisfies J.7 FR-J7-023 (version↔REVIEW coupling).
  - **Next review due**: never (structural exception preserved).
  ```
  [Story: FR-B811-012, ADR-B811-003, NFR-B811-004]

- [x] **T-012** Run `bash bin/validate-standards-yaml.sh .forge/standards/`
  → must exit 0 (FR-B811-013, NFR-B811-004). RESULT (2026-06-03): EXIT=0, all 8
  standards [STD-PASS] including state-management.yaml (v1.1.0 ⇔ REVIEW row coupling
  + structural-exception pair verified). This verifies: (a) version `1.1.0`
  matches the REVIEW.md row (J.7 FR-J7-023); (b) structural-exception pair intact
  (J.7 FR-J7-020). A non-zero exit BLOCKS Phase 3.
  [Story: FR-B811-013, NFR-B811-004, J.7 FR-J7-023, J.7 FR-J7-020]

---

## Phase 3 — Governance doc GREEN

Append NSMA section to `global/linting-rules.md`. Makes T-008 and T-009 green.

- [x] **T-013** Append a new H2 section to
  `.forge/standards/global/linting-rules.md` (FR-B811-020, FR-B811-021,
  FR-B811-022, FR-B811-023, F.4 §4). The section MUST include:
  (a) H2 heading: `## ADR-006 State Management Discipline —
      no-state-management-alternatives` (rule name + anchor).
  (b) Rule description: the warn→fail activation performed by B.8.11; state that
      this is the scheduled activation of the ratified-blocking rule, not a new
      rule (Q-001 ruling: no Article XII amendment required).
  (c) Constitutional basis: cite `Article VI.3` ("State management SHALL use
      `flutter_bloc` exclusively") and `ADR-006` explicitly (FR-B811-023).
  (d) What triggers the rule: a forbidden package in `pubspec.yaml` under the
      scan root (excluding `/.forge/`, `/examples/`, `/.dart_tool/`).
  (e) FAIL message verbatim (from `constitution-linter.sh:L716`):
      `forbidden state-mgmt dep '${pkg}' in <path> (no-state-management-alternatives, ci_blocking=true)`
  (f) Backward-compat note (FR-B811-022): the NSMA scan excludes `/.forge/`,
      `/examples/`, and `/.dart_tool/` so template `.tmpl` files and archived
      examples under those paths are never retroactively failed. Zero scannable
      pubspec.yaml existed in the live Forge tree at activation (verified
      2026-06-03: `find . -name pubspec.yaml | grep -v "/.forge/" |
      grep -v "/examples/" | grep -v "/.dart_tool/"` → zero results, noting
      that real pubspec.yaml files exist under `examples/` but are excluded).
  (g) Activation state note: `pre_commit_hook: false` — the dep-linting
      pre-commit runner is G.2 territory; flip to `true` when a runner artifact
      ships (ADR-B811-002).
  (h) The `FORGE_LINTER_SKIP_NSMA=1` opt-out row added to the existing opt-out
      matrix table (FR-B811-021):
      `| FORGE_LINTER_SKIP_NSMA=1 | Skip ADR-006 state management alternatives check |`
  [Story: FR-B811-020, FR-B811-021, FR-B811-022, FR-B811-023, NFR-B811-008]

---

## Phase 4 — CHANGELOG + CI GREEN

Add CHANGELOG entry and register the harness in forge-ci.yml. Makes T-010 and
T-011 green.

- [x] **T-014** Append an `[Unreleased]` entry to `CHANGELOG.md` summarising the
  B.8.11 deliverables (FR-B811-056). The entry MUST contain the string
  `b8-11-nsma-linter` (whole-file grep, NOT bare "B.8.11" — changelog-test
  [Unreleased] coupling lesson). Content: `state-management.yaml` v1.1.0
  ci_blocking activated; `activated_by: b8-11-nsma-linter` audit field;
  `global/linting-rules.md` NSMA section + `FORGE_LINTER_SKIP_NSMA` opt-out row;
  harness `b8-11.test.sh` (~14 L1 + 2 L2); `forge-ci.yml` registration;
  release target v0.4.0-rc.13.
  [Story: FR-B811-056]

- [x] **T-015** Append `"b8-11.test.sh --level 1"` as a one-line entry to the
  `harnesses=()` loop in `.github/workflows/forge-ci.yml` after the
  `"b8-10.test.sh --level 1"` line (currently L115) (FR-B811-055).
  [Story: FR-B811-055]

---

## Phase 5 — Harness 14/14 GREEN + backward-compat verify

Run the complete harness after all edits are in. Verify the forbidden-fixture
now emits FAIL (post-flip) and the live tree still passes.

- [x] **T-016** Run `bash .forge/scripts/tests/b8-11.test.sh --level 1` →
  must exit 0 with all 14/14 GREEN. RESULT (2026-06-03): 16/16 L1 GREEN, EXIT=0
  (harness implements 16 L1 functions per the tasks.md MANIFEST: ci_blocking,
  version, activation_planned, audit-trail, struct-pair, pre_commit, forbidden-list,
  REVIEW, NSMA-section, opt-out, CHANGELOG, forge-ci, no-new-bash, b8-3, i3,
  backward-compat). Confirm each test:
  - T-001 (`ci_blocking: true`) GREEN
  - T-002 (`version: "1.1.0"`) GREEN
  - T-003 (`activation_planned` absent) GREEN
  - T-004 (`b8-11` audit trail present) GREEN
  - T-005 (structural-exception pair intact) GREEN
  - T-006 (`pre_commit_hook: false`) GREEN
  - T-007 (REVIEW.md row) GREEN
  - T-008 (linting-rules.md NSMA section + ADR-006 + VI.3) GREEN
  - T-009 (`FORGE_LINTER_SKIP_NSMA` opt-out row) GREEN
  - T-010 (CHANGELOG anchor) GREEN
  - T-011 (forge-ci.yml registration) GREEN
  - T-012 (no new bash in constitution-linter.sh) GREEN
  - T-013 (b8-3 coupling) GREEN
  - T-014 (i3 coupling) GREEN
  - T-015 (live-tree backward-compat — zero scannable forbidden deps) GREEN
  Record the full output. Any failure is a constitutional violation (Article V).
  [Story: FR-B811-052, FR-B811-053, FR-B811-055, FR-B811-056, FR-B811-057,
   NFR-B811-001, NFR-B811-002, Article V]

- [x] **T-017** L2 opt-in validation (`FORGE_LINTER_FIXTURE_ROOT` set):
  RESULT (2026-06-03): L1+L2 18/18 GREEN, EXIT=0. `_test_b811_l2_forbidden_pubspec`
  now emits the FAIL line with `ci_blocking=true` (riverpod fixture → FAIL,
  post-flip GREEN as asserted); `_test_b811_l2_clean_pubspec` emits the PASS line
  (`no forbidden state-mgmt deps detected`). When FORGE_LINTER_FIXTURE_ROOT unset,
  both L2 tests SKIP-pass.
  Create a tmpdir; write a `pubspec.yaml` with `riverpod: ^2.0.0` into it.
  Run: `FORGE_LINTER_FIXTURE_ROOT=<tmpdir> bash .forge/scripts/tests/b8-11.test.sh
  --level 1,2`. Assert L2-01 (`_test_b811_l2_forbidden_pubspec`) FAIL line
  `ci_blocking=true` is triggered — confirming that post-flip, a forbidden dep
  pubspec NOW emits FAIL (FR-B811-040). Then write a clean pubspec with
  `flutter_bloc: ^9.0.0` only and confirm L2-02 emits PASS (FR-B811-041).
  If `FORGE_LINTER_FIXTURE_ROOT` cannot be set in the current environment,
  record as `SKIP: FORGE_LINTER_FIXTURE_ROOT not set` — skip-pass (not a FAIL).
  [Story: FR-B811-040, FR-B811-041, FR-B811-054]

---

## Phase 6 — Gates + sibling safety + wrap-up

Run all gates. A partial sweep is insufficient — sibling scans can break
silently (`full_harness_suite_before_push` + `shared-standard sibling-harness
coupling` project memory lessons). Repo-wide scans MUST skip `N.N.N/` versioned
subtrees.

- [x] **T-018** Run `bash .forge/scripts/validate-change-yaml.sh
  .forge/changes/b8-11-nsma-linter/.forge.yaml` → must exit 0. Record output.
  [Story: Article V]

- [x] **T-019** Run `bash bin/validate-standards-yaml.sh .forge/standards/`
  → must exit 0 (directory-mode; FR-B811-013, NFR-B811-004, J.7 FR-J7-023).
  Record output.
  [Story: FR-B811-013, NFR-B811-004]

- [x] **T-020** Run `bash bin/verify.sh` → must exit 0 (PASS). Record output.
  [Story: Article V]

- [x] **T-021** Run `bash .forge/scripts/constitution-linter.sh` → must produce
  `OVERALL PASS` (FR-B811-030, NFR-B811-006). This is the live backward-compat
  proof: with `ci_blocking: true` active, the Forge repo must still be GREEN
  (zero scannable pubspec.yaml outside exclusions — P-21 confirmed at T-003).
  Confirm the NSMA section emits the `not_applicable` or `no forbidden state-mgmt
  deps` line (not a FAIL line). Record output.
  [Story: FR-B811-030, FR-B811-031, FR-B811-032, NFR-B811-006]

- [x] **T-022** Run `bash .forge/scripts/tests/b8-3.test.sh --level 1` → exit 0
  (schema invariants unaffected; B.8.11 touches no schema file, only
  `state-management.yaml` enforcement fields). Record output.
  [Story: FR-B811-013, NFR-B811-004]

- [x] **T-023** Run `bash .forge/scripts/tests/i3.test.sh --level 1` → exit 0
  (I.3 interlock intact; `state-management.yaml` still excluded from T3-Forbidden
  walk; `FORGE_LINTER_SKIP_NSMA=1` still consumed by the linter at L674).
  Record output.
  [Story: FR-B811-042, NFR-B811-008]

- [x] **T-024** Sibling scan: grep all harnesses in `.forge/scripts/tests/` for
  any that hard-assert `state-management.yaml` `ci_blocking: false` or
  `version: "1.0.0"` as a live-file assertion (not as a synthetic fixture
  inline YAML, which is safe). Known safe: `t4.test.sh:413` is an embedded
  inline fixture YAML for `_test_t4_l2_expired_warns` — not a grep of the live
  file. Also check for any harness asserting the linter emits WARN (not FAIL)
  for a forbidden pubspec against the real `state-management.yaml`. Known case:
  `t4.test.sh:343` `_test_t4_l2_lint_warn_riverpod` uses a broad grep
  `no-state-management-alternatives|state-management.*forbidden|forbidden.*riverpod`
  that matches both WARN and FAIL text — survives the flip without change;
  verify by running `t4.test.sh --level 1` (L1 only; L2 requires live linter).
  For each harness asserting the old `ci_blocking: false` or `version: "1.0.0"`
  against the LIVE file: fix the assertion to match the new values and re-run to
  confirm GREEN. A regression in a sibling harness is a blocker
  (`shared-standard sibling-harness coupling` lesson from B.8.6/transport.yaml).
  Record all harness names checked and their exit codes.
  [Story: NFR-B811-002, `shared-standard sibling-harness coupling` lesson]

- [x] **T-025** Neutralize all `[NEEDS CLARIFICATION:]` markers in `specs.md`
  that were resolved by the ADRs and Phase 0 live evidence (b8-9/b8-10
  precedent). Per `open-questions.md` anchor table:
  - Q-001 marker → `Resolved by ADR-B811-001: no fresh Article XII amendment
    required; VI.3 + ADR-006 already mandate blocking; B.8.11 is the scheduled
    activation executing F.4 §2-4; ratified by independent reviewer 2026-06-03.`
  - Q-002 marker → `Resolved by ADR-B811-002: pre_commit_hook keeps false; no
    dep-linting runner artifact ships; runner is G.2 territory.`
  - Q-003 marker → `Resolved by ADR-B811-003: version 1.0.0 → 1.1.0 minor bump;
    transport.yaml v1.1.0 (t5-connect-codegen) precedent.`
  - Q-004 marker → `Resolved by ADR-B811-004: activated_by:
    "b8-11-nsma-linter (B.8.11, 2026-06-03)" field replaces activation_planned;
    schema-legal (enforcement.additionalProperties: true, P-19).`
  Do NOT modify `.omc/plans/*.md` (plan files are read-only).
  [Story: Article III.4, FR-B811-002]

- [x] **T-026** Run the FULL ~50-harness suite
  (`for h in .forge/scripts/tests/*.test.sh; do bash "$h" --level 1; done`).
  Verify each harness exits 0. Pay attention to:
  - `t4.test.sh` — references `state-management.yaml` (parseable, exception_constitutional, forbidden list); confirm all assertions still GREEN post-flip.
  - `j7.test.sh` — validates standards YAML schema; the synthetic `state-management.yaml` fixture at line 499 is self-contained and unaffected.
  - Any harness whose repo-wide scan of `linting-rules.md` might pick up the
    new NSMA section (e.g. delivery-related harnesses).
  Versioned `N.N.N/` subtrees are exempt from repo-wide scans per
  scaffolding.md convention. Any regression is a blocker (NFR-B811-002).
  Record all harness names and exit codes.
  [Story: NFR-B811-002, `full_harness_suite_before_push` lesson]

- [x] **T-027** Flip `.forge/changes/b8-11-nsma-linter/.forge.yaml`:
  `status: designed → planned` AND add `timeline.planned: 2026-06-03`.
  Run `bash .forge/scripts/validate-change-yaml.sh
  .forge/changes/b8-11-nsma-linter/.forge.yaml` → exit 0. Then immediately
  **re-run POST-flip gates** (b8-coroot lesson: gates re-run AFTER the flip,
  not trusted from pre-flip run). Re-run at minimum:
  `b8-11.test.sh --level 1` (14/14), `b8-3.test.sh --level 1`,
  `i3.test.sh --level 1`, `validate-standards-yaml.sh`, `verify.sh`,
  `constitution-linter.sh`. Record all outputs.
  [Story: Article V, b8-coroot lesson]
  **NOTE**: this task is the `.forge.yaml` flip for `planned` only. The
  `implemented` flip happens after implementation is complete, in a separate
  wrap-up task.

- [x] **T-028** Independent review pass (separate lane — author MUST NOT
  self-approve; NFR-B811-007; t5-2 self-validation lesson). The independent
  reviewer MUST re-execute (not trust the transcript):
  `b8-11.test.sh --level 1` (14/14), `b8-3.test.sh --level 1` (schema),
  `i3.test.sh --level 1` (I.3 interlock), `validate-standards-yaml.sh .forge/standards/`,
  `constitution-linter.sh` (OVERALL PASS), `verify.sh`, and the
  `[NEEDS CLARIFICATION:]` neutralization check on `specs.md`.
  Record the reviewer's name and run timestamp in the change record.
  [Story: NFR-B811-007, Article V.2, t5-2 lesson]

- [x] **T-029** Archive prep: verify all tasks marked complete, run
  `/forge:archive b8-11-nsma-linter` to flip status `implemented → archived`
  after the independent review PASS. Note: the implemented flip (status
  `planned → implemented` + `timeline.implemented: <date>`) occurs at the end
  of the implementation phase; the archive flip occurs after the independent
  review PASS.
  [Story: Article V]

---

## FR-B811-* / NFR-B811-* Coverage Table

All 29 FRs + 8 NFRs covered.

| FR / NFR | Task(s) |
|----------|---------|
| FR-B811-001 | T-007 (T-001), T-010, T-016 |
| FR-B811-002 | T-007 (T-003/T-004), T-010, T-016, T-025 |
| FR-B811-003 | T-007 (T-012 git diff), T-010, T-016 |
| FR-B811-004 | T-007 (T-005), T-010, T-016 |
| FR-B811-005 | T-007 (T-006), T-010, T-016 |
| FR-B811-006 | T-010, T-016 (last_reviewed date update) |
| FR-B811-010 | T-007 (T-002), T-010, T-016 |
| FR-B811-011 | T-010 (in-file version-history comment), T-007 (T-004 b8-11 grep) |
| FR-B811-012 | T-007 (T-007), T-011, T-016 |
| FR-B811-013 | T-012, T-019, T-022 (b8-3 coupling) |
| FR-B811-020 | T-007 (T-008), T-013, T-016 |
| FR-B811-021 | T-007 (T-009), T-013, T-016 |
| FR-B811-022 | T-013 (backward-compat note in NSMA section), T-016 |
| FR-B811-023 | T-007 (T-008), T-013, T-016 |
| FR-B811-030 | T-021 (constitution-linter.sh OVERALL PASS), T-007 (T-015) |
| FR-B811-031 | T-021 (/.forge/ exclusion structural, confirmed T-001) |
| FR-B811-032 | T-007 (T-015), T-021 |
| FR-B811-040 | T-008 (L2-01), T-017 |
| FR-B811-041 | T-008 (L2-02), T-017 |
| FR-B811-042 | T-007 (T-014), T-001, T-023 |
| FR-B811-043 | T-007 (T-012), T-016 |
| FR-B811-050 | T-006, T-016 |
| FR-B811-051 | T-006, T-016 |
| FR-B811-052 | T-007, T-008, T-009, T-016 |
| FR-B811-053 | T-007 (T-013/T-014), T-016 |
| FR-B811-054 | T-008, T-017 |
| FR-B811-055 | T-007 (T-011), T-015, T-016 |
| FR-B811-056 | T-007 (T-010), T-014, T-016 |
| FR-B811-057 | T-007 (T-015), T-016, T-021 (LOW-3: dedicated test id) |
| NFR-B811-001 | T-007 (≤ 2 s), T-009 (confirmed), T-016 |
| NFR-B811-002 | T-009, T-016, T-026 (full ~50-harness suite) |
| NFR-B811-003 | T-007 (T-012), T-016 (no new bash in constitution-linter.sh) |
| NFR-B811-004 | T-012, T-019, T-022 (validate-standards-yaml.sh exit 0) |
| NFR-B811-005 | T-007 (T-005), T-010, T-016 (structural-exception pair) |
| NFR-B811-006 | T-021 (constitution-linter.sh OVERALL PASS post-flip) |
| NFR-B811-007 | T-028 (independent review — separate lane) |
| NFR-B811-008 | T-001 (EXCLUDE_STANDARDS re-read), T-007 (T-014), T-023 |
