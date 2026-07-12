# Tasks: b6-9-compliance

<!-- Status: planned (pre-implementation) -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED), write the
  artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-B69-XXX]` (Article V.1) on every task.
- `[P]` marks tasks parallelizable within the same phase.
- **Article III.4 is load-bearing** : Phase 2 carries a Demeter+Aegis review pass
  on the regulatory prose BEFORE GREEN ; `_test_b69_030` negative-grep is the
  deterministic backstop.
- ADRs from `design.md` (ADR-B69-001..007) honoured verbatim.
- Each phase ends with a **gate task** confirming counter movement AND the
  cross-impact invariants (`i6.test.sh` + `b7-5.test.sh` stay GREEN).

---

## Phase 1 — Foundation : RED harness + cross-impact verification

- [x] **T-HAR-001** : Create `.forge/scripts/tests/b6-9.test.sh` — bash header,
      source `_helpers.sh`, PASS/FAIL counters, `--level` parsing (default 1),
      audit comment, `print_summary`. Mirror `b7-5.test.sh`. [Story: FR-B69-BD-100 / FR-B69-BD-113]
- [x] **T-HAR-002** : Path variables (`NIS2_DIR`, `STD_FILE`, `I6_STD`,
      `BUNDLE_SCRIPT`, `ROI_HELPER`, `DORA_TEMPLATE`, `B75_HARNESS`, `INDEX_YML`,
      `REVIEW_MD`, `COMPLIANCE_DOC`, `CHANGELOG_MD`, canonical-surface sources). [Story: FR-B69-BD-100]
- [x] **T-HAR-003** : 17 L1 test bodies (`_test_b69_001..061`) per the `design.md`
      catalogue. [Story: FR-B69-BD-101 / FR-B69-BD-102 / FR-B69-BD-103]
- [x] **T-HAR-004** [P] : 3 L2 test bodies (`_test_b69_l2_bundle_integration`,
      `_test_b69_l2_bundle_determinism`, `_test_b69_l2_graceful_absence`). [Story: FR-B69-BD-110 / FR-B69-BD-111]
- [x] **T-HAR-005** : Test runner — iterate L1, gate L2 on `--level`, exit 0 if
      FAIL==0 else 1. [Story: FR-B69-BD-113]
- [x] **T-HAR-006** [P] : Register `b6-9.test.sh --level 1,2` in `forge-ci.yml`
      after `b7-5.test.sh` (comment noting compliance-family placement,
      ADR-B69-005). Keep < 400 lines. [Story: FR-B69-BD-112 / NFR-B69-007]
- [x] **T-XIMP-001** : Cross-impact verification — confirm `i6.test.sh` +
      `b7-5.test.sh` L2 fixtures build their own tmpdir (never read live
      `.forge/compliance/`), so creating `nis2/` will not break their counts. [Story: ADR-B69-002 / NFR-B69-001]
- [x] **T-HAR-007** : RED gate — `b6-9.test.sh --level 1,2` exits 1 (all FAIL) ;
      `i6.test.sh` / `b7-5.test.sh` / `verify.sh` / `constitution-linter.sh`
      unchanged. [Story: FR-B69-BD-113]

---

## Phase 2 — NIS2 artefacts + DORA helper + b7-5 lock-step (anti-hallucination gated)

- [x] **T-NIS2-001** : RED witness — `_test_b69_001..012` + `_030` FAIL. [Story: FR-B69-NIS2-001..030]
- [x] **T-NIS2-002** : Create `.forge/compliance/nis2/incident-reporting.md` —
      grounded 24h/72h + < 24h figures verbatim, event-stack operational
      scenarios (NATS/Temporal/Postgres), evidence surfaces (audit-ledger + IX.4
      OTel), Q-001 `[NEEDS CLARIFICATION]`. [Story: FR-B69-NIS2-010 / FR-B69-NIS2-011]
- [x] **T-NIS2-003** [P] : Create `.forge/compliance/nis2/incident-report.template.yaml`
      — 24h/72h skeleton, `<FILL:>`, Q-001 marker. [Story: FR-B69-NIS2-012]
- [x] **T-NIS2-004** : Create `.forge/compliance/nis2/obligations-index.yaml` —
      2 grounded (`incident-reporting`, `supply-chain-security`) + 2
      needs-clarification (themis K.5). [Story: FR-B69-NIS2-013 / FR-B69-SBOM-010]
- [x] **T-NIS2-005** : Add the `<!-- Audit: B.6.9 (b6-9-compliance) -->` anchor to
      every nis2 member. [Story: FR-B69-NIS2-002]
- [x] **T-DORA-001** : Create `.forge/scripts/compliance/dora-roi-helper.sh` —
      reads the b7-5 dora RoI base, emits stack-specialised RoI (NATS/Temporal/
      Postgres), Q-002 marker, grounded 30 avr 2026, exit codes. [Story: FR-B69-DORA-001 / FR-B69-DORA-010 / FR-B69-DORA-020]
- [x] **T-LOCK-001** : Amend `b7-5.test.sh::_test_b75_001` — drop the two
      `nis2/`-reserved lines, keep the `cra/`-reserved lines (ADR-B69-006). [Story: FR-B69-BD-130]
- [x] **T-REV-001** : **Demeter + Aegis review pass** — confirm every legal
      specific is grounded OR inside a `[NEEDS CLARIFICATION]` marker
      (NFR-B69-004). Writer ≠ reviewer. [Story: NFR-B69-004]
- [x] **T-P2-GREEN** : `b6-9.test.sh --level 1` — `_test_b69_001..021` + `_030` +
      `_053` GREEN. Re-run `b7-5.test.sh --level 1,2` GREEN (lock-step verified). [Story: FR-B69-BD-102 / FR-B69-BD-130]

---

## Phase 3 — Standard + bundle wiring (I.6 lock-step)

- [x] **T-STD-001** : RED witness — `_test_b69_040..042` FAIL. [Story: FR-B69-BD-020..027]
- [x] **T-STD-002** : Create `.forge/standards/global/nis2-dora-eda-artefacts.md`
      — H1 + audit + trigger comments ; frontmatter (1.0.0, 2026-07-10) ; 6 H2 ;
      SBOM-wiring section ; ≥ 3 MUST NOT ; Themis cross-link ; Constitutional
      Compliance. [Story: FR-B69-BD-020..027 / FR-B69-SBOM-001]
- [x] **T-STD-003** : GREEN witness — `_test_b69_040..042` GREEN. [Story: FR-B69-BD-022]
- [x] **T-BND-001** : RED witness — `_test_b69_051..052` + L2 bundle tests FAIL. [Story: FR-B69-BD-001..004]
- [x] **T-BND-002** : Extend `bundle.sh` — add `"nis2"` to the walk tuple ;
      update the header member-list comment. Touch NOTHING else. [Story: FR-B69-BD-001 / FR-B69-BD-002 / FR-B69-BD-004]
- [x] **T-I6-001** : Amend `compliance-artefacts-bundle.md` — `regulatory/nis2/*`
      schema row ; bump 1.1.0 → 1.2.0 + refresh dates ; reserved prose (NIS2
      shipped / CRA reserved) ; Interdiction #3 amended. [Story: FR-B69-BD-010 / FR-B69-BD-011]
- [x] **T-I6-002** : Confirm `i6.test.sh` stays GREEN (hermetic per T-XIMP-001). [Story: NFR-B69-001]
- [x] **T-IDX-001** : Append the `global/nis2-dora-eda-artefacts` entry to
      `index.yml` under a new `# ─── B.6.9 …` section header. [Story: FR-B69-BD-030]
- [x] **T-RVW-001** : Append the REVIEW.md H2
      `## 2026-07-10 — Initial ratification (b6-9-compliance, B.6.9)` recording
      the new standard `1.0.0 KEEP` + the `compliance-artefacts-bundle.md`
      `1.1.0 → 1.2.0` amendment. [Story: FR-B69-BD-031]
- [x] **T-P3-GREEN** : GREEN witness — `_test_b69_050..052` GREEN. [Story: FR-B69-BD-010 / FR-B69-BD-030]

---

## Phase 4 — Docs + stale-prose lock-step

- [x] **T-DOC-001** : Add `docs/COMPLIANCE.md` H2 `## Regulatory artefacts (NIS2 +
      DORA event-driven)` (after the b7-5 AI-Act H2), cross-linking the nis2 dir
      + the helper + the standard + the bundle `regulatory/nis2/`. [Story: FR-B69-BD-120]
- [x] **T-DOC-002** : Fix the stale "NIS2 reserved" prose — `docs/COMPLIANCE.md`
      b7-5 section (line ~212) + `ai-act-dora-artefacts.md` (§ Purpose + § Themis
      cross-link) → NIS2 shipped via B.6.9, CRA reserved. [Story: FR-B69-BD-131]
- [x] **T-DOC-003** : GREEN witness — `_test_b69_060` GREEN. [Story: FR-B69-BD-120]
- [x] **T-LOG-001** : Add `CHANGELOG.md [Unreleased]` `### Added` entry
      (b6-9-compliance NIS2 + DORA event-driven compliance hooks). [Story: FR-B69-BD-121]
- [x] **T-LOG-002** : GREEN witness — `_test_b69_061` GREEN. [Story: FR-B69-BD-121]
- [ ] **T-INV-001** [P] : Update `docs/new-archetypes-plan.md` B.6.9 row + §11
      table + `.forge/product/roadmap.md`. **DEFERRED (intentionally
      unchecked)** — separate maintainer resync, collision avoidance across the
      6 in-flight B.6 PRs (mirrors b7-5 T-INV). [Story: N/A — deferred]

---

## Phase 5 — L2 fixtures + final gates

- [x] **T-L2-001** : Implement `_test_b69_l2_bundle_integration`. [Story: FR-B69-BD-110]
- [x] **T-L2-002** : Implement `_test_b69_l2_bundle_determinism`. [Story: FR-B69-BD-110 / NFR-B69-002]
- [x] **T-L2-003** : Implement `_test_b69_l2_graceful_absence`. [Story: FR-B69-BD-111]
- [x] **T-L2-GREEN** : `b6-9.test.sh --level 1,2` — all GREEN, exit 0. [Story: FR-B69-BD-113]
- [x] **T-GAT-001** : `bash .forge/scripts/verify.sh` — overall PASS (Failed=0). [Story: NFR-B69-001]
- [x] **T-GAT-002** : `bash .forge/scripts/tests/i6.test.sh --level 1,2` — GREEN. [Story: NFR-B69-001]
- [x] **T-GAT-003** : `bash .forge/scripts/tests/b7-5.test.sh --level 1,2` — GREEN
      (lock-step, no regression). [Story: NFR-B69-001 / FR-B69-BD-130]
- [x] **T-GAT-004** : `bash .forge/scripts/constitution-linter.sh` — OVERALL PASS. [Story: NFR-B69-004]
- [x] **T-GAT-005** : `bash bin/validate-standards-yaml.sh` — GREEN (new standard
      is MD, out of scope). [Story: NFR-B69-001]
- [x] **T-GAT-006** : `wc -l .github/workflows/forge-ci.yml` < 400. [Story: NFR-B69-007]
- [x] **T-GAT-007** : Status flip `.forge.yaml` → `implemented` ; timeline. [Story: Article V]

---

## Task summary

| Phase | Tasks | Notes |
|-------|-------|-------|
| 1 | 8 | RED harness + 20 tests + CI reg + cross-impact verification. |
| 2 | 9 | NIS2 artefacts (3) + DORA helper + **b7-5 lock-step** + Demeter+Aegis review + negative-grep GREEN. |
| 3 | 10 | New standard + additive `bundle.sh` + **I.6 standard 1.1.0→1.2.0 lock-step** + index + REVIEW. |
| 4 | 6 | docs/COMPLIANCE.md H2 + stale-prose fix + CHANGELOG (plan/roadmap deferred). |
| 5 | 10 | L2 bundle integration/determinism/graceful-absence + final gates incl. i6 + b7-5 GREEN. |
| **Total** | **43** | Immutable RED→GREEN→REFACTOR ; Article III.4 grounded-or-deferred ; I.6 contract 1.1.0→1.2.0 + b7-5 harness amended in lock-step. |

## Anti-hallucination checklist (Article III.4 — re-verify before archive)

- [x] No NIS2/DORA Article number, recital, or precise date in any artefact that
      is NOT traceable to a cited repo source OR inside a `[NEEDS CLARIFICATION]`
      marker (`_test_b69_030` negative-grep GREEN).
- [x] Every `obligations-index.yaml` `status: satisfied` entry names a concrete
      Forge evidence surface.
- [x] Every legal question the repo cannot answer is a `[NEEDS CLARIFICATION]`
      tagged "Themis (K.5)".
- [x] Context7 was NOT used for legal text.
