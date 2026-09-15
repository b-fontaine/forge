# Proposal — `t7-qwik-deps-refresh`

The symmetric half of `t7-flutter-deps-refresh`, whose Q-003 recorded that
`web-pwa/package.json` had become framework-owned without its versions being verified.

## What the resolve found, in order of importance

**Two HIGH `sharp` advisories on the shipped surface** (`npm audit` counts 3 high). `npm audit` on a freshly rendered
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

---

## Scope extension — reopened 2026-09-14, before review

A read-only pre-release audit found that this brick fixed **one of three** Qwik surfaces
while its CHANGELOG entry reads as the fix. The chain is not specific to `web-pwa`: it is
`@builder.io/qwik-city` itself, and every Forge Qwik surface depends on it.

```
ai-native-rag/1.0.0/frontend/web-public/package.json (HEAD template, lockfile resolve)
  @builder.io/qwik-city@1.20.0 -> vite-imagetools@9.0.3 -> sharp@0.34.5
  npm audit: 4 vulnerabilities (1 low, 3 high)  GHSA-f88m-g3jw-g9cj, GHSA-rgj7-g3m4-5g8c
```

And the surface that stayed vulnerable is the one that matters most: `ai-native-rag` is
`stable` / `scaffoldable: true` in HEAD **and in the published `@sdd-forge/cli@0.5.1`**,
whereas `web-pwa` was a refused `candidate` in 0.5.1. The brick patched the surface no
adopter could render and left the one they could.

The brick is still `implemented` and unreviewed, so the gap is extended here rather than
in an eighteenth change: one review, one Security entry (maintainer arbitration
2026-09-14).

**In (extension):**

- `overrides.sharp` on the two sibling templates — `ai-native-rag/1.0.0` (rendered at
  `forge init`) and `full-stack-monorepo/2.0.0` (rendered by the flagship migration plan).
- `vite` `=7.3.5` → `=7.3.6` on the same two templates. `web-frontend.yaml:47` has pinned
  `7.3.6` **exactly** since 2026-07-28; both siblings have been out of the standard since.
- The sharp floor moves into `web-frontend.yaml` (1.2.0 → 1.3.0), with its removal
  trigger, as the `ignore` workaround already is — which reverses this brick's original
  "Out: web-frontend.yaml". The reason it was out ("none of its pins move") stopped
  being true once the fix had to hold on three surfaces.
- `b8-9::T-014`, a discovery guard beside `T-013`: every Qwik template agrees with the
  standard on the sharp override and the exact vite pin. No new harness, so no
  `NFR-CI-002` line.
- The CHANGELOG Security entry names every template surface, says the shipped example is
  still affected, and gives 0.5.1 `ai-native-rag` adopters the manual workaround —
  `forge upgrade` cannot deliver it: it merges only the paths the framework's own root
  `.forge/framework-owned-paths.yml` owns, taken from the framework tree, and no project
  manifest is in that set (Q-007).

**Out (extension):** `examples/forge-rag-example` (it also lacks the `ignore` workaround;
recorded as Q-004, a maintainer question); `typescript` / `@types/node` /
`vite-tsconfig-paths` on the siblings (maintainer arbitration 2026-09-14: sharp and the
standard's vite pin only); the scaffold snapshot tarballs (`de92625` precedent).
