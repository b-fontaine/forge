# Specs: f2-yaml-schema

**Namespace** : `FR-YS-*` / `NFR-YS-*` (nouveau, sera consolidé dans
`.forge/specs/change-yaml-schema.md` à l'archive).

**Constitution** : v1.1.0 (pas d'amendement).

**Décisions** : pure shell + Python inline (Q-001), strict timeline
(a+c) (Q-002), shape-only b1-workflow (Q-003).

---

## ADDED Requirements

### Cluster 1 — Schema file

#### FR-YS-001 — `change.schema.json` exists

`.forge/schemas/change.schema.json` MUST exister, format JSON Schema
Draft 2020-12.

Le schema MUST déclarer :
- `$schema: "https://json-schema.org/draft/2020-12/schema"`
- `$id` ou `title` identifiant `Forge change .forge.yaml`
- `type: object`
- `required: [name, status, created, schema, constitution_version]`
- `additionalProperties: false`

**Test L1** : `[[ -f change.schema.json ]]` + parsing JSON valide + grep des keys.

#### FR-YS-002 — Field `name` pattern

Le schema MUST déclarer `name` comme `type: string` avec
`pattern: "^[a-z][a-z0-9.-]*$"` (slug Forge typique : démarre par
lettre minuscule, accepte chiffres, points, tirets ; pas de
underscore ni majuscule).

#### FR-YS-003 — Field `status` enum

Le schema MUST déclarer `status` comme `type: string` avec
`enum: [proposed, specified, designed, planned, implemented, archived]`.
Pas d'autre valeur acceptée.

#### FR-YS-004 — Field `created` ISO date

Le schema MUST déclarer `created` comme `type: string` avec
`pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"` (format ISO 8601 simple,
pas de timestamp).

#### FR-YS-005 — Field `schema` enum dynamique

Le schema MUST déclarer `schema` comme `type: string`. La liste des
valeurs valides est l'ensemble des sous-répertoires de
`.forge/schemas/` qui contiennent un `schema.yaml`.

À l'écriture (T+0), la liste est : `default, full-stack-monorepo,
mobile-only, ai-first, rapid, tdd-flutter, tdd-rust`.

**Approche** : le schema JSON contient un `enum` statique avec ces
valeurs, mis à jour manuellement quand un nouvel archetype est
ajouté. Le harness `f2.test.sh` test L1 vérifie que la liste enum
correspond aux sous-répertoires `.forge/schemas/*/schema.yaml`
existants — détecte la dérive.

**Test L1** : grep enum dans schema.json + cross-check avec
`find .forge/schemas -name schema.yaml -exec dirname {} \;`.

#### FR-YS-006 — Field `constitution_version` semver

Le schema MUST déclarer `constitution_version` comme `type: string`
avec `pattern: "^[0-9]+\\.[0-9]+\\.[0-9]+$"`.

---

### Cluster 2 — Timeline coherence

#### FR-YS-007 — `timeline` shape

Le schema MUST déclarer `timeline` comme `type: object` (optional au
top-level — un change `proposed` peut omettre `timeline` entièrement,
même si en pratique il est créé immédiatement).

Sub-keys autorisées : `proposed`, `specified`, `designed`, `planned`,
`implemented`, `archived`. Chaque sous-clé MUST avoir le même pattern
ISO 8601 que `created` (FR-YS-004).

#### FR-YS-008 — Strict timeline coherence (Q-002 a)

Le validateur MUST FAIL si :
- `status: specified` ET `timeline.specified` absent.
- `status: designed` ET `timeline.designed` absent.
- `status: planned` ET `timeline.planned` absent.
- `status: implemented` ET `timeline.implemented` absent.
- `status: archived` ET `timeline.archived` absent.

Cette règle ne peut PAS être exprimée en JSON Schema pure (pas de
conditional `if/then/else` simple sur l'absence de clé). Elle est
implémentée dans le **script `validate-change-yaml.sh`** comme étape
post-schema (Python inline).

#### FR-YS-009 — Strict archive coherence (Q-002 c)

Le validateur MUST FAIL si `status: archived` ET au moins une des
phases précédentes (`proposed`, `specified`, `designed`, `planned`,
`implemented`) manque dans `timeline`.

Implémentée dans le script post-schema.

#### FR-YS-010 — Date order non enforced (Q-002 b)

Le validateur NE DOIT PAS fail sur l'ordre des dates dans `timeline`
(p. ex. `proposed: 2026-04-30` puis `archived: 2026-04-29`). Cohérent
avec décision Q-002 — un mainteneur peut corriger une date après coup.

---

### Cluster 3 — b1-workflow extras (shape only)

#### FR-YS-011 — `layers` field shape

Si présent, `layers` MUST être `type: array` d'`items: { type: object }`
avec keys `id` (string) et `path` (string) requises.

#### FR-YS-012 — `designs_per_layer` / `tasks_per_layer` shape

Si présents, MUST être `type: object` avec `additionalProperties:
{ type: string }` (map<layer-id, filename>).

**Note** : la validation cross-layer (`designs_per_layer` keys ⊆
`layers.id`) n'est PAS scope F.2 (Q-003 c). Elle reste dans
`b1-workflow`'s `validate-foundations.sh`.

---

### Cluster 4 — Validator script

#### FR-YS-013 — `validate-change-yaml.sh` exists

`.forge/scripts/validate-change-yaml.sh` MUST exister, executable.

Signature : `bash validate-change-yaml.sh <path-to-.forge.yaml>`.
Exit codes :
- `0` : valide
- `1` : invalide (cause détaillée sur stderr)
- `2` : erreur d'usage (mauvais args, fichier introuvable)

#### FR-YS-014 — Validation engine

Implémentation : Python 3 inline (pattern existant `python3 - <<PY`).
Étapes :
1. Parse YAML via PyYAML.
2. Apply JSON Schema `change.schema.json` via vérifications manuelles
   (require, type, enum, pattern) — **pas de `jsonschema` library**
   (Q-001).
3. Apply post-schema rules : timeline coherence (FR-YS-008,
   FR-YS-009).
4. Output FAIL avec message clair sur stderr ; exit 1.

#### FR-YS-015 — Error message format

FAIL message format :
- `validate-change-yaml: <path>: <field>: <reason>` (1 ligne par erreur)
- Émis sur stderr.
- Exit 1 même si plusieurs erreurs (toutes émises).

---

### Cluster 5 — verify.sh integration

#### FR-YS-016 — Section "Change YAML Schema"

`.forge/scripts/verify.sh` MUST inclure une nouvelle section
`── Change YAML Schema ──` qui itère sur
`.forge/changes/*/.forge.yaml`, invoque `validate-change-yaml.sh`
sur chacun, et émet `pass` ou `fail` agrégé.

Skip-guard `examples/` honored (FR-GL-026).

#### FR-YS-017 — Backward compatibility

Les **11 changes archivés existants** MUST passer la validation post-F.2.
Si un fail est détecté, F.2 MUST :
1. Identifier la cause (schema trop strict OU change.yaml vraiment
   invalide).
2. Si schema trop strict → assouplir.
3. Si change.yaml invalide → ouvrir une question dans
   `open-questions.md` du change F.2 et corriger le change-amendment
   dans le scope F.2 (ou via change-amendment dédié post-F.2).

**Test L2** : valider chaque `.forge/changes/*/.forge.yaml` existant ;
zéro fail. NFR-YS-001.

---

### Cluster 6 — Standard

#### FR-YS-018 — `change-yaml-schema.md` standard

`.forge/standards/global/change-yaml-schema.md` MUST exister avec
≥ 5 sections H2 (Purpose, Schema Reference, Required Fields,
Timeline Coherence Rules, Extending the Schema).

Le standard documente :
- Comment lire `change.schema.json`.
- Pourquoi shape-only (vs cross-layer).
- Comment ajouter un nouvel archetype au enum `schema`.
- Comment ajouter un nouveau status (process amendment requis ;
  Article XII).

#### FR-YS-019 — Index entry

`.forge/standards/index.yml` MUST registrer
`global/change-yaml-schema` avec triggers `change.yaml,
.forge.yaml, schema validation, JSON Schema, status enum,
timeline coherence`.

---

### Cluster 7 — Documentation

#### FR-YS-020 — Docs reference

`docs/GUIDE.md` (existant) ou nouveau `docs/SCHEMA.md` MUST contenir
une section "Change YAML Schema" de ≥ 25 lignes documentant le
schema + comment debugger un FAIL.

---

### Cluster 8 — Harness

#### FR-YS-021 — Harness `f2.test.sh`

`.forge/scripts/tests/f2.test.sh` MUST :
- Pattern manifest, ≥ 12 tests L1 + ≥ 5 tests L2.
- Tests L1 : présence schema.json, parsing valide, presence required
  enum values, presence script validateur, executable, presence
  standard, index entry.
- Tests L2 fixture-based :
  - `_test_f2_l2_001` : `.forge.yaml` valide → exit 0.
  - `_test_f2_l2_002` : `name` invalide (uppercase) → exit 1.
  - `_test_f2_l2_003` : `status` hors enum → exit 1.
  - `_test_f2_l2_004` : `archived` sans `timeline.archived` → exit 1.
  - `_test_f2_l2_005` : tous les changes archivés existants passent
    (NFR-YS-001).
- Enregistré dans `.github/workflows/forge-ci.yml` job `harness`.

---

### Cluster 9 — Périmètre négatif

#### FR-YS-022 — No prohibited touch

F.2 NE DOIT PAS modifier :
- `cli/src/**` (zéro édition TS).
- `.forge/constitution.md` (pas d'amendement).
- Les changes archivés (immuables).
- Les schémas d'archetypes (`.forge/schemas/*/schema.yaml`) — F.2
  ajoute un schema NOUVEAU au même niveau, ne touche pas les existants.

---

## Non-Functional Requirements

### NFR-YS-001 — Backward compatibility hard

Les 11 changes archivés existants (b1-foundations, b1-scaffolder,
b1-workflow, b1-delivery, g1-forge-ci, c1-reference-project,
a7-forge-upgrade, b5-1-init-wizard, d5-governance, b4-mobile-only,
f1-open-questions) DOIVENT tous passer `validate-change-yaml.sh`
post-implementation. Vérifié par test L2 dédié.

### NFR-YS-002 — Performance

`validate-change-yaml.sh` sur un seul fichier MUST exécuter en ≤ **150ms**
(MacBook M-series référence). Verify.sh aggregate sur 12 changes
≤ **2 secondes** total. Mesuré via `time`.

### NFR-YS-003 — No new dep

Pas de `pip install jsonschema` ni nouvelle dep système. PyYAML déjà
disponible (utilisé par verify.sh existant).

### NFR-YS-004 — 100 % FR coverage

Chaque FR-YS-NNN MUST avoir ≥ 1 test L1 ou L2 dans `f2.test.sh`.

---

## Acceptance Criteria (BDD)

### Scénario 1 — Validation OK

```gherkin
Given a `.forge.yaml` with all required fields and coherent timeline
When the maintainer runs `bash validate-change-yaml.sh path/to/.forge.yaml`
Then the script exits with code 0
And no output is emitted on stderr
```

### Scénario 2 — Status hors enum

```gherkin
Given a `.forge.yaml` with `status: closed` (typo for `archived`)
When the maintainer runs the validator
Then the script exits with code 1
And stderr contains "status: 'closed' not in enum [proposed, specified, designed, planned, implemented, archived]"
```

### Scénario 3 — Archived sans timeline.archived

```gherkin
Given a `.forge.yaml` with `status: archived` but no `timeline.archived`
When the maintainer runs the validator
Then the script exits with code 1
And stderr contains "timeline.archived: missing while status is 'archived'"
```

### Scénario 4 — verify.sh integration

```gherkin
Given the project has 12 changes (11 archived + 1 in flight)
When the maintainer runs `bash .forge/scripts/verify.sh`
Then the section "Change YAML Schema" emits 12 PASS lines
And the global RESULT is PASS
```

### Scénario 5 — Date format invalide

```gherkin
Given a `.forge.yaml` with `created: 2026-4-30` (not zero-padded)
When the maintainer runs the validator
Then the script exits with code 1
And stderr contains "created: pattern mismatch (expected YYYY-MM-DD)"
```

---

## Anti-Hallucination Pass

| FR | Testable ? | Ambigu ? | Conforme Constitution ? |
|---|---|---|---|
| FR-YS-001..006 (schema fields) | ✅ JSON parse + grep | ❌ | ✅ |
| FR-YS-007..010 (timeline coherence) | ✅ L2 fixture | ❌ | ✅ Article V |
| FR-YS-011..012 (b1-workflow extras) | ✅ schema validation | ❌ | ✅ Article IV |
| FR-YS-013..015 (validator script) | ✅ exit codes + stderr | ❌ | ✅ |
| FR-YS-016..017 (verify.sh integration) | ✅ L2 + rétrocompat audit | ❌ | ✅ Article V |
| FR-YS-018..019 (standard + index) | ✅ presence + grep | ❌ | ✅ |
| FR-YS-020 (docs) | ✅ presence | ❌ | ✅ |
| FR-YS-021 (harness) | ✅ presence + manifest | ❌ | ✅ Article I |
| FR-YS-022 (negative scope) | ✅ git diff | ❌ | ✅ |

**Aucun `[NEEDS CLARIFICATION:]` restant.** 3 questions Q-001..003
résolues dans `open-questions.md`.

---

## Constitution Compliance Summary

- **Article I (TDD)** : `f2.test.sh` RED→GREEN. ✅
- **Article II (BDD)** : 5 scénarios documentés. ✅
- **Article III (Specs Before Code)** : pipeline complet. ✅
- **Article III.4 (Anti-hallucination)** : 3 questions trackées + résolues via F.1 mécanique (dogfooding). ✅
- **Article IV (Delta-based)** : ADDED-only namespace. ✅
- **Article V (Process Gates)** : nouveau gate verify.sh "Change YAML Schema". ✅
- **Article VI / VII / VIII / IX / XI** : NA. ✅
- **Article X (Quality)** : NFR-YS-002 (perf) + NFR-YS-001 (backward compat) garantissent qualité structurelle. ✅
- **Article XII (Governance)** : `constitution_version: "1.1.0"`. ✅

---

**Status** : `specified`. Next : `/forge:design f2-yaml-schema`.
