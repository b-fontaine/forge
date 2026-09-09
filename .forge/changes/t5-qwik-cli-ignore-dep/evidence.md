# Evidence — `t5-qwik-cli-ignore-dep`

All probes run 2026-09-09 on this machine: Node v26.8.1, npm 12.0.2.
The archetypes' declared target is `.nvmrc` = **24** — this matters, see P-7.

---

## P-1 — the defect, reproduced with zero project files

`package.json` with two dependencies (`@builder.io/qwik ^1.20.0`,
`@builder.io/qwik-city ^1.20.0`), no sources, no vite config:

```
$ npx qwik --help
Error: Cannot find module 'ignore'
Require stack:
- node_modules/@builder.io/qwik/dist/cli.cjs
    at packages/qwik/src/cli/migrate-v2/tools/visit-not-ignored-files.ts (dist/cli.cjs:3377:29)
    at __init (dist/cli.cjs:16:56)
  code: 'MODULE_NOT_FOUND'
```

Two things this establishes that a scaffold-level reproduction cannot:

- **No Forge template is a contributing cause.** There are no templates in this
  tree.
- **The failure is not `build`-scoped.** The require runs in the bundle's
  `__init` prologue, so it precedes argument parsing. `--help` dies.

`@builder.io/qwik@1.20.0` declared dependencies: `csstype`, `launch-editor`,
`rollup`. `ls node_modules/ignore` → nothing.

## P-2 — no upstream version to bump to

```
$ npm view @builder.io/qwik version   → 1.20.0
$ npm view @builder.io/qwik dist-tags → latest: 1.20.0
```

1.20.0 *is* `latest`. ADR-T5QCI-001's first alternative is unavailable, not merely
less attractive.

## P-3 — blast radius, measured per archetype

`grep -rl '"@builder.io/qwik"' .forge/templates` → three `package.json.tmpl`:
`full-stack-monorepo/2.0.0`, `ai-native-rag/1.0.0`, `mobile-pwa-first/2.0.0`.
`grep -rl '"ignore"'` → none.

**The flagship was checked, not inferred.** It carries `@connectrpc/connect` and
`@connectrpc/connect-web` on top of Qwik, so `ignore` could plausibly have been
hoisted transitively and the flagship spared. Installed its exact dependency set:
`ignore` absent, `qwik build` → `MODULE_NOT_FOUND`. Affected.

## P-4 — verify-then-pin, LIVE

```
$ npm view ignore version license   → 7.0.9  MIT
$ npm view ignore@7.0.9 dependencies → (none)
$ npm view ignore@7.0.9 engines      → { node: '>= 4' }
```

Zero transitive dependencies; `npm install` reports `added 1 package`. Compatible
with the surfaces' `engines.node >= 18.11`.

## P-5 — the fix, on a freshly rendered tree

Rendered `mobile-pwa-first` through the real wrapper
(`FORGE_MPF_FORCE_SCAFFOLD=1`, `SOURCE_DATE_EPOCH=0`), i.e. from the patched
template, with no manual `npm install ignore` step:

```
$ grep '"ignore"' web-pwa/package.json  → "ignore": "7.0.9",
$ npm install                            → OK
$ npm run build                          → exit 0        (under npm 11, see P-7)
```

## P-6 — the flagship surface

`init.sh` renders the **1.0.0** flagship layout; the 2.0.0 `frontend/web-public`
surface has no rendering path through it, so no full render-and-build was
available for the flagship. It was therefore proven at the layer where the defect
actually lives — module resolution — using the template's exact dependency set:

```
before: qwik build → Cannot find module 'ignore'
after (+ ignore@7.0.9): npx qwik help → loads, prints "🔭 Qwik Help"
npm ls ignore --depth=0 → └── ignore@7.0.9
```

Stated at that scope deliberately: this is not a claim that the flagship's full
build was executed end-to-end.

## P-7 — a SECOND, independent upstream defect (npm ≥ 12 only)

With `ignore` present, `qwik build` progresses past module load and then fails:

```
npm run build.types
npm error code EUNKNOWNCONFIG
npm error Unknown cli flag: --pretty
Error: Type check failed:
```

Cause, read from the bundle (`dist/cli.cjs:11861` and `:11926`):
`getScript("build.types")` returns the string `npm run build.types`, to which the
CLI appends ` --pretty` before executing it. So `--pretty` is handed to **npm**,
not to `tsc`.

**Version-scoped by measurement, not assumption:**

| npm | `npm run build.types --pretty` |
|---|---|
| 9 | accepts (exit 0) |
| 10 | accepts (exit 0) |
| 11 | accepts (exit 0) |
| 12.0.2 | **rejects** — `EUNKNOWNCONFIG` |

And end-to-end on the rendered tree:

```
under npm 11 (what Node 24 — the .nvmrc target — ships):  npm run build → exit 0
under npm 12 (this machine, ahead of target):             npm run build → exit 1
```

**This is why `build` was NOT recomposed on top of `vite`.** The evidence first
looked like it forced that redesign; measuring the npm axis showed the
orchestration is fine on the declared target, and that recomposing would have
been an over-correction driven by one machine being ahead of `.nvmrc`. Recorded
as `open-questions.md` Q-004 with a dated trigger rather than acted on now.

The `ignore` fix is therefore necessary **and** sufficient for the target
environment, and remains necessary under npm 12 (the CLI cannot load without it).

## P-8 — the tests were made to fail before being trusted

`b8-9.test.sh::T-013`, all three branches:

| Probe | Mutation | Result |
|---|---|---|
| M1 | drop `ignore` from one template | RED, naming that file |
| M2 | template pins `7.0.8`, standard `7.0.9` | RED on the disagreement |
| M3 | point discovery at an empty directory | RED — "discovered ZERO Qwik surfaces" |

M3's first attempt was a **broken probe**, not a passing one: the copied harness
was placed outside `tests/`, so `_helpers.sh` no longer resolved and `run_test`
was undefined. It emitted no T-013 line at all, which is easy to misread as
"nothing to report". Re-run from inside `tests/`, it fails as designed. Recorded
because a probe that cannot execute looks, in a grep-filtered log, much like a
probe that passed.

## P-9 — pre-existing CI red, found while doing this

`main`'s CI had been failing on its five most recent runs. Not caused by this
change; found because this change touches `web-frontend.yaml`.

- **`b8-9.test.sh::T-007`** asserted the literal `version: "1.0.0"` and went red
  when `b9-2-web-pwa` legitimately bumped the standard to `1.1.0` on 2026-07-28 —
  red for six weeks. The `Forge gates` job (verify.sh + constitution-linter) stayed
  green throughout: it does not run the per-brick harnesses, so "gates pass" was
  true and much narrower than it sounded.
- **`b9-1.test.sh:391,406`** — SC1010, two shell variables named `fi` (the `if`
  terminator). CI's `Shell lint` runs at `severity=warning`, so a warning is a red
  job.

Both repaired here. T-007 now asserts well-formed SemVer, and T-008 requires a
ledger row for whichever version the standard *currently* declares — so the next
bump cannot silently desynchronise them again. Mutation-probed: a malformed
version reds T-007; a valid-but-unledgered `9.9.9` reds T-008 while T-007 stays
green, proving the two assert different things.

## P-10 — flaky harnesses, recorded not fixed

Sweeping all 70 CI-registered harnesses locally surfaced `b8-12` and `b8-15` as
**non-deterministic**: five consecutive runs of `b8-12` gave exit codes
`1 1 1 0 0`, and again `0 0 0 1 0`, with `Failed: 0` reported in the body each
time. Both pass in isolation. This is the known shared-tree snapshot race
(`b8-1` family). Out of scope here; it means `main`'s CI can go red at random
independently of anything in this change.

## P-11 — regression

See `tasks.md` T6. `verify.sh`, `constitution-linter.sh`, the full `b8-9` suite
and the CI-registered harness sweep are recorded there.
