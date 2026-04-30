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

| Archetype | Status | Persona | When to pick | Stack | Since | Spec |
|---|---|---|---|---|---|---|
| `default` | Active | Generic projects, framework dog-fooding | You want minimal Forge install with no language-specific scaffold ; you'll write your own structure on top | Any (Forge framework only) | 0.1.0 | `default/schema.yaml` |
| `full-stack-monorepo` | Active | Full-stack teams shipping Flutter clients + Rust backend services | You're building a product app + a backend service + need shared protos as a single source of truth across both | Flutter + Rust + Infra (Kustomize / Kong / OTel / SigNoz) | 1.0.0 | [`full-stack-monorepo.md`](../.forge/specs/full-stack-monorepo.md) |
| `flutter-firebase` | Planned (B.2) | Consumer-app teams without backend capacity | You want Firebase as your backend (Auth / Firestore / Functions / Storage) with Flutter as the only stack | Flutter + Firebase | TBD | TBD |
| `mobile-only` | Planned (B.4) | Mobile-native teams with own backend + external OIDC provider | You want Flutter iOS + Android with secure OIDC auth via flutter_appauth, no BaaS | Flutter + OIDC (Auth0 / Keycloak / Cognito / Okta) | TBD | TBD |
| `rust-cli-tui` | Planned (B.3) | Dev-tool authors | You're shipping a Rust CLI / TUI binary with cargo-dist signed releases, multi-channel distribution | Rust CLI + TUI (ratatui) | TBD | TBD |

## How `forge init` chooses

`forge init` has three selection modes :

1. **Explicit** — `forge init --archetype <name> [project-name] --org <reverse-domain>`. Bypasses the wizard ; deterministic for scripted use.
2. **Auto-detection** — `forge init --auto --target <dir>`. Inspects the target dir for archetype signals (`pubspec.yaml`, `Cargo.toml`, etc.) and picks the matching archetype. Aborts with `[NEEDS DECISION:]` on ambiguity (Article III.4 anti-hallucination).
3. **Interactive wizard** — `forge init` (no flags) on a TTY shell. Prompts the user for archetype + project name + reverse domain via Node's `readline` (no third-party UI library).

Non-TTY invocations without flags fall back to the `default` archetype silently — preserves CI compatibility for adopters who scripted `forge init` before B.5.1 landed.

When the archetype's `signals:` list is non-empty (i.e., the archetype expects a project name + reverse domain), the dispatcher REQUIRES `--org <reverse-domain>` (or the wizard's prompt). Reverse domain validation : `^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$`.
