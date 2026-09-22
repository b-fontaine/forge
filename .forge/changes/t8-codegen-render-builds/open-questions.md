# Open questions — `t8-codegen-render-builds`

## Q-001: the two flagship buf manifests can drift, and only one is reachable by fresh init

- **Status**: open
- **Raised in**: `specs.md § ADR-T8CRB-002`
- **Raised on**: 2026-09-22
- **Raised by**: @bfontaine

### Question

The flagship ships two codegen manifests: `shared/protos/buf.gen.yaml.tmpl` (1.0.0) and
`2.0.0/shared/protos/buf.gen.yaml.tmpl`. `scaffold-plan-2.0.0.yaml:174` inherits the
**1.0.0** one, so `forge init --archetype full-stack-monorepo` — the stable default —
renders it; the 2.0.0 copy is reached only by `migration-plan-2.0.0.yaml:138`, i.e. by
`forge-migrate-flagship`. The two therefore differ on the es output path and on the
`connectrpc/go` pin (v1.19.2 vs v1.20.0) with nothing comparing them.

This brick fixed both rather than choosing between them. Which is right — re-point the
2.0.0 plan at the 2.0.0 manifest, or retire the 2.0.0 copy as migration-only — is a
maintainer call, and whichever way it goes the pair needs a guard: no harness runs
`buf generate` against a fresh 2.0.0 render today.

## Q-002: `buf lint` fails on a freshly rendered `ai-native-rag`

- **Status**: open
- **Raised in**: `evidence.md § P-1`
- **Raised on**: 2026-09-22
- **Raised by**: @bfontaine

### Question

Found while measuring Q-005, reported by the investigation lane and not re-measured here:
`cd shared/protos && buf lint` exits 100 on a fresh render with STANDARD-category
violations. `task proto:check` is therefore red out of the box, independently of
`buf generate`. Not fixed, because it is a proto-style decision (rename the fields, or
configure the lint category) rather than a broken tool.

## Q-003: the Go Connect stubs are generated into a Rust crate directory

- **Status**: open
- **Raised in**: `proposal.md § Scope`
- **Raised on**: 2026-09-22
- **Raised by**: @bfontaine

### Question

`buf.gen.yaml` sends `buf.build/connectrpc/go` output into
`backend/crates/grpc-api/src/generated/connect/go/`, inside a Rust crate, where no Go
toolchain will ever read it. The template comment calls it forward-compatibility.

This brick made that plugin *work* rather than questioning it, because removing a plugin
from a shipped archetype changes what adopters get. But it is worth deciding: a plugin
nobody consumes is a remote call, a dependency and a `go_package_prefix` to maintain on
every proto change. If it stays, the comment should say what will consume it and when.

## Q-004: the tonic `no_include` probe could not be completed

- **Status**: open
- **Raised in**: `evidence.md § P-8`
- **Raised on**: 2026-09-22
- **Raised by**: @bfontaine

### Question

The mutation probe that drops `no_include=true` and expects `T-C02` to FAIL returned SKIP
instead. Checked rather than assumed: the BSR was rate-limiting at that moment
(`resource_exhausted: too many requests`), so `T-C02` correctly classified a genuine
transport failure — the probe never reached the tonic error. The FAIL path for that exact
message is unit-tested (evidence P-6), but the end-to-end probe should be re-run once the
rate limit clears rather than left as proven.
