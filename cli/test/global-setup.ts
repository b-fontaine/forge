// <!-- Audit: T5.3.3 (t5-3-3-vitest-bundle-preflight) -->
//
// Vitest globalSetup — runs `npm run bundle` once before any test starts.
//
// Background : `cli/assets/` is gitignored (`cli/.gitignore::assets/`) and
// is regenerated from canonical sources by `npm run bundle`. The e2e
// suite spawns `node cli/dist/index.js init …` which rsyncs from
// `cli/assets/`. Without a fresh bundle, the e2e tests fail with
// confusing rsync errors (exit 23, missing template files) or `forge
// init` exit 255 on stale `cli/dist/`. `npm test` triggers the bundle
// via `prepack`/`prepublishOnly` chains but bare `vitest run` /
// `npx vitest` bypass it. Vitest's `globalSetup` fires regardless of
// the invocation path, closing the bypass for every contributor.
//
// Surfaced as a LOW finding in the `b1-1-dev-up-matrix-fixes` (T5.3.1)
// independent code-reviewer pass, and reproduced 2026-05-20 as the
// `npx vitest run` failure that triggered T5.3.3.
//
// Implementation : `spawnSync` (per ADR-T533-001) — vitest globalSetup
// runs serially, no concurrency to exploit, simpler error propagation.

import { spawnSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const CLI_DIR = resolve(__dirname, "..");

export default function setup(): void {
  // eslint-disable-next-line no-console
  console.log("[vitest globalSetup] running 'npm run bundle' in", CLI_DIR);
  const result = spawnSync("npm", ["run", "bundle"], {
    cwd: CLI_DIR,
    stdio: "inherit",
    shell: false,
  });
  if (result.error) {
    throw new Error(
      `[vitest globalSetup] failed to spawn 'npm run bundle': ${result.error.message}`,
    );
  }
  if (result.status !== 0) {
    throw new Error(
      `[vitest globalSetup] 'npm run bundle' exited ${result.status} — test suite cannot proceed against a stale cli/assets/ mirror. Stderr above.`,
    );
  }
}
