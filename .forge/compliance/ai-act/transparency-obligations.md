<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->
# AI Act — Transparency Obligations (`ai-native-rag` archetype)

> **Governance**: content-frozen at v1.0.0 under BDFL (Phase A); Themis (K.5)
> maintains in Phase B. See `.forge/standards/global/ai-act-dora-artefacts.md`.

## Obligations

The transparency-obligation posture grounded in `risk-classification.md`
triggers the following duties for an `ai-native-rag` deployment (stated as the
transparency-obligation class, NOT cited to a specific provision):

- **Users are informed they interact with an AI system.** A person interacting
  with the RAG system is made aware it is an AI system, not a human.
- **AI output is identifiable.** Content produced or assisted by the AI system
  is distinguishable from non-AI content (e.g. the UI surfaces when a response
  was AI-generated and when it fell back to a non-AI path).

## Forge evidence surfaces

Each transparency duty is linked to the concrete Forge surface that produces
the evidence for it:

| Obligation | Forge evidence surface |
|---|---|
| User informed they interact with an AI system | Qwik UI shell + `fallbackUsed` indicator (`b7-2-scaffolder` FR-B7-2-020) — the UI distinguishes an AI response from a non-AI fallback response |
| AI interaction logged / auditable | IX.6 prompt-audit record (model, tenant, tier, token counts, latency, provider, fallback flag — `.forge/standards/global/llm-gateway.md` § "Prompt audit & observability") |

These two surfaces are the grounded, satisfied obligation classes recorded in
`obligations-index.yaml`. Obligation classes the repo does not ground
(conformity assessment, CE marking, post-market monitoring) are flagged
`needs-clarification` in that index, NOT asserted here.
