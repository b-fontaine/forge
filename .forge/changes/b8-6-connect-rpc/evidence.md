<!-- Audit: B.8.6 (b8-6-connect-rpc) — verify-then-pin evidence ledger -->
# Verify-then-pin Evidence — b8-6-connect-rpc

This file records the LIVE-verified facts consumed by the ADRs in `design.md`.
Verification was performed at `/forge:design` on **2026-06-02** by the main
thread (Ferris + Atlas roles), using the crates.io REST API, the upstream
CHANGELOG, the upstream README, pub.dev, the npm registry, and the GitHub
releases API. All claims are reproducible via the URLs in the provenance table
below.

Per the b8-coroot lesson: pins are always resolved LIVE on the registry at the
appropriate phase; none of the version strings below were fabricated upstream.
The final re-verify step at `/forge:implement` is still required (ADR-B86-001
final-re-verify clause).

---

## Provenance Table

| # | Source URL | Access date | Agent | What it proves |
|---|------------|-------------|-------|----------------|
| P-01 | `https://crates.io/api/v1/crates/connectrpc` | 2026-06-02 | main thread | `connectrpc` max stable = **0.6.1** (2026-05-27, MSRV 1.88); version history 0.1.x yanked, 0.3.3, 0.4.0–0.4.2, 0.5.0, 0.6.0, 0.6.1 |
| P-02 | `https://crates.io/api/v1/crates/connectrpc-build` | 2026-06-02 | main thread | `connectrpc-build` max stable = **0.6.1** — exact lockstep with `connectrpc` |
| P-03 | `https://crates.io/api/v1/crates/buffa` | 2026-06-02 | main thread | `buffa` max stable = **0.7.0** (2026-05-29, MSRV 1.87); prior: 0.6.0 (05-15), 0.5.x, 0.4.0, 0.3.0 |
| P-04 | `https://crates.io/api/v1/crates/buffa-types` | 2026-06-02 | main thread | `buffa-types` max stable = **0.7.0** (2026-05-29); same release cadence as `buffa` |
| P-05 | `https://crates.io/api/v1/crates/connectrpc/0.6.1/dependencies` | 2026-06-02 | main thread | `connectrpc 0.6.1` dependency constraints: `buffa ^0.6` (kind: **normal**), `buffa-types ^0.6` (kind: **dev** — test/dev dependency of connectrpc itself, not a normal dep), `axum ^0.8` (optional, feature `axum`), `tower-http ^0.6` (optional), `tower ^0.5`, `http ^1`, `tokio ^1`. **`buffa ^0.6` excludes 0.7.0; only 0.6.0 satisfies the constraint exactly.** |
| P-06 | `https://raw.githubusercontent.com/anthropics/connect-rust/main/CHANGELOG.md` | 2026-06-02 | main thread | Full breaking-surface log 0.3.3 → 0.6.1 (summarised below); repo identity confirmed: `https://github.com/anthropics/connect-rust` |
| P-07 | `https://raw.githubusercontent.com/anthropics/connect-rust/main/README.md` | 2026-06-02 | main thread | "With Axum (recommended)" section on 0.6.x shows `service.register(ConnectRouter::new())` then `.fallback_service(connect.into_axum_service())`. The 0.6.x surface uses **`ConnectRouter`** (not `connectrpc::Router`) and **`into_axum_service()`** (not `into_axum_router()`). The mount surface **CHANGED** from 0.3.x. The `axum` feature is still non-default; `features = ["axum"]` is still required. |
| P-08 | `https://pub.dev/api/packages/connectrpc` | 2026-06-02 | main thread | Dart package `connectrpc` latest = **1.0.0** (all published: 0.1.0–0.5.0, 1.0.0). Official "Implementation of the Connect protocol for Dart". BSR plugin `buf.build/connectrpc/dart:v1.0.0` remains current. |
| P-09 | `https://registry.npmjs.org/@connectrpc/connect` | 2026-06-02 | main thread | `@connectrpc/connect` latest = **2.1.1**; range `^2.0.0` in transport.yaml remains valid |
| P-10 | `https://registry.npmjs.org/@bufbuild/protoc-gen-es` | 2026-06-02 | main thread | `@bufbuild/protoc-gen-es` latest = **2.12.0**; range `>=2.2.0` in transport.yaml remains valid |
| P-11 | `https://api.github.com/repos/connectrpc/connect-go/releases/latest` | 2026-06-02 | main thread | connect-go latest release = **v1.20.0** (2026-05-20). BSR remote-plugin availability of v1.20.0 MUST be verified live at `/forge:implement`; until then v1.19.2 stays the recorded pin. |

---

## Finding 1 — connectrpc 0.6.1 + buffa 0.6.0 is the correct 2.0.0 pin set (ADR-B86-001)

### Version inventory (crates.io, P-01 through P-04)

**connectrpc** (repo: `https://github.com/anthropics/connect-rust`):
- 0.1.x — yanked (all)
- 0.3.3 — the current 1.0.0 pin (WAIVER, t5-connect-codegen)
- 0.4.0 (2026-05-06), 0.4.1 (2026-05-07), 0.4.2 (2026-05-08)
- 0.5.0 (2026-05-18)
- 0.6.0 (2026-05-20), **0.6.1 (2026-05-27)** ← max stable, MSRV 1.88

**connectrpc-build**: exact lockstep — 0.3.3, 0.4.0–0.4.2, 0.5.0, 0.6.0, **0.6.1**.

**buffa**: 0.3.0, 0.4.0, 0.5.0–0.5.2, **0.6.0** (2026-05-15), 0.7.0 (2026-05-29).

**buffa-types**: same cadence — 0.3.0, 0.4.0, 0.5.0–0.5.2, 0.6.0, **0.7.0** (2026-05-29).

### Dependency-requirement finding (P-05)

`connectrpc 0.6.1` declares:
- `buffa = "^0.6"` — kind: **normal** dependency.
- `buffa-types = "^0.6"` — kind: **dev** dependency (used in connectrpc's own tests/dev tooling; NOT a normal runtime dep of connectrpc itself).

For both: `^0.6` resolves to `>=0.6.0, <0.7.0`.
- Published versions satisfying this range: **0.6.0 only** (0.7.0 exceeds the upper bound).
- Therefore the correct exact pin for `buffa` alongside `connectrpc 0.6.1` is **`=0.6.0`**.
- 0.7.0 is **OUT OF RANGE** — using `buffa = "=0.7.0"` alongside `connectrpc = "=0.6.1"` would create an irresolvable dependency conflict.

**buffa-types dev-dep note**: because `buffa-types` is a dev-dependency of `connectrpc` (not a normal dep), the 1.0.0 `Cargo.toml.tmpl` carries it as a normal dep (line 36: `buffa-types = "=0.3.0"`) because the generated code references it at runtime. Whether the 2.0.0 `Cargo.toml.tmpl` requires `buffa-types = "=0.6.0"` as a **normal** dep must be verified against the generated-code imports at `/forge:implement` (the implementer checks the `OUT_DIR/_connectrpc.rs` generated output for any `buffa_types::` references). The `=0.6.0` pin value is unaffected by this distinction — the ^0.6 math holds regardless of dependency kind.

**Conclusion**: the 2.0.0 pin set is:
```
connectrpc       = "=0.6.1"
connectrpc-build = "=0.6.1"
buffa            = "=0.6.0"
buffa-types      = "=0.6.0"   # verify normal vs dev at implement (see buffa-types note above)
```
MSRV 1.88 (unchanged vs T5; the T5 WAIVER cited pre-1.0 age; at 0.6.x the crate is still pre-1.0 but mature with an Anthropic OSS pedigree + ConnectRPC conformance suite). No new WAIVER required — these are the current stable pins on the modern line (the T5 WAIVER was for the 13-day age of 0.3.3; no age concern applies here).

---

## Finding 2 — CHANGELOG breaking surface 0.3.3 → 0.6.1 (P-06)

Source: upstream CHANGELOG at `https://raw.githubusercontent.com/anthropics/connect-rust/main/CHANGELOG.md`, accessed 2026-06-02.

**0.4.0** — Handler signatures redesigned (#7); generated service code emitted as
`<stem>.__connect.rs`; buffa 0.5 sync; `ConnectError` 248→72 bytes; view
response bodies; `connectrpc` no longer pulls axum default features.

**0.4.2** — Adds `connectrpc::axum::serve_tls`; `server` feature enables
`tokio/macros`.

**0.5.0** — Streaming handler traits gain `type Item: Encodable<Res>`;
`RequestContext` `#[non_exhaustive]`; `ClientConfig`/`CallOptions` fields
`pub(crate)`; `Server`/`BoundServer`/`ServeTls` builders renamed `with_*`;
**buffa floor bumped to 0.6**; adds `PreEncoded<M>`, `DeadlinePolicy`.

**0.6.0** — Server-side interceptors (typed async middleware). BREAKING only for
hand-rolled `impl Dispatcher` (`call_unary` takes `Payload` not `Bytes`;
`MethodDescriptor` `#[non_exhaustive]`). **"connectrpc-build users (build.rs
integration) are unaffected — Cargo rebuilds OUT_DIR automatically."**

**0.6.1** (2026-05-27) — Patch; robustness of streaming/decompression paths;
**no API changes**; bytes floor 1.6.

### Impact on the 1.0.0 transport_connect.rs.tmpl

The 1.0.0 adapter (`backend/crates/grpc-api/src/transport_connect.rs.tmpl`)
builds `connectrpc::Router`, calls `into_axum_router()`, and wires handler impl
blocks following the 0.3.x handler signature shape (verified by direct re-read
this session). The **0.4.0 handler-signature redesign** changes those impl
blocks. The 1.0.0 template source is therefore **incompatible with 0.6.x at
the handler-impl level**. A 2.0.0 variant of the adapter is REQUIRED (this
falsifies the "buf.gen-only" minimal option for Q-002; option (b) is selected —
ADR-B86-002).

The **build.rs codegen path** (`connectrpc-build`) is **unaffected** by the
0.6.0 dispatcher breaking change (CHANGELOG verbatim: "connectrpc-build users
are unaffected — Cargo rebuilds OUT_DIR automatically").

---

## Finding 3 — Axum mount surface CHANGED 0.3.x → 0.6.x (P-07, ADR-B86-001/002)

Source: upstream README "With Axum (recommended)" section, accessed 2026-06-02.

The README on the `main` branch (representing 0.6.x) shows:
```rust
service.register(ConnectRouter::new())
// ...
.fallback_service(connect.into_axum_service())
```

**The mount surface CHANGED between 0.3.x and 0.6.x**:

| | 0.3.x (frozen 1.0.0 template) | 0.6.x (2.0.0 target) |
|---|---|---|
| Router type | `connectrpc::Router` | `ConnectRouter` |
| Axum method | `into_axum_router()` | `into_axum_service()` |
| Registration | direct | `service.register(ConnectRouter::new())` |

The frozen 1.0.0 `transport_connect.rs.tmpl` uses `connectrpc::Router::new()` +
`into_axum_router()` (re-read 2026-06-02, lines 77/81). This API is gone in 0.6.x.
The 2.0.0 adapter MUST use `ConnectRouter::new()` + `into_axum_service()`.

This is an **additional justification** for the 2.0.0 adapter variant (ADR-B86-002
option b) beyond the 0.4.0 handler-signature redesign: the axum mount surface
itself changed. The `axum` feature is still non-default; `features = ["axum"]`
must still be declared in Cargo.toml (unchanged in that respect).

The T-006 harness assertion (frozen 1.0.0 `transport_connect.rs.tmpl` still
contains `into_axum_router()`) remains **correct** — it targets the frozen 1.0.0
file, not the 2.0.0 variant.

---

## Finding 4 — Connect-Dart: pub.dev latest = 1.0.0; official plugin identity confirmed (P-08, ADR-B86-003)

Source: `https://pub.dev/api/packages/connectrpc`, accessed 2026-06-02.

- Dart package `connectrpc` latest: **1.0.0** (pub.dev).
- Published versions: 0.1.0, 0.2.0, 0.3.0, 0.4.0, 0.5.0, **1.0.0**.
- Description: "Implementation of the Connect protocol for Dart" (official,
  published by `connectrpc.com`).
- BSR plugin `buf.build/connectrpc/dart:v1.0.0` remains current.

**Conclusion**: the plan's `protoc-gen-connect-dart-community` name is
definitively stale (as established by t5-connect-codegen / FR-T5-CC-003). The
official plugin identity is `buf.build/connectrpc/dart` at `v1.0.0`. The 2.0.0
`buf.gen.yaml.tmpl` carries `buf.build/connectrpc/dart:v1.0.0` — no version
advancement since the 1.0.0 frozen pin. The gRPC-Web-via-Envoy fallback is
documented per plan §13 risk #1.

---

## Finding 5 — JS/npm versions remain valid (P-09, P-10, ADR-B86-005)

Source: npm registry, accessed 2026-06-02.

- `@connectrpc/connect`: latest **2.1.1**; the transport.yaml range `^2.0.0` remains valid.
- `@bufbuild/protoc-gen-es`: latest **2.12.0**; the transport.yaml range `>=2.2.0` remains valid.

No range changes required in the `codegen.versions_2_0_0` block for the JS entries.

---

## Finding 6 — connect-go BSR tag: v1.19.2 stays the recorded pin (P-11, ADR-B86-003)

Source: `https://api.github.com/repos/connectrpc/connect-go/releases/latest`,
accessed 2026-06-02.

- Latest GitHub release: **v1.20.0** (2026-05-20).
- BSR remote-plugin availability of `buf.build/connectrpc/go:v1.20.0` MUST be
  verified live at `/forge:implement` (the BSR may lag behind GitHub releases).
- Until then, `v1.19.2` remains the recorded pin in `transport.yaml` and in the
  `codegen.versions_2_0_0` block. The implementer MUST check
  `buf.build/connectrpc/go:v1.20.0` availability and update accordingly.

---

## /forge:implement Final Re-Verify — LIVE 2026-06-02T13:35Z (ADR-B86-001 final-re-verify clause)

The Phase 0 (T001–T005) live re-verification was executed by the main thread on
**2026-06-02 at 13:35Z** (UA `forge-verify-then-pin`). These entries refresh the
design-phase provenance (P-01..P-11) and resolve the two carried verify-then-pin
items (the Rust pin set + the BSR connect-go tag) plus the buffa-types
normal-dep question.

| # | Source URL | Access date | Agent | What it proves |
|---|------------|-------------|-------|----------------|
| P-12 | `https://crates.io/api/v1/crates/{connectrpc,connectrpc-build,buffa,buffa-types}` + `https://crates.io/api/v1/crates/connectrpc/0.6.1/dependencies` | 2026-06-02T13:35:52Z | main thread | **Re-verify (T001/T002):** `connectrpc` max_stable = **0.6.1** ✓; `connectrpc-build` = **0.6.1** ✓; `buffa`/`buffa-types` max = **0.7.0**, **0.6.0** exists ✓. `connectrpc 0.6.1` deps: `buffa ^0.6` (kind: normal), `buffa-types ^0.6` (kind: dev), `axum ^0.8` (normal, optional), `tower-http ^0.6` (optional). **Compat matrix UNCHANGED vs design — pin set CONFIRMED: connectrpc `=0.6.1`, connectrpc-build `=0.6.1` (build-dep), buffa `=0.6.0`, buffa-types `=0.6.0`.** No `[NEEDS CLARIFICATION]`. |
| P-13 | BSR remote-plugin probe (hermetic tmpdir, `buf generate`, buf CLI 1.70.0, probe proto + managed-mode `go_package_prefix`) | 2026-06-02T13:35Z | main thread | **Re-verify (T003/T004):** plugins `buf.build/connectrpc/go:v1.20.0` + `buf.build/connectrpc/dart:v1.0.0` + `buf.build/bufbuild/es:v2.2.0` ALL resolved and generated (`probe.connect.go`, `probe.connect.client.dart`, `probe_pb.js`) — `buf generate` exit 0. **ADR-B86-003 decision point resolved: connect-go BSR availability of `v1.20.0` CONFIRMED → refresh connect-go `v1.19.2 → v1.20.0` in the 2.0.0 buf.gen variant** (1.0.0 file keeps `v1.19.2`, frozen). connect-dart `v1.0.0` confirmed current (no advancement). |
| P-14 | `https://raw.githubusercontent.com/anthropics/connect-rust/main/README.md` | 2026-06-02T13:35Z | main thread | **Re-verify (T005):** 0.6.x handler shape confirmed. Imports: `use connectrpc::{Router, ConnectRpcService, Context, ConnectError}; use buffa::OwnedView;`. Handler: `async fn greet(&self, ctx: Context, request: OwnedView<GreetRequestView<'static>>) -> Result<(GreetResponse, Context), ConnectError>` (zero-copy views; response returned with ctx tuple). Axum mount: `use connectrpc::Router as ConnectRouter;` → `let connect = service.register(ConnectRouter::new());` → axum `Router::new()...fallback_service(connect.into_axum_service())`. `axum` feature still non-default. **Mount surface confirmed CHANGED from 0.3.x (`into_axum_router()` → `into_axum_service()`).** |
| P-15 | `https://raw.githubusercontent.com/anthropics/connect-rust/main/examples/eliza/Cargo.toml` | 2026-06-02T13:35Z | main thread | **buffa-types normal-dep question RESOLVED (evidence.md Finding 1 note):** the upstream canonical example (`examples/eliza`) carries BOTH `buffa` and `buffa-types` as **normal** `[dependencies]` (comment "Serialization (for generated message types)"). ⇒ the 2.0.0 `Cargo.toml.tmpl` keeps `buffa-types = "=0.6.0"` as a **normal** dep (mirrors the 1.0.0 posture + upstream). No demotion to dev-dep. |

**Phase 0 verdict**: all five Phase-0 re-verify tasks (T001–T005) PASS with the
design ADRs unfalsified. Two carried items resolved: (1) Rust pin set confirmed
identical (P-12); (2) connect-go BSR `v1.20.0` available → bumped in the 2.0.0
buf.gen variant (P-13). buffa-types stays a normal dep (P-15). No
`[NEEDS CLARIFICATION]` raised — implementation proceeds to Phase 1.
