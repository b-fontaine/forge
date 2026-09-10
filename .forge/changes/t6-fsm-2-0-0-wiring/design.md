# Design — `t6-fsm-2-0-0-wiring`

## Three edits, one of which is the whole point

| file | change |
|---|---|
| `scaffold-plan-2.0.0.yaml` | +7 entries — `infra/postgres/**` (3), `infra/zitadel/**` (4) |
| `2.0.0/docker-compose.dev.yml.tmpl` | `fsm-db` → the pgvector service; `fsm-zitadel` added |
| `2.0.0/.env.example.tmpl` | `ZITADEL_DB_DSN`, `ZITADEL_MASTERKEY`, `ZITADEL_EXTERNALDOMAIN` |

The plan entries alone would change **nothing observable**: the directories would
land and the stack would still start `postgres:16-alpine`, because the fragments are
files nobody reads. The compose splice is what makes the wiring real, and it is what
the B.8.5 fragment header asked for — *"Compose into the 2.0.0 dev stack at
B.8.10/B.8.14"*.

The `.env` entries are not decoration either: `fsm-zitadel` dereferences
`${ZITADEL_DB_DSN}` and `${ZITADEL_MASTERKEY}` **without defaults**. Shipping the
service without them converts a working `task dev:up` into a failing one — the
day-one-red shape this project has now rejected twice (the `pwa-deploy` job, `npm ci`).

## Why splice rather than `include:`

Compose's `include:` would read the fragments directly, which reads cleaner. It needs
Compose v2.20+, and the archetype pins no Compose floor anywhere — adopting it would
add an unpinned toolchain requirement to save a copy-paste. The fragments stay in the
tree and ship, as the documented source of each block (ADR-T6W-001).

## The boundary, and why it is not arbitrary

`jwt_middleware.rs` is Zitadel's server-side JWT validator. It looks like it belongs
in "wire Zitadel" — and it cannot ship alone:
`2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl` carries `connectrpc = "=0.6.1"`,
`buffa` and `buffa-types`. Taking the middleware means shipping the **Connect-RPC**
stack into every new project, which is B.8.6's decision.

What makes the cut coherent rather than convenient: the middleware's own docstring
says *"defense-in-depth"*. Primary validation is Envoy's `security-policy.yaml`,
which fresh-init already ships. So after this change the issuer exists (Zitadel), the
validator exists (Envoy), and only the backend's second layer waits (ADR-T6W-002).

## Verification

1. Guards written first, run against the unwired tree → **RED naming all 7 missing
   files, `postgres:16-alpine`, and each absent `ZITADEL_*` variable**.
2. Wire. Re-run → GREEN.
3. Mutation-probe each assertion.
4. **Render through the real CLI** and inspect the result.

Step 4 is where the first attempt failed and taught something: `node cli/dist/index.js
init` renders from `cli/assets/`, a **bundled mirror**, not from `.forge/templates/`.
The first render showed none of the changes. `npm run bundle` in `cli/`, then the
render shows `fsm-db: pgvector/pgvector:0.8.2-pg17`, `fsm-zitadel` present, and the
7 files on disk. `cli/assets/` is gitignored and regenerated, so nothing to commit
there — but a template edit verified only against `.forge/templates/` proves nothing
about what `forge init` does.

## A trap this change walked into

The negative assertion `grep -qF 'postgres:16-alpine'` failed **after** the fix — on
the comment explaining that the file used to pin it. The template documents what it
excludes and an unfiltered grep reads that prose as the violation: the b9-2
T-013/T-014 trap. Fixed by stripping comments first.

And the comment-stripping was first written as `grep -vE '^\s*#' … | grep -qF …` —
the exact `pipefail` shape swept out yesterday. Rewritten as
`grep -qF … < <(grep -vE …)`.
