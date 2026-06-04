# Design: b8-12-e2e-migration

<!-- Status: designed -->
<!-- Schema: default -->
<!-- Audit: B.8.12 (b8-12-e2e-migration) — E2E migration convergence gate.
     MIXED evidence: EXTERNAL verify-then-pin (connectrpc 0.6.x client API,
     Envoy v1.8.0 SecurityPolicy/JWT, Zitadel OIDC discovery — evidence.md
     P-01..P-04, fetched LIVE 2026-06-04) + INTERNAL-FILE (baseline span
     inventory, migration driver, t5-otel-live-run fake-OTLP pattern, standards
     pins, CI-no-toolchain, no-committed-latency ADR — P-10..P-33). GROUND-TRUTH
     (Article III.4): (1) before/after = span-inventory SUPERSET, never live
     latency (fsm-backend = image:scratch, ADR-B8-1-002, P-30); (2) the 3-span
     baseline + phantom Flutter root are HARD FACTS (P-10/P-11); (3) migrate c1 =
     forge-migrate-flagship.sh --target against a tmpdir COPY (P-12/P-13), the
     committed c1 stays 1.0.0 (P-21); (4) B.8.12 lands the deferred S2S Connect
     client (ADR-B86-004) on the documented connectrpc client API (P-01) + the
     deferred Envoy-OIDC wiring (ADR-B87-006) on the v1.8.0 SecurityPolicy/JWT
     shape (P-03); (5) CI = Python+Node+shellcheck only → L1 hermetic + L2 opt-in
     (P-31); (6) B.8.12 bumps NO standard — pure additive templates+harness+doc
     (P-23/P-28/P-29). VERIFY-AT-IMPLEMENT items: connectrpc `client` Cargo
     feature flag (P-24), Zitadel jwks path (P-04), backend JWT tower-layer shape. -->

**Agents**: Ferris (Rust architecture — the S2S Connect client template) + Atlas
(Infra architect — the Envoy-OIDC wiring + migration driver glue) + Eris (test
architect — the golden-superset gate + L1/L2 harness).
**Live evidence**: external URLs fetched + on-disk re-reads 2026-06-04; full
provenance in `evidence.md` (P-01..P-33). The VERIFY-AT-IMPLEMENT items
(connectrpc `client` feature flag P-24, Zitadel jwks path P-04, backend JWT
middleware shape) are re-read LIVE at `/forge:implement` before any template line
is authored (b8-coroot lesson).
**Scope reminder**: this is the DESIGN phase. It ships **no template, no golden,
no doc section, no harness, no CHANGELOG entry, no CI line**. It is the normative
blueprint the impl phase realizes. The four decisions below (ADR-B812-001..004)
are encoded; the matching Q entries are flipped to answered in `open-questions.md`.
**No self-approval** — independent review follows before `/forge:plan`.

**CENTRAL FINDING (Article III.4)**: "captures p95/p99 avant/après" is NOT
capturable as live latency (`fsm-backend = image: scratch`, P-30). The honest,
hermetic before/after gate is a **span-inventory superset** (P-10): the 1.0.0
baseline 3-span set is a SUBSET of the captured 2.0.0 after-state; new 2.0.0 spans
are additive; the phantom Flutter root (P-11) is absent from both goldens. Real
p95/p99 is a methodology DOC + an opt-in `FORGE_B8_12_LIVE` leg, skip-passing by
default. A negative guard asserts NO committed p99 number exists anywhere in the
change tree (ADR-B8-1-002 + III.4).

---

## Architecture Decisions

### ADR-B812-001 — Before/after = golden span-inventory superset; NO committed latency; methodology doc → MIGRATIONS.md (resolves Q-001 + Q-005)

**Context**: Q-001 — the before/after mechanism; Q-005 — the methodology-doc home.
The plan wording ("captures p95/p99 avant/après") conflicts with the hard fact that
`fsm-backend` is `image: scratch` (P-30, FR-B8-1-012). ADR-B8-1-002 ratified
"methodology + optional sample, NEVER committed live numbers."

**Decision**:
1. **The binding L1 gate is a span-inventory superset.** Commit the 2.0.0 after-state
   golden span inventory at `.forge/changes/b8-12-e2e-migration/captures/full-stack-monorepo-2.0.0.span-inventory.yaml`
   (same schema as the 1.0.0 baseline — `archetype`/`version`/`captured`/`demo`/`spans[]`
   with `name`/`otel_kind`/`layer`/`source`/`verified_marker`/`role`). The harness asserts
   the 1.0.0 baseline's 3 code-verified spans (P-10) are a SUBSET of the 2.0.0 golden:
   (a) a `client` span with marker `SpanKind.client`; (b) `http.request` `server` with
   `otel.kind = "server"`; (c) `greeter.greet` `internal` with `name = "greeter.greet"`.
   New 2.0.0 spans (Connect server-side, Envoy-injected, etc.) are additive and allowed.
   The phantom `user.interaction` Flutter root (P-11) MUST be absent from BOTH goldens.
2. **The capture mechanism is the t5-otel-live-run hermetic fake-OTLP pattern** (P-15..P-18):
   the committed golden is the deterministic artifact; the L1 assertion is a `diff -q`-style
   subset check of the 3 named spans against the committed 2.0.0 golden, plus the sanitiser
   guard (`"<ts:redacted>"` present, no IPv4 — P-16). Any companion `.golden.json` capture
   reuses the existing stdlib collector (P-18); no new collector artifact is required.
3. **Real p95/p99 = a methodology DOC, home = `docs/MIGRATIONS.md`** (Q-005 lean (a)
   confirmed). Extend `docs/MIGRATIONS.md` with a "Latency measurement methodology
   (when a real backend image exists)" section, anchored to the B.8.13 rollback
   thresholds (p99 >20%, traceparent errors >1%) and cross-referencing `docs/B8-BASELINE.md §6`.
   MIGRATIONS.md is the natural per-migration home; B8-BASELINE §6 is the procedure
   reference. The section commits NO numeric ms figure.
4. **Negative guard (ADR-B8-1-002 + III.4)**: the harness asserts NO committed p95/p99
   number exists anywhere under `.forge/changes/b8-12-e2e-migration/` (pattern
   `p9[59][^a-z].*[0-9]+\s*(ms|µs|s\b)` → zero matches), and the methodology doc itself
   commits no numeric figure.

**Consequences**: FR-B812-001..006 + FR-B812-050..052 satisfied. The before/after gate
is hermetic, deterministic, and honest. The opt-in `FORGE_B8_12_LIVE` leg exercises the
methodology flow and skip-passes without toolchains.

**Compliance**: Article III.4 (no faked latency — the negative guard is machine-verified);
ADR-B8-1-002 (chain preserved); II (the golden-superset flow ships a BDD `.feature` scenario).

---

### ADR-B812-002 — Envoy-OIDC: land all three (SecurityPolicy + JWT + backend middleware), verify-then-pin; documented fallback (resolves Q-002)

**Context**: Q-002 — the Envoy-OIDC scope. ADR-B87-006 deferred the Envoy SecurityPolicy,
the JWT filter, and the backend JWT validation middleware to B.8.12, and barred fabricating
the Envoy Gateway API version and the Zitadel OIDC discovery URL. Live verification
(P-02/P-03/P-04) shows the Envoy Gateway latest (v1.8.0) MATCHES the existing `gateway.yaml`
chart pin (P-28), and the SecurityPolicy + JWT shape is documented at v1.8.

**Decision — land all three** (Q-002 lean (a) confirmed; the API is cleanly pinnable LIVE):

1. **SecurityPolicy template** `.../2.0.0/infra/k8s/envoy-gateway/securitypolicy.yaml.tmpl`:
   `apiVersion: gateway.envoyproxy.io/v1alpha1`, `kind: SecurityPolicy` (P-03 — distinct
   from the `gateway.networking.k8s.io/v1` group used by the existing Gateway/HTTPRoute
   templates, P-27); `spec.targetRef` → `{group: gateway.networking.k8s.io, kind: HTTPRoute,
   name: <route>}`; `spec.jwt.providers[].name` + `.remoteJWKS.backendRefs[{group:
   gateway.envoyproxy.io, kind: Backend, name: <jwks-backend>, port: 443}]` (+ optional
   `issuer`/`audiences`). The issuer = the `zitadel.configmapConfig.ExternalDomain` from
   the b8-7 `values-forge` overlay (P-04). A companion `Backend` resource (the jwks upstream)
   is included or documented in the same template.
2. **JWT provider / JWTAuthn configuration** is expressed inside the SecurityPolicy
   `spec.jwt.providers[]` (the v1.8 SecurityPolicy form folds the JWT filter into the
   SecurityPolicy resource — P-03). If the live v1.8.x docs at implement still expose a
   separate JWTAuthn resource, it lands as `jwtauthn.yaml.tmpl` in the same dir; otherwise
   the providers block IS the JWT wiring. **VERIFY-AT-IMPLEMENT** which form v1.8.x uses.
3. **Backend JWT validation middleware template** under `.../2.0.0/backend/` (a Rust tower
   layer that validates the forwarded JWT / the `authorization` header on inbound requests).
   The EXACT middleware shape (tower `Layer`/`Service`, the validation crate, the JWKS fetch)
   is **VERIFY-AT-IMPLEMENT** — do NOT fabricate the connectrpc/axum JWT-middleware API. The
   template carries documented stubs + the validation posture (issuer/audience checks, JWKS
   source = the Zitadel discovery doc).
4. **Cross-reference**: every Envoy-OIDC template carries an `identity.yaml@1.1.0` comment
   (P-29 — chart `10.0.2`, appVersion `v4.14.0`, ghcr.io) + a `gateway.yaml` (v1.8.0, P-28)
   comment. The `kustomization.yaml.tmpl` is updated to list the new resource files (carry).

**Consequence (documented fallback — ADR-B87-006, III.4)**: if at `/forge:implement` the live
Envoy SecurityPolicy API or the Zitadel jwks path CANNOT be cleanly pinned, fall back to
**middleware-only + a documented gateway-side stub** (a commented SecurityPolicy skeleton
that names the unresolved field + the discovery URL), and record the fallback explicitly in
`evidence.md` + `open-questions.md`. NO fabrication of API strings.

**Compliance**: Article III.4 (Envoy/Zitadel APIs verify-then-pin LIVE, not fabricated;
fallback recorded); ADR-B87-006 (anti-fabrication honoured); V (the wiring is the named
B.8.12 deliverable); VIII.1 (Envoy joins Kong additively — Kong not removed).

---

### ADR-B812-003 — S2S Connect client on the documented connectrpc 0.6.x client API; auth/TLS/deadline/retry; cargo-check L2 opt-in (resolves Q-003)

**Context**: Q-003 — the Rust S2S Connect client surface. ADR-B86-004 re-deferred
`transport_connect_client.rs.tmpl` to B.8.12 citing the non-trivial auth/TLS/deadline/retry
decisions. The connectrpc 0.6.x client API is now documented LIVE (P-01); the 2.0.0
`transport_connect.rs.tmpl` is server-only (P-25); the pins are `connectrpc =0.6.1` (P-23).

**Decision — land a minimal correct client template + documented posture + L2 cargo-check**
(Q-003 lean (a) confirmed):

1. **New file** `.../2.0.0/backend/crates/grpc-api/src/transport_connect_client.rs.tmpl`
   (the `N.N.N/` subtree convention, sibling of `transport_connect.rs.tmpl`, P-25). The
   1.0.0 flat-tree server adapter and the 2.0.0 server adapter (P-25) stay byte-frozen
   (FR-B812-033).
2. **Client construction on the documented API** (P-01):
   `use connectrpc::client::{HttpClient, ClientConfig, CallOptions};`;
   `let http = HttpClient::plaintext();` (cleartext, in-cluster) or `HttpClient::...with_tls()`
   (https — documented swap); `let config = ClientConfig::new(uri.parse()?)
   .with_default_timeout(Duration::from_secs(30))
   .with_default_header("authorization", format!("Bearer {token}"));`;
   `let client = GreetServiceClient::new(http, config);` (generated `<Svc>Client::new(http, config)`);
   `client.greet(req).await?` + per-call `client.greet_with_options(req,
   CallOptions::default().with_timeout(Duration::from_secs(5)))`.
3. **The four posture knobs are explicit** (FR-B812-032 — at least via documented stubs):
   - **auth** → `with_default_header("authorization", "Bearer <token>")` carrying the Zitadel
     machine-user token (cross-ref the Envoy-OIDC issuer, ADR-B812-002);
   - **TLS** → `HttpClient::...with_tls()` documented (plaintext for cleartext in-cluster);
   - **deadline** → `with_default_timeout(Duration)` config default + per-call
     `CallOptions::default().with_timeout(Duration)` override;
   - **retry** → documented inline (connectrpc client retry posture — VERIFY-AT-IMPLEMENT
     the exact retry knob on 0.6.1; do NOT fabricate).
4. **Pin coupling**: the companion `Cargo.toml.tmpl` carries `connectrpc = "=0.6.1"` (P-23/P-24).
   **CARRY (P-24)**: the client surface likely needs an additional connectrpc feature beyond
   `axum` (the current `features = ["axum"]` gates the SERVER `into_axum_service`). VERIFY-AT-IMPLEMENT
   the EXACT feature flag name for the client (`client` vs feature-implied) against the live
   crate `Cargo.toml`/docs, then either add `features = ["axum", "client"]` OR document that the
   client surface is feature-implied. Do NOT fabricate the flag name at design.
5. **cargo-check L2 opt-in** (`FORGE_E2E_TOOLCHAINS=1`): CI has no cargo (P-31). The harness
   renders the template into a minimal tmpdir Rust project and runs `cargo check` only when
   `FORGE_E2E_TOOLCHAINS=1`; otherwise `SKIP: FORGE_E2E_TOOLCHAINS not set` (0 failures).

**Consequences**: FR-B812-030..035 satisfied. The 2.0.0 backend gains a compilable,
documented S2S client template; the quality bar (cargo-check) is verifiable behind opt-in.

**Compliance**: Article III.4 (client API from the README P-01, not fabricated; retry knob +
feature flag flagged VERIFY-AT-IMPLEMENT); ADR-B86-004 (the named landing); VII (the client is
a transport adapter — no business logic; mirrors the server adapter's hexagonal posture, P-25).

---

### ADR-B812-004 — Migration target = tmpdir copy + `forge-migrate-flagship.sh --target`; L1 dry-run, L2 real overlay (resolves Q-004)

**Context**: Q-004 — the migration target mechanics. 2.0.0 is `scaffoldable: false` until
B.8.14; "migrate c1" = invoke the B.8.10 driver against a COPY (P-12/P-13), never scaffold a
new committed example. The committed c1 stays 1.0.0 (P-21).

**Decision — tmpdir copy + `--target`, L1 dry-run, L2 real overlay** (Q-004 lean (a) confirmed):

1. **Each test run creates a fresh tmpdir**: `cp -r examples/forge-fsm-example/` into
   `$(mktemp -d)`, `git init` (the driver's Git-clean gate, P-13), `trap` cleanup. The
   committed c1 example is never touched (FR-B812-012, asserted via `git diff --quiet
   examples/forge-fsm-example/` after the L1 block).
2. **L1 hermetic** = `bash bin/forge-migrate-flagship.sh --target <tmpdir-copy> --dry-run`
   asserts exit 0 (Phase 0 passes on the 1.0.0 manifest, P-12); the dry-run output contains
   the additive-delta lines + the preservation invariant (P-14); `git -C <tmpdir> status
   --porcelain` is empty after `--dry-run` (no mutation). Plus the negative test:
   a tmpdir with `archetype_version: 2.0.0` → `--dry-run` exits **7** (wrong-version, P-12).
3. **L2 opt-in** (`FORGE_B8_12_LIVE=1`) = the real Phase-2 overlay against the tmpdir copy,
   asserting the additive result: (a) `infra/k8s/envoy-gateway/` present; (b) Kong preserved;
   (c) Connect/Zitadel/Qwik/pg17 markers detectable; (d) no Kong/Temporal/REST path removed
   (`diff -rq` vs the 1.0.0 base shows no deletions). Without the env var → skip-pass.
4. **The committed before/after artifact is the span-inventory YAML golden** (ADR-B812-001),
   NOT a committed migrated project tree — simple, isolated, deterministic.

**Consequences**: FR-B812-010..015 satisfied. The migration E2E driver is hermetic at L1,
real at L2 opt-in, and never mutates the committed reference.

**Compliance**: Article III.4 (the driver surface + exit-7 envelope are quoted from the live
script, P-12/P-13/P-14); VIII.1/VIII.2 (additive overlay — Kong + Temporal preserved, P-13);
IV (the committed c1 is a read-only input).

---

## Change Surface (per-file plan — authored at impl, NOT created here)

| File | Action | Intent |
|------|--------|--------|
| `.forge/changes/b8-12-e2e-migration/captures/full-stack-monorepo-2.0.0.span-inventory.yaml` | CREATE | 2.0.0 after-state golden; superset of the 1.0.0 baseline 3 spans (P-10); phantom absent (P-11); sanitised (P-16). ADR-B812-001. |
| `.forge/templates/.../2.0.0/backend/crates/grpc-api/src/transport_connect_client.rs.tmpl` | CREATE | S2S Connect client on the connectrpc 0.6.x client API (P-01); auth/TLS/deadline/retry posture. ADR-B812-003. |
| `.forge/templates/.../2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl` | EDIT (feature add OR doc) | Add the connectrpc `client` feature if the client surface requires it (VERIFY-AT-IMPLEMENT P-24); else document. ADR-B812-003. |
| `.forge/templates/.../2.0.0/infra/k8s/envoy-gateway/securitypolicy.yaml.tmpl` | CREATE | Envoy SecurityPolicy + JWT providers (`gateway.envoyproxy.io/v1alpha1`, `remoteJWKS.backendRefs`→Backend, P-03); identity.yaml@1.1.0 + gateway.yaml v1.8.0 cross-ref. ADR-B812-002. |
| `.forge/templates/.../2.0.0/infra/k8s/envoy-gateway/jwtauthn.yaml.tmpl` | CREATE (conditional) | Separate JWTAuthn resource ONLY if v1.8.x exposes one distinct from the SecurityPolicy providers block (VERIFY-AT-IMPLEMENT). ADR-B812-002. |
| `.forge/templates/.../2.0.0/infra/k8s/envoy-gateway/kustomization.yaml.tmpl` | EDIT | List the new SecurityPolicy (+ JWTAuthn) resource files (carry, P-27). ADR-B812-002. |
| `.forge/templates/.../2.0.0/backend/<jwt-middleware>.rs.tmpl` (exact path at impl) | CREATE | Backend JWT validation middleware (tower layer — VERIFY-AT-IMPLEMENT shape); issuer/audience checks; JWKS = Zitadel discovery (P-04). ADR-B812-002. |
| `docs/MIGRATIONS.md` | APPEND | "Latency measurement methodology" section; B.8.13 thresholds (p99 >20%, traceparent >1%); xref B8-BASELINE §6; NO committed ms figure. ADR-B812-001. |
| `.forge/scripts/tests/b8-12.test.sh` | CREATE | ~14 L1 hermetic + L2 opt-in (`FORGE_B8_12_LIVE` / `FORGE_E2E_TOOLCHAINS`); mirrors t5-otel-live-run + b8-10/b8-11 structure. |
| `.github/workflows/forge-ci.yml` | APPEND | One line `"b8-12.test.sh --level 1"` after the `b8-11.test.sh` line (P-31). |
| `CHANGELOG.md` | APPEND | `[Unreleased]` entry anchored `b8-12-e2e-migration` (whole-file grep, P-31). |

**Files NOT touched**: the 1.0.0 flat-tree server `transport_connect.rs.tmpl` (FR-B812-033);
the 2.0.0 server `transport_connect.rs.tmpl` (P-25, frozen); the 1.0.0 `infra/k8s/` Kong
manifests (FR-B812-045); `examples/forge-fsm-example/**` (committed c1 — migration runs in
tmpdir, NFR-B812-003/010); `transport.yaml`/`gateway.yaml`/`identity.yaml` (consumed, not
bumped — Finding 4); `bin/forge-migrate-flagship.sh` (invoked, not edited); the Constitution
(no amendment); `.forge/schemas/**`.

---

## Component Diagram

```mermaid
graph TD
    H12[".forge/scripts/tests/b8-12.test.sh<br/>~14 L1 hermetic + L2 opt-in"]
    subgraph GATE["Before/after gate (ADR-B812-001)"]
      BASE[".forge/baselines/...1.0.0.span-inventory.yaml<br/>3 code-verified spans (P-10)<br/>phantom user.interaction ABSENT (P-11)"]
      GOLD[".forge/changes/b8-12.../captures/<br/>...2.0.0.span-inventory.yaml<br/>SUPERSET of baseline · sanitised (P-16)"]
      COLL["fake_otlp_collector.py (reused, P-18)<br/>Python stdlib only · run_smoke.sh"]
    end
    subgraph MIG["Migration E2E driver (ADR-B812-004)"]
      DRV["bin/forge-migrate-flagship.sh (P-12/P-13)<br/>--target <tmpdir-copy> --dry-run<br/>exit 0 · exit 7 wrong-version"]
      TMP["mktemp -d cp -r examples/forge-fsm-example/<br/>git init · trap cleanup · 1.0.0 manifest"]
    end
    subgraph S2S["S2S Connect client (ADR-B812-003)"]
      CLI["transport_connect_client.rs.tmpl<br/>connectrpc::client::{HttpClient,ClientConfig,CallOptions} (P-01)<br/>Bearer · with_tls · with_default_timeout · CallOptions"]
      CARGO["Cargo.toml.tmpl connectrpc =0.6.1 (P-23)<br/>+ client feature (VERIFY-AT-IMPLEMENT P-24)"]
    end
    subgraph OIDC["Envoy-OIDC wiring (ADR-B812-002)"]
      SP["securitypolicy.yaml.tmpl<br/>gateway.envoyproxy.io/v1alpha1 SecurityPolicy (P-03)<br/>spec.jwt.providers[].remoteJWKS.backendRefs→Backend"]
      MW["backend JWT middleware (tower layer)<br/>issuer/audience · VERIFY-AT-IMPLEMENT shape"]
      ZIT["Zitadel issuer = ExternalDomain (P-04)<br/>/.well-known/openid-configuration → jwks_uri"]
    end
    DOC["docs/MIGRATIONS.md<br/>latency methodology · B.8.13 thresholds<br/>NO committed p99 (ADR-B8-1-002, P-30)"]
    CI[".github/workflows/forge-ci.yml<br/>b8-12.test.sh --level 1 (P-31)"]

    DRV -->|--target| TMP
    TMP -->|migrated copy| COLL
    COLL -->|capture after-state| GOLD
    BASE -->|3-span subset check| H12
    GOLD -->|superset assertion (diff -q)| H12
    CLI --> CARGO
    SP --> ZIT
    MW --> ZIT
    CLI -->|Bearer token| SP
    H12 -->|L1 golden superset + phantom-absent| GOLD
    H12 -->|L1 dry-run exit 0 / exit 7| DRV
    H12 -->|L1 client tmpl present + pin| CLI
    H12 -->|L1 SecurityPolicy present| SP
    H12 -->|L1 no committed p99| DOC
    H12 -->|L1 b8-1 + b8-10 coupling (P-32)| DRV
    H12 -->|L2 cargo-check (FORGE_E2E_TOOLCHAINS)| CLI
    H12 -->|L2 real overlay (FORGE_B8_12_LIVE)| DRV
    CI -->|registers| H12
```

---

## Sequence Diagram — migrate copy → capture after → assert superset; S2S call → Envoy JWT → backend

```mermaid
sequenceDiagram
    participant H as b8-12.test.sh
    participant Tmp as tmpdir copy of c1
    participant Drv as forge-migrate-flagship.sh
    participant Coll as fake_otlp_collector.py
    participant Gold as 2.0.0 golden (committed)

    Note over H,Gold: Before/after gate (ADR-B812-001 / ADR-B812-004)
    H->>Tmp: cp -r examples/forge-fsm-example/ → mktemp -d; git init
    H->>Drv: --target <tmpdir> --dry-run
    Drv->>Drv: Phase 0 manifest archetype_version==1.0.0? (P-12)
    Drv-->>H: exit 0 + additive-delta plan (P-14); no mutation
    H->>Tmp: negative — manifest 2.0.0 → --dry-run → exit 7 (P-12)
    opt L2 FORGE_B8_12_LIVE=1
        H->>Drv: --target <tmpdir> --phase 2 (real overlay)
        Drv->>Tmp: additive overlay (Envoy ∥ Kong; Connect; Zitadel; pg17)
        H->>Coll: capture after-state spans (run_smoke pattern, P-17/P-18)
        Coll-->>H: capture-NNN.json (ts redacted, P-16)
    end
    H->>Gold: assert 3 baseline spans ⊆ 2.0.0 golden (P-10); phantom absent (P-11)
    H->>H: assert NO committed p99 anywhere (P-30)

    Note over H: S2S call posture (ADR-B812-003 / ADR-B812-002) — documented, L2 cargo-check
    participant Client as transport_connect_client.rs
    participant Envoy as Envoy SecurityPolicy
    participant Zitadel as Zitadel JWKS
    participant Backend as backend JWT middleware
    Client->>Envoy: greet(req) + authorization: Bearer <machine-user token> (P-01)
    Envoy->>Zitadel: fetch JWKS via remoteJWKS.backendRefs→Backend (P-03/P-04)
    Zitadel-->>Envoy: signing keys (jwks_uri from discovery)
    Envoy->>Backend: forward validated request
    Backend->>Backend: tower layer re-validates issuer/audience (VERIFY-AT-IMPLEMENT)
    Backend-->>Client: GreetResponse
```

---

## Testing Strategy

**Harness**: `.forge/scripts/tests/b8-12.test.sh`
**Pattern**: mirrors `t5-otel-live-run.test.sh` (P-15..P-18) + `b8-10.test.sh`/`b8-11.test.sh`:
`--level` flag parsed at top; `source "$HARNESS_DIR/_helpers.sh"`; `PASS=0; FAIL=0;
FAIL_NAMES=()`; named test functions; `run_test`/`print_summary` in `main()`; L2 block under
`case ",$LEVEL," in *,2,*)`.
**Registration**: `"b8-12.test.sh --level 1"` in `forge-ci.yml` after `b8-11.test.sh` (P-31).
**Budget**: L1 ≤ a few seconds (grep/stat/diff + one dry-run invocation); no cargo/flutter/docker.

### L1 Assertion List (~14 hermetic tests; ephemeral `mktemp -d` fixtures + static greps)

| # | FR / NFR | Assertion | Implementation |
|---|----------|-----------|----------------|
| T-001 | FR-B812-001 | 2.0.0 golden span inventory present + schema fields | `[ -f captures/...2.0.0.span-inventory.yaml ]` + `grep "archetype: full-stack-monorepo"` + `grep 'version: "2.0.0"'` |
| T-002 | FR-B812-002 | 3-span superset: client + http.request + greeter.greet in 2.0.0 golden | `grep "SpanKind.client"` + `grep "http.request"` + `grep "greeter.greet"` → all exit 0 |
| T-003 | FR-B812-003 | phantom `user.interaction` absent from BOTH goldens | `grep "user.interaction" <baseline>` → zero + `grep "user.interaction" <2.0.0 golden>` → zero |
| T-004 | FR-B812-004/NFR-006 | goldens sanitised: `"<ts:redacted>"` present (JSON captures), no IPv4 | `grep '"<ts:redacted>"'` (JSON) + `! grep -E '"([0-9]{1,3}\.){3}[0-9]{1,3}"'` |
| T-005 | FR-B812-010 | migration dry-run exits 0 on a 1.0.0 tmpdir copy | `cp -r` example → `mktemp -d` + `git init`; `bash forge-migrate-flagship.sh --target <tmp> --dry-run`; `[ $? -eq 0 ]` |
| T-006 | FR-B812-011 | dry-run output has additive-delta lines + preservation invariant; no mutation | `grep "Kong / Temporal / REST preserved" <out>` + `git -C <tmp> status --porcelain` empty |
| T-007 | FR-B812-015 | exit-7 on wrong-version tmpdir | tmpdir with `archetype_version: 2.0.0`; `--dry-run`; `[ $? -eq 7 ]` |
| T-008 | FR-B812-012/NFR-003 | committed c1 example git-clean after L1 | `git diff --quiet examples/forge-fsm-example/` → exit 0 |
| T-009 | FR-B812-023/020 | demo-001..003 `.feature` Given/When/Then intact (P-19 paths) | awk G/W/T check on `demo-00{1,2,3}-*/features/*.feature` |
| T-010 | FR-B812-022 | demo-004 status stays `specified` (P-20 path) | `grep "status: specified" examples/forge-fsm-example/.forge/changes/demo-004-user-onboarding/.forge.yaml` |
| T-011 | FR-B812-030 | `transport_connect_client.rs.tmpl` present | `[ -f .../2.0.0/backend/crates/grpc-api/src/transport_connect_client.rs.tmpl ]` |
| T-012 | FR-B812-031/032 | client pin sentinel + posture terms | `grep "=0.6" <client tmpl OR Cargo.toml.tmpl>` + `grep -iE "auth\|tls\|deadline\|retry" <client tmpl>` |
| T-013 | FR-B812-035 | transport.yaml `versions_2_0_0` + connectrpc pin (P-23) | `grep "versions_2_0_0" transport.yaml` + `grep "connectrpc.*=0.6.1" transport.yaml` |
| T-014 | FR-B812-040 | Envoy-OIDC template(s) present in 2.0.0 subtree | `find .../2.0.0/infra/k8s/envoy-gateway/ -name "*security*" -o -name "*jwt*" -o -name "*oidc*"` → ≥1 |
| T-015 | FR-B812-042 | backend JWT middleware template present | `find .../2.0.0/backend/ -name "*jwt*" -o -name "*auth*middleware*"` → ≥1 |
| T-016 | FR-B812-044 | Envoy-OIDC template cross-refs identity.yaml@1.1.0 | `grep "identity.yaml" <envoy-oidc tmpl>` (or `grep "1.1.0"` audit comment) |
| T-017 | FR-B812-006/051/NFR-004 | NO committed p99 number anywhere in the change tree (anti-faked-latency guard) | `! grep -rE 'p9[59][^a-z].*[0-9]+\s*(ms\|µs\|s\b)' .forge/changes/b8-12-e2e-migration/` |
| T-018 | FR-B812-050 | methodology doc present + B.8.13 anchor, no committed number | `grep "p99" docs/MIGRATIONS.md` + `grep "B.8.13" docs/MIGRATIONS.md` + T-017 pattern on the doc |
| T-019 | FR-B812-063 | reused fake-OTLP collector is stdlib-only (P-15/P-18) | forbidden-import grep on the collector script → zero matches |
| T-020 | FR-B812-033/045 | 1.0.0 + 2.0.0 server `transport_connect.rs.tmpl` + 1.0.0 Kong infra byte-unchanged | `git diff --quiet <each frozen path>` → exit 0 |
| T-021 | FR-B812-067 | CHANGELOG has `b8-12-e2e-migration` (whole-file grep, P-31) | `grep "b8-12-e2e-migration" CHANGELOG.md` |
| T-022 | FR-B812-066 | forge-ci.yml has `b8-12.test.sh` | `grep "b8-12.test.sh" forge-ci.yml` |
| T-023 | FR-B812-068 | coupling guards: `b8-1.test.sh --level 1` + `b8-10.test.sh --level 1` exit 0 (P-32) | `bash b8-1.test.sh --level 1 >/dev/null 2>&1; [ $? -eq 0 ]` + same for b8-10 |

(The list runs to ~23 named functions; the proposal's "~14 L1" is the count of the
distinct core assertion groups — golden, dry-run, demo-survival, S2S, Envoy-OIDC,
anti-latency, methodology, frozen-files, CHANGELOG/CI, coupling. T-001..T-008 are the
gate core; T-019/T-020/T-021/T-022/T-023 are infra/coupling. Eris consolidates trivially
co-located greps to keep the wall-clock ≤ a few seconds.)

### L2 Opt-In Block

| # | FR | Gate | Assertion |
|---|----|------|-----------|
| L2-01 | FR-B812-013/064 | `FORGE_B8_12_LIVE=1` | real Phase-2 overlay on tmpdir copy: `infra/k8s/envoy-gateway/` present; Kong preserved; Connect/Zitadel/Qwik/pg17 markers; overlay exit 0 |
| L2-02 | FR-B812-014 | `FORGE_B8_12_LIVE=1` | VIII.1/VIII.2: no Kong/Temporal/REST path removed (`diff -rq` vs 1.0.0 base — zero deletions) |
| L2-03 | FR-B812-052 | `FORGE_B8_12_LIVE=1` | methodology flow exercised (doc readable, re-capture step drives the fake-OTLP collector); skip-pass without env |
| L2-04 | FR-B812-034/065 | `FORGE_E2E_TOOLCHAINS=1` | render `transport_connect_client.rs.tmpl` into a minimal tmpdir Rust project + `cargo check` → exit 0 |

When `FORGE_B8_12_LIVE` / `FORGE_E2E_TOOLCHAINS` is unset: each L2 test emits
`SKIP: FORGE_B8_12_LIVE not set` (resp. `FORGE_E2E_TOOLCHAINS`) and contributes 0 failures
(skip is not a FAIL — the b8-1 `FORGE_B8_1_DOCKER` / t5-otel `FORGE_LIVE_RUN_DOCKER` precedent, P-31).

### FR Traceability Table (all 40 FRs + 10 NFRs)

| FR / NFR | Design element | Harness |
|----------|----------------|---------|
| FR-B812-001 | ADR-B812-001: committed 2.0.0 golden span inventory | T-001 |
| FR-B812-002 | ADR-B812-001: 3-span superset (P-10) | T-002 |
| FR-B812-003 | ADR-B812-001: phantom absent (P-11) | T-003 |
| FR-B812-004 | ADR-B812-001: sanitised goldens (P-16) | T-004 |
| FR-B812-005 | ADR-B812-001: hermetic fake-OTLP `diff -q` (P-15/P-17) | T-002/T-004 |
| FR-B812-006 | ADR-B812-001: no-committed-p99 negative guard (P-30) | T-017 |
| FR-B812-010 | ADR-B812-004: Phase 0 dry-run exit 0 on 1.0.0 (P-12) | T-005 |
| FR-B812-011 | ADR-B812-004: dry-run additive-delta lines + no mutation (P-14) | T-006 |
| FR-B812-012 | ADR-B812-004: committed c1 git-clean (P-21) | T-008 |
| FR-B812-013 | ADR-B812-004: L2 real overlay additive (P-13) | L2-01 |
| FR-B812-014 | ADR-B812-004: L2 Kong/Temporal/REST preserved | L2-02 |
| FR-B812-015 | ADR-B812-004: exit-7 wrong-version (P-12) | T-007 |
| FR-B812-020 | ADR-B812-004: demo `.feature` intact (P-19 paths) | T-009 |
| FR-B812-021 | ADR-B812-004: `.proto` contracts preserved (P-22) | T-008 (+ L2 diff) |
| FR-B812-022 | ADR-B812-004: demo-004 stays `specified` (P-20) | T-010 |
| FR-B812-023 | ADR-B812-004: demo G/W/T sentinel | T-009 |
| FR-B812-030 | ADR-B812-003: client template present | T-011 |
| FR-B812-031 | ADR-B812-003: connectrpc =0.6.1 sentinel (P-23/P-24) | T-012/T-013 |
| FR-B812-032 | ADR-B812-003: auth/TLS/deadline/retry posture (P-01) | T-012 |
| FR-B812-033 | ADR-B812-003: 1.0.0 + 2.0.0 server adapter frozen (P-25) | T-020 |
| FR-B812-034 | ADR-B812-003: cargo-check L2 opt-in (P-31) | L2-04 |
| FR-B812-035 | ADR-B812-003: transport.yaml versions_2_0_0 pin (P-23) | T-013 |
| FR-B812-040 | ADR-B812-002: Envoy-OIDC templates in 2.0.0 subtree (P-26) | T-014 |
| FR-B812-041 | ADR-B812-002: SecurityPolicy apiVersion verify-then-pin (P-03) | T-014 (+ impl re-verify) |
| FR-B812-042 | ADR-B812-002: backend JWT middleware present | T-015 |
| FR-B812-043 | ADR-B812-002: Zitadel discovery URL verify-then-pin (P-04) | impl re-verify (T-016 cross-ref) |
| FR-B812-044 | ADR-B812-002: identity.yaml@1.1.0 cross-ref (P-29) | T-016 |
| FR-B812-045 | ADR-B812-002: 1.0.0 Kong infra byte-unchanged | T-020 |
| FR-B812-050 | ADR-B812-001: methodology doc → MIGRATIONS.md (Q-005) | T-018 |
| FR-B812-051 | ADR-B812-001: no committed number in the doc (P-30) | T-017/T-018 |
| FR-B812-052 | ADR-B812-001: opt-in methodology leg skip-pass | L2-03 |
| FR-B812-060 | harness file created + executable + audit header | harness structure (T-019..T-023) |
| FR-B812-061 | harness structure: --level, _helpers.sh, run_test/print_summary | harness structure |
| FR-B812-062 | L1 hermetic ~14 tests ≤ a few seconds | T-001..T-023 |
| FR-B812-063 | fake-OTLP stdlib-only guard (P-15/P-18) | T-019 |
| FR-B812-064 | L2 FORGE_B8_12_LIVE real migrate + recapture | L2-01/L2-03 |
| FR-B812-065 | L2 FORGE_E2E_TOOLCHAINS cargo-check | L2-04 |
| FR-B812-066 | forge-ci.yml registration (P-31) | T-022 |
| FR-B812-067 | CHANGELOG anchored b8-12-e2e-migration (P-31) | T-021 |
| FR-B812-068 | coupling guards b8-1 + b8-10 (P-32) | T-023 |
| NFR-B812-001 | L1 wall-clock ≤ a few seconds hermetic | testing strategy note |
| NFR-B812-002 | full ~51-harness suite GREEN pre-push | implementation note |
| NFR-B812-003 | frozen 1.0.0 templates + c1 byte-identity | T-008/T-020 |
| NFR-B812-004 | NO committed latency number (III.4 + ADR-B8-1-002) | T-017/T-018 |
| NFR-B812-005 | verify-then-pin LIVE: connectrpc client API + Envoy API + Zitadel issuer | evidence.md P-01..P-04 + impl re-read |
| NFR-B812-006 | goldens deterministic (ts redacted, no IPv4) (P-16) | T-004 |
| NFR-B812-007 | zero new external dep (stdlib collector) (P-18) | T-019 |
| NFR-B812-008 | VIII.1/VIII.2 preserved (additive-only) | T-008/T-020/L2-02 |
| NFR-B812-009 | independent review before /forge:plan + pre-archive | not self-approved here |
| NFR-B812-010 | committed c1 stays 1.0.0 throughout (P-21) | T-008/T-010 |

### TDD Order (Article I RED → GREEN)

1. **RED**: commit `b8-12.test.sh` with all ~14 L1 assertions before any template/golden/doc
   exists. T-001..T-023 fail immediately (no golden, no client template, no Envoy-OIDC template,
   no methodology section, no CHANGELOG/CI entry).
2. **GREEN — golden span inventory**: author the 2.0.0 after-state golden (superset of P-10,
   phantom absent P-11, sanitised P-16). T-001/T-002/T-003/T-004 green.
3. **GREEN — migration dry-run wiring**: confirm the tmpdir-copy dry-run + exit-7 negative.
   T-005/T-006/T-007/T-008 green.
4. **GREEN — demo-survival**: confirm the P-19/P-20 paths. T-009/T-010 green.
5. **GREEN — S2S client template**: LIVE re-read connectrpc client API (P-01) + the `client`
   feature flag (P-24) first; author `transport_connect_client.rs.tmpl` + Cargo.toml.tmpl edit.
   T-011/T-012/T-013/T-020 green.
6. **GREEN — Envoy-OIDC**: LIVE re-read the v1.8.x SecurityPolicy/JWT shape (P-03) + the Zitadel
   jwks path (P-04) + the backend JWT middleware shape; author the templates + kustomization edit.
   T-014/T-015/T-016 green. If unpinnable → middleware-only + documented stub (ADR-B812-002 fallback).
7. **GREEN — methodology + anti-latency guard**: append the MIGRATIONS.md section (no number).
   T-017/T-018 green.
8. **GREEN — collector guard + CHANGELOG + CI**: T-019/T-021/T-022 green.
9. **GREEN — coupling guards**: `b8-1.test.sh` + `b8-10.test.sh` --level 1. T-023 green.
10. **POST-flip re-run** (NFR-B812-002): full ~51-harness suite (mirror forge-ci loop) + gates
    re-run POST status-flip; sibling repo-wide scans confirmed GREEN; `N.N.N/` subtree skip honoured.

---

## Standards Applied

| Standard | Role in this change |
|----------|---------------------|
| `transport.yaml` v1.3.0 `versions_2_0_0` (P-23) | CONSUMED — connectrpc =0.6.1 pin for the S2S client template. NOT bumped. |
| `gateway.yaml` v1.0.0 (P-28) | CONSUMED — Envoy Gateway v1.8.0 control-plane pin; the SecurityPolicy/JWT templates target the same chart. NOT bumped. |
| `identity.yaml` v1.1.0 (P-29) | CONSUMED + cross-referenced — Zitadel issuer / chart 10.0.2 / appVersion v4.14.0; the Envoy-OIDC templates carry an `identity.yaml@1.1.0` comment. NOT bumped. |
| `global/source-document-pinning.md` | Provenance table in `evidence.md` (P-01..P-33; external URLs + internal file:line + read date + what it proves). |
| `global/open-questions.md` | Q-001..Q-005 resolved → ADR-B812-001..004 (independent reviewer ratifies before `/forge:plan`). |
| `global/forge-self-ci.md` | Harness registration in the forge-ci.yml declarative loop (≤ 300-line budget). |
| `scaffolding.md` | `N.N.N/` subtree skip convention — the 2.0.0 templates live under the versioned subtree; repo-wide scanners exempt it. |

**No standard is created or bumped (Finding 4).** B.8.12 is pure additive — templates +
goldens + a doc section + a harness + a CHANGELOG entry + a CI line — consuming the three
pin sources as inputs. The T5.1 / B.8.10 no-standard-bump precedent applies.
`constitution_version: 1.1.0` unchanged.

---

## Constitutional Compliance Gate

- **Article I (TDD RED-first)**: `b8-12.test.sh` is committed with all ~14 L1 assertions
  BEFORE any template/golden/doc exists (TDD Order step 1). Tests fail RED, then turn GREEN
  per the order. No production-equivalent file precedes its test.

- **Article II (BDD)**: the golden-superset flow ships a `.feature` (Given a migrated c1 / When
  spans are captured / Then the 1.0.0 span set is a subset / And no phantom appears) — the
  BDD acceptance scenarios in specs.md are the Given/When/Then contract; the harness's awk
  G/W/T sentinel (T-009) also guards the demo `.feature` files.

- **Article III.1/III.2 (Specs before code)**: design follows specs (both in
  `.forge/changes/b8-12-e2e-migration/`); no template/golden/doc is authored before this design.

- **Article III.4 (Anti-Hallucination) — CENTRAL**: (a) NO committed p95/p99 number — the
  negative guard (T-017/T-018, FR-B812-006/051) is machine-verified; `fsm-backend = image: scratch`
  (P-30) + ADR-B8-1-002 ground it. (b) The connectrpc client API (ADR-B812-003) is read from the
  upstream README (P-01), not fabricated; the retry knob + the `client` Cargo feature flag (P-24)
  are flagged VERIFY-AT-IMPLEMENT. (c) The Envoy SecurityPolicy apiVersion/kind + JWT shape
  (ADR-B812-002) are read from the v1.8 docs (P-03); the Zitadel jwks path (P-04) is pinned only
  to the discovery URL — the exact `/oauth/v2/keys` path is VERIFY-AT-IMPLEMENT; the backend JWT
  middleware shape is VERIFY-AT-IMPLEMENT; the documented fallback (middleware-only + gateway stub)
  bars fabrication (ADR-B87-006). (d) The 3-span baseline + phantom (P-10/P-11), the migration
  driver surface (P-12/P-13/P-14), and the demo paths (P-19/P-20) are quoted live facts.

- **Article IV (Delta-based)**: all artifacts are ADDITIVE — new templates, a new golden, a new
  doc section, a new harness, a CHANGELOG entry, a CI line. The 1.0.0 + 2.0.0 server adapters,
  the 1.0.0 Kong infra, the three standards, the migration driver, and the committed c1 are
  read-only inputs. No spec rewrite, no schema mutation.

- **Article V (Compliance gate)**: ADR-B812-001..004 encode all five resolved open questions
  (Q-005 folds into ADR-B812-001). The coupling guards (b8-1 + b8-10) re-run at TDD step 9. The
  full ~51-harness suite + gates re-run POST-flip (NFR-B812-002; full_harness_suite +
  shared_standard_sibling lessons).

- **Article VII (Hexagonal)**: the S2S client template is a transport adapter — no business
  logic; it mirrors the server adapter's hexagonal posture (P-25). The backend JWT middleware
  is an inbound infrastructure concern (a tower layer), not a domain rule.

- **Article VIII.1 (Kong SHALL — PRESERVED)**: the migration overlay adds Envoy in parallel and
  never removes Kong (FR-B812-014, L2-02). The SecurityPolicy/JWT templates JOIN the existing
  envoy-gateway dir additively (P-26). 2.0.0 stays `scaffoldable: false` until B.8.14. No violation.

- **Article VIII.2 (Temporal SHALL — PRESERVED)**: the additive overlay preserves Temporal +
  REST-bridge paths (FR-B812-014, L2-02, NFR-B812-008). No DBOS leg is introduced. No violation.

- **Article XII (Governance)**: no Constitution amendment; `constitution_version: 1.1.0` unchanged.
  No standard bump (Finding 4). No governance change.

**No violations. Gate PASS** (subject to independent review — NOT self-approved here).

---

## Anti-Hallucination Pass (Design Phase)

- **No committed p95/p99 number anywhere** (central): `fsm-backend = image: scratch` (P-30);
  ADR-B8-1-002 bars committed latency. FR-B812-006/051 + the harness negative guard (T-017/T-018)
  encode this as a machine-verified invariant. The methodology doc commits only relative
  rollback thresholds (percentages), never a frozen ms value.

- **connectrpc client API is quoted from the README (P-01), not fabricated**: the four posture
  knobs (auth via `with_default_header`, TLS via `with_tls`, deadline via `with_default_timeout`
  + `CallOptions::with_timeout`, retry) map to documented methods. The retry knob shape and the
  `client` Cargo feature flag (P-24) are flagged VERIFY-AT-IMPLEMENT — not invented.

- **Envoy SecurityPolicy/JWT read from v1.8 docs (P-03), distinct group confirmed**:
  `gateway.envoyproxy.io/v1alpha1` (SecurityPolicy) is NOT conflated with the
  `gateway.networking.k8s.io/v1` used by the existing Gateway/HTTPRoute (P-27). The
  `remoteJWKS.backendRefs`→Backend form is flagged VERIFY-AT-IMPLEMENT against the exact v1.8.x doc.

- **Zitadel jwks path NOT pinned beyond the discovery URL (P-04)**: `/oauth/v2/keys` is named
  only as a convention; resolved at implement from the live discovery doc (ADR-B87-006).

- **Backend JWT middleware shape is VERIFY-AT-IMPLEMENT**: the tower `Layer`/`Service` shape,
  the validation crate, and the JWKS fetch are not fabricated; the template carries documented
  stubs + posture until the live shape is pinned at implement.

- **Demo paths corrected from a live `ls` (P-19/P-20)**: the demo `.feature` files live under
  `.forge/changes/demo-NNN-*/features/` inside the c1 example (NOT `test/features/`, the spec
  guess); demo-004 has no feature file and stays `specified`. The design pins the real paths.

- **B.8.12 bumps no standard (Finding 4)**: transport.yaml/gateway.yaml/identity.yaml are
  consumed and cross-referenced, not edited — a live read confirms.

- **Independent review required (NFR-B812-009)**: this design is NOT self-approved. The
  Constitutional Compliance Gate PASS is the author's assessment; an independent reviewer ratifies
  before `/forge:plan`. The VERIFY-AT-IMPLEMENT items are re-read LIVE at `/forge:implement`.

---

## Open Items / Carry Items for `/forge:implement`

- **CARRY-1 (connectrpc `client` Cargo feature flag, P-24)** — VERIFY-AT-IMPLEMENT: confirm the
  EXACT connectrpc 0.6.1 feature flag for the client surface (`client` vs feature-implied by
  default) against the live crate `Cargo.toml`/docs. Then either add `features = ["axum", "client"]`
  to `Cargo.toml.tmpl` OR document that the client surface is feature-implied. Blocks T-012/L2-04
  if mis-set.

- **CARRY-2 (Zitadel jwks path, P-04)** — VERIFY-AT-IMPLEMENT: read the live Zitadel discovery doc
  (`https://<ExternalDomain>/.well-known/openid-configuration`) and extract the exact `jwks_uri`
  path; do NOT hardcode `/oauth/v2/keys` beyond the discovery URL. Feeds the SecurityPolicy
  `remoteJWKS` Backend.

- **CARRY-3 (backend JWT middleware shape)** — VERIFY-AT-IMPLEMENT: confirm the tower `Layer`/`Service`
  shape + the JWT validation crate + the JWKS fetch posture (issuer/audience checks) for the
  connectrpc/axum backend; do NOT fabricate. Land documented stubs if the shape is not cleanly pinnable.

- **CARRY-4 (Envoy SecurityPolicy v1.8.x form, P-03)** — VERIFY-AT-IMPLEMENT: confirm whether v1.8.x
  folds JWT into `SecurityPolicy.spec.jwt.providers[]` or exposes a separate JWTAuthn resource, and
  the exact `remoteJWKS.backendRefs`→Backend shape. If unpinnable cleanly → middleware-only +
  documented gateway stub (ADR-B812-002 fallback), recorded in evidence.md + open-questions.md.

- **CARRY-5 (LIVE re-read at implement, b8-coroot lesson)**: before authoring any template, re-read
  P-01 (connectrpc client README), P-03 (Envoy v1.8 SecurityPolicy/JWT), P-04 (Zitadel discovery),
  P-23 (transport.yaml pins still =0.6.1), P-12/P-13/P-14 (migration driver unchanged), and the
  demo paths P-19/P-20.

- **Independent review follows** — this design is NOT self-approved. The note "maintainer decision
  pending INDEPENDENT reviewer ratification before /forge:plan" is recorded in `open-questions.md`.
