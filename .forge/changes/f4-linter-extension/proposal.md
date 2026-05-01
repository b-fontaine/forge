# Proposal: f4-linter-extension

## Problem

Le `constitution-linter.sh` couvre aujourd'hui partiellement la Constitution :

| Article | Couverture actuelle |
| --- | --- |
| Article I (TDD) | ✅ partiel — vérifie présence de tests Flutter / Rust |
| Article II (BDD) | ✅ partiel — compte AC dans changes |
| Article III (Specs Before Code) | ✅ partiel — vérifie artifacts |
| Article III.4 (Anti-Hallucination) | ✅ ajouté par F.1 |
| Article IV (Delta Format) | ✅ vérifie format ADDED/MODIFIED/REMOVED |
| **Article V (Compliance Gate)** | ❌ **non couvert** |
| Article VI / VII (Flutter / Rust archi) | ✅ partiel |
| Article VIII (Infrastructure) | ✅ partiel |
| Article IX (Observability) | ✅ partiel |
| Article X.1 / X.2 (modules + boundaries) | ✅ partiel |
| **Article X.3 (Public API doc)** | ❌ **non couvert** |
| Article X.4 (No unresolved TODOs) | ✅ |
| Article X.5 (Static analysis) | ✅ |
| **Article XI.3 (GenUI schema-driven)** | ❌ **non couvert** |
| **Article XI.5 (Mandatory fallback TESTED)** | ⚠️ **partiel** — vérifie présence, pas test |

Conséquence : un projet peut passer le linter avec des violations
silencieuses des articles V, X.3, XI.3, XI.5. F.4 est l'**extension
ciblée** qui couvre ces 4 articles.

Module **F.4** sur le plan d'audit (T3 robustesse). Effort `L`
parce que 4 règles indépendantes, chacune avec ses heuristiques.

## Solution

Étendre `.forge/scripts/constitution-linter.sh` avec **4 nouvelles règles**
ciblées, chacune dans sa propre section :

### Règle 1 — Article V (Constitutional Compliance Gate)

Pour chaque change avec `status >= planned` :
- Vérifier que `tasks.md` existe (artifact gate already checked, mais
  on verrouille).
- Vérifier que `tasks.md` contient au minimum **1 référence
  `[Story: FR-`** (preuve que l'audit trail tasks ↔ FR existe).

Cette règle ne tente PAS d'imposer 1 FR par task (trop strict — les
tâches admin/commit/etc. n'ont pas toujours de FR). Elle vérifie
juste que la structure d'audit est en place.

### Règle 2 — Article X.3 (Public API Documentation)

Pour les sources Dart (`lib/**/*.dart`) :
- Compter les déclarations publiques (regex heuristique :
  `^class [A-Z]`, `^[A-Z][a-zA-Z]* [a-z][a-zA-Z]*\(`, etc.).
- Compter combien sont précédées d'un `///` doc comment.
- Émettre `pass` si ratio ≥ 80% ; `fail` sinon avec liste des
  premiers 5 manquants.

Pour les sources Rust (`src/**/*.rs`) :
- Compter `^pub fn`, `^pub struct`, `^pub enum`, `^pub trait`.
- Compter combien sont précédées d'un `///` doc comment.
- Même règle 80%.

**Skip-guard** : si aucun source dir Dart / Rust n'existe (cas du
framework repo lui-même), `not_applicable` au lieu de fail.

### Règle 3 — Article XI.3 (Generative UI schema-driven)

Heuristique — émet **warning** (pas fail) :
- Si des imports AI sont détectés (`anthropic|openai|gpt|claude|llm` dans
  les imports `.dart` / `.rs` / `package.json`) ET que des fichiers
  Widget / render sont présents → warning si aucun fichier
  `*.schema.json` n'est référencé dans le contexte AI.
- Si le schema `ai-first` est déclaré dans `.forge.yaml` racine du
  projet, la règle est **actives** (warning montant en fail si pas de
  schema JSON référencé).

**Limitation explicite** : XI.3 est fondamentalement dynamique, le
linter ne peut pas distinguer un widget AI-driven schema-validated
d'un widget AI-driven HTML-injection. Le warning pousse l'adopter à
auditer manuellement.

### Règle 4 — Article XI.5 (Mandatory Fallback TESTED)

Pour chaque fichier matchant `lib/**/*fallback*.dart` ou
`src/**/*fallback*.rs` (case-insensitive) :
- Chercher un test correspondant : `test/**/*fallback*_test*.dart`
  ou `tests/**/*fallback*.rs`.
- Émettre `fail` si fichier source de fallback existe sans test
  associé.

**Skip-guard** : si schema != `ai-first` ET aucun fichier `*fallback*`
n'existe → `not_applicable`.

### Règles métadonnées

- Chaque règle ajoute 1 section H2 dans `constitution-linter.sh`
  (cohérent avec le pattern existant `## Article X — ...`).
- Chaque règle peut être **désactivée** via env var
  (`FORGE_LINTER_SKIP_V_1`, `FORGE_LINTER_SKIP_X_3`, etc.) pour
  les adopteurs avec des contraintes spécifiques. Documenté dans le
  standard.

## Scope In

- 4 nouvelles règles dans `.forge/scripts/constitution-linter.sh` :
  Article V.1 (task ↔ FR linkage), Article X.3 (public API doc),
  Article XI.3 (GenUI schema warning), Article XI.5 (fallback test
  pair).
- Mécanisme d'opt-out par env var pour chaque règle.
- Update du standard `.forge/standards/global/forge-self-ci.md` (ou
  nouveau `linting-rules.md`) documentant les nouvelles règles +
  les opt-outs.
- Harness `f4.test.sh` (manifest pattern, ≥ 16 tests L1 + ≥ 6 L2
  fixtures couvrant chaque règle FAIL et PASS).
- CI registration dans `forge-ci.yml`.
- Documentation : section dans `docs/GUIDE.md` ou nouveau
  `docs/LINTING.md`.
- Update CHANGELOG, roadmap, plan d'audit.

## Scope Out (Explicit Exclusions)

- **Article V.2 / V.3 (violation handling at runtime)** — ne peut pas
  être checké statiquement. Documenté.
- **Migration des sources existantes** (framework repo n'a pas de
  Flutter / Rust source) — la règle X.3 retournera `not_applicable`.
  Pour les adopteurs qui activent F.4 sur leurs projets, documenter
  comment introduire progressivement (env var skip pendant la
  migration).
- **Détection AI parfaite** pour XI.3 — heuristique seulement (warning).
  Une vraie analyse AST nécessiterait un parser Dart/Rust complet
  (hors scope F.4).
- **Auto-fix** — F.4 détecte les violations, ne les corrige pas.
  Auto-fix possible en F.5+ via un nouveau outil dédié.
- **Validation cross-change** (e.g. "FR référencé dans tasks.md
  existe vraiment dans specs.md") — F.5+, beaucoup plus complexe.
- **Bumping Constitution** — F.4 ne touche pas la Constitution.
  Les règles existantes (Articles I-IV, VI-X.5) ne sont pas modifiées.

## Impact

- **Users affected** :
  - **Mainteneurs Forge** — gain : couverture Constitution
    augmentée de ~70% à ~85% (estimation basée sur le nombre
    d'articles avec règles).
  - **Adopters Forge** — détection plus fine des violations dans
    leurs projets ; opt-out par env var pour les cas particuliers.
- **Technical impact** :
  - 4 nouvelles sections dans `constitution-linter.sh` (~+150 lignes
    bash + python inline).
  - 1 nouveau standard ou extension d'existant.
  - 1 harness ~22 tests.
  - 1 doc.
  - Pas de modification `cli/`.
  - Pas d'amendement Constitution.
- **Dependencies** :
  - **F.1 + F.2** ✅ livrés — F.4 hérite des conventions
    open-questions et schema validation.
  - Pas de dépendance bloquante.

## Constitution Compliance

- **Article I (TDD)** : `f4.test.sh` RED→GREEN. L2 fixtures pour
  chaque règle (1 PASS + 1 FAIL fixture par règle).
- **Article II (BDD)** : 4-6 scénarios documentaires.
- **Article III (Specs Before Code)** : pipeline complet.
- **Article III.4 (Anti-hallucination)** : 4 questions trackées dans
  `open-questions.md` (Q-001..004).
- **Article IV (Delta-based)** : ADDED-only namespace `FR-LE-*`.
- **Article V (Process Gates)** : F.4 EST un renforcement de cet article.
- **Article VI / VII / VIII / IX / XI** : F.4 NE TOUCHE PAS le code
  applicatif Flutter/Rust/Infra/Observability/AI ; il vérifie via heuristique.
- **Article X (Quality)** : F.4 améliore la couverture du linter
  (X.3 + autres). NFR perf : `constitution-linter.sh` reste sous
  2 secondes total.
- **Article XII (Governance)** : `constitution_version: "1.1.0"`.

---

## Décisions ouvertes — résolues 2026-05-01

Conformément à F.1, les 4 questions ont été trackées dans
`open-questions.md` et résolues par décision utilisateur.

1. **Q-001 — V coverage** → `tasks.md` (status ≥ planned) MUST contenir
   ≥ 1 `[Story: FR-` (preuve audit trail, pas 1-par-task).
2. **Q-002 — X.3 strictness** → ratio threshold **80%** + skip si
   aucun source dir Dart/Rust détecté.
3. **Q-003 — XI.3 detection** → **warning** heuristique seulement
   (pas fail). Active si `schema=ai-first` OU AI imports détectés.
4. **Q-004 — XI.5 fallback testing** → **name-based pair**
   `*fallback*` ↔ `*fallback*_test*` ; FAIL si source sans test.
   Skip si `schema != ai-first` ET aucun fichier `*fallback*`.

Opt-out par env var pour chaque règle :
`FORGE_LINTER_SKIP_V_1`, `FORGE_LINTER_SKIP_X_3`,
`FORGE_LINTER_SKIP_XI_3`, `FORGE_LINTER_SKIP_XI_5`.
