# Open Questions — b6-9-compliance

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.

Two classes of question:

  - LEGAL (Q-001..Q-005) — regulatory specifics this brick MUST NOT invent.
    "Context7 is for software libraries, not law." Each legal question is
    resolved by one of:
      (a) GROUNDED — the repo verifiably records the fact (cite the source);
      (b) DEFERRED-TO-THEMIS — the fact is NOT in the repo; the artefact carries
          a literal `[NEEDS CLARIFICATION: <q>]` marker flagged "Themis (K.5) to
          supply"; this brick does NOT answer it.
    DEFERRED-TO-THEMIS is the EXPECTED resolution for most legal questions.

  - DESIGN (Q-010..Q-016) — implementation choices resolved by an ADR in design.md.
-->

## ── Legal questions (Article III.4 — grounded-or-deferred, NEVER invented) ──

## Q-001: What are the NIS2 incident-reporting windows this archetype must support?

- **Status**: resolved — GROUNDED (24h/72h) + DEFERRED-TO-THEMIS (precise stage breakdown)
- **Raised in**: proposal.md §B.6.9.a ; specs.md FR-B69-NIS2-010
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

`nis2/incident-reporting.md` must state the NIS2 reporting windows. What can the
repo ground, and what must be deferred?

### Resolution

**GROUNDED** : the repo records the NIS2 reporting windows **verbatim** as
"reporting 24h/72h" in `docs/ARCHITECTURE-TARGET.md` §10.4 line 788
(`- **NIS2** : reporting 24h/72h [source: nis-2-directive.com, accessed 2026-04].`)
and mirrored in `docs/new-archetypes-plan.md` §7.1's I.6 bullet
("NIS2 reporting 24h/72h"). The Themis persona charter grounds an
"incident reporting < 24h" figure (`ARCHITECTURE-TARGET.md` §9.2 line 735). The
artefact cites these **exactly** and MUST NOT invent any other figure.

**DEFERRED-TO-THEMIS** : the repo does NOT record the *named* NIS2 reporting
stages (early warning / incident notification / final report) that map onto the
24h/72h windows, nor the competent-authority / CSIRT routing. The artefact marks
the precise stage breakdown with a `[NEEDS CLARIFICATION]` tagged
"Themis (K.5) to supply from the official NIS2 text". This brick does NOT invent
the stage names.

---

## Q-002: What is the DORA Register-of-Information (RoI) field schema for this stack?

- **Status**: resolved — GROUNDED (deadline + ICT-provider set) + DEFERRED-TO-THEMIS (authoritative field schema)
- **Raised in**: proposal.md §B.6.9.b ; specs.md FR-B69-DORA-010
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

The DORA RoI submission helper must emit register entries for this archetype's
ICT third-party providers. What can the repo ground?

### Resolution

**GROUNDED** : the repo records the DORA RoI ESA submission deadline verbatim —
"RoI à soumettre 30 avr 2026 ESA" (`ARCHITECTURE-TARGET.md` §10.4 line 789 with
its `[source: …, accessed 2026-04]` footnote) — and grounds the archetype's ICT
third-party stack in `.forge/schemas/event-driven-eu/1.0.0.yaml` `components:`
(NATS JetStream event-backbone, Temporal orchestration, Postgres event-store) +
`event_specifics.eu_sovereignty`. The helper enumerates those provider
**categories** as adopter-fillable entries.

**DEFERRED-TO-THEMIS** : the repo does NOT record the *authoritative* DORA RoI
mandatory-field schema (the ESA-prescribed templates / fields). The helper emits
a **starting structure** only and carries a `[NEEDS CLARIFICATION]` for the
authoritative field list, tagged "Themis (K.5) to supply". It reuses the b7-5
`dora/roi-register.template.yaml` base rather than forking it (ADR-B69-004).

---

## Q-003: Which NIS2 obligation classes does the repo ground for this archetype?

- **Status**: resolved — GROUNDED (incident-reporting + supply-chain transparency)
- **Raised in**: proposal.md §B.6.9.a ; specs.md FR-B69-NIS2-012
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

NIS2 imposes several obligation classes. Which does the repo ground so
`nis2/obligations-index.yaml` is faithful?

### Resolution

**GROUNDED** : the repo grounds exactly two NIS2 obligation classes it ties to
Forge evidence surfaces —
(1) **incident-reporting** (the 24h/72h windows, §10.4 + §9.2 charter) →
satisfied by the I.6 audit-ledger snapshot + the IX.4 Rust OTel tracing spans
(the archetype's SigNoz/OBI/Coroot observability, schema `observability`
component) ; and
(2) **supply-chain security / transparency** →
satisfied by the CycloneDX SBOM (`bin/forge-sbom.sh` over the Rust `Cargo.lock`)
which `compliance-artefacts-bundle.md` § Purpose grounds as the NIS2
supply-chain-transparency evidence surface.
The index maps these two → those surfaces and **stops there**. Ungrounded NIS2
pillars (detailed risk-management measures, governance/management-body
accountability) are flagged `needs-clarification` / `themis_owner: K.5`, NOT
asserted satisfied. No NIS2 Article number is written in the artefact text
(the grounding source is cited by document section, per Interdiction 1).

---

## Q-004: Does the SBOM item require new generator code for event-driven-eu?

- **Status**: resolved — GROUNDED (no new code; ride bin/forge-sbom.sh)
- **Raised in**: proposal.md §B.6.9.c ; specs.md FR-B69-SBOM-001
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

B.6.9 names "SBOM CycloneDX auto-generation". Does event-driven-eu need a new
SBOM generator?

### Resolution

**GROUNDED — no new generator.** `bin/forge-sbom.sh` (J.8.d) already parses
`Cargo.lock` (Rust) into a CycloneDX 1.5 SBOM (`_parse_cargo_lock`,
`pkg:cargo/...` purls) and event-driven-eu is a Rust backend. The I.6 bundle
already packs the SBOM as its `sbom/sbom.cdx.json` member. So the B.6.9 SBOM
deliverable is the **wiring documentation + obligation mapping** grounding that
event-driven-eu SBOM generation rides the existing `bin/forge-sbom.sh`
mechanism — NOT reinventing it (the brief: "wire the same mechanism in, don't
reinvent it"). No edit to `bin/forge-sbom.sh`. The archetype's scaffold/CI SBOM
step is B.6.2 / B.6.5 territory (sibling lanes).

---

## Q-005: Where do the event-driven-eu DORA artefacts live given b7-5 already filled `dora/`?

- **Status**: resolved — DESIGN via ADR-B69-004 (helper script, not a dora/ file)
- **Raised in**: proposal.md §B.6.9.b
- **Raised on**: 2026-07-10
- **Raised by**: @bfontaine

### Question

`.forge/compliance/dora/` already carries the b7-5 (ai-native-rag) DORA
artefacts, each pinned to the `B.7.5+B.7.8` audit anchor and gated by
`b7-5.test.sh::_test_b75_002` (per-file anchor) + `_test_b75_030` (per-file
negative-grep). Where does the B.6.9 DORA RoI submission helper live?

### Resolution

**ADR-B69-004** : the helper is a **script** `.forge/scripts/compliance/dora-roi-helper.sh`,
NOT a new file dropped under `.forge/compliance/dora/`. Adding a B.6.9-anchored
file to `dora/` would break the b7-5 harness's per-file `B.7.5+B.7.8` anchor
assertion (a sibling-harness regression). The helper DRIVES (reads, never forks)
the b7-5 `dora/roi-register.template.yaml` base and specialises it for the
event-driven-eu ICT third-party stack. This keeps `dora/` byte-stable for b7-5
and satisfies the "script/template" deliverable.

---

## ── Design questions (resolved via ADR in design.md) ──

## Q-010: `.forge/compliance/` layout — create `nis2/` now?

- **Status**: answered — ADR-B69-001
- **Raised in**: proposal.md §Solution
- **Raised on**: 2026-07-10

### Resolution

**ADR-B69-001** : create `.forge/compliance/nis2/` — the I.6-forward-declared
(`{nis2,dora,cra,ai-act}/`) sibling. `event-driven-eu`'s profile (§10.3 line
782) names **NIS2 + DORA + CRA** ; NIS2 is its primary regulatory surface, so
the `nis2/` sibling is filled here. `cra/` stays reserved (commercial-binary
territory). `ai-act/` + `dora/` are b7-5's (untouched).

---

## Q-011: Bundle wiring — extend `bundle.sh` for `nis2/` now?

- **Status**: answered — ADR-B69-002
- **Raised in**: proposal.md §B.6.9.d
- **Raised on**: 2026-07-10

### Resolution

**ADR-B69-002** : yes. Add `"nis2"` to the `bundle.sh` directory-walk tuple
(currently `("ai-act", "dora")`). The MANIFEST + tar loop consume
`sorted(members.keys())` unchanged, so `regulatory/nis2/*` is absorbed with no
change to the archive format or determinism recipe. SemVer-minor bump of the I.6
bundle contract `compliance-artefacts-bundle.md` 1.1.0 → 1.2.0, updated in the
SAME change with a REVIEW.md entry. Interdiction #3 (which forbade adding the
"still-reserved NIS2/CRA" artefacts to the bundle) is amended to remove NIS2
(now shipped) while keeping CRA reserved.

---

## Q-012: New standard vs extend b7-5's `ai-act-dora-artefacts.md`?

- **Status**: answered — ADR-B69-003
- **Raised in**: proposal.md §B.6.9.e
- **Raised on**: 2026-07-10

### Resolution

**ADR-B69-003** : new standard `global/nis2-dora-eda-artefacts.md`. b7-5's
`ai-act-dora-artefacts.md` is scoped to the `ai-native-rag` archetype's AI Act +
DORA content. B.6.9 governs the `event-driven-eu` archetype's NIS2 + DORA-EDA
content + the SBOM wiring posture — a distinct concern with distinct grounding.
Mirrors how I.2/I.6/b7-5 are separate standards in the compliance family.

---

## Q-013: Harness placement in `forge-ci.yml`?

- **Status**: answered — ADR-B69-005
- **Raised in**: proposal.md §B.6.9.f
- **Raised on**: 2026-07-10

### Resolution

**ADR-B69-005** : place `b6-9.test.sh --level 1,2` immediately after the
`b7-5.test.sh` row in the `harness` matrix — the compliance family cluster
(`i2`/`i6`/`i3`/`i5`/`b7-5`). B.6.9 extends the same I.6-reserved
`.forge/compliance/` layout and bumps the same I.6 bundle contract, so it belongs
with the compliance harnesses by substance (the `b6` prefix is by number only).
`--level 1,2` mirrors `i6`/`b7-5` (it carries L2 bundle fixtures).

---

## Q-014: Does `forge-compliance.yml` need a new step?

- **Status**: answered — ADR-B69-007
- **Raised in**: proposal.md §B.6.9.g
- **Raised on**: 2026-07-10

### Resolution

**ADR-B69-007** : NO. Once `bundle.sh` collects the `nis2/` members
(ADR-B69-002), the existing `bundle` step in the I.5 reusable
`forge-compliance.yml` packs them into the uploaded `.tgz` automatically. The
artefacts reach the auditor hand-off with zero workflow change; the 4-step
contract (`demeter`/`linter`/`sbom`/`bundle`) is preserved. Structural
validation of the artefacts lives in `b6-9.test.sh` (run by `forge-ci.yml`),
mirroring b7-5 ADR-B75-005.

---

## Q-015: How is the b7-5 sibling-harness `nis2-reserved` assertion handled?

- **Status**: answered — ADR-B69-006
- **Raised in**: proposal.md §Cross-impact
- **Raised on**: 2026-07-10

### Resolution

**ADR-B69-006** : lock-step amendment. `b7-5.test.sh::_test_b75_001` asserted
`.forge/compliance/nis2/` was NOT created (a forward reservation written when
NIS2 was Themis-territory). B.6.9 IS that "later" for NIS2, so the assertion is
amended in the SAME change: drop the `nis2/`-reserved check, keep the `cra/`
reservation. The b7-5 harness stays GREEN after the edit; b6-9's harness carries
a positive `_test_b69_053` guard asserting the lock-step edit is present. This is
the "shared reservation → update every sibling that hard-pins it" discipline
(the same lock-step b7-5 applied to the I.6 bundle-member count).
