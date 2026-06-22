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

# ── J.8.c b7-9-janus-ai — combination refusal (FR-B7-9-040..044 / ADR-B7-9-003) ──
# <!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) -->
#
# _refuse_if_forbidden_combination <archetype> <provider>
# Reads .forge/scaffolding/dispatch-table.yml::forbidden_combinations ; if the
# (archetype, provider, resolved-tier) combination matches a forbidden entry,
# emit the structured refusal to stderr and exit 3. ADDITIVE — does NOT modify
# or replace _refuse_if_forbidden (J.8.a archetype-only contract preserved,
# NFR-B7-9-001). Shares the forge-root discovery + PyYAML inline parse pattern
# (ADR-J8-005).
#
# Tier resolution order (FR-B7-9-041 / ADR-J8-006) :
#   $FORGE_EU_TIER  →  <forge_root>/.forge/.forge-tier first line  →  empty.
# Empty tier ⇒ only `tier: any` entries can match (the T3 rule does NOT fire on
# an undeclared tier — Article III.4, no guessed default).
#
# Match predicate : archetype == arg1 AND provider == arg2 AND
#   (tier == "any" OR tier == resolved_tier).
# On match → stderr [REFUSAL: <archetype>/<provider>@<tier>: <rule_id>:
#   <reason> ; alternative: <alt>] + exit 3 (ADR-J8-003).
# No-match / unreachable table → return 0 (fail-open — the CLI dispatcher is
# the canonical refusal point ; this helper is best-effort defense in depth,
# mirroring _refuse_if_forbidden).
_refuse_if_forbidden_combination() {
  local archetype="${1:?archetype name required}"
  local provider="${2:?provider required}"

  # Locate forge root : env override > ascend from $PWD until we find
  # `.forge/scaffolding/dispatch-table.yml` (verbatim _refuse_if_forbidden).
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
    # No dispatch-table reachable ; fail open (FR-B7-9-044).
    return 0
  fi

  # Resolve declared tier : $FORGE_EU_TIER → .forge/.forge-tier first line → ∅.
  local tier="${FORGE_EU_TIER:-}"
  if [ -z "$tier" ] && [ -f "$forge_root/.forge/.forge-tier" ]; then
    tier="$(head -n1 "$forge_root/.forge/.forge-tier" | tr -d '[:space:]')"
  fi

  local refusal
  refusal="$(FORGE_ROOT="$forge_root" FORGE_COMBO_TIER="$tier" \
             python3 - "$archetype" "$provider" <<'PY'
import os, sys
import yaml
archetype = sys.argv[1]
provider = sys.argv[2]
tier = os.environ.get('FORGE_COMBO_TIER', '') or ''
forge_root = os.environ['FORGE_ROOT']
table_path = os.path.join(forge_root, '.forge', 'scaffolding', 'dispatch-table.yml')
try:
    with open(table_path) as f:
        data = yaml.safe_load(f) or {}
except Exception:
    sys.exit(0)
for entry in (data.get('forbidden_combinations') or []):
    if entry.get('archetype') != archetype:
        continue
    if entry.get('provider') != provider:
        continue
    etier = entry.get('tier', 'any')
    # `tier: any` always matches ; otherwise the resolved tier must equal it.
    # An empty resolved tier matches only `any` (no guessed default).
    if etier != 'any' and etier != tier:
        continue
    rid = entry.get('rule_id', 'J8-RULE-???')
    reason = entry.get('reason', '<no reason>')
    alt = entry.get('alternative', '<no alternative>')
    shown_tier = tier if tier else 'unset'
    print(f'[REFUSAL: {archetype}/{provider}@{shown_tier}: {rid}: {reason} ; alternative: {alt}]')
    sys.exit(0)
PY
)"

  if [ -n "$refusal" ]; then
    echo "$refusal" >&2
    exit 3
  fi
}
