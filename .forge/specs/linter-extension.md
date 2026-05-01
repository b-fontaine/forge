# Spec: linter-extension

<!-- Audit: F.4 (f4-linter-extension) — 4 nouvelles règles dans constitution-linter.sh. -->
<!-- Source change : `.forge/changes/f4-linter-extension/` (archived 2026-05-01). -->

**Namespace** : `FR-LE-*` / `NFR-LE-*`.

**Constitution** : v1.1.0. Pas d'amendement.

---

## Functional Requirements

### Cluster 1 — Article V.1 (Task ↔ FR linkage)

#### FR-LE-001 — Section "Article V" in linter

`constitution-linter.sh` MUST contenir une section
`Article V (Constitutional Compliance Gate):`.

#### FR-LE-002 — Audit trail check

Pour chaque change avec `status` ∈ {planned, implemented, archived} :
PASS si `tasks.md` contient ≥ 1 `[Story: FR-` ; FAIL sinon avec
format `<change>: tasks.md missing [Story: FR-XXX] audit trail`.

#### FR-LE-003 — Skip-guard env var

`FORGE_LINTER_SKIP_V_1=1` désactive la règle. Skip-guard `examples/`.

---

### Cluster 2 — Article X.3 (Public API doc ratio)

#### FR-LE-004 — Section "Article X.3" in linter

Section dédiée `Article X.3 (Public API Documentation):`.

#### FR-LE-005 — Dart heuristic

Compteur public symbols Dart : classes, abstract classes, enums,
mixins, top-level functions ; check `///` précédent (skip blank
lines + `@`-attributes).

#### FR-LE-006 — Rust heuristic

Compteur Rust : `^pub\s+(fn|struct|enum|trait|const|static|type|impl)\b` ;
check `///` ou `//!` précédent (skip `#[...]` attributes).

#### FR-LE-007 — Ratio threshold

PASS si ratio `documented/total` ≥ threshold (default 80%) ;
FAIL avec liste des 5 premiers symboles non-documentés sinon.

#### FR-LE-008 — Skip when no source

Si aucun fichier Dart/Rust → `not_applicable`.

#### FR-LE-009 — Threshold override + opt-out

`FORGE_LINTER_X3_THRESHOLD=<n>` override. `FORGE_LINTER_SKIP_X_3=1`
désactive.

---

### Cluster 3 — Article XI.3 (GenUI warning)

#### FR-LE-010 — Section "Article XI.3" in linter

Section dédiée. Opt-out `FORGE_LINTER_SKIP_XI_3=1`.

#### FR-LE-011 — AI detection

`schema: ai-first` dans root `.forge.yaml` OU grep AI imports
(`anthropic|openai|gpt-|claude|@google/genai|llm|langchain`) dans
sources + manifests. Si rien → `not_applicable`.

#### FR-LE-012 — UI rendering + schema check

Si AI détecté ET UI rendering (`Widget|render`) sans schema JSON
référencé → **WARN** (pas FAIL). Le warning incrémente WARN
counter, n'affecte pas exit code.

#### FR-LE-013 — Opt-out

`FORGE_LINTER_SKIP_XI_3=1`.

---

### Cluster 4 — Article XI.5 (Fallback tested)

#### FR-LE-014 — Section "Article XI.5" in linter

Section dédiée. Opt-out `FORGE_LINTER_SKIP_XI_5=1`.

#### FR-LE-015 — Fallback source detection

Lister `lib/**/*[fF]allback*.dart`, `src/**/*[fF]allback*.rs` ;
chercher pair test :
- Dart : `test/**/*[fF]allback*_test*.dart` OU
  `test/**/*[fF]allback*.dart`.
- Rust : `tests/**/*[fF]allback*.rs` OU `#[cfg(test)]`/`#[test]` in source.

#### FR-LE-016 — Pair check

FAIL si source sans pair. Cas particulier `schema: ai-first` sans
fallback → FAIL `Article XI.5 requires a fallback implementation`.
Sinon (no fallback + not ai-first) → `not_applicable`.

#### FR-LE-017 — Opt-out

`FORGE_LINTER_SKIP_XI_5=1`.

---

### Cluster 5 — Standard

#### FR-LE-018 — `linting-rules.md`

`.forge/standards/global/linting-rules.md` avec ≥ 6 sections H2
(Purpose, Article V.1, Article X.3, Article XI.3, Article XI.5,
Opt-Out Mechanism) documentant heuristiques + limitations + opt-outs.

#### FR-LE-019 — Index entry

`global/linting-rules` enregistré dans `index.yml`.

---

### Cluster 6 — Documentation

#### FR-LE-020 — `docs/LINTING.md`

Guide ≥ 30 lignes documentant les 4 règles, comment opt-out,
comment debug, limitations heuristiques.

---

### Cluster 7 — Harness

#### FR-LE-021 — `f4.test.sh`

Pattern manifest, ≥ 16 L1 + ≥ 6 L2 fixture-based. Enregistré dans CI.

---

### Cluster 8 — Périmètre négatif

#### FR-LE-022 — No prohibited touch

Pas de `cli/src/`, pas d'amendement Constitution, pas de modification
des changes archivés ou des règles existantes du linter (Articles
I/II/III/III.4/IV/VI/VII/VIII/IX/X.1/X.2/X.4/X.5/X.6/XI.1/XI.2/XI.4/XI.6).

---

## Non-Functional Requirements

### NFR-LE-001 — Performance

`constitution-linter.sh` total ≤ **3 secondes** sur projet Forge actuel.
Mesuré : 1.97s.

### NFR-LE-002 — No new dep

Pas de nouvelle dep pip/system. PyYAML déjà disponible.

### NFR-LE-003 — Backward compatibility

Linter OVERALL PASS post-F.4 sur framework repo (les 4 nouvelles
règles retournent `not_applicable` ou `pass` sans bruit).

### NFR-LE-004 — 100 % FR coverage

Chaque FR-LE-* couvert par ≥ 1 test L1/L2.

---

## Acceptance Criteria (BDD)

6 scénarios documentés dans `.forge/changes/f4-linter-extension/specs.md` :

1. V.1 task audit trail FAIL
2. X.3 doc ratio FAIL avec liste manquants
3. XI.3 GenUI WARNING (pas FAIL)
4. XI.5 fallback test pair FAIL
5. Opt-out via env var (skipped message)
6. Forge framework repo (no sources) → all NEW rules `not_applicable`, OVERALL PASS

---

## Constitution Compliance Summary

- **Article I (TDD)** : `f4.test.sh` 23/23 PASS RED→GREEN. ✅
- **Article II (BDD)** : 6 scénarios. ✅
- **Article III (Specs Before Code)** : pipeline complet. ✅
- **Article III.4 (Anti-hallucination)** : 4 questions Q-001..004 résolues via F.1 dogfooding. ✅
- **Article IV (Delta-based)** : ADDED-only ; règles existantes intactes. ✅
- **Article V (Process Gates)** : F.4 EST le renforcement de cet article. ✅
- **Articles VI/VII/VIII/IX/XI** : F.4 ajoute des règles linter pour XI.3 et XI.5 ; ne modifie pas les règles existantes. ✅
- **Article X (Quality)** : X.3 nouvelle règle, NFR perf 1.97s/3s. ✅
- **Article XII (Governance)** : `constitution_version: "1.1.0"`. ✅
