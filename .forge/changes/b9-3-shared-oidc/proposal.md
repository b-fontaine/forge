# Proposal: b9-3-shared-oidc

<!-- Created: 2026-07-29 -->
<!-- Schema: default -->
<!-- Audit: B.9.3 (docs/new-archetypes-plan.md §5.2 — shared OIDC templates) -->

## Problem

`mobile-pwa-first` now has two rendered surfaces (B.9.2) and exactly one of them can
authenticate. The Flutter `app` surface carries a complete OIDC stack inherited from
`mobile-only`; the Qwik `web-pwa` surface has none. This brick gives the PWA channel
an auth path against the **same provider**, and is the archetype's **first real
cross-layer change** — the case B.9.1 anticipated when it declared
`fr_id_prefix_cross_layer: FR-GL-` and `cross_layer.agent: Janus`.

**Ground truth (re-read live 2026-07-29, Article III.4):**

- **The plan's wording for this brick is a category error, and following it literally
  would undo B.9.2.** `docs/new-archetypes-plan.md` §5.2 B.9.3 says the Flutter
  AuthGateway *"est doublé d'un client TypeScript **Connect-ES** (Qwik) qui parle au
  même provider OIDC via `authorization_code + PKCE`"*. Connect-ES is an **RPC
  transport** for calling a Connect/gRPC **backend**. OIDC `authorization_code + PKCE`
  is browser redirects plus token-endpoint calls against an identity provider — the
  two are unrelated, and Connect-ES cannot perform an OIDC flow. Worse,
  **B.9.2 deliberately pruned `@connectrpc/connect` and `@connectrpc/connect-web`**
  from `web-pwa/package.json` because this archetype has no backend layer
  (ADR-B9-2-001, ratified at review). Reintroducing them here — for a job they cannot
  do — would reverse that decision without argument. **Recorded, not silently
  reinterpreted** (→ ADR-B9-3-001).

- **No browser-side OIDC client exists anywhere in this repo.** Searched all archetype
  frontend trees: zero hits. In the flagship, OIDC is enforced **server-side at the
  gateway** — `full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/security-policy.yaml`
  (`SecurityPolicy` + `remoteJWKS`, B.8.12) — and `web-public/` ships no auth client at
  all. So unlike B.9.2, which had the B.8.9 Qwik spine to port, **this brick has no
  precedent to copy**. It is net-new code, and whatever it depends on is subject to
  verify-then-pin LIVE (→ ADR-B9-3-003).

- **What the two surfaces can actually share is a contract and a config shape — not
  code, and not a session.** The Flutter side declares
  `OidcConfig{issuer, clientId, redirectUri, scopes, discoveryUrl}`
  (`lib/infrastructure/auth/oidc_config.dart`) behind an `AuthRepository` port with
  `login()` / `refresh()` / `logout()` / `getCurrentToken()`
  (`lib/domain/auth/auth_repository.dart`), implemented over `flutter_appauth`
  (`lib/data/auth/auth_repository_impl.dart`). A Dart implementation and a TypeScript
  one share no runtime, no storage and no session: a token minted in the native app is
  not available to the PWA and vice versa. **"Shared" therefore means shape-parity and
  a single provider configuration, not a shared implementation** — and the scaffold
  must say so plainly rather than imply single sign-on it does not deliver
  (→ ADR-B9-3-002).

- **The two surfaces will usually need DIFFERENT client registrations.** A native app
  using a custom-scheme redirect (`<reverse-domain>://callback`, the value
  `oidc_config.dart` documents) and a browser app using an `https://…` redirect are
  normally two client entries at the provider, with different `clientId` and
  `redirectUri`. "Same provider" is true; "same client" is generally false. The shared
  config shape must model that instead of assuming one tuple fits both
  (→ ADR-B9-3-002).

- **`identity.yaml` is server-shaped and this archetype has no server.** It declares
  `default: zitadel` with `versions:` for `zitadel_chart` (10.0.2), `zitadel`
  (v4.14.0) and `zitadel_login` (v4.14.0) — Helm chart and container images — plus
  `compliance_tier_aware: true` noting **"T3 requires self-host"**. `mobile-pwa-first`
  is `layer_profile: client-only`: it has no infra layer and **cannot self-host
  anything**. Its predecessor targets an *external* provider (mobile-only's own
  description names Auth0 / Keycloak / Okta / AWS Cognito). So this brick consumes
  identity.yaml's provider stance but **cannot satisfy its T3 clause from inside the
  archetype** — the T3 obligation falls on the adopter's separately-operated provider.
  That gap must be stated explicitly, in the scaffold and in the standard, rather than
  left for a T3 adopter to discover (→ ADR-B9-3-004).

## Solution

Give `web-pwa/` a browser OIDC client performing `authorization_code + PKCE` against
the same provider as the native surface, and express the shared **configuration
contract** once so the two surfaces cannot drift apart. Ship the honest boundary:
two independent sessions, two client registrations, one provider.

Decisions reserved for `/forge:design` (ADRs); leanings stated:

- **ADR-B9-3-001 — what the TS client actually is.** Lean: **not** Connect-ES. Either
  a small dependency-free PKCE implementation on `fetch` + `crypto.subtle` (the
  archetype already hand-rolls base64url for VAPID in `src/lib/push.ts`), or a single
  audited OIDC browser library resolved verify-then-pin. Decide with live evidence;
  record the plan's wording as superseded either way.
- **ADR-B9-3-002 — how "shared" is expressed.** Lean: a single provider-config
  artefact declaring the issuer and scopes once, with **per-surface** `clientId` and
  `redirectUri`, plus a documented parity contract between the Dart `AuthRepository`
  port and its TS counterpart. No claim of shared sessions.
- **ADR-B9-3-003 — dependency or hand-rolled.** Lean: prefer zero runtime dependency
  if the flow fits in reviewable code, since B.9.2 established this surface as
  dependency-lean. Verify-then-pin LIVE at implement if a library wins.
- **ADR-B9-3-004 — the T3 gap.** Lean: state it in `identity.yaml`-adjacent docs and
  the `web-pwa` README — a client-only archetype cannot satisfy "T3 requires
  self-host"; the obligation transfers to the adopter's provider deployment. Whether
  this warrants an `identity.yaml` edit or only scaffold documentation is a design
  call.
- **ADR-B9-3-005 — token storage in the browser.** Lean: no refresh token in
  `localStorage`. The native surface uses Keychain/Keystore via
  `secure_storage_adapter.dart`; the browser has no equivalent, and pretending
  otherwise would be the same fiction pattern this module has already refused twice.

## Scope In

- A browser OIDC client under `web-pwa/src/lib/` implementing `authorization_code +
  PKCE`, plus its redirect/callback route.
- A shared provider-configuration artefact + the documented Dart↔TS parity contract.
- Documentation of the two-sessions boundary and the T3 gap.
- `b9-3.test.sh`, including a negative asserting `@connectrpc/*` has **not** returned
  to `web-pwa/package.json` (ADR-B9-2-001 must not be silently reversed).

## Scope Out

- **Any backend, token-exchange service or BFF** — `layer_profile: client-only`.
- **Single sign-on between the two surfaces** — not deliverable without a shared
  session store; explicitly disclaimed rather than half-built.
- **Changes to the Flutter auth stack** — it works and is byte-frozen by the B.9.2
  equivalence gate; this brick adds the TS side and the shared contract.
- **Provider provisioning / Zitadel deployment** — adopter territory.
- **Decision-tree prose** (B.9.4), **bloc generators** (B.9.5), **CI** (B.9.7),
  **snapshot** (B.9.8), **migration** (B.9.9), **promotion** (B.9.11).

## Impact

- **Users**: the PWA channel becomes able to authenticate. The archetype stays
  `candidate`, so nothing renders for adopters until B.9.11.
- **Technical**: first browser-side OIDC in the repo; first cross-layer change in this
  archetype, so Janus arbitrates and `FR-GL-` identifiers apply.
- **Risk**: writing auth code with no in-repo precedent. The mitigations are keeping
  the flow small enough to review, refusing browser refresh-token storage, and being
  explicit about what is *not* delivered.

## Constitution Compliance

- **Article I**: `b9-3.test.sh` RED before any client code.
- **Article II**: user-facing (a login flow) ⇒ BDD scenarios required.
- **Article III.4**: the plan's Connect-ES wording is contradicted by the code and is
  recorded as such, not quietly reinterpreted. No pin before implement.
- **Article IV**: additive; the Flutter surface is untouched.
- **Article X.2**: no secret scaffolded; client secrets are not used in public-client
  PKCE flows and none may be committed.
- **Article XII**: no amendment.

## Open Questions (seed)

- **Q-001** — what the TS client is, given Connect-ES cannot do OIDC (→ ADR-B9-3-001).
- **Q-002** — how the shared configuration models per-surface client registrations
  (→ ADR-B9-3-002).
- **Q-003** — dependency vs hand-rolled PKCE (→ ADR-B9-3-003).
- **Q-004** — where the T3 self-host gap is recorded, and whether `identity.yaml`
  itself needs an edit (→ ADR-B9-3-004).
- **Q-005** — browser token storage, and what the scaffold refuses to do
  (→ ADR-B9-3-005).
