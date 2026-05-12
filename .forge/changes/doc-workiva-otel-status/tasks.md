# Tasks: doc-workiva-otel-status
<!-- Status: planned -->
<!-- Schema: default -->

> 2 tasks. Single impl phase — doc annotation only.

## Phase 1 — Implementation

### T-DWO-001 — Insert status annotation in ARCHITECTURE-TARGET.md §9

- **Action**: Add a dated status callout block in §9 of
  `docs/ARCHITECTURE-TARGET.md`, after the agents-impacted table and
  before the `### 9.2` heading.
- **Files**: `docs/ARCHITECTURE-TARGET.md`.
- **Content**: Signal coverage table (Traces=Beta, Metrics=Alpha,
  Logs=Unimplemented), date-stamp 2026-05-12, pkg pin
  `opentelemetry: 0.18.11` (Workiva), scope note (Traces only active),
  future-review trigger (2026-11-12 / >= 0.19.0).
- [Story: FR-DWO-001, FR-DWO-002, FR-DWO-003, FR-DWO-004, FR-DWO-005]

### T-DWO-002 — Run gates and archive

- **Action**: Run `verify.sh` and `constitution-linter.sh` from the
  worktree root; confirm both exit 0. Set `.forge.yaml` status to
  `implemented`, then archive by adding `archived` to the timeline.
- **Files**: `.forge/changes/doc-workiva-otel-status/.forge.yaml`.
- [Story: NFR-DWO-003]
