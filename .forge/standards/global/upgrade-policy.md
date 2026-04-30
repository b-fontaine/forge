<!-- Audit: A.7 (a7-forge-upgrade) -->
<!-- Stage: stable -->

# Upgrade Policy

This standard governs the `forge upgrade` capability — the
non-destructive merge of Forge framework updates into a
scaffolded project. It activates whenever the framework version
declared in a project's `.forge/scaffold-manifest.yaml` differs
from the version of the Forge framework currently invoking
`forge upgrade`.

## Framework-owned paths

The single authoritative declaration of which paths `forge
upgrade` manages lives in `cli/assets/framework-owned-paths.yml`.
The file declares two top-level keys :

- `owned:` — list of glob-style patterns the framework merges.
  Includes the constitution, standards, templates, schemas,
  scripts, Claude agents/commands/skills, MCP config, root
  CLAUDE.md, public docs, license + notice, and the framework's
  own bin entries.
- `excluded:` — list of paths the framework MUST NOT touch :
  `.claude/settings.local.json` (per-user override),
  `.forge/changes/**`, `.forge/specs/**`, `.forge/product/**`
  (project content), `.forge/scaffold-manifest.yaml` (mutated
  post-merge by FR-UP-007, not 3-way merged), `.omc/**`
  (runtime state).

A file is in the merge surface IFF it matches at least one
`owned:` glob AND no `excluded:` glob. Files outside the merge
surface are reported as `skipped` in the structured summary and
left alone.

To extend the merge surface — for example, when a new framework
file is introduced by an upcoming change — the contributor MUST
edit `framework-owned-paths.yml` in the same Forge change that
introduces the file. An L1 audit test
(`test_owned_paths_exist_in_framework`) asserts every glob
resolves to actual files in the framework repo, so silent drift
is mechanically detected in CI.

## Three-way merge policy

For each path in the merge surface, `forge upgrade` reads three
contents :

- **BASE** — the framework state at the project's
  `archetype_version` (recovered via the committed snapshot
  tarball under
  `cli/assets/scaffold-snapshots/<archetype>/<version>.tar.gz`).
- **LEFT** — the project's current file.
- **RIGHT** — the framework's current file.

Sameness is **binary SHA-256 of raw bytes**. Whitespace-only
edits count as real edits ; this is deterministic and audit-
friendly.

The merge action follows an exhaustive truth table :

| LEFT vs BASE | RIGHT vs BASE | Action |
|---|---|---|
| same | same | no-op (`unchanged`) |
| same | changed | replace LEFT with RIGHT (`upgraded`) |
| changed | same | keep LEFT (`preserved`) |
| changed | changed | `git merge-file --diff3 LEFT BASE RIGHT` ; `upgraded` on clean merge, `conflicted` on conflict |

When BASE is unavailable (snapshot missing for a legacy version),
the merge degrades to a 2-way comparison : LEFT == RIGHT → no-op,
else conflict (without `--force`) or replace (with `--force`).
Adopters get an explicit `[BASE unavailable for X.Y.Z, falling
back to 2-way merge]` warning.

## Conflict resolution discipline

When `git merge-file --diff3` produces conflict markers, they are
written **in-place** to the LEFT file using the standard git
format :

```
<<<<<<< HEAD
project's current state
||||||| BASE
the state at scaffold-time
=======
the framework's current state
>>>>>>> NEW
```

At completion, `forge upgrade` writes a `.merge-conflicts` file
at the project root listing every conflicted path :

```
[CONFLICT] .forge/standards/global/naming.md
[CONFLICT] .forge/agents/forge-master.md
```

When zero conflicts, any pre-existing `.merge-conflicts` file is
removed. The file is **gitignored** (FR-UP-012) — it is session
state, never project content.

Adopters resolve conflicts manually using their preferred tool
(`git diff`, an editor's merge view, `vimdiff`, etc.), then re-run
`forge upgrade`. Re-running sees LEFT == RIGHT for the resolved
files (the adopter has chosen one side) and exits cleanly.

The `--force` flag bypasses the exit-8 stop and lets conflicts
land in-place. **Adopters MUST first commit or stash any
uncommitted Git changes** — `forge upgrade --force` requires a
clean Git working tree (`git status --porcelain` empty). On a
non-Git target, `--force` aborts with an error instructing the
adopter to `git init`.

## Schema-version migration boundary

Before any merge, `forge upgrade` parses `archetype_version` from
the project's manifest and the framework's schema version. If the
**major** version differs (e.g. `1.x.y → 2.0.0`), the command
aborts with exit 7 and emits :

```
forge upgrade: major-version migration required (1.x.y → 2.0.0).
Manual migration needed — see docs/MIGRATIONS.md.
[NEEDS MIGRATION: from 1.x.y to 2.0.0]
```

This is Article III.4 anti-hallucination compliance : when the
upgrade would require ratifying a constitutional shift, we abort
rather than guess. Each major-bump change opens a new section in
`docs/MIGRATIONS.md` documenting the required adopter action.

Minor and patch bumps proceed normally. The SemVer convention is
the contract : minor bumps are additive, patch bumps are bug
fixes ; both are safe to mechanically merge.

When the schema lacks a `version` field (legacy archetype prior
to FR-GL-024 of `b1-delivery`), `forge upgrade` emits a warning
and proceeds, treating the bump as a patch.

## Upgrade history audit trail

After every successful run, the project's
`.forge/scaffold-manifest.yaml` is updated to record the upgrade.
The new optional top-level field `upgrade_history:` is **append-
only** :

```yaml
upgrade_history:
  - date: 2026-05-15T10:32:18Z
    from_version: "1.0.0"
    to_version: "1.1.0"
    from_template_set_sha: <sha>
    to_template_set_sha: <sha>
    counts:
      unchanged: 32
      upgraded: 5
      preserved: 2
      conflicted: 1
      skipped: 8
    cli_version: "0.3.0"
```

Each upgrade adds one entry. Existing entries are never edited.
The manifest's canonical fields (`archetype_version`,
`scaffold_date`, `scaffold_plan_sha`, `template_set_sha`,
`tools`) are **mutated** to reflect the most recent state, so
new tools can read the manifest without parsing the history.

The identity fields — `project_name`, `reverse_domain`,
`root_module` — are **immutable post-scaffold**. `forge upgrade`
MUST refuse to change them (changing the project name would
conflict with file paths and Cargo / Flutter package identity).

## Interdictions

The following patterns are forbidden. Each is a constitutional
violation under Article V.2 ; CI gates enforce them where
feasible.

- **Hand-editing files under `owned:` outside a Forge change.**
  Drift accumulates silently ; the next `forge upgrade` either
  detects it as `preserved` (best case — the adopter never
  benefits from framework improvements to that file) or
  surfaces it as a conflict marker (worse case — adopter
  resolves something that should never have been a conflict).
  Always go through the Forge pipeline.
- **Running `forge init --force` when meaning `forge upgrade`.**
  `init` wipes ; `upgrade` preserves. The two commands look
  superficially similar but are operationally opposite. Always
  use `upgrade` for an existing project.
- **Committing `.merge-conflicts` to the project repo.** It is
  session-only state listing conflicts that the adopter has not
  yet resolved. Committing it freezes conflict markers in the
  project's history, which is the worst possible state.
  `.gitignore` covers it (FR-UP-012) — adopters MUST NOT remove
  the entry.
