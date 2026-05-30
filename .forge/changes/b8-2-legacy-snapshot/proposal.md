# Proposal: b8-2-legacy-snapshot

<!-- Created: 2026-05-30 -->
<!-- Schema: default -->
<!-- Audit: B.8.2 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0 migration, legacy snapshot freeze) -->

## Problem

B.8 migrates `full-stack-monorepo / 1.0.0` → `2.0.0` (the point of no return,
§4). For `forge upgrade` to offer adopters a **reverse** path (stay on / roll
back to 1.0.0), the 1.0.0 scaffold must survive as an immutable BASE after
2.0.0 templates land. Plan §4.2 B.8.2 phrases this as "snapshot tarball
archived definitively in `.forge/scaffold-snapshots/legacy/`".

**Ground truth (verified 2026-05-30):** the A.7 mechanism already keys
snapshots by version, not by a `legacy/` dir. `forge-upgrade.sh:279` recovers
BASE from `.forge/scaffold-snapshots/<archetype>/<from_version>.tar.gz`, and
`full-stack-monorepo/1.0.0.tar.gz` (650.8 KB) already exists and is exercised
by `a7.test.sh` (FR-UP-008 present/extractable/BASE-recovery). So the reverse
target path is **already correct**; the plan's `legacy/` is terminology, not a
new location.

The real gap is **immutability**. The snapshot is rebuilt by
`bin/forge-snapshot.sh build <archetype> <version>` on changes that touch
owned paths — it has been regenerated through rc.1→rc.6 (the B.8.8 obs trio
changed templates while keeping schema 1.0.0). Once 2.0.0 templates land,
nothing stops an accidental `forge-snapshot.sh build full-stack-monorepo
1.0.0` from overwriting the 1.0.0 tarball with 2.0.0 content — silently
destroying the only reverse target at the exact moment it matters most.

## Solution

**Freeze the current 1.0.0-final snapshot in place** (do not move it, do not
rebuild it) and make any future drift tamper-evident.

1. **Do NOT rebuild** the tarball. The committed
   `full-stack-monorepo/1.0.0.tar.gz` already reflects the 1.0.0-final
   templates (post-obs-trio, rc.6). Rebuilding would change bytes
   (`SOURCE_DATE_EPOCH` = HEAD timestamp) for no semantic gain. Freeze what
   exists.
2. **Integrity manifest** — commit
   `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` capturing the
   sha256 of the frozen tarball, so the reverse target is provable +
   tamper-evident.
3. **Immutability guard** — new harness `b8-2.test.sh` asserts the committed
   tarball's sha256 equals the committed manifest. It FAILS if `1.0.0.tar.gz`
   is ever rebuilt/corrupted (e.g. accidentally rebuilt with 2.0.0 templates).
   This is the actual protection for the point of no return.
4. **Freeze policy** — document (in `global/upgrade-policy.md` and/or
   `docs/B8-BASELINE.md`) that 1.0.0 enters **maintenance-freeze** at B.8.2:
   no further 1.0.0 template edits (all changes go to 2.0.0); the 2.0.0
   snapshot MUST build to `2.0.0.tar.gz` (a new file), never overwrite
   1.0.0. A deliberate, audited 1.0.0 security patch may update both tarball
   and manifest together (the guard catches *accidental* drift, not audited
   bumps).

Decisions reserved for `/forge:design` (ADRs):

- **ADR-1** — `legacy/` dir vs version-keyed path. Lean: **keep the
  version-keyed `full-stack-monorepo/1.0.0.tar.gz`** (forge-upgrade reads it;
  introducing `legacy/` would require an A.7 change = scope creep + breaks the
  established BASE-recovery contract). Reconcile the plan's wording in the doc.
- **ADR-2** — manifest format/location: sibling `.sha256` file vs a richer
  `1.0.0.manifest.yaml` (sha + byte size + frozen-at commit + source schema).
  Lean: sibling `.sha256` (simplest, greppable), optionally a 1-line frozen-at
  note.
- **ADR-3** — freeze-policy home: extend `global/upgrade-policy.md` vs a new
  standard. Lean: extend `upgrade-policy.md` (A.7 owns it) — but that is a
  standard bump, so it crosses NFR scope; confirm whether to keep it doc-only
  (`docs/B8-BASELINE.md` §) to stay zero-standard like B.8.1, or accept a
  scoped `upgrade-policy.md` minor bump.
- **ADR-4** — flagship-only vs also freeze `mobile-only/1.0.0.tar.gz`. Lean:
  flagship-only (plan §4.2); mobile freeze is B.9 territory.

Release vehicle: **v0.4.0-rc.7** (maintainer-set). Additive, reversible.

## Scope In

- Integrity manifest for `full-stack-monorepo/1.0.0.tar.gz` (sha256).
- New harness `b8-2.test.sh` (immutability/tamper guard + tarball
  present/extractable re-assert), registered in `forge-ci.yml` (≤ 300 lines).
- Freeze-policy documentation (location per ADR-3).
- CHANGELOG `[Unreleased]` entry.
- Consolidated spec `.forge/specs/b8-legacy-snapshot.md` (`FR-B8-2-*`).

## Scope Out (Explicit Exclusions)

- **Rebuilding the tarball** — explicitly NOT done (would churn bytes via SDE
  for no gain). Freeze the existing artifact.
- **`forge-upgrade.sh` changes** — the BASE-recovery path is already correct.
- **A `legacy/` directory** — rejected unless ADR-1 overturns the lean.
- **2.0.0 snapshot** — B.8.x once 2.0.0 templates exist (B.8.3+).
- **Schema 2.0.0 candidate** — B.8.3.
- **`mobile-only/1.0.0` freeze** — B.9.
- **Any 1.0.0 template/standard edit** — the change freezes 1.0.0; it does not
  modify it.

## Impact

- **Users affected**: B.8 migration architects + 1.0.0 adopters who will rely
  on `forge upgrade` reverse. No scaffold change for current adopters.
- **Technical impact**: one manifest file + one harness + CI registration +
  doc. Possibly a scoped `upgrade-policy.md` bump (ADR-3). Near-zero risk.
- **Dependencies**: none upstream. Sibling to B.8.1 (baseline doc). Downstream:
  B.8.15 (upgrade matrix test) relies on the frozen 1.0.0 BASE;
  B.8.12/B.8.13 cite it as the rollback artifact.

## Constitution Compliance

- **Article I (TDD)**: `b8-2.test.sh` written RED-first (guard fails before the
  manifest exists / on a deliberately corrupted copy), GREEN once the manifest
  is committed.
- **Article II (BDD)**: no user-facing runtime feature; guard behavior
  documented in the harness comment.
- **Article III.4 (Anti-Hallucination)**: the sha256 is computed from the live
  committed tarball, never assumed; the `legacy/`-vs-version-keyed reconciliation
  is grounded in `forge-upgrade.sh:279`, not the plan's wording.
- **Article IV/V (audit trail + compliance gate)**: additive; the freeze is an
  auditable, reversible record.
- **Article XII (Governance)**: no constitutional amendment; if ADR-3 picks the
  `upgrade-policy.md` bump it is an additive standard minor with a REVIEW.md
  ledger entry.

## Open Questions (seed)

- **Q-001** — `legacy/` vs version-keyed path (→ ADR-1).
- **Q-002** — manifest format (→ ADR-2).
- **Q-003** — freeze-policy doc-only vs `upgrade-policy.md` bump (→ ADR-3).
- **Q-004** — flagship-only vs also mobile-only (→ ADR-4).
