# Spec: init-wizard

<!-- Audit: Module B.5.1 — `/forge:init` wizard with archetype auto-detection. -->
<!-- This file accumulates archived requirements for the                       -->
<!-- `forge init` dispatcher / wizard / auto-detection capability.             -->
<!--                                                                           -->
<!-- Audience here : Forge maintainers + adopters using the CLI for project   -->
<!-- scaffolding. Distinct from full-stack-monorepo.md (archetype contract),  -->
<!-- example-reference.md (reference example tree), upgrade.md (forge         -->
<!-- upgrade), and forge-ci.md (Forge's own CI).                             -->

This spec is the consolidated contract for the **`forge init`
dispatcher** — the single canonical entry point for project
scaffolding. It activates whenever `forge init` is invoked, in
any of its three modes (explicit `--archetype`, `--auto`
detection, interactive `--wizard`).

The full standard governing the discipline is
`.forge/standards/global/scaffolding.md`.

---

## Archived changes

| Change | Date | Phase | FRs added |
|---|---|---|---|
| [`b5-1-init-wizard`](../changes/b5-1-init-wizard/) | 2026-04-30 | Multi-archetype dispatcher + wizard | FR-IW-001..012 + NFR-IW-001..006 ; MODIFIED FR-GL-011 (CLI becomes the canonical entry point) |

---

## Requirements

### FR-IW-001: `forge init` dispatcher

- **MUST** — `cli/src/commands/init.ts` is a pure dispatcher
  routing argv to one of four code paths : `--archetype <name>`,
  `--auto`, `--wizard` (or no flags + TTY stdin), or no flags +
  non-TTY stdin (silent default).
- **MUST** — supported flags : `--archetype <name>`, `--auto`,
  `--wizard`, `--target <dir>`, `--source <dir>`, `--org
  <reverse-domain>`, `--force`, plus the existing positional
  `[project-name]`.
- **MUST** — flag validation : unknown `--archetype` value →
  exit 2. `--archetype` AND `--auto` together → exit 2 (mutually
  exclusive). `--archetype` AND `--wizard` together → exit 2.
- **MUST** — exit codes : `0` success, `1` runtime error, `2`
  argument error, `3` regex / format validation failure.

**Constitution reference:** Articles V, X. **Testable:** yes —
`cli/test/commands/init.test.ts` (7 tests) +
`test_init_cli_flags_parse` in `b5.test.sh`.

### FR-IW-002: Dispatch table `dispatch-table.yml`

- **MUST** — `.forge/scaffolding/dispatch-table.yml` declares
  one top-level key `archetypes:` mapping each archetype name
  to a record with required fields `name`, `scaffolder`
  (`"<built-in>"` or shell-script path) and optional fields
  `description`, `signals`, `since`. Forward-compatible :
  unknown keys are ignored.
- **MUST** — at archive time, the dispatch table contains
  exactly two entries : `default` and `full-stack-monorepo`.
- **MUST** — every `scaffolder` value resolves to an existing
  file (or equals `"<built-in>"`). L1 audit test enforces.

**Constitution reference:** Article V. **Testable:** yes —
`test_dispatch_table_shape` + `test_dispatch_scaffolders_exist`.

### FR-IW-003: `default` archetype path preserves current behavior

- **MUST** — `--archetype default` invokes the file-copy
  scaffolder logic, byte-equivalent to the pre-b5.1
  `forge init` flow (no flags). Implemented via
  `runDefaultInit` extracted to `init-default.ts`.
- **MUST** — no flags + non-TTY stdin → silent default
  (preserves CI behavior, NFR-IW-004).
- **SHALL** — no flags + TTY stdin → wizard mode.

**Constitution reference:** Articles V, X. **Testable:** yes —
`init-default.test.ts` (5 tests) + e2e tests preserved.

### FR-IW-004: `full-stack-monorepo` archetype wrapper

- **MUST** — `bin/forge-init-fsm.sh` exists, executable. Stable
  ABI : `--target <dir> --project-name <slug>
  --reverse-domain <fqdn> [--force]`.
- **MUST** — translates the CLI ABI into `init.sh`'s legacy ABI
  (positional `<project-name>` + `--org <fqdn>` +
  `--target-dir <dir>`).
- **MUST** — propagates the underlying scaffolder's exit code
  unchanged. Passes shellcheck.

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_forge_init_fsm_sh_exists_executable` +
`test_forge_init_fsm_sh_translates_abi`.

### FR-IW-005: Auto-detection heuristic

- **MUST** — `cli/src/domain/archetype-detect.ts` is a pure
  function returning a discriminated union : `match` /
  `ambiguous` / `none`. Caller probes the file system to build
  the signal record.
- **MUST** — at archive time : `pubspec.yaml + Cargo.toml` →
  `match full-stack-monorepo` ; `pubspec.yaml` only → `ambiguous`
  (no Flutter-only archetype shipped) ; `Cargo.toml` only →
  `ambiguous` (no Rust-only archetype shipped) ; empty → `none`.
- **MUST** — caller surfaces ambiguity via `[NEEDS DECISION:]`
  exit 2 (Article III.4).

**Constitution reference:** Articles III.4, V. **Testable:** yes
— `archetype-detect.test.ts` (5 cases) +
`test_auto_detection_ambiguous_aborts`.

### FR-IW-006: Interactive wizard via Node's `readline`

- **MUST** — `cli/src/commands/init-wizard.ts` uses Node's
  `readline` exclusively. NO third-party UI library
  (NFR-IW-002).
- **MUST** — sequential prompts : numbered archetype menu,
  project name (regex `^[a-z][a-z0-9-]{1,49}$`), reverse domain
  (required iff archetype's `signals` list is non-empty).
- **MUST** — re-prompt × 3 on invalid input ; exit 2 after
  3 failures.
- **MUST** — non-TTY stdin → wizard does NOT start ; dispatcher
  routes to silent-default (NFR-IW-003).

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_wizard_skips_when_non_tty`.

### FR-IW-007: `--org` reverse-domain validation

- **MUST** — when an archetype declares non-empty `signals`,
  the dispatcher REQUIRES `--org <reverse-domain>` (or wizard
  prompt). Missing → exit 2.
- **MUST** — regex
  `^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$`. Invalid → exit 3.
- **SHALL** — implemented as a pure function in
  `cli/src/domain/reverse-domain.ts`.

**Constitution reference:** Article V. **Testable:** yes —
`reverse-domain.test.ts` (9 cases) + `test_reverse_domain_regex`.

### FR-IW-008: Standard `global/scaffolding.md`

- **MUST** — file `.forge/standards/global/scaffolding.md`
  contains 6 canonical H2 sections : `## Dispatch table contract`,
  `## Per-archetype scaffolder ABI`, `## Auto-detection
  heuristic`, `## Interactive wizard mode`, `## Adding a new
  archetype`, `## Interdictions`.
- **MUST** — Interdictions list 3 forbidden patterns :
  hard-coding archetype names outside the dispatch table,
  per-archetype scaffolders reading the dispatch table directly,
  bypassing the dispatcher via direct invocation of internal
  modules.

**Constitution reference:** Articles III.4, V, X. **Testable:**
yes — `test_standard_scaffolding_has_required_sections`.

### FR-IW-009: `docs/ARCHETYPES.md` decision matrix

- **MUST** — `docs/ARCHETYPES.md` exists with H1 `# Forge
  Archetypes — Decision Matrix` and H2 `## Available archetypes`
  containing a markdown table with at least 5 rows (today : 2
  active + 3 planned).

**Constitution reference:** Article X.3. **Testable:** yes —
`test_archetypes_decision_matrix_present`.

### FR-IW-010: Standards index entry

- **MUST** — `.forge/standards/index.yml` contains
  `id: global/scaffolding`, `scope: all`, `priority: high`,
  triggers including `init`, `forge init`, `wizard`, `archetype`,
  `dispatch-table`, `--auto`, `--wizard`.

**Constitution reference:** Article V. **Testable:** yes —
`test_index_has_scaffolding_entry`.

### FR-IW-011: Test harness `b5.test.sh`

- **MUST** — `.forge/scripts/tests/b5.test.sh` exists,
  executable, sources `_helpers.sh`. Manifest pattern with
  `test_b5_manifest_self_consistency` meta-check.
- **MUST** — three levels :
  - L1 (hermetic) — yml shape, scaffolder paths, standard
    sections, index entry, decision matrix, feature file, regex,
    no new third-party deps.
  - L2 (no flag) — CLI flag parsing, default-dispatcher
    idempotence, wizard non-TTY skip, ambiguous auto abort.
  - L3 (`--require-external-tools`) — placeholder for end-to-end
    against a real scaffold (deferred to scaffolder.test.sh L3
    which already exercises the same scaffolder).
- **MUST** — invoked from `forge-ci.yml` `harness` job.

**Constitution reference:** Article I. **Testable:**
self-testing via the meta-check.

### FR-IW-012: Spec consolidation at `init-wizard.md`

- **MUST** — at archive time, `.forge/specs/init-wizard.md`
  exists (this file). Consistent with `forge-ci.md`,
  `example-reference.md`, `upgrade.md` per-namespace spec
  conventions.
- **MUST** — links back to archived changes in the table above.

**Constitution reference:** Articles III.2, IV. **Testable:** yes
— `test_init_wizard_spec_present_post_archive` (gated).

---

## Non-Functional Requirements

### NFR-IW-001: Dispatcher idempotence

- **MUST** — running `forge init --archetype default` twice on
  the same target with the same flags produces the same outcome.
  L2 fixture exercises against the built CLI.

### NFR-IW-002: Zero new third-party dependencies

- **MUST** — the wizard, dispatcher, and dispatch-table parser
  use Node's standard library exclusively. No `inquirer`,
  `prompts`, `enquirer`, `js-yaml`, or similar packages added to
  `cli/package.json`. Audit test enforces.

### NFR-IW-003: Wizard auto-skip when stdin is non-TTY

- **MUST** — when `process.stdin.isTTY` is `false` AND no
  selection flag is passed, the dispatcher routes to the silent
  `default` scaffold path. Preserves CI compatibility.

### NFR-IW-004: Backwards compatibility on existing `forge init` flow

- **MUST** — existing CI scripts invoking `forge init` (with no
  archetype flag, in a non-TTY environment) MUST produce the
  same output and exit code as pre-b5.1. The dispatcher's
  silent-default path is byte-equivalent to the legacy file-copy.
  Exercised by the existing e2e tests in
  `cli/test/e2e/cli.test.ts` (kept passing post-refactor).

### NFR-IW-005: Audit-ID traceability

- **MUST** — every file created or modified by this change
  carries an `<!-- Audit: B.5.1 (part of b5-1-init-wizard) -->`
  comment in its first five lines, or YAML / shell equivalent.

### NFR-IW-006: Wizard time budget

- **SHOULD** — the wizard's total prompt → dispatch handoff time
  is ≤ 200 ms exclusive of user typing time.

---

## Scope

**In scope for the dispatcher (delivered so far):**

- The TS dispatcher (FR-IW-001) — **b5-1-init-wizard**.
- `dispatch-table.yml` (FR-IW-002) — **b5-1-init-wizard**.
- `default` archetype path preservation (FR-IW-003) — **b5**.
- `full-stack-monorepo` archetype wrapper (FR-IW-004) — **b5**.
- Auto-detection heuristic (FR-IW-005) — **b5**.
- Interactive wizard via readline (FR-IW-006) — **b5**.
- `--org` reverse-domain validation (FR-IW-007) — **b5**.
- Standard `global/scaffolding.md` (FR-IW-008) — **b5**.
- `docs/ARCHETYPES.md` decision matrix (FR-IW-009) — **b5**.
- Index entry (FR-IW-010) — **b5**.
- Test harness `b5.test.sh` 17/17 (FR-IW-011) — **b5**.
- This consolidated spec (FR-IW-012) — **b5**.

**Deferred to future changes (out of scope for B.5.1):**

- Additional archetypes (B.2 / B.3 / B.4 — separate changes).
  Each will register one entry in `dispatch-table.yml` + ship
  one `bin/forge-init-<archetype>.sh` wrapper.
- `docs/MIGRATION-PATHS.md` (cross-archetype migration guide ;
  needs ≥ 2 archetypes to be useful).
- Richer wizard UX (autocomplete, colours, type-ahead) via a
  third-party library — deferred unless adopter feedback
  demands it.
- Remote scaffolders (`forge init --from-template <url>`).
- Anonymous archetype-selection telemetry (deferred to H.3).
