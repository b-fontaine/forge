# Design: cli-trust-harness
<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: T5.1 (docs/new-archetypes-plan.md §0.1) -->

> Read alongside `specs.md` (FR-T51-* / NFR-T51-*) and
> `open-questions.md` (Q-001..Q-005). This document locks the
> implementation strategy and resolves Q-001..Q-005 via
> ADR-T51-001..005.

## Architecture Decisions

### ADR-T51-001 — Toolchain availability : opt-in via env-var, skip-pass otherwise (resolves Q-001)

**Context** : Q-001 weighed three options for handling missing
`task` / `flutter` / `cargo` on the runner :

- **Option A** — `FORGE_E2E_TOOLCHAINS=1` opts into tighter checks ;
  default off ; skip-pass each tool independently.
- **Option B** — Hard requirement ; CI matrix installs all three.
- **Option C** — Auto-detect on PATH ; silently skip otherwise ; no
  env-var gate.

**Decision** : **Option A — opt-in via `FORGE_E2E_TOOLCHAINS=1` +
skip-pass with a `[INFO: ...]` log line**, with **one exception** :
`task` is treated specially — it MUST always be on PATH in CI, and
the GitHub Actions workflow installs it explicitly. Rationale :

1. `task --list-all` is the **only** check that would have caught the
   originating 23-day-old `Taskfile.yml.tmpl:67` bug. Skipping it
   silently defeats the purpose of the harness.
2. `flutter` and `cargo` are much heavier to install (200 MB+ each
   for the Flutter SDK, several minutes for `rustup`). Defaulting
   them off keeps PR CI fast.
3. Mirrors the `t5-otel-app.test.sh::_test_ota_l2_002_flutter_analyze`
   pattern (skip-pass `flutter` when absent) and the
   `t5-otel-live-run.test.sh::_test_t5_otel_live_run_l2`
   pattern (opt-in via env-var). Two precedents from T5 already.
4. Option C (silent skip) loses the audit signal — a CI run with all
   3 toolchains absent would be indistinguishable from a CI run that
   passed every check.

**Concrete behavior** :

- `task` : install in `.github/workflows/forge-ci.yml` `harness` job
  via `arduino/setup-task@v2` (apache-2.0, official action). Skip-pass
  in `archetypes-smoke.test.ts` if local dev machine lacks it.
- `cargo` : skip-pass by default. Tighter check runs when
  `FORGE_E2E_TOOLCHAINS=1` AND `command -v cargo` is true.
- `flutter` : skip-pass by default. Tighter check runs when
  `FORGE_E2E_TOOLCHAINS=1` AND `command -v flutter` is true.
- All three skip-pass cases MUST log
  `[INFO: <tool> absent on PATH — skipped per ADR-T51-001]` so the
  decision is visible in CI logs.

**Consequences** :

- ✅ CI catches the Taskfile bug class.
- ✅ Default CI run completes in ≤ 30 s ; tighter checks only on
  opt-in machines (maintainer pre-release verification).
- ⚠️ Adds one external CI action dependency (`arduino/setup-task@v2`).
  Justified : the action is open-source, ~1 KB of YAML, pinned by
  major-version (`@v2`) for supply-chain safety per
  `global/sbom-policy.md::SBOM-RULE-002`.

**Constitution Compliance** : Article I (TDD — the harness's RED →
GREEN cycle remains hermetic on the L1 grep path). Article IX
(Observability — `[INFO: ...]` audit lines preserve traceability).

---

### ADR-T51-002 — YAML fixtures + vendored mini-parser (resolves Q-002)

**Context** : Q-002 weighed YAML vs JSON for the per-archetype
fixture file at `cli/test/e2e/archetype-fixtures/<name>.yml`.

**Decision** : **YAML**, parsed via a vendored 1-file mini-parser at
`cli/test/e2e/helpers/load-fixture.ts` (~80 LOC, restricted to the
subset the fixtures use). Rationale :

1. Forge convention is YAML for declarative configuration
   (`dispatch-table.yml`, `framework-owned-paths.yml`, `.forge.yaml`,
   `.forge/standards/*.yaml`). The fixtures fall in the same
   category.
2. JSON would force one of :
   - A new dep on `js-yaml` or `yaml` (violates NFR-T51-001).
   - Translating each fixture by hand (loses commentability).
3. The `cli/src/domain/dispatch-table.ts` precedent already
   hand-rolls a YAML parser for the same use case (flat key-value +
   nested map + list-of-strings, no flow style, no anchors). The
   helper MAY re-export from there or duplicate the logic — see
   "Implementation strategy" below.

**Parser subset supported** (formally documented in the helper's
header comment) :

- Top-level `key: value` pairs where `value` is a scalar (string,
  boolean, integer).
- Nested mapping under a key (one level deep).
- Block-style lists under a key
  (`key:\n  - item1\n  - item2`).
- Block-style scalar lists where each item is a string.
- Leading `#` comments (skipped).

**Not supported** (any usage triggers a clear parse error) :

- Flow style (`key: [a, b]` or `key: {a: 1}`).
- YAML anchors / merge keys.
- Multi-document files (`---` separator).
- Multi-line block scalars (`|`, `>`).

**Consequences** :

- ✅ Zero new external dep (NFR-T51-001 honored).
- ✅ Fixtures stay in the Forge idiom.
- ⚠️ The mini-parser is a maintenance surface ; mitigated by ~80 LOC
  ceiling + a dedicated vitest test
  (`cli/test/domain/load-fixture.test.ts`) covering the subset.

**Constitution Compliance** : Article I (TDD — parser ships with its
own test before any fixture is loaded). Article III.4 (the parser
fails loudly on unsupported syntax rather than mis-parsing).

---

### ADR-T51-003 — Pre-publish isolation : `npm install --prefix=<tmp> --global` (resolves Q-003)

**Context** : Q-003 weighed three isolation mechanisms for
`prepublish-smoke.mjs` :

- **Option A** — `npm install --prefix=<tmp> --global <tarball>`.
- **Option B** — `npx --no-install <tarball>`.
- **Option C** — `tar -xz` + direct `node <extracted>/dist/index.js`.

**Decision** : **Option A — `npm install --prefix=<tmp> --global`**.

**Rationale** :

1. Exercises the same code path an adopter triggers via
   `npm install -g @sdd-forge/cli` after the publish. The binary
   resolves via the `bin/` symlink ; the `package.json::bin` entry
   is consulted ; ESM module resolution honors `package.json::type`.
   Each of those was a source of historical bugs (v0.2.0 → v0.2.1
   shipped an empty tarball because `files:` was wrong ; the
   bundled-tarball test in `cli/test/e2e/cli.test.ts` was added in
   response).
2. Option B (`npx`) is newer / less stable across npm versions ;
   debugging on failure is harder (npm caches the tarball
   transparently).
3. Option C bypasses the `bin/` symlink resolution entirely — exactly
   the layer we want to validate.

**Concrete sequence** (pseudocode) :

```js
const pkgRoot = path.resolve(__dirname, '..');
const tarball = execSync('npm pack', { cwd: pkgRoot }).toString().trim().split('\n').pop();
const tarballPath = path.join(pkgRoot, tarball);

const installPrefix = await mkdtemp(path.join(tmpdir(), 'forge-prepublish-install-'));
try {
  execSync(`npm install --prefix=${installPrefix} --global ${tarballPath}`, { stdio: 'inherit' });
  const installedBin = path.join(installPrefix, 'bin', 'forge');

  const scaffoldTmp = await mkdtemp(path.join(tmpdir(), 'forge-prepublish-scaffold-'));
  await rm(scaffoldTmp, { recursive: true }); // exercise mkdir -p path
  try {
    execSync(`${installedBin} init smoke-fsm --archetype full-stack-monorepo --org dev.forge.test --target ${scaffoldTmp}`, { stdio: 'inherit' });
    assertFileMatrix(scaffoldTmp, loadFixture('full-stack-monorepo'));
    if (commandExists('task')) {
      execSync(`task --list-all`, { cwd: scaffoldTmp, stdio: 'inherit' });
    }
    console.log('[PASS] T5.1 pre-publish smoke');
  } finally {
    await rm(scaffoldTmp, { recursive: true, force: true });
  }
} catch (err) {
  console.error('[FAIL] tarball=' + tarballPath);
  console.error('[FAIL] install-prefix=' + installPrefix);
  process.exit(1);
} finally {
  await rm(installPrefix, { recursive: true, force: true });
  // Clean the tarball too — it's regenerated on each invocation.
  await rm(tarballPath, { force: true });
}
```

**Consequences** :

- ✅ Realistic publish-path coverage.
- ✅ Hermetic — maintainer's global prefix never touched.
- ⚠️ Adds ~10-15 s to `npm publish` invocations (the `npm pack` +
  `npm install` cycle). Tolerable for a release-time gate ;
  un-tolerable would have been per-commit.

**Constitution Compliance** : Article VIII (Infrastructure — the
script is local, no daemon). Article XII (Release Process — the
gate slots into the existing maintainer-driven workflow).

---

### ADR-T51-004 — Augment, don't replace, `cli/test/e2e/cli.test.ts` (resolves Q-004)

**Context** : Q-004 weighed whether the new
`help-snapshots.test.ts` + `archetypes-smoke.test.ts` should
**replace** or **augment** the existing `cli/test/e2e/cli.test.ts`.

**Decision** : **Augment**. The existing 5 tests stay verbatim ; the
two new files add coverage on top.

**Rationale** :

1. The existing tests are passing. Refactoring them to extract their
   logic into the new files risks regressions (test code is still
   code).
2. Three of the existing tests target the `default` archetype which
   the new `archetypes-smoke.test.ts` explicitly skips (per
   FR-T51-041). The roles are complementary.
3. The "regression v0.3.2 `--eu-tier`" test is in `cli.test.ts` ; it
   stays as belt-and-suspenders alongside the new golden snapshot.
4. Future cleanup is always possible — if the test surface grows
   unwieldy in T6 / T7, consolidation can happen as a separate
   change.

**File-by-file role** post-change :

| File                                       | Role                                                                     |
|--------------------------------------------|--------------------------------------------------------------------------|
| `cli/test/e2e/cli.test.ts`                 | Default archetype + `--help` + `version` + `--eu-tier` regression       |
| `cli/test/e2e/help-snapshots.test.ts`      | Golden snapshot of every subcommand's `--help` + dispatch cross-check   |
| `cli/test/e2e/archetypes-smoke.test.ts`    | Per-non-default-archetype scaffold + file matrix + `task --list-all`    |

**Consequences** :

- ✅ Zero regression risk on existing coverage.
- ⚠️ Some surface duplication between `cli.test.ts::--eu-tier` and
  the golden snapshot of `init --help`. Acceptable redundancy.

**Constitution Compliance** : Article I (TDD — existing tests remain
RED-able for future refactors). Article V (audit — the v0.3.2
regression's test is preserved verbatim, satisfying the audit-trail
intuition that tests for past bugs stay in place).

---

### ADR-T51-005 — Emergency override allowed via `FORGE_SKIP_PREPUBLISH=1` (resolves Q-005)

**Context** : Q-005 weighed whether the pre-publish gate should
have an escape hatch.

**Decision** : **Yes — `FORGE_SKIP_PREPUBLISH=1`**, with the loud
`[WARN: ...BYPASS...]` log line + follow-up issue obligation
documented in GOVERNANCE.md.

**Rationale** :

1. Forge is small (one maintainer). A blocking gate with no escape
   creates a single point of failure if the gate itself is buggy
   (e.g. a transient `npm pack` flake, a `task` install issue in
   GitHub Actions).
2. The maintainer's mental model of release process must allow
   "ship anyway, fix later" for true emergencies (security CVE,
   blocker in an adopter's prod). The override exists for that
   path.
3. The `BYPASS` keyword in the stderr line makes post-incident
   grep trivial — anyone auditing release logs can spot every use
   of the override.
4. Mirrors `FORGE_LINTER_SKIP_*` opt-outs in
   `constitution-linter.sh` which also exist for the same class of
   emergencies.

**Concrete behavior** :

- Default : `FORGE_SKIP_PREPUBLISH` unset or `0` → gate runs.
- Override : `FORGE_SKIP_PREPUBLISH=1` → smoke script prints
  `[WARN: T5.1 BYPASS — FORGE_SKIP_PREPUBLISH=1 set ; pre-publish smoke skipped. File a follow-up issue.]`
  to stderr and exits 0 without running.
- GOVERNANCE.md § Release Process gains :
  > **`FORGE_SKIP_PREPUBLISH=1`** : reserved for emergency
  > releases when the T5.1 pre-publish gate itself blocks
  > legitimate work (e.g. transient npm registry flakes, gate
  > false-positives). Every use of this variable MUST be followed
  > within 7 days by a GitHub issue at
  > `github.com/bfontaine/forge/issues` titled
  > `[T5.1 bypass post-mortem] vX.Y.Z` and labeled
  > `cli-trust-harness`. The issue MUST document what went wrong,
  > what was bypassed, and what fix landed.

**Consequences** :

- ✅ Pragmatic safety valve.
- ✅ Audit trail preserved (stderr line + mandatory issue).
- ⚠️ Discipline depends on the maintainer following the
  "file an issue" rule. Mitigated by the loudness of the warning
  message + the BDFL governance model (one person, one process).

**Constitution Compliance** : Article XII (Governance — the
override is part of the documented Release Process). Article V
(Audit — the bypass leaves a traceable record).

---

## Technical Design

### File layout post-change

```
cli/
├── package.json                          # MR-T51-001 : prepublishOnly extended
├── scripts/
│   └── prepublish-smoke.mjs              # NEW : Layer T5.1.C
└── test/
    └── e2e/
        ├── cli.test.ts                   # UNCHANGED (ADR-T51-004)
        ├── help-snapshots.test.ts        # NEW : Layer T5.1.A
        ├── archetypes-smoke.test.ts      # NEW : Layer T5.1.B
        ├── __snapshots__/
        │   └── help/                     # NEW : 5 .snap.txt files
        │       ├── root.snap.txt
        │       ├── init.snap.txt
        │       ├── upgrade.snap.txt
        │       ├── verify.snap.txt
        │       └── version.snap.txt
        ├── archetype-fixtures/
        │   ├── full-stack-monorepo.yml   # NEW : matrix declaration
        │   └── mobile-only.yml           # NEW : matrix declaration
        └── helpers/
            └── load-fixture.ts           # NEW : mini-YAML parser

.forge/
├── templates/
│   └── archetypes/
│       └── full-stack-monorepo/
│           └── Taskfile.yml.tmpl         # MR-T51-003 : line 67 single-quoted
└── scripts/
    └── tests/
        └── t5-1.test.sh                  # NEW : harness ≥ 16 L1 + 2 L2

.github/workflows/
└── forge-ci.yml                          # MR-T51-002 : harness matrix +1 row

GOVERNANCE.md                              # MR-T51-004 : release-process gate doc
CHANGELOG.md                               # FR-T51-150 : [Unreleased] entry
docs/
├── new-archetypes-plan.md                # FR-T51-152 : §0.1 + §1.4 + §11 flips
└── ARCHETYPES.md                         # MR-T51-005 : snapshot pointer
.forge/product/roadmap.md                  # FR-T51-151 : Planned → Done flip

examples/forge-fsm-example/Taskfile.yml    # MR-T51-003 mirror
cli/assets/                                # MR-T51-003 mirror via npm run bundle
```

### Fixture YAML schema (informal)

```yaml
# Audit: T5.1 (cli-trust-harness) — fixture for archetype <name>
archetype: full-stack-monorepo            # echoed for cross-check

has_rust_backend: true                    # gates FR-T51-050
has_flutter_frontend: true                # gates FR-T51-051

required_paths:
  - .forge/constitution.md
  - .claude/settings.json
  - bin/forge-install.sh
  - Taskfile.yml
  - backend
  - frontend
  - proto/buf.gen.yaml

forbidden_paths:
  - cli
  - .claude/settings.local.json
```

The mini-parser (`load-fixture.ts`) returns a typed shape :

```ts
export interface ArchetypeFixture {
  archetype: string;
  has_rust_backend: boolean;
  has_flutter_frontend: boolean;
  required_paths: string[];
  forbidden_paths: string[];
}
```

### Harness L1 anchor list (FR-T51-124)

| ID                                         | Asserts                                                                                            |
|--------------------------------------------|----------------------------------------------------------------------------------------------------|
| `_test_t51_l1_001_taskfile_line67_quoted`  | `Taskfile.yml.tmpl:67` matches `'echo "infra tests: delegated …'`                                  |
| `_test_t51_l1_002_no_unquoted_colon_space` | No `cmds:`-list plain scalar matches `^[[:space:]]*- echo "[^"]*: ` across templates                |
| `_test_t51_l1_003_help_snapshots_file`     | `cli/test/e2e/help-snapshots.test.ts` exists + audit comment                                       |
| `_test_t51_l1_004_snapshots_dir_5files`    | `cli/test/e2e/__snapshots__/help/` contains 5 `.snap.txt` files                                    |
| `_test_t51_l1_005_smoke_file`              | `cli/test/e2e/archetypes-smoke.test.ts` exists + audit comment                                     |
| `_test_t51_l1_006_fixture_fsm`             | `archetype-fixtures/full-stack-monorepo.yml` exists + audit comment                                |
| `_test_t51_l1_007_fixture_mobile_only`     | `archetype-fixtures/mobile-only.yml` exists + audit comment                                        |
| `_test_t51_l1_008_load_fixture_helper`     | `helpers/load-fixture.ts` exists + audit comment                                                   |
| `_test_t51_l1_009_prepublish_script`       | `cli/scripts/prepublish-smoke.mjs` exists + audit comment                                          |
| `_test_t51_l1_010_prepublish_wired`        | `cli/package.json::prepublishOnly` ends with `node scripts/prepublish-smoke.mjs`                   |
| `_test_t51_l1_011_skip_prepublish_env`     | `FORGE_SKIP_PREPUBLISH` referenced in `cli/scripts/prepublish-smoke.mjs`                           |
| `_test_t51_l1_012_toolchains_env`          | `FORGE_E2E_TOOLCHAINS` referenced in `cli/test/e2e/archetypes-smoke.test.ts`                       |
| `_test_t51_l1_013_changelog_entry`         | `CHANGELOG.md [Unreleased]` contains `cli-trust-harness`                                            |
| `_test_t51_l1_014_governance_gate_doc`     | `GOVERNANCE.md § Release Process` mentions `prepublishOnly` + `FORGE_SKIP_PREPUBLISH`               |
| `_test_t51_l1_015_ci_registration`         | `.github/workflows/forge-ci.yml` registers `t5-1.test.sh`                                          |
| `_test_t51_l1_016_dispatch_xref`           | Every non-`removed_from_roadmap` archetype in `dispatch-table.yml` has a fixture file               |
| `_test_t51_l1_017_ci_line_budget`          | `.github/workflows/forge-ci.yml` ≤ 300 lines                                                       |

17 L1 anchors — exceeds the ≥ 16 floor (FR-T51-124).

### L2 opt-in fixtures (FR-T51-125)

- **`_test_t51_l2_smoke_one_archetype`** — gated by `FORGE_T51_LIVE=1`.
  Invokes `vitest run cli/test/e2e/archetypes-smoke.test.ts -t 'full-stack-monorepo'`.
  Skip-pass when env-var absent (mirrors `t5-otel-live-run`).
- **`_test_t51_l2_pack_isolation`** — gated by `FORGE_T51_PACK=1`.
  Invokes `node cli/scripts/prepublish-smoke.mjs --dry-run` (the
  script honors a `--dry-run` flag : `npm pack` runs, install runs,
  smoke runs, but no cleanup error if anything explodes ;
  cleanup still attempted). Asserts the isolated tmpdir was created
  and removed. Skip-pass when env-var absent.

### Snapshot capture mechanism (FR-T51-022..024)

Uses vitest's built-in `toMatchFileSnapshot` (vitest 2.x ; already
in `cli/package.json::devDependencies`). The matcher writes the
captured stdout to the path on first run if missing, and diffs on
subsequent runs. `vitest -u` updates intentionally.

Example test body :

```ts
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const CLI = resolve(__dirname, "..", "..", "dist", "index.js");

function captureHelp(args: string[]): string {
  const r = spawnSync(process.execPath, [CLI, ...args, "--help"], {
    encoding: "utf8",
    env: { ...process.env, NO_COLOR: "1", FORCE_COLOR: "0" },
  });
  return (r.stdout ?? "").replace(/\r\n/g, "\n").replace(/[ \t]+$/gm, "");
}

describe("cli help snapshots", () => {
  it.each(["", "init", "upgrade", "verify", "version"])(
    "captures forge %s --help",
    (subcommand) => {
      const args = subcommand ? [subcommand] : [];
      const stdout = captureHelp(args);
      const name = subcommand || "root";
      expect(stdout).toMatchFileSnapshot(`__snapshots__/help/${name}.snap.txt`);
    }
  );
});
```

### Cross-check assertion (FR-T51-025)

```ts
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { parseDispatchTable } from "../../src/domain/dispatch-table.js";

it("forge init --help mentions every active archetype from dispatch-table", () => {
  const dispatchYaml = readFileSync(
    resolve(__dirname, "..", "..", "..", ".forge/scaffolding/dispatch-table.yml"),
    "utf8",
  );
  const table = parseDispatchTable(dispatchYaml);
  const active = Object.values(table.archetypes).filter(
    (e) => (e as any).status !== "removed_from_roadmap",
  );
  const initHelp = captureHelp(["init"]);
  for (const arch of active) {
    expect(initHelp, `missing '${arch.name}' in forge init --help`).toContain(arch.name);
  }
});
```

### Smoke loop pseudocode (FR-T51-040..055)

```ts
describe.each(activeArchetypes())("smoke: %s", (entry) => {
  it("scaffolds + matches fixture + task --list-all OK", async () => {
    const tmp = await mkdtemp(join(tmpdir(), `forge-smoke-${entry.name}-`));
    await rm(tmp, { recursive: true, force: true }); // exercise mkdir -p path
    try {
      const r = spawnSync(process.execPath, [CLI, "init",
        `smoke-${entry.name}`,
        "--archetype", entry.name,
        "--org", "dev.forge.test",
        "--target", tmp,
      ], { encoding: "utf8", env: { ...process.env, NO_COLOR: "1" } });
      expect(r.status, `stderr:\n${r.stderr}`).toBe(0);

      const fixture = loadFixture(entry.name);
      for (const p of fixture.required_paths) {
        expect(existsSync(join(tmp, p)), `required path missing: ${p}`).toBe(true);
      }
      for (const p of fixture.forbidden_paths) {
        expect(existsSync(join(tmp, p)), `forbidden path present: ${p}`).toBe(false);
      }

      if (commandOnPath("task")) {
        const t = spawnSync("task", ["--list-all"], { cwd: tmp, encoding: "utf8" });
        expect(t.status, `task --list-all failed:\n${t.stderr}`).toBe(0);
      } else {
        console.log("[INFO: task absent on PATH — skipped per ADR-T51-001]");
      }

      if (process.env.FORGE_E2E_TOOLCHAINS === "1") {
        if (fixture.has_rust_backend && commandOnPath("cargo")) {
          const c = spawnSync("cargo", ["check", "--workspace"], { cwd: join(tmp, "backend"), encoding: "utf8" });
          expect(c.status).toBe(0);
        }
        if (fixture.has_flutter_frontend && commandOnPath("flutter")) {
          const f = spawnSync("flutter", ["analyze"], { cwd: join(tmp, "frontend"), encoding: "utf8" });
          expect(f.status).toBe(0);
        }
      }
    } finally {
      await rm(tmp, { recursive: true, force: true });
    }
  });
});
```

### Sweep recipe for FR-T51-002

```bash
# Phase 2 of tasks.md uses this exact recipe to enumerate matches :
grep -rn --include='*.tmpl' --include='Taskfile.yml' \
  -E '^[[:space:]]*-[[:space:]]+(echo|printf|"[^"]*: ).*: ' \
  .forge/templates/ examples/ cli/assets/ \
  | grep -v "'echo" \
  | grep -v '#'
```

The grep produces a list of matches. Each is hand-quoted by the
maintainer (single-quote the entire shell command). Re-running the
grep MUST produce zero matches post-fix.

### CI matrix entry

Add immediately after the `f3.test.sh` row in
`.github/workflows/forge-ci.yml::harness::strategy::matrix::test` :

```yaml
- name: t5-1
  script: .forge/scripts/tests/t5-1.test.sh
  level: "1"
```

Plus, in the same job's `steps:` block before the matrix execution,
install `task` via :

```yaml
- name: Install go-task
  uses: arduino/setup-task@v2
  with:
    version: "3.x"
    repo-token: ${{ secrets.GITHUB_TOKEN }}
```

This makes `task --list-all` always available in CI (per
ADR-T51-001 exception clause).

---

## Test Strategy

| Layer | Test depth | Skip-pass mechanism                                       |
|-------|------------|-----------------------------------------------------------|
| T5.1.0 | Grep + the L1 harness asserts the line is quoted          | None — the fix is permanent                                |
| T5.1.A | Vitest snapshot assertion ; harness asserts file presence | None — `--help` always runs                                |
| T5.1.B | Vitest e2e per archetype ; harness asserts file presence  | `task` skip-pass when absent ; `cargo` / `flutter` opt-in  |
| T5.1.C | Harness asserts wiring ; L2 opt-in `FORGE_T51_PACK=1`     | L2 skip-pass when env-var absent                            |

---

## Migration / rollout

This change is purely additive on test infrastructure. No adopter
sees a behavior change at install time. The maintainer sees one
behavior change : `npm publish` now refuses to proceed if the
smoke fails (unless `FORGE_SKIP_PREPUBLISH=1` is set, with a
mandatory follow-up issue).

**Rollout sequence** :

1. Land the change as PR `cli-trust-harness` against `main`
   (not `optim`, per the additive nature confirmed in §0.1 of the
   plan).
2. Wait for CI green (the new harness + the existing 14 harnesses
   all run on PR).
3. Merge.
4. Maintainer tags **v0.3.3** in a separate step using
   `scripts/release.sh --version 0.3.3 --otp <…>` — the
   `prepublishOnly` hook exercises the new gate on the very tarball
   being published. If the gate is buggy in any way, the maintainer
   sees the failure **before** the tarball escapes.

---

## Risks + mitigations

| Risk                                                       | Probability | Impact | Mitigation                                                                                                |
|------------------------------------------------------------|-------------|--------|-----------------------------------------------------------------------------------------------------------|
| `arduino/setup-task@v2` action is unmaintained or hijacked | Low         | Low    | Pin major-version ; review per `global/sbom-policy.md` before merge                                       |
| `npm pack` produces a different tarball than `npm publish` would | Very low    | High   | Industry standard semantics ; if discovered, escape-hatch via `FORGE_SKIP_PREPUBLISH` while a fix lands    |
| The mini YAML parser mis-parses a fixture edge case        | Low         | Medium | Dedicated vitest test for the parser ; restricted documented subset ; reject unsupported syntax loudly    |
| Smoke takes too long and slows down PR feedback            | Low         | Medium | NFR-T51-002 budget ≤ 30 s ; skip-pass `cargo`/`flutter` ; only `task --list-all` runs by default          |
| A future archetype has runtime semantics that can't be skip-passed (e.g. requires a network call) | Medium      | Medium | Address in that archetype's change ; the fixture YAML can grow new `skip_if:` keys additively              |
| GitHub Actions `setup-task` action fails on a release      | Low         | High   | `FORGE_SKIP_PREPUBLISH=1` emergency override + post-incident issue                                        |

---

## ADR summary table

| ADR ID        | Question                                                | Decision                                                                |
|---------------|---------------------------------------------------------|-------------------------------------------------------------------------|
| ADR-T51-001   | Q-001 — toolchain handling                              | Opt-in via `FORGE_E2E_TOOLCHAINS=1`, `task` always installed in CI       |
| ADR-T51-002   | Q-002 — fixture file format                             | YAML, parsed by vendored 1-file mini-parser (~80 LOC)                   |
| ADR-T51-003   | Q-003 — pre-publish isolation mechanism                 | `npm install --prefix=<tmp> --global <tarball>`                          |
| ADR-T51-004   | Q-004 — replace or augment existing e2e tests           | Augment ; existing `cli.test.ts` stays verbatim                          |
| ADR-T51-005   | Q-005 — emergency override                              | `FORGE_SKIP_PREPUBLISH=1` allowed ; loud BYPASS log + mandatory issue   |
