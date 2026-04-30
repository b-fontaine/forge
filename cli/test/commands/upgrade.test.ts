import { describe, expect, it, vi } from "vitest";
import { upgradeCommand } from "../../src/commands/upgrade.js";

const baseDeps = (overrides: Record<string, unknown> = {}) => {
  const runner = vi.fn().mockResolvedValue({ exitCode: 0 });
  const readManifest = vi.fn().mockResolvedValue({
    archetype: "full-stack-monorepo",
    archetype_version: "1.0.0",
  });
  const resolveFrameworkVersion = vi.fn().mockResolvedValue("1.1.0");
  const writeLine = vi.fn();
  const writeError = vi.fn();
  return {
    options: {
      targetDir: "/proj",
      dryRun: false,
      force: false,
      verbose: false,
    },
    runner,
    readManifest,
    resolveFrameworkVersion,
    shellDriverPath: "/forge/bin/forge-upgrade.sh",
    writeLine,
    writeError,
    ...overrides,
  };
};

describe("upgradeCommand", () => {
  it("spawns the shell driver with required flags and propagates exit 0", async () => {
    const deps = baseDeps();
    const rc = await upgradeCommand(deps);
    expect(rc).toBe(0);
    expect(deps.runner).toHaveBeenCalledTimes(1);
    expect(deps.runner).toHaveBeenCalledWith({
      script: "/forge/bin/forge-upgrade.sh",
      args: [
        "--target",
        "/proj",
        "--to-version",
        "1.1.0",
      ],
      cwd: "/proj",
    });
    expect(deps.writeError).not.toHaveBeenCalled();
  });

  it("forwards --dry-run and --force and --verbose flags", async () => {
    const deps = baseDeps({
      options: {
        targetDir: "/proj",
        dryRun: true,
        force: true,
        verbose: true,
      },
    });
    await upgradeCommand(deps);
    expect(deps.runner).toHaveBeenCalledWith({
      script: "/forge/bin/forge-upgrade.sh",
      args: [
        "--target",
        "/proj",
        "--to-version",
        "1.1.0",
        "--dry-run",
        "--force",
        "--verbose",
      ],
      cwd: "/proj",
    });
  });

  it("returns exit 2 when manifest is missing", async () => {
    const readManifest = vi.fn().mockResolvedValue(null);
    const deps = baseDeps({ readManifest });
    const rc = await upgradeCommand(deps);
    expect(rc).toBe(2);
    expect(deps.runner).not.toHaveBeenCalled();
    expect(deps.writeError).toHaveBeenCalledWith(
      expect.stringContaining("not a Forge project"),
    );
  });

  it("returns exit 2 when framework version cannot be resolved", async () => {
    const resolveFrameworkVersion = vi
      .fn()
      .mockRejectedValue(new Error("schema.yaml missing"));
    const deps = baseDeps({ resolveFrameworkVersion });
    const rc = await upgradeCommand(deps);
    expect(rc).toBe(2);
    expect(deps.runner).not.toHaveBeenCalled();
    expect(deps.writeError).toHaveBeenCalledWith(
      expect.stringContaining("could not resolve framework version"),
    );
  });

  it("propagates non-zero exit codes from the shell driver", async () => {
    const runner = vi.fn().mockResolvedValue({ exitCode: 8 });
    const deps = baseDeps({ runner });
    const rc = await upgradeCommand(deps);
    expect(rc).toBe(8);
  });
});
