<!-- Audit: B.8.10 (b8-10-migrate-flagship) -->
# Tasks: b8-10-migrate-flagship

TDD-ordered. Migration orchestrator `bin/forge-migrate-flagship.sh` (bash-thin +
Python-inline, set -uo pipefail) sourcing `forge-upgrade.sh` and reusing the
`_a7_*` library (ADR-B810-001). Exit envelope `0/2/5/7/8` aligned to A.7
(ADR-B810-002). Doc-only CLI surface — no TS commander registration (ADR-B810-003).
Ledger: wrap `_a7_append_upgrade_history` with `_b810_tag_last_history_kind`,
`forge-upgrade.sh` byte-unchanged (ADR-B810-004). Phase 2 canary document-only
(ADR-B810-005). Five `[VERIFY AT IMPLEMENT]` carry items resolved LIVE before any
script line is authored (b8-coroot lesson). 9 `[NEEDS CLARIFICATION:]` markers in
specs.md neutralized pre-flip (b8-9 precedent). Full ~49-harness suite GREEN before
push (NFR-B810-003). POST-flip gates re-run (b8-coroot lesson). Independent review
required before `/forge:archive` (NFR-B810-009, T5.2 lesson).

---

## Phase 0 — Verify-then-pin LIVE re-execution (Article III.4 + b8-coroot lesson)

Each carry item is a live on-disk re-read that produces evidence; falsification
MUST surface as `[NEEDS CLARIFICATION: <detail>]` + STOP rather than proceeding
with a stale assumption. Append every result to `evidence.md` with file:line
provenance and a one-line summary of what it proves (source-document-pinning.md).

- [x] **T001** Re-read `bin/forge-upgrade.sh` lines ~1-30 (docblock) to confirm
  the exit-code envelope is still `0/2/5/7/8` (ADR-B810-002 grounds itself on
  P-01). Re-read lines ~387-389 (or the current equivalent) to confirm the
  `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` sourcing guard protecting `_a7_main` from
  running on `source` is still present (ADR-B810-001 grounds itself on P-03).
  Record the exact line numbers + the guard text as evidence (P-01-recheck /
  P-03-recheck). If the guard has been removed or the exit envelope has changed,
  emit `[NEEDS CLARIFICATION: forge-upgrade.sh sourcing guard or exit envelope
  changed — ADR-B810-001/002 require re-evaluation]` and STOP.
  [Story: ADR-B810-001, ADR-B810-002, FR-B810-003, FR-B810-005, Article III.4]

- [x] **T002** Re-read the 2.0.0 template-set at
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/` to confirm: (a) the
  file count is still 27 (P-13-recheck); (b) `grep -ril 'dbos'` over that tree
  returns exit code 1 — zero DBOS files (P-14-recheck); (c) `_a7_check_version_compat`
  is NOT called by any file in that directory. Record the exact count + grep rc as
  evidence. If the count has changed or any DBOS file is found, emit
  `[NEEDS CLARIFICATION: 2.0.0 template-set changed from 27 files or DBOS file
  detected — ADR-B810-001/FR-B810-032 require re-evaluation]` and STOP.
  [Story: ADR-B810-001, FR-B810-030, FR-B810-032, NFR-B810-008, Article III.4]

- [x] **T003** Verify the frozen 1.0.0 snapshot is present and byte-intact:
  (a) confirm `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` exists
  and its sha256 matches the companion
  `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` (expected:
  `8d439b942bf81dbcc103e010d946504035dd410f613b31f673d7d691c3224ca9`, P-11);
  (b) confirm `b8-2.test.sh --level 1` exits 0 (byte-identity guard). Record the
  computed sha256 + the b8-2 exit code as evidence (P-11-recheck). If the sha256
  does not match or b8-2 fails, STOP — do NOT proceed with a corrupted BASE.
  [Story: FR-B810-012, FR-B810-041, NFR-B810-004, ADR-B810-001]

- [x] **T004** Re-read `_a7_append_upgrade_history` (forge-upgrade.sh:144-187 or
  current lines) to confirm the function signature and Python-inline block shape
  (P-08-recheck): positional parameters `<manifest> <from> <to> <from_sha>
  <to_sha> <unc> <upg> <prs> <cnf> <skp> <cli_v>`, appends to `upgrade_history`
  list, uses `yaml.safe_dump(default_flow_style=False, sort_keys=True)`, does NOT
  touch identity fields (`project_name`, `reverse_domain`, `root_module`). Also
  re-read `_a7_check_force_clean_git` (P-04-recheck), `_a7_classify` (P-06-recheck),
  and `_a7_three_way_merge` (P-05-recheck) to confirm they remain sourceable with
  no argument changes. Record each function's current signature + location as
  evidence. If any signature has changed, emit `[NEEDS CLARIFICATION: _a7_*
  function signature changed — ADR-B810-001/004 require re-evaluation]` and STOP.
  [Story: ADR-B810-001, ADR-B810-004, FR-B810-060, FR-B810-061, FR-B810-062,
   Article III.4]

- [x] **T005** Re-read `examples/forge-fsm-example/.forge/scaffold-manifest.yaml`
  (or any live 1.0.0 scaffold target) to confirm the manifest shape (P-18-recheck):
  `archetype: full-stack-monorepo`, `archetype_version: 1.0.0`, `project_name`,
  `reverse_domain`, `root_module`, `scaffold_date`, `template_set_sha`,
  `upgrade_history` list. Confirm the schema layer paths used to map 2.0.0 relpaths
  to target relpaths (P-16-recheck: `backend/`, `frontend/`, `infra/`, `shared/`).
  Record both as evidence. If the manifest structure has changed materially, emit
  `[NEEDS CLARIFICATION: scaffold-manifest shape changed — Phase 0 manifest read
  and ledger append require re-evaluation]` and STOP.
  [Story: FR-B810-010, FR-B810-060, FR-B810-061, ADR-B810-001, Article III.4]

---

## Phase 1 — Harness RED

Author `b8-10.test.sh` with all ~12 L1 assertions before the script, MIGRATIONS.md
section, or CHANGELOG entry exist. Run immediately to confirm the RED baseline.
T-010 (frozen sha256 guard) and T-011 (b8-2/b8-3 coupling) may pass immediately
as their targets already exist — record which tests pass and which fail.

- [x] **T006** Author `.forge/scripts/tests/b8-10.test.sh` (~12 L1 hermetic
  tests; mirror b8-9.test.sh structure: `--level` flag, `source _helpers.sh`,
  `run_test`, `print_summary`; `set -uo pipefail`; HARNESS_DIR / FORGE_ROOT
  detection pattern). Include all twelve assertions per design.md Testing Strategy
  table (T-001..T-012):
  - **T-001** (FR-B810-001/071): `bin/forge-migrate-flagship.sh` exists (`-f`) +
    executable (`-x`) + `grep -qF 'Audit: B.8.10 (b8-10-migrate-flagship)'` in
    script body + `grep -qF 'set -uo pipefail'` in script body. Any missing
    element is a FAIL.
  - **T-002** (FR-B810-002/008): `out=$(bash $SCRIPT --help); rc=$?; [ $rc -eq 0 ]
    && grep -qF '--target' <<<"$out"` — help exits 0 and mentions `--target`
    plus the `0/2/5/7/8` exit-code table.
  - **T-003** (FR-B810-006/NFR-B810-001): zero new dep guard — grep the script
    body for `command -v` or invocations of non-allowed binaries (`npm`, `cargo`,
    `pub`, `docker`); only `git`, `python3`, `tar`, `shasum`/`sha256sum` are
    allowed. A match on a non-listed binary is a FAIL.
  - **T-004** (FR-B810-014/072/NFR-B810-010): create ephemeral fixture via
    `mktemp -d`; write a valid `scaffold-manifest.yaml` (`archetype:
    full-stack-monorepo`, `archetype_version: 1.0.0`) into
    `<fixture>/.forge/scaffold-manifest.yaml`; `git init -q <fixture>`;
    run `bash $SCRIPT --target <fixture> --dry-run`; assert exit 0; assert
    `git -C <fixture> status --porcelain` is empty after the run. Clean up
    `<fixture>` in a trap. A mutation or non-zero exit is a FAIL.
  - **T-005** (FR-B810-005/073): four exit-code sub-assertions with ephemeral
    fixtures — (a) no `--target` → exit 2; (b) `--help` → exit 0; (c) `--target
    <dir-with-archetype_version-0.9.0>` → exit 7; (d) `--phase 3` with a
    valid 1.0.0 target → exit 0 (forward-reference stub). Each uses a fresh
    ephemeral fixture cleaned in a trap.
  - **T-006** (FR-B810-032/074/NFR-B810-008): no-DBOS static grep —
    `grep -v '^[[:space:]]*#' $SCRIPT | grep -iE 'dbos'` → zero matches. A
    match is a FAIL (constitutional no-DBOS guard: VIII.2, FR-B810-032).
  - **T-007** (FR-B810-031/075/NFR-B810-007): additive-only static grep —
    `grep -nE '\b(rm|rmdir)\b' $SCRIPT | grep -iE 'kong|temporal|rest'` → zero
    matches. A match is a FAIL (constitutional additive invariant: VIII.1,
    FR-B810-031).
  - **T-008** (FR-B810-040/041/076): rollback-path grep — `grep -qF
    'scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz' $SCRIPT` → must match
    (rollback sources the frozen snapshot); plus `grep -nE
    '>[[:space:]]*.*scaffold-snapshots|tar -c.*scaffold-snapshots' $SCRIPT` →
    zero matches (script NEVER writes to scaffold-snapshots/). Either check
    failing is a FAIL.
  - **T-009** (FR-B810-050/051/077): MIGRATIONS.md battery — assert all of:
    (1) `grep -qE '1\.0\.0.*2\.0\.0|2\.0\.0.*1\.0\.0' docs/MIGRATIONS.md`;
    (2) `grep -qF 'forge-migrate-flagship' docs/MIGRATIONS.md`;
    (3) `grep -qE 'scaffoldable.*false|false.*scaffoldable' docs/MIGRATIONS.md`;
    (4) `grep -qF 'B.8.13' docs/MIGRATIONS.md` (rollback criteria xref);
    (5) `grep -vE '^[[:space:]]*#' docs/MIGRATIONS.md | grep -qi 'dbos'` →
    zero matches in rollback-criteria context.
    Any sub-assertion failing is a FAIL.
  - **T-010** (FR-B810-012/077/NFR-B810-004): frozen snapshot guard — assert
    `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` exists and
    contains `8d439b942bf81dbcc103e010d946504035dd410f613b31f673d7d691c3224ca9`;
    assert `1.0.0.tar.gz` exists alongside it. A missing file or wrong digest is
    a FAIL.
  - **T-011** (FR-B810-078/NFR-B810-003): coupling guards — `bash
    .forge/scripts/tests/b8-2.test.sh --level 1 >/dev/null 2>&1` exits 0 +
    `bash .forge/scripts/tests/b8-3.test.sh --level 1 >/dev/null 2>&1` exits 0.
    A failure in either is a b8-10 FAIL.
  - **T-012** (FR-B810-007/078/NFR-B810-005): SOURCE_DATE_EPOCH determinism
    (static) + L2 opt-in — L1 static: `grep -qF 'SOURCE_DATE_EPOCH' $SCRIPT`
    must match (ledger wrapper consumes the env var). L2 env-gate gated on
    `FORGE_B8_10_LIVE=1` (pattern from b8-1.test.sh `FORGE_B8_1_DOCKER=1`):
    when set, create a temporary 1.0.0 scaffold fixture (via `forge init` or
    equivalent), run `bash $SCRIPT --target <fixture> --dry-run`, assert exit 0
    and no file mutation. When unset, emit `SKIP: FORGE_B8_10_LIVE not set` and
    return 0 (not a FAIL).
  L1 budget ≤ 2 s (NFR-B810-002). Zero network, Docker, or live `forge init` at L1.
  [Story: FR-B810-070, FR-B810-071, FR-B810-072, FR-B810-073, FR-B810-074,
   FR-B810-075, FR-B810-076, FR-B810-077, FR-B810-078, NFR-B810-001,
   NFR-B810-002]

- [x] **T007** Run `bash .forge/scripts/tests/b8-10.test.sh --level 1` → verify
  RED baseline. RESULT: 2 PASS (T-010 frozen sha256, T-011 b8-2/b8-3 coupling),
  10 FAIL (T-001..T-009, T-012-L1). L1 ≤ 2 s (0.71 s). Matches design baseline. Expected fail: T-001..T-009, T-012-L1 (no script, no MIGRATIONS.md
  section, no CHANGELOG entry). Expected pass: T-010 (frozen sha256 already
  present), T-011 (b8-2/b8-3 already GREEN before any edit). Record the exact
  pass/fail counts; if T-010 or T-011 are RED, STOP and investigate before Phase 2.
  [Story: FR-B810-070, Article I RED]

---

## Phase 2 — GREEN: script skeleton (G1)

Create `bin/forge-migrate-flagship.sh` with shebang, audit header, docblock,
`set -uo pipefail`, source guard, and arg-parse while/case. Wire the exit envelope.
No phase functions yet — just the skeleton that makes T-001, T-002, T-003, T-005
sub-assertions (a)(b) green.

- [x] **T008** Create `bin/forge-migrate-flagship.sh` with:
  (a) Shebang + audit header + docblock (FR-B810-002):
      ```
      #!/usr/bin/env bash
      # Forge — `forge-migrate-flagship` 1.0.0 → 2.0.0 flagship migration orchestrator
      # <!-- Audit: B.8.10 (b8-10-migrate-flagship) -->
      #   Usage: bash bin/forge-migrate-flagship.sh --target <dir> [flags]
      #   Exit-codes: 0 success | 2 usage error | 5 missing tool |
      #               7 precondition not met | 8 overlay conflicts (ADR-B810-002)
      #   Determinism: SOURCE_DATE_EPOCH consumed via os.environ.get() in ledger wrapper
      #   Pattern: bash-thin + Python 3 inline; mirrors bin/forge-sbom.sh / bundle.sh
      ```
  (b) `set -uo pipefail` as the first executable statement (FR-B810-003).
  (c) `SCRIPT_DIR` + `FORGE_REPO_ROOT` detection (same pattern as forge-upgrade.sh):
      ```
      SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      FORGE_REPO_ROOT="${FORGE_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
      TPL_20="$FORGE_REPO_ROOT/.forge/templates/archetypes/full-stack-monorepo/2.0.0"
      SNAP="$FORGE_REPO_ROOT/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
      SNAP_SHA="$FORGE_REPO_ROOT/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256"
      ```
  (d) `source "$SCRIPT_DIR/forge-upgrade.sh"` with a `# shellcheck source=` annotation
      (ADR-B810-001 — sourcing is safe; the `_a7_main` guard confirmed at T001).
  (e) `err()` helper + `usage()` heredoc covering: synopsis (`--target <dir>` +
      all flags), the `0/2/5/7/8` exit-code table, reference to `docs/MIGRATIONS.md`
      (FR-B810-008).
  (f) Tool preflight: `command -v git python3 tar >/dev/null ||
      { err "required tools missing: git python3 tar"; exit 5; }` (exit-5 per
      ADR-B810-002/P-01 alignment).
  (g) Arg-parse via `while/case` (bundle.sh shape, P-19):
      `--target <dir>` (required; absent → `err "..." ; usage; exit 2`);
      `--dry-run` (sets `DRY_RUN=1`); `--phase <0|1|2|all>` (default `all`);
      `--force` (sets `FORCE=1`); `--rollback` (sets `ROLLBACK=1`);
      `--help` / `-h` (prints usage, exit 0); unknown flag → `err`; exit 2.
      After arg-parse: if `--rollback` and `--phase` both set (and `--phase != all`),
      emit `forge-migrate-flagship: --phase ignored with --rollback (full-snapshot
      restore only)` to stderr (ADR-B810-002).
  (h) Tail: `rc=$?; exit $rc` (P-19 envelope tail).
  Make executable: `chmod +x bin/forge-migrate-flagship.sh`.
  [Story: FR-B810-001, FR-B810-002, FR-B810-003, FR-B810-004, FR-B810-005,
   FR-B810-006, FR-B810-008, ADR-B810-001, ADR-B810-002]

- [x] **T009** Run `bash .forge/scripts/tests/b8-10.test.sh --level 1` → confirm
  T-001, T-002, T-003 are now GREEN. Confirm T-005 sub-assertions (a) `no --target
  → exit 2` and (b) `--help → exit 0` are GREEN. Record the new pass count.
  [Story: FR-B810-001, FR-B810-002, FR-B810-003, FR-B810-004, FR-B810-005,
   FR-B810-008]

- [x] **T010** Run `bash bin/forge-migrate-flagship.sh --help` and confirm the
  output contains: `--target`, `0/2/5/7/8`, and `docs/MIGRATIONS.md`. Confirm
  `bash bin/forge-migrate-flagship.sh` (no args) exits 2. Confirm `bash
  bin/forge-migrate-flagship.sh --unknown-flag` exits 2.
  [Story: FR-B810-004, FR-B810-005, FR-B810-008]

---

## Phase 3 — GREEN: Phase 0 preflight (G2)

Implement `_b810_phase0_preflight <target>` using the live-verified shapes from
T001-T005. This makes T-004 (dry-run no-mutation) and T-005 sub-assertion (c)
(non-1.0.0 target → exit 7) green.

- [x] **T011** Implement `_b810_phase0_preflight()`:
  (a) Manifest read (Python-inline `<<'PY'` heredoc; P-18 shape):
      open `<target>/.forge/scaffold-manifest.yaml` via `yaml.safe_load`; assert
      `archetype == 'full-stack-monorepo'` and `archetype_version == '1.0.0'`;
      on any failure emit `forge-migrate-flagship: preflight: <category>: <msg>`
      to stderr (FR-B810-013 structured pattern) and exit 7. Distinct messages for:
      manifest missing, wrong archetype, wrong archetype_version.
  (b) Git-clean gate: call sourced `_a7_check_force_clean_git "$TARGET"` unless
      `FORCE=1`; on dirty-tree failure emit the structured `forge-migrate-flagship:
      preflight: dirty-git: ...` message and exit 7 (FR-B810-011/013). With `--force`,
      skip the check.
  (c) Snapshot sha256 verify: compute sha256 of `$SNAP` (using `shasum -a 256` or
      `sha256sum`; platform-detect as in b8-2.test.sh); compare to `$SNAP_SHA`
      content; on mismatch emit `forge-migrate-flagship: preflight: snapshot-sha256:
      expected <E> actual <A>` and exit 7 (FR-B810-012/013).
  (d) `--dry-run` gate: after all assertions, if `DRY_RUN=1`, print a structured
      plan to stdout — target path, from-version 1.0.0, to-version 2.0.0, phases
      to run, list of the 5 additive deltas (Kong→Envoy, REST→Connect, Zitadel,
      Qwik, pg17+pgvector) — then return 0 without mutation (FR-B810-014).
  No file in `<target>` is written by this function under any code path.
  [Story: FR-B810-010, FR-B810-011, FR-B810-012, FR-B810-013, FR-B810-014,
   ADR-B810-001, ADR-B810-002]

- [x] **T012** Run the harness: `bash .forge/scripts/tests/b8-10.test.sh --level 1`
  → T-004 (dry-run fixture) and T-005(c) (non-1.0.0 → exit 7) must now be GREEN.
  Confirm T-005(d) (`--phase 3` → exit 0) is still pending (Phase 3/4 stub not
  yet implemented). Record pass count.
  [Story: FR-B810-010, FR-B810-011, FR-B810-012, FR-B810-013, FR-B810-014]

- [x] **T013** Manual smoke: create a temp dir with no manifest, invoke `--target
  <empty-dir>` → confirm exit 7 and stderr contains `forge-migrate-flagship:
  preflight: manifest`. Create a dir with `archetype_version: 0.9.0`, invoke →
  confirm exit 7 and stderr contains `archetype_version`. Create a dir with a
  valid 1.0.0 manifest but a dirty git tree (touch a new file), invoke without
  `--force` → confirm exit 7 and stderr contains `dirty-git`. With `--force` →
  confirm it proceeds past the git check. Invoke `--dry-run` on the clean 1.0.0
  fixture → exit 0, stdout mentions the 5 deltas, `git status --porcelain` shows
  no changes.
  [Story: FR-B810-010, FR-B810-011, FR-B810-013, FR-B810-014, NFR-B810-010]

---

## Phase 4 — GREEN: Phase 1 idempotent + Phase 2 overlay (G3+G4)

Implement `_b810_phase1_obs_contracts <target>` (assert-or-noop) and
`_b810_phase2_overlay <target>` (additive 3-way merge via sourced `_a7_*`).
Wire Phase 3/4 stubs. Uses P-05/P-06/P-10/P-13/P-16 from T004-T005 evidence.

- [x] **T014** Implement `_b810_phase1_obs_contracts()` (FR-B810-020/021/022):
  Check whether the obs trio (B.8.8 OTel / SigNoz / Coroot markers) and Connect
  codegen overlays (B.8.6) are already present in the target. Detection predicate:
  grep for known sentinel files or manifest markers (the exact predicate from
  ADR-B810-001 — assert-or-apply via `_a7_classify`). If all expected markers are
  present, print `[Phase 1] obs/contracts: all present (no-op)` and return 0
  (idempotent). If any is absent and `DRY_RUN=1`, print the missing items and
  return 0 (no mutation, FR-B810-022). If absent and not dry-run, apply the missing
  overlay via `_a7_classify` + copy/merge path. Idempotent invariant: running twice
  on a target with all markers present produces zero diff.
  [Story: FR-B810-020, FR-B810-021, FR-B810-022, ADR-B810-001]

- [x] **T015** Implement `_b810_phase2_overlay()` (FR-B810-030..036):
  (a) Extract BASE: `base_dir=$(mktemp -d); trap "rm -rf $base_dir" EXIT;
      tar -xzf "$SNAP" -C "$base_dir"` (P-10/P-11 shape; FR-B810-040's snapshot is
      read-only — NEVER written).
  (b) Walk RIGHT: `find "$TPL_20" -type f | sort | while read -r right_abs; do
      rel="${right_abs#$TPL_20/}"; tgt_rel="$(_b810_map_relpath "$rel")"` — strip
      the `2.0.0/` prefix and apply schema layer mapping (P-16; `backend/`,
      `frontend/`, `infra/`, `shared/`).
  (c) Per-file classify: `cls=$(_a7_classify "$TARGET/$tgt_rel"
      "$base_dir/$tgt_rel" "$TPL_20/$rel")` (P-06 sourced; P-05 for merge).
      `case $cls in unchanged) C_UNC++;; upgraded) ...cp and C_UPG++;; preserved)
      C_PRS++;; merge_candidate) _a7_three_way_merge ... && C_UPG++ || ...
      C_CNF++;; conflict_2way) force? cp:C_UPG++ : C_CNF++;; esac`.
  (d) Additive-only invariant: the loop MUST NOT contain `rm`, `rmdir`, or
      destructive `mv` on any Kong, Temporal, or REST-bridge path (FR-B810-031;
      static-checked by T-007). The 2.0.0 RIGHT has zero DBOS files (P-14) so no
      DBOS reference enters any apply path (FR-B810-032; static-checked by T-006).
  (e) Canary guidance: after the loop, print a `[Phase 2] canary cutover:` note
      block directing the adopter to the manual Kong→Envoy per-route process in
      `docs/MIGRATIONS.md` (ADR-B810-005; FR-B810-034). No per-route config
      is generated.
  (f) Conflicts gate: `if [ "$C_CNF" -gt 0 ] && [ "${FORCE:-0}" != "1" ]; then
      err "phase 2: $C_CNF conflict(s) — re-run with --force to overwrite";
      exit 8; fi` (ADR-B810-002 exit-8 alignment).
  (g) `--dry-run` fast-path at entry of function: if `DRY_RUN=1`, print the
      per-delta plan (files to create/merge) without modifying any file and return 0
      (FR-B810-035). No mutation ever occurs in dry-run.
  [Story: FR-B810-030, FR-B810-031, FR-B810-032, FR-B810-033, FR-B810-034,
   FR-B810-035, ADR-B810-001, ADR-B810-002]

- [x] **T016** Implement `_b810_map_relpath()` helper (inline bash): strips the
  leading path component from 2.0.0 template relpaths and returns the corresponding
  adopter project relpath (P-16 layer map). Example: `2.0.0/frontend/web-public/...`
  → `frontend/web-public/...`; `2.0.0/infra/k8s/...` → `infra/k8s/...`.
  The function strips only the `2.0.0/` prefix (first path component); the remainder
  is the adopter-project relpath unchanged (P-16 shows the layer names are the same
  in the 2.0.0 tree and in the adopter's tree).
  [Story: ADR-B810-001, FR-B810-030]

- [x] **T017** Implement `_b810_phase34_stub()` (FR-B810-036): `case "$1" in
  3) echo "[Phase 3] T7 new archetypes — forward reference: see docs/MIGRATIONS.md
  Phase 3 stub."; exit 0;;
  4) echo "[Phase 4] T8 deprecation plan — forward reference: see docs/MIGRATIONS.md
  Phase 4 stub."; exit 0;; esac`. Wire into the phase dispatch so `--phase 3`
  and `--phase 4` both reach this stub and exit 0.
  [Story: FR-B810-036, FR-B810-052]

- [x] **T018** Wire phase dispatch: after arg-parse + tool preflight:
  `if [ "${ROLLBACK:-0}" = "1" ]; then _b810_phase0_preflight; _b810_rollback;
   else _b810_phase0_preflight; case "$PHASE" in
     0) ;; 1) _b810_phase1_obs_contracts;; 2) _b810_phase2_overlay;;
     all) _b810_phase1_obs_contracts; _b810_phase2_overlay;;
     3|4) _b810_phase34_stub "$PHASE";; *) err "unknown --phase value"; exit 2;;
   esac; fi` (Phase 0 always runs first as the precondition gate).
  [Story: FR-B810-004, FR-B810-036, ADR-B810-002]

- [x] **T019** Run `bash .forge/scripts/tests/b8-10.test.sh --level 1` → T-005(d)
  (`--phase 3` → exit 0) must now be GREEN. Confirm T-006 (no-DBOS grep) and T-007
  (additive-only grep) are GREEN against the implemented body. Record pass count.
  [Story: FR-B810-030, FR-B810-031, FR-B810-032, FR-B810-036]

---

## Phase 5 — GREEN: rollback (G5)

Implement `_b810_rollback()`. Makes T-008 fully green (rollback path grep + no
snapshot write).

- [x] **T020** Implement `_b810_rollback()` (FR-B810-040..043):
  (a) Verify snapshot sha256 before restore: same check as Phase 0 FR-B810-012.
      If the sha256 mismatches, emit `forge-migrate-flagship: rollback: snapshot-sha256
      mismatch — refusing restore to prevent corruption` and exit 7.
  (b) `--dry-run` fast-path: if `DRY_RUN=1`, print `[Rollback] restore plan:
      source=$SNAP sha256=<digest> target=$TARGET` and exit 0 (FR-B810-043;
      no file modification).
  (c) Live restore: `tar -xzf "$SNAP" -C "$TARGET"` (P-11 shape). The script MUST
      NOT write to `$SNAP` or `$SNAP_SHA` under any code path (FR-B810-041; static-
      checked by T-008 no-snapshot-write grep). After restore exit 0.
  (d) Help text for `--rollback` MUST include a cross-reference to B.8.13 for
      rollback criteria and explicitly note that DBOS-CPU is removed per B8O
      (FR-B810-042). This is in the `usage()` function under the `--rollback` line.
  [Story: FR-B810-040, FR-B810-041, FR-B810-042, FR-B810-043, ADR-B810-002]

- [x] **T021** Run `bash .forge/scripts/tests/b8-10.test.sh --level 1` → T-008
  (rollback path grep + no snapshot write) must now be GREEN. Record pass count.
  [Story: FR-B810-040, FR-B810-041, FR-B810-076]

---

## Phase 6 — GREEN: ledger wrapper + MIGRATIONS.md + CHANGELOG (G6+G7)

Implement `_b810_tag_last_history_kind`, author the `docs/MIGRATIONS.md`
1.0.0→2.0.0 section, and add the CHANGELOG entry. Makes T-009 and T-012-L1 green.

- [x] **T022** Implement `_b810_tag_last_history_kind()` (ADR-B810-004):
  A thin Python-inline wrapper that: (a) opens `<manifest>` via `yaml.safe_load`;
  (b) stamps `kind: flagship-migration` onto the LAST entry of `upgrade_history`;
  (c) if `SOURCE_DATE_EPOCH` is set via `os.environ.get("SOURCE_DATE_EPOCH")`,
  override the `date` field of that entry with
  `datetime.utcfromtimestamp(int(SOURCE_DATE_EPOCH)).isoformat() + 'Z'`
  (P-19 pattern; FR-B810-007/NFR-B810-005); (d) `yaml.safe_dump` back to the
  same file using `default_flow_style=False, sort_keys=True` (P-08 dump shape).
  This function is called from `_b810_phase2_overlay` AFTER `_a7_append_upgrade_history`
  completes, ONLY when `DRY_RUN=0`. It MUST NOT modify any field other than `kind`
  and (when `SOURCE_DATE_EPOCH` set) `date` on the last entry, and MUST NOT touch
  `project_name`, `reverse_domain`, or `root_module` (FR-B810-061).
  Wire the call into the tail of `_b810_phase2_overlay`: `_a7_append_upgrade_history
  "$manifest" "1.0.0" "2.0.0" "$from_sha" "$to_sha" "$C_UNC" "$C_UPG" "$C_PRS"
  "$C_CNF" "$C_SKP" "$CLI_VERSION"; _b810_tag_last_history_kind "$manifest"`.
  [Story: FR-B810-060, FR-B810-061, FR-B810-062, FR-B810-007, ADR-B810-004,
   NFR-B810-005]

- [x] **T023** Author (or expand) `docs/MIGRATIONS.md` with the `## 1.0.0 → 2.0.0`
  section (A.7 deferred stub fill; FR-B810-050). The section MUST include at minimum:
  (a) **4-phase walkthrough** — Phase 0 preflight (manifest + git-clean + snapshot
      sha256), Phase 1 obs+contracts (assert-or-noop), Phase 2 structural overlay
      (additive: Kong→Envoy, REST→Connect, Zitadel, Qwik, pg17+pgvector — additive
      only; Kong/Temporal/REST preserved until B.8.14), Phase 3/4 forward-reference
      stubs;
  (b) **Additive-first posture statement**: "Kong, Temporal, and REST-bridge
      templates are preserved. B.8.14 performs the breaking removal and the
      VIII.1/VIII.2 Constitution amendment.";
  (c) **B8O no-DBOS note**: "The `temporal-intent → dbos-embedded` migration delta
      is cancelled (B8O / ADR-B8O-001). Temporal is retained as the Rust
      orchestrator. This script does NOT scaffold, run, or reference DBOS.";
  (d) **Rollback criteria cross-reference (B.8.13)**: "See B.8.13 for full rollback
      runbook. Criteria: p99 +>20% after Envoy → rollback Kong; traceparent errors
      >1% → rollback OTel SDK only. (DBOS-CPU criterion removed per B8O.)";
  (e) **Stay-on-1.0.0 option**: "Adopters may remain on 1.0.0 until T8 / B.8.14.
      No forced migration occurs. The 2.0.0 candidate is `scaffoldable: false`
      until B.8.14.";
  (f) **`scaffoldable: false` caveat**: "`forge init` continues to scaffold the
      1.0.0 template until B.8.14.";
  (g) **Invocation guidance** (ADR-B810-003 doc-only): "Run:
      `bash bin/forge-migrate-flagship.sh --target . --dry-run` to inspect the
      migration plan before applying." (`forge-migrate-flagship` sentinel for T-009
      assertion (2); FR-B810-051/053);
  (h) **Canary by-route section** (ADR-B810-005): document the manual Kong→Envoy
      per-route canary process with example `HTTPRoute` weight snippets; note that
      Envoy SecurityPolicy/JWT OIDC wiring is deferred to B.8.12;
  (i) **Phase 3/4 stubs** (FR-B810-052): `## Phase 3 — T7 new archetypes (forward
      reference — not yet delivered)` + `## Phase 4 — T8 deprecation (forward
      reference — not yet delivered)`.
  The `forge-migrate-flagship` token must appear at least once (T-009 assertion (2);
  FR-B810-051). The `scaffoldable.*false` pattern must appear (T-009 assertion (3);
  FR-B810-054). The `B.8.13` token must appear (T-009 assertion (4); FR-B810-042).
  No `dbos` in rollback-criteria context (T-009 assertion (5)).
  [Story: FR-B810-050, FR-B810-051, FR-B810-052, FR-B810-053, FR-B810-054,
   FR-B810-034, FR-B810-036, FR-B810-042, ADR-B810-003, ADR-B810-005]

- [x] **T024** Append a `## [Unreleased]` entry to `CHANGELOG.md` summarising the
  B.8.10 deliverables: `bin/forge-migrate-flagship.sh` (phased orchestrator — Phase
  0/1/2 executable, Phase 3/4 forward-ref stubs; bash-thin + Python-inline; sources
  forge-upgrade.sh `_a7_*` library; exit `0/2/5/7/8`; flags `--target --phase
  --dry-run --force --rollback --help`; additive-only — Kong/Temporal/REST
  preserved; no DBOS; rollback from frozen 1.0.0 snapshot; `upgrade_history` +
  `kind: flagship-migration`), `docs/MIGRATIONS.md` 1.0.0→2.0.0 section,
  harness `b8-10.test.sh`. Entry MUST contain the string `b8-10-migrate-flagship`
  (T-012 / harness T-009 CHANGELOG anchor — changelog-test [Unreleased] coupling
  lesson: grep whole file, NOT bare "B.8.10"). Mirrors B.8.9 CHANGELOG precedent.
  [Story: FR-B810-077, NFR-B810-001]

- [x] **T025** Run `bash .forge/scripts/tests/b8-10.test.sh --level 1` → T-009
  (MIGRATIONS.md battery) and the L1 part of T-012 (`grep -qF 'SOURCE_DATE_EPOCH'
  $SCRIPT`) must now be GREEN. Check the CHANGELOG anchor: confirm `grep -qF
  'b8-10-migrate-flagship' CHANGELOG.md` passes. Record pass count.
  [Story: FR-B810-050, FR-B810-051, FR-B810-052, FR-B810-053, FR-B810-054,
   FR-B810-007, NFR-B810-001]

---

## Phase 7 — GREEN: forge-ci.yml registration (G8)

Register `b8-10.test.sh` in CI. Makes T-011 coupling guard stable.

- [x] **T026** Append `"b8-10.test.sh --level 1"` as a one-line entry to the
  `harnesses=()` loop in `.github/workflows/forge-ci.yml` after the
  `"b8-9.test.sh --level 1"` line (currently line 114). Verify the CI file
  stays within the NFR-CI-002 ≤ 300-line budget (count lines after the append).
  [Story: FR-B810-070, NFR-CI-002]

---

## Phase 8 — Harness 12/12 GREEN + L2 opt-in

- [x] **T027** Run `bash .forge/scripts/tests/b8-10.test.sh --level 1` → must
  exit 0 with all 12/12 GREEN. Record the full output. Any failure is a
  constitutional violation (Article V). Confirm:
  - T-001 (exists + exec + audit header + set -uo pipefail) GREEN
  - T-002 (--help exit 0 + --target mention) GREEN
  - T-003 (zero new dep) GREEN
  - T-004 (dry-run fixture no mutation) GREEN
  - T-005 (exit envelope: no-target→2, help→0, non-1.0.0→7, phase-3→0) GREEN
  - T-006 (no-DBOS grep) GREEN
  - T-007 (additive-only grep) GREEN
  - T-008 (rollback path + no snapshot write) GREEN
  - T-009 (MIGRATIONS.md battery) GREEN
  - T-010 (frozen sha256 guard) GREEN
  - T-011 (b8-2/b8-3 coupling) GREEN
  - T-012-L1 (SOURCE_DATE_EPOCH static grep) GREEN
  [Story: FR-B810-070..078, NFR-B810-001, NFR-B810-002, Article V]

- [x] **T028** L2 opt-in validation (`FORGE_B8_10_LIVE=1`): if `forge init` and
  the full toolchain are available, run `FORGE_B8_10_LIVE=1 bash
  .forge/scripts/tests/b8-10.test.sh --level 2` and confirm the L2 block
  (a) scaffolds a temporary 1.0.0 fixture, (b) runs `--dry-run` against it,
  (c) asserts exit 0 and no file mutation. If the toolchain is unavailable,
  confirm the L2 block emits `SKIP: FORGE_B8_10_LIVE not set` when unset and
  contribute 0 failures — record as skip-pass. Do NOT block on toolchain absence.
  [Story: FR-B810-078, NFR-B810-005, ADR-B810-001]

---

## Phase 9 — Gates + sibling safety + wrap-up

Run all gates. A partial sweep is insufficient — sibling scans can break silently
(`full_harness_suite_before_push` + `shared-standard sibling-harness coupling`
project memory lessons). Repo-wide scans MUST skip `N.N.N/` versioned subtrees.

- [x] **T029** Run `bash .forge/scripts/validate-change-yaml.sh
  .forge/changes/b8-10-migrate-flagship/.forge.yaml` → must exit 0. Record output.
  [Story: Article V]

- [x] **T030** Run `bash bin/verify.sh` → must exit 0 (PASS). Record output.
  [Story: Article V]

- [x] **T031** Run `bash bin/constitution-linter.sh` → must exit 0. Record output.
  [Story: Article V]

- [x] **T032** Run `bash .forge/scripts/tests/b8-2.test.sh --level 1` → exit 0
  (confirms frozen `1.0.0.tar.gz` + `1.0.0.sha256` are byte-unchanged — B.8.10
  added no files to `scaffold-snapshots/`; NFR-B810-004). Record output.
  [Story: NFR-B810-004, FR-B810-041]

- [x] **T033** Run `bash .forge/scripts/tests/b8-3.test.sh --level 1` → exit 0
  (schema invariants unaffected; B.8.10 touches no schema file). Record output.
  [Story: NFR-B810-003]

- [x] **T034** Sibling scan: grep all harnesses in `.forge/scripts/tests/` for
  any that reference `forge-upgrade.sh` or `MIGRATIONS.md` or `forge-migrate-flagship`
  (new script name). For each harness found: confirm it still exits 0 after
  B.8.10 additions. Run any affected harness and record its exit code. A
  regression in a sibling harness is a blocker (shared-standard sibling-harness
  coupling lesson).
  [Story: NFR-B810-003, `shared-standard sibling-harness coupling` lesson]

- [x] **T035** Run the FULL ~49-harness suite (all `*.test.sh` in
  `.forge/scripts/tests/`). Verify each harness exits 0 or is marked as expected-fail
  in `forge-ci.yml`. Pay attention to any harness whose repo-wide scan might pick
  up the new `bin/forge-migrate-flagship.sh` or the new `docs/MIGRATIONS.md` section
  (delivery.test.sh, a7.test.sh, b8-1.test.sh, b8o.test.sh). Versioned `N.N.N/`
  subtrees are exempt from repo-wide scans per the scaffolding.md convention.
  Any regression is a blocker.
  [Story: NFR-B810-003]

- [x] **T036** Neutralize the 9 `[NEEDS CLARIFICATION:]` markers in `specs.md`
  that were resolved by the ADRs (design phase) and by Phase 0 live evidence.
  Reword each marker to `Resolved by ADR-B810-NNN: <summary>; see evidence.md
  P-XX` (b8-9 precedent: no open `[NEEDS CLARIFICATION:]` in finalized specs
  before status flip to `implemented`). Do NOT modify plan files
  (`.omc/plans/*.md`). Map per open-questions.md anchor table:
  - `(Q-002 → ADR-B810-002)` exit envelope → "Resolved by ADR-B810-002: 0/2/5/7/8 aligned to A.7"
  - `(Q-002 → ADR-B810-002)` --rollback/--phase → "Resolved by ADR-B810-002: mutually exclusive; warn if both passed"
  - `(Q-004 → ADR-B810-001)` overlay engine → "Resolved by ADR-B810-001: source forge-upgrade.sh, reuse _a7_*"
  - `(Q-004 → ADR-B810-001)` Phase 1 detection predicate → "Resolved by ADR-B810-001: assert-or-apply via _a7_classify"
  - `(Q-004 → ADR-B810-001)` per-delta file set → "Resolved by ADR-B810-001: 27-file 2.0.0 RIGHT walk (P-13)"
  - `(Q-003 → ADR-B810-004)` ledger kind marker → "Resolved by ADR-B810-004: wrap _a7_append_upgrade_history with _b810_tag_last_history_kind"
  - `(Q-005 → ADR-B810-005)` canary → "Resolved by ADR-B810-005: document-only in MIGRATIONS.md"
  - `(Q-001 → ADR-B810-003)` CLI surface → "Resolved by ADR-B810-003: doc-only; TS subcommand deferred to B.8.15"
  - `(Q-002 → ADR-B810-002)` rollback restore scope → "Resolved by ADR-B810-002: full-tree restore from frozen snapshot"
  [Story: Article III.4, FR-B810-036]

- [x] **T037** Flip `.forge/changes/b8-10-migrate-flagship/.forge.yaml` status
  `planned → implemented` AND add `timeline.implemented: <YYYY-MM-DD>`.
  **Re-run POST-flip gates immediately after the flip** (b8-coroot lesson: gates
  must be re-run AFTER the flip, not trusted from the pre-flip run). Re-run at
  minimum: `b8-10.test.sh --level 1`, `b8-2.test.sh --level 1`,
  `b8-3.test.sh --level 1`, `validate-change-yaml.sh`, `verify.sh`.
  [Story: Article V, NFR-B810-003, b8-coroot lesson]

- [x] **T038** Independent review pass (separate lane — author MUST NOT self-approve;
  NFR-B810-009; T5.2 self-validation lesson). The independent reviewer MUST
  re-execute (not trust the transcript):
  `b8-10.test.sh --level 1` (12/12), `b8-2.test.sh --level 1` (frozen sha256),
  `b8-3.test.sh --level 1` (schema invariants), `validate-change-yaml.sh`,
  `constitution-linter.sh`, `verify.sh`, and the `[NEEDS CLARIFICATION:]`
  neutralization check on `specs.md`. Record the reviewer's name and run timestamp
  in the change record.
  [Story: NFR-B810-009, Article V.2, T5.2 lesson]

- [x] **T039** Archive prep: verify all tasks marked complete, run
  `/forge:archive b8-10-migrate-flagship` to flip status `implemented → archived`
  after the independent review PASS. Note the B.8.13 (rollback runbook criteria doc),
  B.8.12 (Envoy SecurityPolicy/JWT OIDC wiring), B.8.14 (breaking removal +
  VIII.1/VIII.2 amendment + schema promotion), and B.8.15 (`forge upgrade` matrix +
  TS subcommand surface) dependency chain.
  [Story: Article V, ADR-B810-003]

---

## FR-B810-* / NFR-B810-* Coverage Table

All 44 FRs + 10 NFRs covered.

| FR / NFR | Task(s) |
|----------|---------|
| FR-B810-001 | T006 (T-001), T008, T027 |
| FR-B810-002 | T006 (T-001/T-002), T008, T027 |
| FR-B810-003 | T006 (T-001), T008, T027 |
| FR-B810-004 | T006 (T-005), T008, T018, T027 |
| FR-B810-005 | T006 (T-005), T008, T010, T027 |
| FR-B810-006 | T006 (T-003), T008, T027 |
| FR-B810-007 | T006 (T-012-L1), T022, T025, T027 |
| FR-B810-008 | T006 (T-002), T008, T010, T020, T027 |
| FR-B810-010 | T006 (T-005), T011, T012, T013, T027 |
| FR-B810-011 | T011, T012, T013, T027 |
| FR-B810-012 | T006 (T-010), T011, T013, T027 |
| FR-B810-013 | T011, T013, T027 |
| FR-B810-014 | T006 (T-004), T011, T013, T027 |
| FR-B810-020 | T014, T027 |
| FR-B810-021 | T014, T027 |
| FR-B810-022 | T014, T027 |
| FR-B810-030 | T006 (T-004/plan), T015, T016, T019, T027 |
| FR-B810-031 | T006 (T-007), T015, T019, T027 |
| FR-B810-032 | T006 (T-006), T015, T019, T027 |
| FR-B810-033 | T015, T027 |
| FR-B810-034 | T006 (T-009), T015, T023, T025, T027 |
| FR-B810-035 | T015, T027 |
| FR-B810-036 | T006 (T-005/T-009), T017, T018, T019, T023, T027 |
| FR-B810-040 | T006 (T-008), T020, T021, T027 |
| FR-B810-041 | T006 (T-008), T020, T021, T032 |
| FR-B810-042 | T006 (T-009), T020, T023, T025, T027 |
| FR-B810-043 | T006 (T-004), T020, T027 |
| FR-B810-050 | T006 (T-009), T023, T025, T027 |
| FR-B810-051 | T006 (T-009), T023, T025, T027 |
| FR-B810-052 | T006 (T-009), T017, T023, T025, T027 |
| FR-B810-053 | T006 (T-009), T023, T025, T027 |
| FR-B810-054 | T006 (T-009), T023, T025, T027 |
| FR-B810-060 | T022, T027, T028 (L2) |
| FR-B810-061 | T022, T027, T028 (L2) |
| FR-B810-062 | T022, T028 (L2) |
| FR-B810-070 | T006, T007, T026, T027 |
| FR-B810-071 | T006 (T-001), T027 |
| FR-B810-072 | T006 (T-004), T027 |
| FR-B810-073 | T006 (T-005), T027 |
| FR-B810-074 | T006 (T-006), T027 |
| FR-B810-075 | T006 (T-007), T027 |
| FR-B810-076 | T006 (T-008), T027 |
| FR-B810-077 | T006 (T-009/T-010), T023, T024, T025, T027 |
| FR-B810-078 | T006 (T-011/T-012), T028 |
| NFR-B810-001 | T006 (T-003), T008, T027 |
| NFR-B810-002 | T006, T007, T027 (≤ 2 s L1) |
| NFR-B810-003 | T033, T034, T035 (full ~49-harness suite) |
| NFR-B810-004 | T003, T006 (T-010), T032 |
| NFR-B810-005 | T006 (T-012-L1), T022, T028 (L2 determinism) |
| NFR-B810-006 | implementation note (diff `.forge/standards/` — no change expected) |
| NFR-B810-007 | T006 (T-007), T015, T019, T027 (Kong additive invariant) |
| NFR-B810-008 | T006 (T-006), T015, T019, T027 (Temporal / no-DBOS) |
| NFR-B810-009 | T038 (independent review — separate lane) |
| NFR-B810-010 | T006 (T-004), T011, T013, T014, T015, T020, T027 |
