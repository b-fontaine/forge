# Spec: b8-qwik-web-public

<!-- Audit: B.8.9 (b8-9-qwik-web-public) -->
<!-- Source change : `.forge/changes/b8-9-qwik-web-public/` (delta specs.md authoritative). -->

**Namespace** : `FR-B89-*` / `NFR-B89-*` / `ADR-B89-*`.
**Constitution** : v1.1.0, unchanged (no amendment). Article VIII.1 (Kong SHALL)
is **PRESERVED** — additive brick; Kong removal at B.8.14. Article VI (Flutter
architecture mandate) is **UNTOUCHED** — the Qwik surface is additive and outside
Article VI's Flutter mobile/desktop/backoffice scope. This change ships **no
production code** in the running example tree: it authors template files + a new
standard + standard-index entry + buf.gen manifest edit + schema annotation +
harness only.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-Hallucination —
ALL Qwik-specific version numbers, npm package identities, scaffold shapes, and
Node LTS values are verify-then-pin LIVE at `/forge:design` and re-verified at
`/forge:implement`; Q-NNN markers used throughout), IV (delta-based: ADDED FRs
only; new standard gets a birth REVIEW.md row; buf.gen edit additive on the 2.0.0
copy only), V (harness + gates before status flips; full suite before push;
POST-flip re-run), VI (Flutter arch PRESERVED — no Flutter file touched),
VIII.1 (Kong SHALL — in force, PRESERVED), XII (BDFL decisions as ADRs at
`/forge:design`; new standard under 12-month review lifecycle).

## Overview

B.8.9 delivers the **Qwik web-public brick**: a versioned subtree
`2.0.0/frontend/web-public/` (10 files: `package.json.tmpl`, `tsconfig.json.tmpl`,
`vite.config.ts.tmpl`, `qwik.config.ts.tmpl` (via vite), `.nvmrc.tmpl`,
`src/routes/index.tsx.tmpl`, `src/root.tsx.tmpl`,
`src/lib/greeter-client.ts.tmpl`, `src/entry.ssr.tsx.tmpl`,
`README.md.tmpl`) schema-aligned per ADR-B8-3-004 (sub-path under `frontend/`),
pinning `@builder.io/qwik` and `@builder.io/qwik-city ^1.20.0` (stable v1 line —
verify-then-pin LIVE 2026-06-03; `@qwik.dev/*` v2 remains beta-only → watch-list
future-option), `vite =7.3.5` (peer `>=5 <8` excludes live-latest 8.0.16),
`@connectrpc/connect ^2.0.0` and `@connectrpc/connect-web ^2.0.0` (transport.yaml
v1.3.0 pinned facts), Connect-ES v2 client module using `createClient` +
`createConnectTransport` from `@connectrpc/connect` + `@connectrpc/connect-web`,
`.nvmrc` = Node LTS `24` (verify-then-pin LIVE — satisfies `engines.node >=18.11`),
es codegen out-path re-pointed to `frontend/web-public/src/lib/generated/connect`
(ADR-B89-004), NEW standard `web-frontend.yaml` v1.0.0 (default: qwik-city,
alternatives: [sveltekit], first Qwik web-frontend pin source),
`2.0.0.yaml` comment-only delivery annotation (safest vs b8-3 T-012/T-015),
`b8-9.test.sh` 12 L1, full suite 48/48 GREEN, independent review design + final
APPROVE round 1. Zod/OIDC/OTel/PWA/streaming/hosting all deferred.
Archived 2026-06-03.

## GROUND-TRUTH FINDINGS (Article III.4) — this brick INTRODUCES the web-public surface

**Ground truth (re-read 2026-06-02, Article III.4):**

- **The 1.0.0 flagship has no web split at all.** `frontend/` is a single flat
  Flutter app; zero `web-public`/`web-backoffice`/`qwik` matches anywhere on the
  1.0.0 line or B8-BASELINE. The migration delta is honest:
  `from: no-web-public-layer` — this brick **introduces** the surface, it migrates
  nothing.
- **Path tension — schema governs.** Plan §4.2 says
  `templates/full-stack-monorepo/2.0.0/web-public/` (top-level), but the ratified
  ADR-B8-3-004 models surfaces as **sub-paths under `frontend/`**
  (FR-B8-3-021: no new top-level layer; FR-GL-001 validator triple preserved).
  The on-disk subtree location follows the schema: `2.0.0/frontend/web-public/`
  (schema-aligned lean, recorded in ADR-B89-002). Plan top-level path superseded.
- **No Qwik version or package name existed anywhere** in the plan or
  ARCHITECTURE-TARGET — only "Qwik City", performance figures, and a benchmarks
  citation. The Qwik line (1.x vs 2.x), npm package identities, Vite coupling,
  engines field, and scaffold shape were **verify-then-pin LIVE** at design
  (Q-001 → ADR-B89-001). **RESOLVED:** stable v1 line uses `@builder.io/qwik*`;
  `@qwik.dev/*` v2 beta-only → watch-list.
- **Stale codegen naming in plan/AT**: both still cite `protoc-gen-connect-es`,
  which Connect v2 retired. The B.8.6 2.0.0 manifest reality is
  `buf.build/bufbuild/es:v2.2.0` (`target=ts`, `import_extension=js`) with
  runtime `@connectrpc/connect ^2.0.0` (transport.yaml v1.3.0 `versions_2_0_0`).
  The Qwik client consumes THAT output (same naming-drift class as B.8.6/B.8.7).
  FR-B89-024 documents the retirement; no template file references `protoc-gen-connect-es`.
- **TS codegen out-path was not yet surface-aligned**: the B.8.6 2.0.0 manifest es
  plugin emitted to `../../frontend/lib/generated/connect/ts` (the 1.0.0 single-app
  path). B.8.9 re-points the 2.0.0 manifest es output to the web-public surface
  sub-path `frontend/web-public/src/lib/generated/connect` (ADR-B89-004). Bump-note
  added to the 2.0.0 manifest header. 1.0.0 manifest byte-unchanged.
- **No owning web standard existed**: `grep -rn qwik .forge/standards/` → matrix/
  lifecycle prose only. The 2.0.0.yaml `web-public` surface carried no `standard:`
  field. This brick creates the first Qwik web-frontend pin source:
  `web-frontend.yaml` v1.0.0 (Q-003 → ADR-B89-005, name confirmed at design).
- **No Node toolchain pin existed**: no `.nvmrc` or `.node-version` in archetype.
  A Node pin convention is net-new. Resolved: `.nvmrc.tmpl` = `24` (active LTS,
  verify-then-pin LIVE, satisfies `engines.node >=18.11`; ADR-B89-006).
- **Iris-Web (K.4, Qwik standards owner) is a T7 agent — not yet shipped.**
  Janus arbitrates the two surfaces until K.4. The standard created here is the
  bridge.
- **Compliance**: Qwik client binaries are compliant at all tiers. Hosting rows
  (Cloudflare/Vercel/OVH) are B.9.7 territory — out of scope here.

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4 (Module B.8), §4.2 B.8.9 (GROUND-TRUTH NOTE: path tension resolved by schema — plan top-level `2.0.0/web-public/` superseded by ADR-B89-002 schema-aligned `2.0.0/frontend/web-public/`; no Qwik versions in plan/AT; protoc-gen-connect-es retired by B.8.6) |
| **Candidate schema (observed)** | `.forge/schemas/full-stack-monorepo/2.0.0.yaml` — `layers.frontend.surfaces[web-public]` { path: web-public/, stack: qwik, note: new in 2.0.0 (B.8.9) }; `migration_deltas[no-web-public-layer → qwik-web-public]` { brick: B.8.9, strategy: additive-first }. No `standard:` field on the web-public surface (b8-3 T-011 coupling — comment-only annotation is safest). |
| **transport.yaml v1.3.0 (observed)** | `versions_2_0_0:` JS pins: `"@connectrpc/connect": "^2.0.0"`, `"@connectrpc/connect-web": "^2.0.0"`, `"protoc-gen-es": ">=2.2.0"`. These are the AUTHORITATIVE runtime pins the Qwik client respects — pinned facts, citable without live verification. |
| **buf.gen.yaml.tmpl 2.0.0 (observed)** | `.forge/templates/archetypes/full-stack-monorepo/2.0.0/shared/protos/buf.gen.yaml.tmpl` — es plugin: `remote: buf.build/bufbuild/es:v2.2.0`, out-path re-pointed (ADR-B89-004) from `../../frontend/lib/generated/connect/ts` → `../../frontend/web-public/src/lib/generated/connect`, `opt: [target=ts, import_extension=js]`. 1.0.0 manifest frozen (NFR-B89-001). |
| **web-frontend.yaml (created)** | `.forge/standards/web-frontend.yaml` v1.0.0 — `default: qwik-city`, `alternatives: [sveltekit]`, `versions:` map (`@builder.io/qwik: "^1.20.0"`, `@builder.io/qwik-city: "^1.20.0"`, `vite: "=7.3.5"`, `@connectrpc/connect: "^2.0.0"`, `@connectrpc/connect-web: "^2.0.0"`; `@qwik.dev/*: "watch-list (beta-only)"`), `pin_review_cadence: { qwik: P30D }`. J.7-valid frontmatter, `last_reviewed: 2026-06-03`, `expires_at: 2027-06-03`. |
| **identity.yaml + gateway.yaml (observed)** | Frontmatter model for the new web-frontend standard: `version`, `last_reviewed`, `expires_at`, `exception_constitutional: false`, `linter_rule: null`, `enforcement: ci_blocking: false`, `versions:` map + `pin_review_cadence:` ISO 8601 (gateway.yaml precedent). |
| **B.8.3 invariants (binding)** | 1.0.0 frozen (B.8.2 sha256 guard); candidate `scaffoldable: false` until B.8.14; pins live in standards not in schema (ADR-B8-3-002); no forbidden inline-pin keys `{version, pin, image}` (b8-3 T-012); no bare `^\d+\.\d+` scalars (b8-3 T-015); every `standard:` ref resolves (b8-3 T-011). |
| **b8-7 harness shape (observed)** | `b8-7.test.sh` — 12 L1 tests, `--level` flag, `source _helpers.sh`, `run_test`/`print_summary`, exit-code-only coupling guard for b8-3+b8-3b, CHANGELOG whole-file grep anchored on change name. |
| **b8-6.test.sh coupling** | Asserts `buf.gen.yaml.tmpl` content (es plugin out-path). ADR-B89-004 re-points the 2.0.0 manifest; b8-6 assertions updated to reflect new out-path; coupling guard in b8-9 harness. |
| **FR-B8-3-020/021/022 (binding)** | Surfaces invariants: sub-paths under frontend/ only, no new top-level layer, FR-GL-001 validator triple backend/frontend/infra preserved. |
| **Release target** | v0.4.0-rc.11 |
| **Dependencies** | B.8.3 (surfaces modeling, FR-GL-001), B.8.6 (Connect TS codegen + JS pins), B.8.4 (subtree + standard conventions, Envoy path) |

---

## ADDED Requirements

### Functional Requirements

#### Group 1 — web-public subtree (FR-B89-001 → 010)

##### FR-B89-001 — 2.0.0 web-public subtree created at the schema-aligned location
The brick MUST create the versioned web-public subtree following the `N.N.N/`
versioned-subtree convention. The exact disk path is schema-aligned:
`2.0.0/frontend/web-public/` (sub-path under `frontend/`, per ADR-B8-3-004
/ FR-B8-3-021). This resolves Q-002 → ADR-B89-002; the plan's top-level
`2.0.0/web-public/` path is superseded by the schema. The FR-GL-001
validator triple (backend/frontend/infra) is preserved unchanged.
The subtree is exempt from repo-wide scans that skip `N.N.N/` directories.

##### FR-B89-002 — Minimal Qwik City skeleton; file-count budget ≤ 15 template files
The subtree contains a minimal, hand-curated Qwik City skeleton of **10 template
files** (well within the ≤15 budget):
1. `package.json.tmpl` — Connect-ES runtime deps + Qwik/Vite build deps
2. `tsconfig.json.tmpl` — TypeScript configuration
3. `vite.config.ts.tmpl` — Vite + qwikVite() plugin config
4. `.nvmrc.tmpl` — Node LTS pin (`24`)
5. `src/routes/index.tsx.tmpl` — root route (Qwik City entry)
6. `src/root.tsx.tmpl` — app root component
7. `src/lib/greeter-client.ts.tmpl` — Connect-ES client module
8. `src/entry.ssr.tsx.tmpl` — SSR entry point
9. `src/lib/generated/connect/.gitkeep.tmpl` — codegen output placeholder
10. `README.md.tmpl` — documentation (§G7)

The subtree is NOT a full vendored `create-qwik` dump. All Qwik and Connect API
symbols in template files are verified live at design (ADR-B89-001 — no fabricated
symbols).

##### FR-B89-003 — Audit comment headers on all template files
Every template file in the web-public subtree carries a top-of-file audit
comment `# <!-- Audit: B.8.9 (b8-9-qwik-web-public) -->` (or
`<!-- Audit: B.8.9 (b8-9-qwik-web-public) -->` for HTML/Markdown/TSX files)
and a `# Standard: .forge/standards/web-frontend.yaml` reference.
Mirrors the B.8.4 / B.8.7 audit-header invariant.

##### FR-B89-004 — Template variable conventions match sibling subtrees
All template variables in the web-public subtree use the `<variable-name>`
angle-bracket convention established by B.8.4 / B.8.5 / B.8.7 (e.g.,
`<project-name>`, `<namespace>`). No deviating variable syntax is introduced.
Template vars match the set used by sibling 2.0.0 subtrees where applicable.

##### FR-B89-005 — Subtree visible on disk; scaffoldable: false preserved
The `2.0.0/frontend/web-public/` subtree is an on-disk asset for the 2.0.0
candidate. The candidate schema remains `scaffoldable: false` until B.8.14
(ADR-B8-3-003/005). `forge init` still emits the flat 1.0.0 template tree
with no web-public surface. The README carries a "Status" block:
`candidate, scaffoldable: false until B.8.14`.

##### FR-B89-006 — 1.0.0 template assets byte-unchanged
No file under `.forge/templates/archetypes/full-stack-monorepo/` outside the
`2.0.0/` versioned path is modified by this brick (B.8.2 maintenance freeze).
The 1.0.0 `schema.yaml`, `docker-compose.dev.yml.tmpl`, `.env.example.tmpl`,
and all 1.0.0 template files are byte-identical before and after.

##### FR-B89-007 — web-backoffice Flutter surface explicitly unchanged
No file in any `web-backoffice/` subtree is touched by this brick. The 1.0.0
Flutter app covers the backoffice; any backoffice move is B.8.10/B.8.14
territory. The README states this posture explicitly.

##### FR-B89-008 — No fabricated Qwik API symbols in template files
Template files contain only Qwik and Connect API usage patterns verified live
at design (ADR-B89-001). Import paths, hook names, component patterns, and
transport factory names are all resolved from live npm registry and documentation
evidence (Q-001). Any symbol not verified is an Article III.4 violation.
**DELIVERED:** `createClient` + `createConnectTransport` from `@connectrpc/connect`
+ `@connectrpc/connect-web` verified live 2026-06-03.

##### FR-B89-009 — README.md.tmpl present and follows B.8.4/B.8.7 conventions
The subtree contains `README.md.tmpl` documenting: (a) the delivery model and
standard reference (`web-frontend.yaml`), (b) the Janus arbitration posture
(§G7), (c) the Envoy Connect/HTTP path (§G7), (d) web-backoffice unchanged
posture (§G7), (e) explicit scope-outs (§G7), (f) Status block
(`candidate, scaffoldable: false until B.8.14`), (g) Node toolchain setup
guidance (§G5). The README carries an audit comment
`<!-- Audit: B.8.9 (b8-9-qwik-web-public) -->`.

##### FR-B89-010 — Subtree under frontend/ preserves FR-GL-001 triple
The web-public subtree does NOT introduce a new top-level layer entry in
`2.0.0.yaml` (FR-B8-3-020/021 — the minimum layer triple backend/frontend/infra
is preserved unchanged). The subtree is a sub-path under the existing `frontend/`
layer. The FR-GL-001 validator check remains unaffected.

---

#### Group 2 — Connect-ES client wiring (FR-B89-020 → 025)

##### FR-B89-020 — Connect-ES client module present and imports generated descriptors
The subtree contains `src/lib/greeter-client.ts.tmpl` — a Connect-ES client
module. The module imports service descriptors from the B.8.6 TS codegen output
path as resolved by ADR-B89-004 (Q-004): `./generated/connect/<service>_connect`
(relative to the web-public src tree, pointing to the re-pointed buf.gen output).
No descriptor generation logic is re-implemented in the Qwik subtree.

##### FR-B89-021 — Runtime deps respect transport.yaml versions_2_0_0 JS pins
The `package.json.tmpl` declares `@connectrpc/connect` and
`@connectrpc/connect-web` with constraints satisfying the transport.yaml v1.3.0
`versions_2_0_0` pins:
- `@connectrpc/connect`: `^2.0.0`
- `@connectrpc/connect-web`: `^2.0.0`
These are **pinned facts** (transport.yaml v1.3.0 — citable without live
verification). No weaker or diverging constraint is permitted.

##### FR-B89-022 — Demonstrates at least one unary Connect call pattern
The Connect-ES client module demonstrates one unary RPC call against the demo
Greeter service descriptors (the same service used by B.8.6 examples). The API
shape uses `createClient` + `createConnectTransport` (verified live 2026-06-03,
ADR-B89-001): `createConnectTransport({ baseUrl })` from `@connectrpc/connect-web`,
`createClient(GreeterService, transport)` from `@connectrpc/connect`. This is the
Connect-ES v2 idiomatic pattern (not the v0.x `createPromiseClient` API).

##### FR-B89-023 — No fabricated API symbols; shapes verified live at design
The client module does NOT use Qwik hooks, Connect transport factory names, or
import paths that were not verified live at design (Q-001 / ADR-B89-001).
The verify-then-pin obligation applies equally at implement phase (re-verified
2026-06-03). **DELIVERED:** `createClient` / `createConnectTransport` confirmed
as the v2 API surface.

##### FR-B89-024 — protoc-gen-connect-es naming retired; stale reference documented
No template file or README references `protoc-gen-connect-es` as the current
codegen tool. The correct tool per B.8.6 is `buf.build/bufbuild/es:v2.2.0`
(`@bufbuild/protoc-gen-es >=2.2.0`). The README notes the naming drift
(ADR-B89-003) to prevent adopter confusion.

##### FR-B89-025 — Zod deferred; README note present (ADR-B89-003)
Zod is **deferred** (ADR-B89-003 — protobuf-es types suffice for the skeleton;
AT:612 reference recorded). `package.json.tmpl` does NOT declare a `zod`
dependency. `README.md.tmpl` includes an explicit note: "Connect-ES client +
Zod schemas — deferred per ADR-B89-003 (protobuf-es types may suffice for the
skeleton; revisit at B.9.2)."

---

#### Group 3 — buf.gen 2.0.0 es out-path (FR-B89-030 → 033)

##### FR-B89-030 — 2.0.0 buf.gen manifest es out-path re-pointed per ADR-B89-004
The 2.0.0 `buf.gen.yaml.tmpl` es plugin `out:` value is re-pointed from
`../../frontend/lib/generated/connect/ts` to
`../../frontend/web-public/src/lib/generated/connect`
(additive edit; the 2.0.0 manifest is a B.8.6-owned standalone copy designed
for exactly this evolution). The 1.0.0 manifest is untouched (NFR-B89-001).

##### FR-B89-031 — 1.0.0 buf.gen manifest byte-unchanged
The frozen 1.0.0 `buf.gen.yaml.tmpl` at
`.forge/templates/archetypes/full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl`
is byte-unchanged by this brick (B.8.2 / NFR-B89-001). Only the 2.0.0 copy
at `2.0.0/shared/protos/buf.gen.yaml.tmpl` is edited.

##### FR-B89-032 — Manifest header carries a bump-note for the out-path change
The 2.0.0 manifest header comment receives a bump-note:
```
# B.8.9 delta: es plugin out-path re-pointed to the web-public surface (ADR-B89-004).
```

##### FR-B89-033 — b8-6.test.sh stays GREEN after the manifest edit
After the edit to the 2.0.0 `buf.gen.yaml.tmpl`, the sibling `b8-6.test.sh
--level 1` stays GREEN. The b8-9 harness includes an exit-code coupling guard
for b8-6 (FR-B89-087). The b8-6 harness assertions that tested the old out-path
are updated to reflect the new path (additive change to b8-6 assertions, confirmed
by the coupling guard in b8-9).

---

#### Group 4 — NEW standard web-frontend.yaml (FR-B89-040 → 047)

##### FR-B89-040 — web-frontend.yaml created (ADR-B89-005)
`.forge/standards/web-frontend.yaml` is created at v1.0.0 (name confirmed by
ADR-B89-005 lean: role-named like `gateway.yaml`/`identity.yaml` — survives a
hypothetical Qwik→SvelteKit pivot without rename).

##### FR-B89-041 — J.7-valid frontmatter
The standard carries J.7-valid frontmatter matching the `gateway.yaml`/`identity.yaml`
model:
- `version: "1.0.0"` (birth version)
- `last_reviewed: 2026-06-03`
- `expires_at: 2027-06-03` (dated 12-month expiry — web framework pins drift;
  NOT `never`; `exception_constitutional: false` per FR-J7-020 coupling)
- `linter_rule: null` (advisory standard; no constitution-linter.sh anchor)
- `enforcement: ci_blocking: false, pre_commit_hook: false` (documentation-only
  at birth; enforcement is Iris-Web / K.4 territory)

##### FR-B89-042 — default/alternatives per ADR-B89-005
The standard declares:
- `default: qwik-city` (ratifying ADR-005 ARCHITECTURE-TARGET.md:365-374)
- `alternatives: [sveltekit]` (per ADR-005 rationale)
- `rationale:` citing ADR-005 + SEO/resumability/LCP/TTI rationale
  (ARCHITECTURE-TARGET.md citation — no fabricated benchmark figures)

##### FR-B89-043 — First versions: map (live-resolved at design, NOT fabricated)
The standard contains a `versions:` map as the first Qwik web-frontend pin
source. **RESOLVED at /forge:design (ADR-B89-001, re-verified 2026-06-03):**
- `"@builder.io/qwik": "^1.20.0"` (stable v1 line)
- `"@builder.io/qwik-city": "^1.20.0"` (stable v1 line)
- `"vite": "=7.3.5"` (peer constraint `>=5 <8` excludes live-latest 8.0.16)
- `"@connectrpc/connect": "^2.0.0"` (transport.yaml v1.3.0 pinned fact)
- `"@connectrpc/connect-web": "^2.0.0"` (transport.yaml v1.3.0 pinned fact)
- `"@qwik.dev/*": "watch-list (beta-only)"` — future-option; `requires: v2-ga`

##### FR-B89-044 — pin_review_cadence: field added, ISO 8601
The standard adds `pin_review_cadence:` with entries for each Qwik package.
Cadence `P30D` for framework packages (active upstream velocity).
ISO 8601 duration format (gateway.yaml / identity.yaml precedent).

##### FR-B89-045 — REVIEW.md ledger receives a B.8.9 birth row
`.forge/standards/REVIEW.md` receives an append-only `Created` entry for
`web-frontend.yaml v1.0.0`, dated 2026-06-03, with a one-line description
(birth: first web-frontend pin source — Qwik City default, ADR-005 ratification).
Mirrors the B.8.4 `gateway.yaml` and B.8.7 `identity.yaml` REVIEW.md precedents
(Article XII append-only ledger).

##### FR-B89-046 — web-frontend.yaml passes bin/validate-standards-yaml.sh
After creation, `bin/validate-standards-yaml.sh` (J.7) passes in both
single-file mode and directory mode. The MANDATORY `REVIEW.md` row for
`web-frontend.yaml | 1.0.0` (FR-J7-023 coupling) is satisfied by FR-B89-045.

##### FR-B89-047 — index.yml entry added with correct triggers
`.forge/standards/index.yml` receives an entry for `web-frontend.yaml`
with triggers including at minimum: `qwik`, `web-public`, `connect-es`,
`web frontend`, `qwik-city`, `sveltekit`. The entry follows the existing
index.yml structure (trigger list + file reference).

---

#### Group 5 — Node toolchain pin (FR-B89-050 → 052)

##### FR-B89-050 — Node version-file convention in the subtree
The web-public subtree contains `.nvmrc.tmpl` (ADR-B89-006). The convention
mirrors the Flutter `flutter-version-file` pattern: a single-line file consumed
by `setup-node` (GitHub Actions) or `nvm`/`fnm` at setup time. The value is
a literal pin (not a template variable — the LTS version is a fixed fact for
the skeleton).

##### FR-B89-051 — Node LTS value live-resolved at design, NOT fabricated
**RESOLVED at /forge:design (ADR-B89-006, re-verified 2026-06-03):** Active Node
LTS is `24` (`.nvmrc` = `24`), sourced from the official Node.js release schedule
(nodejs.org/en/about/previous-releases). Node 24 is the current active LTS and
satisfies Qwik's `engines.node >=18.11` constraint.

##### FR-B89-052 — README setup guidance mirrors flutter-version-file pattern
The `README.md.tmpl` includes a "Node toolchain setup" section documenting:
(a) `.nvmrc` convention (nvm/fnm), (b) `nvm use` / `fnm use` / `setup-node`
usage pattern, (c) note that the value (`24`) is the active LTS satisfying
Qwik's engine requirements.

---

#### Group 6 — 2.0.0.yaml annotation (FR-B89-060 → 063)

##### FR-B89-060 — 2.0.0.yaml receives a B.8.9 delivery annotation (comment-only)
The `2.0.0.yaml` web-public surface and the `no-web-public-layer → qwik-web-public`
migration delta receive a comment-only delivery annotation per ADR-B89-007
(safest vs b8-3 T-012/T-015). The annotation form mirrors the B.8.4/B.8.6/B.8.7
delivered-flip style: `# B.8.9 — delivered` as an inline comment.

##### FR-B89-061 — Annotation MUST NOT break b8-3 (17/17) or b8-3b (12/12)
The annotation does NOT introduce a forbidden inline-pin key (`version`/`pin`/
`image` — b8-3 T-012) and does NOT add a component scalar value matching
`^\d+\.\d+` (b8-3 T-015). The `frontend` layer `surfaces` block (including
`web-public` and `web-backoffice` entries) and `migration_deltas` remain
intact. After the annotation, `b8-3.test.sh` (17 L1) and `b8-3b.test.sh` (12 L1)
stay GREEN.

##### FR-B89-062 — standard: web-frontend.yaml reference: comment-only (ADR-B89-007)
ADR-B89-007 chose comment-only annotation (lean). No `standard:` key is added
to the YAML structure in `2.0.0.yaml` — the delivery annotation is a comment
only, preserving all b8-3 schema invariants.

##### FR-B89-063 — 2.0.0.yaml surfaces block + migration_delta keys byte-stable to YAML parser
After the annotation, the `layers.frontend.surfaces` block structure (both
`web-backoffice` and `web-public` entries) and the `migration_deltas` remain
valid YAML and byte-parseable by the same Python3 + PyYAML parser used in
b8-3/b8-3b harnesses. No key rename or structural change is made.

---

#### Group 7 — Documentation (FR-B89-070 → 075)

##### FR-B89-070 — Janus arbitration section in README
The `README.md.tmpl` includes a section documenting: Janus arbitrates the
two surfaces (`web-public` and `web-backoffice`) for cross-layer changes until
Iris-Web (K.4) is shipped (T7 agent). The section cites plan:2321 and
ARCHITECTURE-TARGET.md:743 references for the arbitration contract.

##### FR-B89-071 — Envoy Connect/HTTP path documented
The README documents the Qwik→Envoy communication path: the Qwik client
makes Connect-protocol HTTP calls; Envoy Gateway (B.8.4) is the ingress
(`AT C4: Rel(qwik, envoy)`). The section cross-references the B.8.4 Envoy
template path `2.0.0/infra/k8s/envoy-gateway/`.

##### FR-B89-072 — web-backoffice unchanged posture documented
The README explicitly states that the `web-backoffice` Flutter Web surface is
unchanged by this brick: it uses the existing 1.0.0 Flutter app; any backoffice
migration is B.8.10/B.8.14 territory.

##### FR-B89-073 — Explicit scope-outs section in README
The README includes a "Scope out (this brick)" section listing:
- PWA machinery (Service Worker, Web Push/VAPID, offline shell) → B.9.2
- OIDC/PKCE Qwik client → B.9.3
- OTel wiring from Qwik (`Rel(qwik, otel)` OTLP) → B.8.12/B.7
- Streaming patterns (SSE/WebTransport/cancel-on-unmount) → B.7.10
- Hosting tier rows (Cloudflare Pages/Vercel/OVH) → B.9.7
- Iris-Web agent → K.4 (T7)
- Adopter CI workflow for the web surface (forge-web.yml) → B.8.10 (lean defer)

##### FR-B89-074 — Status block in README
The README includes a prominently placed Status block:
```
Status: candidate — scaffoldable: false until B.8.14
```

##### FR-B89-075 — Zod deferral note present (ADR-B89-003 — deferred)
The README includes: "Connect-ES client + Zod schemas — deferred per
ADR-B89-003 (protobuf-es types may suffice for the skeleton; revisit at B.9.2)."

---

#### Group 8 — Harness + CI + CHANGELOG (FR-B89-080 → 087)

##### FR-B89-080 — Harness file created, hermetic, ≤ 2 s L1, registered
`.forge/scripts/tests/b8-9.test.sh` ships with: `--level` flag, `source _helpers.sh`,
`run_test`, `print_summary` (mirroring b8-7 harness structure). L1 wall-clock
budget **≤ 2 s** (NFR-B89-001). Zero network or Docker calls at L1. Registered
as a one-line entry `"b8-9.test.sh --level 1"` in `.github/workflows/forge-ci.yml`
after the `b8-8.test.sh` / last existing harness line before b8-9.
**DELIVERED: 12 L1 tests, all GREEN.**

##### FR-B89-081 — Harness asserts subtree existence (required files)
The harness asserts that the required files in the web-public subtree exist.
At minimum: `package.json.tmpl`, `README.md.tmpl`, the Connect-ES client module
(`src/lib/greeter-client.ts.tmpl`), and the Node version file (`.nvmrc.tmpl`).
A missing required file is a FAIL.

##### FR-B89-082 — Harness asserts package.json.tmpl pin sentinels
The harness asserts that `package.json.tmpl` contains sentinel strings for
`@connectrpc/connect` and `@connectrpc/connect-web` (the transport.yaml
`versions_2_0_0` pinned facts). A missing sentinel is a FAIL.

##### FR-B89-083 — Harness asserts no fabricated-API guard
The harness asserts that `protoc-gen-connect-es` does NOT appear as an
active (non-comment) reference in any template file in the subtree (FR-B89-024).
A grep hit outside a comment line is a FAIL.

##### FR-B89-084 — Harness asserts web-frontend.yaml version + versions map
The harness asserts:
- `web-frontend.yaml` `version:` field is `"1.0.0"`
- The file contains a `versions:` block with at least one key
- `default:` field is present
Mirrors b8-7 (identity.yaml version + versions: block assertion).

##### FR-B89-085 — Harness asserts index.yml entry + REVIEW.md row
The harness asserts:
- `.forge/standards/index.yml` contains a reference to `web-frontend.yaml`
- `.forge/standards/REVIEW.md` contains a row referencing `web-frontend.yaml`
  and `1.0.0`
Mirrors b8-7 (REVIEW.md row assertion).

##### FR-B89-086 — Harness asserts 2.0.0.yaml annotation + frozen-1.0.0 guard
The harness asserts:
- `2.0.0.yaml` contains a B.8.9 delivery annotation comment (grep for
  `B\.8\.9.*delivered\|delivered.*B\.8\.9`)
- The `no-web-public-layer → qwik-web-public` migration delta with
  `strategy: additive-first` is intact
- The 1.0.0 `shared/protos/buf.gen.yaml.tmpl` (frozen) does NOT contain a
  B.8.9 annotation (guard against accidental 1.0.0 touch)

##### FR-B89-087 — Harness coupling guards: b8-3/b8-3b + b8-6 + CHANGELOG
The harness includes:
- Exit-code coupling guard for `b8-3.test.sh --level 1` (17/17 GREEN)
- Exit-code coupling guard for `b8-3b.test.sh --level 1` (12/12 GREEN)
- Exit-code coupling guard for `b8-6.test.sh --level 1` (GREEN — buf.gen
  manifest coupling, FR-B89-033)
- CHANGELOG whole-file grep anchored on `b8-9-qwik-web-public` (not bare "B.8.9")
A FAIL in any coupling guard is a b8-9 FAIL.

---

### Non-Functional Requirements

##### NFR-B89-001 — Harness L1 ≤ 2 s wall-clock (hermetic)
The `b8-9.test.sh` L1 harness wall-clock is ≤ **2 s** on the CI runner
(no network, no Docker, no npm install). All assertions are grep / stat /
file-exists / exit-code operations. 12 test cases at L1 (mirroring b8-7).
**DELIVERED: 12 L1 tests GREEN.**

##### NFR-B89-002 — Frozen 1.0.0 byte-identity preserved (b8-2 guard)
The frozen 1.0.0 schema.yaml, flat template tree, and `1.0.0.tar.gz` are
byte-unchanged. The frozen 1.0.0 `shared/protos/buf.gen.yaml.tmpl` is
byte-unchanged (FR-B89-031). Respects B.8.2 maintenance freeze + sha256 guard.

##### NFR-B89-003 — b8-3 (17/17) + b8-3b (12/12) + b8-6 sibling harnesses GREEN
All three sibling gates stay GREEN after every file touched by this brick.
A FAIL in any constitutes a B.8.9 constitutional violation (Article V.2). The
b8-9 harness enforces these as coupling guards (FR-B89-087).
**DELIVERED: full suite 48/48 GREEN.**

##### NFR-B89-004 — Full ~48-harness suite GREEN pre-push
Before pushing, the full forge-ci harness suite passes (the `full_harness_suite_before_push`
memory lesson — sibling scans can break silently). This includes b8-3, b8-3b,
b8-4, b8-5, b8-6, b8-7, b8-9, and any harness whose repo-wide scan could be
affected by the new `web-frontend.yaml` or the web-public subtree.
**DELIVERED: full suite 48/48 GREEN.**

##### NFR-B89-005 — Zero new external dependency for the harness
`b8-9.test.sh` does NOT introduce any new external binary or npm package. All
assertions are bash + grep + python3 (stdlib). The `web-frontend.yaml` `versions:`
block records pins as documentation only.

##### NFR-B89-006 — Verify-then-pin LIVE at /forge:design; re-verify at /forge:implement
ALL Qwik package identities, version strings, npm package names, Node LTS value,
and any version appearing in `web-frontend.yaml` `versions:` were resolved from
live sources at `/forge:design` and re-verified at `/forge:implement` (2026-06-03).
**DELIVERED:** `@builder.io/qwik ^1.20.0`, `@builder.io/qwik-city ^1.20.0`,
`vite =7.3.5`, Node `24` — all live-verified.

##### NFR-B89-007 — No secret material anywhere
No committed file introduced or modified by this brick contains a plaintext
secret value. The Qwik templates contain no credentials or API keys.

##### NFR-B89-008 — Article VI Flutter mandate untouched
This brick is additive on the Qwik surface. Flutter remains the
mobile/desktop/backoffice stack (ADR-005 KEEP half). The `flutter_bloc` mandate,
Flutter standard, and all Flutter template files are untouched.

##### NFR-B89-009 — Article VIII.1 preserved (Kong SHALL — UNTOUCHED)
This brick is additive. Kong removal and any VIII.1 amendment are B.8.14. The
candidate remains `scaffoldable: false`. No scaffolder code change ships.

##### NFR-B89-010 — Independent review required before /forge:plan
These specs passed an **independent reviewer** (not the author) before
`/forge:design` (t5-2 self-validation lesson). Self-approval of the
anti-hallucination pass and open-questions leanings is prohibited.
**DELIVERED: independent review design + final APPROVE round 1.**

##### NFR-B89-011 — Gates re-run POST-flip before any status promotion
The b8-3/b8-3b/b8-6 coupling guards and the full harness suite were re-run
AFTER the `2.0.0.yaml` delivered-flip annotation and AFTER the `web-frontend.yaml`
creation (b8-coroot lesson). **DELIVERED: post-flip re-run confirmed.**

##### NFR-B89-012 — Template file-count budget enforced
The web-public subtree does NOT exceed **15 template files** (FR-B89-002).
10 template files delivered. The harness asserts the file count at L1.

---

## Architecture Decision Records

| ADR | Decision | As-Implemented Resolution |
|-----|----------|--------------------------|
| **ADR-B89-001** | Qwik line + package identities | Stable v1 line: `@builder.io/qwik ^1.20.0` and `@builder.io/qwik-city ^1.20.0` (live-verified from npm registry 2026-06-03). `vite =7.3.5` (peer `>=5 <8` excludes live-latest 8.0.16). `@qwik.dev/*` v2 remains beta-only → watch-list future-option (`requires: v2-ga`). Connect client API: `createClient` + `createConnectTransport` from `@connectrpc/connect` + `@connectrpc/connect-web` (Connect-ES v2 idiomatic; not the retired `createPromiseClient`). |
| **ADR-B89-002** | Subtree location + skeleton scope | `2.0.0/frontend/web-public/` (schema-aligned sub-path under `frontend/`, per ADR-B8-3-004 / FR-B8-3-021). Plan top-level `2.0.0/web-public/` path superseded by the schema. Minimal hand-curated skeleton: 10 template files (well within ≤15 budget). |
| **ADR-B89-003** | Connect-ES consumption + Zod decision | Runtime `@connectrpc/connect` + `@connectrpc/connect-web` `^2.0.0` per transport.yaml; client module demonstrates one unary call using `createClient`/`createConnectTransport`. Zod **deferred** — protobuf-es types suffice for skeleton; AT:612 deferral note in README; revisit at B.9.2. `protoc-gen-connect-es` retired (B.8.6 reality); documented in README. |
| **ADR-B89-004** | TS codegen out-path | Re-pointed the 2.0.0 manifest es output from `../../frontend/lib/generated/connect/ts` → `../../frontend/web-public/src/lib/generated/connect` (additive edit; 1.0.0 untouched; bump-note in 2.0.0 manifest header: "B.8.9 delta: es plugin out-path re-pointed to the web-public surface"). |
| **ADR-B89-005** | Standard naming/shape | `web-frontend.yaml` (role-named, framework-agnostic — survives a hypothetical Qwik→SvelteKit pivot without rename; mirrors `gateway.yaml`/`identity.yaml` precedent). v1.0.0 birth. `default: qwik-city`, `alternatives: [sveltekit]`. |
| **ADR-B89-006** | Node pin convention | `.nvmrc.tmpl` in the web-public subtree; value = `24` (active LTS, verified from nodejs.org release schedule 2026-06-03; satisfies Qwik's `engines.node >=18.11`). README includes `nvm use` / `fnm use` / `setup-node` guidance. |
| **ADR-B89-007** | 2.0.0.yaml annotation shape | Comment-only annotation (safest vs b8-3 T-012/T-015): `# B.8.9 — delivered` inline comment on the web-public surface and/or migration delta in `2.0.0.yaml`. No `standard:` key added to YAML structure (b8-3 T-011 would require a resolvable file ref; comment-only avoids all structural risks). `2.0.0.yaml` comment-only annotation means no b8-3 T-012/T-015 exposure. |

---

## BDD Acceptance Criteria

```gherkin
Feature: Qwik web-public surface introduced additively as a 2.0.0 template brick,
  web-frontend standard created, buf.gen manifest out-path resolved, and frozen
  1.0.0 assets untouched
  As a Forge B.8 migration architect
  I want the Qwik web-public skeleton subtree, Connect-ES client wiring,
  owning web-frontend standard, and buf.gen manifest out-path decision
  delivered additively for the 2.0.0 candidate
  So that the flagship gains its first SEO-capable web surface,
  the web-frontend standard is properly versioned,
  and the frozen 1.0.0 stack is untouched

  Scenario: The 2.0.0 web-public subtree lands additively without disturbing any frozen 1.0.0 asset
    Given no web-public subtree existing yet in the 2.0.0 frontend tree
    And the frozen 1.0.0 template tree byte-identical to the B.8.2 freeze
    And no web-frontend.yaml standard existing in .forge/standards/
    And b8-3.test.sh (17 L1) and b8-3b.test.sh (12 L1) and b8-6.test.sh GREEN
    When the B.8.9 brick is implemented from these specs
    Then the web-public subtree exists at 2.0.0/frontend/web-public/ (schema-aligned per ADR-B89-002)
    And the subtree contains package.json.tmpl with @connectrpc/connect and @connectrpc/connect-web constraints
    And the subtree contains src/lib/greeter-client.ts.tmpl importing B.8.6 TS codegen descriptors
    And the subtree contains README.md.tmpl with Janus arbitration, scope-outs, and Status block
    And the subtree contains .nvmrc.tmpl = "24" (Node active LTS, live-verified)
    And the subtree file count is 10 template files (≤ 15 budget)
    And web-frontend.yaml exists at version "1.0.0" with a versions: map and a default: qwik-city entry
    And .forge/standards/REVIEW.md has a new web-frontend.yaml 1.0.0 ledger entry
    And 2.0.0.yaml carries a B.8.9 delivery annotation comment (comment-only per ADR-B89-007)
    And the no-web-public-layer → qwik-web-public migration_delta strategy: additive-first is intact
    And the frozen 1.0.0 template tree is byte-unchanged (sha256 guard, B.8.2)
    And b8-3.test.sh (17/17) and b8-3b.test.sh (12/12) and b8-6.test.sh stay GREEN
    And b8-9.test.sh passes all 12 L1 checks within 2 s

  Scenario: web-frontend.yaml becomes the Qwik web pin source and passes J.7
    Given web-frontend.yaml does not exist yet
    And bin/validate-standards-yaml.sh is at J.7 compliance level
    When the B.8.9 brick creates web-frontend.yaml at version "1.0.0"
    Then web-frontend.yaml has J.7-valid frontmatter (version, last_reviewed, expires_at, exception_constitutional: false, linter_rule: null)
    And default: qwik-city is declared (ratifying ADR-005)
    And alternatives: [sveltekit] is declared
    And the versions: map contains @builder.io/qwik ^1.20.0 and @builder.io/qwik-city ^1.20.0 (live-verified)
    And vite =7.3.5 is recorded (peer >=5 <8 excludes live-latest 8.0.16)
    And @qwik.dev/* is recorded as watch-list beta-only future-option
    And pin_review_cadence: is present with ISO 8601 P30D entry for qwik packages
    And .forge/standards/index.yml contains a web-frontend.yaml entry with qwik and web-public triggers
    And bin/validate-standards-yaml.sh passes on web-frontend.yaml
    And REVIEW.md has a | web-frontend.yaml | 1.0.0 | ledger row

  Scenario: 2.0.0 candidate scaffold is still refused until B.8.14
    Given the 2.0.0.yaml candidate with scaffoldable: false (ADR-B8-3-003/005)
    And the new web-public subtree present on disk
    When forge init is invoked
    Then the scaffolder still emits the flat 1.0.0 template tree with no web-public surface
    And no 2.0.0 Qwik template is scaffolded
    And scaffoldable: false is still the effective setting
    And no scaffolder code change ships in this brick
```
