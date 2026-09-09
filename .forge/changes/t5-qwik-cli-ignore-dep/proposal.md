# Proposal — `t5-qwik-cli-ignore-dep`

**Every Qwik surface Forge scaffolds ships a dead `npm run build`.**

## The defect

`@builder.io/qwik@1.20.0` publishes a CLI bundle, `dist/cli.cjs`, that does
`require("ignore")` at **module-initialisation time** — the call site is
`packages/qwik/src/cli/migrate-v2/tools/visit-not-ignored-files.ts`, reached from
the bundle's `__init` prologue. But the published package declares only three
runtime dependencies:

```
csstype  ^3.1.3
launch-editor  ^2.11.1
rollup  ^4.59.0
```

`ignore` is **not** among them. npm therefore never installs it, and the require
throws `MODULE_NOT_FOUND` before any command is dispatched. This is an undeclared
dependency in the published artefact — an upstream packaging bug, not a
misconfiguration on our side.

Two consequences the earlier B.9.2/B.9.3 write-ups understated:

1. **It is not `build`-specific.** The failure is at bundle load, so *every*
   `qwik` subcommand dies. `qwik --help` dies. That kills `build`, `preview`
   (`qwik build preview && vite preview`) and the `qwik` passthrough script alike.
2. **It is not `mobile-pwa-first`-specific.** It was recorded as a B.9 debt
   ("broken in the rendered scaffold"). It is in fact repo-wide.

## Blast radius — three archetypes, one of them stable and shipped

| Archetype | Surface | Status | `build` | `preview` |
|---|---|---|---|---|
| `full-stack-monorepo / 2.0.0` | `frontend/web-public/` | **stable, scaffoldable, shipped** | dead | dead |
| `ai-native-rag / 1.0.0` | `frontend/web-public/` | stable | dead | dead |
| `mobile-pwa-first / 2.0.0` | `web-pwa/` | candidate | dead | dead |

None of the three declares `ignore`. The flagship is the one that matters most:
it is `stable`, scaffoldable today, and its templates went out inside
`@sdd-forge/cli@0.5.1`. Anyone who ran `forge init` and then `npm run build` in
the web surface got a stack trace.

This is precisely the failure class the **CLI Trust Harness** (T5.1) exists to
prevent — "a tarball `@sdd-forge/cli@X` must not ship a scaffold that is
broken" — which is why this change sits in the T5 bucket rather than under B.9.

## Why it went unseen

The three archetype harnesses assert template *shape* (files present, sentinels
declared, counts within budget) and never execute an install-and-build. The one
place a real build runs is opt-in and Docker/npm-gated. `vite build` — which the
CI-adjacent checks and the b9-3 reviewer both reached for — **works**, because it
never loads the qwik CLI bundle. So every green signal available was genuinely
green; none of them covered the broken path.

## Options considered

**A — Bump `@builder.io/qwik` past the bug.** Not available: `1.20.0` *is* the
npm `latest` (verified live 2026-09-09). There is no fixed version to move to.

**B — Stop using the qwik CLI: recompose `build` from `vite` directly.** Works
for `build`, but silently redefines what `build` means (the CLI orchestrates
client + SSR + type-check as one step), leaves `preview` and the `qwik`
passthrough broken, and would have to be un-done when upstream ships the fix.

**C — Declare the missing dependency ourselves (chosen).** Add `ignore` to each
Qwik surface's `devDependencies` and pin it in the standard that owns Qwik pins.
One line per surface, restores every `qwik` subcommand, and is a no-op the day
upstream declares it properly.

C is a workaround for someone else's packaging bug and is documented as such at
every site, so it can be removed on evidence rather than archaeology.

## Supply-chain note

`ignore@7.0.9` — MIT, **zero transitive dependencies** (`npm install` reports
`added 1 package`). The same property that made `oauth4webapi` acceptable to
B.9.3. It is already in the dependency graph of most JS toolchains; here it
becomes explicit rather than assumed.

## Scope

**In:** the three `package.json.tmpl` files; `web-frontend.yaml` (pin + pitfall
note, minor bump) and its `REVIEW.md` ledger row; a sweeping guard in
`b8-9.test.sh`; a `CHANGELOG` entry.

**Out:** the `vite` pin drift between the standard (`7.3.6`) and two templates
(`=7.3.5`) — real, pre-existing, and needing its own verify-then-pin pass; see
`open-questions.md`. Also out: B.9.7's CI web layer, which will *consume* a
working build but does not belong to this fix.

## Negative scope

MUST NOT touch `cli/src/**`, any archetype schema, `overlay.sh`, the frozen
`ai-native-rag` snapshot, or any `.forge/changes/` archive.
