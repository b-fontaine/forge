# Migration Paths

This document indexes every supported migration in Forge. Each section
documents what `forge upgrade` adds, what stays untouched, and any
manual work the adopter must perform.

> Created 2026-05-05 by `t5-connect-codegen` to back the
> `transport-codegen-coverage` linter rule (FR-T5-CC-040). Future
> migrations append a new section per archetype × version pair.

---

## T.5 — Connect codegen additive (v0.3.x → v0.4.0-rc.x)

**Status** : in flight on branch `t5-connect-codegen` (planned status,
21/25 tests GREEN at the time of writing).

**Scope** : the `full-stack-monorepo / 1.0.0` archetype is extended
**additively** with Connect-RPC codegen alongside the existing tonic
gRPC + Kong-bridge REST path. **No path is retired** in T.5 — the
breaking codec swap (and Kong → Envoy, Temporal → DBOS, etc.) ships
in B.8 (T6).

### What `forge upgrade` adds

After this change archives, an adopter running `forge upgrade` against
a project scaffolded from `full-stack-monorepo / 1.0.0` (v0.3.x) gets :

- **`shared/protos/buf.gen.yaml`** receives 3 new entries via 3-way
  merge :
  - `buf.build/connectrpc/go:v1.19.2` — Go forward-compat for B.6/B.7.
  - `buf.build/bufbuild/es:v2.2.0` — Connect v2 / Protobuf-ES v2 (TS).
  - `buf.build/connectrpc/dart:v1.0.0` — official ConnectRPC Dart
    plugin (replaces the abandoned `skadero/connect-dart-community`).
- **`.gitignore`** receives `backend/crates/grpc-api/src/generated/connect/`
  + `frontend/lib/generated/connect/` (the generated stubs are NOT
  committed — `task proto` regenerates them).
- **`.forge/standards/transport.yaml`** is bumped 1.0.0 → 1.1.0 with
  a new `codegen.versions:` map pinning the 11 toolchain components
  (buf, protoc-gen-connect-go, protoc-gen-es, connectrpc-dart,
  connectrpc/buffa/buffa-types/connectrpc-build pinned `=0.3.3` —
  `WAIVER` documented inline).

### What stays untouched

- **The Kong-bridge REST path is preserved**. Existing REST routes
  served via Kong remain bound to their tonic gRPC backends ; the
  Connect adapter is mounted in **parallel** under `/connect`.
- **The tonic gRPC server bind is unchanged** (ADR-004 KEEP). Adopters
  who only consume gRPC continue to work.
- **The application + domain layers are untouched**. The Connect
  adapter is a transport-only concern under
  `backend/crates/grpc-api/src/transport_connect.rs`.
- **`framework-owned-paths.yml` is NOT extended** with the Rust crate
  paths. Adopter-owned files (`backend/crates/grpc-api/Cargo.toml`,
  `build.rs`, `src/transport_connect.rs`, `bin-server/src/main.rs`)
  are NOT propagated by future `forge upgrade` runs (per
  ADR-T5-006). Adopters who modify these files keep their changes.
  A future T.5+ amendment of these `.tmpl` will not flow downstream
  via 3-way merge — adopters must re-scaffold or patch manually.

### Linter rule `transport-codegen-coverage` (WARN-only)

A new section in `.forge/scripts/constitution-linter.sh` walks the
project for any `proto/` or `protos/` directory and emits a single
WARN line if no sibling `gen/connect/` tree exists, pointing here.

The rule is **WARN-only — never blocking**. Opt out via
`FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1` if you have a reason to keep
proto contracts without Connect codegen during the v0.3.x → v0.4.0-rc.x
window (e.g. mid-migration projects, single-language consumers).

### Codec coverage on day 1

The `connectrpc` crate (Anthropic OSS, `=0.3.3`) multiplexes :

- `application/connect+json` (HTTP/1.1 + HTTP/2)
- `application/connect+proto` (HTTP/1.1 + HTTP/2)
- `application/grpc` (HTTP/2)
- `application/grpc-web` (HTTP/1.1 + HTTP/2)

…all on the **same handler**. The `application/connect+json` HTTP/1.1
codec — originally deferred to B.8 — ships immediately with this
change.

### Pre-1.0 risk for `connectrpc=0.3.3`

The crate is < 30 days old at the time of pinning (waiver justified
by 6 558 conformance tests + Anthropic OSS pedigree + exact pin —
see `transport.yaml` inline `WAIVER` block). If a 0.4.x lands before
B.8 (T6), evaluate bump vs stay via a new `transport.yaml` review
entry.
