#!/usr/bin/env bash
# Forge Scaffolder Test Harness (b1-scaffolder)
# <!-- Audit: B.1.2 + B.1.3 + B.1.4 + B.1.13 (b1-scaffolder) -->
#
# Three-level test strategy (design ADR-010):
#
#   L1 — plan shape     : parse scaffold-plan.yaml, assert schema +
#                          source existence. ZERO external tool deps.
#   L2 — overlay render : render templates in a tmpdir, assert
#                          substitution + manifest. ZERO external deps.
#   L3 — end-to-end     : full scaffold via init.sh, requires
#                          flutter + cargo + buf on PATH. OPT-IN.
#
# Auto-detection: L1 + L2 always run. L3 runs if --require-external-tools
# is passed OR if flutter + cargo + buf are all on PATH.
#
# Usage:
#   bash .forge/scripts/tests/scaffolder.test.sh
#   bash .forge/scripts/tests/scaffolder.test.sh --level 1
#   bash .forge/scripts/tests/scaffolder.test.sh --require-external-tools
#   bash .forge/scripts/tests/scaffolder.test.sh --target /tmp/forge-smoke

set -euo pipefail

# ─── Paths ──────────────────────────────────────────────────────

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"
ARCHETYPE_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo"
SCAFFOLD_PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
OVERLAY_SH="$SCRIPTS_DIR/scaffolder/overlay.sh"        # created in Phase 4
INIT_SH="$SCRIPTS_DIR/scaffolder/init.sh"              # created in Phase 5

# ─── Shared helpers ─────────────────────────────────────────────
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

# ─── Flags ──────────────────────────────────────────────────────

LEVEL=""               # auto if empty, else 1|2|3
REQUIRE_TOOLS=false
TARGET_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --level)
      LEVEL="${2:-}"
      shift 2
      ;;
    --level=*) LEVEL="${1#*=}"; shift ;;
    --require-external-tools) REQUIRE_TOOLS=true; shift ;;
    --target)
      TARGET_DIR="${2:-}"
      shift 2
      ;;
    --target=*) TARGET_DIR="${1#*=}"; shift ;;
    --help|-h)
      sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "scaffolder.test.sh: unknown flag '$1' (try --help)" >&2
      exit 2
      ;;
  esac
done

# ─── Auto-detect external tools ─────────────────────────────────

have_external_tools() {
  command -v flutter >/dev/null 2>&1 \
    && command -v cargo >/dev/null 2>&1 \
    && command -v buf >/dev/null 2>&1
}

# Decide which levels to run based on flags + auto-detection.
decide_levels() {
  if [ -n "$LEVEL" ]; then
    echo "$LEVEL"
    return
  fi
  # Auto: always L1 + L2. L3 if --require-external-tools or tools present.
  if [ "$REQUIRE_TOOLS" = "true" ] || have_external_tools; then
    echo "1,2,3"
  else
    echo "1,2"
  fi
}

# ─── L1 tests : plan shape (no external deps) ───────────────────

test_plan_yaml_parses_as_safe_yaml() {
  python3 - "$SCAFFOLD_PLAN" <<'PY' || { echo "    plan failed to parse" >&2; return 1; }
import sys, yaml
try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f"YAML parse error: {e}", file=sys.stderr); sys.exit(1)
PY
}

test_plan_has_required_top_level_keys() {
  local result
  result=$(python3 - "$SCAFFOLD_PLAN" <<'PY'
import sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)
required = {"archetype", "version", "official_scaffolders", "templates", "post_steps"}
missing = sorted(required - set(data.keys() if isinstance(data, dict) else []))
if missing:
    print(f"missing: {missing}")
else:
    print("ok")
PY
)
  assert_eq "ok" "$result" "required keys"
}

test_plan_archetype_field_exact() {
  local archetype
  archetype=$(python3 -c "
import yaml
print(yaml.safe_load(open('$SCAFFOLD_PLAN'))['archetype'])
")
  assert_eq "full-stack-monorepo" "$archetype" "archetype name"
}

test_plan_version_is_semver() {
  local version
  version=$(python3 -c "
import yaml
print(yaml.safe_load(open('$SCAFFOLD_PLAN'))['version'])
")
  if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[[:alnum:].-]+)?$ ]]; then
    echo "    version '$version' does not match SemVer" >&2
    return 1
  fi
}

test_plan_templates_sources_exist() {
  local result
  result=$(python3 - "$SCAFFOLD_PLAN" "$ARCHETYPE_DIR" <<'PY'
import sys, yaml, os
plan_path = sys.argv[1]
archetype_dir = sys.argv[2]
with open(plan_path, 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)
templates = data.get("templates", [])
if not isinstance(templates, list):
    print("KO: templates is not a list"); sys.exit(0)
missing = []
for entry in templates:
    if not isinstance(entry, dict):
        missing.append(f"<non-dict entry>"); continue
    src = entry.get("source")
    if not src:
        missing.append(f"<entry without source>"); continue
    if not os.path.isfile(os.path.join(archetype_dir, src)):
        missing.append(src)
if missing:
    print(f"KO: missing sources: {missing}")
else:
    print("OK")
PY
)
  assert_eq "OK" "$result" "source existence"
}

test_plan_official_scaffolders_shape() {
  local result
  result=$(python3 - "$SCAFFOLD_PLAN" <<'PY'
import sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)
entries = data.get("official_scaffolders", [])
if not isinstance(entries, list):
    print("KO: not a list"); sys.exit(0)
for i, e in enumerate(entries):
    if not isinstance(e, dict):
        print(f"KO: entry {i} is not a dict"); sys.exit(0)
    if "cmd" not in e or not isinstance(e["cmd"], str):
        print(f"KO: entry {i} missing 'cmd'"); sys.exit(0)
    if "required" in e and not isinstance(e["required"], bool):
        print(f"KO: entry {i} 'required' not bool"); sys.exit(0)
print("OK")
PY
)
  assert_eq "OK" "$result" "official_scaffolders shape"
}

test_plan_templates_count_minimum() {
  local count
  count=$(python3 -c "
import yaml
print(len(yaml.safe_load(open('$SCAFFOLD_PLAN')).get('templates', [])))
")
  if [ "$count" -lt 20 ]; then
    echo "    templates count=$count (minimum: 20 per AC-007)" >&2
    return 1
  fi
}

# ─── L2 tests : overlay rendering (no external deps) ────────────
#
# All L2 tests use mk_tmpdir_with_trap + a trap cleanup so nothing
# leaks to /tmp between runs. They invoke overlay.sh (the renderer
# under test) and assert its behavior on synthetic targets.

test_overlay_substitutes_project_name() {
  local tgt; tgt=$(mk_tmpdir_with_trap forge-overlay-subst)
  trap "rm -rf '$tgt'" RETURN
  bash "$OVERLAY_SH" --target "$tgt" --project-name foo --reverse-domain com.example >/dev/null 2>&1 || {
    echo "    overlay.sh exited non-zero on happy path" >&2; return 1;
  }
  # <project-name> must be replaced in README.md (substitute: true)
  local content; content=$(cat "$tgt/README.md")
  assert_contains "$content" "foo" "project-name substituted in README" || return 1
  assert_not_contains "$content" "<project-name>" "placeholder leaked in README" || return 1
}

test_overlay_preserves_non_substitute_files() {
  local tgt; tgt=$(mk_tmpdir_with_trap forge-overlay-preserve)
  trap "rm -rf '$tgt'" RETURN
  bash "$OVERLAY_SH" --target "$tgt" --project-name foo --reverse-domain com.example >/dev/null 2>&1 \
    || return 1
  # .gitignore is substitute: false — must be byte-identical to source.
  local src="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/.gitignore.tmpl"
  if ! diff -q "$src" "$tgt/.gitignore" >/dev/null 2>&1; then
    echo "    .gitignore differs from source despite substitute=false" >&2
    return 1
  fi
}

test_overlay_force_overwrites_existing() {
  local tgt; tgt=$(mk_tmpdir_with_trap forge-overlay-force)
  trap "rm -rf '$tgt'" RETURN
  # Pre-create a target file that would collide with an overlay target.
  mkdir -p "$tgt"
  echo "pre-existing content" > "$tgt/.forge.yaml"
  # Without --force: expect exit 4 and the file untouched.
  if bash "$OVERLAY_SH" --target "$tgt" --project-name foo --reverse-domain com.example >/dev/null 2>&1; then
    echo "    expected exit 4 on collision without --force, got 0" >&2
    return 1
  fi
  local preserved; preserved=$(cat "$tgt/.forge.yaml")
  assert_eq "pre-existing content" "$preserved" "pre-existing file preserved" || return 1
  # With --force: must succeed and overwrite.
  bash "$OVERLAY_SH" --target "$tgt" --project-name foo --reverse-domain com.example --force >/dev/null 2>&1 \
    || { echo "    --force run failed" >&2; return 1; }
  local overwritten; overwritten=$(cat "$tgt/.forge.yaml")
  assert_not_contains "$overwritten" "pre-existing content" "file was overwritten" || return 1
}

test_overlay_idempotent_with_force() {
  local tgt; tgt=$(mk_tmpdir_with_trap forge-overlay-idempotent)
  trap "rm -rf '$tgt'" RETURN
  # SOURCE_DATE_EPOCH pins the manifest timestamp so two runs produce
  # byte-identical output (reproducible-builds convention).
  SOURCE_DATE_EPOCH=1761062400 bash "$OVERLAY_SH" \
    --target "$tgt" --project-name foo --reverse-domain com.example --force >/dev/null 2>&1 || return 1
  local snapshot1; snapshot1=$(find "$tgt" -type f -exec sha256sum {} \; | sort)
  SOURCE_DATE_EPOCH=1761062400 bash "$OVERLAY_SH" \
    --target "$tgt" --project-name foo --reverse-domain com.example --force >/dev/null 2>&1 || return 1
  local snapshot2; snapshot2=$(find "$tgt" -type f -exec sha256sum {} \; | sort)
  if [ "$snapshot1" != "$snapshot2" ]; then
    echo "    second --force run produced different output (not idempotent)" >&2
    echo "    first : $(printf '%s' "$snapshot1" | head -3)" >&2
    echo "    second: $(printf '%s' "$snapshot2" | head -3)" >&2
    return 1
  fi
}

test_overlay_writes_manifest() {
  local tgt; tgt=$(mk_tmpdir_with_trap forge-overlay-manifest)
  trap "rm -rf '$tgt'" RETURN
  bash "$OVERLAY_SH" --target "$tgt" --project-name foo --reverse-domain com.example >/dev/null 2>&1 || return 1
  if [ ! -f "$tgt/.forge/scaffold-manifest.yaml" ]; then
    echo "    scaffold-manifest.yaml not written" >&2
    return 1
  fi
  local result; result=$(python3 - "$tgt/.forge/scaffold-manifest.yaml" <<'PY'
import sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    m = yaml.safe_load(f)
required = {"archetype", "archetype_version", "scaffold_plan_sha", "template_set_sha", "tools", "scaffold_date"}
missing = sorted(required - set(m.keys() if isinstance(m, dict) else []))
if missing:
    print(f"KO: missing keys {missing}"); sys.exit(0)
if m.get("archetype") != "full-stack-monorepo":
    print(f"KO: archetype mismatch"); sys.exit(0)
print("OK")
PY
)
  assert_eq "OK" "$result" "manifest shape" || return 1
}

test_overlay_regex_validates_project_name() {
  local tgt; tgt=$(mk_tmpdir_with_trap forge-overlay-regex-name)
  trap "rm -rf '$tgt'" RETURN
  local bad
  for bad in "UPPER-NAME" "a name with spaces" "../evil" "1starts_with_digit"; do
    if bash "$OVERLAY_SH" --target "$tgt" --project-name "$bad" --reverse-domain com.example --force >/dev/null 2>&1; then
      echo "    overlay accepted invalid project-name '$bad'" >&2
      return 1
    fi
  done
}

test_overlay_regex_validates_reverse_domain() {
  local tgt; tgt=$(mk_tmpdir_with_trap forge-overlay-regex-domain)
  trap "rm -rf '$tgt'" RETURN
  local bad
  for bad in "no-dot" "-bad.start" "com..double" "ends.with.dot."; do
    if bash "$OVERLAY_SH" --target "$tgt" --project-name foo --reverse-domain "$bad" --force >/dev/null 2>&1; then
      echo "    overlay accepted invalid reverse-domain '$bad'" >&2
      return 1
    fi
  done
}

# ─── L3 tests : end-to-end (requires flutter + cargo + buf) ─────
#
# Each L3 test creates a fresh tmpdir target, invokes init.sh, and
# asserts on the scaffolded tree. The happy-path test is intentionally
# the most expensive (one `flutter create` + five `cargo new`s) —
# keep the other tests as specific as possible to amortise.

test_e2e_happy_path() {
  local tmp; tmp=$(mk_tmpdir_with_trap forge-e2e-happy)
  trap "rm -rf '$tmp'" RETURN
  local tgt="$tmp/demo-app"
  bash "$INIT_SH" demo-app --org com.example.forgetest --target-dir "$tgt" >"$tmp/log" 2>&1 || {
    echo "    init.sh exited non-zero on happy path — see $tmp/log" >&2
    tail -20 "$tmp/log" >&2
    return 1
  }
  # Key artefacts produced by the official scaffolders:
  [ -f "$tgt/frontend/pubspec.yaml" ]     || { echo "    frontend/pubspec.yaml missing" >&2; return 1; }
  [ -f "$tgt/backend/Cargo.toml" ]        || { echo "    backend/Cargo.toml missing" >&2; return 1; }
  [ -f "$tgt/backend/crates/domain/Cargo.toml" ] || { echo "    backend/crates/domain missing" >&2; return 1; }
  [ -f "$tgt/backend/bin-server/Cargo.toml" ]    || { echo "    backend/bin-server missing" >&2; return 1; }
  # Archetype overlay files:
  [ -f "$tgt/Taskfile.yml" ]                        || { echo "    Taskfile.yml missing" >&2; return 1; }
  [ -f "$tgt/docker-compose.dev.yml" ]              || { echo "    docker-compose.dev.yml missing" >&2; return 1; }
  [ -f "$tgt/shared/protos/v1/example/example.proto" ] || { echo "    example.proto missing" >&2; return 1; }
  # Scaffold manifest with tools populated:
  [ -f "$tgt/.forge/scaffold-manifest.yaml" ]       || { echo "    scaffold-manifest.yaml missing" >&2; return 1; }
  local tool_count; tool_count=$(python3 -c "
import yaml
m = yaml.safe_load(open('$tgt/.forge/scaffold-manifest.yaml'))
print(len(m.get('tools', {})))
")
  assert_eq "3" "$tool_count" "manifest.tools has 3 entries (flutter/cargo/buf)" || return 1
}

test_e2e_missing_flutter_aborts() {
  local tmp; tmp=$(mk_tmpdir_with_trap forge-e2e-nofl)
  trap "rm -rf '$tmp'" RETURN
  local tgt="$tmp/should-not-exist"
  # Strip flutter from PATH only — keep cargo and buf available so we
  # hit the flutter check, not a composite failure.
  local filtered_path
  filtered_path=$(printf '%s' "$PATH" | tr ':' '\n' \
    | grep -v '/flutter' | paste -sd: -)
  if PATH="$filtered_path" bash "$INIT_SH" demo-app --org com.example --target-dir "$tgt" >/dev/null 2>&1; then
    echo "    init.sh did not abort when flutter is absent" >&2
    return 1
  fi
  if [ -e "$tgt" ]; then
    echo "    target directory was created despite early-abort" >&2
    return 1
  fi
}

test_e2e_buf_lint_passes() {
  local tmp; tmp=$(mk_tmpdir_with_trap forge-e2e-buf)
  trap "rm -rf '$tmp'" RETURN
  local tgt="$tmp/demo-app"
  bash "$INIT_SH" demo-app --org com.example.forgetest --target-dir "$tgt" >/dev/null 2>&1 || return 1
  if ! (cd "$tgt/shared/protos" && buf lint >/dev/null 2>&1); then
    echo "    buf lint failed on scaffolded protos" >&2
    return 1
  fi
}

test_e2e_detects_missing_file() {
  local tmp; tmp=$(mk_tmpdir_with_trap forge-e2e-missing)
  trap "rm -rf '$tmp'" RETURN
  local tgt="$tmp/demo-app"
  bash "$INIT_SH" demo-app --org com.example.forgetest --target-dir "$tgt" >/dev/null 2>&1 || return 1
  # Delete the schema file and re-run the scaffolded project's validator.
  rm -f "$tgt/.forge/schemas/full-stack-monorepo/schema.yaml"
  if FORGE_ROOT="$tgt" bash "$tgt/.forge/scripts/validate-foundations.sh" >/dev/null 2>&1; then
    echo "    validator PASSed after schema deletion (regression?)" >&2
    return 1
  fi
}

test_e2e_detects_contract_drift() {
  local tmp; tmp=$(mk_tmpdir_with_trap forge-e2e-drift)
  trap "rm -rf '$tmp'" RETURN
  local tgt="$tmp/demo-app"
  bash "$INIT_SH" demo-app --org com.example.forgetest --target-dir "$tgt" >/dev/null 2>&1 || return 1
  # Inject a malformed version into the schema and re-run the validator.
  python3 -c "
import yaml
p = '$tgt/.forge/schemas/full-stack-monorepo/schema.yaml'
d = yaml.safe_load(open(p))
d['version'] = 'draft'  # non-SemVer
with open(p, 'w') as f: yaml.safe_dump(d, f)
"
  if FORGE_ROOT="$tgt" bash "$tgt/.forge/scripts/validate-foundations.sh" >/dev/null 2>&1; then
    echo "    validator PASSed after contract drift injection" >&2
    return 1
  fi
}

test_e2e_performance_budget() {
  # NFR-006 : warm scaffold SHOULD complete in < 10s (cold first run
  # downloads Flutter SDK deps so we relax to 60s on cold and 30s on
  # warm). This is a ceiling, not a tight assertion.
  local tmp; tmp=$(mk_tmpdir_with_trap forge-e2e-perf)
  trap "rm -rf '$tmp'" RETURN
  local tgt="$tmp/demo-app"
  local start_ns end_ns elapsed_ms
  start_ns=$(python3 -c 'import time; print(int(time.time()*1e9))')
  bash "$INIT_SH" demo-app --org com.example.forgetest --target-dir "$tgt" >/dev/null 2>&1 || return 1
  end_ns=$(python3 -c 'import time; print(int(time.time()*1e9))')
  elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
  echo "    elapsed: ${elapsed_ms}ms (NFR-006 warm budget: 30000ms, hard ceiling: 60000ms)"
  if [ "$elapsed_ms" -gt 60000 ]; then
    echo "    FAIL: ${elapsed_ms}ms > 60000ms ceiling" >&2
    return 1
  fi
}

test_e2e_idempotence_with_force() {
  local tmp; tmp=$(mk_tmpdir_with_trap forge-e2e-idempo)
  trap "rm -rf '$tmp'" RETURN
  local tgt="$tmp/demo-app"
  # First run — fresh scaffold.
  bash "$INIT_SH" demo-app --org com.example.forgetest --target-dir "$tgt" >/dev/null 2>&1 || return 1
  # Snapshot just the overlay-owned files (not flutter/cargo output, which
  # would require a non-trivial subset — overlay covers .forge.yaml,
  # Taskfile.yml, docker-compose.dev.yml, CLAUDE.md, etc.).
  local snapshot1
  snapshot1=$(SOURCE_DATE_EPOCH=1761062400 sha256sum \
    "$tgt/.forge.yaml" "$tgt/Taskfile.yml" "$tgt/docker-compose.dev.yml" "$tgt/CLAUDE.md" \
    | sort)
  # Second overlay pass with --force + pinned timestamp.
  SOURCE_DATE_EPOCH=1761062400 bash "$OVERLAY_SH" \
    --target "$tgt" --project-name demo-app --reverse-domain com.example.forgetest --force >/dev/null 2>&1 || return 1
  local snapshot2
  snapshot2=$(sha256sum \
    "$tgt/.forge.yaml" "$tgt/Taskfile.yml" "$tgt/docker-compose.dev.yml" "$tgt/CLAUDE.md" \
    | sort)
  assert_eq "$snapshot1" "$snapshot2" "overlay files byte-identical after --force re-run"
}

# ─── Main dispatcher ────────────────────────────────────────────

main() {
  echo "── Forge Scaffolder Test Harness ──"
  echo "  ARCHETYPE=$ARCHETYPE_DIR"
  echo "  SCAFFOLD_PLAN=$SCAFFOLD_PLAN"
  local levels; levels="$(decide_levels)"
  echo "  LEVELS=$levels"
  echo ""

  if [[ "$levels" == *"1"* ]]; then
    echo "── L1 : plan shape ──"
    run_test test_plan_yaml_parses_as_safe_yaml
    run_test test_plan_has_required_top_level_keys
    run_test test_plan_archetype_field_exact
    run_test test_plan_version_is_semver
    run_test test_plan_templates_sources_exist
    run_test test_plan_official_scaffolders_shape
    run_test test_plan_templates_count_minimum
  fi

  if [[ "$levels" == *"2"* ]]; then
    echo ""
    echo "── L2 : overlay rendering ──"
    run_test test_overlay_substitutes_project_name
    run_test test_overlay_preserves_non_substitute_files
    run_test test_overlay_force_overwrites_existing
    run_test test_overlay_idempotent_with_force
    run_test test_overlay_writes_manifest
    run_test test_overlay_regex_validates_project_name
    run_test test_overlay_regex_validates_reverse_domain
  fi

  if [[ "$levels" == *"3"* ]]; then
    if ! have_external_tools && [ "$REQUIRE_TOOLS" != "true" ]; then
      echo ""
      echo "── L3 : end-to-end — SKIPPED (flutter / cargo / buf not all on PATH) ──"
    else
      echo ""
      echo "── L3 : end-to-end ──"
      run_test test_e2e_happy_path
      run_test test_e2e_missing_flutter_aborts
      run_test test_e2e_buf_lint_passes
      run_test test_e2e_detects_missing_file
      run_test test_e2e_detects_contract_drift
      run_test test_e2e_performance_budget
      run_test test_e2e_idempotence_with_force
    fi
  fi

  print_summary
}

main "$@"
