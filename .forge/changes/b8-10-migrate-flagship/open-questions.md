# Open Questions — b8-10-migrate-flagship

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
Resolutions are made at /forge:design by an INDEPENDENT reviewer + the
maintainer, NOT self-approved. All author-phase leanings are recorded below
as candidate positions only; they do not constitute decisions.
-->

## Resolution Log (/forge:design, 2026-06-03)

All five questions resolved at /forge:design (maintainer decisions, encoded in
`design.md` ADR-B810-001..005). The author flips them to answered here; an
INDEPENDENT reviewer ratifies before `/forge:plan` (NOT self-approved).
Maintainer decision pending INDEPENDENT reviewer ratification before /forge:plan.

This is **pure tooling** — no external version pins. The verify-then-pin
equivalent is the LIVE on-disk re-read of `bin/forge-upgrade.sh` internals, the
2.0.0 template-set, and the frozen snapshot (evidence.md P-01..P-27, read
2026-06-03; authoritative). The `_a7_*` inventory + 2.0.0 set are re-read LIVE at
`/forge:implement` before any script line is authored (b8-coroot lesson).

| Q | Decision | ADR |
|---|----------|-----|
| Q-001 | **(a) doc-only** — `docs/MIGRATIONS.md` documents `bash bin/forge-migrate-flagship.sh --target . --dry-run`; NO `cli/src/commands/migrate-flagship.ts`. A `forge migrate-flagship` TS subcommand is DEFERRED to **B.8.15** (the `forge upgrade` matrix brick). Mirrors the doc-only `bin/` posture of `bin/forge-sbom.sh` / `bundle.sh` (P-20). | ADR-B810-003 |
| Q-002 | **ALIGN to A.7 `0/2/5/7/8`** (REFINES the spec lean `0/1/2/7`) — live re-read (P-01) shows A.7 uses `0`/`2`/`5`/`7`/`8` and **never `1`**; Phase 2 delegates the merge to `_a7_three_way_merge` (conflicts surface as exit-8) and depends on `git`/`python3`/`tar` (exit-5), so aligning keeps the two scripts' exit semantics identical. Flags: `--target`(req) `--phase <0\|1\|2\|all>` `--dry-run` `--force` `--rollback` `--help`. **`--rollback`/`--phase` mutually exclusive** (full-snapshot restore only; `--phase` ignored + warned); `--rollback --dry-run` always safe (exit 0). | ADR-B810-002 |
| Q-003 | **(a) reuse `upgrade_history` with `kind: flagship-migration`** — least-invasive WRAP: call the sourced `_a7_append_upgrade_history` (P-08, identity fields frozen) then a thin post-append python-inline (`_b810_tag_last_history_kind`) stamps `kind` onto the last entry. **Does NOT edit the A.7 helper** (`forge-upgrade.sh` is an `owned:` file, P-21, byte-unchanged). No parallel `migration_history` block. | ADR-B810-004 |
| Q-004 | **(a) SOURCE forge-upgrade.sh, reuse `_a7_*`** — `_a7_main` is guarded to direct-invocation only (P-03), so sourcing is side-effect-free. Reuse `_a7_check_force_clean_git` (Phase 0), `_a7_classify` + `_a7_three_way_merge` (Phase 2 per-file). **Merge RIGHT = the rendered 2.0.0 template-set** (`.forge/templates/.../2.0.0/`, P-13, 27 files); **BASE = frozen `1.0.0.tar.gz`** (P-11); RIGHT relpaths mapped by stripping `2.0.0/` + schema layer paths (P-16) — `_a7_resolve_owned_paths` NOT used for RIGHT selection (resolves the framework's own `.forge/templates/**` mirror, P-21 — would mis-target). **DELIBERATELY NOT calling `_a7_check_version_compat`** (P-02 — the guard that delegated here). One merge engine, no duplication. | ADR-B810-001 |
| Q-005 | **(a) document-only** — Phase 2 applies the Envoy Gateway overlay (6 `2.0.0/infra/k8s/envoy-gateway/` files, P-13) but generates NO per-route canary weights; prints canary-by-route Kong→Envoy guidance in Phase 2 stdout + `docs/MIGRATIONS.md` manual runbook. Auto-wiring without Envoy SecurityPolicy/JWT OIDC (B.8.12) would emit an invalid intermediate config. No auto-wiring. | ADR-B810-005 |

### specs.md `[NEEDS CLARIFICATION]` / Q→ADR anchor map

The design-deferred anchors in `specs.md` map to the ADRs below. **specs.md is NOT
edited now** — the marker-neutralization happens at `/forge:implement` before the
status flip (b8-9 precedent). This table records the mapping for the implementer.

| specs.md anchor | FR / location | Resolved by |
|-----------------|---------------|-------------|
| `(Q-002 → ADR-B810-002)` exit envelope | FR-B810-005 (L152-161); Anti-Halluc. L706-707 | ADR-B810-002 — `0/2/5/7/8` (refines `0/1/2/7`) |
| `(Q-002 → ADR-B810-002)` `--rollback`/`--phase` | FR-B810-004 (L147); FR-B810-040 (L354) | ADR-B810-002 — mutually exclusive |
| `(Q-004 → ADR-B810-001)` overlay engine | FR-B810-033 (L306-318); Anti-Halluc. L702 | ADR-B810-001 — source + reuse `_a7_*` |
| `(Q-004 → ADR-B810-001)` Phase 1 detection predicate | FR-B810-020 (L243-252); Anti-Halluc. L732-735 | ADR-B810-001 — assert-or-apply via `_a7_classify` |
| `(Q-004 → ADR-B810-001)` per-delta file set | FR-B810-030 (L272-283) | ADR-B810-001 — 27-file 2.0.0 RIGHT walk (P-13) |
| `(Q-003 → ADR-B810-004)` ledger `kind` marker | FR-B810-060 (L444-454); Anti-Halluc. L708-711 | ADR-B810-004 — wrap `_a7_append_upgrade_history` |
| `(Q-005 → ADR-B810-005)` canary | FR-B810-034 (L320-327); Anti-Halluc. L729-731 | ADR-B810-005 — document-only |
| `(Q-001 → ADR-B810-003)` CLI surface | FR-B810-053 (L424-431); FR-B810-050(g) (L403) | ADR-B810-003 — doc-only; TS deferred B.8.15 |
| `(Q-002 → ADR-B810-002)` rollback restore scope | FR-B810-040 (L349-357) | ADR-B810-002 — full-tree restore from frozen snapshot |

---

## Q-001: CLI surface — doc-only invocation vs `forge migrate-flagship` TS subcommand

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B810-003 seed), `specs.md` FR-B810-053
- **Raised on**: 2026-06-03
- **Raised by**: author (b8-10 specify pass)
- **Resolves at**: `/forge:design` → ADR-B810-003

### Context

Today the exit-7 `[NEEDS MIGRATION: from 1.0.0 to 2.0.0]` message from
`forge-upgrade.sh` (line 139) directs adopters to `docs/MIGRATIONS.md`. The
question is whether B.8.10 should also wire a `forge migrate-flagship` TS
subcommand in `cli/src/commands/` (following the `cli/src/commands/upgrade.ts`
thin-wrapper dispatch pattern observed in A.7), or whether the MIGRATIONS.md
section simply documents:
```
bash bin/forge-migrate-flagship.sh --target <project-dir> --dry-run
```
as the canonical invocation.

### Options

- **(a) Doc-only (lean here)**: MIGRATIONS.md documents `bash
  bin/forge-migrate-flagship.sh --target <dir>` as the invocation. No TS
  commander registration in this brick. A `forge migrate-flagship` subcommand
  is deferred to B.8.14/B.8.15 when the CLI surface is stabilised. This is
  the smallest viable change and avoids CLI churn before the 2.0.0 archetype
  is scaffoldable.
- **(b) TS subcommand wired**: Add `cli/src/commands/migrate-flagship.ts`
  following the `upgrade.ts` pattern; register in commander. Costs ~1 TS file
  + a test; keeps CLI surface consistent with `forge upgrade`. Only viable if
  the TS wrapper is genuinely trivial (shell-out to the bash script).

**Lean here (author position)**: **(a) doc-only** — the migration script is an
opt-in power-user tool not a day-to-day CLI command; doc-only minimises scope
and CLI churn; the TS subcommand can follow at B.8.14 when `forge upgrade`
must also be updated.

### Resolution

- **Resolved on**: 2026-06-03 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered).
- **Decision**: **(a) doc-only for B.8.10**. `docs/MIGRATIONS.md` documents
  `bash bin/forge-migrate-flagship.sh --target . --dry-run` as the canonical
  invocation; NO `cli/src/commands/migrate-flagship.ts`, no commander
  registration. The `forge migrate-flagship` TS subcommand is DEFERRED to
  **B.8.15** (the `forge upgrade` matrix brick), where the CLI surface is
  stabilised alongside the `forge upgrade` subcommand it sits next to. The
  exit-7 `[NEEDS MIGRATION:]` message (already pointing at `docs/MIGRATIONS.md`,
  evidence.md P-02) is the discovery path. Mirrors the doc-only `bin/` posture of
  `bin/forge-sbom.sh` / `bundle.sh` (P-20). No fabricated TS surface (Article III.4).
- **Rationale**: (ADR-B810-003; evidence.md P-02, P-20.)

---

## Q-002: Exit-code envelope + flag interactions — final values and `--rollback` / `--phase` interaction

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B810-002 seed), `specs.md` FR-B810-005 / FR-B810-004
- **Raised on**: 2026-06-03
- **Raised by**: author (b8-10 specify pass)
- **Resolves at**: `/forge:design` → ADR-B810-002

### Context

Two sub-questions:
1. **Exit-code values**: The script needs an exit-code contract. The A.7
   precedent uses `0/2/5/7/8`. B.8.10 can either mirror A.7 exactly (adds
   `5` for missing tools, `8` for conflicts) or define a simpler `0/1/2/7`
   envelope (1 = migration error, no `5`/`8` needed if the script delegates
   conflict handling to forge-upgrade.sh).
2. **`--rollback` + `--phase` interaction**: Are `--rollback` and `--phase`
   mutually exclusive (rollback exits early, phase is ignored), or does
   `--phase` select which phase's overlay to roll back? Is `--rollback
   --dry-run` always safe (lean: yes)?

### Options

Sub-question 1 — exit codes:
- **(a) `0/1/2/7` (lean here)**: `0` success, `1` migration/apply error,
  `2` usage error, `7` precondition not met. Simpler; conflicts are surfaced
  as exit-1 from the delegated forge-upgrade machinery.
- **(b) Mirror A.7 `0/2/5/7/8`**: adds `5` (missing tool) and `8` (unresolved
  conflicts). More granular; consistent with forge-upgrade.sh exit semantics.

Sub-question 2 — `--rollback` / `--phase`:
- **(a) Mutually exclusive (lean here)**: `--rollback` ignores `--phase`;
  emits a warning if both are passed; always restores the full 1.0.0 snapshot.
- **(b) Phase-scoped rollback**: `--rollback --phase 2` only undoes Phase 2
  overlays. More surgical but requires tracking what Phase 2 wrote.

**Lean here (author position)**:
- Exit codes: **(a) 0/1/2/7** — simpler and sufficient for an orchestrator
  that delegates the merge to forge-upgrade.sh.
- `--rollback` / `--phase`: **(a) mutually exclusive** — full-snapshot restore
  is the only safe semantics before B.8.13's runbook defines partial rollback.

### Resolution

- **Resolved on**: 2026-06-03 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered).
- **Decision (sub-1 — exit codes)**: **ALIGN to A.7 `0/2/5/7/8`** — this
  **refines** the author lean `0/1/2/7`. Live re-read of the `forge-upgrade.sh`
  docblock (evidence.md P-01) shows A.7 uses `0` success / `2` usage / `5` missing
  tool / `7` precondition / `8` conflicts and **never uses `1`**. Because Phase 2
  delegates the merge to the sourced `_a7_three_way_merge` (which surfaces
  conflicts as `_a7_main`'s exit-8, P-05) and depends on the same tools
  (`git`/`python3`/`tar`, exit-5), aligning keeps the two scripts' exit semantics
  identical for an adopter who runs `forge upgrade` then `forge-migrate-flagship`.
  Mapping: `0` success / `2` usage / `5` missing tool / `7` precondition
  (non-1.0.0 target, dirty git w/o `--force`, snapshot sha256 mismatch) / `8`
  overlay conflicts w/o `--force`.
- **Decision (sub-2 — `--rollback`/`--phase`)**: **(a) mutually exclusive** —
  `--rollback` restores the FULL frozen snapshot and ignores `--phase` (warns on
  stderr if both passed); phase-scoped rollback is deferred to B.8.13.
  `--rollback --dry-run` is always safe (prints the restore plan, exit 0).
- **Flags**: `--target`(req) `--phase <0|1|2|all>` (default `all`) `--dry-run`
  (default-safe) `--force` `--rollback` `--help`/`-h`.
- **Rationale**: (ADR-B810-002; evidence.md P-01, P-05, P-09.) This is a deliberate
  design refinement of the spec lean, not a contradiction.

---

## Q-003: Ledger — reuse `upgrade_history` with `kind` marker vs parallel `migration_history` block

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B810-004 seed), `specs.md` FR-B810-060
- **Raised on**: 2026-06-03
- **Raised by**: author (b8-10 specify pass)
- **Resolves at**: `/forge:design` → ADR-B810-004

### Context

The A.7 ledger (`_a7_append_upgrade_history`) appends to `upgrade_history` in
the target's `.forge/scaffold-manifest.yaml`. B.8.10 needs to record the
migration event. The question is whether to:
- Reuse the same `upgrade_history` list with an added `kind` field, OR
- Introduce a separate `migration_history` list alongside `upgrade_history`.

The trade-off: reuse keeps the manifest schema stable and the tooling simpler;
a separate block makes it easier for tooling to distinguish upgrade events from
migration events without inspecting the `kind` field.

### Options

- **(a) Reuse `upgrade_history` with `kind: flagship-migration` (lean here)**:
  Append to the existing list; add `kind: flagship-migration` to the entry to
  distinguish it from a standard `forge upgrade` history entry. The A.7 Python
  inline block shape is reused as-is (with the extra field). Minimal manifest
  schema change; `upgrade_history` consumers still see the full history in order.
- **(b) Parallel `migration_history` block**: Add a `migration_history:` key
  to the manifest alongside `upgrade_history`. Cleaner separation; cost is a
  new key in the manifest schema that `a7.test.sh` and other consumers do not
  currently expect.

**Lean here (author position)**: **(a) reuse `upgrade_history`** — single
ledger, append-only, minimal manifest schema change, reuses the A.7 Python
inline block pattern directly. The `kind` marker is sufficient for tooling
discrimination.

### Resolution

- **Resolved on**: 2026-06-03 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered).
- **Decision**: **(a) reuse `upgrade_history` with `kind: flagship-migration`**,
  via the **least-invasive wrap**. The script calls the sourced
  `_a7_append_upgrade_history` (evidence.md P-08 signature: appends the standard
  entry — `date`/`from_version`/`to_version`/`from_template_set_sha`/
  `to_template_set_sha`/`counts`/`cli_version` — and freezes identity fields), then
  runs a thin post-append python-inline wrapper `_b810_tag_last_history_kind
  <manifest>` that re-opens the manifest, stamps `kind: flagship-migration` onto the
  LAST entry, and `yaml.safe_dump`s it back (same dump shape as P-08). **This does
  NOT edit the A.7 helper** — `bin/forge-upgrade.sh` is an `owned:` framework file
  (P-21) and stays byte-unchanged. No parallel `migration_history` key (which
  `a7.test.sh` does not expect). Only on a real Phase 2 apply (not `--dry-run`); the
  wrapper overrides `date` deterministically when `SOURCE_DATE_EPOCH` is set (P-19).
- **Rationale**: (ADR-B810-004; evidence.md P-08, P-19, P-21.)

---

## Q-004: Overlay engine — delegate to `forge-upgrade.sh` machinery vs dedicated render path; selection of the 2.0.0 template set as merge RIGHT

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B810-001 seed), `specs.md` FR-B810-033
- **Raised on**: 2026-06-03
- **Raised by**: author (b8-10 specify pass)
- **Resolves at**: `/forge:design` → ADR-B810-001

### Context

The core implementation question. `forge-upgrade.sh` implements a 3-way merge
engine (`_a7_classify`, `_a7_three_way_merge`, `_a7_resolve_owned_paths`,
snapshot-BASE recovery). The migration script could:
- **Shell out to / source `forge-upgrade.sh`** and pass it the 2.0.0 template
  directory as the RIGHT side and the frozen 1.0.0 snapshot as the BASE,
  delegating the per-file merge logic entirely.
- **Implement a dedicated overlay-render path** that copies/merges the 2.0.0
  template files directly without using the A.7 machinery.

Two sub-problems:
1. **How the migration script locates the 2.0.0 template set** (the merge
   RIGHT): by `FORGE_REPO_ROOT` detection (as forge-upgrade.sh does), by a
   `--forge-root` flag, or by convention (script is co-located in `bin/`).
2. **Whether `_a7_resolve_owned_paths` is usable for the migration context**:
   the function resolves paths from `framework-owned-paths.yml`; the migration
   applies 2.0.0-specific overlays that may not be in that file yet.

### Options

- **(a) Delegate to forge-upgrade.sh machinery (lean here)**: Source
  `forge-upgrade.sh` (or shell out) and call the `_a7_*` functions with the
  2.0.0 template set as RIGHT and the frozen snapshot as BASE. Avoids
  duplicating `git merge-file` logic. Requires deciding how the 2.0.0
  template set path is passed (likely via `FORGE_REPO_ROOT` which
  forge-upgrade.sh already detects from `BASH_SOURCE`).
- **(b) Dedicated overlay-render path**: The migration script directly copies
  the 2.0.0 template files into the target using a simpler
  overlay-only approach (no 3-way merge for files not in the 1.0.0 base).
  Simpler to implement but misses user customisations in existing files.
- **(c) Hybrid**: delegate 3-way merge for files that exist in both 1.0.0 and
  2.0.0 (using forge-upgrade.sh); copy-new for files that only exist in 2.0.0.

**Lean here (author position)**: **(a) delegate** — avoids a second merge
engine; the 3-way merge handles user customisations correctly; the
`FORGE_REPO_ROOT` detection in `forge-upgrade.sh` already works from
`bin/` co-location. The design must confirm `_a7_resolve_owned_paths` covers
the 2.0.0 overlay paths or extend `framework-owned-paths.yml` if needed.

### Resolution

- **Resolved on**: 2026-06-03 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered).
- **Decision**: **(a) SOURCE `forge-upgrade.sh` and reuse the `_a7_*` library**.
  `_a7_main` runs only on direct invocation (`[[ "${BASH_SOURCE[0]}" == "${0}" ]]`,
  evidence.md P-03), so sourcing is side-effect-free. The script reuses
  `_a7_check_force_clean_git` (Phase 0 gate, P-04), `_a7_classify` (per-file verdict,
  P-06), and `_a7_three_way_merge` (`git merge-file --diff3`, P-05) — **one merge
  engine, no duplication** (FR-B810-033).
  - **Merge RIGHT = the rendered 2.0.0 template-set** at
    `.forge/templates/archetypes/full-stack-monorepo/2.0.0/` (P-13, the 27-file set,
    zero DBOS per P-14). The script walks that root and maps each relpath to the
    target by **stripping the `2.0.0/` prefix + applying the schema layer paths**
    (P-16: `backend/`, `frontend/`, `infra/`, `shared/`).
  - **Merge BASE = the frozen `1.0.0.tar.gz`** (P-11) extracted into a `mktemp -d`
    (same recovery shape as `_a7_main`, P-10).
  - `_a7_resolve_owned_paths` is **NOT** used for RIGHT selection — it resolves the
    framework's own `.forge/templates/**` mirror via `framework-owned-paths.yml`
    (P-07/P-21), which would mis-target the overlay surface. (Sub-problem 2 of Q-004
    resolved: no `framework-owned-paths.yml` extension is needed.)
  - **DELIBERATELY NOT calling `_a7_check_version_compat`** (P-02) — that major-diff
    guard is exactly what aborted `forge upgrade` and delegated here; re-calling it
    would re-abort with exit-7. Phase 0 asserts `archetype_version == 1.0.0` directly
    off the manifest (P-18) instead.
- **Rationale**: (ADR-B810-001; evidence.md P-02..P-13, P-16, P-21.)

---

## Q-005: Phase 2 canary — auto-wire per-route Envoy canary config vs document-only

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B810-005 seed), `specs.md` FR-B810-034
- **Raised on**: 2026-06-03
- **Raised by**: author (b8-10 specify pass)
- **Resolves at**: `/forge:design` → ADR-B810-005

### Context

The additive-first migration (Phase 2) places Envoy Gateway in parallel with
Kong. A canary-by-route pattern (gradually shifting traffic route-by-route
from Kong to Envoy) is the recommended cutover strategy. The question is
whether the migration script should:
- Emit a ready-to-apply Envoy `HTTPRoute` / `BackendTrafficPolicy` canary
  config (weighted routing, e.g., Kong 90% / Envoy 10%), or
- Document the canary approach in MIGRATIONS.md as a manual adopter step.

Envoy SecurityPolicy/JWT OIDC wiring (needed for a complete canary cutover)
is deferred to B.8.12. Attempting to auto-wire a canary without OIDC wiring
would produce an incomplete config.

### Options

- **(a) Document-only (lean here)**: Phase 2 applies the Envoy Gateway overlay
  templates (the `envoy-gateway/` infra templates from B.8.4) but does NOT
  generate per-route canary traffic weights. MIGRATIONS.md describes the
  manual canary-by-route process with example `HTTPRoute` snippets. The full
  canary automation is B.8.12.
- **(b) Auto-wire canary config**: Phase 2 generates an initial
  `envoy-gateway/canary.yaml` with 0% Envoy weight (adopter edits to graduate
  traffic). Risk: the generated config may be invalid without B.8.12 OIDC
  wiring; adds complexity to Phase 2.

**Lean here (author position)**: **(a) document-only** — auto-wiring a
partial canary config without OIDC wiring (B.8.12) creates an invalid
intermediate state; documentation is sufficient for B.8.10 scope; wiring
is B.8.12.

### Resolution

- **Resolved on**: 2026-06-03 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered).
- **Decision**: **(a) document-only**. Phase 2 applies the Envoy Gateway overlay
  templates (the 6 `2.0.0/infra/k8s/envoy-gateway/` files — evidence.md P-13) but
  generates **no per-route canary traffic weights**. The script prints
  canary-by-route Kong→Envoy guidance in its Phase 2 stdout (a "canary cutover" note
  block) and `docs/MIGRATIONS.md` carries the manual runbook with example
  `HTTPRoute` weight snippets. A complete canary needs Envoy SecurityPolicy/JWT OIDC
  wiring, which is **B.8.12**; auto-wiring a partial canary without OIDC would emit
  an invalid intermediate config. No auto-wiring; Kong is never auto-removed
  (VIII.1 preserved).
- **Rationale**: (ADR-B810-005; evidence.md P-13.)
