# Specifications: j7-validate-standards-yaml
<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-J7-*` / `NFR-J7-*`. **Constitution** : v1.1.0. Pas
d'amendement requis.

## Source Documents

This change descends from a single ratified source plus the F.2 validator
infrastructure that it directly reuses :

| Field             | Value                                                                                                                                                             |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **ADR base**      | `t4-adr-ratification` archived 2026-05-04 (FR-T4-STD-001..006 ratifying the six standards YAML + FR-T4-LC-001..005 ratifying the lifecycle frontmatter contract)  |
| **Plan ref**      | `docs/new-archetypes-plan.md` §1.4 J.7 row + §15 item #3 (T5 next concrete action post-`t5-connect-codegen`)                                                      |
| **Roadmap ref**   | `.forge/product/roadmap.md` Phase 3 / T5 row (§"Still pending in T5")                                                                                             |
| **Standard ref**  | `.forge/standards/global/standards-lifecycle.md` (12-month review cycle, Article XII coupling)                                                                    |
| **Pattern reuse** | `f2-yaml-schema` archived 2026-05-01 (`validate-change-yaml.sh` bash + Python 3 inline pattern, schema Draft 2020-12 + Phase 1/Phase 2 separation)                |
| **YAML baseline** | Six `.forge/standards/*.yaml` files : `transport` v1.1.0, `state-management` / `observability` / `orchestration` / `identity` / `persistence` v1.0.0              |

No new external source document is pinned. The frontmatter contract is
already spelled out by FR-T4-LC-001..005 in `.forge/specs/adr-ratification.md`
and by the `global/standards-lifecycle.md` standard.

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — JSON Schema for standard frontmatter (FR-J7-001 → 010)

##### FR-J7-001 — `standard.schema.json` exists

`.forge/schemas/standard.schema.json` MUST exist as a JSON Schema
Draft 2020-12 document with `additionalProperties: true` (standards
carry body fields beyond the frontmatter — e.g. `transport.yaml`'s
`codegen.versions`).

##### FR-J7-002 — Required frontmatter fields

`required: [version, last_reviewed, expires_at, exception_constitutional, linter_rule, enforcement, forbidden, rationale]`.

##### FR-J7-003 — `version` SemVer pattern

`^[0-9]+\.[0-9]+\.[0-9]+$`. String type.

##### FR-J7-004 — `last_reviewed` ISO 8601

Pattern `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`. String type.

##### FR-J7-005 — `expires_at` polymorphic

Either ISO 8601 date string `^[0-9]{4}-[0-9]{2}-[0-9]{2}$` OR the
literal string `never`.

##### FR-J7-006 — `exception_constitutional` boolean

`type: boolean`.

##### FR-J7-007 — `linter_rule` nullable string

`type: [string, "null"]`. When string, MUST match the canonical
section-anchor pattern `^[a-z][a-z0-9-]*$` (kebab-case).

##### FR-J7-008 — `enforcement` object shape

`type: object` with `required: [ci_blocking, pre_commit_hook]`. Each
sub-key `type: boolean`. `additionalProperties: false`.

##### FR-J7-009 — `forbidden` list shape

`type: array`, `items: { type: string }`. Empty list `[]` is valid
(some standards have no forbidden alternatives).

##### FR-J7-010 — `rationale` non-empty string

`type: string`, `minLength: 1`. Multiline strings (YAML `|` block
scalars) are valid.

---

#### Cluster 2 — Lifecycle invariants (FR-J7-020 → 023)

These are cross-field rules enforced **after** Phase 1 schema validation
(Phase 2 in the validator script, mirroring F.2 FR-YS-008/009 split).

##### FR-J7-020 — `expires_at: never` ⇔ `exception_constitutional: true`

If `expires_at == "never"`, then `exception_constitutional` MUST be
`true`. Conversely, if `exception_constitutional == true`, then
`expires_at` MUST be `"never"`. **Bidirectional coupling** — Article XII
mandates that only constitutional decisions are exempt from the 12-month
review cycle.

##### FR-J7-021 — `expires_at > last_reviewed` when dated

If `expires_at` is an ISO date (not `never`), it MUST be **strictly
greater** than `last_reviewed`. No tolerance window.

##### FR-J7-022 — 12-month review cycle (informational only)

The validator MUST emit a non-blocking `[STD-INFO]` line if
`expires_at` is more than `last_reviewed + 13 months` (i.e. the
cycle is loose). It MUST NOT block on this rule. Resolution of Q-002 :
**strict 12 months** for the dated case ; opt-out is `expires_at:
never` (paired with `exception_constitutional: true`).

##### FR-J7-023 — REVIEW.md drift check

`.forge/standards/REVIEW.md` MUST contain at least one ledger entry
whose `Reviewed standards` table cell mentions the given standard
filename and whose recorded `version` matches the standard's
declared `version`. The validator MUST emit `[STD-FAIL]` when the
declared `version` is absent from the ledger. Append-only ledger
semantics from F.1 / T4 are preserved.

---

#### Cluster 3 — `linter_rule` cross-reference (FR-J7-030 → 031)

##### FR-J7-030 — Rule existence in `constitution-linter.sh`

If `linter_rule` is a non-null string, the validator MUST verify that
`.forge/scripts/constitution-linter.sh` contains a matching section
anchor (heuristic : grep for the canonical header pattern
`^# === ${linter_rule} ===` or equivalent ; the exact pattern is
locked at design time per Q-003 below). On miss → `[STD-FAIL]`.

##### FR-J7-031 — Null escape hatch preserved

`linter_rule: null` is always valid (no cross-reference performed).
Used by structural standards like `transport.yaml` and
`state-management.yaml` whose enforcement is amongst Janus
orchestrator rules (J.8) rather than the constitution linter.

---

#### Cluster 4 — `forbidden` list shape (FR-J7-040 → 041)

##### FR-J7-040 — Canonical entries

Each entry MUST be a non-empty trimmed string. Leading/trailing
whitespace is rejected.

##### FR-J7-041 — No duplicates

Within a single standard's `forbidden:` list, the same canonical
string MUST NOT appear twice.

---

#### Cluster 5 — `index.yml` triggers cross-reference (FR-J7-050 → 051)

Resolution of Q-001 : **YES**, the linter validates
`.forge/standards/index.yml` triggers point to existing standards.

##### FR-J7-050 — Trigger target exists

For every entry in `index.yml` whose `path:` field references a
`.forge/standards/*.yaml` or `.forge/standards/global/*.md` file,
the referenced file MUST exist on disk. On miss → `[STD-FAIL]`.

##### FR-J7-051 — Reverse coverage (informational)

The validator MUST emit a non-blocking `[STD-INFO]` line for any
`.forge/standards/*.yaml` file that is **not** referenced by any
`index.yml` entry. This is informational only — orphan standards
are allowed (e.g. legacy or pre-T4 files), but the maintainer is
notified.

---

#### Cluster 6 — Validator script (FR-J7-060 → 064)

##### FR-J7-060 — `validate-standards-yaml.sh` exists

`bin/validate-standards-yaml.sh` MUST exist as an executable bash
script with the standard Forge header (`#!/usr/bin/env bash`,
`set -uo pipefail`, source `_helpers.sh` if present).

##### FR-J7-061 — Signature

`validate-standards-yaml.sh [<path-to-standards-dir>]` ; defaults to
`.forge/standards/` when no argument is provided. Exit codes :
`0` (all PASS), `1` (one or more FAIL), `2` (usage error).

##### FR-J7-062 — Validation engine

Python 3 inline (no `jsonschema` library — F.2 reuse pattern).
**Phase 1** : per-file JSON Schema validation (FR-J7-001..010).
**Phase 2** : lifecycle invariants + cross-references
(FR-J7-020..023, FR-J7-030, FR-J7-040..041, FR-J7-050..051).

##### FR-J7-063 — Date coercion

PyYAML coerces unquoted ISO dates to `datetime.date`. The validator
MUST convert them back to `string` before pattern matching, mirroring
`validate-change-yaml.sh` lines 80–90. Reuse, do not re-invent.

##### FR-J7-064 — Error format

Deterministic single-line format :
`[STD-FAIL: <relative-path>:<field>: <reason>]` to stderr. Multiple
errors per file accumulate before exit. PASS files emit
`[STD-PASS] <relative-path>` to stdout.

---

#### Cluster 7 — `verify.sh` integration (FR-J7-070 → 072)

##### FR-J7-070 — New section "Standards YAML Schema"

`verify.sh` MUST gain a section header **immediately after** the
"Change YAML Schema" section (F.2) and **before** the harness
matrix invocations. Section iterates over `.forge/standards/*.yaml`
(top-level only ; `global/` excluded — those are markdown).

##### FR-J7-071 — Counter aggregation

PASS/FAIL counts from this section MUST aggregate into the same
totals as F.2 ; the final summary line is unchanged in shape.

##### FR-J7-072 — Skip-guards

The `examples/` skip-guard convention from F.1 / F.2 MUST be
honored : standards under `examples/**/.forge/standards/*.yaml`
(if any ever appear) are skipped without count.

---

#### Cluster 8 — Test harness `j7.test.sh` (FR-J7-080 → 082)

##### FR-J7-080 — Harness layout

`.forge/scripts/tests/j7.test.sh` MUST mirror the F.2 / T.5 layout :
shared bash header, `_helpers.sh` source, PASS/FAIL counters,
`--level 1,2` parsing, `print_summary` close-out.

##### FR-J7-081 — L1 coverage ≥ 15 tests

Minimum 15 L1 tests covering : 8 frontmatter fields × shape
(presence + type + pattern), 4 invariants
(FR-J7-020..023), 2 cross-references (FR-J7-030, FR-J7-050),
1 negative `forbidden` duplicate case.

##### FR-J7-082 — L2 coverage ≥ 3 fixture tests

Minimum 3 L2 fixture tests using temp dirs :
1. **Good fixture** : a synthetic standard YAML mirroring
   `transport.yaml`'s shape passes Phase 1 + Phase 2.
2. **Bad fixture** : six negative cases (one per failure mode :
   missing field, bad SemVer, bad date, broken Article XII
   coupling, unknown `linter_rule`, dangling `index.yml` trigger),
   each producing the exact deterministic
   `[STD-FAIL: <file>:<field>: <reason>]` line.
3. **Drift fixture** : a YAML where `version: "1.2.0"` but
   `REVIEW.md` only mentions `1.1.0` → expects `[STD-FAIL]`.

---

#### Cluster 9 — CI registration (FR-J7-090)

##### FR-J7-090 — `forge-ci.yml` matrix entry

`.github/workflows/forge-ci.yml` MUST register `j7.test.sh` in the
`harness` job matrix immediately after `t5.test.sh` with
`--level 1,2` so both levels run on every PR.

---

#### Cluster 10 — Standard + Documentation (FR-J7-100 → 102)

##### FR-J7-100 — `standards-lifecycle.md` cross-reference

`.forge/standards/global/standards-lifecycle.md` MUST gain a section
"Automated enforcement" referencing `bin/validate-standards-yaml.sh`
and the `j7.test.sh` harness.

##### FR-J7-101 — `docs/SCHEMA.md` extension

`docs/SCHEMA.md` MUST gain a section "Standard YAML schema" mirroring
the existing "Change YAML schema" section (frontmatter contract,
invariants, common errors).

##### FR-J7-102 — `CHANGELOG.md` entry

`CHANGELOG.md` MUST gain one line under `## [Unreleased]` summarising
the new linter, schema, and harness.

---

### Non-Functional Requirements

#### NFR-J7-001 — Linter performance budget

`bash bin/validate-standards-yaml.sh` MUST complete in **≤ 2 seconds**
on the six existing standards (cold + warm). `j7.test.sh --level 1`
MUST complete in **≤ 3 seconds** ; full `--level 1,2` in **≤ 8
seconds** (no Rust build, no network).

#### NFR-J7-002 — Backward compatibility

The six existing standards MUST pass the linter on first invocation
(GREEN baseline) without any modification to the YAML files
themselves. **No retroactive frontmatter rewriting** is permitted by
this change.

#### NFR-J7-003 — Article V audit trail

Every task in `tasks.md` MUST carry a `[Story: FR-J7-XXX]` tag.
Linter failure messages MUST reference the schema field path, not
free-form text, so downstream gates can be machine-parsed.

#### NFR-J7-004 — F.2 pattern alignment

The validator script MUST follow the F.2 pattern verbatim where
applicable : Phase 1/Phase 2 split, Python 3 inline, PyYAML date
coercion, single-line stderr error format. Deviations MUST be
documented in `design.md` ADR-J7-NNN entries.

#### NFR-J7-005 — Forge CLI surface

This change MUST NOT introduce any new flag or subcommand on the
npm `@sdd-forge/cli` binary. The linter is invoked through
`verify.sh` and the harness only.

#### NFR-J7-006 — No external Python deps

The validator MUST work on a vanilla `python3` (≥ 3.10) without
`pip install`. Standard library only (`yaml` is shipped via PyYAML
which F.2 already requires ; no further dependencies).

---

## BDD Acceptance Criteria

The linter is maintainer-facing, but the L2 fixture tests are
expressed as Given/When/Then scenarios for clarity (FR-J7-082).

### Scenario 1 — Happy path on the production tree

```gherkin
Given the six standards under .forge/standards/*.yaml exist as shipped by t4-adr-ratification + t5-connect-codegen
When `bash bin/validate-standards-yaml.sh` runs from the repo root
Then exit code is 0
And every line on stdout has the shape "[STD-PASS] <path>"
And nothing is written to stderr
```

### Scenario 2 — Detects a broken Article XII coupling

```gherkin
Given a synthetic standard YAML with `expires_at: never` but `exception_constitutional: false`
When the validator runs against the fixture directory
Then exit code is 1
And stderr contains exactly one line "[STD-FAIL: <fixture>:expires_at: never requires exception_constitutional: true (Article XII)]"
And no other failure line is emitted for that file
```

### Scenario 3 — Detects REVIEW.md drift

```gherkin
Given a synthetic standard YAML with version "1.2.0"
And the synthetic REVIEW.md only mentions version "1.1.0" for that file
When the validator runs against the fixture directory
Then exit code is 1
And stderr contains the line "[STD-FAIL: <fixture>:version: declared 1.2.0 not present in REVIEW.md ledger]"
```

---

## Anti-Hallucination Pass

For each FR above :

- **Testable** : every FR is asserted by at least one test in
  `j7.test.sh` (mapping captured in `tasks.md` `[Story: FR-J7-XXX]`
  tags during `/forge:plan`).
- **Unambiguous** : two ambiguities flagged below as
  `[NEEDS CLARIFICATION:]` for `/forge:design` resolution.
- **Constitution-compliant** : Article I (TDD enforced via RED
  witness convention), Article III (specs first, no code yet),
  Article V (audit trail), Article X (raises gate coverage),
  Article XII (enforces lifecycle without amending it).

---

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this `specs.md`.
Two open questions Q-003 + Q-004 raised at this phase, both tracked
in `open-questions.md` and resolved during `/forge:design` :

- **Q-003** → ADR-J7-002 locks the `linter_rule` cross-reference
  pattern to a structured grep `^\s*(echo|#).*\b{rule}\b` after a
  live `constitution-linter.sh` inspection (the cosmetic
  `# === ${rule} ===` candidate does not exist in the live
  convention ; the actual section anchors are echo-form and
  comment-header form).
- **Q-004** → ADR-J7-003 locks the REVIEW.md drift detection scope
  to a **full ledger scan** (multi-entry per `(file, version)`
  tolerated, as confirmed by `transport.yaml` having two legitimate
  v1.1.0 entries on 2026-05-05).

---

## Resolved Open Questions (from proposal)

- **Q-001 (proposal)** : Validate that `index.yml` triggers reference
  existing standards ? → **YES**, captured as Cluster 5 (FR-J7-050).
- **Q-002 (proposal)** : Tolerance window on `expires_at >
  last_reviewed + 12 months` ? → **Strict** ; opt-out is
  `expires_at: never` paired with `exception_constitutional: true`
  (FR-J7-021 + FR-J7-022).
