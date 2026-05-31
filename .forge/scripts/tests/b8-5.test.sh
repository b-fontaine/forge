#!/usr/bin/env bash
# Forge — B.8.5 Postgres-17 + pgvector 2.0.0 datastore-brick harness
# <!-- Audit: B.8.5 (b8-5-postgres-pgvector) — 2.0.0 datastore template brick gate -->
#
# Validates the b8-5-postgres-pgvector deliverables (design.md § Test Strategy):
#
#   T-001  2.0.0/infra/postgres/ tree has the 3 expected .tmpl files          (FR-B85-051, ADR-B85-001)
#   T-002  compose fragment declares a pgvector/pgvector Postgres-17 image      (FR-B85-011, ADR-B85-003)
#   T-003  init-SQL CREATE EXTENSION ... vector + docker-entrypoint-initdb.d    (FR-B85-012/052, ADR-B85-003)
#   T-004  fragment mirrors 1.0.0 fsm-db shape (pg_isready, named vol, env)     (FR-B85-013, ADR-B85-002)
#   T-005  anti-hallucination image grep-guard (VERIFY_THEN_PIN OR :pg17; no    (NFR-B85-005, FR-B85-030, ADR-B85-003)
#          non-pg17 / postgres:16 literal leaked into the 2.0.0 postgres tree)
#   T-006  orchestration.yaml records DBOS-Rust deferral + default:dbos kept    (FR-B85-054/005, ADR-B85-005/006)
#          AND 2.0.0.yaml dbos-embedded status: deferred
#   T-007  orchestration.yaml passes J.7 DIRECTORY mode + REVIEW.md 1.1.0 row   (FR-B85-054/004, ADR-B85-005)
#   T-008  2.0.0.yaml postgres comp refs persistence.yaml (resolves) + no pin   (FR-B85-053/021, ADR-B85-004)
#   T-009  coupling guard: b8-3 (17/17) + b8-3b (12/12) stay GREEN (exit-code)  (NFR-B85-004, FR-B85-056)
#   T-010  2.0.0.yaml temporal->dbos delta deferred + postgres-16 delta intact  (FR-B85-055/014, ADR-B85-006)
#   T-011  additive — flat 1.0.0 postgres:16-alpine + frozen schema.yaml intact (FR-B85-056, NFR-B85-003)
#   T-012  anti-hallucination: NO dbos crate / Cargo.toml dbos / DBOSContext    (NFR-B85-001, FR-B85-030)
#
# 12 L1 tests. Budget L1 ≤ 5 s, zero net/Docker. The live image verify-then-pin
# is a /forge:implement step, NOT an L1 assertion. T-009 is exit-code only (the
# b8-4 T-012 strategy) — keeps the coupling guard within the ≤ 5 s budget.
# Mirrors b8-4.test.sh / b8-3.test.sh structure (--level flag + _helpers.sh).

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

TEMPLATE_ROOT="$FORGE_ROOT/.forge/templates/archetypes/full-stack-monorepo"
PG_DIR="$TEMPLATE_ROOT/2.0.0/infra/postgres"
FRAGMENT="$PG_DIR/docker-compose.fragment.yml.tmpl"
INIT_SQL="$PG_DIR/init-pgvector.sql.tmpl"
PG_README="$PG_DIR/README.md.tmpl"
FLAT_COMPOSE="$TEMPLATE_ROOT/docker-compose.dev.yml.tmpl"

STANDARDS_DIR="$FORGE_ROOT/.forge/standards"
ORCH_STD="$STANDARDS_DIR/orchestration.yaml"
REVIEW_MD="$STANDARDS_DIR/REVIEW.md"
VALIDATOR="$FORGE_ROOT/bin/validate-standards-yaml.sh"

SCHEMA_20="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/2.0.0.yaml"
SCHEMA_10="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/schema.yaml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b85_l1_001_tree_files() {
  local expected=(docker-compose.fragment.yml.tmpl init-pgvector.sql.tmpl README.md.tmpl)
  local missing=()
  for f in "${expected[@]}"; do
    [ -f "$PG_DIR/$f" ] || missing+=("$f")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    FAIL T-001: missing .tmpl file(s) under $PG_DIR: ${missing[*]} (FR-B85-051, ADR-B85-001)" >&2
    return 1
  fi
}

_test_b85_l1_002_pgvector_image() {
  if [ ! -f "$FRAGMENT" ]; then
    echo "    FAIL T-002: compose fragment missing: $FRAGMENT (FR-B85-011)" >&2
    return 1
  fi
  # The datastore image MUST be from the pgvector/pgvector family (Postgres 17 +
  # pgvector). Accept the VERIFY_THEN_PIN placeholder OR a verified pg17 tag.
  if ! grep -qE '^[[:space:]]*image:[[:space:]]*pgvector/pgvector:' "$FRAGMENT"; then
    echo "    FAIL T-002: fragment has no 'image: pgvector/pgvector:' line (FR-B85-011, ADR-B85-003)" >&2
    return 1
  fi
}

_test_b85_l1_003_init_extension() {
  local ok=1
  if [ ! -f "$INIT_SQL" ]; then
    echo "    FAIL T-003: init SQL missing: $INIT_SQL (FR-B85-012)" >&2; return 1
  fi
  # The init SQL must enable the extension (CREATE EXTENSION ... vector).
  if ! grep -qiE 'CREATE[[:space:]]+EXTENSION' "$INIT_SQL"; then
    echo "    FAIL T-003: init SQL has no CREATE EXTENSION statement (FR-B85-012, FR-B85-052)" >&2; ok=0
  fi
  if ! grep -qF 'vector' "$INIT_SQL"; then
    echo "    FAIL T-003: init SQL does not reference the 'vector' extension (FR-B85-052)" >&2; ok=0
  fi
  # The fragment must mount it into docker-entrypoint-initdb.d (the enable mech).
  if ! grep -qF 'docker-entrypoint-initdb.d' "$FRAGMENT"; then
    echo "    FAIL T-003: fragment does not mount init-SQL into docker-entrypoint-initdb.d (ADR-B85-003)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b85_l1_004_mirrors_fsm_db_shape() {
  local ok=1
  # The 2.0.0 fragment mirrors the frozen 1.0.0 fsm-db shape (the recognizable
  # datastore delta): pg_isready healthcheck + named fsm-db-data volume + the
  # three POSTGRES_* env vars.
  grep -qF 'pg_isready' "$FRAGMENT" \
    || { echo "    FAIL T-004: fragment has no pg_isready healthcheck (FR-B85-013)" >&2; ok=0; }
  grep -qF 'fsm-db-data' "$FRAGMENT" \
    || { echo "    FAIL T-004: fragment has no named fsm-db-data volume (FR-B85-013)" >&2; ok=0; }
  for env in POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD; do
    grep -qF "$env" "$FRAGMENT" \
      || { echo "    FAIL T-004: fragment missing $env env (FR-B85-013, ADR-B85-002)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b85_l1_005_image_anti_hallucination() {
  local ok=1
  # The image is EITHER the VERIFY_THEN_PIN placeholder OR a verified
  # pgvector/pgvector:*-pg17 / :pg17 tag — never an unsourced non-pg17 literal.
  if grep -qE 'image:[[:space:]]*pgvector/pgvector:VERIFY_THEN_PIN' "$FRAGMENT" \
     || grep -qE 'image:[[:space:]]*pgvector/pgvector:[^[:space:]]*pg17' "$FRAGMENT"; then
    :  # ok — placeholder OR a pg17-family tag
  else
    echo "    FAIL T-005: fragment image is neither VERIFY_THEN_PIN nor a pgvector pg17 tag (NFR-B85-005, ADR-B85-003)" >&2; ok=0
  fi
  # No non-pg17 pgvector image literal (e.g. :pg16, :pg18) anywhere in the tree.
  if grep -rqE 'pgvector/pgvector:[^[:space:]]*pg(1[^7]|[2-9])' "$PG_DIR" 2>/dev/null; then
    echo "    FAIL T-005: a non-pg17 pgvector image literal leaked into the 2.0.0 postgres tree (NFR-B85-005)" >&2; ok=0
  fi
  # No Postgres-16 IMAGE declaration leaked into the 2.0.0 tree (the 16→17 delta
  # is the point). Match an `image:`-keyed `postgres:16` line ONLY — the README
  # legitimately documents the 16→17 delta in prose ("postgres:16-alpine"), which
  # must NOT trip this guard. Restrict to the compose fragment's image line.
  if grep -rqE '^[[:space:]]*image:[[:space:]]*postgres:16' "$PG_DIR" 2>/dev/null; then
    echo "    FAIL T-005: a postgres:16 image declaration leaked into the 2.0.0 postgres tree (the 2.0.0 delta is pg17) (NFR-B85-005)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b85_l1_006_dbos_deferral_recorded() {
  local ok=1
  # orchestration.yaml records the DBOS-Rust deferral.
  grep -qF 'rust_sdk_status' "$ORCH_STD" \
    || { echo "    FAIL T-006: orchestration.yaml has no rust_sdk_status block (FR-B85-003, ADR-B85-005)" >&2; ok=0; }
  grep -qE 'available:[[:space:]]*false' "$ORCH_STD" \
    || { echo "    FAIL T-006: orchestration.yaml rust_sdk_status does not record available: false (FR-B85-003)" >&2; ok=0; }
  # default: dbos is UNCHANGED in VALUE (language-conditional aspirational
  # target). The value must remain `dbos`; an optional trailing #comment is
  # permitted (the bump annotates it inline but does not change the value).
  grep -qE '^default:[[:space:]]*dbos[[:space:]]*(#.*)?$' "$ORCH_STD" \
    || { echo "    FAIL T-006: orchestration.yaml 'default: dbos' value was changed (must stay unchanged) (ADR-B85-005)" >&2; ok=0; }
  # 2.0.0.yaml dbos-embedded carries status: deferred.
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
    ERR:*)   echo "    FAIL T-006: 2.0.0.yaml parse error — ${out#ERR:} (FR-B85-005)" >&2; ok=0 ;;
    NO_DBOS) echo "    FAIL T-006: no dbos-embedded component in 2.0.0.yaml (FR-B85-005)" >&2; ok=0 ;;
    status=deferred) ;;
    *) echo "    FAIL T-006: dbos-embedded $out != status=deferred (ADR-B85-006)" >&2; ok=0 ;;
  esac
  [ "$ok" = "1" ]
}

_test_b85_l1_007_orch_j7_dir_mode() {
  local ok=1
  if [ ! -f "$ORCH_STD" ]; then
    echo "    FAIL T-007: orchestration.yaml missing: $ORCH_STD (FR-B85-004)" >&2; return 1
  fi
  # Directory mode is mandatory: the FR-J7-023 REVIEW.md ledger drift check is a
  # Phase-2 cross-cutting block that only runs in directory context (b8-4 lesson).
  local out rc
  out=$(bash "$VALIDATOR" "$STANDARDS_DIR/" 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    FAIL T-007: validate-standards-yaml.sh (dir mode) exited $rc (FR-B85-004)" >&2
    printf '%s\n' "$out" | grep -F 'STD-FAIL' | head -5 >&2; ok=0
  fi
  if ! printf '%s' "$out" | grep -qE '\[STD-PASS\] .*standards/orchestration\.yaml'; then
    echo "    FAIL T-007: no [STD-PASS] line for standards/orchestration.yaml in dir-mode output (FR-B85-004)" >&2; ok=0
  fi
  # FR-J7-023 anchor: the REVIEW.md cell is the BARE basename + version 1.1.0.
  grep -qE '\|[[:space:]]*orchestration\.yaml[[:space:]]*\|[[:space:]]*1\.1\.0[[:space:]]*\|' "$REVIEW_MD" \
    || { echo "    FAIL T-007: REVIEW.md has no '| orchestration.yaml | 1.1.0 |' ledger row (basename anchor, FR-J7-023)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b85_l1_008_persistence_ref() {
  local out
  out=$(python3 - "$SCHEMA_20" "$STANDARDS_DIR" <<'PY'
import sys, os, yaml
try:
    with open(sys.argv[1], encoding='utf-8') as f:
        d = yaml.safe_load(f)
except Exception as e:
    print(f"ERR:{e}"); sys.exit(0)
std_dir = sys.argv[2]
comps = d.get('components', []) if isinstance(d, dict) else []
c = next((c for c in comps if isinstance(c, dict) and 'postgres' in c.get('name','').lower()), None)
if c is None:
    print("NO_PG"); sys.exit(0)
std = c.get('standard', 'MISSING')
resolves = os.path.isfile(os.path.join(std_dir, std)) if isinstance(std, str) and std != 'MISSING' else False
forbidden = {'version', 'pin', 'image'}
pin = ','.join(sorted(set(c.keys()) & forbidden)) or 'NONE'
print(f"standard={std}")
print(f"resolves={resolves}")
print(f"pin={pin}")
PY
)
  case "$out" in
    ERR:*) echo "    FAIL T-008: 2.0.0.yaml parse error — ${out#ERR:} (FR-B85-021)" >&2; return 1 ;;
    NO_PG) echo "    FAIL T-008: no postgres component in 2.0.0.yaml (FR-B85-021)" >&2; return 1 ;;
  esac
  local std res pin ok=1
  std=$(printf '%s' "$out" | grep '^standard=' | cut -d= -f2-)
  res=$(printf '%s' "$out" | grep '^resolves=' | cut -d= -f2-)
  pin=$(printf '%s' "$out" | grep '^pin=' | cut -d= -f2-)
  [ "$std" = "persistence.yaml" ] || { echo "    FAIL T-008: postgres comp standard='$std' != 'persistence.yaml' (FR-B85-021)" >&2; ok=0; }
  [ "$res" = "True" ]             || { echo "    FAIL T-008: persistence.yaml ref does not resolve (re-asserts b8-3 T-011) (FR-B85-053)" >&2; ok=0; }
  [ "$pin" = "NONE" ]             || { echo "    FAIL T-008: postgres comp carries forbidden inline-pin key(s): $pin (ADR-B85-004)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b85_l1_009_sibling_harness_coupling() {
  # Exit-code-only coupling guard (NO output parse — keeps T-009 within the
  # ≤ 5 s L1 budget, the b8-4 T-012 strategy). b8-3 (17/17) + b8-3b (12/12)
  # MUST stay GREEN under the B.8.5 edits.
  bash "$HARNESS_DIR/b8-3.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-009: b8-3.test.sh --level 1 is RED under the B.8.5 edit (NFR-B85-004 coupling regression)" >&2; return 1; }
  bash "$HARNESS_DIR/b8-3b.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-009: b8-3b.test.sh --level 1 is RED under the B.8.5 edit (NFR-B85-004 coupling regression)" >&2; return 1; }
}

_test_b85_l1_010_deltas_deferred_and_intact() {
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
tnote = (tdb or {}).get('note', '') if tdb else 'NO_DELTA'
pg16 = any(isinstance(x, dict) and str(x.get('from','')).startswith('postgres-16') for x in deltas)
print(f"temporal_note={tnote}")
print(f"pg16_delta={pg16}")
PY
)
  case "$out" in
    ERR:*) echo "    FAIL T-010: 2.0.0.yaml parse error — ${out#ERR:} (FR-B85-055)" >&2; return 1 ;;
  esac
  local tnote pg16 ok=1
  tnote=$(printf '%s' "$out" | grep '^temporal_note=' | cut -d= -f2-)
  pg16=$(printf '%s' "$out" | grep '^pg16_delta=' | cut -d= -f2-)
  # The temporal->dbos delta is annotated deferred (note containing DEFERRED or
  # the no-Rust-SDK reason).
  case "$tnote" in
    *DEFERRED*|*"no Rust SDK"*|*"no rust sdk"*) ;;
    NO_DELTA) echo "    FAIL T-010: no temporal-intent->dbos-embedded migration_delta (FR-B85-055)" >&2; ok=0 ;;
    *) echo "    FAIL T-010: temporal->dbos delta note not marked deferred: '$tnote' (FR-B85-055)" >&2; ok=0 ;;
  esac
  # The postgres-16 delta is INTACT (still present, actively delivered).
  [ "$pg16" = "True" ] || { echo "    FAIL T-010: postgres-16-no-pgvector delta missing — must stay intact (FR-B85-014)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b85_l1_011_flat_tree_untouched() {
  local ok=1
  if [ ! -f "$FLAT_COMPOSE" ]; then
    echo "    FAIL T-011: flat 1.0.0 docker-compose.dev.yml.tmpl missing: $FLAT_COMPOSE (NFR-B85-003)" >&2
    return 1
  fi
  # The frozen flat 1.0.0 fsm-db is still postgres:16-alpine (additive-first —
  # B.8.5 touches nothing in the flat tree).
  grep -qF 'image: postgres:16-alpine' "$FLAT_COMPOSE" \
    || { echo "    FAIL T-011: flat 1.0.0 postgres:16-alpine sentinel missing/modified (NFR-B85-003)" >&2; ok=0; }
  # The frozen 1.0.0 schema.yaml is still version: "1.0.0" (anchored, b8-3b T-012 form).
  if [ ! -f "$SCHEMA_10" ]; then
    echo "    FAIL T-011: frozen schema.yaml (1.0.0) missing: $SCHEMA_10 (NFR-B85-003)" >&2; ok=0
  elif ! grep -qx 'version: "1.0.0"' "$SCHEMA_10"; then
    echo "    FAIL T-011: frozen schema.yaml is not version: \"1.0.0\" — a candidate edit bled into the frozen schema (NFR-B85-003)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b85_l1_012_no_dbos_crate() {
  # Anti-hallucination (central Article III.4): NO dbos crate pin / Cargo.toml
  # dbos / DBOSContext anywhere in the 2.0.0 postgres tree (the deferral is
  # prose-only; DBOS has no Rust SDK).
  if grep -rqiE 'dbos[[:space:]]*=|cargo[[:space:]]+add[[:space:]]+dbos|DBOSContext' "$PG_DIR" 2>/dev/null; then
    echo "    FAIL T-012: a dbos crate pin / cargo add dbos / DBOSContext token leaked into the 2.0.0 postgres tree (NFR-B85-001)" >&2
    grep -rniE 'dbos[[:space:]]*=|cargo[[:space:]]+add[[:space:]]+dbos|DBOSContext' "$PG_DIR" 2>/dev/null | head -3 >&2
    return 1
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.8.5 — b8-5-postgres-pgvector — level $LEVEL ──"
  run_test _test_b85_l1_001_tree_files
  run_test _test_b85_l1_002_pgvector_image
  run_test _test_b85_l1_003_init_extension
  run_test _test_b85_l1_004_mirrors_fsm_db_shape
  run_test _test_b85_l1_005_image_anti_hallucination
  run_test _test_b85_l1_006_dbos_deferral_recorded
  run_test _test_b85_l1_007_orch_j7_dir_mode
  run_test _test_b85_l1_008_persistence_ref
  run_test _test_b85_l1_009_sibling_harness_coupling
  run_test _test_b85_l1_010_deltas_deferred_and_intact
  run_test _test_b85_l1_011_flat_tree_untouched
  run_test _test_b85_l1_012_no_dbos_crate
  print_summary
}

main
