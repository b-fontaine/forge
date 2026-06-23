# /forge:vision — Define Product Vision

## Purpose
Capture the product mission, problem, users, and value proposition.

## Interview Process

Ask these questions one by one (wait for response before next):

1. **Mission**: "What is [project name] trying to achieve? Complete: '[Project] helps [who] to [what] by [how].'"

2. **Problem**: "What specific problem does this solve? What is painful/slow/broken today?"

3. **Users**: "Who are the primary users? Describe 2-3 user personas with their goals and frustrations."

4. **Value Proposition**: "Why would someone choose this over alternatives? What's unique?"

5. **MVP Scope**: "For the first version (MVP), what are the 3-5 most important capabilities?"

6. **AI Features?**: "Does your product include AI features (voice, generation, agents)?" 
   - YES → Invoke **Oracle** for AI-First brainstorm session
   - NO → Continue

## Existing Project Mode
If README or other docs exist:
- Extract mission, problem, users from existing docs
- Present proposed mission statement for confirmation
- Ask about AI features

## Output
Update `.forge/product/mission.md`, `.forge/product/roadmap.md`, `.forge/product/tech-stack.md` with gathered information.

"Vision captured. Next step: `/forge:new <feature-name>` to start your first feature."
