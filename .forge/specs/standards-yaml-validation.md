# Spec: standards-yaml-validation

<!-- Audit: J.7 (j7-validate-standards-yaml) — automated enforcement of the .forge/standards/*.yaml frontmatter contract. -->
<!-- Source change : `.forge/changes/j7-validate-standards-yaml/` (archived 2026-05-08). -->

**Namespace** : `FR-J7-*` / `NFR-J7-*`.

**Constitution** : v1.1.0. Pas d'amendement requis (J.7 enforces, ne modifie pas).

**Validator** : `bin/validate-standards-yaml.sh`.
**Schema** : `.forge/schemas/standard.schema.json`.
**Harness** : `.forge/scripts/tests/j7.test.sh` (21 tests : 17 L1 + 4 L2).
**Lifecycle standard** : `.forge/standards/global/standards-lifecycle.md` § "Automated enforcement".
**User documentation** : `docs/SCHEMA.md` § "Standard YAML schema".

---

## Functional Requirements

### Cluster 1 — JSON Schema for standard frontmatter

#### FR-J7-001 — `standard.schema.json` exists

`.forge/schemas/standard.schema.json` MUST exist as JSON Schema
Draft 2020-12 with `additionalProperties: true` at root (ADR-J7-004 :
domain-specific bodies like `transport.codegen`, `state-management.framework`
remain free-form).

#### FR-J7-002 — Required frontmatter fields

`required: [version, last_reviewed, expires_at, exception_constitutional, linter_rule, enforcement, forbidden, rationale]`.

#### FR-J7-003 — `version` SemVer pattern

`^[0-9]+\.[0-9]+\.[0-9]+$`. String type.

#### FR-J7-004 — `last_reviewed` ISO 8601

Pattern `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`. String type.

#### FR-J7-005 — `expires_at` polymorphic

Either ISO 8601 date OR the literal `never`. Polymorphic check
performed in Phase 2 of the validator (schema declares `type: string`
to keep the walker simple).

#### FR-J7-006 — `exception_constitutional` boolean

`type: boolean`. Strict — non-bool (e.g. `"yes"`) rejected.

#### FR-J7-007 — `linter_rule` nullable string

`type: ["string", "null"]`. When string, kebab-case
`^[a-z][a-z0-9-]*$`.

#### FR-J7-008 — `enforcement` object shape

`required: [ci_blocking, pre_commit_hook]`. Each sub-key
`type: boolean`. `additionalProperties: true` — relaxed from initial
spec to accommodate `state-management.yaml`'s documented
`activation_planned: "B.8 (T6)"` extension. Future J.7-extension may
tighten once the extension vocabulary stabilises.

#### FR-J7-009 — `forbidden` list shape

`type: array`, `items: {type: string}`. Empty list `[]` valid.

#### FR-J7-010 — `rationale` non-empty string

`type: string`, `minLength: 1`. Multiline `|` block scalars valid.

---

### Cluster 2 — Lifecycle invariants (Phase 2)

#### FR-J7-020 — Article XII coupling (bidirectional)

`expires_at: never` ⇔ `exception_constitutional: true`. Both
directions checked. Error : `[STD-FAIL: ...:expires_at: never requires exception_constitutional: true (Article XII)]`
(or symmetric).

#### FR-J7-021 — Strict ordering when dated

`expires_at > last_reviewed` strict when both are ISO dates. No
tolerance. Error : `must be strictly greater than last_reviewed`.

#### FR-J7-022 — 12-month review cycle (informational)

Non-blocking `[STD-INFO]` when `expires_at - last_reviewed > ~13 months + 5d slack`.

#### FR-J7-023 — REVIEW.md ledger drift (full ledger scan)

Per ADR-J7-003 : the declared `version` MUST appear in
`.forge/standards/REVIEW.md` somewhere. Match a markdown table row
`| <basename> | <version> | ...` (regex multiline). Multi-entry per
`(file, version)` pair tolerated (e.g. transport.yaml's two legitimate
v1.1.0 entries on 2026-05-05).

---

### Cluster 3 — `linter_rule` cross-reference

#### FR-J7-030 — Rule existence in `constitution-linter.sh`

Per ADR-J7-002 : when `linter_rule` is non-null, regex
`^\s*(echo|#).*\b{rule}\b` (Python `re.M`) MUST match in
`.forge/scripts/constitution-linter.sh`. This catches both echo-form
section prints and comment-form section headers, while excluding
incidental matches inside `fail`/`warn` arguments.

#### FR-J7-031 — Null escape hatch preserved

`linter_rule: null` is always valid. Used by structural standards
(`transport.yaml`, `state-management.yaml`) whose enforcement is
amongst Janus orchestrator rules (J.8) rather than the constitution
linter.

---

### Cluster 4 — `forbidden` list shape

#### FR-J7-040 — Canonical entries

Each entry MUST be a non-empty trimmed string.

#### FR-J7-041 — No duplicates

Within a single standard's `forbidden:` list, the same canonical
string MUST NOT appear twice.

---

### Cluster 5 — `index.yml` triggers cross-reference

#### FR-J7-050 — Trigger target exists

For every entry in `index.yml` whose `path:` field references a
`.yaml` or `.md` file, the referenced file MUST exist on disk.
Resolution : `path:` is relative to `.forge/`, so candidate paths are
`<repo-root>/.forge/<path>` (canonical) and `<repo-root>/<path>`
(fallback).

#### FR-J7-051 — Reverse coverage (informational)

Non-blocking `[STD-INFO]` for any `.forge/standards/*.yaml` not
referenced by any `index.yml` entry. Orphans are allowed (legacy or
pre-T4 files) but the maintainer is notified.

---

### Cluster 6 — Validator script

#### FR-J7-060 — `validate-standards-yaml.sh` exists

`bin/validate-standards-yaml.sh`, executable bash header
(`#!/usr/bin/env bash`, `set -uo pipefail`).

#### FR-J7-061 — Signature

`bash bin/validate-standards-yaml.sh [<dir-or-file>]`. Default
`.forge/standards/`. Exit `0` (PASS), `1` (FAIL), `2` (usage error).

#### FR-J7-062 — Validation engine

Python 3 inline (no `jsonschema` lib — F.2 reuse pattern). Phase 1 :
JSON Schema walk. Phase 2 : lifecycle + cross-references.

#### FR-J7-063 — Date coercion

PyYAML parses unquoted ISO dates as `datetime.date` ; the validator
converts back to string before pattern match. Mirrors F.2 lines
55–67 of `validate-change-yaml.sh`.

#### FR-J7-064 — Error format (ADR-J7-005)

- stdout : `[STD-PASS] <relative-path>` for clean files,
  `[STD-INFO: <path>:<field>: <reason>]` for non-blocking signals.
- stderr : `[STD-FAIL: <path>:<field>: <reason>]` for blocking
  violations. Multiple errors per file accumulate before exit.

---

### Cluster 7 — `verify.sh` integration

#### FR-J7-070 — New section "Standards YAML Schema"

Section header in `.forge/scripts/verify.sh`, immediately after the
F.2 "Change YAML Schema" section.

#### FR-J7-071 — Counter aggregation

PASS/FAIL counts aggregate into the global `verify.sh` totals (no new
mint).

#### FR-J7-072 — Skip-guards

`examples/**/.forge/standards/*.yaml` skipped without count
(if any ever appear). `index.yml` is excluded by name from the
per-file iteration.

---

### Cluster 8 — Test harness `j7.test.sh`

#### FR-J7-080 — Harness layout

`.forge/scripts/tests/j7.test.sh`, mirrors F.2 / T.5 layout : shared
bash header, `_helpers.sh` source, PASS/FAIL counters, `--level 1,2`
parsing.

#### FR-J7-081 — L1 coverage ≥ 16 tests

17 L1 tests shipped (16 schema/invariants + 1 production-tree
GREEN-baseline guard).

#### FR-J7-082 — L2 coverage ≥ 3 fixture tests

4 L2 tests shipped : good-fixture mini-tree, bad-fixture six failure
modes, drift-fixture, perf-budget on the live tree.

---

### Cluster 9 — CI registration

#### FR-J7-090 — `forge-ci.yml` matrix entry

`j7.test.sh` registered in the `harness` job matrix with
`--level 1,2` immediately after `t5.test.sh`.

---

### Cluster 10 — Standard + Documentation

#### FR-J7-100 — `standards-lifecycle.md` cross-reference

`.forge/standards/global/standards-lifecycle.md` § "Automated
enforcement" lists the 5 blocking + 2 informational invariants and
points to the validator + harness.

#### FR-J7-101 — `docs/SCHEMA.md` extension

`docs/SCHEMA.md` § "Standard YAML schema" : frontmatter table,
lifecycle invariants, CLI usage, common errors recipe, "adding a new
standard YAML" walkthrough.

#### FR-J7-102 — `CHANGELOG.md` entry

Entry under `## [Unreleased]` summarising the validator, schema, harness,
verify.sh integration, doc updates.

---

## Non-Functional Requirements

### NFR-J7-001 — Performance budget

`bash bin/validate-standards-yaml.sh` ≤ 2 s on the six existing
standards. **Measured** : 122 ms (6 % of budget). Harness `--level 1`
≤ 3 s, full `--level 1,2` ≤ 8 s.

### NFR-J7-002 — Backward compatibility

The six existing standards pass the validator on first invocation
(GREEN baseline) without YAML modification. **Confirmed** :
6 `[STD-PASS]` + 0 `[STD-FAIL]` on the live tree.

### NFR-J7-003 — Article V audit trail

Linter failure messages reference the schema field path
(`<file>:<field>: <reason>`), machine-parseable. All tasks in
`tasks.md` carry `[Story: FR-J7-XXX]`.

### NFR-J7-004 — F.2 pattern alignment

Validator follows F.2's bash + Python 3 inline pattern verbatim where
applicable. Phase 1/Phase 2 split, PyYAML date coercion, single-line
stderr error format. Documented in ADR-J7-001 (design.md).

### NFR-J7-005 — Forge CLI surface

No new flag or subcommand on `@sdd-forge/cli`. Linter is invoked
through `verify.sh` and the harness only.

### NFR-J7-006 — No external Python deps

Vanilla `python3` (≥ 3.10) without `pip install`. Standard library +
PyYAML (already required by F.2).

---

## ADRs (J.7 design)

| ID         | Decision summary                                                                                                                                                              |
|------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ADR-J7-001 | Validator architecture : F.2 verbatim reuse (bash thin + Python 3 inline, PyYAML date coercion, Phase 1/Phase 2 split, accumulating errors).                                  |
| ADR-J7-002 | `linter_rule` cross-reference pattern : structured grep `^\s*(echo|#).*\b{rule}\b` (Python `re.M`). Locks Q-003 after live `constitution-linter.sh` inspection.               |
| ADR-J7-003 | REVIEW.md drift detection scope : full ledger scan via `\| <file> \| <version> \|` table-row regex (multiline). Multi-entry per `(file, version)` tolerated. Locks Q-004.    |
| ADR-J7-004 | Schema location `.forge/schemas/standard.schema.json` ; `additionalProperties: true` at root (domain bodies free) ; `additionalProperties: true` on enforcement (relaxed).   |
| ADR-J7-005 | Error format : `[STD-FAIL: <path>:<field>: <reason>]` to stderr, `[STD-PASS]` / `[STD-INFO]` to stdout. Exit codes 0/1/2 mirror F.2.                                          |

Full design rationale + Mermaid diagrams + Open Questions resolution :
`.forge/changes/j7-validate-standards-yaml/design.md`.
