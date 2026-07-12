# Proposal: b6-7-harness

<!-- Created: 2026-07-12 -->
<!-- Schema: default -->
<!-- Audit: B.6.7 (docs/new-archetypes-plan.md §6.1 B.6 + §0.13 B.6 brick table row 7 — b6-7.test.sh ≥35 + snapshot tarball ; THE PROMOTION GATE candidate→stable/scaffoldable:true, ADR-B6-1-002, mirroring B.7.6 + B.8.14-C2) -->
<!-- Input: b6-1-schema (the candidate schema this brick flips) + b6-2-scaffolder (the gated scaffolder body + the b6-7 TODOs) + b7-6-harness (the ai-native-rag promotion precedent, structurally cloned here) -->

## Problem

The `event-driven-eu` archetype is **fully scaffolded but inert**. As of B.6.10
the chain has shipped: the candidate schema (b6-1), the complete template tree +
gated scaffolder body (b6-2, 48 templates, verify-then-pin'd backend), the
event/AsyncAPI/NATS/Temporal standards (b6-3), the compliance artefacts (b6-4/b6-9),
the per-layer CI templates (b6-5), the Helm charts (b6-6), and the Janus
broker-refusal rule (b6-10). Yet `forge init --archetype event-driven-eu` still
**refuses with exit 3** because the schema is `stage: candidate` /
`scaffoldable: false`.

That refusal is by design and gated on this brick. Three concrete facts make
b6-7 the gate:

1. **The schema is candidate.** `.forge/schemas/event-driven-eu/1.0.0.yaml:41-42`
   declares `stage: candidate` + `scaffoldable: false`. The CLI's
   `selectScaffoldableVersion` returns null for it, so the versioned-schema layer
   refuses (`b6-1.test.sh` T-005/T-006 records candidate/false; `b6-2.test.sh`
   T-006 asserts the wrapper refuses exit 3 while candidate). The schema header
   (`1.0.0.yaml:19-22`) states promotion "happens in the B.6.7 snapshot/harness
   brick, gated on a green b6.test.sh (>=35 tests) proving a real end-to-end
   scaffold — mirroring the B.7.6 (ai-native-rag) and B.8.14-C2 flips
   (ADR-B6-1-002)."

2. **The scaffolder body is already built and gated — not missing.**
   `bin/forge-init-event-driven-eu.sh:75-96` reads the schema's
   `stage`/`scaffoldable` itself: while candidate it refuses (exit 3, structured
   `[REFUSAL …]`, zero writes); "the moment the schema is promoted to `stable` /
   `scaffoldable: true` … the gate opens and this same body renders the scaffold
   with NO further edits to this file" (lines 17-19). b6-2's L2 already proves the
   render path works under the `FORGE_EDE_FORCE_SCAFFOLD=1` override
   (`b6-2.test.sh` T-L2-003). So promotion is a **schema flip + bundle regen**, not
   a new scaffolder.

3. **The live codegen + build was explicitly deferred to b6-7.**
   `bin/forge-init-event-driven-eu.sh:166-184` carries the deferred post-render
   steps: `buf generate` (shared/protos → Connect/gRPC stubs into `backend/gen/rust`
   + TS into `gen/ts`) and `cargo fetch`. The proto codegen manifest
   (`shared/protos/buf.gen.yaml.tmpl:14-34`) uses **remote BSR plugins**
   (`buf.build/community/neoeinstein-tonic`, `buf.build/bufbuild/es`, …), so
   `buf generate` needs buf **and BSR network access**. The archetype's
   end-to-end build path (proto → Rust + TS codegen → `cargo build`/`test` of the
   rendered workspace) has never been run and asserted as a promotion gate — only
   the hermetic render + offline `cargo check` (b6-2 L2, opt-in). Promoting the
   archetype to `scaffoldable: true` without first proving that path is exactly the
   "broken scaffold" the candidate gate exists to prevent.

So the archetype's end-to-end build path has never been proven as a promotion
gate. **This brick is the promotion gate.** It ships a comprehensive promotion
test suite (≥35 tests) that proves the whole archetype end-to-end, wires + verifies
the deferred live codegen/build, and — only once that suite is green — flips the
schema to `stable` / `scaffoldable: true` and regenerates the CLI bundle so
`forge init --archetype event-driven-eu` stops refusing and renders the tree.

**Ground truth (re-read + LIVE-verified 2026-07-12, Article III.4):**

- **No constitution amendment is required.** Unlike B.8.14 (which split into
  prep + flip *because* §VIII.1 Kong→Envoy was a constitution amendment requiring
  a ≥7-day Article XII window), this promotion touches only the archetype schema,
  the dispatch-table `status` marker, and the CLI bundle. It amends nothing in
  `.forge/constitution.md`, no standard, and no other archetype (Q-A).
- **The validator's invariant is one-directional.**
  `validate-foundations.sh::check_versioned_schema_siblings` (lines 446-454)
  enforces `candidate ⇒ scaffoldable: false` (line 453) and `stage=stable
  requires version ≥ 1.0.0 without prerelease` (lines 448-451). There is **no**
  `stable ⇒ scaffoldable:true` clause. event-driven-eu `1.0.0` satisfies the
  version floor; flipping to `stable` + `scaffoldable:true` clears the candidate
  clause and stays valid (live-checked: `validate-foundations.sh` PASS on this base).
- **buf AND cargo are present on this dev host (2026-07-12).** `buf 1.70.0`,
  `cargo 1.97.0`, `node v24.8.0`, `python3 3.13.7` + PyYAML 6.0.3 are all on PATH.
  So — unlike b7-6, where buf was absent locally — the live codegen/build path
  (`buf generate` → Rust+TS stubs → `cargo build`/`test`) can be run genuinely
  LIVE here and recorded honestly. CI's `harness` job has no buf/cargo, so the L2
  legs SKIP there; the live path runs in the `harness-rust` CI job.
- **event-driven-eu has NO active frontend surface.** The schema declares a
  `frontend` layer whose only surface (`ops-console`, Qwik) is `status: deferred`
  (`1.0.0.yaml:106-112`); the template tree ships NO `frontend/` directory
  (backend/infra/shared only). So there is NO Qwik `tsc` L2 leg (the b7-6 rag_pb
  ride-along has no analogue here).
- **The bundle is a gitignored build artifact.** `cli/assets/` is gitignored;
  `npm run bundle` mirrors `.forge/` into `cli/assets/`. CI runs `npm run bundle`
  fresh every run (`forge-ci.yml:52-56`), so the schema flip propagates to the CLI
  automatically in CI; locally the adopter rebuilds. This is exactly how B.7.6 and
  B.8.14-flip handled it.

## Solution

Structurally clone the already-merged B.7.6 (ai-native-rag) promotion shape,
adapted to the event-driven-eu stack (NATS/Temporal/AsyncAPI, `EventService`
Connect proto, no frontend). Concretely:

1. **Promotion test suite `.forge/scripts/tests/b6-7.test.sh` (≥35 tests).**
   Four tiers (mirroring the b7-6 tier structure):
   - **Tier A — aggregation (hermetic):** re-run each sibling B.6 per-brick harness
     (b6-1, b6-2, b6-3, b6-4, b6-5, b6-6, b6-9, b6-10) at its CI level and assert
     each exits 0 (a genuine superset gate); absent sibling → clean SKIP.
   - **Tier B — net-new L1 e2e structural (hermetic, CI-safe):** the cross-brick
     coherence of the assembled archetype the per-brick siblings don't check — the
     `EventService` Publish/ReadStream proto + `events.v1` versioning/idempotency
     fields, the buf.gen codegen-manifest Rust+TS targets, the buf.yaml lint/breaking
     governance, the AsyncAPI 3.1 event SSoT, the scaffold-plan↔tree full coverage,
     the NATS-idempotency/inbox/event-store/saga-compensation/activity-only standards
     markers, pin discipline, the gated wrapper + dispatch entry, and the bin-server
     axum surface + DI wiring.
   - **Tier C — L2 live-codegen (toolchain-gated, SKIP-when-absent):** render via
     `overlay.sh` (b6-2 convention), then the **live** path: `buf generate` (proto →
     Rust `backend/gen/rust` + TS `gen/ts`), `cargo build`/`cargo test --workspace`
     of the rendered backend. SKIP gracefully when buf/BSR/cargo absent (the b6-2/b7-6
     precedent); these are the legs that MUST run green in the `harness-rust` CI job.
   - **Tier D — promotion post-flip guard + committed snapshot:** before the flip,
     the schema is still candidate + the CLI still refuses; the flip inverts these to
     assert stable + scaffoldable:true + the CLI renders; plus the committed snapshot
     tarball is present/valid/extractable.
2. **Wire + verify the deferred live codegen/build.** Confirm `task proto`
   (`buf generate`) materialises the Rust stubs (`backend/gen/rust`) + the TS
   descriptor (`gen/ts`); run `cargo build`/`cargo test --workspace` on the rendered
   backend. The *mechanism* is template-level (the `Taskfile.yml.tmpl` proto/build
   targets + `buf.gen.yaml.tmpl` already exist); b6-7's job is to make the
   end-to-end run green and assert it in Tier C.
3. **Re-verify LIVE pins build.** Run the live cargo build of the rendered
   workspace; record the result in a research file. Fix only pins that genuinely
   fail to resolve (verify-then-pin LIVE, recorded; pinned only in `Cargo.toml.tmpl`).
4. **Snapshot tarball.** Ship a deterministic snapshot of the framework owned tree
   at `.forge/scaffold-snapshots/event-driven-eu/1.0.0.tar.gz` via
   `bin/forge-snapshot.sh build event-driven-eu 1.0.0` (the flagship / ai-native-rag
   convention for `forge upgrade` BASE recovery). Committed, git-tracked (like the
   ai-native-rag / full-stack / mobile-only snapshots).
5. **The flip (FINAL, gated).** Only after the suite is green: edit
   `.forge/schemas/event-driven-eu/1.0.0.yaml` `stage: candidate → stable`,
   `scaffoldable: false → true`, reword the candidate-semantics header; flip the
   dispatch-table `status: candidate → stable`; invert the sibling held-guards
   (`b6-1.test.sh` T-005/T-006/L2 + `b6-2.test.sh` T-006/T-009/T-010) in lockstep;
   add the CLI scaffold-matrix fixture (`cli/test/e2e/archetype-fixtures/event-driven-eu.yml`);
   `npm run bundle` regen; register `b6-7.test.sh` in `forge-ci.yml`. Full suite +
   `verify.sh` + `constitution-linter.sh` + `validate-foundations.sh` green.

## Scope In

- `.forge/scripts/tests/b6-7.test.sh` — the ≥35-test promotion suite (Tier A/B/C/D)
  + registration in `.github/workflows/forge-ci.yml`.
- Live verification of the b6-2 deferred codegen (`buf generate`, `cargo`
  build/test) — recorded honestly in a research file.
- A committed snapshot tarball at `.forge/scaffold-snapshots/event-driven-eu/1.0.0.tar.gz`.
- **The schema flip** (`event-driven-eu/1.0.0.yaml` stage/scaffoldable) — the FINAL,
  suite-gated task.
- **The dispatch-table `status` flip** (candidate → stable) + refusal-comment reword.
- The lockstep harness inversions (b6-1 T-005/006/L2, b6-2 T-006/009/010) in the
  SAME commit as the flip.
- The CLI scaffold-matrix fixture `cli/test/e2e/archetype-fixtures/event-driven-eu.yml`
  (required by t5-1 T-016 + archetypes-smoke.test.ts once the archetype is scaffoldable).
- `npm run bundle` regen so the CLI stops refusing (gitignored artifact).
- The forge-ci line-budget lock-step (bump the current 380 ceiling in all coupled
  harnesses + docs) for the b6-7 registration + the `harness-rust` L2 leg.

## Scope Out (Explicit Exclusions)

- **No constitution amendment, no standard bump, no other-archetype edit.**
- **No new scaffolder body.** `forge-init-event-driven-eu.sh` auto-opens on the flip
  with no edit (lines 17-19, 72-73).
- **No new event/saga feature.** b6-3/b6-4/b6-5/b6-6/b6-9/b6-10 are separate bricks;
  b6-7 *aggregates* their harnesses, it does not re-implement them.
- **No `examples/forge-eda-example/`** — that is B.6.8 (which follows this flip so
  its example renders from a stable archetype; soft relation, not a hard dependency).
- **No new CI job.** The b6-7 L2 legs reuse the existing `harness-rust` buf+rust+node
  job (a second live-codegen step), avoiding a job-count cascade (ADR-B6-7-005).
- **No edit to the frozen full-stack 1.0.0/2.0.0 trees, no `archetype.schema.json`
  change.**

## Impact

- **Users**: after this brick, `forge init --archetype event-driven-eu` STOPS
  refusing (exit 3) and renders a NATS JetStream + Temporal saga + AsyncAPI + Postgres
  event-store tree that builds end-to-end (`task proto` → `cargo build`). First time
  the archetype is usable.
- **Technical**: the schema flips candidate→stable/scaffoldable:true (the source-of-
  truth edit); the dispatch `status` flips to stable (moving the archetype into the
  cli-trust scaffold matrix); the wrapper auto-activates; the bundle re-mirrors the
  schema; the CLI's `selectScaffoldableVersion` now returns 1.0.0.
- **Dependencies**: B.6.1/2/3/4/5/6/9/10 archived; B.6.8 (example) soft-follows.

## Constitution Compliance (v2.0.0)

- **Article I (TDD)**: `b6-7.test.sh` is authored RED-first (Tier D fails before the
  flip); the live legs prove the rendered tree compiles + its tests pass.
- **Article III (Specs Before Code)**: proposal → specs → design → tasks before any
  harness/schema edit. **III.4 anti-hallucination**: every claim is grounded in a
  cited file read 2026-07-12; the live pins + codegen are LIVE-verified, not assumed.
- **Article VIII.2 (orchestration)**: the suite asserts the rendered tree preserves
  the Temporal activity-only saga + compensation markers under live build.
- **Promotion discipline (ADR-B6-1-002)**: the suite GATES the flip — the flip is the
  last task, performed only after the suite is green.

## Open Questions (resolved at design)

- **Q-A** — Single change vs split? **Single change** (no constitution-amendment
  window forces a split; mirrors B.7.6 ADR-B7-6-001).
- **Q-B** — Where do the live legs run / how is the flip justified? The live path runs
  in the existing `harness-rust` CI job (a second `b6-7.test.sh --level 1,2` step) as
  a permanent per-PR gate, AND is run + recorded LIVE on this buf+cargo host
  (ADR-B6-7-005).
- **Q-C** — Suite composition: aggregate the 8 siblings + net-new e2e (ADR-B6-7-002).
- **Q-D** — Snapshot tarball: ship it, deterministic, committed (ADR-B6-7-004).

---

**Gate**: Proposal created at `.forge/changes/b6-7-harness/proposal.md`.
Next → `/forge:specify b6-7-harness`.
