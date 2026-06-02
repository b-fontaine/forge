<!-- Audit: B.8.6 (b8-6-connect-rpc) -->
# Tasks: b8-6-connect-rpc

TDD-ordered. Four-file extended subtree (ADR-B86-002: buf.gen.yaml.tmpl +
README.md.tmpl + transport_connect.rs.tmpl + Cargo.toml.tmpl under 2.0.0/).
Rust pins are verify-then-pin LIVE at Phase 0 (ADR-B86-001 final-re-verify
clause). The 2.0.0.yaml annotation + transport.yaml v1.3.0 bump keep b8-3
17/17 + b8-3b 12/12 green (NFR-B86-003). 1.0.0 frozen surfaces untouched
(NFR-B86-002).

---

## Phase 0 — Verify-then-pin (LIVE re-execution, Article III.4 + b8-coroot lesson)

Every task in this phase queries a live external registry. Each result MUST be
appended to `evidence.md` with: URL, HTTP response timestamp, value recorded,
and a one-line summary of what it proves. If any pin is falsified vs the design
ADR, emit `[NEEDS CLARIFICATION: <detail>]` and stop — do NOT proceed to Phase 1
with stale pins.

- [x] **T001** Re-query crates.io for `connectrpc`: confirm `0.6.1` is still the
  max stable version (or record the new max stable if superseded). Append
  evidence: `https://crates.io/api/v1/crates/connectrpc/versions` — record
  the max stable version + publish date + MSRV. If the result differs from
  `0.6.1`, check whether the new version still declares `buffa ^0.6`; if not,
  emit `[NEEDS CLARIFICATION]` and stop.
  [Story: FR-B86-010, NFR-B86-006, ADR-B86-001]

- [x] **T002** Re-query crates.io for `connectrpc-build`, `buffa`, `buffa-types`:
  confirm max stable versions and that `connectrpc <verified>` still declares
  `buffa ^0.6` (resolving to `=0.6.0` only — 0.7.0 out-of-range). Record the
  full resolved 2.0.0 pin set in `evidence.md` (P-01..P-05 refresh). If the
  compat matrix has changed, emit `[NEEDS CLARIFICATION]` and stop.
  [Story: FR-B86-010, FR-B86-012, NFR-B86-006, ADR-B86-001]

- [x] **T003** Check BSR availability of `buf.build/connectrpc/go:v1.20.0`.
  Query `https://buf.build/connectrpc/go` (BSR UI or API). If `v1.20.0` is
  published on BSR, the 2.0.0 `buf.gen.yaml.tmpl` and the
  `codegen.versions_2_0_0.protoc-gen-connect-go` entry in `transport.yaml`
  MUST use `1.20.0`; if absent, retain `1.19.2`. Record evidence (P-11 refresh).
  [Story: FR-B86-004, ADR-B86-003]

- [x] **T004** Verify `buf.build/connectrpc/dart:v1.0.0` is still the current
  published BSR plugin (pub.dev proxy: `https://pub.dev/packages/connectrpc`).
  Confirm no version advancement since the design-phase P-08 check (2026-06-02).
  Record evidence. If advancement is found, update `connect_dart_version` in
  `evidence.md` and use the new version in the 2.0.0 manifest (1.0.0 frozen
  manifest is byte-unchanged regardless).
  [Story: FR-B86-004, ADR-B86-003, NFR-B86-006]

- [x] **T005** Verify `docs.rs/connectrpc/<verified-version>` for the exact
  0.4.0+ handler-signature shape: confirm `ConnectRouter::new()` +
  `into_axum_service()` axum mount surface (ADR-B86-001 P-07 re-verify).
  Confirm the `axum` feature is still non-default. Record evidence (P-07
  refresh). If the API surface has changed further, emit `[NEEDS CLARIFICATION]`
  and stop before authoring `transport_connect.rs.tmpl`.
  [Story: FR-B86-013, ADR-B86-001/002]

---

## Phase 1 — Harness RED

Author `b8-6.test.sh` with ALL ~12 L1 assertions before any template, standard
edit, or schema annotation. Run it immediately after authoring to confirm the
expected RED baseline. Tests that assert current frozen state (T-005 1.0.0
sentinel, T-006 into_axum_router sentinel) may pass immediately — record
which pass and which fail in a run note.

- [x] **T006** Author `.forge/scripts/tests/b8-6.test.sh` (~12 L1 hermetic tests,
  mirror b8-5.test.sh structure: `--level` flag, `source _helpers.sh`,
  `run_test`, `print_summary`). Include all assertions per design.md Testing
  Strategy table (T-001..T-012). L1 budget ≤ 2 s, zero network/Docker.
  [Story: FR-B86-050, NFR-B86-001]

- [x] **T007** Run `bash .forge/scripts/tests/b8-6.test.sh --level 1` → verify
  RED baseline. Expected fail: T-001 (no 2.0.0/shared/protos/ subtree),
  T-002 (no 2.0.0/backend/crates/grpc-api/ subtree), T-003 (no 6-plugin
  manifest), T-004 (no 0.6.1/0.6.0 Cargo pins), T-007 (transport.yaml not yet
  v1.3.0), T-008 (no versions_2_0_0 block), T-009 (no REVIEW.md 1.3.0 row),
  T-010 (no B.8.6 delivered annotation), T-012 (no CHANGELOG entry).
  Expected pass: T-005 (1.0.0 dart:v1.0.0 sentinel present), T-006 (1.0.0
  into_axum_router sentinel present), T-011 (b8-3/b8-3b coupling — already
  green before any edit). Record the exact pass/fail counts.
  [Story: FR-B86-050, Article I RED]

---

## Phase 2 — GREEN: transport.yaml v1.3.0 (standard FIRST — no resolution-order trap for b8-3 T-011)

Unlike B.8.4 (gateway.yaml had to exist before T-011 resolved), B.8.6 has no
resolution-order trap: `standard: transport.yaml` has resolved since T.5 and is
not renamed. The transport.yaml bump and the 2.0.0.yaml annotation are
order-independent for b8-3 T-011. Transport.yaml is edited first because the
`versions_2_0_0` block drives the pin values in the template files.

- [x] **T008** Edit `.forge/standards/transport.yaml`: (a) fix stale `"v1.1.0"`
  header comment → update audit block to `v1.3.0` recording B.8.6 (additive:
  2.0.0-line Rust Connect crate pins block + header fix; FR-B86-022); (b) bump
  `version:` field `"1.2.0"` → `"1.3.0"` (FR-B86-020); (c) add
  `codegen.versions_2_0_0:` sibling block under `codegen:` carrying the four
  Rust crate pins from Phase 0 verification (connectrpc, connectrpc-build,
  buffa, buffa-types) plus JS/Dart/Go entries per ADR-B86-005 shape (FR-B86-021).
  The existing `codegen.versions:` map MUST be byte-unchanged (FR-B86-025).
  No `breaking_change: true` (FR-B86-026, ADR-B86-005).
  [Story: FR-B86-020, FR-B86-021, FR-B86-022, FR-B86-025, FR-B86-026, ADR-B86-005]

- [x] **T009** Append a `B.8.6` `Updated` entry to `.forge/standards/REVIEW.md`
  (append-only ledger, Article XII): the row MUST contain
  `| transport.yaml | 1.3.0 |` (FR-J7-023 anchor). Mirror the B.8.4
  gateway.yaml and B.8.5 orchestration.yaml REVIEW.md precedents.
  [Story: FR-B86-023, FR-B86-024, ADR-B86-005]

- [x] **T010** Run `bash bin/validate-standards-yaml.sh .forge/standards/` in
  DIRECTORY mode → must exit 0 with `[STD-PASS] …transport.yaml` line
  (FR-B86-024, b8-4 dir-mode lesson). Re-run `b8-6.test.sh --level 1` → T-007,
  T-008, T-009 must now be GREEN. Record the new pass count.
  [Story: FR-B86-024, ADR-B86-005]

---

## Phase 3 — GREEN: 2.0.0.yaml delivered-flip annotation

- [x] **T011** Edit `.forge/schemas/full-stack-monorepo/2.0.0.yaml`: add inline
  comment `# protocol: connect-rpc — B.8.6 delivered` on the `standard:
  transport.yaml` line of the `connect-rpc` component, mirroring the B.8.4
  envoy-gateway annotation style (ADR-B86-005 annotation section; FR-B86-033).
  The `rest-bridge → connect-rpc` migration_delta with `strategy: additive-first`
  MUST remain intact (FR-B86-032). No forbidden inline-pin keys `{version, pin,
  image}` introduced (FR-B86-031, b8-3 T-012). No `^\d+\.\d+` scalar value
  added (b8-3 T-015). REST-bridge NOT removed (FR-B86-032, FR-B8-3-031).
  [Story: FR-B86-030, FR-B86-031, FR-B86-032, FR-B86-033, FR-B86-034, ADR-B86-005]

- [x] **T012** Run `bash .forge/scripts/tests/b8-3.test.sh --level 1` → must
  exit 0 (17/17). Run `bash .forge/scripts/tests/b8-3b.test.sh --level 1` →
  must exit 0 (12/12). Any failure is a B.8.6 constitutional violation
  (NFR-B86-003). Re-run `b8-6.test.sh --level 1` → T-010 must now be GREEN.
  Record pass counts.
  [Story: NFR-B86-003, FR-B86-034, FR-B86-058]

---

## Phase 4 — GREEN: 2.0.0 template subtree (four files, ADR-B86-002)

Author all four template files. Use the Phase 0 verified pins. The 1.0.0 frozen
files (shared/protos/buf.gen.yaml.tmpl, backend/.../transport_connect.rs.tmpl,
backend/.../Cargo.toml.tmpl) MUST be byte-unchanged throughout (NFR-B86-002).

### G1a — 2.0.0/shared/protos/buf.gen.yaml.tmpl

- [x] **T013** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  shared/protos/buf.gen.yaml.tmpl`: full standalone copy (ADR-B86-002,
  FR-B86-002); carry all six plugin remote references: `neoeinstein-tonic`,
  `neoeinstein-prost`, `protocolbuffers/dart` (gRPC Rust + Dart stubs),
  `buf.build/connectrpc/go` (Phase 0 T003 verified version: v1.19.2 or v1.20.0),
  `buf.build/bufbuild/es:v2.2.0`, `buf.build/connectrpc/dart:v1.0.0` (Phase 0
  T004 confirmed — or new version if advancement found). `neoeinstein-tonic`
  MUST be retained (FR-B86-006, Article VII.2). MUST NOT reference or import
  the 1.0.0 manifest (FR-B86-002). Audit header: B.8.6 + ADR-B86-001/002/003.
  [Story: FR-B86-001, FR-B86-002, FR-B86-003, FR-B86-004, FR-B86-006, FR-B86-007,
   FR-B86-008, ADR-B86-002/003] [P]

### G1b — 2.0.0/shared/protos/README.md.tmpl

- [x] **T014** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  shared/protos/README.md.tmpl`: document (a) Connect-RPC as the 2.0.0 default
  transport, (b) additive posture vs frozen 1.0.0 codegen manifest, (c)
  gRPC-Web-via-Envoy fallback section titled "gRPC-Web-via-Envoy Fallback
  (Connect-Dart Risk #1)" cross-referencing `2.0.0/infra/k8s/envoy-gateway/`
  (FR-B86-009, FR-B86-040, FR-B86-042), (d) verify-then-pin note for the Rust
  crate line (ADR-B86-001), (e) policy-source reference to `transport.yaml`,
  (f) record that `buf.build/connectrpc/dart` is the official plugin (not
  `protoc-gen-connect-dart-community` — Q-004 naming drift) and its provenance
  (pub.dev, Phase 0 T004). Connect-Dart MUST be established as the DEFAULT Dart
  transport; fallback is conditional (FR-B86-042, ADR-B86-003). MUST NOT modify
  any file under `2.0.0/infra/k8s/envoy-gateway/` (FR-B86-041). Mirrors the
  B.8.5 postgres `README.md.tmpl` exemplar format.
  [Story: FR-B86-005, FR-B86-009, FR-B86-040, FR-B86-041, FR-B86-042,
   FR-B86-043, ADR-B86-003] [P]

### G2a — 2.0.0/backend/crates/grpc-api/src/transport_connect.rs.tmpl

- [x] **T015** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  backend/crates/grpc-api/src/transport_connect.rs.tmpl`: rewrite for the
  0.4.0+ handler-signature shape (ADR-B86-002 central finding; evidence.md P-06
  + Phase 0 T005 verified). Use axum mount surface `ConnectRouter::new()` +
  `into_axum_service()` (Phase 0 T005 confirmed — CHANGED from 0.3.x). The
  `build.rs` `include!(concat!(env!("OUT_DIR"), "/_connectrpc.rs"))` pattern
  PRESERVED (ADR-T5-006 path-α codegen mechanism; 0.6.0 CHANGELOG confirms
  build.rs users unaffected). MUST NOT copy the 1.0.0 adapter body verbatim
  (ADR-B86-002). Audit header: B.8.6 + ADR-B86-001/002. Module-level doc
  comments reference B.8.6 and 0.6.1. The 1.0.0 frozen adapter is byte-
  unchanged (NFR-B86-002).
  [Story: FR-B86-001, FR-B86-013, ADR-B86-001/002]

### G2b — 2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl

- [x] **T016** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  backend/crates/grpc-api/Cargo.toml.tmpl`: carry the Phase 0 verified 2.0.0
  pin set: `connectrpc = { version = "=0.6.1", features = ["axum"] }`,
  `buffa = "=0.6.0"`, `buffa-types = "=0.6.0"` (verify at Phase 0 T002 whether
  `buffa-types` appears in OUT_DIR/_connectrpc.rs generated imports — if not,
  demote to dev-dep; the 1.0.0 template carries it as a normal dep so retain
  normal unless evidence says otherwise; ADR-B86-002 Cargo.toml.tmpl note),
  `[build-dependencies] connectrpc-build = "=0.6.1"`. All other deps inherit
  from workspace pins (unchanged from 1.0.0 template). Audit header: B.8.6 +
  ADR-B86-001. The 1.0.0 frozen Cargo.toml.tmpl is byte-unchanged (NFR-B86-002,
  FR-B86-011). Pin values MUST NOT appear inline in `2.0.0.yaml` (FR-B86-015,
  ADR-B8-3-002).
  [Story: FR-B86-010, FR-B86-011, FR-B86-015, ADR-B86-001/002]

### Compile check (implementation-phase validation, NOT a harness gate)

- [x] **T017** Run `cargo check` (or equivalent) on the rendered 2.0.0 adapter
  to verify the 0.4.0+ handler shape compiles against `connectrpc 0.6.1`. This
  is a local validation step, not an L1 harness assertion (design.md L2 opt-in
  note — harness is hermetic grep/stat only). Record the result (pass or
  `[NEEDS CLARIFICATION: <error>]`). If compilation fails due to API surface
  uncertainty, surface the exact compiler error and stop before proceeding.
  [Story: FR-B86-013, ADR-B86-001/002]

---

## Phase 5 — GREEN: CHANGELOG + forge-ci.yml registration

- [x] **T018** Append a `## [Unreleased]` entry to `CHANGELOG.md` summarising
  the B.8.6 deliverables: 2.0.0 transport subtree (4 files), Rust Connect crate
  pin modernization (0.6.1/0.6.0), transport.yaml v1.3.0 (header fix +
  versions_2_0_0 block), 2.0.0.yaml connect-rpc delivered annotation, harness
  b8-6.test.sh. Mirrors B.8.4/B.8.5 CHANGELOG precedent.
  [Story: FR-B86-059]

- [x] **T019** Append `"b8-6.test.sh --level 1"` as a one-line entry to the
  `harnesses=()` loop in `.github/workflows/forge-ci.yml` after the
  `b8-5.test.sh --level 1` line (FR-B86-050). Verify the CI file stays within
  the NFR-CI-002 ≤ 300-line budget.
  [Story: FR-B86-050, NFR-CI-002]

---

## Phase 6 — Full harness GREEN

- [x] **T020** Run `bash .forge/scripts/tests/b8-6.test.sh --level 1` → must
  exit 0 with all 12/12 GREEN. Record the full output. Any failure is a
  constitutional violation (Article V). Confirm T-011 coupling guard shows
  b8-3 (17/17) + b8-3b (12/12) both exiting 0.
  [Story: FR-B86-050..059, NFR-B86-001/003]

---

## Phase 7 — Gates and sibling safety (NFR-B86-004 full-suite-before-push lesson)

Run all gates. A partial sweep is not sufficient — sibling scans can break
silently (b8-4 lesson; `full_harness_suite_before_push` project memory).
Repo-wide scans MUST skip `2.0.0/` subtrees (N.N.N/ convention from B.8.4/B.8.5;
established in scaffolding.md).

- [x] **T021** Run `bash bin/validate-standards-yaml.sh .forge/standards/` in
  DIRECTORY mode → must exit 0 with `[STD-PASS]` lines for transport.yaml
  (among others). Confirm the `| transport.yaml | 1.3.0 |` REVIEW.md anchor
  satisfies FR-J7-023 (J.7 drift check runs only in dir context).
  [Story: FR-B86-024, NFR-B86-005]

- [x] **T022** Run `bash bin/verify.sh` → must exit 0 (PASS). Record output.
  [Story: Article V]

- [x] **T023** Run `bash bin/constitution-linter.sh` → must exit 0. Record output.
  [Story: Article V]

- [x] **T024** Run `bash .forge/scripts/validate-change-yaml.sh
  .forge/changes/b8-6-connect-rpc/.forge.yaml` → must exit 0.
  [Story: Article V]

- [x] **T025** 1.0.0 byte-identity check: verify `b8-2.test.sh` frozen-sha256
  guard still passes (confirms 1.0.0 templates, schema.yaml, and 1.0.0.tar.gz
  are byte-unchanged):
  `bash .forge/scripts/tests/b8-2.test.sh --level 1` → exit 0.
  [Story: NFR-B86-002, FR-B86-007, FR-B86-011]

- [x] **T026** Run b8-3 and b8-3b one final time post all edits:
  `bash .forge/scripts/tests/b8-3.test.sh --level 1` → 17/17.
  `bash .forge/scripts/tests/b8-3b.test.sh --level 1` → 12/12.
  [Story: NFR-B86-003, FR-B86-034]

- [x] **T027** Run the FULL ~42-harness suite (all `*.test.sh` in
  `.forge/scripts/tests/`). Verify each harness exits 0 or is marked as
  expected-fail in forge-ci.yml. Pay special attention to any harness whose
  repo-wide scan might pick up the new `2.0.0/shared/protos/` or
  `2.0.0/backend/crates/grpc-api/` subtrees (delivery.test.sh, scaffolder.test.sh,
  t5.test.sh, b8-3.test.sh, b8-3b.test.sh, b8-4.test.sh, b8-5.test.sh). Any
  regression is a blocker.
  [Story: NFR-B86-004]

---

## Phase 8 — Wrap-up (ADR-B86 protocol + b8-coroot lesson)

- [x] **T028** Flip `.forge/changes/b8-6-connect-rpc/.forge.yaml` status:
  `designed → planned` (this file, done at plan time), then at implement-time:
  `planned → implemented`. **Re-run Phase 7 gates POST status flip** (b8-coroot
  lesson: gates must be re-run AFTER the flip, not trusted from pre-flip run).
  [Story: Article V, b8-coroot lesson]

- [x] **T029** Independent review pass (separate lane — author MUST NOT
  self-approve; NFR-B86-009, T5.2 lesson). The independent reviewer MUST
  re-execute (not trust the transcript): `b8-6.test.sh --level 1`, `b8-3.test.sh
  --level 1`, `b8-3b.test.sh --level 1`, `validate-standards-yaml.sh` dir-mode,
  and the 1.0.0 byte-identity check (T-005/T-006 sentinel greps). Record the
  reviewer's name and the run timestamp in the change record.
  [Story: NFR-B86-009, Article V.2]

- [x] **T030** Archive prep: verify all tasks marked complete, run
  `/forge:archive b8-6-connect-rpc` to flip status `implemented → archived`
  after the independent review PASS. Confirm the b8-8 / b8-12 next-brick
  dependency chain is noted (ADR-B86-004 re-defer to B.8.12 recorded).
  [Story: Article V, ADR-B86-004]

---

## FR-B86-* Coverage Table

| FR / NFR | Task(s) |
|----------|---------|
| FR-B86-001 | T013, T014 |
| FR-B86-002 | T013 |
| FR-B86-003 | T013, T020 |
| FR-B86-004 | T003, T004, T013, T014 |
| FR-B86-005 | T014 |
| FR-B86-006 | T013, T020 |
| FR-B86-007 | T013, T025 |
| FR-B86-008 | T011, T026 |
| FR-B86-009 | T014 |
| FR-B86-010 | T001, T002, T016 |
| FR-B86-011 | T016, T025 |
| FR-B86-012 | T002 |
| FR-B86-013 | T005, T015, T017 |
| FR-B86-014 | T029 (re-defer ADR-B86-004 explicit — no client template; not silently omitted) |
| FR-B86-015 | T016 |
| FR-B86-020 | T008 |
| FR-B86-021 | T008 |
| FR-B86-022 | T008 |
| FR-B86-023 | T009 |
| FR-B86-024 | T010, T021 |
| FR-B86-025 | T008 |
| FR-B86-026 | T008 |
| FR-B86-030 | T011 |
| FR-B86-031 | T011, T012 |
| FR-B86-032 | T011, T012 |
| FR-B86-033 | T011 |
| FR-B86-034 | T012, T026 |
| FR-B86-040 | T014 |
| FR-B86-041 | T014 |
| FR-B86-042 | T014 |
| FR-B86-043 | T014 |
| FR-B86-050 | T006, T007, T019 |
| FR-B86-051 | T006, T013, T014 |
| FR-B86-052 | T006, T013, T016 |
| FR-B86-053 | T006, T025 |
| FR-B86-054 | T006, T008, T010 |
| FR-B86-055 | T006, T008, T010 |
| FR-B86-056 | T006, T009 |
| FR-B86-057 | T006, T011, T012 |
| FR-B86-058 | T006, T012, T020, T026 |
| FR-B86-059 | T018 |
| NFR-B86-001 | T006, T007, T020 |
| NFR-B86-002 | T013, T015, T016, T025 |
| NFR-B86-003 | T012, T020, T026 |
| NFR-B86-004 | T027 |
| NFR-B86-005 | T016 |
| NFR-B86-006 | T001, T002, T003, T004, T005 |
| NFR-B86-007 | T013, T020 |
| NFR-B86-008 | T011, T026 |
| NFR-B86-009 | T029 |
