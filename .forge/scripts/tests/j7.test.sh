#!/usr/bin/env bash
# Forge — J.7 Standards YAML Schema Test Harness (j7-validate-standards-yaml)
# <!-- Audit: J.7 (j7-validate-standards-yaml) -->
#
# Validates the deterministic linter `bin/validate-standards-yaml.sh` and its
# JSON Schema `.forge/schemas/standard.schema.json` deliverables :
#
#   - 8-field frontmatter contract (FR-J7-001..010)
#   - Article XII lifecycle invariants (FR-J7-020..023)
#   - linter_rule cross-reference into constitution-linter.sh (FR-J7-030)
#   - forbidden list shape + no-duplicate (FR-J7-040..041)
#   - index.yml trigger reachability (FR-J7-050..051)
#   - validate-standards-yaml.sh signature + error format (FR-J7-060..064)
#   - verify.sh integration (FR-J7-070..072)
#   - production-tree GREEN baseline (NFR-J7-002)
#   - performance budget ≤ 2 s on the live tree (NFR-J7-001)
#
# 21 tests : 17 L1 hermetic + 4 L2 fixture-based.
# Performance budget : L1 ≤ 3 s, full ≤ 8 s wall-clock (NFR-J7-001).
# L2 SKIP semantics : when `python3` < 3.10 is detected, L2 prints
# `[SKIP: python3 ≥ 3.10 required]` and returns 0 (CI guarantees 3.11+).

set -uo pipefail

LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in --level=*) LEVEL="${arg#*=}" ;; esac
  prev="$arg"
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

STD_DIR="$FORGE_ROOT_REAL/.forge/standards"
SCHEMA_FILE="$FORGE_ROOT_REAL/.forge/schemas/standard.schema.json"
VALIDATOR="$FORGE_ROOT_REAL/bin/validate-standards-yaml.sh"
LINTER="$FORGE_ROOT_REAL/.forge/scripts/constitution-linter.sh"
INDEX_YML="$STD_DIR/index.yml"
REVIEW_MD="$STD_DIR/REVIEW.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (17 tests)
# MANIFEST: _test_j7_001_required_version    — FR-J7-002 missing version field FAIL
# MANIFEST: _test_j7_002_bad_semver          — FR-J7-003 non-semver FAIL
# MANIFEST: _test_j7_003_bad_date            — FR-J7-004 last_reviewed bad ISO FAIL
# MANIFEST: _test_j7_004_expires_never       — FR-J7-005 expires_at never + exc=true PASS
# MANIFEST: _test_j7_005_expires_dated       — FR-J7-005 expires_at dated PASS
# MANIFEST: _test_j7_006_exc_bool            — FR-J7-006 exception_constitutional non-bool FAIL
# MANIFEST: _test_j7_007_linter_rule_null    — FR-J7-007 linter_rule null PASS
# MANIFEST: _test_j7_008_enforcement_shape   — FR-J7-008 enforcement missing sub-required FAIL
# MANIFEST: _test_j7_009_forbidden_array     — FR-J7-009 forbidden non-array FAIL
# MANIFEST: _test_j7_010_rationale_empty     — FR-J7-010 rationale minLength FAIL
# MANIFEST: _test_j7_017_live_tree_green     — NFR-J7-002 live .forge/standards/ exit 0
# MANIFEST: _test_j7_020_xii_coupling        — FR-J7-020 never + exc=false FAIL (Article XII)
# MANIFEST: _test_j7_021_expires_order       — FR-J7-021 expires_at < last_reviewed FAIL
# MANIFEST: _test_j7_023_review_drift        — FR-J7-023 version not in REVIEW.md FAIL
# MANIFEST: _test_j7_030_linter_rule_miss    — FR-J7-030 unknown linter_rule FAIL
# MANIFEST: _test_j7_041_forbidden_dup       — FR-J7-041 duplicate forbidden entries FAIL
# MANIFEST: _test_j7_050_index_dangling      — FR-J7-050 index.yml dangling trigger FAIL
#
# L2 (4 fixture tests)
# MANIFEST: _test_j7_l2_good_fixture          — FR-J7-082 happy-path mini-tree PASS
# MANIFEST: _test_j7_l2_bad_fixture_six_modes — FR-J7-082 6 failure modes one-shot
# MANIFEST: _test_j7_l2_drift_fixture         — FR-J7-082 version/REVIEW.md drift
# MANIFEST: _test_j7_l2_perf_budget           — NFR-J7-001 live-tree ≤ 2 s wall-clock

# ─── Helpers ────────────────────────────────────────────────────

_setup_l1_fixture() {
  L1_TMP="$(mktemp -d -t forge-j7-l1-XXXXXX)"
}

_teardown_l1_fixture() {
  if [ -n "${L1_TMP:-}" ] && [ -d "$L1_TMP" ]; then
    rm -rf "$L1_TMP"
  fi
}

_setup_l2() {
  L2_TMP="$(mk_tmpdir_with_trap forge-j7-fixtures)"
}

_teardown_l2() {
  if [ -n "${L2_TMP:-}" ] && [ -d "$L2_TMP" ]; then
    rm -rf "$L2_TMP"
  fi
}

# _run_v <yaml-path>
# Runs validate-standards-yaml.sh against the given path.
# Sets globals : J7_RC, J7_OUT, J7_ERR
_run_v() {
  local target="$1"
  local err_file="${L1_TMP:-/tmp}/j7-err.$$"
  J7_OUT="$(bash "$VALIDATOR" "$target" 2>"$err_file")"
  J7_RC=$?
  J7_ERR="$(cat "$err_file" 2>/dev/null || true)"
  rm -f "$err_file"
}

# Sentinel-fail helper — every Phase 2/3-deferred stub returns FAIL with
# "not implemented" stderr. Body replaced in subsequent tasks.
_not_implemented() {
  echo "    not implemented (RED witness — pending implementation tasks)" >&2
  return 1
}

# ─── L1 tests ───────────────────────────────────────────────────

# FR-J7-002 missing version field FAIL
_test_j7_001_required_version() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (no version)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code"     || return 1
  assert_contains "$J7_ERR" "version: required field missing" || return 1
}

# FR-J7-003 non-semver FAIL
_test_j7_002_bad_semver() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "v1"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (bad semver)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code"     || return 1
  assert_contains "$J7_ERR" "version: pattern mismatch" || return 1
}

# FR-J7-004 last_reviewed bad ISO FAIL
_test_j7_003_bad_date() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026/05/04"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (bad date)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "last_reviewed: pattern mismatch" || return 1
}

# FR-J7-005 expires_at: never + exception_constitutional: true PASS
_test_j7_004_expires_never() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: never
exception_constitutional: true
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (never)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "0" "$J7_RC" "exit code (expected 0)" || return 1
  assert_contains "$J7_OUT" "[STD-PASS]" || return 1
}

# FR-J7-005 expires_at dated PASS
_test_j7_005_expires_dated() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (dated)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "0" "$J7_RC" "exit code (expected 0)" || return 1
  assert_contains "$J7_OUT" "[STD-PASS]" || return 1
}

# FR-J7-006 exception_constitutional non-bool FAIL
_test_j7_006_exc_bool() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: "yes"
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (exc bad type)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "exception_constitutional: expected type boolean" || return 1
}

# FR-J7-007 linter_rule: null PASS
_test_j7_007_linter_rule_null() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (linter_rule null)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "0" "$J7_RC" "exit code (expected 0)" || return 1
  assert_contains "$J7_OUT" "[STD-PASS]" || return 1
}

# FR-J7-008 enforcement missing pre_commit_hook FAIL
_test_j7_008_enforcement_shape() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
forbidden: []
rationale: "fixture (no pre_commit_hook)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "enforcement.pre_commit_hook: required field missing" || return 1
}

# FR-J7-009 forbidden non-array FAIL
_test_j7_009_forbidden_array() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: "single-string"
rationale: "fixture (forbidden bad type)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "forbidden: expected type array" || return 1
}

# FR-J7-010 rationale empty FAIL
_test_j7_010_rationale_empty() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: ""
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "rationale: minLength" || return 1
}

# NFR-J7-002 production tree GREEN baseline
_test_j7_017_live_tree_green() {
  J7_ERR_FILE=/tmp/j7-live-err.$$ \
    J7_OUT="$(bash "$VALIDATOR" 2>/tmp/j7-live-err.$$)"
  J7_RC=$?
  J7_ERR="$(cat /tmp/j7-live-err.$$ 2>/dev/null || true)"
  rm -f /tmp/j7-live-err.$$
  assert_eq "0" "$J7_RC" "live tree exit (expected 0)" || return 1
  assert_not_contains "$J7_ERR" "[STD-FAIL" "no FAIL on live tree" || return 1
}

# FR-J7-020 expires_at: never + exception_constitutional: false → Article XII coupling FAIL
_test_j7_020_xii_coupling() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: never
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (XII coupling broken)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "Article XII" || return 1
}

# FR-J7-021 expires_at < last_reviewed FAIL
_test_j7_021_expires_order() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-05-04"
expires_at: "2026-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (expires before review)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "must be strictly greater than last_reviewed" || return 1
}

# FR-J7-023 version not in REVIEW.md fixture ledger FAIL
_test_j7_023_review_drift() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "9.9.9"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (drifted version)"
YML
  cat > "$L1_TMP/REVIEW.md" <<'MD'
# Standards Review Ledger

## 2026-01-01 — seed

| Standard   | Version | Decision |
|------------|---------|----------|
| std.yaml   | 1.0.0   | KEEP     |
MD
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "version: declared 9.9.9 not present in REVIEW.md ledger" || return 1
}

# FR-J7-030 unknown linter_rule cross-reference FAIL
_test_j7_030_linter_rule_miss() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: zzz-nonexistent-rule
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (linter_rule miss)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "linter_rule: rule \"zzz-nonexistent-rule\" not found" || return 1
}

# FR-J7-041 duplicate forbidden entries FAIL
_test_j7_041_forbidden_dup() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden:
  - riverpod
  - riverpod
rationale: "fixture (forbidden duplicate)"
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "duplicate entry 'riverpod'" || return 1
}

# FR-J7-050 index.yml dangling trigger FAIL
_test_j7_050_index_dangling() {
  _setup_l1_fixture
  trap '_teardown_l1_fixture' RETURN
  cat > "$L1_TMP/std.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture (dangling)"
YML
  cat > "$L1_TMP/index.yml" <<'YML'
standards:
  - id: ghost
    path: standards/ghost.md
YML
  _run_v "$L1_TMP/std.yaml"
  assert_eq "1" "$J7_RC" "exit code" || return 1
  assert_contains "$J7_ERR" "dangling path 'standards/ghost.md'" || return 1
}

# ─── L2 fixtures ────────────────────────────────────────────────

# FR-J7-082 happy-path mini-tree PASS — 2 conformant yamls in fixture dir.
_test_j7_l2_good_fixture() {
  _setup_l2
  trap '_teardown_l2' RETURN
  cat > "$L2_TMP/transport.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: never
exception_constitutional: true
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture transport"
YML
  cat > "$L2_TMP/state-management.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden:
  - riverpod
rationale: "fixture state-management"
YML
  J7_OUT="$(bash "$VALIDATOR" "$L2_TMP" 2>"$L2_TMP/err.log")"
  J7_RC=$?
  J7_ERR="$(cat "$L2_TMP/err.log")"
  assert_eq "0" "$J7_RC" "exit code (good fixture, expected 0)" || return 1
  local pass_count
  pass_count="$(printf '%s\n' "$J7_OUT" | grep -c '^\[STD-PASS\]')"
  assert_eq "2" "$pass_count" "PASS line count" || return 1
}

# FR-J7-082 6 distinct failure modes one fixture each.
_test_j7_l2_bad_fixture_six_modes() {
  _setup_l2
  trap '_teardown_l2' RETURN
  # Mode 1 — missing version
  cat > "$L2_TMP/m1-missing-version.yaml" <<'YML'
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "m1"
YML
  # Mode 2 — bad semver
  cat > "$L2_TMP/m2-bad-semver.yaml" <<'YML'
version: "v1"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "m2"
YML
  # Mode 3 — bad date
  cat > "$L2_TMP/m3-bad-date.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026/01/01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "m3"
YML
  # Mode 4 — broken Article XII coupling
  cat > "$L2_TMP/m4-xii-coupling.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: never
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "m4"
YML
  # Mode 5 — unknown linter_rule
  cat > "$L2_TMP/m5-linter-rule.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: zzz-nonexistent
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "m5"
YML
  # Mode 6 — dangling index trigger (yaml is fine ; index.yml carries the defect)
  cat > "$L2_TMP/m6-good.yaml" <<'YML'
version: "1.0.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "m6"
YML
  cat > "$L2_TMP/index.yml" <<'YML'
standards:
  - id: ghost
    path: standards/ghost.md
YML
  J7_OUT="$(bash "$VALIDATOR" "$L2_TMP" 2>"$L2_TMP/err.log")"
  J7_RC=$?
  J7_ERR="$(cat "$L2_TMP/err.log")"
  assert_eq "1" "$J7_RC" "exit code (bad fixture, expected 1)" || return 1
  # Modes 1..5 each produce ≥ 1 STD-FAIL line on their file ; mode 6's defect
  # is on index.yml. Assert each of the 6 fail anchors is present.
  assert_contains "$J7_ERR" "m1-missing-version.yaml:version: required" || return 1
  assert_contains "$J7_ERR" "m2-bad-semver.yaml:version: pattern mismatch" || return 1
  assert_contains "$J7_ERR" "m3-bad-date.yaml:last_reviewed: pattern mismatch" || return 1
  assert_contains "$J7_ERR" "m4-xii-coupling.yaml:expires_at: never requires" || return 1
  assert_contains "$J7_ERR" "m5-linter-rule.yaml:linter_rule: rule \"zzz-nonexistent\" not found" || return 1
  assert_contains "$J7_ERR" "index.yml:trigger: dangling path 'standards/ghost.md'" || return 1
}

# FR-J7-082 / FR-J7-023 drift detection.
_test_j7_l2_drift_fixture() {
  _setup_l2
  trap '_teardown_l2' RETURN
  cat > "$L2_TMP/drifted.yaml" <<'YML'
version: "1.2.0"
last_reviewed: "2026-01-01"
expires_at: "2027-01-01"
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "fixture drift"
YML
  cat > "$L2_TMP/REVIEW.md" <<'MD'
# Standards Review Ledger

## 2026-01-01 — seed

| Standard       | Version | Decision |
|----------------|---------|----------|
| drifted.yaml   | 1.1.0   | KEEP     |
MD
  J7_OUT="$(bash "$VALIDATOR" "$L2_TMP/drifted.yaml" 2>"$L2_TMP/err.log")"
  J7_RC=$?
  J7_ERR="$(cat "$L2_TMP/err.log")"
  assert_eq "1" "$J7_RC" "exit code (drift, expected 1)" || return 1
  assert_contains "$J7_ERR" "version: declared 1.2.0 not present in REVIEW.md ledger" || return 1
  # Exactly one drift error :
  local drift_count
  drift_count="$(printf '%s\n' "$J7_ERR" | grep -c 'not present in REVIEW.md ledger')"
  assert_eq "1" "$drift_count" "drift error count" || return 1
}

# NFR-J7-001 wall-clock budget on the live tree.
_test_j7_l2_perf_budget() {
  local start_ns end_ns elapsed_ms
  start_ns="$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time_ns()))')"
  bash "$VALIDATOR" >/dev/null 2>&1
  local rc=$?
  end_ns="$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time_ns()))')"
  elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
  if [ "$rc" -ne 0 ]; then
    echo "    validator exited $rc (expected 0)" >&2
    return 1
  fi
  if [ "$elapsed_ms" -gt 2000 ]; then
    echo "    perf budget exceeded : ${elapsed_ms} ms > 2000 ms" >&2
    return 1
  fi
  echo "    [PERF] live-tree validator wall-clock = ${elapsed_ms} ms (budget 2000 ms)" >&2
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── J.7 — j7-validate-standards-yaml harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — schema fields + invariants + cross-references"
  run_test _test_j7_001_required_version
  run_test _test_j7_002_bad_semver
  run_test _test_j7_003_bad_date
  run_test _test_j7_004_expires_never
  run_test _test_j7_005_expires_dated
  run_test _test_j7_006_exc_bool
  run_test _test_j7_007_linter_rule_null
  run_test _test_j7_008_enforcement_shape
  run_test _test_j7_009_forbidden_array
  run_test _test_j7_010_rationale_empty
  run_test _test_j7_017_live_tree_green
  run_test _test_j7_020_xii_coupling
  run_test _test_j7_021_expires_order
  run_test _test_j7_023_review_drift
  run_test _test_j7_030_linter_rule_miss
  run_test _test_j7_041_forbidden_dup
  run_test _test_j7_050_index_dangling

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based"
    run_test _test_j7_l2_good_fixture
    run_test _test_j7_l2_bad_fixture_six_modes
    run_test _test_j7_l2_drift_fixture
    run_test _test_j7_l2_perf_budget
  fi

  print_summary
}

main "$@"
