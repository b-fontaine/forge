# Change YAML Schema

<!-- Audit: F.2 (f2-yaml-schema, FR-YS-020) -->

This guide complements the standard
[`global/change-yaml-schema.md`](../.forge/standards/global/change-yaml-schema.md)
and covers practical workflow concerns — how to write a valid
`.forge.yaml`, how to debug a `verify.sh` schema FAIL, how to extend
the enum when a new archetype is added.

## Required shape

Every `.forge/changes/<name>/.forge.yaml` MUST declare these five
top-level fields :

```yaml
name: my-change         # slug ^[a-z][a-z0-9.-]*$
status: proposed        # one of: proposed, specified, designed, planned, implemented, archived
created: 2026-05-01     # YYYY-MM-DD
schema: default         # archetype enum
constitution_version: "1.1.0"  # semver string (quoted)
```

The `timeline` field is optional at `proposed`, but becomes
de-facto required as the change advances :

```yaml
timeline:
  proposed: 2026-05-01
  specified: 2026-05-02
  designed: 2026-05-03
  planned: 2026-05-04
  implemented: 2026-05-08
  archived: 2026-05-09
```

When `status: archived`, ALL six timeline phases MUST be populated.

## Validating manually

```bash
bash .forge/scripts/validate-change-yaml.sh \
  .forge/changes/my-change/.forge.yaml
```

Exit codes : `0` valid, `1` invalid (errors on stderr), `2` usage
error.

## Common errors

### `name: pattern mismatch`

Your slug uses uppercase, underscores, or starts with a digit. Fix :
rename the directory and the `name` field to match
`^[a-z][a-z0-9.-]*$`.

### `status: 'closed' not in enum`

You used a status not in the canonical six. Forge has no `closed`,
`done`, `wip`, or `wontfix` status — the enum is closed (no pun).
Use one of `proposed`, `specified`, `designed`, `planned`,
`implemented`, `archived`.

### `timeline.archived: missing while status is 'archived'`

You flipped the status to `archived` but forgot to add the timestamp.
Add `archived: YYYY-MM-DD` under `timeline:`.

### `created: pattern mismatch (expected /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)`

You wrote `2026-5-1` (not zero-padded) or used a different format
(`05/01/2026`, `Mai 1 2026`, etc.). Use `2026-05-01`.

### `<field>: unknown field (additionalProperties: false)`

You added a custom field not in the schema. Either :
- Remove it (if it's a typo).
- Move the metadata to a sibling file (`linkage.md`,
  `notes.md`).
- Discuss with the maintainers whether the field deserves to be
  added to the schema (Article XII amendment process).

## Adding a new archetype

When a new archetype lands in `.forge/schemas/<new-archetype>/schema.yaml` :

1. Bump `change.schema.json` : add the new value to the
   `properties.schema.enum` list.
2. Run `bash .forge/scripts/tests/f2.test.sh --level 1` — the drift
   detector test (`_test_f2_006`) confirms the enum now matches
   disk.
3. Commit the schema bump alongside the new archetype's templates.

## Adding a new status

Adding a status value (e.g. `frozen`, `superseded`) is a structural
change to the pipeline. It requires :

1. A Constitution amendment (Article XII Governance amendment
   process — public 7-day discussion, BDFL ratification).
2. Bumps to `change.schema.json` (`properties.status.enum`).
3. Updates to `.forge/templates/change.yaml`.
4. Skill updates (`/forge:propose`, `/forge:specify`, etc. may need
   to handle the new value).
5. Re-audit of all archived changes against the new schema (none
   should fail — the new value is additive).

## Standard YAML schema (J.7)

Symmetric to the Change YAML schema, the **Standard YAML schema**
governs the frontmatter contract of `.forge/standards/*.yaml` files
and the lifecycle invariants from
`.forge/standards/global/standards-lifecycle.md`.

### Required frontmatter

| Field                       | Type           | Constraint                                                              |
|-----------------------------|----------------|-------------------------------------------------------------------------|
| `version`                   | string         | SemVer pattern `^[0-9]+\.[0-9]+\.[0-9]+$`                               |
| `last_reviewed`             | string         | ISO 8601 date `YYYY-MM-DD`                                              |
| `expires_at`                | string         | ISO 8601 date OR the literal `never`                                    |
| `exception_constitutional`  | boolean        | `true` ⇔ `expires_at: never` (Article XII coupling)                     |
| `linter_rule`               | string \| null | When string : kebab-case `^[a-z][a-z0-9-]*$`                            |
| `enforcement`               | object         | Required sub-keys `ci_blocking` + `pre_commit_hook` (booleans)          |
| `forbidden`                 | array          | List of non-empty trimmed strings, no duplicates                        |
| `rationale`                 | string         | Non-empty (`minLength: 1`) ; multiline `|` block scalars valid          |

Body fields beyond the frontmatter are **allowed** (`additionalProperties: true`
at the root level) since each standard carries domain-specific content
(e.g. `transport.yaml::codegen`, `state-management.yaml::framework`).

### Lifecycle invariants

- **Article XII coupling** : `expires_at: never` ⇔ `exception_constitutional: true`.
- **Strict ordering** : `expires_at > last_reviewed` when both are dated.
- **REVIEW.md drift** : the declared `version` MUST appear in
  `.forge/standards/REVIEW.md` (full ledger scan, table-row regex).
- **`linter_rule` cross-reference** : when non-null, the rule name MUST
  appear as a section header (line starting `echo` or `#`) in
  `.forge/scripts/constitution-linter.sh`.
- **`index.yml` triggers** : every `path:` in
  `.forge/standards/index.yml` MUST resolve to an existing file under
  `.forge/<path>` or `<repo-root>/<path>`.

### Validating manually

```bash
bash bin/validate-standards-yaml.sh                           # default .forge/standards/
bash bin/validate-standards-yaml.sh <dir>                     # validate every *.yaml in <dir>
bash bin/validate-standards-yaml.sh .forge/standards/transport.yaml  # single file
```

Output line shapes :

```
[STD-PASS] <relative-path>                         # stdout, file conformant
[STD-FAIL: <path>:<field>: <reason>]               # stderr, blocking violation
[STD-INFO: <path>:<field>: <reason>]               # stdout, non-blocking signal
```

Exit codes : `0` (all PASS) / `1` (≥ 1 FAIL) / `2` (usage error).

### Common errors

| Error fragment                                    | Likely cause                                                                                            |
|---------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| `version: required field missing`                 | Frontmatter does not declare `version:` at the top level.                                               |
| `version: pattern mismatch`                       | `version` is not strict SemVer (`v1`, `1.0`, `1.0.0-rc.1` all rejected).                                |
| `last_reviewed: pattern mismatch`                 | Date is not `YYYY-MM-DD` (e.g. `2026/05/04`, `04-05-2026`).                                             |
| `Article XII`                                     | `expires_at: never` paired with `exception_constitutional: false` (or the reverse).                     |
| `must be strictly greater than last_reviewed`     | Dated `expires_at` is on or before `last_reviewed`.                                                     |
| `declared <V> not present in REVIEW.md ledger`    | The standard's `version:` was bumped without an `Updated` entry in `.forge/standards/REVIEW.md`.        |
| `rule "<r>" not found … in constitution-linter.sh`| `linter_rule:` references a rule that has no matching section header in the live linter.                |
| `dangling path '...' (file does not exist)`       | `index.yml` trigger path points to a missing standard file.                                             |
| `expected type boolean`                           | `enforcement.ci_blocking` / `pre_commit_hook` set to a non-boolean value (e.g. `"true"`, `1`, `"yes"`). |

### Adding a new standard YAML

1. Create the file under `.forge/standards/<name>.yaml` with all 8
   frontmatter fields conformant to the table above.
2. Append an entry to `.forge/standards/REVIEW.md` (initial
   ratification) — the full ledger scan needs at least one row
   matching `(<basename>, <version>)`.
3. Optional : register in `.forge/standards/index.yml` for JIT
   injection by triggers (FR-J7-051 emits `[STD-INFO]` orphans, but
   it does not block — the file is usable without index registration).
4. Run `bash bin/validate-standards-yaml.sh .forge/standards/<name>.yaml`
   — expect exit 0.

## See also

- Standard : [`change-yaml-schema.md`](../.forge/standards/global/change-yaml-schema.md)
- Schema (changes) : [`change.schema.json`](../.forge/schemas/change.schema.json)
- Schema (standards) : [`standard.schema.json`](../.forge/schemas/standard.schema.json)
- Validator (changes) : [`.forge/scripts/validate-change-yaml.sh`](../.forge/scripts/validate-change-yaml.sh)
- Validator (standards) : [`bin/validate-standards-yaml.sh`](../bin/validate-standards-yaml.sh)
- Lifecycle : [`global/standards-lifecycle.md`](../.forge/standards/global/standards-lifecycle.md)
- Constitution : [Article XII Governance](../.forge/constitution.md)
