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
#   T-013  a REAL migration writes no .tmpl, no placeholder, no shadowing sibling (FR-B810B-001/002/004)
#   T-014  migration-plan-2.0.0.yaml covers the 2.0.0 tree exactly, both ways   (FR-B810B-001)
#
#   T-L2-002 (opt-in) the same assertions on a REAL 1.0.0 render — proves the
#            synthetic T-013 fixture is faithful                              (FR-B810B-005)
#
# 14 L1 + 2 L2 tests. Budget L1 ≤ 2 s, zero net/Docker/live-`forge init`. The live
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

_test_b810_l1_014_migration_plan_covers_the_tree() {
  # A hand-maintained list of 36 paths drifts the moment someone adds a template.
  # Asserted in BOTH directions: an entry pointing at a missing source would make
  # overlay.sh fail at migration time, and an unlisted source would be silently
  # dropped from what the adopter receives — which is the failure this whole brick
  # exists to fix, reappearing one file at a time (FR-B810B-001).
  local plan="$FORGE_ROOT/.forge/templates/archetypes/full-stack-monorepo/migration-plan-2.0.0.yaml"
  [ -f "$plan" ] || { echo "    FAIL T-014: migration-plan-2.0.0.yaml missing (FR-B810B-001)" >&2; return 1; }

  python3 - "$FORGE_ROOT" "$plan" <<'PY' >&2
import subprocess, sys, yaml, os
root, plan = sys.argv[1], sys.argv[2]
prefix = ".forge/templates/archetypes/full-stack-monorepo/2.0.0/"
# git ls-files, NOT a filesystem walk: this tree is a working directory and runtime
# tooling can drop ignored state into it. That happened while the plan was authored
# and briefly made the count 37.
out = subprocess.run(["git", "-C", root, "ls-files", prefix],
                     capture_output=True, text=True).stdout
tracked = {p[len(prefix):] for p in out.splitlines() if p.strip()}
doc = yaml.safe_load(open(plan)) or {}
listed = {e["source"][len("2.0.0/"):] for e in (doc.get("templates") or [])
          if str(e.get("source", "")).startswith("2.0.0/")}
missing = sorted(tracked - listed)
extra = sorted(listed - tracked)
bad = False
if missing:
    print("    FAIL T-014: %d tracked 2.0.0 file(s) absent from the migration plan "
          "— the adopter would not receive them (FR-B810B-001):" % len(missing))
    for m in missing[:5]:
        print("      %s" % m)
    bad = True
if extra:
    print("    FAIL T-014: %d plan entr(y/ies) point at a source that does not exist "
          "— overlay.sh would fail at migration time:" % len(extra))
    for e in extra[:5]:
        print("      %s" % e)
    bad = True
if not tracked:
    print("    FAIL T-014: git ls-files found NO tracked files under 2.0.0/ — the "
          "comparison is vacuous")
    bad = True
raise SystemExit(1 if bad else 0)
PY
}

_test_b810_l1_013_migration_output_rendered() {
  # THE gap this harness had: every other test inspects the SCRIPT, and the only
  # live test is a --dry-run, which by construction produces no files. Nothing
  # ever looked at what the migration actually writes into an adopter's tree.
  #
  # It writes raw templates. `TPL_20` (:48) is the framework's 2.0.0 template
  # tree, `_b810_map_relpath` strips only the `2.0.0/` prefix, and the file ops
  # are a plain `cp` — so `.tmpl` files land with `<project-name>` intact
  # (b8-10b-migrate-render, FR-B810B-001/002/004).
  local fix; fix=$(_b810_make_fixture 1.0.0)
  # shellcheck disable=SC2064
  trap "rm -rf '$fix'" RETURN

  # Seed the two files the 2.0.0 set also provides, so assertion (3) is actually
  # exercised. Without them the fixture has nothing to shadow and that branch
  # would pass vacuously — which is how a three-part test quietly becomes a
  # two-part one. A real adopter tree has nine such collisions.
  printf '# %s\n' "b810-fixture" > "$fix/README.md"
  printf '# %s\n' "b810-fixture" > "$fix/CLAUDE.md"
  git -C "$fix" add -A >/dev/null 2>&1
  git -C "$fix" -c user.email=b810@forge.test -c user.name=b810 \
    commit -q -m "seed shadowable files" >/dev/null 2>&1

  bash "$SCRIPT" --target "$fix" --force >/dev/null 2>&1
  local rc=$?
  if [ "$rc" != "0" ]; then
    echo "    FAIL T-013: migration exited $rc on a clean 1.0.0 fixture (FR-B810B-001)" >&2
    return 1
  fi

  local ok=1

  # (1) No raw template may reach the adopter. Stated over the tree, not over a
  # list of known files, so a future addition to the 2.0.0 set inherits the rule.
  local tmpls
  tmpls=$(find "$fix" -name '*.tmpl' -not -path '*/.git/*' -not -path '*/.forge/templates/*' | sort)
  if [ -n "$tmpls" ]; then
    echo "    FAIL T-013: $(printf '%s\n' "$tmpls" | wc -l | tr -d ' ') raw .tmpl file(s) written into the target (FR-B810B-001):" >&2
    printf '%s\n' "$tmpls" | head -5 | sed "s|$fix/|      |" >&2
    ok=0
  fi

  # (2) No unsubstituted placeholder. A file could be renamed off .tmpl and still
  # carry <project-name>, which is why this is a separate assertion.
  local ph
  ph=$(grep -rlE '<project-name>|<reverse-domain>|<root-module>|<project_name_snake>' \
       "$fix" --exclude-dir=.git --exclude-dir=templates 2>/dev/null | sort)
  if [ -n "$ph" ]; then
    echo "    FAIL T-013: $(printf '%s\n' "$ph" | wc -l | tr -d ' ') file(s) still carry an unsubstituted placeholder (FR-B810B-002):" >&2
    printf '%s\n' "$ph" | head -5 | sed "s|$fix/|      |" >&2
    ok=0
  fi

  # (3) No file may shadow an already-rendered sibling: `X.tmpl` beside `X` leaves
  # the adopter two files where the migration should have merged one.
  local shadow=0 f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "${f%.tmpl}" ] && shadow=$((shadow+1))
  done <<<"$tmpls"
  if [ "$shadow" -gt 0 ]; then
    echo "    FAIL T-013: $shadow file(s) shadow an already-rendered sibling of the same name (FR-B810B-004)" >&2
    ok=0
  fi

  [ "$ok" = "1" ]
}

# ─── L2 (opt-in) ─────────────────────────────────────────────────
# Mirrors the b8-1 FORGE_B8_1_DOCKER opt-in env-gate (P-23). When
# FORGE_B8_10_LIVE=1 and a real 1.0.0 scaffold target can be produced, run a
# live --dry-run and assert exit 0 + no mutation. When unset, skip-pass.

_test_b810_l2_002_real_migration_rendered() {
  # T-013's L1 sibling runs against a SYNTHETIC target — a manifest plus two seeded
  # files. That is enough to catch the defect and it runs everywhere, which is the
  # point (b8-10's only pre-existing live test is toolchain-gated, and CI's `cli`
  # job installs neither flutter nor buf, so gated legs never run there).
  #
  # This leg proves the synthetic fixture is FAITHFUL: same assertions against a
  # real `bin/forge-init-fsm.sh` render, where the 2.0.0 set genuinely overlaps 9
  # existing files. Opt-in, skip-when-absent (FR-B810B-005, Q-003).
  if [ "${FORGE_B8_10_LIVE:-}" != "1" ]; then
    echo "    SKIP T-L2-002: set FORGE_B8_10_LIVE=1 to run the real-render leg"
    return 0
  fi
  if ! command -v flutter >/dev/null 2>&1 || ! command -v cargo >/dev/null 2>&1; then
    echo "    SKIP T-L2-002: needs flutter + cargo for a real 1.0.0 render"
    return 0
  fi

  local tgt; tgt=$(mktemp -d -t b8-10-live-XXXXXX)
  # shellcheck disable=SC2064
  trap "rm -rf '$tgt'" RETURN

  if ! SOURCE_DATE_EPOCH=0 bash "$FORGE_ROOT/bin/forge-init-fsm.sh" \
        --target "$tgt" --project-name b810live --reverse-domain io.forge.b810live \
        --force >/dev/null 2>&1; then
    echo "    FAIL T-L2-002: 1.0.0 render failed — cannot exercise the migration" >&2
    return 1
  fi
  git init -q "$tgt" >/dev/null 2>&1
  git -C "$tgt" add -A >/dev/null 2>&1
  git -C "$tgt" -c user.email=b810@forge.test -c user.name=b810 \
    commit -q -m "1.0.0 base" >/dev/null 2>&1

  bash "$SCRIPT" --target "$tgt" --force >/dev/null 2>&1

  local ok=1 n
  n=$(find "$tgt" -name '*.tmpl' -not -path '*/.git/*' -not -path '*/.forge/templates/*' | wc -l | tr -d ' ')
  if [ "$n" != "0" ]; then
    echo "    FAIL T-L2-002: $n raw .tmpl file(s) in a REAL migrated tree (FR-B810B-001)" >&2
    ok=0
  fi
  # The whole point of the real leg: the Qwik surface must arrive as usable files.
  if [ ! -f "$tgt/frontend/web-public/package.json" ]; then
    echo "    FAIL T-L2-002: frontend/web-public/package.json absent — the surface docs/MIGRATIONS.md promises did not arrive rendered (FR-B810B-001)" >&2
    ok=0
  fi
  if grep -qE '<project-name>|<reverse-domain>|<root-module>' \
       "$tgt/frontend/web-public/README.md" 2>/dev/null; then
    echo "    FAIL T-L2-002: the rendered web-public README still carries a placeholder (FR-B810B-002)" >&2
    ok=0
  fi
  [ "$ok" = "1" ]
}

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
  run_test _test_b810_l1_013_migration_output_rendered
  run_test _test_b810_l1_014_migration_plan_covers_the_tree

  if [ "$LEVEL" = "2" ] || printf '%s' "$LEVEL" | grep -q '2'; then
    run_test _test_b810_l2_001_live_dry_run
    run_test _test_b810_l2_002_real_migration_rendered
  fi

  print_summary
}

main
