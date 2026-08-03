# Open Questions — b9-3-shared-oidc

<!--
Per `.forge/standards/global/open-questions.md` (Article III.4 mechanisation).
Q-NNN sequential, never reused. Resolved questions are kept indefinitely.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: What is the TS client, given Connect-ES cannot perform an OIDC flow?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-3-001)
- **Raised on**: 2026-07-29
- **Raised by**: @bfontaine

### Question

The plan specified a Connect-ES client, which is an RPC transport and cannot execute
`authorization_code + PKCE`. What replaces it?

### Resolution

- **Resolved on**: 2026-07-29
- **Decision**: **`oauth4webapi`** (zero dependencies, WebCrypto).
- **Rationale**: live npm survey — `openid-client` is a layer *on top of*
  `oauth4webapi`; `@auth/qwik` pulls Auth.js, a **server-side** session framework
  needing a secret, wrong for a public client in a `client-only` archetype;
  `oidc-client-ts` is a higher-level session manager (user store, silent renew) where
  this brick needs protocol primitives, and it adds a transitive dependency where
  `oauth4webapi` adds none. `oauth4webapi` is storage-agnostic, so ADR-B9-3-005 stays
  achievable, and adds exactly one package to the installed tree.
- **Correction (self-caught 2026-07-29, before review)**: the first draft rejected
  `oidc-client-ts` for "managing its own storage, fighting FR-B9-3-030". Checked
  against the vendor docs rather than from memory, that is wrong — the store is
  injectable and the library ships `InMemoryWebStorage` for precisely this case. The
  rejection is a judgement about surface area, not a compatibility verdict, and is
  restated as such.
- **Version observed at design**: 3.8.6 — **recorded as evidence, not as a pin**. The
  pin is resolved verify-then-pin LIVE at `/forge:implement` (NFR-B9-3-002).

## Q-002: How does the shared configuration model per-surface client registrations?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-3-002)
- **Raised on**: 2026-07-29
- **Raised by**: @bfontaine

### Question

The two surfaces share a provider but normally need different `clientId` and
`redirectUri`. How is that modelled without duplicating the issuer?

### Resolution

- **Resolved on**: 2026-07-29
- **Decision**: one artefact declaring `issuer` / `scopes` / `discoveryUrl?` **once**,
  plus a `surfaces` map carrying `clientId` + `redirectUri` per surface
  (ADR-B9-3-002).
- **Rationale**: a native custom-scheme redirect and a browser HTTPS redirect are
  normally two client entries at the provider; a single tuple would be wrong for the
  common case.
- **Constraint discovered**: the Dart `OidcConfig` is **byte-frozen** by the B.9.2
  equivalence gate (`b9-2.test.sh` T-007). The shared artefact is therefore purely
  **additive** — rewiring the Dart side to consume it would break T-007 and is
  explicitly deferred to a later brick.

## Q-003: Dependency or hand-rolled PKCE?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-3-003)
- **Raised on**: 2026-07-29
- **Raised by**: @bfontaine

### Question

B.9.2 established `web-pwa` as dependency-lean and the archetype already hand-rolls
base64url. Should the OIDC flow be written directly on `fetch` + `crypto.subtle`?

### Resolution

- **Resolved on**: 2026-07-29
- **Decision**: **use the dependency.** This **reverses the proposal's lean.**
- **Rationale**: a correct OIDC client must validate the ID token — JWKS fetch, key
  selection, JWS signature verification — plus `iss` / `aud` / `exp` / `nonce`. The
  failure mode of getting that wrong is silent acceptance of a forged token, which no
  scaffold test would catch. `oauth4webapi`'s SECURITY.md states these guarantees
  explicitly (state validation, PKCE, nonce validation, issuer validation, token
  signature verification), confirmed via Context7 `/panva/oauth4webapi`.
- **Why this does not contradict B.9.2**: that brick pruned `@connectrpc/*` because
  they served a backend that does not exist — the objection was *uselessness*, not
  dependency count. This dependency does work the archetype needs and cannot safely do
  itself, with zero transitive dependencies.

## Q-004: Where is the T3 self-host gap recorded — does `identity.yaml` change?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-3-004)
- **Raised on**: 2026-07-29
- **Raised by**: @bfontaine

### Question

`identity.yaml` declares `compliance_tier_aware: true` / "T3 requires self-host", but a
`layer_profile: client-only` archetype can self-host nothing. Standard edit, or
scaffold documentation?

### Resolution

- **Resolved on**: 2026-07-29
- **Decision**: **scaffold documentation only; `identity.yaml` is NOT edited**
  (ADR-B9-3-004).
- **Rationale**: the standard is not wrong — it is correctly scoped to archetypes that
  *can* deploy a provider. The gap is a property of this archetype, not a defect in the
  standard, and the honest place to say "your provider must satisfy this, we cannot" is
  where the adopter configures the provider. Editing a shared standard to accommodate
  one archetype's shape would push archetype-specific qualification into a file three
  other archetypes read — the same single-responsibility argument that produced
  `pwa.yaml` in ADR-B9-2-004, applied in the opposite direction.

## Q-005: What does the browser do with tokens?

- **Status**: answered
- **Raised in**: proposal.md (→ ADR-B9-3-005)
- **Raised on**: 2026-07-29
- **Raised by**: @bfontaine

### Question

The native surface has Keychain / encrypted SharedPreferences. The browser has no
equivalent. What does the scaffold persist, and what does it refuse to?

### Resolution

- **Resolved on**: 2026-07-29
- **Decision**: access token **in memory only**; **no refresh token in
  `localStorage`/`sessionStorage`**; session continuity across reload by re-running
  the authorization request (ADR-B9-3-005).
- **CORRECTED 2026-08-03 (implementation review, F2)**: this resolution originally
  said continuity came from a *silent re-authorization* (`prompt=none`). The
  implementation sends no `prompt` parameter and restores nothing on boot, so the
  recovery is an ordinary redirect that a live provider cookie usually satisfies
  without user interaction. The observable outcome is similar, which is how the claim
  survived design review — but the mechanism named did not exist.
- **Cost, stated rather than hidden**: in-memory means a reload drops the session, and
  re-authorization is invisible to the user only while the provider's session cookie
  is reachable —
  which third-party-cookie restrictions increasingly prevent depending on whether the
  provider is same-site. On some deployments a reload will therefore mean a visible
  redirect. That is a real regression against the native surface and the README must
  say so, alongside the escape hatch (a BFF holding the refresh token server-side,
  which is a backend and outside this archetype).
- **Rejected**: refresh token in `localStorage`. It is the easy path and the third
  instance of the pattern this module has already refused twice — stub layers in
  B.9.1, a push server in B.9.2 — where a scaffold claims a capability its
  architecture does not support.

## Q-006: Does anything actually require the ID token to be validated?

- **Status**: answered
- **Raised in**: design review finding **B1** (2026-07-29), pre-implementation
- **Raised on**: 2026-07-29
- **Raised by**: independent reviewer

### Question

ADR-B9-3-001/003 justifies taking a dependency on the grounds that ID-token validation
"is precisely the class of code that should not be hand-written", and states that the
failure mode — silent acceptance of a forged token — is one "no scaffold test would
catch". Did the specification then require that validation, and test for it?

### Resolution

- **Resolved on**: 2026-07-29
- **Answer**: **No, and that was the defect.** Verified before fixing: `specs.md`
  contained **zero** requirements mentioning ID token, JWKS, signature or validation —
  the single grep hit was a Source-Documents row describing the *flagship's* gateway.
  The `nonce` appeared twice, both times on the **sending** side; nothing required it
  to be checked on return. A nonce that is generated and sent but never verified
  provides no replay protection at all.
- **Consequence had it shipped**: an implementer could have satisfied all 23 specified
  tests — discovery, PKCE, state, callback, skew — while POSTing the token endpoint
  with bare `fetch` and accepting whatever came back. The dependency would have been
  installed, pinned and evidenced, and its principal security guarantee never invoked.
  Every project scaffolded from the template would inherit that.
- **Fix**: **FR-B9-3-009** added (JWS signature against the discovered JWKS, plus
  `iss` / `aud` / `exp` / `nonce`, performed through the library's validating entry
  point and explicitly NOT by hand-decoding the JWT); **FR-B9-3-004** extended so the
  nonce is verified on return rather than merely sent; three test rows added
  (**T-009a** call path present and probe-proven, **T-009b** negative against
  hand-decoding, **T-009c** the expected nonce is passed into the validating call).
- **The first fix did NOT close it** (re-check, same day). FR-B9-3-009 and T-009a
  offered `processAuthorizationCodeResponse` **/** `validateAuthResponse` as
  interchangeable. Verified against `oauth4webapi@3.8.6` `index.d.ts`: they are
  different stages — `validateAuthResponse` (`:2258`) takes and returns
  `URLSearchParams` and performs **zero** ID-token validation, while
  `processAuthorizationCodeResponse` (`:1833`) takes the token-endpoint `Response`.
  Since `validateAuthResponse` is the *correct* call for the state half, the natural
  implementation would call it, satisfy the alternation, and still POST the token
  endpoint with bare `fetch` — **the original scenario surviving verbatim, now with a
  green test row pointing at it**. Fixed: the alternation is gone, the state check is
  split into its own row, and two option defaults that silently void the requirement
  are now mandatory — `expectedNonce` must receive the minted **string** (default is
  `expectNoNonce`, i.e. no check and no error) and `requireIdToken: true` must be set.
  A behavioural **T-L2-002** was added as the real proof, since the L1 rows cannot
  catch a validating call wrapped in a swallowing `try/catch`.
- **A SECOND defect in the same row, which I had flagged myself and the reviewer
  confirmed independently**: "is imported AND invoked" is the T-008 problem again. A
  static match proves a token exists in a file, never that the call is on the path the
  callback takes — it passes on a dead branch, an uncalled helper, or a
  computed-then-discarded result. So the row was decoration **twice over**: wrong
  function accepted, and the right one unprovable. T-009a is now an **explicitly
  labelled L1 proxy**, and the proof moved to a behavioural **T-L2-002**.
- **T-L2-002 is a seven-case table over one stubbed-`fetch` fixture** — bad signature,
  wrong `nonce`, wrong `iss`, wrong `aud`, expired `exp`, no `id_token`, and **one
  fully valid case**. The valid row is the one that matters most and the one a hurried
  author drops: without it, all six negatives pass on an implementation that rejects
  *everything*, so a callback that always throws would score a perfect six. It tests
  the **property**, not the call path, which is why decoration cannot satisfy it.
- **Silver lining, verified**: `ProcessTokenResponseOptions` carries only
  `recognizedTokenTypes` plus JWE-decrypt options — there is **no** signature-skipping
  escape hatch. Once the call is on the path with both options set, clauses 1–4 are
  structurally enforced by the library.
- **Why this is recorded rather than quietly patched**: the design named the exact
  failure mode and then failed to require the defence against it. That is the strongest
  argument yet for reviewing design **before** implementation — the fix cost three
  paragraphs; found after B.9.4–B.9.11 built on it, it would have cost a security
  advisory.
