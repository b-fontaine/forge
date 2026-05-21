# Tasks: t5-3-3-vitest-bundle-preflight
<!-- Status: planned -->
<!-- Schema: default -->
<!-- Audit: T5.3.3 (docs/new-archetypes-plan.md §0.6) -->

## Convention
- TDD immutable. Audit tag `[Story: FR-T533-XXX]` on each task.
- ADRs T533-001/002 resolved inline in design.md.

## Phase 1 — RED harness + CI registration

- [ ] **T-HAR-001** — Create `.forge/scripts/tests/t5-3-3.test.sh`
      with bash header, `_helpers.sh` source, `--level` parsing,
      audit comment, 5 L1 tests per FR-T533-041, manifest block.
      [Story: FR-T533-040 / FR-T533-041]
- [ ] **T-HAR-002** — Register in `forge-ci.yml` matrix after
      `t5-3-1.test.sh`. Compress `i5.test.sh` + `f3.test.sh`
      comment blocks per design ADR-T533-002 to stay ≤ 300.
      [Story: FR-T533-044 / NFR-T533-003]
- [ ] **T-HAR-003** — RED gate : `t5-3-3.test.sh --level 1`
      exits non-zero, ≥ 4 FAIL (global-setup.ts absent,
      vitest.config.ts not wired, changelog entry missing).

## Phase 2 — Implementation (GREEN)

- [ ] **T-IMPL-001** — Create `cli/test/global-setup.ts` per
      FR-T533-001..005 (default export, spawnSync npm run
      bundle, exit-code check, audit comment).
      [Story: FR-T533-001..005]
- [ ] **T-IMPL-002** — Edit `cli/vitest.config.ts` to add
      `globalSetup: "./test/global-setup.ts"` in `test:` block.
      [Story: FR-T533-020..022]
- [ ] **T-IMPL-003** — `tsc --noEmit -p cli/tsconfig.json`
      exit 0 (no new TypeScript errors).
      [Story: FR-T533-022]

## Phase 3 — Documentation

- [ ] **T-DOC-001** — CHANGELOG entry under `[Unreleased]`.
      [Story: FR-T533-060]
- [ ] **T-DOC-002** — Plan inventory + §0.6 in
      `docs/new-archetypes-plan.md`.
      [Story: FR-T533-061 / FR-T533-062]

## Phase 4 — Validate

- [ ] **T-VAL-001** — `t5-3-3.test.sh --level 1` GREEN 5/5.
- [ ] **T-VAL-002** — Manual : `rm -rf cli/assets/ && npx
      vitest run cli/test/e2e/archetypes-smoke.test.ts` →
      tests GREEN (proves globalSetup recovered the bundle).
- [ ] **T-VAL-003** — `verify.sh` + `constitution-linter.sh`
      OVERALL PASS preserved. [Story: NFR-T533-004]
- [ ] **T-VAL-004** — `forge-ci.yml` ≤ 300 lines.
      [Story: NFR-T533-003]
