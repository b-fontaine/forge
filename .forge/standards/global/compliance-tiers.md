# Standard — Compliance Tiers (T1 / T2 / T3)

<!-- Audit: I.2 (i2-compliance-tiers) -->
<!-- Trigger: compliance, t1, t2, t3, eu-tier, dpa, schrems, cloud-act, tier-classification -->

```yaml
version: 1.0.0
last_reviewed: 2026-05-11
expires_at: 2027-05-11
exception_constitutional: false
linter_rule: t3-forbidden-components
enforcement: ci         # flipped from 'review' by i3-t3-forbidden-linter, 2026-05-12
forbidden: []           # this standard DOCUMENTS ; I.3 (i3-t3-forbidden-linter) ENFORCES
rationale: >-
  Codifies the EU compliance gradient T1/T2/T3 from
  docs/ARCHITECTURE-TARGET.md §10 so adopters and Demeter share a
  single human-readable reference.
```

> **Status note** — `linter_rule: t3-forbidden-components` is the
> **resolved** pointer to the I.3 linter rule shipped 2026-05-12 via
> `i3-t3-forbidden-linter`. The matching section anchor in
> `.forge/scripts/constitution-linter.sh::ADR-I3-001` enforces this
> standard's forward-pointer deterministically. The standard's
> `enforcement` is now `ci` (was `review` until 2026-05-12) — the
> linter rule refuses T3 declarations that scaffold forbidden
> components per the §10.2 matrix encoded in
> `.forge/standards/global/forbidden-components-rules.md`
> (T3-RULE-NNN catalogue).

---

## Purpose

This standard codifies the **EU compliance gradient T1 / T2 / T3**
as a human-readable contract sitting between :

- **Machine source of truth** —
  `.forge/schemas/compliance-tier.schema.json` v1.0.0 (ratified by
  `t4-adr-ratification`, 2026-05-04). The schema locks the
  `enum: [T1, T2, T3]` value and the `x-tier-descriptions` block.
- **Narrative architecture source** —
  `docs/ARCHITECTURE-TARGET.md` §10 (lines 731-779). The
  architecture document carries the §10.2 component-eligibility
  matrix, the §10.3 archetype-profile matrix, and the §10.4
  regulatory deadlines.

The standard exists because :

- The Demeter persona (`.claude/agents/demeter.md`, K.3 — shipped
  2026-05-10) forward-cites this standard as a sibling reference.
  Without the file, the forward-pointer was unresolved ; reviewers
  clicking through from Demeter landed in the architecture
  document buried in a 1000-line file.
- The downstream items I.3 (T3-forbidden linter rule), I.5
  (`forge-compliance.yml` workflow), I.6 (regulatory artefacts —
  NIS2 / DORA / CRA / AI Act) all need a stable in-repo citation
  anchor. The schema is one line per tier ; the architecture
  document is sprawling ; this standard is the right granularity.
- Adopters reading the standards index for `[t1, t2, t3, eu-tier,
  compliance]` triggers MUST find a canonical human-readable
  standard. Before this, they found nothing.

The standard's job is to **mirror** the schema and §10.2 matrix
faithfully — no paraphrase, no extension. Demeter's
Anti-Hallucination Protocol (FR-K3-DEM-020) requires verbatim
citation of the schema ; this standard provides the narrative
canvas with the verbatim block embedded.

Source audit item : **I.2** from
`docs/new-archetypes-plan.md` §7.1 line 727-729.

---

## Tier definitions

Cited **verbatim** from
`.forge/schemas/compliance-tier.schema.json` v1.0.0
`x-tier-descriptions` block. **MUST NOT** paraphrase, **MUST NOT**
extend (see Interdictions). The schema is the single source of
truth ; this section is its narrative mirror.

> **T1** — "RGPD-compliant via DPA — SaaS hors EU acceptable si DPA + SCC + protections complémentaires (chiffrement, BYOK), assume risque résiduel CLOUD Act."

> **T2** — "Self-hostable — déployable sur n'importe quel K8s EU, contrôle technique mais pas qualification sovereign."

> **T3** — "Hébergement EU strict — SecNumCloud / HDS / EUCS High, 100% EU jurisdiction, immune CLOUD Act."

**Tier ordering** : T1 is the most permissive (non-EU SaaS
acceptable under a DPA + SCC envelope) ; T3 is the most restrictive
(100% EU jurisdiction, no CLOUD Act exposure). T2 is the
self-host middle ground — EU-deployable but not formally
sovereign-certified.

**Regulatory cross-references** :

- **T1** ↔ RGPD Article 28 (Data Processing Agreement) +
  EDPB-aligned transfer impact assessment + Schrems II SCC
  envelope.
- **T2** ↔ NIS2 essential-entity self-host posture +
  technical-control surface.
- **T3** ↔ SecNumCloud (ANSSI) / HDS (santé numérique) / EUCS High
  (EU Cybersecurity Certification Scheme) ; 100% EU jurisdiction
  precludes CLOUD Act exposure (18 U.S.C. §2713).

---

## Component eligibility matrix

Mirrored **verbatim** from `docs/ARCHITECTURE-TARGET.md` §10.2
(cible 2026). 15 rows × 5 columns. Cells preserve the source's
emoji + text byte-for-byte per `NFR-I2-CT-005`.

| Composant                        |        T1        |       T2       |             T3             | Forçage tier                                                                                            |
|----------------------------------|:----------------:|:--------------:|:--------------------------:|----------------------------------------------------------------------------------------------------------|
| Flutter / Qwik (binaires client) |        ✅         |       ✅        |             ✅              | aucun                                                                                                    |
| Rust + tonic + axum              |        ✅         |       ✅        |             ✅              | aucun                                                                                                    |
| Envoy Gateway                    |        ✅         |       ✅        |             ✅              | aucun (CNCF)                                                                                             |
| Postgres 17 + pgvector           |        ✅         |       ✅        |             ✅              | aucun                                                                                                    |
| DBOS (embedded library)          |        ✅         |       ✅        |             ✅              | aucun                                                                                                    |
| Zitadel                          | ⚠️ Cloud SaaS T1 | ✅ self-host T2 | ✅ self-host EU+SecNumCloud | T3 = self-host obligatoire                                                                               |
| SigNoz                           | ⚠️ Cloud SaaS T1 | ✅ self-host T2 |       ✅ self-host EU       | T3 = self-host obligatoire                                                                               |
| Coroot                           |   ✅ self-host    |       ✅        |             ✅              | —                                                                                                        |
| OTel Collector / OBI             |        ✅         |       ✅        |             ✅              | —                                                                                                        |
| OVHcloud / Scaleway / Outscale   |        —         |       —        |             ✅              | T3 obligatoire = SecNumCloud Outscale (only public cloud SecNumCloud-qualifié)                           |
| AWS / GCP / Azure                |    ⚠️ T1 only    |       ❌        |             ❌              | **CLOUD Act** force max T1                                                                               |
| Firebase                         |        ❌         |       ❌        |             ❌              | Disqualifié pour archétype EU strict                                                                     |
| Temporal Cloud                   |      ⚠️ T1       | ✅ self-host T2 |       ✅ self-host EU       | self-host pour T3                                                                                        |
| LLM Gateway (OpenAI/Anthropic)   |    ⚠️ T1 max     |       ❌        |             ❌              | Pour T3 : Mistral on Scaleway ou vLLM self-host                                                          |
| NATS JetStream                   |        ✅         |       ✅        |             ✅              | self-host T2/T3                                                                                          |

**Source citations** (faithful reproduction from §10.2 footnote
references) :

- **DBOS** : [source: dbos.dev, accessed 2026-04]
- **Zitadel** : [source: zitadel.com/blog/zitadel-vs-keycloak, accessed 2026-04]
- **OVHcloud / Scaleway / Outscale** : [source: 3ds.com/newsroom/press-releases/outscale-enhances-outscale-kubernetes-service, accessed 2026-04]
- **AWS / GCP / Azure (CLOUD Act)** : [source: spreecommerce.org/gdpr-schrems-ii-ecommerce-compliance, accessed 2026-04]

**Reading guide** :

- ✅ — eligible at this tier without constraint.
- ⚠️ — eligible at this tier under specific constraint
  (text in the cell).
- ❌ — refused at this tier (incompatible with the tier's
  posture).
- — — N/A (the component is not a candidate at this tier).

When a cell reads "⚠️ Cloud SaaS T1", the cloud SaaS variant of
the component (e.g. zitadel.com hosted offering) is acceptable
only at T1 with a DPA ; the self-host variant is acceptable at T2
and T3.

---

## Demeter integration

This standard is the **canonical narrative reference** that the
Demeter agent (`.claude/agents/demeter.md`, K.3) cites at review
time. Demeter is the **deterministic enforcement surface** ; this
standard is the **human-readable canon**.

### Severity scaling (FR-K3-DEM-068)

Demeter scales the severity of `K3-RULE-001` (US-jurisdiction
publisher detected) by the declared tier of the project, per
`FR-K3-DEM-068` :

- **T1 → Informational** : T1 declares "RGPD via DPA acceptable",
  so residual CLOUD Act risk is acknowledged. Findings surface
  for adopter awareness without blocking the build.
- **T2 → High** : T2 declares "self-hostable", so US-jurisdiction
  publishers contradict the posture even when deployment is on
  EU infrastructure (the binary still embeds compiled US-published
  code).
- **T3 → Critical** : T3 declares "100% EU jurisdiction", so any
  US-jurisdiction dependency is a tier violation that BLOCKS the
  change.

### K3-RULE catalogue cross-reference

The full Demeter rule catalogue lives in
[`global/data-stewardship-rules.md`](data-stewardship-rules.md)
(sibling standard). Six seed rules cover :

- **K3-RULE-001** — US-jurisdiction publisher (tier-scaled).
- **K3-RULE-002** — DPA undeclared at T1 with ⚠️-T1 component.
- **K3-RULE-002a** — DPA declaration stale (> 13 months).
- **K3-RULE-003** — Tier downgrade refused (new US dep at T2/T3).
- **K3-RULE-004** — Data classification missing (PII heuristic).
- **K3-RULE-005** — Cargo workspace drift (Cargo.toml without
  Cargo.lock).
- **K3-RULE-006** — Publisher list staleness.

### `.forge/.forge-tier` ledger

Demeter consumes the per-project tier declaration from a plain-text
ledger file `.forge/.forge-tier` (pattern shipped by J.8 ADR-J8-006
and re-used verbatim by K.3 per ADR-K3-002 for `.forge-dpa-declared`) :

```
T2
```

One line, content in `{T1, T2, T3}`, mandatory trailing newline
(POSIX). Demeter reads via plain-text `cat` ; no YAML parser
dependency on the consumer side.

When the ledger is missing AND `--eu-tier` flag is also absent,
Demeter emits `[NEEDS CLARIFICATION: compliance tier undeclared —
pass --eu-tier T1|T2|T3 or write .forge/.forge-tier]` and STOPS.
No default tier is inferred (K.3 Anti-Hallucination Protocol).

### Janus refusal cross-link

The Janus orchestrator (`.claude/agents/cross-layer-orchestrator.md`,
J.8) enforces two T3-specific refusal rules at scaffold time, both
of which reference this tier gradient :

- **J8-RULE-002** — `--eu-tier T3` refuses non-self-host Zitadel
  (matrix row 6 forces self-host obligatoire at T3).
- **J8-RULE-003** — `--eu-tier T3` refuses Datadog and SigNoz Cloud
  SaaS (matrix row 7 forces self-host obligatoire at T3 ; Datadog
  is documented in `observability.yaml::forbidden:`).

The Janus rules are scaffolding-time refusals (exit code 3,
blocking) ; Demeter's K3-RULE findings are review-time signals
(severity-scaled, blocking only at High / Critical). Both surfaces
quote the same gradient — this standard is the shared canon.

---

## Adoption path

Adopters can opt in incrementally without committing to the full
review pipeline at once. Mirrors the K.3
`data-stewardship-rules.md::Adoption path` structure.

### Minimum viable adoption (T2 / T3 projects)

1. Declare the compliance tier in `.forge/.forge-tier` :
   ```bash
   echo "T2" > .forge/.forge-tier
   ```
   (or `T1` / `T3` as appropriate). One line, trailing newline.
2. Run `bash bin/forge-demeter-scan.sh --target $(pwd) --tier T2`
   (or `T3`) at PR time, fail the build on exit code 3 (BLOCKED).
3. Review findings ; either replace flagged dependencies or
   formally downgrade the declared tier with an audit trail.

### Full adoption (T1 projects with regulated workloads)

1. Steps 1-3 above.
2. Add the `.forge/.forge-dpa-declared` ledger when ⚠️-T1
   components are in scope (matrix rows 6 / 7 / 11 / 13 / 14 —
   Zitadel cloud, SigNoz cloud, AWS/GCP/Azure, Temporal Cloud,
   LLM Gateway). One line, content :
   ```
   T1: <ISO-8601-date> <free-form-ref>
   ```
   Mandatory trailing newline. Demeter is **proof-of-attestation**
   only — it does NOT parse DPA legal text (K.3 explicitly
   out-of-scope per FR-K3-DEM-044).
3. Wire Demeter into the Janus cross-layer review at Step 9. The
   dispatch is automatic — Janus reads `.forge/.forge.yaml::layers:`
   and routes accordingly (Aegis and Demeter run in parallel as
   the security / data-stewardship pass).
4. When Themis (K.5) ships (T7+), regulatory deadlines + EDPB
   opinion windows are tracked at the regulatory layer ; Themis
   consumes Demeter's findings and produces NIS2 / DORA / CRA /
   AI Act artefacts. Until then, adopters track regulatory
   deadlines manually.

### Migration between tiers

Migrations are **explicit** :

- **Upgrade** (e.g. T1 → T2) : adopter edits `.forge/.forge-tier`
  and re-runs Demeter. Findings that were Informational at T1
  surface as High at T2 ; adopter remediates or stays at T1.
- **Downgrade** (e.g. T3 → T1) : Demeter does NOT silently allow
  downgrades. The adopter MUST edit `.forge/.forge-tier`
  explicitly ; Demeter detects ledger / flag mismatches and emits
  `[NEEDS CLARIFICATION: tier ledger mismatch]` until reconciled
  (per K.3 Anti-Hallucination Protocol). See Interdictions.

---

## Extending the matrix

The component-eligibility matrix is **incremental**. New rows MAY
be added when new dependencies enter the Forge supported set ; tier
cells MAY shift when the upstream component changes posture (e.g.
a vendor opens an EU-jurisdiction region) ; the
`x-tier-descriptions` semantics MUST NOT be amended without an
Article XII Constitution amendment.

### Governance — two phases

#### Phase A — Interim (now → Themis ships, ~T7+)

- **Who** : BDFL (per `GOVERNANCE.md`).
- **Cadence** : 12-month default `expires_at` per
  `global/standards-lifecycle.md`.
- **Trigger** : explicit vendor announcement of a new EU region,
  EDPB opinion shifting Schrems II interpretation, NIS2 / DORA /
  CRA / AI Act regulatory update, security advisory affecting a
  matrix row.
- **SemVer policy** :
  - **Minor bump** (1.0.0 → 1.1.0) for additive changes : new
    component row, tier shift on an existing row, footnote
    citation update.
  - **Major bump** (1.0.0 → 2.0.0) for breaking changes : matrix
    row removal, tier-meaning change (impossible without an
    Article XII amendment on the schema's `x-tier-descriptions`
    — see Interdictions).

#### Phase B — Themis (T7+)

- **Who** : Themis agent (K.5, compliance officer) — proposes
  matrix edits via PR.
- **Cadence** : 6-month rolling cadence (faster than 12-month
  standards default because component velocity exceeds standards
  drift, mirroring the K.3 publisher-list pattern per
  ADR-K3-003).
- **Trigger** : same as Phase A + Themis's monthly
  `forge review-standards` cycle.
- The transition Phase A → Phase B is a single PR (Themis shipped
  + this standard's `linter_rule` enforcement flipped from
  `review` to `ci` + `maintained_by` field added). No data
  migration required.

### Edits to this standard MUST

- Bump `version:` per SemVer (additive = minor ; structural
  schema change = major).
- Refresh `last_reviewed:` to the edit date.
- Recompute `expires_at:` per the active phase's cadence.
- Append an entry in `.forge/standards/REVIEW.md` documenting
  the edit (REVIEW.md is append-only — Article XII).
- Synchronise with `docs/ARCHITECTURE-TARGET.md` §10.2 in the
  **same PR** — the two surfaces MUST stay byte-identical
  (Interdiction below).

---

## Interdictions

RFC-2119 normative clauses governing the standard's lifecycle and
its relationship to upstream sources. These MUST NOT be relaxed
without an Article XII Constitution amendment (see
`.forge/constitution.md` Article XII).

### 1. MUST NOT paraphrase the schema

The three tier descriptions cited in **Tier definitions** above
MUST be reproduced byte-for-byte from
`.forge/schemas/compliance-tier.schema.json` v1.0.0
`x-tier-descriptions` block. Demeter's Anti-Hallucination Protocol
(FR-K3-DEM-020) requires verbatim citation ; any paraphrase
introduces a deviation Demeter cannot reconcile against the schema.
The harness test `_test_i2_007_tier_definitions_verbatim` asserts
byte-equivalence via `grep -F` (fixed string match).

### 2. MUST NOT add a new compliance tier without Article XII

The enum `[T1, T2, T3]` is **structural** — it defines the EU
compliance gradient that anchors Forge's positioning. Adding T4
("EU sovereign hyperscaler") or T0 ("non-EU acceptable") or any
sub-tier (T2.5) is a structural change that MUST go through the
Article XII Constitution amendment procedure :

1. Discussion publique ≥ 7 days via GitHub Discussions.
2. Proposal Forge change with rationale + impact analysis on
   existing archetypes and adopter projects.
3. Vote BDFL (current phase) or comité (mature phase, future
   amendment).
4. Constitution version bump (minor if extension, major if
   breaking).
5. Synchronised updates to : the schema's `enum:` ; the schema's
   `x-tier-descriptions` ; this standard ; the Demeter persona
   ; the Janus rules ; `docs/ARCHITECTURE-TARGET.md` §10.

### 3. MUST NOT silently downgrade a declared T3 project

When `.forge/.forge-tier` declares `T3`, Demeter MUST NOT
auto-allow a downgrade to T1 to clear a US-jurisdiction-publisher
finding. The adopter MUST edit `.forge/.forge-tier` explicitly ;
Demeter detects ledger / flag mismatches and emits
`[NEEDS CLARIFICATION: tier ledger mismatch — ledger says <X>,
flag says <Y>]` until reconciled. The downgrade is a deliberate
human decision with an audit trail, not a silent CI bypass.

### 4. MUST NOT couple T3 to providers beyond named certifications

T3 is defined as "SecNumCloud / HDS / EUCS High". The standard
MUST NOT pre-emptively endorse additional certification schemes
(e.g. C5 / ISO 27001 / SOC 2) as T3-equivalent without an
Article XII amendment + a documented gap analysis. C5 is a German
scheme that does NOT preclude CLOUD Act exposure ; ISO 27001 and
SOC 2 are jurisdiction-agnostic and do not imply EU sovereignty.
Adding them silently would dilute the T3 contract.

### 5. MUST stay byte-identical to ARCHITECTURE-TARGET §10.2

The matrix in **Component eligibility matrix** above MUST stay
byte-identical to `docs/ARCHITECTURE-TARGET.md` §10.2. Edits to
either surface MUST update both in the same PR. A future drift
detector (potential J.X follow-up) will enforce this
deterministically ; until then, REVIEW.md entries cite both file
paths and the SHA of the cross-referenced commit.

---

## Constitutional Compliance

This standard implements (does not amend) :

- **Article III.4** (anti-hallucination) — verbatim citation of
  the schema's `x-tier-descriptions` block ; no paraphrase
  (Interdiction 1).
- **Article V** (audit trail) — REVIEW.md append-only ledger
  records every edit ; matrix source citations preserve
  traceability.
- **Article XI.1** (agent-native architecture) — Demeter
  (`.claude/agents/demeter.md`) is the canonical consumer of this
  standard. The standard's narrative is consumed by an agent
  persona, not by opaque LLM-generated content.
- **Article XI.3** (schema-driven) — the standard mirrors the
  JSON Schema verbatim ; no schema-divergent semantic introduced.
- **Article XII** (governance) — adding a tier requires Article
  XII amendment (Interdiction 2) ; matrix edits follow SemVer
  per `global/standards-lifecycle.md` ; REVIEW.md is append-only.

This standard does **not** carry the J.7 frontmatter contract
**structurally** because it ships as Markdown (mirroring
`data-stewardship-rules.md`, `janus-orchestration-rules.md`,
`sbom-policy.md`). The YAML-equivalent fields at the top of this
file are **narrative** ; `bin/validate-standards-yaml.sh` does not
scan MD standards.
