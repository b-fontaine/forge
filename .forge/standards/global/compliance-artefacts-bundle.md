# Standard — Compliance Artefacts Bundle

<!-- Audit: I.6 (i6-compliance-artefacts) -->
<!-- Trigger: compliance, bundle, auditor, dpa, audit-ledger, nis2, dora, cra, ai-act, regulatory-handoff -->

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
rationale: "Documents the deterministic .tgz hand-off bundle for EU regulator counter-parties."
```

## Purpose & EU compliance rationale

Forge ships a regulatory hand-off bundle generator
(`.forge/scripts/compliance/bundle.sh`) so adopters can deliver a
single, deterministic, byte-stable archive of every
compliance-relevant artefact the framework carries to internal
audit, external auditors, or regulator counter-parties.

The bundle is the **first-line baseline** for EU regulatory
hand-offs : it lists the tier posture, the DPA attestation
template, an audit-trail snapshot, and the CycloneDX SBOM. The
content is sufficient to satisfy first-pass review under :

- **NIS2** (Directive (EU) 2022/2555) Article 21 — risk-management
  measures + supply-chain transparency.
- **DORA** (Regulation (EU) 2022/2554) — ICT third-party risk
  evidence + audit-trail surface.
- **CRA** (Cyber Resilience Act, Regulation (EU) 2024/2847)
  Article 13 — SBOM availability for products with digital
  elements placed on the EU market.
- **AI Act** (Regulation (EU) 2024/1689) — when the project carries
  AI-system components, the audit trail records the design
  decisions reviewed by Aegis + Demeter.

Adopters needing richer attestation (license enrichment,
vulnerability cross-refs, transparency-log signing, regulatory
deadline tracking) layer their preferred upstream tooling on top
of this baseline. The full NIS2 / DORA / CRA / AI Act regulatory
deadline artefacts under `.forge/compliance/{nis2,dora,cra,ai-act}/`
require **Themis** (K.5, T7+) to maintain ; the bundle schema in
this v1.0.0 is **forward-stable** so Themis-territory artefacts
drop into the same layout without a breaking change (see § Forward
compatibility below).

## Bundle content schema

A successful bundle invocation produces a single `.tgz` file
(default name `forge-compliance-artefacts.tgz`) containing exactly
the following six members at the exact relative paths inside the
archive :

| Member path                              | Source                                                                 | Schema                                                                                                       |
|------------------------------------------|------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| `MANIFEST`                               | Script-generated                                                       | Plain text, sorted by member path, `<sha256-hex>  <size-bytes>  <member-path>\n` per line                    |
| `tier-matrix/compliance-tiers.md`        | Copy of `.forge/standards/global/compliance-tiers.md` (I.2)            | UTF-8 Markdown, byte-identical to source                                                                     |
| `templates/forge-dpa-declared.template`  | Copy of `.forge/templates/compliance/forge-dpa-declared.template` (I.6)| UTF-8 plain text, K.3 ADR-K3-002 DPA ledger format                                                           |
| `audit/audit-ledger.json`                | Script-generated snapshot                                              | CycloneDX-style JSON envelope, `schema_version: 1.0.0`, five top-level keys                                  |
| `audit/audit-ledger.md`                  | Script-generated snapshot                                              | UTF-8 Markdown, H1 + 3 H2 sections (`Archived changes`, `Standards reviews`, `Active rule catalogues`)       |
| `sbom/sbom.cdx.json`                     | Output of `bin/forge-sbom.sh` (J.8.d)                                  | CycloneDX 1.5 JSON ; minimal envelope when no lockfile present (FR-I6-CA-019)                                |

Adding or removing a member is a **SemVer minor bump** on this
standard. Renaming an existing member is a **SemVer major bump**
because downstream consumers (I.5 future workflow, auditor
tooling) reference paths by string.

The `audit/audit-ledger.json` schema :

```json
{
  "schema_version": "1.0.0",
  "generated_at": "<ISO-8601 UTC>",
  "framework_version": "<contents of VERSION file>",
  "archived_changes": [
    {"name": "...", "archived": "...", "parent_audit_items": ["..."]}
  ],
  "standards_reviews": [
    {"date": "...", "title": "..."}
  ],
  "active_rule_catalogues": ["K3-RULE-001..006", "J8-RULE-001..003"]
}
```

Top-level keys are stable across the v1.0.x line. Array contents
(`archived_changes`, `standards_reviews`) grow monotonically as
Forge ships new changes ; `active_rule_catalogues` evolves with
new K3-RULE / J8-RULE catalogues as future changes ship them.

## Determinism guarantee

When the `SOURCE_DATE_EPOCH` environment variable is set
(POSIX-standard integer Unix timestamp), two consecutive bundle
invocations against the same target tree MUST produce
byte-identical `.tgz` outputs.

The recipe :

- Per-member tar `mtime` set to `SOURCE_DATE_EPOCH`.
- Per-member tar `uid`, `gid`, `uname`, `gname` normalised to `0` /
  `""`.
- Per-member tar `mode` pinned to `0o644`.
- Gzip header `mtime` field set to `SOURCE_DATE_EPOCH` (Python
  `gzip.GzipFile(mtime=...)` two-step idiom).
- Bundle members emitted in lexicographic order by path.
- JSON members serialised with `sort_keys=True`, `indent=2`,
  trailing newline.
- `MANIFEST` lines sorted lexicographically by member path.

This recipe mirrors the precedent set by
[`global/sbom-policy.md` § Regeneration cadence](sbom-policy.md)
for the CycloneDX SBOM. Both surfaces share the SOURCE_DATE_EPOCH
discipline so downstream consumers compose bundles + SBOMs without
determinism drift.

Adopters verify the determinism guarantee locally via :

```bash
SOURCE_DATE_EPOCH=0 bash .forge/scripts/compliance/bundle.sh --output b1.tgz
SOURCE_DATE_EPOCH=0 bash .forge/scripts/compliance/bundle.sh --output b2.tgz
diff -q b1.tgz b2.tgz   # exits 0 if byte-identical
```

The Forge harness `.forge/scripts/tests/i6.test.sh` asserts this
invariant at L2 (`_test_i6_l2_bundle_determinism`).

## Consumption protocol

The canonical downstream consumer is the **I.5 future workflow**
`.github/workflows/forge-compliance.yml`. That workflow has **not
shipped yet** (deferred — depends on Themis maturing the regulatory
deadline artefacts). The bundle schema in this v1.0.0 is a
**forward-stable contract** : I.5 when it ships consumes the
bundle without negotiating new member paths or schema fields.

Today, adopters consume the bundle directly :

1. Run `bash .forge/scripts/compliance/bundle.sh --target $(pwd)`
   at the project root.
2. Hand `forge-compliance-artefacts.tgz` to the auditor /
   regulator counter-party.
3. Auditor extracts `tar -xzf forge-compliance-artefacts.tgz` and
   reads `MANIFEST` first to verify the six members' SHA-256
   checksums.

The bundle is consumed by Demeter (`.claude/agents/demeter.md`) at
review time : Demeter reads `audit/audit-ledger.json` when
classifying historical posture and verifying that the tier
declaration in `.forge/.forge-tier` is supported by archived
audit trail.

When Themis (K.5, T7+) ships, Themis MUST :

- Add NIS2 / DORA / CRA / AI Act regulatory deadline artefacts
  under a new `regulatory/` subdirectory inside the bundle
  (additive ; no rename of existing members).
- Bump this standard from `1.0.0` → `1.1.0` (minor) per
  `global/standards-lifecycle.md` SemVer rules.
- Update the bundle MANIFEST to include the new members.

## Regeneration cadence

The bundle is regenerated :

- **Every release** : when Forge cuts a new version, the bundle is
  produced as part of the release artefacts (deferred until I.5 +
  `forge-compliance.yml` ship).
- **On demand** : adopters run `bash
  .forge/scripts/compliance/bundle.sh --target <project-tree>` at
  any point (e.g. before a customer audit, after a dependency
  bump, after a tier escalation).
- **Reproducibly** : when `SOURCE_DATE_EPOCH` is exported, two
  consecutive runs against the same source tree produce
  byte-identical output. Adopters integrating into a CI / CD
  pipeline SHOULD set `SOURCE_DATE_EPOCH` to the build's commit
  timestamp for traceability.

This cadence mirrors `global/sbom-policy.md::Regeneration cadence`
verbatim ; the bundle's recipe is the SBOM recipe scaled to a
multi-member archive.

## Interdictions

This standard locks the following **MUST NOT** clauses (RFC-2119
sense) :

1. The bundle script MUST NOT include adopter PII (personal data),
   secret material (API keys, signing keys, OAuth credentials), or
   any other privacy-class content in the bundle. The artefacts
   shipped are structural Forge metadata only — tier matrix, DPA
   template, audit-trail snapshot, SBOM. None of these contain
   adopter business data.
2. The bundle script MUST NOT introduce a `--no-deterministic`,
   `--skip-mtime-pinning`, or equivalent escape hatch that bypasses
   the determinism guarantee. Reproducible output is a
   non-negotiable contract per NFR-I6-CA-005.
3. Adopters MUST NOT add NIS2 / DORA / CRA / AI Act regulatory
   deadline artefacts to the bundle under any path before Themis
   (K.5, T7+) ships. Until then, the regulatory layer is **out of
   bundle scope** and adopters track deadlines manually per
   `docs/COMPLIANCE.md` § Cross-references. The bundle layout is
   forward-stable so Themis-territory artefacts drop in additively
   when ready.
4. The bundle MUST NOT be modified after emission. Adopters who
   need richer attestation (Sigstore signing, license enrichment,
   transparency-log upload) produce SIBLING artefacts ; they MUST
   NOT alter the canonical `forge-compliance-artefacts.tgz`.

## Forward compatibility

The bundle schema in this v1.0.0 is designed for **additive
evolution**. Future changes MAY :

- Append new member paths under new subdirectories
  (`regulatory/`, `licenses/`, `attestations/`) without renaming
  existing members.
- Extend `audit-ledger.json` with new top-level keys (each new key
  is a SemVer minor bump per RFC 7159 JSON evolution conventions).
- Add new triggers to the standards index entry without removing
  existing triggers.

Future changes MUST NOT :

- Rename or remove the six existing v1.0.0 members.
- Change the `MANIFEST` format (the `<sha256> <size> <path>` triple).
- Break the `SOURCE_DATE_EPOCH` determinism guarantee.

When Themis (K.5, T7+) ships, the schema graduates to v1.1.0
**additively** — no major bump required.

## Constitutional Compliance

This standard implements (does not amend) :

- **Article III.4** (anti-hallucination) — three Q-NNN open
  questions resolved at design time via ADR-I6-CA-001..003 ;
  no inline `[NEEDS CLARIFICATION:]` markers in shipped
  artefacts.
- **Article V** (audit trail) — the bundle IS the audit-trail
  surface for downstream regulator hand-off ; every member
  carries SHA-256 + size in `MANIFEST`.
- **Article XI.1** (agent-native) — Demeter consumes the bundle's
  `audit/audit-ledger.json` at review time. See
  `.claude/agents/demeter.md`.
- **Article XI.3** (schema-driven) — every bundle member has a
  declared schema ; no opaque LLM-generated content.
- **Article XI.6** (privacy / data minimisation) — Interdiction #1
  forbids PII / secrets in the bundle.
- **Article XII** (governance) — extensions follow
  `global/standards-lifecycle.md` SemVer rules under BDFL
  governance (Phase A) ; Themis (Phase B, T7+) inherits
  maintenance.

No constitutional amendment is required.
