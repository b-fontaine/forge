#!/usr/bin/env bash
# Forge — B.8.15 forge-upgrade matrix test (T5.1 Layer D)
# <!-- Audit: B.8.15 (b8-15-upgrade-matrix) -->
#
# The v0.4.0-stable publish gate. Realises the N-1 → N "matrix" as harness cells.
# DIRECT new cells (e2e against the binaries): cross-major exit-7 [NEEDS MIGRATION:],
# --force-on-dirty refusal, flagship 1.0.0→2.0.0 (migrate-flagship on a c1 copy),
# flip-gated skip-pass guard. The same-major / ledger-generic / .merge-conflicts
# machinery is gated via the a7 coupling (a7 is its authoritative harness).
#
# L1 hermetic (git/python3/tar, no cargo/flutter/docker), ≤ a few seconds.
# L2 (FORGE_B8_15_LIVE): the full migrate-flagship real overlay on a c1 copy.

set -uo pipefail

# Hermetic git identity — the cells git-init+commit tmpdir projects; CI runners
# may lack a global identity (b8-12 lesson).
export GIT_AUTHOR_NAME="Forge Harness" GIT_AUTHOR_EMAIL="harness@forge.invalid"
export GIT_COMMITTER_NAME="Forge Harness" GIT_COMMITTER_EMAIL="harness@forge.invalid"

LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in --level=*) LEVEL="${arg#*=}" ;; esac
  prev="$arg"
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

UPGRADE_SH="$FORGE_ROOT_REAL/bin/forge-upgrade.sh"
MIGRATE_SH="$FORGE_ROOT_REAL/bin/forge-migrate-flagship.sh"
C1_EXAMPLE="$FORGE_ROOT_REAL/examples/forge-fsm-example"
SCHEMA_20="$FORGE_ROOT_REAL/.forge/schemas/full-stack-monorepo/2.0.0.yaml"
FIXTURE="$FORGE_ROOT_REAL/cli/test/e2e/archetype-fixtures/full-stack-monorepo.yml"
SNAP="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
SNAP_SHA="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256"
CHANGELOG="$FORGE_ROOT_REAL/CHANGELOG.md"
FORGE_CI="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# Synthesize a minimal Forge project at a given archetype_version, git-committed.
_b815_synth_project() {
  # _b815_synth_project <dir> <version>
  local dir="$1" ver="$2"
  mkdir -p "$dir/.forge"
  printf 'archetype: full-stack-monorepo\narchetype_version: "%s"\ntemplate_set_sha: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"\nproject_name: probe\nreverse_domain: test.probe\nroot_module: probe\n' "$ver" > "$dir/.forge/scaffold-manifest.yaml"
  git -C "$dir" init -q
  git -C "$dir" add -A
  git -C "$dir" commit -q -m init
}

# ─── Manifest ────────────────────────────────────────────────────
# L1 (9) — direct e2e cells + a7/b8-10/b8-14 coupling + CI/frozen.
# MANIFEST: _test_b815_001_negative_major_abort     — FR-B815-010
# MANIFEST: _test_b815_002_force_dirty_refused       — FR-B815-011
# MANIFEST: _test_b815_003_additive_static_guard     — FR-B815-041
# MANIFEST: _test_b815_004_flagship_dryrun_c1         — FR-B815-040
# MANIFEST: _test_b815_005_flip_gated_guard           — FR-B815-050
# MANIFEST: _test_b815_006_coupling                   — FR-B815-020/021/030/031/062
# MANIFEST: _test_b815_007_changelog_anchor           — FR-B815-061
# MANIFEST: _test_b815_008_forgeci_registration       — FR-B815-060
# MANIFEST: _test_b815_009_frozen_snapshot            — FR-B815-063
# L2 (1) — gated on FORGE_B8_15_LIVE
# MANIFEST: _test_b815_l2_flagship_overlay            — FR-B815-040/041/042

# FR-B815-010 — cross-major upgrade aborts exit 7 + [NEEDS MIGRATION:] (e2e binary)
_test_b815_001_negative_major_abort() {
  local tmp; tmp="$(mktemp -d -t b815-neg-XXXXXX)"
  trap "rm -rf '$tmp'" RETURN
  _b815_synth_project "$tmp" "1.5.2" >/dev/null 2>&1
  local out rc
  out="$(bash "$UPGRADE_SH" --target "$tmp" --to-version 2.0.0 2>&1)"; rc=$?
  if [ "$rc" -ne 7 ]; then
    echo "    expected exit 7 on 1.5.2→2.0.0, got $rc" >&2; return 1
  fi
  if ! printf '%s' "$out" | grep -qF "[NEEDS MIGRATION: from 1.5.2 to 2.0.0]"; then
    echo "    missing literal [NEEDS MIGRATION: from 1.5.2 to 2.0.0] marker" >&2; return 1
  fi
}

# FR-B815-011 — --force on a dirty tree refused (same-major target; force-clean gate)
_test_b815_002_force_dirty_refused() {
  local tmp; tmp="$(mktemp -d -t b815-dirty-XXXXXX)"
  trap "rm -rf '$tmp'" RETURN
  _b815_synth_project "$tmp" "1.0.0" >/dev/null 2>&1
  echo "dirt" > "$tmp/dirty.txt"   # dirty the working tree (uncommitted)
  local out rc
  out="$(bash "$UPGRADE_SH" --target "$tmp" --to-version 1.0.1 --force 2>&1)"; rc=$?
  if [ "$rc" -ne 7 ]; then
    echo "    expected exit 7 (--force on dirty same-major), got $rc" >&2; return 1
  fi
  if ! printf '%s' "$out" | grep -qiF "requires a clean Git working tree"; then
    echo "    missing dirty-git refusal message" >&2; return 1
  fi
}

# FR-B815-041 (L1) — migrate-flagship is additive: no rm/rmdir on Kong/REST/Temporal
_test_b815_003_additive_static_guard() {
  [ -f "$MIGRATE_SH" ] || { echo "    forge-migrate-flagship.sh missing" >&2; return 1; }
  local hit
  hit="$(grep -niE '(rm|rmdir|git rm)[^#]*(kong|temporal|rest)' "$MIGRATE_SH" | grep -viE '^[0-9]+: *#' || true)"
  if [ -n "$hit" ]; then
    echo "    migrate-flagship appears to REMOVE Kong/REST/Temporal (must be additive):" >&2
    printf '%s\n' "$hit" | sed 's/^/      /' >&2
    return 1
  fi
  grep -qiE "ADDITIVE.ONLY|additive only|never removes" "$MIGRATE_SH" || { echo "    additive-only declaration missing" >&2; return 1; }
}

# FR-B815-040 (L1) — flagship dry-run on a c1 copy: 1.0.0→2.0.0 plan, no mutation
_test_b815_004_flagship_dryrun_c1() {
  [ -d "$C1_EXAMPLE" ] || { echo "    c1 example missing: $C1_EXAMPLE" >&2; return 1; }
  local tmp; tmp="$(mktemp -d -t b815-c1dry-XXXXXX)"
  trap "rm -rf '$tmp'" RETURN
  cp -r "$C1_EXAMPLE/." "$tmp/c1"
  git -C "$tmp/c1" init -q; git -C "$tmp/c1" add -A; git -C "$tmp/c1" commit -q -m init
  local out rc
  out="$(bash "$MIGRATE_SH" --target "$tmp/c1" --dry-run 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    flagship --dry-run on a c1 copy exited $rc (expected 0)" >&2
    printf '%s\n' "$out" | tail -5 | sed 's/^/      /' >&2
    return 1
  fi
  printf '%s' "$out" | grep -qiE "2\.0\.0|Envoy" || { echo "    dry-run plan does not mention the 2.0.0/Envoy target" >&2; return 1; }
  local dirty; dirty="$(git -C "$tmp/c1" status --porcelain)"
  if [ -n "$dirty" ]; then
    echo "    dry-run mutated the c1 copy (must be no-op)" >&2; return 1
  fi
}

# FR-B815-050 — flip-gated cells documented + skip-passed (front-door 2.0.0 + Kong removal)
_test_b815_005_flip_gated_guard() {
  # The front-door positive 2.0.0 upgrade + Kong-removal assertions are gated on the
  # B.8.14 flip. While 2.0.0 is still candidate/scaffoldable:false, those cells are
  # pending — assert the gate is still closed (consistent with the held state).
  [ -f "$SCHEMA_20" ] || { echo "    2.0.0.yaml missing" >&2; return 1; }
  if ! grep -qE '^scaffoldable: *false' "$SCHEMA_20"; then
    echo "    2.0.0 is no longer scaffoldable:false — the flip happened; ACTIVATE the front-door + Kong-removal cells (remove this skip-guard)" >&2
    return 1
  fi
  echo "    [skip] front-door auto-resolve-to-2.0.0 + Kong-removal cells pending b8-14-promotion-flip" >&2
}

# FR-B815-020/021/030/031/062 — engine machinery via the authoritative siblings
_test_b815_006_coupling() {
  # a7.test.sh predates the --level flag (forge-ci registers it bare); b8-10/b8-14
  # take --level 1. Invoke each the way forge-ci.yml does.
  local sib out
  for sib in a7 b8-10 b8-14; do
    if [ ! -f "$HARNESS_DIR/${sib}.test.sh" ]; then
      echo "    ${sib}.test.sh missing" >&2; return 1
    fi
    if [ "$sib" = "a7" ]; then
      out="$(bash "$HARNESS_DIR/${sib}.test.sh" 2>&1)" || {
        echo "    ${sib}.test.sh exited non-zero (coupling break):" >&2
        printf '%s\n' "$out" | grep -E "✗|Failed:|Failures:|    -" | sed 's/^/      /' >&2
        return 1
      }
    else
      out="$(bash "$HARNESS_DIR/${sib}.test.sh" --level 1 2>&1)" || {
        echo "    ${sib}.test.sh --level 1 exited non-zero (coupling break):" >&2
        printf '%s\n' "$out" | grep -E "✗|Failed:|Failures:|    -" | sed 's/^/      /' >&2
        return 1
      }
    fi
  done
}

# FR-B815-061 — CHANGELOG anchor
_test_b815_007_changelog_anchor() {
  [ -f "$CHANGELOG" ] || { echo "    CHANGELOG.md missing" >&2; return 1; }
  grep -qF "b8-15" "$CHANGELOG" || { echo "    b8-15 anchor missing in CHANGELOG" >&2; return 1; }
}

# FR-B815-060 — forge-ci registration
_test_b815_008_forgeci_registration() {
  [ -f "$FORGE_CI" ] || { echo "    forge-ci.yml missing" >&2; return 1; }
  grep -qF "b8-15.test.sh" "$FORGE_CI" || { echo "    b8-15.test.sh not registered in forge-ci.yml" >&2; return 1; }
}

# FR-B815-063 — frozen 1.0.0 snapshot byte-identity
_test_b815_009_frozen_snapshot() {
  [ -f "$SNAP" ] && [ -f "$SNAP_SHA" ] || { echo "    1.0.0 snapshot or .sha256 missing" >&2; return 1; }
  local actual expected
  actual="$(shasum -a 256 "$SNAP" | awk '{print $1}')"
  expected="$(grep -oE '[a-f0-9]{64}' "$SNAP_SHA" | head -1 || true)"
  [ "$actual" = "$expected" ] || { echo "    1.0.0 snapshot drifted" >&2; return 1; }
}

# ── L2 (opt-in) — real flagship overlay on a c1 copy ──
# FR-B815-040/041/042
_test_b815_l2_flagship_overlay() {
  if [ -z "${FORGE_B8_15_LIVE:-}" ]; then
    echo "    [skip] set FORGE_B8_15_LIVE=1 to run the real flagship overlay" >&2; return 0
  fi
  [ -d "$C1_EXAMPLE" ] || { echo "    [skip] c1 example absent" >&2; return 0; }
  local tmp; tmp="$(mktemp -d -t b815-c1live-XXXXXX)"
  trap "rm -rf '$tmp'" RETURN
  cp -r "$C1_EXAMPLE/." "$tmp/c1"
  git -C "$tmp/c1" init -q; git -C "$tmp/c1" add -A; git -C "$tmp/c1" commit -q -m init
  local rc
  bash "$MIGRATE_SH" --target "$tmp/c1" >/dev/null 2>&1; rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    real flagship overlay exited $rc (expected 0)" >&2; return 1
  fi
  # ledger: flagship entry from 1.0.0 to 2.0.0 with kind: flagship-migration
  local man="$tmp/c1/.forge/scaffold-manifest.yaml"
  python3 - "$man" <<'PY' || { echo "    upgrade_history flagship entry missing/incomplete" >&2; return 1; }
import sys, yaml
m = yaml.safe_load(open(sys.argv[1]))
h = m.get('upgrade_history') or []
ok = any(str(e.get('from_version'))=='1.0.0' and str(e.get('to_version'))=='2.0.0'
         and e.get('kind')=='flagship-migration' for e in h)
sys.exit(0 if ok else 1)
PY
  # additive: Kong still present in the overlaid tree
  grep -qE '^  fsm-kong:' "$tmp/c1/docker-compose.dev.yml" || { echo "    Kong (fsm-kong) removed by the overlay (must be additive)" >&2; return 1; }
  [ -f "$tmp/c1/infra/kong/kong.yml.example" ] || [ -d "$tmp/c1/infra/kong" ] || { echo "    infra/kong removed by the overlay" >&2; return 1; }
  # T5.1.B fixture matrix on the overlaid tree
  if [ -f "$FIXTURE" ]; then
    python3 - "$FIXTURE" "$tmp/c1" <<'PY' || { echo "    T5.1.B fixture matrix failed on the overlaid tree" >&2; return 1; }
import sys, os, yaml
fx = yaml.safe_load(open(sys.argv[1])); root = sys.argv[2]
req = fx.get('required_paths') or fx.get('required') or []
forb = fx.get('forbidden_paths') or fx.get('forbidden') or []
miss = [p for p in req if not os.path.exists(os.path.join(root, p))]
bad  = [p for p in forb if os.path.exists(os.path.join(root, p))]
if miss or bad:
    print("missing:", miss, "forbidden-present:", bad); sys.exit(1)
sys.exit(0)
PY
  fi
}

# ─── Main ────────────────────────────────────────────────────────
main() {
  echo "── B.8.15 — b8-15-upgrade-matrix — level $LEVEL ──"
  echo ""
  echo "L1 — upgrade engine e2e (binary) + flagship + flip-gate"
  run_test _test_b815_001_negative_major_abort
  run_test _test_b815_002_force_dirty_refused
  run_test _test_b815_003_additive_static_guard
  run_test _test_b815_004_flagship_dryrun_c1
  run_test _test_b815_005_flip_gated_guard

  echo ""
  echo "L1 — coupling + CI + frozen"
  run_test _test_b815_006_coupling
  run_test _test_b815_007_changelog_anchor
  run_test _test_b815_008_forgeci_registration
  run_test _test_b815_009_frozen_snapshot

  case ",$LEVEL," in
    *,2,*)
      echo ""
      echo "L2 — real flagship overlay (FORGE_B8_15_LIVE)"
      run_test _test_b815_l2_flagship_overlay
      ;;
  esac

  print_summary
}

main "$@"
