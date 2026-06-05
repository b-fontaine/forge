# Specs: b8-14-promotion-flip

**Audit item**: B.8.14 (flip) · **Effort**: L · **Status**: specified → 2026-06-05
**Constitution**: 1.1.0 (this change ratifies → v2.0.0) · THE POINT OF NO RETURN.

> Grounded by the `wf_a02b388e` 6-mapper+critic workflow. Two ordered commits
> (ratify → enable). No `[NEEDS CLARIFICATION]` — BDFL decided scope 2026-06-05.

## ADDED Requirements

### Group 1 — Ratification (Commit 1)
#### FR-FLIP-001: BDFL waiver recorded honestly
`.forge/standards/REVIEW.md` MUST carry a Correction Entry recording the §VIII.1
window compression: opened 2026-06-04, ratified 2026-06-05 (~1 day), BDFL
authority, rationale. NO claim of a completed 7-day window.

#### FR-FLIP-002: §VIII.1 amended + Version bumped
`.forge/constitution.md`: §VIII.1 reads "Envoy Gateway SHALL …" (Connect-RPC
replaces gateway REST↔gRPC transcoding); the `## Amendments` table gains row #2
(VIII.1 Kong→Envoy, v1.1.0→v2.0.0, with the waiver callout); `**Version**` is
`v2.0.0`. §VIII.2 (Temporal) UNCHANGED.

#### FR-FLIP-003: constitution_version bumped in templates only
`change.yaml` + `full-stack-monorepo/.forge.yaml.tmpl` + `mobile-only/.forge.yaml.tmpl`
constitution_version → "2.0.0". The 46 historical change `.forge.yaml` files STAY
"1.1.0" (d5 ADR-006 opened-under-old-version).

#### FR-FLIP-004: d5 inverted in lockstep
`d5.test.sh` _012 asserts `**Version**: v2.0.0` + amendment row #2; _013 asserts
templates carry "2.0.0" (d5's own `.forge.yaml` stays 1.0.0).

#### FR-FLIP-005: CHANGELOG BREAKING + framework stays pre-GA
`CHANGELOG.md` `[Unreleased]` gains a `### BREAKING` subsection (constitution
v2.0.0, Kong→Envoy). The framework VERSION stays on the 0.4.0 MINOR line
(pre-GA carve-out VERSIONING.md:70-73) — NOT bumped to 2.x.

#### FR-FLIP-006: ARCHITECTURE-TARGET §11/§12.1 rewrite via t4 material-path
`docs/ARCHITECTURE-TARGET.md` §11/§12.1 realigned (DBOS→Temporal, Kong→Envoy);
`bin/forge-rehash-architecture-doc.sh` re-pins the sha in t4 specs.md + appends
REHASH-LOG.md. `t4.test.sh::_test_t4_023` GREEN after re-pin.

#### FR-FLIP-007: Kong standard tombstone + index cleanup
`.forge/standards/infra/kong.md` becomes a deprecation tombstone redirecting to
`gateway.yaml` (Envoy) + `transport.yaml` (Connect). Its `standards/index.yml`
entry is removed atomically. `j7.test.sh` GREEN.

#### FR-FLIP-008: 1.0.0 deprecation activated
`CHANGELOG.md` `### Deprecated` (full-stack-monorepo 1.0.0, EOL 2026-12-05,
T+6mo) + a support note in VERSIONING.md/GOVERNANCE.md.

### Group 2 — Enablement (Commit 2)
#### FR-FLIP-020: 2.0.0 schema promoted
`2.0.0.yaml`: stage candidate→stable, scaffoldable false→true; the
constitutional-prohibition block reworded (now ratified). `b8-3.test.sh` _006
asserts scaffoldable==true.

#### FR-FLIP-021: Kong-less 2.0.0 scaffold composition
A new `scaffold-plan-2.0.0.yaml` (omitting the Kong entries) + a
`forge-init-fsm-2.0.0` path + a `dispatch-table.yml` 2.0.0 entry produce a fresh
2.0.0 scaffold = 1.0.0 base MINUS Kong PLUS the 2.0.0 overlay. The frozen 1.0.0
base/snapshot are NEVER edited.

#### FR-FLIP-022: scaffolder versioned-selection + guard (B.8.3.b deferred)
`forge init` selects the highest stable+scaffoldable schema (2.0.0) and a runtime
guard REFUSES any `scaffoldable:false` schema. New code in `cli/src`.

#### FR-FLIP-023: New flip harness, RED-first, registered
`.forge/scripts/tests/b8-14-flip.test.sh` asserts: a fresh 2.0.0 scaffold is
Kong-less (no `fsm-kong`, no `infra/kong/`) + Envoy/Connect present; the selection
guard refuses scaffoldable:false; constitution is v2.0.0 + §VIII.1 Envoy.
Registered in `forge-ci.yml`'s hardcoded array.

#### FR-FLIP-024: b8-15 front-door activation; migrate stays additive
`b8-15.test.sh` _005 skip-guard removed; front-door 2.0.0 + Kong-removal-in-fresh-
scaffold cells implemented. The line-225 migrate-flagship fsm-kong assertion STAYS
(migrate additive forever — 1.0.0 adopters keep Kong; b8-12 STAYS green).

#### FR-FLIP-025: bundle regenerated
`cli/assets` regenerated via `npm run bundle` (gitignored build artifact).

### Group 3 — Invariants
#### FR-FLIP-030: migrate-flagship + frozen base untouched
No edit to `bin/forge-migrate-flagship.sh` removal behavior (stays additive), the
frozen 1.0.0 base, or the snapshot (b8-2 sha guard green). b8-12 Kong-preservation
invariants STAY green.

#### FR-FLIP-031: Full suite + gates green
The full 53-harness suite + verify.sh + constitution-linter OVERALL PASS after
both commits.

## Non-functional
- **NFR-001**: New harness hermetic (git/python3/tar/node); registered in the CI array.
- **NFR-002**: Ratify commit precedes removal commit (auditable ordering).
- **NFR-003**: No fabrication (waiver honest; citations verified); independent review before approval.

## BDD
```gherkin
Feature: B.8.14 point-of-no-return flip
  Scenario: Constitution mandates Envoy after ratification
    Given the BDFL ratified the §VIII.1 amendment (waiver recorded)
    Then .forge/constitution.md is v2.0.0 with "Envoy Gateway SHALL" in §VIII.1
    And the Amendments table has row #2 with the window-compression callout

  Scenario: A fresh 2.0.0 scaffold is Kong-less Envoy
    Given 2.0.0 is stage:stable / scaffoldable:true
    When forge init --archetype full-stack-monorepo runs
    Then it produces an Envoy/Connect tree with no fsm-kong and no infra/kong/
    And forge init refuses any scaffoldable:false schema

  Scenario: Existing 1.0.0 adopters keep Kong (additive migrate)
    Given a 1.0.0 project migrates via forge-migrate-flagship.sh
    Then Kong (fsm-kong) is preserved (additive) — removal is fresh-scaffold-only
```
