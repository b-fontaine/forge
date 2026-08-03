# Tasks: b9-3-shared-oidc

<!-- Status: planned -->
<!-- Schema: default -->
<!-- Audit: B.9.3 (docs/new-archetypes-plan.md §5.2, as corrected by cf822fb) -->

TDD-ordered (Article I). Three deliverables: a browser OIDC client on
`oauth4webapi`, a shared provider-configuration artefact, and the documentation of
what this archetype deliberately does **not** deliver.

**The load-bearing ordering constraint — Phase 2 exists because of review finding B1.**
The design's whole justification for taking a dependency is that a correct OIDC client
must validate the ID token. Two successive drafts specified tests that could not catch
its absence. So before the real client is written, an **adversarial bare-`fetch`
implementation** is written deliberately, and `T-L2-002` MUST go **red** against it.
Only then is the real client allowed to exist. A test suite that has never rejected a
wrong implementation has not been shown to work.

---

## Phase 1: RED — the harness and its fixture

- [x] **T1.1** Author `.forge/scripts/tests/b9-3.test.sh` — all L1 rows from
  design.md §Testing Strategy. Hermetic: no network, no npm, no provider.
  [Story: FR-B9-3-001..040, NFR-B9-3-004]
- [x] **T1.2** Author the **L2 stubbed-`fetch` fixture** driving `T-L2-002`'s
  seven-case table (bad signature · wrong `nonce` · wrong `iss` · wrong `aud` ·
  expired `exp` · no `id_token` · **fully valid**). Opt-in behind an env flag, in the
  npm leg alongside `T-L2-001`. [Story: **FR-B9-3-009**, NFR-B9-3-004]
- [x] **T1.3** Run `--level 1` → **verify RED**. **DONE: 4 passed / 23 failed.**
  Expected already-GREEN and confirmed: `T-003` (no `@connectrpc` — b9-2 left it
  clean), `T-004` (no connect-client import), `T-022` (Flutter tree unchanged),
  `T-023` (schema still candidate). **Correction to this task's own prediction**: it
  listed `T-021` as expected-green, which was imprecise — only its `identity.yaml`
  half describes today's state; its "the T3 gap is recorded" half is new work, so the
  row is correctly RED. [Gate: Article I]

## Phase 2: the adversarial proof (B1) — do NOT skip, do NOT reorder

- [x] **T2.1** Write a **deliberately wrong** callback: `discoveryRequest`,
  `generateRandomCodeVerifier`, `calculatePKCECodeChallenge`, redirect,
  `validateAuthResponse` for the state check — then **POST the token endpoint with
  bare `fetch` and keep whatever comes back**. This is precisely the implementation the
  reviewer described, and the one two drafts of the spec would have scored green.
  [Story: **FR-B9-3-009**]
- [x] **T2.2** Run the full suite against it. **`T-L2-002` MUST fail on all six
  rejection rows** while the `fully valid` row passes. If the suite is green, the
  test is decoration and Phase 3 does not start — fix the test, not the clock.
  Capture the red output verbatim; it is the evidence that FR-B9-3-009 is enforced.
  [Gate: **the B1 acceptance proof**]
- [x] **T2.3** **Done, and stronger than planned.** The task assumed the adversarial
  build would live in the templates, so `T-009a-proxy` would simply go red. Since the
  adversarial build was put in a *rendered tree* instead (cleaner — nothing to delete),
  the more useful demonstration was run: a template callback with
  `processAuthorizationCodeResponse` inside an `if (false)` dead branch and a bare
  `fetch` on the live path **passes `T-009a-proxy`**. The "proxy, not a proof" label is
  therefore earned empirically, not asserted — see `evidence.md` P-1.c. Template
  removed after the demonstration; `git status` clean.
- [x] **T2.4** **Delete the adversarial implementation.** It exists to falsify the
  suite, never to ship. `git status` after this task MUST show no trace of it.

## Phase 3: GREEN — the real client

- [x] **T3.1** **Verify-then-pin LIVE.** `oauth4webapi` re-resolved 2026-07-31:
  still 3.8.6 latest, MIT, and `npm install` reports **`added 1 package`** — the
  zero-dependency claim rests on what npm did, not on the packument alone. API
  surface then checked against the shipped `index.d.ts`, including the NEGATIVE
  that `requireIdToken` does not exist on the refresh path. `evidence.md` P-3.
- [x] **T3.2** `oauth4webapi: ^3.8.6` added to `web-pwa/package.json` dependencies.
- [x] **T3.3** Auth module authored: `config` / `provider` / `discovery` /
  `authorize` / `pending` / `session` / `token` / `callback` / `index`.
  `provider.ts` is the ONLY module importing the shared JSON, deliberately kept off
  the authorization path so `authorize`/`callback` take configuration as an argument.
- [x] **T3.4** Callback route authored; `validateAuthResponse` with the pending state
  **string**, then `processAuthorizationCodeResponse` with `expectedNonce` string +
  `requireIdToken: true`, then the URL scrub via `history.replaceState`.
- [x] **T3.5** Token model: 30 s skew matching `auth_token.dart:17`; `toString`/
  `toJSON` render no token material; access + refresh token in memory only.
- [x] **T3.6** Port authored — `login` / `refresh` / `logout` / `getCurrentToken`,
  with `end_session_endpoint` honoured when advertised. `login()` resolves `void`
  and the divergence from the Dart signature is documented at the call site: a
  browser sign-in destroys the document, so a token-returning promise would
  misrepresent the platform.
- [x] **T3.7** **31/31 GREEN** at `--level 12`, including all seven `T-L2-002` rows.

  **Two defects were found by this phase and are recorded rather than absorbed:**
  - A harness bug (`pipefail` + `grep -q` → SIGPIPE 141) that had **silently
    disabled four negatives**, in this suite and in `b9-2`. `evidence.md` P-4.
  - `bad-signature` (T-L2-002 row 1) did not discriminate: `oauth4webapi`
    deliberately skips ID-token signature validation on the code path, per OIDC
    Core §3.1.3.7, so a correct client failed that row too. FR-B9-3-009 is met as
    written by opting into `validateApplicationLevelSignature` rather than
    rewriting the requirement to match the library default. `evidence.md` P-5.

## Phase 4: the shared configuration

- [x] **T4.1** `2.0.0/oidc-provider.json.tmpl` — `issuer` / `scopes` /
  `discoveryUrl` once, `surfaces.{app,web-pwa}` carrying `clientId` + `redirectUri`.
  Additive; the Dart `OidcConfig` untouched.
- [x] **T4.2** Port parity recorded in `index.ts`'s header as a Dart→TS operation
  table, with the one genuine signature divergence named and justified.
- [x] **T4.3** All 11 new files registered in `scaffold-plan.yaml` (61 → 72 entries);
  a real render confirms every one lands with `.tmpl` stripped.
- [x] **T4.4** `b9-2.test.sh` **22/22 green**, T-007 included. T-007's exclusion list
  gained `oidc-provider.json` — a NEW root-level file the legacy render has no
  counterpart for, the same reason `web-pwa/` is excluded. Every Flutter file stays
  compared byte-for-byte, confirmed independently by T-022 and by `git diff`.

## Phase 5: the documentation of what is NOT delivered

- [x] **T5.1** README: the two surfaces hold independent sessions, **not SSO** —
  including why it *looks* like SSO until the provider session expires.
- [x] **T5.2** README: reload cost and the BFF escape hatch named as a backend and
  therefore out of this archetype. **Corrected after review (F2):** the first version
  described recovery as a silent `prompt=none` re-authorization, which is not
  implemented — no `prompt` parameter is sent anywhere. Now states what actually
  happens (an ordinary redirect a live provider cookie usually satisfies silently)
  and names the silent flow as unbuilt.
- [x] **T5.3** README: the T3 self-host obligation transfers to the adopter's
  separately-operated provider. `identity.yaml` **NOT** edited (asserted by T-021).
- [x] **T5.4** Documentation rows GREEN.

## Phase 6: Integration

- [x] **T6.1** `"b9-3.test.sh --level 1"` registered in `forge-ci.yml`. **418 lines**
  against the 420 ceiling — no lockstep bump needed; all four asserting harnesses
  still agree on 420.
- [x] **T6.2** `validate-foundations.sh` → **0 KO**; the schema validates as
  `stage=candidate profile=client-only layers=['app','web-pwa']`.
- [x] **T6.3** Siblings GREEN: b9-1 23/0 · b9-2 22/0 · scaffolder 7/0 · a7 29/0 ·
  t5-1 17/0 · k5 25/0.

## Phase 7: Quality

- [x] **T7.1** `verify.sh` **583 PASS / 0 FAIL / 1 WARN — PASS**;
  `constitution-linter.sh` **86 / 0 / 13 WARN — OVERALL PASS**. Both at baseline.
- [x] **T7.2** Diff scope confirmed: `lib/`, `ios/`, `android/`, `test/`,
  `identity.yaml` and `overlay.sh` all byte-unchanged vs HEAD.
- [x] **T7.3** **Every negative probed**, each mutation guarded by an assertion that
  the mutation actually applied (a non-matching replace is a silent no-op, and
  "suite still green" would prove nothing). All red under mutation: T-003, T-004,
  T-005, T-006, T-009b, T-009c, T-009d, T-018 (both halves), T-009a-state — plus
  b9-2's VAPID negative, which had been dead. Sources restored byte-for-byte
  (sha256 verified).
- [x] **T7.4** REFACTOR: the L2 legs were consolidated onto one rendered+installed
  workspace instead of four, and `_run_fixture` replaced three copies of the
  render/install/copy/run sequence. Everything re-run after: 31/31.
- [x] **T7.5** **Independent review** — two lanes, neither self-approved (Article V).
  Both returned **CHANGES REQUIRED**; all blockers fixed and re-probed (`evidence.md`
  P-9 to P-12).
  - Implementation lane: **F1** `server.fs.allow: [".."]` served the whole project
    over the dev server (confirmed by fetching the Flutter `pubspec.yaml`), narrowed
    to the single file; **F2** README/ADR/`session.ts`/open-questions/tasks all
    described a `prompt=none` silent re-authorization that is not implemented, all
    five corrected. Plus a `specs.md` error asserting the library enforces the ID-token
    signature, three low findings fixed (`token_type` parity, `discoveryUrl` https
    guard, `offline_access` documented), and one pre-existing B.9.2 defect recorded
    (`npm run build` is broken).
  - Harness lane: **F1** `state-mismatch.mjs` could not fail — a renamed export and an
    always-throwing body both scored 2/2; rewritten with an export guard and a positive
    control. Plus T-023 matching any dispatch entry, skipped L2 rows counting as
    passes, and `git diff HEAD` being blind to added files.
  - Found by re-probing between the two lanes: T-011, T-012 and T-016 were satisfied by
    substrings from unrelated files and could not fail (`evidence.md` P-11).
  - Three items the review left optional were closed anyway (`evidence.md` P-13):
    T-007 now asserts the state/nonce are SENT and not merely named; T-L2-004
    instruments `setItem` so a write-then-remove cannot escape; T-001 and T-015
    mutation-probed for the first time.

## Constitution Gate (per task) — summary

- TDD order: harness RED (T1.3) → **adversarial falsification (T2.2)** → real client
  GREEN (T3.7). The middle phase is what distinguishes a suite that works from one
  that merely passes. ✓
- Article III.4: no pin before T3.1 resolves it live; the design recorded 3.8.6 as
  evidence, not as a pin. ✓
- Article IV: additive — the Flutter surface, `identity.yaml` and `overlay.sh`
  untouched. ✓
- Article X.2: public client, no secret; no credential in web storage. ✓
- Article V: T7.5 defers approval to an independent lane. ✓
- **No [TASK VIOLATION].**

## Follow-up left open (later B.9 bricks — NOT this change)

- Rewiring the **Dart** side onto the shared config — blocked by the T-007 byte-freeze;
  needs a brick that can also re-baseline the expected output.
- Decision-tree prose (B.9.4) · bloc generators (B.9.5) · CI `pwa-deploy` (B.9.7) ·
  snapshot (B.9.8) · migration script (B.9.9) · `MIGRATION-PATHS.md` (B.9.10).
- **B.9.11 MUST flip the dispatch entry `status: candidate` → `stable` AND add the CLI
  Trust Harness fixture in the same change** — carried forward from B.9.2.
- **The `pipefail` + `grep -q` defect exists in ~40 other harnesses** (`evidence.md`
  P-4). Almost all are `find … | grep -q .`, whose output never approaches the 64 KiB
  pipe buffer, so they are latent rather than broken — but the failure mode is silent
  for negatives and appears only as a corpus grows. Fixed here in `b9-3` and `b9-2`
  (where this change surfaced it); a repo-wide sweep is a brick of its own.
- **`npm run build` (`qwik build`) is broken in the rendered scaffold** — dies with
  `MODULE_NOT_FOUND: ignore` inside `@builder.io/qwik/dist/cli.cjs` before user code
  loads. Pre-existing from B.9.2, confirmed not caused by b9-3 (`vite build` and
  `vite build --mode ssr` both work). Fixing it means a Qwik pin bump or a workaround
  dependency, which needs a verify-then-pin pass owned by `web-frontend.yaml`.
- **Per-surface `scopes`** — `offline_access` currently reaches the browser surface,
  which cannot persist a refresh token. FR-GL-B9-3-020 declares `scopes` ONCE, so the
  surfaces cannot diverge without a schema change. Documented at the config site
  (evidence P-9 F5); the decision itself is deferred.
- A real browser-level BDD leg for the sign-in scenario — no brick provides a live
  provider today; recorded rather than implied covered.
