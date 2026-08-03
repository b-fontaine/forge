// Forge — B.9.3 T-L2-002 fixture: the ID-token rejection table
// <!-- Audit: B.9.3 (b9-3-shared-oidc) — THE proof of FR-B9-3-009 -->
//
// WHY THIS FILE EXISTS. Two successive drafts of b9-3's spec specified tests that
// could not detect a missing ID-token validation — the exact property the
// `oauth4webapi` dependency was chosen for. Static assertions cannot close that gap:
// a call can sit in a dead branch, in an uncalled helper, or have its result
// discarded while a separately bare-fetched response is the one actually used.
//
// This fixture tests the PROPERTY instead of the call path. It stands up a fake
// provider — real EC keypair, real JWKS, real signed JWTs — stubs `fetch`, and drives
// the auth module's callback with seven token responses that each differ in exactly
// one way. An implementation that bare-fetches the token endpoint fails every
// rejection row. One that calls the validator in a dead branch fails them too.
//
// THE LAST ROW IS NOT PADDING. Without the `valid` case, all six negatives pass on an
// implementation that rejects everything — a callback that always throws would score a
// perfect six. The valid row is what makes the negatives mean something.
//
// CONTRACT with the auth module (defined here first, TDD):
//   web-pwa/src/lib/auth/callback.ts exports
//     completeAuthorization({ currentUrl, pending, config }): Promise<TokenSet>
//   It MUST reject (throw) on any validation failure and resolve only on success.
//
// Usage:  npx tsx oidc-rejection-table.mjs <path-to-rendered-web-pwa>

import { generateKeyPair, exportJWK, SignJWT, base64url } from 'jose';
import { pathToFileURL } from 'node:url';
import { join } from 'node:path';

const WEBPWA = process.argv[2];
if (!WEBPWA) {
  console.error('usage: oidc-rejection-table.mjs <path-to-rendered-web-pwa>');
  process.exit(2);
}

const ISSUER = 'https://issuer.example.test';
const CLIENT_ID = 'web-pwa-client';
const REDIRECT = 'https://app.example.test/auth/callback';
const NONCE = 'nonce-minted-for-this-request';
const STATE = 'state-minted-for-this-request';
const VERIFIER = 'a'.repeat(64);

const { publicKey, privateKey } = await generateKeyPair('ES256', { extractable: true });
const jwk = await exportJWK(publicKey);
jwk.kid = 'test-key-1';
jwk.alg = 'ES256';
const JWKS = { keys: [jwk] };

// A second, unrelated key — used to forge a signature the real JWKS cannot verify.
const other = await generateKeyPair('ES256', { extractable: true });

const DISCOVERY = {
  issuer: ISSUER,
  authorization_endpoint: `${ISSUER}/authorize`,
  token_endpoint: `${ISSUER}/token`,
  jwks_uri: `${ISSUER}/jwks`,
  end_session_endpoint: `${ISSUER}/logout`,
  response_types_supported: ['code'],
  id_token_signing_alg_values_supported: ['ES256'],
  code_challenge_methods_supported: ['S256'],
};

const now = () => Math.floor(Date.now() / 1000);

async function idToken({ signer = privateKey, iss = ISSUER, aud = CLIENT_ID,
                         nonce = NONCE, exp = now() + 3600 } = {}) {
  return new SignJWT({ nonce })
    .setProtectedHeader({ alg: 'ES256', kid: 'test-key-1' })
    .setIssuer(iss)
    .setAudience(aud)
    .setSubject('user-123')
    .setIssuedAt(now() - 10)
    .setExpirationTime(exp)
    .sign(signer);
}

// The seven cases. Each differs from `valid` in exactly one way.
const CASES = [
  { name: 'bad-signature',  expect: 'reject', token: () => idToken({ signer: other.privateKey }) },
  { name: 'wrong-nonce',    expect: 'reject', token: () => idToken({ nonce: 'not-the-minted-nonce' }) },
  { name: 'wrong-issuer',   expect: 'reject', token: () => idToken({ iss: 'https://evil.example.test' }) },
  { name: 'wrong-audience', expect: 'reject', token: () => idToken({ aud: 'some-other-client' }) },
  { name: 'expired',        expect: 'reject', token: () => idToken({ exp: now() - 120 }) },
  { name: 'no-id-token',    expect: 'reject', token: () => null },
  { name: 'valid',          expect: 'accept', token: () => idToken() },
];

function stubFetch(idTokenValue) {
  return async (input) => {
    const url = typeof input === 'string' ? input : (input.url ?? String(input));
    const json = (body, status = 200) =>
      new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

    if (url.includes('/.well-known/openid-configuration')) return json(DISCOVERY);
    if (url.includes('/jwks')) return json(JWKS);
    if (url.includes('/token')) {
      const body = {
        access_token: 'access-token-value',
        token_type: 'Bearer',
        expires_in: 3600,
        refresh_token: 'refresh-token-value',
      };
      if (idTokenValue) body.id_token = idTokenValue;
      return json(body);
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
if (typeof completeAuthorization !== 'function') {
  console.error('FIXTURE-ERROR: callback.ts does not export completeAuthorization()');
  process.exit(3);
}

let failures = 0;
for (const c of CASES) {
  const tok = await c.token();
  globalThis.fetch = stubFetch(tok);
  const currentUrl = `${REDIRECT}?code=auth-code-value&state=${STATE}`;
  let outcome;
  try {
    await completeAuthorization({
      currentUrl,
      pending: { state: STATE, nonce: NONCE, codeVerifier: VERIFIER },
      config,
    });
    outcome = 'accept';
  } catch {
    outcome = 'reject';
  }
  const ok = outcome === c.expect;
  if (!ok) failures += 1;
  console.log(`${ok ? 'OK  ' : 'FAIL'}  ${c.name.padEnd(14)} expected=${c.expect} got=${outcome}`);
}

console.log(failures === 0
  ? 'T-L2-002: 7/7 — ID-token validation is on the live path'
  : `T-L2-002: ${failures} case(s) wrong — FR-B9-3-009 is NOT enforced`);
process.exit(failures === 0 ? 0 : 1);
