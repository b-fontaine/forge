#!/usr/bin/env bash
# shellcheck shell=bash
# Forge — Shared init wrapper helpers (J.8 j8-janus-rules)
# <!-- Audit: J.8 (j8-janus-rules, FR-J8-022 / ADR-J8-005) -->
#
# Helpers sourced by `bin/forge-init-<archetype>.sh` wrappers.
# Provides defense-in-depth refusal logic for archetypes listed in
# `.forge/scaffolding/dispatch-table.yml::forbidden_archetypes`.
#
# Convention : the TS dispatcher (cli/src/commands/init-archetype.ts)
# is the FIRST line of defense ; this helper is the SECOND line for
# cases where the dispatcher is bypassed (e.g. CI scripts directly
# invoking the wrapper).
#
# Usage in a wrapper:
#   source "$(dirname "${BASH_SOURCE[0]}")/_forge-init-helpers.sh"
#   _refuse_if_forbidden "<archetype-name>"
#
# Refusal exit code: 3 (policy violation per ADR-J8-003).
# Refusal stderr format: [REFUSAL: <archetype>: <rule_id>: <reason> ; alternative: <alt>]

# _refuse_if_forbidden <archetype-name>
# Reads .forge/scaffolding/dispatch-table.yml ; if archetype is on
# forbidden_archetypes list, emit the structured refusal error to
# stderr and exit 3.
_refuse_if_forbidden() {
  local archetype="${1:?archetype name required}"

  # Locate forge root : env override > ascend from $PWD until we find
  # `.forge/scaffolding/dispatch-table.yml`.
  local forge_root="${FORGE_ROOT:-}"
  if [ -z "$forge_root" ]; then
    local probe="$PWD"
    while [ "$probe" != "/" ]; do
      if [ -f "$probe/.forge/scaffolding/dispatch-table.yml" ]; then
        forge_root="$probe"
        break
      fi
      probe="$(dirname "$probe")"
    done
  fi

  if [ -z "$forge_root" ] || [ ! -f "$forge_root/.forge/scaffolding/dispatch-table.yml" ]; then
    # No dispatch-table reachable ; do nothing (fail open — the TS
    # dispatcher is the canonical refusal point ; this helper is
    # best-effort defense in depth).
    return 0
  fi

  local refusal
  refusal="$(FORGE_ROOT="$forge_root" python3 - "$archetype" <<'PY'
import os, sys
import yaml
archetype = sys.argv[1]
forge_root = os.environ['FORGE_ROOT']
table_path = os.path.join(forge_root, '.forge', 'scaffolding', 'dispatch-table.yml')
try:
    with open(table_path) as f:
        data = yaml.safe_load(f) or {}
except Exception:
    sys.exit(0)
for entry in (data.get('forbidden_archetypes') or []):
    if entry.get('name') == archetype:
        rid = entry.get('rule_id', 'J8-RULE-???')
        reason = entry.get('reason', '<no reason>')
        alt = entry.get('alternative', '<no alternative>')
        print(f'[REFUSAL: {archetype}: {rid}: {reason} ; alternative: {alt}]')
        sys.exit(0)
PY
)"

  if [ -n "$refusal" ]; then
    echo "$refusal" >&2
    exit 3
  fi
}
