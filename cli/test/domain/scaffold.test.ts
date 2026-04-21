import { describe, expect, it } from "vitest";
import { scaffoldPlan } from "../../src/domain/scaffold.js";

describe("scaffoldPlan", () => {
  it("copies a whitelisted root file when the target is empty", () => {
    const plan = scaffoldPlan({
      sourceFiles: ["CLAUDE.md"],
      targetExisting: new Set(),
      force: false,
    });

    expect(plan).toEqual([{ type: "copy", src: "CLAUDE.md", dst: "CLAUDE.md" }]);
  });

  it("skips a file that already exists in target when force is false", () => {
    const plan = scaffoldPlan({
      sourceFiles: ["CLAUDE.md"],
      targetExisting: new Set(["CLAUDE.md"]),
      force: false,
    });

    expect(plan).toEqual([
      { type: "skip", dst: "CLAUDE.md", reason: "exists" },
    ]);
  });

  it("overwrites a file that already exists when force is true", () => {
    const plan = scaffoldPlan({
      sourceFiles: ["CLAUDE.md"],
      targetExisting: new Set(["CLAUDE.md"]),
      force: true,
    });

    expect(plan).toEqual([
      { type: "copy", src: "CLAUDE.md", dst: "CLAUDE.md" },
    ]);
  });

  it("never copies .claude/settings.local.json (private user state)", () => {
    const plan = scaffoldPlan({
      sourceFiles: [".claude/settings.local.json", ".claude/settings.json"],
      targetExisting: new Set(),
      force: true,
    });

    const copiedPaths = plan
      .filter((op) => op.type === "copy")
      .map((op) => op.dst);

    expect(copiedPaths).toContain(".claude/settings.json");
    expect(copiedPaths).not.toContain(".claude/settings.local.json");
  });

  it("never copies source .forge/product/* (user content territory)", () => {
    const plan = scaffoldPlan({
      sourceFiles: [
        ".forge/product/mission.md",
        ".forge/product/roadmap.md",
        ".forge/product/tech-stack.md",
      ],
      targetExisting: new Set(),
      force: true,
    });

    const copies = plan.filter((op) => op.type === "copy");
    expect(copies).toEqual([]);
  });

  it("scaffolds .forge/product/<name>.md from a template when target has none", () => {
    const plan = scaffoldPlan({
      sourceFiles: [".forge/templates/product/mission.md"],
      targetExisting: new Set(),
      force: false,
    });

    expect(plan).toContainEqual({
      type: "copy",
      src: ".forge/templates/product/mission.md",
      dst: ".forge/templates/product/mission.md",
    });
    expect(plan).toContainEqual({
      type: "scaffold",
      src: ".forge/templates/product/mission.md",
      dst: ".forge/product/mission.md",
    });
  });

  it("never overwrites an existing .forge/product/<name>.md even with force", () => {
    const plan = scaffoldPlan({
      sourceFiles: [".forge/templates/product/mission.md"],
      targetExisting: new Set([".forge/product/mission.md"]),
      force: true,
    });

    const scaffolds = plan.filter((op) => op.type === "scaffold");
    expect(scaffolds).toEqual([]);
    expect(plan).toContainEqual({
      type: "skip",
      dst: ".forge/product/mission.md",
      reason: "user-content-preserved",
    });
  });

  it("never copies runtime state dirs (.forge/_memory, .forge/changes, .forge/specs)", () => {
    const plan = scaffoldPlan({
      sourceFiles: [
        ".forge/_memory/some-cache.json",
        ".forge/changes/old-feature/proposal.md",
        ".forge/specs/legacy.md",
      ],
      targetExisting: new Set(),
      force: true,
    });

    const copies = plan.filter((op) => op.type === "copy");
    expect(copies).toEqual([]);
  });
});
