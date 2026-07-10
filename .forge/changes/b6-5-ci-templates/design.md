# Design: b6-5-ci-templates

<!-- Designed: 2026-07-10 -->
<!-- Routing: Atlas (infra/CI lead) + Vulcan/Ferris (Rust gate shape) + Eris (test strategy) -->
<!-- Grounding: full-stack-monorepo workflows (B.1.9) + event-driven-eu Taskfile & -->
<!--            docker-compose pins (B.6.2). No external version asserted from memory. -->

**Constitution** : v2.0.0 — no bump (additive). Gate at end: no Article violation.

## Architecture Decisions

### ADR-B6-CI-001 — Crate-scoped tests, workspace-scoped lint (ratified)
**Context**: the `event-driven-eu` backend is a SINGLE Cargo workspace with four
members. `full-stack-monorepo` split CI by directory (frontend vs backend); here
the split is WITHIN one workspace, by change surface. Running `task backend:test`
(`cargo test --workspace`) in each of the three workflows would compile+test the
whole workspace up to three times for a scoped change.
**Decision**: each workflow builds/tests only its surface crates —
`cargo build/test -p events -p eventstore` (forge-events), `-p saga`
(forge-workflows). The workspace-wide quality gate `task backend:lint`
(`cargo clippy --workspace --all-targets -- -D warnings` + `cargo fmt --all
--check`) is invoked per workflow: clippy is cheap relative to a full test run,
and a workspace-scoped clippy prevents a change in one crate from silently
breaking another's lint.
**Consequences**: honest per-layer split; `task backend:lint` is the shared
"reference the Task target" anchor; test steps use `cargo -p` (still the same
toolchain the Taskfile drives). Redundant clippy only when a change spans two
surfaces (rare; and then full coverage is desirable).

### ADR-B6-CI-002 — Non-blocking temporal-sdk leg via workflow_dispatch (ratified; Q-2)
**Context**: the `saga` crate's `temporal-sdk` feature pulls the pre-alpha
`temporalio-sdk`/`-client` (Public Preview; ADR-B6-2-004). Compiling it in the
PR gate is fragile. The archetype must nonetheless offer a way to exercise it.
The `ci-workflows.md` failure-semantics section forbids `continue-on-error: true`
in reference workflows.
**Decision**: ship the opt-in leg as a SEPARATE job `saga-temporal-sdk` gated
`if: github.event_name == 'workflow_dispatch'`. It runs `cargo test -p saga
--features temporal-sdk` and is clearly commented NON-BLOCKING. On
`pull_request`/`push` the job is skipped, so it can never gate a PR — achieving
"non-blocking" without `continue-on-error`. `on:` gains `workflow_dispatch`.
**Consequences**: default gate stays hermetic (no pre-alpha SDK); the opt-in leg
is a deliberate manual action; no forbidden failure-semantics pattern.

### ADR-B6-CI-003 — Postgres migration applied twice against a live server (ratified; Q-3)
**Context**: `init-eventstore.sql` uses `CREATE TABLE IF NOT EXISTS` +
`CREATE ... INDEX IF NOT EXISTS`, i.e. it is designed to be idempotent (it runs
via `docker-entrypoint-initdb.d`).
**Decision**: the infra workflow starts a `postgres:17-alpine` service and runs
`psql -v ON_ERROR_STOP=1 -f infra/postgres/init-eventstore.sql` twice. First run
= valid DDL against a real server; second run = idempotency proof (no error on
re-apply). `postgres:17-alpine` reuses the archetype's docker-compose pin.
**Consequences**: catches DDL typos AND non-idempotent statements that would
break a container restart. No app code / no sqlx needed.

### ADR-B6-CI-004 — No forge-integration analogue (ratified)
**Context**: the plan §6.1 B.6.5 names exactly three per-layer workflows. The
archetype has no frontend/E2E surface in the first cut (ADR-B6-2-003).
**Decision**: ship only the three named per-layer workflows. A cross-layer
integration workflow rides a later change that adds the ops-console.
**Consequences**: smaller, honest first cut; no dead docker-compose E2E job.

## Workflow shapes

```
forge-events.yml         forge-workflows.yml          forge-infra.yml
─────────────────        ────────────────────          ───────────────
filter (paths-filter)    filter (paths-filter)         filter (paths-filter)
  events/eventstore/       saga/ + Cargo.*               infra/ + shared/asyncapi/
  protos/ + Cargo.*
     │                        │                             │
     ▼ (if events)            ▼ (if saga)                   ▼ (if infra)
  build:                   saga:                         validate:
   rust toolchain           rust toolchain                nats-server -c … -t     (nats:2.10-alpine)
   cache cargo              cache cargo                    setup-node + setup-task
   setup-task               setup-task                     task asyncapi:validate
   task backend:lint        task backend:lint             psql -f init-eventstore.sql × 2  (postgres:17-alpine service)
   cargo build/test         cargo build/test               verify.sh
     -p events                -p saga (default feats)       constitution-linter.sh
     -p eventstore          verify.sh
   verify.sh                constitution-linter.sh
   constitution-linter.sh
                          saga-temporal-sdk:  (workflow_dispatch ONLY — NON-BLOCKING)
                            cargo test -p saga --features temporal-sdk
```

## Render safety (b6-2 T-L2-001 alignment)

- Only `<project-name>` appears as an angle-bracket placeholder (in the
  concurrency group) → `substitute: true`; `overlay.sh` replaces it.
- All GitHub `${{ … }}` expressions and the `dorny/paths-filter` `filters: |`
  block are NOT placeholders and survive render untouched.
- b6-5's L2 render-clean check mirrors b6-2 EXACTLY: it greps for a surviving
  `.tmpl` suffix and for `<(project-name|reverse-domain|root-module)>` — it does
  NOT grep for `{{`, which would false-positive on `${{ github.ref }}`.

## Coupling managed

- **b6-2.test.sh T-002** (plan↔tree): the three `.tmpl` files are added to
  `scaffold-plan.yaml`; b6-2 stays green (re-run in verification).
- **delivery.test.sh** `continue-on-error` guard: scoped to
  `full-stack-monorepo/.github/workflows/` only — does not scan event-driven-eu.
  b6-5 nonetheless forbids `continue-on-error` for consistency (FR-B6-CI-041).

## Testing Strategy (Eris)

- **L1 harness `b6-5.test.sh`** (hermetic): file existence, YAML parse + `name`/
  `on`, Task-target references, paths-filter scoping, temporal-sdk opt-in +
  non-blocking, Forge-gates-last, no continue-on-error, scaffold-plan
  registration.
- **L2 harness** (toolchain-gated): `overlay.sh` render → the three workflows
  land under `.github/workflows/*.yml`, no `.tmpl`/`<placeholder>` survives,
  each parses as valid YAML.
- **BDD**: the 4 `specs.md` scenarios → `features/b6-5-ci-templates.feature`,
  each cross-referencing the enforcing b6-5 test.
- **No-regression**: `b6-2.test.sh` L1+L2, `b6-1.test.sh`, `verify.sh`,
  `constitution-linter.sh`.

## Standards Applied

- `.forge/standards/infra/ci-workflows.md` (full-stack scope) — reused BY
  REFERENCE for conventions (paths-filter always-runs rationale, gate ordering,
  tool pinning, no-continue-on-error). NOT amended (out of scope).
- `orchestration.yaml` (Temporal, §VIII.2) — the feature-OFF-by-default posture
  the workflows honour.

## Constitutional Compliance Gate

- Article I (TDD): `b6-5.test.sh` RED→GREEN. ✅
- Article II (BDD): 4 scenarios authored. ✅
- Article III (Specs/anti-hal): NATS `-t`, `@asyncapi/cli validate`, image pins
  grounded in shipped archetype files. ✅
- Article VIII.2 (Temporal): default gate never compiles pre-alpha SDK;
  activity-only posture preserved. ✅
- Article X (Quality): Forge gates last; clippy `-D warnings`; no
  continue-on-error. ✅
- **No violation → gate PASS.**

---

**Gate**: Design complete. Next: `/forge:plan b6-5-ci-templates`.
