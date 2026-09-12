// Forge — minimal YAML subset parser for `dispatch-table.yml`.
// FR-IW-002 of b5-1-init-wizard. Pure function, no third-party
// dependency (NFR-IW-002).
//
// The grammar handled is intentionally narrow — exactly the
// shape of dispatch-table.yml :
//
//   archetypes:
//     <name>:
//       name: <scalar>
//       scaffolder: <scalar>
//       description: <scalar>
//       signals: []                 # empty inline list
//       signals:                    # block list
//         - item1
//         - item2
//       since: <scalar>
//
//   forbidden_archetypes:         # J.8 — t7-forbidden-archetypes-wiring
//     - name: <scalar>
//       reason: <scalar>
//       since: <scalar>
//       alternative: <scalar>
//       rule_id: <scalar>
//
// TOP-LEVEL KEYS ARE TRACKED, and that is not cosmetic. Before
// t7-forbidden-archetypes-wiring this parser had no notion of which block it was
// in: it skipped `archetypes:` and then matched 4-space fields against whatever
// `currentName` was last set. Two consequences, both measured:
//
//   * `forbidden_archetypes:` was never returned, so J.8's refusal at
//     init-archetype.ts:159 could never fire and `forge init --archetype
//     flutter-firebase` exited 127 with a shell error instead of 3 with a
//     [REFUSAL: ...] line;
//   * every `since:` in the blocks that FOLLOW `archetypes:` overwrote the last
//     archetype's. `flutter-firebase` — the last entry — parsed as
//     `"0.5.0"   # realigned 2026-09-08 ...`, picking up both a wrong value and a
//     trailing comment from forbidden_combinations:'s final row.

import type {
  DispatchTable,
  DispatchTableEntry,
  ForbiddenArchetypeEntry,
} from "../commands/init-archetype.js";

// Remove a trailing `# ...` comment that is not inside a quoted scalar.
// Hardening, not a bug fix on its own: once top-level blocks are tracked, no value
// inside `archetypes:` carries one today. It is here so that adding a comment to a
// field tomorrow cannot silently become part of its value, which is exactly how
// `flutter-firebase.since` ended up holding a sentence.
function stripComment(s: string): string {
  const t = s.trim();
  if (t.startsWith('"') || t.startsWith("'")) {
    const q = t[0];
    const end = t.indexOf(q, 1);
    if (end !== -1) return t.slice(0, end + 1);
    return t;
  }
  const hash = t.indexOf("#");
  return hash === -1 ? t : t.slice(0, hash).trimEnd();
}

function stripQuotes(s: string): string {
  if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
    return s.slice(1, -1);
  }
  if (s.length >= 2 && s.startsWith("'") && s.endsWith("'")) {
    return s.slice(1, -1);
  }
  return s;
}

type Block = "archetypes" | "forbidden_archetypes" | "other";

export function parseDispatchTable(content: string): DispatchTable {
  const lines = content.split("\n");
  const archetypes: Record<string, DispatchTableEntry> = {};
  const forbidden: ForbiddenArchetypeEntry[] = [];
  let currentName: string | null = null;
  let entry: Partial<DispatchTableEntry> = {};
  let inSignalsBlock = false;
  let block: Block = "other";
  let forbiddenEntry: Partial<ForbiddenArchetypeEntry> | null = null;

  const flushForbidden = (): void => {
    if (forbiddenEntry && forbiddenEntry.name) {
      forbidden.push({
        name: forbiddenEntry.name,
        reason: forbiddenEntry.reason ?? "",
        since: forbiddenEntry.since ?? "",
        alternative: forbiddenEntry.alternative ?? "",
        rule_id: forbiddenEntry.rule_id ?? "",
      });
    }
    forbiddenEntry = null;
  };

  const flush = (): void => {
    if (currentName) {
      const final: DispatchTableEntry = {
        name: entry.name ?? currentName,
        scaffolder: entry.scaffolder ?? "",
        description: entry.description,
        signals: entry.signals ?? [],
        since: entry.since,
        status: entry.status,
      };
      archetypes[currentName] = final;
    }
  };

  for (const raw of lines) {
    if (/^\s*$/.test(raw) || /^\s*#/.test(raw)) continue;

    // Any top-level key closes the block before it. This is what stops
    // forbidden_archetypes: and forbidden_combinations: from leaking their fields
    // into the last archetype parsed.
    const topLevel = raw.match(/^([a-z_]+):\s*$/);
    if (topLevel) {
      flush();
      flushForbidden();
      currentName = null;
      entry = {};
      inSignalsBlock = false;
      block =
        topLevel[1] === "archetypes"
          ? "archetypes"
          : topLevel[1] === "forbidden_archetypes"
            ? "forbidden_archetypes"
            : "other";
      continue;
    }

    if (block === "forbidden_archetypes") {
      // `  - name: <scalar>` opens an entry; `    <key>: <scalar>` continues it.
      const itemStart = raw.match(/^ {2}- ([a-z_]+):\s*(.*)$/);
      if (itemStart) {
        flushForbidden();
        forbiddenEntry = {};
        (forbiddenEntry as Record<string, string>)[itemStart[1]] = stripQuotes(
          stripComment(itemStart[2]),
        );
        continue;
      }
      const cont = raw.match(/^ {4}([a-z_]+):\s*(.*)$/);
      if (cont && forbiddenEntry) {
        (forbiddenEntry as Record<string, string>)[cont[1]] = stripQuotes(
          stripComment(cont[2]),
        );
      }
      continue;
    }

    if (block !== "archetypes") continue;

    // 2-space indent : archetype name
    const archMatch = raw.match(/^ {2}([A-Za-z][A-Za-z0-9_-]*):\s*$/);
    if (archMatch) {
      flush();
      currentName = archMatch[1];
      entry = { name: currentName, scaffolder: "", signals: [] };
      inSignalsBlock = false;
      continue;
    }

    // 4-space indent : field
    const fieldMatch = raw.match(/^ {4}([a-z_]+):\s*(.*)$/);
    if (fieldMatch && currentName) {
      const key = fieldMatch[1];
      const value = stripComment(fieldMatch[2]);
      if (key === "signals") {
        const inline = value.match(/^\[(.*)\]$/);
        if (inline) {
          entry.signals = inline[1]
            .split(",")
            .map((s) => stripQuotes(s.trim()))
            .filter(Boolean);
          inSignalsBlock = false;
        } else if (value === "" || value === "[]") {
          entry.signals = [];
          inSignalsBlock = value === "";
        } else {
          // unsupported inline signal scalar — treat as single item
          entry.signals = [stripQuotes(value.trim())];
          inSignalsBlock = false;
        }
      } else {
        const v = stripQuotes(value);
        if (
          key === "name" ||
          key === "scaffolder" ||
          key === "description" ||
          key === "since" ||
          key === "status"
        ) {
          (entry as Record<string, string>)[key] = v;
        }
        inSignalsBlock = false;
      }
      continue;
    }

    // 6-space indent + "- value" : block signals list item
    const itemMatch = raw.match(/^ {6}- (.+)$/);
    if (itemMatch && inSignalsBlock && currentName && entry.signals) {
      entry.signals.push(stripQuotes(itemMatch[1].trim()));
      continue;
    }
  }
  flush();
  flushForbidden();

  return forbidden.length > 0
    ? { archetypes, forbidden_archetypes: forbidden }
    : { archetypes };
}
