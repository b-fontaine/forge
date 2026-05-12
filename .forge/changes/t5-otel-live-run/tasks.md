# Tasks: t5-otel-live-run
<!-- Status: planned -->
<!-- Schema: full-stack-monorepo -->

## Convention

- TDD order is **immutable** : RED → verify RED → GREEN → verify
  GREEN → REFACTOR.
- Audit trail tag `[Story: FR-T5-OLR-XXX]` on every task (Article V.1).
- `[P]` marks tasks parallelizable within the same phase.
- Each phase ends with a **gate task** running the harness +
  `verify.sh` + `constitution-linter.sh`.
- ADRs from `design.md` (ADR-T5-OLR-001..006) honored verbatim.

---

## Phase 1 — Foundation : RED harness with all stubs failing

Goal : `t5-otel-live-run.test.sh` exists with **8 L1 stubs all FAIL +
1 L2 stub gracefully skipping**, full RED state captured.

- [ ] **T-OLR-001** : Create
      `.forge/scripts/tests/t5-otel-live-run.test.sh` with bash
      header, `set -uo pipefail`, source `_helpers.sh`, PASS/FAIL
      counters, `--level 1,2` parsing, `print_summary` close-out.
      Mirror `t5-otel-traceparent-e2e.test.sh` per ADR-T5-OLR-006.
      [Story: FR-T5-OLR-080]
- [ ] **T-OLR-002** : Add **8 L1 test stubs** returning
      `_not_implemented` per the FR↔test mapping in
      `design.md` ADR-T5-OLR-006.
      [Story: FR-T5-OLR-081..088]
- [ ] **T-OLR-003** [P] : Add **1 L2 test stub**
      `_test_olr_l2_001_docker_compose_smoke` with the
      `FORGE_LIVE_RUN_DOCKER` env gate.
      [Story: FR-T5-OLR-101]
- [ ] **T-OLR-004** [P] : Register
      `t5-otel-live-run.test.sh` in `.github/workflows/forge-ci.yml`
      `harness` job matrix immediately after
      `t5-otel-traceparent-e2e.test.sh` with `--level 1`. Verify file
      length ≤ 300 lines after the addition (NFR-T5-OLR-005 /
      NFR-CI-002). [Story: FR-T5-OLR-120]
- [ ] **T-OLR-005** : RED gate confirmed — run the harness ; expect
      8 FAIL on `--level 1`. [Story: FR-T5-OLR-080]

**Phase 1 exit gate** : harness exits 1 with `FAIL == 8` ;
`forge-ci.yml` ≤ 300 lines ; constitution-linter PASS.

---

## Phase 2 — Fake collector + smoke driver (FR-T5-OLR-001..028)

- [ ] **T-OLR-010** : Create
      `examples/forge-fsm-example/test/live-run/fake_otlp_collector.py`
      per ADR-T5-OLR-001 (stdlib walker, no pip dep). Implement :
      - `argparse` for `--bind`, `--out`.
      - `http.server.ThreadingHTTPServer` on the bind address.
      - Handler routing : `GET /` → 200 + body
        `fake-otlp-collector\n` (FR-T5-OLR-007).
      - Handler routing : `POST /v1/traces|/v1/metrics|/v1/logs` →
        decode body, sanitise, write capture JSON, return 200.
      - 404 for other paths.
      - varint + length-delimited walker extracting
        `service.name` and `ResourceSpans` count.
      - Sanitiser : timestamps → `<ts:redacted>` ; IPv4 →
        `<ip:redacted>` ; `host.name` → `<host:redacted>`.
      - JSON writer using `json.dumps(..., indent=2, sort_keys=True)`
        for deterministic byte output.
      - SIGTERM / SIGINT handler.
      [Story: FR-T5-OLR-001..010]
- [ ] **T-OLR-011** : Create
      `examples/forge-fsm-example/test/live-run/run_smoke.sh` per
      FR-T5-OLR-020..028 :
      - `argparse`-style bash flag parsing for `--out`,
        `--probe-only`, `--scenario {direct,kong}`.
      - Start collector in background, trap EXIT to kill.
      - Health-poll via `curl -fsS http://127.0.0.1:4318/`.
      - Decode hex-canned OTLP payload, POST to
        `/v1/traces` via Python `urllib.request.urlopen`
        (because curl --data-binary has line-ending quirks on
        macOS).
      - Grep capture for `service_name`, `traceparent`,
        `resource_spans_count`.
      - Exit codes : 0 PASS / 1 FAIL / 2 missing toolchain.
      [Story: FR-T5-OLR-020..028]
- [ ] **T-OLR-012** : Flip `_test_olr_001_driver_files_exist` to
      its real assertion (both files exist + audit headers).
      [Story: FR-T5-OLR-081]
- [ ] **T-OLR-013** : Flip `_test_olr_002_collector_stdlib_only` to
      its real assertion (no `import protobuf|grpc|requests`).
      [Story: FR-T5-OLR-082]
- [ ] **T-OLR-014** : Flip `_test_olr_003_smoke_driver_runs` to its
      real assertion : run the driver against a tmpdir, expect exit
      0 + at least one `capture-NNN.json` appears. Skip cleanly if
      `python3` not on PATH. [Story: FR-T5-OLR-083]
- [ ] **T-OLR-015** : Run the harness ; expect
      `_test_olr_001..003` flip GREEN (3 of 8).
      [Story: FR-T5-OLR-081..083]

**Phase 2 exit gate** : 3/8 GREEN, 5 FAIL. Collector + driver work
end-to-end against a fresh tmpdir.

---

## Phase 3 — Golden captures + BDD feature (FR-T5-OLR-040..064)

- [ ] **T-OLR-020** : Generate the **direct** golden capture by
      running `bash test/live-run/run_smoke.sh --scenario direct
      --out .forge/changes/t5-otel-live-run/captures/`. Rename the
      output to `direct.golden.json`. Verify it contains
      `service_name: fsm-backend` + `<ts:redacted>` + zero IPv4
      patterns. [Story: FR-T5-OLR-040 / FR-T5-OLR-043]
- [ ] **T-OLR-021** : Generate the **kong** golden capture similarly
      with `--scenario kong`. Rename to `kong.golden.json`.
      [Story: FR-T5-OLR-041 / FR-T5-OLR-043]
- [ ] **T-OLR-022** : Write
      `.forge/changes/t5-otel-live-run/captures/README.md` documenting
      regen flow + sanitisation rules + deterministic placeholders.
      [Story: FR-T5-OLR-042]
- [ ] **T-OLR-023** : Flip `_test_olr_004_capture_matches_direct_golden`
      + `_test_olr_005_capture_matches_kong_golden` to their real
      assertions (`diff -q`). [Story: FR-T5-OLR-084 / FR-T5-OLR-085]
- [ ] **T-OLR-024** : Flip `_test_olr_020_goldens_sanitised` to its
      real assertion. [Story: FR-T5-OLR-087]
- [ ] **T-OLR-025** : Create
      `examples/forge-fsm-example/test/features/traceparent_live_run.feature`
      with 2 scenarios per ADR-T5-OLR-005, audit header,
      cross-reference comment to Phase C, Phase B symbol
      forward-pointer. [Story: FR-T5-OLR-060..064]
- [ ] **T-OLR-026** : Flip `_test_olr_010_feature_file_exists` to
      its real assertion. [Story: FR-T5-OLR-086]
- [ ] **T-OLR-027** : Run the harness ; expect 7/8 GREEN (only
      `_test_olr_030_ci_matrix_entry` still RED).
      [Story: FR-T5-OLR-040..087]

**Phase 3 exit gate** : 7/8 GREEN, 1 FAIL (CI matrix). Goldens
committed and byte-stable.

---

## Phase 4 — CI matrix + L2 docker leg + docs (FR-T5-OLR-100..142)

- [ ] **T-OLR-030** : Flip `_test_olr_030_ci_matrix_entry` to its
      real assertion (line-order + `--level 1` + file ≤ 300 lines).
      Then run the harness ; expect 8/8 GREEN. T-OLR-004 already
      added the matrix entry in Phase 1. [Story: FR-T5-OLR-088 /
      FR-T5-OLR-120]
- [ ] **T-OLR-031** [P] : Create
      `examples/forge-fsm-example/test/live-run/docker-compose.live-run.yml`
      per FR-T5-OLR-100. Minimal stack : just `fsm-otel-collector`.
      `fsm-` prefix + healthcheck + named network preserved.
      [Story: FR-T5-OLR-100]
- [ ] **T-OLR-032** [P] : Create
      `examples/forge-fsm-example/test/live-run/README.md` per
      FR-T5-OLR-102.
      [Story: FR-T5-OLR-102]
- [ ] **T-OLR-033** : Implement `_test_olr_l2_001_docker_compose_smoke`
      per FR-T5-OLR-101 with env + tool guards. Skips silently when
      `FORGE_LIVE_RUN_DOCKER` != `1` or `docker` absent.
      [Story: FR-T5-OLR-101]
- [ ] **T-OLR-034** [P] : Add a `## [Unreleased]` entry to
      `CHANGELOG.md` per FR-T5-OLR-140.
      [Story: FR-T5-OLR-140]
- [ ] **T-OLR-035** [P] : Add the Phase D row to
      `docs/new-archetypes-plan.md` per FR-T5-OLR-141.
      [Story: FR-T5-OLR-141]
- [ ] **T-OLR-036** [P] : Add the inventory bullet to
      `.forge/product/roadmap.md` per FR-T5-OLR-142.
      [Story: FR-T5-OLR-142]

### T-REV — Quality review gate

- [ ] **T-OLR-040** : Run `bash .forge/scripts/tests/t5-otel-live-run.test.sh`
      ; expect 8/8 L1 GREEN ≤ 10 s.
      [Story: NFR-T5-OLR-001]
- [ ] **T-OLR-041** : Run `bash .forge/scripts/verify.sh` ; expect
      RESULT: PASS, aggregate ≥ baseline + 1 PASS / 0 FAIL.
      [Story: NFR-T5-OLR-002]
- [ ] **T-OLR-042** : Run `bash .forge/scripts/constitution-linter.sh`
      ; expect OVERALL PASS. [Story: NFR-T5-OLR-002]
- [ ] **T-OLR-043** : Verify NFR-T5-OLR-004 by running
      `git diff --stat HEAD~..HEAD examples/forge-fsm-example/backend
      examples/forge-fsm-example/frontend/lib` and confirming **no**
      `.rs` or `.dart` file is touched. [Story: NFR-T5-OLR-004]
- [ ] **T-OLR-044** : Verify NFR-T5-OLR-005 :
      `wc -l .github/workflows/forge-ci.yml` ≤ 300.
      [Story: NFR-T5-OLR-005]

**Phase 4 exit gate (= implementation readiness for
`/forge:archive`)** :

- harness 8/8 L1 GREEN, ≤ 10 s ; L2 skips when env unset.
- `verify.sh` aggregate ≥ baseline + 1 PASS / 0 FAIL / RESULT: PASS.
- `constitution-linter.sh` OVERALL PASS.
- `forge-ci.yml` ≤ 300 lines.
- No `.rs` or `.dart` touched.
- `CHANGELOG.md` `[Unreleased]` entry.
- Roadmap + plan entries updated.
- BDD feature + 2 goldens + harness + driver + collector + compose
  + README all shipped.

---

## Out-of-scope but adjacent (NOT in this change)

- **`b8-envoy-migration`** — Envoy live-run leg, T6 / B.8.
- Real cucumber-rs / bdd_widget_test step bindings — future change.
- gRPC OTLP probe (only HTTP/protobuf in scope per ADR-T5-OTA-002
  symmetry).

---

## Constitutional task review (per Article V)

| Task family | TDD order                              | Spec link                            | Architecture                           |
|-------------|----------------------------------------|--------------------------------------|----------------------------------------|
| T-OLR-001..005 | RED phase (intentional)             | FR-T5-OLR-080..088                   | ADR-T5-OLR-006                         |
| T-OLR-010..015 | RED witness then collector + driver | FR-T5-OLR-001..028                   | ADR-T5-OLR-001..004                    |
| T-OLR-020..027 | RED witness then goldens + feature  | FR-T5-OLR-040..064                   | ADR-T5-OLR-003 / ADR-T5-OLR-005        |
| T-OLR-030..036 | RED witness then CI + docs          | FR-T5-OLR-100..142                   | ADR-T5-OLR-002                         |
| T-OLR-040..044 | Final gate                          | NFR-T5-OLR-001..005                  | All ADRs                                |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement`.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 5     | 2                    | 8 + 1 stubs   |
| 2     | 6     | 0                    | 3 (driver tests) |
| 3     | 8     | 0                    | 4 (goldens + feature) |
| 4     | 12    | 4                    | 1 (CI matrix) |
| **Total** | **31** | **6**          | **16 RED witnesses** |
