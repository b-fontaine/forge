# Specifications: k5-themis
<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-K5-THE-*` / `NFR-K5-THE-*`. **Constitution** :
v2.0.0. Pas d'amendement requis (K.5 introduces a new agent + CLI +
sibling workflow ; existing articles unchanged).

## Source Documents

| Field             | Value                                                                                                                                                             |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Audit base**    | `K.5` (`new-archetypes-plan` §9 line 2672 — Themis compliance officer, scope `tous EU`) + `ARCHITECTURE-TARGET` §9.2 line 735                                       |
| **Plan ref**      | `docs/new-archetypes-plan.md` §9 line 2672 + §7.1 I.6 bullet lines 2629-2634 (regulatory deadlines verbatim) + §2.3 P-3 lines 2220-2238 + §11.2 T7-recap lines 2224-2237 |
| **Cadence base**  | `.forge/standards/global/standards-lifecycle.md` v1.1.0 (T.4 — 12-month `expires_at` review window + "Themis hook (deferred — T7)" section) + `.forge/standards/REVIEW.md` append-only ledger |
| **Bundle base**   | `.forge/scripts/compliance/bundle.sh` (I.6) + `global/compliance-artefacts-bundle.md` v1.1.0 (forward-stable `regulatory/` layout Themis drives)                    |
| **Workflow base** | `.github/workflows/forge-compliance.yml` (I.5) + `global/forge-compliance-workflow.md` v1.0.0 (forward-stable for additive Themis territory)                        |
| **Sibling agent** | `.claude/agents/demeter.md` (K.3 — data steward EU) ; `global/data-stewardship-rules.md` (K3-RULE-001..006) ; Demeter reserves `K5-RULE-NNN` for Themis            |
| **Pattern reuse** | `bin/forge-demeter-scan.sh` (K.3) + `bin/forge-sbom.sh` (J.8.d) + `.forge/scripts/compliance/bundle.sh` (I.6) — bash thin + Python 3 inline (ADR-J8-007 lineage)    |
| **Regulatory ref**| NIS2 (Directive (EU) 2022/2555) ; DORA (Regulation (EU) 2022/2554) ; CRA (Regulation (EU) 2024/2847) ; AI Act (Regulation (EU) 2024/1689) — dates cited from the plan doc VERBATIM, not re-derived (Article III.4) |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Themis persona file (FR-K5-THE-001 → 009)

##### FR-K5-THE-001 — Persona file location

`.claude/agents/themis.md` MUST exist as the canonical Themis persona
file, flat in `.claude/agents/` alongside `demeter.md` (K.3) and the
other 16 top-level Forge agents (ADR-K5-001).

##### FR-K5-THE-002 — Persona section

The file MUST start with an H1 `# Agent: Compliance Officer EU
(Themis)` and a `## Persona` H2 declaring :
- **Name** : Themis (Greek titaness of divine law, good counsel, and
  the ordered cycle of the seasons — the natural patron of a
  time-bound compliance cadence).
- **Role** : Compliance officer EU — tracks NIS2 / DORA / CRA / AI Act
  regulatory deadlines and automates the 12-month standards review
  cadence.
- **Style** : Methodical, cadence-first, evidence-driven. Mirrors the
  Demeter / Aegis stylistic pattern — every finding carries a
  severity, specific evidence, and an actionable remediation.

##### FR-K5-THE-003 — Purpose section

A `## Purpose` H2 MUST describe Themis's two responsibilities
(standards review cadence + regulatory deadline tracking) and
explicitly cite the source audit item (K.5) + the upstream surfaces
Themis consumes (`standards-lifecycle.md`, `compliance-tiers.md`,
`bundle.sh`, `forge-compliance.yml`).

##### FR-K5-THE-004 — Boundary vs Demeter section (load-bearing)

A `## Boundary — Themis vs Demeter` H2 MUST make the two agents'
responsibilities mutually exclusive and explicit :
- **Demeter** (K.3) = data steward — CLOUD Act detection, DPA
  validation, tier classification at **SCAFFOLD-TIME / review-time**
  (project creation, PR review, Janus Step 9).
- **Themis** (K.5) = compliance officer — regulatory-deadline tracking
  + standards review cadence at **REPO-LIFECYCLE-TIME** (ongoing,
  ambient, time-triggered / scheduled).

The section MUST state that Themis does NOT duplicate Demeter's
scaffold-time responsibilities and does NOT scan dependency lockfiles
for jurisdiction (that is Demeter's `bin/forge-demeter-scan.sh`).

##### FR-K5-THE-005 — Checklists section

A `## Checklists` H2 MUST host at least three H3 sub-sections, each
following the Demeter bullet-checklist style (`[ ] item` with
`Verify:` / `Check:` / `Exception:` annotations, ≥ 5 items each) :
- **Standards Review Cadence** (walk `.forge/standards/` for
  `last_reviewed` / `expires_at` ; classify FRESH / DUE-SOON /
  EXPIRED ; skip structural exceptions).
- **Regulatory Deadlines** (the NIS2 / DORA / CRA / AI Act calendar ;
  horizon check).
- **Compliance Bundle Automation** (drive `bundle.sh` ; emit the
  regulatory-deadline summary ; never fork the I.6 recipe).

##### FR-K5-THE-006 — Output report format

A `## Output: Standards Review Report` H2 MUST declare the report
shape :
- A `Summary` table with severity counts (Critical / High / Medium /
  Low / Informational) mirroring Demeter's table.
- A `Findings` section citing `[SEVERITY] <K5-RULE-NNN>: <title>`,
  `Category`, `Location`, `Evidence`, `Risk`, `Remediation`,
  `Verification`.
- A `Cleared Items` section.
- An overall status line : `BLOCKED` / `REVIEW-DUE` / `CLEARED`
  (BLOCKED only in `--strict` mode on expired standards ; REVIEW-DUE
  when review debt is present but non-blocking ; CLEARED otherwise).

##### FR-K5-THE-007 — Rule catalogue section

A `## Rule Catalogue` H2 MUST enumerate the seed `K5-RULE-*` rules
(≥ 5, see Cluster 6). Each rule MUST cite (a) trigger, (b) severity,
(c) evidence pattern, (d) remediation hint, (e) cross-link.

##### FR-K5-THE-008 — Integration section

A `## Integration` H2 MUST describe :
- The `forge review-standards` CLI (`bin/forge-review-standards.sh`).
- The `.forge/standards/global/standards-lifecycle.md` cadence Themis
  automates (12-month window, `verify.sh` WARN).
- The sibling CI workflow `forge-standards-review.yml` (scheduled).
- Driving the I.6 `bundle.sh` (not forking it).
- The sibling relationship + boundary with Demeter (cross-link to
  FR-K5-THE-004).

##### FR-K5-THE-009 — Anti-hallucination protocol

A `## Anti-Hallucination Protocol` H2 MUST state that Themis emits
`[NEEDS CLARIFICATION: <specific question>]` and STOPS when a
regulatory date is not sourced from a cited document, when a
standard's frontmatter is malformed / ambiguous, or when a
structural-exception coherence check is contradictory — never guesses
a regulatory deadline or a review date. This is the Article III.4
contract.

---

#### Cluster 2 — Audit-comment header anchors (FR-K5-THE-010 → 011)

##### FR-K5-THE-010 — Audit comment

The persona file, the CLI, the standard, and the harness MUST each
carry a top-of-file `<!-- Audit: K.5 (k5-themis) -->` (or `#`-comment
equivalent for the shell scripts) per the Forge audit-trail
convention.

##### FR-K5-THE-011 — Source citations

Every paragraph importing a constraint from `ARCHITECTURE-TARGET.md`
or `new-archetypes-plan.md` MUST cite the section + line range.

---

#### Cluster 3 — `forge review-standards` CLI (FR-K5-THE-020 → 036)

##### FR-K5-THE-020 — CLI script

`bin/forge-review-standards.sh` MUST exist as executable bash
(`#!/usr/bin/env bash`, `set -uo pipefail`) following the F.2 / J.7 /
J.8.d / K.3 pattern verbatim per NFR-K5-THE-004. Signature :
```
bin/forge-review-standards.sh [--target <dir>] [--window <days>]
                              [--output <path>] [--format json|md]
                              [--bundle] [--strict]
```
Defaults : `--target $(pwd)`, `--window 30`, `--output
standards-review-report.json`, `--format json`.

##### FR-K5-THE-021 — Exit codes

Exit codes MUST be :
- `0` — CLEARED (no expired standards, none due within the window).
- `1` — REVIEW-DUE (one or more standards expired or due within the
  window). This is a WARN-level, **non-blocking** signal by default
  (`standards-lifecycle.md` "WARN n'est jamais bloquant").
- `2` — usage error (bad args, target not a directory,
  `.forge/standards/` absent).
- `3` — BLOCKED (only reachable when `--strict` is passed AND at least
  one non-structural standard is expired).

##### FR-K5-THE-022 — Standards discovery

The CLI MUST walk `<target>/.forge/standards/` recursively and detect
every standard carrying `last_reviewed` / `expires_at` frontmatter, in
BOTH forms :
- **YAML standard** (`*.yaml`) : top-level `last_reviewed:` /
  `expires_at:` keys at column 0.
- **Markdown standard** (`*.md`) : `last_reviewed:` / `expires_at:`
  keys inside a fenced ```` ```yaml ```` frontmatter block.

`REVIEW.md` and `index.yml` MUST be excluded from the walk (they are
the ledger + the registry, not reviewable standards).

##### FR-K5-THE-023 — Structural-exception skip

A standard declaring `expires_at: never` AND
`exception_constitutional: true` MUST be classified `structural` and
MUST NOT be flagged as expired or due-soon (it is amendable only via
Article XII). Themis reports it as a `Cleared` item.

##### FR-K5-THE-024 — Expiry classification

For each non-structural standard with a dated `expires_at` :
- `expires_at < today` → **EXPIRED** → `K5-RULE-001` (Medium).
- `today ≤ expires_at ≤ today + window` → **DUE-SOON** →
  `K5-RULE-002` (Low).
- `expires_at > today + window` → **FRESH** → Cleared item.

Date comparison uses ISO-8601 `YYYY-MM-DD`. "today" is
`SOURCE_DATE_EPOCH` when set, else the wall clock (NFR-K5-THE-005).

##### FR-K5-THE-025 — Missing-frontmatter finding

A file under `.forge/standards/` that a human would treat as a
standard (a `*.yaml` top-level standard listed in `index.yml`, or a
`global/*.md` standard) but that carries NEITHER `last_reviewed` NOR
`expires_at` MUST emit `K5-RULE-003` (Medium). Sub-directory prose
standards without frontmatter (`flutter/*.md`, `rust/*.md`,
`infra/*.md`, `observability/*.md` that predate the frontmatter
contract) are reported as `Informational`, not Medium, to avoid a
false-positive storm on the pre-T.4 corpus (ADR-K5-004).

##### FR-K5-THE-026 — Structural-exception coherence finding

A standard where `expires_at: never` XOR `exception_constitutional:
true` (one present without the other) MUST emit `K5-RULE-005`
(Medium) — a review-time WARN companion to the J.7 hard `[STD-FAIL]`
`FR-J7-020`. `K5-RULE-005` additionally covers Markdown standards
(which `validate-standards-yaml.sh` does NOT scan), closing the J.7
gap for the `global/*.md` corpus (ADR-K5-005).

##### FR-K5-THE-027 — Regulatory deadline calendar

The CLI MUST carry the regulatory-deadline calendar copied
**VERBATIM** from `new-archetypes-plan.md` §7.1's I.6 bullet
(lines 2629-2634) :
- `NIS2 reporting 24h/72h`
- `DORA RoI ESA submission 30 avr 2026`
- `CRA reporting 11 sept 2026, full requirements 11 déc 2027`
- `AI Act phases 2025–2027 par catégorie de risque`

The CLI MUST NOT invent, approximate, or re-derive these dates
(Article III.4 ; NFR-K5-THE-009). The JSON report exposes them under
`regulatory_deadlines[]`.

##### FR-K5-THE-028 — Regulatory horizon finding

A regulatory milestone carrying a parseable ISO-8601 date (the DORA
30 avr 2026 and CRA 11 sept 2026 / 11 déc 2027 milestones) that falls
within a fixed 365-day horizon of "today" MUST surface as a
`K5-RULE-004` `Informational` finding for maintainer awareness.
NIS2 24h/72h and "AI Act phases 2025–2027" carry no single parseable
date and are reported as informational calendar entries only.

##### FR-K5-THE-029 — JSON report shape

The JSON report MUST conform to :
```json
{
  "version": "1.0.0",
  "generated_at": "<ISO-8601 timestamp>",
  "target": "<absolute-path>",
  "review_window_days": 30,
  "summary": {
    "critical": 0, "high": 0, "medium": 0,
    "low": 0, "informational": 0, "cleared": 0
  },
  "overall_status": "BLOCKED|REVIEW-DUE|CLEARED",
  "standards": [
    {"path": "...", "version": "...", "last_reviewed": "...",
     "expires_at": "...", "status": "FRESH|DUE-SOON|EXPIRED|STRUCTURAL"}
  ],
  "findings": [
    {"rule_id": "K5-RULE-NNN", "severity": "...", "category": "...",
     "location": "...", "evidence": "...", "risk": "...",
     "remediation": "...", "verification": "..."}
  ],
  "regulatory_deadlines": [
    {"regulation": "NIS2", "deadline": "reporting 24h/72h", "date": null}
  ],
  "cleared": [{"path": "...", "status": "..."}],
  "metadata": {
    "scanner_version": "0.1.0",
    "standards_scanned": 0,
    "coverage_mode": "frontmatter-walk"
  }
}
```

##### FR-K5-THE-030 — Markdown report shape

When `--format md`, the CLI MUST emit a Markdown Standards Review
Report mirroring the persona's `## Output` shape. Both forms cover the
same findings.

##### FR-K5-THE-031 — Determinism

Two consecutive runs against the same target MUST produce
**byte-identical** output when `SOURCE_DATE_EPOCH` is set. Standards
in the report MUST be sorted by relative path ; findings by
`(severity_rank, rule_id, location)`. JSON uses
`json.dumps(..., sort_keys=True, indent=2)` + trailing newline.

##### FR-K5-THE-032 — `--bundle` drives (never forks) the I.6 bundle

When `--bundle` is passed, the CLI MUST :
1. Write a deterministic regulatory-deadline summary
   `forge-regulatory-deadlines.md` (verbatim calendar) next to the
   report.
2. Invoke `.forge/scripts/compliance/bundle.sh --target <target>`
   (propagating `SOURCE_DATE_EPOCH`) to regenerate the canonical I.6
   `.tgz`.

The CLI MUST NOT edit, re-implement, or byte-alter `bundle.sh` or its
output recipe. If `bundle.sh` is absent at the target, `--bundle`
emits a diagnostic and the summary is still written (graceful
degradation).

##### FR-K5-THE-033 — `--strict` opt-in blocking

Without `--strict`, expired standards are WARN-only (exit 1). With
`--strict`, at least one expired non-structural standard forces exit 3
(BLOCKED) for adopters wiring a hard gate. Structural exceptions never
trigger `--strict` blocking.

##### FR-K5-THE-034 — No paid services / offline

The CLI MUST function fully offline. No network access, no paid
service. Stdlib + PyYAML only.

##### FR-K5-THE-035 — Bogus-arg + help contract

`--help` / `-h` MUST print a `Usage:` block and exit 0. An unknown
argument MUST print a diagnostic and exit 2.

##### FR-K5-THE-036 — Empty-tree contract

If `<target>/.forge/standards/` does not exist, the CLI MUST exit 2
with a diagnostic (usage error) — it MUST NOT silently report CLEARED
against a non-existent standards corpus.

---

#### Cluster 4 — Standard + index + lifecycle integration (FR-K5-THE-050 → 055)

##### FR-K5-THE-050 — Standard file existence

`.forge/standards/global/standards-review-rules.md` MUST exist with
≥ 5 H2 sections : Purpose, Rule catalogue (`K5-RULE-NNN` table),
Regulatory-deadline calendar, Review cadence automation, Extending the
catalogue. Markdown only (mirrors K.3's `data-stewardship-rules.md`;
no J.7 YAML frontmatter contract).

##### FR-K5-THE-051 — Standards index registration

`.forge/standards/index.yml` MUST gain :
```yaml
- id: global/standards-review-rules
  path: standards/global/standards-review-rules.md
  triggers: [themis, review-standards, standards-review, compliance-officer, nis2, dora, cra, ai-act, regulatory-deadline, k5-rule, review-cadence]
  scope: all
  priority: high
```

##### FR-K5-THE-052 — standards-lifecycle.md Themis-section update

`.forge/standards/global/standards-lifecycle.md` "Themis hook
(deferred — T7)" section MUST be updated (delta, Article IV.1) to
record that Themis has shipped (K.5) and `forge review-standards` is
now automated via `bin/forge-review-standards.sh` +
`forge-standards-review.yml`. The structural-exception table
(`transport.yaml`, `state-management.yaml`) MUST remain intact
(`t4.test.sh::_test_t4_025`).

##### FR-K5-THE-053 — CLAUDE.md agent-delegation row

The repo `CLAUDE.md` agent-delegation table MUST gain :
```markdown
| Regulatory compliance | **Themis** | Compliance Officer EU |
```

##### FR-K5-THE-054 — docs/GUIDE.md transversal-agents row

`docs/GUIDE.md` "Agents Transversaux" table MUST gain a Themis row
(`Compliance Officer EU | Themis | NIS2/DORA/CRA, cycle review-standards`).

##### FR-K5-THE-055 — docs/COMPLIANCE.md Themis section

`docs/COMPLIANCE.md` MUST gain a `## Standards review cadence (Themis)`
H2 documenting `forge review-standards`, the review window, and the
regulatory-deadline calendar — extending the adopter doc, not forking
a competing one.

---

#### Cluster 5 — Sibling CI workflow (FR-K5-THE-060 → 063)

##### FR-K5-THE-060 — Workflow file

`.github/workflows/forge-standards-review.yml` MUST exist and parse as
valid YAML.

##### FR-K5-THE-061 — Triggers

The workflow MUST declare `on:` with BOTH a `schedule:` (monthly cron)
and a `workflow_call:` trigger. The monthly cadence realises the plan
doc's "issue de revue mensuelle via le hook `forge review-standards`"
(`standards-lifecycle.md` line 73).

##### FR-K5-THE-062 — Step invocation

The workflow MUST invoke `bash bin/forge-review-standards.sh` and MUST
NOT hard-fail on review debt by default (`continue-on-error: true` on
the review step OR the default WARN exit is tolerated) — consistent
with the non-blocking cadence doctrine.

##### FR-K5-THE-063 — Minimum permissions

The workflow MUST declare `permissions: contents: read` (Aegis
hygiene, mirrors `forge-compliance.yml`).

---

#### Cluster 6 — Seed K5-RULE catalogue (FR-K5-THE-070 → 074)

The seed K.5 rule catalogue per ADR-K5-003 (5 seed rules, incremental
growth, namespace `K5-RULE-NNN` per ADR-J8-004 inheritance).

##### FR-K5-THE-070 — K5-RULE-001 — Standard past review window

**Trigger** : a non-structural standard's `expires_at < today`.
**Severity** : Medium (WARN ; blocking only under `--strict`).
**Remediation** : review the standard, refresh `last_reviewed` /
`expires_at`, append a `REVIEW.md` entry ; open a Forge change if the
review concludes REPLACE / DEPRECATE.

##### FR-K5-THE-071 — K5-RULE-002 — Standard due for review

**Trigger** : `today ≤ expires_at ≤ today + window`. **Severity** :
Low. **Remediation** : schedule the review before `expires_at`.

##### FR-K5-THE-072 — K5-RULE-003 — Standard missing lifecycle frontmatter

**Trigger** : a top-level `*.yaml` standard (or `global/*.md`
standard) carries neither `last_reviewed` nor `expires_at`.
**Severity** : Medium (Informational for pre-T.4 sub-directory prose
standards per ADR-K5-004). **Remediation** : add the frontmatter
contract per `standards-lifecycle.md`.

##### FR-K5-THE-073 — K5-RULE-004 — Regulatory deadline on horizon

**Trigger** : a tracked regulatory milestone with a parseable
ISO-8601 date within a 365-day horizon of today. **Severity** :
Informational. **Remediation** : verify the repo's compliance
artefacts address the milestone ; drive the I.6 bundle.

##### FR-K5-THE-074 — K5-RULE-005 — Structural-exception coherence

**Trigger** : `expires_at: never` XOR `exception_constitutional:
true`. **Severity** : Medium. **Remediation** : align the two keys per
`standards-lifecycle.md` Article-XII coupling (the J.7 `FR-J7-020`
bidirectional rule) ; this WARN also covers Markdown standards J.7
does not scan.

---

#### Cluster 7 — Test harness `k5.test.sh` (FR-K5-THE-100 → 102)

##### FR-K5-THE-100 — Harness exists

`.forge/scripts/tests/k5.test.sh` MUST exist mirroring the K.3 layout
(bash header, `_helpers.sh` source, PASS/FAIL counters, `--level 1,2`
parsing, `print_summary`).

##### FR-K5-THE-101 — L1 coverage ≥ 20 tests

Minimum 20 L1 tests covering persona structure (file + audit comment +
Persona / Purpose / Boundary / Checklists / Output / Rule Catalogue /
Integration / Anti-Hallucination H2 anchors), checklist sub-sections
(≥ 5 `[ ]` each), rule catalogue (K5-RULE-001..005 anchors), CLI
(exists + signature + exit codes + bogus-arg + empty-tree), standard +
index registration, standards-lifecycle Themis-section update,
workflow presence + triggers + permissions, CLAUDE.md + GUIDE.md +
COMPLIANCE.md rows, regulatory-date verbatim presence, and namespace
collision guard (`K5-RULE` never in K.3 surfaces, and vice-versa).

##### FR-K5-THE-102 — L2 coverage ≥ 2 fixture tests

Minimum 2 L2 fixtures :
- **L2-expired** : tmpdir with a synthetic `.forge/standards/` carrying
  one expired MD standard + one fresh YAML standard ; assert exit 1,
  `overall_status: "REVIEW-DUE"`, ≥ 1 `K5-RULE-001` Medium finding
  citing the expired standard.
- **L2-clean-deterministic** : tmpdir where every standard is fresh (or
  structural) ; assert exit 0, `overall_status: "CLEARED"`, and
  byte-identical output across two `SOURCE_DATE_EPOCH`-pinned runs.

---

#### Cluster 8 — Documentation (FR-K5-THE-110 → 112)

##### FR-K5-THE-110 — GUIDE + COMPLIANCE entries

Covered by FR-K5-THE-054 / 055.

##### FR-K5-THE-111 — CHANGELOG entry

A new entry under `## [Unreleased]` → `### Added` summarising the
three sub-modules (K.5.a persona, K.5.b CLI, K.5.c integration),
referencing `k5-themis`.

##### FR-K5-THE-112 — Audit cross-references

The persona footer MUST cite the upstream sources with section + line
refs : `ARCHITECTURE-TARGET` §9.2 line 735 ; `new-archetypes-plan` §9
line 2672 + §7.1 I.6 bullet + §2.3 P-3 ; `standards-lifecycle.md`
Themis hook.

---

### Non-Functional Requirements

#### NFR-K5-THE-001 — Performance budget

`bin/forge-review-standards.sh` MUST complete in ≤ 5 s against the
live `.forge/standards/` tree (~40 standards). Harness `--level 1`
≤ 5 s ; full `--level 1,2` ≤ 20 s.

#### NFR-K5-THE-002 — Backward compatibility

Purely additive. Adopters not invoking `forge review-standards` and
not wiring `forge-standards-review.yml` MUST observe ZERO behavioural
change. No edit to `forge-compliance.yml` (I.5) or `bundle.sh` (I.6).

#### NFR-K5-THE-003 — Article V audit trail

Every task tagged `[Story: FR-K5-THE-XXX]`. Every finding carries a
`K5-RULE-NNN` ID + structured JSON shape.

#### NFR-K5-THE-004 — F.2 / J.7 / J.8 / K.3 pattern alignment

`bin/forge-review-standards.sh` follows the bash + Python 3 inline
pattern of `forge-demeter-scan.sh` / `bundle.sh` / `forge-sbom.sh`. No
new external dependency (PyYAML already required).

#### NFR-K5-THE-005 — Reproducibility

Output byte-identical across consecutive runs when `SOURCE_DATE_EPOCH`
is set (mirrors `bundle.sh` NFR-I6-CA-005 / `forge-demeter-scan.sh`
NFR-K3-DEM-005).

#### NFR-K5-THE-006 — No sibling-harness breakage

The change MUST leave `i5.test.sh`, `i6.test.sh`, `k3.test.sh`,
`t4.test.sh`, `j7.test.sh` GREEN. It MUST NOT bump
`compliance-artefacts-bundle.md` (exact-pinned by `i6.test.sh`) nor
edit `forge-compliance.yml` (step-pinned by `i5.test.sh`).

#### NFR-K5-THE-007 — TypeScript strict mode preserved

The change touches NO `cli/src/**.ts` file.

#### NFR-K5-THE-008 — WARN-never-blocks doctrine

Default posture is WARN (exit 1, non-blocking) — an expired standard
never freezes the pipeline (`standards-lifecycle.md`). Blocking is an
explicit `--strict` opt-in.

#### NFR-K5-THE-009 — Anti-hallucination on regulatory dates

Regulatory dates are copied VERBATIM from a cited source. When a date
is not sourced, Themis emits `[NEEDS CLARIFICATION:]` — never invents a
deadline.

---

## BDD Acceptance Criteria

### Scenario 1 — Expired standard flagged (WARN, non-blocking)

```gherkin
Given a target tree with a standard whose expires_at is in the past
And the standard is NOT a structural exception
When `bash bin/forge-review-standards.sh --target <tree>` runs
Then the process exits with code 1
And the JSON report contains 1 finding with rule_id "K5-RULE-001" and severity "Medium"
And the JSON report's overall_status is "REVIEW-DUE"
And the finding's evidence cites the expired standard's path + expires_at date
```

### Scenario 2 — Structural exception never flagged

```gherkin
Given a target tree containing a standard with expires_at: never and exception_constitutional: true
And today is well past any 12-month window
When Themis reviews the standards tree
Then the structural standard is reported as a Cleared item with status "STRUCTURAL"
And it produces no K5-RULE-001 finding
```

### Scenario 3 — Clean deterministic run

```gherkin
Given a target tree where every non-structural standard is fresh
And SOURCE_DATE_EPOCH is exported
When `bash bin/forge-review-standards.sh --target <tree>` runs twice with --format json
Then both runs exit with code 0
And both JSON reports have overall_status "CLEARED"
And both JSON reports are byte-identical
```

---

## Anti-Hallucination Pass

For each FR :

- **Testable** : every FR is asserted by at least one test in
  `k5.test.sh` (mapping captured in `tasks.md` `[Story: FR-K5-THE-XXX]`
  tags during `/forge:plan`).
- **Unambiguous** : 3 ambiguities flagged in proposal, all resolvable
  at design time :
  - Q-K5-001 — workflow placement : design picks sibling workflow.
  - Q-K5-002 — regulatory date source : verbatim from the plan doc.
  - Q-K5-003 — blocking posture : WARN-only default + `--strict`
    opt-in.
- **Constitution-compliant** : Articles I (TDD), II (BDD), III + III.4
  (specs first + verbatim regulatory dates), IV (delta edits), V
  (audit trail), VIII (CI script), XI (agent-native, schema-driven),
  XII (governance — enforces, does not amend ; structural exceptions
  untouched).

---

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`specs.md`. Three open questions Q-K5-001 + Q-K5-002 + Q-K5-003 raised
at the proposal phase, tracked in `open-questions.md`, slated for
resolution during `/forge:design` via ADR-K5-001..006.

## Counts

- **FR-K5-THE-***: 44 (001-009 persona, 010-011 audit/citations,
  020-036 CLI, 050-055 integration, 060-063 workflow, 070-074 seed
  rules, 100-102 harness, 110-112 docs)
- **NFR-K5-THE-***: 9 (001-009)
- **BDD Scenarios** : 3
- **Open Questions** : 3 (Q-K5-001..Q-K5-003, all status `open`)
