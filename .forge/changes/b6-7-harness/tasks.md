# Tasks: b6-7-harness

<!-- Planned: 2026-07-12 -->
<!-- TDD-ordered (Article I). Tests = b6-7.test.sh assertions (RED before the flip, GREEN after). -->
<!-- [REQUIRES-TOOLS: ...] flags the legs needing buf/BSR/cargo. -->
<!-- The schema flip is the FINAL, suite-gated task (ADR-B6-7-006). -->

## Phase 0: Suite skeleton + sibling census (RED)

- [ ] T-001 Create `.forge/scripts/tests/b6-7.test.sh` skeleton (set -uo pipefail,
      `--level` parse, path vars, `_helpers.sh` source, `run_test`/`print_summary`,
      counters) — mirror `b6-2.test.sh`/`b7-6.test.sh`. CI registration DEFERRED to
      Phase 4. [Story: FR-B6-7-001]
- [ ] T-002 Re-confirm the sibling `run_test` census live; record in
      `.forge/research/b6-7-live-codegen.md`. [Story: ADR-B6-7-002]
- [ ] T-003 **Verify RED**: run `b6-7.test.sh --level 1` → MUST fail (Tier D post-flip
      guard + snapshot absent). Record the failing list. [Story: Article I]

## Phase 1: Aggregation tier (Tier A) — GREEN

- [ ] T-010 GREEN: one `run_test` per sibling (b6-1/2/3/4/5/6/9/10) at its CI level,
      assert exit 0; absent sibling → clean SKIP. [Story: FR-B6-7-003]

## Phase 2: Net-new L1 e2e structural (Tier B) — GREEN

- [ ] T-020 GREEN: proto (EventService Publish + ReadStream + events.v1 versioning/
      idempotency); codegen manifest (tonic+prost → backend/gen/rust, bufbuild/es →
      gen/ts); buf.yaml governance. [Story: FR-B6-7-002]
- [ ] T-021 GREEN: AsyncAPI 3.1 contract; layer roots; workspace members;
      scaffold-plan↔tree coverage. [Story: FR-B6-7-002]
- [ ] T-022 GREEN: standards conformance (Nats-Msg-Id / inbox / append-only /
      activity-only / compensation / event_version); pin discipline; wrapper +
      dispatch + bin-server axum + wiring. [Story: FR-B6-7-002]
- [ ] T-023 GREEN: `b6-7.test.sh --level 1` (Tier A + B) all PASS buf-less/cargo-less. [Story: NFR-B6-7-003]

## Phase 3: L2 live-codegen (Tier C) — the real e2e [REQUIRES-TOOLS]

- [ ] T-030 GREEN (L1 wiring): Tier C legs SKIP gracefully when buf/cargo absent. [Story: FR-B6-7-004]
- [ ] T-031 [REQUIRES-TOOLS: buf + BSR] GREEN: render via overlay.sh; `buf generate`;
      assert Rust `backend/gen/rust` + TS `gen/ts` materialised. Record LIVE run. [Story: FR-B6-7-004/005]
- [ ] T-032 [REQUIRES-TOOLS: cargo] GREEN: `cargo build` + `cargo test --workspace` on
      the rendered backend; offline → SKIP; VERIFY LIVE pins resolve+build. [Story: FR-B6-7-004/005/NFR-B6-7-005]
- [ ] T-033 **Record the live run honestly** in `.forge/research/b6-7-live-codegen.md`
      (real buf/cargo versions + commands + outputs). NO fabricated CI-green. [Story: NFR-B6-7-006]

## Phase 4: THE FLIP (FINAL, suite-gated — only after Phases 1-3 green)

- [ ] T-040 **Pre-flip gate**: full suite + `verify.sh` + `constitution-linter.sh` +
      `validate-foundations.sh` GREEN; Tier D held-guard confirms schema still
      candidate + CLI still refuses (RED expected). [Story: NFR-B6-7-001/002]
- [ ] T-041 **MODIFIED (schema)**: `event-driven-eu/1.0.0.yaml` stage candidate→stable,
      scaffoldable false→true; reword header (keep candidate/promotion/additive words).
      Confirm validate-foundations stays green. [Story: FR-B6-7-020]
- [ ] T-042 **MODIFIED (dispatch, SAME commit)**: dispatch-table event-driven-eu
      status candidate→stable + reword comment. [Story: FR-B6-7-021]
- [ ] T-043 **MODIFIED (lockstep inversions, SAME commit)**: b6-1 T-005/006/L2; b6-2
      T-006/009/010. Run each → GREEN. [Story: FR-B6-7-022]
- [ ] T-044 **NEW fixture (SAME commit)**: `cli/test/e2e/archetype-fixtures/event-driven-eu.yml`
      (mirror ai-native-rag.yml). Run t5-1 + archetypes-smoke → GREEN. [Story: FR-B6-7-023]
- [ ] T-045 **Bundle regen**: `npm run bundle`; confirm CLI stops refusing. [Story: FR-B6-7-024]
- [ ] T-046 **Snapshot**: `bin/forge-snapshot.sh build event-driven-eu 1.0.0`; commit
      the tarball. Tier D snapshot test → GREEN. [Story: FR-B6-7-010]
- [ ] T-047 Register `b6-7.test.sh --level 1` in the `forge-ci.yml` harness array +
      add `b6-7.test.sh --level 1,2` step to the existing `harness-rust` job. [Story: FR-B6-7-001 / ADR-B6-7-005]
- [ ] T-048 **forge-ci size-budget lock-step (SAME commit as T-047)**: bump 380 → 400
      in g1/c1/t5-1/t5-otel-live-run + forge-ci.md + forge-self-ci.md. Re-run the four
      asserting harnesses → GREEN. NO job-count edit. [Story: FR-B6-7-030 / ADR-B6-7-007]

## Phase 5: Gate + archive

- [ ] T-050 **Post-flip gate**: full harness suite + `verify.sh` +
      `constitution-linter.sh` + `validate-foundations.sh` OVERALL PASS; frozen
      full-stack + constitution + standards + archetype.schema.json byte-unchanged. [Story: NFR-B6-7-002]
- [ ] T-051 **Independent review** (separate reasoning pass): flip is last +
      suite-gated, no fabricated CI-green, no standard/constitution/other-archetype
      edit, ≥35 tests real, live pins verified live. [Story: NFR-B6-7-006]
- [ ] T-052 Flip `.forge.yaml` → archived (full timeline); consolidate ADDED/MODIFIED
      reqs into `.forge/specs/event-driven-eu.md` (append B.6.7 block, preserve prior);
      update `docs/new-archetypes-plan.md` §0.13 B.6.7 row + §11 T7. [Story: archive]

## Constitutional Compliance Gate (per phase)

No task requires violating TDD (every wiring/flip task is RED-first or suite-gated),
bypassing specs (all cite FR/ADR), or amending the constitution (b6-7 touches no
Article). No `[TASK VIOLATION]`. All Q-A/Q-B/Q-C/Q-D resolved at design.

---

**Gate**: Tasks generated. Next → `/forge:implement b6-7-harness`.
