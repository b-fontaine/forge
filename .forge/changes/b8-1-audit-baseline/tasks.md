# Tasks: b8-1-audit-baseline

<!-- Status: archived -->
<!-- Schema: default -->
<!-- Audit: B.8.1 (docs/new-archetypes-plan.md §4.2) -->

TDD order is mandatory (Article I): every deliverable clause is driven by a
failing harness assertion first. The harness IS the test; the doc + YAML are
the implementation that turns it GREEN.

## Phase 1: Harness RED (write failing tests first)

- [x] T01 — Scaffold `.forge/scripts/tests/b8-1.test.sh` from the `t5-3-1.test.sh` / `b8-coroot.test.sh` frame: `--level` parsing (default 1), `_helpers.sh` source, `Passed/Failed/Failures` summary, non-zero exit on failure. [Story: FR-B8-1-050]
- [x] T02 — Write L1 assertions RED: doc present+dated, archetype name, component matrix rows + pins (FR-B8-1-010), Postgres-16 delta clause (FR-B8-1-011), backend-placeholder clause (FR-B8-1-012), Temporal-gap clause (FR-B8-1-013), span-tree section with 4 named spans (FR-B8-1-020). [Story: FR-B8-1-051] [P]
- [x] T03 — Write the negative MTBF guard RED: FAIL if a numeric MTBF appears adjacent to "Temporal". [Story: FR-B8-1-033] [P]
- [x] T04 — Write inventory↔source cross-check RED: each span in the YAML must grep-match an instrument site in `backend/.../greet.rs` + `middleware.rs`. [Story: FR-B8-1-032] [P]
- [x] T05 — Run `b8-1.test.sh --level 1` → confirm RED (all target assertions fail; deliverables absent). Capture transcript for evidence.md. [Story: Article I — verify RED]

## Phase 2: Author deliverables to GREEN

- [x] T06 — Create `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml`: 4 spans (Flutter root client, axum `server`, connectrpc handler, `greeter.greet` `internal`) with `otel.kind`, each cross-checked against live source (Article III.4). [Story: FR-B8-1-031, ADR-B8-1-005]
- [x] T07 — Author `docs/B8-BASELINE.md`: header + date + archetype; component/version matrix (re-read every pin from the live files at authoring time, NOT from this spec). [Story: FR-B8-1-001/010, ADR-B8-1-001]
- [x] T08 — Add the Postgres-16-vs-17 delta clause + backend-placeholder clause + consequence (no live latency from compose unmodified). [Story: FR-B8-1-011/012, ADR-B8-1-002]
- [x] T09 — Add the Temporal-gap clause with the B.8.5/DBOS forward-pointer; ensure NO MTBF figure. [Story: FR-B8-1-013, ADR-B8-1-003]
- [x] T10 — Add the demo-005 span-tree section + traceparent propagation-boundary identification. [Story: FR-B8-1-020]
- [x] T11 — Add the re-measurement methodology (stack-up → drive demo-005 → read SigNoz), tool-version-anchored; optional sample capture clearly marked non-normative. [Story: FR-B8-1-030, ADR-B8-1-002]
- [x] T12 — Run `b8-1.test.sh --level 1` → confirm GREEN (all L1 pass). [Story: Article I — verify GREEN]
- [x] T13 — Verify the MTBF guard RED-fires: temporarily insert a fake `MTBF: 99h` near "Temporal", re-run, confirm FAIL, remove it, confirm GREEN. [Story: FR-B8-1-033 — guard proof]

## Phase 3: Integration

- [x] T14 — Implement L2 opt-in block (`FORGE_B8_1_DOCKER=1`, skip-pass absent): dev-stack-up → drive demo-005 → SigNoz non-empty trace, span superset of inventory; placeholder-backend truncation handled per BDD scenario. [Story: FR-B8-1-060]
- [x] T15 — Register `b8-1.test.sh` in `.github/workflows/forge-ci.yml::harness` matrix; reclaim lines via 3-comment compression; assert ≤ 300 lines. [Story: FR-B8-1-080, ADR-B8-1-006]
- [x] T16 — Add CHANGELOG `[Unreleased]` entry citing `b8-1-audit-baseline` + B.8.1. [Story: FR-B8-1-090]
- [x] T17 — Create consolidated spec `.forge/specs/b8-baseline.md` for the `FR-B8-1-*` namespace. [Story: FR-B8-1-100] [P]

## Phase 4: Quality & Verification

- [x] T18 — `git diff --name-only` scope check: zero `.forge/templates/**`, `.forge/standards/**`, `.forge/schemas/**` touched. [Story: NFR-B8-1-002]
- [x] T19 — Determinism: re-run authoring-adjacent generation twice, confirm byte-stable inventory YAML; no timestamps. [Story: NFR-B8-1-003] [P]
- [x] T20 — Regression: `a7.test.sh` GREEN (no owned-path touched). [Story: NFR-B8-1-004] [P]
- [x] T21 — Perf: `time b8-1.test.sh --level 1` ≤ 5 s, zero network/Docker. [Story: NFR-B8-1-001] [P]
- [x] T22 — Gates: `verify.sh` 0 FAIL (Open Questions gate passes — all 3 answered) + `constitution-linter.sh` OVERALL PASS. [Story: Article V gate]
- [x] T23 — Independent reviewer pass (separate context, T5.2 discipline): DONE. Round 1 → CHANGES REQUIRED (1 blocker: §5 phantom-span misattribution + 3 non-blocking); all fixed; round 2 → **APPROVE**. Reviewer re-derived all pins/spans/gates from live files (no transcript trust). [Story: Author/Reviewer separation]
- [x] T24 — Populate `evidence.md` with RED→GREEN transcripts, guard-fire proof (T13), scope-check, gate outputs. [Story: Article V audit trail]

## Constitutional Compliance Gate (per task)

All tasks reviewed: none requires violating TDD (Phase 1 precedes Phase 2),
none bypasses specs (every task carries an FR/NFR/ADR story), none touches a
runtime architecture article (no Flutter/Rust code authored). No
`[TASK VIOLATION]` raised. Gate PASS.
