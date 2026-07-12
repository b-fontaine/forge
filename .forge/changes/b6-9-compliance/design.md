# Design: b6-9-compliance

<!-- Status: planned (pre-implementation) -->
<!-- Schema: default -->
<!-- Routing: Clio (artefact prose) + Demeter (K.3, data-steward review) + Aegis (legal-content sanity) + Atlas (bundle wiring) + Vulcan/Ferris (event-stack grounding) -->
<!-- Context7: NOT consulted — no software-library API surface; regulatory content is law, not a library (Article III.4). bin/forge-sbom.sh is reused verbatim, not re-authored. -->

> Read alongside `specs.md` (FR-B69-* / NFR-B69-*) and `open-questions.md`
> (legal Q-001..Q-005 grounded-or-deferred ; design Q-010..Q-015 →
> ADR-B69-001..007). This document locks the implementation strategy + the b7-5
> + I.6 cross-impact analysis.

**Constitution** : v2.0.0 — no bump (additive). Gate at end : no Article violation.

## Architecture Decisions

### ADR-B69-001 — Create `.forge/compliance/nis2/` (resolves Q-010)

**Context** : I.6 forward-declared `.forge/compliance/{nis2,dora,cra,ai-act}/`
(ADR-I6-CA-002). b7-5 filled `ai-act/` + `dora/` (ai-native-rag). The `nis2/` +
`cra/` siblings stayed reserved.

**Decision** : fill the `nis2/` sibling. `event-driven-eu`'s profile (§10.3 line
782) names **NIS2 + DORA (si finance) + CRA** ; NIS2 is its primary regulatory
surface, so `nis2/` is created here. `cra/` stays reserved (commercial-binary
CRA — a separate brick). `ai-act/` + `dora/` are b7-5's (untouched).

**Consequences** : ✅ honours the I.6 forward-declaration ; ✅ the bundle
`regulatory/nis2/<file>` path mirrors the source 1:1 ; ⚠️ creating `nis2/`
trips the b7-5 `_test_b75_001` reservation assertion → ADR-B69-006 lock-step.

**Constitution** : Article V (audit trail), Article XI.3 (schema-driven layout).

---

### ADR-B69-002 — Wire nis2 into the I.6 bundle now; 1.1.0 → 1.2.0 lock-step (resolves Q-011)

**Context** : `bundle.sh` walks `("ai-act", "dora")` and keys members
`regulatory/<reg>/<file>` ; the MANIFEST + tar loop iterate
`sorted(members.keys())`. b7-5 realised the ai-act/dora expansion at contract
v1.1.0. NIS2 is the next additive member set.

**Decision** : add `"nis2"` to the walk tuple. The new members are absorbed with
**zero change to the archive format, the determinism recipe, or the MANIFEST
format**. SemVer-minor bump of the bundle contract
`compliance-artefacts-bundle.md` **1.1.0 → 1.2.0**. The I.6 standard's schema
table gains a `regulatory/nis2/*` row (FR-B69-BD-010), its reserved-siblings
prose records NIS2 shipped / CRA reserved, and Interdiction #3 is amended to
remove NIS2 (FR-B69-BD-011). REVIEW.md entry in the SAME change.

**I.6 cross-impact** :
- `i6.test.sh` L2 builds a *synthetic minimal tree* (4 canonical surfaces only,
  no `.forge/compliance/`), so its member-count assertion is immune to the new
  `nis2/` artefacts — **no edit to `i6.test.sh` required** (confirmed hermetic,
  same as b7-5's finding). Verified at implementation RED (T-XIMP-001).
- b7-5's L2 fixture `cp`s only `ai-act/*` + `dora/*` into its tmpdir — creating
  the live `nis2/` dir does NOT change b7-5's L2 MANIFEST count.

**Constitution** : Article XII (SemVer per the bundle standard ; REVIEW.md
append-only), Article V (audited bump).

---

### ADR-B69-003 — New standard `global/nis2-dora-eda-artefacts.md` (resolves Q-012)

**Decision** : new standard. b7-5's `ai-act-dora-artefacts.md` governs the
`ai-native-rag` AI-Act + DORA content ; B.6.9 governs the `event-driven-eu` NIS2
+ DORA-EDA content + the SBOM-wiring posture — a distinct concern with distinct
grounding + a distinct (event-stack) evidence-surface set. Precedent : I.2 / I.6
/ b7-5 are separate standards in one compliance family.

**Constitution** : Article XII (one standard, one concern).

---

### ADR-B69-004 — DORA RoI helper is a script driving the b7-5 base (resolves Q-005)

**Context** : `.forge/compliance/dora/` already carries the b7-5 DORA artefacts,
each pinned to `B.7.5+B.7.8` and gated per-file by `b7-5.test.sh` (audit-anchor +
negative-grep). Dropping a B.6.9-anchored file into `dora/` would regress the
b7-5 harness.

**Decision** : the DORA RoI submission helper is a **script**
`.forge/scripts/compliance/dora-roi-helper.sh` (bash thin + Python 3 inline, the
repo `bundle.sh`/`forge-sbom.sh` pattern per NFR-B69-003). It reads the b7-5
`dora/roi-register.template.yaml` base (DRIVE, never fork) and emits a
stack-specialised RoI skeleton (NATS/Temporal/Postgres provider categories +
the `[NEEDS CLARIFICATION]` for the authoritative ESA schema). This keeps
`dora/` byte-stable for b7-5 and satisfies the "script/template" deliverable.

**Consequences** : ✅ zero b7-5 `dora/` regression ; ✅ genuine "submission
helper" (generator, not a static file) ; ⚠️ the helper reads a b7-5 file — a
one-directional DRIVE dependency, documented.

**Constitution** : Article V, Article XI.3 (schema-driven output).

---

### ADR-B69-005 — Harness after `b7-5.test.sh` (compliance family) (resolves Q-013)

**Decision** : `b6-9.test.sh --level 1,2` immediately after the `b7-5.test.sh`
row. The brick extends the I.x compliance family (fills the I.6-reserved layout,
bumps the I.6 bundle contract), so it clusters with the compliance harnesses
(`i2`/`i6`/`i3`/`i5`/`b7-5`), not the b6 archetype-mechanics harnesses. `--level
1,2` mirrors `i6`/`b7-5` (L2 bundle fixtures). The `b6` prefix in the `i`/`b7-5`
block is intentional (by number, not substance) — the matrix comment notes it.

**Constitution** : Article VIII (CI infra), Article XII (deterministic ordering).

---

### ADR-B69-006 — b7-5 `_test_b75_001` nis2-reserved assertion amended in lock-step (resolves Q-015)

**Context** : `b7-5.test.sh::_test_b75_001` fails if `.forge/compliance/nis2/`
exists — a forward reservation written when NIS2 was Themis-territory. B.6.9 IS
that "later" for NIS2.

**Decision** : amend `_test_b75_001` in the SAME change — remove the two lines
that fail on `nis2/` existing ; **keep** the `cra/`-reserved lines. The b7-5
harness stays GREEN after the edit. b6-9's `_test_b69_053` positively asserts the
edit is present (nis2 check gone, cra check kept). This is the
"shared-reservation → update every sibling that hard-pins it" discipline — the
same lock-step b7-5 itself applied to the I.6 bundle-member count.

**Consequences** : ✅ no silent CI-red on main ; ✅ b7-5 harness intent
preserved (cra still reserved) ; ⚠️ editing a merged sibling's harness — audited
here + re-run at the final gate (T-GAT).

**Constitution** : Article V (audited cross-impact edit), Article I (both
harnesses GREEN before done).

---

### ADR-B69-007 — No new `forge-compliance.yml` step (resolves Q-014)

**Decision** : NO. Once `bundle.sh` collects the nis2 members (ADR-B69-002), the
existing `bundle` step in `forge-compliance.yml` packs them into the uploaded
`.tgz` automatically. The 4-step contract (`demeter`/`linter`/`sbom`/`bundle`) is
preserved. Structural validation lives in `b6-9.test.sh` (mirrors b7-5
ADR-B75-005).

**Constitution** : Article VIII (minimal infra), Article XII (stable
reusable-workflow contract).

---

## Artefact content design (the load-bearing anti-hallucination surface)

Each artefact is grounded ONLY in cited repo sources (`open-questions.md`
Q-001..Q-005). No NIS2/DORA Article number appears in the artefact text (the
grounding is cited by document section — the negative-grep `_test_b69_030`
enforces this).

### `.forge/compliance/nis2/incident-reporting.md`

```
<!-- Audit: B.6.9 (b6-9-compliance) -->
# NIS2 — Incident Reporting (event-driven-eu archetype)

> Governance: content-frozen v1.0.0 (BDFL Phase A) ; Themis (K.5) Phase B.

## Grounded obligation
A significant incident affecting the event-driven system must be reported.
Grounded reporting windows (verbatim):
- "reporting 24h/72h"  (ARCHITECTURE-TARGET §10.4 [source: nis-2-directive.com,
   accessed 2026-04] ; new-archetypes-plan §7.1 I.6 bullet).
- "incident reporting < 24h"  (Themis charter, ARCHITECTURE-TARGET §9.2).

## Operational surface (event-driven-eu)
Incident scenarios scoped to the archetype's grounded component stack
(event-driven-eu/1.0.0.yaml components:):
- NATS JetStream event-backbone outage / message loss.
- Temporal orchestration workflow failure / stuck saga.
- Postgres event-store breach / corruption.

## Forge evidence surfaces
| Obligation | Forge evidence surface |
|---|---|
| Incident detected + auditable trail | I.6 audit-ledger snapshot (bundle.sh → audit/audit-ledger.json) |
| Operational telemetry for the incident | IX.4 Rust OTel tracing spans (SigNoz/OBI/Coroot — schema observability component) |

## Precise reporting stages
[NEEDS CLARIFICATION: the NIS2 reporting stages (early warning / incident
 notification / final report) mapping onto the 24h/72h windows + the CSIRT /
 competent-authority routing — Themis (K.5) to supply from the official NIS2
 text; the repo grounds only the "24h/72h" + "< 24h" figures.]
```

### `.forge/compliance/nis2/incident-report.template.yaml`

Adopter-fillable YAML skeleton: `# Audit: B.6.9 (b6-9-compliance)` +
`[NEEDS CLARIFICATION]` (CSIRT field schema) header, then a
`incident_notification:` block with a `early_warning` (24h) sub-block +
`incident_notification` (72h) sub-block + an `affected_components` list of
`<FILL: NATS/Temporal/Postgres ...>` entries.

### `.forge/compliance/nis2/obligations-index.yaml`

```yaml
# Audit: B.6.9 (b6-9-compliance)
schema_version: "1.0.0"
regulation: nis2
obligations:
  - id: incident-reporting
    title: "Significant incident reported within the 24h/72h windows"
    status: satisfied
    satisfied_by:
      - "I.6 audit-ledger snapshot"
      - "IX.4 Rust OTel tracing spans (SigNoz/OBI/Coroot)"
    source: "docs/ARCHITECTURE-TARGET.md §10.4 (24h/72h) ; §9.2 (< 24h) ; nis2/incident-reporting.md"
  - id: supply-chain-security
    title: "Supply-chain transparency via SBOM"
    status: satisfied
    satisfied_by:
      - "CycloneDX SBOM (bin/forge-sbom.sh over Cargo.lock)"
      - "I.6 bundle sbom/sbom.cdx.json member"
    source: "global/compliance-artefacts-bundle.md § Purpose (NIS2 supply-chain transparency)"
  - id: risk-management-measures
    title: "Detailed NIS2 risk-management measures"
    status: needs-clarification
    themis_owner: K.5
    satisfied_by: []
  - id: governance-oversight
    title: "Management-body governance / accountability (NIS2 pillar)"
    status: needs-clarification
    themis_owner: K.5
    satisfied_by: []
```

### `.forge/scripts/compliance/dora-roi-helper.sh`

bash thin + Python 3 inline. Reads
`<target>/.forge/compliance/dora/roi-register.template.yaml` (the b7-5 base) ;
emits (stdout or `--output`) an RoI skeleton whose `ict_third_party_providers:`
list is pre-seeded with the event-driven-eu categories (NATS JetStream /
Temporal / Postgres) as `<FILL: ...>` entries, plus a `# [NEEDS CLARIFICATION]`
for the authoritative ESA field schema and the grounded `30 avr 2026` deadline.
Exit 0 success / 1 missing base template / 2 usage.

---

## Implementation strategy (TDD phases)

### Phase 1 — RED harness + cross-impact verification
1. Create `b6-9.test.sh` with the full L1 + L2 test bodies. Register in
   `forge-ci.yml` after `b7-5.test.sh`.
2. Verify i6 + b7-5 L2 fixtures are hermetic (T-XIMP-001).
3. RED gate : `b6-9.test.sh --level 1,2` exits 1 (all FAIL) ; `i6.test.sh` /
   `b7-5.test.sh` / `verify.sh` / `constitution-linter.sh` unchanged.

### Phase 2 — NIS2 artefacts + DORA helper + b7-5 lock-step
Author the 3 nis2 members + the DORA helper. Amend `b7-5.test.sh::_test_b75_001`
(drop nis2 reservation) in the SAME phase (so the live `nis2/` dir does not turn
b7-5 red). **Demeter + Aegis review pass** on the regulatory prose before GREEN.
Artefact/helper L1 tests + the negative-grep + the b7-5-lock-step guard flip
GREEN ; re-run `b7-5.test.sh` GREEN.

### Phase 3 — Standard + bundle wiring (I.6 lock-step)
Author `nis2-dora-eda-artefacts.md`. Extend `bundle.sh` (add `"nis2"`). Bump the
I.6 standard 1.1.0 → 1.2.0 (schema row + reserved prose + Interdiction #3).
Index entry + REVIEW.md (birth + I.6 amendment). Standard + bundle-schema L1
tests flip GREEN.

### Phase 4 — Docs + stale-prose lock-step
`docs/COMPLIANCE.md` new H2 + the b7-5-section "reserved" fix ;
`ai-act-dora-artefacts.md` "reserved" → shipped fix ; CHANGELOG. Docs L1 tests
flip GREEN.

### Phase 5 — L2 fixtures + final gates
L2 bundle-integration + determinism + graceful-absence flip GREEN. Final gates :
`b6-9.test.sh --level 1,2` all GREEN ; `b7-5.test.sh --level 1,2` GREEN (no
regression) ; `i6.test.sh --level 1,2` GREEN ; `verify.sh` PASS ;
`constitution-linter.sh` PASS ; `validate-standards-yaml.sh` GREEN. Status →
`implemented`.

---

## L1 / L2 test catalogue

### L1 (≥ 14 tests — hermetic, ≤ 5 s)

| # | Test | FR/NFR |
|---|------|--------|
| 1 | `_test_b69_001_nis2_dir_present` | FR-B69-NIS2-001 |
| 2 | `_test_b69_002_audit_comments` | FR-B69-NIS2-002 |
| 3 | `_test_b69_010_incident_reporting` | FR-B69-NIS2-010 / FR-B69-NIS2-011 |
| 4 | `_test_b69_011_incident_report_template` | FR-B69-NIS2-012 |
| 5 | `_test_b69_012_nis2_obligations_index` | FR-B69-NIS2-013 / FR-B69-SBOM-010 |
| 6 | `_test_b69_020_dora_roi_helper_present` | FR-B69-DORA-001 |
| 7 | `_test_b69_021_dora_roi_helper_runs` | FR-B69-DORA-010 / FR-B69-DORA-020 |
| 8 | `_test_b69_030_no_fabricated_citation` (negative-grep) | FR-B69-BD-102 / FR-B69-NIS2-030 |
| 9 | `_test_b69_040_standard_presence_frontmatter` | FR-B69-BD-020 / FR-B69-BD-021 |
|10 | `_test_b69_041_standard_h2_must_not_governance` | FR-B69-BD-022 / FR-B69-BD-024 / FR-B69-BD-026 |
|11 | `_test_b69_042_standard_sbom_wiring` | FR-B69-SBOM-001 |
|12 | `_test_b69_050_index_review_entries` | FR-B69-BD-030 / FR-B69-BD-031 |
|13 | `_test_b69_051_i6_standard_amended` | FR-B69-BD-010 / FR-B69-BD-011 |
|14 | `_test_b69_052_bundle_walks_nis2` | FR-B69-BD-001 |
|15 | `_test_b69_053_b75_harness_lockstep` | FR-B69-BD-130 |
|16 | `_test_b69_060_compliance_doc_h2` | FR-B69-BD-120 |
|17 | `_test_b69_061_changelog_entry` | FR-B69-BD-121 |

### L2 (3 fixture tests)

| # | Test | FR/NFR |
|---|------|--------|
| 1 | `_test_b69_l2_bundle_integration` | FR-B69-BD-110 / FR-B69-BD-001 / FR-B69-BD-002 |
| 2 | `_test_b69_l2_bundle_determinism` | FR-B69-BD-110 / FR-B69-BD-003 / NFR-B69-002 |
| 3 | `_test_b69_l2_graceful_absence` | FR-B69-BD-111 / FR-B69-BD-004 |

L2 fixtures build their OWN tmpdir (the 4 I.6 canonical surfaces ± the nis2
artefacts) — never reading the live worktree's bundle output — so they are
hermetic and do not couple to i6/b7-5 counts.

---

## BDD scenarios (Article II)

```gherkin
Feature: event-driven-eu NIS2 + DORA regulatory hand-off
  As an auditor of an event-driven-eu deployment
  I want the NIS2 incident-reporting + DORA RoI artefacts in the hand-off bundle
  So that I can trace each obligation to the Forge evidence surface

  Scenario: Auditor receives the NIS2 artefacts in the bundle
    Given an event-driven-eu project carrying .forge/compliance/nis2/
    When the adopter runs .forge/scripts/compliance/bundle.sh
    Then the .tgz contains regulatory/nis2/incident-reporting.md
    And the MANIFEST lists it with a sha256 + size

  Scenario: Adopter compiles the DORA Register of Information for the stack
    Given the b7-5 dora/roi-register.template.yaml base exists
    When the adopter runs .forge/scripts/compliance/dora-roi-helper.sh
    Then the emitted RoI skeleton enumerates NATS JetStream, Temporal, Postgres
    And it carries a [NEEDS CLARIFICATION] for the authoritative ESA field schema
```

---

## Out of scope (deferred)

- **`cra/` sibling** — reserved (commercial-binary CRA).
- **New SBOM generator** — `bin/forge-sbom.sh` already handles Rust (Q-004).
- **Scaffold/CI SBOM step** — B.6.2 / B.6.5 (sibling lanes).
- **Themis (K.5) itself** — already shipped ; `[NEEDS CLARIFICATION]` = Phase-B.
- **Plan/roadmap resync** — deferred (collision avoidance, mirrors b7-5 T-INV).
- **VERSION bump** — maintainer release task (NFR-B69-005).

---

## Constitutional Compliance per Article

- **Article I (TDD)** — Phase 1 full RED witness before any artefact.
- **Article II (BDD)** — Gherkin above.
- **Article III.4 (anti-hallucination)** — LOAD-BEARING ; Q-001..Q-005
  grounded-or-deferred ; `_test_b69_030` negative-grep ; Demeter+Aegis review ;
  Context7 NOT used for law.
- **Article V (audit trail)** — every task `[Story: FR-B69-*]` ; audit anchors ;
  I.6 amendment + b7-5 lock-step in REVIEW.md / the change record.
- **Article VIII.2 / IX.4** — artefacts LINK to grounded Temporal + Rust OTel
  evidence, do not re-implement.
- **Article XII (governance)** — standard ENFORCES content schema + Phase A/B ;
  bundle SemVer-minor per the bundle standard ; REVIEW.md append-only. No
  amendment.

No constitutional amendment required.
