# Spec: b8-baseline

<!-- Audit: B.8.1 (b8-1-audit-baseline) — flagship 1.0.0 → 2.0.0 migration baseline. -->
<!-- Source change : `.forge/changes/b8-1-audit-baseline/` (delta specs.md authoritative). -->

**Namespace** : `FR-B8-1-*` / `NFR-B8-1-*` / `ADR-B8-1-*`.
**Constitution** : v1.1.0. No amendment. Pure audit artifact — no migration
code, no template / standard / schema mutation (NFR-B8-1-002).
**Governing article** : III.4 (Anti-Hallucination).

## Purpose

First item of Module B.8 (`docs/new-archetypes-plan.md` §4.2). Freezes the
measurable characteristics of `full-stack-monorepo / 1.0.0` before any
migration template touches the flagship, so B.8.12 (regression gate) and
B.8.13 (rollback runbook) have a comparison anchor, and B.8.5 (DBOS) inherits
the Temporal-gap finding.

## Deliverables

| Artifact | Path | FR |
|----------|------|----|
| Baseline doc | `docs/B8-BASELINE.md` | FR-B8-1-001/010/011/012/013/020/030 |
| Span inventory | `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml` | FR-B8-1-031/032 |
| Harness | `.forge/scripts/tests/b8-1.test.sh` (10 L1 + 1 L2 opt-in) | FR-B8-1-050/051/033/060 |
| CI registration | `.github/workflows/forge-ci.yml::harness` | FR-B8-1-080 |
| CHANGELOG | `[Unreleased]` entry | FR-B8-1-090 |
| Consolidated spec | this file | FR-B8-1-100 |

## Anti-Hallucination findings recorded (Article III.4)

1. **Temporal gap** (FR-B8-1-013) — no Temporal worker deployed; documentary
   only. No MTBF fabricated; negative harness guard (FR-B8-1-033). Forward
   pointer: B.8.5 DBOS replaces a documented intent, not a running system.
2. **Backend placeholder** (FR-B8-1-012) — `fsm-backend` is `image: scratch`;
   live end-to-end latency not capturable from the example unmodified →
   latency baseline is methodology, not numbers (ADR-B8-1-002).
3. **Postgres 16** (FR-B8-1-011) — 1.0.0 ships `postgres:16-alpine`, no
   pgvector; 2.0.0 target is 17 + pgvector. Delta recorded, not normalized.
4. **3-span vs 4-span** (FR-B8-1-020) — demo-005 emits 3 code-verified spans
   (`http client request` client / `http.request` server / `greeter.greet`
   internal); the doc prose's "connectrpc handler" is not a distinct
   instrument site (shares the server span). Implement-time correction.

## ADRs

- **ADR-B8-1-001** — baseline doc adopter-facing at `docs/B8-BASELINE.md`.
- **ADR-B8-1-002** — latency = methodology + non-normative sample, no
  committed live numbers (placeholder backend forces it).
- **ADR-B8-1-003** — Temporal gap recorded with B.8.5 forward-pointer.
- **ADR-B8-1-004** — flagship-only scope; harness path parameterized for B.9.
- **ADR-B8-1-005** — span inventory is durable YAML under `.forge/baselines/`.
- **ADR-B8-1-006** — CI registration within 300-line budget via 3-comment
  compression.

## Constitutional compliance

Article I (TDD RED-first harness), II (L2 BDD scenario), III.4 (4 findings
above), V (audit-trail artifact), IX (span inventory = trace-coverage
reference), XII (additive, no amendment). No violations.
