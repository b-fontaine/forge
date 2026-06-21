# Specifications: b7-standards

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.7.3 (docs/new-archetypes-plan.md §6.2 — ai-native-rag standards) -->

**Namespace** : `FR-B7-3-*` / `NFR-B7-3-*` / `ADR-B7-3-*`.
**Constitution** : v2.0.0, unchanged. Additive — three `global/*.md` pattern
standards + index/REVIEW registration. Ships NO version pins (research §3).
**Governing articles** : III.1/III.2, III.4 (anti-hallucination), IV (additive),
XI.5/XI.6 + IX.6 (encoded into the patterns).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | §6.2 B.7.3 — `standards/global/{rag-patterns,llm-gateway,mcp-servers}.md` (effort M) |
| **Research** | `.forge/research/b7-standards-verify-then-pin.md` — LIVE baseline (rmcp 1.7.0 / pgvector 0.4.2 / async-openai 0.41.0) + Context7 pattern grounding + scope decision |
| **Schema fwd-refs (observed)** | `ai-native-rag/1.0.0.yaml` components `llm-gateway`/`mcp-servers`/`rag-pipeline` carry `delivered_by: B.7.3` |
| **Standard families (observed)** | versioned `*.yaml` (j7-validated, may pin) vs `global/*.md` (patterns). Plan picks `.md`. |
| **Pin-home precedent (observed)** | `transport.yaml` Connect pins delivered by b8-6 (consuming template), "verified LIVE"; `persistence.yaml` pins the pgvector *extension* not the crate |
| **EU/AI machinery (observed)** | `compliance-tiers.md`, `forbidden-components-rules.md` (I.3), `data-stewardship-rules.md` (K.3), `identity.yaml` (Zitadel), Constitution XI.5/XI.6/IX.6 |
| **index.yml / REVIEW pattern (observed)** | `.md` entry = id/path/triggers/scope/priority; REVIEW birth entry per standard |
| **Downstream** | B.7.2-full (consumes patterns + verify-then-pin baseline), b7-9-janus-ai (J.8.c) |
| **Release target** | maintainer-set ([Unreleased]) |

---

## ADDED Requirements

### Functional

#### Cluster 1 — rag-patterns.md (FR-B7-3-001 → 004)

##### FR-B7-3-001 — file + required sections
`global/rag-patterns.md` MUST exist with H2 sections covering: chunking &
embeddings; retrieval (vector + BM25 **hybrid**, Reciprocal Rank Fusion);
re-ranking; context-window management; pgvector HNSW tuning; evaluation;
Constitutional Compliance; Out-of-scope.

##### FR-B7-3-002 — pgvector retrieval specifics (Context7-grounded)
MUST document: distance ops `<->`/`<=>`/`<#>` + `vector_cosine_ops`;
`hnsw.ef_search` recall/speed trade-off; `hnsw.iterative_scan`
(`strict_order`/`relaxed_order`) for filtered queries; coarse `binary_quantize`
→ exact-distance re-rank. No fabricated SQL.

##### FR-B7-3-003 — EU sovereignty for embeddings
MUST state T3 requires a self-hosted / Mistral-EU embeddings provider (references
`compliance-tiers.md` + `data-stewardship-rules.md`; no duplication of tier defs).

##### FR-B7-3-004 — no version pins
MUST NOT inline a pgvector-crate / embedding-model version pin; references the
B.7.2-full verify-then-pin baseline (research §1).

#### Cluster 2 — llm-gateway.md (FR-B7-3-010 → 014)

##### FR-B7-3-010 — file + required sections
`global/llm-gateway.md` MUST exist with H2: proxy architecture (in-repo Rust
axum); upstream providers (OpenAI-compatible → Mistral-Scaleway / vLLM / OpenAI
fallback); tier-aware refusal; prompt audit & observability; budgets & kill
switch; PII & fallback; Constitutional Compliance; Out-of-scope.

##### FR-B7-3-011 — tier-aware refusal couples to EU machinery
MUST state T3 forbids OpenAI-direct / Vertex / Bedrock and REFERENCE
`forbidden-components-rules.md` (I.3) + `compliance-tiers.md` + Demeter (K.3);
MUST defer the runtime Janus AI refusal rules to `b7-9-janus-ai` (J.8.c), not
restate them.

##### FR-B7-3-012 — prompt audit wires IX.6
MUST require prompt-audit logging with token counts + fallback-invocation metrics
(Article IX.6), aligned to the schema's `prompt-audit` phase.

##### FR-B7-3-013 — XI.5 fallback + XI.6 PII
MUST mandate a non-AI fallback (XI.5) and PII minimisation + explicit consent
(XI.6); no PII to external providers without consent + DPA.

##### FR-B7-3-014 — no version pins
MUST NOT inline an `async-openai` / model version pin (research §1 baseline; pins
ride with B.7.2-full).

#### Cluster 3 — mcp-servers.md (FR-B7-3-020 → 024)

##### FR-B7-3-020 — file + required sections
`global/mcp-servers.md` MUST exist with H2: rmcp server pattern (stdio +
streamable-HTTP/axum, `#[tool_router]`); security; authentication; versioning &
maturity; Constitutional Compliance; Out-of-scope.

##### FR-B7-3-021 — security (least privilege, no arbitrary exec)
MUST mandate least-privilege tools, JsonSchema input validation, and NO arbitrary
filesystem/command execution from tool arguments (sandboxed db/file/search stubs).

##### FR-B7-3-022 — auth couples to Zitadel/Envoy-OIDC
MUST document OAuth 2.1 + PKCE (S256) + RFC 8707 resource binding and reference
`identity.yaml` (Zitadel, B.8.7) + Envoy SecurityPolicy JWT (B.8.12).

##### FR-B7-3-023 — rmcp maturity caveat + verify-then-pin (III.4)
MUST record the rmcp upstream **Tier-3** status (no stable release versioning) and
the three-conflicting-sources finding (README 0.16.0 / index 0.5.0 / LIVE 1.7.0)
as the motivating example; MUST require exact-pin + re-verify-at-bump. MUST NOT
inline an rmcp version pin (the 1.7.0 baseline is recorded for B.7.2-full only).

##### FR-B7-3-024 — schema reference mapping
mcp-servers.md (+ rag-patterns.md) headers MUST note the mapping from the schema
component names (`mcp-servers`, `rag-pipeline`) to the standard filenames (Q-002).

#### Cluster 4 — registration & harness (FR-B7-3-030 → 032)

##### FR-B7-3-030 — index.yml entries
`.forge/standards/index.yml` MUST gain one entry per standard (id/path/triggers/
scope/priority), triggers chosen for JIT injection (e.g. rag, embeddings,
retrieval, llm-gateway, mcp, rmcp, ai-native-rag).

##### FR-B7-3-031 — REVIEW.md birth entries
`.forge/standards/REVIEW.md` MUST gain an append-only birth entry per standard
(dated 2026-06-13).

##### FR-B7-3-032 — harness
`.forge/scripts/tests/b7-3.test.sh` MUST assert each standard exists + carries its
required H2 sections + a Constitutional-Compliance section + an Out-of-scope note,
AND that no standard inlines a forbidden version-pin pattern (negative grep for
`rmcp = "`, `pgvector = "`, `async-openai = "` semver lines). Registered in
`forge-ci.yml`.

### Non-Functional

##### NFR-B7-3-001 — additive
No existing standard/schema/constitution/CLI/template edited; only new `.md` +
index/REVIEW appends + new harness + CI registration.

##### NFR-B7-3-002 — no pins anywhere
No version pin in any of the three standards (FR-B7-3-004/014/023/032). The
research baseline is the only place versions appear, explicitly as a B.7.2-full
verify-then-pin baseline.

##### NFR-B7-3-003 — gates green
`verify.sh`, `constitution-linter.sh`, `validate-standards-yaml.sh` (no new yaml,
so no-op), and the harness suite stay GREEN.

## ADRs (seeded — resolved at /forge:design)

- **ADR-B7-3-001** — `.md` pattern docs, zero pins (transport.yaml/b8-6 precedent).
- **ADR-B7-3-002** — reference existing EU machinery, don't duplicate; J.8.c → b7-9.
- **ADR-B7-3-003** — record the rmcp Tier-3 / three-source caveat verbatim (III.4).

## Acceptance Criteria (impl)

1. Three `global/*.md` exist with all required H2 sections + Constitutional
   Compliance + Out-of-scope.
2. No version pin in any standard (negative-grep harness test passes).
3. index.yml has 3 new entries; REVIEW.md has 3 birth entries.
4. `b7-3.test.sh` GREEN; registered in forge-ci.yml.
5. verify.sh + constitution-linter.sh + validate-standards-yaml.sh no regression.
6. Schema/constitution/existing-standards untouched.
