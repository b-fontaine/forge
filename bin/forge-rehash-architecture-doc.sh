#!/usr/bin/env bash
# Forge — Rehash escape hatch for docs/ARCHITECTURE-TARGET.md
# <!-- Audit: T.4 (t4-adr-ratification, FR-T4-DOC-002) -->
#
# When `docs/ARCHITECTURE-TARGET.md` is edited (typo fix, formatting,
# minor reformulation), the sha256 hash pinned in
# `.forge/changes/t4-adr-ratification/specs.md::Source Document` table
# drifts. The drift gate `t4.test.sh::_test_t4_023` then FAILs CI.
#
# This script provides a controlled rehash workflow :
#   1. Recompute sha256 of docs/ARCHITECTURE-TARGET.md
#   2. Update the `| **sha256** | ... |` line in specs.md
#   3. Append a dated entry to REHASH-LOG.md (created on first run)
#   4. Print old + new hash for audit trail
#
# Usage :
#   bash bin/forge-rehash-architecture-doc.sh           # rehash and update specs.md
#   bash bin/forge-rehash-architecture-doc.sh --dry-run # show diff without modifying files
#
# Convention : run this script ONLY after a human-reviewed edit. The
# rehash creates an explicit audit moment that is recorded in
# REHASH-LOG.md (immutable history). Never bypass the drift gate by
# overwriting specs.md by hand.

set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '/^# Forge/,/^# REHASH-LOG/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH_DOC="$REPO_ROOT/docs/ARCHITECTURE-TARGET.md"
SPECS_MD="$REPO_ROOT/.forge/changes/t4-adr-ratification/specs.md"
REHASH_LOG="$REPO_ROOT/.forge/changes/t4-adr-ratification/REHASH-LOG.md"

if [ ! -f "$ARCH_DOC" ]; then
  echo "ERROR: $ARCH_DOC not found" >&2
  exit 1
fi
if [ ! -f "$SPECS_MD" ]; then
  echo "ERROR: $SPECS_MD not found" >&2
  exit 1
fi

new_hash="$(shasum -a 256 "$ARCH_DOC" | awk '{print $1}')"
old_hash="$(grep -oE '[a-f0-9]{64}' "$SPECS_MD" | head -1 || true)"

if [ -z "$old_hash" ]; then
  echo "ERROR: no pinned sha256 found in $SPECS_MD (expected hex string in Source Document table)" >&2
  exit 1
fi

if [ "$old_hash" = "$new_hash" ]; then
  echo "OK : hashes already match — no rehash needed."
  echo "  pinned : $old_hash"
  echo "  actual : $new_hash"
  exit 0
fi

echo "Rehash plan :"
echo "  pinned (old) : $old_hash"
echo "  actual (new) : $new_hash"

if [ "$DRY_RUN" = "1" ]; then
  echo ""
  echo "[--dry-run] : specs.md and REHASH-LOG.md NOT modified."
  exit 0
fi

# In-place rewrite of the sha256 line in specs.md
# We use awk for portability (BSD vs GNU sed differ on -i ; awk is uniform)
tmp_specs="$(mktemp)"
awk -v old="$old_hash" -v new="$new_hash" '
  { gsub(old, new); print }
' "$SPECS_MD" > "$tmp_specs"
mv "$tmp_specs" "$SPECS_MD"

# Append rehash log entry
date_iso="$(date +%Y-%m-%d)"
handle="${USER:-unknown}"
if [ ! -f "$REHASH_LOG" ]; then
  cat > "$REHASH_LOG" <<'HEADER'
# Rehash log — t4-adr-ratification

This file is **append-only**. Every invocation of
`bin/forge-rehash-architecture-doc.sh` that mutates the pinned hash
in `specs.md` records one H2 entry below, in chronological order.

Entries document **when** and **by whom** the
`docs/ARCHITECTURE-TARGET.md` doc was rehashed. The reviewer is
responsible for confirming that the edit which triggered the rehash
does NOT change any of the 10 ADR Decisions (Decision / Context /
Consequences blocks). Material edits MUST be ratified by a fresh
Forge change that supersedes parts of `t4-adr-ratification`.

---

HEADER
fi
{
  echo ""
  echo "## $date_iso — rehash by @$handle"
  echo ""
  echo "- **Old hash**: \`$old_hash\`"
  echo "- **New hash**: \`$new_hash\`"
  echo "- **Reviewer attestation required**: confirm no ADR Decision was materially changed."
} >> "$REHASH_LOG"

echo ""
echo "✓ specs.md updated : sha256 $new_hash"
echo "✓ REHASH-LOG.md updated"
echo ""
echo "REMINDER: confirm the edit did not change any ADR Decision before committing."
