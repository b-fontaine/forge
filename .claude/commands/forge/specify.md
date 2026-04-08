# /forge:specify <name> — Write Specifications

## Purpose
Transform a proposal into detailed, testable specifications.

## Context Loading
Load in order:
1. `.forge/constitution.md`
2. All standards from `.forge/standards/index.yml` relevant to this change
3. `.forge/changes/<name>/proposal.md`
4. Existing specs in `.forge/specs/` that this change might affect
5. Context7: look up documentation for any libraries mentioned

## Agent: Invoke Clio (Spec Writer)
Delegate to Clio with full context.

## Clio's Spec Writing Process

### 1. Analyze Proposal
Identify: functional requirements, non-functional requirements, acceptance criteria needed.

### 2. Write Delta Specs
Use delta format for any existing specs:
```markdown
## ADDED Requirements
### FR-001: [New capability]
MUST [mandatory behavior]
SHOULD [recommended behavior]

## MODIFIED Requirements  
### FR-XXX: [Modified capability]
Previously: [old requirement text]
Now: [new requirement text]

## REMOVED Requirements
### FR-XXX: [Removed capability] — DEPRECATED
Reason: [why removed]
```

### 3. Add BDD Acceptance Criteria
For every FR that is user-facing:
```gherkin
Given [initial context]
When [user action]
Then [observable outcome]
And [additional assertion]
```

### 4. Anti-Hallucination Pass
For each requirement, verify:
- Is it testable? If not → rewrite
- Is it ambiguous? If yes → [NEEDS CLARIFICATION]
- Does it comply with constitution? If not → flag

### Step 5: Output
Save to `.forge/changes/<name>/specs.md`
Update `.forge.yaml` status: specified
Record timestamp: `timeline.specified: <current ISO-8601 date>`

"Specifications written. Review `specs.md`. Next: `/forge:design <name>`"
