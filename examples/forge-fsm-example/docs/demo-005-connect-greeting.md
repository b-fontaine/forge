# demo-005 — connect-greeting traceparent round-trip

<!-- Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation -->

This demo extends `demo-002-greeting-screen` (Flutter UI + Greeter Cubit)
and `demo-001-greeting-service` (Rust Greeter use case) by wiring a
**distributed trace** that flows from the Flutter UI through the Rust
backend and back, with a single W3C `traceparent` header carrying the
context across the network hop.

## What you get

When the user types a name and taps **Greet** :

1. The Flutter `GreetingCubit` emits a `GreetEvent` — captured by the
   `TracingBlocObserver`.
2. `GreetingRepositoryImpl` calls the Connect/Dart client ; the underlying
   `dio` instance carries the `TracingInterceptor` which starts a
   `client` span and injects the W3C `traceparent` header on the outbound
   POST `/connect/greeting.v1.GreeterService/Greet`.
3. The Rust axum router applies `tower-http::TraceLayer::new_for_http()`
   with the `make_span_with` closure that extracts the inbound
   `traceparent` and creates a `server` span linked to the parent context.
4. The connectrpc handler dispatches to the `GreetUseCase`, annotated
   with `#[tracing::instrument(name = "greeter.greet", ...)]` ; the
   `tracing-opentelemetry` bridge automatically chains this `internal`
   span as a child of the server span.
5. All four spans share the same `traceId` and land in SigNoz via the
   collector :4318 OTLP HTTP receiver.

## Trace this in SigNoz

Three steps, exactly as adopters would run them on a fresh checkout :

### 1. Spin up the local dev cluster

```bash
cd examples/forge-fsm-example
task dev
```

`task dev` orchestrates `docker-compose.dev.yml` :

- `fsm-db` (Postgres).
- `fsm-otel-collector` (OTel Collector with the
  `processors.probabilistic_sampler` from Phase A).
- `fsm-signoz` (the SigNoz UI — `http://localhost:3301`).
- `fsm-backend` (the Rust bin-server with `OTEL_EXPORTER_OTLP_ENDPOINT`
  pointed at the collector).
- `fsm-frontend` (a Flutter web build served behind the Kong gateway,
  with `--dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=...` matching the
  collector).

### 2. Trigger the round trip

- Open the Flutter app at `http://localhost:8080`.
- Type a name into the **Audience name** field (e.g. `Forge`).
- Tap **Say hello**.

### 3. Read the trace tree in SigNoz

- Open SigNoz at `http://localhost:3301`.
- Navigate to **Traces**.
- Filter by `service.name = fsm-frontend` to find the most recent click.
- Click into the trace — you should see four spans on the timeline :

   ```
   ◯ [Flutter] user.interaction greet              (root span)
     ◯ [Flutter] POST /connect/greeting.v1.GreeterService/Greet  (client)
       ◯ [Rust]    http.request                              (server)
         ◯ [Rust]    greeter.greet                          (internal)
   ```

   All four carry the **same `traceId`** ; the parent / child links are
   visible in the SigNoz waterfall view.

## Troubleshooting

- **No spans in SigNoz** : check the collector's debug exporter
  (`docker logs fsm-otel-collector | grep -i error`). The collector
  rejects spans where `service.name` is missing — that should never
  happen if the SDK init follows the standards verbatim.
- **Two trace trees instead of one** : the `traceparent` header is not
  reaching the backend. Check that the Flutter `TracingInterceptor` is
  attached to the dio client (see `greeting_repository_impl.dart`) and
  that the Rust `TraceLayer` is using
  `otel_make_span_with_traceparent_extraction` (see
  `crates/infrastructure/src/telemetry/middleware.rs`).
- **Spans without `host.name`** : the `hostname` crate cannot read the
  hostname inside some sandboxed runtimes ; the SDK falls back to
  `"unknown"`. Cosmetic — does not break the trace tree.

## Related

- Phase A — `t5-otel-stack` (archived 2026-05-10) : the infra side
  (collector, OBI, Coroot, sampler ratios).
- Phase C — Envoy / Kong end-to-end traceparent (deferred ;
  `_test_t5_l2_traceparent_dual` in
  `.forge/changes/t5-connect-codegen/tasks.md` § DEFERRED).
- Standards : `.forge/standards/rust/opentelemetry.md`,
  `.forge/standards/flutter/opentelemetry.md`,
  `.forge/standards/observability.yaml`.
