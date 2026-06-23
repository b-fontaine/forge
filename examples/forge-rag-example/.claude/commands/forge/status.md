# /forge:status — Project Status Report

## Purpose
Show complete state of the Forge project.

## Report Format

```
# Forge Status Report
Generated: <date>

## Product
- Mission: [first line of mission.md, or "Not defined"]
- Stack: [from tech-stack.md, or "Not defined"]

## Standards
- Total: [count from index.yml]
- Scopes: flutter ([n]), rust ([n]), infra ([n]), observability ([n]), global ([n])

## Active Changes
[For each change in .forge/changes/ where status != archived:]
- **<name>** — Status: [status] — Phase: [current phase] — Next: /forge:[command] <name>
  Tasks: [X]/[Y] complete

## Completed Changes
[Count of archived changes]

## Specs (Accumulated)
- Files: [count in .forge/specs/]  
- Requirements: [count FR-XXX entries]
- BDD Scenarios: [count Given/When/Then blocks]

## Quality Metrics
[If metrics available from last review:]
- Test coverage: [X]%
- flutter analyze: [clean/warnings]
- cargo clippy: [clean/warnings]

## Suggestions
[Based on state:]
- No active changes → "Start with /forge:new <feature-name>"
- Changes in propose state → "Run /forge:specify <name> to write specs"
- All tasks done → "Run /forge:review <name> to check quality"
```
