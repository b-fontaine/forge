import { describe, expect, it } from "vitest";
import { parseVersion } from "../../src/domain/version.js";

describe("parseVersion", () => {
  it("trims trailing newline from VERSION file contents", () => {
    expect(parseVersion("0.1.0\n")).toBe("0.1.0");
  });

  it("throws on content that is not a valid SemVer", () => {
    expect(() => parseVersion("not-a-version\n")).toThrow(
      /invalid version/i,
    );
  });
});
