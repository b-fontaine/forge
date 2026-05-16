# Tasks: t5-bin-server-deps
<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: T5.1.E (Option B follow-on) -->

## Convention

- TDD immutable. Audit tag `[Story: FR-T5BSD-XXX]` on each task.
- `[P]` parallelizable in same phase.
- ADR-T5BSD-001..002 honored verbatim.

RED witness in the wild : `task smoke-with-toolchains` 2026-05-16
post-buffa-fix shows E0432/E0433 unresolved imports.

---

## Phase 1 — RED harness + CI registration

### T-HAR — Harness skeleton

- [ ] **T-HAR-001** — Create `.forge/scripts/tests/t5-bin-server.test.sh`
      with bash header (`#!/usr/bin/env bash`, `set -uo pipefail`),
      `_helpers.sh` source, `--level` parsing, audit comment
      `# Audit: T5.1.E (t5-bin-server-deps)`, manifest block,
      `print_summary` close-out.
      [Story: FR-T5BSD-070]
- [ ] **T-HAR-002** — Path constants :
      - `WORKSPACE_CARGO` → `.forge/templates/.../backend/Cargo.toml.tmpl`
      - `WORKSPACE_CARGO_MIRROR` → `cli/assets/.forge/templates/.../backend/Cargo.toml.tmpl`
      - `BIN_SERVER_CARGO` → `.forge/templates/.../backend/bin-server/Cargo.toml.tmpl`
      - `BIN_SERVER_CARGO_MIRROR` → `cli/assets/.forge/templates/.../backend/bin-server/Cargo.toml.tmpl`
      - `SNAPSHOT` → `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      [Story: FR-T5BSD-070]
- [ ] **T-HAR-003** — 9 L1 stubs returning `_not_implemented` per
      `design.md` § Harness L1 anchor list.
      [Story: FR-T5BSD-071]
- [ ] **T-HAR-004** [P] — 1 L2 stub
      `_test_t5bsd_l2_cargo_check_fresh_scaffold` ; skip-pass when
      `FORGE_T5BSD_LIVE` unset OR `cargo` absent.
      [Story: FR-T5BSD-072]
- [ ] **T-HAR-005** — Test runner + main.
      [Story: FR-T5BSD-071 / FR-T5BSD-072]
- [ ] **T-HAR-006** [P] — Register in `.github/workflows/forge-ci.yml`
      matrix after `t5-cargo.test.sh`. Verify file stays ≤ 300
      lines (NFR-T5BSD-003). If line budget exceeded, trim a
      pre-existing comment as documented in design.md.
      [Story: FR-T5BSD-073 / NFR-T5BSD-003]
- [ ] **T-HAR-007** — RED gate — `bash .forge/scripts/tests/t5-bin-server.test.sh --level 1`
      exits 1 with `Failed: 9 / Passed: 0`.

### Exit gate

Harness 9/9 FAIL. `forge-ci.yml` ≤ 300 lines.

---

## Phase 2 — Workspace deps + new bin-server manifest

### T-WS — Workspace Cargo.toml

- [ ] **T-WS-001** — RED witness for L1 anchors 1, 2, 3.
- [ ] **T-WS-002** — Edit
      `.forge/templates/archetypes/full-stack-monorepo/backend/Cargo.toml.tmpl`
      to add the three deps + the audit comment block per
      FR-T5BSD-001..004 :
      ```toml
      # ── HTTP / transport (T5.1.E follow-on, t5-bin-server-deps) ──
      # axum 0.8 is required by connectrpc 0.3.3 (declares `axum = "^0.8"`).
      axum = "0.8"
      tower-http = { version = "0.6", features = ["trace"] }
      http = "1"
      ```
      Insert immediately after the existing `# ── gRPC ──` block.
      [Story: FR-T5BSD-001 / FR-T5BSD-002 / FR-T5BSD-003 / FR-T5BSD-004]

### T-BIN — bin-server/Cargo.toml.tmpl

- [ ] **T-BIN-001** — RED witness for L1 anchors 4, 5, 6.
- [ ] **T-BIN-002** — Create
      `.forge/templates/archetypes/full-stack-monorepo/backend/bin-server/Cargo.toml.tmpl`
      with the canonical block per FR-T5BSD-020..025 :
      ```toml
      # <!-- Audit: T5.1.E (t5-bin-server-deps) -->
      #
      # bin-server — DI wiring + entrypoint for the flagship.
      # Hexagonal layer per backend/CLAUDE.md § Strict Dependency Rules :
      # no business logic, no domain types, no infrastructure imports.
      # Inherits deps via workspace ; declares grpc-api as a path dep.

      [package]
      name = "bin-server"
      version = "0.1.0"
      edition = "2024"

      [dependencies]
      # Path dep on the gRPC adapter crate (consumes transport_connect::into_router).
      grpc-api = { path = "../crates/grpc-api" }

      # Workspace deps (inherited from backend/Cargo.toml).
      tokio = { workspace = true }
      anyhow = { workspace = true }
      tracing = { workspace = true }
      tracing-subscriber = { workspace = true }
      tonic = { workspace = true }
      axum = { workspace = true }
      tower-http = { workspace = true }
      http = { workspace = true }
      ```
      [Story: FR-T5BSD-020..025]
- [ ] **T-BIN-003** — GREEN gate — anchors 1..6 GREEN. Harness
      reports `Failed: 3 / Passed: 6`.

### Exit gate

Source template files updated. L1 anchors 1..6 GREEN.

---

## Phase 3 — Mirror + snapshot regen

### T-MIR — Bundled mirror + snapshot

- [ ] **T-MIR-001** — RED witness for L1 anchors 7, 8.
- [ ] **T-MIR-002** — Run `cd cli && npm run bundle` to refresh
      mirrors. Verify both Cargo.toml.tmpl files are byte-identical
      between source + mirror via `diff -q`.
      [Story: FR-T5BSD-050]
- [ ] **T-MIR-003** — Regenerate snapshot tarballs :
      ```bash
      rm -f .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz
      bash bin/forge-snapshot.sh build full-stack-monorepo 1.0.0
      cd cli && npm run bundle
      diff -q .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz \
              cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz
      ```
      [Story: FR-T5BSD-051]
- [ ] **T-MIR-004** [P] — Run `bash .forge/scripts/tests/a7.test.sh`
      to confirm A.7 backward-compat preserved (expected 29/29).
      [Story: NFR-T5BSD-004]
- [ ] **T-MIR-005** — GREEN gate — anchors 7, 8 GREEN. Harness
      reports `Failed: 1 / Passed: 8`.

### Exit gate

Mirrors byte-identical, snapshot embeds the new bin-server
manifest. A.7 29/29 GREEN preserved.

---

## Phase 4 — Live cargo check (validation) + docs

### T-LIVE — Live cargo check end-to-end

- [ ] **T-LIVE-001** — Run live smoke against fresh scaffold :
      ```bash
      tmp=$(mktemp -d /tmp/forge-t5bsd-XXXXXX) && rm -rf "$tmp"
      node cli/dist/index.js init smoke_t5bsd \
        --archetype full-stack-monorepo --org dev.forge.test --target "$tmp"
      cd "$tmp/backend" && cargo check --workspace
      ```
      Expected : exit 0. The five E0432/E0433 errors from the
      RED witness MUST be gone.
      [Story: BDD scenario / FR-T5BSD-072 manual]
- [ ] **T-LIVE-002** — Optional : run
      `FORGE_T5BSD_LIVE=1 bash .forge/scripts/tests/t5-bin-server.test.sh --level 1,2`
      to exercise L2 as well.
      [Story: FR-T5BSD-072]

### T-DOC — Documentation

- [ ] **T-DOC-001** — RED witness for L1 anchor 9.
- [ ] **T-DOC-002** — Add `### Fixed — bin-server deps + workspace
      HTTP deps (T5.1.E follow-on, t5-bin-server-deps)` to
      `CHANGELOG.md [Unreleased]` per FR-T5BSD-100.
      [Story: FR-T5BSD-100]
- [ ] **T-DOC-003** [P] — Plan inventory : add
      `| t5-bin-server-deps | archived | T5.1.E (bin-server deps) |`
      ; bump 26 → 27.
      [Story: FR-T5BSD-101]
- [ ] **T-DOC-004** — GREEN gate — anchor 9 GREEN. All 9 L1 GREEN.

### T-VER — Final gates

- [ ] **T-VER-001** — `bash t5-bin-server.test.sh --level 1` →
      `Failed: 0 / Passed: 9`.
- [ ] **T-VER-002** [P] — `bash verify.sh` → RESULT: PASS.
- [ ] **T-VER-003** [P] — `bash constitution-linter.sh` → OVERALL:
      PASS.
- [ ] **T-VER-004** [P] — `bash validate-standards-yaml.sh` →
      STD-PASS.
- [ ] **T-VER-005** [P] — `bash validate-change-yaml.sh
      .forge/changes/t5-bin-server-deps/.forge.yaml` → exit 0.
- [ ] **T-VER-006** — Inline `[NEEDS CLARIFICATION:]` gate :
      `grep -n '\[NEEDS CLARIFICATION:' .forge/changes/t5-bin-server-deps/*.md`
      finds no real markers.
- [ ] **T-VER-007** [P] — `task smoke-with-toolchains` GREEN on
      the full-stack-monorepo cargo check leg. (mobile-only flutter
      analyze still RED — T5.3 territory.)
- [ ] **T-VER-008** — Update `.forge.yaml` timeline :
      `specified/designed/planned/implemented: 2026-05-16`.

### Exit gate

All 9 L1 GREEN. Live `cargo check` GREEN. Forge gates preserved.
T5.1.E RED witness CLOSED end-to-end for the full-stack-monorepo
cargo check leg.

---

## Sequencing summary

```
Phase 1 — RED + CI                       (9 L1 FAIL → harness ready)
Phase 2 — workspace deps + bin-server    (6/9 GREEN)
Phase 3 — mirror + snapshot regen        (8/9 GREEN ; A.7 preserved)
Phase 4 — live cargo check + docs        (9/9 GREEN)
```

---

## Post-archive release wiring

After `cli-trust-harness` + `t5-cargo-pin-refresh` + this change
are all archived :

1. Bump VERSION 0.3.2 → 0.3.3.
2. Bump `cli/package.json::version`.
3. Seal CHANGELOG `## [Unreleased]` → `## [0.3.3] — 2026-05-XX`.
4. PR main (direct, additive per `no_pr_before_t2_p1_p2.md`).
5. `scripts/release.sh --version 0.3.3 --otp <…>`. The
   `prepublishOnly` gate (T5.1.C) exercises the smoke on the
   real tarball ; both cargo + bin-server deps now resolve.
