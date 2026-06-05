# Tasks: b8-14-promotion-flip

**Status**: planned → 2026-06-05 · Constitution 1.1.0 → v2.0.0
THE POINT OF NO RETURN. Two ordered commits (ratify → enable). Independent review
before approval (no self-approval).

## Commit 1 — Ratification + governance
- [ ] T-001 REVIEW.md BDFL-waiver Correction Entry (opened 2026-06-04, ratified
      2026-06-05, ~1 day, BDFL authority, rationale). [Story: FR-FLIP-001]
- [ ] T-002 Amend `.forge/constitution.md`: §VIII.1 Kong→Envoy/Connect; Amendments
      row #2 (waiver callout); `**Version**: v2.0.0`; effective-date line.
      [Story: FR-FLIP-002]
- [ ] T-003 Bump constitution_version "1.1.0"→"2.0.0" in TEMPLATES only
      (change.yaml 2×, full-stack-monorepo + mobile-only .forge.yaml.tmpl). Leave
      the 46 historical change files at 1.1.0. [Story: FR-FLIP-003]
- [ ] T-004 Invert `d5.test.sh` _012 (v2.0.0 + amendment row #2) + _013 (templates
      "2.0.0"; d5 own .forge.yaml stays 1.0.0). Run d5 → GREEN. [Story: FR-FLIP-004]
- [ ] T-005 CHANGELOG `### BREAKING` (constitution v2.0.0, Kong→Envoy; framework
      stays 0.4.0 pre-GA) + `### Deprecated` (1.0.0 EOL 2026-12-05) + VERSIONING
      support note. [Story: FR-FLIP-005/008]
- [ ] T-006 Rewrite ARCHITECTURE-TARGET §11/§12.1 (DBOS→Temporal, Kong→Envoy);
      run `bin/forge-rehash-architecture-doc.sh`; confirm REHASH-LOG + t4 _023
      GREEN. Record t4 supersession in REVIEW. [Story: FR-FLIP-006]
- [ ] T-007 kong.md → tombstone-redirect (gateway.yaml + transport.yaml); remove
      the standards/index.yml kong entry. Run j7 → GREEN. [Story: FR-FLIP-007]
- [ ] T-008 Retire b8-14.test.sh held-guards → flip positive assertions
      (constitution v2.0.0 + §VIII.1 Envoy; row #2). Run b8-14 → GREEN.
      [Story: FR-FLIP-002]
- [ ] T-009 **C1 gate**: d5 + t4 + j7 + b8-14 + constitution-linter + verify.sh
      GREEN. Commit `feat(b8-14-flip)` C1 (ratification). [Story: FR-FLIP-031]

## Commit 2 — Enablement (net-new code, RED-first)
- [ ] T-020 Write `.forge/scripts/tests/b8-14-flip.test.sh` (RED): fresh 2.0.0
      scaffold Kong-less + Envoy/Connect present; selection guard refuses
      scaffoldable:false; constitution v2.0.0 + §VIII.1 Envoy. Register in
      forge-ci.yml array. Verify RED. [Story: FR-FLIP-023]
- [ ] T-021 Promote `2.0.0.yaml` (stage stable + scaffoldable:true; reword
      prohibition block). Invert b8-3.test.sh _006 (scaffoldable==true).
      [Story: FR-FLIP-020]
- [ ] T-022 New `scaffold-plan-2.0.0.yaml` (omits Kong) + `forge-init-fsm-2.0.0`
      path + `dispatch-table.yml` 2.0.0 entry (Kong-less composition). NEVER edit
      the frozen 1.0.0 plan/snapshot. [Story: FR-FLIP-021]
- [ ] T-023 `cli/src`: versioned-schema selection (highest stable+scaffoldable) +
      runtime `scaffoldable:false` refusal guard. Run cli vitest. [Story: FR-FLIP-022]
- [ ] T-024 Verify GREEN: b8-14-flip.test.sh passes (Kong-less scaffold + guard).
      [Story: FR-FLIP-023]
- [ ] T-025 Activate b8-15.test.sh _005 (front-door 2.0.0 + Kong-removal-in-fresh-
      scaffold cells); KEEP line-225 migrate additive assertion. 2.0.0 README
      wording. [Story: FR-FLIP-024]
- [ ] T-026 `npm run bundle` (regen cli/assets). [Story: FR-FLIP-025]
- [ ] T-027 **C2 gate**: full 53-harness suite + verify.sh + constitution-linter
      OVERALL PASS; b8-12 + b8-15 line-225 STILL green (migrate additive).
      [Story: FR-FLIP-030/031]

## Quality gate + archive
- [ ] T-030 Independent implementation review (re-execute suite live; verify Kong-
      less scaffold, additive migrate untouched, honest waiver, no fabrication).
      APPROVE. [Story: NFR-003]
- [ ] T-031 Flip `.forge.yaml` → implemented; post-flip gate.
- [ ] T-032 Archive: spec → `.forge/specs/`; status archived; plan §0.0 + §4.2
      (B.8.14 FLIP done, B.8 COMPLETE) + roadmap T6; memory update.
- [ ] T-033 Commit `feat(b8-14-flip)` C2 (enablement) + push.

## Constitutional compliance
- Ratify (C1) precedes removal (C2) — ordering auditable.
- BDFL waiver recorded honestly (no fabricated window).
- Only templates bump constitution_version; historical changes stay 1.1.0.
- migrate-flagship additive forever; frozen 1.0.0 untouched.
- TDD: T-020 RED before T-023 GREEN. Independent review before approval.
