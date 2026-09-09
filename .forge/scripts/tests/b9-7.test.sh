#!/usr/bin/env bash
# Forge — B.9.7 web CI layer for mobile-pwa-first
# <!-- Audit: B.9.7 (b9-7-web-ci) — per-surface Qwik CI workflow gate -->
#
# The archetype's only workflow was the B.4 mobile-only one (ios / android /
# e2e-android / summary), filtering on lib|ios|android|pubspec. A change under
# web-pwa/ triggered nothing, and the `summary` required check reported success
# with no web step having run. This harness gates the workflow that fixes that.
#
#   T-001  web-pwa-ci.yml.tmpl exists                                  (FR-B9-7-001)
#   T-002  it is registered in scaffold-plan.yaml with the right target(FR-B9-7-001)
#   T-003  the template is valid YAML once comments are stripped       (FR-B9-7-001)
#   T-004  dorny/paths-filter@v3 present AND on.<event>.paths absent   (FR-B9-7-002)
#   T-005  the filter is scoped to web-pwa/**                          (FR-B9-7-002)
#   T-006  Node comes from node-version-file: web-pwa/.nvmrc           (FR-B9-7-003)
#   T-007  gate ORDER by byte offset: build.types < build < verify.sh
#          < constitution-linter.sh                                     (FR-B9-7-004)
#   T-008  dist/ is uploaded; no deploy action and no deploy secret     (FR-B9-7-005)
#   T-009  a summary job exists, needs the build job, treats skipped
#          as success                                                   (FR-B9-7-006)
#   T-010  no `continue-on-error: true`                                 (FR-B9-7-007)
#   T-011  third-party actions are pinned (checkout/setup-node/upload/
#          paths-filter)                                                (FR-B9-7-004)
#   T-012  the header declares what is ABSENT (no format/test step, no
#          deploy, npm install not npm ci)                              (NFR-B9-7-004)
#
# 12 L1 tests. Budget <= 3 s, zero net/Docker/npm.
#
# WHAT THIS HARNESS CANNOT DO, stated so it is not inferred from what it checks:
# it never runs the workflow. There is no GitHub runner here. It gates the
# template's SHAPE — that the right mechanism is used in the right order with
# pinned actions — not that GitHub would accept or that the build passes. The
# build itself was proven live by t5-qwik-cli-ignore-dep (evidence P-5/P-7).

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

ARCH_DIR="$FORGE_ROOT/.forge/templates/archetypes/mobile-pwa-first"
WF="$ARCH_DIR/2.0.0/.github/workflows/web-pwa-ci.yml.tmpl"
PLAN="$ARCH_DIR/scaffold-plan.yaml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# Body of the template with `#` comment lines removed. Every content assertion
# runs against THIS, not the raw file: the header deliberately DOCUMENTS what the
# workflow excludes (no deploy, no continue-on-error), so an unstripped grep would
# match the prose describing the violation and report the file as violating it.
# That is the b9-2 T-013/T-014 trap, and the b9-3 `[^\n]` trap, in one.
_body() {
  [ -f "$WF" ] || return 1
  grep -vE '^[[:space:]]*#' "$WF"
}

# Byte offset of a needle in the stripped body, or -1. Used by T-007: asserting
# that four keywords are PRESENT says nothing about their ORDER, and a
# presence-only test passes a file whose steps have been reordered.
_offset() {
  local needle="$1" body="$2"
  python3 - "$needle" <<PY
import sys
body = """$body"""
print(body.find(sys.argv[1]))
PY
}

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b97_l1_001_workflow_exists() {
  [ -f "$WF" ] || {
    echo "    FAIL T-001: web-pwa-ci.yml.tmpl missing: $WF (FR-B9-7-001)" >&2; return 1; }
}

_test_b97_l1_002_registered_in_scaffold_plan() {
  [ -f "$PLAN" ] || { echo "    FAIL T-002: scaffold-plan.yaml missing (FR-B9-7-001)" >&2; return 1; }
  local ok=1
  # A template that exists but is not in the plan renders NOTHING. Assert both
  # halves of the entry: the source and the target it lands on.
  grep -qF '2.0.0/.github/workflows/web-pwa-ci.yml.tmpl' "$PLAN" \
    || { echo "    FAIL T-002: plan has no source entry for web-pwa-ci.yml.tmpl (FR-B9-7-001)" >&2; ok=0; }
  grep -qF 'target: .github/workflows/web-pwa-ci.yml' "$PLAN" \
    || { echo "    FAIL T-002: plan has no target .github/workflows/web-pwa-ci.yml (FR-B9-7-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b97_l1_003_valid_yaml() {
  [ -f "$WF" ] || { echo "    FAIL T-003: template absent (see T-001)" >&2; return 1; }
  python3 - "$WF" <<'PY' 2>/dev/null || { echo "    FAIL T-003: template is not valid YAML (FR-B9-7-001)" >&2; return 1; }
import sys, yaml
raw = open(sys.argv[1]).read()
text = "\n".join(l for l in raw.splitlines() if not l.lstrip().startswith("#"))
doc = yaml.safe_load(text)
assert isinstance(doc, dict) and doc, "empty or non-mapping document"
# YAML 1.1 quirk: a bare `on` key parses as the boolean True under safe_load.
on = doc.get("on", doc.get(True))
assert isinstance(on, dict), "`on:` is not a mapping"
assert isinstance(doc.get("jobs"), dict) and doc["jobs"], "no jobs"
PY
}

_test_b97_l1_004_paths_filter_not_native_paths() {
  local body; body="$(_body)" || { echo "    FAIL T-004: template absent (see T-001)" >&2; return 1; }
  local ok=1
  grep -qF 'dorny/paths-filter@v3' <<<"$body" \
    || { echo "    FAIL T-004: missing dorny/paths-filter@v3 (FR-B9-7-002, ci-workflows.md ADR-002)" >&2; ok=0; }
  # The rejected mechanism. `on.<event>.paths` skips the workflow entirely, so no
  # required status is published and branch protection cannot distinguish
  # "not applicable" from "never ran".
  if grep -qE '^[[:space:]]{4,6}paths:' <<<"$body"; then
    echo "    FAIL T-004: uses on.<event>.paths — the mechanism ci-workflows.md ADR-002 rejects (FR-B9-7-002)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b97_l1_005_filter_scoped_to_web_pwa() {
  local body; body="$(_body)" || { echo "    FAIL T-005: template absent (see T-001)" >&2; return 1; }
  grep -qF "'web-pwa/**'" <<<"$body" \
    || { echo "    FAIL T-005: paths filter is not scoped to 'web-pwa/**' (FR-B9-7-002)" >&2; return 1; }
}

_test_b97_l1_006_node_from_nvmrc() {
  local body; body="$(_body)" || { echo "    FAIL T-006: template absent (see T-001)" >&2; return 1; }
  local ok=1
  grep -qF 'node-version-file: web-pwa/.nvmrc' <<<"$body" \
    || { echo "    FAIL T-006: Node is not read from web-pwa/.nvmrc (FR-B9-7-003)" >&2; ok=0; }
  # A hardcoded node-version would keep working after .nvmrc moved, which is the
  # silent-drift failure this requirement exists to prevent. It also decides
  # whether the build passes at all: qwik build hands ` --pretty` to npm, which
  # npm >= 12 rejects; .nvmrc pins Node 24 (npm <= 11), where it exits 0.
  if grep -qE '^[[:space:]]*node-version:[[:space:]]*[0-9]' <<<"$body"; then
    echo "    FAIL T-006: pins a literal node-version instead of the .nvmrc file (FR-B9-7-003)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b97_l1_007_gate_ordering_by_offset() {
  local body; body="$(_body)" || { echo "    FAIL T-007: template absent (see T-001)" >&2; return 1; }
  local ok=1
  # Needles are STEP NAMES, not the commands. `npm run build` is a PREFIX of
  # `npm run build.types`, so find() would return the SAME offset for both and the
  # ordering check would fail no matter how the file is written — a test that can
  # never pass is as useless as one that can never fail. The commands themselves
  # are asserted separately below.
  local needles=("Static analysis" "Production build" "verify.sh" "constitution-linter.sh")
  local prev_off=-1 name off
  for name in "${needles[@]}"; do
    off="$(_offset "$name" "$body")"
    if [ "$off" -lt 0 ]; then
      echo "    FAIL T-007: step keyword absent: '$name' (FR-B9-7-004)" >&2; ok=0; continue
    fi
    if [ "$off" -le "$prev_off" ]; then
      echo "    FAIL T-007: '$name' appears at offset $off, before the step that must precede it (offset $prev_off) — ci-workflows.md gate ordering (FR-B9-7-004)" >&2; ok=0
    fi
    prev_off="$off"
  done
  # The steps must also actually run the commands the names claim.
  local c
  for c in "npm run build.types" "npm run build"; do
    grep -qF "$c" <<<"$body" \
      || { echo "    FAIL T-007: step command absent: '$c' (FR-B9-7-004)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b97_l1_008_artifact_not_deploy() {
  local body; body="$(_body)" || { echo "    FAIL T-008: template absent (see T-001)" >&2; return 1; }
  local ok=1
  grep -qF 'actions/upload-artifact@v4' <<<"$body" \
    || { echo "    FAIL T-008: dist/ is not uploaded (FR-B9-7-005)" >&2; ok=0; }
  grep -qF 'web-pwa/dist' <<<"$body" \
    || { echo "    FAIL T-008: the uploaded path is not web-pwa/dist (FR-B9-7-005)" >&2; ok=0; }
  # ADR-B9-7-003: no deploy job. A scaffolded deploy needs adopter secrets to
  # exist before the first push, so it is red on day one for every adopter who
  # has not chosen a host — and pwa.yaml::PWA-RULE-003 places deploy-time secrets
  # with the adopter.
  local hit
  if hit=$(grep -inE 'wrangler|cloudflare|vercel|netlify|VERCEL_TOKEN|CLOUDFLARE_API_TOKEN' <<<"$body"); then
    echo "    FAIL T-008: deploy provider reference in the workflow body (FR-B9-7-005, ADR-B9-7-003): $hit" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b97_l1_009_summary_required_check() {
  local body; body="$(_body)" || { echo "    FAIL T-009: template absent (see T-001)" >&2; return 1; }
  local ok=1
  grep -qE '^[[:space:]]{2}summary:' <<<"$body" \
    || { echo "    FAIL T-009: no summary job (FR-B9-7-006)" >&2; ok=0; }
  grep -qE 'needs:.*build' <<<"$body" \
    || { echo "    FAIL T-009: summary does not depend on the build job (FR-B9-7-006)" >&2; ok=0; }
  # A paths-filter miss skips the build job; ADR-002 defines that as the normal
  # not-applicable outcome, so the summary must accept it rather than fail.
  grep -qF 'skipped' <<<"$body" \
    || { echo "    FAIL T-009: summary does not treat 'skipped' as success (FR-B9-7-006)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b97_l1_010_no_continue_on_error() {
  local body; body="$(_body)" || { echo "    FAIL T-010: template absent (see T-001)" >&2; return 1; }
  if grep -qE 'continue-on-error[[:space:]]*:[[:space:]]*true' <<<"$body"; then
    echo "    FAIL T-010: continue-on-error: true is forbidden (FR-B9-7-007, ci-workflows.md § Failure semantics)" >&2
    return 1
  fi
}

_test_b97_l1_011_actions_pinned() {
  local body; body="$(_body)" || { echo "    FAIL T-011: template absent (see T-001)" >&2; return 1; }
  local ok=1 a
  for a in "actions/checkout@v4" "actions/setup-node@v4" "actions/upload-artifact@v4" "dorny/paths-filter@v3"; do
    grep -qF "$a" <<<"$body" \
      || { echo "    FAIL T-011: action not pinned or absent: $a (ci-workflows.md § Tool version pinning)" >&2; ok=0; }
  done
  # An unpinned @main/@master would be a supply-chain regression.
  if grep -qE 'uses:.*@(main|master)\b' <<<"$body"; then
    echo "    FAIL T-011: an action is pinned to a moving ref (@main/@master)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b97_l1_012_header_declares_absences() {
  [ -f "$WF" ] || { echo "    FAIL T-012: template absent (see T-001)" >&2; return 1; }
  local ok=1 n
  # Asserted on the RAW file: these are header comments, which _body strips.
  # A reader must not conclude from this workflow that the surface is
  # format-clean, tested, or deployable.
  for n in "no format step" "no test step" "npm install"; do
    grep -qiF "$n" "$WF" \
      || { echo "    FAIL T-012: header does not declare '$n' (NFR-B9-7-004)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.9.7 — b9-7-web-ci — level $LEVEL ──"
  run_test _test_b97_l1_001_workflow_exists
  run_test _test_b97_l1_002_registered_in_scaffold_plan
  run_test _test_b97_l1_003_valid_yaml
  run_test _test_b97_l1_004_paths_filter_not_native_paths
  run_test _test_b97_l1_005_filter_scoped_to_web_pwa
  run_test _test_b97_l1_006_node_from_nvmrc
  run_test _test_b97_l1_007_gate_ordering_by_offset
  run_test _test_b97_l1_008_artifact_not_deploy
  run_test _test_b97_l1_009_summary_required_check
  run_test _test_b97_l1_010_no_continue_on_error
  run_test _test_b97_l1_011_actions_pinned
  run_test _test_b97_l1_012_header_declares_absences
  print_summary
}

main
