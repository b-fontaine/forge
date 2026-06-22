# Tasks: b7-5-ai-act

<!-- Status: planned (pre-implementation) -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED), write the
  artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-B75-XXX]` (Article V.1, enforced by
  `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the **same phase**.
- **Article III.4 is load-bearing** : Phase 2 carries a mandatory Demeter+Aegis
  review pass on the regulatory prose BEFORE the artefacts go GREEN; the
  negative-grep guard (`_test_b75_030`) is the deterministic backstop.
- ADRs from `design.md` (ADR-B75-001..005) honoured verbatim; deviations require
  a new ADR.
- Each phase ends with a **gate task** running `b7-5.test.sh` (+ `i6.test.sh` /
  `verify.sh` / `constitution-linter.sh` where relevant) confirming counter
  movement AND the I.6 cross-impact invariant (i6 stays GREEN).

---

## Phase 1 — Foundation : RED harness + I.6 cross-impact verification

Goal : `b7-5.test.sh` exists with ≥ 14 L1 + 3 L2 stubs all FAIL; I.6 hermeticity
confirmed; CI registration done.

### T-HAR — harness skeleton

- [ ] **T-HAR-001** : Create `.forge/scripts/tests/b7-5.test.sh` — bash header
      (`#!/usr/bin/env bash`, `set -uo pipefail`), source `_helpers.sh`,
      PASS/FAIL counters, `--level 1|2|1,2|all` parsing (default 1), audit
      comment `# Audit: B.7.5+B.7.8 (b7-5-ai-act)`, `print_summary` close-out.
      Mirror the `i6.test.sh` layout. [Story: FR-B75-BD-100 / FR-B75-BD-113]
- [ ] **T-HAR-002** : Define path variables : `AIACT_DIR`
      (`.forge/compliance/ai-act`), `DORA_DIR` (`.forge/compliance/dora`),
      `STD_FILE` (`global/ai-act-dora-artefacts.md`), `I6_STD`
      (`global/compliance-artefacts-bundle.md`), `BUNDLE_SCRIPT`, `INDEX_YML`,
      `REVIEW_MD`, `COMPLIANCE_DOC`, `CHANGELOG_MD`. [Story: FR-B75-BD-100]
- [ ] **T-HAR-003** : Add ≥ 14 L1 stubs (`_test_b75_001..061`) all
      `_not_implemented`, per the `design.md` L1 catalogue. [Story: FR-B75-BD-101 / FR-B75-BD-102]
- [ ] **T-HAR-004** [P] : Add 3 L2 stubs (`_test_b75_l2_bundle_integration`,
      `_test_b75_l2_bundle_determinism`, `_test_b75_l2_graceful_absence`) all
      `_not_implemented`. [Story: FR-B75-BD-110 / FR-B75-BD-111]
- [ ] **T-HAR-005** : Test runner — iterate L1, gate L2 on `--level`, exit 0 if
      FAIL==0 else 1. [Story: FR-B75-BD-113]
- [ ] **T-HAR-006** [P] : Register `b7-5.test.sh --level 1,2` in
      `forge-ci.yml` `harness` matrix immediately after `i5.test.sh`; add a
      one-line comment noting the intentional b7-in-i-block placement
      (ADR-B75-004). Keep file < 300 lines. [Story: FR-B75-BD-112 / NFR-B75-007]
- [ ] **T-XIMP-001** : **I.6 cross-impact verification** — read
      `i6.test.sh::_test_i6_l2_bundle_good` + `_setup_l2`; CONFIRM the i6 L2
      fixture `cp`s named surfaces into a tmpdir and never reads the live
      `.forge/compliance/` tree (so its `wc -l == 6` assertion is immune to the
      new artefacts). If it is NOT hermetic, record a deviation ADR and make the
      i6 count assertion variable in THIS change. [Story: ADR-B75-002 / NFR-B75-001]
- [ ] **T-HAR-007** : RED gate — `b7-5.test.sh --level 1,2` exits 1
      (all FAIL); `i6.test.sh --level 1,2`, `verify.sh`, `constitution-linter.sh`
      unchanged. [Story: FR-B75-BD-113]

### Phase 1 exit gate

`b7-5.test.sh --level 1,2` exits 1, all FAIL. `forge-ci.yml` updated, < 300
lines. I.6 hermeticity confirmed. `i6.test.sh` / `verify.sh` /
`constitution-linter.sh` unchanged.

---

## Phase 2 — Regulatory artefacts (AI-Act + DORA) — anti-hallucination gated

Goal : the 6 ai-act + 3 dora members ship, each grounded-or-flagged; the
artefact L1 tests + the negative-grep guard flip GREEN. **No legal content
invented.**

### T-AA — AI-Act artefacts

- [ ] **T-AA-001** : RED witness — confirm `_test_b75_001..013` + `_030` FAIL.
      [Story: FR-B75-AA-001..030]
- [ ] **T-AA-002** : Create `.forge/compliance/ai-act/risk-classification.md`
      per the `design.md` content shape : grounded transparency posture
      (cite §10.3 + llm-gateway.md), escalation triggers, the Q-001 + Q-003
      `[NEEDS CLARIFICATION]` markers verbatim. [Story: FR-B75-AA-010 / FR-B75-AA-011]
- [ ] **T-AA-003** [P] : Create
      `.forge/compliance/ai-act/transparency-obligations.md` — obligations +
      the obligation→evidence table (Qwik `fallbackUsed` FR-B7-2-020; IX.6
      prompt-audit). [Story: FR-B75-AA-012]
- [ ] **T-AA-004** [P] : Create
      `.forge/compliance/ai-act/model-card.template.md` +
      `dataset-card.template.md` — adopter-fillable skeletons (DPA-template
      pattern), Q-004 `[NEEDS CLARIFICATION]` on the bias-eval Article in the
      header; no legal duty asserted. [Story: FR-B75-AA-020 / FR-B75-AA-021]
- [ ] **T-AA-005** : Create `.forge/compliance/ai-act/obligations-index.yaml`
      per the `design.md` YAML : two grounded obligations (transparency,
      logging) `satisfied` + concrete `satisfied_by`; ungrounded
      (conformity-assessment, post-market-monitoring) `needs-clarification` +
      `themis_owner: K.5`. [Story: FR-B75-AA-025 / FR-B75-AA-026]
- [ ] **T-AA-006** : Add the `<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->` anchor
      to every ai-act member. [Story: FR-B75-AA-002]

### T-DO — DORA artefacts

- [ ] **T-DO-001** : RED witness — confirm `_test_b75_020..022` FAIL.
      [Story: FR-B75-DO-001..020]
- [ ] **T-DO-002** : Create `.forge/compliance/dora/incident-reporting.md` —
      grounded obligation (cite the "< 24h" charter figure §9.2 + RoI "30 avr
      2026" §10.4 verbatim), obligation→evidence (I.6 audit-ledger + IX.6
      prompt-audit), the Q-002 `[NEEDS CLARIFICATION]` for the precise DORA
      windows. [Story: FR-B75-DO-010 / FR-B75-DO-011]
- [ ] **T-DO-003** [P] : Create
      `.forge/compliance/dora/roi-register.template.yaml` — adopter-fillable
      RoI skeleton; Q `[NEEDS CLARIFICATION]` for the authoritative field
      schema. [Story: FR-B75-DO-015]
- [ ] **T-DO-004** [P] : Create
      `.forge/compliance/dora/obligations-index.yaml` (`regulation: dora`) —
      grounded incident-reporting + RoI entries; ungrounded pillars flagged.
      [Story: FR-B75-DO-016]
- [ ] **T-DO-005** : Add the audit anchor to every dora member.
      [Story: FR-B75-DO-002]

### T-REV — anti-hallucination review pass (MANDATORY before GREEN)

- [ ] **T-REV-001** : **Demeter + Aegis review pass** on every artefact :
      confirm every legal specific is either traceable to a cited repo source OR
      inside a `[NEEDS CLARIFICATION]` marker (NFR-B75-004 / Article III.4). Fix
      any ungrounded assertion (downgrade to a marker). This is a separate
      review lane (writer ≠ reviewer). [Story: NFR-B75-004]
- [ ] **T-AA-DO-GREEN** : GREEN witness — `b7-5.test.sh --level 1` ; expect
      `_test_b75_001..022` + `_030` (negative-grep) flip GREEN. The negative-grep
      test (`_test_b75_030`) is the deterministic backstop for T-REV-001.
      [Story: FR-B75-BD-102]

### Phase 2 exit gate

10 of 16 L1 GREEN (2 dir + 8 artefact + negative-grep ... per catalogue). The
negative-grep guard GREEN proves no fabricated citation. `i6.test.sh` /
`verify.sh` / `constitution-linter.sh` unchanged.

---

## Phase 3 — Standard + bundle wiring (I.6 lock-step)

Goal : the standard ships; `bundle.sh` collects regulatory members; the I.6
standard + tests are amended in lock-step; standard + bundle-schema L1 tests
flip GREEN.

### T-STD — new standard

- [ ] **T-STD-001** : RED witness — `_test_b75_040..041` FAIL.
      [Story: FR-B75-BD-020..027]
- [ ] **T-STD-002** : Create `.forge/standards/global/ai-act-dora-artefacts.md`
      — H1 + audit + trigger comments; frontmatter (version 1.0.0, last_reviewed
      2026-06-22, expires_at 2027-06-22); 6 H2 (Purpose & EU regulatory scope ;
      Artefact content schema [table] ; Obligation → evidence traceability ;
      Governance — two phases BDFL→Themis ; Consumption protocol [I.6 bundle
      `regulatory/`] ; Interdictions [≥ 3 MUST NOT incl. the no-fabrication
      clause]) ; Themis cross-link ; `## Constitutional Compliance`.
      [Story: FR-B75-BD-020..027]
- [ ] **T-STD-003** : GREEN witness — `_test_b75_040..041` GREEN.
      [Story: FR-B75-BD-022]

### T-BND — bundle wiring (additive)

- [ ] **T-BND-001** : RED witness — `_test_b75_051` + the L2 bundle tests FAIL.
      [Story: FR-B75-BD-001..004]
- [ ] **T-BND-002** : Extend `.forge/scripts/compliance/bundle.sh` : in the
      Python inline block, after the 5 static members are assembled
      (`bundle.sh:358`), walk `<target>/.forge/compliance/ai-act/` +
      `dora/` and add each file to `members` keyed `regulatory/ai-act/<name>` /
      `regulatory/dora/<name>`. Graceful absence (FR-B75-BD-004) : skip silently
      if a dir is absent. Touch NOTHING else (MANIFEST loop, gzip idiom, tar
      loop all consume `sorted(members.keys())` unchanged).
      [Story: FR-B75-BD-001 / FR-B75-BD-002 / FR-B75-BD-004]
- [ ] **T-BND-003** : Update the `bundle.sh` header member-list comment
      (`:8-13`) to add the `regulatory/{ai-act,dora}/*` members (kept accurate
      per the I.6 convention). [Story: FR-B75-BD-001]

### T-I6 — I.6 standard + tests lock-step amendment

- [ ] **T-I6-001** : Amend
      `.forge/standards/global/compliance-artefacts-bundle.md` : add
      `regulatory/ai-act/*` + `regulatory/dora/*` rows to the `## Bundle content
      schema` table; change "exactly 6 members" prose to "6 base + N regulatory";
      bump `version: 1.0.0 → 1.1.0`, refresh `last_reviewed`/`expires_at`; update
      the FR-I6-CA-053 forward-compat sentence to record the B.7.5/B.7.8 v1.1.0
      expansion (NIS2/CRA still reserved). [Story: FR-B75-BD-010 / FR-B75-BD-011]
- [ ] **T-I6-002** : Confirm `i6.test.sh` stays GREEN (the L2 count assertion is
      hermetic per T-XIMP-001). If T-XIMP-001 found it non-hermetic, update the
      i6 count assertion to be member-count-variable HERE (single lock-step
      edit). [Story: NFR-B75-001]
- [ ] **T-BND-GREEN** : GREEN witness — `_test_b75_051` (i6 standard amended)
      flips GREEN. [Story: FR-B75-BD-010]

### T-IDX — index + REVIEW

- [ ] **T-IDX-001** : Append the `global/ai-act-dora-artefacts` entry to
      `index.yml` under a new `# ─── B.7.5/B.7.8 …` section header, 9 triggers,
      scope all, priority high. [Story: FR-B75-BD-030]
- [ ] **T-RVW-001** : Append the REVIEW.md H2
      `## 2026-06-22 — Initial ratification (b7-5-ai-act, B.7.5 + B.7.8)`
      recording the new standard `1.0.0 KEEP` + the
      `compliance-artefacts-bundle.md` `1.0.0 → 1.1.0` amendment.
      [Story: FR-B75-BD-031]
- [ ] **T-IDX-GREEN** : GREEN witness — `_test_b75_050` GREEN.
      [Story: FR-B75-BD-030 / FR-B75-BD-031]

### Phase 3 exit gate

14 of 16 L1 GREEN. `bundle.sh` extended. I.6 standard 1.1.0 + REVIEW.md amended.
`i6.test.sh` GREEN (count unbroken). `verify.sh` / `constitution-linter.sh`
unchanged. Only the 2 docs L1 + the 3 L2 tests remain.

---

## Phase 4 — Docs + inventory

- [ ] **T-DOC-001** : Add `docs/COMPLIANCE.md` H2 `## Regulatory artefacts
      (AI Act + DORA)` after `## Auditor hand-off bundle`, cross-linking the
      artefacts dir + the standard + the bundle `regulatory/` subdirectory,
      noting Themis-Phase-B governance for the `[NEEDS CLARIFICATION]` items.
      [Story: FR-B75-BD-120]
- [ ] **T-DOC-002** : GREEN witness — `_test_b75_060` GREEN. [Story: FR-B75-BD-120]
- [ ] **T-LOG-001** : Add `CHANGELOG.md [Unreleased]` entry `### Added — B.7.5
      + B.7.8 AI-Act + DORA regulatory artefacts (b7-5-ai-act)` (artefacts +
      standard + bundle 1.1.0 + harness). [Story: FR-B75-BD-122]
- [ ] **T-LOG-002** : GREEN witness — `_test_b75_061` GREEN. [Story: FR-B75-BD-122]
- [ ] **T-INV-001** [P] : Update `docs/new-archetypes-plan.md` rows B.7.5 +
      B.7.8 (§6.2) Done; §0.12 line 2024 brick #6 flipped; §2760 T7 line moves
      the brick to "livrées". All cite `b7-5-ai-act`. [Story: FR-B75-BD-121]
- [ ] **T-INV-002** [P] : Update `.forge/product/roadmap.md` inventory line.
      [Story: FR-B75-BD-122]

### Phase 4 exit gate

16 of 16 L1 GREEN. Plan/roadmap/CHANGELOG recorded. L2 tests remain.

---

## Phase 5 — L2 fixtures + final gates

- [ ] **T-L2-001** : Implement `_test_b75_l2_bundle_integration` — synthetic
      tmpdir (4 I.6 surfaces + the regulatory artefacts); run `bundle.sh`;
      assert the `.tgz` carries `regulatory/ai-act/*` + `regulatory/dora/*` +
      the 6 base members + a sorted MANIFEST listing all.
      [Story: FR-B75-BD-110 / FR-B75-BD-001 / FR-B75-BD-002]
- [ ] **T-L2-002** : Implement `_test_b75_l2_bundle_determinism` — run the
      extended bundle twice with `SOURCE_DATE_EPOCH=0`; `diff -q` byte-identical.
      [Story: FR-B75-BD-110 / FR-B75-BD-003 / NFR-B75-002]
- [ ] **T-L2-003** : Implement `_test_b75_l2_graceful_absence` — tmpdir WITHOUT
      `.forge/compliance/{ai-act,dora}/`; `bundle.sh` exits 0 with base 6
      members only. [Story: FR-B75-BD-111 / FR-B75-BD-004]
- [ ] **T-L2-GREEN** : `b7-5.test.sh --level 1,2` — all GREEN, exit 0.
      [Story: FR-B75-BD-113]

### T-GAT — final gates

- [ ] **T-GAT-001** : `bash .forge/scripts/verify.sh` — overall PASS (additive;
      no regression; Failed = 0; Passed ≥ prior baseline). [Story: NFR-B75-001]
- [ ] **T-GAT-002** : `bash .forge/scripts/tests/i6.test.sh --level 1,2` — GREEN
      (the I.6 bundle-member count assertion unbroken; the standard amendment
      tests, if any, GREEN). [Story: NFR-B75-001]
- [ ] **T-GAT-003** : `bash .forge/scripts/constitution-linter.sh` — OVERALL
      PASS (no inline `[NEEDS CLARIFICATION]` outside the intended artefact
      markers — confirm the linter does not flag the artefact markers; if it
      does, the artefacts' markers use a distinct comment form the linter
      excludes, per the i6 precedent). [Story: NFR-B75-004]
- [ ] **T-GAT-004** : `bash bin/validate-standards-yaml.sh` — GREEN (new standard
      is MD, out of scope; live baseline preserved). [Story: NFR-B75-001]
- [ ] **T-GAT-005** : `wc -l .github/workflows/forge-ci.yml` < 300.
      [Story: NFR-B75-007]
- [ ] **T-GAT-006** : Status flip `.forge.yaml` → `implemented`; timeline
      populated. [Story: Article V]

### Phase 5 exit gate

All L1 + L2 GREEN. All gate scripts PASS. `i6.test.sh` GREEN (no cross-impact
regression). Status `implemented`. Ready for `/forge:archive` on user trigger.

---

## Task summary

| Phase | Tasks | Notes |
|-------|-------|-------|
| 1 | 9 | RED harness + 17 stubs + CI reg + **I.6 cross-impact verification** (T-XIMP-001). |
| 2 | 13 | Artefacts (6 ai-act + 3 dora) + **mandatory Demeter+Aegis anti-hallucination review** + negative-grep GREEN. |
| 3 | 11 | New standard + additive `bundle.sh` + **I.6 standard 1.1.0 lock-step** + index + REVIEW. |
| 4 | 6 | docs/COMPLIANCE.md + CHANGELOG + plan/roadmap inventory. |
| 5 | 10 | L2 bundle integration/determinism/graceful-absence + final gates incl. i6-GREEN. |
| **Total** | **49** | TDD discipline; immutable RED→GREEN→REFACTOR; Article III.4 grounded-or-deferred; I.6 contract bumped 1.0.0→1.1.0 in lock-step. |

## Anti-hallucination checklist (Article III.4 — re-verify before archive)

- [ ] No AI-Act / DORA Article number, recital, or precise date in any artefact
      that is NOT traceable to a cited repo source OR inside a
      `[NEEDS CLARIFICATION]` marker (`_test_b75_030` negative-grep GREEN).
- [ ] Every `obligations-index.yaml` `status: satisfied` entry names a concrete
      Forge evidence surface.
- [ ] Every legal question the repo cannot answer is a `[NEEDS CLARIFICATION]`
      tagged "Themis (K.5)" — NOT an invented answer.
- [ ] Context7 was NOT used for legal text (only — if at all — for any incidental
      software API, of which this brick has none).
