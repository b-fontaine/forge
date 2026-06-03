# Specifications: b8-9-qwik-web-public

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.9 (docs/new-archetypes-plan.md §4.2 B.8.9 — Qwik web-public
     templates brick; ratified by ADR-005 ARCHITECTURE-TARGET.md:365-374 —
     KEEP Flutter mobile+desktop, REPLACE Flutter Web public → Qwik City;
     SEO/LCP/TTI rationale. GROUND-TRUTH NOTE (Article III.4): (1) the 1.0.0
     flagship has NO web split — frontend/ is a single flat Flutter app, zero
     web-public/web-backoffice/qwik matches repo-wide; (2) plan path
     "2.0.0/web-public/" conflicts with the ratified schema modeling — ADR-B8-3-004
     surfaces are SUB-PATHS under frontend/, schema governs, disk path resolved
     at design (Q-002); (3) NO Qwik version/package exists anywhere — full
     verify-then-pin LIVE at design (Q-001); (4) plan/AT still cite
     protoc-gen-connect-es, retired by Connect v2 — B.8.6 reality is
     buf.build/bufbuild/es:v2.2.0 + @connectrpc/connect ^2.0.0.) -->

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
  The on-disk subtree location MUST follow the schema. Design-time resolution
  (Q-002) decides whether this is `2.0.0/frontend/web-public/` (schema-aligned
  lean) or an ADR-B89-002-recorded alternative.
- **No Qwik version or package name exists anywhere** in the plan or
  ARCHITECTURE-TARGET — only "Qwik City", performance figures, and a benchmarks
  citation. The Qwik line (1.x vs 2.x), npm package identities, Vite coupling,
  engines field, and scaffold shape are **verify-then-pin LIVE** at design (Q-001).
- **Stale codegen naming in plan/AT**: both still cite `protoc-gen-connect-es`,
  which Connect v2 retired. The B.8.6 2.0.0 manifest reality is
  `buf.build/bufbuild/es:v2.2.0` (`target=ts`, `import_extension=js`) with
  runtime `@connectrpc/connect ^2.0.0` (transport.yaml v1.3.0 `versions_2_0_0`).
  The Qwik client consumes THAT output (same naming-drift class as B.8.6/B.8.7).
- **TS codegen out-path not yet surface-aligned**: the B.8.6 2.0.0 manifest es
  plugin emits to `../../frontend/lib/generated/connect/ts` (the 1.0.0 single-app
  path). B.8.9 MUST decide: re-point the 2.0.0 manifest es output vs document the
  import path (Q-004 → ADR-B89-004).
- **No owning web standard exists**: `grep -rn qwik .forge/standards/` → matrix/
  lifecycle prose only. The 2.0.0.yaml `web-public` surface carries no `standard:`
  field. Unlike gateway.yaml / identity.yaml, the web-frontend pin source must be
  **created** by this brick (Q-003 → ADR-B89-005).
- **No Node toolchain pin exists anywhere**: no `.nvmrc` or `.node-version` in
  `cli/` or archetype; frontend CI is Flutter-only. A Node pin convention is
  **net-new** (Q-005 → ADR-B89-006).
- **Iris-Web (K.4, Qwik standards owner) is a T7 agent — not yet shipped.**
  Janus arbitrates the two surfaces until K.4. The standard created here is the
  bridge.
- **Compliance**: Qwik client binaries are compliant at all tiers. Hosting rows
  (Cloudflare/Vercel/OVH) are B.9.7 territory — out of scope here.
- **Downstream reuse**: B.9.2 (PWA channel), B.7.2/B.7.10 (streaming RAG UI).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4.2 B.8.9 — Qwik web-public templates brick (lean: `2.0.0/web-public/`; GROUND-TRUTH NOTE: path tension resolved by schema at design, Q-002) |
| **Candidate schema (observed)** | `.forge/schemas/full-stack-monorepo/2.0.0.yaml` — `layers.frontend.surfaces[web-public]` { path: web-public/, stack: qwik, note: new in 2.0.0 (B.8.9) }; `migration_deltas[no-web-public-layer → qwik-web-public]` { brick: B.8.9, strategy: additive-first }. No `standard:` field on the web-public surface. |
| **transport.yaml v1.3.0 (observed)** | `versions_2_0_0:` JS pins: `"@connectrpc/connect": "^2.0.0"`, `"@connectrpc/connect-web": "^2.0.0"`, `"protoc-gen-es": ">=2.2.0"`. These are the AUTHORITATIVE runtime pins the Qwik client MUST respect — pinned facts, citable without live verification. |
| **buf.gen.yaml.tmpl 2.0.0 (observed)** | `.forge/templates/archetypes/full-stack-monorepo/2.0.0/shared/protos/buf.gen.yaml.tmpl` — es plugin: `remote: buf.build/bufbuild/es:v2.2.0`, `out: ../../frontend/lib/generated/connect/ts`, `opt: [target=ts, import_extension=js]`. 1.0.0 manifest frozen (NFR-B89-001). Q-004 resolves whether the 2.0.0 out-path is re-pointed to the web-public surface. |
| **identity.yaml + gateway.yaml (observed)** | Frontmatter model for the new web-frontend standard: `version`, `last_reviewed`, `expires_at`, `exception_constitutional: false`, `linter_rule: null`, `enforcement: ci_blocking: false`, `versions:` map + `pin_review_cadence:` ISO 8601 (gateway.yaml precedent). |
| **B.8.3 invariants (binding)** | 1.0.0 frozen (B.8.2 sha256 guard); candidate `scaffoldable: false` until B.8.14; pins live in standards not in schema (ADR-B8-3-002); no forbidden inline-pin keys `{version, pin, image}` (b8-3 T-012); no bare `^\d+\.\d+` scalars (b8-3 T-015); every `standard:` ref resolves (b8-3 T-011). |
| **b8-7 harness shape (observed)** | `b8-7.test.sh` — 12 L1 tests, `--level` flag, `source _helpers.sh`, `run_test`/`print_summary`, exit-code-only coupling guard for b8-3+b8-3b, CHANGELOG whole-file grep anchored on change name. |
| **b8-6.test.sh coupling** | Asserts `buf.gen.yaml.tmpl` content (es plugin out-path). If Q-004 re-points the 2.0.0 manifest, b8-6 assertions MUST stay GREEN (coupling guard in b8-9 harness). |
| **FR-B8-3-020/021/022 (binding)** | surfaces invariants: sub-paths under frontend/ only, no new top-level layer, FR-GL-001 validator triple backend/frontend/infra preserved. |
| **Release target** | v0.4.0-rc.11 |
| **Dependencies** | B.8.3 (surfaces modeling, FR-GL-001), B.8.6 (Connect TS codegen + JS pins), B.8.4 (subtree + standard conventions, Envoy path) |

---

## ADDED Requirements

### Functional Requirements

#### Group 1 — web-public subtree (FR-B89-001 → 010)

##### FR-B89-001 — 2.0.0 web-public subtree created at the schema-aligned location
The brick MUST create the versioned web-public subtree following the `N.N.N/`
versioned-subtree convention. The exact disk path MUST be schema-aligned: the
`2.0.0/frontend/web-public/` location (sub-path under `frontend/`, per ADR-B8-3-004
/ FR-B8-3-021) is the lean; the design-time decision is recorded in ADR-B89-002.
If ADR-B89-002 chooses a different sub-path, the deviation MUST be documented in
ADR-B89-002 with evidence that FR-GL-001 and b8-3 T-011/T-015 stay GREEN. The
invariant: the subtree is a **sub-path under the frontend layer path**, not a
new top-level layer, unless ADR-B89-002 records otherwise with evidence.
The subtree is exempt from repo-wide scans that skip `N.N.N/` directories.

##### FR-B89-002 — Minimal Qwik City skeleton; file-count budget ≤ 15 template files
The subtree MUST contain a minimal, hand-curated Qwik City skeleton. The exact
file list is a design-time decision per Q-001/Q-002 (ADR-B89-001/002). This spec
mandates:
- A `package.json.tmpl` with Connect-ES runtime dependency declarations (using the
  transport.yaml v1.3.0 `versions_2_0_0` pins as the authoritative constraint
  floor; Qwik package identities and their version pinning resolved at design via
  Q-001/ADR-B89-001 — NOT fabricated here).
- Build/config files matching the live Qwik City scaffold shape verified at design.
- A `tsconfig.json.tmpl` or equivalent TypeScript configuration.
- At least one route file in the `src/` tree.
- At least one Connect-ES client module (§G2).
- A `README.md.tmpl` (§G7).
- A `.nvmrc.tmpl` or equivalent Node toolchain pin file (§G5).
The subtree MUST NOT be a full vendored `create-qwik` dump. The total count of
template files in the subtree MUST NOT exceed **15**. Exact file list is
decided at design and asserted by the harness.

##### FR-B89-003 — Audit comment headers on all template files
Every template file in the web-public subtree MUST carry a top-of-file audit
comment in the form `# <!-- Audit: B.8.9 (b8-9-qwik-web-public) -->` (or
`<!-- Audit: B.8.9 (b8-9-qwik-web-public) -->` for HTML/Markdown files) and a
`# Standard: .forge/standards/web-frontend.yaml` reference (or equivalent comment
syntax). Mirrors the B.8.4 / B.8.7 audit-header invariant.

##### FR-B89-004 — Template variable conventions match sibling subtrees
All template variables in the web-public subtree MUST use the `<variable-name>`
angle-bracket convention established by B.8.4 / B.8.5 / B.8.7 (e.g., `<project-name>`,
`<namespace>`). No deviating variable syntax is introduced. Template vars MUST
match the set used by sibling 2.0.0 subtrees where applicable.

##### FR-B89-005 — Subtree visible on disk; scaffoldable: false preserved
The 2.0.0/frontend/web-public/ subtree (or the path decided by ADR-B89-002) is
an on-disk asset for the 2.0.0 candidate. The candidate schema remains
`scaffoldable: false` until B.8.14 (ADR-B8-3-003/005). `forge init` still emits
the flat 1.0.0 template tree with no web-public surface. The README MUST carry a
"Status" block stating: `candidate, scaffoldable: false until B.8.14`.

##### FR-B89-006 — 1.0.0 template assets byte-unchanged
No file under `.forge/templates/archetypes/full-stack-monorepo/` outside the
`2.0.0/` versioned path MAY be modified by this brick (B.8.2 maintenance freeze).
The 1.0.0 `schema.yaml`, `docker-compose.dev.yml.tmpl`, `.env.example.tmpl`, and
all 1.0.0 template files MUST be byte-identical before and after. Any diff
touching a 1.0.0 asset is a constitutional violation.

##### FR-B89-007 — web-backoffice Flutter surface explicitly unchanged
No file in any `web-backoffice/` subtree (present or future) is touched by this
brick. The 1.0.0 Flutter app already covers the backoffice; any backoffice move
is B.8.10/B.8.14 territory. The README MUST state this posture explicitly
(§G7).

##### FR-B89-008 — No fabricated Qwik API symbols in template files
Template files in the subtree MUST NOT contain Qwik or Connect API usage patterns
that have not been verified live at design (ADR-B89-001). The exact import paths,
hook names, and component patterns are resolved at design via live npm registry
evidence (Q-001) and re-verified at implement. Any symbol asserted here without
live evidence is an Article III.4 violation.

##### FR-B89-009 — README.md.tmpl present and follows B.8.4/B.8.7 conventions
The subtree MUST contain `README.md.tmpl` documenting: (a) the delivery model and
standard reference (`web-frontend.yaml`), (b) the Janus arbitration posture
(§G7), (c) the Envoy Connect/HTTP path (§G7), (d) web-backoffice unchanged
posture (§G7), (e) explicit scope-outs (§G7), (f) Status block
(`candidate, scaffoldable: false until B.8.14`), (g) Node toolchain setup
guidance (§G5). The README MUST carry an audit comment
`<!-- Audit: B.8.9 (b8-9-qwik-web-public) -->`.

##### FR-B89-010 — Subtree under frontend/ preserves FR-GL-001 triple
The web-public subtree MUST NOT introduce a new top-level layer entry in
`2.0.0.yaml` (FR-B8-3-020/021 — the minimum layer triple backend/frontend/infra
is preserved unchanged). The subtree is a sub-path under the existing `frontend/`
layer. The FR-GL-001 validator check MUST remain unaffected.

---

#### Group 2 — Connect-ES client wiring (FR-B89-020 → 025)

##### FR-B89-020 — Connect-ES client module present and imports generated descriptors
The subtree MUST contain at least one Connect-ES client module (e.g.,
`src/lib/greeter-client.ts.tmpl` or equivalent path resolved at design). The
module MUST import service descriptors from the B.8.6 TS codegen output path as
resolved by ADR-B89-004 (Q-004). No descriptor generation logic is re-implemented
in the Qwik subtree; the import path references the buf.gen output.

##### FR-B89-021 — Runtime deps respect transport.yaml versions_2_0_0 JS pins
The `package.json.tmpl` MUST declare `@connectrpc/connect` and
`@connectrpc/connect-web` with constraints satisfying the transport.yaml v1.3.0
`versions_2_0_0` pins:
- `@connectrpc/connect`: constraint satisfying `^2.0.0`
- `@connectrpc/connect-web`: constraint satisfying `^2.0.0`
These are **pinned facts** (transport.yaml v1.3.0 — citable without live
verification). No weaker or diverging constraint is permitted.

##### FR-B89-022 — Demonstrates at least one unary Connect call pattern
The Connect-ES client module MUST demonstrate at least one unary RPC call against
the demo Greeter service descriptors (the same service used by the B.8.6 and B.8.7
examples). The exact API shape (transport creation, client instantiation, call
syntax) is resolved at design via live Qwik + Connect-ES documentation (Q-001 /
ADR-B89-001) and re-verified at implement. No Connect or Qwik API symbol is
asserted as correct in this spec.

##### FR-B89-023 — No fabricated API symbols; shapes verified live at design
The client module MUST NOT use Qwik hooks, Connect transport factory names, or
import paths that have not been verified live at design (Q-001 / ADR-B89-001).
The verify-then-pin obligation applies equally at implement phase (re-verify).
A symbol written at specify time that later conflicts with the live API is an
Article III.4 violation caught at the implement anti-hallucination pass.

##### FR-B89-024 — protoc-gen-connect-es naming retired; stale reference documented
The template files and README MUST NOT reference `protoc-gen-connect-es` as the
current codegen tool. The correct tool per B.8.6 is `buf.build/bufbuild/es:v2.2.0`
(`@bufbuild/protoc-gen-es >=2.2.0`). The README MUST note the naming drift
(ADR-B89-003) to prevent adopter confusion.

##### FR-B89-025 — Zod inclusion decided by ADR-B89-003 (Q-006); either-way invariant
Whether `zod` is included as a skeleton dependency is resolved at design (Q-006 /
ADR-B89-003). The invariant regardless of the decision:
- If Zod is **included**: `package.json.tmpl` declares a `zod` dependency with a
  version pin resolved live at design (NOT fabricated here); the client module
  demonstrates Zod schema usage.
- If Zod is **deferred**: `README.md.tmpl` includes an explicit note citing the
  AT:612 deferral rationale ("protobuf-es types may suffice for the skeleton; Zod
  deferred per ADR-B89-003") and records the deferral for B.9.2 or the next
  brick requiring it.

---

#### Group 3 — buf.gen 2.0.0 es out-path (FR-B89-030 → 033)

##### FR-B89-030 — 2.0.0 buf.gen manifest es out-path decision implemented per ADR-B89-004
The 2.0.0 `buf.gen.yaml.tmpl` es plugin `out:` value MUST be updated per the
decision in ADR-B89-004 (Q-004). The lean is: re-point to the web-public surface
sub-path (additive edit; the 2.0.0 manifest is a B.8.6-owned standalone copy
designed for exactly this evolution). The exact out-path value is resolved at
design (Q-002 / Q-004) — NOT fabricated here. If the decision is to keep the
current `../../frontend/lib/generated/connect/ts` path (document-import lean),
the manifest is unchanged and ADR-B89-004 records the rationale.

##### FR-B89-031 — 1.0.0 buf.gen manifest byte-unchanged
The frozen 1.0.0 `buf.gen.yaml.tmpl` at
`.forge/templates/archetypes/full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl`
MUST be byte-unchanged by this brick (B.8.2 / NFR-B89-001). Only the 2.0.0 copy
at `2.0.0/shared/protos/buf.gen.yaml.tmpl` may be edited.

##### FR-B89-032 — Manifest header carries a bump-note for the out-path change
If ADR-B89-004 re-points the out-path, the 2.0.0 manifest header comment MUST
receive a bump-note in the form:
```
# B.8.9 delta: es plugin out-path re-pointed to the web-public surface (ADR-B89-004).
```
If the out-path is kept unchanged (document-import lean), no bump-note is added.

##### FR-B89-033 — b8-6.test.sh stays GREEN after the manifest edit
After any edit to the 2.0.0 `buf.gen.yaml.tmpl`, the sibling `b8-6.test.sh --level 1`
MUST stay GREEN. The b8-9 harness MUST include an exit-code coupling guard for
b8-6 (the b8-4/b8-5/b8-7 coupling strategy). If b8-6 asserts the current es
out-path value, the harness coupling guard detects any breakage introduced by
the Q-004 re-point decision.

---

#### Group 4 — NEW standard web-frontend.yaml (FR-B89-040 → 047)

##### FR-B89-040 — web-frontend.yaml created (final name per ADR-B89-005, Q-003)
The brick MUST create `.forge/standards/web-frontend.yaml` (name per ADR-B89-005
lean; role-named like `gateway.yaml`/`identity.yaml` — survives a hypothetical
Qwik→SvelteKit pivot without rename). If ADR-B89-005 chooses a different name,
that name is used consistently throughout. This spec uses `web-frontend.yaml` as
the canonical placeholder.

##### FR-B89-041 — J.7-valid frontmatter
The standard MUST carry J.7-valid frontmatter matching the `gateway.yaml`/`identity.yaml`
model:
- `version: "1.0.0"` (birth version)
- `last_reviewed: 2026-06-02`
- `expires_at:` — a dated 12-month expiry (e.g., `2027-06-02`; NOT `never` —
  web framework pins drift, this is NOT a structural standard)
- `exception_constitutional: false` (dated expiry → exc:false per FR-J7-020
  coupling)
- `linter_rule: null` (advisory standard; no constitution-linter.sh anchor)
- `enforcement: ci_blocking: false, pre_commit_hook: false` (documentation-only
  at birth; enforcement is a later brick, Iris-Web / K.4 territory)

##### FR-B89-042 — default/alternatives per ADR-B89-005
The standard MUST declare:
- `default: qwik-city` (ratifying ADR-005 ARCHITECTURE-TARGET.md:365-374)
- `alternatives: [sveltekit]` (per ADR-005 rationale)
- `rationale:` citing ADR-005 + the SEO/resumability/LCP/TTI benchmarks source
  (ARCHITECTURE-TARGET.md citation). The rationale MUST NOT fabricate benchmark
  figures — it references the AT citation for evidence.

##### FR-B89-043 — First versions: map (values live-resolved at design, NOT fabricated here)
The standard MUST contain a `versions:` map as the first Qwik web-frontend pin
source (mirroring `gateway.yaml` / `identity.yaml`). The map MUST contain Qwik
package entries for at least the primary framework packages. **The exact package
names (e.g., `@builder.io/qwik` vs `@qwik.dev/core` or their renamed equivalents),
version values, and Vite coupling are resolved LIVE at `/forge:design` via npm
registry evidence (Q-001 → ADR-B89-001) and re-verified at implement (b8-coroot
lesson).**

**RESOLVED at /forge:design (ADR-B89-001):** Qwik package identities and version values confirmed LIVE from npm registry (re-verified 2026-06-03): `@builder.io/qwik ^1.20.0` and `@builder.io/qwik-city ^1.20.0` (stable v1 line); `vite =7.3.5` (peer constraint `>=5 <8` excludes live-latest 8.x); `@qwik.dev/*` v2 remains beta-only → watch-list future-option `requires: v2-ga`. The `@connectrpc/connect ^2.0.0` and `@connectrpc/connect-web ^2.0.0` entries are transport.yaml v1.3.0 pinned facts cited without live verification.

##### FR-B89-044 — pin_review_cadence: field added, ISO 8601
The standard MUST add `pin_review_cadence:` with entries for each Qwik package
in the `versions:` map. Cadence values (e.g., P30D for framework packages with
active upstream velocity) are resolved at design based on upstream release cadence.
The field MUST use ISO 8601 duration format (gateway.yaml / identity.yaml
precedent).

##### FR-B89-045 — REVIEW.md ledger receives a B.8.9 birth row
`.forge/standards/REVIEW.md` MUST receive an append-only `Updated` or `Created`
entry for `web-frontend.yaml v1.0.0`, dated 2026-06-02, with a one-line
description (birth: first web-frontend pin source — Qwik City default, ADR-005
ratification). Mirrors the B.8.4 `gateway.yaml` and B.8.7 `identity.yaml`
REVIEW.md precedents (Article XII append-only ledger).

##### FR-B89-046 — web-frontend.yaml passes bin/validate-standards-yaml.sh
After creation, `bin/validate-standards-yaml.sh` (J.7) MUST pass in both
single-file mode and directory mode. The MANDATORY `REVIEW.md` row for
`web-frontend.yaml | 1.0.0` (FR-J7-023 coupling) is satisfied by FR-B89-045.

##### FR-B89-047 — index.yml entry added with correct triggers
`.forge/standards/index.yml` MUST receive an entry for `web-frontend.yaml`
with triggers including at minimum: `qwik`, `web-public`, `connect-es`,
`web frontend`, and any framework-specific trigger resolved at design
(e.g., `qwik-city`, `sveltekit`). The entry MUST follow the existing
index.yml structure (trigger list + file reference) observed in sibling entries.

---

#### Group 5 — Node toolchain pin (FR-B89-050 → 052)

##### FR-B89-050 — Node version-file convention in the subtree
The web-public subtree MUST contain a Node toolchain version file — either
`.nvmrc.tmpl` or an equivalent (`.node-version.tmpl`) — as decided by
ADR-B89-006 (Q-005). The convention mirrors the Flutter `flutter-version-file`
pattern: a single-line file consumed by `setup-node` (GitHub Actions) or `nvm`/
`fnm` at setup time. The file MUST use the `<variable-name>` template var
convention if the value is to be parameterized, or a literal value if the
version is pinned directly.

##### FR-B89-051 — Node LTS value live-resolved at design, NOT fabricated
The Node version value MUST be the active LTS version that satisfies Qwik's
`engines.node` field, resolved LIVE at `/forge:design` from the official Node.js
release schedule and the Qwik package `engines` field (Q-005 → ADR-B89-006).
No Node version string is fabricated in this spec.

**RESOLVED at /forge:design (ADR-B89-006):** Active Node LTS version is `24` (`.nvmrc` = `24`), sourced from the official Node.js release schedule (nodejs.org/en/about/previous-releases provenance). Node 24 is the current active LTS and satisfies Qwik's `engines.node >=18.11` constraint.

##### FR-B89-052 — README setup guidance mirrors flutter-version-file pattern
The `README.md.tmpl` MUST include a "Node toolchain setup" section documenting:
(a) the version-file convention chosen by ADR-B89-006, (b) the `nvm use` / `fnm use`
/ `setup-node` usage pattern, (c) a note that the value is the active LTS
satisfying Qwik's engine requirements. Mirrors the Flutter setup section in
sibling README templates.

---

#### Group 6 — 2.0.0.yaml annotation (FR-B89-060 → 063)

##### FR-B89-060 — 2.0.0.yaml receives a B.8.9 delivery annotation (comment-only lean)
The `2.0.0.yaml` web-public surface and/or `no-web-public-layer → qwik-web-public`
migration delta MUST receive a delivery annotation per ADR-B89-007. The lean is
comment-only (safest vs b8-3 T-012/T-015). The exact annotation form is resolved
at design by inspecting the live B.8.4/B.8.6/B.8.7 delivered-flip annotations.

##### FR-B89-061 — Annotation MUST NOT break b8-3 (17/17) or b8-3b (12/12)
The annotation MUST NOT introduce a forbidden inline-pin key (`version`/`pin`/
`image` — b8-3 T-012) and MUST NOT add a component scalar value matching
`^\d+\.\d+` (b8-3 T-015). The `frontend` layer `surfaces` block (including
`web-public` and `web-backoffice` entries) and `migration_deltas` MUST remain
intact. After the annotation, `b8-3.test.sh` (17 L1) and `b8-3b.test.sh` (12 L1)
MUST stay GREEN.

##### FR-B89-062 — standard: web-frontend.yaml reference on the component or surface
Whether the delivery annotation adds a `standard: web-frontend.yaml` reference
to a 2.0.0.yaml component or surface entry is constrained by the b8-3 schema
invariants. If ADR-B89-007 adds a `standard:` reference, it MUST be a reference-
only annotation (not an inline pin — ADR-B8-3-002), it MUST resolve as a file
on disk (b8-3 T-011 coupling), and it MUST NOT introduce a forbidden key
(b8-3 T-012). If the decision is comment-only (lean), no `standard:` key is
added to the YAML structure.

##### FR-B89-063 — 2.0.0.yaml surfaces block + migration_delta keys byte-stable to YAML parser
After the annotation, the `layers.frontend.surfaces` block structure (both
`web-backoffice` and `web-public` entries) and the `migration_deltas` MUST
remain valid YAML and byte-parseable by the same Python3 + PyYAML parser used
in b8-3/b8-3b harnesses. No key rename or structural change is permitted.

---

#### Group 7 — Documentation (FR-B89-070 → 075)

##### FR-B89-070 — Janus arbitration section in README
The `README.md.tmpl` MUST include a section documenting: Janus arbitrates the
two surfaces (`web-public` and `web-backoffice`) for cross-layer changes until
Iris-Web (K.4) is shipped (T7 agent). The section MUST cite the plan
(plan:2321) and ARCHITECTURE-TARGET.md:743 references for the arbitration
contract.

##### FR-B89-071 — Envoy Connect/HTTP path documented
The README MUST document the Qwik→Envoy communication path: the Qwik client
makes Connect-protocol HTTP calls; Envoy Gateway (B.8.4) is the ingress
(`AT C4: Rel(qwik, envoy)`). The section MUST cross-reference the B.8.4 Envoy
template path `2.0.0/infra/k8s/envoy-gateway/`.

##### FR-B89-072 — web-backoffice unchanged posture documented
The README MUST explicitly state that the `web-backoffice` Flutter Web surface is
unchanged by this brick: it uses the existing 1.0.0 Flutter app; any backoffice
migration is B.8.10/B.8.14 territory.

##### FR-B89-073 — Explicit scope-outs section in README
The README MUST include a "Scope out (this brick)" section listing each of the
following with the responsible future brick:
- PWA machinery (Service Worker, Web Push/VAPID, offline shell) → B.9.2
- OIDC/PKCE Qwik client → B.9.3
- OTel wiring from Qwik (`Rel(qwik, otel)` OTLP) → B.8.12/B.7
- Streaming patterns (SSE/WebTransport/cancel-on-unmount) → B.7.10
- Hosting tier rows (Cloudflare Pages/Vercel/OVH) → B.9.7
- Iris-Web agent → K.4 (T7)
- Adopter CI workflow for the web surface (forge-web.yml) → B.8.10 (lean defer)

##### FR-B89-074 — Status block in README
The README MUST include a prominently placed Status block:
```
Status: candidate — scaffoldable: false until B.8.14
```
This prevents adopters from attempting to scaffold the 2.0.0 archetype before
the migration/cutover bricks complete.

##### FR-B89-075 — Zod deferral note (if deferred by ADR-B89-003)
If ADR-B89-003 defers Zod, the README MUST include a note citing the AT:612
reference: "Connect-ES client + Zod schemas — deferred per ADR-B89-003
(protobuf-es types may suffice for the skeleton; revisit at B.9.2)."
If Zod is included, the README documents its usage pattern instead.

---

#### Group 8 — Harness + CI + CHANGELOG (FR-B89-080 → 087)

##### FR-B89-080 — Harness file created, hermetic, ≤ 2 s L1, registered
The brick MUST ship `.forge/scripts/tests/b8-9.test.sh` with: `--level` flag,
`source _helpers.sh`, `run_test`, `print_summary` (mirroring b8-7 harness
structure). L1 wall-clock budget **≤ 2 s** (NFR-B89-001). Zero network or
Docker calls at L1. MUST be registered as a one-line entry
`"b8-9.test.sh --level 1"` in `.github/workflows/forge-ci.yml` after the
`b8-8.test.sh` line (or the last existing harness line before b8-9).

##### FR-B89-081 — Harness asserts subtree existence (required files)
The harness MUST assert that the required files in the web-public subtree exist.
The exact file list is decided at design (Q-001/Q-002 → ADR-B89-001/002) and
encoded in the harness at implement. At minimum the harness MUST assert:
`package.json.tmpl`, `README.md.tmpl`, the Connect-ES client module, and the
Node version file are present. A missing required file is a FAIL.

##### FR-B89-082 — Harness asserts package.json.tmpl pin sentinels
The harness MUST assert that `package.json.tmpl` contains sentinel strings for
`@connectrpc/connect` and `@connectrpc/connect-web` (the transport.yaml
`versions_2_0_0` pinned facts). These are grep-verifiable facts. A missing
sentinel is a FAIL.

##### FR-B89-083 — Harness asserts no fabricated-API guard (where greppable)
The harness MUST assert that `protoc-gen-connect-es` does NOT appear as an
active (non-comment) reference in any template file in the subtree
(FR-B89-024). A grep hit outside of a comment line is a FAIL.

##### FR-B89-084 — Harness asserts web-frontend.yaml version + versions map
The harness MUST assert:
- `web-frontend.yaml` `version:` field is `"1.0.0"`
- The file contains a `versions:` block with at least one key
- `default:` field is present
Mirrors b8-7 T-008 (identity.yaml version + versions: block assertion).

##### FR-B89-085 — Harness asserts index.yml entry + REVIEW.md row
The harness MUST assert:
- `.forge/standards/index.yml` contains a reference to `web-frontend.yaml`
- `.forge/standards/REVIEW.md` contains a row referencing `web-frontend.yaml`
  and `1.0.0`
Mirrors b8-7 T-009 (REVIEW.md row assertion).

##### FR-B89-086 — Harness asserts 2.0.0.yaml annotation + frozen-1.0.0 guard
The harness MUST assert:
- `2.0.0.yaml` contains a B.8.9 delivery annotation comment (grep for
  `B\.8\.9.*delivered\|delivered.*B\.8\.9` or the equivalent annotation form
  chosen by ADR-B89-007)
- The `no-web-public-layer → qwik-web-public` migration delta with
  `strategy: additive-first` is intact
- The 1.0.0 `shared/protos/buf.gen.yaml.tmpl` (frozen) does NOT contain a
  B.8.9 annotation (guard against accidental 1.0.0 touch)

##### FR-B89-087 — Harness coupling guards: b8-3/b8-3b + b8-6 + CHANGELOG
The harness MUST include:
- Exit-code coupling guard for `b8-3.test.sh --level 1` (17/17 GREEN)
- Exit-code coupling guard for `b8-3b.test.sh --level 1` (12/12 GREEN)
- Exit-code coupling guard for `b8-6.test.sh --level 1` (GREEN — buf.gen
  manifest coupling, FR-B89-033)
- CHANGELOG whole-file grep anchored on `b8-9-qwik-web-public` (not bare "B.8.9"
  — sibling false-pass prevention per `changelog-test [Unreleased] coupling` lesson)
A FAIL in any coupling guard is a b8-9 FAIL.

---

### Non-Functional Requirements

##### NFR-B89-001 — Harness L1 ≤ 2 s wall-clock (hermetic)
The `b8-9.test.sh` L1 harness wall-clock MUST be ≤ **2 s** on the CI runner
(no network, no Docker, no npm install). All assertions are grep / stat /
file-exists / exit-code operations. ~12 test cases at L1 (mirroring b8-7).

##### NFR-B89-002 — Frozen 1.0.0 byte-identity preserved (b8-2 guard)
The frozen 1.0.0 schema.yaml, flat template tree, and `1.0.0.tar.gz` MUST be
byte-unchanged. The frozen 1.0.0 `shared/protos/buf.gen.yaml.tmpl` MUST be
byte-unchanged (FR-B89-031). Respects B.8.2 maintenance freeze + sha256 guard.

##### NFR-B89-003 — b8-3 (17/17) + b8-3b (12/12) + b8-6 sibling harnesses GREEN
All three sibling gates MUST stay GREEN after every file touched by this brick.
A FAIL in any constitutes a B.8.9 constitutional violation (Article V.2). The
b8-9 harness enforces these as coupling guards (FR-B89-087).

##### NFR-B89-004 — Full ~47-harness suite GREEN pre-push
Before pushing, the full forge-ci harness suite (all ~47 harnesses in
`.forge/scripts/tests/`) MUST pass (the `full_harness_suite_before_push` memory
lesson — sibling scans can break silently). This includes b8-3, b8-3b, b8-4,
b8-5, b8-6, b8-7, b8-9, and any harness whose repo-wide scan could be affected
by the new `web-frontend.yaml` or the web-public subtree. Versioned `N.N.N/`
subtrees are exempt from repo-wide scanner scans per convention.

##### NFR-B89-005 — Zero new external dependency for the harness
`b8-9.test.sh` MUST NOT introduce any new external binary or npm package. All
assertions are bash + grep + python3 (stdlib). The `web-frontend.yaml` `versions:`
block records pins as documentation; it does not introduce a new build-time dep.

##### NFR-B89-006 — Verify-then-pin LIVE at /forge:design; re-verify at /forge:implement
ALL Qwik package identities, version strings, npm package names, Node LTS value,
and any version appearing in `web-frontend.yaml` `versions:` MUST be resolved
from live sources at `/forge:design` and re-verified at `/forge:implement`
(b8-coroot lesson). No version string is fabricated at specify phase. Any version
asserted without live evidence is an Article III.4 anti-hallucination failure.

##### NFR-B89-007 — No secret material anywhere
No committed file introduced or modified by this brick MAY contain a plaintext
secret value. The Qwik templates contain no credentials or API keys. This is a
hard stop (Article XI.6 spirit).

##### NFR-B89-008 — Article VI Flutter mandate untouched
This brick is additive on the Qwik surface. Flutter remains the
mobile/desktop/backoffice stack (ADR-005 KEEP half). The `flutter_bloc` mandate,
Flutter standard, and all Flutter template files are untouched. The Qwik surface
is explicitly outside Article VI's scope.

##### NFR-B89-009 — Article VIII.1 preserved (Kong SHALL — UNTOUCHED)
This brick is additive. Kong removal and any VIII.1 amendment are B.8.14. The
candidate remains `scaffoldable: false`. No scaffolder code change ships.

##### NFR-B89-010 — Independent review required before /forge:plan
These specs MUST pass an **independent reviewer** (not the author) before
`/forge:design` proceeds (t5-2 self-validation lesson). Self-approval of the
anti-hallucination pass and open-questions leanings is prohibited.

##### NFR-B89-011 — Gates re-run POST-flip before any status promotion
The b8-3/b8-3b/b8-6 coupling guards and the full harness suite MUST be re-run
AFTER the `2.0.0.yaml` delivered-flip annotation and AFTER the `web-frontend.yaml`
creation (b8-coroot lesson: gates re-run post-flip). A green run before the
edits does not satisfy the gate requirement.

##### NFR-B89-012 — Template file-count budget enforced
The web-public subtree MUST NOT exceed **15 template files** (FR-B89-002). The
harness MUST assert the file count at L1 (a simple `find ... | wc -l` check).
This prevents accidental vendoring of a full create-qwik scaffold dump.

---

## Architecture Decision Records (seeds — finalized at /forge:design)

- **ADR-B89-001 — Qwik line + package identities.** Verify LIVE: current stable
  line (1.x vs 2.x), npm package names (`@builder.io/qwik*` vs `@qwik.dev/*`
  renamed family or other), Vite version coupling, create-qwik scaffold shape,
  engines.node field. **Lean:** latest stable line with caret pins recorded in
  the new standard; npm registry identity and package names captured live.
- **ADR-B89-002 — Subtree location + skeleton scope.** **Lean:**
  `2.0.0/frontend/web-public/` (schema-aligned sub-path, ADR-B8-3-004); minimal
  hand-curated skeleton (≤15 template files: package.json, Node version file,
  build/vite/qwik config, tsconfig, at least one route, one Connect client
  module, README) — NOT a full vendored create-qwik dump.
- **ADR-B89-003 — Connect-ES consumption + Zod decision.** **Lean:** runtime
  `@connectrpc/connect` + `@connectrpc/connect-web` `^2.0.0` per transport.yaml;
  client module demonstrates one unary call against demo Greeter descriptors;
  Zod deferred with README note (protobuf-es types may suffice for the skeleton;
  AT:612 reference recorded).
- **ADR-B89-004 — TS codegen out-path.** **Lean:** re-point the 2.0.0 manifest
  es output to the web-public surface sub-path (additive edit, 1.0.0 untouched;
  bump-note in manifest header). Exact out-path value depends on Q-002 resolution.
- **ADR-B89-005 — Standard naming/shape.** **Lean:** `web-frontend.yaml`
  (role-named, framework-agnostic — survives a hypothetical Qwik→SvelteKit pivot
  without rename; mirrors `gateway.yaml`/`identity.yaml` precedent).
- **ADR-B89-006 — Node pin convention.** **Lean:** `.nvmrc.tmpl` in the
  web-public subtree; value = active LTS verified live against Qwik's engines.node;
  README setup-node guidance.
- **ADR-B89-007 — 2.0.0.yaml annotation shape.** **Lean:** comment-only on the
  surface and/or delta (safest vs b8-3 T-012/T-015); no component-SET entry
  unless the schema's reference-only invariants stay GREEN with live evidence.

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
    Then the web-public subtree exists at the schema-aligned location under 2.0.0/frontend/
    And the subtree contains package.json.tmpl with @connectrpc/connect and @connectrpc/connect-web constraints
    And the subtree contains at least one Connect-ES client module importing B.8.6 TS codegen descriptors
    And the subtree contains README.md.tmpl with Janus arbitration, scope-outs, and Status block
    And the subtree file count is ≤ 15 template files
    And web-frontend.yaml exists at version "1.0.0" with a versions: map and a default: qwik-city entry
    And .forge/standards/REVIEW.md has a new web-frontend.yaml 1.0.0 ledger entry
    And 2.0.0.yaml carries a B.8.9 delivery annotation comment
    And the no-web-public-layer → qwik-web-public migration_delta strategy: additive-first is intact
    And the frozen 1.0.0 template tree is byte-unchanged (sha256 guard, B.8.2)
    And b8-3.test.sh (17/17) and b8-3b.test.sh (12/12) and b8-6.test.sh stay GREEN
    And b8-9.test.sh passes all L1 checks within 2 s

  Scenario: web-frontend.yaml becomes the Qwik web pin source and passes J.7
    Given web-frontend.yaml does not exist yet
    And bin/validate-standards-yaml.sh is at J.7 compliance level
    When the B.8.9 brick creates web-frontend.yaml at version "1.0.0"
    Then web-frontend.yaml has J.7-valid frontmatter (version, last_reviewed, expires_at, exception_constitutional: false, linter_rule: null)
    And default: qwik-city is declared (ratifying ADR-005)
    And alternatives: [sveltekit] is declared
    And the versions: map contains at least one Qwik package entry (live-resolved at design)
    And pin_review_cadence: is present with ISO 8601 duration entries
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

---

## Anti-Hallucination Pass (Article III.4)

- **No Qwik version numbers anywhere in this spec.** No `1.x`, `2.x`, or specific
  semver string for any Qwik package is asserted as a registry-verified fact.
  All Qwik version values are **RESOLVED at /forge:design (ADR-B89-001)**: `@builder.io/qwik ^1.20.0`, `@builder.io/qwik-city ^1.20.0`, `vite =7.3.5`; re-verified LIVE 2026-06-03.
- **No Qwik npm package names asserted beyond transport.yaml.** The `@connectrpc/connect
  ^2.0.0` and `@connectrpc/connect-web ^2.0.0` entries are transport.yaml v1.3.0
  `versions_2_0_0` pinned facts — citable without live verification. All Qwik
  package identities (`@builder.io/qwik*` vs `@qwik.dev/*` or other renamed
  family) are **RESOLVED at /forge:design (ADR-B89-001)**: stable v1 line uses `@builder.io/qwik*`; `@qwik.dev/*` v2 beta-only → watch-list.
- **Node LTS value not fabricated.** No Node version string appears in this spec
  — **RESOLVED at /forge:design (ADR-B89-006)**: Node `24` (active LTS, `.nvmrc` = `24`, satisfies `engines.node >=18.11`).
- **Subtree exact location not fabricated.** The `2.0.0/frontend/web-public/`
  path is the lean; the resolution is Q-002 → ADR-B89-002. No path is asserted
  as final here.
- **Standard final name not fabricated as a hard fact.** `web-frontend.yaml` is
  the lean per ADR-B89-005; Q-003 confirms at design.
- **buf.gen out-path final value not fabricated.** The current value is an
  observed fact (`../../frontend/lib/generated/connect/ts`); the re-point decision
  is Q-004 → ADR-B89-004.
- **Zod not asserted as included or excluded.** Both outcomes are specced as
  either-way invariants (FR-B89-025). The decision is Q-006 → ADR-B89-003.
- **protoc-gen-connect-es retired — documented, not used.** FR-B89-024 records
  this as historical; the correct tool is `buf.build/bufbuild/es:v2.2.0`
  (B.8.6 observed fact).
- **b8-3 coupling grounded in direct re-read.** The `web-public` surface uses
  the YAML `path`/`stack`/`note` structure — none in the b8-3 T-012 forbidden
  set `{version, pin, image}`. A comment-only annotation (lean) is not a YAML
  scalar value — T-015 does not flag it. FR-B89-061 is grounded in direct
  re-read of the b8-3 test assertions.
- **Iris-Web / K.4 is T7, not yet shipped.** No K.4 agent behavior is assumed.
  Janus arbitration documented as the bridge posture.
- **Independent review required (NFR-B89-010).** These specs MUST pass an
  independent reviewer before `/forge:design`. Not self-approved here.

## Open Questions

Tracked in `open-questions.md`: Q-001 (Qwik line + packages — live npm registry
verify at /forge:design → ADR-B89-001, open), Q-002 (subtree location + skeleton
file list → ADR-B89-002, open, lean schema-aligned + minimal), Q-003 (owning
standard name → ADR-B89-005, open, lean `web-frontend.yaml`), Q-004 (TS codegen
out-path → ADR-B89-004, open, lean re-point), Q-005 (Node LTS + package manager →
ADR-B89-006, open), Q-006 (Zod → ADR-B89-003, open, lean defer with note).
