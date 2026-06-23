# /forge:implement <name> — Execute Implementation

## Purpose
Execute the next unchecked task in TDD order.

## Task Selection
1. Read `.forge/changes/<name>/tasks.md`
2. Find first unchecked task `- [ ]`
3. Extract story reference `[Story: FR-XXX]`
4. Check if task is `[P]` (parallelizable)

## Context Injection
For the selected task:
1. Load constitution
2. Load relevant standards via index.yml triggers (match task description to triggers)
3. Load Context7 docs for any libraries the task requires:
   - resolve-library-id → query-docs
4. Load change context: proposal + specs + design

## Agent Routing
- Task involves Flutter code → Delegate to **Hera** (Flutter Orchestrator)
- Task involves Rust code → Delegate to **Vulcan** (Rust Orchestrator)
- Task involves infrastructure → Delegate to **Atlas**
- Task involves observability → Delegate to **Panoptes**

## TDD Protocol (NON-NEGOTIABLE)
The implementing agent MUST follow:
```
1. Write the failing test
2. Run: `flutter test` or `cargo test` — MUST SEE RED
3. Write minimal production code
4. Run test again — MUST SEE GREEN
5. Refactor if needed
6. Run test again — MUST STAY GREEN
```

If RED is not confirmed → STOP and report
If GREEN not achieved → STOP and report, do not continue

## Task Completion
After successful RED→GREEN→REFACTOR:
1. Mark task as checked: `- [x]`
2. Update `.forge.yaml` if all tasks complete: status: implemented
   Record timestamp: `timeline.implemented: <current ISO-8601 date>`
3. Ask: "Task complete. Continue with next task? (yes/no)"

## Blocked State
If task cannot be completed:
- Output reason
- Do NOT skip to next task
- Ask for guidance
