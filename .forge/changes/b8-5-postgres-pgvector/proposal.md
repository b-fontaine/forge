# Proposal: b8-5-postgres-pgvector

<!-- Created: 2026-05-31 -->
<!-- Schema: default -->
<!-- Audit: B.8.5 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0 migration, RE-SCOPED: Postgres 16→17 + pgvector datastore brick; DBOS deferred — no Rust SDK) -->

## Problem

B.8 migrates `full-stack-monorepo / 1.0.0` → `2.0.0` (the point of no
return, plan §4) under an **additive-first, breaking-second** strategy
(§4.1): new components are added **in parallel** with the 1.0.0
components, and the actual `1.0.0 → 2.0.0` bump plus removal of
Kong / Temporal / REST-bridge happens at **B.8.14**, not before. B.8.4
(`b8-4-envoy-gateway`, archived 2026-05-31) shipped the **first real
2.0.0 template brick** and established the versioned-subtree convention
`.forge/templates/archetypes/full-stack-monorepo/2.0.0/...`.

### CENTRAL ANTI-HALLUCINATION FINDING (Article III.4) — the plan's B.8.5 premise is FALSIFIED

Plan §4.2 B.8.5 reads: *"Templates DBOS embedded — Cargo.toml `dbos =
0.x`, DBOSContext boilerplate, init Postgres state tables."* **This
premise is FALSE: DBOS has NO Rust SDK.** Re-verified 2026-05-31:

- **crates.io has no `dbos` crate** (the `dbos = 0.x` pin the plan
  prescribes does not exist — a `cargo add dbos` would 404).
- **DBOS Transact ships SDKs for TypeScript, Python, Go, and Java only**
  — confirmed via Context7 (`docs.dbos.dev` *quickstart* and
  *explanations/portable-workflows* both enumerate verbatim *"Python,
  TypeScript, Go, and Java"*; Context7 library catalog surfaces
  `dbos-transact-py`, `@dbos-inc/dbos-sdk` (TS),
  `github.com/dbos-inc/dbos-transact-golang` (Go) — **no Rust crate**).
- The two crates.io "alternatives" are **too immature for the flagship**
  (`durable-rust` ~612 downloads, solo author; `raftoral` ~327
  downloads, embedded-Raft — **not** Postgres-backed durable execution).

There is therefore **no `dbos` crate to pin and no DBOSContext to
scaffold for a Rust backend** today. Per Article III.4 this finding is
recorded prominently rather than guessed around: **this change SHALL NOT
spec any `dbos` crate pin, any `Cargo.toml dbos = 0.x` line, or any
DBOSContext boilerplate.**

### Maintainer re-scope decision

The maintainer DECIDED to **defer DBOS** (keep **Temporal** as the 2.0.0
workflow orchestrator until a production-grade Rust DBOS SDK ships) and
to **re-scope B.8.5 to the real, achievable delta the plan ALSO assigns
to it**: the **Postgres 16 → 17 + pgvector** datastore. The 2.0.0
candidate schema already carries this delta as a first-class component:

```yaml
- name: postgres-17-pgvector
  role: persistence
  replaces: postgres-16  # 1.0.0 baseline: postgres:16-alpine, no pgvector (B8-BASELINE §2)
  delivered_by: B.8.5  # DBOS state tables + B.7 RAG depend on this delta
  standard: persistence.yaml  # default: postgres-17, extensions: pgvector
  migration_note: >
    CROSSING DELTA (B8-BASELINE §2): 1.0.0 ships postgres:16-alpine without
    pgvector. This bump MUST NOT be silent; it crosses during B.8.5 migration.
```

and the matching migration delta:

```yaml
- from: postgres-16-no-pgvector
  to: postgres-17-pgvector
  brick: B.8.5
  note: crossing delta; pgvector also required by B.7 (ai-native-rag archetype)
```

This re-scoped delta is the substantive, buildable B.8.5 deliverable: it
**unblocks B.7 RAG** (vector workloads) and **any future DBOS state
store** (DBOS, in any language, is Postgres-backed — the Postgres-17 +
pgvector datastore is the prerequisite regardless of which language's
DBOS SDK eventually lands).

**Ground truth (re-read 2026-05-31, Article III.4):**

- **1.0.0 Postgres today is `postgres:16-alpine`, no pgvector.** The dev
  datastore is declared in
  `.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl:38`
  (`fsm-db` service, `image: postgres:16-alpine`, named volume
  `fsm-db-data`, `pg_isready` healthcheck). It is in the **flat 1.0.0
  tree** (no version subdir) and is **frozen** (B.8.2). There is **no
  pgvector** anywhere in the flat tree.
- **The 2.0.0 delta = Postgres 17 + pgvector**, sitting in the
  **versioned** 2.0.0 subtree per the B.8.4 convention
  (`.forge/templates/archetypes/full-stack-monorepo/2.0.0/...`). Today
  that subtree contains only `2.0.0/infra/k8s/envoy-gateway/**` (B.8.4);
  there is **no** persistence/datastore template under `2.0.0/` yet.
- **The version pin source ALREADY EXISTS — no new standard needed.**
  `.forge/standards/persistence.yaml` v1.0.0 (ADR-010, T.4 ratification)
  already declares `default: postgres-17` and `extensions: [pgvector-0.8,
  postgis, timescaledb]`, and the 2.0.0.yaml `postgres-17-pgvector`
  component already cites `standard: persistence.yaml`. **This is the key
  CONTRAST with B.8.4**, which had to *create* a new `gateway.yaml`
  standard (`pin_source: B.8.4`) because no `*.yaml` standard pinned a
  gateway. Here the standard, the default version, and the extension list
  pre-exist and the schema ref already resolves. The B.8.5 datastore
  template **consumes** persistence.yaml; it does **not** author a new
  persistence standard.
- **The concrete container image tag is verify-then-pin at implement.**
  Context7 (`/pgvector/pgvector`) confirms the official Docker Hub image
  is `pgvector/pgvector:pg<MAJOR>-<distro>` (docs render `pg18-trixie` as
  the current example; the **Postgres-17 family tag is the
  `pg17`-prefixed variant**, e.g. `pgvector/pgvector:pg17` /
  `pgvector/pgvector:pg17-trixie`). The extension is enabled with
  `CREATE EXTENSION vector;` once per database. The **exact tag string**
  (which distro suffix, whether `pg17` vs `pg17-trixie`) is
  **verify-then-pin at `/forge:implement`** (live registry inspect),
  NOT hard-pinned in specify (kong / b8-coroot / b8-signoz lesson). This
  change identifies the **image family + extension-enable mechanism**
  only.
- **orchestration.yaml records the DBOS-Rust gap as a pre-existing,
  ratified concern.** `.forge/standards/orchestration.yaml` v1.0.0
  declares `default: dbos, fallback: temporal` (ADR-002, assumed DBOS
  usable), and the REVIEW.md seed ledger (2026-05-04) already flags
  *"orchestration.yaml … DBOS-rs maturity (< 1 year prod) to revisit"*.
  This change extends that ratified concern with the concrete 2026-05-31
  finding: **DBOS has no Rust SDK at all** (not merely immature), so for
  the Rust flagship **Temporal is RETAINED** as the 2.0.0 orchestrator.
- **Standard frontmatter contract (observed, J.7-enforced).** Every
  `.forge/standards/*.yaml` carries `version` / `last_reviewed` /
  `expires_at` / `exception_constitutional` / `linter_rule` /
  `enforcement{ci_blocking,pre_commit_hook}` / `forbidden` / `rationale`,
  validated by `bin/validate-standards-yaml.sh` (J.7), and an additive
  bump registers a row in `.forge/standards/REVIEW.md` (precedent:
  `transport.yaml` 1.0.0 → 1.1.0 / 1.2.0 KEEP-WITH-CHANGES,
  `observability.yaml` → v2.1.0). The orchestration.yaml deferral edit,
  if a body field + version bump, MUST satisfy that contract and add a
  REVIEW.md row.

## Solution

Author the **specification for** the Postgres 16 → 17 + pgvector
datastore brick (B.8.5, re-scoped), plus the standards/schema annotations
that record the DBOS-Rust-unavailable deferral. **B.8.5 (this change)
ships NO templates, NO concrete image pin, and NO standard/schema edits
as code** — this is propose + specify only. The datastore template, the
concrete pgvector image tag (verify-then-pin), the orchestration.yaml
deferral edit, and the 2.0.0.yaml dbos-deferred annotation are built in
the implementation phase from these specs after design.

When built, the B.8.5 brick MUST:

1. **Add a Postgres 17 + pgvector datastore to the versioned 2.0.0
   template tree** rooted at
   `.forge/templates/archetypes/full-stack-monorepo/2.0.0/...` (the
   B.8.4 versioned-subtree convention), coexisting with — and
   byte-untouching — the flat 1.0.0 `docker-compose.dev.yml.tmpl`
   (`postgres:16-alpine`) (→ ADR-B85-001, ADR-B85-002). The datastore
   MUST use a Postgres-17 + pgvector image from the
   `pgvector/pgvector:pg17`-family (concrete tag verify-then-pin), and
   MUST enable the `vector` extension (`CREATE EXTENSION vector;`) on
   init (→ ADR-B85-003).
2. **Consume the pre-existing `persistence.yaml` pin source** (default
   `postgres-17`, extensions `pgvector-0.8`) — NOT author a new
   persistence standard. The 2.0.0.yaml `postgres-17-pgvector`
   component's `standard: persistence.yaml` ref already resolves
   (b8-3 T-011 green); the postgres delta stays as-is (→ ADR-B85-004).
3. **Record the DBOS-Rust-unavailable deferral** in
   `.forge/standards/orchestration.yaml`: a note/field stating DBOS has
   no Rust SDK, so for the Rust flagship **Temporal is RETAINED** as the
   2.0.0 orchestrator until a Rust DBOS ships; the `default: dbos` value
   remains the aspirational target for non-Rust contexts. This is an
   additive standard edit (J.7-validated + REVIEW.md row). Whether it is
   a version bump (1.0.0 → 1.1.0) + a body field vs a frontmatter note is
   an OPEN question studied against the transport.yaml /
   observability.yaml additive-bump precedent (→ ADR-B85-005, Q-002).
4. **Annotate the 2.0.0.yaml `dbos-embedded` component + its
   migration_delta as deferred** (candidate edit — permitted, it is the
   candidate not the frozen 1.0.0 `schema.yaml`): mark `dbos-embedded`
   deferred (no Rust SDK; Temporal retained) and annotate the
   `temporal-intent → dbos-embedded` delta deferred. The
   `postgres-16-no-pgvector → postgres-17-pgvector` delta STAYS (now
   actively delivered by this brick). The representation (a `status:` /
   `note:` field) MUST NOT introduce a forbidden inline-pin key
   (`version`/`pin`/`image`) and MUST NOT add a scalar value matching
   `^\d+\.\d+`, so b8-3 T-010/T-011/T-012/T-015 stay green — and editing
   2.0.0.yaml MUST keep b8-3 (17 L1) + b8-3b (12 L1) GREEN (→ ADR-B85-006,
   Q-003).
5. **Be additive-first and freeze-safe**: B.8.5 MUST NOT modify the flat
   1.0.0 `docker-compose.dev.yml.tmpl` (`postgres:16-alpine` byte-
   untouched), MUST NOT modify the frozen `schema.yaml`, and MUST inherit
   the candidate's `scaffoldable: false` posture (the 2.0.0 datastore is
   an additive on-disk asset, not scaffolded by default).
6. **Ship a harness `b8-5.test.sh`** (≤5s hermetic, zero net/Docker,
   `--level` + `_helpers.sh`, registered one-line in forge-ci.yml after
   `b8-4.test.sh`) asserting the intent: postgres-17 + pgvector template
   present in the 2.0.0 tree, pgvector `CREATE EXTENSION vector`
   enabled, `persistence.yaml` reference resolves, orchestration.yaml
   DBOS-deferral recorded, 2.0.0.yaml dbos deferred + postgres delta
   intact, additive (1.0.0 `postgres:16` byte-untouched), and b8-3 /
   b8-3b stay GREEN (→ FR-B85-050..056).

Decisions reserved for `/forge:design` (ADRs), leanings stated, open
where genuinely undecided (see `open-questions.md`):

- **ADR-B85-001 — datastore placement in the versioned 2.0.0 tree.**
  Plan §4.2 B.8.5 named "init Postgres state tables" inside the (defunct)
  DBOS framing; the real datastore delta belongs in the B.8.4 versioned
  subtree. **Lean:** new datastore template under
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/...`, coexisting
  with the byte-untouched flat 1.0.0 `docker-compose.dev.yml.tmpl`.
  Mirrors the ratified B.8.3 / B.8.4 versioned-sibling precedent.
- **ADR-B85-002 — exact datastore template shape (compose vs k8s vs
  both).** The flat 1.0.0 datastore is the dev `fsm-db` service in
  `docker-compose.dev.yml.tmpl`; the 1.0.0 K8s base
  (`infra/k8s/base/`) carries deployment/service but no Postgres
  StatefulSet. **Lean:** a 2.0.0 dev-compose datastore fragment mirroring
  the 1.0.0 `fsm-db` shape (env, named volume, `pg_isready`
  healthcheck) bumped to the pgvector image + an init step that runs
  `CREATE EXTENSION vector;`. Whether a K8s manifest also ships is open
  (→ Q-001).
- **ADR-B85-003 — pgvector image family + extension-enable mechanism.**
  Context7: `pgvector/pgvector:pg<MAJOR>-<distro>`, `CREATE EXTENSION
  vector;`. **Lean:** `pgvector/pgvector:pg17`-family image; enable the
  extension via an init SQL (`docker-entrypoint-initdb.d`) or migration.
  **Concrete tag string is verify-then-pin at implement** (live registry
  inspect), NOT pinned here (→ Q-004).
- **ADR-B85-004 — persistence.yaml is CONSUMED, not authored.** Contrast
  B.8.4 (created `gateway.yaml`). persistence.yaml v1.0.0 already pins
  `default: postgres-17` + `extensions: pgvector-0.8`; the 2.0.0.yaml
  component already refs it. **Lean:** consume as-is, no persistence
  standard edit, no version bump of persistence.yaml.
- **ADR-B85-005 — orchestration.yaml DBOS-deferral representation.**
  **Lean:** additive version bump 1.0.0 → 1.1.0 adding a body field
  (e.g. `rust_sdk_status` / a `notes`/`deferral` block) recording
  "DBOS has no Rust SDK; Temporal retained for the Rust flagship", with
  a REVIEW.md KEEP-WITH-CHANGES row — mirroring transport.yaml's additive
  1.0.0 → 1.1.0 bump. Whether a frontmatter note suffices (no bump) is
  open (→ Q-002). `default: dbos` is NOT changed (it stays the
  aspirational non-Rust target).
- **ADR-B85-006 — 2.0.0.yaml dbos-deferred annotation shape.** **Lean:**
  add a `status: deferred` + `note:` (free-text) to the `dbos-embedded`
  component and a `note:` to its `temporal-intent → dbos-embedded` delta.
  These keys are NOT in the forbidden set `{version,pin,image}` and carry
  no `^\d+\.\d+` scalar, so b8-3 T-012/T-015 stay green; the
  `standard: orchestration.yaml` ref stays (T-011). The postgres delta is
  untouched. Confirm the candidate-schema shape extension is acceptable
  (→ Q-003).

Release vehicle: maintainer-set (additive datastore template + additive
orchestration.yaml deferral edit + candidate-schema annotation; no change
to default 1.0.0 scaffolding behavior; Postgres-16 dev datastore
unchanged).

## Scope In

- `proposal.md`, `specs.md`, `.forge.yaml`, `open-questions.md` for
  `b8-5-postgres-pgvector` (this change): authoring requirements + ADRs +
  open questions for the re-scoped Postgres 16→17 + pgvector datastore
  brick and the DBOS-Rust-unavailable deferral record.
- Requirement set (`FR-B85-*` / `NFR-B85-*`) defining WHAT the 2.0.0
  datastore template, the pgvector image family + extension-enable, the
  persistence.yaml consumption, the orchestration.yaml deferral edit,
  the 2.0.0.yaml dbos-deferred annotation, and the b8-5 harness must
  contain.
- ADRs `ADR-B85-001..006` capturing datastore placement, template shape,
  the pgvector image family, persistence.yaml consumption, the
  orchestration deferral representation, and the candidate annotation
  shape.
- Identification (via Context7) of the `pgvector/pgvector:pg17`-family
  image + the `CREATE EXTENSION vector` mechanism, with the concrete tag
  **deferred to verify-then-pin at `/forge:implement`**.

## Scope Out (Explicit Exclusions)

- **Any `dbos` crate pin, `Cargo.toml dbos = 0.x` line, or DBOSContext
  boilerplate** — DBOS has NO Rust SDK (central finding). This change
  SHALL NOT spec them. DBOS is DEFERRED; Temporal is retained.
- **Building the 2.0.0 datastore template itself**
  (`.../full-stack-monorepo/2.0.0/...` datastore fragment) — that is the
  implementation phase of B.8.5, authored AFTER design from these specs.
- **The concrete pgvector container image tag** — `pgvector/pgvector:
  pg17`-family identified; the exact tag string (distro suffix) is
  **verify-then-pin at implement** (live registry inspect), never
  fabricated in propose/specify.
- **Editing/creating `persistence.yaml`** — it already pins
  `postgres-17` + `pgvector-0.8`; B.8.5 CONSUMES it (contrast B.8.4's new
  `gateway.yaml`). No persistence standard authored or bumped.
- **Editing the flat 1.0.0 template tree** (`docker-compose.dev.yml.tmpl`
  `postgres:16-alpine`) or the frozen `schema.yaml` — additive only;
  Postgres-16 dev datastore stays in parallel. Removal/bump is B.8.14.
- **Changing `orchestration.yaml default: dbos`** — `default` stays the
  aspirational non-Rust target; B.8.5 only RECORDS the Rust-SDK gap +
  Temporal retention (additive note/field).
- **Amending Constitution Article VIII.2 (Temporal SHALL)** — NOT needed.
  This re-scope PRESERVES VIII.2 (Temporal retained) — see "Constitution
  Compliance". Contrast the abandoned DBOS plan, which would have needed
  the B.8.14 amendment to drop Temporal.
- **Connect-RPC** (B.8.6), **Zitadel** (B.8.7), **Qwik web-public**
  (B.8.9), **migration script** (B.8.10), **zero-regression E2E**
  (B.8.12), **schema bump + breaking removal** (B.8.14).
- **B.7 ai-native-rag archetype** — B.8.5 unblocks it (vector datastore)
  but does not implement RAG.

## Impact

- **Users affected**: B.8 migration architects (the Postgres-17 +
  pgvector datastore is the persistence realization of the 2.0.0
  candidate) and B.7 (RAG vector workloads), B.8.12 / B.8.14 (consume the
  2.0.0 datastore). **No effect on current 1.0.0 adopters** — the flat
  1.0.0 `postgres:16-alpine` dev datastore is untouched and the 2.0.0
  candidate is `scaffoldable: false`.
- **Technical impact**: spec artifacts only in this change. Downstream, a
  new additive 2.0.0 datastore template appears; orchestration.yaml gains
  an additive DBOS-Rust-deferral record (+ REVIEW.md row); 2.0.0.yaml
  gains dbos-deferred annotations (candidate edit). No new persistence
  standard (persistence.yaml consumed as-is).
- **Dependencies**: depends on B.8.3 (candidate schema declares the
  postgres-17-pgvector component + the postgres-16 → postgres-17
  migration delta this brick realizes; declares dbos-embedded that this
  brick annotates deferred) and B.8.4 (versioned 2.0.0 subtree convention
  + J.7 additive-standard-edit + REVIEW.md ledger precedent). Gates /
  feeds B.7 (RAG vector store), B.8.12 (zero-regression gate), B.8.14
  (bump + removal).

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: this is the
  propose+specify gate; no implementation precedes it. The datastore
  template, the orchestration.yaml edit, and the 2.0.0.yaml annotation
  are built only after design from these specs.
- **Article III.4 (Anti-Hallucination) — CENTRAL**: the plan's B.8.5 DBOS
  premise is FALSIFIED and recorded prominently. **DBOS has no Rust SDK**
  (crates.io `dbos` 404; DBOS Transact = Python/TypeScript/Go/Java only,
  Context7 `docs.dbos.dev`); this change therefore specs NO `dbos` crate
  pin / `Cargo.toml dbos = 0.x` / DBOSContext. The 1.0.0
  `postgres:16-alpine` reality, the pre-existing persistence.yaml pins,
  and the orchestration.yaml `default: dbos` are re-read from live files.
  The pgvector image family (`pgvector/pgvector:pg17`) + extension-enable
  (`CREATE EXTENSION vector`) are sourced from Context7 (`/pgvector/
  pgvector`); the **concrete tag is deferred to verify-then-pin at
  implement** (kong / b8-coroot / b8-signoz lesson). Genuine unknowns are
  flagged `[NEEDS CLARIFICATION]`.
- **Article IV (Delta-based)**: the 2.0.0 datastore template is a NEW
  additive asset; it does not rewrite or delete the flat 1.0.0
  `docker-compose.dev.yml.tmpl`. The orchestration.yaml deferral is an
  additive edit; the 2.0.0.yaml annotations are additive edits to the
  *candidate* (permitted), not the frozen 1.0.0 `schema.yaml`.
- **Article V (Compliance gate)**: ADRs map each open question to a
  design-phase resolution; no work proceeds around the unresolved
  template-shape / orchestration-representation / annotation-shape / image
  pin questions.
- **Article VIII.2 (Temporal SHALL — IN FORCE, PRESERVED)**: Constitution
  v1.1.0 §VIII.2 mandates **Temporal** for workflow orchestration, and
  the 2.0.0.yaml header records VIII.2 binding until B.8.14. **This
  re-scope PRESERVES VIII.2 as a compliance positive**: deferring DBOS and
  **retaining Temporal** keeps the Rust flagship squarely on the
  Constitutionally-mandated orchestrator. Crucially — and unlike the
  abandoned DBOS plan, which would have replaced Temporal with DBOS and
  thus required the B.8.14 GOVERNANCE.md amendment to VIII.2 — **B.8.5 as
  re-scoped needs NO amendment to VIII.2**. The orchestration.yaml
  `default: dbos` remains an aspirational (non-Rust) target recorded in a
  *standard*, not a deployed violation of the Temporal SHALL clause.
- **Article VIII.5 (IaC) / X (quality)**: the datastore template is
  version-controlled IaC; persistence.yaml (consumed) already carries its
  J.7 frontmatter + review cadence; the orchestration.yaml additive edit
  lands under the J.7-validated standard contract + REVIEW.md row. No
  relaxation of TDD/BDD/coverage.
- **Article XII (Governance)**: no Constitution amendment here. Because
  Temporal is retained, the VIII.2 amendment that the DBOS plan would have
  required is NOT triggered.

## Open Questions (seed)

- **Q-001** — datastore template shape: dev-compose fragment only, vs
  compose + a K8s Postgres StatefulSet manifest, vs init-SQL placement
  (→ ADR-B85-002; open, resolved at `/forge:design`).
- **Q-002** — orchestration.yaml DBOS-deferral representation: version
  bump 1.0.0 → 1.1.0 + a body field (transport.yaml additive-bump
  precedent) vs a frontmatter-only note (no bump) (→ ADR-B85-005; open).
- **Q-003** — 2.0.0.yaml dbos-deferred annotation shape: `status:` +
  `note:` field on the `dbos-embedded` component + delta `note:` —
  confirm this candidate-schema shape extension is acceptable and keeps
  b8-3 T-010/011/012/015 + b8-3b green (→ ADR-B85-006; open).
- **Q-004** — concrete `pgvector/pgvector:pg17`-family image tag (distro
  suffix) + extension-enable mechanism (init-SQL vs migration) —
  **verify-then-pin at `/forge:implement`**, flagged `[NEEDS
  CLARIFICATION]` here, not guessed (→ ADR-B85-003; open).
