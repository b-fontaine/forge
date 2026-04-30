#!/usr/bin/env bash
# Forge Deterministic Verification Script
# Runs concrete, file-based checks that do not depend on LLM judgment.
# Exit code 0 = all checks pass, 1 = at least one failure.

set -uo pipefail

FORGE_ROOT="${FORGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CHANGES_DIR="$FORGE_ROOT/.forge/changes"
PASS=0
FAIL=0
WARN=0

# ─── c1-reference-project skip-guard (FR-GL-026) ────────────────
# When invoked from the Forge framework repository (signature : the
# canonical archetype spec file lives under .forge/specs/ AND an
# examples/ directory exists), the framework's own gates MUST NOT
# recurse into examples/. Each example tree owns its own gates and
# runs them via examples/forge-fsm-example/.forge/scripts/verify.sh.
# When invoked from inside an example tree, the signature does not
# match (example trees expose the archetype contract via .forge/specs/
# in the framework repo, not in their own .forge/), so the guard does
# not activate.
FORGE_REPO_DETECTED=0
if [ -f "$FORGE_ROOT/.forge/specs/full-stack-monorepo.md" ] \
     && [ -d "$FORGE_ROOT/examples" ]; then
  FORGE_REPO_DETECTED=1
fi

# is_under_examples <path> — returns 0 (true) iff $path falls under
# $FORGE_ROOT/examples/ AND the framework-repo signature matched.
# Used by every section that walks the file tree to skip example
# subtrees with an explicit '[skipped: examples] ...' notice.
# This guard is defensive : the current verify.sh sections walk
# fixed paths that do not naturally cross examples/ ; the guard
# protects against future broader walks (FR-GL-026).
is_under_examples() {
  [ "$FORGE_REPO_DETECTED" = "1" ] || return 1
  case "$1" in
    "$FORGE_ROOT/examples"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# ─── Helpers ────────────────────────────────────────────────────

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }
warn() { WARN=$((WARN + 1)); echo "  ⚠ $1"; }
section() { echo ""; echo "── $1 ──"; }

# ─── b1-workflow additions (multi-root scoping) ─────────────────

# Layer-scoped pass/fail — prefix every line with [<layer>] so
# aggregated output is unambiguous (design ADR-006).
pass_scoped() { PASS=$((PASS + 1)); echo "  ✓ [$1] $2"; }
fail_scoped() { FAIL=$((FAIL + 1)); echo "  ✗ [$1] $2"; }
warn_scoped() { WARN=$((WARN + 1)); echo "  ⚠ [$1] $2"; }

# detect_target_schema — reads <FORGE_ROOT>/.forge.yaml and echoes
# its `schema:` field (empty string on missing/malformed). Used to
# gate the multi-root sections (ADR-005).
detect_target_schema() {
  local yml="$FORGE_ROOT/.forge.yaml"
  [ -f "$yml" ] || { echo ""; return; }
  python3 - "$yml" <<'PY' 2>/dev/null || echo ""
import sys, yaml
try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        d = yaml.safe_load(f) or {}
except yaml.YAMLError:
    sys.exit(0)
print(d.get('schema', ''))
PY
}

# resolve_layer_path <layer-id> — echoes the path of a given layer
# relative to FORGE_ROOT, resolved dynamically from the archetype
# schema (ADR-004). Empty string if the schema or the layer is
# absent. Rejects paths containing `..` or starting with `/`.
resolve_layer_path() {
  local layer_id="$1"
  local schema="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/schema.yaml"
  [ -f "$schema" ] || { echo ""; return; }
  python3 - "$schema" "$layer_id" <<'PY' 2>/dev/null || echo ""
import sys, yaml, re
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    d = yaml.safe_load(f) or {}
for layer in d.get('layers', []) or []:
    if isinstance(layer, dict) and layer.get('id') == sys.argv[2]:
        p = layer.get('path') or ''
        # Reject traversal + absolute paths (design Security).
        if '..' in p or p.startswith('/') or re.search(r'\s', p):
            sys.exit(0)
        print(p.rstrip('/'))
        sys.exit(0)
PY
}

# ─── 1. Change Artifact Completeness ───────────────────────────

section "Change Artifact Completeness"

if [ ! -d "$CHANGES_DIR" ] || [ -z "$(ls -A "$CHANGES_DIR" 2>/dev/null)" ]; then
  warn "No active changes in .forge/changes/"
else
  for change_dir in "$CHANGES_DIR"/*/; do
    [ -d "$change_dir" ] || continue
    # c1-reference-project skip-guard (FR-GL-026) — defensive : if a
    # future change_dir ever lives under examples/ (currently never
    # the case since CHANGES_DIR is fixed at the framework root),
    # skip it explicitly so example trees stay self-contained.
    if is_under_examples "$change_dir"; then
      echo "  [skipped: examples] $change_dir"
      continue
    fi
    change_name="$(basename "$change_dir")"
    forge_yaml="$change_dir/.forge.yaml"

    if [ ! -f "$forge_yaml" ]; then
      fail "$change_name: missing .forge.yaml"
      continue
    fi

    status=$(grep '^status:' "$forge_yaml" | head -1 | awk '{print $2}')
    pass "$change_name: .forge.yaml found (status: $status)"

    # Check artifacts exist based on status progression (cumulative)
    needs_proposal=false; needs_specs=false; needs_design=false; needs_tasks=false
    case "$status" in
      implemented|archived) needs_tasks=true; needs_design=true; needs_specs=true; needs_proposal=true ;;
      planned)              needs_design=true; needs_specs=true; needs_proposal=true ;;
      designed)             needs_specs=true; needs_proposal=true ;;
      specified)            needs_proposal=true ;;
    esac

    if $needs_proposal; then
      [ -f "$change_dir/proposal.md" ] && pass "$change_name: proposal.md exists" || fail "$change_name: missing proposal.md (required at status=$status)"
    fi
    if $needs_specs; then
      [ -f "$change_dir/specs.md" ] && pass "$change_name: specs.md exists" || fail "$change_name: missing specs.md (required at status=$status)"
    fi
    if $needs_design; then
      [ -f "$change_dir/design.md" ] && pass "$change_name: design.md exists" || fail "$change_name: missing design.md (required at status=$status)"
    fi
    if $needs_tasks; then
      [ -f "$change_dir/tasks.md" ] && pass "$change_name: tasks.md exists" || fail "$change_name: missing tasks.md (required at status=$status)"
    fi
  done
fi

# ─── 2. Flutter Checks ─────────────────────────────────────────

if [ -f "$FORGE_ROOT/pubspec.yaml" ]; then
  section "Flutter Checks"

  # Static analysis
  if command -v flutter &>/dev/null; then
    if flutter analyze --fatal-infos "$FORGE_ROOT" 2>/dev/null; then
      pass "flutter analyze: zero issues"
    else
      fail "flutter analyze: issues found"
    fi

    # Formatting
    if dart format --output=none --set-exit-if-changed "$FORGE_ROOT/lib" 2>/dev/null; then
      pass "dart format: all files formatted"
    else
      fail "dart format: unformatted files found"
    fi

    # Tests + coverage
    if flutter test --coverage "$FORGE_ROOT" 2>/dev/null; then
      pass "flutter test: all tests pass"

      # Coverage threshold
      if [ -f "$FORGE_ROOT/coverage/lcov.info" ]; then
        if command -v lcov &>/dev/null; then
          coverage=$(lcov --summary "$FORGE_ROOT/coverage/lcov.info" 2>&1 | grep 'lines' | grep -oP '\d+\.\d+(?=%)' || echo "0")
          if [ "$(echo "$coverage >= 80" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
            pass "Coverage: ${coverage}% (>= 80%)"
          else
            fail "Coverage: ${coverage}% (< 80% threshold)"
          fi
        else
          warn "lcov not installed, cannot check coverage threshold"
        fi
      fi
    else
      fail "flutter test: test failures"
    fi
  else
    warn "flutter CLI not found, skipping Flutter checks"
  fi

  # Layer boundary: domain must not import Flutter
  domain_flutter_imports=$(grep -rl "import 'package:flutter" "$FORGE_ROOT/lib/features"/*/domain/ 2>/dev/null | wc -l | tr -d ' ')
  if [ "$domain_flutter_imports" = "0" ]; then
    pass "Layer boundary: domain has zero Flutter imports"
  else
    fail "Layer boundary: $domain_flutter_imports domain files import Flutter"
  fi
fi

# ─── 3. Rust Checks ────────────────────────────────────────────

if [ -f "$FORGE_ROOT/Cargo.toml" ]; then
  section "Rust Checks"

  if command -v cargo &>/dev/null; then
    # Clippy
    if cargo clippy --all-features --manifest-path "$FORGE_ROOT/Cargo.toml" -- -D warnings 2>/dev/null; then
      pass "cargo clippy: zero warnings"
    else
      fail "cargo clippy: warnings found"
    fi

    # Formatting
    if cargo fmt --all --manifest-path "$FORGE_ROOT/Cargo.toml" --check 2>/dev/null; then
      pass "cargo fmt: all files formatted"
    else
      fail "cargo fmt: unformatted files found"
    fi

    # Tests
    if cargo test --all-features --manifest-path "$FORGE_ROOT/Cargo.toml" 2>/dev/null; then
      pass "cargo test: all tests pass"
    else
      fail "cargo test: test failures"
    fi

    # unwrap/panic in production code
    unwrap_count=$(grep -rn '\.unwrap()' "$FORGE_ROOT/src/" 2>/dev/null | grep -v '#\[cfg(test)\]' | grep -v '// SAFETY:' | wc -l | tr -d ' ')
    if [ "$unwrap_count" = "0" ]; then
      pass "No unwrap() in production code"
    else
      fail "$unwrap_count unwrap() calls in production code (src/)"
    fi

    panic_count=$(grep -rn 'panic!' "$FORGE_ROOT/src/" 2>/dev/null | grep -v '#\[cfg(test)\]' | wc -l | tr -d ' ')
    if [ "$panic_count" = "0" ]; then
      pass "No panic!() in production code"
    else
      fail "$panic_count panic!() calls in production code (src/)"
    fi
  else
    warn "cargo CLI not found, skipping Rust checks"
  fi

  # Domain purity: domain must not import infra crates directly
  domain_infra=$(grep -rn 'sqlx\|reqwest\|hyper\|tonic' "$FORGE_ROOT/src/domain/" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$domain_infra" = "0" ]; then
    pass "Domain purity: no infrastructure imports in domain/"
  else
    fail "Domain purity: $domain_infra infrastructure imports in domain/"
  fi
fi

# ─── 4. Constitution Compliance (Cross-Language) ────────────────

section "Constitution Compliance"

# No untracked TODOs/FIXMEs
todo_dirs=""
[ -d "$FORGE_ROOT/lib" ] && todo_dirs="$todo_dirs $FORGE_ROOT/lib/"
[ -d "$FORGE_ROOT/src" ] && todo_dirs="$todo_dirs $FORGE_ROOT/src/"
if [ -n "$todo_dirs" ]; then
  untracked_todos=$(grep -rn 'TODO\|FIXME' $todo_dirs 2>/dev/null | grep -v 'ISSUE-\|ISSUE:\|#[0-9]' | wc -l | tr -d ' ')
  if [ "$untracked_todos" = "0" ]; then
    pass "No untracked TODO/FIXME (Article X.4)"
  else
    fail "$untracked_todos untracked TODO/FIXME without issue reference (Article X.4)"
  fi
else
  warn "No lib/ or src/ directories found, skipping TODO check"
fi

# Root .forge.yaml exists
if [ -f "$FORGE_ROOT/.forge.yaml" ]; then
  pass "Root .forge.yaml exists"
else
  fail "Root .forge.yaml missing"
fi

# Constitution exists
if [ -f "$FORGE_ROOT/.forge/constitution.md" ]; then
  pass "Constitution exists"
else
  fail "Constitution missing"
fi

# Standards index exists
if [ -f "$FORGE_ROOT/.forge/standards/index.yml" ]; then
  pass "Standards index exists"
else
  fail "Standards index missing"
fi

# ─── 5. Monorepo Foundations (conditional) ─────────────────────

# This section activates only for projects that have adopted the
# full-stack-monorepo archetype (b1-foundations, audit module B.1).
# Non-monorepo projects are unaffected: the validator is skipped.

if [ -d "$FORGE_ROOT/.forge/schemas/full-stack-monorepo" ]; then
  section "Monorepo Foundations"
  foundations_script="$FORGE_ROOT/.forge/scripts/validate-foundations.sh"
  if [ -x "$foundations_script" ] || [ -f "$foundations_script" ]; then
    # Run the validator, capture its PASS/FAIL lines, and aggregate
    # counters into the enclosing verify.sh totals.
    while IFS= read -r line; do
      case "$line" in
        "PASS: "*) pass "${line#PASS: }" ;;
        "FAIL: "*) fail "${line#FAIL: }" ;;
        *) [ -n "$line" ] && echo "  $line" ;;
      esac
    done < <(FORGE_ROOT="$FORGE_ROOT" bash "$foundations_script" || true)
  else
    warn "validate-foundations.sh missing or not executable — skipping"
  fi
else
  # Intentionally emit an informational message so non-monorepo users
  # see explicit confirmation that the conditional check was skipped.
  echo ""
  echo "── Monorepo Foundations ──"
  echo "  (validate-foundations skipped — not a monorepo)"
fi

# ─── 6. Scaffolder (conditional) ───────────────────────────────

# Activates only when the archetype template tree exists (b1-scaffolder).
# Always runs L1 (plan-shape) and L2 (overlay-rendering) — both are
# hermetic and need no external tools. L3 (end-to-end) is NOT invoked
# from verify.sh because it requires flutter + cargo + buf and takes
# several seconds; run `bash .forge/scripts/tests/scaffolder.test.sh
# --require-external-tools` explicitly on a tooled CI runner.

if [ -d "$FORGE_ROOT/.forge/templates/archetypes/full-stack-monorepo" ]; then
  section "Scaffolder (L1 + L2)"
  scaffolder_harness="$FORGE_ROOT/.forge/scripts/tests/scaffolder.test.sh"
  if [ -x "$scaffolder_harness" ] || [ -f "$scaffolder_harness" ]; then
    while IFS= read -r line; do
      case "$line" in
        "  ✓ "*) pass "${line#  ✓ }" ;;
        "  ✗ "*) fail "${line#  ✗ }" ;;
        # Swallow everything else (harness banner, summary, etc.) so
        # verify.sh owns the output format.
      esac
    done < <(bash "$scaffolder_harness" --level 2 2>&1 || true)
  else
    warn "scaffolder.test.sh missing or not executable — skipping"
  fi
else
  echo ""
  echo "── Scaffolder ──"
  echo "  (scaffolder tests skipped — no archetype template tree)"
fi

# ─── 7. Workflow harness dispatch — b1-workflow ────────────────

# Mirror of Section 6's pattern: when the archetype template tree
# exists, dispatch the workflow harness at --level 2 (hermetic) and
# aggregate PASS/FAIL. Design ADR-009.

if [ -d "$FORGE_ROOT/.forge/templates/archetypes/full-stack-monorepo" ]; then
  section "Workflow (L1 + L2)"
  workflow_harness="$FORGE_ROOT/.forge/scripts/tests/workflow.test.sh"
  if [ -x "$workflow_harness" ] || [ -f "$workflow_harness" ]; then
    while IFS= read -r line; do
      case "$line" in
        "  ✓ "*) pass "${line#  ✓ }" ;;
        "  ✗ "*) fail "${line#  ✗ }" ;;
        # Swallow harness banner/summary for clean output (same
        # convention as Section 6).
      esac
    done < <(bash "$workflow_harness" --level 1,2 2>&1 || true)
  else
    warn "workflow.test.sh missing or not executable — skipping"
  fi
fi

# ─── 8. Multi-root (scoped) — b1-workflow ──────────────────────

# Activates only on monorepo projects (schema: full-stack-monorepo in
# target's .forge.yaml). Preserves NFR-010 byte-for-byte backwards
# compatibility for non-monorepo targets by SKIPPING cleanly — no new
# output whatsoever.

target_schema="$(detect_target_schema)"
if [ "$target_schema" = "full-stack-monorepo" ]; then
  backend_path="$(resolve_layer_path backend)"
  frontend_path="$(resolve_layer_path frontend)"

  # ── Backend (scoped) — FR-BE-002 ──
  if [ -n "$backend_path" ] && [ -f "$FORGE_ROOT/$backend_path/Cargo.toml" ]; then
    section "Backend (scoped)"
    if command -v cargo &>/dev/null; then
      if cargo clippy --all-features --manifest-path "$FORGE_ROOT/$backend_path/Cargo.toml" -- -D warnings 2>/dev/null; then
        pass_scoped backend "cargo clippy: zero warnings"
      else
        fail_scoped backend "cargo clippy: warnings found"
      fi
      if cargo fmt --all --manifest-path "$FORGE_ROOT/$backend_path/Cargo.toml" --check 2>/dev/null; then
        pass_scoped backend "cargo fmt: formatted"
      else
        fail_scoped backend "cargo fmt: unformatted files"
      fi
      if cargo test --all-features --manifest-path "$FORGE_ROOT/$backend_path/Cargo.toml" 2>/dev/null; then
        pass_scoped backend "cargo test: all pass"
      else
        fail_scoped backend "cargo test: failures"
      fi
      # Domain purity scoped.
      domain_src="$FORGE_ROOT/$backend_path/crates/domain/src"
      if [ -d "$domain_src" ]; then
        infra_imports=$(grep -rn 'sqlx\|reqwest\|hyper\|tonic' "$domain_src" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$infra_imports" = "0" ]; then
          pass_scoped backend "domain purity: no infra imports in crates/domain/src/"
        else
          fail_scoped backend "domain purity: $infra_imports infra imports in crates/domain/src/"
        fi
      fi
      # No unwrap / panic in production.
      unwrap_count=$(grep -rn '\.unwrap()' "$FORGE_ROOT/$backend_path"/*/src/ 2>/dev/null | grep -v '#\[cfg(test)\]' | grep -v '// SAFETY:' | wc -l | tr -d ' ')
      if [ "$unwrap_count" = "0" ]; then
        pass_scoped backend "no unwrap() in production code"
      else
        fail_scoped backend "$unwrap_count unwrap() calls in production"
      fi
    else
      warn_scoped backend "cargo not found — skipping"
    fi
  fi

  # ── Frontend (scoped) — FR-FE-002 ──
  if [ -n "$frontend_path" ] && [ -f "$FORGE_ROOT/$frontend_path/pubspec.yaml" ]; then
    section "Frontend (scoped)"
    if command -v flutter &>/dev/null; then
      if flutter analyze --fatal-infos "$FORGE_ROOT/$frontend_path" 2>/dev/null; then
        pass_scoped frontend "flutter analyze: zero issues"
      else
        fail_scoped frontend "flutter analyze: issues found"
      fi
      if dart format --output=none --set-exit-if-changed "$FORGE_ROOT/$frontend_path/lib" 2>/dev/null; then
        pass_scoped frontend "dart format: formatted"
      else
        fail_scoped frontend "dart format: unformatted files"
      fi
      if flutter test --coverage "$FORGE_ROOT/$frontend_path" 2>/dev/null; then
        pass_scoped frontend "flutter test: all pass"
      else
        fail_scoped frontend "flutter test: failures"
      fi
      # Layer boundary.
      domain_flutter=$(grep -rl "import 'package:flutter" "$FORGE_ROOT/$frontend_path/lib/features"/*/domain/ 2>/dev/null | wc -l | tr -d ' ')
      if [ "$domain_flutter" = "0" ]; then
        pass_scoped frontend "layer boundary: zero Flutter imports in features/*/domain/"
      else
        fail_scoped frontend "layer boundary: $domain_flutter files import Flutter"
      fi
    else
      warn_scoped frontend "flutter not found — skipping"
    fi
  fi

  # ── Protos (scoped) — FR-GL-021 ──
  protos_dir="$FORGE_ROOT/shared/protos"
  if [ -d "$protos_dir" ]; then
    section "Protos (scoped)"
    if command -v buf &>/dev/null; then
      if (cd "$protos_dir" && buf lint 2>/dev/null); then
        pass_scoped protos "buf lint: clean"
      else
        fail_scoped protos "buf lint: warnings or errors"
      fi
      # buf breaking — WARN on seed commit (main may not yet exist
      # with the scaffolded tree).
      if (cd "$protos_dir" && buf breaking --against '.git#branch=main' 2>/dev/null); then
        pass_scoped protos "buf breaking: no breaking changes vs main"
      else
        warn_scoped protos "buf breaking: skipped or non-fatal (seed commit?)"
      fi
    else
      warn_scoped protos "buf not found — skipping"
    fi
  fi

  # ── Infra (scoped) — FR-GL-021 ──
  compose_dev="$FORGE_ROOT/docker-compose.dev.yml"
  if [ -f "$compose_dev" ]; then
    section "Infra (scoped)"
    if command -v docker &>/dev/null && docker compose version &>/dev/null; then
      if docker compose -f "$compose_dev" config &>/dev/null; then
        pass_scoped infra "docker-compose.dev.yml: syntax OK"
      else
        fail_scoped infra "docker-compose.dev.yml: syntax error"
      fi
    else
      warn_scoped infra "docker compose not found — skipping compose validation"
    fi
    # Kong + kustomization yaml parse (python3).
    for kong_yml in "$FORGE_ROOT/infra/kong/"*.yml*; do
      [ -f "$kong_yml" ] || continue
      if python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$kong_yml" 2>/dev/null; then
        pass_scoped infra "$(basename "$kong_yml"): parses as YAML"
      else
        fail_scoped infra "$(basename "$kong_yml"): YAML parse error"
      fi
    done
    for kust_yml in "$FORGE_ROOT/infra/k8s"/**/kustomization.yaml; do
      [ -f "$kust_yml" ] || continue
      if python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$kust_yml" 2>/dev/null; then
        pass_scoped infra "kustomization.yaml: parses"
      else
        fail_scoped infra "kustomization.yaml: parse error"
      fi
    done
  fi
fi

# ─── Summary ───────────────────────────────────────────────────

section "Summary"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Warnings: $WARN"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "RESULT: FAIL ($FAIL failures)"
  exit 1
else
  echo ""
  echo "RESULT: PASS"
  exit 0
fi
