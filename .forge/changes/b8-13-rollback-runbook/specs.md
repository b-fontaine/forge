# Specs: b8-13-rollback-runbook

**Audit item**: B.8.13 · **Effort**: S · **Status**: specified → 2026-06-04
**Constitution**: 1.1.0 · **Type**: documentation + L1 harness

> Spec-writer (Clio) note — every FR below is a **grep/diff-checkable** assertion
> against a committed doc or the live tree, so the L1 harness can verify each one
> hermetically (no toolchain, ≤ a few seconds). No FR commits an absolute latency
> figure (Article III.4 Ambiguity Protocol governs the `[NEEDS CLARIFICATION]`
> STOP rule; the no-fabrication doctrine is CLAUDE.md **ANTI-HALLUCINATION
> PROTOCOL** + ADR-B8-1-002). The two rollback thresholds are **relative**
> deltas, ratified in B.8.12.

---

## Anti-hallucination pass (CLAUDE.md ANTI-HALLUCINATION PROTOCOL)

| Claim | Ground truth (verified live) |
|-------|------------------------------|
| §11.3 exists with rollback criteria | `docs/ARCHITECTURE-TARGET.md:856-861` ✓ |
| §11.3 still carries a stale DBOS-CPU criterion | line 860 ✓ |
| §11 has further B8O-stale DBOS refs | mermaid `:805`, Phase 2 `:832`, Phase-2 risk `:837`, Phase-3 risk `:847`, risk table `:867` ✓ (six in §11) |
| §12.1 YAML illustration is B8O-stale | `:930` `default: dbos` ✓ |
| **ARCHITECTURE-TARGET.md is sha256-pinned** | `t4.test.sh::_test_t4_023` (`:278-294`) pins it vs `t4-adr-ratification/specs.md`; live hash `502bd8a2…895d` == pinned ✓ → **must NOT be edited** |
| rehash hatch is non-material-only | `bin/forge-rehash-architecture-doc.sh` REHASH-LOG: "Material edits MUST be ratified by a fresh Forge change" ✓ |
| B8O used record-only (did not edit the pinned doc) | `b8-orchestration-temporal-realign/design.md:18` ✓ |
| MIGRATIONS.md forward-references the runbook | `:144` "see B.8.13 for the full runbook"; `:172` "(B.8.13+)"; `:182` "B.8.13 rollback thresholds" ✓ |
| MIGRATIONS.md is NOT sha-pinned (editable) | only content-grepped by b8-10/b8-12 harnesses ✓ |
| `--rollback` mechanism exists | `bin/forge-migrate-flagship.sh` `--rollback` `:415`, `_b810_rollback` `:373`, snapshot `:50-51` ✓ |
| migrate script embeds the B.8.13 criteria | `:394-396` (p99/Kong, traceparent/OTel, "no CPU criterion (B8O)") ✓ |
| Kong rollback = reverse canary route cutover | Envoy ∥ Kong additive (B.8.4); MIGRATIONS.md:106 ✓ |
| No committed p50/p95/p99 in MIGRATIONS/B8-BASELINE | b8-12 `_test_b812_017`; fsm-backend `image: scratch` ✓ |

No `[NEEDS CLARIFICATION]` markers — scope and mechanisms are fully grounded.

---

## ADDED Requirements

### Group 1 — `docs/ROLLBACK.md` runbook (structure)

#### FR-B813-001: Runbook document exists
A new file `docs/ROLLBACK.md` MUST exist, titled as the 1.0.0 → 2.0.0
`full-stack-monorepo` rollback runbook, with an `<!-- Audit: B.8.13
(b8-13-rollback-runbook) -->` provenance comment.

#### FR-B813-002: Two operational scenarios
The runbook MUST document exactly two rollback scenarios, each a distinct
`##`/`###` section:
- **Scenario A** — p99 latency regression after the Envoy cutover.
- **Scenario B** — traceparent propagation error rate.

#### FR-B813-003: Five-step structure per scenario
Each scenario MUST carry the five operational steps, each a labelled
subsection or list item: **Detect**, **Decide**, **Execute**, **Verify**,
**Re-attempt**.

### Group 2 — Scenario A (p99 → roll back Kong)

#### FR-B813-010: Trigger threshold (relative)
Scenario A MUST state the trigger as **p99 latency regression greater than
20 %** after the Envoy cutover, measured as a **relative delta** (before = Kong
route, after = Envoy route). It MUST NOT state an absolute millisecond figure.

#### FR-B813-011: Detection procedure
Scenario A **Detect** MUST reference the B.8.12 measurement methodology
(`docs/MIGRATIONS.md` "Latency measurement methodology" / `docs/B8-BASELINE.md
§6`): drive the Connect/gRPC happy-path, read p99 from the
exporter/collector at run-time, compare before/after.

#### FR-B813-012: Execution = reverse the canary route cutover
Scenario A **Execute** MUST instruct the operator to roll back the
**Kong → Envoy route weights** (reverse the additive canary cutover; Envoy and
Kong both remain present pre-2.0.0-stable), NOT a full-tree wipe. It MUST
reference the canary cutover documented in `docs/MIGRATIONS.md`.

#### FR-B813-013: Verify + Re-attempt
Scenario A **Verify** MUST describe confirming traffic is served via Kong again
(route weights / health). **Re-attempt** MUST point back at the Phase-2 overlay
once the latency regression is remediated.

### Group 3 — Scenario B (traceparent → roll back OTel SDK)

#### FR-B813-020: Trigger threshold (relative)
Scenario B MUST state the trigger as **traceparent propagation errors
exceeding 1 %**, measured as a rate. No absolute figure beyond the 1 % rate.

#### FR-B813-021: Execution = roll back the OTel SDK overlay only
Scenario B **Execute** MUST instruct rolling back the **OTel SDK overlay
only** (not Envoy, not a full-tree rollback) — the narrowest reversal.

#### FR-B813-022: Verify + Re-attempt
Scenario B **Verify** MUST describe confirming traceparent error rate returns
below 1 %. **Re-attempt** MUST point at re-applying the SDK overlay after fix.

### Group 4 — Full-tree rollback + B8O scope

#### FR-B813-030: Last-resort full-tree rollback section
The runbook MUST document the full-tree rollback as a last resort:
`bin/forge-migrate-flagship.sh --target . --rollback` (restores the byte-frozen
1.0.0 snapshot; `--rollback --dry-run` previews). It MUST note `--rollback` is
mutually exclusive with `--phase`.

#### FR-B813-031: Explicit no-DBOS / no-CPU criterion note
The runbook MUST contain an explicit statement that there is **no DBOS- or
CPU-based rollback criterion** (per B8O — Temporal is the orchestrator; no DBOS
leg exists to roll back to or fall back from). The runbook MUST NOT present any
DBOS- or CPU-based rollback/fallback criterion as active.

#### FR-B813-032: Runbook ↔ migrate-script criteria consistency
The runbook's two criteria MUST be byte-consistent with the criteria text
embedded in `bin/forge-migrate-flagship.sh` (`:394-396`): "p99 +>20% after Envoy
→ roll back Kong" and "traceparent errors >1% → roll back OTel SDK only", and the
"no CPU criterion (B8O)" note. (Harness greps both and asserts agreement.)

### Group 5 — Supersession record (record-only; arch doc stays frozen)

#### FR-B813-040: ARCHITECTURE-TARGET.md left byte-frozen (t4 pin preserved)
The B.8.13 change MUST NOT modify `docs/ARCHITECTURE-TARGET.md`. The harness MUST
positively assert its `shasum -a 256` still equals the hash pinned in
`.forge/changes/t4-adr-ratification/specs.md` (i.e. `t4.test.sh::_test_t4_023`
stays green). Rationale: the doc is sha-pinned and the DBOS realignment is a
*material* edit (rehash hatch forbids material edits; B8O precedent is
record-only).

#### FR-B813-041: Supersession note enumerates the stale refs
`docs/ROLLBACK.md` MUST carry a **Supersession note** that records, as
**obsolete per B8O**, the B8O-stale DBOS references in ARCHITECTURE-TARGET.md:
the six §11 locations (mermaid, Phase 2 ×2 incl. the Go-SDK risk, Phase 3 risk,
§11.3 criterion, §11.4 risk row) **and** §12.1's `default: dbos` illustration —
pointing at `orchestration.yaml` v1.2.0 (`default_by_language.rust: temporal`)
and the `b8-orchestration-temporal-realign` change as the authoritative record.

### Group 6 — MIGRATIONS.md re-point

#### FR-B813-050: Forward-reference resolved
`docs/MIGRATIONS.md` MUST link the full rollback procedure to `docs/ROLLBACK.md`
(the `:144` "see B.8.13 for the full runbook" pointer resolves to a real doc).
The `:172/:182` B.8.13 references MUST remain threshold-consistent with the
runbook (no contradiction). The criteria summary may stay; the operational steps
now live in the runbook.

### Group 7 — Anti-fabrication + frozen invariants

#### FR-B813-060: No committed latency figure
`docs/ROLLBACK.md` MUST NOT introduce any absolute p50/p95/p99 latency number
(ms/µs/s). Only relative deltas (`> 20 %`) and the `> 1 %` error rate are
permitted. (Mirrors b8-12 `_test_b812_017`.)

#### FR-B813-061: Frozen 1.0.0 templates byte-identical
The B.8.13 change MUST NOT modify any
`.forge/templates/archetypes/full-stack-monorepo/` 1.0.0 template file, the
1.0.0 snapshot, or its `.sha256` (b8-2 guard).

#### FR-B813-062: No standard / schema / constitution / sibling-spec mutation
No file under `.forge/standards/`, no `*/2.0.0.yaml` schema, no
`.forge/constitution.md`, and no `.forge/changes/t4-adr-ratification/specs.md`
may change. `constitution_version` stays `1.1.0`.

### Group 8 — Harness + CI

#### FR-B813-066: forge-ci registration
`.github/workflows/forge-ci.yml` MUST register `b8-13.test.sh --level 1` in the
harness matrix.

#### FR-B813-067: CHANGELOG anchor
`CHANGELOG.md` MUST carry a `b8-13` / B.8.13 entry under `[Unreleased]`
(whole-file grep anchor — changelog-coupling lesson).

#### FR-B813-068: Coupling guards
`b8-13.test.sh` MUST include a coupling guard that re-runs, by exit code, the
sibling harnesses whose subjects it forward-references or depends on: at minimum
`b8-12`, `b8-10`, and **`t4`** (the arch-doc pin it must not break).

---

## Non-functional requirements

- **NFR-001**: L1 harness is hermetic — grep/diff/stat/shasum only, no
  cargo/flutter/docker/node, ≤ a few seconds, passes on CI's
  Python+Node+shellcheck-only runner.
- **NFR-002**: All FRs are individually grep/diff-checkable.
- **NFR-003**: Pure-additive — the only mutated pre-existing files are
  `docs/MIGRATIONS.md` (re-point), `CHANGELOG.md`,
  `.github/workflows/forge-ci.yml`; everything else is new (`docs/ROLLBACK.md`,
  `b8-13.test.sh`). `docs/ARCHITECTURE-TARGET.md` is **not** touched (FR-040).
- **NFR-004**: No fabricated external version/API (no external pins in this
  brick at all).

---

## BDD acceptance criteria

```gherkin
Feature: 1.0.0 → 2.0.0 rollback runbook

  Scenario: Operator sees p99 regress after the Envoy cutover
    Given the flagship has been migrated to 2.0.0 with Envoy ∥ Kong
    And p99 latency on the Envoy route is more than 20% above the Kong baseline
    When the operator opens docs/ROLLBACK.md Scenario A
    Then they find a Detect step citing the B.8.12 measurement methodology
    And a Decide step stating the > 20% relative threshold
    And an Execute step that reverses the Kong → Envoy route weights
    And a Verify step confirming traffic is served via Kong again
    And no absolute millisecond latency figure anywhere

  Scenario: Operator sees traceparent errors climb after the OTel overlay
    Given the 2.0.0 OTel SDK overlay is active
    And traceparent propagation errors exceed 1%
    When the operator opens docs/ROLLBACK.md Scenario B
    Then the Execute step rolls back the OTel SDK overlay only
    And neither Envoy nor a full-tree rollback is triggered

  Scenario: Operator needs a clean-slate reversal
    Given a migration must be fully reverted
    When the operator follows the full-tree rollback section
    Then it documents `forge-migrate-flagship.sh --target . --rollback`
    And notes it restores the byte-frozen 1.0.0 snapshot
    And there is no DBOS- or CPU-based rollback criterion anywhere

  Scenario: The stale architecture narrative is recorded, not silently wrong
    Given ARCHITECTURE-TARGET.md is sha256-pinned (t4) and must not be edited
    And §11/§12.1 still describe the B8O-cancelled Temporal→DBOS model
    When docs/ROLLBACK.md is read
    Then a Supersession note lists those references as obsolete per B8O
    And points at orchestration.yaml v1.2.0 as the authoritative record
    And ARCHITECTURE-TARGET.md's sha256 is unchanged (t4 stays green)
```
