# Design: b8-14-promotion-flip

**Status**: designed → 2026-06-05 · Constitution 1.1.0 → (ratifies) v2.0.0
Grounded by `wf_a02b388e` (6 mappers + critic). THE POINT OF NO RETURN.

## ADRs

### ADR-FLIP-001: Two ordered commits (ratify → enable)
Ratify-amendment + version bump (C1) MUST land before the Kong removal /
enablement (C2) — removing Kong before §VIII.1 ratifies violates
`2.0.0.yaml:17-31`. Even with the BDFL waiver, ordering is auditable: C1 = pure
governance/constitution (no scaffolder dependency); C2 = enablement (net-new code).

### ADR-FLIP-002: BDFL window waiver, recorded honestly
The 7-day window opened 2026-06-04 (prep). BDFL ratifies 2026-06-05 (~1 day).
Recorded as a `REVIEW.md` Correction Entry with real dates + rationale (NOT a
fabricated completed window). d5-governance REVIEW precedent. Independent reviewer
before approval (no self-approval — t5.2 lesson).

### ADR-FLIP-003: Removal = fresh-scaffold composition only
The 1.0.0 base is byte-frozen (b8-2 sha guard, exit 7) + protected by b8-12
Kong-preservation invariants. migrate-flagship stays additive **forever** (1.0.0
adopters keep Kong). Kong removal happens ONLY for fresh 2.0.0 scaffolds via a NEW
`scaffold-plan-2.0.0.yaml` (omits the Kong entries): `2.0.0 = 1.0.0 base − Kong +
2.0.0 overlay`. Never edit the 1.0.0 plan/snapshot. (Grounding option (a) —
separate plan, no conditional logic in the linear scaffolder.)

### ADR-FLIP-004: Versioned-schema selection + scaffoldable guard (B.8.3.b deferred)
`forge init` gains: pick the highest `stage: stable` + `scaffoldable: true` schema
(→ 2.0.0), and a runtime guard that REFUSES any selected `scaffoldable: false`
schema. New code in `cli/src` (cli.ts resolver + init dispatch) + a
`dispatch-table.yml` 2.0.0 entry. RED harness first.

### ADR-FLIP-005: ARCHITECTURE-TARGET §11/§12.1 via t4 material-path
The arch doc is sha-pinned (t4). §11/§12.1 still describe Kong/DBOS. Material edit
⇒ rewrite §11/§12.1 (DBOS→Temporal, Kong→Envoy) THEN
`bin/forge-rehash-architecture-doc.sh` (re-pins t4 specs.md hash + appends
REHASH-LOG). This change supersedes the Kong/DBOS parts of t4's ADRs (recorded in
REVIEW). `t4.test.sh::_test_t4_023` GREEN post-rehash.

### ADR-FLIP-006: Kong standard tombstone (not delete) during deprecation
`kong.md` becomes a deprecation tombstone → `gateway.yaml` + `transport.yaml`,
valid for 1.0.0 adopters in the T+6mo window; its `index.yml` trigger removed
atomically (else j7 red). Hard-delete after the window (future).

### ADR-FLIP-007: Constitution MAJOR, framework stays pre-GA MINOR
Constitution v1.1.0→v2.0.0 (breaking VIII.1 per VERSIONING:15-17). Framework
stays on the 0.4.0 line + `### BREAKING` CHANGELOG note (pre-1.0 carve-out
VERSIONING:70-73); framework MAJOR deferred to GA. Only TEMPLATES bump
constitution_version; 46 historical change files stay 1.1.0 (d5 ADR-006).

## Break-cascade (invert in the SAME commit as the trigger)
d5.test.sh _012/_013 · b8-14.test.sh held-guards (retire→positive) ·
b8-3.test.sh _006 · b8-15.test.sh _005 · standards/index.yml kong entry ·
t4.test.sh _023 (post-rehash) · 2.0.0 README wording. (See proposal Risks.)

## Testing strategy
- C1: invert d5 + retire/replace b8-14 guards in lockstep with the edits; rehash
  t4; run d5 + t4 + j7 + linter green before committing C1.
- C2: RED-first `b8-14-flip.test.sh` (Kong-less scaffold + guard) → implement
  cli/src + scaffold-plan-2.0.0 → GREEN; invert b8-3/b8-15; bundle; full 53-harness
  suite + verify.sh + constitution-linter green.
- Independent reviewer re-executes the suite live before approval.

## Constitutional Compliance Gate
- Article XII / GOVERNANCE Amendment Process: honored via the recorded BDFL waiver
  (window opened+compressed, not skipped); Amendments row appended; Version bumped.
- §VIII.1 now Envoy (ratified); §VIII.2 Temporal unchanged.
- Article I (TDD): C2 net-new code RED-first.
- Anti-fabrication: honest waiver; t4 material-path (not record-only for a material
  edit); independent review.
- b8-2 frozen base / b8-12 additive invariants preserved.
- **No BLOCK** (the amendment IS this change's authorized purpose). APPROVED for plan pending independent review.
