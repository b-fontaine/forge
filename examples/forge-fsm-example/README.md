<!-- Audit: C.1 (c1-reference-project — overrides B.1.2 README template) -->

# forge-fsm-example

Reference project demonstrating the Forge framework's
`full-stack-monorepo` archetype : a Flutter frontend + a Rust
backend + Kustomize-based Kubernetes infra + Kong API gateway +
local OpenTelemetry / SigNoz observability stack, with Protobuf
contracts as the single source of truth across layers.

This tree is **inspectable artefact**, not a starter template. It
exists to show adopters what a Forge-conformant project looks like
end-to-end : real proposals, real specs (with delta semantics),
real designs (with ADRs), real tasks (TDD-ordered), and real
archived demo changes.

## How this example was built

This tree was generated **verbatim** by running the Forge
scaffolder on a clean directory, then committed to the Forge repo.
The exact reproduction commands are :

```bash
# From the Forge framework repo root :
bash .forge/scripts/scaffolder/init.sh forge-fsm-example \
  --org io.forge.example \
  --target-dir examples/forge-fsm-example
```

The scaffolder runs the non-negotiable 7-step sequence (per
b1-scaffolder's `FR-GL-011`) : argument validation → tool version
checks (Flutter ≥ 3.24 / Cargo ≥ 1.80 / Buf ≥ 1.30) → framework
asset copy → `flutter create frontend` → archetype overlay (39
templates) → `cargo new` for the 5 hexagonal crates → `buf lint`
seed protos → `validate-foundations.sh`.

The exact tool versions used at scaffold time are recorded in
`.forge/scaffold-manifest.yaml` (`tools.flutter`, `tools.cargo`,
`tools.buf` — see FR-EX-001).

After the scaffolder completed, the four demo changes under
`.forge/changes/demo-*` were authored through the standard Forge
pipeline (`/forge:new` → `/forge:specify` → `/forge:design` →
`/forge:plan` → `/forge:implement` → `/forge:archive`).

## What's in here

The canonical `full-stack-monorepo` layout from
`.forge/standards/global/monorepo-layout.md` :

| Path | What lives here | Standard |
|---|---|---|
| `frontend/` | Flutter application — Clean Architecture + FSD | `flutter/architecture.md` |
| `backend/` | Rust Cargo workspace — 5 hexagonal crates | `rust/architecture.md` |
| `infra/` | Kubernetes (Kustomize base + dev/staging/prod overlays), Kong, Docker, OTel/SigNoz observability | `infra/k8s-overlays.md`, `infra/observability-local.md` |
| `shared/protos/` | Buf workspace + v1 example proto, single source of truth for cross-layer contracts | `global/proto-contracts.md` |
| `.forge/` | Forge framework assets : constitution + standards + change history | — |
| `.claude/` | Claude Code skills + agent routing (Hera / Vulcan / Atlas / Janus) | — |
| `.github/workflows/` | The 4 reference workflows from b1-delivery (`forge-backend.yml`, `forge-frontend.yml`, `forge-infra.yml`, `forge-integration.yml`) | `infra/ci-workflows.md` |
| `Taskfile.yml` | Canonical task runner — entry point for all build/test/lint/release ops | — |
| `docker-compose.dev.yml` | Local dev stack incl. backend + Kong + Postgres + OTel collector + SigNoz | `infra/docker-compose.md`, `infra/observability-local.md` |

Routing rules for Claude Code are documented in the root
`CLAUDE.md`. Each layer's `CLAUDE.md` (under `frontend/`,
`backend/`, `infra/`) loads ONLY that layer's standards via JIT
loading — no context saturation across stacks.

## Demo changes

Under `.forge/changes/`, four demo changes show the change
lifecycle in practice. Read them in numerical order — they form a
narrative.

| Demo | Layers | Status | What it demonstrates |
|---|---|---|---|
| [`demo-001-greeting-service`](.forge/changes/demo-001-greeting-service/) | `[backend]` | archived | Single-layer backend change — gRPC `Greeter` service with hexagonal Rust, proto-first design, BDD via cucumber-rs |
| [`demo-002-greeting-screen`](.forge/changes/demo-002-greeting-screen/) | `[frontend]` | archived | Single-layer frontend change — Flutter screen consuming demo-001's contract via Cubit + `flutter_bloc`, widget test, golden test |
| [`demo-003-rate-limit`](.forge/changes/demo-003-rate-limit/) | `[backend, infra]` | archived | Multi-layer change triggering Janus orchestration — Kong rate-limit plugin with per-layer designs (`design-backend.md` + `design-infra.md`) and tasks (`tasks-backend.md` + `tasks-infra.md`) |
| [`demo-004-user-onboarding`](.forge/changes/demo-004-user-onboarding/) | `[backend, frontend, protos]` | **specified** | In-flight spec demonstrating `[NEEDS CLARIFICATION]` markers (Article III.4) — purposely never advanced past the spec phase to show what a "live spec" looks like |
| [`demo-005-connect-greeting`](.forge/changes/demo-005-connect-greeting/) | `[backend]` | archived | Single-layer backend change shipped by `t5-connect-codegen` — exposes the existing Greeter via Connect-RPC at `/connect`, with a TypeScript reference client under [`clients/connect-client.ts`](clients/connect-client.ts) seeding a W3C `traceparent` header per call. Validates the Connect codec end-to-end without retiring the tonic gRPC path |

A short summary of each demo with its archive date is also
maintained at [`.forge/changes/MANIFEST.md`](.forge/changes/MANIFEST.md).

The deliberate triviality of these demos (greeting, rate-limit,
onboarding) is by design : the example's value is the **process
artefacts**, not the product. See `proposal.md` of each demo for
the framing.

## Reproducing this example

To reproduce the example tree from scratch :

1. **Clone the Forge repo and prepare tools.**

   Required versions (per `b1-scaffolder` NFR-008) :
   - Flutter ≥ 3.24
   - Cargo ≥ 1.80
   - Buf ≥ 1.30
   - Bash ≥ 3.2 (the scaffolder is POSIX-friendly)

2. **Run the scaffolder** (from the Forge framework repo root) :

   ```bash
   bash .forge/scripts/scaffolder/init.sh forge-fsm-example \
     --org io.forge.example \
     --target-dir <some-clean-dir>
   ```

   The scaffolder writes a `.forge/scaffold-manifest.yaml`
   recording the exact tool versions and content hashes — useful
   for byte-equivalence verification.

3. **Diff against the committed example.**

   The committed `examples/forge-fsm-example/` tree is the
   verbatim output of the scaffolder above, plus the four demo
   changes. The four demos are authored on top of the scaffolder
   output — the scaffolder itself does not produce them.

4. **Run the example's gates locally** :

   ```bash
   cd examples/forge-fsm-example
   bash .forge/scripts/verify.sh
   bash .forge/scripts/constitution-linter.sh
   ```

   Both gates exit 0. CI runs the same gates via the example's
   four reference workflows under `.github/workflows/` whenever a
   PR touches this tree (gated by the Forge framework's own
   `forge-ci.yml` `example` job — see FR-CI-012).

5. **Run the local stack** :

   ```bash
   cp .env.example .env
   task dev:up
   ```

   The compose file boots backend + Kong + Postgres + OTel
   collector + SigNoz. Open <http://localhost:3301> for the
   SigNoz UI.

## Environment configuration

<!-- Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation -->

Both layers (Rust backend + Flutter frontend) honour the W3C OpenTelemetry
SDK environment variable names. Per ADR-T5-OTA-007, no Forge-prefixed env
var is introduced — adopters who already run an OTel stack at home
recognise every name. Defaults match the in-cluster Phase A collector
(`infra/observability/otel-collector-config.yaml` :4318 HTTP receiver).

| Variable | Default | Purpose |
|---|---|---|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://fsm-otel-collector:4318` | OTLP HTTP/protobuf collector base URL (ADR-T5-OTA-002 — both layers HTTP/protobuf, port 4318). |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` | Wire format ; symmetric with the Rust + Flutter exporters. |
| `OTEL_SERVICE_NAME` | `fsm-backend` / `fsm-frontend` | Per-layer service identity ; populates the `service.name` resource attribute. Set in each app's process env. |
| `OTEL_RESOURCE_ATTRIBUTES` | `service.namespace=forge-fsm,service.instance.id=local` | Comma-separated `key=value` list passed through to the resource builder. **NEVER PUT SECRETS HERE** (FR-T5-OTA-010 / NFR-T5-OTA-006 — privacy / data minimisation). |
| `OTEL_TRACES_SAMPLER` | `parentbased_traceidratio` | Sampler shape per ADR-T5-OTA-003 (`ParentBased(TraceIdRatioBased(rate))` on both layers). |
| `OTEL_TRACES_SAMPLER_ARG` | `1.0` | Head-side ratio ; the Phase A collector reduces to env-tier ratio downstream. |
| `DEPLOYMENT_ENV` | `dev` | Forge-specific tier (`dev` / `staging` / `prod`) ; populates `deployment.environment` and flips `insecure: true|false` in the Flutter exporter. |

The Flutter mobile build pipeline reads these via
`--dart-define=KEY=VALUE` (forwarded by `flutter run` and `flutter build`).
Native env-var reading on mobile is deferred to a future change
(ADR-T5-OTA-007 Consequences).

To trace the full demo-005 round trip in SigNoz, see
[`docs/demo-005-connect-greeting.md`](docs/demo-005-connect-greeting.md)
§ "Trace this in SigNoz".
