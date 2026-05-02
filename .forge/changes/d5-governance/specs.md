# Specs: d5-governance

**Namespace** : `FR-GOV-*` (nouveau, sera consolidé dans `.forge/specs/governance.md` à l'archive).

**Constitution amendée** : `1.0.0` → `1.1.0` (semver mineur, ajout sans breaking change).

---

## ADDED Requirements

### FR-GOV-001 : Existence de `GOVERNANCE.md` à la racine

Un fichier `GOVERNANCE.md` MUST exister à la racine du dépôt Forge.

Le fichier MUST être au format Markdown (`.md`).

Le fichier MUST être enregistré dans Git (suivi par version control).

Le fichier MUST avoir une taille minimale de 50 lignes (preuve d'une rédaction substantielle, pas un placeholder).

**Test L1** : `[[ -f GOVERNANCE.md ]] && [[ $(wc -l < GOVERNANCE.md) -ge 50 ]]`.

---

### FR-GOV-002 : Sections obligatoires de `GOVERNANCE.md`

`GOVERNANCE.md` MUST contenir au minimum les sections H2 suivantes (titres exacts) :

- `## Maintainers`
- `## Roles and Responsibilities`
- `## Decision Making`
- `## Amendment Process`
- `## Release Process`
- `## Code of Conduct`
- `## Contact`

L'ordre des sections SHOULD être celui ci-dessus pour la cohérence avec les standards OSS.

**Test L1** : `grep -c '^## Maintainers$' GOVERNANCE.md` retourne `1` pour chaque titre listé.

---

### FR-GOV-003 : Section `Maintainers` — contenu requis

La section `## Maintainers` de `GOVERNANCE.md` MUST :

- Lister nominativement le BDFL actuel : `Benoit Fontaine`
- Indiquer son rôle : `BDFL (Benevolent Dictator For Life — current phase ≤ 1.0)`
- Indiquer son handle GitHub : `@bfontaine`
- Lister les co-mainteneurs (vide dans cette première version, mais le tableau MUST être présent comme structure pour les futurs ajouts)

**Test L1** : `grep -q 'Benoit Fontaine' GOVERNANCE.md` ET `grep -q '@bfontaine' GOVERNANCE.md` ET `grep -q -i 'BDFL' GOVERNANCE.md`.

---

### FR-GOV-004 : Section `Roles and Responsibilities` — contenu requis

La section `## Roles and Responsibilities` MUST définir explicitement :

- **Qui peut merger une PR sur `main`** : le BDFL ou un co-mainteneur autorisé
- **Qui publie les releases** : le BDFL ou un co-mainteneur autorisé, suivant le processus défini en `Release Process`
- **Qui ratifie les amendements de Constitution** : le BDFL en dernier ressort (Phase actuelle), ou la majorité du comité (Phase mature)
- **Qui modère le `CODE_OF_CONDUCT.md`** : le BDFL via l'email de contact

Chaque responsabilité MUST être présentée sous forme de bullet ou de tableau scannable (pas de prose noyée).

**Test L1** : la section MUST contenir au minimum 4 bullets (lignes commençant par `- ` ou `* `) ou 4 lignes de tableau dans son corps.

---

### FR-GOV-005 : Section `Decision Making` — modèle BDFL-with-fallback

La section `## Decision Making` MUST documenter :

- **Phase actuelle (Constitution `1.x` ou tant que < 5 contributeurs réguliers)** : modèle BDFL strict, le BDFL tranche.
- **Phase mature (déclenchée par amendement explicite de Constitution)** : modèle « comité de mainteneurs, 3 à 7 membres, vote à la majorité simple, BDFL conserve un veto sur les amendements de Constitution uniquement ».
- **Conditions de transition** : amendement de Constitution requis pour passer de Phase actuelle à Phase mature.

La section MUST mentionner explicitement les deux phrases-clés `Phase actuelle` ET `Phase mature` (en français ou anglais : `Current phase` / `Mature phase` acceptés).

**Test L1** : `grep -E -i 'current phase|phase actuelle' GOVERNANCE.md` ET `grep -E -i 'mature phase|phase mature' GOVERNANCE.md`.

---

### FR-GOV-006 : Section `Amendment Process` — pas-à-pas explicite

La section `## Amendment Process` MUST documenter le processus de modification de la Constitution sous forme d'étapes numérotées (≥ 4 étapes), couvrant au minimum :

1. **Soumission** : ouverture d'un change Forge via `/forge:propose <name>` ciblant `.forge/constitution.md`
2. **Discussion publique** : durée minimale **7 jours** sur GitHub Discussions ou la PR dédiée
3. **Décision** : ratification par le BDFL (Phase actuelle) ou vote majoritaire du comité (Phase mature)
4. **Application** : ajout d'une ligne dans la table « Amendments » de la Constitution + bump `constitution_version` selon semver (patch pour clarification, mineur pour ajout d'article, majeur pour suppression/breaking d'article existant)

La durée minimale de discussion (7 jours) MUST être mentionnée explicitement.

**Test L1** : `grep -E '7 (jours|days)' GOVERNANCE.md` ET la section MUST contenir au moins 4 lignes commençant par `1.`, `2.`, `3.`, `4.`.

---

### FR-GOV-007 : Section `Release Process` — pas-à-pas explicite

La section `## Release Process` MUST documenter sous forme d'étapes numérotées (≥ 4 étapes) :

1. Toute release est précédée d'un change Forge archivé (`/forge:archive`)
2. Le `CHANGELOG.md` est mis à jour avant le tag (responsabilité du pipeline `archive` via Calliope)
3. Tag git `vX.Y.Z` créé sur `main` (semver)
4. Publication sur npm (paquet CLI) et GitHub Releases (notes générées depuis `CHANGELOG.md`)

La section MUST mentionner explicitement la convention de tag `vX.Y.Z`.

**Test L1** : `grep -E 'vX\.Y\.Z|v[0-9]+\.[0-9]+\.[0-9]+' GOVERNANCE.md` retourne ≥ 1 match.

---

### FR-GOV-008 : Section `Code of Conduct` — pointeur valide

La section `## Code of Conduct` MUST :

- Référencer le fichier `CODE_OF_CONDUCT.md` à la racine du dépôt (lien Markdown relatif `[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)` ou équivalent)
- Mentionner le nom de la base utilisée : `Contributor Covenant v2.1`
- Indiquer comment signaler une violation (pointeur vers `## Contact`)

**Test L1** : `grep -q 'CODE_OF_CONDUCT.md' GOVERNANCE.md` ET `grep -q -i 'Contributor Covenant' GOVERNANCE.md`.

---

### FR-GOV-009 : Section `Contact` — email public

La section `## Contact` MUST publier au minimum :

- Un **email public** pour les sujets de gouvernance et les violations du Code of Conduct : `contact@benoitfontaine.fr`
- Un pointeur vers les **GitHub Discussions** pour les sujets non-confidentiels
- Un pointeur vers les **GitHub Issues** pour les bugs

L'email MUST apparaître en clair dans le fichier (pas obfusqué, pas image).

**Test L1** : `grep -qF 'contact@benoitfontaine.fr' GOVERNANCE.md`.

---

### FR-GOV-010 : Existence de `CODE_OF_CONDUCT.md` à la racine

Un fichier `CODE_OF_CONDUCT.md` MUST exister à la racine du dépôt.

Le contenu MUST être basé sur le **Contributor Covenant v2.1** (texte officiel disponible sur https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

Le fichier MUST mentionner explicitement la chaîne `Contributor Covenant` ET la version `2.1`.

Le fichier MUST contenir l'email de contact `contact@benoitfontaine.fr` dans la section « Enforcement » (ou équivalent).

**Test L1** : `[[ -f CODE_OF_CONDUCT.md ]]` ET `grep -q 'Contributor Covenant' CODE_OF_CONDUCT.md` ET `grep -q '2.1' CODE_OF_CONDUCT.md` ET `grep -qF 'contact@benoitfontaine.fr' CODE_OF_CONDUCT.md`.

---

### FR-GOV-011 : Constitution amendée — Article XII Governance

La Constitution `.forge/constitution.md` MUST recevoir un nouvel **Article XII — Governance** placé **après** l'Article XI et **avant** la section `## Amendments`.

L'Article XII MUST :

- Déclarer que `GOVERNANCE.md` est la source de vérité du modèle de gouvernance opérationnel du projet
- Déclarer que les Process Gates de l'Article V sont franchies par les rôles définis dans `GOVERNANCE.md`
- Déclarer que les amendements de Constitution suivent le processus formel défini en `GOVERNANCE.md` § « Amendment Process »
- Déclarer que toute évolution structurelle (passage BDFL → comité, ajout/retrait de mainteneurs) MUST être enregistrée dans `GOVERNANCE.md` ET référencée dans la table « Amendments » si elle implique une modification de Constitution

**Test L1** : `grep -q '^## Article XII' .forge/constitution.md` ET la section MUST contenir une référence à `GOVERNANCE.md`.

---

### FR-GOV-012 : Bump `constitution_version` et enregistrement de l'amendement

`.forge/constitution.md` MUST :

- Mentionner `constitution_version: 1.1.0` (ou toute notation équivalente clairement repérable, p. ex. badge ou ligne de version dans l'en-tête) — note : la version peut aussi rester implicite via le seul mécanisme de la table « Amendments » si l'en-tête actuel n'a pas de ligne « version ». **Décision** : ajouter en haut du fichier une ligne `**Version:** 1.1.0` (juste sous le titre H1) pour rendre la version visible humainement.
- Lister un nouvel amendement dans la table `## Amendments` :
  - Numéro : `1` (premier amendement, la table était vide)
  - Date : `2026-04-30` (ou date d'archive du change)
  - Description : `Add Article XII — Governance. Establish GOVERNANCE.md and CODE_OF_CONDUCT.md.`
  - Ratified By : `Benoit Fontaine (BDFL)`

`.forge/templates/change.yaml` MUST avoir `constitution_version: "1.1.0"` (mise à jour des deux occurrences).

`.forge/templates/archetypes/full-stack-monorepo/.forge.yaml.tmpl` MUST avoir `constitution_version: "1.1.0"`.

Les changes archivés (`b1-*`, `g1-*`, `c1-*`, `a7-*`, `b5-1-*`) NE DOIVENT PAS être modifiés : ils conservent `constitution_version: "1.0.0"` à des fins de traçabilité historique.

Le change `d5-governance` lui-même MUST avoir `constitution_version: "1.0.0"` dans son `.forge.yaml` (il est ratifié SOUS la 1.0.0 et CRÉE la 1.1.0 — l'amendement est l'effet, pas la cause).

**Test L1** :
- `grep -q '^\\*\\*Version:\\*\\* 1\\.1\\.0' .forge/constitution.md`
- `grep -q '| 1 |' .forge/constitution.md` (première ligne d'amendement)
- `grep -c 'constitution_version: "1.1.0"' .forge/templates/change.yaml` retourne `2`
- `grep -q 'constitution_version: "1.1.0"' .forge/templates/archetypes/full-stack-monorepo/.forge.yaml.tmpl`

---

### FR-GOV-013 : `README.md` mis à jour

Le `README.md` à la racine MUST référencer :

- `GOVERNANCE.md` (lien Markdown)
- `CODE_OF_CONDUCT.md` (lien Markdown)

La référence SHOULD apparaître dans une section dédiée (par exemple `## Contributing` ou `## Community`).

**Test L1** : `grep -qF 'GOVERNANCE.md' README.md` ET `grep -qF 'CODE_OF_CONDUCT.md' README.md`.

---

### FR-GOV-014 : Harness de tests structurels `d5.test.sh`

Un harness de tests `.forge/scripts/tests/d5.test.sh` MUST exister.

Le harness MUST utiliser le pattern manifest des autres harnais (`a7.test.sh`, `b5.test.sh`, `c1.test.sh`, `g1.test.sh`) — RED→GREEN incrémental, fonctions `_test_<id>`, `_run_test`, sortie compatible avec `verify.sh`.

Le harness MUST exécuter au minimum **un test par FR-GOV-XXX** ci-dessus, soit ≥ 13 tests structurels.

Le harness MUST être enregistré dans `.github/workflows/forge-ci.yml` (job `harness`) afin de tourner sur chaque PR.

`verify.sh` MUST découvrir et exécuter `d5.test.sh` automatiquement (par discovery `find tests -name '*.test.sh'` déjà en place).

**Test L1** : `[[ -x .forge/scripts/tests/d5.test.sh ]]` ET `bash .forge/scripts/tests/d5.test.sh` retourne `0` après implémentation.

---

### FR-GOV-015 : Aucun impact sur `cli/`, archetypes, standards techniques

Le change `d5-governance` NE DOIT PAS modifier :

- `cli/src/**` (aucun TypeScript touché)
- `cli/package.json`, `cli/package-lock.json`
- Les schémas d'archetypes (`.forge/schemas/*/schema.yaml`)
- Les templates d'archetypes (`.forge/templates/archetypes/*/`) — sauf le `.forge.yaml.tmpl` listé en FR-GOV-012
- Les standards techniques (`.forge/standards/global/*` autres que ceux explicitement listés au design)

**Test L1** : `git diff --name-only main...HEAD` après implémentation NE DOIT PAS lister de fichiers sous `cli/src/`, sous `.forge/schemas/`, ni sous `.forge/templates/archetypes/*/` autres que `.forge.yaml.tmpl`. (Test exécuté manuellement au gate `/forge:archive`, ou automatisé via un test L1 qui inspecte le périmètre via `git diff` si en CI.)

---

## Acceptance Criteria (BDD)

### Scénario 1 : un nouveau contributeur découvre la gouvernance

```gherkin
Given un contributeur externe arrive sur le dépôt Forge sur GitHub
When il consulte la page d'accueil du dépôt
Then il voit "GOVERNANCE.md" listé dans la sidebar GitHub (community files)
And il voit "Code of conduct" listé comme présent (badge GitHub)
And depuis le README, un lien "## Contributing" pointe vers GOVERNANCE.md
And depuis GOVERNANCE.md, il identifie en moins de 30 secondes :
  - qui est le BDFL (Benoit Fontaine, @bfontaine)
  - comment proposer un amendement (section Amendment Process, 4 étapes)
  - comment contacter les mainteneurs (contact@benoitfontaine.fr)
```

### Scénario 2 : un mainteneur veut publier une release

```gherkin
Given un mainteneur a archivé un change Forge sur la branche main
When il veut publier une release
Then il consulte GOVERNANCE.md § "Release Process"
And il suit les 4 étapes documentées dans l'ordre :
  1. archive du change (déjà fait)
  2. mise à jour de CHANGELOG.md (vérifier que Calliope l'a bien fait)
  3. tag git "vX.Y.Z"
  4. publication npm + GitHub Release
And aucune étape n'est ambiguë ou laissée à interprétation
```

### Scénario 3 : un contributeur veut amender la Constitution

```gherkin
Given un contributeur souhaite ajouter un nouvel article ou modifier un article existant de la Constitution
When il consulte GOVERNANCE.md § "Amendment Process"
Then il sait qu'il MUST :
  1. ouvrir un change Forge via /forge:propose
  2. discuter publiquement pendant ≥ 7 jours
  3. obtenir la ratification du BDFL
  4. attendre la mise à jour de la table "Amendments" + le bump constitution_version
And il sait que tant que ces étapes ne sont pas franchies, son amendement n'a aucun effet contraignant
```

### Scénario 4 : un harnais de CI valide la gouvernance

```gherkin
Given le code d5-governance est mergé sur la branche optim
When la CI GitHub Actions exécute le job "harness"
Then le harnais d5.test.sh tourne avec ≥ 13 tests
And tous les tests passent (exit code 0)
And la suite globale verify.sh reste verte (8 harnais → 9 harnais, total 160 → ≥ 173 tests)
```

### Scénario 5 : un signaleur de violation du Code of Conduct

```gherkin
Given un participant subit ou observe une violation du Code of Conduct
When il consulte CODE_OF_CONDUCT.md
Then il trouve dans la section "Enforcement" :
  - l'email contact@benoitfontaine.fr
  - une indication de confidentialité du signalement
  - une indication du délai de réponse (s'il est documenté ; sinon mention "we will respond as soon as possible")
And l'email est cliquable / copiable en clair
```

---

## Non-Functional Requirements

### NFR-GOV-001 : Lisibilité humaine

`GOVERNANCE.md` SHOULD pouvoir être lu et compris par un développeur tiers en moins de **5 minutes**. Cible : 100 à 250 lignes Markdown, structure scannable (sections H2 + bullets), zéro jargon Forge non défini sur place ou linké.

### NFR-GOV-002 : Stabilité documentaire

Une fois D.5 archivé, `GOVERNANCE.md` ET la section Article XII de la Constitution NE DOIVENT PAS être modifiés sans passer par le processus formel d'amendement défini en FR-GOV-006. C'est une discipline humaine, pas un test automatisé — mais le hook de pre-commit (si étendu) pourrait afficher un avertissement lors d'une modification de `GOVERNANCE.md` hors d'un change `.forge/changes/`.

### NFR-GOV-003 : Pas de PII excessive

Seul l'email `contact@benoitfontaine.fr` est exposé. **Aucun** numéro de téléphone, adresse postale, ou autre PII personnelle ne MUST apparaître dans `GOVERNANCE.md` ou `CODE_OF_CONDUCT.md`. Le handle GitHub `@bfontaine` est public et non-sensible.

### NFR-GOV-004 : Compatibilité GitHub Community

La présence de `GOVERNANCE.md` + `CODE_OF_CONDUCT.md` à la racine MUST déclencher la détection automatique GitHub (Community Standards), visible dans Settings > Insights > Community Standards. Cible : passage de l'indicateur de complétude communautaire à ≥ 80 % (vérification manuelle après push).

---

## Anti-Hallucination Pass

Pour chaque FR ci-dessus, vérification appliquée :

| FR | Testable ? | Ambigu ? | Conforme Constitution ? |
|---|---|---|---|
| FR-GOV-001 | ✅ `[[ -f GOVERNANCE.md ]]` | ❌ | ✅ |
| FR-GOV-002 | ✅ `grep -c '^## …'` | ❌ | ✅ |
| FR-GOV-003 | ✅ `grep -q` | ❌ | ✅ |
| FR-GOV-004 | ✅ comptage bullets | ❌ | ✅ |
| FR-GOV-005 | ✅ `grep -E -i` | ❌ (phrases-clés explicitées) | ✅ |
| FR-GOV-006 | ✅ `grep` 7 days + numérotation | ❌ | ✅ |
| FR-GOV-007 | ✅ `grep` vX.Y.Z + numérotation | ❌ | ✅ |
| FR-GOV-008 | ✅ `grep` | ❌ | ✅ |
| FR-GOV-009 | ✅ `grep -qF email` | ❌ | ✅ |
| FR-GOV-010 | ✅ multi-`grep` | ❌ | ✅ |
| FR-GOV-011 | ✅ `grep '^## Article XII'` | ❌ | ✅ (l'amendement est précisément le mécanisme prévu par la Constitution) |
| FR-GOV-012 | ✅ `grep` count occurrences | ❌ | ✅ |
| FR-GOV-013 | ✅ `grep -qF` | ❌ | ✅ |
| FR-GOV-014 | ✅ exit code | ❌ | ✅ |
| FR-GOV-015 | ✅ `git diff --name-only` | ❌ | ✅ (Article III.4 : pas de scope creep silencieux) |

**Aucun `[NEEDS CLARIFICATION:]` restant.** Les trois questions ouvertes du proposal ont été tranchées par décision utilisateur le 2026-04-30 :

1. Modèle = BDFL-with-fallback
2. Code of Conduct = Contributor Covenant v2.1
3. Email = `contact@benoitfontaine.fr`

---

## Constitution Compliance Summary

- **Article I (TDD)** : tests structurels L1 (RED→GREEN) sur le harnais `d5.test.sh`. ✅
- **Article II (BDD)** : 5 scénarios Gherkin documentés ci-dessus pour les flux utilisateur observables. ✅
- **Article III (Specs Before Code)** : ce document est précisément l'application. ✅
- **Article III.4 (Anti-hallucination)** : tableau ci-dessus, zéro `[NEEDS CLARIFICATION:]`. ✅
- **Article IV (Delta-based)** : section ADDED uniquement (pas de modif/suppression d'un FR existant — la Constitution est amendée mais via la table « Amendments », pas via `MODIFIED Requirements`). ✅
- **Article V (Process Gates)** : pipeline `propose → specify → design → plan → implement → archive` complet. ✅
- **Articles VI–XI** : NA (pas de Flutter, pas de Rust, pas d'infra applicative, pas d'observability runtime, pas de quality gates lint/format au sens applicatif, pas d'AI). ✅

---

**Status** : `specified`. Next : `/forge:design d5-governance`.
