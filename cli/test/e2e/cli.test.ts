import { spawnSync } from "node:child_process";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

const CLI_ENTRY = resolve(__dirname, "..", "..", "dist", "index.js");
const REPO_ROOT = resolve(__dirname, "..", "..", "..");

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
});
