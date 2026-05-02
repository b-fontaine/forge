import { describe, expect, it, vi } from "vitest";
import { versionCommand } from "../../src/commands/version.js";

describe("versionCommand", () => {
  it("prints the parsed version and returns exit code 0", async () => {
    const writeLine = vi.fn();
    const writeError = vi.fn();
    const readFile = vi.fn().mockResolvedValue("0.1.0\n");

    const rc = await versionCommand({
      readFile,
      writeLine,
      writeError,
      versionFilePath: "/fake/VERSION",
    });

    expect(readFile).toHaveBeenCalledWith("/fake/VERSION");
    expect(writeLine).toHaveBeenCalledWith("0.1.0");
    expect(writeError).not.toHaveBeenCalled();
    expect(rc).toBe(0);
  });

  it("reports an error and returns exit code 1 if VERSION is malformed", async () => {
    const writeLine = vi.fn();
    const writeError = vi.fn();
    const readFile = vi.fn().mockResolvedValue("garbage\n");

    const rc = await versionCommand({
      readFile,
      writeLine,
      writeError,
      versionFilePath: "/fake/VERSION",
    });

    expect(writeLine).not.toHaveBeenCalled();
    expect(writeError).toHaveBeenCalledOnce();
    expect(writeError.mock.calls[0][0]).toMatch(/invalid version/i);
    expect(rc).toBe(1);
  });

  it("reports an error and returns exit code 1 if VERSION is unreadable", async () => {
    const writeLine = vi.fn();
    const writeError = vi.fn();
    const readFile = vi
      .fn()
      .mockRejectedValue(new Error("ENOENT: no such file"));

    const rc = await versionCommand({
      readFile,
      writeLine,
      writeError,
      versionFilePath: "/fake/VERSION",
    });

    expect(writeError).toHaveBeenCalledOnce();
    expect(writeError.mock.calls[0][0]).toMatch(/ENOENT/);
    expect(rc).toBe(1);
  });
});
