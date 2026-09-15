# Evidence — `t7-qwik-deps-refresh`

All probes 2026-09-13, node v26.8.1 / npm 12.0.2.

---

## P-1 — two HIGH `sharp` advisories on the shipped surface (npm: 3 high)

`npm audit` on a freshly rendered `web-pwa/`, before any change:

```
sharp  <=0.35.4-rc.0
Severity: high
  libvips: CVE-2026-33327, CVE-2026-33328, CVE-2026-35590, CVE-2026-35591
  libheif: GHSA-g89c-p67h-r497, GHSA-2jg2-4ch7-h545
node_modules/sharp
  vite-imagetools  <=3.1.0 || 7.0.4 - 10.0.0
    @builder.io/qwik-city  >=1.17.0

3 high severity vulnerabilities
fix available via `npm audit fix --force`
Will install @builder.io/qwik-city@1.16.1, which is a breaking change
```

`npm outdated` did not mention any of this. The pins were the reason for the brick; the
advisories were the finding.

## P-2 — the remedy npm proposes is a downgrade

qwik-city 1.16.1 is four minors below the `^1.20.0` that `web-frontend.yaml:45-46` pins,
across a breaking change. sharp's latest is **0.35.4** — the first release outside
`<=0.35.4-rc.0` — so the floor can be lifted instead.

After `overrides: { "sharp": "^0.35.4" }`:

```
added 2 packages, removed 1 package, changed 7 packages, and audited 170 packages
found 0 vulnerabilities
```

## P-3 — three of `npm outdated`'s four suggestions were rejected on evidence

```
@types/node          22.20.2  →  26.5.1
typescript             5.9.3  →  7.0.2
vite                   7.3.6  →  8.3.0
vite-tsconfig-paths    4.3.2  →  6.1.1
```

Checked against the installed packages rather than assumed:

```
$ node -p "...@builder.io/qwik/package.json').peerDependencies"
{"vite":">=5 <8"}                       ⇒ vite 8.3.0 EXCLUDED, the exact pin holds

$ node -p "...@builder.io/qwik/package.json').dependencies"
["csstype","launch-editor","rollup"]     ⇒ `ignore` still undeclared, workaround stays

$ cat web-pwa/.nvmrc → 24                ⇒ @types/node ^24.13.4, not 26.5.1
```

`@builder.io/qwik`, `@builder.io/qwik-city` and `oauth4webapi` were not listed at all —
already at their maximum.

## P-4 — the accepted bumps, proven

On the probe, then re-proven on a render from the **updated template**:

```
install OK
found 0 vulnerabilities
tsc rc=0            (tsc Version 7.0.2)
✓ built in 428ms    (qwik build)
```

TypeScript 7 typechecks the surface with no change to any source file.

## P-5 — mutation probes

| probe | result |
|---|---|
| `overrides.sharp` removed | RED |
| sharp set below the CVE floor (`^0.34.5`) | RED |
| `vite` loosened to a caret | RED |
| `vite` bumped to `=8.3.0` | RED |
| `@types/node` moved off the pinned runtime | RED |
| `ignore` workaround dropped | RED |

**6/6**, template restored byte-identical each time.

## P-6 — regression

Full CI matrix **81/81** · `b9-2` **37/0** · `cli/assets/` re-bundled after the template
edit (the coupling `t7-flutter-deps-refresh` P-7 already recorded).

## P-7 — negative scope

`web-frontend.yaml` untouched: it pins `qwik`, `qwik_city` and `vite`, none of which
move, so a version bump there would have been churn on a file other harnesses pin.
`@builder.io/qwik*`, `oauth4webapi`, `vite` and `ignore` are unchanged in the manifest.

---

# Extension — reopened 2026-09-14

node v26.8.1 / npm 12.0.2 again (Q-003 still applies). Every render below is the
**real wrapper** (`bin/forge-init-ai-native-rag.sh`) into a scratch directory outside
the repository and outside `cli/assets/`.

## P-8 — the sibling surfaces carry the same chain

`ai-native-rag` rendered from the HEAD template, `frontend/web-public/`:

```
overrides= None   vite= =7.3.5
npm ls sharp:  @builder.io/qwik-city@1.20.0 -> vite-imagetools@9.0.3 -> sharp@0.34.5
npm audit:     esbuild 0.27.3 - 0.28.0   (GHSA-g7r4-m6w7-qqqr, low)
               sharp <=0.35.4-rc.0  Severity: high
                 GHSA-f88m-g3jw-g9cj (libvips CVE-2026-33327/33328/35590/35591)
                 GHSA-rgj7-g3m4-5g8c (libheif)
               4 vulnerabilities (1 low, 3 high)
npm audit --audit-level=high  -> exit 1
```

`full-stack-monorepo/2.0.0` `frontend/web-public/` is rendered only by
`migration-plan-2.0.0.yaml`, not by `forge init`; its manifest, placeholders
substituted, lockfile-resolved (`npm install --package-lock-only`): the same
`sharp@0.34.5` and the same **4 vulnerabilities (1 low, 3 high)**.

In `@sdd-forge/cli@0.5.1` `ai-native-rag` was `stable` / `scaffoldable: true` and
`mobile-pwa-first` a refused `candidate`: the first pass fixed the surface no 0.5.1
adopter could render and missed the one they could.

## P-9 — RED, in two steps

`b8-9::T-014` against HEAD: fails at the standard (`versions: has no single 'sharp'
floor`). With the standard's pin added and nothing else: **exactly four** failures,
two per sibling (`overrides.sharp is None`, `vite is '=7.3.5'`), none on web-pwa, and
`T-008` red for the missing `REVIEW.md` 1.3.0 row. `b8-9` 12/14.

## P-10 — GREEN, and the render after

`b8-9` **14/14**. Same wrapper, updated template:

```
overrides= {'sharp': '^0.35.4'}   vite= =7.3.6
npm ls sharp:  ... vite-imagetools@9.0.3 -> sharp@0.35.4
npm ls:        vite@7.3.6, esbuild@0.28.2
npm audit:     found 0 vulnerabilities
npm audit --audit-level=high -> exit 0
tsc --noEmit -> 0      vite build -> 0 ("built in 722ms")
qwik --help (node .../qwik/dist/cli.cjs) -> 0
```

Before the edit the same three checks were also 0 (`built in 653ms`): nothing that
built stopped building.

Flagship 2.0.0 manifest, lockfile-resolved after: `sharp@0.35.4`, `vite@7.3.6`,
`esbuild@0.28.2`, **found 0 vulnerabilities**.

The low `esbuild` advisory closed as a side effect of the vite alignment, not of the
override: 7.3.5 resolves `esbuild@0.27.7`, 7.3.6 resolves `0.28.2`. It was first
written down the other way round — "closing it would mean moving the pin" — and
corrected after this measurement.

Two probe-side workarounds, identical before and after, neither in any Forge file:
`buf generate` was run with the es plugin only (Q-005), and the generated
`v1/rag/rag_pb.ts` was copied to the path `connect-client.ts` imports (Q-006).
`npx qwik --help` exits 1 under npm 12 whatever the tree; the CLI was invoked directly.

## P-11 — mutation probes on T-014

| probe | result |
|---|---|
| `overrides` removed (ai-native-rag) | RED, names that file |
| override set below the CVE floor, `^0.34.5` (ai-native-rag) | RED |
| `vite` loosened to `^7.3.6` (flagship) | RED |
| `vite` reverted to `=7.3.5` (flagship) | RED |
| `overrides` removed (web-pwa, the first-pass surface) | RED |
| `versions.sharp` deleted from the standard | RED |
| the pin survives only as a comment in `versions:` | RED |
| the pin moved out of `versions:` to top level | RED |
| the standard's floor raised to 0.35.5, surfaces left behind | RED, all three named |

**9/9**, each file restored byte-identical (sha256), `b8-9` 14/14 after. The failure
message distinguishes a vulnerable value from one merely out of lock-step.

## P-12 — regression

Local replay of `forge-ci`: `npm run bundle`, then all **82** harness entries parsed from
`forge-ci.yml` — **81 PASS**; the one red is `b7-7::test_b7_7_no_archetype_or_schema_edit`,
which fails on *any uncommitted* edit under the `ai-native-rag` template tree
(`git diff --name-only HEAD`) and passes once committed. `verify.sh` RESULT: PASS
(0 failed). `constitution-linter.sh` 103 PASS / 0 FAIL. `shellcheck --severity=warning`
(the CI level) clean on `b8-9.test.sh`. `forge-ci.yml` untouched: 421 lines.

## P-13 — review round 1 (2026-09-15)

Four independent read-only lanes (spec-and-guard, claims, couplings, security-process),
each finding re-checked by a separate skeptic: **CHANGES REQUIRED** from three lanes,
APPROVE-WITH-NITS from one. 11 findings survived verification (one rated major by its
lane, minor by its verifier), three were refuted as not-a-defect (`status: implemented`
with T8.7 open; `k4`'s stale 7.3.5 literal, which predates this change; the removal
comment not naming `b9-2::T-037`, now named anyway).

The guard findings, proven before fixing — five probes, all GREEN against round 0:

| probe | round 0 | round 1 |
|---|---|---|
| qwik + qwik-city moved to `devDependencies`, override dropped (ai-native-rag) | GREEN | RED |
| new `qwik-city`-only surface with no override | GREEN | RED |
| README `vite` row reverted to `=7.3.5` (ai-native-rag) | GREEN | RED |
| README `sharp` row deleted (flagship) | GREEN | RED |
| README `sharp` row set to `^0.34.5` (flagship) | GREEN | RED |

With the nine P-11 probes: **14/14 RED**, every file restored byte-identical (sha256), the
temporary probe surface removed, `b8-9` 14/14, `shellcheck --severity=warning` clean.

The written-claim findings, each reproduced by its verifier:
`sharp` carries **two** HIGH advisories — npm's "3 high" counts sharp, vite-imagetools and
qwik-city; qwik-city 1.16.1 is **four** minors below 1.20; the shipped
`examples/forge-rag-example` still resolves `sharp@0.34.5`; `migration-plan-2.0.0.yaml`
is not in `v0.5.1` (`e183673`, after the tag), so the flagship web surface was not
rendered by 0.5.1; `forge upgrade` reads only the framework's root owned-paths file
(Q-007); the "tsc / vite build still pass" sentence depended on the two probe workarounds;
`web-pwa-ci.yml` would audit `web-pwa` only; and `harness-rust` printed
`SKIP T-C02: buf generate skipped — BSR network unavailable (offline)` on run
`34815880019` while its cargo leg downloaded crates — the underlying go_package error was
reproduced locally with T-C02's own pattern.

## P-14 — review round 2 (2026-09-15)

Two lanes — closure of the eleven round-1 findings, accuracy of the round-1 text — each
finding re-checked by a separate skeptic. Closure: F1, F2, F3, F5, F6, F7, F8, F10 closed;
**F4, F9, F11 partial**. Five findings confirmed, one refuted (a Known-issues ordering
premise that did not match HEAD).

F11's partial closure, proven before fixing:

| probe | round 1 | round 2 |
|---|---|---|
| both pin rows of the ai-native-rag table deleted, header kept | GREEN | RED |
| flagship vite row de-backticked (`\| vite \|`) at `=7.3.5`, sharp row deleted | GREEN | RED |
| flagship Pin cell `=7.3.5`, Provenance quoting `` `=7.3.6` `` | GREEN | RED |

All seventeen probes (P-11's nine, P-13's five, these three): **17/17 RED**, each naming
the file and, for READMEs, the offending cell; every file restored byte-identical;
`b8-9` 14/14.

The text findings: Q-001 still said `web-pwa-ci.yml` runs `npm ci` (it runs `npm install`,
template `:107`) and still called an audit there "the obvious close"; the older `t5-qwik`
CHANGELOG sentence still implied the flagship web surface reached 0.5.1 users, dated
"corrected 2026-09-14" when the finding is from 2026-09-15; plan §0.16 still said 9/9
probes and omitted the README check; and two statements this brick now knows to be false
were still made elsewhere without a pointer — the `t7-flutter-deps-refresh` CHANGELOG
reach claim (Q-007) and the roadmap B.7 row's `harness-rust` claim (Q-005).

## P-15 — regression on the committed tree (T8.7)

On commit `892eff0` (clean tree): `npm run bundle`, then all **82** harness entries parsed
from `forge-ci.yml` — **82/82 PASS**, including `b7-7` 22/0 (its no-uncommitted-template-
edit guard, the only red on the uncommitted tree). `verify.sh` RESULT: PASS;
`constitution-linter.sh` 103 PASS / 0 FAIL, OVERALL PASS; `forge-ci.yml` 421 lines,
unchanged (NFR-T7QD-004).
