# Design: b8-5-postgres-pgvector

<!-- Status: designed -->
<!-- Schema: default -->
<!-- Audit: B.8.5 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0, RE-SCOPED: Postgres 16→17 + pgvector datastore brick; DBOS deferred — no Rust SDK; Temporal retained, Article VIII.2 preserved) -->

**Agents**: Atlas (datastore / dev-compose topology framing) + Eris (test strategy).
**Context7**: invoked during specify (`/pgvector/pgvector`, `docs.dbos.dev`); evidence frozen in `specs.md` § "Context7 Evidence". NOT re-invoked here — design records the image FAMILY + the extension-enable mechanism only; the concrete `pgvector/pgvector:pg17`-family tag is **verify-then-pin at `/forge:implement`** (NFR-B85-005, Q-004).
**Scope reminder**: this is the DESIGN phase. It ships **no template, no `orchestration.yaml` edit, no `2.0.0.yaml` edit, and no harness file**. It is the normative blueprint the impl phase realizes. The four maintainer-resolved decisions below (Q-001..Q-004) are encoded; the matching Q entries are flipped to answered in `open-questions.md` (independent reviewer + maintainer log). **No self-approval** — independent review follows before `/forge:plan`.

**CENTRAL FINDING carried from specify (Article III.4)**: DBOS has **NO Rust SDK** (crates.io `dbos` 404; DBOS Transact = Python / TypeScript / Go / Java only — Context7 `docs.dbos.dev`). This design therefore specs **NO** `dbos` crate pin, **NO** `Cargo.toml dbos = 0.x`, and **NO** DBOSContext boilerplate. DBOS is **DEFERRED**; **Temporal is RETAINED** as the 2.0.0 orchestrator for the Rust flagship (Article VIII.2 preserved, no amendment).

---

## Architecture Decisions

### ADR-B85-001 — Postgres-17 + pgvector dev datastore in the versioned 2.0.0 template subtree; flat 1.0.0 tree byte-untouched

**Context**: Q-001 (resolved maintainer 2026-05-31, **option a** — dev-compose fragment + init-SQL, NO k8s). The live 1.0.0 datastore is the dev `fsm-db` service in the FLAT tree at
`.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl:37-55`
(`image: postgres:16-alpine`, `POSTGRES_{DB,USER,PASSWORD}` env, named volume `fsm-db-data`, `pg_isready` healthcheck, network `fsm-dev`). The 1.0.0 K8s base (`infra/k8s/base/`) ships deployment/service/serviceaccount/ingress but carries **NO Postgres StatefulSet** — the dev compose is the **only** datastore manifest in the whole 1.0.0 tree (re-read this session). The B.8.4 precedent established the versioned subtree `.../full-stack-monorepo/2.0.0/...` (today: only `2.0.0/infra/k8s/envoy-gateway/**`).

**Decision**: The Postgres-17 + pgvector dev datastore is authored (at impl) under a NEW versioned subtree rooted at
`.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/postgres/`, as a **dev-compose fragment + an init-SQL + a README**, mirroring the 1.0.0 `fsm-db` *shape* bumped to the pgvector image. **NO k8s StatefulSet is added** — the 1.0.0 tree has none to mirror; a prod Postgres K8s surface, if ever needed, belongs to a later prod-hardening brick, not B.8.5 (the live 1.0.0 prod DB is external/managed, per the maintainer ground-truth: postgres is pinned ONLY in the dev compose). The flat 1.0.0 `docker-compose.dev.yml.tmpl` (`postgres:16-alpine`) is **byte-untouched**; the `2.0.0/infra/postgres/` subtree coexists with the flat 1.0.0 tree exactly as `2.0.0/infra/k8s/envoy-gateway/` (B.8.4) and `2.0.0.yaml` (B.8.3) coexist with their frozen 1.0.0 siblings.

**Consequences**: Zero touch to the frozen 1.0.0 surface; the B.8.2 sha256 guard (`b8-2.test.sh`) and `1.0.0.tar.gz` byte-identity (NFR-B85-003) stay GREEN; `git diff --name-only` shows only NEW paths under `.../2.0.0/infra/postgres/` plus the change dir, the orchestration.yaml additive edit + its REVIEW.md row, the `2.0.0.yaml` dbos-deferred annotation, the new harness, and the CI registration line. The 2.0.0 candidate is `scaffoldable: false`, so `forge init` continues to scaffold the flat 1.0.0 (`postgres:16-alpine`) datastore by default; the pgvector tree is an additive on-disk asset gating B.7 (RAG vector store) / B.8.12 / B.8.14. Teaching the scaffolder/snapshot tooling to *discover* the versioned datastore root is a **separate downstream concern** (parallels the B.8.4 / B.8.3.b deferral) — NOT done in B.8.5.

**Compliance**: Article IV (delta-based — additive sibling, no rewrite of the frozen surface); FR-B85-010/013; NFR-B85-003.

### ADR-B85-002 — Datastore template shape: dev-compose fragment + init-SQL + README (mirrors the 1.0.0 `fsm-db` shape)

**Context**: Q-001 (resolved, option a). The fragment must be a recognizable sibling of the 1.0.0 `fsm-db` service so B.8.10 (migration script) / B.8.12 (zero-regression) have a clean convergence target, and so the brick is freeze-safe (smallest additive delta over the only existing datastore manifest).

**Decision**: Three files under `2.0.0/infra/postgres/` (full shapes in § "Exact `2.0.0/infra/postgres/` Template Tree"):
1. **`docker-compose.fragment.yml.tmpl`** — a dev-compose service fragment declaring a `fsm-db` Postgres-17 + pgvector service that mirrors the 1.0.0 `fsm-db` shape: `POSTGRES_{DB,USER,PASSWORD}` env (same `<project-name>` placeholders + `${…}` defaults), a named data volume (`fsm-db-data`), a `pg_isready` healthcheck, network `fsm-dev`, and the init-SQL mounted into `docker-entrypoint-initdb.d`. The `image:` is a **verify-then-pin PLACEHOLDER** keyed to `persistence.yaml` (ADR-B85-003). It is a `fragment` (not a full compose file) so it does not duplicate / collide with the SigNoz/Kong/backend services in the flat 1.0.0 compose — it is the datastore *delta*, composable into the 2.0.0 dev stack at B.8.10/B.8.14.
2. **`init-pgvector.sql.tmpl`** — the extension-enable init script (`CREATE EXTENSION IF NOT EXISTS vector;`), mounted into `docker-entrypoint-initdb.d` so it runs once on first DB init (ADR-B85-003).
3. **`README.md.tmpl`** — documents the verify-then-pin image discipline, the init-SQL mechanism, that this is the 2.0.0 datastore delta over the frozen 1.0.0 `postgres:16-alpine`, and that the pgvector extension version target (`pgvector-0.8`) is policy-sourced from `persistence.yaml` (NOT pinned inline in the compose).

**Consequences**: The fragment is the recognizable 2.0.0 datastore delta; it is composable, freeze-safe, and consistent with the 1.0.0 `fsm-db` surface. No new datastore *surface shape* (k8s) is introduced (ADR-B85-001). Whether B.8.10 splices the fragment into a full 2.0.0 compose or the scaffolder discovers it is a downstream concern.

**Compliance**: FR-B85-010/012/013; ADR-B85-001.

### ADR-B85-003 — pgvector image family + extension-enable; concrete tag verify-then-pin at implement

**Context**: Q-004 (verify-then-pin item, not a multiple-choice design decision). Context7 (`/pgvector/pgvector`, frozen in `specs.md`) identifies the official Docker Hub image family `pgvector/pgvector:pg<MAJOR>-<distro>` (docs render `pg18-trixie` as the current example; the Postgres-17 family is the `pg17`-prefixed variant, e.g. `pgvector/pgvector:pg17` / `pgvector/pgvector:pg17-trixie`) and the extension-enable command `CREATE EXTENSION vector;` (once per database). The 2.0.0 delta requires Postgres **major 17** (over the 1.0.0 `postgres:16-alpine` baseline) with pgvector ≥ 0.8 (`persistence.yaml`). The kong / b8-coroot / b8-signoz lesson: image pins are verified LIVE on the registry, never fabricated upstream of `/forge:implement`.

**Decision**: The design fixes the image FAMILY + the extension-enable MECHANISM but leaves the concrete tag a clearly-marked **verify-then-pin PLACEHOLDER**, resolved live at `/forge:implement`:
1. **Image family**: `pgvector/pgvector:pg17`-family. In the `docker-compose.fragment.yml.tmpl` the `image:` value is the placeholder token **`pgvector/pgvector:VERIFY_THEN_PIN`** (Postgres major **17** is asserted in a comment + the README; the distro suffix — `pg17` vs `pg17-trixie` — and exact tag are resolved by `docker manifest inspect` / Docker Hub tag listing at implement). The token deliberately carries no `pg17`-vs-`pg17-trixie` literal so no fabricated concrete tag is asserted as registry-verified (Article III.4).
2. **Extension-enable mechanism**: an init SQL (`init-pgvector.sql.tmpl`) mounted into `docker-entrypoint-initdb.d`, running `CREATE EXTENSION IF NOT EXISTS vector;`. This is explicit (the brick does NOT rely on the extension being implicitly present — the image ships the extension *files*, but the extension MUST be `CREATE EXTENSION`-d in the target database — FR-B85-012).
3. **Extension version target**: `pgvector-0.8` is policy-sourced from `persistence.yaml` (`extensions: [pgvector-0.8, …]`); it is NOT a scalar in the compose/init (no inline pin).

At `/forge:implement` the live check resolves the concrete tag and the `VERIFY_THEN_PIN` token is replaced with the registry-verified tag string; the impl records the verification (manifest digest / Docker Hub listing) in an `evidence.md`, mirroring b8-4. **The design + the authored templates assert NO concrete tag as verified** (NFR-B85-005). If the live registry does not carry a `pg17`-family pgvector image at implement, the impl surfaces `[NEEDS CLARIFICATION]` rather than guessing.

**Consequences**: No premature pin = no Article III.4 anti-hallucination failure; the b8-5 harness includes an anti-hallucination grep-guard asserting the `image:` is either the `VERIFY_THEN_PIN` placeholder OR a verified `pgvector/pgvector:pg17`-prefixed tag (NOT an unsourced/fabricated concrete tag) — see Test Strategy T-005.

**Compliance**: Article III.4 (Anti-Hallucination); NFR-B85-005; FR-B85-011/012/030.

### ADR-B85-004 — persistence.yaml is CONSUMED, not authored (no new standard, no bump)

**Context**: ADR seed (resolved). The pin source PRE-EXISTS — this is the key CONTRAST with B.8.4, which had to *create* `gateway.yaml` because no `*.yaml` standard pinned a gateway. Re-read this session: `.forge/standards/persistence.yaml` v1.0.0 (ADR-010, T.4) already declares `default: postgres-17` + `extensions: [pgvector-0.8, postgis, timescaledb]`, complete J.7 frontmatter, and the `2.0.0.yaml` `postgres-17-pgvector` component already cites `standard: persistence.yaml` (b8-3 T-011 GREEN today).

**Decision**: B.8.5 **consumes** `persistence.yaml` v1.0.0 as the policy source for the Postgres-17 default + the pgvector-0.8 extension target. It MUST NOT create a new persistence standard and MUST NOT bump `persistence.yaml`. The concrete Postgres-17 + pgvector-0.8 *policy* lives in `persistence.yaml`; the concrete *image tag* lives in the verify-then-pin compose placeholder (ADR-B85-003); NEITHER is an inline scalar in `2.0.0.yaml`. The `2.0.0.yaml` `postgres-17-pgvector` component's `standard: persistence.yaml` ref is left **as-is** and keeps resolving (b8-3 T-011), and the component's `migration_note` + the `postgres-16-no-pgvector → postgres-17-pgvector` migration_delta are left **intact** and are now **actively delivered** by this brick (b8-3 T-016 preserved).

**Consequences**: No standards-lifecycle event for `persistence.yaml` (no version bump, no REVIEW.md row for it); the only standard touched is `orchestration.yaml` (ADR-B85-005, the DBOS-deferral). The `2.0.0.yaml` postgres component is UNCHANGED — only the `dbos-embedded` component + its delta are annotated (ADR-B85-006).

**Compliance**: Article IV (delta-based — persistence.yaml untouched); FR-B85-014/020/021; b8-3 T-011/T-016.

### ADR-B85-005 — orchestration.yaml additive bump 1.0.0 → 1.1.0 + DBOS-Rust-deferred body field + REVIEW.md row; `default: dbos` UNCHANGED but recorded as a **language-conditional** (aspirational non-Rust) target

**Context**: Q-002 (resolved maintainer 2026-05-31, **option a** — version bump + body field + REVIEW.md row). `.forge/standards/orchestration.yaml` v1.0.0 (ADR-002, T.4) declares `default: dbos`, `fallback: temporal`, `fallback_trigger: …`, `forbidden: [inngest]`, and the REVIEW.md seed (2026-05-04) already flags *"orchestration.yaml … DBOS-rs maturity (< 1 year prod) to revisit"*. The `transport.yaml` 1.0.0 → 1.1.0 → 1.2.0 + `observability.yaml` → 2.1.0 additive-bump precedent (KEEP-WITH-CHANGES body fields + REVIEW.md rows) is the canonical shape for an additive standard bump.

**Decision**: B.8.5 (at impl) bumps `orchestration.yaml` **1.0.0 → 1.1.0** as an **additive** edit, mirroring `transport.yaml`'s 1.0.0 → 1.1.0:
- **Frontmatter delta**: `version: "1.1.0"`; `last_reviewed: 2026-05-31`; `expires_at: 2027-05-31` (resets the 12-month cycle, preserving `expires_at > last_reviewed` strict ordering — FR-J7-021, the canonical enforcement pair). `exception_constitutional: false` is **kept** (dated expiry ⇒ exc:false, FR-J7-020 coupling — orchestration.yaml is not structural). `linter_rule: null`, `enforcement`, `forbidden: [inngest]` are **unchanged**.
- **Body field** (additive — root `additionalProperties: true`, the gateway.yaml/observability.yaml `versions:`/`pin_review_cadence:` precedent): a new top-level block, e.g.

  ```yaml
  rust_sdk_status:
    dbos:
      available: false        # DBOS has NO Rust SDK (verified 2026-05-31)
      verified: 2026-05-31
      evidence: >
        crates.io has no `dbos` crate (cargo add dbos → 404). DBOS Transact
        ships SDKs for Python, TypeScript, Go, and Java only (Context7
        docs.dbos.dev quickstart + explanations/portable-workflows). The
        crates.io alternatives (durable-rust, raftoral) are too immature for
        the flagship. There is no `dbos` crate to pin and no DBOSContext to
        scaffold for a Rust backend today.
      rust_flagship_orchestrator: temporal   # RETAINED until a Rust DBOS SDK ships (Article VIII.2 preserved)
      default_is_language_conditional: true
      note: >
        `default: dbos` below is a LANGUAGE-CONDITIONAL aspirational target for
        non-Rust contexts (Python/TypeScript/Go/Java, where a DBOS SDK exists).
        It is NOT an active selection for the Rust flagship: for Rust, Temporal
        is the orchestrator (fallback: temporal applies; Article VIII.2 Temporal
        SHALL preserved, no amendment). `default: dbos` is therefore left
        UNCHANGED but is explicitly recorded here as aspirational/non-Rust, not
        a deployed Rust default.
  ```
  `default: dbos` + `fallback: temporal` + `fallback_trigger:` semantics remain parseable and **UNCHANGED** in value. The body field is the machine-readable + prose record that (per the review nit) the `dbos` default is **language-conditional**, not a live Rust selection — recorded explicitly, not merely left "unchanged."
- **REVIEW.md row** (append-only, Article XII): a new H2 section dated 2026-05-31 carrying a KEEP-WITH-CHANGES row whose cells satisfy the FR-J7-023 full-ledger drift anchor `\|\s*orchestration\.yaml\s*\|\s*1\.1\.0\s*\|` — the basename `orchestration.yaml` and the version `1.1.0` MUST be exactly those cells (see § "REVIEW.md row" below). This row is **MANDATORY**: the J.7 validator FAILs the bumped file if `1.1.0` is absent from the ledger (FR-J7-023, validate-standards-yaml.sh:320-328).

**Why `default: dbos` stays**: removing or flipping `default` would be a *breaking* policy change to a ratified standard, out of scope for an additive B.8.5 edit and unnecessary — the Rust flagship's behavior is governed by `rust_sdk_status` + `fallback: temporal`, and the non-Rust archetypes where a DBOS SDK exists still legitimately default to DBOS. The body field makes the language-conditionality explicit.

**Consequences**: Full standards-lifecycle traceability (J.7 + append-only ledger), directly mirroring `transport.yaml`'s additive 1.0.0 → 1.1.0. The bump keeps `validate-standards-yaml.sh` GREEN (J.7 dir-mode): frontmatter complete, FR-J7-020 coupling satisfied (`exc:false` ⇔ dated expiry), FR-J7-021 ordering satisfied (`2027-05-31 > 2026-05-31`), FR-J7-023 satisfied (the REVIEW.md `1.1.0` row). **No index.yml change** — `orchestration.yaml` is already registered (an additive body field + version bump does not change its trigger entry).

**Compliance**: `standards-lifecycle.md` (J.7 standard contract); Article XII (Governance — REVIEW.md append-only); Article VIII.2 (Temporal retained — preserved, no amendment); FR-B85-002/003/004; NFR-B85-006.

### ADR-B85-006 — 2.0.0.yaml dbos-embedded annotated `status: deferred` + `note:`; temporal→dbos delta annotated deferred; postgres delta INTACT — keeps b8-3 (17 L1) + b8-3b (12 L1) GREEN

**Context**: Q-003 (resolved maintainer 2026-05-31, **option a** — `status: deferred` + `note:` on the component + a `note:` on the delta). Editing `2.0.0.yaml` is permitted because it is the **candidate**, not the frozen 1.0.0 `schema.yaml` (b8-3 T-014 / b8-3b T-012 untouched). b8-3.test.sh is tightly coupled (re-read this session, b8-3.test.sh:104-162): forbidden component keys = exactly `{version, pin, image}` (T-012); no component direct-scalar value may match `^\d+\.\d+` (T-015, a `for k,v in c.items()` value-walk over `components` only); every `standard:` ref must resolve (T-011); every component needs a `name` (T-010); the postgres component must keep its `migration_note` + a `from=postgres-16*` delta must exist (T-016).

**Decision**: Two annotations to `2.0.0.yaml` (impl phase, NOT here):
1. The `dbos-embedded` component gains `status: deferred` + `note:` (free-text prose), e.g.:
   ```yaml
     - name: dbos-embedded
       role: workflow-orchestration
       replaces: temporal-intent
       delivered_by: B.8.5
       standard: orchestration.yaml  # default: dbos (language-conditional; see orchestration.yaml rust_sdk_status)
       status: deferred              # B.8.5 — DBOS has NO Rust SDK (verified 2026-05-31); Temporal RETAINED for the Rust flagship (Article VIII.2 preserved)
       note: >
         DBOS Transact ships Python/TypeScript/Go/Java only; there is no Rust
         crate (crates.io dbos 404). For the Rust flagship Temporal is retained
         until a production-grade Rust DBOS SDK ships. See orchestration.yaml
         v1.1.0 rust_sdk_status.
   ```
2. The `temporal-intent → dbos-embedded` migration_delta gains a `note:` marking it deferred:
   ```yaml
     - from: temporal-intent
       to: dbos-embedded
       brick: B.8.5
       note: >
         DEFERRED — DBOS has no Rust SDK (verified 2026-05-31); replaces
         documented intent, not a live workflow system. Temporal retained for
         the Rust flagship (Article VIII.2 preserved). Re-evaluated when a Rust
         DBOS SDK ships.
   ```

The `postgres-17-pgvector` component (its `migration_note` + `standard: persistence.yaml`) and the `postgres-16-no-pgvector → postgres-17-pgvector` migration_delta are left **INTACT** — the postgres delta is now actively delivered (NOT deferred). The postgres component is UNCHANGED by this brick (it already references persistence.yaml).

**Why this keeps b8-3 + b8-3b GREEN** (the critical coupling — confirmed against b8-3.test.sh source this session):
- **b8-3 T-010** (every component has `name`): GREEN — `dbos-embedded` keeps its `name`; no component removed.
- **b8-3 T-011** (every `standard:` ref resolves): GREEN — `dbos-embedded` keeps `standard: orchestration.yaml`, which still resolves (the file still exists; the 1.1.0 bump does not rename it); `postgres-17-pgvector` keeps `standard: persistence.yaml`.
- **b8-3 T-012** (no forbidden inline pin key `{version, pin, image}`): GREEN — `status` and `note` are NOT in the forbidden set (the validator does an exact key-set intersection `set(c.keys()) & {'version','pin','image'}`); `status`/`note` add no forbidden key.
- **b8-3 T-015** (no component direct-scalar matches `^\d+\.\d+`): GREEN — `status: deferred` is the scalar `"deferred"` (no leading digits); `note:` is a folded-scalar prose string that does NOT start with `\d+\.\d+` (it starts with "DBOS …"). **CRITICAL DRAFTING RULE**: the `note:` prose MUST NOT begin with a `\d+\.\d+` token (e.g. must not start with `"0.8 …"` or a bare version). The dated `2026-05-31` inside the prose is safe because (a) it is mid-string, not the start, and (b) T-015 uses `version_re.match` (anchored at start) on the *full scalar value*, and the value starts with a letter. The delta `note:` lives under `migration_deltas`, which T-015 does **NOT walk at all** (T-015 iterates `components` only) — so the delta annotation is unconstrained by T-015.
- **b8-3 T-016** (postgres component has `migration_note` + a `from=postgres-16*` delta): GREEN — both are left intact (the postgres component is untouched; the `postgres-16-no-pgvector` delta stays). Annotating the *temporal* delta does not affect the postgres delta.
- **b8-3 T-013** (migration_deltas non-empty): GREEN — adding a `note:` to an existing delta does not reduce the count.
- **b8-3 T-003/004/005/006/007/008/009/017** (name/version/stage/scaffoldable/tdd/layers/surfaces/bump_at): all unaffected — only the `dbos-embedded` component + the temporal delta gain prose keys.
- **b8-3b T-003/T-004** (live `validate-foundations.sh` exits 0 + PASS for `full-stack-monorepo/2.0.0.yaml`): GREEN — the versioned-schema discovery checks `filename ⇔ version` (`2.0.0.yaml` still `version: "2.0.0"`) and `candidate ⇒ scaffoldable: false` (both unchanged). The `status`/`note` annotations touch neither invariant.
- **b8-3b T-012** (frozen `schema.yaml` byte-identity, still `version: "1.0.0"`): GREEN — `schema.yaml` is NOT touched (only the candidate `2.0.0.yaml`).

**Consequences**: The candidate honestly records the DBOS deferral without breaking the b8-3/b8-3b coupling. **No companion b8-3 test update is needed** (Q-003 sub-question): the deferral is asserted positively by the **new b8-5 harness** (T-006), not by b8-3 — b8-3 stays the candidate-structure gate, b8-5 owns the dbos-deferred positive assertion + the exit-code coupling guard (T-009).

**Compliance**: Article IV (additive candidate edit — permitted, not the frozen schema); Article VIII.2 (Temporal retained); FR-B85-005/006/014; b8-3 T-010/011/012/015/016 + b8-3b T-003/004/012.

---

## Exact `2.0.0/infra/postgres/` Template Tree (impl deliverable, NOT created here)

All files use the 1.0.0 conventions: `.tmpl` extension, `<project-name>` angle-bracket placeholder, `${VAR:-default}` env defaults, and a leading `# <!-- Audit: B.8.5 (b8-5-postgres-pgvector, FR-B85-NNN) -->` comment. The image tag is a verify-then-pin PLACEHOLDER per ADR-B85-003.

```
.forge/templates/archetypes/full-stack-monorepo/2.0.0/
└── infra/
    └── postgres/
        ├── docker-compose.fragment.yml.tmpl   # fsm-db Postgres-17 + pgvector dev service (VERIFY_THEN_PIN image)
        ├── init-pgvector.sql.tmpl             # CREATE EXTENSION IF NOT EXISTS vector;
        └── README.md.tmpl                      # verify-then-pin discipline + init mechanism + persistence.yaml policy ref
```

### `docker-compose.fragment.yml.tmpl` (FR-B85-010/011/013)
A dev-compose **service fragment** mirroring the 1.0.0 `fsm-db` shape (`docker-compose.dev.yml.tmpl:37-55`), bumped to the pgvector image + the init-SQL mount:

```yaml
# <!-- Audit: B.8.5 (b8-5-postgres-pgvector, FR-B85-010/011/012/013) -->
#
# 2.0.0 datastore DELTA — Postgres 17 + pgvector dev service. ADDITIVE sibling of
# the FROZEN flat 1.0.0 docker-compose.dev.yml.tmpl fsm-db (postgres:16-alpine),
# which is BYTE-UNTOUCHED (B.8.2 freeze; ADR-B85-001). Compose into the 2.0.0 dev
# stack at B.8.10/B.8.14. Postgres major 17 (the 2.0.0 delta over 1.0.0's 16).
#
# IMAGE = VERIFY-THEN-PIN (ADR-B85-003 / Q-004): the concrete
# pgvector/pgvector:pg17-family tag (distro suffix) is resolved LIVE at
# /forge:implement (docker manifest inspect / Docker Hub tag listing), NEVER
# fabricated here (Article III.4; kong/b8-coroot/b8-signoz lesson). pgvector
# extension version target = pgvector-0.8 (policy: persistence.yaml — NOT pinned
# inline here).
services:
  fsm-db:
    image: pgvector/pgvector:VERIFY_THEN_PIN   # verify-then-pin — pgvector/pgvector:pg17-family, Postgres major 17 (ADR-B85-003)
    env_file: .env
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-<project-name>_dev}
      POSTGRES_USER: ${POSTGRES_USER:-<project-name>_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${FSM_DB_PORT:-5432}:5432"
    volumes:
      - fsm-db-data:/var/lib/postgresql/data
      # init-SQL — runs CREATE EXTENSION IF NOT EXISTS vector; once on first DB init
      - ./infra/postgres/init-pgvector.sql:/docker-entrypoint-initdb.d/init-pgvector.sql:ro
    networks:
      - fsm-dev
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-<project-name>_user} -d ${POSTGRES_DB:-<project-name>_dev}"]
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 10s

volumes:
  fsm-db-data:

networks:
  fsm-dev:
    driver: bridge
    name: fsm-dev
```
The `image:` token `pgvector/pgvector:VERIFY_THEN_PIN` carries Postgres-major-17 intent in its comment but asserts **no** concrete distro tag. The `init-pgvector.sql` mount under `docker-entrypoint-initdb.d` is the extension-enable mechanism. Env/volume/healthcheck/network mirror the 1.0.0 `fsm-db` verbatim (departures: the image + the init mount — both justified by the pgvector delta, FR-B85-013).

### `init-pgvector.sql.tmpl` (FR-B85-012)
```sql
-- <!-- Audit: B.8.5 (b8-5-postgres-pgvector, FR-B85-012) -->
-- Enable pgvector in the <project-name> database. Runs once on first DB init via
-- docker-entrypoint-initdb.d (ADR-B85-003). The image ships the extension files;
-- this CREATE EXTENSION makes it available in the target database. pgvector
-- extension version target = pgvector-0.8 (policy: persistence.yaml).
CREATE EXTENSION IF NOT EXISTS vector;
```
`IF NOT EXISTS` is idempotent (re-runnable / safe under restart). The bare `CREATE EXTENSION vector` substring is present for the harness grep (FR-B85-052 / T-003).

### `README.md.tmpl` (FR-B85-010, ADR-B85-002/003)
Documents: (a) this is the **2.0.0 datastore delta** over the frozen 1.0.0 `postgres:16-alpine` (additive, ADR-B85-001); (b) the image is **verify-then-pin** — `pgvector/pgvector:pg17`-family, concrete tag resolved live at `/forge:implement`, never fabricated (Article III.4); (c) the extension is enabled by `init-pgvector.sql` via `docker-entrypoint-initdb.d`; (d) the Postgres-17 default + the pgvector-0.8 extension target are policy-sourced from `.forge/standards/persistence.yaml` (NOT pinned inline). NO k8s manifest is shipped (the 1.0.0 tree has no Postgres StatefulSet; ADR-B85-001).

---

## `orchestration.yaml` 1.1.0 Bump (impl deliverable, NOT created here)

The ONLY change to `orchestration.yaml` (impl phase, NOT here) is the additive 1.0.0 → 1.1.0 bump of ADR-B85-005. Frontmatter delta + the additive `rust_sdk_status:` body field; `default: dbos` / `fallback: temporal` / `fallback_trigger:` / `forbidden: [inngest]` UNCHANGED in value.

**Before** (current, re-read this session):
```yaml
version: "1.0.0"
last_reviewed: 2026-05-04
expires_at: 2027-05-04
exception_constitutional: false
...
default: dbos
fallback: temporal
fallback_trigger: "workflow_volume_per_day_gt_10000 OR cross_service_count_gt_10"
```
**After** (B.8.5):
```yaml
version: "1.1.0"           # B.8.5 — additive bump (DBOS-Rust-deferred record; transport.yaml 1.0.0→1.1.0 precedent)
last_reviewed: 2026-05-31  # reset (FR-J7-021 ordering: expires_at > last_reviewed)
expires_at: 2027-05-31     # 12-month cycle reset
exception_constitutional: false  # dated expiry ⇒ exc:false (FR-J7-020 — unchanged)
...
default: dbos              # UNCHANGED — language-conditional aspirational target (see rust_sdk_status)
fallback: temporal
fallback_trigger: "workflow_volume_per_day_gt_10000 OR cross_service_count_gt_10"

rust_sdk_status:           # additive body field (ADR-B85-005; root additionalProperties:true)
  dbos:
    available: false
    verified: 2026-05-31
    rust_flagship_orchestrator: temporal
    default_is_language_conditional: true
    note: > ...           # full shape in ADR-B85-005
```

**Why this keeps J.7 (`validate-standards-yaml.sh`) GREEN** (confirmed against the validator source this session, lines 277-328):
- **Frontmatter required set** (`version, last_reviewed, expires_at, exception_constitutional, linter_rule, enforcement{ci_blocking,pre_commit_hook}, forbidden, rationale`): all present + unchanged in shape; only `version`/`last_reviewed`/`expires_at` values move.
- **FR-J7-005** (`expires_at` ISO date OR `never`): `2027-05-31` is a valid ISO date.
- **FR-J7-020** (Article XII coupling): dated `expires_at` ⇒ `exception_constitutional: false` — kept `false`. GREEN.
- **FR-J7-021** (strict ordering): `2027-05-31 > 2026-05-31`. GREEN (this is the canonical enforcement pair).
- **FR-J7-023** (REVIEW.md drift): `version: "1.1.0"` MUST appear as a ledger row `| orchestration.yaml | 1.1.0 |` — provided by the REVIEW.md row below. Without it the validator FAILs. The row is MANDATORY.
- **FR-J7-040/041** (`forbidden` shape): `forbidden: [inngest]` is a non-empty, trimmed, no-duplicate string list. GREEN.
- **Additive body field**: `rust_sdk_status:` is a new top-level key — allowed by root `additionalProperties: true` (the gateway.yaml `versions:`/`controller_name:`/`pin_review_cadence:` + observability.yaml `versions:` precedent, ADR-J7-004). It introduces no semver in a `version`-typed field (the only `^\d+\.\d+\.\d+$` check is on the top-level `version` field, which stays `1.1.0`).

### REVIEW.md row (FR-J7-023, FR-B85-004) — MANDATORY for the bump
Append-only H2 section (mirrors the `transport.yaml` 1.0.0 → 1.1.0 KEEP-WITH-CHANGES precedent), carrying a table row whose `| orchestration.yaml | 1.1.0 |` cells satisfy the FR-J7-023 full-ledger drift anchor `\|\s*orchestration\.yaml\s*\|\s*1\.1\.0\s*\|`:

```markdown
## 2026-05-31 — Updated orchestration.yaml to v1.1.0 (b8-5-postgres-pgvector)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard           | Version | Decision           | Next review due | Notes                                                                                                                                                                                                          |
  |--------------------|---------|--------------------|-----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | orchestration.yaml | 1.1.0   | KEEP-WITH-CHANGES  | 2027-05-31      | Additive. Added `rust_sdk_status.dbos` block recording DBOS has NO Rust SDK (crates.io dbos 404; DBOS Transact = Python/TypeScript/Go/Java only — Context7 docs.dbos.dev). Temporal RETAINED for the Rust flagship (Article VIII.2 preserved). `default: dbos` UNCHANGED — recorded as a language-conditional aspirational non-Rust target, not a deployed Rust default. Closes the seed-entry "DBOS-rs maturity to revisit" concern. |

- **Decision**: KEEP-WITH-CHANGES
- **Next review due**: 2027-05-31
- **Notes**: Updated by `b8-5-postgres-pgvector` (B.8.5). Additive minor bump
  mirroring `transport.yaml` 1.0.0 → 1.1.0. `exception_constitutional: false`
  preserved (dated expiry, FR-J7-020); `last_reviewed` resets to 2026-05-31,
  `expires_at` to 2027-05-31 (FR-J7-021 ordering). The DBOS-Rust-absent finding
  was verified 2026-05-31 (Context7 `docs.dbos.dev`; crates.io `dbos` 404). No
  constitutional amendment — Article VIII.2 (Temporal SHALL) is PRESERVED by
  retaining Temporal (a compliance positive over the abandoned DBOS plan, which
  would have replaced Temporal and thus needed the B.8.14 VIII.2 amendment).
```
**Note on the FR-J7-023 anchor**: the validator keys the drift regex on `os.path.basename(path)` (validate-standards-yaml.sh:321-324): `base = orchestration.yaml`, needle `\|\s*orchestration\.yaml\s*\|\s*1\.1\.0\s*\|`. The REVIEW.md cell MUST be exactly the basename `orchestration.yaml` and the version `1.1.0`, with a table pipe immediately before each. The b8-5 harness asserts `validate-standards-yaml.sh` (dir mode) PASSes, which transitively proves the row matches (T-007).

**No index.yml change**: `orchestration.yaml` is already registered as a root-level standard trigger entry; an additive body field + version bump does not change its `path:`/`triggers:` — so unlike B.8.4 (which added a NEW standard requiring a NEW index.yml entry), B.8.5 adds NO index.yml entry.

---

## `2.0.0.yaml` dbos-deferred Annotation (candidate edit — permitted, ADR-B85-006)

Two annotations (impl phase, NOT here), shapes in ADR-B85-006: (1) `dbos-embedded` component gains `status: deferred` + `note:`; (2) the `temporal-intent → dbos-embedded` migration_delta gains a `note:`. The postgres component + the `postgres-16-no-pgvector → postgres-17-pgvector` delta are INTACT. See ADR-B85-006 for the full b8-3/b8-3b GREEN proof.

### Implementation Ordering (protects b8-3 + b8-3b — 17 L1 + 12 L1 GREEN)

Unlike B.8.4 (whose `2.0.0.yaml` `standard: gateway.yaml` edit had a hard ordering dependency on the gateway.yaml standard file existing FIRST, for b8-3 T-011), B.8.5 has **NO resolution-order trap**: the `dbos-embedded` component already carries `standard: orchestration.yaml`, which already resolves; B.8.5 does NOT add a new `standard:` ref and does NOT rename `orchestration.yaml`. The `status`/`note` annotations add only prose keys. So the `2.0.0.yaml` edit and the `orchestration.yaml` bump are **order-independent for T-011** (the ref resolves before and after). Still, the recommended impl sequence (TDD RED-first per Article I):

1. **RED**: commit `b8-5.test.sh` with all ~12 assertions before any impl artifact exists. The tree-presence / orchestration-bump / dbos-deferred assertions fail RED (no tree, no bump, no annotation).
2. **GREEN — orchestration.yaml bump**: edit `orchestration.yaml` 1.0.0 → 1.1.0 (frontmatter + `rust_sdk_status:`), append the REVIEW.md `1.1.0` row, then validate in **DIRECTORY mode**: `bash bin/validate-standards-yaml.sh .forge/standards/` → exit 0 + `[STD-PASS] …orchestration.yaml`. Directory mode is required (the FR-J7-023 REVIEW.md ledger drift check is a Phase-2 cross-cutting block that only runs in directory context — the b8-4 lesson). The non-recursive `"$target"/*.yaml` glob (validate-standards-yaml.sh:67 == verify.sh:650) already picks up the root-level `orchestration.yaml`.
3. **GREEN — 2.0.0.yaml annotation**: add `status: deferred` + `note:` to `dbos-embedded` + a `note:` to its delta. Re-run `b8-3.test.sh --level 1` (17/17) + `b8-3b.test.sh --level 1` (12/12) → GREEN.
4. **GREEN — template tree**: author `2.0.0/infra/postgres/{docker-compose.fragment.yml.tmpl, init-pgvector.sql.tmpl, README.md.tmpl}` (no harness coupling; additive).
5. **GREEN — image verify-then-pin**: at this step, run the LIVE registry check (`docker manifest inspect` / Docker Hub tag listing) for the `pgvector/pgvector:pg17`-family tag, replace the `VERIFY_THEN_PIN` token with the verified tag, and record the digest in `evidence.md`. If unresolvable, surface `[NEEDS CLARIFICATION]`.
6. **GREEN — register**: append `"b8-5.test.sh --level 1"` to `forge-ci.yml` (after the `b8-4.test.sh --level 1` line, line 110). Re-run b8-5 → 12/12, and b8-3 (17/17) + b8-3b (12/12) stay GREEN (T-009).

The atomic-commit alternative (all edits in one commit) is equivalent and also safe, since there is no T-011 resolution-order trap.

---

## `b8-5.test.sh` Harness Test Strategy (Eris)

**File**: `.forge/scripts/tests/b8-5.test.sh`
**Level**: L1 only (hermetic, ≤ 5 s, zero net/Docker), mirroring `b8-3.test.sh` / `b8-4.test.sh` structure (`--level` flag + `source _helpers.sh` + `run_test` / `print_summary`).
**Registration**: one line `"b8-5.test.sh --level 1"` appended to the `harnesses=( … )` loop in `forge-ci.yml` (after `b8-4.test.sh --level 1`, line 110), preserving the NFR-CI-002 ≤ 300-line budget.

### L1 Assertion List (12 L1 tests)

| # | FR / NFR | Assertion | Implementation |
|---|----------|-----------|----------------|
| T-001 | FR-B85-051 / ADR-B85-001 | The `2.0.0/infra/postgres/` tree exists with the 3 expected files (`docker-compose.fragment.yml.tmpl`, `init-pgvector.sql.tmpl`, `README.md.tmpl`) | `[ -f "$PG_DIR/<name>" ]` per file |
| T-002 | FR-B85-011 / ADR-B85-003 | The compose fragment declares a Postgres-17 + pgvector image from the `pgvector/pgvector` family (either the `VERIFY_THEN_PIN` placeholder OR a verified `pgvector/pgvector:pg17`-prefixed tag) | grep `image: pgvector/pgvector:` in the fragment |
| T-003 | FR-B85-012 / FR-B85-052 / ADR-B85-003 | The init-SQL enables the extension via `CREATE EXTENSION ... vector` AND the fragment mounts it into `docker-entrypoint-initdb.d` | grep `CREATE EXTENSION` + `vector` in init SQL; grep `docker-entrypoint-initdb.d` in fragment |
| T-004 | FR-B85-013 / ADR-B85-002 | The fragment mirrors the 1.0.0 `fsm-db` shape: `pg_isready` healthcheck + a named `fsm-db-data` volume + `POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD` env | grep each sentinel in the fragment |
| T-005 | NFR-B85-005 / FR-B85-030 / ADR-B85-003 | Anti-hallucination grep-guard: the `image:` is EITHER the `VERIFY_THEN_PIN` placeholder OR a `pgvector/pgvector:pg17`-prefixed tag — never an UNSOURCED concrete tag (no `pgvector/pgvector:pg1[^7]`/`:pg2…`/non-pg17 literal); no Postgres-16 image leaked into the 2.0.0 tree | grep-guard: assert `VERIFY_THEN_PIN` OR `:pg17` present; assert no `postgres:16`/non-pg17 pgvector literal in `$PG_DIR` |
| T-006 | FR-B85-054 / FR-B85-005 / ADR-B85-005/006 | `orchestration.yaml` records the DBOS-Rust deferral (`rust_sdk_status` / `available: false` + Temporal-retained) AND `default: dbos` is unchanged AND `2.0.0.yaml` `dbos-embedded` carries `status: deferred` | grep `rust_sdk_status`/`available: false` + `default: dbos` in orchestration.yaml; yaml-parse `dbos-embedded.status == deferred` in 2.0.0.yaml |
| T-007 | FR-B85-054 / FR-B85-004 / ADR-B85-005 | `orchestration.yaml` passes J.7 in **DIRECTORY mode** (`bash bin/validate-standards-yaml.sh .forge/standards/` exit 0 + `[STD-PASS] …orchestration.yaml`) AND the REVIEW.md `\| orchestration.yaml \| 1.1.0 \|` ledger row exists (FR-J7-023 anchor, basename cell) | run validator dir-mode, assert exit 0 + PASS line; grep REVIEW.md row |
| T-008 | FR-B85-053 / FR-B85-021 / ADR-B85-004 | The `2.0.0.yaml` `postgres-17-pgvector` component still refs `standard: persistence.yaml` and the file resolves (re-asserts b8-3 T-011); the postgres component carries no forbidden inline-pin key | yaml-parse: postgres comp `standard == persistence.yaml`, `os.path.isfile`, no `{version,pin,image}` key |
| T-009 | NFR-B85-004 / FR-B85-056 | Coupling guard: `b8-3.test.sh` (17/17) + `b8-3b.test.sh` (12/12) stay GREEN under the B.8.5 edits — **exit-code only** (no output parse; keeps T-009 within ≤ 5 s, the b8-4 T-012 strategy) | `bash b8-3.test.sh --level 1 >/dev/null 2>&1; [ $? -eq 0 ]` + same for `b8-3b.test.sh` |
| T-010 | FR-B85-055 / FR-B85-014 / ADR-B85-006 | `2.0.0.yaml`: the `temporal-intent → dbos-embedded` delta is annotated deferred (has a `note:` containing "DEFERRED"/"no Rust SDK") AND the `postgres-16-no-pgvector → postgres-17-pgvector` delta is INTACT (still present, brick B.8.5) | yaml-parse migration_deltas: temporal delta has `note`, postgres-16 delta present |
| T-011 | FR-B85-056 / NFR-B85-003 | Additive — the flat 1.0.0 `docker-compose.dev.yml.tmpl` `postgres:16-alpine` sentinel is byte-untouched (still `image: postgres:16-alpine`) AND the frozen `schema.yaml` is still `version: "1.0.0"` (anchored grep, b8-3b T-012 form) | grep `image: postgres:16-alpine` in the flat tmpl; `grep -qx 'version: "1.0.0"'` schema.yaml |
| T-012 | NFR-B85-001 / FR-B85-030 | Anti-hallucination: NO `dbos` crate pin / `Cargo.toml dbos` / `dbos = 0.x` line anywhere in the 2.0.0 postgres tree or the change's authored artifacts; the deferral is prose-only (central Article III.4 prohibition) | grep-guard: assert no `dbos =`/`cargo add dbos`/`DBOSContext` token in `$PG_DIR` |

**12 L1 tests.** All file-existence + grep + `python3 yaml.safe_load` (T-006/T-008/T-010) + two sub-harness invocations (T-009) + one validator invocation (T-007, directory mode). No network, no Docker. **Budget ≤ 5 s — SETTLED**: T-009 asserts the two sub-harness **exit codes only** (`>/dev/null 2>&1; [ $? -eq 0 ]`), NOT a full-output parse — the load-bearing coupling guard per the shared-standard sibling-harness lesson, kept within budget (the b8-4 T-012 decided strategy, reused here).

### TDD Order (Article I RED → GREEN)
1. **RED**: commit `b8-5.test.sh` with all 12 assertions before any impl artifact exists. T-001/T-003/T-006/T-007/T-010 fail immediately (no tree, no bump, no annotation).
2. **GREEN**: execute the Implementation Ordering (orchestration bump → validate dir-mode → `2.0.0.yaml` annotation → tree → image verify-then-pin → register). Re-run — 12/12 PASS, and `b8-3` (17/17) + `b8-3b` (12/12) stay GREEN (T-009).
3. **REFACTOR**: tighten messages; confirm ≤ 5 s; confirm CI line budget ≤ 300.

### Performance Budget
File/grep/yaml checks ~1-2 s; validator dir-mode ~1 s; two sub-harnesses ~2-4 s combined (exit-code only). Within the ≤ 5 s L1 budget (inherits the b8-3/b8-4 ≤ 5 s precedent). Zero net/Docker (the live image verify-then-pin is an `/forge:implement` step, NOT an L1 harness assertion).

---

## Component Design

```mermaid
graph TD
    S20[2.0.0.yaml — candidate<br/>dbos-embedded: status: deferred + note<br/>temporal→dbos delta: note deferred<br/>postgres-17-pgvector + postgres-16 delta INTACT]
    ORC[orchestration.yaml v1.1.0<br/>+ rust_sdk_status.dbos available:false<br/>default: dbos UNCHANGED language-conditional]
    REV[REVIEW.md row<br/>orchestration.yaml 1.1.0 KEEP-WITH-CHANGES]
    PER[persistence.yaml v1.0.0<br/>CONSUMED as-is — default postgres-17 + pgvector-0.8<br/>NO bump, NO new standard]
    TREE[2.0.0/infra/postgres/<br/>compose fragment VERIFY_THEN_PIN image + init-pgvector.sql + README]
    FLAT[docker-compose.dev.yml.tmpl<br/>FLAT 1.0.0 — postgres:16-alpine BYTE-UNTOUCHED]
    H5[b8-5.test.sh<br/>12 L1]
    H3[b8-3.test.sh 17 L1<br/>+ b8-3b 12 L1]
    IMPL[/forge:implement<br/>LIVE docker manifest inspect → pin pg17 tag]

    S20 -->|postgres comp standard: ref resolves| PER
    S20 -->|dbos comp standard: ref resolves| ORC
    ORC --> REV
    TREE -->|policy: postgres-17 + pgvector-0.8| PER
    FLAT -.parallel additive-first.-> TREE
    IMPL -.resolves VERIFY_THEN_PIN.-> TREE
    H5 -->|T-001..T-005 assert| TREE
    H5 -->|T-006/T-007 J7 dir-mode| ORC
    H5 -->|T-006/T-008/T-010| S20
    H5 -->|T-009 coupling guard| H3
    H5 -->|T-011 untouched| FLAT
    H3 -->|T-011 refs resolve| ORC
    H3 -->|T-011 refs resolve| PER
```

---

## Standards Applied

| Standard | Role in this change |
|----------|---------------------|
| `persistence.yaml` v1.0.0 | CONSUMED as-is — Postgres-17 default + pgvector-0.8 extension policy source; NOT authored, NOT bumped (ADR-B85-004) |
| `orchestration.yaml` 1.0.0 → 1.1.0 | Additive bump — `rust_sdk_status.dbos` DBOS-Rust-deferred record; `default: dbos` unchanged (ADR-B85-005) |
| `infra/docker-compose.md` | 1.0.0 dev-compose convention the fragment mirrors (`fsm-db` shape, `<project-name>` placeholder) |
| `global/standards-lifecycle.md` | J.7 frontmatter + REVIEW.md ledger for the `orchestration.yaml` 1.1.0 additive bump (transport.yaml precedent) |
| `global/forge-self-ci.md` | harness registration (≤ 300-line CI budget, NFR-CI-002) |
| `global/open-questions.md` | Q-001..Q-004 resolved (independent reviewer + maintainer) |

**Standards created (at impl, NOT here)**: NONE — the key contrast with B.8.4 (which created `gateway.yaml`). `persistence.yaml` pre-exists and is consumed.
**Standards edited (at impl)**: `orchestration.yaml` (1.0.0 → 1.1.0 additive), `REVIEW.md` (+1 KEEP-WITH-CHANGES row). **No index.yml change** (orchestration.yaml already registered).
**Candidate edited (at impl)**: `2.0.0.yaml` (dbos-embedded `status:`/`note:` + temporal-delta `note:` — permitted candidate edit; postgres component + postgres delta UNCHANGED).
**Frozen surfaces NOT touched**: `schema.yaml`, the flat 1.0.0 `docker-compose.dev.yml.tmpl` (`postgres:16-alpine`), `1.0.0.tar.gz`, `persistence.yaml` (consumed, not bumped), the Constitution.

---

## FR-B85-* → Design Element Traceability

| FR / NFR | Design element |
|----------|----------------|
| FR-B85-001 | NO `dbos` crate / Cargo.toml / DBOSContext — central Article III.4 prohibition; T-012 |
| FR-B85-002 | Temporal retained — `orchestration.yaml` `rust_sdk_status.rust_flagship_orchestrator: temporal` (ADR-B85-005); `2.0.0.yaml` dbos `status: deferred` (ADR-B85-006); T-006 |
| FR-B85-003 | `orchestration.yaml` DBOS-deferral body field `rust_sdk_status.dbos.available:false` (ADR-B85-005); T-006 |
| FR-B85-004 | `orchestration.yaml` 1.1.0 J.7-valid + REVIEW.md row (ADR-B85-005); T-007 |
| FR-B85-005 | `2.0.0.yaml` `dbos-embedded` `status: deferred` + `note:` (ADR-B85-006); T-006 |
| FR-B85-006 | annotation keeps b8-3/b8-3b GREEN — `status`/`note` not forbidden, no `^\d+\.\d+` scalar (ADR-B85-006); T-009 |
| FR-B85-010 | `2.0.0/infra/postgres/` versioned subtree (ADR-B85-001/002); T-001 |
| FR-B85-011 | `pgvector/pgvector:VERIFY_THEN_PIN` image, Postgres major 17 (ADR-B85-003); T-002/T-005 |
| FR-B85-012 | `init-pgvector.sql.tmpl` `CREATE EXTENSION IF NOT EXISTS vector;` via `docker-entrypoint-initdb.d` (ADR-B85-003); T-003 |
| FR-B85-013 | fragment mirrors 1.0.0 `fsm-db` shape (env, named volume, `pg_isready`) (ADR-B85-002); T-004 |
| FR-B85-014 | postgres migration_delta intact + actively delivered; postgres component untouched (ADR-B85-004/006); T-010 |
| FR-B85-020 | `persistence.yaml` CONSUMED, no new standard, no bump (ADR-B85-004) |
| FR-B85-021 | `2.0.0.yaml` postgres `standard: persistence.yaml` ref resolves, no inline pin (ADR-B85-004); T-008 |
| FR-B85-030 | concrete image tag = verify-then-pin PLACEHOLDER (ADR-B85-003); T-005 |
| FR-B85-050 | `b8-5.test.sh` hermetic ≤5s + CI one-line registration after b8-4 |
| FR-B85-051 | T-001 (datastore present in 2.0.0 tree) |
| FR-B85-052 | T-002/T-003 (pgvector image + CREATE EXTENSION vector) |
| FR-B85-053 | T-008 (persistence.yaml ref resolves) |
| FR-B85-054 | T-006/T-007 (orchestration DBOS-deferral + J.7 dir-mode + REVIEW row) |
| FR-B85-055 | T-006/T-010 (dbos deferred + temporal delta deferred + postgres delta intact) |
| FR-B85-056 | T-011/T-009 (additive 1.0.0 byte-untouched + b8-3/b8-3b coupling guard) |
| NFR-B85-001 | anti-hallucination: claims re-read from live files / Context7; no fabricated pin; T-005/T-012 |
| NFR-B85-002 | (propose/specify zero-mutation — satisfied by prior phases; design adds no impl) |
| NFR-B85-003 | frozen 1.0.0 byte-identity (schema.yaml, flat tmpl postgres:16, 1.0.0.tar.gz); T-011 |
| NFR-B85-004 | existing gates GREEN; orchestration.yaml J.7-valid; b8-3 + b8-3b GREEN; T-007/T-009 |
| NFR-B85-005 | verify-then-pin at implement (no premature image pin); ADR-B85-003; T-005 |
| NFR-B85-006 | Article VIII.2 preserved (Temporal retained, no amendment); ADR-B85-005 |
| NFR-B85-007 | brick gates B.7 (RAG)/B.8.12/B.8.14; recorded in proposal + persistence consumption |

---

## Constitutional Compliance Gate

- **Article I (TDD RED-first)**: `b8-5.test.sh` is committed with all 12 assertions BEFORE any impl artifact exists; the tree-presence / orchestration-bump / dbos-deferred assertions fail RED, then turn GREEN once the Implementation Ordering lands. No production template precedes its test.
- **Article II (BDD)**: no new user-facing runtime feature in design; the BDD scenario is recorded in `specs.md` for traceability (no `.feature` required — a datastore template + a standard bump + a candidate annotation, not app behavior).
- **Article III.1/III.2 (Specs before code)**: design follows specs; the template tree, the `orchestration.yaml` bump, and the `2.0.0.yaml` annotation are authored only after this design.
- **Article III.4 (Anti-Hallucination) — CENTRAL**: the plan's B.8.5 DBOS premise is FALSIFIED and recorded prominently (DBOS has no Rust SDK; crates.io `dbos` 404; DBOS Transact = Python/TypeScript/Go/Java only — Context7 `docs.dbos.dev`). This design specs NO `dbos` crate pin / `Cargo.toml dbos = 0.x` / DBOSContext (FR-B85-001, T-012). The pgvector image family + extension-enable are sourced from Context7 (`/pgvector/pgvector`); the **concrete tag is an explicit verify-then-pin PLACEHOLDER** (`pgvector/pgvector:VERIFY_THEN_PIN`) resolved live at `/forge:implement` (ADR-B85-003, T-005) — none is asserted as registry-verified here (kong/b8-coroot/b8-signoz lesson). All live facts (1.0.0 `postgres:16-alpine`, no k8s Postgres StatefulSet, persistence.yaml pins, orchestration.yaml `default: dbos`, b8-3 harness mechanics, the J.7 validator REVIEW.md drift + FR-J7-020/021 invariants) were re-read from live files this session, not assumed.
- **Article IV (Delta-based)**: the `2.0.0/infra/postgres/` tree is a NEW additive sibling; it does not rewrite or delete the flat 1.0.0 `docker-compose.dev.yml.tmpl` or `schema.yaml`. The `orchestration.yaml` bump is an additive minor edit (`default: dbos` unchanged); the `2.0.0.yaml` `status:`/`note:` annotations are additive edits to the *candidate* (permitted, ADR-B85-006), not the frozen 1.0.0 surface. `persistence.yaml` is consumed unchanged.
- **Article V (Compliance gate)**: ADR-B85-001..006 each map a resolved open question (Q-001..Q-004) to a design decision; no work proceeds around an unresolved question. Q-004 additionally carries a verify-then-pin step at `/forge:implement`.
- **Article VIII.2 (Temporal SHALL — IN FORCE, PRESERVED)**: Constitution v1.1.0 §VIII.2 mandates Temporal, binding until B.8.14. **B.8.5 PRESERVES VIII.2 as a compliance positive**: deferring DBOS (no Rust SDK) and **retaining Temporal** keeps the Rust flagship on the Constitutionally-mandated orchestrator. **B.8.5 needs NO amendment to VIII.2** — unlike the abandoned DBOS plan, which would have replaced Temporal with DBOS and thus required the B.8.14 GOVERNANCE.md amendment. The `orchestration.yaml` `default: dbos` stays an aspirational (language-conditional, non-Rust) target recorded in a *standard*, not a deployed violation of the Temporal SHALL clause — recorded explicitly in `rust_sdk_status` (ADR-B85-005), not merely "unchanged."
- **Article VIII.5 (IaC) / X (quality)**: the datastore template is version-controlled IaC; `persistence.yaml` (consumed) already carries its J.7 frontmatter + review cadence; the `orchestration.yaml` additive bump lands under the J.7-validated standard contract (`bin/validate-standards-yaml.sh` PASS — T-007) + a REVIEW.md row. No relaxation of TDD/BDD/coverage.
- **Article XII (Governance)**: no Constitution amendment in B.8.5. Because Temporal is retained, the VIII.2 amendment that the DBOS plan would have required is NOT triggered. The `orchestration.yaml` 1.1.0 bump is a dated-expiry (non-structural) standard edit (`exception_constitutional: false`), so it is NOT subject to the Article XII structural-exception process; it follows the ordinary 12-month review cycle and the append-only REVIEW.md ledger.

**No violations. Gate PASS** (subject to independent review — NOT self-approved here).

---

## Anti-Hallucination Pass (Design Phase)

- **DBOS-Rust premise FALSIFIED (central)**: carried from specify, re-affirmed — crates.io has no `dbos` crate; DBOS Transact ships Python/TypeScript/Go/Java only (Context7 `docs.dbos.dev`). This design specs NO `dbos` crate pin / `Cargo.toml dbos = 0.x` / DBOSContext (FR-B85-001). DBOS deferred, Temporal retained.
- **1.0.0 datastore reality**: re-read from `docker-compose.dev.yml.tmpl:37-55` this session — `fsm-db`, `image: postgres:16-alpine`, `POSTGRES_{DB,USER,PASSWORD}`, named volume `fsm-db-data`, `pg_isready` healthcheck, network `fsm-dev`. NO Postgres K8s StatefulSet in `infra/k8s/base/` (the dev compose is the only datastore manifest). This grounds ADR-B85-001's NO-k8s decision — not invented.
- **persistence pin source PRE-EXISTS**: re-read `persistence.yaml` v1.0.0 — `default: postgres-17`, `extensions: [pgvector-0.8, postgis, timescaledb]`, complete J.7 frontmatter. The `2.0.0.yaml` `postgres-17-pgvector` component already refs it (b8-3 T-011 GREEN today). B.8.5 CONSUMES (no new standard) — the explicit contrast with B.8.4's new `gateway.yaml` (ADR-B85-004).
- **pgvector image + extension**: sourced from Context7 (`/pgvector/pgvector`) frozen in `specs.md`, NOT training data — `pgvector/pgvector:pg<MAJOR>-<distro>` family + `CREATE EXTENSION vector`. The concrete tag is a verify-then-pin PLACEHOLDER (`pgvector/pgvector:VERIFY_THEN_PIN`); the `pg17` family vs the docs' `pg18-trixie` example is recorded, not normalized — Q-004, resolved live at implement.
- **b8-3 T-015 / T-012 / T-016 mechanics**: re-read from b8-3.test.sh:104-162 this session — T-012 forbidden set is exactly `{version,pin,image}` (`set(c.keys()) & forbidden`); T-015 is a `version_re.match(r'^\d+\.\d+')` value-walk over `components` *direct scalars only* (migration_deltas NOT walked); T-016 requires the postgres `migration_note` + a `from=postgres-16*` delta. The dbos-deferred annotation shape (ADR-B85-006) is constrained to satisfy these, not assumed safe — including the explicit drafting rule that the `note:` prose must not begin with a `\d+\.\d+` token.
- **J.7 validator mechanics**: re-read from `bin/validate-standards-yaml.sh:277-328` this session — FR-J7-020 (dated expiry ⇒ exc:false), FR-J7-021 (`expires_at > last_reviewed` strict ordering, the canonical pair), FR-J7-023 (REVIEW.md drift: `version` MUST appear as `\|\s*<basename>\s*\|\s*<version>\s*\|`). The orchestration.yaml 1.1.0 bump + the MANDATORY REVIEW.md `1.1.0` row are designed against these exact invariants, validated in DIRECTORY mode (the b8-4 dir-mode lesson — the REVIEW.md drift check is a Phase-2 cross-cutting block that only runs in dir context).
- **No resolution-order trap (vs b8-4)**: re-read confirms `dbos-embedded` already carries `standard: orchestration.yaml` and B.8.5 adds no new `standard:` ref and does not rename the file — so unlike b8-4's `gateway.yaml`-must-exist-first ordering, b8-5's T-011 ref resolves before and after; the `2.0.0.yaml` edit and the `orchestration.yaml` bump are order-independent for T-011. Stated explicitly, not assumed.
- **Article VIII.2 framing**: Temporal SHALL is IN FORCE; B.8.5 RETAINS Temporal (defers DBOS), so VIII.2 is PRESERVED and NO amendment is needed — stated explicitly as a compliance positive (NFR-B85-006), unlike the DBOS plan.

### Two LOW review nits from specify — addressed
1. **FR-B85-040 → NFR-B85-003 (done)**: the spec's FR cluster 4 (verify-then-pin) carries no orphan FR-B85-040 — the verify-then-pin requirement is FR-B85-030 + NFR-B85-005, and the additive-byte-untouched requirement is NFR-B85-003 (mapped to T-011). Confirmed the traceability table has no dangling FR-B85-040 → it is folded into NFR-B85-003 (additive) + NFR-B85-005 (verify-then-pin). No orphan requirement.
2. **ADR-B85-005 language-conditional `default`**: per the review, `default: dbos` is recorded NOT merely as "unchanged" but explicitly as a **language-conditional aspirational non-Rust target** via the `rust_sdk_status.dbos.default_is_language_conditional: true` + `note:` body field (ADR-B85-005). This is the substantive encoding of the review nit — the design states the default is aspirational/non-Rust, not an active Rust selection.

---

## Open Items / [NEEDS CLARIFICATION]

- **None blocking design.** All four maintainer-resolved decisions are encoded (ADR-B85-001..006). The single carried uncertainty — the concrete `pgvector/pgvector:pg17`-family image tag (distro suffix; `pg17` vs `pg17-trixie`) + the exact pgvector minor — is a deliberate **verify-then-pin at `/forge:implement`** item (ADR-B85-003, Q-004), NOT a design ambiguity. If the live registry does not carry a `pg17`-family pgvector image at implement, the impl surfaces `[NEEDS CLARIFICATION]` at that point.
- **Independent review follows** — this design is NOT self-approved. The Constitutional Compliance Gate PASS above is the author's assessment; an independent reviewer ratifies before `/forge:plan`. The image tag verify-then-pin runs LIVE at `/forge:implement` (registry inspect), not here.
