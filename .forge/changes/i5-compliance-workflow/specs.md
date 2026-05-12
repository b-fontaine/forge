# Specifications: i5-compliance-workflow
<!-- Status: archived -->
<!-- Schema: default -->

**Namespace** : `FR-I5-CW-*` / `NFR-I5-CW-*`. **Constitution** :
v1.1.0. No amendment required (I.5 ships a workflow YAML + a
standard ; modifies no Article).

## Source Documents

| Field                  | Value                                                                                                                                                                              |
|------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**           | `docs/new-archetypes-plan.md` §7.1 line 962-963 (I.5 row) ; §10 lines 727-743 (I-module roadmap)                                                                                    |
| **Demeter dep**        | `k3-demeter` archived 2026-05-12 — ships `bin/forge-demeter-scan.sh` with tier-scaled severity (exit 0 CLEARED, exit 3 BLOCKED)                                                     |
| **Linter dep**         | `i3-t3-forbidden-linter` archived 2026-05-12 — ships `constitution-linter.sh::ADR-I3-001 T3-Forbidden Components` section with tier-scaled severity (T1/T2 WARN Phase A, T3 FAIL)   |
| **SBOM dep**           | `j8-janus-rules` archived 2026-05-10 — ships `bin/forge-sbom.sh` CycloneDX 1.5 generator (exit 0 success, exit 1 no lockfile)                                                       |
| **Bundle dep**         | `i6-compliance-artefacts` archived 2026-05-12 — ships `.forge/scripts/compliance/bundle.sh` deterministic `.tgz` (exit 0 success, exit 1 missing artefact, exit 2 usage error)      |
| **Tier ledger**        | `j8-janus-rules` ADR-J8-006 — `.forge/.forge-tier` plain-text ledger ; `--eu-tier` flag plumbing                                                                                    |
| **Exit code envelope** | `j8-janus-rules` ADR-J8-003 (exit 3 refusal) + I.3 ADR-I3-003 (tier-scaled WARN/FAIL) — workflow propagates as exit 0/1 (GitHub Actions step contract)                              |
| **CI workflow size**   | `.github/workflows/forge-ci.yml` 277 lines ; NFR-CI-002 budget ≤ 300                                                                                                                |
| **Pattern reuse**      | `.github/workflows/forge-ci.yml` for declarative shape + actions/checkout@v4 / setup-python@v5 / upload-artifact@v4 versions                                                        |
| **Standard frame**     | `global/standards-lifecycle.md` (T.4 — frontmatter contract, 12-month review cycle, REVIEW.md append-only ledger) ; `global/compliance-artefacts-bundle.md` (I.6, sibling MD)       |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Reusable workflow file (FR-I5-CW-001 → 060)

##### FR-I5-CW-001 — Workflow file presence

A new file `.github/workflows/forge-compliance.yml` MUST exist.

##### FR-I5-CW-002 — Audit comment

The workflow file MUST carry a comment
`# <!-- Audit: I.5 (i5-compliance-workflow) -->` or
`# Audit: I.5 (i5-compliance-workflow)` within the first 10 lines.

##### FR-I5-CW-003 — YAML well-formed

The workflow file MUST parse with `python3 -c "import yaml;
yaml.safe_load(open(...).read())"`. No tab characters, no
unclosed strings.

##### FR-I5-CW-004 — Workflow name

The workflow MUST declare `name: forge-compliance`.

##### FR-I5-CW-005 — `workflow_call` trigger

The workflow MUST declare `on: workflow_call:` as its only
trigger. No `push:`, no `pull_request:` (the workflow is reusable
only).

##### FR-I5-CW-010 — Input `eu-tier`

The workflow MUST declare an input `eu-tier` :
- `required: true`
- `type: string`
- Description : `"EU compliance tier: T1, T2, or T3"`

##### FR-I5-CW-011 — Input `target-dir`

The workflow MUST declare an input `target-dir` :
- `required: false`
- `default: "."`
- `type: string`
- Description : adopter repo root path inside the runner workspace.

##### FR-I5-CW-012 — Input `artefact-name`

The workflow MUST declare an input `artefact-name` :
- `required: false`
- `default: forge-compliance-artefacts`
- `type: string`

##### FR-I5-CW-020 — Output `artefact-path`

The workflow MUST declare an output `artefact-path` carrying the
relative path of the uploaded compliance `.tgz` artefact inside
the runner workspace. Sourced from the `compliance` job's
output of the same name.

##### FR-I5-CW-025 — Permissions block

The workflow MUST declare `permissions: contents: read` at the
top level (Aegis hygiene per `forge-ci.yml` precedent).

##### FR-I5-CW-030 — Single job `compliance`

The workflow MUST declare a single job named `compliance`,
running on `ubuntu-latest`.

##### FR-I5-CW-031 — Job outputs

The `compliance` job MUST declare an output `artefact-path` :
```yaml
outputs:
  artefact-path: ${{ steps.bundle.outputs.path }}
```

##### FR-I5-CW-032 — Tier validation step

The first runtime step (after checkout + setup-python) MUST
validate the `eu-tier` input is one of `T1`, `T2`, `T3`. Any
other value MUST emit `::error::invalid eu-tier '...'` and exit
the workflow with failure.

##### FR-I5-CW-033 — Checkout step

The workflow MUST use `actions/checkout@v4` as the first step.
The pinned major MUST be `v4` (matches `forge-ci.yml` precedent).

##### FR-I5-CW-034 — Setup Python step

The workflow MUST use `actions/setup-python@v5` with
`python-version: "3.11"` (matches `forge-ci.yml` precedent).

##### FR-I5-CW-035 — Install PyYAML step

The workflow MUST install PyYAML via `pip install pyyaml` (the
bundle script reads `.forge/changes/*/.forge.yaml`).

##### FR-I5-CW-040 — Demeter step

The workflow MUST run `bash bin/forge-demeter-scan.sh --target
${{ inputs.target-dir }} --tier ${{ inputs.eu-tier }}`. Step
name : `Demeter — CLOUD Act dependency scan`. Step id :
`demeter`.

##### FR-I5-CW-041 — Constitution linter step

The workflow MUST run `bash .forge/scripts/constitution-linter.sh`
with `FORGE_EU_TIER=${{ inputs.eu-tier }}` exported, so the I.3
ADR-I3-001 T3-Forbidden Components section resolves the tier
from the env var when no `.forge/.forge-tier` ledger is present
in the calling repo. Step name : `Constitution linter (incl.
T3-Forbidden Components)`. Step id : `linter`.

##### FR-I5-CW-042 — SBOM step

The workflow MUST run `bash bin/forge-sbom.sh --target ${{
inputs.target-dir }} --output sbom.cdx.json`. Step name :
`CycloneDX 1.5 SBOM`. Step id : `sbom`. The step MUST set
`continue-on-error: true` so an exit `1` (no lockfile) does NOT
fail the job — instead the next step (the aggregator) decides
fatality.

##### FR-I5-CW-043 — Bundle step

The workflow MUST run `bash .forge/scripts/compliance/bundle.sh
--target ${{ inputs.target-dir }} --output ${{ inputs.artefact-name }}.tgz`.
Step name : `Compliance artefacts bundle`. Step id : `bundle`.
The step MUST export `SOURCE_DATE_EPOCH` resolved per FR-I5-CW-050.

##### FR-I5-CW-044 — Bundle output recording

The `bundle` step MUST write its output path to
`$GITHUB_OUTPUT` so the job output `artefact-path` (FR-I5-CW-031)
is populated. Implementation :
```bash
echo "path=${{ inputs.artefact-name }}.tgz" >> "$GITHUB_OUTPUT"
```

##### FR-I5-CW-045 — Upload step

The workflow MUST use `actions/upload-artifact@v4` with :
- `name: ${{ inputs.artefact-name }}`
- `path: ${{ inputs.artefact-name }}.tgz`
- `if-no-files-found: error`

##### FR-I5-CW-046 — Aggregator step

A final step MUST inspect the prior step outcomes and exit `1`
if any of the following fired :
- `steps.demeter.outcome != 'success'` (Demeter blocked or
  errored).
- `steps.linter.outcome != 'success'` (linter FAIL).
- `steps.bundle.outcome != 'success'` (bundle assembly failed).
- `steps.sbom.outcome == 'failure'` AND `steps.sbom.conclusion`
  is anything other than the documented "no lockfile" tolerance
  (FR-I5-CW-049).

##### FR-I5-CW-049 — SBOM no-lockfile tolerance

The aggregator MUST treat `steps.sbom.outcome == 'failure'` as
**non-fatal** when the SBOM script's underlying failure is the
documented "no lockfile" case (exit 1). Detection : the SBOM
script emits `forge-sbom: no lockfiles found` on stderr. The
aggregator MAY parse this signal or simply trust the
`continue-on-error: true` framing (recommended : the latter ;
the aggregator emits a `::warning::no lockfile detected, SBOM
omitted from the bundle` annotation when the SBOM step did not
succeed).

##### FR-I5-CW-050 — SOURCE_DATE_EPOCH resolution

The workflow MUST resolve `SOURCE_DATE_EPOCH` in a dedicated
step (or inline inside the `bundle` step) :
```bash
TS="${{ github.event.head_commit.timestamp || github.run_started_at }}"
EPOCH="$(date -u -d "$TS" +%s)"
echo "SOURCE_DATE_EPOCH=$EPOCH" >> "$GITHUB_ENV"
```
Default fallback : `github.run_started_at` when no head_commit
timestamp is available (e.g., `workflow_dispatch`).

##### FR-I5-CW-055 — Concurrency control

The workflow MUST declare a `concurrency:` group at the
top-level :
```yaml
concurrency:
  group: forge-compliance-${{ github.ref }}-${{ inputs.eu-tier }}
  cancel-in-progress: false
```
`cancel-in-progress: false` because compliance audits should run
to completion ; the next push retriggers naturally (mirrors
`forge-ci.yml::push:main` semantics).

##### FR-I5-CW-058 — No `secrets:` declaration

The workflow MUST NOT declare a `secrets:` block. None of the
constituent scripts consume secrets ; pulling them in widens the
attack surface.

##### FR-I5-CW-060 — File size budget

The workflow file SHOULD remain under 200 lines (NFR-I5-CW-002).
Soft constraint.

#### Cluster 2 — Standard file (FR-I5-CW-070 → 092)

##### FR-I5-CW-070 — Standard file presence

A new file `.forge/standards/global/forge-compliance-workflow.md`
MUST exist.

##### FR-I5-CW-071 — Standard audit comment

`<!-- Audit: I.5 (i5-compliance-workflow) -->` within the first
5 lines.

##### FR-I5-CW-072 — Standard trigger comment

`<!-- Trigger: compliance, forge-compliance.yml, reusable-workflow,
workflow_call, eu-tier, ci-enforcement, regulatory-handoff,
github-actions -->` within the first 5 lines.

##### FR-I5-CW-073 — Standard H1 anchor

`# Standard — Forge Compliance Workflow` as H1.

##### FR-I5-CW-074 — Frontmatter narrative block

A frontmatter narrative block under H1 carrying :
- `version: 1.0.0`
- `last_reviewed: 2026-05-12`
- `expires_at: 2027-05-12`
- `exception_constitutional: false`
- `linter_rule: null`
- `enforcement: {ci_blocking: false, pre_commit_hook: false}`
- `forbidden: []`
- `rationale: "Documents the reusable forge-compliance.yml workflow contract for adopter repos."`

##### FR-I5-CW-075 — H2 section count

The standard MUST contain ≥ 6 H2 sections (target 7) named
exactly :
- `## Purpose & EU compliance rationale`
- `## Workflow inputs and outputs`
- `## Step-by-step contract`
- `## Tier-scaled severity aggregation`
- `## Consumption protocol`
- `## Interdictions`
- `## Constitutional Compliance`

##### FR-I5-CW-076 — Inputs schema H2 carries the 3-row table

The `## Workflow inputs and outputs` H2 MUST contain a Markdown
table listing exactly the 3 inputs (`eu-tier`, `target-dir`,
`artefact-name`) with required / default / type columns, AND a
second table for the 1 output (`artefact-path`).

##### FR-I5-CW-077 — Step-by-step H2 references the 4 scripts

The `## Step-by-step contract` H2 MUST cite all four constituent
scripts by absolute path :
- `bin/forge-demeter-scan.sh`
- `.forge/scripts/constitution-linter.sh`
- `bin/forge-sbom.sh`
- `.forge/scripts/compliance/bundle.sh`

##### FR-I5-CW-078 — Severity aggregation H2 cites tier matrix

The `## Tier-scaled severity aggregation` H2 MUST cite :
- I.3 ADR-I3-003 (T1/T2 WARN Phase A → T3 FAIL).
- K.3 FR-K3-DEM-068 (Demeter tier-scaled severity).
- The exit-code aggregation table (3 rows × 4 columns showing
  each script's behaviour at each tier).

##### FR-I5-CW-079 — Consumption protocol H2 cites `uses:` pattern

The `## Consumption protocol` H2 MUST include a copy-pasteable
adopter-side YAML snippet :
```yaml
jobs:
  compliance:
    uses: <forge-repo>/.github/workflows/forge-compliance.yml@<ref>
    with:
      eu-tier: T2
```

##### FR-I5-CW-080 — Interdictions H2 carries ≥ 3 MUST NOT

The `## Interdictions` H2 MUST contain ≥ 3 RFC-2119 "MUST NOT"
clauses :
1. MUST NOT modify the four constituent scripts from within the
   workflow ; the workflow is purely orchestrational.
2. MUST NOT pass `--no-deterministic` or equivalent escape hatch
   to the bundle script — `SOURCE_DATE_EPOCH` determinism is a
   non-negotiable contract.
3. MUST NOT widen the permissions block beyond `contents: read`
   without a corresponding ADR amendment under Article XII.

##### FR-I5-CW-081 — RFC-2119 vocabulary

The standard MUST use RFC-2119 capital-letter keywords (MUST,
MUST NOT, SHOULD, MAY) at least 5 times total.

##### FR-I5-CW-082 — Demeter / Aegis / Janus cross-link

The standard MUST cross-link at least one of `.claude/agents/demeter.md`,
`.claude/agents/aegis.md`, or `.claude/agents/cross-layer-orchestrator.md`
(Janus) in at least one H2 section.

##### FR-I5-CW-083 — Forward-compatibility note

The standard MUST contain a sentence stating that the workflow
schema v1.0.0 will expand to include Themis-territory checks
(NIS2 / DORA / CRA / AI Act deadline guards) when Themis ships,
**without** a major SemVer bump (additive change).

##### FR-I5-CW-084 — File size

The standard SHOULD fit under 300 lines of Markdown
(NFR-I5-CW-003).

##### FR-I5-CW-085 — Constitutional Compliance section

The standard MUST contain a `## Constitutional Compliance` H2
listing Articles III.4 / V / XI / XII compliance.

#### Cluster 3 — Standards index + REVIEW (FR-I5-CW-090 → 100)

##### FR-I5-CW-090 — Index entry presence

`.forge/standards/index.yml` MUST contain a new entry under a
new "I.5 — Forge compliance workflow" section header comment.

##### FR-I5-CW-091 — Index entry id

The entry's `id:` field MUST equal `global/forge-compliance-workflow`.

##### FR-I5-CW-092 — Index entry path

The entry's `path:` field MUST equal
`standards/global/forge-compliance-workflow.md`.

##### FR-I5-CW-093 — Index entry triggers

The entry's `triggers:` list MUST contain at least :
`compliance`, `forge-compliance.yml`, `reusable-workflow`,
`workflow_call`, `eu-tier`, `ci-enforcement`,
`regulatory-handoff`, `github-actions`. Eight triggers minimum.

##### FR-I5-CW-094 — Index entry scope + priority

`scope: all`, `priority: high`.

##### FR-I5-CW-100 — REVIEW.md entry presence

`.forge/standards/REVIEW.md` MUST contain a new H2 section header
`## 2026-05-12 — Initial ratification (i5-compliance-workflow)`
appended after the existing last entry.

##### FR-I5-CW-101 — REVIEW.md entry shape

The entry MUST list the standard with version `1.0.0`, decision
`KEEP`, next review `2027-05-12`, with explanatory notes
cross-linking the workflow + the I.3 / I.6 / K.3 / J.8 deps.

#### Cluster 4 — Adopter doc (FR-I5-CW-110 → 113)

##### FR-I5-CW-110 — `docs/COMPLIANCE.md` H2

`docs/COMPLIANCE.md` MUST contain a new H2 section
`## Reusable compliance workflow` after the existing
`## Auditor hand-off bundle` H2.

##### FR-I5-CW-111 — H2 cross-links

The new H2 MUST cross-link :
- `.github/workflows/forge-compliance.yml` (the workflow).
- `.forge/standards/global/forge-compliance-workflow.md` (the
  standard).

##### FR-I5-CW-112 — H2 carries copy-pasteable `uses:` block

The new H2 MUST include a fenced YAML code block showing the
adopter-side `uses:` reference verbatim.

##### FR-I5-CW-113 — H2 cites tier inheritance

The new H2 MUST mention how the `eu-tier` input maps to the
declared `.forge/.forge-tier` ledger in the adopter repo, OR
explicitly note that the workflow accepts the tier as a per-call
input independent of any ledger.

#### Cluster 5 — Test harness (FR-I5-CW-114 → 130)

##### FR-I5-CW-114 — Harness file presence

`.forge/scripts/tests/i5.test.sh` MUST exist as executable bash.

##### FR-I5-CW-115 — Harness audit comment

The harness MUST carry `# Audit: I.5 (i5-compliance-workflow)`
within the first 10 lines.

##### FR-I5-CW-116 — L1 test count

The harness MUST run ≥ 13 L1 hermetic tests covering the
manifest in `design.md` § "L1 unit-level" table.

##### FR-I5-CW-117 — L2 test count

The harness MUST declare 1 L2 fixture-based test gated by both
`--level 2` (or `--level 1,2`) AND `FORGE_I5_ACT=1`. When either
gate is absent, the test MUST exit 0 with an informational
`[INFO: ...]` line on stderr.

##### FR-I5-CW-120 — CI registration

`.github/workflows/forge-ci.yml` `harness` job MUST contain a new
matrix row invoking `bash .forge/scripts/tests/i5.test.sh
--level 1` immediately after the existing `i3.test.sh` row (or
after `i6.test.sh` ; both are equivalent — pick whichever keeps
the section coherent). The file MUST stay ≤ 300 lines.

##### FR-I5-CW-121 — Exit codes

The harness MUST exit 0 when all tests GREEN, 1 otherwise.

##### FR-I5-CW-122 — `--level` parsing

The harness MUST accept `--level 1`, `--level 2`, `--level 1,2`,
`--level all` (default `1`).

##### FR-I5-CW-123 — Harness MANIFEST comments

The harness MUST cite at least one FR-I5-CW-XXX identifier per
test function in MANIFEST comments (mirrors `i2.test.sh` /
`i3.test.sh` / `i6.test.sh`).

##### FR-I5-CW-130 — Harness performance budget

L1 tests MUST complete in ≤ 5 s wall-clock on a developer laptop
(NFR-I5-CW-001).

#### Cluster 6 — Roadmap / plan inventory + CHANGELOG (FR-I5-CW-140 → 142)

##### FR-I5-CW-140 — `docs/new-archetypes-plan.md` row I.5 status update

Row I.5 in `docs/new-archetypes-plan.md` MUST be updated to mark
**I.5 Done** with a citation back to this change name
(`i5-compliance-workflow`). The §10 I-module table + the §13
"Modules toujours en attente" section + the "Modules en cours"
section + the final "8. Livrer I.3 + I.5" milestone MUST all
reflect the new status.

##### FR-I5-CW-141 — `.forge/product/roadmap.md` inventory delta

`.forge/product/roadmap.md` MUST gain an inventory line for the
delivery, mirroring the existing "I.3 done" / "I.6 done" line
style. The T5 row + the "ADR ratification (architecture target)"
milestone row + the I-module phase row MUST all be updated.

##### FR-I5-CW-142 — CHANGELOG entry

`CHANGELOG.md` `[Unreleased]` section MUST gain an
`### Added — I.5 forge-compliance.yml reusable workflow (i5-compliance-workflow)`
entry citing the workflow + standard + harness + index entry.

---

### Non-Functional Requirements

#### NFR-I5-CW-001 — Test harness performance budget

`bash .forge/scripts/tests/i5.test.sh --level 1` MUST complete in
≤ 5 s wall-clock on a developer laptop. Mirrors
`i6.test.sh::NFR-I6-CA-001`.

#### NFR-I5-CW-002 — Workflow file size budget

`.github/workflows/forge-compliance.yml` SHOULD remain under 200
lines. Soft constraint. Separate from `forge-ci.yml`'s 300-line
NFR-CI-002 cap (different file).

#### NFR-I5-CW-003 — Standard file size budget

`.forge/standards/global/forge-compliance-workflow.md` SHOULD
remain under 300 lines. Mirrors `i6` NFR-I6-CA-003.

#### NFR-I5-CW-004 — Backward compatibility

The workflow is additive. No existing artefact, change, test
harness, or CI workflow row MUST regress. `verify.sh` overall
PASS MUST be preserved (no new FAIL ; the `Passed` total MUST
monotonically increase or stay equal across this change).

#### NFR-I5-CW-005 — No new external dependency

The workflow consumes only :
- `actions/checkout@v4`
- `actions/setup-python@v5`
- `actions/upload-artifact@v4`

All three are already pinned in `forge-ci.yml` and treated as
trusted by the Forge constitution. No new action MUST be
introduced.

#### NFR-I5-CW-006 — Forge-ci.yml line budget

The `.github/workflows/forge-ci.yml` matrix-row addition MUST
keep the file under the NFR-CI-002 budget of 300 lines. Current
file is 277 lines ; adding one row brings it to ~280. Comfortable
margin.

#### NFR-I5-CW-007 — Determinism

The workflow MUST propagate `SOURCE_DATE_EPOCH` to the bundle
script per FR-I5-CW-050 so the uploaded `.tgz` artefact is
byte-identical across re-runs of the same commit. Asserted
by `i6.test.sh::_test_i6_l2_bundle_determinism` end-to-end via
the underlying bundle script ; no separate assertion at I.5
level.

#### NFR-I5-CW-008 — Verify.sh / constitution-linter.sh additive

The change MUST NOT introduce new `[NEEDS CLARIFICATION:]`
markers in implemented changes. `constitution-linter.sh` OVERALL
PASS MUST be preserved.

#### NFR-I5-CW-009 — `act` opt-in semantics (L2)

The L2 fixture MUST skip cleanly (exit 0 with informational
stderr) when `act` is not on `$PATH` or `FORGE_I5_ACT=1` is not
exported. Mirrors `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`
precedent.

---

## ADRs (locked at design time, see `design.md`)

- **ADR-I5-CW-001** — Exit code aggregation : trust each script's
  tier scaling end-to-end ; workflow exits 0/1 ; SBOM
  no-lockfile is non-fatal — resolves Q-001.
- **ADR-I5-CW-002** — `SOURCE_DATE_EPOCH` source :
  `github.event.head_commit.timestamp` with
  `github.run_started_at` fallback, no input field — resolves
  Q-002.
- **ADR-I5-CW-003** — L2 act-runner gating : opt-in via
  `FORGE_I5_ACT=1` env var, skip-when-absent semantics —
  resolves Q-003.

---

## Constitutional Compliance summary

- **Article I (TDD)** — RED → GREEN → REFACTOR enforced via
  `tasks.md` Phase 1 (full RED harness) before Phase 2
  (workflow + standard authoring).
- **Article II (BDD)** — Gherkin scenario in `proposal.md` for
  the adopter-side `uses:` flow.
- **Article III.4 (anti-hallucination)** — `[NEEDS CLARIFICATION:]`
  protocol observed ; three Q-NNN open questions resolved in
  `design.md`.
- **Article V (audit trail)** — every task tagged
  `[Story: FR-I5-CW-XXX]` ; workflow + standard + harness all
  carry the `<!-- Audit: I.5 (...) -->` anchor.
- **Article XI (AI-first)** — Demeter / Aegis / Janus consume
  the workflow's uploaded bundle ; deterministic structured
  artefact (the `.tgz` itself).
- **Article XII (governance)** — the standard ENFORCES the
  contract for the workflow's input / output / step list ; does
  NOT amend any Article. Extensions follow
  `global/standards-lifecycle.md` SemVer.

No constitutional amendment required.
