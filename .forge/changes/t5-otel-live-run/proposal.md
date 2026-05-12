# Proposal: t5-otel-live-run
<!-- Created: 2026-05-12 -->
<!-- Schema: full-stack-monorepo -->
<!-- Audit: T.5 / Phase D — OTel live-run validation -->

## Problem

Phase A (`t5-otel-stack` archived 2026-05-10) shipped the OTel + OBI +
Coroot **infra**. Phase B (`t5-otel-app` archived 2026-05-12) shipped
the **app-side SDK** init on both layers of `examples/forge-fsm-example/`.
Phase C (`t5-otel-traceparent-e2e` archived 2026-05-11) shipped the
**BDD spec + grep harness** asserting Kong preserves `traceparent`.

What is still missing : **mechanical proof that the wired stack actually
emits OTLP traffic with the right `service.name` + W3C `traceparent`
parent-child linkage when the apps run**. Phase C explicitly deferred
this to Phase D (see `.forge/changes/t5-otel-traceparent-e2e/tasks.md`
§ "Phase D — DEFERRED").

Concrete gaps after Phase C :

1. **No live OTLP capture**. The collector contract (HTTP/protobuf on
   `:4318`) and the symmetric Rust + Dart SDK init are documented and
   syntactically anchored but never executed end-to-end on developer
   hardware or CI.
2. **No traceparent linkage proof**. Phase C asserts the BDD scenario
   text exists and Kong does not strip the header ; nothing yet
   captures an OTLP export and walks the resulting span tree to
   confirm `traceparent` produced parent-child span relationships
   across hops.
3. **No golden capture committed**. Adopters reading
   `examples/forge-fsm-example/` have a feature file but no
   reproducible reference output of "what a healthy trace tree looks
   like".
4. **No CI gate covering the live wiring**. Phase C's harness runs in
   ≤ 3 s of greps ; live-run is a separate CI surface that must skip
   gracefully when Docker is unavailable (developer laptop in airplane
   mode, GitHub-hosted runners with no Docker daemon).

## Solution

Ship a **dual-mode live runner** : a hermetic **fake-collector mode**
(Python stdlib only, no Docker, runs in CI) and a documented
**docker-compose mode** for adopters who want the full SigNoz + Coroot
stack.

Strict scope :

1. **Fake-collector smoke driver**
   `examples/forge-fsm-example/test/live-run/fake_otlp_collector.py`
   (Python 3 stdlib only — `http.server` + `threading`). Binds
   `:4318/v1/traces`, accepts `application/x-protobuf` POSTs, decodes
   span resource attributes via a minimal protobuf-tag walker (no
   `protobuf` pip dep — Python stdlib only), persists each request as a
   sanitised JSON capture. Resource extraction is intentionally minimal
   (just `service.name` + the W3C `traceparent` echo) — full protobuf
   parsing is **out of scope** ; this is a contract verifier, not a
   collector replacement.
2. **Smoke driver script**
   `examples/forge-fsm-example/test/live-run/run_smoke.sh` — starts
   the fake collector in the background, runs a tiny OTLP-emitting
   probe (a Python `urllib.request.urlopen` POST with a
   pre-canned hex-encoded protobuf payload mimicking what
   `tracing-opentelemetry` would emit), captures the output, asserts :
   (a) `service.name` resource attribute present, (b) `traceparent`
   header forwarded verbatim, (c) request body decodes to a non-empty
   trace payload.
3. **Golden captures**
   `.forge/changes/t5-otel-live-run/captures/` — two committed JSON
   files (`direct.golden.json`, `kong.golden.json`) representing the
   sanitised capture shape (no IPs, no timestamps in capture body —
   timestamps replaced by `"<ts:redacted>"` placeholder by the
   collector's sanitiser). Adopters get a written reference of the
   contract shape.
4. **Docker-compose live-run (documentation + skipped CI)**
   `examples/forge-fsm-example/test/live-run/docker-compose.live-run.yml`
   — boots `fsm-otel-collector` + `fsm-backend` + `fsm-kong` (no
   SigNoz, no DB — minimal for the live run). The harness's L2 leg
   invokes it if `docker compose` is on PATH AND `FORGE_LIVE_RUN_DOCKER=1`
   is set ; otherwise skips with a documented message. CI keeps L1
   only — no Docker on Ubuntu runners.
5. **BDD feature**
   `examples/forge-fsm-example/test/features/traceparent_live_run.feature`
   — a NEW feature file (not a modification of Phase C's
   `traceparent_e2e.feature` which is hard-pinned by NFR-T5-TPE-004).
   Two scenarios : "Fake collector receives OTLP export with the
   expected service.name" and "Captured trace carries a W3C
   traceparent linking parent and child spans".
6. **L1 harness**
   `.forge/scripts/tests/t5-otel-live-run.test.sh` — 8 L1 hermetic
   tests (driver + collector + captures + feature file + CI matrix)
   + 1 L2 docker-compose smoke (skipped when docker absent).
7. **CI registration** : 1 new step in `forge-ci.yml` `harness` job
   matrix immediately after `t5-otel-traceparent-e2e.test.sh`,
   `--level 1`. Budget audit : current `forge-ci.yml` = 269 lines ;
   NFR-CI-002 cap = 300 ; +3 lines ⇒ 272 ≤ 300 ✓.
8. **Spec artefacts** under `.forge/changes/t5-otel-live-run/` :
   `.forge.yaml`, this `proposal.md`, `specs.md` (FR-T5-OLR-* /
   NFR-T5-OLR-*), `design.md` (ADR-T5-OLR-*), `tasks.md`,
   `open-questions.md`.
9. **`CHANGELOG.md` `[Unreleased]` entry.**
10. **Documentation update** : `docs/new-archetypes-plan.md` Phase D
    row + `.forge/product/roadmap.md` Phase 3 inventory.

## Scope In

- Fake-collector + smoke driver + golden captures.
- New BDD feature `traceparent_live_run.feature`.
- New harness `t5-otel-live-run.test.sh`.
- CI registration (1 step).
- Optional docker-compose live-run config (documentation + opt-in L2).
- Roadmap + plan + CHANGELOG entries.
- New `.forge/changes/t5-otel-live-run/` tree.

## Scope Out (Explicit Exclusions)

- **NOT** Envoy gateway live run. Stays deferred to T6 / B.8 per
  `docs/ARCHITECTURE-TARGET.md` ADR-001 (consistent with Phase C
  ADR-T5-TPE-002).
- **NOT** modifying Phase C's `traceparent_e2e.feature` (Phase C is
  hard-pinned by NFR-T5-TPE-004 — comment-only). New feature file
  ships instead.
- **NOT** modifying Phase B's `crates/infrastructure/src/telemetry/`
  module or Flutter `lib/core/telemetry/` (no app-code changes — the
  apps already export OTLP correctly per Phase B's L2 cargo+flutter
  smoke).
- **NOT** writing a real `cucumber-rs` or `bdd_widget_test` step
  binding. The feature file documents the live-run contract ; step
  bodies remain executable-as-documentation (the harness drives the
  actual smoke flow). A future change may bind real cucumber step
  defs ; out of scope here.
- **NOT** bumping OTel lib versions. Stays on Workiva Dart pkg
  `opentelemetry: 0.18.11` (Traces=Beta) and Rust `opentelemetry 0.31`
  family pinned by Phase B (ADR-T5-OTA-001).
- **NOT** I.3 / I.5 / I.6 compliance work (parallel changes).
- **NOT** running a real SigNoz API query. Phase C's design.md
  ADR-T5-TPE-001 already documents the expected SigNoz shape ;
  Phase D's evidence is the OTLP export at the collector boundary,
  which is what `observability.yaml` actually contracts.
- **NOT** Aegis SBOM regeneration or new observability backend.

## Crucial nuance — Phase D is HERMETIC by default

This change ships :
- A fake-collector that runs **without Docker** in CI on the standard
  Ubuntu runner (Python stdlib only).
- A smoke driver that runs **without Docker** by emitting a canned
  OTLP payload (the contract verifier, not a stack runner).
- Golden captures committed once at impl time and asserted byte-stable
  by the harness.

This change explicitly does NOT require :
- Docker to be installed on CI runners (L2 docker leg is opt-in,
  skipped by default).
- A real Rust binary or Flutter app to be built (the live wiring is
  validated by Phase B's L2 cargo+flutter smoke ; this change asserts
  the **collector-side contract** of what OTLP traffic looks like).

The docker-compose mode is **documented** for adopter reproduction on
their own hardware but is not the primary evidence path.

## Impact

- **Users affected** : `examples/forge-fsm-example/` adopters gain a
  hermetic smoke test they can run locally with `bash test/live-run/run_smoke.sh`
  and a reference golden capture under `.forge/changes/t5-otel-live-run/`.
- **Technical impact** : ~1 Python script (≈ 150 lines, stdlib only)
  + ~1 bash driver (≈ 80 lines) + 2 golden JSON files (≈ 30 lines
  each) + 1 new `.feature` file (≈ 50 lines) + 1 new harness (≈ 200
  lines) + 1 CI matrix line + ≤ 5 lines docker-compose example +
  1 new change tree. **Effort `M`** (larger than Phase C because of
  the executable artefact, smaller than Phase B because no app-code
  changes).
- **Dependencies** :
  - `t5-otel-stack` ✅ (collector contract HTTP/protobuf `:4318`).
  - `t5-otel-app` ✅ (Rust + Flutter SDK init shape consumed).
  - `t5-otel-traceparent-e2e` ✅ (Phase C feature file complemented).
  - `t5-otel-dart-api-realign` ✅ (Workiva pkg API ratified).
  - `observability.yaml` v1.1.0 — consumed verbatim, NOT amended.
- **Risk level** : **Low**. The fake-collector is Python stdlib only ;
  the golden captures are sanitised (no PII, no IP, no timestamp) ;
  the docker leg is opt-in.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` ships the
harness with 8 L1 stubs returning `_not_implemented` (full RED
witness). Phase 2 ships the fake collector + driver. Phase 3 ships
the captures + feature file. Phase 4 wires CI + docs.

### Article II — BDD

User-facing surface : the smoke driver produces a healthy OTLP
capture matching the contract shape. 2 BDD scenarios in
`traceparent_live_run.feature`.

### Article III — Specs Before Code

Confirmed. `specs.md` ships `FR-T5-OLR-*` namespace before any code.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

No inline markers. One open question tracked in `open-questions.md`
resolved at design time : **Q-001** (protobuf decoding strategy —
stdlib walker vs Python `protobuf` pip dep).

### Article IV — Delta-Based Changes

ADDED requirements only ; no standard amendment ; no version bump.

### Article V — Audit Trail

Each task tagged `[Story: FR-T5-OLR-XXX]`.

### Article VIII — Infrastructure

Touches `infra/` (the optional docker-compose live-run file under
`test/live-run/`) but additively. Honors `infra/docker-compose`
standard : `fsm-` prefix maintained, named network, healthchecks.

### Article IX — Observability

This change **closes** Phase C's deferred live-run leg. The
collector-boundary contract is now mechanically verified per
`observability.yaml` v1.1.0.

### Article XII — Governance

`observability.yaml` unchanged — no REVIEW.md ledger entry required.

## Citations

- `.forge/changes/t5-otel-traceparent-e2e/tasks.md` § "Phase D —
  DEFERRED" — explicit handover.
- `.forge/changes/t5-otel-traceparent-e2e/proposal.md` lines
  161–174 — "Phase C is harness + spec, NOT live-run".
- `.forge/changes/t5-otel-app/design.md` ADR-T5-OTA-002 — OTLP
  HTTP/protobuf `:4318` symmetry over gRPC.
- `.forge/standards/observability.yaml` v1.1.0 — collector contract.
- `docs/new-archetypes-plan.md` line 167 — "traceparent W3C E2E
  validation through Envoy/Kong" — Phase D row.

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none. One question in
`open-questions.md` :

- **Q-001** (protobuf decoding strategy) : Python stdlib walker vs
  pip `protobuf` dep. Resolved at design time (ADR-T5-OLR-001 :
  stdlib walker, ≤ 60 lines, decodes only the tags we assert).
