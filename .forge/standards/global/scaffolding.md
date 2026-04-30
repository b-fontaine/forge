<!-- Audit: B.5.1 (b5-1-init-wizard) -->
<!-- Stage: stable -->

# Scaffolding (Init Dispatcher Contract)

This standard governs the `forge init` dispatcher — the single
canonical entry point for project scaffolding in the Forge
framework. It activates whenever `forge init` is invoked, in
any of its three modes (explicit `--archetype`, `--auto`
detection, interactive `--wizard`).

## Dispatch table contract

The single authoritative archetype registry lives at
`.forge/scaffolding/dispatch-table.yml`. The file declares one
top-level key `archetypes:` whose values are records with this
shape :

```yaml
archetype-name:
  name: archetype-name             # MUST equal the map key
  scaffolder: <"<built-in>" | path> # relative to repo root
  description: "one-line summary"
  signals: [path1, path2, ...]      # for --auto detection
  since: "<SemVer>"                 # framework version that registered it
```

Required fields : `name`, `scaffolder`. The other fields are
optional but recommended ; tests assert the canonical pair are
present and ignore unknown keys (forward-compatibility per
ADR-012 of `b5-1-init-wizard`).

When `scaffolder` equals `"<built-in>"`, the dispatcher invokes
the TS file-copy logic directly (today only `default`). Otherwise
the dispatcher shells out to the named script.

To extend the dispatcher with a new archetype : (1) append one
entry here ; (2) write `bin/forge-init-<archetype>.sh`
following the per-archetype ABI below ; (3) update
`docs/ARCHETYPES.md` decision matrix. **No edit to the TS
dispatcher is needed.**

## Per-archetype scaffolder ABI

Every per-archetype scaffolder script accepts the same stable
contract :

```
bin/forge-init-<archetype>.sh \
    --target <dir> \
    --project-name <slug> \
    --reverse-domain <fqdn> \
    [--force]
```

The wrapper is responsible for translating these stable flags to
the underlying scaffolder's native flag shape (e.g. for
`full-stack-monorepo`, the wrapper translates to `init.sh`'s
positional `<project-name>` + `--org <fqdn>` + `--target-dir
<dir>`). The wrapper propagates the underlying scaffolder's exit
code unchanged.

This decoupling lets each archetype keep its native scaffolder
interface while the CLI exposes a uniform surface. New
archetypes plug into the dispatcher with no churn elsewhere.

## Auto-detection heuristic

`forge init --auto` reads the `signals:` lists from the
dispatch table and probes the target directory's filesystem for
each declared signal. The result is one of :

- **Match** : exactly one archetype's signals are all present →
  proceed with that archetype.
- **Ambiguous** : signals match multiple archetypes' lists →
  abort (Article III.4 anti-hallucination — never guess).
- **None** : no signals present → fall back to `default`
  archetype only when the user invoked auto on an empty
  directory ; abort otherwise with `[NEEDS DECISION:]`.

The heuristic is implemented as a pure function in
`cli/src/domain/archetype-detect.ts` taking a
`Record<string, boolean>` of `signal-path → present`. The I/O
that builds the record (probing the file system) lives in the
caller. This split makes the heuristic exhaustively unit-testable
without tmpdir setup.

## Interactive wizard mode

When invoked with no selection flag AND `process.stdin.isTTY`
is `true`, the dispatcher enters wizard mode :

1. **Archetype prompt** — numbered closed-list menu drawn from
   the dispatch table.
2. **Project name prompt** — kebab-case slug (regex
   `^[a-z][a-z0-9-]{1,49}$`).
3. **Reverse domain prompt** — required iff the chosen
   archetype's `signals` list is non-empty (regex
   `^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$`).

The wizard uses Node's standard `readline` module exclusively.
**No third-party UI library is permitted** (NFR-IW-002 of
b5-1-init-wizard) — `inquirer`, `prompts`, `enquirer` and
similar packages are forbidden. The wizard auto-skips when
`process.stdin.isTTY` is `false` (NFR-IW-003) — non-TTY
invocations route to the silent-default path.

## Adding a new archetype

When a future change (e.g. `b2-flutter-firebase`) adds a new
archetype, the contributor MUST :

1. Land the archetype's scaffolder script (typically a shell
   script under `.forge/scripts/scaffolder/<archetype>/`).
2. Land the per-archetype wrapper at
   `bin/forge-init-<archetype>.sh` translating the stable ABI
   to the native flags.
3. Append a new entry to `dispatch-table.yml` declaring `name`,
   `scaffolder`, `description`, `signals`, `since`.
4. Append a new row to `docs/ARCHETYPES.md` with the
   decision-matrix metadata (persona, when-to-pick, stack).
5. Extend `b5.test.sh` L3 to exercise the new archetype's
   end-to-end scaffold.

Steps 1 + 2 + 3 + 5 are mechanical ; step 4 is the
documentation deliverable adopters consult before picking.

## Interdictions

The following patterns are forbidden. Each is a constitutional
violation under Article V.2 ; CI gates enforce them where
feasible.

- **Hard-coding archetype names in CLI command files outside
  the dispatch table.** The TS dispatcher MUST resolve archetype
  names from `dispatch-table.yml` at runtime. Hard-coded
  string comparisons (e.g. `if (archetype === "full-stack-monorepo")`)
  inside the dispatcher's path-selection logic are forbidden.
- **Per-archetype scaffolders reading the dispatch table
  directly.** Only the dispatcher reads `dispatch-table.yml`.
  Scaffolders receive their inputs through the stable per-
  archetype ABI. This keeps scaffolders portable and the
  dispatcher the single source of truth.
- **Bypassing the wizard via direct invocation of
  `init-default.ts` / `init-archetype.ts` from external tools.**
  The dispatcher (`init.ts`) is the only authorized entry point.
  Direct invocations from external scripts are unsupported and
  may break across releases.
