# Specs: f1-open-questions

**Namespace** : `FR-OQ-*` / `NFR-OQ-*` (nouveau, sera consolidé dans
`.forge/specs/open-questions.md` à l'archive).

**Constitution** : v1.1.0 (pas d'amendement requis ; F.1 mécanise
l'Article III.4 existant).

**Décisions tranchées** (proposal § "Décisions ouvertes — résolues") :
- Q-IDs séquentiels par change (`Q-001`, `Q-002`, ...).
- Linter `[NEEDS CLARIFICATION:]` interdit dès status `implemented`.
- Skill `/forge:propose` scaffold un `open-questions.md` stub.

---

## ADDED Requirements

### Cluster 1 — Standard

#### FR-OQ-001 — Standard `.forge/standards/global/open-questions.md`

Le fichier MUST exister et contenir au minimum les sections H2 suivantes :
- `## Purpose`
- `## File Location and Lifecycle`
- `## Question Schema`
- `## Status Enum`
- `## Resolution Block`
- `## Verify Gate`
- `## Linter Rule`
- `## Discovery (forge-questions.sh)`

Le fichier MUST inclure ≥ 3 **Interdictions** explicites :
- Pas de modification d'une question `answered` (immutable history).
- Pas de réutilisation d'un Q-NNN même si la question est `wontfix`.
- Pas de `[NEEDS CLARIFICATION:]` inline dans un change `implemented` ou `archived`.

**Test L1** : présence fichier + comptage H2 + comptage `Interdiction` ≥ 3.

#### FR-OQ-002 — Indexed in `.forge/standards/index.yml`

`.forge/standards/index.yml` MUST avoir une entrée `global/open-questions`
avec triggers : `open-questions`, `NEEDS CLARIFICATION`, `Q-001`, `clarification`,
`anti-hallucination`, `Article III.4`.

**Test L1** : `grep -q 'open-questions' index.yml`.

---

### Cluster 2 — Schema convention

#### FR-OQ-003 — Location

Pour un change `<name>`, le fichier de questions ouvertes MUST vivre à
`.forge/changes/<name>/open-questions.md`. Pas d'alternative (un sous-dossier,
un autre nom, un fichier global) acceptée.

#### FR-OQ-004 — Required sections per question

Chaque question dans `open-questions.md` MUST exposer un titre H2
de la forme `## Q-NNN: <Title>` puis les champs structurés suivants
sous forme de bullet-list :

- `**Status**: open | answered | wontfix`
- `**Raised in**: <file or anchor>`
- `**Raised on**: YYYY-MM-DD`
- `**Raised by**: <agent or human handle>`
- `**Reference**: <optional, file:line or section anchor>`

Suivi d'une sous-section H3 `### Question` avec le texte complet.

Si `Status != open`, MUST inclure également une sous-section H3
`### Resolution` avec :
- `**Resolved on**: YYYY-MM-DD`
- `**Resolved by**: <handle>`
- `**Decision**: <the answer chosen>`
- `**Rationale**: <why ; trade-offs>`
- `**Resolved in**: <file/section where the resolution landed>`

**Test L2** : créer un fixture avec une question valide, valider la présence des champs ; créer un fixture avec champs manquants, valider qu'un linter detector signal le problème.

#### FR-OQ-005 — Q-NNN format

Q-IDs MUST suivre `Q-` + 3 digits (zéro-padded), commençant à `Q-001`.
Numérotation séquentielle PAR CHANGE, jamais réutilisée même si la
question est annulée. Formellement : regex `^Q-[0-9]{3}$`.

**Test L2** : créer une question Q-002 sans Q-001 — devrait être détecté comme suspect (warning, pas fail). Q-001 puis Q-001 (doublon) — fail.

#### FR-OQ-006 — Status enum

Status MUST être exactement l'un de : `open`, `answered`, `wontfix`. Tout autre valeur fail le linter.

#### FR-OQ-007 — Backward compatibility

Un change SANS fichier `open-questions.md` MUST être traité comme "aucune question ouverte" par le gate `verify.sh`. Pas de FAIL pour les changes archivés avant F.1 (b1-*, g1, c1, a7, b5-1, d5, b4).

---

### Cluster 3 — Template

#### FR-OQ-008 — Template stub

`.forge/templates/open-questions.md.tmpl` MUST exister, contenir l'en-tête
`# Open Questions — {{change-name}}`, un commentaire pédagogique court (≤ 10
lignes) expliquant la convention, et zéro question pré-remplie (le change
nouveau-né n'a pas de questions par défaut).

**Test L1** : présence fichier + grep `Open Questions` dans le titre.

---

### Cluster 4 — verify.sh gate

#### FR-OQ-009 — Section "Open Questions Gate"

`.forge/scripts/verify.sh` MUST inclure une nouvelle section dédiée intitulée
explicitement `── Open Questions Gate ──` (ou équivalent) qui scanne
`.forge/changes/*/open-questions.md`.

#### FR-OQ-010 — FAIL on archived change with open status

Pour chaque change où `.forge/changes/<name>/.forge.yaml` a `status:
archived` ET `.forge/changes/<name>/open-questions.md` contient
au moins une question `**Status**: open`, le gate MUST émettre un
FAIL bloquant.

**Test L2** : fixture-based — créer un faux change archivé avec une question
`open` dans tmpdir, lancer verify.sh, vérifier exit ≠ 0 + message.

#### FR-OQ-011 — PASS on archived without questions file

Si un change archivé n'a PAS de `open-questions.md`, le gate PASS sans warning
(rétrocompat des changes archivés avant F.1).

**Test L2** : fixture sans le fichier, verify.sh PASS sur cette section.

#### FR-OQ-012 — Skip-guard examples/

Cohérent avec FR-GL-026 (skip-guard `examples/` quand FORGE_REPO_DETECTED=1) :
le gate NE DOIT PAS scanner `examples/<example>/.forge/changes/*/open-questions.md`
(les exemples ont leur propre verify.sh et gèrent leurs propres questions).

**Test L1** : grep `is_under_examples` dans la nouvelle section verify.sh.

---

### Cluster 5 — constitution-linter rule

#### FR-OQ-013 — Linter rule "no NEEDS CLARIFICATION in implemented/archived"

`.forge/scripts/constitution-linter.sh` MUST inclure une nouvelle règle qui :
- Lit `.forge/changes/<name>/.forge.yaml` pour chaque change.
- Si `status` ∈ {`implemented`, `archived`}, scanne les fichiers
  `proposal.md`, `specs.md`, `design.md`, `tasks.md` à la recherche de
  `[NEEDS CLARIFICATION:` (sans le `]` final pour matcher les variantes).
- Émet un FAIL par occurrence trouvée, listant `<change>:<file>:<line>`.

#### FR-OQ-014 — Linter rule output format

L'output MUST être consommable par les agents : un FAIL par ligne,
format `FAIL <change>:<file>:<line>: NEEDS CLARIFICATION inline detected`.

**Test L2** : fixture-based — créer un faux change implementé avec un
`[NEEDS CLARIFICATION:]` dans specs.md, lancer linter, vérifier fail + format.

---

### Cluster 6 — discovery script

#### FR-OQ-015 — `bin/forge-questions.sh` exists

Le fichier MUST exister, être exécutable, et exposer le mode par défaut :
lister toutes les questions `**Status**: open` à travers
`.forge/changes/*/open-questions.md`.

#### FR-OQ-016 — Output format

Format scannable, une question par ligne :
`<change>:Q-NNN  <Title>  (raised <YYYY-MM-DD> by <handle>)`

Trier par `Raised on` (asc).

#### FR-OQ-017 — Filter flag

`bin/forge-questions.sh --change <name>` filtre sur un seul change.
`bin/forge-questions.sh --status <open|answered|wontfix>` filtre par status.

**Test L2** : fixture-based — créer 3 changes avec questions variées,
lancer le script, vérifier output trié + filtres OK.

---

### Cluster 7 — Skill scaffold

#### FR-OQ-018 — Skill `forge:propose` étendu

Le skill `forge:propose` MUST scaffolder un fichier `open-questions.md`
stub à côté de `.forge.yaml` et `proposal.md`. Le stub contient l'en-tête
`# Open Questions — <name>` et un commentaire `<!-- No open questions yet. -->`.

**Si** la modification du skill est techniquement bloquée (skill embarqué
non-modifiable, etc.), fallback : le standard `open-questions.md` documente
la création manuelle du stub par le mainteneur. Le test L1 couvre les deux
cas (skill modifié OU fichier `templates/open-questions.md.tmpl` documenté
dans le standard avec instruction de copie).

**Test L1** : grep dans le skill body OU grep dans le standard pour
l'instruction de scaffold.

---

### Cluster 8 — Documentation

#### FR-OQ-019 — Docs reference

`docs/GUIDE.md` (ou un nouveau `docs/OPEN_QUESTIONS.md` selon où la doc
existante vit le mieux) MUST inclure une section "Tracking Open Questions"
de ≥ 30 lignes, expliquant : pourquoi (Article III.4), quand soulever
(au plus tôt), comment résoudre, comment lister via
`bin/forge-questions.sh`.

**Test L1** : grep `Open Questions` ou équivalent dans `docs/GUIDE.md`.

---

### Cluster 9 — Harness

#### FR-OQ-020 — Harness `f1.test.sh`

`.forge/scripts/tests/f1.test.sh` MUST :
- Suivre le pattern manifest (un test par FR-OQ-NNN, ≥ 15 tests).
- Inclure ≥ 3 tests L2 fixture-based (verify.sh gate fail sur question
  `open`, verify.sh gate PASS sur absence, linter fail sur `[NEEDS
  CLARIFICATION:]` dans `implemented`).
- Être enregistré dans `.github/workflows/forge-ci.yml` job `harness`.
- Découvert automatiquement par `verify.sh`.

**Test L1** : `[[ -x f1.test.sh ]]` + comptage MANIFEST + grep dans CI workflow.

---

### Cluster 10 — Périmètre négatif

#### FR-OQ-021 — Aucune touch interdite

Le change f1-open-questions NE DOIT PAS modifier :
- `cli/src/**` (zéro édition TS).
- `cli/package.json`, `cli/package-lock.json`.
- `.forge/constitution.md` (pas d'amendement).
- Les changes archivés (immuables).
- Les schémas d'archetypes ou leurs templates.

**Test L2** : `git diff --name-only <baseline-parent-of-first-f1-commit>...HEAD`
ne liste rien sous ces paths.

#### FR-OQ-022 — Pas de backfill rétrospectif

Les changes archivés sur `optim` antérieurs à F.1 (b1-*, g1, c1, a7,
b5-1, d5, b4) NE DOIVENT PAS recevoir de `open-questions.md`
rétrospectivement. F.1 trace le futur, pas le passé.

**Test L1** : `find .forge/changes/{b1*,g1*,c1*,a7*,b5*,d5*,b4*}/open-questions.md`
retourne 0 fichier après archive de F.1.

---

## Non-Functional Requirements

### NFR-OQ-001 — Pas de nouvelle dépendance

F.1 NE DOIT PAS ajouter de dépendance npm ni de package système au-delà de
ce qui est déjà disponible (bash, grep, awk, find, python3 si déjà utilisé
dans verify.sh).

### NFR-OQ-002 — Performance verify.sh

La nouvelle section "Open Questions Gate" MUST exécuter en < 500ms sur le
projet Forge actuel (10 changes archivés). Mesure : `time bash verify.sh`
avant/après — delta ≤ 500ms.

### NFR-OQ-003 — Backward compatibility hard

Aucun change archivé existant ne MUST devenir `verify.sh` FAIL après
livraison de F.1. Vérifié explicitement par `verify.sh` global passant à
80 PASS / 0 FAIL post-F.1.

### NFR-OQ-004 — 100 % FR couverts par tests

Chaque FR-OQ-NNN MUST avoir au moins 1 test L1 ou L2 dans `f1.test.sh`.
Pas de FR sans assertion automatisée.

---

## Acceptance Criteria (BDD)

### Scénario 1 — Soulever une question pendant `/forge:specify`

```gherkin
Given a maintainer is writing specs.md for a new change
When they encounter an ambiguity
Then they emit `[NEEDS CLARIFICATION: <question>]` inline AND
And open `.forge/changes/<name>/open-questions.md`
And add a Q-NNN block with Status: open + Raised in: specs.md + Raised on: today
And the change CANNOT be archived until this question is resolved
```

### Scénario 2 — Résoudre une question

```gherkin
Given a change has Q-001 with Status: open
When the maintainer or user provides a decision
Then the maintainer flips Status to "answered"
And adds a ### Resolution block with Decision + Rationale + Resolved in
And replaces the inline [NEEDS CLARIFICATION:] in specs.md/design.md with the resolved text
And the question is preserved in open-questions.md (immutable history)
```

### Scénario 3 — verify.sh blocks archive on open question

```gherkin
Given a change has Status: archived in .forge.yaml
And open-questions.md contains a Q-NNN with Status: open
When the maintainer runs bash .forge/scripts/verify.sh
Then verify.sh emits "FAIL: <change> has 1 open question(s) but is archived"
And exits with non-zero code
```

### Scénario 4 — constitution-linter blocks NEEDS CLARIFICATION in implemented

```gherkin
Given a change has Status: implemented in .forge.yaml
And specs.md contains "[NEEDS CLARIFICATION: which library?]"
When the maintainer runs bash .forge/scripts/constitution-linter.sh
Then linter emits "FAIL <change>:specs.md:<line>: NEEDS CLARIFICATION inline detected"
And exits with non-zero code
```

### Scénario 5 — Transverse list of all open questions

```gherkin
Given the project has 5 changes, 2 with open questions
When the maintainer runs bash bin/forge-questions.sh
Then the output lists 4 open questions (2 from each of the 2 changes)
And lines are formatted as <change>:Q-NNN  <Title>  (raised <date> by <handle>)
And lines are sorted by Raised on ascending
```

### Scénario 6 — Filter by change

```gherkin
Given the project has multiple changes with open questions
When the maintainer runs bash bin/forge-questions.sh --change f1-open-questions
Then only questions belonging to f1-open-questions are listed
```

---

## Anti-Hallucination Pass

| FR | Testable ? | Ambigu ? | Conforme Constitution ? |
|---|---|---|---|
| FR-OQ-001..002 (standard + index) | ✅ presence + grep | ❌ | ✅ |
| FR-OQ-003..007 (schema convention) | ✅ regex + structure | ❌ | ✅ |
| FR-OQ-008 (template) | ✅ presence | ❌ | ✅ |
| FR-OQ-009..012 (verify.sh gate) | ✅ L2 fixture | ❌ | ✅ Article V |
| FR-OQ-013..014 (linter rule) | ✅ L2 fixture + format | ❌ | ✅ Article III.4 |
| FR-OQ-015..017 (discovery script) | ✅ L2 fixture + flags | ❌ | ✅ |
| FR-OQ-018 (skill scaffold) | ✅ grep ; OR fallback documented | ❌ | ✅ |
| FR-OQ-019 (docs) | ✅ presence | ❌ | ✅ |
| FR-OQ-020 (harness) | ✅ presence + manifest | ❌ | ✅ Article I |
| FR-OQ-021..022 (negative scope) | ✅ git diff | ❌ | ✅ |

**Aucun `[NEEDS CLARIFICATION:]` restant.** Les 3 décisions ouvertes du
proposal ont été tranchées par utilisateur 2026-04-30.

---

## Constitution Compliance Summary

- **Article I (TDD)** : harness `f1.test.sh` RED→GREEN. ✅
- **Article II (BDD)** : 6 scénarios documentés ci-dessus. ✅
- **Article III (Specs Before Code)** : pipeline complet. ✅
- **Article III.4 (Anti-hallucination)** : F.1 mécanise précisément cette discipline. Méta-cohérence : ce change EST l'application opérationnelle de l'article qu'il renforce. ✅
- **Article IV (Delta-based)** : ADDED-only namespace `FR-OQ-*`. ✅
- **Article V (Process Gates)** : F.1 ajoute 1 nouveau gate (verify.sh "Open Questions") + 1 règle linter. ✅
- **Article VI / VII / VIII / IX / XI** : NA. ✅
- **Article X (Quality)** : NFR-OQ-002 (perf verify.sh), NFR-OQ-003 (backward compat) sont des qualités structurelles. ✅
- **Article XII (Governance)** : `constitution_version: "1.1.0"`. Pas d'amendement requis. ✅

---

**Status** : `specified`. Next : `/forge:design f1-open-questions`.
