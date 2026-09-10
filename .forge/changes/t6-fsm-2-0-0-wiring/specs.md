# Specs — `t6-fsm-2-0-0-wiring`

**Namespace** : `FR-T6W-*`, `NFR-T6W-*`, `ADR-T6W-*`.

---

## Functional Requirements

### FR-T6W-001 — the 7 files render

`scaffold-plan-2.0.0.yaml` MUST reference all of `2.0.0/infra/postgres/**` (3) and
`2.0.0/infra/zitadel/**` (4), so a fresh `forge init` produces them.

### FR-T6W-002 — the datastore is actually pgvector

`2.0.0/docker-compose.dev.yml.tmpl`'s `fsm-db` service MUST use the pgvector image
the B.8.5 fragment pins (`pgvector/pgvector:0.8.2-pg17`) and MUST mount
`./infra/postgres/init-pgvector.sql` into `/docker-entrypoint-initdb.d/`.

Listing `infra/postgres/**` in the plan without this changes nothing observable: the
files would land and the stack would still start Postgres 16. The fragment header's
"compose into the 2.0.0 dev stack" is this requirement.

### FR-T6W-003 — Zitadel is a service, not just a directory

The same compose MUST carry the `fsm-zitadel` service from the B.8.7 fragment,
including its `depends_on: fsm-db: condition: service_healthy`.

### FR-T6W-004 — the environment the services need

`2.0.0/.env.example.tmpl` MUST declare every variable the two services dereference
without a default: `ZITADEL_DB_DSN`, `ZITADEL_MASTERKEY`, and `ZITADEL_EXTERNALDOMAIN`.

It currently declares **zero** `ZITADEL*` variables. Wiring the service without them
turns a working `task dev:up` into a failing one — the day-one-red outcome this
project has rejected twice already.

### FR-T6W-005 — no dangling reference remains for what we wired

After this change, no file rendered by fresh-init may point at a path under
`infra/postgres/` or `infra/zitadel/` that the project does not have.
`security-policy.yaml:22` is the known instance.

Scoped deliberately to the two wired surfaces: `web-public` references stay dangling
by decision, and FR-T6W-007 records that rather than hiding it.

### FR-T6W-006 — a guard on plan/tree agreement for the wired subset

A test MUST fail if `2.0.0/infra/postgres/**` or `2.0.0/infra/zitadel/**` gains a
file that the fresh-init plan does not reference. This is the drift that produced the
gap in the first place: files added to the tree, plan untouched.

### FR-T6W-007 — the remaining divergence is stated, not implied closed

The Qwik surface (10 files) and the Connect backend (6) stay out. `docs/` MUST say so
where an adopter would look, so "2.0.0" does not read as a single content.

---

## Non-Functional Requirements

### NFR-T6W-001 — migration output is unchanged

`migration-plan-2.0.0.yaml` still lists all 36 and must not be edited. A migrated
project keeps receiving what it received yesterday; this change only raises the
fresh-init floor toward it.

### NFR-T6W-002 — the frozen 1.0.0 line is untouched

No edit to `scaffold-plan.yaml` or any root-tree template. `b8-2.test.sh` green.

### NFR-T6W-003 — the compose stays valid

The spliced `docker-compose.dev.yml` must parse as YAML after rendering, with
`fsm-db` and `fsm-zitadel` both present and the volume/network definitions intact.

---

## ADRs

### ADR-T6W-001 — splice the fragments into the compose; do not use `include:`

**Context.** The two fragments define services (`fsm-db` redefined, `fsm-zitadel`
added) plus shared `volumes:`/`networks:`. Docker Compose has an `include:` key that
could pull them in as files.

**Decision.** Splice their content into `2.0.0/docker-compose.dev.yml.tmpl`.

**Rationale.** `include:` requires Compose v2.20+, which the archetype does not pin
anywhere — adopting it would add an unpinned toolchain floor to satisfy a template
convenience. The fragment's own header says "compose into the 2.0.0 dev stack",
i.e. merge, and the 2.0.0 compose already exists precisely as a spliced variant of
the 1.0.0 one. The fragments stay in the tree and ship, as the documented source of
each block.

### ADR-T6W-002 — the Zitadel backend middleware waits on the Connect decision

`jwt_middleware.rs` is Zitadel's server-side validator and would naturally belong.
It cannot ship without `2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl`, which carries
`connectrpc = "=0.6.1"`, `buffa` and `buffa-types` — so including it ships the whole
Connect-RPC stack into every new project. That is B.8.6's call, not this change's.

Coherent because the middleware declares itself *defense-in-depth*: Envoy's
`security-policy.yaml` performs the primary JWT validation and fresh-init already
ships it. This change delivers the issuer and keeps the validator; only the backend's
second layer is deferred.
