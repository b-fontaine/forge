# Specifications: t5-bin-server-deps
<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: T5.1.E (Option B follow-on to t5-cargo-pin-refresh) -->

**Namespace** : `FR-T5BSD-*` / `NFR-T5BSD-*`. **Constitution** :
v1.1.0, unchanged.

## Source Documents

| Field                  | Value                                                                                                                              |
|------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**           | `docs/new-archetypes-plan.md` §0.1 extension (Option B follow-on, bug surfaced after `t5-cargo-pin-refresh` archived)                |
| **Originating bug**    | `task smoke-with-toolchains` post-buffa-fix 2026-05-16 : `bin-server/src/main.rs` E0432/E0433 unresolved import diagnostics          |
| **Template gap 1**     | `bin-server/Cargo.toml.tmpl` missing — only `src/main.rs.tmpl` shipped today                                                       |
| **Template gap 2**     | `backend/Cargo.toml.tmpl::workspace.dependencies` missing `axum`, `tower-http`, `http`                                              |
| **Version constraint** | `connectrpc 0.3.3` (pinned by `t5-cargo-pin-refresh`) declares `axum = "^0.8"` (verified via crates.io REST API 2026-05-16)         |
| **Reference**          | `examples/forge-fsm-example/backend/bin-server/Cargo.toml` (hand-built, builds today — used as the canonical shape for the template) |
| **Harness frame**      | `t5-cargo.test.sh` (10 L1 + 1 L2 opt-in pattern) ; `_helpers.sh`                                                                    |
| **CI matrix**          | `.github/workflows/forge-ci.yml` `harness` job (currently 297 lines post-`t5-cargo.test.sh` ; NFR-CI-002 ≤ 300)                     |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Workspace deps (FR-T5BSD-001 → 010)

##### FR-T5BSD-001 — `axum` declared as workspace dep

`.forge/templates/archetypes/full-stack-monorepo/backend/Cargo.toml.tmpl::[workspace.dependencies]`
MUST declare `axum = "0.8"`.

##### FR-T5BSD-002 — `tower-http` declared as workspace dep

Same file MUST declare
`tower-http = { version = "0.6", features = ["trace"] }`.

##### FR-T5BSD-003 — `http` declared as workspace dep

Same file MUST declare `http = "1"`.

##### FR-T5BSD-004 — Audit comment line

The three new deps SHOULD be preceded by a comment block tagging
the audit ID :

```toml
# ── HTTP / transport (T5.1.E follow-on, t5-bin-server-deps) ──
# axum 0.8 is required by connectrpc 0.3.3 (declares `axum = "^0.8"`).
```

##### FR-T5BSD-005 — Existing workspace deps preserved

The following deps MUST remain declared (`tokio`, `tracing`,
`tracing-subscriber`, `tonic`, `anyhow`, `thiserror`, `prost`,
`sqlx`, `serde`, `serde_json` etc.). No removal.

#### Cluster 2 — `bin-server/Cargo.toml.tmpl` (FR-T5BSD-020 → 040)

##### FR-T5BSD-020 — New file present

A new file
`.forge/templates/archetypes/full-stack-monorepo/backend/bin-server/Cargo.toml.tmpl`
MUST exist and be valid TOML.

##### FR-T5BSD-021 — Package metadata

The `[package]` block MUST declare :

- `name = "bin-server"`
- `version = "0.1.0"`
- `edition = "2024"`

##### FR-T5BSD-022 — Path dep on `grpc-api`

The `[dependencies]` block MUST declare
`grpc-api = { path = "../crates/grpc-api" }` so the symbol
`grpc_api::transport_connect` resolves at compile time.

##### FR-T5BSD-023 — Workspace deps inherited

The `[dependencies]` block MUST inherit these crates via
`{ workspace = true }` :

- `tokio`
- `anyhow`
- `tracing`
- `tracing-subscriber`
- `tonic`
- `axum`
- `tower-http`
- `http`

##### FR-T5BSD-024 — Audit comment

The new file MUST carry
`# <!-- Audit: T5.1.E (t5-bin-server-deps) -->` within the first
10 lines.

##### FR-T5BSD-025 — No business-logic deps

The new file MUST NOT declare deps that belong in `crates/domain/`,
`crates/application/`, or `crates/infrastructure/` (per
backend/CLAUDE.md hexagonal rules — `bin-server/` is wiring only).
This means no `sqlx`, no `reqwest`, no `serde`-as-direct-dep, etc.
The transitive closure via path deps is acceptable.

#### Cluster 3 — Bundled mirror + snapshot (FR-T5BSD-050 → 060)

##### FR-T5BSD-050 — Bundled-assets mirror

After `npm run bundle`, the bundled mirrors at
`cli/assets/.forge/templates/.../Cargo.toml.tmpl` (workspace) and
`cli/assets/.forge/templates/.../bin-server/Cargo.toml.tmpl`
(new) MUST be byte-identical to their sources.

##### FR-T5BSD-051 — Snapshot tarballs regenerated

`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
(+ bundled mirror) MUST be regenerated post-fix via
`bin/forge-snapshot.sh build full-stack-monorepo 1.0.0`. Extracting
the snapshot's `bin-server/Cargo.toml.tmpl` MUST yield a parseable
TOML containing the FR-T5BSD-021..023 fields.

#### Cluster 4 — Test harness (FR-T5BSD-070 → 090)

##### FR-T5BSD-070 — Harness file

A new file `.forge/scripts/tests/t5-bin-server.test.sh` MUST
exist as executable bash, with `set -uo pipefail`, audit comment,
`--level` parsing, `_helpers.sh` source, manifest comment block.

##### FR-T5BSD-071 — ≥ 7 L1 tests

| Test ID                                              | Asserts                                                                                                  |
|------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| `_test_t5bsd_l1_001_workspace_axum`                  | `backend/Cargo.toml.tmpl` declares `axum = "0.8"` in `[workspace.dependencies]`                          |
| `_test_t5bsd_l1_002_workspace_tower_http`            | declares `tower-http = { version = "0.6", features = ["trace"] }`                                         |
| `_test_t5bsd_l1_003_workspace_http`                  | declares `http = "1"`                                                                                     |
| `_test_t5bsd_l1_004_bin_server_manifest_exists`      | `bin-server/Cargo.toml.tmpl` exists + audit comment present                                              |
| `_test_t5bsd_l1_005_bin_server_grpc_api_path_dep`    | bin-server declares `grpc-api = { path = "../crates/grpc-api" }`                                          |
| `_test_t5bsd_l1_006_bin_server_workspace_deps`       | bin-server inherits all 8 deps via `workspace = true` (FR-T5BSD-023 list)                                |
| `_test_t5bsd_l1_007_mirror_byte_identity`            | `diff -q` between source + bundled mirror returns 0 for both Cargo.toml.tmpl files                       |
| `_test_t5bsd_l1_008_snapshot_content`                | Tar-extracting the snapshot finds the new `bin-server/Cargo.toml.tmpl` with `name = "bin-server"`        |
| `_test_t5bsd_l1_009_changelog_entry`                 | `CHANGELOG.md [Unreleased]` references `t5-bin-server-deps`                                              |

9 L1 anchors — meets the ≥ 7 floor.

##### FR-T5BSD-072 — L2 opt-in `FORGE_T5BSD_LIVE=1`

The harness MUST register at least 1 L2 test gated by
`FORGE_T5BSD_LIVE=1` :

- `_test_t5bsd_l2_cargo_check_fresh_scaffold` — invokes
  `node cli/dist/index.js init smoke_t5bsd --archetype
  full-stack-monorepo --org dev.forge.test --target $tmp`
  then `cd $tmp/backend && cargo check --workspace`. Asserts
  exit 0. Skip-pass when `FORGE_T5BSD_LIVE` is unset OR `cargo`
  is absent on PATH.

##### FR-T5BSD-073 — CI registration

`.github/workflows/forge-ci.yml` MUST register
`t5-bin-server.test.sh` in the matrix immediately after
`t5-cargo.test.sh` with `--level 1`. Workflow stays ≤ 300 lines.

#### Cluster 5 — Documentation (FR-T5BSD-100 → 110)

##### FR-T5BSD-100 — CHANGELOG entry

`CHANGELOG.md [Unreleased]` MUST gain a `### Fixed — bin-server
deps + workspace HTTP deps (T5.1.E follow-on, t5-bin-server-deps)`
block citing the three workspace deps + the new Cargo.toml.tmpl
+ the snapshot regen.

##### FR-T5BSD-101 — Plan inventory

The `Inventaire .forge/changes/` table in
`docs/new-archetypes-plan.md` MUST gain a row for
`t5-bin-server-deps | archived | T5.1.E (bin-server deps)`. Count
26 → 27.

### Non-Functional Requirements

##### NFR-T5BSD-001 — Zero new external dep

No new entry in `cli/package.json` ; no new tool requirement
beyond what `t5-cargo-pin-refresh` already needs.

##### NFR-T5BSD-002 — Harness wall-clock

`bash t5-bin-server.test.sh --level 1` MUST complete in ≤ 3 s.
L2 (`FORGE_T5BSD_LIVE=1`) MAY take up to 90 s wall-clock
(includes `cargo check --workspace` cold compile of ~188 packages).

##### NFR-T5BSD-003 — `forge-ci.yml` size

After registration, `.github/workflows/forge-ci.yml` MUST remain
≤ 300 lines.

##### NFR-T5BSD-004 — Backward compat A.7

`a7.test.sh` MUST stay 29/29 GREEN post-snapshot-regen.

##### NFR-T5BSD-005 — No regression on grpc-api

`grpc-api/Cargo.toml.tmpl` is **not touched** by this change.
`tower-http = { version = "0.6", features = ["trace"] }` already
declared inline in grpc-api/Cargo.toml.tmpl is benign and may be
deduped to `{ workspace = true }` in a future cleanup change
(out of scope here).

### Modified Requirements

##### MR-T5BSD-001 — `backend/Cargo.toml.tmpl::workspace.dependencies`

Three deps added per FR-T5BSD-001..003.

##### MR-T5BSD-002 — Snapshot tarballs

Regenerated per FR-T5BSD-051.

##### MR-T5BSD-003 — `forge-ci.yml` matrix

Gains one new step per FR-T5BSD-073.

### Removed Requirements

None.

---

## BDD Scenarios (Article II)

```gherkin
Feature: bin-server compiles on fresh scaffold (T5.1.E follow-on)

  Scenario: Adopter scaffolds the flagship and runs cargo check
    Given a fresh tmpdir (non-existent)
    When `forge init smoke_fsm --archetype full-stack-monorepo --org dev.forge.test --target <tmp>` runs
    Then exit code is 0
    And `<tmp>/backend/bin-server/Cargo.toml` exists with `name = "bin-server"`
    And `<tmp>/backend/Cargo.toml` lists `axum = "0.8"` in [workspace.dependencies]
    When the maintainer runs `cd <tmp>/backend && cargo check --workspace`
    Then exit code is 0
    And the error `unresolved import \`axum\`` is NOT present in stderr
    And the error `unresolved module \`tonic\`` is NOT present in stderr
```

---

## Constitution Compliance Verification

| Article            | Compliance                                                                  |
|--------------------|----------------------------------------------------------------------------|
| **I — TDD**        | Phase 1 writes harness with 9 L1 stubs RED ; RED witness already wild via `task smoke-with-toolchains`. Phase 2-4 ship fixes. |
| **II — BDD**       | Gherkin scenario above covers the adopter-facing flow.                     |
| **III — Specs**    | This file precedes any TOML edit.                                          |
| **III.4 — Anti-hallucination** | Q-001 / Q-002 in `open-questions.md` ; resolved by ADRs.        |
| **V — Audit**      | Every artefact tags `Audit: T5.1.E (t5-bin-server-deps)`.                  |
| **XII — Governance** | No standard moved ; no Article amended.                                 |

---

## Open Questions reference

See `open-questions.md` Q-001 / Q-002 — resolved by ADR-T5BSD-001..002 in
`design.md`.
