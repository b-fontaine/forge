# Standard — Forge Compliance Workflow

<!-- Audit: I.5 (i5-compliance-workflow) -->
<!-- Trigger: compliance, forge-compliance.yml, reusable-workflow, workflow_call, eu-tier, ci-enforcement, regulatory-handoff, github-actions -->

```yaml
version: 1.0.0
last_reviewed: 2026-05-12
expires_at: 2027-05-12
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "Documents the reusable forge-compliance.yml workflow contract for adopter repos."
```

## Purpose & EU compliance rationale

Forge ships a single **reusable** GitHub Actions workflow at
`.github/workflows/forge-compliance.yml` so adopter repos can gate
their PR + push events against the framework's EU-compliance surface
with one `uses:` reference, no per-repo orchestration boilerplate.

The workflow is the **CI-time orchestration surface** for the four
EU-compliance scripts Forge already ships :

- **Demeter** (`bin/forge-demeter-scan.sh`, K.3) — CLOUD Act
  dependency scanner. Tier-scaled severity per FR-K3-DEM-068.
- **Constitution linter** (`bash .forge/scripts/constitution-linter.sh`,
  with the `ADR-I3-001 T3-Forbidden Components` section from I.3).
  Tier-scaled severity per ADR-I3-003.
- **CycloneDX SBOM** (`bin/forge-sbom.sh`, J.8.d) — minimum-viable
  SBOM at CycloneDX 1.5.
- **Compliance bundle** (`bash .forge/scripts/compliance/bundle.sh`,
  I.6) — deterministic `.tgz` packing tier matrix + DPA template +
  audit-ledger snapshot + SBOM under one MANIFEST.

The workflow satisfies first-pass review under :

- **NIS2** Article 21 — risk-management + supply-chain transparency.
- **DORA** ICT third-party risk evidence + audit-trail surface.
- **CRA** Article 13 — SBOM availability for products with digital
  elements placed on the EU market.
- **AI Act** — Aegis + Demeter audit trail when AI components
  ship.

Adopters needing richer attestation (license enrichment,
vulnerability cross-refs, transparency-log signing, regulatory
deadline tracking) layer their preferred upstream tooling on top of
this baseline. The full NIS2 / DORA / CRA / AI Act regulatory
deadline artefacts under `.forge/compliance/{nis2,dora,cra,ai-act}/`
require **Themis** (K.5, T7+) to maintain ; the workflow contract
in this v1.0.0 is **forward-stable** so Themis-territory steps drop
in additively without a breaking change (see § Forward
compatibility below).

## Workflow inputs and outputs

The workflow is triggered exclusively by `on: workflow_call:`. It
exposes three inputs :

| Input            | Required | Type   | Default                         | Description                                                |
|------------------|----------|--------|---------------------------------|------------------------------------------------------------|
| `eu-tier`        | yes      | string | —                               | EU compliance tier — one of `T1`, `T2`, `T3`               |
| `target-dir`     | no       | string | `.`                             | Adopter repo root inside the runner workspace              |
| `artefact-name`  | no       | string | `forge-compliance-artefacts`    | Name of the uploaded compliance `.tgz` artefact            |

And one output :

| Output           | Description                                                                                                                            |
|------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| `artefact-path`  | Relative path of the uploaded `.tgz` artefact inside the runner workspace (default `forge-compliance-artefacts.tgz`)                   |

The workflow rejects `eu-tier` values outside `{T1, T2, T3}` with a
`::error::` annotation and immediate failure. `target-dir` defaults
to the calling workflow's checkout root ; adopter repos with a
non-standard layout (e.g. Forge configuration nested under a
sub-directory) set `target-dir` explicitly.

## Step-by-step contract

The workflow's `compliance` job runs on `ubuntu-latest` and executes
the following steps in order :

1. **`actions/checkout@v4`** — checkout the calling repo's HEAD.
2. **`actions/setup-python@v5`** with `python-version: "3.11"` —
   needed by every Forge compliance script.
3. **`pip install pyyaml`** — required by
   `.forge/scripts/compliance/bundle.sh` and the linter.
4. **Validate `eu-tier`** — reject values outside `{T1, T2, T3}`.
5. **Resolve `SOURCE_DATE_EPOCH`** — derive from
   `github.event.head_commit.timestamp` with
   `github.run_started_at` fallback (per ADR-I5-CW-002).
6. **Demeter** — `bash bin/forge-demeter-scan.sh --target
   <target-dir> --tier <eu-tier>`. Step id `demeter`.
7. **Constitution linter** — `FORGE_EU_TIER=<eu-tier> bash
   .forge/scripts/constitution-linter.sh`. Step id `linter`. The
   env var lets the I.3 ADR-I3-001 section resolve the tier when
   no `.forge/.forge-tier` ledger is present in the calling repo.
8. **CycloneDX SBOM** — `bash bin/forge-sbom.sh --target
   <target-dir> --output sbom.cdx.json`. Step id `sbom` ;
   `continue-on-error: true` so no-lockfile (exit 1) does not fail
   the job.
9. **Compliance bundle** — `bash .forge/scripts/compliance/bundle.sh
   --target <target-dir> --output <artefact-name>.tgz`. Step id
   `bundle`. Writes the output path to `$GITHUB_OUTPUT`.
10. **`actions/upload-artifact@v4`** — upload the `.tgz` with
    `if-no-files-found: error`.
11. **Aggregator** — final inline bash step inspecting
    `steps.<id>.outcome` for all four constituent steps and exiting
    `1` if any of {demeter, linter, bundle} is not `'success'`. SBOM
    no-success is treated as informational (emits `::warning::`).

The four constituent scripts are referenced by their absolute path
in this workflow ; the workflow MUST NOT shadow them with local
re-implementations (see Interdictions).

## Tier-scaled severity aggregation

The workflow's final exit code is the maximum severity observed
across the four constituent steps, with the SBOM no-lockfile case
explicitly tolerated. Per script :

| Script   | T1 behaviour                                  | T2 behaviour                                  | T3 behaviour                                                  |
|----------|-----------------------------------------------|-----------------------------------------------|---------------------------------------------------------------|
| Demeter  | Informational findings ; exit 0 typical       | High severity → exit 3 (BLOCKED)              | Critical severity → exit 3 (BLOCKED)                          |
| Linter   | T3-Forbidden section WARN-only (Phase A)      | T3-Forbidden section WARN-only (Phase A)      | T3-Forbidden section FAIL → exit 1                            |
| SBOM     | exit 0 if lockfile ; exit 1 (warn) if absent  | exit 0 if lockfile ; exit 1 (warn) if absent  | exit 0 if lockfile ; exit 1 (warn) if absent (still non-fatal)|
| Bundle   | exit 0 on success ; exit 1 if source missing  | exit 0 on success ; exit 1 if source missing  | exit 0 on success ; exit 1 if source missing                  |

The aggregation rule (ADR-I5-CW-001) is **trust each script's tier
scaling end-to-end** :

- Demeter exits `0` / `3` ; the workflow propagates as `0` / `1`
  (GitHub Actions step contract collapses every non-zero step into
  a step failure). The script's tier scaling produces the right
  signal already (FR-K3-DEM-068).
- The linter's `OVERALL` line emits `PASS` (exit 0) or `FAIL`
  (exit 1) ; the T3-Forbidden section's tier-scaled WARN/FAIL is
  internal to the script per ADR-I3-003.
- The SBOM step uses `continue-on-error: true` so its exit 1
  (no-lockfile) does not collapse the job ; the aggregator emits
  a GitHub Actions `::warning::` instead.
- The bundle script's exit `1` (missing source artefact) and exit
  `2` (usage error) both propagate as workflow failure.

Cross-references :
- I.3 ADR-I3-003 — tier-scaled severity scaling rule
  (T1/T2 → WARN Phase A, T3 → FAIL immediate).
- K.3 FR-K3-DEM-068 — Demeter severity scaling
  (T1 → Informational, T2 → High, T3 → Critical).
- J.8 ADR-J8-003 — exit `3` refusal envelope (Janus refusal rules
  ; same exit-code convention Demeter inherits).
- I.6 FR-I6-CA-019 — SBOM no-lockfile tolerance (bundle ships an
  empty CycloneDX envelope instead of failing).

## Consumption protocol

Adopter repos consume this workflow with a single `uses:` reference
inside their own `.github/workflows/*.yml` :

```yaml
# Adopter repo: .github/workflows/eu-compliance.yml
name: eu-compliance

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  compliance:
    uses: <forge-repo>/.github/workflows/forge-compliance.yml@<ref>
    with:
      eu-tier: T2          # required ; T1 | T2 | T3
      target-dir: .        # optional ; default '.'
      artefact-name: forge-compliance-artefacts   # optional
```

Replace `<forge-repo>` with the forge repo coordinate (e.g.
`bfontaine/forge` or your fork) and `<ref>` with a tag, branch, or
SHA (e.g. `v0.4.0` or `main`). The workflow uploads
`forge-compliance-artefacts.tgz` as a CI artefact ; adopters
download it from the GitHub Actions UI for hand-off to auditors,
internal review boards, or regulator counter-parties.

The workflow's output `artefact-path` is available to the calling
workflow for further chaining (e.g. uploading to S3, re-signing
via Sigstore, attaching to a release).

Demeter (`.claude/agents/demeter.md`) consumes the bundle's
`audit/audit-ledger.json` member when classifying historical
posture. Aegis (`.claude/agents/aegis.md`) consumes the
`sbom/sbom.cdx.json` member during security review. Janus
(`.claude/agents/cross-layer-orchestrator.md`) consumes the
`tier-matrix/compliance-tiers.md` member at scaffold-time when
refusing T3-forbidden archetypes.

Adopters MAY set `FORGE_LINTER_SKIP_T3_FORBIDDEN=1` in their
calling workflow's `env:` block to opt out of the I.3 T3-Forbidden
section temporarily (e.g. during a rollout phase). The Demeter and
bundle steps have no equivalent escape hatch — adopter projects
that cannot satisfy them either declare a lower tier or change
their dependency posture.

## Forward compatibility

The workflow contract in v1.0.0 is designed for **additive
evolution**. Future changes MAY :

- Add new optional `inputs.*` fields (each new field is a SemVer
  minor bump on this standard).
- Add new steps between the existing ones (e.g. Themis-territory
  regulatory deadline guards under `.forge/compliance/{nis2,dora,
  cra,ai-act}/`) without changing the existing step order.
- Add new triggers to the standards index entry without removing
  existing triggers.

Future changes MUST NOT :

- Remove or rename the three v1.0.0 inputs (`eu-tier`,
  `target-dir`, `artefact-name`).
- Remove or rename the v1.0.0 output (`artefact-path`).
- Bypass `SOURCE_DATE_EPOCH` determinism.
- Widen the permissions block beyond `contents: read` without an
  ADR amendment under Article XII.

When Themis (K.5, T7+) ships, the workflow gains NIS2 / DORA /
CRA / AI Act deadline guards as additional steps — additive ;
no major bump required.

## Interdictions

This standard locks the following **MUST NOT** clauses (RFC-2119
sense) :

1. The workflow MUST NOT modify the four constituent scripts from
   within its body ; it is **purely orchestrational**. Adopter
   wishes to alter Demeter / linter / SBOM / bundle behaviour
   route through the respective script's standard (K.3 / I.3 /
   J.8 / I.6).
2. The workflow MUST NOT pass `--no-deterministic` or equivalent
   escape hatch to the bundle script. `SOURCE_DATE_EPOCH`
   determinism is a non-negotiable contract per NFR-I6-CA-005.
3. The workflow MUST NOT widen the top-level `permissions:` block
   beyond `contents: read` without a corresponding ADR amendment
   under Article XII. The workflow MUST NOT use `permissions:
   write-all` under any circumstance.
4. Adopters MUST NOT embed secrets (`secrets:` block on
   `workflow_call`) into the workflow ; none of the constituent
   scripts consume secrets, and pulling them in widens the attack
   surface unnecessarily.

## Constitutional Compliance

This standard implements (does not amend) :

- **Article III.4** (anti-hallucination) — three Q-NNN open
  questions resolved at design time via ADR-I5-CW-001..003 ; no
  inline `[NEEDS CLARIFICATION:]` markers in shipped artefacts.
- **Article V** (audit trail) — the workflow's outputs include the
  uploaded `.tgz` artefact whose `MANIFEST` carries SHA-256 + size
  for every member. The GitHub Actions run log preserves the
  invocation envelope.
- **Article VIII** (infrastructure) — single declarative YAML
  executed by GitHub Actions on `ubuntu-latest` ; no service /
  daemon / privileged ops.
- **Article XI.1** (agent-native) — Demeter / Aegis / Janus
  consume the uploaded bundle at review time. See the cross-links
  in § Consumption protocol.
- **Article XI.3** (schema-driven) — workflow inputs / outputs /
  step list have a declared schema ; no opaque LLM-generated
  content.
- **Article XI.6** (privacy / data minimisation) — Interdiction #4
  forbids `secrets:` ; the workflow handles no PII.
- **Article XII** (governance) — extensions follow
  `global/standards-lifecycle.md` SemVer rules under BDFL
  governance (Phase A) ; Themis (Phase B, T7+) inherits
  maintenance.

No constitutional amendment is required.
