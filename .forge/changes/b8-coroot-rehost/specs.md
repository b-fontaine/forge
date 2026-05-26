# Specifications: b8-coroot-rehost
<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, Coroot leg) -->
<!-- Trio context: .forge/_memory/b8-observability-rearch-exploration.md §5.1 -->

> **CORRECTION NOTICE (2026-05-25)** : every claim in this spec that
> "v-prefix mandatory on GHCR" (FR-B8-COR-003, FR-B8-COR-031,
> FR-B8-COR-032, source-documents row "Tag convention (verified)")
> is **inverted**. The true GHCR convention for
> `ghcr.io/coroot/coroot` is no v-prefix — `1.20.2` works,
> `v1.20.2` returns `manifest unknown`. The mis-read was caught at
> `/forge:implement` Phase 6 by the L2 manifest-pull fixture.
> Authoritative records : `design.md::ADR-B8-COR-001` (rewritten),
> `open-questions.md::Q-001` (resolution flipped), `evidence.md`
> § 1 (corrected transcripts), `CHANGELOG.md` (corrected entry),
> `REVIEW.md` (corrected entry), `observability.yaml` (pins now
> `coroot: "1.20.2"` without v-prefix). This spec is preserved
> as-is per Article V (history).

**Namespace** : `FR-B8-COR-*` / `NFR-B8-COR-*` / `ADR-B8-COR-*`.
**Constitution** : v1.1.0, unchanged. **Article II** : N/A — infra-only
template refresh, no user-facing feature ; BDD scenario documented anyway
for the L2 manifest-pull harness, mirroring `b1-1-dev-up-matrix-fixes`
precedent.

## Source Documents

| Field                             | Value                                                                                                                                       |
|-----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**                      | `docs/new-archetypes-plan.md` §4.2 B.8.8 (observability rearch)                                                                              |
| **Trio research note**            | `.forge/_memory/b8-observability-rearch-exploration.md` §2 (verify-then-pin) + §5.1 (Coroot sub-change scope)                                |
| **Originating failure 1**         | `docker manifest inspect coroot/coroot:1.4.4` ❌ `denied: requested access to the resource is denied / unauthorized: authentication required` |
| **Originating failure 2**         | `docker manifest inspect coroot/coroot:latest` ❌ same `denied/unauthorized` envelope                                                         |
| **Upstream new host (verified)**  | `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` ✅ multi-arch OCI index (amd64 + arm64)                                              |
| **Tag convention (verified)**     | `docker manifest inspect ghcr.io/coroot/coroot:v1.20.2` ❌ `manifest unknown` — v-prefix mandatory **[HISTORICAL — inverted ; corrected at /forge:implement per CORRECTION NOTICE above]**                                             |
| **Upstream compose canonical**    | `https://raw.githubusercontent.com/coroot/coroot/main/deploy/docker-compose.yaml` → `image: ghcr.io/coroot/coroot${LICENSE_KEY:+-ee}`         |
| **Upstream latest release**       | `https://api.github.com/repos/coroot/coroot/releases/latest` → `tag: v1.20.2` (2026-05-06)                                                  |
| **Current pin in standard**       | `.forge/standards/observability.yaml::versions.coroot: "1.4.4"` (set by T.5 `t5-otel-stack` 2026-05-09, ADR-OTEL-002)                        |
| **Template (canonical)**          | `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl`                                                  |
| **Template (cli bundle)**         | `cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl`                                       |
| **Rendered (example mirror)**     | `examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml`                                                                            |
| **Rendered (cli bundle example)** | `cli/assets/examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml`                                                                 |
| **Standards lifecycle owner**     | `.forge/standards/global/standards-lifecycle.md` v1.1.0 (Article XII) — additive bump path                                                  |
| **REVIEW ledger**                 | `.forge/standards/REVIEW.md` (append-only per FR-T4-LC-005 / FR-J7-023)                                                                     |
| **Harness frame**                 | `_helpers.sh` + `--level` parsing pattern from `t5-3-1.test.sh` (b1-1-dev-up-matrix-fixes 2026-05-19)                                         |
| **CI matrix budget**              | `.github/workflows/forge-ci.yml` currently 294 lines (T5.3.3 trim ADR-T533-002) ; NFR-CI-002 ≤ 300 → +6 line headroom                       |
| **Snapshot tarball owner**        | `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` regenerated via `bin/forge-snapshot.sh` (SOURCE_DATE_EPOCH-deterministic)       |
| **Release target**                | `v0.4.0-rc.3` (rc.2 sealed 2026-05-21, T5.3.1 + T5.3.3 piggybacked)                                                                          |
| **Trio sibling 1 (not yet)**      | `b8-signoz-unified` — will own `observability.yaml v2.0.0` breaking + `pin_review_cadence:` field                                            |
| **Trio sibling 2 (not yet)**      | `b8-obi-refresh` — will own Beyla 2.0.1 → 3.15.0 major bump                                                                                  |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Image rehost across all 4 copies (FR-B8-COR-001 → 020)

##### FR-B8-COR-001 — Canonical template image migrated

`.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl::spec.template.spec.containers[].image`
MUST equal exactly `ghcr.io/coroot/coroot:1.20.2`. Old value
`coroot/coroot:1.4.4` MUST NOT appear anywhere in the file.

##### FR-B8-COR-002 — Registry change is explicit (not just tag)

The substitution MUST replace **both** the registry (`docker.io` implicit
→ `ghcr.io` explicit) and the tag (`1.4.4` → `1.20.2`). A tag-only bump
under the old registry would leave the file unpullable per the
originating-failure evidence.

##### FR-B8-COR-003 — v-prefix mandatory in template

The tag in FR-B8-COR-001 MUST carry the `v` prefix. Per the
tag-convention evidence (Source Documents), GHCR returns
`manifest unknown` on the unprefixed form.

##### FR-B8-COR-004 — Cli-bundle template mirror

`cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl`
MUST be byte-identical to the canonical FR-B8-COR-001 template after
`npm run bundle`.

##### FR-B8-COR-005 — Example rendered mirror

`examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml` MUST
carry the same image reference as the canonical template (literal
`ghcr.io/coroot/coroot:1.20.2`, no templating placeholders — this file
is the rendered output).

##### FR-B8-COR-006 — Cli-bundle example mirror

`cli/assets/examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml`
MUST be byte-identical to the example mirror at FR-B8-COR-005 after
`npm run bundle`.

##### FR-B8-COR-007 — Exactly 4 paths total

`find` for `coroot-deployment.yaml` AND `coroot-deployment.yaml.tmpl`
under repo root (excluding `node_modules`, `.git`) MUST return exactly
4 paths matching the 4 above. A fifth introduction MUST be rejected by
the harness.

##### FR-B8-COR-008 — Audit comment

Each of the 4 files MUST gain (or preserve, if already present from
`t5-otel-stack`) a YAML comment block above the `containers:` block :

```yaml
# ── B.8.8 / b8-coroot-rehost (2026-05-24) — image rehost ghcr.io ──
# Migrated from coroot/coroot:1.4.4 (docker.io public-access denied
# 2026-05-24, verify-then-pin lesson T5.3.2 institutionalised).
```

#### Cluster 2 — Standard `observability.yaml` v1.1.0 → v1.2.0 (FR-B8-COR-030 → 045)

##### FR-B8-COR-030 — Version bump

`.forge/standards/observability.yaml::version` MUST move `"1.1.0"` →
`"1.2.0"`. **Additive only** ; no field is removed, no field's contract
is broken. The semver minor bump signals new pin information,
not a behavioural break.

##### FR-B8-COR-031 — `versions.coroot` field updated

The `versions.coroot` field MUST be set to `"1.20.2"` (v-prefix per
FR-B8-COR-003).

##### FR-B8-COR-032 — Within-file v-prefix heterogeneity tolerated

`versions.beyla` MUST remain `"2.0.1"` (no v-prefix) — its bump is
deferred to `b8-obi-refresh`. The heterogeneity (`beyla` no-prefix,
`coroot` v-prefix) MUST be documented in a YAML comment adjacent to
the `versions:` block. Resolution of the field-wide convention is
`[NEEDS CLARIFICATION: ADR-B8-COR-001 deferred to design]`.

##### FR-B8-COR-033 — Optional `coroot_registry` field

The standard MAY gain an explicit `coroot_registry: "ghcr.io/coroot/coroot"`
top-level or under `versions:`. The decision to add this field is
`[NEEDS CLARIFICATION: ADR-B8-COR-002 deferred to design]` — Atlas will
arbitrate whether explicit registry adds clarity or just YAML noise.

##### FR-B8-COR-034 — `last_reviewed` refreshed

`.forge/standards/observability.yaml::last_reviewed` MUST move
`2026-05-04` → `2026-05-24`. `expires_at` MAY remain `2027-05-04` per
the 12-month loose cadence (no constitutional cadence change in this
sub-change ; SigNoz 30-day cadence is reserved for `b8-signoz-unified`).

##### FR-B8-COR-035 — Frontmatter coherence with J.7 invariants

After the bump, `bash bin/validate-standards-yaml.sh
.forge/standards/observability.yaml` MUST exit 0 — the strict
`expires_at > last_reviewed` invariant (FR-J7-021), the Article XII
coupling (FR-J7-020), the REVIEW.md drift check (FR-J7-023) MUST all
still pass.

##### FR-B8-COR-036 — `linter_rule` unchanged

The standard's `linter_rule: null` declaration MUST remain ; Coroot
host change does not introduce a new `constitution-linter.sh` rule.

##### FR-B8-COR-037 — Forbidden list unchanged

`forbidden: [datadog]` MUST remain unchanged ; no Coroot-related
addition (Coroot itself is **not** forbidden per K3-RULE-001
evidence-pending). The jurisdiction posture for Coroot is documented
in the standard's `rationale:` block update (FR-B8-COR-038).

##### FR-B8-COR-038 — `rationale` updated

The `rationale:` multi-line block MUST gain a sentence acknowledging
the host migration and the verify-then-pin process that surfaced it,
without re-littering the block with full evidence (which lives in
this spec + the research note).

#### Cluster 3 — REVIEW.md ledger entry (FR-B8-COR-050 → 055)

##### FR-B8-COR-050 — Append-only entry

`.forge/standards/REVIEW.md` MUST gain a row in the running ledger :

```
| 2026-05-24 | Updated | observability.yaml v1.1.0 → v1.2.0 (b8-coroot-rehost) |
```

The row MUST be appended after the existing latest entry, never
inserted mid-ledger (FR-J7-023 append-only invariant).

##### FR-B8-COR-051 — Cross-reference to spec ID

The ledger entry MUST cite the change-name `b8-coroot-rehost` so
historical reverse-lookup from REVIEW.md → spec is possible without
git archaeology.

##### FR-B8-COR-052 — No new lifecycle exemption

Coroot pin update MUST NOT alter the `expires_at` field nor introduce
a `expires_at: never` exemption. The 12-month loose cadence remains
authoritative for `observability.yaml` (slow-moving Coroot + Beyla)
until `b8-signoz-unified` introduces the differentiated
`pin_review_cadence` field for SigNoz only.

#### Cluster 4 — Harness `b8-coroot.test.sh` (FR-B8-COR-070 → 095)

##### FR-B8-COR-070 — Harness file exists

`.forge/scripts/tests/b8-coroot.test.sh` MUST exist, executable bash,
`set -uo pipefail`, audit comment block, `--level` parsing, sources
`_helpers.sh`, manifest comment block — mirroring `t5-3-1.test.sh`
shape (b1-1-dev-up-matrix-fixes precedent).

##### FR-B8-COR-071 — ≥ 9 L1 grep-based tests

| Test ID                                                           | Asserts                                                                                                            |
|-------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| `_test_b8cor_l1_001_canonical_image_pin`                          | canonical template's `image:` line equals `ghcr.io/coroot/coroot:1.20.2`                                          |
| `_test_b8cor_l1_002_canonical_no_dockerio_coroot`                 | canonical template contains zero occurrences of `coroot/coroot:1` (substring) outside the audit comment            |
| `_test_b8cor_l1_003_canonical_audit_comment`                      | canonical template contains the FR-B8-COR-008 audit comment block                                                  |
| `_test_b8cor_l1_004_cli_bundle_template_byte_identity`            | `diff -q` between canonical and `cli/assets/.forge/templates/...` returns 0                                        |
| `_test_b8cor_l1_005_example_rendered_image_pin`                   | `examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml` image equals `ghcr.io/coroot/coroot:1.20.2`     |
| `_test_b8cor_l1_006_cli_bundle_example_byte_identity`             | `diff -q` between example rendered and `cli/assets/examples/forge-fsm-example/...` returns 0                       |
| `_test_b8cor_l1_007_four_copies_only`                             | `find` returns exactly 4 coroot-deployment files (FR-B8-COR-007)                                                   |
| `_test_b8cor_l1_008_standard_version_bumped`                      | `observability.yaml::version` regex matches `^"?1\.2\.0"?$`                                                        |
| `_test_b8cor_l1_009_standard_coroot_pin_vprefix`                  | `observability.yaml::versions.coroot` regex matches `^"?v1\.20\.2"?$`                                              |
| `_test_b8cor_l1_010_standard_last_reviewed_today`                 | `observability.yaml::last_reviewed` regex matches `2026-05-24`                                                     |
| `_test_b8cor_l1_011_review_ledger_appended`                       | `REVIEW.md` last line (or last non-empty row) matches the FR-B8-COR-050 pattern (date + Updated + change-name)     |
| `_test_b8cor_l1_012_validate_standards_yaml_passes`               | running `bash bin/validate-standards-yaml.sh .forge/standards/observability.yaml` exits 0 (FR-B8-COR-035)          |
| `_test_b8cor_l1_013_changelog_entry`                              | `CHANGELOG.md [Unreleased]` mentions `b8-coroot-rehost`                                                            |

13 L1 anchors — well above the ≥ 9 floor.

##### FR-B8-COR-072 — L2 opt-in `FORGE_B8_COROOT_DOCKER=1`

At least 1 L2 test gated by `FORGE_B8_COROOT_DOCKER=1` AND
`command -v docker` :

- `_test_b8cor_l2_001_ghcr_manifest_pullable` — runs
  `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` ; asserts
  exit 0 AND output contains `"architecture":"amd64"` AND
  `"architecture":"arm64"` (multi-arch invariant per verify-then-pin
  evidence). Skip-pass when either gate is unmet (mirrors
  `FORGE_B1DUM_DOCKER=1` precedent per FR-B1-DUM-082 →
  ADR-T5-OLR-005).

##### FR-B8-COR-073 — L2 negative-control test

A second L2 test under the same `FORGE_B8_COROOT_DOCKER=1` gate :

- `_test_b8cor_l2_002_old_pin_denied` — runs
  `docker manifest inspect coroot/coroot:1.4.4 2>&1` ; asserts the
  output contains `denied` OR `unauthorized` (verify-then-pin
  evidence stays correct over time — if this assertion ever flips,
  Coroot Inc has re-opened public access and the constitutional
  rationale weakens).

##### FR-B8-COR-074 — Determinism

Re-running `bash .forge/scripts/tests/b8-coroot.test.sh --level 1`
twice in a row on a clean tree MUST produce byte-identical stdout
(modulo wall-clock seconds). No randomness, no network, no Docker
(L1).

##### FR-B8-COR-075 — CI registration

`.github/workflows/forge-ci.yml::harness` matrix MUST register
`b8-coroot.test.sh` immediately after `t5-3-3.test.sh` (latest
registered harness as of T5.3.3) with `--level 1`.

#### Cluster 5 — Snapshot tarball regen (FR-B8-COR-100 → 105)

##### FR-B8-COR-100 — Snapshot regenerated

`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` MUST be
regenerated via `bin/forge-snapshot.sh` with `SOURCE_DATE_EPOCH` set
to a deterministic value. The new tarball reflects the rehosted
Coroot image inside its inline copy of the K8s manifest.

##### FR-B8-COR-101 — Snapshot determinism preserved

Re-running `SOURCE_DATE_EPOCH=<same-value> bin/forge-snapshot.sh
--archetype full-stack-monorepo --version 1.0.0` twice in a row MUST
produce byte-identical tarballs (existing snapshot-determinism
contract per `t5-otel-stack` NFR-OTEL-001).

##### FR-B8-COR-102 — Cli bundle snapshot mirror

`cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
MUST be byte-identical to the canonical snapshot after `npm run
bundle`.

##### FR-B8-COR-103 — `a7.test.sh` backward compat

After snapshot regen, `.forge/scripts/tests/a7.test.sh --level 1`
MUST stay GREEN (forge-upgrade non-destructive 3-way merge invariant
per A.7).

#### Cluster 6 — Documentation + plan inventory (FR-B8-COR-120 → 135)

##### FR-B8-COR-120 — CHANGELOG entry

`CHANGELOG.md` MUST gain a `### Fixed — Coroot image rehosted ghcr.io
(B.8.8, b8-coroot-rehost)` block under `[Unreleased]` citing :

- Docker Hub `coroot/coroot` denied 2026-05-24 → migrate to
  `ghcr.io/coroot/coroot:1.20.2`
- `observability.yaml` v1.1.0 → v1.2.0 additive
- REVIEW.md ledger appended
- 4-copy mirror sync
- New harness `b8-coroot.test.sh`
- Snapshot regenerated

##### FR-B8-COR-121 — Plan inventory updated

The `Inventaire .forge/changes/` table in
`docs/new-archetypes-plan.md` MUST gain a row (once `archived`) :

```
| b8-coroot-rehost | archived | B.8.8 (Coroot rehost ghcr.io + v1.20.2, T6 trio pilot) |
```

##### FR-B8-COR-122 — Roadmap status line

`.forge/product/roadmap.md` Phase 3 / T6 row MUST gain a "B.8.8
(Coroot leg) Done <date>" entry once archived. (Optional during
`specified` → mandatory at archive.)

##### FR-B8-COR-123 — `infra/CLAUDE.md.tmpl` § "Coroot persistence"

The existing § "Coroot persistence" in
`.forge/templates/archetypes/full-stack-monorepo/infra/CLAUDE.md.tmpl`
MUST be updated to cite `ghcr.io/coroot/coroot:1.20.2` if it
mentions the image pin (Atlas verifies during design phase).

##### FR-B8-COR-124 — Plan §0.7 status update entry

`docs/new-archetypes-plan.md` MUST gain a `## 0.7 Status update —
2026-05-24 (B.8.8 / b8-coroot-rehost done)` section once archived,
mirroring the §0.4 / §0.5 / §0.6 cadence. Section MAY be drafted at
`specified` phase, completed at archive.

### Non-Functional Requirements

##### NFR-B8-COR-001 — Zero new external dep

No new entry in `cli/package.json`, no new Rust crate, no new Dart
package, no new tool prerequisite. The L2 `docker manifest inspect`
gate is opt-in via env-var.

##### NFR-B8-COR-002 — Harness wall-clock budget

`bash .forge/scripts/tests/b8-coroot.test.sh --level 1` MUST complete
in ≤ 2 s on the maintainer's reference machine (apple M-series, dev
loop). L2 (`FORGE_B8_COROOT_DOCKER=1`) MAY take up to 15 s wall-clock
(2× `docker manifest inspect` calls, network-bound).

##### NFR-B8-COR-003 — `forge-ci.yml` size

After registration, `.github/workflows/forge-ci.yml` MUST remain
≤ 300 lines (NFR-CI-002). Current 294 → matrix entry adds ~3 lines
(name + comment + run) → 297 ; remains within budget. Refactor if it
doesn't.

##### NFR-B8-COR-004 — No regression on prior harnesses

`verify.sh` PASS count MUST NOT decrease.
`constitution-linter.sh` OVERALL MUST remain PASS. Existing harnesses
(`t5-1`, `t5-2`, `t5-otel-dartastic`, `t5-3-1`, `t5-3-3`, `i2..i6`,
`j7`, `j8`, `k3`, `a7`) MUST stay GREEN.

##### NFR-B8-COR-005 — Atomic revertability

The change MUST be revertable via a single `git revert <merge-sha>`
without leaving the 4 coroot-deployment copies out-of-sync or the
standard frontmatter inconsistent with REVIEW.md. (Tested via the
harness running pre- and post-revert in a separate worktree if
needed.)

##### NFR-B8-COR-006 — Coroot 1.4 → 1.20 ConfigMap schema diff

`[NEEDS CLARIFICATION: ADR-B8-COR-003 deferred to design]` — sixteen
minor versions of upstream evolution between currently-shipped
`1.4.4` and target `1.20.2`. Atlas MUST surface evidence during
`/forge:design` confirming the existing forge-templated
Coroot ConfigMap (if any) still deserialises against `1.20.2`
without requiring template-side edits. Mitigation : optional
L2 fixture (Q-001 design output) running `kind` apply with the
new pin. If schema drift is discovered, scope MAY expand to include
ConfigMap field updates — in which case this NFR auto-bumps
FR-B8-COR-030 from additive `v1.2.0` to additive-with-config-fields
`v1.3.0` (still no breaking).

##### NFR-B8-COR-007 — Demeter jurisdiction evidence

`[NEEDS CLARIFICATION: ADR-B8-COR-004 deferred to design]` —
jurisdiction of Coroot Inc vs K3-RULE-001 (T3 forbidden
US-jurisdiction). Demeter pass during `/forge:design` MUST produce
written evidence (publisher US/EU posture, CE/EE data-plane behavior,
any telemetry phone-home). Likely outcome (not pre-judged) :
T1/T2 CE-OK, T3 candidate-substitution flag, possibly a new
`K3-RULE-EXT-NNN` if warranted. If outcome is "Coroot CE forbidden
at all tiers", this sub-change escalates : Coroot would join the
standard's `forbidden:` list and the rehost becomes a substitute-
candidate exercise instead.

##### NFR-B8-COR-008 — Trio coupling tolerance

The standard `observability.yaml v1.2.0` shipped here MUST remain a
valid input for the upcoming `b8-signoz-unified` (v2.0.0 breaking)
and `b8-obi-refresh` (additive). I.e. this sub-change MUST NOT
introduce a frontmatter shape that would force one of the siblings
to revert this change before its own bump. Concretely : no new
required field introduced here that the SigNoz sibling will replace
with its v2.0.0 breaking-rewritten counterpart.

### Open Decisions Deferred to `/forge:design`

| ID                | Decision                                                                                                            | Owner               |
|-------------------|---------------------------------------------------------------------------------------------------------------------|---------------------|
| `ADR-B8-COR-001`  | `versions.*` v-prefix convention — v-prefix coroot only / uniform v-prefix / drop v-prefix at template-render time  | Atlas (Infra)       |
| `ADR-B8-COR-002`  | Optional `coroot_registry: "ghcr.io/coroot/coroot"` explicit field — add for clarity, or rely on inline image only  | Atlas (Infra)       |
| `ADR-B8-COR-003`  | Coroot 1.4 → 1.20 ConfigMap schema diff — manifest-pull L2 fixture, sample-apply on kind, both, or grep-only        | Atlas (Infra)       |
| `ADR-B8-COR-004`  | K3-RULE-001 jurisdiction posture — T1/T2 OK, T3 candidate-substitution-flag, new K3-RULE-EXT, or full forbidden     | Demeter             |

These four open questions are tracked in `open-questions.md`
(`Q-001..Q-004`) at Status `open` until design resolves each into an
ADR. The trio-sibling impact note (NFR-B8-COR-008) explicitly forbids
introducing a frontmatter shape via these ADRs that the SigNoz sibling
would have to revert.

---

## BDD Scenarios

> Article II (BDD) is N/A for this change (no user-facing feature),
> but the L2 harness scenarios are documented in Given/When/Then for
> consistency with `b1-1-dev-up-matrix-fixes` precedent.

### Scenario : GHCR manifest pullable for the new pin

```gherkin
Given an environment with `docker` on PATH
  And FORGE_B8_COROOT_DOCKER=1 is exported
When `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` is executed
Then exit code is 0
  And stdout contains "\"architecture\":\"amd64\""
  And stdout contains "\"architecture\":\"arm64\""
  And stdout contains "manifests"
```

### Scenario : Docker Hub legacy pin remains denied (verify-then-pin invariant)

```gherkin
Given an environment with `docker` on PATH
  And FORGE_B8_COROOT_DOCKER=1 is exported
When `docker manifest inspect coroot/coroot:1.4.4` is executed
Then exit code is non-zero
  And stderr (or stdout) contains "denied" or "unauthorized"
```

> If the second scenario ever flips (Coroot Inc re-opens public
> docker.io access), the verify-then-pin evidence weakens and a
> follow-up change SHOULD revisit the host migration rationale.
> The harness MUST surface this as a WARN, not silently pass —
> design phase decides whether the assertion is hard-fail or
> warn-only.

---

## Anti-Hallucination Pass

| Surface                                                  | Verified via                                                                                                          |
|----------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| `coroot/coroot:1.4.4` denied on docker.io                | `docker manifest inspect coroot/coroot:1.4.4` 2026-05-24 → `denied: unauthorized` (in-session evidence)               |
| `coroot/coroot:latest` denied on docker.io               | `docker manifest inspect coroot/coroot:latest` 2026-05-24 → same `denied: unauthorized`                               |
| `ghcr.io/coroot/coroot:1.20.2` exists multi-arch        | `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` 2026-05-24 → valid OCI image index (amd64 + arm64)            |
| v-prefix mandatory on GHCR                               | `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` 2026-05-24 → `manifest unknown`                                |
| Upstream tag `1.20.2`                                   | `https://api.github.com/repos/coroot/coroot/releases/latest` → `tag: v1.20.2`, published 2026-05-06                   |
| Upstream compose uses `ghcr.io/coroot/coroot`            | `https://raw.githubusercontent.com/coroot/coroot/main/deploy/docker-compose.yaml` → `image: ghcr.io/coroot/coroot...` |
| 4 file mirror count                                      | `find` for `coroot-deployment.yaml*` 2026-05-24 returned exactly 4 paths (Source Documents)                            |
| Current standard pin                                     | `.forge/standards/observability.yaml::versions.coroot: "1.4.4"` read 2026-05-24                                       |
| Current standard version                                 | `.forge/standards/observability.yaml::version: "1.1.0"` read 2026-05-24                                                |
| Current CI line count                                    | `wc -l .github/workflows/forge-ci.yml` after T5.3.3 ADR-T533-002 trim returned 294                                     |
| Trio sibling 1 reserved scope                            | `.forge/_memory/b8-observability-rearch-exploration.md` §5.2 — SigNoz owns v2.0.0 breaking + `pin_review_cadence`     |
| Trio sibling 2 reserved scope                            | `.forge/_memory/b8-observability-rearch-exploration.md` §5.3 — OBI owns Beyla 2 → 3 bump                              |
| L2 opt-in env-var precedent                              | `FORGE_LIVE_RUN_DOCKER=1` documented in `t5-otel-live-run` ADR-T5-OLR-005 ; same gate pattern reused                  |
| Harness frame pattern                                    | Read `t5-3-1.test.sh` FR-B1-DUM-080..084 cluster ; same shape applied as FR-B8-COR-070..075                            |

No symbol asserted in this spec is unsourced. Four explicit
`[NEEDS CLARIFICATION: ...]` markers (FR-B8-COR-032, FR-B8-COR-033,
NFR-B8-COR-006, NFR-B8-COR-007) are open against ADR-pending
decisions ; they MUST be resolved by `/forge:design` before
`/forge:plan` is run, per Article III.4.

---

*Next : `/forge:design b8-coroot-rehost`.*
