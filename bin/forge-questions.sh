#!/usr/bin/env bash
# Forge — `forge-questions.sh` open-questions aggregator
# <!-- Audit: F.1 (f1-open-questions, FR-OQ-015..017) -->
#
# Lists open (or filtered) questions across `.forge/changes/*/open-questions.md`.
#
# Usage :
#   bash bin/forge-questions.sh                   # list all Status: open
#   bash bin/forge-questions.sh --change <name>   # filter by change name
#   bash bin/forge-questions.sh --status <enum>   # filter by status (open|answered|wontfix)
#
# Output format (one question per line) :
#   <change>:Q-NNN  <title>  (raised <date> by <handle>)
#
# Sorted by `Raised on` ascending.
#
# Exit codes :
#   0  — success (zero or more questions listed)
#   2  — argument error

set -uo pipefail

FORGE_ROOT="${FORGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CHANGES_DIR="$FORGE_ROOT/.forge/changes"

err() { echo "forge-questions: $*" >&2; }

# ─── Args ────────────────────────────────────────────────────────

FILTER_CHANGE=""
FILTER_STATUS="open"  # default

while [ $# -gt 0 ]; do
  case "$1" in
    --change) FILTER_CHANGE="${2:-}"; shift 2 ;;
    --change=*) FILTER_CHANGE="${1#*=}"; shift ;;
    --status) FILTER_STATUS="${2:-}"; shift 2 ;;
    --status=*) FILTER_STATUS="${1#*=}"; shift ;;
    -h|--help)
      sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) err "unknown flag: $1"; exit 2 ;;
  esac
done

case "$FILTER_STATUS" in
  open|answered|wontfix) ;;
  *) err "invalid --status '$FILTER_STATUS' (expected: open|answered|wontfix)"; exit 2 ;;
esac

# ─── Aggregation ─────────────────────────────────────────────────

if [ ! -d "$CHANGES_DIR" ]; then
  exit 0
fi

# Collect (date, line) tuples then sort by date.
results=$(
  for oq in "$CHANGES_DIR"/*/open-questions.md; do
    [ -f "$oq" ] || continue
    change_dir="$(dirname "$oq")"
    change_name="$(basename "$change_dir")"
    if [ -n "$FILTER_CHANGE" ] && [ "$change_name" != "$FILTER_CHANGE" ]; then
      continue
    fi
    awk -v change="$change_name" -v want_status="$FILTER_STATUS" '
      function flush() {
        if (qid != "" && status == want_status) {
          printf "%s\t%s\t%s\t%s\t%s\n", raised_on, change, qid, title, raised_by
        }
        qid=""; title=""; status=""; raised_on=""; raised_by=""
      }
      /^## Q-[0-9][0-9][0-9]: / {
        flush()
        # Extract Q-NNN (positions 4..8) and title (everything after "## Q-NNN: ")
        qid = substr($0, 4, 5)
        title = substr($0, 11)
        next
      }
      /^- \*\*Status\*\*: / {
        sub(/^- \*\*Status\*\*: /, ""); status=$0
      }
      /^- \*\*Raised on\*\*: / {
        sub(/^- \*\*Raised on\*\*: /, ""); raised_on=$0
      }
      /^- \*\*Raised by\*\*: / {
        sub(/^- \*\*Raised by\*\*: /, ""); raised_by=$0
      }
      END { flush() }
    ' "$oq"
  done
)

# Sort by date (col 1 = raised_on, ISO 8601 sorts lexicographically).
if [ -z "$results" ]; then
  exit 0
fi

printf '%s\n' "$results" | sort | while IFS=$'\t' read -r raised_on change qid title raised_by; do
  printf '%s:%s  %s  (raised %s by %s)\n' "$change" "$qid" "$title" "$raised_on" "$raised_by"
done

exit 0
