# b7-6 — live codegen / build verification record

<!-- Audit: B.7.6 (b7-6-harness) — honest record of the live codegen/build path -->
<!-- per NFR-B7-6-006 (no fabricated CI-green) + ADR-B7-6-005 (Q-B option b). -->
<!-- Written 2026-06-23. -->

## Promotion bar (maintainer Option-A decision, 2026-06-23)

The promotion bar for `ai-native-rag` is **flagship parity**, NOT a compiled Rust
Connect service handler. Grounding (files read 2026-06-23):

- The `ai-native-rag` backend workspace is exactly `rag`, `llm_gateway`, `mcp`,
  `bin-server` (`.forge/templates/archetypes/ai-native-rag/1.0.0/backend/Cargo.toml.tmpl`
  members). There is **no `grpc-api` crate** and no `crates/` dir.
- `bin-server/Cargo.toml.tmpl` does **not** depend on `grpc-api`; its comment:
  "Connect/Temporal/Zitadel are consumed from the 2.0.0 substrate BY REFERENCE
  (see main.rs) — not re-declared here."
- `bin-server/src/main.rs.tmpl` composes the axum surface as
  `Router::new().merge(llm_gateway::handler::router())`; the Connect line at
  lines 38-39 is a documented **adopter seam** ("mount additional substrate routes
  (Connect under /connect) at the adopter's wiring step"), not code.
- The flagship's own Connect adapter
  (`full-stack-monorepo/.../grpc-api/src/transport_connect.rs.tmpl`) is itself an
  **unwired seed**: `into_router()` builds an empty `ConnectRouter::new()` with a
  `TODO(adopter): wire your proto-generated service handlers here`, returning a
  404-only router. So the reference stable/scaffoldable archetype ships an UNWIRED
  Connect seed too.

⇒ b7-6 does **not** add a grpc-api crate (that would hold ai-native-rag higher than
the flagship + expand scope beyond the promotion gate + violate the b7-2 "Connect by
reference" ADR-B7-2-007). The Connect handler stays a documented adopter seam;
b7-6's Tier-B L1 asserts the seam EXISTS (T-B08/T-B09), not that a handler compiles.

## What "live codegen + build" means for this archetype (the real, provable path)

1. `buf generate` (proto → Rust tonic/prost stubs into
   `backend/crates/grpc-api/src/generated` + the TS Connect `rag_pb` descriptor into
   `frontend/web-public/src/lib/generated/connect`). Needs the `buf` CLI + BSR
   network (remote plugins in `buf.gen.yaml.tmpl`).
2. `cargo build`/`cargo test --workspace` of the rendered **4-crate** backbone
   (`rag`/`llm_gateway`/`mcp`/`bin-server`) — this is hand-written and compiles
   WITHOUT the generated stubs (the stubs are the adopter's future grpc-api crate).
3. Qwik `tsc --noEmit` of the rendered web-public surface — the
   `./generated/connect/rag_pb` import resolves ONCE `buf generate` has produced the
   TS descriptor. This is the genuine "rides b7-6" leg deferred from b7-10
   (`b7-10.test.sh` T-L2-004 SKIP, "rides b7-6").

## What was verified LOCALLY (2026-06-23, this dev host)

Tooling present: `cargo` (~/.cargo/bin/cargo), `node`/`npm` (linuxbrew).
Tooling ABSENT: `buf` (`which buf` → not found), `tsc` (not on PATH).

- **Render** (`overlay.sh` via the absolutize-temp-plan convention): clean, no
  `.tmpl` survivors, no unsubstituted `{{placeholder}}`, byte-stable re-render.
  (`b7-6.test.sh` T-C01 ✓.)
- **`cargo test --workspace` on the rendered backend**: RAN LIVE and the 4-crate
  backbone compiled + its unit tests passed. (`b7-6.test.sh` T-C03 ✓, not SKIP —
  cargo present + registry reachable.) `cargo metadata --no-deps` on the rendered
  workspace also resolves the manifest cleanly. This VERIFIES the LIVE pins
  (rmcp 1.7.0 / pgvector 0.4.2 / async-openai 0.41.1 / fastembed 5.17.2 / sqlx 0.9 /
  tokio-stream 0.1.18) resolve + build — no verify-then-pin LIVE fix was needed
  (NFR-B7-6-005).
- **`buf generate`** (T-C02) + **Qwik `tsc`** (T-C04): SKIPPED locally (buf + tsc
  absent). These are NOT proven on this host.

## What is proven in CI (the authoritative gate — Q-B option b)

The `harness-rust` job in `.github/workflows/forge-ci.yml` installs `buf`
(`bufbuild/buf-setup-action`, pinned), a Rust toolchain (`dtolnay/rust-toolchain`,
pinned), and node, then runs `b7-6.test.sh --level 1,2`. There the L2 legs RUN LIVE:
`buf generate` materialises the Rust + TS stubs, `cargo build`/`test` builds the
4-crate workspace, and Qwik `tsc` type-checks the web-public surface with the now-
resolvable `rag_pb` import. The candidate→stable flip is justified by this job going
green on the PR.

**Honesty note (NFR-B7-6-006):** the buf-dependent legs (T-C02 buf generate, T-C04
Qwik tsc) are proven by the CI `harness-rust` job, NOT by a local run on this host
(buf absent). No "CI green with buf" claim is fabricated here — the CI job IS the
evidence, and it gates PR merge before the flip can reach main. The cargo backbone
build is independently proven LOCALLY (above).
