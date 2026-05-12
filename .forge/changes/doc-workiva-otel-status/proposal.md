# Proposal: doc-workiva-otel-status
<!-- Created: 2026-05-12 -->
<!-- Schema: default -->

## Problem

`ARCHITECTURE-TARGET.md` §9 (Mapping agents Forge) references agents
**Argus** (Flutter OTel) and **Sentinel** (Rust OTel) without documenting
the signal-coverage asymmetry of the Dart OTel SDK they rely on.

The sibling change `t5-otel-dart-api-realign` pinned `opentelemetry:
0.18.11` (Workiva) and established in FR-FOT-DA-060/061 that:

- **Traces** → Beta
- **Metrics** → Alpha
- **Logs** → Unimplemented

This data lives in the flutter standard frontmatter and specs but has
never been annotated in the architecture document itself. Any reader of
§9 who wants to understand OTel Dart coverage must hunt across two files.

## Solution

Add a single dated status annotation to §9 of `ARCHITECTURE-TARGET.md`,
immediately after the Argus row in the agents table, as a callout block
documenting the three-signal maturity levels and a future-review trigger.

Scope: one paragraph/table in `docs/ARCHITECTURE-TARGET.md`. No code
changes. No new agents. No changes to other sections.

## Scope In

- One status annotation (callout block with table) inserted in §9 of
  `docs/ARCHITECTURE-TARGET.md`.
- Future-review trigger dated 2026-11-12 or when Workiva pkg bumps to
  >= 0.19.0.
- Minimal Forge pipeline artefacts (proposal, specs, design, tasks).

## Scope Out

- No OTel code changes (Rust or Dart).
- No changes to other ARCHITECTURE-TARGET.md sections.
- No test harness additions (doc change; constitution-linter validates).
- No PR, no push.

## Risk

Low — documentation-only change. Rollback is `git revert`.
