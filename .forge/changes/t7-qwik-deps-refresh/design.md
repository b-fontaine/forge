# Design — `t7-qwik-deps-refresh`

## `npm outdated` is a report, not an instruction

Four packages were reported behind. Three of the four suggestions would have been
regressions, and separating them is most of the work:

| reported | verdict | why |
|---|---|---|
| `vite` 7.3.6 → 8.3.0 | **rejected** | `@builder.io/qwik` 1.20.0 peers `">=5 <8"`, re-confirmed live from the installed package |
| `@types/node` 22 → 26.5.1 | **redirected** to `^24.13.4` | `.nvmrc` pins node 24; types must describe the runtime, not the registry |
| `typescript` 5.9 → 7.0.2 | accepted | `tsc --noEmit` clean on the real surface |
| `vite-tsconfig-paths` 4.3.2 → 6.1.1 | accepted | build passes |

The one thing `npm outdated` did **not** report is the one that mattered: three HIGH
advisories, visible only to `npm audit`.

## The override, and why not the remedy npm proposes

```
@builder.io/qwik-city  ->  vite-imagetools  ->  sharp <=0.35.4-rc.0
```

`npm audit fix --force` resolves this by installing qwik-city **1.16.1** — two minors
back, across a breaking change, away from the version `web-frontend.yaml:45-46` pins.
That trades a known CVE for an unevaluated regression *and* a standard violation.

sharp 0.35.4 is the first release outside the vulnerable range and is compatible with
what vite-imagetools asks for, so `overrides` lifts the floor and nothing else moves.
The manifest records when the override becomes removable, so it does not outlive its
cause.

## The guard reads parsed JSON

T-037 asserts on `json.load`, never on text. The manifest's `_audit` block now discusses
`sharp`, `vite`, `@types/node`, `ignore` and the version numbers of each — a textual
grep would match the prose explaining the constraint and report the explanation as the
assertion. That is the T-013 trap this repository has paid for six times, and the fix
each time is to assert on structure.

Four constraints, each with its own failure message naming the consequence:

1. `overrides.sharp` exists and is ≥ 0.35.4 — else the surface ships 3 HIGH advisories.
2. `vite` is an **exact** pin and below 8 — a caret would let npm resolve 8.x, which
   qwik's peers exclude.
3. `@types/node`'s major equals `.nvmrc`'s — a drift is otherwise silent.
4. `ignore` is present — without it every `qwik` subcommand dies MODULE_NOT_FOUND.

Plus an anti-vacuity floor, so a broken parse fails rather than passing over an empty
dict.

## Verification

`npm install` → `npm audit` → `tsc --noEmit` → `qwik build`, on a surface rendered from
the **updated template**, not on the hand-edited probe used to find the answers. The
probe establishes what to write; the render proves what was written.
