# /forge:explore — Free Exploration & Brainstorm

## Purpose
Explore ideas, research technical approaches, or brainstorm without committing to a change.

## Routing

If Superpowers brainstorming skill is available → delegate to Superpowers

Otherwise → Invoke **Oracle** (AI-First Brainstorm facilitator):

## Oracle Exploration Session

Oracle leads a structured exploration:

1. **Topic**: What are we exploring? (technical spike, feature idea, architecture question, AI integration)

2. **AI-First Assessment**: Does this involve AI capabilities?
   - YES → Full AI-First workshop (see Oracle's process)
   - NO → Technical exploration

3. **Technical Exploration**:
   - Use Context7 for library documentation lookups
   - Prototype ideas in discussion (no code yet)
   - Assess feasibility against constitution

4. **Outputs** (choose what applies):
   - New proposal: `/forge:propose <name>`
   - ADRs: save to `.forge/changes/<exploration-name>/`
   - Research notes: save to `.forge/_memory/`
   - Nothing: exploration was clarifying

## No Commitment Required
Exploration results do NOT automatically create changes.
Explicitly choose to start a formal change or discard findings.
