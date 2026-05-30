# Specifications: b8-1-audit-baseline

<!-- Status: archived -->
<!-- Schema: default -->
<!-- Audit: B.8.1 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0 migration, first item) -->

**Namespace** : `FR-B8-1-*` / `NFR-B8-1-*` / `ADR-B8-1-*`.
**Constitution** : v1.1.0, unchanged. This change authors **no migration
code and no runtime feature**; it is a pure audit artifact (doc + harness +
CI registration). **Article III.4** (Anti-Hallucination) is the governing
article — the baseline records observed reality, never an assumed one.

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4.2 B.8.1 + §4.1 (additive-first strategy) + §4.2 B.8.12/B.8.13 (downstream consumers) |
| **End-to-end path (observed)** | Flutter → `fsm-kong` (`kong:3.6-alpine`) → `fsm-backend` → `fsm-db` (`postgres:16-alpine`) |
| **Dev compose** | `examples/forge-fsm-example/docker-compose.dev.yml` (services enumerated in FR-B8-1-010) |
| **Backend placeholder (observed)** | `docker-compose.dev.yml:58-64` — `fsm-backend` carries `image: scratch` with a `TODO(forge-fsm-example)` Dockerfile note. The 1.0.0 example backend is **not a runnable service**. |
| **Postgres version (observed)** | `postgres:16-alpine` — note: ARCHITECTURE-TARGET §6.1 targets Postgres 17 + pgvector for 2.0.0; the 1.0.0 baseline is 16, no pgvector. |
| **Temporal (observed gap)** | No Temporal service in `docker-compose.dev.yml`; no worker manifest in `examples/forge-fsm-example/infra/`. Temporal is documentary only (`infra/CLAUDE.md:39,97-100`). |
| **Trace topology (observed)** | `demo-005-connect-greeting` 4-span tree, documented `examples/forge-fsm-example/docs/demo-005-connect-greeting.md` |
| **Use-case span** | `backend/crates/application/src/greet.rs:32` — `#[tracing::instrument(name = "greeter.greet", otel.kind = "internal")]` |
| **Server span** | `backend/crates/infrastructure/src/telemetry/middleware.rs:35` — `otel.kind = "server"`, `traceparent` extracted from incoming headers (W3C propagation boundary) |
| **K8s base components** | `examples/forge-fsm-example/infra/k8s/base/` — `coroot-deployment.yaml` (`ghcr.io/coroot/coroot:1.20.2`), `obi-daemonset.yaml` (`grafana/beyla:3.15.0`), `deployment.yaml`, `ingress.yaml` |
| **SigNoz stack (observed)** | unified arch (B.8.8 sibling 2): `signoz/signoz:v0.125.1` + `signoz/signoz-otel-collector:v0.144.4` + `clickhouse/clickhouse-server:25.5.6` + `signoz/zookeeper:3.7.1` |
| **Harness frame** | `--level` parsing + `_helpers.sh` pattern from `t5-3-1.test.sh` / `b8-coroot.test.sh` |
| **L2 opt-in precedent** | `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER` (ADR-T5-OLR-005) |
| **CI matrix budget** | `.github/workflows/forge-ci.yml` 300/300 lines (NFR-CI-002 ceiling) — registration likely needs 3-comment compression per ADR-T533-002 |
| **Downstream consumers** | B.8.12 (regression gate: "0 regression on 4 demos"), B.8.13 (rollback runbook thresholds), B.8.5 (DBOS — inherits Temporal-gap finding) |
| **Release target** | next `0.4.0-rc.x` (Scenario A: v0.4.0 stable from rc.5 first; otherwise next rc) |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Baseline document (FR-B8-1-001 → 050)

##### FR-B8-1-001 — Baseline doc exists and is dated
A baseline document MUST exist at the location ratified by ADR-B8-1-001
(proposal ADR-1; default `docs/B8-BASELINE.md`). It MUST carry a creation
date `2026-05-29` and name the audited archetype + version
`full-stack-monorepo / 1.0.0` verbatim.

##### FR-B8-1-010 — Deployed component matrix
The doc MUST contain a component/version matrix listing every service the
1.0.0 example actually ships, with its pinned image tag. The matrix MUST
include exactly these dev-compose services: `fsm-db` (`postgres:16-alpine`),
`fsm-backend` (placeholder — see FR-B8-1-012), `fsm-kong`
(`kong:3.6-alpine`), `fsm-signoz-zookeeper` (`signoz/zookeeper:3.7.1`),
`init-clickhouse` + `fsm-signoz-clickhouse`
(`clickhouse/clickhouse-server:25.5.6`), `fsm-signoz-otel-collector`
(`signoz/signoz-otel-collector:v0.144.4`), `fsm-signoz` (`signoz/signoz:v0.125.1`).
The matrix MUST also list the K8s-base-only components `coroot`
(`ghcr.io/coroot/coroot:1.20.2`) and `obi`/Beyla (`grafana/beyla:3.15.0`).
Each version MUST be cross-checked against the live file at authoring time
(Article III.4) — no value transcribed from the plan.

##### FR-B8-1-011 — Postgres-16 baseline noted against 2.0.0 target
The matrix MUST flag that 1.0.0 ships `postgres:16-alpine` **without
pgvector**, whereas ARCHITECTURE-TARGET §6.1 targets Postgres 17 + pgvector
for 2.0.0. This is a recorded delta the migration must cross; it MUST NOT be
silently normalized to 17.

##### FR-B8-1-012 — Backend-placeholder finding recorded
The doc MUST record that the 1.0.0 example `fsm-backend` is a placeholder
(`image: scratch`, Dockerfile TODO at `docker-compose.dev.yml:58-64`) and is
therefore **not a runnable service in the dev stack as shipped**. The doc
MUST state the consequence: live end-to-end latency (p50/p95/p99) **cannot
be captured from the example dev compose unmodified**, which is why the
latency baseline is methodology + sample, not committed live numbers
(ADR-B8-1-002).

##### FR-B8-1-013 — Temporal gap recorded (anti-hallucination marquee)
The doc MUST contain an explicit clause stating that **no Temporal worker is
deployed** in the 1.0.0 flagship (no compose service, no infra manifest;
documentary reference only at `infra/CLAUDE.md`). It MUST NOT report a
Temporal MTBF figure. The clause MUST forward this finding to B.8.5 (DBOS):
the "Temporal → DBOS" migration replaces a *documented intent*, not a
running system. A fabricated MTBF in this doc is a hard Article III.4
violation and MUST fail the harness (FR-B8-1-033).

##### FR-B8-1-020 — Trace topology captured
The doc MUST capture the `demo-005-connect-greeting` span tree as the
W3C-trace coverage baseline: the ordered 4-span chain Flutter root → axum
server span (`otel.kind = "server"`) → connectrpc handler → use-case span
`greeter.greet` (`otel.kind = "internal"`), and MUST identify the
process-boundary propagation points where `traceparent` is injected/extracted
(client interceptor → `middleware.rs` server extraction).

##### FR-B8-1-030 — Re-measurement methodology
The doc MUST contain a step-by-step methodology to re-capture the baseline
identically post-migration: how to bring the dev stack up, how to drive
demo-005, and how to read the span tree (and, when a real backend image
exists, latency percentiles) from SigNoz. The methodology MUST be
tool-version-anchored so B.8.12 can re-run it deterministically.

#### Cluster 2 — Static trace-coverage snapshot (FR-B8-1-031 → 040)

##### FR-B8-1-031 — Span inventory checked in
A machine-readable span inventory (named spans + count + `otel.kind`) for
demo-005 MUST be checked into the repo at the location ratified by
ADR-B8-1-001. It MUST be derivable by static inspection of the instrumented
source — no live capture required — so a later harness can assert
"2.0.0 emits ≥ the 1.0.0 span set" without infra.

##### FR-B8-1-032 — Inventory matches source
Every span named in the inventory MUST correspond to an existing
`#[tracing::instrument]` / span-creation site in
`examples/forge-fsm-example/backend/`. The harness MUST cross-check
(FR-B8-1-052). The change MUST NOT add, rename, or remove any instrumentation
span (that is `t5-otel-app` territory).

#### Cluster 3 — Harness (FR-B8-1-050 → 070)

##### FR-B8-1-050 — Harness exists with --level parsing
`.forge/scripts/tests/b8-1.test.sh` MUST exist, follow the `--level`
convention (default 1), and emit the standard `Passed/Failed/Failures`
summary with non-zero exit on any failure.

##### FR-B8-1-051 — L1 assertions (hermetic, grep-based)
L1 MUST assert: (i) baseline doc present + dated (FR-B8-1-001), (ii)
component matrix lists the enumerated services + pins (FR-B8-1-010), (iii)
Postgres-16 delta clause present (FR-B8-1-011), (iv) backend-placeholder
clause present (FR-B8-1-012), (v) Temporal-gap clause present **and** no
MTBF figure (FR-B8-1-013/033), (vi) span-tree section present with the 4
named spans (FR-B8-1-020), (vii) span inventory present + cross-checks
against backend source (FR-B8-1-032).

##### FR-B8-1-033 — Negative assertion on fabricated MTBF
L1 MUST FAIL if the baseline doc contains a Temporal MTBF measurement
(e.g. a numeric `MTBF` / `mean time between failures` value adjacent to
"Temporal"). This guards against a future edit silently inventing one.

##### FR-B8-1-060 — L2 live-trace check (opt-in)
L2, gated behind `FORGE_B8_1_DOCKER=1` and skip-passing when Docker or the
toolchain is absent, MUST bring the dev stack up, drive demo-005, and assert
SigNoz returns a non-empty trace whose span set is a superset of the checked-in
inventory. It MUST honor the backend-placeholder reality: if the backend is
still a placeholder, L2 asserts trace *topology* reachable up to the gateway
boundary and documents the truncation rather than failing.

#### Cluster 4 — Integration (FR-B8-1-080 → 100)

##### FR-B8-1-080 — CI registration within budget
`b8-1.test.sh` MUST be registered in `.github/workflows/forge-ci.yml::harness`
matrix. Total workflow length MUST stay ≤ 300 lines (NFR-CI-002); the
3-comment compression precedent (ADR-T533-002) MAY be used.

##### FR-B8-1-090 — CHANGELOG entry
A `[Unreleased]` CHANGELOG entry MUST cite `b8-1-audit-baseline` and B.8.1.
(Per this session's `t5-cargo` lesson, any harness changelog assertion MUST
grep the whole file, not the `[Unreleased]` section, to survive release
graduation.)

##### FR-B8-1-100 — Consolidated spec
A consolidated spec `.forge/specs/b8-baseline.md` MUST be created for the
`FR-B8-1-*` namespace, consistent with the one-spec-per-namespace convention.

### Non-Functional Requirements

##### NFR-B8-1-001 — Hermetic + fast L1
`b8-1.test.sh --level 1` MUST run with zero network and zero Docker, wall-clock
≤ 5 s (mirrors NFR-J7-001 / NFR-K3-DEM budgets).

##### NFR-B8-1-002 — Zero mutation of templates / standards / schema
The change MUST NOT edit any `.forge/templates/**`, `.forge/standards/**`, or
`.forge/schemas/**` file. Verified by `git diff --name-only` scope in review.

##### NFR-B8-1-003 — Determinism
The span inventory and any committed sample capture MUST be byte-stable
across re-runs (`SOURCE_DATE_EPOCH` where timestamps are unavoidable).

##### NFR-B8-1-004 — Backward compatibility
No adopter scaffold changes; `forge upgrade` unaffected (no owned-path
touched). `a7.test.sh` MUST stay GREEN.

## BDD Acceptance Criteria

Only the L2 opt-in live-trace check is observable behavior:

```gherkin
Scenario: Baseline trace topology is reproducible from the dev stack
  Given the forge-fsm-example dev stack is brought up with FORGE_B8_1_DOCKER=1
  And the SigNoz unified stack is healthy
  When demo-005-connect-greeting is driven end to end
  Then SigNoz returns at least one trace for the request
  And the trace's span set is a superset of the checked-in demo-005 inventory
  And if fsm-backend is a placeholder, the harness records the span-tree
      truncation at the gateway boundary instead of failing
```

## Anti-Hallucination Pass

- **Temporal MTBF** — REMOVED from scope as a measurable; recorded as a gap
  (FR-B8-1-013) with a negative harness guard (FR-B8-1-033). Source: absence
  in `docker-compose.dev.yml` + `infra/` verified 2026-05-29.
- **Backend placeholder** — the plan's "p95/p99 end-to-end" assumed a
  running backend; observed reality is `image: scratch`. Captured as
  FR-B8-1-012; drives ADR-B8-1-002 (methodology over live numbers).
- **Postgres version** — plan/target says 17+pgvector; 1.0.0 observed = 16,
  no pgvector. Captured as FR-B8-1-011, not normalized.
- **[NEEDS CLARIFICATION]** — none outstanding inline; open design choices
  are tracked as Q-001..Q-003 in `open-questions.md`, not as code-blocking
  ambiguities.

## Open Questions

Tracked in `open-questions.md`: Q-001 (doc location, → ADR-B8-1-001), Q-002
(latency form, → ADR-B8-1-002), Q-003 (flagship-only vs also mobile-only
baseline — lean flagship-only per plan §4.2).
