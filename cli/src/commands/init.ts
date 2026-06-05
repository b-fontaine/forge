// Forge — `forge init` dispatcher (FR-IW-001 + ADR-001 / ADR-007).
//
// Single canonical entry point for project scaffolding. Routes to
// one of four code paths based on flags + TTY :
//   --archetype <name>  → archetype dispatch (default → built-in,
//                         others → per-archetype wrapper)
//   --auto              → auto-detect, then archetype dispatch
//   --wizard            → interactive wizard, then archetype dispatch
//   no flags + non-TTY  → silent default (NFR-IW-004 backwards compat)
//   no flags + TTY      → wizard mode

import {
  type ArchetypeRunner,
  type DispatchTableReader,
  autoDetectArchetype,
  resolveScaffolder,
  runArchetypeInit,
} from "./init-archetype.js";
import type { SchemaMeta } from "../domain/schema-version.js";
import { runDefaultInit } from "./init-default.js";
import { runWizard } from "./init-wizard.js";
import { validateReverseDomain } from "../domain/reverse-domain.js";
import type { Op } from "../domain/scaffold.js";

// Re-export legacy types for backwards compatibility with callers
// that imported InitOptions / InitResult from this module.
export type { Op } from "../domain/scaffold.js";

export interface InitOptions {
  // Existing fields (unchanged from pre-b5.1)
  sourceDir: string;
  targetDir: string;
  force: boolean;
  // New b5.1 fields (all optional — absence = legacy behavior)
  archetype?: string;
  auto?: boolean;
  wizard?: boolean;
  projectName?: string;
  reverseDomain?: string;
  isTty?: boolean;
  // J.8 j8-janus-rules — EU compliance tier (FR-J8-040..045 / ADR-J8-002).
  // Optional ; absence preserves backward compat (NFR-J8-002).
  euTier?: string;
}

/**
 * J.8 j8-janus-rules — valid `--eu-tier` values per
 * `.forge/schemas/compliance-tier.schema.json` v1.0.0 (T.4).
 */
export const EU_TIER_ENUM: readonly ["T1", "T2", "T3"] = ["T1", "T2", "T3"];

export interface InitResult {
  // For default-archetype runs, mirrors the legacy shape
  ops?: Op[];
  errors: string[];
  exitCode?: number; // for archetype runs (propagated from wrapper)
}

export interface InitDispatcherDeps {
  options: InitOptions;
  // Wired from cli.ts ; injectable for tests
  readDispatchTable: DispatchTableReader;
  archetypeRunner: ArchetypeRunner;
  dispatchTablePath: string;
  forgeRootDir: string;
  stdin: NodeJS.ReadableStream;
  stdout: NodeJS.WritableStream;
  stderr: NodeJS.WritableStream;
  // B.8.14 (b8-14-promotion-flip C2) — versioned-schema selection + the deferred
  // B.8.3.b scaffoldable:false guard. Both optional: when absent, init keeps the
  // legacy archetype-NAME-only routing (no version resolution, no guard).
  readArchetypeSchemas?: (archetype: string) => Promise<SchemaMeta[]>;
  versionedScaffolderExists?: (relPath: string) => Promise<boolean>;
}

function writeError(stream: NodeJS.WritableStream, text: string): void {
  stream.write(`${text}\n`);
}

function countSelectionFlags(o: InitOptions): number {
  return (
    (o.archetype !== undefined ? 1 : 0) +
    (o.auto ? 1 : 0) +
    (o.wizard ? 1 : 0)
  );
}

export async function initCommand(
  deps: InitDispatcherDeps,
): Promise<InitResult> {
  const { options } = deps;

  // ── Mutual exclusion (ADR-007) ──────────────────────────────
  if (countSelectionFlags(options) > 1) {
    writeError(
      deps.stderr,
      "forge init: --archetype, --auto, --wizard are mutually exclusive",
    );
    return { errors: ["mutually exclusive selection flags"], exitCode: 2 };
  }

  // ── --eu-tier validation (J.8 j8-janus-rules / FR-J8-040..043) ──
  // Validates against compliance-tier.schema.json enum. Absence
  // preserves backward compat (NFR-J8-002 / ADR-J8-002 — no default).
  if (options.euTier !== undefined) {
    if (!(EU_TIER_ENUM as readonly string[]).includes(options.euTier)) {
      writeError(
        deps.stderr,
        `forge init: invalid --eu-tier '${options.euTier}'. ` +
          `Must be one of [${EU_TIER_ENUM.join(", ")}] per ` +
          `.forge/schemas/compliance-tier.schema.json.`,
      );
      return { errors: ["invalid eu-tier"], exitCode: 2 };
    }
    // Pass the validated tier to wrapper scripts via env var.
    // Wrappers source bin/_forge-init-helpers.sh and gate their
    // tier-specific blocks on `[ -n "$FORGE_EU_TIER" ]`.
    process.env.FORGE_EU_TIER = options.euTier;
  }

  // ── Resolve archetype ──────────────────────────────────────
  let archetype: string;
  let projectName = options.projectName ?? "";
  let reverseDomain = options.reverseDomain ?? "";

  if (options.wizard || (!options.archetype && !options.auto && options.isTty)) {
    // Interactive wizard mode
    const dispatchTable = await deps.readDispatchTable(deps.dispatchTablePath);
    const result = await runWizard({
      input: deps.stdin,
      output: deps.stdout,
      dispatchTable,
    });
    archetype = result.archetype;
    projectName = result.projectName;
    reverseDomain = result.reverseDomain ?? "";
  } else if (options.auto) {
    // Auto-detection mode
    const dispatchTable = await deps.readDispatchTable(deps.dispatchTablePath);
    const detection = await autoDetectArchetype({
      dispatchTable,
      targetDir: options.targetDir,
    });
    if (detection.kind === "match") {
      archetype = detection.archetype;
    } else if (detection.kind === "ambiguous") {
      writeError(
        deps.stderr,
        `forge init: cannot disambiguate archetype from signals.\n` +
          `  Detected signals: ${detection.detected.join(", ") || "<none>"}\n` +
          `  Candidate archetypes: ${
            detection.candidates.length > 0
              ? detection.candidates.join(", ")
              : "<none registered yet>"
          }\n` +
          `[NEEDS DECISION: re-run with --archetype default for a minimal install, ` +
          `or wait for a matching archetype to ship.]`,
      );
      return { errors: ["ambiguous auto-detection"], exitCode: 2 };
    } else {
      writeError(
        deps.stderr,
        `forge init: --auto found no archetype signals in target dir.\n` +
          `[NEEDS DECISION: re-run with --archetype default for a minimal install.]`,
      );
      return { errors: ["no archetype signals"], exitCode: 2 };
    }
  } else if (options.archetype) {
    archetype = options.archetype;
  } else {
    // No flags + non-TTY → silent default (NFR-IW-004)
    archetype = "default";
  }

  // ── Dispatch ───────────────────────────────────────────────
  if (archetype === "default") {
    const result = await runDefaultInit({
      sourceDir: options.sourceDir,
      targetDir: options.targetDir,
      force: options.force,
    });
    return { ops: result.ops, errors: result.errors };
  }

  // Non-default archetype → per-archetype wrapper
  if (!projectName) {
    writeError(
      deps.stderr,
      `forge init: archetype '${archetype}' requires a project name (positional argument or wizard prompt).`,
    );
    return { errors: ["missing project name"], exitCode: 2 };
  }
  if (!reverseDomain) {
    writeError(
      deps.stderr,
      `forge init: archetype '${archetype}' requires --org <reverse-domain>.`,
    );
    return { errors: ["missing reverse domain"], exitCode: 2 };
  }
  const orgValidation = validateReverseDomain(reverseDomain);
  if (!orgValidation.valid) {
    writeError(
      deps.stderr,
      `forge init: invalid reverse domain '${reverseDomain}': ${orgValidation.reason}`,
    );
    return { errors: ["invalid reverse domain"], exitCode: 3 };
  }

  const dispatchTable = await deps.readDispatchTable(deps.dispatchTablePath);
  if (!dispatchTable.archetypes[archetype]) {
    const known = Object.keys(dispatchTable.archetypes).join(", ");
    writeError(
      deps.stderr,
      `forge init: unknown archetype '${archetype}'. Known: ${known}.`,
    );
    return { errors: ["unknown archetype"], exitCode: 2 };
  }

  // ── B.8.14 (b8-14-promotion-flip C2) — versioned-schema selection + guard ──
  // Pick the highest stage:stable + scaffoldable:true schema for this archetype
  // and route to its versioned wrapper; refuse (exit 3) when none is scaffoldable
  // (deferred B.8.3.b guard). Return-based exit code (not throw) so the refusal
  // surfaces as exit 3 reliably. Skipped when the deps are not wired (legacy).
  let scaffolderOverride: string | undefined;
  if (deps.readArchetypeSchemas && deps.versionedScaffolderExists) {
    const metas = await deps.readArchetypeSchemas(archetype);
    const resolution = await resolveScaffolder(
      dispatchTable.archetypes[archetype].scaffolder,
      metas,
      deps.versionedScaffolderExists,
    );
    if (resolution.kind === "refuse") {
      writeError(
        deps.stderr,
        `forge init: archetype '${archetype}' ${resolution.reason}. ` +
          `[B.8.3.b scaffoldable guard]`,
      );
      return { errors: ["no scaffoldable schema version"], exitCode: 3 };
    }
    scaffolderOverride = resolution.scaffolder;
  }

  const arch = await runArchetypeInit({
    archetype,
    targetDir: options.targetDir,
    projectName,
    reverseDomain,
    force: options.force,
    forgeRootDir: deps.forgeRootDir,
    dispatchTable,
    runner: deps.archetypeRunner,
    scaffolderOverride,
  });
  return { errors: [], exitCode: arch.exitCode };
}
