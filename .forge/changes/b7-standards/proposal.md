# Proposal: b7-standards

<!-- Created: 2026-06-13 -->
<!-- Schema: default -->
<!-- Audit: B.7.3 (docs/new-archetypes-plan.md §6.2 — ai-native-rag standards) -->

## Problem

B.7.1 shipped `.forge/schemas/ai-native-rag/1.0.0.yaml` whose component set
references three standards as `delivered_by: B.7.3` — `llm-gateway`,
`mcp-servers`, `rag-pipeline` — that **do not exist yet**. Until they land, the
schema's references are forward-pointers with no target, and B.7.2-full (the
scaffolder) has no ratified patterns to scaffold against. This change ships those
three pattern standards.

**Ground truth (re-read 2026-06-13, Article III.4):**

- **Two standard families** in `.forge/standards/`: versioned `*.yaml`
  (frontmatter-validated by `j7-validate-standards-yaml`, 12-month review, may
  carry version pins — e.g. `transport.yaml`, `persistence.yaml`) and
  `global/*.md` human-readable pattern docs (e.g. `sbom-policy.md`,
  `data-stewardship-rules.md`). Plan §6.2 B.7.3 names the three as
  `standards/global/*.md` — **pattern docs, not pin-bearing yaml**.
- **The pin-home precedent is unambiguous**: `transport.yaml`'s Connect crate
  pins were delivered BY the brick that shipped the consuming template
  (`b8-6-connect-rpc`), each "verified LIVE", NOT by a standalone standards
  change. `persistence.yaml` carries `pgvector-0.8` (the Postgres extension), not
  the Rust crate. ⇒ rmcp / pgvector-crate / gateway-client **version pins belong
  with B.7.2-full's `Cargo.toml.tmpl`**, not here (maintainer decision 2026-06-13,
  research §3).
- **Verify-then-pin LIVE baseline** (`.forge/research/b7-standards-verify-then-pin.md`,
  crates.io 2026-06-13): `rmcp = 1.7.0`, `pgvector = 0.4.2`, `async-openai =
  0.41.0`. The rmcp version was WRONG in every doc source (README 0.16.0, Context7
  index 0.5.0) — only `cargo search` was correct. rmcp is upstream **Tier 3** (no
  stable release versioning). These are recorded as the B.7.2-full baseline; this
  change pins NONE of them.
- **Existing EU/AI machinery to couple to** (re-read, real): `compliance-tiers.md`
  (T1/T2/T3), `forbidden-components-rules.md` (I.3 — T3 forbids OpenAI-direct /
  Vertex / Bedrock), `data-stewardship-rules.md` (Demeter K.3), Constitution
  Article XI.5 (mandatory fallback) / XI.6 (PII) / IX.6 (AI observability),
  `identity.yaml` (Zitadel) + Envoy SecurityPolicy JWT (B.8.12) for MCP OAuth.
- **index.yml registration**: `.md` standards register with `id:` / `path:` /
  `triggers:` / `scope:` / `priority:` (e.g. `global/data-stewardship-rules`).
  `REVIEW.md` gets a birth entry per new standard.

## Solution

Author three `global/*.md` pattern standards (no version pins), register them in
`index.yml`, add `REVIEW.md` birth entries, and ship a harness asserting their
presence + required structure.

1. **`global/rag-patterns.md`** — chunking, embeddings, retrieval (vector + BM25
   hybrid via Reciprocal Rank Fusion), re-ranking (coarse binary-quantize →
   exact-distance; cross-encoder), context-window management, pgvector HNSW
   tuning (`ef_search`, `iterative_scan` for filtered queries), evaluation, EU
   sovereignty (embeddings provider self-host / Mistral-EU for T3).
2. **`global/llm-gateway.md`** — in-repo Rust axum proxy pattern; OpenAI-compatible
   upstream (Mistral-Scaleway / vLLM / OpenAI fallback T1); **tier-aware refusal**
   (T3 forbids OpenAI-direct/Vertex/Bedrock — couples to compliance-tiers +
   forbidden-components + Demeter + J.8.c); prompt-audit logs (IX.6); BYOK;
   tenant-scoped budgets; kill switch; PII minimisation (XI.6); mandatory non-AI
   fallback (XI.5).
3. **`global/mcp-servers.md`** — rmcp server pattern (stdio + streamable-HTTP/axum,
   `#[tool_router]`); security (least-privilege, input validation, NO arbitrary
   fs/exec); auth (OAuth 2.1 + PKCE + RFC 8707 → Zitadel/Envoy-OIDC); versioning +
   the rmcp Tier-3/pre-stable exact-pin-and-re-verify rule.

All three carry a `## Constitutional Compliance` section and an `## Out-of-scope`
note stating pins are delivered by B.7.2-full.

Decisions for `/forge:design` (ADRs); leanings stated:

- **ADR-B7-3-001 — `.md` pattern docs, zero version pins.** Lean: per the
  transport.yaml/b8-6 precedent + research §3, pins ride with B.7.2-full. Rejected:
  shipping a pin-bearing `.yaml` now (orphan pins under j7 + 12-month review with
  no consumer; rmcp churns pre-1.0).
- **ADR-B7-3-002 — couple to existing EU machinery, don't duplicate.** Lean:
  llm-gateway.md REFERENCES compliance-tiers / forbidden-components / Demeter
  rather than restating tier rules; the actual Janus AI refusal rules (J.8.c) stay
  deferred to `b7-9-janus-ai`.
- **ADR-B7-3-003 — record the rmcp maturity caveat verbatim.** Lean: mcp-servers.md
  states the Tier-3 / three-conflicting-sources finding as the motivating example
  for verify-then-pin (Article III.4), no fabricated stability claim.

## Scope In

- `.forge/standards/global/{rag-patterns,llm-gateway,mcp-servers}.md` (new).
- `.forge/standards/index.yml` — three entries.
- `.forge/standards/REVIEW.md` — three birth entries.
- `.forge/scripts/tests/b7-3.test.sh` — presence + required-section harness; CI.
- `.forge/research/b7-standards-verify-then-pin.md` (already written — the baseline).
- Change artifacts.

## Scope Out (Explicit Exclusions)

- **Version pins** (rmcp / pgvector-crate / async-openai) — B.7.2-full
  `Cargo.toml.tmpl`, verify-then-pin LIVE then (research §1 is the baseline).
- **A pin-bearing `.yaml` standard** — not created (ADR-B7-3-001).
- **Templates / scaffold-plan / scaffolder** — B.7.2-full.
- **Janus AI refusal rules (J.8.c)** — `b7-9-janus-ai`.
- **Schema promotion** — schema stays candidate/scaffoldable:false.
- **Agent Pythia (K.2)** — `b7-pythia`.

## Impact

- **Users**: B.7 archetype authors gain the ratified RAG/gateway/MCP patterns the
  scaffolder (B.7.2-full) will implement. No runtime/CLI change; no existing
  archetype affected. The three `.md` resolve the b7-1 schema forward-references.
- **Dependencies**: B.7.1 (the schema referencing these). Unblocks B.7.2-full
  (scaffolder consumes the patterns + the verify-then-pin baseline).

## Constitution Compliance

- **III.1/III.2 (Specs before code)**: propose+specify first; standards authored
  at impl (harness RED before the docs).
- **III.4 (Anti-Hallucination)**: every claim Context7/cargo-grounded; the rmcp
  three-source version conflict + Tier-3 status recorded, not glossed; no pin
  fabricated.
- **IV (Delta-based)**: additive — three new `.md` + index/REVIEW appends; no
  existing standard/schema/constitution edited.
- **XI / IX.6**: llm-gateway.md + mcp-servers.md encode XI.5 fallback, XI.6 PII,
  IX.6 AI observability into the archetype's patterns.
- **XII (Governance)**: no amendment; `.md` standards are not Article-XII
  structural-exception yaml.

## Open Questions (seed)

- **Q-001** — do the three `.md` carry a `linter_rule:`-style enforcement hook, or
  pure guidance? (Lean: pure guidance now; enforcement via existing
  forbidden-components linter for the T3 cases. Resolve at design.)
- **Q-002** — `rag-pipeline` (schema component name) vs `rag-patterns.md` (standard
  filename): confirm the schema's `delivered_by` reference resolves by intent (the
  component is the pipeline; the standard documents its patterns). (Lean: keep both
  names; note the mapping in the standard header. Resolve at design.)
