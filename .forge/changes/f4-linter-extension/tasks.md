# Tasks: f4-linter-extension

**Pipeline** : RED → GREEN incrémental. **Single-session, 1 commit final** (cf. ADR-008).

**Volume cible** : ~25 tâches en 11 phases.

**Précondition** : Constitution v1.1.0, F.1 + F.2 archived.

---

## Phase 1 — Harness RED

- [ ] **T001** Créer `.forge/scripts/tests/f4.test.sh` (executable, manifest pattern). ≥ 16 tests L1 + ≥ 6 tests L2. Flag `--level 1,2`. [Story: FR-LE-021]
- [ ] **T002** Lancer `bash f4.test.sh --level 1` — vérifier RED : ~16 FAIL, 0 PASS. [Article I gate]

---

## Phase 2 — Section "Article V" (V.1 task↔FR linkage)

- [ ] **T003** Étendre `.forge/scripts/constitution-linter.sh` avec une nouvelle section `Article V (Constitutional Compliance Gate):`. Skip-guard env var `FORGE_LINTER_SKIP_V_1`. Pour chaque change avec `status` ∈ {planned, implemented, archived}, lit `tasks.md` ; PASS si grep `\[Story: FR-` trouve ≥ 1 occurrence ; FAIL avec format `<change>: tasks.md missing [Story: FR-XXX] audit trail` sinon. Skip-guard examples/. [Story: FR-LE-001..003]

---

## Phase 3 — Section "Article X.3" (Public API doc ratio)

- [ ] **T004** Étendre linter avec section `Article X.3 (Public API Documentation):`. Skip-guard env vars `FORGE_LINTER_SKIP_X_3` et `FORGE_LINTER_X3_THRESHOLD` (default 80). Si `has_flutter` ou `has_rust` détecté, scanner `lib/**/*.dart` + `src/**/*.rs` ; sinon `not_applicable`. [Story: FR-LE-004, FR-LE-008, FR-LE-009]
- [ ] **T005** Implémenter compteur public symbol declarations Dart : grep `^class [A-Z]`, `^abstract class [A-Z]`, `^enum [A-Z]`, `^mixin [A-Z]`, `^[A-Z][a-zA-Z]+ [a-z][a-zA-Z_]*\(`. Compter combien sont précédées d'un `///` (skip blank lines + `@` attributes). [Story: FR-LE-005]
- [ ] **T006** Implémenter compteur Rust : `^pub fn`, `^pub struct`, `^pub enum`, `^pub trait`, `^pub impl`, `^pub const`, `^pub static`, `^pub type`. Compter `///` ou `//!` précédent (skip `#[...]` attributes). [Story: FR-LE-006]
- [ ] **T007** Calculer ratio = documented / total. PASS si ≥ threshold% ; FAIL avec liste des 5 premiers symboles non-documentés (`<file>:<line>:<symbol>`). [Story: FR-LE-007]

---

## Phase 4 — Section "Article XI.3" (GenUI warning)

- [ ] **T008** Étendre linter avec section `Article XI.3 (Generative UI):`. Skip-guard env var `FORGE_LINTER_SKIP_XI_3`. [Story: FR-LE-010, FR-LE-013]
- [ ] **T009** Détecter AI features : (1) `schema: ai-first` dans `.forge.yaml` racine OU (2) grep récursif `anthropic|openai|gpt-|claude|@google/genai|llm|langchain` dans `lib/**/*.dart`, `src/**/*.rs`, `package.json`, `pubspec.yaml`, `Cargo.toml`. Si aucune détection → `not_applicable`. [Story: FR-LE-011]
- [ ] **T010** Si AI détecté : grep UI rendering (`Widget` Dart, `render` TS/HTML), grep schema JSON (`*.schema.json` references). Émettre `warn` (PAS `fail`) si UI rendering présent sans schema JSON. Sinon `pass`. [Story: FR-LE-012]

---

## Phase 5 — Section "Article XI.5" (Fallback tested)

- [ ] **T011** Étendre linter avec section `Article XI.5 (Mandatory Fallback Tested):`. Skip-guard env var `FORGE_LINTER_SKIP_XI_5`. [Story: FR-LE-014, FR-LE-017]
- [ ] **T012** Lister sources `*fallback*` (case-insensitive) : `lib/**/*[fF]allback*.dart`, `src/**/*[fF]allback*.rs`. Pour chaque source : chercher pair `*fallback*_test*` Dart ou `*fallback*` Rust contenant `#[cfg(test)]`/`#[test]`. [Story: FR-LE-015]
- [ ] **T013** Émettre `fail: <source> has no matching *fallback*_test* in test/` si source sans pair. Cas particulier `schema: ai-first` sans aucun fallback → FAIL `Article XI.5 requires a fallback implementation in ai-first projects`. Sinon (no fallback + not ai-first) → `not_applicable`. [Story: FR-LE-016]

---

## Phase 6 — Standard + index

- [ ] **T014** Créer `.forge/standards/global/linting-rules.md` avec ≥ 6 sections H2 (Purpose, Article V.1 — Task ↔ FR Linkage, Article X.3 — Public API Documentation, Article XI.3 — Generative UI Schema (Warning), Article XI.5 — Fallback Testing, Opt-Out Mechanism). Liste exhaustive des env vars + procédure pour proposer une nouvelle règle. [Story: FR-LE-018]
- [ ] **T015** Ajouter entrée `global/linting-rules` dans `.forge/standards/index.yml` avec triggers `linting, constitution-linter, linter rules, public API doc, fallback test, GenUI schema, audit trail`. [Story: FR-LE-019]

---

## Phase 7 — Documentation

- [ ] **T016** Créer `docs/LINTING.md` (≥ 30 lignes) documentant les 4 nouvelles règles, comment opt-out, comment debug un FAIL, limitations heuristiques explicites. [Story: FR-LE-020]

---

## Phase 8 — CI integration

- [ ] **T017** Mettre à jour `.github/workflows/forge-ci.yml` job `harness` : ajouter `- name: f4.test.sh; run: bash .forge/scripts/tests/f4.test.sh --level 1,2` après `f2.test.sh`. [Story: FR-LE-021]

---

## Phase 9 — Verify global GREEN + zéro régression + perf

- [ ] **T018** Lancer `bash f4.test.sh --level 1,2` — vérifier ≥ 22/22 GREEN. [Article I gate]
- [ ] **T019** Lancer `bash constitution-linter.sh` global — vérifier OVERALL PASS post-F.4 (les 4 nouvelles règles retournent `not_applicable` ou `pass` sur le framework repo, sans bruit). [NFR-LE-003]
- [ ] **T020** Lancer `bash verify.sh` global — vérifier 101+ PASS, 0 FAIL. [Article V gate]
- [ ] **T021** Lancer chaque harness (foundations à f4) — vérifier 13 harnais all GREEN. [Article V gate]
- [ ] **T022** Mesurer perf : `time bash constitution-linter.sh` ≤ 3s total. [NFR-LE-001]

---

## Phase 10 — Archive admin

- [ ] **T023** Créer `.forge/specs/linter-extension.md` consolidant FR-LE-001..022 + NFR-LE-001..004 + 6 BDD scenarios. [Story: archive consolidation]
- [ ] **T024** Mettre à jour `.forge/product/roadmap.md` : marquer F.4 ✅ Done en T3. [Story: project tracking]
- [ ] **T025** Mettre à jour `/Users/bfontaine/.claude/plans/il-s-agit-l-d-un-noble-gem.md` : marquer F.4 ✅ Livré T3. **T3 robustesse 100% livré** — tous les facilitateurs F.x archivés. Bascule vers PR optim → main + release v0.3.x à la discrétion utilisateur. [Story: project tracking]
- [ ] **T026** Mettre à jour `CHANGELOG.md` `[Unreleased]` : ajouter `### Added — f4-linter-extension`. **Reste `[Unreleased]`** tant que l'utilisateur ne demande pas la PR/release. [Story: project tracking]
- [ ] **T027** Flip `.forge.yaml` status `archived` + timeline complete. Vérifier que `validate-change-yaml.sh` PASS sur ce fichier (auto-validation F.2). Confirmer Q-001..004 status `answered` dans `open-questions.md`. [Article V gate]

---

## Phase 11 — Commit + push

- [ ] **T028** Stage Phase F.4 (linter sections + standard + index + doc + CI workflow + harness + spec consolidée + roadmap + plan + CHANGELOG + .forge.yaml + open-questions.md). Commit + push. [Article V gate]

---

## Constitutional Compliance Gate (sweep final)

| Tâche | Article violé ? |
|---|---|
| T001-T002 (harness RED) | Aucun. Article I respecté. |
| T003 (V.1 task linkage) | Aucun. Article V renforcé. |
| T004-T007 (X.3 ratio) | Aucun. Article X.3 mécanisé. |
| T008-T010 (XI.3 warning) | Aucun. Article XI.3 partiellement statique. |
| T011-T013 (XI.5 pair) | Aucun. Article XI.5 mécanisé. |
| T014-T015 (standard + index) | Aucun. Article XII (process amendment). |
| T016 (doc) | Aucun. |
| T017 (CI) | Aucun. |
| T018-T022 (verify global + perf) | Aucun. NFR-LE-001..003. |
| T023-T027 (archive admin) | Aucun. |
| T028 (commit) | Aucun. |

**Aucun `[TASK VIOLATION:]`.**

---

**Status** : `planned`. Next : `/forge:implement f4-linter-extension`.

**Mode** : single-session.

**Note T3 final** : F.4 est le **dernier facilitateur T3** identifié dans le plan d'audit. Avec son archive, T3 robustesse 100% livré. La PR `optim → main` + release v0.3.x peuvent être ouvertes à la discrétion utilisateur.
