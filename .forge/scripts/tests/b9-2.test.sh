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
  out=$(diff -r \
        --exclude=web-pwa \
        --exclude=scaffold-manifest.yaml \
        --exclude=oidc-provider.json \
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
  find "$WEBPWA/src/routes" -ipath "*offline*" -name "index.tsx.tmpl" 2>/dev/null | grep -q . \
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
  print_summary
}

main
