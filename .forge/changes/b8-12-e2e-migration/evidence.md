# Evidence — b8-12-e2e-migration

<!-- Status: designed -->
<!-- Audit: B.8.12 (b8-12-e2e-migration) — E2E migration convergence gate.
     MIXED evidence: (a) EXTERNAL verify-then-pin (URLs) for the connectrpc 0.6.x
     CLIENT API + Envoy Gateway SecurityPolicy/JWT shape + Zitadel OIDC discovery,
     collected LIVE 2026-06-04 by the main thread; (b) INTERNAL-FILE evidence
     (file:line) for the baseline span-inventory, the migration driver, the
     t5-otel-live-run fake-OTLP pattern, the standards pins, the CI-no-toolchain
     reality, and the no-committed-latency ADR chain. Article III.4: every
     ADR-B812-001..004 fact in design.md traces to a P-NN row here; no connectrpc
     client symbol, Envoy API string, or Zitadel jwks path is fabricated beyond
     what these rows quote. Items flagged VERIFY-AT-IMPLEMENT are re-confirmed
     LIVE at /forge:implement before any template line is authored (b8-coroot
     lesson). -->

**Collection timestamp**: 2026-06-04 (external URLs fetched + on-disk re-reads by
the main orchestration thread; authoritative). Internal facts are file-state reads
of the working tree at `/Users/bfontaine/git/github/forge` on `main`.

**Re-verify obligation (verify-then-pin LIVE at `/forge:implement`)**: the
connectrpc 0.6.x client API symbols, the connectrpc `client` Cargo feature flag
name, the Envoy Gateway `SecurityPolicy` apiVersion/kind + JWT provider shape, the
Zitadel OIDC discovery `jwks_uri` path, and the backend JWT validation middleware
(tower layer) shape are ALL re-read LIVE at `/forge:implement` before the template
files are authored (b8-coroot lesson: verify-then-pin runs live at implement, not
trusted from this design transcript). If the upstream API has drifted, the affected
template falls back per ADR-B812-002 (no fabrication — ADR-B87-006).

---

## Provenance Table — EXTERNAL (verify-then-pin, source URLs)

| ID | Source URL | Read | Agent | What it proves |
|----|------------|------|-------|----------------|
| P-01 | `https://raw.githubusercontent.com/anthropics/connect-rust/main/README.md` | 2026-06-04 | main thread | **connectrpc 0.6.x Rust CLIENT API.** `use connectrpc::client::{HttpClient, ClientConfig, CallOptions};`. Construction: `let http = HttpClient::plaintext();` (cleartext) or `HttpClient::...with_tls()` (https); `let config = ClientConfig::new("http://host:8080".parse()?).with_default_timeout(Duration::from_secs(30)).with_default_header("authorization", "Bearer ...");`; `let client = GreetServiceClient::new(http, config);` (generated `<Svc>Client::new(http, config)`). Calls: `client.greet(req).await?` + per-call `client.greet_with_options(req, CallOptions::default().with_timeout(Duration::from_secs(5)))` (per-call overrides config defaults). This is the S2S surface for `transport_connect_client.rs.tmpl` (ADR-B812-003). |
| P-02 | `https://api.github.com/repos/envoyproxy/gateway/releases` (latest) | 2026-06-04 | main thread | Envoy Gateway latest release = **v1.8.0** (2026-05-13). MATCHES the B.8.4 `gateway.yaml` chart pin `envoy_gateway_chart: "v1.8.0"` (P-13). No chart bump is required for B.8.12 — the SecurityPolicy/JWT templates target the SAME control-plane version already pinned. |
| P-03 | `https://gateway.envoyproxy.io/docs/tasks/security/jwt-authentication/` (latest = v1.8) | 2026-06-04 | main thread | **Envoy Gateway SecurityPolicy + JWT shape (v1.8.0).** `apiVersion: gateway.envoyproxy.io/v1alpha1`, `kind: SecurityPolicy`; `spec.targetRef` → `{group: gateway.networking.k8s.io, kind: HTTPRoute, name: <route>}`; `spec.jwt.providers[].name` + `spec.jwt.providers[].remoteJWKS.backendRefs[{group: gateway.envoyproxy.io, kind: Backend, name: <jwks-backend>, port: 443}]` (+ optional `issuer` / `audiences`). v1.8 uses the `remoteJWKS.backendRefs`→`Backend` form (NOT a bare `remoteJWKS.uri` field). Grounds ADR-B812-002 SecurityPolicy template. VERIFY-AT-IMPLEMENT: re-confirm `remoteJWKS.backendRefs` vs any `uri` shorthand against the v1.8.x docs at implement. |
| P-04 | OIDC Core + Zitadel discovery convention (standard `.well-known`) | 2026-06-04 | main thread | **Zitadel OIDC discovery.** Standard OIDC: the issuer `https://<ExternalDomain>` exposes `/.well-known/openid-configuration`; the `jwks_uri` therein resolves to the Zitadel keys endpoint (commonly `/oauth/v2/keys`). The issuer = the `zitadel.configmapConfig.ExternalDomain` from the b8-7 `values-forge` overlay. **VERIFY-AT-IMPLEMENT**: the EXACT jwks path is read from the live discovery doc at implement; do NOT hardcode `/oauth/v2/keys` as a fact beyond the discovery URL (`https://<ExternalDomain>/.well-known/openid-configuration`). ADR-B87-006 barred fabricating the Zitadel issuer URL pattern — only the discovery URL is pinned here. |

## Provenance Table — INTERNAL (file:line, not URLs)

| ID | Source (file:line) | Read | What it proves |
|----|--------------------|------|----------------|
| P-10 | `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml:20-46` | 2026-06-04 | **Before-state baseline.** `archetype: full-stack-monorepo`, `version: "1.0.0"`, `captured: "2026-05-29"`, `demo: demo-005-connect-greeting`, exactly **3 code-verified spans**: (1) `name: "<http-method> <path>"`, `otel_kind: client`, `layer: frontend`, `verified_marker: "SpanKind.client"` (dio interceptor, `tracing_interceptor.dart`); (2) `name: "http.request"`, `otel_kind: server`, `verified_marker: 'otel.kind = "server"'` (tower-http, `middleware.rs`); (3) `name: "greeter.greet"`, `otel_kind: internal`, `verified_marker: 'name = "greeter.greet"'` (`#[tracing::instrument]`, `greet.rs`). Grounds FR-B812-002. |
| P-11 | `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml:9-18,48-55` (4-vs-3-span note) | 2026-06-04 | **Phantom-span HARD FACT.** The demo-005 doc waterfall draws a 4-span tree; only 3 are real instrument sites. The PHANTOM is the Flutter `user.interaction greet` ROOT — no `startSpan('user.interaction …')` in `frontend/lib`. The connectrpc POST IS the real client span (span 1). B.8.12 asserts the 3 spans, not the phantom. Grounds FR-B812-003 (negative guard: `user.interaction` absent from both goldens). |
| P-12 | `bin/forge-migrate-flagship.sh:110-167` (`_b810_phase0_preflight`) | 2026-06-04 | **Phase 0 preflight + exit-7 envelope.** Reads `<target>/.forge/scaffold-manifest.yaml` via python3-inline; `ver = str(d.get("archetype_version", ""))`; emits `wrong-version:%s` and routes to `exit 7` (L132/L141-143) when `archetype_version != 1.0.0`; missing-manifest/not-1.0.0 → `exit 7` (L140/L146/L153/L160/L167). Grounds FR-B812-010 (Phase 0 passes on 1.0.0) + FR-B812-015 (exit 7 on wrong-version). |
| P-13 | `bin/forge-migrate-flagship.sh:1-44` (header + flags + invariants) | 2026-06-04 | **Driver surface.** `--target <dir>` / `--phase 0\|1\|2\|3\|4\|all` / `--dry-run` / `--force` / `--rollback` / `--help\|-h`; exit-codes `0/2/5/7/8` (`1` deliberately unused). Constitutional invariant (L31-34): "ADDITIVE-ONLY: never removes Kong, Temporal, or REST-bridge paths (VIII.1/VIII.2 SHALL clauses binding until B.8.14). FR-B810-031." Grounds FR-B812-013/014 (additive overlay) + NFR-B812-008. |
| P-14 | `bin/forge-migrate-flagship.sh:178-183` (dry-run additive-delta block) | 2026-06-04 | **Dry-run plan lines.** `"- Kong → Envoy Gateway          (B.8.4)"`, `"- REST-bridge → Connect-RPC      (B.8.6)"`, `"- implicit-auth → Zitadel        (B.8.7)"`, `"- no-web → Qwik web-public       (B.8.9)"`, `"- postgres-16 → 17 + pgvector    (B.8.5)"`, and the invariant line `"(Kong / Temporal / REST preserved — additive only, removal is B.8.14.)"`. Grounds FR-B812-011 (dry-run grep assertions). |
| P-15 | `.forge/scripts/tests/t5-otel-live-run.test.sh:105-119` (`_test_olr_002_collector_stdlib_only`) | 2026-06-04 | **Stdlib-only guard pattern.** Forbidden-import list `("protobuf" "google.protobuf" "grpc" "requests" "httpx" "yaml" "opentelemetry")`; `grep -qE "^(import\|from)[[:space:]]+${mod}([[:space:]]\|\.\|$)"` → FAIL. Mirrored by FR-B812-063 for any B.8.12 fake-OTLP collector artifact. |
| P-16 | `.forge/scripts/tests/t5-otel-live-run.test.sh:249-265` (`_test_olr_020_goldens_sanitised`) | 2026-06-04 | **Sanitiser pattern.** Each golden MUST contain `'"<ts:redacted>"'` (timestamp placeholder) and MUST NOT match `'"([0-9]{1,3}\.){3}[0-9]{1,3}"'` (no IPv4 dotted-quad). Grounds FR-B812-004 + NFR-B812-006. |
| P-17 | `.forge/scripts/tests/t5-otel-live-run.test.sh:122-196` (`_test_olr_003/004/005` driver + `diff -q` golden) | 2026-06-04 | **Golden capture-and-diff pattern.** `bash "$DRIVER_SH" --out "$tmpdir" --scenario direct\|kong`; capture appears as `$tmpdir/capture-*.json`; `diff -q "$cap" "$GOLDEN"` → FAIL on mismatch. `_skip_if_no_toolchain python3` returns 0 (skip-pass) when python3 absent. Grounds FR-B812-005 (golden superset via `diff -q`, hermetic). |
| P-18 | `examples/forge-fsm-example/test/live-run/fake_otlp_collector.py:25-32` (imports) | 2026-06-04 | **Reusable collector is stdlib-only.** Imports: `argparse`, `json`, `os`, `re`, `signal`, `sys`, `threading`, `http.server.{BaseHTTPRequestHandler, ThreadingHTTPServer}` — zero third-party. B.8.12's after-capture reuses this collector + `run_smoke.sh` (`--out`/`--scenario`/`--probe-only`, capture-NNN.json, L22-27/L89/L129) directly; no new collector artifact is required. |
| P-19 | `examples/forge-fsm-example/.forge/changes/demo-00{1,2,3}-*/features/*.feature` | 2026-06-04 | **Demo feature-file canonical paths (CORRECTS the spec guess).** The demo `.feature` files live at `examples/forge-fsm-example/.forge/changes/demo-001-greeting-service/features/greeter.feature`, `.../demo-002-greeting-screen/features/greeting_screen.feature`, `.../demo-003-rate-limit/features/rate_limit.feature` — NOT under `test/features/` (the spec FR-B812-020 path guess). demo-004-user-onboarding has NO `features/` dir (it is frozen at `specified`). Grounds FR-B812-020/023 path resolution (ADR-B812-004). |
| P-20 | `examples/forge-fsm-example/.forge/changes/demo-004-user-onboarding/.forge.yaml:1-2` | 2026-06-04 | **demo-004 status + location.** `name: demo-004-user-onboarding`, `status: specified` — lives INSIDE the c1 example tree (`examples/forge-fsm-example/.forge/changes/`), NOT the top-level `.forge/changes/`. The overlay targets `examples/forge-fsm-example/` and never touches this metadata. Grounds FR-B812-022 path resolution. |
| P-21 | `examples/forge-fsm-example/.forge/scaffold-manifest.yaml:1-2` | 2026-06-04 | `archetype: full-stack-monorepo`, `archetype_version: 1.0.0`. The committed c1 reference is 1.0.0; the migration runs against a tmpdir COPY (ADR-B812-004); the committed example stays 1.0.0 (FR-B812-012, NFR-B812-010). |
| P-22 | `examples/forge-fsm-example/shared/protos/` (listing) | 2026-06-04 | c1 proto contracts: `v1/`, `buf.gen.yaml`, `buf.yaml`. These adopter `.proto` files are PRESERVED paths in the A.7 3-way merge (additive overlay never overwrites them). Grounds FR-B812-021. |
| P-23 | `.forge/standards/transport.yaml:114-120` (`versions_2_0_0:` block) | 2026-06-04 | **Authoritative 2.0.0 Connect pins.** `versions_2_0_0:` → `connectrpc: "=0.6.1"`, `connectrpc-build: "=0.6.1"`, `buffa: "=0.6.0"`, `buffa-types: "=0.6.0"` (verified LIVE 2026-06-02, ADR-B86-001 re-verify clause). The client template + companion Cargo.toml.tmpl couple to these pins. Grounds FR-B812-031/035. NOT bumped by B.8.12. |
| P-24 | `.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl:43-45` | 2026-06-04 | **Cargo feature gap (VERIFY-AT-IMPLEMENT carry).** Current: `connectrpc = { version = "=0.6.1", features = ["axum"] }`, `buffa = "=0.6.0"`, `buffa-types = "=0.6.0"`. The `axum` feature gates the SERVER surface (`into_axum_service`). The S2S CLIENT (`connectrpc::client::HttpClient`, P-01) likely needs an additional `client` feature. **VERIFY-AT-IMPLEMENT**: confirm the EXACT connectrpc 0.6.1 feature flag name for the client surface (`client` vs feature-implied-by-default) against the live crate `Cargo.toml`/docs; then either add it to `features = ["axum", "client"]` OR document that the client surface is feature-implied. Do NOT fabricate the flag name at design. Grounds ADR-B812-003 carry item + FR-B812-031. |
| P-25 | `.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/src/transport_connect.rs.tmpl:55-125` | 2026-06-04 | **Server-only adapter (the parallel for the new client).** The 2.0.0 `transport_connect.rs.tmpl` is server-only: `use connectrpc::{ConnectError, Context, Router as ConnectRouter}`, `pub fn into_router<U>(...) -> Router`, `ConnectRouter::new().into_axum_service()`. NO `ClientConfig`/`CallOptions`/`HttpClient`. Byte-frozen by B.8.12 (FR-B812-033). The new `transport_connect_client.rs.tmpl` is a SIBLING file (P-01 client API), not an edit to this one. |
| P-26 | `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/` (listing) | 2026-06-04 | **Existing B.8.4 envoy-gateway dir (the join point).** Present: `README.md.tmpl`, `backendtlspolicy.yaml.tmpl`, `gateway.yaml.tmpl`, `gatewayclass.yaml.tmpl`, `httproute.yaml.tmpl`, `kustomization.yaml.tmpl`. The new SecurityPolicy + JWT templates JOIN this dir (FR-B812-040). |
| P-27 | `.forge/templates/.../2.0.0/infra/k8s/envoy-gateway/{gateway,httproute}.yaml.tmpl:6-9` | 2026-06-04 | **Existing apiVersion convention.** `gateway.yaml.tmpl` + `httproute.yaml.tmpl` use `apiVersion: gateway.networking.k8s.io/v1` (standard Gateway API) for `Gateway`/`HTTPRoute`. The NEW `SecurityPolicy` uses the Envoy-SPECIFIC `apiVersion: gateway.envoyproxy.io/v1alpha1` (P-03) — a different API group, correct for the Envoy extension. The `kustomization.yaml.tmpl` must list the new resource files (carry item). |
| P-28 | `.forge/standards/gateway.yaml:7-8,19,43-51` | 2026-06-04 | **Gateway chart pin (consumed, not bumped).** `version: "1.0.0"`; `envoy_gateway_chart: "v1.8.0"`, `gateway_api_bundle: "v1.5.1"`, `controller_name: gateway.envoyproxy.io/gatewayclass-controller`. The SecurityPolicy/JWT templates are served by the SAME v1.8.0 control plane (P-02). B.8.12 bumps NO standard. |
| P-29 | `.forge/standards/identity.yaml:15,43-46` | 2026-06-04 | **Zitadel identity pins (cross-ref, not bumped).** `version: "1.1.0"`; `zitadel_chart: "10.0.2"`, `zitadel: "v4.14.0"`, `zitadel_login: "v4.14.0"` (ghcr.io, v-prefix). The Envoy-OIDC templates carry an `identity.yaml@1.1.0` cross-reference comment (FR-B812-044). NOT bumped by B.8.12. |
| P-30 | `docs/B8-BASELINE.md §3 / §6` + ADR-B8-1-002 (referenced via b8-1) | 2026-06-04 | **No-committed-latency ADR chain.** ADR-B8-1-002 ratified: live p50/p95/p99 "cannot be captured from the example dev compose unmodified" (`fsm-backend` = `image: scratch`, FR-B8-1-012); §6 methodology committs "none" — methodology + optional sample, NEVER committed live numbers. Grounds ADR-B812-001 (negative guard FR-B812-006/051) + III.4. |
| P-31 | `.github/workflows/forge-ci.yml:88,106,115-117` (harness registration tail) | 2026-06-04 | **CI registration insertion point + no-toolchain reality.** `"t5-otel-live-run.test.sh --level 1"` (L88), `"b8-1.test.sh --level 1"` (L106), `"b8-10.test.sh --level 1"` (L115), `"b8-11.test.sh --level 1"` (L116), `"b8o.test.sh --level 1"` (L117). `b8-12.test.sh --level 1` appends after L116/L117 (the last b8-N entry, `harnesses=()` array form). CI runs Python+Node+shellcheck only — NO cargo/flutter/docker; every harness is `--level 1`. Grounds FR-B812-066 + the L2 opt-in posture (FR-B812-034/064/065). |
| P-32 | `.forge/scripts/tests/b8-1.test.sh` + `.forge/scripts/tests/b8-10.test.sh` (coupling guards) | 2026-06-04 | **Coupling-guard targets.** `b8-1.test.sh --level 1` (baseline 3-span inventory + anti-faked-latency invariants) and `b8-10.test.sh --level 1` (migration-script invariants) are the two exit-0 coupling guards B.8.12 re-runs (FR-B812-068). Pattern mirrors b8-10's `T-011` (b8-2/b8-3 coupling) and b8-11's `T-013/T-014`. |
| P-33 | `.forge/schemas/change.schema.json:15-42` (status + timeline) | 2026-06-04 | `status` enum includes `designed`; `timeline.properties.designed` = `{"type":"string","pattern":"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"}`. The `.forge.yaml` flip to `status: designed` + `timeline.designed: 2026-06-04` is schema-compliant (validate-change-yaml.sh exit 0). |

---

## Provenance Table — IMPLEMENT-TIME LIVE RE-READ (Phase 0, /forge:implement)

Re-read LIVE 2026-06-04 by the executor at `/forge:implement` before any
template/golden/doc line was authored (b8-coroot lesson: verify-then-pin runs
live at implement, not trusted from the design transcript). The four CARRY items
(CARRY-1..4) are resolved here; the base live re-read (CARRY-5) confirms no pin
drift. Phase-0 CARRY evidence for CARRY-1..4 was additionally verified LIVE by
the main thread 2026-06-04T12:24Z (carried into this brief) and reconfirmed
against the on-disk working tree below.

| ID | Source | Read | What it proves |
|----|--------|------|----------------|
| P-34 | `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml:20-46` (T-001 re-read) | 2026-06-04 (impl) | **Baseline 3-span set CONFIRMED unchanged.** `archetype: full-stack-monorepo` (L20), `version: "1.0.0"` (L21), `captured: "2026-05-29"` (date-only, no live ts), `demo: demo-005-connect-greeting` (L23). Exactly 3 spans: (1) `name: "<http-method> <path>"`, `otel_kind: client`, `verified_marker: "SpanKind.client"` (L26-32); (2) `name: "http.request"`, `otel_kind: server`, `verified_marker: 'otel.kind = "server"'` (L34-39); (3) `name: "greeter.greet"`, `otel_kind: internal`, `verified_marker: 'name = "greeter.greet"'` (L41-46). `user.interaction` appears ONLY in the explanatory comment/notes (phantom-absent as a span entry — no `name: "user.interaction"` span key). T-001 PASS. |
| P-35 | `bin/forge-migrate-flagship.sh` + LIVE dry-run against a tmpdir copy (T-003/T-005/T-006/T-007 re-read) | 2026-06-04 (impl) | **Driver surface + behaviour CONFIRMED.** Flags `--target`/`--phase 0\|1\|2\|3\|4\|all`/`--dry-run`/`--force`/`--rollback`/`--help` (parse L406-430); exit envelope 0/2/5/7/8 (header L13-17). Phase 0 preflight reads `archetype_version`, exits 7 on `!= 1.0.0` (L132/L141-143). LIVE dry-run on a fresh `cp -r examples/forge-fsm-example/` + `git init` tmpdir copy: **exit 0**, prints `(Kong / Temporal / REST preserved — additive only, removal is B.8.14.)` (driver L183), `git status --porcelain` EMPTY (no mutation). LIVE negative: a tmpdir with `archetype_version: 2.0.0` → `--dry-run` **exit 7**. The dry-run plan additionally emits `Envoy SecurityPolicy/JWT OIDC is B.8.12` (Phase 2 canary line) — confirms the B.8.12 join point. T-003/T-005/T-006/T-007 grounded. |
| P-36 | demo paths LIVE `ls` (T-004 re-read) | 2026-06-04 (impl) | **Demo feature paths CONFIRMED (Spec Delta).** `examples/forge-fsm-example/.forge/changes/demo-001-greeting-service/features/greeter.feature`, `.../demo-002-greeting-screen/features/greeting_screen.feature`, `.../demo-003-rate-limit/features/rate_limit.feature` all present + non-empty; greeter.feature carries `Feature:` + 3 `Scenario:` + `Given`/`When`/`Then` (Background `Given`). `demo-004-user-onboarding/` exists with `.forge.yaml` carrying `status: specified` (L2) and NO `features/` dir. `examples/forge-fsm-example/shared/protos/` holds `v1/`, `buf.gen.yaml`, `buf.yaml`. T-004 grounded. |
| P-37 | **CARRY-1** — connectrpc 0.6.1 `client` Cargo feature (crates.io 0.6.1 feature table, main-thread live 2026-06-04T12:24Z) | 2026-06-04 (impl) | **CARRY-1 RESOLVED.** connectrpc 0.6.1 declares `client = ['hyper/client','hyper/http1','hyper/http2','hyper-util/client',…,'tokio/net']`; `client-tls = [...,'client']` (https); `tls = ['server-tls','client-tls']`. The S2S client surface (`connectrpc::client::{HttpClient, ClientConfig, CallOptions}`, P-01) REQUIRES the explicit `client` feature (and `client-tls` for TLS). The 2.0.0 `Cargo.toml.tmpl` currently has `features = ["axum"]` (server). **Resolution**: the client template's Cargo guidance documents adding `"client"` (and `"client-tls"` when https). The exact flag name `client` is confirmed live — NOT fabricated. Grounds T-005/T-019 (Phase 3). |
| P-38 | **CARRY-2** — Zitadel jwks_uri (live `https://zitadel.cloud/.well-known/openid-configuration` + zitadel source `op.NewEndpoint("/oauth/v2/keys")`, main-thread live 2026-06-04T12:24Z) | 2026-06-04 (impl) | **CARRY-2 RESOLVED.** `issuer = https://<ExternalDomain>`; `jwks_uri = <issuer>/oauth/v2/keys`. Confirmed live: issuer `https://zitadel.cloud`, jwks_uri `https://zitadel.cloud/oauth/v2/keys`. The SecurityPolicy `remoteJWKS` Backend + the backend middleware reference `<issuer>/oauth/v2/keys` (templated `<zitadel-issuer>` placeholder + the resolved-from-discovery comment). NOT a bare hardcode — the path is the live-verified discovery result. Grounds T-006 / T-022 / T-023 (Phase 4). |
| P-39 | **CARRY-3** — backend JWT middleware crate (crates.io `jwt-authorizer = 0.15.0`, main-thread live 2026-06-04T12:24Z) | 2026-06-04 (impl) | **CARRY-3 RESOLVED.** `jwt-authorizer = 0.15.0` — "jwt authorizer middleware for axum and tonic" (JWKS-based axum tower layer). Backend JWT middleware template uses `JwtAuthorizer::from_jwks_url(jwks_uri)` → tower `Layer` on the axum router, with issuer/audience validation. The family pin (`0.15`) is confirmed live; the exact builder symbols beyond `from_jwks_url`/`validation` are marked `// VERIFY-AT-DEPLOY` (documented stub) where uncertain — NO fabrication. Grounds T-007 / T-023 (Phase 4). |
| P-40 | **CARRY-4** — Envoy SecurityPolicy v1.8 JWT form (gateway.envoyproxy.io/v1alpha1 SecurityPolicy.spec.jwt.providers[], main-thread live 2026-06-04T12:24Z) | 2026-06-04 (impl) | **CARRY-4 RESOLVED.** Envoy Gateway v1.8 folds JWT into `SecurityPolicy.spec.jwt.providers[]` (apiVersion `gateway.envoyproxy.io/v1alpha1`) — NO separate JWTAuthn resource in v1.8. Shape: `spec.targetRef`→HTTPRoute; `spec.jwt.providers[{name, issuer: https://<ExternalDomain>, remoteJWKS.backendRefs[{group: gateway.envoyproxy.io, kind: Backend, name, port: 443}]}]` + a `Backend` resource pointing at the Zitadel jwks host. **Resolution**: a SINGLE `security-policy.yaml.tmpl` (NOT a separate jwtauthn file). Envoy GW v1.8.0 = `gateway.yaml` pin (P-28). Grounds T-008 / T-022 / T-024 (Phase 4). |
| P-41 | pins re-read (CARRY-5 base re-read): transport.yaml `versions_2_0_0`, gateway.yaml, identity.yaml | 2026-06-04 (impl) | **No pin drift.** `transport.yaml` `versions_2_0_0:` → `connectrpc: "=0.6.1"`, `connectrpc-build: "=0.6.1"`, `buffa: "=0.6.0"`, `buffa-types: "=0.6.0"` (unchanged vs P-23). `gateway.yaml` `version: "1.0.0"`, `envoy_gateway_chart: "v1.8.0"` (unchanged vs P-28). `identity.yaml` `version: "1.1.0"`, `zitadel_chart: "10.0.2"`, `zitadel: "v4.14.0"` (unchanged vs P-29). The 2.0.0 server adapter `transport_connect.rs.tmpl` is byte-frozen (P-25 still holds); the 2.0.0 `Cargo.toml.tmpl` gains ONLY the `client` feature + a CARRY-1 comment (the allowed ADR-B812-003 companion edit). No `[NEEDS CLARIFICATION]` — CARRY-5 clean. |
| P-42 | L2-04 `cargo check` on the rendered `transport_connect_client.rs.tmpl` vs the LIVE connectrpc 0.6.1 crate (`FORGE_E2E_TOOLCHAINS=1`) | 2026-06-04 (impl) | **Client API compile-verified — `ClientConfig::new` takes `Uri`, not `&str`.** The first cargo-check (template authored from P-01 prose `ClientConfig::new(uri.parse()?)`) FAILED `E0308`: connectrpc-0.6.1 `src/client/mod.rs:594` declares `pub fn new(base_uri: Uri) -> Self`. The template was corrected to parse `base_url.parse::<http::Uri>()` → `ClientConfig::new(uri)` and return `Result<ClientConfig, http::uri::InvalidUri>`. Re-check GREEN: the full client surface (`HttpClient::plaintext()`, `ClientConfig::new(Uri).with_default_timeout(Duration).with_default_header(..)`, `CallOptions`) compiles against connectrpc 0.6.1 (features `["axum","client"]` + `http = "1"`). Confirms the P-01 client symbols are real, not fabricated — the cargo-check L2 leg is the binding quality gate (ADR-B812-003). |

---

## Finding 1 — Before/after gate is a span-inventory superset, NOT live latency (P-10/P-11/P-30, ADR-B812-001)

The c1 `fsm-backend` is `image: scratch` (P-30): there is no running backend to load-test,
so p50/p95/p99 cannot be captured from the unmodified example. ADR-B8-1-002 ratified that
no live latency number is ever committed. The honest, hermetic before/after gate is the
**span-inventory superset**: capture the 2.0.0 after-state spans from a migrated c1 copy
(via the P-17/P-18 fake-OTLP pattern) and assert the 1.0.0 baseline 3-span set (P-10) is a
SUBSET (new 2.0.0 spans are additive). The phantom Flutter root (P-11) is asserted ABSENT
from both goldens. Real p95/p99 is delivered as a methodology DOC + an opt-in
`FORGE_B8_12_LIVE` leg that skip-passes by default. A negative guard (FR-B812-006/051)
asserts NO committed p99 number exists anywhere in the change tree.

## Finding 2 — connectrpc 0.6.x client API is a documented surface, not a fabrication (P-01, ADR-B812-003)

The connectrpc Rust client surface (P-01) is read verbatim from the upstream README:
`HttpClient::plaintext()` / `with_tls()`, `ClientConfig::new(uri).with_default_timeout().with_default_header()`,
`<Svc>Client::new(http, config)`, `client.greet(req)` + `client.greet_with_options(req, CallOptions::default().with_timeout())`.
This maps the four ADR-B86-004 posture concerns cleanly:
- **auth** → `with_default_header("authorization", "Bearer <token>")` (carries the Zitadel machine-user token);
- **TLS** → `HttpClient::...with_tls()` (documented; plaintext for in-cluster cleartext);
- **deadline** → `with_default_timeout(Duration)` (config default) + per-call `CallOptions::default().with_timeout(Duration)` (override);
- **retry** → connectrpc client retry posture documented inline (VERIFY-AT-IMPLEMENT: confirm the retry knob shape on 0.6.1).

**CARRY (P-24)**: the connectrpc `client` Cargo feature flag name is VERIFY-AT-IMPLEMENT —
confirm against the live crate before editing `Cargo.toml.tmpl` `features`.

## Finding 3 — Envoy SecurityPolicy/JWT at v1.8.0 matches the existing chart pin (P-02/P-03/P-27/P-28, ADR-B812-002)

The Envoy Gateway latest (v1.8.0, P-02) is the SAME version already pinned in `gateway.yaml`
(P-28) and used by the existing B.8.4 envoy-gateway templates (P-26/P-27). The SecurityPolicy
+ JWT shape (P-03) — `apiVersion: gateway.envoyproxy.io/v1alpha1`, `kind: SecurityPolicy`,
`spec.targetRef`→HTTPRoute, `spec.jwt.providers[].remoteJWKS.backendRefs`→`Backend` — is read
from the v1.8 docs, NOT fabricated. The Zitadel discovery URL (P-04) is pinned only to
`https://<ExternalDomain>/.well-known/openid-configuration`; the exact `jwks_uri` path is
VERIFY-AT-IMPLEMENT. **Fallback (ADR-B812-002, ADR-B87-006)**: if at implement the live
SecurityPolicy API or the Zitadel jwks path cannot be cleanly pinned, land middleware-only +
a documented gateway-side stub — NO fabrication.

## Finding 4 — B.8.12 bumps NO standard; pure additive templates + harness + doc (P-23/P-28/P-29)

`transport.yaml` (P-23), `gateway.yaml` (P-28), and `identity.yaml` (P-29) are all CONSUMED
as authoritative pin sources and cross-referenced; none is edited or version-bumped. B.8.12
ships new 2.0.0 template files + goldens + a methodology doc section + a harness + a CHANGELOG
entry + a CI line only (T5.1 / B.8.10 no-standard-bump precedent).

---

## Anti-Hallucination Pass (Evidence Phase)

- **connectrpc client API (P-01) is quoted from the upstream README**, not assumed. The four
  posture knobs (auth/TLS/deadline/retry) map to documented methods. The retry knob shape and
  the `client` Cargo feature flag (P-24) are flagged VERIFY-AT-IMPLEMENT — not fabricated.
- **Envoy SecurityPolicy/JWT (P-03) is read from the v1.8 docs**; the `gateway.envoyproxy.io/v1alpha1`
  group is distinct from the standard `gateway.networking.k8s.io/v1` used by the existing
  Gateway/HTTPRoute templates (P-27) — confirmed, not conflated. The `remoteJWKS.backendRefs`→Backend
  form is flagged VERIFY-AT-IMPLEMENT against the exact v1.8.x doc.
- **Zitadel jwks path is NOT pinned beyond the discovery URL (P-04)** — `/oauth/v2/keys` is named
  only as a convention, resolved at implement from the live discovery doc (ADR-B87-006 anti-fabrication).
- **No committed p95/p99 number anywhere (P-30)** — `fsm-backend = image: scratch`; ADR-B8-1-002
  bars committed latency. FR-B812-006/051 + the harness anti-faked-latency guard encode this.
- **3-span baseline + phantom (P-10/P-11) are HARD FACTS** re-read from the baseline YAML.
- **Demo feature-file paths (P-19) CORRECT the spec guess** — they live under
  `.forge/changes/demo-NNN-*/features/` inside the c1 example, not `test/features/`. demo-004 has
  no feature file and stays `specified` (P-20). This is a live `ls` result, not an assumption.
- **The migration driver surface (P-12/P-13/P-14) is quoted from the live script**, not invented.
- **B.8.12 bumps no standard (P-23/P-28/P-29)** — a live read of the three pin sources confirms
  they are consumed, not edited.
- **Independent review required (NFR-B812-009)**: this evidence is NOT self-approved. The
  VERIFY-AT-IMPLEMENT items are resolved at implement by re-reading the live sources, and the
  design is ratified by an independent reviewer before `/forge:plan`.
