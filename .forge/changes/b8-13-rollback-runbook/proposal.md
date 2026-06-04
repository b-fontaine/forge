# Proposal: b8-13-rollback-runbook

**Audit item**: B.8.13 (docs/new-archetypes-plan.md §4.2, lines 2339-2344)
**Effort**: S
**Status**: proposed → 2026-06-04
**Type**: documentation + L1 harness (no code, no standard, no schema, no constitution mutation)

## Why

The `full-stack-monorepo` 1.0.0 → 2.0.0 migration (B.8.4–B.8.12) ships additive
overlays (Envoy ∥ Kong, Connect ∥ REST-bridge, Zitadel, Qwik, pg17) and a
migrate driver (`bin/forge-migrate-flagship.sh`) with a full-tree `--rollback`.
What it does **not** yet ship is the operational **runbook** that tells an
adopter, in production, *when* to roll back and *how* — step by step, per
failure mode. Three documents already forward-reference that runbook as if it
existed:

- `docs/ARCHITECTURE-TARGET.md` §11.3 lists rollback *criteria* (bullets only).
- `docs/MIGRATIONS.md:144` says verbatim: *"Rollback criteria — see B.8.13 for
  the full runbook."*
- `docs/MIGRATIONS.md:172,182` reference *"(B.8.13+)"* / *"the B.8.13 rollback
  thresholds"* as the landing point for the real-backend measurement procedure.

B.8.13 lands that runbook (`docs/ROLLBACK.md`) and closes the dangling
forward-references.

## Ground-Truth finding — §11 is B8O-stale, but the doc is sha256-pinned

`docs/ARCHITECTURE-TARGET.md` §11 still carries the orchestration model B8O
cancelled. B8O (`b8-orchestration-temporal-realign`, archived 2026-06-01, commit
56a8b7d) established **Temporal is the Rust orchestration default** — DBOS has no
Rust SDK (`orchestration.yaml` v1.2.0 `default_by_language.rust: temporal`,
`dbos.available: false`). B8O realigned the *standard* but **deliberately did not
edit ARCHITECTURE-TARGET.md** (its own design.md:18 + open-questions.md:23 record
*why*: the doc is **sha256-pinned by `t4.test.sh::_test_t4_023`** against the hash
in `.forge/changes/t4-adr-ratification/specs.md`; editing it flips that pin RED on
`main` CI and the `bin/forge-rehash-architecture-doc.sh` escape hatch is for
*non-material* edits only — its REHASH-LOG mandates "**Material edits MUST be
ratified by a fresh Forge change that supersedes parts of t4-adr-ratification**").

So §11 is B8O-stale in **six** spots — and §12.1 in a seventh:

| Location | Stale text |
|----------|-----------|
| §11.1 mermaid (`:805`) | `DBOS embedded` |
| §11.2 Phase 2 (`:832`) | "Migrer Temporal → DBOS pour workflows monorepo simples" |
| §11.2 Phase 2 risk (`:837`) | "DBOS Go SDK encore récent" |
| §11.2 Phase 3 risk (`:847`) | "maturité DBOS pour AI agents" |
| **§11.3 (`:860`)** | **"DBOS Postgres saturé > 70 % CPU → fallback à Temporal"** ← the criterion the plan strikes |
| §11.4 risk table (`:867`) | "DBOS Go SDK breaking changes" |
| §12.1 (`:930`) | `default: dbos` / `fallback: temporal` (YAML illustration) |

Removing the §11.3 criterion + realigning the Temporal→DBOS migration strategy is
a **material** edit (it changes documented architecture). Per the rehash
convention and the B8O precedent, the correct, lowest-risk move is **record-only
supersession**, not an in-place edit + re-pin (which would drag
`t4-adr-ratification`'s ratified spec into B.8.13's blast radius — re-ratification
territory, adjacent to B.8.14's lane).

## What ships

1. **`docs/ROLLBACK.md`** — a new, dedicated, **authoritative** operational
   runbook (not sha-pinned). Two scenarios (the two surviving criteria), each
   with five steps — **Detect** (B.8.12 methodology; relative deltas only),
   **Decide** (threshold), **Execute** (the exact reversal), **Verify**,
   **Re-attempt** — plus a last-resort full-tree rollback section and an explicit
   **"no DBOS / CPU-based criterion (per B8O)"** statement. It carries a
   **Supersession note** that records ARCHITECTURE-TARGET.md's seven B8O-stale
   DBOS references (table above) as **obsolete per B8O**, pointing at
   `orchestration.yaml` v1.2.0 + the B8O change as the authoritative record —
   the same record-only pattern B8O itself used.

2. **`docs/MIGRATIONS.md`** (editable — not sha-pinned) — re-point the
   `:144` forward-reference at `docs/ROLLBACK.md` (keep the short criteria
   summary; the full procedure now lives in the runbook). `:172/:182` already
   threshold-consistent — enumerated, no re-point needed.

3. **`docs/ARCHITECTURE-TARGET.md`** — **left byte-frozen** (t4 pin preserved).
   §11.3 is superseded *by record* via ROLLBACK.md, not edited in place. (A
   future non-B.8 cleanup, or B.8.14's broader doc pass, may re-pin via the
   rehash hatch; out of scope here.)

4. **`.forge/scripts/tests/b8-13.test.sh`** — L1 hermetic harness (grep/diff,
   ≤ a few seconds, no toolchain) asserting: runbook present with both scenarios
   + five steps + exact relative thresholds; **no DBOS rollback criterion in the
   runbook** (B8O); supersession note enumerates the stale refs; runbook criteria
   **byte-consistent with the embedded text in `forge-migrate-flagship.sh`**
   (`:394-396`); **no committed p50/p95/p99 number** (III.4 consistency with
   B.8.12); **ARCHITECTURE-TARGET.md sha256 UNCHANGED** (positively guards the
   frozen-pin invariant + that we did NOT break t4); forward-references resolved;
   frozen 1.0.0 templates byte-identical; CHANGELOG anchor; forge-ci
   registration; coupling guards (b8-12, b8-10, **t4**).

5. **`.github/workflows/forge-ci.yml`** — register `b8-13.test.sh --level 1`.

## Out of scope

- Editing `docs/ARCHITECTURE-TARGET.md` (sha-pinned; material DBOS realignment is
  recorded by supersession, not in-place — see above).
- Re-pinning `t4-adr-ratification`'s hash / t4 re-ratification.
- Any code change to `forge-migrate-flagship.sh` / `forge-upgrade.sh` (the
  `--rollback` mechanism already exists — B.8.10).
- The Constitution Article VIII.1/VIII.2 amendment, the schema 2.0.0
  `scaffoldable:true` flip, and the breaking removal of Kong/Temporal/REST —
  **all B.8.14** (the point of no return).
- Any committed absolute latency figure (ADR-B8-1-002 + Article III.4 Ambiguity
  Protocol / CLAUDE.md ANTI-HALLUCINATION PROTOCOL).
- Standard bumps / schema mutations / snapshot rebuilds (none — pure doc + test).

## Risks

| Risk | Mitigation |
|------|------------|
| Editing the sha-pinned arch doc silently reds `main` CI (t4) | **Do not edit it.** Record-only supersession; harness positively asserts the arch-doc sha256 is unchanged + adds `t4` to the coupling guard. |
| Scope creep into B.8.14 / t4 re-ratification | No constitution/schema/standard/sibling-spec mutation (asserted by harness + `constitution_version` guard). |
| Runbook drifts from the real `--rollback` behaviour | Runbook cites the exact `forge-migrate-flagship.sh` flags; harness greps the documented criteria against the script's embedded text (`:394-396`). |
| Fabricated latency number sneaks in | Harness asserts repo-wide absence of any committed p50/p95/p99 figure in the runbook (mirrors b8-12 `_test_b812_017`). |
| Tree stays self-contradictory (frozen §11 vs ROLLBACK.md) | Accepted, precedent-aligned (B8O did the same): the *authoritative* doc is correct + records the stale refs; the pinned narrative is superseded-by-record, not silently wrong. |
