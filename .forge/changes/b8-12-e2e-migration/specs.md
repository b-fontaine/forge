# Specifications: b8-12-e2e-migration

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.12 (docs/new-archetypes-plan.md §4.2 B.8.12 — "Tests E2E migration :
     c1-reference-project migré vers 2.0.0, captures p95/p99 avant/après, 0 régression
     sur les 4 demos." GROUND-TRUTH NOTES (Article III.4): (1) p50/p95/p99 CANNOT be
     captured from unmodified c1 (fsm-backend = image:scratch placeholder, B8-BASELINE §3
     / FR-B8-1-012; ADR-B8-1-002 = "methodology + optional sample, NEVER committed live
     numbers" — faking latency violates III.4); the real hermetic before/after gate is a
     SPAN-INVENTORY / golden-span-tree REGRESSION (.forge/baselines/
     full-stack-monorepo-1.0.0.span-inventory.yaml, 3 code-verified spans on demo-005).
     (2) 3-span vs 4-span: demo-005 doc draws 4 spans, only 3 are real instrument sites;
     the phantom is Flutter user.interaction greet root — no startSpan in frontend/lib;
     B.8.12 asserts the 3 code-verified spans ONLY. (3) "migrate c1 to 2.0.0" =
     invoke bin/forge-migrate-flagship.sh against a COPY (dry-run hermetic L1 + opt-in
     real Phase-2 overlay L2); committed examples/forge-fsm-example/ stays 1.0.0
     (frozen). (4) B.8.12 is the named landing point for the Rust S2S Connect client
     (ADR-B86-004) and the Envoy-OIDC wiring (ADR-B87-006; SecurityPolicy + JWTAuthn +
     backend JWT validation middleware — verify-then-pin Envoy Gateway API LIVE at
     /forge:design, ADR-B87-006 barred fabrication). (5) CI: Python+Node+shellcheck only,
     no cargo/flutter/docker — L1 hermetic + L2 opt-in. (6) "4 demos" = demo-001..004
     (demo-005 is T.5 Connect demo, separate); demo-004 stays specified. (7) Qwik→OTel
     wiring is NOT B.8.12 — routes to B.7. -->

**Namespace**: `FR-B812-*` / `NFR-B812-*`.
**Constitution**: v1.1.0, unchanged (no amendment — this change is additive and
extends the convergence gate; no constitutional principle is altered).
**Governing articles**: I (TDD — harness RED-first; templates asserted before
they exist), II (BDD — Given/When/Then before implementation), III.4 (Anti-
Hallucination — central: no fabricated connectrpc client API symbols, no
fabricated Envoy Gateway SecurityPolicy apiVersion/kind, no fabricated Zitadel
OIDC discovery URL, no committed p95/p99 number; all verify-then-pin LIVE at
/forge:design), IV (delta-based: ADDED FRs only), V (harness + gates before flip;
full ~51-harness suite pre-push; POST-flip re-run), VIII.1 (Kong SHALL — additive
overlay; Kong preserved), VIII.2 (Temporal SHALL — additive overlay; Temporal
preserved).

No prior `.forge/specs/` file owns E2E migration regression, Rust S2S Connect
client, or Envoy-OIDC wiring. All requirements below are therefore **ADDED**
(Article IV delta-based).

## GROUND-TRUTH FINDINGS (Article III.4)

**Ground truth (re-read 2026-06-04):**

- **The real, hermetic before/after gate is a span-inventory / golden-span-tree
  regression.** The 1.0.0 before-state is `.forge/baselines/full-stack-monorepo-
  1.0.0.span-inventory.yaml` — 3 code-verified spans on demo-005-connect-greeting:
  (1) `<http-method> <path>` otel_kind=client (Flutter dio TracingInterceptor,
  `SpanKind.client` marker, `examples/forge-fsm-example/frontend/lib/core/
  telemetry/interceptors/tracing_interceptor.dart`); (2) `http.request`
  otel_kind=server (Rust tower-http make_span_with, `otel.kind = "server"` marker,
  `backend/crates/infrastructure/src/telemetry/middleware.rs`); (3) `greeter.greet`
  otel_kind=internal (`#[tracing::instrument]` GreetUseCase, `name = "greeter.greet"`
  marker, `backend/crates/application/src/greet.rs`). No committed live p95/p99
  number exists or will exist (ADR-B8-1-002 + III.4).
- **3-span / 4-span correction is a hard fact.** The demo-005 doc waterfall draws
  a 4-span tree; only 3 are real instrument sites. The phantom is the Flutter
  `user.interaction greet` root span — there is no `startSpan('user.interaction …')`
  in `frontend/lib`. B.8.12 MUST assert the 3 code-verified spans, not the phantom.
- **"Migrate c1" = invoke B.8.10 against a COPY.** 2.0.0 is `scaffoldable: false`
  until B.8.14. B.8.12 runs `bin/forge-migrate-flagship.sh --target <tmpdir-copy>`
  (Phase 0 preflight + `--dry-run` plan assertion at L1; opt-in real Phase-2 overlay
  at L2 via `FORGE_B8_12_LIVE`). The additive overlay result: Envoy templates added
  alongside Kong (VIII.1 preserved), Connect, Zitadel, Qwik, pg17; Kong/Temporal/
  REST paths NEVER removed (VIII.2 preserved). The committed
  `examples/forge-fsm-example/` stays at 1.0.0 (frozen reference; git-clean after).
- **Rust S2S Connect client is a named deferral landing here.** ADR-B86-004
  (b8-6-connect-rpc, 2026-06-02): the `transport_connect_client.rs.tmpl` was
  explicitly re-deferred from B.8.6 to B.8.12 as the target landing. The
  connectrpc 0.6.x crate provides client-side primitives; the exact API symbols
  (`ClientConfig`, `CallOptions`, etc.) MUST be verify-then-pin LIVE at
  /forge:design (ADR-B812-003) — they are NOT fabricated here. Transport.yaml
  `versions_2_0_0` block pins (`connectrpc =0.6.1`, `buffa =0.6.0`) are the
  AUTHORITATIVE observed pins (transport.yaml v1.3.0, observed 2026-06-04).
- **Envoy-OIDC wiring is a named deferral landing here.** ADR-B87-006
  (b8-7-zitadel, 2026-06-02): the Envoy SecurityPolicy, JWTAuthn filter, and
  backend JWT validation middleware were explicitly deferred from B.8.7/B.8.10 to
  B.8.12. ADR-B87-006 barred fabricating Envoy Gateway API versions and Zitadel
  OIDC discovery URL patterns — these are verify-then-pin LIVE at /forge:design
  (ADR-B812-002). Identity.yaml v1.1.0 records the Zitadel chart-tested pair:
  chart `10.0.2` / appVersion `v4.14.0` (ghcr.io, v-prefix convention).
- **CI toolchain reality**: Python 3.11 + Node + shellcheck only — no cargo,
  flutter, docker. All harnesses run `--level 1`. B.8.12 is L1 hermetic + L2
  opt-in (`FORGE_B8_12_LIVE` / `FORGE_E2E_TOOLCHAINS`), reusing the t5-otel-live-
  run fake-OTLP-collector (Python stdlib, no third-party imports) + sanitized
  golden-capture (`diff -q` vs committed golden, `"<ts:redacted>"` placeholder)
  pattern.
- **"4 demos" = demo-001..004 (demo-005 is T.5, separate).** The 0-regression
  assertion covers demo-001..004 `.feature` files, proto contracts, and spec FRs
  surviving the 2.0.0 overlay byte-intact (additive overlay NEVER rewrites demos).
  Demo-004 stays `specified` (the Article III.4 anti-hallucination demo, frozen
  at spec). Qwik→OTel is NOT B.8.12 — routes to B.7 (ai-native-rag).
- **Kong-pin drift corrected.** B8-BASELINE §1 corrected `kong:3.6-alpine` →
  `kong:3.6` (the `-alpine` tag was pulled). The after-state golden and additive-
  overlay assertions trust `kong:3.6` as the 1.0.0 shipped pin.
- **`forge-migrate-flagship.sh` Phase/flag surface (observed, bin/forge-migrate-
  flagship.sh, 2026-06-04):** `--target <dir>`, `--phase 0|1|2|3|4|all`,
  `--dry-run` (mutates nothing; prints plan), `--force`; exit-codes 0/2/5/7/8.
  Phase 0 = preflight (manifest read + git-clean gate + snapshot sha256 verify);
  Phase 2 = structural overlay (additive 3-way merge via sourced _a7_* library);
  `--phase all` = Phase 0 + Phase 1 + Phase 2.

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4.2 B.8.12 — "Tests E2E migration : c1-reference-project migré vers 2.0.0" |
| **Before-state baseline (observed)** | `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml` — archetype: full-stack-monorepo, version: 1.0.0, captured: 2026-05-29, demo: demo-005-connect-greeting, spans: 3 code-verified |
| **3-span correction** | `B8-BASELINE.md §5` + span-inventory notes: "Only THREE are real instrument sites. The PHANTOM span is the Flutter `user.interaction greet` ROOT." |
| **No committed latency (ADR-B8-1-002)** | `docs/B8-BASELINE.md §3`: "live end-to-end latency (p50/p95/p99) cannot be captured from the example dev compose unmodified" (backend = image:scratch); §6 methodology: "none committed" sample |
| **Migration driver (observed)** | `bin/forge-migrate-flagship.sh` — flags: `--target`, `--dry-run`, `--phase 0|1|2|all`; exit-codes 0/2/5/7/8; Phase 2 additive 3-way merge; constitutional invariant: "ADDITIVE-ONLY: never removes Kong, Temporal, or REST-bridge paths (VIII.1/VIII.2)" |
| **S2S client deferral** | ADR-B86-004 (`.forge/changes/b8-6-connect-rpc/design.md`): "explicitly re-deferred to B.8.12 … target landing"; connectrpc 0.6.x client primitives; verify-then-pin LIVE at /forge:design |
| **Envoy-OIDC deferral** | ADR-B87-006 (`.forge/changes/b8-7-zitadel/design.md`): "Envoy SecurityPolicy, JWTAuthn filter, and backend JWT validation middleware … deferred to B.8.10 … and B.8.12"; barred fabricating API versions / Zitadel issuer URL |
| **transport.yaml versions_2_0_0 (observed)** | `.forge/standards/transport.yaml` v1.3.0: `connectrpc: "=0.6.1"`, `connectrpc-build: "=0.6.1"`, `buffa: "=0.6.0"`, `buffa-types: "=0.6.0"` (re-verified LIVE 2026-06-02) |
| **identity.yaml v1.1.0 (observed)** | `.forge/standards/identity.yaml`: `zitadel_chart: "10.0.2"`, `zitadel: "v4.14.0"`, `zitadel_login: "v4.14.0"`, ghcr.io registry, v-prefix convention |
| **Fake-OTLP pattern (observed)** | `.forge/scripts/tests/t5-otel-live-run.test.sh`: Python stdlib only fake collector; `"<ts:redacted>"` sanitiser placeholder; `diff -q` golden comparison; L2 gated on `FORGE_LIVE_RUN_DOCKER=1` |
| **L2 opt-in pattern (observed)** | `.forge/scripts/tests/b8-1.test.sh` uses `FORGE_B8_1_DOCKER`; t5-otel-live-run uses `FORGE_LIVE_RUN_DOCKER`; B.8.12 uses `FORGE_B8_12_LIVE` / `FORGE_E2E_TOOLCHAINS` |
| **Release target** | v0.4.0-rc.14 |

---

## ADDED Requirements

### Functional Requirements

#### Group 1 — Golden-span-tree regression gate (FR-B812-001 → 006)

##### FR-B812-001 — Committed 2.0.0 after-state golden span inventory present
A committed 2.0.0 after-state golden span inventory file MUST exist at
`.forge/changes/b8-12-e2e-migration/captures/full-stack-monorepo-2.0.0.span-inventory.yaml`
(or equivalent path under `.forge/changes/b8-12-e2e-migration/captures/`). The file
MUST use the same schema as the before-state baseline (`archetype`, `version`, `captured`,
`demo`, `spans` list with `name`, `otel_kind`, `layer`, `source`, `verified_marker`,
`role` fields). Testable: `[ -f .forge/changes/b8-12-e2e-migration/captures/full-stack-monorepo-2.0.0.span-inventory.yaml ]` → exit 0;
`grep "archetype: full-stack-monorepo" <file>` → exit 0; `grep "version: \"2.0.0\""` → exit 0.

##### FR-B812-002 — 2.0.0 golden is a SUPERSET of the 1.0.0 baseline (3 code-verified spans preserved)
The 2.0.0 after-state golden MUST contain all 3 code-verified spans from
`.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml`:
(1) a span with `otel_kind: client` and `verified_marker` containing `SpanKind.client`;
(2) a span named `http.request` with `otel_kind: server` and `verified_marker` containing
`otel.kind = "server"`; (3) a span named `greeter.greet` with `otel_kind: internal` and
`verified_marker` containing `name = "greeter.greet"`.
The 2.0.0 golden MAY contain additional spans (additive — new 2.0.0 instrumentation);
it MUST NOT omit any of the 3. Testable: `grep "SpanKind.client"` → exit 0;
`grep "http.request"` → exit 0; `grep "greeter.greet"` → exit 0 — all in the 2.0.0 golden file.

##### FR-B812-003 — Phantom Flutter root span NOT in either golden
Neither the 1.0.0 baseline nor the 2.0.0 golden MUST contain any span with
`name: "user.interaction"` or `name: "user.interaction greet"` (the phantom Flutter root
span documented in B8-BASELINE §5 and the span-inventory notes). B.8.12 asserts the
3 code-verified spans, not the doc's phantom root. Testable:
`grep "user.interaction" .forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml` →
zero matches; `grep "user.interaction" .forge/changes/b8-12-e2e-migration/captures/full-stack-monorepo-2.0.0.span-inventory.yaml` → zero matches.

##### FR-B812-004 — Goldens are sanitized (timestamps redacted, no IPv4)
Both the before-state baseline and the 2.0.0 after-state golden (and any companion
`.golden.json` capture files) MUST be deterministic artifacts: all timestamp values
MUST use the `"<ts:redacted>"` placeholder (the t5-otel-live-run pattern), and no
raw IPv4 dotted-quad pattern MUST appear as a JSON string value. The span-inventory
YAML files MUST carry no `captured_at:` timestamp value beyond a date string. Testable:
`grep '"<ts:redacted>"' <golden.json>` → exit 0 (for JSON captures);
`grep -E '"([0-9]{1,3}\.){3}[0-9]{1,3}"' <golden>` → zero matches.

##### FR-B812-005 — Golden superset assertion runs via the hermetic fake-OTLP collector (Python stdlib)
The harness `b8-12.test.sh` L1 MUST drive the before/after golden comparison using
the hermetic fake-OTLP collector pattern (Python stdlib only — no third-party imports
such as `protobuf`, `grpc`, `requests`, `opentelemetry`; mirroring the
`t5-otel-live-run.test.sh` `_test_olr_002_collector_stdlib_only` guard). The
golden superset `diff -q` assertion MUST complete without Docker, without cargo,
without flutter, within the L1 budget (≤ a few seconds wall-clock). The assertion
is: `diff -q <1.0.0-baseline-extracted-spans> <2.0.0-golden-spans>` with the
3-span names verified present in the 2.0.0 set. Testable: `bash b8-12.test.sh --level 1`
exits 0 on CI (Python 3.11, no toolchains).

##### FR-B812-006 — No committed p95/p99 number anywhere in the b8-12 change tree
No file in `.forge/changes/b8-12-e2e-migration/` MUST contain a committed numeric
p95 or p99 latency figure (e.g., `"p99: 42ms"`, `p99_ms: 38`, any pattern
`p9[59].*[0-9]+\s*(ms|s|µs)`). This is the III.4 + ADR-B8-1-002 hard invariant:
faking a p95/p99 number is a constitutional violation. Testable (the anti-faked-
latency guard): `grep -rE 'p9[59][^a-z].*[0-9]+\s*(ms|µs|s\b)' .forge/changes/b8-12-e2e-migration/` → zero matches.

---

#### Group 2 — Migration E2E driver (FR-B812-010 → 015)

##### FR-B812-010 — L1 hermetic: Phase 0 preflight passes on the 1.0.0 manifest
The harness `b8-12.test.sh` L1 MUST invoke
`bin/forge-migrate-flagship.sh --target <tmpdir-copy-of-c1> --dry-run`
and assert it exits 0. The tmpdir copy MUST be a fresh `cp -r` of
`examples/forge-fsm-example/` into `$(mktemp -d)` with a clean `.forge/scaffold-manifest.yaml`
containing `archetype: full-stack-monorepo` and `archetype_version: 1.0.0`. Phase 0
preflight MUST pass (exit 0) on this manifest, confirming the 1.0.0 manifest structure
is recognized. The tmpdir is cleaned up via `trap`. Testable: the harness test function
`_test_b812_l1_migrate_dryrun` exits 0 on CI.

##### FR-B812-011 — L1 hermetic: `--dry-run` plan output asserts additive deltas, no mutation
The `--dry-run` output from `forge-migrate-flagship.sh` MUST contain the additive-
delta summary lines (observed from `_b810_phase0_preflight` dry-run block):
`"Kong → Envoy Gateway"` (B.8.4), `"REST-bridge → Connect-RPC"` (B.8.6),
`"implicit-auth → Zitadel"` (B.8.7), `"no-web → Qwik web-public"` (B.8.9),
`"postgres-16 → 17 + pgvector"` (B.8.5), and the invariant line
`"(Kong / Temporal / REST preserved — additive only, removal is B.8.14.)"`.
MUST mutate nothing in the tmpdir. Testable:
`grep "Kong / Temporal / REST preserved" <dry-run-output>` → exit 0;
`git -C <tmpdir> status --porcelain` → empty (no mutations after `--dry-run`).

##### FR-B812-012 — L1 hermetic: committed c1 example stays 1.0.0 (git-clean after)
After running any L1 harness test (including the tmpdir-copy migration), the
committed `examples/forge-fsm-example/` MUST be byte-unchanged. The harness MUST
assert `git diff --quiet examples/forge-fsm-example/` exits 0 after all L1 tests.
The c1 example's `scaffold-manifest.yaml` MUST still carry `archetype_version: 1.0.0`.
Testable: `git diff --quiet examples/forge-fsm-example/` → exit 0 after the harness L1 block;
`grep "archetype_version: 1.0.0" examples/forge-fsm-example/.forge/scaffold-manifest.yaml` → exit 0.

##### FR-B812-013 — L2 opt-in (FORGE_B8_12_LIVE): real Phase-2 overlay asserts additive result
When `FORGE_B8_12_LIVE=1` is set, the harness MUST run the real Phase-2 overlay
(not `--dry-run`) against the tmpdir copy and assert the additive result:
(a) Envoy Gateway templates are present in the result (`infra/k8s/envoy-gateway/`
directory exists); (b) Kong is preserved (`infra/k8s/` Kong manifests or
docker-compose kong service still present); (c) Connect crate markers, Zitadel
markers, Qwik markers, and pg17 markers are detectable in the result tree; (d) no
Kong/Temporal/REST-bridge path was removed. When `FORGE_B8_12_LIVE` is unset, L2
MUST emit `SKIP: FORGE_B8_12_LIVE not set` and contribute 0 failures. Testable:
with `FORGE_B8_12_LIVE=1` → all four sub-assertions exit 0; without it → skip-pass.

##### FR-B812-014 — L2 opt-in: VIII.1 / VIII.2 invariant: Kong + Temporal + REST NOT removed
The L2 real overlay result MUST NOT remove any Kong-related path or Temporal-related
path or REST-bridge path from the tmpdir. Concretely: `grep -r "kong" <result>/docker-compose*.yml`
→ exit 0; no `kong` or `temporal` or `rest-bridge` path under `infra/` is deleted
vs the 1.0.0 base. The `forge-migrate-flagship.sh` constitutional invariant
("ADDITIVE-ONLY: never removes Kong, Temporal, or REST-bridge paths") is verified
behaviorally, not assumed. Testable: the L2 sub-assertion for removal exits 0
(no removed paths detected via `diff -rq`).

##### FR-B812-015 — Exit-code envelope: Phase 0 exits 7 on wrong-version input
The harness MUST include a negative test: create a tmpdir with a manifest carrying
`archetype_version: 2.0.0` (already-migrated) and assert `forge-migrate-flagship.sh
--target <tmpdir> --dry-run` exits 7 (precondition not met — wrong-version, observed
from `_b810_phase0_preflight` `wrong-version:` branch). This validates the exit-code
envelope without mutation. Testable: `bash forge-migrate-flagship.sh --target <bad-tmpdir>
--dry-run; echo $?` → 7.

---

#### Group 3 — Zero regression on the 4 demos (FR-B812-020 → 023)

##### FR-B812-020 — demo-001..004 `.feature` files byte-intact after additive overlay
The four demo `.feature` files under `examples/forge-fsm-example/test/features/`
(or `docs/`) corresponding to demo-001, demo-002, demo-003, and demo-004 MUST be
byte-unchanged after the L2 additive overlay. The additive overlay NEVER rewrites
demo feature files (they are not in the 2.0.0 RIGHT template set). Testable:
`git diff --quiet <path-to-demo-001..004-feature-files>` → exit 0 after L2 overlay.
(L1 hermetic version: `diff -q` the committed feature files vs themselves —
they exist and are non-empty.)

##### FR-B812-021 — proto contracts (`.proto` files) byte-intact after overlay
The proto contract files under `examples/forge-fsm-example/shared/protos/`
MUST be byte-unchanged after the L2 additive overlay. The 2.0.0 overlay adds
templates (new `buf.gen.yaml.tmpl`, new `README.md.tmpl`) but MUST NOT overwrite
committed `.proto` files in the adopter tree (these are preserved paths in the A.7
3-way merge logic). Testable: `git diff --quiet examples/forge-fsm-example/shared/protos/`
→ exit 0 after L2 overlay.

##### FR-B812-022 — demo-004 status stays `specified` (no status flip from overlay)
The demo-004 change entry (`.forge/changes/demo-004-*/`  or equivalent) MUST retain
`status: specified` after the migration overlay. The overlay is additive and targets
`examples/forge-fsm-example/` — it MUST NOT touch `.forge/changes/` metadata.
Testable: `grep "status: specified" .forge/changes/demo-004*/.forge.yaml` → exit 0
(or equivalent path).

##### FR-B812-023 — Demo BDD Given/When/Then structure preserved (contract-survival sentinel)
The harness MUST include a structural check: for each of the 4 demo `.feature` files,
confirm the `Feature:` + at least one `Scenario:` + `Given`/`When`/`Then` structure
is intact (mirroring the `_test_olr_010_feature_file_exists` awk pattern). This is a
sentinel that the overlay did not truncate or corrupt any `.feature` file. Testable:
the harness awk-based Given/When/Then check exits 0 for all 4 demo feature files.

---

#### Group 4 — Rust S2S Connect client (FR-B812-030 → 035)

##### FR-B812-030 — New 2.0.0 template `transport_connect_client.rs.tmpl` present
A new file `transport_connect_client.rs.tmpl` MUST exist at
`.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/src/transport_connect_client.rs.tmpl`
(following the `N.N.N/` subtree convention from B.8.4/B.8.5/B.8.6 precedent).
Testable: `[ -f .forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/src/transport_connect_client.rs.tmpl ]` → exit 0.

##### FR-B812-031 — Client template carries connectrpc 0.6.x sentinels (verify-then-pin)
The `transport_connect_client.rs.tmpl` MUST contain sentinel strings that confirm
it targets the 0.6.x line per transport.yaml `versions_2_0_0` pins:
`connectrpc = "=0.6.1"` (or the exact pin from transport.yaml at implement time)
MUST appear in the companion `Cargo.toml.tmpl` or the template itself. The exact
client API symbols (`ClientConfig`, `CallOptions`, or their 0.6.x equivalents) are
verify-then-pin LIVE at `/forge:design` (ADR-B812-003) and MUST NOT be fabricated
in this spec. Testable: `grep "=0.6" .forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/src/transport_connect_client.rs.tmpl || grep "=0.6" <companion-Cargo.toml.tmpl>` → exit 0.

##### FR-B812-032 — Client template covers auth/TLS/deadline/retry posture (via comments at minimum)
The `transport_connect_client.rs.tmpl` MUST include inline comments or documented
stubs addressing: (a) authentication posture (how the client presents credentials,
e.g., Bearer token injection); (b) TLS configuration; (c) deadline propagation
(context deadline forwarded to outbound calls); (d) retry policy posture. The
exact implementation shape is resolved by ADR-B812-003 at `/forge:design`. The
minimum testable requirement: `grep -E "auth|tls|deadline|retry" .../transport_connect_client.rs.tmpl` → exit 0 (at least one of these terms present). Testable:
`grep -iE "auth|tls|deadline|retry" <template-path>` → exit 0.

##### FR-B812-033 — 1.0.0 server adapter (`transport_connect.rs.tmpl`) byte-UNCHANGED
The existing 1.0.0 flat-tree adapter
`.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/src/transport_connect.rs.tmpl`
(the server-only 0.3.x template) MUST be byte-unchanged. B.8.12 adds a NEW 2.0.0
client template; it MUST NOT modify the 1.0.0 server template. Testable:
`git diff .forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/src/transport_connect.rs.tmpl` → empty (zero diff lines).

##### FR-B812-034 — cargo-check gated behind L2 opt-in (FORGE_E2E_TOOLCHAINS)
The harness MUST NOT invoke `cargo check` or `cargo build` at L1. Cargo invocation
is gated behind `FORGE_E2E_TOOLCHAINS=1` (L2 opt-in). When `FORGE_E2E_TOOLCHAINS` is
unset, any cargo-related test function MUST emit `SKIP: FORGE_E2E_TOOLCHAINS not set` and
contribute 0 failures. When set, the harness renders `transport_connect_client.rs.tmpl`
into a tmpdir with a minimal `Cargo.toml` and runs `cargo check` on it, asserting exit 0.
Testable: without `FORGE_E2E_TOOLCHAINS` → skip-pass; with it → cargo-check exits 0.

##### FR-B812-035 — transport.yaml `versions_2_0_0` pin sentinels present (connectrpc =0.6.1)
The harness L1 MUST assert that `.forge/standards/transport.yaml` contains the
`versions_2_0_0:` block (already shipped by B.8.6) and that the `connectrpc: "=0.6.1"`
pin is present. This couples the client template to the authoritative standard.
Testable: `grep "versions_2_0_0" .forge/standards/transport.yaml` → exit 0;
`grep "connectrpc.*=0.6.1" .forge/standards/transport.yaml` → exit 0.

---

#### Group 5 — Envoy-OIDC wiring (FR-B812-040 → 045)

##### FR-B812-040 — Envoy-OIDC templates present in the 2.0.0 `infra/k8s/envoy-gateway/` subtree
The deferred Envoy-OIDC wiring (ADR-B87-006) MUST be landed as template files
under `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/`.
At minimum a SecurityPolicy template and a JWTAuthn filter configuration template
MUST be present (exact filenames resolved by ADR-B812-002 at `/forge:design`).
Testable: `find .forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/ -name "*security*" -o -name "*jwt*" -o -name "*oidc*"` → at least one file found.

##### FR-B812-041 — Envoy Gateway SecurityPolicy apiVersion/kind NOT fabricated — verify-then-pin LIVE
The Envoy Gateway SecurityPolicy API version (e.g., `apiVersion: gateway.envoy.io/v1alpha1`)
and `kind: SecurityPolicy` (or correct kind) MUST be verify-then-pin LIVE at
`/forge:design` (ADR-B812-002). These symbols MUST NOT appear with fabricated values
in this spec. **RESOLVED (ADR-B812-002, live 2026-06-04): `apiVersion: gateway.envoyproxy.io/v1alpha1`, `kind: SecurityPolicy`, JWT folded into `spec.jwt.providers[]` (Envoy Gateway v1.8.0; no separate JWTAuthn resource).** Testable at implement:
`grep "apiVersion" <security-policy-template>` must match the live Envoy Gateway API
version verified at design time.

##### FR-B812-042 — Backend JWT validation middleware template present (scope per Q-002)
A backend JWT validation middleware template MUST be present under
`.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/` (exact path
resolved by ADR-B812-002 at `/forge:design` — the scope question is whether the
gateway-side templates or the middleware-only or both land here). Per Q-002 lean:
both gateway-side and backend middleware land in B.8.12 unless the Envoy Gateway
API cannot be cleanly pinned live. Testable: `find .forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/ -name "*jwt*" -o -name "*auth*middleware*"` → at least one file found.

##### FR-B812-043 — Zitadel OIDC discovery URL pattern NOT fabricated — verify-then-pin LIVE
The Zitadel OIDC discovery URL pattern (e.g., `https://<host>/.well-known/openid-configuration`)
MUST be verify-then-pin LIVE at `/forge:design` (ADR-B812-002). The exact URL
pattern MUST NOT be fabricated in this spec. **RESOLVED (ADR-B812-002, live 2026-06-04): issuer `https://<ExternalDomain>`, jwks_uri `<issuer>/oauth/v2/keys` (confirmed live via Zitadel discovery + zitadel source `op.NewEndpoint("/oauth/v2/keys")`).**
Testable at implement: the Envoy-OIDC template references the verified Zitadel
OIDC discovery URL pattern from ADR-B812-002.

##### FR-B812-044 — identity.yaml v1.1.0 pin cross-reference present in Envoy-OIDC templates
The Envoy-OIDC template(s) MUST carry a reference to `identity.yaml@1.1.0` (the
authoritative Zitadel pin source: chart `10.0.2`, appVersion `v4.14.0`, ghcr.io
registry, v-prefix convention). This is the Forge standard that the template
cross-references for the IdP identity. Testable: `grep "identity.yaml" <envoy-oidc-template>` → exit 0 (or `grep "1.1.0"` in an audit comment within the template).

##### FR-B812-045 — 1.0.0 `infra/k8s/` Kong paths byte-UNCHANGED (additive only)
The existing 1.0.0 Kong manifests under
`.forge/templates/archetypes/full-stack-monorepo/infra/k8s/` (the server-only
flat-tree, frozen by B.8.2) MUST be byte-unchanged. B.8.12 adds Envoy-OIDC
templates to the NEW `2.0.0/` subtree; it MUST NOT modify the frozen 1.0.0 infra
templates. Testable: `git diff .forge/templates/archetypes/full-stack-monorepo/infra/` → empty.

---

#### Group 6 — Real p95/p99 methodology doc (FR-B812-050 → 052)

##### FR-B812-050 — Methodology doc present (home resolved by Q-005)
A methodology document MUST exist describing how to measure p50/p95/p99 latency
once a real backend image exists, anchored to the B.8.13 rollback thresholds
(p99 >20%, traceparent errors >1%). The home of this doc (extension to
`docs/MIGRATIONS.md` vs a new section vs a `docs/B8-BASELINE` follow-on) is
resolved by Q-005 → ADR-B812-001 at `/forge:design`. The doc MUST reference
`docs/B8-BASELINE.md §6` (the re-measurement methodology) and the B.8.13 rollback
criteria. Testable: `[ -f <methodology-doc-path> ]` → exit 0; `grep "p99" <doc>` → exit 0;
`grep "B.8.13" <doc>` → exit 0.

##### FR-B812-051 — NO committed p95/p99 latency number in the methodology doc
The methodology doc MUST NOT commit any numeric p95 or p99 latency figure. It
describes the measurement procedure and the rollback thresholds (relative
percentages), not a stored measurement. ADR-B8-1-002 and III.4 both bar committed
live numbers. Testable: `grep -E 'p9[59].*[0-9]+(ms|µs|s\b)' <doc>` → zero matches.
This is the same anti-faked-latency guard as FR-B812-006, applied to the methodology doc.

##### FR-B812-052 — Opt-in leg (`FORGE_B8_12_LIVE`) exercises methodology flow, skip-passes without toolchains
The L2 opt-in leg MUST include a test that exercises the methodology flow (e.g.,
checks the methodology doc is readable, the opt-in leg runs without error, the
re-capture step would drive the fake-OTLP collector). Without `FORGE_B8_12_LIVE`
or without real toolchains (docker, a real backend image), this leg MUST skip-pass
with `SKIP: FORGE_B8_12_LIVE not set` (0 failures). The skip is NOT a failure.
Testable: `bash b8-12.test.sh` (no env vars) → L2 methodology leg contributes 0 failures.

---

#### Group 7 — Harness + CI + CHANGELOG (FR-B812-060 → 068)

##### FR-B812-060 — Harness file created at `.forge/scripts/tests/b8-12.test.sh`
The brick MUST create `.forge/scripts/tests/b8-12.test.sh`. The file MUST be
present and executable. It MUST open with:
```
#!/usr/bin/env bash
# Forge — B.8.12 E2E migration test harness (b8-12-e2e-migration)
# <!-- Audit: B.8.12 (b8-12-e2e-migration) -->
```
Testable: `[ -f .forge/scripts/tests/b8-12.test.sh ] && [ -x .forge/scripts/tests/b8-12.test.sh ]` → exit 0;
`grep "Audit: B.8.12 (b8-12-e2e-migration)" .forge/scripts/tests/b8-12.test.sh` → exit 0.

##### FR-B812-061 — Harness structure: `--level` flag, `source _helpers.sh`, `run_test`/`print_summary`
`b8-12.test.sh` MUST implement the standard harness pattern (mirroring
`t5-otel-live-run.test.sh` and `b8-11.test.sh`): `--level` flag parsed at the top;
`source "$HARNESS_DIR/_helpers.sh"`; `PASS=0; FAIL=0; FAIL_NAMES=()` counters; each
test in a named function; `run_test <fn>` and `print_summary` in `main()`.
Testable: `grep "source.*_helpers.sh" .forge/scripts/tests/b8-12.test.sh` → exit 0;
`grep "print_summary"` → exit 0.

##### FR-B812-062 — L1 hermetic assertions (~14 tests, ≤ a few seconds wall-clock)
The L1 block MUST assert all of the following (each as a named test function):
1. 2.0.0 golden span inventory file present (FR-B812-001).
2. 3-span superset check: client + http.request + greeter.greet in 2.0.0 golden (FR-B812-002).
3. Phantom user.interaction span absent from both goldens (FR-B812-003).
4. Goldens sanitized: `"<ts:redacted>"` present, no IPv4 (FR-B812-004).
5. Migration dry-run exits 0 on 1.0.0 tmpdir copy (FR-B812-010).
6. Dry-run output contains additive-delta lines + preservation invariant (FR-B812-011).
7. Committed c1 example git-clean after L1 (FR-B812-012).
8. Exit-7 on wrong-version tmpdir (FR-B812-015).
9. demo-001..004 feature file Given/When/Then structure intact (FR-B812-023).
10. demo-004 status stays `specified` (FR-B812-022).
11. `transport_connect_client.rs.tmpl` present (FR-B812-030).
12. connectrpc =0.6.1 pin sentinel present in template or Cargo.toml.tmpl (FR-B812-031).
13. transport.yaml `versions_2_0_0` block + connectrpc pin (FR-B812-035).
14. Envoy-OIDC template(s) present in 2.0.0 subtree (FR-B812-040).
15. No committed p99 number in the b8-12 change tree (FR-B812-006 anti-faked-latency guard).
16. CHANGELOG.md contains `b8-12-e2e-migration` anchor (FR-B812-067).
17. forge-ci.yml contains `b8-12.test.sh` entry (FR-B812-066).
18. b8-1 + b8-10 coupling guard exit 0 (FR-B812-068).

All L1 tests MUST complete in ≤ a few seconds wall-clock (grep/stat/diff only;
no migration script invocation at L1 except the dry-run). Testable:
`bash .forge/scripts/tests/b8-12.test.sh --level 1` → exit 0 on CI.

##### FR-B812-063 — Fake-OTLP collector stdlib-only guard in harness
`b8-12.test.sh` MUST include a test verifying that any Python fake-OTLP collector
artifact used by B.8.12 imports only Python stdlib modules (no `protobuf`, `grpc`,
`requests`, `opentelemetry`, etc.), mirroring `_test_olr_002_collector_stdlib_only`
from t5-otel-live-run.test.sh. Testable: the harness test exits 0 (no forbidden
imports found in the collector script).

##### FR-B812-064 — L2 opt-in (FORGE_B8_12_LIVE): real migrate + golden re-capture + additive assertion
`b8-12.test.sh` MUST include an L2 block gated on `FORGE_B8_12_LIVE=1` that runs:
(a) real Phase-2 overlay on a tmpdir copy (FR-B812-013); (b) Kong/Temporal/REST
preserved assertion (FR-B812-014); (c) methodology leg skip-pass (FR-B812-052).
When `FORGE_B8_12_LIVE` is unset, ALL L2 tests MUST emit skip-pass (0 failures).
Testable: `bash b8-12.test.sh --level 2` without `FORGE_B8_12_LIVE` → all L2 contribute 0 failures.

##### FR-B812-065 — L2 opt-in (FORGE_E2E_TOOLCHAINS): cargo-check on rendered S2S client template
`b8-12.test.sh` MUST include an L2 block gated on `FORGE_E2E_TOOLCHAINS=1` (in
addition to `FORGE_B8_12_LIVE`) that renders `transport_connect_client.rs.tmpl`
into a minimal tmpdir Rust project and runs `cargo check` (FR-B812-034). When
`FORGE_E2E_TOOLCHAINS` is unset, this block MUST emit `SKIP: FORGE_E2E_TOOLCHAINS not set`
and contribute 0 failures. Testable: without toolchains → skip-pass.

##### FR-B812-066 — forge-ci.yml registration
`b8-12.test.sh` MUST be registered in `.github/workflows/forge-ci.yml` as a
one-line entry `"b8-12.test.sh --level 1"` placed after the `b8-11.test.sh` line
(or the last b8-N entry in sequence). Testable:
`grep "b8-12.test.sh" .github/workflows/forge-ci.yml` → exit 0.

##### FR-B812-067 — CHANGELOG entry anchored `b8-12-e2e-migration`
`CHANGELOG.md` `[Unreleased]` section MUST have an entry for this change. The
entry MUST contain the string `b8-12-e2e-migration` (whole-file grep, NOT bare
"B.8.12" — sibling false-pass prevention per changelog-test [Unreleased] coupling
memory lesson). Testable: `grep "b8-12-e2e-migration" CHANGELOG.md` → exit 0.

##### FR-B812-068 — Coupling guards: b8-1 and b8-10 exit-code assertions
`b8-12.test.sh` MUST include exit-code coupling guards:
- `.forge/scripts/tests/b8-1.test.sh --level 1` → must exit 0 (before-state baseline
  invariants GREEN; verifies 3-span inventory and anti-faked-latency guard still pass).
- `.forge/scripts/tests/b8-10.test.sh --level 1` → must exit 0 (migration script
  invariants GREEN; verifies `forge-migrate-flagship.sh` is still functioning).
A non-zero exit from either coupling guard is a b8-12 FAIL. Testable: coupling
guard test functions run as part of the L1 block and are counted in PASS/FAIL.

---

### Non-Functional Requirements

##### NFR-B812-001 — L1 harness wall-clock: ≤ a few seconds hermetic (no toolchain)
`b8-12.test.sh` L1 wall-clock MUST be achievable in ≤ a few seconds on the CI
runner (Python 3.11 + shellcheck only; no Docker, no network, no cargo). All L1
assertions are grep/stat/diff/dry-run operations. The dry-run invocation
(FR-B812-010..011) MUST be included in this budget (it is a bash script invocation,
not a cargo build).

##### NFR-B812-002 — Full ~51-harness suite GREEN pre-push
Before pushing, the full forge-ci harness suite (all ~51 harnesses in
`.forge/scripts/tests/`) MUST pass (`full_harness_suite_before_push` memory lesson).
This includes b8-1 (baseline), b8-10 (migration script), t5-otel-live-run (fake-OTLP
pattern), and any harness whose repo-wide scan touches the new 2.0.0 template subtree.
Subtrees versioned `N.N.N/` MUST be skipped by repo-wide scans (existing convention).

##### NFR-B812-003 — Frozen 1.0.0 templates + committed c1 example byte-identity
The following MUST remain byte-identical after B.8.12 is applied:
(a) all files under `.forge/templates/archetypes/full-stack-monorepo/` that are NOT
under a `2.0.0/` subdirectory (the frozen 1.0.0 flat-tree, B.8.2 freeze);
(b) `examples/forge-fsm-example/` (the committed c1 reference; migration runs in tmpdir only).
Testable: `git diff .forge/templates/archetypes/full-stack-monorepo/ -- ':!*.forge/templates/archetypes/full-stack-monorepo/2.0.0'` → empty; `git diff examples/forge-fsm-example/` → empty.

##### NFR-B812-004 — NO committed latency number (III.4 + ADR-B8-1-002)
No numeric p95/p99 latency value MUST be committed in any file owned by B.8.12.
The methodology doc (FR-B812-050) describes measurement procedure and relative
rollback thresholds (percentage deltas), never a frozen ms value. This NFR is
machine-verified by FR-B812-006 + FR-B812-051 + the harness anti-faked-latency
guard (test 15 in FR-B812-062).

##### NFR-B812-005 — Verify-then-pin LIVE for connectrpc client API + Envoy Gateway API + Zitadel issuer
At `/forge:design`, the implementer MUST verify LIVE (via crates.io, GitHub
Releases API, Envoy Gateway docs) and PIN in ADR-B812-002 and ADR-B812-003:
(a) the exact connectrpc 0.6.x client API symbols used in `transport_connect_client.rs.tmpl`;
(b) the Envoy Gateway SecurityPolicy `apiVersion`/`kind` and `JWTAuthn` filter shape;
(c) the Zitadel OIDC discovery URL pattern.
These were NOT fabricated at spec phase (b8-coroot lesson). **RESOLVED at implement (live 2026-06-04): (a) connectrpc::client {HttpClient, ClientConfig, CallOptions} + `client`/`client-tls` features (ClientConfig::new takes `http::Uri`, caught by L2 cargo-check); (b) Envoy SecurityPolicy gateway.envoyproxy.io/v1alpha1 spec.jwt.providers[]; (c) Zitadel discovery issuer + `<issuer>/oauth/v2/keys`.**

##### NFR-B812-006 — Goldens deterministic (timestamps redacted, no IPv4, byte-stable on re-run)
All committed golden files (span inventories, JSON captures) MUST be deterministic:
timestamps replaced with `"<ts:redacted>"`, no raw IPv4 addresses, byte-stable on
re-run with the same inputs. The fake-OTLP collector MUST redact timestamps before
comparing against the golden (t5-otel-live-run pattern). Testable: FR-B812-004.

##### NFR-B812-007 — Zero new external dep for the harness (Python stdlib fake collector)
The `b8-12.test.sh` harness and any associated fake-OTLP collector Python script
MUST introduce zero new external dependencies. The collector is Python stdlib only
(no pip install). Bash harness deps are git, python3, and shellcheck — all already
present in CI. Testable: FR-B812-063 (stdlib-only guard).

##### NFR-B812-008 — VIII.1 / VIII.2 preserved (additive-only invariant)
The migration driver overlay MUST preserve Kong and Temporal paths. No B.8.12
template, harness, or script MUST remove or render any Kong/Temporal/REST-bridge
path unreachable. Removal is B.8.14's scope. The b8-12 harness MUST NOT add any
`--force` flag call that could overwrite preserved paths without conflict detection.
Testable: NFR-B812-003 + FR-B812-014.

##### NFR-B812-009 — Independent review before `/forge:plan` and pre-archive
These specs MUST pass an independent reviewer (not the author) before `/forge:design`
proceeds (t5-2 self-validation lesson; b8-coroot inversion lessons). Independent
review is required again before `/forge:archive`. The verify-then-pin LIVE items
(NFR-B812-005) are resolved at design by the reviewer, not self-ruled.

##### NFR-B812-010 — Committed c1 example stays 1.0.0 throughout B.8.12 lifecycle
`examples/forge-fsm-example/.forge/scaffold-manifest.yaml` MUST retain
`archetype_version: 1.0.0` after B.8.12 is archived. The 2.0.0 migration runs in
a tmpdir only; the reference example is never promoted to 2.0.0 until B.8.14.
Testable: `grep "archetype_version: 1.0.0" examples/forge-fsm-example/.forge/scaffold-manifest.yaml` → exit 0 post-archive.

---

## Architecture Decision Records (seeds — finalized at `/forge:design`)

- **ADR-B812-001 — before/after mechanism + methodology doc home (Q-001 + Q-005).**
  Open. Lean: golden span-inventory superset (hermetic, binding L1 gate) + methodology
  doc (home = extension of `docs/MIGRATIONS.md §B.8.12` or `docs/B8-BASELINE` follow-on,
  resolved at design). No committed latency numbers.
- **ADR-B812-002 — Envoy-OIDC scope + API verify-then-pin (Q-002).** Open. Lean: land
  gateway-side SecurityPolicy + JWTAuthn templates (verify-then-pin Envoy Gateway API
  LIVE at design) + backend JWT validation middleware template; if the Envoy Gateway
  SecurityPolicy API cannot be cleanly pinned live, defer gateway half to a follow-on
  and land middleware only (no fabrication — ADR-B87-006).
- **ADR-B812-003 — S2S client surface + auth/TLS/deadline/retry posture (Q-003).**
  Open. Lean: minimal client on connectrpc 0.6.x with documented auth/TLS/deadline/retry
  posture; cargo-check gated behind L2 opt-in; exact API symbols verify-then-pin LIVE.
- **ADR-B812-004 — migration target mechanics (Q-004).** Open. Lean: tmpdir copy of
  `examples/forge-fsm-example/` + `forge-migrate-flagship.sh --target`; committed c1
  stays 1.0.0; real overlay L2 opt-in; dry-run plan assertion L1.

---

## BDD Acceptance Criteria

```gherkin
Feature: B.8.12 E2E migration convergence gate
  As a Forge framework CI gate
  I want proof that migrating the c1 reference project to 2.0.0 produces zero
  behavioral regression across demo-001..004, with the 1.0.0 span inventory
  preserved as a strict subset of the 2.0.0 span set, and no committed latency number
  So that the B.8 migration is demonstrably safe and the before/after gate is honest

  Scenario: Golden span-tree superset — 1.0.0 span set preserved in 2.0.0
    Given the 1.0.0 baseline at .forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml
      with 3 code-verified spans (client POST, http.request server, greeter.greet internal)
    And the 2.0.0 after-state golden at .forge/changes/b8-12-e2e-migration/captures/
    When the harness runs the golden superset diff (diff -q, timestamps redacted)
    Then all 3 code-verified 1.0.0 spans are present in the 2.0.0 golden
    And no user.interaction phantom span appears in either golden
    And the diff completes hermetically without Docker, cargo, or flutter
    And the harness exits 0

  Scenario: Additive overlay preserves Kong, Temporal, and REST (VIII.1/VIII.2)
    Given a tmpdir copy of examples/forge-fsm-example/ at archetype_version 1.0.0
    When the L2 opt-in applies the real Phase-2 overlay via forge-migrate-flagship.sh --target
    Then Envoy Gateway templates are present (additive)
    And Kong manifests are preserved (not removed)
    And Temporal scaffolding paths are preserved (not removed)
    And REST-bridge paths are preserved (not removed)
    And the overlay exit code is 0

  Scenario: Forbidden committed latency number triggers harness FAIL (anti-faked-latency guard)
    Given a file under .forge/changes/b8-12-e2e-migration/ containing a pattern "p99: 42ms"
    When the harness L1 anti-faked-latency guard runs
    Then the guard emits a FAIL
    And the harness exits non-zero
    And the committed numeric p99 value is reported in the failure message
```

---

## Anti-Hallucination Pass (Article III.4)

- **NO fabricated connectrpc client API symbols.** The exact connectrpc 0.6.x client
  API (`ClientConfig`, `CallOptions`, or their 0.6.x equivalents) is NOT stated in
  this spec. **RESOLVED (ADR-B812-003, live 2026-06-04): `connectrpc::client::{HttpClient, ClientConfig, CallOptions}`; `ClientConfig::new(uri: http::Uri)` (NOT `&str` — caught by L2 cargo-check); `client`/`client-tls` Cargo features.**
- **NO fabricated Envoy Gateway SecurityPolicy apiVersion/kind.** The exact Envoy
  Gateway SecurityPolicy API version string (e.g., `gateway.envoy.io/v1alpha1`) and
  the `JWTAuthn` filter configuration shape are NOT stated in this spec. **RESOLVED (ADR-B812-002, live 2026-06-04): Envoy Gateway v1.8.0 folds JWT into `SecurityPolicy.spec.jwt.providers[].remoteJWKS.backendRefs`→Backend — no separate JWTAuthn resource.**
- **NO fabricated Zitadel OIDC discovery URL.** The exact Zitadel OIDC discovery URL
  pattern (e.g., `https://<host>/.well-known/openid-configuration`) is NOT fabricated
  here. **RESOLVED (ADR-B812-002, live 2026-06-04): issuer `https://<ExternalDomain>`; jwks_uri `<issuer>/oauth/v2/keys` (confirmed via live Zitadel discovery).**
- **NO committed p95/p99 number anywhere.** The whole point of the proposal re-scoping
  is that the c1 `fsm-backend` is `image: scratch` (B8-BASELINE §3, FR-B8-1-012).
  ADR-B8-1-002 ratified that no live latency numbers are committed. FR-B812-006,
  FR-B812-051, and the harness anti-faked-latency guard (test 15 in FR-B812-062)
  encode this as machine-verifiable constraints. Any spec text with a numeric ms figure
  is a violation.
- **3-span baseline is a HARD FACT.** `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml`
  was re-read 2026-06-04. It records exactly 3 spans. The 4th (Flutter
  `user.interaction greet` root) is documented as a phantom — no `startSpan` in
  `frontend/lib`. FR-B812-002, FR-B812-003, and BDD Scenario 1 encode this as testable assertions.
- **"Additive overlay never removes Kong/Temporal/REST" is a HARD FACT.** The
  `forge-migrate-flagship.sh` script (observed 2026-06-04) carries the comment
  "ADDITIVE-ONLY: never removes Kong, Temporal, or REST-bridge paths (VIII.1/VIII.2 SHALL
  clauses binding until B.8.14). FR-B810-031." and the Phase 2 walk does not delete
  existing paths. FR-B812-014 and NFR-B812-008 encode this as testable invariants.
- **"Committed c1 example stays 1.0.0" is a HARD FACT.** 2.0.0 is `scaffoldable: false`
  until B.8.14. The migration runs in a tmpdir. FR-B812-012 and NFR-B812-010 encode
  this as testable assertions (git-clean + manifest version grep).
- **transport.yaml `versions_2_0_0` pins are OBSERVED FACTS.** Re-read from
  `.forge/standards/transport.yaml` v1.3.0 (2026-06-04): `connectrpc: "=0.6.1"`,
  `buffa: "=0.6.0"`. FR-B812-035 uses these as testable sentinels. The implementer
  MUST re-verify at `/forge:implement` (b8-coroot lesson / ADR-B86-001 final-re-verify).
- **identity.yaml v1.1.0 pins are OBSERVED FACTS.** Re-read from
  `.forge/standards/identity.yaml` (2026-06-04): `zitadel_chart: "10.0.2"`,
  `zitadel: "v4.14.0"`, ghcr.io registry. FR-B812-044 uses these as testable sentinels.
- **"4 demos = demo-001..004" is an OBSERVED FACT.** The proposal and .forge.yaml both
  state this. Demo-005 is the T.5 Connect demo (separate). Demo-004 stays `specified`.
  FR-B812-022 encodes the demo-004 status as testable.
- **Qwik→OTel is OUT OF SCOPE.** The proposal §1 GROUND-TRUTH states it explicitly:
  "Qwik→OTel deferral is NOT B.8.12's in any binding form … Out of scope here; routes
  to B.7 (ai-native-rag OTel)." No FR in this spec references Qwik→OTel wiring.
- **Independent review required (NFR-B812-009).** These specs MUST pass an independent
  reviewer before `/forge:design`. Not self-approved here.

## Open Questions

Tracked in `open-questions.md`: Q-001 (before/after mechanism + methodology doc home →
ADR-B812-001, open, lean golden superset + MIGRATIONS.md extension), Q-002 (Envoy-OIDC
scope → ADR-B812-002, open, lean full land gateway + middleware unless API unpinnable),
Q-003 (S2S client surface + auth/TLS/deadline/retry → ADR-B812-003, open, lean minimal
client + L2 cargo-check), Q-004 (migration target mechanics → ADR-B812-004, open, lean
tmpdir + `--target` + L2 real overlay), Q-005 (methodology doc home → ADR-B812-001,
open, lean MIGRATIONS.md extension).

---

## Spec Delta (design-phase, ADR-B812-004 — 2026-06-04)

Design-phase live evidence (P-19/P-20) falsified the demo `.feature` /
`.forge.yaml` paths assumed in Group 3. The live layout: demo-001/002/003 each
ship a feature file at `examples/forge-fsm-example/.forge/changes/demo-00N-*/features/*.feature`
(NOT `test/features/` — that dir holds only the demo-005/traceparent features);
**demo-004 has NO feature file** (`status: specified`, spec-frozen). The four
FRs are corrected below per the b8-7 `## Spec Delta` precedent. The design test
table (T-009/T-010) already uses these corrected paths.

##### FR-B812-020 — MODIFIED
- **Previously**: "The four demo `.feature` files under
  `examples/forge-fsm-example/test/features/` (or `docs/`) corresponding to
  demo-001, demo-002, demo-003, and demo-004 MUST be byte-unchanged …"
- **Now**: The **three** demo `.feature` files at
  `examples/forge-fsm-example/.forge/changes/demo-00{1,2,3}-*/features/*.feature`
  (greeter.feature, greeting_screen.feature, rate_limit.feature) MUST be
  byte-unchanged after the L2 additive overlay. **demo-004 has no `.feature`
  file** (it is spec-frozen at `status: specified`) — it is excluded from this
  assertion. The overlay never rewrites demo feature files (not in the 2.0.0
  RIGHT set). Testable: `git diff --quiet examples/forge-fsm-example/.forge/changes/demo-00{1,2,3}-*/features/` → exit 0 after L2.

##### FR-B812-022 — MODIFIED
- **Previously**: "`grep "status: specified" .forge/changes/demo-004*/.forge.yaml` → exit 0 (or equivalent path)."
- **Now**: the demo-004 entry at
  `examples/forge-fsm-example/.forge/changes/demo-004-user-onboarding/.forge.yaml`
  MUST retain `status: specified` after the overlay (the overlay is additive,
  targets the example tree's runtime files, and MUST NOT touch `.forge/changes/`
  metadata). Testable: `grep "status: specified" examples/forge-fsm-example/.forge/changes/demo-004-user-onboarding/.forge.yaml` → exit 0.

##### FR-B812-023 — MODIFIED (count correction)
- **Previously**: "for each of the **4** demo `.feature` files … the harness
  awk-based Given/When/Then check exits 0 for all **4** demo feature files."
- **Now**: for each of the **3** demo `.feature` files (demo-001/002/003) the
  harness MUST confirm `Feature:` + ≥1 `Scenario:` + Given/When/Then structure
  intact (mirroring `_test_olr_010_feature_file_exists`). demo-004 (no feature
  file) is excluded. The check exits 0 for all **3** demo feature files.

All other FRs remain in force unchanged. FR-B812-021 (proto contracts under
`examples/forge-fsm-example/shared/protos/`) was already correct.
