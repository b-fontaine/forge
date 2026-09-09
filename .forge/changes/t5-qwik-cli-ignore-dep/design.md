# Design — `t5-qwik-cli-ignore-dep`

## Diagnosis, reproduced

Minimal reproduction — two dependencies, **zero source files**, no vite config:

```json
{ "dependencies": { "@builder.io/qwik": "^1.20.0",
                    "@builder.io/qwik-city": "^1.20.0" } }
```

```
$ npx qwik --help
Error: Cannot find module 'ignore'
Require stack:
- node_modules/@builder.io/qwik/dist/cli.cjs
    at packages/qwik/src/cli/migrate-v2/tools/visit-not-ignored-files.ts (dist/cli.cjs:3377:29)
    at __init (dist/cli.cjs:16:56)
  code: 'MODULE_NOT_FOUND'
```

Two facts this reproduction establishes that the earlier B.9 write-ups did not:

- **`--help` fails.** The require runs in the bundle's `__init` prologue, before
  argument parsing. No `qwik` subcommand is reachable, so the defect is not
  `build`-scoped.
- **No project file is involved.** With zero sources, nothing in the Forge
  templates can be a contributing cause. The defect is entirely upstream.

`@builder.io/qwik@1.20.0`'s declared dependencies are `csstype`,
`launch-editor`, `rollup`. `ignore` appears in neither those nor anything they
pull in — verified by `ls node_modules/ignore` returning nothing.

**Hoisting was checked, not assumed.** The flagship surface carries
`@connectrpc/connect` and `@connectrpc/connect-web` on top of qwik, so `ignore`
could plausibly have been hoisted transitively and the flagship spared. Installed
the flagship's exact dependency set: `ignore` absent, `qwik build` dies. The
flagship is affected.

## Fix

One line per surface:

```json
"devDependencies": {
  "ignore": "7.0.9",
  ...
}
```

Exact pin, no caret — matching how `vite` is pinned in these files, and
appropriate for a package we carry only to satisfy someone else's bundle.

## Verification strategy

Two layers, because they prove different things:

| Layer | Asserts | Blind to |
|---|---|---|
| `b8-9.test.sh` L1 sweep | every Qwik surface *declares* `ignore`, consistently with the standard | whether the build actually runs |
| live render + install + build | `npm run build` reaches exit 0 in a real rendered tree | future surfaces |

The L1 sweep alone would pass against a wrong version string. The live build
alone would not notice a fourth surface added next month. Neither substitutes
for the other; NFR-T5QCI-004 requires both.

### Discovery, not enumeration

The sweep greps `.forge/templates/` for `package.json.tmpl` files declaring
`@builder.io/qwik`, then asserts each declares `ignore`. Two guards make the
discovery honest:

1. **Non-empty guard.** Zero discovered surfaces is a FAIL, not a pass. A
   discovery assertion that finds nothing is vacuous — the failure shape that
   produced `_test_f3_011` and `_test_f3_012` twice in this session.
2. **Standard agreement.** Each template's pinned value is compared against
   `web-frontend.yaml`'s, so a template drifting from the standard fails here
   rather than at somebody's `npm install`.

### Mutation probe

Before the fix is called done, the test is proven non-vacuous by removing the
`ignore` line from one template and confirming a RED, then restoring it. A test
written against already-correct files can pass for the wrong reason.

## Ordering (TDD)

1. Write the sweep test. Run it. **Confirm RED** — three surfaces missing the
   declaration, standard missing the pin.
2. Add the pin to `web-frontend.yaml`; bump `1.1.0` → `1.2.0`; `REVIEW.md` row.
3. Add the declaration + `_audit` note to the three templates.
4. Run the test. Confirm GREEN.
5. Mutation-probe (remove one line → RED → restore).
6. Live proof: render `mobile-pwa-first`, `npm install`, `npm run build` → 0.
7. Regression: `b8-9` full, `verify.sh`, `constitution-linter.sh`.

## Why `b8-9.test.sh` and not a new harness

`forge-ci.yml` sits at 418 lines against a 420 cap (NFR-CI-002) asserted in five
harnesses (`b6-8`, `t5-1`, `c1`, `g1`, `t5-otel-live-run`) plus `forge-self-ci.md`
and a `REVIEW.md` entry. A new harness costs a seven-file lock-step bump. For a
two-line defect fix that is disproportionate, and `b8-9` owns `web-frontend.yaml`
anyway — the guard belongs with the standard it enforces (ADR-T5QCI-002).
