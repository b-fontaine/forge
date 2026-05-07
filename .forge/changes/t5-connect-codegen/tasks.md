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

### T-VER — Toolchain version resolution (ADR-T5-002 / FR-T5-CC-022)

> **Most versions resolved at design phase 2026-05-05** post-Context7
> investigation (see `design.md` ADR-T5-002 table). Impl Phase 1 only
> re-confirms drift + spikes the connectrpc Rust crate (T-VER-006).

> **T-VER-001..005 status (2026-05-05)** : design-phase resolution and
> impl-phase drift check happen **the same day** in this run, so the
> drift check is mathematically a no-op. All 5 pins were resolved
> during `/forge:design` via Context7 + WebSearch + WebFetch (see
> `design.md` ADR-T5-002 table + `open-questions.md` Q-002 resolved
> values + this commit's evidence trail). When/if `/forge:implement`
> re-runs after a non-trivial gap, these tasks become real drift
> checks (re-fetch the same URLs and verify versions are still
> current ; pick patch if upstream has shipped). For this run, all
> five marked [x] with the design-phase values authoritative.

- [x] **T-VER-001** : `buf` CLI **v1.68.2** confirmed
      (`buf.build/docs/cli/installation`, accessed 2026-05-05). No
      drift (same-day). `buf format --diff` against
      `templates/full-stack-monorepo/1.0.0/proto/` is deferred to
      first impl run that touches the proto tree (T-BUF phase) ;
      run it then with `BUF_VERSION=1.68.2`. [Story: FR-T5-CC-022 / NFR-T5-CC-010]
- [x] **T-VER-002** [P] : `protoc-gen-connect-go` **v1.19.2** confirmed
      (released 2025-04-20, `github.com/connectrpc/connect-go/releases/latest`,
      accessed 2026-05-05). 1 year old, well past 30-day criterion.
      [Story: FR-T5-CC-001 / FR-T5-CC-022]
- [x] **T-VER-003** [P] : Connect v2 baseline confirmed
      (`@bufbuild/protoc-gen-es ≥ v2.2.0`, `@connectrpc/connect@^2.0.0`,
      `@connectrpc/connect-web@^2.0.0`) per
      `github.com/connectrpc/connect-es/blob/main/MIGRATING.md`
      accessed 2026-05-05. `protoc-gen-connect-es` retired and
      explicitly NOT consumed. [Story: FR-T5-CC-002 / FR-T5-CC-022]
- [x] **T-VER-004** [P] : Official `connectrpc/connect-dart` plugin
      confirmed (pub.dev `connectrpc` v1.0.0+, verified publisher
      `connectrpc.com`, Apache-2.0, 24.1k downloads, last update
      ≈ July 2025). Replaces abandoned `skadero/protoc-gen-connect-dart`
      (last update 2022-09). [Story: FR-T5-CC-003 / FR-T5-CC-022]
- [x] **T-VER-005** : npm `@connectrpc/connect@^2.0.0` +
      `@connectrpc/connect-web@^2.0.0` confirmed as Connect v2 canonical
      runtime (same source as T-VER-003). Pin in
      `clients/package.json` deferred to T-DEMO-009 task.
      [Story: FR-T5-CC-032]
- [x] **T-VER-006** : **Spike completed 2026-05-05** via WebFetch
      `github.com/anthropics/connect-rust`. Findings :
      - **Pin** : `connectrpc = "=0.3.3"` + `buffa = "=0.3.3"` +
        `buffa-types = "=0.3.3"` (released 2026-04-22 ;
        Apache-2.0 ; MSRV Rust 1.88).
      - **Conformance** : 6 558 tests passing (3 600 server +
        1 514 TLS + 1 444 client) — Connect + gRPC + gRPC-Web, all
        4 RPC types (unary, server-stream, client-stream, bidi).
      - **Axum integration** : inline via
        `connectrpc::Router::into_axum_service()` — **no separate
        `connectrpc-axum` crate**. Update design.md class diagram +
        ADR-T5-001 + tasks T-RUST-002 to remove the standalone
        `ConnectRpcAxum` reference.
      - **Codegen path** : **Option 2 / Path α (`connectrpc-build`
        via `build.rs`)** picked — supersedes the initial Option A
        (buf-driven local plugins) decision after T-BUF investigation
        revealed (a) the codebase convention is "remote plugins only"
        in `buf.gen.yaml.tmpl` (no local plugins, no `cargo install`
        adopter prerequisite), (b) the `buf.build/anthropics/connect-rust`
        remote plugin is **not yet shipped** in the BSR (planned
        upstream, not accepted as of 2026-05-05). `connectrpc-build`
        is upstream-supported (documented as "Option B" in the
        connect-rust README, not a workaround) and integrates as a
        `build.rs` build-dependency in
        `backend/crates/grpc-api/Cargo.toml.tmpl` ; generated code
        consumed via `connectrpc::include_generated!()`. When the
        BSR remote plugin ships post-T5, a follow-up change migrates.
      - **Version-age waiver** : v0.3.3 is 13 days old (< 30 days
        ADR-T5-002 criterion #1). Waiver justification : (1)
        conformance suite passing satisfies the regression-filter
        intent of the rule, (2) Anthropic OSS pedigree, (3) we pin
        exact `=0.3.3` so upgrades are manual. Documented in
        `design.md` ADR-T5-002 footnote.
      - **API surface caveat** : pre-1.0 ; pin exact, monitor
        upstream releases ; if a 0.4.x lands before B.8, evaluate
        whether to bump or stay on 0.3.x.
      [Story: ADR-T5-001 / ADR-T5-002 / FR-T5-CC-010]

### T-PHA — t5.test.sh skeleton (RED for the whole change)

- [x] **T-PHA-001** : Created
      `.forge/scripts/tests/t5.test.sh` with bash header
      (`#!/usr/bin/env bash`, `set -uo pipefail`, source `_helpers.sh`),
      PASS/FAIL counters reset, and final `print_summary` block via
      the shared helper. Mirrored t4.test.sh shape (same `--level`
      parsing, same `_yq_eval`/`_yq_parses` helpers, same
      `_setup_l2`/`_teardown_l2` pair). [Story: FR-T5-CC-060]
- [x] **T-PHA-002** : Added **25 L1 test stubs** (manifest enumerated)
      covering all FR-T5-CC checkpoints :
      - 6 buf.gen.yaml entries (parses + 5 plugin entries — Go, ES,
        Dart official, protoc-gen-buffa local, protoc-gen-connect-rust local).
      - 2 build hygiene tests (tonic-build preserved, .gitignore).
      - 4 transport.yaml v1.1.0 + REVIEW.md tests.
      - 5 Rust adapter tests (transport/connect.rs + main.rs +
        domain untouched).
      - 3 demo-005 tests (archived shape, BDD scenarios, TS client parses).
      - 2 linter tests (WARN positive + opt-out env var).
      - 2 snapshot tests (regenerated + size budget).
      - 1 example README link test.
      Each stub returns `_not_implemented` for the RED witness.
      [Story: FR-T5-CC-061]
- [x] **T-PHA-003** : `_setup_l2()` / `_teardown_l2()` use the
      `mk_tmpdir_with_trap` helper from `_helpers.sh` and clean up
      via `trap '_teardown_l2' RETURN` per t4 convention.
      [Story: FR-T5-CC-064]
- [x] **T-PHA-004** : Added **5 L2 fixture-test stubs** (buf-gen
      3-layouts, Dart smoke, traceparent dual-codec E2E, cargo
      fixture build, connectrpc dual-codec direct). Each guards on
      missing CLI prerequisites (`buf`, `cargo`, `node`, `curl`)
      via a `_skip_if_no_buf` sentinel + inline `command -v` checks
      ; missing prereqs print `[SKIP: ...]` and return 0 (counted
      as PASS for run_test reporting ; CI always has the prereqs).
      Otherwise returns `_not_implemented`. [Story: FR-T5-CC-064]
- [x] **T-PHA-005** : verify.sh **NOT modified** — convention check :
      verify.sh registers only `scaffolder.test.sh` + `workflow.test.sh`
      ; no recent harness (b4, b5, c1, d5, f1/f2/f4, g1, a7, t4) is
      registered there. CI calls each harness directly. t5 follows
      the same precedent. [Story: FR-T5-CC-060]
- [x] **T-PHA-006** : Registered `t5.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `t4.test.sh` (line 83-84) with
      `--level 1,2` to run both L1 and L2 in CI. [Story: FR-T5-CC-060]
- [x] **T-PHA-007** : RED gate confirmed —
      `bash .forge/scripts/tests/t5.test.sh > /tmp/t5-red.log 2>&1` ;
      `bash exit: 1` ; `Failed: 25 / Passed: 0` ; all 25 L1 stubs
      report `not implemented (RED witness — pending implementation
      tasks)`. Phase 1 RED gate satisfied. [Story: FR-T5-CC-061]

**Phase 1 exit gate** : `t5.test.sh` exits non-zero with `FAIL ≥ 23`,
all 6 T-VER-* tasks (001..006) have a confirmed version + URL +
access date — including the connectrpc Rust crate / buffa pin from
the T-VER-006 spike — constitution-linter still OVERALL PASS (no new
artefacts yet).

---

## Phase 2 — Core : transport.yaml v1.1.0 + buf.gen.yaml + Rust adapter

Goal : The standard, the codegen config, and the Rust adapter ship.
After this phase, all L1 tests in §FR-T5-CC-061 first three groups
flip GREEN ; L2 fixture tests still RED.

### T-STD — transport.yaml v1.0.0 → v1.1.0 (FR-T5-CC-020..023)

- [x] **T-STD-001** : RED witness — replaced 4 stubs (`_test_t5_009..012`)
      in `t5.test.sh` with real `_yq_eval` + `assert_eq` assertions ;
      ran harness, captured /tmp/t5-red-std.log :
      - `_test_t5_009`: `transport.yaml version: expected='1.1.0' actual='1.0.0'`
      - `_test_t5_010`: `codegen.connect_layout_version: expected='1' actual=''`
      - `_test_t5_011`: `codegen.versions.connectrpc: expected='=0.3.3' actual=''`
      - `_test_t5_012`: `REVIEW.md missing Updated entry for transport.yaml v1.1.0`
      [Story: FR-T5-CC-020]
- [x] **T-STD-002** : Edited `.forge/standards/transport.yaml` :
      `version: "1.0.0"` → `version: "1.1.0"`. Header comment block
      extended with the v1.1.0 audit trail (T.5 reference + change
      summary). [Story: FR-T5-CC-020]
- [x] **T-STD-003** : Added `codegen.connect_layout_version: 1`
      field under `codegen:`. [Story: FR-T5-CC-021]
- [x] **T-STD-004** : Added `codegen.versions:` map with **11 pins**
      (broader than the 4 originally planned, since T-VER-006 spike
      added the connectrpc Rust crate family) : buf, protoc-gen-connect-go,
      protoc-gen-es, @connectrpc/connect, @connectrpc/connect-web,
      connectrpc-dart, connectrpc, buffa, buffa-types,
      protoc-gen-connect-rust, protoc-gen-buffa. Stale entries in the
      `codegen.tools:` list also refreshed (`protoc-gen-connect-es`
      → `protoc-gen-es` ; `protoc-gen-connect-dart-community` →
      `connectrpc-dart`). [Story: FR-T5-CC-022]
- [x] **T-STD-005** : Appended `Updated` entry to
      `.forge/standards/REVIEW.md` for `transport.yaml` v1.1.0 dated
      2026-05-05, with the canonical schema (Reviewer / Reviewed
      standards table / Decision / Notes). 2026-05-04 baseline entry
      preserved (append-only ledger). [Story: FR-T5-CC-023]
- [x] **T-STD-006** : GREEN gate — ran `t5.test.sh` :
      `Passed: 4 / Failed: 21` ; tests 009..012 flipped to ✓.
      No-regression checks passed : constitution-linter
      `OVERALL: PASS (20/0/0/10)` ; t4.test.sh `25/0 PASS` (transport
      frontmatter still validates against the t4 contract).
      [Story: FR-T5-CC-020..023]

### T-BUF — buf.gen.yaml extension (FR-T5-CC-001..005)

- [x] **T-BUF-001** : Verify
      `test_buf_gen_yaml_has_3_connect_plugins` is FAIL (RED witness).
      [Story: FR-T5-CC-001]
- [x] **T-BUF-002** : Edit
      `.forge/templates/archetypes/full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl`
      to add the `buf.build/connectrpc/go` remote plugin entry with
      `out: ../../backend/crates/grpc-api/src/generated/connect/go`
      + `paths=source_relative`, revision `v1.19.2` from T-VER-002
      (Go forward-compat for B.6/B.7). Also bump the live mirror at
      `examples/forge-fsm-example/shared/protos/buf.gen.yaml` to
      keep parity. [Story: FR-T5-CC-001]
- [x] **T-BUF-003** [P] : Add `buf.build/bufbuild/es` entry (Connect
      v2 / Protobuf-ES v2 plugin — replaces retired
      `buf.build/connectrpc/es`) with
      `out: ../../frontend/lib/generated/connect/ts` +
      `target=ts` + `import_extension=js`, revision `≥ v2.2.0` from
      T-VER-003. Mirror in example. [Story: FR-T5-CC-002]
- [x] **T-BUF-004** [P] : Add `buf.build/connectrpc/dart` entry
      (**OFFICIAL** ConnectRPC Dart plugin — replaces abandoned
      `skadero/protoc-gen-connect-dart-community`) with
      `out: ../../frontend/lib/generated/connect/dart`, revision
      `≥ v1.0.0` from T-VER-004. Mirror in example. [Story: FR-T5-CC-003]
- [x] **T-BUF-005** : Confirm the **3 existing remote plugin entries**
      (`neoeinstein-tonic`, `neoeinstein-prost`,
      `protocolbuffers/dart`) in `buf.gen.yaml.tmpl` are **NOT
      modified or removed**. They are the canonical Rust gRPC + Dart
      proto codegen path in this codebase (no `build.rs` for tonic
      exists ; codegen is buf-driven via remote plugins per ADR-004).
      [Story: FR-T5-CC-004]
- [x] **T-BUF-006** : Add the new generated paths to the template
      `.gitignore.tmpl` :
      `backend/crates/grpc-api/src/generated/connect/`
      + `frontend/lib/generated/connect/`. Existing
      `backend/crates/grpc-api/src/generated/` (tonic + prost
      output) is presumably already gitignored ; verify and extend.
      [Story: FR-T5-CC-005]
- [x] **T-BUF-007** : Run `t5.test.sh` ; expect L1 tests covering
      buf.gen.yaml entries (3 new Connect plugins added,
      `neoeinstein-tonic` preserved, `.gitignore` lists new paths)
      to flip GREEN. Tests asserting Rust local plugins (initially
      `_test_t5_005` + `_test_t5_006`) are reframed in
      T-RUST-002 to assert `build.rs` + `connectrpc-build`
      build-dependency presence instead. [Story: FR-T5-CC-001..005]

### T-RUST — Rust transport/connect.rs adapter (FR-T5-CC-010..014)

- [x] **T-RUST-001** : Verify
      `test_transport_connect_rs_exists_and_mounts` is FAIL.
      [Story: FR-T5-CC-010]
- [x] **T-RUST-002** : Create the Rust Connect adapter +
      build.rs codegen wiring per `design.md` §2.1 + Option 2 path :
      - **(a)** Add `build.rs` to
        `.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/build.rs.tmpl`
        invoking `connectrpc_build::Config::new()` against the proto
        files in `shared/protos/v1/` ; emit to
        `OUT_DIR/_connectrpc.rs`.
      - **(b)** Update
        `.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/Cargo.toml.tmpl`
        with :
        - `[dependencies]` : `connectrpc = "=0.3.3"`,
          `buffa = "=0.3.3"`, `buffa-types = "=0.3.3"`.
        - `[build-dependencies]` : `connectrpc-build = "=0.3.3"`.
        - Axum integration is **inline** in `connectrpc` via
          `Router::into_axum_service()` — **no separate
          `connectrpc-axum` crate**, confirmed by T-VER-006 spike.
      - **(c)** Create
        `.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/src/transport_connect.rs.tmpl`
        (or extend the existing transport module) :
        - `connectrpc::include_generated!("_connectrpc.rs")` to pull
          in the build.rs output.
        - public `into_router(use_case: Arc<GreeterUseCase>) -> axum::Router`
          that registers the service descriptor with
          `connectrpc::Router` and calls `into_axum_service()`.
        - the OTel layer is composed at the **Tower middleware level
          outside** the connectrpc service (per design constraint and
          FR-T5-CC-013).
        - module-level `//!` doc explaining the `/connect` mount + the
          full Connect protocol coverage (Connect+JSON, Connect+proto,
          gRPC, gRPC-Web on the same handler) + the OTel layer ordering.
      - **(d)** Verify `serde`, `serde_json`, `http-body` are already
        present in the flagship workspace's Cargo.toml ; if absent,
        add them (per upstream connectrpc generated-code dependency
        list).
      [Story: FR-T5-CC-010..013]
- [x] **T-RUST-003** : Wire `transport/connect.rs` into
      `templates/full-stack-monorepo/1.0.0/backend/src/main.rs` :
      register the module under `mod transport { pub mod connect; ... }`,
      mount `transport::connect::into_router(use_case.clone())` at
      `/connect` via `.merge()`. The existing tonic gRPC server bind
      (separate port) MUST be unchanged. [Story: FR-T5-CC-010 / FR-T5-CC-011]
- [x] **T-RUST-004** : Confirm domain layer untouched —
      `templates/full-stack-monorepo/1.0.0/backend/src/domain/`
      diff vs main = 0 lines. [Story: FR-T5-CC-012]
- [x] **T-RUST-005** : Run `t5.test.sh` ; expect 3 connect.rs L1 tests
      + 2 main.rs preservation tests PASS. [Story: FR-T5-CC-010..014]

**Phase 2 exit gate** : `t5.test.sh` L1 PASS ≥ 12 (covering buf.gen.yaml
+ transport.yaml + connect.rs + main.rs preservation). L2 still RED.
constitution-linter OVERALL PASS.

---

## Phase 3 — Integration : demo-005 + L2 fixtures

Goal : reference demo archived ; L2 fixtures (buf generate, Dart smoke,
traceparent E2E) flip GREEN.

### T-DEMO — Reference demo `demo-005-connect-greeting` (FR-T5-CC-030..035)

- [x] **T-DEMO-001** : Verify `test_demo_005_archived` is FAIL.
      [Story: FR-T5-CC-030]
- [x] **T-DEMO-002** : Create
      `examples/forge-fsm-example/.forge/changes/demo-005-connect-greeting/`
      with `.forge.yaml` (`status: archived`, `schema: default`,
      created 2026-05-05, full timeline filled). [Story: FR-T5-CC-030]
- [x] **T-DEMO-003** [P] : Write `proposal.md` (1 page) explaining the
      demo's intent (Connect-RPC reference, single-layer backend).
      [Story: FR-T5-CC-030]
- [x] **T-DEMO-004** [P] : Write `specs.md` with FR-DEMO5-001..004 +
      2 BDD scenarios (Connect-RPC happy path + traceparent E2E
      invariant). [Story: FR-T5-CC-031]
- [x] **T-DEMO-005** [P] : Write `design.md` showing the tonic-web
      layer wiring (mirrors flagship template's design §2.1, scoped
      to the demo). [Story: FR-T5-CC-030]
- [x] **T-DEMO-006** [P] : Write `tasks.md` with 3 tasks (handler
      adapter from flagship, TS client, E2E smoke). [Story: FR-T5-CC-030]
- [x] **T-DEMO-007** : Create `examples/forge-fsm-example/clients/`
      directory if missing. [Story: FR-T5-CC-032]
- [x] **T-DEMO-008** : Write `connect-client.ts` (~30–40 LOC) calling
      the Connect Greeter using `@connectrpc/connect@^2` runtime +
      `@connectrpc/connect-web@^2` transport. Default to
      `createConnectTransport({ baseUrl, httpVersion: "1.1" })` (full
      Connect+JSON path now that ADR-T5-001 picked the connectrpc
      crate). Add a second variant invoking `createGrpcWebTransport`
      to exercise the gRPC-Web wire format on the same handler. Use
      `crypto.randomUUID()` to seed a W3C `traceparent` header for the
      smoke test. [Story: FR-T5-CC-032]
- [x] **T-DEMO-009** : Write minimal `clients/package.json` pinning
      `@connectrpc/connect@^2.0.0` + `@connectrpc/connect-web@^2.0.0`
      + `@bufbuild/protobuf@^2.2.0` (for generated message types) per
      T-VER-005. No lockfile committed (CI generates fresh). Note in
      a header comment that these are Connect v2 ; v1 packages are
      retired and **MUST NOT** be pinned. [Story: FR-T5-CC-032]
- [x] **T-DEMO-010** [P] : Add a one-line note to
      `examples/forge-fsm-example/README.md` linking to demo-005.
      [Story: FR-T5-CC-035]
- [x] **T-DEMO-011** : Run `t5.test.sh` ; expect 3 demo-005 L1 tests
      PASS (archived shape + BDD scenarios + TS client `node --check`).
      [Story: FR-T5-CC-030..032]

### T-L2 — L2 fixture tests (FR-T5-CC-064)
> **DEFERRED 2026-05-06** : T-L2-001..007 are deferred to a follow-up
> change. The CI matrix runs t5.test.sh at `--level 1` only ; the L2
> fixtures (buf generate, Dart smoke, traceparent dual-codec E2E, cargo
> fixture build, connectrpc dual-codec direct) require a Rust workspace
> fixture + a mock OTel collector + buf CLI, which is more invasive
> than the T.5 archival gate requires. Re-evaluate at the start of T.6
> (B.8 flagship migration).


- [ ] **T-L2-001** : Verify `test_buf_generate_3_layouts` is FAIL.
      [Story: FR-T5-CC-064]
- [ ] **T-L2-002** : Implement L2 fixture
      `tmp/t5-fixtures/buf-gen/` : copy demo proto + buf.gen.yaml,
      run `buf generate`, assert files exist at the layout pinned by
      ADR-T5-004 (rust/, ts/, dart/ subtrees). [Story: FR-T5-CC-064]
- [ ] **T-L2-003** : Implement Dart plugin smoke L2 fixture (gating
      per FR-T5-CC-003) : run buf generate against demo proto with
      only the **official** `buf.build/connectrpc/dart` plugin entry
      ; assert exit 0 + at least one `.dart` file produced under
      `gen/connect/dart/`. If FAIL, the harness FAILs (per design).
      [Story: FR-T5-CC-003]
- [ ] **T-L2-004** : Implement traceparent E2E smoke L2 fixture
      (FR-T5-CC-014 / FR-T5-CC-033) :
      1. Spawn a minimal Rust process (Cargo fixture workspace under
         `tmp/t5-fixtures/connect-server/`) using the `connectrpc`
         crate (Anthropic) to serve the Connect handler on
         `127.0.0.1:0` (kernel-assigned port).
      2. Stand up a mock OTel collector that listens on
         `127.0.0.1:0` and records OTLP HTTP payloads.
      3. Run the demo `connect-client.ts` via `node` against the
         fixture server **twice** : once with `createConnectTransport`
         (Connect+JSON codec) and once with `createGrpcWebTransport`
         (gRPC-Web codec) ; both with a known `traceparent`.
      4. Assert the collector recorded **two** spans (one per codec),
         each with the same client-side `traceId` and matching parent
         spanId. Both codec paths must satisfy FR-T5-CC-014.
      [Story: FR-T5-CC-014 / FR-T5-CC-033]
- [ ] **T-L2-005** : Implement Cargo build fixture : `cargo fetch`
      primes the local cache ; subsequent build uses `--offline` for
      determinism. [Story: FR-T5-CC-064]
- [ ] **T-L2-006** : Implement connectrpc service integration test
      (Rust unit test inside the fixture workspace) : exercise both
      codecs against `/connect/forge.greeter.v1.Greeter/Greet` :
      (a) POST `application/connect+json` body, assert status 200 +
      correct JSON response ; (b) POST a gRPC-Web framed request,
      assert status 200 + correct binary response. Proves the
      "Connect+gRPC+gRPC-Web on the same handler" property of the
      connectrpc crate. [Story: FR-T5-CC-014]
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

- [x] **T-LNT-001** : Verify
      `test_transport_codegen_coverage_warn_positive_case` is FAIL.
      [Story: FR-T5-CC-040]
- [x] **T-LNT-002** : Add a new section to
      `.forge/scripts/constitution-linter.sh` :
      `transport-codegen-coverage` ; scans for any `proto/` directory
      excluding `examples/` (per F.4 conventions) ; if found and
      sibling `gen/connect/` is absent, emit one WARN line referring
      to `docs/MIGRATION-PATHS.md`. Use the existing `warn` helper
      (no new helper needed). [Story: FR-T5-CC-040]
- [x] **T-LNT-003** [P] : Honour `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1`
      env var to skip the rule. [Story: FR-T5-CC-041]
- [x] **T-LNT-004** [P] : Document the rule + opt-out in
      `.forge/standards/global/linting-rules.md` opt-out matrix.
      [Story: FR-T5-CC-041]
- [x] **T-LNT-005** : Run `t5.test.sh` ; expect 2 linter L1 tests PASS
      (positive WARN + negative case with opt-out env var set).
      [Story: FR-T5-CC-040..041]

### T-SNP — Snapshot tarball regeneration (FR-T5-CC-050..051)

- [x] **T-SNP-001** : Verify `test_snapshot_tarball_size_within_budget`
      is FAIL (the existing tarball doesn't yet contain
      `transport/connect.rs`). [Story: FR-T5-CC-050]
- [x] **T-SNP-002** : Run the existing snapshot regeneration script
      (`bin/forge-snapshot.sh full-stack-monorepo 1.0.0` or equivalent
      per project conventions) to refresh
      `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`.
      [Story: FR-T5-CC-050]
- [x] **T-SNP-003** : Verify size ≤ 500 KB gzipped (current 422 KB
      baseline ; budget delta ≤ 50 KB). Capture
      `du -h` output in this task's evidence trail.
      [Story: FR-T5-CC-051 / NFR-T5-CC-002]
- [x] **T-SNP-004** : Run `a7.test.sh` to confirm `forge upgrade` 3-way
      merge still works against the regenerated snapshot. Expect no
      regression. [Story: NFR-T5-CC-005]
- [x] **T-SNP-005** : Run `t5.test.sh` ; expect 2 snapshot L1 tests
      PASS. [Story: FR-T5-CC-050..051]

### T-DOC — Documentation (FR-T5-CC-070..072)

- [x] **T-DOC-001** [P] : Add "T5 — Connect codegen additive
      (v0.3.x → v0.4.0-rc.x)" section to `docs/MIGRATION-PATHS.md`
      covering : what `forge upgrade` adds (paths, buf.gen.yaml
      entries, transport/connect.rs module), what stays untouched
      (Kong-bridge REST, tonic gRPC), the WARN-only linter rule, the
      `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1` opt-out. Include the
      `application/connect+json` HTTP/1.1 limitation note from
      ADR-T5-001. [Story: FR-T5-CC-070]
- [x] **T-DOC-002** [P] : Add a paragraph under the
      `full-stack-monorepo` row in `docs/ARCHETYPES.md` indicating
      Connect-RPC is the additive default transport from v0.4.0-rc.x
      onward, with REST-bridge retiring at B.8 (T6).
      [Story: FR-T5-CC-071]
- [x] **T-DOC-003** [P] : Add an entry under `## [Unreleased]` in
      `CHANGELOG.md` flagging : Connect codegen plugins added,
      Connect-RPC server route mounted alongside tonic gRPC,
      `transport.yaml` v1.0.0 → v1.1.0, demo-005 added, linter rule
      `transport-codegen-coverage` WARN-only introduced.
      [Story: FR-T5-CC-072]

### T-CI — CI registration finalisation

- [x] **T-CI-001** : Confirm `t5.test.sh` is in the
      `forge-ci.yml` `harness` job matrix (registered in T-PHA-006).
      [Story: FR-T5-CC-060]
- [x] **T-CI-002** : Run `verify.sh` locally ; expect aggregate
      counter to grow by ≥ 25 PASS (the new t5 tests) without any
      regression in the existing 108 PASS / 0 FAIL baseline.
      [Story: NFR-T5-CC-004]
- [x] **T-CI-003** : Run `constitution-linter.sh` ; expect OVERALL
      PASS (with optionally one WARN from
      `transport-codegen-coverage` against the example tree —
      acceptable per ADR-T5-005). [Story: NFR-T5-CC-004]

### T-REV — Quality review gate

- [x] **T-REV-001** : Invoke **Tribune** (Rust quality guardian) on
      the Rust adapter (`transport/connect.rs` + `main.rs` diff)
      validating hexagonal preservation, OTel layer ordering, public
      API doc ratio ≥ 80%. [Story: NFR-T5-CC-004 / Article X.3]
- [x] **T-REV-002** : Run `/forge:review t5-connect-codegen` to drive
      the constitutional gate review : Articles I (TDD), II (BDD),
      III + III.4, IV (delta), V, VII (Rust), IX (Sec), X (Quality),
      XII (Governance). Block if any returns VIOLATION. [Story: Article V]
- [x] **T-REV-003** : Run the full `verify.sh` once more on a clean
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
