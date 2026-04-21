# Forge — Spec-Driven Development Framework for Claude Code

> Turn Claude Code into a structured, multi-agent development team that never skips the spec.

---

## Quickstart

Pick whichever channel fits your workflow.

**A — `curl | sh` (no Node required)**

```bash
curl -fsSL https://raw.githubusercontent.com/bfontaine/forge/main/bin/forge-install.sh | bash
```

**B — `@forge/cli` (npm)**

```bash
npx @forge/cli init
# or install globally
npm install -g @forge/cli && forge init
```

**C — Docker (CI)**

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace forge/linter:latest
```

**Then**, open Claude Code in the project directory and run `/forge`. It
auto-detects state and routes you to the right phase.

Installation guarantees (shared by A and B):

- Idempotent — re-runs never clobber your edits without `--force`.
- `.forge/product/*` is always scaffolded from templates, so your mission
  and roadmap are yours, not Forge's.
- Private Claude Code state (`.claude/settings.local.json`) is never copied.

---

## Commands

| Command                   | Description                                          |
|---------------------------|------------------------------------------------------|
| `/forge`                  | Master command — auto-detects state and routes       |
| `/forge:init`             | Initialize Forge (new or existing project)           |
| `/forge:discover`         | Extract existing conventions as standards            |
| `/forge:vision`           | Define product mission and value proposition         |
| `/forge:new <name>`       | Start a new feature (propose + specify)              |
| `/forge:propose <name>`   | Create a change proposal                             |
| `/forge:specify <name>`   | Write delta specifications                           |
| `/forge:design <name>`    | Create technical design                              |
| `/forge:plan <name>`      | Generate TDD-ordered task list                       |
| `/forge:implement <name>` | Execute next task (TDD cycle)                        |
| `/forge:review <name>`    | Run quality gates                                    |
| `/forge:archive <name>`   | Merge specs and mark complete                        |
| `/forge:explore`          | Free brainstorm / research                           |
| `/forge:verify <name>`    | Verify spec-to-code alignment (3 dimensions)         |
| `/forge:clarify <name>`   | Identify spec ambiguities before design              |
| `/forge:diff <name>`      | Semantic spec diff (ADDED/MODIFIED/REMOVED)          |
| `/forge:metrics`          | Development velocity metrics and bottleneck analysis |
| `/forge:onboard`          | New contributor orientation and checklist            |
| `/forge:status`           | Full project state report                            |

---

## Agents

### Flutter Team (led by Hera)

| Agent                | Name       | Specialty                           |
|----------------------|------------|-------------------------------------|
| Flutter Orchestrator | Hera       | Team coordination, feature workflow |
| Flutter Architect    | Athena     | Clean Architecture, FSD, DI         |
| Flutter TDD-BDD      | Spartan    | Test enforcement, zero tolerance    |
| Flutter UX/UI        | Apollo     | Multi-platform design, Material 3   |
| Flutter Widgets      | Hephaestus | Custom widgets, animations          |
| Flutter Performance  | Hermes     | Profiling, optimization             |
| Flutter A11y & i18n  | Iris       | Accessibility, internationalization |
| Flutter OTel         | Argus      | Client-side instrumentation         |
| Flutter AI           | Prometheus | Voice, GenUI, agents                |
| Flutter Quality      | Nemesis    | Final gate, delegation              |

### Rust Team (led by Vulcan)

| Agent             | Name      | Specialty                    |
|-------------------|-----------|------------------------------|
| Rust Orchestrator | Vulcan    | Team coordination            |
| Rust Architect    | Ferris    | Hexagonal architecture, gRPC |
| Rust TDD-BDD      | Centurion | Test enforcement             |
| Rust TUI          | Terminal  | ratatui, Elm architecture    |
| Rust OTel         | Sentinel  | Server-side instrumentation  |
| Rust Quality      | Tribune   | Final gate                   |

### Cross-cutting Agents

| Agent               | Name       | Specialty                                       |
|---------------------|------------|-------------------------------------------------|
| Forge Master        | Forge      | Orchestration, routing                          |
| Spec Writer         | Clio       | Requirements, RFC 2119                          |
| DDD Strategist      | Socrates   | Domain modeling, Event Storming                 |
| AI-First Brainstorm | Oracle     | AI workshop, agent architecture                 |
| Infra Architect     | Atlas      | Docker, K8s, Kong, Temporal                     |
| Observability       | Panoptes   | OTel, SigNoz, ELK, Prometheus                   |
| Security Auditor    | Aegis      | Security audit, OWASP                           |
| DevOps Engineer     | Heracles   | CI/CD, deployment                               |
| Product Analyst     | Pythia     | PRFAQ, competitive analysis, product briefs     |
| Technical Writer    | Calliope   | Changelogs, release notes, API docs             |
| API Designer        | Hermes-API | OpenAPI, AsyncAPI, gRPC contracts               |
| Test Architect      | Eris       | Test pyramid, mutation testing, flaky detection |

---

## Compatibility

**Superpowers** — TDD delegation is built in. When `/forge:implement` runs, it delegates to the appropriate TDD agent (
Spartan for Flutter, Centurion for Rust) who enforces the RED → GREEN → REFACTOR cycle without exception.

**oh-my-claudecode** — Forge responds to OMC keyword triggers:

- `autopilot` → full pipeline execution
- `ulw` → ultrawork mode (deep implementation)
- `team` → explicit multi-agent delegation

**Context7** — External API documentation is resolved automatically via the MCP server. Forge calls `resolve-library-id`
then `query-docs` to fetch up-to-date docs rather than relying on training data.

---

## Philosophy

- **Specs are the source code of intent** — Code is ephemeral; specs are the durable record of what was decided and why.
- **TDD is non-negotiable, not optional** — Every task in every feature follows RED → GREEN → REFACTOR. No exceptions,
  no rationalization accepted.
- **Quality is structural, not willpower-based** — Quality gates, constitution checks, and delegation patterns make
  quality the path of least resistance.

---

## Documentation

- [User Guide](docs/GUIDE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Constitution](.forge/constitution.md)

---

## License

Apache License 2.0. See [LICENSE](LICENSE) for the full terms and
[NOTICE](NOTICE) for upstream attributions (BMAD Method, GitHub SpecKit,
OpenSpec, Agent OS v3, Superpowers, oh-my-claudecode, Context7).

## Governance

- [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md)
- [Security policy](SECURITY.md) — private disclosure channels
- [Changelog](CHANGELOG.md) — Keep a Changelog format
- [Versioning policy](docs/VERSIONING.md) — SemVer, coupled to the Constitution
