# Spec: open-questions

<!-- Audit: F.1 (f1-open-questions) — Article III.4 mechanisation. -->
<!-- Source change : `.forge/changes/f1-open-questions/` (archived 2026-05-01). -->

**Namespace** : `FR-OQ-*` / `NFR-OQ-*`.

**Constitution** : v1.1.0. Pas d'amendement requis (F.1 mécanise l'article III.4 existant).

---

## Functional Requirements

### Cluster 1 — Standard

#### FR-OQ-001 — Standard

`.forge/standards/global/open-questions.md` MUST exister avec 8 sections H2
(Purpose, File Location and Lifecycle, Question Schema, Status Enum,
Resolution Block, Verify Gate, Linter Rule, Discovery) + ≥ 3
Interdictions (no modify answered, no reuse Q-NNN, no inline marker in
implemented/archived).

#### FR-OQ-002 — Index entry

`.forge/standards/index.yml` MUST registrer `global/open-questions`
avec triggers `open-questions, NEEDS CLARIFICATION, Q-001,
clarification, anti-hallucination, Article III.4, forge-questions.sh`.

---

### Cluster 2 — Schema convention

#### FR-OQ-003 — File location

Per-change : `.forge/changes/<name>/open-questions.md`. Pas d'alternative.

#### FR-OQ-004 — Required sections per question

H2 `## Q-NNN: <Title>` + bullet-list (Status, Raised in, Raised on,
Raised by, optional Reference) + H3 `### Question`. Si Status != open,
H3 `### Resolution` (Resolved on / by / Decision / Rationale / Resolved in).

#### FR-OQ-005 — Q-NNN format

Regex `^Q-[0-9]{3}$`, séquentiel par change, jamais réutilisé.

#### FR-OQ-006 — Status enum

`open` | `answered` | `wontfix`. Aucune autre valeur.

#### FR-OQ-007 — Backwards compatibility

Absence du fichier = aucune question = OK. Rétrocompat avec les 10 changes archivés pré-F.1.

---

### Cluster 3 — Template

#### FR-OQ-008 — Template stub

`.forge/templates/open-questions.md.tmpl` avec en-tête `# Open Questions — {{change-name}}` + commentaire pédagogique.

---

### Cluster 4 — verify.sh gate

#### FR-OQ-009 — Section "Open Questions Gate"

Section dédiée `── Open Questions Gate ──` dans `verify.sh`.

#### FR-OQ-010 — FAIL on archived + open

Pour chaque change `archived` avec ≥ 1 question `Status: open` → FAIL `<change> has N open question(s) but is archived`.

#### FR-OQ-011 — PASS on archived without file

Absence de `open-questions.md` → SKIP (rétrocompat).

#### FR-OQ-012 — Skip-guard examples/

Le gate respecte `is_under_examples` (FR-GL-026 cohérent).

---

### Cluster 5 — constitution-linter rule

#### FR-OQ-013 — Rule "no NEEDS CLARIFICATION inline"

Pour chaque change `implemented` ou `archived`, scan
proposal/specs/design/tasks.md à la recherche de `[NEEDS CLARIFICATION:`.
Exclusions : marqueur dans backticks, dans commentaire HTML, dans bloc
de code fencé (\`\`\`...\`\`\`).

#### FR-OQ-014 — FAIL format

`FAIL  <change>:<file>:<line>: NEEDS CLARIFICATION inline detected`.

---

### Cluster 6 — Discovery script

#### FR-OQ-015 — `bin/forge-questions.sh`

Exécutable, mode par défaut = lister les questions `Status: open`.

#### FR-OQ-016 — Output format

`<change>:Q-NNN  <Title>  (raised <date> by <handle>)` trié par
`Raised on` ascendant.

#### FR-OQ-017 — Filter flags

`--change <name>` et `--status <open|answered|wontfix>`.

---

### Cluster 7 — Skill scaffold

#### FR-OQ-018 — Skill or fallback doc

Le skill `/forge:propose` scaffold un stub `open-questions.md` SI le
skill est modifiable. Fallback : standard documente la création
manuelle. Test L1 accepte les 2 cas.

---

### Cluster 8 — Documentation

#### FR-OQ-019 — Docs reference

`docs/OPEN_QUESTIONS.md` (livré) ou `docs/GUIDE.md` doit contenir une
section "Open Questions" ≥ 30 lignes.

---

### Cluster 9 — Harness

#### FR-OQ-020 — Harness `f1.test.sh`

Pattern manifest, ≥ 12 L1 + ≥ 5 L2 fixture-based, enregistré CI.

---

### Cluster 10 — Périmètre négatif

#### FR-OQ-021 — No prohibited touch

Pas de `cli/src/`, pas d'amendement Constitution, pas de touch des changes archivés.

#### FR-OQ-022 — No backfill

Les 10 changes archivés pré-F.1 (b1-*, g1, c1, a7, b5-1, d5, b4) NE DOIVENT PAS recevoir de `open-questions.md` rétrospectivement.

---

## Non-Functional Requirements

### NFR-OQ-001 — No new dep
Pas de nouvelle dépendance npm/pip/system au-delà de bash/grep/awk/find.

### NFR-OQ-002 — verify.sh perf
Section "Open Questions Gate" ajoute < 500ms.

### NFR-OQ-003 — Backward compatibility hard
Aucun change archivé existant ne devient FAIL post-F.1.

### NFR-OQ-004 — 100 % FR couverts
Chaque FR-OQ-* a ≥ 1 test L1/L2.

---

## Acceptance Criteria (BDD)

6 scénarios documentés dans `.forge/changes/f1-open-questions/specs.md` § "Acceptance Criteria (BDD)" : raise question, resolve, archive blocked by open, linter blocked by NEEDS CLARIFICATION, transverse list, filter by change.

---

## Constitution Compliance Summary

- **Article I (TDD)** : `f1.test.sh` 17 tests RED→GREEN. ✅
- **Article II (BDD)** : 6 scénarios documentés. ✅
- **Article III (Specs Before Code)** : pipeline complet. ✅
- **Article III.4 (Anti-hallucination)** : F.1 EST la mécanique. ✅
- **Article IV (Delta-based)** : ADDED-only namespace. ✅
- **Article V (Process Gates)** : nouveau gate verify.sh + nouvelle règle linter. ✅
- **Articles VI/VII/VIII/IX/XI** : NA. ✅
- **Article X (Quality)** : NFR-OQ-002 (perf), NFR-OQ-003 (rétrocompat). ✅
- **Article XII (Governance)** : `constitution_version: "1.1.0"`. ✅
