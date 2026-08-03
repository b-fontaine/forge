// Forge — B.9.3 T-L2-003 fixture: a mismatched state never reaches the token endpoint
// <!-- Audit: B.9.3 (b9-3-shared-oidc, FR-B9-3-004) — design T-008 -->
//
// WHY THIS FILE EXISTS. T-L2-003 was described in the harness header from the day it
// was written and was never implemented — documented, registered nowhere, run never.
//
// WHY IT LOOKS THE WAY IT DOES. Its first implementation could not fail. It asserted
// only "the call rejected" and "the token endpoint was not hit", and BOTH hold for an
// implementation that does nothing at all: a renamed export, or a body that throws on
// line one, scored a perfect 2/2. That is precisely the trap the sibling fixture's own
// header warns about ("a callback that always throws would score a perfect six") —
// reproduced here, in the fixture written to fix a row that never ran.
//
// So this file now carries what that one has:
//   * an EXPORT GUARD — a missing or renamed `completeAuthorization` is a fixture
//     error (exit 3), never a pass;
//   * a POSITIVE CONTROL — a matching state must RESOLVE, and must hit the token
//     endpoint EXACTLY ONCE. Without it the negative proves nothing, because "never
//     redeemed the code" is trivially true of a client that never does anything.
//
// WHAT THE NEGATIVE ACTUALLY PROVES, beyond "it rejected": the ORDER. A client could
// check the state AFTER redeeming the code and still reject correctly — having already
// handed a live authorization code to the provider on behalf of a callback it had no
// reason to trust. So the assertion is about a request that must never be made.
//
// Usage:  npx tsx state-mismatch.mjs <path-to-rendered-web-pwa>

import { generateKeyPair, exportJWK, SignJWT } from 'jose';
import { pathToFileURL } from 'node:url';
import { join } from 'node:path';

const WEBPWA = process.argv[2];
if (!WEBPWA) {
  console.error('usage: state-mismatch.mjs <path-to-rendered-web-pwa>');
  process.exit(2);
}

const ISSUER = 'https://issuer.example.test';
const CLIENT_ID = 'web-pwa-client';
const REDIRECT = 'https://app.example.test/auth/callback';
const STATE = 'state-minted-for-this-request';
const NONCE = 'nonce-minted-for-this-request';
const VERIFIER = 'a'.repeat(64);

const { publicKey, privateKey } = await generateKeyPair('ES256', { extractable: true });
const jwk = await exportJWK(publicKey);
jwk.kid = 'test-key-1';
jwk.alg = 'ES256';

const DISCOVERY = {
  issuer: ISSUER,
  authorization_endpoint: `${ISSUER}/authorize`,
  token_endpoint: `${ISSUER}/token`,
  jwks_uri: `${ISSUER}/jwks`,
  response_types_supported: ['code'],
  id_token_signing_alg_values_supported: ['ES256'],
  code_challenge_methods_supported: ['S256'],
};

const nowSec = () => Math.floor(Date.now() / 1000);

let tokenEndpointHits = 0;

async function installFetch() {
  const idToken = await new SignJWT({ nonce: NONCE })
    .setProtectedHeader({ alg: 'ES256', kid: 'test-key-1' })
    .setIssuer(ISSUER)
    .setAudience(CLIENT_ID)
    .setSubject('user-123')
    .setIssuedAt(nowSec() - 10)
    .setExpirationTime(nowSec() + 3600)
    .sign(privateKey);

  globalThis.fetch = async (input) => {
    const url = typeof input === 'string' ? input : (input.url ?? String(input));
    const json = (body) => new Response(JSON.stringify(body), {
      status: 200, headers: { 'content-type': 'application/json' },
    });
    if (url.includes('/.well-known/openid-configuration')) return json(DISCOVERY);
    if (url.includes('/jwks')) return json({ keys: [jwk] });
    if (url.includes('/token')) {
      tokenEndpointHits += 1;
      return json({
        access_token: 'access-token-value',
        token_type: 'Bearer',
        expires_in: 3600,
        refresh_token: 'refresh-token-value',
        id_token: idToken,
      });
    }
    throw new Error(`fixture: unexpected fetch to ${url}`);
  };
}

const config = {
  issuer: ISSUER,
  scopes: ['openid', 'profile', 'email'],
  surfaces: { 'web-pwa': { clientId: CLIENT_ID, redirectUri: REDIRECT } },
};

const modUrl = pathToFileURL(join(WEBPWA, 'src/lib/auth/callback.ts')).href;
let completeAuthorization;
try {
  ({ completeAuthorization } = await import(modUrl));
} catch (err) {
  console.error(`FIXTURE-ERROR: cannot import ${modUrl}: ${err.message}`);
  process.exit(3);
}
// A missing export is a FIXTURE ERROR, not a pass. Without this, renaming the
// function makes every rejection assertion below trivially true.
if (typeof completeAuthorization !== 'function') {
  console.error('FIXTURE-ERROR: callback.ts does not export completeAuthorization()');
  process.exit(3);
}

await installFetch();

const pending = { state: STATE, nonce: NONCE, codeVerifier: VERIFIER };
let failures = 0;

// ── control: a MATCHING state must complete, and must redeem the code exactly once ──
tokenEndpointHits = 0;
let controlOk = false;
try {
  const token = await completeAuthorization({
    currentUrl: `${REDIRECT}?code=auth-code-value&state=${STATE}`,
    pending,
    config,
  });
  controlOk = Boolean(token && token.accessToken === 'access-token-value');
} catch (err) {
  console.log(`FAIL  control: a MATCHING state was rejected — ${err.message}`);
}
if (!controlOk) {
  console.log('FAIL  control: the matching-state flow did not produce a token');
  failures += 1;
} else if (tokenEndpointHits !== 1) {
  console.log(`FAIL  control: token endpoint hit ${tokenEndpointHits}x, expected exactly 1`);
  failures += 1;
} else {
  console.log('OK    control: a matching state completes and redeems the code once');
}

// ── the assertion: a MISMATCHED state rejects, and never reaches the token endpoint ──
tokenEndpointHits = 0;
let rejected = false;
try {
  await completeAuthorization({
    currentUrl: `${REDIRECT}?code=auth-code-value&state=state-from-somewhere-else`,
    pending,
    config,
  });
} catch {
  rejected = true;
}

if (!rejected) {
  console.log('FAIL  the mismatched state was ACCEPTED');
  failures += 1;
} else {
  console.log('OK    the mismatched state was rejected');
}

if (tokenEndpointHits !== 0) {
  console.log(`FAIL  the token endpoint was requested ${tokenEndpointHits}x — the code was redeemed before the state was checked`);
  failures += 1;
} else {
  console.log('OK    the token endpoint was never requested');
}

console.log(failures === 0
  ? 'T-L2-003: 3/3 — the state is checked BEFORE the code is redeemed'
  : `T-L2-003: ${failures} check(s) wrong — FR-B9-3-004 is NOT enforced`);
process.exit(failures === 0 ? 0 : 1);
