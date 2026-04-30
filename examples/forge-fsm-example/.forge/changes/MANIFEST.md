# Demo changes — manifest

<!-- Audit: C.1 (c1-reference-project FR-EX-006) -->

This file is the **chronological index** of demo changes shipped
under `examples/forge-fsm-example/.forge/changes/`. Listed in
archive order so adopters reading the directory get a narrative.

| Demo | Status | One-line summary |
|---|---|---|
| [`demo-001-greeting-service`](demo-001-greeting-service/) | archived (2026-04-30) | Single-layer backend — minimal gRPC `Greeter` service with hexagonal Rust + cucumber-rs BDD. |
| [`demo-002-greeting-screen`](demo-002-greeting-screen/) | archived (2026-04-30) | Single-layer frontend — Flutter screen consuming demo-001's contract via Cubit + `flutter_bloc`. Widget + golden test. |
| [`demo-003-rate-limit`](demo-003-rate-limit/) | archived (2026-04-30) | Multi-layer (backend + infra) — Kong rate-limit plugin demonstrates Janus orchestration with per-layer designs / tasks (FR-GL-016). |
| [`demo-004-user-onboarding`](demo-004-user-onboarding/) | **specified** (in-flight) | Multi-layer (backend + frontend + protos) — illustrates Article III.4 anti-hallucination protocol with realistic `[NEEDS CLARIFICATION:]` markers. Deliberately not advanced past the spec phase. |

Each demo's change directory contains the canonical artefacts :
`.forge.yaml`, `proposal.md`, `specs.md`, and (for archived demos)
`design.md` or per-layer `design-<layer>.md`, `tasks.md` or
per-layer `tasks-<layer>.md`, and `features/<demo>.feature` for
the BDD scenarios.

For the framework-level meta-doc on this `examples/` tree, see
`../../../README.md` (the example tree's top-level README) and
`../../../../README.md` (the `examples/` directory README in the
Forge framework repo).
