# Specifications: t5-cargo-pin-refresh
<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: T5.1.E (docs/new-archetypes-plan.md §0.1 extension — Option B) -->

**Namespace** : `FR-T5CPR-*` / `NFR-T5CPR-*`. **Constitution** : v1.1.0,
unchanged.

## Source Documents

| Field                          | Value                                                                                                                                  |
|--------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**                   | `docs/new-archetypes-plan.md` §0.1 extension (2026-05-16) — Option B, T5.1.E                                                          |
| **Roadmap ref**                | `.forge/product/roadmap.md` Phase 2 T5.1 row (Partial → Done after this change archives)                                              |
| **Originating bug**            | `task smoke-with-toolchains` (cli-trust-harness FORGE_E2E_TOOLCHAINS=1) fail 2026-05-16 : `buffa = "=0.3.3"` not resolvable on crates.io |
| **Bug introduced by**          | `t5-connect-codegen` archived 2026-05-06 (PR #3) ; transport.yaml v1.1.0 ; Cargo.toml.tmpl pins lines 27-28                            |
| **Upstream fact source**       | crates.io REST API : `https://crates.io/api/v1/crates/buffa`, `…/buffa-types`, `…/connectrpc/0.3.3/dependencies` (queried 2026-05-16) |
| **Standard touched**           | `.forge/standards/transport.yaml` v1.1.0 → **v1.2.0** (additive, REVIEW.md ledger Updated entry)                                       |
| **Templates touched**          | `Cargo.toml.tmpl` (source + cli/assets/ mirror)                                                                                       |
| **Snapshots touched**          | `full-stack-monorepo/1.0.0.tar.gz` (source + cli/assets/ mirror)                                                                      |
| **Harness frame**              | `f3.test.sh` (10 L1 + 1 L2 opt-in pattern) ; `_helpers.sh` shared runner                                                                |
| **CI matrix**                  | `.github/workflows/forge-ci.yml` `harness` job (292 lines today ; NFR-CI-002 ≤ 300)                                                    |
| **Constitution refs**          | Articles I (TDD), III (specs before code), V (audit trail), XII (governance / standards-lifecycle re-revue)                            |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Pin correction in templates (FR-T5CPR-001 → 015)

##### FR-T5CPR-001 — `buffa` pin corrected in source template

The file
`.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/Cargo.toml.tmpl`
MUST declare `buffa = "=0.3.0"` (instead of `=0.3.3`).

##### FR-T5CPR-002 — `buffa-types` pin corrected in source template

The same file MUST declare `buffa-types = "=0.3.0"` (instead of
`=0.3.3`).

##### FR-T5CPR-003 — `connectrpc` pin unchanged

`connectrpc = "=0.3.3"` MUST remain at `=0.3.3` (the version exists
on crates.io ; ADR-T5-001 of `t5-connect-codegen` holds).

##### FR-T5CPR-004 — `connectrpc-build` pin unchanged

`connectrpc-build = "=0.3.3"` MUST remain at `=0.3.3`.

##### FR-T5CPR-005 — Bundled-assets template mirrors

`cli/assets/.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/Cargo.toml.tmpl`
MUST carry the same FR-T5CPR-001..004 edits as the source. The two
files MUST be byte-identical after the change lands.

#### Cluster 2 — Standard amendment (FR-T5CPR-020 → 040)

##### FR-T5CPR-020 — `transport.yaml` version bumped

`.forge/standards/transport.yaml` MUST declare `version: "1.2.0"`
(was `"1.1.0"`).

##### FR-T5CPR-021 — `buffa` pin corrected in `transport.yaml`

The same file MUST declare `buffa: "=0.3.0"` in its
`codegen.versions:` block.

##### FR-T5CPR-022 — `buffa-types` pin corrected in `transport.yaml`

The same file MUST declare `buffa-types: "=0.3.0"`.

##### FR-T5CPR-023 — WAIVER comment block rewritten

Lines 55-63 of `transport.yaml` (the multi-line `# WAIVER 2026-05-05`
comment block) MUST be replaced with a comment that :

- Records the original WAIVER amendment date (`2026-05-16`) and the
  ID of this change (`t5-cargo-pin-refresh`).
- States the factual cause : `buffa` and `buffa-types` 0.3.1 / 0.3.2
  / 0.3.3 were never published ; `=0.3.0` is the only resolvable
  exact pin in their 0.3 series.
- States that `connectrpc 0.3.3` declares `buffa = "^0.3"` (the
  semver-caret constraint) and therefore `=0.3.0` satisfies it.
- States that the pedigree-style justifications previously listed
  for `=0.3.3` (conformance suite, Anthropic OSS, 30-day rule
  waiver) **continue to apply** to the `connectrpc` and
  `connectrpc-build` pins (still at `=0.3.3`) but are not the
  load-bearing argument for the corrected `buffa` / `buffa-types`
  pins.

The replacement comment block SHOULD remain ≤ 12 lines.

##### FR-T5CPR-024 — REVIEW.md ledger entry

`.forge/standards/REVIEW.md` MUST gain an append-only entry for
`transport.yaml v1.2.0` :

```
| Updated 2026-05-16 | transport.yaml | 1.1.0 → 1.2.0 | t5-cargo-pin-refresh | buffa + buffa-types pin correction (=0.3.3 → =0.3.0 ; crates.io 0.3.1+ never published) |
```

Format may follow the existing ledger convention exactly.

#### Cluster 3 — Snapshot regeneration (FR-T5CPR-050 → 060)

##### FR-T5CPR-050 — Source snapshot tarball regenerated

`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` MUST be
regenerated **after** the template edits (FR-T5CPR-001..002) land,
so the embedded `Cargo.toml.tmpl` matches the post-fix source. The
regeneration mechanism is the standard one (`bin/forge-snapshot.sh`
or equivalent ; documented in B.8.2 / A.7 backward-compat policy).

##### FR-T5CPR-051 — Bundled-assets snapshot mirror regenerated

`cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
MUST contain the regenerated tarball — either via direct copy from
the source, or via `npm run bundle` re-run.

##### FR-T5CPR-052 — Snapshot content invariant

After regeneration, extracting any snapshot tarball and grepping
its `grpc-api/Cargo.toml.tmpl` MUST find `buffa = "=0.3.0"` AND
`buffa-types = "=0.3.0"`. The post-fix grep MUST find **zero**
occurrences of `buffa = "=0.3.3"` or `buffa-types = "=0.3.3"`.

##### FR-T5CPR-053 — Snapshot mirror byte-identity

The source snapshot and the bundled mirror MUST be byte-identical
post-regeneration (verified by `diff -q` or equivalent).

#### Cluster 4 — Test harness (FR-T5CPR-070 → 090)

##### FR-T5CPR-070 — Harness file presence

A new file `.forge/scripts/tests/t5-cargo.test.sh` MUST exist as an
executable bash harness.

##### FR-T5CPR-071 — Strict mode + audit

The harness MUST carry `set -uo pipefail` and the audit comment
`# Audit: T5.1.E (t5-cargo-pin-refresh)` in the first 10 lines.

##### FR-T5CPR-072 — `--level` parsing

The harness MUST accept `--level <1|2|1,2|all>` mirroring
`f3.test.sh`.

##### FR-T5CPR-073 — ≥ 8 L1 tests

The harness MUST register at least **8 L1 hermetic grep-based tests** :

| Test ID                              | Asserts                                                                            |
|--------------------------------------|------------------------------------------------------------------------------------|
| `_test_t5c_l1_001_source_template`   | source Cargo.toml.tmpl has `buffa = "=0.3.0"` and `buffa-types = "=0.3.0"`         |
| `_test_t5c_l1_002_source_no_dead_pin`| source Cargo.toml.tmpl has no `=0.3.3` pin for `buffa` or `buffa-types`            |
| `_test_t5c_l1_003_mirror_template`   | bundled-assets mirror has the same content (or byte-identical to source)            |
| `_test_t5c_l1_004_standard_version`  | `transport.yaml::version` is `"1.2.0"`                                              |
| `_test_t5c_l1_005_standard_pins`     | `transport.yaml` has `buffa: "=0.3.0"` and `buffa-types: "=0.3.0"`                  |
| `_test_t5c_l1_006_standard_waiver_rewritten` | The pre-fix pedigree-justification phrasing for `=0.3.3` is absent, the new amend note is present (per ADR-T5CPR-003) |
| `_test_t5c_l1_007_review_ledger`     | `REVIEW.md` contains an `Updated 2026-05-16` entry referencing `t5-cargo-pin-refresh` |
| `_test_t5c_l1_008_snapshot_content`  | Extracting the source snapshot tarball and grepping its embedded Cargo.toml.tmpl finds `=0.3.0` (no `=0.3.3`) for buffa-family |
| `_test_t5c_l1_009_snapshot_mirror_identity` | source snapshot and bundled mirror are byte-identical (`shasum -a 256` match) |
| `_test_t5c_l1_010_changelog_entry`   | CHANGELOG `[Unreleased]` references `t5-cargo-pin-refresh`                          |

The 8-L1-floor wording in FR-T5CPR-073 is satisfied by the 10
anchors listed (margin acceptable).

##### FR-T5CPR-074 — L2 opt-in `FORGE_T5C_LIVE=1`

The harness MUST register **at least 1 L2 fixture-based test**
gated by `FORGE_T5C_LIVE=1` :

- `_test_t5c_l2_resolve_against_crates_io` — invokes `curl` against
  the crates.io REST API to assert that `buffa` 0.3.0 + `buffa-types`
  0.3.0 still exist (non-yanked) and that `connectrpc 0.3.3`
  declares `buffa = "^0.3"`. Skip-pass when `FORGE_T5C_LIVE` is
  unset (network-bound, mirrors `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`
  pattern).

##### FR-T5CPR-075 — CI registration

`.github/workflows/forge-ci.yml` MUST register `t5-cargo.test.sh`
in the `harness` job matrix immediately after `t5-1.test.sh` with
`--level 1`. Workflow MUST stay ≤ 300 lines (NFR-CI-002).

#### Cluster 5 — Documentation (FR-T5CPR-100 → 110)

##### FR-T5CPR-100 — CHANGELOG entry

`CHANGELOG.md [Unreleased]` MUST gain a
`### Fixed — Cargo pin refresh (T5.1.E, t5-cargo-pin-refresh)` block
listing the two corrected pins + the snapshot regeneration
+ the `transport.yaml` v1.2.0 bump.

##### FR-T5CPR-101 — Plan + roadmap inventory rows

The `Inventaire .forge/changes/` table in
`docs/new-archetypes-plan.md` MUST gain a row for
`t5-cargo-pin-refresh | archived | T5.1.E (cargo pin)`. The
archived count MUST be bumped from 25 to 26.

##### FR-T5CPR-102 — Plan T5.1 status update

`docs/new-archetypes-plan.md` §0.1 extension MUST flip the T5.1.E
item from "*(nouveau change)*" to "**Done 2026-05-XX** via
`t5-cargo-pin-refresh`". §1.4 + §11 rows updated accordingly.

##### FR-T5CPR-103 — Roadmap row flip

`.forge/product/roadmap.md` T5.1 row MUST flip from `**Partial**`
to `**Done**` once both `cli-trust-harness` AND
`t5-cargo-pin-refresh` are archived.

### Non-Functional Requirements

##### NFR-T5CPR-001 — Zero new external dep

No new entry in `cli/package.json` / no new crate in the workspace.
Harness uses only `curl`, `python3`, `bash`, `tar`, `shasum`
(already required by the F.2 / J.7 / J.8.d / K.3 precedents).

##### NFR-T5CPR-002 — Harness wall-clock budget

`bash .forge/scripts/tests/t5-cargo.test.sh --level 1` MUST
complete in ≤ 3 s on the maintainer's machine. L2 opt-in
(`FORGE_T5C_LIVE=1`) MAY take up to 10 s (network round-trips).

##### NFR-T5CPR-003 — `forge-ci.yml` size

After registration, `.github/workflows/forge-ci.yml` MUST remain
≤ 300 lines (currently 292 ; +5 ≈ within budget).

##### NFR-T5CPR-004 — Snapshot determinism

The regenerated snapshot tarball MUST be deterministic enough for
the harness to grep its content reliably. Strict byte-identity
across regenerations is **not** required (gzip headers may differ
across systems) — only content-extraction-grep parity.

##### NFR-T5CPR-005 — Backwards compatibility

`forge upgrade` invoked against an existing scaffold that was
created from the **pre-fix** template MUST still work :

- The post-fix snapshot is the new BASE for `forge upgrade --diff3`.
- Existing adopter trees may contain `buffa = "=0.3.3"` (which
  was already not building) ; their `forge upgrade` would offer
  the corrected line as a 3-way merge candidate.

No archetype `schema` bump is performed (1.0.0 stays 1.0.0 — the
fix is at template level, not at schema-contract level).

### Modified Requirements

##### MR-T5CPR-001 — `transport.yaml::codegen.versions.buffa`

`buffa: "=0.3.3"` → `buffa: "=0.3.0"`.

##### MR-T5CPR-002 — `transport.yaml::codegen.versions.buffa-types`

`buffa-types: "=0.3.3"` → `buffa-types: "=0.3.0"`.

##### MR-T5CPR-003 — `transport.yaml::version`

`version: "1.1.0"` → `version: "1.2.0"`.

##### MR-T5CPR-004 — `transport.yaml` WAIVER comment block

Rewritten per ADR-T5CPR-003 (see design.md).

##### MR-T5CPR-005 — `Cargo.toml.tmpl` (source + mirror)

Lines 27-28 corrected per FR-T5CPR-001..002.

##### MR-T5CPR-006 — Snapshot tarballs (source + mirror)

Regenerated per FR-T5CPR-050..053.

##### MR-T5CPR-007 — `.github/workflows/forge-ci.yml` matrix

Extended with one new step registering `t5-cargo.test.sh`.

### Removed Requirements

None.

---

## BDD Scenarios (Article II)

### Scenario 1 — Adopter scaffolds and builds

```gherkin
Feature: Cargo pin refresh (T5.1.E)

  Scenario: Fresh full-stack-monorepo scaffold builds with cargo
    Given a fresh tmpdir (non-existent before invocation)
    When `forge init smoke_fsm --archetype full-stack-monorepo --org dev.forge.test --target <tmp>` runs
    Then exit code is 0
    And `<tmp>/backend/crates/grpc-api/Cargo.toml` contains `buffa = "=0.3.0"`
    And `<tmp>/backend/crates/grpc-api/Cargo.toml` does NOT contain `buffa = "=0.3.3"`
    When the maintainer runs `cd <tmp>/backend && cargo check --workspace`
    Then exit code is 0
    And the error `failed to select a version for the requirement \`buffa = "=0.3.3"\`` is NOT present in stderr
```

### Scenario 2 — Standard re-revue trail

```gherkin
Feature: Standard versioning discipline (Article XII)

  Scenario: transport.yaml bump produces an audit-trail entry
    Given transport.yaml was at v1.1.0 before this change
    When this change lands
    Then transport.yaml::version is "1.2.0"
    And REVIEW.md contains an `Updated 2026-05-16` row referencing transport.yaml + t5-cargo-pin-refresh
    And the bump is additive (no breaking_change: true)
```

---

## Constitution Compliance Verification

| Article            | Compliance                                                                                                                      |
|--------------------|---------------------------------------------------------------------------------------------------------------------------------|
| **I — TDD**        | Phase 1 of `tasks.md` writes harness with ≥ 8 L1 stubs RED ; Phase 2 ships template + standard fix ; Phase 3 snapshot regen ; Phase 4 docs. |
| **II — BDD**       | Two Gherkin scenarios above ; adopter-facing flow + standard re-revue.                                                          |
| **III — Specs**    | This file precedes any pin edit.                                                                                                |
| **III.4 — Anti-hallucination** | Q-001..Q-003 in `open-questions.md` ; resolved by ADR-T5CPR-001..003 in `design.md`. No inline marker.              |
| **V — Audit**      | Every artefact carries `Audit: T5.1.E (t5-cargo-pin-refresh)`.                                                                  |
| **XII — Governance** | Standard bump uses the canonical re-revue procedure (`global/standards-lifecycle.md`) ; REVIEW.md ledger gains an Updated entry. |

---

## Open Questions reference

See `open-questions.md` Q-001..Q-003 ; resolved by ADR-T5CPR-001..003 in
`design.md`.
