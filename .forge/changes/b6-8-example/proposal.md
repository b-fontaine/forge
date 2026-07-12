# Proposal: b6-8-example

<!-- Created: 2026-07-12 -->
<!-- Schema: default -->
<!-- Audit: B.6.8 (docs/new-archetypes-plan.md §6.1 / §0.13 T7 brick #10) — examples/forge-eda-example/ (3 demos) -->
<!-- Precedent: b7-7-example (examples/forge-rag-example/) + c1-reference-project (examples/forge-fsm-example/) + .forge/specs/example-reference.md -->

## Problem

The `event-driven-eu` archetype now has a **complete, promoted
backbone** — `b6-1-schema` (the `1.0.0` schema), `b6-2-scaffolder`
(48 templates + scaffold-plan + verify-then-pin'd Rust backbone),
`b6-3-standards` (`global/{event-driven,asyncapi-contracts}.md` +
`infra/nats-jetstream.md`), `b6-4-hermes-async`, `b6-5-ci-templates`,
`b6-6-helm`, and — decisively — `b6-7-harness`, which **promoted the
archetype `candidate → stable` / `scaffoldable: false → true`** after a
green ≥35-test suite + the live `harness-rust` codegen/build gate.
`forge init --archetype event-driven-eu` now renders the tree for real
adopters (it no longer refuses with exit 3).

But an adopter evaluating the event-driven archetype has **no concrete
artefact** to inspect, exactly as the audit roadmap flagged for the
flagship before `c1-reference-project` and for RAG before
`b7-7-example`:

> Le nouvel utilisateur n'a aucun moyen de voir à quoi ressemble une
> **bonne** proposal, un **bon** specs.md delta, un **bon** design avec
> ADRs — *pour l'archétype event-driven spécifiquement*.

`examples/forge-fsm-example/` (c1) demonstrates `full-stack-monorepo`;
`examples/forge-rag-example/` (b7-7) demonstrates `ai-native-rag`.
Neither demonstrates the event-driven surfaces that are the whole point
of `event-driven-eu`:

1. **Ingestion** — an axum HTTP endpoint wrapping a command in an
   idempotent, versioned envelope and publishing it to **NATS
   JetStream** (`Nats-Msg-Id` dedup) — `backend/events/`.
2. **Projection** — a consumer that folds the persisted event stream
   (Postgres event store) into a query-optimised **read model**, with
   the inbox dedup guard — `backend/eventstore/` + `backend/events/`.
3. **Saga** — a **Temporal activity-only** saga orchestrating a
   3-step process with reverse-order compensation (Article VIII.2 — no
   ad-hoc saga in application code) — `backend/saga/`.

Without an event-driven reference, every claim the archetype makes
(event versioning, idempotency keys, the outbox/inbox pattern, saga
compensation, AsyncAPI-as-SSoT, the EU-sovereign broker refusals) is
abstract. This brick (#10 of the B.6 chain) closes that gap: a
`forge-eda-example/` reference project with **3 archived demo
application changes** illustrating the event backbone end-to-end.

## Solution

Build a **reference project** under `examples/forge-eda-example/`,
scaffolded from the promoted `event-driven-eu/1.0.0` archetype **through
the real public `forge init --archetype event-driven-eu` CLI path** (see
Impact + ADR-B6-8-001 — this is the key divergence from `b7-7-example`,
which had to use `overlay.sh` because RAG was still `candidate` at its
own creation time), with **3 archived demo application changes** that
demonstrate every event-driven surface.

This change **mirrors `b7-7-example`'s shape** for the event-driven
archetype, reusing the example-tree machinery `c1` already shipped:

- The `examples/` directory, its meta-`README.md`, the skip-guards in
  `verify.sh` / `constitution-linter.sh`, the `.gitignore` example
  entries, and the `example` CI job already exist (FR-EX-001..010,
  FR-GL-026..028, FR-CI-012). **b6-8 reuses them** — it does NOT
  re-create the machinery, only adds a third example tree under it.

### Why render through the real CLI (settled by ADR-B6-8-001)

`b7-7-example` rendered `forge-rag-example/` via `overlay.sh` directly,
because `ai-native-rag` was still `candidate` / `scaffoldable: false`
when b7-7 was authored (its `forge init` path refused with exit 3 —
ADR-B7-7-001). **b6-8's situation is different and simpler:**
`event-driven-eu` is ALREADY `stable` / `scaffoldable: true` (promoted
by `b6-7-harness`). So b6-8 renders the example the way an actual
adopter would — `forge init --archetype event-driven-eu` — which is a
*stronger* demonstration than b7-7 could give at its creation time: it
proves the promoted archetype scaffolds end-to-end through the public
CLI, not just through the internal renderer.

### What ships

1. **`examples/forge-eda-example/`** — a fully-rendered
   `event-driven-eu/1.0.0` project tree, produced by running
   `forge init --archetype event-driven-eu` on a clean dir, then
   committed verbatim. Includes: `.forge/` (with
   `scaffold-manifest.yaml`), `.claude/`, `backend/` (Rust workspace —
   `events/`, `eventstore/`, `saga/`, `bin-server/`), `infra/`
   (NATS JetStream + Postgres event store + Temporal cluster Helm/compose),
   `shared/asyncapi/` (AsyncAPI 3.1) + `shared/protos/v1/events/`
   (`events.proto` with `EventService.Publish` / `ReadStream`),
   `Taskfile.yml`, `docker-compose.dev.yml`, `CLAUDE.md`, `README.md`,
   `.gitignore`, `.forge.yaml` declaring `schema: event-driven-eu`.

2. **3 archived demo application changes** under
   `examples/forge-eda-example/.forge/changes/`:
   - **`demo-001-ingestion-http-nats`** (single-layer backend) —
     axum HTTP ingestion → idempotent, versioned `EventEnvelope` →
     publish to NATS JetStream (`Nats-Msg-Id` dedup). Full TDD +
     cucumber-rs BDD.
   - **`demo-002-projection-readmodel`** (single-layer backend) — a
     consumer that folds the Postgres event stream into a read-model
     projection, deterministic + replayable, guarded by the inbox
     dedup (outbox/inbox pattern). cucumber-rs BDD.
   - **`demo-003-order-saga`** (multi-layer backend + infra) — a
     Temporal **activity-only** 3-step saga (reserve stock → charge
     payment → confirm shipment) with reverse-order compensation
     (Article VIII.2). Triggers the **Janus** cross-layer orchestrator
     (≥ 2 layers: `backend` saga crate + `infra` Temporal cluster
     substrate). Per-layer designs/tasks.

3. **`examples/forge-eda-example/README.md`** — top-of-tree navigation
   (4 canonical H2 sections per FR-EX-002): How this example was built /
   What's in here / Demo changes / Reproducing this example. Documents
   that the tree was rendered via the real `forge init` CLI (the
   archetype is `stable`/`scaffoldable`), and the "no ops-console
   frontend" known gap (the frontend layer is deferred — ADR-B6-1-004).

4. **`examples/README.md` third row** — append `forge-eda-example` to
   the existing examples table (FR-EX-003 was designed for multiple rows).

5. **`example` CI job extension** — the existing `example` job in
   `forge-ci.yml` (FR-CI-012) keeps its `examples/**` paths-filter but
   gains a third tree to gate: run `examples/forge-eda-example/`'s own
   `verify.sh` + `constitution-linter.sh`, and structurally parse the
   EDA archetype's committed YAML. Mirrors the FSM + RAG blocks already
   present (own-gates-only, parse-only — no build, no network).

6. **Test harness `b6-8.test.sh`** — validates the EDA example
   structure (scaffold-manifest present + `archetype: event-driven-eu`,
   3 demos follow naming + each has the 5 artefacts, demo-003 is
   multi-layer, the `example` CI job gates the EDA tree, the size budget
   holds). Mirrors `b7-7.test.sh`'s manifest pattern; registered in
   `forge-ci.yml`'s harness loop.

## Scope In

- The fully-rendered `examples/forge-eda-example/` tree (rendered via
  the real `forge init --archetype event-driven-eu` CLI, then committed
  verbatim).
- 3 archived demo changes (`demo-001-ingestion-http-nats`,
  `demo-002-projection-readmodel`, `demo-003-order-saga`) with all
  lifecycle artefacts (proposal, specs, design/-per-layer, tasks/
  -per-layer, features).
- `examples/forge-eda-example/README.md` (4 canonical H2 sections).
- One appended row in `examples/README.md`.
- Extension of the existing `example` job in `forge-ci.yml` to gate the
  EDA tree (paths-filter already covers `examples/**`).
- A `.forge/changes/MANIFEST.md` inside the EDA example listing the 3
  demos.
- Test harness `.forge/scripts/tests/b6-8.test.sh` + its forge-ci.yml
  harness-loop registration + the `forge-ci.yml` line-budget bump (in
  lockstep with all coupled assertions) if the third gate block exceeds
  the current 400-line cap.
- A size-budget NFR for the EDA example tree (mirror NFR-EX-002).
- Append `b6-8` requirements to `.forge/specs/example-reference.md`
  (the consolidated `FR-EX-*` / `FR-RAGEX-*` spec) + the MODIFIED
  `FR-CI-012` delta to `.forge/specs/forge-ci.md` at archive time.

## Scope Out (Explicit Exclusions)

- **No new example-tree machinery**. The skip-guards (FR-GL-026/027),
  the `.gitignore` entries (FR-GL-028), the `examples/README.md` file,
  and the `example` CI job (FR-CI-012) already exist from c1 — b6-8
  reuses them. Only the `example` job's per-tree steps are extended.
- **No archetype promotion, no archetype/template/schema edit**.
  `event-driven-eu` is already `stable` / `scaffoldable: true` (promoted
  by `b6-7-harness`); b6-8 CONSUMES that archetype, it does not modify
  it. No edit to `.forge/templates/archetypes/event-driven-eu/**`, the
  `1.0.0.yaml` schema, or the `global/{event-driven,asyncapi-contracts}`
  / `infra/nats-jetstream` standards.
- **No ops-console frontend demo** — the `frontend` layer is a single
  DEFERRED surface in the archetype (ADR-B6-1-004); the example ships no
  web UI, so the multi-layer (Janus) demo spans `[backend, infra]`
  instead of `[backend, frontend]` (ADR-B6-8-002).
- **No live NATS / Temporal / Postgres calls in CI**. The demos exercise
  the pipeline with the in-memory fakes the archetype ships
  (`InMemoryEventStore`, the recording publisher, the in-process saga
  coordinator); the `example` CI job runs structural + own-gate checks
  only (no Docker, no `cargo build`, no `buf generate`), mirroring c1's
  and b7-7's parse-only `example` job (ADR-B6-8-004).
- **No compliance demo** (NIS2/DORA/SBOM arrive in `b6-9-compliance`,
  already archived; the example references it but ships no compliance
  demo). **No Janus-rule refusal demo** (b6-10 ships the rules).

## Impact

- **Users affected**: every adopter evaluating the `event-driven-eu`
  archetype (major onboarding uplift); Forge maintainers (a third
  example to maintain alongside the archetype's evolution).
- **Technical impact**: Large. ~40-60 new files under
  `examples/forge-eda-example/` (the rendered tree + its framework
  assets), ~18-20 new files under the example's `.forge/changes/`
  (3 demos × 5-7 artefacts), 1 new harness `b6-8.test.sh`, 1
  `example`-job extension + 1 harness-loop entry + a line-budget bump
  in `forge-ci.yml`, 1 appended row in `examples/README.md`. No
  archetype template, schema, standard, or CLI code is edited.
- **Dependencies**: `b6-1-schema`, `b6-2-scaffolder`, `b6-3-standards`
  (archived — provide the schema + templates + scaffold-plan +
  standards). **`b6-7-harness`** (archived — promoted the archetype to
  `stable`/`scaffoldable`, which is what lets b6-8 render through the
  real CLI). `c1-reference-project` (archived — provides the
  example-tree machinery this brick reuses).
- **Risk level**: **Medium**.
  - The example tree is large; review burden non-trivial (mitigated by
    the c1 + b7-7 precedents — reviewers know the shape).
  - **Shared-file edit to `forge-ci.yml`** (the `example` job + harness
    loop + the line budget). Mitigation: keep the edit additive and
    minimal (one extra gate block + one loop entry + a budget bump in
    lockstep across the four asserting harnesses + the standard doc).

## Constitution Compliance (v2.0.0)

### Article I — TDD

The `b6-8.test.sh` harness follows the manifest pattern (RED first
against an empty `examples/forge-eda-example/`, GREEN once the tree +
demos exist). Each demo's product code is TDD-conformant (every Rust
module in the rendered backbone ships inline `#[cfg(test)]` tests). Each
demo archives its own RED→GREEN cycle.

### Article II — BDD

Every demo ships a `features/<demo>.feature` with realistic Gherkin:
demo-001 covers ingest → publish → dedup; demo-002 covers fold → read
model → replay/inbox-dedup; demo-003 covers the 3-step saga happy path +
the reverse-order compensation path.

### Article III — Specs Before Code

Every demo has a complete proposal → specs → design → tasks pipeline.
The example **is** the demonstration of Article III for the event-driven
archetype. `[NEEDS CLARIFICATION]` markers (III.4) are used in
`open-questions.md` where a genuine ambiguity existed, then resolved.

### Article IV — Semantic Deltas

Each demo's specs.md uses ADDED / MODIFIED / REMOVED delta format.
demo-003 (multi-layer) demonstrates per-layer delta semantics with FR
IDs prefixed by layer (`FR-BE-*`, `FR-IN-*`).

### Article V — Conformance Gate

The example's own gates (its `verify.sh`, `constitution-linter.sh`) all
pass; the extended `example` job in `forge-ci.yml` enforces this on PRs
touching `examples/**`.

### Article VII — Rust Architecture

demo-001/002/003 follow the archetype's hexagonal Rust layering (axum +
the `events`/`eventstore`/`saga` crates). `unwrap()`/`panic!()`
prohibited in production paths.

### Article VIII.2 — Temporal (no ad-hoc saga)

demo-003 exercises the Temporal activity-only saga surface — the
in-process compensation core is the unit-testable logic, the durable
retry/timeout semantics come from Temporal (behind the OFF-by-default
`temporal-sdk` feature). NO ad-hoc saga in application code.

---

## Open Questions for the design phase

See `open-questions.md` (all RESOLVED at design):

1. **Render via real CLI vs overlay.sh.** The archetype is now
   `stable`/`scaffoldable`, so render through the real
   `forge init --archetype event-driven-eu` CLI (the divergence from
   b7-7's ADR-B7-7-001). → ADR-B6-8-001.
2. **Which demo is multi-layer, given no frontend.** The saga demo
   (`[backend, infra]`) — the archetype's `frontend` layer is deferred.
   → ADR-B6-8-002.
3. **3 archived demos vs 3 archived + 1 specified.** Ship exactly 3
   archived (honour the brick count). → ADR-B6-8-003.

---

**Gate**: Proposal created at `.forge/changes/b6-8-example/proposal.md`.
Review and confirm before proceeding to → `/forge:specify b6-8-example`.
