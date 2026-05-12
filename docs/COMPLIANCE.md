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
