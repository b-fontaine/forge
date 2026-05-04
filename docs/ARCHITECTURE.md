# Architecture — Forge

---

## Vue d'Ensemble

Forge est une collection de fichiers Markdown exécutés par un LLM. Il n'y a pas de runtime, pas de binaire, pas de
package à installer. Le "runtime" est Claude Code + le LLM Claude.

**L'insight fondamental : le Markdown EST le code.**

Les définitions d'agents, les commandes slash, les standards techniques et les skills sont tous des fichiers Markdown
qui façonnent le comportement du LLM. Quand Claude Code charge `.claude/agents/flutter/hera.md`, Hera existe. Quand le
fichier n'est pas chargé, Hera n'existe pas. Il n'y a pas de magie — juste du contexte injecté de façon contrôlée.

Ce modèle a une implication importante : **la qualité du Markdown détermine la qualité du comportement**. Un agent mal
défini produit un comportement imprévisible. Une commande ambiguë produit des résultats incohérents. Forge traite ses
fichiers Markdown avec le même soin qu'un codebase de production.

---

## Structure Annotée

```
forge/
├── CLAUDE.md                    # Point d'entrée — lu automatiquement par Claude Code
│                                # Charge les instructions globales, référence les agents,
│                                # définit les comportements de base
│
├── .mcp.json                    # Configuration MCP (Context7)
│                                # Déclare le serveur MCP pour la résolution de docs
│
├── .forge/
│   ├── constitution.md          # La loi suprême — 11 articles, aucune violation tolérée
│   │                            # Tout agent, toute commande, tout output doit s'y conformer
│   │
│   ├── standards/               # Règles techniques injectées dynamiquement
│   │   ├── index.yml            # Catalogue avec triggers — orchestration de l'injection
│   │   │                        # Chaque entrée : id, path, triggers, scope, priority
│   │   ├── global/              # Standards transversaux (TDD, BDD, DDD, SOLID, naming...)
│   │   ├── flutter/             # Standards Flutter (architecture, tests, UI...)
│   │   ├── rust/                # Standards Rust (architecture, error handling, async...)
│   │   ├── infra/               # Standards infrastructure (Docker, K8s, Kong, Temporal...)
│   │   └── observability/       # Standards observabilité (OTel, SigNoz, ELK, Prometheus)
│   │
│   ├── schemas/                 # Workflows personnalisables par type de projet
│   │   ├── default/             # Pipeline standard
│   │   ├── tdd-flutter/         # Flutter + golden tests + BDD
│   │   ├── tdd-rust/            # Rust + hexagonal + clippy
│   │   ├── rapid/               # 4 phases minimales
│   │   └── ai-first/            # Avec phase atelier Oracle
│   │
│   ├── product/                 # Vision et contexte produit
│   │   ├── vision.md            # Mission, proposition de valeur, utilisateurs cibles
│   │   └── exploration/         # Notes de brainstorming (non-structurées)
│   │
│   ├── changes/                 # Changements en cours (un dossier par feature/fix)
│   │   └── <nom>/
│   │       ├── proposal.md      # Problème + solution proposée
│   │       ├── specs.md         # Specs delta RFC 2119
│   │       ├── design.md        # ADRs + décisions techniques
│   │       └── tasks.md         # Plan TDD ordonné
│   │
│   ├── specs/                   # Specs accumulées (résultat des archives)
│   │                            # Base de connaissance du projet — croît dans le temps
│   │
│   └── templates/               # Templates pour chaque artifact
│       ├── proposal.md          # Template proposal
│       ├── specs.md             # Template specs delta
│       ├── design.md            # Template design / ADR
│       └── tasks.md             # Template plan de tâches
│
├── .claude/
│   ├── commands/forge/          # Commandes slash Claude Code
│   │   ├── forge.md             # /forge — master command avec détection d'état
│   │   ├── init.md              # /forge:init
│   │   ├── discover.md          # /forge:discover
│   │   ├── vision.md            # /forge:vision
│   │   ├── new.md               # /forge:new
│   │   ├── propose.md           # /forge:propose
│   │   ├── specify.md           # /forge:specify
│   │   ├── design.md            # /forge:design
│   │   ├── plan.md              # /forge:plan
│   │   ├── implement.md         # /forge:implement
│   │   ├── review.md            # /forge:review
│   │   ├── archive.md           # /forge:archive
│   │   ├── explore.md           # /forge:explore
│   │   └── status.md            # /forge:status
│   │
│   ├── agents/                  # Définitions des agents (personas + règles)
│   │   │   ├── forge-master.md      # Agent principal (Forge)
│   │   ├── spec-writer.md       # Clio
│   │   ├── ddd-strategist.md    # Socrates
│   │   ├── ai-first-brainstorm.md # Oracle
│   │   ├── infra-architect.md   # Atlas
│   │   ├── observability-specialist.md # Panoptes
│   │   ├── security-auditor.md  # Aegis
│   │   ├── devops-engineer.md   # Heracles
│   │   ├── product-analyst.md   # Pythia (PRFAQ, competitive analysis)
│   │   ├── technical-writer.md  # Calliope (docs, changelogs)
│   │   ├── api-designer.md      # Hermes-API (OpenAPI, gRPC)
│   │   ├── test-architect.md    # Eris (test strategy, mutation testing)
│   │   ├── flutter/             # Équipe Flutter (Hera, Athena, Spartan...)
│   │   └── rust/                # Équipe Rust (Vulcan, Ferris, Centurion...)
│   │
│   ├── skills/                  # Skills auto-injectées par Claude Code
│   │   ├── forge-tdd/SKILL.md   # Enforcement TDD + anti-rationalisation
│   │   ├── forge-bdd/SKILL.md   # Enforcement BDD + Given/When/Then
│   │   └── forge-docs/SKILL.md  # Context7 — résolution docs API
│   │
│   └── commands/forge/          # Commandes slash (19 total)
│       ├── forge.md             # Master command + state detection
│       ├── init.md, discover.md, vision.md
│       ├── new.md, propose.md, specify.md, design.md, plan.md
│       ├── implement.md, review.md, archive.md
│       ├── explore.md, status.md
│       ├── verify.md            # Spec-to-code alignment (NEW)
│       ├── clarify.md           # Ambiguity detection (NEW)
│       ├── onboard.md           # Contributor orientation (NEW)
│       ├── diff.md              # Semantic spec diffing (NEW)
│       └── metrics.md           # Velocity metrics (NEW)
│
└── docs/                        # Documentation humaine (vous êtes ici)
    ├── GUIDE.md
    ├── ARCHITECTURE.md
    └── CONTRIBUTING.md
```

---

## Flux de Données

```
Idée utilisateur
      |
      v
/forge (détection d'état)
      |
      +---> Lit .forge/changes/ pour détecter l'état courant
      |
      v
Proposal (Clio)
      |
      v
Specs delta — RFC 2119 (Clio)
      |                         <--- Constitution check (à chaque phase)
      v
Design / ADRs (Athena | Ferris | Socrates)
      |
      v
Plan TDD (tâches ordonnées)
      |                         <--- Standards injection (index.yml, JIT)
      v
Implémentation TDD             <--- Context7 (APIs externes, docs temps réel)
  RED → GREEN → REFACTOR
  (Spartan | Centurion)
      |
      v
Review (Nemesis | Tribune)
      |
      v
Archive → .forge/specs/
  (specs delta fusionnées, état = DONE)
```

La Constitution est vérifiée à chaque transition de phase. Un agent ne peut pas produire un design qui viole l'Article
I (tests obligatoires) ou continuer une implémentation qui ne respecte pas les standards injectés. Le gate est bloquant,
pas advisory.

---

## Patterns Empruntés

| Pattern                    | Source           | Usage dans Forge                               |
|----------------------------|------------------|------------------------------------------------|
| Agents-personas            | BMAD Method      | Chaque agent a un nom, rôle, style persistant  |
| Gates bloquants            | GitHub SpecKit   | Constitution check bloque si violation         |
| Deltas sémantiques         | OpenSpec         | ADDED/MODIFIED/REMOVED au lieu de réécriture   |
| Standards injection        | Agent OS v3      | index.yml avec triggers pour injection JIT     |
| Table anti-rationalisation | Superpowers      | 12 excuses TDD avec réfutations                |
| Keywords naturels          | oh-my-claudecode | autopilot, ulw, team déclenchent comportements |
| Docs temps réel            | Context7         | MCP server pour APIs externes à jour           |

---

## Gestion du Contexte

La fenêtre de contexte d'un LLM est une ressource limitée. Forge adopte 4 stratégies pour l'utiliser efficacement.

### 1. index.yml — Injection JIT des Standards

Les standards ne sont PAS tous chargés en même temps. `index.yml` définit des triggers (mots-clés, patterns de fichiers,
phases) qui déclenchent le chargement d'un standard précis. Si vous travaillez sur un composant Flutter, seuls les
standards Flutter pertinents sont injectés — pas les standards Rust, pas les standards infra.

Exemple d'entrée dans `index.yml` :

```yaml
- id: flutter-clean-architecture
  path: standards/flutter/clean-architecture.md
  triggers:
    - flutter
    - usecase
    - repository
    - domain
  scope: implementation
  priority: high
```

Cela évite la saturation de la fenêtre de contexte par des règles non-pertinentes.

### 2. Micro-fichiers

Chaque agent, commande et standard est un fichier séparé. Seul ce qui est nécessaire pour la tâche en cours est chargé.
Un fichier monolithique de 50 000 tokens serait chargé en entier à chaque invocation — les micro-fichiers permettent une
sélection chirurgicale.

### 3. Subagents Isolés

Déléguer à un sous-agent (Spartan, Athena, etc.) crée un contexte isolé pour ce spécialiste. Spartan n'a pas besoin de
connaître l'historique de la vision produit pour enforcer TDD. Cette isolation évite la contamination croisée et permet
à chaque agent de rester concentré sur sa mission.

### 4. Context7 Séparé

La documentation des bibliothèques externes est récupérée à la demande via le serveur MCP, pas stockée dans le
framework. Stocker la doc de Flutter SDK dans Forge serait : (a) volumineux, (b) obsolète rapidement, (c) chargé même
quand non-nécessaire. Context7 résout les trois problèmes.

---

## Extensibilité

### Axe 1 — Nouveaux Standards

1. Créer `.forge/standards/<domaine>/<nom>.md` avec le format requis (Scope, Rules, Anti-patterns)
2. Ajouter une entrée dans `.forge/standards/index.yml` avec des triggers précis

Les triggers doivent être suffisamment spécifiques pour ne pas déclencher le standard dans des contextes non-pertinents.
Préférer des termes techniques précis à des mots généraux.

### Axe 2 — Nouveaux Agents

1. Créer `.claude/agents/<équipe>/<nom>.md` avec : Persona (Name, Role, Style), Purpose, Expertise, Workflow, Rules
2. Référencer le nouvel agent depuis l'orchestrateur approprié : Hera pour Flutter, Vulcan pour Rust, Forge pour
   transversal

Convention de nommage : mythologie grecque pour Flutter, latin/romain pour Rust, mixte pour transversal.

### Axe 3 — Nouveaux Schemas

1. Créer `.forge/schemas/<nom>/schema.yaml` avec la définition des phases, conditions de gate, et configurations
   d'outils
2. Tester le schema avec un projet réel du début à la fin

Un schema peut supprimer des phases optionnelles (exploration, design détaillé) mais ne peut jamais rendre le TDD
optionnel — c'est une violation de la constitution.

---

## Limitations Connues

**Fenêtre de contexte** — Charger trop de standards simultanément peut saturer la fenêtre de contexte de Claude. Les
triggers dans `index.yml` doivent être calibrés avec soin. Pour les projets complexes avec beaucoup de standards,
surveiller les signes de dégradation de qualité qui indiqueraient une saturation.

**Non-déterminisme** — Des exécutions différentes peuvent produire des outputs différents. Les standards et la
constitution réduisent la variance mais ne l'éliminent pas. Pour les décisions architecturales critiques, une revue
humaine est recommandée en plus de la review par Nemesis/Tribune.

**Pas de CI réel** — Les quality gates sont évalués par le LLM, pas par des outils automatisés. "La constitution est
respectée" est un jugement de l'agent, pas un test unitaire qui passe ou échoue. Pour les projets critiques, combiner
les gates Forge avec une vraie CI (GitHub Actions, etc.) qui exécute les vrais tests.
