# Specifications: i2-compliance-tiers
<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-I2-CT-*` / `NFR-I2-CT-*`. **Constitution** :
v1.1.0. Pas d'amendement requis (I.2 documents et codifie, ne
modifie pas).

## Source Documents

| Field                | Value                                                                                                                                                                              |
|----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **ADR base**         | `t4-adr-ratification` archived 2026-05-04 (ratifies `compliance-tier.schema.json` v1.0.0 ; ADR-007 + ADR-008 + ADR-010 lock the EU posture)                                         |
| **Persona ref**      | `k3-demeter` archived 2026-05-10 — Demeter persona forward-cites this standard (`.claude/agents/demeter.md::Standards consumed`) ; severity scaling per FR-K3-DEM-068 (T1/T2/T3)    |
| **Janus ref**        | `j8-janus-rules` archived 2026-05-10 — J8-RULE-002 + J8-RULE-003 enforce T3 refusals against cloud Zitadel / Datadog / SigNoz Cloud SaaS                                            |
| **Plan ref**         | `docs/new-archetypes-plan.md` §7.1 line 727-729 (I.2 row) ; §10 lines 727-743 (I-module roadmap)                                                                                    |
| **Schema reuse**     | `.forge/schemas/compliance-tier.schema.json` v1.0.0 (verbatim — `enum [T1, T2, T3]` + `x-tier-descriptions` block) ; `.forge/schemas/standard.schema.json` v1.0.0 (J.7 frontmatter) |
| **Architecture ref** | `docs/ARCHITECTURE-TARGET.md` §10 lines 731-779 (compliance graded EU + §10.2 component matrix + §10.3 archetype profile + §10.4 regulatory deadlines)                              |
| **Pattern reuse**    | `global/data-stewardship-rules.md` (K.3 standard template) ; `global/janus-orchestration-rules.md` (J.8 standard template) ; `global/sbom-policy.md` (J.8.d standard template)      |
| **Standard frame**   | `global/standards-lifecycle.md` (T.4 — frontmatter contract, 12-month review cycle, REVIEW.md append-only ledger)                                                                  |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Standard file frontmatter (FR-I2-CT-001 → 010)

##### FR-I2-CT-001 — File presence

A new file `.forge/standards/global/compliance-tiers.md` MUST exist
at the path. Content type Markdown.

##### FR-I2-CT-002 — Audit comment

The file MUST carry a `<!-- Audit: I.2 (i2-compliance-tiers) -->`
HTML comment within the first 5 lines, anchoring the file to its
source audit item per the existing convention
(`data-stewardship-rules.md`, `janus-orchestration-rules.md`,
`sbom-policy.md` all carry an equivalent audit comment).

##### FR-I2-CT-003 — Trigger comment

The file MUST carry a `<!-- Trigger: compliance, t1, t2, t3,
eu-tier, dpa, schrems, cloud-act, tier-classification -->` HTML
comment within the first 5 lines, mirroring the trigger registration
in `.forge/standards/index.yml`. The comment is informative for
human readers ; the index is the machine source of truth.

##### FR-I2-CT-004 — H1 anchor

The file MUST open with an H1 heading `# Standard — Compliance
Tiers (T1 / T2 / T3)` matching the existing standard-title
convention.

##### FR-I2-CT-005 — Frontmatter block

The file MUST carry a Markdown frontmatter-style block within the
first 30 lines documenting the J.7-equivalent fields :

- `version: 1.0.0`
- `last_reviewed: 2026-05-11`
- `expires_at: 2027-05-11`
- `exception_constitutional: false`
- `linter_rule: t3-forbidden-components`
- `enforcement: review` (becomes `ci` when I.3 lands)
- `forbidden: []` (this standard documents, doesn't forbid)
- `rationale:` — non-empty multi-line string

The block is **narrative** (the standard is MD, not YAML — J.7
`validate-standards-yaml.sh` does not scan it). The structure
mirrors the YAML standards for consistency.

##### FR-I2-CT-006 — SemVer version

`version: 1.0.0` MUST be present in the frontmatter block. Bumps
follow SemVer per `global/standards-lifecycle.md` §SemVer
discipline.

##### FR-I2-CT-007 — Lifecycle dates

`last_reviewed: 2026-05-11` + `expires_at: 2027-05-11` MUST be
present. The 365-day window matches the default 12-month review
cadence locked by T.4.

##### FR-I2-CT-008 — Linter rule forward-pointer

`linter_rule: t3-forbidden-components` MUST be present as a
kebab-case forward-pointer to the I.3 linter rule that will
ship later. The string MUST match the I.3 section anchor when
I.3 lands.

##### FR-I2-CT-009 — Constitutional exception flag

`exception_constitutional: false` MUST be present. The compliance
tier semantics are **structural** (Article XII) but the standard
documenting them is **amendable** under normal SemVer governance.
Adding a tier T4 or amending `x-tier-descriptions` requires
Article XII Constitution amendment — this is documented in the
Interdictions section, not via the structural-exception flag.

##### FR-I2-CT-010 — Rationale field

`rationale:` MUST be present with a non-empty value :
`"Codifies the EU compliance gradient T1/T2/T3 from
docs/ARCHITECTURE-TARGET.md §10 so adopters and Demeter share a
single human-readable reference."` (or semantically equivalent —
exact wording locked at design time).

---

#### Cluster 2 — Body H2 sections (FR-I2-CT-020 → 030)

##### FR-I2-CT-020 — H2 section count

The file body MUST carry at least 6 H2 sections. The minimum set
(exact titles locked at design time, semantic content fixed) :

1. `## Purpose`
2. `## Tier definitions`
3. `## Component eligibility matrix`
4. `## Demeter integration`
5. `## Adoption path`
6. `## Extending the matrix`
7. `## Interdictions`

The total set MAY exceed 6 (e.g. a `## Cross-references` H2 added
at design time is acceptable). The 6 minimum H2 sections cover
the structural commitment.

##### FR-I2-CT-021 — Purpose section

The `## Purpose` section MUST cite :
- The K.3 / I.4 audit item (Demeter persona is the canonical
  consumer).
- The schema (`compliance-tier.schema.json` v1.0.0) as single
  source of truth.
- The architecture document (`docs/ARCHITECTURE-TARGET.md` §10)
  as narrative source.
- The downstream items I.3 / I.5 / I.6 that the standard unblocks.

##### FR-I2-CT-022 — Tier definitions section (schema verbatim)

The `## Tier definitions` section MUST cite the three tier
descriptions **verbatim** from
`compliance-tier.schema.json::x-tier-descriptions` :

- T1 : `"RGPD-compliant via DPA — SaaS hors EU acceptable si DPA
  + SCC + protections complémentaires (chiffrement, BYOK), assume
  risque résiduel CLOUD Act."`
- T2 : `"Self-hostable — déployable sur n'importe quel K8s EU,
  contrôle technique mais pas qualification sovereign."`
- T3 : `"Hébergement EU strict — SecNumCloud / HDS / EUCS High,
  100% EU jurisdiction, immune CLOUD Act."`

**No paraphrase, no extension.** The K.3 Anti-Hallucination
Protocol (FR-K3-DEM-020) precedent applies — Demeter MUST be able
to cite the standard byte-for-byte against the schema. The harness
test asserts byte-equivalence via grep.

##### FR-I2-CT-023 — Component eligibility matrix section

The `## Component eligibility matrix` section MUST carry a
Markdown table mirroring `docs/ARCHITECTURE-TARGET.md §10.2` with
all **15 component rows** :

1. Flutter / Qwik (binaires client)
2. Rust + tonic + axum
3. Envoy Gateway
4. Postgres 17 + pgvector
5. DBOS (embedded library)
6. Zitadel
7. SigNoz
8. Coroot
9. OTel Collector / OBI
10. OVHcloud / Scaleway / Outscale
11. AWS / GCP / Azure
12. Firebase
13. Temporal Cloud
14. LLM Gateway (OpenAI/Anthropic)
15. NATS JetStream

Columns : `Composant | T1 | T2 | T3 | Forçage tier | Source`.
Cells preserve the source's emoji + text verbatim (✅, ⚠️ T1
only, ❌, ⚠️ Cloud SaaS T1, ✅ self-host T2, ...). The table is
the **faithful mirror** of §10.2 — no condensation, no row
elision.

##### FR-I2-CT-024 — Demeter integration section

The `## Demeter integration` section MUST :

- Cross-link to `.claude/agents/demeter.md` (Demeter persona).
- Cross-link to `.forge/standards/global/data-stewardship-rules.md`
  (K.3 standard, sibling).
- Cite FR-K3-DEM-068 (tier scaling rationale : T1 →
  Informational, T2 → High, T3 → Critical).
- Reference the K3-RULE-001..006 catalogue.
- Reference the `.forge/.forge-tier` ledger format (one line,
  content `{T1, T2, T3}` + trailing newline ; ADR-J8-006 pattern).

##### FR-I2-CT-025 — Adoption path section

The `## Adoption path` section MUST document at least two adoption
tiers :

- **Minimum viable adoption** : declare the tier in
  `.forge/.forge-tier` ; run Demeter at PR time.
- **Full adoption** : add the `.forge/.forge-dpa-declared` ledger
  when ⚠️-T1 components are in scope ; wire Demeter into the
  Janus Step 9 dispatch ; await Themis (K.5, T7+) for regulatory
  artefact aggregation.

Mirrors the K.3 `data-stewardship-rules.md::Adoption path`
structure.

##### FR-I2-CT-026 — Extending the matrix section

The `## Extending the matrix` section MUST document the BDFL
interim (Phase A) and Themis-post-T7 (Phase B) governance phases :

- **Phase A — Interim (now → Themis ships T7+)** : BDFL maintains
  the standard. SemVer minor bump for new component rows + tier
  shifts ; SemVer major bump for `x-tier-descriptions` semantics
  changes (cross-references Article XII amendment per
  Interdictions).
- **Phase B — Themis** : K.5 Themis agent inherits ownership.
  6-month rolling review cadence (faster than 12-month standards
  default because component velocity exceeds standards drift).

Mirrors the K.3 publisher-list two-phase governance pattern.

##### FR-I2-CT-027 — Interdictions section (≥ 3 MUST NOTs)

The `## Interdictions` section MUST carry at least three explicit
RFC-2119 "MUST NOT" clauses :

1. **MUST NOT paraphrase the schema** — the
   `compliance-tier.schema.json::x-tier-descriptions` block is
   the single source of truth ; the standard cites verbatim.
2. **MUST NOT add a new compliance tier** (T4, T0, sub-tier)
   **without an Article XII Constitution amendment**. T1 / T2 /
   T3 are structural ; expanding the enum is a structural change.
3. **MUST NOT silently downgrade a declared T3 project to T1**.
   Adopters edit `.forge/.forge-tier` explicitly ; Demeter detects
   ledger / flag mismatches and emits `[NEEDS CLARIFICATION:]`
   (K.3 anti-hallucination protocol).

Additional MUST NOTs MAY be added (e.g. "MUST NOT couple the
standard to any specific cloud provider's certification scheme
beyond SecNumCloud / HDS / EUCS High as named in T3" — exact list
locked at design time).

##### FR-I2-CT-028 — RFC-2119 vocabulary

The body MUST use RFC-2119 vocabulary (MUST / MUST NOT / SHOULD /
MAY) in the normative paragraphs. Informative paragraphs (e.g.
the introduction, the cross-references) may use plain prose.
At least one MUST + one MUST NOT + one SHOULD MUST appear in the
body — easy to satisfy given the FR-I2-CT-027 mandate.

##### FR-I2-CT-029 — Constitutional Compliance section (optional but recommended)

A `## Constitutional Compliance` H2 SHOULD be present (mirrors the
K.3 / J.8 standards). Lists the Articles the standard touches
(III.4 anti-hallucination, V audit trail, XI agent-native, XII
governance) and clarifies that the standard does not amend any
Article.

##### FR-I2-CT-030 — File size

The file SHOULD be between 150 and 500 lines (NFR-I2-CT-003).
Standards too short under-document ; too long deviate from the
existing standards corpus density.

---

#### Cluster 3 — Standards index registration (FR-I2-CT-040 → 045)

##### FR-I2-CT-040 — Index entry presence

`.forge/standards/index.yml` MUST gain a new entry under the
existing `standards:` list :

```yaml
  - id: global/compliance-tiers
    path: standards/global/compliance-tiers.md
    triggers: [compliance, t1, t2, t3, eu-tier, dpa, schrems, cloud-act, tier-classification]
    scope: all
    priority: high
```

##### FR-I2-CT-041 — Entry id

The `id:` field MUST be exactly `global/compliance-tiers`,
mirroring the K.3 pattern (`global/data-stewardship-rules`) and
the J.8 pattern (`global/janus-orchestration-rules`).

##### FR-I2-CT-042 — Entry path

The `path:` field MUST be exactly
`standards/global/compliance-tiers.md` (relative to
`.forge/`), matching the file location locked by FR-I2-CT-001.

##### FR-I2-CT-043 — Entry triggers

The `triggers:` list MUST contain at least the 9 keywords :
`compliance, t1, t2, t3, eu-tier, dpa, schrems, cloud-act,
tier-classification`. Additional triggers MAY be added at design
time.

##### FR-I2-CT-044 — Entry scope + priority

`scope: all` + `priority: high`. The standard applies to every
adopter independently of archetype (the EU posture is a
cross-cutting concern), priority matches K.3 (`high`).

##### FR-I2-CT-045 — Index alphabetical placement

The entry SHOULD be placed under the "Cross-Cutting Standards"
section of `index.yml`, after the K.3 entry
(`global/data-stewardship-rules`) which currently terminates the
file. Exact placement locked at design time.

---

#### Cluster 4 — REVIEW ledger entry (FR-I2-CT-050 → 052)

##### FR-I2-CT-050 — REVIEW entry presence

`.forge/standards/REVIEW.md` MUST gain a new append-only H2
section dated 2026-05-11 recording the standard's birth.

##### FR-I2-CT-051 — Entry shape

The entry MUST follow the existing schema documented at the top
of `REVIEW.md` :

```markdown
## 2026-05-11 — Initial ratification (i2-compliance-tiers)

- **Reviewer**: @bfontaine
- **Reviewed standards**: <table with global/compliance-tiers.md v1.0.0 / KEEP / 2027-05-11>
- **Decision**: KEEP
- **Next review due**: 2027-05-11
- **Notes**: <one paragraph citing the audit item + the
  consuming agent (Demeter) + the unblocked downstream items
  (I.3 / I.5 / I.6)>
```

##### FR-I2-CT-052 — Append-only invariant preserved

The new entry MUST be appended after the existing last entry
(2026-05-05 t5-connect-codegen pivot correction). No prior entry
is modified — append-only per Article XII.

---

#### Cluster 5 — Adopter intro doc (FR-I2-CT-090 → 093)

##### FR-I2-CT-090 — `docs/COMPLIANCE.md` presence

A new file `docs/COMPLIANCE.md` MUST exist at the path.
Content type Markdown.

##### FR-I2-CT-091 — H1 anchor

The file MUST open with H1 `# Forge Compliance — EU Tier
Adoption Guide` (or semantically equivalent — exact wording locked
at design time).

##### FR-I2-CT-092 — H2 section count

The file body MUST carry at least 3 H2 sections :

1. `## Quick start` — minimum-viable adoption (declare tier ; run
   Demeter).
2. `## Tier picker` — decision tree pointing to the standard.
3. `## Cross-references` — pointers to `ARCHITECTURE-TARGET §10`,
   `standards/global/compliance-tiers.md`,
   `standards/global/data-stewardship-rules.md`, `agents/demeter.md`.

##### FR-I2-CT-093 — Cross-link to the standard

The file MUST cross-link to `.forge/standards/global/compliance-tiers.md`
at least once. The cross-link is the entry-point for the deep
contract ; `docs/COMPLIANCE.md` is the adopter-facing front door.

---

#### Cluster 6 — Test harness (FR-I2-CT-100 → 112)

##### FR-I2-CT-100 — Harness file presence

A new file `.forge/scripts/tests/i2.test.sh` MUST exist. Bash
script, mirrors the J.7 / J.8 / K.3 layout (set -uo pipefail,
`--level 1` parsing, sources `_helpers.sh`, PASS/FAIL counters,
`print_summary` close-out, exit code reflects FAIL count).

##### FR-I2-CT-101 — Harness audit comment

The harness file MUST carry `<!-- Audit: I.2 (i2-compliance-tiers) -->`
in the header comment block, anchoring it to the source audit
item.

##### FR-I2-CT-102 — L1 test count

The harness MUST register at least 12 L1 hermetic tests. The
minimum coverage set :

1. `_test_i2_001_standard_exists` — FR-I2-CT-001 file presence.
2. `_test_i2_002_audit_comment` — FR-I2-CT-002 audit comment.
3. `_test_i2_003_trigger_comment` — FR-I2-CT-003 trigger comment.
4. `_test_i2_004_h1_anchor` — FR-I2-CT-004 H1 anchor.
5. `_test_i2_005_frontmatter_version` — FR-I2-CT-005/006 version.
6. `_test_i2_006_h2_sections` — FR-I2-CT-020 ≥ 6 H2 sections.
7. `_test_i2_007_tier_definitions_verbatim` — FR-I2-CT-022 schema verbatim citation (grep T1/T2/T3 strings).
8. `_test_i2_008_matrix_rows` — FR-I2-CT-023 ≥ 15 matrix rows.
9. `_test_i2_009_demeter_crosslink` — FR-I2-CT-024 Demeter cross-link.
10. `_test_i2_010_interdictions` — FR-I2-CT-027 ≥ 3 MUST NOTs.
11. `_test_i2_011_index_entry` — FR-I2-CT-040 standards/index.yml entry.
12. `_test_i2_012_review_entry` — FR-I2-CT-050 REVIEW.md entry.

##### FR-I2-CT-103 — Compliance doc presence

The harness MUST include at least one test asserting
`docs/COMPLIANCE.md` exists with the H1 + ≥ 3 H2 sections per
FR-I2-CT-090 / FR-I2-CT-091 / FR-I2-CT-092.

##### FR-I2-CT-104 — CHANGELOG entry assertion

The harness MUST include at least one test asserting
`CHANGELOG.md` `[Unreleased]` carries a section
mentioning `i2-compliance-tiers` per FR-I2-CT-080.

##### FR-I2-CT-110 — CI registration

`.github/workflows/forge-ci.yml` MUST register `i2.test.sh` in
the `harness` job matrix, placed after `k3.test.sh`, invoked as
`bash .forge/scripts/tests/i2.test.sh --level 1`.

##### FR-I2-CT-111 — Exit codes

The harness MUST exit 0 when all tests PASS, exit 1 when any L1
test FAILs. Argument `--level 1` (default) runs L1 ; no L2 tier
in this initial release.

##### FR-I2-CT-112 — Validate-standards-yaml integration

`bash bin/validate-standards-yaml.sh` MUST NOT regress (the new
standard is MD, not YAML — out of scope for J.7 ; but the live
tree GREEN baseline NFR-J7-002 is preserved by the additive
nature of this change).

---

#### Cluster 7 — CHANGELOG (FR-I2-CT-080 → 081)

##### FR-I2-CT-080 — CHANGELOG entry

`CHANGELOG.md` `## [Unreleased]` MUST gain a new
`### Added — I.2 compliance-tiers standard (`i2-compliance-tiers`)`
H3 section. The section MUST list :

- The new standard file path.
- The standards/index.yml registration.
- The REVIEW.md ledger entry.
- The `docs/COMPLIANCE.md` adopter intro.
- The `.forge/scripts/tests/i2.test.sh` harness.
- The forge-ci.yml matrix row.

##### FR-I2-CT-081 — Audit cross-reference

The CHANGELOG entry MUST cite the I.2 audit item from
`docs/new-archetypes-plan.md` §7.1 line 727 + reference the K.3
forward-pointer that the standard resolves.

---

### Non-Functional Requirements

#### NFR-I2-CT-001 — Test harness performance budget

`.forge/scripts/tests/i2.test.sh --level 1` MUST complete in
≤ 3 seconds wall-clock on a standard CI runner. L1 tests are
hermetic grep-based assertions ; no network, no fixture setup.

#### NFR-I2-CT-002 — Backward compatibility

The change is **additive only**. No existing standard, no existing
schema, no existing CI workflow row is modified. Existing matrix
rows in `forge-ci.yml` are preserved verbatim ; the new row is
appended. The standards/index.yml entry is appended ; no existing
entry is reordered. The REVIEW.md ledger is appended ; the
append-only invariant is preserved.

#### NFR-I2-CT-003 — Standard file size

`.forge/standards/global/compliance-tiers.md` SHOULD be between
150 and 500 lines. Standards under 150 lines under-document the
matrix + adoption path + interdictions ; over 500 lines deviate
from the existing corpus density (K.3 ~220 lines, J.8 ~120 lines,
SBOM policy ~85 lines).

#### NFR-I2-CT-004 — Verbatim-citation invariant

The three `x-tier-descriptions` strings (T1 / T2 / T3) MUST be
reproduced byte-identical to
`.forge/schemas/compliance-tier.schema.json` v1.0.0. The harness
test `_test_i2_007_tier_definitions_verbatim` asserts byte
equivalence via grep -F (fixed string match).

#### NFR-I2-CT-005 — Matrix row count invariant

The component matrix MUST carry exactly 15 rows matching
`docs/ARCHITECTURE-TARGET.md §10.2`. Adding or removing a row
requires a SemVer minor bump in the standard's frontmatter ;
changing a cell value requires a justified note in the REVIEW.md
ledger.

#### NFR-I2-CT-006 — No external dependency

The change introduces no new external dependency. Standard is
pure Markdown ; harness is bash + grep ; CI matrix gains one
row using the existing bash runtime.

#### NFR-I2-CT-007 — Deterministic harness

The harness MUST be deterministic. No randomised inputs, no
network calls, no time-dependent assertions (beyond the
`last_reviewed` literal-string match against the file).
Two consecutive runs produce identical PASS/FAIL output.

---

## Acceptance Criteria

A merge of `i2-compliance-tiers` is acceptable when :

1. `.forge/standards/global/compliance-tiers.md` ships with all
   FR-I2-CT-001..030 satisfied (frontmatter + 6+ H2 sections +
   15-row matrix + 3+ MUST NOTs).
2. `.forge/standards/index.yml` registers the new standard
   (FR-I2-CT-040..045).
3. `.forge/standards/REVIEW.md` carries the append-only birth
   entry (FR-I2-CT-050..052).
4. `docs/COMPLIANCE.md` ships with the 3+ H2 adopter intro
   (FR-I2-CT-090..093).
5. `.forge/scripts/tests/i2.test.sh` ships with ≥ 12 L1 tests,
   all GREEN end-to-end (FR-I2-CT-100..112).
6. `.github/workflows/forge-ci.yml` matrix registers `i2.test.sh`
   after `k3.test.sh` (FR-I2-CT-110).
7. `CHANGELOG.md` `[Unreleased]` carries the I.2 entry
   (FR-I2-CT-080..081).
8. `bash .forge/scripts/verify.sh` overall PASS.
9. `bash .forge/scripts/constitution-linter.sh` overall PASS.
10. `bash bin/validate-standards-yaml.sh` remains GREEN
    (NFR-J7-002 baseline preserved).

---

## BDD Scenarios (Article II)

### Scenario 1 — Reviewer reads the standard

```gherkin
Given a reviewer reading .forge/standards/global/compliance-tiers.md
When they search the file for "RGPD-compliant via DPA"
Then the T1 description appears verbatim from compliance-tier.schema.json

Given a reviewer reading the same standard
When they count the H2 sections
Then there are at least 6 sections (Purpose, Tier definitions,
  Component eligibility matrix, Demeter integration, Adoption path,
  Extending the matrix, Interdictions)
```

### Scenario 2 — Adopter onboards via docs/COMPLIANCE.md

```gherkin
Given an adopter new to Forge's EU compliance posture
When they open docs/COMPLIANCE.md
Then they find a "Quick start" H2 that tells them to declare
  the tier in .forge/.forge-tier and run Demeter

Given the same adopter following the cross-references
When they click through to the standard
Then they land on .forge/standards/global/compliance-tiers.md
```

### Scenario 3 — Demeter resolves its forward-pointer

```gherkin
Given the Demeter persona file (.claude/agents/demeter.md)
When a reviewer clicks the cross-link to global/compliance-tiers.md
Then the file exists on disk (i2-compliance-tiers archived)

Given Demeter classifying a component against the tier matrix
When Demeter cites the standard for the T1/T2/T3 row of a component
Then the standard's matrix row matches docs/ARCHITECTURE-TARGET.md
  §10.2 verbatim (no paraphrase, FR-K3-DEM-020 preserved)
```

### Scenario 4 — Harness runs in CI

```gherkin
Given the forge-ci.yml `harness` job
When the runner reaches the i2.test.sh step
Then the harness executes in ≤ 3 seconds and exits 0

Given the same harness invoked locally as
  `bash .forge/scripts/tests/i2.test.sh --level 1`
When all 12+ L1 tests run
Then PASS = test count, FAIL = 0, exit 0
```

---

## Open Questions

Three questions Q-001 / Q-002 / Q-003 carried over from
`proposal.md`. All three are slated for resolution at
`/forge:design` and tracked in `open-questions.md`. Provisional
leans :

- **Q-001** → Option A : `linter_rule: t3-forbidden-components`
  forward-pointer.
- **Q-002** → Option A : verbatim 15-row matrix.
- **Q-003** → Option A : root `docs/COMPLIANCE.md`.

No `[NEEDS CLARIFICATION:]` inline markers in this specs.md.
