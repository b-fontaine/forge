# Evidence — `t7-qwik-deps-refresh`

All probes 2026-09-13, node v26.8.1 / npm 12.0.2.

---

## P-1 — three HIGH advisories on the shipped surface

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

qwik-city 1.16.1 is two minors below the `^1.20.0` that `web-frontend.yaml:45-46` pins,
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
