# Evidence — b8-10-migrate-flagship

<!-- Status: designed -->
<!-- Audit: B.8.10 (b8-10-migrate-flagship) — PURE TOOLING brick. No external
     version pins (no npm/registry/image verify-then-pin). The "verify-then-pin"
     equivalent is reading bin/forge-upgrade.sh internals + the 2.0.0 template-set
     + the frozen snapshot LIVE on disk. All evidence below is INTERNAL-FILE
     evidence (cite file:line, NOT URLs). Article III.4: every internal fact in
     design.md ADR-B810-001..005 traces to a P-NN row here; no forge-upgrade.sh
     internal is fabricated beyond what these rows quote. -->

**Collection timestamp**: 2026-06-03 (on-disk re-read by the main orchestration
thread; authoritative). All facts are file-state reads of the working tree at
`/Users/bfontaine/git/github/forge` on `main`.

**Re-verify obligation**: the `bin/forge-upgrade.sh` `_a7_*` function inventory and
the 2.0.0 template-set file list are re-read LIVE at `/forge:implement` before any
line of `bin/forge-migrate-flagship.sh` is authored (b8-coroot lesson: verify-then-pin
runs live at implement, not trusted from the design transcript). If `forge-upgrade.sh`
has been refactored in the interim, the source-and-orchestrate contract (ADR-B810-001)
is re-validated before sourcing.

---

## Provenance Table (internal-file evidence — file:line, not URLs)

| ID | Source (file:line) | Read | What it proves |
|----|--------------------|------|----------------|
| P-01 | `bin/forge-upgrade.sh:13-21` (docblock exit-code table) | 2026-06-03 | A.7 exit-code envelope: `0` success / `2` argument error / `5` missing required tool (git/python3/tar) / `7` upgrade aborted (major-version migration / dirty git / non-Git target with `--force`) / `8` conflicts produced (without `--force`). **`1` is NOT used by A.7.** Grounds ADR-B810-002's alignment decision (0/2/5/7/8 — NOT a fabricated 0/1/2/7). |
| P-02 | `bin/forge-upgrade.sh:131-142` (`_a7_check_version_compat`) | 2026-06-03 | Computes majors via `_a7_semver_major`; on major mismatch emits `forge-upgrade: major-version migration required ($from → $to). … see docs/MIGRATIONS.md.` + `[NEEDS MIGRATION: from $from to $to]` on stderr + `return 7`. **This is the guard that delegates TO this brick.** The migration script MUST NOT call/re-trigger it (ADR-B810-001). |
| P-03 | `bin/forge-upgrade.sh:387-389` (sourcing guard) | 2026-06-03 | `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then _a7_main "$@"; fi` — `_a7_main` runs ONLY on direct invocation, NOT when sourced. **Proves the file is safely sourcable** (ADR-B810-001 source-and-orchestrate). |
| P-04 | `bin/forge-upgrade.sh:107-120` (`_a7_check_force_clean_git`) | 2026-06-03 | `return 7` when target lacks `.git` OR `git status --porcelain` is non-empty; `return 5` when git is off PATH; `0` on clean Git tree. Reusable as the Phase 0 Git-clean gate (FR-B810-011). Emits `forge-upgrade: --force requires …` messages on stderr. |
| P-05 | `bin/forge-upgrade.sh:90-94` (`_a7_three_way_merge`) | 2026-06-03 | `git merge-file --diff3 <left> <base> <right>`; mutates LEFT in place; `return 5` if git absent; non-zero = git's conflict-section count. The single merge engine reused for Phase 2 (ADR-B810-001) — NOT re-implemented. |
| P-06 | `bin/forge-upgrade.sh:52-83` (`_a7_classify`) | 2026-06-03 | Pure classifier → `unchanged \| upgraded \| preserved \| merge_candidate \| conflict_2way` from LEFT/BASE/RIGHT sha256 (`_a7_sha256`, lines 42-50). Drives the per-file action in Phase 2 dry-run plan + apply. |
| P-07 | `bin/forge-upgrade.sh:192-227` (`_a7_resolve_owned_paths`) | 2026-06-03 | Reads `<root>/.forge/framework-owned-paths.yml`; prints owned rel-paths matched by `owned:` globs minus `excluded:` globs; `return 4` if the yml is absent. Resolves the Phase 2 merge surface (ADR-B810-001). |
| P-08 | `bin/forge-upgrade.sh:144-187` (`_a7_append_upgrade_history`) | 2026-06-03 | Python3-inline append to the manifest `upgrade_history` list. Entry keys: `date` (UTC ISO, `.replace(microsecond=0)`), `from_version`, `to_version`, `from_template_set_sha`, `to_template_set_sha`, `counts{unchanged,upgraded,preserved,conflicted,skipped}`, `cli_version`. Also MUTATES `archetype_version` + `template_set_sha` + `scaffold_date`. Identity fields `project_name`/`reverse_domain`/`root_module` UNTOUCHED. Grounds ADR-B810-004 (wrap, do NOT edit, this helper). |
| P-09 | `bin/forge-upgrade.sh:235-251` (`_a7_main` arg loop) | 2026-06-03 | Flags: `--target`(req) / `--to-version`(req) / `--dry-run` / `--force` / `--verbose` / `--help\|-h`; unknown arg → `return 2`; missing `--target`/`--to-version` → `return 2`; missing target dir → `return 2`. The CLI-shape precedent ADR-B810-002 mirrors (minus `--to-version`, plus `--phase`/`--rollback`). |
| P-10 | `bin/forge-upgrade.sh:277-291` (BASE snapshot recovery + owned-path resolve) | 2026-06-03 | BASE recovered from `$FORGE_REPO_ROOT/.forge/scaffold-snapshots/$archetype/$from_version.tar.gz` into a `mktemp -d`; degrades to 2-way merge if absent. `owned_list=$(_a7_resolve_owned_paths "$FORGE_REPO_ROOT")`. Proves the BASE = frozen `1.0.0.tar.gz`, the merge RIGHT = `$FORGE_REPO_ROOT/<rel>`. ADR-B810-001 redirects RIGHT to the 2.0.0 template-set. |
| P-11 | `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` (content) | 2026-06-03 | `8d439b942bf81dbcc103e010d946504035dd410f613b31f673d7d691c3224ca9  1.0.0.tar.gz`. The byte-frozen B.8.2 rollback target + Phase 0 sha256 verify expected digest (FR-B810-012). MUST NOT be rebuilt/overwritten (FR-B810-041). |
| P-12 | `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` (on-disk size) | 2026-06-03 | Live size **656.5 KB** (`du -h` reports 660K block-rounded). Under the 1 MB rollback budget. **Drift note**: NFR-UP-003 / proposal cite 422 KB — stale; the live 656.5 KB figure is authoritative. Carried as a doc-drift flag, not this brick's fix. |
| P-13 | `.forge/templates/archetypes/full-stack-monorepo/2.0.0/` (full file list) | 2026-06-03 | **27 template files** under `2.0.0/` (see "2.0.0 Template-Set File List" below). The merge RIGHT for Phase 2 (ADR-B810-001). **Drift note**: the design task brief estimated "26 files"; the live count is **27** — authoritative. |
| P-14 | `grep -ril 'dbos' .forge/templates/archetypes/full-stack-monorepo/2.0.0/` → rc=1 (zero matches) | 2026-06-03 | **No `2.0.0/` template file references DBOS** (no `orchestration/dbos` dir, no `dbos` crate, no `dbos-embedded` overlay). Grounds the no-DBOS HARD constraint (FR-B810-032 / NFR-B810-008): there is literally nothing to apply. |
| P-15 | `.forge/schemas/full-stack-monorepo/2.0.0.yaml:120-129` (`migration_deltas` temporal→dbos) | 2026-06-03 | `from: temporal-intent → to: dbos-embedded`, `cancelled: true` (B8O / ADR-B8O-001): "the Temporal→DBOS swap is CANCELLED for Rust (not deferred)". The 5 ADDITIVE-FIRST deltas (`strategy: additive-first` or crossing-delta) Phase 2 applies: kong→envoy (B.8.4), rest-bridge→connect-rpc (B.8.6), implicit-auth→zitadel (B.8.7), no-web-public-layer→qwik-web-public (B.8.9), postgres-16→17-pgvector (B.8.5). |
| P-16 | `.forge/schemas/full-stack-monorepo/2.0.0.yaml:46` (`scaffoldable: false`) | 2026-06-03 | `scaffoldable: false   # ADR-B8-3-003/005 — opt-in only; B.8.14 promotes to stable`. Grounds FR-B810-054 (the script is an opt-in tool; `forge init` keeps scaffolding 1.0.0) + the VIII.1/VIII.2 pre-amendment compliance posture. |
| P-17 | `.forge/schemas/full-stack-monorepo/2.0.0.yaml:17-25` (CONSTITUTIONAL PROHIBITION header) | 2026-06-03 | "Constitution v1.1.0 §VIII.1 mandates Kong … §VIII.2 mandates Temporal. Both SHALL clauses remain binding until B.8.14." Grounds the additive-only invariant (FR-B810-031): removing Kong/Temporal/REST before B.8.14 would be a constitutional violation. |
| P-18 | `examples/forge-fsm-example/.forge/scaffold-manifest.yaml:1-9` (manifest shape) | 2026-06-03 | `archetype: full-stack-monorepo`, `archetype_version: 1.0.0`, `project_name`, `reverse_domain`, `root_module`, `scaffold_date`, `scaffold_plan_sha`, `template_set_sha`, `tools:`. Phase 0 reads `archetype` + `archetype_version` (FR-B810-010); identity fields are the frozen set (FR-B810-061). |
| P-19 | `.forge/scripts/compliance/bundle.sh:34,54-67,95,414-415` (bash-thin pattern) | 2026-06-03 | `set -uo pipefail`; `err()` helper; `while/case` arg-parse with `--flag`/`--flag=*` forms + `--help\|-h`; Python3 `<<'PY'` heredoc; `SOURCE_DATE_EPOCH` via `os.environ.get(...)` (lines 126-128); terminal `rc=$?; exit $rc`. The exact pattern `bin/forge-migrate-flagship.sh` mirrors (FR-B810-002/003/004/007). |
| P-20 | `bin/forge-sbom.sh:27-69,71,291-292` (bash-thin pattern, doc-only posture) | 2026-06-03 | Sibling bash-thin+Python-inline script; doc-only `bin/` invocation (no TS commander wrapper). Grounds ADR-B810-003 (doc-only CLI surface for B.8.10) + FR-B810-006 (zero new dep: `bash`+`git`+`python3`+`tar`+`shasum`). |
| P-21 | `.forge/framework-owned-paths.yml:17-51` (owned/excluded globs) | 2026-06-03 | `owned:` includes `.forge/templates/**`, `.forge/schemas/**`, `.forge/standards/**`, `.forge/scripts/**`, `bin/forge-*.sh`; `excluded:` includes `.forge/scaffold-manifest.yaml`, `.forge/scaffold-snapshots/**`, `.forge/changes/**`. Consumed by `_a7_resolve_owned_paths` (P-07). Note for ADR-B810-001: the 2.0.0 overlay relpaths live UNDER `.forge/templates/**` (owned), but the migration RIGHT is the rendered 2.0.0 template-set, NOT the framework's own `.forge/templates/**` mirror — see ADR-B810-001 RIGHT-selection. |
| P-22 | `.forge/scripts/tests/b8-9.test.sh:28-75,243-260` (harness shape) | 2026-06-03 | `--level` flag parse via `for arg; prev`; `HARNESS_DIR`/`FORGE_ROOT` resolution; `source "$HARNESS_DIR/_helpers.sh"`; `run_test <fn>` + `print_summary`; 12 L1 tests, hermetic, exit-code-only sibling coupling (`bash b8-X.test.sh --level 1 >/dev/null 2>&1`). The structural model for `b8-10.test.sh` (FR-B810-070..078). |
| P-23 | `.forge/scripts/tests/b8-1.test.sh:201-205,240-242` (L2 opt-in env-gate) | 2026-06-03 | L2 test body: `if [ "${FORGE_B8_1_DOCKER:-0}" != "1" ]; then echo "    skipped (… unset — opt-in)" >&2; return 0; fi`; dispatched only when `LEVEL` contains `2`. The exact skip-pass pattern for the `FORGE_B8_10_LIVE=1` L2 leg (FR-B810-078). |
| P-24 | `.forge/scripts/tests/_helpers.sh:80,97` (`run_test`/`print_summary`) | 2026-06-03 | `run_test()` invokes the named fn, prints ✓/✗, accumulates PASS/FAIL; `print_summary()` prints the aggregate + sets exit status. Shared harness primitives — zero new dep (NFR-B810-001). |
| P-25 | `.forge/schemas/change.schema.json` (status enum + timeline props) | 2026-06-03 | `status` enum includes `designed`; `timeline.properties` includes `designed`; `timeline.additionalProperties: false`; FR-YS-008 coherence requires `timeline.designed` present when `status: designed`. Grounds the `.forge.yaml` flip (deliverable D). |
| P-26 | `.github/workflows/forge-ci.yml:68,113` (harness loop) | 2026-06-03 | `harnesses=( … "b8-7.test.sh --level 1" … "b8-9.test.sh --level 1" )` declarative loop; entry order load-bearing. `b8-10.test.sh --level 1` registers after the `b8-9.test.sh` line (FR-B810-070). |
| P-27 | `.forge/schemas/full-stack-monorepo/2.0.0.yaml:75-82,105-108` (DBOS future-option + obs closed) | 2026-06-03 | `dbos-embedded … status: future-option` ("no Rust crate; Temporal is the Rust default; ADR-002's swap cancelled for Rust"); `signoz-obi-coroot … already closed at B.8.8 — observability standard at v2.1.0`. Grounds Phase 1 (obs trio already shipped → assert-present no-op) + the no-DBOS Phase 2 guard. |

---

## 2.0.0 Template-Set File List (P-13 — the Phase 2 merge RIGHT; 27 files, no DBOS)

```
2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl
2.0.0/backend/crates/grpc-api/src/transport_connect.rs.tmpl       # B.8.6 Connect-RPC
2.0.0/frontend/web-public/.nvmrc.tmpl                              # B.8.9 Qwik
2.0.0/frontend/web-public/package.json.tmpl                        # B.8.9 Qwik
2.0.0/frontend/web-public/qwik.env.d.ts.tmpl                       # B.8.9 Qwik
2.0.0/frontend/web-public/README.md.tmpl                           # B.8.9 Qwik
2.0.0/frontend/web-public/src/entry.ssr.tsx.tmpl                   # B.8.9 Qwik
2.0.0/frontend/web-public/src/lib/connect-client.ts.tmpl           # B.8.9 Qwik
2.0.0/frontend/web-public/src/root.tsx.tmpl                        # B.8.9 Qwik
2.0.0/frontend/web-public/src/routes/index.tsx.tmpl               # B.8.9 Qwik
2.0.0/frontend/web-public/tsconfig.json.tmpl                       # B.8.9 Qwik
2.0.0/frontend/web-public/vite.config.ts.tmpl                      # B.8.9 Qwik
2.0.0/infra/k8s/envoy-gateway/backendtlspolicy.yaml.tmpl           # B.8.4 Envoy
2.0.0/infra/k8s/envoy-gateway/gateway.yaml.tmpl                    # B.8.4 Envoy
2.0.0/infra/k8s/envoy-gateway/gatewayclass.yaml.tmpl              # B.8.4 Envoy
2.0.0/infra/k8s/envoy-gateway/httproute.yaml.tmpl                  # B.8.4 Envoy
2.0.0/infra/k8s/envoy-gateway/kustomization.yaml.tmpl             # B.8.4 Envoy
2.0.0/infra/k8s/envoy-gateway/README.md.tmpl                       # B.8.4 Envoy
2.0.0/infra/postgres/docker-compose.fragment.yml.tmpl             # B.8.5 pg17+pgvector
2.0.0/infra/postgres/init-pgvector.sql.tmpl                        # B.8.5 pg17+pgvector
2.0.0/infra/postgres/README.md.tmpl                                # B.8.5 pg17+pgvector
2.0.0/infra/zitadel/bootstrap.md.tmpl                              # B.8.7 Zitadel
2.0.0/infra/zitadel/docker-compose.fragment.yml.tmpl              # B.8.7 Zitadel
2.0.0/infra/zitadel/README.md.tmpl                                 # B.8.7 Zitadel
2.0.0/infra/zitadel/values-forge.yaml.tmpl                         # B.8.7 Zitadel
2.0.0/shared/protos/buf.gen.yaml.tmpl                              # B.8.6 codegen
2.0.0/shared/protos/README.md.tmpl                                 # B.8.6 codegen
```

**27 files. Zero DBOS.** Coverage maps cleanly to the 5 additive-first deltas (P-15):
Envoy (6) + Connect-RPC backend (2) + Qwik web-public (10) + Postgres 17+pgvector (3) +
Zitadel (4) + shared protos codegen (2). There is **no `orchestration/`, no `dbos/`, no
`temporal/` overlay** in the 2.0.0 set — the no-DBOS constraint is structurally enforced
by the absence of any DBOS template to apply (P-14).

---

## Findings Summary

### Finding 1 — `forge-upgrade.sh` is safely sourcable; one merge engine, reused not rebuilt

`_a7_main` runs only on direct invocation (P-03). Sourcing the file exposes the `_a7_*`
library (P-04..P-08, P-10) without side effects. `bin/forge-migrate-flagship.sh` therefore
`source`s `bin/forge-upgrade.sh` and orchestrates `_a7_check_force_clean_git` (Phase 0 gate),
`_a7_resolve_owned_paths` + `_a7_classify` + `_a7_three_way_merge` (Phase 2 overlay), and a
thin wrapper over `_a7_append_upgrade_history` (Phase 2 ledger). **No second merge engine.**

### Finding 2 — the exit-7 guard is the delegation boundary; do NOT re-trigger it

`_a7_check_version_compat` (P-02) returns 7 + `[NEEDS MIGRATION:]` on the 1.0.0→2.0.0 major
diff. That guard is precisely what aborts `forge upgrade` and points the adopter at
`docs/MIGRATIONS.md`. The migration script is the thing invoked AFTER that abort; it MUST
NOT call `_a7_check_version_compat` (ADR-B810-001) — doing so would re-abort. Instead Phase 0
asserts `archetype_version == 1.0.0` directly off the manifest (P-18).

### Finding 3 — exit envelope ALIGNS to A.7 (0/2/5/7/8), not a fabricated 0/1/2/7

The proposal/specs lean was `0/1/2/7`. Live re-read of P-01 shows A.7 never uses `1`; it uses
`5` (missing tool) and `8` (conflicts). Since the script reuses A.7's tooling (which itself
returns 5/8), ADR-B810-002 ALIGNS to `0/2/5/7/8` so a delegated `_a7_three_way_merge` conflict
surfaces as exit-8, not an invented exit-1. This supersedes the spec lean (recorded as a
design refinement in open-questions Q-002, not a contradiction).

### Finding 4 — no-DBOS + additive-only are structurally enforced, not just policed

The 2.0.0 template-set contains zero DBOS files (P-13/P-14); the `temporal→dbos` delta is
`cancelled: true` (P-15); the constitutional prohibition header (P-17) keeps Kong/Temporal/REST
binding until B.8.14. Phase 2 applies only the 27-file additive set and never removes a 1.0.0
component. The harness no-DBOS / additive-only guards (FR-B810-074/075) are belt-and-suspenders
on top of a template-set that has nothing to violate.

### Finding 5 — frozen snapshot is the rollback BASE and the rollback SOURCE

`_a7_main` already recovers BASE from `1.0.0.tar.gz` (P-10). `--rollback` restores from the
same byte-frozen file (P-11, sha256 `8d43…4ca9`), never rebuilding it (FR-B810-041). The
Phase 0 sha256 verify (FR-B810-012) and the rollback both read this one file.

### Finding 6 — manifest ledger reuse without editing the helper

`_a7_append_upgrade_history` (P-08) already appends the right shape and freezes identity
fields. ADR-B810-004 wraps it (a thin post-append `kind: flagship-migration` tag via a separate
inline python that re-opens the manifest and stamps the last `upgrade_history` entry) rather
than editing the A.7 helper — keeping `forge-upgrade.sh` byte-unchanged (it is an `owned:`
framework file, P-21).

### Finding 7 — doc-drift surfaced, not propagated (Article III.4)

Two on-disk drifts vs the source documents are recorded rather than silently inherited:
(1) snapshot size 656.5 KB live vs 422 KB in NFR-UP-003 (P-12); (2) 2.0.0 template-set is
27 files live vs "26" in the design task brief (P-13). Both are flagged for a doc pass; neither
blocks this brick. The live figures are authoritative.

---

## Phase 0 LIVE re-execution (T001–T005, `/forge:implement`, read 2026-06-03)

Article III.4 + b8-coroot lesson: every Phase 0 carry item is re-read LIVE on disk
at implement time before any script line is authored. All five re-checks PASS; no
falsification surfaced; no `[NEEDS CLARIFICATION:]` emitted. Provenance below.

| ID | Source (live re-read) | What it confirms |
|----|-----------------------|------------------|
| P-28 (P-01-recheck) | `bin/forge-upgrade.sh:15-21` (docblock) | Exit-code envelope UNCHANGED: `0` success / `2` argument error / `5` missing tool (git/python3/tar) / `7` upgrade aborted / `8` conflicts. **`1` still absent.** ADR-B810-002 `0/2/5/7/8` alignment holds. |
| P-29 (P-03-recheck) | `bin/forge-upgrade.sh:387-389` (sourcing guard) | `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then _a7_main "$@"; fi` STILL PRESENT verbatim — `_a7_main` runs only on direct invocation; `source`ing is side-effect-free. ADR-B810-001 source-and-orchestrate holds. |
| P-30 (P-13-recheck) | `find .forge/templates/archetypes/full-stack-monorepo/2.0.0 -type f \| wc -l` → **27** | 2.0.0 template-set is still **27 files** (no drift from P-13). Phase 2 RIGHT walk targets the same set. |
| P-31 (P-14-recheck) | `grep -ril 'dbos' .forge/templates/.../2.0.0/` → **rc=1 (zero matches)** | No DBOS file in the 2.0.0 tree — the no-DBOS HARD constraint (FR-B810-032) is structurally enforced; nothing to apply. |
| P-32 | `grep -rl '_a7_check_version_compat' .forge/templates/.../2.0.0/` → **rc=1 (zero)** | No file in the 2.0.0 tree calls the exit-7 delegation guard — confirms the migration path never re-triggers `_a7_check_version_compat` from a template. |
| P-33 (P-08-recheck) | `bin/forge-upgrade.sh:144-187` (`_a7_append_upgrade_history`) | Signature UNCHANGED: `<mf> <from> <to> <from_sha> <to_sha> <unc> <upg> <prs> <cnf> <skp> <cli_v>`; Python-inline appends to `upgrade_history` list; `yaml.safe_dump(default_flow_style=False, sort_keys=True)`; mutates `archetype_version`/`template_set_sha`/`scaffold_date`; identity fields (`project_name`/`reverse_domain`/`root_module`) UNTOUCHED. ADR-B810-004 wrap holds. |
| P-34 (P-04/P-05/P-06-recheck) | `bin/forge-upgrade.sh:107-120` / `:90-94` / `:56-83` | `_a7_check_force_clean_git` (return 7 dirty / 5 no-git / 0 clean), `_a7_three_way_merge` (`git merge-file --diff3`, return 5 if git absent), `_a7_classify` (`unchanged\|upgraded\|preserved\|merge_candidate\|conflict_2way`) — all sourceable, no argument changes. ADR-B810-001 reuse holds. |
| P-35 (P-11-recheck) | `shasum -a 256 -c 1.0.0.sha256` → `1.0.0.tar.gz: OK`; b8-2 `--level 1` → rc 0 | Frozen snapshot byte-intact; digest `8d439b942bf81dbcc103e010d946504035dd410f613b31f673d7d691c3224ca9`; BASE/rollback source uncorrupted (FR-B810-012/041/NFR-B810-004). |
| P-36 (P-18-recheck) | `examples/forge-fsm-example/.forge/scaffold-manifest.yaml:1-9` | `archetype: full-stack-monorepo`, `archetype_version: 1.0.0` (string, line-regex parseable), plus `project_name`/`reverse_domain`/`root_module`/`scaffold_date`/`scaffold_plan_sha`/`template_set_sha`/`tools:`. Phase 0 manifest read shape (FR-B810-010) confirmed; schema layer relpaths `backend/`/`frontend/`/`infra/`/`shared/` (P-16) intact in the 2.0.0 tree. |

**Verdict**: T001–T005 all GREEN. No drift, no signature change, no falsification.
Proceeding to Phase 1 (harness RED).

---

## Anti-Hallucination Pass (Evidence Phase)

- Every `_a7_*` function cited (P-02..P-10) is quoted with its exact line range from a direct
  re-read of `bin/forge-upgrade.sh`. **No `_a7_*` function name is invented** beyond the
  inventory: `_a7_sha256`, `_a7_classify`, `_a7_three_way_merge`, `_a7_record_conflict`,
  `_a7_check_force_clean_git`, `_a7_semver_major`, `_a7_check_version_compat`,
  `_a7_append_upgrade_history`, `_a7_resolve_owned_paths`, `_a7_usage`, `_a7_main`,
  `find_excluding_examples`.
- The exit-code envelope (P-01) is read from the docblock table, not inferred. The `0/2/5/7/8`
  alignment is a fact about A.7, not a B.8.10 invention.
- The no-DBOS finding (P-13/P-14) is a `grep -ril 'dbos'` returning rc=1 over the live 2.0.0
  tree, not an assumption. The `cancelled: true` delta (P-15) is quoted from the schema.
- The frozen sha256 (P-11) is read from the `.sha256` file; it is a grounding fact for
  FR-B810-012, not an asserted design detail.
- The bash-thin pattern (P-19/P-20) is quoted from two sibling scripts; the new script's
  structure mirrors theirs and introduces no new dependency (P-24, NFR-B810-001).
- Doc-drift (P-12, P-13) is surfaced explicitly per Article III.4, not propagated.
