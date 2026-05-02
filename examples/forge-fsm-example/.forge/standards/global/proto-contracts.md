<!-- Audit: B.1.5 (part of b1-foundations) -->
<!-- Stage: draft -->

# Proto Contracts

This standard activates when `.forge.yaml` declares `schema: full-stack-monorepo`. It establishes Protocol Buffers (Protobuf) as the single source of truth for all cross-layer contracts — between backend and frontend, and between multiple backend services when more than one exists. Every consuming layer MUST derive its types exclusively from generated stubs; hand-written type definitions that duplicate or shadow a proto-defined message are prohibited. Compliance with this standard is a constitutional requirement under Article VII.2 (gRPC and Protocol Buffers) and Article IX.4 (Rust Observability / contracts as security surface).

## Arborescence shared/protos

All proto sources SHALL live under a single top-level `shared/protos/` directory at the repository root. This colocation makes the contract surface explicit and reviewable in a single diff.

```text
shared/protos/
├── buf.yaml
├── buf.gen.yaml
├── v1/
│   └── <service>/<service>.proto
└── v2/
    └── <service>/<service>.proto
```

**`buf.yaml`** — Buf module configuration. MUST declare:

- `lint.use` rules at minimum `STANDARD` (enforces naming, package conventions, field numbering).
- `breaking.use` set to `FILE` so any wire-incompatible change is flagged across the entire file surface.
- `deps` for well-known types (`buf.build/googleapis/googleapis` for `google.api`, etc.).

**`buf.gen.yaml`** — Code-generation configuration. MUST list at least two plugins:
- `buf.build/community/neoeinstein-tonic` for Rust (server + client stubs via `tonic-build`).
- `protoc_plugin` (the Dart protobuf plugin) for Flutter, outputting to `frontend/lib/generated/protos/`.

Additional plugins (e.g. `connect-es` for browser TypeScript) MAY be added as the stack grows.

**Namespace convention** — Each directory under `shared/protos/` represents a major API version (`v1/`, `v2/`). The proto `package` field MUST include the version: `myapp.<service>.v1`. Services within a namespace are further separated by subdirectory; one `.proto` file per service is RECOMMENDED. This layout means a `grep` over `v1/` always returns the complete v1 surface — no hunting across the repository.

## Versioning (v1, v2, deprecation)

Proto versioning is an explicit contract with consumers. Breaking a contract silently is a constitutional violation (Article III — Specs Before Code, Article IX.4 — contracts as security surface).

- Each major API version SHALL occupy its own directory (`v1/`, `v2/`). The directory is permanent once shipped.
- A shipped `v1/` MUST NOT be mutated in any breaking way. Breaking changes include: removing a field or message, changing a field type, renumbering fields, removing or renaming an RPC.
- When a breaking change is required, a new `v2/` directory MUST be created alongside `v1/`. The `v1/` service MUST remain available and actively supported for **at least two consecutive releases** after `v2/` becomes generally available.
- Non-breaking additions (new optional fields, new RPCs, new messages) MAY be added to an existing version in place.
- Deprecated fields MUST be annotated with `[deprecated = true]` and a comment pointing to the replacement. Deprecated RPCs MUST carry the `deprecated` option. `buf breaking` tracks these as warnings until removal in the next major version.

Example showing a deprecated field with a replacement pointer:

```protobuf
// shared/protos/v1/user/user.proto
syntax = "proto3";
package myapp.user.v1;

message UserProfile {
  string user_id   = 1;
  string full_name = 2;

  // Deprecated: use given_name + family_name instead (available since v1.4).
  string display_name = 3 [deprecated = true];

  string given_name  = 4;
  string family_name = 5;
}
```

Removed field numbers MUST be added to a `reserved` statement before the file is shipped, preventing accidental reuse.

## Gates CI (buf lint + buf breaking)

Two blocking gates protect the proto surface on every pull request.

**`buf lint`** — Runs on every PR that touches any file matching `shared/protos/**`. Zero warnings policy: a single lint warning fails the gate. There are no `warn` exceptions. Suppressing a rule requires an entry in `buf.yaml` under `lint.ignore_only` with a comment justifying the suppression.

**`buf breaking`** — Runs on every PR that modifies a file inside an existing namespace. The baseline is `main`:

```bash
buf breaking --against '.git#branch=main'
```

- Breaking changes detected inside a `v1/` namespace are **auto-rejected**. The PR MUST NOT be merged; the author MUST create a `v2/` instead.
- Breaking changes inside a `v2/` (or later) namespace are permitted only if that version has not yet been tagged as generally available in a release. Once a version is released, it follows the same immutability rules as `v1/`.

A local Taskfile target encapsulates both checks for developer use:

```yaml
# Taskfile.yml (excerpt)
tasks:
  proto:check:
    desc: Lint and breaking-change check for all protos
    cmds:
      - buf lint shared/protos
      - buf breaking shared/protos --against '.git#branch=main'
```

Developers MUST run `task proto:check` before pushing any branch that modifies `shared/protos/`. The CI gate enforces the same commands; local pre-push hooks are RECOMMENDED.

The GitHub Actions workflow that enforces these gates in CI is delivered as part of the `b1-delivery` milestone. Its job name SHALL be `proto-gates` and MUST be listed as a required status check on `main`.

## Génération des stubs (tonic-build, protoc_plugin)

Generated stubs are an artifact of the proto source — they MUST NOT diverge from it.

**Rust** — `tonic-build` is invoked from `backend/crates/grpc-api/build.rs` as part of Cargo's build script mechanism. Outputs land in `OUT_DIR` and are included in the crate with `include!`:

```rust
// backend/crates/grpc-api/build.rs
fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(true)
        .build_client(true)
        .compile(
            &["../../../shared/protos/v1/order/order.proto"],
            &["../../../shared/protos"],
        )?;
    Ok(())
}
```

Both server and client stubs are generated together. Consumers choose which to use via feature flags or direct inclusion.

**Dart** — `protoc_plugin` is invoked via a `dart run` tool script declared in `pubspec.yaml`. Outputs MUST land in `frontend/lib/generated/protos/` and SHALL be namespaced by service and version to avoid collisions.

**Single command regeneration** — The Taskfile target `task proto` regenerates both layers atomically:

```yaml
tasks:
  proto:
    desc: Regenerate Rust and Dart stubs from shared/protos
    cmds:
      - buf generate shared/protos
```

`buf.gen.yaml` drives both plugins from this single invocation.

**Committed vs gitignored** — Forge defaults to **committing generated stubs**. The trade-offs are:

| Strategy | Advantages | Disadvantages |
|----------|-----------|---------------|
| Committed (default) | Reviewable in diff; CI-stable without codegen step; works in air-gapped environments | Repository size grows; merge conflicts on generated files |
| Gitignored | Smaller repository; always regenerated fresh | Every CI job must run codegen; harder to audit historical contracts |

Teams that prefer the gitignored strategy MUST document this explicitly in `.forge.yaml`:

```yaml
# .forge.yaml
schema: full-stack-monorepo
proto:
  generated_stubs: gitignored   # Default: committed
```

When `gitignored` is set, the CI pipeline MUST include a codegen step before any build or test job that depends on the stubs.

**Crucial policy**: generated files MUST NOT be hand-edited under either strategy. If a generated file needs to change, the `.proto` source changes first, then `task proto` is re-run.

## Interdictions

The following are absolute prohibitions. Each violation is a constitutional violation that MUST block the PR.

- **No proto definitions outside `shared/protos/`.** Proto files scattered across service directories create split sources of truth and make `buf lint` / `buf breaking` unreliable.
- **No manual edits to generated stubs.** Regenerate with `task proto`. Hand-edits are silently overwritten on the next generation and introduce invisible drift between the contract and its consumers.
- **No `google.protobuf.Any` or `google.protobuf.Struct` to smuggle untyped payloads.** These types defeat the type safety that Protobuf provides and push validation burden onto application code, away from the schema layer. Use a concrete message type. If the shape is genuinely dynamic, model it explicitly with `oneof` or a well-typed discriminated union message.
- **No breaking changes to a released `v1/`.** Create `v2/` instead. The versioning discipline is the contract with consumers; breaking it without a new namespace violates Article IV (delta-based change management) and Article IX.4 (security surface integrity).
- **No mixing of `v1/` and `v2/` imports in the same service endpoint.** Each endpoint SHALL commit to a single namespace. Mixed imports produce consumers that must handle two incompatible schemas simultaneously, eroding the type guarantee.

---

## Relation to the Forge Constitution

**Article IV — Delta-Based Change Management** maps directly onto proto evolution. Field additions correspond to `ADDED` deltas. Field deprecations (marking `[deprecated = true]` with a replacement pointer) correspond to `MODIFIED` deltas. Field removals, performed only in a subsequent major version after the deprecation window, correspond to `REMOVED` deltas. Teams MUST document proto evolution using this delta format in the change's `specs.md`, keeping the spec history intact and reviewable.

**Article IX.4 — Rust Observability / Contracts as Security Surface** — The proto contract is not merely a data-transfer convenience; it is a security boundary. Auth token fields, tenant identifiers, and permission scopes are expressed in proto messages. Request shape validation (field presence, range constraints, enum membership) enforced at the gRPC layer prevents malformed or malicious payloads from reaching domain logic. Every security-relevant field — tenant ID, user ID, authorization scope — MUST be a first-class typed field in the proto definition, never smuggled through `Struct` or `Any`. Treat every change to a proto message that carries auth or tenant data as a security-surface change requiring Aegis review.
