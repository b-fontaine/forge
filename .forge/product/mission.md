# Product Mission

## Project Name

Forge Framework

## Mission Statement

We help Flutter and Rust teams ship reliable features faster by enforcing a
spec-driven, test-first workflow whose quality gates are structural rather than
disciplinary — the workflow makes skipping the right thing harder than doing it.

## Problem Statement

**Current situation.** Most teams operate on a spectrum between two failure
modes. On one end, "just ship it": specs live in tickets, tests are written
after the fact (if at all), and architectural decisions rot silently in chat
logs. On the other end, process-heavy shops pile on ceremony — RFC templates,
design reviews, ADRs — which slows feature delivery without durably preventing
regressions, because the ceremony is advisory, not enforced.

**Pain points.** (1) Specs drift from the implementation once code lands —
nobody re-reads them, so the intent behind features is lost. (2) TDD is
advocated but skipped whenever the schedule tightens; "I'll add tests after" is
the #1 lie in the industry. (3) External library APIs change faster than LLM
training data, so AI coding assistants silently hallucinate signatures that no
longer exist. (4) Quality guardrails are willpower-based: a tired reviewer at
4pm Friday is the only thing between production and a broken migration.

**Cost of inaction.** Features ship with hidden technical debt that compounds.
Production bugs trace back to skipped process steps. Onboarding new engineers
takes weeks because the "why" of each design decision is undocumented. AI
assistants amplify the problem: they make it faster to write code *without*
making it harder to write the wrong code.

**Why Forge.** Forge collapses these failure modes by making the process
itself executable: a constitution with blocking gates, deterministic shell
linters that do not depend on LLM judgment, 28 specialized agents that each
refuse to proceed when their invariants are violated, and live documentation
via Context7 so API signatures are current, not hallucinated.

## Target Users

### Primary: Alex the Senior Flutter/Rust Engineer

- **Context**: Works on a 10-person product team at a scale-up shipping a
  Flutter consumer app backed by a Rust services layer. Has seen two previous
  "spec process" initiatives fizzle because they were advisory.
- **Goal**: Ship features without accumulating hidden technical debt, while
  keeping the velocity the business demands.
- **Frustration**: Tests are written after the fact or not at all, specs drift
  from reality within weeks of a feature shipping, and production incidents
  trace back to skipped steps that "we'll clean up next sprint".

### Secondary: Jordan the Engineering Manager

- **Context**: Oversees three squads (two Flutter, one Rust), responsible for
  delivery predictability and on-call burden.
- **Goal**: Maintain velocity without sacrificing quality. Wants evidence, not
  promises, when approving a feature for merge.
- **Frustration**: No visibility into which features have real test coverage
  vs. which were "tested manually and it seemed fine". Can't enforce standards
  without becoming the bottleneck.

## Value Proposition

Unlike advisory frameworks (ADR templates, process wikis, review checklists),
Forge's guardrails are **structural** — the tooling refuses to proceed when
invariants are violated. The core value: a spec-driven pipeline where each
phase has a blocking gate, and where the LLM is only one voice among several
(deterministic scripts, mythological-persona agents, constitutional articles)
rather than the sole arbiter.

- **Specs are enforced, not optional** — `/forge:implement` refuses to proceed
  without a completed spec in `.forge/changes/<name>/`, every time.
- **TDD is structural** — the RED → GREEN → REFACTOR cycle is embedded in the
  agents (Spartan for Flutter, Centurion for Rust), and a 12-excuses
  anti-rationalization table blocks the most common skip attempts.
- **39 standards injected just-in-time** via `.forge/standards/index.yml` —
  context windows stay small, relevant rules are loaded only when triggered.
- **28 specialized agents** (10 Flutter, 6 Rust, 12 transversal) with
  mythological personas, each with scoped authority and clear routing — no
  single agent becomes a dumping ground.
- **Deterministic scripts complement the LLM** — `verify.sh` and
  `constitution-linter.sh` run without an LLM, catching structural violations
  that a tired reviewer (human or AI) would miss.

## Success Metrics

| Metric | Current Baseline | 3-Month Target | 12-Month Target |
|--------|-----------------|----------------|-----------------|
| Projects using Forge | 0 | 5 | 50 |
| Avg. test coverage in Forge projects | — | ≥ 80% | ≥ 85% |
| Time from proposal to approved spec | — | < 2 days | < 1 day |
| Post-launch production bugs per feature | — | < 2 | < 1 |

## Out of Scope

- **Languages other than Flutter and Rust in v1**. The framework is
  deliberately narrow and premium. TypeScript, Python, Go, Java, Swift are not
  supported and are explicitly deprioritized — see roadmap "Deprioritized /
  Parked".
- **Project management replacement**. Forge does not replace Jira, Linear,
  GitHub Projects. It complements them with spec artifacts and status metadata
  in `.forge/changes/<name>/.forge.yaml`.
- **Code generation / scaffolding of business logic**. Forge enforces process
  and scaffolds archetypes (see roadmap Module B), not feature boilerplate.
  The LLM writes the code inside the spec envelope Forge enforces.
- **Visual / GUI dashboard in v1**. Forge is file-based and CLI-invoked. A
  web dashboard is a Phase 3 idea, not a v1 commitment.
- **Multi-LLM provider abstraction in v1**. Forge targets Claude Code today.
  A provider-neutral CLI wrapper is a Phase 3 idea (Module G.6 in the audit
  roadmap).
