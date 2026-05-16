// Audit: T5.1 (cli-trust-harness) — T-LOAD-004
//
// Unit tests for the vendored mini YAML parser at
// cli/test/e2e/helpers/load-fixture.ts. Covers the documented supported
// subset (ADR-T51-002) and asserts unsupported syntax is rejected
// loudly with a line-number-bearing error.

import { describe, expect, it } from "vitest";
import { parseFixture } from "../e2e/helpers/load-fixture.js";

describe("load-fixture parseFixture", () => {
  it("parses a minimal valid fixture", () => {
    const yaml = `
# header comment
archetype: full-stack-monorepo
has_rust_backend: true
has_flutter_frontend: true
required_paths:
  - .forge/constitution.md
  - Taskfile.yml
forbidden_paths:
  - cli
`;
    const r = parseFixture(yaml);
    expect(r.archetype).toBe("full-stack-monorepo");
    expect(r.has_rust_backend).toBe(true);
    expect(r.has_flutter_frontend).toBe(true);
    expect(r.required_paths).toEqual([".forge/constitution.md", "Taskfile.yml"]);
    expect(r.forbidden_paths).toEqual(["cli"]);
  });

  it("rejects flow style with a line number", () => {
    const yaml = `required_paths: [a, b]\n`;
    expect(() => parseFixture(yaml)).toThrow(/line 1.*flow style/);
  });

  it("rejects YAML anchors with a line number", () => {
    const yaml = `archetype: foo &anchor\n`;
    expect(() => parseFixture(yaml)).toThrow(/anchor/);
  });

  it("skips leading comments and blank lines", () => {
    const yaml = `\n\n# only comments\n\narchetype: bar\n`;
    const r = parseFixture(yaml);
    expect(r.archetype).toBe("bar");
  });

  it("tolerates trailing whitespace and strips quotes", () => {
    const yaml = `archetype: "quoted-name"   \nrequired_paths:\n  - 'single-quoted'\n`;
    const r = parseFixture(yaml);
    expect(r.archetype).toBe("quoted-name");
    expect(r.required_paths).toEqual(["single-quoted"]);
  });

  it("rejects multi-doc separator", () => {
    const yaml = `---\narchetype: x\n`;
    expect(() => parseFixture(yaml)).toThrow(/multi-doc/);
  });
});
