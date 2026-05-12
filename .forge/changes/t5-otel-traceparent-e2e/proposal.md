# Proposal: t5-otel-traceparent-e2e
<!-- Created: 2026-05-11 -->
<!-- Schema: full-stack-monorepo -->
<!-- Audit: T.5 / Phase C — W3C traceparent end-to-end validation -->

## Problem

Phase A (`t5-otel-stack`, archived 2026-05-10) shipped the **infra side** of
the OTel + OBI + Coroot stack on the `full-stack-monorepo` archetype
(collector, sampler, SigNoz, Coroot, Beyla DaemonSet). Phase B
(`t5-otel-app`, archived 2026-05-10) shipped the **app side** : Rust SDK
init + axum/connectrpc/tonic middleware composition + Flutter SDK init +
Connect/Dio `TracingInterceptor` + demo-005 traceparent round-trip.

What is **still missing** to close T.5's Article IX promise at the
archetype level is **mechanical evidence** that a W3C `traceparent`
header survives every hop of the demo-005 round trip — most notably the
**Kong gateway hop** sitting between the Flutter client and the
backend pod.

Concrete gaps after Phase B :

1. **No BDD `.feature` file** asserts the gateway-traversing scenario.
   `examples/forge-fsm-example/test/features/demo_005_traceparent.feature`
   exists (shipped by Phase B per FR-T5-OTA-031) but it covers the
   **direct path** only (Flutter → axum → connectrpc handler → use case,
   4 spans). It does NOT cover the gateway-traversing path
   (Flutter → Kong → axum → handler → use case, 5 spans).
2. **`infra/kong/kong.yml.example` has no `traceparent` policy
   declaration.** It happens to preserve `traceparent` by default
   (Kong only strips headers when an explicit
   `request_transformer.remove.headers` plugin asks for it ; the
   current file has no such plugin), but the **absence of a
   header-strip rule is implicit** — adopters reading the file have no
   anchor confirming the gateway is OTel-clean. A defensive grep
   gate in this change asserts the absence remains absent.
3. **Sampled-off (`flags=00`) behaviour is not documented or tested.**
   `observability.yaml::sampler: parentbased_traceidratio` says a
   span inheriting `flags=00` MUST NOT export. Phase B's collector +
   SDK can do this correctly, but neither layer has a written
   acceptance scenario.
4. **`_test_t5_l2_traceparent_dual` is still deferred**
   (`.forge/changes/t5-connect-codegen/tasks.md` § "DEFERRED 2026-05-06"
   uplift). It was waiting on Phase B (now shipped) + Phase C
   (this change). Closing Phase C produces the deferred test
   artefact even if the live-run leg ships at Phase D.
5. **Article IX evidence loop is open.** Without a documented
   end-to-end scenario, future Aegis audits cannot point at a
   structural BDD artefact for "the gateway preserves trace context".

`docs/new-archetypes-plan.md` lines 994–1000 enumerated three phases for
T.5 ; this change closes the third :

> Phase A (`t5-otel-stack`) ✅ archived 2026-05-10
> Phase B (`t5-otel-app`)   ✅ archived 2026-05-10
> Phase C (E2E traceparent) ← this change

## Solution

Phase C is a **harness + spec** change, not a live-run change. The
actual stack-run validation (start `docker compose`, hit the Flutter
app, capture spans from SigNoz, assert traceId consistency) is
**Phase D** — explicitly deferred and documented in `tasks.md`.

Strict scope :

1. **New BDD feature file**
   `examples/forge-fsm-example/test/features/traceparent_e2e.feature`
   (full Gherkin, NOT the Phase B stub
   `demo_005_traceparent.feature` which it complements). Three
   scenarios :
   - **Direct path** — Flutter → axum → connectrpc handler → use case
     (4 spans, 1 traceId). Symmetric with the Phase B stub but
     written as an executable BDD step list.
   - **Kong path** — Flutter → Kong gateway → axum → handler → use
     case (5 spans, traceparent preserved through Kong).
   - **Sampled-off path** — incoming `traceparent: 00-{tid}-{sid}-00`
     (sampled bit = 0) — spans MUST be recorded but MUST NOT export
     per `observability.yaml`'s sampler contract.
2. **Kong gateway assertion** — patch
   `examples/forge-fsm-example/infra/kong/kong.yml.example` IF NEEDED
   to declare W3C `traceparent` preservation. Verification of the
   file's current state precedes any patch ; if the file already
   declares no header-strip (which it does as of 2026-05-11), the
   patch is purely additive (a comment block making the contract
   explicit + a defensive grep test).
3. **L1 grep harness**
   `.forge/scripts/tests/t5-otel-traceparent-e2e.test.sh` with at
   minimum :
   - BDD feature file shape (3 scenarios, Gherkin Given/When/Then).
   - `infra/kong/kong.yml.example` does NOT strip `traceparent`
     (assert no `request_transformer.remove.headers` entry mentions
     `traceparent` ; assert no `headers.traceparent: false` directive).
   - Phase B's `HeaderMapExtractor` + `MetadataMapCarrier` referenced
     from the new BDD step descriptions (forward-pointer reachable).
   - Forge-CI matrix entry for the new harness.
4. **L2 inheritance** — compile-only inheritance from Phase B :
   - `cargo build -p bin-server` PASS (inherited green).
   - `flutter analyze` — **STILL xfail (Q-004 unresolved in this
     branch's tree)**. The `t5-otel-dart-api-realign` change
     addresses Q-004 separately. Documented in the harness comment
     so future readers understand the cascade.
5. **Spec artefacts** under `.forge/changes/t5-otel-traceparent-e2e/` :
   `.forge.yaml` (`schema: full-stack-monorepo`,
   `layers: [backend, frontend, infra]`,
   `depends_on: [t5-otel-stack, t5-otel-app, t5-connect-codegen]`,
   `parent_audit_items: [T.5 / Phase C]`), this `proposal.md`,
   `specs.md` (`FR-T5-TPE-NNN` / `NFR-T5-TPE-NNN`), `design.md`,
   `tasks.md`, `open-questions.md`.
6. **`CHANGELOG.md` `[Unreleased]` entry.**

## Scope In

- BDD feature `examples/forge-fsm-example/test/features/traceparent_e2e.feature`
  with 3 scenarios (direct / Kong / sampled-off).
- Additive comment-only patch to
  `examples/forge-fsm-example/infra/kong/kong.yml.example` declaring
  the W3C traceparent preservation contract.
- New harness `.forge/scripts/tests/t5-otel-traceparent-e2e.test.sh`
  (L1 grep, L2 inheritance from Phase B).
- CI registration in `.github/workflows/forge-ci.yml` `harness` job.
- New change tree under `.forge/changes/t5-otel-traceparent-e2e/`.
- `CHANGELOG.md` `[Unreleased]` entry.

## Scope Out (Explicit Exclusions)

- **NOT** Envoy gateway validation. Envoy is part of the T6 / B.8
  flagship migration per `docs/ARCHITECTURE-TARGET.md` ADR-001 ; the
  example tree does not yet ship an Envoy config. **Forward-pointer**
  to the future `b8-envoy-migration` change (or whichever name the
  T6 migration takes) is documented in this change's `design.md`
  § Out of scope. The Envoy traceparent assertion is explicitly
  deferred to that change.
- **NOT** Phase D — actual stack run + live span capture against a
  stub OTLP receiver. Phase D will start `docker compose up`,
  trigger the Flutter UI, capture spans from SigNoz / the collector's
  `debug` exporter, and assert traceId consistency programmatically.
  Phase C ships the spec + the gateway assertion + the BDD scaffold ;
  Phase D wires the live-run leg. Documented in `tasks.md`.
- **NOT** modifying Phase B example impl
  (`backend/bin-server/`, `frontend/lib/core/telemetry/`). Phase B
  is already shipped — only additive structural edits (e.g. a
  forward-pointer comment) are accepted.
- **NOT** modifying `flutter/opentelemetry.md` standard. The Q-004
  Dart-API-realign is owned by the separate
  `t5-otel-dart-api-realign` change. This change inherits the
  Q-004 xfail and documents it in the harness comment.
- **NOT** modifying the archetype template
  (`templates/full-stack-monorepo/`). Phase A territory ; not
  affected.
- **NOT** modifying `observability.yaml` standard. Phase A bumped
  it to v1.1.0 ; this change consumes the sampler contract without
  amending it. No REVIEW.md ledger entry required (additive
  realisation per `.forge/standards/global/standards-yaml.md`
  lifecycle rules).
- **NOT** Aegis automation, **NOT** SBOM regeneration, **NOT** new
  observability backend.

## Crucial nuance — Phase C is harness + spec, NOT live-run

This change ships :
- The BDD feature file (Gherkin text, no live step bindings yet).
- The Kong gateway preservation assertion (grep against the
  declarative config file).
- The L1 harness wiring this evidence into Forge-CI.

This change explicitly does NOT ship :
- A `docker compose up` invocation.
- A `flutter run` / `flutter test` E2E driver.
- A SigNoz API call to verify the captured trace tree.
- Programmatic traceId consistency assertions across hops.

All four are Phase D scope. The split is documented in `tasks.md`'s
"Phase D — DEFERRED" section so future implementers don't miss it.

## Impact

- **Users affected** : `examples/forge-fsm-example/` reference
  consumers. After this change, the example tree carries a
  documented BDD acceptance for the gateway-traversing trace
  scenario ; the Kong config file gains an explicit comment
  declaring the traceparent contract. No archetype template change ;
  no `forge init` adopter sees any new surface.
- **Technical impact** : ~1 new `.feature` file (≈ 80 lines of
  Gherkin) + ~1 modified `kong.yml.example` (≈ 5 lines of
  comment) + ~1 new harness (≈ 200 lines of bash, mostly
  grep-based) + 1 CI matrix line + 1 new change tree under
  `.forge/changes/`. **Effort `S`** (smaller than Phase B because no
  app-side code).
- **Dependencies** :
  - `t5-otel-stack` ✅ archived 2026-05-10 (provides the sampler
    contract).
  - `t5-otel-app` ✅ archived 2026-05-10 (provides the
    `HeaderMapExtractor` + `MetadataMapCarrier` symbol references the
    BDD steps quote).
  - `t5-connect-codegen` ✅ archived 2026-05-06 (provides demo-005
    + the deferred `_test_t5_l2_traceparent_dual` this change
    uplifts).
  - `observability.yaml` v1.1.0 ✅ shipped — consumed, not amended.
- **Risk level** : **Low**. Low because no production code is
  shipped ; the only mutable artefacts are a `.feature` file
  (Gherkin), a comment in `kong.yml.example`, and a bash harness.
  The L2 `flutter analyze` xfail inheritance is the single residual
  risk surface — documented inline.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`t5-otel-traceparent-e2e.test.sh` with all L1 stubs returning
`_not_implemented` (full RED witness). Phase 2 ships the BDD feature
file ; Phase 3 ships the Kong assertion ; Phase 4 wires CI + docs.
Same cadence as `t5-otel-stack`, `t5-otel-app`, `j8-janus-rules`.

### Article II — BDD

User-facing : pressing the greeting button MUST produce a span tree
visible in SigNoz with the same `traceId` from Flutter root span to
backend handler span. ≥ 3 BDD scenarios shipped in
`traceparent_e2e.feature` covering direct / Kong / sampled-off paths.

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-T5-TPE-*`
namespace before any code ships. `/forge:design` ratifies the gateway
assertion shape + harness layout before `/forge:implement`.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

No inline markers in this proposal. Two open questions tracked in
`open-questions.md` resolved in `design.md` (Q-001 sampled-off
exporter behaviour ; Q-002 Phase D forward-pointer name).

### Article IV — Delta-Based Changes

ADDED requirements only ; no standard amendment ; no version bump on
`observability.yaml`. Kong config edit is comment-only.

### Article V — Audit Trail

Each task tagged `[Story: FR-T5-TPE-XXX]` (Article V.1).

### Article VIII — Infrastructure

Touches `infra/kong/kong.yml.example` (comment-only additive edit).
Honors `infra/kong` standard : declarative config only, no admin API
mutation.

### Article IX — Observability

This change **closes** Article IX's evidence loop for the gateway
hop. After this change, the example tree carries structural BDD
evidence of W3C traceparent preservation across every hop documented
in the demo-005 round trip.

### Article XII — Governance

`observability.yaml` unchanged — **no REVIEW.md ledger entry
required**.

## Citations

- `docs/new-archetypes-plan.md` lines **994–1000** — Phase A + B
  done ; Phase C identified as the closing change.
- `.forge/changes/t5-otel-stack/design.md` ADR-OTEL-001 (sampler
  collector-side) — Phase A's ratio mechanism ; this change asserts
  the sampled-off path is honoured.
- `.forge/changes/t5-otel-app/design.md` ADR-T5-OTA-004 (middleware
  composition order) — Phase B's contract ; this change quotes
  `HeaderMapExtractor` from that ADR's sketch.
- `.forge/changes/t5-otel-app/specs.md` FR-T5-OTA-031 (parent
  linkage of the demo-005 span tree) — Phase B's contract ; this
  change extends it through the Kong gateway hop.
- `.forge/changes/t5-connect-codegen/tasks.md` § "DEFERRED 2026-05-06"
  (`_test_t5_l2_traceparent_dual`) — uplifted to this change.
- `docs/ARCHITECTURE-TARGET.md` ADR-001 (Envoy migration) —
  forward-pointer for the Envoy validation deferred from this scope.
- `examples/forge-fsm-example/infra/kong/kong.yml.example` —
  declarative gateway config audited for `traceparent` policy.

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none in this proposal.
Two open questions raised at this phase, tracked in
`open-questions.md` and resolved during `/forge:design` :

- **Q-001** (sampled-off path exporter semantics) : when an
  incoming `traceparent: 00-...-00` (sampled bit = 0) reaches the
  Rust axum server, MUST the inner spans be created-but-not-exported
  OR not-created-at-all ? OTel-spec answer is "created, recorded,
  parent-based-not-exported" but the Rust SDK's exact behaviour at
  pin `opentelemetry 0.31` needs Context7 confirmation. Resolve at
  design time.
- **Q-002** (Envoy forward-pointer change name) : the future B.8 /
  T6 Envoy migration change name is not yet finalised
  (`b8-envoy-migration` is a working name in
  `docs/ARCHITECTURE-TARGET.md`). Pick the working name to use in
  this change's forward-pointer at design time ; document that the
  name may be renamed at the future change's creation time.
