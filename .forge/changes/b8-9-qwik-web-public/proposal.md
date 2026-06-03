# Proposal: b8-9-qwik-web-public

<!-- Created: 2026-06-02 -->
<!-- Schema: default -->
<!-- Audit: B.8.9 (docs/new-archetypes-plan.md §4.2 lines 2319-2321 — Qwik web-public templates brick; ratified by ADR-005 ARCHITECTURE-TARGET.md:365-374) -->

## Problem

The 2.0.0 candidate schema (B.8.3) models the web surface split the flagship
needs for SEO-sensitive public web:

```yaml
# 2.0.0.yaml — layers.frontend (ADR-B8-3-004, FR-B8-3-021)
    surfaces:
      - id: web-backoffice
        path: web-backoffice/
        stack: flutter-web
        note: Flutter Web — backoffice / admin UI; was frontend/ in 1.0.0
      - id: web-public
        path: web-public/
        stack: qwik
        note: Qwik PWA — public-facing web; new in 2.0.0 (B.8.9)
# 2.0.0.yaml — migration_deltas
  - from: no-web-public-layer
    to: qwik-web-public
    brick: B.8.9
    strategy: additive-first
```

The brick is **not delivered**: no `web-public` template exists anywhere on
disk; the 2.0.0 tree carries only B.8.4/B.8.5/B.8.6/B.8.7 subtrees. This is
the **last 2.0.0 template brick** before the migration/cutover bricks
(B.8.10–B.8.15).

### GROUND-TRUTH FINDINGS (Article III.4)

**Ground truth (re-read 2026-06-02):**

- **The 1.0.0 flagship has no web split at all.** `frontend/` is a single
  flat Flutter app (lib_core/features/shared/generated_protos gitkeeps);
  zero `web-public`/`web-backoffice`/`qwik` matches repo-wide on the 1.0.0
  line; B8-BASELINE has no web/qwik mention. The migration delta is honest:
  `from: no-web-public-layer` — this brick **introduces** the surface.
- **Path tension — schema governs.** Plan §4.2 says
  `templates/full-stack-monorepo/2.0.0/web-public/` (top-level), but the
  ratified ADR-B8-3-004 models surfaces as **sub-paths under `frontend/`**
  (FR-B8-3-021: no new top-level layer; FR-GL-001 validator triple
  preserved). The on-disk subtree location must follow the schema
  (`2.0.0/frontend/web-public/` lean) — decided at design (Q-002).
- **No Qwik version or package name exists anywhere** in the plan or
  ARCHITECTURE-TARGET (only "Qwik City", perf figures, and the
  benchmarks-repo citation). The Qwik line (1.x vs 2.x), package identities
  (`@builder.io/qwik*` vs the renamed `@qwik.dev/*` family), and scaffold
  shape are **verify-then-pin LIVE** at design (Q-001).
- **Stale codegen naming in plan/AT**: both still cite
  `protoc-gen-connect-es`, which **Connect v2 retired** — the B.8.6 2.0.0
  manifest reality is `buf.build/bufbuild/es:v2.2.0` (`target=ts`) with
  runtime `@connectrpc/connect ^2.0.0` (transport.yaml v1.3.0
  `versions_2_0_0`). The Qwik client consumes THAT output; same
  naming-drift class as B.8.6 Q-004 / B.8.7 plugin findings.
- **TS codegen out-path not yet surface-aligned**: the B.8.6 manifest emits
  to `frontend/lib/generated/connect/ts` (the 1.0.0 single-app path), not
  to a `web-public/` location. B.8.9 must decide: re-point the 2.0.0
  manifest vs import-from-current-path (Q-004).
- **No owning web standard exists**: `grep -rn qwik .forge/standards/` →
  matrix/lifecycle prose only. The 2.0.0.yaml qwik surface carries **no
  `standard:` field** and the component SET has no web entry. Unlike
  Envoy/Zitadel (gateway.yaml/identity.yaml), the web-frontend pin source
  must be **created** by this brick (Q-003), J.7-compliant, with an
  index.yml entry. Note: state-management.yaml is Flutter-bloc-scoped and
  silent on Qwik; its `activation_planned: "B.8 (T6)"` belongs to B.8.11,
  not this brick.
- **No Node toolchain pin exists anywhere** (no .nvmrc/.node-version in
  cli/ or archetype; frontend CI is Flutter-only via
  `flutter-version-file`). A Node pin convention is **net-new** (Q-005).
- **Iris-Web (K.4, Qwik standards owner) is a T7 agent — not yet shipped.**
  B.8.9 ships templates without a dedicated Qwik agent; **Janus arbitrates**
  the two surfaces (plan:2321; AT:743). The standard created here is the
  bridge until K.4.
- **Compliance**: Qwik client binaries are ✅ at all tiers, "aucun" forcing
  (compliance-tiers.md:116). Hosting rows (Cloudflare/Vercel/OVH) are B.9.7
  territory — out of scope here.
- Downstream reuse: B.9.2 (mobile-pwa-first PWA channel), B.7.2/B.7.10
  (ai-native-rag streaming UI) both build on this brick's Qwik foundation.

## Solution

When built, the B.8.9 brick MUST:

1. Create the versioned web-public subtree (location per Q-002, lean
   `2.0.0/frontend/web-public/`) containing a **minimal Qwik City
   skeleton**: `package.json.tmpl` (Qwik + Qwik City + Connect-ES runtime
   pins — all verify-then-pin LIVE), build/config files per the live
   scaffold shape, a minimal `src/` with one route + one **Connect-ES
   client wiring example** (consuming the B.8.6 TS codegen, target=ts /
   import_extension=js), and `README.md.tmpl` (→ ADR-B89-001/002, Q-001/Q-002).
2. Respect the transport.yaml v1.3.0 `versions_2_0_0` JS pins:
   `@connectrpc/connect ^2.0.0`, `@connectrpc/connect-web ^2.0.0`,
   descriptors from `@bufbuild/protoc-gen-es >=2.2.0` — and record the
   stale `protoc-gen-connect-es` naming as historical (→ ADR-B89-003).
3. Resolve the TS codegen out-path question: re-point the 2.0.0
   `buf.gen.yaml.tmpl` es output to the web-public surface vs document
   the import path — additive either way, 1.0.0 manifest untouched
   (→ ADR-B89-004, Q-004).
4. Create the **owning web-frontend standard** (name per Q-003, lean
   `web-frontend.yaml`): ratifies ADR-005 (`default: qwik-city`,
   `alternatives: [sveltekit]`, rationale SEO/resumability with the AT
   citation), first `versions:` map (Qwik packages + pinned line) +
   `pin_review_cadence:`, J.7-valid frontmatter (gateway.yaml model),
   index.yml entry + REVIEW.md birth row (→ ADR-B89-005).
5. Establish the **net-new Node toolchain pin convention** for the web
   surface (`.nvmrc`-style version-file consumed by setup-node, mirroring
   the Flutter `flutter-version-file` pattern; package manager decided at
   design) (→ ADR-B89-006, Q-005).
6. Annotate the 2.0.0.yaml delivery per precedent (comment-only on the
   web-public surface and/or migration delta; whether a component-SET
   entry is added with `standard: web-frontend.yaml` is a design decision
   constrained by b8-3.test.sh 17/17 + b8-3b 12/12) (→ ADR-B89-007, Q-003).
7. Document: Janus arbitration of the two surfaces (until Iris-Web/K.4),
   the Envoy Connect/HTTP path (AT C4 `Rel(qwik, envoy)`), web-backoffice
   = Flutter Web unchanged posture, and explicit scope-outs (OTel wiring
   `Rel(qwik, otel)` → B.8.12/B.7; OIDC PKCE client → B.9.3; Service
   Worker/Web Push PWA → B.9.2; hosting tiers → B.9.7; Zod schemas
   decision recorded per AT:612 — include or defer, Q-006).
8. Ship harness `.forge/scripts/tests/b8-9.test.sh` (~12 hermetic L1,
   mirror b8-7), register in `forge-ci.yml`, CHANGELOG `[Unreleased]`
   entry anchored on `b8-9-qwik-web-public`.
9. Run the full ~47-harness suite + gates before push; gates re-run
   POST-flip; independent review at design and pre-archive (separate
   lanes).

Decisions reserved for `/forge:design` (ADRs), leanings stated:

- **ADR-B89-001 — Qwik line + package identities.** Verify LIVE: current
  stable line, npm package names (`@builder.io/qwik`/`-city` vs
  `@qwik.dev/core`/`router` rename), Vite version coupling, create-qwik
  scaffold shape. **Lean:** latest stable line with exact-or-caret pins
  recorded in the new standard; registry identity captured (npm).
- **ADR-B89-002 — subtree location + skeleton scope.** **Lean:**
  `2.0.0/frontend/web-public/` (schema-aligned sub-path); minimal
  hand-curated skeleton (~6-10 files: package.json, vite/qwik config,
  tsconfig, one route, one Connect client module, README) — NOT a full
  vendored create-qwik dump (template-budget + maintainability).
- **ADR-B89-003 — Connect-ES consumption.** **Lean:** runtime
  `@connectrpc/connect` + `@connectrpc/connect-web` `^2.0.0` per
  transport.yaml; client module demonstrates one unary call against the
  demo Greeter service descriptors.
- **ADR-B89-004 — TS codegen out-path.** **Lean:** re-point the 2.0.0
  manifest es output to the web-public surface (the 2.0.0 manifest is
  already a B.8.6-owned standalone copy; additive edit, 1.0.0 untouched);
  bump-note in the manifest header.
- **ADR-B89-005 — standard naming/shape.** **Lean:** `web-frontend.yaml`
  (role-named like gateway/identity/persistence, not framework-named) —
  survives a hypothetical Qwik→SvelteKit pivot without rename.
- **ADR-B89-006 — Node pin.** **Lean:** `.nvmrc.tmpl` in the web-public
  subtree + README setup-node guidance; version = active LTS verified
  live against Qwik's engine requirements.
- **ADR-B89-007 — 2.0.0.yaml annotation shape.** **Lean:** comment-only
  on the surface + delta (safest vs b8-3 T-012/T-015); component-SET
  entry only if the schema's reference-only invariants stay GREEN.

Release vehicle: **v0.4.0-rc.11**.

## Scope In

- Web-public Qwik City skeleton subtree (location per Q-002) + Connect-ES
  client example.
- New standard `web-frontend.yaml` (Q-003 naming) + index.yml + REVIEW.md.
- 2.0.0 buf.gen manifest es out-path decision (additive).
- Node pin convention for the web surface.
- 2.0.0.yaml delivery annotation.
- Janus-arbitration + scope-out documentation.
- Harness `b8-9.test.sh` + forge-ci.yml + CHANGELOG.

## Scope Out (Explicit Exclusions)

- **Any 1.0.0 touch** — templates, schema.yaml, snapshot, the 1.0.0
  buf.gen manifest (frozen per B.8.2).
- **PWA machinery** (Service Worker, Web Push/VAPID, manifest, offline
  shell) — B.9.2 (mobile-pwa-first channel).
- **OIDC/PKCE Qwik client** — B.9.3 (with Zitadel B.8.7 as IdP).
- **OTel wiring from Qwik** (`Rel(qwik, otel)` OTLP) — B.8.12/B.7
  territory; documented as target only.
- **Streaming patterns** (SSE/WebTransport/cancel-on-unmount) — B.7.10.
- **Hosting tier rows** (Cloudflare Pages/Vercel/OVH) — B.9.7.
- **Iris-Web agent** — K.4 (T7); Janus arbitrates meanwhile.
- **web-backoffice/ Flutter Web templates** — the 1.0.0 Flutter app
  already covers it; any backoffice move is B.8.10/B.8.14 migration
  territory.
- **Adopter CI workflow for the web surface** (forge-web.yml) — decided
  at design as in-or-out; lean defer to B.8.10 with README guidance only.
- **REST-bridge/Kong removal, schema promotion, Constitution amendment** —
  B.8.14.

## Impact

- **Users affected**: none until B.8.14 — 2.0.0 stays
  `scaffoldable: false`; 1.0.0 adopters see zero change.
- **Technical impact**: new web-public subtree (~6-10 template files),
  1 NEW standard (first web-frontend pin source), 1 additive buf.gen
  manifest edit (2.0.0 copy only), 1 schema annotation, 1 new harness.
  No production code.
- **Dependencies**: B.8.3 (surfaces modeling), B.8.6 (Connect TS codegen +
  JS pins), B.8.4 (subtree + standard conventions, Envoy path).

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: proposal precedes specs;
  no template before specs.md + design.md + tasks.md.
- **Article III.4 (Anti-Hallucination) — CENTRAL**: zero Qwik versions
  exist in any source document — the entire toolchain is verify-then-pin
  LIVE at design + re-verified at implement; plan-vs-schema path tension
  and retired-plugin naming surfaced here, resolved by ADR with evidence.
- **Article IV (Delta-based)**: ADDED FRs; new standard gets a birth
  REVIEW.md row; buf.gen edit additive on the 2.0.0 copy only.
- **Article V (Compliance gate)**: harness + gates before status flips;
  full suite before push; POST-flip re-run.
- **Article VI (Flutter arch — PRESERVED)**: Flutter remains the
  mobile/desktop/backoffice stack (ADR-005 KEEP half); flutter_bloc
  mandate untouched; the Qwik surface is additive and outside Article VI's
  Flutter scope.
- **Article VIII.1 (Kong SHALL — IN FORCE, UNTOUCHED)**: additive brick.
- **Article XII (Governance)**: new standard ships under standard
  lifecycle rules (12-month review, not structural); BDFL decisions as
  ADRs at design.

## Open Questions (seed)

- **Q-001** — Qwik line + packages: current stable (1.x vs 2.x), npm
  identities (`@builder.io/qwik*` vs `@qwik.dev/*`), Vite coupling,
  engines field — verify LIVE (→ ADR-B89-001; open).
- **Q-002** — subtree location + skeleton file list: schema-aligned
  `2.0.0/frontend/web-public/` vs plan-literal `2.0.0/web-public/`;
  minimal skeleton scope (→ ADR-B89-002; open, lean schema-aligned +
  minimal).
- **Q-003** — owning standard name + 2.0.0.yaml component-SET entry vs
  comment-only annotation (b8-3 coupling) (→ ADR-B89-005/007; open, lean
  `web-frontend.yaml` + comment-only).
- **Q-004** — TS codegen out-path: re-point 2.0.0 manifest to the
  web-public surface vs document import path (→ ADR-B89-004; open, lean
  re-point).
- **Q-005** — Node pin + package manager: `.nvmrc` value (active LTS vs
  Qwik engines), npm vs pnpm (→ ADR-B89-006; open).
- **Q-006** — Zod schemas (AT:612 "Connect-ES client + Zod schemas"):
  include zod in the skeleton or record as deferred (→ ADR-B89-003; open,
  lean defer with note — protobuf-es types may suffice for the skeleton).
