# Spec: Rollback Runbook (full-stack-monorepo 1.0.0 → 2.0.0)

Canonical requirements for the migration rollback runbook. Source change:
`b8-13-rollback-runbook` (archived 2026-06-04, audit B.8.13). Authoritative doc:
`docs/ROLLBACK.md`. Harness: `.forge/scripts/tests/b8-13.test.sh` (18 L1).

## Requirements

### FR-RBK-001: Authoritative rollback runbook
`docs/ROLLBACK.md` MUST exist as the authoritative operational rollback runbook
for the `full-stack-monorepo` 1.0.0 → 2.0.0 migration, audit-stamped B.8.13. It
MUST be the doc `docs/MIGRATIONS.md` forward-references for the full procedure.

### FR-RBK-002: Two scenarios, five steps each
The runbook MUST document exactly two rollback scenarios —
**A** (p99 latency regression after the Envoy cutover) and
**B** (traceparent propagation error rate) — each with the five operational
steps Detect / Decide / Execute / Verify / Re-attempt.

### FR-RBK-003: Relative thresholds, no committed latency
Triggers MUST be expressed as **relative deltas only**: p99 regression `> 20 %`
(Scenario A), traceparent errors `> 1 %` (Scenario B). NO absolute p50/p95/p99
latency figure may be committed (ADR-B8-1-002 + CLAUDE.md ANTI-HALLUCINATION
PROTOCOL). Detection references the B.8.12 measurement methodology
(`docs/B8-BASELINE.md §6`).

### FR-RBK-004: Graduated reversal (narrowest first)
- Scenario A Execute → reverse the **Kong → Envoy route weights** (config
  reversal; Kong remains the scaffolded default until B.8.14).
- Scenario B Execute → roll back the **OTel SDK overlay only**.
- Last resort → `bin/forge-migrate-flagship.sh --target . --rollback`
  (full byte-frozen 1.0.0 snapshot restore; mutually exclusive with `--phase`).
The runbook criteria MUST stay byte-consistent with the criteria embedded in
`bin/forge-migrate-flagship.sh`.

### FR-RBK-005: No DBOS/CPU criterion (B8O)
The runbook MUST state there is no DBOS- or CPU-based rollback criterion
(Temporal is the orchestrator; no DBOS leg — per B8O).

### FR-RBK-006: Record-only supersession of the sha-pinned arch doc
`docs/ARCHITECTURE-TARGET.md` is sha256-pinned by `t4.test.sh::_test_t4_023` and
MUST NOT be edited by rollback-documentation work. Its B8O-stale §11/§12.1 DBOS
references are superseded **by record** via a Supersession note in
`docs/ROLLBACK.md` (enumerating §11.1/§11.2 ×3/§11.3/§11.4 + §12.1), pointing at
`.forge/standards/orchestration.yaml` v1.2.0 as the authoritative record. The
B.8.13 harness positively asserts the arch-doc sha256 is unchanged.

<!-- Added in b8-13-rollback-runbook change, 2026-06-04 -->
