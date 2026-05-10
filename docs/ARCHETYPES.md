# Forge Archetypes — Decision Matrix

<!-- Audit: B.5.1 (b5-1-init-wizard, FR-IW-009) -->

This document is the public-facing decision matrix for picking
a Forge archetype. Each archetype is a curated combination of
schema, standards, and scaffolded tree designed for one type of
project. Pick one before running `forge init`.

For the canonical contract of each archetype, see the
corresponding spec under `.forge/specs/`. For the dispatcher
itself, see `.forge/standards/global/scaffolding.md`.

## Available archetypes

| Archetype             | Status        | Persona                                                           | When to pick                                                                                                                                                                | Stack                                                                                                                        | Since | Spec                                                               |
|-----------------------|---------------|-------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|-------|--------------------------------------------------------------------|
| `default`             | Active        | Generic projects, framework dog-fooding                           | You want minimal Forge install with no language-specific scaffold ; you'll write your own structure on top                                                                  | Any (Forge framework only)                                                                                                   | 0.1.0 | `default/schema.yaml`                                              |
| `full-stack-monorepo` | Active        | Full-stack teams shipping Flutter clients + Rust backend services | You're building a product app + a backend service + need shared protos as a single source of truth across both                                                              | Flutter + Rust + Infra (Kustomize / Kong / OTel + OBI eBPF + Coroot + SigNoz). **From v0.4.0-rc.x onward (T.5 `t5-connect-codegen`)** : Connect-RPC codegen ships **additively** alongside tonic gRPC + Kong-bridge REST — see [`MIGRATION-PATHS.md`](MIGRATION-PATHS.md). T.5 `t5-otel-stack` ships the OBI DaemonSet + Coroot deploy + `processors.probabilistic_sampler` env-tier overlays (Aegis audit required for prod ; see `infra/CLAUDE.md`). **T.5 `t5-otel-app` (Phase B — app SDK instrumentation)** wires the example Rust backend (`tracing-opentelemetry` + OTLP HTTP exporter + axum `TraceLayer` traceparent extraction) and Flutter frontend (`opentelemetry` Dart pkg + `BatchSpanProcessor` + `TracingInterceptor` + BLoC + navigation observers) so demo-005 emits a connected span tree end-to-end. Kong → Envoy + Temporal → DBOS swap is the breaking change of B.8 (T6). | 1.0.0 | [`full-stack-monorepo.md`](../.forge/specs/full-stack-monorepo.md) |
| `flutter-firebase`    | Planned (B.2) | Consumer-app teams without backend capacity                       | You want Firebase as your backend (Auth / Firestore / Functions / Storage) with Flutter as the only stack                                                                   | Flutter + Firebase                                                                                                           | TBD   | TBD                                                                |
| `mobile-only`         | Active        | Mobile-native teams with own backend + external OIDC provider     | You want Flutter iOS + Android with secure OIDC auth via flutter_appauth, no BaaS, with biometric lock + App Attest / Play Integrity attestation + Fastlane store pipelines | Flutter + OIDC (Auth0 / Keycloak / Cognito / Okta) + Keychain/Keystore secure storage + local_auth biometric + OpenTelemetry | 1.2.0 | [`mobile-only.md`](../.forge/specs/mobile-only.md)                 |
| `rust-cli-tui`        | Planned (B.3) | Dev-tool authors                                                  | You're shipping a Rust CLI / TUI binary with cargo-dist signed releases, multi-channel distribution                                                                         | Rust CLI + TUI (ratatui)                                                                                                     | TBD   | TBD                                                                |

## How `forge init` chooses

`forge init` has three selection modes :

1. **Explicit** — `forge init --archetype <name> [project-name] --org <reverse-domain>`. Bypasses the wizard ;
   deterministic for scripted use.
2. **Auto-detection** — `forge init --auto --target <dir>`. Inspects the target dir for archetype signals (
   `pubspec.yaml`, `Cargo.toml`, etc.) and picks the matching archetype. Aborts with `[NEEDS DECISION:]` on ambiguity (
   Article III.4 anti-hallucination).
3. **Interactive wizard** — `forge init` (no flags) on a TTY shell. Prompts the user for archetype + project name +
   reverse domain via Node's `readline` (no third-party UI library).

Non-TTY invocations without flags fall back to the `default` archetype silently — preserves CI compatibility for
adopters who scripted `forge init` before B.5.1 landed.

When the archetype's `signals:` list is non-empty (i.e., the archetype expects a project name + reverse domain), the
dispatcher REQUIRES `--org <reverse-domain>` (or the wizard's prompt). Reverse domain validation :
`^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$`.

## Forbidden combinations

J.8 (`j8-janus-rules`) ships a runtime refusal mechanism for archetype +
flag combinations that conflict with Forge's EU-strict / premium positioning.
Refusals fire **before any scaffolding side-effect** : exit code is **3**
(policy violation) and the structured stderr line is

```
[REFUSAL: <archetype>: <rule_id>: <reason> ; alternative: <alternative>]
```

| Rule ID       | Trigger                                       | Refusal target                                  | Alternative                                                                          |
|---------------|-----------------------------------------------|-------------------------------------------------|--------------------------------------------------------------------------------------|
| `J8-RULE-001` | `--archetype flutter-firebase`                | scaffolding of flutter-firebase                 | `default` archetype + adopter-managed Firebase overlay (out of Forge scope)         |
| `J8-RULE-002` | `--eu-tier T3` + non-self-host Zitadel        | cloud-Zitadel / Auth0 / Keycloak-cloud variants | self-host Zitadel on EU-jurisdiction infrastructure                                  |
| `J8-RULE-003` | `--eu-tier T3` + Datadog or SigNoz Cloud SaaS | Datadog exporter / `signoz.io` endpoints        | self-host SigNoz on EU-jurisdiction infrastructure (`infra/observability/` already defaults to local self-host) |

Full rule catalogue : `.forge/standards/global/janus-orchestration-rules.md`.

## EU compliance tier (`--eu-tier`)

`forge init --eu-tier <T1|T2|T3>` declares the project's intended EU
compliance posture. The flag is **optional** ; absence preserves
backward compat (no tier-specific refusals fire).

| Tier | Posture                                       | Janus enforcement at scaffold time                                              |
|------|-----------------------------------------------|---------------------------------------------------------------------------------|
| T1   | RGPD via DPA (cloud SaaS acceptable)          | Informational only — `[INFO: T1: tier recorded ; no refusal at this tier ; ...]` |
| T2   | Self-hostable recommended                     | Informational only.                                                              |
| T3   | SecNumCloud / EUCS High strict EU jurisdiction | Refusals fire (J8-RULE-002 + J8-RULE-003 — cloud identity + Datadog + SigNoz Cloud blocked) |

When `--eu-tier` is set (any tier), the wrapper writes a one-line
ledger file `<target>/.forge/.forge-tier` containing the chosen tier
(plain text, trailing newline). Adopter-side downstream tooling
consumes this for deployment-time gating.

Validation : the flag value is checked against
`.forge/schemas/compliance-tier.schema.json` enum `[T1, T2, T3]`
(case-sensitive). Invalid value → exit 2 + usage error.
