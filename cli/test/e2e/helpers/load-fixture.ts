// Audit: T5.1 (cli-trust-harness) — ADR-T51-002
//
// Vendored mini YAML parser for archetype fixtures at
// `cli/test/e2e/archetype-fixtures/<name>.yml`. Zero new external dep
// (NFR-T51-001) ; ~80 LOC ceiling.
//
// Supported subset :
//   - Top-level `key: value` pairs where value is a scalar
//     (string, boolean, integer).
//   - Block-style scalar lists under a key
//     (`key:\n  - item1\n  - item2`).
//   - Leading `#` comments (skipped).
//
// Not supported (rejected loudly per ADR-T51-002) :
//   - Flow style (`key: [a, b]` or `key: {a: 1}`).
//   - YAML anchors / merge keys (`&foo`, `<<:`).
//   - Multi-document files (`---` separator).
//   - Multi-line block scalars (`|`, `>`).

import { readFileSync } from "node:fs";

export interface ArchetypeFixture {
  archetype: string;
  has_rust_backend: boolean;
  has_flutter_frontend: boolean;
  required_paths: string[];
  forbidden_paths: string[];
}

function stripQuotes(s: string): string {
  if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) return s.slice(1, -1);
  if (s.length >= 2 && s.startsWith("'") && s.endsWith("'")) return s.slice(1, -1);
  return s;
}

function parseScalar(value: string): string | boolean | number {
  const v = stripQuotes(value.trim());
  if (v === "true") return true;
  if (v === "false") return false;
  if (/^-?\d+$/.test(v)) return parseInt(v, 10);
  return v;
}

function rejectUnsupported(line: string, lineNo: number, raw: string): never {
  throw new Error(
    `load-fixture: unsupported YAML at line ${lineNo}: '${line}' — ${raw}`,
  );
}

export function parseFixture(content: string): Record<string, unknown> {
  const lines = content.split("\n");
  const result: Record<string, unknown> = {};
  let currentListKey: string | null = null;
  let currentList: string[] | null = null;

  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    const lineNo = i + 1;

    if (/^\s*$/.test(raw) || /^\s*#/.test(raw)) continue;

    if (raw.startsWith("---")) rejectUnsupported("multi-doc separator", lineNo, raw);
    if (raw.includes(" &") || raw.includes("<<:")) rejectUnsupported("anchor / merge key", lineNo, raw);

    // 2-space indent list item under the current key
    const listItem = raw.match(/^ {2}- (.+)$/);
    if (listItem && currentList) {
      const v = stripQuotes(listItem[1].trim());
      currentList.push(v);
      continue;
    }

    // Top-level `key: value` or `key:` (start of block list)
    const kv = raw.match(/^([a-zA-Z_][a-zA-Z0-9_]*):(?:\s*(.*))?$/);
    if (kv) {
      const key = kv[1];
      const value = (kv[2] ?? "").trim();
      if (value === "") {
        // Block-style list expected on subsequent lines.
        currentListKey = key;
        currentList = [];
        result[key] = currentList;
      } else {
        // Flow-style rejection.
        if (value.startsWith("[") || value.startsWith("{")) {
          rejectUnsupported("flow style", lineNo, raw);
        }
        if (value === "|" || value === ">") {
          rejectUnsupported("block scalar", lineNo, raw);
        }
        result[key] = parseScalar(value);
        currentListKey = null;
        currentList = null;
      }
      continue;
    }

    rejectUnsupported("unrecognised line", lineNo, raw);
  }

  return result;
}

export function loadFixture(archetypeName: string, fixturesDir: string): ArchetypeFixture {
  const path = `${fixturesDir}/${archetypeName}.yml`;
  const content = readFileSync(path, "utf8");
  const parsed = parseFixture(content);

  const archetype = parsed.archetype;
  const requiredPaths = parsed.required_paths;
  const forbiddenPaths = parsed.forbidden_paths;

  if (typeof archetype !== "string") {
    throw new Error(`load-fixture: ${path} missing 'archetype:' scalar`);
  }
  if (!Array.isArray(requiredPaths)) {
    throw new Error(`load-fixture: ${path} missing 'required_paths:' list`);
  }
  if (!Array.isArray(forbiddenPaths)) {
    throw new Error(`load-fixture: ${path} missing 'forbidden_paths:' list`);
  }

  return {
    archetype,
    has_rust_backend: parsed.has_rust_backend === true,
    has_flutter_frontend: parsed.has_flutter_frontend === true,
    required_paths: requiredPaths as string[],
    forbidden_paths: forbiddenPaths as string[],
  };
}
