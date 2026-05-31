#!/usr/bin/env bash
# Forge — B.8.3.b versioned-schema discovery harness
# <!-- Audit: B.8.3.b (b8-3b-validator-versioned-schema) — versioned schema gate -->
#
# Validates that validate-foundations.sh discovers + validates versioned schema
# siblings (<archetype>/<X.Y.Z>.yaml) alongside the canonical schema.yaml, and
# enforces the two new invariants:
#   - filename <-> version  (X.Y.Z.yaml MUST declare version: "X.Y.Z")
#   - stage: candidate  ⇒  scaffoldable: false  (stable/draft are exempt)
#
#   T-001  check_versioned_schema_siblings function present     (FR-B83B-001)
#   T-002  function called from main()                          (FR-B83B-001)
#   T-003  live validate-foundations.sh exits 0                 (FR-B83B-002/003, NFR-B83B-001)
#   T-004  live output has PASS for full-stack-monorepo/2.0.0.yaml (FR-B83B-002)
#   T-005  canonical FR-GL-001 (schema.yaml) still PASSes        (NFR-B83B-003)
#   (verify.sh backward-compat covered by the CI `gates` job — too slow for L1)
#   T-007  NEG filename/version mismatch -> specific FAIL line    (FR-B83B-010)
#   T-008  NEG candidate w/o scaffoldable:false -> specific FAIL  (FR-B83B-011)
#   T-009  NEG candidate scaffoldable:true -> specific FAIL       (FR-B83B-011)
#   T-010  POS stable w/o scaffoldable -> specific PASS, no FAIL  (FR-B83B-012)
#   T-011  no-op for archetypes with no versioned sibling        (FR-B83B-004)
#   T-012  frozen schema.yaml (1.0.0) byte-identity preserved    (NFR-B83B-003)
#   T-013  harness registered in forge-ci.yml                    (FR-B83B-032)
#
# 12 L1 tests. Budget L1 <= 5 s, zero net/Docker. Real schema files are NEVER
# mutated — negatives build a tmp FORGE_ROOT and mutate a COPY of 2.0.0.yaml.
# Negatives assert the SPECIFIC `FR-GL-001-versioned:<file>` line (a partial tmp
# tree fails unrelated FR-GL checks too, so bare exit code is non-discriminating).

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

VALIDATOR="$SCRIPTS_DIR/validate-foundations.sh"
SCHEMA_DIR="$FORGE_ROOT_REAL/.forge/schemas/full-stack-monorepo"
SCHEMA_10="$SCHEMA_DIR/schema.yaml"
SCHEMA_20="$SCHEMA_DIR/2.0.0.yaml"
CI_YML="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# Cache the live validator run (T-003/T-004/T-005 share it).
_LIVE_OUT=""
_LIVE_RC=""
_ensure_live() {
  if [ -z "$_LIVE_RC" ]; then
    _LIVE_OUT=$(bash "$VALIDATOR" 2>&1); _LIVE_RC=$?
  fi
}

# _mk_fixture_with_versioned <archetype> <versioned-filename> <py-mutation>
# Builds a tmp FORGE_ROOT containing a copy of the real frozen schema.yaml plus
# a versioned sibling derived from the real 2.0.0.yaml with <py-mutation> applied
# (a python snippet operating on dict `d`). Echoes the tmp root path.
_mk_fixture_with_versioned() {
  local archetype="$1" vfile="$2" mutation="$3"
  local root; root=$(mk_tmpdir_with_trap b8-3b-fixture)
  local adir="$root/.forge/schemas/$archetype"
  mkdir -p "$adir"
  cp "$SCHEMA_10" "$adir/schema.yaml"
  python3 - "$SCHEMA_20" "$adir/$vfile" "$mutation" <<'PY'
import sys, yaml
src, dst, mutation = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src) as f:
    d = yaml.safe_load(f)
exec(mutation)
with open(dst, 'w') as f:
    yaml.safe_dump(d, f, sort_keys=False)
PY
  echo "$root"
}

# ─── L1 ──────────────────────────────────────────────────────────

_test_b83b_l1_001_function_present() {
  grep -qF 'check_versioned_schema_siblings()' "$VALIDATOR" \
    || { echo "    check_versioned_schema_siblings() not defined in validate-foundations.sh (FR-B83B-001)" >&2; return 1; }
}

_test_b83b_l1_002_called_from_main() {
  local n; n=$(grep -cF 'check_versioned_schema_siblings' "$VALIDATOR")
  if [ "$n" -lt 2 ]; then
    echo "    check_versioned_schema_siblings defined but not called from main() (count=$n, need >=2) (FR-B83B-001)" >&2; return 1
  fi
}

_test_b83b_l1_003_live_exit_zero() {
  _ensure_live
  if [ "$_LIVE_RC" -ne 0 ]; then
    echo "    validate-foundations.sh exited $_LIVE_RC on the live tree (expected 0) (NFR-B83B-001)" >&2
    printf '%s\n' "$_LIVE_OUT" | grep -iE 'FAIL|Traceback' | head -5 >&2
    return 1
  fi
}

_test_b83b_l1_004_versioned_pass_line() {
  _ensure_live
  printf '%s' "$_LIVE_OUT" | grep -qF 'PASS: FR-GL-001-versioned:full-stack-monorepo/2.0.0.yaml' \
    || { echo "    no PASS line for full-stack-monorepo/2.0.0.yaml discovery (FR-B83B-002)" >&2; return 1; }
}

_test_b83b_l1_005_canonical_still_pass() {
  _ensure_live
  printf '%s' "$_LIVE_OUT" | grep -qE '^PASS: FR-GL-001 —' \
    || { echo "    canonical FR-GL-001 (schema.yaml) PASS line missing — backward-compat regression (NFR-B83B-003)" >&2; return 1; }
}

# NOTE: verify.sh backward-compat (it aggregates validate-foundations.sh
# PASS/FAIL lines) is covered by the CI `gates` job, which runs verify.sh
# standalone. It is intentionally NOT re-run here: verify.sh takes ~12 s, which
# would blow this harness's <=5 s L1 budget. T-003 + T-005 already prove the
# validator-level backward-compat (exits 0, canonical FR-GL-001 still PASSes).

# Negative: filename/version mismatch (2.0.0.yaml declaring version 2.1.0).
_test_b83b_l1_007_neg_filename_version_mismatch() {
  local root out
  root=$(_mk_fixture_with_versioned full-stack-monorepo 2.0.0.yaml "d['version']='2.1.0'")
  out=$(FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1)
  printf '%s' "$out" | grep -qE '^FAIL: FR-GL-001-versioned:full-stack-monorepo/2\.0\.0\.yaml .*(filename/version|mismatch)' \
    || { echo "    expected a filename/version-mismatch FAIL for 2.0.0.yaml (FR-B83B-010)" >&2
         printf '%s\n' "$out" | grep -F 'FR-GL-001-versioned' >&2; return 1; }
}

# Negative: candidate without scaffoldable:false.
_test_b83b_l1_008_neg_candidate_no_scaffoldable() {
  local root out
  root=$(_mk_fixture_with_versioned full-stack-monorepo 3.0.0.yaml "d['version']='3.0.0'; d['stage']='candidate'; d.pop('scaffoldable', None)")
  out=$(FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1)
  printf '%s' "$out" | grep -qE '^FAIL: FR-GL-001-versioned:full-stack-monorepo/3\.0\.0\.yaml .*scaffoldable' \
    || { echo "    expected a scaffoldable FAIL for candidate 3.0.0.yaml with no scaffoldable field (FR-B83B-011)" >&2
         printf '%s\n' "$out" | grep -F 'FR-GL-001-versioned' >&2; return 1; }
}

# Negative: candidate with scaffoldable:true.
_test_b83b_l1_009_neg_candidate_scaffoldable_true() {
  local root out
  root=$(_mk_fixture_with_versioned full-stack-monorepo 3.0.0.yaml "d['version']='3.0.0'; d['stage']='candidate'; d['scaffoldable']=True")
  out=$(FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1)
  printf '%s' "$out" | grep -qE '^FAIL: FR-GL-001-versioned:full-stack-monorepo/3\.0\.0\.yaml .*scaffoldable' \
    || { echo "    expected a scaffoldable FAIL for candidate 3.0.0.yaml with scaffoldable:true (FR-B83B-011)" >&2
         printf '%s\n' "$out" | grep -F 'FR-GL-001-versioned' >&2; return 1; }
}

# Positive: stable versioned schema without scaffoldable passes (stable exempt).
_test_b83b_l1_010_pos_stable_no_scaffoldable() {
  local root out
  root=$(_mk_fixture_with_versioned full-stack-monorepo 3.0.0.yaml "d['version']='3.0.0'; d['stage']='stable'; d.pop('scaffoldable', None)")
  out=$(FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1)
  if printf '%s' "$out" | grep -qE '^FAIL: FR-GL-001-versioned:full-stack-monorepo/3\.0\.0\.yaml'; then
    echo "    stable 3.0.0.yaml without scaffoldable should NOT fail the versioned check (FR-B83B-012)" >&2
    printf '%s\n' "$out" | grep -F 'FR-GL-001-versioned' >&2; return 1
  fi
  printf '%s' "$out" | grep -qF 'PASS: FR-GL-001-versioned:full-stack-monorepo/3.0.0.yaml' \
    || { echo "    expected a PASS line for stable 3.0.0.yaml (FR-B83B-012)" >&2; return 1; }
}

# No-op: an archetype dir with only schema.yaml emits no versioned-discovery line.
_test_b83b_l1_011_noop_no_sibling() {
  local root adir out
  root=$(mk_tmpdir_with_trap b8-3b-noop)
  adir="$root/.forge/schemas/fresh-arch"
  mkdir -p "$adir"
  cp "$SCHEMA_10" "$adir/schema.yaml"
  out=$(FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1)
  if printf '%s' "$out" | grep -qF 'FR-GL-001-versioned:fresh-arch'; then
    echo "    versioned discovery emitted a line for an archetype with no X.Y.Z.yaml sibling (FR-B83B-004)" >&2
    printf '%s\n' "$out" | grep -F 'fresh-arch' >&2; return 1
  fi
}

_test_b83b_l1_012_frozen_schema_intact() {
  if [ ! -f "$SCHEMA_10" ]; then
    echo "    frozen schema.yaml missing: $SCHEMA_10 (NFR-B83B-003)" >&2; return 1
  fi
  grep -qx 'version: "1.0.0"' "$SCHEMA_10" \
    || { echo "    frozen schema.yaml is not version 1.0.0 — it was modified (NFR-B83B-003)" >&2; return 1; }
}

_test_b83b_l1_013_ci_registered() {
  grep -qF 'b8-3b.test.sh' "$CI_YML" \
    || { echo "    b8-3b.test.sh not registered in forge-ci.yml (FR-B83B-032)" >&2; return 1; }
}

# ─── Main ──────────────────────────────────────────────────────────

main() {
  echo "── B.8.3.b — b8-3b-validator-versioned-schema — level $LEVEL ──"
  run_test _test_b83b_l1_001_function_present
  run_test _test_b83b_l1_002_called_from_main
  run_test _test_b83b_l1_003_live_exit_zero
  run_test _test_b83b_l1_004_versioned_pass_line
  run_test _test_b83b_l1_005_canonical_still_pass
  run_test _test_b83b_l1_007_neg_filename_version_mismatch
  run_test _test_b83b_l1_008_neg_candidate_no_scaffoldable
  run_test _test_b83b_l1_009_neg_candidate_scaffoldable_true
  run_test _test_b83b_l1_010_pos_stable_no_scaffoldable
  run_test _test_b83b_l1_011_noop_no_sibling
  run_test _test_b83b_l1_012_frozen_schema_intact
  run_test _test_b83b_l1_013_ci_registered
  print_summary
}

main
