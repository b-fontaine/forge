# Standard: Change YAML Schema

<!-- Audit: F.2 (f2-yaml-schema, FR-YS-018) -->

This standard governs the `.forge/changes/<name>/.forge.yaml` files
that declare per-change metadata. It defines :
- The required and optional fields.
- Allowed values for each field (enums, patterns).
- Coherence rules between `status` and `timeline` sub-keys.
- The validation tooling (`validate-change-yaml.sh`).

The schema lives at [`change.schema.json`](../../schemas/change.schema.json)
(JSON Schema Draft 2020-12). Indexed in
`.forge/standards/index.yml` with triggers `change.yaml`,
`.forge.yaml`, `schema validation`, `JSON Schema`, `status enum`,
`timeline coherence`.

---

## Purpose

Per-change metadata is the **structural contract** of every Forge
change. Before F.2, the file shape was learned by mimétisme from
`.forge/templates/change.yaml`. Typos like `status: closed` or a
forgotten `timeline.implemented` could silently slip through every
gate. F.2 mechanises validation : a JSON Schema describing the
contract + a validator script + a `verify.sh` gate.

---

## Schema Reference

The full schema is at `.forge/schemas/change.schema.json`. Top-level :

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | string | yes | Change slug. Pattern `^[a-z][a-z0-9.-]*$`. |
| `status` | string | yes | Pipeline phase. Enum (see below). |
| `created` | string | yes | ISO 8601 date `YYYY-MM-DD`. |
| `schema` | string | yes | Archetype enum (see below). |
| `constitution_version` | string | yes | Semver `^[0-9]+\.[0-9]+\.[0-9]+$`. |
| `timeline` | object | no | Per-phase timestamps. Coherence rules apply. |
| `layers` | array | no | b1-workflow extension (multi-layer changes). |
| `designs_per_layer` | object | no | b1-workflow extension. |
| `tasks_per_layer` | object | no | b1-workflow extension. |
| `parent_audit_items` | array | no | Historical extended field (b1-* / g1 / c1 / a7 / b5). |
| `depends_on` | array | no | Historical extended field. |
| `archived_to` | array | no | Historical extended field. |
| `schema_promotion` | object | no | Historical extended field (b1-scaffolder). |
| `promotes_schema` | object | no | Historical extended field (b1-delivery). |

---

## Required Fields

### `name`

Slug for the change. Used as the directory name under
`.forge/changes/<name>/`. Pattern :

- Starts with a lowercase letter `[a-z]`.
- Follows with lowercase letters, digits, dots, or hyphens
  `[a-z0-9.-]*`.
- No underscores, no uppercase, no spaces.

Examples :
- ✅ `b4-mobile-only`, `f1-open-questions`, `g1-forge-ci`
- ❌ `B4-mobile-only`, `b4_mobile_only`, `B.4 Mobile Only`

### `status`

Pipeline phase. Strict enum :

| Value | Meaning |
| --- | --- |
| `proposed` | After `/forge:propose`. Only `proposal.md` exists. |
| `specified` | After `/forge:specify`. `specs.md` exists. |
| `designed` | After `/forge:design`. `design.md` exists. |
| `planned` | After `/forge:plan`. `tasks.md` exists. |
| `implemented` | All tasks complete. Code shipped. |
| `archived` | After `/forge:archive`. Specs consolidated. |

Adding a new value requires a Constitution amendment per Article XII
(Governance) since it changes the pipeline contract.

### `created`

ISO 8601 date when the change was opened. Pattern
`^[0-9]{4}-[0-9]{2}-[0-9]{2}$`. The validator coerces YAML date
literals (unquoted `2026-04-30`) to strings before pattern check —
adopters do not need to quote dates.

### `schema`

Archetype this change targets. Strict enum :

`default | full-stack-monorepo | mobile-only | ai-first | rapid | tdd-flutter | tdd-rust`

The harness `f2.test.sh` includes a **drift detector** that compares
this enum to the actual sub-directories under `.forge/schemas/`.
When a new archetype is added, the schema enum MUST be bumped or the
test fails.

### `constitution_version`

The Constitution version under which the change was ratified.
Semver pattern `^[0-9]+\.[0-9]+\.[0-9]+$`. Per ADR-006 of
`d5-governance`, a change creating Constitution N+1 stays at version
N (no circular reference).

---

## Timeline Coherence Rules

The `timeline` object is optional at the top level (a fresh
`proposed` change may omit it), but its sub-keys are constrained by
the current `status` :

### Rule 1 — `status >= phase` requires `timeline.<phase>` (FR-YS-008)

If `status` is `specified`, `designed`, `planned`, `implemented`, or
`archived`, the corresponding `timeline.<phase>` MUST be present.

The exception is `proposed` — its timestamp lives in the top-level
`created` field and `timeline.proposed` is conventionally a duplicate
(strongly encouraged but not required by the rule).

### Rule 2 — `archived` requires the full timeline (FR-YS-009)

If `status: archived`, ALL of `timeline.proposed`,
`timeline.specified`, `timeline.designed`, `timeline.planned`,
`timeline.implemented`, `timeline.archived` MUST be present.
Archive is the audit trail seal — partial trails are not allowed.

### Rule 3 — Date order NOT enforced

Dates in `timeline` SHOULD be monotonically increasing (proposed ≤
specified ≤ ... ≤ archived) but this is NOT enforced. A maintainer
can manually correct a date out of order (typo fix). Decision Q-002
of f2-yaml-schema.

---

## Extending the Schema

Adding a new field, a new status value, or a new archetype to the
enum requires :

1. A Constitution amendment (Article XII §  Governance amendment
   process), if the change alters pipeline semantics.
2. A `change.schema.json` bump (additive change, optional fields are
   non-breaking ; required fields are breaking).
3. A re-run of the audit on all archived changes (NFR-YS-001) — if
   any fail, decide whether to assouplir the schema or refactor the
   archived data via a change-amendment.
4. An update to this standard.

Historical extended fields (`parent_audit_items`, `depends_on`,
`archived_to`, `schema_promotion`, `promotes_schema`) are included
as optional in the schema — they were used by early changes (b1-*,
g1, c1, a7, b5) before the schema was formalized. New changes
SHOULD NOT add these fields ; if the project needs more metadata,
prefer a separate file under the change directory (e.g.
`linkage.md`).

---

## Tooling

### `validate-change-yaml.sh`

Standalone script at `.forge/scripts/validate-change-yaml.sh`.

```bash
bash .forge/scripts/validate-change-yaml.sh path/to/.forge.yaml
```

Exit codes :
- `0` : valid.
- `1` : invalid (errors emitted on stderr, format
  `validate-change-yaml: <path>: <field>: <reason>`, one per line ;
  all errors emitted before exit).
- `2` : usage error (missing arg, file not found, schema not found).

Engine : Python 3 inline (`python3 - <<PY`) using stdlib + PyYAML.
No `jsonschema` library required.

### `verify.sh` integration

Section `── Change YAML Schema ──` in `.forge/scripts/verify.sh`
iterates over `.forge/changes/*/.forge.yaml`, invokes the validator
on each, and aggregates `pass` / `fail`. Skip-guard `examples/`
honored (FR-GL-026).
