# Design: b8-3b-validator-versioned-schema

<!-- Status: designed -->
<!-- Schema: default -->
<!-- Audit: B.8.3.b (docs/new-archetypes-plan.md §4.2 — validator versioned-schema discovery) -->

**Agents**: Atlas (validator topology), Eris (test strategy). No runtime code;
no templates; no schema edits. **Context7**: not invoked — deliverables are
Bash script edits and a shell harness.

---

## Architecture Decisions

### ADR-B83B-001 — Discovery scope: generic across all archetype dirs (no-op elsewhere)
**Context**: Q-001 resolved (maintainer 2026-05-31, generic option). Two options:
scoped only to `full-stack-monorepo/` (current validator scope) vs generic across
every `.forge/schemas/<archetype>/` dir.
**Decision**: **Generic**. Discovery globs `<FORGE_ROOT>/.forge/schemas/*/`
and, inside each archetype dir, finds every file whose basename matches
`^[0-9]+\.[0-9]+\.[0-9]+\.yaml$`. Only `full-stack-monorepo/2.0.0.yaml` matches
today — the six other archetype dirs have only a canonical `schema.yaml` with no
versioned sibling, so discovery is a genuine **no-op** everywhere else. This
keeps B.8.3.b generic for B.9.1 (`mobile-pwa-first/2.0.0.yaml`) without a further
validator edit. The canonical `schema.yaml` of each archetype is left entirely
untouched; the `mobile-only/schema.yaml` heterogeneous shape (`archetype:` /
`schema_version:`) is never touched — it has no versioned sibling so discovery
adds zero validations there.
**Consequences**: Strict superset guaranteed: each archetype that has no versioned
sibling keeps its existing PASS/FAIL exactly as before. Future versioned siblings
(e.g. `mobile-pwa-first/2.0.0.yaml`) become visible without further validator edits.
**Compliance**: FR-B83B-001/003/004, NFR-B83B-001/005.

### ADR-B83B-002 — Helper placement: localize in `validate-foundations.sh` only; `verify.sh` and `constitution-linter.sh` unchanged
**Context**: Q-002 resolved (maintainer 2026-05-31, localize-where-deep-validation-happens).
Re-read of all three validators (cited line numbers, Article III.4):

| Script | What it does with the schema path | Deep-validates? |
|---|---|---|
| `validate-foundations.sh:91-153` | `check_schema_full_stack_monorepo()` — full python3 parse: name/SemVer/stage/triple/phases | **YES — the only deep validator** |
| `verify.sh:83-98` | `resolve_layer_path()` — reads `schema.yaml` to extract a layer's `path` field for scoped Article VI/VII re-runs; emits a bare path string, never pass/fail | **NO — path resolution only** |
| `constitution-linter.sh:69-83` | `resolve_monorepo_path()` — identical purpose: reads `schema.yaml` to resolve a layer path for scoped Article VI/VII re-runs | **NO — path resolution only** |

Only `validate-foundations.sh` deep-validates. `verify.sh` and
`constitution-linter.sh` use `schema.yaml` purely for layer-path resolution and
MUST NOT be changed — they have no validation logic to extend, and touching them
would enlarge blast radius without adding gate coverage. Discovery + invariant
logic goes in **one place only**: inside `check_schema_full_stack_monorepo()` in
`validate-foundations.sh`, after the existing `schema.yaml` validation block.
No shared sourced helper is needed (only one file changes; a helper for a single
consumer would be an over-abstraction). The sibling-harness coupling lesson is
satisfied by NOT duplicating logic, not by adding a shared file.
**Decision**: Add a new `check_versioned_schema_siblings()` function to
`validate-foundations.sh`, called from `main()` immediately after
`check_schema_full_stack_monorepo`. `verify.sh` and `constitution-linter.sh`
are **byte-unchanged**.
**Consequences**: Minimal blast radius — only one script modified; the two
path-resolution helpers in `verify.sh`/`constitution-linter.sh` keep resolving
from `schema.yaml` as today. The `validate-foundations.sh` output already flows
into `verify.sh` via its `PASS:`/`FAIL:` aggregation loop (`verify.sh:385-391`),
so new PASS/FAIL lines from the versioned-sibling check are automatically surfaced
in `verify.sh` output with zero change to `verify.sh`.
**Compliance**: FR-B83B-002/013/020/021/022, NFR-B83B-001/002/004.

### ADR-B83B-003 — Invariant placement: inside the per-file validation path, strict superset
**Context**: The existing `check_schema_full_stack_monorepo()` python3 block
(lines 98-152) validates: mapping root, `name`, SemVer `version`, layers
(non-empty, ids ⊇ {backend,frontend,infra}, each layer has
id/path/fr_id_prefix/primary_agent), `stage` enum, `stable⇒version≥1.0.0` no
prerelease, non-empty `phases`. This exact rule-set MUST be applied to each
versioned sibling.
**Decision**: The new `check_versioned_schema_siblings()` function iterates over
discovered `<X.Y.Z>.yaml` files and passes each through the **same python3
validation logic** as `schema.yaml`, expressed as a reusable heredoc in the new
function. Additionally, for each versioned file it enforces:
1. **Filename↔version** — `basename == version_field + ".yaml"` (e.g. `2.0.0.yaml`
   must declare `version: "2.0.0"`).
2. **Candidate invariant** — if `stage == "candidate"` then `scaffoldable` MUST
   be present and equal `False` (Python boolean). `stage` `draft` and `stable` are
   not subject to this check, so the frozen `schema.yaml` (stable, no
   `scaffoldable` field) keeps validating unchanged.
Both new invariants are enforced in the same python3 block as the existing
name/SemVer/stage rules, so a versioned file is held to a **strict superset** of
the `schema.yaml` rule-set with no divergent code path.
**Compliance**: FR-B83B-002/010/011/012/013, NFR-B83B-001.

### ADR-B83B-004 — Scaffolder guard DEFERRED to B.8.14 (decided non-goal)
**Context**: Q-003 resolved by independent reviewer 2026-05-31, option (a).
Reviewer independently confirmed via live code:
- `cli/src/cli.ts:213-226` — `resolveFrameworkVersion()` hard-codes the literal
  `"schema.yaml"` path component:
  ```
  const schemaPath = resolve(assets, ".forge/schemas", archetype, "schema.yaml");
  ```
  It reads this file only to extract `version:` for upgrade tracking. It never
  reads any `X.Y.Z.yaml` file.
- `cli/src/commands/init-archetype.ts` — dispatches by archetype name to a
  per-archetype wrapper shell script via the dispatch table. Reads NO schema file
  at all; the wrapper script handles scaffolding from the snapshot tarball.
- `cli/src/commands/init.ts` — routes to `init-archetype.ts` or the default
  scaffolder; reads NO `schemas/<archetype>/schema.yaml`.
**Decision**: No scaffolder code change in B.8.3.b. The scaffolder cannot
materialize a versioned or `scaffoldable: false` schema today. Enforcement in
B.8.3.b is the **validator invariant** (`stage: candidate ⇒ scaffoldable: false`
must be present in the candidate file, enforced by `validate-foundations.sh`).
The **runtime selection guard** — preventing `forge init` from ever selecting a
non-scaffoldable schema — lands at **B.8.14**, when `2.0.0.yaml` is promoted to
`stable` and the scaffolder gains versioned-schema selection.
**Compliance**: FR-B83B-040/041, NFR-B83B-001.

---

## Exact Discovery Mechanism

### Where it runs

`validate-foundations.sh` gains one new function `check_versioned_schema_siblings()`
called from `main()` after `check_schema_full_stack_monorepo` (line 382 today).
No other file is modified.

### The loop

```bash
check_versioned_schema_siblings() {
  local schemas_dir="$FORGE_ROOT/.forge/schemas"
  # Iterate every archetype dir under .forge/schemas/
  for arch_dir in "$schemas_dir"/*/; do
    [ -d "$arch_dir" ] || continue
    local archetype
    archetype="$(basename "$arch_dir")"
    # Find versioned siblings: files named X.Y.Z.yaml (SemVer filename)
    for versioned in "$arch_dir"[0-9]*.[0-9]*.[0-9]*.yaml; do
      [ -f "$versioned" ] || continue          # glob matched nothing → skip
      local basename_file
      basename_file="$(basename "$versioned")"
      # Validate with the same rule-set as schema.yaml + 2 new invariants.
      local result
      result=$(python3 - "$versioned" "$archetype" "$basename_file" <<'PY'
import sys, re, yaml
path, expected_name, filename = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f"KO: YAML parse error: {e}"); sys.exit(0)

if not isinstance(data, dict):
    print("KO: schema root is not a mapping"); sys.exit(0)

# Existing rule 1: name == archetype dir name (generalised from hard-coded check)
if data.get('name') != expected_name:
    print(f"KO: name mismatch (got {data.get('name')!r}, expected {expected_name!r})"); sys.exit(0)

# Existing rule 2: version matches SemVer
version = data.get('version')
if not isinstance(version, str) or not re.match(r'^\d+\.\d+\.\d+(-[\w.-]+)?$', version):
    print(f"KO: version does not match SemVer (got {version!r})"); sys.exit(0)

# NEW invariant 1: filename X.Y.Z.yaml must agree with declared version
expected_version = filename[:-5]  # strip ".yaml"
if version != expected_version:
    print(f"KO: filename/version mismatch: filename implies {expected_version!r} but version={version!r}"); sys.exit(0)

# Existing rule 3: layers present, ids ⊇ {backend, frontend, infra}
layers = data.get('layers')
if not isinstance(layers, list) or not layers:
    print("KO: layers missing or empty"); sys.exit(0)
layer_ids = {l.get('id') for l in layers if isinstance(l, dict)}
required = {'backend', 'frontend', 'infra'}
if not required.issubset(layer_ids):
    missing = sorted(required - layer_ids)
    print(f"KO: layers must include at least backend, frontend, infra (missing: {missing})"); sys.exit(0)
for layer in layers:
    for key in ('id', 'path', 'fr_id_prefix', 'primary_agent'):
        if key not in layer:
            print(f"KO: layer {layer.get('id','?')!r} missing field {key!r}"); sys.exit(0)

# Existing rule 4: stage enum
stage = data.get('stage')
if stage not in ('draft', 'candidate', 'stable'):
    print(f"KO: stage must be one of draft/candidate/stable (got {stage!r})"); sys.exit(0)

# Existing rule 5: stable ⇒ version ≥ 1.0.0 no prerelease
if stage == 'stable':
    m = re.match(r'^(\d+)\.(\d+)\.(\d+)(-.*)?$', version)
    if not m or int(m.group(1)) < 1 or m.group(4):
        print(f"KO: stage=stable requires version >= 1.0.0 without prerelease (got {version!r})"); sys.exit(0)

# Existing rule 6: phases non-empty
phases = data.get('phases')
if not isinstance(phases, list) or not phases:
    print("KO: phases missing or empty"); sys.exit(0)

# NEW invariant 2: candidate ⇒ scaffoldable: false
# (stable and draft are NOT subject to this check — frozen schema.yaml is stable,
#  has no scaffoldable field, and must keep validating unchanged)
if stage == 'candidate':
    scaffoldable = data.get('scaffoldable')
    if scaffoldable is not False:
        print(f"KO: stage=candidate requires scaffoldable: false (got {scaffoldable!r})"); sys.exit(0)

print(f"OK: versioned schema {version} stage={stage} layers={sorted(layer_ids)}")
PY
      )
      local fr_tag="FR-GL-001-versioned:${archetype}/${basename_file}"
      if [[ "$result" == OK:* ]]; then
        pass_fr "$fr_tag" "${result#OK: }"
      else
        fail_fr "$fr_tag" "${archetype}/${basename_file}: ${result#KO: }"
      fi
    done
  done
}
```

The bash glob `"$arch_dir"[0-9]*.[0-9]*.[0-9]*.yaml` matches filenames whose
first character is a digit and that contain at least two dots before `.yaml`.
If no versioned file exists in an archetype dir, the glob expands to the literal
pattern, `[ -f "$versioned" ]` is false, and `continue` fires — zero
pass/fail lines emitted for that dir. `main()` gains one call:

```bash
main() {
  check_schema_full_stack_monorepo   # unchanged — line 382 today
  check_standard_monorepo_layout     # unchanged
  ...
  check_multi_layer_change_metadata  # unchanged
  check_versioned_schema_siblings    # NEW — appended last
  finalize
}
```

### FR tag convention

Each versioned-sibling check emits a `PASS:`/`FAIL:` line with FR tag
`FR-GL-001-versioned:<archetype>/<X.Y.Z>.yaml` so it is distinct from the
canonical `FR-GL-001` tag (which covers `schema.yaml`) and aggregates cleanly
into `verify.sh`'s existing `PASS:`/`FAIL:` loop (`verify.sh:385-391`).

**Namespace reconciliation (decided — option a).** The runtime tag deliberately
**extends `FR-GL-001`** (the existing schema-validation requirement in
`validate-foundations.sh`) rather than coining an `FR-B83B-*` runtime tag:
versioned-schema validation IS the FR-GL-001 concern applied to versioned
siblings, in the same script, so a `FR-GL-001-versioned:` suffix reads as "the
FR-GL-001 rule-set, for this versioned file". The `FR-B83B-*` ids remain the
**spec requirements** of this change (they mandate the new behaviour and are the
traceability anchors); the emitted line uses the FR-GL family because that is
the validator's established output namespace. This avoids leaking a
change-scoped id (`FR-B83B-*`) into a permanent validator's stdout contract.
ADR-B83B-003 records this.

---

## The Three Invariants — Precise Specification

### Invariant 0 (existing, applied to versioned files)
All existing `check_schema_full_stack_monorepo` rules apply to each versioned
file with `name` generalised to `archetype dir name` (not hard-coded
`'full-stack-monorepo'`):
- Root is a YAML mapping.
- `name == <archetype directory name>`.
- `version` matches `^\d+\.\d+\.\d+(-[\w.-]+)?$`.
- `layers` non-empty list; ids ⊇ `{backend, frontend, infra}`; each layer has
  `id`, `path`, `fr_id_prefix`, `primary_agent`.
- `stage ∈ {draft, candidate, stable}`.
- `stage == stable ⇒ version ≥ 1.0.0`, no prerelease suffix.
- `phases` is a non-empty list.

### Invariant 1 — Filename ↔ version (NEW)
A versioned file named `X.Y.Z.yaml` MUST declare `version: "X.Y.Z"`. Implemented
as: `expected_version = filename[:-5]` (strip `.yaml`), assert
`version == expected_version`. A mismatch (e.g. `2.0.0.yaml` with
`version: "2.1.0"`) emits `KO: filename/version mismatch`.

### Invariant 2 — Candidate ⇒ `scaffoldable: false` (NEW)
Applied **only when `stage == "candidate"`**. `draft` and `stable` are
explicitly excluded. Check: `data.get('scaffoldable') is not False` → fail.
This means:
- `scaffoldable: false` (Python `False`) → PASS.
- `scaffoldable: true` → FAIL.
- `scaffoldable` field absent → FAIL (`None is not False`).
- `stage: stable` with no `scaffoldable` field → PASS (check not reached).
- `stage: draft` with no `scaffoldable` field → PASS (check not reached).

The frozen `schema.yaml` (`stage: stable`, no `scaffoldable` field) passes
because it is validated by `check_schema_full_stack_monorepo`, not by
`check_versioned_schema_siblings`. Even if it were discovered, `stable` bypasses
Invariant 2. It is not a versioned-filename file (it is named `schema.yaml`), so
the filename glob never matches it.

---

## Backward-Compatibility Proof

The dominant risk is NFR-B83B-001: the change MUST be a strict superset.

| Path | Today | After B.8.3.b | Why unchanged |
|---|---|---|---|
| `full-stack-monorepo/schema.yaml` | Validated by `check_schema_full_stack_monorepo` → PASS | Same function, unmodified → PASS | Function body byte-unchanged |
| `full-stack-monorepo/2.0.0.yaml` | Not validated (invisible) | Discovered; passes all rules (name=full-stack-monorepo ✓, version=2.0.0 ✓, filename matches ✓, stage=candidate+scaffoldable:false ✓, layers triple ✓, phases ✓) → PASS | Live file already satisfies all invariants |
| `default/schema.yaml` | Not validated by these scripts | No versioned sibling → 0 new checks | Glob finds nothing |
| `ai-first/schema.yaml` | Not validated | No versioned sibling → 0 new checks | Glob finds nothing |
| `mobile-only/schema.yaml` | Not validated (`archetype:`/`schema_version:` shape) | No versioned sibling → 0 new checks | Glob finds nothing; heterogeneous shape never touched |
| `rapid/schema.yaml` | Not validated | No versioned sibling → 0 new checks | Glob finds nothing |
| `tdd-flutter/schema.yaml` | Not validated | No versioned sibling → 0 new checks | Glob finds nothing |
| `tdd-rust/schema.yaml` | Not validated | No versioned sibling → 0 new checks | Glob finds nothing |
| `verify.sh` behaviour | Aggregates `validate-foundations.sh` PASS/FAIL lines | Same aggregation loop; new PASS lines for `2.0.0.yaml` added automatically | `verify.sh` byte-unchanged (`verify.sh:385-391`) |
| `constitution-linter.sh` behaviour | Uses `schema.yaml` for layer-path resolution only | Same path, same resolution | Byte-unchanged |

Exit-code semantics: `finalize()` exits 0 iff `FAIL==0`. Before B.8.3.b, the
versioned file was invisible (no FAIL, no PASS for it). After B.8.3.b, it adds
one PASS line. If it were to fail an invariant, it would add one FAIL and cause
exit 1 — the intended gate behaviour.

---

## `b8-3b.test.sh` Test Strategy (Eris)

**File**: `.forge/scripts/tests/b8-3b.test.sh`
**Level**: L1 only (hermetic, ≤ 5 s, zero net/Docker, mirrors `b8-3.test.sh`
conventions: `--level` flag, `source _helpers.sh`, `run_test` + `print_summary`).
**Role**: The gate for B.8.3.b. Asserts that after the validator rewiring:
1. Discovery finds `2.0.0.yaml` and it passes all rules.
2. Both new invariants are enforced (positive + negative via tmp fixtures).
3. Backward-compat: single-`schema.yaml` archetypes pass unchanged; frozen
   `schema.yaml` still passes; `verify.sh` + `validate-foundations.sh` still
   emit PASS on the live tree.

**Negative fixtures**: The harness creates synthetic YAML fixtures in a `mktemp`
directory and points a `FORGE_ROOT`-overridden invocation of
`validate-foundations.sh` at them to assert that malformed versioned files cause
a FAIL exit. Real schema files are **never mutated**. The tmp dir is removed by a
`trap ... EXIT`.

### L1 Assertion List

| # | FR/NFR | Description | Mechanism |
|---|---|---|---|
| T-001 | FR-B83B-001 | `check_versioned_schema_siblings` function is present in `validate-foundations.sh` | `grep -qF 'check_versioned_schema_siblings'` |
| T-002 | FR-B83B-001 | `check_versioned_schema_siblings` is called from `main()` | `grep -qF 'check_versioned_schema_siblings' validate-foundations.sh` (function def + call, count ≥ 2) |
| T-003 | FR-B83B-002/003 | Live `validate-foundations.sh` exits 0 on the real FORGE_ROOT (schema.yaml + 2.0.0.yaml both pass) | `bash validate-foundations.sh`; assert exit 0 |
| T-004 | FR-B83B-002 | Output of T-003 contains a PASS line for `2.0.0.yaml` discovery | `assert_contains` on stdout: `PASS: FR-GL-001-versioned:full-stack-monorepo/2.0.0.yaml` |
| T-005 | NFR-B83B-003 | Frozen `schema.yaml` still passes (FR-GL-001 PASS line present) | `assert_contains` on T-003 stdout: `PASS: FR-GL-001` (the canonical check) |
| T-006 | NFR-B83B-001 | `verify.sh` exits 0 on the live tree (backward-compat — aggregation of new PASS line doesn't break it) | `bash verify.sh`; assert exit 0 |
| T-007 | FR-B83B-010 | **Negative — filename/version mismatch FAILS**: fixture `full-stack-monorepo/2.0.0.yaml` with `version: "2.1.0"` | tmp FORGE_ROOT; assert stdout contains the **specific** line `FAIL: FR-GL-001-versioned:full-stack-monorepo/2.0.0.yaml` with a filename/version-mismatch message (NOT bare exit code — other FR-GL checks also FAIL on a partial tree, so the assertion MUST target the versioned line) |
| T-008 | FR-B83B-011 | **Negative — candidate without `scaffoldable: false` FAILS**: fixture `full-stack-monorepo/3.0.0.yaml`, `stage: candidate`, NO `scaffoldable` | tmp FORGE_ROOT; assert stdout contains `FAIL: FR-GL-001-versioned:full-stack-monorepo/3.0.0.yaml` with a `scaffoldable`-related message (discriminating — not bare exit/`FAIL:`) |
| T-009 | FR-B83B-011 | **Negative — candidate with `scaffoldable: true` FAILS**: fixture `3.0.0.yaml`, `stage: candidate`, `scaffoldable: true` | tmp FORGE_ROOT; assert stdout contains `FAIL: FR-GL-001-versioned:full-stack-monorepo/3.0.0.yaml` with the `scaffoldable` message (discriminating) |
| T-010 | FR-B83B-012 | **Positive — stable schema without `scaffoldable` passes**: fixture `3.0.0.yaml`, `stage: stable`, no `scaffoldable` | tmp FORGE_ROOT; assert stdout contains `PASS: FR-GL-001-versioned:full-stack-monorepo/3.0.0.yaml` AND does NOT contain a `FAIL: FR-GL-001-versioned:...3.0.0.yaml` line (assert on the versioned line, NOT process exit — unrelated FR-GL-002..018 may FAIL on a partial tree) |
| T-011 | FR-B83B-004 | **No-op for single-`schema.yaml` archetypes**: a tmp archetype dir with only `schema.yaml` (no versioned sibling) emits zero versioned-discovery lines | tmp FORGE_ROOT with a fresh archetype dir; assert output contains NO `FR-GL-001-versioned:fresh-arch` line (PASS or FAIL) |
| T-012 | NFR-B83B-003 | Frozen `schema.yaml` (1.0.0) byte-identity preserved | `grep -qx 'version: "1.0.0"' .forge/schemas/full-stack-monorepo/schema.yaml` (the file carries `version: "1.0.0"`; no tarball involved — the b8-2 snapshot tarball is out of scope for this change) |
| T-013 | FR-B83B-032 | Harness is registered in `forge-ci.yml` harness array (one-line entry) | `grep -qF 'b8-3b.test.sh' .github/workflows/forge-ci.yml` |

**13 L1 tests.** Performance budget: T-003/T-006 run live validators (Bash + python3 `yaml.safe_load` only, ≤ 2 s each per existing NFR-002 budgets). Fixture tests (T-007..T-011) create/destroy tmp dirs with `mktemp`; no network, no Docker.

### Fixture structure for negative tests

Each negative-fixture test constructs a tmp FORGE_ROOT containing:
- `.forge/schemas/full-stack-monorepo/schema.yaml` — copy of the real frozen
  `schema.yaml` (unchanged; so `check_schema_full_stack_monorepo` at
  `validate-foundations.sh:91-153` finds the schema-file it gates on at
  `validate-foundations.sh:93`).
- `.forge/schemas/full-stack-monorepo/<X.Y.Z>.yaml` — the synthetic bad file.
- No `.forge/changes/` dir (so `check_multi_layer_change_metadata` skips cleanly).

**Discriminating assertions (critical).** This tmp tree is NOT fully populated,
so unrelated checks (FR-GL-002..018: missing standards/index/VERSIONING) also
FAIL and the process exits 1 regardless of the versioned-schema invariant.
Therefore the negative tests MUST NOT assert on the bare process exit code or a
bare `FAIL:` substring — both would pass even if `check_versioned_schema_siblings`
were absent. They assert on the **specific** `FAIL: FR-GL-001-versioned:<arch>/<file>`
line (and its message), which is emitted **only** by the new function. This
requires the function to emit a distinct, greppable line per versioned file:
`PASS: FR-GL-001-versioned:<arch>/<file>` when all invariants hold, else
`FAIL: FR-GL-001-versioned:<arch>/<file> — <reason>` (one of: filename/version
mismatch, candidate-without-scaffoldable-false). The shared fixture helper is
used across T-007..T-011.

**Prerequisite.** B.8.3.b depends on commit `6175a61` (the FR-GL-017
dict-`layers` crash fix): before it, `validate-foundations.sh` exited 1 mid-run
and the new `check_versioned_schema_siblings` (appended last in `main()`) would
have been dead code on the live tree, and T-003/T-006 ("exits 0 on live tree")
would have been unsatisfiable. With `6175a61` landed, `validate-foundations.sh`
exits 0 standalone and the new check runs — so this design's backward-compat
proof and live-tree tests hold.

### TDD Order (Article I RED → GREEN)

1. **RED**: commit `b8-3b.test.sh` with all 13 assertions. Run — T-001 and T-002
   fail immediately (function does not yet exist in `validate-foundations.sh`);
   T-003's exit 0 expectation fails (no versioned sibling validated); T-004
   fails (no PASS line for `2.0.0.yaml`); T-007..T-009 fail (no FAIL emitted for
   bad fixtures — the validator is unaware of them). T-005, T-006, T-010..T-013
   may pass or fail depending on state.
2. **GREEN**: author `check_versioned_schema_siblings()` in
   `validate-foundations.sh` + add the call in `main()` + add CI registration.
   Re-run — all 13 pass.
3. **REFACTOR**: tighten error messages, confirm ≤ 5 s wall-clock.

### Performance Budget

All assertions use `bash` + `python3 yaml.safe_load` + file-existence checks.
No network, no Docker, no subprocess chains beyond single Python invocations.
Target: ≤ 3 s on a laptop (well within the 5 s NFR budget).

---

## Component Design

```
validate-foundations.sh
  ├── check_schema_full_stack_monorepo()   [UNCHANGED — validates schema.yaml]
  ├── check_standard_monorepo_layout()     [UNCHANGED]
  ├── check_standard_proto_contracts()     [UNCHANGED]
  ├── check_standard_docker_compose()      [UNCHANGED]
  ├── check_git_workflow_scoped_commits()  [UNCHANGED]
  ├── check_versioning_monorepo_section()  [UNCHANGED]
  ├── check_index_new_entries()            [UNCHANGED]
  ├── check_standard_multi_layer_workflow()[UNCHANGED]
  ├── check_multi_layer_change_metadata()  [UNCHANGED]
  └── check_versioned_schema_siblings()    [NEW — B.8.3.b]
        ├── glob .forge/schemas/*/[0-9]*.yaml
        ├── for each match: python3 validate (Inv0 + Inv1 + Inv2)
        └── emit PASS/FAIL: FR-GL-001-versioned:<arch>/<X.Y.Z>.yaml

verify.sh                                  [UNCHANGED]
  └── aggregates validate-foundations.sh PASS/FAIL lines via existing loop
      → new PASS line for 2.0.0.yaml appears automatically (verify.sh:385-391)

constitution-linter.sh                     [UNCHANGED]
  └── resolve_monorepo_path() reads schema.yaml for layer-path resolution only
      → no deep validation → no change needed

b8-3b.test.sh                              [NEW]
  ├── T-001..T-002: function present + called in main()
  ├── T-003..T-006: live-tree PASS (validate-foundations + verify)
  ├── T-007..T-011: negative + positive fixtures (tmp FORGE_ROOT)
  ├── T-012: frozen schema.yaml byte-check
  └── T-013: CI registration check

forge-ci.yml harness array                 [ONE LINE ADDED]
  └── "b8-3b.test.sh --level 1"  (after "b8-3.test.sh --level 1")
```

---

## Standards Applied

| Standard | Role in this change |
|---|---|
| `global/forge-self-ci.md` | Harness registration (one-line array entry, NFR-CI-002) |
| `global/upgrade-policy.md` | Backward-compat constraint (shared validators = shared infra, sibling-harness coupling lesson) |

**Standards NOT touched**: no `*.yaml` standard is edited by B.8.3.b. No
`REVIEW.md` ledger entry required. No schema file edited. `git diff --name-only`
MUST show only: `validate-foundations.sh` (new function + `main()` call),
`b8-3b.test.sh` (new harness), `forge-ci.yml` (one array line), change dir
artifacts.

---

## FR-B83B-* → Design Element Traceability

| FR/NFR | Design element |
|---|---|
| FR-B83B-001 | `check_versioned_schema_siblings()` glob + loop; ADR-B83B-001 |
| FR-B83B-002 | Same python3 rule-set (Inv0) applied per versioned file; ADR-B83B-003 |
| FR-B83B-003 | `name == archetype dir name` (generalised); python3 `expected_name` arg |
| FR-B83B-004 | `[ -f "$versioned" ] || continue` no-op branch; backward-compat table |
| FR-B83B-010 | Invariant 1 (filename↔version); T-007 negative |
| FR-B83B-011 | Invariant 2 (candidate⇒scaffoldable:false); T-008/T-009 negatives |
| FR-B83B-012 | Invariant 2 only applies when `stage=='candidate'`; T-010 positive |
| FR-B83B-013 | Both invariants inside same python3 block as Inv0; ADR-B83B-003 |
| FR-B83B-020 | `validate-foundations.sh` only (ADR-B83B-002); `verify.sh`/`constitution-linter.sh` unchanged |
| FR-B83B-021 | `verify.sh:385-391` aggregation loop unchanged; new PASS lines flow through automatically |
| FR-B83B-022 | `resolve_layer_path` / `resolve_monorepo_path` byte-unchanged |
| FR-B83B-030 | `b8-3b.test.sh` 13 L1 assertions; T-007..T-009 negative fixtures |
| FR-B83B-031 | TDD order: RED (harness committed first, validators unmodified) → GREEN |
| FR-B83B-032 | One-line entry `"b8-3b.test.sh --level 1"` in `forge-ci.yml` harness array |
| FR-B83B-040 | No scaffolder code change; ADR-B83B-004 |
| FR-B83B-041 | Runtime guard deferred to B.8.14; `cli.ts:213-226` + `init-archetype.ts` cited |
| FR-B83B-042 | Plan §4.2 B.8.3.b text update from "Proposed" to committed; implementation deliverable |
| NFR-B83B-001 | Backward-compat table; ADR-B83B-002 (only `validate-foundations.sh` changed) |
| NFR-B83B-002 | Full CI matrix GREEN before flip; independent reviewer re-execution required |
| NFR-B83B-003 | `schema.yaml` and `2.0.0.yaml` byte-unchanged (neither file touched by B.8.3.b) |
| NFR-B83B-004 | `validate-foundations.sh` < 2 s NFR-002 preserved; `b8-3b.test.sh` ≤ 5 s |
| NFR-B83B-005 | Generic discovery (ADR-B83B-001): archetype dir name from path, not hard-coded |
| NFR-B83B-006 | Anti-hallucination: every cited line re-read; `constitution-linter.sh:69` is path-resolution not deep-validation (corrected from b8-3 framing) |

---

## Constitutional Compliance Gate

- **Article I (TDD RED-first)**: `b8-3b.test.sh` is committed with all 13
  assertions BEFORE the `check_versioned_schema_siblings()` function exists.
  T-001/T-002 fail RED immediately. The validator rewiring is then authored;
  all 13 turn GREEN. The RED witness is the commit gap.
- **Article II (BDD)**: no new user-facing runtime feature. The Gherkin scenario
  in `specs.md` provides traceability; no `.feature` file required.
- **Article III.1/III.2 (Specs before code)**: design follows specs; validator
  edit authored only after this design.
- **Article III.4 (Anti-Hallucination)**: every path/line cited verified by
  live file read. Key finding: `constitution-linter.sh:69` (`resolve_monorepo_path`)
  is **layer-path resolution only**, not deep validation — this is why only
  `validate-foundations.sh` needs modification (ADR-B83B-002). The b8-3 design's
  description of `validate-foundations.sh:271-281` as an "env.example check" is
  confirmed incorrect (it is `check_multi_layer_change_metadata`, lines 269-354);
  this correction is now stable across both design documents. `cli/src/cli.ts:213-226`
  cited as the closing evidence for ADR-B83B-004 (scaffolder hardcodes `"schema.yaml"`).
- **Article IV (Delta-based)**: `validate-foundations.sh` gains one new function
  and one `main()` call. `verify.sh` and `constitution-linter.sh` are
  byte-unchanged. No file is rewritten or deprecated.
- **Article X (Quality)**: `b8-3b.test.sh` covers the discovery + invariant
  contract with 13 L1 assertions including negative fixture tests.
- **Article XII (Governance)**: no Constitution amendment. VIII.1/VIII.2
  amendments land with the actual bump at B.8.14.

**No violations. Gate PASS.**

---

## Anti-Hallucination Pass (Design Phase)

- **`validate-foundations.sh` line span for `check_multi_layer_change_metadata`**:
  re-read confirms lines 269-354 (not "271-281" as the b8-3 design's framing
  stated). The function body runs from line 269 to 354; the python3 heredoc
  starts at line 278. Corrected in this document.
- **`constitution-linter.sh:67-83` — `resolve_monorepo_path`**: re-read confirms
  this function reads `schema.yaml` only to extract a layer's `path` field for
  scoped re-runs. It emits a bare path string (no `pass`/`fail` call). Deep
  validation of any schema file is not performed here. This is the decisive
  evidence for ADR-B83B-002 (localize in `validate-foundations.sh` only).
- **`verify.sh:83-98` — `resolve_layer_path`**: same pattern — reads `schema.yaml`
  for layer-path resolution only. Byte-unchanged.
- **`cli/src/cli.ts:213-226` — `resolveFrameworkVersion`**: re-read confirms
  `resolve(assets, ".forge/schemas", archetype, "schema.yaml")` — the literal
  string `"schema.yaml"` is hard-coded. No versioned path is ever constructed.
  This closes Q-003.
- **`cli/src/commands/init-archetype.ts`**: re-read confirms it reads the dispatch
  table and passes a `scaffolderPath` to an `ArchetypeRunner`. No schema YAML file
  is read. The dispatch table (`dispatch-table.yml`) contains archetype names and
  wrapper script paths; it does not reference `schema.yaml` or any versioned schema.
- **`2.0.0.yaml` invariant check**: re-read of live `2.0.0.yaml` confirms
  `name: full-stack-monorepo`, `version: "2.0.0"`, `stage: candidate`,
  `scaffoldable: false`, layers `{backend, frontend, infra}` each with
  `id/path/fr_id_prefix/primary_agent`, non-empty `phases`. All invariants
  satisfied → T-003/T-004/T-005 will pass GREEN immediately after the function
  is authored.
- **"One of them (mobile-only)" correction**: There is exactly **one** archetype
  whose `schema.yaml` uses a heterogeneous shape (`archetype:`/`schema_version:`
  instead of `name:`/`version:`/`stage:`): `mobile-only`. Not "two" as an earlier
  draft stated. Corrected here and in the specs/proposal nit-fixes below.
- **Harness CI registration**: `forge-ci.yml:68-109` re-read confirms the
  declarative `harnesses=( … )` bash array; `b8-3.test.sh --level 1` is the last
  entry (line 108). The new entry `"b8-3b.test.sh --level 1"` appends on line 109.

---

## Nit-Fixes to specs.md / proposal.md (reviewer LOW findings)

The following LOW citation errors from the independent reviewer are corrected
in-place in `specs.md` and `proposal.md` as part of this design pass (Article IV
delta-based corrections; no requirement changes):

1. **"reads no tarball"** — `init-archetype.ts` dispatches to a per-archetype
   wrapper shell script, not to a tarball directly. The tarball is managed by the
   snapshot mechanism (`b8-2`), not read by the TypeScript CLI. `specs.md`
   Source Documents row for "Scaffolder reality" corrected.
2. **`cli.ts:213-226` citation** — added as the explicit closing evidence for
   ADR-B83B-004 in both documents.
3. **`validate-foundations.sh` function span** — `check_multi_layer_change_metadata`
   runs lines 269-354 (not "271-281"). Corrected in specs.md Source Documents and
   proposal.md Problem section.
4. **"One of them (mobile-only)"** — only one archetype (`mobile-only`) uses a
   heterogeneous shape, not "two". Corrected in specs.md and proposal.md.
5. **Q-003 resolution evidence** — `cli.ts:213-226` + `init-archetype.ts`
   dispatch-table evidence cited explicitly in both documents.

---

## Author Note

This is an **author-only** design pass. Per the constitutional Author/Reviewer
separation (and the T5.2 self-validation lesson), this design MUST be validated
by an **INDEPENDENT reviewer** before `/forge:plan`. The author does not
self-approve.
