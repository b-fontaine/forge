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
| **Done** | **Archetype `full-stack-monorepo`** (Flutter + Rust + Infra) with CLAUDE.md scoping, protos as single source of truth via buf, multi-layer change workflow, and the `Janus` cross-layer orchestrator agent. **Delivered 2026-04-21 via `b1-foundations`** (schema, 3 standards, scoped commits, monorepo versioning, validator). **Delivered 2026-04-22 via `b1-scaffolder`** (archetype template tree, overlay renderer, `/forge:init --archetype` 7-step orchestrator, 3-level test harness, scaffold-manifest with tool versions). **Delivered 2026-04-23 via `b1-workflow`** (Janus agent + multi-root verify.sh / constitution-linter.sh + per-change `layers:` metadata + per-layer designs/tasks). **Delivered 2026-04-29 via `b1-delivery`** (4 reference GitHub Actions workflows with dorny/paths-filter, Kustomize base + 3 overlays dev/staging/prod with HPA, OTel + SigNoz local observability stack, 3 infra standards). **Schema promoted to `stable / 1.0.0` on 2026-04-29.** B.1 contract fully delivered ; 75/75 tests PASS across 4 harnesses. | Audit Module B.1 — flagship archetype, highest differentiation vs. alternatives                   |
| **Done** | **First public reference project** scaffolded via `/forge:init --archetype full-stack-monorepo`, with 4 demo changes (3 archived + 1 specified-only) demonstrating the full pipeline. **Delivered 2026-04-30 via `c1-reference-project`** : `examples/forge-fsm-example/` (~2.3 MB, 52 % of NFR-EX-002 5 MB budget) with 4 demo changes — `demo-001-greeting-service` (single-layer backend, gRPC Greeter + hexagonal Rust + cucumber-rs BDD), `demo-002-greeting-screen` (single-layer frontend, Flutter Cubit + bloc_test + widget tests), `demo-003-rate-limit` (multi-layer backend+infra triggering Janus orchestration with per-layer designs/tasks + Kong rate-limit plugin), `demo-004-user-onboarding` (multi-layer status:specified illustrating Article III.4 `[NEEDS CLARIFICATION:]` markers). Skip-guards in `verify.sh` + `constitution-linter.sh` (FR-GL-026/027), new `example` job in `forge-ci.yml` (FR-CI-012, paths-filter on `examples/**`). NFR-017 measured: **2124 bytes** overlay diff (52 % of budget). 30/30 tests PASS in `c1.test.sh`. New consolidated spec `.forge/specs/example-reference.md` for the `FR-EX-*` namespace. | Audit Module C.1 — coherent with the canonical archetype form (moved from T1 to avoid divergence) |
| **Done** | **`/forge:init` wizard with archetype auto-detection. Delivered 2026-04-30 via `b5-1-init-wizard`** : the npm CLI `forge init` is now the canonical entry point with three modes — `--archetype <name>` (explicit), `--auto` (signals heuristic on `pubspec.yaml` / `Cargo.toml`), `--wizard` (interactive Node `readline` prompt, zero new third-party deps). Dispatch table at `.forge/scaffolding/dispatch-table.yml` (2 active archetypes : `default` + `full-stack-monorepo` ; 3 placeholders : `flutter-firebase` / `mobile-only` / `rust-cli-tui` for B.2 / B.4 / B.3). Per-archetype wrappers under `bin/forge-init-<archetype>.sh` with stable ABI. Strict `[NEEDS DECISION:]` abort on auto ambiguity (Article III.4). NFR-IW-004 backwards-compat preserved (CI scripts invoking `forge init` without flags on non-TTY still work). New standard `global/scaffolding.md`, public `docs/ARCHETYPES.md` decision matrix, harness `b5.test.sh` 17/17 PASS, Vitest 56/56. New consolidated spec `.forge/specs/init-wizard.md`. | Audit Module B.5.1 — collapses onboarding friction ; dependency amont of B.2 / B.3 / B.4 |
| **Done** | **Reference GitHub Actions workflow running `verify.sh` + `constitution-linter.sh` + 4 test harnesses + CLI Vitest + shellcheck on every PR.** **Delivered 2026-04-29 via `g1-forge-ci`** : single-workflow `forge-ci.yml` with 5 jobs (harness/gates/cli/lint/summary), conditional `cancel-in-progress` PR/main asymmetry, minimal `contents: read` permissions, `cli/.nvmrc` Node 20.18.0 pinning, dedicated standard `global/forge-self-ci.md`, branch-protection guidance in `CONTRIBUTING.md`. Single required status `forge-ci / summary`. 14/14 tests PASS in `g1.test.sh`. | Audit Module G.1 — T1 carry-over, extends the blocking gates to CI                                |
| **Done** | **`forge upgrade` command: non-destructive merge of framework updates into a project. Delivered 2026-04-30 via `a7-forge-upgrade`** : new CLI subcommand `forge upgrade` (TS thin orchestrator + bash thick driver `bin/forge-upgrade.sh`), 3-way merge via `git merge-file --diff3` over paths declared in `.forge/framework-owned-paths.yml` (22 owned globs + 8 excluded), BASE recovery via committed snapshot tarballs (`full-stack-monorepo / 1.0.0` snapshot 422 KB gzipped, 41 % of 1 MB budget), conflict markers + `.merge-conflicts` companion, `--force` Git-cleanliness gate, major-version migration abort with `[NEEDS MIGRATION:]` marker, append-only `upgrade_history` ledger in `scaffold-manifest.yaml` with immutable identity fields, new standard `global/upgrade-policy.md` (6 H2 sections + 3 Interdictions), test harness `a7.test.sh` 29/29 PASS (L1 hermetic + L2 fixture truth-table + L3 opt-in against example tree), 5 Vitest unit tests for the TS layer. `examples/forge-fsm-example/` smoke test : 160 unchanged + 15 preserved + 0 conflicts, exit 0. New consolidated spec `.forge/specs/upgrade.md`. | Audit Module A.7 — adopters can now follow Constitution / standards / agents bumps without manual chores |
| Medium   | Pre-commit hook package (`forge-hooks`) for local constitution linting                                                                                                                                     | Audit Module G.2                                                                                  |
| Medium   | pipx packaging (`forge-cli`) as a Python-first alternative to `@sdd-forge/cli`                                                                                                                             | Audit Module A.4 complement — Python teams without Node on PATH                                   |
| Medium   | Homebrew formula (macOS dev ergonomics)                                                                                                                                                                    | Audit Module A.8                                                                                  |
| **Done** | **Persistent `[NEEDS CLARIFICATION]` tracking per change (`open-questions.md`). Delivered 2026-05-01 via `f1-open-questions`** : new standard `global/open-questions.md` (8 H2 sections + 3 Interdictions), template `open-questions.md.tmpl`, per-change file convention with Q-NNN sequential / Status enum (open/answered/wontfix) / Resolution block, **`verify.sh` Open Questions Gate** blocks archive on lingering `Status: open` questions, **`constitution-linter.sh` Article III.4 rule** blocks `[NEEDS CLARIFICATION:` inline in `implemented` or `archived` changes (with smart exclusions for backticks / HTML comments / fenced code blocks), **`bin/forge-questions.sh`** discovery script with `--change` / `--status` filters. Backwards-compatible : 10 pre-F.1 archived changes (b1-*, g1, c1, a7, b5-1, d5, b4) NOT backfilled, gate skips on absent file. 17/17 tests PASS in `f1.test.sh` (12 L1 + 5 L2 fixture-based). 11 harnesses now run in CI. New consolidated spec `.forge/specs/open-questions.md`. Documentation: `docs/OPEN_QUESTIONS.md`. | Audit Module F.1 — robustness; F.2 + F.4 still pending in T3 |
| **Done** | **JSON Schema validating `.forge.yaml` per change, enforced by `verify.sh`. Delivered 2026-05-01 via `f2-yaml-schema`** : new `.forge/schemas/change.schema.json` (Draft 2020-12) with required name/status/created/schema/constitution_version, status enum (6 values), schema enum dynamique with drift detector test, semver pattern, timeline shape + coherence rules. New `.forge/scripts/validate-change-yaml.sh` (bash + Python 3 inline, no jsonschema lib). New `verify.sh` section "Change YAML Schema" iterates over `.forge/changes/*/.forge.yaml`. New standard `global/change-yaml-schema.md`, doc `docs/SCHEMA.md`, harness `f2.test.sh` 18/18 PASS. **All 11 archived pre-F.2 changes validated** (NFR-YS-001 backward compat) — schema accommodates historical extended fields (`parent_audit_items`, `depends_on`, `archived_to`, `schema_promotion`, `promotes_schema`). PyYAML date coercion implemented (unquoted ISO dates parsed as `datetime.date` are converted to strings before pattern check). 12 harnesses now run in CI. New consolidated spec `.forge/specs/change-yaml-schema.md`. | Audit Module F.2 — robustness; F.4 still pending in T3 |
| Medium   | `constitution-linter.sh` extended to cover Articles V, X.3, XI.3, XI.5 (not only heuristic greps)                                                                                                          | Audit Module F.4                                                                                  |
| **Done** | **Governance model (`GOVERNANCE.md`) — amendment process, release ownership, BDFL vs. committee decision. Delivered 2026-04-30 via `d5-governance`** : `GOVERNANCE.md` at repo root (BDFL-with-fallback model — current phase Benoit Fontaine `@bfontaine` ; mature phase committee 3-7 members behind future amendment), `CODE_OF_CONDUCT.md` at repo root (Contributor Covenant v2.1 verbatim, contact `contact@benoitfontaine.fr`), Constitution amended v1.0.0 → v1.1.0 (new **Article XII — Governance** delegating operational rules to `GOVERNANCE.md`, first row in `## Amendments` table), templates bumped (`change.yaml` × 2 + archetype `.forge.yaml.tmpl`), README `## Governance` section now links both files. ADR-006 establishes the canonical precedent : a change-amendment ratified UNDER version N stays at N in its `.forge.yaml` and CREATES N+1 (no circular reference). 15/15 tests PASS in `d5.test.sh` ; 9 harnesses now run in CI (`b5.test.sh` + `d5.test.sh` newly registered). New consolidated spec `.forge/specs/governance.md`. | Audit Module D.5 — closes T2 P1 (last facilitator) and unblocks the second-archetype work in T3 P2 |
| **Done** | **Archetype `mobile-only` (Flutter iOS + Android, OIDC via `flutter_appauth`, no BaaS) — second archetype premium. Delivered 2026-04-30 via `b4-mobile-only` in 3 phases**: Phase A (core scaffold structure, schema + wrapper bash + dispatch entry + Flutter/iOS/Android skeleton + snapshot 436 KB), Phase B (runtime modules: oidc_config + auth_repository + auth_bloc + secure_storage_adapter + biometric_service + biometric_lock_widget + DeviceAttestor + 3 impls iOS App Attest / Android Play Integrity / Fake + Swift bridge AppAttestService + Kotlin bridge PlayIntegrityService + OTel init + flutter-mobile.md standard 7 H2 + 3 Interdictions), Phase C (Fastlane per-platform with secrets via ENV exclusively + mobile-ci.yml.tmpl iOS macos-latest + Android ubuntu-latest + e2e opt-in + ARCHETYPES.md row + framework-owned-paths.yml.tmpl per-archetype). 47/47 tests PASS in `b4.test.sh` (42 L1 + 5 L2). 10 harnesses now run in CI ; total ≥ 234 tests on `optim`. Snapshot 465 KB gzipped (23 % of NFR-MO-001 budget 2 MB). New consolidated spec `.forge/specs/mobile-only.md`. **First validation of B.5.1 dispatcher ABI**: zero TypeScript edit, adding mobile-only = 1 dispatch-table.yml entry + 1 `bin/forge-init-mobile-only.sh` wrapper. **First change ratified under Constitution v1.1.0** (post-D.5). | Audit Module B.4 — closes T2 P2 (second-archetype gate) ; **guard-rail PR optim → main + v0.3.x release now liftable at user discretion** |

## Phase 3 (Later — 2026-Q4 and beyond)

Longer-horizon ideas, not committed. These exist to capture direction and
ensure MVP architecture does not foreclose on them.

### Phase 3 Ideas

| Idea                                                                                                                                                                            | Why It Matters                                                                                                                              | Why It's Later                                                                 |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------|
| Archetype `flutter-firebase` (frontend + BaaS) with security-rules harness and preview channels CI                                                                              | Covers the largest segment of consumer-app teams without backend capacity                                                                   | Audit Module B.2 — depends on B.1 scaffolder infrastructure being proven       |
| ~~Archetype `mobile-only`~~ — **Done in T2 P2 (2026-04-30 via `b4-mobile-only`).** See Phase 2 row above for full details. | — | Audit Module B.4 — DONE |
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
