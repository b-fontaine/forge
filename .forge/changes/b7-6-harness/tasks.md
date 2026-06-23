# Tasks: b7-6-harness

<!-- Planned: 2026-06-23 -->
<!-- TDD-ordered (Article I). Tests = b7-6.test.sh assertions (RED before the wiring/flip, -->
<!-- GREEN after). [REQUIRES-TOOLS: ...] flags the legs needing buf/BSR/cargo/node. -->
<!-- The schema flip is the FINAL, suite-gated task (ADR-B7-6-006). Status: PLANNED (no code yet). -->
<!-- BLOCKED ON: Q-A (single vs split) + Q-B (where the live legs run / how the flip is justified) -->
<!-- — resolve at the proposal/design gate before Phase 4 (the flip) hardens. -->

## Phase 0: Suite skeleton + sibling census (RED)

- [ ] T-001 Create `.forge/scripts/tests/b7-6.test.sh` skeleton (set -uo pipefail,
      `--level` parse, path vars, `_helpers.sh` source, `run_test`/`print_summary`,
      counters) — mirror `b7-2.test.sh`/`b7-10.test.sh`. **CI registration DEFERRED
      to Phase 4** (a RED suite on main breaks CI). [Story: FR-B7-6-001]
- [ ] T-002 Re-confirm the sibling `run_test` census live (`grep -c '^\s*run_test'`
      per harness) so the ≥35 figure stays grounded; record in
      `.forge/research/b7-6-live-codegen.md`. [Story: ADR-B7-6-002 / NFR-B7-6-005]
- [ ] T-003 **Verify RED**: run `b7-6.test.sh --level 1` → MUST fail (Tier B/C/D
      assertions absent). Record the failing list. [Story: Article I]

## Phase 1: Aggregation tier (Tier A) — GREEN

- [ ] T-010 GREEN: one `run_test` per sibling harness (b7-1, b7-2, b7-2a, b7-3,
      b7-5, b7-9, b7-10, b7-pythia) invoking it at its CI level, asserting exit 0;
      absent sibling → clean SKIP (not FAIL). [Story: FR-B7-6-003]
- [ ] T-011 GREEN: confirm Tier A passes against the current (pre-flip) tree — the
      siblings are already green, so Tier A is GREEN immediately; this is the
      superset-gate baseline. [Story: FR-B7-6-003 / NFR-B7-6-002]

## Phase 2: Net-new L1 e2e structural (Tier B) — RED→GREEN

- [ ] T-020 RED: Tier B assertions fail where the assembled view isn't yet checked
      (codegen-manifest targets, Connect-handler seam). [Story: FR-B7-6-002/005]
- [ ] T-021 GREEN: proto coexistence (unary `Query` + streaming `QueryStream`/
      `QueryChunk`, single `SourceChunk`); codegen manifest declares Rust
      (tonic+prost) + TS (bufbuild/es) outputs to the real target dirs
      (`buf.gen.yaml.tmpl`). [Story: FR-B7-6-002]
- [ ] T-022 GREEN: **Connect-handler registration wiring** — edit
      `backend/bin-server/src/main.rs.tmpl` to register the `rag.v1.RagService`
      handler via the `grpc-api` `transport_connect` adapter under `/connect`
      (the seam at `:38-39`), guarded so it compiles once codegen runs. Assert the
      registration marker at L1. [Story: FR-B7-6-005]
- [ ] T-023 GREEN: scaffold-plan↔tree full coverage (every `source:` resolves; no
      orphan `.tmpl`); pins only in `Cargo.toml.tmpl` + LIVE pins present;
      standards-conformance markers (RRF/HNSW, prompt-audit/redact_pii/fallback,
      tool_router/schemars/StreamableHttp); gated wrapper + dispatch entry exist;
      XI.5/IX.6/XI.6 markers across the assembled backend. [Story: FR-B7-6-002]
- [ ] T-024 GREEN: `b7-6.test.sh --level 1` (Tier A + B + held-guard) all PASS in
      a buf-less/cargo-less env (== CI). [Story: NFR-B7-6-003]

## Phase 3: L2 live-codegen (Tier C) — the real e2e [REQUIRES-TOOLS]

- [ ] T-030 GREEN (L1 wiring): Tier C legs SKIP gracefully (echo `SKIP`, return 0)
      when buf/BSR/cargo/tsc absent — assert the SKIP path on this dev host
      (buf absent). [Story: FR-B7-6-004 / b7-10 precedent]
- [ ] T-031 [REQUIRES-TOOLS: buf + BSR network] GREEN: render via `overlay.sh`,
      run `buf generate` (`task proto`); assert Rust `grpc-api` stubs +
      TS `generated/connect/rag_pb` materialised. Run on a buf-equipped host;
      record command+output+versions in the research file. [Story: FR-B7-6-004/005]
- [ ] T-032 [REQUIRES-TOOLS: cargo] GREEN: `cargo build` + `cargo test --workspace`
      on the rendered+generated tree (Connect handler compiles against the stubs);
      offline-detect → SKIP (b7-10 T-L2-002). VERIFY the LIVE pins resolve+build;
      any genuine failure = verify-then-pin LIVE fix in `Cargo.toml.tmpl` ONLY,
      recorded. [Story: FR-B7-6-004 / NFR-B7-6-005]
- [ ] T-033 [REQUIRES-TOOLS: node + tsc] GREEN: Qwik `tsc --noEmit`/build clean on
      the rendered web-public surface (`rag_pb` now resolves). SKIP if absent.
      [Story: FR-B7-6-004]
- [ ] T-034 (Q-D) GREEN: generate the deterministic `SOURCE_DATE_EPOCH` snapshot
      tarball of the rendered tree + assert byte-stable re-tar — OR, if Q-D
      resolves "not now", drop FR-B7-6-010 and record. [Story: FR-B7-6-010 / NFR-B7-6-004]
- [ ] T-035 **Record the live run honestly** in `.forge/research/b7-6-live-codegen.md`
      (real `buf`/`cargo`/`node` versions + commands + outputs) — the flip's
      justification (NFR-B7-6-006). NO fabricated CI-green. [Story: ADR-B7-6-005 / Q-B]

## Phase 4: THE FLIP (FINAL, suite-gated — only after Phases 1-3 green)

> Mirrors b8-14 prep→flip ordering, collapsed into one change. Do NOT start until
> the suite is green AND Q-A (single vs split) + Q-B (live-run justification) are
> resolved by the maintainer.

- [ ] T-040 **Pre-flip gate**: full suite + `verify.sh` + `constitution-linter.sh`
      + `validate-foundations.sh` GREEN; Tier D held-guard confirms schema still
      candidate + CLI still refuses. [Story: NFR-B7-6-001/002]
- [ ] T-041 **MODIFIED (the promotion)**: `.forge/schemas/ai-native-rag/1.0.0.yaml`
      `stage: candidate → stable`, `scaffoldable: false → true`; reword the
      candidate-semantics header (`:10-18`). Confirm `validate-foundations.sh
      check_versioned_schema_siblings` stays green (candidate clause gone; 1.0.0
      clears the stable floor). [Story: FR-B7-6-020]
- [ ] T-042 **MODIFIED (lockstep inversions, SAME commit as T-041)**:
      `b7-1.test.sh` T-005 (→ stable) / T-006 (→ True) / L2 (→ no exit 3);
      `b7-2.test.sh` T-006 (wrapper no longer refuses — positively require the
      promoted state); `b7-2a.test.sh` L2 (→ no exit 3 / renders). Run each → GREEN.
      [Story: FR-B7-6-021]
- [ ] T-043 Invert Tier D held-guard → post-flip positive (schema stable/
      scaffoldable:true + CLI renders + validator green). [Story: FR-B7-6-021 / NFR-B7-6-001]
- [ ] T-044 **Bundle regen**: `npm run bundle` (regen gitignored `cli/assets/`);
      confirm `forge init --archetype ai-native-rag` STOPS refusing and renders
      (live CLI). [Story: FR-B7-6-022 / ADR-B7-6-003]
- [ ] T-045 Register `b7-6.test.sh` in `.github/workflows/forge-ci.yml` harness
      array (CI level = L1 + aggregation + post-flip guard; L2 SKIPs there). If
      Q-B=option b, ALSO add the `harness-rust` buf+cargo+node job running
      `--level 1,2`. [Story: FR-B7-6-001 / ADR-B7-6-005]
- [ ] T-046 **forge-ci size-budget lock-step (4 places, SAME commit as T-045).**
      Registering the harness (+ any new job) pushes `forge-ci.yml` past its budget
      (300 today, live-counted). RE-READ the LIVE budget at implement (may be 340
      from a merged b7-7 — do NOT assume 300) and bump from current in ALL FOUR:
      `g1.test.sh:343`, `c1.test.sh:738`, `forge-ci.md:298` (FR-CI-013),
      `forge-self-ci.md:43` — to b7-6's final line count. Re-run `g1.test.sh` +
      `c1.test.sh` → GREEN. [Story: FR-B7-6-030 / ADR-B7-6-007]
- [ ] T-047 **Refresh `forge-self-ci.md` staleness**: line 16 "five jobs" → "six"
      (harness/gates/cli/lint/example/summary); line 43 budget → b7-6's number
      (narrative refresh — no SemVer frontmatter, no REVIEW.md entry). Confirm no
      harness pins its content (j7/standards-yaml don't cover it). [Story: FR-B7-6-031]

## Phase 5: Gate + archive

- [ ] T-050 **Post-flip gate**: full 50+-harness suite + `verify.sh` +
      `constitution-linter.sh` + `validate-foundations.sh` OVERALL PASS; frozen
      full-stack 1.0.0/2.0.0 + constitution + standards + `archetype.schema.json`
      byte-unchanged (`git status` + b8-2/t4 coupling green). [Story: NFR-B7-6-002]
- [ ] T-051 **Independent review** (separate agent/context — Tribune): re-execute
      the live legs (or re-verify the honest run record), confirm the flip is last
      + suite-gated, no fabricated CI-green, no standard/constitution/other-archetype
      edit, ≥35 tests real. APPROVE required. [Story: NFR-B7-6-006]
- [ ] T-052 Flip `.forge.yaml` → implemented (timeline); post-flip gate re-run.
- [ ] T-053 Archive: consolidate ADDED/MODIFIED reqs into `.forge/specs/ai-native-rag.md`
      (append B.7.6 block, preserve prior B.7 blocks); status → archived;
      `archived_to: [.forge/specs/ai-native-rag.md]`; update plan §0.12 table row 9
      (b7-6 Done, archetype scaffoldable) + roadmap T7; memory update.

## Constitutional Compliance Gate (per phase)

No task requires violating TDD (every wiring/flip task is RED-first or
suite-gated), bypassing specs (all tasks cite FR/ADR), or amending the constitution
(b7-6 touches no Article — the key difference from B.8.14). No `[TASK VIOLATION]`.
**Open**: Q-A (single vs split) + Q-B (live-run justification / CI buf job) +
Q-D (snapshot) — `[NEEDS CLARIFICATION]`, resolve at the proposal/design gate
BEFORE Phase 4 (the flip).

---

**Gate**: Tasks generated. Review `tasks.md`. Next: `/forge:implement b7-6-harness`
(after the maintainer resolves Q-A + Q-B; Phases 0-3 are unblocked, Phase 4 the
flip is gated on Q-B + a green suite).
