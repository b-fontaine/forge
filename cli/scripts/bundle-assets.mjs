#!/usr/bin/env node
// Copies whitelisted repo-root assets into cli/assets/ so that the published
// @sdd-forge/cli tarball contains everything `forge init` needs to scaffold a
// project (constitution, standards, schemas, templates, Claude Code assets,
// installer script, docs). Filtering rules live in src/domain/bundle.ts and
// are covered by unit tests.
import { copyFile, mkdir, readdir, rm, stat } from "node:fs/promises";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { bundlePlan } from "../dist/domain/bundle.js";

const HERE = dirname(fileURLToPath(import.meta.url));
const CLI_DIR = resolve(HERE, "..");
const REPO_ROOT = resolve(CLI_DIR, "..");
const ASSETS_DIR = resolve(CLI_DIR, "assets");

const TOP_LEVEL_SKIP = new Set([
  "cli",
  "node_modules",
  ".git",
  ".idea",
  ".vscode",
  ".omc",
  "dist",
  "coverage",
  "build",
  ".next",
  ".turbo",
]);

async function walkRoot(root) {
  const out = [];
  async function visit(dir, depth) {
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      if (depth === 0 && entry.isDirectory() && TOP_LEVEL_SKIP.has(entry.name)) {
        continue;
      }
      const full = join(dir, entry.name);
      if (entry.isDirectory()) {
        await visit(full, depth + 1);
      } else if (entry.isFile()) {
        out.push(relative(root, full).split(sep).join("/"));
      }
    }
  }
  await visit(root, 0);
  return out;
}

async function pathExists(p) {
  try {
    await stat(p);
    return true;
  } catch {
    return false;
  }
}

async function main() {
  if (await pathExists(ASSETS_DIR)) {
    await rm(ASSETS_DIR, { recursive: true, force: true });
  }
  const rootFiles = await walkRoot(REPO_ROOT);
  const selected = bundlePlan({ rootFiles });
  for (const rel of selected) {
    const src = join(REPO_ROOT, rel);
    const dst = join(ASSETS_DIR, rel);
    await mkdir(dirname(dst), { recursive: true });
    await copyFile(src, dst);
  }
  process.stdout.write(`bundle-assets: ${selected.length} files → ${relative(CLI_DIR, ASSETS_DIR)}/\n`);
}

main().catch((err) => {
  process.stderr.write(`bundle-assets: ${err.message}\n`);
  process.exit(1);
});
