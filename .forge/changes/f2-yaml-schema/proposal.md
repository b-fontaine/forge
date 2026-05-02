# Proposal: f2-yaml-schema

## Problem

Le fichier `.forge/changes/<name>/.forge.yaml` est un **contrat structurel**
de chaque change : il déclare le name, le status, le schema applicable, la
constitution_version et la timeline des phases. Mais aujourd'hui :

1. **Aucun schéma formel** ne décrit ce contrat. La forme attendue est
   décrite informellement dans `.forge/templates/change.yaml` (un example
   commenté) et apprise par mimétisme.
2. **Aucune validation systématique** : `verify.sh` lit certains champs
   ad hoc dans plusieurs sections (`grep -E '^status:'` etc.) mais ne
   vérifie pas que :
   - `name` matche un pattern (regex `[a-z][a-z0-9-]+` typiquement)
   - `status` est dans l'enum {proposed, specified, designed, planned, implemented, archived}
   - `created` est une date ISO 8601 valide
   - `schema` est dans l'enum des schémas connus (default, full-stack-monorepo, mobile-only, ai-first, rapid, tdd-flutter, tdd-rust)
   - `constitution_version` matche `^[0-9]+\.[0-9]+\.[0-9]+$`
   - `timeline.<phase>` est cohérent avec `status` (e.g. `archived`
     implique que `timeline.archived` est présent)
   - Les fichiers correspondants existent (`specs.md` doit exister
     si `status >= specified`)
3. **Risque concret** : un mainteneur tape `status: closed` (pas dans
   l'enum) ou `status: implemented` mais oublie le `timeline.implemented`.
   Aucune mécanique ne le détecte ; le change passe les gates avec un
   métadonnées incohérent.
4. **Module F.2** sur le plan d'audit (T3 robustesse).

## Solution

Livrer un **schéma JSON formel** décrivant `.forge.yaml` per-change
+ **validation dans verify.sh** + **règle dans constitution-linter.sh**.

### Composants livrés

1. **Schéma JSON Schema (Draft 2020-12)** à
   `.forge/schemas/change.schema.json` décrivant :
   - Required : `name`, `status`, `created`, `schema`, `constitution_version`
   - `name` : pattern `^[a-z][a-z0-9.-]*$` (slug Forge typique)
   - `status` : enum strict
   - `created` : pattern ISO 8601 `^\d{4}-\d{2}-\d{2}$`
   - `schema` : enum dynamique (lit `.forge/schemas/*/schema.yaml`)
   - `constitution_version` : pattern semver
   - `timeline` : object avec sous-clés conditionnelles (chacune même
     pattern de date)
   - `layers / designs_per_layer / tasks_per_layer` : optional, b1-workflow
     extension shape-only
2. **Validateur shell** dans `.forge/scripts/validate-change-yaml.sh`
   (réutilisable depuis verify.sh + agents) : prend un chemin de
   `.forge.yaml` en argument, retourne 0 si valide, ≠ 0 sinon avec
   message stderr.
3. **Section verify.sh** "Change YAML Schema" : pour chaque
   `.forge/changes/*/.forge.yaml`, invoque le validateur. Émet
   PASS/FAIL.
4. **Règle conditionnelle de cohérence timeline** : si `status: archived`,
   `timeline.archived` MUST exister. Idem implemented, planned, etc.
5. **Tests Python** ou shell L2 fixture-based sur des `.forge.yaml`
   valides + invalides.
6. **Update**`.forge/templates/change.yaml` (template) avec un
   commentaire pointant vers le schema.
7. **Standard `.forge/standards/global/change-yaml-schema.md`** documentant
   le schéma + comment l'étendre.
8. **Harness `f2.test.sh`** (manifest pattern, ≥ 12 tests L1 + ≥ 5 L2 fixtures).
9. **CI registration** dans `forge-ci.yml`.
10. **Doc** : section dans `docs/GUIDE.md` ou nouveau `docs/SCHEMA.md`.

### Validation strategy

- Si Python `jsonschema` n'est pas disponible (pas de pip install
  systématique en CI Forge core), **fallback** sur python3 inline avec
  validation manuelle (pattern matching + enum check). Décision Q-001
  ouverte.
- Le validateur retourne FAIL spécifique : `FAIL <change>:.forge.yaml: <reason>`.

## Scope In

- Schema JSON formel à `.forge/schemas/change.schema.json`
- Script `.forge/scripts/validate-change-yaml.sh`
- Section dans `verify.sh` "Change YAML Schema"
- Standard `global/change-yaml-schema.md` + index entry
- Harness `f2.test.sh`
- CI registration
- Documentation
- Update `.forge/templates/change.yaml` (commentaire pointant le schema)

## Scope Out (Explicit Exclusions)

- **Validation des autres `.forge.yaml`** (root du projet) — F.2 cible
  les changes seulement. Le root `.forge.yaml` (déclaration archetype)
  est validé séparément par les schemas existants
  `.forge/schemas/<archetype>/schema.yaml` qui n'ont pas le même
  contrat.
- **Migration des changes archivés** — pas de "fix-up" rétrospectif
  des `.forge.yaml` existants. F.2 valide ; si un change archivé fail
  la validation, c'est un bug à corriger via un nouveau change-amendment
  (et tracé dans `open-questions.md` du change F.2 si découvert).
- **Cross-layer semantic validation** — `b1-workflow` valide déjà la
  cohérence `designs_per_layer ⊆ layers`. F.2 fait shape only.
- **Validation dynamique runtime** — F.2 valide à `verify.sh`
  invocation, pas en runtime CLI lors d'un `/forge:propose`.
- **TypeScript types pour `cli/`** — pas de génération de types TS
  depuis le schema (cohérent avec discipline B.5.1 ABI : zéro touch
  `cli/src/`).
- **Schema for `open-questions.md`** — F.1 livre la convention en
  Markdown ; pas de schema JSON pour cette structure.
- **`jsonschema` package install** — décision Q-001 (pure
  shell+python par défaut).

## Impact

- **Users affected** :
  - Mainteneurs Forge — gain : détection précoce des typos /
    incohérences `status` / `timeline`.
  - Adopters Forge — la même validation s'applique à leurs changes.
  - Agents (Claude, etc.) — schéma référence pour générer des
    `.forge.yaml` conformes.
- **Technical impact** :
  - 1 schema JSON, 1 script bash + python inline, 1 standard, 1
    harness, 1 entrée index.yml.
  - Aucune dépendance Python nouvelle (par défaut, Q-001 ouverte).
  - Pas de touch `cli/`.
  - Pas d'amendement Constitution.
- **Dependencies** :
  - **F.1** ✅ livré — F.2 hérite du pattern open-questions
    (déjà ouvert ci-dessus).
  - Aucune autre dépendance.

## Constitution Compliance

- **Article I (TDD)** : harness `f2.test.sh` RED→GREEN. Tests L1
  (présence + grep) + L2 (fixtures de `.forge.yaml` valides/invalides).
- **Article II (BDD)** : 4-5 scénarios documentaires (validation valide,
  validation invalide, intégration verify.sh, message d'erreur).
- **Article III (Specs Before Code)** : pipeline complet.
- **Article III.4 (Anti-hallucination)** : 3 questions ouvertes
  trackées dans `open-questions.md` (Q-001..Q-003) — F.1 mécanique
  appliquée à F.2 elle-même (premier change post-F.1, dogfooding).
- **Article IV (Delta-based)** : ADDED-only namespace `FR-YS-*`.
- **Article V (Process Gates)** : F.2 ajoute 1 nouveau gate (verify.sh
  "Change YAML Schema").
- **Article VI / VII / VIII / IX / XI** : NA.
- **Article X (Quality)** : NFR perf (validation ≤ 200ms) +
  rétrocompat (les 11 changes archivés doivent passer la validation).
- **Article XII (Governance)** : `constitution_version: "1.1.0"`.

---

## Validation rétrocompat

**Important** : avant d'ajouter le gate à verify.sh, F.2 MUST valider que les
**11 changes archivés existants** passent le schema. Si un fail est
détecté, deux options :
1. Le schema est trop strict → l'assouplir.
2. Le change archivé a une vraie erreur → la corriger via un
   change-amendment dédié (et noter le bug dans `open-questions.md`
   de F.2).

Le test L2 du harness inclut un test "all current archived changes
pass the schema" pour cadenasser ce niveau de qualité.

---

## Décisions ouvertes — résolues 2026-05-01

Conformément à F.1, les 3 questions ont été trackées dans
`open-questions.md` et résolues par décision utilisateur.

1. **Q-001 — Validation engine** → **pure shell + Python inline**
   (zéro nouvelle dep pip, cohérent avec `verify.sh` existant).
2. **Q-002 — Timeline coherence strict ?** → **strict (a + c)** :
   `timeline.<phase>` requis si `status >= phase`, toutes les phases
   peuplées si `archived`. Permissif sur (b) — pas d'enforcement
   d'ordre monotone des dates. Format `YYYY-MM-DD` IS enforced.
3. **Q-003 — b1-workflow multi-layer fields ?** → **(a) shape only**.
   F.2 valide la forme ; `b1-workflow` garde la sémantique cross-layer
   (validate-foundations.sh).
