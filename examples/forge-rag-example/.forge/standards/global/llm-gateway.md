# Standard — LLM gateway

<!-- Audit: B.7.3 (b7-standards) — ai-native-rag archetype. -->
<!-- Schema mapping: documents the `llm-gateway` component of -->
<!-- `.forge/schemas/ai-native-rag/1.0.0.yaml` (delivered_by: B.7.3). -->
<!-- Pattern standard — NO version pins (async-openai pin rides with -->
<!-- B.7.2-full ; baseline in .forge/research/b7-standards-verify-then-pin.md). -->

> **Status**: pattern guidance for the `ai-native-rag` archetype (T7).
> **Schema component mapping**: `llm-gateway` (`ai-native-rag/1.0.0.yaml`) ↔ this
> standard (1:1). The schema references it as `delivered_by: B.7.3`.

## Schema mapping & scope

The gateway is an **in-repo** component (maintainer decision, exploration §4 A):
a thin Rust proxy the archetype scaffolds, not an adopted external service. This
standard documents its patterns; the upstream-client version pin (`async-openai`)
is delivered by B.7.2-full.

## Proxy architecture

- A thin Rust **axum** service in the backend workspace, fronting all LLM calls.
  Application code never calls a provider SDK directly — it calls the gateway, so
  audit, budgets, tier-refusal, and the kill switch are enforced in one place.
- Upstream via an **OpenAI-compatible** HTTP client (`async-openai`), because the
  sanctioned EU providers expose OpenAI-compatible APIs. Speak Connect/HTTP to the
  gateway internally (consistent with `transport.yaml`).

## Providers

- **Mistral on Scaleway** / **vLLM (self-host, EU)** — the sanctioned providers.
- **OpenAI (direct)** — fallback for **T1 only**; forbidden at T3 (see
  *Tier-aware refusal*).
- Provider selection is configuration, not code-fork; the gateway routes by a
  tenant/tier-aware policy. BYOK (bring-your-own-key) per tenant; keys never
  committed (Article XI.6 / secrets policy).

## Tier-aware refusal

- T3 (EU-strict) **forbids** OpenAI-direct / Google Vertex / AWS Bedrock
  (CLOUD Act). The gateway MUST refuse to route to a forbidden provider at the
  active tier. This standard does **not** restate the tier matrix or the
  component eligibility rules — it REFERENCES the existing machinery:
  - `compliance-tiers.md` — T1/T2/T3 definitions + eligibility matrix.
  - `forbidden-components-rules.md` (I.3) — the `t3-forbidden-components` linter
    rule that already fails T3 builds wiring OpenAI-direct / Vertex / Bedrock.
  - `data-stewardship-rules.md` (Demeter, K.3) — dependency-jurisdiction scan.
- The **runtime** Janus refusal rules for AI archetypes (force Mistral-EU / vLLM
  at T3) are **deferred to `b7-9-janus-ai` (J.8.c)** — not defined here.

## Prompt audit & observability

- Every gateway call emits a **prompt-audit** record (wires the schema's
  `prompt-audit` phase + **Article IX.6**): model, tenant, tier, token counts
  (prompt/completion), latency, provider, and **fallback-invocation** flag.
- Redact/minimise PII before logging (XI.6). Audit records are the evidence trail
  for budgets, abuse, and the AI Act transparency obligations (B.7.5 territory).

## Budgets, kill switch & fallback / PII

- **Tenant-scoped budgets**: the gateway enforces per-tenant token/cost ceilings;
  over-budget requests degrade to the fallback, not a hard 500.
- **Kill switch**: a single config flag disables all LLM routing; the archetype
  MUST keep functioning on the non-AI fallback.
- **Article XI.5 (mandatory fallback)**: every LLM-backed feature has a defined
  non-AI fallback (e.g. RAG returns ranked source documents; see `rag-patterns.md`),
  tested with the AI mocked to fail.
- **Article XI.6 (PII)**: no PII to an external provider without explicit consent +
  DPA; minimise payloads to what the feature needs.

## Constitutional Compliance

- **XI.5 / XI.6** — fallback + PII, above.
- **IX.6** — prompt-audit token/fallback metrics, above.
- **VIII** — the gateway speaks the sanctioned transport (`transport.yaml`); it
  does not introduce a second gateway/ingress (that is Envoy, §VIII.1).
- **III.4** — provider/CLOUD-Act claims reference the existing EU standards; the
  `async-openai` baseline (`research` §1) is recorded, not pinned here.

## Out-of-scope

- **Version pins** (`async-openai`, model versions) — B.7.2-full `Cargo.toml.tmpl`,
  verify-then-pin LIVE (baseline: `research` §1 — `async-openai = "<pinned-by-B.7.2-full>"`).
- The gateway's concrete Rust implementation + templates — B.7.2-full.
- Janus AI runtime refusal rules (J.8.c) — `b7-9-janus-ai`.
- AI Act / DORA artefacts — `b7-5-ai-act` (Themis territory).
