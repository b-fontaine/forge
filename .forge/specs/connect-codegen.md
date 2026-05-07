# Spec: connect-codegen

<!-- Audit: T.5 (t5-connect-codegen) — Connect-RPC additive transport for full-stack-monorepo / 1.0.0. -->
<!-- This file accumulates the archived requirements for the Connect-RPC      -->
<!-- additive transport on the flagship archetype. Source change :            -->
<!-- `.forge/changes/t5-connect-codegen/` (archived 2026-05-06).               -->
<!-- First Phase 1 ARCHITECTURE-TARGET item (additive, no path retired).      -->

**Namespace** : `FR-T5-CC-*` / `NFR-T5-CC-*`.

**Constitution** : v1.1.0 (no bump per NFR-T5-CC-008).

**Phase position** : Phase 1 of `docs/ARCHITECTURE-TARGET.md` migration plan ;
fully reversible, no path retired. The breaking codec swap (Kong → Envoy,
Temporal → DBOS, REST/JSON Kong-bridge → Connect-only) ships in B.8 (T6).

**Pin family** : `connectrpc / buffa / buffa-types / connectrpc-build = "=0.3.3"`
(Anthropic OSS, Apache-2.0, MSRV Rust 1.88, 6 558 conformance tests). Inline
`WAIVER 2026-05-05` in `.forge/standards/transport.yaml` documents the
13-day age waiver of ADR-T5-002 #1 (criterion deferred to monitoring of
upstream 0.4.x via the standard review window).

---

## Functional Requirements

### Group 1 — buf.gen.yaml plugins (FR-T5-CC-001..005)

- **FR-T5-CC-001** — `buf.build/connectrpc/go:v1.19.2` plugin entry in
  `templates/full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl` for
  Go forward-compat (B.6 / B.7).
- **FR-T5-CC-002** — `buf.build/bufbuild/es:v2.2.0` plugin entry
  (Connect v2 / Protobuf-ES v2 ; the legacy `protoc-gen-connect-es`
  is retired by Connect v2 migration).
- **FR-T5-CC-003** — `buf.build/connectrpc/dart:v1.0.0` plugin entry
  (OFFICIAL ConnectRPC Dart plugin, replaces abandoned
  `skadero/protoc-gen-connect-dart-community`).
- **FR-T5-CC-004** — Existing Rust gRPC remote-plugin codegen
  (`neoeinstein-tonic`, `neoeinstein-prost`, `protocolbuffers/dart`)
  preserved untouched (ADR-004 KEEP).
- **FR-T5-CC-005** — Output layout `gen/connect/{rust,ts,dart}/<proto-package>/`
  pinned via `transport.yaml::codegen.connect_layout_version: 1`.
  Generated paths added to template `.gitignore.tmpl` (NOT committed).

### Group 2 — Rust transport adapter (FR-T5-CC-010..014)

- **FR-T5-CC-010** — `crates/grpc-api/src/transport_connect.rs.tmpl`
  exposes `pub fn into_router<U, L: Layer<...>>(_use_case: Arc<U>, tracing_layer: L) -> axum::Router`
  using `connectrpc::Router::into_axum_service()` (inline ; no separate
  `connectrpc-axum` crate per T-VER-006 spike).
- **FR-T5-CC-011** — tonic gRPC server bind on port 50051 preserved
  in `bin-server/src/main.rs.tmpl` (ADR-004 KEEP) ; the Connect
  adapter mounts on a separate axum router under `/connect`.
- **FR-T5-CC-012** — Domain layer (`crates/domain`) untouched ; no
  template files under `crates/domain` (Article VII hexagonal
  preservation).
- **FR-T5-CC-013** — The tracing layer is applied **outside** the
  `connectrpc::Router` (Tower middleware composition on the outer
  `axum::Router` returned by `into_router`). The seed ships
  `tower_http::trace::TraceLayer` as a generic HTTP placeholder ;
  adopters swap for `axum_tracing_opentelemetry::OtelAxumLayer` to
  satisfy FR-T5-CC-014.
- **FR-T5-CC-014** — Once the OTel layer is wired, traceparent W3C
  end-to-end propagation MUST hold for both `application/connect+json`
  and `application/grpc-web` codecs. Validation deferred to L2 fixture
  in a follow-up change (see DEFERRED note in `tasks.md::T-L2`).

### Group 3 — Standard `transport.yaml` v1.1.0 (FR-T5-CC-020..023)

- **FR-T5-CC-020** — Bump `version: "1.0.0"` → `"1.1.0"` (additive ; no
  breaking change ; structural exception preserved).
- **FR-T5-CC-021** — `codegen.connect_layout_version: 1` field added.
- **FR-T5-CC-022** — `codegen.versions:` map with 11 toolchain pins
  (buf, protoc-gen-connect-go, protoc-gen-es, @connectrpc/connect,
  @connectrpc/connect-web, connectrpc-dart, connectrpc, buffa,
  buffa-types, connectrpc-build, plus the inline `WAIVER 2026-05-05`
  block).
- **FR-T5-CC-023** — `.forge/standards/REVIEW.md` ledger receives an
  `Updated` entry dated 2026-05-05 (append-only, Article XII).

### Group 4 — Reference demo `demo-005-connect-greeting` (FR-T5-CC-030..035)

- **FR-T5-CC-030** — Archived demo under
  `examples/forge-fsm-example/.forge/changes/demo-005-connect-greeting/`
  with `.forge.yaml` (status: archived, schema: full-stack-monorepo,
  full timeline, layers: [backend], parent_audit_items: [T.5]) +
  proposal/specs/design/tasks.
- **FR-T5-CC-031** — `specs.md` ships ≥ 2 BDD scenarios (Connect+JSON
  happy path + traceparent W3C E2E invariant).
- **FR-T5-CC-032** — `examples/forge-fsm-example/clients/connect-client.ts`
  + `package.json` pinning `@connectrpc/connect@^2.0.0` +
  `@connectrpc/connect-web@^2.0.0` + `@bufbuild/protobuf@^2.2.0`.
- **FR-T5-CC-033** — TS client seeds a fresh W3C `traceparent` header
  per call via Web Crypto `getRandomValues` (CSPRNG).
- **FR-T5-CC-034** — Demo overlay budget : ≤ 100 KB added to the
  example tree (effective: ~6 KB).
- **FR-T5-CC-035** — `examples/forge-fsm-example/README.md` links
  demo-005 in the `## Demo changes` table.

### Group 5 — Linter rule `transport-codegen-coverage` (FR-T5-CC-040..041)

- **FR-T5-CC-040** — New WARN-only section in
  `.forge/scripts/constitution-linter.sh` walks the project for any
  `proto/` or `protos/` directory and emits a WARN if no sibling
  `gen/connect/` tree exists, pointing to `docs/MIGRATION-PATHS.md`.
- **FR-T5-CC-041** — Opt-out via `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1`
  (env var ; respected by the rule's first conditional check).

### Group 6 — Snapshot tarball (FR-T5-CC-050..051)

- **FR-T5-CC-050** — Snapshot regenerated with the 5 post_cargo_new
  templates inside the tarball (verified via `python3 tarfile.getnames()`
  cross-platform).
- **FR-T5-CC-051** — Tarball size ≤ **640 KB** gzipped (post-T.5 budget,
  bumped from the original 500 KB after T-RUST shipped — pre-T.5
  baseline 422 KB ; post-T.5 measured ~517 KB ; remaining headroom
  ~123 KB).

### Group 7 — Test harness `t5.test.sh` (FR-T5-CC-060..064)

- **FR-T5-CC-060** — Harness file at `.forge/scripts/tests/t5.test.sh`
  registered in `.github/workflows/forge-ci.yml` matrix at `--level 1`.
- **FR-T5-CC-061** — Harness coverage : 25 L1 tests covering all
  FR-T5-CC checkpoints (validates buf.gen.yaml entries, transport.yaml
  v1.1.0 fields, Rust adapter shape, demo-005 archived shape, linter
  rule opt-in/opt-out, snapshot inclusion).
- **FR-T5-CC-062** — Harness wall-clock ≤ 5 s on L1 (NFR-T5-CC-001).
  Measured : 1.19 s.
- **FR-T5-CC-063** — Output format mirrors b4 / t4 conventions
  (`✓` / `✗` per test ; `── Summary ──` block ; exit 1 on any FAIL).
- **FR-T5-CC-064** — L2 fixture coverage (5 stubs : buf generate,
  Dart smoke, traceparent dual-codec E2E, cargo fixture build,
  connectrpc dual-codec direct). **DEFERRED 2026-05-06** to a follow-up
  change ; CI runs `--level 1` only.

### Group 8 — Documentation (FR-T5-CC-070..072)

- **FR-T5-CC-070** — `docs/MIGRATION-PATHS.md` (NEW) — top-level
  migration index referenced by the WARN-only linter rule.
- **FR-T5-CC-071** — `docs/ARCHETYPES.md` `full-stack-monorepo` row
  references the additive Connect-RPC adoption from v0.4.0-rc.x onward.
- **FR-T5-CC-072** — `CHANGELOG.md ## [Unreleased]` entry summarising
  all T.5 deliverables.

---

## Non-Functional Requirements

- **NFR-T5-CC-001** — Harness L1 ≤ 5 s wall-clock ; full ≤ 30 s.
- **NFR-T5-CC-002** — Snapshot delta ≤ 640 KB gzipped (bumped post-T-RUST).
- **NFR-T5-CC-003** — Per-file budgets : `transport_connect.rs.tmpl`
  ≤ 80 LOC ; `main.rs.tmpl` ≤ 80 LOC ; total post_cargo_new tmpl
  payload < 8 KB.
- **NFR-T5-CC-004** — Backward compatibility : v0.3.x adopters continue
  to work after `forge upgrade` (no path retired ; tonic gRPC bind
  preserved ; new `phase: post_cargo_new` field is additive in
  `scaffold-plan.yaml` schema). `scaffolder.test.sh` 7/7 PASS post-T.5.
- **NFR-T5-CC-005** — Zero adopter runtime breakage (a7.test.sh 29/29
  ; `forge upgrade` 3-way merge against the regenerated snapshot
  succeeds).
- **NFR-T5-CC-006** — Schema unchanged : flagship stays at `1.0.0` ;
  no `2.0.0/` directory created (B.8 / T6 territory).
- **NFR-T5-CC-007** — Generated stub size budget across 3 languages
  ≤ 500 KB (the demo Greeter service stays well under).
- **NFR-T5-CC-008** — Constitution stays at v1.1.0 (no bump).
- **NFR-T5-CC-009** — Connect handler latency budget ≤ 5 ms p50
  overhead vs the REST-bridge baseline (deferred validation to L2
  fixture).
- **NFR-T5-CC-010** — Plugin version traceability — every pin in
  `transport.yaml::codegen.versions` documented with provenance URL +
  access date in `design.md::ADR-T5-002`.

---

## ADRs ratified by this change

- **ADR-T5-001** — Adopt the `connectrpc` Rust crate (Anthropic OSS) ;
  axum integration via inline `Router::into_axum_service()` (no
  separate `connectrpc-axum` crate).
- **ADR-T5-002** — Toolchain pins resolved at design phase via
  Context7 + WebSearch (11 versions documented).
- **ADR-T5-003** — Demo-005 ships TS-only ; Rust S2S Connect client
  deferred to B.8 (T6).
- **ADR-T5-004** — Flat-by-language layout
  `gen/connect/<lang>/<proto-package>/<service>.connect.<ext>`.
- **ADR-T5-005** — `transport-codegen-coverage` linter rule is
  WARN-only ; never blocking CI.
- **ADR-T5-006** — `phase: post_cargo_new` template pattern in
  `scaffold-plan.yaml` schema (extension introduced during impl after
  T-BUF investigation revealed the BSR remote plugin is not yet
  shipped, forcing a `connectrpc-build` build.rs pivot).
