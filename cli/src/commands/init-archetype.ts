// Forge — `forge init --archetype <non-default>` archetype path.
// FR-IW-001 + FR-IW-005 + ADR-001 / ADR-003 of b5-1-init-wizard.
//
// Reads the dispatch table at .forge/scaffolding/dispatch-table.yml,
// probes the target dir for signals (--auto), then delegates to the
// per-archetype wrapper script via the stable ABI declared in
// `global/scaffolding.md`.

import { mkdir, stat } from "node:fs/promises";
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

/**
 * J.8 j8-janus-rules — forbidden_archetypes entry.
 * Documented in `.forge/standards/global/janus-orchestration-rules.md`
 * and mirrored in `.claude/agents/cross-layer-orchestrator.md`.
 */
export interface ForbiddenArchetypeEntry {
  name: string;
  reason: string;
  since: string;
  alternative: string;
  rule_id: string;
}

export interface DispatchTable {
  archetypes: Record<string, DispatchTableEntry>;
  forbidden_archetypes?: ForbiddenArchetypeEntry[];
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
  // J.8 j8-janus-rules — forbidden_archetypes refusal (FR-J8-020 / ADR-J8-003).
  // First line of defense before any wrapper invocation. Refusal exit code
  // is 3 (policy violation) ; the wrapper-side helper provides defense in
  // depth for cases where this dispatcher is bypassed.
  const forbidden = (opts.dispatchTable.forbidden_archetypes ?? []).find(
    (e) => e.name === opts.archetype,
  );
  if (forbidden) {
    const err = new Error(
      `[REFUSAL: ${forbidden.name}: ${forbidden.rule_id}: ${forbidden.reason} ; alternative: ${forbidden.alternative}]`,
    );
    (err as Error & { exitCode?: number }).exitCode = 3;
    throw err;
  }

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
  // v0.3.2 fix : ensure targetDir exists before spawn — otherwise
  // Node fails with `spawn bash ENOENT` (the error references bash
  // but the underlying syscall is the missing `cwd`).
  await mkdir(opts.targetDir, { recursive: true });
  return opts.runner({
    scaffolderPath,
    args,
    cwd: opts.targetDir,
  });
}
