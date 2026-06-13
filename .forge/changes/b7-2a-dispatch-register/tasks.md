# Tasks: b7-2a-dispatch-register

<!-- Status: archived -->
<!-- Schema: default -->
<!-- Audit: B.7.2 (docs/new-archetypes-plan.md §6.2 — ai-native-rag dispatch registration slice) -->

TDD-ordered (Article I). Deliverable: one dispatch entry + one refusing wrapper +
test updates. Harness authored FIRST and must fail before the entry/wrapper exist.

## Phase 1: RED — failing harness

- [x] **T1.1** Author `.forge/scripts/tests/b7-2a.test.sh` (sources `_helpers.sh`).
  L1: dispatch entry `ai-native-rag` present & well-formed (name/scaffolder/
  description/signals/since/status via the python dispatch parse); wrapper
  `bin/forge-init-ai-native-rag.sh` exists + executable + `#!/usr/bin/env bash`;
  direct invocation (in a tmpdir) → exit 3 + structured `[REFUSAL: ...]` stderr +
  **zero files written**. L2 (opt-in `FORGE_B7_2A_LIVE` + `cli/dist/index.js`,
  skip-pass otherwise): `forge init testproj --archetype ai-native-rag --org
  com.example.test` → exit 3. [Story: FR-B7-2A-001/002/003/006]
- [x] **T1.2** Run `bash .forge/scripts/tests/b7-2a.test.sh --level 1` → **verify
  RED** (no entry, no wrapper). [Gate: Article I]

## Phase 2: GREEN

- [x] **T2.1** Append the `ai-native-rag` entry to
  `.forge/scaffolding/dispatch-table.yml`: `name`, `scaffolder:
  bin/forge-init-ai-native-rag.sh`, `description`, `signals: []`, `since: "0.5.0"`
  (ADR-B7-2A-004), `status: candidate` (ADR-B7-2A-005). [Story: FR-B7-2A-001]
- [x] **T2.2** Write `bin/forge-init-ai-native-rag.sh` — executable bash refusing
  wrapper: structured `[REFUSAL: ai-native-rag: not-yet-scaffoldable ...]` to
  stderr, `exit 3`, zero filesystem writes; ABI-shaped arg tolerance
  (ADR-B7-2A-003). `chmod +x`. [Story: FR-B7-2A-002]
- [x] **T2.3** Run `b7-2a.test.sh --level 1` → **verify GREEN**. [Gate: Article I]

## Phase 3: Integration

- [x] **T3.1** Flip `.forge/scripts/tests/b7-1.test.sh`
  `_test_b71_l2_001_init_refuses` to assert **exit 3** (+ docstring: now
  registered, refusal is the schema-version layer). [Story: FR-B7-2A-005]
- [x] **T3.2** Run `b5.test.sh` → `test_dispatch_scaffolders_exist` GREEN (the
  wrapper path resolves). [Story: FR-B7-2A-004]
- [x] **T3.3** (build available) `npm run bundle` then `FORGE_B7_2A_LIVE=1
  b7-2a.test.sh --level 2` + `FORGE_B7_1_LIVE=1 b7-1.test.sh --level 1,2` → CLI
  exit 3 live. If no build: rely on L2 skip-pass + document. [Story: FR-B7-2A-003]
- [x] **T3.4** Register `b7-2a.test.sh` in `.github/workflows/forge-ci.yml`
  (after `b7-1.test.sh`). [Story: FR-B7-2A-006]
- [x] **T3.5** (post-review Q-003) `cli/src/cli.ts` `--archetype` help text +=
  `ai-native-rag`; regen `cli/test/e2e/__snapshots__/help/init.snap.txt` via
  `npx vitest run -u`. [Story: FR-B7-2A-007]
- [x] **T3.6** (post-review Q-003) `cli/test/e2e/archetypes-smoke.test.ts`:
  partition `status === "candidate"` out of the fixture/scaffold matrix; add a
  refusal test asserting candidates exit 3 + no scaffold. `cd cli && npm test` →
  87 passed / 1 skipped. [Story: FR-B7-2A-007]

## Phase 4: Quality

- [x] **T4.1** `verify.sh` + `constitution-linter.sh` → no regression. [NFR-B7-2A-003]
- [x] **T4.2** `git diff --name-only` → additive: new wrapper + harness + change
  artifacts; edits limited to dispatch-table (append), b7-1 L2, CI matrix. Schema
  unchanged (still candidate/scaffoldable:false). [NFR-B7-2A-001]
- [x] **T4.3** REFACTOR; re-run full b7-2a + b7-1 harness → GREEN.
- [x] **T4.4** `/forge:review b7-2a-dispatch-register` — independent reviewer
  **APPROVE** (2026-06-12, after one fix iteration on the CRITICAL/HIGH CLI-e2e
  regression) + **maintainer ratification** of ADR-B7-2A-001..005 + Q-003
  (2026-06-12). Article V satisfied (reviewer was a separate context). Archived.

## Constitution Gate (per task)
- TDD: harness RED (T1.2) before entry/wrapper GREEN (T2.3). ✓
- Additive; every task cites its FR/NFR/ADR. ✓ No [TASK VIOLATION].
