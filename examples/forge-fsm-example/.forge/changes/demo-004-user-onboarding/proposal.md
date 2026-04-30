# Proposal: demo-004-user-onboarding

<!-- Audit: C.1 (in-flight illustrative demo, status: specified) -->
<!-- Layers: [backend, frontend, protos] — multi-layer, will trigger Janus -->

## Problem

Adopters need to see what a **live, in-flight Forge spec** looks
like — one that has been written but not yet designed, where
genuine ambiguity in the requirements has been surfaced via
Article III.4's `[NEEDS CLARIFICATION:]` markers and is awaiting
product/engineering resolution before design begins.

The 3 archived demos (001-003) all show the **end state** of a
change. They do not show what a spec looks like *while it is
still being negotiated*. Adopters miss this view.

## Solution

Introduce `demo-004-user-onboarding` — a multi-layer change
covering a realistic feature (user onboarding flow with email
verification) — and **deliberately stop the change at status :
specified**. The change ships :

- `proposal.md` (this file).
- `specs.md` with FR-BE-/FR-FE-/FR-IN- requirements AND at least
  one realistic `[NEEDS CLARIFICATION:]` marker on a
  product-decision-pending question.
- No `design.md`, no `tasks.md`, no `features/`, no application
  code.

The demo is **not archived**. Its `.forge.yaml` declares
`status: specified` and only `timeline.specified` is populated.
Future iterations of this example may advance demo-004 through
the design / plan / implement / archive phases ; for c1's
purpose, the in-flight state is the artefact.

## Scope In

- Proposal + specs only.
- `[NEEDS CLARIFICATION:]` markers on at least one ambiguous
  product decision.
- Multi-layer FR namespacing (FR-BE-/FR-FE-/FR-IN-) demonstrated
  in the spec.

## Scope Out

- Design phase (deliberately not run).
- Tasks phase.
- Implementation.
- Archive.
- Application code in `frontend/` / `backend/` / `shared/protos/`.

## Impact

- **Technical impact**: zero application code. Two markdown
  files + one `.forge.yaml`.
- **Risk level**: Trivial. The demo is documentation.

## Constitution compliance

- **Article III.4 (Anti-hallucination)**: the `[NEEDS
  CLARIFICATION:]` marker MUST stop implementation work — this
  demo is the canonical illustration of that protocol.
- **Article IV.4 (Lifecycle)**: every change's `.forge.yaml`
  declares its current state ; demo-004 is `specified` and stays
  there until a follow-up explicitly advances it.
