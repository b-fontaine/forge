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

## MVP (Now — 2026-Q2)

Current quarter commitments. These are the items in active development and
correspond to tier **T0** (immediate) and the start of **T1** of the audit
roadmap.

### MVP Items

| Status | Item | Audit ID | Change ID |
|--------|------|----------|-----------|
| Complete | Open-source license decision (Apache 2.0) | A1 | N/A |
| Complete | Rewrite `LICENSE`, add `NOTICE` with upstream attribution | A2 | N/A |
| Complete | Fill `.forge/product/mission.md` with Forge's own mission | E1 | N/A |
| Complete | Fill `.forge/product/roadmap.md` with public roadmap | E2 | N/A |
| Complete | Remove `defaultMode: plan` from project `.claude/settings.json` | F7 | N/A |
| In Progress | Idempotent shell installer (`forge init`) | A3 | N/A |
| In Progress | First reference project (Flutter example) | C1 | N/A |
| In Progress | `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CHANGELOG.md`, issue/PR templates | D1-D4 | N/A |

Change IDs remain `N/A` until `.forge/changes/` is populated retroactively
(audit item E3, scheduled for Phase 3).

### MVP Exit Criteria

- [x] Apache 2.0 `LICENSE` and `NOTICE` published at repository root.
- [x] `.forge/product/mission.md` and `.forge/product/roadmap.md` filled
      with real content (no HTML comment placeholders remaining).
- [x] `.claude/settings.json` no longer forces `defaultMode: plan` on all
      contributors.
- [ ] `forge init` shell installer copies `.forge/`, `.claude/`, `.mcp.json`,
      `CLAUDE.md` into a target project idempotently.
- [ ] At least one public reference project exists on disk with a populated
      `.forge/archive/` of 3–5 archived changes.
- [ ] `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CHANGELOG.md`, GitHub issue and
      PR templates are present in the repository.

## Phase 2 (Next — 2026-Q3)

Planned but not yet committed. Corresponds to audit tiers **T2** and the
start of **T3**.

### Phase 2 Items

| Priority | Capability | Rationale |
|----------|-----------|-----------|
| High | **Archetype `full-stack-monorepo`** (Flutter + Rust + Infra) with CLAUDE.md scoping, protos as single source of truth via buf, multi-layer change workflow, and the `Janus` cross-layer orchestrator agent | Audit Module B.1 — flagship archetype, highest differentiation vs. alternatives |
| High | `/forge:init` wizard with archetype auto-detection (`--archetype` flag + heuristics based on existing `pubspec.yaml` / `Cargo.toml`) | Audit Module B.4.1 — collapses onboarding friction |
| High | Reference GitHub Actions workflow running `verify.sh` + `constitution-linter.sh` on every PR | Audit Module G.1 — extends the blocking gates to CI |
| High | `forge upgrade` command: non-destructive merge of framework updates into a project | Audit Module A.7 — without it, every constitution bump becomes a manual chore |
| Medium | Pre-commit hook package (`forge-hooks`) for local constitution linting | Audit Module G.2 |
| Medium | npm and pipx packaging (`@forge/cli`, `forge-cli`) | Audit Modules A.4 — lower installer friction |
| Medium | Docker image `forge/linter:latest` bundling `verify.sh` + `constitution-linter.sh` for CI | Audit Module A.5 |
| Medium | Persistent `[NEEDS CLARIFICATION]` tracking per change (`open-questions.md`) | Audit Module F.1 — ambiguity protocol needs durable state for scale |
| Medium | JSON Schema validating `.forge.yaml` per change, enforced by `verify.sh` | Audit Module F.2 |
| Medium | `CHANGELOG.md` with Keep a Changelog format, governance model (`GOVERNANCE.md`) | Audit Modules D.3, D.5 |

## Phase 3 (Later — 2026-Q4 and beyond)

Longer-horizon ideas, not committed. These exist to capture direction and
ensure MVP architecture does not foreclose on them.

### Phase 3 Ideas

| Idea | Why It Matters | Why It's Later |
|------|---------------|----------------|
| Archetype `flutter-firebase` (frontend + BaaS) with security-rules harness and preview channels CI | Covers the largest segment of consumer-app teams without backend capacity | Audit Module B.2 — depends on B.1 scaffolder infrastructure being proven |
| Archetype `rust-cli-tui` with `cargo-dist`, signed releases, man pages, completions, multi-channel distribution | Dev-tools audience: outsized influence-per-user | Audit Module B.3 — release-engineering surface is large and distinct |
| `forge-cli` provider-neutral wrapper usable from Cursor, Aider, Continue | Unlocks audiences locked out of Claude Code | Audit Module G.6 — requires stable internal contracts first |
| GitHub App "Forge Guardian" that posts constitutional-compliance status on PRs | Automates the gate without requiring contributor installation | Audit Module G.3 — depends on a stable `constitution-linter.sh` coverage (F.4) |
| VSCode extension with FR-ID autocomplete and spec-delta previews | Reduces friction for contributors who never touch the CLI | Audit Module G.7 |
| Linear / Jira plugin bidirectional sync | Bridges Forge artifacts to enterprise PM stacks | Audit Module G.4 |
| Multi-level constitution (org + project + team amendments) | Blocks enterprise adoption until delivered | Audit Module H.1 |
| Opt-in telemetry to understand which gates block most and which agents fire | Can't improve a framework whose usage is invisible | Audit Module H.3 — requires privacy review and opt-in UX |
| Compliance reports mapping constitutional articles to OWASP ASVS / ISO 27001 / SOC 2 | Unlocks regulated-industry procurement | Audit Module H.4 |
| Retroactive `.forge/changes/001-initial-scaffolding/` documenting the framework's own construction | Dog-fooding proof + pedagogy | Audit Module E.3 — low urgency vs. external adoption blockers |

## Key Milestones

| Milestone | Target Date | Success Criteria | Status |
|-----------|-------------|-----------------|--------|
| Alpha: OSS release + Forge dog-foods itself | 2026-06-30 | Apache 2.0 LICENSE + NOTICE published; mission + roadmap filled; settings.json cleaned; installer shell script works on macOS + Linux | In Progress |
| Beta: flagship archetype shipped | 2026-09-30 | `full-stack-monorepo` archetype scaffoldable via `/forge:init`; first public reference project; GitHub Actions reference workflow live | Not Started |
| v1.0: Three archetypes + adoption | 2026-12-31 | `flutter-firebase` and `rust-cli-tui` archetypes delivered; 10+ projects using Forge publicly; constitution-linter covers all 11 articles | Not Started |

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
