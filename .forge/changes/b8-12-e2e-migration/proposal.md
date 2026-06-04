# Proposal: b8-12-e2e-migration

<!-- Created: 2026-06-04 -->
<!-- Schema: default -->
<!-- Audit: B.8.12 (docs/new-archetypes-plan.md §4.2 lines 2335-2336 — E2E migration tests; the zero-regression convergence gate for the B.8 flagship migration) -->

## Problem

The B.8 migration has shipped all five 2.0.0 template bricks (B.8.4-9), the
migration orchestrator (B.8.10), and the NSMA activation (B.8.11). What is
missing is the **convergence gate**: proof that migrating the `c1`
reference project (`examples/forge-fsm-example/`) to 2.0.0 produces **zero
behavioral regression** across the demos, plus the before/after capture
that feeds B.8.13's rollback criteria. Two deferrals also name B.8.12 as
their landing point: the **Rust S2S Connect client** (ADR-B86-004) and the
**Envoy-OIDC wiring** (ADR-B87-006).

### GROUND-TRUTH FINDINGS (Article III.4)

**Ground truth (re-read 2026-06-04):**

- **"p95/p99 before/after" is NOT capturable as live latency.** The c1
  `fsm-backend` is `image: scratch` (placeholder, B8-BASELINE §3 /
  FR-B8-1-012). ADR-B8-1-002 ratified that the latency baseline is
  "methodology + optional sample, NEVER committed live numbers"; faking a
  p99 violates III.4. **The real, hermetic before/after gate is a
  span-inventory / golden-span-tree regression** — the before-state
  already exists at `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml`
  (3 code-verified spans on demo-005: client → server → `greeter.greet`).
  Real p95/p99 is delivered as a **methodology doc + an opt-in
  `FORGE_B8_12_LIVE` leg that skip-passes by default** (needs a real
  backend image + load tool, absent in CI). This re-scopes the plan's
  "captures p95/p99" wording to its honest, ratified form.
- **The 3-span / 4-span correction stands.** B.8.1 found the demo-005 doc
  draws a 4-span tree but only **3** are real instrument sites (the 4th, a
  Flutter `user.interaction` root, is phantom — no `startSpan` in
  `frontend/lib`). B.8.12's after-capture asserts the **3 code-verified
  spans**, not the phantom.
- **"Migrate c1 to 2.0.0" = invoke B.8.10 against a COPY, not scaffold a
  new example.** 2.0.0 is `scaffoldable: false`. B.8.12 runs
  `bin/forge-migrate-flagship.sh --target <copy-of-c1>` (dry-run hermetic +
  opt-in real Phase-2 overlay), asserting the additive overlay (Envoy ∥
  Kong — Kong stays, Connect, Zitadel, Qwik, pg17) and the span superset.
  The committed `examples/forge-fsm-example/` stays at 1.0.0 (frozen
  reference); the migration runs in a tmpdir.
- **B.8.12 lands the Rust S2S Connect client** (ADR-B86-004, chain
  ADR-T5-003 → ADR-B86-004 → B.8.12 "target landing"). The 2.0.0
  `transport_connect.rs.tmpl` is **server-only** today (`into_router` +
  `ConnectRouter`, no `ClientConfig`/`CallOptions`). B.8.12 adds
  `transport_connect_client.rs.tmpl` on the connectrpc 0.6.x client
  primitives — auth, TLS, deadline propagation, retry policy. Crate API
  verify-then-pin LIVE at design/implement (b8-coroot lesson).
- **B.8.12 owns the Envoy-OIDC wiring** (ADR-B87-006 split B.8.10/B.8.12;
  B.8.10 shipped doc-only canary). The deferred artifacts: the Envoy
  **SecurityPolicy**, the **JWTAuthn filter** (AT C4 `Rel(envoy, zitadel,
  "OIDC")`), and the **backend JWT validation middleware**. ADR-B87-006
  explicitly barred fabricating Envoy Gateway API versions + Zitadel issuer
  URL patterns — so these are verify-then-pin LIVE at design (Envoy Gateway
  SecurityPolicy API + Zitadel OIDC discovery). Scope is a Q (land all
  three vs land the gateway-side + defer middleware) — Q-002.
- **CI toolchain reality**: Python 3.11 + Node + shellcheck only — NO
  cargo, flutter, or docker; every harness runs `--level 1`. So B.8.12 is
  hermetic L1 + opt-in L2 (`FORGE_B8_12_LIVE` / `FORGE_E2E_TOOLCHAINS`),
  reusing the t5-otel-live-run **fake-OTLP-collector (Python stdlib) +
  sanitized golden-capture (`diff -q` vs committed golden)** pattern.
- **The "4 demos" = demo-001..004** (demo-005 is the later T.5 Connect
  demo, separate). demo-004 stays `specified` (the Article III.4
  anti-hallucination demo, frozen at spec). "0 regression" = the demos'
  contracts + `.feature` files + BDD survive the 2.0.0 overlay unchanged.
- **Qwik→OTel deferral is NOT B.8.12's** in any binding form — it appears
  only as a b8-9 sequence-diagram annotation ("Rel(qwik,otel) → B.8.12/B.7"),
  no ADR/FR/harness. Out of scope here; routes to B.7 (ai-native-rag OTel).
- **Kong-pin drift**: B8-BASELINE §1 corrected `kong:3.6-alpine` →
  `kong:3.6` (the `-alpine` tag was pulled); b8-1 specs.md prose is stale.
  B.8.12's after-capture trusts the shipped artifacts (`kong:3.6`), and in
  2.0.0 Kong is joined by Envoy (additive) per §7.

## Solution

When built, the B.8.12 brick MUST:

1. Ship the **golden-span-tree regression gate**: capture the 2.0.0
   after-state span inventory from a migrated copy of c1 and assert it is a
   **superset of** `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml`
   (the 3 code-verified spans preserved; new 2.0.0 spans additive). Reuse
   the t5-otel-live-run hermetic fake-OTLP-collector + sanitized golden
   pattern (no real infra). Committed before/after goldens, deterministic
   (timestamps redacted).
2. Ship the **migration E2E driver**: invoke `bin/forge-migrate-flagship.sh`
   against a tmpdir copy of `examples/forge-fsm-example/` — Phase 0 preflight
   (1.0.0 manifest), `--dry-run` plan assertion (hermetic L1), and an opt-in
   real Phase-2 overlay (L2, `FORGE_B8_12_LIVE`) asserting the additive
   result: Envoy templates present + Kong preserved + Connect + Zitadel +
   Qwik + pg17, no Kong/Temporal/REST removal.
3. Assert **0 regression on the 4 demos** (demo-001..004): their
   `.feature` files, proto contracts, and spec FRs survive the overlay
   byte-intact (the overlay is additive — it adds 2.0.0 surfaces, never
   rewrites the demos); demo-004 stays `specified`.
4. Land the **Rust S2S Connect client** `transport_connect_client.rs.tmpl`
   (2.0.0 backend template) on connectrpc 0.6.x client primitives — auth /
   TLS / deadline / retry posture decided at design (Q-003); crate API
   verify-then-pin LIVE.
5. Land the **Envoy-OIDC wiring** (scope per Q-002): SecurityPolicy +
   JWTAuthn filter templates (2.0.0 `infra/k8s/envoy-gateway/`, verify-then-pin
   Envoy Gateway API + Zitadel OIDC discovery) + backend JWT validation
   middleware template; cross-ref identity.yaml v1.1.0 (Zitadel issuer).
6. Ship the **real-p95/p99 methodology doc** (extend `docs/MIGRATIONS.md`
   or a B8-BASELINE follow-on): how to measure p50/p95/p99 once a real
   backend image exists, anchored to the B.8.13 rollback thresholds
   (p99 >20%, traceparent errors >1%); the opt-in `FORGE_B8_12_LIVE` leg
   exercises it, skip-passing without toolchains.
7. Ship harness `.forge/scripts/tests/b8-12.test.sh` (~14 L1 hermetic +
   L2 opt-in): golden span superset diff, migration dry-run exit 0,
   additive-overlay assertion, 4-demo contract-survival, S2S client
   template present + pin sentinels, Envoy-OIDC template present, no-faked-
   latency guard (no committed p99 number), CHANGELOG anchor, forge-ci
   registration, b8-1/b8-10 coupling guard; **L2** (`FORGE_B8_12_LIVE`):
   real migrate + cargo-check the rendered S2S client + golden re-capture.
8. Register `b8-12.test.sh` in `forge-ci.yml`; CHANGELOG `[Unreleased]`.
9. Run the full ~51-harness suite + gates before push; gates re-run
   POST-flip; independent review at design and pre-archive.

Decisions reserved for `/forge:design` (ADRs), leanings stated:

- **ADR-B812-001 (Q-001) — before/after mechanism.** **Lean:** golden
  span-inventory superset (hermetic, the ratified honest form) as the
  binding L1 gate; real p95/p99 = methodology doc + opt-in skip-pass leg.
  No committed latency numbers (ADR-B8-1-002 + III.4).
- **ADR-B812-002 (Q-002) — Envoy-OIDC scope.** **Lean:** land the
  gateway-side SecurityPolicy + JWTAuthn templates (verify-then-pin Envoy
  Gateway API LIVE) + the backend JWT validation middleware template; if
  the Envoy SecurityPolicy API cannot be cleanly pinned live, defer the
  gateway half to a B.8.12-follow-on and land only the middleware
  (no fabrication — ADR-B87-006).
- **ADR-B812-003 (Q-003) — S2S client surface.** **Lean:** minimal
  `createClient`-equivalent on connectrpc 0.6.x with a documented
  auth/TLS/deadline/retry posture; cargo-check gated behind L2 opt-in.
- **ADR-B812-004 (Q-004) — migration target mechanics.** **Lean:** tmpdir
  copy of `examples/forge-fsm-example/` + `forge-migrate-flagship.sh
  --target`; committed c1 stays 1.0.0 (frozen reference). Real overlay L2
  opt-in; dry-run plan assertion L1.

Release vehicle: **v0.4.0-rc.14**.

## Scope In

- Golden-span-tree before/after regression gate (hermetic) + committed
  goldens.
- Migration E2E driver invoking `forge-migrate-flagship.sh` against a c1
  copy (dry-run L1 + opt-in real L2).
- 0-regression assertion over demo-001..004 contracts/`.feature`/specs.
- Rust S2S Connect client template (`transport_connect_client.rs.tmpl`).
- Envoy-OIDC wiring templates (SecurityPolicy + JWTAuthn + backend JWT
  middleware — scope per Q-002, verify-then-pin).
- Real-p95/p99 methodology doc + opt-in `FORGE_B8_12_LIVE` leg.
- Harness `b8-12.test.sh` + forge-ci.yml + CHANGELOG.

## Scope Out (Explicit Exclusions)

- **Committed live p95/p99 numbers** — barred (ADR-B8-1-002 + III.4);
  methodology + opt-in leg only.
- **Scaffolding a new committed 2.0.0 example** — 2.0.0 is
  scaffoldable:false until B.8.14; migration runs in a tmpdir.
- **Removing Kong/Temporal/REST** — additive-only; removal is B.8.14.
- **Qwik→OTel wiring** — B.7 (no binding deferral to B.8.12).
- **OIDC/PKCE Qwik client** — B.9.3.
- **The rollback runbook itself** — B.8.13 (B.8.12 supplies the
  capture/methodology it consumes).
- **Schema 2.0.0 promotion + VIII.1/VIII.2 amendment** — B.8.14.
- **`forge upgrade` matrix test** — B.8.15.
- **Any mutation of the committed c1 example, 1.0.0 templates, schema, or
  the frozen snapshot** — all read-only inputs.

## Impact

- **Users affected**: none until B.8.14 — the regression gate is internal
  framework validation; the c1 example stays 1.0.0.
- **Technical impact**: 1 new harness + goldens, 2 new 2.0.0 templates
  (S2S client, Envoy-OIDC), 1 methodology doc, migration-driver glue. No
  committed example mutation; real toolchain work behind opt-in.
- **Dependencies**: B.8.1 (baseline), B.8.10 (migration script), B.8.6
  (S2S client deferral + transport pins), B.8.7 (Envoy-OIDC deferral +
  Zitadel), C.1 (the c1 example), T.5 (golden-capture pattern).

## Constitution Compliance

- **Article I (TDD)**: harness RED-first; the new templates get their
  assertions before they exist.
- **Article II (BDD)**: the golden-capture flow ships a `.feature`
  (Given a migrated c1 / When spans are captured / Then the 1.0.0 span set
  is a subset) — Given/When/Then before implementation.
- **Article III.4 (Anti-Hallucination) — CENTRAL**: the "p95/p99" plan
  wording is re-scoped to the ratified honest form (no faked latency); the
  3-span correction is preserved; Envoy/Zitadel/connectrpc APIs are
  verify-then-pin LIVE, never fabricated (ADR-B87-006 + b8-coroot lesson).
- **Article IV (Delta-based)**: ADDED FRs; new templates + goldens; no
  spec rewrite.
- **Article V (Compliance gate)**: harness + gates before flip; full suite
  before push; POST-flip re-run.
- **Article VIII.1 (Kong SHALL) / VIII.2 (Temporal SHALL) — PRESERVED**:
  the migration driver is additive (Kong + Temporal stay); removal is
  B.8.14.
- **Article XII (Governance)**: no governance change.

## Open Questions (seed)

- **Q-001** — before/after mechanism: golden span-superset (hermetic,
  binding) + opt-in real p95/p99 vs attempting any committed latency number
  (→ ADR-B812-001; open, lean golden + opt-in; no committed numbers).
- **Q-002** — Envoy-OIDC scope: land SecurityPolicy + JWTAuthn + backend
  middleware all here, vs land middleware + defer the gateway half if the
  Envoy Gateway SecurityPolicy API can't be cleanly verify-then-pinned
  (→ ADR-B812-002; open).
- **Q-003** — S2S client surface + auth/TLS/deadline/retry posture; cargo-
  check L1 (no — toolchain absent) vs L2 opt-in (→ ADR-B812-003; open, lean
  L2).
- **Q-004** — migration target: tmpdir copy + `--target` vs another
  mechanism; real overlay L1 (no) vs L2 opt-in (→ ADR-B812-004; open, lean
  tmpdir + L2 real, L1 dry-run).
- **Q-005** — methodology-doc home: extend `docs/MIGRATIONS.md` vs a new
  `docs/B8-BASELINE` follow-on section (→ ADR-B812-001; open).
