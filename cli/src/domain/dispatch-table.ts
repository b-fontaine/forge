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

import type {
  DispatchTable,
  DispatchTableEntry,
} from "../commands/init-archetype.js";

function stripQuotes(s: string): string {
  if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
    return s.slice(1, -1);
  }
  if (s.length >= 2 && s.startsWith("'") && s.endsWith("'")) {
    return s.slice(1, -1);
  }
  return s;
}

export function parseDispatchTable(content: string): DispatchTable {
  const lines = content.split("\n");
  const archetypes: Record<string, DispatchTableEntry> = {};
  let currentName: string | null = null;
  let entry: Partial<DispatchTableEntry> = {};
  let inSignalsBlock = false;

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
    if (/^archetypes:\s*$/.test(raw)) continue;

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
      const value = fieldMatch[2].trimEnd();
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

  return { archetypes };
}
