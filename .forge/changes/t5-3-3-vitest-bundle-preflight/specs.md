# Specifications: t5-3-3-vitest-bundle-preflight
<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: T5.3.3 (docs/new-archetypes-plan.md §0.6) -->

**Namespace** : `FR-T533-*` / `NFR-T533-*`. **Constitution** :
v1.1.0, unchanged. **Article II** : N/A.

## Source Documents

| Field                       | Value                                                                                                                  |
|-----------------------------|------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**                | `docs/new-archetypes-plan.md` §0.6                                                                                     |
| **Origin**                  | T5.3.1 code-reviewer LOW finding (2026-05-19) + user-reproduced failure (2026-05-20) on `npx vitest run`                |
| **Bypass surface**          | `cli/test/e2e/archetypes-smoke.test.ts` calls `node cli/dist/index.js init` → rsync from `cli/assets/` (gitignored)    |
| **Files touched (new)**     | `cli/test/global-setup.ts`                                                                                             |
| **Files touched (edit)**    | `cli/vitest.config.ts` (add `globalSetup` key)                                                                         |
| **Standard touched**        | none                                                                                                                   |
| **Snapshot touched**        | none                                                                                                                   |
| **Harness frame**           | `_helpers.sh` ; new `t5-3-3.test.sh` (5 L1 grep)                                                                        |
| **CI matrix**               | `.github/workflows/forge-ci.yml` (currently 299/300 after T5.3.1 ; +1 entry → 300/300 budget edge)                      |
| **Release vehicle**         | `v0.4.0-rc.2` — same as T5.3.1                                                                                         |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Global setup file (FR-T533-001 → 005)

##### FR-T533-001 — `cli/test/global-setup.ts` exists

A new file `cli/test/global-setup.ts` MUST exist, written
in TypeScript with Node.js stdlib only (no new dep).

##### FR-T533-002 — Exports default vitest globalSetup signature

The file MUST export a default function with the vitest
globalSetup signature (`() => void | Promise<void>` or
`() => { teardown?: () => void | Promise<void> }`).

##### FR-T533-003 — Invokes `npm run bundle` from cli/

The default export MUST `spawnSync("npm", ["run", "bundle"],
{ cwd: <repo cli/>, stdio: "inherit" })` or equivalent, with
`shell: false` for safety.

##### FR-T533-004 — Asserts exit 0

If the bundle process exits non-zero, the globalSetup MUST
throw a clear Error message containing the exit code AND
indicating that the test suite cannot proceed without a
fresh bundle. Stderr from the bundle MUST be surfaced
(`stdio: "inherit"` is sufficient).

##### FR-T533-005 — Audit comment

The file MUST carry an audit comment in the header :
```typescript
// <!-- Audit: T5.3.3 (t5-3-3-vitest-bundle-preflight) -->
```

#### Cluster 2 — Vitest config wiring (FR-T533-020 → 022)

##### FR-T533-020 — `globalSetup` key added

`cli/vitest.config.ts::test.globalSetup` MUST be set to
`"./test/global-setup.ts"` (string, single setup file).

##### FR-T533-021 — Other config preserved

All existing config keys (`include`, `environment`,
`coverage`) MUST remain unchanged.

##### FR-T533-022 — Type-safe

`tsc --noEmit -p tsconfig.json` from `cli/` MUST exit 0
after the change (no new TypeScript errors).

#### Cluster 3 — Harness (FR-T533-040 → 050)

##### FR-T533-040 — New file `t5-3-3.test.sh`

A new file `.forge/scripts/tests/t5-3-3.test.sh` MUST exist,
executable bash, mirroring the T5.3.1 / T5.2 harness frame
(`set -uo pipefail`, audit comment, `--level` parsing,
`_helpers.sh` source, manifest comment block).

##### FR-T533-041 — ≥ 5 L1 grep tests

| Test ID                                       | Asserts                                                                                                |
|-----------------------------------------------|--------------------------------------------------------------------------------------------------------|
| `_test_t533_l1_001_global_setup_exists`       | `cli/test/global-setup.ts` exists                                                                       |
| `_test_t533_l1_002_global_setup_audit_comment`| audit comment `T5.3.3 (t5-3-3-vitest-bundle-preflight)` present                                         |
| `_test_t533_l1_003_global_setup_spawns_bundle`| file contains `npm` AND `bundle` AND `spawnSync` (or `spawn`)                                           |
| `_test_t533_l1_004_vitest_config_wired`       | `cli/vitest.config.ts` contains `globalSetup` AND `"./test/global-setup.ts"`                            |
| `_test_t533_l1_005_changelog_entry`           | `CHANGELOG.md` mentions `t5-3-3-vitest-bundle-preflight`                                                |

##### FR-T533-042 — No L2 test (deliberate)

Unlike T5.3.1 and other recent changes, T5.3.3 ships **no
L2 test**. The L2 equivalent — actually running `vitest`
against a stale `cli/assets/` — is intrinsically covered by
the vitest suite itself : if globalSetup fails to rebuild,
the e2e tests FAIL on stale assets, which is the inverse
proof. Adding a dedicated L2 here would be redundant.

##### FR-T533-043 — Determinism

L1 tests MUST be deterministic — no `$RANDOM`, no network,
no spawn. Pure grep on the 3 files.

##### FR-T533-044 — CI registration

`.github/workflows/forge-ci.yml` MUST register
`t5-3-3.test.sh` after `t5-3-1.test.sh` with `--level 1`.
File must stay ≤ 300 lines (NFR-CI-002). Current 299 → +3
expected (entry with comment) → 302. **Compression of an
existing comment block REQUIRED** to fit.

#### Cluster 4 — Documentation (FR-T533-060 → 062)

##### FR-T533-060 — CHANGELOG entry

`CHANGELOG.md` under `[Unreleased]` MUST gain :
```markdown
### Added — vitest globalSetup bundle preflight (T5.3.3, `t5-3-3-vitest-bundle-preflight`)
- `cli/test/global-setup.ts` runs `npm run bundle` once
  before every vitest suite, closing the bypass where
  `npx vitest run` skipped the bundle (T5.3.1 reviewer LOW
  finding).
- Wired via `cli/vitest.config.ts::test.globalSetup`.
- Catches stale `cli/assets/` mirror state regardless of
  how vitest is invoked.
```

##### FR-T533-061 — Plan inventory

Add row to `docs/new-archetypes-plan.md` inventory :
```
| t5-3-3-vitest-bundle-preflight | archived | T5.3.3 (vitest globalSetup bundle preflight) |
```
Count 30 → 31.

##### FR-T533-062 — Plan §0.6

Add §0.6 "T5.3.3 — vitest bundle preflight" briefly
documenting the change (1 short section, no architectural
verbiage).

### Non-Functional Requirements

##### NFR-T533-001 — Zero new external dep

No new entry in `cli/package.json::dependencies` or
`devDependencies`. The bundle invocation uses Node.js
stdlib (`child_process`) and the `npm` CLI already present.

##### NFR-T533-002 — Bundle wall-clock budget

`globalSetup` adds ≤ 30 s to a clean tsc + assets copy
vitest run. Warm cache : ≤ 5 s. Documented as acceptable.

##### NFR-T533-003 — `forge-ci.yml` ≤ 300 lines

Current 299 ; T5.3.3 entry adds ~3 lines without
compression → 302 > 300. Compression of one existing
comment block REQUIRED to satisfy NFR-CI-002.

##### NFR-T533-004 — No regression

`verify.sh` + `constitution-linter.sh` OVERALL stay PASS.
All prior harnesses + the new `t5-3-3.test.sh` stay GREEN.

### Open Decisions Deferred to `/forge:design`

| ID                | Decision                                                                                  | Owner             |
|-------------------|-------------------------------------------------------------------------------------------|-------------------|
| `ADR-T533-001`    | Use `spawnSync` (synchronous) vs `spawn` + Promise (async) for the bundle invocation     | Atlas             |
| `ADR-T533-002`    | `forge-ci.yml` compression target — which existing comment block to trim                  | Atlas             |

Resolved inline in design.md since both decisions are
low-stakes implementation details with no controversy.

---

## Anti-Hallucination Pass

| Surface                                                | Verified via                                                                                    |
|--------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| vitest globalSetup API exists                          | `cli/vitest.config.ts` already imports from `"vitest/config"` ; globalSetup is documented vitest API |
| `cli/assets/` is gitignored                            | `grep "^assets/" cli/.gitignore` returned hit (T5.3.1 review evidence)                          |
| `npm run bundle` works from `cli/`                     | Executed twice during T5.3.1 implementation (Phase 3 T-MIR-002/003)                              |
| `cli/test/e2e/archetypes-smoke.test.ts` spawns CLI     | T5.3.1 L2 test reproduces the same pattern (verified)                                            |
| CI line count post-T5.3.1                              | `wc -l .github/workflows/forge-ci.yml` returned 299 (T5.3.1 evidence ledger)                    |

No invented API. Vitest `globalSetup` is a documented
feature ; the spawn pattern is Node.js stdlib.

---

*Next : `/forge:design t5-3-3-vitest-bundle-preflight`.*
