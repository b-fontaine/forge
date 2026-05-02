# Spec: b1-workflow
<!-- Delta format: ADDED, MODIFIED, REMOVED sections only -->
<!-- Audit: B.1.6 + B.1.7 + B.1.8 -->
<!-- Depends on spec: full-stack-monorepo.md (FR-GL-001..014 + FR-BE-001 + FR-FE-001 + FR-IN-001 + NFR-001..008) -->

## ADDED Requirements

### FR-GL-015: Janus agent — cross-layer orchestrator

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — a file `.claude/agents/cross-layer-orchestrator.md` exists and declares the
  Janus agent with the standard Forge persona pattern (Roman
  mythological name, role, style, 12-step workflow, quality gates).
- **MUST** — Janus is classified as an **orchestrator** : it NEVER
  writes application code. Its role is to dispatch per-layer
  specialists (Hera for `frontend/`, Vulcan for `backend/`, Atlas
  for `infra/`, Hermes-API for `shared/protos/`), aggregate their
  outputs, and enforce cross-layer contract alignment.
- **MUST** — Janus is invoked by `/forge:design`, `/forge:implement`,
  `/forge:review` when the change's `.forge.yaml` declares `layers:`
  with ≥ 2 entries.
- **MUST** — Janus's workflow emits `[NEEDS CLARIFICATION: ...]`
  markers (Article V.3) when per-layer deliverables disagree ; it
  NEVER silently resolves a conflict.
- **SHALL** — Janus's routing table in the file references the
  sub-specialists by name (Hera / Vulcan / Atlas / Hermes-API /
  Nemesis / Tribune / Aegis) with a one-line rationale per
  invocation rule.

**Constitution reference:** Article V (gates), Articles VI.2, VII.3,
VIII. **Testable:** yes — `test_janus_agent_file_has_required_sections`
in `workflow.test.sh`.

---

### FR-GL-016: `.forge.yaml` per-change gains optional multi-layer fields

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — the `.forge/templates/change.yaml` template exposes
  three new optional top-level fields :
    - `layers:` — list of layer ids (subset of `backend`, `frontend`,
      `infra`, matching the archetype schema's `layers[].id`).
    - `designs_per_layer:` — map of `layer-id → filename`.
      Required only when `layers:` has ≥ 2 entries.
    - `tasks_per_layer:` — map of `layer-id → filename`. Same
      trigger as `designs_per_layer:`.
- **MUST** — when `layers:` has exactly 1 entry, the existing
  `design.md` / `tasks.md` convention applies (backwards compatible
  with every pre-`b1-workflow` change).
- **MUST** — when `layers:` is absent, the change is treated as
  single-layer (backwards compatible). Only monorepo projects
  populate this field.
- **SHOULD** — the template carries an inline comment block that
  documents the schema + the one-sentence rule "≥ 2 layers triggers
  Janus orchestration and per-layer deliverables".

**Constitution reference:** Article III.2 (specs-as-code), Article IV
(deltas at the metadata level too). **Testable:** yes — template
inspection + downstream check in `validate-foundations.sh`.

---

### FR-GL-017: Validator check for multi-layer change metadata

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — `.forge/scripts/validate-foundations.sh` gains a new
  check `check_multi_layer_change_metadata` that inspects every
  `.forge/changes/*/.forge.yaml`.
- **MUST** — when a change's `layers:` has ≥ 2 entries, the check
  REQUIRES `designs_per_layer:` and `tasks_per_layer:` to be present
  and non-empty.
- **MUST** — every file referenced in `designs_per_layer:` and
  `tasks_per_layer:` MUST exist in the change directory. Missing
  file = FAIL.
- **MUST** — layer ids in `layers:` MUST be a subset of the archetype
  schema's `layers[].id` (currently `backend`, `frontend`, `infra`).
  Unknown layer = FAIL.
- **SHALL** — when a change is single-layer (or omits `layers:`),
  the check is N/A : emits a PASS line with the rationale `("single-layer
  change — no per-layer files expected")`.
- **SHALL** — the check is gated on the archetype schema being
  present at `.forge/schemas/full-stack-monorepo/schema.yaml`.
  Non-monorepo projects see the check SKIPPED, not N/A.

**Constitution reference:** Article III, Article V. **Testable:** yes
— `test_multi_layer_metadata_check` in `workflow.test.sh` with
fixture changes (valid single-layer, valid multi-layer, invalid
missing-per-layer, invalid unknown-layer).

---

### FR-GL-018: Standard `global/multi-layer-workflow.md` formalizes the routing policy

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — a file `.forge/standards/global/multi-layer-workflow.md`
  exists and contains these canonical H2 sections :
    - `## Routing Policy` — when `/forge:design|implement|review` is
      invoked, how the dispatcher chooses between the single-layer
      orchestrator (Hera / Vulcan / Atlas) and Janus.
    - `## `.forge.yaml` Multi-Layer Schema` — documents the
      `layers:` / `designs_per_layer:` / `tasks_per_layer:` fields
      with examples.
    - `## Per-Layer Design Convention` — what each
      `design-<layer>.md` file contains (FR-ID prefix, cross-layer
      references, standards loaded).
    - `## Per-Layer Tasks Convention` — per-layer TDD-ordered tasks
      files, phase numbering convention when several per-layer tasks
      files coexist.
    - `## Cross-Layer Contract Alignment` — rules Janus enforces
      (proto-contract coherence, shared interfaces, versioning
      coherence, delta across layers).
    - `## Interdictions` — non-negotiable rules (no layer writes
      outside its subtree except protos ; no direct dispatch to
      per-layer agent when `layers:` has ≥ 2).
- **MUST** — the standard cites Article V, VI.2, VII.3, VIII, IX.4,
  and cross-references `global/monorepo-layout.md` (archived in
  `b1-foundations`).
- **SHALL** — the standard includes one worked example of a
  hypothetical cross-layer change (backend + frontend) with its
  resulting `.forge/changes/<name>/` tree.

**Constitution reference:** Article V, VI, VII, VIII, X.
**Testable:** yes — section-presence check via
`check_standard_multi_layer_workflow` in validator.

---

### FR-GL-019: Index references `global/multi-layer-workflow.md`

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — `.forge/standards/index.yml` contains one new entry :
    - `id: global/multi-layer-workflow`, `path: standards/global/multi-layer-workflow.md`,
      `scope: monorepo`, `priority: high`, triggers including
      `multi-layer`, `janus`, `cross-layer`, `layers:`, `layers count`.
- **SHALL** — purely additive ; no pre-existing entry is modified.

**Constitution reference:** Article V (JIT loading via index).
**Testable:** yes — existing `check_index_new_entries` pattern
extended to validate the new entry.

---

### FR-GL-020: Per-layer design and tasks templates

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — two new templates exist under `.forge/templates/` :
    - `design-per-layer.md` — per-layer design template. Same
      sections as `design.md` (ADRs, Component Design, Data Flow,
      Testing Strategy, Standards Applied, Security, Observability)
      but scoped to ONE layer. Header comment declares which layer
      the file targets (`<!-- Layer: backend -->`).
    - `tasks-per-layer.md` — per-layer tasks template. Phase
      numbering continues from the sibling tasks files using a
      layer-prefix convention (e.g. Backend Phase 1, Frontend Phase
      1) to avoid ambiguity.
- **MUST** — both templates carry the `<!-- Audit: B.1.6 -->`
  header.
- **SHOULD** — both templates include a leading `## Cross-Layer
  References` section documenting which FR-GL-* requirements this
  per-layer slice satisfies (for traceability).

**Constitution reference:** Article III.2, Article X.3. **Testable:**
yes — file existence + section-presence check.

---

### FR-BE-002: Layer-scoped Rust checks in `verify.sh`

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — `verify.sh` detects the `full-stack-monorepo` schema
  at the target's `.forge.yaml` and, when matched, runs a new
  **Backend** section scoped to `<FORGE_ROOT>/backend/` :
    - `cargo clippy --all-features --manifest-path backend/Cargo.toml -- -D warnings`.
    - `cargo fmt --all --manifest-path backend/Cargo.toml --check`.
    - `cargo test --all-features --manifest-path backend/Cargo.toml`.
    - Domain-purity check scoped to `backend/crates/domain/src/` :
      zero `sqlx`/`reqwest`/`hyper`/`tonic` imports.
    - No `unwrap()` / `panic!()` in `backend/**/src/` (production code
      only ; `#[cfg(test)]` blocks excluded).
- **MUST** — each emitted PASS/FAIL/WARN line is prefixed `[backend] ...`
  so the aggregated output is unambiguous.
- **MUST** — when `backend/` does not exist OR the schema is not
  `full-stack-monorepo`, the Backend section is SKIPPED (with a
  one-line skip message) — not failed.

**Constitution reference:** Article VII.3. **Testable:** yes —
fixture with a minimal backend/ tree ; harness asserts
`[backend] ...` lines emitted and exit 0.

---

### FR-FE-002: Layer-scoped Flutter checks in `verify.sh`

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — same shape as FR-BE-002 but for the Flutter layer :
    - `flutter analyze --fatal-infos <FORGE_ROOT>/frontend`.
    - `dart format --output=none --set-exit-if-changed frontend/lib`.
    - `flutter test --coverage <FORGE_ROOT>/frontend`.
    - Coverage threshold 80 % on `frontend/coverage/lcov.info`
      (inherited from `tdd-rules.md`).
    - Layer-boundary check : zero `import 'package:flutter'` under
      `frontend/lib/features/*/domain/`.
- **MUST** — lines prefixed `[frontend] ...`.
- **MUST** — SKIPPED when `frontend/` absent OR schema mismatch.

**Constitution reference:** Article VI.2. **Testable:** yes —
fixture with a minimal frontend/ tree.

---

### FR-GL-021: Layer-scoped protos + infra checks in `verify.sh`

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — new **Protos** section (prefix `[protos] ...`) runs when
  `<FORGE_ROOT>/shared/protos/` exists AND schema is
  `full-stack-monorepo` :
    - `buf lint` (blocking).
    - `buf breaking --against '.git#branch=main'` (blocking in
      existing namespaces, WARN when `main` branch is absent on the
      seed commit).
- **MUST** — new **Infra** section (prefix `[infra] ...`) runs
  similarly :
    - `docker compose -f <FORGE_ROOT>/docker-compose.dev.yml config`
      returns exit 0 (validates syntax).
    - Every `<FORGE_ROOT>/infra/kong/*.yml` parses as YAML (python3
      `yaml.safe_load`).
    - Every `<FORGE_ROOT>/infra/k8s/**/kustomization.yaml` parses
      as YAML.
- **MUST** — both sections SKIP gracefully when their subtree or
  tool is absent (WARN, not FAIL).

**Constitution reference:** Article IV, Article VIII, Article IX.4.
**Testable:** yes — fixture-based.

---

### FR-GL-022: Layer-scoped `constitution-linter.sh` activation

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — `constitution-linter.sh` detects the
  `full-stack-monorepo` schema at the target root and, when matched,
  scopes the Article VI checks to `frontend/` and the Article VII
  checks to `backend/` (instead of scanning the repo root which
  currently yields `N/A`).
- **MUST** — when schema is other, the existing single-root behavior
  is preserved byte-for-byte.
- **SHALL** — emit `[scoped: frontend]` / `[scoped: backend]`
  in the section header so the activation is visible in the output.

**Constitution reference:** Article VI, Article VII. **Testable:**
yes — fixture tests compare scoped vs non-scoped behavior.

---

### FR-GL-023: Workflow test harness (`workflow.test.sh`)

<!-- From change: b1-workflow (2026-04-22) -->

- **MUST** — a new harness `.forge/scripts/tests/workflow.test.sh`
  exists and exercises :
    - **L1** — Janus agent file structure (required sections, routing
      table present, mythological pattern consistent with other
      Forge agents). Hermetic, no external tools.
    - **L2** — multi-layer metadata check via fixtures : valid
      single-layer, valid multi-layer (complete), invalid
      multi-layer (missing per-layer files), invalid (unknown layer
      id). Hermetic.
    - **L2** — multi-layer-workflow standard section-presence check.
      Hermetic.
    - **L3** — fixture-based multi-root `verify.sh` : a minimal
      tree with `frontend/pubspec.yaml` + `backend/Cargo.toml` +
      `shared/protos/` stubs ; assert scoped sections emit `[<layer>] ...`
      lines. Requires `flutter` / `cargo` / `buf` ; auto-skip
      otherwise (same convention as scaffolder L3).
- **MUST** — the harness uses `.forge/scripts/tests/_helpers.sh`
  for shared helpers.
- **MUST** — `verify.sh` invokes this harness at `--level 2`
  (hermetic) as a new **Section 7 : Workflow (conditional)** when
  the archetype template tree exists.

**Constitution reference:** Article I (TDD), Article V. **Testable:**
self-testing — harness validates its own outputs on fixtures.

---

## MODIFIED Requirements

### FR-GL-008 — validator gains the Section 7 dispatch

<!-- Modified in change: b1-workflow (2026-04-22) -->
<!-- Previously: the validator had 7 FR checks + the Monorepo
     Foundations conditional dispatch in verify.sh. -->
<!-- Now: the validator AND verify.sh gain a new Workflow conditional
     dispatch that runs the multi-layer metadata check (FR-GL-017). -->

- **Previously** — `validate-foundations.sh` exposed checks for
  FR-GL-001..007 plus the Section 5 conditional dispatch in
  `verify.sh`.
- **Now** — the same script additionally exposes
  `check_multi_layer_change_metadata` (FR-GL-017) and
  `check_standard_multi_layer_workflow` (FR-GL-018 validator side).
  `verify.sh` dispatch remains the same ; the new Section 7
  (Workflow) is orthogonal and handled by `workflow.test.sh` at
  `--level 2` (per FR-GL-023).
- **Reason** — multi-layer metadata check conceptually belongs to
  the foundations validator (it validates the archetype contract
  extended to the change-level metadata, not the runtime).

---

## REMOVED Requirements

<!-- None. -->

---

## Acceptance Criteria

### AC-001 — Links FR-GL-015 : Janus agent file structure

```gherkin
Given the repo head is post-b1-workflow
When a reviewer opens `.claude/agents/cross-layer-orchestrator.md`
Then the file declares name "Janus"
And the file contains a "## Routing Policy" section
And the file contains a "## 12-Step Workflow" section
And the file cites Hera, Vulcan, Atlas as primary dispatch targets
And Hermes-API is referenced for proto-contract steps
```

### AC-002 — Links FR-GL-016, FR-GL-017 : multi-layer metadata validation

```gherkin
Given a change `.forge/changes/cross-layer-demo/.forge.yaml` declares
  `layers: [backend, frontend]` and `designs_per_layer: {backend: design-backend.md, frontend: design-frontend.md}`
And both `design-backend.md` and `design-frontend.md` exist in the change directory
When `validate-foundations.sh` runs
Then the new check passes with `PASS: FR-GL-017 — multi-layer metadata OK`

Given a change declares `layers: [backend, frontend]` but omits `designs_per_layer:`
When the validator runs
Then `FAIL: FR-GL-017 — designs_per_layer missing`

Given a change declares `layers: [backend, unicorn]`
When the validator runs
Then `FAIL: FR-GL-017 — unknown layer id 'unicorn'`
```

### AC-003 — Links FR-GL-018 : standard sections

```gherkin
Given `.forge/standards/global/multi-layer-workflow.md` exists
When the foundations validator runs
Then `PASS: FR-GL-018 — multi-layer-workflow standard OK`
And the standard's required H2 headings are detected
```

### AC-004 — Links FR-BE-002, FR-FE-002 : multi-root scoped checks

```gherkin
Given a scaffolded project at /tmp/demo-app with frontend/, backend/, shared/protos/
And the schema at `.forge.yaml` is `full-stack-monorepo`
When `FORGE_ROOT=/tmp/demo-app bash verify.sh` runs
Then stdout contains lines prefixed `[backend] ...` for Rust checks
And stdout contains lines prefixed `[frontend] ...` for Flutter checks
And stdout contains lines prefixed `[protos] ...` for buf lint
And the Infra section reports compose syntax OK
```

### AC-005 — Links FR-GL-022 : single-root backwards compatibility

```gherkin
Given a non-monorepo project where `.forge.yaml` declares `schema: default`
When `verify.sh` runs at the target
Then the new Backend / Frontend / Protos / Infra sections are SKIPPED (not FAILed)
And the existing single-root checks run as before
And the output is byte-identical to the pre-b1-workflow behavior
```

### AC-006 — Links FR-GL-023 : workflow harness self-consistency

```gherkin
Given the repo head post-b1-workflow
When `bash .forge/scripts/tests/workflow.test.sh --level 2` runs
Then it exits 0
And all L1 + L2 scenarios PASS (Janus structure, metadata check, standard sections)
```

### AC-007 — Links FR-GL-015 : Janus never writes code

```gherkin
Given Janus is invoked on a cross-layer change design phase
When Janus processes the change
Then Janus dispatches to Hera (frontend) + Vulcan (backend) for their designs
And Janus ONLY aggregates their outputs + flags conflicts
And no file under frontend/ or backend/ was written by Janus itself
```

---

## Non-Functional Requirements

### NFR-009 : Multi-root verify.sh performance

<!-- Context : scoped sections add a few cargo / flutter invocations
     that are legitimately slower than the pre-b1-workflow scripts. -->

- **SHALL** — on a scaffolded project with no real domain code,
  `verify.sh` completes in less than **30 seconds** on a standard
  dev machine (warm caches). Hard ceiling : 60 seconds.
  Per-layer sections (`[backend]`, `[frontend]`) will dominate the
  runtime once real code lands ; the archetype's own invocations
  must remain fast on an empty scaffold.

### NFR-010 : Backwards compatibility of single-root scripts

- **MUST** — when a target's `.forge.yaml` declares a schema OTHER
  than `full-stack-monorepo`, `verify.sh` + `constitution-linter.sh`
  produce byte-identical stdout + same exit code as the
  pre-b1-workflow scripts. Exercised by a regression fixture in
  `workflow.test.sh` L2.

### NFR-011 : Janus agent pattern consistency

- **SHALL** — the Janus agent file follows the same Markdown
  structure as `forge-master.md`, `flutter/orchestrator.md`, and
  `rust/orchestrator.md` (identical section headings, same 12-step
  convention, same quality-gate invocation pattern). Enforced by an
  L1 structural check in `workflow.test.sh`.

### NFR-012 : Multi-layer metadata documentation

- **MUST** — `global/multi-layer-workflow.md` documents every
  optional field of the new `.forge.yaml` extension with a realistic
  example and a one-sentence purpose.

---

## Out of Scope

- **GitHub Actions CI workflows** (`B.1.9`) — `b1-delivery`.
- **`forge upgrade`** (`A.7`).
- **Environment overlays + observability** (`B.1.12`, `B.1.14`) —
  `b1-delivery`.
- **Release train / release-plz wiring** — `b1-delivery`.
- **Constitution amendments** — none required.
- **Slash command rework** beyond adding a "multi-layer branch" note
  that delegates to Janus.
- **Cross-language refactors** — archetype layers still have no
  real domain code.

---

## Open Questions

Locked from `proposal.md` — proposed resolutions pending `/forge:design` :

- `[NEEDS CLARIFICATION]` Janus + Hermes-API split on proto changes :
  proposed **delegate to Hermes-API**. Janus invokes Hermes-API in
  its step 8 when `shared/protos/` is touched.

- `[NEEDS CLARIFICATION]` `designs_per_layer:` shape : proposed **map
  with explicit keys** (`backend: design-backend.md`) — cheaper to
  query in shell/python, matches the layer enum from the archetype
  schema.

- `[NEEDS CLARIFICATION]` Layer-path detection : proposed **dynamic
  from schema.yaml** (`layers[].path`) to respect projects that
  customize the layout.

These decisions will be locked in `/forge:design b1-workflow`.
