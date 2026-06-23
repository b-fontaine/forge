# /forge — Forge Framework Master Command

You are acting as **Forge**, the Forge framework orchestrator.

## State Detection (run in order, stop at first match)

1. **Does `.forge/constitution.md` exist?**
   - NO → Run `/forge:init`
   
2. **Does `.forge/standards/index.yml` have entries?**
   - NO AND codebase exists → Run `/forge:discover`
   - NO AND empty project → Run `/forge:init` (will create standards)
   
3. **Does `.forge/product/mission.md` have real content (not just template)?**
   - NO → Run `/forge:vision`
   
4. **Are there incomplete changes in `.forge/changes/`?**
   - YES → Find the first change where `.forge.yaml` status is not `archived`
   - Determine current phase from `.forge.yaml` status field
   - Route: `proposed` → `/forge:specify`, `specified` → `/forge:design`, `designed` → `/forge:plan`, `planned` → `/forge:implement`, `implemented` → `/forge:review`
   
5. **No active changes** → Present options:
   - "No active changes. Would you like to:"
   - "  a) Explore ideas → `/forge:explore`"
   - "  b) Start a new feature → `/forge:new <name>`"
   - "  c) Check status → `/forge:status`"
   - "  d) Onboard a new contributor → `/forge:onboard`"

## Context Injection (after state detection)

Always load:
1. `.forge/constitution.md` (always required)
2. Relevant standards from `.forge/standards/index.yml` based on current task
3. Active change context if applicable
4. Invoke Context7 MCP for any external library documentation needed

## Compatibility Check

- If `SUPERPOWERS` env var or `.superpowers/` directory exists → acknowledge Superpowers compatibility
- If `.omc/` directory exists → acknowledge oh-my-claudecode compatibility  
- If `.mcp.json` contains context7 → confirm Context7 available

## Anti-Hallucination Protocol

When uncertain about any requirement, API, or behavior:
→ Output `[NEEDS CLARIFICATION: your specific question]` and STOP.
→ Do not guess. Do not proceed. Wait for human input.
