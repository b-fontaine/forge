# Specs — `t7-ci-line-budget-440`

**Namespace** : `FR-T7CB-*`, `NFR-T7CB-*`.

---

## Functional Requirements

### FR-T7CB-001 — the cap is 440, in all five harnesses

`c1.test.sh`, `g1.test.sh`, `t5-1.test.sh`, `t5-otel-live-run.test.sh` and
`b6-8.test.sh` (`CI_LINE_BUDGET`). All five, or CI is red at 421.

### FR-T7CB-002 — the two documents follow

`.forge/specs/forge-ci.md` `NFR-CI-002` and
`.forge/standards/global/forge-self-ci.md`, each carrying the reason and the date, as
the four prior bumps did.

### FR-T7CB-003 — both documents say five, not four

Corrected on evidence: `b6-8` fires on an over-budget workflow and was not listed.

### FR-T7CB-004 — the structural remedy is recorded where the next bump will look

Both documents state that the array costs one line per harness, that it is 102 of 420
lines, that externalising it frees ~80, and that the measured obstacle is 30 harnesses
reading the workflow with ≥7 grepping it for their own name.

### FR-T7CB-005 — CHANGELOG

---

## Non-Functional Requirements

### NFR-T7CB-001 — the workflow itself is untouched

Zero lines added to `forge-ci.yml`. This brick raises a ceiling; it does not build under
it.

### NFR-T7CB-002 — the lock-step set is measured, not read

Established by pushing the workflow over the cap and recording which harnesses fire —
the method that caught the stale list, and the one the standard now prescribes.
