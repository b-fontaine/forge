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

## See also

- Standard : [`change-yaml-schema.md`](../.forge/standards/global/change-yaml-schema.md)
- Schema : [`change.schema.json`](../.forge/schemas/change.schema.json)
- Validator : [`.forge/scripts/validate-change-yaml.sh`](../.forge/scripts/validate-change-yaml.sh)
- Constitution : [Article XII Governance](../.forge/constitution.md)
