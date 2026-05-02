# Specs: f4-linter-extension

**Namespace** : `FR-LE-*` / `NFR-LE-*` (Linter Extension).

**Constitution** : v1.1.0. Pas d'amendement.

**Décisions** : ≥ 1 FR-link in tasks.md (Q-001), ratio 80% + skip
no-source (Q-002), warning-only XI.3 (Q-003), name-based fallback
pair (Q-004).

---

## ADDED Requirements

### Cluster 1 — Article V.1 (Task ↔ FR linkage)

#### FR-LE-001 — Section "Article V" in linter

`.forge/scripts/constitution-linter.sh` MUST inclure une section
`Article V (Constitutional Compliance Gate):` qui itère sur tous les
changes.

#### FR-LE-002 — Audit trail check

Pour chaque change avec `status` ∈ {`planned`, `implemented`, `archived`}
ET `tasks.md` présent :
- Vérifier que `tasks.md` contient au minimum **1 occurrence** de
  `[Story: FR-` (regex `\[Story: FR-`).
- Si oui : `pass` per-change line.
- Si non : `fail` per-change line avec format
  `<change>: tasks.md missing [Story: FR-XXX] audit trail`.

#### FR-LE-003 — V.1 skip-guard

Skip-guard `examples/` (FR-GL-026 cohérent). Skip-guard env var
`FORGE_LINTER_SKIP_V_1=1` désactive la règle complètement (output
`skipped via FORGE_LINTER_SKIP_V_1`).

---

### Cluster 2 — Article X.3 (Public API doc ratio)

#### FR-LE-004 — Section "Article X.3" in linter

Section `Article X.3 (Public API Documentation):` dans le linter.

#### FR-LE-005 — Dart public symbol detection

Pour chaque fichier `lib/**/*.dart` (récursif) :
- Compter les **public symbol declarations** via heuristique :
  - `^class [A-Z]` (top-level class)
  - `^abstract class [A-Z]` (abstract class)
  - `^enum [A-Z]` (top-level enum)
  - `^mixin [A-Z]` (top-level mixin)
  - `^[A-Z][a-zA-Z]+ [a-z][a-zA-Z_]*\(` (top-level function returning a typed class)
- Pour chaque déclaration, vérifier si la ligne précédente
  (skip blank lines, attributes `@`) contient `///`.
- Calculer ratio `documented / total`.

#### FR-LE-006 — Rust public symbol detection

Pour chaque fichier `src/**/*.rs` :
- Compter `^pub fn`, `^pub struct`, `^pub enum`, `^pub trait`,
  `^pub impl`, `^pub const`, `^pub static`, `^pub type`.
- Vérifier `///` ou `//!` immédiatement précédente (skip attributes
  `#[...]`).

#### FR-LE-007 — Ratio threshold

Émettre :
- `pass` si ratio ≥ 0.80 (80%).
- `fail` si ratio < 0.80, avec liste des **5 premiers** symboles
  manquants (`<file>:<line>:<symbol> missing /// doc`).

#### FR-LE-008 — Skip when no source

Si aucun fichier source Dart (`lib/**/*.dart`) ET aucun Rust
(`src/**/*.rs`) → `not_applicable: No source directories found`.

#### FR-LE-009 — Threshold override

Env var `FORGE_LINTER_X3_THRESHOLD` (default `80`) permet d'ajuster.
Env var `FORGE_LINTER_SKIP_X_3=1` désactive complètement.

---

### Cluster 3 — Article XI.3 (GenUI schema-driven warning)

#### FR-LE-010 — Section "Article XI.3" in linter

Section `Article XI.3 (Generative UI):` dans le linter.

#### FR-LE-011 — AI imports detection (heuristic)

Détecter présence d'AI :
- `schema: ai-first` dans `.forge.yaml` racine du projet, OU
- pattern grep récursif `anthropic|openai|gpt-|claude|@google/genai|llm|langchain` dans `lib/**/*.dart`, `src/**/*.rs`, `package.json`, `pubspec.yaml`, `Cargo.toml`.

Si aucune détection → `not_applicable: No AI features detected`.

#### FR-LE-012 — UI rendering presence

Si AI détecté ET fichiers UI (`Widget` dans Dart, `render` dans
TS/HTML/templates) sont présents :
- Chercher la présence d'au moins 1 fichier `*.schema.json`
  référencé dans le code (`schema.json` dans imports/strings).
- Émettre :
  - `pass` si schema JSON présent.
  - **`warn`** (PAS `fail`) si absent : `XI.3 heuristic warning: AI features + UI rendering detected without coexisting *.schema.json reference. Manual audit recommended.`

#### FR-LE-013 — Opt-out

Env var `FORGE_LINTER_SKIP_XI_3=1` désactive.

---

### Cluster 4 — Article XI.5 (Fallback tested)

#### FR-LE-014 — Section "Article XI.5" in linter

Section `Article XI.5 (Mandatory Fallback Tested):` dans le linter.

#### FR-LE-015 — Fallback source detection

Lister les fichiers source matchant case-insensitive
`*fallback*` :
- Dart : `lib/**/*[fF]allback*.dart`
- Rust : `src/**/*[fF]allback*.rs`

Pour chaque fichier source identifié :
- Chercher un test pair par convention de nommage :
  - Dart : `test/**/*[fF]allback*_test.dart` OU
    `test/**/*[fF]allback*.dart`
  - Rust : `tests/**/*[fF]allback*.rs` OU `src/**/*[fF]allback*.rs`
    contenant `#[cfg(test)]` ou `#[test]`.

#### FR-LE-016 — Pair check

Pour chaque source `*fallback*` sans test pair :
- Émettre `fail: <source> has no matching *fallback*_test* in test/`.

Si aucun fichier `*fallback*` source ET schema != `ai-first` →
`not_applicable: No fallback files and not an AI-first project`.

Si `schema: ai-first` mais aucun `*fallback*` source du tout →
`fail: AI-first schema requires fallback implementation (Article XI.5)`.

#### FR-LE-017 — Opt-out

Env var `FORGE_LINTER_SKIP_XI_5=1` désactive.

---

### Cluster 5 — Standard

#### FR-LE-018 — Standard `linting-rules.md`

Créer `.forge/standards/global/linting-rules.md` avec ≥ 6 sections H2 :
- Purpose
- Article V.1 — Task ↔ FR Linkage
- Article X.3 — Public API Documentation
- Article XI.3 — Generative UI Schema (Warning)
- Article XI.5 — Fallback Testing
- Opt-Out Mechanism

Le standard documente :
- Heuristiques utilisées par chaque règle.
- Limites connues (XI.3 dynamique, X.3 ratio fragile, etc.).
- Toutes les env vars d'opt-out (`FORGE_LINTER_SKIP_V_1` etc.).
- Procédure pour proposer une nouvelle règle (process Article XII).

#### FR-LE-019 — Index entry

`.forge/standards/index.yml` MUST registrer `global/linting-rules`
avec triggers `linting, constitution-linter, linter rules,
public API doc, fallback test, GenUI schema, audit trail`.

---

### Cluster 6 — Documentation

#### FR-LE-020 — Docs `LINTING.md`

`docs/LINTING.md` (nouveau) ou section dans `docs/GUIDE.md` MUST
contenir ≥ 30 lignes documentant :
- Les 4 nouvelles règles (V.1, X.3, XI.3, XI.5).
- Comment opt-out (env vars).
- Comment debug un FAIL.
- Limitations heuristiques explicites.

---

### Cluster 7 — Harness

#### FR-LE-021 — Harness `f4.test.sh`

`.forge/scripts/tests/f4.test.sh` MUST :
- Pattern manifest, ≥ 16 tests L1 + ≥ 6 tests L2 fixture-based.
- Tests L1 : présence des sections dans linter, présence du
  standard + index entry, présence doc, registration CI.
- Tests L2 fixture-based pour chaque règle :
  - V.1 : fixture change `planned` avec tasks.md sans FR-link → FAIL ;
    avec FR-link → PASS.
  - X.3 : fixture lib/ avec ratio < 80% → FAIL ; avec ratio ≥ 80% → PASS ;
    sans lib/ → not_applicable.
  - XI.3 : fixture avec AI imports + Widget sans schema → WARN ;
    avec schema → PASS ; sans AI → not_applicable.
  - XI.5 : fixture avec `fallback.dart` sans test pair → FAIL ;
    avec test pair → PASS.
- Test env var opt-outs (par règle).
- Enregistré dans CI workflow.

---

### Cluster 8 — Périmètre négatif

#### FR-LE-022 — No prohibited touch

F.4 NE DOIT PAS modifier :
- `cli/src/**`
- `.forge/constitution.md` (pas d'amendement)
- Les changes archivés
- Les schémas d'archetypes
- Les règles existantes du linter (Articles I, II, III, III.4,
  IV, VI, VII, VIII, IX, X.1, X.2, X.4, X.5, X.6, XI.1, XI.2,
  XI.4, XI.6) — F.4 ajoute uniquement.

---

## Non-Functional Requirements

### NFR-LE-001 — Performance

`constitution-linter.sh` complet (incluant les 4 nouvelles règles)
MUST exécuter en ≤ **3 secondes** total sur le projet Forge actuel.
Mesuré via `time`. Avant F.4 : ~1 seconde ; budget +2 secondes.

### NFR-LE-002 — No new dep

PyYAML déjà disponible. Pas de nouvelle dep.

### NFR-LE-003 — Backward compatibility

`constitution-linter.sh` global MUST rester `OVERALL PASS` post-F.4
sur `optim` (le framework repo n'a ni source Dart/Rust ni AI features
ni fallbacks ; les 4 nouvelles règles retournent `not_applicable`
ou `pass` sans bruit).

### NFR-LE-004 — 100 % FR coverage

Chaque FR-LE-NNN MUST avoir ≥ 1 test L1 ou L2 dans `f4.test.sh`.

---

## Acceptance Criteria (BDD)

### Scénario 1 — V.1 task audit trail

```gherkin
Given a change with status: planned and tasks.md without [Story: FR-XXX]
When the maintainer runs constitution-linter.sh
Then the linter emits "FAIL: <change>: tasks.md missing [Story: FR-XXX] audit trail"
And the linter exits non-zero
```

### Scénario 2 — X.3 doc ratio

```gherkin
Given a Dart library with 10 public classes and only 6 with /// doc
When the maintainer runs constitution-linter.sh
Then the linter computes ratio = 60% < 80%
And emits "FAIL: Article X.3: doc ratio 60% below threshold 80%"
And lists the first 5 missing-doc symbols
```

### Scénario 3 — XI.3 GenUI warning

```gherkin
Given a project with `import 'package:claude/claude.dart'` AND Widget code
And no *.schema.json file referenced
When the maintainer runs constitution-linter.sh
Then the linter emits a WARNING (not FAIL) "XI.3 heuristic warning: ..."
And the overall result remains PASS unless other rules fail
```

### Scénario 4 — XI.5 fallback test pair

```gherkin
Given a file lib/ai/translation_fallback.dart with no corresponding test
When the maintainer runs constitution-linter.sh
Then the linter emits "FAIL: lib/ai/translation_fallback.dart has no matching *fallback*_test* in test/"
```

### Scénario 5 — Opt-out via env var

```gherkin
Given the maintainer sets FORGE_LINTER_SKIP_X_3=1
When the maintainer runs constitution-linter.sh
Then the Article X.3 section emits "skipped via FORGE_LINTER_SKIP_X_3"
And the linter exits 0 even if X.3 violations would otherwise FAIL
```

### Scénario 6 — Forge framework repo (no sources)

```gherkin
Given the Forge framework repo with no Dart/Rust source code
When the maintainer runs constitution-linter.sh
Then Article X.3 emits "not_applicable: No source directories found"
And Article XI.3 emits "not_applicable: No AI features detected"
And Article XI.5 emits "not_applicable: No fallback files..."
And the overall result remains OVERALL PASS
```

---

## Anti-Hallucination Pass

| FR | Testable ? | Ambigu ? | Conforme Constitution ? |
|---|---|---|---|
| FR-LE-001..003 (V.1) | ✅ L2 fixture | ❌ | ✅ Article V |
| FR-LE-004..009 (X.3) | ✅ L2 fixture + ratio | ❌ | ✅ Article X.3 |
| FR-LE-010..013 (XI.3) | ✅ L2 fixture warning | ❌ | ✅ Article XI.3 |
| FR-LE-014..017 (XI.5) | ✅ L2 fixture pair | ❌ | ✅ Article XI.5 |
| FR-LE-018..019 (standard) | ✅ presence + grep | ❌ | ✅ |
| FR-LE-020 (docs) | ✅ presence | ❌ | ✅ |
| FR-LE-021 (harness) | ✅ manifest count | ❌ | ✅ Article I |
| FR-LE-022 (negative scope) | ✅ git diff | ❌ | ✅ |

**Aucun `[NEEDS CLARIFICATION:]` restant.** 4 questions Q-001..004
résolues dans `open-questions.md`.

---

## Constitution Compliance Summary

- **Article I (TDD)** : `f4.test.sh` RED→GREEN. ✅
- **Article II (BDD)** : 6 scénarios documentés. ✅
- **Article III (Specs Before Code)** : pipeline complet. ✅
- **Article III.4 (Anti-hallucination)** : 4 questions Q-NNN trackées + résolues via F.1. ✅
- **Article IV (Delta-based)** : ADDED-only. ✅
- **Article V (Process Gates)** : F.4 EST le renforcement de cet article. ✅
- **Articles VI/VII/VIII/IX/XI** : F.4 ajoute des règles linter pour XI.3 et XI.5 ; ne modifie pas les règles existantes des autres articles. ✅
- **Article X (Quality)** : X.3 nouvelle règle ; X.1, X.2, X.4, X.5, X.6 inchangés. ✅
- **Article XII (Governance)** : `constitution_version: "1.1.0"`. ✅

---

**Status** : `specified`. Next : `/forge:design f4-linter-extension`.
