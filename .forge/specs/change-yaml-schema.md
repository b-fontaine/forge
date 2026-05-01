# Spec: change-yaml-schema

<!-- Audit: F.2 (f2-yaml-schema) — formal schema for per-change .forge.yaml. -->
<!-- Source change : `.forge/changes/f2-yaml-schema/` (archived 2026-05-01). -->

**Namespace** : `FR-YS-*` / `NFR-YS-*`.

**Constitution** : v1.1.0. Pas d'amendement requis.

---

## Functional Requirements

### Cluster 1 — Schema fields

#### FR-YS-001 — `change.schema.json` exists

`.forge/schemas/change.schema.json` MUST exist as JSON Schema Draft 2020-12,
with `required: [name, status, created, schema, constitution_version]` and
`additionalProperties: false`.

#### FR-YS-002 — `name` pattern

Pattern `^[a-z][a-z0-9.-]*$`.

#### FR-YS-003 — `status` enum

Strict 6 values : `proposed | specified | designed | planned | implemented | archived`.

#### FR-YS-004 — `created` ISO 8601

Pattern `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`.

#### FR-YS-005 — `schema` enum dynamique

Static enum in JSON Schema, drift detector via harness compares enum to filesystem (`.forge/schemas/*/schema.yaml`). Currently includes : default, full-stack-monorepo, mobile-only, ai-first, rapid, tdd-flutter, tdd-rust.

#### FR-YS-006 — `constitution_version` semver

Pattern `^[0-9]+\.[0-9]+\.[0-9]+$`.

---

### Cluster 2 — Timeline coherence

#### FR-YS-007 — `timeline` object shape

Object avec sub-keys `proposed/specified/designed/planned/implemented/archived`, chacune string ISO date.

#### FR-YS-008 — Strict required (Q-002 a)

If `status >= phase`, `timeline.<phase>` MUST be present (specified onwards). Implémenté en Python post-schema.

#### FR-YS-009 — Strict archived (Q-002 c)

If `status: archived`, ALL six phases MUST be in timeline.

#### FR-YS-010 — Date order non enforced (Q-002 b)

Pas d'enforcement de monotonie des dates ; format `YYYY-MM-DD` IS enforced.

---

### Cluster 3 — b1-workflow extras (shape only)

#### FR-YS-011 — `layers` shape

Array d'objets `{id, path}`.

#### FR-YS-012 — `designs_per_layer` / `tasks_per_layer` shape

Object map<string, string>.

---

### Cluster 4 — Validator script

#### FR-YS-013 — `validate-change-yaml.sh` exists

`.forge/scripts/validate-change-yaml.sh` executable, signature `<path-to-.forge.yaml>`, exit 0/1/2.

#### FR-YS-014 — Validation engine

Python 3 inline (no `jsonschema` library). Phase 1 = schema validation (required, enum, pattern, type, additionalProperties). Phase 2 = timeline coherence rules (FR-YS-008, FR-YS-009). Date coercion (PyYAML date → string).

#### FR-YS-015 — Error format

`validate-change-yaml: <path>: <field>: <reason>` 1 ligne par erreur, stderr, accumule toutes avant exit 1.

---

### Cluster 5 — verify.sh integration

#### FR-YS-016 — Section "Change YAML Schema"

Section dédiée dans `verify.sh` qui itère sur `.forge/changes/*/.forge.yaml`, invoque le validator, agrège PASS/FAIL. Skip-guard `examples/` honored.

#### FR-YS-017 — Backward compatibility (NFR-YS-001 audit)

Les 11 changes archivés pré-F.2 MUST passer la validation. Audit avant gate (ADR-007). Schema accommodates historical extended fields : `parent_audit_items`, `depends_on`, `archived_to`, `schema_promotion`, `promotes_schema`.

---

### Cluster 6 — Standard

#### FR-YS-018 — `change-yaml-schema.md` standard

`.forge/standards/global/change-yaml-schema.md` avec ≥ 5 H2 sections (Purpose, Schema Reference, Required Fields, Timeline Coherence Rules, Extending the Schema).

#### FR-YS-019 — Index entry

`global/change-yaml-schema` enregistré dans `index.yml`.

---

### Cluster 7 — Documentation

#### FR-YS-020 — Docs

`docs/SCHEMA.md` documente le schema + erreurs courantes + comment étendre l'enum.

---

### Cluster 8 — Harness

#### FR-YS-021 — `f2.test.sh`

Pattern manifest, ≥ 12 L1 + ≥ 5 L2 fixture-based. Enregistré dans CI.

---

### Cluster 9 — Périmètre négatif

#### FR-YS-022 — No prohibited touch

Pas de `cli/src/`, pas d'amendement Constitution, pas de modification des changes archivés ou des schémas d'archetypes existants.

---

## Non-Functional Requirements

### NFR-YS-001 — Backward compat hard

11 changes archivés pré-F.2 passent. Vérifié par test L2 dédié.

### NFR-YS-002 — Performance

≤ 150ms par fichier, ≤ 2s aggregate.

### NFR-YS-003 — No new dep

PyYAML déjà disponible. Pas de `jsonschema` install.

### NFR-YS-004 — 100 % FR coverage

Chaque FR-YS-* couvert par ≥ 1 test L1/L2.

---

## Acceptance Criteria (BDD)

5 scénarios documentés dans `.forge/changes/f2-yaml-schema/specs.md` :

1. Validation OK (valid yaml → exit 0)
2. Status hors enum → exit 1 + stderr
3. Archived sans timeline.archived → exit 1
4. verify.sh integration → 12 PASS lines
5. Date format invalide → exit 1

---

## Constitution Compliance Summary

- **Article I (TDD)** : `f2.test.sh` 18 tests RED→GREEN. ✅
- **Article II (BDD)** : 5 scénarios. ✅
- **Article III (Specs Before Code)** : pipeline complet. ✅
- **Article III.4 (Anti-hallucination)** : 3 questions résolues via F.1 mécanique. ✅
- **Article IV (Delta-based)** : ADDED-only namespace. ✅
- **Article V (Process Gates)** : nouveau gate verify.sh "Change YAML Schema". ✅
- **Articles VI/VII/VIII/IX/XI** : NA. ✅
- **Article X (Quality)** : NFR perf + backward compat. ✅
- **Article XII (Governance)** : `constitution_version: "1.1.0"`. ✅
