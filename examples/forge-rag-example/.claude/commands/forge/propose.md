# /forge:propose <name> — Create a Change Proposal

## Purpose
Create a new change in `.forge/changes/<name>/` and write the proposal document.

## Process

### Step 1: Create Directory Structure
```
.forge/changes/<name>/
├── .forge.yaml      # Change metadata
├── proposal.md      # Problem and solution
├── specs.md         # (created by /forge:specify)
├── design.md        # (created by /forge:design)
└── tasks.md         # (created by /forge:plan)
```

### Step 2: Initialize .forge.yaml
```yaml
name: <name>
status: proposed
created: <ISO-8601 date>
schema: default
constitution_version: "1.0.0"
```

### Step 2b: Record Timeline
The `.forge.yaml` `timeline.proposed` is set to the same value as `created`.

### Step 2c: Product Context (Optional)
If the proposal involves a new product area or market analysis is needed, invoke **Pythia** (Product Analyst) for PRFAQ and competitive analysis before proceeding.

### Step 3: Generate Proposal
Load the proposal template and fill in based on context:

```markdown
# Proposal: <name>

## Problem
[What user pain or technical need does this address?]

## Solution
[High-level description of the approach]

## Scope In
- [Capability 1]
- [Capability 2]

## Scope Out (Explicit Exclusions)
- [What is NOT included, to prevent scope creep]

## Impact
- **Users affected**: [who]
- **Technical impact**: [components touched, complexity]
- **Dependencies**: [other changes required first]

## Constitution Compliance
- Article I (TDD): [How TDD will be applied]
- Article II (BDD): [User-facing features to get BDD scenarios]
- Article III (Specs Before Code): [Confirmed: spec-first approach]
- Article VI or VII: [Flutter or Rust architecture compliance]
```

### Step 4: Constitution Check
Verify proposal does not violate any constitution article.
If violation found → output `[CONSTITUTION VIOLATION: Article N - description]` and STOP.

### Step 5: Gate
"Proposal created at `.forge/changes/<name>/proposal.md`. 
Review and confirm before proceeding to → `/forge:specify <name>`"
