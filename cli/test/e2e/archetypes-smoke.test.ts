// Audit: T5.1 (cli-trust-harness)
//
// Layer T5.1.B — smoke test per archetype (FR-T51-040..055).
//
// For each active archetype in dispatch-table.yml (skipping `default`,
// `removed_from_roadmap`, and `legacy_alias` entries whose target is
// also present), this suite :
//
//   1. Creates a tmpdir path that does NOT yet exist on disk (exercises
//      the v0.3.2 `mkdir -p` fix in init-archetype.ts:148).
//   2. Invokes `forge init <slug> --archetype <name> --org dev.forge.test
//      --target <tmp>` and asserts exit 0.
//   3. Loads the per-archetype YAML fixture under archetype-fixtures/
//      and asserts every `required_paths:` entry exists + every
//      `forbidden_paths:` entry is absent (FR-T51-045).
//   4. Runs `task --list-all` on the scaffolded tmpdir if `task` is on
//      PATH ; skip-pass otherwise (ADR-T51-001 / FR-T51-049).
//   5. When `FORGE_E2E_TOOLCHAINS=1` AND the relevant toolchain is on
//      PATH, runs `cargo check --workspace` / `flutter analyze` per
//      fixture flags (FR-T51-050 / FR-T51-051).

import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { afterAll, describe, expect, it } from "vitest";

import { parseDispatchTable } from "../../src/domain/dispatch-table.js";
import { loadFixture } from "./helpers/load-fixture.js";

const CLI_ROOT = resolve(__dirname, "..", "..");
const CLI_ENTRY = resolve(CLI_ROOT, "dist", "index.js");
const REPO_ROOT = resolve(CLI_ROOT, "..");
const DISPATCH_TABLE_PATH = resolve(
  REPO_ROOT,
  ".forge/scaffolding/dispatch-table.yml",
);
const FIXTURES_DIR = resolve(__dirname, "archetype-fixtures");

function commandOnPath(cmd: string): boolean {
  const r = spawnSync("sh", ["-c", `command -v ${cmd}`], { encoding: "utf8" });
  return r.status === 0;
}

interface ActiveArchetype {
  name: string;
  status?: string;
}

function activeArchetypes(): ActiveArchetype[] {
  const yaml = readFileSync(DISPATCH_TABLE_PATH, "utf8");
  const table = parseDispatchTable(yaml);
  return Object.values(table.archetypes)
    .filter((e) => e.name !== "default") // covered by cli.test.ts
    .filter((e) => e.status !== "removed_from_roadmap")
    .map((e) => ({ name: e.name, status: e.status }));
}

/**
 * Derive a slug satisfying BOTH archetypes' constraints :
 * - full-stack-monorepo accepts kebab-case.
 * - mobile-only requires [a-z][a-z0-9_]+ (no dashes).
 * Using underscores everywhere is safe for all current and future
 * archetypes assuming they pin to lowercase alphanumerics + underscores.
 */
function slugFor(archetypeName: string): string {
  return `smoke_${archetypeName.replace(/-/g, "_")}`;
}

const createdTmpdirs: string[] = [];

afterAll(async () => {
  for (const t of createdTmpdirs) {
    await rm(t, { recursive: true, force: true });
  }
});

describe("T5.1.B — smoke per archetype", () => {
  const archetypes = activeArchetypes();

  it("dispatch-table cross-reference: every active archetype has a fixture (FR-T51-055)", () => {
    for (const a of archetypes) {
      const path = join(FIXTURES_DIR, `${a.name}.yml`);
      expect(
        existsSync(path),
        `T5.1 smoke: archetype '${a.name}' lacks a fixture. Add ${path}.`,
      ).toBe(true);
    }
  });

  it.each(archetypes.map((a) => [a.name]))(
    "scaffolds %s + file matrix + task --list-all",
    async (archetypeName) => {
      const tmp = await mkdtemp(join(tmpdir(), `forge-smoke-${archetypeName}-`));
      // Delete so `forge init` exercises the mkdir -p path from v0.3.2.
      await rm(tmp, { recursive: true, force: true });
      createdTmpdirs.push(tmp);

      const slug = slugFor(archetypeName);
      const r = spawnSync(
        process.execPath,
        [
          CLI_ENTRY,
          "init",
          slug,
          "--archetype",
          archetypeName,
          "--org",
          "dev.forge.test",
          "--target",
          tmp,
        ],
        {
          encoding: "utf8",
          env: { ...process.env, NO_COLOR: "1" },
        },
      );
      expect(
        r.status,
        `forge init exited ${r.status} for archetype ${archetypeName}:\n${r.stderr}`,
      ).toBe(0);

      // File matrix.
      const fixture = loadFixture(archetypeName, FIXTURES_DIR);
      for (const p of fixture.required_paths) {
        expect(
          existsSync(join(tmp, p)),
          `archetype '${archetypeName}': required path missing: ${p}`,
        ).toBe(true);
      }
      for (const p of fixture.forbidden_paths) {
        expect(
          existsSync(join(tmp, p)),
          `archetype '${archetypeName}': forbidden path present: ${p}`,
        ).toBe(false);
      }

      // task --list-all — skip-pass when `task` absent (ADR-T51-001)
      // OR when the archetype doesn't ship a `Taskfile.yml` at scaffold
      // root (mobile-only is intentionally Taskfile-less).
      const taskfileLocal = existsSync(join(tmp, "Taskfile.yml"));
      if (!taskfileLocal) {
        // eslint-disable-next-line no-console
        console.log(
          `[INFO: archetype '${archetypeName}' ships no Taskfile.yml — task --list-all skipped]`,
        );
      } else if (commandOnPath("task")) {
        const t = spawnSync("task", ["--list-all"], {
          cwd: tmp,
          encoding: "utf8",
        });
        expect(
          t.status,
          `archetype '${archetypeName}': 'task --list-all' failed:\n${t.stderr}`,
        ).toBe(0);
      } else {
        // eslint-disable-next-line no-console
        console.log(
          `[INFO: task absent on PATH — skipped per ADR-T51-001 for archetype ${archetypeName}]`,
        );
      }

      // Opt-in tighter checks gated on FORGE_E2E_TOOLCHAINS=1.
      if (process.env.FORGE_E2E_TOOLCHAINS === "1") {
        if (fixture.has_rust_backend && commandOnPath("cargo")) {
          const c = spawnSync("cargo", ["check", "--workspace"], {
            cwd: join(tmp, "backend"),
            encoding: "utf8",
          });
          expect(
            c.status,
            `archetype '${archetypeName}': 'cargo check --workspace' failed:\n${c.stderr}`,
          ).toBe(0);
        }
        if (fixture.has_flutter_frontend && commandOnPath("flutter")) {
          // mobile-only puts Flutter at root ; fsm puts it under frontend/.
          const cwd =
            archetypeName === "mobile-only" ? tmp : join(tmp, "frontend");
          const f = spawnSync("flutter", ["analyze"], { cwd, encoding: "utf8" });
          expect(
            f.status,
            `archetype '${archetypeName}': 'flutter analyze' failed:\n${f.stderr}`,
          ).toBe(0);
        }
      }
    },
    /* per-archetype timeout in ms */ 60_000,
  );
});
