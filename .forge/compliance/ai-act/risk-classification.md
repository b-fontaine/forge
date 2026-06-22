<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->
# AI Act — Risk Classification (`ai-native-rag` archetype)

> **Governance**: content-frozen at v1.0.0 under BDFL (Phase A). The
> `[NEEDS CLARIFICATION]` markers below are **Themis (K.5) Phase-B work items**
> — they are deferred legal determinations, NOT framework defects. See
> `.forge/standards/global/ai-act-dora-artefacts.md`.

## Grounded posture

The `ai-native-rag` archetype carries EU AI Act **transparency obligations**.

- The archetype's compliance profile is **"RGPD + AI Act + DORA si finance"**.
  Source: `docs/ARCHITECTURE-TARGET.md` §10.3 (profile table, `ai-native-rag`
  row) — i.e. the AI Act applies to this archetype.
- Forge's prompt-audit records are the evidence trail for "the AI Act
  **transparency obligations** (B.7.5 territory)". Source:
  `.forge/standards/global/llm-gateway.md` § "Prompt audit & observability".

What the repo grounds is therefore the **transparency-obligation posture** (the
obligation class associated with interactive AI systems): users are informed
they interact with an AI system and the AI output is identifiable. The concrete
evidence surfaces are mapped in `transparency-obligations.md` and
`obligations-index.yaml`.

## Escalation triggers the DEPLOYER must self-assess (with counsel)

The framework grounds the transparency posture but CANNOT determine, for a
given deployment, whether a stricter obligation class applies. The deployer
MUST self-assess the following escalation triggers, with legal counsel:

- Deployment in a **regulated / finance** context (the §10.3 profile records
  "DORA si finance" for this archetype — a finance deployment is a sensitive
  sector).
- Use for a **decision that affects individuals' rights** or access to services.
- Use in any context the deployer's counsel flags as elevated-risk.

A trigger firing means the deployer escalates to the precise risk-category
determination below — which the framework does not make.

## Precise risk-category mapping

[NEEDS CLARIFICATION: AI Act risk-category mapping (prohibited / high-risk /
limited-risk / minimal) and the corresponding citations — Themis (K.5) to supply
from the official AI Act text; not in the repo's grounded sources.]

[NEEDS CLARIFICATION: whether a finance-sector RAG deployment is AI-Act high-risk
— deployer + counsel determination; Themis (K.5) to track the regulatory
position; not framework-determinable.]
