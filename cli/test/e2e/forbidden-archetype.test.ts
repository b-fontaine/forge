// Audit: t7-forbidden-archetypes-wiring (FR-T7FA-001..004)
//
// J.8's forbidden_archetypes refusal (FR-J8-020 / ADR-J8-003) was specified, coded at
// init-archetype.ts:159-171, and documented in docs/ARCHETYPES.md:103 and
// global/janus-orchestration-rules.md — and unreachable, because
// parseDispatchTable returned `{ archetypes }` and never read the block. A real run
// exited 127 with `bash: .../cli/assets/<removed>: No such file or directory`.
//
// These cases exist because the parse fix alone would leave the next regression as
// invisible as this one was: J.8 shipped the refusal with nothing that runs it.

import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { afterAll, describe, expect, it } from "vitest";

import { parseDispatchTable } from "../../src/domain/dispatch-table.js";

const CLI_ROOT = resolve(__dirname, "..", "..");
const CLI_ENTRY = resolve(CLI_ROOT, "dist", "index.js");
const REPO_ROOT = resolve(CLI_ROOT, "..");
const DISPATCH_TABLE_PATH = resolve(
  REPO_ROOT,
  ".forge/scaffolding/dispatch-table.yml",
);

const created: string[] = [];
afterAll(async () => {
  for (const d of created) await rm(d, { recursive: true, force: true });
});

describe("J.8 — forbidden_archetypes refusal", () => {
  const table = parseDispatchTable(readFileSync(DISPATCH_TABLE_PATH, "utf8"));

  // FR-T7FA-001 — the producer exists at all.
  it("parseDispatchTable returns the forbidden_archetypes block", () => {
    expect(table.forbidden_archetypes).toBeDefined();
    expect(table.forbidden_archetypes!.length).toBeGreaterThan(0);
  });

  // FR-T7FA-005 — and every entry carries the five keys the refusal message formats.
  // A missing key would render as `undefined` inside the structured line rather than
  // fail, which is the quiet kind of wrong.
  it("every entry carries name / reason / since / alternative / rule_id", () => {
    for (const e of table.forbidden_archetypes ?? []) {
      for (const k of [
        "name",
        "reason",
        "since",
        "alternative",
        "rule_id",
      ] as const) {
        expect(e[k], `entry ${e.name}: ${k}`).toBeTruthy();
      }
    }
  });

  it("flutter-firebase is the J8-RULE-001 entry", () => {
    const ff = (table.forbidden_archetypes ?? []).find(
      (e) => e.name === "flutter-firebase",
    );
    expect(ff).toBeDefined();
    expect(ff!.rule_id).toBe("J8-RULE-001");
  });

  // FR-T7FA-002 / FR-T7FA-003 — the behaviour, end to end. Before this change the
  // same invocation exited 127 with a locale-dependent shell error.
  it("forge init --archetype flutter-firebase refuses with exit 3 and renders nothing", async () => {
    if (!existsSync(CLI_ENTRY)) {
      // Matches the suite's convention: the built CLI is a precondition, not a subject.
      return;
    }
    const tmp = await mkdtemp(join(tmpdir(), "forge-j8-"));
    created.push(tmp);

    const r = spawnSync(
      process.execPath,
      [
        CLI_ENTRY,
        "init",
        "ffprobe",
        "--archetype",
        "flutter-firebase",
        "--org",
        "dev.forge.test",
      ],
      { cwd: tmp, encoding: "utf8" },
    );

    expect(r.status, `stderr: ${r.stderr}`).toBe(3);
    expect(r.stderr).toContain("[REFUSAL: flutter-firebase: J8-RULE-001:");
    expect(r.stderr).toContain("alternative:");
    // A clean refusal leaves nothing behind.
    expect(existsSync(join(tmp, "ffprobe"))).toBe(false);
  });
});
