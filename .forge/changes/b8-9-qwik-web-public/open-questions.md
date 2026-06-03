# Open Questions — b8-9-qwik-web-public

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
Resolutions are made at /forge:design by an INDEPENDENT reviewer + the
maintainer, NOT self-approved. All verify-then-pin items (Qwik package
identities, version strings, Node LTS, npm registry identity) resolved
LIVE at /forge:design and re-verified at /forge:implement.
-->

## Resolution Log (/forge:design, 2026-06-02)

All six questions resolved at /forge:design (maintainer decisions, encoded in
`design.md` ADR-B89-001..007). The author flips them to answered here; an
INDEPENDENT reviewer ratifies before `/forge:plan` (NOT self-approved).
Maintainer decision pending INDEPENDENT reviewer ratification before /forge:plan.

Live evidence collected 2026-06-02T20:53Z (evidence.md P-01..P-15, authoritative).
Final pin re-verify is a LIVE step at `/forge:implement` (ADR-B89-001
final-re-verify clause; b8-coroot lesson).

| Q | Decision | ADR |
|---|----------|-----|
| Q-001 | **(b) Stable 1.x line** — `@builder.io/qwik ^1.20.0` + `@builder.io/qwik-city ^1.20.0` (P-01/P-02). v2 rename (`@qwik.dev/core`/`@qwik.dev/router`) is beta-only (latest = 2.0.0-beta.35, P-03/P-04) — NOT GA. `@qwik.dev/city` does not exist (P-05). Vite pin: `=7.3.5` EXACT — vite 8.0.16 (live latest, P-08) is EXCLUDED by peer range `"vite": ">=5 <8"` (P-06). Node 24 (active LTS, P-10) satisfies `engines.node: ">=18.11"`. v2 recorded as watch-list future-option (`requires: v2-ga`). Final re-verify LIVE at /forge:implement. | ADR-B89-001 |
| Q-002 | **(a) Schema-aligned `2.0.0/frontend/web-public/`** — schema confirmed sub-path under `frontend/` (P-15, ADR-B8-3-004). Plan §4.2 literal path `2.0.0/web-public/` superseded by schema. 10-file skeleton (package.json.tmpl, .nvmrc.tmpl, vite.config.ts.tmpl, tsconfig.json.tmpl, qwik.env.d.ts.tmpl, src/entry.ssr.tsx.tmpl, src/root.tsx.tmpl, src/routes/index.tsx.tmpl, src/lib/connect-client.ts.tmpl, README.md.tmpl) — ≤ 15 budget with 5 slots remaining. | ADR-B89-002 |
| Q-003 | **(a) `web-frontend.yaml`** (role-named) — framework-agnostic, mirrors gateway.yaml/identity.yaml convention, survives Qwik→SvelteKit pivot. `@connectrpc/connect ^2.0.0` + `@connectrpc/connect-web ^2.0.0` runtime (transport.yaml pinned facts, P-12). API shapes (createClient, createConnectTransport) verified at implement via Context7 — NOT fabricated at design (Article III.4). | ADR-B89-003, ADR-B89-005 |
| Q-004 | **(a) Re-point the 2.0.0 manifest es out-path** — new out-path: `../../frontend/web-public/src/lib/generated/connect`. b8-6.test.sh coupling check (P-14): T-003 greps plugin NAME sentinels only, does NOT grep the `out:` value — re-point is safe. 1.0.0 manifest byte-frozen (NFR-B89-002). Bump-note in 2.0.0 manifest header. b8-9 harness T-011 runs b8-6 exit-code coupling guard. | ADR-B89-004 |
| Q-005 | **(a) Node 24 / npm** — Node v24 active LTS (P-10, 2026-06-02); satisfies Qwik engines `>=18.11`. Official starter ships `.npmrc` → npm (P-11). `.nvmrc.tmpl` content: `24`. Zero-new-convention lean. | ADR-B89-006 |
| Q-006 | **(a) Zod DEFERRED** — AT:612 is aspirational (not a binding B.8.9 deliverable). Protobuf-ES v2 generated types sufficient for a minimal unary Connect call skeleton. README note cites AT:612 + ADR-B89-003 deferral: "revisit at B.9.2 or next requiring brick." | ADR-B89-003 |

---

## Q-001: Qwik line + package identities (npm registry; 1.x vs 2.x; @builder.io vs @qwik.dev)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B89-001 seed), `specs.md`
  FR-B89-002/008/020/021/022/023/043
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-9 specify pass)

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision**: **(b) Stable 1.x line** — `@builder.io/qwik ^1.20.0` +
  `@builder.io/qwik-city ^1.20.0`.
  Evidence (all from live npm registry queries 2026-06-02T20:53Z):
  1. `@builder.io/qwik` dist-tags `latest = 1.20.0` (P-01). Stable 1.x line confirmed.
  2. `@builder.io/qwik-city` dist-tags `latest = 1.20.0` (P-02). Co-released.
  3. `@qwik.dev/core` dist-tags `latest = 2.0.0-beta.35` (P-03) — beta-only, NOT GA.
  4. `@qwik.dev/router` dist-tags `latest = 2.0.0-beta.35` (P-04) — same beta line.
  5. `@qwik.dev/city` does NOT exist on npm (P-05).
  6. `vite` peer range: `">=5 <8"` (P-06/P-07). vite live-latest 8.0.16 (P-08) EXCLUDED.
     Pin: `vite =7.3.5` (max stable 7.x, P-09).
  7. Node 24 active LTS (P-10) satisfies `engines.node: ">=16.8.0 <18.0.0 || >=18.11"`.
  The v2 `@qwik.dev/*` family is recorded as a **watch-list future-option** in
  `web-frontend.yaml` (`requires: v2-ga`; B.8.O DBOS-watch precedent). The Vite-8
  excluded trap is recorded explicitly in the standard's versions map (comment) and
  README pitfall note.
  Carry items at implement: re-query npm dist-tags for all three packages before writing
  any template pin; record new provenance if changed.
- **Rationale**: (ADR-B89-001; evidence.md P-01..P-09, P-10.)

---

## Q-002: Subtree location + skeleton file list

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B89-002 seed), `specs.md`
  FR-B89-001/002/010/030
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-9 specify pass)

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision (Q-002a)**: **(a) Schema-aligned: `2.0.0/frontend/web-public/`**.
  Evidence: `2.0.0.yaml` `layers.frontend.surfaces[web-public]` has `path: web-public/`
  under the `frontend` layer (P-15). ADR-B8-3-004 + FR-B8-3-021 mandate surfaces as
  sub-paths under `frontend/`. Plan §4.2 `2.0.0/web-public/` superseded by the ratified
  schema. FR-GL-001 triple preserved (no new top-level layer).
- **Decision (Q-002b)**: 10-file skeleton (design.md ADR-B89-002 file table):
  `package.json.tmpl`, `.nvmrc.tmpl`, `vite.config.ts.tmpl`, `tsconfig.json.tmpl`,
  `qwik.env.d.ts.tmpl`, `src/entry.ssr.tsx.tmpl`, `src/root.tsx.tmpl`,
  `src/routes/index.tsx.tmpl`, `src/lib/connect-client.ts.tmpl`, `README.md.tmpl`.
  ≤ 15 budget (NFR-B89-012) satisfied with 5 slots to spare. Official starter shape (P-11)
  informed the selection; eslint/css/public assets deferred as adopter concerns.
- **Rationale**: (ADR-B89-002; evidence.md P-11, P-15.)

---

## Q-003: Owning standard name + 2.0.0.yaml component-SET entry vs comment-only

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B89-005/007 seed), `specs.md`
  FR-B89-040/060/061/062
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-9 specify pass)

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision (Q-003a — standard name)**: **(a) `web-frontend.yaml`** — role-named,
  framework-agnostic, mirrors gateway.yaml/identity.yaml/persistence.yaml convention.
  Survives a hypothetical Qwik→SvelteKit pivot without rename. ADR-005 names SvelteKit
  as the alternative — the standard name must outlive the framework choice.
- **Decision (Q-003b — annotation shape)**: **(a) Comment-only** on the `web-public`
  surface entry and migration delta in `2.0.0.yaml`. Analysis: `web-public` is in
  `layers.frontend.surfaces[]`, NOT in `components:` (where envoy-gateway, connect-rpc,
  zitadel live). Adding a component-SET entry for a surface would be architecturally
  incorrect and risks b8-3 T-012 if misconfigured. Comment-only is safest and consistent
  with the surface-level modeling.
  b8-3 safety: YAML comments transparent to `yaml.safe_load`; T-012/T-015 unaffected.
- **Rationale**: (ADR-B89-005; ADR-B89-007; evidence.md P-14.)

---

## Q-004: TS codegen out-path — re-point 2.0.0 manifest vs document import path

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B89-004 seed), `specs.md`
  FR-B89-030/031/032/033
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-9 specify pass)

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision**: **(a) Re-point the 2.0.0 manifest es out-path** to
  `../../frontend/web-public/src/lib/generated/connect`.
  Critical coupling check (P-14, full read of b8-6.test.sh):
  - T-003 greps plugin NAME sentinels (`bufbuild/es`, etc.) — does NOT grep `out:` path.
  - No other b8-6 test pins the string `../../frontend/lib/generated/connect/ts`.
  - Re-pointing the 2.0.0 manifest out-path does NOT break b8-6 (confirmed by full read).
  The 1.0.0 manifest is byte-frozen (B.8.2 / NFR-B89-002). Bump-note added to 2.0.0
  manifest header (FR-B89-032). b8-9 harness T-011 runs b8-6 exit-code coupling guard
  for ongoing safety.
- **Rationale**: (ADR-B89-004; evidence.md P-13, P-14.)

---

## Q-005: Node LTS pin + package manager

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B89-006 seed), `specs.md`
  FR-B89-050/051/052
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-9 specify pass)

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision (Q-005a — Node version)**: **Node 24** (`.nvmrc.tmpl` content: `24`).
  Evidence: Node v24 is Active LTS at 2026-06-02 (P-10: Active LTS since 2025-10-28,
  maintenance 2026-10-20, EOL 2028-04-30). Node v22 is already in maintenance mode.
  v24 satisfies Qwik 1.20.0 `engines.node: ">=16.8.0 <18.0.0 || >=18.11"` (24 ≥ 18.11).
- **Decision (Q-005b — package manager)**: **npm**. Evidence: the official Qwik base
  starter ships `.npmrc` (P-11) — indicating npm as the default. No `packageManager`
  field for pnpm/bun in the base starter. Zero-new-convention lean; consistent with
  Forge tooling defaults.
- **Rationale**: (ADR-B89-006; evidence.md P-10, P-11.)

---

## Q-006: Zod schemas — include in skeleton or defer?

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B89-003 seed), `specs.md` FR-B89-025/075
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-9 specify pass)

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision**: **(a) Defer Zod** — lean confirmed. AT:612 is aspirational at B.8.9,
  not a binding deliverable for this brick. Protobuf-ES v2 generates TypeScript types
  directly from `.proto` files — sufficient for the minimal unary Connect call example.
  Including Zod would require: (1) live-resolving a zod version pin (additional verify-then-pin
  obligation); (2) fabricating a Zod schema usage pattern without verified Connect-ES + Zod
  integration docs (Article III.4 risk). The smallest viable skeleton does not need Zod.
  `README.md.tmpl` carries the explicit deferral note: "Connect-ES client + Zod schemas —
  deferred per ADR-B89-003 (protobuf-es types may suffice for the skeleton; revisit at
  B.9.2 or the next brick requiring client-side validation; AT:612 reference recorded)."
- **Rationale**: (ADR-B89-003; Article III.4 anti-fabrication constraint.)
