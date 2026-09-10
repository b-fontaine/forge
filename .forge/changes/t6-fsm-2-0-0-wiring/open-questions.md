# Open questions — `t6-fsm-2-0-0-wiring`

## Q-001 — the backend JWT middleware is still not shipped

`2.0.0/backend/crates/grpc-api/src/jwt_middleware.rs.tmpl` is Zitadel's server-side
validator and belongs, conceptually, with what this change wired. It cannot ship
without `2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl`, whose dependencies are
`connectrpc = "=0.6.1"`, `buffa`, `buffa-types` — the Connect-RPC stack.

So "ship the Zitadel middleware" and "ship Connect-RPC in fresh-init" are the same
decision, and the second is B.8.6's, not this brick's.

Not harmless to leave: Envoy validates JWTs at the edge, so the deployed posture is
sound, but the backend has no second layer and the four Connect files remain in the
tree reachable only by migration.

## Q-002 — the Qwik surface stays migration-only

`2.0.0/frontend/web-public/` — 10 files — is opt-in by maintainer decision
(2026-09-10). It is an entire additional surface with its own toolchain, CI workflow
and pins; pgvector and Zitadel are infrastructure the project already referenced.

The visible residue: `.claude/agents/iris-web.md` still scaffolds into every 2.0.0
project, and `docs/` still describe a web-public surface. An agent shipped for a
surface that is not there is a smaller version of the problem this change fixed.
Whether to gate the agent on the surface, or ship the surface, is undecided.

## Q-003 — `ZITADEL_MASTERKEY` ships with a placeholder that is exactly 32 characters

Zitadel requires exactly 32. `.env.example` carries
`changeme_local_only_32_chars_xx`, which satisfies the length so the stack starts on
first `task dev:up` rather than failing on a validation error the adopter has to
decode.

The trade-off is real and worth naming: a working default is also a credential
nobody is forced to change. It is `.env.example`, not `.env`, and the line says
`changeme` — but the same reasoning has produced shipped secrets elsewhere in the
industry. A `bootstrap.md` prompt or a generated key would be safer.

## Q-004 — the `docs/ARCHETYPES.md` table row is stale beyond this change's scope

The `full-stack-monorepo` row still reads version **1.0.0** and describes **Kong**,
which fresh-init has not delivered since B.8.14 (2026-06-05). This change adds a
section stating what 2.0.0 delivers rather than rewriting that row: its prose spans
five bricks' worth of history and rewriting it correctly is a documentation task, not
a by-product of wiring two services.

Already a tracked inventory item ("`docs/ARCHETYPES.md` still describes the flagship
as 1.0.0/Kong"). Recorded here so the new section is not mistaken for having closed it.
