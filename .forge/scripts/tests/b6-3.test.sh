#!/usr/bin/env bash
# Forge — B.6.3 event-driven-eu standards harness
# <!-- Audit: B.6.3 (b6-3-standards) — event-driven / asyncapi-contracts / nats-jetstream .md -->
#
# Validates the three pattern standards + their registration:
#
#   T-001  event-driven.md exists + required H2 sections + scaffold grounding (FR-B6-STD-001..006)
#   T-002  asyncapi-contracts.md exists + required H2 + validate/diff commands (FR-B6-STD-010..014)
#   T-003  nats-jetstream.md exists + required H2 + clustering/consumer specifics (FR-B6-STD-020..024)
#   T-004  each standard has Constitutional Compliance + Out-of-scope + Schema-mapping (FR-B6-STD-024/etc.)
#   T-005  index.yml registers all three (FR-B6-STD-030)
#   T-006  REVIEW.md has a birth entry for all three (FR-B6-STD-031)
#   T-007  NO inline crate version pin in any standard (NFR-B6-STD-002, FR-B6-STD-032)
#
# 7 L1 tests. Performance budget: L1 <= 3 s, zero net/Docker. The standards are
# pattern docs (no crate pins); the async-nats / sqlx / temporalio-sdk pins ride
# with B.6.2's Cargo.toml.tmpl (b6-2 verify-then-pin research; transport.yaml/b8-6
# precedent). T-007 guards against an accidental inline pin via a negative grep for
# the Cargo.toml form `<crate> = "<digit>` (placeholders like
# "<pinned-by-B.6.2>" are allowed — they don't start with a digit).

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

STD_DIR="$FORGE_ROOT/.forge/standards"
ED="$STD_DIR/global/event-driven.md"
AC="$STD_DIR/global/asyncapi-contracts.md"
NJ="$STD_DIR/infra/nats-jetstream.md"
INDEX="$STD_DIR/index.yml"
REVIEW="$STD_DIR/REVIEW.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# _has_h2 <file> <keyword> — case-insensitive grep for an H2 heading containing keyword
_has_h2() { grep -qiE "^##[^#].*$2" "$1" 2>/dev/null; }

_test_b63_l1_001_event_driven() {
  [ -f "$ED" ] || { echo "    FAIL T-001: event-driven.md missing: $ED (FR-B6-STD-001)" >&2; return 1; }
  local ok=1
  for kw in "Versioning|version" "Idempotency" "Saga|compensation" "Outbox|Inbox" "Process manager"; do
    _has_h2 "$ED" "$kw" || { echo "    FAIL T-001: event-driven.md missing H2 ~ '$kw' (FR-B6-STD-001)" >&2; ok=0; }
  done
  # scaffold grounding (FR-B6-STD-002/003): envelope field + subject scheme + dedup header
  grep -qE "event_version" "$ED" || { echo "    FAIL T-001: event-driven.md missing event_version (FR-B6-STD-002)" >&2; ok=0; }
  grep -qE "events\.v" "$ED" || { echo "    FAIL T-001: event-driven.md missing events.v<n>.<Type> subject scheme (FR-B6-STD-002)" >&2; ok=0; }
  grep -qE "Nats-Msg-Id" "$ED" || { echo "    FAIL T-001: event-driven.md missing Nats-Msg-Id dedup header (FR-B6-STD-003)" >&2; ok=0; }
  # saga = Temporal activity-only, VIII.2, refs infra/temporal.md (FR-B6-STD-004)
  grep -qiE "reverse" "$ED" || { echo "    FAIL T-001: event-driven.md missing reverse-order compensation (FR-B6-STD-004)" >&2; ok=0; }
  grep -qE "infra/temporal\.md|VIII\.2" "$ED" || { echo "    FAIL T-001: event-driven.md must reference infra/temporal.md / Article VIII.2 (FR-B6-STD-004)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b63_l1_002_asyncapi_contracts() {
  [ -f "$AC" ] || { echo "    FAIL T-002: asyncapi-contracts.md missing: $AC (FR-B6-STD-010)" >&2; return 1; }
  local ok=1
  for kw in "single source|source of truth" "Versioning|version" "Validation|validate" "Breaking"; do
    _has_h2 "$AC" "$kw" || { echo "    FAIL T-002: asyncapi-contracts.md missing H2 ~ '$kw' (FR-B6-STD-010)" >&2; ok=0; }
  done
  grep -qE "3\.1" "$AC" || { echo "    FAIL T-002: asyncapi-contracts.md missing AsyncAPI 3.1 reference (FR-B6-STD-011)" >&2; ok=0; }
  grep -qE "asyncapi validate" "$AC" || { echo "    FAIL T-002: asyncapi-contracts.md missing 'asyncapi validate' (FR-B6-STD-013)" >&2; ok=0; }
  grep -qE "asyncapi diff" "$AC" || { echo "    FAIL T-002: asyncapi-contracts.md missing 'asyncapi diff' breaking-change tool (FR-B6-STD-014)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b63_l1_003_nats_jetstream() {
  [ -f "$NJ" ] || { echo "    FAIL T-003: nats-jetstream.md missing: $NJ (FR-B6-STD-020)" >&2; return 1; }
  local ok=1
  for kw in "Clustering|RAFT" "Persistence" "Consumer"; do
    _has_h2 "$NJ" "$kw" || { echo "    FAIL T-003: nats-jetstream.md missing H2 ~ '$kw' (FR-B6-STD-020)" >&2; ok=0; }
  done
  grep -qiE "raft" "$NJ" || { echo "    FAIL T-003: nats-jetstream.md missing RAFT consensus (FR-B6-STD-021)" >&2; ok=0; }
  grep -qiE "durable" "$NJ" || { echo "    FAIL T-003: nats-jetstream.md missing durable consumers (FR-B6-STD-023)" >&2; ok=0; }
  # EU sovereignty (FR-B6-STD-024): no Kafka SaaS US, Redpanda acceptable
  grep -qiE "redpanda" "$NJ" || { echo "    FAIL T-003: nats-jetstream.md missing EU-sovereignty (Redpanda) note (FR-B6-STD-024)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b63_l1_004_common_sections() {
  local ok=1
  for f in "$ED" "$AC" "$NJ"; do
    [ -f "$f" ] || { echo "    FAIL T-004: $f missing (covered by T-001..003)" >&2; ok=0; continue; }
    _has_h2 "$f" "Constitutional Compliance" || { echo "    FAIL T-004: $(basename "$f") missing '## Constitutional Compliance'" >&2; ok=0; }
    _has_h2 "$f" "Out-of-scope|Out of scope" || { echo "    FAIL T-004: $(basename "$f") missing Out-of-scope section" >&2; ok=0; }
    grep -qiE "schema (component )?mapping|event-driven-eu/1.0.0" "$f" || { echo "    FAIL T-004: $(basename "$f") missing schema-mapping note (FR-B6-STD-002/010/020)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b63_l1_005_index_entries() {
  [ -f "$INDEX" ] || { echo "    FAIL T-005: index.yml missing" >&2; return 1; }
  local ok=1
  for s in global/event-driven global/asyncapi-contracts infra/nats-jetstream; do
    grep -qE "$s\b" "$INDEX" || { echo "    FAIL T-005: index.yml has no entry for $s (FR-B6-STD-030)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b63_l1_006_review_births() {
  [ -f "$REVIEW" ] || { echo "    FAIL T-006: REVIEW.md missing" >&2; return 1; }
  local ok=1
  for s in event-driven asyncapi-contracts nats-jetstream; do
    grep -qE "$s\.md" "$REVIEW" || { echo "    FAIL T-006: REVIEW.md has no birth entry for $s.md (FR-B6-STD-031)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b63_l1_007_no_inline_pins() {
  # NFR-B6-STD-002 — no Cargo.toml-style crate pin (`<crate> = "<digit>`) in any
  # standard. Placeholder forms ("<pinned-by-B.6.2>") are allowed. The concrete pins
  # live in B.6.2's Cargo.toml.tmpl (b6-2 verify-then-pin research).
  local hits ok=1
  for f in "$ED" "$AC" "$NJ"; do
    [ -f "$f" ] || continue
    hits=$(grep -nE '(async-nats|sqlx|temporalio-sdk|temporalio-client)[[:space:]]*=[[:space:]]*"[0-9]' "$f" 2>/dev/null || true)
    if [ -n "$hits" ]; then
      echo "    FAIL T-007: $(basename "$f") inlines a crate version pin (NFR-B6-STD-002): $hits" >&2; ok=0
    fi
  done
  [ "$ok" = "1" ]
}

main() {
  echo "── B.6.3 — b6-3-standards — level $LEVEL ──"
  run_test _test_b63_l1_001_event_driven
  run_test _test_b63_l1_002_asyncapi_contracts
  run_test _test_b63_l1_003_nats_jetstream
  run_test _test_b63_l1_004_common_sections
  run_test _test_b63_l1_005_index_entries
  run_test _test_b63_l1_006_review_births
  run_test _test_b63_l1_007_no_inline_pins
  print_summary
}

main
