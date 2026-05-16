#!/usr/bin/env node
// Audit: T5.1 (cli-trust-harness) — Layer T5.1.C pre-publish tarball gate
//
// Wired into cli/package.json::prepublishOnly between `bundle` and the
// implicit `npm publish` step. Refuses to let `npm publish` proceed when
// the tarball that would be uploaded cannot be installed + scaffolded
// against a fresh tmpdir.
//
// Sequence (ADR-T51-003 — `npm install --prefix=<tmp> --global`) :
//   1. `npm pack` in cli/ — capture produced tarball path.
//   2. `mkdtemp` → install-prefix tmpdir.
//   3. `npm install --prefix=<install-prefix> --global <tarball>` — installs
//      the tarball binary at `<install-prefix>/bin/forge`. Maintainer's
//      global prefix never touched.
//   4. `mkdtemp` → scaffold tmpdir, then delete it so `forge init`
//      exercises the v0.3.2 `mkdir -p` fix.
//   5. `<install-prefix>/bin/forge init <slug> --archetype full-stack-monorepo
//      --org dev.forge.test --target <scaffold-tmp>`.
//   6. Assert the file matrix from
//      cli/test/e2e/archetype-fixtures/full-stack-monorepo.yml.
//   7. If `task` is on PATH AND Taskfile.yml present in scaffold —
//      run `task --list-all`, assert exit 0.
//   8. Cleanup both tmpdirs + the produced tarball ; exit 0.
//   9. On any failure — print captured paths + failed assertion + exit 1.
//
// Emergency override (ADR-T51-005) : `FORGE_SKIP_PREPUBLISH=1` prints a
// loud BYPASS warning on stderr, exits 0 without running. The maintainer
// commits to filing a follow-up issue per `GOVERNANCE.md § Release
// Process` documentation.

import { execSync, spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { mkdtemp, rm, unlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PKG_ROOT = resolve(__dirname, "..");
const REPO_ROOT = resolve(PKG_ROOT, "..");
const FIXTURE_PATH = resolve(
  PKG_ROOT,
  "test/e2e/archetype-fixtures/full-stack-monorepo.yml",
);

const DRY_RUN = process.argv.includes("--dry-run");

// ── Emergency override (FR-T51-098 / ADR-T51-005) ────────────────
if (process.env.FORGE_SKIP_PREPUBLISH === "1") {
  process.stderr.write(
    "[WARN: T5.1 BYPASS — FORGE_SKIP_PREPUBLISH=1 set ; pre-publish smoke skipped. File a follow-up issue.]\n",
  );
  process.exit(0);
}

// ── Minimal YAML reader for the fixture (subset matching load-fixture.ts) ──
function parseFixturePaths(yamlPath) {
  const content = readFileSync(yamlPath, "utf8");
  const lines = content.split("\n");
  const required = [];
  const forbidden = [];
  let mode = null;
  for (const raw of lines) {
    if (/^\s*$/.test(raw) || /^\s*#/.test(raw)) continue;
    if (/^required_paths:\s*$/.test(raw)) { mode = "required"; continue; }
    if (/^forbidden_paths:\s*$/.test(raw)) { mode = "forbidden"; continue; }
    if (/^[a-zA-Z_]+:/.test(raw)) { mode = null; continue; }
    const m = raw.match(/^ {2}- (.+)$/);
    if (m && mode === "required") required.push(m[1].trim().replace(/^['"]|['"]$/g, ""));
    if (m && mode === "forbidden") forbidden.push(m[1].trim().replace(/^['"]|['"]$/g, ""));
  }
  return { required, forbidden };
}

function commandOnPath(cmd) {
  const r = spawnSync("sh", ["-c", `command -v ${cmd}`], { encoding: "utf8" });
  return r.status === 0;
}

// ── 1. npm pack ──────────────────────────────────────────────────
process.stdout.write("[T5.1] step 1: npm pack\n");
let tarballPath;
try {
  const out = execSync("npm pack --silent", { cwd: PKG_ROOT, encoding: "utf8" });
  const tarballName = out.trim().split("\n").pop();
  if (!tarballName) {
    throw new Error("npm pack produced no tarball name");
  }
  tarballPath = join(PKG_ROOT, tarballName);
  if (!existsSync(tarballPath)) {
    throw new Error(`expected tarball at ${tarballPath} — not found`);
  }
  process.stdout.write(`[T5.1] tarball=${tarballPath}\n`);
} catch (err) {
  process.stderr.write(`[FAIL] npm pack failed: ${err.message}\n`);
  process.exit(1);
}

// ── 2 / 3. Isolated install ──────────────────────────────────────
process.stdout.write("[T5.1] step 2-3: isolated install via npm install --prefix --global\n");
let installPrefix;
let installedBin;
try {
  installPrefix = await mkdtemp(join(tmpdir(), "forge-prepublish-install-"));
  execSync(
    `npm install --silent --prefix='${installPrefix}' --global '${tarballPath}'`,
    { stdio: ["ignore", "ignore", "inherit"] },
  );
  installedBin = join(installPrefix, "bin", "forge");
  if (!existsSync(installedBin)) {
    throw new Error(`expected ${installedBin} after install — not found`);
  }
  process.stdout.write(`[T5.1] installed-bin=${installedBin}\n`);
} catch (err) {
  process.stderr.write(`[FAIL] isolated install failed: ${err.message}\n`);
  process.stderr.write(`[FAIL] tarball=${tarballPath}\n`);
  if (installPrefix) process.stderr.write(`[FAIL] install-prefix=${installPrefix}\n`);
  process.exit(1);
}

// ── 4 / 5 / 6 / 7. Scaffold smoke ────────────────────────────────
process.stdout.write("[T5.1] step 4-7: scaffold smoke against full-stack-monorepo\n");
const scaffoldTmp = await mkdtemp(join(tmpdir(), "forge-prepublish-scaffold-"));
// Delete so `forge init` exercises the mkdir -p path (v0.3.2 regression).
await rm(scaffoldTmp, { recursive: true, force: true });

let failed = false;
try {
  const r = spawnSync(installedBin, [
    "init",
    "smoke_full_stack_monorepo",
    "--archetype",
    "full-stack-monorepo",
    "--org",
    "dev.forge.test",
    "--target",
    scaffoldTmp,
  ], { encoding: "utf8", env: { ...process.env, NO_COLOR: "1" } });
  if (r.status !== 0) {
    process.stderr.write(`[FAIL] forge init exited ${r.status}\n${r.stderr}\n`);
    failed = true;
  } else {
    // File matrix.
    const fixture = parseFixturePaths(FIXTURE_PATH);
    for (const p of fixture.required) {
      if (!existsSync(join(scaffoldTmp, p))) {
        process.stderr.write(`[FAIL] required path missing: ${p}\n`);
        failed = true;
      }
    }
    for (const p of fixture.forbidden) {
      if (existsSync(join(scaffoldTmp, p))) {
        process.stderr.write(`[FAIL] forbidden path present: ${p}\n`);
        failed = true;
      }
    }
    // task --list-all if available and Taskfile present.
    const taskfile = join(scaffoldTmp, "Taskfile.yml");
    if (existsSync(taskfile) && commandOnPath("task")) {
      const t = spawnSync("task", ["--list-all"], {
        cwd: scaffoldTmp,
        encoding: "utf8",
      });
      if (t.status !== 0) {
        process.stderr.write(`[FAIL] 'task --list-all' exited ${t.status}\n${t.stderr}\n`);
        failed = true;
      } else {
        process.stdout.write("[T5.1] task --list-all OK\n");
      }
    } else if (!commandOnPath("task")) {
      process.stdout.write("[T5.1] task absent on PATH — skipped per ADR-T51-001\n");
    }
  }
} catch (err) {
  process.stderr.write(`[FAIL] smoke threw: ${err.message}\n`);
  failed = true;
}

// ── 8. Cleanup or post-mortem ────────────────────────────────────
if (failed) {
  process.stderr.write(`[FAIL] tarball=${tarballPath}\n`);
  process.stderr.write(`[FAIL] install-prefix=${installPrefix}\n`);
  process.stderr.write(`[FAIL] scaffold-tmp=${scaffoldTmp}\n`);
  if (DRY_RUN) {
    process.stderr.write("[T5.1] --dry-run set — paths preserved for inspection\n");
    process.exit(1);
  }
  process.exit(1);
}

// Success — cleanup.
try {
  await rm(scaffoldTmp, { recursive: true, force: true });
  await rm(installPrefix, { recursive: true, force: true });
  await unlink(tarballPath);
} catch (err) {
  // Cleanup error is non-fatal in dry-run mode (NFR-T51-003 idempotency).
  if (!DRY_RUN) {
    process.stderr.write(`[WARN] cleanup error (non-fatal): ${err.message}\n`);
  }
}
process.stdout.write("[PASS] T5.1 pre-publish smoke\n");
process.exit(0);
