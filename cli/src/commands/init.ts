import { copyFile, mkdir, readdir } from "node:fs/promises";
import { dirname, join, relative, sep } from "node:path";
import { type Op, scaffoldPlan } from "../domain/scaffold.js";

export interface InitOptions {
  sourceDir: string;
  targetDir: string;
  force: boolean;
}

export interface InitResult {
  ops: Op[];
  errors: string[];
}

const WALK_SKIP_DIRS: ReadonlySet<string> = new Set([
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

async function walkFiles(root: string): Promise<string[]> {
  const out: string[] = [];
  async function visit(dir: string): Promise<void> {
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      if (entry.isDirectory() && WALK_SKIP_DIRS.has(entry.name)) continue;
      const full = join(dir, entry.name);
      if (entry.isDirectory()) {
        await visit(full);
      } else if (entry.isFile()) {
        out.push(relative(root, full).split(sep).join("/"));
      }
    }
  }
  await visit(root);
  return out;
}

export async function initCommand(opts: InitOptions): Promise<InitResult> {
  const errors: string[] = [];

  const [sourceFiles, targetFiles] = await Promise.all([
    walkFiles(opts.sourceDir),
    walkFiles(opts.targetDir),
  ]);

  const plan = scaffoldPlan({
    sourceFiles,
    targetExisting: new Set(targetFiles),
    force: opts.force,
  });

  for (const op of plan) {
    if (op.type === "skip") continue;
    if (op.type === "ensure-dir") {
      try {
        await mkdir(join(opts.targetDir, op.dst), { recursive: true });
      } catch (err) {
        errors.push(`${op.dst}: ${(err as Error).message}`);
      }
      continue;
    }
    // copy or scaffold
    const src = join(opts.sourceDir, op.src);
    const dst = join(opts.targetDir, op.dst);
    try {
      await mkdir(dirname(dst), { recursive: true });
      await copyFile(src, dst);
    } catch (err) {
      errors.push(`${op.dst}: ${(err as Error).message}`);
    }
  }

  return { ops: plan, errors };
}
