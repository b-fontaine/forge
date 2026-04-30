# Spec: <!-- change-name -->
<!-- Delta format: ADDED, MODIFIED, REMOVED sections only -->

## ADDED Requirements

### FR-001: <!-- Requirement name -->
- **MUST**: <!-- Mandatory behavior — non-negotiable -->
- **SHALL**: <!-- Commitment the system makes -->
- **SHOULD**: <!-- Recommended behavior, can deviate with justification -->
- **MAY**: <!-- Optional enhancement -->

**Constitution Reference**: Article <!-- N -->
**Testable**: <!-- Yes — how it will be verified -->

<!-- Add more FR-XXX as needed, incrementing from last used ID -->

## MODIFIED Requirements
<!-- Only include if modifying existing requirements from .forge/specs/ -->

### FR-XXX: <!-- Existing requirement name -->
**Previously**: <!-- exact previous text -->
**Now**: <!-- new text -->
**Reason**: <!-- why this changed -->

## REMOVED Requirements
<!-- Only include if deprecating existing requirements -->

### FR-XXX: <!-- Requirement name --> — DEPRECATED
**Reason**: <!-- why removed -->
**Replacement**: <!-- FR-XXX if replaced, or "no replacement" -->

---

## Acceptance Criteria
<!-- One AC block per user-facing FR. Written as Gherkin. -->

### AC-001 — Links FR-001: <!-- FR name -->
```gherkin
Given <!-- initial context, state of the system -->
When <!-- user action or event -->
Then <!-- observable outcome -->
And <!-- additional assertions if needed -->
```

### AC-002 — Links FR-001: <!-- Edge case or error scenario -->
```gherkin
Given <!-- edge case context -->
When <!-- same action -->
Then <!-- different outcome, e.g., error message -->
```

## Non-Functional Requirements

### NFR-001: Performance
- **MUST**: <!-- response time target, e.g., "p95 < 200ms" -->

### NFR-002: Reliability
- **SHALL**: <!-- uptime target, error rate -->

## Out of Scope
<!-- Explicit exclusions to prevent scope creep -->
- 

## Open Questions
<!-- [NEEDS CLARIFICATION: specific question] — blocks progress until resolved -->
