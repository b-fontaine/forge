# Standard — NIS2 + DORA Event-Driven Regulatory Artefacts

<!-- Audit: B.6.9 (b6-9-compliance) -->
<!-- Trigger: nis2, dora, event-driven-eu, compliance, regulatory, incident-reporting, roi, sbom, supply-chain, themis -->

```yaml
version: 1.0.0
last_reviewed: 2026-07-10
expires_at: 2027-07-10
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "Governs the content schema + Phase A/B governance of the EU NIS2 + DORA regulatory artefacts + the SBOM-wiring posture under .forge/compliance/nis2/ (+ the DORA RoI helper) for the event-driven-eu archetype."
```

## Purpose & EU regulatory scope

This standard governs the **regulatory content artefacts** the `event-driven-eu`
archetype carries — their content schema and their Phase A/B governance posture.
It is a sibling of, and distinct from, the I.6 standard
`compliance-artefacts-bundle.md` (which governs the **bundle mechanism**) and the
B.7.5/B.7.8 standard `ai-act-dora-artefacts.md` (which governs the
`ai-native-rag` archetype's AI Act + DORA content). One standard, one archetype,
one concern (Article XII / `standards-lifecycle.md`).

The archetype's grounded compliance profile is **"NIS2 + DORA (si finance) +
CRA"** (`docs/ARCHITECTURE-TARGET.md` §10.3, `event-driven-eu` row). Its primary
EU regulatory surface is **NIS2** (critical-infrastructure incident reporting)
and **DORA** (financial-sector operational resilience). The artefacts capture
only what the repo grounds:

- **NIS2** — a significant-incident reporting obligation with the grounded
  reporting windows **"24h/72h"** (`ARCHITECTURE-TARGET.md` §10.4 ;
  `new-archetypes-plan.md` §7.1 I.6 bullet) and the "< 24h" charter figure
  (§9.2), scoped to the archetype's NATS JetStream / Temporal / Postgres
  operational surface ; plus **supply-chain transparency** via the SBOM.
- **DORA** — the Register of Information (RoI) ESA submission (deadline
  "30 avr 2026", §10.4), compiled for the archetype's ICT third-party stack via
  the `dora-roi-helper.sh` submission helper (which drives the b7-5 DORA RoI
  base — it does not fork it).

**SBOM auto-generation wiring.** `event-driven-eu` is a Rust backend, so its
CycloneDX SBOM auto-generation rides the **existing** `bin/forge-sbom.sh`
(which parses the Rust `Cargo.lock` into a CycloneDX 1.5 SBOM) and the I.6
bundle's `sbom/sbom.cdx.json` member — the same mechanism every other archetype
uses. This standard does NOT introduce a new SBOM generator (the brief: "wire
the same mechanism in, don't reinvent it"). The SBOM is the NIS2
supply-chain-transparency evidence surface (see § Obligation → evidence
traceability).

**DORA** is the second-tier surface (the archetype profile qualifies it "si
finance"). **CRA** is the archetype's third named regulation but its artefacts
stay **reserved** (`.forge/compliance/cra/`, not shipped here — commercial-binary
territory).

## Artefact content schema

Every artefact this standard governs, its purpose, and whether its core
obligation is `satisfied` (grounded + evidence-mapped) or `deferred` (flagged
`needs-clarification` for Themis):

| Artefact | Regulation | Purpose | Status |
|---|---|---|---|
| `nis2/incident-reporting.md` | NIS2 | Grounded incident-reporting obligation (24h/72h) scoped to the NATS/Temporal/Postgres surface → evidence surfaces | satisfied (obligation) / deferred (precise stages) |
| `nis2/incident-report.template.yaml` | NIS2 | Adopter-fillable incident-notification skeleton (24h/72h) | deferred (authoritative CSIRT schema) |
| `nis2/obligations-index.yaml` | NIS2 | NIS2 obligation → evidence map (machine-readable) | satisfied (incident-reporting, supply-chain-security) / deferred (risk-management, governance) |
| `.forge/scripts/compliance/dora-roi-helper.sh` | DORA | RoI submission helper — emits the ICT third-party register for the event stack, driving the b7-5 RoI base | deferred (authoritative ESA field schema) |

The `obligations-index.yaml` file is valid YAML with `schema_version`,
`regulation`, and an `obligations:` list ; each item carries `id`, `title`,
`status` (`satisfied` | `needs-clarification` | `deployer-assessed`),
`satisfied_by` (list, possibly empty), and an optional `source`.

## Obligation → evidence traceability

A `satisfied` obligation MUST name the concrete Forge surface that produces its
evidence. The grounded mappings:

| Obligation | Forge evidence surface |
|---|---|
| NIS2 incident-reporting trail | I.6 audit-ledger snapshot (`bundle.sh` → `audit/audit-ledger.json`) |
| NIS2 incident operational telemetry | IX.4 Rust OTel tracing spans (SigNoz / OBI / Coroot — the schema `observability` component) |
| NIS2 supply-chain transparency | CycloneDX SBOM (`bin/forge-sbom.sh` over the Rust `Cargo.lock` ; I.6 bundle `sbom/sbom.cdx.json` member) |
| DORA Register of Information | `dora-roi-helper.sh` output (drives `dora/roi-register.template.yaml`) |

The artefacts **LINK** to these grounded surfaces (the Temporal orchestration of
Article VIII.2, the Rust `tracing` OTel spans of Article IX.4, the J.8.d SBOM) ;
they do not re-implement them.

## Governance — two phases (BDFL → Themis)

Mirrors `compliance-tiers.md` § "Governance — two phases" and
`ai-act-dora-artefacts.md`.

- **Phase A — Interim (now)**: the artefacts are **content-frozen at v1.0.0
  under BDFL** (per `GOVERNANCE.md`). Edits follow `standards-lifecycle.md`
  SemVer with a REVIEW.md entry.
- **Phase B — Themis (K.5)**: the artefacts become **Themis-maintained** (the EU
  compliance officer, shipped by `k5-themis`) on a rolling cadence. Themis
  supplies the deferred legal specifics and keeps the regulatory-deadline
  calendar current.

Every `[NEEDS CLARIFICATION]` marker in the artefacts is a **Themis Phase-B work
item**, NOT a framework defect. The framework deliberately defers the precise
legal determinations (the named NIS2 reporting stages, the authoritative CSIRT
notification schema, the authoritative DORA RoI field schema) rather than
inventing them (Article III.4).

## Consumption protocol

The NIS2 artefacts ride the **I.6 hand-off bundle**. Once `bundle.sh` collects
them, they appear in the `.tgz` under `regulatory/nis2/<member>`. An auditor
extracts the bundle and reads `regulatory/nis2/` to inspect the NIS2 posture.
See `compliance-artefacts-bundle.md` (the bundle contract, bumped to **v1.2.0**
by this change) for the bundle mechanics and the determinism guarantee.

The DORA RoI submission helper is run on demand:

```bash
bash .forge/scripts/compliance/dora-roi-helper.sh --target $(pwd) --output roi.yaml
```

It reads the b7-5 `.forge/compliance/dora/roi-register.template.yaml` base and
emits an RoI skeleton enumerating the archetype's ICT third-party providers
(NATS JetStream / Temporal / Postgres), which the adopter fills and submits per
their competent authority's process.

## Interdictions

This standard locks the following **MUST NOT** clauses (RFC-2119 sense):

1. Authors and Themis MUST NOT fabricate a NIS2 / DORA article number, recital,
   or precise deadline that is absent from the repo's cited grounded sources —
   they MUST flag `[NEEDS CLARIFICATION]` instead (Article III.4). The
   `b6-9.test.sh` `_test_b69_030` negative-grep guard is the deterministic
   backstop.
2. An author MUST NOT mark an obligation `satisfied` in
   `nis2/obligations-index.yaml` without naming a concrete Forge evidence
   surface in `satisfied_by`.
3. This change MUST NOT introduce a new SBOM generator — event-driven-eu SBOM
   generation MUST ride the existing `bin/forge-sbom.sh` + the I.6 bundle
   `sbom/sbom.cdx.json` member.
4. The DORA RoI helper MUST NOT fork or mutate the b7-5
   `dora/roi-register.template.yaml` base — it reads (drives) it and emits a
   specialised skeleton.
5. Once Themis (K.5) maintains these artefacts, an author MUST NOT modify their
   frozen content outside the Themis Phase-B cadence, except via an explicit
   BDFL Phase-A amendment with a REVIEW.md entry.

## Themis cross-link

The Phase-B maintainer is **Themis (K.5, compliance officer)** — the agent that
"Auto-check[s] NIS2/DORA/CRA artifacts (incident reporting < 24h, SBOM, vuln
handling)" (`docs/ARCHITECTURE-TARGET.md` §9.2 ; `.claude/agents/themis.md`).
Themis already carries the NIS2 / DORA / CRA / AI Act regulatory-deadline
calendar verbatim (`bin/forge-review-standards.sh`, shipped by `k5-themis`).
This brick ships the frozen v1.0.0 artefacts Themis maintains on a rolling
cadence ; the layout is forward-stable so the reserved CRA sibling drops in
additively.

## Constitutional Compliance

This standard implements (does not amend):

- **Article III.4** (anti-hallucination) — every regulatory specific is
  grounded-or-deferred; the negative-grep guard (`b6-9.test.sh`
  `_test_b69_030`) is the deterministic backstop.
- **Article V** (audit trail) — every artefact carries the
  `B.6.9 (b6-9-compliance)` audit anchor; the I.6 bundle-contract amendment
  (1.1.0 → 1.2.0) is recorded in REVIEW.md.
- **Article VIII.2** (workflow orchestration) — the artefacts LINK to the
  archetype's grounded Temporal orchestration; they do not re-implement it.
- **Article IX.4** (Rust observability) — the incident evidence surface is the
  Rust `tracing` OTel spans; the artefacts LINK to them.
- **Article XII** (governance) — content schema + Phase A/B governance per
  `standards-lifecycle.md`; the bundle contract extension follows the
  `compliance-artefacts-bundle.md` SemVer (additive = minor); REVIEW.md
  append-only. No amendment.

No constitutional amendment is required.
