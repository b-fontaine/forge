# Spec — B.8 Orchestration default reconciled with Constitution §VIII.2 (Temporal)

<!-- Consolidated spec for change `b8-orchestration-temporal-realign` (B.8.5 follow-on),
     archived 2026-06-01. Namespace FR-B8O-* / NFR-B8O-* / ADR-B8O-*. Source of intent;
     the full requirement bodies + BDD + anti-hallucination pass live in
     .forge/changes/b8-orchestration-temporal-realign/specs.md. -->

## Context

ADR-002 (`docs/ARCHITECTURE-TARGET.md`) proposed Temporal→DBOS as the default
orchestrator. That swap is **unbuildable**: DBOS has **no Rust SDK** (crates.io `dbos`
404; SDKs = Python/TS/Go/Java/Kotlin) and Forge backends are Rust end-to-end.
Constitution **§VIII.2 already mandates Temporal**. This change reconciles the
orchestration standard with §VIII.2 (no amendment) and demotes DBOS to a watch-list
future-option.

## ADDED Requirements (FR-B8O-* / NFR-B8O-*)

Authored in `b8-orchestration-temporal-realign/specs.md` (6 clusters):
- **Cluster 1 — orchestration.yaml C-map bump (FR-B8O-001..008, 017, 018, 019):**
  1.1.0 → 1.2.0 additive; `default_by_language: { rust: temporal }`; `dbos:`
  future-option block (`available: false`, `requires: rust-sdk-ga`, `revisit`); `temporal:`
  crate-family (no version); flat `default:`/`fallback:`/`fallback_trigger:` dropped; J.7
  GREEN + REVIEW.md 1.2.0 row; consumers updated (`b8-5.test.sh` T-006/T-010,
  `constitution-linter.sh:802`, `forbidden-components-rules.md` T3-RULE-003, `2.0.0.yaml:76`).
- **Cluster 2 — 2.0.0.yaml candidate (FR-B8O-010..016):** `dbos-embedded` →
  `status: future-option` (no `replaces:`); `temporal-intent → dbos-embedded` delta
  `cancelled: true` (kept, auditable); b8-3 (17/17) + b8-3b (12/12) GREEN.
- **Cluster 3 — temporal.md realign (FR-B8O-020..026):** real published `temporalio-sdk`
  macro API (`#[workflow]`/`#[workflow_methods]`/`#[run]` + `WorkflowContext`;
  `#[activities]`/`#[activity]` + `ActivityContext`; `WorkerOptions`/`register_workflow`);
  Public-Preview caveat; NO concrete version pin (family-only + verify-then-pin).
- **Cluster 4 — ADR-002 reconciliation (FR-B8O-030..033):** ADR-B8O-001 cancels the
  Temporal→DBOS swap for Rust; **no Constitution amendment** (§VIII.2 already mandates
  Temporal); INDEPENDENT reviewer ratifies.
- **Cluster 5 — roadmap deltas (FR-B8O-040..043):** B.8.5 struck / B.8.10 Phase-2 DBOS
  leg dropped / B.8.13 DBOS-saturation rollback removed / B.6.2 native-Rust-SDK note.
- **Cluster 6 — gates (FR-B8O-050..053):** new `b8o.test.sh` (10 L1, CI-registered;
  T-009 scans orchestration.yaml + temporal.md); full ~42-harness suite pre-push + post
  `planned→implemented` flip.
- **NFR-B8O-001..005:** additive-only / zero 1.0.0-adopter impact; no fabricated
  versions/APIs (verify-then-pin); harness ≤5s zero-dep; consumer enumeration before key
  drops; independent review + full-suite ordering.

## MODIFIED Requirements

### ADR-002 "DBOS default" ratification — SUPERSEDED FOR RUST
- **Previously** (recorded at `.forge/specs/adr-ratification.md:47`, ADR-002): DBOS is the
  default orchestrator for `full-stack-monorepo` + `ai-native-rag`; Temporal reserved for
  `event-driven-eu`.
- **Now** (ADR-B8O-001): for Rust archetypes the default is **Temporal** (aligned with
  Constitution §VIII.2); DBOS is a watch-list future-option pending a production-grade Rust
  DBOS SDK; `event-driven-eu` unchanged (already Temporal). `adr-ratification.md` is left
  byte-untouched (harness-coupled list mention; supersession recorded here + in
  `orchestration.yaml` v1.2.0 + REVIEW.md + CHANGELOG + design.md ADR-B8O-001).

## ADRs

`ADR-B8O-001` (reconcile default with §VIII.2; cancel ADR-002 for Rust; no amendment),
`ADR-B8O-002` (orchestration.yaml shape), `ADR-B8O-003` (2.0.0.yaml reclassify + delta
cancellation, b8-3-safe), `ADR-B8O-004` (temporal.md realign + verify-then-pin),
`ADR-B8O-005` (roadmap deltas in-change). Full bodies in the change's `design.md`.

## Verification

Independent review (impl): round 1 CHANGES REQUIRED → round 3 APPROVE (reproducible
`temporalio-sdk` citation in evidence.md §2b; CRITICAL-1/CRITICAL-2/MAJOR closed). Gates
GREEN pre-flip, post-flip, post-correction: 44/44 harnesses, verify PASS, linter OVERALL
PASS (Article III.4 PASS), J.7 dir+file, b8-3 17/17, b8-3b 12/12, b8-5 (repurposed) 12/12,
i3, b8o 10/10. constitution.md / frozen schema.yaml / flat 1.0.0 compose byte-untouched.
