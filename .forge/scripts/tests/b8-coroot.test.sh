#!/usr/bin/env bash
# Forge — B.8.8 Coroot rehost ghcr.io + 1.20.2 harness
# <!-- Audit: B.8.8 (b8-coroot-rehost) — observability rearch trio pilot -->
#
# Validates the b8-coroot-rehost deliverables :
#
#   - Coroot image pin migrated `coroot/coroot:1.4.4` →
#     `ghcr.io/coroot/coroot:1.20.2` across 4 mirror copies
#     (FR-B8-COR-001..007 ; ADR-B8-COR-001 uniform no-v-prefix —
#     inverted at /forge:implement after L2 manifest-pull caught
#     proposal's v-prefix-mandatory mis-read).
#   - `.forge/standards/observability.yaml` bumped v1.1.0 → v1.2.0
#     additive (FR-B8-COR-030..038).
#   - `.forge/standards/REVIEW.md` ledger appended (FR-B8-COR-050).
#   - `bin/validate-standards-yaml.sh` exits 0 post-bump (FR-B8-COR-035).
#   - CHANGELOG entry (FR-B8-COR-120).
#   - L2 opt-in (FORGE_B8_COROOT_DOCKER=1) confirms
#     ghcr.io/coroot/coroot:1.20.2 multi-arch pullable + --config flag
#     valid (FR-B8-COR-072 ; ADR-B8-COR-003 manifest-pull leg) AND
#     docker.io coroot/coroot:1.4.4 stays denied (FR-B8-COR-073
#     verify-then-pin invariant per ADR-B8-COR-003).
#
# 13 L1 + 2 L2 = 15 tests.
# Performance budget : L1 ≤ 2 s wall-clock (NFR-B8-COR-002).

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

COROOT_CANONICAL="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl"
COROOT_CLI_MIRROR="$FORGE_ROOT_REAL/cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl"
COROOT_EXAMPLE="$FORGE_ROOT_REAL/examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml"
COROOT_CLI_EXAMPLE_MIRROR="$FORGE_ROOT_REAL/cli/assets/examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml"
OBSERV_YAML="$FORGE_ROOT_REAL/.forge/standards/observability.yaml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
VALIDATOR="$FORGE_ROOT_REAL/bin/validate-standards-yaml.sh"

NEW_PIN="ghcr.io/coroot/coroot:1.20.2"
LEGACY_PIN="coroot/coroot:1.4.4"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (13 tests)
# MANIFEST: _test_b8cor_l1_001_canonical_image_pin                     — FR-B8-COR-001/-002/-003
# MANIFEST: _test_b8cor_l1_002_canonical_no_dockerio_coroot             — FR-B8-COR-001
# MANIFEST: _test_b8cor_l1_003_canonical_audit_comment                  — FR-B8-COR-008
# MANIFEST: _test_b8cor_l1_004_cli_bundle_template_byte_identity        — FR-B8-COR-004
# MANIFEST: _test_b8cor_l1_005_example_rendered_image_pin               — FR-B8-COR-005
# MANIFEST: _test_b8cor_l1_006_cli_bundle_example_byte_identity         — FR-B8-COR-006
# MANIFEST: _test_b8cor_l1_007_four_copies_only                         — FR-B8-COR-007
# MANIFEST: _test_b8cor_l1_008_standard_version_bumped                  — FR-B8-COR-030
# MANIFEST: _test_b8cor_l1_009_standard_coroot_pin_no_vprefix          — FR-B8-COR-031 / ADR-B8-COR-001 (no v-prefix per inverted finding)
# MANIFEST: _test_b8cor_l1_010_standard_last_reviewed_today             — FR-B8-COR-034
# MANIFEST: _test_b8cor_l1_011_review_ledger_appended                   — FR-B8-COR-050
# MANIFEST: _test_b8cor_l1_012_validate_standards_yaml_passes           — FR-B8-COR-035
# MANIFEST: _test_b8cor_l1_013_changelog_entry                          — FR-B8-COR-120
#
# L2 (2 tests, opt-in via FORGE_B8_COROOT_DOCKER=1)
# MANIFEST: _test_b8cor_l2_001_ghcr_manifest_pullable                   — FR-B8-COR-072 ; ADR-B8-COR-003
# MANIFEST: _test_b8cor_l2_002_old_pin_denied                           — FR-B8-COR-073 ; ADR-B8-COR-003

# ─── L1 tests ────────────────────────────────────────────────────

_test_b8cor_l1_001_canonical_image_pin() {
  if [ ! -f "$COROOT_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if ! grep -Fq "image: $NEW_PIN" "$COROOT_CANONICAL"; then
    echo "    canonical template does not declare 'image: $NEW_PIN' (FR-B8-COR-001)" >&2
    return 1
  fi
}

_test_b8cor_l1_002_canonical_no_dockerio_coroot() {
  if [ ! -f "$COROOT_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  # Match the legacy pin only on `image:` lines, so the audit comment
  # block (which references the legacy pin verbatim) does not trigger.
  if grep -Eq '^\s*image:\s*coroot/coroot:1' "$COROOT_CANONICAL"; then
    echo "    canonical template still uses legacy docker.io coroot pin on an image: line (FR-B8-COR-001)" >&2
    return 1
  fi
}

_test_b8cor_l1_003_canonical_audit_comment() {
  if [ ! -f "$COROOT_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if ! grep -Fq "B.8.8 / b8-coroot-rehost" "$COROOT_CANONICAL"; then
    echo "    canonical template missing audit comment 'B.8.8 / b8-coroot-rehost' (FR-B8-COR-008)" >&2
    return 1
  fi
}

_test_b8cor_l1_004_cli_bundle_template_byte_identity() {
  if [ ! -f "$COROOT_CANONICAL" ] || [ ! -f "$COROOT_CLI_MIRROR" ]; then
    echo "    canonical or cli/assets mirror missing" >&2; return 1
  fi
  if ! diff -q "$COROOT_CANONICAL" "$COROOT_CLI_MIRROR" > /dev/null 2>&1; then
    echo "    canonical vs cli/assets mirror diverge (FR-B8-COR-004 — run 'npm run bundle' from cli/)" >&2
    return 1
  fi
}

_test_b8cor_l1_005_example_rendered_image_pin() {
  if [ ! -f "$COROOT_EXAMPLE" ]; then
    echo "    example rendered file missing" >&2; return 1
  fi
  if ! grep -Fq "image: $NEW_PIN" "$COROOT_EXAMPLE"; then
    echo "    example rendered file does not declare 'image: $NEW_PIN' (FR-B8-COR-005)" >&2
    return 1
  fi
}

_test_b8cor_l1_006_cli_bundle_example_byte_identity() {
  if [ ! -f "$COROOT_EXAMPLE" ] || [ ! -f "$COROOT_CLI_EXAMPLE_MIRROR" ]; then
    echo "    example or cli/assets example mirror missing" >&2; return 1
  fi
  if ! diff -q "$COROOT_EXAMPLE" "$COROOT_CLI_EXAMPLE_MIRROR" > /dev/null 2>&1; then
    echo "    example vs cli/assets example mirror diverge (FR-B8-COR-006 — run 'npm run bundle' from cli/)" >&2
    return 1
  fi
}

_test_b8cor_l1_007_four_copies_only() {
  local count
  count=$( ( find "$FORGE_ROOT_REAL" -name "coroot-deployment.yaml" \
                   -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
             find "$FORGE_ROOT_REAL" -name "coroot-deployment.yaml.tmpl" \
                   -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
           ) | wc -l | tr -d ' ')
  if [ "$count" != "4" ]; then
    echo "    expected exactly 4 coroot-deployment file copies, found $count (FR-B8-COR-007)" >&2
    ( find "$FORGE_ROOT_REAL" -name "coroot-deployment.yaml" \
            -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
      find "$FORGE_ROOT_REAL" -name "coroot-deployment.yaml.tmpl" \
            -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null ) >&2
    return 1
  fi
}

_test_b8cor_l1_008_standard_version_bumped() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  # The observability.yaml standard is shared across the b8-observability-rearch
  # trio. Leg 1 (b8-coroot-rehost) set version 1.2.0 additive ; leg 2
  # (b8-signoz-unified) bumped it to 2.0.0 BREAKING (2026-05-27). Track the
  # current trio state ; leg 3 (b8-obi-refresh) will bump again. FR-B8-COR-030
  # intent is "version was bumped by the trio", not a frozen 1.2.0.
  if ! grep -Eq '^version:\s*"?2\.0\.0"?\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml::version is not '2.0.0' (FR-B8-COR-030 ; bumped BREAKING by trio leg 2 b8-signoz-unified)" >&2
    grep -E '^version:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8cor_l1_009_standard_coroot_pin_no_vprefix() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  if ! grep -Eq '^\s+coroot:\s*"?1\.20\.2"?\s*(#.*)?$' "$OBSERV_YAML"; then
    echo "    observability.yaml::versions.coroot is not '1.20.2' (FR-B8-COR-031 / ADR-B8-COR-001 — no v-prefix per corrected GHCR convention)" >&2
    grep -E 'coroot:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8cor_l1_010_standard_last_reviewed_today() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  # The observability.yaml standard is shared across the b8-observability-rearch
  # trio. Leg 1 (b8-coroot-rehost) refreshed last_reviewed to 2026-05-24..25 ;
  # leg 2 (b8-signoz-unified) refreshed it to 2026-05-26..27. NFR-B8-COR-008
  # (trio coupling) only requires the bump to be recent, not a specific day —
  # track the current trio state ; leg 3 (b8-obi-refresh) will refresh again.
  if ! grep -Eq '^last_reviewed:\s*2026-05-2[67]\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml::last_reviewed is not 2026-05-26 or 2026-05-27 (FR-B8-COR-034 ; refreshed by b8-signoz-unified trio leg 2)" >&2
    grep -E '^last_reviewed:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8cor_l1_011_review_ledger_appended() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing" >&2; return 1
  fi
  if ! grep -Fq "b8-coroot-rehost" "$REVIEW_MD"; then
    echo "    REVIEW.md does not mention b8-coroot-rehost (FR-B8-COR-050 / -051)" >&2
    return 1
  fi
}

_test_b8cor_l1_012_validate_standards_yaml_passes() {
  if [ ! -x "$VALIDATOR" ]; then
    echo "    bin/validate-standards-yaml.sh missing or not executable" >&2; return 1
  fi
  if ! "$VALIDATOR" "$OBSERV_YAML" > /dev/null 2>&1; then
    echo "    validate-standards-yaml.sh failed on observability.yaml (FR-B8-COR-035)" >&2
    "$VALIDATOR" "$OBSERV_YAML" 2>&1 | tail -20 >&2 || true
    return 1
  fi
}

_test_b8cor_l1_013_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing" >&2; return 1
  fi
  if ! grep -Fq "b8-coroot-rehost" "$CHANGELOG_MD"; then
    echo "    CHANGELOG.md does not mention b8-coroot-rehost (FR-B8-COR-120)" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in) ───────────────────────────────────────────

_test_b8cor_l2_001_ghcr_manifest_pullable() {
  if [ "${FORGE_B8_COROOT_DOCKER:-0}" != "1" ]; then
    echo "    skipped (FORGE_B8_COROOT_DOCKER unset — opt-in)" >&2
    return 0
  fi
  if ! command -v docker > /dev/null 2>&1; then
    echo "    skipped (docker absent on PATH)" >&2
    return 0
  fi
  local out
  out=$(docker manifest inspect "$NEW_PIN" 2>&1)
  if [ $? -ne 0 ]; then
    echo "    docker manifest inspect $NEW_PIN failed (FR-B8-COR-072)" >&2
    printf '%s\n' "$out" | head -20 >&2
    return 1
  fi
  # Docker manifest inspect emits formatted JSON with whitespace
  # around `:` separators ; the regex below tolerates either pretty
  # or compact JSON output.
  if ! printf '%s' "$out" | grep -Eq '"architecture"[[:space:]]*:[[:space:]]*"amd64"'; then
    echo "    manifest is missing amd64 platform (FR-B8-COR-072 / NFR-B8-COR-008)" >&2
    return 1
  fi
  if ! printf '%s' "$out" | grep -Eq '"architecture"[[:space:]]*:[[:space:]]*"arm64"'; then
    echo "    manifest is missing arm64 platform (FR-B8-COR-072 / NFR-B8-COR-008)" >&2
    return 1
  fi
  # ADR-B8-COR-003 extension : confirm `--config` arg flag remains valid
  # on the 1.20.2 image (templated Deployment passes
  # --config=/etc/coroot/config.yaml ; this guards against an upstream
  # flag rename).
  local help_out
  help_out=$(docker run --rm "$NEW_PIN" --help 2>&1)
  if ! printf '%s' "$help_out" | grep -qE -- '--config|-config'; then
    echo "    coroot 1.20.2 --help does not advertise --config flag (ADR-B8-COR-003)" >&2
    printf '%s\n' "$help_out" | head -20 >&2
    return 1
  fi
}

_test_b8cor_l2_002_old_pin_denied() {
  if [ "${FORGE_B8_COROOT_DOCKER:-0}" != "1" ]; then
    echo "    skipped (FORGE_B8_COROOT_DOCKER unset — opt-in)" >&2
    return 0
  fi
  if ! command -v docker > /dev/null 2>&1; then
    echo "    skipped (docker absent on PATH)" >&2
    return 0
  fi
  # Verify-then-pin invariant : if docker.io public access is re-opened
  # on coroot/coroot:1.4.4, the rationale for the rehost weakens and a
  # follow-up change SHOULD revisit. WARN-only flip per ADR-B8-COR-003
  # footnote — we still hard-fail here so the WARN surfaces in CI ;
  # the maintainer turns it into a follow-up change as needed.
  local out
  out=$(docker manifest inspect "$LEGACY_PIN" 2>&1 || true)
  if ! printf '%s' "$out" | grep -qE 'denied|unauthorized|manifest unknown'; then
    echo "    WARN : $LEGACY_PIN no longer denied on docker.io — verify-then-pin invariant flipped (FR-B8-COR-073)" >&2
    echo "    docker.io public access may have been re-opened ; revisit b8-coroot-rehost rationale." >&2
    printf '%s\n' "$out" | head -10 >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── B.8.8 — b8-coroot-rehost — level $LEVEL ──"

  # L1 always runs.
  run_test _test_b8cor_l1_001_canonical_image_pin
  run_test _test_b8cor_l1_002_canonical_no_dockerio_coroot
  run_test _test_b8cor_l1_003_canonical_audit_comment
  run_test _test_b8cor_l1_004_cli_bundle_template_byte_identity
  run_test _test_b8cor_l1_005_example_rendered_image_pin
  run_test _test_b8cor_l1_006_cli_bundle_example_byte_identity
  run_test _test_b8cor_l1_007_four_copies_only
  run_test _test_b8cor_l1_008_standard_version_bumped
  run_test _test_b8cor_l1_009_standard_coroot_pin_no_vprefix
  run_test _test_b8cor_l1_010_standard_last_reviewed_today
  run_test _test_b8cor_l1_011_review_ledger_appended
  run_test _test_b8cor_l1_012_validate_standards_yaml_passes
  run_test _test_b8cor_l1_013_changelog_entry

  # L2 runs when --level includes 2.
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — ghcr manifest pullable + verify-then-pin (opt-in FORGE_B8_COROOT_DOCKER=1)"
    run_test _test_b8cor_l2_001_ghcr_manifest_pullable
    run_test _test_b8cor_l2_002_old_pin_denied
  fi

  print_summary
}

main "$@"
