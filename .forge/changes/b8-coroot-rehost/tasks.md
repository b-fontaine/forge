# Tasks: b8-coroot-rehost
<!-- Status: planned -->
<!-- Schema: default -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, Coroot leg) -->

> **CORRECTION NOTICE (2026-05-25)** : task descriptions below that mention
> "v-prefix mandatory per GHCR" (e.g. lines around "ghcr v1.20.2 OK
> multi-arch") encode the **inverted** verify-then-pin claim from the
> early exploration. The L2 manifest-pull fixture caught the mis-read
> at `/forge:implement` Phase 6 ; the corrected convention is **uniform
> no-v-prefix** across `versions.*`. Authoritative records :
> `design.md::ADR-B8-COR-001` (rewritten), `open-questions.md::Q-001`
> (resolution flipped), `evidence.md` § 1 (corrected transcripts),
> `CHANGELOG.md` (corrected entry), `REVIEW.md` (corrected entry).
> This tasks.md is preserved as-is per Article V (history). The harness
> code shipped is the corrected one (no v-prefix).

## Convention

- TDD immutable. Audit tag `[Story: FR-B8-COR-XXX | NFR-B8-COR-XXX | ADR-B8-COR-XXX]` on each task.
- `[P]` parallelizable inside the same phase (independent file edits).
- ADR-B8-COR-001..004 honoured verbatim (a / b / a+b / a).
- Trio coupling : NFR-B8-COR-008 enforced — no edit to `versions.beyla`,
  no new K.3 rule, no constitutional amendment.

RED witness in the wild :
- `docker manifest inspect coroot/coroot:1.4.4` returns
  `denied: requested access to the resource is denied / unauthorized:
  authentication required`. Any adopter scaffolding the flagship today
  inherits an unpullable Coroot Deployment.
- `bash bin/validate-standards-yaml.sh .forge/standards/observability.yaml`
  passes today (v1.1.0 frontmatter valid) — but the underlying image pin
  is dead.

---

## Phase 1 — RED harness + CI registration

### T-HAR — Harness skeleton

- [ ] **T-HAR-001** — Create `.forge/scripts/tests/b8-coroot.test.sh`
      with bash header (`#!/usr/bin/env bash`, `set -uo pipefail`),
      `_helpers.sh` source, `--level` parsing, audit comment
      `# Audit: B.8.8 (b8-coroot-rehost) — Coroot rehost ghcr.io + v1.20.2`,
      manifest block, `print_summary` close-out.
      [Story: FR-B8-COR-070]

- [ ] **T-HAR-002** — Path constants :
      - `COROOT_CANONICAL` → `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl`
      - `COROOT_CLI_MIRROR` → `cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl`
      - `COROOT_EXAMPLE` → `examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml`
      - `COROOT_CLI_EXAMPLE_MIRROR` → `cli/assets/examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml`
      - `OBSERV_YAML` → `.forge/standards/observability.yaml`
      - `REVIEW_MD` → `.forge/standards/REVIEW.md`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      - `SNAPSHOT` → `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      - `VALIDATOR` → `bin/validate-standards-yaml.sh`
      - `NEW_PIN` → `ghcr.io/coroot/coroot:1.20.2`
      [Story: FR-B8-COR-070]

- [ ] **T-HAR-003** — 13 L1 tests with real grep-based assertions per
      `specs.md::FR-B8-COR-071` anchor list :
      1. `_test_b8cor_l1_001_canonical_image_pin`
      2. `_test_b8cor_l1_002_canonical_no_dockerio_coroot`
      3. `_test_b8cor_l1_003_canonical_audit_comment`
      4. `_test_b8cor_l1_004_cli_bundle_template_byte_identity`
      5. `_test_b8cor_l1_005_example_rendered_image_pin`
      6. `_test_b8cor_l1_006_cli_bundle_example_byte_identity`
      7. `_test_b8cor_l1_007_four_copies_only`
      8. `_test_b8cor_l1_008_standard_version_bumped`
      9. `_test_b8cor_l1_009_standard_coroot_pin_vprefix`
      10. `_test_b8cor_l1_010_standard_last_reviewed_today`
      11. `_test_b8cor_l1_011_review_ledger_appended`
      12. `_test_b8cor_l1_012_validate_standards_yaml_passes`
      13. `_test_b8cor_l1_013_changelog_entry`
      [Story: FR-B8-COR-071]

- [ ] **T-HAR-004** [P] — 2 L2 stubs gated on
      `FORGE_B8_COROOT_DOCKER=1` AND `command -v docker` :
      - `_test_b8cor_l2_001_ghcr_manifest_pullable` —
        `docker manifest inspect ghcr.io/coroot/coroot:1.20.2`
        exits 0 with both `"architecture":"amd64"` and
        `"architecture":"arm64"` ; **plus** per ADR-B8-COR-003 :
        `docker run --rm ghcr.io/coroot/coroot:1.20.2 --help` exits 0
        and stdout matches `/--config/`.
      - `_test_b8cor_l2_002_old_pin_denied` —
        `docker manifest inspect coroot/coroot:1.4.4 2>&1` stdout/stderr
        matches `/denied|unauthorized/` (verify-then-pin invariant ;
        WARN-only flip per ADR-B8-COR-003 footnote).
      Both skip-pass when either gate unmet. Cleanup trap on EXIT.
      [Story: FR-B8-COR-072 / FR-B8-COR-073]

- [ ] **T-HAR-005** — Test runner + `main` dispatcher
      (`--level 1`, `--level 1,2`, default `--level 1`). Mirrors
      `t5-3-1.test.sh` shape.
      [Story: FR-B8-COR-071 / FR-B8-COR-072]

- [ ] **T-HAR-006** [P] — Register in
      `.github/workflows/forge-ci.yml` `harness` matrix
      immediately after `t5-3-3.test.sh` :
      ```yaml
      - { name: b8-coroot, path: .forge/scripts/tests/b8-coroot.test.sh, level: "1" }
      ```
      Verify file stays ≤ 300 lines (NFR-CI-002, current 294 → 297).
      [Story: FR-B8-COR-075 / NFR-B8-COR-003]

- [ ] **T-HAR-007** — Determinism trap : no `$RANDOM`, no `mktemp -u`,
      no network call on L1. L2 may pull (network).
      [Story: FR-B8-COR-074]

- [ ] **T-HAR-008** — RED gate —
      `bash .forge/scripts/tests/b8-coroot.test.sh --level 1` exits
      non-zero with at minimum **8 FAIL** : 001 (canonical pin not
      yet `ghcr.io/coroot/coroot:1.20.2`), 002 (legacy substring
      still present), 003 (audit comment absent), 005 (example pin
      old), 008 (standard `version: 1.1.0` not `1.2.0`), 009
      (`versions.coroot: 1.4.4` not `1.20.2`), 010 (`last_reviewed`
      not `2026-05-24`), 011 (no REVIEW row yet), 013 (CHANGELOG
      empty).

### Exit gate Phase 1

`b8-coroot.test.sh --level 1` reports ≥ 8 FAIL / ≤ 5 PASS.
`forge-ci.yml` ≤ 300 lines. No production code touched yet.

---

## Phase 2 — Canonical template edit (GREEN start)

### T-CAN — Canonical template

- [ ] **T-CAN-001** — Edit `COROOT_CANONICAL` :
      Replace `image: coroot/coroot:1.4.4` (line 80, indented under
      `containers:`) with `image: ghcr.io/coroot/coroot:1.20.2`.
      Single-line `sed -i` substitution.
      [Story: FR-B8-COR-001 / FR-B8-COR-002 / FR-B8-COR-003 / ADR-B8-COR-001]

- [ ] **T-CAN-002** — Edit `COROOT_CANONICAL` :
      Replace annotation `forge.dev/standard: "observability.yaml@1.1.0"`
      (line 65, in Deployment metadata.annotations) with
      `forge.dev/standard: "observability.yaml@1.2.0"`.
      [Story: FR-B8-COR-001 / Cluster 1]

- [ ] **T-CAN-003** — Edit `COROOT_CANONICAL` :
      Insert audit comment block above the `containers:` line :
      ```yaml
      # ── B.8.8 / b8-coroot-rehost (2026-05-24) — image rehost ghcr.io ──
      # Migrated from coroot/coroot:1.4.4 (docker.io public-access denied
      # 2026-05-24, verify-then-pin lesson T5.3.2 institutionalised).
      ```
      [Story: FR-B8-COR-008]

- [ ] **T-CAN-004** — Verify canonical edits :
      `bash .forge/scripts/tests/b8-coroot.test.sh --level 1` flips
      tests 001/002/003 from FAIL → PASS.

### Exit gate Phase 2

Tests 001/002/003 PASS. Tests 004/005/006/007/008/009/010/011/012/013
still FAIL (mirrors + standard + REVIEW + CHANGELOG not yet edited).

---

## Phase 3 — Mirror sync + Standard bump + REVIEW + Snapshot regen (GREEN continued)

### T-MIR — Template mirror sync

- [ ] **T-MIR-001** [P] — Sync `COROOT_CLI_MIRROR` byte-identical
      to `COROOT_CANONICAL`. Method : `cp` after `npm run bundle` OR
      direct `cp $COROOT_CANONICAL $COROOT_CLI_MIRROR` (T5.3.3
      vitest globalSetup will run bundle anyway).
      [Story: FR-B8-COR-004]

- [ ] **T-MIR-002** [P] — Edit `COROOT_EXAMPLE` (rendered, not
      templated) :
      - Replace `image: coroot/coroot:1.4.4` with
        `image: ghcr.io/coroot/coroot:1.20.2`.
      - Replace `forge.dev/standard: "observability.yaml@1.1.0"`
        with `forge.dev/standard: "observability.yaml@1.2.0"`.
      - Insert audit comment block (same as T-CAN-003).
      [Story: FR-B8-COR-005]

- [ ] **T-MIR-003** [P] — Sync `COROOT_CLI_EXAMPLE_MIRROR`
      byte-identical to `COROOT_EXAMPLE`.
      [Story: FR-B8-COR-006]

- [ ] **T-MIR-004** — Verify mirror sync :
      Tests 004/005/006/007 flip FAIL → PASS.

### T-STD — Standard `observability.yaml` v1.1.0 → v1.2.0

- [ ] **T-STD-001** — Edit `OBSERV_YAML` frontmatter :
      - `version: "1.1.0"` → `version: "1.2.0"`.
      - `last_reviewed: 2026-05-04` → `last_reviewed: 2026-05-24`.
      - `expires_at: 2027-05-04` UNCHANGED (12-month loose cadence
        preserved per ADR-B8-COR-004 + standards-lifecycle).
      [Story: FR-B8-COR-030 / FR-B8-COR-034 / NFR-B8-COR-008]

- [ ] **T-STD-002** — Edit `OBSERV_YAML::versions.coroot` :
      `"1.4.4"` → `"1.20.2"` (v-prefix mandatory per ADR-B8-COR-001).
      [Story: FR-B8-COR-031 / FR-B8-COR-003 / ADR-B8-COR-001]

- [ ] **T-STD-003** — Insert YAML comment block above the `versions:`
      block in `OBSERV_YAML` documenting v-prefix heterogeneity per
      ADR-B8-COR-001 (`versions.beyla` no-prefix vs `versions.coroot`
      v-prefix). Suggested text :
      ```yaml
      # Pin convention note (b8-coroot-rehost / ADR-B8-COR-001) :
      # `coroot` carries v-prefix because GHCR rejects the unprefixed form
      # (`docker manifest inspect ghcr.io/coroot/coroot:1.20.2` →
      # manifest unknown). `beyla` stays without v-prefix because
      # Docker Hub accepts both ; bump deferred to b8-obi-refresh.
      ```
      [Story: FR-B8-COR-032 / ADR-B8-COR-001]

- [ ] **T-STD-004** — Edit `OBSERV_YAML::rationale` block. Append a
      paragraph documenting :
      - Host migration (`docker.io/coroot` → `ghcr.io/coroot/coroot`).
      - Coroot CE Apache-2.0, US-incorporated Coroot Inc, no upstream
        phone-home in CE (per ADR-B8-COR-004 + evidence.md).
      - T1/T2 CE-OK ; T3 SHOULD flag Coroot as candidate-substitution
        at deployment-time Demeter pass.
      [Story: FR-B8-COR-038 / ADR-B8-COR-004]

- [ ] **T-STD-005** — Confirm `linter_rule: null` UNCHANGED and
      `forbidden:` list UNCHANGED (Coroot NOT added per
      ADR-B8-COR-004 + ADR-B8-COR-002).
      [Story: FR-B8-COR-036 / FR-B8-COR-037 / ADR-B8-COR-004]

- [ ] **T-STD-006** — Verify J.7 invariants — run
      `bash bin/validate-standards-yaml.sh .forge/standards/observability.yaml`
      ; assert exit 0 (FR-B8-COR-035, blocks Article XII coupling
      check + `expires_at > last_reviewed` strict).
      [Story: FR-B8-COR-035]

- [ ] **T-STD-007** — Verify standard edits :
      Tests 008/009/010/012 flip FAIL → PASS.

### T-REV — REVIEW.md ledger append

- [ ] **T-REV-001** — Append row to `REVIEW_MD` after the existing
      latest entry :
      ```
      | 2026-05-24 | Updated | observability.yaml v1.1.0 → v1.2.0 (b8-coroot-rehost) |
      ```
      Strict append (no insertion mid-ledger) per FR-J7-023.
      [Story: FR-B8-COR-050 / FR-B8-COR-051]

- [ ] **T-REV-002** — Verify REVIEW.md append :
      Test 011 flips FAIL → PASS.

### T-SNP — Snapshot tarball regeneration

- [ ] **T-SNP-001** — Regenerate
      `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      via `SOURCE_DATE_EPOCH=$(git log -1 --format=%ct HEAD)
      bin/forge-snapshot.sh --archetype full-stack-monorepo
      --version 1.0.0` (or the canonical invocation per
      `bin/forge-snapshot.sh --help`).
      [Story: FR-B8-COR-100 / FR-B8-COR-101]

- [ ] **T-SNP-002** [P] — Run `npm run bundle` to mirror the new
      snapshot into `cli/assets/.forge/scaffold-snapshots/`.
      [Story: FR-B8-COR-102]

- [ ] **T-SNP-003** — Determinism check : re-run T-SNP-001 with the
      same `SOURCE_DATE_EPOCH` ; assert `diff -q` between the two
      tarballs is empty.
      [Story: FR-B8-COR-101]

- [ ] **T-SNP-004** — Backward compat : run
      `bash .forge/scripts/tests/a7.test.sh --level 1` ; assert
      GREEN (forge-upgrade non-destructive 3-way merge invariant
      preserved).
      [Story: FR-B8-COR-103]

### Exit gate Phase 3

Tests 001..012 PASS. Test 013 (CHANGELOG entry) still FAIL.
`validate-standards-yaml.sh` exits 0. `a7.test.sh --level 1` GREEN.
Snapshot regeneration deterministic.

---

## Phase 4 — Evidence collection (audit trail)

### T-EVD — `evidence.md` for ADR-B8-COR-003 + ADR-B8-COR-004

- [ ] **T-EVD-001** — Create `.forge/changes/b8-coroot-rehost/evidence.md`.
      Header block with audit comment + ADR references.
      [Story: ADR-B8-COR-003 / ADR-B8-COR-004]

- [ ] **T-EVD-002** — Section "Verify-then-pin transcripts (2026-05-24)" :
      paste the 5 `docker manifest inspect` results verbatim from
      session evidence (coroot:1.4.4 denied, coroot:latest denied,
      ghcr v1.20.2 OK multi-arch, ghcr 1.20.2 manifest unknown, beyla
      2.0.1 OK).
      [Story: Article III.4 / FR-B8-COR-072..073]

- [ ] **T-EVD-003** — Section "Coroot CHANGELOG review v1.5.0 → v1.20.2"
      per ADR-B8-COR-003 :
      - Fetch upstream CHANGELOG (GitHub releases API or
        `https://github.com/coroot/coroot/blob/main/CHANGELOG.md`).
      - Grep for ConfigMap field changes (`listen`, `data_dir`,
        `otel.grpc.listen`, `otel.http.listen`,
        `integrations.collector_endpoint`).
      - Record any field rename / removal / new-required-field finding.
      - If no breaking finding : record "no ConfigMap breaking change
        detected v1.5.0 → v1.20.2 ; current templated config remains
        valid".
      - If breaking finding : escalate — update FR-B8-COR-030 to v1.3.0
        + add T-CAN-005..007 task block for ConfigMap edits per
        NFR-B8-COR-006 footnote.
      [Story: ADR-B8-COR-003 / NFR-B8-COR-006]

- [ ] **T-EVD-004** — Section "Coroot CE jurisdiction evidence" per
      ADR-B8-COR-004 :
      - Record 1 : Coroot Inc US-incorporated. Source URL + retrieval
        timestamp (e.g. Coroot GitHub org metadata, About-Us page).
      - Record 2 : Coroot CE Apache-2.0. Source : LICENSE file SHA pin
        on `coroot/coroot` GitHub repo at the v1.20.2 tag.
      - Record 3 : No upstream phone-home in CE. Source : grep CE
        source tree for telemetry endpoints (`grep -rn -e
        "telemetry\." -e ".coroot.com/api/" -e "analytics" CE-clone/`)
        + reference Coroot docs section on telemetry.
      [Story: ADR-B8-COR-004 / NFR-B8-COR-007]

- [ ] **T-EVD-005** — Cross-link `evidence.md` from
      `design.md::ADR-B8-COR-003::Implementation` and
      `design.md::ADR-B8-COR-004::Implementation` (relative paths).
      [Story: Article V]

### Exit gate Phase 4

`evidence.md` complete, all 3 sections filled. If T-EVD-003 escalated,
Phase 2 tasks expanded (recorded in this tasks.md as inline patch).

---

## Phase 5 — Documentation

### T-DOC — CHANGELOG + plan inventory + roadmap + CLAUDE.md.tmpl

- [ ] **T-DOC-001** — `CHANGELOG.md [Unreleased]` gains :
      ```markdown
      ### Fixed — Coroot image rehosted ghcr.io (B.8.8, `b8-coroot-rehost`)

      - Docker Hub public access on `coroot/coroot:1.4.4` returns
        `denied: unauthorized` 2026-05-24. Migrate to
        `ghcr.io/coroot/coroot:1.20.2` (v-prefix mandatory per GHCR
        convention).
      - `observability.yaml` v1.1.0 → v1.2.0 additive — `versions.coroot`
        bumped, `last_reviewed: 2026-05-24` ; YAML comment block
        documents v-prefix heterogeneity per ADR-B8-COR-001.
      - REVIEW.md ledger entry appended.
      - 4-copy mirror sync (canonical .tmpl + cli bundle + example
        rendered + cli bundle example).
      - New harness `b8-coroot.test.sh` (13 L1 + 2 L2 opt-in via
        `FORGE_B8_COROOT_DOCKER=1`).
      - Snapshot tarball regenerated deterministic.
      - Demeter posture per ADR-B8-COR-004 : Coroot CE T1/T2 OK ;
        T3 candidate-substitution flag in `observability.yaml::rationale`
        (no new K.3 rule).
      - Pilot of the **b8-observability-rearch trio** ; b8-signoz-unified
        and b8-obi-refresh follow.
      ```
      Then test 013 flips FAIL → PASS.
      [Story: FR-B8-COR-120]

- [ ] **T-DOC-002** [P] — `docs/new-archetypes-plan.md` :
      Append a row to the `Inventaire .forge/changes/` table (after
      `t5-3-3-vitest-bundle-preflight`) :
      ```
      | b8-coroot-rehost | archived | B.8.8 (Coroot rehost ghcr.io + v1.20.2, T6 trio pilot) |
      ```
      Status will flip from `proposed → archived` at archive time ;
      placeholder row added at `planned` is acceptable per b1-1
      precedent.
      [Story: FR-B8-COR-121]

- [ ] **T-DOC-003** [P] — `docs/new-archetypes-plan.md` :
      Add `## 0.7 Status update — 2026-05-24 (B.8.8 / b8-coroot-rehost)`
      H2 section after §0.6, mirroring §0.4 cadence (Origine + Fix
      livré + Inverse proof + Effort + release). Section drafted at
      `planned`, completed at archive.
      [Story: FR-B8-COR-124]

- [ ] **T-DOC-004** [P] — `.forge/product/roadmap.md` Phase 3 / T6
      row gains a "B.8.8 (Coroot leg) Done 2026-05-24" inline note
      (optional at `planned`, mandatory at archive).
      [Story: FR-B8-COR-122]

- [ ] **T-DOC-005** [P] — `.forge/templates/archetypes/full-stack-monorepo/infra/CLAUDE.md.tmpl`
      § "Coroot persistence" updated to cite the new pin
      `ghcr.io/coroot/coroot:1.20.2` if the image is mentioned
      inline. Atlas verifies.
      [Story: FR-B8-COR-123]

### Exit gate Phase 5

All 13 L1 tests GREEN. Documentation cohesive across CHANGELOG +
plan + roadmap + CLAUDE.md.tmpl.

---

## Phase 6 — Final verification + archive prep

### T-VER — Cross-gate verification

- [ ] **T-VER-001** — Run `bash .forge/scripts/tests/b8-coroot.test.sh
      --level 1` ; assert 13/13 PASS.
      [Story: FR-B8-COR-071]

- [ ] **T-VER-002** — Run `bash .forge/scripts/tests/b8-coroot.test.sh
      --level 1,2` with `FORGE_B8_COROOT_DOCKER=1` ; assert 13 L1 + 2
      L2 PASS (15/15). If docker absent : 13 L1 + 2 L2 skip-pass.
      [Story: FR-B8-COR-072 / FR-B8-COR-073]

- [ ] **T-VER-003** [P] — Run `bash .forge/scripts/verify.sh` ; assert
      PASS count MUST NOT decrease.
      [Story: NFR-B8-COR-004]

- [ ] **T-VER-004** [P] — Run `bash .forge/scripts/constitution-linter.sh` ;
      assert OVERALL PASS.
      [Story: NFR-B8-COR-004]

- [ ] **T-VER-005** [P] — Run all existing harnesses
      (`t5-1`, `t5-2`, `t5-otel-dartastic`, `t5-3-1`, `t5-3-3`,
      `i2..i6`, `j7`, `j8`, `k3`, `a7`) ; assert GREEN.
      [Story: NFR-B8-COR-004]

- [ ] **T-VER-006** — Run `bash bin/validate-standards-yaml.sh
      .forge/standards/observability.yaml` ; exit 0 (re-confirm).
      [Story: FR-B8-COR-035]

- [ ] **T-VER-007** — Determinism final check : re-run
      `b8-coroot.test.sh --level 1` twice ; assert stdout
      byte-identical (modulo wall-clock).
      [Story: FR-B8-COR-074]

- [ ] **T-VER-008** — Atomic revert dry-run :
      `git stash` the working tree, confirm pre-implementation state
      restored ; `git stash pop` ; confirm working tree restored.
      Validates NFR-B8-COR-005.
      [Story: NFR-B8-COR-005]

### T-IMP — Status flip → implemented

- [ ] **T-IMP-001** — Update `.forge.yaml` :
      `status: designed` → `status: implemented`,
      `timeline.implemented: 2026-05-24`. Validator exit 0.

- [ ] **T-IMP-002** — Commit the change with Forge-style scoped
      Conventional Commit (rules per `git-workflow` standard) :
      ```
      feat(infra)!: B.8.8 — Coroot rehost ghcr.io + v1.20.2
      ```
      `feat!` because `observability.yaml` minor bump signals new pin
      info — but **NOT breaking the SemVer of the framework** (additive
      to standard). Maintainer decides between `feat(infra)` and
      `fix(infra)` at commit time.

### Exit gate Phase 6

All harnesses GREEN. verify.sh PASS count unchanged or up.
constitution-linter.sh OVERALL PASS. `.forge.yaml`
status: implemented. Working tree committable.

---

## Archive preparation (post-implementation, separate session)

When ready to archive (via `/forge:archive b8-coroot-rehost`) :

1. Confirm all 4 questions in `open-questions.md` are `Status: answered`.
2. Bump `status: implemented` → `status: archived` and
   `timeline.archived: <date>`.
3. Finalize §0.7 status update in `docs/new-archetypes-plan.md`.
4. Append to `Inventaire .forge/changes/` table with `archived`.
5. Mark `.forge/product/roadmap.md` Phase 3 / T6 row.
6. Tag release `v0.4.0-rc.3` (or v0.4.0 final per maintainer arbitrage
   ratified 2026-05-24 : v0.4.0 final reserved for T6 complete).

> Per maintainer ratification 2026-05-24 (session memory) :
> **v0.4.0 final contains all of T6** ; this change ships as
> `v0.4.0-rc.3` (or later rc.x). v0.4.0 final lands once
> b8-coroot-rehost + b8-signoz-unified + b8-obi-refresh (trio
> complete) + the rest of B.8 are all archived.

---

## Constitutional Compliance Gate (per task)

For each task above :

| Risk | Check |
|---|---|
| TDD bypass | All edits gated by harness assertion ; T-CAN-001 cannot run before T-HAR-008 RED gate. |
| Specs bypass | Every task carries `[Story: FR/NFR/ADR-XXX]` link. |
| Architecture violation | Article VIII (infra excellence) honored ; Article XII (governance) honored via additive bump ; ADR-B8-COR-004 K3-RULE-001 interpretation evidence-driven not assumed. |
| Trio coupling | NFR-B8-COR-008 enforced — no task touches `versions.beyla` (T-STD-003 documents asymmetry only), no task touches K.3 standards (T-EVD-004 records evidence in this change's `evidence.md` only). |
| Article III.4 (Anti-Hallucination) | T-EVD-* phase explicitly collects upstream evidence pre-archive. |

No `[TASK VIOLATION:]` flag raised. Plan is ratified.

---

*Next : `/forge:implement b8-coroot-rehost`.*
