# Product Roadmap

This roadmap is a living document. Dates are approximate and may shift as
discovery reveals complexity. Items may move between phases. Ownership:
project maintainer reviews monthly; community input via GitHub Discussions
once opened (Module D.6 in the source audit roadmap).

## Vision (6–12 Months)

By 2027-Q1, any Flutter or Rust team can bootstrap a Forge project in under
five minutes via an official installer, pick one of three production-grade
**archetypes** (`full-stack-monorepo`, `flutter-firebase`, `rust-cli-tui`),
and start a spec → implementation cycle the same day. The framework is
distributed under Apache License 2.0 and is actively dog-fooded — Forge is
developed *through* Forge, its own `.forge/changes/` directory documenting
every amendment to the Constitution and every new capability. Two public
reference projects demonstrate the pipeline end-to-end. The deterministic
linters run in CI on every contributor's PR, blocking constitutional
violations before review.

## MVP (Now — 2026-Q2) — **Complete as of 2026-04-21 (v0.2.1)**

Corresponds to tier **T0** (immediate) and **T1** of the audit roadmap. All
MVP exit criteria are met. Residual T1 work (reference GitHub Actions
workflow, G.1) carried into Phase 2.

### MVP Items

| Status   | Item                                                                     | Audit ID | Shipped In |
|----------|--------------------------------------------------------------------------|----------|------------|
| Complete | Open-source license decision (Apache 2.0)                                | A1       | v0.1.0-t0  |
| Complete | Rewrite `LICENSE`, add `NOTICE` with upstream attribution                | A2       | v0.1.0-t0  |
| Complete | Fill `.forge/product/mission.md` with Forge's own mission                | E1       | v0.1.0-t0  |
| Complete | Fill `.forge/product/roadmap.md` with public roadmap                     | E2       | v0.1.0-t0  |
| Complete | Remove `defaultMode: plan` from project `.claude/settings.json`          | F7       | v0.1.0-t0  |
| Complete | Idempotent shell installer (`bin/forge-install.sh`)                      | A3       | v0.2.0     |
| Complete | `.forge/product/*` scaffolded from `.forge/templates/product/*`          | A3.0     | v0.2.0     |
| Complete | npm CLI package (`@sdd-forge/cli`) with `init`, `verify`, `version`      | A4       | v0.2.0     |
| Complete | CLI tarball bundles scaffoldable assets (fixed empty `init` from npm)    | A4.1     | v0.2.1     |
| Complete | Docker image `forge/linter:latest` bundling deterministic scripts        | A5       | v0.2.0     |
| Complete | SemVer policy coupled to the Constitution (`VERSION`, `docs/VERSIONING`) | A6       | v0.2.0     |
| Complete | `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CHANGELOG.md`, issue/PR templates  | D1-D4    | v0.2.0     |

Change IDs remain `N/A` until `.forge/changes/` is populated retroactively
(audit item E3, scheduled for Phase 3). The `A4.1` sub-item was discovered
during T1 validation: `@sdd-forge/cli@0.2.0` shipped a three-file tarball
(`dist/`, `VERSION`, `README.md` only) that could not scaffold anything.
`v0.2.1` adds a `prepack` hook that bundles `.forge/`, `.claude/`, `bin/`,
`docs/`, and root artifacts into `cli/assets/` so `npx @sdd-forge/cli init`
produces a functional install.

### MVP Exit Criteria

- [x] Apache 2.0 `LICENSE` and `NOTICE` published at repository root.
- [x] `.forge/product/mission.md` and `.forge/product/roadmap.md` filled
  with real content (no HTML comment placeholders remaining).
- [x] `.claude/settings.json` no longer forces `defaultMode: plan` on all
  contributors.
- [x] `forge init` shell installer copies `.forge/`, `.claude/`, `.mcp.json`,
  `CLAUDE.md` into a target project idempotently.
- [x] `@sdd-forge/cli` npm package is installable and `forge init` scaffolds
  a functional Forge project from the published tarball (validated in
  `cli/test/e2e/cli.test.ts` > *published-tarball layout*).
- [x] `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CHANGELOG.md`, GitHub issue and
  PR templates are present in the repository.

Note: the **first public reference project** (audit item C1) is deliberately
deferred to Phase 2, alongside the `full-stack-monorepo` archetype (B.1). An
example built before the archetype is defined would either diverge from the
canonical form or prematurely constrain archetype decisions. Building C1 via
`/forge:init --archetype full-stack-monorepo` — once that command exists —
makes the example free to produce and structurally coherent with what Forge
actually scaffolds.

## Phase 2 (Next — 2026-Q3)

Planned but not yet committed. Corresponds to audit tiers **T2** and the
start of **T3**.

### Phase 2 Items

| Priority | Capability                                                                                                                                                                                                 | Rationale                                                                                         |
|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| **In Progress** | **Archetype `full-stack-monorepo`** (Flutter + Rust + Infra) with CLAUDE.md scoping, protos as single source of truth via buf, multi-layer change workflow, and the `Janus` cross-layer orchestrator agent. **Delivered 2026-04-21 via `b1-foundations`** (schema, 3 standards, scoped commits, monorepo versioning, validator). **Delivered 2026-04-22 via `b1-scaffolder`** (archetype template tree, overlay renderer, `/forge:init --archetype` 7-step orchestrator, 3-level test harness, scaffold-manifest with tool versions). Schema promoted to `candidate / 1.0.0-rc.1`. Remaining : `b1-workflow` (Janus + multi-root linters + multi-layer change workflow), `b1-delivery` (CI workflows + `forge upgrade` + env matrix + observability). | Audit Module B.1 — flagship archetype, highest differentiation vs. alternatives                   |
| High     | **First public reference project** scaffolded via `/forge:init --archetype full-stack-monorepo`, with 3–5 archived changes in `.forge/archive/` demonstrating the full pipeline                            | Audit Module C.1 — coherent with the canonical archetype form (moved from T1 to avoid divergence) |
| High     | `/forge:init` wizard with archetype auto-detection (`--archetype` flag + heuristics across the four archetypes: `full-stack-monorepo`, `flutter-firebase`, `mobile-only`, `rust-cli-tui`)                  | Audit Module B.5.1 — collapses onboarding friction                                                |
| High     | Reference GitHub Actions workflow running `verify.sh` + `constitution-linter.sh` on every PR                                                                                                               | Audit Module G.1 — T1 carry-over, extends the blocking gates to CI                                |
| High     | `forge upgrade` command: non-destructive merge of framework updates into a project                                                                                                                         | Audit Module A.7 — without it, every constitution bump becomes a manual chore                     |
| Medium   | Pre-commit hook package (`forge-hooks`) for local constitution linting                                                                                                                                     | Audit Module G.2                                                                                  |
| Medium   | pipx packaging (`forge-cli`) as a Python-first alternative to `@sdd-forge/cli`                                                                                                                             | Audit Module A.4 complement — Python teams without Node on PATH                                   |
| Medium   | Homebrew formula (macOS dev ergonomics)                                                                                                                                                                    | Audit Module A.8                                                                                  |
| Medium   | Persistent `[NEEDS CLARIFICATION]` tracking per change (`open-questions.md`)                                                                                                                               | Audit Module F.1 — ambiguity protocol needs durable state for scale                               |
| Medium   | JSON Schema validating `.forge.yaml` per change, enforced by `verify.sh`                                                                                                                                   | Audit Module F.2                                                                                  |
| Medium   | `constitution-linter.sh` extended to cover Articles V, X.3, XI.3, XI.5 (not only heuristic greps)                                                                                                          | Audit Module F.4                                                                                  |
| Medium   | Governance model (`GOVERNANCE.md`) — amendment process, release ownership, BDFL vs. committee decision                                                                                                     | Audit Module D.5                                                                                  |

## Phase 3 (Later — 2026-Q4 and beyond)

Longer-horizon ideas, not committed. These exist to capture direction and
ensure MVP architecture does not foreclose on them.

### Phase 3 Ideas

| Idea                                                                                                                                                                            | Why It Matters                                                                                                                              | Why It's Later                                                                 |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------|
| Archetype `flutter-firebase` (frontend + BaaS) with security-rules harness and preview channels CI                                                                              | Covers the largest segment of consumer-app teams without backend capacity                                                                   | Audit Module B.2 — depends on B.1 scaffolder infrastructure being proven       |
| Archetype `mobile-only` (Flutter iOS + Android, OIDC via `flutter_appauth`, no BaaS) with secure token storage, biometric lock, App Attest / Play Integrity, Fastlane pipelines | Mobile-native teams with their own backend and an external OIDC provider (Auth0/Keycloak/Okta/Cognito) — largest segment not covered by B.2 | Audit Module B.4 — depends on B.1 scaffolder infrastructure; complements B.2   |
| Archetype `rust-cli-tui` with `cargo-dist`, signed releases, man pages, completions, multi-channel distribution                                                                 | Dev-tools audience: outsized influence-per-user                                                                                             | Audit Module B.3 — release-engineering surface is large and distinct           |
| `forge-cli` provider-neutral wrapper usable from Cursor, Aider, Continue                                                                                                        | Unlocks audiences locked out of Claude Code                                                                                                 | Audit Module G.6 — requires stable internal contracts first                    |
| GitHub App "Forge Guardian" that posts constitutional-compliance status on PRs                                                                                                  | Automates the gate without requiring contributor installation                                                                               | Audit Module G.3 — depends on a stable `constitution-linter.sh` coverage (F.4) |
| VSCode extension with FR-ID autocomplete and spec-delta previews                                                                                                                | Reduces friction for contributors who never touch the CLI                                                                                   | Audit Module G.7                                                               |
| Linear / Jira plugin bidirectional sync                                                                                                                                         | Bridges Forge artifacts to enterprise PM stacks                                                                                             | Audit Module G.4                                                               |
| Multi-level constitution (org + project + team amendments)                                                                                                                      | Blocks enterprise adoption until delivered                                                                                                  | Audit Module H.1                                                               |
| Opt-in telemetry to understand which gates block most and which agents fire                                                                                                     | Can't improve a framework whose usage is invisible                                                                                          | Audit Module H.3 — requires privacy review and opt-in UX                       |
| Compliance reports mapping constitutional articles to OWASP ASVS / ISO 27001 / SOC 2                                                                                            | Unlocks regulated-industry procurement                                                                                                      | Audit Module H.4                                                               |
| Retroactive `.forge/changes/001-initial-scaffolding/` documenting the framework's own construction                                                                              | Dog-fooding proof + pedagogy                                                                                                                | Audit Module E.3 — low urgency vs. external adoption blockers                  |

## Key Milestones

| Milestone                                   | Target Date | Success Criteria                                                                                                                                          | Status                        |
|---------------------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------|
| Alpha: OSS release + Forge dog-foods itself | 2026-06-30  | Apache 2.0 LICENSE + NOTICE; mission + roadmap filled; settings.json cleaned; shell installer on macOS + Linux; `@sdd-forge/cli` on npm; Docker image     | Complete (2026-04-21, v0.2.1) |
| Beta: flagship archetype shipped            | 2026-09-30  | `full-stack-monorepo` archetype scaffoldable via `/forge:init`; first public reference project; GitHub Actions reference workflow live                    | Not Started                   |
| v1.0: Four archetypes + adoption            | 2026-12-31  | `flutter-firebase`, `mobile-only`, and `rust-cli-tui` archetypes delivered; 10+ projects using Forge publicly; constitution-linter covers all 11 articles | Not Started                   |

## Deprioritized / Parked

- **Language extension to TypeScript / Node / Python / Go / Java / Swift**.
  Deliberately set aside. Forge targets Flutter and Rust as a premium
  positioning — three archetypes pushed to the state of the art beat seven
  archetypes held at mediocrity. Revisit only if a credible maintainer for
  a new language-arch emerges from the community.
- **Visual spec editor (web UI)**. File-based markdown is faster to ship,
  easier to diff, and sufficient for the target audience. Parked pending
  clear demand from a contributor population that refuses the CLI workflow.
- **Forge Cloud (hosted spec history, dashboards)**. Would require a
  commercial structure Forge does not currently have. Parked until the
  governance model (Module D.5) is resolved.
- **Auto-generation of feature code from specs**. Contrary to the core
  premise — Forge enforces process, not output. Parked permanently unless
  the positioning changes.
