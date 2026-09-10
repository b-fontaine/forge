# Proposal — `t6-fsm-2-0-0-wiring`

**A fresh `full-stack-monorepo / 2.0.0` project and a migrated one are different
products.** This closes the half of the gap that the project already assumes.

## The divergence, measured

The `2.0.0/` template tree holds 36 files. `scaffold-plan-2.0.0.yaml` — the fresh-init
plan — references **13**. `migration-plan-2.0.0.yaml` references all **36**.

The 13 are the five root files plus the eight Envoy Gateway manifests: exactly
"1.0.0 minus Kong, plus Envoy", which is what B.8.14 set out to deliver. The 23
absent ones are the three additive bricks — B.8.5 pgvector, B.8.7 Zitadel, B.8.9 Qwik
— plus B.8.6's Connect backend.

So two adopters on the same archetype at the same version hold materially different
trees depending on how they arrived.

## It is not merely "fewer files"

A fresh 2.0.0 project **references what it does not have**:

| token | referenced in | present |
|---|---|---|
| `postgres` / `pgvector` | `docker-compose.dev.yml`, `.env.example`, `docs/ARCHITECTURE-TARGET.md` | `infra/postgres` **absent** |
| `zitadel` | `infra/k8s/envoy-gateway/security-policy.yaml`, its README, `docs/MIGRATIONS.md` | `infra/zitadel` **absent** |
| `web-public` | `docs/`, `.claude/agents/iris-web.md` | **absent** |

Three concrete consequences:

- **The datastore is the previous generation.** `docker-compose.dev.yml` runs
  `postgres:16-alpine`. The 2.0.0 variant of that template contains **zero**
  occurrences of pgvector or postgres:17 — B.8.5 reached neither the plan nor the
  compose. The project runs Postgres 16 while its own architecture doc describes
  pgvector.
- **A shipped manifest points at nothing.** `security-policy.yaml:22` cites
  `infra/zitadel/values-forge.yaml.tmpl` for its OIDC issuer. That directory is not
  in the project.
- **An agent with no surface.** `.claude/agents/iris-web.md` — the frontend web
  specialist — is scaffolded; `frontend/web-public/` is not.

Nothing here breaks `task dev:up`. It is quieter than that: the project starts, and
what it runs does not match what it documents.

## The forward pointers were explicit

`infra/postgres/docker-compose.fragment.yml.tmpl`, in its own header: *"Compose into
the 2.0.0 dev stack at B.8.10/B.8.14."* Neither brick did. This is an unfulfilled
pointer, not an undiscovered gap.

## Scope — maintainer decision, 2026-09-10

Wire **pgvector and Zitadel**; leave the **Qwik surface opt-in**. Qwik is an entire
additional surface with its own toolchain and CI, not something the backend already
expects; pgvector and Zitadel are already referenced by files the project ships.

**In:** the 7 files of `infra/postgres` (3) and `infra/zitadel` (4); the
`docker-compose.dev.yml` splice that the fragments exist to be composed into; the
`.env.example` variables Zitadel needs.

**Out, and why it is not a judgement call:** `backend/crates/grpc-api` (4) and
`shared/protos` (2). `jwt_middleware.rs` is Zitadel's server-side JWT validation and
would belong — but it cannot ship without
`2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl`, which carries `connectrpc`, `buffa`
and `buffa-types`. Including it means shipping the whole **Connect-RPC** stack into
every new project, which is B.8.6's decision and neither pgvector nor Zitadel.

The boundary is coherent rather than merely convenient: `jwt_middleware.rs` declares
itself *"defense-in-depth"*. Primary JWT validation is done by Envoy's
`security-policy.yaml`, which fresh-init already ships. So this change delivers the
issuer (Zitadel) and the validator (Envoy); only the backend's second layer waits on
the Connect decision. Recorded as `open-questions.md` Q-001.

**Also out:** `frontend/web-public` (10) — the maintainer's opt-in call, Q-002.

## Negative scope

MUST NOT touch the frozen 1.0.0 templates, `scaffold-plan.yaml`, or
`migration-plan-2.0.0.yaml`. MUST NOT change the Envoy manifests already shipped.
