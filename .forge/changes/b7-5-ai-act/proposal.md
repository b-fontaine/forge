# Proposal: b7-5-ai-act

<!-- Created: 2026-06-22 -->
<!-- Schema: default -->
<!-- Audit: B.7.5 + B.7.8 (docs/new-archetypes-plan.md §6.2 lines 2587-2595 — ai-native-rag AI-Act + DORA compliance artefacts) -->
<!-- Brick: #6 of the 9-brick B.7 chain (docs/new-archetypes-plan.md §0.12 line 2024) -->
<!-- Input: i6-compliance-artefacts (forward-stable bundle layout) + llm-gateway.md ("B.7.5 territory") -->

## Problem

`docs/new-archetypes-plan.md` §6.2 lists two adjacent B.7 items as the
regulatory layer of the `ai-native-rag` archetype :

- **B.7.5** (line 2587-2589) — "Templates compliance AI Act : classification
  de risque, transparence (model card jointe au build), évaluation biais
  (dataset cards), opt-out training. Effort : `M`."
- **B.7.8** (line 2594-2595) — "Compliance hooks : DORA + AI Act artefacts
  (incident reporting < 24h, SBOM, vuln handling, model evaluation reports).
  Effort : `M`."

This brick (#6 of the 9-brick B.7 chain, §0.12 line 2024 :
`b7-5-ai-act` = B.7.5 + B.7.8) lands those two items together because they
share one physical surface : the `.forge/compliance/{ai-act,dora}/` directory
tree that I.6 (`i6-compliance-artefacts`) deliberately deferred to **"Themis
territory (K.5, T7+)"**.

**Ground truth (re-read 2026-06-22, Article III.4) — what already exists :**

- **`.forge/compliance/` is empty.** I.6 shipped the deterministic `.tgz`
  bundle generator (`.forge/scripts/compliance/bundle.sh`) and forward-declared
  a stable layout `.forge/compliance/{nis2,dora,cra,ai-act}/`, but **shipped no
  file under it** (proposal.md "Scope Out" + ADR-I6-CA-002). The bundle's
  `members` dict (`bundle.sh:358`) and `MANIFEST` (computed over
  `sorted(members.keys())`, `bundle.sh:368`) absorb new members additively — a
  new `regulatory/` subdirectory drops in with **no bundle-format change**
  (ADR-I6-CA-002 : "Future Themis-territory artefacts drop into a new
  `regulatory/` subdirectory without renaming existing members").
- **The AI archetype's runtime compliance hooks already exist as scaffolded
  Rust** (`b7-2-scaffolder`, archived 2026-06-21) : the LLM gateway emits a
  prompt-audit record (Article IX.6), enforces tenant budgets + a kill switch,
  carries a non-AI fallback (Article XI.5) and PII consent (Article XI.6), and
  wires tier-aware refusal hooks. `llm-gateway.md` §"Prompt audit & observability"
  states explicitly : "Audit records are the evidence trail for budgets, abuse,
  and **the AI Act transparency obligations (B.7.5 territory)**" and §"Cross-refs"
  defers "AI Act / DORA artefacts — `b7-5-ai-act` (Themis territory)".
- **The regulatory facts the repo verifiably carries** live in
  `docs/ARCHITECTURE-TARGET.md` §10.4 ("Échéances réglementaires à coder dans
  `.forge/compliance/`") with source citations, mirrored in
  `docs/COMPLIANCE.md` §"Cross-references" and `global/compliance-tiers.md`
  §"Regulatory cross-references". The `ai-native-rag` compliance profile
  (§10.3 line 783) is **"RGPD + AI Act + DORA si finance"**, T1 ⚠️ (LLM externe)
  / T2 Mistral self-host / T3 vLLM EU.

So today : the **runtime evidence** the regulator wants (prompt-audit spans,
SBOM, tier posture) is produced by the scaffolded archetype, but there is **no
spec-time artefact** that (a) classifies the archetype's AI-Act risk posture,
(b) names the DORA obligations relevant to a finance-tier RAG deployment, or
(c) links the runtime evidence to those obligations so an auditor can trace
"obligation → where Forge produces the evidence". Nothing under
`.forge/compliance/` consumes the I.6 bundle layout. Themis (K.5) — the agent
that will maintain these artefacts on a rolling cadence — cannot ship until the
**artefact schema + initial content** it maintains exists.

This brick lands that schema + initial content for the **AI-Act + DORA subset**
relevant to the AI archetype, forward-stable so Themis (K.5) can later
consume/extend/refresh it without a layout break. It does **NOT** ship Themis
itself, and it does **NOT** touch the NIS2/CRA siblings (those stay deferred —
this brick scopes only the two regulations the `ai-native-rag` profile names).

## Solution

Ship a small, deterministic, **content-frozen** set of regulatory artefacts
under `.forge/compliance/{ai-act,dora}/`, wired into the existing I.6 bundle
generator via a new `regulatory/` subdirectory, governed by one new standard,
and proven by one new test harness. Five coordinated sub-modules :

### B.7.5/8.a — `.forge/compliance/ai-act/` artefacts

A directory of structured, human-and-machine-readable artefacts capturing the
EU AI Act obligations **relevant to a RAG/LLM archetype**, grounded ONLY in
what the repo already records (`ARCHITECTURE-TARGET.md` §10.3/§10.4,
`llm-gateway.md`, `rag-patterns.md`). Planned members (see `design.md` for the
exact schema) :

- `risk-classification.md` — the archetype's AI-Act risk posture (a RAG
  assistant over an organisation's own documents is a **limited-risk /
  transparency-obligation** system, NOT a prohibited or high-risk Annex-III
  system *by default*; the artefact records the classification rationale + the
  triggers that would escalate it to high-risk, and **defers any case the repo
  cannot ground to `[NEEDS CLARIFICATION]`**).
- `transparency-obligations.md` — the transparency duties the
  limited-risk classification triggers (users informed they interact with an AI
  system; AI-generated output is identifiable), linked to where the scaffolded
  archetype produces the evidence (the Qwik `fallbackUsed` indicator from
  `b7-2-scaffolder` FR-B7-2-020; the prompt-audit record IX.6).
- `model-card.template.md` + `dataset-card.template.md` — the
  B.7.5 "model card jointe au build" + "dataset cards (évaluation biais)"
  templates : empty, adopter-fillable skeletons mirroring the
  `forge-dpa-declared.template` precedent (header cites the audit item +
  remediation notes, body carries a canonical example block).
- `obligations-index.yaml` — a machine-parseable index mapping each AI-Act
  obligation the archetype carries → the Forge evidence surface that
  satisfies it (e.g. `transparency → Qwik fallbackUsed indicator + IX.6
  prompt-audit span`). This is the artefact Themis (K.5) will refresh.

### B.7.5/8.b — `.forge/compliance/dora/` artefacts

A directory capturing the DORA obligations relevant to a **finance-tier** RAG
deployment, grounded ONLY in `ARCHITECTURE-TARGET.md` §10.4 (DORA "appliqué
depuis 17 jan 2025, RoI à soumettre 30 avr 2026 ESA") + the Themis persona
charter (§9.2 line 735 : "incident reporting < 24h, SBOM, vuln handling").
Planned members :

- `incident-reporting.md` — the DORA major-ICT-incident reporting obligation
  the archetype must support, linked to where Forge produces the evidence
  (the I.6 audit-ledger snapshot, the prompt-audit span). The repo records
  "incident reporting < 24h" (§9.2 / §6.1.9 NIS2 24h/72h) — any precise DORA
  reporting-window figure NOT in the repo is `[NEEDS CLARIFICATION]`.
- `roi-register.template.yaml` — a skeleton for the DORA "Register of
  Information" (RoI) the §10.4 deadline references, adopter-fillable.
- `obligations-index.yaml` — same machine-parseable obligation → evidence
  mapping pattern as the AI-Act sibling.

### B.7.5/8.c — Standard `global/ai-act-dora-artefacts.md`

A new Markdown standard (mirroring `compliance-artefacts-bundle.md` /
`sbom-policy.md` / `compliance-tiers.md`) documenting : the artefacts' purpose
(regulator-facing obligation→evidence traceability for the AI archetype); the
content schema (the members above); the **content-frozen / Themis-maintained**
governance posture (the dates + obligations are frozen until Themis K.5 ships,
mirroring how `compliance-tiers.md` §"Governance — two phases" splits BDFL
Phase A from Themis Phase B); the consumption protocol (the I.6 bundle's
`regulatory/` subdirectory); interdictions (≥ 3 RFC-2119 MUST NOT, incl. "MUST
NOT fabricate a legal article number / deadline absent from the repo's grounded
sources").

### B.7.5/8.d — Bundle wiring (I.6 additive extension)

Extend `.forge/scripts/compliance/bundle.sh` so the `members` dict additionally
collects the `.forge/compliance/{ai-act,dora}/*` artefacts under a `regulatory/`
subdirectory (`regulatory/ai-act/…`, `regulatory/dora/…`), per the
ADR-I6-CA-002 forward-stable layout. The MANIFEST + determinism guarantee
absorb the new members automatically (sorted-keys). This is a **SemVer minor**
bump of the bundle contract per `compliance-artefacts-bundle.md` (adding bundle
members = minor). The I.6 standard's forward-compatibility note (FR-I6-CA-053)
is thereby realised.

### B.7.5/8.e — `forge-compliance.yml` wiring (IF the layout calls for it)

The I.5 reusable workflow (`forge-compliance.yml`) already runs the I.6 bundle
step, which — once wired in B.7.5/8.d — automatically packs the new regulatory
members into the uploaded `.tgz`. **No new workflow step is required** for the
artefacts to reach the auditor hand-off (they ride the existing `bundle` step).
A new step is added **only if** design concludes a standalone validation
(e.g. an `obligations-index.yaml` schema check) belongs in CI rather than the
harness — an open question for `design.md`. Default lean : NO new
`forge-compliance.yml` step; the harness + the bundle step suffice.

### B.7.5/8.f — Test harness + docs

- New harness `.forge/scripts/tests/b7-5.test.sh` (L1 hermetic + L2 fixture
  bundle-integration), registered in `forge-ci.yml` `harness` matrix after the
  I.5 row (adjacency : the regulatory artefacts extend the I.x compliance
  family; the b7-5 row sits with the compliance harnesses, not the b7 archetype
  harnesses — open question Q for design).
- `index.yml` entry + `REVIEW.md` birth for the new standard.
- `docs/COMPLIANCE.md` new H2 `## Regulatory artefacts (AI Act + DORA)`
  cross-linking the artefacts + the standard + the bundle's `regulatory/`
  subdirectory.
- `docs/new-archetypes-plan.md` rows B.7.5 + B.7.8 marked Done; §0.12 brick #6
  flipped; `.forge/product/roadmap.md` inventory delta; `CHANGELOG.md`.

## Scope In

- `.forge/compliance/ai-act/*` artefacts (risk classification, transparency
  obligations, model-card + dataset-card templates, obligations index).
- `.forge/compliance/dora/*` artefacts (incident-reporting obligation, RoI
  register template, obligations index).
- New standard `global/ai-act-dora-artefacts.md` v1.0.0 (≥ 6 H2, ≥ 3 MUST NOT).
- Additive extension of `.forge/scripts/compliance/bundle.sh` : new
  `regulatory/{ai-act,dora}/…` bundle members (SemVer minor of the bundle
  contract; I.6 standard `## Bundle content schema` table + member-count
  assertions updated in lock-step).
- New harness `.forge/scripts/tests/b7-5.test.sh` (L1 + L2), CI matrix row.
- `index.yml` entry + `REVIEW.md` birth.
- `docs/COMPLIANCE.md` new H2; plan + roadmap + CHANGELOG inventory.

## Scope Out (Explicit Exclusions)

- **NOT Themis (K.5) itself.** The agent persona, the `forge review-standards`
  monthly cycle, and the rolling regulatory-deadline maintenance stay in the
  K.5 brick. This brick ships the **artefacts Themis will maintain**, frozen at
  v1.0.0 BDFL Phase A, forward-stable for Themis Phase B (mirrors
  `compliance-tiers.md` §"Governance — two phases").
- **NOT the NIS2 / CRA siblings** under `.forge/compliance/{nis2,cra}/`. The
  `ai-native-rag` profile (§10.3 line 783) names only **AI Act + DORA**. NIS2
  applies to the `event-driven-eu` profile (§10.3 line 782) and CRA to
  commercially-distributed binaries (§10.3 line 784) — separate bricks /
  archetypes. The bundle's `regulatory/` layout reserves `nis2/` + `cra/`
  siblings additively for those.
- **NOT runtime Janus AI refusal rules (J.8.c)** — `b7-9-janus-ai` (brick #5).
  This brick references the tier-aware refusal hooks the scaffolder already
  ships; it does not add runtime enforcement.
- **NOT any fabricated legal text.** No AI-Act article number, no DORA RTS
  reference, no precise reporting-window figure is invented. Every regulatory
  specific is either (a) grounded in a cited repo source
  (`ARCHITECTURE-TARGET.md` §10.4 with its `[source: …, accessed 2026-04]`
  footnotes) or (b) flagged `[NEEDS CLARIFICATION]` in `open-questions.md`
  (Article III.4 — "Context7 is for software libraries, not law").
- **NOT a constitutional amendment.** Articles III.4, V, IX.6, XI, XII
  preserved; no Article touched.
- **NOT a change to the I.6 bundle's archive format / determinism recipe.**
  The extension is purely additive members; ADR-I6-CA-001 (`.tgz` gzip POSIX
  tar) + the `SOURCE_DATE_EPOCH` two-step idiom are reused verbatim.
- **NOT the model-evaluation *report generation*.** B.7.8 names "model
  evaluation reports" — this brick ships the **model-card / dataset-card
  templates** (B.7.5 "model card jointe au build" + "dataset cards") an adopter
  fills; automated report generation (running an eval suite + emitting a report)
  is out (a future Pythia/`b7-pythia` K.2 capability — open question for design).

## Impact

- **Users affected** :
  - Adopters of the `ai-native-rag` archetype get a spec-time obligation→evidence
    map for AI Act + DORA, plus fillable model/dataset-card templates, plus the
    artefacts ride the existing I.6 hand-off `.tgz` automatically.
  - Auditors / regulator counter-parties receive the AI-Act + DORA artefacts in
    the same deterministic bundle they already receive the tier matrix + SBOM in.
  - Themis (K.5, T7+) when it ships gets a ready-to-maintain artefact set + a
    governance posture (Phase A frozen → Phase B Themis-maintained) already
    encoded in the standard — no green-field design.
  - No impact on adopters not using the AI archetype or not running the bundle.
- **Technical impact** : ≈ 9-11 new files (artefacts + templates + standard +
  harness) + ≈ 6 modified (bundle.sh additive, i6 standard table + member
  count, index.yml, REVIEW.md, COMPLIANCE.md, plan/roadmap/CHANGELOG). **Effort
  `M` + `M` = `M`-`L`** (the two §6.2 items are both `M`; shared surface).
- **Dependencies** :
  - **I.6** `i6-compliance-artefacts` archived 2026-05-12 — ships the bundle
    generator + the forward-stable `regulatory/` layout this brick fills.
  - **I.2** `i2-compliance-tiers` archived 2026-05-12 — the tier gradient
    (T1/T2/T3) the artefacts cite for the archetype profile.
  - **B.7.3** `b7-standards` archived 2026-06-13 — `llm-gateway.md` /
    `rag-patterns.md` whose IX.6 / XI.5 / XI.6 hooks the artefacts link to.
  - **B.7.2** `b7-2-scaffolder` archived 2026-06-21 — the runtime evidence
    surfaces (prompt-audit span, Qwik `fallbackUsed` indicator) the
    obligations-index maps to.
  - No new external dependency. Bundle extension reuses the `python3` stdlib +
    PyYAML already required by I.6.
- **Risk level** : **Low-Medium**. The artefacts are spec-time documents +
  templates (no runtime code). The only real risks are (a) **legal-content
  hallucination** — mitigated by the Article III.4 protocol (grounded-or-flagged,
  several `[NEEDS CLARIFICATION]` expected) + an Aegis/Demeter review pass; and
  (b) **bundle determinism regression** from the additive members — mitigated by
  re-running the I.6 L2 determinism test against the extended member set.

## Constitution Compliance (v2.0.0)

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 writes `b7-5.test.sh` with all L1+L2
stubs returning `_not_implemented` (full RED witness). Phases 2-4 ship the
artefacts / standard / bundle wiring / docs, flipping tests GREEN incrementally.
Phase 5 runs final gates incl. the re-run I.6 determinism test.

### Article II — BDD

The user-facing flow (the auditor receives AI-Act + DORA artefacts in the
hand-off bundle; the adopter fills a model card) gets Given/When/Then scenarios
in `specs.md`.

### Article III — Specs Before Code

This proposal → specs → design → tasks before any artefact is authored.

### Article III.4 — `[NEEDS CLARIFICATION]` Discipline (LOAD-BEARING HERE)

Every regulatory specific is grounded in a cited repo source or flagged. The
proposal raises (and `open-questions.md` tracks) the legal questions the repo
cannot answer — expected several (precise AI-Act risk-tier mapping, exact DORA
reporting windows, whether a finance-tier RAG triggers high-risk Annex-III).
Context7 is NOT used for legal text.

### Article V — Audit Trail

Every task tagged `[Story: FR-B75-AA-XXX]`. Each artefact + the standard +
the harness carry the `<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->` anchor.

### Article IX.6 / XI.5 / XI.6 — AI hooks

The artefacts do not re-implement these; they **link to** the scaffolded
runtime hooks (`b7-2-scaffolder`) as the evidence surfaces satisfying the
transparency / fallback / PII obligations.

### Article XII — Governance

The standard ENFORCES the artefacts' content schema + the Phase A (frozen) →
Phase B (Themis) governance posture. It does NOT amend any Article. Bundle
contract extension follows `compliance-artefacts-bundle.md` SemVer (additive =
minor).

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers in this `proposal.md` : none (the scope
is grounded). The legal-specificity questions + the design questions are tracked
in `open-questions.md` (Q-001 … Q-00n) and resolved (legal : grounded-or-deferred;
design : ADR) before authoring — several legal items are expected to remain
**deferred to Themis (K.5)** rather than answered here.

---

**Gate** : Proposal created at `.forge/changes/b7-5-ai-act/proposal.md`. Review
and confirm before proceeding to → `/forge:specify b7-5-ai-act`.
