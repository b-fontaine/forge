#!/usr/bin/env bash
# Forge — scaffold-snapshot builder for the `forge upgrade` BASE recovery.
# <!-- Audit: A.7 (a7-forge-upgrade, FR-UP-008) -->
#
# Builds a versioned snapshot tarball capturing the framework's
# `owned:` paths (per .forge/framework-owned-paths.yml) at the
# current state. Output goes to
# .forge/scaffold-snapshots/<archetype>/<version>.tar.gz.
#
# Usage :
#   bin/forge-snapshot.sh build <archetype> <version>
#   bin/forge-snapshot.sh extract <archetype> <version> <target-dir>
#
# Subcommands :
#   build    — produce a snapshot tarball from the current framework
#              tree. Used at archive time of every framework version
#              that consumers may need to upgrade FROM.
#   extract  — restore a snapshot tarball into <target-dir>. Used by
#              forge-upgrade.sh to recover BASE for the 3-way merge.
#
# Exit codes :
#   0  — success
#   2  — argument error
#   3  — version regex mismatch
#   4  — target collision (build) / target missing (extract)
#   5  — missing tool (python3 / tar / gzip)

set -euo pipefail

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OWNED_YML="$FORGE_ROOT/.forge/framework-owned-paths.yml"
SNAP_BASE_DIR="$FORGE_ROOT/.forge/scaffold-snapshots"

# Helpers
err() { echo "forge-snapshot.sh: $*" >&2; }
require_tool() {
  command -v "$1" >/dev/null 2>&1 || { err "missing required tool: $1"; exit 5; }
}
require_tool python3
require_tool tar
require_tool gzip

usage() {
  sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Resolve owned-paths globs against FORGE_ROOT. Echoes one path per
# line (relative to FORGE_ROOT). Excluded paths are stripped.
resolve_owned_paths() {
  python3 - "$OWNED_YML" "$FORGE_ROOT" <<'PY'
import sys, os, glob, fnmatch, yaml

owned_yml, root = sys.argv[1], sys.argv[2]
data = yaml.safe_load(open(owned_yml)) or {}
owned_globs = data.get("owned") or []
excluded_globs = data.get("excluded") or []

def expand(pattern, base):
    # ** glob expansion via Python glob (recursive=True)
    abs_pattern = os.path.join(base, pattern)
    matches = glob.glob(abs_pattern, recursive=True)
    out = []
    for m in matches:
        if os.path.isfile(m):
            out.append(os.path.relpath(m, base))
    return out

def is_excluded(rel, excludes):
    for ex in excludes:
        # Translate ** glob → fnmatch ; ** matches anything inc. /
        # so we replace ** with * and match path-by-path (or just
        # use fnmatch with translated pattern)
        normalized = ex.replace("**", "*")
        if fnmatch.fnmatch(rel, ex) or fnmatch.fnmatch(rel, normalized):
            return True
        if rel.startswith(ex.rstrip("*").rstrip("/")) and "**" in ex:
            return True
    return False

found = set()
for g in owned_globs:
    for path in expand(g, root):
        if not is_excluded(path, excluded_globs):
            found.add(path)

for p in sorted(found):
    print(p)
PY
}

cmd_build() {
  local archetype="$1" version="$2"
  if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]; then
    err "version '$version' does not match SemVer ^X.Y.Z(-pre)?$"; exit 3
  fi
  local out_dir="$SNAP_BASE_DIR/$archetype"
  local out_file="$out_dir/$version.tar.gz"
  mkdir -p "$out_dir"
  if [ -e "$out_file" ]; then
    err "snapshot already exists: $out_file (delete first or bump version)"; exit 4
  fi

  # tmpdir must be visible to the EXIT trap from any shell scope ;
  # use a global var to avoid the local-scope unbound-variable trap.
  SNAP_TMP_DIR=$(mktemp -d -t forge-snap-XXXXXX)
  # shellcheck disable=SC2064  # intentional immediate expansion
  trap "rm -rf '$SNAP_TMP_DIR'" EXIT
  local tmp="$SNAP_TMP_DIR"

  # Resolve owned paths and copy them into the staging dir preserving structure
  local count=0
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    local src="$FORGE_ROOT/$rel"
    local dst="$tmp/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    count=$((count + 1))
  done < <(resolve_owned_paths)

  if [ "$count" = "0" ]; then
    err "no owned paths resolved — refusing to build empty snapshot"; exit 4
  fi

  # Tarball production — Python tarfile path (b8-obi-refresh /
  # ADR-B8-OBI-011 determinism patch, 2026-05-29).
  #
  # Two reproducibility properties enforced :
  #   1. Per-file SHA-256 determinism — preserved by `cp -p` (was
  #      already the case ; this is what `forge upgrade` checks via
  #      ADR-004).
  #   2. **Tarball byte-identity across rebuilds** — newly enforced
  #      via SOURCE_DATE_EPOCH-pinned mtimes + sorted entry order +
  #      uid/gid normalised to 0 + uname/gname blanked + gzip header
  #      mtime stripped. Lifts the long-standing variance previously
  #      acknowledged in this script (rebuild produced different
  #      SHA-256). Triggered by the trio-3 review finding (HIGH)
  #      that NFR-B8-OBI-011 claimed byte-identity the tooling did
  #      not deliver.
  #
  # SOURCE_DATE_EPOCH source : env-var first, then `git log -1
  # --pretty=%ct` HEAD timestamp (FORGE_ROOT), then 0. Mirrors the
  # I.5 ADR-I5-CW-002 commit-ts precedent (`bin/forge-sbom.sh` uses
  # the same fallback chain for CycloneDX SBOM determinism).
  #
  # macOS / Linux portability — Python tarfile is used instead of
  # invoking `tar(1)` so the same code path runs on BSD tar (macOS)
  # and GNU tar (Linux CI). The previous BSD-only
  # `--no-mac-metadata --no-xattrs` flags are no longer needed
  # because `cp -p` over Python tarfile addition does not surface
  # AppleDouble / xattr headers (TarInfo objects are constructed
  # from stat() output only).
  local sde="${SOURCE_DATE_EPOCH:-}"
  if [ -z "$sde" ]; then
    sde=$(cd "$FORGE_ROOT" && git log -1 --pretty=%ct 2>/dev/null || echo 0)
  fi

  python3 - "$tmp" "$out_file" "$sde" <<'PY'
import os, sys, tarfile, gzip, io
src_dir, out_path, sde = sys.argv[1], sys.argv[2], int(sys.argv[3])

# Walk + sort lexically (LC_ALL=C-equivalent — Python sort uses
# byte-comparison on byte-strings or codepoint-comparison on str).
entries = []
for dirpath, dirs, files in os.walk(src_dir):
    dirs.sort()
    for f in sorted(files):
        entries.append(os.path.join(dirpath, f))
entries.sort()

# Write tarball through a gzip stream with explicit mtime=0 so the
# gzip header carries no embedded timestamp (otherwise gzip stamps
# the wall-clock at compression time and breaks byte-identity).
with open(out_path, 'wb') as fp:
    with gzip.GzipFile(filename='', mode='wb', fileobj=fp, mtime=0) as gz:
        # Use ustar format (POSIX, portable) — avoids the
        # variable-length pax extended headers GNU tar emits by
        # default.
        with tarfile.open(fileobj=gz, mode='w', format=tarfile.USTAR_FORMAT) as tf:
            for abs_path in entries:
                rel = os.path.relpath(abs_path, src_dir)
                # Tar entry name uses the POSIX './<rel>' shape that
                # the previous `tar -czf <out> .` invocation produced,
                # for backward identity with consumers that grep on
                # the leading './'.
                ti = tarfile.TarInfo(name=f'./{rel}')
                st = os.stat(abs_path)
                ti.size = st.st_size
                ti.mtime = sde
                ti.mode = st.st_mode & 0o7777
                # Normalise owner/group — drop host-specific uids.
                ti.uid = 0
                ti.gid = 0
                ti.uname = ''
                ti.gname = ''
                ti.type = tarfile.REGTYPE
                with open(abs_path, 'rb') as content:
                    tf.addfile(ti, content)
PY

  local size; size=$(wc -c < "$out_file" | tr -d ' ')
  echo "✓ snapshot built: $out_file ($count files, $size bytes gzipped, SOURCE_DATE_EPOCH=$sde)"
}

cmd_extract() {
  local archetype="$1" version="$2" target="$3"
  local in_file="$SNAP_BASE_DIR/$archetype/$version.tar.gz"
  if [ ! -f "$in_file" ]; then
    err "snapshot missing: $in_file"; exit 4
  fi
  if [ ! -d "$target" ]; then
    err "target dir missing: $target"; exit 4
  fi
  tar -xzf "$in_file" -C "$target"
  echo "✓ snapshot extracted: $in_file → $target"
}

main() {
  if [ $# -lt 1 ]; then
    usage; exit 2
  fi
  local sub="$1"; shift
  case "$sub" in
    build)
      [ $# -eq 2 ] || { err "build requires <archetype> <version>"; exit 2; }
      cmd_build "$1" "$2"
      ;;
    extract)
      [ $# -eq 3 ] || { err "extract requires <archetype> <version> <target-dir>"; exit 2; }
      cmd_extract "$1" "$2" "$3"
      ;;
    --help|-h|help)
      usage
      ;;
    *)
      err "unknown subcommand: $sub"; usage; exit 2
      ;;
  esac
}

main "$@"
