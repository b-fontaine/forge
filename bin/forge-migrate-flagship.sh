#!/usr/bin/env bash
# Forge — `forge-migrate-flagship` 1.0.0 → 2.0.0 flagship migration orchestrator
# <!-- Audit: B.8.10 (b8-10-migrate-flagship) -->
#
#   Usage:
#     bash bin/forge-migrate-flagship.sh --target <dir> \
#          [--phase 0|1|2|3|4|all] [--dry-run] [--force] [--rollback] [--help|-h]
#
#   Exit-codes (ALIGNED to A.7 / bin/forge-upgrade.sh — ADR-B810-002, evidence P-01/P-28):
#     0 — success (migration applied, dry-run complete, rollback complete, --help)
#     2 — usage / argument error (missing --target, unknown flag, target absent)
#     5 — missing required tool (git / python3 / tar)
#     7 — precondition not met (not a 1.0.0 full-stack-monorepo target,
#         dirty Git tree without --force, frozen-snapshot sha256 mismatch)
#     8 — overlay produced merge conflicts without --force (the
#         _a7_three_way_merge conflict path; mirrors forge-upgrade.sh)
#   Summary: this is the 0/2/5/7/8 envelope — `1` is deliberately NOT used.
#
#   Determinism: SOURCE_DATE_EPOCH (POSIX integer Unix timestamp) is consumed via
#     os.environ.get("SOURCE_DATE_EPOCH") in the ledger wrapper; two runs with the
#     same SOURCE_DATE_EPOCH + inputs produce byte-identical ledger output.
#
#   Pattern: bash-thin + Python 3 inline (mirrors bin/forge-sbom.sh /
#     .forge/scripts/compliance/bundle.sh). The 3-way merge engine is SOURCED
#     from bin/forge-upgrade.sh (the _a7_* library) — this script is an
#     orchestration layer, NOT a second merge engine (ADR-B810-001). The
#     forge-upgrade.sh `_a7_main` runs only on direct invocation (sourcing guard,
#     evidence P-03/P-29) so sourcing is side-effect-free.
#
#   Constitutional invariants:
#     - ADDITIVE-ONLY: never removes Kong, Temporal, or REST-bridge paths
#       (VIII.1/VIII.2 SHALL clauses binding until B.8.14). FR-B810-031.
#     - NO orchestration swap to a DBOS-embedded backend: the 2.0.0 template-set
#       has zero such files (evidence P-14/P-31) and the temporal→embedded delta
#       is cancelled:true (B8O / ADR-B8O-001). Temporal is retained as the Rust
#       orchestrator. FR-B810-032. (This script never scaffolds or references
#       that cancelled backend — the token is named only in this comment.)
#     - FROZEN SNAPSHOT: reads .forge/scaffold-snapshots/full-stack-monorepo/
#       1.0.0.tar.gz read-only; NEVER rebuilds/overwrites it or its .sha256.
#       FR-B810-041.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_REPO_ROOT="${FORGE_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Phase 2 merge RIGHT root (the 27-file 2.0.0 template-set, evidence P-13/P-30).
TPL_20="$FORGE_REPO_ROOT/.forge/templates/archetypes/full-stack-monorepo/2.0.0"
# Merge BASE + rollback SOURCE (the byte-frozen B.8.2 snapshot, evidence P-11/P-35).
SNAP="$FORGE_REPO_ROOT/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
SNAP_SHA="$FORGE_REPO_ROOT/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256"

# Source the A.7 engine — SAFE (_a7_main guarded to direct-invocation only, P-03).
# DELIBERATELY does NOT call _a7_check_version_compat (the exit-7 guard that
# delegated here; re-calling would re-abort — ADR-B810-001).
# shellcheck source=bin/forge-upgrade.sh
source "$SCRIPT_DIR/forge-upgrade.sh"

# ─── State ──────────────────────────────────────────────────────────────────
TARGET=""
PHASE="all"
DRY_RUN=0
FORCE=0
ROLLBACK=0

err() { echo "forge-migrate-flagship: $*" >&2; }

usage() {
  cat <<EOF
Usage: forge-migrate-flagship.sh --target <dir> [flags]

Orchestrates the additive 1.0.0 → 2.0.0 full-stack-monorepo migration by
sourcing bin/forge-upgrade.sh and reusing its _a7_* 3-way merge library.

Flags:
  --target <dir>        Project directory to migrate (required).
  --phase <0|1|2|all>   Run the given phase(s) only. Default: all.
                        3|4 are forward-reference stubs (print plan, exit 0).
  --dry-run             Print the plan and per-phase actions; mutate nothing.
  --force               Override the Git-clean gate; accept conflicts as overwrite.
  --rollback            Restore the target from the frozen 1.0.0 snapshot.
                        Mutually exclusive with --phase (full-snapshot restore
                        only; --phase is ignored + a warning is emitted).
                        Rollback criteria (p99 / traceparent thresholds) are the
                        B.8.13 runbook — the cancelled orchestration-swap leg (B8O)
                        contributes no CPU criterion. See docs/MIGRATIONS.md.
  --help, -h            Print this usage and exit 0.

Exit-codes: 0 success / 2 usage error / 5 missing tool / 7 precondition not met /
            8 overlay conflicts without --force.  (The 0/2/5/7/8 envelope.)

Runbook: docs/MIGRATIONS.md (1.0.0 → 2.0.0 section). Recommended first step:
  bash bin/forge-migrate-flagship.sh --target . --dry-run
EOF
}

# ─── shasum platform shim ─────────────────────────────────────────────────────
_b810_sha256_file() {
  local f="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    sha256sum "$f" | awk '{print $1}'
  fi
}

# ─── Phase 0 preflight ────────────────────────────────────────────────────────
# Asserts the target is a clean 1.0.0 full-stack-monorepo and the frozen snapshot
# is byte-intact. Writes NOTHING to the target under any code path. FR-B810-010..014.
_b810_phase0_preflight() {
  local target="$1"
  local manifest="$target/.forge/scaffold-manifest.yaml"

  # (a) Manifest read + archetype/version asserts (Python-inline, P-18/P-36).
  if [ ! -f "$manifest" ]; then
    err "preflight: manifest-missing: $manifest not found — target is not a Forge project"
    exit 7
  fi
  local verdict
  verdict=$(python3 - "$manifest" <<'PY'
import sys, yaml
mf = sys.argv[1]
try:
    d = yaml.safe_load(open(mf)) or {}
except Exception as e:
    print("parse-error:%s" % e); raise SystemExit(0)
arch = d.get("archetype", "")
ver = str(d.get("archetype_version", ""))
if arch != "full-stack-monorepo":
    print("wrong-archetype:%s" % (arch or "<none>")); raise SystemExit(0)
if ver != "1.0.0":
    print("wrong-version:%s" % (ver or "<none>")); raise SystemExit(0)
print("ok")
PY
)
  case "$verdict" in
    ok) ;;
    wrong-archetype:*)
      err "preflight: wrong-archetype: target archetype is '${verdict#wrong-archetype:}', expected full-stack-monorepo"
      exit 7 ;;
    wrong-version:*)
      err "preflight: wrong-version: target archetype_version is '${verdict#wrong-version:}'. Migration requires archetype_version: 1.0.0."
      exit 7 ;;
    *)
      err "preflight: manifest-unreadable: could not parse $manifest (${verdict})"
      exit 7 ;;
  esac

  # (b) Git-clean gate (reuse the sourced _a7_check_force_clean_git, P-04) unless --force.
  if [ "$FORCE" != "1" ]; then
    if ! _a7_check_force_clean_git "$target"; then
      err "preflight: dirty-git: target Git tree is dirty or not initialised — commit/stash first, or pass --force"
      exit 7
    fi
  fi

  # (c) Frozen snapshot sha256 verify (FR-B810-012).
  if [ ! -f "$SNAP" ] || [ ! -f "$SNAP_SHA" ]; then
    err "preflight: snapshot-missing: frozen 1.0.0 snapshot or sha256 absent under .forge/scaffold-snapshots/full-stack-monorepo/"
    exit 7
  fi
  local expected actual
  expected=$(awk '{print $1}' "$SNAP_SHA")
  actual=$(_b810_sha256_file "$SNAP")
  if [ "$expected" != "$actual" ]; then
    err "preflight: snapshot-sha256: expected $expected actual $actual — refusing to use a corrupted BASE"
    exit 7
  fi

  # (d) --dry-run: print the plan and return without mutation (FR-B810-014).
  if [ "$DRY_RUN" = "1" ]; then
    echo "[Phase 0] preflight: OK"
    echo "  target:        $target"
    echo "  from version:  1.0.0"
    echo "  to version:    2.0.0 (scaffoldable: false until B.8.14)"
    echo "  phases:        $PHASE"
    echo "  additive deltas (5):"
    echo "    - Kong → Envoy Gateway          (B.8.4)"
    echo "    - REST-bridge → Connect-RPC      (B.8.6)"
    echo "    - implicit-auth → Zitadel        (B.8.7)"
    echo "    - no-web → Qwik web-public       (B.8.9)"
    echo "    - postgres-16 → 17 + pgvector    (B.8.5)"
    echo "  (Kong / Temporal / REST preserved — additive only, removal is B.8.14.)"
  fi
}

# ─── Phase 1 obs + contracts (idempotent assert-or-apply) ─────────────────────
# The flagship 1.0.0 ships the obs trio post-B.8.8 + Connect codegen (B.8.6); this
# phase is primarily a verification gate. FR-B810-020..022.
_b810_phase1_obs_contracts() {
  local target="$1"
  local missing=()
  # Detection predicate: known sentinel surfaces shipped by the flagship 1.0.0.
  local sentinels=(
    "shared/protos/buf.gen.yaml"
    "backend/crates/grpc-api"
    "infra/k8s"
  )
  local s
  for s in "${sentinels[@]}"; do
    if [ ! -e "$target/$s" ]; then
      missing+=("$s")
    fi
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    echo "[Phase 1] obs/contracts: all present (no-op)"
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "[Phase 1] obs/contracts: missing sentinels (dry-run, no mutation):"
    printf '    - %s\n' "${missing[@]}"
    return 0
  fi

  # Absent + apply: the obs/contracts overlays live in the 2.0.0 RIGHT and are
  # applied by the Phase 2 classify path; Phase 1 records the gap and defers the
  # additive apply to Phase 2 (idempotent — re-running with all present is a no-op).
  echo "[Phase 1] obs/contracts: ${#missing[@]} sentinel(s) absent — additive apply deferred to Phase 2 overlay"
}

# ─── Phase 2 relpath mapper ───────────────────────────────────────────────────
# Strip the leading 2.0.0/ prefix; the remainder is the adopter-project relpath
# (the schema layer names backend/ frontend/ infra/ shared/ are identical in the
# 2.0.0 tree and the adopter tree — evidence P-16). FR-B810-030, ADR-B810-001.
_b810_map_relpath() {
  local rel="$1"
  printf '%s\n' "${rel#2.0.0/}"
}

# ─── Phase 2 structural overlay (additive 3-way merge via sourced _a7_*) ──────
# FR-B810-030..036. ADDITIVE ONLY — never deletes a Kong/Temporal/REST path.
_b810_phase2_overlay() {
  local target="$1"
  local manifest="$target/.forge/scaffold-manifest.yaml"

  # Extract BASE from the frozen 1.0.0 snapshot (read-only; P-10/P-11).
  local base_dir
  base_dir=$(mktemp -d -t forge-mig-base-XXXXXX)
  # shellcheck disable=SC2064
  trap "rm -rf '$base_dir'" RETURN
  tar -xzf "$SNAP" -C "$base_dir"

  local C_UNC=0 C_UPG=0 C_PRS=0 C_CNF=0 C_SKP=0
  local right_abs rel tgt_rel left base cls

  # Walk the 2.0.0 RIGHT set (sorted for determinism).
  while IFS= read -r right_abs; do
    [ -z "$right_abs" ] && continue
    rel="${right_abs#"$TPL_20"/}"
    tgt_rel="$(_b810_map_relpath "2.0.0/$rel")"
    left="$target/$tgt_rel"
    base="$base_dir/$tgt_rel"
    cls=$(_a7_classify "$left" "$base" "$right_abs")
    case "$cls" in
      unchanged) C_UNC=$((C_UNC+1)) ;;
      upgraded)
        if [ "$DRY_RUN" = "1" ]; then
          echo "    [upgraded]  $tgt_rel"
        else
          mkdir -p "$(dirname "$left")"
          cp "$right_abs" "$left"
        fi
        C_UPG=$((C_UPG+1)) ;;
      preserved) C_PRS=$((C_PRS+1)) ;;
      merge_candidate)
        if [ "$DRY_RUN" = "1" ]; then
          echo "    [merge]     $tgt_rel"
          C_CNF=$((C_CNF+1))
        else
          if _a7_three_way_merge "$left" "$base" "$right_abs"; then
            C_UPG=$((C_UPG+1))
          else
            _a7_record_conflict "$target" "$tgt_rel"
            C_CNF=$((C_CNF+1))
          fi
        fi ;;
      conflict_2way)
        if [ "$DRY_RUN" = "1" ]; then
          echo "    [new/2way]  $tgt_rel"
          C_UPG=$((C_UPG+1))
        elif [ "$FORCE" = "1" ]; then
          mkdir -p "$(dirname "$left")"
          cp "$right_abs" "$left"
          C_UPG=$((C_UPG+1))
        else
          # New file (no BASE counterpart) — additive create is safe, not a conflict.
          mkdir -p "$(dirname "$left")"
          cp "$right_abs" "$left"
          C_UPG=$((C_UPG+1))
        fi ;;
    esac
  done < <(find "$TPL_20" -type f | sort)

  # Canary cutover guidance (document-only; ADR-B810-005, FR-B810-034). No
  # per-route weights are generated — the Kong→Envoy canary is adopter-driven.
  echo "[Phase 2] canary cutover: Kong→Envoy is a manual, per-route graduated cutover."
  echo "  Kong is preserved; Envoy is added in parallel. Shift HTTPRoute weights"
  echo "  route-by-route per docs/MIGRATIONS.md (Envoy SecurityPolicy/JWT OIDC is B.8.12)."

  echo "[Phase 2] overlay summary: unchanged=$C_UNC upgraded=$C_UPG preserved=$C_PRS conflicted=$C_CNF skipped=$C_SKP"

  if [ "$DRY_RUN" = "1" ]; then
    return 0
  fi

  # Ledger append (reuse the A.7 helper, then tag kind — ADR-B810-004).
  local from_sha to_sha cli_version="dev"
  from_sha=$(awk '{print $1}' "$SNAP_SHA")
  to_sha=$(python3 -c "
import hashlib, os, sys
h = hashlib.sha256()
root = sys.argv[1]
for dp, _, fns in os.walk(root):
    for fn in sorted(fns):
        with open(os.path.join(dp, fn), 'rb') as fh:
            h.update(fh.read())
print(h.hexdigest())
" "$TPL_20")
  [ -f "$FORGE_REPO_ROOT/cli/VERSION" ] && cli_version=$(tr -d '\n' < "$FORGE_REPO_ROOT/cli/VERSION")
  _a7_append_upgrade_history "$manifest" \
    "1.0.0" "2.0.0" "$from_sha" "$to_sha" \
    "$C_UNC" "$C_UPG" "$C_PRS" "$C_CNF" "$C_SKP" "$cli_version" || return 1
  _b810_tag_last_history_kind "$manifest"

  if [ "$C_CNF" -gt 0 ] && [ "$FORCE" != "1" ]; then
    err "phase 2: $C_CNF conflict(s) produced — resolve, or re-run with --force to overwrite"
    exit 8
  fi
}

# ─── Ledger kind tagger (thin wrapper; does NOT edit forge-upgrade.sh) ────────
# Stamps kind: flagship-migration onto the LAST upgrade_history entry; overrides
# the entry date deterministically when SOURCE_DATE_EPOCH is set. ADR-B810-004,
# FR-B810-007/060/061/062, NFR-B810-005.
_b810_tag_last_history_kind() {
  local manifest="$1"
  python3 - "$manifest" <<'PY' || return 1
import sys, os, yaml, datetime
mf = sys.argv[1]
with open(mf) as f:
    d = yaml.safe_load(f) or {}
hist = d.get("upgrade_history") or []
if not hist:
    raise SystemExit(0)
last = hist[-1]
last["kind"] = "flagship-migration"
sde = os.environ.get("SOURCE_DATE_EPOCH")
if sde is not None:
    last["date"] = (
        datetime.datetime.utcfromtimestamp(int(sde))
        .replace(microsecond=0).isoformat() + "Z"
    )
d["upgrade_history"] = hist
with open(mf, "w") as f:
    yaml.safe_dump(d, f, default_flow_style=False, sort_keys=True)
PY
}

# ─── Phase 3 / 4 forward-reference stubs ──────────────────────────────────────
# FR-B810-036/052. Print the plan and exit 0 informational; no overlay, no mutation.
_b810_phase34_stub() {
  case "$1" in
    3) echo "[Phase 3] T7 new archetypes — forward reference: see docs/MIGRATIONS.md Phase 3 stub." ;;
    4) echo "[Phase 4] T8 deprecation plan — forward reference: see docs/MIGRATIONS.md Phase 4 stub." ;;
  esac
  exit 0
}

# ─── Rollback (full-tree restore from the frozen snapshot) ────────────────────
# FR-B810-040..043. NEVER writes the snapshot or its .sha256.
_b810_rollback() {
  local target="$1"

  # Verify snapshot integrity before restore (FR-B810-012 reuse).
  if [ ! -f "$SNAP" ] || [ ! -f "$SNAP_SHA" ]; then
    err "rollback: snapshot-missing: frozen 1.0.0 snapshot or sha256 absent"
    exit 7
  fi
  local expected actual
  expected=$(awk '{print $1}' "$SNAP_SHA")
  actual=$(_b810_sha256_file "$SNAP")
  if [ "$expected" != "$actual" ]; then
    err "rollback: snapshot-sha256 mismatch — refusing restore to prevent corruption"
    exit 7
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "[Rollback] restore plan:"
    echo "  source:  scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
    echo "  sha256:  $actual"
    echo "  target:  $target"
    echo "  (B.8.13 rollback criteria: p99 +>20% after Envoy → roll back Kong;"
    echo "   traceparent errors >1% → roll back OTel SDK only. The cancelled"
    echo "   orchestration-swap leg (B8O) contributes no CPU criterion.)"
    exit 0
  fi

  tar -xzf "$SNAP" -C "$target"
  echo "[Rollback] target restored from the frozen 1.0.0 snapshot."
  exit 0
}

# ─── Arg parse (while/case; bundle.sh shape) ──────────────────────────────────
_b810_parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --target) TARGET="${2:-}"; shift 2 ;;
      --target=*) TARGET="${1#*=}"; shift ;;
      --phase) PHASE="${2:-}"; shift 2 ;;
      --phase=*) PHASE="${1#*=}"; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --force) FORCE=1; shift ;;
      --rollback) ROLLBACK=1; shift ;;
      --help|-h) usage; exit 0 ;;
      *) err "unknown argument: $1"; usage >&2; exit 2 ;;
    esac
  done

  [ -n "$TARGET" ] || { err "--target is required"; usage >&2; exit 2; }
  [ -d "$TARGET" ] || { err "target directory not found: $TARGET"; exit 2; }

  # --rollback / --phase mutually exclusive (ADR-B810-002): warn, then ignore --phase.
  if [ "$ROLLBACK" = "1" ] && [ "$PHASE" != "all" ]; then
    err "--phase ignored with --rollback (full-snapshot restore only)"
    PHASE="all"
  fi
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────
_b810_main() {
  _b810_parse_args "$@"

  # Tool preflight (exit 5 — ADR-B810-002 / P-01 alignment).
  local tool
  for tool in git python3 tar; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      err "required tools missing: git python3 tar"
      exit 5
    fi
  done

  if [ "$ROLLBACK" = "1" ]; then
    _b810_phase0_preflight "$TARGET"
    _b810_rollback "$TARGET"
    return 0
  fi

  # Phase 3/4 stubs reach the dispatch directly (no overlay).
  case "$PHASE" in
    3|4)
      _b810_phase0_preflight "$TARGET"
      _b810_phase34_stub "$PHASE" ;;
  esac

  # Phase 0 always runs first as the precondition gate.
  _b810_phase0_preflight "$TARGET"

  case "$PHASE" in
    0) ;;
    1) _b810_phase1_obs_contracts "$TARGET" ;;
    2) _b810_phase2_overlay "$TARGET" ;;
    all)
      _b810_phase1_obs_contracts "$TARGET"
      _b810_phase2_overlay "$TARGET" ;;
    *) err "unknown --phase value: $PHASE (expected 0|1|2|3|4|all)"; exit 2 ;;
  esac

  return 0
}

_b810_main "$@"
rc=$?
exit $rc
