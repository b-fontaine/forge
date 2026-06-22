# Tasks: b7-2-scaffolder

<!-- Planned: 2026-06-21 -->
<!-- TDD-ordered (Article I). Tests = b7-2.test.sh assertions (RED before template, -->
<!-- GREEN after) AND rendered-code #[cfg(test)] validated by L2 cargo check/test. -->
<!-- [P] = parallelizable within its phase. -->

## Phase 0: Verify-then-pin + harness skeleton ✅ (2026-06-21)

- [x] Create `.forge/scripts/tests/b7-2.test.sh` skeleton — RED confirmed (T-001/T-002 fail, tree absent; T-003/004/005 green). **CI registration DEFERRED to end of Phase 1** (a RED test on main would break CI). [Story: FR-B7-2-060]
- [x] **Verify-then-pin LIVE** (`cargo add --dry-run`, cargo 1.96.0): `rmcp = "1.7.0"` (server/macros/schemars/auth; stdio=`transport-io`, http=`transport-streamable-http-server`+`server-side-http`+`tower`), `pgvector = "0.4.2"` (sqlx), `async-openai = "0.41.1"`, `fastembed = "5.17.2"` — recorded in `.forge/research/b7-2-verify-then-pin.md` [Story: FR-B7-2-040]
- [x] rmcp drift resolved → **1.7.0** (crates.io ground truth vs README 0.16.0 / Context7 0.5.0) [Story: FR-B7-2-040] [ADR-B7-3-003]

## Phase 1: Template tree foundation ✅ (2026-06-21, VulcanP1; verified independently)

- [x] RED confirmed at P0 (T-001/T-002 fail, tree absent) [Story: FR-B7-2-001]
- [x] GREEN: layer-root tree created (mirror flagship 2.0.0) — 20 `.tmpl` files; T-001 GREEN [Story: FR-B7-2-001]
- [x] GREEN: `scaffold-plan.yaml` authored; T-002 plan↔tree coverage GREEN (no orphan/dangling) [Story: FR-B7-2-002]
- [x] GREEN: L2 render-clean — **renders via `overlay.sh`, NOT `init.sh`** (init.sh hardcodes full-stack-monorepo + needs flutter/buf; overlay.sh is the repo-wide hermetic-render convention, cf. b8-14-flip/scaffolder L2). 21 files rendered, no `.tmpl`/no `{{placeholder}}`, byte-stable double render (NFR-B7-2-004). T-L2-001 GREEN, non-vacuous (verified 21 files) [Story: FR-B7-2-003]
- [x] GREEN: `shared/protos/v1/rag/rag.proto` (`rag.v1.RagService.Query`, `fallback_used` per XI.5) + `buf.yaml`/`buf.gen.yaml` (Rust+Go+TS Connect, no Dart) [Story: FR-B7-2-001]
- [x] (carried fwd) `backend/Cargo.toml.tmpl` workspace pin-ledger shipped here (T-004 requires a pin once `backend/` exists): rmcp 1.7.0 / pgvector 0.4.2 / async-openai 0.41.1 / fastembed 5.17.2, `members` commented out, no Rust src. Pins live only here (ADR-B7-2-003) [Story: FR-B7-2-041]

## Phase 2: Backend core (Rust, Vulcan/Ferris — all TDD) ✅ (2026-06-21, VulcanP1; verified independently — rendered `cargo test` 35 GREEN + L2 `cargo check` GREEN)

- [x] `backend/Cargo.toml.tmpl` workspace + 4 per-crate manifests; rendered `cargo check --workspace` clean (T-L2-002 GREEN) [Story: FR-B7-2-010] [ADR-B7-2-003]
- [x] `bin-server` axum entrypoint; substrate (Connect/Temporal/Zitadel/OTel) consumed by reference [Story: FR-B7-2-011]
- [x] `rag::embeddings::Embedder` trait + `select_backend` tier test (T3⇒Local, verified real) [Story: FR-B7-2-014] [ADR-B7-2-004]
- [x] `MistralEmbedder` (async-openai, **feature `embedding`** — deviation) [Story: FR-B7-2-014]
- [x] `LocalEmbedder` (fastembed, **feature `local-embeddings` OFF by default** — ONNX heavy-dep guard; Mutex wrap for `&self`/`&mut self`) [Story: FR-B7-2-014]
- [x] `rag/` pipeline — chunking, hybrid retrieval vector+BM25+RRF (RRF-merge + determinism tests), coarse→exact re-rank (ordering test), pgvector HNSW `<=>` `vector_cosine_ops` via **sqlx 0.9** (deviation: pgvector 0.4.2 requires it) [Story: FR-B7-2-014] [rag-patterns.md]
- [x] RAG heavy work as Temporal **activity-only** worker [Story: FR-B7-2-014]
- [x] `llm_gateway/` thin axum proxy — `decide_route` (kill-switch/tier-refusal/budget→fallback), prompt-audit span (IX.6) + PII redaction (XI.6), **non-AI fallback tested with upstream mocked to fail** (XI.5, verified real) [Story: FR-B7-2-012] [llm-gateway.md]
- [x] `mcp/` rmcp `#[tool_router(server_handler)]` + `search` stub tool; tool-JSON-schema test [Story: FR-B7-2-013] [mcp-servers.md]
- [x] `mcp/transport/{stdio,http}.rs` feature-gated (`mcp-stdio` default = `rmcp/transport-io`; `mcp-http` = streamable-http-server+server-side-http+tower, OAuth→Zitadel hook); both feature sets build [Story: FR-B7-2-013] [ADR-B7-2-005]
- [x] Harness T-L2-002 upgraded from NOTE stub → real render + `cargo check --workspace` (skips gracefully if cargo absent) [Story: FR-B7-2-060]

## Phase 3: Frontend + infra ✅ (2026-06-21, VulcanP1; verified independently — L2 7/7 over 54 templates, Qwik typecheck clean bar the 1 expected un-generated-proto import)

- [x] `frontend/web-public/` Qwik shell (mirror flagship 2.0.0) wired via Connect-ES v2, RAG query UI (answer + sources + `fallbackUsed` XI.5 indicator), non-streaming baseline; `npx tsc --noEmit` = 1 expected error only (generated `rag_pb` import → buf generate deferred to b7-6, same as flagship) [Story: FR-B7-2-020] [ADR-B7-2-006]
- [x] web-public no Flutter/mobile surface (Q-5) [Story: FR-B7-2-020]
- [x] `infra/` — pgvector HNSW init (Phase 1) confirmed wired; `k8s/llm-gateway/{deployment,service,kustomization}` added; Temporal/Zitadel/Envoy/SigNoz reused by reference, no new infra component [Story: FR-B7-2-030] [NFR-B7-2-001]

## Phase 4: Scaffolder wrapper + CLI bundle ✅ (2026-06-21, VulcanP1; verified independently)

- [x] **Gated real body** in `bin/forge-init-ai-native-rag.sh` (ADR-B7-2-007): scaffoldability gate (candidate→exit 3 BEFORE arg-parse) → renders via **overlay.sh** when scaffoldable (NOT init.sh); J.8 hook retained; `buf generate`+`cargo fetch` = TODO(b7-6); `FORGE_AINR_FORCE_SCAFFOLD=1` harness-only override [Story: FR-B7-2-050]
- [x] Wrapper refuses exit 3 + zero writes while candidate (verified direct: 0 files); T-006 + T-L2-003 (gated render → 55 files clean) added [Story: FR-B7-2-051] [ADR-B7-2-001]
- [x] `npm run bundle` (848 files; 55 ai-native-rag assets + plan + schema + wrapper bundled by exclusion-whitelist, no bundle.ts change); `cd cli && npm test` 87/1-skip GREEN, ai-native-rag = refusing-candidate partition (ran live); `cli/assets/` is gitignored build artifact (not in git status, correct) [Story: FR-B7-2-052]
- [x] Regression caught+fixed: b7-2a T-003 (gate moved before arg-parse so legacy `testproj --org` ABI shape still refuses exit 3) → b7-2a 3/3 [Story: NFR-B7-2-002]

## Phase 5: BDD + quality gates + no-regression ✅ (2026-06-21, VulcanP1; verified independently)

- [x] `features/b7-2-scaffolder.feature` — 4 scenarios (render-clean→T-L2-001/T-002, backend-builds→T-L2-002+rendered cargo test, CLI-refuses→archetypes-smoke+T-006, gateway-fallback→rust `upstream_down_degrades_to_non_ai_fallback`); each cross-references the enforcing test [Story: FR-B7-2-001/003/051/012] [Article II]
- [x] `b7-2.test.sh` finalized: L1 6 (incl T-006) + L2 9 (incl T-L2-002 cargo check, T-L2-003 gated render); registered in `forge-ci.yml` (`--level 1`, after b7-3 — CI job has python+node, no rust, so L2 stays local/b7-6) [Story: FR-B7-2-060]
- [x] No-regression sweep: verify.sh PASS (442/0/1), constitution-linter OVERALL PASS, validate-foundations PASS, b5 17/0, b7-1 18/0, b7-2a 3/0, b7-3 7/0 [Story: NFR-B7-2-002]
- [x] b7-3 T-007 no-inline-pin guard GREEN (pins only in backend Cargo.toml.tmpl) [Story: FR-B7-2-041]
- [x] Independent review pass (ReviewerB72, separate agent) → APPROVE-WITH-NITS; MAJOR + MINOR fixed by author + re-verified (L1 7/7, L2 10/10, cargo test 35/0, verify.sh PASS 442/0); promotion to stable/scaffoldable NOT done here (→ b7-6) [Story: ADR-B7-2-001]

## Independent review outcome (ReviewerB72, 2026-06-21) — APPROVE-WITH-NITS

Reproduced independently: b7-2 L1 6→7/L2 9/9, rendered `cargo test --workspace` 35/0,
`cargo check` 42s real, both feature gates build, no-regression (verify.sh PASS,
constitution-linter PASS, b7-1/2a/3 GREEN), schema unchanged (candidate). Dispositions:
- [MAJOR] FR-B7-2-060 conformance grep specced-not-shipped → **FIXED** (new L1 test, author pass).
- [MINOR] upstream-outage mislabeled `KillSwitch` in IX.6 audit → **FIXED** (`FallbackReason::UpstreamUnavailable`, author pass).
- [MINOR] `docs/new-archetypes-plan.md` out of NFR-B7-2-001 → **clarified**: separate maintainer resync task, committed separately (see NFR-B7-2-001 scope note).
- [NIT] Temporal worker name-only + bin-server gateway stub → expected for a scaffold; **deferred to b7-6** (activity contract + `buf generate`/`cargo fetch` wiring + promotion).

## Constitutional Compliance Gate (per phase)

No task requires violating TDD (every impl task is RED→GREEN), bypassing specs
(all tasks cite FR/ADR), or breaking architecture articles. No `[TASK VIOLATION]`.

---

**Gate**: Tasks generated. Review `tasks.md`. Next: `/forge:implement b7-2-scaffolder`.
