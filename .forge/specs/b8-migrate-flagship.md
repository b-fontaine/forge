# Spec: b8-migrate-flagship

<!-- Audit: B.8.10 (b8-10-migrate-flagship) -->
<!-- Source change : `.forge/changes/b8-10-migrate-flagship/` (delta specs.md authoritative). -->

**Namespace** : `FR-B810-*` / `NFR-B810-*` / `ADR-B810-*`.
**Constitution** : v1.1.0, unchanged (no amendment). Article VIII.1 (Kong SHALL)
is **PRESERVED** — the script adds Envoy in parallel and never removes Kong;
VIII.1 stays satisfied because 2.0.0 is `scaffoldable: false` and the default
is never flipped off Kong until B.8.14. Article VIII.2 (Temporal SHALL) is
**PRESERVED** — Temporal is retained; no DBOS leg in the script (B8O /
ADR-B8O-001). Article VIII.5 (IaC) — the overlays applied are declarative
templates already under version control. This change ships **no production
code** in the running example tree: it authors one new `bin/` script, one
doc section, one ledger-append, and a harness only.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-Hallucination —
overlay engine internals, exact CLI wiring, and ledger marker are design-time ADRs;
Q-NNN markers used throughout), IV (delta-based: ADDED FRs only; MIGRATIONS.md
gets a new section), V (harness + gates before status flips; full ~49-harness
suite before push; POST-flip re-run per b8-coroot lesson), VIII.1 (Kong SHALL
— in force, PRESERVED), VIII.2 (Temporal SHALL — in force, PRESERVED; no DBOS),
VIII.5 (IaC declarative templates), XII (no governance change — breaking
bump/amendment is B.8.14).

## Overview

B.8.10 delivers the **flagship migration orchestrator**: `bin/forge-migrate-flagship.sh`,
a bash-thin + Python-inline script that `source`s `bin/forge-upgrade.sh` (safe —
`_a7_main` runs only under the `[[ BASH_SOURCE == $0 ]]` guard) and reuses
`_a7_resolve_owned_paths` / `_a7_three_way_merge` / `_a7_check_force_clean_git`
over a 4-phase flow:

- **Phase 0** — preflight: assert 1.0.0 full-stack-monorepo, Git-clean gate,
  frozen snapshot sha256 verification (b8-2 guard reuse).
- **Phase 1** — observability + contracts: idempotent assert-or-apply gate for
  the B.8.8 obs trio and B.8.6 Connect codegen overlays.
- **Phase 2** — additive structural overlay: applies the 5 additive-first
  2.0.0 deltas (Kong→Envoy B.8.4, REST→Connect B.8.6, implicit→Zitadel B.8.7,
  no-web→Qwik B.8.9, pg16→17+pgvector B.8.5). **NO DBOS leg** — the
  `temporal-intent → dbos-embedded` delta is `cancelled: true` (B8O /
  ADR-B8O-001); Temporal retained.
- **Phases 3 & 4** — forward-reference stubs only (T7 new archetypes / T8
  deprecation); print plan, exit 0.

The script is **additive-only**: MUST NOT remove Kong / Temporal / REST paths
(B.8.14 responsibility). `--dry-run` is default-safe (no mutation). `--rollback`
restores from the byte-frozen `1.0.0.tar.gz` snapshot (B.8.2 guard, never
rebuilt). Ledger `kind: flagship-migration` appended via `_b810_tag_last_history_kind`
wrapper — `forge-upgrade.sh` is NOT edited. CLI surface is doc-only for B.8.10
(`bash bin/forge-migrate-flagship.sh --target . --dry-run`); TS subcommand
deferred to B.8.15 (ADR-B810-003). `docs/MIGRATIONS.md` 1.0.0→2.0.0 section fills
the A.7 deferred stub. Exit envelope: `0/2/5/7/8` (aligned to A.7, corrected
from spec lean `0/1/2/7` at design — ADR-B810-002). `b8-10.test.sh` ships
12 L1 + L2 opt-in (`FORGE_B8_10_LIVE=1`). Full ~49-harness suite GREEN.
Independent review design + final APPROVE round 1. Archived 2026-06-03.

## GROUND-TRUTH FINDINGS (Article III.4) — this brick SUPPLIES the migration orchestration

**Ground truth (re-read 2026-06-03, Article III.4):**

- **The exit-7 abort is already built.** `forge-upgrade.sh` line 131-142:
  `_a7_check_version_compat` emits `[NEEDS MIGRATION: from $from to $to]` on
  stderr and returns 7 when the major version differs. B.8.10 does NOT touch
  `forge-upgrade.sh`; it fills the other side — the orchestration script the
  adopter runs after the abort, and the `docs/MIGRATIONS.md` section the abort
  message points to. The migration script deliberately NEVER calls
  `_a7_check_version_compat` (that guard is what delegated here).
- **Phase 2 has NO DBOS leg.** `2.0.0.yaml` `migration_deltas` entry for
  `temporal-intent → dbos-embedded` is marked `cancelled: true` (B8O /
  ADR-B8O-001). `orchestration.yaml` v1.2.0 retains `default_by_language.rust:
  temporal`. The script applies ONLY: Kong→Envoy (B.8.4), REST→Connect (B.8.6),
  implicit→Zitadel (B.8.7), no-web→Qwik (B.8.9), pg16→17+pgvector (B.8.5).
  It MUST NOT scaffold, run, dual-run, or reference DBOS as an applied delta.
- **Additive-only — no breaking removal.** The script applies the 2.0.0 overlays
  in parallel with the 1.0.0 components and MUST NOT remove Kong/Temporal/
  REST-bridge. Those removals + the VIII.1/VIII.2 amendment are B.8.14.
- **Rollback target is the byte-frozen B.8.2 snapshot.**
  `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` +
  `1.0.0.sha256` (observed sha256:
  `8d439b942bf81dbcc103e010d946504035dd410f613b31f673d7d691c3224ca9`).
  The `b8-2.test.sh` guard asserts byte-identity. The migration script
  restores from this file and MUST NOT rebuild or overwrite it.
- **The scaffold-manifest fields (observed).** `examples/forge-fsm-example/.forge/
  scaffold-manifest.yaml`: `archetype: full-stack-monorepo`,
  `archetype_version: 1.0.0`, `project_name`, `reverse_domain`, `root_module`
  (identity fields). Phase 0 reads `archetype` + `archetype_version`.
- **`_a7_append_upgrade_history` shape (observed, `forge-upgrade.sh:144-187`).**
  Python3 inline block: reads `upgrade_history` list from manifest, appends an
  entry with keys `date`, `from_version`, `to_version`, `from_template_set_sha`,
  `to_template_set_sha`, `counts` (unchanged/upgraded/preserved/conflicted/
  skipped), `cli_version`; writes back with `yaml.safe_dump`. Identity fields
  (`project_name`, `reverse_domain`, `root_module`) are NOT touched. The
  `kind: flagship-migration` marker is stamped post-append via a thin wrapper
  `_b810_tag_last_history_kind` — `forge-upgrade.sh` is NOT edited.
- **bash-thin + Python-inline pattern (observed, `bundle.sh` + `forge-sbom.sh`).**
  `#!/usr/bin/env bash` shebang; `set -uo pipefail`; arg-parse via `while/case`;
  exit-code envelope `rc=$?; exit $rc`; Python logic passed as heredoc `<<'PY'`.
  SOURCE_DATE_EPOCH consumed in Python via `os.environ.get("SOURCE_DATE_EPOCH")`.
- **Harness shape (observed, `b8-9.test.sh`).** `--level` flag; `source
  _helpers.sh`; `run_test` / `print_summary`; L1 hermetic ≤2 s, zero net/
  Docker; L2 opt-in env-gate `FORGE_B8_10_LIVE=1` pattern (b8-1.test.sh).
- **Phases 3 & 4 are forward-reference stubs only.** Phase 3 (new archetypes,
  T7) and Phase 4 (deprecation, T8) are documented in `--help` + MIGRATIONS.md
  as future stages; not executed by this brick. The script prints the stub plan
  and exits informational.
- **Pure tooling — no standard bump.** No `.forge/standards/*.yaml` edit;
  `constitution_version: 1.1.0` unchanged.
- **Exit envelope corrected at design.** The spec lean was `0/1/2/7`. Resolved
  at `/forge:design` (ADR-B810-002): aligned to A.7's actual envelope
  `0/2/5/7/8` (`1` is unused by A.7; conflicts surface as exit-8).
- **Canary is document-only.** Resolved at `/forge:design` (ADR-B810-005):
  the script prints canary-by-route Kong→Envoy guidance; actual per-route
  cutover wiring is B.8.12.

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4.2 B.8.10 — "Migration scripts `bin/forge-migrate-flagship.sh` orchestrant les 4 phases ARCHITECTURE-TARGET §11" |
| **Exit-7 abort (observed)** | `bin/forge-upgrade.sh:131-142` — `_a7_check_version_compat` emits `[NEEDS MIGRATION: from $from to $to]` on stderr and returns 7; `_a7_main:272` calls it before proceeding. This is the abort B.8.10 fills the OTHER side of. |
| **Ledger shape (observed)** | `bin/forge-upgrade.sh:144-187` — `_a7_append_upgrade_history <manifest> <from> <to> <from_sha> <to_sha> <unc> <upg> <prs> <cnf> <skp> <cli_v>` — Python3 inline block appending to `upgrade_history` list; identity fields (`project_name`, `reverse_domain`, `root_module`) untouched. |
| **bash-thin+Python-inline pattern** | `.forge/scripts/compliance/bundle.sh` — `set -uo pipefail`; `while/case` arg-parse; Python3 `<<'PY'` heredoc; `rc=$?; exit $rc` envelope; `SOURCE_DATE_EPOCH` via `os.environ.get(...)`. |
| **2.0.0.yaml (observed)** | `.forge/schemas/full-stack-monorepo/2.0.0.yaml` — `scaffoldable: false`; 5 additive-first deltas (Kong→Envoy B.8.4, REST→Connect B.8.6, implicit→Zitadel B.8.7, no-web→Qwik B.8.9, pg16→pg17 B.8.5); `temporal-intent→dbos-embedded` delta `cancelled: true` (B8O). |
| **Frozen snapshot (observed)** | `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` sha256: `8d439b942bf81dbcc103e010d946504035dd410f613b31f673d7d691c3224ca9` (`1.0.0.sha256`). MUST NOT be rebuilt or overwritten. |
| **scaffold-manifest shape (observed)** | `examples/forge-fsm-example/.forge/scaffold-manifest.yaml` — `archetype: full-stack-monorepo`, `archetype_version: 1.0.0`, `project_name`, `reverse_domain`, `root_module`, `scaffold_date`, `template_set_sha`, `tools:`. |
| **Harness shape** | `.forge/scripts/tests/b8-9.test.sh` — `--level` flag, `source _helpers.sh`, `run_test`/`print_summary`, L1 ≤2 s hermetic, L2 opt-in env-gate. |
| **B.8.13 rollback criteria** | Cross-reference only (full runbook is B.8.13): p99 >20% after Envoy → rollback Kong; traceparent errors >1% → rollback OTel SDK only. DBOS-CPU criterion removed per B8O. |
| **Release target** | v0.4.0-rc.12 |
| **Dependencies** | A.7 (forge-upgrade.sh machinery + exit-7 abort + upgrade_history ledger), B.8.2 (frozen 1.0.0 snapshot), B.8.4/5/6/7/9 (2.0.0 overlays applied), B8O (no-DBOS constraint) |

---

## ADDED Requirements

### Functional Requirements

#### Group 1 — Script skeleton + CLI contract (FR-B810-001 → 008)

##### FR-B810-001 — `bin/forge-migrate-flagship.sh` exists and is executable
The brick MUST create `bin/forge-migrate-flagship.sh`. The file MUST be
present on disk and have executable permission (`chmod +x` or equivalent).
Testable: `[ -f bin/forge-migrate-flagship.sh ] && [ -x bin/forge-migrate-flagship.sh ]`.

##### FR-B810-002 — bash-thin + Python-inline header with audit comment
The script MUST open with:
```
#!/usr/bin/env bash
# Forge — `forge-migrate-flagship` 1.0.0 → 2.0.0 flagship migration orchestrator
# <!-- Audit: B.8.10 (b8-10-migrate-flagship) -->
```
followed immediately by a docblock covering: Usage, Exit-codes (citing
ADR-B810-002 for final values), Determinism (SOURCE_DATE_EPOCH where a
timestamp is emitted), and Pattern (bash-thin + Python 3 inline, mirrors
`bin/forge-sbom.sh` / `.forge/scripts/compliance/bundle.sh`).
The shebang line MUST be `#!/usr/bin/env bash`. Testable: grep for the
audit comment sentinel `Audit: B.8.10 (b8-10-migrate-flagship)`.

##### FR-B810-003 — `set -uo pipefail` immediately after the docblock
The script MUST set `set -uo pipefail` as the first non-comment, non-blank
executable statement, matching the bash-thin pattern in `bundle.sh` and
`forge-upgrade.sh`. Testable: grep for `set -uo pipefail` in the script body.

##### FR-B810-004 — Argument parsing: `--target` required, standard flags
The script MUST implement argument parsing via a `while/case` loop (matching
the `bundle.sh` / `forge-upgrade.sh` pattern) supporting:
- `--target <dir>` (required): the project directory to migrate.
- `--dry-run`: print the plan and per-phase file actions; mutate nothing.
- `--phase <0|1|2|all>`: run the specified phase(s) only (default: `all`).
- `--force`: override the Git-clean gate (mirrors A.7 `--force`).
- `--rollback`: restore from the frozen 1.0.0 snapshot (mutually exclusive
  with `--phase`; ADR-B810-002 resolves the exact interaction).
- `--help` / `-h`: print usage and exit 0.
Exit with code 2 when `--target` is absent or the directory does not exist.
Testable: invoke with no args → exit 2; invoke with `--help` → exit 0.

##### FR-B810-005 — Exit-code envelope: 0/2/5/7/8 (aligned to A.7, ADR-B810-002)
The script MUST use the exit-code envelope aligned to A.7's actual envelope
(corrected from spec lean `0/1/2/7` at `/forge:design`):
- `0` — success (migration applied or dry-run complete).
- `2` — usage/argument error (missing `--target`, unknown flag).
- `5` — internal script error (unexpected failure in a helper).
- `7` — precondition not met (not a 1.0.0 full-stack-monorepo target, dirty
  Git tree without `--force`, snapshot sha256 mismatch).
- `8` — conflict / overlay failure (merge conflict requiring manual resolution).
The script MUST exit with the correct code for each failure mode.
Testable: invoke with a non-1.0.0 target → exit 7.

##### FR-B810-006 — Zero new external dependency
The script MUST NOT introduce any new external binary dependency beyond those
already present in the Forge dev environment: `bash`, `git`, `python3`
(stdlib + PyYAML), `tar`, `shasum`/`sha256sum`. No new npm package, Cargo
crate, Dart pub package, or third-party binary. Testable: grep the script
for any `command -v` or shell invocation against a non-listed binary; harness
asserts none are present.

##### FR-B810-007 — SOURCE_DATE_EPOCH-deterministic timestamp output
Any timestamp written by the script (e.g., the ledger `date` field) MUST be
derived from `SOURCE_DATE_EPOCH` when that environment variable is set,
matching the pattern in `bundle.sh` (`os.environ.get("SOURCE_DATE_EPOCH")`).
When `SOURCE_DATE_EPOCH` is unset, the current UTC time is used. Two runs
with the same `SOURCE_DATE_EPOCH` and the same inputs MUST produce
byte-identical ledger output. Testable: set `SOURCE_DATE_EPOCH=0`; run
`--dry-run` twice; compare ledger output.

##### FR-B810-008 — `--help` / `-h` prints usage and exits 0
The script MUST implement `--help` and `-h` flags that print a usage block
including: script name, synopsis (`--target <dir>` + all flags), exit-code
table, and a reference to `docs/MIGRATIONS.md` for the full runbook.
Exit code MUST be 0. Testable: `bash bin/forge-migrate-flagship.sh --help;
echo $?` → 0 and output contains `--target`.

---

#### Group 2 — Phase 0 audit/preflight (FR-B810-010 → 014)

##### FR-B810-010 — Assert target is a scaffolded 1.0.0 full-stack-monorepo
Phase 0 MUST read `<target>/.forge/scaffold-manifest.yaml` and assert:
- `archetype: full-stack-monorepo` (exact string match).
- `archetype_version: 1.0.0` (exact string match).
If either assertion fails (file absent, wrong archetype, wrong version), the
script MUST emit an actionable error message on stderr — e.g.:
  `forge-migrate-flagship: target is not a 1.0.0 full-stack-monorepo project
  (archetype_version: X.Y.Z). Migration requires archetype_version: 1.0.0.`
and exit 7. Testable: invoke against a directory with no manifest → exit 7;
invoke against a manifest with `archetype_version: 0.9.0` → exit 7.

##### FR-B810-011 — Git-clean gate with `--force` override
Phase 0 MUST assert that the target directory is a Git repository with an
empty `git status --porcelain` output (mirrors `_a7_check_force_clean_git`
from `forge-upgrade.sh:107-121`). If the tree is dirty and `--force` is NOT
passed, the script MUST exit 7 with an actionable message directing the
adopter to stash or commit first. When `--force` is passed, the Git-clean
check is skipped. Testable: invoke against a dirty Git tree without
`--force` → exit 7; with `--force` → proceeds past the Git check.

##### FR-B810-012 — Verify frozen 1.0.0 snapshot sha256 (b8-2 guard reuse)
Phase 0 MUST verify the sha256 of
`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` against the
companion `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` file.
Expected sha256 (observed): `8d439b942bf81dbcc103e010d946504035dd410f613b31f673d7d691c3224ca9`.
If the computed sha256 does not match, the script MUST exit 7 with a message
citing the snapshot path and expected vs actual digest. This reuses the b8-2
guard invariant. Testable: corrupt the sha256 file → exit 7.

##### FR-B810-013 — Structured failure with actionable message (exit-7-style)
All Phase 0 precondition failures MUST follow the structured pattern:
`forge-migrate-flagship: <category>: <human-readable explanation with remediation hint>`
emitted on stderr. The exit code MUST be 7 (precondition not met). At
minimum, distinct messages are required for: (a) manifest missing, (b) wrong
archetype, (c) wrong archetype_version, (d) dirty Git tree, (e) snapshot
sha256 mismatch. Testable: each precondition failure message contains
`forge-migrate-flagship:` and the relevant category keyword.

##### FR-B810-014 — `--dry-run` reports the plan without mutating
When `--dry-run` is passed, Phase 0 MUST complete all assertions but MUST NOT
write any file, modify any Git state, or append any ledger entry. The script
MUST print a structured plan listing: target path, current archetype version,
migration target version, phases to be run, and the list of overlays to be
applied (one per delta). Output MUST be to stdout. No file in the target
directory may be modified when `--dry-run` is active. Testable: run
`--dry-run` on a 1.0.0 fixture; `git status --porcelain` on the fixture
remains empty after the run.

---

#### Group 3 — Phase 1 observability + contracts (idempotent) (FR-B810-020 → 022)

##### FR-B810-020 — Assert-or-apply the obs trio + Connect codegen overlays
Phase 1 MUST check whether the obs trio (SigNoz/OBI/Coroot, closed at B.8.8)
and the Connect codegen overlays (B.8.6) are already present in the target.
The flagship 1.0.0 ships the obs trio post-B.8.8; Phase 1 is primarily a
verification gate on the flagship. If the expected files/markers are present,
Phase 1 exits the check as a no-op (idempotent). If any marker is absent,
Phase 1 applies the missing overlay. The exact detection predicate and
overlay path are resolved by ADR-B810-001. This FR mandates the idempotent
contract; the mechanism is left to design. Testable: run Phase 1 twice on
the same target — second run produces no diff.

##### FR-B810-021 — No-op when already present (idempotent re-run safe)
Phase 1 MUST be safe to re-run on a target that already has all B.8.8 +
B.8.6 overlays. Re-running MUST NOT overwrite files that have not changed,
MUST NOT create duplicate entries in any manifest or ledger, and MUST NOT
emit a failure exit code when all checks pass. This is the idempotent
invariant: `phase_1(phase_1(target)) == phase_1(target)`. Testable:
apply Phase 1 twice; `git diff` after the second application shows no changes.

##### FR-B810-022 — Phase 1 `--dry-run` safe (no mutation)
When `--dry-run` is active and `--phase 1` (or `--phase all`) is selected,
Phase 1 MUST print the obs/contracts verification results (present/missing)
without modifying any file. Testable: `--dry-run --phase 1` on a 1.0.0
fixture → exit 0; fixture has no new files after the run.

---

#### Group 4 — Phase 2 structural overlay (additive) (FR-B810-030 → 036)

##### FR-B810-030 — Apply the 5 additive-first 2.0.0 overlays
Phase 2 MUST apply the following overlays from the 2.0.0 template set into
the target, matching the additive-first deltas in `2.0.0.yaml`:
1. Kong→Envoy Gateway (B.8.4) — `2.0.0/infra/k8s/envoy-gateway/` templates.
2. REST-bridge→Connect-RPC (B.8.6) — Connect codegen + transport overlays.
3. implicit→Zitadel identity (B.8.7) — Zitadel configuration overlays.
4. no-web→Qwik web-public (B.8.9) — `2.0.0/frontend/web-public/` templates.
5. postgres-16→17+pgvector (B.8.5) — Docker image + migration overlay.
The exact file set per delta is determined by ADR-B810-001.
This FR mandates that all five deltas are covered; the per-delta file list is
the ADR's responsibility. Testable: after Phase 2, each overlay directory
exists in the target AND Kong/Temporal/REST paths are still present.

##### FR-B810-031 — MUST NOT remove Kong / Temporal / REST paths (additive invariant)
Phase 2 MUST NOT delete, rename, or overwrite any existing Kong, Temporal, or
REST-bridge file in the target. The `--phase 2` (or `--phase all`) code path
MUST NOT contain any `rm`, `rmdir`, `mv` (for removal), or equivalent
operation that would discard a Kong, Temporal, or REST path. This is the
constitutional additive invariant: VIII.1 (Kong SHALL) + VIII.2 (Temporal
SHALL) remain satisfied. Testable by static analysis: grep the Phase 2 code
path for `rm`/`rmdir`/destructive `mv` on Kong/Temporal/REST target paths →
must return zero matches. Testable at runtime: Kong+Temporal+REST files
present both before and after Phase 2.

##### FR-B810-032 — MUST NOT scaffold, run, or reference DBOS as an applied delta
Phase 2 MUST NOT create any DBOS file, reference `dbos-embedded` as an
applied migration target, add a `dbos` Cargo crate reference, or invoke any
DBOS runtime. The `temporal-intent → dbos-embedded` delta in `2.0.0.yaml`
is `cancelled: true` (B8O / ADR-B8O-001); Phase 2 MUST honour this
cancellation unconditionally. Testable by static analysis: grep the script
body for `dbos` or `dbos-embedded` as applied delta terms → must return zero
matches. This is a hard negative guard; any DBOS reference in the Phase 2
apply path is a constitutional violation (VIII.2 Temporal SHALL, B8O).

##### FR-B810-033 — Merge delegates to forge-upgrade.sh machinery (ADR-B810-001)
The 3-way file merge for the Phase 2 overlays delegates to the
`forge-upgrade.sh` merge machinery by `source`ing `bin/forge-upgrade.sh` and
reusing `_a7_resolve_owned_paths` / `_a7_three_way_merge` /
`_a7_check_force_clean_git`, selecting the 2.0.0 template set as the merge
RIGHT. A second merge engine is NOT introduced. The script deliberately NEVER
calls `_a7_check_version_compat` (that guard is what delegated here).
Testable: the script body MUST NOT duplicate `git merge-file` invocation
logic that already exists in `forge-upgrade.sh`.

##### FR-B810-034 — Canary-by-route documented, not auto-wired (ADR-B810-005)
Phase 2 MUST NOT automatically configure per-route canary traffic splitting
between Kong and Envoy. The canary-by-route guidance (graduated Kong→Envoy
cutover) MUST be documented in `docs/MIGRATIONS.md` as an adopter-driven
manual step (resolved: ADR-B810-005 document-only). Envoy SecurityPolicy/JWT
OIDC wiring is B.8.12.
Testable: Phase 2 does not generate any canary weight / route-split config;
MIGRATIONS.md contains a "canary" section referencing the manual process.

##### FR-B810-035 — Phase 2 `--dry-run` safe (no mutation)
When `--dry-run` is active and `--phase 2` (or `--phase all`) is selected,
Phase 2 MUST print the overlay plan (per-delta: files to be created/merged,
classifications as upgraded/preserved/merge_candidate per A.7 classification)
without modifying any file in the target directory. Testable: `--dry-run
--phase 2` on a clean 1.0.0 fixture; `git diff` after the run shows no
changes in the fixture.

##### FR-B810-036 — Phases 3 and 4 are forward-reference stubs (print plan, exit 0)
When `--phase 3` or `--phase 4` is invoked, the script MUST print the
forward-reference stub for the corresponding phase (T7 new archetypes / T8
deprecation plan) and exit 0 informational. The stubs MUST NOT attempt to
execute any overlay, delete any file, or modify the target. They MUST
reference `docs/MIGRATIONS.md` Phase 3/4 stubs. Testable: `--phase 3` →
exit 0; stdout contains "Phase 3" and "T7"; no file mutation.

---

#### Group 5 — Rollback (FR-B810-040 → 043)

##### FR-B810-040 — `--rollback` restores from the byte-frozen 1.0.0 snapshot
When `--rollback` is invoked, the script MUST restore the target from the
frozen `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` snapshot.
The restore is a `tar -xzf` extraction of the snapshot into the target
directory (or equivalent). The rollback source is the frozen snapshot, not a
newly generated snapshot. Testable: `--rollback` on a Phase-2-applied fixture;
after rollback, the target matches the frozen snapshot sha256.

##### FR-B810-041 — MUST NOT rebuild or overwrite the frozen snapshot or its `.sha256`
The script MUST NOT write to, overwrite, or regenerate
`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` or
`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` under any code
path (rollback, phase, dry-run, or otherwise). These are B.8.2 byte-frozen
assets. Testable by static analysis: grep the script body for any write
operation targeting the `scaffold-snapshots/` path → must return zero matches.
Testable at runtime: the `1.0.0.sha256` content is byte-identical before and
after any script invocation.

##### FR-B810-042 — References B.8.13 rollback criteria (cross-reference, not re-implement)
The script's `--rollback` flag help text and MIGRATIONS.md MUST reference
B.8.13 for the full rollback runbook and criteria: p99 +>20% after Envoy →
rollback Kong; traceparent errors >1% → rollback OTel SDK only. The
DBOS-CPU criterion is **removed per B8O** and MUST NOT appear. B.8.10 only
wires the restore mechanic; the criteria doc is B.8.13. Testable: grep
MIGRATIONS.md for "B.8.13" as the rollback criteria cross-reference; grep
MIGRATIONS.md for "dbos" in a rollback-criteria context → must return zero
matches.

##### FR-B810-043 — `--rollback` with `--dry-run` is safe (no mutation)
When `--rollback` and `--dry-run` are both passed, the script MUST print the
rollback plan (source snapshot path, sha256 to be verified, files to be
restored) without modifying any file. Exit code MUST be 0. Testable:
`--rollback --dry-run` on a Phase-2-applied fixture; `git diff` shows no
changes in the fixture after the run.

---

#### Group 6 — forge upgrade hook + MIGRATIONS.md (FR-B810-050 → 054)

##### FR-B810-050 — `docs/MIGRATIONS.md` gains a 1.0.0→2.0.0 section (A.7 stub fill)
The brick MUST create or expand `docs/MIGRATIONS.md` with a `## 1.0.0 → 2.0.0`
section (filling the A.7 deferred stub). The section MUST include at minimum:
(a) the 4-phase walkthrough (Phase 0 preflight, Phase 1 obs+contracts, Phase 2
structural overlay, Phase 3/4 forward-reference stubs);
(b) the additive-first posture statement (Kong/Temporal/REST preserved until
B.8.14);
(c) the B8O no-DBOS note (Temporal retained; DBOS cancelled for Rust;
ADR-B8O-001 cross-reference);
(d) rollback criteria cross-reference (B.8.13);
(e) the "stay-on-1.0.0-until-T8" legacy option (adopters may remain on 1.0.0
until T8 / B.8.14; no forced migration);
(f) the `scaffoldable: false`-until-B.8.14 caveat;
(g) the invocation lean (ADR-B810-003 doc-only invocation for
B.8.10: `bash bin/forge-migrate-flagship.sh --target . --dry-run`).
Testable: `grep -n "1.0.0.*2.0.0\|2.0.0.*1.0.0" docs/MIGRATIONS.md` →
matches; each sub-item (a)-(g) has a corresponding grep-verifiable sentinel.

##### FR-B810-051 — Exit-7 `[NEEDS MIGRATION:]` message points at MIGRATIONS.md
The existing `forge-upgrade.sh` exit-7 message already includes a reference
to `docs/MIGRATIONS.md` (observed: `"see docs/MIGRATIONS.md"`). B.8.10 MUST
NOT modify `forge-upgrade.sh`. Instead, MIGRATIONS.md MUST contain the
`forge-migrate-flagship` invocation guidance such that an adopter who follows
the exit-7 message can find the script. Testable: `grep -c
"forge-migrate-flagship" docs/MIGRATIONS.md` → ≥ 1.

##### FR-B810-052 — Phase 3/4 forward-reference stubs in MIGRATIONS.md
`docs/MIGRATIONS.md` MUST include stub sections for Phase 3 (new archetypes,
T7) and Phase 4 (deprecation, T8), each clearly marked as
"forward reference — not yet delivered". These stubs satisfy the
`--phase 3` / `--phase 4` informational output referenced in FR-B810-036.
Testable: `grep -n "Phase 3\|Phase 4" docs/MIGRATIONS.md` → matches for
both; each stub contains "T7" or "T8" respectively.

##### FR-B810-053 — CLI surface doc-only for B.8.10 (ADR-B810-003)
The invocation guidance in MIGRATIONS.md and the `[NEEDS MIGRATION:]` context
MUST document a **doc-only** invocation: `bash bin/forge-migrate-flagship.sh
--target <project-dir> --dry-run`. A `forge migrate-flagship` TS subcommand
wired into commander is deferred to B.8.15 (ADR-B810-003). No TS commander
registration is authored in this brick. Testable: MIGRATIONS.md contains
`bash bin/forge-migrate-flagship.sh` as the invocation form.

##### FR-B810-054 — `scaffoldable: false` caveat documented in MIGRATIONS.md
MIGRATIONS.md MUST state that the 2.0.0 candidate remains `scaffoldable:
false` until B.8.14 and that `forge init` continues to scaffold the 1.0.0
template. Adopters using the migration script opt in explicitly; no default
migration occurs. Testable: `grep "scaffoldable.*false\|false.*scaffoldable"
docs/MIGRATIONS.md` → matches.

---

#### Group 7 — Ledger (FR-B810-060 → 062)

##### FR-B810-060 — Append a migration record to `upgrade_history` with `kind: flagship-migration`
The script MUST append one record to the `upgrade_history` list in the
target's `.forge/scaffold-manifest.yaml` after a successful Phase 2 apply
(not on `--dry-run`). The record reuses the A.7 ledger shape (observed in
`_a7_append_upgrade_history`): `date`, `from_version`, `to_version`,
`from_template_set_sha`, `to_template_set_sha`, `counts`, `cli_version`.
It MUST additionally carry a `kind: flagship-migration` marker to distinguish
it from a standard `forge upgrade` history entry (resolved: ADR-B810-004 —
reuse `_a7_append_upgrade_history` then stamp the appended entry with
`kind: flagship-migration` via a thin post-append wrapper
`_b810_tag_last_history_kind`; `forge-upgrade.sh` is NOT edited; identity
fields stay frozen, append-only). Testable: after a Phase 2 apply, the
manifest `upgrade_history` list has one new entry with `kind: flagship-migration`.

##### FR-B810-061 — Identity fields MUST NOT change
The ledger append MUST NOT modify the identity fields `project_name`,
`reverse_domain`, or `root_module` in the target's scaffold-manifest.yaml.
These fields are frozen at scaffold time (A.7 invariant, observed in
`_a7_append_upgrade_history`: "identity fields stay frozen"). Testable:
capture `project_name` + `reverse_domain` + `root_module` before and after
Phase 2 apply; they MUST be byte-identical.

##### FR-B810-062 — Append-only (no overwrite of existing history)
Each invocation MUST append a new entry; it MUST NOT remove, deduplicate,
or overwrite existing `upgrade_history` entries. Re-running Phase 2 on the
same target produces a second entry, not a replacement of the first.
Testable: apply Phase 2 twice; `upgrade_history` list has two entries.

---

#### Group 8 — Harness + CI + CHANGELOG (FR-B810-070 → 078)

##### FR-B810-070 — Harness file created, hermetic, ≤ 2 s L1, registered
The brick MUST ship `.forge/scripts/tests/b8-10.test.sh` with: `--level`
flag, `source _helpers.sh`, `run_test`, `print_summary` (mirroring b8-9
harness structure). L1 wall-clock budget **≤ 2 s** (NFR-B810-002). Zero
network, Docker, or live `forge init` calls at L1. MUST be registered as a
one-line entry `"b8-10.test.sh --level 1"` in
`.github/workflows/forge-ci.yml` after the `b8-9.test.sh` line.
**DELIVERED: 12 L1 tests, all GREEN.**

##### FR-B810-071 — Harness asserts script exists + executable + audit header
The harness MUST assert:
- `bin/forge-migrate-flagship.sh` exists (`-f`).
- The script is executable (`-x`).
- The audit comment sentinel `Audit: B.8.10 (b8-10-migrate-flagship)` is
  present in the script body (grep).
- `set -uo pipefail` is present in the script body (grep).
A missing file, non-executable bit, or absent sentinel is a FAIL.

##### FR-B810-072 — Harness asserts `--dry-run` mutates nothing on a fixture
The harness MUST set up a minimal fixture (a directory with a valid 1.0.0
`scaffold-manifest.yaml`) and assert that invoking the script with
`--dry-run` against it leaves no modified, added, or deleted files. Uses
`git status --porcelain` or equivalent diff check on the fixture. A mutation
is a FAIL. The fixture MUST be ephemeral (created in `mktemp -d` and cleaned
up after the test).

##### FR-B810-073 — Harness asserts phase selection and exit-code envelope
The harness MUST assert:
- Invocation with no `--target` → exit 2.
- Invocation with `--help` → exit 0.
- Invocation with `--target <non-1.0.0-dir>` → exit 7 (precondition not met).
- Invocation with `--phase 3` → exit 0 (forward-reference stub, not an error).
Each assertion MUST use the ephemeral fixture pattern.

##### FR-B810-074 — Harness asserts no-DBOS guard (static grep on script body)
The harness MUST grep the script body for any of the strings `dbos`,
`dbos-embedded`, `dbos_embedded` appearing as applied delta terms (outside
of a comment line). A match is a FAIL. This is the testable negative guard
for FR-B810-032. Testable pattern: `grep -v '^[[:space:]]*#' | grep -E
'dbos|dbos-embedded'` → zero matches required.

##### FR-B810-075 — Harness asserts additive-only guard (no destructive removal of protected paths)
The harness MUST grep the Phase 2 apply code path for any `rm`, `rmdir`, or
destructive `mv` targeting Kong, Temporal, or REST-bridge template paths.
A match is a FAIL. Complementary runtime assertion (if a live fixture is
available at L2): Kong + Temporal + REST paths are present after Phase 2.

##### FR-B810-076 — Harness asserts rollback targets the frozen snapshot path
The harness MUST grep the `--rollback` code path for the frozen snapshot
path `scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`. A missing
reference is a FAIL (ensures rollback does not use a dynamically generated
or alternate snapshot). Also asserts the script body does NOT contain any
write operation to `scaffold-snapshots/` (FR-B810-041 guard).

##### FR-B810-077 — Harness asserts MIGRATIONS.md section, CHANGELOG entry, and frozen-1.0.0 guard
The harness MUST assert:
- `docs/MIGRATIONS.md` contains a `1.0.0.*2.0.0` heading (grep).
- `docs/MIGRATIONS.md` contains `forge-migrate-flagship` (grep, FR-B810-051).
- `CHANGELOG.md` contains `b8-10-migrate-flagship` (whole-file grep anchored
  on the change name, NOT bare "B.8.10" — sibling false-pass prevention per
  `changelog-test [Unreleased] coupling` lesson).
- The frozen snapshot sha256 file at
  `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` is present
  and contains the expected digest (b8-2 guard reuse).

##### FR-B810-078 — Harness includes b8-2 / b8-3 coupling guards + L2 opt-in
The harness MUST include exit-code coupling guards for:
- `b8-2.test.sh --level 1` (frozen snapshot byte-identity guard).
- `b8-3.test.sh --level 1` (17/17 GREEN — schema invariants).
A FAIL in any coupling guard is a b8-10 FAIL.

The harness MUST include an **L2 opt-in** block gated on
`FORGE_B8_10_LIVE=1` (matching the `FORGE_B8_1_DOCKER=1` pattern from
b8-1.test.sh). When the env var is set, L2 MUST:
(a) create a temporary 1.0.0 scaffold fixture (via `forge init` or equivalent).
(b) run `bin/forge-migrate-flagship.sh --target <fixture> --dry-run`.
(c) assert exit 0 and no file mutation (matching FR-B810-072).
When `FORGE_B8_10_LIVE=1` is unset, the L2 block MUST emit a skip-pass
(`SKIP: FORGE_B8_10_LIVE not set`) and contribute 0 failures. The skip is
not a FAIL.

---

### Non-Functional Requirements

##### NFR-B810-001 — Zero new external dependency
`bin/forge-migrate-flagship.sh` and `b8-10.test.sh` MUST NOT introduce any
new external binary or package beyond `bash`, `git`, `python3` (stdlib +
PyYAML), `tar`, `shasum`/`sha256sum`. Mirrors NFR-B89-005. Verified by
FR-B810-006 and the harness static grep.

##### NFR-B810-002 — Harness L1 ≤ 2 s wall-clock (hermetic)
`b8-10.test.sh` L1 wall-clock MUST be ≤ **2 s** on the CI runner (no
network, no Docker, no live `forge init`). All L1 assertions are grep /
stat / file-exists / exit-code operations on ephemeral fixtures built from
scratch or on static script-body grepping.
**DELIVERED: 12 L1 tests GREEN.**

##### NFR-B810-003 — Full ~49-harness suite GREEN pre-push
Before pushing, the full forge-ci harness suite (all ~49 harnesses in
`.forge/scripts/tests/`) MUST pass (`full_harness_suite_before_push` memory
lesson). This includes b8-2 (frozen snapshot), b8-3 (schema), b8-9 (web-public)
and any harness whose repo-wide scan could be affected by the new
`bin/` script or `docs/MIGRATIONS.md` section. Versioned `N.N.N/` subtrees
are exempt from repo-wide scanner scans per convention.

##### NFR-B810-004 — Frozen 1.0.0 byte-identity preserved (b8-2 guard)
The frozen `1.0.0.tar.gz` and `1.0.0.sha256` MUST be byte-unchanged before
and after any B.8.10 deliverable is added. Any diff touching those files is
a constitutional violation (B.8.2 maintenance freeze).

##### NFR-B810-005 — SOURCE_DATE_EPOCH determinism
Any timestamp emitted by the script (ledger `date` field) MUST be
deterministic when `SOURCE_DATE_EPOCH` is set. Two invocations with the same
`SOURCE_DATE_EPOCH` and the same inputs produce byte-identical ledger output
(FR-B810-007). Verified by the L2 opt-in harness when `FORGE_B8_10_LIVE=1`.

##### NFR-B810-006 — No standard bump (constitution_version 1.1.0 unchanged)
This brick is pure tooling. No `.forge/standards/*.yaml` file is created or
modified. `constitution_version: 1.1.0` is unchanged (T5.1 precedent, proposal
Ground-Truth). Verified by diffing `.forge/standards/` before and after.

##### NFR-B810-007 — Article VIII.1 Kong preserved (additive, no removal)
The script applies Envoy in parallel. The Phase 2 code path MUST NOT remove
any Kong template, Kong configuration, or Kong service reference from the
target. VIII.1 (Kong SHALL) stays satisfied. Verified by FR-B810-031 and
the additive-only harness guard (FR-B810-075).

##### NFR-B810-008 — Article VIII.2 Temporal preserved (no DBOS)
The script MUST NOT swap out Temporal, add a `dbos` crate, or reference DBOS
as an applied delta. Temporal remains the Rust orchestrator.
VIII.2 (Temporal SHALL) stays satisfied. Verified by FR-B810-032 and the
no-DBOS harness guard (FR-B810-074).

##### NFR-B810-009 — Independent review required before /forge:plan and pre-archive
These specs passed an **independent reviewer** (not the author) before
`/forge:design` (t5-2 self-validation lesson). Self-approval of the
anti-hallucination pass and open-questions leanings is prohibited.
Independent review required again before `/forge:archive`.
**DELIVERED: independent review design + final APPROVE round 1.**

##### NFR-B810-010 — `--dry-run` default-safe (no mutation without explicit apply)
The `--dry-run` flag is the recommended first step in the adopter runbook.
Any invocation path that prints a plan MUST NOT write, delete, or modify any
file in the target. This invariant applies to all phases and to `--rollback`.
Verified by FR-B810-014 / FR-B810-022 / FR-B810-035 / FR-B810-043 and
the harness dry-run fixture assertion (FR-B810-072).

---

## Architecture Decision Records

| ADR | Decision | As-Implemented Resolution |
|-----|----------|--------------------------|
| **ADR-B810-001** | Overlay mechanism | The script `source`s `bin/forge-upgrade.sh` (safe — `_a7_main` runs only under the `[[ BASH_SOURCE == $0 ]]` guard) and reuses `_a7_resolve_owned_paths` / `_a7_three_way_merge` / `_a7_check_force_clean_git` against the 2.0.0 template set as the merge RIGHT. A second merge engine is NOT introduced. The script deliberately NEVER calls `_a7_check_version_compat` (that guard is what delegated here). |
| **ADR-B810-002** | Exit-code envelope + flags | Corrected from spec lean `0/1/2/7` at `/forge:design`: aligned to A.7's actual envelope `0/2/5/7/8` (`1` is unused by A.7; conflicts surface as exit-8). `--rollback` is mutually exclusive with `--phase` (rollback overrides). `--dry-run` default-safe across all phases. |
| **ADR-B810-003** | CLI surface | Doc-only invocation for B.8.10: `bash bin/forge-migrate-flagship.sh --target <project-dir> --dry-run`. A `forge migrate-flagship` TS subcommand wired into commander is deferred to B.8.15. No TS commander registration authored in this brick. |
| **ADR-B810-004** | Ledger `kind` marker | Reuse `_a7_append_upgrade_history` then stamp the appended entry with `kind: flagship-migration` via a thin post-append wrapper `_b810_tag_last_history_kind`. `forge-upgrade.sh` is NOT edited (owned file). Identity fields stay frozen, append-only. |
| **ADR-B810-005** | Phase 2 canary | Document-only — the script prints canary-by-route Kong→Envoy guidance in MIGRATIONS.md as a manual adopter step; actual per-route cutover wiring is B.8.12. Phase 2 does NOT auto-configure canary weights or route splits. |

---

## BDD Acceptance Criteria

```gherkin
Feature: forge-migrate-flagship.sh orchestrates the 1.0.0→2.0.0 additive migration
  without removing Kong/Temporal/REST, without scaffolding DBOS, and with
  dry-run safety and rollback from the byte-frozen 1.0.0 snapshot
  As a Forge adopter with a 1.0.0 full-stack-monorepo project
  I want a phased migration script that additively applies the 2.0.0 template
  overlays with a safe dry-run preview and a byte-verified rollback
  So that I can migrate to the 2.0.0 candidate at my own pace, inspect every
  change before it is applied, and revert safely if needed

  Scenario: dry-run on a 1.0.0 fixture reports the plan and mutates nothing
    Given a valid 1.0.0 full-stack-monorepo target (scaffold-manifest.yaml:
          archetype_version=1.0.0, archetype=full-stack-monorepo)
    And the frozen 1.0.0 snapshot sha256 matches 1.0.0.sha256 (b8-2 guard)
    And the target is a clean Git working tree
    When I invoke bin/forge-migrate-flagship.sh --target <dir> --dry-run
    Then the script exits 0
    And stdout contains a structured migration plan listing all 5 additive deltas
    And no file in the target directory is created, modified, or deleted
    And git status --porcelain on the target is empty after the run

  Scenario: Phase 0 aborts on a non-1.0.0 or dirty-Git target
    Given a target directory with scaffold-manifest.yaml archetype_version != 1.0.0
    When I invoke bin/forge-migrate-flagship.sh --target <dir>
    Then the script exits 7
    And stderr contains "forge-migrate-flagship:" and an actionable remediation hint

    Given a target directory that is a 1.0.0 full-stack-monorepo with uncommitted changes
    And --force is NOT passed
    When I invoke bin/forge-migrate-flagship.sh --target <dir>
    Then the script exits 7
    And stderr directs the adopter to stash or commit first

  Scenario: rollback restores from the frozen snapshot without rebuilding it
    Given a 1.0.0 target that has had Phase 2 overlays applied
    And the frozen 1.0.0 snapshot at .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz
    And the snapshot sha256 matches the 1.0.0.sha256 companion file
    When I invoke bin/forge-migrate-flagship.sh --target <dir> --rollback
    Then the script exits 0
    And the target is restored to match the frozen 1.0.0 snapshot content
    And the 1.0.0.tar.gz file is byte-identical to before the rollback (MUST NOT be rebuilt)
    And the 1.0.0.sha256 file is byte-identical to before the rollback
```
