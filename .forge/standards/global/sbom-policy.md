# Standard — SBOM Policy

<!-- Audit: J.8 (j8-janus-rules, FR-J8-080) -->
<!-- Trigger: sbom, supply-chain, nis2, dora, cra, cyclonedx, software-bill-of-materials -->

## Purpose & EU compliance rationale

Forge ships a CycloneDX 1.5 Software Bill of Materials (SBOM)
generator (`bin/forge-sbom.sh`) so adopters in regulated EU
sectors can satisfy the supply-chain transparency requirements
of :

- **NIS2** (Directive (EU) 2022/2555) — Article 21 risk-management
  measures require visibility into supply-chain dependencies.
- **DORA** (Regulation (EU) 2022/2554) — financial-sector ICT
  third-party risk regime mandates an inventory of critical ICT
  components.
- **CRA** (Cyber Resilience Act, Regulation (EU) 2024/2847) —
  Article 13 mandates SBOM availability for products with digital
  elements placed on the EU market.

The Forge SBOM is the **first-line baseline** : it lists every
locked dependency the scaffolded project carries. Adopters who
need richer attestation (license enrichment, vulnerability
cross-refs, transparency-log signing) layer their preferred
upstream tooling on top of this baseline.

## Format choice — CycloneDX 1.5 over SPDX 2.3

Forge picks **CycloneDX 1.5** as the canonical SBOM format.
Rationale :

- CycloneDX is governed by **OWASP**, EU-friendly governance
  with no single-jurisdiction copyright concentration.
- CycloneDX 1.5 has first-class support for `pkg:` Package URLs
  (purl) — the de-facto standard for component identification
  across ecosystems (Cargo, npm, pub, maven, pypi, ...).
- CycloneDX 1.5 ships a stable JSON Schema that the Forge
  validator can pin against (out of scope here ; future J.8
  extension may add `cyclonedx-cli validate` as an optional CI
  step).
- SPDX 2.3 is technically equivalent for the basic component
  inventory but its license-expression model is heavier than the
  Forge baseline needs.

The format choice MAY be revisited every 12 months per
`global/standards-lifecycle.md`. As of v0.4.0, the EU NIS2
regulator's published guidance (2024) cites CycloneDX as one of
two acceptable canonical formats ; SPDX is the other.

## Regeneration cadence

The SBOM is regenerated :

- **Every release** : the Forge `forge-ci.yml` `sbom` job
  produces a fresh `sbom.cdx.json` for `examples/forge-fsm-example/`
  on every push to `main` and every PR.
- **On demand** : adopters run `bash bin/forge-sbom.sh
  --target <their-project-tree>` to refresh the SBOM at any point
  (e.g. before a customer audit, after a dependency bump).
- **Reproducibly** : when `SOURCE_DATE_EPOCH` is exported, two
  consecutive runs against the same lockfiles produce
  byte-identical output (FR-J8-075). This is the canonical pattern
  for reproducible builds across the EU regulator
  recommendations + the Reproducible Builds project.

## Out-of-scope (for this change)

- **SBOM signing** (e.g. Sigstore cosign, in-toto) — adopter
  concern, deferred to a future J.8 extension.
- **Transparency-log upload** (Rekor, Bundeswebkonomy SBOM hub) —
  same.
- **Vulnerability cross-references** (NVD CVE matching, OSV
  enrichment) — adopters use upstream tooling
  (`grype`, `osv-scanner`) on the generated baseline.
- **License compliance enrichment** (SPDX expression matching) —
  same.
- **CycloneDX 1.5 schema validation** (`cyclonedx-cli validate`)
  — optional pre-deploy gate ; not bundled here. The Forge
  baseline is **schema-correct by construction** (handcrafted
  per the Context7-verified mandatory fields).

These items are noted here so the conversation about extending
SBOM scope is grounded in what's already shipped vs what isn't.
Future J.8 extensions or a successor change MAY bring them in.
