#!/usr/bin/env bash
# Forge — D.5 Governance Test Harness (d5-governance)
# <!-- Audit: D.5 (d5-governance) -->
#
# Validates :
#  - GOVERNANCE.md exists at repo root with required sections (FR-GOV-001..009)
#  - CODE_OF_CONDUCT.md is Contributor Covenant v2.1 with contact email (FR-GOV-010)
#  - Constitution amended with Article XII + Version 1.1.0 + Amendments table (FR-GOV-011, FR-GOV-012)
#  - change.yaml + archetype tmpl bumped to "1.1.0" ; d5 stays "1.0.0" (ADR-006)
#  - README.md links to GOVERNANCE.md and CODE_OF_CONDUCT.md (FR-GOV-013)
#  - This harness itself is registered in CI (FR-GOV-014)
#
# Manifest pattern : functions are prefixed `_test_d5_NNN`.
#
# Usage :
#   bash .forge/scripts/tests/d5.test.sh

set -uo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

GOV_MD="$FORGE_ROOT_REAL/GOVERNANCE.md"
COC_MD="$FORGE_ROOT_REAL/CODE_OF_CONDUCT.md"
CONSTITUTION="$FORGE_ROOT_REAL/.forge/constitution.md"
CHANGE_TMPL="$FORGE_ROOT_REAL/.forge/templates/change.yaml"
ARCHETYPE_TMPL="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/.forge.yaml.tmpl"
D5_FORGE_YAML="$FORGE_ROOT_REAL/.forge/changes/d5-governance/.forge.yaml"
README_MD="$FORGE_ROOT_REAL/README.md"
CI_WORKFLOW="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# MANIFEST: _test_d5_001  — FR-GOV-001 GOVERNANCE.md exists ≥ 50 lines
# MANIFEST: _test_d5_002  — FR-GOV-002 7 H2 sections present
# MANIFEST: _test_d5_003  — FR-GOV-003 Maintainers names BDFL @bfontaine
# MANIFEST: _test_d5_004  — FR-GOV-004 Roles ≥ 4 bullets
# MANIFEST: _test_d5_005  — FR-GOV-005 Decision Making mentions current+mature phase
# MANIFEST: _test_d5_006  — FR-GOV-006 Amendment Process : 7 days + 4 numbered steps
# MANIFEST: _test_d5_007  — FR-GOV-007 Release Process : vX.Y.Z + 4 numbered steps
# MANIFEST: _test_d5_008  — FR-GOV-008 Code of Conduct section : link + Contributor Covenant
# MANIFEST: _test_d5_009  — FR-GOV-009 Contact section : email contact@benoitfontaine.fr
# MANIFEST: _test_d5_010  — FR-GOV-010 CODE_OF_CONDUCT.md verbatim CC v2.1 + email
# MANIFEST: _test_d5_011  — FR-GOV-011 Constitution Article XII references GOVERNANCE.md
# MANIFEST: _test_d5_012  — FR-GOV-012 Version 1.1.0 + Amendment row #1
# MANIFEST: _test_d5_013  — FR-GOV-012 templates bumped, d5 stays 1.0.0
# MANIFEST: _test_d5_014  — FR-GOV-013 README links to GOVERNANCE + CODE_OF_CONDUCT
# MANIFEST: _test_d5_015  — FR-GOV-014 CI workflow registers d5.test.sh

# ─── Helpers locaux ──────────────────────────────────────────────

_grep_count_h2() {
  # _grep_count_h2 <file> <heading> — exact match on a H2 title line
  grep -c "^## ${2}\$" "$1" 2>/dev/null || true
}

# ─── Tests ───────────────────────────────────────────────────────

_test_d5_001() {
  if [ ! -f "$GOV_MD" ]; then
    echo "    expected: $GOV_MD" >&2; return 1
  fi
  local n
  n=$(wc -l < "$GOV_MD" | tr -d ' ')
  if [ "$n" -lt 50 ]; then
    echo "    GOVERNANCE.md too short: $n lines (need ≥ 50)" >&2; return 1
  fi
}

_test_d5_002() {
  [ -f "$GOV_MD" ] || { echo "    GOVERNANCE.md missing" >&2; return 1; }
  local sections=("Maintainers" "Roles and Responsibilities" "Decision Making" \
                  "Amendment Process" "Release Process" "Code of Conduct" "Contact")
  local missing=()
  for s in "${sections[@]}"; do
    local n
    n=$(_grep_count_h2 "$GOV_MD" "$s")
    [ "$n" -ge 1 ] || missing+=("$s")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    missing H2 sections: ${missing[*]}" >&2; return 1
  fi
}

_test_d5_003() {
  [ -f "$GOV_MD" ] || { echo "    GOVERNANCE.md missing" >&2; return 1; }
  grep -qF 'Benoit Fontaine' "$GOV_MD" || { echo "    'Benoit Fontaine' missing" >&2; return 1; }
  grep -qF '@bfontaine' "$GOV_MD" || { echo "    '@bfontaine' missing" >&2; return 1; }
  grep -qiF 'BDFL' "$GOV_MD" || { echo "    'BDFL' missing" >&2; return 1; }
}

_test_d5_004() {
  [ -f "$GOV_MD" ] || { echo "    GOVERNANCE.md missing" >&2; return 1; }
  # Extract content of "Roles and Responsibilities" section (until next ##)
  local body
  body=$(awk '/^## Roles and Responsibilities/{flag=1; next} /^## /{flag=0} flag' "$GOV_MD")
  local bullets
  bullets=$(printf '%s\n' "$body" | grep -cE '^(- |\* |\| )' || true)
  if [ "$bullets" -lt 4 ]; then
    echo "    Roles section has only $bullets bullets/table-rows (need ≥ 4)" >&2; return 1
  fi
}

_test_d5_005() {
  [ -f "$GOV_MD" ] || { echo "    GOVERNANCE.md missing" >&2; return 1; }
  grep -qiE 'current phase|phase actuelle' "$GOV_MD" \
    || { echo "    'current phase' / 'phase actuelle' not found" >&2; return 1; }
  grep -qiE 'mature phase|phase mature' "$GOV_MD" \
    || { echo "    'mature phase' / 'phase mature' not found" >&2; return 1; }
}

_test_d5_006() {
  [ -f "$GOV_MD" ] || { echo "    GOVERNANCE.md missing" >&2; return 1; }
  local body
  body=$(awk '/^## Amendment Process/{flag=1; next} /^## /{flag=0} flag' "$GOV_MD")
  printf '%s\n' "$body" | grep -qE '7 (jours|days)' \
    || { echo "    Amendment Process : '7 days/jours' missing" >&2; return 1; }
  local steps
  steps=$(printf '%s\n' "$body" | grep -cE '^[1-9][0-9]*\.' || true)
  if [ "$steps" -lt 4 ]; then
    echo "    Amendment Process : $steps numbered steps (need ≥ 4)" >&2; return 1
  fi
}

_test_d5_007() {
  [ -f "$GOV_MD" ] || { echo "    GOVERNANCE.md missing" >&2; return 1; }
  local body
  body=$(awk '/^## Release Process/{flag=1; next} /^## /{flag=0} flag' "$GOV_MD")
  printf '%s\n' "$body" | grep -qE 'vX\.Y\.Z|v[0-9]+\.[0-9]+\.[0-9]+' \
    || { echo "    Release Process : tag pattern vX.Y.Z missing" >&2; return 1; }
  local steps
  steps=$(printf '%s\n' "$body" | grep -cE '^[1-9][0-9]*\.' || true)
  if [ "$steps" -lt 4 ]; then
    echo "    Release Process : $steps numbered steps (need ≥ 4)" >&2; return 1
  fi
}

_test_d5_008() {
  [ -f "$GOV_MD" ] || { echo "    GOVERNANCE.md missing" >&2; return 1; }
  local body
  body=$(awk '/^## Code of Conduct/{flag=1; next} /^## /{flag=0} flag' "$GOV_MD")
  printf '%s\n' "$body" | grep -qF 'CODE_OF_CONDUCT.md' \
    || { echo "    Code of Conduct section : link to CODE_OF_CONDUCT.md missing" >&2; return 1; }
  printf '%s\n' "$body" | grep -qiF 'Contributor Covenant' \
    || { echo "    Code of Conduct section : 'Contributor Covenant' name missing" >&2; return 1; }
}

_test_d5_009() {
  [ -f "$GOV_MD" ] || { echo "    GOVERNANCE.md missing" >&2; return 1; }
  grep -qF 'contact@benoitfontaine.fr' "$GOV_MD" \
    || { echo "    contact@benoitfontaine.fr missing" >&2; return 1; }
}

_test_d5_010() {
  [ -f "$COC_MD" ] || { echo "    expected: $COC_MD" >&2; return 1; }
  grep -qF 'Contributor Covenant' "$COC_MD" \
    || { echo "    'Contributor Covenant' missing" >&2; return 1; }
  grep -qF '2.1' "$COC_MD" \
    || { echo "    version '2.1' missing" >&2; return 1; }
  grep -qF 'contact@benoitfontaine.fr' "$COC_MD" \
    || { echo "    contact email missing" >&2; return 1; }
}

_test_d5_011() {
  [ -f "$CONSTITUTION" ] || { echo "    constitution.md missing" >&2; return 1; }
  grep -qE '^## Article XII' "$CONSTITUTION" \
    || { echo "    Article XII not found" >&2; return 1; }
  # Reference to GOVERNANCE.md inside Article XII body
  local body
  body=$(awk '/^## Article XII/{flag=1; next} /^## /{flag=0} flag' "$CONSTITUTION")
  printf '%s\n' "$body" | grep -qF 'GOVERNANCE.md' \
    || { echo "    Article XII does not reference GOVERNANCE.md" >&2; return 1; }
}

_test_d5_012() {
  [ -f "$CONSTITUTION" ] || { echo "    constitution.md missing" >&2; return 1; }
  grep -qE '^\*\*Version\*\*: v1\.1\.0' "$CONSTITUTION" \
    || { echo "    '**Version**: v1.1.0' line not found under H1" >&2; return 1; }
  # Amendments table : at least one numbered amendment row (| 1 |)
  grep -qE '^\| 1 \| 20[0-9]{2}-[0-9]{2}-[0-9]{2} \|' "$CONSTITUTION" \
    || { echo "    no amendment row '| 1 | <date> |' found" >&2; return 1; }
}

_test_d5_013() {
  [ -f "$CHANGE_TMPL" ] || { echo "    change.yaml template missing" >&2; return 1; }
  local n
  n=$(grep -c 'constitution_version: "1.1.0"' "$CHANGE_TMPL" || true)
  if [ "$n" -ne 2 ]; then
    echo "    change.yaml : expected 2 occurrences of '1.1.0', found $n" >&2; return 1
  fi
  [ -f "$ARCHETYPE_TMPL" ] || { echo "    archetype tmpl missing" >&2; return 1; }
  grep -qF 'constitution_version: "1.1.0"' "$ARCHETYPE_TMPL" \
    || { echo "    archetype .forge.yaml.tmpl not bumped to 1.1.0" >&2; return 1; }
  # d5 itself MUST stay at 1.0.0 (ADR-006)
  [ -f "$D5_FORGE_YAML" ] || { echo "    d5 .forge.yaml missing" >&2; return 1; }
  grep -qF 'constitution_version: "1.0.0"' "$D5_FORGE_YAML" \
    || { echo "    d5 .forge.yaml MUST stay at 1.0.0 (ADR-006)" >&2; return 1; }
}

_test_d5_014() {
  [ -f "$README_MD" ] || { echo "    README.md missing" >&2; return 1; }
  grep -qF 'GOVERNANCE.md' "$README_MD" \
    || { echo "    README does not link GOVERNANCE.md" >&2; return 1; }
  grep -qF 'CODE_OF_CONDUCT.md' "$README_MD" \
    || { echo "    README does not link CODE_OF_CONDUCT.md" >&2; return 1; }
}

_test_d5_015() {
  [ -f "$CI_WORKFLOW" ] || { echo "    forge-ci.yml missing" >&2; return 1; }
  grep -qF 'd5.test.sh' "$CI_WORKFLOW" \
    || { echo "    d5.test.sh not registered in forge-ci.yml" >&2; return 1; }
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — d5-governance Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo ""
  echo "── Phase 2 : GOVERNANCE.md ──"
  run_test _test_d5_001
  run_test _test_d5_002
  run_test _test_d5_003
  run_test _test_d5_004
  run_test _test_d5_005
  run_test _test_d5_006
  run_test _test_d5_007
  run_test _test_d5_008
  run_test _test_d5_009
  echo ""
  echo "── Phase 3 : CODE_OF_CONDUCT.md ──"
  run_test _test_d5_010
  echo ""
  echo "── Phase 4 : Constitution amend + bumps ──"
  run_test _test_d5_011
  run_test _test_d5_012
  run_test _test_d5_013
  echo ""
  echo "── Phase 5 : README ──"
  run_test _test_d5_014
  echo ""
  echo "── Phase 6 : CI integration ──"
  run_test _test_d5_015
  echo ""
  print_summary
}

main "$@"
