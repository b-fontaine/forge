#!/usr/bin/env bash
# Forge — B.8.10 flagship 1.0.0→2.0.0 migration-orchestrator harness
# <!-- Audit: B.8.10 (b8-10-migrate-flagship) — migration script gate -->
#
# Validates the b8-10-migrate-flagship deliverables (design.md § Testing Strategy
# T-001..T-012 + ADR-B810-001..005 — bin/forge-migrate-flagship.sh orchestrator
# that SOURCEs bin/forge-upgrade.sh and reuses the _a7_* library, additive-only,
# no-DBOS, rollback from the byte-frozen 1.0.0 snapshot, docs/MIGRATIONS.md fill):
#
#   T-001  script exists + executable + Audit:B.8.10 sentinel + set -uo pipefail   (FR-B810-001/071)
#   T-002  --help exits 0 + mentions --target + 0/2/5/7/8 exit-code table          (FR-B810-002/008)
#   T-003  zero new dep — only git/python3/tar/shasum/sha256sum invoked            (FR-B810-006/NFR-B810-001)
#   T-004  --dry-run on a 1.0.0 fixture mutates nothing                            (FR-B810-014/072/NFR-B810-010)
#   T-005  exit envelope: no-target→2, --help→0, non-1.0.0→7, --phase 3→0          (FR-B810-005/073)
#   T-006  no-DBOS static grep — no active (non-comment) dbos reference            (FR-B810-032/074/NFR-B810-008)
#   T-007  additive-only static grep — no rm/rmdir on kong/temporal/rest tokens    (FR-B810-031/075/NFR-B810-007)
#   T-008  rollback references the frozen 1.0.0.tar.gz + never WRITES snapshots/   (FR-B810-040/041/076)
#   T-009  docs/MIGRATIONS.md battery + CHANGELOG b8-10-migrate-flagship anchor     (FR-B810-050/051/077)
#   T-010  frozen snapshot sha256 file present + expected digest + .tar.gz present (FR-B810-012/077/NFR-B810-004)
#   T-011  coupling guard: b8-2 (frozen) + b8-3 (schema) stay GREEN (exit-code)    (FR-B810-078/NFR-B810-003)
#   T-012  SOURCE_DATE_EPOCH determinism (L1 static) + L2 opt-in FORGE_B8_10_LIVE  (FR-B810-007/078/NFR-B810-005)
#
# 12 L1 tests. Budget L1 ≤ 2 s, zero net/Docker/live-`forge init`. The live
# verify-then-pin (forge-upgrade.sh _a7_* inventory + 2.0.0 template-set) is a
# /forge:implement Phase 0 step recorded in evidence.md (P-28..P-36), NOT an L1
# assertion. T-011 is exit-code only (the b8-9 coupling strategy) — keeps the
# coupling guard within budget. L2 (FORGE_B8_10_LIVE=1) mirrors the b8-1
# FORGE_B8_1_DOCKER opt-in env-gate. Mirrors b8-9.test.sh structure
# (--level flag + _helpers.sh).

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

SCRIPT="$FORGE_ROOT/bin/forge-migrate-flagship.sh"
MIGRATIONS="$FORGE_ROOT/docs/MIGRATIONS.md"
CHANGELOG="$FORGE_ROOT/CHANGELOG.md"
SNAP_DIR="$FORGE_ROOT/.forge/scaffold-snapshots/full-stack-monorepo"
SNAP_TGZ="$SNAP_DIR/1.0.0.tar.gz"
SNAP_SHA="$SNAP_DIR/1.0.0.sha256"
EXPECTED_DIGEST="8d439b942bf81dbcc103e010d946504035dd410f613b31f673d7d691c3224ca9"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Fixture helper ────────────────────────────────────────────────────────────
# Builds an ephemeral 1.0.0 full-stack-monorepo target with a valid manifest and
# an initialised, clean Git tree. Echoes the fixture path. Caller traps cleanup.
_b810_make_fixture() {
  local ver="${1:-1.0.0}"
  local fix
  fix=$(mktemp -d -t b8-10-fix-XXXXXX)
  mkdir -p "$fix/.forge"
  cat > "$fix/.forge/scaffold-manifest.yaml" <<EOF
archetype: full-stack-monorepo
archetype_version: $ver
project_name: b810-fixture
reverse_domain: io.forge.b810
root_module: b810_fixture
scaffold_date: '2026-06-03T00:00:00+00:00'
template_set_sha: deadbeef
upgrade_history: []
EOF
  git init -q "$fix" >/dev/null 2>&1
  git -C "$fix" add -A >/dev/null 2>&1
  git -C "$fix" -c user.email=b810@forge.test -c user.name=b810 \
    commit -q -m "fixture" >/dev/null 2>&1
  echo "$fix"
}

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b810_l1_001_script_exists_exec_header() {
  local ok=1
  [ -f "$SCRIPT" ] \
    || { echo "    FAIL T-001: missing script $SCRIPT (FR-B810-001/071)" >&2; ok=0; }
  if [ -f "$SCRIPT" ]; then
    [ -x "$SCRIPT" ] \
      || { echo "    FAIL T-001: script not executable: $SCRIPT (FR-B810-001/071)" >&2; ok=0; }
    grep -qF 'Audit: B.8.10 (b8-10-migrate-flagship)' "$SCRIPT" \
      || { echo "    FAIL T-001: missing 'Audit: B.8.10 (b8-10-migrate-flagship)' sentinel (FR-B810-002/071)" >&2; ok=0; }
    grep -qF 'set -uo pipefail' "$SCRIPT" \
      || { echo "    FAIL T-001: missing 'set -uo pipefail' (FR-B810-003/071)" >&2; ok=0; }
  fi
  [ "$ok" = "1" ]
}

_test_b810_l1_002_help_exit0_target_table() {
  if [ ! -f "$SCRIPT" ]; then
    echo "    FAIL T-002: script absent: $SCRIPT (FR-B810-002)" >&2; return 1
  fi
  local out rc ok=1
  out=$(bash "$SCRIPT" --help 2>&1); rc=$?
  [ "$rc" -eq 0 ] \
    || { echo "    FAIL T-002: --help exit $rc != 0 (FR-B810-008)" >&2; ok=0; }
  grep -qF -- '--target' <<<"$out" \
    || { echo "    FAIL T-002: --help output omits --target (FR-B810-008)" >&2; ok=0; }
  grep -qE '0/2/5/7/8' <<<"$out" \
    || { echo "    FAIL T-002: --help output omits the 0/2/5/7/8 exit-code table (FR-B810-002/008, ADR-B810-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b810_l1_003_zero_new_dep() {
  if [ ! -f "$SCRIPT" ]; then
    echo "    FAIL T-003: script absent: $SCRIPT (FR-B810-006)" >&2; return 1
  fi
  # Only git/python3/tar/shasum/sha256sum may be invoked. A non-comment line
  # referencing npm/cargo/pub/docker as a command is a FAIL (NFR-B810-001).
  local hits
  hits=$(grep -nE '\b(npm|cargo|pub|docker)\b' "$SCRIPT" 2>/dev/null \
    | grep -vE '^[[:space:]]*[0-9]+:[[:space:]]*#' \
    | grep -vE ':[[:space:]]*#' \
    || true)
  if [ -n "$hits" ]; then
    echo "    FAIL T-003: disallowed binary reference(s) in $SCRIPT (FR-B810-006/NFR-B810-001):" >&2
    printf '%s\n' "$hits" | sed 's/^/      /' >&2
    return 1
  fi
}

_test_b810_l1_004_dry_run_no_mutation() {
  if [ ! -f "$SCRIPT" ]; then
    echo "    FAIL T-004: script absent: $SCRIPT (FR-B810-014)" >&2; return 1
  fi
  local fix rc dirty
  fix=$(_b810_make_fixture 1.0.0)
  # shellcheck disable=SC2064
  trap "rm -rf '$fix'" RETURN
  bash "$SCRIPT" --target "$fix" --dry-run >/dev/null 2>&1; rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    FAIL T-004: --dry-run on a 1.0.0 fixture exited $rc != 0 (FR-B810-014)" >&2; return 1
  fi
  dirty=$(git -C "$fix" status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    echo "    FAIL T-004: --dry-run mutated the fixture (FR-B810-014/072/NFR-B810-010):" >&2
    printf '%s\n' "$dirty" | sed 's/^/      /' >&2
    return 1
  fi
}

_test_b810_l1_005_exit_envelope() {
  if [ ! -f "$SCRIPT" ]; then
    echo "    FAIL T-005: script absent: $SCRIPT (FR-B810-005)" >&2; return 1
  fi
  local ok=1 rc fix9 fix1

  # (a) no --target → exit 2
  bash "$SCRIPT" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 2 ] \
    || { echo "    FAIL T-005(a): no --target exit $rc != 2 (FR-B810-004/005)" >&2; ok=0; }

  # (b) --help → exit 0
  bash "$SCRIPT" --help >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] \
    || { echo "    FAIL T-005(b): --help exit $rc != 0 (FR-B810-008)" >&2; ok=0; }

  # (c) non-1.0.0 target → exit 7
  fix9=$(_b810_make_fixture 0.9.0)
  bash "$SCRIPT" --target "$fix9" >/dev/null 2>&1; rc=$?
  rm -rf "$fix9"
  [ "$rc" -eq 7 ] \
    || { echo "    FAIL T-005(c): non-1.0.0 target exit $rc != 7 (FR-B810-010/013)" >&2; ok=0; }

  # (d) --phase 3 on a valid 1.0.0 target → exit 0 (forward-reference stub)
  fix1=$(_b810_make_fixture 1.0.0)
  bash "$SCRIPT" --target "$fix1" --phase 3 >/dev/null 2>&1; rc=$?
  rm -rf "$fix1"
  [ "$rc" -eq 0 ] \
    || { echo "    FAIL T-005(d): --phase 3 exit $rc != 0 (FR-B810-036)" >&2; ok=0; }

  [ "$ok" = "1" ]
}

_test_b810_l1_006_no_dbos_guard() {
  if [ ! -f "$SCRIPT" ]; then
    echo "    FAIL T-006: script absent: $SCRIPT (FR-B810-032)" >&2; return 1
  fi
  # Constitutional no-DBOS guard (VIII.2, FR-B810-032, B8O). A comment EXPLAINING
  # the no-DBOS exclusion is allowed (mirrors the b8-9 protoc-gen-connect-es
  # README-note handling); strip comment lines before grepping for an ACTIVE ref.
  local hits
  hits=$(grep -vE '^[[:space:]]*#' "$SCRIPT" 2>/dev/null \
    | grep -iE 'dbos' \
    || true)
  if [ -n "$hits" ]; then
    echo "    FAIL T-006: active dbos reference(s) in $SCRIPT (FR-B810-032/074/NFR-B810-008, VIII.2/B8O):" >&2
    printf '%s\n' "$hits" | sed 's/^/      /' >&2
    return 1
  fi
}

_test_b810_l1_007_additive_only_guard() {
  if [ ! -f "$SCRIPT" ]; then
    echo "    FAIL T-007: script absent: $SCRIPT (FR-B810-031)" >&2; return 1
  fi
  # Constitutional additive invariant (VIII.1/VIII.2, FR-B810-031): the script
  # MUST NOT rm/rmdir a kong/temporal/rest path. Grep destructive-op lines and
  # check none also reference a protected token.
  local hits
  hits=$(grep -nE '\b(rm|rmdir)\b' "$SCRIPT" 2>/dev/null \
    | grep -iE 'kong|temporal|rest' \
    || true)
  if [ -n "$hits" ]; then
    echo "    FAIL T-007: destructive op on a protected (kong/temporal/rest) path (FR-B810-031/075/NFR-B810-007):" >&2
    printf '%s\n' "$hits" | sed 's/^/      /' >&2
    return 1
  fi
}

_test_b810_l1_008_rollback_path_and_no_snapshot_write() {
  if [ ! -f "$SCRIPT" ]; then
    echo "    FAIL T-008: script absent: $SCRIPT (FR-B810-040)" >&2; return 1
  fi
  local ok=1
  # Rollback sources the frozen snapshot.
  grep -qF 'scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz' "$SCRIPT" \
    || { echo "    FAIL T-008: script never references the frozen 1.0.0.tar.gz rollback source (FR-B810-040/076)" >&2; ok=0; }
  # Script NEVER writes to scaffold-snapshots/ (no redirect, no tar -c into it).
  local wr
  wr=$(grep -nE '>[[:space:]]*[^ ]*scaffold-snapshots|tar[[:space:]]+-c[^|]*scaffold-snapshots' "$SCRIPT" 2>/dev/null || true)
  if [ -n "$wr" ]; then
    echo "    FAIL T-008: script WRITES to scaffold-snapshots/ — frozen assets must stay byte-untouched (FR-B810-041/076):" >&2
    printf '%s\n' "$wr" | sed 's/^/      /' >&2
    ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b810_l1_009_migrations_and_changelog() {
  local ok=1
  if [ ! -f "$MIGRATIONS" ]; then
    echo "    FAIL T-009: docs/MIGRATIONS.md missing: $MIGRATIONS (FR-B810-050)" >&2; ok=0
  else
    # (1) 1.0.0 → 2.0.0 heading.
    grep -qE '1\.0\.0.*2\.0\.0|2\.0\.0.*1\.0\.0' "$MIGRATIONS" \
      || { echo "    FAIL T-009(1): MIGRATIONS.md has no 1.0.0↔2.0.0 heading (FR-B810-050)" >&2; ok=0; }
    # (2) forge-migrate-flagship invocation sentinel.
    grep -qF 'forge-migrate-flagship' "$MIGRATIONS" \
      || { echo "    FAIL T-009(2): MIGRATIONS.md has no forge-migrate-flagship invocation (FR-B810-051/053)" >&2; ok=0; }
    # (3) scaffoldable: false caveat.
    grep -qE 'scaffoldable.*false|false.*scaffoldable' "$MIGRATIONS" \
      || { echo "    FAIL T-009(3): MIGRATIONS.md has no 'scaffoldable: false' caveat (FR-B810-054)" >&2; ok=0; }
    # (4) B.8.13 rollback-criteria xref.
    grep -qF 'B.8.13' "$MIGRATIONS" \
      || { echo "    FAIL T-009(4): MIGRATIONS.md has no B.8.13 rollback-criteria xref (FR-B810-042)" >&2; ok=0; }
    # (5) no active dbos in rollback-criteria context (comment/prose explaining
    #     the cancellation is allowed; an active criterion line is not).
    local dbos_hits
    dbos_hits=$(grep -inE 'dbos' "$MIGRATIONS" 2>/dev/null \
      | grep -viE 'cancel|removed|retain|no dbos|not.*dbos|no-dbos|b8o|deprecat' \
      || true)
    if [ -n "$dbos_hits" ]; then
      echo "    FAIL T-009(5): MIGRATIONS.md has a dbos reference outside a cancellation note (FR-B810-042):" >&2
      printf '%s\n' "$dbos_hits" | sed 's/^/      /' >&2
      ok=0
    fi
  fi
  # CHANGELOG anchored on the change NAME (whole-file grep per the
  # changelog-test [Unreleased]-coupling lesson — survives release graduation).
  if [ ! -f "$CHANGELOG" ]; then
    echo "    FAIL T-009: CHANGELOG.md missing: $CHANGELOG (FR-B810-077)" >&2; ok=0
  else
    grep -qF 'b8-10-migrate-flagship' "$CHANGELOG" \
      || { echo "    FAIL T-009: CHANGELOG.md has no b8-10-migrate-flagship entry (FR-B810-077, NFR-B810-001)" >&2; ok=0; }
  fi
  [ "$ok" = "1" ]
}

_test_b810_l1_010_frozen_snapshot_guard() {
  local ok=1
  if [ ! -f "$SNAP_SHA" ]; then
    echo "    FAIL T-010: frozen snapshot sha256 file missing: $SNAP_SHA (FR-B810-012/NFR-B810-004)" >&2; ok=0
  else
    grep -qF "$EXPECTED_DIGEST" "$SNAP_SHA" \
      || { echo "    FAIL T-010: $SNAP_SHA does not contain expected digest $EXPECTED_DIGEST (FR-B810-012)" >&2; ok=0; }
  fi
  [ -f "$SNAP_TGZ" ] \
    || { echo "    FAIL T-010: frozen snapshot tarball missing: $SNAP_TGZ (FR-B810-040/NFR-B810-004)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b810_l1_011_sibling_coupling() {
  # Exit-code-only coupling guard (NO output parse — keeps T-011 within the
  # ≤ 2 s L1 budget, the b8-9 coupling strategy). b8-2 (frozen snapshot
  # byte-identity) + b8-3 (schema invariants) MUST stay GREEN under B.8.10.
  bash "$HARNESS_DIR/b8-2.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-011: b8-2.test.sh --level 1 is RED under B.8.10 (NFR-B810-003/004 coupling regression)" >&2; return 1; }
  bash "$HARNESS_DIR/b8-3.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-011: b8-3.test.sh --level 1 is RED under B.8.10 (NFR-B810-003 coupling regression)" >&2; return 1; }
}

_test_b810_l1_012_source_date_epoch_static() {
  if [ ! -f "$SCRIPT" ]; then
    echo "    FAIL T-012: script absent: $SCRIPT (FR-B810-007)" >&2; return 1
  fi
  # The ledger wrapper consumes SOURCE_DATE_EPOCH for deterministic dates
  # (FR-B810-007/NFR-B810-005). Static presence is the L1 assertion.
  grep -qF 'SOURCE_DATE_EPOCH' "$SCRIPT" \
    || { echo "    FAIL T-012: script body does not reference SOURCE_DATE_EPOCH (FR-B810-007/NFR-B810-005)" >&2; return 1; }
}

# ─── L2 (opt-in) ─────────────────────────────────────────────────
# Mirrors the b8-1 FORGE_B8_1_DOCKER opt-in env-gate (P-23). When
# FORGE_B8_10_LIVE=1 and a real 1.0.0 scaffold target can be produced, run a
# live --dry-run and assert exit 0 + no mutation. When unset, skip-pass.

_test_b810_l2_001_live_dry_run() {
  if [ "${FORGE_B8_10_LIVE:-0}" != "1" ]; then
    echo "    SKIP: FORGE_B8_10_LIVE not set (opt-in)" >&2
    return 0
  fi
  if [ ! -f "$SCRIPT" ]; then
    echo "    FAIL T-012-L2: script absent: $SCRIPT (FR-B810-078)" >&2; return 1
  fi
  # Prefer a real `forge init` 1.0.0 tree; fall back to the hermetic fixture if
  # the toolchain is unavailable (skip-pass honestly rather than block).
  local fix rc dirty
  if command -v forge >/dev/null 2>&1; then
    fix=$(mktemp -d -t b8-10-l2-XXXXXX)
    if ! (cd "$fix" && forge init --archetype full-stack-monorepo --yes >/dev/null 2>&1); then
      rm -rf "$fix"
      echo "    SKIP: 'forge init' unavailable/failed in this env — L2 live leg deferred" >&2
      return 0
    fi
    git -C "$fix" init -q >/dev/null 2>&1 || true
    git -C "$fix" add -A >/dev/null 2>&1 || true
    git -C "$fix" -c user.email=b810@forge.test -c user.name=b810 \
      commit -q -m fixture >/dev/null 2>&1 || true
  else
    echo "    SKIP: 'forge' not on PATH — L2 live leg deferred (skip-pass)" >&2
    return 0
  fi
  # shellcheck disable=SC2064
  trap "rm -rf '$fix'" RETURN
  SOURCE_DATE_EPOCH=0 bash "$SCRIPT" --target "$fix" --dry-run >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] \
    || { echo "    FAIL T-012-L2: live --dry-run exit $rc != 0 (FR-B810-078)" >&2; return 1; }
  dirty=$(git -C "$fix" status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    echo "    FAIL T-012-L2: live --dry-run mutated the target (NFR-B810-005/010):" >&2
    printf '%s\n' "$dirty" | sed 's/^/      /' >&2
    return 1
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.8.10 — b8-10-migrate-flagship — level $LEVEL ──"
  run_test _test_b810_l1_001_script_exists_exec_header
  run_test _test_b810_l1_002_help_exit0_target_table
  run_test _test_b810_l1_003_zero_new_dep
  run_test _test_b810_l1_004_dry_run_no_mutation
  run_test _test_b810_l1_005_exit_envelope
  run_test _test_b810_l1_006_no_dbos_guard
  run_test _test_b810_l1_007_additive_only_guard
  run_test _test_b810_l1_008_rollback_path_and_no_snapshot_write
  run_test _test_b810_l1_009_migrations_and_changelog
  run_test _test_b810_l1_010_frozen_snapshot_guard
  run_test _test_b810_l1_011_sibling_coupling
  run_test _test_b810_l1_012_source_date_epoch_static

  if [ "$LEVEL" = "2" ] || printf '%s' "$LEVEL" | grep -q '2'; then
    run_test _test_b810_l2_001_live_dry_run
  fi

  print_summary
}

main
