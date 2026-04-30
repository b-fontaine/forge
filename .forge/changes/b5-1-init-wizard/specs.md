# Specs: b5-1-init-wizard

<!-- Audit: Module B.5.1 — `/forge:init` wizard with archetype auto-detection. -->
<!-- Depends on: b1-scaffolder + b1-delivery + c1-reference-project           -->
<!--             + a7-forge-upgrade (all archived).                           -->
<!-- Format: ADDED-only delta on the new FR-IW-* namespace.                   -->

This change introduces a new `FR-IW-*` namespace governing the
`forge init` dispatcher / wizard / auto-detection capability. At
archive time the namespace consolidates into a new spec file
`.forge/specs/init-wizard.md` (per the convention used for
`forge-ci.md`, `example-reference.md`, `upgrade.md`).

The 3 open questions from the proposal are **resolved at spec
time per user validation 2026-04-30** :

- **Q1 — wrapper or direct dispatch** : per-archetype wrapper
  scripts under `bin/forge-init-<archetype>.sh` following a stable
  ABI (`--target <dir> --project-name <slug> --reverse-domain <fqdn>`).
  Decouples the CLI's argv shape from each scaffolder's legacy
  flags.
- **Q2 — wizard library** : Node's `readline` (zero new
  dependency). Aligns with the framework's minimal third-party
  stance.
- **Q3 — auto-detection ambiguity** : strict — abort with
  `[NEEDS DECISION: ...]` per Article III.4. No silent fallback.

---

## ADDED Requirements

### FR-IW-001: `forge init` dispatcher

- **MUST** — `cli/src/commands/init.ts` is refactored into a
  pure dispatcher. Routes argv to one of four code paths :
  - `--archetype <name>` → archetype dispatcher
    (FR-IW-002 / FR-IW-003 / FR-IW-004).
  - `--auto` → auto-detection (FR-IW-005), then archetype
    dispatcher.
  - `--wizard` (or no flags + TTY stdin) → interactive wizard
    (FR-IW-006), then archetype dispatcher.
  - No flags + non-TTY stdin → default-schema scaffold + a
    deprecation-style notice on stderr suggesting `--archetype`.
- **MUST** — supported flags : `--archetype <name>` (closed list
  : `default` | `full-stack-monorepo` ; future archetypes
  register here), `--auto`, `--wizard`, `--target <dir>`
  (default cwd), `--source <dir>` (default = bundled assets),
  `--org <reverse-domain>`, `--force`, plus the existing
  positional `[project-name]`.
- **MUST** — flag validation : `--archetype` value MUST appear
  in the dispatch table (FR-IW-002) ; unknown value → exit 2
  with available list. `--archetype` AND `--auto` together →
  exit 2 (mutually exclusive). `--archetype` AND `--wizard`
  together → exit 2.
- **MUST** — exit codes follow the existing `forge init`
  convention : `0` success, `1` runtime error, `2` argument
  error.

**Constitution reference:** Articles V (gates), X (CLI
ergonomics). **Testable:** yes — Vitest unit tests in
`cli/test/commands/init.test.ts` (extended) +
`test_init_cli_flags_parse` in `b5.test.sh`.

### FR-IW-002: Dispatch table `dispatch-table.yml`

- **MUST** — `.forge/scaffolding/dispatch-table.yml` exists with
  one top-level key `archetypes:` that maps each archetype name
  to a record :
    - `name` : string, MUST equal the map key.
    - `scaffolder` : string, the script path relative to the
      framework root (e.g. `bin/forge-init-fsm.sh`). For the
      built-in `default` archetype, the value is the literal
      `"<built-in>"` and the dispatcher invokes its TS path
      directly.
    - `description` : human-readable one-line summary.
    - `signals` : list of relative paths (or globs) that, if
      present in the target dir, suggest this archetype during
      auto-detection (FR-IW-005). Empty list for `default`.
    - `since` : SemVer string of the framework version that
      first registered the archetype (e.g. `"1.0.0"` for
      `full-stack-monorepo`).
- **MUST** — at archive time of `b5-1-init-wizard`, the
  dispatch table contains exactly two entries :
  `default` and `full-stack-monorepo`.
- **MUST** — the file parses as YAML via `yaml.safe_load`. An
  L1 audit test asserts shape + every `scaffolder:` script path
  exists (or equals `"<built-in>"`).

**Constitution reference:** Article V (deterministic gate).
**Testable:** yes — `test_dispatch_table_shape` +
`test_dispatch_scaffolders_exist` in `b5.test.sh`.

### FR-IW-003: `default` archetype path preserves current behavior

- **MUST** — when `--archetype default` is selected, the
  dispatcher invokes the existing file-copy scaffolder logic
  (extracted from `cli/src/commands/init.ts` to a new module
  `cli/src/commands/init-default.ts`). The behavior is
  byte-identical to the pre-b5.1 `forge init` (no `--archetype`
  flag) modulo the new structured exit-code path.
- **MUST** — when invoked with no flags AND non-TTY stdin, the
  dispatcher silently chooses `default` archetype to preserve
  CI behavior. A `forge init` invocation in a CI script that
  worked pre-b5.1 keeps working post-b5.1 (NFR-IW-004).
- **SHALL** — when invoked with no flags AND TTY stdin, the
  dispatcher enters wizard mode (FR-IW-006) instead of
  defaulting silently.

**Constitution reference:** Articles V, X. **Testable:** yes —
extended Vitest tests on `init-default.test.ts` + L2 fixture
in `b5.test.sh`.

### FR-IW-004: `full-stack-monorepo` archetype wrapper

- **MUST** — a new shell wrapper `bin/forge-init-fsm.sh` exists,
  executable. Stable ABI :
  `forge-init-fsm.sh --target <dir> --project-name <slug>
  --reverse-domain <fqdn> [--force]`. Decouples the CLI's argv
  shape from `.forge/scripts/scaffolder/init.sh`'s legacy
  argument convention (positional + `--org`).
- **MUST** — the wrapper translates the CLI ABI into the
  `init.sh` ABI (positional `<project-name>` first, then
  `--org <reverse-domain>` + `--target-dir <dir>`) and shells
  out via `bash`. It propagates `init.sh`'s exit code unchanged.
- **MUST** — the wrapper passes `shellcheck` (already wired into
  `forge-ci.yml` `lint` job).
- **SHALL** — every recursive walk uses the
  `find_excluding_examples` pattern established by FR-GL-027.

**Constitution reference:** Articles V, VII (shell discipline by
analogy), X. **Testable:** yes —
`test_forge_init_fsm_sh_exists_executable` +
`test_forge_init_fsm_sh_translates_abi` (L2 fixture).

### FR-IW-005: Auto-detection heuristic

- **MUST** — `cli/src/domain/archetype-detect.ts` exposes a pure
  function
  `detectArchetype(signalsByPath: Record<string, boolean>): DetectionResult`
  where `DetectionResult` is one of :
  - `{ kind: "match", archetype: string }`
  - `{ kind: "ambiguous", candidates: string[] }`
  - `{ kind: "none" }`
- **MUST** — at archive time, the heuristic encodes :
  - `pubspec.yaml` AND `Cargo.toml` → `match
    full-stack-monorepo`.
  - `pubspec.yaml` only → `ambiguous` with empty candidates
    (today : no Flutter-only archetype shipped → caller
    surfaces `[NEEDS DECISION:]`).
  - `Cargo.toml` only → same shape (today : no Rust-only
    archetype shipped).
  - Empty signals → `none` ; caller defaults to `default`
    archetype.
- **MUST** — the calling dispatcher converts an `ambiguous` /
  `none-with-signals` result into a clear error message
  citing the present signals + the missing archetype name(s)
  + a suggested `--archetype default` workaround.
- **MUST** — the function takes its input as a plain object
  (no I/O) ; the I/O wrapper that probes the file system lives
  in `init-archetype.ts`. This split keeps the heuristic
  unit-testable without tmpdir setup.

**Constitution reference:** Articles III.4 (anti-hallucination),
V. **Testable:** yes — Vitest unit tests for every heuristic
case + `test_auto_detection_ambiguous_aborts` in `b5.test.sh`.

### FR-IW-006: Interactive wizard via Node's `readline`

- **MUST** — `cli/src/commands/init-wizard.ts` exposes the
  `runWizard(deps): Promise<WizardResult>` function. `deps`
  injects an input stream (default `process.stdin`), output
  stream (default `process.stdout`), and a runner that delegates
  to the archetype dispatcher.
- **MUST** — the wizard sequentially prompts :
  1. **Archetype** — numbered closed-list menu, options drawn
     from the dispatch table (today : `1) default`,
     `2) full-stack-monorepo`). Empty input → exit 2 with an
     informative message ; out-of-range or non-numeric → re-prompt
     up to 3 times then exit 2.
  2. **Project name** — kebab-case slug
     (regex `^[a-z][a-z0-9-]{1,49}$`). Re-prompt up to 3 times
     on invalid input.
  3. **Reverse domain** — required iff the chosen archetype's
     `signals` list is non-empty (today : `full-stack-monorepo`
     requires it ; `default` does not). Regex
     `^[a-z][a-z0-9.-]+$`.
- **MUST** — when stdin is **not a TTY**, the wizard MUST NOT
  start ; the dispatcher routes to the non-interactive code
  path (FR-IW-003 silent default).
- **MUST** — the wizard uses Node's standard `readline` module
  exclusively. NO new third-party dependency
  (`prompts`/`inquirer` etc. are forbidden — NFR-IW-002).
- **SHALL** — the wizard prints a one-line confirmation summary
  before invoking the archetype dispatcher
  (e.g. `"forge init: archetype=full-stack-monorepo, project=my-app, org=io.acme.myapp"`).

**Constitution reference:** Articles V, X. **Testable:** yes —
Vitest tests with scripted stdin streams + `test_wizard_skips_when_non_tty`.

### FR-IW-007: `--org` reverse-domain validation

- **MUST** — when an archetype declares non-empty `signals` in
  the dispatch table (today : `full-stack-monorepo`), the
  dispatcher REQUIRES `--org <reverse-domain>` (or the wizard's
  prompt). Missing → exit 2 with an explicit message.
- **MUST** — reverse-domain validation regex :
  `^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$` (must contain at least
  one dot separator). Invalid → exit 3.
- **SHALL** — the validator is a pure function in
  `cli/src/domain/reverse-domain.ts` for testability.

**Constitution reference:** Article V. **Testable:** yes — Vitest
unit tests + `test_reverse_domain_regex` in `b5.test.sh`.

### FR-IW-008: Standard `global/scaffolding.md`

- **MUST** — file `.forge/standards/global/scaffolding.md`
  exists and contains 6 canonical H2 sections :
  `## Dispatch table contract`, `## Per-archetype scaffolder ABI`,
  `## Auto-detection heuristic`, `## Interactive wizard mode`,
  `## Adding a new archetype`, `## Interdictions`.
- **MUST** — `## Interdictions` lists 3 forbidden patterns :
  (1) hard-coding archetype names in CLI command files outside
  the dispatch table, (2) per-archetype scaffolders reading the
  dispatch table directly (only the dispatcher does), (3)
  bypassing the wizard via direct invocation of `init-default.ts`
  / `init-archetype.ts` from external tools.
- **MUST** — cites Articles III.4, V, X.

**Constitution reference:** Articles III.4, V, X. **Testable:**
yes — `test_standard_scaffolding_has_required_sections`.

### FR-IW-009: `docs/ARCHETYPES.md` decision matrix

- **MUST** — `docs/ARCHETYPES.md` exists with the H1 title
  `# Forge Archetypes — Decision Matrix` and an H2 section
  `## Available archetypes` containing a markdown table with
  columns : `Archetype` | `Status` | `Persona` | `When to pick`
  | `Stack` | `Since` | `Spec`.
- **MUST** — at archive time of `b5-1-init-wizard`, the table
  contains five rows :
  - `default` — Active — generic projects — minimal Forge
    install, any stack — 0.1.0 — `default/schema.yaml`.
  - `full-stack-monorepo` — Active — Flutter+Rust full-stack
    teams — multi-layer monorepo with protos as SoT — 1.0.0 —
    `full-stack-monorepo.md`.
  - `flutter-firebase` — Planned (B.2) — consumer apps with
    BaaS — Flutter + Firebase Auth/Firestore — TBD — TBD.
  - `mobile-only` — Planned (B.4) — Flutter iOS+Android with
    own backend — Flutter + OIDC via flutter_appauth — TBD —
    TBD.
  - `rust-cli-tui` — Planned (B.3) — dev tools — Rust CLI/TUI
    with cargo-dist — TBD — TBD.
- **SHALL** — a `## How `forge init` chooses` H2 section
  briefly documents the auto-detection heuristic +
  `--archetype` / `--auto` / `--wizard` selection modes.

**Constitution reference:** Article X.3 (public docs).
**Testable:** yes — `test_archetypes_decision_matrix_present` in
`b5.test.sh`.

### FR-IW-010: Standards index entry

- **MUST** — `.forge/standards/index.yml` contains a new entry :
  `id: global/scaffolding`, `path:
  standards/global/scaffolding.md`, `scope: all`, `priority:
  high`, triggers including `init`, `forge init`, `wizard`,
  `archetype`, `dispatch-table`, `--auto`, `--wizard`.

**Constitution reference:** Article V (JIT loading).
**Testable:** yes — `test_index_has_scaffolding_entry`.

### FR-IW-011: Test harness `b5.test.sh`

- **MUST** — `.forge/scripts/tests/b5.test.sh` exists,
  executable, sources `_helpers.sh`. Manifest pattern with
  `test_b5_manifest_self_consistency` meta-check.
- **MUST** — three levels :
  - **L1 (hermetic)** — structural / static checks :
    dispatch-table shape, every scaffolder path resolves,
    standard sections, index entry, decision matrix, feature
    file shape, CLI flag parsing via static text-grep on
    `init.ts`.
  - **L2 (fixture-based)** — auto-detection heuristic (3
    fixtures : full-stack signals, ambiguous, no signals),
    wrapper ABI translation (`forge-init-fsm.sh` translates and
    delegates), wizard scripted stdin (3 happy-path + 2
    re-prompt scenarios), reverse-domain regex.
  - **L3 (opt-in via `--require-external-tools`)** — full
    end-to-end : `forge init --archetype full-stack-monorepo
    foo --org io.test.foo --target <tmp>` actually scaffolds a
    valid full-stack-monorepo tree (requires `flutter`,
    `cargo`, `buf` on PATH). L3 reuses the b1-scaffolder L3
    discipline.
- **MUST** — invoked from `forge-ci.yml` `harness` job (L1
  only) alongside the existing 7 harnesses.

**Constitution reference:** Article I. **Testable:**
self-testing.

### FR-IW-012: Spec consolidation at `init-wizard.md`

- **MUST** — at archive time, `.forge/specs/init-wizard.md`
  exists as the new consolidated spec for the `FR-IW-*`
  namespace (consistent with `forge-ci.md`, `example-reference.md`,
  `upgrade.md` conventions).
- **MUST** — links back to `b5-1-init-wizard` in the Archived
  changes table.

**Constitution reference:** Articles III.2, IV. **Testable:** yes
— `test_init_wizard_spec_present_post_archive` (gated).

---

## MODIFIED Requirements

### FR-GL-011: `/forge:init --archetype full-stack-monorepo` slash command branch

<!-- MODIFIED by b5-1-init-wizard (2026-04-30) — the npm CLI's `forge init` becomes the canonical entry point ; direct invocation of `init.sh` is now a low-level escape hatch. -->

**Previously (b1-scaffolder):**
> the slash command delegates to `.forge/scripts/scaffolder/init.sh`
> which executes a non-negotiable 7-step sequence [...]

**Now:** *(7-step sequence unchanged, ABI preserved)* The CLI's
`forge init` is the **canonical user-facing entry point**.
Adopters invoke `forge init --archetype full-stack-monorepo
<project-name> --org <reverse-domain>`. The dispatcher
(FR-IW-001) translates this into `init.sh`'s legacy ABI via
the `bin/forge-init-fsm.sh` wrapper (FR-IW-004). Direct
invocation of `bash .forge/scripts/scaffolder/init.sh ...`
remains supported (Forge maintainers + advanced users), but
documentation favours the CLI flow.

**Constitution reference:** Articles V, X. **Testable:** yes —
extended scaffolder L3 fixture + new wrapper L2 fixture.

---

## REMOVED Requirements

*(none — purely additive on FR-IW-* + 1 MODIFIED on FR-GL-011.)*

---

## Non-Functional Requirements

### NFR-IW-001: Dispatcher idempotence

- **MUST** — running `forge init --archetype default --target
  <dir>` twice on the same target dir with the same flags
  produces the same outcome each time (existing
  `init-default` behavior preserves the `--force` semantics).
  L2 fixture exercises.

### NFR-IW-002: Zero new third-party dependencies

- **MUST** — the wizard uses Node's standard library
  exclusively (`readline`, `process.stdin`, etc.). No new
  entries in `cli/package.json`'s `dependencies` or
  `devDependencies` (Vitest stays unchanged). Aligns with the
  framework's minimal third-party stance.

### NFR-IW-003: Wizard auto-skip when stdin is non-TTY

- **MUST** — when `process.stdin.isTTY` is `false` AND no flags
  are passed, the dispatcher routes to the silent `default`
  scaffold path (FR-IW-003) rather than starting the wizard.
  Preserves CI scripts that run `forge init` non-interactively.

### NFR-IW-004: Backwards compatibility on existing `forge init` flow

- **MUST** — existing CI scripts invoking `forge init` (with no
  archetype flag, in a non-TTY environment) MUST produce the
  same output and exit code as pre-b5.1. The new dispatcher's
  silent-default path is byte-equivalent to the legacy
  file-copy. Exercised by an extended Vitest e2e test in
  `cli/test/e2e/cli.test.ts`.

### NFR-IW-005: Audit-ID traceability

- **MUST** — every file created or modified by this change
  carries an `<!-- Audit: B.5.1 (part of b5-1-init-wizard) -->`
  comment in its first five lines (or YAML / shell equivalent).

### NFR-IW-006: Wizard time budget

- **SHOULD** — the wizard's total prompt → dispatch handoff
  time is ≤ 200 ms exclusive of user typing time. (Effective
  ceiling — Node's `readline` overhead is dominated by the
  user's typing speed.)

---

## Acceptance Criteria (BDD)

### AC-IW-001: Explicit archetype dispatch

```gherkin
Feature: Forge init — explicit archetype
  As an adopter scaffolding a new project
  I want to pick the archetype via --archetype
  So that I bypass the wizard for scripted use

  Scenario: --archetype full-stack-monorepo + --org dispatches the wrapper
    Given a clean target directory at <tmp>
    When the adopter runs "forge init --archetype full-stack-monorepo my-app --org io.acme.myapp --target <tmp>"
    Then bin/forge-init-fsm.sh is invoked with --target <tmp> --project-name my-app --reverse-domain io.acme.myapp
    And the command exits with the wrapper's exit code
    And no wizard prompt is printed to stdout
```

### AC-IW-002: Auto-detection of full-stack-monorepo

```gherkin
Feature: Forge init — auto-detection
  Scenario: pubspec.yaml + Cargo.toml co-presence selects full-stack-monorepo
    Given a target directory containing both pubspec.yaml and Cargo.toml
    When the adopter runs "forge init --auto --target <dir>"
    Then the dispatcher resolves the archetype to "full-stack-monorepo"
    And the dispatcher prompts for project name + --org if missing (TTY) or aborts with a usage message (non-TTY)
```

### AC-IW-003: Ambiguous auto aborts with NEEDS DECISION

```gherkin
Feature: Forge init — auto-detection ambiguity
  Scenario: pubspec.yaml only triggers a strict abort
    Given a target directory containing pubspec.yaml but not Cargo.toml
    When the adopter runs "forge init --auto --target <dir>"
    Then the command exits 2
    And the output contains "[NEEDS DECISION:" and the available archetypes
    And the output suggests "--archetype default" as the workaround
```

### AC-IW-004: Wizard prompts and writes

```gherkin
Feature: Forge init — interactive wizard
  Scenario: User selects full-stack-monorepo via the wizard
    Given an interactive terminal session
    And no init flags are passed
    When the adopter runs "forge init"
    Then the wizard prints a numbered archetype menu
    And accepts user input "2" for full-stack-monorepo
    And prompts for "Project name" and "Reverse domain"
    And prints a one-line confirmation summary
    And invokes the same dispatcher path as --archetype full-stack-monorepo
```

### AC-IW-005: Non-TTY without flags falls back to default

```gherkin
Feature: Forge init — non-TTY backwards compat
  Scenario: CI script invocation without flags
    Given a non-interactive environment (no TTY on stdin)
    And no --archetype flag is passed
    When the adopter runs "forge init --target <tmp>"
    Then the dispatcher silently selects the "default" archetype
    And the file-copy scaffold runs (byte-equivalent to pre-b5.1 behavior)
    And the command exits 0
```

---

## Constitution compliance summary

| Article | Compliance |
|---|---|
| I — TDD | New harness `b5.test.sh` follows manifest pattern. CLI subcommand ships with Vitest unit tests. RED→GREEN order across 3 implementation phases. |
| II — BDD | `features/init-wizard.feature` ships ≥ 5 scenarios covering AC-IW-001..005. |
| III — Specs Before Code | This spec is the gate before design and tasks. |
| III.4 — Anti-Hallucination | Auto-detection ambiguity aborts with `[NEEDS DECISION:]` (FR-IW-005) — no guess. |
| IV — Delta-Based Change Management | All modifications in delta format. Dispatch table is purely additive. |
| V — Conformance Gate | The dispatcher itself is a gate ; invalid `--archetype` aborts. |
| VI / VII / VIII / IX / XI | Out of scope — `forge init` is a framework-internal CLI command. |
| X — Quality | TS passes ESLint + Vitest. Shell wrapper passes shellcheck. Standard passes pymarkdown. NFR-IW-002 forbids new third-party deps. |

✅ **No constitutional violation. Proceeding to /forge:design.**
