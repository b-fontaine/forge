#!/usr/bin/env bash
# Forge — B.8.8 SigNoz 3-svc → unified arch harness
# <!-- Audit: B.8.8 (b8-signoz-unified) — SigNoz 3-svc → unified arch -->
#
# Validates the b8-signoz-unified deliverables :
#
#   - docker-compose.dev.yml.tmpl migrated 3-service SigNoz
#     (signoz/frontend + signoz/query-service + otel-collector-contrib)
#     → unified arch : signoz/signoz:v0.125.1 +
#     signoz/signoz-otel-collector:v0.144.4 + clickhouse 25.5.6 +
#     signoz/zookeeper:3.7.1 (4 long-running) + init-clickhouse +
#     telemetrystore-migrator (2 init) across 6 mirror copies
#     (FR-B8-SIG-A-* / FR-B8-SIG-G-* ; ADR-B8-SIG-001..004,007).
#   - .forge/standards/observability.yaml bumped v1.2.0 → v2.0.0
#     BREAKING : versions surgery + ISO 8601 pin_review_cadence: +
#     WAIVER (ADR-J7-004) + breaking_change: true (FR-B8-SIG-B-*).
#   - .forge/standards/REVIEW.md ARCH-CHANGE ledger entry (FR-B8-SIG-H-002).
#   - bin/validate-standards-yaml.sh exits 0 post-bump (FR-B8-SIG-C-001).
#   - CHANGELOG entry (FR-B8-SIG-H-003).
#   - snapshot tarball regenerated within the 700 KiB ceiling (ADR-B8-SIG-008),
#     cli-bundle snapshot mirror byte-identical, and inline compose carries the
#     unified pin (FR-B8-SIG-D-001/-002/-003).
#   - L2 opt-in (FORGE_B8_SIGNOZ_DOCKER=1) confirms the 4 pins multi-arch
#     pullable + rotted 3-svc pins denied + compose-up healthy
#     (FR-B8-SIG-E-016..018 ; ADR-B8-SIG-001..007 ; verify-then-pin T5.3.2).
#
# 20 L1 + 6 L2 = 26 tests.
# Performance budget : L1 ≤ 2 s wall-clock (NFR-B8-SIG-003).
# L2 budget : ≤ 180 s end-to-end (NFR-B8-SIG-004).

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

# ─── Path constants (Implementer Notes 4-6 — NO 1.0.0/infra/ segment) ──
ARCH_BASE=".forge/templates/archetypes/full-stack-monorepo"
SIG_CANONICAL="$FORGE_ROOT_REAL/$ARCH_BASE/docker-compose.dev.yml.tmpl"
SIG_CLI_TMPL="$FORGE_ROOT_REAL/cli/assets/$ARCH_BASE/docker-compose.dev.yml.tmpl"
SIG_EXAMPLE="$FORGE_ROOT_REAL/examples/forge-fsm-example/docker-compose.dev.yml"
SIG_CLI_EXAMPLE="$FORGE_ROOT_REAL/cli/assets/examples/forge-fsm-example/docker-compose.dev.yml"
SIG_EXAMPLE_TMPL="$FORGE_ROOT_REAL/examples/forge-fsm-example/$ARCH_BASE/docker-compose.dev.yml.tmpl"
SIG_CLI_EXAMPLE_TMPL="$FORGE_ROOT_REAL/cli/assets/examples/forge-fsm-example/$ARCH_BASE/docker-compose.dev.yml.tmpl"
OBSERV_YAML="$FORGE_ROOT_REAL/.forge/standards/observability.yaml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
SNAPSHOT="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
SNAPSHOT_CLI="$FORGE_ROOT_REAL/cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
VALIDATOR="$FORGE_ROOT_REAL/bin/validate-standards-yaml.sh"

# Pin constants (verify-then-pin'd live 2026-05-27 — evidence.md § 2).
SIG_PIN="signoz/signoz:v0.125.1"
COLLECTOR_PIN="signoz/signoz-otel-collector:v0.144.4"
CH_PIN="clickhouse/clickhouse-server:25.5.6"
ZK_PIN="signoz/zookeeper:3.7.1"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (20 tests)
# MANIFEST: _test_b8sig_l1_001_canonical_pins                  — FR-B8-SIG-E-003/-004 / A-001/-002
# MANIFEST: _test_b8sig_l1_002_canonical_no_rotted_pins        — FR-B8-SIG-E-005 / A-003
# MANIFEST: _test_b8sig_l1_003_canonical_sidecar_pins          — ADR-B8-SIG-002/-007 / A-004
# MANIFEST: _test_b8sig_l1_004_audit_comment_present           — FR-B8-SIG-E-006 / A-010
# MANIFEST: _test_b8sig_l1_005_ui_port_envvar                  — FR-B8-SIG-A-007 / ADR-004
# MANIFEST: _test_b8sig_l1_006_otlp_ports                      — FR-B8-SIG-A-008
# MANIFEST: _test_b8sig_l1_007_healthchecks_restart            — FR-B8-SIG-A-011/-012
# MANIFEST: _test_b8sig_l1_008_standard_version_v200           — FR-B8-SIG-E-007 / B-001
# MANIFEST: _test_b8sig_l1_009_standard_signoz_pin             — FR-B8-SIG-E-008/-009 / B-002/-003
# MANIFEST: _test_b8sig_l1_010_no_legacy_version_keys          — FR-B8-SIG-B-004
# MANIFEST: _test_b8sig_l1_011_pin_review_cadence              — FR-B8-SIG-E-010 / B-005 / ADR-005
# MANIFEST: _test_b8sig_l1_012_last_reviewed_expires           — FR-B8-SIG-E-011 / B-007/-008
# MANIFEST: _test_b8sig_l1_013_waiver_cite_appendonly          — FR-B8-SIG-E-012 / B-009 (Article V WAIVER + ADR-J7-004 cite preserved)
# MANIFEST: _test_b8sig_l1_014_review_ledger_arch_change       — FR-B8-SIG-E-013 / H-002
# MANIFEST: _test_b8sig_l1_015_validate_standards_yaml         — FR-B8-SIG-E-014 / C-001/-002
# MANIFEST: _test_b8sig_l1_016_changelog_entry                 — FR-B8-SIG-E-015 / H-003
# MANIFEST: _test_b8sig_l1_017_mirror_count                    — FR-B8-SIG-G-001..005
# MANIFEST: _test_b8sig_l1_018_snapshot_exists_within_budget   — FR-B8-SIG-D-001 / ADR-B8-SIG-008
# MANIFEST: _test_b8sig_l1_019_snapshot_cli_mirror_identical   — FR-B8-SIG-D-003
# MANIFEST: _test_b8sig_l1_020_snapshot_carries_unified_pin    — FR-B8-SIG-D-001/-002
# MANIFEST: _test_b8sig_l1_021_breaking_change_field_present   — FR-B8-SIG-B-010 (split 2026-05-29 post-review MEDIUM — value owned by current-version harness)
#
# L2 (6 tests, opt-in via FORGE_B8_SIGNOZ_DOCKER=1)
# MANIFEST: _test_b8sig_l2_001_signoz_manifest_pullable        — FR-B8-SIG-E-016 / NFR-004
# MANIFEST: _test_b8sig_l2_002_collector_manifest_pullable     — FR-B8-SIG-E-017 / NFR-004
# MANIFEST: _test_b8sig_l2_003_clickhouse_manifest_pullable    — ADR-B8-SIG-002 / NFR-004
# MANIFEST: _test_b8sig_l2_004_zookeeper_manifest_pullable     — ADR-B8-SIG-007 / NFR-004
# MANIFEST: _test_b8sig_l2_005_compose_up_healthy              — FR-B8-SIG-E-018 / NFR-004
# MANIFEST: _test_b8sig_l2_006_old_pins_denied                 — FR-B8-SIG-A-003 / NFR-004

# ─── L1 helpers ──────────────────────────────────────────────────

# Strip the audit-comment block so rotted-pin greps do not match the
# historical context inside it (FR-B8-SIG-A-003 carve-out). The audit
# block is delimited by the FR-B8-SIG-A-010 banner line and runs until
# the next non-comment line.
_sig_body_without_audit() {
  # Drop every line that is a YAML comment (starts with optional
  # whitespace then '#'). Image: lines and structural YAML survive.
  grep -vE '^\s*#' "$1" 2>/dev/null
}

# ─── L1 tests ────────────────────────────────────────────────────

_test_b8sig_l1_001_canonical_pins() {
  if [ ! -f "$SIG_CANONICAL" ]; then
    echo "    canonical template missing: $SIG_CANONICAL" >&2; return 1
  fi
  if ! grep -Fq "image: $SIG_PIN" "$SIG_CANONICAL"; then
    echo "    canonical missing 'image: $SIG_PIN' (FR-B8-SIG-A-001)" >&2; return 1
  fi
  if ! grep -Fq "image: $COLLECTOR_PIN" "$SIG_CANONICAL"; then
    echo "    canonical missing 'image: $COLLECTOR_PIN' (FR-B8-SIG-A-002)" >&2; return 1
  fi
}

_test_b8sig_l1_002_canonical_no_rotted_pins() {
  if [ ! -f "$SIG_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  local body; body="$(_sig_body_without_audit "$SIG_CANONICAL")"
  local needle
  for needle in "signoz/frontend" "signoz/query-service" "otel/opentelemetry-collector-contrib" ":0.55.1"; do
    if printf '%s' "$body" | grep -Fq -- "$needle"; then
      echo "    canonical still contains rotted substring '$needle' outside audit block (FR-B8-SIG-A-003)" >&2
      return 1
    fi
  done
}

_test_b8sig_l1_003_canonical_sidecar_pins() {
  if [ ! -f "$SIG_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if ! grep -Fq "image: $CH_PIN" "$SIG_CANONICAL"; then
    echo "    canonical missing 'image: $CH_PIN' (ADR-B8-SIG-002 / FR-B8-SIG-A-004)" >&2; return 1
  fi
  if ! grep -Fq "image: $ZK_PIN" "$SIG_CANONICAL"; then
    echo "    canonical missing 'image: $ZK_PIN' (ADR-B8-SIG-007)" >&2; return 1
  fi
}

_test_b8sig_l1_004_audit_comment_present() {
  if [ ! -f "$SIG_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  if ! grep -Fq "B.8.8 / b8-signoz-unified" "$SIG_CANONICAL"; then
    echo "    canonical missing audit-comment block 'B.8.8 / b8-signoz-unified' (FR-B8-SIG-A-010)" >&2
    return 1
  fi
}

_test_b8sig_l1_005_ui_port_envvar() {
  if [ ! -f "$SIG_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  # ADR-004 env-var indirection : host ${SIGNOZ_UI_PORT:-3301} → ctr 8080.
  if ! grep -Fq '${SIGNOZ_UI_PORT:-3301}:8080' "$SIG_CANONICAL"; then
    echo "    canonical missing UI port mapping '\${SIGNOZ_UI_PORT:-3301}:8080' (FR-B8-SIG-A-007 / ADR-004)" >&2
    return 1
  fi
}

_test_b8sig_l1_006_otlp_ports() {
  if [ ! -f "$SIG_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  # FR-B8-SIG-A-008 : OTLP gRPC :4317 + HTTP :4318 host-published. Since the
  # Aegis FIX 3 loopback-bind, the publish form is "127.0.0.1:4317:4317"
  # (host-side bound to loopback, not 0.0.0.0). Accept the loopback-prefixed
  # form (and tolerate a bare "4317:4317" for backward-compat) ; reject if the
  # port pair is absent entirely.
  if ! grep -Eq '"(127\.0\.0\.1:)?4317:4317"' "$SIG_CANONICAL"; then
    echo "    canonical missing OTLP gRPC port 4317:4317 (FR-B8-SIG-A-008)" >&2; return 1
  fi
  if ! grep -Eq '"(127\.0\.0\.1:)?4318:4318"' "$SIG_CANONICAL"; then
    echo "    canonical missing OTLP HTTP port 4318:4318 (FR-B8-SIG-A-008)" >&2; return 1
  fi
  # Assert the dev loopback-bind posture explicitly (Aegis FIX 3) : OTLP MUST
  # bind 127.0.0.1, never 0.0.0.0 on the host side.
  if ! grep -Eq '"127\.0\.0\.1:4317:4317"' "$SIG_CANONICAL"; then
    echo "    OTLP gRPC :4317 not loopback-bound (127.0.0.1) — dev security posture (Aegis FIX 3)" >&2; return 1
  fi
}

_test_b8sig_l1_007_healthchecks_restart() {
  if [ ! -f "$SIG_CANONICAL" ]; then
    echo "    canonical template missing" >&2; return 1
  fi
  # 4 long-running services each declare a healthcheck + restart:
  # unless-stopped ; 2 init containers declare restart: on-failure.
  local hc_count restart_unless restart_onfail
  hc_count=$(grep -cE '^\s+healthcheck:' "$SIG_CANONICAL")
  restart_unless=$(grep -cE '^\s+restart:\s*unless-stopped' "$SIG_CANONICAL")
  restart_onfail=$(grep -cE '^\s+restart:\s*on-failure' "$SIG_CANONICAL")
  # >= 4 healthchecks (the 4 SigNoz long-running ; fsm-db/backend/kong
  # already carry their own and are also counted, so >=4 is the floor).
  if [ "$hc_count" -lt 4 ]; then
    echo "    canonical declares < 4 healthcheck blocks (got $hc_count) (FR-B8-SIG-A-011)" >&2
    return 1
  fi
  if [ "$restart_unless" -lt 4 ]; then
    echo "    canonical declares < 4 'restart: unless-stopped' (got $restart_unless) (FR-B8-SIG-A-011)" >&2
    return 1
  fi
  if [ "$restart_onfail" -lt 2 ]; then
    echo "    canonical declares < 2 'restart: on-failure' init containers (got $restart_onfail) (FR-B8-SIG-A-012)" >&2
    return 1
  fi
}

_test_b8sig_l1_008_standard_version_v200() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  # Widened 2026-05-29 by b8-obi-refresh (ADR-B8-OBI-006) — leg 3 bumped
  # additive 2.0.0 → 2.1.0. FR-B8-SIG-B-001 owns the major-bump invariant
  # (v1.x → v2.x), not a frozen v2.0.0. Accept 2.x.y line so future
  # additive minor bumps don't trigger sibling-harness churn.
  if ! grep -Eq '^version:\s*"?2\.[0-9]+\.[0-9]+"?\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml::version is not in v2.x.y line (FR-B8-SIG-B-001 ; widened by leg 3 b8-obi-refresh)" >&2
    grep -E '^version:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8sig_l1_009_standard_signoz_pin() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  # v-prefix MANDATORY on signoz repos (evidence § 1.4 — opposite coroot/beyla).
  if ! grep -Eq '^\s+signoz:\s*"?v0\.125\.1"?\s*(#.*)?$' "$OBSERV_YAML"; then
    echo "    observability.yaml::versions.signoz is not 'v0.125.1' (FR-B8-SIG-B-002)" >&2
    return 1
  fi
  if ! grep -Eq '^\s+signoz_otel_collector:\s*"?v0\.144\.4"?\s*(#.*)?$' "$OBSERV_YAML"; then
    echo "    observability.yaml::versions.signoz_otel_collector is not 'v0.144.4' (FR-B8-SIG-B-003)" >&2
    return 1
  fi
  if ! grep -Eq '^\s+clickhouse:\s*"?25\.5\.6"?\s*(#.*)?$' "$OBSERV_YAML"; then
    echo "    observability.yaml::versions.clickhouse is not '25.5.6' (ADR-B8-SIG-002)" >&2
    return 1
  fi
  if ! grep -Eq '^\s+signoz_zookeeper:\s*"?3\.7\.1"?\s*(#.*)?$' "$OBSERV_YAML"; then
    echo "    observability.yaml::versions.signoz_zookeeper is not '3.7.1' (ADR-B8-SIG-007)" >&2
    return 1
  fi
}

_test_b8sig_l1_010_no_legacy_version_keys() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  local key
  for key in "signoz_frontend" "signoz_query_service" "otel_collector_contrib"; do
    if grep -Eq "^\s+${key}:\s*" "$OBSERV_YAML"; then
      echo "    observability.yaml still declares legacy versions key '${key}:' (FR-B8-SIG-B-004)" >&2
      return 1
    fi
  done
}

_test_b8sig_l1_011_pin_review_cadence() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  if ! grep -Eq '^pin_review_cadence:\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml missing top-level 'pin_review_cadence:' map (FR-B8-SIG-B-005 / ADR-005)" >&2
    return 1
  fi
  # ISO 8601 durations (P30D / P12M) per Implementer Note 1. Require the
  # 6 component keys each with an ISO 8601 duration value.
  local comp
  for comp in signoz signoz_otel_collector clickhouse signoz_zookeeper beyla coroot; do
    if ! grep -Eq "^\s+${comp}:\s*\"?P[0-9]+[DMY]\"?" "$OBSERV_YAML"; then
      echo "    pin_review_cadence.${comp} missing or not ISO 8601 (P30D/P12M) (FR-B8-SIG-B-005 / Note 1)" >&2
      return 1
    fi
  done
}

_test_b8sig_l1_012_last_reviewed_expires() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  # Widened 2026-05-29 by b8-obi-refresh (ADR-B8-OBI-006 1-char date regex
  # widening) — trio sibling 3 refreshed dates to 2026-05-29 / 2027-05-29.
  # The widening accepts 2026-05-2[6789] / 2027-05-2[6789] so future trio
  # legs landing inside the window can refresh without a sibling-harness sweep.
  if ! grep -Eq '^last_reviewed:\s*2026-05-2[6789]\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml::last_reviewed is not in 2026-05-2[6789] window (FR-B8-SIG-B-007 ; widened by b8-obi-refresh ADR-B8-OBI-006)" >&2
    grep -E '^last_reviewed:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
  if ! grep -Eq '^expires_at:\s*2027-05-2[6789]\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml::expires_at is not in 2027-05-2[6789] window (FR-B8-SIG-B-008 ; widened by b8-obi-refresh ADR-B8-OBI-006)" >&2
    grep -E '^expires_at:' "$OBSERV_YAML" >&2 || true
    return 1
  fi
}

_test_b8sig_l1_013_waiver_cite_appendonly() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  # STRICT — the WAIVER block + ADR-J7-004 citation shipped by
  # b8-signoz-unified are Article V append-only historical evidence
  # of the v1.2.0 → v2.0.0 BREAKING bump. They MUST remain
  # byte-identical across all subsequent additive bumps. The
  # current-version `breaking_change:` value is **NOT** asserted
  # here — value ownership transferred to the harness owning the
  # current standard version (b8-obi.test.sh
  # `_test_b8obi_l1_017_standard_breaking_change_false`, post-2026-05-29).
  # Field-presence (the boolean must exist with either value) is
  # asserted by sibling test 021 below — split out of this test on
  # 2026-05-29 (b8-obi-refresh post-review MEDIUM fix) so the test
  # name no longer misrepresents what it asserts.
  if ! grep -Fq "WAIVER" "$OBSERV_YAML"; then
    echo "    observability.yaml missing WAIVER block (FR-B8-SIG-B-009 ; Article V append-only)" >&2; return 1
  fi
  if ! grep -Fq "ADR-J7-004" "$OBSERV_YAML"; then
    echo "    observability.yaml WAIVER does not cite ADR-J7-004 (Implementer Note 2 / FR-B8-SIG-B-009)" >&2
    return 1
  fi
}

_test_b8sig_l1_014_review_ledger_arch_change() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing" >&2; return 1
  fi
  # FR-B8-SIG-H-002 ARCH-CHANGE flag (NOT 'Updated'). Match within a
  # section that names 2026-05-26 + ARCH-CHANGE + observability.yaml +
  # b8-signoz-unified (tolerant of intervening text / table layout).
  if ! grep -Pzoq '(?s)2026-05-26.*?ARCH-CHANGE.*?observability\.yaml.*?b8-signoz-unified' "$REVIEW_MD" 2>/dev/null; then
    # Fallback for grep builds lacking -P : require all four tokens present.
    if grep -Fq "ARCH-CHANGE" "$REVIEW_MD" \
       && grep -Fq "b8-signoz-unified" "$REVIEW_MD" \
       && grep -Fq "2026-05-26" "$REVIEW_MD" \
       && grep -Fq "observability.yaml" "$REVIEW_MD"; then
      return 0
    fi
    echo "    REVIEW.md missing ARCH-CHANGE entry for observability.yaml / b8-signoz-unified dated 2026-05-26 (FR-B8-SIG-H-002)" >&2
    return 1
  fi
}

_test_b8sig_l1_015_validate_standards_yaml() {
  if [ ! -x "$VALIDATOR" ]; then
    echo "    bin/validate-standards-yaml.sh missing or not executable" >&2; return 1
  fi
  if ! "$VALIDATOR" "$OBSERV_YAML" > /dev/null 2>&1; then
    echo "    validate-standards-yaml.sh failed on observability.yaml (FR-B8-SIG-C-001)" >&2
    "$VALIDATOR" "$OBSERV_YAML" 2>&1 | tail -20 >&2 || true
    return 1
  fi
}

_test_b8sig_l1_016_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing" >&2; return 1
  fi
  if ! grep -Fq "b8-signoz-unified" "$CHANGELOG_MD"; then
    echo "    CHANGELOG.md does not mention b8-signoz-unified (FR-B8-SIG-H-003)" >&2
    return 1
  fi
}

_test_b8sig_l1_017_mirror_count() {
  # 6-copy mirror inventory resolves (Implementer Note 4) and all 6
  # carry the unified pins. Resolves FR-B8-SIG-G-005 → 6.
  local f missing=0
  for f in "$SIG_CANONICAL" "$SIG_CLI_TMPL" "$SIG_EXAMPLE" "$SIG_CLI_EXAMPLE" \
           "$SIG_EXAMPLE_TMPL" "$SIG_CLI_EXAMPLE_TMPL"; do
    if [ ! -f "$f" ]; then
      echo "    mirror copy missing: $f (FR-B8-SIG-G-005)" >&2
      missing=1
    fi
  done
  [ "$missing" = "0" ] || return 1

  # Exactly 6 copies on disk, no 7th.
  local count
  count=$(find "$FORGE_ROOT_REAL" -name 'docker-compose*.yml*' \
            -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" != "6" ]; then
    echo "    expected exactly 6 docker-compose copies, found $count (FR-B8-SIG-G-005)" >&2
    find "$FORGE_ROOT_REAL" -name 'docker-compose*.yml*' \
      -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null >&2
    return 1
  fi

  # Every copy declares the unified signoz + collector pins.
  for f in "$SIG_CANONICAL" "$SIG_CLI_TMPL" "$SIG_EXAMPLE" "$SIG_CLI_EXAMPLE" \
           "$SIG_EXAMPLE_TMPL" "$SIG_CLI_EXAMPLE_TMPL"; do
    if ! grep -Fq "image: $SIG_PIN" "$f"; then
      echo "    mirror copy missing unified pin '$SIG_PIN': $f (FR-B8-SIG-G-002/-003/-004)" >&2
      return 1
    fi
    if ! grep -Fq "image: $COLLECTOR_PIN" "$f"; then
      echo "    mirror copy missing collector pin '$COLLECTOR_PIN': $f (FR-B8-SIG-G-002/-003/-004)" >&2
      return 1
    fi
  done

  # .tmpl pairs byte-identical (canonical → cli ; example-tmpl → cli) ;
  # rendered example pair byte-identical.
  if ! diff -q "$SIG_CANONICAL" "$SIG_CLI_TMPL" > /dev/null 2>&1; then
    echo "    canonical .tmpl vs cli-bundle .tmpl diverge (FR-B8-SIG-G-002 — run 'npm run bundle')" >&2
    return 1
  fi
  if ! diff -q "$SIG_EXAMPLE_TMPL" "$SIG_CLI_EXAMPLE_TMPL" > /dev/null 2>&1; then
    echo "    example .tmpl vs cli-bundle example .tmpl diverge (FR-B8-SIG-G-002)" >&2
    return 1
  fi
  if ! diff -q "$SIG_EXAMPLE" "$SIG_CLI_EXAMPLE" > /dev/null 2>&1; then
    echo "    rendered example vs cli-bundle rendered example diverge (FR-B8-SIG-G-004)" >&2
    return 1
  fi
}

# ─── L1 snapshot tests (FR-B8-SIG-D-001/-002/-003) ───────────────

_test_b8sig_l1_018_snapshot_exists_within_budget() {
  # FR-B8-SIG-D-001 : snapshot tarball exists + is within the CI-enforced
  # size ceiling. The AUTHORITATIVE gate is t5.test.sh::_test_t5_024
  # (ADR-B8-SIG-008 bumped it 640 KiB → 700 KiB) ; this test asserts the
  # SAME 716800 B ceiling so the two stay in lockstep on any future bump.
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    missing snapshot tarball: $SNAPSHOT (FR-B8-SIG-D-001)" >&2
    return 1
  fi
  local size_bytes; size_bytes="$(wc -c <"$SNAPSHOT" | tr -d ' ')"
  local budget_bytes=716800  # 700 KiB — keep in lockstep with t5.test.sh::_test_t5_024 (ADR-B8-SIG-008)
  if [ "$size_bytes" -gt "$budget_bytes" ]; then
    echo "    snapshot $size_bytes B > $budget_bytes B ceiling (700 KiB ; authoritative gate = t5_024 / ADR-B8-SIG-008)" >&2
    return 1
  fi
}

_test_b8sig_l1_019_snapshot_cli_mirror_identical() {
  # FR-B8-SIG-D-003 : the canonical snapshot and the cli-bundle snapshot
  # mirror MUST be byte-identical after `npm run bundle` (mirrors the
  # b8-coroot.test.sh / a7.test.sh cli-mirror diff discipline).
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    missing canonical snapshot: $SNAPSHOT (FR-B8-SIG-D-003)" >&2
    return 1
  fi
  if [ ! -f "$SNAPSHOT_CLI" ]; then
    echo "    missing cli-bundle snapshot mirror: $SNAPSHOT_CLI (FR-B8-SIG-D-003 — run 'npm run bundle')" >&2
    return 1
  fi
  if ! cmp -s "$SNAPSHOT" "$SNAPSHOT_CLI"; then
    echo "    canonical snapshot vs cli-bundle snapshot diverge (FR-B8-SIG-D-003 — run 'npm run bundle')" >&2
    return 1
  fi
}

_test_b8sig_l1_020_snapshot_carries_unified_pin() {
  # FR-B8-SIG-D-001/-002 : the snapshot's INLINE docker-compose.dev.yml(.tmpl)
  # carries the unified signoz/signoz:v0.125.1 pin — proves the regen
  # captured the 3-svc → unified rewrite (not a stale tarball). Extract the
  # tarball in-memory via Python tarfile (cross-platform, mirrors t5_023).
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    missing snapshot tarball: $SNAPSHOT (FR-B8-SIG-D-001)" >&2
    return 1
  fi
  python3 - "$SNAPSHOT" "$SIG_PIN" <<'PY' || return 1
import sys, tarfile
snap, pin = sys.argv[1], sys.argv[2]
try:
    with tarfile.open(snap, 'r:gz') as t:
        composes = [m for m in t.getmembers()
                    if m.isfile() and 'docker-compose.dev.yml' in m.name]
        if not composes:
            print("    snapshot contains no docker-compose.dev.yml(.tmpl) entry", file=sys.stderr)
            sys.exit(1)
        found = False
        for m in composes:
            f = t.extractfile(m)
            if f is None:
                continue
            body = f.read().decode('utf-8', 'replace')
            if ('image: ' + pin) in body:
                found = True
                break
        if not found:
            print(f"    no snapshot docker-compose carries 'image: {pin}' "
                  f"(checked {len(composes)} entries) — regen did not capture the unified rewrite",
                  file=sys.stderr)
            print(f"    (regen via bin/forge-snapshot.sh build full-stack-monorepo 1.0.0)", file=sys.stderr)
            sys.exit(1)
except Exception as e:
    print(f"    tarfile open/scan failed: {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# Split out of _test_b8sig_l1_013 on 2026-05-29 (b8-obi-refresh
# post-review MEDIUM fix). The original test asserted both the
# Article V WAIVER cite (kept strict in 013) AND `breaking_change:
# true` (value-pinned to v2.0.0 ; not portable across additive
# minor bumps). This new test asserts the boolean field is present
# with EITHER `true` or `false` value — proving the schema slot
# is preserved across trio refreshes, without claiming a specific
# historical value. The CURRENT value belongs to the
# current-version owner harness (e.g. b8-obi.test.sh
# `_test_b8obi_l1_017_standard_breaking_change_false` for v2.1.0).
_test_b8sig_l1_021_breaking_change_field_present() {
  if [ ! -f "$OBSERV_YAML" ]; then
    echo "    observability.yaml missing" >&2; return 1
  fi
  if ! grep -Eq '^breaking_change:\s*(true|false)\s*$' "$OBSERV_YAML"; then
    echo "    observability.yaml missing 'breaking_change:' boolean field (FR-B8-SIG-B-010 ; field-presence invariant — value owned by current-version harness)" >&2
    return 1
  fi
}

# ─── L2 helpers ──────────────────────────────────────────────────

_l2_gate_unmet() {
  if [ "${FORGE_B8_SIGNOZ_DOCKER:-0}" != "1" ]; then
    echo "    skipped (FORGE_B8_SIGNOZ_DOCKER unset — opt-in)" >&2
    return 0
  fi
  if ! command -v docker > /dev/null 2>&1; then
    echo "    skipped (docker absent on PATH)" >&2
    return 0
  fi
  return 1  # gate met — do NOT skip
}

_l2_assert_manifest_multiarch() {
  local pin="$1" fr="$2"
  local out
  out=$(docker manifest inspect "$pin" 2>&1)
  if [ $? -ne 0 ]; then
    echo "    docker manifest inspect $pin failed ($fr)" >&2
    printf '%s\n' "$out" | head -20 >&2
    return 1
  fi
  if ! printf '%s' "$out" | grep -Eq '"architecture"[[:space:]]*:[[:space:]]*"amd64"'; then
    echo "    $pin manifest missing amd64 ($fr / NFR-B8-SIG-004)" >&2
    return 1
  fi
  if ! printf '%s' "$out" | grep -Eq '"architecture"[[:space:]]*:[[:space:]]*"arm64"'; then
    echo "    $pin manifest missing arm64 ($fr / NFR-B8-SIG-004)" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in) ───────────────────────────────────────────

_test_b8sig_l2_001_signoz_manifest_pullable() {
  if _l2_gate_unmet; then return 0; fi
  _l2_assert_manifest_multiarch "$SIG_PIN" "FR-B8-SIG-E-016"
}

_test_b8sig_l2_002_collector_manifest_pullable() {
  if _l2_gate_unmet; then return 0; fi
  _l2_assert_manifest_multiarch "$COLLECTOR_PIN" "FR-B8-SIG-E-017"
}

_test_b8sig_l2_003_clickhouse_manifest_pullable() {
  if _l2_gate_unmet; then return 0; fi
  _l2_assert_manifest_multiarch "$CH_PIN" "ADR-B8-SIG-002"
}

_test_b8sig_l2_004_zookeeper_manifest_pullable() {
  if _l2_gate_unmet; then return 0; fi
  _l2_assert_manifest_multiarch "$ZK_PIN" "ADR-B8-SIG-007"
}

_test_b8sig_l2_005_compose_up_healthy() {
  if _l2_gate_unmet; then return 0; fi
  # Render the canonical .tmpl into a tmpdir, substitute placeholders,
  # bind UI to 127.0.0.1, isolate the SigNoz services into their own
  # compose, `up -d`, poll the 4 long-running healthchecks ≤ 120 s, then
  # `down -v`. Cleanup trap on EXIT. NFR-B8-SIG-004 ≤ 180 s wall-clock.
  local tmp; tmp="$(mktemp -d -t forge-b8sig-XXXXXX)"
  # shellcheck disable=SC2064
  trap "(cd '$tmp' 2>/dev/null && docker compose -f rendered.yml down -v >/dev/null 2>&1); rm -rf '$tmp'" RETURN

  # Substitute <project-name> placeholders + a random UI port to avoid
  # collisions ; the canonical already loopback-binds (127.0.0.1, FIX 3 /
  # Aegis), so we only swap the UI port number, keeping the 127.0.0.1 prefix.
  local ui_port="33$(( ( RANDOM % 90 ) + 10 ))"  # 3310-3399 host range
  sed -e 's/<project-name>/b8sigsmoke/g' \
      -e "s/127.0.0.1:\${SIGNOZ_UI_PORT:-3301}:8080/127.0.0.1:${ui_port}:8080/g" \
      "$SIG_CANONICAL" > "$tmp/rendered.yml"

  # The collector mounts ./infra/observability/signoz-otel-collector-config.yaml
  # (relative to the compose dir) — stage it into the tmpdir so the rendered
  # compose's relative mount resolves.
  mkdir -p "$tmp/infra/observability"
  local sig_cfg_tmpl
  sig_cfg_tmpl="$(dirname "$SIG_CANONICAL")/infra/observability/signoz-otel-collector-config.yaml.tmpl"
  if [ -f "$sig_cfg_tmpl" ]; then
    sed 's/<project-name>/b8sigsmoke/g' "$sig_cfg_tmpl" \
      > "$tmp/infra/observability/signoz-otel-collector-config.yaml"
  fi

  # Extract only the SigNoz subgraph + network/volumes for the smoke ;
  # the fsm-db/backend/kong services are out of scope for this leg and
  # require an .env file. We instead `up` only the SigNoz services by
  # name so the smoke is hermetic.
  local services="fsm-signoz-zookeeper init-clickhouse fsm-signoz-clickhouse fsm-signoz-telemetrystore-migrator fsm-signoz-otel-collector fsm-signoz"
  # Provide a throwaway .env so `env_file: .env` (other services) resolves.
  : > "$tmp/.env"

  ( cd "$tmp" && docker compose -f rendered.yml up -d $services ) > "$tmp/up.log" 2>&1
  if [ $? -ne 0 ]; then
    echo "    docker compose up -d (SigNoz services) failed (FR-B8-SIG-E-018)" >&2
    tail -30 "$tmp/up.log" >&2
    return 1
  fi

  # Poll ≤ 120 s for convergence. The 3 healthcheck-bearing SigNoz services
  # (zookeeper + clickhouse + signoz) MUST reach `healthy` ; the collector
  # carries no healthcheck (minimal image, no http tool — matches upstream
  # EV-1) so it is asserted `running` (not Restarting) instead. The 2 init
  # containers run to completion and drop out of `ps` once exited 0.
  local deadline=$(( $(date +%s) + 120 ))
  local converged=0
  while [ "$(date +%s)" -lt "$deadline" ]; do
    local healthy collector_state
    healthy=$( cd "$tmp" && docker compose -f rendered.yml ps --format '{{.Health}}' 2>/dev/null | grep -c '^healthy$' )
    collector_state=$( cd "$tmp" && docker compose -f rendered.yml ps --format '{{.Name}} {{.State}}' 2>/dev/null | grep 'otel-collector' | awk '{print $2}' )
    if [ "$healthy" -ge 3 ] && [ "$collector_state" = "running" ]; then converged=1; break; fi
    sleep 5
  done
  if [ "$converged" != "1" ]; then
    echo "    SigNoz stack did not converge within 120 s : need 3 healthy (zk+ch+signoz) + collector running (FR-B8-SIG-E-018 / NFR-B8-SIG-004)" >&2
    ( cd "$tmp" && docker compose -f rendered.yml ps ) >&2
    return 1
  fi
}

_test_b8sig_l2_006_old_pins_denied() {
  if _l2_gate_unmet; then return 0; fi
  # Verify-then-pin invariant (T5.3.2 lesson) : the rotted 3-svc pins
  # remain unpullable. WARN-not-FAIL semantics if Docker Hub re-opens
  # them (ADR-B8-COR-003 footnote) — we hard-fail so the WARN surfaces.
  local out
  out=$(docker manifest inspect signoz/frontend:0.55.1 2>&1 || true)
  if ! printf '%s' "$out" | grep -qiE 'no such manifest|denied|unauthorized|manifest unknown|not found'; then
    echo "    WARN : signoz/frontend:0.55.1 no longer denied — verify-then-pin invariant flipped (FR-B8-SIG-A-003)" >&2
    printf '%s\n' "$out" | head -10 >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── B.8.8 — b8-signoz-unified — level $LEVEL ──"

  # L1 always runs.
  run_test _test_b8sig_l1_001_canonical_pins
  run_test _test_b8sig_l1_002_canonical_no_rotted_pins
  run_test _test_b8sig_l1_003_canonical_sidecar_pins
  run_test _test_b8sig_l1_004_audit_comment_present
  run_test _test_b8sig_l1_005_ui_port_envvar
  run_test _test_b8sig_l1_006_otlp_ports
  run_test _test_b8sig_l1_007_healthchecks_restart
  run_test _test_b8sig_l1_008_standard_version_v200
  run_test _test_b8sig_l1_009_standard_signoz_pin
  run_test _test_b8sig_l1_010_no_legacy_version_keys
  run_test _test_b8sig_l1_011_pin_review_cadence
  run_test _test_b8sig_l1_012_last_reviewed_expires
  run_test _test_b8sig_l1_013_waiver_cite_appendonly
  run_test _test_b8sig_l1_014_review_ledger_arch_change
  run_test _test_b8sig_l1_015_validate_standards_yaml
  run_test _test_b8sig_l1_016_changelog_entry
  run_test _test_b8sig_l1_017_mirror_count
  run_test _test_b8sig_l1_018_snapshot_exists_within_budget
  run_test _test_b8sig_l1_019_snapshot_cli_mirror_identical
  run_test _test_b8sig_l1_020_snapshot_carries_unified_pin
  run_test _test_b8sig_l1_021_breaking_change_field_present

  # L2 runs when --level includes 2.
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — manifest pullable + compose-up + verify-then-pin (opt-in FORGE_B8_SIGNOZ_DOCKER=1)"
    run_test _test_b8sig_l2_001_signoz_manifest_pullable
    run_test _test_b8sig_l2_002_collector_manifest_pullable
    run_test _test_b8sig_l2_003_clickhouse_manifest_pullable
    run_test _test_b8sig_l2_004_zookeeper_manifest_pullable
    run_test _test_b8sig_l2_005_compose_up_healthy
    run_test _test_b8sig_l2_006_old_pins_denied
  fi

  print_summary
}

main "$@"
