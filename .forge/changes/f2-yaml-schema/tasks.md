# Tasks: f2-yaml-schema

**Pipeline** : RED → GREEN incrémental. **Single-session, 1 commit final** (cf. ADR-008).

**Volume cible** : ~21 tâches en 11 phases.

**Précondition** : Constitution v1.1.0, F.1 archived (open-questions convention available).

---

## Phase 1 — Harness RED

- [ ] **T001** Créer `.forge/scripts/tests/f2.test.sh` (executable, pattern manifest, sourcing `_helpers.sh`). ≥ 12 fonctions L1 + 5 L2 fixture-based. Inclure flag `--level 1,2`. [Story: FR-YS-021]
- [ ] **T002** Lancer `bash f2.test.sh --level 1` — vérifier RED : ~12 FAIL L1, 0 PASS. [Article I gate]

---

## Phase 2 — Schema JSON

- [ ] **T003** Créer `.forge/schemas/change.schema.json` (JSON Schema Draft 2020-12) avec `required: [name, status, created, schema, constitution_version]`, patterns name/created/constitution_version, enum status (6 values) + schema (7 archetypes), `timeline` object avec sous-clés ISO date, `layers/designs_per_layer/tasks_per_layer` shape only (b1-workflow extras), `additionalProperties: false`. [Story: FR-YS-001..012]

---

## Phase 3 — Validator script

- [ ] **T004** Créer `.forge/scripts/validate-change-yaml.sh` (executable). Wrapper bash qui invoque `python3 - <<PY` inline. Args : `<path-to-.forge.yaml>` (exit 2 si manquant ou file introuvable). [Story: FR-YS-013, FR-YS-015]
- [ ] **T005** Implémenter Python inline phase 1 (schema validation) : load YAML + JSON schema, vérifier required keys, enum, pattern, type, additionalProperties=false. Émettre erreurs sur stderr format `validate-change-yaml: <path>: <field>: <reason>`. Accumuler toutes les erreurs avant exit 1. [Story: FR-YS-014, FR-YS-015]
- [ ] **T006** Implémenter Python inline phase 2 (timeline coherence) : pour chaque status ∈ {specified, designed, planned, implemented, archived}, fail si `timeline.<status>` absent. Si `status: archived`, fail si une phase précédente manque dans timeline. [Story: FR-YS-008, FR-YS-009]

---

## Phase 4 — Audit existant (CRITIQUE — ADR-007)

- [ ] **T007** Invoquer `validate-change-yaml.sh` sur les **11 changes archivés existants** : b1-foundations, b1-scaffolder, b1-workflow, b1-delivery, g1-forge-ci, c1-reference-project, a7-forge-upgrade, b5-1-init-wizard, d5-governance, b4-mobile-only, f1-open-questions. Capturer le compteur PASS/FAIL. [NFR-YS-001 gate]
- [ ] **T008** Si fail détecté : analyser cause. Si schema trop strict → assouplir le schema (T003 update). Si change.yaml vraiment invalide → ouvrir Q-NNN dans `open-questions.md` du change F.2 + corriger le change-amendment. Re-lancer T007 jusqu'à 11/11 PASS. [NFR-YS-001 gate]

---

## Phase 5 — verify.sh integration

- [ ] **T009** Étendre `.forge/scripts/verify.sh` avec une nouvelle section `── Change YAML Schema ──`. Pour chaque `.forge/changes/*/.forge.yaml`, invoque `bash .forge/scripts/validate-change-yaml.sh <path>`. Émet `pass`/`fail` aggrégé. Honor skip-guard `examples/` (FR-GL-026). [Story: FR-YS-016]
- [ ] **T010** Lancer `bash verify.sh` — vérifier que la nouvelle section ajoute 12 PASS (11 archivés + f2 lui-même) et zéro FAIL. [Story: FR-YS-017, NFR-YS-001]

---

## Phase 6 — Standard + index

- [ ] **T011** Créer `.forge/standards/global/change-yaml-schema.md` avec ≥ 5 sections H2 (Purpose, Schema Reference, Required Fields, Timeline Coherence Rules, Extending the Schema). [Story: FR-YS-018]
- [ ] **T012** Ajouter entrée `global/change-yaml-schema` dans `.forge/standards/index.yml` avec triggers `change.yaml, .forge.yaml, schema validation, JSON Schema, status enum, timeline coherence`. [Story: FR-YS-019]

---

## Phase 7 — Documentation

- [ ] **T013** Créer `docs/SCHEMA.md` (ou ajouter section dans `docs/GUIDE.md`) — ≥ 25 lignes documentant le schema, les patterns acceptés, comment debugger un FAIL, comment ajouter un nouvel archetype au enum schema. [Story: FR-YS-020]

---

## Phase 8 — CI integration

- [ ] **T014** Mettre à jour `.github/workflows/forge-ci.yml` job `harness` : ajouter `- name: f2.test.sh; run: bash .forge/scripts/tests/f2.test.sh --level 1,2` après `f1.test.sh`. [Story: FR-YS-021]

---

## Phase 9 — Verify global GREEN + zero regression

- [ ] **T015** Lancer `bash f2.test.sh --level 1,2` — vérifier ≥ 17/17 GREEN. [Article I gate]
- [ ] **T016** Lancer `bash verify.sh` global — vérifier 84+ PASS, 0 FAIL. [Article V, NFR-YS-001]
- [ ] **T017** Lancer `bash constitution-linter.sh` global — OVERALL PASS confirmé. [Article III.4]
- [ ] **T018** Lancer chaque harness (foundations à f2) — vérifier 12 harnais all GREEN, total ≥ 268 tests. NFR-YS-001 (a7.test.sh 29/29 maintenu). [Article V gate]
- [ ] **T019** Mesurer perf : `time bash validate-change-yaml.sh path` ≤ 150ms ; `time bash verify.sh` total ≤ 5s overall. NFR-YS-002. [NFR gate]

---

## Phase 10 — Archive admin

- [ ] **T020** Créer `.forge/specs/change-yaml-schema.md` consolidant FR-YS-001..022 + NFR-YS-001..004 + 5 BDD scenarios. [Story: archive consolidation]
- [ ] **T021** Mettre à jour `.forge/product/roadmap.md` : marquer F.2 ✅ Done en T3. [Story: project tracking]
- [ ] **T022** Mettre à jour `/Users/bfontaine/.claude/plans/il-s-agit-l-d-un-noble-gem.md` : marquer F.2 ✅ Livré T3, F.4 reste. [Story: project tracking]
- [ ] **T023** Mettre à jour `CHANGELOG.md` `[Unreleased]` : ajouter `### Added — f2-yaml-schema` détaillant schema + validator + verify gate + standard + harness. **Reste `[Unreleased]`**. [Story: project tracking]
- [ ] **T024** Flip `.forge.yaml` status `archived` + timeline complete. Vérifier que `validate-change-yaml.sh` PASS sur ce fichier (auto-validation). Flip Q-001..003 status `answered` confirmé dans `open-questions.md`. [Article V gate]

---

## Phase 11 — Commit + push

- [ ] **T025** Stage Phase F.2 (schema + validator + verify section + standard + index + harness + CI workflow + spec consolidée + roadmap + plan + CHANGELOG + .forge.yaml + open-questions.md updates). Commit + push. [Article V gate]

---

## Constitutional Compliance Gate (sweep final)

| Tâche | Article violé ? |
|---|---|
| T001-T002 (harness RED) | Aucun. Article I respecté. |
| T003 (schema) | Aucun. Article IV (delta-based, ADDED). |
| T004-T006 (validator) | Aucun. Article X (no new dep, NFR-YS-003). |
| T007-T008 (audit existant) | Aucun. Article X (backward compat). |
| T009-T010 (verify.sh integration) | Aucun. Article V gate. |
| T011-T013 (standard + doc) | Aucun. |
| T014 (CI) | Aucun. |
| T015-T019 (verify global + perf) | Aucun. NFR-YS-001, 002. |
| T020-T024 (archive admin) | Aucun. |
| T025 (commit) | Aucun. |

**Aucun `[TASK VIOLATION:]`.**

---

**Status** : `planned`. Next : `/forge:implement f2-yaml-schema`.

**Mode d'exécution** : single-session.

**Risk de dérapage** : la phase 4 (audit existant) peut révéler des fails sur les changes archivés. Si oui, T008 ajuste le schema ou ouvre des Q-NNN — c'est attendu et tracé via la convention F.1.
