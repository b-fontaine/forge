# Proposal: j7-validate-standards-yaml
<!-- Created: 2026-05-07 -->
<!-- Schema: default -->

## Problem

The six versioned standards `.forge/standards/*.yaml` (`transport`, `state-management`,
`observability`, `orchestration`, `identity`, `persistence`) shipped via
`t4-adr-ratification` (2026-05-04) and bumped by `t5-connect-codegen`
(2026-05-06 — `transport.yaml` 1.0.0 → 1.1.0) carry a **uniform frontmatter
contract** : `version`, `last_reviewed`, `expires_at`, `exception_constitutional`,
`linter_rule`, `enforcement`, `forbidden`, `rationale`.

Today, this contract is enforced **by convention only**. There is no automated
check that:

- All required fields are present and well-typed.
- `version` follows SemVer.
- `last_reviewed` and `expires_at` are valid ISO-8601 dates ; `expires_at` is
  either the literal `never` or strictly greater than `last_reviewed`
  (12-month review cycle per `global/standards-lifecycle.md`).
- `expires_at: never` is **always coupled** with `exception_constitutional: true`
  (Article XII coupling — only constitutional decisions are exempt from review).
- The `linter_rule:` field references a rule actually emitted by
  `constitution-linter.sh`.
- `forbidden:` entries are well-formed (canonical strings, no duplicates).
- The `version` declared in the frontmatter matches the latest `Updated` /
  `Reviewed` entry in `.forge/standards/REVIEW.md`.

A typo, missing field, or stale `last_reviewed` can silently ship and only
surface when an adopter or downstream tool parses the YAML. Every new standard
bump (`observability.yaml` when SigNoz / OBI / Coroot lands in T5,
`identity.yaml` when Zitadel migration completes in T6, additional standards in
T7+) compounds the risk.

The `j7-validate-standards-yaml` linter closes this gap **before** the audit
surface gets bigger.

## Solution

Ship a deterministic linter `bin/validate-standards-yaml.sh` (mirroring the
bash + Python 3 inline pattern of `validate-change-yaml.sh` from F.2) that:

1. Iterates over every `.forge/standards/*.yaml` (excluding `index.yml`).
2. Validates each against a JSON Schema **Draft 2020-12** at
   `.forge/schemas/standard.schema.json` covering the 8 frontmatter fields.
3. Cross-checks the lifecycle invariants:
   - `expires_at: never` ⇒ `exception_constitutional: true`.
   - Otherwise `expires_at` is a valid ISO-8601 date strictly greater than
     `last_reviewed`.
4. Cross-checks the `linter_rule:` field against the rule registry in
   `constitution-linter.sh` (grep on the section anchors).
5. Cross-checks the declared `version` against the latest matching
   `Reviewed` / `Updated` entry in `.forge/standards/REVIEW.md`.
6. Wires into `verify.sh` as a new section "Standards YAML Schema" (placed
   immediately after the F.2 "Change YAML Schema" section for symmetry).
7. Emits a deterministic line format `[STD-PASS] <file>` /
   `[STD-FAIL: <file>:<field>: <reason>]` so CI greps remain stable.

A new harness `j7.test.sh` ships with **≥ 15 L1 + 3 L2** fixture tests
(mirroring f2 / t4 conventions). New consolidated spec
`.forge/specs/standards-yaml-validation.md` consolidates the FRs.

## Scope In

- `bin/validate-standards-yaml.sh` — the linter (bash thin + Python 3 inline,
  no `jsonschema` lib required).
- `.forge/schemas/standard.schema.json` — Draft 2020-12 schema.
- `verify.sh` integration — new "Standards YAML Schema" section iterating
  over `.forge/standards/*.yaml`.
- `.forge/scripts/tests/j7.test.sh` — harness with ≥ 15 L1 + 3 L2 fixture
  tests (good-YAML positive cases + bad-YAML negative cases per failure
  mode).
- CI registration in `.github/workflows/forge-ci.yml` — register
  `j7.test.sh` in the `harness` job matrix.
- New consolidated spec `.forge/specs/standards-yaml-validation.md` with
  `FR-J7-*` + `NFR-J7-*`.
- Documentation update : extend `docs/SCHEMA.md` with the standards section
  and cross-reference from `.forge/standards/global/standards-lifecycle.md`
  to the new linter.
- `CHANGELOG.md` entry under `## [Unreleased]`.

## Scope Out (Explicit Exclusions)

- **NOT** modifying any of the six existing standards YAML files (the
  linter is read-only ; six existing standards already conform to the
  contract by construction so the linter starts GREEN).
- **NOT** introducing a new standard format or any breaking change to the
  existing frontmatter contract.
- **NOT** tackling **J.8** (Janus orchestrator forbidden-list rules) —
  separate change, picked up next.
- **NOT** auto-fixing violations — linter is **report-only** (Article V
  gate semantics : block, do not mutate).
- **NOT** validating standard *body* content (only frontmatter + lifecycle
  cross-references).
- **NOT** wiring into pre-commit hooks (G.2 carry-over, future change).
- **NOT** validating `.forge/standards/global/*.md` files — they don't
  carry the YAML frontmatter contract.

## Impact

- **Users affected** : Forge maintainers + downstream adopters who add or
  edit standards. **No runtime impact** on adopter projects.
- **Technical impact** : 3 new files (linter, schema, harness) + 2 edits
  (`verify.sh`, `forge-ci.yml`) + 1 new spec + 1 doc extension.
  Complexity **S** (mirrors F.2 pattern almost verbatim).
- **Dependencies** :
  - T4 (six standards already shipped) ✅.
  - T5 (`transport.yaml` 1.1.0 already in tree) ✅.
  - F.2 schema infrastructure (PyYAML date coercion + Python 3 inline
    pattern) ✅ — pure reuse.
  - No new external dependencies.
- **Risk level** : **Low** — purely additive, validation is read-only,
  six existing standards already conform by construction so the harness
  starts GREEN. Worst case if a regression sneaks in : `verify.sh` fails
  loudly with a deterministic error reference and the exception path is
  trivial (set the schema field, ship a fix-up commit).

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 writes `j7.test.sh` with ≥ 15
L1 + 3 L2 stubs returning `_not_implemented` (full RED witness captured
to `/tmp/j7-red.log`). Phase 2 implements linter sections one at a time,
each preceded by a RED witness on the affected test cluster. Same cadence
as `f2-yaml-schema` and `t5-connect-codegen`.

### Article II — BDD

Not user-facing ; no BDD scenarios required. Linter behavior is captured
via L2 fixture tests : a `good/` directory with valid standards passes,
a `bad/` directory with one failure mode per file (missing field, bad
SemVer, bad date, broken `expires_at` coupling, broken `linter_rule`
back-reference, `version` / REVIEW.md drift) fails with the exact
deterministic message shape.

### Article III — Specs Before Code

Confirmed : `/forge:specify` will write `specs.md` before `/forge:design`
and any implementation. No code written ahead of the spec.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Two open questions captured below ; both will be resolved before the
change leaves `proposed`.

### Article V — Audit Trail

Each task tagged `[Story: FR-J7-XXX]` per Article V.1. Linter failure
messages reference the schema field path, not free-form text, so
downstream gates can be machine-parsed.

### Article VII — Rust Architecture

N/A — bash + Python 3 inline only ; no Rust code touched.

### Article X — Quality Gates

The linter itself **is** a quality gate ; it raises the
constitution-linter coverage from ~85 % (post-F.4) toward ~90 % by
transferring lifecycle invariants from human-review-only to automated
enforcement. No regression on existing gates : J.7 only adds a section
to `verify.sh`, never removes or weakens one.

### Article XII — Governance

The schema *enforces* `standards-lifecycle.md` invariants but does
**not amend** the standard. No constitutional amendment is needed.
The change shifts **how** the standard is checked, not **what** it
requires.

## Open Questions

[NEEDS CLARIFICATION: Should the linter additionally validate that
`index.yml` triggers reference standards that actually exist on disk
(no orphan triggers, no missing standards) ? — Lean YES, defer to
design phase ; one-line yq lookup, low cost, closes a real gap.]

[NEEDS CLARIFICATION: Tolerance window for the
`expires_at > last_reviewed + ~12 months` invariant — exact 12 months
mandated, or `± 30 days` permitted to avoid noisy renewals on the
boundary day ? — Defer to design phase ; preference for **strict
12 months** with explicit `expires_at: never` opt-out for structural
exceptions.]
