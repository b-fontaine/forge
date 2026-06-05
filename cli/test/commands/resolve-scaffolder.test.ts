import { describe, expect, it } from "vitest";
import { resolveScaffolder } from "../../src/commands/init-archetype.js";
import type { SchemaMeta } from "../../src/domain/schema-version.js";

// B.8.14 (b8-14-promotion-flip C2) — versioned scaffolder selection + the deferred
// B.8.3.b scaffoldable:false guard, as wired into `forge init`.

const FSM_DEFAULT = "bin/forge-init-fsm.sh";

describe("resolveScaffolder", () => {
  it("routes to the versioned wrapper when 2.0.0 is the highest scaffoldable and its wrapper exists", async () => {
    const metas: SchemaMeta[] = [
      { version: "1.0.0", stage: "stable", scaffoldable: true },
      { version: "2.0.0", stage: "stable", scaffoldable: true },
    ];
    const res = await resolveScaffolder(FSM_DEFAULT, metas, async (rel) =>
      rel === "bin/forge-init-fsm-2.0.0.sh",
    );
    expect(res).toEqual({
      kind: "ok",
      scaffolder: "bin/forge-init-fsm-2.0.0.sh",
      version: "2.0.0",
    });
  });

  it("falls back to the default wrapper when the chosen version has no versioned wrapper", async () => {
    const metas: SchemaMeta[] = [
      { version: "1.0.0", stage: "stable", scaffoldable: true },
    ];
    // No bin/forge-init-fsm-1.0.0.sh exists → keep the dispatch-table default.
    const res = await resolveScaffolder(FSM_DEFAULT, metas, async () => false);
    expect(res).toEqual({
      kind: "ok",
      scaffolder: FSM_DEFAULT,
      version: "1.0.0",
    });
  });

  it("falls back to the default wrapper (legacy) when no versioned schema is parseable", async () => {
    // e.g. mobile-only ships a schema.yaml with a different field shape
    // (archetype/schema_version), so the reader yields no metas. Must NOT refuse.
    const res = await resolveScaffolder(FSM_DEFAULT, [], async () => true);
    expect(res).toEqual({ kind: "ok", scaffolder: FSM_DEFAULT, version: "" });
  });

  it("refuses (B.8.3.b) when every schema version is non-scaffoldable", async () => {
    const metas: SchemaMeta[] = [
      { version: "2.0.0", stage: "candidate", scaffoldable: false },
    ];
    const res = await resolveScaffolder(FSM_DEFAULT, metas, async () => true);
    expect(res.kind).toBe("refuse");
    if (res.kind === "refuse") {
      expect(res.reason).toMatch(/scaffoldable/i);
    }
  });

  it("does not probe for a versioned wrapper when none could differ (1.0.0 only, default already 1.0.0-less name)", async () => {
    // Guard: the probe must only fire for a versioned candidate distinct from the
    // default name; a positive probe must not hijack the default when versions match.
    const metas: SchemaMeta[] = [
      { version: "2.0.0", stage: "stable", scaffoldable: true },
    ];
    let probed = "";
    const res = await resolveScaffolder(FSM_DEFAULT, metas, async (rel) => {
      probed = rel;
      return true;
    });
    expect(probed).toBe("bin/forge-init-fsm-2.0.0.sh");
    expect(res).toMatchObject({ kind: "ok", version: "2.0.0" });
  });
});
