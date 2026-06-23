<!-- Audit: B.7.2 (b7-2-scaffolder, Phase 3) — ai-native-rag infra README -->
<!-- Standard: infra/docker-compose.md, infra/kubernetes.md -->

# Infrastructure for `forge-rag-example`

The `ai-native-rag` archetype **reuses the B.8 substrate by reference** and adds
nothing new at the component level (`NFR-B7-2-001`). This directory holds only the
RAG-specific deltas; everything else is consumed from the flagship 2.0.0 stack.

## Reused B.8 substrate (by reference — not re-created here)

| Component | Source | Role |
|-----------|--------|------|
| Postgres + **pgvector** (HNSW) | `pgvector:0.8.2-pg17` (B.8.5) | RAG vector store |
| **Temporal** | B8O (`orchestration.yaml`) | activity-only RAG workers (`backend/rag/worker`) |
| **Zitadel** OIDC | B.8.7 (`identity.yaml`) | identity plane (incl. MCP-over-HTTP OAuth 2.1) |
| **Envoy Gateway** | B.8.4 / §VIII.1 | edge ingress + SecurityPolicy JWT (B.8.12) |
| **SigNoz / OBI / Coroot** | B.8.8 (`observability.yaml`) | traces/metrics (prompt-audit spans, IX.6) |

These are wired the same way the flagship 2.0.0 stack wires them (docker-compose
fragments for dev; Envoy Gateway + Kustomize for k8s). Do not re-declare them in
this archetype — point your overlays at the flagship manifests.

## RAG-specific additions (the only deltas)

| Path | What |
|------|------|
| `postgres/init-pgvector.sql` | `CREATE EXTENSION vector` + the HNSW (`vector_cosine_ops`) and full-text (GIN) indexes the hybrid-retrieval pipeline queries (wired into the dev compose `arn-db` init mount). |
| `k8s/llm-gateway/` | The in-repo LLM gateway proxy (`backend/llm_gateway`) as a Deployment + Service + kustomization — the Connect endpoint all model traffic funnels through. |
| root `docker-compose.dev.yml` | The `arn-llm-gateway` service wiring (dev) + the `arn-db` pgvector init mount. |

## Dev vs prod

- **Dev**: `docker-compose.dev.yml` brings up `arn-db` (pgvector), `arn-backend`,
  and `arn-llm-gateway` on the `arn-dev` network. Run `task dev:up`.
- **Prod**: compose the `k8s/llm-gateway/` kustomization with the reused B.8
  Envoy Gateway + Zitadel + observability overlays. This is a DEV-first scaffold;
  production hardening (TLS, auth gates, NetworkPolicy, the llm-gateway image +
  `llm-gateway-secrets` Secret) is an **Aegis-audited** delta before any prod
  rollout (see `infra/CLAUDE.md`).
