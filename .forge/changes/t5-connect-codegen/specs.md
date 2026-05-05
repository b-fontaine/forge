# Specifications: t5-connect-codegen
<!-- Status: specified -->
<!-- Schema: default -->

## Source Documents

This change descends from two ratified sources :

| Field           | Value                                                                                                |
|-----------------|------------------------------------------------------------------------------------------------------|
| **ADR base**    | `t4-adr-ratification` archived 2026-05-05 (FR-T4-ADR-003 + FR-T4-ADR-009 + FR-T4-STD-001 transport)  |
| **Plan ref**    | `docs/new-archetypes-plan.md` §11 Phase 1 + §15 item #1 (T5 first concrete action)                   |
| **Roadmap ref** | `.forge/product/roadmap.md` Phase 3 / T5 row                                                         |
| **Standard**    | `.forge/standards/transport.yaml` v1.0.0 (baseline ; this change bumps to v1.1.0)                    |

No new external source document is pinned by this change ; it consumes the
T4 baseline. ADR-003 + ADR-009 line ranges are already pinned through
`t4-adr-ratification/specs.md` Source Document table.

---

## ADDED Requirements

### Functional Requirements

#### Group 1 — `buf.gen.yaml` Connect codegen extension (FR-T5-CC-001 → 005)

Targets the flagship template
`templates/full-stack-monorepo/1.0.0/proto/buf.gen.yaml`. All edits are
additive ; no existing plugin entry is removed.

##### FR-T5-CC-001: `protoc-gen-connect-go` plugin entry
- **MUST** add a `plugins:` entry generating Go-flavoured Connect stubs
  that the Rust workspace consumes via the established `tonic-build` →
  Rust path (server-side handler skeletons).
- **MUST** pin the plugin version (Q-002) in `transport.yaml` `codegen.versions`.
- **MUST** declare `out:` under `gen/connect/rust/` (per FR-T5-CC-005 layout).

##### FR-T5-CC-002: `protoc-gen-connect-es` plugin entry
- **MUST** add a `plugins:` entry generating TypeScript Connect stubs.
- **MUST** pin the plugin version in `transport.yaml` `codegen.versions`.
- **MUST** declare `out:` under `gen/connect/ts/`.
- **MUST** include `opt: target=ts` (no JS-only output) per Q-004 resolution.

##### FR-T5-CC-003: `protoc-gen-connect-dart-community` plugin entry (gated)
- **MUST** add a `plugins:` entry generating Dart Connect stubs.
- **MUST** pin the plugin version in `transport.yaml` `codegen.versions`.
- **MUST** declare `out:` under `gen/connect/dart/`.
- **MUST** be guarded by an L2 smoke test in `t5.test.sh` : if the
  plugin fails at codegen time against the demo proto, the change blocks
  archive (does not auto-disable the entry).
- **MUST NOT** be consumed by any template in this change (forward-compat
  only ; mobile-only / 1.0.0 untouched).

##### FR-T5-CC-004: `tonic-build` invocation preserved
- **MUST NOT** modify the existing tonic-build path in
  `templates/full-stack-monorepo/1.0.0/backend/build.rs` (or equivalent).
- **MUST** keep the existing gRPC service generation as the canonical
  Rust server-side codegen path (ADR-004).
- **MUST** ensure both `gen/connect/` outputs and `tonic-build` outputs
  coexist in the workspace `.gitignore` policy (both ignored ; both
  regenerable).

##### FR-T5-CC-005: Output layout `gen/connect/{rust,ts,dart}/`
- **MUST** declare a stable layout pinned in `transport.yaml`
  `codegen.connect_layout_version: 1`.
- **MUST** organise outputs as `gen/connect/{rust|ts|dart}/<package>/<service>.connect.<ext>`
  (flat-by-language, nested-by-package). Q-004 resolution.
- **MUST** add `gen/connect/` to the template `.gitignore`.
- **MUST** be referenced from a new section in `docs/MIGRATION-PATHS.md`.

#### Group 2 — Rust Connect-RPC server route (FR-T5-CC-010 → 014)

##### FR-T5-CC-010: Parallel axum route
- **MUST** add a new module
  `templates/full-stack-monorepo/1.0.0/backend/src/transport/connect.rs`
  exposing a Connect-RPC handler for the existing Greeter use case.
- **MUST** mount the handler under `/connect` on the existing axum
  router (separate path prefix from REST-bridge `/api`).
- **MUST** preserve the existing tonic gRPC server on its own port (no
  port collision ; documented in `design.md`).

##### FR-T5-CC-011: tonic gRPC service kept on its own port
- **MUST NOT** remove or modify
  `templates/full-stack-monorepo/1.0.0/backend/src/main.rs` mounting of
  the tonic Greeter service.
- **MUST** keep the gRPC server bound to its current port unchanged.

##### FR-T5-CC-012: Hexagonal preservation
- **MUST** treat the Connect handler as an *adapter* under
  `transport/` ; the `Greeter` use case in the domain layer is
  unchanged and shared between gRPC and Connect adapters.
- **MUST** not introduce any direct dependency from domain to Connect
  crate (Article VII compliance).

##### FR-T5-CC-013: OTel middleware on Connect handler
- **MUST** wrap the Connect handler with the existing
  `tower-http::trace` + `tracing-opentelemetry` layer used by the REST
  side, producing OTel spans with attribute `transport=connect`.
- **MUST** ensure the OTel middleware order is documented in
  `design.md` (Connect codec must run after the trace layer to capture
  request boundaries).

##### FR-T5-CC-014: traceparent W3C end-to-end propagation
- **MUST** propagate W3C `traceparent` headers from the TypeScript
  client (demo-005) through Kong to the Connect handler and onward to
  any downstream call.
- **MUST** be validated by an L2 smoke test in `t5.test.sh` against a
  fixture spawning a SigNoz-less collector that asserts a single
  `traceId` is observed across the chain.

#### Group 3 — `transport.yaml` v1.0.0 → v1.1.0 (FR-T5-CC-020 → 023)

##### FR-T5-CC-020: Version bump
- **MUST** update `version: "1.0.0"` → `version: "1.1.0"` in
  `.forge/standards/transport.yaml` (additive change, no breaking).
- **MUST NOT** change `exception_constitutional`, `expires_at: never`,
  `protocol`, `fallback`, or `http_versions` keys.

##### FR-T5-CC-021: `codegen.connect_layout_version` field added
- **MUST** add `codegen.connect_layout_version: 1` to
  `transport.yaml`.
- **MUST** match the layout described in FR-T5-CC-005.

##### FR-T5-CC-022: Plugin version pins
- **MUST** add `codegen.versions:` map pinning the three Connect plugin
  versions (`protoc-gen-connect-go`, `protoc-gen-connect-es`,
  `protoc-gen-connect-dart-community`) plus the `buf` CLI version.
- **MUST** match the versions declared in `buf.gen.yaml` (cross-checked
  by `t5.test.sh`).
- Concrete pin values resolved at design time (Q-002).

##### FR-T5-CC-023: `REVIEW.md` Updated entry
- **MUST** append an `Updated` entry (not a new review) to
  `.forge/standards/REVIEW.md` for `transport.yaml`, recording the
  v1.1.0 bump and the date 2026-05-05.
- **MUST NOT** alter the `Reviewed on: 2026-05-04` baseline entry
  (immutable ledger).

#### Group 4 — Reference demo `demo-005-connect-greeting` (FR-T5-CC-030 → 035)

##### FR-T5-CC-030: Change archived in example tree
- **MUST** be created at
  `examples/forge-fsm-example/.forge/changes/demo-005-connect-greeting/`.
- **MUST** ship `proposal.md`, `specs.md`, `design.md`, `tasks.md`,
  `.forge.yaml` with `status: archived`.
- **MUST** be a single-layer backend change (no `layers:` declaration
  beyond the default — no Janus orchestration needed).

##### FR-T5-CC-031: BDD scenarios
- **MUST** ship at least 2 Gherkin scenarios in `specs.md` covering
  the Connect-RPC happy path and the traceparent propagation
  invariant.

##### FR-T5-CC-032: Minimal TypeScript client
- **MUST** ship a TypeScript file
  `examples/forge-fsm-example/clients/connect-client.ts` (or similar
  contained location) calling the Connect-RPC Greeter.
- **MUST** depend only on `@connectrpc/connect` + `@connectrpc/connect-web`
  (or current equivalent) — no Qwik, no React, no SvelteKit.
- **MUST NOT** ship a `package.json` lockfile in a way that bloats the
  example beyond NFR-T5-CC-002.

##### FR-T5-CC-033: traceparent end-to-end smoke test
- **MUST** be implemented in `t5.test.sh` as an L2 fixture spinning up
  a minimal Rust process serving the Connect handler + a Node script
  acting as the TS client.
- **MUST** assert that one `traceparent` header originates client-side
  and is preserved unchanged in the OTel span emitted server-side.

##### FR-T5-CC-034: Overlay budget
- **MUST** keep the demo-005 overlay diff under 100 KB added to
  `examples/forge-fsm-example/` (including generated stubs that ship in
  the example tree, if any).

##### FR-T5-CC-035: Cross-link from existing demos
- **MUST** add a one-line note in `examples/forge-fsm-example/README.md`
  pointing to demo-005 as the Connect-RPC reference.

#### Group 5 — Constitution-linter `transport-codegen-coverage` (FR-T5-CC-040 → 041)

##### FR-T5-CC-040: New WARN-only linter section
- **MUST** add a section to `constitution-linter.sh` that scans any
  scaffolded project (excluding `examples/` per F.4 conventions) and
  emits a WARN if `proto/` exists but `gen/connect/` is absent.
- **MUST** emit `WARN` only ; **MUST NOT** emit `FAIL`.
- **MUST** point the user to `docs/MIGRATION-PATHS.md` Connect section.

##### FR-T5-CC-041: Opt-out env var
- **MUST** honour `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1` to skip the
  rule entirely (consistent with F.4 opt-out matrix).
- **MUST** be documented in `.forge/standards/global/linting-rules.md`.

#### Group 6 — Snapshot tarball update (FR-T5-CC-050 → 051)

##### FR-T5-CC-050: Snapshot regenerated
- **MUST** regenerate
  `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` after
  template edits (FR-T5-CC-001..014) so `forge upgrade` reverse path
  remains functional.
- **MUST NOT** create a new schema slot (`2.0.0/`) — that ships in B.8
  (T6).

##### FR-T5-CC-051: Snapshot size budget
- **MUST** keep the tarball under 500 KB gzipped (current : 422 KB ;
  budget delta ≤ 50 KB).

#### Group 7 — Test harness `t5.test.sh` (FR-T5-CC-060 → 064)

##### FR-T5-CC-060: Harness file location
- **MUST** be created at `.forge/scripts/harnesses/t5.test.sh`.
- **MUST** be registered in `.github/workflows/forge-ci.yml` under the
  `harness` job matrix.
- **MUST** be registered in `verify.sh` aggregated pass count.

##### FR-T5-CC-061: Harness coverage (≥ 25 tests)
- **MUST** include at least :
  - 5 tests : `buf.gen.yaml` parses + each of the 3 plugin entries
    present + `tonic-build` invocation preserved + layout matches
    `transport.yaml` `codegen.connect_layout_version`.
  - 4 tests : `transport.yaml` v1.1.0 (parses, version bumped,
    `codegen.versions` pinned, layout pinned).
  - 3 tests : Connect handler module exists, mounted under `/connect`,
    OTel middleware present.
  - 2 tests : tonic gRPC server unchanged (port + service registration
    preserved).
  - 3 tests : demo-005 archived, BDD scenarios present, TS client
    parses (Node `--check`).
  - 2 tests : `transport-codegen-coverage` linter rule WARN behaviour
    (positive and negative case).
  - 2 tests : snapshot tarball regenerated and size budget respected.
  - 2 tests : L2 fixture — buf generate against frozen demo proto
    produces expected files in 3 layouts.
  - 1 test : L2 fixture — Connect-RPC end-to-end traceparent smoke test
    (FR-T5-CC-033).
  - 1 test : L2 fixture — Dart plugin smoke (FR-T5-CC-003).

##### FR-T5-CC-062: Harness performance budget
- **MUST** complete in ≤ 5 seconds wall-clock on a baseline laptop
  for L1 tests.
- **MUST** complete in ≤ 30 seconds wall-clock including L2 fixtures
  (buf generate + Node smoke + Cargo build of a minimal fixture
  workspace).
- **MAY** mark L2 tests `SKIP` if `buf` CLI absent (CI-only execution).

##### FR-T5-CC-063: Output format
- **MUST** match the L1/L2 PASS/FAIL/SKIP convention used by existing
  harnesses (t4.test.sh, f4.test.sh).

##### FR-T5-CC-064: L2 fixture coverage
- **MUST** include at least 5 L2 fixture-based tests using a temporary
  `tmp/t5-fixtures/` directory (created and torn down by the harness).

#### Group 8 — Documentation (FR-T5-CC-070 → 072)

##### FR-T5-CC-070: `docs/MIGRATION-PATHS.md` extension
- **MUST** add a section "T5 — Connect codegen additive (v0.3.x → v0.4.0-rc.x)"
  documenting :
  - what `forge upgrade` adds (new `gen/connect/` paths, extended
    `buf.gen.yaml`, optional Connect handler module).
  - what stays untouched (Kong-bridge REST API, tonic gRPC).
  - the WARN-only linter rule and how to opt out.

##### FR-T5-CC-071: `docs/ARCHETYPES.md` note
- **MUST** add a one-paragraph note under the `full-stack-monorepo`
  row indicating Connect-RPC is the additive default transport from
  v0.4.0-rc.x onward, with REST-bridge retiring at B.8 (T6).

##### FR-T5-CC-072: CHANGELOG entry
- **MUST** add an entry under `## [Unreleased]` in `CHANGELOG.md`
  flagging :
  - Connect codegen plugins added to flagship `buf.gen.yaml`.
  - Connect-RPC server route mounted alongside tonic gRPC.
  - `transport.yaml` v1.0.0 → v1.1.0.
  - Reference demo-005 added.
  - `transport-codegen-coverage` WARN-only linter rule introduced.

### Non-Functional Requirements

##### NFR-T5-CC-001: Harness performance
- L1 portion of `t5.test.sh` ≤ 5 s wall-clock. Full run including L2
  fixtures ≤ 30 s. Verified by `time bash` in CI.

##### NFR-T5-CC-002: Snapshot delta
- Snapshot tarball delta ≤ 50 KB gzipped vs baseline 422 KB.

##### NFR-T5-CC-003: File budget
- Total NEW files ≤ 25 :
  - 1 `transport/connect.rs` Rust module.
  - 1 `clients/connect-client.ts` TS client (in example tree).
  - 5 demo-005 files (`.forge.yaml`, `proposal.md`, `specs.md`,
    `design.md`, `tasks.md`).
  - 1 `t5.test.sh` harness.
  - ≤ 10 fixture files under `tmp/t5-fixtures/` (gitignored ; not
    counted toward source budget).
  - 1 `MIGRATION-PATHS.md` section, 1 `ARCHETYPES.md` paragraph,
    1 CHANGELOG entry (modifications, not new files).
- Modified files ≤ 8 : `buf.gen.yaml`, `transport.yaml`, `REVIEW.md`,
  `verify.sh`, `constitution-linter.sh`, `forge-ci.yml`, `linting-rules.md`,
  snapshot tarball.

##### NFR-T5-CC-004: Backward compatibility
- All 14 archived changes' validation MUST keep passing (verified by
  `f2.test.sh` aggregate).
- All 4 existing demos in `examples/forge-fsm-example/` MUST keep
  passing (verified by their respective harnesses + `c1.test.sh`).
- `verify.sh` aggregate counter MUST grow only through new t5 tests
  (no regression in existing 108 PASS / 0 FAIL baseline).

##### NFR-T5-CC-005: Zero adopter runtime breakage
- An adopter project running `forge upgrade` from v0.3.0 to this
  change MUST exit 0 against the example fixture (no required
  manual conflict resolution beyond what `forge upgrade` already
  surfaces for hand-customised routers — those produce conflict
  markers, not failure).

##### NFR-T5-CC-006: Schema unchanged
- Flagship schema stays at `1.0.0`. No `2.0.0/` directory created.
- `archetype.schema.json` v2 untouched.

##### NFR-T5-CC-007: Generated stub size
- For the demo-005 proto (single Greeter service, ≤ 50 lines of
  proto), generated stubs across the 3 languages MUST not exceed
  500 KB total in the example tree.

##### NFR-T5-CC-008: Constitution unchanged
- Constitution stays at v1.1.0. No bump to v1.2.0.

##### NFR-T5-CC-009: Connect handler latency budget
- The Connect handler MUST add ≤ 5 ms p50 overhead vs the REST-bridge
  baseline on a localhost benchmark against the Greeter service.
  Verified during `/forge:review` (NOT a CI gate — informational
  only ; B.8 will gate p99 / 20 % regression).

##### NFR-T5-CC-010: Plugin version traceability
- Every plugin version pinned in `transport.yaml` `codegen.versions`
  MUST be reachable via a public release notes URL recorded in
  `design.md` (Q-002 evidence trail).

---

## MODIFIED Requirements

### `transport.yaml` v1.0.0 → v1.1.0

Previously :
```yaml
version: "1.0.0"
codegen:
  source_of_truth: protobuf
  tools:
    - buf
    - protoc-gen-connect-go
    - protoc-gen-connect-es
    - protoc-gen-connect-dart-community
    - tonic-build
  derived_outputs: [openapi-3.1, asyncapi-3.1]
```

Now :
```yaml
version: "1.1.0"
codegen:
  source_of_truth: protobuf
  connect_layout_version: 1
  tools:
    - buf
    - protoc-gen-connect-go
    - protoc-gen-connect-es
    - protoc-gen-connect-dart-community
    - tonic-build
  versions:                # pinned per FR-T5-CC-022, values resolved in design.md (Q-002)
    buf: "<pinned>"
    protoc-gen-connect-go: "<pinned>"
    protoc-gen-connect-es: "<pinned>"
    protoc-gen-connect-dart-community: "<pinned>"
  derived_outputs: [openapi-3.1, asyncapi-3.1]
```

Reason : ADR-009 + ADR-003 prescribe Connect codegen ; T5 ships it
additively. The new `connect_layout_version: 1` and `versions:` keys
formalise the codegen contract so `t5.test.sh` and adopters can rely
on a stable layout. No `forbidden:` modification.

### `templates/full-stack-monorepo/1.0.0/proto/buf.gen.yaml`

Previously : `tonic-build` only, no Connect plugin entry.

Now : 3 additional `protoc-gen-connect-*` plugin entries with stable
output paths (FR-T5-CC-001..005). Existing tonic-build invocation
unchanged.

Reason : enable Connect codegen alongside the existing gRPC pipeline.

---

## REMOVED Requirements

None.

This change is **strictly additive** per the Phase 1 ARCH §11
discipline. The Kong-bridge REST API, the tonic gRPC service, and the
existing demos all stay in place. Removal of Kong + REST-bridge happens
in B.8 (T6).

---

## Acceptance Criteria (BDD)

### Scenario: TypeScript client successfully calls Connect-RPC Greeter

```gherkin
Given the flagship template `full-stack-monorepo / 1.0.0` is scaffolded
  And the Rust backend is running with the Connect-RPC route mounted at /connect
  And `buf generate` has produced TS stubs in `gen/connect/ts/`
When a TypeScript client invokes `GreeterClient.greet({ name: "Forge" })`
Then the response payload contains `message: "Hello, Forge"`
  And the response status is OK
  And the response Content-Type is `application/connect+proto` or `application/connect+json`
```

### Scenario: traceparent W3C header is preserved end-to-end

```gherkin
Given a Connect-RPC client emits an outbound request with header `traceparent: 00-<traceId>-<spanId>-01`
  And the Rust backend has OTel middleware enabled
When the request reaches the Connect handler
Then the OTel span emitted server-side carries the same `<traceId>`
  And the parent span ID matches the client's `<spanId>`
  And no traceparent header is dropped or rewritten between Kong and the handler
```

### Scenario: Existing tonic gRPC client still works (regression guard)

```gherkin
Given the flagship template post-upgrade has both Connect and tonic mounted
  And a Dart Flutter client (demo-002) calls the tonic gRPC Greeter on the legacy port
When the call is issued
Then the response is received unchanged from the v0.3.0 baseline
  And no new traceparent format is required
  And the existing demo-002 BDD scenario keeps passing
```

### Scenario: Adopter runs `forge upgrade` from v0.3.0 to v0.4.0-rc.1

```gherkin
Given a project scaffolded via `@sdd-forge/cli@0.3.0` archetype `full-stack-monorepo`
  And the project has not customised `proto/buf.gen.yaml` or `backend/src/transport/`
When the adopter runs `npx @sdd-forge/cli@latest upgrade`
Then `forge upgrade` adds the 3 Connect plugin entries to `buf.gen.yaml`
  And `forge upgrade` adds `gen/connect/` to `.gitignore`
  And `forge upgrade` adds the `transport/connect.rs` module to the backend
  And `forge upgrade` does NOT modify `kong/kong.yml` or the REST-bridge handler
  And `forge upgrade` exit code is 0
```

### Scenario: Adopter has hand-customised the axum router

```gherkin
Given a project scaffolded via v0.3.0 has hand-edited `backend/src/main.rs` with custom routes
When the adopter runs `forge upgrade`
Then `forge upgrade` produces conflict markers in `backend/src/main.rs` only at the router-mount line
  And `forge upgrade` writes a `.merge-conflicts` companion file
  And the adopter receives a clear remediation instruction in the output
  And `forge upgrade` exit code is non-zero (conflict signalled)
```

### Scenario: Dart plugin smoke fails at codegen time

```gherkin
Given `protoc-gen-connect-dart-community` returns a non-zero exit during `buf generate` against the demo proto
When `t5.test.sh` runs the Dart smoke L2 fixture
Then the test FAILs with message "protoc-gen-connect-dart-community codegen failed against demo proto"
  And the harness exit code is non-zero
  And the change cannot be archived (verify.sh blocks)
```

### Scenario: `transport-codegen-coverage` linter warns on adopter project

```gherkin
Given an adopter project has `proto/` populated with .proto files
  And the project has no `gen/connect/` directory
When the adopter runs `bash .forge/scripts/constitution-linter.sh`
Then the linter emits exactly one WARN line "transport-codegen-coverage: gen/connect/ missing, run `buf generate`"
  And exit code is 0 (warn does not fail)
  And the warning is suppressed if `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1`
```

---

## Anti-hallucination pass

- Every FR is testable via `t5.test.sh` ; coverage is enumerated in
  Group 7 (FR-T5-CC-061).
- No FR depends on an un-shipped agent (Demeter K.3, Hermes-Async K.1,
  Pythia K.2, Iris-Web K.4, Themis K.5 are out of scope).
- No FR depends on B.8 deliverables (Envoy, DBOS, Zitadel, Postgres
  +pgvector default, Qwik public web).
- Constitution articles I, III, IV, V, VII, IX, X, XII are explicitly
  addressed in `proposal.md::Constitution Compliance`. II covered via
  BDD scenarios (Acceptance Criteria above). VI / VIII / XI declared
  inapplicable in `proposal.md`.
- All concrete plugin version pins (FR-T5-CC-022) and the choice of
  Connect-Rust crate (Q-001) are deliberately deferred to `design.md`
  ; this `specs.md` declares the *requirement to pin* without
  prescribing the *exact pin* — preventing premature commitment to
  potentially stale versions.
- `[NEEDS CLARIFICATION:]` markers : none in this `specs.md`. Four
  open questions Q-001..Q-004 tracked in `open-questions.md`, all
  marked `Status: open` ; resolution required before `/forge:design`
  finalises.
