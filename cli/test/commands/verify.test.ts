import { describe, expect, it, vi } from "vitest";
import { verifyCommand } from "../../src/commands/verify.js";

describe("verifyCommand", () => {
  it("runs both scripts and returns 0 when both succeed", async () => {
    const runner = vi.fn().mockResolvedValue({ exitCode: 0 });
    const writeLine = vi.fn();
    const writeError = vi.fn();

    const rc = await verifyCommand({
      runner,
      writeLine,
      writeError,
      targetDir: "/proj",
    });

    expect(runner).toHaveBeenCalledTimes(2);
    expect(runner).toHaveBeenNthCalledWith(1, {
      script: "/proj/.forge/scripts/verify.sh",
      cwd: "/proj",
    });
    expect(runner).toHaveBeenNthCalledWith(2, {
      script: "/proj/.forge/scripts/constitution-linter.sh",
      cwd: "/proj",
    });
    expect(rc).toBe(0);
    expect(writeError).not.toHaveBeenCalled();
  });

  it("returns 1 if either script fails, and still runs both", async () => {
    const runner = vi
      .fn()
      .mockResolvedValueOnce({ exitCode: 0 })
      .mockResolvedValueOnce({ exitCode: 1 });
    const writeLine = vi.fn();
    const writeError = vi.fn();

    const rc = await verifyCommand({
      runner,
      writeLine,
      writeError,
      targetDir: "/proj",
    });

    expect(runner).toHaveBeenCalledTimes(2);
    expect(rc).toBe(1);
  });

  it("returns 2 and skips run if a script is missing", async () => {
    const runner = vi
      .fn()
      .mockRejectedValueOnce(
        Object.assign(new Error("ENOENT"), { code: "ENOENT" }),
      );
    const writeLine = vi.fn();
    const writeError = vi.fn();

    const rc = await verifyCommand({
      runner,
      writeLine,
      writeError,
      targetDir: "/proj",
    });

    expect(rc).toBe(2);
    expect(writeError).toHaveBeenCalledWith(
      expect.stringMatching(/not found|ENOENT/i),
    );
  });
});
