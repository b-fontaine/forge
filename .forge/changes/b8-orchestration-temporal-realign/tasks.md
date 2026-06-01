<!-- Audit: B.8.5 follow-on (b8-orchestration-temporal-realign) -->
# Tasks: b8-orchestration-temporal-realign

TDD-ordered. **Critical ordering (sibling-harness coupling):** the
`orchestration.yaml` + `2.0.0.yaml` flips (P2/P3) transiently turn `b8-5.test.sh`
RED until its T-006 + T-010 are repurposed (P4) — P2→P3→P4 are ONE tight block;
`b8-5` is re-run GREEN only at the end of P4, never pushed RED. Concrete
`temporalio-*` crate version is **verify-then-pin LIVE** (P0) — never fabricated
(Article III.4; b8-coroot/dartastic lessons). Scope reminder: this change does
**not** create a Temporal worker template / `Cargo.toml` (downstream brick) — it
realigns the `temporal.md` standard + records the crate family.

## Phase 0 — Verify-then-pin (LIVE, before temporal.md is rewritten)
- [x] **T001** Verify LIVE (crates.io / docs.rs) the real Temporal Rust crate
  name(s) + current version + the closure-registration API
  (`Worker::new_from_core`, `register_wf`/`register_activity`, `WfContext`/
  `ActContext`, `WfExitValue`, `CoreRuntime`/`WorkerConfig`/`init_worker`,
  `ClientOptions`) + the pre-alpha status. Record in `evidence.md` (crate name,
  version, source URLs, the verbatim pre-alpha statement). If the registry
  contradicts the design shape → `[NEEDS CLARIFICATION]`, do NOT guess.
  [Story: FR-B8O-023, NFR-B8O-002]

## Phase 1 — Harness RED
- [x] **T002** Author `.forge/scripts/tests/b8o.test.sh` (L1, grep/python, ≤5s,
  zero new dep) asserting the TARGET state (orchestration.yaml v1.2.0 +
  `default_by_language.rust == temporal` + `dbos.status == future-option` + no
  flat `^default:` scalar + `forbidden:[inngest]` kept; 2.0.0.yaml dbos-embedded
  `status: future-option` + temporal→dbos delta `cancelled: true`; temporal.md
  free of `#[workflow]`/`#[activity]`; "pre-alpha" caveat present; no concrete
  `temporalio-*` version outside evidence). Run → **RED**. [Story: FR-B8O-050]

## Phase 2 — orchestration.yaml C-map bump (start of the tight block)
- [x] **T003** `orchestration.yaml` 1.1.0 → 1.2.0: add `default_by_language:
  { rust: temporal }`; add `dbos:` future-option block (`status: future-option`,
  `available: false`, `requires: rust-sdk-ga`, `revisit: 2027-05-31`, `note:`);
  add `temporal:` block (`crate_family` from T001 evidence, `stability:
  pre-alpha` — NO version); **drop** flat `default:`/`fallback:`/`fallback_trigger:`;
  fold the v1.1.0 `rust_sdk_status.dbos` facts (keep `available: false`) into
  `dbos:`; keep `forbidden:[inngest]`; reset `last_reviewed:2026-06-01`/
  `expires_at:2027-05-31`. [Story: FR-B8O-001..008]
- [x] **T004** Append REVIEW.md `| orchestration.yaml | 1.2.0 | … KEEP-WITH-CHANGES`
  row (1.1.0 row stays — append-only). Confirm `index.yml` orchestration triggers
  still reachable. [Story: FR-B8O-005/007]
- [x] **T005** `validate-standards-yaml.sh .forge/standards/` (dir-mode) +
  file-mode → exit 0, `[STD-PASS] …orchestration.yaml`. [Story: FR-B8O-004]

## Phase 3 — 2.0.0.yaml candidate reclassify (b8-3/b8-3b-safe)
- [x] **T006** `2.0.0.yaml`: `dbos-embedded` `status: deferred → future-option`
  + reconciled `note:`; **remove** `replaces: temporal-intent` (Temporal not
  replaced); keep `name`/`role`/`standard:`. Reclassify the `temporal-intent →
  dbos-embedded` delta IN PLACE with `cancelled: true` + `note:` (keep the entry
  — T-013 count). Fix the `:76` inline comment (FR-B8O-019). Strengthen the
  header §VIII.2 note. Postgres component/delta UNTOUCHED. [Story: FR-B8O-010/011/015/016/019]
- [x] **T007** Re-run `b8-3.test.sh --level 1` (==17) + `b8-3b.test.sh --level 1`
  (==12) → MUST stay GREEN. [Story: FR-B8O-012/013]

## Phase 4 — Repurpose b8-5 sibling harness (closes the tight block)
- [x] **T008** Repurpose `b8-5.test.sh` **T-006**: retarget `^default: dbos` →
  `default_by_language.rust == temporal`; `dbos-embedded status==deferred` →
  `==future-option`; retarget the literal `rust_sdk_status` grep (`:151`) → the
  `dbos:` block; keep `available: false` grep. Update the FR/ADR comment
  (supersedes ADR-B85-005/006 via ADR-B8O-002/003). [Story: FR-B8O-017]
- [x] **T009** Repurpose `b8-5.test.sh` **T-010**: retarget the delta-note
  `*DEFERRED*`/`*no Rust SDK*` assertion → assert the temporal→dbos delta carries
  `cancelled: true` (+ no-Rust-SDK reason); KEEP the postgres-16-intact assertion
  (`:283`). [Story: FR-B8O-017]
- [x] **T010** Run `b8-5.test.sh --level 1` → GREEN (block complete; standard +
  schema + harness now consistent). [Story: FR-B8O-014]

## Phase 5 — temporal.md API realign
- [x] **T011** Rewrite `temporal.md` code samples to the real closure API (from
  T001 evidence) — remove all `#[workflow]`/`#[activity]` macros; add a
  "Stability" H2 (native `temporalio-sdk` pre-alpha / API-may-change / no support
  guarantees; Core crates production); preserve the API-accurate Rules. No
  concrete version outside the evidence-sourced dependency note. [Story: FR-B8O-020/021/022/025/026]

## Phase 6 — Stale remediation text (two sites)
- [x] **T012** Update `constitution-linter.sh:802` hint → Temporal default;
  T3-RULE-003 mapping + `forbidden:[inngest]` unchanged. [Story: FR-B8O-018]
- [x] **T013** Update `forbidden-components-rules.md:62` T3-RULE-003 Remediation
  cell → Temporal default (cross-link ADR-B8O-001); if the doc carries a version
  frontmatter, bump + append REVIEW.md row; no T3-RULE-006 forbidden-token
  cross-mention. Re-run `i3.test.sh` (anchor unchanged) + `constitution-linter.sh`
  OVERALL PASS. [Story: FR-B8O-018]

## Phase 7 — Roadmap deltas
- [x] **T014** `docs/new-archetypes-plan.md`: strike B.8.5 DBOS-templates premise;
  drop B.8.10 Phase-2 DBOS leg; remove B.8.13 DBOS-saturation rollback; add §6.1
  B.6.2 note (native `temporalio-sdk` supersedes "Temporal Go SDK via FFI/REST",
  + pre-alpha caveat). [Story: FR-B8O-040/041/042/043]

## Phase 8 — b8o GREEN + integration
- [x] **T015** Run `b8o.test.sh` → GREEN. [Story: FR-B8O-050]
- [x] **T016** Register `b8o.test.sh` one-line in `.github/workflows/forge-ci.yml`
  harness loop. CHANGELOG `[Unreleased]` entry. [Story: FR-B8O-051]

## Phase 9 — Full gate sweep (PRE-push)
- [x] **T017** FULL ~42-harness suite (mirror forge-ci loop; skip versioned
  `N.N.N/` subtrees) + `verify.sh` PASS + `constitution-linter.sh` PASS + J.7
  dir-mode + b8-3 17/17 + b8-3b 12/12 + b8-5 (repurposed) GREEN + i3 + b8o GREEN.
  Confirm frozen 1.0.0 `schema.yaml` + flat tree byte-untouched; constitution.md
  UNTOUCHED. [Story: FR-B8O-052, NFR-B8O-001/005]

## Phase 10 — Flip + post-flip re-run + independent review
- [x] **T018** Flip `.forge.yaml` `planned → implemented`; **RE-RUN** the full
  suite POST-flip (b8-coroot lesson — gates re-run after the flip, not only
  before). [Story: FR-B8O-053]
- [x] **T019** INDEPENDENT reviewer validates the implementation (re-reads live
  files + re-executes the coupled harnesses; does NOT trust the author transcript)
  before archive. Author does NOT self-approve. [Story: FR-B8O-032, NFR-B8O-005]

---

**Constitutional gate (per task):** every task is additive standard-bump /
candidate-edit / doc / test work — no TDD bypass (T002 is RED-first), no
spec bypass, no architecture-article violation. §VIII.2 is ALIGNED, not amended;
`constitution.md` is never edited. No `[TASK VIOLATION]`.
