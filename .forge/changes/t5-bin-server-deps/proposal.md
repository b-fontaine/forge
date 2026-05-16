# Proposal: t5-bin-server-deps
<!-- Created: 2026-05-16 -->
<!-- Schema: default -->
<!-- Audit: T5.1.E (docs/new-archetypes-plan.md §0.1 extension — Option B follow-on) -->

## Problem

After `t5-cargo-pin-refresh` (T5.1.E) unblocked the Cargo dependency
resolution on the `full-stack-monorepo` template, `task
smoke-with-toolchains` exposed the next layer of bugs : the
`bin-server` crate compiles errors because the deps it imports are
not declared in any manifest the workspace can resolve from.

### Error verbatim (2026-05-16 post-buffa-fix)

```
error[E0432]: unresolved import `axum`
  --> bin-server/src/main.rs:14:5
error[E0432]: unresolved import `grpc_api`
  --> bin-server/src/main.rs:15:5
error[E0433]: failed to resolve: use of unresolved module or unlinked crate `tonic`
  --> bin-server/src/main.rs:16:5
error[E0433]: failed to resolve: use of unresolved module or unlinked crate `tower_http`
  --> bin-server/src/main.rs:17:5
error[E0433]: failed to resolve: use of unresolved module or unlinked crate `tokio`
  --> bin-server/src/main.rs:19:3
```

### Root cause — two compounding gaps

1. **`bin-server/Cargo.toml.tmpl` does not exist** at
   `.forge/templates/archetypes/full-stack-monorepo/backend/bin-server/`.
   Only `src/main.rs.tmpl` is shipped. The scaffolder writes
   `main.rs` but never gives the crate a manifest declaring its
   deps. `cargo` treats this as a directory with source but no
   package — workspace resolution fails to bring deps in.

2. **Workspace `[workspace.dependencies]` is missing three crates**
   that `bin-server/main.rs.tmpl` imports :

   - `axum` — used as `axum::Router` (line 14)
   - `tower-http` — used as `tower_http::trace::TraceLayer` (line 17)
   - `http` — implicit via `axum` but desirable to declare

   `tokio`, `tracing`, `tracing-subscriber`, `anyhow`, `tonic` are
   already in `workspace.dependencies` — only the axum / tower-http
   / http trio is missing.

3. **Version constraint on `axum` must be 0.8**, not the 0.7 the
   existing reference example `examples/forge-fsm-example/backend/Cargo.toml`
   ships with. Reason : `connectrpc 0.3.3` (pinned by
   `t5-connect-codegen` 2026-05-06, kept by `t5-cargo-pin-refresh`)
   declares `axum = "^0.8"` as a normal dependency. The example
   currently has `axum = "0.7"` AND does not consume `connectrpc`
   (the example was scaffolded before `t5-connect-codegen` and was
   never regenerated), so it builds. The **template**, which DOES
   pull in `connectrpc 0.3.3`, must pin `axum = "0.8"` for Cargo to
   resolve a consistent graph.

### Why earlier tests didn't catch this

- `t5.test.sh` (T.5 grep harness) was grep-only.
- `a7.test.sh` covers `forge upgrade` 3-way merge, not the
  buildability of the rendered template.
- `forge-ci.yml` never ran `cargo` against a fresh scaffold.
- The example tree `forge-fsm-example/backend/` carries
  hand-written manifests that don't expose the gap (it was
  scaffolded once + has been hand-edited).

`t5-cargo-pin-refresh` removed the upstream `buffa` resolution
failure, and `task smoke-with-toolchains` (T5.1.B with
`FORGE_E2E_TOOLCHAINS=1`) immediately surfaced this next layer.

## Solution

Three minimum-edit fixes :

### T5BSD-A — Add three workspace deps

Extend `backend/Cargo.toml.tmpl::[workspace.dependencies]` with :

```toml
# ── HTTP / transport (T5.1.E follow-on, t5-bin-server-deps) ──
# axum 0.8 is required by connectrpc 0.3.3 (declares `axum = "^0.8"`).
axum = "0.8"
tower-http = { version = "0.6", features = ["trace"] }
http = "1"
```

### T5BSD-B — Create `bin-server/Cargo.toml.tmpl`

New file at
`.forge/templates/archetypes/full-stack-monorepo/backend/bin-server/Cargo.toml.tmpl`
with the canonical [package] block + the deps `main.rs.tmpl`
actually imports, all consumed via `workspace = true` (per the
example pattern verified in
`examples/forge-fsm-example/backend/bin-server/Cargo.toml`) :

```toml
[package]
name = "bin-server"
version = "0.1.0"
edition = "2024"

[dependencies]
# Path dep on the gRPC adapter crate (consumes transport_connect::into_router).
grpc-api = { path = "../crates/grpc-api" }

# Workspace deps inherited from backend/Cargo.toml.
tokio = { workspace = true }
anyhow = { workspace = true }
tracing = { workspace = true }
tracing-subscriber = { workspace = true }
tonic = { workspace = true }
axum = { workspace = true }
tower-http = { workspace = true }
http = { workspace = true }
```

### T5BSD-C — Bundled-assets mirror + snapshot regen

- Mirror the two edits in `cli/assets/.forge/templates/...` via
  `npm run bundle`.
- Regenerate the snapshot tarballs
  `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
  (+ bundled mirror) via `bin/forge-snapshot.sh build
  full-stack-monorepo 1.0.0` so `forge upgrade` BASE recovery
  serves the corrected template.

### Out of scope

- **Update `examples/forge-fsm-example/`** to align with the
  corrected template. The example will be regenerated as part of
  `t5-otel-dartastic-realign` (T5.3) or a later refresh ; its
  current Cargo.toml (axum 0.7, no connectrpc) builds today.
  Regenerating it now would conflate two changes.
- **Bump `axum` workspace dep to a major beyond 0.8** — this
  change pins what `connectrpc 0.3.3` requires. Future bumps
  follow the same modernisation track as the `connectrpc` family
  (B.8 / T6).
- **Constitution amendment.** No Article touched.
- **`transport.yaml` bump.** The standard's `codegen.versions:`
  block does not list `axum` or `tower-http` (those are
  application-side deps, not Connect-RPC codegen pins). No
  standard version moves.

## Scope In

- Edit `.forge/templates/.../backend/Cargo.toml.tmpl` :
  - Add `axum = "0.8"` + `tower-http = { version = "0.6",
    features = ["trace"] }` + `http = "1"` to
    `[workspace.dependencies]`.
- New file
  `.forge/templates/.../backend/bin-server/Cargo.toml.tmpl` per
  T5BSD-B body above.
- Mirror both edits in `cli/assets/.forge/templates/...` via
  `npm run bundle`.
- Regenerate snapshot tarballs (source + bundled mirror).
- New harness `.forge/scripts/tests/t5-bin-server.test.sh` ≥ 7 L1
  grep + 1 L2 fixture-based.
- Register harness in `.github/workflows/forge-ci.yml`.
- CHANGELOG `[Unreleased]` entry.
- Plan §0.1 + inventory : add T5BSD note ; bump archived count
  26 → 27.

## Scope Out (Explicit Exclusions)

- Regenerating the live example tree
  `examples/forge-fsm-example/backend/`. Same reasoning as the
  Out-of-scope block above.
- Adding `opentelemetry`, `opentelemetry-otlp`, `opentelemetry-sdk`,
  `tracing-opentelemetry` to workspace deps. The flagship Phase B
  (`t5-otel-app`) instrumented the **example** ; the **template**
  does not yet ship the OTel SDK init (it's deferred until
  flutter/opentelemetry.md v2.0.0 lands via T5.3, at which point
  the cross-cutting Dart + Rust OTel layout is realigned together).
- Modernising `axum` past 0.8 / `tower-http` past 0.6. B.8 (T6)
  territory.
- Touching `crates/grpc-api/Cargo.toml.tmpl` further. `t5-cargo-pin-refresh`
  is the last word on that file for v0.3.3 ; the `grpc-api` crate
  re-declares `tower-http = { version = "0.6", features = ["trace"] }`
  inline (not via workspace) and that's compatible with the new
  workspace dep — duplication is benign and may be deduped later.
- Constitution amendment.

## Impact

- **Users affected** :
  - **Forge adopters who scaffold `full-stack-monorepo` after
    `t5-cargo-pin-refresh` lands** : `cd backend && cargo check
    --workspace` exits 0 on the fresh scaffold.
  - **Forge maintainer** : `task smoke-with-toolchains` GREEN
    on the cargo check leg for full-stack-monorepo. (The
    mobile-only / flutter analyze fail is T5.3 territory,
    unaffected by this change.)
- **Technical impact** : ~10 LOC added to
  `backend/Cargo.toml.tmpl` ; ~15 LOC new file
  `bin-server/Cargo.toml.tmpl` ; mirrors auto-regenerated ;
  snapshot regen ; ~150 LOC new harness. No new external dep on
  the Forge toolchain side.
- **Dependencies** : depends on `cli-trust-harness` (the smoke
  test infrastructure) + `t5-cargo-pin-refresh` (the upstream
  Cargo resolution unblocker) being archived first.
- **Risk level** : **Low**. Template-only fixes ; cargo build
  outcome verifiable end-to-end via `task smoke-with-toolchains`
  before archive. No runtime behavior change ; the binary's
  `main()` already exists, it just couldn't compile.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. RED witness already wild :
`task smoke-with-toolchains` fails today on the cargo check leg.
Phase 1 of `tasks.md` reproduces this at the harness level
(7 L1 stubs RED) ; Phase 2 + 3 ship the fixes ; Phase 4 verifies.

### Article II — BDD

The adopter-facing flow (scaffold → `cargo check --workspace`
exits 0) gets a Gherkin scenario in `specs.md`.

### Article III — Specs Before Code

Confirmed.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Two open questions raised, both resolved during `/forge:design`
by ADR-T5BSD-001..002.

### Article V — Audit Trail

Each task tagged `[Story: FR-T5BSD-XXX]`. New files carry
`# Audit: T5.1.E (t5-bin-server-deps)`.

### Article XII — Governance

No standard moves ; no Article amended.

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none.
Two open questions Q-001 / Q-002 raised in `open-questions.md`,
resolved by ADR-T5BSD-001..002 in `design.md`.
