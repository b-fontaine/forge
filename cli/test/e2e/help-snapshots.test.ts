// Audit: T5.1 (cli-trust-harness)
//
// Layer T5.1.A — golden snapshots of every subcommand's `--help` output
// (FR-T51-020..027) + dispatch-table cross-reference (FR-T51-025/026).
//
// Any drift in the CLI surface fails the test until the snapshot is updated
// deliberately (commit the new snapshot in the same PR as the surface
// change). Run `vitest -u` to update snapshots intentionally.
//
// The dispatch-table cross-reference catches the class of bug where a new
// archetype is added to `dispatch-table.yml` but its name is never advertised
// in `forge init --help`. The maintainer's GitHub Discussions posts can copy
// from these snapshots as the authoritative `forge init` ABI reference
// (NFR-T51-010 / MR-T51-005).

import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

import { parseDispatchTable } from "../../src/domain/dispatch-table.js";

const CLI_ROOT = resolve(__dirname, "..", "..");
const CLI_ENTRY = resolve(CLI_ROOT, "dist", "index.js");
const REPO_ROOT = resolve(CLI_ROOT, "..");
const DISPATCH_TABLE_PATH = resolve(
  REPO_ROOT,
  ".forge/scaffolding/dispatch-table.yml",
);

/**
 * Invoke `forge <args> --help` and return the captured stdout, normalised
 * so the snapshot is deterministic (NFR-T51-007) :
 * - `NO_COLOR=1` + `FORCE_COLOR=0` strip every ANSI escape.
 * - CRLF → LF.
 * - Trailing whitespace stripped per line.
 */
function captureHelp(args: string[]): string {
  const r = spawnSync(process.execPath, [CLI_ENTRY, ...args, "--help"], {
    encoding: "utf8",
    env: { ...process.env, NO_COLOR: "1", FORCE_COLOR: "0" },
  });
  if (r.status !== 0) {
    throw new Error(
      `forge ${args.join(" ")} --help exited ${r.status}: ${r.stderr}`,
    );
  }
  return (r.stdout ?? "")
    .replace(/\r\n/g, "\n")
    .replace(/[ \t]+$/gm, "");
}

describe("CLI help snapshots (T5.1.A)", () => {
  it.each([
    ["root", [] as string[]],
    ["init", ["init"]],
    ["upgrade", ["upgrade"]],
    ["verify", ["verify"]],
    ["version", ["version"]],
  ])("captures `forge %s --help`", async (name, args) => {
    const stdout = captureHelp(args);
    await expect(stdout).toMatchFileSnapshot(
      `__snapshots__/help/${name}.snap.txt`,
    );
  });

  it("`forge init --help` mentions every active archetype from dispatch-table", () => {
    const dispatchYaml = readFileSync(DISPATCH_TABLE_PATH, "utf8");
    const table = parseDispatchTable(dispatchYaml);
    // Active = anything not explicitly removed. `legacy_alias` entries are
    // kept active until their target archetype lands (FR-T51-041).
    const active = Object.values(table.archetypes).filter(
      (e) => (e as { status?: string }).status !== "removed_from_roadmap",
    );

    const initHelp = captureHelp(["init"]);
    for (const arch of active) {
      expect(
        initHelp,
        `forge init --help is missing archetype name '${arch.name}'. ` +
          `Either add it to the help text or mark it 'removed_from_roadmap' in dispatch-table.yml.`,
      ).toContain(arch.name);
    }
  });
});
