# Proposal: a7-forge-upgrade

<!-- Created: 2026-04-30 -->
<!-- Schema: default -->
<!-- Parent audit module: A.7 — `forge upgrade` non-destructive merge -->
<!-- Depends on: b1-foundations + b1-scaffolder + b1-delivery + c1-reference-project (all archived) -->

## Problem

Once a project is scaffolded by `forge init`, the framework's
`.forge/`, `.claude/`, `.mcp.json`, `bin/`, and `docs/` trees are
**copied verbatim** into the project. From that moment on, the
project's framework copy is **frozen at the scaffold-time version**
recorded in `.forge/scaffold-manifest.yaml` (FR-EX-001 of
`c1-reference-project`).

When Forge itself evolves — Constitution amendments, new standards,
new agents, schema bumps, scaffold-plan version changes — adopters
have **no mechanism to pull the updates** into their project. They
have two equally bad options today :

1. **Manual copy-paste** : open Forge in one editor and the project
   in another, hand-merge each updated file. Error-prone, opaque
   audit trail, no rollback path.
2. **Re-run `forge init --force`** : overwrites every framework-owned
   file, **destroys any local customization** (custom standards
   added, project-specific Claude agents, edits to the scaffolded
   `Taskfile.yml`).

This is **the single biggest blocker for the first wave of adopters**.
Without a non-destructive upgrade path, every Constitution bump
becomes a manual chore and adopters drift away from the canonical
form. The drift compounds : after 3 bumps, no one wants to upgrade
because they don't know what they have left to lose.

The drift was just surfaced concretely by `c1-reference-project` :
the scaffolder's `scaffold-plan.yaml` had `version: "0.1.0"` even
though the schema had been promoted to `stable / 1.0.0` by
`b1-delivery`. The c1 implementation had to manually bump
`scaffold-plan.yaml` and re-run the scaffolder to regenerate the
manifest. **This is exactly the kind of drift `forge upgrade` would
mechanize for downstream projects** — they would never have noticed
the bump if they weren't actively scaffolding.

The audit roadmap (Module A.7) flags this as **High** priority for
T2 — and the user's guard-rail (no PR / no release before P1+P2
done) makes A.7 a P1 blocker before any release lands.

## Solution

Add a new CLI subcommand `forge upgrade [target]` that performs a
**3-way merge** between :

- **BASE** : the framework version originally used to scaffold the
  project (read from `.forge/scaffold-manifest.yaml` —
  `archetype_version` + `scaffold_plan_sha` + `template_set_sha`).
- **LEFT** : the project's **current state** of every
  framework-owned file (i.e. files under `.forge/`, `.claude/`,
  `.mcp.json`, `bin/`, `docs/`, root `CLAUDE.md`, `LICENSE`,
  `NOTICE` — paths declared in a new authoritative manifest
  `framework-owned-paths.yml`).
- **RIGHT** : the **current Forge framework version** (the version
  of Forge running `forge upgrade`, identified by `cli/VERSION` or
  framework SHA).

For each framework-owned path, the merge follows :

| LEFT vs BASE | RIGHT vs BASE | Action |
|---|---|---|
| same | same | no-op |
| same | changed | **clean upgrade** : replace LEFT with RIGHT |
| changed | same | **keep LEFT** : project's local customization is preserved |
| changed | changed | **3-way merge** via `git merge-file --diff3` ; on conflict, write a `.merge-conflict` marker and report. |

After the merge, `forge upgrade` updates the scaffold-manifest in
the project to record the new framework version + a new
`upgrade_history` array tracking every applied upgrade with date,
prior version, new version, and conflict count.

The command is **idempotent** : running `forge upgrade` twice in a
row on the same project produces no second-run changes. It is
**dry-runnable** via `--dry-run` which prints the planned actions
without writing.

## Scope In

- New CLI subcommand `forge upgrade [target-dir]` (defaults to
  current dir). Lives in `cli/src/commands/upgrade.ts` ; exposed
  via `cli/src/cli.ts` argv parsing.
- A new authoritative file `cli/assets/framework-owned-paths.yml`
  declaring every path the framework owns (`.forge/`, `.claude/`,
  `.mcp.json`, `bin/`, `docs/GUIDE.md`, root `CLAUDE.md`, etc.) +
  exclusions (`.claude/settings.local.json`, `.forge/changes/`,
  `.forge/specs/`, `.forge/product/`, `.omc/`).
- A new shell driver `bin/forge-upgrade.sh` (the underlying
  primitive — invoked by the JS CLI). Mirrors the
  `bin/forge-install.sh` pattern.
- 3-way merge implementation : reads `scaffold-manifest.yaml` to
  recover BASE ; runs `git merge-file --diff3` per file ; surfaces
  conflicts with explicit notice.
- Updates to `.forge/scaffold-manifest.yaml` schema : add
  `upgrade_history: [{date, from_version, to_version, conflicts: N}]`.
- New CLI flags : `--dry-run`, `--force` (overwrite even on
  conflict, with a backup), `--target <dir>`.
- New test harness `.forge/scripts/tests/a7.test.sh` exercising :
  L1 (CLI flag parsing, manifest schema, framework-owned-paths
  YAML), L2 (3-way merge fixtures with synthetic BASE/LEFT/RIGHT
  trees), L3 (end-to-end against a real example project — uses
  `examples/forge-fsm-example/` as the L3 fixture, exploiting c1's
  delivery).
- Documentation updates : `docs/GUIDE.md` § Upgrade flow,
  `docs/CONTRIBUTING.md` § How upgrades affect your local Forge
  customizations, README adoption section.
- New standard `.forge/standards/global/upgrade-policy.md`
  declaring : framework-owned paths convention, 3-way merge
  policy, conflict-resolution discipline, scaffold-manifest
  upgrade-history shape.
- Index entry : `global/upgrade-policy` in
  `.forge/standards/index.yml`.

## Scope Out (Explicit Exclusions)

- **No automatic Constitution amendment**. If a Constitution
  amendment requires action from the adopter (e.g., a new article
  bans a previously-allowed pattern), `forge upgrade` MUST surface
  the change and stop with a `[NEEDS CLARIFICATION:]` block.
  Mechanical merge is not the vehicle for ratifying constitutional
  shifts.
- **No spec-content migration**. `forge upgrade` does NOT touch
  `.forge/specs/`, `.forge/changes/`, or `.forge/product/`. Those
  are the project's content, not the framework's.
- **No archetype migration**. Switching schemas (e.g.,
  `default` → `full-stack-monorepo`) is a separate concern
  (deferred to a future change). `forge upgrade` only updates the
  current archetype's framework files.
- **No automatic CI workflow regeneration**. If `b1-delivery`'s 4
  reference workflows under `.github/workflows/` change shape, the
  upgrade reports the diff but does NOT auto-overwrite — adopters
  may have customized their workflows.
- **No GitHub App or remote integration**. `forge upgrade` is a
  local-only CLI command. The Forge Guardian GitHub App (G.3) is
  out of scope and deferred to T4+.
- **No multi-archetype support in this change**. Only the current
  archetype's framework files are merged. Cross-archetype upgrade
  is not in P1.

## Impact

- **Users affected** : every Forge adopter, current and future.
  Without A.7, the first early adopter who tries to follow a
  Constitution bump quits.
- **Technical impact** : Medium-Large. New CLI subcommand (~200
  lines TS), new shell driver (~150 lines bash), new YAML
  declaration (~50 lines), new test harness (~300 lines), new
  standard (~100 lines), updates to scaffold-manifest schema
  (~10 lines diff), docs updates. Estimated 800-1000 lines of
  new content.
- **Dependencies** : All archived (`b1-foundations` for schema,
  `b1-scaffolder` for manifest shape, `b1-delivery` for promoted
  schema, `c1-reference-project` for the L3 fixture). No upstream
  blockers.
- **Risk level** : **Medium**.
  - 3-way merge can produce surprising results on edge cases
    (e.g., a file the framework rewrote AND the user customized).
    Mitigated by `git merge-file --diff3` (battle-tested) and by
    the `--dry-run` mode.
  - `framework-owned-paths.yml` must be exhaustive ; a missing
    path = silent drift. Mitigated by an audit test that asserts
    every file under `.forge/`, `.claude/`, etc. in a fresh
    scaffold is either listed in the YAML or explicitly excluded.
  - Adopters with heavy customization may face conflicts. The
    conflict-marker approach + clear standard documents the
    discipline ; the `--force` flag with backup gives an escape
    hatch.

## Constitution Compliance

### Article I — TDD

The new CLI subcommand and shell driver ship with full TDD coverage :
- Unit tests for the 3-way merge logic (CLI side via Vitest,
  shell side via the new `a7.test.sh` harness).
- L2 fixture tests exercising every cell of the merge truth table.
- L3 end-to-end against `examples/forge-fsm-example/` simulating
  a real upgrade.

### Article II — BDD

The user-facing capability (`forge upgrade`) gets a Gherkin
`features/upgrade.feature` covering :
- Clean upgrade (no local edits → straight replacement).
- Customized file (local edits + framework unchanged → preservation).
- Conflicting upgrade (both changed → 3-way merge + conflict marker).
- Dry-run (no side effects).
- Re-run after upgrade (idempotence).

### Article III — Specs Before Code

This proposal precedes spec which precedes design which precedes
tasks which precedes code. Standard discipline.

### Article IV — Delta-Based Change Management

The new standard `global/upgrade-policy.md` is purely additive.
Updates to `scaffold-manifest.yaml` schema use the documented
`upgrade_history` extension — non-breaking append.

### Article V — Conformance Gate

`forge upgrade` itself is **the mechanism** for keeping projects
in conformance with bumped Constitutions. The conformance gate
governs `forge upgrade` itself (TDD, no `unwrap()` equivalent in
TS, etc.).

### Article X — Quality

- The CLI subcommand passes ESLint + Vitest with full coverage.
- The shell driver passes `shellcheck` (already wired into
  `forge-ci.yml` `lint` job).
- The standard passes `pymarkdown` lint.

### Articles VI / VII / VIII / IX / XI

Out of scope — `forge upgrade` is a framework-internal CLI command,
no Flutter / Rust / infra / observability / AI surface.

---

## Open Questions for the design phase

The proposal makes definitive choices on the strategic frame.
Three decisions remain for the design phase :

1. **Conflict markers** — should we use git-style `<<<<<<<` /
   `=======` / `>>>>>>>` markers (familiar to anyone who has
   resolved a merge), or a Forge-specific `[CONFLICT: ...]` block
   (more explicit, harder to miss) ? Recommendation : **git-style**
   for muscle memory, with a `.merge-conflicts` companion file
   listing every conflicted file for visibility.

2. **Backup strategy on `--force`** — should `--force` keep a
   `.forge.bak/` shadow tree, write per-file `.bak` siblings, or
   rely on Git (require clean working tree before `--force`) ?
   Recommendation : **require clean Git working tree** — uses Git
   as the canonical backup, no Forge-specific shadow tree to
   maintain. Adopters who don't use Git get an explicit error.

3. **Schema upgrade detection** — how do we detect a schema bump
   that requires content migration in the project's `.forge/specs/`
   (out of scope per the exclusion above) ? The upgrade should
   surface this and stop. Recommendation : compare
   `archetype_version` in the project's manifest vs the framework's
   schema.yaml ; if **major** version differs, abort with a clear
   `[NEEDS MIGRATION: from X.Y.Z to A.B.C]` message. Minor / patch
   bumps proceed normally.
