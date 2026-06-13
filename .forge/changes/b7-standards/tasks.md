# Tasks: b7-standards

<!-- Status: archived -->
<!-- Schema: default -->
<!-- Audit: B.7.3 (docs/new-archetypes-plan.md §6.2 — ai-native-rag standards) -->

TDD-ordered (Article I). Deliverable: three `global/*.md` pattern standards (no
pins) + index/REVIEW registration + harness. Harness authored FIRST.

## Phase 1: RED — failing harness

- [x] **T1.1** Author `.forge/scripts/tests/b7-3.test.sh` (sources `_helpers.sh`).
  L1: each of rag-patterns/llm-gateway/mcp-servers.md exists; each has its required
  H2 sections (per design blueprint) + a Constitutional-Compliance section + an
  Out-of-scope note + a schema-mapping note; index.yml has the 3 entries;
  REVIEW.md has the 3 birth entries; **negative grep**: no inline version pin
  (`rmcp = "`, `pgvector = "`, `async-openai = "` followed by a semver) in any of
  the three. [Story: FR-B7-3-001/010/020/030/031/032, NFR-B7-3-002]
- [x] **T1.2** Run `bash .forge/scripts/tests/b7-3.test.sh --level 1` → **verify
  RED** (no standards yet). [Gate: Article I]

## Phase 2: GREEN — author the standards

- [x] **T2.1** `global/rag-patterns.md` (FR-B7-3-001..004) — chunking/embeddings,
  hybrid retrieval + RRF, re-ranking, pgvector HNSW tuning (ef_search/
  iterative_scan/binary-quantize), context-window, evaluation, EU sovereignty
  (refs compliance-tiers), Constitutional Compliance, Out-of-scope. [P]
- [x] **T2.2** `global/llm-gateway.md` (FR-B7-3-010..014) — axum proxy,
  OpenAI-compatible upstream (Mistral/vLLM/fallback), tier-aware refusal (refs I.3
  + compliance-tiers + Demeter; J.8.c→b7-9), prompt audit (IX.6), budgets/kill
  switch, PII+fallback (XI.6/XI.5), Constitutional Compliance, Out-of-scope. [P]
- [x] **T2.3** `global/mcp-servers.md` (FR-B7-3-020..024) — rmcp server pattern,
  security (least-priv/input-validation/no-exec), OAuth 2.1+PKCE+RFC8707 →
  Zitadel/Envoy-OIDC, versioning + rmcp Tier-3/verify-then-pin caveat,
  Constitutional Compliance, Out-of-scope. [P]
- [x] **T2.4** Add 3 entries to `.forge/standards/index.yml` (id/path/triggers/
  scope/priority). [Story: FR-B7-3-030]
- [x] **T2.5** Add 3 birth entries to `.forge/standards/REVIEW.md` (2026-06-13).
  [Story: FR-B7-3-031]
- [x] **T2.6** Run `b7-3.test.sh --level 1` → **verify GREEN**. [Gate: Article I]

## Phase 3: Integration

- [x] **T3.1** Register `b7-3.test.sh` in `.github/workflows/forge-ci.yml` (after
  `b7-2a.test.sh`). [Story: FR-B7-3-032]
- [x] **T3.2** Run `validate-standards-yaml.sh` → no-op/GREEN (no new yaml).

## Phase 4: Quality

- [x] **T4.1** `verify.sh` + `constitution-linter.sh` → no regression. [NFR-B7-3-003]
- [x] **T4.2** `git diff --name-only` → additive: 3 new `.md` + harness + change
  artifacts + research; edits limited to index.yml (append), REVIEW.md (append),
  CI matrix. No schema/constitution/existing-standard touched. [NFR-B7-3-001]
- [x] **T4.3** REFACTOR; re-run b7-3 harness → GREEN.
- [x] **T4.4** `/forge:review b7-standards` — independent reviewer **APPROVE**
  (2026-06-13, first pass — 0 CRITICAL/HIGH/MEDIUM) + **maintainer ratification**
  of ADR-B7-3-001..004 + Q-001/Q-002 (2026-06-13). Article V satisfied. Archived.

## Constitution Gate (per task)
- TDD: harness RED (T1.2) before docs GREEN (T2.6). ✓
- Additive; every task cites its FR/NFR/ADR. ✓ No [TASK VIOLATION].

## Parallelization
- T2.1–T2.3 are `[P]` (three independent files); author together, then T2.4/T2.5
  registration, then the single GREEN gate (T2.6).
