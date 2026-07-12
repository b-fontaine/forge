# b6-7 — live codegen / build verification record

<!-- Audit: B.6.7 (b6-7-harness) — honest record of the live codegen/build path -->
<!-- per NFR-B6-7-006 (no fabricated CI-green) + ADR-B6-7-005. Written 2026-07-12. -->

## Toolchain present on this dev host (LIVE-probed 2026-07-12)

| tool    | version                          | used for |
|---------|----------------------------------|----------|
| buf     | 1.70.0                           | `buf build` / `buf generate` |
| cargo   | 1.97.0 (c980f4866 2026-06-30)    | `cargo build`/`cargo test --workspace` |
| node    | v24.8.0                          | (bundle regen only) |
| python3 | 3.13.7 + PyYAML 6.0.3            | overlay render |
| task    | 3.52.0                           | (Taskfile targets) |
| tar/gzip| bsdtar 3.5.3 / gzip              | snapshot |

`tsc` is absent — irrelevant: event-driven-eu ships NO frontend surface (the
`ops-console` Qwik surface is `status: deferred`), so there is no Qwik typecheck leg
(contrast b7-6's rag_pb ride-along).

## Sibling `run_test` census (LIVE `grep -c '^\s*run_test'` 2026-07-12)

| harness | run_test | CI level (forge-ci.yml) |
|---------|----------|--------------------------|
| b6-1    | 18       | --level 1,2 |
| b6-2    | 13       | --level 1   |
| b6-3    | 7        | --level 1   |
| b6-4    | 19       | --level 1,2 |
| b6-5    | 9        | --level 1,2 |
| b6-6    | 13       | --level 1   |
| b6-9    | 20       | --level 1,2 |
| b6-10   | 12       | --level 1,2 |
| **sum** | **111**  | |

The b6-7 suite adds 8 (Tier A) + 22 (Tier B) + 3 (Tier C) + 3 (Tier D) = **36**
`run_test` invocations, comfortably ≥ 35 (ADR-B6-7-002). None padded — each is a
distinct assertion.

## The real end-to-end BUILD proof: `cargo test --workspace` — PASS (LIVE)

The b6-7 Tier C `_test_b67_l2_c03_cargo_build_test` renders the archetype via
`overlay.sh` and runs `cargo test --workspace` on the rendered `backend/`
(events / eventstore / saga / bin-server). **It passed LIVE on this host** (cargo
1.97.0, online crate registry). This is the genuine end-to-end proof that the
archetype compiles and its unit tests pass.

This VERIFIES the b6-2 verify-then-pin LIVE pins resolve + build + test:
`async-nats = "0.49.1"`, `sqlx = "0.9"` (runtime-tokio + tls-rustls-ring),
`temporalio-sdk = "0.5.0"` / `temporalio-client = "0.5.0"` (declared in the
workspace, kept OFF by default behind the `temporal-sdk` feature — the default
`cargo test` resolves them but does not compile the unstable SDK). No pin failed to
resolve; **no verify-then-pin fix was required** (NFR-B6-7-005). The generated proto
stubs are NOT compiled by the workspace (they land in `backend/gen/`, not a workspace
member), so the build does not depend on codegen.

## The live proto gate: `buf build` — PASS (LIVE)

`_test_b67_l2_c02_buf_build` renders the tree and runs `buf build` on the rendered
`shared/protos/` module. **It passed LIVE** (buf 1.70.0, exit 0): the `events.v1`
`EventService` proto compiles into a FileDescriptorSet (syntax + imports valid).

## `buf generate` (full plugin codegen) — a documented, out-of-scope limitation

`buf generate` (what `task proto` runs) does **NOT** fully succeed, for reasons that
are pre-existing archetype/upstream issues, NOT introduced by b6-7, and shared with
the other Rust archetypes:

1. **connectrpc/go needs a Go import path.** With the archetype's
   `managed: { enabled: true }` (no `go_package_prefix`) the `connectrpc/go` plugin
   fails: `protoc-gen-connect-go: unable to determine Go import path for
   "v1/events/events.proto"`. Adding a `managed.override` `go_package_prefix`
   (buf v2 syntax, confirmed via buf docs) fixes this — verified LIVE.
2. **neoeinstein-tonic cannot read prost's sibling output in buf's remote-plugin
   sandbox.** With go_package fixed, the next failure is
   `plugin buf.build/community/neoeinstein-tonic:v0.4.0: read events.v1.rs: file
   does not exist`. Isolated: `neoeinstein-prost` alone succeeds (writes
   `events.v1.rs`); `neoeinstein-tonic` alone fails (it reads the prost-generated
   `events.v1.rs` to append the service impl, but buf runs each REMOTE plugin in an
   isolated sandbox that never sees a sibling plugin's output). This is a
   fundamental limitation of using the split `neoeinstein-prost` + `neoeinstein-tonic`
   REMOTE plugins together; the idiomatic fixes (local plugins run in sequence, or a
   `build.rs` tonic-build step) are adopter-side. With `neoeinstein-tonic` removed,
   `buf generate` fully succeeds (prost `events.v1.rs` + TS `events_pb.ts` + Go
   `events.connect.go`) — verified LIVE.

**Scope decision (ADR-B6-7-008):** b6-7 is a promotion GATE, not a codegen redesign.
The archetype's own wrapper already treats post-render `buf generate` as best-effort
("we never fail the scaffold on a codegen miss" — `forge-init-event-driven-eu.sh`),
and the workspace builds + tests WITHOUT the generated stubs. So b6-7 leaves the
archetype's `buf.gen.yaml.tmpl` pristine (b6-2's deliverable) and gates the live proto
path on `buf build` (contract validity) + `cargo test` (the real build). It does NOT
run full `buf generate` as a hard gate, and — critically — does NOT green-wash the
tonic failure: the b6-7 `buf build` leg's offline-detect matches ONLY genuine network
signals (`dial tcp`, `could not resolve host`, `TLS handshake timeout`, …), never the
substring `buf.build` (which appears in every plugin name).

**Systemic note (flagged separately, out of this brick's scope):** the same split
neoeinstein-tonic+prost config ships in the flagship (`full-stack-monorepo`, whose
proto tree is empty so it was never exercised) and in `ai-native-rag`. b7-6's C02
`buf generate` leg masks the identical tonic failure behind a loose offline-grep that
matches `buf.build`, so it has never actually verified codegen. That is a pre-existing
issue in the merged b7-6 brick, not introduced here.

## Honesty statement (NFR-B6-7-006)

- No "CI green with buf codegen" is fabricated. The passing live legs are `buf build`
  (proto compiles) + `cargo test --workspace` (workspace builds + tests) — both run
  LIVE on this host 2026-07-12, exit 0.
- The `buf generate` plugin-codegen limitation is recorded truthfully above; it is a
  pre-existing systemic issue, not a b6-7 regression, and is out of the promotion
  gate's scope.
- These legs run per-PR in the forge-ci `harness-rust` job (buf 1.70.0 + Rust
  toolchain), which is the permanent CI gate justifying the flip (ADR-B6-7-005).
