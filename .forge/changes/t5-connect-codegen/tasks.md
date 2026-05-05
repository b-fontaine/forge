# Tasks: t5-connect-codegen
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail, write the
  artefact, watch it pass, refactor.
- Audit trail tag `[Story: FR-T5-CC-XXX]` (Article V.1) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the same phase.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/verify.sh` and confirms expected counter movement.
- Concrete plugin versions pinned in Phase 1 (T-VER-*) per ADR-T5-002 ;
  no version is guessed elsewhere in the plan.

---

## Phase 1 — Foundation : version resolution + RED harness

Goal : Context7-resolved versions recorded ; `t5.test.sh` exists with
≥ 25 L1 + ≥ 5 L2 stub tests all returning FAIL. Full RED state.

### T-VER — Plugin version resolution (ADR-T5-002 / FR-T5-CC-022)

- [ ] **T-VER-001** : Resolve `buf` CLI latest stable via
      `mcp__context7__resolve-library-id` (`bufbuild/buf`) +
      `mcp__context7__query-docs`. Record version + changelog URL +
      access date in this section as a comment table. Verify
      `buf format --diff` against `templates/full-stack-monorepo/1.0.0/proto/`
      yields no diff (acceptance criterion #3 of ADR-T5-002).
      [Story: FR-T5-CC-022 / NFR-T5-CC-010]
- [ ] **T-VER-002** [P] : Resolve `protoc-gen-connect-go` latest stable
      ≥ 30 days old via Context7 (or fallback `WebFetch`
      <https://github.com/connectrpc/connect-go/releases>). Record
      version + URL + access date. [Story: FR-T5-CC-001 / FR-T5-CC-022]
- [ ] **T-VER-003** [P] : Resolve `protoc-gen-connect-es` latest stable
      ≥ 30 days old via Context7 (or
      <https://github.com/connectrpc/connect-es/releases>). Verify
      compatibility with `@connectrpc/connect-web` runtime version
      that demo-005 will pin (acceptance criterion #4).
      [Story: FR-T5-CC-002 / FR-T5-CC-022]
- [ ] **T-VER-004** [P] : Resolve `protoc-gen-connect-dart-community`
      latest stable ≥ 30 days old via Context7 (or its GitHub releases
      page). Confirm OSI licence. [Story: FR-T5-CC-003 / FR-T5-CC-022]
- [ ] **T-VER-005** : Resolve `@connectrpc/connect` and
      `@connectrpc/connect-web` npm versions for demo-005. Pin together
      with the protoc-gen-connect-es version chosen in T-VER-003.
      [Story: FR-T5-CC-032]

### T-PHA — t5.test.sh skeleton (RED for the whole change)

- [ ] **T-PHA-001** : Create
      `.forge/scripts/harnesses/t5.test.sh` with bash header
      (`#!/usr/bin/env bash`, `set -euo pipefail`, source `_helpers.sh`),
      PASS/FAIL/SKIP counters, and final report block.
      [Story: FR-T5-CC-060]
- [ ] **T-PHA-002** : Add the 18 L1 test stubs enumerated in
      `specs.md` FR-T5-CC-061 (buf.gen.yaml × 5, transport.yaml × 4,
      connect.rs × 3, main.rs preserved × 2, demo-005 × 3, linter × 2,
      snapshot × 2). Each stub calls `_fail "not implemented"`.
      [Story: FR-T5-CC-061]
- [ ] **T-PHA-003** [P] : Add `setup_l2()` / `teardown_l2()` creating
      `tmp/t5-fixtures/` with mktemp-style unique subdirs and `trap`
      EXIT cleanup. [Story: FR-T5-CC-064]
- [ ] **T-PHA-004** : Add 5 L2 fixture-test stubs (buf-generate-3-layouts,
      Dart smoke, traceparent E2E, Cargo build fixture, tonic-web
      integration) all returning FAIL. SKIP if `buf` CLI absent.
      [Story: FR-T5-CC-064]
- [ ] **T-PHA-005** [P] : Register `t5.test.sh` in `verify.sh`
      aggregated runner (after `t4.test.sh`). [Story: FR-T5-CC-060]
- [ ] **T-PHA-006** [P] : Register `t5.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix.
      [Story: FR-T5-CC-060]
- [ ] **T-PHA-007** : RED gate — run
      `bash .forge/scripts/harnesses/t5.test.sh` ; expect exit code
      non-zero ; expect `FAIL ≥ 23` ; capture log.
      [Story: FR-T5-CC-061]

**Phase 1 exit gate** : `t5.test.sh` exits non-zero with `FAIL ≥ 23`,
all 5 T-VER-* tasks have a recorded version + URL + access date,
constitution-linter still OVERALL PASS (no new artefacts yet).

---

## Phase 2 — Core : transport.yaml v1.1.0 + buf.gen.yaml + Rust adapter

Goal : The standard, the codegen config, and the Rust adapter ship.
After this phase, all L1 tests in §FR-T5-CC-061 first three groups
flip GREEN ; L2 fixture tests still RED.

### T-STD — transport.yaml v1.0.0 → v1.1.0 (FR-T5-CC-020..023)

- [ ] **T-STD-001** : Verify `test_transport_yaml_v1_1_0` is FAIL
      (RED witness). [Story: FR-T5-CC-020]
- [ ] **T-STD-002** : Edit `.forge/standards/transport.yaml` :
      `version: "1.0.0"` → `version: "1.1.0"`. No other key touched.
      [Story: FR-T5-CC-020]
- [ ] **T-STD-003** : Add `codegen.connect_layout_version: 1` field
      under `codegen:`. [Story: FR-T5-CC-021]
- [ ] **T-STD-004** : Add `codegen.versions:` map with the 4 pins
      from T-VER-001..004 (buf, protoc-gen-connect-go,
      protoc-gen-connect-es, protoc-gen-connect-dart-community).
      [Story: FR-T5-CC-022]
- [ ] **T-STD-005** : Append an `Updated` entry to
      `.forge/standards/REVIEW.md` for `transport.yaml` (date
      2026-05-05, reason "v1.1.0 codegen pins per t5-connect-codegen").
      Do NOT alter the existing `Reviewed on: 2026-05-04` baseline
      (immutable ledger). [Story: FR-T5-CC-023]
- [ ] **T-STD-006** : Run `t5.test.sh` ; expect 4 tests PASS
      (parses, version bumped, codegen.connect_layout_version present,
      codegen.versions complete). [Story: FR-T5-CC-020..023]

### T-BUF — buf.gen.yaml extension (FR-T5-CC-001..005)

- [ ] **T-BUF-001** : Verify
      `test_buf_gen_yaml_has_3_connect_plugins` is FAIL (RED witness).
      [Story: FR-T5-CC-001]
- [ ] **T-BUF-002** : Edit
      `templates/full-stack-monorepo/1.0.0/proto/buf.gen.yaml` to add
      the `protoc-gen-connect-go` remote plugin entry with
      `out: gen/connect/rust` + `paths=source_relative`, version pin
      from T-VER-002. [Story: FR-T5-CC-001]
- [ ] **T-BUF-003** [P] : Add `protoc-gen-connect-es` entry with
      `out: gen/connect/ts` + `target=ts` + `import_extension=js`,
      version pin from T-VER-003. [Story: FR-T5-CC-002]
- [ ] **T-BUF-004** [P] : Add `protoc-gen-connect-dart-community`
      entry with `out: gen/connect/dart`, version pin from T-VER-004.
      [Story: FR-T5-CC-003]
- [ ] **T-BUF-005** : Verify the existing `tonic-build` invocation in
      `templates/full-stack-monorepo/1.0.0/backend/build.rs` (or wherever
      the flagship hosts it) is unchanged ; if `buf.gen.yaml` had
      tonic-build entries, leave them. [Story: FR-T5-CC-004]
- [ ] **T-BUF-006** : Add `gen/connect/` to the template `.gitignore`.
      [Story: FR-T5-CC-005]
- [ ] **T-BUF-007** : Run `t5.test.sh` ; expect 5 buf-related L1 tests
      PASS. [Story: FR-T5-CC-001..005]

### T-RUST — Rust transport/connect.rs adapter (FR-T5-CC-010..014)

- [ ] **T-RUST-001** : Verify
      `test_transport_connect_rs_exists_and_mounts` is FAIL.
      [Story: FR-T5-CC-010]
- [ ] **T-RUST-002** : Create
      `templates/full-stack-monorepo/1.0.0/backend/src/transport/connect.rs`
      module per `design.md` §2.1 :
      - public `into_router(use_case: Arc<GreeterUseCase>) -> axum::Router`
      - wraps the existing tonic Greeter service descriptor with
        `tonic_web::GrpcWebLayer::new()`.
      - the OTel layer is composed **outside** the tonic-web layer
        (per design constraint and FR-T5-CC-013).
      - module-level `//!` doc explaining the `/connect` mount + the
        Connect-ES wire-compat note + the `Connect+JSON` deferment.
      [Story: FR-T5-CC-010..013]
- [ ] **T-RUST-003** : Wire `transport/connect.rs` into
      `templates/full-stack-monorepo/1.0.0/backend/src/main.rs` :
      register the module under `mod transport { pub mod connect; ... }`,
      mount `transport::connect::into_router(use_case.clone())` at
      `/connect` via `.merge()`. The existing tonic gRPC server bind
      (separate port) MUST be unchanged. [Story: FR-T5-CC-010 / FR-T5-CC-011]
- [ ] **T-RUST-004** : Confirm domain layer untouched —
      `templates/full-stack-monorepo/1.0.0/backend/src/domain/`
      diff vs main = 0 lines. [Story: FR-T5-CC-012]
- [ ] **T-RUST-005** : Run `t5.test.sh` ; expect 3 connect.rs L1 tests
      + 2 main.rs preservation tests PASS. [Story: FR-T5-CC-010..014]

**Phase 2 exit gate** : `t5.test.sh` L1 PASS ≥ 12 (covering buf.gen.yaml
+ transport.yaml + connect.rs + main.rs preservation). L2 still RED.
constitution-linter OVERALL PASS.

---

## Phase 3 — Integration : demo-005 + L2 fixtures

Goal : reference demo archived ; L2 fixtures (buf generate, Dart smoke,
traceparent E2E) flip GREEN.

### T-DEMO — Reference demo `demo-005-connect-greeting` (FR-T5-CC-030..035)

- [ ] **T-DEMO-001** : Verify `test_demo_005_archived` is FAIL.
      [Story: FR-T5-CC-030]
- [ ] **T-DEMO-002** : Create
      `examples/forge-fsm-example/.forge/changes/demo-005-connect-greeting/`
      with `.forge.yaml` (`status: archived`, `schema: default`,
      created 2026-05-05, full timeline filled). [Story: FR-T5-CC-030]
- [ ] **T-DEMO-003** [P] : Write `proposal.md` (1 page) explaining the
      demo's intent (Connect-RPC reference, single-layer backend).
      [Story: FR-T5-CC-030]
- [ ] **T-DEMO-004** [P] : Write `specs.md` with FR-DEMO5-001..004 +
      2 BDD scenarios (Connect-RPC happy path + traceparent E2E
      invariant). [Story: FR-T5-CC-031]
- [ ] **T-DEMO-005** [P] : Write `design.md` showing the tonic-web
      layer wiring (mirrors flagship template's design §2.1, scoped
      to the demo). [Story: FR-T5-CC-030]
- [ ] **T-DEMO-006** [P] : Write `tasks.md` with 3 tasks (handler
      adapter from flagship, TS client, E2E smoke). [Story: FR-T5-CC-030]
- [ ] **T-DEMO-007** : Create `examples/forge-fsm-example/clients/`
      directory if missing. [Story: FR-T5-CC-032]
- [ ] **T-DEMO-008** : Write `connect-client.ts` (~30 LOC) calling the
      Connect Greeter via `createGrpcWebTransport({ baseUrl:
      "http://localhost:8080/connect" })`. Use `crypto.randomUUID()`
      to seed a `traceparent` header for the smoke test.
      [Story: FR-T5-CC-032]
- [ ] **T-DEMO-009** : Write minimal `clients/package.json` pinning
      `@connectrpc/connect` + `@connectrpc/connect-web` from T-VER-005.
      No lockfile committed (CI generates fresh). [Story: FR-T5-CC-032]
- [ ] **T-DEMO-010** [P] : Add a one-line note to
      `examples/forge-fsm-example/README.md` linking to demo-005.
      [Story: FR-T5-CC-035]
- [ ] **T-DEMO-011** : Run `t5.test.sh` ; expect 3 demo-005 L1 tests
      PASS (archived shape + BDD scenarios + TS client `node --check`).
      [Story: FR-T5-CC-030..032]

### T-L2 — L2 fixture tests (FR-T5-CC-064)

- [ ] **T-L2-001** : Verify `test_buf_generate_3_layouts` is FAIL.
      [Story: FR-T5-CC-064]
- [ ] **T-L2-002** : Implement L2 fixture
      `tmp/t5-fixtures/buf-gen/` : copy demo proto + buf.gen.yaml,
      run `buf generate`, assert files exist at the layout pinned by
      ADR-T5-004 (rust/, ts/, dart/ subtrees). [Story: FR-T5-CC-064]
- [ ] **T-L2-003** : Implement Dart plugin smoke L2 fixture (gating
      per FR-T5-CC-003) : run buf generate against demo proto with
      only the dart plugin entry ; assert exit 0 + at least one .dart
      file produced. If FAIL, the harness FAILs (per design).
      [Story: FR-T5-CC-003]
- [ ] **T-L2-004** : Implement traceparent E2E smoke L2 fixture
      (FR-T5-CC-014 / FR-T5-CC-033) :
      1. Spawn a minimal Rust process (Cargo fixture workspace under
         `tmp/t5-fixtures/connect-server/`) serving the Connect handler
         on `127.0.0.1:0` (kernel-assigned port).
      2. Stand up a mock OTel collector that listens on
         `127.0.0.1:0` and records OTLP HTTP payloads.
      3. Run the demo `connect-client.ts` via `node` against the
         fixture server with a known traceparent.
      4. Assert the collector recorded a span with the same `traceId`
         and matching parent spanId.
      [Story: FR-T5-CC-014 / FR-T5-CC-033]
- [ ] **T-L2-005** : Implement Cargo build fixture : `cargo fetch`
      primes the local cache ; subsequent build uses `--offline` for
      determinism. [Story: FR-T5-CC-064]
- [ ] **T-L2-006** : Implement tonic-web layer integration test
      (Rust unit test inside the fixture workspace) : POST a gRPC-Web
      framed request to `/connect/forge.greeter.v1.Greeter/Greet`,
      assert status 200 + correct response payload.
      [Story: FR-T5-CC-014]
- [ ] **T-L2-007** : Run `t5.test.sh` full ; expect 5 L2 tests PASS
      (or `SKIP` if `buf` CLI absent locally — CI must PASS).
      [Story: FR-T5-CC-064]

**Phase 3 exit gate** : `t5.test.sh` L1 + L2 all GREEN (or L2 SKIP
locally, GREEN in CI). NFR-T5-CC-001 timing : L1 ≤ 5 s, full ≤ 30 s
(verified via `time bash`). NFR-T5-CC-007 generated stub size budget
verified.

---

## Phase 4 — Quality : linter + snapshot + docs + CI gate

Goal : the cross-cutting bits ship ; CI registration validated ;
snapshot regenerated under budget ; docs updated.

### T-LNT — Linter `transport-codegen-coverage` (FR-T5-CC-040..041)

- [ ] **T-LNT-001** : Verify
      `test_transport_codegen_coverage_warn_positive_case` is FAIL.
      [Story: FR-T5-CC-040]
- [ ] **T-LNT-002** : Add a new section to
      `.forge/scripts/constitution-linter.sh` :
      `transport-codegen-coverage` ; scans for any `proto/` directory
      excluding `examples/` (per F.4 conventions) ; if found and
      sibling `gen/connect/` is absent, emit one WARN line referring
      to `docs/MIGRATION-PATHS.md`. Use the existing `warn` helper
      (no new helper needed). [Story: FR-T5-CC-040]
- [ ] **T-LNT-003** [P] : Honour `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1`
      env var to skip the rule. [Story: FR-T5-CC-041]
- [ ] **T-LNT-004** [P] : Document the rule + opt-out in
      `.forge/standards/global/linting-rules.md` opt-out matrix.
      [Story: FR-T5-CC-041]
- [ ] **T-LNT-005** : Run `t5.test.sh` ; expect 2 linter L1 tests PASS
      (positive WARN + negative case with opt-out env var set).
      [Story: FR-T5-CC-040..041]

### T-SNP — Snapshot tarball regeneration (FR-T5-CC-050..051)

- [ ] **T-SNP-001** : Verify `test_snapshot_tarball_size_within_budget`
      is FAIL (the existing tarball doesn't yet contain
      `transport/connect.rs`). [Story: FR-T5-CC-050]
- [ ] **T-SNP-002** : Run the existing snapshot regeneration script
      (`bin/forge-snapshot.sh full-stack-monorepo 1.0.0` or equivalent
      per project conventions) to refresh
      `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`.
      [Story: FR-T5-CC-050]
- [ ] **T-SNP-003** : Verify size ≤ 500 KB gzipped (current 422 KB
      baseline ; budget delta ≤ 50 KB). Capture
      `du -h` output in this task's evidence trail.
      [Story: FR-T5-CC-051 / NFR-T5-CC-002]
- [ ] **T-SNP-004** : Run `a7.test.sh` to confirm `forge upgrade` 3-way
      merge still works against the regenerated snapshot. Expect no
      regression. [Story: NFR-T5-CC-005]
- [ ] **T-SNP-005** : Run `t5.test.sh` ; expect 2 snapshot L1 tests
      PASS. [Story: FR-T5-CC-050..051]

### T-DOC — Documentation (FR-T5-CC-070..072)

- [ ] **T-DOC-001** [P] : Add "T5 — Connect codegen additive
      (v0.3.x → v0.4.0-rc.x)" section to `docs/MIGRATION-PATHS.md`
      covering : what `forge upgrade` adds (paths, buf.gen.yaml
      entries, transport/connect.rs module), what stays untouched
      (Kong-bridge REST, tonic gRPC), the WARN-only linter rule, the
      `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1` opt-out. Include the
      `application/connect+json` HTTP/1.1 limitation note from
      ADR-T5-001. [Story: FR-T5-CC-070]
- [ ] **T-DOC-002** [P] : Add a paragraph under the
      `full-stack-monorepo` row in `docs/ARCHETYPES.md` indicating
      Connect-RPC is the additive default transport from v0.4.0-rc.x
      onward, with REST-bridge retiring at B.8 (T6).
      [Story: FR-T5-CC-071]
- [ ] **T-DOC-003** [P] : Add an entry under `## [Unreleased]` in
      `CHANGELOG.md` flagging : Connect codegen plugins added,
      Connect-RPC server route mounted alongside tonic gRPC,
      `transport.yaml` v1.0.0 → v1.1.0, demo-005 added, linter rule
      `transport-codegen-coverage` WARN-only introduced.
      [Story: FR-T5-CC-072]

### T-CI — CI registration finalisation

- [ ] **T-CI-001** : Confirm `t5.test.sh` is in the
      `forge-ci.yml` `harness` job matrix (registered in T-PHA-006).
      [Story: FR-T5-CC-060]
- [ ] **T-CI-002** : Run `verify.sh` locally ; expect aggregate
      counter to grow by ≥ 25 PASS (the new t5 tests) without any
      regression in the existing 108 PASS / 0 FAIL baseline.
      [Story: NFR-T5-CC-004]
- [ ] **T-CI-003** : Run `constitution-linter.sh` ; expect OVERALL
      PASS (with optionally one WARN from
      `transport-codegen-coverage` against the example tree —
      acceptable per ADR-T5-005). [Story: NFR-T5-CC-004]

### T-REV — Quality review gate

- [ ] **T-REV-001** : Invoke **Tribune** (Rust quality guardian) on
      the Rust adapter (`transport/connect.rs` + `main.rs` diff)
      validating hexagonal preservation, OTel layer ordering, public
      API doc ratio ≥ 80%. [Story: NFR-T5-CC-004 / Article X.3]
- [ ] **T-REV-002** : Run `/forge:review t5-connect-codegen` to drive
      the constitutional gate review : Articles I (TDD), II (BDD),
      III + III.4, IV (delta), V, VII (Rust), IX (Sec), X (Quality),
      XII (Governance). Block if any returns VIOLATION. [Story: Article V]
- [ ] **T-REV-003** : Run the full `verify.sh` once more on a clean
      checkout to confirm reproducibility. [Story: NFR-T5-CC-004]

**Phase 4 exit gate (= change archival readiness)** :
- `t5.test.sh` ≥ 25 PASS, 0 FAIL, ≤ 30 s wall-clock.
- `verify.sh` aggregate ≥ 133 PASS, 0 FAIL.
- `constitution-linter.sh` OVERALL PASS.
- `bin/forge-questions.sh --change t5-connect-codegen --status open`
  returns empty (Q-001..Q-004 all answered at design).
- Snapshot tarball ≤ 500 KB.
- All FR-T5-CC-001..072 tasks checked.
- CHANGELOG entry under `## [Unreleased]`.

---

## Constitutional task review (per Article V)

For each task above, verifying TDD compliance + spec linkage + architecture
preservation :

| Task family | TDD order | Spec link | Architecture |
|-------------|-----------|-----------|--------------|
| T-VER-* | N/A (resolution work, no code) | FR-T5-CC-022 / NFR-T5-CC-010 | N/A |
| T-PHA-* | RED phase (intentionally) | FR-T5-CC-060..064 | N/A |
| T-STD-* | RED witness before each edit | FR-T5-CC-020..023 | Article XII (standard) |
| T-BUF-* | RED witness before each edit | FR-T5-CC-001..005 | proto-contracts standard |
| T-RUST-* | RED witness then minimal impl | FR-T5-CC-010..014 | Article VII (hexagonal) |
| T-DEMO-* | RED witness then archived demo | FR-T5-CC-030..035 | Article II (BDD scenarios) |
| T-L2-* | RED witness then fixture impl | FR-T5-CC-014 / FR-T5-CC-033..064 | Article I (TDD) |
| T-LNT-* | RED witness then linter section | FR-T5-CC-040..041 | Article V (gates) |
| T-SNP-* | RED witness then snapshot regen | FR-T5-CC-050..051 | upgrade-policy standard |
| T-DOC-* | No code, doc-only | FR-T5-CC-070..072 | N/A |
| T-CI-* | Validation only | FR-T5-CC-060 / NFR-T5-CC-004 | forge-self-ci standard |
| T-REV-* | Final gate, no production code | Article V / X | All articles |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement`.
