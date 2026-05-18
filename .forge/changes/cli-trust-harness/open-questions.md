# Open Questions: cli-trust-harness
<!-- Created: 2026-05-14 -->
<!-- Audit: T5.1 (docs/new-archetypes-plan.md §0.1) -->

Questions raised during `/forge:propose`. All MUST be resolved (status
`answered` or `wontfix`) before `/forge:plan` runs, per `verify.sh`
Open Questions Gate (Article III.4 / `global/open-questions.md`).

---

## Q-001 — Toolchain availability handling in T5.1.B

**Status** : answered (ADR-T51-001)

**Raised by** : proposal.md § T5.1.B (smoke test per archetype)

**Question** : how should the harness handle the case where `task`,
`flutter`, or `cargo` are absent from PATH on the runner machine ?

Three options on the table :

- **A. Skip-pass via env-var (proposed)** — `FORGE_E2E_TOOLCHAINS=1`
  enables the tighter checks ; default off ; mirrors
  `t5-otel-app.test.sh::_test_ota_l2_002_flutter_analyze` and
  `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`. Skip-pass each tool
  independently when its binary is absent.
- **B. Hard requirement** — fail the test when any expected
  toolchain is missing. Forces the CI matrix to install `task`
  alongside Node 20.18.0. Stricter ; closer to what an adopter
  would see ; but makes contributor PRs harder.
- **C. Adaptive (auto-detect)** — run the check if the binary is
  on PATH, silently skip otherwise, no env-var gate. Easiest UX
  but loses the audit signal (you can't tell from CI logs whether
  the check was skipped or genuinely passed).

**Affects** : NFR-T51-001 (zero new external dep), NFR-T51-002
(harness wall-clock budget), FR-T51-B-xxx (smoke matrix).

**Likely resolution** : **Option A** + a `task` install step in the
existing `forge-ci.yml` `harness` matrix job (so `task --list-all`
always runs under CI, while `flutter` / `cargo` stay opt-in).

**Resolution** : <!-- to be filled by /forge:design via ADR-T51-001 -->

---

## Q-002 — Archetype fixture file format

**Status** : answered (ADR-T51-002)

**Raised by** : proposal.md § T5.1.B step 3 (file matrix declaration)

**Question** : the per-archetype expected-files matrix lives in
fixture files at `cli/test/e2e/archetype-fixtures/<name>.yml`. Should
the format be YAML or JSON ?

- **YAML (proposed)** — matches Forge convention
  (`dispatch-table.yml`, `framework-owned-paths.yml`, `.forge.yaml`,
  `change.schema.json` consumes `.forge.yaml`). Allows comments
  explaining why a path is in the matrix.
- **JSON** — vitest-native, no YAML parser needed in the test
  pipeline (vitest doesn't ship one by default). Forces a tiny
  YAML dependency in `cli/package.json::devDependencies`.

**Affects** : NFR-T51-001 (zero new external dep) — YAML would
require `yaml` or `js-yaml` package in the CLI tree.

**Likely resolution** : **YAML** + a vendored 1-file minimal YAML
parser in `cli/test/e2e/helpers/yaml-load.ts` (~50 LOC, restricted
to the flat key:value + list-of-strings + nested-map subset the
fixtures need — no anchors, no flow style, no advanced features).
Justified by Forge convention and by the `cli/src/domain/dispatch-table.ts`
precedent which already parses `dispatch-table.yml` with a hand-rolled
parser.

**Resolution** : <!-- to be filled by /forge:design via ADR-T51-002 -->

---

## Q-003 — Pre-publish gate isolation mechanism (T5.1.C)

**Status** : answered (ADR-T51-003)

**Raised by** : proposal.md § T5.1.C (pre-publish tarball gate)

**Question** : how should `cli/scripts/prepublish-smoke.mjs` install
the packed tarball to exercise the actual published binary, without
polluting the maintainer's global npm prefix ?

Three options :

- **A. `npm install --prefix=<tmp> --global <tarball>`** — standard
  isolation pattern ; respects `prefix` for both bin and lib.
  `<tmp>/bin/forge` is the binary the smoke runs.
- **B. `npx --no-install <tarball>`** — npx 7+ can execute a local
  tarball directly. Cleaner UX but less explicit about where the
  binary lives ; debugging on failure is harder.
- **C. `tar -xz + node <extracted>/dist/index.js`** — manual extraction,
  no npm machinery. Tightest isolation ; bypasses `bin/` symlink
  resolution which is part of what we want to validate.

**Affects** : FR-T51-C-001 (isolation strategy), NFR-T51-003
(prepublish gate idempotency + cleanup).

**Likely resolution** : **Option A**. It exercises the same code
path adopters trigger via `npm install -g @sdd-forge/cli` or
`npx @sdd-forge/cli init` (post-publish). The tmpdir is cleaned up
in a `try/finally`. Both A and B will work ; A is more explicit
in failure logs.

**Resolution** : <!-- to be filled by /forge:design via ADR-T51-003 -->

---

## Q-004 — Replace or augment existing e2e tests ?

**Status** : answered (ADR-T51-004)

**Raised by** : proposal.md § Scope Out (last bullet on replacing
`cli/test/e2e/cli.test.ts`)

**Question** : `cli/test/e2e/cli.test.ts` already contains :

- `--help` lists `init` / `verify` / `version`
- `forge version` prints a SemVer
- `forge init --help` lists `--eu-tier` (regression added v0.3.2)
- `forge init --target <tmp>` scaffolds against the repo (default archetype)
- `published-tarball layout (bundled assets/)` block re-runs against
  packed assets

Should T5.1.B / T5.1.A subsume these tests (refactor / consolidate),
or run alongside them (additive only) ?

- **A. Augment only (proposed)** — `cli.test.ts` keeps its 5
  existing tests verbatim ; the new `help-snapshots.test.ts` adds
  golden-snapshot coverage ; the new `archetypes-smoke.test.ts`
  adds per-non-default-archetype coverage. Net positive : no
  coverage lost, no churn risk.
- **B. Consolidate** — fold the existing `--help` / `version` /
  default-archetype tests into the new files, delete `cli.test.ts`.
  Smaller surface but risks losing tests during the move.

**Affects** : FR-T51-A-001 (snapshot scope), FR-T51-B-001 (smoke
scope).

**Likely resolution** : **Option A**. The existing tests are working
; we add coverage rather than churn the file structure.

**Resolution** : <!-- to be filled by /forge:design via ADR-T51-004 -->

---

## Q-005 — Emergency override for pre-publish gate ?

**Status** : answered (ADR-T51-005)

**Raised by** : proposal.md § Impact (Risk level paragraph)

**Question** : should the pre-publish gate (T5.1.C) ship with an
emergency escape hatch (`FORGE_SKIP_PREPUBLISH=1`) hat lets the
maintainer ship a tarball even when the smoke fails ?

- **A. Yes (proposed)** — `FORGE_SKIP_PREPUBLISH=1` skips
  `prepublish-smoke.mjs` with a loud stderr warning. Necessary
  if a known-broken-but-not-blocking regression must ship for
  CVE-style urgency.
- **B. No** — every publish goes through the gate. Forces the
  maintainer to land a hotfix change + re-run before publish.

**Affects** : FR-T51-C-002 (override semantics), NFR-T51-004
(release process integrity).

**Likely resolution** : **Option A** + an audit line in
`GOVERNANCE.md § Release Process` describing the override and
mandating a follow-up issue if it's ever used. Mirrors the existing
`FORGE_LINTER_SKIP_*` opt-outs in `constitution-linter.sh` which
also exist for emergency cases.

**Resolution** : <!-- to be filled by /forge:design via ADR-T51-005 -->

---

## Resolution summary

| ID    | Status   | Resolution                                                                                                          |
|-------|----------|---------------------------------------------------------------------------------------------------------------------|
| Q-001 | answered | **ADR-T51-001** — Opt-in via `FORGE_E2E_TOOLCHAINS=1` + `task` always installed in CI via `arduino/setup-task@v2`. |
| Q-002 | answered | **ADR-T51-002** — YAML fixtures + vendored 1-file mini-parser (~80 LOC) ; zero new external dep.                   |
| Q-003 | answered | **ADR-T51-003** — `npm install --prefix=<tmp> --global <tarball>` (exercises real `bin/` symlink resolution).      |
| Q-004 | answered | **ADR-T51-004** — Augment ; existing `cli/test/e2e/cli.test.ts` stays verbatim ; new files add coverage on top.    |
| Q-005 | answered | **ADR-T51-005** — `FORGE_SKIP_PREPUBLISH=1` allowed ; loud `BYPASS` log + mandatory follow-up issue per GOVERNANCE. |
