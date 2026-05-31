# Open Questions — b8-5-postgres-pgvector

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
AUTHOR phase only: leanings recorded; resolutions are made at /forge:design by
an INDEPENDENT reviewer + the maintainer, NOT self-approved here. The concrete
pgvector image tag (Q-004) is verify-then-pin at /forge:implement.
-->

## Resolution Log (/forge:design, 2026-05-31)

All four questions resolved at /forge:design (maintainer decisions, encoded in
`design.md` ADR-B85-001..006). The author flips them to answered here; an
INDEPENDENT reviewer ratifies before `/forge:plan` (NOT self-approved). The
Q-004 image tag is recorded as a verify-then-pin SHAPE in design + a LIVE pin at
`/forge:implement` (registry inspect), never fabricated.

| Q | Decision | ADR |
|---|----------|-----|
| Q-001 | **(a)** dev-compose fragment + init-SQL under `2.0.0/infra/postgres/`, **NO k8s** (1.0.0 has no Postgres StatefulSet; prod DB external/managed) | ADR-B85-001/002 |
| Q-002 | **(a)** orchestration.yaml additive bump 1.0.0 → 1.1.0 + `rust_sdk_status` body field + REVIEW.md KEEP-WITH-CHANGES row; `default: dbos` UNCHANGED, recorded language-conditional | ADR-B85-005 |
| Q-003 | **(a)** `2.0.0.yaml` `dbos-embedded` `status: deferred` + `note:` + delta `note:`; keeps b8-3 (17 L1) + b8-3b (12 L1) GREEN (status/note ∉ {version,pin,image}; no `^\d+\.\d+` scalar); NO companion b8-3 test update | ADR-B85-006 |
| Q-004 | verify-then-pin SHAPE recorded (`pgvector/pgvector:VERIFY_THEN_PIN`, pg17-family, init-SQL); concrete tag LIVE at `/forge:implement` | ADR-B85-003 |

## Q-001: Datastore template shape (dev-compose fragment vs +K8s)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B85-002 seed), `specs.md` FR-B85-010/013
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-5 specify pass)

### Question

The flat 1.0.0 datastore is the dev `fsm-db` service in
`docker-compose.dev.yml.tmpl` (`postgres:16-alpine`, env, named volume,
`pg_isready`). The flat 1.0.0 K8s base (`infra/k8s/base/`) ships
deployment/service/ingress but **no Postgres StatefulSet** (the dev compose is
the only datastore manifest today). The 2.0.0 datastore belongs in the B.8.4
versioned subtree (`.../full-stack-monorepo/2.0.0/...`).

`[NEEDS CLARIFICATION: Should the 2.0.0 datastore ship as (a) a dev-compose
fragment only, mirroring the 1.0.0 fsm-db shape bumped to the pgvector image +
init-SQL; (b) compose PLUS a K8s Postgres StatefulSet/Service manifest under
2.0.0/infra/k8s/; or (c) an init-SQL/migration asset only, assuming the image is
wired elsewhere? And what exact path under 2.0.0/ does the datastore live at?]`

- (a) **Dev-compose fragment mirroring 1.0.0 fsm-db** — smallest additive delta,
  consistent with the only existing datastore manifest (the dev compose);
  freeze-safe. **Lean here** (matches the 1.0.0 datastore surface).
- (b) **Compose + K8s StatefulSet** — fuller production parity, but the 1.0.0
  tree has NO Postgres K8s manifest to mirror, so this introduces a new surface
  shape that may belong to a later prod-hardening brick.
- (c) **Init-SQL / migration asset only** — minimal, but leaves the image
  wiring implicit, weakening the "datastore present" assertion.

### Resolution

- **Resolved on**: 2026-05-31 (/forge:design — maintainer; INDEPENDENT reviewer ratifies before /forge:plan)
- **Decision**: **(a)** Dev-compose fragment + init-SQL, **NO k8s**. The 2.0.0
  datastore ships under `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/postgres/`
  as three files: `docker-compose.fragment.yml.tmpl` (a `fsm-db` Postgres-17 +
  pgvector dev service mirroring the 1.0.0 `fsm-db` shape, with a verify-then-pin
  image placeholder), `init-pgvector.sql.tmpl` (`CREATE EXTENSION IF NOT EXISTS
  vector;` via `docker-entrypoint-initdb.d`), and `README.md.tmpl`. No K8s
  Postgres StatefulSet is added. (ADR-B85-001 / ADR-B85-002.)
- **Rationale**: The live 1.0.0 datastore is pinned ONLY in the dev compose
  (`docker-compose.dev.yml.tmpl:38`, `postgres:16-alpine`); `infra/k8s/base/`
  carries NO Postgres StatefulSet (the live 1.0.0 prod DB is external/managed).
  Mirroring the 1.0.0 datastore footprint means a dev-compose + init-SQL delta in
  the B.8.4 versioned subtree — the smallest additive, freeze-safe delta over the
  only existing datastore manifest. A K8s StatefulSet would introduce a new
  surface shape with no 1.0.0 analogue to mirror; it belongs to a later
  prod-hardening brick if ever needed.

---

## Q-002: orchestration.yaml DBOS-deferral representation (version bump + body field vs frontmatter note)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B85-005 seed), `specs.md` FR-B85-003/004
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-5 specify pass)

### Question

`.forge/standards/orchestration.yaml` v1.0.0 declares `default: dbos`,
`fallback: temporal` (ADR-002), and the REVIEW.md seed already flags
*"orchestration.yaml … DBOS-rs maturity (< 1 year prod) to revisit"*. B.8.5 must
record the concrete 2026-05-31 finding (DBOS has NO Rust SDK at all → Temporal
retained for the Rust flagship). The transport.yaml additive-bump precedent
(1.0.0 → 1.1.0 → 1.2.0, KEEP-WITH-CHANGES body fields + REVIEW.md rows) shows the
shape for an additive standard bump.

`[NEEDS CLARIFICATION: Should the DBOS-Rust-deferral be recorded as (a) an
additive version bump 1.0.0 → 1.1.0 adding a body field (e.g. rust_sdk_status /
a deferral/notes block) + a REVIEW.md KEEP-WITH-CHANGES row, mirroring
transport.yaml; or (b) a frontmatter-only note with NO version bump (lighter,
but no REVIEW.md ledger event)? In both cases default: dbos is UNCHANGED.]`

- (a) **Version bump 1.0.0 → 1.1.0 + body field + REVIEW.md row** — full
  standards-lifecycle traceability (J.7 + append-only ledger), directly mirrors
  transport.yaml's additive 1.0.0 → 1.1.0. **Lean here.** `default: dbos` stays
  the aspirational non-Rust target; the new field records the Rust-SDK gap +
  Temporal retention.
- (b) **Frontmatter note, no bump** — lighter, but skips the REVIEW.md ledger
  event the ratified DBOS-rs concern arguably deserves; weaker auditability.

### Resolution

- **Resolved on**: 2026-05-31 (/forge:design — maintainer; INDEPENDENT reviewer ratifies before /forge:plan)
- **Decision**: **(a)** Additive version bump 1.0.0 → 1.1.0 + a body field +
  a REVIEW.md KEEP-WITH-CHANGES row (the `transport.yaml` additive-bump
  precedent). The body field is a top-level `rust_sdk_status.dbos` block
  (`available: false`, `verified: 2026-05-31`, `rust_flagship_orchestrator:
  temporal`, `default_is_language_conditional: true`, `note:` prose). Frontmatter
  resets `last_reviewed: 2026-05-31` / `expires_at: 2027-05-31` (FR-J7-021
  ordering), keeps `exception_constitutional: false` (FR-J7-020). `default: dbos`
  is UNCHANGED but recorded as a **language-conditional** aspirational non-Rust
  target (not a live Rust selection). (ADR-B85-005.)
- **Rationale**: Full standards-lifecycle traceability (J.7 + append-only
  ledger) over a frontmatter-only note, mirroring `transport.yaml` 1.0.0 → 1.1.0.
  The bump keeps `validate-standards-yaml.sh` GREEN in dir-mode: the MANDATORY
  REVIEW.md `| orchestration.yaml | 1.1.0 |` row satisfies FR-J7-023 (without it
  the validator FAILs); `2027-05-31 > 2026-05-31` satisfies FR-J7-021 (the
  canonical enforcement pair); dated expiry ⇒ `exc:false` satisfies FR-J7-020.
  The additive body field is allowed by root `additionalProperties: true`
  (gateway.yaml/observability.yaml precedent). Per the review, the language-
  conditional nature of `default: dbos` is recorded explicitly in the body field,
  not merely left "unchanged."

---

## Q-003: 2.0.0.yaml dbos-deferred annotation shape (b8-3 / b8-3b coupling)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B85-006 seed), `specs.md` FR-B85-005/006
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-5 specify pass)

### Question

The 2.0.0.yaml `dbos-embedded` component (`replaces: temporal-intent,
delivered_by: B.8.5, standard: orchestration.yaml`) and its `temporal-intent →
dbos-embedded` migration_delta must be annotated **deferred** (DBOS has no Rust
SDK; Temporal retained). Editing 2.0.0.yaml is permitted (it is the candidate,
not the frozen 1.0.0 `schema.yaml`). But b8-3.test.sh is tightly coupled:
forbidden component keys = exactly `{version, pin, image}` (T-012); no component
scalar value may match `^\d+\.\d+` (T-015); every `standard:` ref must resolve
(T-011); every component needs a `name` (T-010); the postgres component must keep
its migration_note + the postgres-16 delta (T-016).

`[NEEDS CLARIFICATION: What annotation shape marks dbos-embedded deferred — (a)
a status: deferred + note: <free text> field on the component plus a note: on
the temporal->dbos delta; (b) a top-level deferred_components: list; or (c)
something else? Any new key MUST NOT be version/pin/image and MUST NOT carry a
^\d+\.\d+ scalar, so b8-3 T-010/011/012/015 + b8-3b stay GREEN. Is extending the
candidate-schema component shape with status:/note: acceptable, or does b8-3
need a companion test update?]`

- (a) **`status: deferred` + `note:` on the component + delta `note:`** — keys
  are NOT in `{version,pin,image}`, carry no `^\d+\.\d+` scalar (free-text
  prose), `standard:`/`name` preserved → b8-3 T-010/011/012/015 stay green; the
  postgres delta is untouched (T-016 green). **Lean here** — smallest additive
  candidate-shape extension.
- (b) **Top-level `deferred_components: [dbos-embedded]` list** — keeps the
  component body untouched, but introduces a new top-level key the schema readers
  may not expect; less locally legible.
- (c) **Comment-only annotation** — zero schema-shape change, but invisible to
  any programmatic "is dbos deferred?" assertion the b8-5 harness wants.

> NOTE: whichever shape is chosen, FR-B85-006 requires re-running b8-3 (17/17) +
> b8-3b (12/12) after the edit; the b8-5 harness includes the exit-code coupling
> guard (FR-B85-056). Whether b8-3 should gain a companion positive assertion
> for the deferred annotation is a design call.

### Resolution

- **Resolved on**: 2026-05-31 (/forge:design — maintainer; INDEPENDENT reviewer ratifies before /forge:plan)
- **Decision**: **(a)** `status: deferred` + `note:` (free-text prose) on the
  `dbos-embedded` component, plus a `note:` on the `temporal-intent →
  dbos-embedded` migration_delta. The `postgres-17-pgvector` component, its
  `migration_note`, and the `postgres-16-no-pgvector → postgres-17-pgvector`
  delta are left INTACT (the postgres delta is actively delivered, NOT deferred).
  **NO companion b8-3 test update** — the deferral is asserted positively by the
  new `b8-5.test.sh` (T-006/T-010), not b8-3. (ADR-B85-006.)
- **Rationale**: Confirmed against b8-3.test.sh source (lines 104-162): `status`
  and `note` are NOT in the forbidden key-set `{version, pin, image}` (T-012 does
  an exact `set(c.keys()) & forbidden` intersection); `status: deferred` and the
  `note:` prose are direct scalars that do NOT start with `^\d+\.\d+` (T-015 is a
  `version_re.match` value-walk over `components` direct scalars only — the
  drafting rule is that the `note:` must not BEGIN with a version token; the
  mid-string `2026-05-31` is safe). The delta `note:` lives under
  `migration_deltas`, which T-015 does NOT walk. `standard:` refs stay (T-011),
  `name` stays (T-010), the postgres `migration_note` + postgres-16 delta stay
  (T-016). b8-3 (17/17) + b8-3b (12/12) stay GREEN; the b8-5 harness re-runs both
  exit-code-only as a coupling guard (T-009). Smallest additive candidate-shape
  extension; the candidate (not the frozen schema.yaml) is editable.

---

## Q-004: Concrete pgvector image tag + extension-enable mechanism (verify-then-pin)

- **Status**: answered (shape recorded; concrete tag deferred to /forge:implement)
- **Raised in**: `proposal.md` (ADR-B85-003 seed), `specs.md` FR-B85-011/012/030,
  NFR-B85-005, Context7 Evidence
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-5 specify pass)

### Question

Context7 (`/pgvector/pgvector`) identifies the image family
`pgvector/pgvector:pg<MAJOR>-<distro>` (docs render `pg18-trixie` as the current
example; the Postgres-17 family is the `pg17`-prefixed variant) and the
extension-enable command `CREATE EXTENSION vector;`. The 2.0.0 delta requires
Postgres major **17** (over the 1.0.0 `postgres:16-alpine` baseline) with
pgvector ≥ 0.8 (persistence.yaml). The **concrete** tag string (which distro
suffix; `pg17` vs `pg17-trixie`) and the precise extension-enable placement
depend on the live registry state at implement time.

`[NEEDS CLARIFICATION: The concrete pgvector/pgvector:pg17-family tag (distro
suffix) and the extension-enable mechanism (init-SQL in
docker-entrypoint-initdb.d vs a migration step) MUST be VERIFIED LIVE at
/forge:implement (Docker Hub tag listing / docker manifest inspect) before being
written. They MUST NOT be fabricated in propose/specify/design (Article III.4 +
kong/b8-coroot/b8-signoz verify-then-pin lesson).]`

- This is a **verify-then-pin** item, not a multiple-choice design decision: the
  tag is determined by live registry inspection at `/forge:implement`. The design
  phase records the image FAMILY + the extension-enable shape + the verification
  procedure; the implementation phase performs the live check and pins. **Lean
  (shape):** `pgvector/pgvector:pg17`-family image, extension enabled via init-SQL
  in `docker-entrypoint-initdb.d`, target pgvector ≥ 0.8.

### Resolution

- **Resolved on**: 2026-05-31 (/forge:design records the verify procedure + shape;
  /forge:implement performs the LIVE pin — INDEPENDENT reviewer ratifies the
  design before /forge:plan)
- **Decision**: Verify-then-pin SHAPE recorded; concrete tag NOT pinned here.
  Image FAMILY = `pgvector/pgvector:pg17`-family (Postgres major 17). In
  `docker-compose.fragment.yml.tmpl` the `image:` is the placeholder token
  `pgvector/pgvector:VERIFY_THEN_PIN` (carries Postgres-major-17 intent in a
  comment, asserts NO concrete distro tag). Extension-enable mechanism =
  init-SQL (`init-pgvector.sql.tmpl`, `CREATE EXTENSION IF NOT EXISTS vector;`)
  mounted into `docker-entrypoint-initdb.d`. Extension version target =
  `pgvector-0.8` (policy: persistence.yaml, NOT inline). The concrete tag
  (distro suffix; `pg17` vs `pg17-trixie`) is resolved LIVE at `/forge:implement`
  via `docker manifest inspect` / Docker Hub tag listing, the digest recorded in
  `evidence.md`, and the `VERIFY_THEN_PIN` token replaced with the verified tag.
  (ADR-B85-003.)
- **Rationale**: This is a verify-then-pin item, not a multiple-choice design
  decision (kong / b8-coroot / b8-signoz lesson + Article III.4). The design
  fixes the FAMILY + the extension-enable shape + the verification procedure; the
  implementation phase performs the live check and pins. No concrete tag is
  asserted as registry-verified in design (NFR-B85-005). If the live registry
  lacks a `pg17`-family pgvector image at implement, the impl surfaces
  `[NEEDS CLARIFICATION]` rather than guessing.
