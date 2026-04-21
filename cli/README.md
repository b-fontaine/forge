# @forge/cli

Install, upgrade, and verify the [Forge framework](https://github.com/bfontaine/forge)
in a project.

## Install

```bash
npm install -g @forge/cli
# or, project-scoped
npx @forge/cli --help
```

## Commands

```bash
forge init [--source <dir>] [--target <dir>] [--force]
    Scaffold Forge into <target> (default: current directory). Copies the
    constitution, standards, schemas, templates, Claude Code assets, and the
    MCP config. Never copies runtime state (.forge/changes, .forge/specs,
    .forge/_memory) or private user config (.claude/settings.local.json).
    .forge/product/* is scaffolded from templates, never overwritten.

forge verify [--target <dir>]
    Run the deterministic Forge scripts (verify.sh and constitution-linter.sh)
    in the target directory. Exits 0 if both pass, 1 if either reports a
    violation, 2 if the scripts are missing.

forge version
    Print the installed Forge framework version.
```

## Guarantees

- **Idempotent**: re-running `forge init` without `--force` preserves every
  existing file in the target. It is safe to run in CI.
- **Never leaks Forge's own product content**: the source repo's
  `.forge/product/mission.md` is explicitly excluded from any copy; the
  target project's `.forge/product/*` is scaffolded from
  `.forge/templates/product/*` so each installation starts from a blank
  template.
- **Never leaks private Claude Code config**: `.claude/settings.local.json`
  is never copied.
- **Typed**: strict TypeScript. All domain rules are pure functions covered
  by unit tests; I/O adapters are covered by integration tests using real
  temporary directories.

## Development

```bash
npm install
npm test        # vitest unit + integration + e2e (requires `npm run build`)
npm run build
npm run lint    # tsc --noEmit
```

The package layout follows Clean Architecture:

- `src/domain/` — pure functions, zero I/O (`parseVersion`, `scaffoldPlan`)
- `src/commands/` — command handlers that take injected dependencies
- `src/cli.ts`, `src/index.ts` — commander wiring + process entry
- `test/domain/` — pure-function tests
- `test/commands/` — unit + integration tests with tmpdir fixtures
- `test/e2e/` — spawns the built binary

Every feature was driven by a failing test first (RED → GREEN → REFACTOR).

## Versioning

`@forge/cli` tracks the Forge framework version lockstep. The `prebuild`
script copies `VERSION` from the repo root into the package so that
`forge version` stays accurate. See [../docs/VERSIONING.md](../docs/VERSIONING.md).

## License

Apache-2.0. See [../LICENSE](../LICENSE) and [../NOTICE](../NOTICE).
