#!/usr/bin/env bash
# Forge — G.1 CI Test Harness (g1-forge-ci)
# <!-- Audit: G.1 (g1-forge-ci) -->
#
# Validates the contract surface of Forge's own CI workflow at
# `.github/workflows/forge-ci.yml`, the `cli/.nvmrc` Node pin, the
# `global/forge-self-ci.md` standard, and the branch-protection
# section in `docs/CONTRIBUTING.md`. Mirrors the manifest pattern
# established by `delivery.test.sh` (FR-GL-025 of b1-delivery).
#
# This harness is L1 only — purely structural YAML / file
# inspection. Runtime behaviour of the workflow is validated by
# the workflow itself when GitHub Actions runs it.
#
# Usage :
#   bash .forge/scripts/tests/g1.test.sh

set -euo pipefail

# ─── Paths ──────────────────────────────────────────────────────

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

WORKFLOW_FILE="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
NVMRC="$FORGE_ROOT_REAL/cli/.nvmrc"
STD_SELF_CI="$FORGE_ROOT_REAL/.forge/standards/global/forge-self-ci.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
CONTRIBUTING="$FORGE_ROOT_REAL/docs/CONTRIBUTING.md"

# ─── Shared helpers ─────────────────────────────────────────────
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

# ─── Manifest — single source of truth for FR ↔ test mapping ────
#
# Every line of the form `# MANIFEST: test_* — FR-CI-XXX`
# below is parsed by `test_g1_manifest_self_consistency` to assert
# that every entry resolves to a defined bash function.
#
# MANIFEST: test_forge_ci_workflow_shape                          — FR-CI-001
# MANIFEST: test_forge_ci_harness_job_invokes_four_harnesses      — FR-CI-002
# MANIFEST: test_forge_ci_gates_job_invokes_both_scripts          — FR-CI-003
# MANIFEST: test_forge_ci_cli_job_runs_npm_pipeline               — FR-CI-004
# MANIFEST: test_forge_ci_lint_job_invokes_shellcheck_on_target_dirs — FR-CI-005
# MANIFEST: test_forge_ci_summary_job_aggregates_needs            — FR-CI-006
# MANIFEST: test_forge_ci_concurrency_policy                      — FR-CI-007
# MANIFEST: test_forge_ci_nvmrc_present_and_pinned                — FR-CI-008
# MANIFEST: test_forge_ci_no_unpinned_uses                        — FR-CI-009
# MANIFEST: test_standard_forge_self_ci_has_required_sections    — ADR-003
# MANIFEST: test_index_has_forge_self_ci_entry                    — ADR-003
# MANIFEST: test_contributing_documents_branch_protection         — FR-CI-011
# MANIFEST: test_forge_ci_under_size_budget                       — NFR-CI-002
# MANIFEST: test_g1_manifest_self_consistency                     — meta (FR-CI-010)
#
# ────────────────────────────────────────────────────────────────

# ─── Workflow YAML helper ───────────────────────────────────────

# parse_workflow_yaml — emits a Python YAML inspector that loads the
# workflow file ; callers extend the script with their own assertions
# via stdin. Reduces boilerplate.
parse_workflow_yaml_assertions() {
  python3 - "$WORKFLOW_FILE" "$@"
}

# ─── Phase 2 : workflow shape & jobs ───────────────────────────

test_forge_ci_workflow_shape() {
  if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "    workflow file missing: $WORKFLOW_FILE" >&2; return 1
  fi
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml, re
text = open(sys.argv[1]).read()
doc = yaml.safe_load(text)
if doc is None:
    print("    yaml empty", file=sys.stderr); sys.exit(1)
errors = []

# Triggers : pull_request branches:[main] AND push branches:[main], no others
on = doc.get("on", doc.get(True, None))
if not isinstance(on, dict):
    errors.append(f"`on:` not a mapping: {type(on).__name__}")
else:
    if set(on.keys()) != {"pull_request", "push"}:
        errors.append(f"`on:` keys must be exactly {{pull_request, push}}; got {sorted(on.keys())}")
    for k in ("pull_request", "push"):
        if k in on:
            entry = on[k] or {}
            branches = entry.get("branches") if isinstance(entry, dict) else None
            if branches != ["main"]:
                errors.append(f"`on.{k}.branches` must be ['main']; got {branches!r}")

# Permissions: top-level contents: read only
perms = doc.get("permissions")
if perms != {"contents": "read"}:
    errors.append(f"top-level permissions must be {{contents: read}}; got {perms!r}")

# Exactly 6 jobs with the expected names. The 'example' job was
# added by c1-reference-project (FR-CI-012) ; the original 5-job
# shape from g1-forge-ci was MODIFIED in c1's specs.md.
jobs = doc.get("jobs") or {}
expected_jobs = {"harness", "gates", "cli", "lint", "example", "summary"}
if set(jobs.keys()) != expected_jobs:
    errors.append(f"jobs must be exactly {sorted(expected_jobs)}; got {sorted(jobs.keys())}")

# Every job runs on ubuntu-latest
for name, job in jobs.items():
    if not isinstance(job, dict):
        errors.append(f"jobs.{name} not a mapping")
        continue
    if job.get("runs-on") != "ubuntu-latest":
        errors.append(f"jobs.{name}.runs-on must be 'ubuntu-latest'; got {job.get('runs-on')!r}")

# No continue-on-error: true anywhere
if re.search(r"continue-on-error\s*:\s*true\b", text):
    errors.append("forbidden `continue-on-error: true`")

for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_forge_ci_harness_job_invokes_four_harnesses() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
errors = []
job = (doc.get("jobs") or {}).get("harness") or {}
runs = []
for s in job.get("steps") or []:
    if isinstance(s, dict) and s.get("run"):
        runs.append(s["run"])
joined = "\n".join(runs)
for needle in [
    "bash .forge/scripts/tests/foundations.test.sh",
    "bash .forge/scripts/tests/scaffolder.test.sh --level 1,2",
    "bash .forge/scripts/tests/workflow.test.sh --level 1,2",
    "bash .forge/scripts/tests/delivery.test.sh",
]:
    if needle not in joined:
        errors.append(f"harness job missing invocation: `{needle}`")
# pyyaml install via setup-python + pip
uses = [s.get("uses") for s in (job.get("steps") or []) if isinstance(s, dict)]
if not any(u and u.startswith("actions/setup-python@") for u in uses):
    errors.append("harness job missing actions/setup-python@v5 step")
if "pyyaml" not in joined.lower():
    errors.append("harness job missing `pip install pyyaml` step")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_forge_ci_gates_job_invokes_both_scripts() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
errors = []
job = (doc.get("jobs") or {}).get("gates") or {}
runs = "\n".join(s.get("run", "") for s in (job.get("steps") or []) if isinstance(s, dict))
verify_pos = runs.find("bash .forge/scripts/verify.sh")
linter_pos = runs.find("bash .forge/scripts/constitution-linter.sh")
if verify_pos < 0:
    errors.append("gates job missing `bash .forge/scripts/verify.sh`")
if linter_pos < 0:
    errors.append("gates job missing `bash .forge/scripts/constitution-linter.sh`")
if verify_pos >= 0 and linter_pos >= 0 and verify_pos > linter_pos:
    errors.append("gates job runs constitution-linter.sh BEFORE verify.sh; ordering wrong")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_forge_ci_cli_job_runs_npm_pipeline() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
errors = []
job = (doc.get("jobs") or {}).get("cli") or {}
defaults = job.get("defaults") or {}
runs_dir = (defaults.get("run") or {}).get("working-directory")
if runs_dir != "cli":
    errors.append(f"cli job defaults.run.working-directory must be 'cli'; got {runs_dir!r}")
steps = job.get("steps") or []
# setup-node@v4 with .nvmrc + cache: 'npm'
node_step = None
for s in steps:
    if isinstance(s, dict) and (s.get("uses") or "").startswith("actions/setup-node@"):
        node_step = s; break
if not node_step:
    errors.append("cli job missing actions/setup-node@v4 step")
else:
    w = node_step.get("with") or {}
    if w.get("node-version-file") != "cli/.nvmrc":
        errors.append(f"setup-node node-version-file must be 'cli/.nvmrc'; got {w.get('node-version-file')!r}")
    if w.get("cache") != "npm":
        errors.append(f"setup-node cache must be 'npm'; got {w.get('cache')!r}")
    if w.get("cache-dependency-path") != "cli/package-lock.json":
        errors.append(f"setup-node cache-dependency-path must be 'cli/package-lock.json'; got {w.get('cache-dependency-path')!r}")
# Run sequence: npm ci → npm run lint → npm run bundle → npm test.
# Bundle MUST run before test because the e2e suite (test/e2e/cli.test.ts)
# spawns the built CLI from cli/dist/index.js — without a fresh bundle
# the e2e tests fail with ERR_MODULE_NOT_FOUND. (v0.3.0 fix-up.)
runs = "\n".join(s.get("run", "") for s in steps if isinstance(s, dict))
expected = ["npm ci", "npm run lint", "npm run bundle", "npm test"]
positions = [(n, runs.find(n)) for n in expected]
for n, p in positions:
    if p < 0:
        errors.append(f"cli job missing `{n}`")
present = [p for n, p in positions if p >= 0]
if len(present) >= 2 and present != sorted(present):
    errors.append(f"cli job step ordering wrong: {positions}")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_forge_ci_lint_job_invokes_shellcheck_on_target_dirs() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml, re
doc = yaml.safe_load(open(sys.argv[1]))
errors = []
job = (doc.get("jobs") or {}).get("lint") or {}
shellcheck_steps = []
for s in job.get("steps") or []:
    if isinstance(s, dict) and "ludeeus/action-shellcheck" in (s.get("uses") or ""):
        shellcheck_steps.append(s)
if len(shellcheck_steps) < 2:
    errors.append(f"lint job must invoke ludeeus/action-shellcheck twice (one per scandir); got {len(shellcheck_steps)}")
# Pinning : MUST NOT use @master/@main
for s in shellcheck_steps:
    uses = s.get("uses") or ""
    if not re.search(r"@[v0-9]", uses):
        errors.append(f"shellcheck step uses unpinned: {uses!r}")
# Two distinct scandirs
scandirs = [(s.get("with") or {}).get("scandir") for s in shellcheck_steps]
if not any(sd and "scripts" in sd for sd in scandirs):
    errors.append(f"no scandir targeting `.forge/scripts`; got {scandirs}")
if not any(sd and "bin" in sd for sd in scandirs):
    errors.append(f"no scandir targeting `bin`; got {scandirs}")
# severity warning
for s in shellcheck_steps:
    sev = (s.get("with") or {}).get("severity")
    if sev not in ("warning", "error"):
        errors.append(f"shellcheck step severity must be 'warning' or stricter; got {sev!r}")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_forge_ci_summary_job_aggregates_needs() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
errors = []
job = (doc.get("jobs") or {}).get("summary") or {}
needs = job.get("needs") or []
if isinstance(needs, str): needs = [needs]
expected = {"harness", "gates", "cli", "lint", "example"}
if set(needs) != expected:
    errors.append(f"summary.needs must be {sorted(expected)}; got {sorted(needs)}")
# Summary always runs (no `if:` short-circuit on a non-failure condition)
if "if" in job:
    cond = str(job["if"])
    # Only allow `always()` or absence
    if "always" not in cond.lower():
        errors.append(f"summary job MUST always run (no conditional skip); got `if: {cond}`")
# First step references needs.<job>.result either directly in run:
# or via an env: indirection (the safer pattern that avoids mixing
# ${{ }} expressions with bash heredocs).
steps = job.get("steps") or []
combined_text = ""
for s in steps:
    if not isinstance(s, dict): continue
    combined_text += "\n" + (s.get("run") or "")
    env = s.get("env") or {}
    if isinstance(env, dict):
        for v in env.values():
            combined_text += "\n" + str(v)
for j in ("harness", "gates", "cli", "lint", "example"):
    if f"needs.{j}.result" not in combined_text:
        errors.append(f"summary script doesn't read `needs.{j}.result`")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_forge_ci_concurrency_policy() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml, re
text = open(sys.argv[1]).read()
doc = yaml.safe_load(text)
errors = []
conc = doc.get("concurrency")
if not isinstance(conc, dict):
    errors.append(f"top-level `concurrency:` not a mapping; got {conc!r}");
else:
    grp = str(conc.get("group", ""))
    if "forge-ci-" not in grp or "github.ref" not in grp:
        errors.append(f"concurrency.group must reference 'forge-ci-' and github.ref; got {grp!r}")
    cancel = conc.get("cancel-in-progress")
    cancel_str = str(cancel)
    if "github.event_name" not in cancel_str or "pull_request" not in cancel_str:
        errors.append(f"cancel-in-progress must be a conditional on github.event_name == 'pull_request'; got {cancel_str!r}")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_forge_ci_no_unpinned_uses() {
  if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "    workflow file missing: $WORKFLOW_FILE" >&2; return 1
  fi
  # Every `uses:` must have @<version> ; no @main, @master, @HEAD ; no :latest
  if grep -E 'uses:\s*[^@[:space:]]+@(main|master|HEAD)\b' "$WORKFLOW_FILE"; then
    echo "    forbidden unpinned @main/@master/@HEAD reference" >&2; return 1
  fi
  if grep -E ':latest\b' "$WORKFLOW_FILE" >/dev/null; then
    echo "    forbidden :latest tag" >&2; return 1
  fi
  # All `uses:` have @
  if grep -E '^\s*uses:\s*[^@[:space:]]+\s*$' "$WORKFLOW_FILE"; then
    echo "    `uses:` reference missing @<ref>" >&2; return 1
  fi
}

test_forge_ci_under_size_budget() {
  if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "    workflow file missing" >&2; return 1
  fi
  local lines; lines=$(wc -l < "$WORKFLOW_FILE")
  if [ "$lines" -gt 250 ]; then
    echo "    workflow $lines lines > 250 (NFR-CI-002)" >&2; return 1
  fi
}

# ─── Phase 3 : supporting files ────────────────────────────────

test_forge_ci_nvmrc_present_and_pinned() {
  if [ ! -f "$NVMRC" ]; then
    echo "    cli/.nvmrc missing" >&2; return 1
  fi
  local content; content=$(tr -d '[:space:]' < "$NVMRC")
  if ! echo "$content" | grep -qE '^20\.[0-9]+\.[0-9]+$'; then
    echo "    cli/.nvmrc must match ^20\\.[0-9]+\\.[0-9]+$ ; got '$content'" >&2; return 1
  fi
}

test_standard_forge_self_ci_has_required_sections() {
  if [ ! -f "$STD_SELF_CI" ]; then
    echo "    standard missing: $STD_SELF_CI" >&2; return 1
  fi
  local missing=()
  for h in "Workflow shape" "What's intentionally different from infra/ci-workflows.md" "Branch protection"; do
    if ! grep -qE "^## ${h}$" "$STD_SELF_CI"; then
      missing+=("$h")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    forge-self-ci.md missing sections: ${missing[*]}" >&2; return 1
  fi
}

test_index_has_forge_self_ci_entry() {
  python3 - "$INDEX_YML" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
ids = {s.get("id") for s in (doc or {}).get("standards", [])}
if "global/forge-self-ci" not in ids:
    print("    missing index entry: global/forge-self-ci", file=sys.stderr)
    sys.exit(1)
PY
}

test_contributing_documents_branch_protection() {
  if [ ! -f "$CONTRIBUTING" ]; then
    echo "    docs/CONTRIBUTING.md missing" >&2; return 1
  fi
  if ! grep -qE "^## (Continuous Integration|CI|Branch protection)" "$CONTRIBUTING"; then
    echo "    CONTRIBUTING.md missing CI/branch-protection H2 section" >&2; return 1
  fi
  if ! grep -q "forge-ci / summary" "$CONTRIBUTING"; then
    echo "    CONTRIBUTING.md doesn't mention required status 'forge-ci / summary'" >&2; return 1
  fi
  if ! grep -qiE "Settings.*Branches|GitHub UI" "$CONTRIBUTING"; then
    echo "    CONTRIBUTING.md doesn't name the GitHub UI configuration path" >&2; return 1
  fi
}

test_g1_manifest_self_consistency() {
  local missing=()
  while IFS= read -r fn; do
    if ! declare -F "$fn" >/dev/null 2>&1; then
      missing+=("$fn")
    fi
  done < <(grep -oE '^# MANIFEST: test_[a-z0-9_]+' "${BASH_SOURCE[0]}" | awk '{print $3}')
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    manifest declares functions not defined: ${missing[*]}" >&2
    return 1
  fi
}

# ─── Main dispatcher ────────────────────────────────────────────

main() {
  echo "── Forge G.1 CI Test Harness ──"
  echo "  WORKFLOW_FILE=$WORKFLOW_FILE"
  echo ""

  echo "── L1 : structural invariants ──"
  run_test test_forge_ci_workflow_shape
  run_test test_forge_ci_harness_job_invokes_four_harnesses
  run_test test_forge_ci_gates_job_invokes_both_scripts
  run_test test_forge_ci_cli_job_runs_npm_pipeline
  run_test test_forge_ci_lint_job_invokes_shellcheck_on_target_dirs
  run_test test_forge_ci_summary_job_aggregates_needs
  run_test test_forge_ci_concurrency_policy
  run_test test_forge_ci_no_unpinned_uses
  run_test test_forge_ci_under_size_budget
  run_test test_forge_ci_nvmrc_present_and_pinned
  run_test test_standard_forge_self_ci_has_required_sections
  run_test test_index_has_forge_self_ci_entry
  run_test test_contributing_documents_branch_protection
  run_test test_g1_manifest_self_consistency

  print_summary
}

main "$@"
