# Spec: compliance-tiers

<!-- Audit: I.2 (i2-compliance-tiers) — single human-readable standard codifying the EU compliance gradient T1/T2/T3 from `compliance-tier.schema.json` v1.0.0 (T.4) and `ARCHITECTURE-TARGET.md` §10. -->
<!-- Source change : `.forge/changes/i2-compliance-tiers/` (archived 2026-05-12). -->

**Namespace** : `FR-I2-CT-*` / `NFR-I2-CT-*`. **Constitution** : v1.1.0.
Pas d'amendement requis (I.2 documents et codifie ; ne modifie pas).

**Five physical deliverables** (per `tasks.md`) :

- **I.2.a** — `.forge/standards/global/compliance-tiers.md` v1.0.0
  authoritative standard. 7 H2 sections (Purpose, Tier definitions,
  Component eligibility matrix, Demeter integration, Adoption path,
  Extending the matrix, Interdictions + Constitutional Compliance).
  Frontmatter pins `linter_rule: t3-forbidden-components` as a
  forward-pointer to I.3 (ADR-I2-CT-001).
- **I.2.b** — `.forge/standards/index.yml` entry under "I.2 —
  Compliance tiers" : id `global/compliance-tiers`, 9 triggers
  (`compliance, t1, t2, t3, eu-tier, dpa, schrems, cloud-act,
  tier-classification`), scope `all`, priority `high`.
- **I.2.c** — `.forge/standards/REVIEW.md` append-only birth entry
  dated 2026-05-11. KEEP decision, next review due 2027-05-11.
- **I.2.d** — `docs/COMPLIANCE.md` adopter-facing intro. 3 H2
  sections (Quick start, Tier picker, Cross-references) + decision
  tree for tier selection. Root placement per ADR-I2-CT-003.
- **I.2.e** — `.forge/scripts/tests/i2.test.sh` harness (14 L1
  hermetic grep-based tests, registered in `forge-ci.yml` after
  `k3.test.sh`).

**Pattern reuse** : the standard reuses K.3 / J.8 standard-template
shape verbatim (audit comment + trigger comment + H1 + frontmatter
block + body H2 sections + Interdictions section). The 15-row
component matrix is **byte-identical** to `ARCHITECTURE-TARGET.md`
§10.2 (verbatim per K.3 FR-K3-DEM-020 precedent / ADR-I2-CT-002).
The `x-tier-descriptions` block is **byte-identical** to
`compliance-tier.schema.json` v1.0.0 (Anti-Hallucination Article
III.4 + NFR-I2-CT-004 verbatim-citation invariant).

**Forward-pointers resolved** (none for I.2 itself — purely
documentary) :

- K.3 / Demeter persona (`.claude/agents/demeter.md::Standards
  consumed`) forward-cites `global/compliance-tiers.md` — that
  citation now resolves to a shipped file.
- K.3 / Demeter severity scaling (FR-K3-DEM-068) cites T1 / T2 / T3
  thresholds — the threshold definitions now live in the standard.

**Forward-pointers introduced** (deferred to downstream changes) :

- I.3 — `t3-forbidden-components` linter rule in
  `constitution-linter.sh`. The frontmatter `linter_rule:` field
  points to the future section anchor (ADR-I2-CT-001 kebab-case).
- I.5 — `forge-compliance.yml` reusable workflow.
- I.6 — Regulatory artefacts under `.forge/compliance/` (NIS2 /
  DORA / CRA / AI Act). Future grouping of `docs/COMPLIANCE.md`
  into `docs/compliance/` deferred to Themis (K.5) per
  ADR-I2-CT-003.

**Manual user follow-ups (out of I.2 scope)** :

- **I.3** : `t3-forbidden-components` linter rule. Reads the matrix
  in this standard and the `forbidden_for_tier:` annotations.
- **I.5** : `.github/workflows/forge-compliance.yml` reusable
  workflow that calls Demeter + SBOM + future I.6 artefacts.
- **I.6** : `.forge/compliance/` artefact tree mapping the standard
  to NIS2 / DORA / CRA / AI Act control IDs.
- **Themis hand-over (Phase B)** : at K.5 ship, the standard's
  steward flips from BDFL to Themis ; review cadence tightens
  12-month → 6-month (mirrors K.3 ADR-K3-003).

---

## Functional Requirements

### Cluster 1 — Standard file frontmatter (FR-I2-CT-001 → 010)

Anchors the standard file at `.forge/standards/global/compliance-tiers.md`
(FR-I2-CT-001) with mandatory audit + trigger HTML comments within
the first 5 lines (FR-I2-CT-002 / FR-I2-CT-003), H1 heading
`# Standard — Compliance Tiers (T1 / T2 / T3)` (FR-I2-CT-004), and a
narrative frontmatter block within the first 30 lines (FR-I2-CT-005)
mirroring J.7 YAML standards : `version: 1.0.0` (FR-I2-CT-006),
`last_reviewed: 2026-05-11` + `expires_at: 2027-05-11` (FR-I2-CT-007),
`exception_constitutional: false` (FR-I2-CT-008),
`linter_rule: t3-forbidden-components` (FR-I2-CT-009 — kebab-case
forward-pointer per ADR-I2-CT-001), `enforcement: review` +
`forbidden: []` + non-empty `rationale:` (FR-I2-CT-010).

### Cluster 2 — Body H2 sections (FR-I2-CT-020 → 030)

Seven mandatory H2 sections in fixed order : **Purpose** (FR-I2-CT-020
— cites I.2 audit slot + upstream schema + downstream consumers),
**Tier definitions** (FR-I2-CT-021 — verbatim citation of
`compliance-tier.schema.json::x-tier-descriptions` per NFR-I2-CT-004
+ Article III.4 + K.3 FR-K3-DEM-020 precedent), **Component
eligibility matrix** (FR-I2-CT-022 — 15-row Markdown table
byte-identical to `ARCHITECTURE-TARGET.md` §10.2 per ADR-I2-CT-002 +
NFR-I2-CT-005), **Demeter integration** (FR-I2-CT-023 — cross-link to
`.claude/agents/demeter.md` + FR-K3-DEM-068 severity scaling table),
**Adoption path** (FR-I2-CT-024 — three-step adopter checklist
mirroring K.3 `data-stewardship-rules.md::Adoption path`),
**Extending the matrix** (FR-I2-CT-025 — governance procedure :
proposal change, Themis review post-T7, Article XII coupling),
**Interdictions** (FR-I2-CT-026 — ≥ 3 RFC-2119 MUST NOT clauses ; the
shipped standard contains 5 : no paraphrase of schema descriptions,
no new tier without Article XII amendment, no silent T3 downgrade,
no certification-scheme coupling beyond SecNumCloud / HDS / EUCS
High, matrix byte-identical to §10.2). FR-I2-CT-027 → 030 add the
trailing **Constitutional Compliance** matrix listing Articles III.4
/ V / XI.1 / XI.3 / XII coverage.

### Cluster 3 — Standards index registration (FR-I2-CT-040 → 045)

`.forge/standards/index.yml` gains one entry under a new H2 section
`### I.2 — Compliance tiers` (FR-I2-CT-040 — placed after the K.3
`### K.3 — Data stewardship` section per chronological audit-slot
order, FR-I2-CT-041). The entry carries `id: global/compliance-tiers`
(FR-I2-CT-042), 9 triggers in fixed order `compliance, t1, t2, t3,
eu-tier, dpa, schrems, cloud-act, tier-classification` (FR-I2-CT-043),
`scope: all` (FR-I2-CT-044), `priority: high` (FR-I2-CT-045).
Trigger reachability MUST be enforceable by J.7 (FR-J7-050) — the 9
triggers map to at least one cross-cutting injection context.

### Cluster 4 — REVIEW ledger entry (FR-I2-CT-050 → 052)

`.forge/standards/REVIEW.md` gains one append-only entry under the
**Standards review log** table : standard
`global/compliance-tiers.md` v1.0.0, last reviewed 2026-05-11,
decision KEEP, next review due 2027-05-11, ledger reason "Initial
ratification (i2-compliance-tiers)" (FR-I2-CT-050 → 052 ; ordering
chronological per `global/standards-lifecycle.md` ledger contract).

### Cluster 5 — Adopter intro doc (FR-I2-CT-090 → 093)

A new `docs/COMPLIANCE.md` ships at the repository root
(FR-I2-CT-090 — placement per ADR-I2-CT-003 ; future I.6 grouping
into `docs/compliance/` deferred to Themis K.5). The file carries an
H1 `# Compliance Tiers (T1 / T2 / T3)` (FR-I2-CT-091), 3 H2 sections
**Quick start** (one-paragraph onboarding + pointer to
`global/compliance-tiers.md`), **Tier picker** (decision tree with
discriminating questions : EU jurisdiction binding, sovereign
certification required, self-host budget), **Cross-references** (one
hyperlink per : standard, schema, Demeter, J.8 `--eu-tier` flag,
ARCHITECTURE-TARGET §10) — FR-I2-CT-092 → 093.

### Cluster 6 — Test harness (FR-I2-CT-100 → 112)

`.forge/scripts/tests/i2.test.sh` carries 14 L1 hermetic grep-based
tests (FR-I2-CT-100 register / FR-I2-CT-101 audit comment /
FR-I2-CT-102 trigger comment / FR-I2-CT-103 H1 / FR-I2-CT-104
version line / FR-I2-CT-105 dates pair / FR-I2-CT-106
`linter_rule:` / FR-I2-CT-107 H2 count ≥ 7 / FR-I2-CT-108 schema
verbatim citation / FR-I2-CT-109 15-row matrix presence /
FR-I2-CT-110 Demeter crosslink + FR-K3-DEM-068 citation /
FR-I2-CT-111 ≥ 3 MUST NOT clauses / FR-I2-CT-112 index.yml entry +
REVIEW.md entry + `docs/COMPLIANCE.md` presence + CHANGELOG entry).
Registered in `.github/workflows/forge-ci.yml` matrix after
`k3.test.sh` per project CI convention.

### Cluster 7 — CHANGELOG (FR-I2-CT-080 → 081)

`CHANGELOG.md` `[Unreleased]` section gains a top-of-list
`### Added — I.2 compliance-tiers standard (i2-compliance-tiers)`
entry (FR-I2-CT-080 placement / FR-I2-CT-081 content : cites all 5
shipped files + 3 ADRs + unblocked downstream items I.3 / I.5 / I.6).

---

## Non-Functional Requirements

### NFR-I2-CT-001 — Test harness performance budget

`.forge/scripts/tests/i2.test.sh --level 1` MUST complete in
≤ 3 s wall-clock on the live repo tree (mirrors K.3 NFR-K3-DEM-001
budget). 14 grep-only tests against a single 437-LOC file —
empirical wall-clock at archive time ≪ 1 s.

### NFR-I2-CT-002 — Backward compatibility

Purely additive change. Adopters not consuming the standard observe
ZERO behavioural change. The matching `t3-forbidden-components`
linter section ships in I.3, not here ; the I.2 standard alone
emits no CI signal.

### NFR-I2-CT-003 — Standard file size

`.forge/standards/global/compliance-tiers.md` MUST stay between 300
and 600 LOC (envelope chosen to keep one-screen H2 navigation
practical for adopters). Shipped at 437 LOC.

### NFR-I2-CT-004 — Verbatim-citation invariant

The `x-tier-descriptions` block in the **Tier definitions** H2 MUST
be byte-identical to `.forge/schemas/compliance-tier.schema.json`'s
corresponding block. Article III.4 anti-hallucination + K.3
FR-K3-DEM-020 precedent : no paraphrase, no rewording, no
restructuring. Reviewer / harness MAY assert via `diff` against the
schema's JSON-extracted descriptions.

### NFR-I2-CT-005 — Matrix row count invariant

The 15-row component matrix in the **Component eligibility matrix**
H2 MUST be byte-identical to `docs/ARCHITECTURE-TARGET.md` §10.2 —
same rows, same column order (Component, T1, T2, T3, Notes), same
verdict cells (✅ / ⚠ / ⛔ / verbatim string). Any divergence from
§10.2 is a defect.

### NFR-I2-CT-006 — No external dependency

This change ships pure Markdown + bash + index.yml YAML edit. Zero
new dependency (no npm, no Python lib, no binary). Mirrors K.3
NFR-K3-DEM-004 + J.8.d NFR-J8-005 zero-new-dep posture.

### NFR-I2-CT-007 — Deterministic harness

`.forge/scripts/tests/i2.test.sh` MUST produce byte-identical
output when re-run with the same source tree (no `date(1)` calls
in test output, no PRNG, no network). Mirrors K.3 NFR-K3-DEM-005
reproducibility posture.

---

## ADRs (I.2 design)

| ID            | Decision                                                                                                                                                                                                              |
|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ADR-I2-CT-001 | `linter_rule:` value is the **kebab-case forward-pointer** `t3-forbidden-components`. The matching `constitution-linter.sh` section anchor ships with I.3 (downstream change). Resolves Q-001 ; mirrors J.7 FR-J7-030 + ADR-J7-002 cross-reference contract. |
| ADR-I2-CT-002 | Matrix encoding = **verbatim 15 rows** of `ARCHITECTURE-TARGET.md` §10.2. No paraphrase, no restructure, no row collapse. Mirrors K.3 FR-K3-DEM-020 verbatim-citation precedent. Resolves Q-002.                                                              |
| ADR-I2-CT-003 | `docs/COMPLIANCE.md` placement = **root** (not `docs/compliance/COMPLIANCE.md`). Mirrors the existing root convention (`docs/SCHEMA.md`, `docs/LINTING.md`, `docs/OPEN_QUESTIONS.md`, `docs/ARCHETYPES.md`). Future grouping into `docs/compliance/` deferred to Themis (K.5). Resolves Q-003. |

Full design rationale + decision tree narratives + Open Questions
resolution :
[`.forge/changes/i2-compliance-tiers/design.md`](../changes/i2-compliance-tiers/design.md)
(15 943 bytes, archived 2026-05-12).

---

## Acceptance Criteria

- [x] `.forge/standards/global/compliance-tiers.md` v1.0.0 exists,
      437 LOC, 7 H2 sections, 5 MUST NOT clauses.
- [x] `.forge/standards/index.yml` carries the I.2 entry with 9
      triggers, scope `all`, priority `high`.
- [x] `.forge/standards/REVIEW.md` carries the 2026-05-11 KEEP
      entry.
- [x] `docs/COMPLIANCE.md` exists at repository root with H1 + 3 H2
      sections + decision tree.
- [x] `.forge/scripts/tests/i2.test.sh --level 1` → 14 PASS / 0
      FAIL.
- [x] `.github/workflows/forge-ci.yml` invokes `i2.test.sh --level
      1` after `k3.test.sh`.
- [x] `CHANGELOG.md` `[Unreleased]` carries the I.2 Added entry.
- [x] `bash .forge/scripts/verify.sh` → PASS (165/0 + 1 WARN T.5
      legacy).
- [x] `bash .forge/scripts/constitution-linter.sh` → OVERALL PASS.
- [x] `bash bin/validate-standards-yaml.sh` → STD-PASS (the new
      standard is MD ; live tree YAML baseline preserved).

---

## BDD Scenarios (Article II)

The four scenarios documented in
`.forge/changes/i2-compliance-tiers/specs.md` §BDD (Reviewer reads
the standard ; Adopter onboards via `docs/COMPLIANCE.md` ; Demeter
resolves its forward-pointer ; Harness runs in CI) are the
canonical Given/When/Then narratives. They are preserved in the
change directory verbatim ; this consolidated spec deliberately
omits them to keep the surface lean for downstream readers
(mirrors K.3 / J.8 consolidated-spec convention).

---

## Cross-References

- **Upstream schema** :
  `.forge/schemas/compliance-tier.schema.json` v1.0.0 (T.4 —
  ratified 2026-05-04 via `t4-adr-ratification`).
- **Upstream architecture** : `docs/ARCHITECTURE-TARGET.md` §10
  (compliance graded EU) ; §10.2 (component matrix verbatim
  source) ; §10.3 (archetype profile mapping) ; §10.4 (regulatory
  deadlines NIS2 / DORA / CRA / AI Act).
- **Persona consumer** : `.claude/agents/demeter.md` (K.3 — archived
  2026-05-12 via `k3-demeter`) — forward-cites this standard via
  the `Standards consumed` section ; severity scaling per
  FR-K3-DEM-068.
- **Janus enforcement** : `.claude/agents/cross-layer-orchestrator.md`
  J8-RULE-002 / J8-RULE-003 (J.8 — archived 2026-05-10) — refuses
  T3 with cloud-managed identity / observability.
- **CLI surface** : `cli/src/init.ts` `--eu-tier T1|T2|T3` flag +
  `FORGE_EU_TIER` env-var ABI + `<target>/.forge/.forge-tier`
  ledger (J.8.b).
- **Downstream linter** : I.3 — `t3-forbidden-components` in
  `constitution-linter.sh` (forward-pointer per ADR-I2-CT-001).
- **Downstream workflow** : I.5 — `forge-compliance.yml`.
- **Downstream artefacts** : I.6 — `.forge/compliance/` tree
  (NIS2 / DORA / CRA / AI Act control mapping).
- **Standard frame** : `global/standards-lifecycle.md` (T.4 —
  12-month review cycle, REVIEW.md append-only ledger).
- **Plan ref** : `docs/new-archetypes-plan.md` §7.1 line 727-729
  (I.2 row) + §10 (I-module roadmap).
