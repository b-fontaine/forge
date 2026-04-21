import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Command } from "commander";
import { initCommand } from "./commands/init.js";
import { verifyCommand } from "./commands/verify.js";
import { versionCommand } from "./commands/version.js";

export interface CliIo {
  argv: string[];
  stdout: NodeJS.WritableStream;
  stderr: NodeJS.WritableStream;
  cwd: string;
}

function packageRoot(): string {
  const here = dirname(fileURLToPath(import.meta.url));
  // dist/cli.js → package root is one up from dist/
  return resolve(here, "..");
}

function writeLine(stream: NodeJS.WritableStream): (text: string) => void {
  return (text: string) => {
    stream.write(`${text}\n`);
  };
}

export async function runCli(io: CliIo): Promise<number> {
  const program = new Command();
  program
    .name("forge")
    .description(
      "Install, upgrade, and verify the Forge framework in a project.",
    )
    .showHelpAfterError();

  let exitCode = 0;

  program
    .command("version")
    .description("print the installed Forge framework version")
    .action(async () => {
      const rc = await versionCommand({
        readFile: (p) => readFile(p, "utf8"),
        writeLine: writeLine(io.stdout),
        writeError: writeLine(io.stderr),
        versionFilePath: resolve(packageRoot(), "VERSION"),
      });
      exitCode = rc;
    });

  program
    .command("init")
    .description("scaffold Forge into a project directory")
    .option("--target <dir>", "target project directory", io.cwd)
    .option(
      "--source <dir>",
      "local Forge source checkout (default: the files bundled with this CLI)",
    )
    .option("--force", "overwrite existing framework files", false)
    .action(async (opts: { target: string; source?: string; force: boolean }) => {
      const source = opts.source ?? packageRoot();
      const result = await initCommand({
        sourceDir: source,
        targetDir: opts.target,
        force: opts.force,
      });
      const copied = result.ops.filter((op) => op.type === "copy").length;
      const scaffolded = result.ops.filter(
        (op) => op.type === "scaffold",
      ).length;
      const skipped = result.ops.filter((op) => op.type === "skip").length;
      io.stdout.write(
        `forge init: copied ${copied}, scaffolded ${scaffolded}, skipped ${skipped} — OK\n`,
      );
      if (result.errors.length > 0) {
        for (const e of result.errors) io.stderr.write(`${e}\n`);
        exitCode = 1;
      }
    });

  program
    .command("verify")
    .description(
      "run Forge's deterministic scripts (verify.sh + constitution-linter.sh)",
    )
    .option("--target <dir>", "target project directory", io.cwd)
    .action(async (opts: { target: string }) => {
      const rc = await verifyCommand({
        runner: ({ script, cwd }) =>
          new Promise((res, rej) => {
            const child = spawn("bash", [script], {
              cwd,
              stdio: ["ignore", "inherit", "inherit"],
            });
            child.on("error", rej);
            child.on("close", (code) => res({ exitCode: code ?? 1 }));
          }),
        writeLine: writeLine(io.stdout),
        writeError: writeLine(io.stderr),
        targetDir: opts.target,
      });
      exitCode = rc;
    });

  try {
    await program.parseAsync(io.argv, { from: "user" });
  } catch (err) {
    io.stderr.write(`${(err as Error).message}\n`);
    return 1;
  }
  return exitCode;
}
