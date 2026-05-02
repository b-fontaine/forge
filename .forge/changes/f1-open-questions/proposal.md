# Proposal: f1-open-questions

## Problem

L'**Article III.4 (Anti-Hallucination Protocol)** de la Constitution
Forge impose le marqueur `[NEEDS CLARIFICATION: ...]` dès qu'un agent
ou contributeur ne peut résoudre une ambiguïté. Le marqueur est
intégré inline dans `specs.md`, `design.md` ou `tasks.md` à l'endroit
où la question surgit.

**Mais** — il n'existe **aucun mécanisme structurel** pour :

1. **Inventorier** les questions ouvertes à l'échelle d'un change
   (combien, où, depuis quand)
2. **Tracer leur lifecycle** : ouverte → en discussion → répondue →
   sans suite (won't fix)
3. **Empêcher mécaniquement l'archivage** d'un change qui contient
   encore des `[NEEDS CLARIFICATION:]` non résolus
4. **Auditer rétrospectivement** : pour un change archivé, quelles
   étaient les questions ouvertes et comment ont-elles été tranchées ?
5. **Découvrir transverse** : "donne-moi toutes les questions
   ouvertes du projet" pour une review hebdo

À l'usage, on a vu cette friction au fil des derniers changes (b5.1,
a7, d5, b4) : les décisions tranchées en début de pipeline (proposal §
"Décisions ouvertes — résolues") sont du bon pattern, mais elles
mélangent lieu de **soulèvement** (specs/design) et lieu de
**résolution** (proposal final). Pas de fichier dédié, pas d'audit
trail dans le temps.

Le risque concret : un mainteneur fatigué archive un change avec un
`[NEEDS CLARIFICATION:]` dans `design.md` non résolu, et l'historique
ne porte plus la trace que la question existait.

Module **F.1** sur le plan d'audit (T3 robustesse technique).

## Solution

Livrer un fichier conventionnel `open-questions.md` **par change**,
avec un schéma Markdown structuré, et étendre `verify.sh` pour
**bloquer l'archive** si un change archivé contient encore des
questions `status: open`.

### Anatomie du fichier

```markdown
# Open Questions — <change-name>

## Q-001 : Titre court de la question

- **Status**: open | answered | wontfix
- **Raised in**: specs.md / design.md / proposal.md / discussion #N
- **Raised on**: YYYY-MM-DD
- **Raised by**: [agent or human handle]
- **Reference**: [file:line or section anchor]

### Question

[Texte complet — peut multi-paragraphe, lien vers `[NEEDS CLARIFICATION:]`
inline correspondant]

### Resolution (only if status != open)

- **Resolved on**: YYYY-MM-DD
- **Resolved by**: [maintainer handle]
- **Decision**: [the answer chosen]
- **Rationale**: [why this answer ; trade-offs evaluated]
- **Resolved in**: [where the resolution landed — usually proposal.md
  § "Décisions ouvertes — résolues" + the corresponding
  specs.md/design.md edit]
```

### Lifecycle

- **`open`** — la question est posée, pas encore tranchée. Le change
  ne peut PAS être archivé tant qu'au moins une question est `open`.
- **`answered`** — l'utilisateur ou le mainteneur a tranché. La
  résolution est documentée dans le bloc `### Resolution`. Le
  marqueur `[NEEDS CLARIFICATION:]` inline correspondant est
  remplacé par la réponse. La question reste tracée pour l'audit.
- **`wontfix`** — la question est explicitement laissée sans
  réponse pour ce change (souvent : "scope creep, sera traité dans
  un futur change"). Doit également documenter le rationale.

### Outils

1. **Convention de nommage** : `Q-001`, `Q-002`, ... numéroté dans
   l'ordre de soulèvement, jamais réutilisé même si un Q est annulé.
2. **Discovery** : un nouveau script `bin/forge-questions.sh`
   (ou dans `cli/` plus tard) qui liste toutes les questions
   ouvertes à travers `.forge/changes/*/open-questions.md`.
3. **Gate verify.sh** : nouvelle section qui :
   - Pour chaque change `status: archived`, vérifie qu'aucune
     question `open` ne traîne dans `open-questions.md`.
   - Émet un FAIL bloquant si trouvé.
4. **Linter d'inline** : ajout d'une règle à
   `constitution-linter.sh` qui détecte les marqueurs
   `[NEEDS CLARIFICATION:` dans les changes archivés et émet un
   FAIL (Article III.4 strict enforcement).

### Migration des changes existants

Les changes déjà archivés sur `optim` (b1-*, g1-forge-ci, c1-*, a7-*,
b5-1-*, d5-*, b4-*) **n'ont PAS de `open-questions.md`** car ils ont
été archivés sans cette discipline. C'est OK :

- Le gate verify.sh est **rétrocompatible** : absence de
  `open-questions.md` = pas de questions = pas de FAIL.
- Les nouveaux changes (à partir de F.1+) sont attendus avec
  `open-questions.md` non-vide si questions ouvertes ; absent ou
  empty stub = pas de questions = OK.

## Scope In

- Convention de structure `open-questions.md` documentée dans le
  standard `.forge/standards/global/open-questions.md` (nouveau).
- Template `.forge/templates/open-questions.md` qu'un nouveau
  change peut copier comme starter.
- Update `.forge/templates/change.yaml` (ou `.forge.yaml.tmpl`
  archetype) pour encourager la création de `open-questions.md`.
- Section dans `verify.sh` : "Open Questions Gate" qui scanne
  `.forge/changes/*/open-questions.md` pour les changes archivés
  et fail si questions `status: open` détectées.
- Update `constitution-linter.sh` : règle "no `[NEEDS CLARIFICATION:`
  inline in archived changes" — fail si trouvé dans
  `.forge/changes/<archived-change>/{specs,design,tasks}.md`.
- Script `bin/forge-questions.sh` — list mode (toutes les questions
  ouvertes du projet, format scannable).
- Update `.forge/standards/index.yml` avec le nouveau standard.
- Update `.forge/skills/forge:propose` (le skill existant) pour
  scaffold automatiquement un `open-questions.md` vide à
  l'ouverture du change. **Si** les skills sont user-modifiable
  (à confirmer en design).
- Harness `f1.test.sh` (manifest pattern, ≥ 12 tests structurels +
  fixture-based gate test).
- Update `docs/GUIDE.md` (ou équivalent) avec une section
  "Tracking open questions" courte.
- Update `CHANGELOG.md` `[Unreleased]`, roadmap, plan d'audit.

## Scope Out (Explicit Exclusions)

- **Backfill rétrospectif des changes archivés** : pas de
  reconstruction des `open-questions.md` historiques pour b1-*,
  a7, d5, b4. Effort élevé, valeur ajoutée faible (l'historique
  est tracé dans les commits + `## Décisions ouvertes — résolues`
  des proposals).
- **UI / dashboard / web view** : `forge-questions.sh` reste CLI
  uniquement.
- **Integration Linear / GitHub Issues / Jira** : un fichier
  Markdown auto-suffisant ; les liens vers tickets externes peuvent
  être inclus dans le bloc `### Resolution` mais pas auto-générés.
- **Refactor de `proposal.md`** : la convention "## Décisions
  ouvertes — résolues" continue de coexister. F.1 est complémentaire
  (track lifecycle), pas un remplacement.
- **Auto-detection des marqueurs `[NEEDS CLARIFICATION:]` non
  reportés en `open-questions.md`** : un linter pourrait croiser
  les deux sources, hors scope F.1 (laisse au futur F.5).
- **Notification automatique** (Slack, email) sur questions
  ouvertes depuis > N jours : hors scope, c'est de la plomberie.

## Impact

- **Users affected** :
  - **Mainteneurs Forge** — gagnent un mécanisme structurel pour
    auditer les ambiguïtés à travers les changes.
  - **Contributeurs externes** — savent où porter une question
    ouverte (un fichier dédié, pas un comment perdu en specs).
  - **Adopteurs Forge** — la même discipline s'applique à leurs
    propres changes (`open-questions.md` dans
    `.forge/changes/<their-change>/`).
- **Technical impact** :
  - 1 nouveau standard, 1 template, 1 nouveau script bash, 2 lignes
    dans `verify.sh`, 1 règle dans `constitution-linter.sh`, 1
    skill update (si possible), 1 harness.
  - Aucun TS modifié (cohérent avec la discipline B.5.1 ABI).
  - Pas de bump Constitution requis (Article III.4 est déjà la base
    légale ; F.1 ajoute la mécanique).
- **Dependencies** :
  - **A.7** (✅ livré) — `verify.sh` a déjà la structure pour
    accueillir un nouveau gate.
  - **D.5** (✅ livré) — Article XII Governance encadre les
    décisions ouvertes (qui les tranche).
  - Aucune dépendance bloquante.

## Constitution Compliance

- **Article I (TDD)** : harness `f1.test.sh` RED→GREEN. Tests L1
  (présence fichiers + grep sections) + tests L2 (fixture-based :
  créer un faux change archivé avec une question `open`, vérifier
  que `verify.sh` fail).
- **Article II (BDD)** : 3-5 scénarios documentaires (raise question,
  resolve question, archive blocked by open question, transverse
  list).
- **Article III (Specs Before Code)** : pipeline complet.
- **Article III.4 (Anti-hallucination)** : ce change EST le
  durcissement opérationnel de l'Article III.4. F.1 n'invente rien,
  il mécanise une discipline qui était laissée au bon vouloir des
  contributeurs.
- **Article IV (Delta-based)** : ADDED-only namespace `FR-OQ-*`
  (open-questions). Pas de modification d'un FR existant.
- **Article V (Process Gates)** : ajoute un nouveau gate
  (verify.sh "Open Questions Gate" + linter rule). Cohérent.
- **Article XII (Governance)** : `constitution_version: "1.1.0"`.

---

## Décisions ouvertes — à trancher avant `/forge:specify`

Conformément à la nouvelle convention que ce change AMÈNE, je
soulève ici en proposal et propose des recommandations :

1. **Question Q-IDs : `Q-001` séquentiel par change, ou
   `OQ-NNN` numérotation globale ?**
   - **Recommandation** : `Q-001` séquentiel par change.
     Plus simple, pas de coordination cross-change. Si on veut une
     vue globale, `forge-questions.sh` ajoute le préfixe
     `<change>:Q-001` automatiquement.
2. **Anti-hallucination linter — `[NEEDS CLARIFICATION:]` interdit
   dans `archived` SEULEMENT, ou aussi dans `implemented` ?**
   - **Recommandation** : interdit à partir de **`implemented`** —
     un change implémenté qui contient encore `[NEEDS CLARIFICATION:]`
     est un signal d'incohérence (du code a été écrit alors qu'une
     question était ouverte). En pratique, le change devrait
     redescendre à `planned` pour répondre, puis remonter.
3. **Skill `forge:propose` — scaffold automatique de
   `open-questions.md` vide ?**
   - **Recommandation** : OUI. Le skill crée déjà `.forge.yaml`
     et `proposal.md` ; ajouter `open-questions.md` (vide stub)
     est cohérent. Si le skill ne peut pas être modifié (skill
     d'utilisateur), fallback : le standard documente la création
     manuelle.

Ces 3 décisions seront tranchées avant `/forge:specify`. Si tu
valides les recommandations, dis-le et j'enchaîne.

## Décisions ouvertes — résolues 2026-04-30

1. **Q-IDs format** → `Q-001` séquentiel **par change**, jamais réutilisé
   même si Q est annulé. `forge-questions.sh` préfixe `<change>:Q-NNN`
   pour la vue globale.
2. **Linter `[NEEDS CLARIFICATION:]`** → interdit à partir du status
   **`implemented`** (un change qui a du code et encore une question
   ouverte est un signal d'incohérence ; il doit redescendre à
   `planned` pour répondre).
3. **Skill `forge:propose` scaffold auto** → **OUI** si techniquement
   possible. Le skill `/forge:propose` génère désormais aussi un stub
   `open-questions.md` vide à côté de `.forge.yaml` + `proposal.md`.
   Si modification skill bloquée par contrainte technique, fallback
   doc manuelle dans le standard.
