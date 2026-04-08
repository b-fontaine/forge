# Guide de Contribution — Forge

---

## Philosophie de Contribution

Forge se développe selon ses propres principes. Ce n'est pas une ironie — c'est une nécessité. Un framework qui préconise les specs et le TDD mais qui accepte des contributions non-spécifiées et sans tests serait incohérent.

Toute contribution DOIT :
- Passer par le pipeline Forge (Proposal → Specs → Design → Tasks → TDD)
- Respecter la constitution (11 articles, sans exception)
- Inclure des tests — même pour du Markdown, sous forme de scénarios de validation documentés et exécutés

Si vous contribuez à Forge, vous utilisez Forge pour contribuer à Forge. C'est le meilleur test d'intégration possible.

---

## Ajouter un Standard

Un standard est une règle technique injectée dynamiquement dans le contexte de l'agent approprié au moment opportun.

### Les 5 étapes

1. **Créer le fichier** — `.forge/standards/<domaine>/<nom>.md` avec le format requis (voir ci-dessous)

2. **Enregistrer dans le catalogue** — Ajouter une entrée dans `.forge/standards/index.yml` :
   ```yaml
   - id: <domaine>-<nom>
     path: standards/<domaine>/<nom>.md
     triggers:
       - <mot-clé-1>
       - <mot-clé-2>
     scope: <implementation|design|review|all>
     priority: <high|medium|low>
   ```

3. **Choisir des triggers précis** — Les triggers doivent être suffisamment spécifiques. `flutter` est trop large. `riverpod`, `provider`, `bloc` sont précis. Des triggers trop généraux polluent le contexte avec des standards non-pertinents.

4. **Tester** — Créer un scénario de test : lancer `/forge:implement` dans un contexte qui devrait déclencher le standard, et vérifier que le standard est bien injecté et que l'agent s'y conforme.

5. **Documenter** — Expliquer dans le fichier du standard : pourquoi cette règle existe, dans quel contexte elle s'applique, et ce qui se passe si on ne la respecte pas.

### Format requis pour un standard

```markdown
# Standard: [Nom]

## Scope
[À quoi s'applique ce standard — domaine, contexte, situations]

## Rules
[Règles avec exemples concrets de code ou de comportement attendu]

## Anti-patterns
[Ce qu'il ne faut PAS faire — avec exemples et explication du problème]
```

La section "Anti-patterns" est fortement recommandée. Un LLM qui voit "ne pas faire X" est moins susceptible de faire X qu'un LLM qui voit seulement "faire Y".

---

## Ajouter un Agent

Un agent est un persona persistant avec une expertise, un style de communication et des règles de comportement spécifiques.

### Les 4 étapes

1. **Créer le fichier** — `.claude/agents/<équipe>/<nom>.md`

2. **Sections obligatoires** :
   - `## Persona` — Name (mythologique), Role (titre), Style (comment il communique)
   - `## Purpose` — Une phrase décrivant pourquoi cet agent existe
   - `## Expertise` — Domaines de compétence
   - `## Workflow` — Comment il approche les tâches (étapes)
   - `## Rules` — Règles non-négociables (comportements interdits, comportements obligatoires)

3. **Référencer depuis l'orchestrateur** — L'agent doit être invocable :
   - Équipe Flutter → référencer depuis `hera.md`
   - Équipe Rust → référencer depuis `vulcan.md`
   - Transversal → référencer depuis `forge.md`

4. **Convention de nommage** :
   - Flutter team → Mythologie grecque (Hera, Athena, Spartan, Apollo, Hephaestus...)
   - Rust team → Latin/Romain (Vulcan, Ferris, Centurion, Tribune, Terminal...)
   - Transversal → Mythologie grecque ou latine (Forge, Clio, Oracle, Atlas, Aegis, Panoptes...)

---

## Ajouter une Commande

Une commande slash est un fichier Markdown dans `.claude/commands/forge/` que Claude Code expose via `/forge:<nom>`.

### Les 3 étapes

1. **Créer le fichier** — `.claude/commands/forge/<nom>.md`

   Format obligatoire :
   ```markdown
   # /forge:<nom> — Description courte

   ## Purpose
   [Pourquoi cette commande existe]

   ## Process
   1. [Première étape]
   2. [Deuxième étape]
   ...

   ## Output
   [Ce que la commande produit]
   ```

2. **Intégrer dans la détection d'état** — Si la commande fait partie du cycle principal, mettre à jour la logique de détection dans `forge.md` pour que `/forge` puisse router vers elle automatiquement.

3. **Documenter** — Mettre à jour :
   - `README.md` — tableau des commandes
   - `docs/GUIDE.md` — section commandes et/ou cycle de développement
   - `docs/ARCHITECTURE.md` — structure annotée si un nouveau fichier est ajouté

---

## Ajouter un Schema

Un schema définit un pipeline de phases personnalisé pour un type de projet.

### Les 2 étapes

1. **Créer le fichier** — `.forge/schemas/<nom>/schema.yaml` :
   ```yaml
   name: <nom>
   description: <description>
   phases:
     - id: vision
       command: /forge:vision
       required: true
     - id: explore
       command: /forge:explore
       required: false
     # ... autres phases
   gates:
     constitution: strict      # Ne jamais assouplir
     tdd: mandatory            # Ne jamais rendre optionnel
   tools:
     # Configurations spécifiques (golden tests, clippy, etc.)
   ```

2. **Tester avec un projet réel** — Créer un projet de test depuis zéro, appliquer le schema, et parcourir l'intégralité du pipeline. Documenter les résultats dans la PR.

**Contrainte absolue** : Un schema ne peut pas rendre le TDD optionnel. `tdd: optional` est une violation de la constitution — la PR sera rejetée.

---

## Modifier la Constitution

La constitution est la loi suprême de Forge. Elle contient 11 articles qui définissent les règles non-négociables du framework. La modifier est un acte grave.

### Processus d'amendement

1. **Justification documentée** — Rédiger un document explicite : quel article est concerné, pourquoi la règle actuelle pose problème, quelle modification est proposée, quel impact sur les projets existants.

2. **Approbation humaine** — Le propriétaire du projet (mainteneur principal) doit approuver explicitement. Pas de merge automatique, pas de vote par agents.

3. **Entrée dans le registre d'amendements** — Ajouter l'amendement dans le tableau des amendements en bas de `constitution.md` avec date, auteur, justification résumée.

4. **Revue d'impact** — Analyser toutes les specs existantes dans `.forge/specs/` pour identifier les violations potentielles induites par le changement.

Ne pas modifier la constitution à la légère. La stabilité de la constitution est une fonctionnalité, pas une contrainte arbitraire.

---

## Conventions

### Nommage des Agents

| Équipe | Panthéon | Exemples |
|--------|----------|---------|
| Flutter | Grec | Hera, Athena, Spartan, Apollo, Hephaestus, Hermes, Iris, Argus, Prometheus, Nemesis |
| Rust | Latin/Romain | Vulcan, Ferris, Centurion, Tribune, Terminal, Sentinel |
| Transversal | Grec ou Latin | Forge, Clio, Oracle, Socrates, Atlas, Panoptes, Aegis, Heracles |

### Format des Standards

- Section "Scope" obligatoire — sans elle, les triggers sont impossibles à calibrer
- Exemples de code concrets — les règles abstraites sont moins efficaces
- Section "Anti-patterns" recommandée — les contre-exemples ancrent les règles
- Pas de TODOs dans les standards livrés — un standard incomplet est pire qu'un standard inexistant

### Format des Commandes

- Titre `# /forge:<nom> — Description` obligatoire
- Sections : Purpose, Process (étapes numérotées), Output
- Process toujours numéroté — les LLMs suivent mieux les étapes ordonnées explicitement

---

## Tests du Framework

Avant de soumettre une contribution, exécuter les 5 scénarios de validation suivants et documenter les résultats dans la PR.

### Scénario 1 — Nouveau projet Flutter vide

1. Créer un répertoire vide
2. Copier Forge
3. Lancer `/forge:init`
4. Lancer `/forge:vision`
5. Lancer `/forge:new feature-test`
6. **Vérifier** : la constitution est respectée à chaque étape, les fichiers appropriés sont créés dans `.forge/changes/feature-test/`

### Scénario 2 — Projet Rust existant

1. Utiliser un projet Rust existant avec du code
2. Copier Forge
3. Lancer `/forge:init`
4. Lancer `/forge:discover`
5. **Vérifier** : les conventions existantes sont capturées dans `.forge/standards/`, le fichier `index.yml` est mis à jour

### Scénario 3 — Cycle TDD complet

1. Depuis un état avec un plan de tâches (`tasks.md` existant)
2. Lancer `/forge:implement <nom>`
3. **Vérifier** : l'agent enforce RED (test écrit et échouant) avant GREEN, REFACTOR est proposé après GREEN, aucune étape n'est sautée

### Scénario 4 — Violation de la constitution

1. Créer manuellement un fichier `design.md` qui viole un article de la constitution (ex : design sans tests prévus)
2. Lancer `/forge:review <nom>`
3. **Vérifier** : le gate BLOQUE explicitement, l'agent cite l'article violé, il refuse de continuer sans correction

### Scénario 5 — Archive de delta specs

1. Depuis un état avec une review passée
2. Lancer `/forge:archive <nom>`
3. **Vérifier** : les specs delta sont fusionnées dans `.forge/specs/`, le dossier de changement est marqué DONE, un résumé apparaît dans le journal du projet

---

## Roadmap du Framework

### Court terme — Corrections et complétions

- Templates d'ADR pour les décisions d'internationalisation (i18n)
- Runbooks d'observabilité par défaut (SigNoz, ELK, Prometheus)
- Schema `mobile-only` optimisé pour Firebase sans backend custom

### Moyen terme — Nouvelles fonctionnalités

- Schema `microservices` pour projets multi-services avec gestion des contrats inter-services
- Agent `DataEngineer` pour pipelines de données (ingestion, transformation, qualité)
- Intégration Linear / Jira pour traçabilité bidirectionnelle entre tasks Forge et tickets
- Schema `mobile-first` avec priorité iOS/Android et patterns de navigation natifs

### Long terme — Évolution architecturale

- Métriques de vélocité — cycle time par phase, identification des goulots d'étranglement
- Dashboard de santé du projet — couverture de tests, dette technique, âge des specs
- Export des specs vers formats standards (OpenAPI pour REST, AsyncAPI pour événements)
- Support multi-LLM — différents agents sur différents modèles selon leurs forces respectives
