import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { afterEach, beforeAll, beforeEach, describe, expect, it } from "vitest";

const CLI_ROOT = resolve(__dirname, "..", "..");
const CLI_ENTRY = resolve(CLI_ROOT, "dist", "index.js");
const REPO_ROOT = resolve(CLI_ROOT, "..");
const ASSETS_DIR = resolve(CLI_ROOT, "assets");
const BUNDLE_SCRIPT = resolve(CLI_ROOT, "scripts", "bundle-assets.mjs");

function run(args: string[], cwd?: string): { stdout: string; stderr: string; status: number } {
  const r = spawnSync(process.execPath, [CLI_ENTRY, ...args], {
    cwd,
    encoding: "utf8",
    env: { ...process.env, NO_COLOR: "1" },
  });
  return {
    stdout: r.stdout ?? "",
    stderr: r.stderr ?? "",
    status: r.status ?? 1,
  };
}

describe("@sdd-forge/cli (e2e — requires build)", () => {
  it("prints usage when invoked with --help", () => {
    const r = run(["--help"]);
    expect(r.status).toBe(0);
    expect(r.stdout).toMatch(/forge/i);
    expect(r.stdout).toMatch(/init/);
    expect(r.stdout).toMatch(/verify/);
    expect(r.stdout).toMatch(/version/);
  });

  it("`forge version` prints a SemVer", () => {
    const r = run(["version"]);
    expect(r.status).toBe(0);
    expect(r.stdout.trim()).toMatch(/^\d+\.\d+\.\d+(-[\w.-]+)?$/);
  });

  // Regression v0.3.2 : the J.8 --eu-tier flag was declared in init.ts
  // (EU_TIER_ENUM + validator) but never wired into commander, so users
  // hit `error: unknown option '--eu-tier'` on v0.3.0 / v0.3.1.
  it("`forge init --help` lists the --eu-tier flag", () => {
    const r = run(["init", "--help"]);
    expect(r.status).toBe(0);
    expect(r.stdout).toMatch(/--eu-tier/);
  });

  it("`forge init --target <tmp>` scaffolds against the repo", async () => {
    const target = await mkdtemp(join(tmpdir(), "forge-e2e-"));
    try {
      const r = run(["init", "--source", REPO_ROOT, "--target", target]);
      expect(r.status, `stderr:\n${r.stderr}`).toBe(0);
      expect(r.stdout).toMatch(/installed|copied|ok/i);

      // Spot checks
      const settings = spawnSync("test", [
        "-f",
        join(target, ".claude/settings.json"),
      ]);
      expect(settings.status).toBe(0);

      const leaked = spawnSync("test", [
        "-f",
        join(target, ".claude/settings.local.json"),
      ]);
      expect(leaked.status).not.toBe(0);
    } finally {
      await rm(target, { recursive: true, force: true });
    }
  });

  describe("published-tarball layout (bundled assets/)", () => {
    beforeAll(() => {
      // Simulate `npm publish` preparation: run the same bundle step prepack
      // would run. Required so `forge init` without --source has something to
      // copy from. Fails loudly if the bundle script is broken.
      const r = spawnSync(process.execPath, [BUNDLE_SCRIPT], {
        cwd: CLI_ROOT,
        encoding: "utf8",
      });
      if (r.status !== 0) {
        throw new Error(
          `bundle-assets.mjs failed (status=${r.status}):\n${r.stderr}`,
        );
      }
      if (!existsSync(ASSETS_DIR)) {
        throw new Error(`expected ${ASSETS_DIR} to exist after bundling`);
      }
    });

    it("`forge init --target <tmp>` (no --source) scaffolds from bundled assets", async () => {
      const target = await mkdtemp(join(tmpdir(), "forge-e2e-bundle-"));
      try {
        const r = run(["init", "--target", target]);
        expect(r.status, `stderr:\n${r.stderr}`).toBe(0);

        // Key artifacts that MUST land in a freshly-init'd project.
        for (const rel of [
          ".forge/constitution.md",
          ".claude/settings.json",
          "bin/forge-install.sh",
          ".mcp.json",
          "LICENSE",
          "NOTICE",
        ]) {
          expect(
            existsSync(join(target, rel)),
            `expected ${rel} to be scaffolded`,
          ).toBe(true);
        }

        // The CLI package itself must never be scaffolded into targets.
        expect(existsSync(join(target, "cli"))).toBe(false);
        // Private Claude Code config must never leak.
        expect(existsSync(join(target, ".claude/settings.local.json"))).toBe(
          false,
        );
      } finally {
        await rm(target, { recursive: true, force: true });
      }
    });
  });
});
