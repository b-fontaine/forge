# Specifications: b9-3-shared-oidc

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.9.3 (docs/new-archetypes-plan.md §5.2, as corrected 2026-07-29 by cf822fb) -->

**Namespace** : `FR-B9-3-*` / `NFR-B9-3-*` / `ADR-B9-3-*`. Cross-layer identifiers use
the archetype's `fr_id_prefix_cross_layer: FR-GL-` where a requirement binds **both**
surfaces.
**Constitution** : v2.0.0, unchanged, no amendment.
**Governing articles** : I (TDD), II (BDD — a login flow is user-facing),
III.1/III.2, III.4 (Anti-Hallucination / verify-then-pin), IV (delta-based),
X.2 (no committed secrets).
**Cross-layer**: this is the archetype's first change spanning `app` + `web-pwa`;
**Janus** arbitrates, Hera owns the Dart side, Iris-Web the TS side.

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §5.2 B.9.3, **as corrected 2026-07-29** — the original specified a Connect-ES client, which cannot perform an OIDC flow |
| **Layer contract** | `mobile-pwa-first/2.0.0.yaml` — `app` at `.` (Hera), `web-pwa` at `web-pwa/` (Iris-Web), `layer_profile: client-only` |
| **Dart port (observed)** | `lib/domain/auth/auth_repository.dart` — `AuthRepository{ login(), refresh(String), logout(), getCurrentToken() }` |
| **Dart config (observed)** | `lib/infrastructure/auth/oidc_config.dart` — `OidcConfig{issuer, clientId, redirectUri, scopes, discoveryUrl?}`; `discoveryUrl` falls back to `<issuer>/.well-known/openid-configuration`; default scopes `[openid, profile, email, offline_access]` |
| **Dart token (observed)** | `lib/domain/auth/auth_token.dart` — `AuthToken{accessToken, refreshToken, expiresAt, tokenType='Bearer'}`, `isExpired` with a **30 s** skew, and `stringify => false` so tokens never land in logs |
| **Dart impl (observed)** | `lib/data/auth/auth_repository_impl.dart` over `flutter_appauth` (PKCE) |
| **Native storage (observed)** | `lib/infrastructure/storage/secure_storage_adapter.dart` — Keychain `first_unlock_this_device` / `synchronizable: false`, Android `encryptedSharedPreferences: true`. **The browser has no equivalent** (→ FR-B9-3-030) |
| **web-pwa routes (observed)** | `src/routes/index.tsx`, `src/routes/offline/index.tsx`, `src/routes/service-worker.ts` |
| **Precedent** | **None.** No browser OIDC client exists anywhere in this repo; the flagship enforces OIDC server-side at the Envoy gateway (`security-policy.yaml`, `remoteJWKS`). This brick is net-new |
| **Identity standard** | `identity.yaml` v1.1.0 — `default: zitadel`, Helm/image pins, `compliance_tier_aware: true` ("T3 requires self-host") — **server-shaped**, see FR-B9-3-040 |
| **Release target** | maintainer-set |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — The browser OIDC client (FR-B9-3-001 → 008)

##### FR-B9-3-001 — authorization_code + PKCE, public client
The `web-pwa` surface MUST implement OIDC Authorization Code flow with PKCE
(`code_challenge_method=S256`). It MUST be a **public client**: no client secret is
used, requested or scaffolded (Article X.2).

##### FR-B9-3-002 — NOT Connect-ES
The client MUST NOT be built on `@connectrpc/*`. Those packages were removed from
`web-pwa/package.json` by ADR-B9-2-001 because this archetype has no backend, and
they cannot perform an OIDC flow regardless. **Asserted by a negative test** —
reversing B.9.2 must fail loudly, not silently.

##### FR-B9-3-003 — verifier and challenge generated with the platform CSPRNG
`code_verifier` MUST be generated from `crypto.getRandomValues`, and the
`code_challenge` MUST be its SHA-256 via `crypto.subtle.digest`, base64url-encoded
without padding. `Math.random` MUST NOT appear in the auth path.

##### FR-B9-3-004 — CSRF and replay parameters, both checked on return
Each authorization request MUST carry a fresh `state` and a fresh `nonce`, both
CSPRNG-generated. The callback MUST reject a response whose `state` does not match
the pending request, **before** exchanging the code. The `nonce` MUST additionally be
**verified against the `nonce` claim of the returned ID token** (FR-B9-3-009) — a
nonce that is generated and sent but never checked on return provides **no** replay
protection, and an earlier draft of this spec required only the sending half.

##### FR-B9-3-005 — a callback route
A dedicated route MUST handle the redirect, exchange the code at the token endpoint,
and route the user onward. It MUST NOT leave `code`, `state` or tokens in the address
bar after completion.

##### FR-B9-3-006 — discovery parity with the Dart side
The client MUST resolve endpoints from `<issuer>/.well-known/openid-configuration`,
with an optional explicit `discoveryUrl` override — the same rule
`oidc_config.dart:29` already applies. Endpoints MUST NOT be hard-coded per provider.

##### FR-B9-3-007 — refresh and logout
The client MUST support refresh via `refresh_token` when the provider issues one, and
a logout that clears local session state and, when the provider advertises an
`end_session_endpoint`, performs RP-initiated logout.

##### FR-B9-3-008 — token expiry skew parity
The TS token model MUST treat a token as expired **30 seconds before** its actual
expiry, matching `auth_token.dart:17`. A divergence here produces surface-dependent
auth bugs that are painful to diagnose.

##### FR-B9-3-009 — the ID token MUST be validated *(added after design review, finding B1)*
The token response MUST NOT be accepted until its ID token has been validated:

1. **JWS signature** verified against the JWKS discovered from the authorization
   server metadata — not merely decoded;
2. **`iss`** equals the configured issuer;
3. **`aud`** contains this surface's `clientId`;
4. **`exp`** in the future (with the FR-B9-3-008 skew);
5. **`nonce`** equals the value minted for this authorization request
   (FR-B9-3-004).

The implementation MUST perform this through **`processAuthorizationCodeResponse`**
specifically — **not** by hand-decoding the JWT, and **not** via `validateAuthResponse`,
which is a different stage entirely. Verified against `oauth4webapi@3.8.6`'s
`index.d.ts`:

```ts
:2258  validateAuthResponse(as, client, parameters: URLSearchParams | URL, expectedState?): URLSearchParams
:1833  processAuthorizationCodeResponse(as, client, response: Response, options?): Promise<TokenEndpointResponse>
```

`validateAuthResponse` takes and returns **URL parameters**; it never sees the token
response and performs **zero** ID-token validation. It is nonetheless the correct call
for FR-B9-3-004's *state* half — which is exactly why offering the two as
interchangeable was dangerous: the natural implementation calls it for the state check,
satisfies a test worded as an alternation, and can still POST the token endpoint with
bare `fetch`. (`validateCodeIdTokenResponse` / `validateDetachedSignatureResponse` are
legitimate alternatives — they take `expectedNonce` as a **required** positional.
`validateAuthResponse` is not one.)

Two options of that call are **required**, because their defaults silently disable
clauses of this requirement:

- **`expectedNonce`** MUST receive the minted nonce **string**. It is optional and its
  documented default is `expectNoNonce` — omitting it performs no nonce validation and
  raises no error, silently voiding clause 5.
- **`requireIdToken: true`** MUST be set. Unset, a provider returning no ID token
  resolves the call happily and nothing is validated, contradicting this requirement's
  own opening sentence.

**CORRECTED 2026-08-03 (implementation review, finding F2-doc).** This paragraph
previously read: *"No signature-skipping escape hatch exists on this path … clauses
1–4 are structurally enforced by the library."* That was wrong about clause 1, and
wrong in a way that inverted the facts. There is no signature-skipping *option*
because there is no signature *check* to skip: `processAuthorizationCodeResponse` →
`processGenericAccessTokenResponse` → `validateJwt` parses the ID token header,
checks `alg`, and validates claims — it never verifies a signature.

That is deliberate on the library's part and correct per OIDC Core §3.1.3.7 item 6:
the token arrives over a direct TLS channel, so TLS server validation may stand in for
the signature check. `oauth4webapi` exposes signature verification separately as
`validateApplicationLevelSignature` and documents it as opt-in.

So the accurate statement is:

- clauses **2–5** (issuer, audience, expiry, nonce) are structurally enforced by
  `processAuthorizationCodeResponse` once `expectedNonce` and `requireIdToken` are
  passed as above;
- clause **1** (signature) requires an **explicit additional call**, which the
  implementation makes — `await validateApplicationLevelSignature(as, response)`
  before the token is returned.

This requirement is met as written; what was wrong was the reasoning about *how*. The
error mattered: it is the same mistake recorded as `evidence.md` P-5, where a
seven-case rejection table scored a correct client as failing because its
`bad-signature` row assumed the library did this. A spec that mis-describes its
dependency's guarantees produces tests that assert the wrong thing.

**This requirement is the entire justification for ADR-B9-3-001/003.** The design
argues that ID-token validation "is precisely the class of code that should not be
hand-written" and takes a dependency on that basis — while an earlier draft of this
spec required no validation anywhere and specified no test for it. An implementer
could have satisfied every other requirement, installed the dependency, and never
invoked the guarantee it was chosen for. Recorded rather than quietly patched: the
gap was found at design review, before any code existed.

#### Cluster 2 — What "shared" means (FR-GL-B9-3-020 → 023, cross-layer)

##### FR-GL-B9-3-020 — one provider configuration artefact
A single configuration artefact MUST declare the provider `issuer`, the requested
`scopes` and the optional `discoveryUrl` **once**, consumed by both surfaces. The two
surfaces MUST NOT carry independent copies of the issuer.

##### FR-GL-B9-3-021 — per-surface client registration
That artefact MUST model `clientId` and `redirectUri` **per surface**, not as one
shared pair. A native custom-scheme redirect (`<reverse-domain>://callback`) and a
browser `https://` redirect are normally two client entries at the provider. A
single-tuple model would be wrong for the common case.

##### FR-GL-B9-3-022 — documented port parity
The TS client MUST expose the same four operations as the Dart `AuthRepository` —
`login`, `refresh`, `logout`, `getCurrentToken` — and the parity MUST be recorded in
a form a reviewer can check. Drift between the two ports is the failure mode this
brick exists to prevent.

##### FR-GL-B9-3-023 — no claim of shared sessions
Scaffolded documentation MUST state plainly that the two surfaces hold **independent
sessions**: a token obtained in the native app is not available to the PWA, and vice
versa. This is **not** single sign-on, and the scaffold MUST NOT imply it is.

#### Cluster 3 — Browser storage, stated as a limitation (FR-B9-3-030 → 032)

##### FR-B9-3-030 — no refresh token in `localStorage` or `sessionStorage`
The refresh token MUST NOT be persisted to `localStorage` or `sessionStorage`. The
native surface uses Keychain / encrypted SharedPreferences
(`secure_storage_adapter.dart`); the browser has no equivalent, and pretending
otherwise would be the fiction pattern this module has already refused twice
(stub layers in B.9.1, a push server in B.9.2).

##### FR-B9-3-031 — the limitation is documented, not hidden
The `web-pwa` README MUST state what the browser session actually is, what it is not,
and what an adopter must add (a BFF or provider-side session) if they need
stronger persistence than the scaffold provides.

##### FR-B9-3-032 — tokens never logged
The TS token model MUST NOT expose token material through its default string
representation, mirroring `auth_token.dart`'s `stringify => false`.

#### Cluster 4 — The T3 gap (FR-B9-3-040)

##### FR-B9-3-040 — record that T3 self-host is out of this archetype's reach
`identity.yaml` declares `compliance_tier_aware: true` with "T3 requires self-host",
but `mobile-pwa-first` is `layer_profile: client-only` and has no infra layer: it can
self-host nothing. The scaffold MUST record that a T3 adopter satisfies this
obligation through their **separately operated** provider deployment, not through
anything this archetype renders. Whether `identity.yaml` itself is edited is
ADR-B9-3-004's call.

### BDD Acceptance Criteria (Article II)

```gherkin
Scenario: a user signs in to the PWA channel
  Given a scaffolded mobile-pwa-first project with a configured OIDC provider
  And the user is not signed in on the web-pwa surface
  When the user starts sign-in
  Then the browser is redirected to the provider's authorization endpoint
  And the request carries a code_challenge with method S256
  And the request carries a fresh state and nonce

Scenario: the callback rejects a mismatched state
  Given a sign-in has been started and a state is pending
  When the provider redirects back with a different state value
  Then the authorization code is NOT exchanged
  And the user is shown an authentication error

Scenario: the two surfaces hold independent sessions
  Given a user signed in on the native app surface
  When the same user opens the web-pwa surface
  Then the web-pwa surface does not consider the user signed in
  And the documentation states this is expected, not a defect
```

### Non-Functional Requirements

##### NFR-B9-3-001 — the Flutter surface is untouched
No file under `lib/`, `ios/`, `android/` or `test/` may change. The `app` surface is
byte-frozen by the B.9.2 equivalence gate (`b9-2.test.sh` T-007), which MUST stay
green.

##### NFR-B9-3-002 — dependency discipline
If the flow is implemented without a runtime dependency, `web-pwa/package.json`
`dependencies` MUST stay exactly as B.9.2 left it. If a library is chosen instead, it
MUST be resolved **verify-then-pin LIVE** at implement with evidence recorded — never
copied from memory or from a stale standard (ADR-B9-3-003).

##### NFR-B9-3-003 — zero regression
`verify.sh`, `constitution-linter.sh` and the sibling suites (`b9-1`, `b9-2`,
`scaffolder`, `a7`, `t5-1`, `k5`) MUST show no new FAIL. Baseline **measured with
this dossier in place**: verify.sh **582 PASS / 0 FAIL / 1 WARN**; linter OVERALL
PASS. (An earlier draft recorded 580 — the count before the dossier's own spec files
were counted.)

##### NFR-B9-3-004 — harness level split
`b9-3.test.sh` L1 MUST be hermetic — no network, no npm, no provider. The `tsc`
typecheck of the rendered surface belongs to L2 opt-in, as in B.9.2, where that leg
caught a real template bug the static asserts could not see.

##### NFR-B9-3-005 — CI budget in lockstep
Registering `b9-3.test.sh` MUST respect the NFR-CI-002 ceiling of **420** lines on
`forge-ci.yml` (currently **415**). If it overflows, the ceiling is asserted in
`b6-8`, `c1`, `t5-1` and `t5-otel-live-run` and they bump together.

##### NFR-B9-3-006 — the archetype stays candidate
`mobile-pwa-first/2.0.0.yaml` MUST remain `stage: candidate` / `scaffoldable: false`;
promotion is B.9.11's, and the dispatch entry keeps `status: candidate`.

---

## ADRs (seeded — resolved at `/forge:design`)

| ADR | Question | Lean |
|-----|----------|------|
| **ADR-B9-3-001** | What the TS client is, given Connect-ES cannot do OIDC | Dependency-free PKCE on `fetch` + `crypto.subtle`, or one audited library — decide on live evidence |
| **ADR-B9-3-002** | How the shared configuration models per-surface registrations | One issuer/scopes block + per-surface `clientId`/`redirectUri` |
| **ADR-B9-3-003** | Dependency vs hand-rolled | Prefer zero runtime dependency; verify-then-pin if a library wins |
| **ADR-B9-3-004** | Where the T3 gap is recorded; does `identity.yaml` change | Scaffold docs at minimum; standard edit is a design call |
| **ADR-B9-3-005** | Browser token storage | In-memory access token; **no** refresh token in web storage |

## Acceptance Criteria

1. `b9-3.test.sh` GREEN at `--level 1`; the `@connectrpc` negative fails when reversed.
1b. **The ID-token validation call path is asserted and probe-proven** (FR-B9-3-009) —
   removing the validating call MUST turn the suite red.
2. The three BDD scenarios are realised by tests or explicitly recorded as deferred
   with the gap named — not silently unimplemented.
3. `b9-2.test.sh` T-007 still GREEN — the `app` surface is byte-unchanged.
4. `verify.sh` and `constitution-linter.sh` show no new FAIL.
5. No secret, and no refresh token in web storage.
6. Every pin, if any, resolved live with evidence.
