# Four Spec-Driven Development frameworks put to the test with Claude Code: what the mechanics say, what users say, what the numbers say

*A rigorous comparison of BMAD-METHOD v6, GitHub SpecKit, OpenSpec and Agent OS v3, within a production workflow with Claude Code. Observations dated May 5, 2026.*

---

## Preliminary disclaimer on the temporal baseline

All the quantified data in this article — versions, GitHub stars, open-issue numbers, release cadence — are frozen as of **May 5, 2026**. The market for Spec-Driven Development (SDD) frameworks is evolving at an abnormal pace: between the writing of this article and its reading, several comparison columns will probably have moved. ThoughtWorks' Technology Radar Vol. 34 (April 2026) explicitly formalized a mechanism dubbed *too young to blip* — tools so recent that no stable assessment is possible. The present article does not escape this constraint: use it as a methodological snapshot, not as a product recommendation.

I will systematically distinguish three registers: (a) what the frameworks **claim** to do in their official documentation; (b) what their **users report** in issues, field feedback and engineering blogs; (c) what is **objectively measurable** — stars, release cadence, modules actually delivered. The attentive reader will note that these three registers often diverge.

---

## Why this comparison, and why now

Since Sean Grove's keynote at the AI Engineer World's Fair in May 2025 ("The New Code"), a thesis has been circulating in the community: the specification, and no longer the code, would become the primary artifact of software engineering in the era of capable models. Andrej Karpathy and Tobi Lütke popularized in June 2025 the expression *context engineering*, which shifted the center of gravity from the *prompt* to the architecture of the context supplied to the model. ThoughtWorks' Radar Vol. 33 (November 2025) then classified spec-driven development as *Assess*, noting two emerging camps: those who trust the native capabilities of agents, and those who impose structured workflows.

On this ideological terrain, four frameworks have emerged as operational references for teams using Claude Code in production:

- **BMAD-METHOD v6** (bmad-code-org), centered on persona-agents covering the entire SDLC;
- **GitHub SpecKit** (github/spec-kit), centered on the *constitution* and the `[NEEDS CLARIFICATION]` markers;
- **OpenSpec** (Fission-AI), centered on specification *deltas* and brownfield;
- **Agent OS v3** (buildermethods), centered on standards injection.

Before comparing, one must settle on a grid. And before proposing a grid, one needs an anti-hype anchor.

## Anti-hype anchor: what METR measures

The randomized controlled trial published by METR in July 2025 (arXiv:2507.09089) remains, as of May 5, 2026, the only serious empirical study on the impact of AI tools on the productivity of experienced developers. Across 246 tasks assigned to 16 expert open-source contributors working on their own repositories (~5 years of seniority on average), being allowed to use Cursor Pro with Claude 3.5/3.7 Sonnet **increased** completion time by 19%. Before starting, the developers estimated a 24% gain; after the experiment, they estimated a 20% gain. The gap between perception and measurement is the most instructive result. METR published in February 2026 a note (`metr.org/blog/2026-02-24-uplift-update`) acknowledging that the continuation of the experiment suffered from a selection bias — the most enthusiastic developers withdrew from the non-AI tasks — and that the design needed to be revised.

Provisional conclusion: no SDD framework can, to date, claim to demonstrate that it speeds up experienced developers on mature codebases. Any assessment of the frameworks compared here must therefore begin with a question: *what problem am I really solving?* — before the more glamorous one: *which framework should I adopt?*

## The comparison grid, laid out before the comparison

To avoid the pitfall of the ad hoc table that flatters the framework one already prefers, here are the eight axes I use, chosen before any in-depth examination of the frameworks:

1. **Lifecycle coverage**: from product vision to maintenance.
2. **Anti-hallucination and anti-drift mechanisms**: constitution, ambiguity markers, deltas, RFC 2119.
3. **Spec model**: centralized, delta-based, injectable standards, or personas.
4. **Brownfield vs greenfield**.
5. **Native Claude Code integration**: `.claude/`, slash commands, skills, subagents, MCP.
6. **Real ergonomic friction**: overhead for a minor bug fix, learning curve, stability of the framework's API.
7. **Community maturity**: critical issues, release cadence, extension ecosystem.
8. **Native vs delegated TDD/BDD**.

No weighting is given here: the weighting depends on the reader's context (team size, greenfield/brownfield ratio, regulatory requirements). This grid is not neutral — it reflects my own engineering priorities. It is explicit, and therefore contestable.

---

## BMAD-METHOD v6: maximalist agile-AI

**Status as of May 5, 2026**: stable version v6.0.4 released in early March 2026 ("End of Beta"), recent version v6.2.2 of March 26, 2026, around 45,800 GitHub stars, MIT License, created by Brian Madison.

BMAD claims to be a complete agile-AI framework ("Breakthrough Method for Agile AI-Driven Development") covering the entire SDLC via specialized persona-agents: Analyst, PM, Architect, UX, Scrum Master, Dev, QA (TEA — Test Architect), Tech Writer. v6 introduces five modules (BMM, BMB, CIS, GDS, TEA), a *skills* architecture compatible with Claude Code's SKILL.md format, and an `npx bmad-method install` installation mode that scaffolds the `_bmad/` tree in the project.

### Technical integration with Claude Code

BMAD's installer detects the tools present (`.claude/`, `.cursor/`, etc.) and generates 27 agents and 74 workflows by default, configurable via a TOML overrides system in `_bmad/custom/` (introduced with v6.2.x via PRs #2284-2289). A `_bmad/config.toml` file centralizes the module choices. The legacy workflows (proprietary `workflow.yaml` format) are being migrated to Claude Code's native SKILL.md format, which for now makes the integration partially dual: a third-party plugin such as `aj-geddes/claude-code-bmad-skills` or `PabloLION/bmad-plugin` aggregates the modules for Claude Code while waiting for the upstream migration to be complete.

Concretely, after installation, a developer has slash commands organized around the phases (analysis → planning → solutioning → implementation), with a `bmad-help` agent that acts as a conversational router: "I've finished the architecture, what do I do?". Claude Code subagents are used for code reviews and certain TEA (test architect) workflows.

### Ergonomic friction

This is where the gap between claim and field experience becomes marked. Issue #2003 ("Structural Gaps and Contradictions of the BMAD Method V.6 Stable"), opened by a user declaring themselves a fan of the framework, exposes a structural critique: for a small or medium project, the process imposes disproportionate overhead, mixing agents, *party mode* and multiple orchestrations that would make practical execution more complex than a simple `CLAUDE.md` coupled with a structured plan. The author concludes that BMAD is valuable in the ideation, brainstorming and multi-domain research phase, but becomes "unnecessarily complex even for extremely small projects" in the execution phase.

Issue #1332 illustrates another flaw: the code review workflow imposed a minimum of 3 issues to find per review, forcing nitpicks on clean code — an anti-pattern that has been recognized and fixed since, but revealing a tendency toward over-prescription in the framework's internal prompts. Issue #2274, more recent, shows an improvement: `bmad-create-story` now reads files marked `UPDATE` before generating its dev notes, to avoid improvising on existing behaviors — in other words, BMAD is progressively adding brownfield guardrails that were initially missing.

Example of a configuration line in the new TOML architecture:

```toml
[modules.bmm]
project_knowledge = "research"
user_skill_level = "expert"

[core]
project_name = "my-project"
```

Honest verdict: the release cadence is high (several versions per month in April 2026), the API changes fast. For a lead of AI-First Transformation managing 9 BUs and 500+ devs, this instability is a hidden cost.

---

## GitHub SpecKit: the constitution as discipline

**Status as of May 5, 2026**: recent version 0.8.1, around 89,000-91,000 GitHub stars (forks ~7,700-7,900), MIT License, launched by GitHub on September 2, 2025.

SpecKit is arguably the most visible framework because of the GitHub brand that carries it. Den Delimarsky's post on the GitHub Blog in September 2025 set the frame: coding agents are treated as *literal-minded pair programmers*, not as search engines. The workflow is a strict pipeline: `/speckit.constitution` → `/speckit.specify` → `/speckit.clarify` (optional) → `/speckit.plan` → `/speckit.tasks` → `/speckit.analyze` → `/speckit.implement`.

### Technical integration with Claude Code

Installation is done via `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git` then `specify init`. SpecKit lays down two folders: `.specify/` (templates, scripts, memory) and `.claude/commands/` (the `speckit.*` slash commands for Claude Code). The documentation lists 17+ supported agents: Claude Code, GitHub Copilot, Cursor, Gemini CLI, Windsurf, Qwen, Codex CLI, OpenCode, etc. This multi-agent agnosticism is a strong argument vis-à-vis heterogeneous teams.

The central anti-hallucination mechanism is twofold:
- the **constitution** (`.specify/memory/constitution.md`) — a document of non-negotiable principles that the `/speckit.plan` command consults explicitly like a simulated *compliance officer*;
- the **`[NEEDS CLARIFICATION: specific question]`** markers — an internal instruction to the templates so that LLMs, rather than filling in ambiguities, flag them.

The community extension ecosystem (`specify extension add`) is becoming a differentiator: adversarial review, security audit, post-implementation code review, side-effect analysis, Jira/Linear integration, etc.

Example of a marker in a template:

```markdown
When creating this spec from a user prompt:
1. Mark all ambiguities: Use [NEEDS CLARIFICATION: specific question]
2. Don't guess: If the prompt doesn't specify something, mark it
```

### Ergonomic friction

The most credible field feedback comes from ThoughtWorks' Radar Vol. 33 and EPAM's blog (November 2025). EPAM documented in detail the use of SpecKit on a brownfield Java project: the constitution must state not only the principles but also the explicit **anti-patterns** ("No try-catch blocks in route handlers"), failing which the agent re-introduces them. The team-lead remains a *technical lead reviewing a junior developer's implementation* — in other words, SpecKit does not remove the critical review, it displaces it.

The critical GitHub issues underline this tension: #806 ("brownfield project requires more iterating"), #540 (the Source Tree section of `plan-template.md` sometimes produces corrupted trees), #1173 and #1285 (documentary gaps on brownfield), discussion #331 and #746 (users looking for how to import an existing codebase). Radar Vol. 33 acknowledges these difficulties while noting that SpecKit produces the most value in the hands of engineers already experienced in clean code.

The risk of *instruction bloat* — the accumulation of project context in the constitution until it triggers *context rot* — is explicitly mentioned by the ThoughtWorks teams. The required discipline is non-trivial.

---

## OpenSpec: deltas as a primitive

**Status as of May 5, 2026**: version 0.22.0 (April 2026), around 45,200-45,300 GitHub stars (forks ~3,100), MIT License, maintained by Fission-AI (Tabish, *@0xTab*).

OpenSpec positions itself explicitly as a *lightweight* alternative to the more prescriptive frameworks. Its philosophy: "fluid not rigid, iterative not waterfall, built for brownfield not just greenfield". The ThoughtWorks Radar Vol. 34 (April 2026) placed OpenSpec in *Assess* with an explicit note: its focus on *spec deltas* rather than on a complete upfront specification makes it a better candidate than SpecKit for existing systems.

### Technical integration with Claude Code

Installation is lightweight: `npm install -g @fission-ai/openspec` then `openspec init`. The structure produced:

```
openspec/
├── specs/        # source of truth (current state)
├── changes/      # active proposals
│   └── archive/  # history
└── config.yaml
```

The default workflow (*core* profile) relies on four slash commands: `/opsx:propose`, `/opsx:explore`, `/opsx:apply`, `/opsx:archive`. The extended profile (11 commands: `/opsx:new`, `/opsx:continue`, `/opsx:ff`, `/opsx:verify`, `/opsx:sync`, `/opsx:bulk-archive`, `/opsx:onboard`) covers more advanced cases. On the Claude Code side, OpenSpec generates `.claude/skills/` and `.claude/commands/opsx/`; a *CommandAdapterRegistry* manages 23+ specific adapters (Cursor, Windsurf, Codex, Copilot, Antigravity, Kiro, Junie, etc.).

OpenSpec's anti-drift mechanism is the **delta**: each change proposes a partial spec file structured by the sections `## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements`. The requirements themselves use the RFC 2119 keywords (`MUST`, `SHALL`, `SHOULD`) with `GIVEN/WHEN/THEN` scenarios:

```markdown
## MODIFIED Requirements
### Requirement: Session Timeout
The system SHALL expire sessions after 30 minutes of inactivity.
(Previously: 60 minutes)

#### Scenario: Idle timeout
- GIVEN an authenticated session
- WHEN 30 minutes pass without activity
- THEN the session is invalidated
```

At archiving, the delta is merged into the current spec, and the change is moved to `changes/archive/` with a timestamp. The physical separation between *source of truth* and *proposed updates* provides a clean audit trail.

### Ergonomic friction

The most instructive field feedback comes from Mathivanan Mani's article comparing SpecKit, OpenSpec and BMAD on a brownfield Java/Spring Boot project: OpenSpec produced the cleanest design and the best code standards for a medium-sized feature. The learning curve is notably gentler than BMAD's, and the weight of meta-instructions is lower than SpecKit's.

On the limits side: no multi-agent personas, no native cross-repo orchestration, and the extension ecosystem remains more modest than SpecKit's. OpenSpec's author himself indicates that automatic spec generation for existing codebases is a subject explored but not solved — the philosophy remains "create specs along with features, not as a retrospective block". For a legacy repo of 500K LOC, this is an appreciable epistemic honesty, but also a functional gap.

The release cadence is high but seems more targeted than BMAD: each release solves a named problem (workflow, profile, custom schemas, support for new tools). The repo shows, as of May 5, 2026, around 226 open issues, mostly evolution requests rather than structural bugs.

---

## Agent OS v3: retraction as a methodology

**Status as of May 5, 2026**: version 3.0 published in April 2026, around 4,400 GitHub stars, MIT License, created by Brian Casel (Builder Methods).

Agent OS is the outsider of this comparison — not by lack of quality, but by deliberate positioning. v3 explicitly removed around 70% of the v2 framework. Brian Casel justifies this choice in the v3 release note: Claude Code's Plan modes and extended thinking now handle correctly the writing of specs and the breakdown of tasks; it is no longer relevant for a third-party framework to re-implement these functions. Agent OS v3 refocuses on three primitives: `/discover-standards`, `/inject-standards`, `/shape-spec`.

### Technical integration with Claude Code

Installation goes through a shell script: `curl -sSL https://raw.githubusercontent.com/buildermethods/agent-os/main/setup/base.sh | bash -s -- --claude-code`. The structure lays down an `.agent-os/` folder at the project level containing standards, specs, and product docs, plus slash commands in `.claude/commands/`. An `index.yml` file enables the automatic detection of which standards to inject in which context.

Example of a typical standard (injectable Markdown):

```markdown
---
name: api-conventions
applies_to: [backend, api]
---

## API Implementation Structure
- Router function with request validation
- Router calls data client and/or API client directly
- NO business logic layer/service layer
- Simple logic stays in router; complex logic in data clients
```

The native integration with Claude Code's *skills* is central: `/inject-standards` can bake the standards into any subagent, skill or custom prompt — a pattern compatible with the official Anthropic doc on skills (`.claude/skills/<skill-name>/SKILL.md`). v3 removes the implementation and orchestration phases of v2: the framework delegates to Claude Code the responsibilities that Claude Code already fulfills well.

### Ergonomic friction

This is, paradoxically, the lowest friction of the four. The learning curve is limited to three commands, and the "do little, do it cleanly" philosophy reduces the migration debt. The price is obvious: Agent OS v3 does not cover the full lifecycle; it is designed to nest into a native Claude Code workflow (Plan Mode + skills + subagents), not to be self-sufficient.

The epistemic risk here is the inverse of BMAD's: a transformation lead could underestimate the value of Agent OS because it does not look like a "framework". This is precisely the creator's argument — the value is in the discipline of extracting and injecting standards, not in the ribbon around it. The modest size of the community (4.4k stars vs 45-90k for the others) reflects less an intrinsic weakness than an assumed niche positioning.

---

## Synthetic comparison table

Codes: ✅ solid native coverage; ⚠️ partial coverage or documented friction; ❌ absent coverage or explicitly delegated.

| Axis | BMAD-METHOD v6 | GitHub SpecKit | OpenSpec | Agent OS v3 |
|---|---|---|---|---|
| **1. Lifecycle** | ✅ Vision → maintenance via 5 modules | ⚠️ Spec → implementation, no vision/product | ⚠️ Change-driven, no native product phase | ❌ Standards only, delegates the rest to Claude Code |
| **2. Anti-hallucination / drift** | ⚠️ Multiple validations but documented over-prescription (#1332) | ✅ Constitution + `[NEEDS CLARIFICATION]` + `/analyze` | ✅ Deltas ADDED/MODIFIED/REMOVED + RFC 2119 | ⚠️ Explicit standards but no formal gate |
| **3. Spec model** | Personas-driven (12+ agents) | Centralized (constitution + spec/plan/tasks) | Deltas separated specs/changes/archive | Injectable standards on demand |
| **4. Brownfield vs Greenfield** | ⚠️ Brownfield supported via document-project + Test Architect, high complexity | ⚠️ Greenfield-first, brownfield documented as a gap (issues #806, #540, #1173) | ✅ Brownfield-first claimed and recognized (Radar Vol. 34) | ✅ `/discover-standards` extracts from the existing |
| **5. Claude Code integration** | ⚠️ Migration in progress toward SKILL.md, third-party plugins required | ✅ Native `.claude/commands/` slash commands, multi-agent | ✅ Skills + commands for 23+ tools | ✅ Designed for Plan Mode + Skills + Subagents Claude Code |
| **6. Friction for a minor bug fix** | ❌ Overhead judged disproportionate by users (#2003) | ⚠️ Constitution + 4 heavy phases for an isolated change | ✅ Lightweight `/opsx:propose`, *core* profile at 4 commands | ✅ Skills on demand, no imposed pipeline |
| **7. Community maturity** | ✅ ~45.8k stars, very high cadence but unstable API | ✅ ~89-91k stars, rich extension ecosystem | ✅ ~45.2k stars, targeted releases | ⚠️ ~4.4k stars, more modest community |
| **8. Native TDD/BDD** | ✅ Dedicated TEA module (Test Architect) | ⚠️ Possible via constitution but not native | ⚠️ GIVEN/WHEN/THEN scenarios in deltas but no execution | ❌ Delegated to Claude Code and standards |

No line gives an absolute winner. The grid shows four different profiles that respond to different constraints.

---

## What the frameworks don't say

Four recurring blind spots deserve to be named:

**1. Release cadence is disguised maintenance debt.** BMAD published several versions per month between January and April 2026, sometimes with changes of configuration format (YAML → TOML transition, abandonment of YAML after a brief introduction — PR #2284, #2283). SpecKit has releases v0.4.5 and v0.5.0 published without template assets, breaking `specify init` (issue #2092). For a team of 500+ devs, each migration costs dozens of hours of unaccounted internal support.

**2. Star counts don't measure quality.** OpenCode gained around 47k GitHub stars in two months in early 2026 according to MightyBot. A star testifies to an intention, not to production use. Radar Vol. 34 names this effect *too young to blip*: the market is saturated with projects maintained by a single contributor working with a coding agent.

**3. No public RCT evaluates SDD frameworks.** METR measured the impact of general AI tools (Cursor + Claude 3.5/3.7 Sonnet), not the differential impact of a spec framework. The published experience reports (EPAM, Mathivanan Mani, Scott Logic, etc.) are methodologically honest n=1 cases but not generalizable. The adoption figures are self-selected.

**4. *Semantic diffusion* contaminates the comparisons.** Radar Vol. 34 names the problem explicitly: *spec-driven development*, *harness engineering*, *context engineering* are used interchangeably, sometimes to designate different things. When a blog presents a framework as "spec-driven", one must question: what does that mean here, operationally?

---

## Hybridization: thesis, objections, conditions of validity

### Thesis

The structural blind spots of each framework justify, in certain team configurations, considering a hybridization rather than an exclusive choice. Concretely: an injection standard (Agent OS) for cross-cutting conventions, a delta mechanism (OpenSpec) for brownfield evolutions, a constitution discipline (SpecKit) for greenfield phases, personas (BMAD) for complex domains requiring multiple perspectives.

### Objections

Hybridization carries five serious risks that must be named.

**Integration cost.** Four frameworks means four `.claude/commands/`, four file conventions, four release cadences. The risk of slash-command naming collisions (`/spec*`, `/opsx:*`, `/inject-standards`, `/bmad-help`) increases, and each update becomes a coordinated event.

**Convention conflict.** SpecKit pushes a central constitution, OpenSpec a specs/changes separation, BMAD a multi-agent orchestration, Agent OS a contextual diffusion of standards. These philosophies are not mutually exclusive in theory, but can produce in practice duplicated or contradictory specs.

**Maintenance debt.** At the scale of 9 BUs, multiplying frameworks means multiplying responsibilities of evangelization, training, internal support. The coordination cost can exceed the marginal gain.

**Over-engineering risk.** BMAD issue #2003 stands as a general warning: an elaborate method applied to a minor bug fix produces noise, not signal. Over-specification is an anti-pattern recognized by Radar Vol. 33, which speaks of *yak shaving*: one descends into layers more complex than the initial problem.

**Semantic diffusion.** Combining frameworks whose vocabularies partially overlap (constitution vs standards vs project.md vs CLAUDE.md) increases the risk that a team thinks it is talking about the same thing when it is not — precisely the problem named by ThoughtWorks Vol. 34.

### Argued refutations and conditions of validity

Hybridization is only defensible under certain explicit conditions:

- **Delimited scope of application**: for example, BMAD reserved for high-stakes greenfield product projects, OpenSpec used for all evolutions of existing systems, Agent OS as a cross-cutting standards-injection layer. Without this delimitation, the frameworks step on each other.
- **Single owner per BU**: a dedicated technical referent for each adopted framework, able to absorb release changes and protect the team from noisy migrations.
- **Monitored friction metric**: track the average time to execute a minor bug fix under the framework, and abandon if that time exceeds an agreed threshold (for example, the non-framework time + 50%).

Several *hybridization patterns* are documented in practice by the community in May 2026, without any of them establishing itself as canonical:

- **SpecKit + Agent OS**: SpecKit's constitution absorbs Agent OS's standards via `/inject-standards`. Reported by several developers on the SpecKit repo as a stable combination, but with a risk of redundancy.
- **OpenSpec + BMAD-TEA**: OpenSpec handles the spec deltas, BMAD's TEA module is isolated for the test strategy. Documented by Mathivanan Mani as a compromise for large-scale brownfield codebases.
- **Agent OS alone, as a minimalist layer**: reflects Brian Casel's stance — delegate as much as possible to native Claude Code and add only a standards-injection discipline.

None of these patterns is measured experimentally. They are team heuristics, not results.

---

## Epistemic limits of this comparison

Three structural limits deserve to be kept in mind.

**No public RCT on SDD frameworks.** The METR study measures AI tools, not spec frameworks. The difference is crucial: an SDD framework could slow down expert developers even further (methodological overhead on a familiar codebase) or speed them up (reduction of re-spec back-and-forth). We do not know. Any comparison therefore operates on plausible principles, not on measured effects.

**Self-selected adoption samples.** The published feedback comes from enthusiastic practitioners. The teams that tried and then abandoned rarely blog. The observation of GitHub stars is even more biased: a *star* can mean "I like the idea", not "I use it in production".

**Semantic diffusion identified by Radar Vol. 34.** When four frameworks use the term *spec-driven development*, but SpecKit produces sequential Markdown artifacts, OpenSpec RFC 2119 deltas, BMAD handoffs between personas and Agent OS injectable standards, the common term masks very different designs. The axis-by-axis comparison is an attempt to disambiguate this confusion, not an absolute ranking tool.

To these limits is added the fact that **Claude Code itself is evolving rapidly**: Anthropic's April 2026 post-mortem on quality regressions of Claude Code (default effort, loss of reasoning history in stale sessions, prompt verbosity) shows that the underlying layer is not stable. Any conclusion about a framework's native integration with Claude Code can flip with a behavior change of the host tool.

---

## Conclusion: three conditions of revision, and a methodological stance

What this article can defend methodologically: for an organization managing a fleet of 500+ devs across 9 BUs, the right reasoning is not "which framework to adopt", but **"under which empirical conditions should my analysis be revised"**. This is the inverse of the marketing stance.

At least three falsifiable conditions would justify a revision of this comparison:

1. **Publication of a comparative RCT** between two or more of these frameworks, on real brownfield tasks, measuring not only completion time (à la METR) but also the quality of the code delivered (independent review) and the quality of the specs produced. If such a study showed that a framework produces a measurable and sustainable gain, the axis-by-axis analysis above would become secondary.

2. **Convergence of the frameworks on a shared spec format.** If SpecKit, OpenSpec, BMAD and Agent OS adopted a common subset (for example a standardized RFC 2119 delta format, or a unified SKILL.md schema), the comparison would lose its relevance as a comparison between products, and would shift toward a comparison between dialects of a single standard. The ongoing migration of BMAD modules toward SKILL.md, and the growing absorption of skills into the Agent OS and OpenSpec workflows, suggest a movement in this direction without confirming it.

3. **Collapse or consolidation of a major framework.** If one of the four frameworks ceases to be maintained (for example, a strong fragmentation of the BMAD community around the v6 forks, or a prolonged stagnation of Agent OS releases), the comparison loses one of its poles. Conversely, if a major player (Anthropic, GitHub, AWS Kiro) absorbs or renders redundant one of the frameworks via a native feature, the balance of power changes. The indicators to watch are release cadence over a rolling 90 days, the number of critical issues opened vs closed, and the ratio of accepted community PRs.

These conditions are descriptive, not prescriptive. They do not suggest an experimental protocol — they indicate what would need to be observed to consider this analysis outdated.

The frame I defend is therefore strictly methodological: require of frameworks that they state the three distinct registers (official claims, user feedback, measurable facts); settle on a grid before comparing; name one's epistemic limits; refuse the role of oracle. The choice of a framework — or the decision not to adopt one — falls under a local trade-off that I cannot make for the reader, and that no one should claim to make in their place.

Remains the practical question: as of May 5, 2026, in a distributed organization, on heterogeneous brownfield/greenfield codebases, with Claude Code as the reference tool, I have not seen strong evidence that a framework dominates. I have seen, on the other hand, many teams adopt too fast and abandon too late. The most defensible operational hypothesis — testable, falsifiable, modest — is probably the following: start with the lightest of the candidates compatible with the team's profile, measure the friction over three months, and add mechanics only when a specific problem justifies it.

The rest is prose.

---

*Main sources used (paraphrased, not cited as quotes): GitHub repositories bmad-code-org/BMAD-METHOD, github/spec-kit, Fission-AI/OpenSpec, buildermethods/agent-os; ThoughtWorks Technology Radar Vol. 33 (November 2025) and Vol. 34 (April 2026, thoughtworks.com/radar); METR "Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity" (arXiv:2507.09089, July 2025) and "We are Changing our Developer Productivity Experiment Design" (metr.org/blog/2026-02-24-uplift-update); GitHub Blog "Spec-driven development with AI" (Den Delimarsky, September 2025); Sean Grove, "The New Code", AI Engineer World's Fair (May 2025); Andrej Karpathy and Tobi Lütke on context engineering (June 2025); Claude Code documentation (code.claude.com/docs/en/sub-agents); EPAM Insights on SpecKit in brownfield; Mathivanan Mani, OpenSpec/SpecKit/BMAD comparison (Medium); Scott Logic, "Putting Spec Kit Through Its Paces" (November 2025).*

*All quantified observations are dated May 5, 2026. This baseline will expire quickly; the reader is invited to cross-check systematically.*
