#!/usr/bin/env bash
# Forge — T5.3.1 docker-compose.dev.yml template hygiene harness
# <!-- Audit: T5.3.1 (b1-1-dev-up-matrix-fixes) -->
#
# Validates the T5.3.1 deliverables :
#
#   - `image: scratch` removed from fsm-backend (ADR-B1-DUM-001 Option A).
#   - top-level `version: "3.8"` key removed (ADR-B1-DUM-002 Option B).
#   - T5.3.1 audit comment present in canonical template.
#   - 4 mirror copies byte-identical (FR-B1-DUM-040..043).
#   - Exactly 4 docker-compose.dev.yml.tmpl files under repo root (1.0.0 set;
#     the additive 2.0.0/ Kong-less variant is excluded — B.8.14, see b8-14-flip).
#   - Adopter swap-in comment preserved.
#   - CHANGELOG entry references the change.
#
# 9 L1 + 1 L2 = 10 tests.
# Performance budget : L1 ≤ 2 s wall-clock (NFR-B1-DUM-002).

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

DC_CANONICAL="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl"
DC_EXAMPLE="$FORGE_ROOT_REAL/examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl"
DC_CLI_MIRROR="$FORGE_ROOT_REAL/cli/assets/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl"
DC_CLI_EXAMPLE_MIRROR="$FORGE_ROOT_REAL/cli/assets/examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
SNAPSHOT="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (9 tests)
# MANIFEST: _test_b1dum_l1_001_canonical_no_scratch                        — FR-B1-DUM-001
# MANIFEST: _test_b1dum_l1_002_canonical_no_version_key                    — FR-B1-DUM-020/021
# MANIFEST: _test_b1dum_l1_003_audit_comment_present                       — FR-B1-DUM-005
# MANIFEST: _test_b1dum_l1_004_mirror_example_byte_identity                — FR-B1-DUM-040
# MANIFEST: _test_b1dum_l1_005_mirror_cli_assets_byte_identity             — FR-B1-DUM-041
# MANIFEST: _test_b1dum_l1_006_mirror_cli_assets_example_byte_identity     — FR-B1-DUM-042
# MANIFEST: _test_b1dum_l1_007_four_copies_only                            — FR-B1-DUM-043
# MANIFEST: _test_b1dum_l1_008_adopter_comment_preserved                   — FR-B1-DUM-004
# MANIFEST: _test_b1dum_l1_009_changelog_entry                             — FR-B1-DUM-110
#
# L2 (1 test, opt-in via FORGE_B1DUM_DOCKER=1)
# MANIFEST: _test_b1dum_l2_dev_up_cycle                                    — FR-B1-DUM-082 / FR-B1-DUM-060..062

# ─── L1 tests ────────────────────────────────────────────────────

_test_b1dum_l1_001_canonical_no_scratch() {
  if [ ! -f "$DC_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if grep -Fq 'image: scratch' "$DC_CANONICAL"; then
    echo "    canonical template still declares 'image: scratch' (ADR-B1-DUM-001 violated)" >&2
    return 1
  fi
}

_test_b1dum_l1_002_canonical_no_version_key() {
  if [ ! -f "$DC_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if grep -Eq '^version:' "$DC_CANONICAL"; then
    echo "    canonical template still declares top-level 'version:' key (ADR-B1-DUM-002 violated)" >&2
    return 1
  fi
}

_test_b1dum_l1_003_audit_comment_present() {
  if [ ! -f "$DC_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if ! grep -Fq 'T5.3.1 (b1-1-dev-up-matrix-fixes)' "$DC_CANONICAL"; then
    echo "    canonical template missing audit comment 'T5.3.1 (b1-1-dev-up-matrix-fixes)' (FR-B1-DUM-005)" >&2
    return 1
  fi
}

_test_b1dum_l1_004_mirror_example_byte_identity() {
  if [ ! -f "$DC_CANONICAL" ] || [ ! -f "$DC_EXAMPLE" ]; then
    echo "    canonical or example mirror missing" >&2; return 1
  fi
  if ! diff -q "$DC_CANONICAL" "$DC_EXAMPLE" > /dev/null 2>&1; then
    echo "    canonical vs example mirror diverge (FR-B1-DUM-040)" >&2
    diff -u "$DC_CANONICAL" "$DC_EXAMPLE" | head -20 >&2
    return 1
  fi
}

_test_b1dum_l1_005_mirror_cli_assets_byte_identity() {
  if [ ! -f "$DC_CANONICAL" ] || [ ! -f "$DC_CLI_MIRROR" ]; then
    echo "    canonical or cli/assets mirror missing" >&2; return 1
  fi
  if ! diff -q "$DC_CANONICAL" "$DC_CLI_MIRROR" > /dev/null 2>&1; then
    echo "    canonical vs cli/assets mirror diverge (FR-B1-DUM-041 — run 'npm run bundle' from cli/)" >&2
    return 1
  fi
}

_test_b1dum_l1_006_mirror_cli_assets_example_byte_identity() {
  if [ ! -f "$DC_EXAMPLE" ] || [ ! -f "$DC_CLI_EXAMPLE_MIRROR" ]; then
    echo "    example or cli/assets example mirror missing" >&2; return 1
  fi
  if ! diff -q "$DC_EXAMPLE" "$DC_CLI_EXAMPLE_MIRROR" > /dev/null 2>&1; then
    echo "    example vs cli/assets example mirror diverge (FR-B1-DUM-042 — run 'npm run bundle' from cli/)" >&2
    return 1
  fi
}

_test_b1dum_l1_007_four_copies_only() {
  # Counts the full-stack-monorepo 1.0.0 canonical docker-compose template set
  # (source + cli/assets mirror + the two forge-fsm-example copies). ALL versioned
  # subtrees (`N.N.N/`) are EXCLUDED — they are distinct artifacts shipping their
  # own docker-compose: the additive 2.0.0/ Kong-less variant (B.8.14, covered by
  # b8-14-flip.test.sh) AND other archetypes' versioned trees (e.g.
  # ai-native-rag/1.0.0/, B.7.2 — a candidate with its own RAG compose). Version-
  # aware, matching the b8-signoz / b8-3b scans; still catches flagship 1.0.0
  # proliferation.
  local count
  count=$(find "$FORGE_ROOT_REAL" -name "docker-compose.dev.yml.tmpl" \
            -not -path "*/node_modules/*" -not -path "*/.git/*" \
            -not -path '*/[0-9]*.[0-9]*.[0-9]*/*' 2>/dev/null \
          | wc -l | tr -d ' ')
  if [ "$count" != "4" ]; then
    echo "    expected exactly 4 docker-compose.dev.yml.tmpl copies (flagship 1.0.0 set, excl. versioned N.N.N/ subtrees), found $count (FR-B1-DUM-043)" >&2
    find "$FORGE_ROOT_REAL" -name "docker-compose.dev.yml.tmpl" \
        -not -path "*/node_modules/*" -not -path "*/.git/*" \
        -not -path '*/[0-9]*.[0-9]*.[0-9]*/*' >&2
    return 1
  fi
}

_test_b1dum_l1_008_adopter_comment_preserved() {
  if [ ! -f "$DC_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  # Adopter swap-in intent (FR-B1-DUM-004) — accepts the pre-T5.3.1 wording
  # ("Replace the image below with the project image once built") OR the
  # post-T5.3.1 rewording ("Replace the image below with your real backend image").
  if ! grep -qE "Replace the image (below|in [a-z]+) with (the project|your real)" "$DC_CANONICAL"; then
    echo "    adopter swap-in comment block missing (FR-B1-DUM-004)" >&2
    return 1
  fi
}

_test_b1dum_l1_009_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing" >&2; return 1
  fi
  if ! grep -Fq "b1-1-dev-up-matrix-fixes" "$CHANGELOG_MD"; then
    echo "    CHANGELOG.md does not mention b1-1-dev-up-matrix-fixes (FR-B1-DUM-110)" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in) ───────────────────────────────────────────

_test_b1dum_l2_dev_up_cycle() {
  if [ "${FORGE_B1DUM_DOCKER:-0}" != "1" ]; then
    echo "    skipped (FORGE_B1DUM_DOCKER unset — opt-in)" >&2
    return 0
  fi
  if ! command -v docker > /dev/null 2>&1; then
    echo "    skipped (docker absent on PATH)" >&2
    return 0
  fi
  if ! command -v task > /dev/null 2>&1; then
    echo "    skipped (task CLI absent on PATH — required by Taskfile dev:up)" >&2
    return 0
  fi
  local tmp
  tmp=$(mktemp -d "/tmp/forge-b1dum-XXXXXX")
  # shellcheck disable=SC2064  # we want $tmp expanded at trap-install time
  trap "(cd '$tmp' 2>/dev/null && task dev:down >/dev/null 2>&1 || true); rm -rf '$tmp'" EXIT

  if ! node "$FORGE_ROOT_REAL/cli/dist/index.js" init smoke_b1dum \
        --archetype full-stack-monorepo --org dev.forge.test --target "$tmp" > /dev/null 2>&1; then
    echo "    forge init failed" >&2
    return 1
  fi
  # Mirror the dev-up-matrix smoke driver (Taskfile.yml:160-162) :
  # bootstrap .env from .env.example, since `env_file: .env` in the
  # rendered compose requires its presence — exactly what an adopter
  # following the README does on first scaffold.
  if [ -f "$tmp/.env.example" ] && [ ! -f "$tmp/.env" ]; then
    cp "$tmp/.env.example" "$tmp/.env"
  fi
  if ! (cd "$tmp" && task dev:up > /dev/null 2>&1); then
    echo "    task dev:up failed on fresh scaffold (FR-B1-DUM-060)" >&2
    return 1
  fi
  # Assert non-backend infra services running/healthy.
  local ps_json
  ps_json=$(cd "$tmp" && docker compose ps --format json 2>/dev/null || true)
  for svc in fsm-db fsm-kong fsm-signoz fsm-otel-collector; do
    if ! printf '%s' "$ps_json" | grep -q "\"Service\":\"$svc\""; then
      echo "    $svc not listed in 'docker compose ps --format json' (FR-B1-DUM-061)" >&2
      return 1
    fi
  done
  if ! (cd "$tmp" && task dev:down > /dev/null 2>&1); then
    echo "    task dev:down failed (FR-B1-DUM-062)" >&2
    return 1
  fi
  # Assert no orphan fsm-* containers.
  if docker ps --format '{{.Names}}' | grep -q '^fsm-'; then
    echo "    orphan fsm-* container survives task dev:down (FR-B1-DUM-062)" >&2
    return 1
  fi
  trap - EXIT
  rm -rf "$tmp"
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T5.3.1 — b1-1-dev-up-matrix-fixes — level $LEVEL ──"

  # L1 always runs.
  run_test _test_b1dum_l1_001_canonical_no_scratch
  run_test _test_b1dum_l1_002_canonical_no_version_key
  run_test _test_b1dum_l1_003_audit_comment_present
  run_test _test_b1dum_l1_004_mirror_example_byte_identity
  run_test _test_b1dum_l1_005_mirror_cli_assets_byte_identity
  run_test _test_b1dum_l1_006_mirror_cli_assets_example_byte_identity
  run_test _test_b1dum_l1_007_four_copies_only
  run_test _test_b1dum_l1_008_adopter_comment_preserved
  run_test _test_b1dum_l1_009_changelog_entry

  # L2 runs when --level includes 2.
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — live task dev:up cycle (opt-in FORGE_B1DUM_DOCKER=1)"
    run_test _test_b1dum_l2_dev_up_cycle
  fi

  print_summary
}

main "$@"
