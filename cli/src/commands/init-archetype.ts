// Forge — `forge init --archetype <non-default>` archetype path.
// FR-IW-001 + FR-IW-005 + ADR-001 / ADR-003 of b5-1-init-wizard.
//
// Reads the dispatch table at .forge/scaffolding/dispatch-table.yml,
// probes the target dir for signals (--auto), then delegates to the
// per-archetype wrapper script via the stable ABI declared in
// `global/scaffolding.md`.

import { stat } from "node:fs/promises";
import { join } from "node:path";
import {
  type ArchetypeRegistration,
  type DetectionResult,
  detectArchetype,
} from "../domain/archetype-detect.js";

export interface DispatchTableEntry {
  name: string;
  scaffolder: string;
  description?: string;
  signals?: string[];
  since?: string;
}

export interface DispatchTable {
  archetypes: Record<string, DispatchTableEntry>;
}

export type DispatchTableReader = (path: string) => Promise<DispatchTable>;

export interface ArchetypeRunRequest {
  scaffolderPath: string; // absolute
  args: string[];
  cwd: string;
}

export interface ArchetypeRunResult {
  exitCode: number;
}

export type ArchetypeRunner = (
  req: ArchetypeRunRequest,
) => Promise<ArchetypeRunResult>;

export interface AutoDetectDeps {
  dispatchTable: DispatchTable;
  targetDir: string;
}

/**
 * Probe the target dir for archetype signals and return the detection
 * result. Pure I/O wrapper around `detectArchetype` (FR-IW-005).
 */
export async function autoDetectArchetype(
  deps: AutoDetectDeps,
): Promise<DetectionResult> {
  const registrations: ArchetypeRegistration[] = Object.values(
    deps.dispatchTable.archetypes,
  ).map((entry) => ({
    name: entry.name,
    signals: entry.signals ?? [],
  }));
  const allSignals = new Set<string>();
  for (const r of registrations) {
    for (const s of r.signals) allSignals.add(s);
  }
  const signalsByPath: Record<string, boolean> = {};
  for (const sig of allSignals) {
    const full = join(deps.targetDir, sig);
    try {
      const st = await stat(full);
      signalsByPath[sig] = st.isFile();
    } catch {
      signalsByPath[sig] = false;
    }
  }
  return detectArchetype(registrations, signalsByPath);
}

export interface ArchetypeInitOptions {
  archetype: string;
  targetDir: string;
  projectName: string;
  reverseDomain: string;
  force: boolean;
  forgeRootDir: string; // resolves bin/forge-init-<archetype>.sh
  dispatchTable: DispatchTable;
  runner: ArchetypeRunner;
}

export async function runArchetypeInit(
  opts: ArchetypeInitOptions,
): Promise<ArchetypeRunResult> {
  const entry = opts.dispatchTable.archetypes[opts.archetype];
  if (!entry) {
    throw new Error(
      `forge init: unknown archetype '${opts.archetype}' — not in dispatch table`,
    );
  }
  if (entry.scaffolder === "<built-in>") {
    throw new Error(
      `forge init: archetype '${opts.archetype}' uses the built-in scaffolder ` +
        `— call runDefaultInit instead`,
    );
  }
  const scaffolderPath = join(opts.forgeRootDir, entry.scaffolder);
  const args: string[] = [
    "--target",
    opts.targetDir,
    "--project-name",
    opts.projectName,
    "--reverse-domain",
    opts.reverseDomain,
  ];
  if (opts.force) args.push("--force");
  return opts.runner({
    scaffolderPath,
    args,
    cwd: opts.targetDir,
  });
}
