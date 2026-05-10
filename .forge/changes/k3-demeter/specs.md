# Specifications: k3-demeter
<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-K3-DEM-*` / `NFR-K3-DEM-*`. **Constitution** :
v1.1.0. Pas d'amendement requis (K.3 introduces a new agent +
scanner ; existing articles unchanged).

## Source Documents

| Field             | Value                                                                                                                                                                                |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Audit base**    | `K.3` (`new-archetypes-plan` §1.4 row 353 + §9 line 779) + `I.4` (`new-archetypes-plan` §7.1 line 733)                                                                                |
| **ADR base**      | `t4-adr-ratification` archived 2026-05-04 (FR-T4-ADR-007 / 008 / 010 ratifying Schrems II + CLOUD Act + EU compliance positioning ; FR-T4-SCH-001..002 ratifying compliance-tier + archetype.schema v2) ; `j8-janus-rules` archived 2026-05-10 (ADR-J8-004 rule-ID format ; ADR-J8-005 helper-pattern) |
| **Plan ref**      | `docs/new-archetypes-plan.md` §1.4 row K.3 + §7.1 line 733 + §9 lines 779 ; `docs/ARCHITECTURE-TARGET.md` §9.2 line 717 + §10 lines 731-779 + §11.2 line 800 + §12.5 lines 957-967    |
| **Roadmap ref**   | `.forge/product/roadmap.md` Phase 3 / T5 row ("K.3 Demeter agent — Pending T5")                                                                                                       |
| **Schema reuse**  | `.forge/schemas/compliance-tier.schema.json` v1.0.0 (T.4 — enum `[T1, T2, T3]`) ; `.forge/schemas/archetype.schema.json` v2 (5-archetype enum)                                        |
| **Pattern reuse** | `j8-janus-rules` (ADR-J8-004 rule-ID format ; ADR-J8-005 helper sourcing pattern ; ADR-J8-006 plain-text ledger ; ADR-J8-007 F.2 / J.7 bash + Python 3 inline pattern for the scanner) |
| **Standard refs** | `identity.yaml` v1.0.0 (Zitadel default + forbidden Firebase Auth) ; `observability.yaml` v1.1.0 (forbidden Datadog) ; `persistence.yaml` v1.0.0 (forbidden_for_eu_strict) ; `global/janus-orchestration-rules.md` (J.8 — sibling pattern) |
| **CLOUD Act ref** | Schrems II decision (CJEU C-311/18, 2020) ; CLOUD Act 18 U.S.C. §2713 ; EDPB Recommendations 01/2020 on supplementary measures                                                       |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Demeter persona file (FR-K3-DEM-001 → 008)

##### FR-K3-DEM-001 — Persona file location

`.claude/agents/demeter.md` MUST exist as the canonical Demeter
persona file at the path locked by ADR-K3-001 (design phase). The
file follows the `.claude/agents/<name>.md` convention used by
all 16 existing Forge agents (e.g. `security-auditor.md`,
`observability-specialist.md`).

##### FR-K3-DEM-002 — Persona section

The file MUST start with an H1 `# Agent: Data Steward EU
(Demeter)` and a `## Persona` H2 declaring :
- **Name** : Demeter (Greek goddess of harvest and law-bound
  cycles — the natural patron of regulated data flows).
- **Role** : Data steward EU — classifies data, validates DPA
  posture, detects CLOUD Act exposure in dependency manifests.
- **Style** : Methodical, severity-first, evidence-driven.
  Mirrors the Aegis stylistic pattern (every finding carries a
  severity, specific evidence, and actionable remediation).

##### FR-K3-DEM-003 — Purpose section

A `## Purpose` H2 MUST describe Demeter's three responsibilities
and explicitly cite the source audit items (K.3 + I.4) and the
upstream T.4 schemas Demeter consumes
(`compliance-tier.schema.json`).

##### FR-K3-DEM-004 — Checklists section

A `## Checklists` H2 MUST host at least three sub-sections
(H3) :
- **Data Classification** (T1 / T2 / T3 against
  `compliance-tier.schema.json::x-tier-descriptions`).
- **DPA Validation** (declaration presence at T1 ; informational
  at T2 / T3).
- **CLOUD Act Exposure** (jurisdiction matching against the
  cloud-act publishers list).

Each sub-section MUST follow the Aegis bullet-checklist style :
`[ ] item` lines with `Verify: <how>` + `Check: <what>` +
`Exception: <when>` annotations. The sub-sections MUST be
greppable for `[ ]` markers per the Aegis pattern (≥ 5 items per
sub-section).

##### FR-K3-DEM-005 — Output report format

An `## Output: Data Stewardship Report` H2 MUST declare the
report shape :
- A `Summary` table with severity counts (Critical / High /
  Medium / Low / Informational) mirroring Aegis's table.
- A `Findings` section with per-finding entries citing :
  `[SEVERITY] <K3-RULE-NNN>: <title>`, `Category`, `Location`,
  `Evidence`, `Risk`, `Remediation`, `Verification`.
- A `Cleared Items` section listing checklist items the audit
  verified clean.
- An overall status line : `BLOCKED` / `CONCERNS` / `CLEARED`
  (BLOCKED on any Critical or High ; mirrors Aegis).

##### FR-K3-DEM-006 — Rule catalogue section

A `## Rule Catalogue` H2 MUST enumerate the seed `K3-RULE-*`
rules (≥ 5 rules, see Cluster 9). Each rule MUST cite : (a)
trigger condition, (b) severity, (c) evidence pattern, (d)
remediation hint, (e) cross-link to the relevant standard or
ADR.

##### FR-K3-DEM-007 — Integration section

A `## Integration` H2 MUST describe :
- How Janus dispatches Demeter at Step 9 (security pass) of the
  cross-layer workflow (cross-link to
  `cross-layer-orchestrator.md` Step 9 narrative).
- How `forge audit --compliance` (CLI surface declared in
  ARCHITECTURE-TARGET §12.4 line 952 — not yet implemented)
  invokes Demeter.
- The relationship to Aegis (Demeter and Aegis are siblings —
  Demeter owns data-stewardship, Aegis owns vulnerability
  posture).
- The relationship to Themis (K.5, deferred to T7) — Themis is
  the future compliance officer that consumes Demeter outputs at
  the regulatory-deadline level.

##### FR-K3-DEM-008 — Anti-hallucination protocol

A `## Anti-Hallucination Protocol` H2 MUST state that when a
classification is ambiguous (e.g. a publisher whose
jurisdiction has changed mid-cycle, a dependency in a lockfile
that is not in the
`.forge/data/cloud-act-publishers.yml` list), Demeter MUST emit
`[NEEDS CLARIFICATION: <specific question>]` and STOP — never
guess. This is the Article III.4 contract.

---

#### Cluster 2 — Audit-comment header anchors (FR-K3-DEM-010 → 011)

##### FR-K3-DEM-010 — Audit comment

The persona file MUST carry a top-of-file
`<!-- Audit: K.3 (k3-demeter) -->` HTML comment per the Forge
audit-trail convention. A second
`<!-- Audit: I.4 (k3-demeter) -->` comment MAY be added if I.4
items materialize as direct outputs of this change.

##### FR-K3-DEM-011 — Source citations

Every paragraph that imports a constraint from
`docs/ARCHITECTURE-TARGET.md` or `docs/new-archetypes-plan.md`
MUST cite the section + line range (e.g. "ARCHITECTURE-TARGET
§9.2 line 717"). This is the same convention Aegis uses.

---

#### Cluster 3 — T1 / T2 / T3 classification logic (FR-K3-DEM-020 → 026)

##### FR-K3-DEM-020 — Tier source of truth

Demeter MUST consume `compliance-tier.schema.json` v1.0.0 as the
single source of truth for tier definitions. The persona file
MUST cite the `x-tier-descriptions` block verbatim (the three
sentences for T1 / T2 / T3) and MUST NOT redefine, paraphrase,
or extend tier semantics.

##### FR-K3-DEM-021 — Tier inference

When an adopter has not declared `--eu-tier` (the J.8 flag is
absent and no `.forge/.forge-tier` ledger exists), Demeter MUST
emit `[NEEDS CLARIFICATION: compliance tier undeclared — pass
--eu-tier T1|T2|T3 or write .forge/.forge-tier]` and STOP. No
default tier is inferred.

##### FR-K3-DEM-022 — Tier matrix consumption

Demeter MUST consume the component-tier eligibility matrix from
`docs/ARCHITECTURE-TARGET.md` §10.2 lines 740-758 (rows :
Flutter, Rust, Envoy Gateway, Postgres, DBOS, Zitadel, SigNoz,
Coroot, OTel, OVH/Scaleway/Outscale, AWS/GCP/Azure, Firebase,
Temporal Cloud, LLM Gateway, NATS JetStream). The matrix is
encoded **textually** in the persona checklists ; it is **not**
re-implemented as a YAML data structure in this change (a
future I.2 standard `global/compliance-tiers.md` will own the
machine-readable form).

##### FR-K3-DEM-023 — T1 acceptance posture

At T1, Demeter MUST accept any component listed as `✅` or `⚠️
T1` in the §10.2 matrix, provided the DPA-validation check
(Cluster 5) succeeds. T1 components flagged `⚠️` MUST surface as
severity `Informational` findings citing the residual CLOUD Act
risk per `compliance-tier.schema.json::x-tier-descriptions.T1`.

##### FR-K3-DEM-024 — T2 acceptance posture

At T2, Demeter MUST refuse any component flagged `❌` for T2 in
the §10.2 matrix (e.g. Firebase, AWS / GCP / Azure managed
services for T2 strict). Refusals at T2 emit severity `High`
findings.

##### FR-K3-DEM-025 — T3 acceptance posture

At T3, Demeter MUST refuse any component flagged `❌` for T3 OR
flagged `⚠️ T1 only` for T1 (e.g. AWS / GCP / Azure managed
services, LLM Gateway non-EU). Refusals at T3 emit severity
`Critical` findings. T3 enforcement is the strictest tier.

##### FR-K3-DEM-026 — `forge-tier` consumption

Demeter MUST read `.forge/.forge-tier` when present (the ledger
file shipped by `j8-janus-rules` ADR-J8-006) as the canonical
declared tier. The ledger format is plain text, one line, value
in `{T1, T2, T3}` with mandatory trailing newline. Mismatch
between `.forge-tier` and an explicit `--eu-tier` flag emits
`[NEEDS CLARIFICATION: tier ledger mismatch — ledger says <X>,
flag says <Y>]`.

---

#### Cluster 4 — DPA validation (FR-K3-DEM-040 → 044)

##### FR-K3-DEM-040 — Declaration surface

Demeter MUST verify the adopter has *declared* DPA presence via
`.forge/.forge-dpa-declared` plain-text ledger file (one line,
content `T1: <ISO-8601-date> <free-form-ref>` with mandatory
trailing newline) per ADR-K3-002 (design phase, resolves
Q-001). The declaration is **proof-of-attestation**, not
legal-document parsing.

##### FR-K3-DEM-041 — T1 DPA-required check

When `compliance_tier: T1` AND the project uses any component
flagged `⚠️ T1` or `⚠️ Cloud SaaS T1` in the §10.2 matrix
(Zitadel cloud, SigNoz cloud, Temporal Cloud, LLM Gateway, AWS
/ GCP / Azure single-component), Demeter MUST verify
`.forge/.forge-dpa-declared` exists. Absence emits a
`K3-RULE-002` severity-`High` finding.

##### FR-K3-DEM-042 — T2 / T3 DPA informational

At T2 / T3 the declaration is **informational** — adopters who
self-host don't need a DPA to a non-EU SaaS, but having a DPA
declared anyway (e.g. for residual third-party SaaS used by the
adopter outside Forge scope) is recorded as a `Cleared` item
not as a finding.

##### FR-K3-DEM-043 — Stale declaration

Demeter MUST parse the date in the ledger line (ISO-8601
`YYYY-MM-DD`). If the date is older than 13 months (RGPD
review cycle + 1 month grace), emit a `K3-RULE-002a` severity-
`Medium` finding suggesting refresh.

##### FR-K3-DEM-044 — Out-of-scope clarification

The persona MUST explicitly state that Demeter does NOT parse
DPA legal text, does NOT verify SCC clauses, does NOT check
signature authenticity. These are out-of-scope (legal-domain
work). The `.forge-dpa-declared` ledger is a self-declared
attestation surface only.

---

#### Cluster 5 — CLOUD Act dependency detection (FR-K3-DEM-060 → 074)

##### FR-K3-DEM-060 — Scanner script

`bin/forge-demeter-scan.sh` MUST exist as executable bash
(`#!/usr/bin/env bash`, `set -uo pipefail`) following the F.2 /
J.7 / J.8.d pattern verbatim per NFR-K3-DEM-004. Signature :
```
bin/forge-demeter-scan.sh [--target <dir>] [--tier T1|T2|T3] [--output <path>] [--format json|md]
```
Defaults : `--target $(pwd)`, `--tier $(cat
$target/.forge/.forge-tier 2>/dev/null)` (or `[NEEDS
CLARIFICATION:]` if ledger absent), `--output
demeter-report.json`, `--format json`.

##### FR-K3-DEM-061 — Exit codes

Exit codes MUST be :
- `0` — CLEARED (no findings, no Critical / High in the report).
- `1` — CONCERNS (Medium findings present, no Critical / High).
- `2` — usage error (bad args).
- `3` — BLOCKED (Critical or High findings present — matches the
  J.8 ADR-J8-003 policy-refusal exit code semantics).

##### FR-K3-DEM-062 — Lockfile detection

The scanner MUST detect, in `--target`, the presence of any of :
- `Cargo.lock` (Rust workspace root or member crate)
- `package-lock.json` OR `pnpm-lock.yaml` OR `yarn.lock` (npm
  family — at least one accepted)
- `pubspec.lock` (Dart / Flutter)

Lockfile detection MUST recurse to a maximum depth of 3
directories (default Forge monorepo layout :
`{frontend,backend,shared/protos}` are at depth 1 ; sub-crates
at depth 2-3).

At least one lockfile MUST be present, else exit 2 with
diagnostic citing the lockfile-detection requirement.

##### FR-K3-DEM-063 — Cargo.toml-only refusal

If `Cargo.toml` is present in `--target` but `Cargo.lock` is
absent (workspace drift), the scanner MUST refuse to classify
the workspace and emit a `K3-RULE-005` severity-`Medium`
finding. Cargo dependencies without a lockfile cannot be
deterministically jurisdiction-classified.

##### FR-K3-DEM-064 — Publisher list source

The scanner MUST read `.forge/data/cloud-act-publishers.yml` as
the single source of truth for jurisdiction classification.
File shape (locked at design phase, ADR-K3-003 resolves Q-002) :
```yaml
version: "1.0.0"
last_reviewed: "2026-05-10"
expires_at: "2027-05-10"
maintained_by: "BDFL (interim — see standards/global/data-stewardship-rules.md)"
ecosystems:
  cargo:
    - publisher: "<author-name>"
      jurisdiction: "US"
      evidence: "<crates.io profile or company HQ ref>"
  npm:
    - publisher: "<scope-or-author>"
      jurisdiction: "US"
      evidence: "<npm profile or company HQ ref>"
  pub:
    - publisher: "<author-name>"
      jurisdiction: "US"
      evidence: "<pub.dev profile or company HQ ref>"
```

##### FR-K3-DEM-065 — Cargo classification

For each entry in `Cargo.lock`, the scanner MUST extract the
`name`, `version`, `source` (registry URL), and the publisher
metadata (resolved from `crates.io` API cache or from the
`cloud-act-publishers.yml` deny-list). Deny-list match emits a
`K3-RULE-001` finding with severity scaling per declared tier
(`Informational` at T1 ; `High` at T2 ; `Critical` at T3).

##### FR-K3-DEM-066 — npm classification

For each entry in `package-lock.json` (or pnpm/yarn lock), the
scanner MUST extract `name`, `version`, and the publisher scope
(e.g. `@aws-sdk/*` → AWS-published). Scope or author match
against `cloud-act-publishers.yml::ecosystems.npm` deny-list
emits a `K3-RULE-001` finding. Severity scaling per
FR-K3-DEM-065.

##### FR-K3-DEM-067 — pub classification

For each entry in `pubspec.lock`, the scanner MUST extract
`name`, `version`, `description.name` (publisher), and the
hosted URL. Match against
`cloud-act-publishers.yml::ecosystems.pub` deny-list emits a
`K3-RULE-001` finding. Severity scaling per FR-K3-DEM-065.

##### FR-K3-DEM-068 — Tier-based severity scaling

A single `K3-RULE-001` rule MUST scale severity based on the
declared `--eu-tier` :
- T1 → `Informational` (residual CLOUD Act risk acknowledged
  per the T1 tier description).
- T2 → `High` (T2 declares "self-hostable" — US-jurisdiction
  publishers contradict the posture).
- T3 → `Critical` (T3 declares "100% EU jurisdiction" — any
  US-jurisdiction dependency is a tier violation).

##### FR-K3-DEM-069 — Determinism

Two consecutive runs against the same target tree MUST produce
**identical output bytes** when `SOURCE_DATE_EPOCH` is set
(reproducible-build convention, mirrors `forge-sbom.sh`
NFR-J8-005). Components in the JSON report MUST be sorted by
`(ecosystem, name, version)` lexicographic key.

##### FR-K3-DEM-070 — Offline mode

The scanner MUST support a fully offline mode : when network
access is denied and no `crates.io` / `npm` / `pub.dev` cache is
populated, the scanner falls back to deny-list-only
classification. Coverage drop is reported in the JSON report
under `metadata.coverage_mode: "offline-deny-list-only"`.

##### FR-K3-DEM-071 — JSON report shape

The JSON report MUST conform to the shape :
```json
{
  "version": "1.0.0",
  "generated_at": "<ISO-8601 timestamp>",
  "target": "<absolute-path>",
  "declared_tier": "T1|T2|T3|null",
  "summary": {
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0,
    "informational": 0,
    "cleared": 0
  },
  "overall_status": "BLOCKED|CONCERNS|CLEARED",
  "findings": [
    {
      "rule_id": "K3-RULE-NNN",
      "severity": "...",
      "category": "data-classification|dpa|cloud-act|tier-mismatch",
      "location": "<file:line>",
      "evidence": "<snippet>",
      "risk": "<one-line>",
      "remediation": "<numbered steps>",
      "verification": "<how-to-confirm-fix>"
    }
  ],
  "cleared": [
    {"rule_id": "...", "verified": "..."}
  ],
  "metadata": {
    "scanner_version": "0.1.0",
    "publisher_list_version": "1.0.0",
    "publisher_list_last_reviewed": "<date>",
    "coverage_mode": "online|offline-deny-list-only"
  }
}
```

##### FR-K3-DEM-072 — Markdown report shape

When `--format md`, the scanner MUST emit a Markdown report
mirroring Aegis's "Security Audit Report" shape (the template
in `security-auditor.md::Output: Security Report`). The MD form
is human-readable ; the JSON form is machine-parseable. Both
forms cover the same findings.

##### FR-K3-DEM-073 — Reproducible publisher list

The `.forge/data/cloud-act-publishers.yml` file MUST carry
`last_reviewed:` and `expires_at:` ISO-8601 dates. Demeter MUST
emit a `K3-RULE-006` severity-`Medium` finding when
`expires_at < today` (list staleness).

##### FR-K3-DEM-074 — No paid services

The scanner MUST function without any paid scanning service
(Snyk, Sonatype, JFrog Xray, etc.). Network access is OPTIONAL
(for `crates.io` / `npm` / `pub.dev` enrichment) ; offline
fallback is mandatory per FR-K3-DEM-070.

---

#### Cluster 6 — Constitution-linter / Janus / dispatch-table integration (FR-K3-DEM-080 → 086)

##### FR-K3-DEM-080 — Janus dispatch-table cross-link

`.claude/agents/cross-layer-orchestrator.md` MUST gain a single
new row in its **Dispatch Table** (the H2 table at lines 21-32
today) :

| `Data stewardship across layers — tier classification, DPA, CLOUD Act exposure` | **Demeter** (Data Steward EU) | Demeter performs data-stewardship reviews that cross layer boundaries ; complementary to Aegis's vulnerability-focused security pass. |

The row MUST be placed **after** the Aegis row (security review)
and **before** the closing `---` of the table.

##### FR-K3-DEM-081 — Janus Step 9 narrative

The "Step 9 — Security Pass (Aegis)" H3 in
`cross-layer-orchestrator.md` MUST be MODIFIED to "Step 9 —
Security & Data-Stewardship Pass (Aegis + Demeter)" with two
paragraphs : the existing Aegis paragraph (unchanged) + a new
Demeter paragraph describing the dispatch.

This is a **delta-based modification** per Article IV.1 ;
captured in `tasks.md` Phase 2.

##### FR-K3-DEM-082 — Standards index registration

`.forge/standards/index.yml` MUST gain a new entry :
```yaml
- id: global/data-stewardship-rules
  path: standards/global/data-stewardship-rules.md
  triggers: [demeter, data-steward, dpa, cloud-act, schrems, t1, t2, t3, dependency-jurisdiction, k3-rule]
  scope: all
  priority: high
```

##### FR-K3-DEM-083 — Standard file existence

`.forge/standards/global/data-stewardship-rules.md` MUST exist
with at least 5 H2 sections : Purpose, Rule catalogue
(`K3-RULE-NNN` table), Adoption path, DPA declaration semantics,
Extending the catalogue. Markdown only — no YAML frontmatter (so
J.7 validation is informational not blocking, mirrors J.8's
`janus-orchestration-rules.md`).

##### FR-K3-DEM-084 — CLAUDE.md trigger registration

The repo-level `CLAUDE.md` (or the agent dispatch table
fragment locked at design time) MUST gain a new row :

| Data stewardship | **Demeter** | Data Steward EU |

The row MUST be placed alphabetically between `AI features
(Oracle)` and `Domain modeling (Socrates)`.

##### FR-K3-DEM-085 — Dispatch-table is not edited

`.forge/scaffolding/dispatch-table.yml` is **NOT** edited by
this change. Demeter is invoked by Janus and by `forge audit`
(future), not by the CLI's scaffold-time init dispatcher.

##### FR-K3-DEM-086 — No K3-RULE collision with J8-RULE

The `K3-RULE-*` namespace MUST NOT collide with the
`J8-RULE-*` namespace shipped by `j8-janus-rules`. Rule-ID
format `<MODULE>-RULE-NNN` per ADR-J8-004 makes collision
syntactically impossible — but the spec asserts the invariant
explicitly so reviewers can grep for it.

---

#### Cluster 7 — Test harness `k3.test.sh` (FR-K3-DEM-100 → 102)

##### FR-K3-DEM-100 — Harness exists

`.forge/scripts/tests/k3.test.sh` MUST exist mirroring the
J.7 / J.8 / T.5-OTel layout : bash header, `_helpers.sh` source,
PASS/FAIL counters, `--level 1,2` parsing, `print_summary`
close-out.

##### FR-K3-DEM-101 — L1 coverage ≥ 18 tests

Minimum 18 L1 tests covering :
- 3 persona file structure (file exists + audit comment +
  Persona / Purpose / Checklists / Output / Rule Catalogue /
  Integration / Anti-Hallucination H2 anchors).
- 3 checklist sub-section presence (Data Classification + DPA
  Validation + CLOUD Act Exposure H3 anchors with ≥ 5 `[ ]`
  items each).
- 3 rule catalogue (K3-RULE-001..005 anchors present).
- 3 scanner script (`bin/forge-demeter-scan.sh` exists +
  signature parses + exit codes 0/1/2/3 distinct).
- 2 publisher list (`.forge/data/cloud-act-publishers.yml`
  exists + valid YAML + `last_reviewed` + `expires_at` keys).
- 2 standard (`global/data-stewardship-rules.md` exists with
  ≥ 5 H2 sections + index.yml entry registered).
- 1 Janus integration (cross-layer-orchestrator.md gains the
  Demeter dispatch row + Step 9 narrative MODIFIED).
- 1 CLAUDE.md trigger row added.

##### FR-K3-DEM-102 — L2 coverage ≥ 2 fixture tests

Minimum 2 L2 fixtures :
- **L2-deny-list-hit** : tmpdir with synthetic `Cargo.lock`
  declaring an `aws-sdk-*` cargo crate (deny-listed) +
  `.forge/.forge-tier` set to `T3` ; assert scanner exits 3
  with `BLOCKED` overall status + 1 `K3-RULE-001` Critical
  finding.
- **L2-clean-tree** : tmpdir with synthetic `Cargo.lock` whose
  packages are NOT on the deny-list + `.forge/.forge-tier` set
  to `T2` ; assert scanner exits 0 with `CLEARED` overall
  status + 0 findings.

---

#### Cluster 8 — Documentation (FR-K3-DEM-110 → 112)

##### FR-K3-DEM-110 — `docs/AGENTS.md` (or equivalent) entry

The doc that catalogues Forge agents (filename locked at design
time — likely `docs/AGENTS.md`, else `docs/agents/README.md`)
MUST gain a new H2 section "Demeter — Data Steward EU"
summarising the persona, the three responsibilities, and the
invocation surfaces (Janus Step 9 + future
`forge audit --compliance`).

##### FR-K3-DEM-111 — `CHANGELOG.md` entry

A new entry under `## [Unreleased]` summarising the three
sub-modules (K.3.a persona, K.3.b scanner, K.3.c standards
integration).

##### FR-K3-DEM-112 — Audit cross-references

The persona file footer MUST cite the four upstream sources
that justify Demeter's existence, with section + line refs :
- `docs/ARCHITECTURE-TARGET.md` §9.2 line 717
- `docs/ARCHITECTURE-TARGET.md` §10 lines 731-779
- `docs/ARCHITECTURE-TARGET.md` §11.2 line 800
- `docs/new-archetypes-plan.md` §1.4 row K.3 line 353
- `docs/new-archetypes-plan.md` §7.1 line 733
- `docs/new-archetypes-plan.md` §9 lines 779

---

#### Cluster 9 — Seed K3-RULE catalogue (FR-K3-DEM-120 → 124)

The seed K.3 rule catalogue per ADR-K3-005 (design phase,
resolves Q-003 — incremental growth, 5 seed rules).

##### FR-K3-DEM-120 — K3-RULE-001 — US-jurisdiction publisher

**Trigger** : a dependency in any detected lockfile resolves to
a publisher present in
`.forge/data/cloud-act-publishers.yml::ecosystems.*` deny-list.
**Severity** : tier-scaled per FR-K3-DEM-068. **Remediation** :
replace with EU-jurisdiction equivalent OR downgrade declared
tier.

##### FR-K3-DEM-121 — K3-RULE-002 — DPA undeclared at T1

**Trigger** : `compliance_tier: T1` AND project uses any
component flagged `⚠️ T1` in §10.2 matrix AND
`.forge/.forge-dpa-declared` is absent. **Severity** : `High`.
**Remediation** : create `.forge/.forge-dpa-declared` with
`T1: <date> <free-form-ref>` content OR downgrade dependency
posture (use only ✅ T1 components).

##### FR-K3-DEM-122 — K3-RULE-003 — Tier downgrade refused

**Trigger** : a change introduces a new US-jurisdiction
dependency in a project currently declared at T2 or T3
(detected via diff against the merge base — out of scope for
the scanner script in this change ; documented in the rule for
future automation in I.5 workflow). **Severity** : `Critical`
at T3, `High` at T2. **Remediation** : revert dependency OR
formally downgrade declared tier with audit trail.

##### FR-K3-DEM-123 — K3-RULE-004 — Data classification missing

**Trigger** : domain entity carries PII per Demeter heuristics
(field names matching `email`, `phone`, `ssn`, `iban`, `dob`,
…) but no `data_classification:` block in its companion design
doc. **Severity** : `Medium`. **Remediation** : add
`data_classification:` block to the entity's design doc OR
remove PII fields. Heuristic list locked at design phase
(ADR-K3-006).

##### FR-K3-DEM-124 — K3-RULE-005 — Cargo workspace drift

**Trigger** : `Cargo.toml` is present but `Cargo.lock` is
absent, OR `Cargo.lock` is present but a dependency declared
in `Cargo.toml` is missing from `Cargo.lock`. **Severity** :
`Medium`. **Remediation** : run `cargo generate-lockfile` and
re-run Demeter.

---

### Non-Functional Requirements

#### NFR-K3-DEM-001 — Performance budget

`bin/forge-demeter-scan.sh` MUST complete in ≤ 8 s on
`examples/forge-fsm-example/` (small monorepo, ~ 50 deps total
across the three lockfiles). Harness `k3.test.sh --level 1`
≤ 5 s ; full `--level 1,2` ≤ 20 s.

#### NFR-K3-DEM-002 — Backward compatibility

This change is purely additive. Adopters not invoking Demeter
(no `forge audit --compliance` call, no Janus cross-layer
review) MUST observe ZERO behavioural change.

#### NFR-K3-DEM-003 — Article V audit trail

Every task tagged `[Story: FR-K3-DEM-XXX]`. Every Demeter
finding carries `K3-RULE-NNN` + structured JSON shape, jointly
machine-parseable per Article V.1 (enforced by
`f4-linter-extension`).

#### NFR-K3-DEM-004 — F.2 / J.7 / J.8 pattern alignment

`bin/forge-demeter-scan.sh` follows the bash + Python 3 inline
pattern of `forge-sbom.sh` (J.8.d), `validate-standards-yaml.sh`
(J.7), and `validate-change-yaml.sh` (F.2). No new external
dependencies (PyYAML already required).

#### NFR-K3-DEM-005 — Reproducibility

Scanner output is byte-identical across consecutive runs when
`SOURCE_DATE_EPOCH` is set (mirrors `forge-sbom.sh`
NFR-J8-005). Reproducible-build convention preserved.

#### NFR-K3-DEM-006 — No paid scanning service

The scanner MUST NOT depend on Snyk, Sonatype, JFrog Xray,
GitHub Advanced Security, or any paid scanning service. The
deny-list approach is curated in-repo per NFR-K3-DEM-008.

#### NFR-K3-DEM-007 — TypeScript strict mode preserved

This change does NOT touch any `cli/src/**.ts` file — Demeter
is bash + Python + Markdown only. Constraint asserted as a
guard so future task-creep is caught at review.

#### NFR-K3-DEM-008 — Publisher list governance

`.forge/data/cloud-act-publishers.yml` MUST carry :
- `version:` (SemVer, bumped on any deny-list edit).
- `last_reviewed:` (ISO-8601 date).
- `expires_at:` (ISO-8601, default = `last_reviewed + 12 months`
  in the interim ; will be tightened to 6 months when Themis
  ships in T7 — design ADR-K3-003 resolves Q-002).
- `maintained_by:` (BDFL in interim ; Themis post-T7).

The standard `global/data-stewardship-rules.md` documents the
review cadence + the upgrade path for the maintainer role.

#### NFR-K3-DEM-009 — Anti-hallucination on classification

When a publisher's jurisdiction is ambiguous (e.g. multinational
with both US and EU offices, recent acquisition not yet
reflected in the deny-list), the scanner MUST emit a
`[NEEDS CLARIFICATION:]` JSON entry instead of a finding. The
adopter (or Themis at review time) resolves the ambiguity
upstream, not the scanner.

---

## BDD Acceptance Criteria

### Scenario 1 — T2 US-jurisdiction publisher detected

```gherkin
Given an adopter has declared compliance_tier T2 via .forge/.forge-tier
And the target tree contains a Cargo.lock with a US-jurisdiction publisher (per cloud-act-publishers.yml)
When `bash bin/forge-demeter-scan.sh --target <tree>` runs
Then the process exits with code 3
And the JSON report contains 1 finding with rule_id "K3-RULE-001" and severity "High"
And the JSON report's overall_status is "BLOCKED"
And the finding's evidence cites the offending crate name + version
```

### Scenario 2 — T1 DPA declaration missing

```gherkin
Given an adopter has declared compliance_tier T1 via --eu-tier flag
And the project uses Zitadel cloud (a "⚠️ Cloud SaaS T1" component per §10.2)
And no .forge/.forge-dpa-declared file exists in the target tree
When Demeter is invoked (via Janus Step 9 dispatch or `forge-demeter-scan.sh`)
Then the report contains 1 finding with rule_id "K3-RULE-002" and severity "High"
And the remediation cites the path "create .forge/.forge-dpa-declared"
```

### Scenario 3 — T3 clean tree CLEARED

```gherkin
Given an adopter has declared compliance_tier T3 via .forge/.forge-tier
And the target tree's lockfiles contain only EU-jurisdiction or jurisdiction-neutral publishers
And SOURCE_DATE_EPOCH is exported as 0
When `bash bin/forge-demeter-scan.sh --target <tree>` runs twice in succession
Then both runs exit with code 0
And both JSON reports have overall_status "CLEARED"
And both JSON reports are byte-identical
```

---

## Anti-Hallucination Pass

For each FR :

- **Testable** : every FR is asserted by at least one test in
  `k3.test.sh` (mapping captured in `tasks.md`
  `[Story: FR-K3-DEM-XXX]` tags during `/forge:plan`).
- **Unambiguous** : 3 ambiguities flagged in proposal, all
  resolvable at design time after :
  - Q-001 — DPA surface : design audits the J.8 ledger pattern.
  - Q-002 — publisher list cadence : design splits interim
    (BDFL, 12-month) vs permanent (Themis, 6-month).
  - Q-003 — K3-RULE allocation : 5 seed rules covering the BDD
    scenarios + Cluster 9 ; growth incremental.
- **Constitution-compliant** : Articles I (TDD), II (BDD), III
  + III.4 (specs first + ambiguity protocol), IV (delta —
  Janus agent edit is delta-based per FR-K3-DEM-081), V (audit
  trail), XI (AI-First — agent-native architecture, schema-
  driven outputs), XII (governance — enforces, does not
  amend).

---

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`specs.md`. Three open questions Q-001 + Q-002 + Q-003 raised
at the proposal phase, tracked in `open-questions.md`,
slated for resolution during `/forge:design` via ADR-K3-001..006.

## Counts

- **FR-K3-DEM-***: 41 (001-008 persona, 010-011 audit/citations,
  020-026 tier classification, 040-044 DPA, 060-074 CLOUD Act
  scanner, 080-086 integration, 100-102 harness, 110-112 docs,
  120-124 seed rules)
- **NFR-K3-DEM-***: 9 (001-009)
- **BDD Scenarios** : 3
- **Open Questions** : 3 (Q-001..Q-003, all status `open`)
