# Forge Compliance — EU Tier Adoption Guide

> **Audit**: I.2 (`i2-compliance-tiers`, 2026-05-11). Adopter-facing
> intro to the Forge EU compliance posture. The deep contract lives
> in [`.forge/standards/global/compliance-tiers.md`](../.forge/standards/global/compliance-tiers.md)
> ; this document is the front door.

Forge codifies EU compliance as a **three-tier gradient** :

- **T1 — RGPD via DPA** : non-EU SaaS acceptable under a DPA + SCC
  envelope, residual CLOUD Act risk acknowledged.
- **T2 — Self-hostable** : EU-deployable on any K8s, technical
  control but not formally sovereign-certified.
- **T3 — EU strict** : SecNumCloud / HDS / EUCS High, 100% EU
  jurisdiction, immune to CLOUD Act.

The tiers are **structural** (the enum `[T1, T2, T3]` is locked in
[`compliance-tier.schema.json`](../.forge/schemas/compliance-tier.schema.json)
v1.0.0). The verbatim definitions live in
[`compliance-tiers.md`](../.forge/standards/global/compliance-tiers.md)
under the H2 "Tier definitions".

---

## Quick start

If you are scaffolding a new Forge project today and want EU
compliance baked in :

1. **Declare your tier** in `.forge/.forge-tier` :

   ```bash
   echo "T2" > .forge/.forge-tier
   ```

   One line, content in `{T1, T2, T3}`, mandatory trailing
   newline. `T2` is the most common choice for greenfield projects
   (self-hostable on any EU K8s — no SecNumCloud commitment yet).

2. **Run Demeter** at PR time :

   ```bash
   bash bin/forge-demeter-scan.sh --target $(pwd) --tier T2
   ```

   Exit code 0 = CLEARED ; exit 3 = BLOCKED on a Critical / High
   finding ; exit 2 = no lockfile detected. See the
   [Demeter persona](../.claude/agents/demeter.md) for the rule
   catalogue.

3. **Iterate** : Demeter flags US-jurisdiction dependencies at
   T2 severity High and at T3 severity Critical. Replace the
   flagged dependency or formally downgrade the tier (an explicit
   `.forge/.forge-tier` edit with audit trail).

That is the minimum-viable adoption. Adopters with regulated
workloads at T1 (RGPD via DPA) add a
`.forge/.forge-dpa-declared` ledger to declare their DPA
attestation — see "Full adoption" in the standard.

---

## Tier picker

| If your project ...                                              | Pick    |
|------------------------------------------------------------------|---------|
| Uses Firebase, Datadog, Auth0, AWS managed services, or Sentry   | **T1**  |
| Self-hosts everything on EU K8s but isn't SecNumCloud-certified  | **T2**  |
| Must run 100% on EU-jurisdiction sovereign cloud (SecNumCloud)   | **T3**  |

**Decision tree** :

```
Does your data NEVER leave EU jurisdiction (even via SaaS publisher) ?
├─ YES, and you're SecNumCloud / HDS / EUCS High certified
│   → T3 (strict EU)
├─ YES, but you self-host on regular EU K8s (no formal cert)
│   → T2 (self-hostable)
└─ NO — you accept CLOUD Act residual risk under a DPA + SCC
    → T1 (RGPD via DPA)
```

When in doubt, **pick T2**. T2 is the safest default for a
greenfield Forge project : you keep EU jurisdiction without
committing to the SecNumCloud certification effort. You can
upgrade to T3 later (edit `.forge/.forge-tier`, re-run Demeter) ;
you can downgrade to T1 with an explicit ledger edit if your
business requires non-EU SaaS components.

For the verbatim tier definitions and the full 15-row component
eligibility matrix, read
[`compliance-tiers.md`](../.forge/standards/global/compliance-tiers.md).

---

## Cross-references

| Surface                                                                                                                       | What it provides                                                                |
|-------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| [`docs/ARCHITECTURE-TARGET.md` §10](ARCHITECTURE-TARGET.md)                                                                   | Narrative source : tier definitions, §10.2 component matrix, §10.3 archetypes  |
| [`.forge/schemas/compliance-tier.schema.json`](../.forge/schemas/compliance-tier.schema.json)                                  | Machine source of truth : enum + x-tier-descriptions verbatim                  |
| [`.forge/standards/global/compliance-tiers.md`](../.forge/standards/global/compliance-tiers.md)                                | This standard's authoritative human-readable contract (I.2)                    |
| [`.forge/standards/global/data-stewardship-rules.md`](../.forge/standards/global/data-stewardship-rules.md)                    | K.3 Demeter rule catalogue (K3-RULE-001..006)                                  |
| [`.claude/agents/demeter.md`](../.claude/agents/demeter.md)                                                                    | Demeter persona — data steward EU agent                                        |
| [`.forge/standards/global/janus-orchestration-rules.md`](../.forge/standards/global/janus-orchestration-rules.md)              | J.8 Janus refusal rules — T3 enforcement at scaffold time                      |
| [`.claude/agents/cross-layer-orchestrator.md`](../.claude/agents/cross-layer-orchestrator.md)                                  | Janus persona — orchestrates Step 9 security / data-stewardship pass           |
| [`bin/forge-demeter-scan.sh`](../bin/forge-demeter-scan.sh)                                                                    | Deterministic scanner : lockfile → publisher jurisdiction → severity finding   |
| [`.forge/data/cloud-act-publishers.yml`](../.forge/data/cloud-act-publishers.yml)                                              | Deny-list : US-jurisdiction publisher patterns per ecosystem                   |

For regulatory deadlines (NIS2 / DORA / CRA / AI Act), see
`docs/new-archetypes-plan.md` §7.1 line 738-742 ; the formal
artefacts land with I.6 (deferred, Themis K.5 territory T7+).

---

## Auditor hand-off bundle

> **Audit**: I.6 (`i6-compliance-artefacts`, 2026-05-12).

Forge ships a deterministic regulatory hand-off bundle generator
that packs every compliance-relevant artefact the framework carries
into a single, byte-stable `.tgz` archive. Hand it to your internal
audit team, external auditors, or regulator counter-parties without
manually re-assembling the surface each time.

### Quick start

```bash
bash .forge/scripts/compliance/bundle.sh
# → forge-compliance-artefacts.tgz at $(pwd)
```

Optional flags : `--output <path>` (default
`forge-compliance-artefacts.tgz`), `--target <dir>` (default
`$(pwd)`), `--help`/`-h`.

### Bundle members

| Member path                              | Source                                                               |
|------------------------------------------|----------------------------------------------------------------------|
| `MANIFEST`                               | Script-generated index : `<sha256>  <size>  <path>` per line, sorted |
| `tier-matrix/compliance-tiers.md`        | Copy of I.2 standard `global/compliance-tiers.md`                    |
| `templates/forge-dpa-declared.template`  | Copy of `.forge/templates/compliance/forge-dpa-declared.template`    |
| `audit/audit-ledger.json`                | Script-generated audit-trail snapshot (machine-parseable)            |
| `audit/audit-ledger.md`                  | Script-generated audit-trail snapshot (human-readable)               |
| `sbom/sbom.cdx.json`                     | Output of `bin/forge-sbom.sh` (CycloneDX 1.5 SBOM)                   |

### Determinism

When `SOURCE_DATE_EPOCH` is exported (POSIX-standard integer Unix
timestamp), two consecutive bundle invocations against the same
target tree produce **byte-identical** `.tgz` outputs. Verify
locally :

```bash
SOURCE_DATE_EPOCH=0 bash .forge/scripts/compliance/bundle.sh --output b1.tgz
SOURCE_DATE_EPOCH=0 bash .forge/scripts/compliance/bundle.sh --output b2.tgz
diff -q b1.tgz b2.tgz   # exits 0 if byte-identical (NFR-I6-CA-005)
```

The bundle script
([`.forge/scripts/compliance/bundle.sh`](../.forge/scripts/compliance/bundle.sh))
honours the same `SOURCE_DATE_EPOCH` recipe as
[`bin/forge-sbom.sh`](../bin/forge-sbom.sh) for the CycloneDX SBOM
member. The full content schema, determinism recipe, consumption
protocol, and forward-compatibility rules live in
[`compliance-artefacts-bundle.md`](../.forge/standards/global/compliance-artefacts-bundle.md).

When the project carries an archetype's regulatory artefacts (below),
the bundle additionally collects them under `regulatory/ai-act/*` +
`regulatory/dora/*` (bundle contract v1.1.0, `b7-5-ai-act`,
`ai-native-rag`) and `regulatory/nis2/*` (v1.2.0, `b6-9-compliance`,
`event-driven-eu`). They ride the bundle automatically — no extra step.

---

## Regulatory artefacts (AI Act + DORA)

> **Audit**: B.7.5 + B.7.8 (`b7-5-ai-act`, 2026-06-22).

The `ai-native-rag` archetype carries EU **AI Act** + **DORA** regulatory
artefacts under
[`.forge/compliance/ai-act/`](../.forge/compliance/ai-act/) and
[`.forge/compliance/dora/`](../.forge/compliance/dora/). They capture the
**grounded** compliance posture (the archetype profile is "RGPD + AI Act +
DORA si finance", `ARCHITECTURE-TARGET.md` §10.3) and map each grounded
obligation to the Forge runtime evidence surface that satisfies it (the IX.6
prompt-audit record + the Qwik `fallbackUsed` indicator + the I.6
audit-ledger snapshot).

| Artefact | Regulation | Purpose |
|---|---|---|
| `ai-act/risk-classification.md`       | AI Act | Grounded transparency posture + deployer escalation triggers |
| `ai-act/transparency-obligations.md`  | AI Act | Transparency duties → Forge evidence surfaces |
| `ai-act/model-card.template.md`       | AI Act | Adopter-fillable model-card skeleton |
| `ai-act/dataset-card.template.md`     | AI Act | Adopter-fillable dataset-card skeleton |
| `ai-act/obligations-index.yaml`       | AI Act | Machine-readable obligation → evidence map |
| `dora/incident-reporting.md`          | DORA   | Grounded incident-reporting obligation → evidence surfaces |
| `dora/roi-register.template.yaml`     | DORA   | Adopter-fillable Register-of-Information skeleton |
| `dora/obligations-index.yaml`         | DORA   | Machine-readable obligation → evidence map |

The content schema + Phase A/B governance are documented in the standard
[`ai-act-dora-artefacts.md`](../.forge/standards/global/ai-act-dora-artefacts.md).
The artefacts reach an auditor via the I.6 hand-off bundle's `regulatory/`
subdirectory (above).

**Themis-Phase-B governance**: the artefacts are content-frozen at v1.0.0 under
BDFL (Phase A). The precise legal determinations the repo cannot ground (AI Act
risk-category mapping, finance high-risk determination, dataset-bias legal
trigger, DORA notification windows, authoritative RoI schema) are carried as
`[NEEDS CLARIFICATION]` markers — **Themis (K.5, T7+) Phase-B work items**, not
framework defects. Forge does not invent legal specifics (Article III.4). The
NIS2 event-driven artefacts ship separately (see § Regulatory artefacts (NIS2 +
DORA event-driven) below, `b6-9-compliance`); the CRA sibling remains reserved.

---

## Regulatory artefacts (NIS2 + DORA event-driven)

> **Audit**: B.6.9 (`b6-9-compliance`, 2026-07-10).

The `event-driven-eu` archetype carries EU **NIS2** + **DORA** regulatory
artefacts. Its grounded compliance profile is "NIS2 + DORA (si finance) + CRA"
(`ARCHITECTURE-TARGET.md` §10.3). The NIS2 artefacts live under
[`.forge/compliance/nis2/`](../.forge/compliance/nis2/); the DORA Register-of-
Information submission helper is
[`.forge/scripts/compliance/dora-roi-helper.sh`](../.forge/scripts/compliance/dora-roi-helper.sh).

| Artefact | Regulation | Purpose |
|---|---|---|
| `nis2/incident-reporting.md`          | NIS2 | Grounded incident-reporting obligation (24h/72h) scoped to NATS/Temporal/Postgres → evidence surfaces |
| `nis2/incident-report.template.yaml`  | NIS2 | Adopter-fillable incident-notification skeleton (24h/72h) |
| `nis2/obligations-index.yaml`         | NIS2 | Machine-readable obligation → evidence map (incident-reporting + supply-chain SBOM) |
| `dora-roi-helper.sh`                  | DORA | RoI submission helper — emits the ICT third-party register (NATS/Temporal/Postgres) driving the b7-5 RoI base |

**SBOM CycloneDX auto-generation** for `event-driven-eu` (a Rust backend) rides
the existing [`bin/forge-sbom.sh`](../bin/forge-sbom.sh) (Rust `Cargo.lock` →
CycloneDX 1.5) + the I.6 bundle's `sbom/sbom.cdx.json` member — the same
mechanism every archetype uses (no new generator). It is the NIS2 supply-chain
transparency evidence surface.

The content schema + SBOM-wiring posture + Phase A/B governance are documented in
the standard
[`nis2-dora-eda-artefacts.md`](../.forge/standards/global/nis2-dora-eda-artefacts.md).
The NIS2 artefacts reach an auditor via the I.6 hand-off bundle's
`regulatory/nis2/` subdirectory (bundle contract v1.2.0).

**Themis-Phase-B governance**: the artefacts are content-frozen at v1.0.0 under
BDFL (Phase A). The precise legal determinations the repo cannot ground (the
named NIS2 reporting stages, the authoritative CSIRT notification schema, the
authoritative DORA RoI field schema) are carried as `[NEEDS CLARIFICATION]`
markers — **Themis (K.5) Phase-B work items**, not framework defects. The CRA
sibling remains reserved.

---

## Reusable compliance workflow

> **Audit**: I.5 (`i5-compliance-workflow`, 2026-05-12).

Forge ships a **reusable** GitHub Actions workflow at
[`.github/workflows/forge-compliance.yml`](../.github/workflows/forge-compliance.yml)
so adopter repos can gate their PRs + pushes against the framework's
EU-compliance surface with one `uses:` reference, no per-repo
orchestration boilerplate.

The workflow orchestrates the four EU-compliance checks Forge already
ships : Demeter (`bin/forge-demeter-scan.sh`), the constitution
linter incl. its I.3 ADR-I3-001 T3-Forbidden Components section
(`.forge/scripts/constitution-linter.sh`), the CycloneDX 1.5 SBOM
(`bin/forge-sbom.sh`), and the compliance artefacts bundle
(`.forge/scripts/compliance/bundle.sh`). It uploads the deterministic
`.tgz` produced by the bundle script as a CI artefact for hand-off
to auditors and regulators.

### Quick start

In your adopter repo, create a workflow that calls the reusable one :

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

Replace `<forge-repo>` with the Forge repo coordinate (e.g.
`bfontaine/forge` or your fork) and `<ref>` with a tag, branch, or
SHA (e.g. `v0.4.0`, `main`, or a commit hash).

### Tier inheritance

The `eu-tier` input is **per-call** : it is passed explicitly into
the workflow as a string. It is independent of any
`.forge/.forge-tier` ledger that may live inside the calling repo —
the workflow's I.3 linter step receives the tier via
`FORGE_EU_TIER=<eu-tier>` so it works even when the calling repo has
no ledger file (e.g. early adoption).

When a `.forge/.forge-tier` ledger IS present in the calling repo,
adopters SHOULD pass `eu-tier:` matching its content to keep the two
signals coherent. A mismatch is allowed (the per-call value wins) but
typically signals a misconfiguration adopters should resolve.

### Outputs

The workflow exposes one output `artefact-path` carrying the
relative path of the uploaded `.tgz` artefact (default
`forge-compliance-artefacts.tgz`). Adopter workflows can chain the
artefact downstream (e.g. attach it to a release, upload it to S3,
or re-sign it via Sigstore).

The full step-by-step contract, tier-scaled severity aggregation
recipe, consumption protocol, and interdictions live in
[`forge-compliance-workflow.md`](../.forge/standards/global/forge-compliance-workflow.md).

---

## Standards review cadence (Themis)

> **Audit**: K.5 (`k5-themis`, 2026-07-10).

Forge ships a **compliance officer** agent — **Themis**
([`.claude/agents/themis.md`](../.claude/agents/themis.md)) — and its
automation `forge review-standards`
([`bin/forge-review-standards.sh`](../bin/forge-review-standards.sh)).
Themis works at **repo-lifecycle-time** (ongoing, ambient), distinct
from Demeter's **scaffold-time** data-stewardship (see the Themis
persona's "Boundary — Themis vs Demeter" section).

Themis automates the 12-month standards review cadence codified in
[`standards-lifecycle.md`](../.forge/standards/global/standards-lifecycle.md)
and tracks the EU regulatory-deadline calendar.

### Quick start

```bash
bash bin/forge-review-standards.sh --target $(pwd)
# → standards-review-report.json ; exit 0 CLEARED / 1 REVIEW-DUE (WARN)
```

Optional flags : `--window <days>` (default 30), `--format json|md`,
`--output <path>`, `--bundle` (drive the I.6 bundle + emit a
regulatory-deadline summary), `--strict` (opt-in : an expired standard
forces a blocking exit 3). The default posture is **WARN-only** — a
review debt never freezes the pipeline
(`standards-lifecycle.md`: "WARN is never blocking").

### Regulatory-deadline calendar

Themis carries the NIS2 / DORA / CRA / AI Act deadlines **verbatim**
from `docs/new-archetypes-plan.md` §7.1's I.6 bullet :

- NIS2 reporting 24h/72h
- DORA RoI ESA submission Apr 30 2026
- CRA reporting Sept 11 2026, full requirements Dec 11 2027
- AI Act phases 2025–2027 by risk category

### CI cadence

The sibling workflow
[`.github/workflows/forge-standards-review.yml`](../.github/workflows/forge-standards-review.yml)
runs the cadence check monthly (`on: schedule:`) and is
`workflow_call`-invokable by adopters. It is deliberately separate from
the per-PR blocking `forge-compliance.yml` gate (Themis is
time-triggered and WARN-only). The `K5-RULE-*` catalogue + the review
cadence live in
[`standards-review-rules.md`](../.forge/standards/global/standards-review-rules.md).
