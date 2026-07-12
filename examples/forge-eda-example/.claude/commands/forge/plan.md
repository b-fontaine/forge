# /forge:plan <name> — Generate Implementation Tasks

## Purpose
Break down the design into TDD-ordered implementation tasks.

## Context Loading
Load: constitution + all standards + proposal + specs + design

## Task Generation Rules

### Task Format
```markdown
- [ ] [Task description] [Story: FR-XXX] [P if parallelizable]
```

### Required Task Ordering
For every feature, tasks MUST follow TDD order:
1. Write failing test (RED)
2. Run test — verify it fails
3. Write minimal implementation (GREEN)  
4. Run test — verify it passes
5. Refactor if needed
6. Repeat for next feature

### Phase Structure
```markdown
# Tasks: <name>

## Phase 1: Foundation
[Domain model, interfaces, test utilities]

## Phase 2: Core Implementation  
[Use cases, repositories, BLoC — all TDD]

## Phase 3: Integration
[Adapters, UI, E2E tests]

## Phase 4: Quality
[Golden tests, a11y, performance, observability]
```

### Parallelizable Tasks
Mark tasks that can run simultaneously:
- `[P]` = can be done in parallel with other `[P]` tasks in same phase

## Constitutional Compliance Gate (Per Task)
For EACH task, verify:
- Does implementing this task require violating TDD? → BLOCK
- Does it bypass specs? → BLOCK
- Does it violate architecture articles? → BLOCK

Output: `[TASK VIOLATION: task X violates Article N - reason]`

Save to `.forge/changes/<name>/tasks.md`
Update `.forge.yaml` status: planned
Record timestamp: `timeline.planned: <current ISO-8601 date>`

"Tasks generated. Review `tasks.md`. Next: `/forge:implement <name>`"
