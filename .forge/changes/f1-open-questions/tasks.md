# Tasks: f1-open-questions

**Pipeline** : RED → GREEN incrémental. **Single-session, 1 commit final** (cf. ADR-011).

**Volume cible** : ~22 tâches groupées en 8 phases.

**Précondition** : Constitution v1.1.0 active. Le `.forge.yaml` du change déjà à `constitution_version: "1.1.0"`.

---

## Phase 1 — Harness RED

- [ ] **T001** Créer `.forge/scripts/tests/f1.test.sh` (executable, pattern manifest, sourcing `_helpers.sh`). ≥ 17 fonctions `_test_f1_NNN` couvrant FR-OQ-001..022 + 5 tests L2 fixture-based (`_test_f1_l2_001..005`). Inclure flag `--level 1,2`. [Story: FR-OQ-020]
- [ ] **T002** Lancer `bash f1.test.sh --level 1` — vérifier RED : ~12 FAIL L1, 0 PASS. Capturer le compteur. [Article I gate]

---

## Phase 2 — Standard + template + index

- [ ] **T003** Créer `.forge/standards/global/open-questions.md` avec 8 sections H2 (Purpose, File Location and Lifecycle, Question Schema, Status Enum, Resolution Block, Verify Gate, Linter Rule, Discovery) + ≥ 3 Interdictions explicites (no modify answered, no reuse Q-NNN, no `[NEEDS CLARIFICATION:]` inline in implemented/archived). [Story: FR-OQ-001]
- [ ] **T004** Créer `.forge/templates/open-questions.md.tmpl` avec en-tête `# Open Questions — {{change-name}}` + commentaire pédagogique court (≤ 10 lignes) + zéro question pré-remplie. [Story: FR-OQ-008]
- [ ] **T005** Ajouter entrée `global/open-questions` dans `.forge/standards/index.yml` avec triggers `open-questions, NEEDS CLARIFICATION, Q-001, clarification, anti-hallucination, Article III.4`. [Story: FR-OQ-002]

---

## Phase 3 — Discovery script `bin/forge-questions.sh`

- [ ] **T006** Créer `bin/forge-questions.sh` (executable) : itère sur `.forge/changes/*/open-questions.md`, parse via awk les blocs `## Q-NNN: <Title>` jusqu'au prochain `##`, extrait Status + Title + Raised on + Raised by. Output format `<change>:Q-NNN  <Title>  (raised <date> by <handle>)`, trié par Raised on asc. Mode par défaut = lister `Status: open`. [Story: FR-OQ-015, FR-OQ-016]
- [ ] **T007** Implémenter flags `--change <name>` (filter sur un seul change) et `--status <open|answered|wontfix>` (filter par status). Refus exit 2 si flag inconnu. [Story: FR-OQ-017]

---

## Phase 4 — Gates (verify.sh + constitution-linter)

- [ ] **T008** Étendre `.forge/scripts/verify.sh` avec une nouvelle section `── Open Questions Gate ──`. Pour chaque change, lit `.forge.yaml` (status), si `archived` ET `open-questions.md` exists, scanne grep `^- \*\*Status\*\*: open$`, fail bloquant si trouvé. Skip si `open-questions.md` absent (rétrocompat). Skip-guard `examples/` (FR-GL-026 cohérent). [Story: FR-OQ-009, FR-OQ-010, FR-OQ-011, FR-OQ-012]
- [ ] **T009** Étendre `.forge/scripts/constitution-linter.sh` avec une nouvelle règle "no `[NEEDS CLARIFICATION:` in implemented/archived". Pour chaque change : lit `.forge.yaml` (status), si `implemented` ou `archived`, scanne `proposal.md / specs.md / design.md / tasks.md` (mais PAS `open-questions.md` qui est le lieu légitime de tracé). Émet FAIL par occurrence avec format `FAIL <change>:<file>:<line>: NEEDS CLARIFICATION inline detected`. [Story: FR-OQ-013, FR-OQ-014]

---

## Phase 5 — Skill scaffold + doc

- [ ] **T010** Tenter de modifier le skill `/forge:propose` (chercher dans `.claude/skills/forge/propose.md` ou équivalent). Ajouter une étape qui crée `open-questions.md` stub à côté de `.forge.yaml` et `proposal.md`. Si l'emplacement est non-modifiable ou non-trouvé, **fallback** : la création du stub est documentée explicitement dans le standard `.forge/standards/global/open-questions.md` § "File Location and Lifecycle" comme étape obligatoire au moment du `/forge:propose`. [Story: FR-OQ-018]
- [ ] **T011** Documenter dans `docs/GUIDE.md` (ou créer `docs/OPEN_QUESTIONS.md`) une section "Tracking Open Questions" de ≥ 30 lignes : pourquoi (Article III.4), quand soulever (au plus tôt), comment résoudre (workflow status flip), comment lister via `bin/forge-questions.sh`. [Story: FR-OQ-019]

---

## Phase 6 — CI integration

- [ ] **T012** Mettre à jour `.github/workflows/forge-ci.yml` job `harness` : ajouter `- name: f1.test.sh; run: bash .forge/scripts/tests/f1.test.sh --level 1,2` après `b4.test.sh`. [Story: FR-OQ-020]
- [ ] **T013** Vérifier que `bash verify.sh` découvre automatiquement `f1.test.sh` (find `tests -name '*.test.sh'`). [Article V gate]

---

## Phase 7 — Verify global GREEN + zero regression

- [ ] **T014** Lancer `bash f1.test.sh --level 1,2` — vérifier ≥ 17/17 GREEN. [Article I gate]
- [ ] **T015** Lancer `bash verify.sh` global — vérifier 80+ PASS, 0 FAIL (la nouvelle section Open Questions Gate scanne les 11 changes ; aucun n'a `open-questions.md`, donc gate SKIP partout = PASS). [Article V gate, NFR-OQ-003]
- [ ] **T016** Lancer `bash constitution-linter.sh` global — vérifier qu'aucun change archivé ne contient de `[NEEDS CLARIFICATION:]` inline (les changes existants ont leurs `## Décisions ouvertes — résolues` propres mais ne contiennent pas le marqueur littéral inline). [Article III.4 gate]
- [ ] **T017** Lancer chaque harness (foundations, scaffolder, workflow, delivery, g1, c1, a7, b5, d5, b4, **f1**) — vérifier total ≥ 250 tests, zéro régression. NFR-OQ-007 (a7.test.sh 29/29 maintenu, etc.). [Article V gate]
- [ ] **T018** Mesurer perf verify.sh : `time bash verify.sh` avant/après — delta ≤ 500ms (NFR-OQ-002). Si dépassement, optimiser le scan (limiter à `find -maxdepth 3` par exemple). [NFR-OQ-002]

---

## Phase 8 — Archive

- [ ] **T019** Créer `.forge/specs/open-questions.md` consolidant FR-OQ-001..022 + NFR-OQ-001..004 + 6 BDD scenarios. En-tête référence `f1-open-questions` + date d'archive. [Story: ADR-008 design (consolidation pattern)]
- [ ] **T020** Mettre à jour `.forge/product/roadmap.md` : marquer F.1 ✅ Done en T3 (robustesse technique). [Story: project tracking]
- [ ] **T021** Mettre à jour `/Users/bfontaine/.claude/plans/il-s-agit-l-d-un-noble-gem.md` : marquer F.1 ✅ Livré T3, signaler que F.2 + F.4 restent en T3. [Story: project tracking]
- [ ] **T022** Mettre à jour `CHANGELOG.md` `[Unreleased]` : ajouter `### Added — f1-open-questions` détaillant standard + template + verify gate + linter rule + discovery script + harness. **Reste `[Unreleased]`** tant que l'utilisateur ne demande pas la PR. [Story: project tracking]
- [ ] **T023** Flip `.forge/changes/f1-open-questions/.forge.yaml` : `status: archived` + `timeline.implemented` + `timeline.archived` à `2026-04-30`. [Article V gate]
- [ ] **T024** Stage Phase F.1 (standard + template + index + script + verify + linter + skill/doc + CI + harness + spec consolidée + roadmap + plan + CHANGELOG + .forge.yaml status). Commit + push. [Article V gate]

**Constitutional check** : ✅ tous articles. Aucun `[TASK VIOLATION:]`.

---

## Constitutional Compliance Gate (sweep final)

| Tâche | Article violé ? |
|---|---|
| T001-T002 (harness RED) | Aucun. Article I respecté. |
| T003-T005 (standard + template + index) | Aucun. Article IV (delta-based). |
| T006-T007 (script discovery) | Aucun. Article X (no new dep). |
| T008-T009 (gates) | Aucun. Articles III.4 + V mécanisés. |
| T010-T011 (skill + doc) | Aucun. ADR-009 fallback couvre les 2 cas. |
| T012-T013 (CI) | Aucun. Article V gate. |
| T014-T018 (verify global + perf) | Aucun. NFR-OQ-002, 003, 007. |
| T019-T024 (archive) | Aucun. Admin standard. |

**Aucun `[TASK VIOLATION:]`.**

---

**Status** : `planned`. Next : `/forge:implement f1-open-questions`.

**Mode d'exécution recommandé** : single-session (cohérent avec D.5, ADR-011). 1 commit final.
