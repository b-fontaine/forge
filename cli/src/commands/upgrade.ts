// Forge — `forge upgrade` CLI subcommand.
// Audit: A.7 (a7-forge-upgrade, FR-UP-001).
//
// Thin TypeScript orchestrator. The actual merge work lives in
// `bin/forge-upgrade.sh` (FR-UP-009). This layer :
//   1. resolves target dir + reads scaffold-manifest.yaml,
//   2. computes the framework's RIGHT version,
//   3. spawns the shell driver with the appropriate flags,
//   4. propagates the shell's exit code.

export interface UpgradeRunRequest {
  script: string;
  args: string[];
  cwd: string;
}

export interface UpgradeRunResult {
  exitCode: number;
}

export type UpgradeRunner = (
  req: UpgradeRunRequest,
) => Promise<UpgradeRunResult>;

// Read the scaffold-manifest. Returns null when absent or malformed
// (callers map that to exit 2 with a friendly message).
export type ManifestReader = (
  manifestPath: string,
) => Promise<{ archetype: string; archetype_version: string } | null>;

// Resolve the framework's CURRENT version for the given archetype.
// In production this reads `.forge/schemas/<archetype>/schema.yaml`
// from the framework's bundled assets ; in tests it is mocked.
export type FrameworkVersionResolver = (archetype: string) => Promise<string>;

export interface UpgradeOptions {
  targetDir: string;
  dryRun: boolean;
  force: boolean;
  verbose: boolean;
}

export interface UpgradeCommandDeps {
  options: UpgradeOptions;
  runner: UpgradeRunner;
  readManifest: ManifestReader;
  resolveFrameworkVersion: FrameworkVersionResolver;
  shellDriverPath: string;
  writeLine(text: string): void;
  writeError(text: string): void;
}

export async function upgradeCommand(
  deps: UpgradeCommandDeps,
): Promise<number> {
  const {
    options,
    runner,
    readManifest,
    resolveFrameworkVersion,
    shellDriverPath,
    writeError,
  } = deps;

  const manifestPath = `${options.targetDir}/.forge/scaffold-manifest.yaml`;
  const manifest = await readManifest(manifestPath);
  if (manifest === null) {
    writeError(
      "forge upgrade: target is not a Forge project " +
        "(missing .forge/scaffold-manifest.yaml)",
    );
    return 2;
  }

  let toVersion: string;
  try {
    toVersion = await resolveFrameworkVersion(manifest.archetype);
  } catch (err) {
    writeError(
      `forge upgrade: could not resolve framework version for archetype ` +
        `'${manifest.archetype}': ${(err as Error).message}`,
    );
    return 2;
  }

  const args: string[] = [
    "--target",
    options.targetDir,
    "--to-version",
    toVersion,
  ];
  if (options.dryRun) args.push("--dry-run");
  if (options.force) args.push("--force");
  if (options.verbose) args.push("--verbose");

  const result = await runner({
    script: shellDriverPath,
    args,
    cwd: options.targetDir,
  });
  return result.exitCode;
}
