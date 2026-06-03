#!/usr/bin/env bash
# Forge — B.8.9 Qwik web-public 2.0.0 frontend-brick harness
# <!-- Audit: B.8.9 (b8-9-qwik-web-public) — 2.0.0 Qwik web-public template brick gate -->
#
# Validates the b8-9-qwik-web-public deliverables (design.md § Testing Strategy +
# ADR-B89-001..007 — 10-file Qwik City skeleton, web-frontend.yaml v1.0.0,
# 2.0.0 buf.gen es out-path re-point, 2.0.0.yaml comment-only annotation):
#
#   T-001  2.0.0/frontend/web-public/ directory exists                              (FR-B89-001/005, ADR-B89-002)
#   T-002  all 10 required Qwik skeleton files present in the subtree               (FR-B89-002/081, ADR-B89-002)
#   T-003  template file count ≤ 15 in the subtree                                  (NFR-B89-012/082)
#   T-004  package.json.tmpl carries @connectrpc/connect + @connectrpc/connect-web  (FR-B89-021/082, ADR-B89-003)
#   T-005  protoc-gen-connect-es absent as an active (non-comment) reference        (FR-B89-024/083, ADR-B89-003)
#   T-006  .nvmrc.tmpl contains 24 (active LTS re-verified at T004)                 (FR-B89-050/051, ADR-B89-006)
#   T-007  web-frontend.yaml version "1.0.0" + versions: block + default: present   (FR-B89-040/041/084, ADR-B89-005)
#   T-008  index.yml web-frontend.yaml ref + REVIEW.md | web-frontend.yaml | 1.0.0 |(FR-B89-045/047/085)
#   T-009  2.0.0.yaml B.8.9 delivered annotation comment present                    (FR-B89-060/086, ADR-B89-007)
#   T-010  2.0.0 buf.gen es out-path re-pointed + bump-note; frozen 1.0.0 untouched (FR-B89-030/032/086, ADR-B89-004)
#   T-011  coupling guard: b8-3 (17/17) + b8-3b (12/12) + b8-6 (12/12) stay GREEN   (NFR-B89-003/087)
#   T-012  CHANGELOG.md has a b8-9-qwik-web-public entry (whole-file grep)          (FR-B89-087, NFR-B89-001)
#
# 12 L1 tests. Budget L1 ≤ 2 s, zero net/Docker/npm. The live verify-then-pin
# (Qwik/Vite/Node + Connect-ES/Qwik API shapes) is a /forge:implement step, NOT
# an L1 assertion. T-011 is exit-code only (the b8-4/b8-5/b8-6/b8-7 coupling
# strategy) — keeps the coupling guard within budget. Mirrors b8-7.test.sh
# structure (--level flag + _helpers.sh).

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
# 2.0.0 Qwik web-public subtree (the B.8.9 deliverable — schema-aligned under frontend/).
WEB_PUBLIC_DIR="$TEMPLATE_ROOT/2.0.0/frontend/web-public"
PKG="$WEB_PUBLIC_DIR/package.json.tmpl"
NVMRC="$WEB_PUBLIC_DIR/.nvmrc.tmpl"

# 2.0.0 buf.gen manifest (re-pointed) + frozen 1.0.0 manifest (untouched).
BUF_GEN_20="$TEMPLATE_ROOT/2.0.0/shared/protos/buf.gen.yaml.tmpl"
BUF_GEN_10="$TEMPLATE_ROOT/shared/protos/buf.gen.yaml.tmpl"

STANDARDS_DIR="$FORGE_ROOT/.forge/standards"
WEB_FRONTEND_STD="$STANDARDS_DIR/web-frontend.yaml"
INDEX_YML="$STANDARDS_DIR/index.yml"
REVIEW_MD="$STANDARDS_DIR/REVIEW.md"

SCHEMA_20="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/2.0.0.yaml"
CHANGELOG="$FORGE_ROOT/CHANGELOG.md"

# The 10 required Qwik City skeleton files (ADR-B89-002 file list).
REQUIRED_FILES=(
  "package.json.tmpl"
  ".nvmrc.tmpl"
  "vite.config.ts.tmpl"
  "tsconfig.json.tmpl"
  "qwik.env.d.ts.tmpl"
  "src/entry.ssr.tsx.tmpl"
  "src/root.tsx.tmpl"
  "src/routes/index.tsx.tmpl"
  "src/lib/connect-client.ts.tmpl"
  "README.md.tmpl"
)

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b89_l1_001_web_public_dir_exists() {
  [ -d "$WEB_PUBLIC_DIR" ] \
    || { echo "    FAIL T-001: missing web-public subtree dir $WEB_PUBLIC_DIR (FR-B89-001/005, ADR-B89-002)" >&2; return 1; }
}

_test_b89_l1_002_all_ten_files_present() {
  if [ ! -d "$WEB_PUBLIC_DIR" ]; then
    echo "    FAIL T-002: web-public subtree dir absent: $WEB_PUBLIC_DIR (FR-B89-002)" >&2; return 1
  fi
  local ok=1 f
  for f in "${REQUIRED_FILES[@]}"; do
    [ -f "$WEB_PUBLIC_DIR/$f" ] \
      || { echo "    FAIL T-002: missing required skeleton file $f under web-public/ (FR-B89-002/081, ADR-B89-002)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b89_l1_003_file_count_within_budget() {
  if [ ! -d "$WEB_PUBLIC_DIR" ]; then
    echo "    FAIL T-003: web-public subtree dir absent: $WEB_PUBLIC_DIR (NFR-B89-012)" >&2; return 1
  fi
  local count
  count=$(find "$WEB_PUBLIC_DIR" -name "*.tmpl" -type f | wc -l | tr -d ' ')
  [ "$count" -le 15 ] \
    || { echo "    FAIL T-003: web-public template file count $count > 15 budget (NFR-B89-012/082)" >&2; return 1; }
}

_test_b89_l1_004_package_connect_sentinels() {
  if [ ! -f "$PKG" ]; then
    echo "    FAIL T-004: package.json.tmpl missing: $PKG (FR-B89-021)" >&2; return 1
  fi
  local ok=1
  grep -qF '@connectrpc/connect' "$PKG" \
    || { echo "    FAIL T-004: package.json.tmpl missing @connectrpc/connect sentinel (FR-B89-021/082, ADR-B89-003)" >&2; ok=0; }
  grep -qF '@connectrpc/connect-web' "$PKG" \
    || { echo "    FAIL T-004: package.json.tmpl missing @connectrpc/connect-web sentinel (FR-B89-021/082, ADR-B89-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b89_l1_005_no_protoc_gen_connect_es() {
  if [ ! -d "$WEB_PUBLIC_DIR" ]; then
    # Subtree absent (RED baseline) → no stale reference either → PASS.
    return 0
  fi
  # protoc-gen-connect-es is retired by Connect v2 (ADR-B89-003); it MUST NOT
  # appear as an ACTIVE reference (a package.json dependency key, a buf.gen
  # remote:/plugin: line, or a code import). Lines that DOCUMENT the retirement
  # are explicitly required by FR-B89-024 (README note) and are allowed:
  #   - comment lines (#, //, /* *, <!--)
  #   - markdown blockquotes (>) and prose containing 'retired'/'stale'
  # An active reference is therefore one that survives BOTH exclusion filters.
  local hits
  hits=$(grep -rn 'protoc-gen-connect-es' "$WEB_PUBLIC_DIR" 2>/dev/null \
    | grep -vE ':[[:space:]]*(#|//|/\*|\*|<!--|>)' \
    | grep -viE 'retired|stale|deprecat|do not use|replaced by' \
    || true)
  if [ -n "$hits" ]; then
    echo "    FAIL T-005: active protoc-gen-connect-es reference(s) in $WEB_PUBLIC_DIR (FR-B89-024/083, ADR-B89-003):" >&2
    printf '%s\n' "$hits" | sed 's/^/      /' >&2
    return 1
  fi
}

_test_b89_l1_006_nvmrc_node_lts() {
  if [ ! -f "$NVMRC" ]; then
    echo "    FAIL T-006: .nvmrc.tmpl missing: $NVMRC (FR-B89-050, ADR-B89-006)" >&2; return 1
  fi
  grep -qF '24' "$NVMRC" \
    || { echo "    FAIL T-006: .nvmrc.tmpl does not contain '24' (active LTS; FR-B89-050/051, ADR-B89-006)" >&2; return 1; }
}

_test_b89_l1_007_web_frontend_standard_shape() {
  if [ ! -f "$WEB_FRONTEND_STD" ]; then
    echo "    FAIL T-007: web-frontend.yaml missing: $WEB_FRONTEND_STD (FR-B89-040, ADR-B89-005)" >&2; return 1
  fi
  local ok=1
  grep -qE '^version:[[:space:]]*"1\.0\.0"' "$WEB_FRONTEND_STD" \
    || { echo "    FAIL T-007: web-frontend.yaml version: field is not \"1.0.0\" (FR-B89-040/084, ADR-B89-005)" >&2; ok=0; }
  grep -qF 'versions:' "$WEB_FRONTEND_STD" \
    || { echo "    FAIL T-007: web-frontend.yaml has no versions: block (FR-B89-043/084, ADR-B89-005)" >&2; ok=0; }
  grep -qF 'default:' "$WEB_FRONTEND_STD" \
    || { echo "    FAIL T-007: web-frontend.yaml has no default: field (FR-B89-042/084, ADR-B89-005)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b89_l1_008_index_and_review_ledger() {
  local ok=1
  if [ ! -f "$INDEX_YML" ]; then
    echo "    FAIL T-008: index.yml missing: $INDEX_YML (FR-B89-047)" >&2; ok=0
  else
    grep -qF 'web-frontend.yaml' "$INDEX_YML" \
      || { echo "    FAIL T-008: index.yml has no web-frontend.yaml reference (FR-B89-047/085)" >&2; ok=0; }
  fi
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    FAIL T-008: REVIEW.md missing: $REVIEW_MD (FR-B89-045)" >&2; ok=0
  else
    # FR-J7-023 anchor: BARE basename + version 1.0.0 ledger row.
    grep -qE '\|[[:space:]]*web-frontend\.yaml[[:space:]]*\|[[:space:]]*1\.0\.0[[:space:]]*\|' "$REVIEW_MD" \
      || { echo "    FAIL T-008: REVIEW.md has no '| web-frontend.yaml | 1.0.0 |' ledger row (FR-J7-023, FR-B89-045/085)" >&2; ok=0; }
  fi
  [ "$ok" = "1" ]
}

_test_b89_l1_009_schema_delivered_annotation() {
  if [ ! -f "$SCHEMA_20" ]; then
    echo "    FAIL T-009: 2.0.0.yaml missing: $SCHEMA_20 (FR-B89-060)" >&2; return 1
  fi
  grep -qE 'B\.8\.9.*delivered|delivered.*B\.8\.9' "$SCHEMA_20" \
    || { echo "    FAIL T-009: 2.0.0.yaml has no 'B.8.9 delivered' annotation comment (FR-B89-060/086, ADR-B89-007)" >&2; return 1; }
}

_test_b89_l1_010_buf_gen_repoint_and_frozen_guard() {
  if [ ! -f "$BUF_GEN_20" ]; then
    echo "    FAIL T-010: 2.0.0 buf.gen.yaml.tmpl missing: $BUF_GEN_20 (FR-B89-030)" >&2; return 1
  fi
  local ok=1
  # es out-path re-pointed to the web-public surface (ADR-B89-004).
  grep -qF 'web-public/src/lib/generated/connect' "$BUF_GEN_20" \
    || { echo "    FAIL T-010: 2.0.0 buf.gen es out-path NOT re-pointed to web-public/src/lib/generated/connect (FR-B89-030/086, ADR-B89-004)" >&2; ok=0; }
  # Bump-note present (FR-B89-032).
  grep -qF 'B.8.9 delta' "$BUF_GEN_20" \
    || { echo "    FAIL T-010: 2.0.0 buf.gen header missing 'B.8.9 delta' bump-note (FR-B89-032)" >&2; ok=0; }
  # Frozen 1.0.0 manifest MUST NOT carry a B.8.9 annotation (FR-B89-031).
  if [ -f "$BUF_GEN_10" ]; then
    if grep -qF 'B.8.9' "$BUF_GEN_10"; then
      echo "    FAIL T-010: frozen 1.0.0 buf.gen.yaml.tmpl carries a B.8.9 annotation — must be byte-untouched (FR-B89-031, NFR-B89-002)" >&2; ok=0
    fi
  else
    echo "    FAIL T-010: frozen 1.0.0 buf.gen.yaml.tmpl missing: $BUF_GEN_10 (FR-B89-031)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b89_l1_011_sibling_harness_coupling() {
  # Exit-code-only coupling guard (NO output parse — keeps T-011 within the
  # ≤ 2 s L1 budget, the b8-4/b8-5/b8-6/b8-7 coupling strategy). b8-3 (17/17) +
  # b8-3b (12/12) + b8-6 (12/12) MUST stay GREEN under the B.8.9 edits.
  bash "$HARNESS_DIR/b8-3.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-011: b8-3.test.sh --level 1 is RED under the B.8.9 edit (NFR-B89-003 coupling regression)" >&2; return 1; }
  bash "$HARNESS_DIR/b8-3b.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-011: b8-3b.test.sh --level 1 is RED under the B.8.9 edit (NFR-B89-003 coupling regression)" >&2; return 1; }
  bash "$HARNESS_DIR/b8-6.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-011: b8-6.test.sh --level 1 is RED under the B.8.9 es out-path re-point (NFR-B89-003/FR-B89-033 coupling regression)" >&2; return 1; }
}

_test_b89_l1_012_changelog_entry() {
  if [ ! -f "$CHANGELOG" ]; then
    echo "    FAIL T-012: CHANGELOG.md missing: $CHANGELOG (FR-B89-087)" >&2; return 1
  fi
  # A B.8.9 entry must exist (grep the whole file per the changelog-test
  # [Unreleased]-coupling lesson — survives release graduation). Anchored on
  # the change NAME `b8-9-qwik-web-public` (not the bare "B.8.9" string, which a
  # sibling entry could mention in prose — that would false-pass).
  if ! grep -qF 'b8-9-qwik-web-public' "$CHANGELOG"; then
    echo "    FAIL T-012: CHANGELOG.md has no b8-9-qwik-web-public entry (FR-B89-087, NFR-B89-001)" >&2
    return 1
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.8.9 — b8-9-qwik-web-public — level $LEVEL ──"
  run_test _test_b89_l1_001_web_public_dir_exists
  run_test _test_b89_l1_002_all_ten_files_present
  run_test _test_b89_l1_003_file_count_within_budget
  run_test _test_b89_l1_004_package_connect_sentinels
  run_test _test_b89_l1_005_no_protoc_gen_connect_es
  run_test _test_b89_l1_006_nvmrc_node_lts
  run_test _test_b89_l1_007_web_frontend_standard_shape
  run_test _test_b89_l1_008_index_and_review_ledger
  run_test _test_b89_l1_009_schema_delivered_annotation
  run_test _test_b89_l1_010_buf_gen_repoint_and_frozen_guard
  run_test _test_b89_l1_011_sibling_harness_coupling
  run_test _test_b89_l1_012_changelog_entry
  print_summary
}

main
