#!/usr/bin/env node
import { runCli } from "./cli.js";

const rc = await runCli({
  argv: process.argv.slice(2),
  stdin: process.stdin,
  stdout: process.stdout,
  stderr: process.stderr,
  cwd: process.cwd(),
});

process.exit(rc);
