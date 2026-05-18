# Tasks: t5-2-platform-verification
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail
  (RED), write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-T52-XXX]` (Article V.1, enforced
  by `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/t5-2.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms expected
  counter movement.
- ADRs from `design.md` (ADR-T52-001..004) are honored verbatim ;
  deviations require a new ADR.
- T5.2 is a **process change** — no production runtime code is
  modified. All implementation work is documentation +
  configuration + test harness.

---

## Phase 1 — Foundation : RED harness + CI registration

Goal : `t5-2.test.sh` exists with **8 L1 + 1 L2 stubs** ; L1
stubs FAIL (full RED witness for the 8 L1 anchors) ; L2 returns
0 (skip-pass by default per ADR-T52-002 + FR-T52-E-001) ; CI
registration done.

### T-HAR — `t5-2.test.sh` skeleton

- [x] **T-HAR-001** : Create `.forge/scripts/tests/t5-2.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`), source `_helpers.sh`, PASS/FAIL
      counters reset, `--level` parsing for `1|2|1,2|all`,
      audit comment `# Audit: T.5.2 (t5-2-platform-verification)`,
      `print_summary` close-out. Mirror the I.5 / I.6 / I.3
      layout per ADR-T52-004.
      [Story: FR-T52-D-001 / FR-T52-D-002]
- [x] **T-HAR-002** : Define the path variables at the top of
      the harness :
      - `AGENT_FILE` → `.claude/agents/document-specialist.md`
      - `LIFECYCLE_STD` → `.forge/standards/global/standards-lifecycle.md`
      - `REVIEW_MD` → `.forge/standards/REVIEW.md`
      - `CONTRIBUTING_MD` → `docs/CONTRIBUTING.md`
      - `LINTING_MD` → `docs/LINTING.md`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      - `FORGE_CI_YML` → `.github/workflows/forge-ci.yml`
      [Story: FR-T52-D-001]
- [x] **T-HAR-003** : Add **8 L1 test stubs** all returning
      `_not_implemented` covering the 8 anchor IDs from
      `specs.md` FR-T52-D-003..010 :
      - `_test_t52_l1_001_agent_file_present`
      - `_test_t52_l1_002_checklist_h2`
      - `_test_t52_l1_003_three_axes_named`
      - `_test_t52_l1_004_platform_mismatch_token`
      - `_test_t52_l1_005_lifecycle_v110`
      - `_test_t52_l1_006_re_verification_h2`
      - `_test_t52_l1_007_review_ledger_entry`
      - `_test_t52_l1_008_article_iii4_xref`
      [Story: FR-T52-D-003..010]
- [x] **T-HAR-004** [P] : Add **1 L2 test stub**
      (`_test_t52_l2_001_pubdev_tooling_smoke`) that returns 0
      by default (skip-pass per ADR-T52-002 + FR-T52-E-001).
      Implementation body (curl + grep) is filled in Phase 4.
      [Story: FR-T52-E-001 / FR-T52-E-002]
- [x] **T-HAR-005** : Add the test runner — iterate through the
      8 L1 functions, call `run_test`, gate L2 on `--level`
      containing `2` or `all` AND `FORGE_T52_LIVE=1`, call
      `print_summary`. Exit 0 if `FAIL == 0`, else 1.
      Failure messages MUST echo the failing FR-T52-* identifier
      first (NFR-T52-007).
      [Story: FR-T52-D-001 / NFR-T52-007]
- [x] **T-HAR-006** [P] : Register `t5-2.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `t5-otel-live-run.test.sh` with
      `--level 1`. Keep the file under 300 lines
      (NFR-T52-006 budget surface).
      [Story: FR-T52-H-002]
- [x] **T-HAR-007** : RED gate — confirm
      `bash .forge/scripts/tests/t5-2.test.sh --level 1` exits
      1 with `Failed: 8 / Passed: 0`. Capture output for the
      archive.
      [Story: NFR-T52-007]

### Phase 1 exit gate

`t5-2.test.sh --level 1` exits 1 with FAIL = 8. `forge-ci.yml`
matrix updated, still under 300 lines. `verify.sh` overall PASS
unchanged. `constitution-linter.sh` overall PASS unchanged.

---

## Phase 2 — Canonical procedural surface (agent file)

Goal : ship `.claude/agents/document-specialist.md` Forge-local
override per ADR-T52-001 option A. After this phase, **5 of 8 L1
tests flip GREEN** (001, 002, 003, 004, 008).

### T-AGT — Forge-local agent file

- [x] **T-AGT-001** : Create
      `.claude/agents/document-specialist.md` with H1
      `# Document Specialist (Forge-local override)` and the
      ownership HTML comment
      `<!-- Forge-local override of OMC document-specialist — adds T5.2 platform verification checklist -->`
      within the first 5 lines.
      [Story: FR-T52-A-001 / FR-T52-A-002]
- [x] **T-AGT-002** [P] : Add a short "Purpose" H2 explaining
      that this file extends the OMC `document-specialist`
      persona with Forge-specific ratification procedure (no
      new MCP tool / no new agent subprotocol per FR-T52-A-014).
      Follow the H1+H2 convention of `.claude/agents/demeter.md`
      and `.claude/agents/spec-writer.md` (FR-T52-A-015).
      [Story: FR-T52-A-014 / FR-T52-A-015]
- [x] **T-AGT-003** : Add H2 `## Platform Verification
      Checklist (3-axis)` with **exact verbatim** title (case-
      and whitespace-sensitive — ADR-T52-003). This is the
      canonical anchor referenced from all other surfaces.
      [Story: FR-T52-A-003]
- [x] **T-AGT-004** : Under the H2, write the three axes section
      naming each axis precisely :
      - **Axis 1 — Existence** : "package resolvable on the
        registry (pub.dev / crates.io / npm / Maven / etc.) with
        the pinned version"
      - **Axis 2 — API surface** : "documented symbols match
        those exposed by the actual package (verified via
        Context7 or direct inspection)"
      - **Axis 3 — Platform compatibility** : "every target
        platform declared by the consuming archetype or
        standard is listed in the package's declared support
        matrix"
      [Story: FR-T52-A-004 / FR-T52-A-005 / FR-T52-A-006]
- [x] **T-AGT-005** : Add the **MUST tick-all clause** — a
      sentence stating that each axis MUST be ticked before
      flipping the standard's status to "verified" or
      equivalent ratification state.
      [Story: FR-T52-A-007]
- [x] **T-AGT-006** : Add the `[PLATFORM MISMATCH: ...]`
      escalation clause : if any consuming-archetype target
      platform is missing from the package's declared support
      matrix, the ratification MUST emit a `[PLATFORM MISMATCH:
      ...]` marker and escalate to an ADR. Syntax MUST mirror
      the existing `[NEEDS CLARIFICATION: ...]` Article III.4
      convention.
      [Story: FR-T52-A-008]
- [x] **T-AGT-007** [P] : Add the **Q-006 worked example**
      block citing : package `opentelemetry`, version `0.18.11`,
      consuming archetype `mobile-only` or
      `full-stack-monorepo`, missing platforms `iOS`, `Android`.
      [Story: FR-T52-A-009]
- [x] **T-AGT-008** [P] : Add the per-dependency checklist
      format prescription — each ratified external dependency
      appears in the change's `proposal.md` § "Source Documents"
      as a row with three ticked checkboxes using `[x]` / `[ ]`
      Markdown task-list syntax.
      [Story: FR-T52-A-010]
- [x] **T-AGT-009** [P] : Add the **scope clarification clause**
      — the checklist applies to external dependency-pinning
      standards only ; it does NOT apply to pure prose
      contracts (`global/open-questions.md`,
      `global/standards-lifecycle.md`,
      `global/janus-orchestration-rules.md`, etc.).
      [Story: FR-T52-A-013]
- [x] **T-AGT-010** : Add the bidirectional cross-reference to
      `.forge/standards/global/standards-lifecycle.md` v1.1.0
      § `Platform compatibility re-verification` using the
      **exact verbatim H2 title** in backticks (ADR-T52-003).
      [Story: FR-T52-A-011]
- [x] **T-AGT-011** : Add the Article III.4 cross-reference —
      one sentence citing Constitution Article III.4
      (anti-hallucination) as the constitutional basis for the
      checklist. Use the literal string `Article III.4` so
      FR-T52-D-010 grep passes.
      [Story: FR-T52-A-012]
- [x] **T-AGT-012** : GREEN witness gate — run
      `bash .forge/scripts/tests/t5-2.test.sh --level 1` and
      confirm exactly 5 of 8 tests pass : 001 (file present),
      002 (H2), 003 (3 axes), 004 (PLATFORM MISMATCH token),
      008 (Article III.4 xref). Remaining 3 still FAIL.
      [Story: FR-T52-D-003..006, FR-T52-D-010]

### Phase 2 exit gate

`t5-2.test.sh --level 1` : 5 GREEN / 3 FAIL.
`.claude/agents/document-specialist.md` exists with the
canonical H2 + 3 axes + MUST tick-all + `[PLATFORM MISMATCH:`
token + Q-006 worked example + scope clarification + Article
VIII xref. `verify.sh` overall PASS.

---

## Phase 3 — Standards-lifecycle bump + REVIEW ledger

Goal : ship the additive bump `standards-lifecycle.md` v1.0.0 →
v1.1.0 per ADR-T52-001 option B + the REVIEW.md append-only
ledger entry per Article XII. After this phase, **all 8 L1 tests
flip GREEN**.

### T-STD — Standards-lifecycle v1.1.0 bump

- [x] **T-STD-001** : Read current
      `.forge/standards/global/standards-lifecycle.md`. Identify
      the frontmatter `version:` line and the
      `last_reviewed:` line. Confirm no `breaking_change:`
      field exists yet (additive bump introduces it).
      [Story: FR-T52-B-001]
- [x] **T-STD-002** : Bump frontmatter — set `version: 1.1.0`,
      set `last_reviewed: 2026-05-18`, add `breaking_change:
      false`. Existing fields preserved verbatim
      (NFR-T52-004 backward compatibility).
      [Story: FR-T52-B-001 / FR-T52-B-002 / FR-T52-B-003]
- [x] **T-STD-003** [P] : Update or append the audit comment
      `<!-- Audit: T.4 + T5.2 (additive bump 2026-05-18) -->`
      preserving the existing T.4 pointer.
      [Story: FR-T52-B-004]
- [x] **T-STD-004** : Append new H2 section at the end of the
      file (before any trailing footer, after all existing H2
      sections) :
      `## Platform compatibility re-verification`
      Title is **exact verbatim** per ADR-T52-003.
      [Story: FR-T52-B-005]
- [x] **T-STD-005** : Under the new H2, write the SHOULD clause :
      "Any standard which pins an external dependency SHOULD
      re-execute the 3-axis checklist (per
      `.claude/agents/document-specialist.md` § `Platform
      Verification Checklist (3-axis)`) during each 12-month
      review."
      [Story: FR-T52-B-006]
- [x] **T-STD-006** : Add the MUST clause for platform
      addition : "Any standard which pins an external
      dependency MUST re-execute the 3-axis checklist
      **immediately** when the consuming archetype declares a
      **new target platform** (e.g. `mobile-pwa-first` adding
      PWA Qwik in T8 relative to `mobile-only` v1.0.0, or any
      archetype declaring a new compliance tier with different
      platform constraints)."
      [Story: FR-T52-B-007]
- [x] **T-STD-007** : Add the MUST pre-ratification clause :
      "The checklist MUST be executed **before** any new
      external dependency-pinning standard is ratified (i.e.
      the first ratification, not only subsequent reviews)."
      [Story: FR-T52-B-008]
- [x] **T-STD-008** : Add the bidirectional cross-reference
      to `.claude/agents/document-specialist.md` § `Platform
      Verification Checklist (3-axis)` using the **exact
      verbatim H2 title** in backticks (ADR-T52-003).
      [Story: FR-T52-B-009]
- [x] **T-STD-009** : Add the Q-006 mention — one sentence
      citing Q-006 (Workiva web-only platform mismatch) by
      name as the incident that motivated the cadence.
      [Story: FR-T52-B-010]

### T-RVW — REVIEW.md ledger entry

- [x] **T-RVW-001** : Read current
      `.forge/standards/REVIEW.md`. Confirm the chronological
      tail (existing append-only ledger).
      [Story: FR-T52-C-003]
- [x] **T-RVW-002** : Append a new H2 entry at the end of the
      file :
      `## 2026-05-18 — standards-lifecycle.md v1.0.0 → v1.1.0`
      Pattern matches the regex
      `^## 20[0-9]{2}-[0-9]{2}-[0-9]{2} — standards-lifecycle.md v1.0.0 → v1.1.0$`
      asserted by FR-T52-D-009.
      [Story: FR-T52-C-001]
- [x] **T-RVW-003** : Body of the ledger entry MUST cite (a)
      the change name `t5-2-platform-verification`, (b) the
      trigger incident `Q-006`, (c) the new H2 anchor `Platform
      compatibility re-verification`, and (d) `breaking_change:
      false`.
      [Story: FR-T52-C-002]
- [x] **T-RVW-004** : Verify all prior H2 entries in
      `REVIEW.md` are byte-identical to their pre-T5.2 state
      (Article XII immutability). Diff against `git show`
      origin.
      [Story: FR-T52-C-003 / NFR-T52-008]

### T-GATE-3 — Phase 3 GREEN witness

- [x] **T-GATE-3-001** : Run
      `bash .forge/scripts/tests/t5-2.test.sh --level 1` and
      confirm **all 8 L1 tests pass** (FAIL = 0). Confirm
      tests 005 (lifecycle v1.1.0 frontmatter), 006
      (re-verification H2), 007 (REVIEW ledger entry) have
      flipped GREEN.
      [Story: FR-T52-D-005 / FR-T52-D-006 / FR-T52-D-009]
- [x] **T-GATE-3-002** [P] : Run `bash .forge/scripts/verify.sh`
      and confirm overall PASS (no schema regression on the
      standards-lifecycle frontmatter bump — J.7 still happy
      because frontmatter remains valid YAML).
      [Story: NFR-T52-004]

### Phase 3 exit gate

`t5-2.test.sh --level 1` : 8 GREEN / 0 FAIL.
`standards-lifecycle.md` v1.1.0 with new H2 + bidirectional xref.
`REVIEW.md` carries the append-only ledger entry.
`verify.sh` overall PASS. `constitution-linter.sh` overall PASS.

---

## Phase 4 — Documentation surfaces + L2 live-run + CHANGELOG

Goal : ship the four remaining secondary surfaces (CONTRIBUTING,
LINTING, CHANGELOG, harness L2 body) and verify L2 live-run
works locally.

### T-DOC — `docs/CONTRIBUTING.md`

- [x] **T-DOC-001** : Read `docs/CONTRIBUTING.md`. Locate or
      add a section whose H2 or H3 heading mentions "Adding a
      Standard" (FR-T52-F-001).
      [Story: FR-T52-F-001]
- [x] **T-DOC-002** : In the "Adding a Standard" section, add a
      paragraph cross-referencing
      `.claude/agents/document-specialist.md` § `Platform
      Verification Checklist (3-axis)` using the **exact
      verbatim H2 title** in backticks (ADR-T52-003 +
      FR-T52-F-002). Option (b) preferred over option (a) per
      drift-prevention NFR-T52-010.
      [Story: FR-T52-F-002]
- [x] **T-DOC-003** [P] : Add one sentence mentioning Q-006
      (Workiva web-only) by name as the incident that
      motivated the checklist (FR-T52-F-003). At most one
      sentence of context — full body lives in the agent file.
      [Story: FR-T52-F-003]

### T-LNT — `docs/LINTING.md`

- [x] **T-LNT-001** : Read `docs/LINTING.md`. Locate or add an
      "Informative rules" or "Process rules" section.
      [Story: FR-T52-G-001]
- [x] **T-LNT-002** : Add a paragraph or bullet noting that the
      3-axis platform-verification checklist exists. The
      paragraph MUST clarify that the checklist is
      **procedural**, not enforced by `constitution-linter.sh`
      (T5.2 ships the convention ; enforcement is future work).
      [Story: FR-T52-G-001]
- [x] **T-LNT-003** : Add the cross-reference to
      `.claude/agents/document-specialist.md` § `Platform
      Verification Checklist (3-axis)` using the **exact
      verbatim H2 title** in backticks (ADR-T52-003).
      [Story: FR-T52-G-002]

### T-L2 — Harness L2 live-run body

- [x] **T-L2-001** : Implement the body of
      `_test_t52_l2_001_pubdev_tooling_smoke` per ADR-T52-002 :
      - HTTP GET `https://pub.dev/packages/flutter_bloc` with
        `curl --max-time 10 --silent --fail --show-error`.
      - On non-2xx or curl exit ≠ 0 → skip-pass with explicit
        transport-failure marker `[SKIP: pub.dev unreachable]`
        (FR-T52-E-003).
      - Grep HTML body for the literal substring `Platforms`
        (the chip label on pub.dev).
      - Grep HTML body for at least one platform token among
        `Android`, `iOS`, `Linux`, `macOS`, `Web`, `Windows`.
      - Both greps present → PASS. Either grep missing with
        transport successful → FAIL.
      [Story: FR-T52-E-002]
- [x] **T-L2-002** [P] : Enforce the 20 s hard timeout via
      `timeout 20 bash -c '...'` or equivalent ; convert
      overruns to skip-pass with `[SKIP: timeout >20s]`
      (FR-T52-E-004).
      [Story: FR-T52-E-004]
- [x] **T-L2-003** : Run
      `FORGE_T52_LIVE=1 bash .forge/scripts/tests/t5-2.test.sh --level 1,2`
      locally and confirm the L2 test PASSES (assuming
      network reachable). Capture the output for the archive.
      Verify total wall-clock ≤ 15 s (NFR-T52-002).
      [Story: FR-T52-E-002 / NFR-T52-002]
- [x] **T-L2-004** [P] : Run
      `bash .forge/scripts/tests/t5-2.test.sh --level 1,2`
      **without** the env-var and confirm L2 emits skip-pass
      (does not run curl).
      [Story: FR-T52-E-001]

### T-CHG — CHANGELOG entry

- [x] **T-CHG-001** : Edit `CHANGELOG.md`. Locate the
      `## [Unreleased]` heading (or create one if the latest
      release is the tail).
      [Story: FR-T52-H-001]
- [x] **T-CHG-002** : Add a bullet under the `### Added` or
      `### Changed` subsection of the next patch line :
      `- T5.2: Anti-hallucination platform-verification
      checklist (3-axis) added to document-specialist agent +
      standards-lifecycle.md v1.1.0`. Cite the change name
      `t5-2-platform-verification` verbatim.
      [Story: FR-T52-H-001]

### Phase 4 exit gate

`t5-2.test.sh --level 1` : 8 GREEN. `t5-2.test.sh --level 1,2`
with `FORGE_T52_LIVE=1` : 9 GREEN (8 L1 + 1 L2). `t5-2.test.sh
--level 1,2` without env-var : 8 GREEN + 1 SKIP. `docs/CONTRIBUTING.md`
and `docs/LINTING.md` carry the cross-references. `CHANGELOG.md`
gains the entry.

---

## Phase 5 — Quality gate + archive prep

### T-QA — Quality gate

- [x] **T-QA-001** : Run `bash .forge/scripts/verify.sh` and
      confirm overall PASS (target : Passed ≥ 252, Failed = 0).
      [Story: NFR-T52-004]
- [x] **T-QA-002** [P] : Run
      `bash .forge/scripts/constitution-linter.sh` and confirm
      overall PASS. The Article III.4 reinforcement does not
      add a new linter rule (FR-T52-G-001 explicit), so the
      linter output is unchanged.
      [Story: NFR-T52-009]
- [x] **T-QA-003** : Run
      `bash bin/validate-standards-yaml.sh` (J.7) and confirm
      `state-management.yaml` / `transport.yaml` /
      `observability.yaml` / `orchestration.yaml` /
      `identity.yaml` / `persistence.yaml` still validate.
      The `standards-lifecycle.md` bump is documentation not
      YAML so J.7 does not assert it ; this confirms no
      collateral damage on the YAML standards.
      [Story: NFR-T52-005]
- [x] **T-QA-004** [P] : Run `bash bin/forge-questions.sh
      --change t5-2-platform-verification` and confirm both
      Q-001 + Q-002 are listed as `answered`. Confirm Open
      Questions Gate would pass at archive time.
      [Story: FR-T52-H-003]
- [x] **T-QA-005** : Grep across the repo for the two canonical
      H2 titles :
      - `grep -rn "Platform Verification Checklist (3-axis)" .`
        — expect 4 hits : agent file (H2), CONTRIBUTING xref,
        LINTING xref, REVIEW ledger body or specs/design refs
        (some may be in `.forge/changes/t5-2-platform-verification/*`).
      - `grep -rn "Platform compatibility re-verification" .`
        — expect ≥ 2 hits : lifecycle H2, agent file xref,
        specs/design references.
      Confirm no paraphrased title slips through (ADR-T52-003
      drift guard).
      [Story: NFR-T52-010]
- [x] **T-QA-006** [P] : Wall-clock benchmark — time both
      `--level 1` and `--level 1,2` runs of `t5-2.test.sh`.
      Confirm ≤ 5 s for L1, ≤ 15 s for L1+L2 with
      `FORGE_T52_LIVE=1` (NFR-T52-002).
      [Story: NFR-T52-002]

### T-ARC — Archive preparation

- [x] **T-ARC-001** : Update
      `.forge/changes/t5-2-platform-verification/.forge.yaml` :
      `status: implemented`, append `timeline.implemented:
      2026-05-18`.
      [Story: process]
- [x] **T-ARC-002** [P] : Authoring strategy step 8 (per
      `design.md::Authoring Strategy`) : capture
      `FORGE_T52_LIVE=1` L2 run output for the archive evidence
      (PR description or `.forge/changes/<name>/evidence/`).
      [Story: FR-T52-E-002 / NFR-T52-003]
- [x] **T-ARC-003** : Stage all changed files, run
      `git status` and confirm the diff covers exactly :
      - `.claude/agents/document-specialist.md` (new)
      - `.forge/standards/global/standards-lifecycle.md` (modified)
      - `.forge/standards/REVIEW.md` (modified)
      - `.forge/scripts/tests/t5-2.test.sh` (new)
      - `.github/workflows/forge-ci.yml` (modified)
      - `docs/CONTRIBUTING.md` (modified)
      - `docs/LINTING.md` (modified)
      - `CHANGELOG.md` (modified)
      - `.forge/changes/t5-2-platform-verification/**` (new)
      No other files touched (NFR-T52-005 + NFR-T52-006).
      [Story: NFR-T52-005 / NFR-T52-006]

### Phase 5 exit gate

`verify.sh` PASS. `constitution-linter.sh` PASS. `t5-2.test.sh
--level 1,2` GREEN with `FORGE_T52_LIVE=1`. Git diff scoped to
the 9 paths above. `.forge.yaml` status `implemented`. Ready
for `/forge:review t5-2-platform-verification` then
`/forge:archive t5-2-platform-verification`.

---

## Out-of-band rationale

- **No Phase for code changes** — T5.2 ships zero runtime code.
  All work is documentation + harness + CI config. The "GREEN"
  state for FR-T52-A-* is satisfied by Markdown content, not
  bytecode.
- **No widget/integration/E2E tests** — N/A (no UI, no CLI
  surface change per NFR-T52-006).
- **No performance or a11y phase** — N/A (process change).
- **L2 opt-in is the only network-dependent task** —
  `FORGE_T52_LIVE=1` mirrors `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`
  ; CI runs at `--level 1` only ; the L2 leg is only exercised
  locally by the change author before archive.

---

## Constitutional Compliance Gate (per phase)

| Phase | Article I (TDD) | Article III (Specs) | Article V (Audit) | Article III.4 | Article XII | Verdict |
|---|---|---|---|---|---|---|
| Phase 1 | RED witness 8/8 fail | All tasks tagged `[Story: FR-T52-D-*]` | Harness audit comment | N/A | N/A | ✅ |
| Phase 2 | GREEN witness expected for 5 anchors | All tasks tagged `[Story: FR-T52-A-*]` | HTML override comment | Article III.4 xref | N/A | ✅ |
| Phase 3 | GREEN witness expected for 3 more anchors (total 8) | All tasks tagged `[Story: FR-T52-B-* / -C-*]` | REVIEW.md append-only | Reinforced | Additive bump v1.0.0 → v1.1.0 | ✅ |
| Phase 4 | L2 live-run capture | All tasks tagged `[Story: FR-T52-E-* / -F-* / -G-* / -H-*]` | CHANGELOG entry | Cross-references locked | N/A | ✅ |
| Phase 5 | All gates GREEN | Q-001 + Q-002 answered | Git diff scoped | NFR-T52-009 verified | NFR-T52-008 verified | ✅ |

**No BLOCK conditions raised.** All tasks honor TDD ordering
(test → implementation), all are tagged with FR identifiers,
none bypass specs.

---

> **Next step** : `/forge:implement t5-2-platform-verification`
> to execute the 40 tasks above in TDD order. Foundation phase
> (T-HAR) ships RED first ; subsequent phases flip anchors
> GREEN cluster-by-cluster.
