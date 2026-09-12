#!/usr/bin/env bash
# Forge — B.9.3 shared OIDC across the app and web-pwa surfaces
# <!-- Audit: B.9.3 (b9-3-shared-oidc) — browser OIDC client + shared provider config -->
#
# L1 (hermetic: bash + python3, no network, no npm, no provider):
#   T-001  the auth module exists under web-pwa/src/lib/auth/ (FR-B9-3-001)
#   T-002  oauth4webapi declared in dependencies at a resolved pin (NFR-B9-3-002)
#   T-003  NEGATIVE — no @connectrpc/* in dependencies (FR-B9-3-002)
#   T-004  NEGATIVE — no connect-client import, all 4 forms (FR-B9-3-002)
#   T-005  code_challenge_method is S256; `plain` absent (FR-B9-3-001/003)
#   T-006  NEGATIVE Math.random absent AND POSITIVE crypto.getRandomValues +
#          crypto.subtle.digest actually called (FR-B9-3-003)
#   T-007  state and nonce both minted and sent (FR-B9-3-004)
#   T-009  a callback route exists under src/routes/ (FR-B9-3-005)
#   T-009a-proxy  PROXY ONLY, NOT A PROOF — processAuthorizationCodeResponse imported
#          and appears called. A static match cannot prove the call is on the live
#          path; the proof is T-L2-002 (FR-B9-3-009, partial)
#   T-009a-state  validateAuthResponse receives the pending state STRING, never
#          skipStateCheck / expectNoState (FR-B9-3-004)
#   T-009b NEGATIVE — the ID token is not hand-decoded (FR-B9-3-009)
#   T-009c expectedNonce receives the minted nonce STRING — not omitted, not the
#          expectNoNonce symbol whose default silently disables the check (FR-B9-3-009)
#   T-009d requireIdToken: true is set (FR-B9-3-009)
#   T-010  the URL is scrubbed of code/state after completion (FR-B9-3-005)
#   T-011  discovery via <issuer>/.well-known + discoveryUrl override; no hard-coded
#          provider endpoint (FR-B9-3-006)
#   T-012  refresh + logout present; end_session_endpoint honoured (FR-B9-3-007)
#   T-013  expiry skew is 30 s, matching auth_token.dart:17 (FR-B9-3-008)
#   T-014  the shared config declares issuer/scopes ONCE (FR-GL-B9-3-020)
#   T-015  ... and clientId/redirectUri PER SURFACE (FR-GL-B9-3-021)
#   T-016  the TS port exposes login/refresh/logout/getCurrentToken (FR-GL-B9-3-022)
#   T-017  docs state the sessions are independent and NOT SSO (FR-GL-B9-3-023)
#   T-018  NEGATIVE — no localStorage write at all, and no TOKEN material in
#          sessionStorage, in the auth modules. PROXY: the behavioural proof that no
#          token reaches either store is T-L2-004 (FR-B9-3-030)
#   T-019  the README documents the reload cost + the BFF escape hatch (FR-B9-3-031)
#   T-020  the token model leaks nothing via toString/toJSON (FR-B9-3-032)
#   T-021  the T3 gap is recorded; identity.yaml byte-unchanged (FR-B9-3-040)
#   T-022  lib/ ios/ android/ test/ byte-unchanged (NFR-B9-3-001)
#   T-023  schema still candidate; dispatch entry still status: candidate (NFR-B9-3-006)
#
# L2 (opt-in, needs npm + network):
#   T-L2-001  npm install && tsc --noEmit on the rendered web-pwa/ (NFR-B9-3-002)
#   T-L2-002  THE PROOF of FR-B9-3-009 — stubbed-fetch rejection table, 7 cases
#   T-L2-003  (= design T-008) stubbed fetch: a mismatched state means the token
#             endpoint is NEVER requested (FR-B9-3-004)
#   T-L2-004  stubbed fetch + instrumented storage: a REAL login leaves no token
#             string in sessionStorage/localStorage — the proof behind T-018's
#             identifier-level proxy (FR-B9-3-030)
#
# WHY THE L2 LEGS MATTER MORE THAN USUAL HERE. Two successive drafts of this brick's
# spec specified tests that could not detect a missing ID-token validation — the exact
# property the dependency was chosen for. The L1 rows below are cheap structural
# guards; T-L2-002 is the only assertion that cannot be satisfied by decoration.

set -uo pipefail

# NEVER write `printf '%s' "$out" | grep -q ...` in this file. Use a here-string:
#   grep -qE "..." <<<"$out"
#
# WHY. `grep -q` exits at the first match. Once the auth stream outgrew the 64 KiB
# pipe buffer, `printf` was still writing when grep left, took SIGPIPE, and exited
# 141 — which `pipefail` then promoted to the pipeline's status. A POSITIVE
# assertion written that way reports "absent" for a pattern that is present, and a
# NEGATIVE one (`grep -q X && fail`) does something far worse: the violation
# matches, the pipeline still exits non-zero, the `&&` never fires, and the check
# passes while detecting nothing. Four negatives in this file were silently dead
# that way — T-005 `plain`, T-006 `Math.random`, T-009a-state `skipStateCheck`,
# T-009c `expectNoNonce` — and the bug was invisible during RED because the files
# under test did not exist yet. A here-string has no pipe and no reader to race.

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

TREE="$FORGE_ROOT/.forge/templates/archetypes/mobile-pwa-first/2.0.0"
WEBPWA="$TREE/web-pwa"
AUTHDIR="$WEBPWA/src/lib/auth"
PKG="$WEBPWA/package.json.tmpl"
README="$WEBPWA/README.md.tmpl"
SHARED="$TREE/oidc-provider.json.tmpl"
SCHEMA="$FORGE_ROOT/.forge/schemas/mobile-pwa-first/2.0.0.yaml"
DISPATCH="$FORGE_ROOT/.forge/scaffolding/dispatch-table.yml"
IDENTITY="$FORGE_ROOT/.forge/standards/identity.yaml"
DART_TOKEN="$TREE/lib/domain/auth/auth_token.dart.tmpl"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

_have_py() { command -v python3 >/dev/null 2>&1; }
_have_py_yaml() { command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; }

# Emit `path:line:content` with BOTH `//` and `/* */` comments blanked, over a
# NUL-safe file list. The negatives below MUST never match prose: these modules
# deliberately DOCUMENT what they exclude, and an unstripped grep flags that
# documentation as the violation — the trap that produced three false positives
# in b9-2 (T-013/T-014/T-017).
_stripped() {
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

_auth_files() {
  local -a out=()
  local f
  while IFS= read -r -d '' f; do out+=("$f"); done < <(find "$AUTHDIR" -type f -print0 2>/dev/null)
  # The callback route is part of the auth path even though it lives under routes/.
  while IFS= read -r -d '' f; do out+=("$f"); done < <(find "$WEBPWA/src/routes/auth" -type f -print0 2>/dev/null)
  printf '%s\n' "${out[@]}"
}

_auth_stripped() {
  local -a files=()
  local f
  while IFS= read -r f; do [ -n "$f" ] && files+=("$f"); done < <(_auth_files)
  [ "${#files[@]}" -gt 0 ] || return 1
  _stripped "${files[@]}"
}

# Unchanged vs HEAD: 0 clean, 1 changed, 2 not a git repo.
#
# `git diff HEAD` sees modifications and deletions of TRACKED files only — an ADDED
# file is untracked and invisible to it, so "byte-unchanged" was blind to exactly the
# kind of drift a template port introduces (verified: a new file under 2.0.0/lib/ left
# the check clean). `git status --porcelain` reports untracked paths too.
_git_clean_vs_head() {
  git -C "$FORGE_ROOT" rev-parse --git-dir >/dev/null 2>&1 || return 2
  git -C "$FORGE_ROOT" diff --quiet HEAD -- "$@" 2>/dev/null || return 1
  [ -z "$(git -C "$FORGE_ROOT" status --porcelain -- "$@" 2>/dev/null)" ] || return 1
  return 0
}

# ─── L1 ──────────────────────────────────────────────────────────────────────

_test_b93_l1_001_auth_module_exists() {
  [ -d "$AUTHDIR" ] || { echo "    FAIL T-001: no auth module at web-pwa/src/lib/auth/ (FR-B9-3-001)" >&2; return 1; }
  grep -q . < <(find "$AUTHDIR" -type f -name '*.ts.tmpl' 2>/dev/null) \
    || { echo "    FAIL T-001: auth module dir is empty (FR-B9-3-001)" >&2; return 1; }
}

_test_b93_l1_002_oauth4webapi_pinned() {
  [ -f "$PKG" ] || { echo "    FAIL T-002: web-pwa package.json missing" >&2; return 1; }
  _have_py || return 1
  python3 - "$PKG" <<'PYEOF'
import sys, json, re
d = json.load(open(sys.argv[1]))
deps = d.get('dependencies', {})
v = deps.get('oauth4webapi')
if not v:
    print("    FAIL T-002: oauth4webapi not in dependencies (NFR-B9-3-002)", file=sys.stderr); sys.exit(1)
if not re.match(r'^[\^~=]?\d+\.\d+\.\d+$', str(v)):
    print(f"    FAIL T-002: oauth4webapi version {v!r} is not a resolved pin (NFR-B9-3-002)", file=sys.stderr); sys.exit(1)
PYEOF
}

_test_b93_l1_003_neg_no_connectrpc() {
  [ -f "$PKG" ] || { echo "    FAIL T-003: package.json missing (see T-002)" >&2; return 1; }
  python3 - "$PKG" <<'PYEOF'
import sys, json
d = json.load(open(sys.argv[1]))
bad = [k for sec in ('dependencies','devDependencies','peerDependencies')
       for k in d.get(sec, {}) if k.startswith('@connectrpc/')]
if bad:
    print(f"    FAIL T-003: @connectrpc dependency is back: {bad} — ADR-B9-2-001 removed it; this archetype has no backend (FR-B9-3-002)", file=sys.stderr)
    sys.exit(1)
PYEOF
}

_test_b93_l1_004_neg_no_connect_client_import() {
  [ -d "$WEBPWA" ] || { echo "    FAIL T-004: web-pwa missing" >&2; return 1; }
  local -a files=()
  local f
  while IFS= read -r -d '' f; do files+=("$f"); done < <(find "$WEBPWA" -type f -print0 2>/dev/null)
  local hits=""
  [ "${#files[@]}" -gt 0 ] && hits=$(_stripped "${files[@]}" \
      | grep -E "(import[[:space:]]*\(|import[[:space:]]|require[[:space:]]*\()" \
      | grep -E "connect-client" || true)
  [ -z "$hits" ] || { echo "    FAIL T-004: a connect-client import survives (FR-B9-3-002):" >&2
                      echo "$hits" | sed 's|^|      |' >&2; return 1; }
}

_test_b93_l1_005_s256() {
  local out; out=$(_auth_stripped) || { echo "    FAIL T-005: no auth files (see T-001)" >&2; return 1; }
  local ok=1
  grep -q "S256" <<<"$out" || { echo "    FAIL T-005: code_challenge_method S256 not used (FR-B9-3-001)" >&2; ok=0; }
  grep -qE "code_challenge_method[^\"']*[\"']plain" <<<"$out" \
    && { echo "    FAIL T-005: 'plain' code_challenge_method present (FR-B9-3-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b93_l1_006_csprng() {
  local out; out=$(_auth_stripped) || { echo "    FAIL T-006: no auth files (see T-001)" >&2; return 1; }
  local ok=1
  # POSITIVE — absence of the wrong primitive does not establish presence of the right
  # one, and FR-B9-3-003 requires the CSPRNG affirmatively (review N3).
  grep -qE "crypto\.getRandomValues|generateRandomCodeVerifier" <<<"$out" \
    || { echo "    FAIL T-006: no CSPRNG call (crypto.getRandomValues / generateRandomCodeVerifier) (FR-B9-3-003)" >&2; ok=0; }
  grep -qE "crypto\.subtle\.digest|calculatePKCECodeChallenge" <<<"$out" \
    || { echo "    FAIL T-006: no SHA-256 challenge derivation (FR-B9-3-003)" >&2; ok=0; }
  # NEGATIVE
  grep -q "Math\.random" <<<"$out" \
    && { echo "    FAIL T-006: Math.random in the auth path (FR-B9-3-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b93_l1_007_state_and_nonce() {
  local out; out=$(_auth_stripped) || { echo "    FAIL T-007: no auth files (see T-001)" >&2; return 1; }
  local ok=1
  # The header promises "minted AND SENT", so assert both halves rather than the mere
  # presence of the words: `\bstate\b` alone matched 13 places and `\bnonce\b` 7,
  # almost all of them type declarations and parameter names, none of which put the
  # value on the authorization request.
  local p
  for p in state nonce; do
    grep -qE "generateRandom(State|Nonce)" <<<"$out" \
      || { echo "    FAIL T-007: $p is not minted from the CSPRNG generators (FR-B9-3-004)" >&2; ok=0; break; }
  done
  for p in state nonce; do
    grep -qE "searchParams\.set\([\"']${p}[\"']" <<<"$out" \
      || { echo "    FAIL T-007: '$p' is never SET on the authorization request — minting it is not sending it (FR-B9-3-004)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b93_l1_009_callback_route() {
  grep -q . < <(find "$WEBPWA/src/routes" -ipath "*auth*" -name "index.tsx.tmpl" 2>/dev/null) \
    || { echo "    FAIL T-009: no callback route under src/routes/auth/ (FR-B9-3-005)" >&2; return 1; }
}

_test_b93_l1_009a_proxy_validating_call() {
  # PROXY, NOT A PROOF. A static match shows a token exists in a file; it cannot show
  # the call is on the path the callback takes (dead branch, uncalled helper, or a
  # computed-then-discarded result all pass). The proof is T-L2-002.
  local out; out=$(_auth_stripped) || { echo "    FAIL T-009a-proxy: no auth files (see T-001)" >&2; return 1; }
  grep -q "processAuthorizationCodeResponse" <<<"$out" \
    || { echo "    FAIL T-009a-proxy: processAuthorizationCodeResponse absent. NOTE: validateAuthResponse does NOT satisfy this — it takes/returns URLSearchParams and validates no ID token (index.d.ts:2258 vs :1833) (FR-B9-3-009)" >&2; return 1; }
}

_test_b93_l1_009a_state_string() {
  local out; out=$(_auth_stripped) || return 1
  local ok=1
  grep -q "validateAuthResponse" <<<"$out" \
    || { echo "    FAIL T-009a-state: validateAuthResponse not used for the state check (FR-B9-3-004)" >&2; ok=0; }
  # skipStateCheck / expectNoState satisfy "is invoked" while checking nothing.
  grep -qE "skipStateCheck|expectNoState" <<<"$out" \
    && { echo "    FAIL T-009a-state: skipStateCheck/expectNoState defeats the state check (index.d.ts:2231/:2237) (FR-B9-3-004)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b93_l1_009b_neg_no_hand_decode() {
  local out; out=$(_auth_stripped) || return 1
  local hits
  hits=$(grep -nE "atob\(|jwt-decode|\.split\([\"']\.[\"']\)" <<<"$out" || true)
  [ -z "$hits" ] || { echo "    FAIL T-009b: the ID token looks hand-decoded — no signature verification (FR-B9-3-009):" >&2
                      echo "$hits" | head -5 | sed 's|^|      |' >&2; return 1; }
}

_test_b93_l1_009c_expected_nonce_string() {
  local out; out=$(_auth_stripped) || return 1
  local ok=1
  grep -q "expectedNonce" <<<"$out" \
    || { echo "    FAIL T-009c: expectedNonce not passed — its default is expectNoNonce, so the nonce is silently NOT validated (index.d.ts:1802) (FR-B9-3-009)" >&2; ok=0; }
  grep -q "expectNoNonce" <<<"$out" \
    && { echo "    FAIL T-009c: expectNoNonce disables the nonce check (FR-B9-3-009)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b93_l1_009d_require_id_token() {
  local out; out=$(_auth_stripped) || return 1
  grep -qE "requireIdToken[[:space:]]*:[[:space:]]*true" <<<"$out" \
    || { echo "    FAIL T-009d: requireIdToken: true not set — a provider returning no ID token would resolve with nothing validated (index.d.ts:1813) (FR-B9-3-009)" >&2; return 1; }
}

_test_b93_l1_010_url_scrubbed() {
  local out; out=$(_auth_stripped) || return 1
  grep -qE "replaceState|history\.replace|redirect\(" <<<"$out" \
    || { echo "    FAIL T-010: nothing scrubs code/state from the address bar (FR-B9-3-005)" >&2; return 1; }
}

_test_b93_l1_011_discovery() {
  local out; out=$(_auth_stripped) || return 1
  local ok=1
  grep -qE "discoveryRequest|well-known/openid-configuration" <<<"$out" \
    || { echo "    FAIL T-011: no discovery (FR-B9-3-006)" >&2; ok=0; }
  # `config.discoveryUrl`, not a bare `discoveryUrl`. The identifier also appears as
  # the OPTIONAL FIELD DECLARATION in config.ts's OidcProviderConfig, so a bare match
  # was satisfied by the type alone: deleting the entire override branch from
  # discovery.ts left this row GREEN (verified). Requiring the property ACCESS ties it
  # to a use site.
  grep -qE "config\.discoveryUrl" <<<"$out" \
    || { echo "    FAIL T-011: discoveryUrl declared but never read — the override does nothing (FR-B9-3-006)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b93_l1_012_refresh_logout() {
  local out; out=$(_auth_stripped) || return 1
  local ok=1
  # Anchored to the DEFINITIONS. A bare `refresh` matches the `refreshToken` field on
  # the token model, so deleting refresh() from the port entirely left this row GREEN
  # (verified) — token.ts alone satisfied it.
  # Accepts a function declaration, an exported const/arrow, or a re-export. The
  # first version demanded `export [async] function`, which would have turned RED
  # on a legitimate refactor to `export const refresh = async () => …` — a false
  # ALARM rather than a false pass, but one whose message would not have pointed
  # at the syntax form.
  grep -qE "export[[:space:]]+(async[[:space:]]+)?function[[:space:]]+refresh\\b|export[[:space:]]+(const|let|var)[[:space:]]+refresh\\b|export[[:space:]]*\\{[^}]*\\brefresh\\b" <<<"$out" \
    || { echo "    FAIL T-012: no refresh() exported from the port — 'refreshToken' as a field name does not count (FR-B9-3-007)" >&2; ok=0; }
  grep -qE "export[[:space:]]+(async[[:space:]]+)?function[[:space:]]+logout\\b|export[[:space:]]+(const|let|var)[[:space:]]+logout\\b|export[[:space:]]*\\{[^}]*\\blogout\\b" <<<"$out" \
    || { echo "    FAIL T-012: no logout() exported from the port (FR-B9-3-007)" >&2; ok=0; }
  grep -q "end_session_endpoint" <<<"$out" || { echo "    FAIL T-012: end_session_endpoint not honoured (FR-B9-3-007)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b93_l1_013_skew_parity() {
  local out; out=$(_auth_stripped) || return 1
  # Anchored to the CONSTANT, not a bare 30. `_stripped` emits `path:LINE:content`,
  # so `\b30\b` matched the line-number prefix of any auth file with 30+ lines and
  # the row could never fail.
  grep -qE "EXPIRY_SKEW_SECONDS[[:space:]]*=[[:space:]]*30\b" <<<"$out" \
    || { echo "    FAIL T-013: no 30 s expiry skew — auth_token.dart:17 uses 30 s and a divergence produces surface-dependent auth bugs (FR-B9-3-008)" >&2; return 1; }
  grep -q "seconds: 30" "$DART_TOKEN" 2>/dev/null \
    || { echo "    FAIL T-013: the Dart side no longer uses a 30 s skew — parity target moved (FR-B9-3-008)" >&2; return 1; }
}

_test_b93_l1_014_shared_issuer_once() {
  [ -f "$SHARED" ] || { echo "    FAIL T-014: no shared provider config at 2.0.0/oidc-provider.json (FR-GL-B9-3-020)" >&2; return 1; }
  python3 - "$SHARED" <<'PYEOF'
import sys, json
d = json.load(open(sys.argv[1]))
for k in ('issuer', 'scopes'):
    if k not in d:
        print(f"    FAIL T-014: shared config missing {k!r} (FR-GL-B9-3-020)", file=sys.stderr); sys.exit(1)
if isinstance(d.get('surfaces'), dict):
    for name, s in d['surfaces'].items():
        if 'issuer' in s:
            print(f"    FAIL T-014: surface {name!r} redeclares issuer — it must be declared ONCE (FR-GL-B9-3-020)", file=sys.stderr); sys.exit(1)
PYEOF
}

_test_b93_l1_015_per_surface_client() {
  [ -f "$SHARED" ] || { echo "    FAIL T-015: shared config missing (see T-014)" >&2; return 1; }
  python3 - "$SHARED" <<'PYEOF'
import sys, json
d = json.load(open(sys.argv[1]))
surfaces = d.get('surfaces')
if not isinstance(surfaces, dict):
    print("    FAIL T-015: no surfaces map (FR-GL-B9-3-021)", file=sys.stderr); sys.exit(1)
missing = [n for n in ('app', 'web-pwa') if n not in surfaces]
if missing:
    print(f"    FAIL T-015: surfaces missing {missing} (FR-GL-B9-3-021)", file=sys.stderr); sys.exit(1)
for name in ('app', 'web-pwa'):
    for k in ('clientId', 'redirectUri'):
        if k not in surfaces[name]:
            print(f"    FAIL T-015: surfaces.{name} missing {k!r} — the two surfaces normally need DIFFERENT client registrations (FR-GL-B9-3-021)", file=sys.stderr); sys.exit(1)
if surfaces['app']['redirectUri'] == surfaces['web-pwa']['redirectUri']:
    print("    FAIL T-015: both surfaces share one redirectUri — a custom-scheme and an https redirect are different client entries (FR-GL-B9-3-021)", file=sys.stderr); sys.exit(1)
PYEOF
}

_test_b93_l1_016_port_parity() {
  local out; out=$(_auth_stripped) || return 1
  local ok=1 op
  # Each operation must be an EXPORTED FUNCTION, not merely a substring somewhere in
  # the module. `refresh` matched the `refreshToken` field, so deleting refresh() from
  # the port left this row GREEN (verified); `login` and `getCurrentToken` were only
  # ever satisfied by their real definitions, but all four are anchored for symmetry.
  for op in login refresh logout getCurrentToken; do
    grep -qE "export[[:space:]]+(async[[:space:]]+)?function[[:space:]]+${op}\b|export[[:space:]]+(const|let|var)[[:space:]]+${op}\b|export[[:space:]]*\{[^}]*\b${op}\b" <<<"$out" \
      || { echo "    FAIL T-016: port operation '$op' is not exported (function, const or re-export) — must mirror the Dart AuthRepository (FR-GL-B9-3-022)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b93_l1_017_not_sso() {
  [ -f "$README" ] || { echo "    FAIL T-017: web-pwa README missing" >&2; return 1; }
  local ok=1
  grep -qiE "independent session|not single sign-on|not SSO" "$README" \
    || { echo "    FAIL T-017: the README does not state the sessions are independent and NOT SSO (FR-GL-B9-3-023)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b93_l1_018_neg_no_token_in_web_storage() {
  # Scoped per review N2: comments stripped, auth modules ONLY (not the whole surface),
  # and member expressions rather than the bare identifier — FR-B9-3-031 REQUIRES the
  # README to discuss browser storage, and a naive matcher would trip on it.
  #
  # NARROWED, DELIBERATELY, and narrower than this row's first draft. That draft
  # forbade EVERY `.setItem` in the auth modules, which is stricter than the
  # requirement it enforces: FR-B9-3-030 forbids persisting the REFRESH TOKEN.
  # Signing in is a full-page navigation, so the document that mints the PKCE
  # `code_verifier` is destroyed before the callback runs and the transaction MUST
  # outlive it — no redirect-flow browser client can avoid that. The blanket rule
  # therefore did not describe a safer scaffold, it described one that cannot
  # complete a login, and would have been "satisfied" only by deleting the feature.
  #
  # What is enforced instead, and why it is not weaker where it counts:
  #   - `localStorage.setItem` is forbidden OUTRIGHT. It outlives the tab; nothing
  #     in this flow has any business there.
  #   - `sessionStorage.setItem` is forbidden for anything naming token material.
  #     The transaction triple (state/nonce/codeVerifier) is single-use, tab-scoped,
  #     consumed on read, and worthless without the authorization code.
  # This row is a PROXY: it reads identifiers, so it cannot see what a value
  # actually holds at runtime. The proof is T-L2-004, which drives a real login and
  # then greps both stores for the actual token strings.
  local out; out=$(_auth_stripped) || return 1
  local ok=1 hits

  hits=$(grep -nE "localStorage\.setItem" <<<"$out" || true)
  [ -z "$hits" ] || { echo "    FAIL T-018: localStorage.setItem in the auth path — it outlives the tab (FR-B9-3-030, ADR-B9-3-005):" >&2
                      echo "$hits" | head -5 | sed 's|^|      |' >&2; ok=0; }

  # `.*`, NOT `[^\n]*`. In POSIX ERE a bracket expression treats backslash as a
  # literal, so `[^\n]` means "not a backslash and not the letter n". A violation
  # like sessionStorage.setItem("auth.session", refreshToken) has an `n` between
  # the two halves, does NOT match, and the row passes while the token is written.
  # Confirmed under GNU grep 3.11 (what CI runs): realistic violation 0 hits, `.*`
  # 1 hit. It survived the first mutation probe only because that probe used the
  # key "k", which contains no `n` — the probe string, not the check, was lucky.
  # ugrep (what `grep` resolves to on some dev machines) treats `\n` as a newline
  # escape and hides this completely.
  hits=$(grep -nE "sessionStorage\.setItem.*(accessToken|refreshToken|idToken|access_token|refresh_token|id_token|TokenSet)" <<<"$out" || true)
  [ -z "$hits" ] || { echo "    FAIL T-018: token material written to sessionStorage — the browser has no Keychain equivalent (FR-B9-3-030, ADR-B9-3-005):" >&2
                      echo "$hits" | head -5 | sed 's|^|      |' >&2; ok=0; }

  [ "$ok" = "1" ]
}

_test_b93_l1_019_readme_cost() {
  [ -f "$README" ] || return 1
  local ok=1
  grep -qiE "reload|prompt=none" "$README" || { echo "    FAIL T-019: the README does not state the reload cost (FR-B9-3-031)" >&2; ok=0; }
  grep -qiE "\bBFF\b|backend-for-frontend" "$README" || { echo "    FAIL T-019: the README does not name the BFF escape hatch (FR-B9-3-031)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b93_l1_020_no_token_leak() {
  local out; out=$(_auth_stripped) || return 1
  grep -qE "toJSON|toString" <<<"$out" \
    || return 0   # nothing overridden at all is acceptable — nothing to leak through
  grep -qE "(toJSON|toString).*(accessToken|refreshToken|idToken)" <<<"$out" \
    && { echo "    FAIL T-020: the token model exposes token material via toString/toJSON — auth_token.dart uses stringify => false (FR-B9-3-032)" >&2; return 1; }
  return 0
}

_test_b93_l1_021_t3_gap_and_identity_untouched() {
  local ok=1
  grep -qiE "T3|self-host" "$README" 2>/dev/null \
    || { echo "    FAIL T-021: the T3 self-host gap is not recorded in the scaffold (FR-B9-3-040)" >&2; ok=0; }
  _git_clean_vs_head ".forge/standards/identity.yaml"
  case $? in
    0) ;;
    2) echo "    SKIP T-021: not a git checkout" >&2 ;;
    *) echo "    FAIL T-021: identity.yaml was modified — ADR-B9-3-004 declines to edit it (FR-B9-3-040)" >&2; ok=0 ;;
  esac
  [ "$ok" = "1" ]
}

_test_b93_l1_022_flutter_untouched() {
  _git_clean_vs_head \
    ".forge/templates/archetypes/mobile-pwa-first/2.0.0/lib" \
    ".forge/templates/archetypes/mobile-pwa-first/2.0.0/ios" \
    ".forge/templates/archetypes/mobile-pwa-first/2.0.0/android" \
    ".forge/templates/archetypes/mobile-pwa-first/2.0.0/test"
  case $? in
    0) return 0 ;;
    2) echo "    SKIP T-022: not a git checkout" >&2; return 0 ;;
    *) echo "    FAIL T-022: the Flutter surface changed — it is byte-frozen by b9-2 T-007 (NFR-B9-3-001)" >&2; return 1 ;;
  esac
}

_test_b93_l1_023_promoted() {
  local ok=1
  # INVERTED by b9-11-promotion-gate (2026-09-12). This row is the promotion tripwire;
  # post-promotion it guards the other direction — a silent demotion (ADR-B911-001).
  grep -qE "^stage: stable" "$SCHEMA" || { echo "    FAIL T-023: schema is not stable — promoted by B.9.11 (NFR-B9-3-006)" >&2; ok=0; }
  grep -qE "^scaffoldable: true" "$SCHEMA" || { echo "    FAIL T-023: schema is not scaffoldable:true (NFR-B9-3-006)" >&2; ok=0; }
  # Anchored INSIDE the mobile-pwa-first block. `grep "^    status: candidate"` matched
  # ANY entry, so flipping mobile-pwa-first to stable while an unrelated entry happened
  # to be candidate left this row GREEN — and this row is the promotion tripwire, on a
  # table where candidate->stable flips cascade across siblings.
  #
  # Requires PyYAML (b9-2 guards the same way). If it is missing this row FAILS rather
  # than skipping: a promotion tripwire that quietly stops running is the thing it
  # exists to prevent.
  _have_py_yaml || { echo "    FAIL T-023: python3+PyYAML required to read the dispatch table (NFR-B9-3-006)" >&2; ok=0; }
  _have_py_yaml && python3 - "$DISPATCH" <<'PYDISP' || ok=0
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
table = d.get("archetypes", d) if isinstance(d, dict) else {}
entry = table.get("mobile-pwa-first")
if entry is None:
    print("    FAIL T-023: no mobile-pwa-first entry in the dispatch table (NFR-B9-3-006)", file=sys.stderr)
    sys.exit(1)
got = entry.get("status")
if got != "stable":
    print(f"    FAIL T-023: mobile-pwa-first dispatch status is {got!r}, expected 'stable' (NFR-B9-3-006)", file=sys.stderr)
    sys.exit(1)
PYDISP
  [ "$ok" = "1" ]
}

# ─── L2 (opt-in) ─────────────────────────────────────────────────────────────

_render_tree() {
  # Drive the REAL wrapper under the harness-only gate override (the b7-2 /
  # FORGE_MPF_FORCE_SCAFFOLD pattern) so a wrapper bug is caught, not masked.
  local out="$1"
  SOURCE_DATE_EPOCH=0 FORGE_MPF_FORCE_SCAFFOLD=1 \
    bash "$FORGE_ROOT/bin/forge-init-mobile-pwa-first.sh" \
    --target "$out" --project-name authprobe --reverse-domain com.example.probe --force \
    >/dev/null 2>&1
}

# One rendered, installed workspace shared by every L2 row. Four rows each doing
# their own render + `npm install` cost four installs to produce four identical
# trees; the rows only READ the tree, so one is enough. Cleaned at EXIT.
_L2_WS=""
_L2_TEST_DEPS=0

# MUST be called directly, never as `$(_l2_prepare)`. Command substitution runs the
# function in a SUBSHELL: `_L2_WS` would not survive it (so every row would build its
# own tree) and the EXIT trap would fire when that subshell ended, deleting the
# workspace before the caller could use it. Both happened. It sets `_L2_WS` instead
# of echoing a path for exactly that reason.
_l2_prepare() {
  [ -n "$_L2_WS" ] && return 0
  local w; w="$(mktemp -d -t forge-b9-3-ws-XXXXXX)"
  _render_tree "$w/out" || { echo "    (render failed)" >&2; rm -rf "$w"; return 1; }
  ( cd "$w/out/web-pwa" && npm install --no-audit --no-fund >/dev/null 2>&1 ) \
    || { echo "    (npm install failed)" >&2; rm -rf "$w"; return 1; }
  _L2_WS="$w"
  # shellcheck disable=SC2064
  trap "rm -rf '$w'" EXIT
}

# `jose` and `tsx` are TEST-ONLY: installed with --no-save to run the fixtures, and
# NOT template dependencies. Kept OUT of the base workspace so T-L2-001 type-checks
# against the template's own dependency set and nothing else. The template's
# declared dependencies are asserted by T-002/T-003.
_l2_add_test_deps() {
  [ "$_L2_TEST_DEPS" = "1" ] && return 0
  ( cd "$_L2_WS/out/web-pwa" \
    && npm install --no-save --no-audit --no-fund jose tsx >/dev/null 2>&1 ) || return 1
  _L2_TEST_DEPS=1
}

# Is the L2 leg runnable at all? Checked ONCE in main() rather than per row.
#
# Previously each row skipped itself by returning 0, which `run_test` printed as ✓ and
# counted as a pass — so `--level 12` without FORGE_B9_3_NPM emitted a stdout summary
# IDENTICAL to a real run (the SKIP notices went to stderr). For a suite whose L2 rows
# carry the only assertions that cannot be satisfied by decoration, "the proof ran" and
# "the proof was skipped" must not look the same.
_l2_gate_open() {
  [ "${FORGE_B9_3_NPM:-0}" = "1" ] || return 1
  command -v npm >/dev/null 2>&1 || return 1
  return 0
}

# Run a fixture inside the rendered workspace and require its success marker.
#
# The fixture MUST be copied INTO the workspace before running: Node resolves bare
# specifiers (`jose`) from the importing file's location upward, so executing it in
# place from the Forge repo fails with ERR_MODULE_NOT_FOUND.
_run_fixture() {
  local row="$1" file="$2" marker="$3" desc="$4"
  local fixture="$HARNESS_DIR/fixtures/b9-3/$file"
  [ -f "$fixture" ] || { echo "    FAIL $row: fixture missing: $fixture" >&2; return 1; }

  _l2_prepare || { echo "    FAIL $row: could not prepare the workspace" >&2; return 1; }
  _l2_add_test_deps || { echo "    FAIL $row: could not install the test-only deps" >&2; return 1; }

  local ws="$_L2_WS/out/web-pwa"
  cp "$fixture" "$ws/_b9-3-fixture.mjs"
  local out rc
  out=$( cd "$ws" && npx tsx ./_b9-3-fixture.mjs "$ws" 2>&1 )
  rc=$?
  rm -f "$ws/_b9-3-fixture.mjs"

  if [ "$rc" != "0" ]; then
    echo "    FAIL $row: $desc" >&2
    printf '%s\n' "$out" | sed 's|^|      |' >&2
    return 1
  fi
  grep -q "$marker" <<<"$out" || {
    echo "    FAIL $row: fixture exited 0 but did not report '$marker' — treat as inconclusive, not green" >&2
    printf '%s\n' "$out" | sed 's|^|      |' >&2
    return 1; }
}

_test_b93_l2_001_typecheck() {
  _l2_prepare || { echo "    FAIL T-L2-001: render / npm install failed" >&2; return 1; }
  ( cd "$_L2_WS/out/web-pwa" && npx tsc --noEmit >/dev/null 2>&1 ) \
    || { echo "    FAIL T-L2-001: tsc --noEmit failed in the rendered web-pwa/ (NFR-B9-3-002)" >&2
         ( cd "$_L2_WS/out/web-pwa" && npx tsc --noEmit 2>&1 | head -20 | sed 's|^|      |' >&2 )
         return 1; }
}

_test_b93_l2_002_rejection_table() {
  # THE proof of FR-B9-3-009. See fixtures/b9-3/oidc-rejection-table.mjs for why a
  # static assertion cannot stand in for this.
  _run_fixture "T-L2-002" "oidc-rejection-table.mjs" "7/7" \
    "the ID-token rejection table did not pass (FR-B9-3-009):"
}

_test_b93_l2_003_state_mismatch() {
  # = design T-008. The ORDER is the requirement: a mismatched state must be
  # rejected BEFORE the authorization code is redeemed, not after.
  _run_fixture "T-L2-003" "state-mismatch.mjs" "3/3" \
    "a mismatched state did not stop the token request (FR-B9-3-004):"
}

_test_b93_l2_004_no_token_in_storage() {
  # The behavioural backing for T-018, which can only read identifiers. This drives a
  # real login and searches the stores for the actual token strings.
  _run_fixture "T-L2-004" "no-token-in-storage.mjs" "5/5" \
    "token material reached browser storage (FR-B9-3-030):"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.9.3 — b9-3-shared-oidc — level $LEVEL ──"
  run_test _test_b93_l1_001_auth_module_exists
  run_test _test_b93_l1_002_oauth4webapi_pinned
  run_test _test_b93_l1_003_neg_no_connectrpc
  run_test _test_b93_l1_004_neg_no_connect_client_import
  run_test _test_b93_l1_005_s256
  run_test _test_b93_l1_006_csprng
  run_test _test_b93_l1_007_state_and_nonce
  run_test _test_b93_l1_009_callback_route
  run_test _test_b93_l1_009a_proxy_validating_call
  run_test _test_b93_l1_009a_state_string
  run_test _test_b93_l1_009b_neg_no_hand_decode
  run_test _test_b93_l1_009c_expected_nonce_string
  run_test _test_b93_l1_009d_require_id_token
  run_test _test_b93_l1_010_url_scrubbed
  run_test _test_b93_l1_011_discovery
  run_test _test_b93_l1_012_refresh_logout
  run_test _test_b93_l1_013_skew_parity
  run_test _test_b93_l1_014_shared_issuer_once
  run_test _test_b93_l1_015_per_surface_client
  run_test _test_b93_l1_016_port_parity
  run_test _test_b93_l1_017_not_sso
  run_test _test_b93_l1_018_neg_no_token_in_web_storage
  run_test _test_b93_l1_019_readme_cost
  run_test _test_b93_l1_020_no_token_leak
  run_test _test_b93_l1_021_t3_gap_and_identity_untouched
  run_test _test_b93_l1_022_flutter_untouched
  run_test _test_b93_l1_023_promoted
  case "$LEVEL" in
    *2*)
      if _l2_gate_open; then
        run_test _test_b93_l2_001_typecheck
        run_test _test_b93_l2_002_rejection_table
        run_test _test_b93_l2_003_state_mismatch
        run_test _test_b93_l2_004_no_token_in_storage
      else
        echo "  ⊘ L2 NOT RUN (4 rows) — set FORGE_B9_3_NPM=1 and ensure npm is present."
        echo "    T-L2-002 is THE proof of FR-B9-3-009; this run does not include it."
      fi
      ;;
  esac
  print_summary
}

main
