# Proposal: b8-signoz-unified
<!-- Created: 2026-05-26 -->
<!-- Schema: default -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, SigNoz leg) -->
<!-- Trio context: docs/new-archetypes-plan.md §0.7 (sibling 2 of b8-observability-rearch trio) -->
<!-- Pilot precedent: .forge/changes/b8-coroot-rehost/ (archived v0.4.0-rc.3) -->

## Problem

The `full-stack-monorepo / 1.0.0` archetype ships SigNoz as a **3-service
architecture** (`signoz/frontend:0.55.1` + `signoz/query-service:0.55.1` +
external `otel/opentelemetry-collector-contrib:0.96.0`), pinned in
`infra/docker-compose.dev.yml.tmpl` plus the Helm overlays under
`infra/k8s/base/`, and ratified by `.forge/standards/observability.yaml`
v1.2.0 (`versions.signoz_frontend`, `versions.signoz_query_service`, and
the external `versions.otel_collector_contrib` collector pin).

Two failures, both surfaced by the T5.3.2 verify-then-pin pass:

1. **Upstream architectural migration (2025-2026).** SigNoz upstream
   collapsed the 3-service layout to a **unified 2-service architecture** :
   `signoz/signoz` (unified frontend + query-service + alertmanager,
   embedded sqlite app state) + `signoz/signoz-otel-collector` (SigNoz-
   flavoured collector replacing the external `otel-collector-contrib`).
   This is a structural rearch, not a version bump.

2. **Old pins rotted on Docker Hub.** Per `docs/new-archetypes-plan.md`
   §0.5, the previous 3-service pins (`signoz/frontend:0.55.1`,
   `signoz/query-service:0.55.1`) are no longer publicly pullable — the
   last published `0.76.3` was also pruned. `t5-otel-stack-image-refresh`
   was **ABANDONED 2026-05-20** because pin refresh is impossible — it's
   a re-architecture, explicitly rerouted to B.8 / T6.

This rotted state is the documented root cause of the **`task validate
dev-up-matrix` RED** known-issue for `v0.4.0-rc.2` and `v0.4.0-rc.3`.
Every adopter scaffolding the flagship today inherits a
`docker-compose.dev.yml` that **fails ImagePull** on the SigNoz services.

The trio pilot `b8-coroot-rehost` (archived 2026-05-25 / v0.4.0-rc.3)
established the pattern : verify-then-pin against upstream, 4-copy mirror
sync, L2 manifest-pull harness, additive standards bump. This proposal
applies the same pattern at higher complexity — multi-component
re-architecture with `observability.yaml` **breaking** v1.2.0 → v2.0.0
and a new top-level `pin_review_cadence:` field.

## Solution

Multi-component infra rearch, scoped to **SigNoz only** :

1. **Migrate** `infra/docker-compose.dev.yml.tmpl` from the 3-service
   layout to the unified 2-service layout :
   - `signoz/signoz:v0.125.1` (unified UI + query-service + alertmanager)
   - `signoz/signoz-otel-collector:v0.144.4` (SigNoz-flavoured collector,
     replacing `otel/opentelemetry-collector-contrib:0.96.0`)
   - ClickHouse retained ; version may need bump 24 → 25
     `[NEEDS CLARIFICATION: pending upstream Compose fetch at design phase — Q-002]`
   - sqlite app state if SigNoz embeds it (was Postgres in 3-service arch)
     `[NEEDS CLARIFICATION: pending upstream Compose fetch at design phase — Q-001]`
   - OPAMP plumbing if SigNoz config requires explicit server stub
     `[NEEDS CLARIFICATION: pending upstream Compose fetch at design phase — Q-003]`
   - UI port migration `:3301` → `:8080` (verify against upstream Compose ; collides with
     example backend port — resolution Q-004).

2. **Migrate** Helm overlays under `templates/full-stack-monorepo/1.0.0/infra/k8s/`
   (if SigNoz K8s manifests are shipped — to confirm in `/forge:design`).

3. **Bump** `.forge/standards/observability.yaml` v1.2.0 → **v2.0.0 BREAKING** :
   - REMOVE `versions.signoz_frontend: "0.55.1"`
   - REMOVE `versions.signoz_query_service: "0.55.1"`
   - REMOVE `versions.otel_collector_contrib: "0.96.0"` (replaced by signoz-flavoured collector)
   - ADD `versions.signoz: "0.125.1"`
   - ADD `versions.signoz_otel_collector: "0.144.4"`
   - ADD new top-level field `pin_review_cadence:` with per-component cadence :
     - `signoz: "30d"` (aggressive upstream dev velocity)
     - `signoz_otel_collector: "30d"` (tracks signoz/signoz)
     - `beyla: "12mo"` (slow OBI cadence)
     - `coroot: "12mo"` (established pilot)
   - Update `last_reviewed: 2026-05-26`
   - Update `expires_at: 2027-05-26`
   - WAIVER block documenting architectural shift (not a normal version bump)
     per ADR-J7-* + `standards-lifecycle.md` § Bumps.

4. **Append** `REVIEW.md` ledger entry with `ARCH-CHANGE` flag (not the
   normal `Updated` flag) — semantically distinguishing structural
   re-architecture from version refresh per Article XII governance.

5. **New harness** `.forge/scripts/tests/b8-signoz.test.sh` :
   - L1 grep-based assertions (target ≥ 13 tests mirroring `b8-coroot.test.sh`).
   - L2 opt-in `FORGE_B8_SIGNOZ_DOCKER=1` runs :
     - `docker manifest inspect signoz/signoz:v0.125.1` exit 0 (multi-arch).
     - `docker manifest inspect signoz/signoz-otel-collector:v0.144.4` exit 0 (multi-arch).
     - `docker compose -f <rendered>.yml up -d` + healthcheck poll + cleanup.
     - Network-isolation enforcement (mirror `b8-coroot-rehost` ADR-B8-COR-003 L2 pattern).

6. **Register** harness in `.github/workflows/forge-ci.yml::harness` matrix.
   Verify ≤ 300-line NFR-CI-002 budget (currently 297/300 post b8-coroot-rehost ;
   may need T5.3.3 ADR-T533-002-style comment compression).

7. **Demeter pass** during `/forge:design`. SigNoz Inc jurisdiction +
   K3-RULE-* impact for T3 adopters (Q-006). CE license posture vs hosted
   SigNoz Cloud.

8. **Snapshot regen** via `bin/forge-snapshot.sh full-stack-monorepo 1.0.0`
   (deterministic, NFR-OTEL-001 budget ≤ 600 KB — assess against current
   ~520 KB ; multi-service rewrite may approach budget).

9. **infra/CLAUDE.md.tmpl** H2 section update — document unified
   architecture, OPAMP wiring if applicable, jurisdiction posture
   summary (T1/T2 OK self-host ; T3 candidate-substitution flag pending
   Q-006 evidence).

10. **CHANGELOG** entry under `## [Unreleased]` (release-target rc.4
    section pending /forge:plan).

Decisions reserved for `/forge:design` (resolved as ADRs, see
`open-questions.md` for the 6 initial Q-NNN scaffolds) :

- **ADR-1** — SigNoz unified embedded components inventory
  (alertmanager? ingest? ClickHouse client?). Drives 2-service vs
  3-service final layout.
- **ADR-2** — ClickHouse pin under unified arch (24.x retained vs 25.x
  required). Affects `versions.clickhouse:` standard frontmatter.
- **ADR-3** — OPAMP wiring requirement (native vs explicit server stub).
- **ADR-4** — UI port mapping (`:3301` preserved via env-var vs `:8080`
  direct ; backend example port conflict resolution).
- **ADR-5** — `pin_review_cadence:` schema location (top-level vs
  nested under `versions:`). Schema impact on `standard.schema.json`
  (J.7).
- **ADR-6** — SigNoz Inc jurisdiction posture + Demeter K3-RULE
  classification for T3 adopters.

Release vehicle : **`v0.4.0-rc.4`** — debloques the `task validate
dev-up-matrix` RED known-issue ; ships before `b8-obi-refresh` (trio
sibling 3) which can piggyback rc.5 or v0.4.0 final.

## Scope In

- Edit `templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl` (canonical).
- Mirror to the 3 downstream copies (4-copy mirror sync per pilot pattern) :
  - `examples/forge-fsm-example/infra/docker-compose.yml` (rendered)
  - `examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl` (if present — confirm in `/forge:design`)
  - `cli/assets/.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl`
- Helm overlays under `templates/full-stack-monorepo/1.0.0/infra/k8s/` (if applicable — confirm in `/forge:design`).
- Bump `.forge/standards/observability.yaml` v1.2.0 → v2.0.0 BREAKING (versions surgery + new `pin_review_cadence:` top-level field + WAIVER block).
- Append `2026-05-26 / ARCH-CHANGE / observability.yaml` row to `.forge/standards/REVIEW.md`.
- New harness `b8-signoz.test.sh` (L1 grep ≥ 13 tests + L2 manifest-pull + `docker compose up -d` opt-in).
- Register harness in `.github/workflows/forge-ci.yml::harness` matrix (verify ≤ 300-line NFR-CI-002 budget).
- Snapshot tarball regeneration via `bin/forge-snapshot.sh full-stack-monorepo 1.0.0` (SOURCE_DATE_EPOCH deterministic).
- `infra/CLAUDE.md.tmpl` H2 section update.
- CHANGELOG `[Unreleased]` (or `[0.4.0-rc.4]` post `/forge:plan`) entry.

## Scope Out (Explicit Exclusions)

- **OBI / Beyla refresh** → separate sub-change `b8-obi-refresh` (trio
  sibling 3 ; major bump 2.0.1 → 3.15.0 + capabilities Linux review +
  Aegis re-audit).
- **Re-architecture of OBI eBPF DaemonSet** — owned by `b8-obi-refresh`.
- **Migration to Grafana LGTM stack** — `docs/ARCHITECTURE-TARGET.md`
  ADR-008 declared **KEEP-WITH-CHANGES SigNoz** at flagship 1.0.0 → 2.0.0
  ; an LGTM swap is a separate B.8.x decision, not in scope here.
- **Envoy Gateway migration** — that's B.8.4, separate change.
- **DBOS migration** — that's B.8.5, separate change.
- **Kong removal** — Kong stays (3.6-alpine GONE per plan §0.5
  `docker manifest inspect`; Kong leg = future B.8.x change, defer).
- **`coroot` pin refresh or rearch** — owned by `b8-coroot-rehost` (pilot
  archived v0.4.0-rc.3). This change does not touch `versions.coroot`
  except as a passive read (kept at `1.20.2`).
- **`pin_review_cadence:` retrofit on K.3 or other standards** — this
  change introduces the field on `observability.yaml` only ; broader
  retrofit is a future J.7-class amendment.
- **`signoz-ee` paid edition** — out of forge default ; adopters with
  EE license can override locally.
- **SigNoz Cloud hosted variant** — out of scope ; CE binary self-host
  only ratified here.
- **Mobile-only archetype** — SigNoz is full-stack-monorepo only ;
  mobile-only is untouched.
- **ClickHouse data-volume migration tooling** — if ClickHouse bumps
  24 → 25 (Q-002), adopters with persistent data from the 3-service arch
  need migration ; this change declares **fresh-start only for dev
  environments** (acceptable since `dev-up-matrix` is dev-only ; prod
  adopters were already on rotted pins, not migrating in place).

## Impact

- **Users affected**: every adopter who scaffolded `full-stack-monorepo /
  1.0.0` and runs the dev compose or K8s observability overlay. T1
  adopters running compose-dev get the rotted-pin fix directly. T2/T3
  K8s adopters get the unified-arch Helm overlay update (scope confirmation
  Q-001 pending). Mobile-only adopters are entirely unaffected.
- **Technical impact**: **M-L** (per plan §0.7 sibling 1 estimate ;
  `b8-coroot-rehost` was `S` single-component, signoz is multi-component
  + OPAMP + ClickHouse + sqlite + breaking standard + new top-level field).
- **Dependencies**: depends_on `b8-coroot-rehost` (pilot established
  versions field, verify-then-pin process, 4-copy mirror sync, L2
  manifest-pull pattern, REVIEW.md ledger discipline). The pilot
  archive at v0.4.0-rc.3 is the precedent surface for this change's
  scope decisions.
- **Risk level**: **Medium**. Architectural rewrite class change
  (4 services → 2-3 services) ; tag convention verified
  (v-prefix on SigNoz tags — opposite of Coroot/Beyla, document to avoid
  the b8-coroot ADR-B8-COR-001 inversion pattern). Multi-component
  unknowns drive risk : ClickHouse pin, sqlite location, OPAMP requirement,
  port mapping. Each unknown is a Q-NNN with a `/forge:design` resolution
  path. L2 fixture (`docker compose up -d` with healthchecks) catches
  integration regressions before archive.

## Risk Detail

1. **ClickHouse 25 vs 24 data-volume incompatibility.** SigNoz unified
   may require ClickHouse 25 ; persistent ClickHouse volumes from the
   3-service arch may not migrate cleanly. Mitigation : declare
   "fresh-start only" for the dev compose (acceptable since
   `dev-up-matrix` is dev-environment) ; prod adopters were already on
   rotted pins, not migrating in place. Document in `infra/CLAUDE.md.tmpl`.
2. **sqlite app state vs old Postgres state.** If unified arch embeds
   sqlite for app state (replacing external Postgres), adopters lose
   alert configurations / dashboards saved in the old Postgres. Mitigation :
   document in CHANGELOG + `infra/CLAUDE.md.tmpl` ; same "fresh-start dev"
   posture applies. Confirm at `/forge:design` via upstream Compose fetch (Q-001).
3. **UI port 3301 → 8080 collision with example backend.**
   `examples/forge-fsm-example/backend/` exposes :8080. Two options :
   (a) use `SIGNOZ_UI_PORT` env-var defaulting to `:3301` mapped to container
   `:8080` (preserves adopter muscle memory) ; (b) shift backend port.
   Resolution Q-004 at `/forge:design`.
4. **OPAMP requires collector self-management.** If SigNoz config bakes
   in agents we don't yet ship, may need stub. Mitigation : check upstream
   Compose for explicit OPAMP wiring ; if SigNoz exposes OPAMP natively
   on `signoz/signoz`, no separate stub needed. Resolution Q-003.
5. **L2 fixture network exposure.** `docker compose up -d` in CI runner
   must not expose ports publicly. Mitigation : mirror `b8-coroot-rehost`
   ADR-B8-COR-003 L2 isolation pattern (bind to 127.0.0.1, cleanup trap,
   force-down on exit).
6. **`forge-ci.yml::harness` line budget.** Currently 297/300 post
   `b8-coroot-rehost`. Adding a new matrix entry may exceed NFR-CI-002.
   Mitigation : apply T5.3.3 ADR-T533-002-style comment compression
   before adding the matrix line ; if still exceeded, decline the
   matrix add and document in design.

## Constitution Compliance

### Article I — TDD

RED-GREEN cycle on `b8-signoz.test.sh`. RED first asserts :
1. All 4 copies of `docker-compose.dev.yml.tmpl` reference
   `signoz/signoz:v0.125.1` AND `signoz/signoz-otel-collector:v0.144.4`
   (regex grep).
2. No copy references the rotted 3-service pins
   (`signoz/frontend`, `signoz/query-service`,
   `otel/opentelemetry-collector-contrib`).
3. `observability.yaml::versions.signoz` matches `0.125.1`.
4. `observability.yaml::versions.signoz_otel_collector` matches `0.144.4`.
5. `observability.yaml::pin_review_cadence` declares all 4 components.
6. `observability.yaml::version` is `2.0.0`.
7. `REVIEW.md` carries a dated entry `2026-05-26 / ARCH-CHANGE / observability.yaml`.
8. CHANGELOG `[Unreleased]` (or `[0.4.0-rc.4]`) has a SigNoz section.
9. Snapshot tarball size ≤ NFR-OTEL-001 budget (600 KB).
10. L2 (opt-in) : `docker manifest inspect signoz/signoz:v0.125.1` exit 0.
11. L2 (opt-in) : `docker manifest inspect signoz/signoz-otel-collector:v0.144.4` exit 0.
12. L2 (opt-in) : both manifests carry `amd64` AND `arm64` platforms.
13. L2 (opt-in) : `docker compose up -d` against the rendered fixture
    converges with healthchecks GREEN within 120s ; cleanup on exit.

Then GREEN by editing the 4 copies + standard + REVIEW + CHANGELOG +
infra/CLAUDE.md.tmpl + harness + CI matrix. No code is written before
the test exists and fails as expected.

### Article II — BDD

Not applicable — no user-facing feature. Infra-only template refresh ;
the SigNoz UI is consumed by operators reading observability data, not
by application users. No Given/When/Then scenario justified.

### Article III — Specs Before Code

Confirmed. Pipeline is `/forge:propose` (this) → `/forge:specify` →
`/forge:design` → `/forge:plan` → `/forge:implement`. No template
modification before `specs.md` is ratified and `design.md` resolves the
six ADRs (components inventory / ClickHouse pin / OPAMP / port mapping /
schema location / jurisdiction posture).

### Article III.4 — Anti-Hallucination Protocol

Pin sourced from verified upstream evidence collected **2026-05-26**
(see `evidence.md` § 1 for verbatim transcripts) :

- `docker manifest inspect signoz/signoz:v0.125.1` ✅ multi-arch manifest list
  (amd64 sha256:e56541a2770632c8630c1bd32b6b57c43a8cfdcdfec85018eae410313dc70613 ;
  arm64 sha256:f2e0ce661687e0dcab16df8dc7e1dc3c7041d7c41846b0274bb38ac68b509419).
- `docker manifest inspect signoz/signoz-otel-collector:v0.144.4` ✅ multi-arch
  (amd64 sha256:9b2cc1a07772a703ec03f098130fca9baf097a0d24f18b2357cc3b52855a1a8d ;
  arm64 sha256:42727e4be83e85257f4d4d336d7c2a63c25a7d25e08d6be8c69aa521efff7950).
- Docker Hub tag listing (ordering=last_updated) :
  - `signoz/signoz` → `v0.125.1` published 2026-05-20 (latest).
  - `signoz/signoz-otel-collector` → `v0.144.4` published 2026-05-06 (latest).
- **Tag convention** : SigNoz upstream uses **v-prefix** (`v0.125.1`,
  `v0.144.4`) on both repositories — opposite of `coroot/coroot` and
  `grafana/beyla` which drop the prefix. **Documented inline** to avoid
  the `b8-coroot-rehost` ADR-B8-COR-001 inversion-at-impl pattern
  recurrence ; the upstream convention is verified by Docker Hub tag
  listing (no `0.125.1`-unprefixed alias exists ; the v-prefix is the
  canonical pull form).

Inline `[NEEDS CLARIFICATION:]` markers in this proposal :
- ClickHouse pin (Q-002)
- sqlite app state location (Q-001)
- OPAMP requirement (Q-003)

All three resolved via upstream Compose fetch at `/forge:design`, paired
with Q-NNN entries in `open-questions.md` per Article III.4 + F.1
discipline.

### Article V — Audit Trail

Proposal-phase only ; status `proposed`. No archive touched, no other
change directory modified. `evidence.md` captures the verify-then-pin
pass verbatim (digests + timestamps) so the audit trail survives
archive.

### Article VIII — Infra excellence + observability mandate

Refreshing the SigNoz pins is **the** debloque for the v0.4.0-rc.2/rc.3
known-issue (`task validate dev-up-matrix` RED). Not shipping leaves
Article VIII's "observability is non-negotiable" clause unenforceable
in practice (every adopter has a broken SigNoz compose). Trio
completion via b8-obi-refresh follows.

### Article XII — Governance

Standards bump v1.2.0 → **v2.0.0 BREAKING** with new top-level field
`pin_review_cadence:`. WAIVER block in the standard frontmatter
documents the architectural shift per `standards-lifecycle.md` § Bumps.
REVIEW.md ledger entry uses `ARCH-CHANGE` flag (not `Updated`) to
semantically distinguish from version-refresh bumps.

**Additive `pin_review_cadence:` field does NOT require constitution
amendment** per ADR-J7-008 schema relaxation precedent (additive
top-level fields permitted within the standards-lifecycle contract
without an Article XII amendment, provided the field is documented in
the standard's frontmatter and ratified in REVIEW.md).

The breaking versions surgery (removed `signoz_frontend`,
`signoz_query_service`, `otel_collector_contrib` ; added `signoz`,
`signoz_otel_collector`) IS the breaking change that justifies the
major bump v1.2.0 → v2.0.0, distinct from the additive cadence field.

## Open Questions

Six initial questions surfaced during proposal authoring, deferred to
`open-questions.md` (Q-001 .. Q-006) ; all to be resolved before
this change reaches `status: implemented`. Three `[NEEDS CLARIFICATION:]`
markers inline (ClickHouse pin, sqlite location, OPAMP) are paired
with Q-NNN per Article III.4 + F.1 discipline.

## Source documents

- `docs/new-archetypes-plan.md` §0.5 (T5.3.2 abandoned investigation evidence)
- `docs/new-archetypes-plan.md` §0.7 (b8-coroot-rehost archived rationale + trio scope)
- `docs/new-archetypes-plan.md` §4.2 B.8.8 (observability rearch parent audit item)
- `docs/ARCHITECTURE-TARGET.md` ADR-008 (KEEP-WITH-CHANGES SigNoz at flagship 1.0.0 → 2.0.0)
- `https://signoz.io/docs/install/docker/` (upstream Compose reference — fetch + cite version at `/forge:design`)
- Pilot precedent : `.forge/changes/b8-coroot-rehost/` (4 ADRs ADR-B8-COR-001..004 patterns to mirror or contrast)
