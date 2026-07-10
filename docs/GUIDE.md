# Guide Utilisateur — Forge

---

## Qu'est-ce que Forge ?

Forge est un framework de développement spec-driven qui transforme Claude Code en une équipe de développement structurée
et multi-agents. Il fusionne sept approches complémentaires en un système cohérent :

| Source               | Contribution                                           |
|----------------------|--------------------------------------------------------|
| **BMAD Method**      | Agents-personas avec noms, rôles et styles persistants |
| **GitHub SpecKit**   | Gates bloquants et vérification de conformité          |
| **OpenSpec**         | Deltas sémantiques (ADDED/MODIFIED/REMOVED)            |
| **Agent OS v3**      | Injection de standards à la demande via `index.yml`    |
| **Superpowers**      | TDD non-négociable, table anti-rationalisation         |
| **oh-my-claudecode** | Keywords naturels, orchestration multi-agents          |
| **Context7**         | Résolution de documentation d'API en temps réel        |

Le principe fondamental : **les specs sont le code source de l'intention**. Avant d'écrire une ligne de code, Forge vous
guide pour documenter le problème, la solution, les décisions d'architecture et les tâches TDD. Le code devient alors
une conséquence naturelle de la spec, pas une improvisation.

---

## Installation

### Nouveau projet

1. Copier les fichiers Forge à la racine du projet :
   ```bash
   cp -r forge/ /chemin/vers/votre/projet/
   ```

2. Ouvrir Claude Code et lancer :
   ```
   /forge
   ```

3. Suivre le flux auto-détecté — Forge détecte qu'aucun état n'existe et lance `/forge:init` puis `/forge:vision`.

### Projet existant

1. Copier Forge à la racine du projet comme ci-dessus.

2. Lancer l'initialisation :
   ```
   /forge:init
   ```

3. Capturer les conventions existantes :
   ```
   /forge:discover
   ```
   Forge analyse votre codebase et extrait les patterns, conventions et standards déjà en place, puis les documente dans
   `.forge/standards/`.

---

## La Commande Maîtresse `/forge`

`/forge` est le point d'entrée unique. Elle lit l'état du projet et vous route automatiquement vers la bonne phase.

```
/forge
   |
   v
[.forge/ existe ?]
   |          |
  Non         Oui
   |           |
   v           v
/forge:init  [vision.md existe ?]
              |              |
             Non             Oui
              |               |
              v               v
         /forge:vision   [changes/ contient des dossiers ?]
                              |                    |
                             Non                   Oui
                              |                    |
                              v                    v
                       /forge:explore    [quel état par dossier ?]
                                              |
                              +--------------+---------------+
                              |              |               |
                              v              v               v
                          propose/       specify/         design/
                          (→ specify)   (→ design)       (→ plan)
                              |              |               |
                              v              v               v
                           plan/         implement/       review/
                          (→ impl)       (→ review)      (→ archive)
```

La détection d'état est déterministe : Forge lit les fichiers présents dans `.forge/changes/<nom>/` pour identifier où
vous en êtes dans le cycle.

---

## Le Cycle de Développement

### Étape 1 — Vision (`/forge:vision`)

Définir la mission et la proposition de valeur du produit. Forge guide Oracle (agent AI-First) et vous pour produire :

- Mission statement (une phrase)
- Proposition de valeur (3 bullets)
- Utilisateurs cibles
- Problèmes résolus
- Résultat : `.forge/product/mission.md`

### Étape 2 — Exploration (`/forge:explore`)

Séance de brainstorming libre avec Oracle. Forge ne bloque pas — c'est la phase d'idéation. Oracle facilite une
évaluation AI-First : est-ce que cette fonctionnalité bénéficie de l'IA ? Si oui, comment ? Cette phase produit des
notes non-structurées dans `.forge/product/exploration/`.

### Étape 3 — Proposition (`/forge:propose <nom>`)

Documenter formellement le problème et la solution proposée. Clio (Spec Writer) vous guide pour rédiger :

- Contexte et motivation
- Description du problème
- Solution proposée
- Alternatives considérées
- Critères d'acceptation (haut niveau)
- Résultat : `.forge/changes/<nom>/proposal.md`

### Étape 4 — Spécification (`/forge:specify <nom>`)

Clio rédige les specs delta avec le langage RFC 2119 (MUST, SHOULD, MAY). Format delta : seuls les changements par
rapport à l'état actuel sont documentés (ADDED, MODIFIED, REMOVED). Résultat : `.forge/changes/<nom>/specs.md`

### Étape 5 — Design (`/forge:design <nom>`)

Athena (Flutter) ou Ferris (Rust) — ou Socrates pour le domaine métier — produisent :

- Architecture Decision Records (ADRs)
- Diagrammes de composants
- Contrats d'interface
- Décisions techniques documentées avec justification
- Résultat : `.forge/changes/<nom>/design.md`

### Étape 6 — Planification (`/forge:plan <nom>`)

Génération d'une liste de tâches ordonnées pour TDD. Chaque tâche suit le format :

```
TASK-001: [Description]
  Test: [Quel test écrire en premier — RED]
  Implementation: [Ce qu'il faut implémenter — GREEN]
  Refactor: [Ce qu'il faut nettoyer — REFACTOR]
```

L'ordre des tâches est conçu pour que chaque tâche s'appuie sur la précédente.

### Étape 7 — Implémentation (`/forge:implement <nom>`)

Exécution de la prochaine tâche non-complétée du plan. Le cycle est strict :

1. **RED** — Écrire le test. Le voir échouer.
2. **GREEN** — Écrire le minimum de code pour faire passer le test.
3. **REFACTOR** — Nettoyer sans casser les tests.

Spartan (Flutter) ou Centurion (Rust) enforce ce cycle sans exception. Aucune rationalisation n'est acceptée.

### Étape 8 — Review + Archive (`/forge:review` + `/forge:archive`)

**Review** : Nemesis (Flutter) ou Tribune (Rust) appliquent les quality gates :

- Couverture de tests suffisante ?
- Constitution respectée ?
- Standards techniques validés ?
- Design implémenté fidèlement ?

**Archive** : Une fois la review passée, les specs delta sont fusionnées dans `.forge/specs/`, le dossier de changement
est marqué `DONE`, et un résumé est ajouté au journal du projet.

---

## Les Agents

### Flutter Team (dirigée par Hera)

| Agent                | Nom        | Spécialité                                 |
|----------------------|------------|--------------------------------------------|
| Flutter Orchestrator | Hera       | Coordination d'équipe, workflow de feature |
| Flutter Architect    | Athena     | Clean Architecture, FSD, DI                |
| Flutter TDD-BDD      | Spartan    | Enforcement des tests, tolérance zéro      |
| Flutter UX/UI        | Apollo     | Design multi-plateforme, Material 3        |
| Flutter Widgets      | Hephaestus | Widgets custom, animations                 |
| Flutter Performance  | Hermes     | Profiling, optimisation                    |
| Flutter A11y & i18n  | Iris       | Accessibilité, internationalisation        |
| Flutter OTel         | Argus      | Instrumentation côté client                |
| Flutter AI           | Prometheus | Voice, GenUI, agents                       |
| Flutter Quality      | Nemesis    | Gate final, délégation                     |

### Rust Team (dirigée par Vulcan)

| Agent             | Nom       | Spécialité                    |
|-------------------|-----------|-------------------------------|
| Rust Orchestrator | Vulcan    | Coordination d'équipe         |
| Rust Architect    | Ferris    | Architecture hexagonale, gRPC |
| Rust TDD-BDD      | Centurion | Enforcement des tests         |
| Rust TUI          | Terminal  | ratatui, architecture Elm     |
| Rust OTel         | Sentinel  | Instrumentation côté serveur  |
| Rust Quality      | Tribune   | Gate final                    |

### Agents Transversaux

| Agent               | Nom      | Spécialité                           |
|---------------------|----------|--------------------------------------|
| Forge Master        | Forge    | Orchestration, routing               |
| Spec Writer         | Clio     | Exigences, RFC 2119                  |
| DDD Strategist      | Socrates | Modélisation domaine, Event Storming |
| AI-First Brainstorm | Oracle   | Atelier AI, architecture d'agents    |
| Infra Architect     | Atlas    | Docker, K8s, Kong, Temporal          |
| Observability       | Panoptes | OTel, SigNoz, ELK, Prometheus        |
| Security Auditor    | Aegis    | Audit de sécurité, OWASP             |
| Data Steward EU     | Demeter  | Tier classification, DPA, CLOUD Act  |
| Compliance Officer EU | Themis | NIS2/DORA/CRA, cycle review-standards |
| DevOps Engineer     | Heracles | CI/CD, déploiement                   |

---

## Compatibilité

### Superpowers

La délégation TDD fonctionne comme suit : quand `/forge:implement` est invoqué, Forge détermine le contexte (Flutter ou
Rust), puis délègue à l'agent TDD approprié (Spartan ou Centurion). Cet agent dispose d'une table anti-rationalisation
de 12 excuses communes avec leurs réfutations, et refuse tout argument pour sauter RED ou aller directement au code.

### oh-my-claudecode

Forge s'intègre avec les keyword triggers d'OMC :

| Keyword     | Comportement                                               |
|-------------|------------------------------------------------------------|
| `autopilot` | Exécution complète du pipeline depuis l'état actuel        |
| `ulw`       | Ultrawork mode — implémentation profonde sans interruption |
| `team`      | Délégation explicite à l'équipe multi-agents               |

### Context7

La résolution de documentation se fait en deux temps via le serveur MCP :

1. `resolve-library-id` — identifier la bibliothèque dans le catalogue Context7
2. `query-docs` — récupérer la documentation à jour pour les APIs concernées

Cela garantit que Forge travaille toujours avec la documentation courante, pas avec les données d'entraînement
potentiellement obsolètes.

---

## Intégration AI Modeling

### L'atelier facilité par Oracle

Oracle (agent AI-First) facilite un atelier structuré en 5 phases pour toute fonctionnalité potentiellement IA :

1. **Discovery** — Identifier le besoin réel. Est-ce vraiment un problème d'IA ?
2. **Capability mapping** — Quelles capacités IA sont pertinentes ? (LLM, vision, speech, embeddings...)
3. **Architecture** — Comment intégrer sans coupler ? Ports & Adapters.
4. **Non-determinism strategy** — Comment tester quelque chose de non-déterministe ?
5. **Fallback design** — Que se passe-t-il si l'IA échoue ou est indisponible ?

### Les 3 AImigos

Le concept des 3 AImigos transpose le modèle des 3 Amigos au contexte IA :

- **Product** (besoin réel ?) — Est-ce que l'IA apporte une vraie valeur ici, ou est-ce du feature-isme ?
- **Dev** (faisable ?) — Quelles sont les contraintes techniques ? Latence, coût, modèles disponibles ?
- **Test** (comment tester le non-déterminisme ?) — Contrats de comportement, snapshots sémantiques, évaluation par
  LLM ?

---

## Schemas Personnalisés

Forge supporte 5 schemas prédéfinis qui adaptent le pipeline au contexte du projet :

| Schema        | Cas d'usage         | Particularités                                      |
|---------------|---------------------|-----------------------------------------------------|
| `default`     | Flux standard       | Toutes les phases, équilibré                        |
| `tdd-flutter` | Application Flutter | + Golden tests, phase BDD explicite                 |
| `tdd-rust`    | Application Rust    | + Architecture hexagonale, clippy enforcement       |
| `rapid`       | Prototype rapide    | 4 phases minimales (TDD toujours obligatoire)       |
| `ai-first`    | Produit IA natif    | + Phase atelier Oracle, évaluation non-déterminisme |

Pour appliquer un schema, ajouter dans `.forge.yaml` :

```yaml
schema: tdd-flutter
```

Le schema `rapid` ne supprime pas le TDD — il compresse les phases de documentation. La constitution reste applicable.

---

## Philosophie

**Conviction 1 : Les specs sont le code source de l'intention**

Le code est éphémère — il sera refactorisé, réécrit, supprimé. Les specs sont le registre durable de ce qui a été décidé
et pourquoi. Un projet sans specs est un projet dont l'intention est perdue à chaque rotation d'équipe.

**Conviction 2 : Le TDD est non-négociable, jamais optionnel**

TDD n'est pas une bonne pratique parmi d'autres. C'est la méthode de travail. Chaque tâche, sans exception, commence par
un test qui échoue. "On manque de temps" et "c'est trop simple pour un test" sont des rationalisations cataloguées —
Spartan et Centurion les connaissent toutes.

**Conviction 3 : La qualité est structurelle, pas une question de volonté**

Les quality gates, la constitution, les agents dédiés à la review — tout cela est là pour rendre la qualité inévitable.
On ne compte pas sur la discipline individuelle dans un projet d'équipe. On construit des systèmes où faire les choses
correctement est le chemin de moindre résistance.
