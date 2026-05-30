# Proposal: b8-1-audit-baseline

<!-- Created: 2026-05-29 -->
<!-- Schema: default -->
<!-- Audit: B.8.1 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0 migration, first item) -->

## Problem

Module **B.8** migrates the flagship `full-stack-monorepo / 1.0.0` to `2.0.0`
(Kong → Envoy Gateway, Temporal → DBOS, REST-bridge → Connect-RPC, implicit
auth → Zitadel). The plan calls this the **point of no return** (§4). B.8.13
defines rollback triggers in terms of *measured* deltas — "p99 increases
> 20 % after Envoy → rollback Kong", "traceparent errors > 1 % → rollback OTel
SDK", "DBOS Postgres > 70 % CPU → fallback Temporal". B.8.12 requires "0
regression on the 4 demos" against the *before* state.

**Neither rollback nor regression-gate is measurable without a baseline
captured on the 1.0.0 stack as it stands today.** Once a single Envoy /
DBOS / Connect template lands on the flagship, the 1.0.0 reference state is
gone and can no longer be captured. B.8.1 is therefore the mandatory first
item of B.8: it freezes the measurable characteristics of the current
flagship so every later B.8.x decision has a comparison anchor.

This change captures **no migration code**. It is a documentation +
harness deliverable, fully additive and reversible (Article V audit value
only — it never touches a rendered template).

## Solution

Produce a versioned **baseline audit artifact** for `full-stack-monorepo /
1.0.0` plus the methodology to re-measure it identically post-migration.

Ground truth verified against the repo (2026-05-29) before writing — the
captured stack is what `examples/forge-fsm-example/` actually ships, not
what the plan assumed:

- **End-to-end path (real)**: Flutter frontend → `fsm-kong` gateway →
  `fsm-backend` (Rust axum/tonic) → `fsm-db` (Postgres). Confirmed in
  `docker-compose.dev.yml` services.
- **Trace coverage (real)**: W3C `traceparent` round-trip is demonstrated by
  `demo-005-connect-greeting` (Flutter root → axum server → connectrpc
  handler → application use case), instrumented by `t5-otel-app` + the
  unified SigNoz stack just re-architected by the B.8.8 trio.
- **Temporal MTBF (NOT real — anti-hallucination catch)**: the plan's B.8.1
  wording assumes running Temporal workers. **There is no Temporal service
  in `docker-compose.dev.yml`** and no worker deployment in
  `examples/forge-fsm-example/infra/`. Temporal exists only as *documentary*
  scaffolding (`infra/CLAUDE.md` "activate when touching Temporal namespace
  / worker deployment"). The baseline records this honestly as a **gap**:
  the 1.0.0 flagship ships Temporal-the-doc, not Temporal-the-deployment, so
  there is no MTBF to capture. This directly informs B.8.5 (DBOS) — the
  "Temporal → DBOS" migration is replacing a documented intent, not a
  running system, which lowers B.8 risk on that leg.

Deliverable shape (resolved precisely at `/forge:specify` + `/forge:design`):

1. **Baseline doc** `docs/B8-BASELINE.md` (or `.forge/_memory/`-located,
   ADR at design) enumerating, for 1.0.0:
   - the component/version matrix actually deployed (Kong, Postgres, Rust
     toolchain, SigNoz unified, OBI/Beyla 3.15.0, Coroot),
   - the canonical span tree for `demo-005` with the exact propagation
     points where `traceparent` crosses a process boundary,
   - the explicit Temporal gap above,
   - latency-capture **methodology** (how to run a local load against the
     dev compose and read p50/p95/p99 from SigNoz) so B.8.12 can re-run it
     identically — the *procedure* is the deterministic artifact, not a CI
     load test.
2. **Statically-assertable trace-coverage snapshot**: a checked-in
   enumeration (count + named spans) of the demo-005 trace tree, so a later
   harness can assert "2.0.0 still emits ≥ the same spans" without live
   infra.
3. **New harness** `.forge/scripts/tests/b8-1.test.sh` — L1 grep-based
   assertions on (i) baseline doc present + dated, (ii) component matrix
   lists the 6 deployed services, (iii) Temporal-gap clause present
   (guards against a future edit silently fabricating an MTBF), (iv) span
   inventory matches the demo-005 instrumentation. L2 opt-in
   `FORGE_B8_1_DOCKER=1` brings the dev compose up and asserts the
   methodology actually reads a non-empty trace from SigNoz (mirrors
   `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER` pattern, ADR-T5-OLR-005).

Decisions reserved for `/forge:design` (resolved as ADRs):

- **ADR-1** — Baseline doc location: adopter-facing `docs/B8-BASELINE.md`
  vs internal `.forge/_memory/`. Lean adopter-facing (the rollback runbook
  B.8.13 will cite it).
- **ADR-2** — Latency baseline form: live capture numbers committed now
  (fragile, machine-dependent) vs methodology-only with a captured sample
  run (reproducible). Lean methodology + one sample capture.
- **ADR-3** — Temporal gap disposition: record-only here, or also open a
  forward-pointer note for B.8.5 so the DBOS architect inherits the
  "replacing intent, not a running system" finding.

Release vehicle: next `0.4.0-rc.x` — additive, no schema bump, no standard
bump. **Note**: this proposal assumes Scenario A (v0.4.0 stable cut from
rc.5 first, flagship 2.0.0 reslotted to v0.5.0). If the maintainer keeps the
rc line running through all of B.8, the release vehicle is simply the next
rc.

## Scope In

- New baseline doc capturing the 1.0.0 deployed component matrix, demo-005
  span tree, Temporal gap, and re-measurement methodology.
- Checked-in static trace-coverage snapshot (span inventory) for demo-005.
- New harness `b8-1.test.sh` (L1 grep + L2 docker-compose live-trace
  opt-in).
- Register harness in `.github/workflows/forge-ci.yml::harness` matrix
  (verify ≤ 300-line NFR-CI-002 budget — currently 300/300; may require the
  3-comment compression per ADR-T533-002, confirm at `/forge:design`).
- CHANGELOG `[Unreleased]` entry.
- Consolidated spec `.forge/specs/b8-baseline.md` for the `FR-B8-1-*`
  namespace.

## Scope Out (Explicit Exclusions)

- **Any migration template** (Envoy / DBOS / Connect / Zitadel) → B.8.4–B.8.9.
- **Schema `2.0.0` candidate** → B.8.3.
- **Legacy snapshot tarball** `1.0.0.tar.gz` to `legacy/` → B.8.2 (sibling
  prereq, separate change for atomic revertability).
- **CI-resident load test** — explicitly out. CI stays hermetic; live
  latency capture is an opt-in local procedure, never a blocking CI gate.
- **Standard bump** — no `.forge/standards/*.yaml` touched. Pure audit
  artifact.
- **Fabricating a Temporal MTBF** — forbidden by Article III.4; the gap is
  recorded, not papered over.
- **Acting on rollback thresholds** — B.8.13 owns the thresholds; B.8.1 only
  supplies the numbers they compare against.

## Impact

- **Users affected**: B.8 architects (Atlas/Aegis reviews downstream) and
  flagship 1.0.0 adopters who will read the rollback runbook. No adopter
  scaffold changes.
- **Technical impact**: docs + one harness + CI matrix registration. Zero
  template edits, zero standard edits, zero schema edits. Lowest-risk
  possible B.8 entry point.
- **Dependencies**: none upstream. Downstream: B.8.12 (regression gate) and
  B.8.13 (rollback runbook) consume this artifact; B.8.5 (DBOS) consumes the
  Temporal-gap finding.

## Constitution Compliance

- **Article I (TDD)**: harness `b8-1.test.sh` is written RED-first against the
  not-yet-written baseline doc, then the doc is authored to GREEN it. The
  span-inventory assertion is the failing test that drives the inventory's
  content.
- **Article II (BDD)**: no new user-facing runtime feature; the L2 opt-in
  live-trace check carries a Given/When/Then in the harness comment (dev
  stack up → demo-005 invoked → SigNoz returns a non-empty trace).
- **Article III (Specs Before Code)**: spec `.forge/specs/b8-baseline.md`
  authored at `/forge:specify` before any deliverable. Article III.4
  enforced: the Temporal gap is the marquee anti-hallucination case — no
  fabricated MTBF.
- **Article V (Audit Trail)**: the entire change is an Article-V artifact;
  it adds historical record, mutates no prior change.
- **Article VII (Rust architecture)**: no Rust code authored; the span
  inventory references existing `#[tracing::instrument]` spans from
  `t5-otel-app` without modifying them.
- **Article XII (Governance)**: no constitutional amendment; additive audit
  change ratified under v1.1.0.

## Open Questions (seed — tracked in open-questions.md at /forge:specify)

- **Q-001** — Baseline doc location (ADR-1)?
- **Q-002** — Latency form: live numbers vs methodology + sample (ADR-2)?
- **Q-003** — Does B.8.1 also pre-capture `mobile-only / 1.0.0` baseline, or
  flagship-only? (Plan §4.2 says flagship; B.9 has its own baseline need.)
  Lean flagship-only.
