# Open Questions — t5-connect-codegen

## Q-001: Which Connect-Rust crate to use for the parallel server route?

- **Status**: answered
- **Raised in**: proposal.md (Impact, Risk level Medium)
- **Raised on**: 2026-05-05
- **Raised by**: @bfontaine

### Question

ARCH §14 caveat 2 flags Connect ecosystem maturity outside Go/TS as the
#1 risk for B.8. T5 needs a Rust server-side Connect handler mounted in
parallel to the existing tonic gRPC service. Options :

- **Option A** : depend on the community `connect-rs` crate (or
  equivalent published crate) if it meets production criteria :
  active maintenance (last commit ≤ 6 months), Apache-2.0 / MIT
  licence, OTel middleware compatible, supports Connect-RPC + gRPC +
  gRPC-Web protocols, ≥ 1k downloads. Pro : ready-made, less code to
  maintain.
- **Option B** : hand-roll a Connect codec on top of `tonic` + `tower`
  + `axum`. Pro : zero new dependency, leverages crates already pinned
  by ADR-004. Con : more code in `templates/`, more surface to
  maintain.
- **Option C** : use `tonic-web` to expose gRPC-Web at the same
  endpoints as a partial Connect-compat (Connect-RPC accepts
  gRPC-Web wire format on the same routes). Pro : minimal change.
  Con : not full Connect-RPC compliance (no `application/connect+json`
  HTTP/1.1 codec).

### Resolution

- **Resolved on**: 2026-05-05
- **Initial decision (superseded same day)**: Option C — tonic + tonic-web. Rationale was to avoid spiking a community Rust crate of unknown maturity ; accept HTTP/1.1+JSON Connect codec deferment to B.8.
- **Final decision (post-Context7 investigation)**: **Option A — adopt the `connectrpc` Rust crate (Anthropic OSS, Tower-based, Axum-native)** with companion `buffa` zero-copy proto crate. Ratified as ADR-T5-001 in `design.md`.
- **Rationale (revised)**: Context7 + WebSearch + WebFetch investigation on 2026-05-05 surfaced that Anthropic open-sourced `connectrpc` (`crates.io/crates/connectrpc` + `github.com/anthropics/connect-rust`) as the canonical Rust ConnectRPC implementation. Production-tested at Anthropic, passes the ~12 800 ConnectRPC server/client/TLS conformance tests, integrates as Tower middleware (fits FR-T5-CC-013 OTel layer), Axum-native via `connectrpc-axum`. Apache-2.0 licence. Adopting it eliminates the `application/connect+json` HTTP/1.1 limitation and removes the codec-swap dependency from B.8. Risk mitigation : pin exact crate version, T-VER-006 spike (≤ 30 min) verifies conformance suite + licence + Axum integration before adoption. Crate ecosystem younger than tonic but explicitly nominated as canonical by ConnectRPC governance — defensible choice.

---

## Q-002: Concrete version pins for `protoc-gen-connect-{go,es,dart-community}` and the buf CLI

- **Status**: answered
- **Raised in**: proposal.md (Open Questions section) ; specs.md FR-T5-CC-022
- **Raised on**: 2026-05-05
- **Raised by**: @bfontaine

### Question

`transport.yaml` v1.1.0 (FR-T5-CC-022) requires a `codegen.versions:`
map pinning the four toolchain components. Which exact versions ship
in this change ?

- **Option A** : pin to the latest stable release of each plugin as of
  archive date 2026-05-05.
- **Option B** : pin to the version range advertised by upstream
  Connect documentation as the "supported" combination.
- **Option C** : let `buf.gen.yaml` declare versions and not duplicate
  in `transport.yaml`.

### Resolution

- **Resolved on**: 2026-05-05
- **Decision**: **Versions resolved at design phase** via Context7 + WebSearch + WebFetch investigation 2026-05-05. Recorded in `design.md` ADR-T5-002 table + `transport.yaml` `codegen.versions` (canonical pin source) + `buf.gen.yaml` revision fields + `tasks.md` T-VER-001..006 with provenance URLs. Ratified as ADR-T5-002.
- **Resolved values (2026-05-05)** :
  - `buf` CLI : **v1.68.2** (`buf.build/docs/cli/installation`).
  - `protoc-gen-connect-go` : **v1.19.2** (released 2025-04-20, `github.com/connectrpc/connect-go/releases/latest`) — Go path, forward-compat for B.6/B.7.
  - **`@bufbuild/protoc-gen-es ≥ v2.2.0`** (TS, replaces retired `protoc-gen-connect-es` per Connect v2 migration).
  - **`@connectrpc/connect@^2.0.0`** + **`@connectrpc/connect-web@^2.0.0`** (TS runtime + transport).
  - **`connectrpc/connect-dart` ≥ v1.0.0** (OFFICIAL plugin, pub.dev `connectrpc` package, replaces abandoned `skadero/protoc-gen-connect-dart-community`).
  - **`connectrpc` Rust crate + `buffa` proto crate** (Anthropic OSS, ratified by ADR-T5-001) — exact versions resolved by T-VER-006 spike at impl Phase 1 (≤ 30 min, verifies licence + conformance + Axum integration).
- **Rationale**: Investigation surfaced (a) Connect v2 retired the `protoc-gen-connect-es` plugin in favour of `@bufbuild/protoc-gen-es`, (b) the `skadero/protoc-gen-connect-dart-community` plugin was abandoned in 2022-09 and replaced by an official ConnectRPC Dart plugin in 2025, (c) the `connectrpc` Rust crate (Anthropic OSS) made the original "Connect+JSON deferred to B.8" trade-off unnecessary. Resolving versions at design phase (instead of impl M1) saves ~10 min at impl and avoids shipping a buf.gen.yaml referencing dead plugins. Acceptance criteria : (1) ≥ 30 days old, (2) OSI licence, (3) `buf format --diff` no-op at impl M1 verification, (4) Connect v2 cross-compat verified via upstream MIGRATING.md, (5) ConnectRPC conformance suite passing for the Rust crate. Closes Q-002 structurally with public-URL provenance for every pin (Article III.4).

---

## Q-003: Should demo-005 ship a Rust Connect client in addition to the TypeScript client?

- **Status**: answered
- **Raised in**: proposal.md (Open Questions section)
- **Raised on**: 2026-05-05
- **Raised by**: @bfontaine

### Question

Demo-005 currently scopes a TypeScript client only. A Rust Connect
client (server-to-server scenario) would prove the symmetric path and
help adopters who plan service-to-service calls without going through
Kong. Two options :

- **Option A** (default) : TS only.
- **Option B** : add a Rust Connect client integration test that
  validates the full s2s loop.

### Resolution

- **Resolved on**: 2026-05-05
- **Decision**: **Option A — TypeScript client only**. Ratified as ADR-T5-003.
- **Rationale**: Rust server-to-server Connect calls are deferred to B.8 (T6) where the DBOS-driven workflow patterns ship together with the Connect codec on the Rust side. Decoupling Q-003 from Q-001 keeps the demo overlay tight (under the 100 KB budget — FR-T5-CC-034). The traceparent E2E invariant (FR-T5-CC-014) is language-independent : a TS client is sufficient to prove the propagation contract ; symmetric Rust client is redundant for T5's stated goal. Server-to-server Connect within the Rust workspace remains tested via the existing tonic gRPC path until B.8.

---

## Q-004: Layout convention for `gen/connect/{rust,ts,dart}/` — flat-by-language vs nested-by-package?

- **Status**: answered
- **Raised in**: proposal.md (Open Questions section) ; specs.md FR-T5-CC-005
- **Raised on**: 2026-05-05
- **Raised by**: @bfontaine

### Question

Generated Connect stubs need a stable directory layout pinned via
`transport.yaml` `codegen.connect_layout_version: 1`. Two main options :

- **Option A** (flat-by-language, nested-by-package) :
  `gen/connect/<lang>/<proto-package>/<service>.connect.<ext>`
- **Option B** (nested-by-service-then-language) :
  `gen/connect/<service>/<lang>/<file>.<ext>`

### Resolution

- **Resolved on**: 2026-05-05
- **Decision**: **Option A — flat-by-language, nested-by-package**. Ratified as ADR-T5-004 in `design.md`. Concrete shape :
  ```
  gen/connect/
    rust/forge.greeter.v1/greeter.connect.rs
    ts/forge.greeter.v1/greeter_connect.ts
    dart/forge.greeter.v1/greeter.connect.client.dart
  ```
- **Rationale**: matches the `protoc-gen-connect-{go,es,dart-community}` default `out:` semantics with minimal `opt:` overrides ; clean cross-language symmetry ; predictable for adopters ; survives multi-service proto files without collision ; representable as a single `connect_layout_version: 1` integer in `transport.yaml` (no per-language overrides required). Forward-compat preserved : a future nested-by-service requirement bumps to `connect_layout_version: 2` via a new Forge change with `transport.yaml` v1.x.0 → v2.0.0 (Article XII process).
