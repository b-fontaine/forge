# Tasks: b7-1-schema

<!-- Status: implemented -->
<!-- Schema: default -->
<!-- Audit: B.7.1 (docs/new-archetypes-plan.md §6.2 — ai-native-rag/1.0.0 archetype scaffold schema) -->

TDD-ordered (Article I — RED before GREEN, always). The deliverable is one
declarative schema file + its dedicated harness. Per design.md the harness is
authored FIRST and must fail (no schema file) before the schema is written.
Constitution gate run per task (results inline; none blocks).

## Phase 1: RED — failing harness

- [x] **T1.1** Author `.forge/scripts/tests/b7-1.test.sh` skeleton (bash thin +
  Python 3 inline, **no pyyaml** for the grep-level asserts — mirror `b8-3.test.sh`
  pattern; `--level 1` L1 hermetic). Assertions: schema file exists at
  `.forge/schemas/ai-native-rag/1.0.0.yaml`; `name: ai-native-rag` / `version:
  "1.0.0"` / `stage: candidate` / `scaffoldable: false`; layers ⊇ {backend,
  frontend,infra} each with id/path/fr_id_prefix/primary_agent; `frontend.surfaces`
  has a `qwik` web-public entry; inlined `phases` include `ai_brainstorm` +
  `embeddings-pipeline` + `prompt-audit`; `ai_specifics` block present
  (fallback_mandatory/pii_handling/token_budget); components are reference-only
  (no inline version pin) and `llm-gateway`/`mcp-servers`/`rag-pipeline` carry
  `delivered_by: B.7.3`. [Story: FR-B7-1-001..032, NFR-B7-1-004]
- [x] **T1.2** Run `bash .forge/scripts/tests/b7-1.test.sh --level 1` → **verify
  RED** (schema file absent ⇒ all content asserts fail-loud). Capture the RED
  output as evidence. [Gate: Article I — must observe failure before GREEN]

## Phase 2: GREEN — author the schema file

- [x] **T2.1** Create `.forge/schemas/ai-native-rag/1.0.0.yaml` with the candidate
  header block + identity fields `name: ai-native-rag`, `version: "1.0.0"`,
  `stage: candidate`, `scaffoldable: false` (filename↔version invariant; b8-3b
  candidate⇒scaffoldable:false). [Story: FR-B7-1-002/003/005]
- [x] **T2.2** Add `tdd_enforced: true`, `bdd_required_for_user_facing: true`,
  `coverage_threshold: 80`, `ai_fallback_required: true`, `description`. [Story:
  FR-B7-1-004] [P]
- [x] **T2.3** Add `layers` triple (backend→Vulcan, frontend→Hera with
  `surfaces:[web-public/qwik]`, infra→Atlas) + `fr_id_prefix_cross_layer: FR-GL-`
  + `cross_layer.agent: Janus` (layers_count_ge 2). [Story: FR-B7-1-010..013,
  ADR-B7-1-004] [P]
- [x] **T2.4** Add the **inlined** `phases` (ai_brainstorm → proposal → specs →
  `embeddings-pipeline` → features → design → `prompt-audit` → tasks →
  implementation → review → archive) + `extends: ai-first` documentary key
  (commented non-load-bearing) + `ai_specifics` block. [Story: FR-B7-1-020..024,
  ADR-B7-1-001] [P]
- [x] **T2.5** Add `components` reference-only: existing standards by filename
  (persistence/orchestration/identity/transport/web-frontend/observability) +
  `llm-gateway`/`mcp-servers`/`rag-pipeline` marked `delivered_by: B.7.3` with NO
  inline pin (no `rmcp`/pgvector-crate version committed). [Story: FR-B7-1-030..032,
  ADR-B7-1-003] [P]
- [x] **T2.6** Run `b7-1.test.sh --level 1` → **verify GREEN** (all asserts pass).
  [Gate: Article I — GREEN observed]

## Phase 3: Integration

- [x] **T3.1** Run `bash .forge/scripts/validate-foundations.sh` → confirm
  `FR-GL-001-versioned:ai-native-rag/1.0.0.yaml` **PASS** (the b8-3b generic
  validator now sees the new sibling). [Story: NFR-B7-1-003]
- [x] **T3.2** Confirm `forge init <name> --archetype ai-native-rag --org <rd>`
  → **exit 2** (clean refusal — "unknown archetype"; `init.ts:210` dispatch-table
  gate fires before the schema layer, ai-native-rag not yet registered). Verified
  live (rc=2). The exit-3 `selectScaffoldableVersion`-null path is downstream,
  active once B.7.2 registers the archetype (Q-005). L2 fixture in `b7-1.test.sh`
  (`--level 2`, opt-in `FORGE_B7_1_LIVE`, skip-pass if CLI not built). [Story:
  NFR-B7-1-002]
- [x] **T3.3** Register `b7-1.test.sh` in `.github/workflows/forge-ci.yml` test
  matrix (after the prior B.7 entry / per array order). [Story: NFR-B7-1-004]

## Phase 4: Quality

- [x] **T4.1** Run `verify.sh` + `constitution-linter.sh` → **no regression**
  (OVERALL PASS). [Story: NFR-B7-1-003]
- [x] **T4.2** `git diff --name-only` → only NEW files (the schema + harness +
  CI-matrix line + change artifacts); **no existing schema/standard/constitution/
  CLI/template edited**. [Story: NFR-B7-1-001]
- [x] **T4.3** REFACTOR: tidy header comments / section anchors; re-run the full
  `b7-1.test.sh` + `validate-foundations.sh` → still GREEN. [Gate: behavior
  unchanged]
- [ ] **T4.4** `/forge:review b7-1-schema` — **independent code-reviewer APPROVE +
  maintainer ratification** of ADR-B7-1-001..004 (Article V — not self-approved;
  the design-phase resolutions are pending ratification per open-questions.md).

## Constitution Gate (per task) — summary
- TDD order enforced: harness RED (T1.2) precedes schema GREEN (T2.6). ✓
- No spec bypass: every task cites its FR/NFR/ADR. ✓
- Architecture: additive config schema, no Flutter/Rust/infra code; §VIII consumed
  as-is; XI materialised. ✓
- **No [TASK VIOLATION].**

## Parallelization notes
- T2.2–T2.5 are `[P]` — independent sections of the same file; author together,
  then the single GREEN gate (T2.6) validates the assembled file.
- Phase 3 is sequential after a green Phase 2.
