import { spawn } from "node:child_process";
import { existsSync, statSync } from "node:fs";
import { readFile, readdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Command } from "commander";
import { initCommand } from "./commands/init.js";
import { upgradeCommand } from "./commands/upgrade.js";
import { verifyCommand } from "./commands/verify.js";
import { versionCommand } from "./commands/version.js";
import { parseDispatchTable } from "./domain/dispatch-table.js";
import { type SchemaMeta, parseSchemaMeta } from "./domain/schema-version.js";

export interface CliIo {
  argv: string[];
  stdin: NodeJS.ReadableStream & { isTTY?: boolean };
  stdout: NodeJS.WritableStream;
  stderr: NodeJS.WritableStream;
  cwd: string;
}

function packageRoot(): string {
  const here = dirname(fileURLToPath(import.meta.url));
  // dist/cli.js → package root is one up from dist/
  return resolve(here, "..");
}

// In a published tarball, scaffold assets live under <pkg>/assets/ (produced by
// `npm run bundle`). In local dev (built dist/ inside the repo, no bundle run),
// fall back to the repo root so `forge init` still works without publishing.
function assetsRoot(): string {
  const pkg = packageRoot();
  const bundled = resolve(pkg, "assets");
  if (existsSync(bundled) && statSync(bundled).isDirectory()) return bundled;
  return resolve(pkg, "..");
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
    .argument("[project-name]", "project slug (required for non-default archetypes)")
    .option("--target <dir>", "target project directory", io.cwd)
    .option(
      "--source <dir>",
      "local Forge source checkout (default: the files bundled with this CLI)",
    )
    .option("--archetype <name>", "explicit archetype (e.g. default | full-stack-monorepo | mobile-only | ai-native-rag)")
    .option("--auto", "auto-detect archetype from target dir signals", false)
    .option("--wizard", "force interactive wizard mode", false)
    .option("--org <reverse-domain>", "reverse domain (required for non-default archetypes)")
    .option("--force", "overwrite existing framework files", false)
    .option(
      "--eu-tier <tier>",
      "EU compliance tier (T1|T2|T3) per J.8 j8-janus-rules",
    )
    .action(
      async (
        projectName: string | undefined,
        opts: {
          target: string;
          source?: string;
          archetype?: string;
          auto: boolean;
          wizard: boolean;
          org?: string;
          force: boolean;
          euTier?: string;
        },
      ) => {
        const source = opts.source ?? assetsRoot();
        const assets = assetsRoot();
        const result = await initCommand({
          options: {
            sourceDir: source,
            targetDir: opts.target,
            force: opts.force,
            archetype: opts.archetype,
            auto: opts.auto,
            wizard: opts.wizard,
            projectName,
            reverseDomain: opts.org,
            euTier: opts.euTier,
            isTty: Boolean((io.stdin as { isTTY?: boolean }).isTTY),
          },
          readDispatchTable: async (path) => {
            const yamlContent = await readFile(path, "utf8");
            return parseDispatchTable(yamlContent);
          },
          archetypeRunner: ({ scaffolderPath, args, cwd }) =>
            new Promise((res, rej) => {
              const child = spawn("bash", [scaffolderPath, ...args], {
                cwd,
                stdio: ["ignore", "inherit", "inherit"],
              });
              child.on("error", rej);
              child.on("close", (code) => res({ exitCode: code ?? 1 }));
            }),
          dispatchTablePath: resolve(
            assets,
            ".forge/scaffolding/dispatch-table.yml",
          ),
          forgeRootDir: assets,
          // B.8.14 (b8-14-promotion-flip C2) — versioned-schema selection + the
          // deferred B.8.3.b scaffoldable:false guard.
          readArchetypeSchemas: async (archetype) => {
            const dir = resolve(assets, ".forge/schemas", archetype);
            const metas: SchemaMeta[] = [];
            let names: string[];
            try {
              names = await readdir(dir);
            } catch {
              return metas; // no schema dir → legacy name-only routing
            }
            for (const name of names) {
              if (!name.endsWith(".yaml")) continue;
              try {
                const meta = parseSchemaMeta(
                  await readFile(resolve(dir, name), "utf8"),
                );
                if (meta) metas.push(meta);
              } catch {
                /* skip unreadable/unparsable schema files */
              }
            }
            return metas;
          },
          versionedScaffolderExists: async (relPath) =>
            existsSync(resolve(assets, relPath)),
          stdin: io.stdin as NodeJS.ReadableStream,
          stdout: io.stdout,
          stderr: io.stderr,
        });
        if (result.exitCode !== undefined && result.exitCode !== 0) {
          exitCode = result.exitCode;
          return;
        }
        if (result.ops) {
          // Default-archetype path : print the legacy summary line.
          const copied = result.ops.filter((op) => op.type === "copy").length;
          const scaffolded = result.ops.filter(
            (op) => op.type === "scaffold",
          ).length;
          const skipped = result.ops.filter((op) => op.type === "skip").length;
          io.stdout.write(
            `forge init: copied ${copied}, scaffolded ${scaffolded}, skipped ${skipped} — OK\n`,
          );
        }
        if (result.errors.length > 0) {
          for (const e of result.errors) io.stderr.write(`${e}\n`);
          exitCode = exitCode || 1;
        }
      },
    );

  program
    .command("upgrade")
    .description(
      "non-destructive 3-way merge of framework updates into a scaffolded project",
    )
    .option("--target <dir>", "target project directory", io.cwd)
    .option("--dry-run", "print the plan without writing", false)
    .option("--force", "let conflicts land in-place (requires clean Git tree)", false)
    .option("--verbose", "print progress and BASE-recovery diagnostics", false)
    .action(
      async (opts: {
        target: string;
        dryRun: boolean;
        force: boolean;
        verbose: boolean;
      }) => {
        const assets = assetsRoot();
        const rc = await upgradeCommand({
          options: {
            targetDir: opts.target,
            dryRun: opts.dryRun,
            force: opts.force,
            verbose: opts.verbose,
          },
          runner: ({ script, args, cwd }) =>
            new Promise((res, rej) => {
              const child = spawn("bash", [script, ...args], {
                cwd,
                stdio: ["ignore", "inherit", "inherit"],
              });
              child.on("error", rej);
              child.on("close", (code) => res({ exitCode: code ?? 1 }));
            }),
          readManifest: async (manifestPath) => {
            try {
              const content = await readFile(manifestPath, "utf8");
              const m: Record<string, unknown> = {};
              for (const line of content.split("\n")) {
                const match = line.match(/^([a-z_]+):\s*"?([^"\n]*?)"?\s*$/);
                if (match) m[match[1]] = match[2];
              }
              if (
                typeof m.archetype !== "string" ||
                typeof m.archetype_version !== "string"
              ) {
                return null;
              }
              return {
                archetype: m.archetype,
                archetype_version: m.archetype_version,
              };
            } catch {
              return null;
            }
          },
          resolveFrameworkVersion: async (archetype) => {
            const schemaPath = resolve(
              assets,
              ".forge/schemas",
              archetype,
              "schema.yaml",
            );
            const content = await readFile(schemaPath, "utf8");
            const match = content.match(/^version:\s*"?([^"\n]+?)"?\s*$/m);
            if (!match) {
              throw new Error(`schema.yaml has no version field`);
            }
            return match[1];
          },
          shellDriverPath: resolve(assets, "bin/forge-upgrade.sh"),
          writeLine: writeLine(io.stdout),
          writeError: writeLine(io.stderr),
        });
        exitCode = rc;
      },
    );

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
