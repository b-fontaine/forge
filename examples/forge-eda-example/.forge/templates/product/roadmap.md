# Product Roadmap

<!--
  This roadmap is a living document. Update it as priorities shift.
  Dates are approximate. Items move between phases as discovery reveals complexity.
  
  Ownership: Product + Engineering leads review this monthly.
  Format: Each item is a capability or outcome, not a task.
-->

## Vision (6–12 Months)

<!--
  Where is this product headed in 6–12 months? Describe the aspirational end state.
  This is not a commitment — it is a direction. Be concrete about the user experience
  and capabilities, not about internal implementation details.
  
  Example:
  "In 12 months, any Flutter or Rust team can bootstrap a Forge project in under 5 minutes,
  with a constitution, standards, and their first spec ready to implement. The framework
  enforces TDD and BDD automatically, with quality gates that catch violations before
  they reach review. AI-native features are instrumented with full OTel tracing out of the box."
-->

## MVP (Now — Current Quarter)

<!--
  What is being built right now? These are committed items in active development.
  Each item should map to a change in `.forge/changes/`.
  
  Format each item as: [Status] Description
  Status options: In Progress | In Review | Complete | Blocked
  
  Example:
  - [In Progress] Core spec pipeline: Proposal → Specs → Design → Tasks flow
  - [In Progress] Constitution enforcement in `/forge:plan`
  - [Complete] `.forge/` directory structure and schema definitions
  - [Blocked] Context7 MCP integration — waiting on upstream API stability
  
  Definition of Done for MVP:
  - [ ] Define your MVP exit criteria here
  - [ ] What must be true before MVP is considered "done"?
-->

### MVP Items

| Status | Item | Owner | Change ID |
|--------|------|-------|-----------|
| <!-- status --> | <!-- description --> | <!-- owner --> | <!-- .forge/changes/N --> |

### MVP Exit Criteria

<!--
  List the conditions that must be true for MVP to be considered complete.
  These are binary — each is either true or false.
-->

- [ ] <!-- criterion 1 -->
- [ ] <!-- criterion 2 -->

## Phase 2 (Next — Next Quarter)

<!--
  What comes after MVP? These are planned but not yet committed.
  Items here are prioritized and ready for spec work when MVP completes.
  
  Format each as a capability with a short rationale.
  
  Example:
  - **Multi-team support**: Allow multiple teams to share a Forge constitution with
    team-level overrides. Rationale: enterprise adoption requires org-level governance.
  - **Rust TUI scaffolding**: Pre-built Terminal agent with `ratatui` integration.
    Rationale: unblocks Rust CLI projects that need interactive interfaces.
  - **BDD scenario generator**: Oracle agent drafts Given/When/Then scenarios from
    a natural language feature description. Rationale: highest friction point in the spec pipeline.
-->

### Phase 2 Items

| Priority | Capability | Rationale |
|----------|-----------|-----------|
| <!-- High/Med/Low --> | <!-- capability --> | <!-- why --> |

## Phase 3 (Later — 6+ Months)

<!--
  Longer-horizon ideas. These are not committed. They exist to capture direction
  and ensure the MVP architecture does not foreclose on them.
  
  It is acceptable (and expected) for these to change significantly as the product evolves.
  
  Example:
  - Visual spec editor: Web-based UI for writing and reviewing Forge specs without
    touching markdown files directly.
  - Cross-language support: Extend Forge beyond Flutter and Rust to TypeScript/Node.
  - Forge Cloud: Hosted spec history, compliance dashboards, and team analytics.
  - AI spec reviewer: Automatic constitutional compliance check on PR using an agent.
-->

### Phase 3 Ideas

| Idea | Why It Matters | Why It's Later |
|------|---------------|----------------|
| <!-- idea --> | <!-- value --> | <!-- dependency or risk --> |

## Key Milestones

<!--
  Milestones are significant moments — not feature completions but project-level checkpoints.
  Each milestone has a target date and clear success criteria.
  
  Example milestones:
  - Alpha: First external project using Forge successfully completes a spec → implementation cycle
  - Beta: 5 projects using Forge, constitution enforcement working in CI
  - v1.0: Stable API, documentation complete, 10+ projects
-->

| Milestone | Target Date | Success Criteria | Status |
|-----------|-------------|-----------------|--------|
| <!-- name --> | <!-- YYYY-MM --> | <!-- criteria --> | <!-- Not Started / In Progress / Done --> |

## Deprioritized / Parked

<!--
  Ideas that were considered but deliberately set aside. Capturing these prevents
  re-litigating the same decisions. Include a brief note on why each was parked.
  
  Example:
  - ~~Visual dashboard~~: Parked because CLI-first is faster to ship and sufficient for early adopters.
    Revisit in Phase 3 if adoption warrants it.
-->
