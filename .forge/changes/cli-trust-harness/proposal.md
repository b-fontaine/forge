# Proposal: cli-trust-harness
<!-- Created: 2026-05-14 -->
<!-- Schema: default -->
<!-- Audit: T5.1 (docs/new-archetypes-plan.md §0.1) -->

## Problem

Between **2026-05-02 (v0.3.0)** and **2026-05-13 (v0.3.2)** the maintainer
shipped **three patch releases in 11 days** of `@sdd-forge/cli`, two of which
(`v0.3.1`, `v0.3.2`) were emergency fix-forwards triggered by regressions
exercised only by the **published binary** against a **fresh-machine
install** — not by source-tree unit tests. The same gap caused the
maintainer's public GitHub Discussions post announcing v0.3.0 to omit
`--org` and `--eu-tier` from the documented `forge init` invocation form,
because no copyable ABI source-of-truth exists outside `cli/src/commands/init.ts`.

Concretely, **three first-experience defects** surfaced in production
within 24 hours of the v0.3.1 publication, ratifying that the existing
test surface (`cli/test/e2e/cli.test.ts`) is insufficient :

1. **`--eu-tier <T1|T2|T3>` flag was declared but not wired**
   (`cli/src/commands/init.ts` had `EU_TIER_ENUM` + validator + env-var
   propagation since `j8-janus-rules` 2026-05-10 ; `cli/src/cli.ts` never
   called `.option("--eu-tier <tier>", ...)`). Users hit
   `error: unknown option '--eu-tier'` on v0.3.0 / v0.3.1.
2. **`forge init --target <new-dir>` failed with `spawn bash ENOENT`**
   when `--target` pointed to a path that did not yet exist. The bash
   scaffolder does `mkdir -p` internally but **after** `spawn`, which
   itself fails when `cwd` is missing.
3. **`forge init` required `--force` even in an empty target dir** —
   `.forge/scripts/scaffolder/init.sh:168` refused to scaffold when the
   target dir merely existed, regardless of contents. The natural
   `mkdir foo && cd foo && forge init …` hit the collision guard.

In parallel, a **fourth defect** discovered while debugging the user's
own scaffolded project — present **since B.1 archived 2026-04-21** but
invisible to every existing test — proves the same root cause :

4. **`task dev:up` exits with `invalid keys in command` on every
   freshly-scaffolded full-stack-monorepo project** because
   `.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl:67`
   contains `- echo "infra tests: delegated to b1-delivery workflows"`.
   In a plain YAML scalar, `: ` (colon + space) is a key/value separator ;
   go-task parses the line as the mapping
   `{"echo \"infra tests": "delegated to b1-delivery workflows\""}`
   instead of as a string command. The template has been broken **for
   23 days** and no test caught it because no test runs `task --list-all`
   on a scaffolded project.

**Root cause (shared by all four defects)** : the CLI test pipeline
validates artefacts that are trivial to assert (file presence, exit
codes) but never validates that the **rendered scaffold is functionally
exercisable**. Specifically :

- No test invokes the **published binary** against a clean fresh-machine
  layout (only `dist/index.js` from source).
- No test runs `forge init` against a **non-existent** `--target` (only
  pre-created tmpdirs).
- No test runs **`task --list-all`** (or any downstream tool) on the
  scaffolded project.
- No test asserts that **every flag declared in `init.ts`** is also wired
  into commander in `cli.ts`.
- No test asserts that **every archetype** in `dispatch-table.yml` is
  exercisable from a clean state (only `default`).

The result is a release pattern that **leaks regressions to adopters**
within hours of each push, eroding the trust the framework is supposed
to build. This change ships the structural fix : a four-layer harness
that walls off `npm publish` from any tarball that cannot be
demonstrably scaffolded against a fresh machine.

## Solution

A new tiered test harness `t5-1.test.sh` plus four code layers, ordered
by dependency and defensive value. Layer **D** (upgrade matrix) is
deferred to **B.8.15** in T6 per `docs/new-archetypes-plan.md` §0.1 +
§4.2 — its critical value materialises only once the `2.0.0` snapshot
tarball exists. Total effort `M`. Release criterion **v0.3.3** :
all four in-scope layers GREEN in CI + harness registered in
`forge-ci.yml`.

### T5.1.0 — Fix `Taskfile.yml.tmpl` + template sweep

**Surgical bug fix that the harness will then guarantee against
recurrence.** Sweep every `*.tmpl` / template file under
`.forge/templates/`, `examples/`, and `cli/assets/` for the pattern
`echo "[^"]*: [^"]*"` (and equivalent variants) in YAML `cmds:` lists.
Single-quote each match so the entire shell command is a quoted scalar
that go-task and any compliant YAML 1.2 parser will accept as a string.

Example fix at line 67 of
`.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl` :

```diff
-      - echo "infra tests: delegated to b1-delivery workflows"
+      - 'echo "infra tests: delegated to b1-delivery workflows"'
```

The constitution-linter gains **no new rule** for this — Layer T5.1.B
(smoke per archetype, below) makes the class extinct by executing
`task --list-all` against the scaffolded project on every CI run, which
will fail loudly if any future template re-introduces an unquoted
`: ` in a `cmds:` list.

### T5.1.A — Golden snapshot of CLI flags

A new test file `cli/test/e2e/help-snapshots.test.ts` captures the
output of :

- `forge --help`
- `forge init --help`
- `forge upgrade --help`
- `forge verify --help`
- `forge version --help`

into golden snapshot files at `cli/test/e2e/__snapshots__/help/`. Any
drift in the CLI surface fails the test until the snapshot is updated
**deliberately** (committing the new snapshot in the same PR as the
surface change).

A second assertion cross-references the snapshots against
`.forge/scaffolding/dispatch-table.yml::archetypes` : every entry whose
`status:` is **not** `removed_from_roadmap` must appear by name in
`forge init --help`'s output (description or example section). This
catches the class of bug where a new archetype is added to the
dispatch table but its `--archetype` flag value is never advertised in
help.

Outcome : the `--eu-tier` regression of v0.3.0 would have been blocked
at PR review because the snapshot would have shown the missing flag.
The maintainer's GitHub Discussions post would have a verbatim,
authoritative `forge init --help` to copy from.

### T5.1.B — Smoke test per archetype

A new test file `cli/test/e2e/archetypes-smoke.test.ts` iterates over
`dispatch-table.yml::archetypes`, skipping :

- `default` (already covered by the existing e2e test)
- entries with `status: removed_from_roadmap` (e.g. `flutter-firebase`)

For each remaining archetype, the test :

1. Creates a tmpdir path **without** pre-creating it (`mkdtemp` returns
   the path ; the test then deletes it before invocation) so the
   `forge init` command exercises the `mkdir -p` fix from v0.3.2.
2. Invokes `forge init <slug> --archetype <name> --org dev.forge.test
   --target <tmp>` and asserts exit 0.
3. Asserts a **declarative file matrix** loaded from
   `cli/test/e2e/archetype-fixtures/<archetype-name>.yml` — list of
   paths that MUST exist post-scaffold + list of paths that MUST NOT
   exist (e.g. `cli/` itself MUST never leak into the target, per
   the existing `expect(existsSync(join(target, "cli"))).toBe(false)`
   pattern in `cli/test/e2e/cli.test.ts`).
4. Runs `task --list-all` in the scaffolded tmpdir and asserts exit 0
   (validates the rendered `Taskfile.yml` parses + every task is
   well-formed). **Skip-pass when `task` is absent from PATH** —
   mirrors `t5-otel-app.test.sh::_test_ota_l2_002_flutter_analyze`
   skip-pass for `flutter`.
5. **Opt-in tighter checks** gated by `FORGE_E2E_TOOLCHAINS=1` :
   - `cd backend && cargo check --workspace` for archetypes producing
     a Rust backend (full-stack-monorepo, rust-cli-tui, event-driven-eu,
     ai-native-rag once shipped).
   - `cd frontend && flutter analyze` for archetypes producing a
     Flutter frontend (full-stack-monorepo, mobile-only, mobile-pwa-first
     once shipped).
   - Skip-pass each tool independently when absent from PATH.

The fixture file format is YAML to match Forge convention
(`dispatch-table.yml`, `framework-owned-paths.yml`, `.forge.yaml`).

Outcome : all four defects this change addresses (the three v0.3.2
regressions + the 23-day-old Taskfile bug) would have been blocked at
PR review by this layer.

### T5.1.C — Pre-publish tarball gate

A new script `cli/scripts/prepublish-smoke.mjs` performs the full
publish dry-run **on the actual tarball that `npm publish` would
upload** :

1. Runs `npm pack` in `cli/` ; captures the produced
   `sdd-forge-cli-<version>.tgz`.
2. Extracts the tarball into a hermetic tmpdir.
3. Installs the extracted package into an isolated npm prefix
   (`npm install --prefix=<isolated-tmp> --global ./<tarball>`) so
   the `forge` binary resolves from the tarball, not from the source
   `dist/` tree.
4. Re-runs the **T5.1.B smoke test** with the `FORGE_CLI_BIN` env-var
   pointing to the isolated binary, against a fresh second tmpdir.
5. On any failure, prints the captured tarball path so the maintainer
   can inspect it post-mortem, and exits non-zero.

The script is wired into `cli/package.json::prepublishOnly` between
`bundle` and the implicit `npm publish` step :

```diff
   "prepublishOnly": "npm run lint && npm test && npm run bundle"
+  "prepublishOnly": "npm run lint && npm test && npm run bundle && node scripts/prepublish-smoke.mjs"
```

Outcome : the v0.3.0 `--eu-tier` regression and the v0.3.1 `spawn
bash ENOENT` regression would have aborted `npm publish` before the
tarball reached the registry. Maintainer never sees a bad release
escape.

### T5.1.D — Deferred to B.8.15

`forge upgrade` matrix test (N-1 → N for every active archetype +
re-runs of T5.1.B on the upgraded tree + negative path
`[NEEDS MIGRATION:]`). Deferred to **B.8.15** in T6 per
`docs/new-archetypes-plan.md` §0.1 — its critical value is the
`1.0.0 → 2.0.0` flagship migration covered by B.8, which depends on
the `2.0.0` snapshot tarball B.8.2 ships. Intra-1.x.x pair coverage
(currently only one pair would exist : `1.0.0 → 1.0.0`) provides
insufficient value to justify the work in this change.

### Harness `t5-1.test.sh`

A new shell harness `.forge/scripts/tests/t5-1.test.sh` ships ≥ 16 L1
hermetic grep-based tests (presence of each layer's deliverables,
`prepublishOnly` wiring, audit comment in each artefact, dispatch-table
cross-reference correctness in T5.1.A) + 2 L2 fixture-based tests
(opt-in `FORGE_T51_LIVE=1` exercising T5.1.B end-to-end on a single
archetype, opt-in `FORGE_T51_PACK=1` exercising T5.1.C with a real
`npm pack`). Both L2 tests skip-pass when their env-var is absent
(mirrors `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1` and
`i5-compliance-workflow::FORGE_I5_ACT=1`).

Registered in `.github/workflows/forge-ci.yml` matrix after
`f3.test.sh` with `--level 1`. `forge-ci.yml` stays under the
NFR-CI-002 300-line budget.

### CHANGELOG + roadmap + plan updates

- `CHANGELOG.md [Unreleased]` gets a `### Added — cli-trust-harness
  (T5.1)` entry detailing the four layers + the Taskfile fix.
- `.forge/product/roadmap.md` flips the "Planned T5.1" row to
  "Done 2026-05-XX via `cli-trust-harness`" with the same shape as
  the `f3-release-script-fix` Done row.
- `docs/new-archetypes-plan.md` flips the T5.1 entry in §1.4 + §11
  from "Planned" to "Done", and appends the change to the
  `Inventaire .forge/changes/` table.

## Scope In

- **Taskfile sweep** : single-quote every `cmds:` entry containing
  `: ` in `.forge/templates/**/*.tmpl` + `examples/**/Taskfile.yml`
  + `cli/assets/**/Taskfile.yml*`.
- **`cli/test/e2e/help-snapshots.test.ts`** + golden snapshot files
  under `cli/test/e2e/__snapshots__/help/`.
- **`cli/test/e2e/archetypes-smoke.test.ts`** + YAML fixtures under
  `cli/test/e2e/archetype-fixtures/<name>.yml` (one per active
  non-default archetype : `full-stack-monorepo`, `mobile-only`).
- **`cli/scripts/prepublish-smoke.mjs`** + wiring into
  `cli/package.json::prepublishOnly`.
- **`.forge/scripts/tests/t5-1.test.sh`** harness ≥ 16 L1 + 2 L2
  opt-in.
- Registration of `t5-1.test.sh` in `.github/workflows/forge-ci.yml`.
- CHANGELOG `[Unreleased]` entry.
- Roadmap + plan flips Planned → Done for T5.1 + inventory row.

## Scope Out (Explicit Exclusions)

- **Layer D — `forge upgrade` matrix test.** Deferred to **B.8.15**
  in T6 per `docs/new-archetypes-plan.md` §0.1 + §4.2. The intra-1.x.x
  pair coverage that would land in this change today provides
  insufficient value (only one pair would exist) to justify
  packaging the orchestration in advance of B.8.
- **Toolchain installation by the harness.** `task`, `flutter`,
  `cargo` are NEVER installed by the harness ; each is skip-pass when
  absent. Adopters or CI workflows that want the tighter checks
  opt-in via `FORGE_E2E_TOOLCHAINS=1` and arrange the toolchains
  themselves (mirrors NFR-J7-001 / NFR-K3-DEM-004 zero-new-external-dep
  precedent).
- **New CLI flags or behaviors.** This change is pure test harness +
  one template-bug fix. No new `--option`, no new subcommand.
- **New Forge standard YAML.** T5.1 is plomberie outillage, not an
  architectural decision. No `.forge/standards/*.yaml` is born.
- **New Forge agent.** No K.x slot consumed.
- **Constitution amendment.** Articles I (TDD), III (specs before
  code), V (audit), IX (observability), XII (governance) are
  consumed but unchanged.
- **Replacing the existing `cli/test/e2e/cli.test.ts`.** That file
  stays — T5.1.B adds new tests, it does not refactor the
  default-archetype coverage already in place.
- **Release v0.3.3 publication.** This change archives the harness ;
  the maintainer tags v0.3.3 in a separate step using the
  `scripts/release.sh` helper shipped by `f3-release-script-fix`.
- **`mobile-pwa-first` / `event-driven-eu` / `ai-native-rag` /
  `rust-cli-tui` archetypes.** Not yet shipped (T7 / T8). Their
  fixture YAML files will be added when each archetype lands —
  this change ships fixtures only for the two currently active
  archetypes (`full-stack-monorepo`, `mobile-only`).

## Impact

- **Users affected** :
  - **Forge maintainer** : `prepublishOnly` now runs the smoke
    against a packed tarball before allowing `npm publish`. Adds
    ~30 s to the publish path. Fails loudly if any of the four
    layers regress.
  - **Forge contributors** : new e2e tests run on every PR (vitest
    + the new harness). Adds ~20 s to CI when `task` is on PATH,
    ~5 s when skip-pass. Adds ~10 lines of dispatch-table-vs-help
    cross-check.
  - **Forge adopters** : the v0.3.3 tarball will scaffold cleanly
    against an empty dir, against a non-existent dir, and the
    rendered project's `task --list-all` will exit 0 — three
    regressions the past three releases each introduced or failed
    to catch. No new flag, no migration.
- **Technical impact** : ~5 new files (test + harness + smoke script
  + 2 fixtures), ~2 modified templates (Taskfile.yml.tmpl + any
  sibling caught by the sweep), ~2 modified package files
  (`cli/package.json` script wiring + `.github/workflows/forge-ci.yml`
  matrix entry). Total ~600-800 LOC, mostly fixture + test code.
  No new external dependency.
- **Dependencies** : depends on `go-task` (v3+) being installable
  on developer machines (already a Forge prerequisite — documented
  in flagship README). depends on `npm pack` / `npm install
  --prefix` semantics (stable since npm 6).
- **Risk level** : **Low**. The change is purely additive on the
  test/CI side. The Taskfile fix is a 1-line single-quote diff
  with byte-identical runtime semantics (the shell command echoes
  the same string ; only the YAML escaping changes). The Layer C
  pre-publish gate is opt-out by design (`FORGE_SKIP_PREPUBLISH=1`)
  in case the maintainer needs an emergency override — but the
  default path enforces it.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`t5-1.test.sh` with **≥ 16 L1 stubs all returning `_not_implemented`**
(full RED witness). Phase 2 ships Layer T5.1.0 (Taskfile fix) — the
**simplest** fix, no test churn. Phase 3 ships Layer T5.1.A (golden
snapshots) + its harness GREEN. Phase 4 ships Layer T5.1.B + fixtures
+ its harness GREEN. Phase 5 ships Layer T5.1.C + prepublish wiring +
its harness GREEN. Phase 6 ships doc / changelog / roadmap / plan
updates + final gates.

### Article II — BDD

The maintainer-facing flow (`bash scripts/release.sh --version 0.3.3
…` invokes `prepublishOnly` which runs the smoke harness, which
either GREEN-lights or aborts publication) gets a Gherkin scenario
in `specs.md`. The fixture-matrix flow (a new archetype lands, its
`*.yml` fixture lands with it, T5.1.B picks it up automatically)
also gets a scenario. The internal step-list flow does not.

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-T51-*` +
`NFR-T51-*` namespace before any test or smoke-script authoring.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Five open questions raised at this phase, all expected to resolve
during `/forge:design` :

- **Q-001** — Toolchain availability handling : skip-pass-via-env-var
  vs hard requirement vs adaptive (auto-detect on PATH) ?
- **Q-002** — Archetype fixture format : YAML (Forge convention) vs
  JSON (vitest-native) ?
- **Q-003** — Pre-publish gate isolation mechanism : `npm install
  --prefix=<tmp> --global` vs `npx --no-install <tarball>` vs
  `tar -xz + node <extracted>/dist/index.js` ?
- **Q-004** — Should T5.1.B replace `cli/test/e2e/cli.test.ts`'s
  default-archetype coverage, or augment it ?
- **Q-005** — Emergency override : MUST exist (`FORGE_SKIP_PREPUBLISH=1`)
  or MUST NOT exist (treat every publish as gated, no escape hatch) ?

### Article V — Audit Trail

Each task tagged `[Story: FR-T51-XXX]`. Each new file carries
`# <!-- Audit: T5.1 (cli-trust-harness) -->` (or `//` equivalent
for `.ts` / `.mjs`) in its header comment block. The harness file
carries the same audit comment.

### Article VIII — Infrastructure

The change is purely test / CI / template tooling. No service, no
daemon, no runtime infra. Same posture as `f3-release-script-fix`
and `g1-forge-ci`.

### Article IX — Observability

N/A. The harness emits its own structured output (PASS / FAIL counts,
test names) ; no traces, no metrics. The opt-in `FORGE_T51_PACK=1`
L2 test path captures the produced tarball path in stdout on failure
for post-mortem.

### Article XI — AI-First Design

N/A. The harness is maintainer / CI tooling, not an AI surface.

### Article XII — Governance

The change extends the **Release Process** documented in
GOVERNANCE.md § Release Process (it adds a `prepublishOnly` gate
between `npm run bundle` and `npm publish`). The Release Process
itself remains BDFL-driven (no procedural change). No Article
amended.

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none in this
`proposal.md`. Five open questions Q-001 / Q-002 / Q-003 / Q-004 /
Q-005 raised in `open-questions.md`, all to be resolved by
ADR-T51-001..005 in `design.md`.
