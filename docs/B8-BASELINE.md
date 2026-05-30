# B.8 Flagship Baseline — `full-stack-monorepo / 1.0.0`

<!-- Created: 2026-05-29 -->
<!-- Audit: B.8.1 (b8-1-audit-baseline) — docs/new-archetypes-plan.md §4.2 -->
<!-- Consumed by: B.8.12 (regression gate), B.8.13 (rollback runbook), B.8.5 (DBOS) -->

This document freezes the **measurable characteristics of the
`full-stack-monorepo / 1.0.0` flagship as it stands today**, before any
B.8 migration template (Envoy / DBOS / Connect / Zitadel) touches it. It is
the comparison anchor for the flagship `1.0.0 → 2.0.0` migration: B.8.12
re-runs the methodology below to prove "0 regression on the 4 demos", and
B.8.13's rollback runbook cites these reference points.

Every value here was **re-read from the live repository at authoring time**
(Article III.4); none is transcribed from the plan. Where the observed
reality contradicts the plan's assumptions, the contradiction is recorded,
not normalized.

## 1. Deployed component matrix

Source: `examples/forge-fsm-example/docker-compose.dev.yml` (dev stack) and
`examples/forge-fsm-example/infra/k8s/base/` (K8s-only components).

| Service | Image pin | Layer | Notes |
|---------|-----------|-------|-------|
| `fsm-db` | `postgres:16-alpine` | data | Postgres **16**, no pgvector — see §2 |
| `fsm-backend` | _placeholder_ (`image: scratch`) | backend | **Not runnable** — Dockerfile TODO, see §3 |
| `fsm-kong` | `kong:3.6-alpine` | gateway | API gateway (Kong → Envoy in 2.0.0) |
| `fsm-signoz-zookeeper` | `signoz/zookeeper:3.7.1` | observability | SigNoz unified stack (B.8.8 sibling 2) |
| `init-clickhouse` | `clickhouse/clickhouse-server:25.5.6` | observability | init job (one-shot) |
| `fsm-signoz-clickhouse` | `clickhouse/clickhouse-server:25.5.6` | observability | trace store |
| `fsm-signoz-telemetrystore-migrator` | `signoz/signoz-otel-collector:v0.144.4` | observability | init job (one-shot, `restart: on-failure`) |
| `fsm-signoz-otel-collector` | `signoz/signoz-otel-collector:v0.144.4` | observability | OTLP ingest |
| `fsm-signoz` | `signoz/signoz:v0.125.1` | observability | UI + query (unified image) |
| `coroot` (K8s base only) | `ghcr.io/coroot/coroot:1.20.2` | observability | B.8.8 Coroot leg (ghcr rehost) |
| `obi` / Beyla (K8s base only) | `grafana/beyla:3.15.0` | observability | B.8.8 OBI leg (eBPF DaemonSet) |

The observability triplet reflects the **B.8.8 trio closure**
(`observability.yaml` v2.1.0): SigNoz unified, Coroot ghcr `1.20.2`, Beyla
`3.15.0`.

## 2. Postgres 16 → 17 delta (recorded, not normalized)

1.0.0 ships `postgres:16-alpine` **without pgvector**.
`docs/ARCHITECTURE-TARGET.md` §6.1 targets **Postgres 17 + pgvector** as the
universal default for 2.0.0. This is a delta the migration must cross
(B.8.5 DBOS state tables + B.7 `ai-native-rag` pgvector both depend on it).
The baseline records the gap; it MUST NOT be silently bumped to 17 outside a
scoped migration change.

## 3. Backend-placeholder finding

The 1.0.0 example `fsm-backend` is a **placeholder**: `docker-compose.dev.yml`
(lines 58–64) carries `image: scratch` with a `TODO(forge-fsm-example)`
Dockerfile note. **The example backend is not a runnable service in the dev
stack as shipped.**

Consequence: **live end-to-end latency (p50/p95/p99) cannot be captured from
the example dev compose unmodified.** This is why the latency baseline
(§6) is a re-measurement *methodology* plus an optional non-normative
sample, not committed live numbers (ADR-B8-1-002). The rollback thresholds
in B.8.13 ("p99 +20 % after Envoy") are **relative deltas measured during
the migration window** on a real backend image — not comparisons against a
frozen 1.0.0 number that does not exist today.

## 4. Temporal gap (anti-hallucination marquee)

**No Temporal worker is deployed in `full-stack-monorepo / 1.0.0`.** There is
no Temporal service in `docker-compose.dev.yml` and no worker manifest in
`examples/forge-fsm-example/infra/`. Temporal exists only as *documentary*
scaffolding (`infra/CLAUDE.md`: "activate when touching Temporal namespace /
worker deployment").

Therefore **there is no Temporal MTBF to report**, and none is fabricated
(the harness `_test_b81_l1_006_no_fabricated_mtbf` fails the build if a
numeric MTBF ever appears here).

**Forward-pointer to B.8.5 (DBOS):** the "Temporal → DBOS" migration replaces
a *documented intent*, not a running system. The DBOS leg is therefore
**lower-risk** than plan §4.2 assumed — there is no live Temporal workflow
state to migrate, only template + doc scaffolding to swap.

## 5. W3C trace coverage (demo-005 span tree)

The `demo-005-connect-greeting` round-trip is the flagship's trace-coverage
reference. Machine-readable inventory:
`.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml`.

**Code-verified spans (3 distinct instrument sites):**

1. **`<http-method> <path>`** (dynamic, e.g.
   `POST /connect/greeting.v1.GreeterService/Greet`) — `otel.kind = client` —
   Flutter dio `TracingInterceptor`
   (`frontend/.../interceptors/tracing_interceptor.dart`, span name built from
   `'${options.method} ${_sanitizePath(options.path)}'`, marker
   `SpanKind.client`). Emits the client span and **injects** the W3C
   `traceparent` header on the outbound call.
2. **`http.request`** — `otel.kind = server` — Rust tower-http
   `make_span_with` (`backend/.../telemetry/middleware.rs`, marker
   `otel.kind = "server"`). **Extracts** the inbound `traceparent` and links
   to the parent context (the cross-process propagation boundary).
3. **`greeter.greet`** — `otel.kind = internal` — `GreetUseCase`
   `#[tracing::instrument]` (`backend/.../application/src/greet.rs`), child of
   the server span.

**4-span-vs-3-span discrepancy (recorded):** the demo-005 doc waterfall
(`examples/forge-fsm-example/docs/demo-005-connect-greeting.md` §3, the
ASCII trace tree) draws a **4-span tree**:

```
◯ [Flutter] user.interaction greet              (root span)   ← PHANTOM
  ◯ [Flutter] POST /connect/.../Greet           (client)      ← span 1 above
    ◯ [Rust]  http.request                      (server)      ← span 2 above
      ◯ [Rust] greeter.greet                    (internal)    ← span 3 above
```

Only **three** of these are real instrument sites. The phantom span is the
**Flutter `user.interaction greet` root span** — there is no
`startSpan('user.interaction …')` anywhere in `frontend/lib` (the dio
`TracingInterceptor` emits the `client` span for the outbound POST, the bloc
observer emits `<Bloc>.<Event>` spans, the navigation observer emits
`navigation.push …` — none emits `user.interaction greet`). The connectrpc
POST **is** the real client span (span 1 above), *not* a missing 4th span.
B.8.12 MUST assert the 3 code-verified spans above, not the doc's phantom
Flutter root. (The demo-005 doc itself should be corrected to drop or
instrument that root span — forward-pointer for a follow-up.)

**Propagation boundary:** a single `traceparent` is injected by the Flutter
client span and extracted by the Rust server span; all spans share one
`traceId`.

## 6. Re-measurement methodology (deterministic procedure)

This procedure is the deterministic baseline artifact (ADR-B8-1-002). B.8.12
re-runs it against `2.0.0` for a like-for-like comparison.

**Prerequisites:** Docker + Docker Compose; the dev stack toolchain. Pin the
toolchain versions used for any measurement run in the run notes so the
comparison is apples-to-apples.

**Steps:**

1. **Bring the stack up** from `examples/forge-fsm-example/`:
   `docker compose -f docker-compose.dev.yml up -d`. Wait for the SigNoz
   unified stack to report healthy (`fsm-signoz` UI at
   `http://localhost:3301`).
2. **Drive demo-005**: open the Flutter app (`http://localhost:8080`,
   behind the Kong gateway) and trigger a greeting, or replay the demo-005
   request against the gateway.
3. **Read the trace tree** in SigNoz: filter by service, open the trace for
   the demo-005 request, confirm the span set matches §5 (`http client
   request` → `http.request` → `greeter.greet`, one shared `traceId`).
4. **Latency (when a real backend image exists):** read p50/p95/p99 from
   SigNoz for the demo-005 endpoint over a fixed request count. **Today the
   backend is a placeholder (§3), so this step yields only gateway-boundary
   latency** — record the truncation, do not report an end-to-end number.

**Sample capture:** _none committed._ Any sample attached in a future run is
**non-normative** and MUST carry hardware/context caveats; it is never the
baseline truth (ADR-B8-1-002).

## 7. Migration deltas this baseline anchors

| 1.0.0 (baseline) | 2.0.0 (target) | B.8 item |
|------------------|----------------|----------|
| Kong gateway | Envoy Gateway | B.8.4 |
| Temporal (doc only — §4) | DBOS embedded | B.8.5 |
| REST-bridge | Connect-RPC | B.8.6 |
| implicit auth | Zitadel | B.8.7 |
| Postgres 16, no pgvector (§2) | Postgres 17 + pgvector | B.8.5 / B.7 |
| placeholder backend (§3) | real backend image | B.8.x |

## 8. Constraints honored

- No `.forge/templates/**`, `.forge/standards/**`, `.forge/schemas/**` file
  is touched by this change (NFR-B8-1-002). Pure audit artifact.
- `forge upgrade` is unaffected (no owned path) — `a7.test.sh` stays GREEN.
- The span inventory carries no timestamps; it is byte-stable
  (NFR-B8-1-003).
