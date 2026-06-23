# /forge:clarify <name> — Identify Spec Ambiguities

## Purpose
Proactively analyze specifications for ambiguities, undefined terms, missing edge cases, and incomplete requirements before design or implementation begins.

## Agent
Invoke **Clio** (Spec Writer) in audit mode — batch analysis, not stop-on-first.

## Process

1. Read `.forge/changes/<name>/specs.md`
2. Read `.forge/changes/<name>/proposal.md` for additional context
3. Read accumulated specs in `.forge/specs/` for cross-reference

### Check 1: Testability
For each FR-XXX, ask: "Can a tester verify this in 30 minutes?"
- Flag vague verbs: handle, manage, process, support, ensure (without specifics)
- Flag missing quantifiers: "fast", "large", "recent" (without defined thresholds)
- Flag missing actors: "the system" without specifying which component

### Check 2: RFC 2119 Precision
- Every FR MUST use at least one RFC 2119 keyword (MUST/SHALL/SHOULD/MAY)
- MUST and SHOULD must not be mixed in the same bullet (separate into two requirements)
- No requirement without a keyword is acceptable

### Check 3: Error Paths
For every happy-path AC-XXX, check:
- Is there a corresponding error AC? (network failure, invalid input, timeout, auth failure)
- If no error AC exists → flag as missing

### Check 4: Boundary Conditions
- Numeric limits: min, max, defaults defined?
- String limits: max length, allowed characters?
- Collection limits: max items, pagination?
- Time limits: timeouts, expiry, scheduling windows?

### Check 5: Glossary Completeness
- Any term used in requirements that is not in the Glossary section?
- Any Glossary term defined but never referenced in requirements?

### Check 6: Cross-Reference
- Any FR that contradicts another FR? (compare MUST vs MUST NOT across FRs)
- Any FR that depends on another FR not yet specified?

## Output

```
CLARIFICATION QUESTIONNAIRE: <name>
====================================

Priority: BLOCKING (must resolve before /forge:design)

CQ-001 [FR-002]: Term "recent activity" is undefined.
  Context: FR-002 states "MUST display recent activity" but does not define the time window.
  Options:
    A) Last 24 hours
    B) Last 7 days
    C) Configurable per user (add NFR for default)

CQ-002 [AC-003]: Missing error scenario for FR-001.
  Context: AC-003 covers successful login. No AC covers: wrong password, locked account, network failure.
  Recommendation: Add AC-004 (wrong password), AC-005 (locked account), AC-006 (network timeout).

CQ-003 [FR-005]: Vague verb "handle" without specifics.
  Context: FR-005 states "MUST handle concurrent edits" — how? Last-write-wins, merge, conflict UI?
  Options:
    A) Last-write-wins (simpler, potential data loss)
    B) Optimistic concurrency with conflict detection (safer, more complex)

CQ-004 [Glossary]: Term "workspace" used in FR-003, FR-007 but not in Glossary.
  Recommendation: Define "workspace" in the Glossary section.

Summary:
  Blocking questions:       2 (CQ-001, CQ-003)
  Recommended additions:    1 (CQ-002)
  Glossary gaps:            1 (CQ-004)

Next: Resolve all BLOCKING questions, then proceed to /forge:design <name>
      Or re-run /forge:clarify <name> after updates.
```

## When to Use
- After `/forge:specify` and before `/forge:design` — optimal timing
- On-demand — anytime specs feel incomplete or ambiguous
- Recommended: always run before design for non-trivial changes
