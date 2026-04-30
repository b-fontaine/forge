import { Readable, Writable } from "node:stream";
import { describe, expect, it, vi } from "vitest";
import { initCommand } from "../../src/commands/init.js";
import type { DispatchTable } from "../../src/commands/init-archetype.js";

// Tests for the b5.1 dispatcher. The legacy file-copy behavior is
// covered by init-default.test.ts. These tests focus on dispatcher
// path selection, mutual exclusion, archetype routing, and the
// silent-default backwards-compat fallback (NFR-IW-004).

const dispatchTable: DispatchTable = {
  archetypes: {
    default: {
      name: "default",
      scaffolder: "<built-in>",
      description: "Minimal install",
      signals: [],
      since: "0.1.0",
    },
    "full-stack-monorepo": {
      name: "full-stack-monorepo",
      scaffolder: "bin/forge-init-fsm.sh",
      description: "Flutter + Rust",
      signals: ["pubspec.yaml", "Cargo.toml"],
      since: "1.0.0",
    },
  },
};

function makeStream(): { stream: Writable; chunks: string[] } {
  const chunks: string[] = [];
  const stream = new Writable({
    write(chunk, _enc, cb) {
      chunks.push(chunk.toString());
      cb();
    },
  });
  return { stream, chunks };
}

const baseDeps = (overrides: Record<string, unknown> = {}) => {
  const stdoutS = makeStream();
  const stderrS = makeStream();
  return {
    options: {
      sourceDir: "/src",
      targetDir: "/proj",
      force: false,
    },
    readDispatchTable: vi.fn().mockResolvedValue(dispatchTable),
    archetypeRunner: vi.fn().mockResolvedValue({ exitCode: 0 }),
    dispatchTablePath: "/forge/.forge/scaffolding/dispatch-table.yml",
    forgeRootDir: "/forge",
    stdin: Readable.from([]),
    stdout: stdoutS.stream,
    stderr: stderrS.stream,
    _stdoutChunks: stdoutS.chunks,
    _stderrChunks: stderrS.chunks,
    ...overrides,
  };
};

describe("initCommand dispatcher", () => {
  it("rejects mutually exclusive selection flags with exit 2", async () => {
    const deps = baseDeps({
      options: {
        sourceDir: "/src",
        targetDir: "/proj",
        force: false,
        archetype: "default",
        auto: true,
      },
    });
    const result = await initCommand(deps as never);
    expect(result.exitCode).toBe(2);
    expect(
      (deps as never as { _stderrChunks: string[] })._stderrChunks.join(""),
    ).toContain("mutually exclusive");
  });

  it("falls back to default archetype with no flags + non-TTY (NFR-IW-004)", async () => {
    const deps = baseDeps({
      options: {
        sourceDir: "/nonexistent",
        targetDir: "/nonexistent-target",
        force: false,
      },
    });
    const result = await initCommand(deps as never);
    // Default path : the dispatcher routes to runDefaultInit
    // (which gracefully handles missing dirs), and does NOT read
    // the dispatch table.
    expect(result.exitCode).toBeUndefined();
    expect(deps.readDispatchTable).not.toHaveBeenCalled();
  });

  it("explicit --archetype default routes to runDefaultInit", async () => {
    const deps = baseDeps({
      options: {
        sourceDir: "/nonexistent",
        targetDir: "/nonexistent-target",
        force: false,
        archetype: "default",
      },
    });
    const result = await initCommand(deps as never);
    expect(result.exitCode).toBeUndefined();
    expect(deps.readDispatchTable).not.toHaveBeenCalled();
  });

  it("--archetype full-stack-monorepo without --org returns exit 2", async () => {
    const deps = baseDeps({
      options: {
        sourceDir: "/src",
        targetDir: "/proj",
        force: false,
        archetype: "full-stack-monorepo",
        projectName: "my-app",
      },
    });
    const result = await initCommand(deps as never);
    expect(result.exitCode).toBe(2);
    expect(
      (deps as never as { _stderrChunks: string[] })._stderrChunks.join(""),
    ).toContain("--org");
  });

  it("--archetype with invalid reverse domain returns exit 3", async () => {
    const deps = baseDeps({
      options: {
        sourceDir: "/src",
        targetDir: "/proj",
        force: false,
        archetype: "full-stack-monorepo",
        projectName: "my-app",
        reverseDomain: "INVALID",
      },
    });
    const result = await initCommand(deps as never);
    expect(result.exitCode).toBe(3);
  });

  it("--archetype unknown returns exit 2 with usage", async () => {
    const deps = baseDeps({
      options: {
        sourceDir: "/src",
        targetDir: "/proj",
        force: false,
        archetype: "made-up",
        projectName: "my-app",
        reverseDomain: "io.acme.myapp",
      },
    });
    const result = await initCommand(deps as never);
    expect(result.exitCode).toBe(2);
    expect(
      (deps as never as { _stderrChunks: string[] })._stderrChunks.join(""),
    ).toContain("unknown archetype");
  });

  it("--archetype full-stack-monorepo with valid args invokes archetypeRunner", async () => {
    const deps = baseDeps({
      options: {
        sourceDir: "/src",
        targetDir: "/proj",
        force: false,
        archetype: "full-stack-monorepo",
        projectName: "my-app",
        reverseDomain: "io.acme.myapp",
      },
    });
    const result = await initCommand(deps as never);
    expect(result.exitCode).toBe(0);
    expect(deps.archetypeRunner).toHaveBeenCalledTimes(1);
    const call = (
      deps.archetypeRunner as { mock: { calls: unknown[][] } }
    ).mock.calls[0][0] as { scaffolderPath: string; args: string[] };
    expect(call.scaffolderPath).toContain("forge-init-fsm.sh");
    expect(call.args).toContain("my-app");
    expect(call.args).toContain("io.acme.myapp");
  });
});
