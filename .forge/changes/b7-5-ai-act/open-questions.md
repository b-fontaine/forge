# Open Questions — b7-5-ai-act

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.

This file carries TWO classes of question:

  - LEGAL (Q-001..Q-005) — regulatory specifics this brick MUST NOT invent.
    Per the brief: "Context7 is for software libraries, not law." Each legal
    question is resolved by one of:
      (a) GROUNDED — the repo verifiably records the fact (cite the source);
      (b) DEFERRED-TO-THEMIS — the fact is NOT in the repo; the artefact carries
          a literal `[NEEDS CLARIFICATION: <q>]` marker and the obligation is
          flagged "Themis (K.5) to supply"; this brick does NOT answer it.
    DEFERRED-TO-THEMIS is the EXPECTED resolution for most legal questions —
    forward-stability for Themis is the whole point of the brick.

  - DESIGN (Q-010..Q-014) — implementation choices resolved by an ADR in design.md.
-->

## ── Legal questions (Article III.4 — grounded-or-deferred, NEVER invented) ──

## Q-001: What AI-Act risk class does an `ai-native-rag` deployment fall into?

- **Status**: resolved — GROUNDED (posture) + DEFERRED-TO-THEMIS (precise mapping)
- **Raised in**: proposal.md §B.7.5/8.a ; specs.md FR-B75-AA-010
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

The artefact `risk-classification.md` must state the archetype's AI-Act risk
class. What can the repo ground, and what must be deferred?

### Resolution

**GROUNDED** : `docs/ARCHITECTURE-TARGET.md` §10.3 line 783 records the
`ai-native-rag` compliance profile as **"RGPD + AI Act + DORA si finance"** —
i.e. the AI Act applies to this archetype. `global/llm-gateway.md` records that
prompt-audit records are "the evidence trail for … the AI Act **transparency
obligations** (B.7.5 territory)". So the repo grounds that the archetype carries
**AI-Act transparency obligations** (the obligation class associated with
limited-risk / interactive AI systems).

**DEFERRED-TO-THEMIS** : the repo does NOT record the AI Act's *named risk
categories* (prohibited / high-risk Annex-III / limited-risk / minimal), nor
which one a given RAG deployment lands in, nor the Article numbers. The artefact
therefore states the **transparency-obligation posture as grounded**, lists the
**escalation triggers** that a deployer must self-assess (e.g. the RAG system is
used for a use-case the AI Act treats differently), and marks the precise
risk-category mapping + Article citations with
`[NEEDS CLARIFICATION: AI Act risk-category mapping + Article numbers — Themis (K.5) to supply from the official AI Act text; not in the repo's grounded sources]`.
**This brick does NOT invent the mapping.**

---

## Q-002: What is the exact DORA major-incident reporting window?

- **Status**: resolved — GROUNDED (obligation exists) + DEFERRED-TO-THEMIS (exact window)
- **Raised in**: proposal.md §B.7.5/8.b ; specs.md FR-B75-DO-010
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

`dora/incident-reporting.md` must describe the DORA incident-reporting
obligation. What window figure can the repo ground?

### Resolution

**GROUNDED** : the repo records an incident-reporting obligation exists and a
"< 24h" figure in the **Themis persona charter** context : `ARCHITECTURE-TARGET.md`
§9.2 line 735 ("Auto-check NIS2/DORA/CRA artifacts (**incident reporting < 24h**,
SBOM, vuln handling)") and §6.1.9 / §10.4 (NIS2 "reporting 24h/72h"). DORA itself
is recorded as "appliqué depuis 17 jan 2025, RoI à soumettre 30 avr 2026 ESA"
(§10.4 line 789-790, `[source: cloudsecurityalliance.org/…, accessed 2026-04]`).

**DEFERRED-TO-THEMIS** : the repo does NOT separate the DORA-specific reporting
windows (initial / intermediate / final notification deadlines under DORA's RTS)
from the NIS2 24h/72h figures. The artefact states the obligation as grounded
("a major ICT-related incident must be reported to the competent authority;
Forge's evidence surface is the I.6 audit-ledger snapshot + the IX.6 prompt-audit
span"), cites the §10.4 DORA RoI deadline verbatim, and marks the precise
DORA notification windows with
`[NEEDS CLARIFICATION: DORA major-incident notification windows (initial/intermediate/final) — Themis (K.5) to supply from the official DORA RTS; the repo records only the generic "< 24h" charter figure + the RoI 30 Apr 2026 deadline]`.

---

## Q-003: Does a finance-tier RAG deployment trigger AI-Act high-risk obligations?

- **Status**: resolved — DEFERRED-TO-THEMIS
- **Raised in**: proposal.md §B.7.5/8.a ; specs.md FR-B75-AA-011
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

The archetype profile says "DORA si finance". Finance is a sensitive sector —
does a RAG deployment in finance cross into AI-Act high-risk territory?

### Resolution

**DEFERRED-TO-THEMIS.** The repo records the DORA-if-finance trigger but says
nothing about AI-Act high-risk classification for finance use-cases. This is a
legal determination the framework MUST NOT make. The `risk-classification.md`
artefact lists "deployed in a regulated/finance context" as an **escalation
trigger the deployer must self-assess with counsel**, and marks the AI-Act
high-risk determination with
`[NEEDS CLARIFICATION: whether a finance-sector RAG deployment is AI-Act high-risk (Annex III) — deployer + counsel determination; Themis (K.5) to track the regulatory position; not framework-determinable]`.

---

## Q-004: What dataset-bias-evaluation obligations does the AI Act impose?

- **Status**: resolved — GROUNDED (template scope) + DEFERRED-TO-THEMIS (legal duty)
- **Raised in**: proposal.md §B.7.5/8.a ; specs.md FR-B75-AA-020
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

B.7.5 names "évaluation biais (dataset cards)". What can the dataset-card
template legitimately assert?

### Resolution

**GROUNDED** : the plan item (§6.2 line 2588) names "dataset cards" as the
deliverable — so a **fillable dataset-card template** is in-scope and grounded
as a Forge deliverable. The template is an adopter-fillable skeleton (model
provenance, training-data description, known-bias notes, evaluation method),
mirroring the structure of established model/dataset-card practice WITHOUT
asserting a specific legal duty.

**DEFERRED-TO-THEMIS** : the *specific AI-Act articles* mandating bias
evaluation, and *which* deployments they bind, are not in the repo. The template
header notes the duty source is
`[NEEDS CLARIFICATION: specific AI Act bias-evaluation obligation + Article — Themis (K.5) to supply; the template provides the structure, not the legal trigger]`.

---

## Q-005: Is "transparency" the only AI-Act obligation class to capture, or also logging/record-keeping?

- **Status**: resolved — GROUNDED
- **Raised in**: proposal.md §B.7.5/8.a ; specs.md FR-B75-AA-012
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

The AI Act imposes several obligation classes. Which does the repo ground for
this archetype, so the `obligations-index.yaml` is faithful?

### Resolution

**GROUNDED** : the repo grounds exactly two AI-related evidence surfaces it ties
to AI-Act obligations — (1) **transparency** (`llm-gateway.md` :
"AI Act transparency obligations"; the Qwik `fallbackUsed` indicator,
`b7-2-scaffolder` FR-B7-2-020) and (2) **logging / record-keeping** (the IX.6
prompt-audit record : model, tenant, tier, token counts, latency, provider,
fallback flag — `llm-gateway.md` §"Prompt audit"). The `obligations-index.yaml`
maps these two obligation classes → those two evidence surfaces and **stops
there** : it does NOT enumerate AI-Act obligation classes the repo does not
ground (conformity assessment, CE marking, post-market monitoring), which are
flagged as `[NEEDS CLARIFICATION: … — Themis (K.5)]` placeholders in the index
rather than asserted as satisfied.

---

## ── Design questions (resolved via ADR in design.md) ──

## Q-010: `.forge/compliance/` directory layout — per-regulation vs flat?

- **Status**: answered — ADR-B75-001
- **Raised in**: proposal.md §Solution
- **Raised on**: 2026-06-22

### Question

Where do the artefacts live : `.forge/compliance/{ai-act,dora}/…` (per-regulation
subdirectories, the I.6 forward-declared layout) vs a flat
`.forge/compliance/regulatory.md`?

### Resolution

**ADR-B75-001** : per-regulation subdirectories
`.forge/compliance/{ai-act,dora}/…`. This is the **exact layout I.6
forward-declared** (`{nis2,dora,cra,ai-act}/` — ADR-I6-CA-002 + the I.6 proposal
"Scope Out"). Honouring it means Themis (K.5) and the NIS2/CRA siblings drop in
additively. The bundle's `regulatory/` subdirectory mirrors it
(`regulatory/ai-act/…`, `regulatory/dora/…`).

---

## Q-011: Bundle wiring — extend `bundle.sh` now, or ship artefacts inert?

- **Status**: answered — ADR-B75-002
- **Raised in**: proposal.md §B.7.5/8.d
- **Raised on**: 2026-06-22

### Question

Do we wire the new artefacts into the I.6 bundle now (SemVer-minor bump of the
bundle contract), or ship them under `.forge/compliance/` inert and let a later
brick wire them?

### Resolution

**ADR-B75-002** : wire now. I.6 explicitly built the bundle to absorb these
additively (FR-I6-CA-053 forward-compatibility note + ADR-I6-CA-002
`regulatory/` reservation). Shipping the artefacts without wiring them would
leave the I.6 forward-pointer unrealised and the auditor hand-off incomplete.
The bundle gains `regulatory/{ai-act,dora}/…` members; the I.6 standard's
`## Bundle content schema` table + member-count test assertions are updated in
the SAME change (lock-step, per the I.6 "adding a member = minor" rule). The
archive format + determinism recipe (ADR-I6-CA-001) are untouched.

---

## Q-012: Standard placement — new `global/` standard vs extend `compliance-artefacts-bundle.md`?

- **Status**: answered — ADR-B75-003
- **Raised in**: proposal.md §B.7.5/8.c
- **Raised on**: 2026-06-22

### Question

Does the regulatory-artefacts contract get its own standard, or extend the
existing I.6 bundle standard?

### Resolution

**ADR-B75-003** : new standard `global/ai-act-dora-artefacts.md`. The I.6
standard governs the **bundle mechanism** (determinism, members, hand-off); this
brick governs the **regulatory content + its Phase A/B governance** — a distinct
concern with a distinct review cadence (Themis-maintained). Mirrors how I.2
(`compliance-tiers.md`) and I.6 (`compliance-artefacts-bundle.md`) are separate
standards in the same family. The I.6 standard gains only the additive
bundle-member table rows.

---

## Q-013: Harness placement in `forge-ci.yml` — with the I.x compliance harnesses or the b7 archetype harnesses?

- **Status**: answered — ADR-B75-004
- **Raised in**: proposal.md §B.7.5/8.f
- **Raised on**: 2026-06-22

### Question

`forge-ci.yml` orders harnesses load-bearingly (siblings assert adjacency). Does
`b7-5.test.sh` sit after `i5.test.sh` (compliance family) or after the b7
archetype harnesses?

### Resolution

**ADR-B75-004** : place `b7-5.test.sh --level 1,2` immediately after
`i5.test.sh` in the `harness` matrix. The brick extends the **I.x compliance
family** (it fills the I.6-reserved `.forge/compliance/` layout and bumps the
I.6 bundle contract), so its harness belongs with the compliance harnesses
(`i2`/`i6`/`i3`/`i5`), not the archetype-mechanics harnesses (`b7-1`/`b7-2a`/
`b7-2`/`b7-3`). The `--level 1,2` mirrors `i6.test.sh` (it carries an L2 bundle
fixture). Keeps `forge-ci.yml` under the NFR-CI-002 300-line budget (currently
293 → ~294).

---

## Q-014: Does `forge-compliance.yml` need a new validation step?

- **Status**: answered — ADR-B75-005
- **Raised in**: proposal.md §B.7.5/8.e
- **Raised on**: 2026-06-22

### Question

Do the new artefacts need a dedicated step in the I.5 reusable
`forge-compliance.yml` workflow, or do they ride the existing `bundle` step?

### Resolution

**ADR-B75-005** : NO new `forge-compliance.yml` step. Once `bundle.sh` collects
the regulatory members (ADR-B75-002), the existing `bundle` step in
`forge-compliance.yml` automatically packs them into the uploaded `.tgz` — the
artefacts reach the auditor hand-off with zero workflow change. Validation of
the artefacts' structure (e.g. `obligations-index.yaml` well-formedness) lives in
the `b7-5.test.sh` harness (run by `forge-ci.yml`), not in the reusable
adopter-facing workflow. This keeps `forge-compliance.yml` minimal and its
4-step contract (`demeter`/`linter`/`sbom`/`bundle`) stable.
