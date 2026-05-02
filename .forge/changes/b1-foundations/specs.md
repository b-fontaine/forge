# Spec: b1-foundations
<!-- Delta format: ADDED, MODIFIED, REMOVED sections only -->

## ADDED Requirements

### FR-GL-001: Schema `full-stack-monorepo` déclare le contrat du monorepo

- **MUST** : un fichier `.forge/schemas/full-stack-monorepo/schema.yaml`
  existe et valide syntaxiquement comme YAML.
- **MUST** : le schema contient les clés top-level `name`, `version`,
  `description`, `tdd_enforced`, `bdd_required_for_user_facing`,
  `coverage_threshold`, `phases`, `layers`.
- **MUST** : `name` vaut exactement la chaîne `full-stack-monorepo`.
- **MUST** : `version` est une chaîne SemVer (regex
  `^\d+\.\d+\.\d+(-[\w.-]+)?$`) ; la version initiale est `"0.1.0"` pour
  signaler le stade pré-stable.
- **MUST** : `layers` est un tableau non vide listant **au minimum**
  `backend`, `frontend`, `infra`. Chaque couche est un objet avec
  `id` (string), `path` (chemin relatif racine, ex. `backend/`),
  `fr_id_prefix` (ex. `FR-BE-`), `primary_agent` (ex. `Vulcan`,
  `Hera`, `Atlas`), `standards_scope` (tableau de scopes
  `index.yml`).
- **MUST** : `phases` est un tableau qui **étend** les phases de
  `default/schema.yaml` (proposal, specs, design, tasks, implementation,
  review, archive). Chaque phase définit son `gate`. La phase `design`
  **MUST** tolérer un design par couche touchée (`design-backend.md`,
  `design-frontend.md`, `design-infra.md`) — réserve documentée pour
  `b1-workflow`.
- **MUST** : le schema référence `agent: Janus` pour l'orchestration
  cross-couches, avec une note en commentaire YAML signalant que l'agent
  lui-même est livré par `b1-workflow`.
- **SHALL** : déclarer un champ top-level `stage: draft` pour signaler
  qu'aucune version n'est consommable tant que `b1-scaffolder` n'a pas
  validé la forme par un scaffolding réel.
- **SHOULD** : exposer un champ `fr_id_prefix_cross_layer: FR-GL-` pour
  les requirements qui touchent plusieurs couches.

**Constitution Reference** : Article III.2 (specs-as-code), Article VI
(architecture Flutter), Article VII (architecture Rust), Article VIII
(infra).

**Testable** : *Yes* — un test shell (`tests/schemas/full-stack-monorepo.test.sh`
ou équivalent, exécuté par `verify.sh`) parse le YAML, contrôle les
clés obligatoires, vérifie les contraintes (name, SemVer, layers ≥ 3,
stage=draft). Le test est écrit AVANT le schema (RED → GREEN).

---

### FR-GL-002: Standard `global/monorepo-layout.md` grave l'arborescence canonique

- **MUST** : un fichier `.forge/standards/global/monorepo-layout.md`
  existe et décrit l'arborescence de l'archétype (`frontend/`,
  `backend/`, `infra/`, `shared/protos/`, `.github/workflows/` par
  couche).
- **MUST** : le standard énonce **l'interdiction formelle** d'imports
  croisés `frontend/` ↔ `backend/` autres que via les protos générés
  depuis `shared/protos/`.
- **MUST** : le standard définit la convention de CLAUDE.md imbriqués
  (`frontend/CLAUDE.md`, `backend/CLAUDE.md`, `infra/CLAUDE.md`) avec
  leurs rôles — scoper les standards chargés par Claude Code lorsqu'il
  navigue dans ce sous-dossier, éviter la saturation de contexte.
- **MUST** : le standard déclare les **préfixes FR-ID par couche** :
  `FR-BE-` (backend), `FR-FE-` (frontend), `FR-IN-` (infra),
  `FR-GL-` (cross-couches / global).
- **SHALL** : citer Article VI.2 (Clean Architecture Flutter) et
  Article VII.3 (Hexagonal Rust) comme références applicables dans
  les sous-arborescences respectives.
- **SHALL** : pointer vers `global/proto-contracts.md` pour tout ce qui
  touche au contrat d'échange cross-couches.

**Constitution Reference** : Articles VI, VII, VIII.

**Testable** : *Yes* — check structurel : le fichier existe, contient
des sections nommées `## Arborescence`, `## Interdictions`,
`## CLAUDE.md imbriqués`, `## Préfixes FR-ID`. Vérifié par
`verify.sh` via un linter de présence de sections.

---

### FR-GL-003: Standard `global/proto-contracts.md` formalise les protos comme source unique de vérité

- **MUST** : un fichier `.forge/standards/global/proto-contracts.md`
  existe et décrit l'organisation de `shared/protos/` (structure
  `v1/`, `v2/`, `buf.yaml`, `buf.gen.yaml`).
- **MUST** : le standard impose `buf lint` et `buf breaking` comme
  **gates bloquants** en CI avant tout merge qui touche `shared/protos/`.
- **MUST** : le standard définit la stratégie de versioning des protos
  (namespace `v1`, `v2` ; nouveau namespace à chaque breaking change ;
  deprecation sur 2 versions minimum avant suppression).
- **MUST** : le standard documente la génération des stubs :
  `tonic-build` pour Rust (consommé par `backend/crates/grpc-api/`),
  `protoc_plugin` pour Dart (généré sous
  `frontend/lib/generated/protos/`).
- **SHALL** : interdire toute modification manuelle des fichiers
  générés et imposer qu'ils soient regénérés à la demande via
  `task proto` (défini dans `b1-scaffolder`).
- **SHOULD** : fournir la checklist de review d'un change protos
  (nommage, numérotation, deprecation, compatibilité).

**Constitution Reference** : Article IV (delta specs appliqué aux
contrats), Article IX.4 (contracts as security surface).

**Testable** : *Yes* — check structurel identique à FR-GL-002 :
présence du fichier et de ses sections canoniques.

---

### FR-GL-004: Standard `infra/docker-compose.md` cadre l'orchestration locale

- **MUST** : un fichier `.forge/standards/infra/docker-compose.md`
  existe et décrit la convention `docker-compose.dev.yml` racine du
  monorepo (services nommés avec préfixe `fsm-`, réseau unique
  `fsm-dev`, healthchecks obligatoires, tag `depends_on` avec
  `condition: service_healthy`).
- **MUST** : le standard impose que les services exposent leurs
  variables d'env via un fichier `.env.example` versionné (secrets
  stubs). Le vrai `.env` est gitignoré.
- **MUST** : le standard interdit `docker-compose.yml` non suffixé —
  un monorepo Forge n'a **jamais** un compose racine non suffixé pour
  éviter la confusion dev/prod.
- **SHALL** : documenter les trois services canoniques attendus en dev
  (`fsm-backend`, `fsm-kong`, `fsm-db`) avec healthchecks et scripts
  de seed.
- **SHOULD** : fournir un exemple complet de `docker-compose.dev.yml`
  en annexe du standard.

**Constitution Reference** : Article VIII (infrastructure).

**Testable** : *Yes* — check structurel : présence du fichier et de
ses sections canoniques.

---

### FR-GL-005: `global/git-workflow.md` intègre les Conventional Commits scopés monorepo

- **MUST** : le standard existant `.forge/standards/global/git-workflow.md`
  est enrichi d'une section **"Scoped Conventional Commits (monorepo-only)"**.
- **MUST** : la section déclare la **liste close** des scopes autorisés
  pour un projet en archétype `full-stack-monorepo` :
  `{backend, frontend, infra, protos, forge, docs, ci}`.
- **MUST** : la section interdit formellement les scopes libres (tout
  scope hors liste → commit rejeté par le pre-commit hook prévu en
  `b1-delivery` G.2).
- **MUST** : la section documente que l'archétype non-monorepo continue
  d'utiliser les scopes libres — cette règle n'active que si
  `.forge.yaml` racine déclare `schema: full-stack-monorepo`.
- **SHALL** : fournir au moins 3 exemples par scope (commits
  canoniques et anti-patterns).

**Constitution Reference** : Article X (qualité), Article X.4 (git
hygiene).

**Testable** : *Yes* — check structurel : la section
`## Scoped Conventional Commits (monorepo-only)` existe, la liste
close est parsable (regex sur `` `{backend, frontend, infra,
protos, forge, docs, ci}` ``).

---

### FR-GL-006: `docs/VERSIONING.md` documente les deux modèles de versioning monorepo

- **MUST** : le document existant `docs/VERSIONING.md` est enrichi
  d'une section **"Monorepo Versioning Models"**.
- **MUST** : la section documente les deux modèles :
    - **Release-train** : un `VERSION` racine, un `CHANGELOG.md` racine,
      tous les packages taggés à la même version. Recommandé pour
      équipes ≤ 15 contributeurs.
    - **Per-package via `release-please`** : `VERSION` et `CHANGELOG.md`
      par package/crate, versions indépendantes, release-please PR par
      package. Recommandé pour équipes ≥ 15 ou releases asynchrones.
- **MUST** : la section statue **la recommandation Forge par défaut**
  (release-train) et précise **les critères de bascule** vers
  per-package.
- **SHALL** : fournir la matrice décisionnelle (équipe, cadence,
  couplage des couches, release asynchrone besoin, compliance).
- **SHOULD** : citer des exemples de projets OSS de référence pour
  chaque modèle.

**Constitution Reference** : Article A6 (SemVer), Article X (qualité).

**Testable** : *Yes* — check structurel : section
`## Monorepo Versioning Models` présente avec deux sous-sections
`### Release-train` et `### Per-package via release-please`.

---

### FR-GL-007: `.forge/standards/index.yml` référence les trois nouveaux standards

- **MUST** : l'index existant `.forge/standards/index.yml` contient
  trois nouvelles entrées, chacune avec `name`, `path`, `scope`,
  `priority`, `triggers`.
- **MUST** : `global/monorepo-layout.md` a `scope: monorepo`,
  `priority: high`, triggers incluant `monorepo`, `full-stack`,
  `layers`.
- **MUST** : `global/proto-contracts.md` a `scope: protos`,
  `priority: high`, triggers incluant `proto`, `buf`, `grpc`.
- **MUST** : `infra/docker-compose.md` a `scope: infra`,
  `priority: medium`, triggers incluant `docker-compose`, `local-dev`,
  `compose`.
- **SHALL** : aucune entrée existante n'est modifiée (delta purement
  additif).

**Constitution Reference** : Article V (JIT standards loading via
index).

**Testable** : *Yes* — check structurel : parser `index.yml` en YAML,
vérifier présence des 3 nouvelles entrées et conformité de leurs
champs.

---

### FR-GL-008: Un check structural de fondations est ajouté à `verify.sh`

- **MUST** : `.forge/scripts/verify.sh` (ou un nouveau script
  `.forge/scripts/validate-foundations.sh` appelé depuis `verify.sh`)
  contient les checks testant FR-GL-001 à FR-GL-007.
- **MUST** : le check retourne un code de sortie non-zéro si l'un des
  livrables est absent, malformé, ou ne respecte pas les contraintes
  listées.
- **MUST** : chaque check émet une ligne de log structurée
  `PASS/FAIL: <FR-ID> — <message court>`.
- **SHALL** : les checks sont écrits **avant** les livrables (cycle RED
  → GREEN strictement respecté).
- **SHALL** : le script est portable POSIX shell (pas de bashisms au-delà
  de `#!/usr/bin/env bash`, pas de dépendance exotique — `yq` ou `python3`
  sont acceptables car déjà présents dans l'image `forge/linter`).

**Constitution Reference** : Article I (TDD), Article V (gates
déterministes).

**Testable** : *Yes*, auto-testing — le script est lui-même testé en
l'exécutant sur (a) l'état initial avant livrable → doit FAIL, (b)
l'état final après livrable → doit PASS.

---

## MODIFIED Requirements

<!-- Aucun. Toutes les requirements de ce change sont ADDED : ni le schema
     full-stack-monorepo, ni les trois nouveaux standards, ni la section
     commits scopés monorepo, ni la section monorepo-versioning n'existent
     au préalable. -->

## REMOVED Requirements

<!-- Aucun. -->

---

## Acceptance Criteria

### AC-001 — Links FR-GL-001 : schema existe et valide

```gherkin
Given le repo Forge au commit de tête post-v0.2.1
When un développeur exécute `bash .forge/scripts/verify.sh`
Then la sortie contient `PASS: FR-GL-001 — schema full-stack-monorepo OK`
And le code de sortie est 0
```

### AC-002 — Links FR-GL-001 : schema rejette une version malformée

```gherkin
Given le schema full-stack-monorepo avec `version: "draft"` (non SemVer)
When le check structural est exécuté
Then la sortie contient `FAIL: FR-GL-001 — version does not match SemVer`
And le code de sortie est non-zéro
```

### AC-003 — Links FR-GL-002, FR-GL-003, FR-GL-004 : les trois standards existent

```gherkin
Given le repo Forge au commit de tête post-livrable
When un développeur liste `.forge/standards/global/*.md .forge/standards/infra/*.md`
Then la sortie inclut `monorepo-layout.md`, `proto-contracts.md`, `docker-compose.md`
And chacun contient ses sections canoniques (vérifié par le linter)
```

### AC-004 — Links FR-GL-005 : commits scopés reconnus, scopes libres rejetés

```gherkin
Given un projet utilisant schema `full-stack-monorepo`
When un contributeur propose un commit `feat(payment): add Stripe`
Then le pre-commit hook (livré en b1-delivery) rejette avec
  "scope 'payment' not in {backend, frontend, infra, protos, forge, docs, ci}"
And le hook propose les scopes valides
```
<!-- Ce AC est testé par le standard mais le hook sera livré en b1-delivery.
     Pour ce change, on valide la *déclaration* de la liste close dans le
     standard (linter qui parse la section). -->

### AC-005 — Links FR-GL-006 : docs/VERSIONING expose les deux modèles

```gherkin
Given le fichier docs/VERSIONING.md enrichi
When un contributeur cherche "release-train" et "release-please" dans le fichier
Then les deux modèles sont documentés avec leur recommandation d'usage
And la matrice de décision est présente
```

### AC-006 — Links FR-GL-007 : index.yml charge les nouveaux standards

```gherkin
Given `.forge/standards/index.yml` enrichi
When le linter parse l'index
Then les trois nouvelles entrées sont présentes avec les bons scopes/triggers
And aucune entrée existante n'a été modifiée
```

### AC-007 — Links FR-GL-008 : cycle TDD RED → GREEN exécuté

```gherkin
Given la branche de travail b1-foundations avant livrable (tests écrits, fichiers absents)
When `bash .forge/scripts/verify.sh` est exécuté
Then la sortie contient au moins un FAIL par FR-GL-00[1-7]
And le code de sortie est non-zéro

Given la branche après livrable complet
When `bash .forge/scripts/verify.sh` est exécuté
Then la sortie contient PASS pour tous les FR-GL-00[1-8]
And le code de sortie est 0
```

---

## Non-Functional Requirements

### NFR-001 : Idempotence des checks

- **MUST** : exécuter `bash .forge/scripts/verify.sh` deux fois de suite
  sur le même état du dépôt produit exactement la même sortie et le même
  code de retour. Aucun side effect (fichier créé, cache rempli) ne doit
  perturber la seconde exécution.

### NFR-002 : Performance du check structural

- **SHALL** : la durée d'exécution du check structural des fondations
  reste `< 2 secondes` sur une machine de dev standard (CPU ≥ 2 cores,
  repo Forge en shallow clone). Le check sera appelé sur chaque PR par
  le workflow CI livré en `b1-delivery`.

### NFR-003 : Documentation stable

- **MUST** : les fichiers Markdown livrés doivent passer `markdownlint`
  avec la config par défaut de Forge (cf. `.forge/standards/global/...`).
- **SHALL** : aucune ligne > 100 colonnes dans les standards (cohérent
  avec les standards existants).

### NFR-004 : Traçabilité cross-change

- **MUST** : chaque livrable référence explicitement son audit ID parent
  (`<!-- Audit: B.1.1 -->` en tête de fichier pour le schema, idem pour
  les standards). Permet de retracer chaque fichier à sa justification
  stratégique.

---

## Out of Scope

<!-- Explicitement exclu pour maintenir la focalisation de ce change. -->

- **Scaffolder `/forge:init --archetype full-stack-monorepo`** — livré
  par `b1-scaffolder` (change suivant).
- **Agent Janus** — référencé dans le schema mais implémenté par
  `b1-workflow`.
- **Adaptations multi-root de `verify.sh`/`constitution-linter.sh`** —
  seul un check structural additif est livré ici. La refonte multi-root
  est reportée à `b1-workflow` (B.1.8).
- **Workflows GitHub Actions** — reportés à `b1-delivery` (B.1.9).
- **Templates Taskfile, docker-compose.dev.yml, buf.yaml** — reportés
  à `b1-scaffolder` (B.1.13, B.1.4).
- **Pre-commit hook vérifiant les scopes commits** — reporté à
  `b1-delivery` (Module G.2).
- **Exemples de projets scaffoldés** — reportés à Module C (C.1), qui
  dépend lui-même de `b1-scaffolder` complet.
- **Amendements de la Constitution** — ce change n'en requiert aucun.

---

## Open Questions

<!-- Protocole : [NEEDS CLARIFICATION: question] bloque le progrès. -->

Aucune question ouverte à ce stade. Les décisions structurelles du
proposal (préfixes FR-ID, scopes commits, modèle de versioning par
défaut, stage=draft du schema) ont été gravées ici comme partie du
contrat explicite. Toute question émergeant pendant `/forge:design` sera
tracée dans `.forge/changes/b1-foundations/open-questions.md`
(F.1 — Persistent [NEEDS CLARIFICATION] tracking, non encore livré
mais pratique conventionnelle à adopter dès ce change).
