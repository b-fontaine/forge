<!-- Audit: B.1.5 (part of b1-foundations) -->
<!-- Stage: draft -->

# Monorepo Layout

This standard activates when the root `.forge.yaml` declares `schema: full-stack-monorepo`. It defines the canonical directory tree for projects that combine a Flutter frontend, a Rust backend, and shared infrastructure under a single repository root. The layout is designed to make layer boundaries visible in the file system, enabling both human developers and AI agents to infer architectural intent from directory structure alone. Adherence to this layout is REQUIRED; deviations MUST be justified as a Forge change proposal and ratified before being introduced into the repository. The isolation rules between layers defined here are non-negotiable and are enforced at the Constitutional level (Articles V, VI, VII, and VIII).

## Arborescence

The canonical directory tree for a `full-stack-monorepo` project is as follows:

```plaintext
<project-root>/
├── frontend/                    # Flutter application
│   ├── lib/                     # Dart source code
│   ├── test/                    # Flutter unit, widget, and BDD tests
│   ├── pubspec.yaml             # Dart package manifest
│   └── CLAUDE.md                # Flutter-scoped agent context
│
├── backend/                     # Rust Cargo workspace
│   ├── crates/
│   │   ├── domain/              # Pure domain logic — zero external deps
│   │   ├── application/         # Use cases orchestrating domain ports
│   │   ├── grpc-api/            # tonic gRPC service implementations
│   │   ├── infrastructure/      # Config, DB pool, telemetry bootstrap
│   │   └── bin-server/          # Binary crate — wires everything together
│   └── CLAUDE.md                # Rust-scoped agent context
│
├── infra/                       # Infrastructure configuration
│   ├── kong/                    # Kong declarative config (deck / YAML)
│   ├── k8s/
│   │   ├── base/                # Kustomize base manifests
│   │   └── overlays/            # Per-environment overlays (dev, staging, prod)
│   ├── temporal/                # Temporal worker & workflow definitions
│   ├── docker/                  # Dockerfiles and build contexts
│   └── CLAUDE.md                # Infra-scoped agent context
│
├── shared/
│   └── protos/                  # Protobuf source of truth
│       ├── buf.yaml             # Buf CLI workspace config
│       ├── buf.gen.yaml         # Code-generation targets (Dart + Rust)
│       ├── v1/                  # Stable API surface — breaking changes forbidden
│       └── v2/                  # Next major API surface (additive only until cut)
│
├── .forge/                      # Forge framework assets
├── .claude/                     # Claude Code skills and settings
├── .mcp.json                    # MCP server configuration (Context7, etc.)
├── Taskfile.yml                 # Task runner — canonical entry point for all ops
├── docker-compose.dev.yml       # Local development compose (env suffix required)
├── .forge.yaml                  # Project metadata, schema declaration
└── CLAUDE.md                    # Root cross-cutting agent context
```

**`frontend/`** — Contains the entire Flutter application.
Its internal structure MUST follow Clean Architecture combined with Feature-Sliced Design as mandated by Article VI of the Constitution; in particular, Article VI.2 requires that features be organised as self-contained modules with lazy loading and that no module may import from another module's internal layers.
The `lib/` tree is the only Dart source; generated proto stubs are placed under `lib/generated/protos/` and MUST NOT be edited by hand.
The `test/` tree mirrors the `lib/` structure and MUST contain unit, widget, BDD, and golden tests per Articles I and II.
The presence of its own `CLAUDE.md` limits agent context loading to Flutter-specific standards whenever Claude Code is working within this subtree, preventing context saturation from unrelated Rust or infra rules.

**`backend/`** — A Cargo workspace whose crate members map directly onto the Hexagonal Architecture layers required by Article VII of the Constitution (see `.forge/standards/rust/architecture.md`).
The `domain` crate is a pure Rust library with zero external dependencies outside the standard library and `thiserror`; it defines entities, value objects, and port traits that all other crates depend on.
The `application` crate implements use cases by orchestrating domain ports — it MUST NOT reference any concrete adapter or infrastructure type.
The `grpc-api` crate contains tonic service implementations and the generated Rust proto stubs; generated files under `crates/grpc-api/src/generated/` MUST NOT be edited by hand.
The `bin-server` crate is the sole binary and the composition root where all dependency injection wiring occurs.
Error handling across all crates MUST comply with Article VII.3 — library crates use `thiserror`, application crates use `anyhow`, and `unwrap()` or `panic!()` are prohibited in production code paths.

**`infra/`** — All infrastructure-as-code assets, version-controlled per Article VIII.5.
Kong configuration (under `infra/kong/`) drives REST↔gRPC transcoding at the gateway layer (Article VIII.1); no transcoding logic SHALL appear in application code.
Kubernetes manifests use Kustomize overlays (`k8s/base/` plus `k8s/overlays/<env>/`) to separate base configuration from environment-specific concerns, ensuring that a change to a base manifest propagates consistently across all environments.
Temporal workflow definitions and worker registrations live under `infra/temporal/`, keeping long-running orchestration logic separate from the domain and application layers.
Docker build contexts for each service are maintained under `infra/docker/` and MUST use multi-stage builds with distroless production images per Article VIII.3.

**`shared/protos/`** — The single source of truth for all inter-layer contracts.
Protocol Buffer definitions here drive code generation for both `frontend/lib/generated/protos/` (Dart, via `buf generate`) and `backend/crates/grpc-api/src/generated/` (Rust, via `tonic-build`).
The `buf.yaml` workspace and `buf.gen.yaml` generation targets MUST be kept in sync with the crate and package manifests that consume them.
The `v1/` directory contains the stable API surface; breaking changes to messages or service definitions in `v1/` are forbidden without a major version bump coordinated through a `FR-GL-XXX` change proposal.
See `.forge/standards/global/proto-contracts.md` for versioning rules, breaking-change policy, and the `buf breaking` CI gate.

**`.forge/` and `.claude/`** — Framework-level assets managed by Forge itself.
`.forge/` holds the constitution, standards, change specs, and project metadata.
`.claude/` holds Claude Code skills and agent routing configuration.
These directories MUST NOT contain any stack-specific configuration, standards, or code; they are shared across all stacks and must remain portable across Forge upgrades.
See the `## Interdictions` section below for the explicit prohibition.

**Root files** — `Taskfile.yml` is the canonical task runner; all CI pipelines and developer workflows MUST invoke tasks defined here rather than calling build tools directly, ensuring a single authoritative interface for build, test, lint, generate, and deploy operations.
`docker-compose.dev.yml` provides a reproducible local development environment; the `dev` suffix is mandatory (see `## Interdictions`).
`.forge.yaml` declares the project schema and is the activation trigger for this standard.
The root `CLAUDE.md` provides cross-cutting agent context as described in `## CLAUDE.md imbriqués`.

## Interdictions

The following rules are non-negotiable. A violation MUST be treated as a constitutional violation under Article V.2 and blocks merge. Each rule is accompanied by a rationale; understanding the "why" is as important as knowing the "what," because it enables correct judgment in edge cases not explicitly covered below.

- **No cross-imports between `frontend/` and `backend/`** outside the generated proto stubs in `shared/protos/`. The only sanctioned communication channel between the two stacks is the gRPC contract defined in `shared/protos/`; any direct file or package import across the boundary bypasses the contract layer and makes independent deployment impossible.

- **No direct database access from `frontend/`**. The Flutter application SHALL communicate exclusively with the backend via gRPC. Direct database drivers, connection strings, or SQL embedded in Dart code are prohibited; any such dependency reveals a layer violation that MUST be resolved before the code is merged.

- **No `docker-compose.yml` without an environment suffix**. Compose files MUST carry a suffix that declares their target environment (`docker-compose.dev.yml`, `docker-compose.test.yml`, etc.); a bare `docker-compose.yml` is ambiguous and has historically caused production incidents by being applied in the wrong context.

- **No manual edits to generated proto stubs**. The files under `frontend/lib/generated/protos/` and `backend/crates/grpc-api/src/generated/` are outputs of `buf generate` and MUST be regenerated, not hand-edited. Manual edits are silently overwritten on the next generation pass, creating divergence that is difficult to detect and dangerous in production.

- **No stack-specific code or configuration under `.forge/` or `.claude/`**. These directories are framework assets shared across all stacks. Placing Flutter pubspec snippets, Rust Cargo patches, or Kubernetes manifests there breaks the clean separation between the framework layer and the project layer, making framework upgrades error-prone.

- **No API endpoints exposed directly from `backend/bin-server/` without a Kong route declaration in `infra/kong/`**. Services MUST NOT be accessed directly from the Flutter client; all traffic MUST flow through the Kong gateway. This ensures that authentication, rate-limiting, and REST↔gRPC transcoding policies are applied uniformly and cannot be bypassed by pointing the client at an internal port.

## CLAUDE.md imbriqués

Claude Code supports Just-in-Time (JIT) loading of `CLAUDE.md` files: when the agent navigates into a subdirectory, it automatically appends the nearest `CLAUDE.md` in that subtree to its active context. This monorepo layout exploits that mechanism to deliver precisely the right agent context without saturating the context window with irrelevant standards.

**Root `CLAUDE.md`** — Defines cross-cutting policies that apply regardless of which stack is being worked on:
Forge pipeline rules, the constitutional compliance gate, PR conventions, task runner usage,
and routing logic that directs the agent to the correct sub-team.
The root `CLAUDE.md` MUST NOT import or inline Flutter-specific, Rust-specific, or infra-specific standards;
those belong in their respective subdirectory files.

**`frontend/CLAUDE.md`** — Scoped exclusively to Flutter standards.
It MUST reference or embed the relevant entries from `.forge/standards/flutter/` and SHOULD explicitly activate
the Hera orchestrator and her sub-agents (Athena for architecture, Apollo for UX, Spartan for TDD/BDD, Nemesis for quality gating).
This file is loaded automatically by Claude Code whenever the agent's working path is within `frontend/`,
ensuring that Flutter-specific rules are always present and Rust or infra rules are absent.
It MUST cite Article VI.2 of the Constitution (Clean Architecture module structure and lazy-loading isolation)
as the binding authority for feature organisation.

**`backend/CLAUDE.md`** — Scoped exclusively to Rust standards.
It MUST reference the relevant entries from `.forge/standards/rust/` and SHOULD explicitly activate
the Vulcan orchestrator and his sub-agents (Ferris for architecture, Centurion for TDD/BDD, Tribune for quality gating).
Loaded automatically when the agent's working path is within `backend/`.
It MUST cite Article VII.3 of the Constitution (error handling with `thiserror` / `anyhow`,
prohibition of `unwrap()` in production paths) as a binding constraint that Tribune enforces
before any crate is considered complete.

**`infra/CLAUDE.md`** — Scoped exclusively to infrastructure standards.
It MUST reference `.forge/standards/infra/` entries for Kong, Kubernetes, Temporal, and Docker,
and SHOULD activate the Atlas agent.
Loaded automatically when the agent's working path is within `infra/`.

Without this nesting strategy, the root `CLAUDE.md` would need to carry the complete Flutter standard set,
the complete Rust standard set, and the complete infra standard set simultaneously.
That aggregate easily exceeds the useful portion of the LLM's context window, dilutes the signal-to-noise ratio,
and increases the probability of the agent applying the wrong stack's rules.
JIT-loaded nested `CLAUDE.md` files eliminate this risk by construction:
only the standards relevant to the current working directory are ever in context.

## Préfixes FR-ID

Requirement identifiers in this monorepo use a structured prefix scheme that encodes the layer the requirement belongs to. Identifiers follow the pattern `FR-<LAYER>-<NNN>` where `<NNN>` is a zero-padded three-digit sequence number scoped to the layer.

| Prefix | Layer | Example |
|--------|-------|---------|
| `FR-BE-XXX` | Backend — Rust crates under `backend/` | `FR-BE-042` |
| `FR-FE-XXX` | Frontend — Flutter code under `frontend/` | `FR-FE-017` |
| `FR-IN-XXX` | Infrastructure — assets under `infra/` and `shared/protos/` | `FR-IN-008` |
| `FR-GL-XXX` | Global / cross-layer — requirements spanning two or more layers | `FR-GL-003` |

Identifiers are assigned sequentially and MUST NOT be reused, even after a requirement is removed. Removed requirements SHALL be annotated as `[DEPRECATED]` in the specs document and archived via the Forge change lifecycle (Article IV.4).

### Cross-Layer Changes

When a single functional requirement touches more than one layer — for example, adding a new gRPC endpoint that requires a new Protobuf message, a Rust handler, and a Flutter screen — the change MUST be declared as a `FR-GL-XXX` requirement at the cross-layer level. The `FR-GL-XXX` requirement captures the user-visible intent and MUST reference the per-layer child requirements that refine it.

**Format:**

```text
FR-GL-012 — User sign-in flow
  Delegated: FR-BE-034 (gRPC AuthService.SignIn handler + JWT issuance)
           , FR-FE-078 (sign-in screen, BLoC, and proto client integration)
           , FR-IN-005 (Kong route and rate-limit policy for /auth/*)
```

The `FR-GL-XXX` requirement is the acceptance criterion owner: it is not considered implemented until all delegated child requirements are themselves implemented, their tests pass, and the Nemesis (Flutter) and Tribune (Rust) quality gates report green. Per-layer specs reference the parent `FR-GL-XXX` so that traceability is bidirectional.

### Règles de nommage

Requirement titles SHOULD be written in English to maintain consistency with code symbols and commit messages. The title MUST be a noun phrase that describes the capability from the user's perspective, not the technical solution. Avoid implementation details in requirement identifiers — `FR-FE-078 — Sign-in screen` is preferred over `FR-FE-078 — BLoC for AuthEvent.SignInRequested`.

Proto message and service names defined in `shared/protos/` SHOULD be considered `FR-IN-XXX` scope when they introduce a new contract surface, and referenced from the `FR-BE-XXX` and `FR-FE-XXX` requirements that consume them. This makes the proto layer a first-class citizen in the requirement traceability chain, not an invisible implementation detail.

### Enforcement

The `/forge:plan` command (Article V.1) MUST verify that every task in a planned change has a corresponding `FR-ID` before generating a task list. Tasks without a traceable requirement identifier SHALL be rejected. This check is performed automatically as part of the constitutional compliance gate and cannot be bypassed.
