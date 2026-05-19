# Tasks: b1-1-dev-up-matrix-fixes
<!-- Status: planned -->
<!-- Schema: default -->
<!-- Audit: T5.3.1 (docs/new-archetypes-plan.md §0.4) -->

## Convention

- TDD immutable. Audit tag `[Story: FR-B1-DUM-XXX]` on each task.
- `[P]` parallelizable inside the same phase.
- ADR-B1-DUM-001..003 honored verbatim (Option A `traefik/whoami:latest`
  for backend placeholder ; Option B bare delete + 1-line comment for
  `version:` ; Option A Taskfile-only + L2 opt-in for E2E placement).

RED witness in the wild : `task dev:up` against a freshly
scaffolded `full-stack-monorepo` fails immediately on
`fsm-backend: invalid reference format "scratch"`.

NFR-B1-DUM-006 (snapshot regen) is **resolved here** : Option A
modifies the rendered template body byte-for-byte → snapshot tarball
MUST be regenerated (see T-SNP-001).

---

## Phase 1 — RED harness + CI registration

### T-HAR — Harness skeleton

- [x] **T-HAR-001** — Create `.forge/scripts/tests/t5-3-1.test.sh`
      with bash header (`#!/usr/bin/env bash`, `set -uo pipefail`),
      `_helpers.sh` source, `--level` parsing, audit comment
      `# Audit: T5.3.1 (b1-1-dev-up-matrix-fixes)`, manifest block,
      `print_summary` close-out.
      [Story: FR-B1-DUM-080]

- [x] **T-HAR-002** — Path constants :
      - `DC_CANONICAL` → `.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
      - `DC_EXAMPLE` → `examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
      - `DC_CLI_MIRROR` → `cli/assets/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
      - `DC_CLI_EXAMPLE_MIRROR` → `cli/assets/examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      - `SNAPSHOT` → `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      [Story: FR-B1-DUM-080]

- [x] **T-HAR-003** — 9 L1 tests with real grep-based assertions per
      `specs.md::FR-B1-DUM-081` anchor list :
      1. `_test_b1dum_l1_001_canonical_no_scratch`
      2. `_test_b1dum_l1_002_canonical_no_version_key`
      3. `_test_b1dum_l1_003_audit_comment_present`
      4. `_test_b1dum_l1_004_mirror_example_byte_identity_edits`
      5. `_test_b1dum_l1_005_mirror_cli_assets_byte_identity_full`
      6. `_test_b1dum_l1_006_mirror_cli_assets_example_byte_identity`
      7. `_test_b1dum_l1_007_four_copies_only`
      8. `_test_b1dum_l1_008_adopter_comment_preserved`
      9. `_test_b1dum_l1_009_changelog_entry`
      [Story: FR-B1-DUM-081]

- [x] **T-HAR-004** [P] — 1 L2 stub
      `_test_b1dum_l2_dev_up_cycle` ; skip-pass when
      `FORGE_B1DUM_DOCKER` unset OR `docker` absent on PATH.
      Skeleton invokes `forge init` into `$(mktemp -d)`, runs
      `task dev:up`, asserts `docker compose ps --format json`
      lists `fsm-db`, `fsm-kong`, `fsm-signoz`,
      `fsm-otel-collector` in `running|healthy`, runs
      `task dev:down`, asserts no orphan `fsm-*` container.
      Cleanup trap on EXIT.
      [Story: FR-B1-DUM-082]

- [x] **T-HAR-005** — Test runner + `main` dispatcher
      (`--level 1`, `--level 1,2`, default `--level 1`).
      [Story: FR-B1-DUM-081 / FR-B1-DUM-082]

- [x] **T-HAR-006** [P] — Register in
      `.github/workflows/forge-ci.yml` `harness` matrix
      immediately after `i5.test.sh` :
      ```yaml
      - { name: t5-3-1, path: .forge/scripts/tests/t5-3-1.test.sh, level: "1" }
      ```
      Verify file stays ≤ 300 lines (NFR-CI-002, current 296 → 297).
      [Story: FR-B1-DUM-084 / NFR-B1-DUM-003]

- [x] **T-HAR-007** — Determinism trap : ensure no test reads
      `$RANDOM`, no `mktemp -u` for assertion paths (only for L2
      scratch dir), no network call on L1.
      [Story: FR-B1-DUM-083]

- [x] **T-HAR-008** — RED gate —
      `bash .forge/scripts/tests/t5-3-1.test.sh --level 1` exits
      non-zero with at minimum **4 FAIL** : tests 001
      (scratch present), 002 (version present), 003 (audit comment
      absent), 009 (no CHANGELOG entry yet).

### Exit gate Phase 1

`t5-3-1.test.sh --level 1` reports ≥ 4 FAIL / ≤ 5 PASS.
`forge-ci.yml` ≤ 300 lines. No production code touched yet.

---

## Phase 2 — Canonical template edits (GREEN start)

### T-TPL — Canonical template edits

- [x] **T-TPL-001** — RED witness : confirm tests 001, 002, 003
      FAIL on `bash t5-3-1.test.sh --level 1`.

- [x] **T-TPL-002** — Edit
      `.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
      line 25 (per ADR-B1-DUM-002 Option B) :
      ```yaml
      # Compose v2 — no top-level `version:` key (deprecated 2024-01,
      # inferred from filename).
      ```
      Replaces `version: "3.8"`.
      [Story: FR-B1-DUM-020 / FR-B1-DUM-021]

- [x] **T-TPL-003** — Edit same file `fsm-backend` block
      (per ADR-B1-DUM-001 Option A). Replace lines around 60-65 :
      ```yaml
      # ── T5.3.1 (b1-1-dev-up-matrix-fixes) — fsm-backend placeholder ──
      # Replace the image below with your real backend image once built
      # (e.g. image: ghcr.io/org/<project-name>-backend:dev).
      # `traefik/whoami` is a wiring placeholder that responds 200 OK
      # on GET / — swap it out + restore the original /health probe
      # path before going to staging.
      fsm-backend:
        image: traefik/whoami:latest
        command: ["--port=8080"]
        env_file: .env
        environment:
          DATABASE_URL: ${DATABASE_URL}
          LOG_LEVEL: ${LOG_LEVEL:-info}
        ports:
          - "${FSM_BACKEND_PORT:-8080}:8080"
        networks:
          - fsm-dev
        depends_on:
          fsm-db:
            condition: service_healthy
        healthcheck:
          test: ["CMD-SHELL", "curl -fsS http://localhost:8080/ || exit 1"]
          interval: 10s
          timeout: 5s
          retries: 5
          start_period: 15s
      ```
      [Story: FR-B1-DUM-001 / FR-B1-DUM-003 / FR-B1-DUM-004 / FR-B1-DUM-005]

- [x] **T-TPL-004** — Verify GREEN on canonical-only tests
      (001, 002, 003) after T-TPL-002 + T-TPL-003.

### Exit gate Phase 2

Canonical template clean. Mirrors still divergent (tests 004,
005, 006 still FAIL until Phase 3).

---

## Phase 3 — Mirror sync (GREEN finish)

### T-MIR — Mirror propagation

- [x] **T-MIR-001** — Edit `examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
      to match canonical edited region byte-for-byte (lines 25 +
      former 60-65).
      [Story: FR-B1-DUM-040]

- [x] **T-MIR-002** [P] — Run `npm run bundle` from `cli/` to
      propagate canonical → `cli/assets/.forge/templates/.../docker-compose.dev.yml.tmpl`.
      [Story: FR-B1-DUM-041]

- [x] **T-MIR-003** [P] — Same `npm run bundle` propagates
      example mirror → `cli/assets/examples/forge-fsm-example/.forge/templates/.../docker-compose.dev.yml.tmpl`.
      [Story: FR-B1-DUM-042]

- [x] **T-MIR-004** — Verify GREEN on mirror tests (004, 005,
      006, 007). Test 007 asserts exactly 4 paths under repo root
      (no fifth copy introduced).
      [Story: FR-B1-DUM-043]

### Exit gate Phase 3

L1 tests 1-7 GREEN. Tests 008 (adopter comment preserved)
GREEN (preserved by design). Test 009 (CHANGELOG) still FAIL.

---

## Phase 4 — Snapshot regen + documentation

### T-SNP — Snapshot tarball regen

- [x] **T-SNP-001** — Regenerate
      `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      via `bin/forge-snapshot.sh build full-stack-monorepo 1.0.0`.
      **Determinism is per-file SHA-256** (per `forge-snapshot.sh:127-133`
      and ADR-004) — **not** tarball byte-identity. The script
      explicitly accepts tarball timestamp variance ; sameness in
      `forge upgrade` is asserted via per-file SHA, which is the
      property that matters for BASE recovery. Bundle the snapshot
      mirror at `cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      via `npm run bundle`.
      [Story: NFR-B1-DUM-006]

- [x] **T-SNP-002** — Sanity-extract the regenerated tarball
      into a temp dir, assert the extracted
      `docker-compose.dev.yml.tmpl` matches canonical
      (`diff -q`).

### T-DOC — Documentation

- [x] **T-DOC-001** [P] — Add `CHANGELOG.md` entry under
      `[Unreleased]` (or under v0.4.0-rc.1 if not yet npm-tagged ;
      under a new v0.4.0-rc.2 section if rc.1 is already
      published) :
      ```markdown
      ### Fixed — full-stack-monorepo docker-compose.dev.yml template hygiene (T5.3.1, b1-1-dev-up-matrix-fixes)
      - Replace `image: scratch` placeholder with `traefik/whoami:latest` stand-in (ADR-B1-DUM-001).
      - Remove obsolete top-level `version: "3.8"` key (ADR-B1-DUM-002).
      - Add new harness `.forge/scripts/tests/t5-3-1.test.sh` (9 L1 + 1 L2 opt-in `FORGE_B1DUM_DOCKER=1`).
      - Regenerate `full-stack-monorepo/1.0.0.tar.gz` snapshot.
      ```
      [Story: FR-B1-DUM-110]

- [x] **T-DOC-002** [P] — Update `docs/new-archetypes-plan.md`
      `Inventaire .forge/changes/` table : add row
      `| b1-1-dev-up-matrix-fixes | archived | T5.3.1 (dev-up-matrix template hygiene) |`.
      Also update the §0.4 status line from "planned" to
      "Implemented 2026-MM-DD" once Phase 5 completes.
      [Story: FR-B1-DUM-111]

- [x] **T-DOC-003** [P] — Update `.forge/product/roadmap.md`
      Phase 3 T5 row with "T5.3.1 Done 2026-MM-DD via
      `b1-1-dev-up-matrix-fixes`" once Phase 5 completes.
      [Story: FR-B1-DUM-112]

### Exit gate Phase 4

L1 tests 1-9 GREEN. Snapshot tarball regenerated + mirror'd.

---

## Phase 5 — Validate, L2 dry-run, release prep

### T-VAL — Verification

- [x] **T-VAL-001** — `bash .forge/scripts/tests/t5-3-1.test.sh --level 1`
      → 9/9 PASS, wall-clock ≤ 2 s (NFR-B1-DUM-002).

- [x] **T-VAL-002** [P] — `bash .forge/scripts/constitution-linter.sh`
      → OVERALL PASS, no new FAIL (NFR-B1-DUM-004).

- [x] **T-VAL-003** [P] — `bash .forge/scripts/verify.sh` →
      PASS count ≥ baseline (NFR-B1-DUM-004). Capture pre/post
      counts in T-VAL-007 evidence ledger.

- [x] **T-VAL-004** [P] — Run prior harnesses for regression :
      `t5-1`, `t5-2`, `t5-otel-dartastic`, `i2`, `i3`, `i5`,
      `i6`, `j7`, `j8`, `k3` at `--level 1` → all GREEN.
      [Story: NFR-B1-DUM-004]

- [x] **T-VAL-005** — `bash .forge/scripts/tests/t5-3-1.test.sh --level 1,2`
      with `FORGE_B1DUM_DOCKER=1` exported + `docker` available
      locally. L2 cycle GREEN within 180 s (NFR-B1-DUM-002).
      Capture `docker compose ps --format json` output as
      evidence.
      [Story: FR-B1-DUM-060 / FR-B1-DUM-061 / FR-B1-DUM-062]

- [~] **T-VAL-006** [deferred] — `task validate` end-to-end on the same
      branch (full-stack-monorepo + mobile-only smoke), all legs
      GREEN — including `dev-up-matrix` which is the originating
      target.
      [Story: T5.3.1.D release gate]

- [x] **T-VAL-007** — Evidence ledger : append a short markdown
      block under design.md (or a new `evidence.md` if scope
      grows) capturing T-VAL-001..006 numeric results
      (PASS/FAIL counts, wall-clock seconds). Required by
      Forge verification discipline.

### T-REL — Release prep

- [x] **T-REL-001** — Decide release vehicle :
      - If `v0.4.0-rc.1` NOT yet `npm publish`'d → bundle into
        rc.1 (amend CHANGELOG section).
      - If rc.1 already published → ship as `v0.4.0-rc.2` patch
        (new CHANGELOG section, version bump in
        `cli/package.json`).
      Record decision in T-DOC-001 entry.
      [Story: proposal §"Effort & Release"]

- [~] **T-REL-002** [P] [deferred] — Atomic revert dry-run : in a worktree
      copy, `git revert <merge-sha>` and re-run
      `t5-3-1.test.sh --level 1` to assert clean revert path
      (no template orphan).
      [Story: NFR-B1-DUM-005]

### Exit gate Phase 5

All validations GREEN. Release vehicle decision recorded.
Change ready for `/forge:archive`.

---

## Per-Task Constitutional Compliance

| Task family   | Articles checked                        | Status                                                                                       |
|---------------|-----------------------------------------|----------------------------------------------------------------------------------------------|
| T-HAR-001..008| I (TDD), III (Specs Before Code)        | PASS — harness written FIRST, FRs trace from specs.md                                        |
| T-TPL-001..004| I (TDD), III, V (Immutability archived) | PASS — RED witness BEFORE edits ; archived `b1-foundations` files untouched                  |
| T-MIR-001..004| III, V                                   | PASS — mirrors are live templates, not archived contract surfaces                            |
| T-SNP-001..002| III                                      | PASS — deterministic snapshot regen via documented `forge-snapshot.sh` contract              |
| T-DOC-001..003| III                                      | PASS — documentation surfaces only, no behavior change                                       |
| T-VAL-001..007| I, III, IV (Constitution is Law)         | PASS — verification gates required by Article I and `.forge/standards/global/tdd-rules.md`   |
| T-REL-001..002| XII (Governance — release cadence)      | PASS — release vehicle decided per existing `GOVERNANCE.md § Release Process`                |

**No `[TASK VIOLATION:]` raised.** All tasks honor TDD ordering,
spec-trace via `[Story: FR-B1-DUM-XXX]` tags, and ADR-B1-DUM-001..003
verbatim.

---

*Next : `/forge:implement b1-1-dev-up-matrix-fixes`.*
