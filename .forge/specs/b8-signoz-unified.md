# Spec: b8-signoz-unified

<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, SigNoz leg). -->
<!-- Source change : `.forge/changes/b8-signoz-unified/` (archived 2026-05-28). -->
<!-- Trio sibling 2 of the `b8-observability-rearch` trio (pilot `b8-coroot-rehost` archived 2026-05-25 ; sibling 3 `b8-obi-refresh` deferred). -->
<!-- Predecessor : `.forge/specs/otel-stack.md` ADR-OTEL-002 amended 2026-05-25 by b8-coroot-rehost ; this change is the breaking 2.0.0 follow-up that supersedes the SigNoz 3-service architecture inherited from b1-delivery. -->

**Namespace** : `FR-B8-SIG-*` / `NFR-B8-SIG-*` / `ADR-B8-SIG-*`.
**Constitution** : v1.1.0, unchanged (no Article XII amendment ;
breaking versions surgery is internal to the `observability.yaml`
standard envelope and uses the WAIVER block + `ARCH-CHANGE`
REVIEW.md flag mechanism declared by `standards-lifecycle.md` §
Bumps).
**Standard ratified** : `.forge/standards/observability.yaml`
v2.0.0 (MAJOR breaking bump — versions surgery + new top-level
`pin_review_cadence:` ISO 8601 map + WAIVER + `breaking_change:
true`).
**Templates** : `.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl`
(canonical) + 5 mirror copies (cli-bundle .tmpl + example-side .tmpl
+ cli-bundle example .tmpl + rendered example + cli-bundle rendered
example).
**Harness** : `.forge/scripts/tests/b8-signoz.test.sh` (17 L1 tests
+ 3 snapshot tests + 6 L2 opt-in via `FORGE_B8_SIGNOZ_DOCKER=1` ;
total 26/26 GREEN).

---

## Source Documents — verify-then-pin pass (B.8.8 trio sibling 2)

Verify-then-pin executed in-session 2026-05-26 by the main thread,
before any spec text was committed. The transcripts are captured
verbatim in `.forge/changes/b8-signoz-unified/evidence.md` § 1 and
referenced here only by anchor.

| Field                                | Value                                                                                                                                                |
|--------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**                         | `docs/new-archetypes-plan.md` §4.2 B.8.8 (observability rearch) + §0.5 (T5.3.2 abandoned rationale) + §0.7 (trio scope)                              |
| **Originating failure**              | `task validate dev-up-matrix` RED known-issue on v0.4.0-rc.2 and v0.4.0-rc.3 (rotted 3-service SigNoz image pins on Docker Hub)                       |
| **Verify-then-pin / target unified** | `docker manifest inspect signoz/signoz:v0.125.1` ✅ multi-arch (amd64 sha256:e56541a2770632c8630c1bd32b6b57c43a8cfdcdfec85018eae410313dc70613 ; arm64 sha256:f2e0ce661687e0dcab16df8dc7e1dc3c7041d7c41846b0274bb38ac68b509419) — `evidence.md` § 1.1 |
| **Verify-then-pin / collector**      | `docker manifest inspect signoz/signoz-otel-collector:v0.144.4` ✅ multi-arch (amd64 sha256:9b2cc1a07772a703ec03f098130fca9baf097a0d24f18b2357cc3b52855a1a8d ; arm64 sha256:42727e4be83e85257f4d4d336d7c2a63c25a7d25e08d6be8c69aa521efff7950) — `evidence.md` § 1.2 |
| **Verify-then-pin / clickhouse**     | `docker manifest inspect clickhouse/clickhouse-server:25.5.6` ✅ multi-arch (ADR-B8-SIG-002 — 24→25 bump)                                              |
| **Verify-then-pin / zookeeper**      | `docker manifest inspect signoz/zookeeper:3.7.1` ✅ multi-arch (ADR-B8-SIG-007 — replication coordinator)                                              |
| **Tag convention (verified)**        | **v-prefix mandatory** on both `signoz/signoz` and `signoz/signoz-otel-collector` — opposite of `coroot/coroot` and `grafana/beyla`. Documented inline. |
| **Rotted 3-service pins**            | `signoz/frontend:0.55.1`, `signoz/query-service:0.55.1` pruned from Docker Hub (last published `0.76.3` also pruned per `docs/new-archetypes-plan.md` §0.5) — `evidence.md` § 1.5 |
| **Standards lifecycle owner**        | `.forge/standards/global/standards-lifecycle.md` v1.1.0 (Article XII) — breaking bump path with WAIVER block per `§ Bumps`                          |
| **REVIEW ledger**                    | `.forge/standards/REVIEW.md` 2026-05-26 ARCH-CHANGE row (new flag introduced by this change, FR-B8-SIG-H-006 precedent)                              |
| **Harness frame**                    | `_helpers.sh` + `--level` parsing pattern from `b8-coroot.test.sh` (b8-coroot-rehost 2026-05-25 / archived v0.4.0-rc.3)                              |
| **Snapshot tarball owner**           | `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` regenerated via `bin/forge-snapshot.sh` (SOURCE_DATE_EPOCH-deterministic, ≤ 700 KiB NFR ceiling bumped from 640 KiB per ADR-B8-SIG-008 + WAIVER)                 |
| **Trio sibling 1 (archived)**        | `b8-coroot-rehost` — established versions field, mirror sync, L2 manifest-pull pattern, REVIEW.md ledger discipline                                  |
| **Trio sibling 3 (not yet)**         | `b8-obi-refresh` — Beyla 2.0.1 → 3.15.0 major bump + capabilities Linux review + Aegis re-audit                                                     |

---

## ADDED Requirements

### Functional Requirements

#### Cluster A — Docker Compose rewrite (host-side scaffold) — FR-B8-SIG-A-001 → A-012

##### FR-B8-SIG-A-001 — Canonical compose template carries the unified pin

`.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl`
MUST declare a service whose `image:` field equals exactly
`signoz/signoz:v0.125.1`. The v-prefix is mandatory per the
verify-then-pin evidence (Source Documents, `evidence.md` § 1.1 + § 1.4).

##### FR-B8-SIG-A-002 — Canonical compose template carries the unified collector pin

The same template MUST declare a service whose `image:` field equals
exactly `signoz/signoz-otel-collector:v0.144.4`. The v-prefix is
mandatory per `evidence.md` § 1.2 + § 1.4.

##### FR-B8-SIG-A-003 — Old 3-service pins MUST be absent

The canonical template MUST NOT contain any of the following
substrings (substring grep on the full file, excluding the audit
comment block from FR-B8-SIG-A-010) : `signoz/frontend`,
`signoz/query-service`, `otel/opentelemetry-collector-contrib`,
`:0.55.1` (the rotted-pin version anchor).

##### FR-B8-SIG-A-004 — ClickHouse retained, version pinned

The template MUST continue to declare a ClickHouse service (storage
substrate retained from the 3-service architecture). The pinned
ClickHouse image version is `clickhouse/clickhouse-server:25.5.6`
per ADR-B8-SIG-002 (24→25 bump tracking upstream SigNoz unified
compose).

##### FR-B8-SIG-A-005 — App state location

The unified `signoz/signoz:v0.125.1` image embeds sqlite app state
(replacing the 3-service external Postgres) ; the template MUST
mount a named volume for persistence and MUST declare the volume in
the `volumes:` block per ADR-B8-SIG-001.

##### FR-B8-SIG-A-006 — OPAMP wiring

Per ADR-B8-SIG-003 (Q-003 resolved), OPAMP is **OFF** in dev
compose. The collector receives static config via
`SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_*` env-vars, mirroring upstream
defaults. No separate OPAMP server stub is shipped.

##### FR-B8-SIG-A-007 — UI port mapping

Per ADR-B8-SIG-004 (Q-004 resolved), the SigNoz UI service host port
is `${SIGNOZ_UI_PORT:-3301}` → container `:8080`. The
env-var-indirect form preserves the `:3301` adopter compat default
while exposing the SigNoz upstream container port.

##### FR-B8-SIG-A-008 — OTLP ingest ports MUST be exposed on the collector

The `signoz/signoz-otel-collector` service MUST expose the OTLP
ingress ports `4317` (gRPC) and `4318` (HTTP) on the host,
preserving the FR-IN-009 contract from the full-stack-monorepo spec.

##### FR-B8-SIG-A-009 — `fsm-dev` Docker network membership

Every unified-arch service introduced or retained by this change MUST
join the existing `fsm-dev` Docker network defined elsewhere in the
compose file (preserves FR-IN-007 network-isolation invariant from
the full-stack-monorepo spec).

##### FR-B8-SIG-A-010 — Audit comment block

The canonical template MUST gain (or preserve, if a prior block is
present) a YAML comment block immediately above the SigNoz services
documenting the 3-svc → unified migration, the verify-then-pin
lesson, and the v-prefix convention as opposite of coroot/beyla.

##### FR-B8-SIG-A-011 — Healthchecks + restart policy preserved

Every SigNoz service in the unified arch MUST declare a `healthcheck:`
block and `restart: unless-stopped`, preserving the FR-IN-008
contract from the full-stack-monorepo spec (b1-delivery 2026-04-29).

##### FR-B8-SIG-A-012 — `depends_on` chain coherent

The compose MUST express a `depends_on:` chain such that the
collector service waits for the unified `signoz/signoz` service to
be `service_healthy` (or equivalent), and the unified service waits
for ClickHouse to be `service_healthy` ; the `fsm-signoz-zookeeper`
service is a peer dependency of ClickHouse per ADR-B8-SIG-007.

#### Cluster B — `observability.yaml` v2.0.0 BREAKING bump — FR-B8-SIG-B-001 → B-010

##### FR-B8-SIG-B-001 — Version field BREAKING bump

`.forge/standards/observability.yaml::version` MUST move from
`"1.2.0"` to `"2.0.0"`. The major bump signals a breaking
versions-surgery (REMOVE legacy `signoz_frontend` /
`signoz_query_service` / `otel_collector_contrib` keys ; ADD
unified `signoz` + `signoz_otel_collector` + `clickhouse` +
`signoz_zookeeper`). The bump is NOT additive.

##### FR-B8-SIG-B-002 — `versions.signoz` field ADDED

The standard MUST declare a new key `versions.signoz: "v0.125.1"`.
The value MUST carry the v-prefix per `evidence.md` § 1.4. An
adjacent YAML comment MUST document the v-prefix convention as
opposite of `versions.coroot` / `versions.beyla`.

##### FR-B8-SIG-B-003 — `versions.signoz_otel_collector` field ADDED

The standard MUST declare a new key
`versions.signoz_otel_collector: "v0.144.4"`. v-prefix mandatory
per `evidence.md` § 1.4.

##### FR-B8-SIG-B-004 — Versions REMOVED (breaking, defensive)

The standard MUST NOT carry any of the following keys after the
bump : `versions.signoz_frontend`, `versions.signoz_query_service`,
`versions.otel_collector_contrib`. (v1.2.0 did NOT carry these keys
; this FR is defensive against accidental re-introduction during
the bump.)

##### FR-B8-SIG-B-005 — New top-level field `pin_review_cadence:` ADDED

The standard MUST declare a new top-level map field
`pin_review_cadence:` with at minimum the following keys (ISO 8601
durations per ADR-B8-SIG-005 resolution) :

- `signoz: "P30D"`
- `signoz_otel_collector: "P30D"`
- `beyla: "P12M"`
- `coroot: "P12M"`

##### FR-B8-SIG-B-006 — Cadence-enforcement semantics

`pin_review_cadence:<component>: "P30D"` is **informational-only**
(no blocking gate) at this change ; active enforcement (e.g. a
`forge-questions.sh`-style nag) is reserved for a future J.7-class
amendment. The field MUST be readable by
`validate-standards-yaml.sh` without raising schema errors per
ADR-J7-004 `additionalProperties: true` root posture.

##### FR-B8-SIG-B-007 — `last_reviewed` refreshed

`.forge/standards/observability.yaml::last_reviewed` MUST move from
`2026-05-25` (set by b8-coroot-rehost) to `2026-05-26`.

##### FR-B8-SIG-B-008 — `expires_at` refreshed

`.forge/standards/observability.yaml::expires_at` MUST move from
`2027-05-04` to `2027-05-26` (12-month forward window from the new
`last_reviewed`, preserving `expires_at > last_reviewed` per
FR-J7-021).

##### FR-B8-SIG-B-009 — WAIVER block in frontmatter

The standard frontmatter MUST gain a WAIVER comment block documenting
the breaking architectural shift, citing `standards-lifecycle.md`
§ Bumps + ADR-J7-004 schema-relaxation precedent, and naming
`b8-signoz-unified` as the originating change.

##### FR-B8-SIG-B-010 — `breaking_change: true` invariant marker

The standard frontmatter MUST carry an explicit
`breaking_change: true` field. The marker is the machine-readable
signal that the v1.x → v2.0.0 jump is NOT additive and that the
REVIEW.md row uses `ARCH-CHANGE`, not `Updated`.

#### Cluster C — Schema impact on `standard.schema.json` — FR-B8-SIG-C-001 → C-004

##### FR-B8-SIG-C-001 — `pin_review_cadence` field accepted by J.7 validator

`bin/validate-standards-yaml.sh .forge/standards/observability.yaml`
MUST exit 0 after the v2.0.0 bump. The `pin_review_cadence:` field
MUST NOT trigger an "unknown field" rejection (per ADR-J7-004
`additionalProperties: true` root posture — **no**
`standard.schema.json` edit required).

##### FR-B8-SIG-C-002 — `breaking_change` invariant accepted by J.7 validator

The same validator MUST exit 0 with `breaking_change: true`
declared in the standard. Tolerated via the
`additionalProperties: true` envelope posture (no schema edit).

##### FR-B8-SIG-C-003 — Schema bump bookkeeping

`standard.schema.json` is NOT touched by this change (resolution
"schema-tolerate" per ADR-B8-SIG-005). The decision is recorded in
`design.md` / ADR-B8-SIG-005.

##### FR-B8-SIG-C-004 — Backward-compat of the schema against sibling standards

Every other ratified standard (`transport.yaml`,
`state-management.yaml`, `orchestration.yaml`, `identity.yaml`,
`persistence.yaml`) MUST still validate cleanly under
`validate-standards-yaml.sh` after this change archives.

#### Cluster D — Snapshot regeneration + A.7 backward compat — FR-B8-SIG-D-001 → D-005

##### FR-B8-SIG-D-001 — Snapshot regenerated

`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` MUST be
regenerated via `bin/forge-snapshot.sh build full-stack-monorepo
1.0.0` with `SOURCE_DATE_EPOCH` set to a deterministic value. The
new tarball reflects the unified compose template.

##### FR-B8-SIG-D-002 — Snapshot determinism preserved

Re-running `SOURCE_DATE_EPOCH=<same-value> bin/forge-snapshot.sh
build full-stack-monorepo 1.0.0` twice in a row MUST produce
byte-identical tarballs.

##### FR-B8-SIG-D-003 — Cli-bundle snapshot mirror byte-identity

`cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
MUST be byte-identical to the canonical snapshot after `npm run
bundle`.

##### FR-B8-SIG-D-004 — A.7 forge-upgrade backward compat

After snapshot regen, `.forge/scripts/tests/a7.test.sh --level 1`
MUST stay GREEN with the historical 29/29 PASS count. The
forge-upgrade non-destructive 3-way merge invariant MUST survive
the v1.2.0 → v2.0.0 breaking standard bump.

##### FR-B8-SIG-D-005 — `upgrade_history` ledger ARCH-CHANGE row

When an adopter runs `forge upgrade` across the breaking bump, the
adopter-side `upgrade_history` ledger (per A.7 upgrade-policy
standard) MUST append a row carrying `breaking_change: true` and
naming `b8-signoz-unified` as the source change.

#### Cluster E — Harness `b8-signoz.test.sh` — FR-B8-SIG-E-001 → E-018

The harness MUST exist, be executable bash, use `set -uo pipefail`,
sport an audit comment block, declare `--level` parsing, source
`_helpers.sh`, follow the `b8-coroot.test.sh` shape, and ship
**17 L1 grep tests + 3 snapshot tests** covering all assertions in
clusters A through H (canonical compose pins, rotted-pin absence,
audit comment, standard version + new versions + `pin_review_cadence`
+ `last_reviewed` + WAIVER + `breaking_change`, REVIEW.md ARCH-CHANGE
row, `validate-standards-yaml.sh` exit 0, CHANGELOG entry, mirror
byte-identity, snapshot ceiling). 6 L2 tests are gated by
`FORGE_B8_SIGNOZ_DOCKER=1` (manifest-pull for the 4 unified pins +
compose-up healthy + rotted 3-svc pins denied).

Full FR-E test↔FR mapping preserved in
`.forge/changes/b8-signoz-unified/specs.md::Cluster E` (Article V
immutable).

#### Cluster F — CI integration (forge-ci.yml) — FR-B8-SIG-F-001 → F-003

##### FR-B8-SIG-F-001 — Harness registered in matrix

`.github/workflows/forge-ci.yml::harness` matrix MUST gain a new
entry registering `b8-signoz.test.sh --level 1` immediately after
the `b8-coroot.test.sh` entry.

##### FR-B8-SIG-F-002 — Line budget preserved

After registration, `.github/workflows/forge-ci.yml` MUST remain
≤ 300 lines (NFR-CI-002). Final count : 300/300 (budget exactly
filled).

##### FR-B8-SIG-F-003 — Matrix invocation level

The matrix entry MUST invoke the harness at `--level 1` only. L2
opt-in via `FORGE_B8_SIGNOZ_DOCKER=1` is permitted but out of scope
for this change.

#### Cluster G — 6-copy mirror sync — FR-B8-SIG-G-001 → G-005

The canonical .tmpl is the source of truth ; 5 additional mirror
copies (cli-bundle .tmpl + example-side .tmpl + cli-bundle example
.tmpl + rendered example + cli-bundle rendered example) MUST be
byte-identical after `npm run bundle`. A `find` invocation for
`docker-compose*.yml*` under the repo root MUST return the expected
6 mirror copies.

#### Cluster H — Documentation — FR-B8-SIG-H-001 → H-006

##### FR-B8-SIG-H-001 — `infra/CLAUDE.md.tmpl` SigNoz section updated

The H2 section "SigNoz unified architecture" MUST document the 6-svc
layout (4 long-running + 2 init), the UI port mapping decision
(ADR-B8-SIG-004), the fresh-start-only posture for ClickHouse
data-volume + sqlite app state, the OPAMP-off dev decision
(ADR-B8-SIG-003), the jurisdiction posture (ADR-B8-SIG-006), and
the v-prefix tag convention.

##### FR-B8-SIG-H-002 — `REVIEW.md` ledger entry with ARCH-CHANGE flag

`.forge/standards/REVIEW.md` MUST gain a new row with the
**`ARCH-CHANGE`** flag (NOT `Updated`) appended after the existing
latest entry per FR-J7-023 append-only invariant.

##### FR-B8-SIG-H-003 — CHANGELOG entry

`CHANGELOG.md` MUST gain a `### Fixed — SigNoz 3-service → unified
arch migration (B.8.8, b8-signoz-unified)` block under
`[Unreleased]` citing the `task validate dev-up-matrix` debloque,
the unified pins, the v2.0.0 BREAKING bump, ARCH-CHANGE ledger,
6-copy mirror sync, new harness, snapshot regen, A.7 preservation.

##### FR-B8-SIG-H-004 — Plan inventory updated

The `Inventaire .forge/changes/` table in
`docs/new-archetypes-plan.md` MUST gain a row marking
`b8-signoz-unified` as `archived` once the status flip lands.

##### FR-B8-SIG-H-005 — Roadmap status line

`.forge/product/roadmap.md` Phase 3 / T6 row MUST gain a "B.8.8
(SigNoz leg) Done <date>" entry once archived.

##### FR-B8-SIG-H-006 — `ARCH-CHANGE` ledger flag precedent declaration

`docs/new-archetypes-plan.md` (or governance-equivalent) MUST gain
a one-paragraph declaration that `ARCH-CHANGE` is the new REVIEW.md
ledger flag for breaking architectural shifts on a ratified
standard, distinct from `Updated` for version refreshes. This
change is the originating precedent.

#### Cluster I — Janus + Demeter deltas (jurisdiction-conditional) — FR-B8-SIG-I-001 → I-003

Per ADR-B8-SIG-006 (Q-006 resolved) : SigNoz Inc Delaware-incorporated
US ; CE self-host T1/T2 OK ; T3 candidate-substitution flag at
deployment-time Demeter pass (informational, not blocking) ; SigNoz
Cloud out of scope. No new K3-RULE-EXT added by this change ; no
`cloud-act-publishers.yml` entry added. K3-RULE classification
escalation is reserved for a future Demeter-owned change if
T1/T2/T3 posture shifts.

#### Cluster J — Forward-pointer to b8-obi-refresh (trio sibling 3) — FR-B8-SIG-J-001 → J-002

`.forge/standards/observability.yaml` v2.0.0 MUST carry a YAML
comment adjacent to `versions.beyla` reserving the OBI Beyla 2.0.1
→ 3.15.0 major bump for the upcoming `b8-obi-refresh` sub-change.
This change MUST NOT modify `versions.beyla` itself ; the comment
is documentation-only. `REVIEW.md` MAY carry a parenthetical
pointer in the ARCH-CHANGE row noting that the Beyla pin remains
at `2.0.1` pending trio sibling 3.

### Non-Functional Requirements

##### NFR-B8-SIG-001 — Snapshot size budget

`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` snapshot
ceiling bumped from 640 KiB → **700 KiB** per ADR-B8-SIG-008 +
WAIVER (the unified-arch compose rewrite + init containers + 4
unified pins push the gzipped tarball past the 640 KiB legacy
ceiling). Measurement at archive time stays within the new 700 KiB
ceiling.

##### NFR-B8-SIG-002 — `forge-ci.yml` line count budget

`.github/workflows/forge-ci.yml` MUST remain ≤ 300 lines (NFR-CI-002).
Final : 300/300.

##### NFR-B8-SIG-003 — L1 harness wall-clock budget

`bash .forge/scripts/tests/b8-signoz.test.sh --level 1` MUST complete
in ≤ 2 s on the maintainer's reference machine (apple M-series).

##### NFR-B8-SIG-004 — L2 harness opt-in semantics

L2 (`FORGE_B8_SIGNOZ_DOCKER=1`) MUST skip-pass when either the
env-var is unset OR `command -v docker` returns non-zero. L2
wall-clock budget : ≤ 180 s end-to-end.

##### NFR-B8-SIG-005 — `verify.sh` PASS preservation post-archive

`.forge/scripts/verify.sh` PASS count MUST NOT decrease after this
change is archived.

##### NFR-B8-SIG-006 — `constitution-linter.sh` PASS preservation post-archive

`.forge/scripts/constitution-linter.sh` OVERALL MUST remain PASS
after this change is archived. Existing harnesses MUST stay GREEN.

##### NFR-B8-SIG-007 — `task validate dev-up-matrix` GREEN end-to-end

After this change is archived, `task validate dev-up-matrix` MUST
exit 0 against `full-stack-monorepo / 1.0.0`. This NFR is the
explicit known-issue-debloque for v0.4.0-rc.2 / rc.3.

##### NFR-B8-SIG-008 — Deterministic snapshot via SOURCE_DATE_EPOCH

Snapshot regen MUST be deterministic ;
`SOURCE_DATE_EPOCH=<value> bin/forge-snapshot.sh` twice produces
byte-identical tarballs.

##### NFR-B8-SIG-009 — `pin_review_cadence` enforcement timing

The `pin_review_cadence:` field is informational-only at this
change ; active enforcement is deferred to a future J.7-class
amendment per ADR-B8-SIG-005.

##### NFR-B8-SIG-010 — A.7 forge-upgrade 29/29 PASS preserved

`a7.test.sh --level 1` MUST stay GREEN with the historical 29/29
PASS count.

##### NFR-B8-SIG-011 — Trio coupling tolerance (inherited from b8-coroot-rehost)

The standard `observability.yaml v2.0.0` shipped here MUST remain a
valid input for the upcoming `b8-obi-refresh` (additive Beyla 2.0.1
→ 3.15.0 bump). This change MUST NOT force the OBI sibling to
revert the cadence field nor the `breaking_change` marker.

##### NFR-B8-SIG-012 — Atomic revertability

The change MUST be revertable via a single `git revert <merge-sha>`
without leaving the 6 compose copies out-of-sync or the standard
frontmatter inconsistent with REVIEW.md.

---

## MODIFIED Requirements

> Grep-verified targets in `.forge/specs/full-stack-monorepo.md` —
> `FR-IN-008` and `FR-IN-012` are the canonical FRs that name the
> 3-service SigNoz architecture. Both updated in place in
> `full-stack-monorepo.md` at archive time with
> `<!-- Modified in b8-signoz-unified, 2026-05-28 -->` markers + the
> prior text preserved as commented `<!-- Previously: ... -->` per
> Article V audit trail.

### FR-IN-008 (MODIFIED in b8-signoz-unified)

Authoritative current text lives in `.forge/specs/full-stack-monorepo.md::FR-IN-008`.
The previous b1-delivery 2026-04-29 prose (three services
`fsm-signoz-clickhouse` / `fsm-signoz-query` / `fsm-signoz-frontend`
on `:3301`, healthcheck + restart + `signoz-clickhouse-data` volume
+ `task observe` URL hardcoded `http://localhost:3301`) is preserved
in the `<!-- Previously: ... -->` comment in
`full-stack-monorepo.md` per Article V.

The new prose ships the 2-or-3-service unified architecture, the
`${SIGNOZ_UI_PORT:-3301}` env-var-indirect host port (ADR-B8-SIG-004),
the coherent `depends_on` chain (FR-B8-SIG-A-012), the named-volume
posture for ClickHouse + sqlite app state (FR-B8-SIG-A-005), and the
parameterised `task observe` target.

### FR-IN-012 (MODIFIED in b8-signoz-unified)

Authoritative current text lives in `.forge/specs/full-stack-monorepo.md::FR-IN-012`.
The previous b1-delivery 2026-04-29 prose (3-service version-list :
`otel-collector` + `signoz-clickhouse` + `signoz-query-service` +
`signoz-frontend`) is preserved in the `<!-- Previously: ... -->`
comment in `full-stack-monorepo.md` per Article V.

The new prose records the unified-arch version-list (`signoz` +
`signoz-otel-collector` + `signoz-clickhouse`) and references
`versions.signoz` + `versions.signoz_otel_collector` in
`observability.yaml v2.0.0` as the authoritative source per
FR-B8-SIG-B-002 + FR-B8-SIG-B-003.

---

## Removed Requirements (b8-signoz-unified)

> Honest count : the only `signoz_*` keys in `observability.yaml`
> historically were referenced by `b1-delivery`'s companion text
> under `FR-IN-012` (standard prose), NOT as first-class
> `versions.*` map entries. `b8-coroot-rehost` (v1.2.0) shipped the
> standard with `versions.beyla` + `versions.coroot` only. The
> REMOVED entries below are therefore defensive — they prevent the
> v2.0.0 bump from accidentally re-introducing the legacy names —
> and they do NOT correspond to grep-locatable shipped FR IDs.

- ~~[FR-B8-SIG-REMOVED-001]~~ **DEPRECATED** in b8-signoz-unified,
  2026-05-28. Reason : SigNoz upstream architectural migration
  3-services → unified. The compose service names
  `fsm-signoz-clickhouse` (as the sole ClickHouse service alias),
  `fsm-signoz-query`, `fsm-signoz-frontend` in the canonical
  `docker-compose.dev.yml.tmpl` are removed. Replacement names :
  `fsm-signoz` + `fsm-signoz-otel-collector` (+ optional
  `fsm-signoz-clickhouse` as storage substrate).
- ~~[FR-B8-SIG-REMOVED-002]~~ **DEPRECATED** in b8-signoz-unified,
  2026-05-28. Reason : defensive — the legacy 3-service image pin
  literals (`signoz_frontend`, `signoz_query_service`,
  `otel_collector_contrib`) MUST NOT appear as `versions.*` map
  keys or in prose after the v2.0.0 bump.
- ~~[FR-B8-SIG-REMOVED-003]~~ **DEPRECATED** in b8-signoz-unified,
  2026-05-28. Reason : SigNoz upstream unified Compose exposes
  container `:8080`, which collides with the
  `examples/forge-fsm-example/backend/` default. The hardcoded
  `:3301` host port (FR-IN-008 previous + `task observe` URL) is
  parameterised per ADR-B8-SIG-004 to
  `${SIGNOZ_UI_PORT:-3301}` → `:8080`.

---

## ADRs (b8-signoz-unified design)

| ID                | Decision summary                                                                                                                                                                                                                   |
|-------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ADR-B8-SIG-001    | SigNoz unified embedded components inventory + sqlite app state → 2-or-3-service final layout : `signoz/signoz` embeds sqlite app state (no external Postgres) ; ClickHouse retained as storage substrate.                          |
| ADR-B8-SIG-002    | ClickHouse pinned to `clickhouse/clickhouse-server:25.5.6` (24→25 bump, tracking SigNoz upstream unified compose).                                                                                                                  |
| ADR-B8-SIG-003    | OPAMP **OFF** in dev compose ; static config via `SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_*` env-vars (no separate OPAMP server stub).                                                                                                     |
| ADR-B8-SIG-004    | UI port mapping `${SIGNOZ_UI_PORT:-3301}` → ctr `:8080` (env-var-indirect form preserves `:3301` adopter compat).                                                                                                                  |
| ADR-B8-SIG-005    | `pin_review_cadence:` top-level field, ISO 8601 durations (P30D / P12M), **schema-tolerate** via `additionalProperties: true` (ADR-J7-004) — no `standard.schema.json` edit. Enforcement informational-only at this change.        |
| ADR-B8-SIG-006    | SigNoz Inc Delaware US ; CE self-host T1/T2 OK ; T3 candidate-substitution flag at deployment-time Demeter pass (informational, not blocking) ; SigNoz Cloud out of scope. No new K3-RULE-EXT ; no `cloud-act-publishers.yml` entry. |
| ADR-B8-SIG-007    | `signoz/zookeeper:3.7.1` replication coordinator + 2 init containers (`init-clickhouse` + `fsm-signoz-telemetrystore-migrator` with `restart: on-failure`) — 6 services total (4 long-running + 2 init).                            |
| ADR-B8-SIG-008    | Snapshot ceiling bumped 640 KiB → **700 KiB** with WAIVER ; the unified-arch + init containers + 4 unified pins push gzipped tarball past the legacy 640 KiB ceiling.                                                                |

Full design rationale + Mermaid diagrams + Open Questions resolution :
`.forge/changes/b8-signoz-unified/design.md`.

---

## BDD Acceptance Criteria

Article II (BDD) applies because this change affects user-facing
adopter workflows : `forge init` scaffolding, `task dev:up`, `forge
upgrade`, `forge-demeter-scan.sh`, and the standards-validator
surface. 6 Gherkin scenarios `BDD-B8-SIG-001..006` preserved
verbatim in `.forge/changes/b8-signoz-unified/specs.md::BDD
Acceptance Criteria` (Article V immutable).

### BDD ↔ FR Mapping

| BDD ID              | FR / NFR IDs covered                                                                                          |
|---------------------|---------------------------------------------------------------------------------------------------------------|
| BDD-B8-SIG-001      | FR-B8-SIG-A-001, A-002, A-003, A-007, A-008, A-011, A-012                                                     |
| BDD-B8-SIG-002      | NFR-B8-SIG-007, FR-B8-SIG-A-003, FR-B8-SIG-G-001..G-005                                                       |
| BDD-B8-SIG-003      | FR-B8-SIG-D-004, D-005, NFR-B8-SIG-010                                                                        |
| BDD-B8-SIG-004      | FR-B8-SIG-B-001, B-005, B-009, B-010, C-001, C-002, H-002                                                     |
| BDD-B8-SIG-005      | FR-B8-SIG-I-001, I-002, I-003                                                                                 |
| BDD-B8-SIG-006      | FR-B8-SIG-E-001..E-015, NFR-B8-SIG-003, NFR-B8-SIG-004                                                        |

Every BDD scenario maps to ≥ 1 FR or NFR ID.

---

## Anti-Hallucination Pass

| FR cluster       | Testable ? | Ambiguous ?                                       | Constitution-compliant ? | External-dep claim ?                                                                  |
|------------------|------------|---------------------------------------------------|--------------------------|----------------------------------------------------------------------------------------|
| A (compose)      | YES — grep + L2 compose-up                          | None (Q-001..006 all resolved by archive) | Article III + VIII + IX  | `signoz/signoz:v0.125.1` + `signoz/signoz-otel-collector:v0.144.4` + `clickhouse/clickhouse-server:25.5.6` + `signoz/zookeeper:3.7.1` — all `docker manifest inspect` ✅ (evidence § 1)             |
| B (standard)     | YES — grep + frontmatter + H2                        | None                                       | Article III + IX + XII   | Same 4 pins (evidence § 1)                                                              |
| C (schema)       | YES — `validate-standards-yaml.sh` exit 0           | None                                       | Article III + XII        | None (ADR-J7-004 `additionalProperties: true` posture cited)                            |
| D (snapshot)     | YES — `a7.test.sh` 29/29 + byte-identity diff       | None                                       | Article III + V          | None                                                                                    |
| E (harness)      | YES — 17 L1 + 3 snapshot + 6 L2 ; each maps to FR    | None                                       | Article I + V            | L2 deps : `docker manifest inspect` + `docker compose up -d` (opt-in via env-var)       |
| F (CI)           | YES — `forge-ci.yml` line count + matrix grep       | None                                       | Article V                | None                                                                                    |
| G (mirror sync)  | YES — `diff -q` byte-identity across 6 copies        | None                                       | Article V                | None                                                                                    |
| H (docs)         | YES — file presence + H2 anchor + REVIEW.md regex   | None                                       | Article V                | None                                                                                    |
| I (jurisdiction) | YES — Demeter scan opt-in                            | None (ADR-B8-SIG-006 resolved)            | Article III + XII (K.3)  | SigNoz Inc Delaware US (CE self-host)                                                  |
| J (forward-ptr)  | YES — grep YAML comment                              | None                                       | Article V                | None                                                                                    |

No `[NEEDS CLARIFICATION:]` marker inline. 7 Q-NNN (Q-001..Q-007)
all resolved in `.forge/changes/b8-signoz-unified/open-questions.md`
before archive (status `answered` or `wontfix` ; Q-007 deferred to a
follow-up change per resolution prose, status `wontfix`).
Verify-then-pin pass executed pre-spec at 2026-05-26 (T5.3.2 lesson
institutionalised).

---

## Out of Scope (asserted negatively, mirrors proposal.md § Scope Out)

- **OBI / Beyla eBPF refresh** — owned by trio sibling 3
  `b8-obi-refresh` (Beyla 2.0.1 → 3.15.0 major bump).
  `versions.beyla` stays at `"2.0.1"` per FR-B8-SIG-J-001.
- **Grafana LGTM stack migration** — separate B.8.x decision.
- **Envoy Gateway migration** — owned by B.8.4.
- **DBOS migration** — owned by B.8.5.
- **Kong removal** — Kong stays at the 1.0.0 baseline.
- **`coroot` pin refresh or rearch** — owned by `b8-coroot-rehost`
  (archived 2026-05-25). `versions.coroot` stays at `"1.20.2"`.
- **`pin_review_cadence:` retrofit on K.3 or other standards** —
  future J.7-class amendment.
- **`signoz-ee` paid edition** — out of forge default.
- **SigNoz Cloud hosted variant** — out of scope.
- **Mobile-only archetype** — SigNoz is full-stack-monorepo only.
- **ClickHouse data-volume migration tooling** — fresh-start only
  for dev environments.
- **Constitution amendment** — no Article XII amendment in scope.

---

## Phase scope reminder

- **Trio sibling 1 (archived 2026-05-25)** : `b8-coroot-rehost` —
  host migration `docker.io/coroot/coroot:1.4.4` →
  `ghcr.io/coroot/coroot:1.20.2`. `observability.yaml` v1.1.0 →
  v1.2.0 additive.
- **Trio sibling 2 (this change, archived 2026-05-28)** :
  `b8-signoz-unified` — SigNoz 3-service → unified arch (6
  services). `observability.yaml` v1.2.0 → v2.0.0 **BREAKING**.
  ARCH-CHANGE ledger flag introduced. `task validate dev-up-matrix`
  RED known-issue débloqué.
- **Trio sibling 3 (deferred)** : `b8-obi-refresh` — Beyla 2.0.1 →
  3.15.0 major bump + capabilities Linux review + Aegis re-audit.
