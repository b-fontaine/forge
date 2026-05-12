# Proposal: i5-compliance-workflow
<!-- Created: 2026-05-12 -->
<!-- Schema: default -->

## Problem

`docs/new-archetypes-plan.md` §7.1 line 962-963 lists item **I.5** as
the *reusable GitHub Actions compliance workflow* — the deliverable
that lets adopter repos opt into Forge's EU-compliance gate by calling
a single `uses:` reference instead of re-assembling the script
matrix by hand each release.

Today, every EU-compliance surface Forge ships is **a separate one-shot
script** :

1. `bin/forge-demeter-scan.sh` (K.3, archived 2026-05-12) — dependency
   CLOUD-Act scanner. Tier-scaled severity ; exit `3` = BLOCKED on
   T2 High / T3 Critical.
2. `bash .forge/scripts/constitution-linter.sh` with the
   `ADR-I3-001 T3-Forbidden Components` section (I.3, archived
   2026-05-12). Tier-scaled severity (T1/T2 → WARN Phase A, T3 →
   FAIL immediate). Exit `1` if any FAIL ; exit `0` otherwise.
3. `bin/forge-sbom.sh` (J.8.d, archived 2026-05-10) — CycloneDX 1.5
   SBOM generator. Exit `0` on success, `1` if no lockfile.
4. `bash .forge/scripts/compliance/bundle.sh` (I.6, archived
   2026-05-12) — assembles MANIFEST + tier-matrix + DPA template +
   audit-ledger + SBOM into a deterministic `.tgz`. Exit `0` on
   success, `1` on missing artefact, `2` on usage error.

Adopters who want CI-time EU enforcement must wire each of these
scripts into their own `.github/workflows/*.yml`, propagate
`--eu-tier`, propagate `SOURCE_DATE_EPOCH`, and aggregate the four
exit-code envelopes themselves. The orchestration is mechanical,
non-creative, and gets re-invented in every adopter repo.

The pattern adopters expect — a **single `uses:` reference** that
runs the four checks in the right order, propagates the declared
tier, uploads the bundle as a CI artefact, and aggregates the
severity envelope — does not exist today.

This change closes the gap by shipping :

- A new reusable workflow `.github/workflows/forge-compliance.yml`
  triggered by `on: workflow_call:` with three inputs
  (`eu-tier`, `target-dir`, `artefact-name`), one output
  (`artefact-path`), and an exit-code envelope mirroring the I.3 +
  K.3 tier-scaled severity contract.
- A new standard `.forge/standards/global/forge-compliance-workflow.md`
  v1.0.0 documenting the workflow's purpose, input/output schema,
  step-by-step contract, tier-scaled severity aggregation,
  consumption protocol (the `uses:` reference adopter repos write),
  and interdictions (≥ 3 RFC-2119 MUST NOT clauses).
- A new test harness `.forge/scripts/tests/i5.test.sh` with ≥ 13 L1
  hermetic grep-based tests + 1 L2 fixture (opt-in via
  `FORGE_I5_DOCKER=1` or `FORGE_I5_ACT=1` ; skipped cleanly when
  `act` is not installed).
- Standards index entry under a new "I.5 — Forge compliance
  workflow" section (id `global/forge-compliance-workflow`,
  ≥ 8 triggers, scope `all`, priority `high`).
- `.forge/standards/REVIEW.md` append-only birth entry 2026-05-12.
- `docs/COMPLIANCE.md` new H2 `## Reusable compliance workflow`
  documenting the `uses:` pattern with a copy-pasteable code block.
- `CHANGELOG.md` `[Unreleased]` entry.
- Updates to `docs/new-archetypes-plan.md` (I.5 row done) +
  `.forge/product/roadmap.md` (archive entry after I.3 / I.6).

## Solution

A single reusable GitHub Actions workflow YAML under
`.github/workflows/`, triggered by `workflow_call`, that orchestrates
the four EU-compliance checks already shipped by I.3 / I.6 / K.3 /
J.8.d. Five coordinated sub-modules :

### I.5.a — Reusable workflow (`.github/workflows/forge-compliance.yml`)

A single GitHub Actions workflow file. Trigger : `on: workflow_call:`
(reusable). Three inputs :

```yaml
on:
  workflow_call:
    inputs:
      eu-tier:
        required: true
        type: string   # one of T1|T2|T3, validated at runtime
      target-dir:
        required: false
        default: "."
        type: string
      artefact-name:
        required: false
        default: forge-compliance-artefacts
        type: string
    outputs:
      artefact-path:
        description: Path of the uploaded compliance .tgz artefact
        value: ${{ jobs.compliance.outputs.artefact-path }}
```

Step list (in order, single job `compliance` on `ubuntu-latest`) :

1. `actions/checkout@v4` — checkout the calling repo.
2. `actions/setup-python@v5` with `python-version: "3.11"` —
   needed by every Forge compliance script.
3. Install PyYAML (required by `.forge/scripts/compliance/bundle.sh`
   when reading `.forge.yaml`).
4. **Demeter scan** : `bash bin/forge-demeter-scan.sh --target
   <target-dir> --tier <eu-tier>`. Tier-scaled severity per K.3 :
   exit 3 = BLOCKED. The workflow propagates exit 3 as workflow
   failure.
5. **Constitution linter** : `bash .forge/scripts/constitution-linter.sh`
   with the T3-Forbidden section active. The linter reads the tier
   from `.forge/.forge-tier` if present (precedent) ; the workflow
   exports `FORGE_EU_TIER=<eu-tier>` so the I.3 section can resolve
   the tier even without a ledger. Exit 1 = OVERALL FAIL.
6. **SBOM** : `bash bin/forge-sbom.sh --target <target-dir>
   --output sbom.cdx.json`. Tolerant : if no lockfile present
   (exit 1), the workflow emits a `::warning::` and continues
   (mirrors I.6's FR-I6-CA-019 missing-lockfile tolerance).
7. **Bundle** : `bash .forge/scripts/compliance/bundle.sh
   --target <target-dir> --output <artefact-name>.tgz`. The
   workflow exports `SOURCE_DATE_EPOCH=${{ github.event.head_commit.timestamp || github.run_started_at }}`
   conversion to Unix epoch so the bundle is reproducible from
   the commit timestamp.
8. **Upload** : `actions/upload-artifact@v4` with name
   `<artefact-name>` and path `<artefact-name>.tgz`.
9. **Aggregate exit codes** : a final inline bash step that
   inspects the prior step outcomes and exits 1 if any
   tier-aware step exited FAIL for the declared tier.

### I.5.b — Standard `.forge/standards/global/forge-compliance-workflow.md`

New Markdown standard with 7 H2 sections documenting :

- Purpose & EU compliance rationale
- Workflow inputs and outputs schema
- Step-by-step contract (the 9-step orchestration above)
- Tier-scaled severity aggregation (how the four scripts' exit
  codes map to the workflow's final outcome at each tier)
- Consumption protocol (the `uses:` reference adopter repos write)
- Interdictions (≥ 3 MUST NOT clauses)
- Constitutional Compliance

Frontmatter pins `version: 1.0.0`, `last_reviewed: 2026-05-12`,
`expires_at: 2027-05-12`, `linter_rule: null` (advisory standard ;
the workflow itself is the enforcement surface — no separate linter
rule needed), `enforcement.ci_blocking: false` (the standard
documents the contract ; CI blocking is a per-adopter choice via
the `uses:` reference being added or not).

### I.5.c — Test harness `.forge/scripts/tests/i5.test.sh`

≥ 13 L1 hermetic grep-based tests :

1. Workflow file exists at `.github/workflows/forge-compliance.yml`.
2. Workflow YAML parses (Python `yaml.safe_load`).
3. Audit comment in first 10 lines.
4. `on: workflow_call:` trigger declared.
5. `inputs.eu-tier` declared with `required: true` + `type: string`.
6. `inputs.target-dir` declared with default `.`.
7. `inputs.artefact-name` declared with default
   `forge-compliance-artefacts`.
8. `outputs.artefact-path` declared.
9. Step list grep-checks : `forge-demeter-scan.sh` invoked.
10. Step list grep-checks : `constitution-linter.sh` invoked.
11. Step list grep-checks : `forge-sbom.sh` invoked.
12. Step list grep-checks : `bundle.sh` invoked.
13. `actions/upload-artifact@v4` step present.
14. Standard file exists with H1 + audit + ≥ 7 H2 + ≥ 3 MUST NOT +
    frontmatter version/dates/linter_rule.
15. Standards index entry under "I.5" section header.
16. REVIEW.md birth entry.
17. `docs/COMPLIANCE.md` H2 `## Reusable compliance workflow`.
18. CHANGELOG entry `i5-compliance-workflow`.

L2 (1 fixture, opt-in) : if `act` is installed and
`FORGE_I5_ACT=1` is exported, run `act workflow_call` against a
synthetic fixture repo and assert exit 0. Otherwise skip cleanly.

### I.5.d — Standards index + REVIEW + docs

- `.forge/standards/index.yml` gains a new entry under a new
  comment section header `# ─── I.5 — Forge compliance workflow
  (i5-compliance-workflow) ──`.
- `.forge/standards/REVIEW.md` gains an append-only birth entry.
- `docs/COMPLIANCE.md` gains an H2 `## Reusable compliance workflow`
  cross-linking the workflow file + the standard.
- `docs/new-archetypes-plan.md` row I.5 updated.
- `.forge/product/roadmap.md` updated.
- `CHANGELOG.md` `[Unreleased]` entry.

### I.5.e — CI registration

`.github/workflows/forge-ci.yml` `harness` job matrix gains a new
row invoking `bash .forge/scripts/tests/i5.test.sh --level 1`
immediately after `i6.test.sh`. NFR-CI-002 size budget : `forge-ci.yml`
≤ 300 lines after this addition (current 277 → ~280).

## Scope In

- `.github/workflows/forge-compliance.yml` (reusable workflow).
- `.forge/standards/global/forge-compliance-workflow.md` v1.0.0
  (≥ 7 H2, ≥ 3 MUST NOT).
- `.forge/standards/index.yml` entry.
- `.forge/standards/REVIEW.md` birth entry.
- `docs/COMPLIANCE.md` new H2.
- `.forge/scripts/tests/i5.test.sh` (≥ 13 L1 + 1 opt-in L2).
- `.github/workflows/forge-ci.yml` matrix row registering the
  harness, with file kept ≤ 300 lines.
- `docs/new-archetypes-plan.md` row I.5 status update.
- `.forge/product/roadmap.md` inventory delta.
- `CHANGELOG.md` `[Unreleased]` entry.

## Scope Out (Explicit Exclusions)

- **NOT** any modification to I.3 / I.6 / K.3 / J.8 standards or
  their scripts. Read-only consumption of the existing exit-code
  envelopes.
- **NOT** NIS2 / DORA / CRA / AI Act regulatory-deadline artefacts
  under `.forge/compliance/{nis2,dora,cra,ai-act}/*`. Those require
  Themis (K.5, T7+).
- **NOT** a Forge CLI wrapper (`forge compliance run` or similar) ;
  the workflow is the only entry point. A CLI surface, if ever
  needed, ships as a separate change.
- **NOT** adopter-side examples beyond a single code block in
  `docs/COMPLIANCE.md`. Building a full adopter-repo fixture is
  Themis territory (multi-arch validation).
- **NOT** any signing (Sigstore cosign) of the uploaded artefact or
  transparency-log upload (Rekor). Out of scope per
  `global/sbom-policy.md::Out-of-scope`.
- **NOT** any constitutional amendment. Articles III.4, V, XI, XII
  preserved.

## Impact

- **Users affected** :
  - Adopters wanting EU-compliance CI gating get a single `uses:`
    reference (the workflow's call-site).
  - Forge's own CI is **NOT changed** by this delivery — the new
    workflow is reusable (`workflow_call`), and Forge's own
    `forge-ci.yml` already runs the four constituent scripts
    directly (no recursion).
  - Themis (K.5, T7+) when it ships extends the workflow via a
    new step (additive ; no schema break in the inputs / outputs).
  - No change for adopters who don't add the `uses:` reference
    (purely opt-in delivery).
- **Technical impact** : ≈ 4 new files (workflow, standard,
  harness, change pipeline) + ≈ 6 modified (index.yml, REVIEW.md,
  COMPLIANCE.md, new-archetypes-plan.md, roadmap.md, CHANGELOG.md,
  forge-ci.yml). Workflow file budget ≤ 200 lines (own NFR ;
  separate from forge-ci's 300-line cap). Test harness ≥ 13 L1.
  **Effort `M`** per `new-archetypes-plan` §7.1 line 962.
- **Dependencies** : all four shipped on `main` 2026-05-12
  (I.2 / I.3 / I.6 / K.3 / J.8). No new external dependency. The
  workflow consumes Python 3.11 stdlib + PyYAML (same as every
  other Forge compliance script).
- **Risk level** : **Low**. The workflow is purely orchestrational
  over scripts already in production. The only real risk is exit-
  code aggregation semantics under mixed-tier severities ;
  resolved at design time via Q-001.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`i5.test.sh` with ≥ 13 L1 stubs all returning `_not_implemented`
(full RED witness). Phase 2 ships the workflow + standard. Phase 3
ships index + REVIEW + docs + CHANGELOG + CI. Phase 4 runs final
gates.

### Article II — BDD

User-facing flow (adopter writes `uses:` reference) gets a Gherkin
scenario in `specs.md`. Internal step-list flows do not.

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-I5-CW-*` +
`NFR-I5-CW-*` namespace before any workflow authoring.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Three open questions Q-001 / Q-002 / Q-003 raised at this phase,
all tracked in `open-questions.md` and resolved during
`/forge:design` :

- **Q-001** — Exit code aggregation under mixed-tier severities
  (e.g., T2 WARN from one rule + T3 FAIL from another).
- **Q-002** — `SOURCE_DATE_EPOCH` source : `github.event.head_commit.timestamp`
  vs `github.run_started_at` vs an explicit `inputs.epoch` ?
- **Q-003** — L2 act-runner integration : opt-in env var name +
  skip-when-absent semantics ?

### Article V — Audit Trail

Each task tagged `[Story: FR-I5-CW-XXX]` (Article V.1, enforced by
`f4-linter-extension`). The workflow file carries
`# <!-- Audit: I.5 (i5-compliance-workflow) -->` in its header
comment block. The standard file carries the same audit comment.

### Article VIII — Infrastructure

The workflow is a single declarative YAML executed by GitHub
Actions on `ubuntu-latest`. No service, no daemon, no privileged
ops. Permissions block scoped to `contents: read` (Aegis hygiene).

### Article IX — Observability

N/A directly. The workflow is a CI-time artefact, not a runtime
component. If an adopter wires the workflow's outcome into their
release telemetry, that is adopter-side.

### Article XI — AI-First Design

The workflow is consumed by Demeter / Aegis / Janus when adopters
hand their CI run summaries to those agents. The schemas are
deterministic structured documents — the I.6 bundle is the
authoritative AI consumption surface, and the workflow uploads it
verbatim.

### Article XII — Governance

The standard ENFORCES the contract for the workflow's input /
output / step list. It does **not amend** any constitutional
article. Extensions (additional inputs, additional steps) follow
`global/standards-lifecycle.md` SemVer rules under BDFL governance
(Phase A) and Themis (Phase B, T7+).

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none in this `proposal.md`.

Three open questions Q-001 + Q-002 + Q-003 raised at this phase,
all tracked in `open-questions.md` and resolved during
`/forge:design`.
