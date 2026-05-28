# Specifications: b8-signoz-unified
<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, SigNoz leg) -->
<!-- Trio context: docs/new-archetypes-plan.md §0.7 — sibling 2 of the b8-observability-rearch trio -->
<!-- Pilot precedent: .forge/changes/b8-coroot-rehost/ (archived v0.4.0-rc.3) -->

**Namespace** : `FR-B8-SIG-*` / `NFR-B8-SIG-*` / `ADR-B8-SIG-*`.
**Constitution** : v1.1.0, unchanged. **Article II** : BDD scenarios
documented for the user-facing surfaces of the adopter workflow (`forge
init` + `task dev:up` + `forge upgrade` + standards validator + Demeter
scan) even though the SigNoz UI itself is consumed by operators, not
application end-users — mirroring the `b1-1-dev-up-matrix-fixes` and
`b8-coroot-rehost` precedents.

---

## Source Documents — verify-then-pin pass (B.8.8 trio sibling 2, T5.3.2 lesson applied)

Verify-then-pin executed in-session **2026-05-26** by the main thread,
before any spec text was committed. The transcripts are captured
verbatim in `evidence.md` § 1 and reproduced here only by reference, to
keep the spec normative.

| Field                                | Value                                                                                                                                                |
|--------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**                         | `docs/new-archetypes-plan.md` §4.2 B.8.8 (observability rearch) + §0.5 (T5.3.2 abandoned rationale) + §0.7 (trio scope)                              |
| **Trio research note**               | `.forge/_memory/b8-observability-rearch-exploration.md` §5.2 (SigNoz sub-change scope)                                                              |
| **Originating failure**              | `task validate dev-up-matrix` RED known-issue on v0.4.0-rc.2 and v0.4.0-rc.3 (rotted 3-service SigNoz image pins on Docker Hub)                       |
| **Verify-then-pin / target unified** | `docker manifest inspect signoz/signoz:v0.125.1` ✅ multi-arch (amd64 sha256:e56541a2770632c8630c1bd32b6b57c43a8cfdcdfec85018eae410313dc70613 ; arm64 sha256:f2e0ce661687e0dcab16df8dc7e1dc3c7041d7c41846b0274bb38ac68b509419) — `evidence.md` § 1.1 |
| **Verify-then-pin / collector**      | `docker manifest inspect signoz/signoz-otel-collector:v0.144.4` ✅ multi-arch (amd64 sha256:9b2cc1a07772a703ec03f098130fca9baf097a0d24f18b2357cc3b52855a1a8d ; arm64 sha256:42727e4be83e85257f4d4d336d7c2a63c25a7d25e08d6be8c69aa521efff7950) — `evidence.md` § 1.2 |
| **Docker Hub tag listing**           | `signoz/signoz` → `v0.125.1` published 2026-05-20 ; `signoz/signoz-otel-collector` → `v0.144.4` published 2026-05-06 (both latest, ordering=last_updated) — `evidence.md` § 1.3 |
| **Tag convention (verified)**        | **v-prefix mandatory** on both `signoz/signoz` and `signoz/signoz-otel-collector` — opposite of `coroot/coroot` and `grafana/beyla`. Documented inline to prevent the `b8-coroot-rehost` ADR-B8-COR-001 inversion-at-impl pattern recurrence — `evidence.md` § 1.4 |
| **Rotted 3-service pins**            | `signoz/frontend:0.55.1`, `signoz/query-service:0.55.1` pruned from Docker Hub (last published `0.76.3` also pruned per `docs/new-archetypes-plan.md` §0.5) — `evidence.md` § 1.5 |
| **Current pins in standard**         | `.forge/standards/observability.yaml` v1.2.0 carries `versions.beyla: "2.0.1"` + `versions.coroot: "1.20.2"` ; the SigNoz 3-service pins (`signoz_frontend`, `signoz_query_service`, `otel_collector_contrib`) are NOT carried in the standard — they live in the docker-compose template only |
| **Canonical template**               | `.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl` (canonical) — file path confirmation deferred to `/forge:design` per Q-001 |
| **4-copy mirror inventory**          | Canonical + `cli/assets/.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl` + `examples/forge-fsm-example/infra/docker-compose.yml` (rendered) + `cli/assets/examples/forge-fsm-example/.../docker-compose.yml` (rendered cli-bundle mirror). Existence of the 4th copy + the example-side .tmpl variant pending `/forge:design` discovery (`[NEEDS CLARIFICATION: actual file-system inventory pending design-phase enumeration — Q-001]`). |
| **Sibling FR surface (canonical)**   | `.forge/specs/full-stack-monorepo.md::FR-IN-008` (3-service SigNoz compose) + `FR-IN-012` (standard `infra/observability-local.md` version-list of `signoz-clickhouse`, `signoz-query-service`, `signoz-frontend`) — the **MODIFIED/REMOVED** spec surface for this change. `FR-OTEL-*` in `.forge/specs/otel-stack.md` are scoped to OBI + Coroot + sampler, NOT to SigNoz services, so they remain untouched. |
| **Standards lifecycle owner**        | `.forge/standards/global/standards-lifecycle.md` v1.1.0 (Article XII) — breaking bump path with WAIVER block per `§ Bumps`                          |
| **REVIEW ledger**                    | `.forge/standards/REVIEW.md` (append-only per FR-T4-LC-005 / FR-J7-023) — `ARCH-CHANGE` flag introduced here, distinct from the established `Updated` flag |
| **Harness frame**                    | `_helpers.sh` + `--level` parsing pattern from `b8-coroot.test.sh` (b8-coroot-rehost 2026-05-25 / archived v0.4.0-rc.3)                              |
| **CI matrix budget**                 | `.github/workflows/forge-ci.yml` currently 297 lines post-b8-coroot-rehost ; NFR-CI-002 ≤ 300 → +3 line headroom (may require T5.3.3 ADR-T533-002-style compression — `[NEEDS CLARIFICATION: exact post-add line count pending `/forge:design` measurement — Q-001-adjacent]`) |
| **Snapshot tarball owner**           | `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` regenerated via `bin/forge-snapshot.sh` (SOURCE_DATE_EPOCH-deterministic, ≤ 600 KB NFR-OTEL-001 budget ; current ~520 KB)                 |
| **Release target**                   | `v0.4.0-rc.4` (debloques the `task validate dev-up-matrix` RED known-issue carried in rc.2 / rc.3)                                                  |
| **Trio sibling 1 (archived)**        | `b8-coroot-rehost` — established versions field, 4-copy mirror sync, L2 manifest-pull pattern, REVIEW.md ledger discipline                          |
| **Trio sibling 3 (not yet)**         | `b8-obi-refresh` — Beyla 2.0.1 → 3.15.0 major bump + capabilities Linux review + Aegis re-audit                                                     |

---

## ADDED Requirements

### Functional Requirements

#### Cluster A — Docker Compose rewrite (host-side scaffold) — FR-B8-SIG-A-001 → A-012

##### FR-B8-SIG-A-001 — Canonical compose template carries the unified pin

`.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl`
MUST declare a service whose `image:` field equals exactly
`signoz/signoz:v0.125.1`. The v-prefix is mandatory per the
verify-then-pin evidence (Source Documents, evidence.md § 1.1 + § 1.4).

##### FR-B8-SIG-A-002 — Canonical compose template carries the unified collector pin

The same template MUST declare a service whose `image:` field equals
exactly `signoz/signoz-otel-collector:v0.144.4`. The v-prefix is
mandatory per evidence.md § 1.2 + § 1.4.

##### FR-B8-SIG-A-003 — Old 3-service pins MUST be absent

The canonical template MUST NOT contain any of the following
substrings (substring grep on the full file, excluding the audit
comment block from FR-B8-SIG-A-010) :

- `signoz/frontend`
- `signoz/query-service`
- `otel/opentelemetry-collector-contrib`
- `:0.55.1` (the rotted-pin version anchor)

Mention of these strings inside the audit comment block (FR-B8-SIG-A-010)
is permitted as historical context.

##### FR-B8-SIG-A-004 — ClickHouse retained, version under ADR-2

The template MUST continue to declare a ClickHouse service (storage
substrate retained from the 3-service architecture). The pinned
ClickHouse image version is `[NEEDS CLARIFICATION: 24.x retained vs
25.x required pending upstream Compose fetch — Q-002 → ADR-B8-SIG-002]`.

##### FR-B8-SIG-A-005 — App state location under ADR-1

If `signoz/signoz:v0.125.1` embeds sqlite app state (replacing the
3-service external Postgres), the template MUST mount an appropriate
named volume for persistence and MUST declare the volume in the
`volumes:` block. If the unified arch still requires an external
Postgres, the template MUST declare a Postgres service mirroring the
former layout. The choice is
`[NEEDS CLARIFICATION: sqlite-embed vs external-Postgres pending
upstream Compose fetch — Q-001 → ADR-B8-SIG-001]`.

##### FR-B8-SIG-A-006 — OPAMP wiring under ADR-3

If the unified arch requires an explicit OPAMP server stub, the
template MUST declare it as a separate service with the appropriate
endpoint env-var (`[NEEDS CLARIFICATION: exact env-var name pending
upstream Compose fetch — Q-003 → ADR-B8-SIG-003]`). If OPAMP is
exposed natively on `signoz/signoz`, no separate service is
required and the collector MUST be configured to dial `signoz`
directly. Option (c) "OPAMP disabled in dev compose" is an
acceptable resolution path per Q-003.

##### FR-B8-SIG-A-007 — UI port mapping under ADR-4

The SigNoz UI service MUST expose a host port. The default host port
binding is `[NEEDS CLARIFICATION: `:3301` env-var-indirect vs `:8080`
upstream-aligned vs adopter-remap pending Q-004 → ADR-B8-SIG-004]`.
The chosen mapping MUST NOT collide with the `examples/forge-fsm-example/backend/`
default `:8080` binding without explicit conflict-resolution wording in
`infra/CLAUDE.md.tmpl` (FR-B8-SIG-H-001).

##### FR-B8-SIG-A-008 — OTLP ingest ports MUST be exposed on the collector

The `signoz/signoz-otel-collector` service MUST expose the OTLP
ingress ports `4317` (gRPC) and `4318` (HTTP) on the host, preserving
the FR-IN-009 contract from the full-stack-monorepo spec (apps in
`backend/` and `frontend/` ship `OTEL_EXPORTER_OTLP_ENDPOINT` pointing
at these ports).

##### FR-B8-SIG-A-009 — `fsm-dev` Docker network membership

Every unified-arch service introduced or retained by this change MUST
join the existing `fsm-dev` Docker network defined elsewhere in the
compose file (preserves FR-IN-007 network-isolation invariant from the
full-stack-monorepo spec).

##### FR-B8-SIG-A-010 — Audit comment block

The canonical template MUST gain (or preserve, if a prior block is
present) a YAML comment block immediately above the SigNoz services :

```yaml
# ── B.8.8 / b8-signoz-unified (2026-05-26) — SigNoz 3-svc → unified migration ──
# Migrated from 3-service architecture (signoz/frontend + signoz/query-service +
# otel-collector-contrib) to unified arch (signoz/signoz:v0.125.1 +
# signoz/signoz-otel-collector:v0.144.4). Rotted 3-service pins on Docker Hub
# (verify-then-pin lesson T5.3.2 applied 2026-05-26). v-prefix mandatory on
# SigNoz Docker Hub repositories — opposite of coroot/beyla convention.
```

##### FR-B8-SIG-A-011 — Healthchecks + restart policy preserved

Every SigNoz service in the unified arch MUST declare a `healthcheck:`
block and `restart: unless-stopped`, preserving the FR-IN-008 contract
from the full-stack-monorepo spec (b1-delivery 2026-04-29).

##### FR-B8-SIG-A-012 — `depends_on` chain coherent

The compose MUST express a `depends_on:` chain such that the collector
service waits for the unified `signoz/signoz` service to be
`service_healthy` (or equivalent), and the unified service waits for
ClickHouse to be `service_healthy`. The exact graph is
`[NEEDS CLARIFICATION: 2-service vs 3-service final layout pending
Q-001 → ADR-B8-SIG-001]`.

#### Cluster B — `observability.yaml` v2.0.0 BREAKING bump — FR-B8-SIG-B-001 → B-010

##### FR-B8-SIG-B-001 — Version field BREAKING bump

`.forge/standards/observability.yaml::version` MUST move from `"1.2.0"`
to `"2.0.0"`. The major bump signals a breaking versions-surgery
(REMOVE `signoz_frontend` + `signoz_query_service` +
`otel_collector_contrib` ; ADD `signoz` + `signoz_otel_collector`).
The bump is NOT additive (contrast with `b8-coroot-rehost` v1.1.0 →
v1.2.0 which was strictly additive).

##### FR-B8-SIG-B-002 — `versions.signoz` field ADDED

The standard MUST declare a new key `versions.signoz: "v0.125.1"`. The
value MUST carry the v-prefix per evidence.md § 1.4. An adjacent YAML
comment MUST document the v-prefix convention as opposite of
`versions.coroot` / `versions.beyla`.

##### FR-B8-SIG-B-003 — `versions.signoz_otel_collector` field ADDED

The standard MUST declare a new key
`versions.signoz_otel_collector: "v0.144.4"`. v-prefix mandatory per
evidence.md § 1.4.

##### FR-B8-SIG-B-004 — Versions REMOVED (breaking)

The standard MUST NOT carry any of the following keys after the
bump : `versions.signoz_frontend`, `versions.signoz_query_service`,
`versions.otel_collector_contrib`. (Per evidence.md § 1.5 the keys
are NOT present in v1.2.0 — see Source Documents row "Current pins in
standard" : the standard has historically carried only `beyla` and
`coroot`, and the SigNoz pins lived in the docker-compose template
exclusively. This FR is defensive : it remains TESTABLE as a "MUST
NOT appear after v2.0.0 bump" grep assertion, and prevents accidental
re-introduction during the bump.)

##### FR-B8-SIG-B-005 — New top-level field `pin_review_cadence:` ADDED

The standard MUST declare a new top-level map field
`pin_review_cadence:` with at minimum the following keys :

- `signoz: "30d"` (aggressive upstream dev velocity per evidence.md § 2.4 reservation)
- `signoz_otel_collector: "30d"` (tracks signoz/signoz cadence)
- `beyla: "12mo"` (slow OBI cadence, established precedent)
- `coroot: "12mo"` (established Coroot pilot cadence)

The exact YAML location (top-level flat vs nested under `versions:`) is
`[NEEDS CLARIFICATION: schema location pending Q-005 → ADR-B8-SIG-005]`.

##### FR-B8-SIG-B-006 — Cadence-enforcement semantics

The semantics of `pin_review_cadence:<component>: "30d"` (informational
vs blocking, reviewed-by-whom, what-fires-at-T+30d) is
`[NEEDS CLARIFICATION: enforcement semantics pending Q-005 → ADR-B8-SIG-005]`.
At minimum the field MUST be readable by `validate-standards-yaml.sh`
without raising schema errors (NFR-B8-SIG-009 covers timing).

##### FR-B8-SIG-B-007 — `last_reviewed` refreshed

`.forge/standards/observability.yaml::last_reviewed` MUST move from
`2026-05-25` (set by b8-coroot-rehost) to `2026-05-26`.

##### FR-B8-SIG-B-008 — `expires_at` refreshed

`.forge/standards/observability.yaml::expires_at` MUST move from
`2027-05-04` to `2027-05-26` (12-month forward window from the new
`last_reviewed`, preserving the standards-lifecycle invariant
`expires_at > last_reviewed` per FR-J7-021).

##### FR-B8-SIG-B-009 — WAIVER block in frontmatter

The standard frontmatter MUST gain a WAIVER comment block documenting
the breaking architectural shift, citing `standards-lifecycle.md`
§ Bumps and naming `b8-signoz-unified` as the originating change. The
block MUST also note explicitly that the `pin_review_cadence:`
additive field does not require Article XII constitutional amendment
per ADR-J7-008 schema-relaxation precedent (proposal § Article XII).

##### FR-B8-SIG-B-010 — `breaking_change: true` invariant marker

The standard frontmatter MUST carry an explicit
`breaking_change: true` field (or equivalent comment marker if the
J.7 schema does not yet declare the field — see Cluster C). The
marker is the machine-readable signal that the v1.x → v2.0.0 jump is
NOT additive and that the REVIEW.md row uses `ARCH-CHANGE`, not
`Updated`.

#### Cluster C — Schema impact on `standard.schema.json` — FR-B8-SIG-C-001 → C-004

##### FR-B8-SIG-C-001 — `pin_review_cadence` field accepted by J.7 validator

`bin/validate-standards-yaml.sh .forge/standards/observability.yaml`
MUST exit 0 after the v2.0.0 bump. The `pin_review_cadence:` field
MUST NOT trigger an "unknown field" rejection. The location at which
the field is declared in `standard.schema.json` is
`[NEEDS CLARIFICATION: top-level vs nested vs per-component pending
Q-005 → ADR-B8-SIG-005]`.

##### FR-B8-SIG-C-002 — `breaking_change` invariant accepted by J.7 validator

The same validator MUST exit 0 with `breaking_change: true` declared in
the standard. Either the schema explicitly declares the property (extra
schema-impact entry) or it remains tolerated via the
`additionalProperties` posture of the standard envelope — choice is
`[NEEDS CLARIFICATION: schema-declare vs schema-tolerate pending
Q-005 → ADR-B8-SIG-005]`.

##### FR-B8-SIG-C-003 — Schema bump bookkeeping

If Q-005 resolves to "schema-impact YES" the change MUST also update
the schema's own `$id` / `version` (mirroring the FR-J7-* pattern for
schema evolution). If resolution is "schema-tolerate", `standard.schema.json`
remains untouched. Either path MUST be documented in `design.md` /
ADR-B8-SIG-005.

##### FR-B8-SIG-C-004 — Backward-compat of the schema against sibling standards

After any schema update for FR-B8-SIG-C-001 / C-002, every other
ratified standard (`transport.yaml`, `state-management.yaml`,
`orchestration.yaml`, `identity.yaml`, `persistence.yaml`) MUST still
validate cleanly under `validate-standards-yaml.sh`. The harness
(Cluster E) MUST re-run all standards as a regression guard
(`[NEEDS CLARIFICATION: harness re-run is opt-in or default-on pending
design phase — Q-005-adjacent]`).

#### Cluster D — Snapshot regeneration + A.7 backward compat — FR-B8-SIG-D-001 → D-005

##### FR-B8-SIG-D-001 — Snapshot regenerated

`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` MUST be
regenerated via `bin/forge-snapshot.sh --archetype
full-stack-monorepo --version 1.0.0` with `SOURCE_DATE_EPOCH` set to a
deterministic value. The new tarball reflects the unified compose
template inside its inline copy of `infra/docker-compose.dev.yml.tmpl`.

##### FR-B8-SIG-D-002 — Snapshot determinism preserved

Re-running `SOURCE_DATE_EPOCH=<same-value> bin/forge-snapshot.sh
--archetype full-stack-monorepo --version 1.0.0` twice in a row MUST
produce byte-identical tarballs (preserves NFR-OTEL-001 determinism
contract).

##### FR-B8-SIG-D-003 — Cli-bundle snapshot mirror byte-identity

`cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
MUST be byte-identical to the canonical snapshot after `npm run
bundle`.

##### FR-B8-SIG-D-004 — A.7 forge-upgrade backward compat

After snapshot regen, `.forge/scripts/tests/a7.test.sh --level 1` MUST
stay GREEN with the historical 29/29 PASS count. The forge-upgrade
non-destructive 3-way merge invariant MUST survive the v1.2.0 → v2.0.0
breaking standard bump. Adopters running `forge upgrade --target
<project>` MUST receive `[NEEDS MIGRATION:]` markers for the
docker-compose service deltas (A.7 marker mechanism, Article V
immutability).

##### FR-B8-SIG-D-005 — `upgrade_history` ledger ARCH-CHANGE row

When an adopter runs `forge upgrade` across the breaking bump, the
adopter-side `upgrade_history` ledger (per A.7 upgrade-policy
standard) MUST append a row carrying `breaking_change: true` and
naming `b8-signoz-unified` as the source change. The exact ledger
schema field-name compatibility is
`[NEEDS CLARIFICATION: upgrade-policy ledger field-name pending
design-phase grep — Q-001-adjacent]`.

#### Cluster E — Harness `b8-signoz.test.sh` — FR-B8-SIG-E-001 → E-018

##### FR-B8-SIG-E-001 — Harness file exists

`.forge/scripts/tests/b8-signoz.test.sh` MUST exist, be executable
bash, use `set -uo pipefail`, sport an audit comment block, declare
`--level` parsing, source `_helpers.sh`, and follow the
`b8-coroot.test.sh` shape (b8-coroot-rehost precedent).

##### FR-B8-SIG-E-002 — ≥ 13 L1 grep-based tests

The harness MUST declare at least 13 L1 tests (no network, no Docker)
covering the full assertion surface below.

##### FR-B8-SIG-E-003 — Canonical compose pins unified

L1 test `_test_b8sig_l1_001_canonical_compose_signoz_pin` MUST assert
the canonical template contains exactly `signoz/signoz:v0.125.1`
(FR-B8-SIG-A-001).

##### FR-B8-SIG-E-004 — Canonical compose pins unified collector

L1 test `_test_b8sig_l1_002_canonical_compose_collector_pin` MUST
assert the canonical template contains exactly
`signoz/signoz-otel-collector:v0.144.4` (FR-B8-SIG-A-002).

##### FR-B8-SIG-E-005 — Rotted 3-service pins absent in canonical compose

L1 test `_test_b8sig_l1_003_canonical_no_rotted_pins` MUST assert the
canonical template contains zero occurrences of `signoz/frontend`,
`signoz/query-service`, `otel/opentelemetry-collector-contrib`,
`:0.55.1` outside the audit comment (FR-B8-SIG-A-003).

##### FR-B8-SIG-E-006 — Audit comment block present

L1 test `_test_b8sig_l1_004_audit_comment_present` MUST assert the
FR-B8-SIG-A-010 audit comment block exists in the canonical template.

##### FR-B8-SIG-E-007 — `observability.yaml::version` is v2.0.0

L1 test `_test_b8sig_l1_005_standard_version_v200` MUST regex-match
`^version:\s*"?2\.0\.0"?$` on the standard.

##### FR-B8-SIG-E-008 — `observability.yaml::versions.signoz` is v0.125.1

L1 test `_test_b8sig_l1_006_standard_signoz_pin_vprefix` MUST
regex-match `^\s*signoz:\s*"?v0\.125\.1"?$` (FR-B8-SIG-B-002).

##### FR-B8-SIG-E-009 — `observability.yaml::versions.signoz_otel_collector` is v0.144.4

L1 test `_test_b8sig_l1_007_standard_collector_pin_vprefix` MUST
regex-match `^\s*signoz_otel_collector:\s*"?v0\.144\.4"?$`
(FR-B8-SIG-B-003).

##### FR-B8-SIG-E-010 — `pin_review_cadence` field declared

L1 test `_test_b8sig_l1_008_pin_review_cadence_present` MUST assert
the standard contains a `pin_review_cadence:` field declaring at
minimum the 4 components (signoz, signoz_otel_collector, beyla,
coroot) per FR-B8-SIG-B-005.

##### FR-B8-SIG-E-011 — `last_reviewed` refreshed

L1 test `_test_b8sig_l1_009_standard_last_reviewed_2026_05_26` MUST
regex-match `^last_reviewed:\s*2026-05-26$` (FR-B8-SIG-B-007).

##### FR-B8-SIG-E-012 — WAIVER block + breaking_change marker present

L1 test `_test_b8sig_l1_010_waiver_breaking_change` MUST assert the
standard contains both the WAIVER comment block (FR-B8-SIG-B-009) and
the `breaking_change: true` marker (FR-B8-SIG-B-010).

##### FR-B8-SIG-E-013 — `REVIEW.md` ledger appended with ARCH-CHANGE flag

L1 test `_test_b8sig_l1_011_review_ledger_arch_change` MUST assert
`.forge/standards/REVIEW.md` last non-empty row matches the pattern
`2026-05-26 | ARCH-CHANGE | observability.yaml.*b8-signoz-unified`
(FR-B8-SIG-H-002).

##### FR-B8-SIG-E-014 — `validate-standards-yaml.sh` exits 0

L1 test `_test_b8sig_l1_012_validate_standards_yaml_passes` MUST run
`bash bin/validate-standards-yaml.sh .forge/standards/observability.yaml`
and assert exit code 0 (FR-B8-SIG-C-001).

##### FR-B8-SIG-E-015 — CHANGELOG `[Unreleased]` entry present

L1 test `_test_b8sig_l1_013_changelog_entry` MUST assert
`CHANGELOG.md [Unreleased]` (or `[0.4.0-rc.4]` post `/forge:plan`)
contains `b8-signoz-unified` (FR-B8-SIG-H-003).

##### FR-B8-SIG-E-016 — L2 opt-in `FORGE_B8_SIGNOZ_DOCKER=1` manifest-pull

At least one L2 test gated by `FORGE_B8_SIGNOZ_DOCKER=1` AND
`command -v docker` MUST run :

- `_test_b8sig_l2_001_unified_manifest_pullable` — `docker manifest
  inspect signoz/signoz:v0.125.1` exit 0 AND output contains
  `"architecture":"amd64"` AND `"architecture":"arm64"` (multi-arch
  invariant per evidence.md § 1.1).

Skip-pass when either gate is unmet (mirrors b8-coroot-rehost
ADR-B8-COR-003 + FR-B1-DUM-082 → ADR-T5-OLR-005 precedent).

##### FR-B8-SIG-E-017 — L2 collector manifest-pull

A second L2 test under the same gate :

- `_test_b8sig_l2_002_collector_manifest_pullable` — `docker manifest
  inspect signoz/signoz-otel-collector:v0.144.4` exit 0 + multi-arch
  assertion (evidence.md § 1.2).

##### FR-B8-SIG-E-018 — L2 docker-compose up-down smoke

A third L2 test under the same gate :

- `_test_b8sig_l2_003_compose_up_healthy` — renders the canonical
  compose template into a tmpdir, runs `docker compose -f
  <rendered>.yml up -d`, polls healthchecks for ≤ 120 s, asserts all
  declared services reach `healthy`, then runs `docker compose down
  -v` cleanup. Bound to 127.0.0.1 only (no public port exposure),
  cleanup trap on EXIT, force-down on TRAP (mirrors b8-coroot-rehost
  ADR-B8-COR-003 L2 isolation pattern). Exact rendered-template
  source path is
  `[NEEDS CLARIFICATION: pending Q-001 + Q-004 resolution — Q-001-adjacent]`.

#### Cluster F — CI integration (forge-ci.yml) — FR-B8-SIG-F-001 → F-003

##### FR-B8-SIG-F-001 — Harness registered in matrix

`.github/workflows/forge-ci.yml::harness` matrix MUST gain a new
entry registering `b8-signoz.test.sh --level 1` immediately after the
`b8-coroot.test.sh` entry (latest harness registered as of
v0.4.0-rc.3).

##### FR-B8-SIG-F-002 — Line budget preserved

After registration, `.github/workflows/forge-ci.yml` MUST remain
≤ 300 lines (NFR-CI-002). Current line count is 297 post-b8-coroot-rehost ;
the +3 line addition fills the budget exactly. If compression is
required to stay within budget, apply T5.3.3 ADR-T533-002-style
comment trimming. Exact post-add count is
`[NEEDS CLARIFICATION: deferred to /forge:design measurement pass —
Q-001-adjacent]`.

##### FR-B8-SIG-F-003 — Matrix invocation level

The matrix entry MUST invoke the harness at `--level 1` only. L2
(`FORGE_B8_SIGNOZ_DOCKER=1`) MUST NOT be active in default CI runs ;
opt-in via a separate workflow job is permitted but out of scope for
this change.

#### Cluster G — 4-copy mirror sync — FR-B8-SIG-G-001 → G-005

##### FR-B8-SIG-G-001 — Canonical .tmpl is the source of truth

The canonical
`.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl`
is the single editable source. Every other copy is derived.

##### FR-B8-SIG-G-002 — Cli-bundle .tmpl byte-identity

`cli/assets/.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl`
MUST be byte-identical to the canonical .tmpl after `npm run bundle`.

##### FR-B8-SIG-G-003 — Example rendered file mirror

`examples/forge-fsm-example/infra/docker-compose.yml` (rendered
output, no templating placeholders) MUST carry the same SigNoz +
collector image references as the canonical .tmpl (literal pins,
post-substitution of `<project-name>` placeholders).

##### FR-B8-SIG-G-004 — Cli-bundle example rendered mirror byte-identity

`cli/assets/examples/forge-fsm-example/infra/docker-compose.yml` (or
the example-side .tmpl variant if shipped — pending Q-001) MUST be
byte-identical to the rendered example at FR-B8-SIG-G-003 after `npm
run bundle`.

##### FR-B8-SIG-G-005 — Mirror count discoverable

A `find` invocation for `docker-compose*.yml*` under the repo root
(excluding `node_modules`, `.git`, dot-files outside `.forge/` and
`cli/assets/`) MUST return the expected count of mirror copies. The
exact count target is
`[NEEDS CLARIFICATION: 4 vs 3 mirror copies depending on whether the
example-side .tmpl variant exists — Q-001-adjacent enumeration at
/forge:design]`.

#### Cluster H — Documentation — FR-B8-SIG-H-001 → H-006

##### FR-B8-SIG-H-001 — `infra/CLAUDE.md.tmpl` SigNoz section updated

`.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/CLAUDE.md.tmpl`
MUST gain (or refresh) a H2 section titled "SigNoz unified
architecture" documenting :

- The 2-service (or 3-service per Q-001 resolution) layout with the
  unified `signoz/signoz` + `signoz/signoz-otel-collector` pins.
- The UI port mapping decision (Q-004 → ADR-B8-SIG-004).
- The "fresh-start only for dev environments" posture for ClickHouse
  data-volume + sqlite app state (proposal Scope Out + Risk #1 + #2).
- A pointer to OPAMP wiring if applicable (Q-003 → ADR-B8-SIG-003).
- The jurisdiction posture summary (Q-006 → ADR-B8-SIG-006).
- The v-prefix tag convention as opposite of `coroot/beyla`
  (evidence.md § 1.4).

##### FR-B8-SIG-H-002 — `REVIEW.md` ledger entry with ARCH-CHANGE flag

`.forge/standards/REVIEW.md` MUST gain a new row :

```
| 2026-05-26 | ARCH-CHANGE | observability.yaml v1.2.0 → v2.0.0 (b8-signoz-unified) |
```

The flag MUST be `ARCH-CHANGE`, NOT `Updated`. The row MUST be
appended after the existing latest entry (FR-J7-023 append-only
invariant). `ARCH-CHANGE` is the new flag introduced by this change to
semantically distinguish breaking architectural shifts from version
refreshes ; see FR-B8-SIG-H-006 for the precedent declaration.

##### FR-B8-SIG-H-003 — CHANGELOG entry

`CHANGELOG.md` MUST gain a `### Fixed — SigNoz 3-service → unified
arch migration (B.8.8, b8-signoz-unified)` block under
`[Unreleased]` (or `[0.4.0-rc.4]` post `/forge:plan`) citing :

- `task validate dev-up-matrix` RED known-issue debloqué (rc.2 / rc.3 carry-over)
- 3-service rotted-pin replacement → unified `signoz/signoz:v0.125.1`
  + `signoz/signoz-otel-collector:v0.144.4`
- `observability.yaml` v1.2.0 → v2.0.0 BREAKING (versions surgery + new `pin_review_cadence:` field + WAIVER + breaking_change marker)
- REVIEW.md ledger appended with ARCH-CHANGE flag
- 4-copy mirror sync
- New harness `b8-signoz.test.sh`
- Snapshot regenerated
- A.7 forge-upgrade compat preserved (29/29 a7.test.sh PASS)

##### FR-B8-SIG-H-004 — Plan inventory updated

The `Inventaire .forge/changes/` table in
`docs/new-archetypes-plan.md` MUST gain a row (once `archived`) :

```
| b8-signoz-unified | archived | B.8.8 (SigNoz 3-svc → unified arch, T6 trio sibling 2) |
```

##### FR-B8-SIG-H-005 — Roadmap status line

`.forge/product/roadmap.md` Phase 3 / T6 row MUST gain a "B.8.8
(SigNoz leg) Done <date>" entry once archived. May be drafted at
`specified` phase, completed at archive.

##### FR-B8-SIG-H-006 — `ARCH-CHANGE` ledger flag precedent declaration

`docs/new-archetypes-plan.md` (or an equivalent governance
location to be selected at `/forge:design`) MUST gain a one-paragraph
declaration that `ARCH-CHANGE` is the new REVIEW.md ledger flag for
breaking architectural shifts on a ratified standard, distinct from
the established `Updated` flag for version refreshes. Cites this
change as the originating precedent. Article XII compliance
discussion (no constitution amendment required per ADR-J7-008
schema-relaxation precedent and proposal § Article XII) MUST be
captured inline.

#### Cluster I — Janus + Demeter deltas (jurisdiction-conditional) — FR-B8-SIG-I-001 → I-003

These FR IDs are reserved but conditional on Q-006 resolution. Per
NFR-B8-COR-008 trio-coupling tolerance (inherited from
b8-coroot-rehost), this change MUST NOT modify K.3 / Demeter
standards without an explicit ADR justification.

##### FR-B8-SIG-I-001 — Demeter jurisdiction record for SigNoz Inc

`.forge/scripts/forge-demeter-scan.sh` MAY gain a SigNoz publisher
record (jurisdiction + CE license + phone-home posture) such that T3
adopters running the scan get an informational finding when
`signoz/signoz:v0.125.1` is detected in the docker-compose. The
record content is
`[NEEDS CLARIFICATION: SigNoz Inc jurisdiction + K3-RULE classification
pending Q-006 → ADR-B8-SIG-006]`.

##### FR-B8-SIG-I-002 — K3-RULE classification

If Q-006 resolution is option (b) "T1/T2 OK, T3 introduces new
K3-RULE-EXT-NNN", this change escalates to a K.3 amendment outside
scope per NFR-B8-COR-008. If resolution is option (a) "T1/T2 OK, T3
candidate-substitution flag", no new rule is added and the Demeter
record FR-B8-SIG-I-001 is sufficient. Choice is
`[NEEDS CLARIFICATION: pending Q-006 → ADR-B8-SIG-006]`.

##### FR-B8-SIG-I-003 — `cloud-act-publishers.yml` deny-list posture

`cloud-act-publishers.yml` (or the equivalent K.3 publisher manifest)
MUST NOT gain a SigNoz Inc entry as part of this change unless Q-006
resolution is option (d) "All tiers forbidden", in which case the scope
of this change escalates per NFR-B8-COR-008 trio-coupling exit. Choice
is `[NEEDS CLARIFICATION: pending Q-006 → ADR-B8-SIG-006]`.

#### Cluster J — Forward-pointer to b8-obi-refresh (trio sibling 3) — FR-B8-SIG-J-001 → J-002

##### FR-B8-SIG-J-001 — Reserved scope marker in standard

`.forge/standards/observability.yaml` v2.0.0 MUST carry a YAML comment
adjacent to `versions.beyla` reserving the OBI Beyla 2.0.1 → 3.15.0
major bump for the upcoming `b8-obi-refresh` sub-change (trio sibling
3). This change MUST NOT modify `versions.beyla` itself ; the comment
is documentation-only.

##### FR-B8-SIG-J-002 — Reserved scope marker in REVIEW.md

`.forge/standards/REVIEW.md` MAY carry a parenthetical pointer in the
`ARCH-CHANGE` row noting that the Beyla pin remains at `2.0.1`
pending trio sibling 3. Documentation-only ; no code coupling.

### Non-Functional Requirements

##### NFR-B8-SIG-001 — Snapshot size budget

`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` MUST
remain ≤ 600 KB gzipped (NFR-OTEL-001 budget). Current 520 KB ; the
unified-arch compose rewrite may approach but MUST NOT exceed budget.

##### NFR-B8-SIG-002 — `forge-ci.yml` line count budget

`.github/workflows/forge-ci.yml` MUST remain ≤ 300 lines (NFR-CI-002).

##### NFR-B8-SIG-003 — L1 harness wall-clock budget

`bash .forge/scripts/tests/b8-signoz.test.sh --level 1` MUST complete
in ≤ 2 s on the maintainer's reference machine (apple M-series), per
F.2 / J.7 / k3 / coroot precedent.

##### NFR-B8-SIG-004 — L2 harness opt-in semantics

L2 (`FORGE_B8_SIGNOZ_DOCKER=1`) MUST skip-pass when either the
env-var is unset OR `command -v docker` returns non-zero. Mirrors
b8-coroot-rehost ADR-B8-COR-003 + FR-B1-DUM-082 → ADR-T5-OLR-005
precedent. L2 wall-clock budget : ≤ 180 s end-to-end (manifest-pulls
+ compose up + healthcheck poll + cleanup).

##### NFR-B8-SIG-005 — `verify.sh` PASS preservation post-archive

`.forge/scripts/verify.sh` PASS count MUST NOT decrease after this
change is archived. Pre-archive (status: specified / designed /
planned / implemented) tolerated regression is limited to the
expected "new change at non-terminal status" gate behaviour per F.1.

##### NFR-B8-SIG-006 — `constitution-linter.sh` PASS preservation post-archive

`.forge/scripts/constitution-linter.sh` OVERALL MUST remain PASS
after this change is archived. Existing harnesses (`t5-1`, `t5-2`,
`t5-otel-dartastic`, `t5-3-1`, `t5-3-3`, `b8-coroot`, `i2..i6`, `j7`,
`j8`, `k3`, `a7`) MUST stay GREEN.

##### NFR-B8-SIG-007 — `task validate dev-up-matrix` GREEN end-to-end

After this change is archived, `task validate dev-up-matrix` MUST exit
0 against the `full-stack-monorepo / 1.0.0` archetype. This NFR is the
explicit known-issue-debloque for v0.4.0-rc.2 / rc.3.

##### NFR-B8-SIG-008 — Deterministic snapshot via SOURCE_DATE_EPOCH

Snapshot regen MUST be deterministic per the I.6 / b8-coroot-rehost
ADR-B8-COR pattern : `SOURCE_DATE_EPOCH=<value> bin/forge-snapshot.sh`
twice in a row produces byte-identical tarballs.

##### NFR-B8-SIG-009 — `pin_review_cadence` enforcement timing

The `pin_review_cadence:` field's enforcement timing is
`[NEEDS CLARIFICATION: informational-only vs blocking-after-T+30d
pending Q-005 → ADR-B8-SIG-005]`. At minimum the field MUST be
machine-readable by `validate-standards-yaml.sh` (FR-B8-SIG-C-001).
Active enforcement (e.g. a `forge-questions.sh`-style nag) MAY be
deferred to a future J.7-class amendment.

##### NFR-B8-SIG-010 — A.7 forge-upgrade 29/29 PASS preserved

`a7.test.sh --level 1` MUST stay GREEN with the historical 29/29 PASS
count against the regenerated snapshot (FR-B8-SIG-D-004 paired NFR
budget).

##### NFR-B8-SIG-011 — Trio coupling tolerance (inherited)

The standard `observability.yaml v2.0.0` shipped here MUST remain a
valid input for the upcoming `b8-obi-refresh` (additive Beyla 2.0.1 →
3.15.0 bump). This change MUST NOT introduce a frontmatter shape via
the new `pin_review_cadence:` schema that would force the OBI sibling
to revert the cadence field, NOR a `breaking_change: true` semantic
that would block additive minor bumps from siblings (per
NFR-B8-COR-008 trio-coupling tolerance).

##### NFR-B8-SIG-012 — Atomic revertability

The change MUST be revertable via a single `git revert <merge-sha>`
without leaving the 4 compose copies out-of-sync or the standard
frontmatter inconsistent with REVIEW.md (mirrors NFR-B8-COR-005
atomic-revert invariant).

### Open Decisions Deferred to `/forge:design`

| ADR ID            | Decision                                                                                                              | Q-NNN pairing | Owner          |
|-------------------|-----------------------------------------------------------------------------------------------------------------------|---------------|----------------|
| `ADR-B8-SIG-001`  | SigNoz unified embedded components inventory + sqlite vs Postgres app state → 2-service vs 3-service final layout     | Q-001         | Atlas (Infra)  |
| `ADR-B8-SIG-002`  | ClickHouse pin under unified arch (24.x retained, 25.x required, upstream-tracked)                                    | Q-002         | Atlas (Infra)  |
| `ADR-B8-SIG-003`  | OPAMP wiring requirement (native, separate stub, dev-disabled)                                                        | Q-003         | Atlas (Infra)  |
| `ADR-B8-SIG-004`  | UI port mapping (`:3301` env-var-indirect vs `:8080` upstream-aligned vs adopter-remap)                               | Q-004         | Atlas (Infra)  |
| `ADR-B8-SIG-005`  | `pin_review_cadence:` schema location + enforcement semantics (J.7 schema impact)                                     | Q-005         | Atlas (Infra)  |
| `ADR-B8-SIG-006`  | SigNoz Inc jurisdiction + K3-RULE classification for T3 adopters                                                      | Q-006         | Demeter        |

These six open questions are tracked in `open-questions.md`
(`Q-001..Q-006`) at Status `open` until design resolves each into an
ADR. NFR-B8-SIG-011 explicitly forbids introducing a frontmatter
shape via these ADRs that the OBI sibling would have to revert.

---

## MODIFIED Requirements

> Grep-verified targets in `.forge/specs/full-stack-monorepo.md` —
> `FR-IN-008` and `FR-IN-012` are the canonical FRs that name the
> 3-service SigNoz architecture. Source `find . -path './node_modules'
> -prune -o -name '*.md' -print | xargs grep -lnE
> 'signoz/(frontend|query-service)|signoz_(frontend|query_service)'`
> at 2026-05-26 returns only `.forge/specs/full-stack-monorepo.md`
> + `.forge/specs/otel-app.md` (descriptive prose mentions, no FR
> assertion) + `.forge/specs/otel-traceparent-e2e.md` (BDD prose) +
> the change-directory archive (out of scope per Article V).
> `.forge/specs/otel-stack.md::FR-OTEL-*` does NOT cite SigNoz
> services — it is scoped to OBI + Coroot + sampler — and so remains
> untouched by this MODIFIED/REMOVED set.

### FR-IN-008 (MODIFIED in b8-signoz-unified)

Previously (from `b1-delivery` 2026-04-29) :

> **MUST** — three services `fsm-signoz-clickhouse` (storage),
> `fsm-signoz-query` (HTTP API), `fsm-signoz-frontend` (UI on :3301).
> All pinned to specific versions (no `:latest`).
> **MUST** — only `fsm-signoz-frontend` host-exposes a port (3301).
> `clickhouse` and `query-service` are internal-only.
> **MUST** — every SigNoz service declares a healthcheck and
> `restart: unless-stopped`.
> **MUST** — `depends_on` chain : `query → clickhouse:
> service_healthy`, `frontend → query: service_healthy`.
> **SHALL** — named volume `signoz-clickhouse-data` for persistence.
> **SHOULD** — `Taskfile.yml.tmpl` declares `task observe` that
> opens `http://localhost:3301` via `open` (macOS) or `xdg-open`
> (Linux).

Now :

> **MUST** — two or three services for the unified SigNoz
> architecture : `fsm-signoz` (unified UI + query-service + alertmanager,
> pinned to `signoz/signoz:v0.125.1` per FR-B8-SIG-A-001) +
> `fsm-signoz-otel-collector` (SigNoz-flavoured collector, pinned to
> `signoz/signoz-otel-collector:v0.144.4` per FR-B8-SIG-A-002) +
> optional `fsm-signoz-clickhouse` retained as storage substrate
> (FR-B8-SIG-A-004). The choice of 2-service vs 3-service final layout
> is governed by ADR-B8-SIG-001.
> **MUST** — `fsm-signoz` host-exposes the UI port per
> ADR-B8-SIG-004 ; collector services host-expose `4317` (gRPC OTLP)
> + `4318` (HTTP OTLP) per FR-B8-SIG-A-008.
> **MUST** — every retained or new service declares a healthcheck
> and `restart: unless-stopped` per FR-B8-SIG-A-011.
> **MUST** — `depends_on` chain coherent per FR-B8-SIG-A-012.
> **SHALL** — named volume(s) for ClickHouse persistence + sqlite
> app state if Q-001 resolves to embedded-sqlite per FR-B8-SIG-A-005.
> **SHOULD** — `Taskfile.yml.tmpl` `task observe` target opens the
> UI URL determined by ADR-B8-SIG-004 (formerly hardcoded
> `http://localhost:3301`).
>
> **Constitution reference:** Article IX. **Testable:** yes —
> `_test_b8sig_l1_001..004` + `_test_b8sig_l2_003_compose_up_healthy`
> per Cluster E.

<!-- Modified in b8-signoz-unified, 2026-05-26 -->

### FR-IN-012 (MODIFIED in b8-signoz-unified)

Previously (from `b1-delivery` 2026-04-29) :

> **MUST** — records the exact pinned image versions for
> `otel-collector`, `signoz-clickhouse`, `signoz-query-service`,
> `signoz-frontend` — single source of truth referenced by the
> compose template.

Now :

> **MUST** — records the exact pinned image versions for
> `signoz`, `signoz-otel-collector`, `signoz-clickhouse` (if retained
> per Q-001 / ADR-B8-SIG-001), and references `versions.signoz` +
> `versions.signoz_otel_collector` in `.forge/standards/observability.yaml`
> v2.0.0 as the authoritative source per FR-B8-SIG-B-002 +
> FR-B8-SIG-B-003. The previous 3-service version-list
> (`signoz-clickhouse`, `signoz-query-service`, `signoz-frontend`)
> MUST NOT appear in the standard text after this change.
>
> **Constitution reference:** Article IX. **Testable:** yes —
> `_test_b8sig_l1_005..010` per Cluster E (asserts both presence of
> the new pins AND absence of the legacy 3-service names in the
> standard).

<!-- Modified in b8-signoz-unified, 2026-05-26 -->

---

## REMOVED Requirements

> Honest count : the only ADDED `signoz_*` keys in
> `observability.yaml` historically were planted by `b1-delivery`'s
> companion text under `FR-IN-012` (standard prose), NOT as
> first-class `versions.*` map entries. `b8-coroot-rehost` (v1.2.0)
> shipped the standard with `versions.beyla` + `versions.coroot`
> only ; no `versions.signoz_*` keys are present pre-v2.0.0.
> Therefore the REMOVED entries below are defensive — they prevent
> the bump from accidentally re-introducing the legacy names — and
> they do NOT correspond to grep-locatable shipped FR IDs.

### FR-B8-SIG-REMOVED-001 — Legacy 3-service compose service names

The compose service names `fsm-signoz-clickhouse` (as the sole
ClickHouse service alias), `fsm-signoz-query`, `fsm-signoz-frontend`
in the canonical
`.forge/templates/archetypes/full-stack-monorepo/1.0.0/infra/docker-compose.dev.yml.tmpl`
are DEPRECATED in b8-signoz-unified. Reason : SigNoz upstream
architectural migration 3-services → unified. Old `signoz/frontend`
+ `signoz/query-service` images rotted on Docker Hub (last published
`0.76.3` pruned ; verified `docker manifest inspect` 2026-05-20 per
`docs/new-archetypes-plan.md` §0.5). Replacement names per
FR-IN-008 (MODIFIED above) : `fsm-signoz` + `fsm-signoz-otel-collector`
(+ optional `fsm-signoz-clickhouse` if retained per Q-001).

### FR-B8-SIG-REMOVED-002 — Legacy 3-service image pins from standard prose

If any prior version of `.forge/standards/observability.yaml` carried
literal references to `signoz_frontend`, `signoz_query_service`, or
`otel_collector_contrib` (whether as `versions.*` map keys or in
prose), those references MUST be excised in the v2.0.0 bump.
Per evidence.md § 1.5 + Source Documents row "Current pins in
standard", v1.2.0 does NOT carry these keys ; this REMOVED entry is
defensive against accidental re-introduction.

### FR-B8-SIG-REMOVED-003 — Hardcoded `:3301` host port assumption

The hardcoded `:3301` host port (FR-IN-008 previous + `task observe`
URL) is DEPRECATED ; the host port is now determined by ADR-B8-SIG-004
(Q-004 resolution). Reason : SigNoz upstream unified Compose example
exposes container `:8080`, which collides with the
`examples/forge-fsm-example/backend/` default. The new port mapping
MUST be parameterised per FR-B8-SIG-A-007.

---

## BDD Acceptance Criteria

> Article II (BDD) applies because this change affects user-facing
> adopter workflows : `forge init` scaffolding, `task dev:up`,
> `forge upgrade`, `forge-demeter-scan.sh`, and the
> standards-validator surface. Scenarios are documented in Gherkin
> per Article II.2, even though the SigNoz UI itself is consumed by
> operators, not by application end-users.

### BDD-B8-SIG-001 — Fresh scaffold runs unified SigNoz dev stack

```gherkin
Feature: Adopters scaffolding the flagship inherit the unified SigNoz dev stack
  As a new forge adopter
  I want to scaffold full-stack-monorepo / 1.0.0 and run task dev:up
  So that observability boots cleanly on first run without ImagePull errors

  Scenario: Fresh scaffold + task dev:up reaches healthy unified SigNoz stack
    Given an environment with `docker`, `task`, and `forge` on PATH
      And a clean working directory at `/tmp/probe`
    When the adopter runs `forge init my-app --archetype full-stack-monorepo --org test.local --target /tmp/probe`
      And the adopter runs `task dev:up` from `/tmp/probe/my-app`
    Then `docker compose ps` shows a service running `signoz/signoz:v0.125.1` healthy
      And `docker compose ps` shows a service running `signoz/signoz-otel-collector:v0.144.4` healthy
      And `docker compose ps` exposes OTLP gRPC on `:4317` and OTLP HTTP on `:4318`
      And `docker compose ps` exposes the SigNoz UI on the port declared by ADR-B8-SIG-004
      And no service in `docker compose ps` carries the image `signoz/frontend` or `signoz/query-service` or `otel/opentelemetry-collector-contrib`
```

Maps to : FR-B8-SIG-A-001, A-002, A-003, A-007, A-008, A-011, A-012.

### BDD-B8-SIG-002 — `task validate dev-up-matrix` GREEN end-to-end

```gherkin
Feature: Maintainer task validate dev-up-matrix exits cleanly after b8-signoz-unified
  As a forge maintainer
  I want task validate dev-up-matrix to be GREEN
  So that the v0.4.0-rc.2 / rc.3 known-issue is debloque before rc.4

  Scenario: dev-up-matrix exits 0 on the full-stack-monorepo / 1.0.0 archetype
    Given the maintainer runs from `/Users/bfontaine/git/github/forge` (repo root)
      And the working tree is clean post-b8-signoz-unified archive
    When the maintainer runs `task validate dev-up-matrix`
    Then the exit code is 0
      And no rendered `docker-compose.yml` produced by the matrix references the literal `image: signoz/frontend:0.55.1`
      And no rendered `docker-compose.yml` produced by the matrix references the literal `image: signoz/query-service:0.55.1`
      And the matrix run completes within the documented wall-clock timeout
```

Maps to : NFR-B8-SIG-007, FR-B8-SIG-A-003, FR-B8-SIG-G-001..G-005.

### BDD-B8-SIG-003 — A.7 `forge upgrade` preserves adopter state across the breaking bump

```gherkin
Feature: forge upgrade is non-destructive across the v1.2.0 → v2.0.0 breaking standards bump
  As an adopter on full-stack-monorepo / 1.0.0 pre-b8-signoz-unified
  I want to run forge upgrade and get NEEDS MIGRATION markers, not destruction
  So that the breaking bump never overwrites my customizations silently

  Scenario: forge upgrade emits NEEDS MIGRATION markers for the docker-compose service deltas
    Given an adopter project at `<project>` scaffolded on `full-stack-monorepo / 1.0.0` (pre-b8-signoz-unified)
      And the adopter has customized files outside `.forge/framework-owned-paths.yml`
    When the adopter runs `forge upgrade --target <project>` post-b8-signoz-unified archive
    Then exit code is 0
      And `[NEEDS MIGRATION:]` markers are emitted for the docker-compose service deltas (Article V + A.7 marker mechanism)
      And the adopter's `upgrade_history` ledger appends a row carrying `breaking_change: true` and citing `b8-signoz-unified`
      And the adopter's customizations outside `.forge/framework-owned-paths.yml` are NOT touched
      And `.forge/scripts/tests/a7.test.sh --level 1` exits 0 with 29/29 PASS preserved
```

Maps to : FR-B8-SIG-D-004, FR-B8-SIG-D-005, NFR-B8-SIG-010.

### BDD-B8-SIG-004 — `observability.yaml` v2.0.0 validates against the J.7 schema

```gherkin
Feature: observability.yaml v2.0.0 is accepted by the J.7 standards validator
  As a forge maintainer running J.7 validation
  I want the v2.0.0 breaking standard to pass schema validation
  So that the breaking bump never wedges the standards lifecycle

  Scenario: validate-standards-yaml.sh exits 0 on the v2.0.0 standard
    Given the new `.forge/standards/observability.yaml` v2.0.0 is committed
    When the maintainer runs `bash bin/validate-standards-yaml.sh .forge/standards/observability.yaml`
    Then exit code is 0
      And the validator accepts the new `pin_review_cadence:` field (per ADR-B8-SIG-005 schema location)
      And the validator accepts the `breaking_change: true` marker (per FR-B8-SIG-B-010)
      And the WAIVER comment block is recognised per `standards-lifecycle.md` § Bumps
      And `.forge/standards/REVIEW.md` contains the `ARCH-CHANGE` row for `observability.yaml` v1.2.0 → v2.0.0
```

Maps to : FR-B8-SIG-B-001, B-005, B-009, B-010, C-001, C-002, H-002.

### BDD-B8-SIG-005 — Demeter scan T3 adopter flags SigNoz jurisdiction posture

```gherkin
Feature: Demeter scan classifies SigNoz CE under K.3 for T3 adopters
  As a T3 EU-strict adopter
  I want forge-demeter-scan.sh to surface SigNoz Inc jurisdiction posture
  So that I can make a deployment-time substitution decision under K3-RULE-*

  Scenario: Demeter T3 scan emits an informational finding citing SigNoz Inc
    Given a T3 EU-strict adopter project at `<project>` post-b8-signoz-unified archive
      And the adopter's docker-compose declares `signoz/signoz:v0.125.1`
    When the adopter runs `bash bin/forge-demeter-scan.sh --tier T3 --target <project>`
    Then exit code is non-blocking (informational only for T1/T2/T3 unless Q-006 resolves to option (d))
      And the scan output cites the SigNoz Inc publisher jurisdiction
      And the finding severity follows K3-RULE-NNN tier-scaling per ADR-B8-SIG-006
      And T1 and T2 scans do NOT fail on the same project
```

Maps to : FR-B8-SIG-I-001, FR-B8-SIG-I-002, FR-B8-SIG-I-003.

### BDD-B8-SIG-006 — Maintainer-side harness L1 GREEN

```gherkin
Feature: Maintainer-side b8-signoz harness L1 is GREEN on a clean tree
  As a forge maintainer
  I want b8-signoz.test.sh --level 1 to pass deterministically without Docker
  So that CI never depends on Docker for the L1 layer (NFR-B8-SIG-003 + F.2 precedent)

  Scenario: L1 harness exits 0 with ≥ 13 tests passing
    Given the maintainer runs from a clean working tree post-b8-signoz-unified archive
      And `FORGE_B8_SIGNOZ_DOCKER` is unset
    When the maintainer runs `bash .forge/scripts/tests/b8-signoz.test.sh --level 1`
    Then exit code is 0
      And the stdout reports ≥ 13 tests PASS
      And no L2 test attempts a `docker manifest inspect` call (gated off by env-var)
      And wall-clock time is ≤ 2 s on apple M-series
```

Maps to : FR-B8-SIG-E-001..E-015, NFR-B8-SIG-003, NFR-B8-SIG-004.

### BDD ↔ FR Mapping (Article II.1 enforcement, spec-phase analog of constitution-linter Article V.1 task↔FR linkage)

| BDD ID              | FR / NFR IDs covered                                                                                          |
|---------------------|---------------------------------------------------------------------------------------------------------------|
| BDD-B8-SIG-001      | FR-B8-SIG-A-001, A-002, A-003, A-007, A-008, A-011, A-012                                                     |
| BDD-B8-SIG-002      | NFR-B8-SIG-007, FR-B8-SIG-A-003, FR-B8-SIG-G-001..G-005                                                       |
| BDD-B8-SIG-003      | FR-B8-SIG-D-004, D-005, NFR-B8-SIG-010                                                                        |
| BDD-B8-SIG-004      | FR-B8-SIG-B-001, B-005, B-009, B-010, C-001, C-002, H-002                                                     |
| BDD-B8-SIG-005      | FR-B8-SIG-I-001, I-002, I-003                                                                                 |
| BDD-B8-SIG-006      | FR-B8-SIG-E-001..E-015, NFR-B8-SIG-003, NFR-B8-SIG-004                                                        |

Every BDD scenario maps to ≥ 1 FR or NFR ID. Every FR cluster A..J is
touched by at least one BDD scenario except Cluster F (CI matrix
registration — internal-only, covered by NFR-B8-SIG-002 budget +
existing forge-self-ci harness) and Cluster J (forward-pointer
documentation — non-behavioural, no Gherkin justified).

---

## Anti-Hallucination Pass (Article III.4)

Per `.forge/standards/global/open-questions.md` mechanisation, every
inline `[NEEDS CLARIFICATION: ...]` marker in this spec pairs with an
open Q-NNN tracked in `open-questions.md`. Mapping table :

| Q-NNN  | Subject                                                                                | Inline markers attached to                                                                                                                                                  |
|--------|----------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Q-001  | SigNoz unified embedded components inventory + sqlite app state                        | FR-B8-SIG-A-005, FR-B8-SIG-A-012, FR-B8-SIG-D-005 (ledger field-name), FR-B8-SIG-E-018 (compose path), FR-B8-SIG-F-002 (post-add line count), FR-B8-SIG-G-004, FR-B8-SIG-G-005, Source Documents row "4-copy mirror inventory" |
| Q-002  | ClickHouse version pin under unified SigNoz                                            | FR-B8-SIG-A-004                                                                                                                                                              |
| Q-003  | OPAMP wiring requirement                                                               | FR-B8-SIG-A-006                                                                                                                                                              |
| Q-004  | UI port mapping :3301 vs :8080 vs adopter-remap                                        | FR-B8-SIG-A-007, BDD-B8-SIG-001 (port determined by ADR-B8-SIG-004)                                                                                                          |
| Q-005  | `pin_review_cadence:` schema location + enforcement semantics                          | FR-B8-SIG-B-005, FR-B8-SIG-B-006, FR-B8-SIG-C-001, FR-B8-SIG-C-002, FR-B8-SIG-C-003, FR-B8-SIG-C-004, NFR-B8-SIG-009                                                         |
| Q-006  | SigNoz Inc jurisdiction + K3-RULE classification                                       | FR-B8-SIG-I-001, FR-B8-SIG-I-002, FR-B8-SIG-I-003, BDD-B8-SIG-005                                                                                                            |

Each of the six open questions has at least one `[NEEDS CLARIFICATION:]`
marker attached to a FR/NFR/BDD. No marker is orphan (i.e. not paired
with a tracked Q-NNN). No symbol asserted in this spec is unsourced :
SigNoz tag identities + manifest digests are pinned by evidence.md § 1
; FR-IN-008 / FR-IN-012 MODIFIED set is grep-verified against
`.forge/specs/full-stack-monorepo.md` ; observability.yaml v1.2.0
shape is grep-verified against the live file as Read 2026-05-26.

No fabricated symbols introduced. SigNoz API surface, OPAMP config
schema, ClickHouse migration steps, sqlite path, `forge-demeter-scan.sh`
flag syntax, `forge-questions.sh` nag mechanism — all defer to
Q-NNN-paired ADRs at `/forge:design`.

---

## Out of Scope (asserted negatively, mirrors proposal.md § Scope Out)

The following are explicitly out of scope and MUST NOT be touched by
implementation of this change :

- **OBI / Beyla eBPF refresh** — owned by trio sibling 3
  `b8-obi-refresh` (Beyla 2.0.1 → 3.15.0 major bump + capabilities
  Linux review + Aegis re-audit). `versions.beyla` stays at `"2.0.1"`
  per FR-B8-SIG-J-001.
- **Grafana LGTM stack migration** — `docs/ARCHITECTURE-TARGET.md`
  ADR-008 ratified KEEP-WITH-CHANGES SigNoz at flagship 1.0.0 →
  2.0.0 ; LGTM swap is a separate B.8.x decision.
- **Envoy Gateway migration** — owned by B.8.4, separate change.
- **DBOS migration** — owned by B.8.5, separate change.
- **Kong removal** — Kong stays at the 1.0.0 baseline (3.6-alpine
  rotted-pin handled by a future B.8.x change, out of trio scope).
- **`coroot` pin refresh or rearch** — owned by `b8-coroot-rehost`
  (archived v0.4.0-rc.3). `versions.coroot` stays at `"1.20.2"` as
  inherited from the pilot.
- **`pin_review_cadence:` retrofit on K.3 or other standards** — this
  change introduces the field on `observability.yaml` only. Broader
  retrofit is a future J.7-class amendment.
- **`signoz-ee` paid edition** — out of forge default ; adopters with
  EE license override locally.
- **SigNoz Cloud hosted variant** — out of scope ; CE binary self-host
  only ratified here.
- **Mobile-only archetype** — SigNoz is full-stack-monorepo only ;
  mobile-only is untouched.
- **ClickHouse data-volume migration tooling** — declared "fresh-start
  only for dev environments" per proposal Scope Out. Prod adopters
  were already on rotted pins, not migrating in place.
- **Constitution amendment** — proposal § Article XII establishes that
  no Article XII amendment is required (additive `pin_review_cadence:`
  field per ADR-J7-008 schema-relaxation precedent ; the breaking
  versions surgery is internal to the standard, not to the Constitution).

---

## Constitutional Compliance Note

- **Article I (TDD non-negotiable)** : harness L1 ≥ 13 tests +
  optional L2 manifest-pull / compose-up fixtures cited per
  Cluster E (FR-B8-SIG-E-001..E-018) ; the RED-GREEN cycle runs
  against the harness before any template, standard, REVIEW.md, or
  CHANGELOG edit. No production code path lands without a paired
  test.
- **Article II (BDD discipline)** : 6 Gherkin scenarios
  (BDD-B8-SIG-001..006) cover the user-facing adopter surfaces (init
  + task dev:up + task validate dev-up-matrix + forge upgrade +
  standards validator + Demeter scan + maintainer harness). Each
  scenario maps to ≥ 1 FR/NFR ID via the BDD ↔ FR mapping table.
- **Article III.1 (Specs Before Code)** : this spec is the gate
  between propose (sealed 2026-05-26) and design. No template,
  standard, REVIEW.md, or harness edit occurs before this file is
  ratified.
- **Article III.3 (RFC 2119)** : MUST / MUST NOT / SHALL / SHOULD /
  MAY used per their RFC 2119 meanings throughout.
- **Article III.4 (Anti-Hallucination)** : 6 Q-NNN tracked in
  `open-questions.md` with `[NEEDS CLARIFICATION:]` markers attached
  to every deferred FR/NFR/BDD. Verify-then-pin pass executed
  pre-spec at 2026-05-26 (T5.3.2 lesson institutionalised).
- **Article IV (Delta-Based Change Management)** : the ADDED /
  MODIFIED / REMOVED format is followed. The 2 MODIFIED entries cite
  source FR by ID (`FR-IN-008`, `FR-IN-012`) and reproduce the prior
  text verbatim. REMOVED entries (3) are defensive against accidental
  re-introduction ; honest count caveat documented inline.
- **Article V (Audit Trail)** : no edits inside other archived
  changes. MODIFIED FRs cite source `.forge/specs/full-stack-monorepo.md`
  by FR ID. The 3-service grep that would have located other MODIFIED
  candidates returns only `.forge/specs/otel-app.md` (descriptive
  prose, no FR assertion) + `.forge/specs/otel-traceparent-e2e.md`
  (BDD prose) — both untouched. `.forge/specs/otel-stack.md::FR-OTEL-*`
  is scoped to OBI + Coroot + sampler, NOT SigNoz services, so it
  remains untouched.
- **Article VIII (Infra excellence + observability mandate)** : this
  change is THE debloque for the `task validate dev-up-matrix` RED
  known-issue carried by v0.4.0-rc.2 / rc.3. Without it, Article
  VIII's "observability is non-negotiable" clause is unenforceable
  in practice for every adopter scaffolding the flagship today.
- **Article XII (Governance)** : no constitution amendment in scope.
  `constitution_version: "1.1.0"` carries forward. The standards
  v1.2.0 → v2.0.0 breaking bump is fully internal to the
  `observability.yaml` standard envelope and uses the WAIVER block +
  ARCH-CHANGE REVIEW.md flag mechanism declared by
  `standards-lifecycle.md` § Bumps. The new `pin_review_cadence:`
  field is additive per ADR-J7-008 schema-relaxation precedent.

---

*Next : `/forge:design b8-signoz-unified`.*
