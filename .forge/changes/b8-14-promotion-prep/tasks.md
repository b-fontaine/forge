# Tasks: b8-14-promotion-prep

**Status**: planned → 2026-06-04 · Constitution 1.1.0
Prepare-only governance brick. TDD: harness (negative held-guards + positive
staged-artifact checks) RED-first, then author the staged artifacts to GREEN.
Applies NOTHING breaking.

## Phase 1: Harness first (RED)

- [x] T-001 Write `.forge/scripts/tests/b8-14.test.sh` (set -uo pipefail, path
      vars, manifest, `--level` parse, `_helpers.sh`, counters). [Story: NFR-001]
- [x] T-002 Negative held-state guards (Group 4): constitution still `v1.1.0`
      (030a) + §VIII.1 still "Kong SHALL" (030b) + no gateway/Envoy Amendments row
      (030c); `2.0.0.yaml` still `stage: candidate`+`scaffoldable: false` (031);
      `fsm-kong`+`infra/kong/`+`.forge/standards/infra/kong.md` still present +
      snapshot sha intact (011/032). [Story: FR-B814-011/030/031/032]
- [x] T-003 Positive staged-artifact checks (Groups 1–3): amendment-viii-1.md
      present + Envoy-SHALL + target v2.0.0 + Amendments-row + GOVERNANCE-process
      cite (001/002); constitution byte-unchanged (003); removal-manifest.yaml
      enumerates the real targets incl kong.md + each exists (010); flip-runbook.md
      ordered steps + t4 material-path note (020); deprecation draft (021).
      [Story: FR-B814-001..021]
- [x] T-004 Harness + CI + coupling: CHANGELOG anchor (041), forge-ci reg (040),
      coupling b8-13+t4+b8-3 (042). [Story: FR-B814-040/041/042]
- [x] T-005 **Verify RED**: run `b8-14.test.sh --level 1` → MUST fail (staged
      artifacts absent, CHANGELOG/CI not registered). Record failing list.

## Phase 2: Author staged artifacts (GREEN)

- [x] T-010 Author `amendment-viii-1.md`: proposed §VIII.1 (Envoy Gateway SHALL;
      Connect-RPC replaces gateway REST↔gRPC transcoding) + motivation + impact on
      1.0.0 Kong projects + exact `## Amendments` row + target `Version` v2.0.0
      (cite VERSIONING.md:15-17 MAJOR criterion + GOVERNANCE.md:124-125 + the 4-step
      Amendment Process + d5-governance precedent). NOT applied to constitution.
      [Story: FR-B814-001/002/003]
- [x] T-011 Author `removal-manifest.yaml`: scaffold-composition targets
      (`infra/kong/`, `fsm-kong` service, `FSM_KONG_ADMIN_PORT`, scaffold-plan kong
      entry, REST-bridge route anchors in kong.yml.example.tmpl) + framework-standard
      target (`.forge/standards/infra/kong.md` → superseded by gateway.yaml). Each
      verified to exist. [Story: FR-B814-010]
- [x] T-012 Author `flip-runbook.md`: ordered post-window steps (close discussion →
      ratify → apply amendment [Amendments row + v2.0.0 + change.yaml + archetype
      .forge.yaml.tmpl] → flip 2.0.0.yaml stage:stable+scaffoldable:true → execute
      removal manifest in 2.0.0 composition → land B.8.3.b scaffolder guard →
      activate 1.0.0 deprecation). Pin framework version to VERSIONING.md:70-73
      (pre-GA MINOR + BREAKING note). Note t4 material-path if ARCHITECTURE-TARGET
      touched. [Story: FR-B814-020]
- [x] T-013 Stage the 1.0.0 deprecation announcement draft (T+6mo) destined for
      CHANGELOG + VERSIONING/GOVERNANCE support policy — not activated.
      [Story: FR-B814-021]
- [x] T-014 Add `[Unreleased]` `b8-14` CHANGELOG entry (prepare-only scope) +
      register `b8-14.test.sh --level 1` in forge-ci.yml. [Story: FR-B814-040/041]
- [x] T-015 **Verify GREEN**: `b8-14.test.sh --level 1` all PASS. [Story: all]

## Phase 3: Integration + invariants

- [x] T-020 Coupling guards (b8-13, t4, b8-3) green by exit code; confirm
      `t4.test.sh` green (arch doc untouched). [Story: FR-B814-042]
- [x] T-021 Full hermetic suite (~53 harnesses incl b8-14) ALL_GREEN + verify.sh +
      constitution-linter OVERALL PASS. [Story: NFR-001/003]
- [x] T-022 Confirm held-state via `git status` — NO change to constitution.md,
      2.0.0.yaml, standards/, schemas, scaffolder, frozen templates. [Story: FR-031/032]

## Phase 4: Quality gate + archive

- [x] T-030 Independent implementation review (separate context): re-verify the
      held state (constitution/schema/templates untouched), the staged artifacts'
      correctness (Envoy-SHALL draft, real manifest targets, runbook steps), no
      fabricated citation. APPROVE required.
- [x] T-031 Flip `.forge.yaml` → implemented (timeline); post-flip gate re-run.
- [x] T-032 Archive: merge ADDED reqs into `.forge/specs/` (promotion-prep spec),
      status → archived, update plan §0.0 inventory + §4.2 (B.8.14 prepare-done,
      flip pending) + "Next B.8 step", roadmap T6.
- [x] T-033 Commit `feat(b8-14)` (prepare-only) + push.

## Constitutional compliance (per-task gate)
- NO task edits .forge/constitution.md, flips 2.0.0.yaml, removes Kong, or mutates
  a standard/schema/scaffolder (T-022 asserts; negative guards enforce).
- Amendment Process honored: this brick = step 1 + staged bundle; ratify/apply held.
- TDD: T-005 RED before T-010 GREEN.
- No fabricated citation (T-010 cites real VERSIONING/GOVERNANCE lines; T-030 re-verifies).
