# Design: b6-7-harness

<!-- Designed: 2026-07-12 -->
<!-- Routing: Centurion (Rust TDD/codegen) + Vulcan (workspace build) + Hermes-Async (event/AsyncAPI coherence) ; gate review Tribune -->
<!-- Precedent cloned 2026-07-12: b7-6-harness (the ai-native-rag promotion, structurally identical) ; b6-2.test.sh (the render/cargo L2 convention) ; forge-init-event-driven-eu.sh (the gated body) -->

**Constitution** : v2.0.0 — no bump (this brick amends NO article, NO standard,
NO other archetype). Gate at end: no Article violation.

## Grounding (mechanics re-read + LIVE 2026-07-12 — every seam cited)

- **The flip is one schema edit + one dispatch `status` edit + one bundle regen.**
  The scaffolder body (`bin/forge-init-event-driven-eu.sh`) auto-opens on the flip
  with NO edit to that file (lines 17-19, 72-73). The render path is already proven
  via `FORGE_EDE_FORCE_SCAFFOLD=1` (b6-2 T-L2-003).
- **The deferred live path** is `task proto` (`Taskfile.yml.tmpl:46-49` →
  `cd shared/protos && buf generate`) which drives `buf.gen.yaml.tmpl:14-34`
  (remote BSR plugins: neoeinstein-tonic v0.4.0, neoeinstein-prost v0.4.0,
  bufbuild/es v2.2.0, connectrpc/go v1.20.0) → Rust stubs into `backend/gen/rust`
  + TS into `gen/ts` + Go into `gen/go`. The rendered Cargo workspace
  (`events`/`eventstore`/`saga`/`bin-server`) compiles WITHOUT the generated stubs
  (the stubs land in `backend/gen/`, not a workspace member) — exactly like the
  b7-6 backbone.
- **buf + cargo are present on this host (LIVE-probed 2026-07-12).** buf 1.70.0,
  cargo 1.97.0, node v24.8.0, python3 3.13.7 + PyYAML 6.0.3, task 3.52.0, tar, gzip.
  `tsc` is absent — irrelevant (no frontend). So the Tier C legs run LIVE here.
- **Validator** (`validate-foundations.sh:446-454`): stable needs version ≥ 1.0.0
  no-prerelease (1.0.0 ✓); `candidate ⇒ scaffoldable:false` stops applying once
  stable. No `stable ⇒ scaffoldable:true` clause. LIVE-run PASS on this base.
- **Bundle**: `npm run bundle` mirrors `.forge/` into gitignored `cli/assets/`;
  CI runs it fresh (`forge-ci.yml:52-56`).
- **Scaffold-matrix cascade**: `archetypes-smoke.test.ts` partitions on dispatch
  `status`: candidates are asserted to REFUSE exit 3; non-candidates must have a
  fixture + are scaffolded (toolchain-gated on cargo+buf). Flipping the schema
  WITHOUT flipping dispatch `status` would break the smoke candidate-refusal test
  (the schema renders but the test still expects refusal) — so the dispatch flip +
  the fixture are MANDATORY lockstep, not optional. `t5-1.test.sh` T-016
  (`_test_t51_l1_016_dispatch_xref`) independently requires the fixture for every
  `status != candidate` archetype.

---

## Architecture Decisions

### ADR-B6-7-001 — Single change, not a prep/flip split (ratified)
**Context**: B.8.14 split into prep + flip only because §VIII.1 Kong→Envoy was a
Constitution amendment requiring a ≥7-day window. This promotion amends nothing in
the constitution.
**Decision**: ONE change; the flip is the suite-gated FINAL task (ADR-B6-7-006).
**Compliance**: Article XII not engaged; III (spec-first). Mirrors ADR-B7-6-001.

### ADR-B6-7-002 — Suite = aggregate the 8 siblings + net-new e2e (ratified)
**Context**: the 8 landed B.6 harnesses total **111 run_tests** (b6-1 18, b6-2 13,
b6-3 7, b6-4 19, b6-5 9, b6-6 13, b6-9 20, b6-10 12 — live-counted 2026-07-12). Each
proves one brick; none proves the *assembled* archetype builds end-to-end.
**Decision**: `b6-7.test.sh` has four tiers: (A) aggregation — re-run each sibling at
its CI level, assert exit 0 (absent → clean SKIP); (B) net-new L1 e2e — the
cross-brick coherence (EventService proto surface, buf.gen targets, buf.yaml
governance, AsyncAPI SSoT, scaffold-plan↔tree coverage, conformance markers, pin
discipline, wrapper/dispatch, bin-server axum+wiring); (C) L2 live-codegen
(buf generate + cargo); (D) promotion post-flip guard + snapshot. Net-new ≈ 21 (B) +
3 (C) + 3 (D) → total ≈ 35 (8 + 21 + 3 + 3).
**Compliance**: III.4 (test count grounded in the live run_test census).

### ADR-B6-7-004 — Snapshot tarball: deterministic, committed (ratified)
**Context**: `forge upgrade` recovers BASE from a committed per-archetype snapshot
tarball (the ai-native-rag / full-stack / mobile-only snapshots are git-tracked at
`.forge/scaffold-snapshots/<name>/1.0.0.tar.gz`). `bin/forge-snapshot.sh build`
captures the framework `owned:` tree deterministically (SOURCE_DATE_EPOCH + sorted +
uid/gid0 + ustar + gzip-mtime0).
**Decision**: ship a committed `.forge/scaffold-snapshots/event-driven-eu/1.0.0.tar.gz`,
built LAST (after the flip so it captures the promoted owned tree). Tier D asserts
present / ≤ 2 MB / valid gzip-tar / extractable. Mirrors b7-6 T-D03.
**Compliance**: III.4 (an honest, reproducible artifact, not a fabricated one).

### ADR-B6-7-005 — Reuse the `harness-rust` CI job; NO new job (ratified — divergence from b7-6)
**Context**: `buf generate` needs buf + BSR network (remote plugins); cargo needs the
registry. The `harness` CI job has neither. b7-6 added a dedicated `harness-rust` job
(buf 1.70.0 + `dtolnay/rust-toolchain` + node) that runs `b7-6.test.sh --level 1,2`.
That job ALREADY EXISTS on this base (`forge-ci.yml:303-333`) with exactly the
toolchain b6-7's Tier C needs.
**Decision**: rather than duplicate a ~30-line job (which would take the workflow from
6 → 7 worker jobs and trigger the job-count cascade — g1 workflow_shape, c1 six_jobs,
forge-ci.md FR-CI-001, forge-self-ci.md, the summary needs/aggregator), b6-7 adds a
SECOND step `bash .forge/scripts/tests/b6-7.test.sh --level 1,2` to the existing
`harness-rust` job and generalizes its name. The live codegen/build path runs on
every PR (the ADR-B7-6-005 intent), the toolchain is shared, and the diff is ~4 lines
instead of ~30. The flip is justified by this job green in CI + a recorded LIVE run on
this buf+cargo host (`.forge/research/b6-7-live-codegen.md`).
**Consequences**: smallest viable change; NO job-count cascade (job count stays 6);
only the SIZE budget moves (380 → 400). The `harness` job still runs b6-7 at
`--level 1` (buf-less L1 + aggregation + guards).
**Compliance**: I (the live legs ARE the e2e test, run per-PR); III.4 (real CI gate,
not a fabricated claim). Smallest-diff (Executor discipline).

### ADR-B6-7-006 — Flip is the LAST task, only if green (ratified)
Mirrors ADR-B7-6-006. The schema flip + dispatch flip + sibling inversions + fixture +
bundle are the final phase, after Tiers A/B/C + snapshot are green. Tier D asserts the
post-flip positive; it is RED before the flip (the TDD RED state for the promotion).

### ADR-B6-7-007 — The forge-ci size budget: bump 380 → 400 in lock-step (ratified)
**Context (live-counted 2026-07-12)**: `forge-ci.yml` is **378 lines**, budget **380**,
**6 worker jobs**. The budget is asserted in FOUR harnesses (`g1`, `c1`, `t5-1`,
`t5-otel-live-run`) + TWO docs (`forge-ci.md`, `forge-self-ci.md`).
**Decision**: registering `b6-7.test.sh --level 1` (+1 line) + the `harness-rust`
`--level 1,2` step (~3 lines) pushes the workflow to ~382. Bump the size budget
380 → **400** (headroom) in all FOUR harnesses + TWO docs in the SAME commit; re-run
the four asserting harnesses GREEN. NO job-count edit (ADR-B6-7-005). forge-self-ci.md
has no SemVer frontmatter → narrative refresh, no version bump.
**Compliance**: I (asserting harnesses stay green); III.4 (LIVE 378/380/6 baseline recorded).

---

## Component / seam design

```
.forge/changes/b6-7-harness/                   # this plan (no production code)
.forge/scripts/tests/b6-7.test.sh              # NEW — the ≥35-test promotion suite (4 tiers)
.forge/research/b6-7-live-codegen.md           # NEW — honest record of the live buf/cargo run + pin verification
.forge/scaffold-snapshots/event-driven-eu/1.0.0.tar.gz  # NEW (committed) — forge upgrade BASE snapshot
.forge/schemas/event-driven-eu/1.0.0.yaml      # MODIFIED (FINAL) — stage/scaffoldable flip + header reword
.forge/scaffolding/dispatch-table.yml          # MODIFIED (FINAL) — status candidate→stable + comment reword
.forge/scripts/tests/b6-1.test.sh              # MODIFIED (lockstep) — T-005/006/L2 inverted to stable/scaffoldable/renders
.forge/scripts/tests/b6-2.test.sh              # MODIFIED (lockstep) — T-006/009/010 inverted (wrapper renders, schema stable, dispatch stable)
cli/test/e2e/archetype-fixtures/event-driven-eu.yml  # NEW — scaffold-matrix fixture (t5-1 T-016 + smoke)
.github/workflows/forge-ci.yml                 # MODIFIED — register b6-7 (--level 1) + harness-rust b6-7 --level 1,2 step; grows past 380 → budget 400
.forge/scripts/tests/g1.test.sh                # MODIFIED (lock-step) — size budget 380→400
.forge/scripts/tests/c1.test.sh                # MODIFIED (lock-step) — size budget 380→400
.forge/scripts/tests/t5-1.test.sh              # MODIFIED (lock-step) — size budget 380→400
.forge/scripts/tests/t5-otel-live-run.test.sh  # MODIFIED (lock-step) — size budget 380→400
.forge/specs/forge-ci.md                       # MODIFIED (lock-step) — NFR-CI-002 / FR-CI-013 "≤ 380"→400
.forge/standards/global/forge-self-ci.md       # MODIFIED — budget 380→400 (narrative refresh; no SemVer bump)
cli/assets/                                     # REGENERATED (gitignored) via npm run bundle
```

## The ≥35-test suite composition (the heart of b6-7)

**Tier A — aggregation (8 tests):** one `run_test` per sibling (b6-1 --level 1,2,
b6-2 --level 1, b6-3 --level 1, b6-4 --level 1,2, b6-5 --level 1,2, b6-6 --level 1,
b6-9 --level 1,2, b6-10 --level 1,2 — mirroring the forge-ci.yml harness array
levels); absent sibling → clean SKIP (FR-B6-7-003).

**Tier B — net-new L1 e2e structural (≈ 21 tests, hermetic, CI-safe):**
- proto: `service EventService` + unary `rpc Publish` retained.
- proto: unary `rpc ReadStream` retained.
- proto: package `events.v1` + idempotency_key + event_version fields.
- codegen manifest: neoeinstein-tonic + neoeinstein-prost → `backend/gen/rust`.
- codegen manifest: bufbuild/es → `gen/ts` (TS Connect surface).
- buf.yaml: lint + breaking governance present (proto-contracts.md).
- scaffold-plan ↔ tree: no orphan `.tmpl`.
- scaffold-plan ↔ tree: no dangling `source:`.
- AsyncAPI: contract present + `asyncapi: 3.1.0`.
- AsyncAPI: channels + operations + messages (event SSoT structure).
- layer roots: backend/infra/shared + shared/protos + shared/asyncapi.
- backend workspace members: events/eventstore/saga/bin-server.
- events: Nats-Msg-Id idempotent publish marker.
- events: inbox dedup marker.
- eventstore: append-only + idempotent append (ON CONFLICT).
- saga: Temporal activity-only bias marker.
- saga: compensation coordinator marker.
- event versioning: event_version marker (envelope + store).
- pin discipline: LIVE pins present in Cargo.toml.tmpl.
- pin discipline: no pin leaked into a standard.
- gated wrapper + dispatch entry + bin-server axum surface + DI wiring composition.

**Tier C — L2 live-build (≈ 3 tests, toolchain-gated, SKIP-when-absent):**
- render via `overlay.sh` (absolutize-temp-plan, b6-2 `_b62_render_plan`) + byte-stable re-render.
- `buf build` (the EventService proto contract compiles into a FileDescriptorSet). SKIP if buf absent. NOTE: full `buf generate` plugin codegen is NOT a gate (ADR-B6-7-008).
- `cargo build` + `cargo test --workspace` on the rendered backend — the real build proof. SKIP if cargo absent / registry offline.

**Tier D — promotion post-flip guard + committed snapshot (≈ 3 tests):**
- promotion guard: schema stage:stable / scaffoldable:true (post-flip; RED pre-flip).
- CLI/wrapper guard: wrapper no longer exits 3 (post-flip).
- committed snapshot tarball present + ≤ 2 MB + valid gzip/tar + extractable.

Total: 8 + 21 + 3 + 3 = **35** (≥35, ADR-B6-7-002).

## Where the live codegen runs (Q-B mechanics)

The `harness` job runs `b6-7.test.sh --level 1` (L1 + aggregation + guards; L2 legs
SKIP, buf-less). The EXISTING `harness-rust` job (buf 1.70.0 + Rust toolchain + node)
gains a second step `b6-7.test.sh --level 1,2` — the live legs (`buf generate` → Rust
`backend/gen/rust` + TS `gen/ts`, `cargo build`/`test`) as a permanent per-PR gate
(ADR-B6-7-005). On a buf-less host the L2 legs SKIP, so `--level 1,2` stays runnable
locally. On THIS host (buf + cargo present) they run LIVE and are recorded honestly.

## Testing strategy

- **RED-first**: author `b6-7.test.sh` Tier D (post-flip form) before the flip; confirm
  Tier D fails on the pre-flip tree (schema candidate, snapshot absent), then flip to GREEN.
- **Aggregation** re-runs siblings live — keeps b6-7 honest as a superset gate.
- **No-regression sweep** before the flip: full suite + `verify.sh` +
  `constitution-linter.sh` + `validate-foundations.sh` green.
- **Independent review** (separate reasoning pass) re-verifies the flip is last +
  suite-gated + the honest run record + no fabricated CI-green + ≥35 real tests.

## Constitutional Compliance Gate

- Article I (TDD): suite RED-first; live legs ARE the e2e test. ✅
- Article III (Specs/anti-hal): every mechanic cited to a file read/LIVE-probed 2026-07-12. ✅
- Article VIII.2 (orchestration): conformance tier asserts Temporal activity-only + saga
  compensation survive; the schema keeps `orchestration.yaml` (temporal) reference. ✅
- Article XII: NOT engaged (no constitution amendment). ✅
- ADR-B6-1-002 promotion gate: suite gates the flip; flip is last. ✅

---

**Gate**: Design complete. Next → `/forge:plan b6-7-harness`.
