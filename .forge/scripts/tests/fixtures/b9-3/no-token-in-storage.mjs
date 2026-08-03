// Forge — B.9.3 T-L2-004 fixture: no token reaches browser storage
// <!-- Audit: B.9.3 (b9-3-shared-oidc, FR-B9-3-030, ADR-B9-3-005) -->
//
// WHY THIS FILE EXISTS. T-018 greps the auth modules for `setItem` calls naming
// token identifiers. That is a PROXY and a weak one: it reads names, so it cannot
// see what a value actually holds. `sessionStorage.setItem(k, JSON.stringify(x))`
// where `x` happens to carry a token passes it cleanly.
//
// This fixture asserts the property instead. It runs a REAL, fully successful login
// against a stubbed provider with instrumented storage, then searches everything
// written to `sessionStorage` and `localStorage` for the actual token STRINGS. No
// identifier matching, no reliance on how the code is spelled.
//
// Usage:  npx tsx no-token-in-storage.mjs <path-to-rendered-web-pwa>

import { generateKeyPair, exportJWK, SignJWT } from 'jose';
import { pathToFileURL } from 'node:url';
import { join } from 'node:path';

const WEBPWA = process.argv[2];
if (!WEBPWA) {
  console.error('usage: no-token-in-storage.mjs <path-to-rendered-web-pwa>');
  process.exit(2);
}

const ISSUER = 'https://issuer.example.test';
const CLIENT_ID = 'web-pwa-client';
const REDIRECT = 'https://app.example.test/auth/callback';

// Distinctive values: if any of these appears in a store, it got there from a token.
const ACCESS_TOKEN = 'ACCESSTOKENCANARY-8f3a1c';
const REFRESH_TOKEN = 'REFRESHTOKENCANARY-b7e02d';

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

// ─── instrumented storage ────────────────────────────────────────────────────
// Records EVERY write, not just what survives. Searching only the final contents lets
// a token that is written and then removed escape — and "it was in localStorage for
// 200 ms" is still a token in localStorage, readable by anything running in the origin
// during that window.
function makeStore(label) {
  const map = new Map();
  const writes = [];
  return {
    label,
    map,
    writes,
    getItem: (k) => (map.has(k) ? map.get(k) : null),
    setItem: (k, v) => { writes.push(`${k}=${String(v)}`); map.set(k, String(v)); },
    removeItem: (k) => void map.delete(k),
    clear: () => map.clear(),
    key: (i) => [...map.keys()][i] ?? null,
    get length() { return map.size; },
  };
}
const sessionStore = makeStore('sessionStorage');
const localStore = makeStore('localStorage');
globalThis.sessionStorage = sessionStore;
globalThis.localStorage = localStore;

// ─── the flow ────────────────────────────────────────────────────────────────
const nowSec = () => Math.floor(Date.now() / 1000);

async function run() {
  const authorizeUrl = pathToFileURL(join(WEBPWA, 'src/lib/auth/authorize.ts')).href;
  const pendingUrl = pathToFileURL(join(WEBPWA, 'src/lib/auth/pending.ts')).href;
  const callbackUrl = pathToFileURL(join(WEBPWA, 'src/lib/auth/callback.ts')).href;
  const sessionUrl = pathToFileURL(join(WEBPWA, 'src/lib/auth/session.ts')).href;

  const { beginAuthorization } = await import(authorizeUrl);
  const { savePending, takePending } = await import(pendingUrl);
  const { completeAuthorization } = await import(callbackUrl);
  const { setSession } = await import(sessionUrl);

  const config = {
    issuer: ISSUER,
    scopes: ['openid', 'profile', 'email'],
    surfaces: { 'web-pwa': { clientId: CLIENT_ID, redirectUri: REDIRECT } },
  };

  // Discovery only, for the authorization request.
  globalThis.fetch = async (input) => {
    const url = typeof input === 'string' ? input : (input.url ?? String(input));
    if (url.includes('/.well-known/openid-configuration')) {
      return new Response(JSON.stringify(DISCOVERY), {
        status: 200, headers: { 'content-type': 'application/json' },
      });
    }
    throw new Error(`fixture: unexpected fetch to ${url}`);
  };

  // 1. Start the flow exactly as login() does, including the storage write.
  const { pending } = await beginAuthorization(config);
  savePending(pending);

  // 2. Come back from the provider with a fully valid response.
  const idToken = await new SignJWT({ nonce: pending.nonce })
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
      return json({
        access_token: ACCESS_TOKEN,
        token_type: 'Bearer',
        expires_in: 3600,
        refresh_token: REFRESH_TOKEN,
        id_token: idToken,
      });
    }
    throw new Error(`fixture: unexpected fetch to ${url}`);
  };

  const consumed = takePending();
  if (!consumed) throw new Error('the pending transaction did not survive the redirect');

  const token = await completeAuthorization({
    currentUrl: `${REDIRECT}?code=auth-code-value&state=${consumed.state}`,
    pending: consumed,
    config,
  });
  setSession(token);

  if (token.accessToken !== ACCESS_TOKEN) {
    throw new Error('the login did not actually succeed — the canary token came back changed');
  }
  return token;
}

let failures = 0;
try {
  await run();
  console.log('OK    a full login completed (so the search below is meaningful)');
} catch (err) {
  console.log(`FAIL  the login did not complete: ${err.message}`);
  console.log('T-L2-004: inconclusive — a search of empty stores proves nothing');
  process.exit(1);
}

for (const store of [sessionStore, localStore]) {
  // Every value ever written, plus whatever is still present.
  const dump = [
    ...store.writes,
    ...[...store.map.entries()].map(([k, v]) => `${k}=${v}`),
  ].join('\n');
  for (const [name, canary] of [['access token', ACCESS_TOKEN], ['refresh token', REFRESH_TOKEN]]) {
    if (dump.includes(canary)) {
      console.log(`FAIL  the ${name} was found in ${store.label}`);
      failures += 1;
    } else {
      console.log(`OK    no ${name} in ${store.label}`);
    }
  }
}

// localStorage must be untouched entirely — it outlives the tab.
if (localStore.writes.length !== 0) {
  console.log(`FAIL  localStorage was written to ${localStore.writes.length} time(s): ${localStore.writes.join(', ')}`);
  failures += 1;
} else {
  console.log('OK    localStorage was never written to');
}

console.log(failures === 0
  ? 'T-L2-004: 5/5 — no token material reaches browser storage'
  : `T-L2-004: ${failures} check(s) wrong — FR-B9-3-030 is NOT enforced`);
process.exit(failures === 0 ? 0 : 1);
