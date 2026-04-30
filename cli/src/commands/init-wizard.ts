// Forge — interactive `forge init` wizard (FR-IW-006 + ADR-004).
// Uses Node's `readline` exclusively. NO third-party UI library
// (NFR-IW-002 of b5-1-init-wizard).

import * as readline from "node:readline";

import type { DispatchTable } from "./init-archetype.js";
import { validateReverseDomain } from "../domain/reverse-domain.js";

export interface WizardDeps {
  input: NodeJS.ReadableStream;
  output: NodeJS.WritableStream;
  dispatchTable: DispatchTable;
}

export interface WizardResult {
  archetype: string;
  projectName: string;
  reverseDomain?: string;
}

const PROJECT_NAME_RE = /^[a-z][a-z0-9-]{1,49}$/;
const MAX_REPROMPT = 3;

function makeRl(deps: WizardDeps): readline.Interface {
  return readline.createInterface({
    input: deps.input,
    output: deps.output,
    terminal: false, // no ANSI escape sequences ; deterministic for tests
  });
}

function ask(rl: readline.Interface, prompt: string): Promise<string> {
  return new Promise((resolve) => rl.question(prompt, resolve));
}

function writeLine(out: NodeJS.WritableStream, text: string): void {
  out.write(`${text}\n`);
}

export async function runWizard(deps: WizardDeps): Promise<WizardResult> {
  const archetypes = Object.values(deps.dispatchTable.archetypes).map((e) => ({
    name: e.name,
    description: e.description ?? "",
    signals: e.signals ?? [],
  }));
  const rl = makeRl(deps);

  try {
    // ── 1. Archetype prompt ─────────────────────────────────
    writeLine(deps.output, "Pick an archetype :");
    archetypes.forEach((a, i) => {
      writeLine(deps.output, `  ${i + 1}) ${a.name}  — ${a.description}`);
    });
    let chosenIdx = -1;
    for (let attempt = 0; attempt < MAX_REPROMPT; attempt++) {
      const answer = (await ask(rl, "> ")).trim();
      if (!answer) {
        writeLine(deps.output, "  (empty input — aborting)");
        throw new Error("forge init wizard: empty archetype selection");
      }
      const n = Number.parseInt(answer, 10);
      if (Number.isFinite(n) && n >= 1 && n <= archetypes.length) {
        chosenIdx = n - 1;
        break;
      }
      writeLine(deps.output, `  invalid choice — pick 1..${archetypes.length}`);
    }
    if (chosenIdx === -1) {
      throw new Error("forge init wizard: archetype selection failed after 3 attempts");
    }
    const chosen = archetypes[chosenIdx];

    // ── 2. Project name prompt ──────────────────────────────
    let projectName = "";
    for (let attempt = 0; attempt < MAX_REPROMPT; attempt++) {
      projectName = (await ask(rl, "Project name (kebab-case, 2-50 chars): ")).trim();
      if (PROJECT_NAME_RE.test(projectName)) break;
      writeLine(
        deps.output,
        "  invalid — must match ^[a-z][a-z0-9-]{1,49}$ (e.g. my-app)",
      );
      projectName = "";
    }
    if (!projectName) {
      throw new Error("forge init wizard: project name validation failed");
    }

    // ── 3. Reverse domain prompt (only if archetype expects it) ─
    let reverseDomain: string | undefined;
    if (chosen.signals.length > 0) {
      for (let attempt = 0; attempt < MAX_REPROMPT; attempt++) {
        const candidate = (await ask(
          rl,
          "Reverse domain (e.g. io.acme.myapp): ",
        )).trim();
        const result = validateReverseDomain(candidate);
        if (result.valid) {
          reverseDomain = candidate;
          break;
        }
        writeLine(deps.output, `  ${result.reason}`);
      }
      if (!reverseDomain) {
        throw new Error(
          "forge init wizard: reverse domain validation failed",
        );
      }
    }

    // ── 4. Confirmation summary ─────────────────────────────
    const summary =
      reverseDomain !== undefined
        ? `forge init: archetype=${chosen.name}, project=${projectName}, org=${reverseDomain}`
        : `forge init: archetype=${chosen.name}, project=${projectName}`;
    writeLine(deps.output, summary);

    return { archetype: chosen.name, projectName, reverseDomain };
  } finally {
    rl.close();
  }
}
