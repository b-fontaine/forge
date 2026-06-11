# Exploration — `b7-ai-native-rag` (T7)

> **Type** : research note (output `/forge:explore`, 2026-06-11)
> **Statut** : RATIFIÉE 2026-06-11 — 3 décisions arbitrées par le mainteneur (cf. §4)
> **Servira d'input à** : suite de sous-changes B.7.x (cf. §6 ci-dessous)
> **Source contexte** : `docs/new-archetypes-plan.md` §6.2 (B.7), §11 (T7), §0.11 ;
>   ARCHITECTURE-TARGET §10 (compliance T1/T2/T3) ; Constitution v2.0.0.
> **Décision amont** : maintainer 2026-06-11 — T7 démarre par B.7 (pas B.6),
>   car B.7 réutilise le substrat 2.0.0 déjà livré par B.8 (moins de net-new infra).

---

## 1. Taxonomie déjà câblée (acquis B.8)

`archetype.schema.json` enum **contient déjà** `ai-native-rag` :

> "AI-first archetype — pgvector 0.8 + LLM gateway (Mistral-EU / vLLM) + MCP
> servers + Qwik streaming UI."

⇒ B.7.1 ne touche **pas** l'enum. Il crée `.forge/schemas/ai-native-rag/1.0.0.yaml`.

Base `ai-first/schema.yaml` (v1.0.0) existe et est riche en process :
- phase `ai_brainstorm` AVANT proposal (Oracle → `ai-capability-map.md` +
  `agent-architecture.md` + `risk-matrix.md`), **gate `fallback_strategy_defined`** ;
- `ai_fallback_required: true` (toute feature IA doit avoir un fallback non-IA) ;
- `pii_handling: explicit_consent_required` ; `token_budget_documented: true` ;
- `non_determinism_testing: snapshot + property_based`.

⇒ B.7.1 = `extends: ai-first` + ajout phases `embeddings-pipeline` (avant design)
et `prompt-audit` (gate) per §6.2 B.7.1. La discipline AI-First est héritée, pas
réinventée.

## 2. Verify-then-pin — dépendances externes risquées (Context7, 2026-06-11)

| Composant | Signal Context7 | Verdict faisabilité | Pin |
|---|---|---|---|
| **MCP Rust SDK `rmcp`** | `/modelcontextprotocol/rust-sdk`, High rep, 144 snippets. README live épingle `rmcp = { version = "0.16.0", features = ["server"] }`. Index Context7 snapshot = `v0_5_0` → **DRIFT de version**. Transport HTTP axum-natif `StreamableHttpService` + stdio ; macros `#[tool]`/`#[tool_router]` ; support OAuth (`AuthClient`). | 🟢 GREEN — SDK officiel, axum-natif (flagship déjà axum), OIDC-ready. | ⛔ **NE PAS figer ici.** verify-then-pin LIVE à B.7.2/standards (0.16.0 vs 0.5.0 à confirmer `cargo add`). |
| **pgvector (extension)** | `/pgvector/pgvector`, High rep. Latest **0.8.2 (2026-02-25)**. HNSW cosine `vector_cosine_ops` confirmé ; PG18 supporté ; v0.9 **n'existe pas**. | 🟢 GREEN — déjà livré flagship B.8.5 (`pgvector/pgvector:0.8.2-pg17`). | Réutilise pin B.8.5. |
| **pgvector crate (Rust)** | Côté Rust = crate `pgvector` + feature `sqlx`. Version crate non confirmée cette session. | 🟡 À vérifier | verify-then-pin LIVE B.7.2. |
| **LLM gateway client** | Mistral-Scaleway / vLLM (OpenAI-compatible HTTP). Pas de lib figée. | 🟡 Décision A (cf. §4) | post-arbitrage. |
| **Qwik streaming** | SSE / WebTransport — déjà livré B.8.9 (Qwik City). | 🟢 réutilise B.8.9 | — |

> ⚠️ Leçon coroot/Q-004 institutionnalisée : aucun pin de version n'est figé
> depuis une note d'exploration. Tous les pins ci-dessus sont des *candidats* à
> confirmer LIVE (`cargo add` / `docker manifest inspect` / pub.dev) au moment
> de l'implémentation, attrapés par les fixtures L2 du harness.

## 3. Leverage B.8 — ce qui est DÉJÀ là (substrat 2.0.0)

| Brique B.7 | Source déjà livrée | Reste à faire |
|---|---|---|
| Postgres + pgvector HNSW | B.8.5 (`pgvector:0.8.2-pg17`) | indexes HNSW + crate Rust |
| Orchestration Temporal (Rust) | B8O (`temporalio-sdk 0.4.0`, DBOS annulé Rust) | workers RAG (activity-only, SDK pré-alpha) |
| Qwik web surface | B.8.9 (Qwik City + Connect-ES v2) | streaming SSE/WebTransport |
| Identité OIDC | B.8.7 Zitadel + B.8.12 Envoy SecurityPolicy JWT | MCP OAuth → même provider |
| Transport Connect | B.8.6 (connectrpc 0.6.x) | endpoints RAG |
| OTel app SDK | `t5-otel-app` (Rust + Flutter) | spans embeddings/LLM/prompt-audit |
| Compliance bundle | I.5/I.6 (forward-stable AI-Act/DORA) | artefacts Themis K.5 |

⇒ B.7 est essentiellement net-new sur **3 couches** : LLM gateway, MCP servers,
pipeline RAG (embeddings + retrieval + re-ranking). Le reste est partagé.

## 4. Décisions arbitrées (mainteneur, 2026-06-11)

- **A — LLM gateway → ✅ thin proxy Rust axum IN-REPO.** Pas de gateway externe.
  OpenAI-compatible vers Mistral-Scaleway / vLLM ; tier-aware natif (refus
  OpenAI/Vertex/Bedrock à T3 per B.7.9 + J.8.c + Demeter K.3). Aligne le pattern
  "zero new external dep" de J.8/K.3. → dimensionne `llm-gateway.md` (B.7.3) +
  scaffolder (B.7.2).

- **B — Séquencement → ✅ chaîne incrémentale (grain B.8.x).** 9 changes atomiques
  reviewables/revertables (cf. §5), pas de monolithe B.7.2.

- **C — Agent Pythia (K.2) → ✅ change dédié `b7-pythia`** (patron `k3-demeter`).

- Différées en design.md (n'empêchent pas d'ouvrir B.7.1) :
  - D — embeddings provider (Mistral-EU vs local Candle/fastembed ; T3 ⇒ self-host).
  - E — MCP transport des stubs `db`/`file`/`search` (stdio subprocess vs HTTP axum).

## 5. Séquence de changes proposée (post-arbitrage)

1. `b7-1-schema` — `ai-native-rag/1.0.0.yaml` extends `ai-first` + phases
   `embeddings-pipeline` & `prompt-audit`. Effort `S`. (patron `b8-3-schema-candidate`)
2. `b7-standards` — `rag-patterns.md` + `llm-gateway.md` + `mcp-servers.md`. `M`.
3. `b7-2-scaffolder` — backbone Rust (axum + Temporal + pgvector + gateway + MCP stubs)
   + Qwik streaming. `XL` (ou éclaté selon décision B).
4. `b7-pythia` — agent K.2 (patron `k3-demeter`). `M`.
5. `b7-9-janus-ai` — B.7.9 + **J.8.c** (refus Vertex/Bedrock ; T3 ⇒ Mistral-EU/vLLM). `S`.
6. `b7-5-ai-act` — B.7.5 + B.7.8, débloque Themis K.5 + `.forge/compliance/{ai-act,dora}/`. `M`.
7. `b7-10-streaming` — Qwik SSE/WebTransport. `M`.
8. `b7-7-example` — `examples/forge-rag-example/` (3 demos). `L`.
9. `b7-6-harness` — `b7.test.sh` ≥35 + snapshot tarball. `M`.

Dépendances dures : 1→2→3, puis 4–9 largement parallélisables.

## 6. Mise à jour du registre de risques (§12)

- « MCP encore en évolution » → **dégrader** : SDK Rust officiel mûr, axum-natif,
  OAuth. Risque résiduel = churn d'API entre 0.5↔0.16 (mitigé verify-then-pin).
- « DBOS Go SDK » → **caduc pour B.7** : DBOS annulé Rust (B8O), Temporal natif.
  Risque résiduel = `temporalio-sdk` pré-alpha → activity-only workers, pin exact.
