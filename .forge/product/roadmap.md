# Product Roadmap

This roadmap is a living document. Dates are approximate and may shift as
discovery reveals complexity. Items may move between phases. Ownership:
project maintainer reviews monthly; community input via GitHub Discussions
(Module D.6, opened 2026-04-30).

> **Source documents** : the audit roadmap
> (`/Users/bfontaine/.claude/plans/il-s-agit-l-d-un-noble-gem.md` — internal)
> establishes the original modular plan ; `docs/ARCHITECTURE-TARGET.md`
> (2026-04-29 rev v1.1) ratifies 10 ADRs that revise the archetype taxonomy
> (4 → 5) and the flagship's technical stack ; `docs/new-archetypes-plan.md`
> (2026-05-04) consolidates both into the post-v0.3.0 plan reflected below.

## Vision (6–12 Months)

By 2027-Q1, any Flutter or Rust team can bootstrap a Forge project in under
five minutes via an official installer, pick one of **five production-grade
archetypes** (`full-stack-monorepo`, `mobile-pwa-first`, `event-driven-eu`,
`ai-native-rag`, `rust-cli-tui`) and start a spec → implementation cycle the
same day. The framework is distributed under Apache License 2.0 and is
actively dog-fooded — Forge is developed *through* Forge, its own
`.forge/changes/` directory documenting every amendment to the Constitution
and every new capability. Public reference projects demonstrate each
archetype end-to-end. The deterministic linters run in CI on every
contributor's PR, blocking constitutional violations before review.
EU-friendly by design: the flagship stack defaults to Envoy Gateway,
DBOS-backed durable execution on Postgres, Connect-RPC, Zitadel identity,
and SigNoz + OBI eBPF + Coroot observability — with a graded compliance
profile (T1 RGPD-via-DPA, T2 self-hostable, T3 SecNumCloud / EUCS High).

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
| **Done** | **`constitution-linter.sh` extended to cover Articles V, X.3, XI.3, XI.5 (previously not enforced). Delivered 2026-05-01 via `f4-linter-extension`** : 4 new sections in the linter — Article V.1 (task ↔ FR linkage in tasks.md), Article X.3 (public API doc ratio ≥ 80% Dart/Rust with first-5-missing list), Article XI.3 (GenUI schema-driven heuristic warning, NOT fail), Article XI.5 (fallback test pair `*fallback*` ↔ `*fallback*_test*`). Opt-out env vars per rule (`FORGE_LINTER_SKIP_V_1`, `_X_3`, `_XI_3`, `_XI_5`) + threshold override (`FORGE_LINTER_X3_THRESHOLD`). New `warn` helper + WARN counter. New standard `global/linting-rules.md` (6 H2 + opt-out matrix), doc `docs/LINTING.md` (~140 lignes). Harness 23/23 PASS (16 L1 + 7 L2 fixture-based). 13 harnesses now run in CI. Linter perf 1.97s ≤ 3s budget. Constitution coverage estimated ~70% → ~85%. **T3 robustness 100% delivered** (F.1 + F.2 + F.4). | Audit Module F.4 — DONE; T3 robustness complete |
| **Done** | **Governance model (`GOVERNANCE.md`) — amendment process, release ownership, BDFL vs. committee decision. Delivered 2026-04-30 via `d5-governance`** : `GOVERNANCE.md` at repo root (BDFL-with-fallback model — current phase Benoit Fontaine `@bfontaine` ; mature phase committee 3-7 members behind future amendment), `CODE_OF_CONDUCT.md` at repo root (Contributor Covenant v2.1 verbatim, contact `contact@benoitfontaine.fr`), Constitution amended v1.0.0 → v1.1.0 (new **Article XII — Governance** delegating operational rules to `GOVERNANCE.md`, first row in `## Amendments` table), templates bumped (`change.yaml` × 2 + archetype `.forge.yaml.tmpl`), README `## Governance` section now links both files. ADR-006 establishes the canonical precedent : a change-amendment ratified UNDER version N stays at N in its `.forge.yaml` and CREATES N+1 (no circular reference). 15/15 tests PASS in `d5.test.sh` ; 9 harnesses now run in CI (`b5.test.sh` + `d5.test.sh` newly registered). New consolidated spec `.forge/specs/governance.md`. | Audit Module D.5 — closes T2 P1 (last facilitator) and unblocks the second-archetype work in T3 P2 |
| **Done** | **Archetype `mobile-only` (Flutter iOS + Android, OIDC via `flutter_appauth`, no BaaS) — second archetype premium. Delivered 2026-04-30 via `b4-mobile-only` in 3 phases**: Phase A (core scaffold structure, schema + wrapper bash + dispatch entry + Flutter/iOS/Android skeleton + snapshot 436 KB), Phase B (runtime modules: oidc_config + auth_repository + auth_bloc + secure_storage_adapter + biometric_service + biometric_lock_widget + DeviceAttestor + 3 impls iOS App Attest / Android Play Integrity / Fake + Swift bridge AppAttestService + Kotlin bridge PlayIntegrityService + OTel init + flutter-mobile.md standard 7 H2 + 3 Interdictions), Phase C (Fastlane per-platform with secrets via ENV exclusively + mobile-ci.yml.tmpl iOS macos-latest + Android ubuntu-latest + e2e opt-in + ARCHETYPES.md row + framework-owned-paths.yml.tmpl per-archetype). 47/47 tests PASS in `b4.test.sh` (42 L1 + 5 L2). 10 harnesses now run in CI ; total ≥ 234 tests on `optim`. Snapshot 465 KB gzipped (23 % of NFR-MO-001 budget 2 MB). New consolidated spec `.forge/specs/mobile-only.md`. **First validation of B.5.1 dispatcher ABI**: zero TypeScript edit, adding mobile-only = 1 dispatch-table.yml entry + 1 `bin/forge-init-mobile-only.sh` wrapper. **First change ratified under Constitution v1.1.0** (post-D.5). **Note 2026-05-04**: schema `mobile-only / 1.0.0` becomes a legacy compat alias for the renamed `mobile-pwa-first` archetype (see Phase 3 below). | Audit Module B.4 — closes T2 P2 (second-archetype gate) ; **guard-rail PR optim → main + v0.3.x release now liftable at user discretion** |

### v0.3.0 Release (2026-05-02)

PR #1 merged (`47f8232`), tag `v0.3.0` (`dc0e1ce`) pushed, npm
`@sdd-forge/cli@0.3.0` published. **13 changes archived** on `optim`,
**292/292 tests** PASS across **13 harnesses**, **`verify.sh`** 108 PASS / 0 FAIL,
**`constitution-linter.sh`** OVERALL PASS, Constitution **v1.1.0**. Three
rounds of CI fix-ups required (`c29c9ce` + `f4626e6` + `a22d8c0` + `5cea6c3`)
because `forge-ci.yml` only ran on PR-to-main, never on push-to-optim. GH
release pending manual creation (gh CLI absent on maintainer's machine).
Bug detected in `scripts/release-v0.3.0.sh` (cumulative `cd` via `eval`,
2FA OTP not handled) — to fix post-release in module F.3.

### v0.3.x deliveries since v0.3.0 (2026-05-04 → 2026-05-05)

| Status         | Item                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Plan ID            | Shipped In                                              |
|----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------|---------------------------------------------------------|
| **Done**       | **Methodology ratification — T4 in one shot.** All five T4 methodology pre-requisites of `docs/new-archetypes-plan.md` §2 (P-1 through P-4) **delivered as a single consolidated change** rather than ten separate ADR archives — the audit trail is preserved through 35 ADDED FRs (`FR-T4-ADR-001..010` + `FR-T4-STD-001..006` + `FR-T4-LC-001..005` + `FR-T4-SCH-001..002` + `FR-T4-LNT-001..002` + `FR-T4-TST-001..005` + `FR-T4-IDX-001..002` + `FR-T4-DSP-001` + `FR-T4-DOC-001..003`) + 8 NFRs in `.forge/specs/adr-ratification.md`. Six versioned `.forge/standards/*.yaml` shipped at v1.0.0 (`transport`, `state-management`, `observability`, `orchestration`, `identity`, `persistence`). 12-month review cycle wired (`global/standards-lifecycle.md` + `REVIEW.md` ledger). Two new JSON schemas (`compliance-tier.schema.json` T1/T2/T3 + `archetype.schema.json` v2 with the 5-archetype enum + `mobile-only` legacy alias). Constitution v1.1.0 unchanged ; ADR-006 amendment-versioning precedent reused. **P-5 (Hera 9 → 5 sub-agents) retired 2026-05-06** — rejected by maintainer as an unsourced architect opinion ; the 9 sub-agents stay. | P-1, P-2, P-3, P-4, I.1, J.1–J.6 of `new-archetypes-plan.md` | Archived 2026-05-04 via `t4-adr-ratification` (PR #2)   |
| **Done**       | **Connect codegen on the flagship template (T5 Phase 1, additive). Delivered 2026-05-06 via `t5-connect-codegen`** (PR #3, merge commit `ca27257`). Adds `protoc-gen-connect-go` v1.19.2 + `bufbuild/protoc-gen-es ≥ v2.2.0` (Connect v2) + `connectrpc/connect-dart` v1.0.0+ official to `templates/full-stack-monorepo/1.0.0/proto/buf.gen.yaml.tmpl` ; bumps `transport.yaml` 1.0.0 → 1.1.0 with codegen pinning (11 versions) + REVIEW.md `Updated` entry ; pivots to **`connectrpc-build` via `build.rs`** (Option 2 / Path α) after T-BUF investigation revealed the BSR remote plugin is not yet shipped — the codebase convention is "remote plugins only", so `connectrpc-build` is consumed as a build-dependency in `backend/crates/grpc-api/Cargo.toml.tmpl` instead. Pins `connectrpc = "=0.3.3"` + `buffa = "=0.3.3"` + `buffa-types = "=0.3.3"` (Anthropic OSS, Apache-2.0, 6 558 conformance tests, MSRV 1.88). Adds parallel axum Connect route via `Router::into_axum_service()` ; tonic-build untouched (ADR-004 KEEP). New demo `demo-005-connect-greeting` archived in `examples/forge-fsm-example/`. New WARN-only linter rule `transport-codegen-coverage` (opt-out `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1`). Test harness `t5.test.sh` 25/25 L1 PASS ; **L2 fixtures (T-L2-001..007) deferred to T6** (B.8 flagship migration). New consolidated spec `.forge/specs/connect-codegen.md` (32 FRs `FR-T5-CC-001..072` + 10 NFRs + 6 ADRs `ADR-T5-001..006`). | T5 / Phase 1 ARCH item #1 | Archived 2026-05-06 via `t5-connect-codegen` (PR #3)   |

## Phase 3 (Post-v0.3.0 — 2026-Q3 to 2026-Q4) — Flagship migration + new archetypes

This phase ratifies the **ten ADRs** of `docs/ARCHITECTURE-TARGET.md`
(2026-04-29, rev v1.1) and reorganises the archetype taxonomy from 4 to 5.
The full plan lives in `docs/new-archetypes-plan.md`. Headline shifts:

- **Taxonomy reshuffled** : `flutter-firebase` is **removed** (Schrems II +
  CLOUD Act), `mobile-only` is **renamed** `mobile-pwa-first` (PWA Qwik +
  iOS native fallback), two new archetypes added — `event-driven-eu`
  (NATS + Temporal + AsyncAPI) and `ai-native-rag` (pgvector + LLM gateway
  + MCP). `full-stack-monorepo` and `rust-cli-tui` kept.
- **Flagship technical migration** : Kong → Envoy Gateway, Temporal → DBOS
  (Postgres-backed durable execution), REST/JSON Kong-bridge → Connect-RPC,
  Firebase implicit → Zitadel, Flutter Web public → Qwik (back-office
  Flutter Web kept), Postgres 17 + pgvector universal default, SigNoz +
  OBI eBPF + Coroot triplet observability. Schema bumps `1.0.0 → 2.0.0`.
- **flutter_bloc consecrated** as the only allowed Flutter state-management
  standard. Riverpod / Provider / GetX / MobX / states_rebuilder are
  **forbidden** by a CI-blocking linter rule (`no-state-management-alternatives`).
- **Compliance EU graded T1/T2/T3** introduced as a first-class dimension
  (T1 RGPD via DPA acceptable, T2 self-hostable, T3 SecNumCloud / EUCS
  High strict EU jurisdiction).
- **Five new agents** : Hermes-Async (event-driven), Pythia (AI/RAG),
  Demeter (data steward EU), Iris-Web (Qwik / SvelteKit), Themis (compliance
  officer NIS2 / DORA / CRA).

### Phase 3 Items — overview by quarter

| Quarter | Modules                                                                                              | Effort  | Risk     |
|---------|------------------------------------------------------------------------------------------------------|---------|----------|
| **T4** (2026-Q3 early) | **Done 2026-05-04 via `t4-adr-ratification`** : P-1 (10 ADRs consolidated as 1 archived change rather than 10 — Article V audit trail preserved through `FR-T4-ADR-001..010`) ; P-2 / J.1–J.6 (six `.forge/standards/*.yaml` v1.0.0 shipped) ; P-3 (`global/standards-lifecycle.md` + `REVIEW.md` ledger) ; P-4 / I.1 (`compliance-tier.schema.json` + `archetype.schema.json` v2). **P-5 (Hera 9 → 5) retired 2026-05-06 — rejected as unsourced architect opinion ; 9 sub-agents stay.** | `M` (delivered) | — |
| **T5** (2026-Q3) | **Phase 1 Done 2026-05-06** via `t5-connect-codegen` (PR #3) — Connect codegen additive shipped : buf.gen.yaml extended with `protoc-gen-connect-go` + `bufbuild/protoc-gen-es` (Connect v2) + official `connectrpc/connect-dart`, Rust path via `connectrpc-build` build-dependency (`connectrpc = "=0.3.3"` + `buffa = "=0.3.3"`), `transport.yaml` 1.0.0 → 1.1.0, demo-005-connect-greeting, parallel axum Connect route, tonic-build untouched, `transport-codegen-coverage` linter rule. **Still pending in T5** : OTel + OBI + Coroot stack templates, J.7 (`validate-standards-yaml.sh`), J.8 (Janus forbidden-list rules), K.3 (Demeter agent), I.2–I.6 (compliance docs + workflow + AI Act / NIS2 / DORA / CRA artefacts), traceparent W3C E2E validation (deferred with the L2 fixtures to T6). | `L` | Low — additive only, fully reversible |
| **T6** (2026-Q4 early) | **B.8 — flagship migration `1.0.0 → 2.0.0`** (Envoy Gateway, DBOS, Connect-RPC, Zitadel, Postgres+pgvector, SigNoz+OBI+Coroot) ; Phase 2 ARCHITECTURE-TARGET | `XL` | **High — point of no return.** Canary by route, blue-green Envoy/Kong, Temporal/DBOS dual-run during migration |
| **T7** (2026-Q4) | **B.6 `event-driven-eu`** (NATS JetStream + Temporal + AsyncAPI 3.1) ; **B.7 `ai-native-rag`** (pgvector + LLM gateway + MCP servers + Qwik streaming) ; K.1 / K.2 / K.4 / K.5 (Hermes-Async, Pythia, Iris-Web, Themis agents) | `XL` | Medium — DBOS-rs maturity, MCP evolving, Connect-Dart still community-only |
| **T8** (2027-Q1) | **B.9 `mobile-only` → `mobile-pwa-first`** (web-pwa Qwik subfolder + Bloc reinforcement + decision tree) ; **B.3 `rust-cli-tui`** (cargo-dist signed releases, multi-channel distribution) ; pedagogy C.2–C.5 (walkthrough, anti-patterns, comparison matrix, migration guide) ; F.3 (release script subshell isolation + 2FA OTP) | `L` to `XL` | Low |
| **T9+** | G.* (Forge Guardian GitHub App, VSCode extension, pre-commit hook, Linear/Jira sync, generic CLI wrapper) ; H.* (multi-level constitution, opt-in telemetry, compliance reports OWASP ASVS / ISO 27001 / SOC 2, multi-tenant Claude Code, dashboard) ; E.3 / E.4 (retroactive dog-fooding) | `XL` | — |

### Phase 3 Items — detail

| Module | Capability                                                                                                                                                                                                  | Source                          | Effort |
|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------|--------|
| P-1    | **Done 2026-05-04** via `t4-adr-ratification` — consolidated single archived change rather than 10 separate ADR changes. Article V audit trail preserved via 35 ADDED FRs in `.forge/specs/adr-ratification.md` (10× `FR-T4-ADR-*` + 6× `FR-T4-STD-*` + 5× `FR-T4-LC-*` + 2× `FR-T4-SCH-*` + ...). Rationale : keeping the 10 ADRs in one change avoids cross-referencing churn ; subsequent partial amendments can still be tracked at FR granularity. | ARCH §5                         | `M` (delivered) |
| P-2 / J.1–J.6 | **Done 2026-05-04** via `t4-adr-ratification` — six versioned `.forge/standards/*.yaml` v1.0.0 shipped (`transport`, `state-management`, `observability`, `orchestration`, `identity`, `persistence`) with `forbidden:` lists, `enforcement:`, `expires_at:` frontmatter, ratified into `index.yml` § "T.4 ratifications" block. **Still pending : J.7 (`validate-standards-yaml.sh` linter)** and **J.8 (Janus forbidden-list enforcement rules)** — both deferred to T5. | ARCH §12.1                      | `M` (partial — J.7/J.8 in T5) |
| P-3    | **Done 2026-05-04** via `t4-adr-ratification` — `global/standards-lifecycle.md` standard + `.forge/standards/REVIEW.md` append-only ledger ; structural exemptions wired (`transport.yaml` and `state-management.yaml` flagged `expires_at: never` + `exception_constitutional: true` per ADR-006/ADR-009) ; ledger seed entry for the six v1.0.0 standards (4 with `Next review due: 2027-05-04`, 2 with `never (structural)`). Themis agent automation deferred to K.5 (T7). | ARCH §12.6                      | `S` (delivered) |
| P-4 / I.1 | **Done 2026-05-04** via `t4-adr-ratification` — `.forge/schemas/compliance-tier.schema.json` (T1/T2/T3 enum) + `.forge/schemas/archetype.schema.json` **v2** (`full-stack-monorepo`, `mobile-pwa-first`, `event-driven-eu`, `ai-native-rag`, `rust-cli-tui` + `mobile-only` deprecated legacy alias for v0.3.0 B.4 adopters until B.9 in T8) ; dispatch-table.yml updated with `flutter-firebase` removal note. | ARCH §10                        | `S` (delivered) |
| B.8    | **Flagship migration `full-stack-monorepo / 1.0.0` → `2.0.0`**: Envoy Gateway / DBOS / Connect-RPC / Zitadel / Postgres+pgvector / SigNoz+OBI+Coroot / Qwik public web. **Point of no return.** Schema bump | ARCH §11 + §6.1                 | `XL`   |
| B.9    | **`mobile-only` → `mobile-pwa-first`**: add `web-pwa/` Qwik subfolder + service worker + web push, default decision tree (PWA Android+desktop, native iOS fallback if push critical)                       | ARCH §6.3                       | `L`    |
| B.6    | **New archetype `event-driven-eu`**: Rust + NATS JetStream + Temporal (justified here) + AsyncAPI 3.1 + Postgres event store ; reference project `examples/forge-eda-example/`                              | ARCH §3.3 + §6.4                | `XL`   |
| B.7    | **New archetype `ai-native-rag`**: Rust + Postgres+pgvector 0.8 + LLM gateway (Mistral-EU / vLLM self-host T3) + MCP servers + Qwik streaming UI ; reference project `examples/forge-rag-example/`           | ARCH §3.3 + §6.5                | `XL`   |
| B.3    | Archetype `rust-cli-tui` with `cargo-dist`, signed releases (codesign macOS / Authenticode Windows / gpg), SBOM SPDX, multi-channel distribution (Homebrew / Scoop / cargo binstall / AUR / Nix flake)       | Audit Module B.3 (kept)         | `XL`   |
| K.1–K.5 | Five new agents (Hermes-Async, Pythia, Demeter, Iris-Web, Themis) + edits cross-agents (Janus / Atlas / Apollo / Vulcan / Hermes-API / Argus / Sentinel / Panoptes / Aegis / Heracles)                     | ARCH §9.1 + §9.2                | `L`    |
| I.1–I.6 | Compliance EU graded T1/T2/T3: schemas, `global/compliance-tiers.md`, linter rule (T3 forbids US managed services), `forge-compliance.yml` workflow, `.forge/compliance/` (NIS2 / DORA / CRA / AI Act)        | ARCH §10                        | `L`    |
| C.2–C.5 | Pedagogy: walkthrough "first 30 minutes", anti-patterns gallery, comparison matrix vs BMAD/SpecKit/Agent OS V3/Superpowers, migration guide                                                                  | Audit Module C (carry-over)     | `M`    |
| F.3    | Fix `scripts/release-v0.3.0.sh` (subshell isolation + 2FA OTP handling)                                                                                                                                      | v0.3.0 release post-mortem      | `S`    |
| G.1–G.7 | GitHub Actions for downstream projects, `forge-hooks` pre-commit, Forge Guardian GitHub App, Linear/Jira sync, OpenAPI export, generic CLI wrapper, VSCode extension                                       | Audit Module G                  | `L` to `XL` |
| H.1–H.6 | Multi-level constitution, registry of standards, opt-in telemetry, compliance reports, multi-tenant Claude Code teams, web dashboard                                                                          | Audit Module H                  | `XL`   |

> **Migration safety net** : `forge upgrade` (A.7) already ships the BASE
> recovery via committed snapshot tarballs. The legacy
> `full-stack-monorepo / 1.0.0` snapshot stays in
> `.forge/scaffold-snapshots/` so existing adopters can stay on Kong + Temporal +
> REST-bridge until **2027-Q1** (T8) at the earliest, when the legacy compat is
> formally deprecated.

## Phase 4 (Later — 2027-Q2 and beyond)

Longer-horizon ideas, not committed. These exist to capture direction and
ensure Phase 3 architecture does not foreclose on them.

### Phase 4 Ideas

| Idea                                                                                                | Why It Matters                                                                                                | Why It's Later                                                                 |
|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------|
| Archetype `data-intensive` (ClickHouse / Citus sharded / time-series + analytic workloads)         | Covers a niche left open by `full-stack-monorepo` — analytic-first products                                    | Volontairement écarté en Phase 3 faute de demande explicite (ARCH §14 caveat 9)|
| Archetype Compose Multiplatform (Kotlin) as parallel to Flutter                                    | Tech Radar Vol 33 places Compose Multiplatform on the rise (Netflix, McDonald's prod)                         | ARCH §14 caveat 5 — Forge cible 2027-2028                                       |
| `forge-cli` provider-neutral wrapper usable from Cursor, Aider, Continue                            | Unlocks audiences locked out of Claude Code                                                                   | Audit Module G.6 — requires stable internal contracts first                    |
| GitHub App "Forge Guardian" that posts constitutional-compliance status on PRs                      | Automates the gate without requiring contributor installation                                                  | Audit Module G.3 — depends on stable `constitution-linter.sh` coverage         |
| VSCode extension with FR-ID autocomplete and spec-delta previews                                    | Reduces friction for contributors who never touch the CLI                                                      | Audit Module G.7                                                               |
| Linear / Jira plugin bidirectional sync                                                             | Bridges Forge artifacts to enterprise PM stacks                                                                | Audit Module G.4                                                               |
| Multi-level constitution (org + project + team amendments)                                          | Blocks enterprise adoption until delivered                                                                     | Audit Module H.1                                                               |
| Opt-in telemetry to understand which gates block most and which agents fire                        | Can't improve a framework whose usage is invisible                                                             | Audit Module H.3 — requires privacy review and opt-in UX                       |
| Compliance reports mapping constitutional articles to OWASP ASVS / ISO 27001 / SOC 2                | Unlocks regulated-industry procurement                                                                          | Audit Module H.4                                                               |
| Retroactive `.forge/changes/001-initial-scaffolding/` documenting the framework's own construction  | Dog-fooding proof + pedagogy                                                                                  | Audit Module E.3 — low urgency vs. external adoption blockers                  |

## Key Milestones

| Milestone                                                  | Target Date | Success Criteria                                                                                                                                                                                                                                                  | Status                        |
|------------------------------------------------------------|-------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------|
| Alpha: OSS release + Forge dog-foods itself                | 2026-06-30  | Apache 2.0 LICENSE + NOTICE; mission + roadmap filled; settings.json cleaned; shell installer on macOS + Linux; `@sdd-forge/cli` on npm; Docker image                                                                                                              | Complete (2026-04-21, v0.2.1) |
| Beta: flagship + second archetype + reference + governance | 2026-09-30  | `full-stack-monorepo / 1.0.0` + `mobile-only / 1.0.0` archetypes scaffoldable via `/forge:init` ; reference project `examples/forge-fsm-example/` ; `forge-ci.yml` live ; `forge upgrade` ; governance BDFL-with-fallback ; T3 robustness (F.1+F.2+F.4) all closed | Complete (2026-05-02, v0.3.0) |
| **ADR ratification (architecture target)**                 | 2026-09-30  | 10 ADRs of `docs/ARCHITECTURE-TARGET.md` archived as `.forge/changes/` ; six versioned `.forge/standards/*.yaml` ; compliance T1/T2/T3 schemas ; Demeter agent ; Phase 1 ARCH (OTel+Connect additive) shipped                                                       | **Partial (2026-05-04 + 2026-05-06)** : T4 methodology done via `t4-adr-ratification` (consolidated change, PR #2). T5 Phase 1 (Connect codegen) archived 2026-05-06 via `t5-connect-codegen` (PR #3). Demeter agent (K.3) + OTel/OBI/Coroot stack templates + J.7/J.8 + I.2–I.6 still pending. |
| **v0.4.0: flagship 2.0.0 — point of no return**            | 2026-12-31  | `full-stack-monorepo / 2.0.0` (Envoy + DBOS + Connect + Zitadel + Postgres+pgvector + SigNoz+OBI+Coroot + Qwik public web) ; `forge upgrade` migrates 1.0.0 → 2.0.0 ; CI rollback runbook documented ; legacy 1.0.0 still supported as compat                       | Not Started (T6)              |
| **v0.5.0: five archetypes + EU compliance**                | 2027-Q1     | `event-driven-eu`, `ai-native-rag`, `mobile-pwa-first`, `rust-cli-tui` all delivered ; pedagogy C.2–C.5 shipped ; constitution-linter coverage ≥ 90 % articles ; 5+ projects using Forge publicly ; T3 SecNumCloud profile validated on at least one archetype     | Not Started (T7–T8)           |
| **v1.0: enterprise readiness**                             | 2027-Q3     | Forge Guardian GitHub App ; multi-level constitution ; opt-in telemetry ; compliance reports OWASP ASVS / ISO 27001 / SOC 2 ; 20+ projects using Forge publicly                                                                                                    | Not Started (T9+)             |

## Deprioritized / Parked

- **Archetype `flutter-firebase`** (originally Audit Module B.2). **Removed
  from the roadmap** as of 2026-05-04 following `docs/ARCHITECTURE-TARGET.md`
  ADR-007: Schrems II + CLOUD Act make Firebase incompatible with Forge's
  EU/premium positioning. Adopters who insist on Firebase keep the `default`
  file-copy archetype as a starting point and add Firebase themselves. A
  potential future `flutter-baas-eu` archetype (Supabase EU self-host or
  Appwrite) is not committed and waits on demonstrated demand.
- **Language extension to TypeScript / Node / Python / Go / Java / Swift**.
  Deliberately set aside. Forge targets Flutter and Rust as a premium
  positioning — **five archetypes** pushed to the state of the art beat seven
  archetypes held at mediocrity. Revisit only if a credible maintainer for
  a new language-arch emerges from the community.
- **Visual spec editor (web UI)**. File-based markdown is faster to ship,
  easier to diff, and sufficient for the target audience. Parked pending
  clear demand from a contributor population that refuses the CLI workflow.
- **Forge Cloud (hosted spec history, dashboards)**. Would require a
  commercial structure Forge does not currently have. Parked indefinitely;
  governance model (D.5) is now in place but commercial mandate is not.
- **Auto-generation of feature code from specs**. Contrary to the core
  premise — Forge enforces process, not output. Parked permanently unless
  the positioning changes.
- **GraphQL Federation** as a default transport. Rejected by ARCH ADR-009
  for monorepo scale ; acceptable only if a polyglot non-Connect client
  forces it (`opinion d'architecte non sourcée`).
- **Datadog / AWS Secrets Manager / Firebase Auth / Vertex AI / Bedrock**
  as default integrations. Rejected by ARCH §10.2 (CLOUD Act) for EU-strict
  archetypes. Adopters in the US can substitute manually but no Forge
  template ships them as default.
