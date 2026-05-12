# Quatre frameworks de Spec-Driven Development à l'épreuve de Claude Code : ce que dit la mécanique, ce que disent les utilisateurs, ce que disent les chiffres

*Comparaison rigoureuse de BMAD-METHOD v6, GitHub SpecKit, OpenSpec et Agent OS v3, dans un workflow de production avec Claude Code. Observations datées au 5 mai 2026.*

---

## Avertissement préalable sur la baseline temporelle

Toutes les données chiffrées de cet article — versions, étoiles GitHub, numéros d'issues ouvertes, cadence de release — sont arrêtées au **5 mai 2026**. Le marché des frameworks de Spec-Driven Development (SDD) évolue à une vitesse anormale : entre la conception de cet article et sa lecture, plusieurs colonnes de comparaison auront probablement bougé. Le Technology Radar Vol. 34 de ThoughtWorks (avril 2026) a explicitement formalisé un mécanisme baptisé *too young to blip* — des outils si récents qu'aucune évaluation stable n'est possible. Le présent article n'échappe pas à cette contrainte : utilisez-le comme un instantané méthodologique, pas comme une recommandation produit.

Je distinguerai systématiquement trois registres : (a) ce que les frameworks **prétendent** faire dans leur documentation officielle ; (b) ce que leurs **utilisateurs rapportent** dans les issues, retours de terrain et blogs d'ingénieurs ; (c) ce qui est **mesurable objectivement** — étoiles, cadence de release, modules effectivement livrés. Le lecteur attentif notera que ces trois registres divergent souvent.

---

## Pourquoi cette comparaison, et pourquoi maintenant

Depuis la keynote de Sean Grove à l'AI Engineer World's Fair en mai 2025 (« The New Code »), une thèse circule dans la communauté : la spécification, et non plus le code, deviendrait l'artefact primaire du génie logiciel à l'ère des modèles capables. Andrej Karpathy et Tobi Lütke ont popularisé en juin 2025 l'expression *context engineering*, qui déplaçait le centre de gravité du *prompt* vers l'architecture du contexte fourni au modèle. Le Radar Vol. 33 de ThoughtWorks (novembre 2025) a ensuite classé le spec-driven development en *Assess*, en notant deux camps émergents : ceux qui font confiance aux capacités natives des agents, et ceux qui imposent des workflows structurés.

Sur ce terrain idéologique, quatre frameworks ont émergé comme références opérationnelles pour les équipes utilisant Claude Code en production :

- **BMAD-METHOD v6** (bmad-code-org), centré sur des agents-personas couvrant tout le SDLC ;
- **GitHub SpecKit** (github/spec-kit), centré sur la *constitution* et les marqueurs `[NEEDS CLARIFICATION]` ;
- **OpenSpec** (Fission-AI), centré sur les *deltas* de spécification et le brownfield ;
- **Agent OS v3** (buildermethods), centré sur l'injection de standards.

Avant de comparer, il faut arrêter une grille. Et avant de proposer une grille, il faut un ancrage anti-hype.

## Ancrage anti-hype : ce que mesure la METR

La randomized controlled trial publiée par METR en juillet 2025 (arXiv:2507.09089) reste, au 5 mai 2026, la seule étude empirique sérieuse sur l'impact des outils d'IA sur la productivité de développeurs expérimentés. Sur 246 tâches confiées à 16 contributeurs open-source experts de leurs propres dépôts (~5 ans d'ancienneté en moyenne), l'autorisation d'utiliser Cursor Pro avec Claude 3.5/3.7 Sonnet a **augmenté** le temps de complétion de 19 %. Avant de commencer, les développeurs estimaient un gain de 24 % ; après l'expérience, ils estimaient un gain de 20 %. L'écart entre la perception et la mesure est le résultat le plus instructif. METR a publié en février 2026 une note (`metr.org/blog/2026-02-24-uplift-update`) reconnaissant que la suite de l'expérience souffrait d'un biais de sélection — les développeurs les plus enthousiastes se retiraient des tâches sans IA — et que le design devait être révisé.

Conclusion provisoire : aucun framework SDD ne peut, à ce jour, prétendre démontrer qu'il accélère les développeurs expérimentés sur des codebases matures. Toute évaluation des frameworks comparés ici doit donc commencer par une question : *quel problème suis-je vraiment en train de résoudre ?* — avant celle, plus glamour : *quel framework adopter ?*

## La grille de comparaison, posée avant la comparaison

Pour éviter l'écueil du tableau ad hoc qui flatte le framework qu'on préfère déjà, voici les huit axes que j'utilise, choisis avant tout examen approfondi des frameworks :

1. **Couverture du cycle de vie** : de la vision produit à la maintenance.
2. **Mécanismes anti-hallucination et anti-dérive** : constitution, marqueurs d'ambiguïté, deltas, RFC 2119.
3. **Modèle de spec** : centralisée, en deltas, standards injectables, ou personas.
4. **Brownfield vs greenfield**.
5. **Intégration native Claude Code** : `.claude/`, slash commands, skills, subagents, MCP.
6. **Friction ergonomique réelle** : surcharge pour un bug fix mineur, courbe d'apprentissage, stabilité de l'API du framework.
7. **Maturité communautaire** : issues critiques, cadence de release, écosystème d'extensions.
8. **TDD/BDD natif vs délégué**.

Aucune pondération n'est donnée ici : la pondération dépend du contexte du lecteur (taille d'équipe, ratio greenfield/brownfield, exigence réglementaire). Cette grille n'est pas neutre — elle reflète mes propres priorités d'ingénierie. Elle est explicite, donc contestable.

---

## BMAD-METHOD v6 : l'agile-AI maximaliste

**État au 5 mai 2026** : version stable v6.0.4 sortie début mars 2026 (« End of Beta »), version récente v6.2.2 du 26 mars 2026, environ 45 800 étoiles GitHub, MIT License, créé par Brian Madison.

BMAD revendique être un framework agile-AI complet (« Breakthrough Method for Agile AI-Driven Development ») couvrant le SDLC entier via des agents-personas spécialisés : Analyst, PM, Architect, UX, Scrum Master, Dev, QA (TEA — Test Architect), Tech Writer. La v6 introduit cinq modules (BMM, BMB, CIS, GDS, TEA), une architecture de *skills* compatible avec le format SKILL.md de Claude Code, et un mode d'installation `npx bmad-method install` qui scaffolde l'arborescence `_bmad/` dans le projet.

### Intégration technique avec Claude Code

L'installeur de BMAD détecte les outils présents (`.claude/`, `.cursor/`, etc.) et génère 27 agents et 74 workflows par défaut, configurables via un système TOML d'overrides dans `_bmad/custom/` (introduit avec la v6.2.x via les PR #2284-2289). Un fichier `_bmad/config.toml` centralise les choix de modules. Les workflows historiques (format `workflow.yaml` propriétaire) sont en migration vers le format SKILL.md natif de Claude Code, ce qui rend pour l'instant l'intégration partiellement double : un plugin tiers comme `aj-geddes/claude-code-bmad-skills` ou `PabloLION/bmad-plugin` agrège les modules pour Claude Code en attendant que la migration upstream soit complète.

Concrètement, après installation, un développeur dispose de slash commands organisés autour des phases (analyse → planning → solutioning → implementation), avec un agent `bmad-help` qui sert de routeur conversationnel : « j'ai fini l'architecture, je fais quoi ? ». Les subagents Claude Code sont utilisés pour les revues de code et certains workflows TEA (test architect).

### Friction ergonomique

C'est ici que le décalage entre revendication et expérience terrain devient marqué. L'issue #2003 (« Structural Gaps and Contradictions of the BMAD Method V.6 Stable »), ouverte par un utilisateur déclarant être un fan du framework, expose une critique structurelle : pour un projet petit ou moyen, le processus impose un overhead disproportionné, mêle agents, *party mode* et orchestrations multiples qui rendraient l'exécution pratique plus complexe qu'un simple `CLAUDE.md` couplé à un plan structuré. L'auteur conclut que BMAD est précieux en phase d'idéation, brainstorming, recherche multi-domaine, mais devient « unnecessarily complex even for extremely small projects » en phase d'exécution.

L'issue #1332 illustre un autre travers : le workflow de code review imposait un minimum de 3 issues à trouver par revue, forçant des nitpicks sur du code propre — un anti-pattern reconnu et corrigé depuis, mais révélateur d'une tendance à la sur-prescription dans les prompts internes du framework. L'issue #2274, plus récente, montre une amélioration : `bmad-create-story` lit désormais les fichiers marqués `UPDATE` avant de générer ses dev notes, pour éviter d'improviser sur des comportements existants — autrement dit, BMAD ajoute progressivement des garde-fous brownfield qui manquaient initialement.

Exemple de ligne de configuration dans la nouvelle architecture TOML :

```toml
[modules.bmm]
project_knowledge = "research"
user_skill_level = "expert"

[core]
project_name = "my-project"
```

Verdict honnête : la cadence de release est élevée (plusieurs versions par mois en avril 2026), l'API change vite. Pour un lead d'AI-First Transformation gérant 9 BUs et 500+ devs, cette instabilité est un coût caché.

---

## GitHub SpecKit : la constitution comme discipline

**État au 5 mai 2026** : version 0.8.1 récente, environ 89 000-91 000 étoiles GitHub (forks ~7 700-7 900), MIT License, lancé par GitHub le 2 septembre 2025.

SpecKit est sans doute le framework le plus visible en raison de la marque GitHub qui le porte. Le billet de Den Delimarsky sur le GitHub Blog en septembre 2025 a posé le cadre : on traite les agents de codage comme des *pair programmers literal-minded*, pas comme des moteurs de recherche. Le workflow est un pipeline strict : `/speckit.constitution` → `/speckit.specify` → `/speckit.clarify` (optionnel) → `/speckit.plan` → `/speckit.tasks` → `/speckit.analyze` → `/speckit.implement`.

### Intégration technique avec Claude Code

L'installation se fait via `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git` puis `specify init`. SpecKit pose deux dossiers : `.specify/` (templates, scripts, mémoire) et `.claude/commands/` (les slash commands `speckit.*` pour Claude Code). La documentation liste 17+ agents pris en charge : Claude Code, GitHub Copilot, Cursor, Gemini CLI, Windsurf, Qwen, Codex CLI, OpenCode, etc. Cette agnosticité multi-agent est un argument fort vis-à-vis d'équipes hétérogènes.

Le mécanisme anti-hallucination central est double :
- la **constitution** (`.specify/memory/constitution.md`) — un document de principes non négociables que la commande `/speckit.plan` consulte explicitement comme un *compliance officer* simulé ;
- les marqueurs **`[NEEDS CLARIFICATION: question précise]`** — instruction interne aux templates pour que les LLM, plutôt que de combler les ambiguïtés, les signalent.

L'écosystème d'extensions communautaires (`specify extension add`) est en train de devenir un différenciateur : adversarial review, security audit, code review post-implémentation, side-effect analysis, intégration Jira/Linear, etc.

Exemple de marqueur dans un template :

```markdown
When creating this spec from a user prompt:
1. Mark all ambiguities: Use [NEEDS CLARIFICATION: specific question]
2. Don't guess: If the prompt doesn't specify something, mark it
```

### Friction ergonomique

Le retour de terrain le plus crédible vient du Radar Vol. 33 de ThoughtWorks et du blog d'EPAM (novembre 2025). EPAM a documenté en détail l'usage de SpecKit sur un projet brownfield Java : la constitution doit énoncer non seulement les principes mais aussi les **anti-patterns** explicites (« No try-catch blocks in route handlers »), faute de quoi l'agent les ré-introduit. Le team-lead reste un *technical lead reviewing a junior developer's implementation* — autrement dit, SpecKit ne supprime pas la revue critique, il la déplace.

Les issues GitHub critiques soulignent cette tension : #806 (« brownfield project requires more iterating »), #540 (la section Source Tree du `plan-template.md` produit parfois des arborescences corrompues), #1173 et #1285 (manque documentaire sur le brownfield), discussion #331 et #746 (les utilisateurs cherchent comment importer un codebase existant). Le Radar Vol. 33 reconnaît ces difficultés tout en notant que SpecKit produit le plus de valeur entre des mains d'ingénieurs déjà expérimentés en clean code.

Le risque d'*instruction bloat* — l'accumulation de contexte projet dans la constitution jusqu'à provoquer du *context rot* — est explicitement mentionné par les équipes ThoughtWorks. La discipline requise est non triviale.

---

## OpenSpec : les deltas comme primitive

**État au 5 mai 2026** : version 0.22.0 (avril 2026), environ 45 200-45 300 étoiles GitHub (forks ~3 100), MIT License, maintenu par Fission-AI (Tabish, *@0xTab*).

OpenSpec se positionne explicitement comme une alternative *lightweight* aux frameworks plus prescriptifs. Sa philosophie : « fluid not rigid, iterative not waterfall, built for brownfield not just greenfield ». Le ThoughtWorks Radar Vol. 34 (avril 2026) a placé OpenSpec en *Assess* avec une note explicite : sa focalisation sur les *spec deltas* plutôt que sur une spécification complète en amont en fait un meilleur candidat que SpecKit pour les systèmes existants.

### Intégration technique avec Claude Code

L'installation est légère : `npm install -g @fission-ai/openspec` puis `openspec init`. La structure produite :

```
openspec/
├── specs/        # source de vérité (état courant)
├── changes/      # propositions actives
│   └── archive/  # historique
└── config.yaml
```

Le workflow par défaut (profil *core*) repose sur quatre slash commands : `/opsx:propose`, `/opsx:explore`, `/opsx:apply`, `/opsx:archive`. Le profil étendu (11 commandes : `/opsx:new`, `/opsx:continue`, `/opsx:ff`, `/opsx:verify`, `/opsx:sync`, `/opsx:bulk-archive`, `/opsx:onboard`) couvre des cas plus avancés. Côté Claude Code, OpenSpec génère `.claude/skills/` et `.claude/commands/opsx/` ; un *CommandAdapterRegistry* gère 23+ adaptateurs spécifiques (Cursor, Windsurf, Codex, Copilot, Antigravity, Kiro, Junie, etc.).

Le mécanisme anti-dérive d'OpenSpec est le **delta** : chaque change propose un fichier de spec partiel structuré par les sections `## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements`. Les requirements eux-mêmes utilisent les mots-clés RFC 2119 (`MUST`, `SHALL`, `SHOULD`) avec scénarios `GIVEN/WHEN/THEN` :

```markdown
## MODIFIED Requirements
### Requirement: Session Timeout
The system SHALL expire sessions after 30 minutes of inactivity.
(Previously: 60 minutes)

#### Scenario: Idle timeout
- GIVEN an authenticated session
- WHEN 30 minutes pass without activity
- THEN the session is invalidated
```

À l'archivage, le delta est fusionné dans la spec courante, et le change est déplacé dans `changes/archive/` avec un timestamp. La séparation physique entre *source of truth* et *proposed updates* fournit un audit-trail propre.

### Friction ergonomique

Le retour terrain le plus instructif vient de l'article de Mathivanan Mani comparant SpecKit, OpenSpec et BMAD sur un projet brownfield Java/Spring Boot : OpenSpec a produit le design le plus propre et les meilleurs standards de code pour une feature de taille moyenne. La courbe d'apprentissage est notablement plus douce que celle de BMAD, et le poids de méta-instructions est plus faible que celui de SpecKit.

Côté limites : pas de personas multi-agents, pas d'orchestration cross-repo native, et l'écosystème d'extensions reste plus modeste que celui de SpecKit. L'auteur d'OpenSpec lui-même indique que la génération automatique de specs pour codebases existants est un sujet exploré mais non résolu — la philosophie reste « créer les specs au fil des features, pas en bloc rétrospectif ». Pour un dépôt legacy de 500K LOC, c'est une honnêteté épistémique appréciable, mais aussi un trou fonctionnel.

La cadence de release est élevée mais semble plus ciblée que BMAD : chaque release résout un problème nommé (workflow, profile, schémas custom, support de nouveaux outils). Le repo affiche au 5 mai 2026 environ 226 issues ouvertes, en majorité des demandes d'évolution plutôt que des bugs structurels.

---

## Agent OS v3 : la rétractation comme méthodologie

**État au 5 mai 2026** : version 3.0 publiée en avril 2026, environ 4 400 étoiles GitHub, MIT License, créé par Brian Casel (Builder Methods).

Agent OS est l'outsider de cette comparaison — non par défaut de qualité, mais par positionnement délibéré. La v3 a explicitement supprimé environ 70 % du framework v2. Brian Casel justifie ce choix dans la note de release de la v3 : les modes Plan de Claude Code et l'extended thinking gèrent désormais correctement la rédaction de specs et le découpage de tâches ; il n'est plus pertinent qu'un framework tiers ré-implémente ces fonctions. Agent OS v3 se recentre sur trois primitives : `/discover-standards`, `/inject-standards`, `/shape-spec`.

### Intégration technique avec Claude Code

L'installation passe par un script shell : `curl -sSL https://raw.githubusercontent.com/buildermethods/agent-os/main/setup/base.sh | bash -s -- --claude-code`. La structure pose un dossier `.agent-os/` au niveau projet contenant standards, specs, et product docs, plus des slash commands dans `.claude/commands/`. Un fichier `index.yml` permet la détection automatique de quels standards injecter dans quel contexte.

Exemple de standard typique (Markdown injectable) :

```markdown
---
name: api-conventions
applies_to: [backend, api]
---

## API Implementation Structure
- Router function with request validation
- Router calls data client and/or API client directly
- NO business logic layer/service layer
- Simple logic stays in router; complex logic in data clients
```

L'intégration native avec les *skills* de Claude Code est centrale : `/inject-standards` peut bake les standards dans n'importe quel subagent, skill ou prompt custom — un pattern compatible avec la doc officielle Anthropic sur les skills (`.claude/skills/<skill-name>/SKILL.md`). La v3 retire les phases d'implémentation et d'orchestration de la v2 : le framework délègue à Claude Code les responsabilités que Claude Code remplit déjà bien.

### Friction ergonomique

C'est, paradoxalement, la friction la plus faible des quatre. La courbe d'apprentissage se limite à trois commandes, et la philosophie « fais peu, fais-le proprement » réduit la dette de migration. La rançon est évidente : Agent OS v3 ne couvre pas le cycle de vie complet ; il est conçu pour s'enchâsser dans un workflow Claude Code natif (Plan Mode + skills + subagents), pas pour être autosuffisant.

Le risque épistémique est ici inverse de celui de BMAD : un lead transformation pourrait sous-estimer la valeur d'Agent OS parce qu'il ne ressemble pas à un « framework ». C'est précisément l'argument du créateur — la valeur est dans la discipline d'extraction et d'injection de standards, pas dans le ruban autour. La taille modeste de la communauté (4,4k étoiles vs 45-90k pour les autres) reflète moins une faiblesse intrinsèque qu'un positionnement de niche assumé.

---

## Tableau comparatif synthétique

Codes : ✅ couverture native solide ; ⚠️ couverture partielle ou friction documentée ; ❌ couverture absente ou explicitement déléguée.

| Axe | BMAD-METHOD v6 | GitHub SpecKit | OpenSpec | Agent OS v3 |
|---|---|---|---|---|
| **1. Cycle de vie** | ✅ Vision → maintenance via 5 modules | ⚠️ Spec → implementation, pas de vision/produit | ⚠️ Change-driven, pas de phase produit native | ❌ Standards uniquement, délègue le reste à Claude Code |
| **2. Anti-hallucination / dérive** | ⚠️ Validations multiples mais sur-prescription documentée (#1332) | ✅ Constitution + `[NEEDS CLARIFICATION]` + `/analyze` | ✅ Deltas ADDED/MODIFIED/REMOVED + RFC 2119 | ⚠️ Standards explicites mais pas de gate formel |
| **3. Modèle de spec** | Personas-driven (12+ agents) | Centralisée (constitution + spec/plan/tasks) | Deltas séparés specs/changes/archive | Standards injectables à la demande |
| **4. Brownfield vs Greenfield** | ⚠️ Brownfield supporté via document-project + Test Architect, complexité élevée | ⚠️ Greenfield-first, brownfield documenté comme gap (issues #806, #540, #1173) | ✅ Brownfield-first revendiqué et reconnu (Radar Vol. 34) | ✅ `/discover-standards` extrait de l'existant |
| **5. Intégration Claude Code** | ⚠️ Migration en cours vers SKILL.md, plugins tiers requis | ✅ Slash commands `.claude/commands/` natifs, multi-agent | ✅ Skills + commands pour 23+ outils | ✅ Pensée pour Plan Mode + Skills + Subagents Claude Code |
| **6. Friction pour bug fix mineur** | ❌ Overhead jugé disproportionné par utilisateurs (#2003) | ⚠️ Constitution + 4 phases lourdes pour un changement isolé | ✅ `/opsx:propose` léger, profil *core* à 4 commandes | ✅ Skills à la demande, pas de pipeline imposé |
| **7. Maturité communautaire** | ✅ ~45,8k stars, cadence très élevée mais API instable | ✅ ~89-91k stars, écosystème d'extensions riche | ✅ ~45,2k stars, releases ciblées | ⚠️ ~4,4k stars, communauté plus modeste |
| **8. TDD/BDD natif** | ✅ Module TEA dédié (Test Architect) | ⚠️ Possible via constitution mais non natif | ⚠️ Scénarios GIVEN/WHEN/THEN dans deltas mais pas d'exécution | ❌ Délégué à Claude Code et standards |

Aucune ligne ne donne un gagnant absolu. La grille montre quatre profils différents qui répondent à des contraintes différentes.

---

## Ce que les frameworks ne disent pas

Quatre angles morts récurrents méritent d'être nommés :

**1. La cadence de release est une dette de maintenance déguisée.** BMAD a publié plusieurs versions par mois entre janvier et avril 2026, parfois avec des changements de format de configuration (passage YAML → TOML, abandon de YAML après une introduction brève — PR #2284, #2283). SpecKit a des releases v0.4.5 et v0.5.0 publiées sans assets de templates, cassant `specify init` (issue #2092). Pour une équipe de 500+ devs, chaque migration coûte des dizaines d'heures de support interne non comptabilisées.

**2. Les chiffres d'étoiles ne mesurent pas la qualité.** OpenCode a gagné environ 47k étoiles GitHub en deux mois début 2026 d'après MightyBot. Une étoile témoigne d'une intention, pas d'un usage en production. Le Radar Vol. 34 nomme cet effet *too young to blip* : le marché est saturé de projets maintenus par un seul contributeur travaillant avec un agent de codage.

**3. Aucune RCT publique n'évalue les frameworks SDD.** La METR a mesuré l'impact d'outils d'IA généraux (Cursor + Claude 3.5/3.7 Sonnet), pas l'impact différentiel d'un framework de spec. Les retours d'expérience publiés (EPAM, Mathivanan Mani, Scott Logic, etc.) sont des n=1 méthodologiquement honnêtes mais non généralisables. Les chiffres d'adoption sont auto-sélectionnés.

**4. La *semantic diffusion* contamine les comparatifs.** Le Radar Vol. 34 nomme explicitement le problème : *spec-driven development*, *harness engineering*, *context engineering* sont utilisés de manière interchangeable, parfois pour désigner des choses différentes. Quand un blog présente un framework comme « spec-driven », il faut interroger : qu'est-ce que cela signifie ici, opérationnellement ?

---

## L'hybridation : thèse, objections, conditions de validité

### Thèse

Les angles morts structurels de chaque framework justifient, dans certaines configurations d'équipe, d'envisager une hybridation plutôt qu'un choix exclusif. Concrètement : un standard d'injection (Agent OS) pour les conventions transverses, un mécanisme de delta (OpenSpec) pour les évolutions brownfield, une discipline de constitution (SpecKit) pour les phases greenfield, des personas (BMAD) pour les domaines complexes nécessitant des perspectives multiples.

### Objections

L'hybridation porte cinq risques sérieux qu'il faut nommer.

**Coût d'intégration.** Quatre frameworks signifient quatre `.claude/commands/`, quatre conventions de fichiers, quatre cadences de release. Le risque de collisions de nommage de slash commands (`/spec*`, `/opsx:*`, `/inject-standards`, `/bmad-help`) augmente, et chaque mise à jour devient un événement coordonné.

**Conflit de conventions.** SpecKit pousse une constitution centrale, OpenSpec une séparation specs/changes, BMAD une orchestration multi-agents, Agent OS une diffusion contextuelle de standards. Ces philosophies ne sont pas mutuellement exclusives en théorie, mais peuvent produire en pratique de la spec dupliquée ou contradictoire.

**Dette de maintenance.** À l'échelle de 9 BUs, multiplier les frameworks signifie multiplier les responsabilités d'évangélisation, de formation, de support interne. Le coût de coordination peut excéder le gain marginal.

**Risque d'over-engineering.** L'issue BMAD #2003 vaut comme avertissement général : une méthode élaborée appliquée à un bug fix mineur produit du bruit, pas du signal. La sur-spécification est un anti-pattern reconnu par le Radar Vol. 33, qui parle de *yak shaving* : on descend dans des couches plus complexes que le problème initial.

**Semantic diffusion.** Combiner des frameworks dont les vocabulaires recoupent partiellement (constitution vs standards vs project.md vs CLAUDE.md) augmente le risque qu'une équipe pense parler de la même chose alors que ce n'est pas le cas — précisément le problème nommé par ThoughtWorks Vol. 34.

### Réfutations argumentées et conditions de validité

L'hybridation n'est défendable que sous certaines conditions explicites :

- **Périmètre d'application délimité** : par exemple, BMAD réservé à des projets greenfield à fort enjeu produit, OpenSpec utilisé pour toutes les évolutions de systèmes existants, Agent OS comme couche transversale d'injection de standards. Sans cette délimitation, les frameworks se marchent dessus.
- **Owner unique par BU** : un référent technique dédié pour chaque framework adopté, capable d'absorber les changements de release et de protéger l'équipe des migrations bruyantes.
- **Métrique de friction surveillée** : suivre le temps moyen pour exécuter un bug fix mineur sous le framework, et abandonner si ce temps dépasse un seuil convenu (par exemple, le temps non-framework + 50 %).

Plusieurs *patterns d'hybridation* sont documentés en pratique par la communauté en mai 2026, sans qu'aucun ne s'impose comme canonique :

- **SpecKit + Agent OS** : la constitution de SpecKit absorbe les standards d'Agent OS via `/inject-standards`. Reporté par plusieurs développeurs sur le repo SpecKit comme une combinaison stable, mais avec un risque de redondance.
- **OpenSpec + BMAD-TEA** : OpenSpec gère les deltas de spec, le module TEA de BMAD est isolé pour la stratégie de tests. Documenté par Mathivanan Mani comme un compromis pour des codebases brownfield d'envergure.
- **Agent OS seul, en tant que couche minimaliste** : reflète la posture de Brian Casel — déléguer au maximum à Claude Code natif et n'ajouter qu'une discipline d'injection de standards.

Aucun de ces patterns n'est mesuré expérimentalement. Ils sont des heuristiques d'équipes, pas des résultats.

---

## Limites épistémiques de cette comparaison

Trois limites structurelles méritent d'être tenues présentes à l'esprit.

**Aucune RCT publique sur les frameworks SDD.** L'étude METR mesure des outils d'IA, pas des frameworks de spec. La différence est cruciale : un framework SDD pourrait ralentir encore davantage des développeurs experts (overhead méthodologique sur codebase familière) ou les accélérer (réduction des allers-retours de re-spec). Nous ne savons pas. Toute comparaison fonctionne donc sur des principes plausibles, pas sur des effets mesurés.

**Échantillons d'adoption auto-sélectionnés.** Les retours publiés viennent de praticiens enthousiastes. Les équipes qui ont essayé puis abandonné rarement bloguent. L'observation des étoiles GitHub est encore plus biaisée : un *star* peut signifier « j'aime l'idée », pas « j'utilise en production ».

**Semantic diffusion identifiée par le Radar Vol. 34.** Quand quatre frameworks utilisent le terme *spec-driven development*, mais que SpecKit produit des artefacts Markdown séquentiels, OpenSpec des deltas RFC 2119, BMAD des handoffs entre personas et Agent OS des standards injectables, le terme commun masque des designs très différents. La comparaison axe par axe est une tentative de désambiguïser cette confusion, pas un outil de classement absolu.

À ces limites s'ajoute le fait que **Claude Code lui-même évolue rapidement** : le post-mortem d'avril 2026 d'Anthropic sur des régressions de qualité de Claude Code (effort par défaut, perte d'historique de raisonnement dans des sessions stale, prompt verbosity) montre que la couche sous-jacente n'est pas stable. Toute conclusion sur l'intégration native d'un framework avec Claude Code peut basculer avec un changement de comportement de l'outil hôte.

---

## Conclusion : trois conditions de révision, et une posture méthodologique

Ce que cet article peut défendre méthodologiquement : pour une organisation gérant un parc de 500+ devs sur 9 BUs, le bon raisonnement n'est pas « quel framework adopter », mais **« sous quelles conditions empiriques mon analyse devrait-elle être révisée »**. C'est l'inverse de la posture marketing.

Au moins trois conditions falsifiables justifieraient une révision de cette comparaison :

1. **Publication d'une RCT comparative** entre deux ou plusieurs de ces frameworks, sur des tâches brownfield réelles, mesurant non seulement le temps de complétion (à la METR) mais aussi la qualité du code livré (revue indépendante) et la qualité des specs produites. Si une telle étude montrait qu'un framework produit un gain mesurable et soutenable, l'analyse axe par axe ci-dessus deviendrait secondaire.

2. **Convergence des frameworks sur un format de spec partagé.** Si SpecKit, OpenSpec, BMAD et Agent OS adoptaient un sous-ensemble commun (par exemple un format de delta RFC 2119 standardisé, ou un schéma SKILL.md unifié), la comparaison perdrait sa pertinence en tant que comparaison entre produits, et basculerait vers une comparaison entre dialectes d'un même standard. La migration en cours des modules BMAD vers SKILL.md, et l'absorption croissante de skills dans les workflows Agent OS et OpenSpec, suggèrent un mouvement dans cette direction sans le confirmer.

3. **Effondrement ou consolidation d'un framework majeur.** Si l'un des quatre frameworks cesse d'être maintenu (par exemple, une fragmentation forte de la communauté BMAD autour des forks v6, ou une stagnation prolongée des releases d'Agent OS), la comparaison perd un de ses pôles. Inversement, si un acteur majeur (Anthropic, GitHub, AWS Kiro) absorbe ou rend redondant l'un des frameworks via une fonctionnalité native, le rapport de force change. Les indicateurs à surveiller sont la cadence de release sur 90 jours glissants, le nombre d'issues critiques ouvertes vs fermées, et le ratio de PR communautaires acceptées.

Ces conditions sont descriptives, non prescriptives. Elles ne suggèrent pas de protocole expérimental — elles indiquent ce qu'il faudrait observer pour considérer cette analyse comme dépassée.

Le cadre que je défends est donc strictement méthodologique : exiger des frameworks qu'ils énoncent les trois registres distincts (revendications officielles, retours d'utilisateurs, faits mesurables) ; arrêter une grille avant de comparer ; nommer ses limites épistémiques ; refuser le rôle d'oracle. Le choix d'un framework — ou la décision de ne pas en adopter — relève d'un arbitrage local que je ne peux pas faire pour le lecteur, et que personne ne devrait prétendre faire à sa place.

Reste la question pratique : à compter du 5 mai 2026, dans une organisation distribuée, sur des codebases hétérogènes brownfield/greenfield, avec Claude Code comme outil de référence, je n'ai pas vu d'évidence forte qu'un framework domine. J'ai vu, en revanche, beaucoup d'équipes adopter trop vite et abandonner trop tard. L'hypothèse opérationnelle la plus défendable — testable, falsifiable, modeste — est probablement la suivante : commencer avec le plus léger des candidats compatibles avec le profil de l'équipe, mesurer la friction sur trois mois, et n'ajouter de la mécanique que lorsqu'un problème spécifique le justifie.

Le reste est de la prose.

---

*Sources principales utilisées (paraphrasées, non citées en quotes) : repositories GitHub bmad-code-org/BMAD-METHOD, github/spec-kit, Fission-AI/OpenSpec, buildermethods/agent-os ; ThoughtWorks Technology Radar Vol. 33 (novembre 2025) et Vol. 34 (avril 2026, thoughtworks.com/radar) ; METR « Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity » (arXiv:2507.09089, juillet 2025) et « We are Changing our Developer Productivity Experiment Design » (metr.org/blog/2026-02-24-uplift-update) ; GitHub Blog « Spec-driven development with AI » (Den Delimarsky, septembre 2025) ; Sean Grove, « The New Code », AI Engineer World's Fair (mai 2025) ; Andrej Karpathy et Tobi Lütke sur context engineering (juin 2025) ; documentation Claude Code (code.claude.com/docs/en/sub-agents) ; EPAM Insights sur SpecKit en brownfield ; Mathivanan Mani, comparatif OpenSpec/SpecKit/BMAD (Medium) ; Scott Logic, « Putting Spec Kit Through Its Paces » (novembre 2025).*

*Toutes les observations chiffrées sont datées au 5 mai 2026. Cette baseline périmera rapidement ; le lecteur est invité à recouper systématiquement.*
