# Specifications: b8-obi-refresh
<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, OBI/Beyla leg) -->
<!-- Trio context: docs/new-archetypes-plan.md §0.8 (sibling 3 of b8-observability-rearch trio) -->
<!-- Pilot precedents: b8-coroot-rehost (v0.4.0-rc.3) + b8-signoz-unified (v0.4.0-rc.4) -->

**Namespace** : `FR-B8-OBI-*` / `NFR-B8-OBI-*` / `ADR-B8-OBI-*`.
**Constitution** : v1.1.0, unchanged. **Article II** : N/A — infra-only
template refresh, no user-facing feature ; BDD scenario documented anyway
for the L2 manifest-pull harness, mirroring `b8-coroot-rehost` precedent.

---

## Source Documents

| Field                              | Value                                                                                                                                                |
|------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**                       | `docs/new-archetypes-plan.md` §0.8 + §4.2 B.8.8 (observability rearch trio, sibling 3 — OBI/Beyla leg)                                                |
| **Trio pilot precedent**           | `.forge/changes/b8-coroot-rehost/` archived v0.4.0-rc.3 — pattern (verify-then-pin, 4-copy mirror, L2 manifest pull, additive `Updated` ledger).      |
| **Trio sibling 2 precedent**       | `.forge/changes/b8-signoz-unified/` archived v0.4.0-rc.4 — BREAKING ARCH-CHANGE + `pin_review_cadence:` field + snapshot ceiling 700 KiB (ADR-008).   |
| **Current pin in standard**        | `.forge/standards/observability.yaml::versions.beyla: "2.0.1"` (set by T.5 `t5-otel-stack` 2026-05-09, ADR-OTEL-002).                                 |
| **Current pin in template**        | `templates/full-stack-monorepo/1.0.0/infra/k8s/base/obi-daemonset.yaml.tmpl::image: grafana/beyla:2.0.1` (verified at /forge:propose).                |
| **Target pin (preliminary)**       | `grafana/beyla:3.15.0` — pending live verify at `/forge:design` (Q-001).                                                                              |
| **Tag convention (verified)**      | `versions.beyla` is **no-v-prefix** per `observability.yaml` inline disclaimer ; Docker Hub `grafana/beyla` accepts the unprefixed form.              |
| **Image registry**                 | Docker Hub `grafana/beyla` (NOT GHCR — opposite of Coroot leg ; OBI stayed on Docker Hub per existing template).                                     |
| **Standard previous state**        | v1.1.0 (T.5 ADD versions block) → v1.2.0 (`b8-coroot-rehost` Coroot bump) → v2.0.0 BREAKING (`b8-signoz-unified` SigNoz rearch).                       |
| **Trio sibling-harness 1**         | `.forge/scripts/tests/t5-otel.test.sh` — asserts beyla pin at lines 128, 233 + REVIEW.md v1.1.0 row at the append-only invariant.                     |
| **Trio sibling-harness 2**         | `.forge/scripts/tests/b8-coroot.test.sh` — asserts coroot pin + `last_reviewed` regex (audit at `/forge:design`).                                     |
| **Trio sibling-harness 3**         | `.forge/scripts/tests/b8-signoz.test.sh` — asserts signoz pins + `last_reviewed` regex (audit at `/forge:design`).                                    |
| **Template (canonical)**           | `templates/full-stack-monorepo/1.0.0/infra/k8s/base/obi-daemonset.yaml.tmpl`                                                                          |
| **Template (cli bundle)**          | `cli/assets/templates/full-stack-monorepo/1.0.0/infra/k8s/base/obi-daemonset.yaml.tmpl` — audit at `/forge:design` (Q-005)                            |
| **Rendered (example mirror)**      | `examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`                                                                                       |
| **Rendered (cli bundle example)**  | `cli/assets/examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml` — audit at `/forge:design` (Q-005)                                          |
| **Standards lifecycle owner**      | `.forge/standards/global/standards-lifecycle.md` (Article XII) — additive bump path (no waiver, no breaking flag).                                   |
| **REVIEW ledger**                  | `.forge/standards/REVIEW.md` (append-only per FR-T4-LC-005 / FR-J7-023) ; **`Updated` flag** (NOT ARCH-CHANGE — sibling 2 precedent applied inversely). |
| **Harness frame**                  | `_helpers.sh` + `--level` parsing pattern from `b8-coroot.test.sh` (sibling 1 pilot) + `b8-signoz.test.sh` (sibling 2 multi-component).               |
| **CI matrix budget**               | `.github/workflows/forge-ci.yml` currently 300/300 (NFR-CI-002 plafond) ; comment compression required to free slot.                                  |
| **Snapshot tarball owner**         | `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` ; current 668589 B post-sibling 2 ; ceiling 716800 B (ADR-B8-SIG-008).                  |
| **Release target**                 | `v0.4.0-rc.5` (closes B.8.8 trio).                                                                                                                   |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Image pin refresh across all mirrors (FR-B8-OBI-001 → 020)

##### FR-B8-OBI-001 — Canonical template image migrated

`templates/full-stack-monorepo/1.0.0/infra/k8s/base/obi-daemonset.yaml.tmpl::spec.template.spec.containers[].image`
MUST equal exactly `grafana/beyla:3.15.0` (target pin pending Q-001
live-verify). Old value `grafana/beyla:2.0.1` MUST NOT appear anywhere
in the file.

##### FR-B8-OBI-002 — Tag-only refresh (no registry change)

The substitution MUST replace **only** the tag (`2.0.1 → 3.15.0`).
Registry stays Docker Hub `grafana/beyla` (opposite of Coroot leg which
migrated `docker.io → ghcr.io`). Beyla remains pullable from Docker Hub
public access at the time of /forge:propose.

##### FR-B8-OBI-003 — No v-prefix in pin

The tag in FR-B8-OBI-001 MUST NOT carry the `v` prefix. This matches
the `observability.yaml` § `versions:` block inline disclaimer
("`coroot + beyla` are NOT v-prefixed" — opposite of `signoz/*`).

##### FR-B8-OBI-004 — Cli-bundle template mirror

`cli/assets/templates/full-stack-monorepo/1.0.0/infra/k8s/base/obi-daemonset.yaml.tmpl`
MUST be byte-identical to FR-B8-OBI-001 after `npm run bundle`.

##### FR-B8-OBI-005 — Example rendered mirror

`examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml` MUST
carry the literal `grafana/beyla:3.15.0` (no templating placeholders —
rendered file).

##### FR-B8-OBI-006 — Cli-bundle example mirror

`cli/assets/examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`
MUST be byte-identical to FR-B8-OBI-005 after `npm run bundle`.

##### FR-B8-OBI-007 — Mirror count audit

`find` for `obi-daemonset.yaml` AND `obi-daemonset.yaml.tmpl` under
repo root (excluding `node_modules`, `.git`) MUST return the exact
mirror set agreed in ADR-B8-OBI-005 (Q-005 resolution — 4 vs 6). New
mirror introductions MUST be rejected by the harness.

##### FR-B8-OBI-008 — Audit comment

Each mirror file MUST gain a YAML comment block above the `containers:`
block :

```yaml
# ── B.8.8 / b8-obi-refresh (2026-05-29) — Beyla major bump ──
# Refreshed from grafana/beyla:2.0.1 (T.5 / t5-otel-stack 2026-05-09)
# to grafana/beyla:3.15.0 (verify-then-pin discipline, lesson T5.3.2).
# Aegis re-audited caps + RBAC + kernel floor at ADR-B8-OBI-002/003/004.
```

#### Cluster 2 — Standard `observability.yaml` v2.0.0 → v2.1.0 (FR-B8-OBI-030 → 045)

##### FR-B8-OBI-030 — Version bump

`.forge/standards/observability.yaml::version` MUST change `"2.0.0"` →
`"2.1.0"` (additive minor — semver). `breaking_change:` MUST equal
`false` (or be absent, equivalent per default ; `b8-signoz-unified`
shipped `breaking_change: true` for v2.0.0 — must flip back).

##### FR-B8-OBI-031 — `versions.beyla` pin bump

`versions.beyla:` MUST equal `"3.15.0"` (no v-prefix). The previous
value `"2.0.1"` MUST NOT remain in the file.

##### FR-B8-OBI-032 — `last_reviewed` refresh

`last_reviewed:` MUST equal `2026-05-29` (current ISO-8601 date).

##### FR-B8-OBI-033 — `expires_at` refresh

`expires_at:` MUST equal `2027-05-29` (12-month lifecycle per
`standards-lifecycle.md`).

##### FR-B8-OBI-034 — `pin_review_cadence.beyla` preserved

`pin_review_cadence.beyla:` MUST remain `"P12M"` — OBI cadence is
slow (12-month) per sibling 2 precedent. NO cadence change in this
change scope.

##### FR-B8-OBI-035 — Other components untouched

`versions.signoz`, `versions.signoz_otel_collector`, `versions.clickhouse`,
`versions.signoz_zookeeper`, `versions.coroot`, and every
`pin_review_cadence.*` key other than `beyla` MUST NOT be modified.

##### FR-B8-OBI-036 — Rationale paragraph extension

The `rationale:` block MUST gain a paragraph documenting the Beyla
2.0.1 → 3.15.0 bump : trigger (sibling 3 trio closure), upstream
discipline (Grafana → OTel OBI specification compliance), Aegis
re-audit outcomes (caps + RBAC + kernel floor deltas per ADR-B8-OBI-002/003/004).

##### FR-B8-OBI-037 — Header-comment changelog entry

The file-top comment block MUST gain a v2.1.0 entry below the existing
v2.0.0 (b8-signoz-unified) entry, documenting the Beyla refresh as
**additive minor bump** (no schema surgery, no waiver).

##### FR-B8-OBI-038 — No WAIVER block

The v1.2.0 → v2.0.0 BREAKING WAIVER block (b8-signoz-unified) MUST be
preserved as-is (Article V append-only) but NO new WAIVER block is
added for v2.1.0 (additive bump does not require waiver per
`standards-lifecycle.md § Bumps`).

##### FR-B8-OBI-039 — Forbidden list preserved

`forbidden: [datadog, ...]` MUST be preserved byte-identical to v2.0.0.
This change does not introduce new forbidden entries.

##### FR-B8-OBI-040 — Schema validation post-bump

`bin/validate-standards-yaml.sh .forge/standards/observability.yaml`
MUST exit 0 after the bump. Article XII coupling
(`expires_at:never ⇔ exception_constitutional:true`) preserved at
`false/false`.

#### Cluster 3 — REVIEW.md ledger append (FR-B8-OBI-050 → 055)

##### FR-B8-OBI-050 — Append-only entry

`.forge/standards/REVIEW.md` MUST gain a new row at the end of the
existing table for `observability.yaml`, documenting the v2.0.0 →
v2.1.0 bump on 2026-05-29.

##### FR-B8-OBI-051 — `Updated` flag (NOT ARCH-CHANGE)

The flag column MUST be `Updated` (additive bump). The `ARCH-CHANGE`
flag (introduced by sibling 2 b8-signoz-unified FR-B8-SIG-H-006) MUST
NOT be used — that flag is reserved for breaking architectural shifts.

##### FR-B8-OBI-052 — Notes documenting Beyla bump

The Notes field MUST cite the bump rationale : Beyla 2.0.1 → 3.15.0
major upstream bump, Aegis re-audit completed, sibling 3 trio closure.

##### FR-B8-OBI-053 — Previous entries preserved

Every prior REVIEW.md row (v1.0.0 seed, v1.1.0 t5-otel-stack birth,
v1.2.0 b8-coroot-rehost Updated, v2.0.0 b8-signoz-unified
ARCH-CHANGE) MUST be preserved byte-identical (Article V append-only,
FR-J7-023).

#### Cluster 4 — Aegis re-audit of Linux capabilities + RBAC + kernel floor (FR-B8-OBI-060 → 075)

##### FR-B8-OBI-060 — Capability set re-confirmed against Beyla 3.x

The capability set declared in the DaemonSet
`spec.template.spec.containers[].securityContext.capabilities.add` MUST
be re-confirmed against Beyla 3.x documentation. Currently :
`BPF`, `SYS_PTRACE`, `NET_RAW`, `CHECKPOINT_RESTORE`, `DAC_READ_SEARCH`,
`PERFMON`, `NET_ADMIN`, `SYS_ADMIN`. ADR-B8-OBI-002 MUST document
which caps are added, removed, or unchanged.

##### FR-B8-OBI-061 — `drop: [ALL]` preserved

`spec.template.spec.containers[].securityContext.capabilities.drop`
MUST remain `[ALL]` — every cap not explicitly added stays dropped
(defense in depth).

##### FR-B8-OBI-062 — `privileged: false` preserved

The unprivileged-with-capabilities posture (ADR-OTEL-004) MUST be
preserved. NO `privileged: true` introduction.

##### FR-B8-OBI-063 — RBAC re-confirmed against Beyla 3.x

The ServiceAccount + ClusterRole + ClusterRoleBinding posture
(read-only on pods/nodes/replicasets) MUST be re-confirmed against
Beyla 3.x docs. ADR-B8-OBI-003 MUST document new API groups
introduced (if any).

##### FR-B8-OBI-064 — `nodeSelector` re-confirmed

`spec.template.spec.nodeSelector.forge.dev/kernel-min-58: "true"` MUST
be re-confirmed against Beyla 3.x minimum kernel. ADR-B8-OBI-004 MUST
document whether kernel-58 still suffices or must lift to 60+.

##### FR-B8-OBI-065 — Aegis annotation preserved

`metadata.annotations.forge.dev/aegis-audit: required` MUST be
preserved on the DaemonSet.

##### FR-B8-OBI-066 — Audit evidence captured

`evidence.md` MUST capture the Aegis re-audit pass : Beyla 3.x docs
references (Context7 query at `/forge:design`), capability list
verbatim, RBAC API groups verbatim, kernel floor evidence.

#### Cluster 5 — Sibling-harness coupling sweep (FR-B8-OBI-080 → 095)

##### FR-B8-OBI-080 — `t5-otel.test.sh` pin assertion updated

`.forge/scripts/tests/t5-otel.test.sh` assertion at line 128 (currently
`image: grafana/beyla:2.0.1`) MUST update to `grafana/beyla:3.15.0`.
The negative-assertion `image: grafana/beyla:latest` at line 131 MUST
remain.

##### FR-B8-OBI-081 — `t5-otel.test.sh` standard assertion updated

`.forge/scripts/tests/t5-otel.test.sh` assertion at line 233
(currently `beyla: "2\.0\.1"`) MUST update to `beyla: "3\.15\.0"` (or
narrowed strategy per ADR-B8-OBI-006).

##### FR-B8-OBI-082 — `t5-otel.test.sh` REVIEW.md row assertion narrowed

The append-only REVIEW.md v1.1.0 birth row assertion at line ~228
already accommodates additive subsequent ledger entries (per
b8-signoz-unified narrowing precedent). If still hard-pinning the
mutable end-of-table state → narrow to stable v1.1.0 birth row only.
ADR-B8-OBI-006 to document.

##### FR-B8-OBI-083 — `b8-coroot.test.sh::_test_010` date regex widened

`.forge/scripts/tests/b8-coroot.test.sh::_test_010` accepted
`last_reviewed:` regex MUST widen to accept 2026-05-29 (current set
`2026-05-2[5678]` or similar → extend by one trailing digit, or
switch to loose-date regex per ADR-B8-OBI-006).

##### FR-B8-OBI-084 — `b8-signoz.test.sh::_test_010` date regex widened

`.forge/scripts/tests/b8-signoz.test.sh::_test_010` accepted
`last_reviewed:` regex MUST widen to accept 2026-05-29. Same strategy
as FR-B8-OBI-083 per ADR-B8-OBI-006.

##### FR-B8-OBI-085 — No further sibling regressions

`grep -rn 'beyla.*2\.0\.1\|2\.0\.1.*beyla' .forge/scripts/tests/` MUST
return empty after the change (no leaked hard-pins).

##### FR-B8-OBI-086 — Sibling sweep evidence

`evidence.md` MUST capture the full sibling-harness sweep : pre-change
grep output, file list touched, post-change grep proving zero
leak-back.

#### Cluster 6 — New harness `b8-obi.test.sh` (FR-B8-OBI-100 → 115)

##### FR-B8-OBI-100 — Harness file created

`.forge/scripts/tests/b8-obi.test.sh` MUST exist and be executable
(`chmod +x`).

##### FR-B8-OBI-101 — Harness uses shared helpers

The harness MUST source `_helpers.sh` and use the shared `--level`
parser (mirror `b8-coroot.test.sh` + `b8-signoz.test.sh`).

##### FR-B8-OBI-102 — L1 tests ≥ 10

The harness MUST declare at least 10 L1 grep-based tests covering :
canonical template pin (3.15.0), no-v-prefix invariant, no-latest
invariant, no-2.0.1 leak in mirrors, 4-copy (or 6-copy) mirror count,
observability.yaml `versions.beyla` pin, `version: "2.1.0"`,
`last_reviewed: 2026-05-29`, REVIEW.md `Updated` row, snapshot ≤ 700 KiB
ceiling.

##### FR-B8-OBI-103 — L2 opt-in `FORGE_B8_OBI_DOCKER=1`

The harness MUST gate L2 tests behind `FORGE_B8_OBI_DOCKER=1` env-var
(mirror `b8-coroot.test.sh::FORGE_B8_COROOT_DOCKER=1` and
`b8-signoz.test.sh::FORGE_B8_SIGNOZ_DOCKER=1`).

##### FR-B8-OBI-104 — L2 multi-arch manifest pull

L2 MUST execute `docker manifest inspect grafana/beyla:3.15.0` and
assert exit 0 plus presence of `linux/amd64` AND `linux/arm64`
platform entries.

##### FR-B8-OBI-105 — L2 manifest digest captured

The L2 manifest digest MUST be captured to `evidence.md` § 1 (mirror
b8-signoz § 1.4 capture pattern). Digest serves as the verify-then-pin
audit ticket.

##### FR-B8-OBI-106 — L2 latest negative

L2 MUST execute `docker manifest inspect grafana/beyla:latest` and
NOT assert specific behavior — document the result whatever it is
(some Grafana images have `:latest`, some don't ; informational only).

##### FR-B8-OBI-107 — L1 perf ≤ 2 s wall-clock

L1 full suite (`--level 1`) MUST complete in ≤ 2 s wall-clock on the
maintainer's machine (mirror NFR-J7-001 / NFR-K3-DEM-005 / sibling
budgets).

##### FR-B8-OBI-108 — Skip-pass when docker absent

L2 MUST skip-pass (exit 0 with `SKIPPED` count, NOT fail) when
`docker` is absent from PATH or `FORGE_B8_OBI_DOCKER=1` is not set.

#### Cluster 7 — `forge-ci.yml` matrix registration (FR-B8-OBI-120 → 125)

##### FR-B8-OBI-120 — Harness registered

`.github/workflows/forge-ci.yml::harness` matrix MUST include
`b8-obi.test.sh` after `b8-signoz.test.sh`.

##### FR-B8-OBI-121 — NFR-CI-002 ≤ 300 lines preserved

`wc -l .github/workflows/forge-ci.yml` MUST return ≤ 300 after the
addition (currently 300/300 post-sibling 2 — comment compression
required per ADR-B8-OBI-007).

##### FR-B8-OBI-122 — Comment compression evidence

If compression applied, `evidence.md` MUST document the lines
removed (one-liner per comment) and assert no functional change to
the workflow steps.

#### Cluster 8 — Snapshot regen + a7 backward compat (FR-B8-OBI-130 → 135)

##### FR-B8-OBI-130 — Snapshot regenerated

`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` MUST be
regenerated via `bin/forge-snapshot.sh build full-stack-monorepo 1.0.0`
post-image-pin change.

##### FR-B8-OBI-131 — Snapshot size ≤ 700 KiB

The regenerated tarball MUST be ≤ 716800 bytes (ADR-B8-SIG-008
ceiling). Expected delta from current 668589 B is < 100 B (pin-only
edit). If exceeded → ADR-B8-OBI bump with WAIVER mirror of
ADR-B8-SIG-008.

##### FR-B8-OBI-132 — `a7.test.sh` 29/29 preserved

`.forge/scripts/tests/a7.test.sh` MUST run 29/29 GREEN post-snapshot
regen (forge-upgrade backward compat preserved).

#### Cluster 9 — Documentation (FR-B8-OBI-140 → 145)

##### FR-B8-OBI-140 — infra/CLAUDE.md.tmpl OBI section refreshed

`templates/full-stack-monorepo/1.0.0/infra/CLAUDE.md.tmpl` H2 OBI
section MUST cite the new pin `grafana/beyla:3.15.0` and document any
capability/RBAC/kernel-floor delta surfaced by ADR-B8-OBI-002/003/004.

##### FR-B8-OBI-141 — CHANGELOG entry

`CHANGELOG.md` `## [Unreleased]` section MUST gain a bullet under
`### Changed` documenting the Beyla bump 2.0.1 → 3.15.0 + sibling 3
trio closure + release-target `v0.4.0-rc.5`.

#### Cluster 10 — Pre-flip full-CI gate (FR-B8-OBI-150 → 155)

##### FR-B8-OBI-150 — Full CI matrix sweep before flip

Per `shared_standard_sibling_harness_coupling.md`, the FULL
`forge-ci.yml::harness` matrix MUST run GREEN locally before flipping
`planned → implemented`. Specifically : `t5-otel.test.sh`,
`b8-coroot.test.sh`, `b8-signoz.test.sh`, `b8-obi.test.sh`, plus all
other harnesses that may transitively assert observability.yaml state.

##### FR-B8-OBI-151 — Sweep evidence in evidence.md

`evidence.md` MUST capture the full-CI sweep transcript : per-harness
pass count + total wall-clock + zero-RED invariant.

##### FR-B8-OBI-152 — Anti-self-validation independent reviewer

Per `t5_2_self_validation_lesson.md`, an independent reviewer MUST
re-execute (a) `docker manifest inspect grafana/beyla:3.15.0` from
scratch, (b) the full harness matrix from scratch, (c) `verify.sh` +
`constitution-linter.sh` from scratch. Transcript comparison against
author claims MUST be in `evidence.md`.

---

### Non-Functional Requirements

#### NFR-B8-OBI-001 — Harness L1 wall-clock ≤ 2 s

`b8-obi.test.sh --level 1` MUST complete in ≤ 2 s wall-clock on the
maintainer's reference machine (mirror NFR-J7-001 / NFR-K3-DEM-005
budgets).

#### NFR-B8-OBI-002 — `verify.sh` PASS post-archive

`.forge/scripts/verify.sh` MUST exit 0 with 0 FAIL after the change is
flipped to `archived`. Open Questions Gate enforces every Q-NNN
`Status: answered`.

#### NFR-B8-OBI-003 — `constitution-linter.sh` PASS post-archive

`.forge/scripts/constitution-linter.sh` MUST exit 0 with OVERALL PASS
after `archived`. Article III.4 enforces no `[NEEDS CLARIFICATION:]`
remaining inline outside backtick-wrapped historical evidence.

#### NFR-B8-OBI-004 — `a7.test.sh` 29/29 forge-upgrade backward compat

The snapshot regen MUST NOT regress `a7.test.sh` (forge-upgrade
backward-compat). 29/29 GREEN preserved.

#### NFR-B8-OBI-005 — Snapshot ≤ 700 KiB ceiling

ADR-B8-SIG-008 ceiling (716800 bytes) MUST hold. If exceeded → new
ADR with WAIVER (mirror ADR-B8-SIG-008 pattern). Beyla pin-only edit
expected delta ≪ 100 B → no ceiling pressure expected.

#### NFR-B8-OBI-006 — Article V append-only on REVIEW.md

Every existing REVIEW.md row MUST be byte-identical post-change.
Only append at the end of the `observability.yaml` table.

#### NFR-B8-OBI-007 — `forge-ci.yml` ≤ 300 lines

NFR-CI-002 plafond MUST hold. Comment compression strategy per
ADR-B8-OBI-007 freezes the slot for the new harness entry without
exceeding budget.

#### NFR-B8-OBI-008 — `validate-standards-yaml.sh` exit 0

`.forge/scripts/bin/validate-standards-yaml.sh .forge/standards/observability.yaml`
MUST exit 0 post-bump. All 5 J.7 invariants preserved.

#### NFR-B8-OBI-009 — Anti-self-validation discipline

T5.2 lesson : reviewer MUST re-execute gates from scratch (no
transcript trust). Evidence captured in `evidence.md` § final.

#### NFR-B8-OBI-010 — No new external dep

Harness MUST NOT introduce new external dependencies. Bash + Python 3
stdlib only (mirror F.2 / J.7 / J.8.d / K.3 pattern).

#### NFR-B8-OBI-011 — Determinism

`SOURCE_DATE_EPOCH`-deterministic snapshot output preserved. Two
back-to-back `bin/forge-snapshot.sh build` invocations MUST produce
byte-identical tarballs (mirror NFR-J8-005 / NFR-K3-DEM-005).

---

### Open Decisions Deferred to `/forge:design`

These are documented as ADR scaffolds. Resolved values land in
`design.md::ADR-B8-OBI-NNN` and `open-questions.md::Q-NNN`.

- **ADR-B8-OBI-001 / Q-001** — final target tag (`3.15.0` vs latest
  stable on Docker Hub) confirmed by live `docker manifest inspect`.
- **ADR-B8-OBI-002 / Q-002** — Beyla 3.x Linux capability set delta vs
  2.x ; tighten/widen + justification.
- **ADR-B8-OBI-003 / Q-003** — Beyla 3.x RBAC delta vs 2.x ; new API
  groups required.
- **ADR-B8-OBI-004 / Q-004** — Beyla 3.x minimum kernel ; kernel-58
  nodeSelector still valid vs lift to 60+.
- **ADR-B8-OBI-005 / Q-005** — mirror copy count (4 vs 6) ;
  enumerate every path holding `obi-daemonset.yaml*`.
- **ADR-B8-OBI-006 / Q-006** — sibling-harness narrowing strategy :
  loose-date regex vs commit-pin vs narrowed assertion. Applies to
  `t5-otel.test.sh:128/233`, `b8-coroot.test.sh::_test_010`,
  `b8-signoz.test.sh::_test_010`.
- **ADR-B8-OBI-007 / Q-007** — `forge-ci.yml` line-budget freeing
  strategy (comment compression vs collapsing matrix entries).

---

## BDD Scenarios

Article II is N/A for infra-only template refresh, but the L2
manifest-pull harness gets a Gherkin scenario for completeness
(mirror `b8-coroot-rehost` precedent).

### Scenario : Docker Hub manifest pullable for the new pin

```gherkin
Feature: OBI/Beyla pin refresh to 3.15.0
  As a Forge framework maintainer
  I want the new Beyla pin to be live on Docker Hub before merging
  So that adopters scaffolding `full-stack-monorepo / 1.0.0` after merge
  do not inherit an unpullable DaemonSet.

  Scenario: Multi-arch manifest pullable for grafana/beyla:3.15.0
    Given the FORGE_B8_OBI_DOCKER=1 environment is set
    And `docker manifest inspect` is on PATH
    When I run `docker manifest inspect grafana/beyla:3.15.0`
    Then the command MUST exit 0
    And the output MUST contain a `manifests` array
    And the array MUST contain entries with `platform.architecture: amd64`
    And the array MUST contain entries with `platform.architecture: arm64`
    And every entry's `platform.os` MUST equal `linux`
```

### Scenario : Old pin still pullable (informational, no invariant break)

```gherkin
  Scenario: Beyla 2.0.1 stays on Docker Hub (informational)
    Given the FORGE_B8_OBI_DOCKER=1 environment is set
    When I run `docker manifest inspect grafana/beyla:2.0.1`
    Then the command MAY exit 0 (Grafana does not routinely yank tags)
    And whatever the result, it is captured to evidence.md
    But the harness MUST NOT fail on this — Beyla 2.x persistence is
    informational discipline evidence, not an invariant.
```

---

## Anti-Hallucination Pass

| Check                                                | Status                                                                                |
|------------------------------------------------------|---------------------------------------------------------------------------------------|
| All Q-NNN markers paired with ADR-B8-OBI-NNN         | ✅ Q-001..007 → ADR-001..007.                                                          |
| Target pin `3.15.0` verified live                    | ⏳ Pending /forge:design — verify-then-pin discipline (lesson T5.3.2 institutional).   |
| Beyla 3.x capability/RBAC/kernel delta verified      | ⏳ Pending /forge:design — Context7 query `/grafana/beyla` + upstream changelog.       |
| Mirror copy count verified                           | ⏳ Pending /forge:design — `find` against repo, document in ADR-B8-OBI-005.            |
| Sibling-harness leak-points enumerated               | ✅ 4 known (`t5-otel:128/233`, `b8-coroot::_test_010`, `b8-signoz::_test_010`). Full enumeration at design.    |
| `forge-ci.yml` line budget strategy chosen           | ⏳ Pending /forge:design — ADR-B8-OBI-007 (comment compression vs collapse).           |
| Snapshot ceiling impact estimated                    | ✅ Expected delta < 100 B ; ceiling 716800 B comfortably preserved.                    |
| `Updated` vs `ARCH-CHANGE` flag chosen               | ✅ `Updated` (additive bump per sibling 2 precedent inverse).                          |
| Constitution v1.1.0 compliance                       | ✅ No amendment needed ; Article I + III + III.4 + V + XII compliant by design.        |

All `⏳` items convert to ✅ at `/forge:design` via Context7-anchored
evidence + live `docker manifest inspect` transcripts.
