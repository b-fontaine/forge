#!/usr/bin/env bash
# Forge — B.9.2 mobile-pwa-first web-pwa surface + app-surface port harness
# <!-- Audit: B.9.2 (b9-2-web-pwa) — scaffold-plan port + Qwik PWA surface gate -->
#
# Validates the b9-2-web-pwa deliverables:
#   (1) the app-surface port of mobile-only's 48 templates into a scaffold-plan
#   (2) the new web-pwa/ Qwik City PWA subtree (Connect-free)
#   (3) the pwa.yaml standard + dispatch registration
#
#   T-001  scaffold-plan.yaml exists with archetype/version/templates[] (FR-B9-2-005)
#   T-002  every templates[].source resolves to a real file (FR-B9-2-005)
#   T-003  all 48 mobile-only files are represented in the plan (FR-B9-2-001)
#   T-004  mobile-only tree + wrapper + dispatch alias byte-unchanged (NFR-B9-2-002)
#   T-005  zero {{...}} tokens remain in ported file CONTENTS (FR-B9-2-002)
#   T-006  ported contents use <project-name>/<reverse-domain> only (FR-B9-2-002)
#   T-007  BYTE-EQUIVALENCE of the app surface, legacy vs ported (FR-B9-2-004)
#   T-008  a render emits .forge/scaffold-manifest.yaml with version + SHAs (FR-B9-2-006)
#   T-009  the wrapper carries the Kotlin relocation; no literal placeholder dir survives (FR-B9-2-003)
#   T-010  overlay.sh byte-unchanged vs HEAD (NFR-B9-2-001)
#   T-011  wrapper refuses exit 3 while candidate, ZERO filesystem writes (FR-B9-2-007)
#   T-012  web-pwa/ has the spine; NO src/lib/connect-client.ts (FR-B9-2-010)
#   T-013  NEGATIVE — no @connectrpc/* in the web-pwa package.json (ADR-B9-2-001)
#   T-014  NEGATIVE — no connect-client import anywhere in web-pwa/ (ADR-B9-2-001)
#   T-015  manifest declares name/short_name/start_url/display + >=1 icon (FR-B9-2-011)
#   T-016  Service Worker present + registered; offline-shell route exists (FR-B9-2-012)
#   T-017  push subscription client-side only; NO push server / VAPID keygen (FR-B9-2-013)
#   T-018  zero resolved pin in the plan (no \d+\.\d+ literal) (FR-B9-2-014)
#   T-019  pwa.yaml exists, 8-field frontmatter, registered in index.yml (FR-B9-2-030/031)
#   T-020  B.9.1's four delivered_by:B.9.2 pointers now name pwa.yaml (FR-B9-2-030)
#   T-021  dispatch-table has a mobile-pwa-first: key; mobile-only alias intact (FR-B9-2-020)
#   T-022  schema still candidate / scaffoldable:false (FR-B9-2-023)
#   T-L2-001 (opt-in) forge init --archetype mobile-pwa-first exits 3, renders nothing
#   T-L2-002 (opt-in) npm install && tsc --noEmit in a rendered web-pwa/
#
# 22 L1 + 2 L2. L1 budget <= 15 s (T-007 does two full renders), zero net/Docker/npm.
#
# NOTE on T-007: the wrapper is a GATED real body (ADR-B7-2-007) and refuses while the
# schema is `candidate`, so the harness drives it under FORGE_MPF_FORCE_SCAFFOLD=1 —
# the same harness-only override b7-2 uses (FORGE_AINR_FORCE_SCAFFOLD). This exercises
# the REAL wrapper end-to-end (absolutization + overlay + Kotlin relocation) rather
# than re-implementing its body in the harness, so a wrapper bug fails the test instead
# of being masked. T-011 separately proves the gate still refuses without the override.

set -uo pipefail

# Stream greps here use `grep -q ... < <(producer)`, NOT `producer | grep -q ...`.
# In a pipeline, `grep -q` exits at the first match and the producer takes SIGPIPE
# (141), which `pipefail` promotes to the pipeline's status. Once the web-pwa corpus
# outgrew the 64 KiB pipe buffer this fired for real: T-017 reported a present
# `PushManager` as absent, and T-018's VAPID negative — `if producer | grep -q X`
# — stopped firing entirely, passing while detecting nothing. Process substitution
# keeps the producer out of the pipeline's exit status. See b9-3.test.sh's header.

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
PLAN="$ARCH_DIR/scaffold-plan.yaml"
TREE="$ARCH_DIR/2.0.0"
WEBPWA="$TREE/web-pwa"
MO_DIR="$FORGE_ROOT/.forge/templates/archetypes/mobile-only"
MO_WRAPPER="$FORGE_ROOT/bin/forge-init-mobile-only.sh"
WRAPPER="$FORGE_ROOT/bin/forge-init-mobile-pwa-first.sh"
OVERLAY_SH="$FORGE_ROOT/.forge/scripts/scaffolder/overlay.sh"
SCHEMA="$FORGE_ROOT/.forge/schemas/mobile-pwa-first/2.0.0.yaml"
PWA_STD="$FORGE_ROOT/.forge/standards/pwa.yaml"
STD_INDEX="$FORGE_ROOT/.forge/standards/index.yml"
DISPATCH="$FORGE_ROOT/.forge/scaffolding/dispatch-table.yml"

PROBE_NAME="pwaprobe"
PROBE_DOMAIN="com.example.probe"
PROBE_DOMAIN_PATH="com/example/probe"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

_have_py_yaml() { command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; }

_git_clean_vs_head() {
  # $@ = paths. Returns 0 if unchanged vs HEAD, 1 if changed, 2 if not a git repo.
  git -C "$FORGE_ROOT" rev-parse --git-dir >/dev/null 2>&1 || return 2
  git -C "$FORGE_ROOT" diff --quiet HEAD -- "$@" 2>/dev/null && return 0
  return 1
}

# ─── Render helpers ──────────────────────────────────────────────────────────

# Render the ported plan the way the wrapper does: absolutize `source:` paths
# (overlay.sh:128 hardcodes ARCHETYPE_DIR to full-stack-monorepo, so a relative
# source would resolve against the flagship tree), then overlay, then relocate the
# Kotlin package dir (ADR-B9-2-006, wrapper-side by design).
_render_ported() {
  # Drive the REAL wrapper (plan absolutization + overlay + Kotlin relocation) under
  # the harness-only gate override, mirroring b7-2's FORGE_AINR_FORCE_SCAFFOLD. This
  # is strictly better than re-implementing the wrapper body here: a bug in the
  # wrapper is caught, not masked by a harness copy of the same logic.
  local out_dir="$1"
  SOURCE_DATE_EPOCH=0 FORGE_MPF_FORCE_SCAFFOLD=1 bash "$WRAPPER" \
    --target "$out_dir" --project-name "$PROBE_NAME" \
    --reverse-domain "$PROBE_DOMAIN" --force >/dev/null 2>&1
}

_render_legacy() {
  local out_dir="$1"
  SOURCE_DATE_EPOCH=0 bash "$MO_WRAPPER" --target "$out_dir" \
    --project-name "$PROBE_NAME" --reverse-domain "$PROBE_DOMAIN" --force >/dev/null 2>&1
}


# Emit `path:line:content` for every file given, with BOTH `//` line comments and
# `/* ... */` block comments blanked out. Block comments are replaced space-for-space
# so line numbers stay usable in failure messages. Used by the negative tests, which
# must never match prose: the templates deliberately DOCUMENT what they exclude, and
# an unstripped grep flags that documentation as the violation (the T-013/T-014 trap).
_stripped_stream() {
  python3 - "$@" <<'PYSTRIP'
import sys, re
def blank(m):
    return re.sub(r'[^\n]', ' ', m.group(0))
for path in sys.argv[1:]:
    try:
        src = open(path, encoding='utf-8', errors='replace').read()
    except OSError:
        continue
    src = re.sub(r'/\*.*?\*/', blank, src, flags=re.S)
    src = re.sub(r'//[^\n]*', '', src)
    for i, line in enumerate(src.splitlines(), 1):
        print(f"{path}:{i}:{line}")
PYSTRIP
}

# Safe file list (handles spaces; never reads stdin on an empty result).
_webpwa_files() {
  local -a out=()
  local f
  while IFS= read -r -d '' f; do out+=("$f"); done < <(find "$WEBPWA" -type f -print0 2>/dev/null)
  printf '%s\0' "${out[@]}"
}

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b92_l1_001_plan_exists() {
  [ -f "$PLAN" ] || { echo "    FAIL T-001: scaffold-plan.yaml missing: $PLAN (FR-B9-2-005)" >&2; return 1; }
  _have_py_yaml || { echo "    FAIL T-001: python3+PyYAML required" >&2; return 1; }
  python3 - "$PLAN" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
missing = [k for k in ('archetype', 'version', 'templates') if k not in d]
if missing:
    print(f"    FAIL T-001: plan missing keys {missing} (FR-B9-2-005)", file=sys.stderr); sys.exit(1)
if d['archetype'] != 'mobile-pwa-first':
    print(f"    FAIL T-001: archetype={d['archetype']!r} != 'mobile-pwa-first'", file=sys.stderr); sys.exit(1)
if not isinstance(d['templates'], list) or not d['templates']:
    print("    FAIL T-001: templates[] empty", file=sys.stderr); sys.exit(1)
PY
}

_test_b92_l1_002_sources_resolve() {
  [ -f "$PLAN" ] || { echo "    FAIL T-002: plan absent (see T-001)" >&2; return 1; }
  _have_py_yaml || return 1
  python3 - "$PLAN" "$ARCH_DIR" <<'PY'
import sys, os, yaml
plan, arch = sys.argv[1], sys.argv[2]
d = yaml.safe_load(open(plan))
bad = []
for e in d.get('templates', []):
    s = e.get('source')
    if not s: bad.append('<entry with no source>'); continue
    p = s if os.path.isabs(s) else os.path.join(arch, s)
    if not os.path.isfile(p): bad.append(s)
if bad:
    print(f"    FAIL T-002: {len(bad)} unresolvable source(s), first 5: {bad[:5]} (FR-B9-2-005)", file=sys.stderr)
    sys.exit(1)
PY
}

_test_b92_l1_003_all_48_ported() {
  [ -d "$TREE" ] || { echo "    FAIL T-003: ported tree missing: $TREE (FR-B9-2-001)" >&2; return 1; }
  local expected actual
  expected=$(find "$MO_DIR" -type f | wc -l | tr -d ' ')
  actual=$(find "$TREE" -type f -not -path "$WEBPWA/*" | wc -l | tr -d ' ')
  [ "$actual" -ge "$expected" ] || {
    echo "    FAIL T-003: ported app surface has $actual files, mobile-only has $expected (FR-B9-2-001)" >&2; return 1; }
  # Every mobile-only relative path must exist in the port.
  local missing="" rel
  while IFS= read -r rel; do
    [ -f "$TREE/$rel" ] || missing="$missing $rel"
  done < <(cd "$MO_DIR" && find . -type f | sed 's|^\./||')
  [ -z "$missing" ] || { echo "    FAIL T-003: not ported:$missing (FR-B9-2-001)" >&2; return 1; }
}

_test_b92_l1_004_mobile_only_untouched() {
  _git_clean_vs_head \
    ".forge/templates/archetypes/mobile-only" \
    "bin/forge-init-mobile-only.sh"
  case $? in
    0) ;;
    2) echo "    SKIP T-004: not a git checkout" >&2; return 0 ;;
    *) echo "    FAIL T-004: mobile-only tree or wrapper modified — it is a supported legacy alias (NFR-B9-2-002)" >&2; return 1 ;;
  esac
  grep -qE "^\s+target: mobile-pwa-first" "$DISPATCH" \
    || { echo "    FAIL T-004: the mobile-only alias 'target: mobile-pwa-first' metadata is gone (NFR-B9-2-002)" >&2; return 1; }
  grep -qE "^\s+status: legacy_alias" "$DISPATCH" \
    || { echo "    FAIL T-004: the mobile-only 'status: legacy_alias' metadata is gone (NFR-B9-2-002)" >&2; return 1; }
}

_test_b92_l1_005_no_jinja_tokens_in_contents() {
  [ -d "$TREE" ] || { echo "    FAIL T-005: ported tree missing (see T-003)" >&2; return 1; }
  local hits
  hits=$(grep -rlE '\{\{[a-zA-Z_]+\}\}' "$TREE" 2>/dev/null || true)
  [ -z "$hits" ] || {
    echo "    FAIL T-005: {{...}} token(s) survive in ported CONTENTS (FR-B9-2-002):" >&2
    echo "$hits" | sed 's|^|      |' >&2; return 1; }
}

_test_b92_l1_006_angle_placeholders_used() {
  [ -d "$TREE" ] || { echo "    FAIL T-006: ported tree missing (see T-003)" >&2; return 1; }
  local ok=1
  grep -rq '<project-name>' "$TREE" || { echo "    FAIL T-006: no <project-name> in the port — the rewrite did not happen (FR-B9-2-002)" >&2; ok=0; }
  grep -rq '<reverse-domain>' "$TREE" || { echo "    FAIL T-006: no <reverse-domain> in the port (FR-B9-2-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b92_l1_007_byte_equivalence() {
  # THE port gate (FR-B9-2-004).
  [ -f "$PLAN" ] || { echo "    FAIL T-007: plan absent — port not built (FR-B9-2-004)" >&2; return 1; }
  [ -x "$MO_WRAPPER" ] || [ -f "$MO_WRAPPER" ] || { echo "    FAIL T-007: mobile-only wrapper missing" >&2; return 1; }
  _have_py_yaml || { echo "    FAIL T-007: python3+PyYAML required" >&2; return 1; }
  command -v rsync >/dev/null 2>&1 || { echo "    FAIL T-007: rsync required" >&2; return 1; }

  local work; work="$(mktemp -d -t forge-b9-2-eq-XXXXXX)"
  trap "rm -rf '$work'" RETURN
  local legacy="$work/legacy" ported="$work/ported"

  _render_legacy "$legacy" || { echo "    FAIL T-007: legacy render failed" >&2; return 1; }
  _render_ported "$ported" || { echo "    FAIL T-007: ported render failed (FR-B9-2-004)" >&2; return 1; }

  # web-pwa/, the scaffold manifest and the shared OIDC config exist only on the
  # ported side by design.
  #
  # `oidc-provider.json` was added by B.9.3 (FR-GL-B9-3-020, ADR-B9-3-002): the
  # issuer and scopes are declared ONCE at the project root and read by BOTH
  # surfaces, so it cannot live inside web-pwa/. Excluding it does not weaken this
  # gate in the direction the gate exists for — every Flutter file stays compared
  # byte-for-byte, and B.9.3 adds no file and changes no byte under lib/, ios/,
  # android/ or test/ (asserted independently by b9-3 T-022). What is excluded here
  # is a NEW root-level file that the legacy mobile-only render has no counterpart
  # for, which is the same reason web-pwa/ is excluded.
  #
  # MECHANISM, stated precisely because the intent above is narrower than the tool:
  # `--exclude` matches a BASENAME at ANY depth, so a file called oidc-provider.json
  # appearing anywhere under the ported tree is skipped too, not only the root one.
  # Accepted, because the two sides come from two genuinely different wrappers and real
  # Flutter drift is still caught byte-for-byte — but "every Flutter file is compared"
  # holds only for files not carrying that exact basename.
  local out
  #
  # `web-pwa-ci.yml` was added by B.9.7 (b9-7-web-ci, FR-B9-7-008). Same shape as
  # oidc-provider.json above: a NEW root-level file the legacy mobile-only render
  # has no counterpart for. It cannot live under web-pwa/ — GitHub Actions only
  # reads .github/workflows/ at the repository root — so the exclusion is the only
  # option short of ending this gate.
  #
  # The SAME basename caveat applies: --exclude matches a BASENAME at ANY depth,
  # so a file called web-pwa-ci.yml anywhere under either tree is skipped too. The
  # name is distinctive enough that this costs nothing today; it is spelled out so
  # the next person adding an exclusion sees the mechanism rather than inferring it.
  #
  # What the gate still guarantees, stated precisely: every file under lib/, ios/,
  # android/, test/, and mobile-ci.yml itself, is still compared byte-for-byte.
  # B.9.7 adds no file under any of them (asserted independently by b9-7 T7.1).
  out=$(diff -r \
        --exclude=web-pwa \
        --exclude=scaffold-manifest.yaml \
        --exclude=oidc-provider.json \
        --exclude=web-pwa-ci.yml \
        "$legacy" "$ported" 2>&1)
  if [ -n "$out" ]; then
    echo "    FAIL T-007: app surface NOT byte-equivalent — the port is wrong (FR-B9-2-004)" >&2
    echo "$out" | head -25 | sed 's|^|      |' >&2
    return 1
  fi
}

_test_b92_l1_008_scaffold_manifest_emitted() {
  [ -f "$PLAN" ] || { echo "    FAIL T-008: plan absent (see T-001)" >&2; return 1; }
  _have_py_yaml || return 1
  local work; work="$(mktemp -d -t forge-b9-2-man-XXXXXX)"
  trap "rm -rf '$work'" RETURN
  _render_ported "$work/out" || { echo "    FAIL T-008: render failed" >&2; return 1; }
  local man="$work/out/.forge/scaffold-manifest.yaml"
  [ -f "$man" ] || { echo "    FAIL T-008: no .forge/scaffold-manifest.yaml emitted — the whole reason ADR-B9-2-002 chose overlay.sh (FR-B9-2-006)" >&2; return 1; }
  grep -q "2.0.0" "$man" || { echo "    FAIL T-008: manifest does not record the archetype version (FR-B9-2-006)" >&2; return 1; }
}

_test_b92_l1_009_kotlin_relocation() {
  [ -f "$WRAPPER" ] || { echo "    FAIL T-009: wrapper missing: $WRAPPER (FR-B9-2-003)" >&2; return 1; }
  grep -q "reverse_domain_path" "$WRAPPER" \
    || { echo "    FAIL T-009: wrapper carries no Kotlin relocation — overlay.sh cannot relocate a directory (FR-B9-2-003, ADR-B9-2-006)" >&2; return 1; }
  # And a real render must leave no literal placeholder directory behind.
  [ -f "$PLAN" ] || return 1
  local work; work="$(mktemp -d -t forge-b9-2-kt-XXXXXX)"
  trap "rm -rf '$work'" RETURN
  _render_ported "$work/out" || { echo "    FAIL T-009: render failed" >&2; return 1; }
  [ ! -d "$work/out/android/app/src/main/kotlin/{{reverse_domain_path}}" ] \
    || { echo "    FAIL T-009: literal {{reverse_domain_path}} directory survived the render (FR-B9-2-003)" >&2; return 1; }
  [ -d "$work/out/android/app/src/main/kotlin/$PROBE_DOMAIN_PATH" ] \
    || { echo "    FAIL T-009: Kotlin sources not relocated to $PROBE_DOMAIN_PATH (FR-B9-2-003)" >&2; return 1; }
}

_test_b92_l1_010_overlay_untouched() {
  _git_clean_vs_head ".forge/scripts/scaffolder/overlay.sh"
  case $? in
    0) return 0 ;;
    2) echo "    SKIP T-010: not a git checkout" >&2; return 0 ;;
    *) echo "    FAIL T-010: overlay.sh was modified — it is shared by 3 archetypes and 8+ harnesses; the hardcoding is worked around in the wrapper, not fixed here (NFR-B9-2-001)" >&2; return 1 ;;
  esac
}

_test_b92_l1_011_wrapper_gated_refusal() {
  [ -f "$WRAPPER" ] || { echo "    FAIL T-011: wrapper missing (FR-B9-2-007)" >&2; return 1; }
  local work; work="$(mktemp -d -t forge-b9-2-gate-XXXXXX)"
  trap "rm -rf '$work'" RETURN
  local out="$work/target"
  local err; err=$(bash "$WRAPPER" --target "$out" --project-name "$PROBE_NAME" \
                   --reverse-domain "$PROBE_DOMAIN" 2>&1 >/dev/null)
  local rc=$?
  [ "$rc" = "3" ] || { echo "    FAIL T-011: gated wrapper exit=$rc, expected 3 while the schema is candidate (FR-B9-2-007)" >&2; return 1; }
  grep -q "REFUSAL" <<<"$err" \
    || { echo "    FAIL T-011: no structured [REFUSAL ...] on stderr (FR-B9-2-007)" >&2; return 1; }
  # ZERO filesystem writes: nothing may be created.
  [ ! -e "$out" ] || { echo "    FAIL T-011: the refusing wrapper created $out — must be zero filesystem writes (FR-B9-2-007)" >&2; return 1; }
}

_test_b92_l1_012_webpwa_spine_no_connect_client() {
  [ -d "$WEBPWA" ] || { echo "    FAIL T-012: web-pwa/ subtree missing: $WEBPWA (FR-B9-2-010)" >&2; return 1; }
  local ok=1 f
  for f in package.json.tmpl vite.config.ts.tmpl tsconfig.json.tmpl src/root.tsx.tmpl src/entry.ssr.tsx.tmpl src/routes/index.tsx.tmpl; do
    [ -f "$WEBPWA/$f" ] || { echo "    FAIL T-012: spine file missing: web-pwa/$f (FR-B9-2-010)" >&2; ok=0; }
  done
  [ ! -e "$WEBPWA/src/lib/connect-client.ts.tmpl" ] && [ ! -e "$WEBPWA/src/lib/connect-client.ts" ] \
    || { echo "    FAIL T-012: connect-client.ts present — this archetype has NO backend layer (FR-B9-2-010, ADR-B9-2-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b92_l1_013_neg_no_connectrpc_dep() {
  # NEGATIVE. Assert on the DECLARED DEPENDENCIES, not on any textual occurrence:
  # the template's `_audit` block legitimately explains WHY there is no @connectrpc
  # dependency, and a bare grep would flag that explanation as the violation.
  local pkg="$WEBPWA/package.json.tmpl"
  [ -f "$pkg" ] || { echo "    FAIL T-013: web-pwa package.json missing (see T-012)" >&2; return 1; }
  python3 - "$pkg" <<'PYEOF'
import sys, json
d = json.load(open(sys.argv[1]))
bad = [k for sec in ('dependencies', 'devDependencies', 'peerDependencies')
       for k in d.get(sec, {}) if k.startswith('@connectrpc/')]
if bad:
    print(f"    FAIL T-013: @connectrpc dependency declared in a backend-less archetype: {bad} (ADR-B9-2-001)", file=sys.stderr)
    sys.exit(1)
PYEOF
}

_test_b92_l1_014_neg_no_connect_import() {
  # NEGATIVE. Real import/require STATEMENTS only, comments stripped (block comments
  # included). Covers all four forms:
  #     import x from "…connect-client"     (classic)
  #     import "…connect-client"            (side effect — NO `from`)
  #     import("…connect-client")           (dynamic — NO `from`)
  #     require("…connect-client")
  # The previous regex demanded `from`, so the middle two slipped through: a real
  # side-effect import could sit in root.tsx with the suite green. Caught at review
  # (NIT-1) — and the earlier "fixed" claim was false because its probe was never run.
  [ -d "$WEBPWA" ] || { echo "    FAIL T-014: web-pwa/ missing (see T-012)" >&2; return 1; }
  local -a files=()
  local f
  while IFS= read -r -d '' f; do files+=("$f"); done < <(find "$WEBPWA" -type f -print0 2>/dev/null)
  local hits=""
  if [ "${#files[@]}" -gt 0 ]; then
    hits=$(_stripped_stream "${files[@]}" \
           | grep -nE "(import[[:space:]]*\\(|import[[:space:]]|require[[:space:]]*\\()" \
           | grep -E "connect-client" || true)
  fi
  [ -z "$hits" ] || {
    echo "    FAIL T-014: a real connect-client import survives (ADR-B9-2-001):" >&2
    echo "$hits" | sed 's|^|      |' >&2; return 1; }
  # And the module itself must not exist.
  [ ! -e "$WEBPWA/src/lib/connect-client.ts" ] && [ ! -e "$WEBPWA/src/lib/connect-client.ts.tmpl" ] \
    || { echo "    FAIL T-014: src/lib/connect-client.ts exists (ADR-B9-2-001)" >&2; return 1; }
}

_test_b92_l1_015_manifest_fields() {
  local man; man=$(find "$WEBPWA" -name "manifest*.json*" 2>/dev/null | head -1)
  [ -n "$man" ] || { echo "    FAIL T-015: no web app manifest under web-pwa/ (FR-B9-2-011)" >&2; return 1; }
  local ok=1 k
  for k in name short_name start_url display; do
    grep -q "\"$k\"" "$man" || { echo "    FAIL T-015: manifest missing \"$k\" (FR-B9-2-011)" >&2; ok=0; }
  done
  grep -q '"icons"' "$man" || { echo "    FAIL T-015: manifest declares no icons (FR-B9-2-011)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b92_l1_016_service_worker_and_offline_shell() {
  # Assert the REAL Qwik City mechanism, with `//` comments stripped first.
  # The previous form grepped `serviceWorker\.register|navigator\.serviceWorker`
  # across web-pwa/, which was VACUOUS: it was satisfied by a comment in
  # service-worker.ts.tmpl reading "NOT a hand-rolled navigator.serviceWorker.register
  # call". The SW body could be gutted entirely and the test stayed green (proven by
  # three escalating mutations at review). Same false-positive-on-prose class as
  # T-013/T-014, surviving here inverted as a false NEGATIVE.
  local sw="$WEBPWA/src/routes/service-worker.ts.tmpl"
  local root="$WEBPWA/src/root.tsx.tmpl"
  local ok=1

  [ -f "$sw" ] || { echo "    FAIL T-016: no src/routes/service-worker.ts under web-pwa/ (FR-B9-2-012)" >&2; return 1; }

  # setupServiceWorker() is Qwik City's SW entry point — the thing that must survive.
  grep -q "setupServiceWorker(" < <(_stripped_stream "$sw") \
    || { echo "    FAIL T-016: service-worker.ts never calls setupServiceWorker() — the Qwik City SW is not wired (FR-B9-2-012)" >&2; ok=0; }

  # <ServiceWorkerRegister /> in root.tsx is what registers it.
  # Require the JSX ELEMENT, not the bare identifier: the import line alone
  # (`ServiceWorkerRegister,`) would otherwise satisfy a substring match even after
  # the component is removed from the tree — proven by mutation D at review-fix time.
  grep -qE "<[[:space:]]*ServiceWorkerRegister" < <(_stripped_stream "$root") \
    || { echo "    FAIL T-016: root.tsx never RENDERS <ServiceWorkerRegister /> (importing it is not registering it) — the SW would never be registered (FR-B9-2-012)" >&2; ok=0; }

  # The offline shell must be a real route AND be precached by the worker.
  grep -q . < <(find "$WEBPWA/src/routes" -ipath "*offline*" -name "index.tsx.tmpl" 2>/dev/null) \
    || { echo "    FAIL T-016: no offline-shell route under src/routes/ (FR-B9-2-012)" >&2; ok=0; }
  # Require addAll specifically. `caches.open` alone is NOT precaching — the fetch
  # handler opens the same cache to READ from it, so accepting `caches.open` let a
  # gutted install handler pass (mutation E at review-fix time).
  grep -qE "\.addAll\(" < <(_stripped_stream "$sw") \
    || { echo "    FAIL T-016: the Service Worker never calls cache.addAll() — nothing is precached, so the offline shell would be unavailable exactly when it is needed (FR-B9-2-012, PWA-RULE-002)" >&2; ok=0; }

  [ "$ok" = "1" ]
}

_test_b92_l1_017_push_client_side_only() {
  [ -d "$WEBPWA" ] || { echo "    FAIL T-017: web-pwa/ missing (see T-012)" >&2; return 1; }
  local ok=1
  local -a pfiles=()
  local pf
  while IFS= read -r -d '' pf; do pfiles+=("$pf"); done < <(find "$WEBPWA" -type f -print0 2>/dev/null)
  grep -qE "pushManager\.subscribe|PushManager" < <(_stripped_stream "${pfiles[@]}") \
    || { echo "    FAIL T-017: no client-side push subscription (FR-B9-2-013)" >&2; ok=0; }

  # NEGATIVE — no push SERVER may be scaffolded. Assert on the declared DEPENDENCIES
  # and on real code, never on prose: the b9-1 schema component is literally named
  # `web-push`, pwa.yaml discusses push servers at length, and the README explains why
  # there is none. A bare grep would turn red on the first line that explains the
  # absence (review N3 — the same trap T-013/T-014 were rewritten to avoid).
  local pkg="$WEBPWA/package.json.tmpl"
  if [ -f "$pkg" ]; then
    python3 - "$pkg" <<'PYEOF' || ok=0
import sys, json
d = json.load(open(sys.argv[1]))
bad = [k for sec in ('dependencies', 'devDependencies') for k in d.get(sec, {})
       if k in ('web-push', 'web-push-libs') or k.startswith('web-push')]
if bad:
    print(f"    FAIL T-017: push-server dependency declared: {bad} — this archetype has no backend (FR-B9-2-013, ADR-B9-2-005)", file=sys.stderr)
    sys.exit(1)
PYEOF
  fi
  # And no key-generation call in real code.
  if grep -qE "generateVAPIDKeys\(|vapidKeys\(" < <(_stripped_stream "${pfiles[@]}"); then
    echo "    FAIL T-017: VAPID key generation is scaffolded — adopter responsibility (FR-B9-2-013, ADR-B9-2-005)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b92_l1_018_no_resolved_pin_in_plan() {
  # A scaffold plan must carry no RESOLVED dependency pin — pins live in the
  # standards (web-frontend.yaml / pwa.yaml) and are verify-then-pinned at implement.
  # NOTE: a bare `\d+\.\d+\.\d+` grep is NOT the check — every `source:` path
  # legitimately begins with the archetype version `2.0.0/`, and the top-level
  # `version:` key is the archetype's own. Walk the parsed values instead and ignore
  # source/target paths plus the version key.
  [ -f "$PLAN" ] || { echo "    FAIL T-018: plan absent (see T-001)" >&2; return 1; }
  _have_py_yaml || return 1
  python3 - "$PLAN" <<'PYEOF'
import sys, re, yaml
d = yaml.safe_load(open(sys.argv[1]))
pin = re.compile(r'^[~^=<>]*\d+\.\d+')
bad = []

def walk(node, path):
    if isinstance(node, dict):
        for k, v in node.items():
            if path == '' and k == 'version':
                continue                      # the archetype's own version
            walk(v, f"{path}.{k}" if path else k)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, f"{path}[{i}]")
    elif isinstance(node, str):
        leaf = path.rsplit('.', 1)[-1]
        if leaf in ('source', 'target'):
            return                            # paths, not pins
        if pin.match(node.strip()):
            bad.append(f"{path}={node!r}")

walk(d, '')
if bad:
    print(f"    FAIL T-018: resolved pin(s) in the scaffold plan (FR-B9-2-014): {bad[:5]}", file=sys.stderr)
    sys.exit(1)
PYEOF
}

_test_b92_l1_019_pwa_standard() {
  [ -f "$PWA_STD" ] || { echo "    FAIL T-019: .forge/standards/pwa.yaml missing (FR-B9-2-030, ADR-B9-2-004)" >&2; return 1; }
  local ok=1 k
  for k in version last_reviewed expires_at exception_constitutional linter_rule enforcement forbidden rationale; do
    grep -qE "^${k}:" "$PWA_STD" || { echo "    FAIL T-019: pwa.yaml missing frontmatter field '$k' (J.7 contract, FR-B9-2-031)" >&2; ok=0; }
  done
  grep -q "pwa.yaml" "$STD_INDEX" || { echo "    FAIL T-019: pwa.yaml not registered in standards/index.yml (FR-B9-2-031)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b92_l1_020_b91_pointers_resolved() {
  # Assert on PARSED component values, not raw text: the schema legitimately keeps a
  # comment recording that these four were `delivered_by: B.9.2` before this brick
  # resolved them, and a bare grep would flag that history as the violation.
  [ -f "$SCHEMA" ] || { echo "    FAIL T-020: b9-1 schema missing" >&2; return 1; }
  _have_py_yaml || return 1
  python3 - "$SCHEMA" <<'PYEOF'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
want = {'service-worker', 'web-push', 'offline-shell', 'manifest'}
bad, seen = [], set()
for c in d.get('components', []) or []:
    if not isinstance(c, dict) or c.get('name') not in want:
        continue
    seen.add(c['name'])
    if c.get('standard') != 'pwa.yaml':
        bad.append(f"{c['name']}:standard={c.get('standard')!r}")
    if 'delivered_by' in c:
        bad.append(f"{c['name']}:still-deferred")
missing = want - seen
if missing:
    bad.append(f"missing:{sorted(missing)}")
if bad:
    print(f"    FAIL T-020: B.9.1's forward-pointers unresolved (FR-B9-2-030): {bad}", file=sys.stderr)
    sys.exit(1)
PYEOF
}

_test_b92_l1_021_dispatch_key() {
  grep -qE "^  mobile-pwa-first:" "$DISPATCH" \
    || { echo "    FAIL T-021: no top-level 'mobile-pwa-first:' key in dispatch-table.yml (FR-B9-2-020)" >&2; return 1; }
  grep -qE "^  mobile-only:" "$DISPATCH" \
    || { echo "    FAIL T-021: the mobile-only: entry was removed — it is a supported legacy alias (NFR-B9-2-002)" >&2; return 1; }
}

_test_b92_l1_022_schema_still_candidate() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-022: schema missing" >&2; return 1; }
  local ok=1
  grep -qE "^stage: candidate" "$SCHEMA" || { echo "    FAIL T-022: schema is no longer 'candidate' — promotion is B.9.11's (FR-B9-2-023)" >&2; ok=0; }
  grep -qE "^scaffoldable: false" "$SCHEMA" || { echo "    FAIL T-022: schema is no longer scaffoldable:false (FR-B9-2-023)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# ─── L2 tests (opt-in) ───────────────────────────────────────────────────────

_test_b92_l2_001_init_refuses_exit3() {
  local cli="$FORGE_ROOT/cli/dist/index.js"
  if [ "${FORGE_B9_2_LIVE:-0}" != "1" ] || [ ! -f "$cli" ]; then
    echo "    SKIP T-L2-001: set FORGE_B9_2_LIVE=1 with a built+bundled CLI to run the live refusal check" >&2
    return 0
  fi
  local tmp; tmp=$(mk_tmpdir_with_trap b9-2-init)
  trap "rm -rf '$tmp'" RETURN
  ( cd "$tmp" && node "$cli" init pwaproj --archetype mobile-pwa-first --org com.example.test >/dev/null 2>&1 )
  local rc=$?
  [ "$rc" = "3" ] || { echo "    FAIL T-L2-001: exit=$rc, expected 3 (registered archetype, no scaffoldable version) (FR-B9-2-021)" >&2; return 1; }
  [ ! -d "$tmp/pwaproj" ] || { echo "    FAIL T-L2-001: a tree was rendered despite the refusal (FR-B9-2-021)" >&2; return 1; }
}

_test_b92_l2_002_webpwa_typechecks() {
  if [ "${FORGE_B9_2_NPM:-0}" != "1" ]; then
    echo "    SKIP T-L2-002: set FORGE_B9_2_NPM=1 to run npm install + tsc --noEmit on a rendered web-pwa/" >&2
    return 0
  fi
  command -v npm >/dev/null 2>&1 || { echo "    SKIP T-L2-002: npm absent" >&2; return 0; }
  local work; work="$(mktemp -d -t forge-b9-2-npm-XXXXXX)"
  trap "rm -rf '$work'" RETURN
  _render_ported "$work/out" || { echo "    FAIL T-L2-002: render failed" >&2; return 1; }
  ( cd "$work/out/web-pwa" && npm install --no-audit --no-fund >/dev/null 2>&1 \
    && npx tsc --noEmit >/dev/null 2>&1 ) \
    || { echo "    FAIL T-L2-002: npm install / tsc --noEmit failed in the rendered web-pwa/ (FR-B9-2-014)" >&2; return 1; }
}

# FR-B98-001 / FR-B98-002 — the mobile-pwa-first 2.0.0 snapshot (b9-8-snapshot).
#
# NOTE what this archive is, because the path name misleads: forge-snapshot.sh tars
# the FRAMEWORK's owned paths (.forge/framework-owned-paths.yml) to serve as the BASE
# of `forge upgrade`'s 3-way merge. It renders nothing and reads no archetype
# template — `<archetype>/<version>` is a label recording when the capture was taken.
# ai-native-rag/1.0.0.tar.gz demonstrably contains full-stack-monorepo's 2.0.0 schema.
_test_b92_l1_023_snapshot_2_0_0_present() {
  local dir; dir="$FORGE_ROOT/.forge/scaffold-snapshots/mobile-pwa-first"
  local tarball="$dir/2.0.0.tar.gz" manifest="$dir/2.0.0.sha256"
  local ok=1

  [ -f "$tarball" ] || { echo "    FAIL T-023: snapshot missing: $tarball (FR-B98-001)" >&2; return 1; }
  [ -f "$manifest" ] || { echo "    FAIL T-023: no .sha256 beside it (upgrade-policy.md:189, FR-B98-002)" >&2; ok=0; }

  if [ -f "$manifest" ] && ! ( cd "$dir" && sha256sum -c 2.0.0.sha256 ) >/dev/null 2>&1; then
    echo "    FAIL T-023: 2.0.0.tar.gz does not match its manifest (FR-B98-002)" >&2; ok=0
  fi
  # Built on Linux through the Python tarfile path, so no macOS litter — the defect
  # that cost mobile-only/1.0.0 a repack before it could be frozen.
  local ad; ad=$(tar -tzf "$tarball" 2>/dev/null | grep -c '\._' || true)
  if [ "${ad:-0}" != "0" ]; then
    echo "    FAIL T-023: $ad AppleDouble member(s) in the snapshot (FR-B98-003)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

# ─── B.9.9 — bin/forge-migrate-mobile-pwa.sh (b9-9-migrate-mobile-pwa) ───────
#
# Hosted here rather than in a new harness for two reasons. forge-ci.yml is at
# 419/420 lines (NFR-CI-002) and B.9.11 still has to register b9.test.sh. And this
# harness already owns the scaffold-plan whose entries the migration filters, plus
# _render_legacy / _render_ported — the exact fixtures these tests need.

MIGRATE_MPWA="$FORGE_ROOT/bin/forge-migrate-mobile-pwa.sh"

# FR-B99-001 — shape and exit envelope.
_test_b92_l1_024_migrate_script_shape() {
  local ok=1
  [ -f "$MIGRATE_MPWA" ] || { echo "    FAIL T-024: $MIGRATE_MPWA missing (FR-B99-001)" >&2; return 1; }
  [ -x "$MIGRATE_MPWA" ] || { echo "    FAIL T-024: not executable (FR-B99-001)" >&2; ok=0; }
  grep -qE '^set -euo pipefail' "$MIGRATE_MPWA" \
    || { echo "    FAIL T-024: no 'set -euo pipefail' (FR-B99-001)" >&2; ok=0; }
  local out; out=$(bash "$MIGRATE_MPWA" --help 2>&1); local rc=$?
  [ "$rc" = "0" ] || { echo "    FAIL T-024: --help exited $rc, expected 0 (FR-B99-001)" >&2; ok=0; }
  grep -qF -- '--target' <<<"$out" \
    || { echo "    FAIL T-024: --help does not document --target (FR-B99-001)" >&2; ok=0; }
  # No-target must be a usage error, not a crash.
  bash "$MIGRATE_MPWA" >/dev/null 2>&1; [ "$?" = "2" ] \
    || { echo "    FAIL T-024: missing --target should exit 2 (FR-B99-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# FR-B99-006 — the additive set is DERIVED from the archetype plan, not duplicated.
# A second hand-maintained list is what made b8-10b need a coverage guard.
_test_b92_l1_025_additive_set_matches_plan() {
  [ -f "$PLAN" ] || { echo "    FAIL T-025: plan absent (see T-001)" >&2; return 1; }
  _have_py_yaml || { echo "    FAIL T-025: python3+PyYAML required" >&2; return 1; }
  python3 - "$PLAN" <<'PY' >&2
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
t = d.get("templates") or []
root = {"oidc-provider.json", ".github/workflows/web-pwa-ci.yml"}
add = [e for e in t if str(e.get("target","")).startswith("web-pwa/") or e.get("target") in root]
web = [e for e in add if str(e["target"]).startswith("web-pwa/")]
bad = False
if len(web) != 23:
    print(f"    FAIL T-025: {len(web)} web-pwa/ entries in the plan, expected 23 (FR-B99-006)"); bad = True
missing = root - {e.get("target") for e in add}
if missing:
    print(f"    FAIL T-025: root additive target(s) absent from the plan: {sorted(missing)} (FR-B99-006)"); bad = True
if len(add) != 25:
    print(f"    FAIL T-025: additive filter yields {len(add)} entries, expected 25 (FR-B99-006)"); bad = True
raise SystemExit(1 if bad else 0)
PY
}

# FR-B99-004 / FR-B99-005 / NFR-B99-001 — the behavioural test: migrate a REAL
# mobile-only render and assert (a) the PWA surface arrives RENDERED, (b) the native
# tree is byte-identical afterwards.
#
# (b) is the contract. b8-10b shipped 36 raw .tmpl files into adopters' projects
# because no test ever looked at migration OUTPUT; this one looks.
_test_b92_l1_026_migration_is_additive_and_rendered() {
  [ -f "$MIGRATE_MPWA" ] || { echo "    FAIL T-026: script absent (see T-024)" >&2; return 1; }
  local work; work="$(mktemp -d -t forge-b99-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" RETURN
  _render_legacy "$work/app" || { echo "    FAIL T-026: legacy render failed" >&2; return 1; }

  # Fingerprint the native tree BEFORE.
  local before; before=$(cd "$work/app" && find . -type f -not -path './.git/*' -exec sha256sum {} + 2>/dev/null | sort)

  bash "$MIGRATE_MPWA" --target "$work/app" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" != "0" ]; then
    echo "    FAIL T-026: migration exited $rc on a clean mobile-only render (FR-B99-001)" >&2; return 1
  fi

  local ok=1
  # (a) the surface arrived, rendered.
  [ -f "$work/app/web-pwa/package.json" ] \
    || { echo "    FAIL T-026: web-pwa/package.json absent — surface not delivered (FR-B99-004)" >&2; ok=0; }
  [ -f "$work/app/oidc-provider.json" ] \
    || { echo "    FAIL T-026: oidc-provider.json absent (FR-B99-004)" >&2; ok=0; }
  local n
  n=$(find "$work/app" -name '*.tmpl' -not -path '*/.forge/templates/*' | wc -l | tr -d ' ')
  [ "$n" = "0" ] || { echo "    FAIL T-026: $n raw .tmpl file(s) written — copied, not rendered (FR-B99-004)" >&2; ok=0; }
  if grep -rqE '<project-name>|<reverse-domain>' "$work/app/web-pwa" 2>/dev/null; then
    echo "    FAIL T-026: unsubstituted placeholder under web-pwa/ (FR-B99-004)" >&2; ok=0
  fi

  # (b) THE CONTRACT: nothing that existed before may have changed.
  local after; after=$(cd "$work/app" && find . -type f -not -path './.git/*' -exec sha256sum {} + 2>/dev/null | sort)
  local changed
  changed=$(comm -23 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | wc -l | tr -d ' ')
  if [ "$changed" != "0" ]; then
    echo "    FAIL T-026: $changed pre-existing file(s) modified — the migration must be purely additive (NFR-B99-001)" >&2
    comm -23 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | head -3 | sed 's/^/      /' >&2
    ok=0
  fi
  [ "$ok" = "1" ]
}

# FR-B99-007 / NFR-B99-003 — re-running refuses rather than re-rendering.
_test_b92_l1_027_rerun_refuses() {
  [ -f "$MIGRATE_MPWA" ] || { echo "    FAIL T-027: script absent (see T-024)" >&2; return 1; }
  local work; work="$(mktemp -d -t forge-b99r-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" RETURN
  _render_legacy "$work/app" || return 1
  bash "$MIGRATE_MPWA" --target "$work/app" >/dev/null 2>&1 || {
    echo "    FAIL T-027: first migration failed (see T-026)" >&2; return 1; }
  bash "$MIGRATE_MPWA" --target "$work/app" >/dev/null 2>&1
  local rc=$?
  case "$rc" in
    7|8) ;;
    *) echo "    FAIL T-027: re-run exited $rc, expected 7 or 8 — an additive migration has nothing to converge to (NFR-B99-003)" >&2; return 1 ;;
  esac
}

# ─── B.9.10 — docs/MIGRATION-PATHS.md (b9-10-migration-paths) ────────────────
#
# Same host as B.9.9's T-024..T-027, for the same reason: forge-ci.yml sits at
# 419/420 lines against NFR-CI-002 and B.9.11 still needs the last one to register
# b9.test.sh. This harness already owns the script these guards read.
#
# EVERY check in T-028 is a PRESENCE assertion. A negative one — "the section must not
# say X" — would fire on the sentence explaining why it does not. That is the
# T-013/T-014 trap this very file carries twice, and t6-fsm-2-0-0-wiring walked into
# it again a day later.

MIGRATION_PATHS="$FORGE_ROOT/docs/MIGRATION-PATHS.md"

# The B.9 section alone, so a fact stated elsewhere in the file cannot satisfy a check.
_b910_section() {
  [ -f "$MIGRATION_PATHS" ] || return 1
  awk '/^## B\.9 /{f=1;print;next} f&&/^## /{exit} f{print}' "$MIGRATION_PATHS"
}

# FR-B910-001..004 / FR-B910-007 — the section states what an adopter needs before
# they run anything.
_test_b92_l1_028_migration_paths_section() {
  [ -f "$MIGRATION_PATHS" ] \
    || { echo "    FAIL T-028: $MIGRATION_PATHS missing (FR-B910-001)" >&2; return 1; }
  local sec; sec="$(_b910_section)"
  [ -n "$sec" ] \
    || { echo "    FAIL T-028: no '## B.9 ' section in MIGRATION-PATHS.md (FR-B910-001)" >&2; return 1; }

  local ok=1 needle fr why n=0
  while IFS='|' read -r needle fr why; do
    [ -z "$needle" ] && continue
    n=$((n + 1))
    grep -qF -- "$needle" <<<"$sec" \
      || { echo "    FAIL T-028: the section does not state '$needle' — $why ($fr)" >&2; ok=0; }
  done <<'NEEDLES'
bin/forge-migrate-mobile-pwa.sh|FR-B910-001|the driver an adopter runs
mobile-only|FR-B910-001|the source archetype
mobile-pwa-first|FR-B910-001|the target archetype
26 files added, 0 modified|FR-B910-002|the additive contract, as measured
scaffold-manifest.yaml|FR-B910-002|the only file that differs from a native render
exit 7|FR-B910-003|what an already-migrated target hits
exit 8|FR-B910-003|what a collision hits
--dry-run|FR-B910-003|the flag that makes the plan inspectable first
candidate|FR-B910-004|the target schema is not scaffoldable yet
B.9.11|FR-B910-004|and this is the brick that opens the gate
framework-owned-paths.yml|FR-B910-007|what forge upgrade will NOT propagate afterwards
NEEDLES
  # Anti-vacuity: a mangled here-doc that yields no rows would pass silently.
  [ "$n" = "11" ] \
    || { echo "    FAIL T-028: read $n needle(s) from the battery, expected 11 — the battery itself is broken" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# The rows of the `## Index` table, and nothing else.
#
# Scoped deliberately. The first version of T-029 grepped the WHOLE document for each
# driver name and passed a mutation probe that deleted the flagship's index row —
# because the rollback prose lower down happens to mention `forge-migrate-flagship.sh`
# while explaining why this migration needs no rollback flag. "The name appears
# somewhere" is not "the driver is indexed", and a guard that cannot tell them apart
# is the exact failure this brick was opened to fix.
_b910_index_rows() {
  [ -f "$MIGRATION_PATHS" ] || return 1
  awk '/^## Index/{f=1;next} f&&/^## /{exit} f&&/^\|/{print}' "$MIGRATION_PATHS"
}

# FR-B910-005 — the index covers every migration driver in the repository.
#
# The guard with a future: it fires on a migration script that ships without an index
# row. That is exactly how bin/forge-migrate-flagship.sh stayed unindexed while the
# document's first sentence claimed to index every supported migration.
_test_b92_l1_029_index_covers_every_driver() {
  [ -f "$MIGRATION_PATHS" ] \
    || { echo "    FAIL T-029: $MIGRATION_PATHS missing (FR-B910-005)" >&2; return 1; }
  local rows; rows="$(_b910_index_rows)"
  [ -n "$rows" ] \
    || { echo "    FAIL T-029: no '## Index' table in MIGRATION-PATHS.md (FR-B910-005)" >&2; return 1; }

  local ok=1 drv base n=0 nrows
  while IFS= read -r drv; do
    [ -z "$drv" ] && continue
    n=$((n + 1))
    base="$(basename "$drv")"
    grep -qF -- "$base" <<<"$rows" \
      || { echo "    FAIL T-029: $base is a migration driver with no row in the MIGRATION-PATHS.md index (FR-B910-005)" >&2; ok=0; }
  done < <(find "$FORGE_ROOT/bin" -maxdepth 1 -name 'forge-migrate-*.sh' -type f | sort)

  # Anti-vacuity, both ends: no drivers found means the sweep is broken, and a table
  # of fewer rows than drivers-plus-header means the extraction is.
  nrows=$(grep -c . <<<"$rows")
  [ "$n" -ge 2 ] \
    || { echo "    FAIL T-029: found $n migration driver(s) under bin/, expected >= 2 — this guard is not guarding (FR-B910-005)" >&2; ok=0; }
  [ "$nrows" -ge $((n + 2)) ] \
    || { echo "    FAIL T-029: the index table has $nrows row(s) for $n driver(s) — header, separator and one row per driver is the floor (FR-B910-005)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# NFR-B910-002 — the section cannot claim an ABI the script does not have.
#
# Both halves read a DELIMITED region, never the whole section, because the prose
# legitimately talks about things that are not this script's ABI:
#
#   flags — read from the fenced code blocks. The prose says there is no rollback
#           flag (FR-B910-008); a sweep of the prose would read that sentence as a
#           claim and demand `--rollback` exist.
#   codes — read from the `### Exit codes` table. The prose cites `forge init`'s
#           exit 3 (the candidate-schema refusal, asserted by T-L2-001), which is a
#           DIFFERENT binary's envelope. A guard that cannot tell the two apart would
#           push the document toward vaguer wording — the wrong trade for a brick
#           whose whole point is that documentation states checkable facts.
_test_b92_l1_030_doc_claims_track_the_script() {
  [ -f "$MIGRATE_MPWA" ] || { echo "    FAIL T-030: script absent (see T-024)" >&2; return 1; }
  local sec; sec="$(_b910_section)"
  [ -n "$sec" ] || { echo "    FAIL T-030: no B.9 section (see T-028)" >&2; return 1; }

  local ok=1 flags codes envelope f c nf=0 nc=0
  flags="$(awk '/^```/{inb=!inb;next} inb' <<<"$sec" | grep -oE -- '--[a-z][a-z-]*' | sort -u)"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    nf=$((nf + 1))
    grep -qF -- "$f" "$MIGRATE_MPWA" \
      || { echo "    FAIL T-030: the example invokes '$f', which $MIGRATE_MPWA does not accept (NFR-B910-002)" >&2; ok=0; }
  done <<<"$flags"

  envelope="$(awk '/^### Exit codes/{f=1;next} f&&/^### /{exit} f' <<<"$sec")"
  [ -n "$envelope" ] \
    || { echo "    FAIL T-030: no '### Exit codes' subsection in the B.9 section (FR-B910-003)" >&2; return 1; }
  codes="$(grep -oE 'exits? [0-9]+' <<<"$envelope" | grep -oE '[0-9]+' | sort -un)"
  while IFS= read -r c; do
    [ -z "$c" ] && continue
    nc=$((nc + 1))
    grep -qE "exit ${c}\b" "$MIGRATE_MPWA" \
      || { echo "    FAIL T-030: the section documents exit $c, which is unreachable in $MIGRATE_MPWA (NFR-B910-002)" >&2; ok=0; }
  done <<<"$codes"

  [ "$nf" -ge 2 ] \
    || { echo "    FAIL T-030: $nf flag(s) read from the section's code blocks — the invocation example is missing (FR-B910-003)" >&2; ok=0; }
  [ "$nc" -ge 4 ] \
    || { echo "    FAIL T-030: $nc exit code(s) named in the section — the refusal envelope is missing (FR-B910-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# ─── B.9.4 — the channel decision tree (b9-4-archetype-decision-tree) ────────
#
# Hosted here for the B.9.9/B.9.10 reason (forge-ci.yml at 419/420, B.9.11 needs the
# last line). The MATRIX guard is not here — it stays in b5.test.sh, which owns
# FR-IW-009; two harnesses asserting the same table is how two sources of truth start
# (ADR-B94-003).
#
# Presence assertions only. FR-B94-002 forbids the section from asserting an iOS
# platform capability, and the obvious guard for that — "the section must not say
# iOS cannot do Web Push" — would fire on the sentence explaining that the repository
# makes no such claim. So the prohibition is enforced POSITIVELY: the section must
# carry the disclaimer, and the disclaimer is what a flattened rewrite would drop.
#
# Needles name the CLAIM, never a bare word. `client-only` alone passed a mutation probe
# that deleted the load-bearing table row, because the phrase recurs two paragraphs down
# in `a client-only archetype has none`. Third time in two days (b9-2 T-029, b5's
# FR-IW-009 guard, here): a substring that occurs twice is not an assertion.

ARCHETYPES_DOC="$FORGE_ROOT/docs/ARCHETYPES.md"

_b94_section() {
  [ -f "$ARCHETYPES_DOC" ] || return 1
  awk '/^## Choosing the mobile channel/{f=1;print;next} f&&/^## /{exit} f{print}' "$ARCHETYPES_DOC"
}

# FR-B94-001 / FR-B94-002 / FR-B94-003
_test_b92_l1_031_channel_decision_tree() {
  [ -f "$ARCHETYPES_DOC" ] \
    || { echo "    FAIL T-031: $ARCHETYPES_DOC missing (FR-B94-001)" >&2; return 1; }
  local sec; sec="$(_b94_section)"
  [ -n "$sec" ] \
    || { echo "    FAIL T-031: no '## Choosing the mobile channel' section (FR-B94-001)" >&2; return 1; }

  local ok=1 needle fr why n=0
  while IFS='|' read -r needle fr why; do
    [ -z "$needle" ] && continue
    n=$((n + 1))
    grep -qF -- "$needle" <<<"$sec" \
      || { echo "    FAIL T-031: the section does not state '$needle' — $why ($fr)" >&2; ok=0; }
  done <<'NEEDLES'
pwa.yaml|FR-B94-001|the normative source of the routing rule
channel_fallback|FR-B94-001|the exact key that carries it
channel-decision|FR-B94-001|the schema phase where the choice is recorded per change
makes no claim about iOS capability|FR-B94-002|the disclaimer a flattened rewrite would drop
not assumed|FR-B94-002|the repo's own epistemic framing, which must not become an absolute
candidate|FR-B94-003|the archetype is not scaffoldable yet
exit 3|FR-B94-003|what forge init actually does today
bin/forge-migrate-mobile-pwa.sh|FR-B94-003|the only reachable path to the surface
layer_profile: client-only|FR-B94-003|no backend, no infra — contrary to what ARCHITECTURE-TARGET 6.3 diagrams
NEEDLES
  [ "$n" = "9" ] \
    || { echo "    FAIL T-031: read $n needle(s) from the battery, expected 9 — the battery is broken" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# ─── B.9.5 — bin/forge-gen-bloc.sh (b9-5-bloc-generator) ─────────────────────
#
# Same host as B.9.9/B.9.10/B.9.4's guards, same reason: forge-ci.yml is at 419/420
# lines (NFR-CI-002) and the last one is B.9.11's, to register b9.test.sh.
#
# T-033 asserts the generator's OUTPUT, not its source. b8-10b shipped 36 raw .tmpl
# files with live placeholders into adopters' projects because no test ever opened what
# a generator produced.

GEN_BLOC="$FORGE_ROOT/bin/forge-gen-bloc.sh"

# A minimal tree that satisfies the generator's preflight: a pubspec declaring
# flutter_bloc, and one descriptor. Deliberately NOT a real Flutter project — the
# generator must work from the two facts it actually reads.
_b95_fixture() {
  local root="$1"
  mkdir -p "$root/lib/presentation/cart"
  cat > "$root/pubspec.yaml" <<'PUBSPEC'
name: fixture
environment:
  sdk: ">=3.5.0 <4.0.0"
dependencies:
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
dev_dependencies:
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
PUBSPEC
  cat > "$root/lib/presentation/cart/cart.bloc.yaml" <<'DESC'
name: Cart
repository: CartRepository
events:
  - ItemAdded: {item: CartItem}
  - ItemRemoved: {id: String}
states:
  - Initial
  - Loading
  - Loaded: {items: List<CartItem>}
  - Failure: {message: String}
DESC
}

# FR-B95-001 — shape and exit envelope, matching the sibling bin/ scripts.
_test_b92_l1_032_gen_bloc_shape() {
  local ok=1
  [ -f "$GEN_BLOC" ] || { echo "    FAIL T-032: $GEN_BLOC missing (FR-B95-001)" >&2; return 1; }
  [ -x "$GEN_BLOC" ] || { echo "    FAIL T-032: not executable (FR-B95-001)" >&2; ok=0; }
  grep -qE '^set -euo pipefail' "$GEN_BLOC" \
    || { echo "    FAIL T-032: no 'set -euo pipefail' (FR-B95-001)" >&2; ok=0; }

  local out; out=$(bash "$GEN_BLOC" --help 2>&1); local rc=$?
  [ "$rc" = "0" ] || { echo "    FAIL T-032: --help exited $rc, expected 0 (FR-B95-001)" >&2; ok=0; }
  # --help IS the descriptor contract: no template ships an example (ADR-B95-002).
  local key
  for key in --target --feature --dry-run --force events: states: repository:; do
    grep -qF -- "$key" <<<"$out" \
      || { echo "    FAIL T-032: --help does not document '$key' (FR-B95-001/002)" >&2; ok=0; }
  done

  bash "$GEN_BLOC" --target . >/dev/null 2>&1; [ "$?" = "2" ] \
    || { echo "    FAIL T-032: missing --feature should exit 2 (FR-B95-001)" >&2; ok=0; }
  bash "$GEN_BLOC" --feature cart >/dev/null 2>&1; [ "$?" = "2" ] \
    || { echo "    FAIL T-032: missing --target should exit 2 (FR-B95-001)" >&2; ok=0; }

  local empty; empty="$(mktemp -d -t forge-b95e-XXXXXX)"
  bash "$GEN_BLOC" --target "$empty" --feature cart >/dev/null 2>&1
  local rc7=$?
  rm -rf "$empty"
  [ "$rc7" = "7" ] \
    || { echo "    FAIL T-032: a target with no pubspec.yaml exited $rc7, expected 7 (FR-B95-007)" >&2; ok=0; }

  [ "$ok" = "1" ]
}

# FR-B95-003..006 / NFR-B95-003 — the OUTPUT.
_test_b92_l1_033_gen_bloc_output() {
  [ -f "$GEN_BLOC" ] || { echo "    FAIL T-033: generator absent (see T-032)" >&2; return 1; }
  local work; work="$(mktemp -d -t forge-b95-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" RETURN
  _b95_fixture "$work"

  bash "$GEN_BLOC" --target "$work" --feature cart >/dev/null 2>&1
  local rc=$?
  [ "$rc" = "0" ] \
    || { echo "    FAIL T-033: generation exited $rc on a clean fixture (FR-B95-001)" >&2; return 1; }

  local ok=1 f
  for f in lib/presentation/cart/cart_event.dart \
           lib/presentation/cart/cart_state.dart \
           lib/presentation/cart/cart_bloc.dart \
           test/presentation/cart/cart_bloc_test.dart; do
    [ -f "$work/$f" ] || { echo "    FAIL T-033: $f not written (FR-B95-004)" >&2; ok=0; }
  done
  [ "$ok" = "1" ] || return 1

  local ev st bl te
  ev="$(cat "$work/lib/presentation/cart/cart_event.dart")"
  st="$(cat "$work/lib/presentation/cart/cart_state.dart")"
  bl="$(cat "$work/lib/presentation/cart/cart_bloc.dart")"
  te="$(cat "$work/test/presentation/cart/cart_bloc_test.dart")"

  # Needles are FULL declarations, never a bare identifier — and where the generator has
# TWO emission sites for the same construct, each site gets its own needle. A single
# `List<Object?> get props` needle passed a mutation that broke the base classes,
# because the field-carrying branch still emitted it. Fourth instance in three days of
# a needle satisfied by something other than what it names. b9-4's `client-only` needle
  # was correctly scoped to its section and still survived the mutation that deleted the
  # row it protected, because the word recurred two paragraphs down.
  local needle
  while IFS='|' read -r needle why; do
    [ -z "$needle" ] && continue
    grep -qF -- "$needle" <<<"$ev$st$bl$te" \
      || { echo "    FAIL T-033: generated output lacks '$needle' — $why" >&2; ok=0; }
  done <<'NEEDLES'
abstract class CartEvent extends Equatable|the event base, AuthEvent's idiom (FR-B95-003)
class CartItemAdded extends CartEvent|one class per declared event (FR-B95-003)
class CartItemRemoved extends CartEvent|the second declared event (FR-B95-003)
final CartItem item;|the event's declared field, with its declared type (FR-B95-002)
abstract class CartState extends Equatable|the state base (FR-B95-003)
class CartLoaded extends CartState|a state carrying fields (FR-B95-003)
final List<CartItem> items;|a generic field type survives the round trip (FR-B95-002)
List<Object?> get props => [];|the BASE classes' empty props (FR-B95-003)
List<Object?> get props => [item];|and the field-carrying class's own props — a SECOND emission site, which is why one needle for both passed a mutation that broke only the bases (FR-B95-003)
class CartBloc extends Bloc<CartEvent, CartState>|the bloc (FR-B95-003)
CartBloc({required CartRepository repository})|the repository dependency (FR-B95-003)
super(const CartInitial())|the first declared state is the initial one (FR-B95-007)
on<CartItemAdded>|the handler registration (FR-B95-003)
throw UnimplementedError|handlers throw; an empty body looks implemented (FR-B95-005)
blocTest<CartBloc, CartState>|the generated tripwire test (FR-B95-006)
isA<UnimplementedError>()|the tripwire asserts the stub (ADR-B95-003)
extends Mock implements CartRepository|the mocktail double, no new dependency (FR-B95-006)
NEEDLES

  # One handler and one blocTest per declared event — a generator that emits the first
  # and stops would satisfy every needle above.
  local n_on n_test
  n_on=$(grep -c 'on<Cart' <<<"$bl")
  n_test=$(grep -c 'blocTest<' <<<"$te")
  [ "$n_on" = "2" ] \
    || { echo "    FAIL T-033: $n_on on<Event> registration(s) for 2 declared events (FR-B95-003)" >&2; ok=0; }
  [ "$n_test" = "2" ] \
    || { echo "    FAIL T-033: $n_test blocTest(s) for 2 declared events (FR-B95-006)" >&2; ok=0; }

  # No unsubstituted placeholder, the b8-10b failure.
  if grep -qE '<project-name>|<feature>|TODO_REPLACE' <<<"$ev$st$bl$te"; then
    echo "    FAIL T-033: an unsubstituted placeholder reached the generated output (NFR-B95-003)" >&2
    ok=0
  fi

  # Re-running must refuse rather than silently discard the adopter's handlers.
  bash "$GEN_BLOC" --target "$work" --feature cart >/dev/null 2>&1
  local rc2=$?
  [ "$rc2" = "8" ] \
    || { echo "    FAIL T-033: re-run exited $rc2, expected 8 (collision refusal, FR-B95-008)" >&2; ok=0; }

  [ "$ok" = "1" ]
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.9.2 — b9-2-web-pwa — level $LEVEL ──"
  run_test _test_b92_l1_001_plan_exists
  run_test _test_b92_l1_002_sources_resolve
  run_test _test_b92_l1_003_all_48_ported
  run_test _test_b92_l1_004_mobile_only_untouched
  run_test _test_b92_l1_005_no_jinja_tokens_in_contents
  run_test _test_b92_l1_006_angle_placeholders_used
  run_test _test_b92_l1_007_byte_equivalence
  run_test _test_b92_l1_008_scaffold_manifest_emitted
  run_test _test_b92_l1_009_kotlin_relocation
  run_test _test_b92_l1_010_overlay_untouched
  run_test _test_b92_l1_011_wrapper_gated_refusal
  run_test _test_b92_l1_012_webpwa_spine_no_connect_client
  run_test _test_b92_l1_013_neg_no_connectrpc_dep
  run_test _test_b92_l1_014_neg_no_connect_import
  run_test _test_b92_l1_015_manifest_fields
  run_test _test_b92_l1_016_service_worker_and_offline_shell
  run_test _test_b92_l1_017_push_client_side_only
  run_test _test_b92_l1_018_no_resolved_pin_in_plan
  run_test _test_b92_l1_019_pwa_standard
  run_test _test_b92_l1_020_b91_pointers_resolved
  run_test _test_b92_l1_021_dispatch_key
  run_test _test_b92_l1_022_schema_still_candidate
  case "$LEVEL" in
    *2*)
      run_test _test_b92_l2_001_init_refuses_exit3
      run_test _test_b92_l2_002_webpwa_typechecks
      ;;
  esac
  run_test _test_b92_l1_023_snapshot_2_0_0_present
  run_test _test_b92_l1_024_migrate_script_shape
  run_test _test_b92_l1_025_additive_set_matches_plan
  run_test _test_b92_l1_026_migration_is_additive_and_rendered
  run_test _test_b92_l1_027_rerun_refuses
  run_test _test_b92_l1_028_migration_paths_section
  run_test _test_b92_l1_029_index_covers_every_driver
  run_test _test_b92_l1_030_doc_claims_track_the_script
  run_test _test_b92_l1_031_channel_decision_tree
  run_test _test_b92_l1_032_gen_bloc_shape
  run_test _test_b92_l1_033_gen_bloc_output
  print_summary
}

main
