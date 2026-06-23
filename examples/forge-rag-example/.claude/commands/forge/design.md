# /forge:design <name> — Create Technical Design

## Purpose
Transform specifications into technical architecture decisions.

## Agent Routing
Based on change content:
- Flutter changes → Invoke **Athena** (Flutter Architect)
- Rust changes → Invoke **Ferris** (Rust Architect)
- Infrastructure changes → Invoke **Atlas** (Infrastructure Architect)
- API-related changes → Invoke **Hermes-API** (API Designer) for contract design
- All changes → Invoke **Eris** (Test Architect) for test strategy
- Full-stack → Invoke Athena + Ferris + Atlas + Hermes-API + Eris

## Context Loading
1. `.forge/constitution.md`
2. All relevant standards
3. `.forge/changes/<name>/specs.md`
4. Context7: resolve documentation for all libraries to be used

## Design Document Structure
```markdown
# Design: <name>

## Architecture Decisions

### ADR-001: [Decision]
**Context**: [Why this decision is needed]
**Decision**: [What was decided]
**Consequences**: [Trade-offs]
**Constitution Compliance**: Article N confirmed

## Component Design
[Mermaid class/component diagram]

## Data Flow
[Mermaid sequence diagram for key flows]

## Testing Strategy
- Unit tests: [what to test at unit level]
- Widget/integration tests: [what to test at higher level]
- BDD scenarios: [which FR-XXX get full BDD]

## Standards Applied
- [Standard ID]: [how it's applied]
```

## Constitutional Compliance Gate
BEFORE saving design:
- Does this violate Article I (TDD)? → BLOCK
- Does this violate Article VI (Flutter arch)? → BLOCK
- Does this violate Article VII (Rust arch)? → BLOCK
- Does this violate any other article? → BLOCK

If BLOCK: output `[CONSTITUTION VIOLATION: Article N - specific violation]` and stop.

Save to `.forge/changes/<name>/design.md`
Update `.forge.yaml` status: designed
Record timestamp: `timeline.designed: <current ISO-8601 date>`

"Design complete. Review `design.md`. Next: `/forge:plan <name>`"
