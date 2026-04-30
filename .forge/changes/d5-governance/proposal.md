# Proposal: d5-governance

## Problem

Le projet Forge n'a pas de **modèle de gouvernance explicite et écrit**. La Constitution mentionne « project maintainer(s) » à plusieurs endroits (escalade des violations TDD, ratification des amendements, etc.) mais n'identifie nulle part :

- **Qui** sont ces mainteneurs (BDFL unique ? comité ? noms ?)
- **Comment** un nouveau mainteneur est coopté ou retiré
- **Qui** a autorité pour merger une PR sur `main`
- **Qui** publie les releases (et selon quelle cadence/processus)
- **Comment** un amendement de Constitution est proposé, débattu, ratifié
- **Comment** sont arbitrés les conflits techniques (votes ? consensus mou ? veto ?)
- **Quel** est le code de conduite et qui le fait respecter

Cette absence est un risque concret au moment d'ouvrir le projet à des contributeurs externes (T2 P1 venait de réactiver les GitHub Discussions) :

1. **Risque de bus factor** : si l'auteur initial disparaît, personne ne sait à qui revient le contrôle des merges/releases.
2. **Risque de dilution** : sans règle écrite, des PR pourraient être mergées sans respect du pipeline `propose → specify → design → plan → implement → archive`.
3. **Risque de Constitution mort-née** : la Constitution se proclame loi suprême mais ne décrit pas son propre processus d'amendement (juste « ratifié par les mainteneurs »).
4. **Risque de friction contributeur** : un contributeur externe ne sait pas où porter une suggestion, qui la lit, sous quel délai elle est traitée.

Module **D.5** du plan d'audit `il-s-agit-l-d-un-noble-gem.md` (T2 P1, dernier facilitateur restant après A.7, B.5.1, D.6).

## Solution

Livrer un fichier **`GOVERNANCE.md`** à la racine du dépôt (convention OSS standard, lu automatiquement par GitHub à côté de `README.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`), accompagné de l'amendement constitutionnel qui institue ce document comme source de vérité de la gouvernance.

### Modèle proposé : **BDFL-with-fallback**

- **Phase actuelle (≤ 1.0)** : BDFL = Benoit Fontaine, auteur initial. Le BDFL :
  - merge les PR sur `main` (ou délègue explicitement)
  - publie les releases (tags `vX.Y.Z`)
  - ratifie les amendements de Constitution (en dernier ressort)
  - peut nommer des **co-mainteneurs** (write access) pour des domaines précis
- **Phase mature (≥ 2.0, ou ≥ 5 contributeurs réguliers)** : transition optionnelle vers un **comité de mainteneurs** (3 à 7 membres, vote majoritaire, BDFL conserve un veto sur la Constitution uniquement). Le déclenchement de cette transition est lui-même un amendement de Constitution.

### Processus d'amendement de Constitution

1. Ouverture d'un change `/forge:propose <name>` ciblant `.forge/constitution.md`
2. Discussion publique ≥ 7 jours (GitHub Discussion ou PR dédiée)
3. Décision finale du BDFL (phase actuelle) ou vote majoritaire du comité (phase mature)
4. Si ratifié : ajout d'une ligne dans la table « Amendments » de la Constitution + bump `constitution_version`

### Processus de release

1. Toute release est un change Forge archivé (`/forge:archive`) suivi d'un tag `vX.Y.Z`
2. Le BDFL (ou un co-mainteneur autorisé) publie sur npm + GitHub Releases
3. Le `CHANGELOG.md` est tenu à jour (déjà géré par Calliope dans le pipeline `archive`)

### Code de conduite

Adoption du **Contributor Covenant v2.1** (texte standard), ajout d'un fichier `CODE_OF_CONDUCT.md` à la racine. Les violations sont rapportées via l'email de contact du BDFL inscrit dans `GOVERNANCE.md`.

## Scope In

- Création de `GOVERNANCE.md` à la racine du dépôt avec :
  - Liste nominative des mainteneurs actuels (BDFL + co-mainteneurs si pertinent)
  - Rôles et responsabilités explicites (qui merge, qui release, qui ratifie)
  - Processus d'amendement de Constitution (gabarit pas-à-pas)
  - Processus de release (gabarit pas-à-pas)
  - Conditions de transition BDFL → comité (si Phase mature)
  - Pointeur vers `CODE_OF_CONDUCT.md`
  - Pointeur vers `CONTRIBUTING.md` (si existant ; sinon créé en scope-out de D.5 mais référencé)
- Création de `CODE_OF_CONDUCT.md` (Contributor Covenant v2.1)
- Amendement de la Constitution :
  - Article XII (nouveau) **« Governance »** ou amendement de l'Article V « Process Gates » pour pointer explicitement vers `GOVERNANCE.md`
  - Bump `constitution_version` 1.0.0 → 1.1.0 (semver mineur : ajout sans breaking change)
  - Ligne ajoutée à la table « Amendments » de la Constitution
- Mise à jour du `README.md` pour pointer vers `GOVERNANCE.md` et `CODE_OF_CONDUCT.md` dans la section « Contributing »
- Mise à jour de `.forge/standards/global/` si une règle référence le concept de mainteneur (à auditer)
- Tests structurels (L1) :
  - `GOVERNANCE.md` existe à la racine
  - `CODE_OF_CONDUCT.md` existe à la racine
  - `GOVERNANCE.md` contient les sections requises (Maintainers, Amendment Process, Release Process, Code of Conduct)
  - `constitution.md` référence `GOVERNANCE.md`
  - `constitution_version` bumpé à `1.1.0` dans la Constitution + dans `.forge/templates/change.yaml`

## Scope Out (Explicit Exclusions)

- **Création d'un comité de mainteneurs concret** : la Phase mature reste documentée comme **future option**, pas activée immédiatement (le projet n'a pas encore les 5+ contributeurs réguliers requis).
- **`CONTRIBUTING.md` détaillé** : pourra faire l'objet d'un futur change si besoin ; D.5 se contente d'y faire référence si le fichier est créé en parallèle. Si non, `GOVERNANCE.md` peut absorber temporairement la section « How to contribute » la plus essentielle.
- **Politique de sécurité (`SECURITY.md`)** : sera traitée par un autre change (D.x ou H.x) ; D.5 mentionne le processus de signalement de vulnérabilités sans détailler.
- **Politique de marque, logo, assets** : hors scope.
- **Mécanisme de vote concret pour la phase mature** (quorum, méthode de vote) : décrit en termes généraux, détails laissés à l'amendement qui activera la transition.
- **Refonte du processus d'archivage** : D.5 ne touche pas au pipeline `propose → specify → design → plan → implement → archive`, seulement à **qui** a autorité dans ce pipeline.
- **Migration `constitution_version` au-delà de 1.1.0** : un seul amendement (l'ajout de l'Article XII Governance) suffit.

## Impact

- **Users affected** :
  - **Mainteneurs actuels** (BDFL) : leurs responsabilités sont désormais écrites et auditables.
  - **Contributeurs externes (potentiels)** : ils savent enfin où s'adresser, comment proposer un changement majeur, sous quels délais.
  - **Adopteurs du framework Forge** : ils peuvent citer l'existence d'une gouvernance en justifiant un choix techno (audit interne, conformité légère).
- **Technical impact** :
  - Pas de code applicatif touché. Modifications limitées à : 2 fichiers Markdown créés à la racine + Constitution amendée + `README.md` mis à jour + tests structurels L1 (~50 LOC bash dans `d5.test.sh`).
  - Bump `constitution_version` : impact sur tous les changes futurs qui devront déclarer `constitution_version: "1.1.0"`. Le template `.forge/templates/change.yaml` est mis à jour. Les changes archivés conservent leur version (immuable, traçabilité historique).
  - Pas d'impact sur la CLI `cli/`, ni sur les archetypes, ni sur les standards.
- **Dependencies** :
  - **Aucune** : D.5 est un facilitateur autonome qui peut être livré à tout moment. Tous les A.7, B.5.1, C.1, G.1, B.1.* sont déjà archivés sur `optim`.
  - Doit être livré **avant** la PR `optim → main` selon la guard-rail du plan (T2 P1 doit être complet).

## Constitution Compliance

- **Article I (TDD)** : NA pour la création de documentation Markdown statique. Les tests structurels L1 (présence de fichier, présence de sections) suivent la même discipline RED→GREEN que les autres harnais (cf. `c1.test.sh`, `a7.test.sh`, `b5.test.sh`). Pour l'amendement de Constitution : un test L1 vérifie que `constitution_version` a bien été bumpé et que la table « Amendments » a une nouvelle ligne.
- **Article II (BDD)** : NA — pas de comportement utilisateur observable au sens runtime. Les « scénarios » sont des invariants documentaires (présence de sections, cohérence de version) couverts par L1.
- **Article III (Specs Before Code)** : ✅ confirmed — `/forge:propose` → `/forge:specify` → `/forge:design` → `/forge:plan` → `/forge:implement` → `/forge:archive`, pipeline standard.
- **Article III.4 (Anti-hallucination)** : si pendant `/forge:specify` ou `/forge:design` une question apparaît sur le mode de gouvernance souhaité (BDFL strict ? comité tout de suite ? cadence de release ?), un marqueur `[NEEDS DECISION:]` sera émis pour validation utilisateur. Aucune décision de gouvernance ne sera devinée.
- **Article IV (Delta-based)** : ✅ confirmed — l'amendement à la Constitution est exprimé en delta (ADDED Article XII, MODIFIED Article V si nécessaire), `specs.md` utilisera le format ADDED/MODIFIED/REMOVED.
- **Article V (Process Gates)** : ✅ confirmed — toutes les portes du pipeline sont franchies. D.5 lui-même ajoute une définition formelle de Process Gates en pointant vers `GOVERNANCE.md` pour le « qui » de chaque gate.
- **Article VI (Flutter)** : NA.
- **Article VII (Rust)** : NA.
- **Article VIII (Infra)** : NA.
- **Article IX (Observability)** : NA.
- **Article X (Quality)** : ✅ confirmed — la qualité documentaire est vérifiée par les tests L1 (présence et complétude des sections requises) et par une relecture humaine au gate `/forge:archive`.
- **Article XI (AI-First)** : NA.
- **Nouvel Article XII (Governance)** : ✅ proposé — la création de cet article est précisément le cœur de D.5. Sera validé pendant `/forge:specify`.

---

## Décisions ouvertes — résolues 2026-04-30

1. **Modèle de gouvernance** → **BDFL-with-fallback** (documente la transition future vers comité sans l'activer).
2. **Code of Conduct** → **Contributor Covenant v2.1** (texte standard, zéro effort de rédaction, accepté par GitHub).
3. **Email de contact public** → **`contact@benoitfontaine.fr`** (alias dédié, pas l'email pro).

**Note sur le nom** : `d5-governance` (court, scannable).
