# Specifications: cli-trust-harness
<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: T5.1 (docs/new-archetypes-plan.md §0.1) -->

**Namespace** : `FR-T51-*` / `NFR-T51-*`. **Constitution** : v1.1.0.
No amendment required (T5.1 ships test harness + 1 template-bug fix ;
modifies no Article).

## Source Documents

| Field                  | Value                                                                                                                                                                                                            |
|------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**           | `docs/new-archetypes-plan.md` §0.1 (T5.1 — CLI Trust Harness planned 2026-05-14) ; §1.4 table row ; §4.2 B.8.15 (Layer D deferred) ; §11 priorisation row                                                          |
| **Roadmap ref**        | `.forge/product/roadmap.md` "v0.3.x deliveries" Planned T5.1 entry ; Phase 3 T6 quarterly (B.8.15) ; Phase 3 Items detail B.8 row                                                                                  |
| **Originating bug 1**  | `cli/src/cli.ts` missing `.option("--eu-tier <tier>", ...)` ; fixed v0.3.2 commit `4a33bdc`. Detected only when published binary invoked against fresh install                                                    |
| **Originating bug 2**  | `cli/src/commands/init-archetype.ts:148` missing `await mkdir(opts.targetDir, { recursive: true })` ; fixed v0.3.2                                                                                                |
| **Originating bug 3**  | `.forge/scripts/scaffolder/init.sh:168` collision guard on existing dir regardless of contents ; fixed v0.3.2                                                                                                     |
| **Originating bug 4**  | `.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl:67` plain-YAML scalar with `: ` parsed as mapping by go-task ; broken since B.1 archive 2026-04-21                                              |
| **Dispatch table**     | `.forge/scaffolding/dispatch-table.yml` (3 active : `default`, `full-stack-monorepo`, `mobile-only` ; 1 `removed_from_roadmap` : `flutter-firebase`)                                                              |
| **Existing CLI e2e**   | `cli/test/e2e/cli.test.ts` (127 LOC, 5 tests : `--help`, `version`, `init --help --eu-tier`, `init --target` default-archetype, published-tarball layout)                                                         |
| **Existing harness**   | `.forge/scripts/tests/_helpers.sh` (shared assertions + `run_test` + `print_summary` runner) ; reference patterns `f3.test.sh` (10 L1 + 1 L2), `i6.test.sh` (14 L1 + 2 L2), `t5-otel-live-run.test.sh` (8 L1 + 1 L2 opt-in) |
| **CI matrix**          | `.github/workflows/forge-ci.yml` `harness` job (286 lines today ; NFR-CI-002 ≤ 300)                                                                                                                                |
| **Release process**    | `GOVERNANCE.md § Release Process` step 4 (`bash scripts/release.sh --version X.Y.Z --otp 123456`) — the `prepublishOnly` gate inserts between `bundle` and the implicit `npm publish`                              |
| **Constitution refs**  | Article I (TDD), III (specs before code), III.4 (anti-hallucination), V (audit trail), XII (governance/release process)                                                                                            |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Layer T5.1.0 : Taskfile template sweep (FR-T51-001 → 010)

##### FR-T51-001 — Line 67 single-quoted

The line `.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl:67`
MUST be rewritten so the entire shell command is a single-quoted YAML
scalar :

```yaml
      - 'echo "infra tests: delegated to b1-delivery workflows"'
```

The runtime semantics of the command MUST be byte-identical to the
pre-fix line (same string echoed). Only the YAML quoting changes.

##### FR-T51-002 — Template-wide sweep

Every `*.tmpl` and template file under `.forge/templates/`, `examples/`,
and `cli/assets/` MUST be swept for the pattern : a YAML list item
under `cmds:` containing a plain-scalar `: ` (colon + space) inside an
unescaped string. Each match MUST be either :

- Single-quoted in its entirety, OR
- Re-emitted using YAML block-scalar form (`|` or `>`)

The chosen form per match SHOULD be the minimum change that yields
parseable YAML.

##### FR-T51-003 — Sweep tool reproducibility

The sweep MUST be re-runnable post-merge by executing
`grep -rn 'cmds:' .forge/templates/ examples/ cli/assets/ | …`
(precise recipe documented in `design.md`). No match left unfixed
MUST exit cleanly.

##### FR-T51-004 — Mirror to `cli/assets/`

The bundled-asset mirror at
`cli/assets/.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl`
and `cli/assets/examples/forge-fsm-example/Taskfile.yml` (post-bundle
artefacts) MUST also be fixed, either by direct edit OR by re-running
`npm run bundle` so the assets stay in sync.

##### FR-T51-005 — Example mirror

The committed `examples/forge-fsm-example/Taskfile.yml` (rendered
example) MUST also be fixed if the same line exists there.

##### FR-T51-006 — Audit comment on edited files

Each edited template file MUST receive a 1-line comment near the fix
documenting the audit ID :

```yaml
# Audit: T5.1 (cli-trust-harness) — single-quote shell command containing ': '
```

The comment MAY be omitted if the file already carries a generic
audit-tag header that covers all subsequent edits.

#### Cluster 2 — Layer T5.1.A : Golden flag snapshots (FR-T51-020 → 039)

##### FR-T51-020 — Test file presence

A new vitest file `cli/test/e2e/help-snapshots.test.ts` MUST exist.

##### FR-T51-021 — Audit comment

The file MUST carry `// Audit: T5.1 (cli-trust-harness)` within the
first 10 lines.

##### FR-T51-022 — Captured surfaces

The file MUST capture the stdout of each invocation below into a
golden snapshot under `cli/test/e2e/__snapshots__/help/` :

- `forge --help`
- `forge init --help`
- `forge upgrade --help`
- `forge verify --help`
- `forge version --help`

##### FR-T51-023 — Snapshot file layout

Each captured surface MUST live in its own snapshot file named
`cli/test/e2e/__snapshots__/help/<command>.snap.txt` (text format ;
not the vitest default `.snap` JS format — see ADR-T51-002 rationale).
Content MUST be the raw stdout with trailing whitespace trimmed and
ANSI escapes stripped (`NO_COLOR=1` env on invocation).

##### FR-T51-024 — Snapshot diff fails

A diff between the freshly-captured stdout and the committed snapshot
MUST fail the test. The test author MUST update the snapshot
**deliberately** by running `vitest -u` (vitest update-snapshots flag,
respected by the matcher).

##### FR-T51-025 — Dispatch-table cross-reference

A separate test in the same file MUST :

1. Load `.forge/scaffolding/dispatch-table.yml`.
2. Filter `archetypes` to entries whose `status:` is not
   `removed_from_roadmap` (i.e. `default`, `full-stack-monorepo`,
   `mobile-only` today ; future archetypes auto-picked up).
3. Capture `forge init --help` stdout.
4. Assert each filtered archetype name appears literally in the
   stdout (description, example, or flag default value).

##### FR-T51-026 — Cross-reference failure message

If FR-T51-025 fails, the assertion message MUST identify the missing
archetype name(s) explicitly so the maintainer can either add the
archetype to the help text or mark it as removed.

##### FR-T51-027 — `--eu-tier` regression coverage preserved

The existing `cli/test/e2e/cli.test.ts` regression
"`forge init --help` lists the `--eu-tier` flag" (added v0.3.2) MUST
NOT be deleted. It stays as belt-and-suspenders coverage.

#### Cluster 3 — Layer T5.1.B : Smoke per archetype (FR-T51-040 → 089)

##### FR-T51-040 — Test file presence

A new vitest file `cli/test/e2e/archetypes-smoke.test.ts` MUST exist
with `// Audit: T5.1 (cli-trust-harness)` in the first 10 lines.

##### FR-T51-041 — Iteration source

The test MUST iterate over the entries of
`.forge/scaffolding/dispatch-table.yml::archetypes`, skipping :

- `default` (already covered by the existing e2e `init --target`
  default-archetype test).
- Entries with `status: removed_from_roadmap`.
- Entries with `status: legacy_alias` UNLESS their `target:` archetype
  is also absent (forward-compatibility for B.9 — once `mobile-pwa-first`
  ships, the `mobile-only` legacy alias's smoke gets handled by its
  target's fixture).

##### FR-T51-042 — Non-existent target dir

For each remaining archetype, the test MUST :

1. Compute a tmpdir path via `mkdtemp` + `rm` so the path is known
   but does NOT exist on disk at invocation time (exercises the
   v0.3.2 `mkdir -p` fix in `cli/src/commands/init-archetype.ts:148`).

##### FR-T51-043 — Invocation form

The test MUST invoke the published CLI with :

```
forge init <project-slug> --archetype <name> --org dev.forge.test --target <tmp>
```

`<project-slug>` MUST be a deterministic kebab-case value derived
from the archetype name (e.g. `smoke-full-stack-monorepo`). `<tmp>`
MUST be the non-existent path from FR-T51-042.

##### FR-T51-044 — Exit 0 required

The invocation MUST exit 0. Non-zero exit MUST fail the test with
stderr captured in the assertion message.

##### FR-T51-045 — File matrix assertion

After invocation, the test MUST load a fixture YAML at
`cli/test/e2e/archetype-fixtures/<archetype-name>.yml` defining two
lists :

- `required_paths:` — paths (relative to `<tmp>`) that MUST exist.
- `forbidden_paths:` — paths that MUST NOT exist (e.g. `cli/`).

The test MUST assert each required path resolves to an existing
file or directory, and each forbidden path does not.

##### FR-T51-046 — Fixture audit comment

Each fixture YAML MUST carry a leading comment :
`# Audit: T5.1 (cli-trust-harness) — fixture for archetype <name>`.

##### FR-T51-047 — Fixture loader location

The fixture YAML MUST be loaded via a helper
`cli/test/e2e/helpers/load-fixture.ts` that wraps the
flat-YAML parser shared with `cli/src/domain/dispatch-table.ts`
where possible (NFR-T51-001 — zero new external dep).

##### FR-T51-048 — `task --list-all` execution

After file-matrix assertion, the test MUST run `task --list-all` in
the scaffolded tmpdir and assert exit 0.

##### FR-T51-049 — Skip-pass when `task` absent

If `task` is not on PATH (resolved via `which task` or equivalent),
the `task --list-all` check MUST skip-pass with a clear
`[INFO: task absent — skipped]` line in stdout, NOT fail.

##### FR-T51-050 — Tighter check : `cargo check`

When `FORGE_E2E_TOOLCHAINS=1` is set in the env AND the archetype's
fixture declares `has_rust_backend: true`, the test MUST run
`cargo check --workspace` in `<tmp>/backend` and assert exit 0.
Skip-pass if `cargo` absent.

##### FR-T51-051 — Tighter check : `flutter analyze`

When `FORGE_E2E_TOOLCHAINS=1` is set AND fixture declares
`has_flutter_frontend: true`, the test MUST run `flutter analyze` in
`<tmp>/frontend` and assert exit 0. Skip-pass if `flutter` absent.

##### FR-T51-052 — Cleanup

Each archetype iteration MUST `rm -rf` its tmpdir in a `try/finally`
block, regardless of test outcome.

##### FR-T51-053 — Fixture for `full-stack-monorepo`

The fixture `cli/test/e2e/archetype-fixtures/full-stack-monorepo.yml`
MUST declare at minimum the following required paths :

- `.forge/constitution.md`
- `.claude/settings.json`
- `bin/forge-install.sh`
- `Taskfile.yml`
- `backend/` (directory)
- `frontend/` (directory)
- `proto/buf.gen.yaml`

And the following forbidden paths :

- `cli/` (CLI tree must never leak)
- `.claude/settings.local.json` (private config)

`has_rust_backend: true` and `has_flutter_frontend: true` MUST be
declared.

##### FR-T51-054 — Fixture for `mobile-only`

The fixture `cli/test/e2e/archetype-fixtures/mobile-only.yml` MUST
declare at minimum :

- `.forge/constitution.md`
- `pubspec.yaml`
- `ios/Runner/Info.plist`
- `android/app/build.gradle`
- `lib/core/auth/oidc_config.dart`

Forbidden : `cli/`, `.claude/settings.local.json`, `backend/`,
`Cargo.toml`. `has_flutter_frontend: true`.

##### FR-T51-055 — Future-archetype handling

If `dispatch-table.yml` lists an archetype with no fixture file at
`cli/test/e2e/archetype-fixtures/<name>.yml`, the test MUST fail
with a clear message :

```
T5.1 smoke: archetype '<name>' lacks a fixture. Add cli/test/e2e/archetype-fixtures/<name>.yml.
```

This guarantees new archetypes cannot be added without paying the
test-coverage tax.

#### Cluster 4 — Layer T5.1.C : Pre-publish tarball gate (FR-T51-090 → 119)

##### FR-T51-090 — Smoke script presence

A new file `cli/scripts/prepublish-smoke.mjs` MUST exist as a Node ESM
script with `// Audit: T5.1 (cli-trust-harness)` in the first 10
lines.

##### FR-T51-091 — `npm pack` invocation

The script MUST invoke `npm pack` in `cli/` (or its own resolved
package root) and capture the produced tarball path.

##### FR-T51-092 — Tarball extraction

The script MUST extract the tarball into a hermetic tmpdir created
with `mkdtemp`.

##### FR-T51-093 — Isolated install

The script MUST install the extracted package into an isolated npm
prefix via `npm install --prefix=<isolated-tmp> --global
<extracted-pkg>`. The maintainer's global npm prefix MUST NOT be
touched.

##### FR-T51-094 — Smoke against installed binary

The script MUST re-run a subset of the T5.1.B smoke (full
`full-stack-monorepo` archetype scaffold + file-matrix assertion +
`task --list-all` if `task` on PATH) using
`<isolated-tmp>/bin/forge` as the CLI binary.

##### FR-T51-095 — Cleanup on success

On success, the script MUST remove both tmpdirs (`isolated-tmp` +
`scaffold-tmp`) and exit 0.

##### FR-T51-096 — Failure post-mortem

On failure, the script MUST :

- Print the captured tarball path to stderr (so the maintainer can
  inspect it post-mortem).
- Print the scaffold tmpdir path (left in place for inspection).
- Print the failed assertion or command output.
- Exit non-zero.

##### FR-T51-097 — Wiring in `prepublishOnly`

`cli/package.json::scripts.prepublishOnly` MUST be extended to call
the smoke script after the existing `lint && test && bundle` chain :

```json
"prepublishOnly": "npm run lint && npm test && npm run bundle && node scripts/prepublish-smoke.mjs"
```

##### FR-T51-098 — Emergency override

The script MUST honor `FORGE_SKIP_PREPUBLISH=1` by printing a loud
stderr warning and exiting 0 without running the smoke. The warning
text MUST include the literal string `BYPASS` so post-incident greps
can find it :

```
[WARN: T5.1 BYPASS — FORGE_SKIP_PREPUBLISH=1 set ; pre-publish smoke skipped. File a follow-up issue.]
```

##### FR-T51-099 — GOVERNANCE.md note

`GOVERNANCE.md § Release Process` MUST gain a sub-bullet documenting
the new gate + the override + the mandate to file a follow-up issue
if the override is ever used.

#### Cluster 5 — Harness + CI (FR-T51-120 → 149)

##### FR-T51-120 — Harness file presence

A new file `.forge/scripts/tests/t5-1.test.sh` MUST exist as an
executable bash harness.

##### FR-T51-121 — Strict mode + audit comment

The harness MUST declare `set -uo pipefail` and carry
`# Audit: T5.1 (cli-trust-harness)` in the first 10 lines.

##### FR-T51-122 — `_helpers.sh` sourcing

The harness MUST source `.forge/scripts/tests/_helpers.sh` for the
shared assertion + runner machinery.

##### FR-T51-123 — `--level` parsing

The harness MUST accept `--level <1|2|1,2|all>` and gate L2 tests
accordingly (mirrors `f3.test.sh`).

##### FR-T51-124 — ≥ 16 L1 tests

The harness MUST register **at least 16 L1 hermetic grep-based tests**
covering :

- `Taskfile.yml.tmpl:67` single-quoted (T5.1.0)
- No other unfixed `: `-bearing plain-scalar in `cmds:` lists across templates
- `help-snapshots.test.ts` exists + audit comment (T5.1.A)
- `__snapshots__/help/` dir exists + has 5 files
- `archetypes-smoke.test.ts` exists + audit comment (T5.1.B)
- `archetype-fixtures/full-stack-monorepo.yml` exists
- `archetype-fixtures/mobile-only.yml` exists
- `helpers/load-fixture.ts` exists
- `prepublish-smoke.mjs` exists + audit comment (T5.1.C)
- `package.json::prepublishOnly` references `prepublish-smoke.mjs`
- `FORGE_SKIP_PREPUBLISH` mentioned in the smoke script body
- `FORGE_E2E_TOOLCHAINS` mentioned in `archetypes-smoke.test.ts`
- CHANGELOG `[Unreleased]` entry for `cli-trust-harness`
- `GOVERNANCE.md § Release Process` mentions the new gate
- `.github/workflows/forge-ci.yml` registers `t5-1.test.sh`
- Cross-reference assertion : every non-`removed_from_roadmap`
  archetype in `dispatch-table.yml` has a fixture file.

##### FR-T51-125 — L2 fixture tests (opt-in)

The harness MUST register **at least 2 L2 tests** :

- `_test_t51_l2_smoke_one_archetype` — gated by `FORGE_T51_LIVE=1`.
  Runs the full `archetypes-smoke.test.ts` against a single
  archetype (`full-stack-monorepo`) end-to-end. Skip-pass when
  env-var absent (mirrors `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`).
- `_test_t51_l2_pack_isolation` — gated by `FORGE_T51_PACK=1`. Runs
  `prepublish-smoke.mjs` in dry-run mode + asserts the isolated
  tmpdir is created and cleaned up. Skip-pass when env-var absent.

##### FR-T51-126 — CI registration

`.github/workflows/forge-ci.yml` `harness` job matrix MUST register
`t5-1.test.sh` immediately after `f3.test.sh` with `--level 1`.

##### FR-T51-127 — `forge-ci.yml` line budget

After the registration, `.github/workflows/forge-ci.yml` MUST remain
≤ 300 lines (NFR-CI-002 / NFR-T51-005).

#### Cluster 6 — Documentation + audit trail (FR-T51-150 → 169)

##### FR-T51-150 — CHANGELOG entry

`CHANGELOG.md` `[Unreleased]` section MUST gain a
`### Added — CLI Trust Harness (T5.1, cli-trust-harness)` block
describing the four layers + Taskfile fix in adopter-readable prose.

##### FR-T51-151 — Roadmap flip

`.forge/product/roadmap.md` "Planned T5.1" row MUST flip to
"Done 2026-05-XX via `cli-trust-harness`" with the same shape as the
existing `f3-release-script-fix` Done row.

##### FR-T51-152 — Plan flip

`docs/new-archetypes-plan.md` §0.1 MUST gain a closing paragraph
"Done 2026-05-XX via `cli-trust-harness`". §1.4 + §11 rows flip
Planned → Done.

##### FR-T51-153 — Inventory rows

The `Inventaire .forge/changes/` tables in both
`docs/new-archetypes-plan.md` (§0.0) and `.forge/product/roadmap.md`
MUST gain a new row :

```
| `cli-trust-harness` | archived | T5.1 (CLI Trust Harness) |
```

##### FR-T51-154 — Total archived count bumped

The "X archivés" total in both inventory sections MUST be
incremented from 24 to 25.

### Non-Functional Requirements

##### NFR-T51-001 — Zero new external dep

The change MUST NOT add any new entry to `cli/package.json::dependencies`
or `cli/package.json::devDependencies` beyond what already exists.
Vitest, commander, the TS toolchain, and Node 20 are the only allowed
inputs. (Mirrors NFR-J7-001 / NFR-K3-DEM-004 / NFR-I6-CA-004 precedents.)

##### NFR-T51-002 — Harness wall-clock budget

`bash .forge/scripts/tests/t5-1.test.sh --level 1` MUST complete in
≤ 5 s on the maintainer's machine (M1 Mac baseline). Vitest e2e suite
including `help-snapshots.test.ts` + `archetypes-smoke.test.ts`
(skip-pass `task` / `cargo` / `flutter`) MUST complete in ≤ 30 s.

##### NFR-T51-003 — Pre-publish gate idempotency

`prepublish-smoke.mjs` MUST be idempotent : invoking it twice in
succession on a clean tree MUST produce the same exit code (and
cleanup must succeed both times). Tmpdirs MUST be unique per
invocation (`mkdtemp` provides this).

##### NFR-T51-004 — Release process integrity

If `FORGE_SKIP_PREPUBLISH=1` is used, the bypass MUST be detectable
post-hoc by grepping the release log for the literal `BYPASS` string
emitted on stderr (FR-T51-098). The maintainer commits to filing a
follow-up issue per `GOVERNANCE.md` update (FR-T51-099).

##### NFR-T51-005 — `forge-ci.yml` size

`.github/workflows/forge-ci.yml` MUST remain ≤ 300 lines after the
registration (per NFR-CI-002, currently 286 lines ; new row adds
~2-3 lines).

##### NFR-T51-006 — Backwards compat of existing tests

`cli/test/e2e/cli.test.ts` MUST remain functional and pass without
modification (per ADR-T51-004 augment-only choice). The default
archetype path + the bundled-tarball test stay verbatim.

##### NFR-T51-007 — Deterministic snapshots

The captured `--help` snapshots (FR-T51-022) MUST be deterministic
across runs : invoking each `--help` twice MUST produce
byte-identical stdout (no timestamps, no random IDs, `NO_COLOR=1`
forced).

##### NFR-T51-008 — Cleanup guarantee

Every test in `archetypes-smoke.test.ts` MUST clean up its tmpdir on
both success and failure paths (try/finally). Repeated invocations
of `vitest run` MUST NOT leak tmpdirs into `/tmp/` beyond the test's
own lifetime.

##### NFR-T51-009 — Harness self-discoverability

The harness MUST print a usage block when invoked with `--help` or
`-h` describing the L1 / L2 levels + the L2 env-var gates (mirrors
`f3.test.sh`).

##### NFR-T51-010 — Source-of-truth for `--help` documentation

The captured snapshots (FR-T51-022) MUST be referenced from
`docs/ARCHETYPES.md` (or the relevant adopter-facing doc) as the
authoritative invocation reference, so the maintainer's GitHub
Discussions posts can copy from there rather than retyping the ABI.

### Removed Requirements

None. T5.1 is purely additive.

### Modified Requirements

##### MR-T51-001 — `cli/package.json::scripts.prepublishOnly` extended

The existing `prepublishOnly` script gains `&& node scripts/prepublish-smoke.mjs`
at the tail. Existing chain (`lint && test && bundle`) preserved
verbatim.

##### MR-T51-002 — `.github/workflows/forge-ci.yml::harness` matrix extended

The matrix gains one entry registering `t5-1.test.sh --level 1`
after the `f3.test.sh` entry. No other job touched.

##### MR-T51-003 — `.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl:67` quoted

Per FR-T51-001. Byte-identical runtime semantics ; only YAML quoting
changes.

##### MR-T51-004 — `GOVERNANCE.md § Release Process` step 4 augmented

Step 4 sub-bullet describing the `prepublishOnly` gate + the
`FORGE_SKIP_PREPUBLISH=1` override + the follow-up-issue obligation.

##### MR-T51-005 — `docs/ARCHETYPES.md` references the help snapshots

A new section / pointer at the top of `docs/ARCHETYPES.md` directs
readers to `cli/test/e2e/__snapshots__/help/init.snap.txt` for the
authoritative `forge init` invocation form.

---

## BDD Scenarios (Article II)

### Scenario 1 — Happy publish path (maintainer-facing)

```gherkin
Feature: Pre-publish gate (T5.1.C)

  Scenario: Maintainer publishes a clean tarball
    Given the repository is at HEAD after archiving `cli-trust-harness`
    And the maintainer has bumped VERSION to "0.3.3"
    And CHANGELOG.md has a sealed `## [0.3.3]` block
    When the maintainer runs `bash scripts/release.sh --version 0.3.3 --otp 123456`
    Then the script reaches `npm publish` only after `prepublish-smoke.mjs` exits 0
    And the smoke logs "[PASS] T5.1 pre-publish smoke" on stdout
    And `npm publish` uploads the same tarball the smoke just exercised
    And the maintainer's global npm prefix is unchanged
```

### Scenario 2 — Regression catch (would have blocked v0.3.0)

```gherkin
Feature: Pre-publish gate catches missing flag wiring

  Scenario: A future PR omits a commander flag for a flag declared in init.ts
    Given a developer adds a new option to `cli/src/commands/init.ts`
    But forgets to wire `.option(...)` in `cli/src/cli.ts`
    When the developer pushes the PR
    Then the CI runs `help-snapshots.test.ts`
    And the snapshot diff fails because the option is missing from `forge init --help`
    And the PR is blocked
```

### Scenario 3 — Empty-target-dir regression (would have blocked v0.3.1)

```gherkin
Feature: Smoke per archetype catches scaffold-time spawn failures

  Scenario: forge init against a non-existent target dir
    Given a fresh adopter has `task` installed but has never run `forge init`
    When the smoke test runs `forge init smoke-fsm --archetype full-stack-monorepo --org dev.forge.test --target <non-existent-tmpdir>`
    Then the CLI internally creates the target dir before spawning the bash scaffolder
    And the bash scaffolder exits 0
    And `task --list-all` in the scaffolded dir exits 0
    And the file matrix in `full-stack-monorepo.yml` is satisfied
```

### Scenario 4 — Taskfile YAML regression (would have caught the original bug)

```gherkin
Feature: Smoke per archetype catches broken Taskfile templates

  Scenario: A template introduces an unquoted `: ` in a `cmds:` list
    Given a contributor edits `Taskfile.yml.tmpl` and writes `- echo "foo: bar"` unquoted
    When the CI runs `archetypes-smoke.test.ts`
    Then the scaffolded project's `task --list-all` exits non-zero with `invalid keys in command`
    And the test fails the CI run
    And the contributor must single-quote the line before merge
```

### Scenario 5 — New archetype lands without a fixture

```gherkin
Feature: New archetypes pay the test-coverage tax

  Scenario: A new archetype is added to dispatch-table.yml without a fixture
    Given a contributor adds `event-driven-eu:` to `.forge/scaffolding/dispatch-table.yml`
    But forgets to create `cli/test/e2e/archetype-fixtures/event-driven-eu.yml`
    When the CI runs `archetypes-smoke.test.ts`
    Then the test fails with "T5.1 smoke: archetype 'event-driven-eu' lacks a fixture"
    And the PR is blocked until the fixture lands
```

---

## Constitution Compliance Verification

| Article            | Compliance                                                                                                                |
|--------------------|---------------------------------------------------------------------------------------------------------------------------|
| **I — TDD**        | Phase 1 of `tasks.md` writes harness with ≥ 16 L1 stubs RED ; Phase 2-5 ship one layer per phase GREEN ; Phase 6 docs.    |
| **II — BDD**       | Five Gherkin scenarios above ; user-facing flows (maintainer publish, contributor PR) covered.                            |
| **III — Specs**    | This file precedes any test or smoke-script authoring.                                                                    |
| **III.4 — Anti-hallucination** | Five Q-001..Q-005 in `open-questions.md` ; resolved by ADR-T51-001..005 in `design.md` ; no `[NEEDS CLARIFICATION:]` inline. |
| **V — Audit**      | Every artefact (test files, harness, smoke script, fixtures, edited templates) carries `Audit: T5.1 (cli-trust-harness)`. |
| **IX — Observability** | Harness emits PASS/FAIL counters ; smoke script captures tarball + tmpdir paths on failure.                           |
| **XII — Governance** | Release Process documented in GOVERNANCE.md gains the new gate + override semantics.                                    |

---

## Open Questions reference

See `open-questions.md` for Q-001..Q-005 raised during proposal ;
all resolved by ADR-T51-001..005 in `design.md`.
