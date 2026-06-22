# Design: b7-5-ai-act

<!-- Status: planned (pre-implementation) -->
<!-- Schema: default -->
<!-- Routing: Clio (spec writer, artefact prose) + Demeter (K.3, data-steward review) + Aegis (legal-content sanity) + Atlas (bundle wiring) -->
<!-- Context7: NOT consulted — this brick has no software-library API surface; the regulatory content is law, not a library (Article III.4 / brief). -->

> Read alongside `specs.md` (FR-B75-AA-* / FR-B75-DO-* / FR-B75-BD-* /
> NFR-B75-*) and `open-questions.md` (legal Q-001..Q-005 grounded-or-deferred;
> design Q-010..Q-014 → ADR-B75-001..005). This document locks the
> implementation strategy + the I.6 cross-impact analysis.

**Constitution** : v2.0.0 — no bump (additive). Gate at end : no Article
violation.

## Architecture Decisions

### ADR-B75-001 — Per-regulation `.forge/compliance/{ai-act,dora}/` layout (resolves Q-010)

**Context** : I.6 forward-declared `.forge/compliance/{nis2,dora,cra,ai-act}/`
(I.6 proposal "Scope Out" + ADR-I6-CA-002 reserving a `regulatory/` bundle
subdirectory) but shipped no file there. This brick fills the `ai-act/` + `dora/`
siblings.

**Decision** : per-regulation subdirectories. Each regulation gets its own
directory under `.forge/compliance/`; the `nis2/` + `cra/` siblings stay
reserved (empty, not created) for their owning archetypes/bricks
(`event-driven-eu` for NIS2, commercial-binary CRA).

**Consequences** :
- ✅ Honours the exact I.6 forward-declaration — Themis (K.5) + NIS2/CRA drop in
  additively.
- ✅ The bundle's `regulatory/<regulation>/<file>` path mirrors the source tree
  1:1, so the auditor `cd regulatory/ai-act/` to inspect one regulation.
- ⚠️ Only `ai-act/` + `dora/` are created here (the `ai-native-rag` profile,
  §10.3 line 783, names only those two). Creating empty `nis2/`/`cra/` dirs would
  be premature scaffolding — deferred.

**Constitution** : Article V (audit trail — per-regulation traceability),
Article XI.3 (schema-driven layout).

---

### ADR-B75-002 — Wire into the I.6 bundle now; SemVer-minor bump; I.6 updated in lock-step (resolves Q-011)

**Context** : I.6 built the bundle to absorb these additively (FR-I6-CA-053
forward-compat note; ADR-I6-CA-002 `regulatory/` reservation; MANIFEST over
`sorted(members.keys())`). Shipping artefacts without wiring would leave the
forward-pointer unrealised + the hand-off incomplete.

**Decision** : extend `bundle.sh` now. The Python inline block's `members` dict
(`bundle.sh:358`) gains, via a directory walk, one entry per file under
`.forge/compliance/{ai-act,dora}/`, keyed `regulatory/ai-act/<name>` /
`regulatory/dora/<name>`. Because the MANIFEST + the tar member loop both
iterate `sorted(members.keys())` (`bundle.sh:368`, `:382`), the new members are
absorbed with **zero change to the archive format, the determinism recipe, or
the MANIFEST format**. This is a **SemVer minor** bump of the bundle contract per
`compliance-artefacts-bundle.md` ("adding a member = minor"). The I.6 standard's
schema table (FR-B75-BD-010), its "exactly 6 members" prose, the
forward-compat note (FR-B75-BD-011), AND the `i6.test.sh` member-count
assertions are all updated in the SAME change.

**I.6 cross-impact (critical — must be handled in lock-step)** :
- `i6.test.sh` L2 `_test_i6_l2_bundle_good` asserts `tar -tzf | wc -l == 6`
  (design.md i6 § "L2 good-bundle test" step 5-6 : "6 expected members" / "5
  non-MANIFEST entries"). With the regulatory members present in the worktree,
  this count would break. **Resolution** : the i6 L2 fixture builds a *synthetic
  minimal tree* (i6 design § "L2 good-bundle test" step 1-2 : a tmpdir with only
  the 4 canonical surfaces) — it does NOT include `.forge/compliance/{ai-act,dora}/`,
  so the i6 L2 count stays 6 and i6 stays GREEN unchanged. The b7-5 L2 fixture
  (FR-B75-BD-110) builds its OWN tmpdir that ADDS the regulatory artefacts and
  asserts the higher count. **No edit to `i6.test.sh` is required** provided the
  i6 L2 fixture is confirmed hermetic (it is — it `cp`s named surfaces into a
  tmpdir, never the live `.forge/compliance/`). This must be **verified at
  implementation RED** before touching `bundle.sh` (a `[Story]`-tagged
  verification task).
- If i6 ran its bundle against the *live worktree* anywhere (it does not for the
  count assertion), that path would need the count made variable. Confirmed
  not the case from i6 design § L2.

**Consequences** :
- ✅ Realises FR-I6-CA-053; auditor hand-off now carries the regulatory layer.
- ✅ No determinism regression (recipe untouched; re-asserted by FR-B75-BD-110).
- ⚠️ The I.6 standard version bumps 1.0.0 → 1.1.0 (additive) with a REVIEW.md
  entry — a deliberate, audited contract change.

**Constitution** : Article XII (governance — SemVer-minor per the bundle
standard; REVIEW.md append-only), Article V (the bump is audited).

---

### ADR-B75-003 — New standard `global/ai-act-dora-artefacts.md` (resolves Q-012)

**Context** : Q-012 — own standard vs extend `compliance-artefacts-bundle.md`.

**Decision** : new standard. The I.6 standard governs the **bundle mechanism**
(determinism, members, hand-off contract); this brick governs the **regulatory
content schema + its Phase A/B governance posture** — a separate concern with a
separate (Themis-driven) review cadence. Precedent : I.2
(`compliance-tiers.md`) and I.6 (`compliance-artefacts-bundle.md`) are distinct
standards in the same compliance family. The I.6 standard gains only the
additive bundle-member table rows + the version bump.

**Consequences** :
- ✅ The Themis Phase-B cadence attaches to the right standard (the content one),
  not the mechanism one.
- ✅ The I.6 standard stays focused on determinism/hand-off.

**Constitution** : Article XII (one standard, one concern, SemVer per
`standards-lifecycle.md`).

---

### ADR-B75-004 — Harness after `i5.test.sh` in the compliance family (resolves Q-013)

**Context** : `forge-ci.yml` orders harnesses load-bearingly (siblings
grep-assert adjacency, per the matrix comment lines 58-66). The brick extends the
I.x compliance family (fills the I.6 layout, bumps the I.6 bundle contract).

**Decision** : `b7-5.test.sh --level 1,2` immediately after the `i5.test.sh`
row (the last compliance harness), before `f3.test.sh`. `--level 1,2` because
it carries L2 bundle fixtures (mirrors `i6.test.sh --level 1,2`).

**Consequences** :
- ✅ Compliance harnesses cluster together (`i2`/`i6`/`i3`/`i5`/`b7-5`); a
  reader finds all EU-compliance tests in one block.
- ✅ Keeps `forge-ci.yml` at ~294 lines (under the 300 NFR-CI-002 budget).
- ⚠️ The b7-5 row name carries the `b7` prefix but lives in the `i`-block — a
  documented intentional placement (the brick is a B.7 brick by *number* but a
  compliance-family change by *substance*). The matrix comment will note it.

**Constitution** : Article VIII (CI infra), Article XII (deterministic CI
ordering).

---

### ADR-B75-005 — No new `forge-compliance.yml` step (resolves Q-014)

**Context** : Q-014 — does the I.5 reusable workflow need a new step?

**Decision** : NO. Once `bundle.sh` collects the regulatory members
(ADR-B75-002), the existing `bundle` step in `forge-compliance.yml` (line 119-130)
packs them into the uploaded `.tgz` automatically. The artefacts reach the
auditor hand-off with **zero workflow change**. Structural validation of the
artefacts (`obligations-index.yaml` well-formedness, the anti-hallucination
negative-grep) lives in `b7-5.test.sh` (run by `forge-ci.yml`), not in the
adopter-facing reusable workflow.

**Consequences** :
- ✅ `forge-compliance.yml` stays minimal; its 4-step contract
  (`demeter`/`linter`/`sbom`/`bundle`) + 158-line size are preserved.
- ✅ Adopters consuming the reusable workflow get the regulatory layer for free
  (it rides the bundle they already upload).

**Constitution** : Article VIII (minimal infra surface), Article XII (stable
reusable-workflow contract).

---

## Artefact content design (the load-bearing anti-hallucination surface)

Each artefact is grounded ONLY in cited repo sources (`open-questions.md`
Q-001..Q-005). The design fixes the **shape** so the implementer has no room to
invent legal content.

### `.forge/compliance/ai-act/risk-classification.md`

```
<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->
# AI Act — Risk Classification (ai-native-rag archetype)

## Grounded posture
The ai-native-rag archetype carries AI Act **transparency obligations**.
  Source: docs/ARCHITECTURE-TARGET.md §10.3 (profile "RGPD + AI Act + DORA si finance");
          global/llm-gateway.md ("AI Act transparency obligations (B.7.5 territory)").

## Escalation triggers the DEPLOYER must self-assess (with counsel)
- Deployment in a regulated / finance context (§10.3 "DORA si finance").
- Use for a decision that affects individuals' rights / access to services.
- [other triggers — deployer-assessed]

## Precise risk-category mapping
[NEEDS CLARIFICATION: AI Act risk-category mapping (prohibited / high-risk Annex III /
 limited-risk / minimal) + Article numbers — Themis (K.5) to supply from the official
 AI Act text; not in the repo's grounded sources.]
[NEEDS CLARIFICATION: whether a finance-sector RAG deployment is AI-Act high-risk
 (Annex III) — deployer + counsel determination; Themis (K.5) to track; not
 framework-determinable.]
```

### `.forge/compliance/ai-act/transparency-obligations.md`

H2s : `## Obligations` (users informed they interact with an AI system; AI output
identifiable — stated as the transparency-obligation class, NOT cited to an
Article); `## Forge evidence surfaces` (table : obligation → surface) :

| Obligation | Forge evidence surface |
|---|---|
| User informed they interact with an AI system | Qwik UI shell + `fallbackUsed` indicator (b7-2-scaffolder FR-B7-2-020) |
| AI interaction logged / auditable | IX.6 prompt-audit record (model/tenant/tier/tokens/latency/provider/fallback — llm-gateway.md) |

### `.forge/compliance/ai-act/model-card.template.md` + `dataset-card.template.md`

Adopter-fillable skeletons mirroring `forge-dpa-declared.template` :
header-comment (audit anchor + "fill before build" remediation note + the Q-004
`[NEEDS CLARIFICATION]` on the bias-eval Article) → a `## …` section skeleton
with `<FILL: …>` placeholders → a commented canonical example. No legal duty
asserted.

### `.forge/compliance/ai-act/obligations-index.yaml`

```yaml
# Audit: B.7.5+B.7.8 (b7-5-ai-act)
schema_version: "1.0.0"
regulation: ai-act
obligations:
  - id: transparency
    title: "Users informed of AI interaction; AI output identifiable"
    status: satisfied
    satisfied_by:
      - "Qwik fallbackUsed indicator (b7-2-scaffolder FR-B7-2-020)"
      - "IX.6 prompt-audit record (global/llm-gateway.md)"
    source: "docs/ARCHITECTURE-TARGET.md §10.3 ; global/llm-gateway.md"
  - id: logging-record-keeping
    title: "AI interactions logged for audit"
    status: satisfied
    satisfied_by:
      - "IX.6 prompt-audit record"
      - "I.6 audit-ledger snapshot"
    source: "global/llm-gateway.md §'Prompt audit'"
  - id: conformity-assessment
    title: "Conformity assessment / CE marking (if high-risk)"
    status: needs-clarification
    themis_owner: K.5
    satisfied_by: []
  - id: post-market-monitoring
    title: "Post-market monitoring (if high-risk)"
    status: needs-clarification
    themis_owner: K.5
    satisfied_by: []
```

### `.forge/compliance/dora/incident-reporting.md`

H2s : `## Grounded obligation` (a major ICT-related incident must be reported;
the repo grounds a "< 24h" charter figure — §9.2 line 735 — and the DORA RoI ESA
submission deadline "30 avr 2026" — §10.4); `## Forge evidence surfaces`
(I.6 audit-ledger snapshot + IX.6 prompt-audit span); `## Precise notification
windows` → the Q-002 `[NEEDS CLARIFICATION]` (initial/intermediate/final DORA
windows — Themis K.5).

### `.forge/compliance/dora/roi-register.template.yaml`

Adopter-fillable RoI skeleton; header carries the
`[NEEDS CLARIFICATION: authoritative RoI field schema — Themis (K.5)]`.

### `.forge/compliance/dora/obligations-index.yaml`

Same shape as the AI-Act index, `regulation: dora`; grounded
`incident-reporting` + `register-of-information` entries → evidence; ungrounded
DORA pillars (ICT risk-management framework, third-party-risk register details)
flagged `needs-clarification` / `themis_owner: K.5`.

---

## Implementation strategy (TDD phases)

### Phase 1 — RED harness + I.6 cross-impact verification

1. Create `.forge/scripts/tests/b7-5.test.sh` with ≥ 14 L1 + ≥ 3 L2 stubs all
   `_not_implemented`. Register in `forge-ci.yml` after `i5.test.sh`.
2. **Verify the I.6 L2 fixture is hermetic** (does NOT read live
   `.forge/compliance/`) — confirm `i6.test.sh --level 2` stays GREEN once the
   regulatory dirs will exist. Captured as a `[Story]`-tagged task; if NOT
   hermetic, the i6 count assertion is made variable in this same change.
3. RED gate : `b7-5.test.sh --level 1,2` exits 1 (all FAIL); `i6.test.sh`,
   `verify.sh`, `constitution-linter.sh` unchanged.

### Phase 2 — Artefacts (AI-Act + DORA)

Author the 6 ai-act + 3 dora members per the content design above, each with the
audit anchor + grounded sources + `[NEEDS CLARIFICATION]` markers. **Demeter +
Aegis review pass** on the regulatory prose before GREEN (NFR-B75-004). Artefact
L1 tests + the negative-grep test flip GREEN.

### Phase 3 — Standard + bundle wiring

Author `global/ai-act-dora-artefacts.md`. Extend `bundle.sh` (`members` dict
directory walk). Update the I.6 standard (table rows + 1.0.0→1.1.0 +
forward-compat note). Index entry + REVIEW.md (birth + I.6 amendment). Standard
+ bundle-schema L1 tests flip GREEN.

### Phase 4 — Docs + inventory

`docs/COMPLIANCE.md` H2; plan rows B.7.5+B.7.8 + §0.12 brick #6 + §2760 T7 line;
roadmap; CHANGELOG. Docs L1 tests flip GREEN.

### Phase 5 — L2 fixtures + final gates

L2 bundle-integration + determinism + graceful-absence tests flip GREEN. Final
gates : `b7-5.test.sh --level 1,2` all GREEN; `i6.test.sh` GREEN (member-count
unbroken); `verify.sh` PASS (no regression); `constitution-linter.sh` PASS;
status → `implemented`.

---

## L1 / L2 test catalogue

### L1 (≥ 14 tests — hermetic, ≤ 5 s)

| # | Test | FR/NFR |
|---|------|--------|
| 1 | `_test_b75_001_compliance_dirs_present` | FR-B75-AA-001 / FR-B75-DO-001 |
| 2 | `_test_b75_002_audit_comments` | FR-B75-AA-002 / FR-B75-DO-002 |
| 3 | `_test_b75_010_risk_classification` | FR-B75-AA-010 / FR-B75-AA-011 |
| 4 | `_test_b75_011_transparency_obligations` | FR-B75-AA-012 |
| 5 | `_test_b75_012_model_dataset_cards` | FR-B75-AA-020 / FR-B75-AA-021 |
| 6 | `_test_b75_013_aiact_obligations_index` | FR-B75-AA-025 / FR-B75-AA-026 |
| 7 | `_test_b75_020_incident_reporting` | FR-B75-DO-010 / FR-B75-DO-011 |
| 8 | `_test_b75_021_roi_register` | FR-B75-DO-015 |
| 9 | `_test_b75_022_dora_obligations_index` | FR-B75-DO-016 |
|10 | `_test_b75_030_no_fabricated_citation` (negative-grep) | FR-B75-BD-102 / FR-B75-AA-030 / FR-B75-DO-020 |
|11 | `_test_b75_040_standard_presence_frontmatter` | FR-B75-BD-020 / FR-B75-BD-021 |
|12 | `_test_b75_041_standard_h2_must_not_governance` | FR-B75-BD-022 / FR-B75-BD-024 / FR-B75-BD-026 |
|13 | `_test_b75_050_index_review_entries` | FR-B75-BD-030 / FR-B75-BD-031 |
|14 | `_test_b75_051_i6_standard_amended` | FR-B75-BD-010 / FR-B75-BD-011 |
|15 | `_test_b75_060_compliance_doc_h2` | FR-B75-BD-120 |
|16 | `_test_b75_061_changelog_entry` | FR-B75-BD-122 |

### L2 (≥ 3 fixture tests)

| # | Test | FR/NFR |
|---|------|--------|
| 1 | `_test_b75_l2_bundle_integration` | FR-B75-BD-110.1 / FR-B75-BD-001 / FR-B75-BD-002 |
| 2 | `_test_b75_l2_bundle_determinism` | FR-B75-BD-110.2 / FR-B75-BD-003 / NFR-B75-002 |
| 3 | `_test_b75_l2_graceful_absence` | FR-B75-BD-111 / FR-B75-BD-004 |

L2 fixtures build their OWN tmpdir (the 4 I.6 canonical surfaces ± the
regulatory artefacts) — never reading the live worktree — so they are hermetic
and do not couple to i6's count (ADR-B75-002 cross-impact note).

---

## Dependencies on shipped state

| Dep | Archive date | This brick consumes |
|-----|--------------|---------------------|
| `i6-compliance-artefacts` | 2026-05-12 | `bundle.sh` + `regulatory/` reservation + the I.6 standard it amends |
| `i2-compliance-tiers` | 2026-05-12 | T1/T2/T3 gradient + Phase A/B governance precedent |
| `b7-standards` | 2026-06-13 | `llm-gateway.md` / `rag-patterns.md` (IX.6/XI.5/XI.6 hooks the artefacts link) |
| `b7-2-scaffolder` | 2026-06-21 | prompt-audit span + Qwik `fallbackUsed` indicator (evidence surfaces) |

No new external dependency.

---

## Out of scope (deferred)

- **Themis (K.5) agent itself** — the persona + the `forge review-standards`
  cycle + the rolling regulatory maintenance. This brick ships the frozen v1.0.0
  artefacts Themis Phase B will maintain.
- **NIS2 / CRA** `.forge/compliance/{nis2,cra}/` — other archetypes/bricks; the
  `regulatory/` layout reserves them.
- **Runtime Janus AI refusal (J.8.c)** — `b7-9-janus-ai`.
- **Automated model-evaluation report generation** — templates only here; a
  future Pythia (`b7-pythia` K.2) eval-run capability.
- **The VERSION bump** — maintainer release task (NFR-B75-005).

---

## Constitutional Compliance per Article

- **Article I (TDD)** — Phase 1 full RED witness before any artefact.
- **Article II (BDD)** — Gherkin (auditor-receives-bundle, adopter-fills-card).
- **Article III.4 (anti-hallucination)** — LOAD-BEARING; Q-001..Q-005
  grounded-or-deferred; FR-B75-BD-102 negative-grep; Demeter+Aegis review;
  Context7 NOT used for law.
- **Article V (audit trail)** — every task `[Story: FR-B75-*]`; audit anchors on
  every artefact + standard + harness; I.6 amendment in REVIEW.md.
- **Article IX.6 / XI.5 / XI.6** — artefacts LINK to scaffolded runtime evidence,
  do not re-implement.
- **Article XII (governance)** — standard ENFORCES content schema + Phase A/B;
  bundle SemVer-minor per the bundle standard; REVIEW.md append-only. No amendment.

No constitutional amendment required.
