# Tasks: b8-obi-refresh
<!-- Status: planned -->
<!-- Schema: default -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, OBI/Beyla leg) -->

## Convention

- TDD immutable. Audit tag `[Story: FR-B8-OBI-XXX | NFR-B8-OBI-XXX | ADR-B8-OBI-XXX]` on each task.
- `[P]` parallelizable inside the same phase (independent file edits).
- ADR-B8-OBI-001..008 honoured verbatim (per `design.md`).
- Sibling-trio coupling : ADR-B8-OBI-006 enforced — narrow `t5-otel`,
  widen `b8-coroot` + `b8-signoz` date regex `2026-05-2[6789]`.
- Pre-flip full-CI gate per `shared_standard_sibling_harness_coupling.md`.

**RED witness in the wild** :
- `docker manifest inspect grafana/beyla:3.15.0` ✅ multi-arch (digests
  captured at `/forge:design`) — adopters scaffolding today inherit a
  DaemonSet pinned to `grafana/beyla:2.0.1` (stale by 2026-05-29 ; the
  pin still pulls but lags 1 major).
- `grep -n 'beyla.*2\.0\.1' .forge/scripts/tests/t5-otel.test.sh` →
  lines 128, 233 hard-pinned — sibling coupling debt.
- `grep -n 'last_reviewed.*2026-05-26' .forge/scripts/tests/b8-signoz.test.sh`
  → line 295 exact — sibling coupling debt.

---

## Phase 1 — RED harness + CI registration (line budget compression)

### T-HAR — Harness skeleton

- [ ] **T-HAR-001** — Create `.forge/scripts/tests/b8-obi.test.sh` with
      bash header (`#!/usr/bin/env bash`, `set -uo pipefail`),
      `_helpers.sh` source, `--level` parsing, audit comment
      `# Audit: B.8.8 (b8-obi-refresh) — Beyla 2.0.1 → 3.15.0 + RBAC widen`,
      manifest block, `print_summary` close-out.
      [Story: FR-B8-OBI-100]

- [ ] **T-HAR-002** — Path constants :
      - `OBI_CANONICAL` → `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl`
      - `OBI_CLI_MIRROR` → `cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl`
      - `OBI_EXAMPLE` → `examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`
      - `OBI_CLI_EXAMPLE_MIRROR` → `cli/assets/examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`
      - `OBSERV_YAML` → `.forge/standards/observability.yaml`
      - `REVIEW_MD` → `.forge/standards/REVIEW.md`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      - `SNAPSHOT` → `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      - `VALIDATOR` → `bin/validate-standards-yaml.sh`
      - `NEW_PIN` → `grafana/beyla:3.15.0`
      - `OLD_PIN` → `grafana/beyla:2.0.1`
      [Story: FR-B8-OBI-100]

- [ ] **T-HAR-003** — 12 L1 tests with real grep-based assertions :
      1. `_test_b8obi_l1_001_canonical_image_pin` (FR-B8-OBI-001)
      2. `_test_b8obi_l1_002_canonical_no_old_pin` (FR-B8-OBI-001)
      3. `_test_b8obi_l1_003_canonical_no_latest` (FR-B8-OBI-003 negative)
      4. `_test_b8obi_l1_004_canonical_audit_comment` (FR-B8-OBI-008)
      5. `_test_b8obi_l1_005_cli_bundle_template_byte_identity` (FR-B8-OBI-004)
      6. `_test_b8obi_l1_006_example_rendered_image_pin` (FR-B8-OBI-005)
      7. `_test_b8obi_l1_007_cli_bundle_example_byte_identity` (FR-B8-OBI-006)
      8. `_test_b8obi_l1_008_four_copies_only` (FR-B8-OBI-007 / ADR-B8-OBI-005)
      9. `_test_b8obi_l1_009_canonical_rbac_services_resource` (FR-B8-OBI-063 / ADR-B8-OBI-003)
      10. `_test_b8obi_l1_010_canonical_caps_unchanged` (FR-B8-OBI-060..062 / ADR-B8-OBI-002)
      11. `_test_b8obi_l1_011_canonical_kernel_selector_unchanged` (FR-B8-OBI-064 / ADR-B8-OBI-004)
      12. `_test_b8obi_l1_012_standard_version_bumped` (FR-B8-OBI-030)
      13. `_test_b8obi_l1_013_standard_beyla_pin` (FR-B8-OBI-031)
      14. `_test_b8obi_l1_014_standard_last_reviewed_today` (FR-B8-OBI-032)
      15. `_test_b8obi_l1_015_standard_expires_at_plus_1y` (FR-B8-OBI-033)
      16. `_test_b8obi_l1_016_standard_pin_cadence_preserved` (FR-B8-OBI-034)
      17. `_test_b8obi_l1_017_standard_breaking_change_false` (FR-B8-OBI-030)
      18. `_test_b8obi_l1_018_review_ledger_updated_row` (FR-B8-OBI-050..052)
      19. `_test_b8obi_l1_019_review_ledger_not_arch_change` (FR-B8-OBI-051 negative)
      20. `_test_b8obi_l1_020_validate_standards_yaml_passes` (FR-B8-OBI-040)
      21. `_test_b8obi_l1_021_changelog_entry` (FR-B8-OBI-141)
      22. `_test_b8obi_l1_022_snapshot_ceiling` (FR-B8-OBI-131 / ADR-B8-OBI-008)
      [Story: FR-B8-OBI-102]

- [ ] **T-HAR-004** [P] — 2 L2 fixtures gated on `FORGE_B8_OBI_DOCKER=1`
      AND `command -v docker` :
      - `_test_b8obi_l2_001_dockerhub_manifest_pullable` —
        `docker manifest inspect grafana/beyla:3.15.0` exit 0 +
        amd64+arm64 platform entries present (tolerate extra
        `unknown/unknown` attestation manifests per ADR-B8-OBI-001) ;
        digest captured to `/tmp/b8-obi-digest-$$` for evidence.
      - `_test_b8obi_l2_002_old_pin_informational` —
        `docker manifest inspect grafana/beyla:2.0.1` informational
        (NOT an invariant — MAY exit 0 or non-0, captured but never
        fails the test).
      [Story: FR-B8-OBI-103..108]

- [ ] **T-HAR-005** — `chmod +x .forge/scripts/tests/b8-obi.test.sh`
      then run `bash b8-obi.test.sh --level 1` → MUST be RED (22/22
      FAIL) at this point. Capture transcript to evidence collection
      target.
      [Story: NFR-B8-OBI-001 — wall-clock ≤ 2 s asserted by stopwatch]

### T-CI — forge-ci.yml registration

- [ ] **T-CI-001** — `wc -l .github/workflows/forge-ci.yml` MUST equal
      300 (NFR-CI-002 plafond — pre-edit baseline). Capture to evidence.
      [Story: FR-B8-OBI-121 / ADR-B8-OBI-007]

- [ ] **T-CI-002** — Apply comment compression per ADR-B8-OBI-007 :
      collapse the minimum doc-comment block above the `harness:`
      matrix sufficient to free ≥ 1 line. Mirror the pattern from
      `t5-3-3-vitest-bundle-preflight::ADR-T533-002`. Diff captured
      to evidence.
      [Story: FR-B8-OBI-122 / ADR-B8-OBI-007]

- [ ] **T-CI-003** — Register `b8-obi.test.sh` in `forge-ci.yml::harness`
      matrix immediately after `b8-signoz.test.sh`. Single matrix
      entry line.
      [Story: FR-B8-OBI-120]

- [ ] **T-CI-004** — Verify `wc -l .github/workflows/forge-ci.yml` ≤ 300
      post-edit. Capture diff to evidence.
      [Story: NFR-B8-OBI-007]

### Exit gate Phase 1

- Phase 1 GREEN ⇒ harness RED at all L1 (22/22 FAIL), CI registration
  done, `wc -l ≤ 300`. No template/standard edits yet.

---

## Phase 2 — Canonical template edit (image + RBAC widen + audit comment)

### T-CAN — Canonical OBI DaemonSet template

- [ ] **T-CAN-001** — Edit
      `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl`
      line 87 : `image: grafana/beyla:2.0.1` → `image: grafana/beyla:3.15.0`.
      No-v-prefix preserved (ADR-B8-OBI-001 + FR-B8-OBI-003).
      [Story: FR-B8-OBI-001..003 / ADR-B8-OBI-001]

- [ ] **T-CAN-002** — Edit the ClusterRole `rules:` block (lines 28-34) :
      add `"services"` to the `apiGroups: [""]` resources list :
      `["pods", "nodes"]` → `["pods", "nodes", "services"]`. Verbs
      preserved `["get", "list", "watch"]`.
      [Story: FR-B8-OBI-063 / ADR-B8-OBI-003]

- [ ] **T-CAN-003** — Insert audit comment block above the
      `containers:` block (~line 84) :
      ```yaml
      # ── B.8.8 / b8-obi-refresh (2026-05-29) — Beyla major bump ──
      # Refreshed from grafana/beyla:2.0.1 (T.5 / t5-otel-stack 2026-05-09)
      # to grafana/beyla:3.15.0 (verify-then-pin discipline, lesson T5.3.2).
      # Aegis re-audited caps + RBAC + kernel floor at ADR-B8-OBI-002/003/004.
      ```
      [Story: FR-B8-OBI-008]

- [ ] **T-CAN-004** — Bump `metadata.annotations.forge.dev/standard`
      from `"observability.yaml@1.1.0"` to `"observability.yaml@2.1.0"`
      to track the new standard version.
      [Story: FR-B8-OBI-008]

- [ ] **T-CAN-005** — Verify the caps `add:` list (lines 95-102) is
      preserved verbatim : 8 caps in order BPF / SYS_PTRACE / NET_RAW
      / CHECKPOINT_RESTORE / DAC_READ_SEARCH / PERFMON / NET_ADMIN /
      SYS_ADMIN. Verify `drop: [ALL]` preserved. NO edit (sanity
      check, no diff produced).
      [Story: FR-B8-OBI-060..062 / ADR-B8-OBI-002]

- [ ] **T-CAN-006** — Verify `nodeSelector.forge.dev/kernel-min-58:
      "true"` preserved verbatim. NO edit.
      [Story: FR-B8-OBI-064 / ADR-B8-OBI-004]

- [ ] **T-CAN-007** — Run `bash b8-obi.test.sh --level 1` → tests
      001..004, 009..011 MUST flip from RED to GREEN (canonical
      template assertions). Other tests still RED.
      [Story: TDD GREEN — partial Phase 2]

### Exit gate Phase 2

- Canonical template touched (3 edits : pin + RBAC + comment + annotation
  bump). Caps + nodeSelector + DaemonSet structure unchanged. Harness L1
  partial GREEN.

---

## Phase 3 — Mirror sync + Standard bump + REVIEW + Snapshot

### T-MIR — Template mirror sync (3 mirrors)

- [ ] **T-MIR-001** [P] — `cp` canonical → cli-bundle mirror
      `cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/obi-daemonset.yaml.tmpl`.
      `diff -q` MUST report identical post-copy.
      [Story: FR-B8-OBI-004]

- [ ] **T-MIR-002** [P] — Edit
      `examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`
      to match canonical (image + RBAC + comment + annotation).
      This is a **rendered** file (no template placeholders), but
      content invariants identical.
      [Story: FR-B8-OBI-005]

- [ ] **T-MIR-003** [P] — `cp` rendered example → cli-bundle rendered
      mirror
      `cli/assets/examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`.
      `diff -q` MUST report identical.
      [Story: FR-B8-OBI-006]

- [ ] **T-MIR-004** — Verify mirror count : `find . -type f \(
      -name 'obi-daemonset.yaml' -o -name 'obi-daemonset.yaml.tmpl'
      \) -not -path '*/node_modules/*' -not -path '*/.git/*' | wc -l`
      MUST equal 4 (ADR-B8-OBI-005).
      [Story: FR-B8-OBI-007]

### T-STD — Standard `observability.yaml` v2.0.0 → v2.1.0

- [ ] **T-STD-001** — Edit `.forge/standards/observability.yaml`
      file-top comment block : append v2.1.0 entry below the v2.0.0
      block documenting Beyla 2.0.1 → 3.15.0 refresh + RBAC widen
      `services` + ADR-B8-OBI references.
      [Story: FR-B8-OBI-037]

- [ ] **T-STD-002** — Edit `version: "2.0.0"` → `version: "2.1.0"`.
      [Story: FR-B8-OBI-030]

- [ ] **T-STD-003** — Edit `breaking_change: true` → `breaking_change: false`
      (flip back from sibling 2 ARCH-CHANGE state).
      [Story: FR-B8-OBI-030]

- [ ] **T-STD-004** — Edit `last_reviewed: 2026-05-26` → `last_reviewed: 2026-05-29`.
      [Story: FR-B8-OBI-032]

- [ ] **T-STD-005** — Edit `expires_at: 2027-05-26` → `expires_at: 2027-05-29`.
      [Story: FR-B8-OBI-033]

- [ ] **T-STD-006** — Edit `versions.beyla: "2.0.1"` → `versions.beyla: "3.15.0"`.
      No v-prefix.
      [Story: FR-B8-OBI-031]

- [ ] **T-STD-007** — Verify other `versions.*` keys
      (`signoz`, `signoz_otel_collector`, `clickhouse`,
      `signoz_zookeeper`, `coroot`) UNCHANGED. Sanity check.
      [Story: FR-B8-OBI-035]

- [ ] **T-STD-008** — Verify `pin_review_cadence.beyla: "P12M"` preserved.
      Other cadence keys preserved.
      [Story: FR-B8-OBI-034 / FR-B8-OBI-035]

- [ ] **T-STD-009** — Extend `rationale:` block with paragraph
      documenting Beyla bump : trigger (sibling 3 trio closure),
      RBAC widen (`services` resource per ADR-B8-OBI-003), Aegis
      re-audit outcome (caps/RBAC/kernel UNCHANGED except `services`).
      [Story: FR-B8-OBI-036]

- [ ] **T-STD-010** — Verify the v1.2.0 → v2.0.0 WAIVER block
      (b8-signoz-unified) preserved byte-identical. Article V freeze.
      NO new WAIVER block added.
      [Story: FR-B8-OBI-038]

- [ ] **T-STD-011** — Run `bash bin/validate-standards-yaml.sh
      .forge/standards/observability.yaml` → exit 0. Capture transcript.
      [Story: FR-B8-OBI-040 / NFR-B8-OBI-008]

### T-REV — REVIEW.md ledger append

- [ ] **T-REV-001** — Append a new row to the existing
      `observability.yaml` table in `.forge/standards/REVIEW.md`,
      Article V append-only :
      | observability.yaml | 2.1.0 | Updated | 2027-05-29 | Beyla 2.0.1 → 3.15.0 (b8-obi-refresh, sibling 3 of B.8.8 trio) — RBAC widen `services` per ADR-B8-OBI-003 ; caps + kernel UNCHANGED ; Aegis re-audit PASS. |
      [Story: FR-B8-OBI-050..053]

- [ ] **T-REV-002** — Verify previous REVIEW.md rows byte-identical
      via `git diff -- .forge/standards/REVIEW.md` showing only an
      append. NO existing-row edit.
      [Story: NFR-B8-OBI-006]

- [ ] **T-REV-003** — Verify the flag column = `Updated` (NOT
      `ARCH-CHANGE` — that flag stays reserved for breaking shifts).
      [Story: FR-B8-OBI-051]

### T-SNP — Snapshot tarball regeneration

- [ ] **T-SNP-001** — Run `bin/forge-snapshot.sh build full-stack-monorepo 1.0.0`.
      Determinism : two back-to-back invocations MUST produce
      byte-identical tarballs (`SOURCE_DATE_EPOCH` enforced).
      [Story: FR-B8-OBI-130 / NFR-B8-OBI-011]

- [ ] **T-SNP-002** — Verify tarball size : `stat -f%z` (macOS) or
      `stat -c%s` (Linux) MUST be ≤ 716800 B (700 KiB ceiling
      ADR-B8-SIG-008). Expected delta from baseline 668589 B is < 100 B
      (pin-only edit + comment block + RBAC widen).
      [Story: FR-B8-OBI-131 / NFR-B8-OBI-005]

- [ ] **T-SNP-003** — Run `bash .forge/scripts/tests/a7.test.sh` →
      MUST be 29/29 GREEN (forge-upgrade backward compat preserved).
      [Story: FR-B8-OBI-132 / NFR-B8-OBI-004]

- [ ] **T-SNP-004** — Run `bash b8-obi.test.sh --level 1` → all 22
      tests GREEN (full L1 suite). Wall-clock ≤ 2 s asserted by
      stopwatch.
      [Story: NFR-B8-OBI-001]

### Exit gate Phase 3

- 4 mirrors byte-identical. Standard bumped + validated. REVIEW
  appended. Snapshot regen ≤ 700 KiB. `b8-obi.test.sh --level 1`
  22/22 GREEN. `a7.test.sh` 29/29 GREEN.

---

## Phase 4 — Sibling-harness sweep (ADR-B8-OBI-006 hybrid)

### T-SIB — Sibling harness coupling break

- [ ] **T-SIB-001** [P] — Narrow `t5-otel.test.sh:128` :
      replace `image: grafana/beyla:2.0.1$` exact match with
      `image: grafana/beyla:[^[:space:]]+$` (any tag accepted) AND
      preserve the existing line 131 `image: grafana/beyla:latest`
      negative assertion. Transfer pin ownership to `b8-obi.test.sh`.
      [Story: FR-B8-OBI-080 / ADR-B8-OBI-006]

- [ ] **T-SIB-002** [P] — Narrow `t5-otel.test.sh:233` :
      replace `beyla: "2\.0\.1"` exact match with `versions.beyla:`
      key-presence-only assertion. Transfer value ownership to
      `b8-obi.test.sh`.
      [Story: FR-B8-OBI-081 / ADR-B8-OBI-006]

- [ ] **T-SIB-003** [P] — Widen `b8-coroot.test.sh:196` :
      `last_reviewed:\s*2026-05-2[67]\s*$` → `last_reviewed:\s*2026-05-2[6789]\s*$`
      (1-char widening : accept -26, -27, -28, -29).
      [Story: FR-B8-OBI-083 / ADR-B8-OBI-006]

- [ ] **T-SIB-004** [P] — Widen `b8-signoz.test.sh:295` :
      `last_reviewed:\s*2026-05-26\s*$` → `last_reviewed:\s*2026-05-2[6789]\s*$`
      (1-char widening).
      [Story: FR-B8-OBI-084 / ADR-B8-OBI-006]

- [ ] **T-SIB-005** — Run `bash .forge/scripts/tests/t5-otel.test.sh --level 1`
      → MUST be GREEN post-narrowing.
      [Story: NFR-B8-OBI-009 — sibling regression check]

- [ ] **T-SIB-006** — Run `bash .forge/scripts/tests/b8-coroot.test.sh --level 1`
      → MUST be GREEN post-widening.
      [Story: NFR-B8-OBI-009]

- [ ] **T-SIB-007** — Run `bash .forge/scripts/tests/b8-signoz.test.sh --level 1`
      → MUST be GREEN post-widening.
      [Story: NFR-B8-OBI-009]

- [ ] **T-SIB-008** — `grep -rn 'beyla.*2\.0\.1\|2\.0\.1.*beyla' .forge/scripts/tests/`
      MUST return empty (no leaked hard-pins). Capture grep output to evidence.
      [Story: FR-B8-OBI-085]

### Exit gate Phase 4

- 4 sibling edits applied (2 narrow + 2 widen). All 4 affected
  harnesses pass `--level 1` GREEN. Zero leaked hard-pins on `2.0.1`.

---

## Phase 5 — Evidence collection (audit trail)

### T-EVD — `evidence.md` for ADR-B8-OBI-001..008

- [ ] **T-EVD-001** — Create `.forge/changes/b8-obi-refresh/evidence.md`
      with H1 + 8 H2 sections (one per ADR).
      [Story: NFR-B8-OBI-009 — anti-self-validation discipline]

- [ ] **T-EVD-002** — § 1 — ADR-B8-OBI-001 : capture
      `docker manifest inspect grafana/beyla:3.15.0` full JSON
      transcript + amd64+arm64 digests verbatim. Date 2026-05-29.
      [Story: ADR-B8-OBI-001]

- [ ] **T-EVD-003** — § 2 — ADR-B8-OBI-002 : capture Context7
      `/grafana/beyla` `distributed-traces.md` capability list snippet
      verbatim with the 8-cap justification table.
      [Story: ADR-B8-OBI-002]

- [ ] **T-EVD-004** — § 3 — ADR-B8-OBI-003 : capture Context7
      `/grafana/beyla` `cilium-compatibility.md` RBAC YAML snippet
      verbatim showing `services` resource.
      [Story: ADR-B8-OBI-003]

- [ ] **T-EVD-005** — § 4 — ADR-B8-OBI-004 : capture Beyla README
      Requirements section verbatim ("Linux kernel version 5.8 or
      higher with BTF enabled").
      [Story: ADR-B8-OBI-004]

- [ ] **T-EVD-006** — § 5 — ADR-B8-OBI-005 : capture `find` 4-path
      enumeration verbatim. Path-canonicalisation note for the spec
      correction (Article V preserved).
      [Story: ADR-B8-OBI-005]

- [ ] **T-EVD-007** — § 6 — ADR-B8-OBI-006 : capture
      pre/post sibling sweep grep output + 4-edit diff summary.
      Sibling-coupling-break audit trail.
      [Story: ADR-B8-OBI-006]

- [ ] **T-EVD-008** — § 7 — ADR-B8-OBI-007 : capture pre-edit
      `wc -l .github/workflows/forge-ci.yml` = 300 + post-edit count
      + line-removal diff.
      [Story: ADR-B8-OBI-007]

- [ ] **T-EVD-009** — § 8 — ADR-B8-OBI-008 : capture pre/post
      snapshot size + delta calculation + 700 KiB ceiling preservation
      proof.
      [Story: ADR-B8-OBI-008]

- [ ] **T-EVD-010** — § final — pre-flip full-CI sweep transcript :
      per-harness pass count + total wall-clock + zero-RED invariant.
      Anti-self-validation : independent reviewer re-run hook.
      [Story: FR-B8-OBI-150..152 / NFR-B8-OBI-009]

### Exit gate Phase 5

- `evidence.md` exists with 8 ADR sections + final pre-flip CI sweep
  section. Every ADR anchored to a live transcript or Context7 snippet.

---

## Phase 6 — Documentation

### T-DOC — CHANGELOG + roadmap + plan inventory + CLAUDE.md.tmpl

- [ ] **T-DOC-001** [P] — Append `CHANGELOG.md::## [Unreleased]
      ### Changed` bullet documenting Beyla 2.0.1 → 3.15.0 + RBAC
      widen `services` + sibling-trio closure + release target
      `v0.4.0-rc.5`.
      [Story: FR-B8-OBI-141]

- [ ] **T-DOC-002** [P] — Refresh
      `.forge/templates/archetypes/full-stack-monorepo/infra/CLAUDE.md.tmpl`
      H2 OBI section : cite new pin `grafana/beyla:3.15.0`, document
      RBAC `services` widening, link to ADR-B8-OBI-002/003/004 for
      caps/RBAC/kernel re-audit outcomes.
      [Story: FR-B8-OBI-140]

- [ ] **T-DOC-003** [P] — Append `docs/new-archetypes-plan.md` §0.9
      Status update — 2026-05-29 (B.8.8 — `b8-obi-refresh` archived)
      mirroring §0.7 / §0.8 layout : Origine, Fix livré, 8 ADRs résolus,
      Inverse proof + harness, Effort + release + suite.
      [Story: project-memory closure of trio]

- [ ] **T-DOC-004** [P] — Update `.forge/product/roadmap.md` Phase 3
      detail row B.8 to cite `b8-obi-refresh archived 2026-05-29 (trio
      closed)`. Update Key Milestone v0.4.0 row.
      [Story: project-memory roadmap freshness]

- [ ] **T-DOC-005** — Update `docs/new-archetypes-plan.md` §0.0
      Inventaire `.forge/changes/` table with the new row `b8-obi-refresh
      | archived | B.8.8 (OBI/Beyla refresh — trio sibling 3 — v0.4.0-rc.5 target)`.
      [Story: project-memory inventory freshness]

### Exit gate Phase 6

- CHANGELOG updated. CLAUDE.md.tmpl refreshed. Plan §0.9 status update
  added. Roadmap row updated. Inventory table updated.

---

## Phase 7 — Final verification + status flip

### T-VER — Cross-gate verification (pre-flip full-CI gate)

- [ ] **T-VER-001** — Run `.forge/scripts/verify.sh` → 0 FAIL post-
      archive. Open Questions Gate enforces Q-001..007 all `Status:
      answered`.
      [Story: NFR-B8-OBI-002]

- [ ] **T-VER-002** — Run `.forge/scripts/constitution-linter.sh` →
      OVERALL PASS. Article III.4 enforces no `[NEEDS CLARIFICATION:]`
      remaining outside backtick-wrapped historical text.
      [Story: NFR-B8-OBI-003]

- [ ] **T-VER-003** — Run `bash bin/validate-standards-yaml.sh
      .forge/standards/observability.yaml` → exit 0.
      [Story: NFR-B8-OBI-008]

- [ ] **T-VER-004** — Run `.forge/scripts/validate-change-yaml.sh
      .forge/changes/b8-obi-refresh/.forge.yaml` → exit 0.
      [Story: F.2 invariant]

- [ ] **T-VER-005** — Full-CI gate per `shared_standard_sibling_harness_coupling.md`
      : run `bash .forge/scripts/tests/_run-all.sh` (or equivalent CI
      invocation locally) → every harness GREEN, zero RED. Specifically
      assert `b8-obi.test.sh`, `b8-signoz.test.sh`, `b8-coroot.test.sh`,
      `t5-otel.test.sh`, `t5-otel-app.test.sh`,
      `t5-otel-traceparent-e2e.test.sh`, `t5-otel-live-run.test.sh`,
      `t5-otel-dartastic.test.sh`, `a7.test.sh`, `t5.test.sh`. Capture
      full transcript to evidence § final.
      [Story: FR-B8-OBI-150..151 / shared_standard_sibling_harness_coupling.md]

- [ ] **T-VER-006** — Anti-self-validation gate :
      independent reviewer (separate session / fresh transcript) re-
      executes : (a) `docker manifest inspect grafana/beyla:3.15.0`,
      (b) full harness matrix, (c) `verify.sh`, (d) `constitution-linter.sh`,
      (e) `validate-standards-yaml.sh`. Transcript comparison vs author
      claims captured to evidence.
      [Story: FR-B8-OBI-152 / NFR-B8-OBI-009]

### T-IMP — Status flip → implemented

- [ ] **T-IMP-001** — Verify Phases 1-6 exit gates all GREEN. Verify
      T-VER-001..006 all PASS.
      [Story: pre-flip gate]

- [ ] **T-IMP-002** — Edit `.forge/changes/b8-obi-refresh/.forge.yaml` :
      `status: designed → implemented` + add `timeline.implemented: 2026-05-29`.
      [Story: F.1 + F.2]

- [ ] **T-IMP-003** — Run `bash bin/forge-questions.sh --change
      b8-obi-refresh --status open` → MUST return empty (0 questions
      open).
      [Story: F.1 — Open Questions Gate]

### Exit gate Phase 7

- All gates GREEN. `b8-obi.test.sh` 22/22 GREEN. Status flipped to
  `implemented`. Trio B.8.8 ready for archive on the same session
  (or next session per maintainer preference).

---

## Archive preparation (post-implementation, separate session)

- [ ] **A-ARC-001** — Run `/forge:archive b8-obi-refresh`. Status
      flips `implemented → archived` + `timeline.archived: <date>`.
      Mark trio B.8.8 fully closed in `docs/new-archetypes-plan.md`.

- [ ] **A-REL-001** — Tag `v0.4.0-rc.5` from `main` post-archive.
      `scripts/release.sh --version 0.4.0-rc.5` (no `--otp` →
      interactive prompt or `$NPM_OTP`). Trio B.8.8 closure
      milestone.

- [ ] **A-MEM-001** — Update `MEMORY.md` (auto-memory) — add a memory
      capturing the **trio closure pattern** (Coroot → SigNoz → OBI
      legs each shipping its own rc, sibling-harness coupling break
      via hybrid narrowing+widening, Aegis re-audit per leg, all 3
      under `observability.yaml` major v2.x).

---

## Constitutional Compliance Gate (per task)

| Article                       | Per-task gate                                                                                              |
|-------------------------------|------------------------------------------------------------------------------------------------------------|
| I (TDD)                       | Phase 1 RED MUST precede Phase 2 GREEN. No task in Phase 2/3 may flip to GREEN before T-HAR-005 RED proof. |
| III (Specs Before Code)       | tasks.md derived from `specs.md` + `design.md` only. No new FR introduced here.                            |
| III.4 (Anti-Hallucination)    | T-EVD-002..009 anchor every ADR to a live transcript or Context7 snippet.                                  |
| V (Append-Only)               | T-REV-002 verifies no existing REVIEW.md row edited ; T-STD-010 verifies WAIVER block preserved.           |
| XI.1 (least privilege)        | T-CAN-002 widens RBAC by exactly 1 read-only resource ; T-CAN-005 verifies cap set unchanged.              |
| XII (Governance)              | T-STD-003 flips `breaking_change: false` ; no constitutional amendment (additive minor bump).              |

No `[TASK VIOLATION:]` triggered.
