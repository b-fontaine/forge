# Proposal: b1-foundations
<!-- Created: 2026-04-21 -->
<!-- Schema: default -->
<!-- Parent audit module: B.1 (full-stack-monorepo archetype) -->
<!-- Parent audit items: B.1.1, B.1.5, B.1.10, B.1.11 -->

## Problem

Forge positionne le `full-stack-monorepo` (Flutter + Rust + Infra) comme
l'archétype flagship de son Module B (roadmap Phase 2, v1.0 milestone).
Mais aucun contrat formel n'existe encore pour dire **ce que ce monorepo
doit contenir, comment il s'organise, quelles règles le gouvernent**. Sans
ce contrat :

- Le scaffolder `/forge:init --archetype full-stack-monorepo` (B.1.2) ne
  peut pas être écrit — il scaffolderait dans le vide.
- L'agent `Janus` (B.1.7) ne peut pas router les changes multi-couches —
  il ignore quelles couches existent et comment les nommer.
- Les adaptations multi-root de `verify.sh` et `constitution-linter.sh`
  (B.1.8) ne peuvent pas être spécifiées — aucune arborescence canonique
  n'est gravée.
- Les workflows CI avec `paths-filter` (B.1.9) ne peuvent pas référencer
  de chemins stables.

Sans B.1-foundations, **tous les items B.1.2 à B.1.14 sont bloqués**. Il
faut commencer par poser le contrat.

La Forge elle-même est aussi bloquée pour se positionner face aux
frameworks concurrents (audit §5) : sans schema + standards écrits, la
différenciation *"premium monorepo à l'état de l'art"* reste une
affirmation non vérifiable.

## Solution

Livrer les **fondations non exécutables** du `full-stack-monorepo` — des
fichiers Markdown + un YAML — que tous les items B.1 suivants consommeront
comme contrat :

1. **Schema Forge** (`B.1.1`) : `.forge/schemas/full-stack-monorepo/schema.yaml`
   déclare les phases, les gates par couche, la convention `layers:` dans
   `.forge.yaml` des changes, les exigences TDD/BDD par couche, l'agent
   orchestrateur (Janus, à livrer en `b1-workflow`).
2. **Trois nouveaux standards** (`B.1.5`) sous `.forge/standards/` :
    - `global/monorepo-layout.md` — arborescence canonique, CLAUDE.md
      imbriqués, interdictions (pas d'import croisé frontend/backend hors
      protos), préfixes FR-ID par couche (`FR-BE-`, `FR-FE-`, `FR-IN-`).
    - `global/proto-contracts.md` — protos comme source unique de vérité,
      versioning (`v1`, `v2`), règles `buf lint` + `buf breaking`, stratégie
      de deprecation.
    - `infra/docker-compose.md` — orchestration locale, healthchecks,
      réseaux nommés, variables d'env, conventions de service naming.
3. **Enrichissement de `global/git-workflow.md`** (`B.1.10`) : Conventional
   Commits **scopés** par couche (`feat(backend):`, `fix(frontend):`,
   `chore(infra):`, `feat(protos):`). Liste close des scopes.
4. **Stratégie de versioning** (`B.1.11`) : ajout d'une section dans
   `docs/VERSIONING.md` documentant les deux modèles (release-train unique
   vs per-package via `release-please`), leur domaine d'application, et
   la recommandation Forge par défaut (release-train pour équipes ≤ 15,
   per-package au-delà).
5. **Mise à jour de l'index des standards** (`.forge/standards/index.yml`)
   pour rendre les nouveaux standards chargeables avec les bons triggers
   (`scope: monorepo`, `scope: infra`, `scope: protos`).

Chaque livrable est une **spec-as-code** : du texte stable qui sert de
contrat pour les changes suivants (`b1-scaffolder`, `b1-workflow`,
`b1-delivery`).

## Scope In

- Création de `.forge/schemas/full-stack-monorepo/schema.yaml` conforme à
  la structure de `default/schema.yaml` avec extensions spécifiques
  (champs `layers`, gates par couche, agent Janus référencé).
- Création de trois fichiers Markdown sous `.forge/standards/` :
  `global/monorepo-layout.md`, `global/proto-contracts.md`,
  `infra/docker-compose.md`.
- Édition de `.forge/standards/global/git-workflow.md` pour y ajouter une
  section **"Scoped Conventional Commits (monorepo-only)"** avec la liste
  close des scopes autorisés et l'interdiction de scope libre.
- Édition de `docs/VERSIONING.md` pour y ajouter une section
  **"Monorepo Versioning Models"** documentant release-train vs
  per-package.
- Édition de `.forge/standards/index.yml` pour référencer les trois
  nouveaux standards avec leurs triggers.
- Tests : le `constitution-linter.sh` actuel ne teste pas le schema ni les
  standards. Pour maintenir Article I (TDD) sur du contenu déclaratif, on
  ajoute un **check structural** dans `verify.sh` qui vérifie que le
  schema `full-stack-monorepo` valide syntaxiquement (YAML parse + champs
  obligatoires présents). Test écrit avant le schema (RED → GREEN).

## Scope Out (Explicit Exclusions)

- **Aucune écriture de scaffolder** (`B.1.2`). L'implémentation de
  `/forge:init --archetype full-stack-monorepo` est explicitement reportée
  au change `b1-scaffolder`.
- **Aucun agent Janus** (`B.1.7`). Le schema référence Janus mais
  l'agent lui-même est reporté à `b1-workflow`.
- **Aucune modification de `verify.sh`/`constitution-linter.sh` pour
  multi-root** (`B.1.8`). Seul un check structural de validation du
  schema est ajouté (voir Scope In).
- **Aucun template de Taskfile / docker-compose / buf.yaml / CLAUDE.md
  imbriqués** (`B.1.3`, `B.1.4`, `B.1.13`). Ces templates viendront avec
  `b1-scaffolder`, écrits **à partir** du contrat posé ici.
- **Aucun workflow CI** (`B.1.9`). Reporté à `b1-delivery`.
- **Aucun setup d'environnements (dev/staging/prod) ni observabilité**
  (`B.1.12`, `B.1.14`). Reportés à `b1-delivery`.
- **Aucune modification de la Constitution**. Les fondations s'inscrivent
  dans les Articles existants (I, II, III, IV, VI, VII, VIII, IX) sans
  demander d'amendement.

## Impact

- **Users affected** :
    - Contributeurs Forge (lisent le nouveau schema + standards avant
      d'écrire `b1-scaffolder`).
    - Futurs adopters Forge en archétype `full-stack-monorepo` : le schema
      et les standards deviennent le contrat qu'ils signent en
      `/forge:init`.
- **Technical impact** :
    - Fichiers créés : 4 nouveaux (1 YAML schema, 3 Markdown standards).
    - Fichiers modifiés : 3 (`git-workflow.md`, `docs/VERSIONING.md`,
      `.forge/standards/index.yml`).
    - Complexité : **M** (moyenne) — du texte déclaratif principalement,
      mais avec des choix structurels (convention `layers:`, préfixes
      FR-ID, scopes commits) qui engagent tous les changes B.1 suivants.
- **Dependencies** :
    - En amont : aucune. Ce change est la racine du pipeline B.1.
    - Débloque : `b1-scaffolder`, `b1-workflow`, `b1-delivery` (tous les
      items B.1.2 à B.1.14).
- **Risk level** : **Medium**. Risque principal : figer des conventions
  (noms de couches, scopes commits, FR-ID prefixes) qui se révèlent
  inadéquates une fois le scaffolder écrit. Mitigation : le schema
  explicite un champ `schema_version: "0.1.0"` et les standards indiquent
  leur **stade `draft`** jusqu'à validation par `b1-scaffolder` — les
  bumps sont autorisés sans amendement Constitution tant que le schema
  n'a pas atteint v1.0.

## Constitution Compliance

### Article I — TDD

Le livrable est déclaratif (Markdown + YAML), pas du code exécutable.
**Cycle TDD appliqué** via le check structural :

1. RED : écrire dans `verify.sh` (ou un script dédié
   `.forge/scripts/validate-schemas.sh`) un test qui exige la présence
   d'un fichier `.forge/schemas/full-stack-monorepo/schema.yaml` avec les
   champs `name`, `version`, `layers`, `phases`. Le test échoue.
2. GREEN : créer le schema minimal qui fait passer le test.
3. RED suivant : test qui exige que les trois nouveaux standards soient
   référencés dans `.forge/standards/index.yml` avec leurs triggers. Il
   échoue.
4. GREEN : ajouter les entrées d'index.
5. Itérer ainsi pour chaque contrainte testable.

Les **contraintes de texte libre** (tone d'un standard, qualité de
rédaction) ne sont pas testables mécaniquement et relèvent du gate
`/forge:review` (Nemesis/Tribune n'étant pas applicables ici — Aegis
et éventuellement Calliope pour la qualité éditoriale sont sollicités).

### Article II — BDD

Pas de feature user-facing dans ce change. Article II ne s'applique pas
(confirmé par Article II.3 qui autorise l'exemption pour contenu
déclaratif / infra).

### Article III — Specs Before Code

Confirmé : ce proposal sera suivi de `specs.md` (qui transforme la
solution ci-dessus en FR-XXX testables) avant d'écrire le moindre
fichier de livrable.

### Article IV — Delta Specs

`specs.md` sera écrit au format ADDED / MODIFIED / REMOVED. Quatre FR
ADDED attendus (un par livrable majeur), aucun MODIFIED ou REMOVED car
c'est la première introduction de ces conventions.

### Article VI / VII — Architecture (Flutter / Rust)

Non applicables directement : ce change ne touche aucun code Flutter
ou Rust. Mais le schema et les standards **seront** contraints par ces
articles — par exemple, `global/monorepo-layout.md` cite Article VI.2
(Clean Architecture Flutter) et Article VII.3 (Hexagonal Rust) comme
références obligatoires pour les sous-dossiers `frontend/` et `backend/`.

### Article VIII — Infra

`infra/docker-compose.md` cite Article VIII comme référence. Pas de
violation : ce standard **outille** l'Article VIII, il ne le modifie pas.

### Article IX — Observabilité / Sécurité

Le standard `proto-contracts.md` impose `buf breaking` bloquant en CI —
cohérent avec Article IX.4 (contracts as security surface). Pas de
violation.

## Open Questions

Aucune question bloquante. Les décisions structurelles sont énumérées
dans Scope In et figées ici :

- Préfixes FR-ID par couche : `FR-BE-`, `FR-FE-`, `FR-IN-`, `FR-GL-`
  (global / cross-couches).
- Scopes Conventional Commits : liste close `{backend, frontend, infra,
  protos, forge, docs, ci}`. Refus des scopes libres.
- Modèle de versioning par défaut : release-train (un `VERSION` racine,
  un `CHANGELOG.md` racine). Per-package via `release-please` documenté
  comme option pour équipes ≥ 15 contributeurs.
- Le schema `full-stack-monorepo` démarre en `schema_version: "0.1.0"`
  et reste en stade `draft` jusqu'à validation par `b1-scaffolder`.

Toute question émergeant pendant `/forge:specify` sera tracée en
`open-questions.md` conformément au protocole d'ambiguïté (Article V.3)
— **aucune décision implicite**, on bloque et on demande.
