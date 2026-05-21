# Proposal: t5-3-3-vitest-bundle-preflight
<!-- Created: 2026-05-20 -->
<!-- Schema: default -->
<!-- Audit: T5.3.3 (docs/new-archetypes-plan.md §0.6) -->

## Problem

`cli/assets/` is **gitignored** (`cli/.gitignore:3 → assets/`)
and is regenerated from canonical sources by
`cli/scripts/bundle-assets.mjs` (invoked via `npm run bundle`).
The vitest e2e suite (`cli/test/e2e/archetypes-smoke.test.ts`)
spawns `node cli/dist/index.js init …` which **reads from
`cli/assets/`** — but vitest itself does NOT trigger
`npm run bundle`, only `npm test` does (via npm's `pretest`
chain implicit on the `test` script).

Failure mode observed 2026-05-20 (this session) :
- Developer or contributor invokes `npx vitest run` or
  `vitest run` directly after editing canonical templates.
- `cli/assets/` is **stale** (still mirrors the pre-edit
  state, or worse, is partially missing if a snapshot regen
  or git clean swept files).
- `archetypes-smoke.test.ts` calls `node cli/dist/index.js
  init` which rsyncs from the stale `cli/assets/...`.
- `rsync` errors out with exit 23 (mobile-only) or `forge
  init` returns 255 (full-stack-monorepo, depending on
  which files are stale).
- Test fails with confusing rsync stderr that doesn't point
  to the root cause (stale bundle).

This was logged as a LOW issue by the T5.3.1 independent
code-reviewer pass : *"cli/assets mirrors are gitignored
… Local contributors who run the harness without bundling
first will see false failures."* Pre-existing across other
harnesses (`t5-otel-dartastic.test.sh` has the same
property), but increasingly hit as T5.3.x changes touch
canonical templates.

## Solution

Add a **vitest `globalSetup`** hook that runs
`npm run bundle` exactly once before the test suite starts.
Vitest invokes `globalSetup` for **every entry path** —
`npm test`, `vitest run`, `vitest`, `npx vitest`,
`pnpm vitest`, etc. — closing the bypass entirely.

Implementation : one new file (`cli/test/global-setup.ts`)
+ one config line in `cli/vitest.config.ts::test.globalSetup`.

Performance budget : `npm run bundle` adds ~5-10s to a
clean tsc + assets copy. Acceptable — the failure mode it
prevents costs ~5-15 min of debugging per occurrence.

## Scope In

- `cli/test/global-setup.ts` — new TypeScript file. Spawns
  `npm run bundle` from `cli/` cwd, asserts exit 0, surfaces
  stderr on failure.
- `cli/vitest.config.ts` — add `globalSetup:
  "./test/global-setup.ts"` to `test:` block.
- New harness `t5-3-3.test.sh` OR extension of existing
  patterns — TBD design.
- `CHANGELOG.md` entry under `[Unreleased]`.
- `docs/new-archetypes-plan.md` §0.6 + inventory.

## Scope Out

- No touch on `cli/scripts/bundle-assets.mjs` itself — the
  bundle script is correct, only its invocation is the
  problem.
- No touch on other harnesses (`t5-otel-dartastic`,
  `t5-otel-app`, etc.) that share the same gitignored-mirror
  pattern. They could be fixed in this PR but cleaner to
  centralize the fix in vitest globalSetup which auto-applies
  to all vitest-driven tests.
- No `pretest` hook in `package.json` — would only catch
  `npm test`, not bare `vitest`. globalSetup is the right
  layer.
- No CI changes — `forge-ci.yml` already runs
  `npm run bundle` before vitest in the cli job.

## Impact

- **Users affected** : every contributor who runs vitest
  manually (locally or in custom workflow) after touching
  canonical templates.
- **Technical impact** : 2 small files (one new, one 1-line
  edit). No production code touched.
- **Performance** : +5-10s per vitest invocation on clean
  tsc cache, +1-2s on warm cache (assets copy only).
- **Dependencies** : T5.3.1 archived (✓).

## Constitution Compliance

- **Article I (TDD)** : applies. A new harness asserts the
  globalSetup is wired correctly. RED first.
- **Article II (BDD)** : N/A — no user-facing feature.
- **Article III (Specs Before Code)** : FRs in specs.md
  before code.
- **Article IV.2** : archived files untouched.
- **Article VIII (Infrastructure)** : test infra touched
  additively.

## Effort & Release

- **Effort** : `XS` (~½ hour).
- **Release target** : `v0.4.0-rc.2` (same vehicle as T5.3.1).
- **Critères de réussite** :
  - `cli/assets/` deliberately removed → `npx vitest run`
    regenerates it via globalSetup → tests GREEN.
  - `npm test` and `vitest run` produce identical pass
    counts.
  - `forge-ci.yml` unchanged (CI already calls
    `npm run bundle` separately).

---

*Next : `/forge:specify t5-3-3-vitest-bundle-preflight`.*
