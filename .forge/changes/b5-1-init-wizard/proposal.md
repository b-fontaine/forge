# Proposal: b5-1-init-wizard

<!-- Created: 2026-04-30 -->
<!-- Schema: default -->
<!-- Parent audit module: B.5.1 — `/forge:init` wizard with archetype auto-detection -->
<!-- Depends on: b1-scaffolder + b1-delivery + c1-reference-project + a7-forge-upgrade (all archived) -->

## Problem

The Forge framework today has **two disconnected `init` paths** :

1. **`forge init`** (npm CLI / TypeScript) — does a file-copy
   scaffold via `cli/src/commands/init.ts`. Copies framework
   assets (`.forge/`, `.claude/`, `.mcp.json`, `bin/`, `docs/`,
   `CLAUDE.md`) into the target dir. **Does not** know about
   archetypes ; assumes `default` schema.

2. **`bash .forge/scripts/scaffolder/init.sh`** (shell, delivered
   by `b1-scaffolder`) — the **archetype scaffolder**. Runs
   `flutter create` + `cargo new` + overlay templates +
   scaffold-manifest. Today only handles
   `--archetype full-stack-monorepo`. Adopters invoke it
   **directly**, NOT via the npm CLI.

The two paths solve different problems but the surface is
fragmented :

- An adopter wanting a `full-stack-monorepo` project today must
  clone Forge, find `.forge/scripts/scaffolder/init.sh`, and
  invoke it manually with the right `--org` flag. The published
  `@sdd-forge/cli` doesn't help — its `forge init` does the
  basic copy only, NOT the full archetype scaffold.
- When `b2-flutter-firebase`, `b3-rust-cli-tui`, or
  `b4-mobile-only` ship, each will need its own scaffolder. If
  each lives in a separate `init.sh` invoked directly, adopter
  onboarding fragments further. **The CLI needs an archetype
  dispatcher** before T3 second-archetype work begins.

This is **the dependency amont** of B.2 / B.3 / B.4 (T3 second
archetype) per the audit roadmap : without a multi-archetype
dispatch in `forge init`, each new archetype's onboarding is a
manual one-off.

The audit roadmap (Module B.5.1) flags this as **High** priority
for T2 — and the user's guard-rail (no PR / no release before
P1+P2 done) makes B.5.1 a P1 blocker before any release lands.

## Solution

Refactor `forge init` (TS CLI) to be the **single canonical
entry point** for project scaffolding. Add three modes :

1. **Explicit archetype** :
   `forge init --archetype <name> [project-name] [--org <reverse-domain>]`
   dispatches to the archetype's scaffolder. Today only
   `--archetype full-stack-monorepo` is wired (delegates to the
   existing `init.sh`) and `--archetype default` (the file-copy
   scaffold currently in `init.ts`). The dispatcher is built so
   adding a new archetype = registering its scaffolder + a
   `dispatch-table.yml` entry.

2. **Auto-detection** :
   `forge init --auto [--target <dir>]` inspects the target dir
   for archetype signals and picks the matching one :
   - `pubspec.yaml` AND `Cargo.toml` → `full-stack-monorepo`
   - `pubspec.yaml` only → (today: ambiguous + abort with
     `[NEEDS DECISION:]` ; future: `flutter-firebase` or
     `mobile-only` per heuristics)
   - `Cargo.toml` only → (today: ambiguous + abort ; future:
     `rust-cli-tui`)
   - Empty dir / no signals → `default`.

3. **Interactive wizard** :
   `forge init` (no flags, TTY stdin) prompts the user for :
   archetype (closed list), project name, reverse domain. Falls
   back to non-interactive mode + abort with usage when stdin is
   not a TTY (e.g., CI runs).

The dispatcher contract is documented in a new standard
`global/scaffolding.md`. A new `docs/ARCHETYPES.md` decision
matrix lists every archetype + its trade-offs (today : 1 row
for `default`, 1 row for `full-stack-monorepo`, 3 placeholder
rows for `flutter-firebase` / `mobile-only` / `rust-cli-tui`
that B.2 / B.3 / B.4 will fill in).

## Scope In

- **TS CLI refactor** : `cli/src/commands/init.ts` becomes the
  dispatcher. Existing file-copy logic moves to
  `cli/src/commands/init-default.ts` (still invoked by the
  dispatcher when `--archetype default`). New
  `cli/src/commands/init-archetype.ts` shells out to per-
  archetype scaffolders.
- **Argument plumbing** : new flags on `forge init` :
  `--archetype <name>`, `--auto`, `--wizard` (explicit), plus
  the existing `--target`, `--source`, `--force`. Positional
  `[project-name]` and option `--org <reverse-domain>` for
  archetype-specific scaffolders.
- **Auto-detection** :
  `cli/src/domain/archetype-detect.ts` — pure function reading
  signals from a target dir, returning one of `default` /
  `full-stack-monorepo` / `<ambiguous-list>`.
- **Interactive wizard** :
  `cli/src/commands/init-wizard.ts` — uses Node's `readline`
  (no third-party dep) to prompt sequentially. Closed-list
  archetype selection presented as a numbered menu.
- **Dispatch table** :
  `.forge/scaffolding/dispatch-table.yml` — maps archetype name
  → scaffolder script path. Today : `default` → built-in TS
  scaffolder ; `full-stack-monorepo` →
  `bin/forge-init-fsm.sh` (a thin wrapper around the existing
  `.forge/scripts/scaffolder/init.sh` with the new CLI's flag
  shape). Future archetypes register here.
- **Standard `global/scaffolding.md`** : documents the
  dispatcher contract, the auto-detection heuristic, the wizard
  mode, the dispatch-table convention, the per-archetype
  scaffolder ABI.
- **`docs/ARCHETYPES.md`** : decision matrix listing every
  archetype with its persona, primary stack, when-to-pick
  signals, gotchas. Today's table has 5 rows : 2 active
  (`default`, `full-stack-monorepo`) + 3 placeholders.
- **Test harness `b5.test.sh`** : L1 hermetic (CLI flag parse,
  dispatch-table shape, standard sections) + L2 fixture
  (auto-detection on synthetic project trees, wizard with
  scripted stdin) + L3 opt-in (real `flutter create` /
  `cargo new` against a tmpdir for `full-stack-monorepo`).
- **Updates to `cli/src/cli.ts`** : the `forge init` Commander
  subcommand exposes the new flags + the wizard mode.
- **Bumps to `cli/package.json`** : description updated to
  reflect the new wizard.

## Scope Out (Explicit Exclusions)

- **No new archetypes**. B.2 / B.3 / B.4 are out of scope ; this
  change ships the dispatcher and one wired-up archetype
  (`full-stack-monorepo`). Future archetypes plug into the
  dispatcher when they archive.
- **No `docs/MIGRATION-PATHS.md`**. Cross-archetype migration
  guides only make sense when ≥ 2 archetypes exist. Deferred to
  T3+.
- **No graphical wizard**. The interactive mode is text-only
  via Node's `readline`. A future enhancement (e.g., via
  `inquirer` / `prompts` package) is out of scope.
- **No remote scaffolder**. The dispatcher invokes local
  scaffolders only. `forge init --from-template <url>` style
  features are out of scope.
- **No telemetry on adoption**. Anonymous archetype-selection
  metrics are deferred to module H.3 (T4+).
- **No `forge init --upgrade`** equivalent. `forge upgrade` is
  the dedicated tool for that path (delivered by
  `a7-forge-upgrade`).

## Impact

- **Users affected** : every Forge adopter, current and future.
  The CLI becomes the single canonical entry point ;
  documentation simplifies dramatically.
- **Technical impact** : Medium. ~250 lines of new TS across 3
  command files + 1 domain pure function ; ~50 lines of
  dispatch-table YAML + standard ; ~40 lines `bin/forge-init-fsm.sh`
  wrapper ; ~300 lines of test harness ; doc updates.
  Estimated 700-900 lines.
- **Dependencies** : All archived (`b1-scaffolder` for the
  existing `init.sh` ABI, `b1-delivery` for stable schema,
  `c1-reference-project` for L3 fixture, `a7-forge-upgrade` for
  the dispatch + manifest patterns).
- **Risk level** : **Low-Medium**.
  - Refactoring `cli/src/commands/init.ts` could break the
    existing `default`-schema scaffold if the dispatcher
    miswires. Mitigated by keeping the existing file-copy
    function as `init-default.ts` and exhaustive Vitest unit
    tests on the dispatch.
  - Interactive wizard uses Node's `readline` ; flaky on edge
    cases (Ctrl-C handling, EOF on stdin). Mitigated by
    explicit non-TTY abort path + tests with scripted stdin.
  - Auto-detection heuristics are conservative today (only 1
    archetype recognized) ; extending them to ambiguous cases
    when B.2/B.3/B.4 land may surface false positives.
    Documented in the standard ; revisited per archetype.

## Constitution Compliance

### Article I — TDD

The new harness `b5.test.sh` follows the manifest pattern. CLI
unit tests via Vitest. RED-first per phase across :
- Phase 1 — dispatch infrastructure (table + standard + docs)
- Phase 2 — auto-detection + wizard
- Phase 3 — full-stack-monorepo wrapper + L3 fixture

### Article II — BDD

`features/init-wizard.feature` ships scenarios :
- Wizard prompts archetype + project name + reverse domain
- `--archetype <name>` skips wizard
- `--auto` detects `full-stack-monorepo` from `pubspec.yaml +
  Cargo.toml` co-presence
- `--auto` aborts with `[NEEDS DECISION:]` on ambiguous targets

### Article III — Specs Before Code

Standard pipeline. Specs follow this proposal.

### Article IV — Delta-Based Change Management

The new standard + the dispatch-table + the docs/ARCHETYPES.md
are all additive. `cli/src/commands/init.ts` is refactored ; its
contract is preserved (existing `default` scaffold behavior is
the unchanged path through the dispatcher).

### Article V — Conformance Gate

The dispatcher itself is a gate : invalid `--archetype <name>`
aborts. Auto-detection ambiguity aborts with
`[NEEDS DECISION:]` per Article III.4 (anti-hallucination).

### Article X — Quality

CLI passes ESLint + Vitest. Shell wrapper passes `shellcheck`.
Standard passes `pymarkdown`.

### Articles VI / VII / VIII / IX / XI

Out of scope — `forge init` is a framework-internal CLI command.

---

## Open Questions for the design phase

The proposal makes the strategic frame definitive. Three
decisions remain for the design phase :

1. **Wrapper script or direct dispatch ?** — Should the
   dispatcher invoke `bin/forge-init-fsm.sh` (a thin wrapper
   around `init.sh`) or invoke `init.sh` directly with
   normalized arguments ? Recommendation : **wrapper**, so the
   CLI's argument shape stays decoupled from the legacy
   `init.sh` flags. Each archetype ships a `bin/forge-init-<archetype>.sh`
   following a stable ABI.

2. **Wizard library** — `readline` (zero deps) vs `prompts` /
   `inquirer` (mature UX) ? Recommendation : **readline** for
   v1.0 of B.5.1 ; aligns with the framework's "minimal
   third-party dependencies" stance. If adopter feedback
   demands richer UX (autocomplete, type-ahead, color), revisit
   in a follow-up.

3. **Auto-detection ambiguity policy** — Today, `pubspec.yaml`
   only or `Cargo.toml` only is ambiguous (no archetype yet).
   Should `--auto` exit with `[NEEDS DECISION:]` (strict) or
   default to `default` schema (permissive) ? Recommendation :
   **strict** — `[NEEDS DECISION: pubspec.yaml present but
   archetype unclear (flutter-firebase vs mobile-only —
   neither shipped yet). Re-run with --archetype default for
   now.]`. Aligns with Article III.4 anti-hallucination.
