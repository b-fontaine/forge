import { describe, expect, it } from "vitest";
import { detectArchetype } from "../../src/domain/archetype-detect.js";

const registrations = [
  { name: "default", signals: [] },
  {
    name: "full-stack-monorepo",
    signals: ["pubspec.yaml", "Cargo.toml"],
  },
];

describe("detectArchetype", () => {
  it("matches full-stack-monorepo when both signals present", () => {
    const r = detectArchetype(registrations, {
      "pubspec.yaml": true,
      "Cargo.toml": true,
    });
    expect(r.kind).toBe("match");
    if (r.kind === "match") expect(r.archetype).toBe("full-stack-monorepo");
  });

  it("returns ambiguous when only pubspec.yaml present", () => {
    const r = detectArchetype(registrations, {
      "pubspec.yaml": true,
      "Cargo.toml": false,
    });
    expect(r.kind).toBe("ambiguous");
    if (r.kind === "ambiguous") {
      expect(r.candidates).toContain("full-stack-monorepo");
      expect(r.detected).toContain("pubspec.yaml");
    }
  });

  it("returns ambiguous when only Cargo.toml present", () => {
    const r = detectArchetype(registrations, {
      "pubspec.yaml": false,
      "Cargo.toml": true,
    });
    expect(r.kind).toBe("ambiguous");
  });

  it("returns none for empty signals", () => {
    const r = detectArchetype(registrations, {});
    expect(r.kind).toBe("none");
  });

  it("returns none when all signals are false", () => {
    const r = detectArchetype(registrations, {
      "pubspec.yaml": false,
      "Cargo.toml": false,
    });
    expect(r.kind).toBe("none");
  });
});
