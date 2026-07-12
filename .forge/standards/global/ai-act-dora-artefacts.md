# Standard — AI Act + DORA Regulatory Artefacts

<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->
<!-- Trigger: ai-act, dora, compliance, regulatory, model-card, dataset-card, transparency, incident-reporting, themis -->

```yaml
version: 1.0.0
last_reviewed: 2026-06-22
expires_at: 2027-06-22
exception_constitutional: false
linter_rule: null
enforcement:
  ci_blocking: false
  pre_commit_hook: false
forbidden: []
rationale: "Governs the content schema + Phase A/B governance of the EU AI Act + DORA regulatory artefacts under .forge/compliance/{ai-act,dora}/ for the ai-native-rag archetype."
```

## Purpose & EU regulatory scope

This standard governs the **regulatory content artefacts** the `ai-native-rag`
archetype carries under `.forge/compliance/{ai-act,dora}/` — their content
schema and their Phase A/B governance posture. It is a sibling of, and distinct
from, the I.6 standard `compliance-artefacts-bundle.md`, which governs the
**bundle mechanism** (determinism, members, hand-off). One standard, one
concern (Article XII / `standards-lifecycle.md`).

The archetype's grounded compliance profile is **"RGPD + AI Act + DORA si
finance"** (`docs/ARCHITECTURE-TARGET.md` §10.3). The artefacts capture only
what the repo grounds:

- **AI Act** — the **transparency-obligation posture** (`global/llm-gateway.md`
  § "Prompt audit & observability": "AI Act transparency obligations — B.7.5
  territory").
- **DORA** — a major-ICT-incident reporting obligation (the "< 24h" charter
  figure, §9.2) and the Register of Information deadline (§10.4).

NIS2 (`event-driven-eu`) shipped separately via `b6-9-compliance` (B.6.9) under
`.forge/compliance/nis2/` + `global/nis2-dora-eda-artefacts.md`; this standard
stays scoped to the `ai-native-rag` AI Act + DORA content. CRA
(commercial-binary) remains **reserved** — the `.forge/compliance/cra/` sibling
is deliberately absent.

## Artefact content schema

Every member of `.forge/compliance/{ai-act,dora}/`, its purpose, and whether
its core obligation is `satisfied` (grounded + evidence-mapped) or `deferred`
(flagged `needs-clarification` for Themis):

| Member | Purpose | Status |
|---|---|---|
| `ai-act/risk-classification.md` | Grounded transparency posture + deployer escalation triggers | satisfied (posture) / deferred (precise mapping) |
| `ai-act/transparency-obligations.md` | Transparency duties → Forge evidence surfaces | satisfied |
| `ai-act/model-card.template.md` | Adopter-fillable model-card skeleton | deferred (legal trigger) |
| `ai-act/dataset-card.template.md` | Adopter-fillable dataset-card skeleton | deferred (legal trigger) |
| `ai-act/obligations-index.yaml` | AI Act obligation → evidence map (machine-readable) | satisfied (transparency, logging) / deferred (conformity, post-market) |
| `dora/incident-reporting.md` | Grounded incident obligation → evidence surfaces | satisfied (obligation) / deferred (precise windows) |
| `dora/roi-register.template.yaml` | Adopter-fillable Register-of-Information skeleton | deferred (authoritative schema) |
| `dora/obligations-index.yaml` | DORA obligation → evidence map (machine-readable) | satisfied (incident-reporting, RoI) / deferred (pillars) |

The `obligations-index.yaml` files are valid YAML with `schema_version`,
`regulation`, and an `obligations:` list; each item carries `id`, `title`,
`status` (`satisfied` | `needs-clarification` | `deployer-assessed`),
`satisfied_by` (list, possibly empty), and an optional `source`.

## Obligation → evidence traceability

A `satisfied` obligation MUST name the concrete Forge surface that produces its
evidence. The grounded mappings:

| Obligation | Forge evidence surface |
|---|---|
| AI transparency — user informed of AI interaction | Qwik `fallbackUsed` indicator (`b7-2-scaffolder` FR-B7-2-020) |
| AI logging / record-keeping | IX.6 prompt-audit record (`global/llm-gateway.md`) |
| DORA incident-reporting trail | I.6 audit-ledger snapshot + IX.6 prompt-audit span |
| DORA Register of Information | `dora/roi-register.template.yaml` |

The artefacts **LINK** to these scaffolded runtime surfaces; they do not
re-implement them (Article IX.6 / XI.5 / XI.6).

## Governance — two phases (BDFL → Themis)

Mirrors `compliance-tiers.md` § "Governance — two phases".

- **Phase A — Interim (now → Themis ships, ~T7+)**: the artefacts are
  **content-frozen at v1.0.0 under BDFL** (per `GOVERNANCE.md`). Edits follow
  `standards-lifecycle.md` SemVer with a REVIEW.md entry.
- **Phase B — Themis (T7+)**: the artefacts become **Themis-maintained** (K.5,
  compliance officer) on a rolling cadence. Themis supplies the deferred legal
  specifics.

Every `[NEEDS CLARIFICATION]` marker in the artefacts is a **Themis Phase-B
work item**, NOT a framework defect. The framework deliberately defers the
precise legal determinations (risk-category mapping, finance high-risk
determination, bias-evaluation legal trigger, DORA notification windows,
authoritative RoI schema) rather than inventing them (Article III.4).

## Consumption protocol

The artefacts ride the **I.6 hand-off bundle**. Once `bundle.sh` collects them,
they appear in the `.tgz` under the `regulatory/` subdirectory:
`regulatory/ai-act/<member>` and `regulatory/dora/<member>`. An auditor
extracts the bundle and reads `regulatory/ai-act/` and `regulatory/dora/` to
inspect each regulation. See `compliance-artefacts-bundle.md` (the bundle
contract, bumped to v1.1.0 by this change) for the bundle mechanics and the
determinism guarantee.

## Interdictions

This standard locks the following **MUST NOT** clauses (RFC-2119 sense):

1. Authors and Themis MUST NOT fabricate an AI Act / DORA article number,
   recital, or precise deadline that is absent from the repo's cited grounded
   sources — they MUST flag `[NEEDS CLARIFICATION]` instead (Article III.4).
2. An author MUST NOT mark an obligation `satisfied` in an
   `obligations-index.yaml` without naming a concrete Forge evidence surface in
   `satisfied_by`.
3. Once Themis (K.5) ships, an author MUST NOT modify the artefacts' frozen
   content outside the Themis Phase-B cadence, except via an explicit BDFL
   Phase-A amendment with a REVIEW.md entry.
4. An adopter MUST NOT treat the deferred `[NEEDS CLARIFICATION]` slots as legal
   advice resolved — they remain open determinations for the deployer + counsel
   until Themis supplies them.

## Themis cross-link

The Phase-B maintainer is **Themis (K.5, compliance officer)** — the agent that
"Auto-check[s] NIS2/DORA/CRA artifacts (incident reporting < 24h, SBOM, vuln
handling)" (`docs/ARCHITECTURE-TARGET.md` §9.2). This brick ships the frozen
v1.0.0 artefacts Themis Phase B will maintain on a rolling cadence; the layout
is forward-stable so Themis drops in additively (NIS2 shipped via
`b6-9-compliance`; the CRA sibling remains reserved).

## Constitutional Compliance

This standard implements (does not amend):

- **Article III.4** (anti-hallucination) — every regulatory specific is
  grounded-or-deferred; the negative-grep guard (`b7-5.test.sh`
  `_test_b75_030`) is the deterministic backstop.
- **Article V** (audit trail) — every artefact carries the
  `B.7.5+B.7.8 (b7-5-ai-act)` audit anchor; the I.6 amendment is recorded in
  REVIEW.md.
- **Article IX.6 / XI.5 / XI.6** — the artefacts LINK to scaffolded runtime
  evidence (prompt-audit, fallback indicator); they do not re-implement it.
- **Article XI.3** (schema-driven) — the `obligations-index.yaml` files are
  machine-readable schema, not opaque prose.
- **Article XII** (governance) — content schema + Phase A/B governance per
  `standards-lifecycle.md`; REVIEW.md append-only. No amendment.

No constitutional amendment is required.
