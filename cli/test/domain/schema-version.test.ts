import { describe, expect, it } from "vitest";
import {
  compareSemver,
  parseSchemaMeta,
  selectScaffoldableVersion,
} from "../../src/domain/schema-version.js";

// B.8.14 (b8-14-promotion-flip C2) — versioned-schema selection + the deferred
// B.8.3.b scaffoldable:false guard.

describe("parseSchemaMeta", () => {
  it("treats a stable schema with no scaffoldable key as scaffoldable (b8-3b T-010)", () => {
    // The frozen 1.0.0 schema.yaml: stable, no `scaffoldable` field.
    const meta = parseSchemaMeta('name: full-stack-monorepo\nversion: "1.0.0"\nstage: stable\n');
    expect(meta).toEqual({ version: "1.0.0", stage: "stable", scaffoldable: true });
  });

  it("honours an explicit scaffoldable:false on a candidate", () => {
    const meta = parseSchemaMeta('version: "2.0.0"\nstage: candidate\nscaffoldable: false\n');
    expect(meta).toEqual({ version: "2.0.0", stage: "candidate", scaffoldable: false });
  });

  it("parses the promoted 2.0.0 schema (stable + scaffoldable:true)", () => {
    const meta = parseSchemaMeta('version: "2.0.0"\nstage: stable\nscaffoldable: true    # promoted\n');
    expect(meta).toEqual({ version: "2.0.0", stage: "stable", scaffoldable: true });
  });

  it("returns null when there is no version field", () => {
    expect(parseSchemaMeta("name: something\nstage: stable\n")).toBeNull();
  });

  it("does not treat a non-stable stage without a scaffoldable key as scaffoldable", () => {
    const meta = parseSchemaMeta('version: "0.9.0"\nstage: draft\n');
    expect(meta).toEqual({ version: "0.9.0", stage: "draft", scaffoldable: false });
  });
});

describe("compareSemver", () => {
  it("orders by major/minor/patch", () => {
    expect(compareSemver("2.0.0", "1.0.0")).toBe(1);
    expect(compareSemver("1.0.0", "2.0.0")).toBe(-1);
    expect(compareSemver("1.2.0", "1.1.9")).toBe(1);
    expect(compareSemver("1.0.0", "1.0.0")).toBe(0);
  });

  it("ranks a release above a prerelease of the same x.y.z", () => {
    expect(compareSemver("1.0.0", "1.0.0-rc.1")).toBe(1);
    expect(compareSemver("1.0.0-rc.1", "1.0.0")).toBe(-1);
  });
});

describe("selectScaffoldableVersion", () => {
  it("picks the highest stable + scaffoldable version (1.0.0 + 2.0.0 → 2.0.0)", () => {
    const chosen = selectScaffoldableVersion([
      { version: "1.0.0", stage: "stable", scaffoldable: true },
      { version: "2.0.0", stage: "stable", scaffoldable: true },
    ]);
    expect(chosen?.version).toBe("2.0.0");
  });

  it("ignores a non-scaffoldable candidate and keeps the stable 1.0.0", () => {
    const chosen = selectScaffoldableVersion([
      { version: "1.0.0", stage: "stable", scaffoldable: true },
      { version: "2.0.0", stage: "candidate", scaffoldable: false },
    ]);
    expect(chosen?.version).toBe("1.0.0");
  });

  it("returns null when no version is stable + scaffoldable (B.8.3.b refusal)", () => {
    expect(
      selectScaffoldableVersion([
        { version: "2.0.0", stage: "candidate", scaffoldable: false },
        { version: "0.9.0", stage: "draft", scaffoldable: false },
      ]),
    ).toBeNull();
    expect(selectScaffoldableVersion([])).toBeNull();
  });
});
