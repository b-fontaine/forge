# Evidence — b8-9-qwik-web-public

<!-- Status: designed -->
<!-- Audit: B.8.9 (b8-9-qwik-web-public) — verify-then-pin LIVE evidence collected
     2026-06-02T20:53Z by the main orchestration thread (authoritative).
     Article III.4: all Qwik/Node/Vite version strings in this design
     are sourced from LIVE registry queries; none are fabricated. -->

**Collection timestamp**: 2026-06-02T20:53Z (authoritative; cited in design.md ADRs).
**Re-verify obligation**: ALL pins re-verified LIVE at `/forge:implement` before
writing any template file (b8-coroot lesson; ADR-B89-001 final-re-verify clause).

---

## Provenance Table

| ID | Source URL | Accessed | What it proves |
|----|-----------|----------|----------------|
| P-01 | `https://registry.npmjs.org/@builder.io%2Fqwik` (dist-tags endpoint) | 2026-06-02T20:53Z | `@builder.io/qwik` dist-tags: **latest = 1.20.0**; next = 0.9.0; dev = 1.7.0-dev…. This is the current stable 1.x line. |
| P-02 | `https://registry.npmjs.org/@builder.io%2Fqwik-city` (dist-tags endpoint) | 2026-06-02T20:53Z | `@builder.io/qwik-city` dist-tags: **latest = 1.20.0**. The stable Qwik City router package is on the same 1.20.0 release as the core. |
| P-03 | `https://registry.npmjs.org/@qwik.dev%2Fcore` (dist-tags endpoint) | 2026-06-02T20:53Z | `@qwik.dev/core` dist-tags: **latest = 2.0.0-beta.35** (beta channel); alpha channel present. **v2 rename is STILL IN BETA — not GA.** |
| P-04 | `https://registry.npmjs.org/@qwik.dev%2Frouter` (dist-tags endpoint) | 2026-06-02T20:53Z | `@qwik.dev/router` dist-tags: **latest = 2.0.0-beta.35** — same beta line. The v2 router package is `@qwik.dev/router` (NOT `@qwik.dev/city` which does not exist). |
| P-05 | `https://registry.npmjs.org/@qwik.dev%2Fcity` | 2026-06-02T20:53Z | **Package NOT FOUND on npm.** `@qwik.dev/city` does not exist. The v2 router is `@qwik.dev/router`. |
| P-06 | `https://registry.npmjs.org/@builder.io%2Fqwik/1.20.0` (package metadata) | 2026-06-02T20:53Z | `@builder.io/qwik` 1.20.0 metadata: `engines: { node: ">=16.8.0 <18.0.0 \|\| >=18.11" }`. **peerDependencies: `vite: ">=5 <8"`**. |
| P-07 | `https://registry.npmjs.org/@builder.io%2Fqwik-city/1.20.0` (package metadata) | 2026-06-02T20:53Z | `@builder.io/qwik-city` 1.20.0 metadata: same engines constraint as core. No additional peerDeps. |
| P-08 | `https://registry.npmjs.org/vite` (dist-tags endpoint) | 2026-06-02T20:53Z | vite dist-tags: **latest = 8.0.16**. vite 8 is **EXCLUDED** by Qwik 1.20.0's peer range `"vite: >=5 <8"` — the live-latest Vite is incompatible with the stable Qwik line. |
| P-09 | `https://registry.npmjs.org/vite` (all versions, 7.x series) | 2026-06-02T20:53Z | Previous stable series: vite 6.4.3; max stable 7.x = **7.3.5** (34 stable 7.x releases confirmed). Vite 7.3.5 is the highest vite version satisfying Qwik 1.20.0's peer constraint `>=5 <8`. |
| P-10 | `https://raw.githubusercontent.com/nodejs/Release/main/schedule.json` | 2026-06-02T20:53Z | Node.js active LTS lines at 2026-06-02: **v24** (Active LTS since 2025-10-28; maintenance from 2026-10-20; EOL 2028-04-30) + v22 (already in maintenance since 2025-10-21). v24 is the recommended active LTS. v24 satisfies Qwik 1.20.0's `engines.node: ">=16.8.0 <18.0.0 \|\| >=18.11"` (24 ≥ 18.11). |
| P-11 | `https://api.github.com/repos/QwikDev/qwik/contents/starters/apps/base` | 2026-06-02T20:53Z | Official base starter shape: `package.json`, `vite.config.ts`, `tsconfig.json`, `qwik.env.d.ts`, `eslint.config.js`, `.npmrc`, `public/`, `src/{entry.dev.tsx, entry.preview.tsx, entry.ssr.tsx, global.css}`. Routes and root component come from the qwik-city overlay starter (not the base starter). |
| P-12 | `.forge/standards/transport.yaml` (on-disk, v1.3.0) | 2026-06-02 (B.8.6 verified) | `versions_2_0_0:` JS pins: `"@connectrpc/connect": "^2.0.0"`, `"@connectrpc/connect-web": "^2.0.0"`, `"protoc-gen-es": ">=2.2.0"`. **Authoritative runtime pins — citable without live verification.** |
| P-13 | `.forge/templates/archetypes/full-stack-monorepo/2.0.0/shared/protos/buf.gen.yaml.tmpl` (on-disk) | 2026-06-02 (B.8.6 delivered) | B.8.6 2.0.0 manifest es plugin: `remote: buf.build/bufbuild/es:v2.2.0`, `out: ../../frontend/lib/generated/connect/ts`, `opt: [target=ts, import_extension=js]`. **Current es out-path before B.8.9 re-point.** |
| P-14 | `.forge/scripts/tests/b8-6.test.sh` (on-disk, full read) | 2026-06-02 | b8-6 T-003 asserts plugin remote NAME sentinels (`bufbuild/es`, `connectrpc/go:v1.20.0`, etc.) but does **NOT** grep the `out:` path string. T-005 guards the frozen 1.0.0 manifest, not the 2.0.0 manifest's out-path. **Coupling finding: re-pointing the 2.0.0 es out-path does NOT break b8-6 T-003.** |
| P-15 | `.forge/schemas/full-stack-monorepo/2.0.0.yaml` (on-disk) | 2026-06-02 | `layers.frontend.surfaces[web-public]` present: `path: web-public/`, `stack: qwik`. **Schema-aligned path confirmed: `2.0.0/frontend/web-public/` (sub-path under frontend/, not a new top-level layer).** FR-B8-3-021 triple backend/frontend/infra preserved. |

---

## Findings Summary

### Finding 1 — Qwik stable line: 1.x (`@builder.io/qwik` + `@builder.io/qwik-city`)

The current stable Qwik release is **1.20.0** on the `@builder.io/` namespace (P-01, P-02).
The v2 rename (`@qwik.dev/core`, `@qwik.dev/router`) is **beta-only** (latest dist-tag =
`2.0.0-beta.35` — P-03, P-04). There is no v2 GA release. `@qwik.dev/city` does not exist
(P-05); the v2 router package is `@qwik.dev/router`.

**Decision** (ADR-B89-001): pin `@builder.io/qwik ^1.20.0` + `@builder.io/qwik-city ^1.20.0`.
The `@qwik.dev/*` family is recorded as a **watch-list future-option** (`requires: v2-ga`).
B.8.O precedent (DBOS watch-list) and Constitution §VIII.2 anti-pre-1.0 rationale apply: never
pin a beta when a stable line exists.

---

### Finding 2 — Vite-8 excluded trap (CRITICAL)

Qwik 1.20.0 declares `peerDependencies: { "vite": ">=5 <8" }` (P-06, P-07). The live-latest
vite is **8.0.16** (P-08) — **excluded** by this peer range. Adopters who `npm install` with
the default vite would get a peer conflict or broken build.

**Decision** (ADR-B89-001): pin **`vite =7.3.5`** (the highest stable 7.x version — P-09),
satisfying the `>=5 <8` constraint. This trap is recorded explicitly in the standard
`web-frontend.yaml` versions map and in the README "pitfall" note to prevent adopter confusion.

---

### Finding 3 — Node LTS: v24 (satisfies engines `>=18.11`)

Active LTS at 2026-06-02 is **Node.js v24** (P-10). Qwik 1.20.0 `engines.node:
">=16.8.0 <18.0.0 || >=18.11"` — Node 24 satisfies `>=18.11`. Node v22 is already in
maintenance mode. **`.nvmrc.tmpl` content: `24`.**

---

### Finding 4 — Official starter shape (base + city overlay)

The official Qwik base starter (P-11) contains: `package.json`, `vite.config.ts`,
`tsconfig.json`, `qwik.env.d.ts`, `eslint.config.js`, `.npmrc`, `public/`, and
`src/{entry.dev.tsx, entry.preview.tsx, entry.ssr.tsx, global.css}`. The qwik-city overlay
adds `src/routes/` (index.tsx, layout.tsx) and `src/root.tsx`. The minimal skeleton for
B.8.9 draws from this shape, trimmed to the 10-file budget (ADR-B89-002).

---

### Finding 5 — b8-6.test.sh coupling: es out-path re-point is SAFE (CRITICAL)

Full read of `b8-6.test.sh` (P-14) reveals:
- **T-003** asserts plugin remote NAME sentinels: `neoeinstein-tonic`, `neoeinstein-prost`,
  `protocolbuffers/dart`, `connectrpc/go`, `bufbuild/es`, `connectrpc/dart`,
  and `connectrpc/go:v1.20.0`. It does **not** grep the `out:` path string.
- **T-005** checks the **frozen 1.0.0** manifest (`shared/protos/buf.gen.yaml.tmpl`),
  not the 2.0.0 manifest's out-path.
- No other test in b8-6.test.sh references the string `../../frontend/lib/generated/connect/ts`.

**Coupling finding**: re-pointing the 2.0.0 `buf.gen.yaml.tmpl` es plugin `out:` from
`../../frontend/lib/generated/connect/ts` to `../../frontend/web-public/src/lib/generated/connect`
does **NOT** break b8-6.test.sh (no test pins that path). The b8-9 harness coupling guard
(T-011) still runs b8-6 exit-code to catch any future coupling additions.

---

### Finding 6 — On-disk pinned facts (transport.yaml + buf.gen manifest)

From P-12 and P-13 (on-disk, B.8.6-verified — citable without live re-verify):
- `@connectrpc/connect ^2.0.0` (transport.yaml v1.3.0 `versions_2_0_0`)
- `@connectrpc/connect-web ^2.0.0` (transport.yaml v1.3.0 `versions_2_0_0`)
- `protoc-gen-es >=2.2.0` (transport.yaml v1.3.0 `versions_2_0_0`)
- es plugin: `buf.build/bufbuild/es:v2.2.0`, `target=ts`, `import_extension=js` (2.0.0 manifest)
- Stale naming `protoc-gen-connect-es` is **retired by Connect v2** — correct tool is
  `buf.build/bufbuild/es:v2.2.0`. Documented in ADR-B89-003 to prevent adopter confusion.

---

### Finding 7 — Schema path alignment confirmed

P-15 confirms `layers.frontend.surfaces[web-public]` is `path: web-public/` under the
`frontend` layer — this is a **sub-path under `frontend/`**, not a top-level layer.
The schema-aligned disk path for the B.8.9 subtree is:
`.forge/templates/archetypes/full-stack-monorepo/2.0.0/frontend/web-public/`

The plan's `2.0.0/web-public/` (top-level) is superseded by the schema (ADR-B89-002).
FR-GL-001 triple (backend/frontend/infra) is preserved — no new top-level layer introduced.

---

### Finding 8 — npm package manager (from official starter)

The official Qwik base starter (P-11) contains `.npmrc` — indicating **npm** as the default
package manager for the official scaffold. The `package.json` does not declare a `packageManager`
field for pnpm/bun in the base starter. **Decision** (ADR-B89-006): npm, matching the starter's
posture and the zero-new-convention lean.

---

## Anti-Hallucination Pass (Evidence Phase)

- All version strings in this evidence file are sourced from live queries (P-01..P-15) collected
  2026-06-02T20:53Z. No version is fabricated.
- The Vite-8-excluded trap (Finding 2) is derived from the live peerDependencies field of
  the `@builder.io/qwik` 1.20.0 registry record (P-06) — not a training-data assertion.
- The Node v24 LTS selection (Finding 3) is derived from the live `schedule.json` (P-10).
- The b8-6.test.sh coupling finding (Finding 5) is derived from a full read of the file (P-14),
  not assumed. The exact test functions greping plugin names but not out-paths are cited.
- Connect-ES runtime pins (Finding 6) are on-disk citable facts from transport.yaml v1.3.0
  (B.8.6 verified — re-verification not required for these design-time citations).
- Re-verify obligation: all Qwik/Vite/Node pins re-verified LIVE at `/forge:implement`
  before any template file is written (b8-coroot lesson). If registry facts have changed,
  update pins and record new provenance (P-16+).

---

## Phase 0 — `/forge:implement` LIVE re-verify (2026-06-03T04:54Z, authoritative)

The ADR-B89-001 final-re-verify clause: all Qwik/Vite/Node pins + the Connect-ES v2
and Qwik 1.20.0 API shapes were re-queried LIVE by the main orchestration thread
immediately before any template file was authored. No pin drifted from the design-phase
values (P-01..P-13); the v2 line stays beta-only (no GA). All shapes resolved — no
`[NEEDS CLARIFICATION:]` raised. Tasks T001–T007 satisfied.

| ID | Source | Accessed | What it proves |
|----|--------|----------|----------------|
| P-16 | `@builder.io/qwik` + `@builder.io/qwik-city` dist-tags (npm) | 2026-06-03T04:54Z | Both still `latest = 1.20.0` (P-01/P-02 re-verify — NO drift). Caret pins `^1.20.0` stand. (T001) |
| P-17 | `@qwik.dev/core` dist-tags (npm) | 2026-06-03T04:54Z | Still `latest = 2.0.0-beta.35` — STILL beta, no v2 GA. The v2 line stays watch-list `future-option` (P-03/P-04 re-verify). (T001/T002) |
| P-18 | `@builder.io/qwik@1.20.0` metadata (npm) | 2026-06-03T04:54Z | engines `node: ">=16.8.0 <18.0.0 \|\| >=18.11"`; **peerDependencies `vite: ">=5 <8"`** (P-06 re-verify — NO drift). vite latest = **8.0.16** (EXCLUDED); max stable 7.x = **7.3.5** → exact pin `vite "=7.3.5"` stands. The Vite-8 trap holds. (T003) |
| P-19 | Node.js release schedule | 2026-06-03T04:54Z | Node **v24** still active LTS; satisfies Qwik 1.20.0 engines (24 ≥ 18.11). `.nvmrc` = `24` stands (P-10 re-verify). (T004) |
| P-20 | connect-es v2 README (connectrpc/connect-es) | 2026-06-03T04:54Z | Browser client = `import { createClient } from "@connectrpc/connect"` + transport `import { createConnectTransport } from "@connectrpc/connect-web"` (browser transport — sig `{ baseUrl }`, no httpVersion). Usage: `const client = createClient(GreeterService, createConnectTransport({ baseUrl }))` → `await client.<method>(req)`. Generated descriptors import from protobuf-es v2 output (`*_pb`; Connect v2 retired the separate connect file — single `*_pb` file carries the service descriptor). `@connectrpc/connect` + `@connectrpc/connect-web` latest **2.1.1** (range `^2.0.0` valid). (T005 — populates connect-client.ts.tmpl) |
| P-21 | QwikDev/qwik starters (canonical shapes) | 2026-06-03T04:54Z | `vite.config.ts`: `qwikCity()` + `qwikVite()` + `tsconfigPaths({ root: "." })`. `tsconfig.json`: target ES2020, module ES2022, lib [es2022,DOM,WebWorker,DOM.Iterable], `jsx: react-jsx`, `jsxImportSource: @builder.io/qwik`, moduleResolution Bundler, isolatedModules, noEmit, paths `~/*`. `entry.ssr.tsx`: `renderToStream(<Root />, { ...opts, containerAttributes: { lang, ... } })` from `@builder.io/qwik/server`. `root.tsx`: `QwikCityProvider` + `RouterOutlet` from `@builder.io/qwik-city`. `routes/index.tsx`: `component$(() => ...)` + `export const head: DocumentHead`. Scripts: `dev: vite --mode ssr`, `build: qwik build`, `build.client: vite build`, `build.types: tsc --incremental --noEmit`, `preview`, `qwik`. devDeps include `vite-tsconfig-paths ^4.2.1` (eslint/prettier OMITTED from minimal skeleton). `qwik.env.d.ts`: triple-slash refs to qwik + qwik-city. (T006 — populates the 4 [VERIFY] files) |
| P-22 | `b8-6.test.sh` + `t5.test.sh` re-read (on-disk) | 2026-06-03T04:54Z | b8-6 greps es plugin NAME sentinels only, NOT the `out:` path → re-point safe (P-14 re-verify). `t5.test.sh:257` greps the FROZEN 1.0.0 `.gitignore`, not the 2.0.0 manifest → unaffected by the re-point. (T007) |

**Outcome**: zero drift; zero `[NEEDS CLARIFICATION:]`. All design-phase pins (P-01..P-13)
re-confirmed. Connect-web browser-transport shape (P-20) supersedes the connect-node README
example for the Qwik browser client. Proceeding to Phase 1 (harness RED).
