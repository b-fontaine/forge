# Spec: b8-postgres-pgvector

<!-- Audit: B.8.5 (b8-5-postgres-pgvector) -->
<!-- Source change : `.forge/changes/b8-5-postgres-pgvector/` (delta specs.md authoritative). -->

**Namespace** : `FR-B85-*` / `NFR-B85-*` / `ADR-B85-*`.
**Constitution** : v1.1.0, unchanged (no amendment). Article VIII.2 (Temporal
SHALL) is **PRESERVED** by this re-scope — see proposal "Constitution
Compliance". This change is **propose + specify + design + implement**.
It delivers the re-scoped `full-stack-monorepo / 2.0.0` **Postgres
16→17 + pgvector** datastore brick (B.8.5) and records the
**DBOS-Rust-unavailable deferral**.
**Governing articles** : I (TDD RED-first for the harness), III.1/III.2
(specs before code), III.4 (Anti-Hallucination — DBOS-Rust-absent recorded;
never invent versions/APIs), IV (delta-based: the 2.0.0 datastore tree +
standard/schema edits are additive, the flat 1.0.0 `postgres:16-alpine` and
frozen `schema.yaml` are untouched), VIII.2 (Temporal SHALL — in force,
PRESERVED: Temporal retained, no amendment), VIII.5 (IaC), X (J.7 standard
contract).

## Overview

B.8.5 was **RE-SCOPED**: the plan's premise — *"Templates DBOS embedded —
`Cargo.toml dbos = 0.x`, DBOSContext boilerplate, init Postgres state tables"*
— is **FALSIFIED** (no Rust DBOS SDK: crates.io `dbos` 404; DBOS Transact =
Python/TypeScript/Go/Java only — Context7 `docs.dbos.dev`). DBOS is therefore
**deferred**; Temporal is **retained** as the 2.0.0 orchestrator (Article
VIII.2 preserved). B.8.5 delivers the **real Postgres 16→17 + pgvector delta**
the plan also assigns to B.8.5 (pin `pgvector/pgvector:0.8.2-pg17` from
`persistence.yaml` policy). Concrete deliverables: datastore template tree
under `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/postgres/`
(`docker-compose.fragment.yml.tmpl` + `init-pgvector.sql.tmpl` + `README.md.
tmpl`); `orchestration.yaml` 1.0.0 → 1.1.0 DBOS-deferral record; `2.0.0.yaml`
`dbos-embedded` component annotated deferred; `b8-5.test.sh` 12 L1 hermetic;
independent review APPROVE; archived 2026-05-31.

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — DBOS deferral (no Rust SDK) (FR-B85-001 → 006)

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

#### Cluster 2 — Postgres 17 + pgvector datastore in the 2.0.0 tree (FR-B85-010 → 014)

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

#### Cluster 3 — persistence.yaml consumed, not authored (FR-B85-020 → 021)

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

#### Cluster 4 — Verify-then-pin (image tag) (FR-B85-030)

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
