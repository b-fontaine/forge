# Architecture — Forge

---

## Overview

Forge is a collection of Markdown files executed by an LLM. There is no runtime, no binary, no
package to install. The "runtime" is Claude Code + the Claude LLM.

**The fundamental insight: the Markdown IS the code.**

Agent definitions, slash commands, technical standards, and skills are all Markdown files that
shape the LLM's behavior. When Claude Code loads `.claude/agents/flutter/hera.md`, Hera exists. When
the file is not loaded, Hera does not exist. There is no magic — just context injected in a controlled way.

This model has an important implication: **the quality of the Markdown determines the quality of the
behavior**. A poorly defined agent produces unpredictable behavior. An ambiguous command produces
inconsistent results. Forge treats its Markdown files with the same care as a production codebase.

---

## Annotated Structure

```
forge/
├── CLAUDE.md                    # Entry point — read automatically by Claude Code
│                                # Loads global instructions, references agents,
│                                # defines base behaviors
│
├── .mcp.json                    # MCP configuration (Context7)
│                                # Declares the MCP server for doc resolution
│
├── .forge/
│   ├── constitution.md          # The supreme law — 11 articles, no violation tolerated
│   │                            # Every agent, every command, every output must comply with it
│   │
│   ├── standards/               # Technical rules injected dynamically
│   │   ├── index.yml            # Catalog with triggers — orchestration of injection
│   │   │                        # Each entry: id, path, triggers, scope, priority
│   │   ├── global/              # Cross-cutting standards (TDD, BDD, DDD, SOLID, naming...)
│   │   ├── flutter/             # Flutter standards (architecture, tests, UI...)
│   │   ├── rust/                # Rust standards (architecture, error handling, async...)
│   │   ├── infra/               # Infrastructure standards (Docker, K8s, Kong, Temporal...)
│   │   └── observability/       # Observability standards (OTel, SigNoz, ELK, Prometheus)
│   │
│   ├── schemas/                 # Customizable workflows per project type
│   │   ├── default/             # Standard pipeline
│   │   ├── tdd-flutter/         # Flutter + golden tests + BDD
│   │   ├── tdd-rust/            # Rust + hexagonal + clippy
│   │   ├── rapid/               # 4 minimal phases
│   │   └── ai-first/            # With Oracle workshop phase
│   │
│   ├── product/                 # Product vision and context
│   │   ├── vision.md            # Mission, value proposition, target users
│   │   └── exploration/         # Brainstorming notes (unstructured)
│   │
│   ├── changes/                 # In-progress changes (one folder per feature/fix)
│   │   └── <name>/
│   │       ├── proposal.md      # Problem + proposed solution
│   │       ├── specs.md         # RFC 2119 delta specs
│   │       ├── design.md        # ADRs + technical decisions
│   │       └── tasks.md         # Ordered TDD plan
│   │
│   ├── specs/                   # Accumulated specs (result of archives)
│   │                            # Project knowledge base — grows over time
│   │
│   └── templates/               # Templates for each artifact
│       ├── proposal.md          # Proposal template
│       ├── specs.md             # Delta specs template
│       ├── design.md            # Design / ADR template
│       └── tasks.md             # Task plan template
│
├── .claude/
│   ├── commands/forge/          # Claude Code slash commands
│   │   ├── forge.md             # /forge — master command with state detection
│   │   ├── init.md              # /forge:init
│   │   ├── discover.md          # /forge:discover
│   │   ├── vision.md            # /forge:vision
│   │   ├── new.md               # /forge:new
│   │   ├── propose.md           # /forge:propose
│   │   ├── specify.md           # /forge:specify
│   │   ├── design.md            # /forge:design
│   │   ├── plan.md              # /forge:plan
│   │   ├── implement.md         # /forge:implement
│   │   ├── review.md            # /forge:review
│   │   ├── archive.md           # /forge:archive
│   │   ├── explore.md           # /forge:explore
│   │   └── status.md            # /forge:status
│   │
│   ├── agents/                  # Agent definitions (personas + rules)
│   │   │   ├── forge-master.md      # Main agent (Forge)
│   │   ├── spec-writer.md       # Clio
│   │   ├── ddd-strategist.md    # Socrates
│   │   ├── ai-first-brainstorm.md # Oracle
│   │   ├── infra-architect.md   # Atlas
│   │   ├── observability-specialist.md # Panoptes
│   │   ├── security-auditor.md  # Aegis
│   │   ├── devops-engineer.md   # Heracles
│   │   ├── product-analyst.md   # Pythia (PRFAQ, competitive analysis)
│   │   ├── technical-writer.md  # Calliope (docs, changelogs)
│   │   ├── api-designer.md      # Hermes-API (OpenAPI, gRPC)
│   │   ├── test-architect.md    # Eris (test strategy, mutation testing)
│   │   ├── flutter/             # Flutter team (Hera, Athena, Spartan...)
│   │   └── rust/                # Rust team (Vulcan, Ferris, Centurion...)
│   │
│   ├── skills/                  # Skills auto-injected by Claude Code
│   │   ├── forge-tdd/SKILL.md   # TDD enforcement + anti-rationalization
│   │   ├── forge-bdd/SKILL.md   # BDD enforcement + Given/When/Then
│   │   └── forge-docs/SKILL.md  # Context7 — API doc resolution
│   │
│   └── commands/forge/          # Slash commands (19 total)
│       ├── forge.md             # Master command + state detection
│       ├── init.md, discover.md, vision.md
│       ├── new.md, propose.md, specify.md, design.md, plan.md
│       ├── implement.md, review.md, archive.md
│       ├── explore.md, status.md
│       ├── verify.md            # Spec-to-code alignment (NEW)
│       ├── clarify.md           # Ambiguity detection (NEW)
│       ├── onboard.md           # Contributor orientation (NEW)
│       ├── diff.md              # Semantic spec diffing (NEW)
│       └── metrics.md           # Velocity metrics (NEW)
│
└── docs/                        # Human documentation (you are here)
    ├── GUIDE.md
    ├── ARCHITECTURE.md
    └── CONTRIBUTING.md
```

---

## Data Flow

```
User idea
      |
      v
/forge (state detection)
      |
      +---> Reads .forge/changes/ to detect the current state
      |
      v
Proposal (Clio)
      |
      v
Delta specs — RFC 2119 (Clio)
      |                         <--- Constitution check (at each phase)
      v
Design / ADRs (Athena | Ferris | Socrates)
      |
      v
TDD plan (ordered tasks)
      |                         <--- Standards injection (index.yml, JIT)
      v
TDD implementation             <--- Context7 (external APIs, real-time docs)
  RED → GREEN → REFACTOR
  (Spartan | Centurion)
      |
      v
Review (Nemesis | Tribune)
      |
      v
Archive → .forge/specs/
  (delta specs merged, state = DONE)
```

The Constitution is checked at each phase transition. An agent cannot produce a design that violates
Article I (mandatory tests) or continue an implementation that does not respect the injected
standards. The gate is blocking, not advisory.

---

## Borrowed Patterns

| Pattern                    | Source           | Usage in Forge                                 |
|----------------------------|------------------|------------------------------------------------|
| Agent-personas             | BMAD Method      | Each agent has a persistent name, role, style  |
| Blocking gates             | GitHub SpecKit   | Constitution check blocks on violation         |
| Semantic deltas            | OpenSpec         | ADDED/MODIFIED/REMOVED instead of rewrite      |
| Standards injection        | Agent OS v3      | index.yml with triggers for JIT injection      |
| Anti-rationalization table | Superpowers      | 12 TDD excuses with rebuttals                  |
| Natural keywords           | oh-my-claudecode | autopilot, ulw, team trigger behaviors         |
| Real-time docs             | Context7         | MCP server for up-to-date external APIs        |

---

## Context Management

An LLM's context window is a limited resource. Forge adopts 4 strategies to use it efficiently.

### 1. index.yml — JIT Injection of Standards

Standards are NOT all loaded at the same time. `index.yml` defines triggers (keywords, file patterns,
phases) that trigger the loading of a specific standard. If you are working on a Flutter component, only the
relevant Flutter standards are injected — not the Rust standards, not the infra standards.

Example entry in `index.yml`:

```yaml
- id: flutter-clean-architecture
  path: standards/flutter/clean-architecture.md
  triggers:
    - flutter
    - usecase
    - repository
    - domain
  scope: implementation
  priority: high
```

This avoids saturating the context window with irrelevant rules.

### 2. Micro-files

Each agent, command, and standard is a separate file. Only what is necessary for the current task is loaded.
A monolithic 50,000-token file would be loaded in full on every invocation — micro-files allow a
surgical selection.

### 3. Isolated Subagents

Delegating to a subagent (Spartan, Athena, etc.) creates an isolated context for that specialist. Spartan
does not need to know the history of the product vision to enforce TDD. This isolation avoids cross-contamination
and allows each agent to stay focused on its mission.

### 4. Separate Context7

The documentation for external libraries is fetched on demand via the MCP server, not stored in the
framework. Storing the Flutter SDK docs in Forge would be: (a) bulky, (b) quickly outdated, (c) loaded even
when unnecessary. Context7 solves all three problems.

---

## Extensibility

### Axis 1 — New Standards

1. Create `.forge/standards/<domain>/<name>.md` with the required format (Scope, Rules, Anti-patterns)
2. Add an entry in `.forge/standards/index.yml` with precise triggers

The triggers must be specific enough not to trigger the standard in irrelevant contexts.
Prefer precise technical terms over general words.

### Axis 2 — New Agents

1. Create `.claude/agents/<team>/<name>.md` with: Persona (Name, Role, Style), Purpose, Expertise, Workflow, Rules
2. Reference the new agent from the appropriate orchestrator: Hera for Flutter, Vulcan for Rust, Forge for
   cross-cutting

Naming convention: Greek mythology for Flutter, Latin/Roman for Rust, mixed for cross-cutting.

### Axis 3 — New Schemas

1. Create `.forge/schemas/<name>/schema.yaml` with the definition of phases, gate conditions, and tool
   configurations
2. Test the schema with a real project from start to finish

A schema can remove optional phases (exploration, detailed design) but can never make TDD
optional — that is a violation of the constitution.

---

## Known Limitations

**Context window** — Loading too many standards simultaneously can saturate Claude's context window. The
triggers in `index.yml` must be calibrated carefully. For complex projects with many standards,
watch for signs of quality degradation that would indicate saturation.

**Non-determinism** — Different executions can produce different outputs. The standards and the
constitution reduce variance but do not eliminate it. For critical architectural decisions, a human
review is recommended in addition to the review by Nemesis/Tribune.

**No real CI** — The quality gates are evaluated by the LLM, not by automated tools. "The constitution is
respected" is a judgment made by the agent, not a unit test that passes or fails. For critical projects, combine
the Forge gates with a real CI (GitHub Actions, etc.) that runs the real tests.
