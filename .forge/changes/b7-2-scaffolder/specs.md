# Specs: b7-2-scaffolder

<!-- Specified: 2026-06-21 -->
<!-- Namespace: FR-B7-2-* / NFR-B7-2-* / ADR-B7-2-* -->
<!-- Source: proposal.md + .forge/schemas/ai-native-rag/1.0.0.yaml (B.7.1) -->
<!--         + global/{rag-patterns,llm-gateway,mcp-servers}.md (B.7.3) -->
<!--         + .forge/templates/archetypes/full-stack-monorepo/2.0.0 (structural precedent) -->

**Constitution** : v2.0.0 (no bump — additive; consumes §VIII.1 Envoy + §VIII.2
Temporal + Article XI AI-First + IX.6 as ratified).

**Format** : ADDED requirements only (new template tree + scaffolder body). No
existing spec is MODIFIED or REMOVED. This file's requirements will be appended
to `.forge/specs/ai-native-rag.md` on archive (B.7 spec-accumulation convention).

**Ground truth (re-read 2026-06-21, Article III.4)**:
- Canonical archetype templates live at
  `.forge/templates/archetypes/<archetype>/<version>/`; the bundled mirror is
  `cli/assets/.forge/templates/...` (`npm run bundle`).
- The flagship renders via `.forge/scripts/scaffolder/init.sh --plan <plan>`; the
  ABI wrapper (`bin/forge-init-fsm-2.0.0.sh`) forwards `--plan scaffold-plan-2.0.0.yaml`.
- **`candidate ⇒ scaffoldable:false` is invariant** (b8-3b
  `check_versioned_schema_siblings`). Therefore promotion to `stable` +
  `scaffoldable:true` CANNOT happen in this brick — it is gated on a green
  `b7-6-harness` (ADR-B7-1-002). This brick lands templates + scaffolder body +
  pins, validated by a fixture that drives `init.sh` directly; the CLI keeps
  refusing `forge init --archetype ai-native-rag` (exit 3) until `b7-6`.

---

## Resolved scope decisions (from proposal open questions)

- **Q-1 (promotion) → RESOLVED: deferred.** Promotion (stage flip) stays in
  `b7-6-harness` per ADR-B7-1-002 + the b8-3b invariant. See `ADR-B7-2-001`.
- **Q-2 (slicing) → RESOLVED: single change.** `b7-2-scaffolder` ships the full
  backbone (backend + frontend + infra) as one reviewable change (maintainer
  "lance la suite", 2026-06-21 — fallback offered at the proposal gate). See
  `ADR-B7-2-002`.
- **Q-3 (embeddings provider)** and **Q-4 (MCP transport)** → deferred to
  `design.md` (do not block specs).

---

## ADDED Requirements

### Template tree & scaffold plan

- **FR-B7-2-001** — A versioned template tree MUST exist at
  `.forge/templates/archetypes/ai-native-rag/1.0.0/` with the layer roots declared
  by `ai-native-rag/1.0.0.yaml`: `backend/`, `frontend/web-public/`, `infra/`,
  plus `shared/protos/` (Connect SSoT precedent). Every authored file MUST carry
  the `.tmpl` suffix that `init.sh` strips on render.
- **FR-B7-2-002** — A `scaffold-plan` (e.g.
  `.forge/templates/archetypes/ai-native-rag/scaffold-plan.yaml`) MUST drive the
  render, schema-shaped like `scaffold-plan-2.0.0.yaml` (file list, placeholder
  substitutions `{{project_name}}` / `{{reverse_domain}}` / …), and MUST reference
  only files present in the `1.0.0/` tree (no dangling entries).
- **FR-B7-2-003** — Rendering the plan into an empty target via `init.sh --plan`
  MUST produce a tree with **no unsubstituted placeholders** and **no `.tmpl`
  suffix** remaining (grep-asserted by the fixture).

### Backend layer (`FR-BE-`, Vulcan/Rust)

- **FR-B7-2-010** — A Cargo workspace MUST be scaffolded (`backend/Cargo.toml.tmpl`
  + per-crate manifests), `cargo metadata`/`cargo check` clean on the rendered
  tree (L2 fixture, toolchain-gated skip when `cargo` absent).
- **FR-B7-2-011** — An axum service entrypoint MUST be scaffolded, reusing the
  2.0.0 substrate (Connect transport, Temporal, Zitadel/Envoy-OIDC, OTel app SDK)
  by reference — these layers MUST NOT be re-invented (memo §3).
- **FR-B7-2-012** — An **LLM gateway** module MUST be scaffolded as an in-repo thin
  axum proxy (decision A), OpenAI-compatible upstream client, conforming to
  `global/llm-gateway.md`: tier-aware refusal *hooks* (refs I.3 forbidden-components
  + compliance-tiers; the runtime Janus refusal rules themselves stay in
  `b7-9-janus-ai`), prompt-audit span (IX.6), token budget + kill switch (XI.5),
  PII guard (XI.6). A non-AI **fallback** path MUST be present (XI.5,
  `ai_fallback_required: true`).
- **FR-B7-2-013** — An **MCP server** module MUST be scaffolded using `rmcp`,
  conforming to `global/mcp-servers.md`: stdio + streamable-HTTP/axum transport,
  least-privilege, input validation, OAuth 2.1 → Zitadel/Envoy-OIDC. At least one
  stub server (`db` | `file` | `search`) MUST be rendered.
- **FR-B7-2-014** — A **RAG pipeline** module MUST be scaffolded conforming to
  `global/rag-patterns.md`: chunking/embeddings, hybrid retrieval (vector + BM25 +
  RRF), coarse→exact re-ranking, pgvector HNSW access (`vector_cosine_ops`). Heavy
  retrieval/embedding work MUST run as Temporal **activity-only** workers
  (`temporalio-sdk` pre-alpha caveat, memo §6).

### Frontend layer (`FR-FE-`, Hera)

- **FR-B7-2-020** — A Qwik `web-public` surface MUST be scaffolded under
  `frontend/web-public/`, mirroring the flagship 2.0.0 Qwik shell (B.8.9), wired to
  the backend via Connect-ES v2. The **streaming transport detail** (SSE /
  WebTransport) is explicitly OUT (brick `b7-10-streaming`); a non-streaming
  request/response baseline is sufficient here.

### Infra layer (`FR-IN-`, Atlas)

- **FR-B7-2-030** — Infra manifests MUST be scaffolded **reusing** the 2.0.0
  substrate by reference: Postgres+pgvector HNSW init
  (`pgvector:0.8.2-pg17`, B.8.5), Temporal, Zitadel (B.8.7), observability
  (SigNoz/OBI/Coroot, B.8.8). RAG-specific additions are limited to the HNSW index
  definitions + an `llm-gateway` service wiring. No new infra component is introduced.

### Verify-then-pin (Article III.4)

- **FR-B7-2-040** — Before pinning, each external Rust dependency MUST be verified
  LIVE (`cargo add` / crates.io), NOT copied from any note. Targets: `rmcp`
  (resolve the README-0.16.0 / Context7-0.5.0 / LIVE-1.7.0 drift, ADR-B7-3-003),
  `pgvector` (Rust crate, `sqlx` feature), `async-openai` (or the chosen
  OpenAI-compatible client). The resolved versions MUST be recorded in the change.
- **FR-B7-2-041** — All version pins MUST live in the **rendered**
  `Cargo.toml.tmpl` (the consuming template), not in any `global/*.md` standard
  (the B.7.3 standards stay pin-free — `b7-3.test.sh` T-007 no-inline-pin guard
  MUST stay GREEN).

### Scaffolder wrapper & CLI bundle

- **FR-B7-2-050** — `bin/forge-init-ai-native-rag.sh` MUST be replaced from a
  refusing stub to a real init body, with the stable per-archetype ABI
  (`--target` / `--project-name` / `--reverse-domain` / `--force`). It MUST retain
  the J.8 defense-in-depth refusal hook.
  **AMENDED 2026-06-21 (ADR-B7-2-007, maintainer-approved)**: the real body renders
  **directly via `overlay.sh`**, NOT via `init.sh --plan`. Ground-truth discovered
  in Phase 1 (Article III.4): `init.sh` is hardcoded to `full-stack-monorepo`
  (`ARCHETYPE_DIR=...full-stack-monorepo` + `flutter create` + 5 named `cargo new` +
  `buf lint`) and cannot render a second archetype. The ai-native-rag templates are
  self-contained (full `Cargo.toml`s, Qwik not Flutter, no `cargo new` needed), so
  `overlay.sh` (the same renderer the L2 harness uses) is the correct delegate.
  `init.sh` is left **untouched** (zero flagship-regression risk). Making `init.sh`
  archetype-aware was considered and rejected for this brick (shared-infra risk).
- **FR-B7-2-051** — Because the schema stays `candidate`, `forge init --archetype
  ai-native-rag` through the CLI MUST still refuse with **exit 3** (no scaffoldable
  version). The real wrapper body is therefore validated by the fixture invoking
  `init.sh`/the wrapper directly, NOT through the CLI scaffoldable gate. (Promotion
  → `b7-6`.)
- **FR-B7-2-052** — The schema + new templates + scaffold-plan + updated wrapper
  MUST be bundled into `cli/assets` (`npm run bundle`); `cd cli && npm test` MUST
  stay GREEN, with `archetypes-smoke` keeping `ai-native-rag` partitioned as a
  refusing candidate (B.7.2a precedent) and `help-snapshots` regenerated if the
  description changes.

### Harness

- **FR-B7-2-060** — A dedicated harness `.forge/scripts/tests/b7-2.test.sh` MUST be
  added and registered in `.github/workflows/forge-ci.yml`, with L1 (structure /
  plan-coverage / no-stray-placeholder / standards-conformance grep) and L2
  (toolchain-gated `cargo check` on the rendered tree) levels. The comprehensive
  ≥35-test promotion suite stays in `b7-6-harness`.

## Non-Functional

- **NFR-B7-2-001** — Additive: no edit to `archetype.schema.json`,
  `ai-native-rag/1.0.0.yaml` (stays candidate/scaffoldable:false), the B.7.3
  standards, the constitution, or other archetypes' templates. Existing-file edits
  confined to: the wrapper body, `cli/assets` bundle, CI matrix, and the tested CLI
  couplings (cli help/snapshot, archetypes-smoke partition).
  **Scope note (review 2026-06-21)**: `docs/new-archetypes-plan.md` was also edited
  (+§0.12 + §11 T6/T7 resync). That edit is a **separate maintainer-requested task**
  (plan status resync), NOT part of this change's additive deliverable — it is
  committed separately and is out of this NFR's boundary by design.
- **NFR-B7-2-002** — No regression: `verify.sh`, `constitution-linter.sh`,
  `validate-foundations.sh`, `validate-standards-yaml.sh`, `b5.test.sh`,
  `b7-1.test.sh`, `b7-2a.test.sh`, `b7-3.test.sh` all stay GREEN.
- **NFR-B7-2-003** — Rendered backend MUST satisfy the schema's
  `coverage_threshold: 80` design intent: scaffolded modules ship with their test
  scaffolding (TDD-ready), not bare stubs (Article I).
- **NFR-B7-2-004** — Determinism: render of a fixed plan into a fixed target is
  byte-stable across runs (no timestamps/uuids in rendered output beyond
  documented placeholders).

## BDD Acceptance Criteria

```gherkin
Feature: ai-native-rag scaffold backbone (candidate, pre-promotion)

  Scenario: rendering the scaffold-plan produces a clean tree
    Given the ai-native-rag/1.0.0 template tree and scaffold-plan
    When init.sh renders the plan into an empty target directory
    Then the target contains backend/, frontend/web-public/, infra/, shared/protos/
    And no file retains a .tmpl suffix
    And no unsubstituted {{placeholder}} remains

  Scenario: the rendered backend builds
    Given a freshly rendered ai-native-rag target
    When cargo check runs on the backend workspace
    Then it completes without error
    And the llm_gateway, mcp and rag modules are present with test scaffolding

  Scenario: the CLI still refuses init for the candidate archetype
    Given the schema is stage:candidate / scaffoldable:false
    When a user runs forge init --archetype ai-native-rag
    Then the CLI refuses with exit 3 and writes nothing
    And a [REFUSAL ...] message names the archetype as not yet scaffoldable

  Scenario: a non-AI fallback exists for the gateway
    Given the scaffolded LLM gateway module
    When the AI upstream is unavailable
    Then a non-AI fallback path is exercised (Article XI.5)
```

## ADRs (proposed — to ratify at design)

- **ADR-B7-2-001** — Promotion deferred: keep `stage: candidate` /
  `scaffoldable:false` here; the stage flip rides `b7-6-harness` (b8-3b invariant +
  ADR-B7-1-002, B.8.14-C2 pattern). Validate the scaffolder via direct `init.sh`
  fixture, not the CLI scaffoldable gate.
- **ADR-B7-2-002** — Single change (not split `b7-2b`/`b7-2c`): full backbone in one
  reviewable change (maintainer decision 2026-06-21). If review finds it too large,
  carve `b7-2c` (frontend+infra) as a follow-up — recorded, not pre-committed.
- **ADR-B7-2-003** — Pins live only in the rendered `Cargo.toml.tmpl`; standards
  stay pin-free (b8-6/transport.yaml precedent; ADR-B7-3-001).

## Open Questions (for design)

- **Q-3** — Scaffold-default embeddings provider: Mistral-EU API vs local
  Candle/fastembed (T3 ⇒ self-host). Affects `rag` module + `Cargo.toml.tmpl`.
- **Q-4** — MCP stub transport: stdio subprocess vs HTTP axum (or both). Affects
  `mcp` module shape + `mcp-servers.md` conformance assertions.
- **Q-5** — Frontend layer scope: `1.0.0.yaml` declares `frontend.standards_scope:
  [flutter, all]` but the only surface is Qwik `web-public`. Confirm no Flutter
  mobile app ships in this archetype (web-public-only), or flag the schema mismatch.

## Anti-Hallucination Pass

- Every external version is **verify-then-pin LIVE** (FR-B7-2-040), pinned only in
  the consuming template (FR-B7-2-041). No version is asserted from the exploration
  note or this spec.
- The substrate components (pgvector/Temporal/Zitadel/Connect/Qwik/OTel) are
  reused **by reference** to existing B.8 templates + standards, not re-specified.
- `[NEEDS CLARIFICATION]`: none blocking — Q-3/Q-4/Q-5 are design-time, not
  spec-blocking (the FRs are testable without resolving them).

---

**Gate**: Specs written. Review `specs.md`. Next: `/forge:design b7-2-scaffolder`.
