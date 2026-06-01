#!/usr/bin/env bash
# Forge — B.8 orchestration-temporal-realign harness
# <!-- Audit: B.8.5 follow-on (b8-orchestration-temporal-realign) — orchestration default reconciled with Constitution §VIII.2 -->
#
# Validates the b8-orchestration-temporal-realign deliverables (design.md § Test Strategy):
#
#   T-001  orchestration.yaml is version 1.2.0                                   (FR-B8O-003)
#   T-002  default_by_language.rust == temporal (the real Rust default)          (FR-B8O-001)
#   T-003  dbos: block = future-option + available:false (watch-list, not default)(FR-B8O-002/006)
#   T-004  flat top-level `default:` key DROPPED; forbidden:[inngest] kept        (FR-B8O-008)
#   T-005  REVIEW.md has the '| orchestration.yaml | 1.2.0 |' ledger row         (FR-B8O-005)
#   T-006  2.0.0.yaml dbos-embedded status == future-option                       (FR-B8O-010)
#   T-007  2.0.0.yaml temporal-intent->dbos-embedded delta cancelled: true        (FR-B8O-011)
#   T-008  temporal.md realigned: NO old symbols, HAS temporalio + alpha caveat   (FR-B8O-020/021)
#   T-009  anti-hallucination: NO concrete temporalio-* version in orchestration  (NFR-B8O-002)
#   T-010  coupling guard: b8-3 (17) + b8-3b (12) + b8-5 (repurposed) stay GREEN  (FR-B8O-014/017)
#
# 10 L1 tests. Budget L1 ≤ 5 s, zero net/Docker. The live temporalio-sdk
# verify-then-pin is a /forge:implement step (evidence.md §1/§2), NOT an L1
# assertion. T-010 is exit-code only (b8-4/b8-5 strategy). Mirrors
# b8-5.test.sh / b8-3.test.sh structure (--level flag + _helpers.sh).

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
FORGE_ROOT="$(cd "$SCRIPTS_DIR/../.." && pwd)"

STANDARDS_DIR="$FORGE_ROOT/.forge/standards"
ORCH_STD="$STANDARDS_DIR/orchestration.yaml"
REVIEW_MD="$STANDARDS_DIR/REVIEW.md"
TEMPORAL_MD="$STANDARDS_DIR/infra/temporal.md"
SCHEMA_20="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/2.0.0.yaml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b8o_l1_001_orch_version_1_2_0() {
  grep -qE '^version:[[:space:]]*"1\.2\.0"' "$ORCH_STD" \
    || { echo "    FAIL T-001: orchestration.yaml is not version \"1.2.0\" (FR-B8O-003)" >&2; return 1; }
}

_test_b8o_l1_002_default_by_language_rust_temporal() {
  local out
  out=$(python3 - "$ORCH_STD" <<'PY'
import sys, yaml
try:
    with open(sys.argv[1], encoding='utf-8') as f:
        d = yaml.safe_load(f)
except Exception as e:
    print(f"ERR:{e}"); sys.exit(0)
dbl = (d or {}).get('default_by_language', {}) if isinstance(d, dict) else {}
print(f"rust={dbl.get('rust','MISSING')}" if isinstance(dbl, dict) else "NO_MAP")
PY
)
  case "$out" in
    rust=temporal) ;;
    ERR:*) echo "    FAIL T-002: orchestration.yaml parse error — ${out#ERR:} (FR-B8O-001)" >&2; return 1 ;;
    *) echo "    FAIL T-002: default_by_language.rust != temporal ($out) (FR-B8O-001)" >&2; return 1 ;;
  esac
}

_test_b8o_l1_003_dbos_future_option() {
  local out
  out=$(python3 - "$ORCH_STD" <<'PY'
import sys, yaml
try:
    with open(sys.argv[1], encoding='utf-8') as f:
        d = yaml.safe_load(f)
except Exception as e:
    print(f"ERR:{e}"); sys.exit(0)
dbos = (d or {}).get('dbos', {}) if isinstance(d, dict) else {}
if not isinstance(dbos, dict):
    print("NO_DBOS"); sys.exit(0)
print(f"status={dbos.get('status','MISSING')};available={dbos.get('available','MISSING')}")
PY
)
  case "$out" in
    status=future-option*available=False|status=future-option*available=false) ;;
    ERR:*) echo "    FAIL T-003: parse error — ${out#ERR:} (FR-B8O-002)" >&2; return 1 ;;
    *) echo "    FAIL T-003: dbos block not {status: future-option, available: false} ($out) (FR-B8O-002/006)" >&2; return 1 ;;
  esac
}

_test_b8o_l1_004_flat_default_dropped() {
  local ok=1
  if grep -qE '^default:[[:space:]]' "$ORCH_STD"; then
    echo "    FAIL T-004: flat top-level 'default:' key still present — must be dropped for default_by_language (FR-B8O-008)" >&2; ok=0
  fi
  grep -qE '^[[:space:]]*-[[:space:]]*inngest' "$ORCH_STD" \
    || { echo "    FAIL T-004: forbidden:[inngest] no longer present (must stay) (FR-B8O-008)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b8o_l1_005_review_row_1_2_0() {
  grep -qE '\|[[:space:]]*orchestration\.yaml[[:space:]]*\|[[:space:]]*1\.2\.0[[:space:]]*\|' "$REVIEW_MD" \
    || { echo "    FAIL T-005: REVIEW.md has no '| orchestration.yaml | 1.2.0 |' ledger row (FR-B8O-005, FR-J7-023)" >&2; return 1; }
}

_test_b8o_l1_006_dbos_embedded_future_option() {
  local out
  out=$(python3 - "$SCHEMA_20" <<'PY'
import sys, yaml
try:
    with open(sys.argv[1], encoding='utf-8') as f:
        d = yaml.safe_load(f)
except Exception as e:
    print(f"ERR:{e}"); sys.exit(0)
comps = d.get('components', []) if isinstance(d, dict) else []
c = next((c for c in comps if isinstance(c, dict) and c.get('name') == 'dbos-embedded'), None)
print("NO_DBOS" if c is None else f"status={c.get('status','MISSING')}")
PY
)
  case "$out" in
    status=future-option) ;;
    ERR:*) echo "    FAIL T-006: 2.0.0.yaml parse error — ${out#ERR:} (FR-B8O-010)" >&2; return 1 ;;
    NO_DBOS) echo "    FAIL T-006: no dbos-embedded component in 2.0.0.yaml (FR-B8O-010)" >&2; return 1 ;;
    *) echo "    FAIL T-006: dbos-embedded $out != status=future-option (FR-B8O-010)" >&2; return 1 ;;
  esac
}

_test_b8o_l1_007_delta_cancelled() {
  local out
  out=$(python3 - "$SCHEMA_20" <<'PY'
import sys, yaml
try:
    with open(sys.argv[1], encoding='utf-8') as f:
        d = yaml.safe_load(f)
except Exception as e:
    print(f"ERR:{e}"); sys.exit(0)
deltas = d.get('migration_deltas', []) if isinstance(d, dict) else []
tdb = next((x for x in deltas if isinstance(x, dict) and x.get('to') == 'dbos-embedded'), None)
if tdb is None:
    print("NO_DELTA"); sys.exit(0)
print(f"cancelled={tdb.get('cancelled','MISSING')}")
PY
)
  case "$out" in
    cancelled=True|cancelled=true) ;;
    ERR:*) echo "    FAIL T-007: parse error — ${out#ERR:} (FR-B8O-011)" >&2; return 1 ;;
    NO_DELTA) echo "    FAIL T-007: temporal-intent->dbos-embedded delta missing (FR-B8O-011)" >&2; return 1 ;;
    *) echo "    FAIL T-007: temporal->dbos delta not marked cancelled: true ($out) (FR-B8O-011)" >&2; return 1 ;;
  esac
}

_test_b8o_l1_008_temporal_md_realigned() {
  local ok=1
  # OLD fabricated symbols MUST be gone (evidence.md §2).
  if grep -qE 'temporal_sdk::|temporal_client|WfContext|ActContext' "$TEMPORAL_MD"; then
    echo "    FAIL T-008: temporal.md still carries OLD symbols (temporal_sdk::/temporal_client/WfContext/ActContext) (FR-B8O-020)" >&2
    grep -nE 'temporal_sdk::|temporal_client|WfContext|ActContext' "$TEMPORAL_MD" | head -3 >&2; ok=0
  fi
  # Real published API references MUST be present (attribute macros are correct).
  grep -qE 'temporalio' "$TEMPORAL_MD" \
    || { echo "    FAIL T-008: temporal.md does not reference the real crate family 'temporalio' (FR-B8O-020)" >&2; ok=0; }
  grep -qE 'WorkflowContext|ActivityContext' "$TEMPORAL_MD" \
    || { echo "    FAIL T-008: temporal.md missing WorkflowContext/ActivityContext (real 0.4.0 API) (FR-B8O-020)" >&2; ok=0; }
  # Alpha / unstable stability caveat MUST be present.
  grep -qiE 'public preview|alpha|unstable|will continue to evolve|evolve|may change' "$TEMPORAL_MD" \
    || { echo "    FAIL T-008: temporal.md missing the Public-Preview/unstable stability caveat (FR-B8O-021)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b8o_l1_009_no_fabricated_version() {
  # Standards record the crate FAMILY only — NO concrete temporalio-* version may be
  # pinned in orchestration.yaml OR temporal.md (verify-then-pin lives in the consuming
  # Cargo.toml; evidence.md §1). Scans BOTH files (round-1 review CRITICAL-2: the
  # orchestration.yaml-only scan was a false-green for temporal.md pins).
  local ok=1 f re='temporalio[-_a-z]*[[:space:]]*=[[:space:]]*"?[0-9]+\.[0-9]+'
  for f in "$ORCH_STD" "$TEMPORAL_MD"; do
    if grep -qE "$re" "$f"; then
      echo "    FAIL T-009: concrete temporalio-* version pin in $(basename "$f") (NFR-B8O-002 — family only)" >&2
      grep -nE "$re" "$f" | head -3 >&2; ok=0
    fi
  done
  [ "$ok" = "1" ]
}

_test_b8o_l1_010_sibling_harness_coupling() {
  # Exit-code-only coupling guard (b8-4/b8-5 strategy). The standard + schema flip
  # must keep the coupled harnesses GREEN: b8-3 (17), b8-3b (12), b8-5 (repurposed
  # T-006 + T-010). Budget-safe: each is a fast L1 grep/parse harness.
  local ok=1 t
  for t in b8-3 b8-3b b8-5; do
    if ! bash "$HARNESS_DIR/$t.test.sh" --level 1 >/dev/null 2>&1; then
      echo "    FAIL T-010: coupled harness $t.test.sh is RED after the realign (FR-B8O-014/017)" >&2; ok=0
    fi
  done
  [ "$ok" = "1" ]
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.8 orchestration-temporal-realign — b8o — level $LEVEL ──"
  run_test _test_b8o_l1_001_orch_version_1_2_0
  run_test _test_b8o_l1_002_default_by_language_rust_temporal
  run_test _test_b8o_l1_003_dbos_future_option
  run_test _test_b8o_l1_004_flat_default_dropped
  run_test _test_b8o_l1_005_review_row_1_2_0
  run_test _test_b8o_l1_006_dbos_embedded_future_option
  run_test _test_b8o_l1_007_delta_cancelled
  run_test _test_b8o_l1_008_temporal_md_realigned
  run_test _test_b8o_l1_009_no_fabricated_version
  run_test _test_b8o_l1_010_sibling_harness_coupling
  print_summary
}

main
