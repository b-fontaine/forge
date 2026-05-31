# Specifications: b8-5-postgres-pgvector

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.5 (docs/new-archetypes-plan.md §4.2 — RE-SCOPED: Postgres 16→17 + pgvector datastore; DBOS deferred — no Rust SDK) -->

**Namespace** : `FR-B85-*` / `NFR-B85-*` / `ADR-B85-*`.
**Constitution** : v1.1.0, unchanged (no amendment). Article VIII.2 (Temporal
SHALL) is **PRESERVED** by this re-scope — see proposal "Constitution
Compliance". This change is **propose + specify only**. It authors the
requirements + ADRs for the re-scoped `full-stack-monorepo / 2.0.0` **Postgres
16→17 + pgvector** datastore brick (B.8.5) and the **DBOS-Rust-unavailable
deferral** record. It ships **no template, no concrete image pin, and no
standard/schema edits** — the datastore template, the pgvector image tag
(verify-then-pin), the orchestration.yaml deferral edit, and the 2.0.0.yaml
dbos-deferred annotation are delivered in the impl phase.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-
Hallucination — DBOS-Rust-absent recorded; never invent versions/APIs), IV
(delta-based: the 2.0.0 datastore tree + the standard/schema edits are additive,
the flat 1.0.0 `postgres:16-alpine` and frozen `schema.yaml` are untouched),
VIII.2 (Temporal SHALL — in force, PRESERVED: Temporal retained, no amendment),
VIII.5 (IaC), X (J.7 standard contract).

## CENTRAL FINDING — DBOS has NO Rust SDK (Article III.4)

The plan §4.2 B.8.5 premise — *"Templates DBOS embedded — Cargo.toml `dbos =
0.x`, DBOSContext boilerplate, init Postgres state tables"* — is **FALSIFIED**:

| Evidence | Finding |
|----------|---------|
| **crates.io** | No `dbos` crate exists (`dbos = 0.x` pin would 404). |
| **DBOS Transact SDKs** (Context7 `docs.dbos.dev` quickstart + `explanations/portable-workflows`) | Ships **Python, TypeScript, Go, Java ONLY** — verbatim *"Python, TypeScript, Go, and Java"*. Context7 catalog: `dbos-transact-py`, `@dbos-inc/dbos-sdk`, `dbos-transact-golang`. **No Rust crate.** |
| **crates.io alternatives** | `durable-rust` (~612 dl, solo) + `raftoral` (~327 dl, embedded-Raft, NOT Postgres-backed) — too immature for the flagship. |

**Consequence:** this change SHALL NOT spec any `dbos` crate pin, any
`Cargo.toml dbos = 0.x` line, or any DBOSContext boilerplate. **DBOS is
DEFERRED; Temporal is RETAINED** as the 2.0.0 orchestrator (Article VIII.2
preserved). B.8.5 is re-scoped to the **Postgres 16→17 + pgvector datastore
delta** the plan also assigns to B.8.5 (unblocks B.7 RAG + any future
Postgres-backed DBOS state store, in whatever language a DBOS SDK eventually
ships).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4 (Module B.8), §4.1 (additive-first), §4.2 B.8.5 (DBOS premise FALSIFIED — see above; the postgres-17+pgvector "init Postgres state tables" delta survives as the real deliverable) |
| **Candidate schema (observed)** | `.forge/schemas/full-stack-monorepo/2.0.0.yaml` (B.8.3, candidate, `scaffoldable: false`) — component `postgres-17-pgvector` { role: persistence, replaces: postgres-16, delivered_by: B.8.5, standard: persistence.yaml, migration_note: "CROSSING DELTA …" }; migration_delta { from: postgres-16-no-pgvector, to: postgres-17-pgvector, brick: B.8.5 }; component `dbos-embedded` { role: workflow-orchestration, replaces: temporal-intent, delivered_by: B.8.5, standard: orchestration.yaml }; migration_delta { from: temporal-intent, to: dbos-embedded, brick: B.8.5 }; bump_at: B.8.14 |
| **1.0.0 datastore (observed)** | `.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl:38` — `fsm-db` service, `image: postgres:16-alpine`, env `POSTGRES_{DB,USER,PASSWORD}`, named volume `fsm-db-data`, `pg_isready` healthcheck. FLAT tree, NO version subdir, NO pgvector. Frozen (B.8.2). Baseline = `postgres:16-alpine` (docs/B8-BASELINE.md §2) |
| **2.0.0 template tree (observed)** | Versioned subtree `.forge/templates/archetypes/full-stack-monorepo/2.0.0/` exists (B.8.4) but contains ONLY `2.0.0/infra/k8s/envoy-gateway/**`. No persistence/datastore template under `2.0.0/` yet |
| **persistence.yaml (observed — PIN SOURCE PRE-EXISTS)** | `.forge/standards/persistence.yaml` v1.0.0 (ADR-010, T.4): `default: postgres-17`, `extensions: [pgvector-0.8, postgis, timescaledb]`, `sharding: citus`, `forbidden_for_eu_strict: [dynamodb, firestore, cosmosdb]`. J.7 frontmatter complete. index.yml triggers include `postgres, pgvector, …, ADR-010`. CONTRAST B.8.4 (which CREATED gateway.yaml) — here the standard pre-exists and is CONSUMED |
| **orchestration.yaml (observed)** | `.forge/standards/orchestration.yaml` v1.0.0 (ADR-002, T.4): `default: dbos`, `fallback: temporal`, `fallback_trigger: …`, `forbidden: [inngest]`. REVIEW.md seed (2026-05-04) already flags *"orchestration.yaml … DBOS-rs maturity (< 1 year prod) to revisit"* |
| **Standard additive-bump precedent (observed)** | `transport.yaml` 1.0.0 → 1.1.0 → 1.2.0 (KEEP-WITH-CHANGES, additive body fields, REVIEW.md rows); `observability.yaml` → v2.1.0. REVIEW.md is append-only (Article XII); J.7 = `bin/validate-standards-yaml.sh` |
| **Constitution (observed)** | v1.1.0 §VIII.2 (Temporal SHALL — IN FORCE); 2.0.0.yaml header records VIII.1+VIII.2 binding until B.8.14. This re-scope PRESERVES VIII.2 (Temporal retained) |
| **Predecessors / dependencies** | B.8.3 (`b8-3-schema-candidate`, archived 2026-05-30 — 2.0.0 candidate; b8-3.test.sh 17 L1 + b8-3b.test.sh 12 L1 gates); B.8.4 (`b8-4-envoy-gateway`, archived 2026-05-31 — versioned 2.0.0 subtree convention + J.7 additive-standard-edit + REVIEW.md ledger precedent) |
| **Downstream consuming this** | B.7 (ai-native-rag — pgvector vector store), B.8.12 (zero-regression gate), B.8.14 (1.0.0→2.0.0 bump + breaking removal) |
| **External research** | Context7: `/pgvector/pgvector` (image family + `CREATE EXTENSION vector`), `docs.dbos.dev` (DBOS supported languages — no Rust). Concrete image tag **verify-then-pin at implement** |
| **Test harness coupling** | `b8-3.test.sh` (17 L1) forbids component keys `{version,pin,image}` (T-012), forbids component scalar values matching `^\d+\.\d+` (T-015), requires every `standard:` ref to resolve (T-011), requires postgres migration_note + postgres-16 delta (T-016). `b8-3b.test.sh` (12 L1). Editing 2.0.0.yaml MUST keep both GREEN |
| **Release target** | maintainer-set |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — DBOS deferral (no Rust SDK) (FR-B85-001 → 009)

##### FR-B85-001 — NO `dbos` crate pin / Cargo.toml / DBOSContext
The brick MUST NOT introduce any `dbos` crate pin, any `Cargo.toml dbos = 0.x`
line, or any DBOSContext boilerplate anywhere (templates, standards, schema).
DBOS has NO Rust SDK (crates.io `dbos` 404; DBOS Transact = Python/TypeScript/
Go/Java only — Context7). This is the central Article III.4 prohibition.

##### FR-B85-002 — Temporal retained as the 2.0.0 orchestrator
The brick MUST record that, because DBOS has no Rust SDK, the Rust flagship
**retains Temporal** as the workflow orchestrator for 2.0.0 (Article VIII.2
preserved). DBOS is DEFERRED until a production-grade Rust DBOS SDK ships.

##### FR-B85-003 — orchestration.yaml DBOS-Rust-deferral recorded
B.8.5 MUST record the DBOS-Rust-unavailable finding in
`.forge/standards/orchestration.yaml` as an additive edit: a note/field stating
DBOS has no Rust SDK so Temporal is retained for the Rust flagship. The
`default: dbos` value MUST NOT be changed (it remains the aspirational target
for non-Rust contexts). The representation (version bump 1.0.0 → 1.1.0 + body
field vs frontmatter note) is ADR-B85-005 / Q-002.

##### FR-B85-004 — orchestration.yaml edit satisfies J.7 + REVIEW.md
If the orchestration.yaml edit bumps the version, it MUST keep the J.7
frontmatter contract valid (`bin/validate-standards-yaml.sh` GREEN) and MUST add
a `REVIEW.md` row (append-only, Article XII) following the transport.yaml
KEEP-WITH-CHANGES additive-bump precedent. `default: dbos` + `fallback: temporal`
semantics MUST remain parseable.

##### FR-B85-005 — 2.0.0.yaml dbos-embedded annotated deferred (candidate edit)
The 2.0.0.yaml `dbos-embedded` component MUST be annotated **deferred** (no Rust
SDK; Temporal retained), and its `temporal-intent → dbos-embedded`
migration_delta MUST be annotated deferred. Editing 2.0.0.yaml is permitted
because it is the **candidate**, not the frozen 1.0.0 `schema.yaml`. The
annotation shape (`status:` / `note:`) is ADR-B85-006 / Q-003.

##### FR-B85-006 — annotation MUST NOT break b8-3 / b8-3b
The dbos-deferred annotation MUST NOT introduce a forbidden inline-pin key
(`version`/`pin`/`image` — b8-3 T-012) and MUST NOT add a component scalar value
matching `^\d+\.\d+` (b8-3 T-015). The `dbos-embedded` `standard:
orchestration.yaml` ref MUST keep resolving (b8-3 T-011). The `dbos-embedded`
`name` field MUST remain (b8-3 T-010). After the edit, `b8-3.test.sh` (17 L1) and
`b8-3b.test.sh` (12 L1) MUST stay GREEN.

#### Cluster 2 — Postgres 17 + pgvector datastore in the 2.0.0 tree (FR-B85-010 → 019)

##### FR-B85-010 — datastore in the versioned 2.0.0 template tree
The Postgres 17 + pgvector datastore template MUST live in the versioned subtree
rooted at `.forge/templates/archetypes/full-stack-monorepo/2.0.0/...` (the B.8.4
versioned-subtree convention), coexisting with the byte-untouched flat 1.0.0
`docker-compose.dev.yml.tmpl`. Exact path + shape (compose fragment vs K8s) is
ADR-B85-001/002 / Q-001.

##### FR-B85-011 — Postgres-17 + pgvector image (family identified, tag verify-then-pin)
The datastore MUST use a Postgres-17 image with pgvector preinstalled from the
official `pgvector/pgvector:pg17`-family image (Context7 `/pgvector/pgvector`:
`pgvector/pgvector:pg<MAJOR>-<distro>`). The **concrete tag string** (distro
suffix; `pg17` vs `pg17-trixie` etc.) MUST be **verified live** at
`/forge:implement` (registry inspect) before being written, NOT fabricated here
(NFR-B85-005, Q-004). The image MUST be Postgres **major 17** (the 2.0.0 delta
over the 1.0.0 `postgres:16-alpine` baseline).

##### FR-B85-012 — pgvector extension enabled on init
The datastore MUST enable the pgvector extension by running `CREATE EXTENSION
vector;` (Context7 — once per database), e.g. via an init SQL mounted into
`docker-entrypoint-initdb.d` or an equivalent migration step. The brick MUST NOT
rely on the extension being implicitly present (it is shipped by the image but
MUST be explicitly created in the target database). Mechanism = ADR-B85-003.

##### FR-B85-013 — mirrors the 1.0.0 fsm-db datastore shape
The 2.0.0 dev datastore SHOULD mirror the 1.0.0 `fsm-db` service shape it
supersedes: `POSTGRES_{DB,USER,PASSWORD}` env, a named data volume, and a
`pg_isready` healthcheck — consistent with `docker-compose.dev.yml.tmpl` and the
`<project-name>` placeholder convention. Departures MUST be justified at design.

##### FR-B85-014 — postgres migration delta intact + actively delivered
The 2.0.0.yaml `postgres-16-no-pgvector → postgres-17-pgvector` migration_delta
(brick B.8.5) MUST remain intact — it is **actively delivered** by this brick
(unlike the temporal→dbos delta, annotated deferred). The
`postgres-17-pgvector` component, its `migration_note`, and its `standard:
persistence.yaml` ref MUST stay (b8-3 T-016 / T-011 preserved).

#### Cluster 3 — persistence.yaml consumed, not authored (FR-B85-020 → 029)

##### FR-B85-020 — persistence.yaml is CONSUMED (no new standard, no bump)
The brick MUST consume the pre-existing `.forge/standards/persistence.yaml`
v1.0.0 (`default: postgres-17`, `extensions: [pgvector-0.8, …]`) as its pin
source. It MUST NOT create a new persistence standard and MUST NOT bump
persistence.yaml. **This is the key contrast with B.8.4**, which had to create
`gateway.yaml` because no `*.yaml` standard pinned a gateway; here the pin
source pre-exists (ADR-B85-004).

##### FR-B85-021 — 2.0.0.yaml persistence ref already resolves (no schema pin)
The 2.0.0.yaml `postgres-17-pgvector` component's `standard: persistence.yaml`
ref MUST keep resolving (b8-3 T-011), and the component MUST NOT gain a forbidden
inline-pin key (`version`/`pin`/`image`) or a `^\d+\.\d+` scalar (b8-3 T-012/
T-015). The concrete Postgres-17 + pgvector-0.8 versions live in persistence.yaml
and the verify-then-pin image tag — NOT inline in the schema.

#### Cluster 4 — Verify-then-pin (image tag) (FR-B85-030 → 039)

##### FR-B85-030 — concrete pgvector image tag is verify-then-pin, never fabricated
The concrete `pgvector/pgvector:pg17`-family tag MUST be **verified live** at
`/forge:implement` (e.g. registry inspect / `docker manifest inspect` /
Docker Hub tag listing) **before** being written to the datastore template. This
spec MUST NOT, and the design MUST NOT, assert a concrete tag as registry-
verified. Where uncertain, `[NEEDS CLARIFICATION]` is required (Q-004). The
pgvector extension version target is `pgvector-0.8` per persistence.yaml.

#### Cluster 5 — Harness b8-5.test.sh (FR-B85-050 → 056)

##### FR-B85-050 — harness exists, hermetic, ≤5s, registered
The brick MUST ship `.forge/scripts/tests/b8-5.test.sh`: `--level` flag +
`source _helpers.sh` + `run_test` + `print_summary` (mirroring b8-3 / b8-4),
L1 ≤ 5 s, zero net/Docker. It MUST be registered as a one-line entry
`"b8-5.test.sh --level 1"` in `.github/workflows/forge-ci.yml` after the
`b8-4.test.sh` line.

##### FR-B85-051 — assert datastore present in the 2.0.0 tree
The harness MUST assert the Postgres-17 + pgvector datastore template exists
under `.forge/templates/archetypes/full-stack-monorepo/2.0.0/...` (FR-B85-010).

##### FR-B85-052 — assert pgvector extension enabled
The harness MUST assert the datastore enables pgvector via `CREATE EXTENSION
vector` (init SQL / migration grep) and uses a Postgres-17 `pgvector/pgvector:
pg17`-family image reference (FR-B85-011/012).

##### FR-B85-053 — assert persistence.yaml reference resolves
The harness MUST assert the 2.0.0.yaml `postgres-17-pgvector` component still
refs `standard: persistence.yaml` and that the file resolves (FR-B85-021,
re-asserts b8-3 T-011).

##### FR-B85-054 — assert orchestration.yaml DBOS-deferral recorded
The harness MUST assert the orchestration.yaml DBOS-Rust-deferral record is
present (the note/field per ADR-B85-005), that `default: dbos` is unchanged, and
(if version-bumped) that J.7 dir-mode passes + the REVIEW.md row exists
(FR-B85-003/004).

##### FR-B85-055 — assert 2.0.0.yaml dbos deferred + postgres delta intact
The harness MUST assert the `dbos-embedded` component is annotated deferred
(ADR-B85-006), the `temporal-intent → dbos-embedded` delta is annotated
deferred, AND the `postgres-16-no-pgvector → postgres-17-pgvector` delta is
intact (FR-B85-005/014).

##### FR-B85-056 — assert additive + coupling guard
The harness MUST assert the flat 1.0.0 `docker-compose.dev.yml.tmpl`
`postgres:16-alpine` sentinel is byte-untouched (additive — NFR-B85-003), the
frozen `schema.yaml` is still `version: "1.0.0"`, and (exit-code coupling guard)
`b8-3.test.sh` (17/17) + `b8-3b.test.sh` (12/12) stay GREEN (NFR-B85-004).

### Non-Functional Requirements

##### NFR-B85-001 — anti-hallucination grounding (DBOS-Rust + versions)
Every claim MUST be re-read from a live file (2.0.0.yaml, docker-compose.dev.
yml.tmpl, persistence.yaml, orchestration.yaml, REVIEW.md, the J.7 contract) or
from Context7 (`/pgvector/pgvector`, `docs.dbos.dev`). The DBOS-Rust-absent
finding MUST be recorded prominently, not guessed around; no `dbos` crate pin is
specced. No concrete image tag is asserted as verified (Article III.4).

##### NFR-B85-002 — zero mutation in B.8.5 propose/specify
This change MUST NOT edit any `.forge/standards/**`, `.forge/templates/**`,
`.forge/schemas/**`, `.github/workflows/**`, or Constitution file, and MUST NOT
bump any version. It only authors `b8-5-postgres-pgvector/{.forge.yaml,
proposal.md, specs.md, open-questions.md}`.

##### NFR-B85-003 — frozen 1.0.0 byte-identity preserved
The frozen `schema.yaml` (1.0.0), the flat 1.0.0 template tree (incl.
`docker-compose.dev.yml.tmpl` `postgres:16-alpine`), and
`full-stack-monorepo/1.0.0.tar.gz` MUST be byte-unchanged by this change AND by
the downstream impl (which adds only NEW `.../2.0.0/...` paths + additive
standard/candidate edits). Respects B.8.2 freeze + its sha256 guard.

##### NFR-B85-004 — backward compatibility of existing gates
`validate-foundations.sh`, `verify.sh`, `constitution-linter.sh`,
`b8-3.test.sh` (17 L1), and `b8-3b.test.sh` (12 L1) MUST stay GREEN. The
additive 2.0.0 datastore template, the orchestration.yaml additive edit, and the
2.0.0.yaml dbos-deferred annotation MUST NOT break them; the orchestration.yaml
edit MUST pass `validate-standards-yaml.sh` (J.7).

##### NFR-B85-005 — verify-then-pin at implement (no premature image pin)
The specs + design MUST treat the concrete `pgvector/pgvector:pg17`-family tag
as **deferred** to a live verification step at `/forge:implement`. A concrete
tag written before live verification is a constitutional anti-hallucination
failure (Article III.4; kong / b8-coroot / b8-signoz lesson). Until then the
image is identified by FAMILY + the extension-enable mechanism only.

##### NFR-B85-006 — Article VIII.2 preserved (no amendment)
The specs MUST establish that retaining Temporal (deferring DBOS) PRESERVES
Article VIII.2 (Temporal SHALL) and requires NO GOVERNANCE.md amendment — a
compliance positive over the abandoned DBOS plan, which would have replaced
Temporal and thus needed the B.8.14 VIII.2 amendment.

##### NFR-B85-007 — the brick gates downstream
The specs MUST establish that B.7 (RAG vector store), B.8.12 (zero-regression
convergence), and B.8.14 (bump + removal) build on the Postgres-17 + pgvector
datastore declared here. (Traceability; no runtime artifact in B.8.5 propose/
specify.)

## Architecture Decision Records (seeds — finalized at /forge:design)

- **ADR-B85-001 — datastore placement in the versioned 2.0.0 tree.** Plan §4.2
  named "init Postgres state tables" under the defunct DBOS framing; the real
  datastore belongs in the B.8.4 versioned subtree. **Lean:** new datastore
  template under `.../full-stack-monorepo/2.0.0/...`; flat 1.0.0
  `docker-compose.dev.yml.tmpl` byte-untouched. Mirrors B.8.3/B.8.4 versioned-
  sibling precedent. Resolved at design.
- **ADR-B85-002 — datastore template shape.** **Lean:** a 2.0.0 dev-compose
  datastore fragment mirroring the 1.0.0 `fsm-db` shape (env, named volume,
  `pg_isready`) bumped to the pgvector image + an init step enabling
  `CREATE EXTENSION vector`. Whether a K8s Postgres StatefulSet also ships is
  open (Q-001). Resolved at design.
- **ADR-B85-003 — pgvector image family + extension-enable.** Context7:
  `pgvector/pgvector:pg<MAJOR>-<distro>`, `CREATE EXTENSION vector;`. **Lean:**
  `pgvector/pgvector:pg17`-family; enable via init SQL in
  `docker-entrypoint-initdb.d`. **Concrete tag verify-then-pin at implement**
  (Q-004). Resolved at design (shape) + implement (pin).
- **ADR-B85-004 — persistence.yaml CONSUMED, not authored.** Contrast B.8.4
  (created `gateway.yaml`). persistence.yaml v1.0.0 already pins `postgres-17` +
  `pgvector-0.8`; the 2.0.0.yaml component already refs it. **Lean:** consume
  as-is, no persistence standard edit, no bump. Resolved at design.
- **ADR-B85-005 — orchestration.yaml DBOS-deferral representation.** **Lean:**
  additive version bump 1.0.0 → 1.1.0 + a body field recording "DBOS has no Rust
  SDK; Temporal retained for the Rust flagship" + a REVIEW.md KEEP-WITH-CHANGES
  row (transport.yaml additive-bump precedent). `default: dbos` NOT changed.
  Whether a frontmatter note suffices (no bump) is open (Q-002). Resolved at
  design.
- **ADR-B85-006 — 2.0.0.yaml dbos-deferred annotation shape.** **Lean:** add
  `status: deferred` + `note:` to the `dbos-embedded` component + a `note:` to
  its delta. Keys are NOT in `{version,pin,image}` and carry no `^\d+\.\d+`
  scalar → b8-3 T-012/T-015 stay green; `standard:` ref stays (T-011); `name`
  stays (T-010). The postgres delta is untouched. Confirm candidate-schema
  shape extension acceptable (Q-003). Resolved at design.

## Context7 Evidence (external research, 2026-05-31 — Article III.4)

> Components + mechanisms IDENTIFIED here; concrete image tag **deferred to
> verify-then-pin at `/forge:implement`** (NFR-B85-005).

**DBOS Transact** — Context7 `docs.dbos.dev` (`/websites/dbos_dev`) +
catalog `/dbos-inc/dbos-transact-py`, `@dbos-inc/dbos-sdk`,
`github.com/dbos-inc/dbos-transact-golang`:
- *quickstart* and *explanations/portable-workflows* enumerate supported
  languages verbatim as **"Python, TypeScript, Go, and Java"**.
- Install commands surfaced: `pip install dbos` (Python), `npm install
  @dbos-inc/dbos-sdk@latest` (TS), `go get github.com/dbos-inc/
  dbos-transact-golang` (Go). **No Rust install command, no `cargo add dbos`.**
- **There is NO Rust DBOS SDK.** crates.io `dbos` 404 (re-verified). →
  the plan's `Cargo.toml dbos = 0.x` is unbuildable; DBOS deferred, Temporal
  retained.

**pgvector** — Context7 `/pgvector/pgvector`:
- Official Docker Hub image: `pgvector/pgvector:pg<MAJOR>-<distro>`. Pull
  example rendered as `docker pull pgvector/pgvector:pg18-trixie` (the docs'
  current example tag); the **Postgres-17 family** is the `pg17`-prefixed
  variant (e.g. `pgvector/pgvector:pg17` / `pgvector/pgvector:pg17-trixie`).
- Manual build: `docker build --build-arg PG_MAJOR=17 …` (pin the major).
- Enable the extension once per database: `CREATE EXTENSION vector;`. Vector
  columns: `CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));`.
- pgvector extension version target = **`pgvector-0.8`** (persistence.yaml;
  README current source line `v0.8.2`). The CONCRETE container tag (distro
  suffix, `pg17` vs `pg17-trixie`) is **verify-then-pin at implement**.

**Deferred to verify-then-pin at implement (Q-004 / NFR-B85-005):**
1. The concrete `pgvector/pgvector:pg17`-family image tag (distro suffix) —
   verified via Docker Hub tag listing / `docker manifest inspect`.
2. The extension-enable mechanism placement (init-SQL in
   `docker-entrypoint-initdb.d` vs a migration) — design leans init-SQL.

## BDD Acceptance Criteria

```gherkin
Feature: Postgres 17 + pgvector datastore declared additively for the 2.0.0 candidate, DBOS deferred
  As a Forge B.8 migration architect
  I want the Postgres 16->17 + pgvector datastore authored against the 2.0.0 candidate
  And the DBOS-Rust-unavailable finding recorded so Temporal is retained
  So that the flagship gains a vector-capable datastore (unblocking B.7 RAG) without
  disturbing the frozen 1.0.0 postgres:16 stack or the in-force Article VIII.2 (Temporal SHALL)

  Scenario: The Postgres+pgvector datastore brick is specified and DBOS is deferred without disturbing the frozen 1.0.0 flagship
    Given the 2.0.0 candidate schema declaring postgres-17-pgvector (replaces: postgres-16, delivered_by/standard persistence.yaml) and dbos-embedded (delivered_by B.8.5)
    And the flat 1.0.0 docker-compose.dev.yml.tmpl with fsm-db image postgres:16-alpine (no pgvector, frozen)
    And persistence.yaml v1.0.0 already pinning default postgres-17 + extensions pgvector-0.8
    And orchestration.yaml v1.0.0 default dbos / fallback temporal, with the REVIEW.md DBOS-rs-maturity concern
    And Constitution Article VIII.2 (Temporal SHALL) in force until B.8.14
    And the fact that DBOS has no Rust SDK (crates.io dbos 404; DBOS Transact = Python/TypeScript/Go/Java only)
    When the B.8.5 brick is authored from these specs
    Then the brick specs NO dbos crate pin, NO Cargo.toml dbos = 0.x, and NO DBOSContext boilerplate
    And a Postgres-17 + pgvector datastore lives under templates/full-stack-monorepo/2.0.0/... as a NEW additive asset
    And the datastore uses the pgvector/pgvector:pg17-family image (concrete tag verify-then-pin at /forge:implement, never fabricated)
    And the datastore enables the extension via CREATE EXTENSION vector
    And persistence.yaml is CONSUMED as-is (no new standard, no bump) and its 2.0.0.yaml ref resolves
    And orchestration.yaml records DBOS has no Rust SDK so Temporal is retained, with default: dbos unchanged
    And the 2.0.0.yaml dbos-embedded component + temporal->dbos delta are annotated deferred while the postgres-16->postgres-17 delta stays intact
    And the flat 1.0.0 postgres:16-alpine datastore, schema.yaml, and 1.0.0.tar.gz remain byte-identical
    And b8-3 (17/17) + b8-3b (12/12) stay GREEN under the candidate edit
    And Article VIII.2 is PRESERVED (Temporal retained) and NOT amended (no GOVERNANCE.md amendment needed)
```

## Anti-Hallucination Pass

- **DBOS-Rust premise FALSIFIED (central)** — plan §4.2 B.8.5's `dbos = 0.x`
  Cargo pin + DBOSContext is unbuildable: crates.io has no `dbos` crate; DBOS
  Transact ships Python/TypeScript/Go/Java only (Context7 `docs.dbos.dev`). The
  immature crates.io alternatives (`durable-rust`, `raftoral`) are unfit for the
  flagship. RECORDED prominently → DBOS deferred, Temporal retained, NO dbos
  crate specced (FR-B85-001).
- **persistence pin source PRE-EXISTS** — re-read confirms persistence.yaml
  v1.0.0 already pins `postgres-17` + `pgvector-0.8` and the 2.0.0.yaml component
  already refs it; so B.8.5 CONSUMES (no new standard), the explicit contrast
  with B.8.4 which CREATED gateway.yaml (FR-B85-020 / ADR-B85-004).
- **pgvector image + extension** — sourced from Context7 (`/pgvector/pgvector`),
  NOT training data: `pgvector/pgvector:pg<MAJOR>-<distro>` family +
  `CREATE EXTENSION vector`. The **concrete tag is deferred to verify-then-pin
  at implement** (NFR-B85-005); the `pg17` family vs the docs' `pg18-trixie`
  example is recorded, not normalized — Q-004, not guessed.
- **Article VIII.2 framing** — Temporal SHALL is IN FORCE; this re-scope RETAINS
  Temporal (defers DBOS), so VIII.2 is PRESERVED and NO amendment is needed —
  stated explicitly as a compliance positive (NFR-B85-006), unlike the DBOS plan.
- **Test-coupling grounding** — re-read b8-3.test.sh: forbidden component keys =
  exactly `{version,pin,image}` (T-012), forbidden scalar `^\d+\.\d+` (T-015),
  `standard:` refs must resolve (T-011), postgres migration_note + delta required
  (T-016). The dbos-deferred annotation shape is constrained to satisfy these
  (FR-B85-006 / ADR-B85-006), not assumed safe.
- **Independent review (REQUIRED before design)** — these propose + specify
  artifacts MUST pass an INDEPENDENT reviewer (not the author) before
  `/forge:design`, and the image tag is **verify-then-pin at `/forge:implement`**.
  Not self-approved here.

## Open Questions

Tracked in `open-questions.md`: Q-001 (datastore template shape — compose vs
+K8s → ADR-B85-002, open), Q-002 (orchestration.yaml DBOS-deferral
representation — version bump + body field vs frontmatter note → ADR-B85-005,
open), Q-003 (2.0.0.yaml dbos-deferred annotation shape — `status:`/`note:` keeps
b8-3/b8-3b green → ADR-B85-006, open), Q-004 (concrete `pgvector/pgvector:pg17`-
family image tag + extension-enable mechanism — verify-then-pin at implement →
ADR-B85-003, open).
