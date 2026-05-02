import { describe, expect, it } from "vitest";
import { bundlePlan } from "../../src/domain/bundle.js";

describe("bundlePlan", () => {
  it("includes top-level Forge assets (.forge, .claude, bin, docs, root files)", () => {
    const files = [
      ".forge/constitution.md",
      ".forge/standards/index.yml",
      ".forge/templates/product/mission.md",
      ".claude/settings.json",
      ".claude/commands/forge.md",
      "bin/forge-install.sh",
      "docs/GUIDE.md",
      ".mcp.json",
      "LICENSE",
      "NOTICE",
      "CLAUDE.md",
    ];
    expect(bundlePlan({ rootFiles: files })).toEqual(files);
  });

  it("excludes the cli/ subtree (the CLI package itself must not be scaffolded into targets)", () => {
    const files = [
      ".forge/constitution.md",
      "cli/src/cli.ts",
      "cli/package.json",
      "cli/assets/some-stale-file",
    ];
    expect(bundlePlan({ rootFiles: files })).toEqual([
      ".forge/constitution.md",
    ]);
  });

  it("excludes .claude/settings.local.json", () => {
    expect(
      bundlePlan({
        rootFiles: [".claude/settings.json", ".claude/settings.local.json"],
      }),
    ).toEqual([".claude/settings.json"]);
  });

  it("excludes .forge runtime state (product, _memory, changes, specs)", () => {
    const files = [
      ".forge/constitution.md",
      ".forge/product/mission.md",
      ".forge/_memory/foo.json",
      ".forge/changes/x/spec.md",
      ".forge/specs/y.md",
      ".forge/templates/product/mission.md",
    ];
    expect(bundlePlan({ rootFiles: files })).toEqual([
      ".forge/constitution.md",
      ".forge/templates/product/mission.md",
    ]);
  });

  it("excludes dev / build / editor dirs", () => {
    const files = [
      ".forge/constitution.md",
      "node_modules/foo/index.js",
      ".git/HEAD",
      ".idea/workspace.xml",
      ".vscode/settings.json",
      ".omc/notepad.md",
      "dist/index.js",
      "coverage/lcov.info",
      "build/out.js",
      ".next/cache",
      ".turbo/x",
    ];
    expect(bundlePlan({ rootFiles: files })).toEqual([
      ".forge/constitution.md",
    ]);
  });
});
