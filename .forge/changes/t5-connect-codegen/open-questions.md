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
- **Decision**: **Option C — `tonic` + `tonic-web`**, ratified as ADR-T5-001 in `design.md`.
- **Rationale**: Connect-ES TypeScript client (the only client consumed in T5 — see Q-003) provides `createGrpcWebTransport` natively, which is wire-compatible with `tonic-web`. This keeps the change strictly within the crates already pinned by ADR-004 (no new Rust dependency, no new Cargo.toml widening, no spike on community crate maturity). The known limitation is that strict Connect+JSON over HTTP/1.1 (`application/connect+json` codec) is **not** supported — an acceptable T5 limitation, with full Connect codec support deferred to B.8 (T6) per the additive-first/breaking-second migration discipline. Spike footprint ≤ 30 LOC of glue in `transport/connect.rs`. Documented limitation surfaces in `transport.yaml` rationale and `docs/MIGRATION-PATHS.md`.

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
- **Decision**: **Pin at implementation time** via Context7 lookup for each component, recorded in `transport.yaml` `codegen.versions` AND `buf.gen.yaml` (canonical pin source duplicated for tooling discoverability), with changelog URL captured in `tasks.md` M1 evidence trail. Ratified as ADR-T5-002.
- **Rationale**: Concrete plugin versions drift weekly upstream ; pinning them in this design document at spec time risks staleness by archive time (2026-05-05 is the earliest archive ; M1 of `/forge:implement` re-resolves). Acceptance criteria : (1) each plugin's selected release ≥ 30 days old to filter brand-new regressions ; (2) OSI-approved licence ; (3) `buf` CLI version backwards-compatible with the existing `b1-foundations` pin (verified via `buf format --diff` against frozen flagship `proto/`) ; (4) `protoc-gen-connect-es` version's TS output consumable by the `@connectrpc/connect-web` runtime version pinned in demo-005's TS client. Closes Q-002 structurally rather than by guessing arbitrary numbers (Article III.4).

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
