#!/usr/bin/env bash
# Forge — `forge upgrade` driver — non-destructive merge of
# framework updates into a scaffolded project.
# <!-- Audit: A.7 (a7-forge-upgrade, FR-UP-009) -->
#
# Architecture : library + main. Sourcing this file exposes the
# `_a7_*` library functions for unit-style testing in
# `a7.test.sh`. Direct invocation runs `_a7_main "$@"` to perform
# the upgrade end-to-end.
#
# Invocation contract :
#   forge-upgrade.sh --target <dir> --to-version <X.Y.Z> \
#                    [--dry-run] [--force] [--verbose]
#
# Exit codes :
#   0  — success
#   2  — argument error
#   5  — missing required tool (git / python3 / tar)
#   7  — upgrade aborted (major-version migration / dirty git tree /
#        non-Git target with --force)
#   8  — conflicts produced (without --force)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_REPO_ROOT="${FORGE_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# c1 skip-guard discipline (FR-GL-027) — defensive.
find_excluding_examples() {
  if [ -d "${FORGE_REPO_ROOT:-}/examples" ] \
     && [ -f "${FORGE_REPO_ROOT:-}/.forge/specs/full-stack-monorepo.md" ]; then
    find "$@" -not -path "${FORGE_REPO_ROOT}/examples/*"
  else
    find "$@"
  fi
}

# ─── Library functions (_a7_* — sourceable for testing) ───────

# _a7_sha256 <file> — echo the file's SHA-256 hex digest.
# Empty string when file does not exist.
_a7_sha256() {
  local f="$1"
  [ -f "$f" ] || { echo ""; return 0; }
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    sha256sum "$f" | awk '{print $1}'
  fi
}

# _a7_classify <left> <base> <right> — echo one of :
#   unchanged | upgraded | preserved | merge_candidate
#   | conflict_2way   (when BASE is empty/missing — 2-way fallback)
# Caller acts on the classification ; this function is pure.
_a7_classify() {
  local left="$1" base="$2" right="$3"
  local sha_l sha_b sha_r
  sha_l=$(_a7_sha256 "$left")
  sha_b=""
  [ -n "$base" ] && [ -f "$base" ] && sha_b=$(_a7_sha256 "$base")
  sha_r=$(_a7_sha256 "$right")

  if [ -z "$sha_b" ]; then
    # 2-way fallback : LEFT == RIGHT → unchanged ; else conflict.
    if [ "$sha_l" = "$sha_r" ]; then
      echo "unchanged"
    else
      echo "conflict_2way"
    fi
    return 0
  fi

  if [ "$sha_l" = "$sha_b" ] && [ "$sha_r" = "$sha_b" ]; then
    echo "unchanged"
  elif [ "$sha_l" = "$sha_b" ] && [ "$sha_r" != "$sha_b" ]; then
    echo "upgraded"
  elif [ "$sha_l" != "$sha_b" ] && [ "$sha_r" = "$sha_b" ]; then
    echo "preserved"
  else
    echo "merge_candidate"
  fi
}

# _a7_three_way_merge <left> <base> <right>
# Invokes `git merge-file --diff3` ; the file at LEFT is mutated
# in-place. Returns 0 on clean merge, non-zero on conflict (the
# value is git's conflict-section count). Conflict markers (in
# git format) are written into LEFT.
_a7_three_way_merge() {
  local left="$1" base="$2" right="$3"
  command -v git >/dev/null 2>&1 || { echo "git not on PATH" >&2; return 5; }
  git merge-file --diff3 "$left" "$base" "$right" 2>/dev/null
}

# _a7_record_conflict <project-root> <relpath>
# Appends "[CONFLICT] <relpath>" to <project-root>/.merge-conflicts.
# Creates the file if absent.
_a7_record_conflict() {
  local root="$1" rel="$2"
  printf '[CONFLICT] %s\n' "$rel" >> "$root/.merge-conflicts"
}

# _a7_check_force_clean_git <target>
# Returns 0 when target is a Git repo with empty `git status --porcelain`.
# Returns 7 when target is dirty or not under Git control.
_a7_check_force_clean_git() {
  local target="$1"
  if [ ! -d "$target/.git" ]; then
    echo "forge-upgrade: --force requires a Git-managed target (initialize with git init first)" >&2
    return 7
  fi
  command -v git >/dev/null 2>&1 || { echo "git not on PATH" >&2; return 5; }
  local out
  out=$(git -C "$target" status --porcelain 2>/dev/null)
  if [ -n "$out" ]; then
    echo "forge-upgrade: --force requires a clean Git working tree (use git stash / git commit first)" >&2
    return 7
  fi
}

# _a7_semver_major <version> — echo the major component.
_a7_semver_major() {
  local v="$1"
  echo "$v" | awk -F. '{print $1}'
}

# _a7_check_version_compat <from> <to>
# Returns 0 when the bump is safe (same major). Returns 7 with a
# `[NEEDS MIGRATION:]` message on stderr when the major differs.
_a7_check_version_compat() {
  local from="$1" to="$2"
  local from_major to_major
  from_major=$(_a7_semver_major "$from")
  to_major=$(_a7_semver_major "$to")
  if [ "$from_major" != "$to_major" ]; then
    echo "forge-upgrade: major-version migration required ($from → $to). Manual migration needed — see docs/MIGRATIONS.md." >&2
    echo "[NEEDS MIGRATION: from $from to $to]" >&2
    return 7
  fi
  return 0
}

# _a7_append_upgrade_history <manifest> <from> <to> <from_sha> <to_sha>
#                            <unchanged> <upgraded> <preserved>
#                            <conflicted> <skipped> <cli_version>
# Append-only mutation of the manifest's upgrade_history list.
# Also mutates the canonical fields (archetype_version, scaffold_date,
# template_set_sha) ; identity fields stay frozen.
_a7_append_upgrade_history() {
  local mf="$1" from="$2" to="$3" from_sha="$4" to_sha="$5"
  local c_unc="$6" c_upg="$7" c_prs="$8" c_cnf="$9" c_skp="${10}" cli_v="${11}"
  python3 - "$mf" "$from" "$to" "$from_sha" "$to_sha" \
    "$c_unc" "$c_upg" "$c_prs" "$c_cnf" "$c_skp" "$cli_v" <<'PY' || return 1
import sys, yaml, datetime
mf = sys.argv[1]
(_, _, frm, to, frm_sha, to_sha,
 c_unc, c_upg, c_prs, c_cnf, c_skp, cli_v) = sys.argv[:1] + sys.argv[1:]
with open(mf) as f:
    d = yaml.safe_load(f) or {}
hist = d.get("upgrade_history") or []
entry = {
    "date": datetime.datetime.now(datetime.timezone.utc)
        .replace(microsecond=0).isoformat(),
    "from_version": frm,
    "to_version": to,
    "from_template_set_sha": frm_sha,
    "to_template_set_sha": to_sha,
    "counts": {
        "unchanged": int(c_unc),
        "upgraded": int(c_upg),
        "preserved": int(c_prs),
        "conflicted": int(c_cnf),
        "skipped": int(c_skp),
    },
    "cli_version": cli_v,
}
hist.append(entry)
d["upgrade_history"] = hist
# Mutate canonical fields ; identity fields untouched.
d["archetype_version"] = to
d["template_set_sha"] = to_sha
d["scaffold_date"] = entry["date"]
with open(mf, "w") as f:
    yaml.safe_dump(d, f, default_flow_style=False, sort_keys=True)
PY
}

# _a7_resolve_owned_paths <forge-root>
# Echo one path per line (relative to forge-root) for every file
# matched by `owned:` patterns and not matched by `excluded:`.
_a7_resolve_owned_paths() {
  local root="$1"
  local yml="$root/.forge/framework-owned-paths.yml"
  [ -f "$yml" ] || { echo "framework-owned-paths.yml not found at $yml" >&2; return 4; }
  python3 - "$yml" "$root" <<'PY'
import sys, os, glob, fnmatch, yaml
yml, root = sys.argv[1], sys.argv[2]
data = yaml.safe_load(open(yml)) or {}
owned = data.get("owned") or []
excluded = data.get("excluded") or []
def is_excluded(rel):
    for ex in excluded:
        if fnmatch.fnmatch(rel, ex):
            return True
        if "**" in ex:
            stripped = ex.replace("**", "*")
            if fnmatch.fnmatch(rel, stripped):
                return True
            prefix = ex.split("**")[0].rstrip("/")
            if prefix and rel.startswith(prefix + "/"):
                return True
        if rel == ex:
            return True
    return False
found = set()
for pattern in owned:
    abs_pat = os.path.join(root, pattern)
    for m in glob.glob(abs_pat, recursive=True):
        if os.path.isfile(m):
            rel = os.path.relpath(m, root)
            if not is_excluded(rel):
                found.add(rel)
for p in sorted(found):
    print(p)
PY
}

# ─── Archetype merge surface (t8-upgrade-archetype-surface, Q-007) ───────────
#
# A.7 was designed against `default`, the one archetype that is a file-copy of the
# framework asset tree, and `_a7_main` always resolved owned paths from the FRAMEWORK
# root with RIGHT taken from the framework tree. A RENDERED archetype is a different
# shape: its `.forge/` is output, not a copy of Forge. Measured on an untouched
# mobile-pwa-first render: 49 conflicts, exit 8, and the two paths that project
# declares never opened.

# Echo the project's archetype when it should be merged as a RENDER; empty otherwise.
# Archetype mode requires a named archetype that HAS a scaffold plan (the plan is what
# makes RIGHT reproducible) and a project-side owned-paths declaration (ADR-T8UAS-001).
_a7_project_archetype() {
  local target="$1"
  local manifest="$target/.forge/scaffold-manifest.yaml"
  [ -f "$manifest" ] || return 0
  [ -f "$target/.forge/framework-owned-paths.yml" ] || return 0
  local a
  a=$(python3 -c "
import yaml,sys
try: print((yaml.safe_load(open(sys.argv[1])) or {}).get('archetype','') or '')
except Exception: print('')" "$manifest" 2>/dev/null)
  [ -n "$a" ] || return 0
  # The value comes from the TARGET's manifest — adopter-controlled, and on an
  # untrusted clone attacker-controlled. Unvalidated it becomes a path segment:
  # `../../../../planted` escapes the archetype tree, and a plan found there may
  # carry absolute `source:` paths the absolutizer leaves alone, so with --force
  # arbitrary readable files are written into the adopter's project and reported as
  # upgrades (review round 1, demonstrated end-to-end). overlay.sh already gates its
  # own --project-name / --reverse-domain this way; the archetype name had no gate.
  case "$a" in
    *[!a-zA-Z0-9._-]* | .* | "") return 0 ;;
  esac
  local d="$FORGE_REPO_ROOT/.forge/templates/archetypes/$a"
  [ -d "$d" ] || return 0
  # A template dir without a plan cannot be rendered (mobile-only is one); such a
  # project keeps the framework path it has always had.
  compgen -G "$d/scaffold-plan*.yaml" >/dev/null 2>&1 || return 0
  printf '%s\n' "$a"
}

# The merge surface of a rendered project: its OWN declaration, expanded against its
# own tree. The resolver was already root-parameterised — the defect was purely that
# `_a7_main` never passed anything but the framework root.
_a7_project_owned_paths() {
  _a7_resolve_owned_paths "$1"
}

# How many paths the project's declaration NAMES, before globbing. Compared against
# what actually resolved so a declaration that has drifted away from the tree is
# reported instead of silently shrinking the merge surface.
_a7_declared_path_count() {
  python3 -c "
import yaml,sys
try: d = yaml.safe_load(open(sys.argv[1] + '/.forge/framework-owned-paths.yml')) or {}
except Exception: print(0); raise SystemExit
print(len(d.get('owned') or []))" "$1" 2>/dev/null || echo 0
}

# Render an archetype into a throwaway dir and echo it. `templates_root` is the tree
# holding `.forge/templates/archetypes/<archetype>/` — the repo for RIGHT, an extracted
# snapshot for BASE (ADR-T8UAS-002). Caller owns cleanup.
_a7_render_archetype() {
  local archetype="$1" manifest="$2" templates_root="$3"
  # Re-gated here too: this function takes the name as a parameter, so a future
  # caller must not be able to reintroduce the traversal.
  case "$archetype" in
    *[!a-zA-Z0-9._-]* | .* | "") return 1 ;;
  esac
  local arch_dir="$templates_root/.forge/templates/archetypes/$archetype"
  [ -d "$arch_dir" ] || return 1

  # Prefer the plan named for the version being merged; fall back to the bare plan.
  local version plan
  version=$(python3 -c "
import yaml,sys
try: print((yaml.safe_load(open(sys.argv[1])) or {}).get('archetype_version','') or '')
except Exception: print('')" "$manifest" 2>/dev/null)
  plan="$arch_dir/scaffold-plan-$version.yaml"
  [ -f "$plan" ] || plan="$arch_dir/scaffold-plan.yaml"
  [ -f "$plan" ] || return 1

  local pn rd rmod
  pn=$(python3 -c "
import yaml,sys; print((yaml.safe_load(open(sys.argv[1])) or {}).get('project_name','') or '')" "$manifest" 2>/dev/null)
  rd=$(python3 -c "
import yaml,sys; print((yaml.safe_load(open(sys.argv[1])) or {}).get('reverse_domain','') or '')" "$manifest" 2>/dev/null)
  rmod=$(python3 -c "
import yaml,sys; print((yaml.safe_load(open(sys.argv[1])) or {}).get('root_module','') or '')" "$manifest" 2>/dev/null)
  [ -n "$pn" ] && [ -n "$rd" ] || return 1

  # overlay.sh hardcodes its own ARCHETYPE_DIR, so the plan's relative `source:` paths
  # are absolutized into a throwaway plan first — the trick every archetype wrapper
  # uses, and the reason the committed plan stays portable.
  local abs_plan; abs_plan=$(mktemp)
  if ! ARCH_DIR="$arch_dir" PLAN="$plan" ABS_PLAN="$abs_plan" python3 - <<'PY'
import os, yaml
arch = os.environ['ARCH_DIR']
plan = yaml.safe_load(open(os.environ['PLAN'])) or {}
for e in plan.get('templates', []):
    src = e.get('source', '')
    if src and not os.path.isabs(src):
        e['source'] = os.path.join(arch, src)
yaml.safe_dump(plan, open(os.environ['ABS_PLAN'], 'w'), sort_keys=False)
PY
  then rm -f "$abs_plan"; return 1; fi

  local out; out=$(mktemp -d -t forge-up-render-XXXXXX)
  if ! bash "$FORGE_REPO_ROOT/.forge/scripts/scaffolder/overlay.sh" \
        --target "$out" --project-name "$pn" --reverse-domain "$rd" \
        ${rmod:+--root-module "$rmod"} --plan "$abs_plan" >/dev/null 2>&1; then
    rm -f "$abs_plan"; rm -rf "$out"; return 1
  fi
  rm -f "$abs_plan"

  # The render writes its own manifest; it MUST NOT enter the merge. Measured by
  # b8-10b: without this a target carrying an upgrade_history loses it, near-invisibly,
  # because the rendered manifest repeats the same identity fields (FR-T8UAS-007).
  rm -f "$out/.forge/scaffold-manifest.yaml"
  rmdir "$out/.forge" 2>/dev/null || true

  printf '%s\n' "$out"
}

# ─── Main (only when invoked directly, not when sourced) ──────

_a7_usage() {
  sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

_a7_main() {
  local TARGET="" TO_VERSION="" DRY_RUN=0 FORCE=0 VERBOSE=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --target) TARGET="${2:-}"; shift 2 ;;
      --target=*) TARGET="${1#*=}"; shift ;;
      --to-version) TO_VERSION="${2:-}"; shift 2 ;;
      --to-version=*) TO_VERSION="${1#*=}"; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --force) FORCE=1; shift ;;
      --verbose) VERBOSE=1; shift ;;
      --help|-h) _a7_usage; return 0 ;;
      *) echo "forge-upgrade: unknown argument: $1" >&2; return 2 ;;
    esac
  done
  [ -n "$TARGET" ] || { echo "forge-upgrade: --target is required" >&2; return 2; }
  [ -n "$TO_VERSION" ] || { echo "forge-upgrade: --to-version is required" >&2; return 2; }
  [ -d "$TARGET" ] || { echo "forge-upgrade: target dir not found: $TARGET" >&2; return 2; }

  local manifest="$TARGET/.forge/scaffold-manifest.yaml"
  [ -f "$manifest" ] || {
    echo "forge-upgrade: target is not a Forge project (missing .forge/scaffold-manifest.yaml)" >&2
    return 2
  }

  command -v git >/dev/null 2>&1 || { echo "forge-upgrade: git is required" >&2; return 5; }
  command -v python3 >/dev/null 2>&1 || { echo "forge-upgrade: python3 is required" >&2; return 5; }

  local from_version from_sha
  from_version=$(python3 -c "
import yaml; print(yaml.safe_load(open('$manifest')).get('archetype_version', ''))")
  from_sha=$(python3 -c "
import yaml; print(yaml.safe_load(open('$manifest')).get('template_set_sha', ''))")
  local archetype
  archetype=$(python3 -c "
import yaml; print(yaml.safe_load(open('$manifest')).get('archetype', ''))")

  _a7_check_version_compat "$from_version" "$TO_VERSION" || return $?
  if [ "$FORCE" = "1" ]; then
    _a7_check_force_clean_git "$TARGET" || return $?
  fi

  # Recover BASE via snapshot ; degrade to 2-way if missing.
  local base_dir=""
  local snap="$FORGE_REPO_ROOT/.forge/scaffold-snapshots/$archetype/$from_version.tar.gz"
  if [ -f "$snap" ]; then
    base_dir=$(mktemp -d -t forge-up-base-XXXXXX)
    # shellcheck disable=SC2064
    trap "rm -rf '$base_dir'" EXIT
    tar -xzf "$snap" -C "$base_dir"
  else
    [ "$VERBOSE" = "1" ] && echo "forge-upgrade: [BASE unavailable for $from_version, falling back to 2-way merge]" >&2
  fi

  # Resolve the merge surface. A RENDERED archetype project is merged against its own
  # declaration and a rendered RIGHT; a framework-shaped project keeps the original
  # path unchanged (FR-T8UAS-006).
  local owned_list right_root="$FORGE_REPO_ROOT" base_root="$base_dir"
  local arch_mode; arch_mode=$(_a7_project_archetype "$TARGET")
  if [ -n "$arch_mode" ]; then
    local rendered_right
    if rendered_right=$(_a7_render_archetype "$arch_mode" "$manifest" "$FORGE_REPO_ROOT"); then
      right_root="$rendered_right"
      # shellcheck disable=SC2064
      trap "rm -rf '$rendered_right'" EXIT
      owned_list=$(_a7_project_owned_paths "$TARGET") || return $?
      # NFR-T8UAS-001 named an empty surface as the thing that must never happen, and
      # the only guard was on the render-failure branch. A declaration whose paths the
      # adopter moved or deleted resolves to fewer — or none — and the run reported
      # success, merged nothing, and still stamped the new version (review round 1).
      local declared resolved
      declared=$(_a7_declared_path_count "$TARGET")
      resolved=$(grep -c . <<<"$owned_list")
      if [ "$resolved" -eq 0 ]; then
        echo "forge-upgrade: the project declares $declared framework-owned path(s) and NONE resolved in the target — nothing would be merged; refusing rather than recording a clean upgrade" >&2
        return 8
      fi
      if [ "$declared" -gt 0 ] && [ "$resolved" -lt "$declared" ]; then
        echo "forge-upgrade: [$((declared - resolved)) of $declared declared path(s) did not resolve in the target — moved, renamed or deleted; they cannot receive framework changes]" >&2
      fi
      # BASE from the snapshot's TEMPLATE tree, rendered the same way. Reading an
      # adopter-layout path straight out of a framework-layout snapshot finds nothing
      # and degrades every file to a 2-way conflict (ADR-T8UAS-002).
      base_root=""
      if [ -n "$base_dir" ]; then
        local rendered_base
        if rendered_base=$(_a7_render_archetype "$arch_mode" "$manifest" "$base_dir"); then
          base_root="$rendered_base"
        elif [ "$VERBOSE" = "1" ]; then
          echo "forge-upgrade: [BASE render failed for $arch_mode, falling back to 2-way merge]" >&2
        fi
      fi
    else
      # NFR-T8UAS-001 — degrade to the behaviour this project had before, never to an
      # empty surface, which would report a clean upgrade having merged nothing.
      echo "forge-upgrade: [archetype render failed for $arch_mode, using framework paths]" >&2
      arch_mode=""
      owned_list=$(_a7_resolve_owned_paths "$FORGE_REPO_ROOT") || return $?
    fi
  else
    owned_list=$(_a7_resolve_owned_paths "$FORGE_REPO_ROOT") || return $?
  fi

  local C_UNC=0 C_UPG=0 C_PRS=0 C_CNF=0 C_SKP=0
  local rel src_left src_base src_right cls
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    src_left="$TARGET/$rel"
    src_base=""
    [ -n "$base_root" ] && src_base="$base_root/$rel"
    src_right="$right_root/$rel"
    [ -f "$src_right" ] || { C_SKP=$((C_SKP+1)); continue; }
    cls=$(_a7_classify "$src_left" "$src_base" "$src_right")
    case "$cls" in
      unchanged) C_UNC=$((C_UNC+1)) ;;
      upgraded)
        if [ "$DRY_RUN" = "0" ]; then
          mkdir -p "$(dirname "$src_left")"
          cp "$src_right" "$src_left"
        fi
        C_UPG=$((C_UPG+1))
        ;;
      preserved) C_PRS=$((C_PRS+1)) ;;
      merge_candidate)
        if [ "$DRY_RUN" = "0" ]; then
          if _a7_three_way_merge "$src_left" "$src_base" "$src_right"; then
            C_UPG=$((C_UPG+1))
          else
            _a7_record_conflict "$TARGET" "$rel"
            C_CNF=$((C_CNF+1))
          fi
        else
          # In dry-run, count optimistically as conflict (worst case).
          C_CNF=$((C_CNF+1))
        fi
        ;;
      conflict_2way)
        if [ "$DRY_RUN" = "0" ]; then
          if [ "$FORCE" = "1" ]; then
            cp "$src_right" "$src_left"
            C_UPG=$((C_UPG+1))
          else
            _a7_record_conflict "$TARGET" "$rel"
            C_CNF=$((C_CNF+1))
          fi
        else
          C_CNF=$((C_CNF+1))
        fi
        ;;
    esac
  done <<< "$owned_list"

  # Cleanup the .merge-conflicts file when zero conflicts.
  if [ "$C_CNF" = "0" ] && [ -f "$TARGET/.merge-conflicts" ]; then
    rm -f "$TARGET/.merge-conflicts"
  fi

  # Update manifest unless dry-run.
  if [ "$DRY_RUN" = "0" ]; then
    local to_sha
    # Hash the tree that actually produced RIGHT. This used to join against
    # $FORGE_REPO_ROOT unconditionally; once the surface became PROJECT-relative in
    # archetype mode none of those paths existed there, so every archetype upgrade
    # stamped sha256("") — e3b0c442… — over the project's real template_set_sha, and
    # the next upgrade recorded that constant as its `from`. Silent manifest damage,
    # exactly what FR-T8UAS-007 exists to prevent (review round 1, reproduced).
    to_sha=$(RIGHT_ROOT="$right_root" OWNED="$owned_list" python3 -c "
import hashlib, os, sys
h = hashlib.sha256()
root = os.environ['RIGHT_ROOT']
seen = 0
for line in os.environ['OWNED'].splitlines():
    if not line:
        continue
    p = os.path.join(root, line)
    if os.path.isfile(p):
        h.update(open(p, 'rb').read())
        seen += 1
if seen == 0:
    # Never stamp the empty digest: an all-absent surface means the hash describes
    # nothing, and writing it would erase the provenance the manifest carries.
    sys.exit(3)
print(h.hexdigest())
")
    if [ -z "$to_sha" ]; then
      echo "forge-upgrade: refusing to rewrite template_set_sha — the merge surface hashed nothing" >&2
      return 8
    fi
    local cli_version="dev"
    [ -f "$FORGE_REPO_ROOT/cli/VERSION" ] && cli_version=$(tr -d '\n' < "$FORGE_REPO_ROOT/cli/VERSION")
    _a7_append_upgrade_history "$manifest" \
      "$from_version" "$TO_VERSION" "$from_sha" "$to_sha" \
      "$C_UNC" "$C_UPG" "$C_PRS" "$C_CNF" "$C_SKP" "$cli_version" || return 1
  fi

  # Print structured summary.
  local pname
  pname=$(python3 -c "
import yaml; print(yaml.safe_load(open('$manifest')).get('project_name', ''))")
  echo "forge upgrade : $pname"
  echo "  archetype:        $archetype"
  echo "  from version:     $from_version"
  echo "  to version:       $TO_VERSION"
  echo "  files unchanged:  $C_UNC"
  echo "  files upgraded:   $C_UPG"
  echo "  files preserved:  $C_PRS"
  echo "  files conflicted: $C_CNF"
  echo "  files skipped:    $C_SKP"

  if [ "$C_CNF" -gt 0 ] && [ "$FORCE" = "0" ]; then
    return 8
  fi
  return 0
}

# Only run main when invoked directly (not when sourced).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _a7_main "$@"
fi
