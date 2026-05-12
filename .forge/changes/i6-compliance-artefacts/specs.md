# Specifications: i6-compliance-artefacts
<!-- Status: archived -->
<!-- Schema: default -->

**Namespace** : `FR-I6-CA-*` / `NFR-I6-CA-*`. **Constitution** :
v1.1.0. Pas d'amendement requis (I.6 livre un script + un standard,
ne modifie aucune Article).

## Source Documents

| Field                | Value                                                                                                                                                                                |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **ADR base**         | `t4-adr-ratification` archived 2026-05-04 (locks `compliance-tier.schema.json` v1.0.0 — bundle ships the schema's prose mirror via I.2)                                               |
| **Tier matrix src**  | `i2-compliance-tiers` archived 2026-05-12 — ships `.forge/standards/global/compliance-tiers.md` v1.0.0 (15-row Component Eligibility Matrix copied into the bundle)                   |
| **DPA template src** | `k3-demeter` archived 2026-05-12 — ships `.forge/.forge-dpa-declared` format (ADR-K3-002) the template mirrors verbatim                                                               |
| **SBOM src**         | `j8-janus-rules` archived 2026-05-10 — ships `bin/forge-sbom.sh` (CycloneDX 1.5) the bundle invokes for the SBOM member                                                               |
| **Audit ledger src** | `.forge/changes/*/.forge.yaml` (archived changes) + `.forge/standards/REVIEW.md` + `data-stewardship-rules.md` + `janus-orchestration-rules.md`                                       |
| **Plan ref**         | `docs/new-archetypes-plan.md` §7.1 line 738-743 (I.6 row) ; §10 lines 727-743 (I-module roadmap)                                                                                      |
| **Pattern reuse**    | `bin/forge-sbom.sh` (F.2 / J.7 / J.8.d bash thin + Python 3 inline pattern) ; `.forge/scripts/tests/j8.test.sh` (L1 + L2 fixture pattern for deterministic outputs)                   |
| **Standard frame**   | `global/standards-lifecycle.md` (T.4 — frontmatter contract, 12-month review cycle, REVIEW.md append-only ledger) ; `global/sbom-policy.md` (sibling MD standard pattern)             |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Bundle generator script (FR-I6-CA-001 → 020)

##### FR-I6-CA-001 — Script presence

A new executable bash script `.forge/scripts/compliance/bundle.sh`
MUST exist. Permissions MUST include the executable bit
(`chmod +x`).

##### FR-I6-CA-002 — Audit comment

The script MUST carry a `<!-- Audit: I.6 (i6-compliance-artefacts) -->`
or equivalent shell-comment anchor (`# <!-- Audit: I.6 (i6-compliance-artefacts) -->`)
within the first 10 lines, mirroring the `bin/forge-sbom.sh`
convention.

##### FR-I6-CA-003 — Bash header + safety flags

The script MUST start with `#!/usr/bin/env bash` and MUST set
`set -uo pipefail` after the header comments. The script MUST NOT
set `-e` (mirrors `bin/forge-sbom.sh` — Python subprocess returns
its own `rc` and the trailing `exit $rc` propagates).

##### FR-I6-CA-004 — Usage block

Running the script with `--help` or `-h` MUST print a usage block
to stdout listing :
- The signature `bash .forge/scripts/compliance/bundle.sh [--output <path>] [--target <dir>]`.
- The defaults (`--output forge-compliance-artefacts.tgz`,
  `--target $(pwd)`).
- The exit codes (`0` success, `1` missing source artefact, `2`
  usage error).
- Exit 0 after printing.

##### FR-I6-CA-005 — Argument parsing

The script MUST accept the following CLI flags via while-case
parsing (mirrors `bin/forge-sbom.sh`) :
- `--output <path>` or `--output=<path>` — output `.tgz` path.
- `--target <dir>` or `--target=<dir>` — target project directory.
- `--help` or `-h` — print usage + exit 0.
- Any other flag MUST emit `forge-compliance-bundle: unknown
  argument: <arg>` to stderr and exit 2.

##### FR-I6-CA-006 — Target validation

If `--target` (or default `$(pwd)`) does not resolve to an existing
directory, the script MUST emit `forge-compliance-bundle: target
directory not found: <path>` to stderr and exit 2.

##### FR-I6-CA-007 — Source artefact validation

Before bundle assembly, the script MUST verify the four canonical
source surfaces exist :
- `<target>/.forge/standards/global/compliance-tiers.md`
- `<target>/.forge/templates/compliance/forge-dpa-declared.template`
- `<target>/.forge/changes/` (directory ; at least one
  `*/\.forge\.yaml` inside)
- `<target>/.forge/standards/REVIEW.md`

Missing any of the four surfaces : emit `forge-compliance-bundle:
missing source artefact: <path>` to stderr and exit 1.

##### FR-I6-CA-008 — Bundle members (exhaustive)

The bundle MUST contain exactly the following members, at the
exact relative paths inside the `.tgz` :

| Member path inside `.tgz`              | Source                                                            |
|----------------------------------------|-------------------------------------------------------------------|
| `MANIFEST`                             | Script-generated ; lists every member + SHA-256 + size            |
| `tier-matrix/compliance-tiers.md`      | Copy of `.forge/standards/global/compliance-tiers.md`             |
| `templates/forge-dpa-declared.template`| Copy of `.forge/templates/compliance/forge-dpa-declared.template` |
| `audit/audit-ledger.json`              | Script-generated audit ledger snapshot (machine)                  |
| `audit/audit-ledger.md`                | Script-generated audit ledger snapshot (human)                    |
| `sbom/sbom.cdx.json`                   | Output of `bash bin/forge-sbom.sh --target <target>`              |

Exactly 6 members. Adding or removing a member is a SemVer **minor**
bump per the bundle standard (ADR-I6-CA-001).

##### FR-I6-CA-009 — MANIFEST format

The `MANIFEST` member MUST be plain text, UTF-8, LF line endings,
sorted by member path (lexicographic). Each line MUST follow the
format :

```
<sha256-hex>  <size-bytes>  <member-path>
```

Three space-separated fields. Mandatory trailing newline. SHA-256
computed over the bundle member's bytes (not the bundle tarball
itself).

##### FR-I6-CA-010 — Output path

If `--output` is set, the script MUST write the `.tgz` at that
path. Otherwise the script MUST write `forge-compliance-artefacts.tgz`
in the current working directory (NOT the target directory ; the
caller controls output location independently of source location).

##### FR-I6-CA-011 — Exit code 0 on success

When the bundle is written successfully, the script MUST exit 0
and emit a stderr line `forge-compliance-bundle: wrote <output>
(<N> members, <bytes> bytes)`.

##### FR-I6-CA-012 — Tarfile gzip format

The output MUST be a gzip-compressed POSIX tar archive (Python
stdlib `tarfile.open(..., "w:gz")`). The archive name field for
each member MUST be the relative member path with no leading `./`
or absolute prefix.

##### FR-I6-CA-013 — Audit ledger schema (JSON)

The `audit/audit-ledger.json` member MUST conform to the following
shape :

```json
{
  "schema_version": "1.0.0",
  "generated_at": "<ISO-8601 UTC>",
  "framework_version": "<contents of VERSION file>",
  "archived_changes": [
    {"name": "<change-name>", "archived": "<ISO-8601-date>", "parent_audit_items": ["..."]}
  ],
  "standards_reviews": [
    {"date": "<ISO-8601-date>", "title": "<H2 title>"}
  ],
  "active_rule_catalogues": ["K3-RULE-001..006", "J8-RULE-001..003"]
}
```

Five top-level keys exactly. JSON output uses `sort_keys=True`,
`indent=2`, trailing newline.

##### FR-I6-CA-014 — Audit ledger schema (Markdown)

The `audit/audit-ledger.md` member MUST carry :
- H1 anchor `# Forge Compliance — Audit Ledger Snapshot`.
- A `> Generated at <ISO-8601 UTC>` blockquote line.
- Three H2 sections : `## Archived changes`, `## Standards
  reviews`, `## Active rule catalogues`.

##### FR-I6-CA-015 — Audit ledger sources (read-only)

The audit ledger generator MUST read from :
- `.forge/changes/*/.forge.yaml` files whose `status:` field
  equals `archived` ; collect `name`, `archived` (from `timeline.archived:`),
  `parent_audit_items`.
- `.forge/standards/REVIEW.md` H2 headings matching the regex
  `^## (\d{4}-\d{2}-\d{2}) — (.+)$`.
- A hard-coded list of active rule catalogue identifiers
  (`K3-RULE-001..006` per K.3, `J8-RULE-001..003` per J.8).

The generator MUST NOT write any persistent file outside the
bundle.

##### FR-I6-CA-016 — Audit ledger archived-changes sort

The `archived_changes` array MUST be sorted by `archived` ascending,
then `name` ascending (tie-breaker), for byte-stable output across
filesystem-ordering variations.

##### FR-I6-CA-017 — Audit ledger standards-reviews sort

The `standards_reviews` array MUST be sorted by `date` ascending,
then `title` ascending (tie-breaker).

##### FR-I6-CA-018 — SBOM member generation

The `sbom/sbom.cdx.json` member MUST be produced by invoking
`bash <target>/bin/forge-sbom.sh --target <target> --output
<tmpfile>`, then copied into the bundle. The bundle script MUST
propagate `SOURCE_DATE_EPOCH` to the SBOM invocation so the SBOM
member is itself deterministic.

##### FR-I6-CA-019 — SBOM missing-lockfile tolerance

If `forge-sbom.sh` exits 1 (no lockfiles found in target), the
bundle script MUST treat this as **non-fatal** : the SBOM member
is replaced by a `sbom/sbom.cdx.json` containing the minimal
CycloneDX 1.5 envelope with `"components": []` plus a stderr
warning `forge-compliance-bundle: no lockfiles in target — SBOM
empty`. Other forge-sbom.sh non-zero exits propagate as fatal.

##### FR-I6-CA-020 — Member ordering inside `.tgz`

Bundle members MUST be added to the tar archive in lexicographic
order by member path. This guarantees byte-stability across
Python runtime variations.

#### Cluster 2 — DPA template (FR-I6-CA-030 → 035)

##### FR-I6-CA-030 — Template presence

A new file `.forge/templates/compliance/forge-dpa-declared.template`
MUST exist.

##### FR-I6-CA-031 — Template audit comment

The template MUST carry `<!-- Audit: I.6 (i6-compliance-artefacts) -->`
(via `#` shell comments) within the first 5 lines.

##### FR-I6-CA-032 — Template canonical example

The template body MUST contain the canonical example line
`T1: 2026-04-15 LegalOps-Confluence-DPA-2026-Q2` (verbatim from
`global/data-stewardship-rules.md` § "DPA declaration semantics"),
prefixed by a `# Example:` comment.

##### FR-I6-CA-033 — Template references K.3 ADR-K3-002

The template MUST cross-reference `ADR-K3-002` and
`global/data-stewardship-rules.md` (DPA declaration semantics
section) in the header comment block.

##### FR-I6-CA-034 — Template references K3-RULE-002

The template MUST cite `K3-RULE-002` in the header comment block
(the rule that fires when a `T1` declaration carries ⚠️-T1
components without a DPA declaration).

##### FR-I6-CA-035 — Template references K3-RULE-002a staleness

The template MUST mention the 13-month + 1-month grace staleness
window (K3-RULE-002a per `global/data-stewardship-rules.md` §
"DPA declaration semantics").

#### Cluster 3 — Bundle standard (FR-I6-CA-040 → 055)

##### FR-I6-CA-040 — Standard file presence

A new file `.forge/standards/global/compliance-artefacts-bundle.md`
MUST exist.

##### FR-I6-CA-041 — Standard audit comment

`<!-- Audit: I.6 (i6-compliance-artefacts) -->` within the first 5
lines.

##### FR-I6-CA-042 — Standard trigger comment

`<!-- Trigger: compliance, bundle, auditor, dpa, audit-ledger,
nis2, dora, cra, ai-act, regulatory-handoff -->` within the first 5
lines.

##### FR-I6-CA-043 — Standard H1 anchor

`# Standard — Compliance Artefacts Bundle` as H1.

##### FR-I6-CA-044 — Frontmatter narrative block

A frontmatter narrative block under H1 carrying `version: 1.0.0`,
`last_reviewed: 2026-05-12`, `expires_at: 2027-05-12`,
`exception_constitutional: false`, `linter_rule: null`,
`enforcement: {ci_blocking: false, pre_commit_hook: false}`,
`rationale: "Documents the deterministic .tgz hand-off bundle for
EU regulator counter-parties."`.

##### FR-I6-CA-045 — H2 section count

The standard MUST contain ≥ 6 H2 sections, named exactly :
- `## Purpose & EU compliance rationale`
- `## Bundle content schema`
- `## Determinism guarantee`
- `## Consumption protocol`
- `## Regeneration cadence`
- `## Interdictions`

##### FR-I6-CA-046 — Bundle content schema H2 carries the 6-row table

The `## Bundle content schema` H2 MUST contain a Markdown table
listing exactly the 6 bundle members from FR-I6-CA-008. Headers :
`| Member path | Source | Schema |`. Six rows.

##### FR-I6-CA-047 — Determinism guarantee H2 cites SOURCE_DATE_EPOCH

The `## Determinism guarantee` H2 MUST cite the
`SOURCE_DATE_EPOCH` environment variable as the canonical
reproducibility input. MUST cite the cross-link
`global/sbom-policy.md::Regeneration cadence` for precedent.

##### FR-I6-CA-048 — Consumption protocol H2 cites I.5 future workflow

The `## Consumption protocol` H2 MUST cite I.5
(`forge-compliance.yml`) as the canonical downstream consumer +
explicitly note that I.5 has not shipped yet and the bundle is a
forward-stable contract.

##### FR-I6-CA-049 — Regeneration cadence H2 cites release + on-demand + reproducibly

Three bullets : per release, on demand, reproducibly with
`SOURCE_DATE_EPOCH`. Mirrors `global/sbom-policy.md::Regeneration
cadence`.

##### FR-I6-CA-050 — Interdictions H2 carries ≥ 3 MUST NOT

The `## Interdictions` H2 MUST contain ≥ 3 RFC-2119 "MUST NOT"
clauses :
1. MUST NOT include adopter PII or secret material in the bundle.
2. MUST NOT bypass the determinism guarantee with `--no-deterministic`
   or equivalent escape hatch.
3. MUST NOT add NIS2 / DORA / CRA / AI Act regulatory deadlines
   without Themis (K.5, T7+) — bundle layout is forward-stable but
   contents stay frozen until Themis ships.

##### FR-I6-CA-051 — RFC-2119 vocabulary

The standard MUST use RFC-2119 capital-letter keywords (MUST,
MUST NOT, SHOULD, MAY) at least 5 times total.

##### FR-I6-CA-052 — Demeter cross-link

The standard MUST cross-link `.claude/agents/demeter.md` in at
least one H2 section (Demeter is the canonical consumer for the
audit ledger snapshot).

##### FR-I6-CA-053 — Forward-compatibility note

The standard MUST contain a sentence stating that the bundle schema
v1.0.0 will expand to include Themis-territory artefacts (NIS2 /
DORA / CRA / AI Act) when Themis ships, **without** a major SemVer
bump (additive change).

##### FR-I6-CA-054 — File size

The standard SHOULD fit under 300 lines of Markdown (NFR-I6-CA-003).
Soft constraint.

##### FR-I6-CA-055 — Constitutional Compliance section

The standard SHOULD contain a `## Constitutional Compliance` H2
listing Articles III.4 / V / XI / XII compliance. (Optional but
recommended per existing pattern.)

#### Cluster 4 — Standards index + REVIEW (FR-I6-CA-060 → 070)

##### FR-I6-CA-060 — Index entry presence

`.forge/standards/index.yml` MUST contain a new entry under a
new "I.6 — Compliance artefacts bundle" section header comment
(mirrors the existing "I.2 — Compliance tiers" section header).

##### FR-I6-CA-061 — Index entry id

The entry's `id:` field MUST equal `global/compliance-artefacts-bundle`.

##### FR-I6-CA-062 — Index entry path

The entry's `path:` field MUST equal
`standards/global/compliance-artefacts-bundle.md`.

##### FR-I6-CA-063 — Index entry triggers

The entry's `triggers:` list MUST contain at least :
`compliance`, `bundle`, `auditor`, `dpa`, `audit-ledger`,
`nis2`, `dora`, `cra`, `ai-act`, `regulatory-handoff`.

##### FR-I6-CA-064 — Index entry scope + priority

`scope: all`, `priority: high`.

##### FR-I6-CA-070 — REVIEW.md entry presence

`.forge/standards/REVIEW.md` MUST contain a new H2 section header
`## 2026-05-12 — Initial ratification (i6-compliance-artefacts)`
appended after the existing last entry.

##### FR-I6-CA-071 — REVIEW.md entry shape

The entry MUST list the standard with version `1.0.0`, decision
`KEEP`, next review `2027-05-12`, with explanatory notes
cross-linking the bundle script + the I.2 / K.3 / J.8 deps.

#### Cluster 5 — Adopter doc (FR-I6-CA-080 → 085)

##### FR-I6-CA-080 — `docs/COMPLIANCE.md` Auditor hand-off H2

`docs/COMPLIANCE.md` MUST contain a new H2 section
`## Auditor hand-off bundle` (after the existing
`## Cross-references` H2).

##### FR-I6-CA-081 — Auditor hand-off H2 cross-links

The new H2 MUST cross-link :
- `.forge/scripts/compliance/bundle.sh` (the script).
- `.forge/standards/global/compliance-artefacts-bundle.md` (the
  standard).

##### FR-I6-CA-082 — Auditor hand-off H2 cites determinism

The new H2 MUST mention `SOURCE_DATE_EPOCH` as the determinism
input.

#### Cluster 6 — Roadmap / plan inventory (FR-I6-CA-090 → 092)

##### FR-I6-CA-090 — `docs/new-archetypes-plan.md` row I.6 status update

Row I.6 in `docs/new-archetypes-plan.md` §7.1 MUST be updated to
mark **I.6 Done** with a citation back to this change name
(`i6-compliance-artefacts`).

##### FR-I6-CA-091 — `.forge/product/roadmap.md` inventory delta

`.forge/product/roadmap.md` MUST gain an inventory line for the
delivery, mirroring the existing "I.2 done" line style.

##### FR-I6-CA-092 — CHANGELOG entry

`CHANGELOG.md` `[Unreleased]` section MUST gain an
`### Added — I.6 compliance artefacts bundle (i6-compliance-artefacts)`
entry citing the script + template + standard + harness.

#### Cluster 7 — Test harness (FR-I6-CA-100 → 115)

##### FR-I6-CA-100 — Harness file presence

`.forge/scripts/tests/i6.test.sh` MUST exist as executable bash.

##### FR-I6-CA-101 — Harness audit comment

The harness MUST carry `<!-- Audit: I.6 (i6-compliance-artefacts) -->`
or `# Audit: I.6 (i6-compliance-artefacts)` within the first 10
lines.

##### FR-I6-CA-102 — L1 test count

The harness MUST run ≥ 14 L1 hermetic tests covering :
1. Bundle script presence + executable
2. Bundle script `--help` exit 0
3. Bundle script audit comment
4. Bundle script bogus-arg exit 2
5. Template presence
6. Template audit comment + canonical example
7. Standard presence + H1 anchor
8. Standard frontmatter + version + dates
9. Standard ≥ 6 H2 sections
10. Standard ≥ 3 MUST NOT clauses
11. Standards index entry
12. REVIEW.md birth entry
13. docs/COMPLIANCE.md Auditor hand-off H2
14. CHANGELOG.md entry

##### FR-I6-CA-103 — L2 test count

The harness MUST run ≥ 2 L2 fixture-based tests :
1. Bundle good fixture — synthetic tree, run bundle, assert
   `.tgz` produced + 6 members + MANIFEST present.
2. Bundle determinism — run twice with `SOURCE_DATE_EPOCH=0` and
   assert byte-identical output via `diff -q` on the `.tgz` files.

##### FR-I6-CA-110 — CI registration

`.github/workflows/forge-ci.yml` `harness` job MUST contain a new
matrix row invoking `bash .forge/scripts/tests/i6.test.sh
--level 1,2` immediately after the existing `i2.test.sh` row.

##### FR-I6-CA-111 — Exit codes

The harness MUST exit 0 when all tests GREEN, 1 otherwise.
Mirrors the existing `_helpers.sh::print_summary` contract.

##### FR-I6-CA-112 — `--level` parsing

The harness MUST accept `--level 1`, `--level 2`, `--level 1,2`,
`--level all` (default `1`).

##### FR-I6-CA-113 — Harness audit-comment self-citation

The harness MUST cite at least one FR-I6-CA-XXX identifier per
test function in MANIFEST comments (mirrors `i2.test.sh` /
`j8.test.sh`).

##### FR-I6-CA-115 — Harness performance budget

L1 tests MUST complete in ≤ 5 s wall-clock on a developer laptop
(NFR-I6-CA-001).

---

### Non-Functional Requirements

#### NFR-I6-CA-001 — Test harness performance budget

`bash .forge/scripts/tests/i6.test.sh --level 1` MUST complete in
≤ 5 s wall-clock on a developer laptop ; L2 fixture tests MUST
complete in ≤ 10 s additional. Mirrors `i2.test.sh::NFR-I2-CT-001`
+ `j8.test.sh` L2 budget.

#### NFR-I6-CA-002 — Backward compatibility

The bundle script is additive. No existing artefact, change, test
harness, or CI workflow row MUST regress. `verify.sh` overall PASS
MUST be preserved (no new FAIL ; the `Passed` total MUST monotonically
increase or stay equal across this change).

#### NFR-I6-CA-003 — Standard file size

`.forge/standards/global/compliance-artefacts-bundle.md` SHOULD
remain under 300 lines of Markdown to keep adopter reading time
under 5 min.

#### NFR-I6-CA-004 — Pattern reuse — bash thin + Python 3 inline

`.forge/scripts/compliance/bundle.sh` MUST follow the bash thin +
Python 3 inline pattern of `bin/forge-sbom.sh` verbatim : a bash
front-end that parses args + validates inputs + emits usage, then
invokes a single inline `python3 - "$@" <<'PY' ... PY` heredoc
for the actual bundle assembly + tarfile emission. No separate
Python file ; no external CLI dependency.

#### NFR-I6-CA-005 — Determinism guarantee (byte-identical output)

When `SOURCE_DATE_EPOCH` is set, two consecutive `bash
.forge/scripts/compliance/bundle.sh --target <same-tree>
--output <path-N>` invocations MUST produce byte-identical `.tgz`
files. Asserted by the L2 fixture test via `diff -q`.

#### NFR-I6-CA-006 — No external dependency

The bundle script MUST work with Python 3.11+ stdlib only :
`tarfile`, `hashlib`, `json`, `os`, `sys`, `datetime`, `pathlib`.
No `pip install` required. (PyYAML is already a Forge-wide
dependency — F.2 / J.7 / J.8.d — and the bundle's audit-ledger
reads `.forge/changes/*/.forge.yaml` so PyYAML is used, NOT a new
dep.)

#### NFR-I6-CA-007 — CI workflow line budget

The added `forge-ci.yml` matrix row MUST keep the file under the
NFR-CI-002 budget of 300 lines. Current file is 269 lines ;
adding one row brings it to ~271 lines. Comfortable margin.

#### NFR-I6-CA-008 — Bundle output size budget

A bundle produced over `examples/forge-fsm-example/` SHOULD weigh
under 256 KiB (gzipped). Soft constraint ; depends on the SBOM
content. Asserted approximately by the L2 fixture test.

#### NFR-I6-CA-009 — Verify.sh / constitution-linter.sh additive

The change MUST NOT introduce new `[NEEDS CLARIFICATION:]` markers
in implemented changes. `constitution-linter.sh` OVERALL PASS MUST
be preserved.

---

## ADRs (locked at design time, see `design.md`)

- **ADR-I6-CA-001** — Bundle archive format : `.tgz` (gzip POSIX
  tar) — resolves Q-001.
- **ADR-I6-CA-002** — Audit ledger snapshot location : flat
  inside `audit/` subdirectory at bundle root — resolves Q-002.
- **ADR-I6-CA-003** — Script location :
  `.forge/scripts/compliance/bundle.sh` — resolves Q-003.

---

## Constitutional Compliance summary

- **Article I (TDD)** — RED → GREEN → REFACTOR enforced via
  `tasks.md` Phase 1 (full RED harness) before Phase 2 (script
  authoring).
- **Article II (BDD)** — Gherkin scenarios in `proposal.md`.
- **Article III.4 (anti-hallucination)** — `[NEEDS CLARIFICATION:]`
  protocol observed ; three Q-NNN open questions resolved in
  `design.md`.
- **Article V (audit trail)** — every task tagged
  `[Story: FR-I6-CA-XXX]` ; script header carries audit comment.
- **Article XI (AI-first)** — Demeter consumes the audit ledger
  snapshot ; structured JSON ; no opaque LLM content.
- **Article XII (governance)** — ENFORCES contract for bundle
  determinism + content schema ; does NOT amend any Article.

No constitutional amendment required.
