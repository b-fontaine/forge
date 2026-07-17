# User Guide — Forge

---

## What is Forge?

Forge is a spec-driven development framework that turns Claude Code into a structured, multi-agent
development team. It merges seven complementary approaches into a coherent system:

| Source               | Contribution                                           |
|----------------------|--------------------------------------------------------|
| **BMAD Method**      | Persona-agents with persistent names, roles, and styles |
| **GitHub SpecKit**   | Blocking gates and conformance verification            |
| **OpenSpec**         | Semantic deltas (ADDED/MODIFIED/REMOVED)               |
| **Agent OS v3**      | On-demand standards injection via `index.yml`          |
| **Superpowers**      | Non-negotiable TDD, anti-rationalization table         |
| **oh-my-claudecode** | Natural keywords, multi-agent orchestration            |
| **Context7**         | Real-time API documentation resolution                 |

The core principle: **specs are the source code of intent**. Before writing a single line of code, Forge
guides you through documenting the problem, the solution, the architecture decisions, and the TDD tasks. The
code then becomes a natural consequence of the spec, not an improvisation.

---

## Installation

### New project

1. Copy the Forge files to the project root:
   ```bash
   cp -r forge/ /path/to/your/project/
   ```

2. Open Claude Code and run:
   ```
   /forge
   ```

3. Follow the auto-detected flow — Forge detects that no state exists and runs `/forge:init` then `/forge:vision`.

### Existing project

1. Copy Forge to the project root as above.

2. Run the initialization:
   ```
   /forge:init
   ```

3. Capture the existing conventions:
   ```
   /forge:discover
   ```
   Forge analyzes your codebase and extracts the patterns, conventions, and standards already in place, then
   documents them in `.forge/standards/`.

---

## The `/forge` Master Command

`/forge` is the single entry point. It reads the project state and automatically routes you to the right phase.

```
/forge
   |
   v
[.forge/ exists?]
   |          |
   No         Yes
   |           |
   v           v
/forge:init  [vision.md exists?]
              |              |
              No             Yes
              |               |
              v               v
         /forge:vision   [changes/ contains folders?]
                              |                    |
                              No                   Yes
                              |                    |
                              v                    v
                       /forge:explore    [which state per folder?]
                                              |
                              +--------------+---------------+
                              |              |               |
                              v              v               v
                          propose/       specify/         design/
                          (→ specify)   (→ design)       (→ plan)
                              |              |               |
                              v              v               v
                           plan/         implement/       review/
                          (→ impl)       (→ review)      (→ archive)
```

State detection is deterministic: Forge reads the files present in `.forge/changes/<name>/` to identify where
you are in the cycle.

---

## The Development Cycle

### Step 1 — Vision (`/forge:vision`)

Define the product's mission and value proposition. Forge guides Oracle (the AI-First agent) and you to produce:

- Mission statement (one sentence)
- Value proposition (3 bullets)
- Target users
- Problems solved
- Output: `.forge/product/mission.md`

### Step 2 — Exploration (`/forge:explore`)

Free brainstorming session with Oracle. Forge does not block — this is the ideation phase. Oracle facilitates an
AI-First assessment: does this feature benefit from AI? If so, how? This phase produces unstructured
notes in `.forge/product/exploration/`.

### Step 3 — Proposal (`/forge:propose <name>`)

Formally document the problem and the proposed solution. Clio (Spec Writer) guides you to write:

- Context and motivation
- Problem description
- Proposed solution
- Alternatives considered
- Acceptance criteria (high level)
- Output: `.forge/changes/<name>/proposal.md`

### Step 4 — Specification (`/forge:specify <name>`)

Clio writes the delta specs using RFC 2119 language (MUST, SHOULD, MAY). Delta format: only the changes relative
to the current state are documented (ADDED, MODIFIED, REMOVED). Output: `.forge/changes/<name>/specs.md`

### Step 5 — Design (`/forge:design <name>`)

Athena (Flutter) or Ferris (Rust) — or Socrates for the business domain — produce:

- Architecture Decision Records (ADRs)
- Component diagrams
- Interface contracts
- Technical decisions documented with justification
- Output: `.forge/changes/<name>/design.md`

### Step 6 — Planning (`/forge:plan <name>`)

Generation of an ordered task list for TDD. Each task follows the format:

```
TASK-001: [Description]
  Test: [Which test to write first — RED]
  Implementation: [What to implement — GREEN]
  Refactor: [What to clean up — REFACTOR]
```

The task order is designed so that each task builds on the previous one.

### Step 7 — Implementation (`/forge:implement <name>`)

Execution of the next uncompleted task in the plan. The cycle is strict:

1. **RED** — Write the test. Watch it fail.
2. **GREEN** — Write the minimum code to make the test pass.
3. **REFACTOR** — Clean up without breaking the tests.

Spartan (Flutter) or Centurion (Rust) enforces this cycle without exception. No rationalization is accepted.

### Step 8 — Review + Archive (`/forge:review` + `/forge:archive`)

**Review**: Nemesis (Flutter) or Tribune (Rust) apply the quality gates:

- Sufficient test coverage?
- Constitution respected?
- Technical standards validated?
- Design implemented faithfully?

**Archive**: Once the review passes, the delta specs are merged into `.forge/specs/`, the change folder
is marked `DONE`, and a summary is added to the project log.

---

## The Agents

### Flutter Team (led by Hera)

| Agent                | Name       | Specialty                                  |
|----------------------|------------|--------------------------------------------|
| Flutter Orchestrator | Hera       | Team coordination, feature workflow        |
| Flutter Architect    | Athena     | Clean Architecture, FSD, DI                |
| Flutter TDD-BDD      | Spartan    | Test enforcement, zero tolerance           |
| Flutter UX/UI        | Apollo     | Cross-platform design, Material 3          |
| Flutter Widgets      | Hephaestus | Custom widgets, animations                 |
| Flutter Performance  | Hermes     | Profiling, optimization                    |
| Flutter A11y & i18n  | Iris       | Accessibility, internationalization        |
| Flutter OTel         | Argus      | Client-side instrumentation                |
| Flutter AI           | Prometheus | Voice, GenUI, agents                       |
| Flutter Quality      | Nemesis    | Final gate, delegation                     |

### Rust Team (led by Vulcan)

| Agent             | Name      | Specialty                     |
|-------------------|-----------|-------------------------------|
| Rust Orchestrator | Vulcan    | Team coordination             |
| Rust Architect    | Ferris    | Hexagonal architecture, gRPC  |
| Rust TDD-BDD      | Centurion | Test enforcement              |
| Rust TUI          | Terminal  | ratatui, Elm architecture     |
| Rust OTel         | Sentinel  | Server-side instrumentation   |
| Rust Quality      | Tribune   | Final gate                    |

### Cross-Cutting Agents

| Agent               | Name     | Specialty                            |
|---------------------|----------|--------------------------------------|
| Forge Master        | Forge    | Orchestration, routing               |
| Spec Writer         | Clio     | Requirements, RFC 2119               |
| DDD Strategist      | Socrates | Domain modeling, Event Storming      |
| AI-First Brainstorm | Oracle   | AI workshop, agent architecture      |
| AI/RAG Specialist   | Sibyl    | RAG, embeddings, retrieval tuning    |
| Infra Architect     | Atlas    | Docker, K8s, Kong, Temporal          |
| Observability       | Panoptes | OTel, SigNoz, ELK, Prometheus        |
| Security Auditor    | Aegis    | Security audit, OWASP                |
| Data Steward EU     | Demeter  | Tier classification, DPA, CLOUD Act  |
| Frontend Web Specialist | Iris-Web | Qwik / SvelteKit public-web conventions, distinct from Hera (Flutter) |
| Compliance Officer EU | Themis | NIS2/DORA/CRA, standards-review cycle |
| Event-Driven Messenger | Hermes-Async | AsyncAPI 3.1, NATS/Kafka bindings, idempotency keys, distinct from Hermes (Flutter perf) |
| DevOps Engineer     | Heracles | CI/CD, deployment                    |

---

## Compatibility

### Superpowers

TDD delegation works as follows: when `/forge:implement` is invoked, Forge determines the context (Flutter or
Rust), then delegates to the appropriate TDD agent (Spartan or Centurion). This agent has an anti-rationalization
table of 12 common excuses with their rebuttals, and refuses any argument for skipping RED or going straight to code.

### oh-my-claudecode

Forge integrates with OMC's keyword triggers:

| Keyword     | Behavior                                                   |
|-------------|------------------------------------------------------------|
| `autopilot` | Full pipeline execution from the current state             |
| `ulw`       | Ultrawork mode — deep implementation without interruption  |
| `team`      | Explicit delegation to the multi-agent team                |

### Context7

Documentation resolution happens in two steps via the MCP server:

1. `resolve-library-id` — identify the library in the Context7 catalog
2. `query-docs` — retrieve up-to-date documentation for the relevant APIs

This ensures that Forge always works with current documentation, not with potentially outdated training data.

---

## AI Modeling Integration

### The workshop facilitated by Oracle

Oracle (the AI-First agent) facilitates a structured 5-phase workshop for any potentially AI feature:

1. **Discovery** — Identify the real need. Is this really an AI problem?
2. **Capability mapping** — Which AI capabilities are relevant? (LLM, vision, speech, embeddings...)
3. **Architecture** — How to integrate without coupling? Ports & Adapters.
4. **Non-determinism strategy** — How to test something non-deterministic?
5. **Fallback design** — What happens if the AI fails or is unavailable?

### The 3 AImigos

The 3 AImigos concept transposes the 3 Amigos model to the AI context:

- **Product** (real need?) — Does AI bring real value here, or is it feature-ism?
- **Dev** (feasible?) — What are the technical constraints? Latency, cost, available models?
- **Test** (how to test non-determinism?) — Behavior contracts, semantic snapshots, LLM-based
  evaluation?

---

## Custom Schemas

Forge supports 5 predefined schemas that adapt the pipeline to the project context:

| Schema        | Use case            | Specifics                                           |
|---------------|---------------------|-----------------------------------------------------|
| `default`     | Standard flow       | All phases, balanced                                |
| `tdd-flutter` | Flutter application | + Golden tests, explicit BDD phase                  |
| `tdd-rust`    | Rust application    | + Hexagonal architecture, clippy enforcement        |
| `rapid`       | Rapid prototype     | 4 minimal phases (TDD still mandatory)              |
| `ai-first`    | AI-native product   | + Oracle workshop phase, non-determinism evaluation |

To apply a schema, add to `.forge.yaml`:

```yaml
schema: tdd-flutter
```

The `rapid` schema does not remove TDD — it compresses the documentation phases. The constitution still applies.

---

## Philosophy

**Belief 1: Specs are the source code of intent**

Code is ephemeral — it will be refactored, rewritten, deleted. Specs are the durable record of what was decided
and why. A project without specs is a project whose intent is lost with every team rotation.

**Belief 2: TDD is non-negotiable, never optional**

TDD is not one best practice among others. It is the way of working. Every task, without exception, begins with
a failing test. "We're short on time" and "it's too simple to test" are catalogued rationalizations —
Spartan and Centurion know them all.

**Belief 3: Quality is structural, not a matter of willpower**

The quality gates, the constitution, the agents dedicated to review — all of this is there to make quality
inevitable. In a team project, we don't rely on individual discipline. We build systems where doing things
correctly is the path of least resistance.
