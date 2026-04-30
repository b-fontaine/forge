<!-- Audit: B.1.6 + B.1.7 + B.1.8 (part of b1-workflow) -->
<!-- Stage: draft -->

# Multi-Layer Workflow

This standard activates when `.forge.yaml` declares `schema: full-stack-monorepo`. It governs how changes that span ≥ 2 layers are coordinated, how per-layer deliverables are structured, and how cross-layer contract alignment is enforced. The routing rules defined here are binding from the moment a change's `.forge/changes/<name>/.forge.yaml` declares a `layers:` field with two or more entries; any deviation from the prescribed dispatch chain is a constitutional violation under Article V. Cross-references `monorepo-layout.md` (layer paths and FR-ID prefixes) and `proto-contracts.md` (contract versioning and `buf` gates). The enforcement authority for cross-layer changes is the **Janus** agent (see `/.claude/agents/cross-layer-orchestrator.md`), which acts as the sole cross-layer orchestrator and MUST be the entry point whenever two or more layers are involved.

## Routing Policy

When `/forge:design`, `/forge:implement`, or `/forge:review` is invoked, the dispatcher reads the target change's `.forge/changes/<name>/.forge.yaml` and inspects the `layers:` field to determine the correct orchestrator.

**Single-layer or absent `layers:`:**

- **MUST** — when `layers:` is absent, or contains exactly 0 or 1 entry, dispatch directly to the single-layer orchestrator that owns the declared layer:
  - `frontend` → **Hera** (Flutter Team Orchestrator, see `/.claude/agents/flutter/orchestrator.md`)
  - `backend` → **Vulcan** (Rust Team Orchestrator, see `/.claude/agents/rust/orchestrator.md`)
  - `infra` → **Atlas** (Infra Architect, see `/.claude/agents/atlas.md`)
  - No `layers:` field and `schema:` is not `full-stack-monorepo` → **forge-master** (default orchestrator)

**Multi-layer (`layers:` has ≥ 2 entries):**

- **MUST** — dispatch to **Janus** (cross-layer orchestrator, see `/.claude/agents/cross-layer-orchestrator.md`). This rule has no exceptions. Sending a multi-layer change directly to Hera, Vulcan, or Atlas bypasses Janus's cross-layer coherence checks and constitutes a constitutional violation (Article V).
- **MUST** — Janus NEVER writes application code, edits files under `frontend/`, `backend/`, `infra/`, or `shared/protos/` directly. Its role is exclusively to dispatch, aggregate outputs, and flag conflicts. Code changes are performed by Janus's per-layer specialists (Hera / Vulcan / Atlas / Hermes-API).

**Routing trace:**

- **SHALL** — the dispatcher MUST log a one-line `ROUTE: <change> → <orchestrator>` trace before handing off, e.g. `ROUTE: user-sign-in → Janus`. This trace is the auditability record for the routing decision and is referenced in the workflow harness (FR-GL-023).

## .forge.yaml Multi-Layer Schema

The per-change `.forge.yaml` file (located at `.forge/changes/<name>/.forge.yaml`) is extended with three new optional top-level fields. These fields are defined by FR-GL-016 and validated by FR-GL-017.

**`layers:`** — An ordered list of layer ids. Each id **MUST** be a member of the archetype schema's `layers[].id` set (currently `backend`, `frontend`, `infra`). An unknown layer id causes the FR-GL-017 validator check to FAIL. This field is optional; its absence is backwards-compatible with every pre-b1-workflow change.

**`designs_per_layer:`** — A map keyed by layer id, where each value is a filename relative to the change directory (e.g. `design-backend.md`). This field is **required** when `layers:` has ≥ 2 entries. Map shape per ADR-002: explicit string keys matching the entries in `layers:`, enabling O(1) lookup in the validator. Missing or empty value for any declared layer causes a validator FAIL.

**`tasks_per_layer:`** — A map keyed by layer id, where each value is a filename relative to the change directory (e.g. `tasks-backend.md`). Same trigger and same constraints as `designs_per_layer:`. Required when `layers:` has ≥ 2 entries.

The complete YAML for a realistic cross-layer change is:

```yaml
name: user-sign-in
status: designed
schema: default
constitution_version: "1.0.0"
layers:
  - backend
  - frontend
designs_per_layer:
  backend: design-backend.md
  frontend: design-frontend.md
tasks_per_layer:
  backend: tasks-backend.md
  frontend: tasks-frontend.md
timeline:
  proposed: 2026-05-01
  specified: 2026-05-02
  designed: 2026-05-03
```

**Fallback — single-layer and pre-b1-workflow changes:**

When `layers:` is absent OR contains exactly 1 entry, the existing single-file convention applies unconditionally: one `design.md` and one `tasks.md` in the change directory, exactly as before b1-workflow. The validator emits `PASS: FR-GL-017 — single-layer change — no per-layer files expected` and performs no further checks. This ensures 100% backwards compatibility with every change authored prior to this standard. Layer paths are resolved dynamically from `schema.yaml layers[].path` per ADR-004, so adopters who customize the layout (e.g. rename `backend/` to `server/`) get correct resolution at no extra cost.

## Per-Layer Design Convention

Each per-layer design file (e.g. `design-backend.md`, `design-frontend.md`) is a full design document scoped to a single layer. It mirrors the canonical sections of the shared `design.md` template: ADRs, Component Design, Data Flow, Testing Strategy, Standards Applied, Security Considerations, Observability Plan.

**Layer declaration header:**

- **MUST** — every per-layer design file MUST start with the HTML comment `<!-- Layer: <id> -->` on its first line (e.g. `<!-- Layer: backend -->`). This comment is the machine-readable marker used by the FR-GL-017 validator and the `check_standard_multi_layer_workflow` check.

**Cross-layer traceability:**

- **MUST** — the first section after the title MUST be `## Cross-Layer References`, which lists every `FR-GL-*` requirement this layer slice satisfies, plus the sibling `FR-BE-*` / `FR-FE-*` / `FR-IN-*` requirements it implements. This section is the bidirectional traceability link (see `monorepo-layout.md § Préfixes FR-ID`).

**Standards scope:**

- **SHALL** — per-layer designs MUST reference standards via the layer's own `CLAUDE.md` (e.g. `frontend/CLAUDE.md` for the frontend slice, `backend/CLAUDE.md` for the backend slice), NOT via the root `CLAUDE.md`. This preserves the JIT-loading isolation described in `monorepo-layout.md § CLAUDE.md imbriqués` and prevents cross-contamination of Flutter and Rust standards (Article VI.2, Article VII.3).

Example skeleton for a backend per-layer design:

```markdown
<!-- Layer: backend -->

# Design (backend) — user-sign-in

## Cross-Layer References

- FR-GL-012 — User sign-in flow (parent requirement)
- FR-BE-034 — gRPC AuthService.SignIn handler + JWT issuance
- FR-IN-005 — Kong route and rate-limit policy for /auth/* (dependency)

## Architecture Decisions

### ADR-001: JWT issued in domain layer, not in gRPC adapter
...

## Component Design
...

## Data Flow
...

## Testing Strategy
...

## Standards Applied
...

## Security Considerations
...

## Observability Plan
...
```

## Per-Layer Tasks Convention

Per-layer tasks files (e.g. `tasks-backend.md`, `tasks-frontend.md`) follow the standard Forge tasks format with one mandatory extension: phase headings MUST carry the layer name as a prefix (ADR-010).

**Phase numbering:**

- **MUST** — phase headings use the format `<Layer> Phase N` where `<Layer>` is the title-cased layer name: `Backend Phase 1`, `Frontend Phase 1`, `Infra Phase 1`. This convention prevents the common ambiguity of "Phase 2 is failing — which layer?" in cross-layer review discussions. Numbering restarts at 1 for each layer's own file.

**FR-ID tagging:**

- **MUST** — every task MUST carry a `[Story: FR-<prefix>-XXX]` tag using the layer-appropriate prefix from the archetype schema (`FR-BE-` for backend tasks, `FR-FE-` for frontend tasks, `FR-IN-` for infra tasks, `FR-GL-` for tasks that span layers). Tasks without a traceable FR-ID are rejected by the `/forge:plan` constitutional compliance gate (Article V.1).

**TDD ordering:**

- **SHALL** — TDD ordering applies per-layer within each layer's phases: test tasks precede implementation tasks within each `<Layer> Phase N` block, mirroring the RED → GREEN → REFACTOR cycle mandated by `global/tdd-rules.md`.

Example fragment from `tasks-backend.md` for the `user-sign-in` change:

```markdown
## Backend Phase 1 — Auth domain + gRPC stub

- [ ] [Story: FR-BE-034] Write failing test for `AuthService::sign_in` — invalid credentials returns `Unauthenticated` [RED]
- [ ] [Story: FR-BE-034] Implement `AuthService::sign_in` domain logic — JWT issuance on valid credentials [GREEN]
- [ ] [Story: FR-BE-034] Refactor: extract `JwtFactory` value object, zero `unwrap()` in production path [REFACTOR]

## Backend Phase 2 — gRPC adapter + tonic wiring

- [ ] [Story: FR-BE-034] Write failing integration test for gRPC `AuthService.SignIn` RPC [RED]
- [ ] [Story: FR-BE-034] Wire tonic service implementation, update `bin-server` composition root [GREEN]
```

## Cross-Layer Contract Alignment

Janus is responsible for verifying that the per-layer deliverables produced by Hera, Vulcan, and Atlas are mutually coherent before a cross-layer change is considered designed, implemented, or reviewed. This responsibility is non-delegable: Janus MUST perform these checks at every phase where cross-layer artifacts are produced. Specific technical sub-steps are delegated to Hermes-API (proto diffs), Aegis (security boundary), Nemesis (Flutter quality), and Tribune (Rust quality) as described below.

**Interface coherence:**

- **MUST** — what the backend exposes (gRPC service signatures, proto message shapes, error codes) MUST be identical to what the frontend consumes. Mismatches — for example a versioned proto package in the backend (`myapp.auth.v1`) that differs from what the Flutter generated stubs import — are surfaced by Janus as `[NEEDS CLARIFICATION: <description>]` markers (Article V.3). Janus NEVER silently resolves a contract mismatch.

**Shared DTO consistency:**

- **MUST** — if a cross-layer change introduces or modifies a shared type (a proto message consumed by both layers), its fields, field numbers, and validation rules MUST be identical across all consumers. The proto definition in `shared/protos/` is the authoritative source of truth (per `global/proto-contracts.md`); hand-rolled DTOs that duplicate or shadow a proto-defined message are prohibited (Article IX.4). See also `proto-contracts.md § Interdictions`.

**Env contract consistency:**

- **MUST** — `.env.example` variables referenced by the backend's `env_file:` configuration MUST match what the frontend's runtime config expects. Undeclared or misnamed environment variables surface as a Janus `[NEEDS CLARIFICATION]` during the design phase, not at runtime.

**Versioning coherence:**

- **MUST** — cross-layer changes MUST use the release-train or per-package versioning model declared in the root `.forge.yaml` (`versioning_model:`). Mixed versioning strategies within the same cross-layer change (e.g. patch bump on the backend while a minor bump is required by the frontend proto addition) are a conflict that Janus surfaces before the change advances to implementation.

**Explicit delegation:**

- **Proto diffs** → Hermes-API. Janus invokes Hermes-API in its Step 8 ("Contract Alignment") whenever the change touches any file under `shared/protos/`. Janus collects Hermes-API's `buf breaking` verdict and propagates FAIL to the overall cross-layer report. This delegation is per ADR-003 and preserves Hermes-API's authority as the proto-contract owner (`proto-contracts.md § Gates CI`).
- **Security boundary** → Aegis. Janus invokes Aegis in its Step 9 for any change that modifies proto fields carrying auth tokens, tenant identifiers, or permission scopes (Article IX.4).
- **Flutter quality gate** → Nemesis. Janus requires a Nemesis green status on `frontend/` before marking a cross-layer change complete (Article VI.2).
- **Rust quality gate** → Tribune. Janus requires a Tribune green status on `backend/` before marking a cross-layer change complete (Article VII.3).

## Interdictions

The following rules are non-negotiable for `full-stack-monorepo` projects. Each violation MUST be treated as a constitutional violation under Article V.2 and blocks merge.

- **No direct dispatch to a per-layer orchestrator when `layers:` has ≥ 2 entries** — bypassing Janus when two or more layers are declared skips the cross-layer coherence checks (interface alignment, shared DTO consistency, versioning coherence) that Janus is solely responsible for. Routing Hera or Vulcan directly on a multi-layer change is a process violation regardless of whether the code itself is correct.

- **No single `design.md` or `tasks.md` when `layers:` has ≥ 2 entries** — the per-layer files (`design-backend.md`, `design-frontend.md`, etc.) declared in `designs_per_layer:` and `tasks_per_layer:` are the sources of truth for multi-layer changes. A single `design.md` or `tasks.md` at the change root is silently ignored by the validator when per-layer files are present; relying on it is misleading and constitutes an incompleteness violation that fails the FR-GL-017 check.

- **No cross-layer code (e.g. `backend/crates/domain/src/` importing Flutter types)** — already interdicted by `global/monorepo-layout.md § Interdictions`; repeated here for emphasis. The only sanctioned cross-layer communication channel is the gRPC contract defined in `shared/protos/`. Any direct file, package, or type import across the `frontend/` ↔ `backend/` boundary is prohibited and makes independent deployment impossible.

- **No proto-contract changes without Hermes-API review** — Janus MUST dispatch to Hermes-API in Step 8 whenever any file under `shared/protos/` is touched by the change. Skipping this dispatch voids the `buf breaking` gate (`proto-contracts.md § Gates CI`) and constitutes a security-surface violation under Article IX.4.

- **No Janus step skipping** — all 12 steps of Janus's workflow (see `/.claude/agents/cross-layer-orchestrator.md § 12-Step Workflow`) SHALL execute for every cross-layer change. Skipping one or more steps requires an explicit approved deviation recorded in the change's `proposal.md`, signed off by the project's constitutional compliance authority. Undocumented step skipping is a constitutional violation under Article V and Article X.
