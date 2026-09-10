# Evidence — `t6-fsm-2-0-0-wiring`

All probes 2026-09-10.

---

## P-1 — the divergence, counted

```
2.0.0/ tree                        36 files
scaffold-plan-2.0.0.yaml (fresh)   13 entries
migration-plan-2.0.0.yaml           36 entries
```

The 23 absent from fresh-init: `frontend/web-public` 10, `backend/crates` 4,
`infra/zitadel` 4, `infra/postgres` 3, `shared/protos` 2 — i.e. B.8.5, B.8.6, B.8.7
and B.8.9 in their entirety.

## P-2 — the project referenced what it did not have

On a real `forge init` tree:

| token | referenced in N project files | present |
|---|---|---|
| `postgres` | 12 | `infra/postgres` **absent** |
| `pgvector` | 9 | absent |
| `zitadel` | 5 | `infra/zitadel` **absent** |
| `web-public` | 4 | absent |

The `zitadel` hits are not all prose: `infra/k8s/envoy-gateway/security-policy.yaml`
— a rendered manifest — cited `infra/zitadel/values-forge.yaml.tmpl` at line 22 for
its OIDC issuer.

And the 2.0.0 compose template itself contained **zero** occurrences of pgvector or
postgres:17, so B.8.5 had reached neither the plan nor the stack.

## P-3 — the forward pointer was explicit, and dated

`2.0.0/infra/postgres/docker-compose.fragment.yml.tmpl`, header:

> *"Compose into the 2.0.0 dev stack at B.8.10/B.8.14."*

Neither brick did. `scaffold-plan-2.0.0.yaml`'s own header records the other half:
*"wiring them into fresh-init is out of this brick's scope."*

## P-4 — the boundary is forced, not chosen

`jwt_middleware.rs` is Zitadel's server-side validator (22 mentions of
zitadel/oidc/jwt) and would belong with this wiring. It cannot ship alone:

```
2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl
  connectrpc  = { version = "=0.6.1", features = ["axum", "client"] }
  buffa        = "=0.6.0"
  buffa-types  = "=0.6.0"
```

Taking the middleware means shipping the Connect-RPC stack into every new project —
B.8.6's decision. Coherent to defer because the middleware's own docstring says
*"defense-in-depth"*: primary JWT validation is Envoy's `security-policy.yaml`, which
fresh-init already ships.

## P-5 — RED before GREEN

Three guards written first, run against the unwired tree:

```
  7 × "… is in the 2.0.0 tree but not in scaffold-plan-2.0.0.yaml"
  "the 2.0.0 compose still pins postgres:16-alpine"
  "declares no ZITADEL_DB_DSN / ZITADEL_MASTERKEY / ZITADEL_EXTERNALDOMAIN"
```

After wiring: **12/12 GREEN**.

## P-6 — the negative assertion fired on its own explanation

After the fix, `grep -qF 'postgres:16-alpine'` still failed — on the comment
explaining that the file *used to* pin it. The template documents what it excludes,
and an unfiltered grep reads that prose as the violation: the b9-2 T-013/T-014 trap.

Fixed by stripping comments. The stripping was first written as
`grep -vE '^\s*#' … | grep -qF …` — the exact `pipefail`/SIGPIPE shape swept out the
previous day. Rewritten as `grep -qF … < <(grep -vE …)`.

Two traps this repo has already paid for, both walked into within one edit.

## P-7 — the render, and what the first attempt taught

First render through the real CLI showed **none** of the changes: `postgres:16-alpine`,
no `fsm-zitadel`, no `infra/postgres`. `node cli/dist/index.js init` renders from
`cli/assets/` — a **bundled mirror** — not from `.forge/templates/`.

After `npm run bundle`:

```
  infra/postgres/init-pgvector.sql       présent
  infra/zitadel/values-forge.yaml        présent
  infra/zitadel/bootstrap.md             présent
  fsm-db image      : pgvector/pgvector:0.8.2-pg17
  fsm-zitadel présent: True
```

Compose parses; services list intact. `cli/assets/` is gitignored and regenerated, so
nothing to commit there — but a template edit verified only against
`.forge/templates/` proves nothing about what `forge init` does.

## P-8 — mutation probes

| probe | result |
|---|---|
| revert `fsm-db` to `postgres:16-alpine` | RED "still pins postgres:16-alpine" |
| delete the `fsm-zitadel` service | RED "no fsm-zitadel service" |
| (plan/tree guard) | proven by the 7-file RED in P-5 |

## P-9 — regression

- `b8-14-flip`, `b8-5`, **`b8-2`** (frozen 1.0.0 — must not drift), `c1`,
  `delivery`: all GREEN.
- `verify.sh` **629 / 0**; `constitution-linter.sh` **93 PASS / 0 FAIL, OVERALL
  PASS** — after the status flip.
- `shellcheck --severity=warning`: clean.
- Full 80-entry CI matrix sweep and `cli/` vitest: `tasks.md` T7.2.

Negative scope: no edit to `scaffold-plan.yaml`, the frozen 1.0.0 templates, or
`migration-plan-2.0.0.yaml` — a migrated project receives exactly what it received
yesterday.
