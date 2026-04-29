# Proposal: b1-workflow
<!-- Created: 2026-04-22 -->
<!-- Schema: default -->
<!-- Parent audit module: B.1 (full-stack-monorepo archetype) -->
<!-- Parent audit items: B.1.6, B.1.7, B.1.8 -->
<!-- Depends on: b1-foundations + b1-scaffolder (both archived) -->

## Problem

`b1-foundations` posed the **contract** (schema + standards + validator).
`b1-scaffolder` built the **generator** (archetype templates + overlay
+ orchestrator). What's still missing is the **workflow** that makes
cross-layer work coherent and auditable :

1. **No agent routes cross-layer changes.** The schema references
   `cross_layer.agent: Janus`, but the agent file does not exist yet.
   Today a change that touches `backend/ + frontend/` defaults to the
   root `forge-master.md`, which does not know how to coordinate
   parallel per-layer designs nor validate cross-layer contract
   alignment.

2. **`.forge.yaml` per change ignores the layer dimension.** The
   metadata has no `layers:` field, so there is no mechanical way for
   an agent (or a reviewer) to tell whether a change is single-layer
   or spans backend + frontend + infra. Multi-layer changes get
   written as if they were single-layer and silently drift.

3. **`verify.sh` and `constitution-linter.sh` only inspect a single
   root.** For the Forge repo (which has neither `frontend/` nor
   `backend/`), the current scripts are correct. For a scaffolded
   monorepo, they miss the nested subtrees : `flutter analyze` never
   runs under `frontend/`, `cargo clippy` never runs under `backend/`,
   `buf lint` never runs under `shared/protos/`. The pre-existing
   single-root logic was written before the monorepo archetype
   existed ; it now leaves the largest part of a scaffolded project
   unchecked.

Without this change, adopters of `full-stack-monorepo` get a neat
template tree but no mechanical guardrail preventing cross-layer
drift. The flagship archetype would ship as a **form without a
lifecycle** — opposite of Forge's value proposition.

## Solution

Three tightly-related deliverables, collectively sufficient to give
`full-stack-monorepo` a complete multi-layer workflow :

1. **Janus agent** (B.1.7) — `.claude/agents/cross-layer-orchestrator.md` declares a new
   cross-layer orchestrator with the Forge persona pattern
   (mythological Roman name, role, style, 12-step workflow, quality
   gates). Janus is invoked :
    - On `/forge:design <name>` when the change's `.forge.yaml`
      declares `layers:` with ≥ 2 entries.
    - On `/forge:implement <name>` for the same condition.
    - On `/forge:review <name>` to validate cross-layer contract
      alignment (protos consistency, shared interfaces, versioning
      coherence).
   Janus **never writes code**. It dispatches per-layer specialists
   (Hera for `frontend/`, Vulcan for `backend/`, Atlas for `infra/`),
   aggregates their outputs, enforces a consistent contract across
   layers, and surfaces conflicts as `[NEEDS CLARIFICATION]` instead
   of letting them pass silently.

2. **Multi-layer change metadata** (B.1.6) — extends the
   `.forge.yaml` schema for **individual changes** (not to be
   confused with the archetype schema) :
    - New optional field `layers: [backend, frontend, infra]` listing
      touched layers (subset of what `.forge/schemas/full-stack-monorepo/schema.yaml`
      declares).
    - New optional fields `designs_per_layer:` (map of layer →
      design file, e.g. `backend: design-backend.md`) and
      `tasks_per_layer:` (map of layer → tasks file).
    - When `layers:` has 1 entry, the old single `design.md` +
      `tasks.md` convention applies (backwards compatible).
    - When `layers:` has ≥ 2 entries, Janus is invoked and the
      per-layer files become mandatory.
    - Templates under `.forge/templates/` gain `design-per-layer.md`
      and `tasks-per-layer.md` boilerplate.
    - `validate-foundations.sh` and the main `verify.sh` gain checks
      that confirm the per-layer files exist when `layers:` has ≥ 2.

3. **Multi-root deterministic scripts** (B.1.8) —
    - `verify.sh` detects the `full-stack-monorepo` schema at the
      target's `.forge.yaml` (not at the Forge repo's `.forge.yaml`)
      and, when matched, walks the three canonical subtrees :
        * Under `frontend/` : `flutter analyze --fatal-infos` +
          `flutter test --coverage` + the layer-boundary check
          (no Flutter imports under `features/*/domain/`). Coverage
          threshold scoped to `frontend/`.
        * Under `backend/` : `cargo clippy --all-targets -- -D
          warnings` + `cargo test --all-features` + the domain purity
          check (no `sqlx`/`reqwest`/`hyper`/`tonic` imports under
          `crates/domain/src/`) + no `unwrap()` / `panic!()` in
          production code. All scoped to `backend/`.
        * Under `shared/protos/` : `buf lint` + `buf breaking --against
          '.git#branch=main'` + optional `buf format --diff
          --exit-code`.
        * Under `infra/` : a lightweight syntax check on
          `docker-compose.dev.yml` + `kong.yml*` + `kustomization.yaml`
          if present.
      Aggregated PASS/FAIL lines are emitted with a `[backend] ...`
      / `[frontend] ...` / `[infra] ...` / `[protos] ...` prefix so
      failures are unambiguous.
    - `constitution-linter.sh` applies the existing Articles VI
      (Flutter) and VII (Rust) checks **scoped** to `frontend/` and
      `backend/` respectively. Today those checks run against the
      Forge repo root, which has neither tree — so they emit `N/A`.
      In a scaffolded monorepo, the scoping activates them for real.
    - Both scripts remain backwards compatible : when the target's
      `.forge.yaml` declares a schema OTHER than
      `full-stack-monorepo`, the single-root mode is preserved.

All three deliverables are **ordered** :
- Janus needs no prerequisites in this change — it's just a new
  agent file.
- Multi-layer metadata depends on templates + validator extensions.
- Multi-root scripts depend on both (they emit layer-scoped failures
  that Janus will aggregate in review).

## Scope In

- **`.claude/agents/cross-layer-orchestrator.md`** — new Forge agent with full 12-step
  workflow + quality gates, mirroring the pattern of
  `hera.md` / `vulcan.md` / `forge-master.md`.
- **`.forge/templates/design-per-layer.md`** + **`.forge/templates/tasks-per-layer.md`**
  — per-layer design and task templates, referenced by Janus and
  by the archive flow.
- **`.forge/templates/change.yaml`** — extension to support the
  optional `layers:` / `designs_per_layer:` / `tasks_per_layer:`
  fields with a documented schema (commented inside the template).
- **`.forge/scripts/validate-foundations.sh`** — new check
  `check_multi_layer_change_metadata` : for every `.forge/changes/*/.forge.yaml`
  that has `layers:` with ≥ 2 entries, verify that
  `designs_per_layer:` and `tasks_per_layer:` are populated and
  point at existing files.
- **`.forge/scripts/verify.sh`** — multi-root extension gated on
  schema detection at the target root. Four new sections : Flutter
  (layer-scoped), Rust (layer-scoped), Protos (`buf lint` +
  `buf breaking`), Infra (syntax checks). Preserves the existing
  single-root sections for non-monorepo schemas.
- **`.forge/scripts/constitution-linter.sh`** — layer-scoped
  Articles VI + VII checks that activate only when the target root
  uses the `full-stack-monorepo` schema.
- **`.forge/standards/global/multi-layer-workflow.md`** — new standard
  documenting the Janus routing policy, the `.forge.yaml` multi-layer
  shape, the per-layer design/tasks convention, and the linter
  scoping rule. Referenced by Janus and by `monorepo-layout.md`.
- **`.forge/standards/index.yml`** — one new entry for the new
  standard (scope `monorepo`, priority `high`, triggers
  `multi-layer`, `janus`, `cross-layer`, `layers:`).
- **`.forge/scripts/tests/workflow.test.sh`** — new harness that
  exercises the multi-layer metadata check, the Janus-routing
  contract (by inspection of `cross-layer-orchestrator.md` structure), and the
  multi-root script scoping via fixtures.
- **Update `b1-scaffolder`'s nested `CLAUDE.md` templates** (frontend,
  backend, infra) to reference Janus for cross-layer escalations
  (previously they named Janus but without a concrete routing
  policy document — this change ships that policy).

## Scope Out (Explicit Exclusions)

- **GitHub Actions CI workflows** (`B.1.9`) — `b1-delivery`. This
  change makes the scripts multi-root-aware but does NOT ship the
  CI matrix (monorepo vs non-monorepo) that invokes them on PRs.
- **`forge upgrade`** (`A.7`) — separate change. Out of scope even
  though Janus would be useful during an upgrade merge.
- **Environment overlays** (`B.1.12`) and **observability integration**
  (`B.1.14`) — `b1-delivery`.
- **Template for `release.yml` / release-plz** (`B.1.11`
  implementation) — `b1-delivery`.
- **Constitution amendment** — not required. Janus slots into the
  existing Article V (gates), Article VI.2, Article VII.3, Article
  VIII ; the new standard cites them rather than modifying them.
- **Reworking the slash commands** (`/forge:design`, `/forge:plan`,
  `/forge:implement`, `/forge:review`, `/forge:archive`) to be
  fully Janus-aware — the command Markdown is enriched with a
  "multi-layer branch" note that delegates to Janus, but no new
  slash command is added. Deep rework is out of scope.
- **Cross-language refactors of the 3 archetype layers** — not
  triggered by this change. The scaffolded project still has no
  real domain code.

## Impact

- **Users affected** :
    - **Cross-layer contributors** in a scaffolded monorepo : they
      now have a single point of orchestration (Janus) for changes
      that span ≥ 2 layers, instead of juggling three orchestrators
      manually.
    - **Reviewers** : multi-layer PRs now carry per-layer design and
      task files — they can review each layer independently,
      confident that Janus has verified the cross-layer coherence.
    - **CI (once `b1-delivery` lands)** : will invoke the multi-root
      scripts from a single entry point and get layer-scoped
      PASS/FAIL instead of a single aggregated signal.

- **Technical impact** :
    - New files : 1 agent (`cross-layer-orchestrator.md` — Janus persona), 1 standard
      (`multi-layer-workflow.md`), 2 templates (`design-per-layer.md`,
      `tasks-per-layer.md`), 1 harness (`workflow.test.sh`).
    - Modified files : `validate-foundations.sh` (new check),
      `verify.sh` (multi-root mode), `constitution-linter.sh`
      (layer-scoped Flutter/Rust), `index.yml` (1 entry),
      `change.yaml` template (new optional fields), 3 nested
      `CLAUDE.md` templates (Janus reference).
    - Complexity : **L** (Large). Scripts touch existing logic that
      ships in scaffolded projects ; backwards compatibility is
      mandatory.

- **Dependencies** :
    - Upstream : `b1-foundations` (schema's `cross_layer.agent: Janus`
      reference), `b1-scaffolder` (nested CLAUDE.md templates that
      mention Janus).
    - Downstream : `b1-delivery` (CI workflows invoke the multi-root
      scripts ; pre-commit hook runs the layer-scoped linters).

- **Risk level** : **Medium-High**.
    - Primary risk : breaking the existing single-root behavior of
      `verify.sh` / `constitution-linter.sh` for non-monorepo
      adopters. Mitigation : schema detection at the target root ;
      the new logic only activates when `.forge.yaml` declares
      `schema: full-stack-monorepo`. Other schemas see the scripts
      behave exactly as before (regression tests cover this).
    - Secondary risk : Janus's 12-step workflow codifies too much
      before real usage feedback. Mitigation : Janus v0.1 focuses on
      routing + aggregation (no novel deliverables) ; the workflow
      will evolve with real monorepo usage.
    - Tertiary risk : the multi-layer metadata shape (`layers:`,
      `designs_per_layer:`, `tasks_per_layer:`) may need to mutate
      before it stabilizes. Mitigation : optional fields with
      documented schema ; breaking changes only trigger a schema
      minor bump (`candidate / 1.1.0-rc.1`).

## Constitution Compliance

### Article I — TDD

Three harnesses cover this change :

1. `workflow.test.sh` for the multi-layer metadata check + Janus
   structure invariants (L1, hermetic).
2. Extension of `scaffolder.test.sh` L3 : a new scenario scaffolds
   a monorepo and then runs multi-root `verify.sh` against it,
   asserting the per-layer sections emit scoped output.
3. Fixture-based L2 tests for the multi-root mode that don't
   actually invoke `flutter`/`cargo`/`buf` (a tiny fake subtree
   with stub pubspec.yaml and Cargo.toml suffices to validate the
   scoping logic).

RED → GREEN → REFACTOR is respected : every new check is added as a
failing test first, then implemented.

### Article II — BDD

A user-facing feature exists (a contributor running `/forge:design`
on a cross-layer change and getting a per-layer design). A feature
file `features/b1-workflow.feature` is REQUIRED with scenarios :
- Cross-layer change routes through Janus automatically.
- Per-layer design files are created when `layers:` has ≥ 2 entries.
- Validator fails when `layers:` has 2+ but `designs_per_layer:` is
  missing.
- Multi-root verify.sh runs `flutter analyze` under `frontend/`
  AND `cargo clippy` under `backend/` on the same run.

### Article III — Specs Before Code

Confirmed. `/forge:specify b1-workflow` runs next.

### Article IV — Delta Specs

`specs.md` uses ADDED / MODIFIED / REMOVED format. Purely ADDED with
respect to `full-stack-monorepo.md`. MODIFIED applies to the
`change.yaml` template schema (adds optional fields, does not remove
anything).

### Article V — Gates

New checks added deterministically. The multi-root scripts use
the same PASS/FAIL/WARN protocol as the existing scripts. Janus is a
routing agent, not a gate itself — the existing gates (Nemesis,
Tribune, Aegis) remain in place and receive per-layer inputs from
Janus.

### Article VI — Flutter arch

The layer-scoped `constitution-linter.sh` check for Article VI.2
(Clean Architecture) now RUNS for real on `frontend/` subtrees (it
currently emits `N/A` because the Forge repo has no `frontend/`).

### Article VII — Rust arch

Same : the Article VII.3 (Hexagonal) check activates on `backend/`
subtrees. The domain-purity check (no `sqlx`/`reqwest`/`hyper`/`tonic`
imports in `crates/domain/src/`) is now correctly scoped.

### Article VIII — Infra

Infra syntax checks (compose + kong + kustomization) added as a new
section in `verify.sh`. Lightweight — no network calls, no deploys.

### Article IX — Observability / Security

Aegis review item : Janus dispatches to per-layer specialists by
invoking them by name (via Claude Code's TeamCreate or SendMessage
tool). No shell interpolation from user input ; the only user-supplied
strings (layer names) are validated against the enum declared in
`.forge/schemas/full-stack-monorepo/schema.yaml` `layers[].id`
before any dispatch.

### Article X — Quality

Audit-ID headers on every new file. Markdownlint applied. Traceability
via the standard index.yml entry.

### Article XI — AI-First

N/A — no AI feature.

## Open Questions

- `[NEEDS CLARIFICATION: should Janus's 12-step workflow include a
  mandatory "contract review" step that runs `buf breaking` as a
  cross-layer gate, or delegate that to `Hermes-API`?]` Proposed :
  delegate to Hermes-API (single-responsibility principle — Janus
  orchestrates, Hermes-API owns proto contracts). Janus invokes
  Hermes-API in step 8 of its workflow when a change touches
  `shared/protos/`.

- `[NEEDS CLARIFICATION: should `designs_per_layer:` be a map with
  explicit keys, or a list with `layer:` + `file:` per entry?]`
  Proposed : map with explicit keys (`backend: design-backend.md`).
  Reason : cheaper to query in shell/python, mirrors the layer enum
  from the archetype schema.

- `[NEEDS CLARIFICATION: should the multi-root verify.sh require a
  specific Forge-repo layout (layers at known paths) or detect
  dynamically via `.forge/schemas/full-stack-monorepo/schema.yaml`
  `layers[].path`?]` Proposed : detect dynamically. Adopters who
  modify `layers[].path` (rare but legitimate, e.g. flat layout) get
  the scripts to follow.

These questions do not block specification — they will be locked in
`/forge:specify b1-workflow` or deferred to `/forge:design`.
