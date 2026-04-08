# /forge:onboard — New Contributor Orientation

## Purpose
Guide a new contributor through the project structure, active work, and development workflow. Produces a personalized onboarding summary and first-contribution checklist.

## Process

### Step 1: Constitution Summary
Read `.forge/constitution.md`.
Present a one-sentence summary of each of the 11 articles.
Highlight articles most relevant to the detected tech stack (Flutter → Articles I, II, VI; Rust → Articles I, II, VII).

### Step 2: Product Context
Read `.forge/product/mission.md`.
- If mission has real content: present the mission statement, problem, and target users.
- If mission is still template: note "Product vision not yet defined. Run `/forge:vision` first."

### Step 3: Standards Overview
Read `.forge/standards/index.yml`.
Group standards by scope and present counts:
```
Standards loaded: N total
  Global:        N (TDD, BDD, DDD, SOLID, naming, git, code review)
  Flutter:       N (architecture, state, widgets, testing, DI, networking...)
  Rust:          N (architecture, error handling, async, testing, gRPC...)
  Infra:         N (Docker, K8s, Kong, Temporal, Firebase)
  Observability: N (OTel, SigNoz, ELK, Prometheus)
```
List the critical-priority standards by name.

### Step 4: Active Work
Scan `.forge/changes/` directories.
For each change where status is not `archived`:
```
Active Changes:
  - user-auth: status=planned, next → /forge:implement user-auth
  - search-feature: status=proposed, next → /forge:specify search-feature
```
If no active changes: "No active changes. Start with `/forge:new <name>`."

### Step 5: Accumulated Knowledge
Scan `.forge/specs/` directory.
Count files and FR-XXX/NFR-XXX entries:
```
Accumulated Specs: N files, M requirements
```

### Step 6: Agent Roster
Present the agent delegation table:
```
Forge delegates automatically based on task type:
  Flutter code      → Hera (orchestrator) → Athena, Spartan, Apollo...
  Rust code         → Vulcan (orchestrator) → Ferris, Centurion, Terminal...
  Product analysis  → Pythia
  Specifications    → Clio
  API design        → Hermes-API
  Domain modeling   → Socrates
  Infrastructure    → Atlas
  Observability     → Panoptes
  Security          → Aegis
  CI/CD             → Heracles
  Documentation     → Calliope
  Test strategy     → Eris
  AI features       → Oracle
```

### Step 7: Workflow Walkthrough
```
The Forge Development Cycle:
  1. /forge:propose <name>  — Document the problem and proposed solution
  2. /forge:specify <name>  — Write formal requirements (RFC 2119)
  3. /forge:design <name>   — Architecture decisions and component design
  4. /forge:plan <name>     — Generate TDD-ordered task list
  5. /forge:implement <name> — Execute tasks: RED → GREEN → REFACTOR
  6. /forge:review <name>   — Quality gates (Nemesis/Tribune + Aegis)
  7. /forge:archive <name>  — Merge specs, mark complete

  Shortcuts: /forge:new <name> combines propose + specify
  Master:    /forge auto-detects state and routes to the right phase
```

### Step 8: Codebase Analysis (if code exists)
If `pubspec.yaml` or `Cargo.toml` exists:
- Detect language/framework and version
- List key dependencies (top 10 by relevance)
- Count: source files, test files, test-to-source ratio
- Identify project structure pattern (FSD, hexagonal, monolith, workspace)

### Step 9: First Contribution Checklist
```
FIRST CONTRIBUTION CHECKLIST
=============================
[x] Forge framework installed (constitution.md found)
[ ] Read the constitution: .forge/constitution.md
    Focus on: Article I (TDD), Article II (BDD), Article III (Specs Before Code)
[ ] Understand the spec pipeline: propose → specify → design → plan → implement
[ ] Review active changes: [list or "none"]
[ ] Pick a change to work on, or create new: /forge:new <name>
[ ] Run /forge:status to see current project state
[ ] Set up development environment:
    [Flutter] flutter pub get && flutter analyze
    [Rust]    cargo build && cargo clippy
[ ] Run verification: .forge/scripts/verify.sh
[ ] Make your first change following the TDD cycle (RED → GREEN → REFACTOR)
```

## Output
Formatted onboarding summary with all sections above.
End with: "Welcome to the project. Run `/forge:status` anytime to see where things stand."
