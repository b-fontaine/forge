# Open Questions — k3-demeter

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: DPA declaration surface — ledger file vs `.forge.yaml` block vs both?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-K3-DEM-040..042 (DPA
  validation cluster)
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

Tier T1 (`compliance-tier.schema.json::x-tier-descriptions.T1`)
explicitly accepts non-EU SaaS components **provided** a DPA + SCC
+ complementary protections are in place. Demeter must therefore
verify the adopter has *declared* DPA presence. Three plausible
declaration surfaces :

- **Option A — ledger file** : `.forge/.forge-dpa-declared` plain
  text (mirrors `.forge/.forge-tier` shipped by J.8 ADR-J8-006).
  One line, content `T1: <date> <free-form ref>`. Trivial to
  read, trivial to grep, no parser dependency.
- **Option B — `.forge.yaml` block** : a structured `dpa:` map in
  the change-level or root-level `.forge.yaml` (e.g. `dpa: {
  declared: true, parties: [...], expires: 2027-01-01 }`).
  Schema-validatable, richer metadata.
- **Option C — both** : the ledger is the canonical signal,
  `.forge.yaml` carries optional richer metadata when adopters
  want it.

Lean **A** for parity with the `.forge-tier` ledger pattern J.8
already established (ADR-J8-006), and because Demeter does
**NOT** parse legal documents — it only verifies declaration
presence. Schema validation of structured DPA metadata risks
slipping into legal-document territory which the proposal scope
explicitly excludes.

Resolve at design time after a quick audit of how adopters
**actually** track DPA references today (likely : a Confluence
page or a `LEGAL/` directory). The Forge declaration is a
**proof-of-attestation**, not a re-implementation of legal
record-keeping.

### Resolution

**Resolved by ADR-K3-002** in `design.md`. Decision : **Option A
— ledger file** at `.forge/.forge-dpa-declared`. Plain text, one
line, content `T1: <ISO-8601-date> <free-form-ref>` with
mandatory trailing newline.

The ledger MIRRORS the J.8 `.forge/.forge-tier` pattern shipped
by ADR-J8-006 verbatim. Demeter reads via plain-text `cat` ; no
YAML parser dependency on the consumer side. Option B
(`.forge.yaml` structured block) was rejected because a
schema-validatable structured block invites reviewers to add
fields like `parties:`, `signatures:`, `expires:` which would
creep toward legal parsing — explicitly out of scope per
FR-K3-DEM-044. Option C (both) was rejected because doubling
the surface invites inconsistency.

Implementation : the surface is documented in
`.claude/agents/demeter.md::Checklists::DPA Validation`, in
`.forge/standards/global/data-stewardship-rules.md::DPA
declaration semantics`, and in `bin/forge-demeter-scan.sh`
(K3-RULE-002 fires when T1 + ⚠️-T1 component + ledger absent).

---

## Q-002: `cloud-act-publishers.yml` maintenance cadence — who, when, what triggers refresh?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-K3-DEM-070..074 (CLOUD
  Act detection cluster) ; NFR-K3-DEM-008
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

The cloud-act-publishers list is the **single point of trust** of
the scanner — false negatives understate exposure, false
positives annoy adopters. Three orthogonal questions :

- **Who curates** : Demeter agent itself (LLM-driven proposals,
  human-reviewed PR), Themis (K.5, compliance officer), or the
  Forge maintainer (BDFL per `GOVERNANCE.md`)?
- **What frequency** : aligned with the
  `global/standards-lifecycle.md` 12-month cadence shipped by
  T.4, or faster (e.g. 3-month rolling window for a list that
  tracks acquisitions / corporate restructuring)?
- **What triggers a mid-cycle refresh** : an explicit publisher
  acquisition (e.g. "publisher X acquired by US-jurisdiction
  parent in Q3"), an EU regulator update (e.g. an EDPB opinion
  shifting Schrems II interpretation), or a security advisory
  via the existing `forge audit` command (ARCHITECTURE-TARGET
  §12.4)?

Lean for : **Themis curates** (K.5 owns compliance per
`new-archetypes-plan` §1.4 line 355 — when K.5 ships in T7),
**6-month cadence** for the list (faster than 12-month standards
because acquisition velocity is higher), **mid-cycle refresh on
publisher acquisition / EDPB opinion**.

In the interim (between K.3 ship in T5 and K.5 ship in T7), the
maintainer (BDFL) curates with annual refresh. This is captured
in NFR-K3-DEM-008 + the standard's "Regeneration cadence"
section. Resolve at design time after deciding the
interim-vs-permanent split is acceptable.

### Resolution

**Resolved by ADR-K3-003** in `design.md`. Decision :
**two-phase governance** :

- **Phase A — Interim (T5 → T7, ~ 8 months)** : BDFL curates
  per `GOVERNANCE.md` ; 12-month default `expires_at` per
  `global/standards-lifecycle.md` ; trigger on explicit
  publisher acquisition or EDPB opinion shift.
- **Phase B — Post-K.5 / Themis ship (T7+)** : Themis curates
  via PR ; 6-month rolling cadence (faster than standards
  because acquisition velocity is higher) ; same triggers as
  Phase A plus Themis's monthly `forge review-standards`
  cycle.

The transition Phase A → Phase B is a single PR (Themis
shipped + `cloud-act-publishers.yml::maintained_by:` edited).
No data migration required. K.5 spec MUST reference this ADR.

Implementation :
`.forge/data/cloud-act-publishers.yml::maintained_by` records
"BDFL (interim — see standards/global/data-stewardship-rules.md)".
The standard's "Regeneration cadence" H2 documents both phases.

---

## Q-003: K3-RULE namespace — pre-allocate 10 rules now, or grow incrementally?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-K3-DEM-100..104 (rule
  catalogue cluster)
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

`j8-janus-rules` ADR-J8-004 set the `<MODULE>-RULE-NNN` format
and seeded `J8-RULE-001..003`. K.3 inherits the format and
allocates `K3-RULE-NNN`. Two strategies :

- **Option A — Pre-allocate 10 rules** : K3-RULE-001..010 are
  declared in the spec now, even if the implementation only
  fills the first 5. Clear long-term roadmap ; reviewers see the
  full vision ; gaps in the numbering are taboo (rule IDs are
  never reused per ADR-J8-004).
- **Option B — Grow incrementally** : ship K3-RULE-001..005 in
  this change. Future findings spawn K3-RULE-006..NNN in
  follow-up changes. Pro-incremental, less speculative.

Lean **B** for spec discipline — the proposal scope explicitly
excludes I.2 / I.3 / I.5 / I.6, and pre-allocating IDs for those
items would couple K.3 to scope that hasn't been specified.
Resolve at design time after enumerating the actual rules
needed by the BDD scenarios in specs.md.

The candidate K.3 seed catalogue (subject to design) :

- **K3-RULE-001** : tier mismatch — declared `compliance_tier:
  T3` but `cloud-act-publishers.yml` flags US-jurisdiction
  dependency.
- **K3-RULE-002** : DPA undeclared at T1 — adopter declared
  `--eu-tier T1` but no `.forge/.forge-dpa-declared` ledger.
- **K3-RULE-003** : tier downgrade refused — change introduces a
  new US-jurisdiction dependency in a project declared at T2 / T3.
- **K3-RULE-004** : data classification missing — domain entity
  carries PII per Demeter heuristics but no
  `data_classification:` block in its companion design doc.
- **K3-RULE-005** : Cargo.toml-only false-negative — `Cargo.toml`
  declares a dependency the lockfile does not pin (workspace
  drift) ; scanner refuses to classify until lockfile is
  regenerated.

5 rules cover the scoped functional requirements. Defer 006+ to
follow-up audits.

### Resolution

**Resolved by ADR-K3-005** in `design.md`. Decision : **Option B
— 5 seed rules, incremental growth**, namespace `K3-RULE-NNN`.
Seed catalogue :

- **K3-RULE-001** — US-jurisdiction publisher (FR-K3-DEM-120 ;
  tier-scaled severity per FR-K3-DEM-068).
- **K3-RULE-002** — DPA undeclared at T1 (FR-K3-DEM-121 ;
  severity High).
- **K3-RULE-003** — Tier downgrade refused (FR-K3-DEM-122 ;
  T2 → High, T3 → Critical).
- **K3-RULE-004** — Data classification missing (FR-K3-DEM-123 ;
  Medium ; PII heuristic per ADR-K3-006).
- **K3-RULE-005** — Cargo workspace drift (FR-K3-DEM-124 ;
  Medium).

Plus an operational guardrail emerging from NFR-K3-DEM-008 :

- **K3-RULE-006** — publisher list staleness
  (`expires_at < today` ; severity Medium ; FR-K3-DEM-073).

Future K.3 extensions append `K3-RULE-007..` ; future audit
modules use their own prefix (e.g. `K5-RULE-NNN` for Themis at
T7+). Per ADR-J8-004 inheritance, IDs are NEVER reused —
decommissioned rules carry `DEPRECATED`, the slot is not
recycled.

Implementation : the catalogue ships in three surfaces (kept in
sync) — `.claude/agents/demeter.md::Rule Catalogue`,
`.forge/standards/global/data-stewardship-rules.md::Rule
catalogue`, and `bin/forge-demeter-scan.sh` (the actual rule
firing logic).
