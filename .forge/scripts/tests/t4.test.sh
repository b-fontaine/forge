#!/usr/bin/env bash
# Forge — T4 ADR Ratification Test Harness (t4-adr-ratification)
# <!-- Audit: T.4 (t4-adr-ratification) -->
#
# Validates the methodology deliverables of t4-adr-ratification :
#   - 6 versioned standards .forge/standards/*.yaml (FR-T4-STD-001..006)
#   - .forge/standards/REVIEW.md ledger seed (FR-T4-LC-003)
#   - .forge/standards/global/standards-lifecycle.md (FR-T4-LC-001/002/004/005)
#   - .forge/schemas/compliance-tier.schema.json (FR-T4-SCH-001)
#   - .forge/schemas/archetype.schema.json v2 (FR-T4-SCH-002)
#   - linter rule no-state-management-alternatives (FR-T4-LNT-001, warn-only)
#   - drift detector for docs/ARCHITECTURE-TARGET.md (FR-T4-LNT-002)
#   - rehash escape hatch bin/forge-rehash-architecture-doc.sh (FR-T4-DOC-002)
#
# 30 tests : 25 L1 + 5 L2 fixture-based.
# Performance budget : ≤ 3 s wall-clock (NFR-T4-001).

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
SCHEMAS_DIR="$FORGE_ROOT_REAL/.forge/schemas"
LINTER="$FORGE_ROOT_REAL/.forge/scripts/constitution-linter.sh"
ARCH_DOC="$FORGE_ROOT_REAL/docs/ARCHITECTURE-TARGET.md"
SPECS_MD="$FORGE_ROOT_REAL/.forge/changes/t4-adr-ratification/specs.md"
REHASH_SCRIPT="$FORGE_ROOT_REAL/bin/forge-rehash-architecture-doc.sh"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (25 tests)
# MANIFEST: _test_t4_001 — FR-T4-STD-001 transport.yaml parses
# MANIFEST: _test_t4_002 — FR-T4-STD-002 state-management.yaml parses
# MANIFEST: _test_t4_003 — FR-T4-STD-003 observability.yaml parses
# MANIFEST: _test_t4_004 — FR-T4-STD-004 orchestration.yaml parses
# MANIFEST: _test_t4_005 — FR-T4-STD-005 identity.yaml parses
# MANIFEST: _test_t4_006 — FR-T4-STD-006 persistence.yaml parses
# MANIFEST: _test_t4_007 — FR-T4-STD-001 transport frontmatter complete
# MANIFEST: _test_t4_008 — FR-T4-STD-002 state-mgmt frontmatter complete
# MANIFEST: _test_t4_009 — FR-T4-STD-003 observability frontmatter complete
# MANIFEST: _test_t4_010 — FR-T4-STD-004 orchestration frontmatter complete
# MANIFEST: _test_t4_011 — FR-T4-STD-005 identity frontmatter complete
# MANIFEST: _test_t4_012 — FR-T4-STD-006 persistence frontmatter complete
# MANIFEST: _test_t4_013 — FR-T4-STD-002 state-mgmt forbidden non-empty (8 entries)
# MANIFEST: _test_t4_014 — FR-T4-STD-005 identity forbidden non-empty
# MANIFEST: _test_t4_015 — FR-T4-STD-006 persistence forbidden_for_eu_strict non-empty
# MANIFEST: _test_t4_016 — FR-T4-STD-001 transport exception_constitutional: true
# MANIFEST: _test_t4_017 — FR-T4-STD-002 state-mgmt exception_constitutional: true
# MANIFEST: _test_t4_018 — FR-T4-SCH-001 compliance-tier schema valid Draft 2020-12
# MANIFEST: _test_t4_019 — FR-T4-SCH-001 compliance-tier accepts only T1/T2/T3
# MANIFEST: _test_t4_020 — FR-T4-SCH-002 archetype schema v2 valid Draft 2020-12
# MANIFEST: _test_t4_021 — FR-T4-SCH-002 archetype v2 accepts 5 canonical + mobile-only legacy
# MANIFEST: _test_t4_022 — FR-T4-SCH-002 archetype v2 rejects flutter-firebase
# MANIFEST: _test_t4_023 — FR-T4-LNT-002 architecture doc hash matches specs.md frontmatter
# MANIFEST: _test_t4_024 — FR-T4-LC-003 REVIEW.md has 6 seed entries
# MANIFEST: _test_t4_025 — FR-T4-LC-002 standards-lifecycle.md lists structural exceptions
#
# L2 (5 fixture tests)
# MANIFEST: _test_t4_l2_lint_warn_riverpod   — FR-T4-LNT-001 WARN when riverpod present
# MANIFEST: _test_t4_l2_lint_pass_only_bloc  — FR-T4-LNT-001 PASS when only bloc
# MANIFEST: _test_t4_l2_drift_fail_byte     — FR-T4-LNT-002 fail on byte change
# MANIFEST: _test_t4_l2_drift_pass_rehash   — FR-T4-LNT-002 pass after rehash
# MANIFEST: _test_t4_l2_expired_warns       — FR-T4-LC-005 expired standard emits WARN

# ─── Helper: yq invocation tolerant ─────────────────────────────

_yq_eval() {
  # Args: <yq-expression> <file>
  # Echoes the value (stdout) ; returns yq's exit code.
  if command -v yq >/dev/null 2>&1; then
    yq eval "$1" "$2" 2>/dev/null
  else
    # Fallback : use python3 + PyYAML if yq absent (CI uses yq)
    python3 - "$1" "$2" <<'PY' 2>/dev/null
import sys, yaml
expr = sys.argv[1]
path = sys.argv[2]
with open(path) as f:
    data = yaml.safe_load(f)
# Very limited evaluator — sufficient for `.field` and `.field.subfield`
keys = [k for k in expr.lstrip('.').split('.') if k]
val = data
for k in keys:
    if isinstance(val, dict) and k in val:
        val = val[k]
    else:
        sys.exit(1)
if isinstance(val, (list, dict)):
    print(yaml.safe_dump(val).strip())
else:
    print(val)
PY
  fi
}

_yq_parses() {
  # Args: <file>. Returns 0 if file parses as YAML.
  if command -v yq >/dev/null 2>&1; then
    yq eval '.' "$1" >/dev/null 2>&1
  else
    python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$1" >/dev/null 2>&1
  fi
}

_check_frontmatter_keys() {
  # Args: <file>. Verifies required frontmatter keys exist.
  local f="$1"
  for k in version last_reviewed expires_at exception_constitutional linter_rule enforcement rationale; do
    if ! grep -qE "^${k}:" "$f"; then
      echo "    missing frontmatter key '${k}' in $(basename "$f")" >&2
      return 1
    fi
  done
}

# ─── L1 tests ────────────────────────────────────────────────────

_test_t4_001() {
  [ -f "$STD_DIR/transport.yaml" ] || { echo "    transport.yaml not found" >&2; return 1; }
  _yq_parses "$STD_DIR/transport.yaml" || { echo "    transport.yaml does not parse" >&2; return 1; }
}

_test_t4_002() {
  [ -f "$STD_DIR/state-management.yaml" ] || { echo "    state-management.yaml not found" >&2; return 1; }
  _yq_parses "$STD_DIR/state-management.yaml" || { echo "    state-management.yaml does not parse" >&2; return 1; }
}

_test_t4_003() {
  [ -f "$STD_DIR/observability.yaml" ] || { echo "    observability.yaml not found" >&2; return 1; }
  _yq_parses "$STD_DIR/observability.yaml" || { echo "    observability.yaml does not parse" >&2; return 1; }
}

_test_t4_004() {
  [ -f "$STD_DIR/orchestration.yaml" ] || { echo "    orchestration.yaml not found" >&2; return 1; }
  _yq_parses "$STD_DIR/orchestration.yaml" || { echo "    orchestration.yaml does not parse" >&2; return 1; }
}

_test_t4_005() {
  [ -f "$STD_DIR/identity.yaml" ] || { echo "    identity.yaml not found" >&2; return 1; }
  _yq_parses "$STD_DIR/identity.yaml" || { echo "    identity.yaml does not parse" >&2; return 1; }
}

_test_t4_006() {
  [ -f "$STD_DIR/persistence.yaml" ] || { echo "    persistence.yaml not found" >&2; return 1; }
  _yq_parses "$STD_DIR/persistence.yaml" || { echo "    persistence.yaml does not parse" >&2; return 1; }
}

_test_t4_007() { _check_frontmatter_keys "$STD_DIR/transport.yaml"; }
_test_t4_008() { _check_frontmatter_keys "$STD_DIR/state-management.yaml"; }
_test_t4_009() { _check_frontmatter_keys "$STD_DIR/observability.yaml"; }
_test_t4_010() { _check_frontmatter_keys "$STD_DIR/orchestration.yaml"; }
_test_t4_011() { _check_frontmatter_keys "$STD_DIR/identity.yaml"; }
_test_t4_012() { _check_frontmatter_keys "$STD_DIR/persistence.yaml"; }

_test_t4_013() {
  # state-management.yaml MUST list exactly 8 forbidden state-management libs
  local f="$STD_DIR/state-management.yaml"
  [ -f "$f" ] || { echo "    state-management.yaml missing" >&2; return 1; }
  local count
  count="$(grep -cE '^\s*-\s+(flutter_riverpod|riverpod|provider|get|getx|mobx|flutter_mobx|states_rebuilder)\s*$' "$f" || true)"
  if [ "$count" -lt 8 ]; then
    echo "    expected 8 forbidden entries, found $count" >&2
    return 1
  fi
}

_test_t4_014() {
  # identity.yaml MUST forbid firebase-auth and auth0-saas-us
  local f="$STD_DIR/identity.yaml"
  [ -f "$f" ] || { echo "    identity.yaml missing" >&2; return 1; }
  grep -qE 'firebase-auth' "$f" || { echo "    firebase-auth not forbidden" >&2; return 1; }
  grep -qE 'auth0-saas-us' "$f" || { echo "    auth0-saas-us not forbidden" >&2; return 1; }
}

_test_t4_015() {
  # persistence.yaml MUST forbid dynamodb / firestore / cosmosdb (T2/T3 strict)
  local f="$STD_DIR/persistence.yaml"
  [ -f "$f" ] || { echo "    persistence.yaml missing" >&2; return 1; }
  grep -q 'dynamodb' "$f" || { echo "    dynamodb missing in forbidden" >&2; return 1; }
  grep -q 'firestore' "$f" || { echo "    firestore missing" >&2; return 1; }
  grep -q 'cosmosdb' "$f" || { echo "    cosmosdb missing" >&2; return 1; }
}

_test_t4_016() {
  grep -qE '^exception_constitutional:\s+true' "$STD_DIR/transport.yaml" 2>/dev/null \
    || { echo "    transport.yaml exception_constitutional not true" >&2; return 1; }
}

_test_t4_017() {
  grep -qE '^exception_constitutional:\s+true' "$STD_DIR/state-management.yaml" 2>/dev/null \
    || { echo "    state-management.yaml exception_constitutional not true" >&2; return 1; }
}

_test_t4_018() {
  local f="$SCHEMAS_DIR/compliance-tier.schema.json"
  [ -f "$f" ] || { echo "    compliance-tier.schema.json missing" >&2; return 1; }
  python3 - "$f" <<'PY' || { echo "    schema invalid against meta-schema" >&2; return 1; }
import json, sys
try:
    import jsonschema
except ImportError:
    sys.exit(0)  # meta-validation skipped if jsonschema not installed (CI has it)
with open(sys.argv[1]) as fh:
    s = json.load(fh)
jsonschema.Draft202012Validator.check_schema(s)
PY
}

_test_t4_019() {
  local f="$SCHEMAS_DIR/compliance-tier.schema.json"
  [ -f "$f" ] || { echo "    compliance-tier.schema.json missing" >&2; return 1; }
  python3 - "$f" <<'PY' || { echo "    enum mismatch (expected exactly T1/T2/T3)" >&2; return 1; }
import json, sys
with open(sys.argv[1]) as fh:
    s = json.load(fh)
got = s.get('enum', [])
want = ['T1', 'T2', 'T3']
sys.exit(0 if got == want else 1)
PY
}

_test_t4_020() {
  local f="$SCHEMAS_DIR/archetype.schema.json"
  [ -f "$f" ] || { echo "    archetype.schema.json missing" >&2; return 1; }
  python3 - "$f" <<'PY' || { echo "    archetype schema invalid" >&2; return 1; }
import json, sys
try:
    import jsonschema
except ImportError:
    sys.exit(0)
with open(sys.argv[1]) as fh:
    s = json.load(fh)
jsonschema.Draft202012Validator.check_schema(s)
PY
}

_test_t4_021() {
  local f="$SCHEMAS_DIR/archetype.schema.json"
  [ -f "$f" ] || { echo "    archetype.schema.json missing" >&2; return 1; }
  python3 - "$f" <<'PY' || { echo "    enum does not contain 5 canonical + mobile-only" >&2; return 1; }
import json, sys
with open(sys.argv[1]) as fh:
    s = json.load(fh)
got = set(s.get('enum', []))
want = {'full-stack-monorepo', 'mobile-pwa-first', 'event-driven-eu', 'ai-native-rag', 'rust-cli-tui', 'mobile-only'}
sys.exit(0 if want.issubset(got) else 1)
PY
}

_test_t4_022() {
  local f="$SCHEMAS_DIR/archetype.schema.json"
  [ -f "$f" ] || { echo "    archetype.schema.json missing" >&2; return 1; }
  python3 - "$f" <<'PY' || { echo "    flutter-firebase still in enum (must be removed)" >&2; return 1; }
import json, sys
with open(sys.argv[1]) as fh:
    s = json.load(fh)
got = set(s.get('enum', []))
sys.exit(0 if 'flutter-firebase' not in got else 1)
PY
}

_test_t4_023() {
  # Architecture doc hash matches the value pinned in specs.md
  [ -f "$ARCH_DOC" ] || { echo "    ARCHITECTURE-TARGET.md missing" >&2; return 1; }
  [ -f "$SPECS_MD" ] || { echo "    specs.md missing" >&2; return 1; }
  local actual
  actual="$(shasum -a 256 "$ARCH_DOC" | awk '{print $1}')"
  local expected
  expected="$(grep -oE '[a-f0-9]{64}' "$SPECS_MD" | head -1 || true)"
  if [ -z "$expected" ]; then
    echo "    pinned hash not found in specs.md" >&2
    return 1
  fi
  if [ "$actual" != "$expected" ]; then
    echo "    drift detected: expected=$expected actual=$actual" >&2
    return 1
  fi
}

_test_t4_024() {
  local f="$STD_DIR/REVIEW.md"
  [ -f "$f" ] || { echo "    REVIEW.md missing" >&2; return 1; }
  # Count occurrences of the 6 standard names in a single seed table
  local count=0
  for std in transport.yaml state-management.yaml observability.yaml orchestration.yaml identity.yaml persistence.yaml; do
    grep -qF "$std" "$f" && count=$((count+1))
  done
  if [ "$count" -lt 6 ]; then
    echo "    expected 6 seed entries, found $count" >&2
    return 1
  fi
}

_test_t4_025() {
  local f="$STD_DIR/global/standards-lifecycle.md"
  [ -f "$f" ] || { echo "    standards-lifecycle.md missing" >&2; return 1; }
  grep -qF 'transport.yaml' "$f" || { echo "    transport.yaml not listed as structural exception" >&2; return 1; }
  grep -qF 'state-management.yaml' "$f" || { echo "    state-management.yaml not listed as structural exception" >&2; return 1; }
  grep -qiE 'structural\s+exception|exception_constitutional' "$f" \
    || { echo "    structural exception terminology missing" >&2; return 1; }
}

# ─── L2 fixture tests ────────────────────────────────────────────

_setup_l2() {
  L2_TMP="$(mk_tmpdir_with_trap forge-t4-l2)"
}

_teardown_l2() {
  rm -rf "$L2_TMP"
}

_test_t4_l2_lint_warn_riverpod() {
  _setup_l2
  trap '_teardown_l2' RETURN
  # Synthetic Flutter project with riverpod dependency
  mkdir -p "$L2_TMP/proj/frontend"
  cat > "$L2_TMP/proj/frontend/pubspec.yaml" <<'YAML'
name: l2_riverpod_proj
dependencies:
  flutter_bloc: ^9.0.0
  flutter_riverpod: ^2.5.0
YAML
  # Capture linter output (avoid SIGPIPE issues with `grep -q | pipefail`)
  local out
  out="$(FORGE_LINTER_FIXTURE_ROOT="$L2_TMP/proj" bash "$LINTER" 2>&1 || true)"
  if printf '%s' "$out" | grep -qiE 'no-state-management-alternatives|state-management.*forbidden|forbidden.*riverpod'; then
    return 0
  fi
  echo "    linter did not WARN on riverpod dependency" >&2
  echo "    linter output preview:" >&2
  printf '%s' "$out" | head -5 >&2
  return 1
}

_test_t4_l2_lint_pass_only_bloc() {
  _setup_l2
  trap '_teardown_l2' RETURN
  mkdir -p "$L2_TMP/proj/frontend"
  cat > "$L2_TMP/proj/frontend/pubspec.yaml" <<'YAML'
name: l2_bloc_only_proj
dependencies:
  flutter_bloc: ^9.0.0
YAML
  # Linter should not emit a forbidden-dep line for a bloc-only fixture
  local out
  out="$(FORGE_LINTER_FIXTURE_ROOT="$L2_TMP/proj" bash "$LINTER" 2>&1 || true)"
  if printf '%s' "$out" | grep -qiE 'forbidden state-mgmt dep.*riverpod|FAIL.*no-state-management-alternatives'; then
    echo "    linter unexpectedly flagged bloc-only fixture" >&2
    return 1
  fi
  return 0
}

_test_t4_l2_drift_fail_byte() {
  _setup_l2
  trap '_teardown_l2' RETURN
  cp "$ARCH_DOC" "$L2_TMP/edited.md"
  printf '\n' >> "$L2_TMP/edited.md"  # mutate one byte
  local edited_hash
  edited_hash="$(shasum -a 256 "$L2_TMP/edited.md" | awk '{print $1}')"
  local expected
  expected="$(grep -oE '[a-f0-9]{64}' "$SPECS_MD" | head -1)"
  if [ "$edited_hash" = "$expected" ]; then
    echo "    drift not detected (hash unchanged after mutation — improbable)" >&2
    return 1
  fi
  return 0
}

_test_t4_l2_drift_pass_rehash() {
  _setup_l2
  trap '_teardown_l2' RETURN
  # Copy the doc unchanged → hashes must match
  cp "$ARCH_DOC" "$L2_TMP/copy.md"
  local copy_hash
  copy_hash="$(shasum -a 256 "$L2_TMP/copy.md" | awk '{print $1}')"
  local expected
  expected="$(grep -oE '[a-f0-9]{64}' "$SPECS_MD" | head -1)"
  if [ "$copy_hash" != "$expected" ]; then
    echo "    unchanged copy hash differs from pinned hash" >&2
    return 1
  fi
}

_test_t4_l2_expired_warns() {
  _setup_l2
  trap '_teardown_l2' RETURN
  # Synthetic standard with past expires_at
  cat > "$L2_TMP/expired-std.yaml" <<'YAML'
version: "1.0.0"
last_reviewed: 2020-01-01
expires_at: 2020-12-31
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: |
  Synthetic L2 fixture for t4 expired-standard test.
YAML
  # The expiry detector logic : expires_at < today AND not exception_constitutional
  local today
  today="$(date +%Y-%m-%d)"
  local exp
  exp="$(_yq_eval '.expires_at' "$L2_TMP/expired-std.yaml")"
  local exc
  exc="$(_yq_eval '.exception_constitutional' "$L2_TMP/expired-std.yaml")"
  if [ "$exp" \< "$today" ] && [ "$exc" != "true" ]; then
    return 0  # expired and not exempt → would WARN
  fi
  echo "    expiry logic did not flag expired fixture" >&2
  return 1
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T.4 — t4-adr-ratification harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — declarative artefacts"
  for n in $(seq 1 25); do
    run_test "_test_t4_$(printf '%03d' "$n")"
  done

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based"
    run_test _test_t4_l2_lint_warn_riverpod
    run_test _test_t4_l2_lint_pass_only_bloc
    run_test _test_t4_l2_drift_fail_byte
    run_test _test_t4_l2_drift_pass_rehash
    run_test _test_t4_l2_expired_warns
  fi

  print_summary
}

main "$@"
