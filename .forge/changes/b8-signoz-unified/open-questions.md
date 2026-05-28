# Open Questions — b8-signoz-unified

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN is sequential
per change, zero-padded to 3 digits, never reused.

All Q-NNN here are initial scaffolds raised in proposal.md and to be
resolved at `/forge:design` via upstream Compose fetch + Demeter pass.
-->

## Q-001: SigNoz unified embedded components inventory + sqlite app state

- **Status**: answered (ADR-B8-SIG-001 + ADR-B8-SIG-007)
- **Raised in**: `.forge/changes/b8-signoz-unified/proposal.md` § Solution + § Risk
- **Raised on**: 2026-05-26
- **Raised by**: maintainer (b8-signoz-unified propose pass)
- **Resolved on**: 2026-05-26 (`/forge:design`)
- **Resolved by**: Atlas (Infrastructure Architect)

### Question

The 3-service architecture (`signoz/frontend` + `signoz/query-service` +
external `Postgres` for app state) is being replaced by the unified
`signoz/signoz:v0.125.1`. Two unknowns surface :

1. **Which sub-components does `signoz/signoz` embed?** Does v0.125.1
   bundle the alertmanager + ingest path + ClickHouse client internally,
   or does it require separate alertmanager service? Affects scope
   (2-service vs 3-service final layout).
2. **Where does app state live?** Does unified arch embed sqlite for
   alerts / dashboards (replacing external Postgres), and at which
   container path / volume mount? Adopters with persistent state from
   the 3-service arch lose configurations on migration.

### Options

- (a) **Embedded sqlite, 2-service final layout** — `signoz/signoz` bundles
  everything except collector + ClickHouse. Compose has 3 services total
  (signoz + signoz-otel-collector + clickhouse). Simplest scope.
- (b) **External alertmanager, 3-service final layout** — unified arch
  still requires separate alertmanager. Compose has 4 services. Larger scope.
- (c) **Optional alertmanager via profile** — `signoz/signoz` runs without
  alerts by default, alertmanager opt-in via compose profile. Forge ships
  the default (no alerts) for dev-environment.

### Resolution

- **Decision**: Option (a) extended — embedded sqlite, **4 long-running
  services + 2 init containers**. The unified `signoz/signoz:v0.125.1`
  bundles UI + query-service + alertmanager + sqlite app state at
  `/var/lib/signoz/signoz.db` (named volume `signoz-sqlite` mounted
  at `/var/lib/signoz/`). The proposal's "2-service vs 3-service"
  framing was too narrow : EV-1 surfaced four long-running services
  (`signoz`, `signoz-otel-collector`, `clickhouse`, `zookeeper`)
  plus two init containers (`init-clickhouse`,
  `signoz-telemetrystore-migrator`). The Zookeeper sub-service was not
  anticipated by the proposal and is documented as a first-class
  decision in **ADR-B8-SIG-007** rather than buried in ADR-001
  consequences (per the executor brief discipline).
- **ADR**: see `design.md` **ADR-B8-SIG-001** (components inventory +
  sqlite) and **ADR-B8-SIG-007** (zookeeper sub-service).
- **Evidence**: `design.md` § Evidence Source Notes EV-1
  (`https://raw.githubusercontent.com/SigNoz/signoz/v0.125.1/deploy/docker/docker-compose.yaml`,
  fetched 2026-05-26) + EV-3 (`https://signoz.io/docs/install/docker/`).
  `SIGNOZ_SQLSTORE_SQLITE_PATH=/var/lib/signoz/signoz.db` is the
  canonical sqlite location per the upstream env-var.
- **Rationale**: Upstream Compose is the canonical source of truth ;
  Forge inherits the four-long-running-services + two-init-containers
  layout verbatim. Adopter persistence handled by named volumes
  (`signoz-sqlite`, `signoz-clickhouse-data`, `signoz-zookeeper-data`).

---

## Q-002: ClickHouse version pin under unified SigNoz architecture

- **Status**: answered (ADR-B8-SIG-002)
- **Raised in**: `.forge/changes/b8-signoz-unified/proposal.md` § Risk #1
- **Raised on**: 2026-05-26
- **Raised by**: maintainer (b8-signoz-unified propose pass)
- **Resolved on**: 2026-05-26 (`/forge:design`)
- **Resolved by**: Atlas (Infrastructure Architect)

### Question

Does `signoz/signoz:v0.125.1` require ClickHouse 24.x (current pin in
the 3-service arch), 25.x, or accept either? Three resolution options :

- (a) **Retain ClickHouse 24.x** — minimal disruption, if compatible.
  No data-volume migration concern for adopters.
- (b) **Bump ClickHouse 24 → 25** — required by SigNoz unified.
  Adopters with persistent ClickHouse data may need migration tooling.
  Declare "fresh-start only" for dev environments (acceptable per
  proposal scope).
- (c) **Pin ClickHouse to the exact version embedded in the upstream
  SigNoz compose** — track upstream verbatim, no independent decision.

### Resolution

- **Decision**: Option (c) — **track upstream verbatim**.
  `clickhouse/clickhouse-server:25.5.6` is the pin shipped by SigNoz
  upstream at `v0.125.1`. ClickHouse 24 → 25 is a major upstream jump ;
  SigNoz upstream owns the compatibility certification, Forge inherits
  the upstream-certified pair without independent re-certification.
  Posture for data-volume migration : **fresh-start only for dev
  environments** (prod adopters were already on rotted pins per the
  proposal Scope Out).
- **ADR**: see `design.md` **ADR-B8-SIG-002**.
- **Evidence**: `design.md` § Evidence Source Notes EV-1 (upstream
  Compose image pin) + EV-5 (`docker manifest inspect
  clickhouse/clickhouse-server:25.5.6` exit 0 — amd64
  sha256:5dcbe5f00521c32f4db29a9e804366ea34544be92b85b075d05b4f1572fef83f
  + arm64
  sha256:03c712ef372eb30e5fdefca184b0ff54ff5bea5456638ea349f42fbfcd4043f9,
  verified 2026-05-26).
- **Rationale**: Standard ships `versions.clickhouse: "25.5.6"` (new
  key, additive within the v1.2.0 → v2.0.0 BREAKING envelope — the
  BREAKING jump is driven by the REMOVE-set, not this additive entry).
  Cadence : `pin_review_cadence.clickhouse: "P30D"` tracks SigNoz's
  upstream cadence.

---

## Q-003: OPAMP wiring requirement under unified arch

- **Status**: answered (ADR-B8-SIG-003)
- **Raised in**: `.forge/changes/b8-signoz-unified/proposal.md` § Solution + § Risk #4
- **Raised on**: 2026-05-26
- **Raised by**: maintainer (b8-signoz-unified propose pass)
- **Resolved on**: 2026-05-26 (`/forge:design`)
- **Resolved by**: Atlas (Infrastructure Architect)

### Question

Does unified `signoz/signoz:v0.125.1` require explicit OPAMP server
stub for collector self-management, or does it expose OPAMP natively?
Three options :

- (a) **Native OPAMP on `signoz/signoz`** — no separate service needed.
  Collector dials `signoz` directly. Cleanest scope.
- (b) **Separate OPAMP server stub** — adds a service to the compose.
  Larger scope ; document the new service in `infra/CLAUDE.md.tmpl`.
- (c) **OPAMP disabled in dev compose, opt-in for prod** — ship the
  dev compose without OPAMP, prod overlays enable it. Defers complexity
  to a future B.8.x change.

### Resolution

- **Decision**: Option (c) — **OPAMP disabled in dev Compose, deferred
  to a follow-up B.8.x change for prod K8s overlays**. The pinned-tag
  Compose at `v0.125.1` contains **zero** `OPAMP_*` env vars ; the
  collector is configured statically via
  `SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_DSN`,
  `SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_CLUSTER`, and
  `SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_REPLICATION`. Mirroring upstream
  means OPAMP-off by default — Forge does not introduce wiring that
  upstream itself chose not to ship.
- **ADR**: see `design.md` **ADR-B8-SIG-003**.
- **Evidence**: `design.md` § Evidence Source Notes EV-1 (absence of
  `OPAMP_*` env vars in the pinned Compose — verbatim review of the
  v0.125.1 Compose YAML 2026-05-26).
- **Rationale**: OPAMP solves a non-problem at dev scale (single
  collector). The "no OPAMP in dev, opt-in for prod" posture is
  documented in `infra/CLAUDE.md.tmpl` H2 section pointing at upstream
  docs for the prod overlay path. Future OPAMP wiring for prod K8s
  overlays gets its own change-id and ADR.

---

## Q-004: UI port mapping — `:3301` preserved or `:8080` direct

- **Status**: answered (ADR-B8-SIG-004)
- **Raised in**: `.forge/changes/b8-signoz-unified/proposal.md` § Risk #3
- **Raised on**: 2026-05-26
- **Raised by**: maintainer (b8-signoz-unified propose pass)
- **Resolved on**: 2026-05-26 (`/forge:design`)
- **Resolved by**: Atlas (Infrastructure Architect)

### Question

The 3-service arch exposed SigNoz UI on host `:3301`. The unified
`signoz/signoz:v0.125.1` upstream Compose example exposes container `:8080`.
The forge example backend at `examples/forge-fsm-example/backend/`
already binds host `:8080`. Three resolution options :

- (a) **Env-var indirection** — `SIGNOZ_UI_PORT` env-var defaulting to
  `:3301`, mapped to container `:8080`. Preserves adopter muscle memory
  from the 3-service arch ; backend stays on `:8080`. Cheapest for
  adopters.
- (b) **Shift backend example port** — backend moves to `:8081`,
  SigNoz UI binds host `:8080` (upstream-aligned). Cleaner upstream
  alignment ; breaks adopter muscle memory + example documentation.
- (c) **Document the conflict, leave to adopter** — ship without a port
  override, document in `infra/CLAUDE.md.tmpl` that adopters with the
  example backend must remap one of the two services.

### Resolution

- **Decision**: Option (a) — **env-var indirection**. Canonical Compose
  declares `ports: ["${SIGNOZ_UI_PORT:-3301}:8080"]` on `fsm-signoz`.
  Host port `:3301` preserved as the Forge default (adopter UX
  continuity from the 3-service arch — `Taskfile.yml.tmpl`'s
  `task observe` continues to open `http://localhost:3301`). Container
  port unchanged at `:8080` (the SigNoz UI's native port, healthcheck
  target). Backend example at `:8080` unaffected.
- **ADR**: see `design.md` **ADR-B8-SIG-004**.
- **Evidence**: `design.md` § Evidence Source Notes EV-1 (upstream
  Compose maps host `:8080` to container `:8080`) + repo grep
  (backend example binds host `:8080`).
- **Rationale**: Env-var indirection follows the existing Forge
  `*_PORT` pattern in `templates/.../infra/.env.tmpl`. Upstream
  alignment (`:8080:8080`) is preserved as an opt-in via
  `SIGNOZ_UI_PORT=8080`. The divergence from SigNoz upstream docs is
  documented in `infra/CLAUDE.md.tmpl` H2 section (FR-B8-SIG-H-001).

---

## Q-005: `pin_review_cadence:` schema location in observability.yaml

- **Status**: answered (ADR-B8-SIG-005)
- **Raised in**: `.forge/changes/b8-signoz-unified/proposal.md` § Solution #3
- **Raised on**: 2026-05-26
- **Raised by**: maintainer (b8-signoz-unified propose pass)
- **Resolved on**: 2026-05-26 (`/forge:design`)
- **Resolved by**: Atlas (Infrastructure Architect)

### Question

The new `pin_review_cadence:` field needs a schema location :

- (a) **Top-level field on `observability.yaml`** — sibling to `versions:`
  and `last_reviewed:`. Mirrors `last_reviewed`/`expires_at` placement.
  Cleanest read.
- (b) **Nested under `versions:`** — e.g.
  `versions: { signoz: { pin: "0.125.1", review_cadence: "30d" } }`.
  Per-component co-location ; richer schema.
- (c) **Separate top-level field per component** — e.g.
  `signoz_pin_review_cadence: "30d"`. Verbose, no consolidation benefit.

### Resolution

- **Decision**: Option (a) — **top-level flat map, sibling to
  `versions:` and `last_reviewed:`**. Keys mirror `versions:` keys.
  Values use **ISO 8601 duration strings** (`P30D`, `P12M`) — a
  design-phase tightening over the proposal/specs informal `"30d"` /
  `"12mo"` notation, chosen for forward-compat with any future J.x
  enforcement layer that may parse and compare durations against
  `last_reviewed:`. Validator behaviour at v2.0.0 is **informational-
  only** ; enforcement is deferred to a follow-up J.x change.
- **ADR**: see `design.md` **ADR-B8-SIG-005**.
- **Schema impact**: **none** — `standard.schema.json` declares
  `additionalProperties: true` at root per **ADR-J7-004** in
  `j7-validate-standards-yaml/design.md` lines 152-168 (the
  proposal/specs cite "ADR-J7-008" but the actual schema-relaxation
  ADR is **ADR-J7-004** ; the WAIVER block at `/forge:implement`
  cites the corrected ADR-J7-004 ID). New top-level fields are
  accepted without schema edits.
- **Rationale**: Smallest schema surface. Option (b) would refactor
  `versions:` from scalar-map to object-map, breaking every existing
  reader (`b8-coroot.test.sh` L1 grep, `t5-otel-stack` reads,
  `bin/forge-snapshot.sh` `yq` extractor) — trio coupling violated.
  Option (c) verbose, no consolidation benefit. Final shape ships
  six keys : `signoz: "P30D"`, `signoz_otel_collector: "P30D"`,
  `clickhouse: "P30D"`, `signoz_zookeeper: "P12M"`, `beyla: "P12M"`,
  `coroot: "P12M"`.

---

## Q-006: SigNoz Inc jurisdiction + K3-RULE-* impact

- **Status**: answered (ADR-B8-SIG-006)
- **Raised in**: `.forge/changes/b8-signoz-unified/proposal.md` § Solution #7
- **Raised on**: 2026-05-26
- **Raised by**: maintainer (b8-signoz-unified propose pass)
- **Resolved on**: 2026-05-26 (`/forge:design`)
- **Resolved by**: Demeter (Data Steward EU)

### Question

SigNoz Inc publisher jurisdiction and CE license posture for Demeter
K3-RULE classification :

- What jurisdiction is SigNoz Inc incorporated under? (US? India? other?)
- Does the CE binary (Apache-2.0 / MIT / other OSS license) route any
  data to SigNoz Inc infrastructure (telemetry phone-home)?
- Does SigNoz Cloud (hosted SaaS) jurisdiction posture propagate to CE
  adopters?

Four possible outcomes (mirror Q-004 of `b8-coroot-rehost`) :

- (a) **T1/T2 OK, T3 candidate-substitution flag** — CE OSS self-host,
  no phone-home → safe for T1/T2 ; T3 flags candidate-substitution
  without forbidding. Likely outcome if SigNoz CE matches Coroot CE
  posture.
- (b) **T1/T2 OK, T3 introduces new K3-RULE-EXT-NNN** — formalise the
  flag as an explicit Demeter rule.
- (c) **All tiers OK** — CE evidence so strong even T3 accepts ; no
  new rule.
- (d) **All tiers forbidden** — CE forbidden across all tiers ; pivot
  scope to substitute-candidate exercise. Significant scope creep.

### Resolution

- **Decision**: Option (a) — **T1/T2 OK posture, T3 candidate-
  substitution flag in `observability.yaml::rationale`, no new K.3
  rule in this sub-change**. Mirrors ADR-B8-COR-004 precedent for
  Coroot Inc (US-incorporated, Apache-2.0 CE, no upstream phone-home
  ; T1/T2 OK ; T3 candidate-substitution flag).
- **ADR**: see `design.md` **ADR-B8-SIG-006**.
- **Evidence**: `design.md` § Evidence Source Notes EV-4 (three
  independent sources) — SigNoz Terms of Service + Crunchbase +
  CBInsights, all confirming **SigNoz Inc is incorporated in
  Delaware (US)** with HQ at 2261 Market Street #4496, San Francisco,
  CA 94114, and Indian engineering presence. Fetched 2026-05-26.
- **Rationale**: SigNoz CE is open-source ; the `signoz/signoz:v0.125.1`
  binary runs entirely on adopter infrastructure (SigNoz Cloud is a
  separate hosted SaaS, out of scope per proposal Scope Out).
  K3-RULE-001 is a publisher-jurisdiction + data-plane rule (per
  ADR-B8-COR-004 narrow interpretation), not a pure publisher-
  jurisdiction rule ; CE self-host with no data-plane US-routing
  passes T1/T2. Trio coupling enforcement (NFR-B8-SIG-011) forbids
  touching K.3 standards from a B.8.8 sub-change — option (b) would
  escalate to a K.3 amendment outside scope. **No edit** to
  `data-stewardship-rules.md`, `forbidden-components-rules.md`, or
  `cloud-act-publishers.yml`. The `observability.yaml::rationale`
  block gains the standard "SigNoz Inc Delaware-incorporated / CE
  self-host / T1-T2 OK / T3 flag" sentence pair at `/forge:implement`.

---

## Q-007: SigNoz CE usage-beacon opt-out — config-file mount deferred

- **Status**: answered (option a — doc-qualified ; config-mount deferred to future B.8.x leg)
- **Raised in**: post-review Aegis MEDIUM finding (FIX 4)
- **Raised on**: 2026-05-27
- **Raised by**: Aegis (Security Auditor) + Atlas (fix pass)
- **Resolved on**: 2026-05-27 (`/forge:review` fix pass)
- **Resolved by**: Atlas (Infrastructure Architect)

### Question

The unified `signoz/signoz:v0.125.1` image ships an anonymous usage beacon
(`statsreporter`) that is **ON by default**. The dev compose previously
implied a no-phone-home posture (overstated for T3). How should Forge ship
the opt-out so T3 adopters are not silently phoning home?

### Evidence (Article III.4 — fetched live 2026-05-27)

- Upstream v0.125.1 compose
  (`https://raw.githubusercontent.com/SigNoz/signoz/v0.125.1/deploy/docker/docker-compose.yaml`)
  sets **NO telemetry opt-out env var** on the `signoz` service.
- SigNoz telemetry docs (`https://signoz.io/docs/telemetry/`) : the current
  opt-out is the **config-file key `statsreporter.enabled: false`** (defaults
  `true`). The legacy `TELEMETRY_ENABLED` env var **was removed in SigNoz
  versions > 0.87.0** — it is a **no-op on v0.125.1** (would be a fabricated
  env if added).
- SigNoz config example
  (`https://github.com/SigNoz/signoz/blob/main/conf/example.yaml`) : the
  `statsreporter:` block lives in a mounted `config.yaml`.

### Options

- (a) **Doc-qualify only (this change)** — qualify the standard rationale +
  `infra/CLAUDE.md.tmpl` so the claim is accurate ("beacon ON by default ; T3
  adopters MUST disable via `statsreporter.enabled: false`") and defer the
  config-file mount. Smallest scope, honest.
- (b) **Ship a mounted `signoz` `config.yaml`** with `statsreporter.enabled:
  false` baked in — requires a new template file + a 7th-ish mirror surface +
  collector-style config-mount plumbing. Larger scope.

### Resolution (this change — option a)

- **Decision**: Option (a). NO guessed env var added (`TELEMETRY_ENABLED` is a
  no-op on v0.125.1 per the evidence). The standard rationale +
  `infra/CLAUDE.md.tmpl` jurisdiction note are qualified to state the beacon is
  ON by default and that T3 adopters MUST disable it via the `statsreporter`
  config key. The config-file mount (option b) is **deferred** — a future B.8.x
  leg may ship a mounted `signoz` `config.yaml` with the beacon disabled by
  default. Honesty over a fabricated env (executor brief FIX 4 mandate).
