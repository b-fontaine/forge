<!-- Audit: B.6.9 (b6-9-compliance) -->
# NIS2 — Incident Reporting (`event-driven-eu` archetype)

> **Governance**: content-frozen at v1.0.0 under BDFL (Phase A); Themis (K.5)
> maintains in Phase B. The `[NEEDS CLARIFICATION]` marker below is a Themis
> Phase-B work item. See `.forge/standards/global/nis2-dora-eda-artefacts.md`.

## Grounded obligation

A significant incident affecting the event-driven system must be reported to the
competent authority. The repo grounds the following figures **verbatim**:

- The NIS2 **reporting 24h/72h** windows. Source:
  `docs/ARCHITECTURE-TARGET.md` §10.4
  (`- **NIS2** : reporting 24h/72h [source: nis-2-directive.com, accessed 2026-04].`)
  and `docs/new-archetypes-plan.md` §7.1's I.6 bullet ("NIS2 reporting 24h/72h").
- An "incident reporting **< 24h**" charter figure. Source:
  `docs/ARCHITECTURE-TARGET.md` §9.2 (Themis persona charter row: "Auto-check
  NIS2/DORA/CRA artifacts (incident reporting < 24h, SBOM, vuln handling)").

The archetype's grounded compliance profile is **"NIS2 + DORA (si finance) +
CRA"** (`docs/ARCHITECTURE-TARGET.md` §10.3, `event-driven-eu` row) — i.e. NIS2
applies to this archetype.

## Operational surface (`event-driven-eu`)

The incident scenarios a deployer must be ready to report are scoped to the
archetype's grounded component stack
(`.forge/schemas/event-driven-eu/1.0.0.yaml` `components:`):

- **NATS JetStream** (event-backbone) — cluster outage, message loss, or a
  compromised stream/consumer.
- **Temporal** (orchestration) — workflow/worker failure or a stuck saga leaving
  business state partially applied.
- **Postgres** (event-store) — breach, corruption, or unavailability of the
  append-only event store / projections.

A significant incident affecting any of these — availability, integrity, or
confidentiality — is the trigger for the NIS2 reporting obligation. Use the
adopter-fillable `incident-report.template.yaml` to draft the notification.

## Forge evidence surfaces

Each reporting duty is linked to the concrete Forge surface that produces the
evidence for it:

| Obligation | Forge evidence surface |
|---|---|
| Incident detected + auditable trail | I.6 audit-ledger snapshot (`.forge/scripts/compliance/bundle.sh` → `audit/audit-ledger.json`) |
| Operational telemetry for the incident | IX.4 Rust OTel tracing spans (SigNoz / OBI / Coroot — the schema `observability` component; every request handler creates a root span, downstream calls propagate context) |
| Supply-chain transparency for the affected components | CycloneDX SBOM (`bin/forge-sbom.sh` over the Rust `Cargo.lock`; rides the I.6 bundle `sbom/sbom.cdx.json` member) |

## Precise reporting stages

[NEEDS CLARIFICATION: the NIS2 reporting stages (early warning / incident
notification / final report) mapping onto the grounded 24h/72h windows, and the
CSIRT / competent-authority routing — Themis (K.5) to supply from the official
NIS2 text; the repo grounds only the "24h/72h" (§10.4) and "< 24h" (§9.2)
figures.]

This artefact MUST NOT invent any reporting-window figure beyond the grounded
"24h/72h" and "< 24h".
