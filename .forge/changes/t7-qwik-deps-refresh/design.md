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

The one thing `npm outdated` did **not** report is the one that mattered: two HIGH
`sharp` advisories (`npm audit`: 3 high), visible only to `npm audit`.

## The override, and why not the remedy npm proposes

```
@builder.io/qwik-city  ->  vite-imagetools  ->  sharp <=0.35.4-rc.0
```

`npm audit fix --force` resolves this by installing qwik-city **1.16.1** — four minors
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

1. `overrides.sharp` exists and is ≥ 0.35.4 — else the surface ships two HIGH sharp advisories.
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

---

## Extension (reopened 2026-09-14) — the fix holds on every surface, owned by the standard

### Why the first pass missed two surfaces

It started from the manifest whose pins it was refreshing, found the advisories there,
and fixed them there. The chain lives in `@builder.io/qwik-city`, which all three Forge
Qwik surfaces declare at the same `^1.20.0`. The question that would have caught it —
"which other manifests resolve the same chain?" — is the one `t5-qwik-cli-ignore-dep`
answered for `ignore` by discovering surfaces instead of naming one.

| surface | rendered by | in 0.5.1 | sharp override before |
|---|---|---|---|
| `mobile-pwa-first/2.0.0/web-pwa` | `forge init` (stable since B.9.11) | refused, `candidate` | **yes** (first pass) |
| `ai-native-rag/1.0.0/frontend/web-public` | `forge init` | **stable, scaffoldable** | no |
| `full-stack-monorepo/2.0.0/frontend/web-public` | `migration-plan-2.0.0.yaml` only | not rendered (the 0.5.1 migration copied raw `.tmpl`) | no |

### Where the floor lives

`web-frontend.yaml` already holds one workaround pin exactly like this one — `ignore`,
with its removal trigger and `P30D` cadence, checked on every surface by `b8-9::T-013`.
The sharp floor joins it as `versions.sharp: "0.35.4"` (ADR-T7QD-003). Surfaces write
`"^0.35.4"`: the caret keeps sharp's own patch releases reachable, the floor stays out of
the vulnerable range.

### `b8-9::T-014`

Same discovery as T-013 (`package.json.tmpl` under `.forge/templates` declaring
`@builder.io/qwik`), then `json.load` per surface — never text, because the `_audit`
arrays discuss `sharp` and `vite` in prose.

The standard is read **inside its `versions:` block only**: the file mentions `7.3.5`
and `7.3.6` in comments, and `sharp` would too. The block is cut with `awk` from
`^versions:` to the next top-level key, then the key is matched anchored at two-space
indent. Two anti-vacuity floors: no discovered surface fails; an unreadable pin fails.

Checks per surface: `overrides.sharp == "^" + versions.sharp`;
`devDependencies.vite == "=" + versions.vite`. Each failure names the file and the
consequence.

**Review round 1 (2026-09-15) widened it.** Discovery matches the `"@builder.io/qwik`
prefix, so a `qwik-city`-only manifest is found; a manifest is a surface whether Qwik sits
in `dependencies` or `devDependencies` (the create-qwik starter layout), and a discovered
file that installs neither is reported with a NOTE, not skipped silently. The sibling
`README.md.tmpl` pin table, when present, must carry exactly one `vite` row saying
`` `=<vite>` `` and one `sharp` row saying `` `^<sharp>` ``; a floor fails if no README row
was checked at all. **Round 2 (2026-09-15) made that hold:** the round-1 check found the
table by the rows under test and compared the whole row as text, so deleting both rows of
one table, de-backticking a stale vite row while deleting the sharp row, or quoting the
current pin in the Provenance cell all passed. The table is now parsed into cells, found by its `| Resource | Pin |` header,
and only the Pin cell's first token is compared. `web-pwa`'s README has no pin table and is not held to one.

Mutation probes planned: drop the override on one sibling; set it below the floor; loosen
vite to a caret; revert vite to 7.3.5; delete `versions.sharp` from the standard; move
the sharp literal into a comment only (the region-scoping probe).

### Adopters already on 0.5.1

`forge upgrade` (`bin/forge-upgrade.sh:26,194,291,300`) resolves owned paths from the
framework's own root `.forge/framework-owned-paths.yml` and takes each RIGHT side from the
framework tree. No project manifest is in that set, and the per-archetype
`framework-owned-paths.yml.tmpl` rendered into a project is never read — so no existing
project, of any archetype, receives a template change to its `package.json`. (A first
draft of this section blamed a missing per-archetype entry; review round 1 corrected it,
Q-007.) The CHANGELOG therefore carries the manual fix — one `overrides` block.

### Verification

1. Render `ai-native-rag` with its real wrapper into a scratch directory from the HEAD
   template: `npm install`, `npm audit`, `tsc --noEmit`, `vite build`, `qwik --help`.
2. Same render after the edit: `npm audit --audit-level=high` must exit 0, everything
   else must still pass.
3. `full-stack-monorepo/2.0.0` web-public is migration-only: lockfile resolve +
   `npm audit` on its manifest with placeholders substituted, before and after.
4. `b8-9` RED before GREEN; mutation probes; `b9-2`, `b7-2`, `b7-6`, `b7-7`, `k4`;
   the full CI harness array on the committed tree (`b7-7` fails on uncommitted
   `ai-native-rag` template edits); `verify.sh` + `constitution-linter.sh`.
