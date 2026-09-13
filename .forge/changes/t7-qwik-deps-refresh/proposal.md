# Proposal — `t7-qwik-deps-refresh`

The symmetric half of `t7-flutter-deps-refresh`, whose Q-003 recorded that
`web-pwa/package.json` had become framework-owned without its versions being verified.

## What the resolve found, in order of importance

**Three HIGH advisories on the shipped surface.** `npm audit` on a freshly rendered
`web-pwa/`:

```
@builder.io/qwik-city -> vite-imagetools -> sharp <=0.35.4-rc.0
  libvips  CVE-2026-33327 / 33328 / 35590 / 35591
  libheif  GHSA-g89c-p67h-r497 / GHSA-2jg2-4ch7-h545
3 high severity vulnerabilities
```

`npm audit fix --force` would have **downgraded** `@builder.io/qwik-city` to 1.16.1 — a
breaking change, away from the line `web-frontend.yaml` pins. sharp 0.35.4 is the first
release outside the vulnerable range, so an `overrides` entry lifts the transitive floor
and leaves qwik-city where the standard puts it. Measured after: **0 vulnerabilities**.

**Three stale pins**, all verified by building: `typescript` ^5.4 → **^7.0.2**,
`@types/node` ^22 → **^24.13.4**, `vite-tsconfig-paths` ^4.2.1 → **^6.1.1**.

## Three things `npm outdated` said to change and this brick did not

`npm outdated` is a report, not an instruction. Each of these would have been a
regression:

- **`vite` 7.3.6 → 8.3.0.** `@builder.io/qwik` 1.20.0 peerDependencies is still
  `">=5 <8"`, re-confirmed live. The exact pin stays, and the guard now enforces both
  that it is exact and that it is below 8.
- **`@types/node` 22 → 26.5.1.** `.nvmrc` pins node **24**. "Latest" here would mean the
  types describe a runtime the surface does not run on. Bumped to `^24.13.4` instead —
  current *for the pinned runtime*, which is what up to date means for a types package.
- **the `ignore` devDependency.** Its comment says to delete it once upstream declares
  it. Re-checked live: qwik 1.20.0 is still npm latest and still declares only
  `csstype`/`launch-editor`/`rollup`. It stays.

## Scope

**In:** the three pins, the `sharp` override, the audit notes that land in every
project, and `b9-2::T-037` guarding all four constraints.

**Out:** `.forge/standards/web-frontend.yaml`. It pins `qwik`, `qwik_city` and `vite` —
none of which move — so touching it would mean a version bump for nothing, on a file
whose version other harnesses pin.

## Negative scope

MUST NOT move `vite`, `@builder.io/qwik*` or `oauth4webapi`. MUST NOT drop the `ignore`
workaround. MUST NOT let `npm audit fix --force` anywhere near this manifest.
