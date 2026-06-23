# /forge:verify <name> — Verify Spec-to-Code Alignment

## Purpose
Verify that implementation is complete, correct, and coherent relative to its specifications. Unlike `/forge:review` (which checks code quality via Nemesis/Tribune), verify checks traceability from spec to code.

## Dimensions

### 1. Completeness
- Every FR-XXX in specs.md has at least one corresponding task in tasks.md
- Every task in tasks.md marked `[x]` has corresponding source code
- Every AC-XXX has a test (unit, widget, or BDD `.feature`)
- No FR-XXX is left without implementation

### 2. Correctness
- Implementation matches the MUST/SHALL requirements in specs.md
- Edge cases from AC-XXX error scenarios are handled in code
- NFR constraints (performance, availability) have verification mechanisms
- Delta format respected: ADDED items are new, MODIFIED items differ from previous, REMOVED items are gone

### 3. Coherence
- design.md ADRs are reflected in actual code structure
- Naming in code matches the Glossary in specs.md
- Architecture boundaries from design.md are respected in file organization
- Component relationships in Mermaid diagrams match actual imports/dependencies

## Process

1. Read `.forge/changes/<name>/specs.md` — extract all FR-XXX, AC-XXX, NFR-XXX IDs
2. Read `.forge/changes/<name>/design.md` — extract all ADR-XXX decisions
3. Read `.forge/changes/<name>/tasks.md` — extract all tasks with `[Story: FR-XXX]` references
4. For each FR-XXX: trace → specs.md entry → tasks.md task(s) → test file(s) → source file(s)
5. For each AC-XXX: trace → Gherkin scenario → `.feature` file or test assertion
6. For each ADR-XXX: trace → design decision → actual code pattern
7. Build traceability matrix and identify gaps

## Output

```
VERIFICATION REPORT: <name>
=============================

Traceability Matrix:
  FR-001 → tasks [TASK-3,5] → tests [test_auth.dart] → code [auth_usecase.dart]     ✓
  FR-002 → tasks [TASK-7]   → tests [MISSING]         → code [N/A]                   GAP
  FR-003 → tasks [TASK-9]   → tests [order_test.rs]   → code [order.rs]              ✓
  AC-001 → .feature [login.feature]                                                    ✓
  AC-002 → [NO TEST FOUND]                                                             GAP
  ADR-001 → flutter_bloc used in checkout/                                             ✓
  ADR-002 → [DIVERGENCE: design says Repository pattern, code uses direct DB calls]    GAP

Dimension Results:
  Completeness:  FAIL (1 FR without tests, 1 AC without scenario)
  Correctness:   PASS
  Coherence:     FAIL (1 ADR divergence)

OVERALL: FAIL (3 issues found)

Issues:
  1. [COMPLETENESS] FR-002 has no tests — assign to Spartan/Centurion
  2. [COMPLETENESS] AC-002 has no .feature file — assign to Spartan/Centurion
  3. [COHERENCE] ADR-002 divergence — assign to Athena/Ferris
```

## When to Use
- Before `/forge:review` — catch alignment issues before quality gates
- After implementation phase — verify all specs are covered
- On-demand — check traceability at any time
