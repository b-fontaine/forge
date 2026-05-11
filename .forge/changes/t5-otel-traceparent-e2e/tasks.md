# Tasks: t5-otel-traceparent-e2e
<!-- Status: planned -->
<!-- Schema: full-stack-monorepo -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-T5-TPE-XXX]` (Article V.1) on every
  task, enforced by `f4-linter-extension`.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/t5-otel-traceparent-e2e.test.sh` (and
  `verify.sh` / `constitution-linter.sh` where relevant) and
  confirms expected counter movement.
- ADRs from `design.md` (ADR-T5-TPE-001..006) are honored
  verbatim ; deviations require a new ADR.
- Phase C is **harness + spec, NOT live-run** — see Phase D —
  DEFERRED section at the bottom for what this change explicitly
  does not do.

---

## Phase 1 — Foundation : RED harness with all stubs failing

Goal : `t5-otel-traceparent-e2e.test.sh` exists with **7 L1 stubs
all FAIL + 2 L2 stubs all FAIL/xfail**, full RED state captured.

### T-PHC — Harness skeleton (RED for the whole change)

- [ ] **T-PHC-001** : Create
      `.forge/scripts/tests/t5-otel-traceparent-e2e.test.sh` with
      bash header (`#!/usr/bin/env bash`, `set -uo pipefail`,
      source `_helpers.sh`), PASS/FAIL counters reset, `--level 1,2`
      parsing, `print_summary` close-out. Mirror the
      `t5-otel-app.test.sh` layout per ADR-T5-TPE-004.
      [Story: FR-T5-TPE-040]
- [ ] **T-PHC-002** : Add **7 L1 test stubs** returning
      `_not_implemented` per the FR↔test mapping table in
      `design.md` ADR-T5-TPE-004 :
      - `_test_tpe_001_feature_file_exists` (FR-T5-TPE-001 /
        FR-T5-TPE-010).
      - `_test_tpe_002_three_scenarios` (FR-T5-TPE-002).
      - `_test_tpe_003_gherkin_shape` (FR-T5-TPE-003).
      - `_test_tpe_004_symbol_forward_pointer` (FR-T5-TPE-007).
      - `_test_tpe_010_kong_no_traceparent_strip`
        (FR-T5-TPE-022 / FR-T5-TPE-023 / FR-T5-TPE-045).
      - `_test_tpe_011_kong_contract_comment` (FR-T5-TPE-021 /
        FR-T5-TPE-046).
      - `_test_tpe_020_ci_matrix_entry` (FR-T5-TPE-047 /
        FR-T5-TPE-080).
      [Story: FR-T5-TPE-040..047]
- [ ] **T-PHC-003** [P] : Add **2 L2 test stubs** :
      - `_test_tpe_l2_001_cargo_build_inherited` (gate by
        `_skip_if_no_toolchain cargo`).
      - `_test_tpe_l2_002_flutter_analyze_inherited` (gracefully
        xfail per ADR-T5-TPE-006 — Q-004 cascade).
      [Story: FR-T5-TPE-060..062]
- [ ] **T-PHC-004** [P] : Register
      `t5-otel-traceparent-e2e.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `t5-otel-app.test.sh` with `--level 1`.
      Step name matches the harness filename for shell-grep
      auditability.
      [Story: FR-T5-TPE-047 / FR-T5-TPE-080]
- [ ] **T-PHC-005** : RED gate confirmed —
      `bash .forge/scripts/tests/t5-otel-traceparent-e2e.test.sh > /tmp/t5-otel-tpe-red.log 2>&1` ;
      `bash exit: 1` ; `Failed: 7 / Passed: 0` (L1 only). All
      stubs report `not implemented (RED witness)`.
      [Story: FR-T5-TPE-040]

**Phase 1 exit gate** : `t5-otel-traceparent-e2e.test.sh` exits 1
with `FAIL == 7` on `--level 1` ; `forge-ci.yml` matrix updated ;
no production artefact shipped yet ; constitution-linter.sh OVERALL
PASS.

---

## Phase 2 — BDD feature file (FR-T5-TPE-001..010)

Goal : `traceparent_e2e.feature` ships with three Gherkin scenarios
and four L1 BDD-shape tests flip GREEN
(`_test_tpe_001..004`).

### T-BDD — Feature file (FR-T5-TPE-001..010)

- [ ] **T-BDD-001** : RED witness — flip
      `_test_tpe_001_feature_file_exists` to its real assertion :
      file exists at
      `examples/forge-fsm-example/test/features/traceparent_e2e.feature`
      AND the first 5 lines mention the audit header
      `<!-- Audit: T.5 (t5-otel-traceparent-e2e) ... -->`.
      Capture `/tmp/t5-otel-tpe-red-bdd.log`.
      [Story: FR-T5-TPE-001 / FR-T5-TPE-010]
- [ ] **T-BDD-002** : RED witness —
      `_test_tpe_002_three_scenarios` asserts exactly three
      `^  Scenario:` lines AND each scenario name contains one of
      `Direct`, `Kong`, `Sampled-off` (case-insensitive).
      [Story: FR-T5-TPE-002]
- [ ] **T-BDD-003** : RED witness — `_test_tpe_003_gherkin_shape`
      asserts the feature file declares `Feature:` AND each
      `Scenario:` block contains at least one `Given`, one `When`,
      one `Then`. [Story: FR-T5-TPE-003]
- [ ] **T-BDD-004** : RED witness —
      `_test_tpe_004_symbol_forward_pointer` asserts at least one
      of `HeaderMapExtractor`, `MetadataMapCarrier`,
      `HeaderMapCarrier` appears in the feature file body.
      [Story: FR-T5-TPE-007]
- [ ] **T-BDD-005** : Create
      `examples/forge-fsm-example/test/features/traceparent_e2e.feature`
      with the verbatim Gherkin from `specs.md` § BDD Acceptance
      Criteria. Header comment includes :
      ```
      <!-- Audit: T.5 (t5-otel-traceparent-e2e) — Phase C E2E traceparent through Kong gateway -->
      <!-- Complements demo_005_traceparent.feature (Phase B, FR-T5-OTA-031) -->
      ```
      Three scenarios : Direct path / Kong path / Sampled-off
      path. Body references `HeaderMapExtractor` and
      `MetadataMapCarrier` from Phase B's
      `crates/infrastructure/src/telemetry/propagation.rs`.
      Trailing `TODO(#TBD-OTEL-PHASE-D):` comment per
      FR-T5-TPE-008.
      [Story: FR-T5-TPE-001..010 / FR-T5-TPE-007]
- [ ] **T-BDD-006** : Run
      `t5-otel-traceparent-e2e.test.sh --level 1` ; expect
      `_test_tpe_001..004` flip GREEN (4 of 7).
      [Story: FR-T5-TPE-001..010]

**Phase 2 exit gate** : `t5-otel-traceparent-e2e.test.sh --level 1` :
`Passed: 4 / Failed: 3` (Kong + CI tests still RED).
`constitution-linter.sh` OVERALL PASS.

---

## Phase 3 — Kong gateway preservation + CI registration

Goal : `kong.yml.example` carries the W3C trace context
preservation comment ; the CI matrix entry runs the harness ; the
last 3 L1 tests flip GREEN.

### T-KONG — Gateway preservation (FR-T5-TPE-020..025)

- [ ] **T-KONG-001** : Read
      `examples/forge-fsm-example/infra/kong/kong.yml.example`
      and verify the current state per FR-T5-TPE-020 : no
      `request_transformer` plugin, no `headers.traceparent`
      directive. If the file shows an unexpected header-strip
      directive, raise as a `[NEEDS CLARIFICATION:]` block in
      this task and STOP. (Expected outcome 2026-05-11 : file is
      clean.) [Story: FR-T5-TPE-020]
- [ ] **T-KONG-002** : RED witness —
      `_test_tpe_010_kong_no_traceparent_strip` asserts
      `kong.yml.example` :
      - Has no `remove.headers` line mentioning `traceparent` or
        `tracestate`.
      - Has no `headers.traceparent: false` directive.
      - Has no `disable.headers.traceparent` directive.
      [Story: FR-T5-TPE-022 / FR-T5-TPE-023 / FR-T5-TPE-045]
- [ ] **T-KONG-003** : RED witness —
      `_test_tpe_011_kong_contract_comment` asserts
      `kong.yml.example` contains the literal anchor
      `W3C trace context preservation`.
      [Story: FR-T5-TPE-021 / FR-T5-TPE-046]
- [ ] **T-KONG-004** : Edit
      `examples/forge-fsm-example/infra/kong/kong.yml.example`
      by adding the W3C trace context preservation comment block
      per ADR-T5-TPE-003 verbatim. Placement : between the
      `services:` block end and the legacy commented-out `plugins:`
      block at the bottom (or above the legacy `plugins:` comment,
      whichever reads cleaner). NO change to any service/route
      structure (NFR-T5-TPE-004 — comment-only).
      [Story: FR-T5-TPE-021 / FR-T5-TPE-024 / FR-T5-TPE-025]
- [ ] **T-KONG-005** : Run
      `t5-otel-traceparent-e2e.test.sh --level 1` ; expect
      `_test_tpe_010` and `_test_tpe_011` flip GREEN
      (cumulative 6/7). [Story: FR-T5-TPE-020..025]

### T-CI — CI matrix entry (FR-T5-TPE-047 / FR-T5-TPE-080)

- [ ] **T-CI-001** : RED witness —
      `_test_tpe_020_ci_matrix_entry` asserts
      `.github/workflows/forge-ci.yml` mentions
      `t5-otel-traceparent-e2e.test.sh` with `--level 1` AND the
      step appears immediately after the
      `t5-otel-app.test.sh` step (asserted by checking the line
      order). [Story: FR-T5-TPE-047 / FR-T5-TPE-080]
- [ ] **T-CI-002** : Add the matrix entry to
      `.github/workflows/forge-ci.yml` `harness` job
      immediately after `t5-otel-app.test.sh` :
      ```yaml
      - name: t5-otel-traceparent-e2e.test.sh
        # T.5 Phase C E2E traceparent harness (7 L1 + 2 L2). Phase C
        # is harness + spec ; live-run leg deferred to Phase D — see
        # .forge/changes/t5-otel-traceparent-e2e/tasks.md.
        run: bash .forge/scripts/tests/t5-otel-traceparent-e2e.test.sh --level 1
      ```
      [Story: FR-T5-TPE-047 / FR-T5-TPE-080]
- [ ] **T-CI-003** : Run
      `t5-otel-traceparent-e2e.test.sh --level 1` ; expect
      `_test_tpe_020` flip GREEN (cumulative 7/7 GREEN).
      [Story: FR-T5-TPE-047 / FR-T5-TPE-080]

**Phase 3 exit gate** : `t5-otel-traceparent-e2e.test.sh --level 1`
7/7 GREEN, 0 FAIL, ≤ 3 s wall-clock (NFR-T5-TPE-001).
`constitution-linter.sh` OVERALL PASS.

---

## Phase 4 — Quality : docs + L2 inheritance + review

### T-L2 — L2 inheritance from Phase B (FR-T5-TPE-060..062)

- [ ] **T-L2-001** : Implement
      `_test_tpe_l2_001_cargo_build_inherited` :
      `cd $BACKEND && cargo build -p bin-server --locked` ; expect
      exit 0. Skip cleanly when `cargo` not on PATH. Budget 75 s.
      [Story: FR-T5-TPE-060 / NFR-T5-TPE-002]
- [ ] **T-L2-002** : Implement
      `_test_tpe_l2_002_flutter_analyze_inherited` per
      ADR-T5-TPE-006 (graceful xfail with Q-004 cascade comment).
      The function returns 0 with an explanatory stderr message
      mirroring Phase B's `_test_ota_l2_002` phrasing.
      [Story: FR-T5-TPE-061 / FR-T5-TPE-062 / NFR-T5-TPE-005]
- [ ] **T-L2-003** : Run
      `t5-otel-traceparent-e2e.test.sh --level 1,2` ; expect 7 L1
      + 2 L2 GREEN (the flutter L2 xfails gracefully — counts as
      pass for the harness counter, with stderr noise documenting
      the cascade). Capture `/tmp/t5-otel-tpe-l2.log`.
      [Story: FR-T5-TPE-060..062]

### T-DOC — Documentation (FR-T5-TPE-090..091)

- [ ] **T-DOC-001** [P] : Add an entry under `## [Unreleased]` in
      `CHANGELOG.md` flagging :
      - The BDD feature file
        `examples/forge-fsm-example/test/features/traceparent_e2e.feature`
        (3 scenarios : Direct / Kong / Sampled-off).
      - The Kong gateway W3C trace-context preservation comment in
        `infra/kong/kong.yml.example`.
      - The harness
        `.forge/scripts/tests/t5-otel-traceparent-e2e.test.sh`
        (7 L1 + 2 L2).
      - The forward-pointer to the future Envoy migration
        (`b8-envoy-migration` — provisional).
      [Story: FR-T5-TPE-090]
- [ ] **T-DOC-002** [P] : Confirm `tasks.md` carries an explicit
      "Phase D — DEFERRED" section enumerating the live-run leg
      deliverables (this current file's tail). No-op if the
      section is already present.
      [Story: FR-T5-TPE-091 / NFR-T5-TPE-006]

### T-REV — Quality review gate

- [ ] **T-REV-001** : Run `/forge:review t5-otel-traceparent-e2e`
      driving the constitutional gate review : Articles I (TDD),
      II (BDD — three scenarios shipped), III + III.4 (specs first
      + Q-001..Q-002 answered, Q-004 inheritance documented), IV
      (delta — additive, no standard amendment), V (audit trail —
      `[Story: FR-T5-TPE-XXX]` on every task), VIII (infra — Kong
      declarative-only honored), IX (observability — evidence
      loop closed for gateway hop), XI.6 (privacy — no PII in
      BDD), XII (governance — no standard bump). Block if any
      returns VIOLATION.
      [Story: Article V]
- [ ] **T-REV-002** : Run the full `verify.sh` once more on a
      clean checkout to confirm reproducibility.
      [Story: NFR-T5-TPE-002]
- [ ] **T-REV-003** : Verify
      `bin/forge-questions.sh --change t5-otel-traceparent-e2e --status open`
      returns empty (Q-001..Q-002 fully answered ; Q-004
      inheritance is documented in design.md ADR-T5-TPE-006, not
      a new open question).
      [Story: Article III.4]
- [ ] **T-REV-004** : Verify NFR-T5-TPE-004 by running
      `git diff --stat <archive base>..HEAD` and confirming **no**
      `.rs`, `.dart`, `.proto`, `Cargo.toml`, or `pubspec.yaml`
      file is touched. Acceptable diff surface : `.feature`,
      `.yml.example` (kong, comment-only), `.sh` (harness),
      `.yml` (forge-ci.yml CI matrix), `.md` (changelog +
      `.forge/changes/`).
      [Story: NFR-T5-TPE-004]

**Phase 4 exit gate (= change implementation readiness for
`/forge:archive`)** :

- `t5-otel-traceparent-e2e.test.sh --level 1` : 7/7 PASS, 0 FAIL,
  ≤ 3 s.
- `t5-otel-traceparent-e2e.test.sh --level 1,2` : 7 L1 + 2 L2
  PASS on a toolchain host (flutter L2 xfails gracefully).
- `verify.sh` aggregate ≥ baseline + 1 PASS / 0 FAIL / RESULT:
  PASS.
- `constitution-linter.sh` OVERALL PASS (no new WARN).
- `forge-questions.sh --status open --change t5-otel-traceparent-e2e`
  empty.
- All FR-T5-TPE-001..091 + NFR-T5-TPE-001..007 tasks checked.
- `CHANGELOG.md` entry under `## [Unreleased]`.
- BDD `.feature` file shipped (3 scenarios ; step bodies are
  Phase D scope).
- Kong comment block shipped (declarative contract).

---

## Phase D — DEFERRED (NOT IN THIS CHANGE)

> **Out-of-phase note** : Phase D is the **live-run** validation
> leg. It is NOT shipped in `t5-otel-traceparent-e2e`. Phase C
> (this change) ships only the SPEC + HARNESS. Phase D ships the
> EXECUTOR. Listed here so future implementers have a roadmap.
>
> NFR-T5-TPE-006 enforces this section's discoverability.

Deliverables explicitly deferred :

- [ ] **(Phase D)** `docker compose up` driver invoking the
      example stack from
      `examples/forge-fsm-example/docker-compose.dev.yml`. Brings
      up `fsm-otel-collector`, `fsm-backend`, `fsm-frontend`, and
      `fsm-kong` (the gateway). Waits for healthchecks via
      `compose ... up --wait`.
- [ ] **(Phase D)** Stub OTLP receiver capturing spans from the
      collector's `debug` exporter into a JSON file. Either a
      Rust/Go test fixture or a `tee` redirect from the
      collector's stdout — choice locked at Phase D design time.
- [ ] **(Phase D)** Flutter run / test driver triggering the
      demo-005 greeting round trip programmatically. Either
      `flutter test integration_test/` or a `flutter drive`
      Selenium-style script.
- [ ] **(Phase D)** Programmatic traceId consistency assertion
      across all hops : extract span IDs from the captured OTLP
      JSON, walk the parent-child tree, assert the traceId field
      is identical across the 4 (direct) or 5 (Kong) spans.
- [ ] **(Phase D)** SigNoz API verification : query
      `http://localhost:3301/api/v1/traces/{traceId}` and assert
      the trace tree shape matches the BDD scenario expectations.
- [ ] **(Phase D)** Wire the `bdd_widget_test` step bodies
      (Flutter side) and `cucumber-rs` step bodies (Rust side)
      for both `demo_005_traceparent.feature` (Phase B FR-T5-OTA-031)
      and `traceparent_e2e.feature` (Phase C FR-T5-TPE-001..010).
- [ ] **(Phase D)** Replace `_test_tpe_l2_l2_001_cargo_build_inherited`
      with an actual span-emission assertion (run bin-server
      against the stub OTLP receiver, send a Greet request, assert
      ≥ 1 span exported).

Phase D is its own change (working name `t5-otel-live-run` —
provisional, set at change creation time).

---

## Out-of-scope but adjacent (NOT in this change)

- **`b8-envoy-migration`** (working name) — future T6 / B.8
  flagship migration adding Envoy gateway support. Will ship its
  own traceparent preservation BDD scenario + grep gate against
  the future `envoy.yaml` / `envoy.yml.example` config. The
  scenario will mirror Scenario 2 (Kong path) of this change with
  `Envoy` substituted for `Kong`. Forward-pointer in
  `kong.yml.example` comment + this change's `design.md` § Out
  of scope.
- **`t5-otel-dart-api-realign`** — future change reconciling
  `flutter/opentelemetry.md` standard imports with the actual
  pub.dev `opentelemetry 0.18.x` public API. Resolves Q-004.
  When that change lands, both Phase B and Phase C `flutter
  analyze` L2 xfails reactivate (drop the xfail return-0, assert
  exit 0 for real).

---

## Constitutional task review (per Article V)

| Task family | TDD order                              | Spec link                            | Architecture                           |
|-------------|----------------------------------------|--------------------------------------|----------------------------------------|
| T-PHC-*     | RED phase (intentional)                | FR-T5-TPE-040..047                   | ADR-T5-TPE-004                         |
| T-BDD-*     | RED witness then feature file          | FR-T5-TPE-001..010                   | ADR-T5-TPE-005 (Phase B coexistence)   |
| T-KONG-*    | RED witness then comment patch         | FR-T5-TPE-020..025                   | ADR-T5-TPE-003 (Kong declarative)      |
| T-CI-*      | RED witness then matrix entry          | FR-T5-TPE-047 / FR-T5-TPE-080        | forge-self-ci standard (G.1)           |
| T-L2-*      | RED witness then inherited toolchain   | FR-T5-TPE-060..062                   | ADR-T5-TPE-006 (Q-004 cascade)         |
| T-DOC-*     | No code, doc-only                      | FR-T5-TPE-090..091                   | CHANGELOG + tasks discoverability      |
| T-REV-*     | Final gate, no production code         | Article V / III.4 / VIII / IX        | All articles                           |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement`.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 5     | 2                    | 7 + 2 stubs (L1 + L2) |
| 2     | 6     | 0                    | 4 (BDD shape) |
| 3     | 8     | 0                    | 3 (Kong + CI) |
| 4     | 7     | 2                    | 2 (L2 cluster) |
| **Total** | **26** | **4**          | **18 RED witnesses** |

Estimated wall-clock at single-developer pace : Phase 1 ≈ 30 min,
Phase 2 ≈ 30 min (Gherkin authoring + RED/GREEN cycle), Phase 3
≈ 30 min, Phase 4 ≈ 30 min. Total ≈ 2 h of focused work. Phase C
is the smallest of the three T.5 phases (A : 6 h ; B : 8 h ; C :
2 h) because no production code is shipped.
