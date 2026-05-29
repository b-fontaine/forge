#!/usr/bin/env bash
# Forge — B.8.8 OBI/Beyla refresh harness
# <!-- Audit: B.8.8 (b8-obi-refresh) — observability rearch trio sibling 3 -->
#
# Validates the b8-obi-refresh deliverables :
#
#   - OBI/Beyla image pin refreshed `grafana/beyla:2.0.1` →
#     `grafana/beyla:3.15.0` across 4 mirror copies
#     (FR-B8-OBI-001..007 ; ADR-B8-OBI-001/005 — no v-prefix per
#     observability.yaml convention).
#   - ClusterRole RBAC widened : add `services` resource (read-only)
#     per Beyla 3.x docs (FR-B8-OBI-063 / ADR-B8-OBI-003).
#   - Linux capabilities + kernel-58 nodeSelector UNCHANGED
#     (FR-B8-OBI-060..064 / ADR-B8-OBI-002/004).
#   - `.forge/standards/observability.yaml` bumped v2.0.0 → v2.1.0
#     additive (FR-B8-OBI-030..040 ; `breaking_change: false`).
#   - `.forge/standards/REVIEW.md` Updated ledger row appended
#     (FR-B8-OBI-050..053 ; NOT `ARCH-CHANGE`).
#   - `bin/validate-standards-yaml.sh` exits 0 post-bump (FR-B8-OBI-040).
#   - Snapshot ≤ 716800 B (700 KiB ceiling ADR-B8-SIG-008 / FR-B8-OBI-131).
#   - CHANGELOG entry (FR-B8-OBI-141).
#   - L2 opt-in (FORGE_B8_OBI_DOCKER=1) confirms
#     grafana/beyla:3.15.0 multi-arch pullable (FR-B8-OBI-104 ;
#     ADR-B8-OBI-001 manifest-pull leg).
#
# 22 L1 + 2 L2 = 24 tests.
# Performance budget : L1 ≤ 2 s wall-clock (NFR-B8-OBI-001).

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

OBI_CANONICAL="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl"
OBI_CLI_MIRROR="$FORGE_ROOT_REAL/cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl"
OBI_EXAMPLE="$FORGE_ROOT_REAL/examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml"
OBI_CLI_EXAMPLE_MIRROR="$FORGE_ROOT_REAL/cli/assets/examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml"
OBSERV_YAML="$FORGE_ROOT_REAL/.forge/standards/observability.yaml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
SNAPSHOT="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
VALIDATOR="$FORGE_ROOT_REAL/bin/validate-standards-yaml.sh"

NEW_PIN="grafana/beyla:3.15.0"
OLD_PIN="grafana/beyla:2.0.1"
SNAPSHOT_CEILING=716800   # 700 KiB ceiling per ADR-B8-SIG-008

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (22 tests)
# MANIFEST: _test_b8obi_l1_001_canonical_image_pin                      — FR-B8-OBI-001/-003
# MANIFEST: _test_b8obi_l1_002_canonical_no_old_pin                     — FR-B8-OBI-001
# MANIFEST: _test_b8obi_l1_003_canonical_no_latest                      — FR-B8-OBI-003 negative
# MANIFEST: _test_b8obi_l1_004_canonical_audit_comment                  — FR-B8-OBI-008
# MANIFEST: _test_b8obi_l1_005_cli_bundle_template_byte_identity        — FR-B8-OBI-004
# MANIFEST: _test_b8obi_l1_006_example_rendered_image_pin               — FR-B8-OBI-005
# MANIFEST: _test_b8obi_l1_007_cli_bundle_example_byte_identity         — FR-B8-OBI-006
# MANIFEST: _test_b8obi_l1_008_four_copies_only                         — FR-B8-OBI-007 / ADR-B8-OBI-005
# MANIFEST: _test_b8obi_l1_009_canonical_rbac_services_resource         — FR-B8-OBI-063 / ADR-B8-OBI-003
# MANIFEST: _test_b8obi_l1_010_canonical_caps_unchanged                 — FR-B8-OBI-060..062 / ADR-B8-OBI-002
# MANIFEST: _test_b8obi_l1_011_canonical_kernel_selector_unchanged      — FR-B8-OBI-064 / ADR-B8-OBI-004
# MANIFEST: _test_b8obi_l1_012_standard_version_bumped                  — FR-B8-OBI-030
# MANIFEST: _test_b8obi_l1_013_standard_beyla_pin                       — FR-B8-OBI-031
# MANIFEST: _test_b8obi_l1_014_standard_last_reviewed_today             — FR-B8-OBI-032
# MANIFEST: _test_b8obi_l1_015_standard_expires_at_plus_1y              — FR-B8-OBI-033
# MANIFEST: _test_b8obi_l1_016_standard_pin_cadence_preserved           — FR-B8-OBI-034
# MANIFEST: _test_b8obi_l1_017_standard_breaking_change_false           — FR-B8-OBI-030
# MANIFEST: _test_b8obi_l1_018_review_ledger_updated_row                — FR-B8-OBI-050..052
# MANIFEST: _test_b8obi_l1_019_review_ledger_not_arch_change            — FR-B8-OBI-051 (negative)
# MANIFEST: _test_b8obi_l1_020_validate_standards_yaml_passes           — FR-B8-OBI-040
# MANIFEST: _test_b8obi_l1_021_changelog_entry                          — FR-B8-OBI-141
# MANIFEST: _test_b8obi_l1_022_snapshot_ceiling                         — FR-B8-OBI-131 / ADR-B8-OBI-008
# MANIFEST: _test_b8obi_l1_023_snapshot_determinism                     — NFR-B8-OBI-011 (post-review HIGH fix, snapshot byte-identity across rebuilds)
#
# L2 (2 tests, opt-in via FORGE_B8_OBI_DOCKER=1)
# MANIFEST: _test_b8obi_l2_001_dockerhub_manifest_pullable              — FR-B8-OBI-104 ; ADR-B8-OBI-001
# MANIFEST: _test_b8obi_l2_002_old_pin_informational                    — FR-B8-OBI-106 (informational)

# ─── L1 tests ────────────────────────────────────────────────────

_test_b8obi_l1_001_canonical_image_pin() {
  if [ ! -f "$OBI_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if ! grep -Fq "image: $NEW_PIN" "$OBI_CANONICAL"; then
    echo "    canonical template does not declare 'image: $NEW_PIN' (FR-B8-OBI-001)" >&2
    grep -E 'image:' "$OBI_CANONICAL" >&2 || true
    return 1
  fi
}

_test_b8obi_l1_002_canonical_no_old_pin() {
  if [ ! -f "$OBI_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  # Match the legacy pin only on `image:` lines, so the audit comment
  # block (which references the legacy pin verbatim) does not trigger.
  if grep -Eq '^\s*image:\s*grafana/beyla:2\.' "$OBI_CANONICAL"; then
    echo "    canonical template still uses legacy beyla 2.x pin on an image: line (FR-B8-OBI-001)" >&2
    return 1
  fi
}

_test_b8obi_l1_003_canonical_no_latest() {
  if [ ! -f "$OBI_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if grep -Eq '^\s*image:\s*grafana/beyla:latest\s*$' "$OBI_CANONICAL"; then
    echo "    canonical template uses ':latest' tag (FR-B8-OBI-003 negative)" >&2
    return 1
  fi
}

_test_b8obi_l1_004_canonical_audit_comment() {
  if [ ! -f "$OBI_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if ! grep -Fq "B.8.8 / b8-obi-refresh" "$OBI_CANONICAL"; then
    echo "    canonical template missing audit comment 'B.8.8 / b8-obi-refresh' (FR-B8-OBI-008)" >&2
    return 1
  fi
}

_test_b8obi_l1_005_cli_bundle_template_byte_identity() {
  if [ ! -f "$OBI_CANONICAL" ] || [ ! -f "$OBI_CLI_MIRROR" ]; then
    echo "    canonical or cli/assets mirror missing" >&2; return 1
  fi
  if ! diff -q "$OBI_CANONICAL" "$OBI_CLI_MIRROR" > /dev/null 2>&1; then
    echo "    canonical vs cli/assets mirror diverge (FR-B8-OBI-004 — run 'npm run bundle' from cli/)" >&2
    return 1
  fi
}

_test_b8obi_l1_006_example_rendered_image_pin() {
  if [ ! -f "$OBI_EXAMPLE" ]; then
    echo "    example rendered file missing" >&2; return 1
  fi
  if ! grep -Fq "image: $NEW_PIN" "$OBI_EXAMPLE"; then
    echo "    example rendered file does not declare 'image: $NEW_PIN' (FR-B8-OBI-005)" >&2
    return 1
  fi
}

_test_b8obi_l1_007_cli_bundle_example_byte_identity() {
  if [ ! -f "$OBI_EXAMPLE" ] || [ ! -f "$OBI_CLI_EXAMPLE_MIRROR" ]; then
    echo "    example or cli/assets example mirror missing" >&2; return 1
  fi
  if ! diff -q "$OBI_EXAMPLE" "$OBI_CLI_EXAMPLE_MIRROR" > /dev/null 2>&1; then
    echo "    example vs cli/assets example mirror diverge (FR-B8-OBI-006 — run 'npm run bundle' from cli/)" >&2
    return 1
  fi
}

_test_b8obi_l1_008_four_copies_only() {
  local count
  count=$( ( find "$FORGE_ROOT_REAL" -name "obi-daemonset.yaml" \
                   -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
             find "$FORGE_ROOT_REAL" -name "obi-daemonset.yaml.tmpl" \
                   -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
           ) | wc -l | tr -d ' ')
  if [ "$count" != "4" ]; then
    echo "    expected exactly 4 obi-daemonset file copies, found $count (FR-B8-OBI-007 / ADR-B8-OBI-005)" >&2
    ( find "$FORGE_ROOT_REAL" -name "obi-daemonset.yaml" \
            -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
      find "$FORGE_ROOT_REAL" -name "obi-daemonset.yaml.tmpl" \
            -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null ) >&2
    return 1
  fi
}

_test_b8obi_l1_009_canonical_rbac_services_resource() {
  if [ ! -f "$OBI_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  # Beyla 3.x docs add `services` to the read-only ClusterRole.
  # The line MUST contain pods, nodes, AND services in the same
  # apiGroups: [""] block. Use Python to parse YAML for robustness
  # — bash regex over multiline YAML is brittle.
  if ! python3 - "$OBI_CANONICAL" <<'PY' >/dev/null 2>&1
import sys, re
content = open(sys.argv[1]).read()
# Find the rules: block then the first apiGroups: [""] entry's resources.
m = re.search(r'rules:\s*\n((?:\s+-[^\n]*\n(?:\s+[^\n]+\n)*)+)', content)
if not m:
    sys.exit(1)
rules = m.group(1)
# Look for an apiGroups: [""] rule with resources containing pods, nodes, services.
# Allow either YAML inline list or block-list resources.
for rule_match in re.finditer(r'-\s+apiGroups:\s*\[\s*""\s*\]\s*\n(\s+[^\n]+\n)+', rules):
    block = rule_match.group(0)
    res_match = re.search(r'resources:\s*\[([^\]]+)\]', block)
    if res_match:
        items = [s.strip().strip('"').strip("'") for s in res_match.group(1).split(',')]
        if 'pods' in items and 'nodes' in items and 'services' in items:
            sys.exit(0)
sys.exit(1)
PY
  then
    echo "    canonical ClusterRole apiGroups:[\"\"] is missing 'services' resource (FR-B8-OBI-063 / ADR-B8-OBI-003)" >&2
    return 1
  fi
}

_test_b8obi_l1_010_canonical_caps_unchanged() {
  if [ ! -f "$OBI_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  # ADR-B8-OBI-002 : capability set UNCHANGED. Verify the 8 caps still
  # present + `drop: [ALL]` (or `drop: - ALL` block form).
  local cap
  for cap in BPF SYS_PTRACE NET_RAW CHECKPOINT_RESTORE DAC_READ_SEARCH PERFMON NET_ADMIN SYS_ADMIN; do
    if ! grep -Eq "^\s*-\s*${cap}\s*$" "$OBI_CANONICAL"; then
      echo "    capability $cap missing in canonical (FR-B8-OBI-060 / ADR-B8-OBI-002)" >&2
      return 1
    fi
  done
  if ! grep -Eq "^\s*-\s*ALL\s*$" "$OBI_CANONICAL"; then
    echo "    'drop: [ALL]' missing in canonical (FR-B8-OBI-061)" >&2
    return 1
  fi
}

_test_b8obi_l1_011_canonical_kernel_selector_unchanged() {
  if [ ! -f "$OBI_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if ! grep -Fq 'forge.dev/kernel-min-58: "true"' "$OBI_CANONICAL"; then
    echo "    nodeSelector 'forge.dev/kernel-min-58: \"true\"' missing (FR-B8-OBI-064 / ADR-B8-OBI-004)" >&2
    return 1
  fi
}

_test_b8obi_l1_012_standard_version_bumped() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  if ! grep -Eq '^version:\s*"?2\.1\.0"?\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml::version is not '2.1.0' (FR-B8-OBI-030 — trio sibling 3 additive minor bump)" >&2
    grep -E '^version:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8obi_l1_013_standard_beyla_pin() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  if ! grep -Eq '^\s+beyla:\s*"?3\.15\.0"?\s*(#.*)?$' "$OBSERV_YAML"; then
    echo "    observability.yaml::versions.beyla is not '3.15.0' (FR-B8-OBI-031 — no v-prefix per inline disclaimer)" >&2
    grep -E '^\s+beyla:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8obi_l1_014_standard_last_reviewed_today() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  if ! grep -Eq '^last_reviewed:\s*2026-05-29\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml::last_reviewed is not 2026-05-29 (FR-B8-OBI-032)" >&2
    grep -E '^last_reviewed:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8obi_l1_015_standard_expires_at_plus_1y() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  if ! grep -Eq '^expires_at:\s*2027-05-29\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml::expires_at is not 2027-05-29 (FR-B8-OBI-033)" >&2
    grep -E '^expires_at:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8obi_l1_016_standard_pin_cadence_preserved() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  # pin_review_cadence.beyla MUST stay P12M (ADR-B8-OBI-002 + FR-B8-OBI-034).
  # The cadence map sits below versions; pattern matches indented key with
  # ISO 8601 duration. Re-use the b8-signoz iteration pattern.
  if ! grep -Eq '^\s+beyla:\s*"?P12M"?\s*(#.*)?$' "$OBSERV_YAML"; then
    echo "    pin_review_cadence.beyla is not P12M (FR-B8-OBI-034)" >&2
    grep -E '^\s+beyla:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8obi_l1_017_standard_breaking_change_false() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  # b8-signoz-unified shipped breaking_change: true ; this leg flips to false
  # (additive minor bump per ADR-B8-OBI design.md Article XII gate).
  if ! grep -Eq '^breaking_change:\s*false\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml::breaking_change is not 'false' (FR-B8-OBI-030 ; flipped from sibling 2 ARCH-CHANGE state)" >&2
    grep -E '^breaking_change:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8obi_l1_018_review_ledger_updated_row() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing" >&2; return 1
  fi
  # The new row MUST mention observability.yaml + 2.1.0 + Updated + b8-obi-refresh.
  if ! grep -Eq '\|\s*observability\.yaml\s*\|\s*2\.1\.0\s*\|\s*Updated\s*\|' "$REVIEW_MD"; then
    echo "    REVIEW.md does not contain the v2.1.0 Updated row for observability.yaml (FR-B8-OBI-050..052)" >&2
    return 1
  fi
  if ! grep -Fq "b8-obi-refresh" "$REVIEW_MD"; then
    echo "    REVIEW.md does not cite b8-obi-refresh in the notes (FR-B8-OBI-052)" >&2
    return 1
  fi
}

_test_b8obi_l1_019_review_ledger_not_arch_change() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing" >&2; return 1
  fi
  # FR-B8-OBI-051 negative : the v2.1.0 row must NOT carry the
  # ARCH-CHANGE flag (reserved for breaking shifts). Verify the row
  # explicitly :
  if grep -Eq '\|\s*observability\.yaml\s*\|\s*2\.1\.0\s*\|\s*ARCH-CHANGE\s*\|' "$REVIEW_MD"; then
    echo "    REVIEW.md v2.1.0 row uses ARCH-CHANGE flag — must be Updated (FR-B8-OBI-051)" >&2
    return 1
  fi
}

_test_b8obi_l1_020_validate_standards_yaml_passes() {
  if [ ! -x "$VALIDATOR" ]; then
    echo "    bin/validate-standards-yaml.sh missing or not executable" >&2; return 1
  fi
  if ! "$VALIDATOR" "$OBSERV_YAML" > /dev/null 2>&1; then
    echo "    validate-standards-yaml.sh failed on observability.yaml (FR-B8-OBI-040)" >&2
    "$VALIDATOR" "$OBSERV_YAML" 2>&1 | tail -20 >&2 || true
    return 1
  fi
}

_test_b8obi_l1_021_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing" >&2; return 1
  fi
  if ! grep -Fq "b8-obi-refresh" "$CHANGELOG_MD"; then
    echo "    CHANGELOG.md does not mention b8-obi-refresh (FR-B8-OBI-141)" >&2
    return 1
  fi
}

_test_b8obi_l1_022_snapshot_ceiling() {
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    snapshot tarball missing — run bin/forge-snapshot.sh build full-stack-monorepo 1.0.0" >&2
    return 1
  fi
  local size
  # macOS uses `stat -f%z`, Linux uses `stat -c%s` ; try both.
  size=$(stat -f%z "$SNAPSHOT" 2>/dev/null || stat -c%s "$SNAPSHOT" 2>/dev/null)
  if [ -z "$size" ]; then
    echo "    cannot stat snapshot size" >&2
    return 1
  fi
  if [ "$size" -gt "$SNAPSHOT_CEILING" ]; then
    echo "    snapshot ${size} B exceeds ${SNAPSHOT_CEILING} B ceiling (ADR-B8-SIG-008 / FR-B8-OBI-131)" >&2
    return 1
  fi
}

# NFR-B8-OBI-011 (post-review HIGH fix, 2026-05-29) — snapshot is
# byte-identical across **back-to-back rebuilds with unchanged
# sources**. Patches `bin/forge-snapshot.sh` to enforce
# SOURCE_DATE_EPOCH-pinned mtimes + sorted entry order + uid/gid
# normalised + gzip mtime stripped.
#
# Methodology : delete the canonical artefact, rebuild once (capture
# hash A), delete, rebuild again (capture hash B), assert A == B,
# leave the second build in place (byte-identical to the first by
# definition, so the canonical artefact is preserved). The canonical
# hash that existed before this test ran is NOT used as the
# comparand — it may legitimately differ if any owned source file
# was edited between the previous build and this test run. The
# property under test is **rebuild-vs-rebuild** determinism, not
# rebuild-vs-historical.
_test_b8obi_l1_023_snapshot_determinism() {
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    canonical snapshot missing — run bin/forge-snapshot.sh build full-stack-monorepo 1.0.0" >&2
    return 1
  fi
  local hash_a hash_b
  rm "$SNAPSHOT"
  if ! bash "$FORGE_ROOT_REAL/bin/forge-snapshot.sh" build full-stack-monorepo 1.0.0 > /dev/null 2>&1; then
    echo "    rebuild A failed — bin/forge-snapshot.sh build returned non-zero" >&2
    return 1
  fi
  hash_a=$(shasum -a 256 "$SNAPSHOT" | awk '{print $1}')
  rm "$SNAPSHOT"
  if ! bash "$FORGE_ROOT_REAL/bin/forge-snapshot.sh" build full-stack-monorepo 1.0.0 > /dev/null 2>&1; then
    echo "    rebuild B failed — bin/forge-snapshot.sh build returned non-zero" >&2
    return 1
  fi
  hash_b=$(shasum -a 256 "$SNAPSHOT" | awk '{print $1}')
  if [ "$hash_a" != "$hash_b" ]; then
    echo "    snapshot is NOT deterministic (NFR-B8-OBI-011) — A=$hash_a B=$hash_b" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in) ───────────────────────────────────────────

_test_b8obi_l2_001_dockerhub_manifest_pullable() {
  if [ "${FORGE_B8_OBI_DOCKER:-0}" != "1" ]; then
    echo "    skipped (FORGE_B8_OBI_DOCKER unset — opt-in)" >&2
    return 0
  fi
  if ! command -v docker > /dev/null 2>&1; then
    echo "    skipped (docker absent on PATH)" >&2
    return 0
  fi
  local out
  out=$(docker manifest inspect "$NEW_PIN" 2>&1)
  if [ $? -ne 0 ]; then
    echo "    docker manifest inspect $NEW_PIN failed (FR-B8-OBI-104)" >&2
    printf '%s\n' "$out" | head -20 >&2
    return 1
  fi
  if ! printf '%s' "$out" | grep -Eq '"architecture"[[:space:]]*:[[:space:]]*"amd64"'; then
    echo "    manifest missing amd64 platform (FR-B8-OBI-104)" >&2
    return 1
  fi
  if ! printf '%s' "$out" | grep -Eq '"architecture"[[:space:]]*:[[:space:]]*"arm64"'; then
    echo "    manifest missing arm64 platform (FR-B8-OBI-104)" >&2
    return 1
  fi
}

_test_b8obi_l2_002_old_pin_informational() {
  if [ "${FORGE_B8_OBI_DOCKER:-0}" != "1" ]; then
    echo "    skipped (FORGE_B8_OBI_DOCKER unset — opt-in)" >&2
    return 0
  fi
  if ! command -v docker > /dev/null 2>&1; then
    echo "    skipped (docker absent on PATH)" >&2
    return 0
  fi
  # FR-B8-OBI-106 : MAY succeed (Beyla 2.0.1 not routinely yanked) ;
  # MAY fail (yanked) ; both outcomes informational. Capture but never
  # fail.
  local out
  out=$(docker manifest inspect "$OLD_PIN" 2>&1 || true)
  if printf '%s' "$out" | grep -qE 'denied|unauthorized|manifest unknown'; then
    echo "    INFO : $OLD_PIN no longer pullable (Grafana yanked) — note for audit trail" >&2
  fi
  return 0
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── B.8.8 — b8-obi-refresh — level $LEVEL ──"

  # L1 always runs.
  run_test _test_b8obi_l1_001_canonical_image_pin
  run_test _test_b8obi_l1_002_canonical_no_old_pin
  run_test _test_b8obi_l1_003_canonical_no_latest
  run_test _test_b8obi_l1_004_canonical_audit_comment
  run_test _test_b8obi_l1_005_cli_bundle_template_byte_identity
  run_test _test_b8obi_l1_006_example_rendered_image_pin
  run_test _test_b8obi_l1_007_cli_bundle_example_byte_identity
  run_test _test_b8obi_l1_008_four_copies_only
  run_test _test_b8obi_l1_009_canonical_rbac_services_resource
  run_test _test_b8obi_l1_010_canonical_caps_unchanged
  run_test _test_b8obi_l1_011_canonical_kernel_selector_unchanged
  run_test _test_b8obi_l1_012_standard_version_bumped
  run_test _test_b8obi_l1_013_standard_beyla_pin
  run_test _test_b8obi_l1_014_standard_last_reviewed_today
  run_test _test_b8obi_l1_015_standard_expires_at_plus_1y
  run_test _test_b8obi_l1_016_standard_pin_cadence_preserved
  run_test _test_b8obi_l1_017_standard_breaking_change_false
  run_test _test_b8obi_l1_018_review_ledger_updated_row
  run_test _test_b8obi_l1_019_review_ledger_not_arch_change
  run_test _test_b8obi_l1_020_validate_standards_yaml_passes
  run_test _test_b8obi_l1_021_changelog_entry
  run_test _test_b8obi_l1_022_snapshot_ceiling
  run_test _test_b8obi_l1_023_snapshot_determinism

  # L2 runs when --level includes 2.
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — Docker Hub manifest pullable + old-pin informational (opt-in FORGE_B8_OBI_DOCKER=1)"
    run_test _test_b8obi_l2_001_dockerhub_manifest_pullable
    run_test _test_b8obi_l2_002_old_pin_informational
  fi

  print_summary
}

main "$@"
