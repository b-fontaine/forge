# Standard — Data Stewardship Rules

<!-- Audit: K.3 (k3-demeter, FR-K3-DEM-083) -->
<!-- Trigger: demeter, data-steward, dpa, cloud-act, schrems, t1, t2, t3, dependency-jurisdiction, k3-rule -->

## Purpose

This standard documents the **data-stewardship rules** Forge
adopters must satisfy to operate under EU compliance posture.
The rules implement the requirements of :

- **Schrems II** (CJEU C-311/18, 2020) — non-EU data transfers
  require Standard Contractual Clauses + supplementary measures
  + an EDPB-aligned transfer impact assessment.
- **CLOUD Act** (18 U.S.C. §2713, 2018) — US authorities can
  compel US-jurisdiction publishers to disclose data regardless
  of physical storage location, creating a structural
  incompatibility with strict EU data-residency.
- **RGPD** (Regulation (EU) 2016/679) — Article 28 data
  processing agreement (DPA) and Article 32 security measures
  apply when third-party processors touch personal data.

The Demeter agent (`.claude/agents/demeter.md`) is the
reference implementation. The scanner script
`bin/forge-demeter-scan.sh` is the deterministic check surface.
The deny-list at `.forge/data/cloud-act-publishers.yml` is the
single source of truth for jurisdiction classification.

## Rule catalogue

| Rule ID       | Trigger                                                         | Severity                                          | Reference                                  |
|---------------|-----------------------------------------------------------------|---------------------------------------------------|--------------------------------------------|
| `K3-RULE-001` | Lockfile dep resolves to deny-listed US publisher               | T1 -> Informational ; T2 -> High ; T3 -> Critical | FR-K3-DEM-120 ; ADR-K3-005                 |
| `K3-RULE-002` | `compliance_tier=T1` + ⚠️-T1 component + no `.forge-dpa-declared` | High                                            | FR-K3-DEM-121 ; ADR-K3-002                 |
| `K3-RULE-003` | Diff introduces new US dep at T2 or T3                          | T2 -> High ; T3 -> Critical                       | FR-K3-DEM-122 ; ADR-K3-005                 |
| `K3-RULE-004` | Entity carries PII per heuristic ; no `data_classification:`    | Medium                                            | FR-K3-DEM-123 ; ADR-K3-006                 |
| `K3-RULE-005` | `Cargo.toml` present but `Cargo.lock` absent                    | Medium                                            | FR-K3-DEM-124 ; ADR-K3-005                 |
| `K3-RULE-006` | `cloud-act-publishers.yml::expires_at < today`                  | Medium                                            | FR-K3-DEM-073 ; ADR-K3-003                 |

The full rule body (rationale, evidence pattern, remediation)
lives in `.claude/agents/demeter.md::Rule Catalogue`. The
runtime registry
(`.forge/data/cloud-act-publishers.yml::ecosystems.*`) is the
single source of truth consulted at scan time.

The catalogue is **incremental** per ADR-K3-005 : new
K3-RULE-NNN entries append in monotonic order. IDs are NEVER
reused (decommissioned rules carry `DEPRECATED`). The
`K3-RULE-*` namespace inherits the `<MODULE>-RULE-NNN` format
from ADR-J8-004 — collision with the J.8 namespace is
syntactically impossible.

## Adoption path

Demeter's check surface is layered : adopters can opt in
incrementally without committing to the full review pipeline at
once.

**Minimum viable adoption** (T2 / T3 projects) :

1. Declare the compliance tier in `.forge/.forge-tier` (one
   line, value in `{T1, T2, T3}`).
2. Run `bash bin/forge-demeter-scan.sh --target $(pwd)
   --tier T2` (or `T3`) at PR time, fail the build on exit
   code 3.
3. Review findings ; either replace flagged dependencies or
   formally downgrade the declared tier with audit trail.

**Full adoption** (T1 projects with regulated workloads) :

1. Steps 1-3 above.
2. Add `.forge/.forge-dpa-declared` ledger when ⚠️-T1
   components are in scope (one line, content `T1: <ISO-8601-date>
   <free-form-ref>`).
3. Wire Demeter into the Janus cross-layer review at Step 9
   (the dispatch is automatic — Janus reads
   `.forge/.forge.yaml::layers:` and routes accordingly).
4. Once Themis (K.5, T7+) ships, regulatory deadlines + EDPB
   opinion windows are tracked at the regulatory layer ;
   Themis consumes Demeter's findings.

The forthcoming `forge-compliance.yml` GitHub Actions workflow
template (deferred to a future I.5 / I.6 change per
`docs/new-archetypes-plan.md` §9 line 779) will codify the
canonical wiring once Themis ships. In the interim adopters
write their own.

## DPA declaration semantics

The `.forge/.forge-dpa-declared` ledger is a
**proof-of-attestation** surface, NOT legal-document parsing.
Per ADR-K3-002 :

```
T1: <ISO-8601-date> <free-form-ref>
```

with mandatory trailing newline. Worked example :

```
T1: 2026-04-15 LegalOps-Confluence-DPA-2026-Q2
```

**Demeter does NOT** :

- parse DPA legal text ;
- verify Standard Contractual Clauses ;
- check signature authenticity ;
- inspect counterparty identity.

These are **legal-domain work**, out of scope for K.3 per
FR-K3-DEM-044. The ledger is a self-declared attestation
surface ; the adopter's legal team owns the underlying DPA
document.

The ledger format MIRRORS the J.8 `.forge/.forge-tier` pattern
shipped by ADR-J8-006 verbatim. Both ledgers live in `.forge/`
(per-project, not committed by default — adopters decide).
Demeter reads via plain-text `cat` ; no YAML parser
dependency.

**Staleness check** : Demeter parses the ISO-8601 date and
emits a `K3-RULE-002a` Medium finding when `today − date > 13
months` (RGPD review cycle + 1 month grace). Stale ledgers do
NOT block the build but surface as concerns.

## Extending the catalogue

New `K3-RULE-NNN` rules follow the J.8 precedent (mirroring
`janus-orchestration-rules.md::Extending the catalogue`) :

1. **Spec** — the rule MUST be motivated by a specific
   FR-K3-DEM-NNN entry in a future K.3 follow-up change. No
   speculative rules.
2. **ADR** — if the rule introduces a new design decision (new
   data surface, new heuristic, new tier-scaling formula), an
   ADR is required.
3. **Adoption path** — every rule MUST point to an actionable
   remediation. Adopters reading the finding know what to do.
4. **Test coverage** — the rule MUST have at least one L1
   harness test in `.forge/scripts/tests/k3.test.sh` asserting
   the rule fires when the trigger condition is met.
5. **Catalogue update** — the rule appends to BOTH the persona
   file (`.claude/agents/demeter.md::Rule Catalogue`) AND this
   standard's catalogue table. Both surfaces stay in sync.

Decommissioning a rule : mark the row `DEPRECATED` in both
catalogue tables ; the slot is NOT recycled. Future rule IDs
monotonically increase.

## Regeneration cadence

The `.forge/data/cloud-act-publishers.yml` deny-list ages
faster than the rest of the standards corpus because publisher
acquisitions and corporate restructuring outpace standards
drift. Per ADR-K3-003 :

**Phase A — Interim (T5 ship → T7 ship, ~ 8 months)** :

- WHO : BDFL (per `GOVERNANCE.md`).
- FREQUENCY : 12-month default `expires_at` per
  `global/standards-lifecycle.md`.
- TRIGGER : explicit publisher acquisition (e.g.
  `crates.io` publisher acquired by US-jurisdiction parent),
  EDPB opinion shifting Schrems II interpretation, security
  advisory.

**Phase B — Post-K.5 / Themis ship (T7+)** :

- WHO : Themis agent (proposes deny-list edits via PR).
- FREQUENCY : 6-month rolling cadence (faster than standards
  because acquisition velocity is higher).
- TRIGGER : same as Phase A, plus Themis's monthly
  `forge review-standards` cycle (per
  `docs/new-archetypes-plan.md` §1.4 row K.5).

The transition Phase A → Phase B is a single PR (Themis
shipped + `cloud-act-publishers.yml::maintained_by:` edited).
No data migration required.

Edits to `cloud-act-publishers.yml` MUST :

- bump `version:` per SemVer (any deny-list addition is a
  minor bump ; structural schema change is a major bump) ;
- refresh `last_reviewed:` to the edit date ;
- recompute `expires_at:` per the active phase's cadence ;
- update `maintained_by:` only at the Phase A → B transition.

Demeter emits a `K3-RULE-006` Medium finding when
`expires_at < today` so adopters detect a stale list before
trusting its verdict.

## Constitutional Compliance

This standard implements (does not amend) :

- **Article III.4** (anti-hallucination) — Demeter emits
  `[NEEDS CLARIFICATION:]` instead of guessing on ambiguous
  classifications. The four trigger conditions per
  NFR-K3-DEM-009 are documented in
  `.claude/agents/demeter.md::Anti-Hallucination Protocol`.
- **Article V** (audit trail) — every finding carries
  `K3-RULE-NNN` + structured JSON shape per FR-K3-DEM-071.
- **Article IX** (security / observability cross-cutting
  surface) — data-stewardship is the regulatory complement to
  Aegis's vulnerability posture.
- **Article XI.1** (agent-native) — Demeter is a first-class
  agent persona file.
- **Article XI.3** (schema-driven) — Demeter outputs structured
  JSON ; no opaque LLM-generated content consumed downstream.
- **Article XI.5** (mandatory fallback) — offline mode per
  FR-K3-DEM-070 is the network-unavailable fallback.
- **Article XI.6** (privacy / data minimisation) — the PII
  heuristic operates on field NAMES only ; no actual PII data
  is read or transmitted.
- **Article XII** (governance) — publisher-list maintainer
  delegated to BDFL (Phase A) and Themis (Phase B). Amendments
  to this standard follow `global/standards-lifecycle.md`.
