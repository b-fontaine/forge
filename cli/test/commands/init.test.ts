import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { initCommand } from "../../src/commands/init.js";

describe("initCommand (integration)", () => {
  let source: string;
  let target: string;

  beforeEach(async () => {
    source = await mkdtemp(join(tmpdir(), "forge-src-"));
    target = await mkdtemp(join(tmpdir(), "forge-dst-"));
  });

  afterEach(async () => {
    await rm(source, { recursive: true, force: true });
    await rm(target, { recursive: true, force: true });
  });

  async function seedSource(files: Record<string, string>): Promise<void> {
    for (const [rel, contents] of Object.entries(files)) {
      const full = join(source, rel);
      await mkdir(join(full, ".."), { recursive: true });
      await writeFile(full, contents);
    }
  }

  it("copies whitelisted files into an empty target", async () => {
    await seedSource({
      "CLAUDE.md": "# root instructions\n",
      "VERSION": "0.1.0\n",
      ".forge/constitution.md": "# Constitution\n",
    });

    const result = await initCommand({ sourceDir: source, targetDir: target, force: false });

    expect(result.errors).toEqual([]);
    expect(await readFile(join(target, "CLAUDE.md"), "utf8")).toBe(
      "# root instructions\n",
    );
    expect(await readFile(join(target, "VERSION"), "utf8")).toBe("0.1.0\n");
    expect(await readFile(join(target, ".forge/constitution.md"), "utf8")).toBe(
      "# Constitution\n",
    );
  });

  it("never copies .claude/settings.local.json", async () => {
    await seedSource({
      ".claude/settings.json": "{}\n",
      ".claude/settings.local.json": '{"secret":"xyz"}\n',
    });

    await initCommand({ sourceDir: source, targetDir: target, force: true });

    await expect(
      readFile(join(target, ".claude/settings.local.json"), "utf8"),
    ).rejects.toThrow();
    expect(await readFile(join(target, ".claude/settings.json"), "utf8")).toBe(
      "{}\n",
    );
  });

  it("scaffolds .forge/product/* from templates, never from source product/", async () => {
    await seedSource({
      ".forge/product/mission.md": "FORGE'S OWN MISSION — must not leak\n",
      ".forge/templates/product/mission.md": "# Product Mission\n\n<!-- fill me -->\n",
    });

    await initCommand({ sourceDir: source, targetDir: target, force: false });

    const scaffolded = await readFile(
      join(target, ".forge/product/mission.md"),
      "utf8",
    );
    expect(scaffolded).toBe("# Product Mission\n\n<!-- fill me -->\n");
    expect(scaffolded).not.toContain("FORGE'S OWN MISSION");
    expect(
      await readFile(join(target, ".forge/templates/product/mission.md"), "utf8"),
    ).toBe("# Product Mission\n\n<!-- fill me -->\n");
  });

  it("preserves user product content even when force is true", async () => {
    await seedSource({
      ".forge/templates/product/mission.md": "# Product Mission\n<!-- fill -->\n",
    });
    await mkdir(join(target, ".forge/product"), { recursive: true });
    await writeFile(
      join(target, ".forge/product/mission.md"),
      "## my real mission\n",
    );

    await initCommand({ sourceDir: source, targetDir: target, force: true });

    expect(
      await readFile(join(target, ".forge/product/mission.md"), "utf8"),
    ).toBe("## my real mission\n");
  });

  it("is idempotent: second run copies zero additional files without --force", async () => {
    await seedSource({
      "CLAUDE.md": "# root\n",
      ".forge/constitution.md": "# constitution\n",
    });

    const first = await initCommand({ sourceDir: source, targetDir: target, force: false });
    const second = await initCommand({ sourceDir: source, targetDir: target, force: false });

    const firstCopies = first.ops.filter((op) => op.type === "copy").length;
    const secondCopies = second.ops.filter((op) => op.type === "copy").length;
    expect(firstCopies).toBeGreaterThan(0);
    expect(secondCopies).toBe(0);
  });
});
