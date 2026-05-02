# Tasks: d5-governance

**Pipeline** : RED → GREEN → REFACTOR par phase. Pas de tâche `[P]` (le harnais doit être complet en RED avant les phases d'écriture, et chaque phase d'écriture débloque un sous-ensemble de tests dans le harnais — séquentialité naturelle).

**Volume cible** : ~12 tâches groupées en 7 phases (cf. design.md § Implementation Order).

---

## Phase 1 : Foundation — Harnais en RED

- [ ] **T001** Créer `.forge/scripts/tests/d5.test.sh` au pattern manifest avec 15 fonctions `_test_d5_001` à `_test_d5_015` couvrant les 15 FR. Chaque test utilise `_assert_*` helpers locaux (ou mutualisés si déjà disponibles). Le script MUST être exécutable (`chmod +x`). [Story: FR-GOV-014]
- [ ] **T002** Lancer `bash .forge/scripts/tests/d5.test.sh` — vérifier RED : les 15 tests échouent (aucun fichier `GOVERNANCE.md`, etc.). Capturer le compteur attendu : `0 PASSED, 15 FAILED, 15 TOTAL`. [Story: FR-GOV-014, Article I gate]

**Constitutional check** : ✅ Article I respecté — RED confirmé avant toute écriture de contenu.

---

## Phase 2 : `GOVERNANCE.md` — sections 1-7

- [ ] **T003** Rédiger `GOVERNANCE.md` à la racine du dépôt avec les 7 sections H2 dans l'ordre canonique (`Maintainers`, `Roles and Responsibilities`, `Decision Making`, `Amendment Process`, `Release Process`, `Code of Conduct`, `Contact`). Couvrir le contenu requis par FR-GOV-001 à FR-GOV-009 (BDFL Benoit Fontaine `@bfontaine`, BDFL-with-fallback, 4 étapes d'amendement avec « 7 jours », 4 étapes de release avec `vX.Y.Z`, lien CoC + Contributor Covenant 2.1, email `contact@benoitfontaine.fr`). Cible 100-250 lignes. [Story: FR-GOV-001..009]
- [ ] **T004** Lancer `bash .forge/scripts/tests/d5.test.sh` — vérifier que `_test_d5_001` à `_test_d5_010` passent (10 GREEN). Tests 011-015 restent RED. [Story: FR-GOV-001..009]

**Constitutional check** : ✅ Article II — sections H2 + bullets scannables, lisibilité ≤ 5 min (NFR-GOV-001).

---

## Phase 3 : `CODE_OF_CONDUCT.md`

- [ ] **T005** Créer `CODE_OF_CONDUCT.md` à la racine avec le texte intégral officiel **Contributor Covenant v2.1** (source : https://www.contributor-covenant.org/version/2/1/code_of_conduct/). Remplacer **uniquement** le placeholder `[INSERT CONTACT METHOD]` par `contact@benoitfontaine.fr`. Aucune autre modification du texte officiel. [Story: FR-GOV-010]
- [ ] **T006** Lancer `bash .forge/scripts/tests/d5.test.sh` — vérifier que `_test_d5_011` passe (11 GREEN). [Story: FR-GOV-010]

**Constitutional check** : ✅ ADR-002 respecté — copier-coller verbatim, pas de divergence.

---

## Phase 4 : Constitution amendée + bumps templates

- [ ] **T007** Amender `.forge/constitution.md` :
  - Insérer immédiatement sous le titre H1 `# Forge Constitution` une ligne `**Version:** 1.1.0`.
  - Ajouter `## Article XII — Governance` entre l'Article XI (« AI-First Design ») et la section `## Amendments`. Contenu : ≤ 30 lignes, délègue à `GOVERNANCE.md`, déclare la délimitation principes constitutionnels vs procédures opérationnelles (cf. ADR-005).
  - Ajouter une ligne dans la table `## Amendments` :
    `| 1 | 2026-04-30 | Add Article XII — Governance. Establish GOVERNANCE.md and CODE_OF_CONDUCT.md. | Benoit Fontaine (BDFL) |`
  [Story: FR-GOV-011, FR-GOV-012]
- [ ] **T008** Mettre à jour les templates :
  - `.forge/templates/change.yaml` : remplacer les 2 occurrences de `constitution_version: "1.0.0"` par `"1.1.0"`.
  - `.forge/templates/archetypes/full-stack-monorepo/.forge.yaml.tmpl` : `"1.0.0"` → `"1.1.0"`.
  - **NE PAS** modifier `.forge/changes/d5-governance/.forge.yaml` (reste à `1.0.0` cf. ADR-006).
  - **NE PAS** modifier les `.forge.yaml` des changes archivés (immuabilité historique).
  [Story: FR-GOV-012]
- [ ] **T009** Lancer `bash .forge/scripts/tests/d5.test.sh` — vérifier `_test_d5_012`, `_test_d5_013`, `_test_d5_014` GREEN (14 GREEN total). Test 015 reste RED. [Story: FR-GOV-011, FR-GOV-012]

**Constitutional check** : ✅ Article IV (delta-based) — ajout en table Amendments + nouvel article ; ✅ ADR-006 respecté.

---

## Phase 5 : `README.md`

- [ ] **T010** Mettre à jour `README.md` à la racine :
  - Ajouter (ou compléter) une section `## Contributing` ou `## Community` avec deux liens Markdown :
    - `[GOVERNANCE.md](./GOVERNANCE.md)` (qui décide quoi)
    - `[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)` (règles communautaires)
  - Pas de réécriture du README au-delà de cet ajout (scope FR-GOV-013 + FR-GOV-015).
  [Story: FR-GOV-013]
- [ ] **T011** Lancer `bash .forge/scripts/tests/d5.test.sh` — vérifier `_test_d5_015` GREEN (15/15 GREEN). [Story: FR-GOV-013]

**Constitutional check** : ✅ FR-GOV-015 (périmètre négatif) respecté — seul `README.md` ajouté à la liste, pas de modif `cli/`, pas de schéma touché.

---

## Phase 6 : Intégration CI + verify.sh global

- [ ] **T012** Vérifier que `.forge/scripts/verify.sh` découvre `d5.test.sh` automatiquement (discovery `find tests -name '*.test.sh'`). Lancer `bash .forge/scripts/verify.sh` localement et confirmer compteur 175 tests (160 existants + 15 d5). Si la découverte automatique n'opère pas, ajouter un appel nominatif. [Story: FR-GOV-014]
- [ ] **T013** Mettre à jour `.github/workflows/forge-ci.yml` job `harness` pour appeler `d5.test.sh` (par cohérence avec l'enregistrement nominatif des autres harnais : `a7.test.sh`, `b5.test.sh`, etc.). Vérifier la syntaxe YAML par `cat | head -50` ou via `act` si disponible. [Story: FR-GOV-014]

**Constitutional check** : ✅ Article V — gate CI franchie pour le change.

---

## Phase 7 : Archive — consolidation specs + roadmap + CHANGELOG

- [ ] **T014** Créer `.forge/specs/governance.md` (consolidation post-archive) avec :
  - Les 15 FR-GOV-* + 4 NFR-GOV-* + 5 scénarios BDD copiés depuis `specs.md` du change.
  - En-tête mentionnant le change source `d5-governance` + date d'archive.
  - Format aligné avec `forge-ci.md`, `init-wizard.md`, `upgrade.md`.
  [Story: ADR-008]
- [ ] **T015** Mettre à jour `.forge/product/roadmap.md` :
  - Marquer `D.5 — GOVERNANCE.md` ✅ Done (T2 P1).
  - T2 P1 désormais complet (toutes les cases A.7, B.5.1, D.5, D.6 cochées).
  [Story: project tracking]
- [ ] **T016** Mettre à jour `/Users/bfontaine/.claude/plans/il-s-agit-l-d-un-noble-gem.md` :
  - Marquer D.5 ✅ Livré T2.
  - Bascule T2 P1 → complet ; pivot vers T2 P2 (second archetype) annoncé.
  [Story: project tracking]
- [ ] **T017** Mettre à jour `CHANGELOG.md` sous `## [Unreleased]` :
  - Ajouter une entrée `### Added` listant `GOVERNANCE.md`, `CODE_OF_CONDUCT.md`, Article XII Constitution, bump 1.0.0 → 1.1.0.
  - Ne **pas** sceller la version (reste `[Unreleased]`) — guard-rail no-PR-no-release tant que T2 P2 n'est pas terminé.
  [Story: project tracking]
- [ ] **T018** Lancement final `bash .forge/scripts/verify.sh` + `node cli/dist/index.js status` (ou équivalent) pour confirmer que tout est cohérent. Compter : 175 tests passants, 9 harnais, status `archived` une fois `/forge:archive d5-governance` exécuté. [Story: gate /forge:archive]

**Constitutional check** : ✅ Article III.4 — aucune hallucination ; toutes les valeurs (175, 9, dates) sont mesurables. ✅ NFR-GOV-002 — toute modification future de `GOVERNANCE.md` devra passer par un nouveau change Forge (discipline humaine).

---

## Constitutional Compliance Gate (sweep final)

| Tâche | Article violé ? |
|---|---|
| T001-T002 | Aucun. RED-first respecté (Article I). |
| T003-T004 | Aucun. Doc Markdown, scope clair. |
| T005-T006 | Aucun. Copier-coller verbatim ADR-002. |
| T007-T009 | Aucun. Amendement de Constitution suit le mécanisme prévu par la Constitution elle-même. |
| T010-T011 | Aucun. README minimal touch (FR-GOV-013 + FR-GOV-015). |
| T012-T013 | Aucun. CI standard. |
| T014-T018 | Aucun. Archive admin, pas d'écart. |

**Aucun `[TASK VIOLATION:]`.**

---

**Status** : `planned`. Next : `/forge:implement d5-governance`.

**Mode d'exécution recommandé** : single-session (cohérent avec a7 et b5.1) — c'est de la doc + harness, l'enchaînement est mécanique.
