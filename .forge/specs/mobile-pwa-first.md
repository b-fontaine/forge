# Spec: mobile-pwa-first

<!-- Audit: B.9.1 (b9-1-schema) — mobile-pwa-first/2.0.0 archetype scaffold schema. -->
<!-- This file accumulates the archived requirements for the mobile-pwa-first      -->
<!-- archetype (plan §5.2, T8). Source change: `.forge/changes/b9-1-schema/`        -->
<!-- (archived 2026-09-08). First brick of the B.9 chain; B.9.4 (decision tree),    -->
<!-- B.9.5 (Bloc generators), B.9.7 (web CI), B.9.8 (snapshot), B.9.9 (migration),  -->
<!-- B.9.10 (migration paths), B.9.11 (promotion gate) APPEND here as they archive. -->
<!-- `mobile-only / 1.0.0` keeps its own file, `.forge/specs/mobile-only.md`: it    -->
<!-- stays a supported legacy alias until its EOL, so its requirements are NOT      -->
<!-- migrated here and this file does not supersede it.                            -->

**Namespace** : `FR-B9-1-*` / `NFR-B9-1-*` / `ADR-B9-1-*` (+ `FR-B9-2-*` from B.9.2,
`FR-B9-3-*` from B.9.3, and `FR-GL-B9-3-*` for the cross-layer requirements — B.9.1
declares `fr_id_prefix_cross_layer: FR-GL-`, arbitrated by Janus).

**Constitution** : v2.0.0 (no bump — additive). Consumes Article VI.3 `flutter_bloc`
exclusivity as-is (the `no-state-management-alternatives` linter rule has been
CI-blocking repo-wide since B.8.11, which is why plan item **B.9.6 is a no-op**).

**Position** : T8, first of the B.9 incremental chain, and the rename of
`mobile-only / 1.0.0` → `mobile-pwa-first / 2.0.0` (plan §5.2, ARCHITECTURE-TARGET
§6.3). The archetype is `layer_profile: client-only` — no backend, no infrastructure,
no BaaS — which is the property that forced ADR-B9-1-001 and shapes every brick after
it. As of this archive the schema is still `stage: candidate` / `scaffoldable: false`:
`forge init --archetype mobile-pwa-first` refuses cleanly at **exit 3** and renders
nothing (re-probed 2026-09-08). Promotion to `stable` / `scaffoldable: true` is
**B.9.11**, gated on its own ≥25-test harness, mirroring B.6.7 and B.7.6.

---

## B.9.1 — mobile-pwa-first/2.0.0 archetype scaffold schema (archived 2026-09-08)

<!-- Source change: `.forge/changes/b9-1-schema/` — namespace
     FR-B9-1-* / NFR-B9-1-* / ADR-B9-1-*. -->

First brick of the B.9 chain (T8): the `mobile-pwa-first / 2.0.0` **candidate**
archetype scaffold schema every downstream B.9 brick validates against. The
archetype is client-only, so two of the three layer ids required by
`check_versioned_schema_siblings` (B.8.3.b) would be fiction — ADR-B9-1-001 answers
with a `layer_profile:` discriminator defaulting to `multi-layer`, so every schema
authored before B.9.1 keeps its exact meaning unedited while `client-only` keeps the
per-layer contract without the triple. Ships the schema file and that single-site
validator patch only: no template, no scaffolder, no pin, `mobile-only / 1.0.0`
untouched as a legacy alias.

**ADDED**:
- **FR-B9-1-001/002/003** — archetype-scaffold-schema key set (not the legacy
  `archetype:` / `schema_version:` shape of `mobile-only/schema.yaml`);
  `name: mobile-pwa-first`, `version: "2.0.0"`, `stage: candidate` at
  `.forge/schemas/mobile-pwa-first/2.0.0.yaml` (name==dirname, filename↔version);
  `scaffoldable: false`, the B.8.3.b candidate rule.
- **FR-B9-1-004/005/006** — `tdd_enforced` / `bdd_required_for_user_facing` /
  `coverage_threshold: 80` unrelaxed; candidate header block stating what
  `candidate` means with no `web-pwa/` templates, the B.9.11 promotion trigger and
  additivity; `golden_tests_required` carried forward from `tdd-flutter`.
- **FR-B9-1-010/011/012** — both real surfaces modelled as first-class layers,
  `app` (path `.`, Hera) and `web-pwa` (path `web-pwa/`, Iris-Web), each with
  `id`/`path`/`fr_id_prefix`/`primary_agent`; no layer id may name a surface the
  B.9.2 template tree does not scaffold — the requirement that made Q-001 blocking.
- **FR-B9-1-013/014** — `validate-foundations.sh` PASS with no new KO and no
  regression of `verify.sh` / `constitution-linter.sh`; the relaxation
  discriminator MUST default to today's behaviour so `full-stack-monorepo/2.0.0`,
  `ai-native-rag/1.0.0` and `event-driven-eu/1.0.0` validate with no edit.
- **FR-B9-1-020/021** — phases inlined from `tdd-flutter`, never `extends:` (no
  loader resolves it and `phases` would read empty); the proposal → specs →
  features → design → tasks → implementation → review → archive chain preserved,
  `features` before `design`.
- **FR-B9-1-022/023** — a channel-decision gate for the PWA-vs-native choice (ARCH
  §6.3), the prose decision tree left to B.9.4; a `pwa_specifics` block recording
  installability, offline shell, Web Push/VAPID and the iOS fallback as contract
  text, not pins.
- **FR-B9-1-030/031/032** — components declared by reference to their owning
  standard with zero inline pins (`web-frontend.yaml`, `identity.yaml`,
  `observability.yaml`); Service Worker / Web Push (VAPID) / `manifest.json` /
  offline shell have no standard yet and are marked `delivered_by: B.9.2` rather
  than given an invented one; Article VI.3 `flutter_bloc` exclusivity consumed
  as-is (NSMA CI-blocking since B.8.11).
- **FR-B9-1-040/041/042** — `mobile-only/schema.yaml`, its wrapper and its template
  tree are not edited, and `dispatch-table.yml` is not edited (the T.4 alias
  metadata already yields the clean refusal); the 1:1 forward mapping of
  `mobile-only`'s single `app` layer is recorded in `design.md` for B.9.9.

**NFR**:
- **NFR-B9-1-001/002/003** — additive outside the change dir and
  `.forge/scripts/tests/b9-1.test.sh`; `forge init --archetype mobile-pwa-first`
  refuses cleanly and renders nothing, at **exit 2** (dispatch gate) until a later
  brick registers a `mobile-pwa-first:` key, at which point it becomes 3 — the
  spec-phase "exit 3" claim was asserted, never run, and was corrected under review;
  no new FAIL on `verify.sh` / `constitution-linter.sh`, `forge-ci.yml` line budget
  respected.
- **NFR-B9-1-004/005** — harness split L1 static (hermetic, no Docker/network) with
  any live leg L2 opt-in behind an env flag; no component version resolved before
  `/forge:implement` (verify-then-pin).

**ADRs**: **ADR-B9-1-001** — add `layer_profile:` (`multi-layer` default,
`client-only`) and enforce `{backend, frontend, infra}` only for `multi-layer`,
patching one site, `check_versioned_schema_siblings`, in the one committed
`validate-foundations.sh` (the design's "7 copies in lock-step" was wrong: the
`cli/assets/` copy is gitignored bundle output and the 5 `examples/` copies are
B.1-baseline artefacts that never contained the function); the canonical
`FR-GL-001` check at `:125` is untouched. · **ADR-B9-1-002** — ship
`candidate` + `scaffoldable: false`, promotion flip at B.9.11 with the B.9.8
snapshot as its input. · **ADR-B9-1-003** — `channel-decision` is a distinct phase
placed between `specs` and `features`, so BDD scenarios are never written against
an undecided surface. · **ADR-B9-1-004** — layers `app` + `web-pwa`;
`mobile-only`'s `app` maps 1:1 (same id, same path `.`), which is what makes the
B.9.9 migration purely additive. · **ADR-B9-1-005** — components reference-only;
Service Worker / Web Push / VAPID / offline shell deferred to B.9.2 with no
standard invented and `web-frontend.yaml` not edited.

### MODIFIED FR-B9-1-031

<!-- Modified in b9-2-web-pwa change, 2026-09-08. -->

**FR-B9-1-031** — the four PWA components (Service Worker, Web Push/VAPID,
`manifest.json`, offline shell) each carry `standard: pwa.yaml` and no longer carry
`delivered_by:`. Closed by ADR-B9-2-004, which created `pwa.yaml` as a role-named
standard rather than extending `web-frontend.yaml` (a framework-**selection**
standard, orthogonal to PWA capability).

<!-- Previously (as archived by B.9.1): "the four PWA components have no standard   -->
<!-- today and are referenced as `delivered_by: B.9.2` rather than given an         -->
<!-- invented one".                                                                 -->

Test impact recorded at implement: `b9-1.test.sh` T-020 was re-tagged from
FR-B9-1-031 to FR-B9-2-030. This is the **third** b9-1 assertion coupled to B.9.2 —
FR-B9-2-022 names only T-022 and T-L2-001, both flipped by the dispatch-key
registration; T-020 is flipped by this amendment instead.

---

## B.9.2 — web-pwa surface + app-surface port to a scaffold plan (archived 2026-09-08)

<!-- Source change: `.forge/changes/b9-2-web-pwa/` — namespace
     FR-B9-2-* / NFR-B9-2-* / ADR-B9-2-*. -->

Renders the `web-pwa` layer B.9.1 declared but shipped no templates for: a Qwik City
surface carrying a web app manifest, a Service Worker with an offline shell, and
client-side Web Push (VAPID) — without the Connect client the B.8.9 skeleton wires,
since `mobile-pwa-first` has no backend layer (`layer_profile: client-only`). It also
ports the 48-file `mobile-only` `app` surface onto a real `scaffold-plan.yaml` rendered
by `overlay.sh` (ADR-B9-2-002), so the archetype emits the `scaffold-manifest.yaml` that
8 upgrade/migration harnesses key off, registers the `mobile-pwa-first:` dispatch key,
and flips the b9-1 assertions coupled to that registration. ADR-B9-2-004 reverses the
proposal's lean: PWA capability gets its own role-named `pwa.yaml` rather than a section
inside the framework-selection `web-frontend.yaml`. The schema stays `candidate` /
`scaffoldable: false` — promotion remains B.9.11's.

**ADDED**:
- **FR-B9-2-001/002/003** — copy-forward port of all 48 `mobile-only` template files to
  `.forge/templates/archetypes/mobile-pwa-first/2.0.0/`, `mobile-only` byte-unchanged as
  a legacy alias; `{{project_name}}` ×29 / `{{reverse_domain}}` ×10 rewritten to
  `overlay.sh`'s `<project-name>` / `<reverse-domain>`, zero `{{…}}` left in any
  content; `kotlin/{{reverse_domain_path}}` is a *directory* name `overlay.sh` can
  neither substitute nor move, so the relocation is wrapper-side post-render.
- **FR-B9-2-004** — the acceptance criterion of the port: `diff -r` of the ported render
  against the bespoke `bin/forge-init-mobile-only.sh` render, same inputs, must be empty
  over the `app` surface; a claim of equivalence does not stand in for the diff.
- **FR-B9-2-005/006** — `mobile-pwa-first/scaffold-plan.yaml` (`archetype`/`version`/
  `templates[]` with `source`/`target`/`substitute`, parity with `event-driven-eu`),
  covering both surfaces; a render emits `.forge/scaffold-manifest.yaml` (archetype
  version, plan SHA, template-set SHA) that the bespoke renderer never wrote.
- **FR-B9-2-007** — `bin/forge-init-mobile-pwa-first.sh`, ADR-B7-2-007 gated real body:
  reads the schema `stage`/`scaffoldable` itself, refuses exit 3 with a structured
  `[REFUSAL …]` and zero filesystem writes while candidate; the gate opens at B.9.11
  with no edit to the wrapper.
- **FR-B9-2-010** — `web-pwa/` takes the B.8.9 build/config spine (`package.json`,
  `vite.config.ts`, `tsconfig.json`, `qwik.env.d.ts`, `.nvmrc`, `README.md`,
  `src/root.tsx`, `src/entry.ssr.tsx`, `src/routes/index.tsx`) and excludes
  `src/lib/connect-client.ts` and every `@connectrpc/*` dependency.
- **FR-B9-2-011/012/013** — manifest with `name`/`short_name`/`start_url`/`display`/
  `theme_color`/`background_color` + ≥1 icon (Android/desktop installability); a
  registered Service Worker serving a navigable offline shell (BDD-required); push
  subscription client-side only — no push server, no VAPID keygen, key provenance
  documented as an adopter responsibility.
- **FR-B9-2-014** — every `web-pwa` pin resolved live at implement, none inherited from
  `web-frontend.yaml` (its `P30D` cadence had lapsed), with the Qwik peer range vs
  Vite 8 re-checked specifically.
- **FR-B9-2-015** — no Flutter state-management library on this surface; Article VI.3
  stays Flutter-scoped (the B.9.1 F7 correction).
- **FR-B9-2-020/021/022** — top-level `mobile-pwa-first:` key in `dispatch-table.yml`
  (`mobile-only:`'s `status: legacy_alias` / `target:` / `migration:` preserved), which
  moves `forge init --archetype mobile-pwa-first` from exit 2 (dispatch gate) to exit 3
  (`init.ts:238`, no scaffoldable version); the coupled `b9-1.test.sh` assertions
  flip in this same change.
- **FR-B9-2-023** — `.forge/schemas/mobile-pwa-first/2.0.0.yaml` stays
  `stage: candidate` / `scaffoldable: false`; nothing renders.
- **FR-B9-2-030/031** — new role-named `.forge/standards/pwa.yaml` governing
  installability, offline behaviour and push delivery, resolving B.9.1's four
  `delivered_by: B.9.2` forward-pointers; 8-field frontmatter, `index.yml` entry and
  `REVIEW.md` ledger rows for both `pwa.yaml` and the `web-frontend.yaml` pin refresh.

**NFR**:
- **NFR-B9-2-001/002** — `overlay.sh` untouched (shared by three archetypes and 8+
  harnesses) and `mobile-only/**`, its wrapper and its dispatch entry untouched.
- **NFR-B9-2-003/004/005** — no new FAIL in `verify.sh`, `constitution-linter.sh` or the
  `b9-1`/`scaffolder`/`a7`/`b5`/`t5-1` siblings; `forge-ci.yml` within the NFR-CI-002
  ceiling of 420 lines; `b9-2.test.sh` L1 hermetic (bash + rsync + python3, the
  byte-equivalence render included), any `npm install`/build leg L2 opt-in.

**ADRs**: ADR-B9-2-001 — reuse the B.8.9 spine but drop `connect-client.ts` as three
edits (omit the file, rewrite `routes/index.tsx` backend-free, prune the Connect deps) ·
ADR-B9-2-002 — one `scaffold-plan.yaml` for both surfaces through `overlay.sh`, chosen
for the `scaffold-manifest.yaml` the 8 upgrade/migration harnesses require ·
ADR-B9-2-003 — pins verified live at implement, ledger records match *or* drift (it was
drift: qwik/qwik-city 1.20.0 held, `vite` max-in-range moved 7.3.5 → 7.3.6, Qwik's
`vite: >=5 <8` peer range unchanged so Vite 8 stays excluded) · ADR-B9-2-004 — a new
role-named `pwa.yaml`, not a PWA section in `web-frontend.yaml`, because PWA capability
is orthogonal to framework selection · ADR-B9-2-005 — Web Push is client-side
subscription only; a push server would recreate at template level the backend
`layer_profile: client-only` denies · ADR-B9-2-006 — the Kotlin package relocation stays
in the wrapper; restructuring the Android template onto a fixed directory would break
FR-B9-2-004 byte-equivalence by construction, so the decision is forced, not preferred.

---

## B.9.3 — browser OIDC client + shared provider config (archived 2026-09-08)

<!-- Source change: `.forge/changes/b9-3-shared-oidc/` — namespace FR-B9-3-* / NFR-B9-3-* / ADR-B9-3-*. -->

Gives the `web-pwa` surface an `authorization_code` + PKCE client against the same
provider as the Flutter `app` surface, and declares that provider once for both. The
plan's wording — a TypeScript **Connect-ES** client — is a category error: Connect-ES
is an RPC transport for a backend this `client-only` archetype does not have, and
B.9.2 pruned `@connectrpc/*` (ADR-B9-2-001); recorded as superseded, not
reinterpreted. ADR-B9-3-001/003 reverse the proposal's hand-rolled lean onto
`oauth4webapi` (0 transitive deps), because ID-token validation is not code to
hand-write. First cross-layer change here: Janus arbitrates, `FR-GL-` ids apply.

**ADDED**:
- **FR-B9-3-001/002/003** — public client (no secret), PKCE with
  `code_challenge_method=S256`, built on `oauth4webapi` and explicitly **not** on
  `@connectrpc/*` (negative test, so reversing B.9.2 fails loudly); verifier and
  challenge from `crypto.getRandomValues` + `crypto.subtle.digest`, `Math.random`
  absent from the auth path.
- **FR-B9-3-004** — a fresh `state` and `nonce` per authorization request; the
  callback rejects a mismatched `state` **before** exchanging the code, and the
  `nonce` is checked against the ID-token claim (an earlier draft of the spec
  required only the sending half, which is no replay protection).
- **FR-B9-3-005/006/007/008** — a callback route that exchanges the code and leaves
  no `code`/`state`/token in the address bar; discovery from
  `<issuer>/.well-known/openid-configuration` with an optional `discoveryUrl`
  override, no per-provider hard-coded endpoints; refresh plus RP-initiated logout
  when `end_session_endpoint` is advertised; 30 s expiry skew matching
  `auth_token.dart`.
- **FR-B9-3-009** — the ID token is validated via `processAuthorizationCodeResponse`
  with `expectedNonce` and `requireIdToken: true` (iss, aud, exp, nonce), never by
  hand-decoding and never via `validateAuthResponse`, which is a different stage;
  the JWS signature takes a separate `validateApplicationLevelSignature` call,
  since the library deliberately skips it on the code path (OIDC Core §3.1.3.7,
  TLS-secured channel). Added at design review — the dependency's own justification
  had no requirement behind it — and probe-proven by the L2 rejection table.
- **FR-GL-B9-3-020/021** — one configuration artefact declaring `issuer`, `scopes`
  and the optional `discoveryUrl` once, with `clientId` + `redirectUri` **per
  surface** (custom-scheme for `app`, https for `web-pwa`); the Vite
  `server.fs.allow` exposing it was narrowed at review from `[".."]`, which served
  the whole project, to that single file.
- **FR-GL-B9-3-022/023** — the TS port exposes the same four operations as the Dart
  `AuthRepository` (`login`/`refresh`/`logout`/`getCurrentToken`), and the scaffold
  states plainly that the surfaces hold independent sessions — this is not SSO.
- **FR-B9-3-030/031/032** — no refresh token in `localStorage` or `sessionStorage`
  (access token in memory only); the README states what the browser session is, its
  reload cost, and the BFF an adopter adds instead; the token model exposes no token
  material through its default string form.
- **FR-B9-3-040** — the scaffold records that `identity.yaml`'s "T3 requires
  self-host" is met by the adopter's separately operated provider: a `client-only`
  archetype hosts nothing.

**NFR**:
- **NFR-B9-3-001/006** — `lib/`, `ios/`, `android/`, `test/` byte-unchanged (the
  B.9.2 equivalence gate `b9-2` T-007 stays green); the archetype stays
  `stage: candidate` / `scaffoldable: false`, dispatch entry `status: candidate`.
- **NFR-B9-3-002/003/004/005** — `oauth4webapi` resolved verify-then-pin live with
  evidence; no new FAIL in `verify.sh` (582 PASS / 0 FAIL / 1 WARN baseline),
  `constitution-linter.sh` or the sibling suites; `b9-3.test.sh` L1 hermetic with the
  rendered-surface `tsc` typecheck at L2 opt-in; `forge-ci.yml` inside the
  NFR-CI-002 ceiling of 420 lines.

**ADRs**: ADR-B9-3-001/003 — build on `oauth4webapi` (0 transitive deps), reversing
the hand-rolled lean; `oidc-client-ts`, `openid-client` and `@auth/qwik` rejected on
recorded grounds · ADR-B9-3-002 — one issuer/scopes block plus a `surfaces` map of
per-surface `clientId`/`redirectUri`; the Dart `OidcConfig` is byte-frozen, so the
artefact is additive and rewiring the Dart side is deferred · ADR-B9-3-004 —
`identity.yaml` is NOT edited: archetype-specific qualification does not belong in a
standard three other archetypes read · ADR-B9-3-005 — access token in memory, no
refresh token in web storage, the reload cost stated; the `prompt=none` silent
re-authorization the ADR first claimed was corrected at implement as unbuilt.
