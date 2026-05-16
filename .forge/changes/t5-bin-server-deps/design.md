# Design: t5-bin-server-deps
<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: T5.1.E (Option B follow-on to t5-cargo-pin-refresh) -->

> Read alongside `specs.md` (FR-T5BSD-* / NFR-T5BSD-*) and
> `open-questions.md` (Q-001 / Q-002). This document locks the
> implementation strategy and resolves the two open questions via
> ADR-T5BSD-001..002.

## Architecture Decisions

### ADR-T5BSD-001 — Pin `axum = "0.8"` in workspace deps (not 0.7 as the example carries) (resolves Q-001)

**Context** : Q-001 weighed which axum version to declare in
`backend/Cargo.toml.tmpl::workspace.dependencies` :

- **Option A** — `axum = "0.7"` (mirror the existing
  `examples/forge-fsm-example/backend/Cargo.toml`).
- **Option B** — `axum = "0.8"` (satisfy `connectrpc 0.3.3`'s
  `axum = "^0.8"` dep declaration).
- **Option C** — Don't declare `axum` in workspace ; let
  `bin-server` declare it locally as a direct dep at version 0.8.

**Decision** : **Option B — `axum = "0.8"`**.

**Rationale** :

1. **Consistency with `connectrpc 0.3.3`** : the change
   `t5-connect-codegen` (kept by `t5-cargo-pin-refresh`) pinned
   `connectrpc = "=0.3.3"` in `grpc-api/Cargo.toml.tmpl`.
   `connectrpc 0.3.3` declares `axum = "^0.8"` as a normal
   dependency (verified via crates.io REST API 2026-05-16). If the
   workspace declares `axum = "0.7"`, Cargo finds two incompatible
   constraints — `^0.8` from connectrpc, `^0.7` from workspace —
   and fails to resolve. Option A is therefore not viable.
2. **The example is stale, not authoritative** : the
   `examples/forge-fsm-example/backend/` tree was scaffolded
   **before** `t5-connect-codegen` landed and was never
   regenerated. It carries `axum = "0.7"` AND does not pull in
   `connectrpc` (verified : `grep "buffa\|connectrpc"
   examples/.../grpc-api/Cargo.toml` returns nothing). The example
   builds today because it is internally consistent, not because
   `0.7` is the right version for the **template**. The template
   pulls in `connectrpc 0.3.3` → must use `axum 0.8`.
3. **Option C complicates workspace hygiene** : the canonical
   `backend/CLAUDE.md` § "Strict Dependency Rules" prescribes
   workspace-scoped pins so every crate inherits via
   `{ workspace = true }`. Declaring axum locally in bin-server
   only is a divergence from that pattern. Keep it in workspace
   deps where it belongs.

**Consequences** :

- ✅ `cargo check --workspace` resolves consistently for any new
  scaffold.
- ✅ The future Phase B mirror (when the example is regenerated)
  will pick up `axum = "0.8"` and stay consistent with the
  template.
- ⚠️ The current `forge-fsm-example/backend/Cargo.toml` will be
  out of sync with the template (axum 0.7 vs 0.8). This is
  intentional — the example will be regenerated as part of T5.3
  (`t5-otel-dartastic-realign`) or a later refresh, which is when
  the realignment happens cohesively.

**Constitution Compliance** : Article III.4 (anti-hallucination
— the decision is verified against crates.io REST API, not
guessed) ; Article XII (governance — no standard touched, no
amendment).

---

### ADR-T5BSD-002 — `bin-server/Cargo.toml.tmpl` mirrors the example manifest pattern (resolves Q-002)

**Context** : Q-002 weighed three layouts for the new
`bin-server/Cargo.toml.tmpl` :

- **Option A** — Mirror the existing
  `examples/forge-fsm-example/backend/bin-server/Cargo.toml`
  shape : `[package]` block + `[dependencies]` block consuming
  workspace deps via `{ workspace = true }` + a path dep on
  `grpc-api`.
- **Option B** — Self-contained manifest with every version
  declared inline (no workspace inheritance).
- **Option C** — `[bin]` table embedded in `crates/grpc-api/Cargo.toml.tmpl`
  (declare bin-server as a binary target of grpc-api instead of
  its own crate).

**Decision** : **Option A — mirror the example pattern**.

**Rationale** :

1. **Backend convention is workspace-inherited deps** —
   `backend/CLAUDE.md` § "Strict Dependency Rules" is explicit :
   crates inherit via `{ workspace = true }` ; only deps absent
   from `[workspace.dependencies]` are declared locally. The
   example follows this verbatim, proven to build.
2. **Option B (self-contained)** would duplicate version pins
   between bin-server and the rest of the workspace, creating
   the exact drift class that ADR-T5-001 (Anthropic OSS pedigree
   waiver) and ADR-T5-002 (exact pins for reproducible builds)
   explicitly fight against.
3. **Option C (embed in grpc-api)** breaks the canonical 5-crate
   hexagonal layout documented in `backend/CLAUDE.md`. bin-server
   is structurally its own crate (DI wiring + main entrypoint).
   `workspace.members` lists it explicitly. Embedding would
   require reworking other deliverables (Article VII.3 layout,
   verify.sh hexagonal-layout check). Out of proportion to the
   bug being fixed.

**Concrete manifest** (final wording at implementation time, see
proposal.md § T5BSD-B for the verbatim block).

**Consequences** :

- ✅ Conforms to backend/CLAUDE.md hexagonal rules verbatim.
- ✅ Future workspace deps additions auto-propagate to bin-server.
- ✅ Article VII.3 5-crate layout preserved.

**Constitution Compliance** : Article VII.3 (Rust architecture —
hexagonal workspace, 5-crate layout — bin-server stays its own
crate) ; Article V (audit trail — the new file carries
`# <!-- Audit: T5.1.E (t5-bin-server-deps) -->`).

---

## Technical Design

### Edit summary by file

```
.forge/templates/archetypes/full-stack-monorepo/backend/
├── Cargo.toml.tmpl                           # +3 workspace deps (axum, tower-http, http)
└── bin-server/
    ├── Cargo.toml.tmpl                       # NEW
    └── src/main.rs.tmpl                      # UNCHANGED (already correct)

cli/assets/.forge/templates/.../              # mirrors via `npm run bundle`
.forge/scaffold-snapshots/.../1.0.0.tar.gz    # regenerate via bin/forge-snapshot.sh
cli/assets/.forge/scaffold-snapshots/.../     # mirror

.forge/scripts/tests/t5-bin-server.test.sh    # NEW harness ≥ 7 L1 + 1 L2
.github/workflows/forge-ci.yml                 # +1 step

CHANGELOG.md                                   # [Unreleased] section append
docs/new-archetypes-plan.md                     # §0.1 + inventory
```

### Harness L1 anchor list (FR-T5BSD-071)

| ID                                                   | Mechanism                                                                                                                            |
|------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| `_test_t5bsd_l1_001_workspace_axum`                  | `grep -F 'axum = "0.8"' $WORKSPACE_CARGO`                                                                                            |
| `_test_t5bsd_l1_002_workspace_tower_http`            | `grep -F 'tower-http = { version = "0.6", features = ["trace"] }' $WORKSPACE_CARGO`                                                  |
| `_test_t5bsd_l1_003_workspace_http`                  | `grep -F 'http = "1"' $WORKSPACE_CARGO`                                                                                              |
| `_test_t5bsd_l1_004_bin_server_manifest_exists`      | `[ -f $BIN_SERVER_CARGO ]` + audit comment grep                                                                                       |
| `_test_t5bsd_l1_005_bin_server_grpc_api_path_dep`    | `grep -F 'grpc-api = { path = "../crates/grpc-api" }' $BIN_SERVER_CARGO`                                                              |
| `_test_t5bsd_l1_006_bin_server_workspace_deps`       | For each of the 8 deps (tokio / anyhow / tracing / tracing-subscriber / tonic / axum / tower-http / http), `grep` finds `<dep> = { workspace = true }` |
| `_test_t5bsd_l1_007_mirror_byte_identity`            | `diff -q $WORKSPACE_CARGO $WORKSPACE_CARGO_MIRROR` exit 0 AND same for bin-server                                                    |
| `_test_t5bsd_l1_008_snapshot_content`                | Extract snapshot tarball ; find `bin-server/Cargo.toml.tmpl` ; grep `name = "bin-server"`                                              |
| `_test_t5bsd_l1_009_changelog_entry`                 | `awk '/^## \[Unreleased\]/{f=1;next} /^## \[/{f=0} f' CHANGELOG.md | grep -F 't5-bin-server-deps'`                                    |

### L2 opt-in fixture (FR-T5BSD-072)

```bash
_test_t5bsd_l2_cargo_check_fresh_scaffold() {
  if [ "${FORGE_T5BSD_LIVE:-0}" != "1" ]; then
    echo "    skipped (FORGE_T5BSD_LIVE unset)" >&2; return 0
  fi
  command -v cargo > /dev/null 2>&1 || {
    echo "    skipped (cargo absent on PATH)" >&2; return 0
  }
  local tmp
  tmp=$(mktemp -d "/tmp/forge-t5bsd-XXXXXX")
  rm -rf "$tmp"  # exercise mkdir -p
  if ! node "$FORGE_ROOT_REAL/cli/dist/index.js" init smoke_t5bsd \
      --archetype full-stack-monorepo --org dev.forge.test --target "$tmp"; then
    echo "    forge init failed" >&2
    rm -rf "$tmp"; return 1
  fi
  if ! (cd "$tmp/backend" && cargo check --workspace 2>&1); then
    echo "    cargo check --workspace failed on fresh scaffold" >&2
    rm -rf "$tmp"; return 1
  fi
  rm -rf "$tmp"
}
```

### Snapshot regeneration

Same recipe as `t5-cargo-pin-refresh` :

```bash
rm -f .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz
bash bin/forge-snapshot.sh build full-stack-monorepo 1.0.0
cd cli && npm run bundle
diff -q .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz \
        cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz
```

### CI matrix entry

Insert after `t5-cargo.test.sh` :

```yaml
- name: t5-bin-server.test.sh
  # T5.1.E bin-server deps harness. L1-only by default ; L2
  # (live cargo check fresh scaffold) is opt-in via FORGE_T5BSD_LIVE=1.
  run: bash .forge/scripts/tests/t5-bin-server.test.sh --level 1
```

`forge-ci.yml` growth budget : ~5 lines → 302 total. **Close to the
300-line NFR-CI-002 budget**. Plan B if exceeded : promote one of
the existing harness comments to a `name:` line + drop comments
to stay under. Phase 4 of `tasks.md` includes a line-budget guard.

---

## Migration / rollout

- **Adopters with pre-fix scaffolds** : their tree has `bin-server/`
  with `src/main.rs` but no `Cargo.toml`. Their `cargo build` was
  failing today (per the T5.1 RED witness). `forge upgrade` will
  3-way merge the new `bin-server/Cargo.toml` (or simply add it
  since it's a new file). They run `cargo check` again post-upgrade
  and the build resolves.
- **Fresh adopters** : their `forge init` produces a buildable
  scaffold for the first time since `t5-connect-codegen` landed.
- **Maintainer** : after both `t5-cargo-pin-refresh` AND
  `t5-bin-server-deps` archive, `task smoke-with-toolchains` GREEN
  on the full-stack-monorepo cargo check leg. mobile-only flutter
  analyze stays RED (T5.3 territory).

---

## Risks + mitigations

| Risk                                                            | Probability | Impact | Mitigation                                                                  |
|-----------------------------------------------------------------|-------------|--------|-----------------------------------------------------------------------------|
| `axum 0.8` and `tower-http 0.6` are version-incompatible       | Very low    | High   | Tested by L2 opt-in (`cargo check --workspace` actually compiles)            |
| Adding `bin-server/Cargo.toml.tmpl` confuses the existing scaffolder | Low         | Medium | A.7 `forge upgrade` 3-way merge handles new files cleanly ; `a7.test.sh` GREEN |
| Snapshot regen breaks A.7 backward compat                       | Very low    | High   | T-VER runs `a7.test.sh` ; 29/29 GREEN required                              |
| `forge-ci.yml` exceeds 300-line budget                          | Low         | Low    | Phase 4 guard ; trim a comment if needed (acceptable workaround)             |

---

## ADR summary table

| ADR ID         | Question                                                | Decision                                                                              |
|----------------|---------------------------------------------------------|---------------------------------------------------------------------------------------|
| ADR-T5BSD-001  | Q-001 — axum version in workspace deps                  | `axum = "0.8"` (matches `connectrpc 0.3.3` constraint, not the stale example's 0.7)   |
| ADR-T5BSD-002  | Q-002 — bin-server manifest layout                      | Mirror the example pattern : workspace-inherited deps + path dep on grpc-api          |
