# Proposal: b6-9-compliance

<!-- Created: 2026-07-10 -->
<!-- Schema: default -->
<!-- Audit: B.6.9 (docs/new-archetypes-plan.md §6.1 line 2565-2566 — event-driven-eu compliance hooks) -->
<!-- Template: mirrors b7-5-ai-act (B.7.5+B.7.8), adapted AI-Act→NIS2/DORA for the event-driven-eu archetype -->

## Problem

`docs/new-archetypes-plan.md` §6.1 lists **B.6.9** (line 2565-2566) as the
regulatory layer of the `event-driven-eu` archetype :

> **B.6.9.** Compliance hooks : SBOM CycloneDX auto-generation, NIS2 incident
> reporting template, DORA RoI submission helper. Effort : `M`.

This is the B.6 sibling of **B.7.5 + B.7.8** (`b7-5-ai-act`, archived
2026-06-22), which did the analogous compliance work for `ai-native-rag` — but
whereas the AI archetype's primary EU regulatory surface is the **AI Act** (LLM
risk classification / transparency), `event-driven-eu`'s primary surface is
**NIS2** (critical-infrastructure incident reporting 24h/72h) and **DORA**
(financial-sector operational resilience). The archetype's grounded compliance
profile is **"NIS2 + DORA (si finance) + CRA"** (`docs/ARCHITECTURE-TARGET.md`
§10.3 line 782).

**Ground truth (re-read 2026-07-10, Article III.4) — what already exists :**

- **`.forge/compliance/{ai-act,dora}/` exist** (b7-5-ai-act, ai-native-rag
  flavour). **`.forge/compliance/{nis2,cra}/` are still reserved** (I.6
  forward-declared `{nis2,dora,cra,ai-act}/` layout — ADR-I6-CA-002). This brick
  fills the **`nis2/`** sibling (the primary event-driven-eu surface). `cra/`
  stays reserved.
- **The I.6 bundle already absorbs new regulatory members additively.**
  `.forge/scripts/compliance/bundle.sh` walks `("ai-act", "dora")` under
  `.forge/compliance/` and keys members `regulatory/<reg>/<file>` ; the MANIFEST
  + tar loop consume `sorted(members.keys())`. Adding `"nis2"` to that tuple is a
  zero-format-change additive extension (SemVer-minor bump of the bundle
  contract `compliance-artefacts-bundle.md` 1.1.0 → 1.2.0).
- **The SBOM mechanism already exists.** `bin/forge-sbom.sh` (J.8.d) parses
  `Cargo.lock` (Rust) → CycloneDX 1.5 (`pkg:cargo/...` purls) ; the I.6 bundle
  packs it as `sbom/sbom.cdx.json`. `event-driven-eu` is a Rust backend, so its
  SBOM auto-generation **rides the existing mechanism** — no new generator.
- **The regulatory facts the repo verifiably carries** live in
  `docs/ARCHITECTURE-TARGET.md` §10.4 ("Échéances réglementaires") with source
  citations, mirrored in `docs/new-archetypes-plan.md` §7.1's I.6 bullet :
  **NIS2 reporting 24h/72h** ; **DORA RoI ESA submission 30 avr 2026**. The
  Themis charter (§9.2 line 735) grounds "incident reporting < 24h".
- **Themis (K.5) shipped** 2026-07-10 (`k5-themis`) and already carries the
  NIS2/DORA/CRA/AI-Act regulatory-deadline calendar **verbatim** ; it is the
  Phase-B maintainer of the artefacts this brick ships frozen at v1.0.0.

So today the runtime evidence (audit-ledger, OTel spans, SBOM) exists, but there
is **no spec-time artefact** that (a) states the archetype's NIS2 incident-
reporting obligation scoped to its NATS/Temporal/Postgres operational surface,
(b) helps an adopter compile the DORA Register-of-Information entries for that
stack, or (c) maps those obligations to where Forge produces the evidence.

## Solution

Ship a small, deterministic, **content-frozen** set of regulatory artefacts for
the `event-driven-eu` archetype, wired into the existing I.6 bundle generator
additively, governed by one new standard, proven by one new harness, with the
b7-5 sibling-harness reservation amended in lock-step. Seven coordinated
sub-modules :

### B.6.9.a — `.forge/compliance/nis2/` artefacts (primary surface)

A NEW per-regulation directory (fills the I.6-reserved `nis2/` sibling) capturing
the NIS2 obligations relevant to the archetype, grounded ONLY in cited repo
sources :

- `incident-reporting.md` — the NIS2 major-incident reporting obligation,
  citing the grounded **"reporting 24h/72h"** windows verbatim (§10.4 line 788 +
  §7.1 I.6 bullet ; `[source: nis-2-directive.com, accessed 2026-04]`) and the
  "< 24h" charter figure (§9.2). Scoped to the archetype's **operational
  surface** : NATS JetStream / Temporal / Postgres event-store outage or breach
  scenarios (grounded in `event-driven-eu/1.0.0.yaml` `components:`). Linked to
  the Forge evidence surfaces (I.6 audit-ledger snapshot + IX.4 Rust OTel
  tracing spans). The precise NIS2 stage breakdown → `[NEEDS CLARIFICATION]`.
- `incident-report.template.yaml` — an adopter-fillable NIS2 incident-
  notification skeleton (24h early-warning + 72h notification fields), scoped to
  the event stack ; `[NEEDS CLARIFICATION]` for the authoritative CSIRT field
  schema. Mirrors the b7-5 template pattern.
- `obligations-index.yaml` — machine-parseable NIS2 obligation → evidence map
  (`regulation: nis2`). Two grounded obligations (`incident-reporting`,
  `supply-chain-security`) `satisfied` with concrete `satisfied_by` surfaces ;
  ungrounded pillars flagged `needs-clarification` + `themis_owner: K.5`.

### B.6.9.b — DORA RoI submission helper

A **script** `.forge/scripts/compliance/dora-roi-helper.sh` (bash thin + Python 3
inline, the repo `bundle.sh`/`forge-sbom.sh` pattern) that helps an adopter
compile the DORA Register-of-Information ICT third-party entries **relevant to
this archetype's stack** (NATS JetStream / Temporal / Postgres providers,
grounded in `event-driven-eu/1.0.0.yaml`). It DRIVES (reads, never forks) the
b7-5 `.forge/compliance/dora/roi-register.template.yaml` base and specialises it
for the event stack, emitting an adopter-fillable RoI skeleton. The authoritative
ESA field schema is deferred to Themis via a `[NEEDS CLARIFICATION]` (Q-002).

### B.6.9.c — SBOM CycloneDX auto-generation wiring

Grounding documentation (in the new standard + the `nis2/obligations-index.yaml`
supply-chain obligation) that event-driven-eu SBOM auto-generation rides the
existing `bin/forge-sbom.sh` (Rust `Cargo.lock` → CycloneDX 1.5) + the I.6
bundle's `sbom/sbom.cdx.json` member — the same mechanism every other archetype
uses (Q-004). **No new generator code** ; no edit to `bin/forge-sbom.sh`.

### B.6.9.d — Bundle wiring (I.6 additive extension, 1.1.0 → 1.2.0)

Extend `.forge/scripts/compliance/bundle.sh` so the directory-walk tuple gains
`"nis2"` (`("ai-act", "dora", "nis2")`), collecting `.forge/compliance/nis2/*`
under `regulatory/nis2/*`. Update the I.6 standard
`compliance-artefacts-bundle.md` : add the `regulatory/nis2/*` schema-table row ;
bump `version: 1.1.0 → 1.2.0` ; update the reserved-siblings prose (NIS2 shipped,
CRA reserved) ; amend Interdiction #3 to remove NIS2. REVIEW.md entry.

### B.6.9.e — Standard `global/nis2-dora-eda-artefacts.md`

A new Markdown standard (mirroring `ai-act-dora-artefacts.md`) documenting the
artefacts' purpose (regulator-facing obligation→evidence traceability for the
event-driven-eu archetype), the content schema, the Phase A (BDFL-frozen) →
Phase B (Themis K.5) governance posture, the consumption protocol (the I.6
bundle's `regulatory/nis2/` subdirectory), and ≥ 3 RFC-2119 MUST NOT clauses.

### B.6.9.f — Test harness + docs

- New harness `.forge/scripts/tests/b6-9.test.sh` (L1 hermetic + L2 fixture
  bundle-integration), registered in `forge-ci.yml` `harness` matrix immediately
  after the `b7-5.test.sh` row (compliance family, ADR-B69-005).
- `index.yml` entry + `REVIEW.md` birth (new standard) + I.6 amendment entry.
- `docs/COMPLIANCE.md` new H2 `## Regulatory artefacts (NIS2 + DORA event-driven)`.
- CHANGELOG `[Unreleased]` entry.

### B.6.9.g — `forge-compliance.yml` unchanged

No new step in the I.5 reusable workflow (ADR-B69-007) ; the `nis2/` members ride
the existing `bundle` step (mirrors b7-5 ADR-B75-005).

## Cross-impact — b7-5 sibling-harness lock-step (LOAD-BEARING)

`b7-5.test.sh::_test_b75_001` asserts `.forge/compliance/nis2/` is NOT created
(a forward reservation written when NIS2 was Themis-territory). B.6.9 IS that
"later" for NIS2. Per the "shared reservation → update every sibling that
hard-pins it" discipline, this brick **amends `_test_b75_001` in lock-step**
(drop the `nis2/`-reserved check ; keep the `cra/` reservation). b6-9's harness
carries a positive `_test_b69_053` guard proving the edit is present. The b7-5
L2 fixtures build their own tmpdir (they `cp` only `ai-act/*` + `dora/*`), so
creating the live `nis2/` dir does NOT affect the b7-5 L2 member-count. The
same lock-step touches two stale prose statements : `ai-act-dora-artefacts.md`
(NIS2 "reserved" → shipped by B.6.9) and `docs/COMPLIANCE.md` (b7-5 section).

## Scope In

- `.forge/compliance/nis2/*` artefacts (incident-reporting, incident-report
  template, obligations index).
- `.forge/scripts/compliance/dora-roi-helper.sh` (DORA RoI submission helper).
- New standard `global/nis2-dora-eda-artefacts.md` v1.0.0 (≥ 6 H2, ≥ 3 MUST NOT).
- Additive `bundle.sh` extension (`"nis2"` in the walk tuple) + I.6 standard
  `compliance-artefacts-bundle.md` 1.1.0 → 1.2.0 lock-step.
- New harness `.forge/scripts/tests/b6-9.test.sh` (L1 + L2), CI matrix row.
- `index.yml` entry + `REVIEW.md` birth + I.6 amendment.
- `docs/COMPLIANCE.md` new H2 ; CHANGELOG entry.
- **Lock-step** : `b7-5.test.sh::_test_b75_001` amended (drop nis2-reserved) ;
  `ai-act-dora-artefacts.md` + `docs/COMPLIANCE.md` stale "reserved" prose fixed.

## Scope Out (Explicit Exclusions)

- **NOT the `cra/` sibling.** `.forge/compliance/cra/` stays reserved
  (commercial-binary CRA territory — a separate brick).
- **NOT a new SBOM generator.** `bin/forge-sbom.sh` already handles Rust
  `Cargo.lock` ; B.6.9 documents the wiring, it does not reinvent it (Q-004).
- **NOT the event-driven-eu scaffold/CI SBOM step.** The scaffold templates are
  B.6.2 ; the per-layer CI workflows (`forge-events.yml` …) are B.6.5 (sibling
  lane). B.6.9 is spec-time compliance artefacts.
- **NOT Themis (K.5) itself** (already shipped). This brick ships the frozen
  v1.0.0 artefacts Themis Phase B maintains ; every `[NEEDS CLARIFICATION]` is a
  Themis Phase-B work item.
- **NOT any fabricated legal text.** No NIS2/DORA article number, no precise
  window figure beyond the grounded "24h/72h" / "< 24h" / "30 avr 2026". Every
  regulatory specific is grounded-or-flagged (Article III.4).
- **NOT a constitutional amendment.** Articles III.4 / V / VIII.2 / IX.4 / XII
  preserved.
- **NOT the plan/roadmap resync.** `docs/new-archetypes-plan.md` rows +
  `.forge/product/roadmap.md` are DEFERRED (a separate maintainer resync ;
  collision avoidance across the 6 in-flight B.6 PRs — mirrors b7-5's T-INV
  deferral).
- **NOT the VERSION bump** (maintainer release task ; NFR-B69-005).

## Impact

- **Users affected** :
  - Adopters of `event-driven-eu` get a spec-time NIS2 incident-reporting +
    DORA-RoI obligation→evidence map, a fillable NIS2 incident-notification
    template, a DORA RoI helper for their NATS/Temporal/Postgres stack, and the
    artefacts ride the existing I.6 hand-off `.tgz` automatically.
  - Auditors receive the NIS2 + DORA artefacts in the same deterministic bundle.
  - Themis (K.5) gets a ready-to-maintain NIS2 artefact set + governance posture.
  - No impact on adopters not using event-driven-eu or not running the bundle.
- **Technical impact** : ≈ 9-10 new files (3 nis2 artefacts + helper + standard +
  harness + 6 change docs) + ≈ 6 modified (bundle.sh additive, I.6 standard,
  index.yml, REVIEW.md, COMPLIANCE.md, CHANGELOG) + 3 lock-step edits
  (b7-5.test.sh, ai-act-dora-artefacts.md, COMPLIANCE.md prose). **Effort `M`**.
- **Dependencies** : I.6 (`i6-compliance-artefacts`) ; b6-1-schema (the
  event-driven-eu component set) ; b7-5-ai-act (structural template + the
  dora/roi-register base the helper drives + the harness amended in lock-step) ;
  k5-themis (Phase-B maintainer). No new external dependency (Python stdlib +
  PyYAML already required by I.6).
- **Risk level** : **Low-Medium**. Spec-time documents + one helper script (no
  runtime service code). Real risks : (a) **legal-content hallucination** —
  mitigated by Article III.4 grounded-or-flagged + the `_test_b69_030`
  negative-grep + an Aegis/Demeter review pass ; (b) **b7-5 sibling-harness
  regression** — mitigated by the explicit lock-step amendment + re-running
  `b7-5.test.sh` at the final gate ; (c) **bundle determinism regression** —
  mitigated by re-running the L2 determinism test with the nis2 members.

## Constitution Compliance (v2.0.0)

- **Article I (TDD)** — RED harness first (Phase 1), artefacts flip GREEN
  incrementally (Phases 2-4), L2 fixtures + final gates (Phase 5).
- **Article II (BDD)** — auditor-receives-bundle + adopter-fills-incident-report
  Given/When/Then in `design.md`.
- **Article III.4 (anti-hallucination, LOAD-BEARING)** — Q-001..Q-005
  grounded-or-deferred ; `_test_b69_030` negative-grep guard ; Context7 NOT used
  for legal text.
- **Article V (audit trail)** — every task `[Story: FR-B69-*]` ; every artefact +
  standard + harness carry the `B.6.9 (b6-9-compliance)` audit anchor ; the I.6
  amendment recorded in REVIEW.md.
- **Article VIII.2 / IX.4** — the artefacts reference the archetype's grounded
  Temporal orchestration + Rust OTel tracing evidence surfaces ; they do not
  re-implement them.
- **Article XII (governance)** — the standard ENFORCES the content schema +
  Phase A/B governance ; the bundle contract extension follows
  `compliance-artefacts-bundle.md` SemVer (additive = minor) ; REVIEW.md
  append-only. No amendment.

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers in this proposal : none (the scope is
grounded). Legal specifics + design choices tracked in `open-questions.md`
(Q-001..Q-005 legal grounded-or-deferred ; Q-010..Q-015 design → ADR-B69-001..007).

---

**Gate** : Proposal created at `.forge/changes/b6-9-compliance/proposal.md`.
Proceed to → `specs.md`.
