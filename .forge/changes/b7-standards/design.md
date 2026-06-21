# Design: b7-standards

<!-- Status: designed -->
<!-- Schema: default -->
<!-- Audit: B.7.3 (docs/new-archetypes-plan.md §6.2 — ai-native-rag standards) -->

Resolves the proposal/specs ADRs + Q-001/Q-002. Ships three `global/*.md` pattern
standards (no pins), grounded by `.forge/research/b7-standards-verify-then-pin.md`.

## Architecture Decisions

### ADR-B7-3-001 — `.md` pattern docs, zero version pins
**Context**: the schema's `llm-gateway`/`mcp-servers`/`rag-pipeline` components
point at standards `delivered_by: B.7.3`. Plan §6.2 names them `global/*.md`. Live
crates.io gives rmcp 1.7.0 / pgvector 0.4.2 / async-openai 0.41.0 — but no
consuming template exists until B.7.2-full.
**Decision**: ship pattern `.md` only; **no version pin** in any of the three.
Pins ride with B.7.2-full's `Cargo.toml.tmpl`, re-verified LIVE then — exactly the
`transport.yaml`/b8-6 precedent (pins delivered by the consuming brick, "verified
LIVE"). The research baseline (§1) is recorded for B.7.2-full, not shipped here.
**Consequences**: no orphan pins under the j7 yaml gate + 12-month review; rmcp
(pre-1.0, Tier-3) is re-verified once, at its real consumer. A negative-grep
harness test (FR-B7-3-032) guards against an accidental inline pin.
**Constitution**: III.4 (no fabricated/premature pin) + IV (additive) confirmed.

### ADR-B7-3-002 — reference existing EU machinery, don't duplicate; J.8.c → b7-9
**Context**: tier rules (T1/T2/T3), T3-forbidden components, and data-stewardship
already exist as standards; the runtime Janus AI refusal is a separate planned
brick (J.8.c).
**Decision**: `llm-gateway.md` REFERENCES `compliance-tiers.md` +
`forbidden-components-rules.md` (I.3) + `data-stewardship-rules.md` (K.3) for the
tier-aware refusal, and DEFERS the runtime Janus AI refusal rules to
`b7-9-janus-ai`. No tier definitions or rule catalogues are restated. Resolves
Q-001 → (a) pure guidance (enforcement already lives in I.3 + Demeter).
**Consequences**: single source of truth for tier rules; no pre-emption of b7-9.

### ADR-B7-3-003 — record the rmcp maturity caveat verbatim (III.4)
**Context**: rmcp reported three different versions across sources (README 0.16.0,
Context7 index 0.5.0, crates.io LIVE 1.7.0) and is upstream Tier-3 ("no stable
release versioning").
**Decision**: `mcp-servers.md` records this as the motivating example for
verify-then-pin (exact-pin + re-verify-at-bump, upstream-release watch-list),
mirroring the connectrpc pre-1.0 waiver in `transport.yaml`. No fabricated
stability claim; no inline rmcp pin.
**Constitution**: III.4 confirmed.

### ADR-B7-3-004 — `rag-patterns.md` filename + documented component mapping (Q-002)
**Decision**: keep the plan's `rag-patterns.md` filename; document the schema
component → standard mapping (`rag-pipeline` component ↔ `rag-patterns.md`
standard; `mcp-servers`/`llm-gateway` map 1:1) in each standard's header. Does NOT
edit the b7-1 schema (additive). Rejected: renaming to `rag-pipeline.md` (diverges
from plan §6.2 for no gain).

## Component Design

```mermaid
graph LR
  SCHEMA["ai-native-rag/1.0.0.yaml<br/>components delivered_by: B.7.3"]
  RAG["global/rag-patterns.md"]
  GW["global/llm-gateway.md"]
  MCP["global/mcp-servers.md"]
  IDX["index.yml (3 entries)"]
  REV["REVIEW.md (3 births)"]
  H["b7-3.test.sh"]
  EU["compliance-tiers / forbidden-components / data-stewardship<br/>identity.yaml (Zitadel)"]
  RES["research: verify-then-pin baseline<br/>(rmcp 1.7.0 / pgvector 0.4.2 / async-openai 0.41.0)"]

  SCHEMA -. resolves fwd-ref .-> RAG & GW & MCP
  GW -->|references, no duplication| EU
  MCP -->|OAuth → Zitadel/Envoy-OIDC| EU
  RAG & GW & MCP --> IDX & REV
  H -->|presence + sections + NO-pin negative grep| RAG & GW & MCP
  RES -. baseline for B.7.2-full, NOT pinned here .-> GW & MCP & RAG
```

## Standards content blueprint (authored at impl)

- **rag-patterns.md** — H2: Schema mapping; Chunking & embeddings; Retrieval
  (vector `<->`/`<=>`/`<#>`, BM25 hybrid + RRF); Re-ranking (binary-quantize
  coarse → exact; cross-encoder); pgvector HNSW tuning (`ef_search`,
  `iterative_scan`); Context-window mgmt; Evaluation; EU sovereignty
  (T3 → self-host/Mistral-EU, refs compliance-tiers); Constitutional Compliance;
  Out-of-scope (pins → B.7.2-full).
- **llm-gateway.md** — H2: Schema mapping; Proxy architecture (in-repo Rust axum,
  OpenAI-compatible upstream); Providers (Mistral-Scaleway / vLLM / OpenAI
  fallback T1); Tier-aware refusal (refs I.3 + compliance-tiers + Demeter; J.8.c →
  b7-9); Prompt audit & observability (IX.6); Budgets & kill switch; PII &
  fallback (XI.6/XI.5); Constitutional Compliance; Out-of-scope.
- **mcp-servers.md** — H2: Schema mapping; rmcp server pattern (stdio +
  streamable-HTTP/axum, `#[tool_router]`); Security (least-privilege, input
  validation, no arbitrary fs/exec); Authentication (OAuth 2.1 + PKCE + RFC 8707 →
  Zitadel/Envoy-OIDC); Versioning & maturity (Tier-3 caveat + verify-then-pin);
  Constitutional Compliance; Out-of-scope.

## Testing Strategy (TDD — Article I)

1. **RED**: `b7-3.test.sh` asserts the three files exist, each has its required H2
   set + Constitutional-Compliance + Out-of-scope, index.yml has 3 entries,
   REVIEW.md has 3 births, AND a negative grep finds NO inline version pin
   (`rmcp = "`, `pgvector = "`, `async-openai = "` + semver). Run → fails (no
   files). Verify RED.
2. **GREEN**: author the three `.md` + index/REVIEW entries. Run → PASS.
3. **REFACTOR**: tidy; re-run; verify.sh + constitution-linter.sh +
   validate-standards-yaml.sh (no-op, no new yaml) no regression.
- **BDD**: N/A (documentation standards, not a user-facing feature).
- Register `b7-3.test.sh` in `forge-ci.yml`.

## Standards Applied

- `source-document-pinning.md` / III.4 — verify-then-pin LIVE baseline recorded,
  not pinned; rmcp three-source conflict documented.
- `standards-lifecycle.md` — REVIEW.md birth entries; `.md` standards are not the
  Article-XII structural-exception yaml class.
- Context7/cargo grounding per CLAUDE.md rule 6.

## Constitutional Compliance Gate

- Article I (TDD): harness RED before docs. ✓
- Article IV (delta): additive; no existing standard/schema/constitution edited. ✓
- Article III.4: Context7/cargo-grounded; rmcp caveat recorded; no pin fabricated. ✓
- Article XI.5/XI.6 + IX.6: encoded into gateway/MCP patterns. ✓
- No Article-XII amendment (`.md` standards). ✓
**Gate: PASS.**
