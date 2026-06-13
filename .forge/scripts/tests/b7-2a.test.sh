#!/usr/bin/env bash
# Forge — B.7.2a ai-native-rag dispatch registration harness
# <!-- Audit: B.7.2 (b7-2a-dispatch-register) — dispatch entry + refusing wrapper gate -->
#
# Validates the b7-2a-dispatch-register deliverables (resolves b7-1-schema Q-005):
#
#   T-001  dispatch-table.yml has a well-formed ai-native-rag entry (FR-B7-2A-001)
#   T-002  bin/forge-init-ai-native-rag.sh exists, executable, bash shebang (FR-B7-2A-002)
#   T-003  direct wrapper invocation ⇒ exit 3 + [REFUSAL ...] stderr + zero writes (FR-B7-2A-002/003)
#   T-L2-001 (opt-in) forge init --archetype ai-native-rag ⇒ exit 3 (FR-B7-2A-003 ;
#            FORGE_B7_2A_LIVE=1 + built CLI; skip-pass otherwise)
#
# 3 L1 + 1 L2. Performance budget: L1 ≤ 3 s, zero net/Docker.

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

DISPATCH="$FORGE_ROOT/.forge/scaffolding/dispatch-table.yml"
WRAPPER="$FORGE_ROOT/bin/forge-init-ai-native-rag.sh"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── L1 ───────────────────────────────────────────────────────────────────────

_test_b72a_l1_001_dispatch_entry() {
  python3 - "$DISPATCH" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
e = (d.get("archetypes") or {}).get("ai-native-rag")
errs = []
if e is None:
    print("    FAIL T-001: no 'ai-native-rag' entry in dispatch-table.yml (FR-B7-2A-001)", file=sys.stderr)
    sys.exit(1)
if e.get("name") != "ai-native-rag":
    errs.append(f"name={e.get('name')!r} != 'ai-native-rag'")
if e.get("scaffolder") != "bin/forge-init-ai-native-rag.sh":
    errs.append(f"scaffolder={e.get('scaffolder')!r} != 'bin/forge-init-ai-native-rag.sh'")
if not (isinstance(e.get("description"), str) and e.get("description").strip()):
    errs.append("description missing/empty")
if not isinstance(e.get("signals"), list):
    errs.append(f"signals not a list (got {type(e.get('signals')).__name__})")
if e.get("since") != "0.5.0":
    errs.append(f"since={e.get('since')!r} != '0.5.0' (ADR-B7-2A-004)")
if e.get("status") != "candidate":
    errs.append(f"status={e.get('status')!r} != 'candidate' (ADR-B7-2A-005)")
if errs:
    for x in errs: print(f"    FAIL T-001: {x}", file=sys.stderr)
    sys.exit(1)
PY
}

_test_b72a_l1_002_wrapper_exists_executable() {
  if [ ! -f "$WRAPPER" ]; then echo "    FAIL T-002: wrapper missing: $WRAPPER (FR-B7-2A-002)" >&2; return 1; fi
  if [ ! -x "$WRAPPER" ]; then echo "    FAIL T-002: wrapper not executable: $WRAPPER" >&2; return 1; fi
  head -1 "$WRAPPER" | grep -qE '^#!.*\bbash\b' || { echo "    FAIL T-002: wrapper missing bash shebang" >&2; return 1; }
}

_test_b72a_l1_003_wrapper_refuses_no_writes() {
  [ -x "$WRAPPER" ] || { echo "    FAIL T-003: wrapper not runnable (covered by T-002)" >&2; return 1; }
  local tmp; tmp=$(mk_tmpdir_with_trap b7-2a-wrap)
  trap "rm -rf '$tmp'" RETURN
  local err rc
  err=$( cd "$tmp" && "$WRAPPER" testproj --org com.example.test 2>&1 1>/dev/null ); rc=$?
  if [ "$rc" != "3" ]; then
    echo "    FAIL T-003: wrapper exit=$rc != 3 (ADR-B7-2A-002)" >&2; return 1
  fi
  printf '%s' "$err" | grep -qiE '\[REFUSAL' || { echo "    FAIL T-003: wrapper stderr lacks [REFUSAL ...] (ADR-B7-2A-003); got: $err" >&2; return 1; }
  # zero writes: tmpdir must still be empty
  if [ -n "$(ls -A "$tmp" 2>/dev/null)" ]; then
    echo "    FAIL T-003: wrapper wrote files into the target dir (must be a no-op refusal): $(ls -A "$tmp")" >&2; return 1
  fi
}

# ─── L2 (opt-in live) ─────────────────────────────────────────────────────────

_test_b72a_l2_001_cli_refuses_exit3() {
  # Registered + candidate/scaffoldable:false ⇒ resolveScaffolder refuse ⇒ exit 3.
  # Requires the dispatch entry + schema bundled into cli/assets (npm run bundle).
  local cli="$FORGE_ROOT/cli/dist/index.js"
  if [ "${FORGE_B7_2A_LIVE:-0}" != "1" ] || [ ! -f "$cli" ]; then
    echo "    SKIP T-L2-001: set FORGE_B7_2A_LIVE=1 with a built+bundled CLI (cli/dist/index.js) to run the live exit-3 check" >&2
    return 0
  fi
  local tmp; tmp=$(mk_tmpdir_with_trap b7-2a-init)
  trap "rm -rf '$tmp'" RETURN
  ( cd "$tmp" && node "$cli" init testproj --archetype ai-native-rag --org com.example.test >/dev/null 2>&1 )
  local rc=$?
  if [ "$rc" != "3" ]; then
    echo "    FAIL T-L2-001: forge init --archetype ai-native-rag exit=$rc != 3 (registered, not scaffoldable)" >&2; return 1
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.7.2a — b7-2a-dispatch-register — level $LEVEL ──"
  run_test _test_b72a_l1_001_dispatch_entry
  run_test _test_b72a_l1_002_wrapper_exists_executable
  run_test _test_b72a_l1_003_wrapper_refuses_no_writes
  case "$LEVEL" in
    *2*) run_test _test_b72a_l2_001_cli_refuses_exit3 ;;
  esac
  print_summary
}

main
