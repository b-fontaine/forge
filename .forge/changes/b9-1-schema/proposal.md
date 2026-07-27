# Proposal: b9-1-schema

<!-- Created: 2026-07-27 -->
<!-- Schema: default -->
<!-- Audit: B.9.1 (docs/new-archetypes-plan.md §5.2 — mobile-pwa-first/2.0.0.yaml archetype scaffold schema) -->

## Problem

T8 opens B.9 — the `mobile-only / 1.0.0` → `mobile-pwa-first / 2.0.0` rename +
extension. `mobile-only` (delivered T2 P2 via `b4-mobile-only`) already covers
Flutter iOS + Android, OIDC via `flutter_appauth`, Keychain/Keystore secure
storage, biometric lock, App Attest + Play Integrity attestation and Fastlane
store pipelines. What it lacks is the **Qwik PWA channel** prescribed by
`docs/ARCHITECTURE-TARGET.md` §6.3 — installable PWA on Android + desktop, with
a native iOS fallback when push is critical.

This change is **link #1** of the 11-brick B.9 chain: the archetype scaffold
schema that every downstream brick (web-pwa subfolder, shared OIDC templates,
decision tree, bloc generators, CI, snapshot, migration script, harness)
validates against. Same grain as `b6-1-schema` / `b7-1-schema`.

**Ground truth (re-read live 2026-07-27, Article III.4):**

- **`mobile-only` uses a *third* schema shape**, not either of the two families
  catalogued by B.6.1. `.forge/schemas/mobile-only/schema.yaml` declares
  `archetype:` (not `name:`), `schema_version:` (not `version:`), a **single
  layer** `- id: app / path: .`, and carries **no `stage` / `scaffoldable` /
  `phases`**. It is consequently **invisible** to the versioned-schema validator,
  which globs only `<dir>/[0-9]*.[0-9]*.[0-9]*.yaml`
  (`validate-foundations.sh:407`). Recorded, not normalised.

- **The versioned validator hard-requires `{backend, frontend, infra}`**
  (`validate-foundations.sh:436-438`: `KO: layers must include backend, frontend,
  infra`). `mobile-pwa-first` has by construction **neither a backend nor an infra
  layer** — `mobile-only`'s own description is verbatim *"No backend, no
  infrastructure, no BaaS"*. A versioned `mobile-pwa-first/2.0.0.yaml` therefore
  **cannot satisfy the invariant** without either fabricating two empty layers or
  relaxing the validator. **This is the load-bearing decision of B.9.1**
  (→ ADR-B9-1-001 / Q-001). B.6.1 met a strictly softer form of this (ADR-B6-1-004:
  genuinely backend-centric, only the frontend surface deferred); here **two of the
  three required layers would be pure fiction**.

- **The version is `2.0.0`, not `1.0.0`** (plan §5.2). The archetype is a
  rename + extension of `mobile-only / 1.0.0`, which stays as a legacy alias. The
  directory name changes too, and the validator enforces `name == dirname`, so the
  file must declare `name: mobile-pwa-first`.

- **The rename is already half-wired by T.4 — B.9.1 lands in a reserved slot.**
  `archetype.schema.json` v2 already accepts `mobile-pwa-first` in its enum *and*
  keeps `mobile-only` as a deprecated legacy alias.
  `.forge/scaffolding/dispatch-table.yml:59-64` already carries
  `status: legacy_alias`, `target: mobile-pwa-first`,
  `migration: "B.9 (T8) — bin/forge-migrate-mobile-pwa.sh"`. **No taxonomy edit is
  needed by this change.**

- **The Qwik precedent exists and is reusable.** B.8.9 (`b8-9-qwik-web-public`)
  shipped `frontend/web-public/` — a Qwik City skeleton with a Connect-ES v2
  client — under `full-stack-monorepo / 2.0.0`, plus the **role-named** standard
  `web-frontend.yaml` v1.0.0 (default `qwik-city`, alt `sveltekit`). B.9.2 should
  consume that standard as pin source rather than invent pins. **Not covered by it**:
  Service Worker, Web Push / VAPID, `manifest.json`, offline shell — B.9.2/B.9.3
  territory. Recorded as a gap, never fabricated here.

- **K.4 Iris-Web is forward-stable for this archetype** — its archive record states
  it was scoped to survive `mobile-pwa-first` without rework. No agent work in B.9.

- **B.9.6 is already delivered and is a no-op.** The
  `no-state-management-alternatives` linter rule was activated repo-wide by B.8.11
  (`state-management.yaml` `enforcement.ci_blocking: false → true`). Plan §5.2
  already annotates B.9.6 as *"déjà fait par B.8.11"*. Confirmed live; recorded, not
  re-done.

## Solution

Author the **specification for** `.forge/schemas/mobile-pwa-first/2.0.0.yaml` — its
required content, the process phases it materialises, the component set it
references, the two-surface layer model, and the candidate/non-scaffoldable rules.
Like B.6.1 / B.7.1, this change is **propose + specify + design + plan**; the schema
file itself and its harness are built at the implementation phase. It ships **no
scaffolder, no template, no version pin**, and edits **no existing schema, standard
or constitution article**.

The `2.0.0.yaml`, when built, MUST:

1. Use the *archetype scaffold schema* shape (parity with
   `ai-native-rag/1.0.0.yaml`, `event-driven-eu/1.0.0.yaml`,
   `full-stack-monorepo/2.0.0.yaml`): `name`, `version`, `stage`, `scaffoldable`,
   `description`, `tdd_enforced`, `bdd_required_for_user_facing`,
   `coverage_threshold`, `layers`, `phases`.
2. Declare `name: mobile-pwa-first`, `version: "2.0.0"`, `stage: candidate`,
   `scaffoldable: false`.
3. Model the **two real surfaces** — the native Flutter app (today's `mobile-only`
   `app` layer) and the new Qwik `web-pwa/` channel — and reconcile that model with
   the validator's required layer triple **without fabricating layers that scaffold
   nothing** (→ ADR-B9-1-001 + ADR-B9-1-004).
4. **Inline** the process phases (no `extends:` — no scaffold-schema loader resolves
   it; re-confirmed by B.6.1 and B.7.1), materialised from the Flutter TDD process,
   plus the B.9-specific gate covering the PWA-vs-native channel decision.
5. Declare the component set **reference-only** (ADR-B8-3-002 / ADR-B7-1-003 /
   ADR-B6-1-003 precedent, no inline pins): Qwik → `web-frontend.yaml`,
   OIDC → `identity.yaml`, observability → `observability.yaml`; and **reference as
   deferred** the Service Worker / Web Push (VAPID) / offline-shell concerns that
   have no standard yet (B.9.2 / B.9.3).
6. Carry a header block documenting candidate semantics: not scaffoldable while no
   `web-pwa/` templates exist; promotion to `stable` + `scaffoldable: true` happens
   at the B.9.11 harness brick (mirrors B.6.7 / B.7.6 / B.8.14); `mobile-only / 1.0.0`
   is untouched and keeps rendering byte-equivalently for v0.3.0 adopters.

Decisions reserved for `/forge:design` (ADRs); leanings stated:

- **ADR-B9-1-001 — how a backend-less archetype satisfies the
  `{backend, frontend, infra}` validator invariant.** Three candidates:
  **(a)** declare stub `backend` + `infra` layers marked deferred/empty;
  **(b)** relax the validator narrowly — introduce an explicit `layer_profile:`
  (`multi-layer`, the enforced default preserving today's behaviour, vs
  `client-only`) and require the triple only for `multi-layer`;
  **(c)** keep `mobile-pwa-first` out of the versioned family entirely (legacy
  `schema.yaml` shape only).
  **Lean: (b).** (a) fabricates two layers that scaffold nothing and would poison
  every downstream B.9 brick with dead layer ids — against Article III.4's spirit;
  (c) forfeits the versioned scaffolder routing that B.9.8 + B.9.11 need for the
  promotion flip. **(b) is backward-compatible by default** but touches the
  B.8.3.b-owned shared validator and therefore cascades to `b8-3b.test.sh` and any
  sibling asserting the current KO message — **maintainer call, not self-approved.**
- **ADR-B9-1-002 — stage/scaffoldable for the first cut.** Lean: `candidate` +
  `scaffoldable: false`; promotion deferred to the B.9.11 harness brick.
- **ADR-B9-1-003 — which process phases to inline**, and whether the PWA-vs-native
  decision tree (B.9.4) is a schema `phase` gate or documentation only. Lean: inline
  the Flutter TDD phases + one `channel-decision` gate; the prose tree stays B.9.4's.
- **ADR-B9-1-004 — layer identity and forward mapping.** How the two surfaces are
  named, and how `mobile-only`'s single `app` layer maps forward without breaking
  the legacy alias or `bin/forge-migrate-mobile-pwa.sh` (B.9.9).
- **ADR-B9-1-005 — component references + deferred-standard gap.** Lean:
  reference-only; Service Worker / Web Push / VAPID referenced as `delivered_by: B.9.2`
  with no inline pin.

Release vehicle: maintainer-set (additive spec artifact; no runtime change).

## Scope In

- `proposal.md`, `specs.md`, `design.md`, `tasks.md`, `.forge.yaml` for
  `b9-1-schema` (this change).
- Requirements `FR-B9-1-*` / `NFR-B9-1-*` defining WHAT the schema file must contain
  and the candidate/non-scaffoldable rules.
- ADRs `ADR-B9-1-001..005`.
- At impl: `.forge/schemas/mobile-pwa-first/2.0.0.yaml` +
  `.forge/scripts/tests/b9-1.test.sh`.

## Scope Out (Explicit Exclusions)

- **`web-pwa/` subfolder + Service Worker + Web Push + manifest + offline shell** —
  B.9.2. This change references them as deferred; it creates none.
- **Shared OIDC templates (Flutter `AuthGateway` + TS Connect-ES client)** — B.9.3.
- **Decision-tree documentation in `docs/ARCHETYPES.md`** — B.9.4.
- **Hera bloc/bloc_test generators from proto messages** — B.9.5.
- **NSMA linter activation** — B.9.6, **already delivered by B.8.11**; no-op.
- **CI `pwa-deploy` job** — B.9.7. **Snapshot tarball** — B.9.8.
  **`bin/forge-migrate-mobile-pwa.sh`** — B.9.9. **`docs/MIGRATION-PATHS.md`** —
  B.9.10. **Harness + promotion flip** — B.9.11.
- **Any edit to `mobile-only / 1.0.0`** — the legacy alias stays byte-equivalent.
- **Constitution amendment** — none.
- **Component version pins** — owned by the referenced standards; never inlined.

## Impact

- **Users affected**: B.9 brick authors (the schema is the shared contract gating the
  rest of the chain). **Zero** effect on existing adopters: `mobile-only` is
  untouched and keeps scaffolding as today; `mobile-pwa-first` is not scaffoldable
  yet, so `forge init --archetype mobile-pwa-first` refuses cleanly with exit **2** — `init.ts:210-217` gates on the dispatch table before the B.8.14 `selectScaffoldableVersion` guard, and T.4 registered `mobile-pwa-first` only as the `target:` of the `mobile-only` alias, not as a key of its own. It becomes exit 3 once a brick adds that entry (the `b7-2a-dispatch-register` precedent), rather than emitting a broken scaffold. **Verified live 2026-07-27** — the
  design-phase assumption of exit 3 was wrong and is corrected here.
- **Technical impact**: spec artifacts only in this change. At impl the schema file
  becomes a new sibling validated on landing by `check_versioned_schema_siblings` —
  **conditional on Q-001**, which may additionally require a narrow, backward-
  compatible edit to that validator.
- **Dependencies**: B.8.3.b (versioned-schema validator), B.8.14 (CLI selection /
  refusal path), T.4 (taxonomy slot + dispatch alias). Gates B.9.2 … B.9.11.

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: propose+specify+design+plan gate; the
  schema file is built only after design.
- **Article III.4 (Anti-Hallucination)**: the third schema shape, the validator's
  hard layer triple, the T.4 pre-wiring, the B.8.9 Qwik precedent and the B.8.11
  NSMA no-op are all re-read from live files and cited by path/line. The
  backend/infra layer conflict is **recorded as an open question, not papered over**.
  No library pin is committed here.
- **Article IV (Delta-based)**: additive — no existing schema/standard edited *in
  this change*. Any validator relaxation is itself gated behind Q-001 and would be
  backward-compatible by default.
- **Article VI (Flutter Architecture)**: `flutter_bloc` exclusivity consumed as-is;
  already CI-enforced since B.8.11.
- **Article V (Compliance gate)**: every open question maps to a design-phase ADR;
  no work proceeds around an unresolved question.
- **Article XII (Governance)**: no amendment.

## Open Questions (seed)

- **Q-001** — how a backend-less archetype satisfies the `{backend, frontend, infra}`
  validator invariant: stub layers vs narrow validator relaxation vs staying out of
  the versioned family (→ ADR-B9-1-001; leaning narrow relaxation via
  `layer_profile:`). **Blocking — decides whether B.9.1 stays purely additive.**
- **Q-002** — candidate→stable promotion trigger and owning brick (→ ADR-B9-1-002;
  leaning B.9.11 harness).
- **Q-003** — which process phases to inline + whether the channel decision is a
  phase gate or doc-only (→ ADR-B9-1-003).
- **Q-004** — layer identity + forward mapping of `mobile-only`'s single `app` layer
  (→ ADR-B9-1-004), including what `bin/forge-migrate-mobile-pwa.sh` (B.9.9) will
  have to rewrite.
- **Q-005** — component reference-only + deferred Service Worker / Web Push /VAPID
  standard gap (→ ADR-B9-1-005; leaning reference-only).
