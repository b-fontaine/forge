<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->
# DORA — Incident Reporting (`ai-native-rag` archetype)

> **Governance**: content-frozen at v1.0.0 under BDFL (Phase A); Themis (K.5)
> maintains in Phase B. The `[NEEDS CLARIFICATION]` marker below is a Themis
> Phase-B work item. See `.forge/standards/global/ai-act-dora-artefacts.md`.

## Grounded obligation

A major ICT-related incident must be reported to the competent authority. The
repo grounds the following figures:

- An incident-reporting obligation with a **"< 24h"** charter figure. Source:
  `docs/ARCHITECTURE-TARGET.md` §9.2 (Themis persona charter row: "Auto-check
  NIS2/DORA/CRA artifacts (incident reporting < 24h, SBOM, vuln handling)").
- DORA is recorded as applied since 17 jan 2025, with the **Register of
  Information to be submitted to the ESAs by "30 avr 2026"**. Source:
  `docs/ARCHITECTURE-TARGET.md` §10.4
  (`[source: cloudsecurityalliance.org/…, accessed 2026-04]`). See
  `roi-register.template.yaml` for the adopter-fillable RoI skeleton.

## Forge evidence surfaces

| Obligation | Forge evidence surface |
|---|---|
| Incident reported / auditable trail | I.6 audit-ledger snapshot (`.forge/scripts/compliance/bundle.sh` → `audit/audit-ledger.json`) |
| AI-interaction trail for the incident | IX.6 prompt-audit span (model/tenant/tier/tokens/latency/provider/fallback — `global/llm-gateway.md`) |

## Precise notification windows

[NEEDS CLARIFICATION: the DORA major-incident notification windows
(initial / intermediate / final deadlines) — Themis (K.5) to supply from the
official DORA regulatory text; the repo records only the generic "< 24h"
charter figure (§9.2) and the RoI 30 avr 2026 submission deadline (§10.4).]

This artefact MUST NOT invent any notification-window figure beyond the
grounded "< 24h".
