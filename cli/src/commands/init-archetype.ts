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
import {
  type SchemaMeta,
  selectScaffoldableVersion,
} from "../domain/schema-version.js";

export interface DispatchTableEntry {
  name: string;
  scaffolder: string;
  description?: string;
  signals?: string[];
  since?: string;
  // T5.1 — captured by parseDispatchTable so cross-reference checks
  // (FR-T51-025/041) can filter out `removed_from_roadmap` and
  // `legacy_alias` entries.
  status?: string;
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
  // B.8.14 (b8-14-promotion-flip C2) — when set, overrides entry.scaffolder with
  // the versioned wrapper chosen by resolveScaffolder (e.g. forge-init-fsm-2.0.0.sh).
  scaffolderOverride?: string;
}

/**
 * B.8.14 (b8-14-promotion-flip C2) — versioned scaffolder selection + the deferred
 * B.8.3.b scaffoldable:false guard. Given the archetype's parsed schema metas (all
 * `<schemaRoot>/<archetype>/*.yaml`) and a probe for versioned wrappers, return
 * either the scaffolder to run — the highest stage:stable + scaffoldable:true
 * version's `bin/forge-init-<base>-<version>.sh` wrapper, falling back to the
 * dispatch-table default — or a refusal when NO schema version is scaffoldable.
 */
export type ScaffolderResolution =
  | { kind: "ok"; scaffolder: string; version: string }
  | { kind: "refuse"; reason: string };

export async function resolveScaffolder(
  defaultScaffolder: string,
  metas: readonly SchemaMeta[],
  versionedScaffolderExists: (relPath: string) => Promise<boolean>,
): Promise<ScaffolderResolution> {
  // No parseable versioned schemas (e.g. mobile-only's schema uses a different
  // field shape, or an archetype ships no schema dir) — preserve the legacy
  // name-only routing; the B.8.3.b guard only governs archetypes whose versioned
  // schemas ARE parseable here (today: full-stack-monorepo).
  if (metas.length === 0) {
    return { kind: "ok", scaffolder: defaultScaffolder, version: "" };
  }
  const chosen = selectScaffoldableVersion(metas);
  if (!chosen) {
    return {
      kind: "refuse",
      reason:
        "has no stable, scaffoldable schema version (every version is a non-scaffoldable candidate/draft)",
    };
  }
  let scaffolder = defaultScaffolder;
  const versioned = defaultScaffolder.replace(/\.sh$/, `-${chosen.version}.sh`);
  if (versioned !== defaultScaffolder && (await versionedScaffolderExists(versioned))) {
    scaffolder = versioned;
  }
  return { kind: "ok", scaffolder, version: chosen.version };
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
  const scaffolderPath = join(opts.forgeRootDir, opts.scaffolderOverride ?? entry.scaffolder);
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
