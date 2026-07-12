# Specs: b6-7-harness

<!-- Specified: 2026-07-12 -->
<!-- Namespace: FR-B6-7-* / NFR-B6-7-* / ADR-B6-7-* -->
<!-- Source: proposal.md + bin/forge-init-event-driven-eu.sh (the gated body + deferred codegen) -->
<!--         + .forge/schemas/event-driven-eu/1.0.0.yaml (the schema flipped) -->
<!--         + .forge/scaffolding/dispatch-table.yml (the status marker flipped) -->
<!--         + validate-foundations.sh::check_versioned_schema_siblings (the invariant) -->
<!--         + .forge/changes/b7-6-harness/** (the ai-native-rag promotion precedent, cloned) -->
<!--         + b6-{1,2,3,4,5,6,9,10}.test.sh (the aggregated sibling harnesses) -->

**Constitution** : v2.0.0 (no bump — this brick amends NO constitution article,
NO standard, NO other archetype; mirrors B.7.6 which amended nothing).

**Format** : mostly ADDED (a new promotion suite + a committed snapshot), with
MODIFIED items that are the promotion itself — the schema's `stage`/`scaffoldable`,
the dispatch `status`, and the sibling harness assertions that encode the candidate
precondition. On archive these requirements consolidate into
`.forge/specs/event-driven-eu.md` (B.6 spec-accumulation convention; the prior B.6
blocks there are preserved).

**Ground truth (re-read + LIVE 2026-07-12, Article III.4)** — load-bearing facts:
- Schema candidate: `event-driven-eu/1.0.0.yaml:41-42` (`stage: candidate` /
  `scaffoldable: false`).
- Validator invariant ONE-directional: `validate-foundations.sh:453`
  (`candidate ⇒ scaffoldable: false`); `:448-451` (`stable ⇒ version ≥ 1.0.0`);
  NO `stable ⇒ scaffoldable:true` clause.
- Wrapper auto-opens on flip: `forge-init-event-driven-eu.sh:75-96` (`is_scaffoldable`
  needs stage==stable AND scaffoldable==true).
- Deferred codegen: `forge-init-event-driven-eu.sh:166-184` (`buf generate`,
  `cargo fetch`); codegen manifest `shared/protos/buf.gen.yaml.tmpl:14-34` (Rust →
  `backend/gen/rust`, TS → `gen/ts`, remote BSR plugins).
- Proto surface: `shared/protos/v1/events/events.proto.tmpl` — `service EventService`
  with `rpc Publish` + `rpc ReadStream`, package `events.v1`, idempotency_key +
  event_version fields. NO server-streaming RPC (contrast b7-6's QueryStream).
- Cargo workspace: `backend/Cargo.toml.tmpl` members `events`/`eventstore`/`saga`/
  `bin-server`; LIVE pins async-nats 0.49.1 / sqlx 0.9 / temporalio-sdk 0.5.0 /
  temporalio-client 0.5.0.
- Sibling census (live `grep -c '^\s*run_test'` 2026-07-12): b6-1 18, b6-2 13,
  b6-3 7, b6-4 19, b6-5 9, b6-6 13, b6-9 20, b6-10 12 (= 111 sibling run_tests).
- CI budget: `forge-ci.yml` is **378 lines** with a **380** budget (already bumped
  340→380 by b7-6-harness) and **6 worker jobs** incl. `harness-rust`; budget asserted
  in g1/c1/t5-1/t5-otel-live-run + forge-ci.md + forge-self-ci.md.
- Scaffold-matrix cascade: flipping dispatch `status` → stable moves the archetype
  into the cli-trust scaffold matrix, so t5-1 T-016 (`_test_t51_l1_016_dispatch_xref`)
  + `archetypes-smoke.test.ts` require `cli/test/e2e/archetype-fixtures/event-driven-eu.yml`.

---

## Resolved scope decisions

- **Q-A (single vs split)** → ADR-B6-7-001 **single change** (no amendment window).
- **Q-B (live-codegen / flip justification)** → ADR-B6-7-005: reuse the existing
  `harness-rust` CI job (a second `b6-7.test.sh --level 1,2` step) + a recorded LIVE
  local run on this buf+cargo host.
- **Q-C (suite composition)** → ADR-B6-7-002 (aggregate 8 siblings + net-new e2e).
- **Q-D (snapshot)** → ADR-B6-7-004 (ship a committed deterministic snapshot).

---

## ADDED Requirements

### Promotion test suite (`FR-B6-7-0xx`)

- **FR-B6-7-001** — A dedicated harness `.forge/scripts/tests/b6-7.test.sh` MUST be
  added with **≥35 tests** (`run_test` invocations) covering the archetype
  end-to-end, arg-parsed `--level` + `_helpers.sh` source + `run_test`/`print_summary`
  (mirroring `b6-2.test.sh`/`b7-6.test.sh`). It MUST be registered in
  `.github/workflows/forge-ci.yml`'s hardcoded harness array at the CI-runnable level.
- **FR-B6-7-002** — **Tier B: L1 end-to-end structural (hermetic, CI-safe).** The
  suite MUST assert, by grep/structure over the committed template tree (no
  toolchain): the `EventService` unary Publish + ReadStream RPCs; the `events.v1`
  package + idempotency_key + event_version fields (event versioning + idempotency in
  the contract); the codegen manifest (`buf.gen.yaml.tmpl`) declaring the Rust
  (tonic+prost → `backend/gen/rust`) and TS (bufbuild/es → `gen/ts`) outputs; the
  `buf.yaml` lint/breaking governance; the AsyncAPI 3.1 event contract (`asyncapi:
  3.1.0` + channels/operations); the layer roots (backend/infra/shared + shared/protos
  + shared/asyncapi); the backend workspace members; the standards-conformance markers
  (Nats-Msg-Id idempotent publish, inbox dedup, append-only event store, Temporal
  activity-only, saga compensation); pin discipline (pins in `Cargo.toml.tmpl`, none
  leaked into a standard); the gated wrapper + dispatch entry; the bin-server axum
  surface + DI wiring.
- **FR-B6-7-003** — **Tier A: aggregation.** The suite MUST re-run each sibling
  per-brick harness — `b6-1`, `b6-2`, `b6-3`, `b6-4`, `b6-5`, `b6-6`, `b6-9`, `b6-10`
  — at its CI level and assert each exits 0, so the promotion suite is a genuine
  superset gate. A sibling absent at run time MUST be a clean SKIP, not a hard FAIL.
- **FR-B6-7-004** — **Tier C: L2 live-codegen (toolchain-gated, SKIP-when-absent).**
  When `buf`, BSR network, and `cargo` are present, the suite MUST: render the plan
  via `overlay.sh`; run `buf generate` and assert the Rust `backend/gen/rust` stubs +
  the TS `gen/ts` descriptors are materialised; run `cargo build`/`cargo test
  --workspace` on the rendered backend. Each leg MUST SKIP gracefully (echo `SKIP …`,
  return 0) when its toolchain or BSR/registry network is absent (the b6-2 T-L2-002 /
  b7-6 T-C02/T-C03 precedent). There is NO Qwik `tsc` leg (event-driven-eu ships no
  frontend surface).
- **FR-B6-7-005** — **Live codegen verification (the b6-2 deferral).** The deferred
  `forge-init-event-driven-eu.sh:166-184` post-render steps (`buf generate`,
  `cargo fetch`) MUST be verified as a working end-to-end path asserted green by
  FR-B6-7-004's Tier C legs, and recorded honestly in
  `.forge/research/b6-7-live-codegen.md` (real tool versions + commands + outputs).

### Snapshot tarball (`FR-B6-7-01x`)

- **FR-B6-7-010** — A deterministic snapshot tarball MUST be built via
  `bin/forge-snapshot.sh build event-driven-eu 1.0.0` and committed at
  `.forge/scaffold-snapshots/event-driven-eu/1.0.0.tar.gz` (the flagship /
  ai-native-rag convention for `forge upgrade` BASE recovery). Its Tier D assertion
  MUST verify presence, size ≤ 2 MB, a valid gzip/tar archive, and round-trip
  extractability. Byte-determinism is provided by `forge-snapshot.sh`'s
  SOURCE_DATE_EPOCH + sorted + uid/gid0 + ustar + gzip-mtime0 path.

## MODIFIED Requirements (the promotion — the FINAL, suite-gated edits)

- **FR-B6-7-020 (MODIFIED schema)** — `.forge/schemas/event-driven-eu/1.0.0.yaml`
  MUST change `stage: candidate → stable` and `scaffoldable: false → true`, and the
  candidate-semantics header block MUST be reworded to describe the promoted state
  (retaining the words `candidate`, `promotion`/`promote`, and `additive` so the
  b6-1 T-018 header-block assertion stays green). This is the SOLE source-of-truth
  promotion edit. It MUST satisfy `validate-foundations.sh::check_versioned_schema_siblings`.
  It MUST be the LAST substantive task, performed only after FR-B6-7-001..005 are green.
- **FR-B6-7-021 (MODIFIED dispatch status)** — `.forge/scaffolding/dispatch-table.yml`
  event-driven-eu `status: candidate → stable` (mirroring the ai-native-rag entry), and
  the refusal-comment block MUST be reworded to describe the promoted state. This
  moves the archetype from the refusing partition into the scaffold matrix.
- **FR-B6-7-022 (MODIFIED sibling guards, lockstep)** — In the SAME commit as
  FR-B6-7-020/021, the candidate-precondition assertions in the sibling harnesses MUST
  be inverted (the b7-6 break-cascade pattern; the function names are kept, the
  assertions + comments inverted, POST-FLIP annotated):
  - `b6-1.test.sh` T-005 (`stage == 'candidate'`) → `stable`; T-006 (`scaffoldable ==
    False`) → `True`; T-L2-001 (init refuses) → init no longer refuses (rc != 3).
  - `b6-2.test.sh` T-006 (wrapper refuses exit 3 while candidate) → wrapper no longer
    refuses (rc != 3); T-009 (schema still candidate) → schema stable/scaffoldable:true;
    T-010 (dispatch status candidate) → dispatch status stable.
- **FR-B6-7-023 (CLI scaffold-matrix fixture)** — `cli/test/e2e/archetype-fixtures/event-driven-eu.yml`
  MUST be added (mirroring `ai-native-rag.yml`): `has_rust_backend: true`,
  `has_flutter_frontend: false`, required_paths/forbidden_paths for the rendered tree.
  Required by t5-1 T-016 (`_test_t51_l1_016_dispatch_xref`) + archetypes-smoke.test.ts
  once dispatch `status != candidate`.
- **FR-B6-7-024 (bundle regen)** — `cli/assets/` MUST be regenerated via
  `npm run bundle` so the CLI's `selectScaffoldableVersion` returns the now-scaffoldable
  1.0.0 and `forge init --archetype event-driven-eu` STOPS refusing. `cli/assets/` is a
  gitignored build artifact rebuilt fresh by CI; the committed change is the schema flip.

### forge-ci line-budget lock-step (`FR-B6-7-03x`)

- **FR-B6-7-030 (MODIFIED, lock-step) — size budget.** Registering `b6-7.test.sh` in
  the `forge-ci.yml` harness array AND adding the `b6-7.test.sh --level 1,2` step to
  the existing `harness-rust` job GROWS the workflow past its current 380-line budget
  (378 lines live-counted 2026-07-12). The budget MUST be bumped 380 → **400** with
  headroom in the SIX coupled places, in the SAME commit that grows the workflow, then
  the four asserting harnesses re-run GREEN:
  1. `g1.test.sh::test_forge_ci_under_size_budget` (`-gt 380` → `-gt 400`).
  2. `c1.test.sh::test_forge_ci_under_size_budget` (`-gt 380` → `-gt 400`).
  3. `t5-1.test.sh` (`_test_t51_l1_017_ci_line_budget`, `-gt 380` → `-gt 400`).
  4. `t5-otel-live-run.test.sh` (`_test_olr_030_ci_matrix_entry`, `-gt 380` → `-gt 400`).
  5. `.forge/specs/forge-ci.md` (NFR-CI-002 / FR-CI-013 "≤ 380" → "≤ 400").
  6. `.forge/standards/global/forge-self-ci.md` ("≤ 380 lines" → "≤ 400 lines").
- **FR-B6-7-030b — NO job-count cascade.** The b6-7 L2 legs reuse the EXISTING
  `harness-rust` job (a second run step), so the job count STAYS at 6 workers. The
  "exactly 6 jobs" assertions (g1 workflow_shape, c1 six_jobs, forge-ci.md FR-CI-001,
  forge-self-ci.md, the `summary` needs/aggregator) are UNCHANGED (ADR-B6-7-005). This
  is the key divergence from b7-6 (which added a NEW job → a 6→7 cascade).

## Non-Functional

- **NFR-B6-7-001** — **Suite GATES the flip.** FR-B6-7-020..023 MUST NOT land before
  FR-B6-7-001..005 are green. A pre-flip held-guard (schema candidate + CLI refuses)
  is present via the siblings and inverted by the flip (Tier D asserts the post-flip
  positive; it is RED before the flip).
- **NFR-B6-7-002** — **No regression.** The full harness suite, `verify.sh`,
  `constitution-linter.sh`, and `validate-foundations.sh` MUST be GREEN after the flip.
  The frozen full-stack 1.0.0/2.0.0 trees, `archetype.schema.json`, the constitution,
  and all standards MUST be byte-unchanged (asserted by `git status`).
- **NFR-B6-7-003** — **CI-safe by default.** The CI-registered level of `b6-7.test.sh`
  (`--level 1` in the `harness` job) MUST pass in the buf-less/cargo-less CI matrix job;
  the live-codegen L2 legs SKIP there and RUN in the `harness-rust` job (`--level 1,2`).
- **NFR-B6-7-004** — **Determinism.** Any rendered-tree artifact (double-render diff,
  snapshot tarball) MUST be byte-stable across runs.
- **NFR-B6-7-005** — **Pin discipline.** No new version pin is invented at planning.
  The live cargo build VERIFIES the existing LIVE pins (`Cargo.toml.tmpl`); any genuine
  resolution failure is a verify-then-pin LIVE fix pinned ONLY in `Cargo.toml.tmpl` and
  recorded.
- **NFR-B6-7-006** — **Honest justification.** The live codegen/build run recorded in
  the research file MUST be a real command + real output + real toolchain versions — no
  fabricated "CI green". Where a leg cannot run (offline BSR), the SKIP is recorded honestly.

## BDD Acceptance Criteria

```gherkin
Feature: event-driven-eu promotion gate (b6-7 — candidate → stable/scaffoldable)

  Scenario: the promotion suite proves the archetype end-to-end before the flip
    Given the event-driven-eu archetype is stage:candidate / scaffoldable:false
    When b6-7.test.sh runs at its CI level
    Then ≥35 tests pass: EventService proto, buf.gen Rust+TS targets, AsyncAPI 3.1,
         scaffold-plan coverage, NATS/eventstore/saga conformance, the committed
         snapshot, and every sibling B.6 harness (b6-1/2/3/4/5/6/9/10) exits 0

  Scenario: the live codegen + build path is green where the toolchain is present
    Given a rendered event-driven-eu tree and buf + BSR + cargo available
    When buf generate (task proto) runs
    Then the Rust backend/gen/rust stubs and the TS gen/ts descriptors are materialised
    And cargo build/test --workspace on the rendered backend succeeds

  Scenario: the live legs SKIP cleanly where buf/cargo are absent (CI harness job)
    Given the CI matrix job (python + node, no buf, no cargo)
    When b6-7.test.sh runs
    Then the live-codegen L2 legs echo SKIP and return 0
    And the Tier A + Tier B + Tier D guards still pass

  Scenario: the flip promotes the archetype only after the suite is green
    Given b6-7.test.sh is green
    When the schema is flipped to stage:stable / scaffoldable:true, the dispatch status
         flipped to stable, the fixture added, and the bundle regenerated
    Then validate-foundations.sh check_versioned_schema_siblings stays green
    And b6-1 T-005/T-006/L2 and b6-2 T-006/T-009/T-010 are inverted in the same commit
    And forge init --archetype event-driven-eu STOPS refusing and renders the tree

  Scenario: no constitution amendment, no standard bump, no other-archetype edit
    Given the promotion change
    Then .forge/constitution.md, all .forge/standards/*, archetype.schema.json,
         and the frozen full-stack 1.0.0/2.0.0 trees are byte-unchanged
    And the full suite + verify.sh + constitution-linter.sh stay green
```

## ADRs (ratified at design)

- **ADR-B6-7-001** — Single change, not a prep/flip split (no constitution-amendment
  window; mirrors ADR-B7-6-001).
- **ADR-B6-7-002** — Suite = aggregate the 8 siblings + net-new e2e (the 8 siblings
  total 111 run_tests; b6-7 adds ~21 net-new + ~3 live + ~3 guards → ≥35).
- **ADR-B6-7-004** — Snapshot tarball = deterministic, committed (ship it; mirrors the
  ai-native-rag / flagship convention).
- **ADR-B6-7-005** — Reuse the existing `harness-rust` CI job for the b6-7 L2 legs (no
  new job → no job-count cascade). The flip is justified by that job green in CI + a
  recorded LIVE run on this buf+cargo host.
- **ADR-B6-7-006** — Flip is the LAST task, only if green.
- **ADR-B6-7-007** — The forge-ci size budget lives in 4 harnesses + 2 docs; bump all
  in lock-step 380 → 400.

## Anti-Hallucination Pass

- "the scaffolder is already built; the flip auto-opens it" — grounded in
  `forge-init-event-driven-eu.sh:17-19,72-73,90-96` (read 2026-07-12).
- The deferred codegen is quoted from `forge-init-event-driven-eu.sh:166-184`; the
  Rust/TS targets from `buf.gen.yaml.tmpl:16-28`.
- The validator invariant is one-directional — asserted from reading
  `validate-foundations.sh:446-454` (LIVE-run PASS on this base).
- buf 1.70.0 + cargo 1.97.0 present — LIVE-probed on this host 2026-07-12.
- The scaffold-matrix fixture requirement — grounded in reading t5-1 T-016
  (`_test_t51_l1_016_dispatch_xref`) + archetypes-smoke.test.ts (the `status !=
  candidate` partition + the dispatch cross-reference).
- `[NEEDS CLARIFICATION]`: none outstanding — Q-A/Q-B/Q-C/Q-D resolved by the b7-6
  precedent + live toolchain facts. No test count, pin, or API fabricated.

---

**Gate**: Specs written. Next → `/forge:design b6-7-harness`.
