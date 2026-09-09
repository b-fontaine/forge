#!/usr/bin/env bash
# Forge Foundations Test Harness
# <!-- Audit: B.1 (b1-foundations) -->
#
# Tests the behavior of .forge/scripts/validate-foundations.sh against
# synthetic fixtures: a minimal Forge skeleton copied into a tempdir,
# optionally mutated (inject a malformed schema, remove a standard, etc.),
# then passed as FORGE_ROOT to the validator.
#
# Contract:
#   - Every test function starts with `test_` and is discovered by `main`.
#   - Each test function returns 0 on success, non-zero on failure; emits
#     a one-line summary "✓ <name>" or "✗ <name>: <reason>" to stdout.
#   - `main` aggregates results, exits 0 iff every test passes.
#
# Runtime target: < 2 seconds total on a standard dev machine (NFR-002).
#
# Usage:
#   bash .forge/scripts/tests/foundations.test.sh

set -euo pipefail

# ─── Paths ──────────────────────────────────────────────────────

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"
VALIDATOR="$SCRIPTS_DIR/validate-foundations.sh"

# ─── Shared helpers (assertions, run_test, counters) ────────────
# Extracted to _helpers.sh in b1-scaffolder; sourced for reuse.
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

# ─── Fixture helpers (foundations-specific) ─────────────────────

mk_fixture_root() {
  # mk_fixture_root — creates a tmpdir with a minimal Forge skeleton
  # (no foundations deliverables). Echoes the path. Caller must trap
  # cleanup via `trap "rm -rf '$root'" RETURN`.
  local root
  root="$(mktemp -d -t forge-foundations-fixture-XXXXXX)"
  mkdir -p "$root/.forge/scripts" \
           "$root/.forge/standards/global" \
           "$root/.forge/standards/infra" \
           "$root/.forge/changes" \
           "$root/docs"
  # Minimal index.yml so validator has something to diff against.
  cat > "$root/.forge/standards/index.yml" <<'YML'
standards:
  - name: tdd-rules
    path: global/tdd-rules.md
    scope: all
    priority: high
    triggers: [tdd, test-first]
YML
  # Minimal git-workflow.md for FR-GL-005 baseline (section absent).
  cat > "$root/.forge/standards/global/git-workflow.md" <<'MD'
# Git Workflow (baseline stub for tests)

## Conventional Commits
Standard Conventional Commits rules.
MD
  # Minimal docs/VERSIONING.md for FR-GL-006 baseline (section absent).
  cat > "$root/docs/VERSIONING.md" <<'MD'
# Versioning

## Release Artifacts
Stub.

## Who Bumps the Version
Stub.
MD
  echo "$root"
}

run_validator() {
  # run_validator <fixture_root> — invokes the real validator with
  # FORGE_ROOT pointing at the fixture. Captures stdout+stderr and
  # returns the validator's exit code (via $?).
  local root="$1"
  FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1
}

# ─── Tests: FR-GL-001 (schema full-stack-monorepo) ──────────────

test_schema_absent_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  # No schema file created.
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-001" "validator must FAIL when schema file missing"
  assert_contains "$out" "schema file missing"
}

test_schema_malformed_version_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  mkdir -p "$root/.forge/schemas/full-stack-monorepo"
  cat > "$root/.forge/schemas/full-stack-monorepo/schema.yaml" <<'YML'
name: full-stack-monorepo
version: draft
stage: draft
layers:
  - {id: backend, path: backend/, fr_id_prefix: FR-BE-, primary_agent: Vulcan}
  - {id: frontend, path: frontend/, fr_id_prefix: FR-FE-, primary_agent: Hera}
  - {id: infra, path: infra/, fr_id_prefix: FR-IN-, primary_agent: Atlas}
phases: [{id: proposal}]
YML
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-001"
  assert_contains "$out" "version does not match SemVer"
}

test_schema_missing_layers_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  mkdir -p "$root/.forge/schemas/full-stack-monorepo"
  cat > "$root/.forge/schemas/full-stack-monorepo/schema.yaml" <<'YML'
name: full-stack-monorepo
version: 0.1.0
stage: draft
phases: [{id: proposal}]
YML
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-001"
  assert_contains "$out" "layers missing or empty"
}

test_schema_layers_under_three_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  mkdir -p "$root/.forge/schemas/full-stack-monorepo"
  cat > "$root/.forge/schemas/full-stack-monorepo/schema.yaml" <<'YML'
name: full-stack-monorepo
version: 0.1.0
stage: draft
layers:
  - {id: backend, path: backend/, fr_id_prefix: FR-BE-, primary_agent: Vulcan}
phases: [{id: proposal}]
YML
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-001"
  assert_contains "$out" "must include at least backend, frontend, infra"
}

test_schema_stage_stable_but_prerelease_version_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  mkdir -p "$root/.forge/schemas/full-stack-monorepo"
  cat > "$root/.forge/schemas/full-stack-monorepo/schema.yaml" <<'YML'
name: full-stack-monorepo
version: 0.5.0
stage: stable
layers:
  - {id: backend, path: backend/, fr_id_prefix: FR-BE-, primary_agent: Vulcan}
  - {id: frontend, path: frontend/, fr_id_prefix: FR-FE-, primary_agent: Hera}
  - {id: infra, path: infra/, fr_id_prefix: FR-IN-, primary_agent: Atlas}
phases: [{id: proposal}]
YML
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-001"
  assert_contains "$out" "stage=stable requires version >= 1.0.0"
}

# ─── Tests: FR-GL-002 (monorepo-layout standard) ────────────────

test_standard_monorepo_layout_absent_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  # Fixture has no monorepo-layout.md.
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-002" "validator must FAIL when file missing"
}

test_standard_monorepo_layout_missing_sections_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  printf '# Monorepo Layout\n\nStub without required sections.\n' \
    > "$root/.forge/standards/global/monorepo-layout.md"
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-002" "validator must FAIL on sections missing"
  assert_contains "$out" "missing sections"
}

# ─── Tests: FR-GL-003 (proto-contracts standard) ────────────────

test_standard_proto_contracts_absent_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-003" "validator must FAIL when file missing"
}

test_standard_proto_contracts_missing_sections_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  printf '# Proto Contracts\n\nStub.\n' \
    > "$root/.forge/standards/global/proto-contracts.md"
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-003" "validator must FAIL on sections missing"
  assert_contains "$out" "missing sections"
}

# ─── Tests: FR-GL-004 (docker-compose standard) ─────────────────

test_standard_docker_compose_absent_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-004" "validator must FAIL when file missing"
}

test_standard_docker_compose_missing_sections_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  printf '# Docker Compose\n\nStub.\n' \
    > "$root/.forge/standards/infra/docker-compose.md"
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-004" "validator must FAIL on sections missing"
  assert_contains "$out" "missing sections"
}

# ─── Tests: FR-GL-005 (git-workflow scoped commits) ─────────────

test_git_workflow_missing_scoped_section_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  # Baseline git-workflow.md in fixture has no scoped section.
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-005"
  assert_contains "$out" "section 'Scoped Conventional Commits (monorepo-only)' missing"
}

test_git_workflow_scope_list_not_closed_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  # Section header exists but no closed scope list.
  cat >> "$root/.forge/standards/global/git-workflow.md" <<'MD'

## Scoped Conventional Commits (monorepo-only)

Free-form scopes allowed — no closed list here.
MD
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-005"
  assert_contains "$out" "closed scope list"
}

# ─── Tests: FR-GL-006 (VERSIONING monorepo models) ──────────────

test_versioning_missing_monorepo_section_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  # Baseline docs/VERSIONING.md in fixture has no monorepo section.
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-006"
  assert_contains "$out" "section 'Monorepo Versioning Models' missing"
}

test_versioning_missing_submodels_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  # Section heading present but no Release-train / Per-package subsections.
  cat >> "$root/docs/VERSIONING.md" <<'MD'

## Monorepo Versioning Models

Stub without subsections.
MD
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-006"
  assert_contains "$out" "subsection"
}

# ─── Tests: FR-GL-007 (index.yml new entries) ───────────────────

test_index_missing_three_entries_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  # Baseline fixture only has tdd-rules — the 3 new entries are absent.
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-007"
  assert_contains "$out" "missing index entries"
}

test_index_wrong_scope_fails() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  # Add the three entries but with a wrong scope on monorepo-layout.
  cat >> "$root/.forge/standards/index.yml" <<'YML'
  - id: global/monorepo-layout
    path: standards/global/monorepo-layout.md
    scope: flutter
    priority: high
    triggers: [monorepo, full-stack, layers]
  - id: global/proto-contracts
    path: standards/global/proto-contracts.md
    scope: protos
    priority: high
    triggers: [proto, buf, grpc]
  - id: infra/docker-compose
    path: standards/infra/docker-compose.md
    scope: infra
    priority: medium
    triggers: [docker-compose, local-dev, compose]
YML
  local out; out=$(run_validator "$root" || true)
  assert_contains "$out" "FAIL: FR-GL-007"
  assert_contains "$out" "scope mismatch"
}

# ─── Fixture populator for GREEN-state tests ────────────────────

populate_fixture_with_deliverables() {
  # populate_fixture_with_deliverables <fixture_root>
  # Copies all 7 b1-foundations deliverables from the real repo into
  # the fixture so the validator sees a fully-GREEN state.
  local root="$1"
  local real_root
  real_root="$(cd "$SCRIPTS_DIR/../.." && pwd)"

  mkdir -p "$root/.forge/schemas/full-stack-monorepo"
  cp "$real_root/.forge/schemas/full-stack-monorepo/schema.yaml" \
     "$root/.forge/schemas/full-stack-monorepo/schema.yaml"

  cp "$real_root/.forge/standards/global/monorepo-layout.md" \
     "$root/.forge/standards/global/monorepo-layout.md"
  cp "$real_root/.forge/standards/global/proto-contracts.md" \
     "$root/.forge/standards/global/proto-contracts.md"
  cp "$real_root/.forge/standards/infra/docker-compose.md" \
     "$root/.forge/standards/infra/docker-compose.md"
  # b1-workflow addition: FR-GL-018 (multi-layer-workflow standard)
  # is checked by validate-foundations.sh. The foundations GREEN
  # fixture must therefore also carry it, otherwise the validator
  # exits 1 and `test_green_state_passes_for_all_7` regresses.
  if [ -f "$real_root/.forge/standards/global/multi-layer-workflow.md" ]; then
    cp "$real_root/.forge/standards/global/multi-layer-workflow.md" \
       "$root/.forge/standards/global/multi-layer-workflow.md"
  fi

  # These three are MODIFICATIONS of files that exist in the baseline
  # fixture — overwrite the baseline with the real enriched version.
  cp "$real_root/.forge/standards/global/git-workflow.md" \
     "$root/.forge/standards/global/git-workflow.md"
  cp "$real_root/docs/VERSIONING.md" "$root/docs/VERSIONING.md"
  cp "$real_root/.forge/standards/index.yml" \
     "$root/.forge/standards/index.yml"
}

# ─── Phase 3.2: meta-tests RED / GREEN across all 7 FRs ─────────

test_red_state_fails_for_all_7() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  # Baseline fixture has NONE of the 7 deliverables.
  local out; out=$(run_validator "$root" || true)
  local fail_count
  fail_count=$(printf '%s\n' "$out" | grep -c '^FAIL: FR-GL-00[1-7]' || true)
  if [ "$fail_count" -ne 7 ]; then
    echo "    expected 7 FAIL lines for FR-GL-001..007, got $fail_count" >&2
    echo "    output preview:" >&2
    printf '%s\n' "$out" | head -10 >&2
    return 1
  fi
}

test_green_state_passes_for_all_7() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  populate_fixture_with_deliverables "$root"
  local out; out=$(run_validator "$root" || true)
  local pass_count
  pass_count=$(printf '%s\n' "$out" | grep -c '^PASS: FR-GL-00[1-7]' || true)
  if [ "$pass_count" -ne 7 ]; then
    echo "    expected 7 PASS lines for FR-GL-001..007, got $pass_count" >&2
    echo "    output:" >&2
    printf '%s\n' "$out" | head -10 >&2
    return 1
  fi
  # Also assert exit 0 by re-running in a way we can capture the code.
  if ! FORGE_ROOT="$root" bash "$VALIDATOR" >/dev/null 2>&1; then
    echo "    validator exit code != 0 on fully-populated fixture" >&2
    return 1
  fi
}

# Regression (FR-GL-017): a change whose .forge.yaml `layers:` uses the
# live {id, path} mapping shape (not bare id strings) must be inspected
# WITHOUT crashing. Before the dict->id normalisation, `l not in known_ids`
# hashed a dict -> TypeError: unhashable type, which (under set -e) aborted
# the script mid-run and silently killed FR-GL-017 on the live tree
# (verify.sh masked it by grepping PASS/FAIL lines, not the exit code).
test_dict_shaped_layers_do_not_crash_fr_gl_017() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  populate_fixture_with_deliverables "$root"
  local cdir="$root/.forge/changes/regress-dict-layers"
  mkdir -p "$cdir"
  echo stub > "$cdir/design-backend.md"
  echo stub > "$cdir/design-frontend.md"
  echo stub > "$cdir/tasks-backend.md"
  echo stub > "$cdir/tasks-frontend.md"
  cat > "$cdir/.forge.yaml" <<'YML'
name: regress-dict-layers
status: archived
layers:
  - id: backend
    path: backend/
  - id: frontend
    path: frontend/
designs_per_layer:
  backend: design-backend.md
  frontend: design-frontend.md
tasks_per_layer:
  backend: tasks-backend.md
  frontend: tasks-frontend.md
YML
  local out; out=$(run_validator "$root" || true)
  if printf '%s' "$out" | grep -qiE 'Traceback|unhashable'; then
    echo "    validator crashed on dict-shaped layers (FR-GL-017 regression)" >&2
    printf '%s\n' "$out" | grep -iE 'Traceback|unhashable|Error' >&2
    return 1
  fi
  assert_contains "$out" "PASS: FR-GL-017" "FR-GL-017 must inspect dict-shaped-layer changes and pass"
  if ! FORGE_ROOT="$root" bash "$VALIDATOR" > /dev/null 2>&1; then
    echo "    validator exit != 0 with a dict-shaped-layers change present" >&2
    return 1
  fi
}

# ─── Phase 3.3: NFR-001 idempotence, NFR-002 performance ────────

test_idempotence() {
  local root; root=$(mk_fixture_root); trap "rm -rf '$root'" RETURN
  populate_fixture_with_deliverables "$root"
  local out1 out2
  out1=$(run_validator "$root" || true)
  out2=$(run_validator "$root" || true)
  assert_eq "$out1" "$out2" "validator output must be byte-identical across runs"
}

test_performance_under_two_seconds() {
  # NFR-002 target: < 2.0s on a standard dev machine. We run the
  # validator on the REAL repo (fully populated) and check wall-clock.
  local real_root
  real_root="$(cd "$SCRIPTS_DIR/../.." && pwd)"
  local start_ns end_ns elapsed_ms
  start_ns=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1e9))')
  FORGE_ROOT="$real_root" bash "$VALIDATOR" >/dev/null 2>&1 || true
  end_ns=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1e9))')
  elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
  echo "    elapsed: ${elapsed_ms}ms (NFR-002 budget: 2000ms)"
  # Ceiling at 2000ms per NFR-002. Fail hard above 5000ms (sanity).
  if [ "$elapsed_ms" -gt 5000 ]; then
    echo "    FAIL: ${elapsed_ms}ms > 5000ms (hard ceiling)" >&2
    return 1
  fi
  if [ "$elapsed_ms" -gt 2000 ]; then
    echo "    WARN: ${elapsed_ms}ms > NFR-002 target 2000ms" >&2
  fi
}

# ─── Main runner ────────────────────────────────────────────────

# ─── Shared-helper integrity (t5-helpers-sigpipe) ────────────────────────────
#
# _helpers.sh is sourced by every harness in this directory: 11 of them call
# assert_contains / assert_not_contains across 122 sites. A defect there is a defect
# everywhere, which is why the guards live in the foundations harness rather than
# beside any one consumer.

# FR-T5HSP-003 — static: the helper must not pipe a haystack into an early-exiting
# reader. Under `set -o pipefail` (which every harness sets) the reader closes the
# pipe on match, the writer takes SIGPIPE, and the pipeline yields 141 — so the
# assertion reports the OPPOSITE of the truth. This pattern reads as ordinary shell
# and will come back without a guard.
test_helpers_no_pipe_into_early_exiting_reader() {
  local helpers
  helpers="$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"
  [ -f "$helpers" ] || { echo "    _helpers.sh missing: $helpers" >&2; return 1; }
  local hits
  hits=$(grep -nE '\|[[:space:]]*(grep|head|tail|sed)[[:space:]]' "$helpers" | grep -v '^[[:space:]]*#' || true)
  if [ -n "$hits" ]; then
    echo "    _helpers.sh pipes into an early-exiting reader (FR-T5HSP-001/002):" >&2
    printf '%s\n' "$hits" | head -5 | sed 's/^/      /' >&2
    echo "      use a here-string: grep -Fq -- \"\$needle\" <<<\"\$haystack\"" >&2
    return 1
  fi
}

# FR-T5HSP-004 — behavioural: the static guard proves the code changed, not that the
# race is gone. This exercises the real helper against a haystack shaped like the one
# that failed in production — an EARLY match in a multi-kilobyte string, which
# maximises the bytes still unwritten when the reader exits.
#
# The real case: `postgres:16-alpine` at offset 1735 of a 23723-byte haystack, in
# b8-1.test.sh::_test_b81_l1_002_component_matrix. Measured 57 failures / 500 with
# the piped form, 0 / 500 with the here-string.
test_helpers_assert_contains_is_deterministic() {
  local needle="EARLY-MATCH-SENTINEL"
  local haystack; haystack="$needle"$'\n'
  local i
  for i in $(seq 1 600); do haystack+="filler line $i — padding so the reader exits with bytes left unwritten"$'\n'; done
  # ~40 KB, sentinel at offset 0: the worst case for the race.

  local fails=0
  for i in $(seq 1 300); do
    assert_contains "$haystack" "$needle" "determinism probe" >/dev/null 2>&1 || fails=$((fails+1))
  done
  if [ "$fails" -gt 0 ]; then
    echo "    assert_contains failed $fails/300 times on a needle that IS present" >&2
    echo "    — SIGPIPE under pipefail (FR-T5HSP-004). haystack=${#haystack} bytes" >&2
    return 1
  fi

  # Positive control: the probe must be capable of failing at all. A needle that is
  # genuinely absent has to return non-zero, or the loop above proves nothing.
  if assert_contains "$haystack" "THIS-NEEDLE-IS-NOT-PRESENT-ANYWHERE" "control" >/dev/null 2>&1; then
    echo "    control failed: assert_contains returned 0 for an absent needle" >&2
    return 1
  fi
  # ... and the negative helper must still detect a present needle.
  if assert_not_contains "$haystack" "$needle" "control" >/dev/null 2>&1; then
    echo "    control failed: assert_not_contains returned 0 for a PRESENT needle" >&2
    return 1
  fi
}

# FR-T5PFS-004 — the ONE shape that is always wrong, not merely risky.
#
# `find <tree> | grep -q .` under `set -o pipefail` was measured at 200 failures per
# 200 on a 4000-file tree: find is still traversing when grep exits on the first
# line, takes SIGPIPE, and the pipeline yields 141. So `if find … | grep -q .` never
# takes its true branch, and `find … | grep -q . || fail` always fails. Both are a
# permanently wrong answer, not a flake.
#
# Deliberately NOT a guard against every `| grep -q`: 176 such sites remain by
# design (t5-pipefail-sweep ADR-T5PFS-002), and a guard that flags them would be
# noise and get disabled. This one states a measured fact.
test_no_find_piped_into_grep_q() {
  local dir; dir="$(dirname "${BASH_SOURCE[0]}")/.."
  local hits
  hits=$(grep -rnE '(find|grep[[:space:]]+-r)[^|]*\|[[:space:]]*grep[[:space:]]+-[A-Za-z]*q' \
         "$dir" --include='*.sh' 2>/dev/null | grep -vE ':[0-9]+:[[:space:]]*#' || true)
  if [ -n "$hits" ]; then
    echo "    a find/grep -r is piped into grep -q — that branch can never be taken" >&2
    echo "    (measured 200/200 failures on a large tree; use: grep -q . < <(find …))" >&2
    printf '%s\n' "$hits" | head -5 | sed 's/^/      /' >&2
    return 1
  fi
}

main() {
  echo "── Forge Foundations Test Harness ──"
  echo "  VALIDATOR=$VALIDATOR"
  echo ""

  run_test test_schema_absent_fails
  run_test test_schema_malformed_version_fails
  run_test test_schema_missing_layers_fails
  run_test test_schema_layers_under_three_fails
  run_test test_schema_stage_stable_but_prerelease_version_fails
  run_test test_standard_monorepo_layout_absent_fails
  run_test test_standard_monorepo_layout_missing_sections_fails
  run_test test_standard_proto_contracts_absent_fails
  run_test test_standard_proto_contracts_missing_sections_fails
  run_test test_standard_docker_compose_absent_fails
  run_test test_standard_docker_compose_missing_sections_fails
  run_test test_git_workflow_missing_scoped_section_fails
  run_test test_git_workflow_scope_list_not_closed_fails
  run_test test_versioning_missing_monorepo_section_fails
  run_test test_versioning_missing_submodels_fails
  run_test test_index_missing_three_entries_fails
  run_test test_index_wrong_scope_fails
  run_test test_red_state_fails_for_all_7
  run_test test_green_state_passes_for_all_7
  run_test test_dict_shaped_layers_do_not_crash_fr_gl_017
  run_test test_idempotence
  run_test test_performance_under_two_seconds
  run_test test_helpers_no_pipe_into_early_exiting_reader
  run_test test_helpers_assert_contains_is_deterministic
  run_test test_no_find_piped_into_grep_q

  print_summary
}

main "$@"
