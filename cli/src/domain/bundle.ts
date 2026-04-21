export interface BundleInput {
  rootFiles: string[];
}

const EXCLUDED_TOP_LEVEL_DIRS: ReadonlySet<string> = new Set([
  "cli",
  "node_modules",
  ".git",
  ".idea",
  ".vscode",
  ".omc",
  "dist",
  "coverage",
  "build",
  ".next",
  ".turbo",
]);

const EXCLUDED_PATHS: ReadonlySet<string> = new Set([
  ".claude/settings.local.json",
]);

const EXCLUDED_PREFIXES: readonly string[] = [
  ".forge/product/",
  ".forge/_memory/",
  ".forge/changes/",
  ".forge/specs/",
];

function isExcluded(path: string): boolean {
  const firstSegment = path.split("/", 1)[0] ?? "";
  if (EXCLUDED_TOP_LEVEL_DIRS.has(firstSegment)) return true;
  if (EXCLUDED_PATHS.has(path)) return true;
  if (EXCLUDED_PREFIXES.some((p) => path.startsWith(p))) return true;
  return false;
}

export function bundlePlan(input: BundleInput): string[] {
  return input.rootFiles.filter((p) => !isExcluded(p));
}
