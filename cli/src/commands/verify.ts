export interface RunRequest {
  script: string;
  cwd: string;
}

export interface RunResult {
  exitCode: number;
}

export type Runner = (req: RunRequest) => Promise<RunResult>;

export interface VerifyCommandDeps {
  runner: Runner;
  writeLine(text: string): void;
  writeError(text: string): void;
  targetDir: string;
}

const SCRIPTS = [
  ".forge/scripts/verify.sh",
  ".forge/scripts/constitution-linter.sh",
] as const;

export async function verifyCommand(
  deps: VerifyCommandDeps,
): Promise<number> {
  let rc = 0;
  for (const rel of SCRIPTS) {
    const script = `${deps.targetDir}/${rel}`;
    try {
      const result = await deps.runner({ script, cwd: deps.targetDir });
      if (result.exitCode !== 0) rc = 1;
    } catch (err) {
      const e = err as NodeJS.ErrnoException;
      if (e.code === "ENOENT") {
        deps.writeError(`${rel}: not found (${e.message})`);
        return 2;
      }
      deps.writeError(`${rel}: ${e.message}`);
      rc = 1;
    }
  }
  return rc;
}
