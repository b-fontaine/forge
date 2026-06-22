# Forge Framework — Claude Code Integration

<EXTREMELY_IMPORTANT>
## Non-Negotiable Rules

1. **READ SKILL FILES FIRST**: Before ANY action, check `.claude/skills/` for applicable skills. If a skill has even a 1% chance of applying, it MUST be invoked (the 1% Rule).
   - Working on Dart/Flutter code → invoke `forge-tdd` + `forge-bdd`
   - Working on Rust code → invoke `forge-tdd` + `forge-bdd`
   - Using external libraries → invoke `forge-docs`

2. **TDD IS MANDATORY AND NON-NEGOTIABLE**: NEVER write production code without a failing test first. The cycle is immutable:
   - RED: Write failing test
   - Verify RED: Run test, confirm failure
   - GREEN: Write minimal code to pass
   - Verify GREEN: Run test, confirm pass
   - REFACTOR: Improve without changing behavior
   
   There are NO exceptions. "Too simple to test" is not an excuse.

3. **SPECS BEFORE CODE**: Never implement without a spec in `.forge/changes/`. The pipeline is: Proposal → Specs → Design → Tasks → Implementation.

4. **CONSTITUTION IS LAW**: Every decision must comply with `.forge/constitution.md`. Violations BLOCK progress.

5. **ANTI-HALLUCINATION PROTOCOL**: When uncertain about requirements, APIs, or behavior, output `[NEEDS CLARIFICATION: your specific question]` and STOP. Never guess.

6. **CONTEXT7 FOR DOCS**: Before using any external library, resolve its documentation via Context7 MCP. Never rely on training data for API signatures.

7. **QUALITY GUARDIAN BEFORE MERGE**: All code must pass quality gates (Nemesis for Flutter, Tribune for Rust) before being considered complete.
</EXTREMELY_IMPORTANT>

## About Forge

Forge is a spec-driven development framework that combines the best patterns from BMAD Method, GitHub SpecKit, OpenSpec, Agent OS v3, Superpowers, oh-my-claudecode, and Context7.

**Core Philosophy**:
- Specs are the source code of intent
- TDD is non-negotiable, not optional
- Quality is structural, not willpower-based

**Full documentation**: `.forge/constitution.md`, `docs/GUIDE.md`

## The `/forge` Command

Run `/forge` as your primary entry point. It auto-detects project state:
1. No constitution → `/forge:init`
2. No standards → `/forge:discover`
3. No mission → `/forge:vision`
4. Active changes → continue the active change's current phase
5. No active changes → suggests `/forge:explore` or `/forge:new`

Use specific commands for direct control:
- `/forge:new <name>` — Start a new feature/change
- `/forge:implement <name>` — Continue implementing a change
- `/forge:status` — View project state
- `/forge:review <name>` — Run quality gates

## Agent Delegation System

Forge uses specialized agents. Delegation is automatic:

| Trigger | Agent | Role |
|---------|-------|------|
| Flutter code | **Hera** | Flutter Team Orchestrator |
| Rust code | **Vulcan** | Rust Team Orchestrator |
| Infrastructure | **Atlas** | Infra Architect |
| Observability | **Panoptes** | Observability Specialist |
| AI features | **Oracle** | AI-First Brainstorm |
| AI/RAG tuning | **Sibyl** | AI/RAG Specialist |
| Data stewardship | **Demeter** | Data Steward EU |
| Writing specs | **Clio** | Spec Writer |
| Domain modeling | **Socrates** | DDD Strategist |
| Security audit | **Aegis** | Security Auditor |

**Flutter sub-team** (dispatched by Hera): Athena (architecture), Spartan (TDD/BDD), Apollo (UX/UI), Hephaestus (widgets), Hermes (performance), Iris (a11y/i18n), Argus (OpenTelemetry), Prometheus (AI), Nemesis (quality gate).

**Rust sub-team** (dispatched by Vulcan): Ferris (architecture), Centurion (TDD/BDD), Terminal (TUI), Sentinel (OpenTelemetry), Tribune (quality gate).

## Standards Injection

Standards are loaded dynamically via `.forge/standards/index.yml`. When working on a task, inject relevant standards based on triggers defined in the index. Always load:
- Constitution (always)
- Relevant technology standards (Flutter/Rust/Infra/Observability)
- TDD/BDD rules (always for implementation)

## Context7 Integration

Context7 MCP server is configured in `.mcp.json`. Usage protocol:
1. Identify the external library being used
2. Call `mcp__context7__resolve-library-id` with library name
3. Call `mcp__context7__query-docs` with resolved ID
4. Use the returned documentation for accurate API usage

**Never use training data for external library API signatures** — they change between versions.

## Compatibility

- **Superpowers**: If installed, TDD delegation goes to Superpowers TDD skill. Keywords: `"tdd"`, `"test first"`
- **oh-my-claudecode**: Keywords work normally. `"autopilot"` → autopilot mode, `"ulw"` → ultrawork, `"team"` → team mode
- **Context7**: Configured via `.mcp.json` — always available for doc lookups

## 7 Key Rules (Summary)

1. TDD always — RED before GREEN, always
2. Specs before code — no implementation without `.forge/changes/<n>/`
3. BDD Given/When/Then for every user-facing feature
4. Constitution respected — violations block, period
5. `[NEEDS CLARIFICATION]` instead of guessing
6. Context7 for external library docs
7. Quality guardian (Nemesis/Tribune) before marking anything complete
