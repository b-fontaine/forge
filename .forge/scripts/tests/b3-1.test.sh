#!/usr/bin/env bash
# Forge — B.3.1 rust-cli-tui 1.0.0 candidate schema harness
# <!-- Audit: B.3.1 (b3-1-schema) — the rust-cli-tui archetype scaffold schema -->
#
# B.3's brick breakdown is NOT in this repository: docs/new-archetypes-plan.md §3.3 says
# "inchangé du plan d'origine (B.3.1 → B.3.14)" and that list exists nowhere here. That
# B.3.1 is the schema is INFERRED from an unbroken precedent — B.6.1, B.7.1 and B.9.1
# are each "the schema" — and the inference is recorded as ADR-B31-001 rather than
# presented as a specification.
#
#   T-001  the schema file exists and parses                        (FR-B31-001)
#   T-002  name/version match the path                              (FR-B31-001)
#   T-003  stage: candidate                                         (FR-B31-002)
#   T-004  scaffoldable: false, and it agrees with the stage        (FR-B31-002)
#   T-005  layer_profile: client-only                               (FR-B31-003)
#   T-006  exactly two layers: cli, tui                             (FR-B31-004)
#   T-007  every layer carries the four required fields             (FR-B31-004)
#   T-008  the layer agents are the ratified Rust sub-team          (FR-B31-004)
#   T-009  phases are materialised INLINE, with no `extends:` key   (FR-B31-005)
#   T-010  the tdd-rust chain is present in order                   (FR-B31-005)
#   T-011  the review phase keeps the Rust gates                    (FR-B31-005)
#   T-012  NEGATIVE — no resolved version pin anywhere              (FR-B31-006)
#   T-013  components declare the B.3 surface, each with an owner   (FR-B31-007)
#   T-014  every `delivered_by` names a B.3.x brick                 (FR-B31-007)
#   T-015  the header documents candidate + promotion + the inference (FR-B31-008)
#   T-016  the live validator PASSes this schema                    (FR-B31-009)
#   T-017  NEGATIVE — no dispatch-table key yet                     (NFR-B31-002)
#   T-018  NEGATIVE — the shipped archetypes are untouched          (NFR-B31-001)
#
# 18 L1. Zero network, zero Docker, zero cargo.

set -uo pipefail

# Needles name the CLAIM and are unique in the region they are checked in. T-015's
# first version used the bare word `inferred` and survived a mutation that deleted the
# sentence it protects, because the word recurs two paragraphs down — the SEVENTH
# instance in this repository of a needle satisfied by something other than what it
# names (b9-2 T-029, b5 FR-IW-009, b9-4 client-only, b9-5 props, b9-11 twice).
# Before trusting a needle, grep -c it inside the region: a count above 1 is not an
# assertion about either occurrence.
#
# Stream greps use `<<<` or `< <(...)`, never `producer | grep -q`: under pipefail the
# early-exiting reader makes the writer take SIGPIPE (141) and the assertion reports the
# opposite of the truth (t5-helpers-sigpipe).

LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in --level=*) LEVEL="${arg#*=}" ;; esac
  prev="$arg"
done
: "$LEVEL"

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT="$(cd "$SCRIPTS_DIR/../.." && pwd)"

SCHEMA="$FORGE_ROOT/.forge/schemas/rust-cli-tui/1.0.0.yaml"
DISPATCH="$FORGE_ROOT/.forge/scaffolding/dispatch-table.yml"
TAXONOMY="$FORGE_ROOT/.forge/schemas/archetype.schema.json"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

_have_py_yaml() { command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; }

# One parse, cached as `key=value` lines, so eighteen cells do not re-read the file.
_PY_CACHE=""
_ensure_py_cache() {
  [ -n "$_PY_CACHE" ] && return 0
  [ -f "$SCHEMA" ] || { echo "    schema missing: $SCHEMA" >&2; return 1; }
  _have_py_yaml || { echo "    python3+PyYAML required" >&2; return 1; }
  _PY_CACHE=$(python3 - "$SCHEMA" <<'PY'
import sys, yaml, json
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
r = {}
for k in ('name', 'version', 'stage', 'layer_profile'):
    r[k] = str(d.get(k, 'MISSING'))
r['scaffoldable'] = str(d.get('scaffoldable', 'MISSING'))
r['has_extends'] = str('extends' in d)
layers = d.get('layers') or []
r['layer_ids'] = ','.join(sorted(str((l or {}).get('id', '')) for l in layers))
r['layer_agents'] = ','.join(sorted(str((l or {}).get('primary_agent', '')) for l in layers))
r['layer_fields_ok'] = str(all(
    all(k in (l or {}) for k in ('id', 'path', 'fr_id_prefix', 'primary_agent'))
    for l in layers) and bool(layers))
phases = d.get('phases') or []
r['phase_ids'] = ','.join(str((p or {}).get('id', '')) for p in phases)
review = next((p for p in phases if (p or {}).get('id') == 'review'), {}) or {}
r['review_checks'] = ','.join(sorted(str(c) for c in (review.get('checks') or [])))
comps = d.get('components') or []
r['component_names'] = ','.join(sorted(str((c or {}).get('name', '')) for c in comps))
r['delivered_by'] = ','.join(sorted(
    str((c or {}).get('delivered_by')) for c in comps if (c or {}).get('delivered_by')))
r['unowned_components'] = ','.join(sorted(
    str((c or {}).get('name', '?')) for c in comps
    if not (c or {}).get('delivered_by') and not (c or {}).get('standard')))
for k, v in r.items():
    print(f"{k}={v}")
PY
  ) || { echo "    schema failed to parse" >&2; return 1; }
  return 0
}
_get() { grep -m1 "^$1=" <<<"$_PY_CACHE" | cut -d= -f2-; }

# ─── Identity and stage (T-001..T-004) ───────────────────────────────────────

_test_b31_001_schema_exists() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-001: $SCHEMA missing (FR-B31-001)" >&2; return 1; }
  _ensure_py_cache || return 1
}

_test_b31_002_identity() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get name)" = "rust-cli-tui" ] \
    || { echo "    FAIL T-002: name='$(_get name)' != 'rust-cli-tui' (FR-B31-001)" >&2; ok=0; }
  [ "$(_get version)" = "1.0.0" ] \
    || { echo "    FAIL T-002: version='$(_get version)' != '1.0.0' — the validator derives it from the filename (FR-B31-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b31_003_stage_candidate() {
  _ensure_py_cache || return 1
  [ "$(_get stage)" = "candidate" ] \
    || { echo "    FAIL T-003: stage='$(_get stage)' != 'candidate' — a schema brick ships candidate; promotion is a later B.3 brick (FR-B31-002)" >&2; return 1; }
}

# The PAIR, not the two fields separately: the validator rejects candidate with
# scaffoldable:true, and a half-flip is exactly what b9-11 had to guard against.
_test_b31_004_scaffoldable_agrees() {
  _ensure_py_cache || return 1
  local stage sc; stage="$(_get stage)"; sc="$(_get scaffoldable)"
  [ "$sc" = "False" ] \
    || { echo "    FAIL T-004: scaffoldable='$sc' != False (FR-B31-002)" >&2; return 1; }
  if [ "$stage" = "candidate" ] && [ "$sc" != "False" ]; then
    echo "    FAIL T-004: candidate with scaffoldable=$sc — forbidden by validate-foundations.sh (FR-B31-002)" >&2
    return 1
  fi
}

# ─── Layers (T-005..T-008) ───────────────────────────────────────────────────

_test_b31_005_layer_profile() {
  _ensure_py_cache || return 1
  [ "$(_get layer_profile)" = "client-only" ] \
    || { echo "    FAIL T-005: layer_profile='$(_get layer_profile)' != 'client-only' — a CLI binary has no backend and no infra surface, and declaring stub layers to satisfy the triple would be fabrication (ADR-B31-002)" >&2; return 1; }
}

_test_b31_006_two_layers() {
  _ensure_py_cache || return 1
  [ "$(_get layer_ids)" = "cli,tui" ] \
    || { echo "    FAIL T-006: layers are '$(_get layer_ids)', expected 'cli,tui' — the two surfaces archetype.schema.json's ratified description names (clap + ratatui) (FR-B31-004)" >&2; return 1; }
}

_test_b31_007_layer_fields() {
  _ensure_py_cache || return 1
  [ "$(_get layer_fields_ok)" = "True" ] \
    || { echo "    FAIL T-007: a layer is missing one of id/path/fr_id_prefix/primary_agent — validate-foundations.sh requires all four on BOTH profiles (FR-B31-004)" >&2; return 1; }
}

# The Rust sub-team is fixed by CLAUDE.md: Vulcan orchestrates, Terminal owns the TUI.
# Naming an agent that does not exist would make the schema unroutable.
_test_b31_008_layer_agents() {
  _ensure_py_cache || return 1
  local agents; agents="$(_get layer_agents)"
  [ "$agents" = "Terminal,Vulcan" ] \
    || { echo "    FAIL T-008: layer agents are '$agents', expected 'Terminal,Vulcan' — the ratified Rust sub-team (FR-B31-004)" >&2; return 1; }
}

# ─── Phases (T-009..T-011) ───────────────────────────────────────────────────

# ADR-B9-1-003, paid for once already: no scaffold-schema loader resolves `extends`.
# parseSchemaMeta reads version/stage/scaffoldable; check_versioned_schema_siblings
# reads `phases` straight from the file. A documentary `extends:` is a trap for the
# next author, so the tdd-rust chain is materialised inline instead.
_test_b31_009_no_extends_key() {
  _ensure_py_cache || return 1
  [ "$(_get has_extends)" = "False" ] \
    || { echo "    FAIL T-009: the schema declares an 'extends:' key — nothing resolves it, and b9-1 refused it for that reason (ADR-B9-1-003, FR-B31-005)" >&2; return 1; }
}

_test_b31_010_tdd_rust_chain() {
  _ensure_py_cache || return 1
  local got want="proposal,specs,features,design,tasks,implementation,review,archive"
  got="$(_get phase_ids)"
  [ "$got" = "$want" ] \
    || { echo "    FAIL T-010: phases are '$got', expected '$want' — the tdd-rust chain in order (FR-B31-005)" >&2; return 1; }
}

_test_b31_011_review_gates() {
  _ensure_py_cache || return 1
  local ok=1 checks c
  checks="$(_get review_checks)"
  for c in cargo_audit cargo_test clippy_clean coverage_rust zero_unsafe_undocumented zero_unwrap; do
    grep -qF -- "$c" <<<"$checks" \
      || { echo "    FAIL T-011: the review phase drops the '$c' gate (FR-B31-005)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

# ─── Components (T-012..T-014) ───────────────────────────────────────────────

# NEGATIVE, on a comment-stripped stream. The schema's header legitimately discusses
# versions in prose, and an unstripped grep reads that discussion as the violation —
# the T-013/T-014 trap this repository has now paid for six times.
_test_b31_012_no_resolved_pin() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-012: schema missing (see T-001)" >&2; return 1; }
  local hits
  hits=$(grep -vE '^\s*#' "$SCHEMA" | grep -nE '[0-9]+\.[0-9]+\.[0-9]+' | grep -vE 'version:\s*"?1\.0\.0' || true)
  if [ -n "$hits" ]; then
    echo "    FAIL T-012: a resolved version pin reached the schema — pins are declared by reference to their owning standard and resolved verify-then-pin at the template brick (FR-B31-006):" >&2
    head -3 <<<"$hits" | sed 's/^/      /' >&2
    return 1
  fi
}

_test_b31_013_components_declared() {
  _ensure_py_cache || return 1
  local ok=1 names c
  names="$(_get component_names)"
  for c in clap ratatui cargo-dist code-signing sbom distribution-channels; do
    grep -qF -- "$c" <<<"$names" \
      || { echo "    FAIL T-013: no '$c' component — it is part of B.3's stated surface (roadmap.md:202) (FR-B31-007)" >&2; ok=0; }
  done
  local unowned; unowned="$(_get unowned_components)"
  [ -z "$unowned" ] \
    || { echo "    FAIL T-013: component(s) with neither a standard nor a delivered_by owner: $unowned (FR-B31-007)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# Every forward pointer must name a B.3 brick. b9-1 shipped four `delivered_by: B.9.2`
# pointers and b9-2 had to resolve them; a pointer naming a module that will never run
# is a promise nobody owns.
_test_b31_014_delivered_by_is_b3() {
  _ensure_py_cache || return 1
  local bad; bad=$(tr ',' '\n' <<<"$(_get delivered_by)" | grep -vE '^B\.3\.[0-9]+$' | grep -v '^$' || true)
  [ -z "$bad" ] \
    || { echo "    FAIL T-014: delivered_by pointer(s) outside B.3: $(tr '\n' ' ' <<<"$bad") (FR-B31-007)" >&2; return 1; }
}

# ─── Header, validator, and the negatives (T-015..T-018) ─────────────────────

_test_b31_015_header_documents_the_inference() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-015: schema missing (see T-001)" >&2; return 1; }
  local head ok=1 needle
  head="$(head -45 "$SCHEMA")"
  while IFS='|' read -r needle why; do
    [ -z "$needle" ] && continue
    grep -qF -- "$needle" <<<"$head" \
      || { echo "    FAIL T-015: the header does not state '$needle' — $why (FR-B31-008)" >&2; ok=0; }
  done <<'NEEDLES'
candidate|the stage semantics a reader needs before using it
B.3.1 → B.3.14|that the plan defers to a list this repository does not contain
is therefore **inferred**|that "B.3.1 is the schema" is a precedent, not a specification — the bare word `inferred` recurs later in the header, so it would be satisfied by a sentence this needle is not testing
NEEDLES
  [ "$ok" = "1" ]
}

# The live validator, not a re-implementation of its rules here.
_test_b31_016_live_validator_pass() {
  local v="$SCRIPTS_DIR/validate-foundations.sh"
  [ -f "$v" ] || { echo "    FAIL T-016: validate-foundations.sh missing" >&2; return 1; }
  local out
  out=$(bash "$v" 2>&1 | grep -F "rust-cli-tui/1.0.0.yaml" || true)
  [ -n "$out" ] \
    || { echo "    FAIL T-016: the validator did not report on rust-cli-tui/1.0.0.yaml at all — it is not being checked (FR-B31-009)" >&2; return 1; }
  if grep -qiE 'fail|KO' <<<"$out"; then
    echo "    FAIL T-016: the live validator rejects the schema (FR-B31-009):" >&2
    head -3 <<<"$out" | sed 's/^/      /' >&2
    return 1
  fi
}

# NEGATIVE — b9-1 deliberately left the dispatch key to b9-2, because adding it flips
# `forge init` from exit 2 (unknown archetype) to exit 3 (no scaffoldable version), and
# t5-1 FR-T51-055 then demands a CLI trust fixture. Both belong to the brick that ships
# the templates.
_test_b31_017_no_dispatch_key_yet() {
  _have_py_yaml || { echo "    FAIL T-017: python3+PyYAML required" >&2; return 1; }
  python3 - "$DISPATCH" <<'PY' >&2
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
if 'rust-cli-tui' in (d.get('archetypes') or {}):
    print("    FAIL T-017: a rust-cli-tui dispatch key exists — that flips forge init from "
          "exit 2 to exit 3 and makes t5-1 FR-T51-055 demand a trust fixture, both of which "
          "belong to the template brick (NFR-B31-002)")
    raise SystemExit(1)
PY
}

# NEGATIVE — a schema brick adds a file. It must not touch a shipped archetype.
_test_b31_018_shipped_archetypes_untouched() {
  local ok=1 f
  for f in mobile-pwa-first/2.0.0.yaml ai-native-rag/1.0.0.yaml event-driven-eu/1.0.0.yaml; do
    local p="$FORGE_ROOT/.forge/schemas/$f"
    [ -f "$p" ] || { echo "    FAIL T-018: $f is missing — a schema brick must not remove one (NFR-B31-001)" >&2; ok=0; continue; }
    grep -qE '^stage: stable' "$p" \
      || { echo "    FAIL T-018: $f is no longer stable (NFR-B31-001)" >&2; ok=0; }
  done
  grep -qF '"rust-cli-tui"' "$TAXONOMY" \
    || { echo "    FAIL T-018: rust-cli-tui left archetype.schema.json's enum — it is ADR-ratified and t4.test.sh pins it (NFR-B31-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.3.1 — rust-cli-tui / 1.0.0 candidate schema ──"
  run_test _test_b31_001_schema_exists
  run_test _test_b31_002_identity
  run_test _test_b31_003_stage_candidate
  run_test _test_b31_004_scaffoldable_agrees
  run_test _test_b31_005_layer_profile
  run_test _test_b31_006_two_layers
  run_test _test_b31_007_layer_fields
  run_test _test_b31_008_layer_agents
  run_test _test_b31_009_no_extends_key
  run_test _test_b31_010_tdd_rust_chain
  run_test _test_b31_011_review_gates
  run_test _test_b31_012_no_resolved_pin
  run_test _test_b31_013_components_declared
  run_test _test_b31_014_delivered_by_is_b3
  run_test _test_b31_015_header_documents_the_inference
  run_test _test_b31_016_live_validator_pass
  run_test _test_b31_017_no_dispatch_key_yet
  run_test _test_b31_018_shipped_archetypes_untouched
  print_summary
}

main
