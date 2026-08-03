# Evidence — b9-3-shared-oidc

<!-- Audit: B.9.3 (b9-3-shared-oidc) -->

## P-1 — the B1 acceptance proof (Phase 2, 2026-07-31)

Design review finding **B1** was that nothing in the spec required ID-token
validation, while the whole dependency decision rested on it. The reviewer proposed a
single check: *"write the bare-`fetch` implementation and confirm the suite goes red.
Right now it would go green, which is the whole finding."* The plan promoted that to a
mandatory phase, executed **before** the real client was allowed to exist.

### P-1.a — the adversarial implementation

Written into a **rendered tree**, never into the templates, so nothing had to be
deleted afterwards. It does discovery, `generateRandomCodeVerifier`,
`calculatePKCECodeChallenge` and `validateAuthResponse` for the state check — all
correct — then POSTs the token endpoint with bare `fetch` and returns `res.json()`
unvalidated. This is precisely the implementation the review described.

### P-1.b — T-L2-002 against it

```
FAIL  bad-signature  expected=reject got=accept
FAIL  wrong-nonce    expected=reject got=accept
FAIL  wrong-issuer   expected=reject got=accept
FAIL  wrong-audience expected=reject got=accept
FAIL  expired        expected=reject got=accept
FAIL  no-id-token    expected=reject got=accept
OK    valid          expected=accept got=accept
T-L2-002: 6 case(s) wrong — FR-B9-3-009 is NOT enforced
```

Six rejection rows fail; the **valid row passes**. That combination is what makes the
result meaningful: the fixture is not rejecting everything (which would score six
false positives), and it is not accepting everything (which would score one). It
discriminates.

Note what row 1 means concretely: the bare-`fetch` implementation **accepted an ID
token signed with a key absent from the provider's JWKS**. That is the silent
forged-token acceptance the design named — and the failure mode two drafts of this
spec could not detect.

### P-1.c — the L1 proxy is genuinely weaker, demonstrated

`T-009a-proxy` was labelled "proxy, not a proof" on the reviewer's argument that a
static match cannot show a call is on the live path. Verified empirically rather than
taken on trust — a template whose callback reads:

```ts
if (false as boolean) {
  await oauth.processAuthorizationCodeResponse(null as any, null as any, null as any);
}
const res = await fetch('https://issuer.example.test/token', { method: 'POST' });
return await res.json();
```

**passes `T-009a-proxy`.** The identifier is present, the dead branch never executes,
and the live path bare-fetches. The label is earned, and T-L2-002 is the only
assertion in the suite that rejects this.

### P-1.d — a fixture defect found and fixed while proving it

The first run failed with `ERR_MODULE_NOT_FOUND` on `jose`. Cause: Node ESM resolves
bare specifiers from the **importing file's** location upward, and the fixture was
being executed in place from the Forge repo while `jose` lived in the rendered
project's `node_modules`. Fixed by copying the fixture into the rendered workspace
before running it. Recorded because the failure looked at first like an implementation
error and was actually a test-harness error — the distinction the run output made
obvious only after reading it rather than assuming.

**`jose` and `tsx` are test-only.** They are installed with `--no-save` into the
rendered workspace to run the fixture and are **not** template dependencies; the
template's own dependency set is asserted by T-002 and T-003.

## P-2 — RED baseline (Phase 1, T1.3)

`b9-3.test.sh --level 1` → **4 passed / 23 failed**. The four green rows are exactly
those describing today's state: `T-003` (no `@connectrpc` — B.9.2 left it clean),
`T-004` (no connect-client import), `T-022` (Flutter tree unchanged), `T-023` (schema
still candidate).

`T-021` was predicted green by the plan and is correctly **red**: only its
`identity.yaml`-unchanged half describes today's state; its "the T3 gap is recorded"
half is new work. The prediction was imprecise and is corrected in `tasks.md` rather
than left standing.

## P-3 — verify-then-pin LIVE (Phase 3, T3.1, 2026-07-31)

`oauth4webapi` re-resolved against the registry at implement time, three days after
the design observed it. Article III.4: the design recorded 3.8.6 as *evidence*, never
as a pin.

- `npm view oauth4webapi dist-tags` → `latest = 3.8.6` (unchanged), 77 versions
- license MIT; `integrity sha512-iwemM91xz8nry…`
- the packument has **no** `dependencies`, `peerDependencies`, `optionalDependencies`
  or `bundleDependencies` key at all — checked by key presence, not by an empty print
- installed into a scratch project: **`added 1 package`**, `node_modules/` contains
  exactly `oauth4webapi`

Registry metadata and the installed tree agree, so the zero-dependency claim rests on
what npm actually did rather than on what the packument says.

The API surface was then checked against the shipped `build/index.d.ts` rather than
from memory — this brick has already been bitten twice by the opposite. Confirmed:
`expectedNonce?: string | typeof expectNoNonce` with the library's own comment
*"Default is expectNoNonce"*; `requireIdToken?: boolean`, optional; `validateAuthResponse`
**synchronous**, returning `URLSearchParams`; `None()` for the public client. Also
confirmed **negatively**: `ProcessTokenResponseOptions` carries only
`recognizedTokenTypes`, so `requireIdToken` does **not** exist on the refresh path and
is not passed there.

## P-4 — a harness defect that silently disabled four negatives (Phase 3)

With the modules written, 15 of 27 L1 rows failed — including `S256`, which is
literally present in `authorize.ts`. The cause was in the harness, not the code.

`set -o pipefail` + `printf '%s' "$out" | grep -q PATTERN`: `grep -q` exits at the
first match, `printf` is still writing, takes SIGPIPE and exits 141, and `pipefail`
promotes that to the pipeline's status. Measured directly on the real 84 378-byte
stream:

```
  S256                               pipe-status=141  herestring-status=0
  processAuthorizationCodeResponse   pipe-status=141  herestring-status=0
  replaceState                       pipe-status=0    herestring-status=0
  PIPESTATUS=(141 0)      <- printf killed, grep matched
```

`replaceState` returns 0 only because it lives in the LAST file of the stream, so
grep drains it and `printf` finishes — which is why the failures looked random
across rows rather than systematic.

**The direction that matters is the silent one.** A positive (`grep -q X || fail`)
announces itself by failing loudly. A negative (`grep -q X && fail`) does the
opposite: the violation matches, the pipeline still exits non-zero, the `&&` never
fires, and the check passes having detected nothing. Demonstrated on the real stream
with `Math.random` deliberately injected into the auth modules:

```
Math.random IS present in the stream: 1 hit(s)
--- OLD form (printf | grep -q ... && fail) ---
   -> T-006 would PASS: the violation was NOT reported
--- NEW form (here-string) ---
   -> violation reported
```

Four negatives were dead this way — T-005 `plain`, T-006 `Math.random`,
T-009a-state `skipStateCheck`, T-009c `expectNoNonce`. The 25 occurrences found at
the time were converted
to `grep -qE "…" <<<"$out"`, and each negative then mutation-probed:

```
T-006 Math.random                    ✗ _test_b93_l1_006_csprng
T-005 plain challenge                ✗ _test_b93_l1_005_s256
T-009a-state skipState               ✗ _test_b93_l1_009a_state_string
T-009c expectNoNonce                 ✗ _test_b93_l1_009c_expected_nonce_string
T-009b hand-decode                   ✗ _test_b93_l1_009b_neg_no_hand_decode
```

It was invisible during Phase 1 RED because the files under test did not exist, so
every row failed for an unrelated reason. It appeared exactly when the suite began
to be trusted.

**The same defect was found in `b9-2.test.sh`**, surfaced by this change: appending
~80 lines to `README.md.tmpl` pushed the web-pwa stream past the buffer. T-017's
`PushManager` positive started failing, and its VAPID-keygen negative
(`if _stripped_stream … | grep -q …`) had stopped firing. Both fixed with process
substitution, and the VAPID negative re-probed in both directions: red with a
`generateVAPIDKeys(` file injected, green with it removed.

The pattern exists in ~40 other harnesses, almost all as `find … | grep -q .` whose
output never approaches the buffer. Not swept here — out of scope for this brick, and
recorded in §Follow-up for the maintainer to scope.

## P-5 — CORRECTION to P-1.b: the `bad-signature` row did not discriminate

P-1.b (Phase 2) reported that the adversarial bare-`fetch` implementation "accepted an
ID token signed with a key absent from the provider's JWKS", and called that "the
silent forged-token acceptance the design named". **That reading was wrong**, and the
real client is what exposed it: the first correct implementation *also* accepted that
token, failing the same row.

`oauth4webapi` deliberately does not verify the ID token's signature in
`processAuthorizationCodeResponse`. Its own documentation:

> Validating signatures of JWTs received via direct communication between the Client
> and a TLS-secured Endpoint (which it is here) is not mandatory since the TLS server
> validation is used to validate the issuer instead of checking the token signature.
> You only need to use this method for non-repudiation purposes.

That is OIDC Core §3.1.3.7 item 6, and the library is right. So row 1, as originally
written, separated nothing: it failed against "no validation at all" *and* against
"correct, spec-compliant validation". The other six rows carried the whole proof.

Resolved by making the implementation meet FR-B9-3-009 as specified rather than
rewriting the requirement to match the library default: `callback.ts` now calls
`validateApplicationLevelSignature(as, response)` after processing, and `refresh()`
does the same when an ID token is present. TLS and the signature do not fail
together — TLS authenticates the host that answered, the signature authenticates the
issuer that minted — so the check is not redundant where the two differ. Row 1 is now
a genuine discriminator, and T-L2-002 reports 7/7.

## P-6 — T-018 narrowed deliberately, with a behavioural proof added

T-018 originally forbade **every** `.setItem` in the auth modules. FR-B9-3-030
forbids persisting the **refresh token**. The gap is not academic: signing in is a
full-page navigation, so the document that mints the PKCE `code_verifier` is
destroyed before the callback runs, and the transaction must outlive it. The blanket
rule described a scaffold that cannot complete a login, and could only have been
"satisfied" by deleting the feature.

Narrowed to: `localStorage.setItem` forbidden outright; `sessionStorage.setItem`
forbidden for anything naming token material. Because that is still only identifier
matching, **T-L2-004** was added as the actual proof — it drives a real successful
login with instrumented storage and searches both stores for the literal token
strings (`ACCESSTOKENCANARY-…`, `REFRESHTOKENCANARY-…`), asserts `localStorage` was
never written at all, and refuses to report success if the login did not complete
(a search of empty stores proves nothing).

## P-7 — T-L2-003 existed only in the header

The harness documented three L2 rows from the day it was written. `main()` registered
two, and no `_test_b93_l2_003_*` function existed — the row was described, ran never,
and would have been read as covered. Implemented rather than dropped:
`fixtures/b9-3/state-mismatch.mjs` asserts both that a mismatched state is rejected
**and** that the token endpoint was never requested, because the ORDER is the
requirement — a client that checks the state after redeeming the code rejects
correctly while having already handed a live authorization code to the provider.

## P-8 — final state (Phases 3–6)

```
b9-3.test.sh --level 12 (FORGE_B9_3_NPM=1)   Passed: 31   Failed: 0
  incl. T-L2-001 tsc --noEmit clean on the rendered tree
        T-L2-002 7/7 rejection table
        T-L2-003 2/2 state checked before the code is redeemed
        T-L2-004 5/5 no token material in browser storage
b9-2.test.sh --level 1                       Passed: 22   Failed: 0  (T-007 green)
b9-1 23/0 · scaffolder 7/0 · a7 29/0 · t5-1 17/0 · k5 25/0
validate-foundations.sh                      0 KO
  PASS: FR-GL-001-versioned:mobile-pwa-first/2.0.0.yaml — stage=candidate
        profile=client-only layers=['app', 'web-pwa']
verify.sh                                    583 PASS / 0 FAIL / 1 WARN — RESULT: PASS
constitution-linter.sh                       86 PASS / 0 FAIL / 13 WARN — OVERALL: PASS
forge-ci.yml                                 418 lines (NFR-CI-002 ceiling 420, no bump)
```

T-007's exclusion list gained `oidc-provider.json`, with the reasoning recorded at the
call site: it is a NEW root-level file the legacy mobile-only render has no
counterpart for (the same reason `web-pwa/` is excluded), and every Flutter file
stays compared byte-for-byte **except one carrying that exact basename**: `--exclude`
matches a basename at ANY depth, which is wider than the intent and is now stated at
the call site. Confirmed independently — `lib/`, `ios/`, `android/`,
`test/`, `identity.yaml` and `overlay.sh` are all byte-unchanged vs HEAD.

## P-9 — T7.5 independent review, round 1: the implementation (2026-08-03)

Reviewed in a separate lane (Article V). Verdict **CHANGES REQUIRED** on two findings;
both fixed below. The reviewer confirmed empirically — render, `npm install`,
`tsc --noEmit`, `vite build`, `vite build --mode ssr`, a live dev server, a custom
forgery probe with real keypairs, and by reading `oauth4webapi`'s `build/index.js`
rather than only its `.d.ts`.

**What held up.** Nothing in the OIDC protocol path was exploitable. `expectedNonce`
as a string is strictly compared; `requireIdToken: true` routes to the OpenID path;
`validateAuthResponse` genuinely checks state and additionally enforces RFC 9207
`iss`. Two things I had flagged as my own weakest points both survived: the
`sessionStorage` argument for the PKCE transaction (the reviewer looked for a
materially safer design that still completes a redirect login in a static
client-only PWA and reported there isn't one), and `validateApplicationLevelSignature`
— proven load-bearing, not decorative, by a probe holding `iss`/`aud`/`exp`/`nonce`
all valid and changing only the signing key: `valid → ACCEPTED, forged → REJECTED`.

### F1 (blocking, CONFIRMED then fixed) — the dev server served the whole project

`vite.config.ts.tmpl` carried `server.fs.allow: [".."]`, which I added so the
out-of-root shared config could be imported. Reproduced independently before fixing:
`curl /@fs/<root>/pubspec.yaml` returned the Flutter pubspec **contents**, HTTP 200,
as did `lib/main.dart`.

This is the *mobile* PWA archetype, so `npm run dev -- --host` on a handset is the
normal loop — which serves `lib/**`, `google-services.json`, keystores and `.env` to
every device on the network. Narrowed to `allow: ["../oidc-provider.json"]` and
verified both directions: callback route still **200**, `pubspec.yaml` and
`lib/main.dart` now **403**, `oidc-provider.json` still **200**.

### F2 (blocking, CONFIRMED then fixed) — documenting a mechanism that does not exist

The README, ADR-B9-3-005, `session.ts`, `open-questions.md` and `tasks.md` all
described session recovery as a **silent re-authorization (`prompt=none`)**.
`beginAuthorization()` sends no `prompt` parameter and nothing restores a session on
boot. Verified by grep: the only occurrences were in prose.

The predicted *outcome* is roughly right by accident — an ordinary redirect meeting a
live provider cookie also returns without a prompt — which is exactly how the claim
survived design review. But this brick's stated position is that a scaffold must not
claim a capability it does not implement, and it had done so three times over. All
five sites now describe what actually happens and name the silent flow as unbuilt.
Corrected rather than quietly reworded, because the design doc committed to it.

### Doc error in specs.md, found by the same review

FR-B9-3-009 asserted *"no signature-skipping escape hatch exists on this path …
clauses 1–4 are structurally enforced by the library."* Inverted: there is no
skip *option* because there is no signature *check* to skip —
`processAuthorizationCodeResponse` → `processGenericAccessTokenResponse` →
`validateJwt` parses the header, checks `alg`, validates claims, and never verifies a
signature. This is the same misreading recorded as P-5, still sitting in the spec
after the code had been corrected. Now states accurately: clauses 2–5 structural,
clause 1 via the explicit extra call.

### F3 / F4 / F5 (low, addressed)

- **F3** `token_type` — the library lowercases unconditionally (`index.js:1223`) and
  asserts presence (`:1220`), so the model returned `"bearer"` while the Dart side
  defaults to `'Bearer'`, and the `?? "Bearer"` fallback was unreachable. An adopter
  building `Authorization: ${t.tokenType} …` would send a different header from each
  surface — the same reproduces-on-one-surface-only class the 30 s skew constant
  exists to prevent. Canonicalised `bearer → Bearer`, other types passed through, dead
  fallback removed.
- **F4** the `discoveryUrl` override branch used a bare `fetch` and so skipped the
  protocol check `discoveryRequest` performs. Metadata decides every endpoint the
  client subsequently trusts, and `processDiscoveryResponse` validates only `issuer`,
  which an attacker copies verbatim. Now rejects a non-https `discoveryUrl` explicitly.
- **F5** `offline_access` reaches the browser surface, which can never persist the
  refresh token — a long-lived credential in the JS heap for an XSS to replay. It is a
  consequence of `scopes` being declared ONCE (FR-GL-B9-3-020), not a slip, so it is
  documented at the point of configuration with the trade-off and its cost stated,
  rather than silently changed. Splitting scopes per surface is a schema change.

### F6 — NOT this change: `npm run build` is broken

**CONFIRMED independently.** `npm run build` → `qwik build` dies with
`MODULE_NOT_FOUND` for `ignore`, inside `@builder.io/qwik/dist/cli.cjs`, before any
user code loads. `vite build` and `vite build --mode ssr` both succeed. The `build`
script came from B.9.2; b9-3 does not touch it. Recorded in §Follow-up — fixing it
means a Qwik pin bump or a workaround dependency, both of which need a verify-then-pin
pass owned by `web-frontend.yaml`, not a side-effect of this brick.

## P-10 — two harness rows that could never fail (review round 2, partial)

Found by the harness-review lane, both confirmed by me before fixing.

**`[^\n]` is not "not newline".** In a POSIX bracket expression the backslash is
literal, so `[^\n]` means *"not a backslash and not the letter n"*. Under GNU grep
3.11 — what CI runs:

```
sessionStorage.setItem("auth.session", refreshToken)
  old  [^\n]*  -> 0 hits   (row PASSES while the token is written)
  new  .*      -> 1 hit
```

Two NEGATIVE security rows were affected: T-018 (token material in web storage) and
T-020 (token leak via `toString`/`toJSON`).

**Why it survived my own mutation probe**, which is the part worth keeping: the probe
used `sessionStorage.setItem("k", refreshToken)`. `"k"` contains no letter `n`, so it
matched and the row went red — the probe string was lucky, not the check. A probe
chosen for brevity can satisfy a broken pattern by accident.

**Why it was invisible — CORRECTED, my first diagnosis was wrong.** I reported that a
local `ugrep` shim masked it and the bug was CI-only. The review round-2 lane
challenged that and it does not survive measurement:

```
prompt (interactive zsh) : ugrep 7.5.0     <- a shell function from Claude Code's
                                              own shell snapshot
bash -c / bash <script>  : GNU grep 3.11   <- what the harness actually gets
```

Harnesses are `#!/usr/bin/env bash` and shell functions are not exported into them, so
the harness resolved GNU grep on **every local run too**. The dead negatives were dead
here, not merely in CI, and "27/27 under ugrep and 27/27 under GNU grep" was one
measurement performed twice. The shim only ever affected the ad-hoc `grep` commands
typed at the prompt *while diagnosing* — which is exactly how the wrong conclusion was
reached.

Practical consequence for the ~40 harnesses in §Follow-up: check them with `bash -c`,
never with a `grep` typed at the prompt, or the answer inverts.

**T-013 matched a line number.** `_stripped` emits `path:LINE:content`, so `\b30\b`
matched the `:30:` prefix of any auth file with 30 or more lines. The row could not
fail. Anchored to `EXPIRY_SKEW_SECONDS[[:space:]]*=[[:space:]]*30\b` and re-probed:
changing the constant to 60 now turns it red.

All three rows re-probed under GNU grep with **realistic** violations, and all restored
byte-for-byte (sha256 verified).

## P-11 — three more rows that could not fail (found by re-probing, not by the suite)

The `[^\n]` finding raised the obvious follow-up question: which OTHER rows are
satisfied by a substring that appears somewhere unrelated in the stream? The suite
greps `_auth_stripped`, which concatenates ten files, so any bare identifier can be
supplied by a file that has nothing to do with the property under test.

Checked by asking, per keyword, **which file actually supplies it**:

```
discoveryUrl          config.ts 1   discovery.ts 3
refresh               index.ts  5   token.ts     3
end_session_endpoint  index.ts  2
getCurrentToken       index.ts  1
login                 index.ts  1
```

Two supplies are load-bearing in the wrong way, and both were confirmed by mutation
under GNU grep:

- **T-011** — deleting the `config.discoveryUrl` branch from `discovery.ts` entirely,
  so the override does nothing at all, left the row **GREEN**. `config.ts` declares
  `discoveryUrl?: string | null` as an interface field, and the bare identifier match
  was satisfied by the TYPE. Now requires `config\.discoveryUrl` — a read, not a
  declaration.
- **T-012 and T-016** — deleting `refresh()` from the port left **both GREEN**,
  because `refresh` matches the `refreshToken` field on the token model. Both now
  require `export [async] function <op>`.

Re-probed after the fix with the identical mutations: all three go **RED**. Sources
restored byte-for-byte (sha256 verified), suite back to 27/27.

This is the same defect shape as `[^\n]` and as `\b30\b` matching a line number: an
assertion that passes for a reason unrelated to the property it names. Three separate
instances in one suite says the shape is the problem, not the individual rows — a
whole-stream grep for a bare identifier is structurally weak, and the rows that
survived scrutiny (`end_session_endpoint`, `getCurrentToken`, `login`) did so only
because no other file happened to contain their substring. That is luck, not design.

## P-12 — T7.5 independent review, round 2: the harness (2026-08-03)

Verdict **CHANGES REQUIRED**, one blocker. Fixed and re-probed below.

### F1 (blocker) — the fixture written to fix a row that never ran could not fail

`state-mismatch.mjs` asserted only "the call rejected" and "the token endpoint was not
hit". Both hold for an implementation that does nothing: the reviewer scored **2/2,
rc=0** against a renamed export and against a body that throws on line one.

That is the exact failure the sibling fixture's own header warns about — *"a callback
that always throws would score a perfect six"* — reproduced in the fixture added
because T-L2-003 had never run. Writing the warning down did not stop me repeating it
one file over.

Rewritten with what the rejection table already had: an **export guard** (a missing
`completeAuthorization` is a fixture error, exit 3, never a pass) and a **positive
control** (a matching state must resolve *and* hit the token endpoint exactly once).
Now reports 3/3. Re-probed with the reviewer's two implementations:

```
renamed export      -> ✗ T-L2-003   (was 2/2 PASS)
body throws at once -> ✗ T-L2-003   (was 2/2 PASS)
real implementation -> ✓ 3/3
```

### F2 — T-023's promotion tripwire matched any entry

`grep -qE "^    status: candidate" "$DISPATCH"` matched *any* dispatch entry. Verified:
flipping `mobile-pwa-first` to `stable` while giving an unrelated entry `candidate`
left the row **GREEN**. Latent today (exactly one candidate exists) but this is the
promotion gate, on a table where candidate→stable flips cascade across siblings.
Replaced with a YAML lookup of `mobile-pwa-first.status`; the decoy scenario now
turns it red.

### F3 — a skipped L2 leg was indistinguishable from a run one

Each L2 row skipped itself by returning 0, which `run_test` printed as ✓ and counted
as a pass. `--level 12` without `FORGE_B9_3_NPM` produced a stdout summary **identical**
to a genuine run — the SKIP notices went only to stderr. For a suite whose L2 rows
carry the only assertions that cannot be satisfied by decoration, that is the worst
possible place for an ambiguity. The gate is now checked once in `main()`:

```
  ⊘ L2 NOT RUN (4 rows) — set FORGE_B9_3_NPM=1 and ensure npm is present.
    T-L2-002 is THE proof of FR-B9-3-009; this run does not include it.
  Passed: 27          <- vs 31 for a real run
```

### F4 — "byte-unchanged" could not see added files

`git diff --quiet HEAD -- <paths>` ignores untracked files, so T-022 was blind to an
**addition** under the frozen Flutter tree — the drift a template port is most likely
to introduce. Confirmed by creating a file under `2.0.0/lib/` and watching the row stay
green. Now also checks `git status --porcelain`; the same probe turns it red.

### F5 / §mechanism — two consistency fixes

`b9-2.test.sh` still had one `printf | grep -q` of the shape its own new header
forbids (short input, positive assertion, so it would fail loudly rather than
silently) — converted. And T-007's exclusion comment claimed "a NEW root-level file"
when `--exclude` matches that basename at **any depth**; the comment now says what the
tool does rather than what was intended.

### What the review confirmed rather than found

The reviewer re-derived the rows I had probed and twelve I had not — T-001, T-002,
T-007, T-010, T-011, T-012, T-014, T-015, T-016, T-017, T-019, T-021 — each with a
control-green precondition, an assert-the-mutation-applied step and a sha-verified
restore. All go red under a correct mutation. Its own six "bogus GREENs" were bad
mutations that left the grepped substring intact (`discoveryUrl` → `discoveryUrlX`
still contains `discoveryUrl`) or killed one alternative of an OR, not defects.

**Corrected by the reviewer, in its own disfavour, and worth keeping:** that account
is not the whole story. Its T-011 probe replaced `discoveryUrl` *tree-wide*,
destroying the type declaration and the use site together — so it could never reveal
that the type alone satisfied the check. And it never mutated `refresh` for T-012 or
T-016 at all; it flagged both as "unanchored substrings, weaker than their prose" and
left it as a reasoned note. So P-11 is a finding, not a re-derivation of theirs. The
general lesson is the sharper half: **a blunt mutation that goes red is weaker
evidence than it looks** — it proves the row *can* fail, not that it fails for the
reason its name claims.

On the fixtures: `oidc-rejection-table.mjs` and `no-token-in-storage.mjs` cannot pass
vacuously; all seven rejection rows separate against a bare-fetch implementation, and
**no sibling of the `bad-signature` mistake exists**. One reasoned nit accepted as a
follow-up: `no-token-in-storage.mjs` searches what is still *present* in the stores, so
a written-then-removed token would escape; instrumenting `setItem` with a write log
would close it.

Every reproducible claim in this file was re-derived. The recurring
confident-prose-falsified-by-one-command defect **did not recur** — but its cousin did,
in P-10's causal story, which is corrected above.

## P-13 — the three items the review left as optional, closed anyway

The round-2 report classified these as acceptable follow-ups. They were cheap and each
one was an assertion weaker than the sentence describing it, which is the defect class
this brick keeps producing — so they were closed rather than carried.

**T-007 said "minted AND SENT" and checked neither.** `\bstate\b` matched 13 places
and `\bnonce\b` 7, nearly all type declarations and parameter names. Now requires the
CSPRNG generators *and* `searchParams.set("state"/"nonce")`. Probed: deleting the
single line that puts `nonce` on the authorization URL — leaving the variable minted,
named and unused — turns the row **RED**. The previous version passed that mutation.

**T-L2-004 searched what survived, not what was written.** A token written and then
removed escaped the search, while the fixture header claimed it searched "everything
written". `setItem` is now instrumented with a write log and both the canary search and
the `localStorage`-never-touched assertion read it. The claim in the header is now
literally true rather than aspirational.

**T-001 and T-015 had never been mutated** by either lane. Probed: removing the auth
module turns T-001 red; giving both surfaces the same `redirectUri` turns T-015 red.

Final: **31/31** with the L2 rows genuinely running, 27/27 at L1.

## P-14 — T7.5 confirmation pass: APPROVED (2026-08-03)

The harness lane re-verified every fix by running it. All five of its findings, the
three P-11 rows and the T-L2-004 write log confirmed closed, with control-green
preconditions and sha-verified restores throughout.

**It went further than confirmation on F1, and found the case neither of us had
tested.** Beyond the renamed export and the always-throwing body, it built a *genuine
order violation*: a client that validates the response against **the URL's own state**
— so `validateAuthResponse` always passes — redeems the code, and only then compares
to `pending.state`. That client rejects correctly, so any outcome-only assertion passes
it. The fixture catches it:

```
OK    control: a matching state completes and redeems the code once
OK    the mismatched state was rejected      <- a "did it reject?" test PASSES here
FAIL  the token endpoint was requested 1x — the code was redeemed before the state was checked
```

That is the property T-L2-003 actually names — order, not outcome — now demonstrated
rather than assumed.

The reviewer also recorded that its *first* order-violation attempt went red for the
wrong reason (oauth4webapi brands its `URLSearchParams`, so it threw before the grant
request and the negative leg read "never requested" trivially). **A red result that
proves nothing looks identical to one that proves everything** — the same shape as the
`"k"` probe string in P-10, arrived at independently.

### Two follow-ups taken immediately rather than carried

- **T-012/T-016 were over-strict.** Requiring `export [async] function <op>` would have
  turned red on a legitimate refactor to `export const refresh = async () => …` or a
  re-export — a false *alarm*, not a false pass, but with a message pointing at the
  wrong thing. Both now accept a declaration, an exported const/let/var, or a
  re-export. Probed both ways: de-exporting `refresh()` still turns T-012 and T-016
  **red**; rewriting `logout` as an exported arrow leaves them **green**.
- **T-023 needs PyYAML** where it previously needed only grep. It now says so
  explicitly instead of surfacing a traceback, and **fails** rather than skipping if
  PyYAML is absent — a promotion tripwire that quietly stops running is the thing it
  exists to prevent.

### Left as a recorded follow-up

`git status --porcelain` omits `.gitignore`d paths without `--ignored`, so T-022 would
not see an ignored file added under the frozen Flutter tree. Reasoned-only, and nothing
in this archetype ignores files there.

**Verdict: APPROVED.** Repo byte-identical to the pre-review snapshot after all probes.
