# Proposal: b8-10-migrate-flagship

<!-- Created: 2026-06-03 -->
<!-- Schema: default -->
<!-- Audit: B.8.10 (docs/new-archetypes-plan.md §4.2 lines 2323-2327 — flagship migration script; ARCHITECTURE-TARGET §11 4-phase plan) -->

## Problem

All five 2.0.0 template bricks have shipped (B.8.4 Envoy, B.8.5 Postgres,
B.8.6 Connect, B.8.7 Zitadel, B.8.9 Qwik). The 2.0.0 candidate schema is
complete but `scaffoldable: false` — there is **no orchestrated path** to
carry an existing 1.0.0 flagship project across the additive-first deltas to
the 2.0.0 shape. Today an adopter who runs `forge upgrade` on a 1.0.0
project hits the exit-7 abort:

```
[NEEDS MIGRATION: from 1.0.0 to 2.0.0]
```

(`forge-upgrade.sh::_a7_check_version_compat` — the major-version guard,
already implemented by A.7). The abort points at `docs/MIGRATIONS.md`,
which has **no 1.0.0→2.0.0 section** (A.7 left it a deferred stub). B.8.10
is the **first cutover/orchestration brick** (last template brick was
B.8.9): it supplies the migration orchestration script + the adopter
runbook the abort points to.

### GROUND-TRUTH FINDINGS (Article III.4)

**Ground truth (re-read 2026-06-03):**

- **The exit-7 abort is already built.** `forge-upgrade.sh` trips
  `[NEEDS MIGRATION: from 1.0.0 to 2.0.0]` on the major diff — B.8.10 does
  NOT modify that driver path; it fills the *other side* (the script the
  adopter runs after the abort + the MIGRATIONS.md section).
- **Phase 2 has NO DBOS leg.** B8O (ADR-B8O-001) cancelled the
  Temporal→DBOS swap for Rust; `2.0.0.yaml` marks that delta
  `cancelled: true`; Temporal is retained as the Rust orchestrator
  (orchestration.yaml v1.2.0 `default_by_language.rust: temporal`). The
  script applies **only** the additive-first deltas: Kong→Envoy (B.8.4),
  REST-bridge→Connect (B.8.6), implicit-auth→Zitadel (B.8.7),
  no-web-public→Qwik (B.8.9), and the postgres-16→17+pgvector crossing
  delta (B.8.5). It MUST NOT scaffold/run DBOS, swap out Temporal,
  dual-run, or add a `dbos` crate.
- **Additive-only — no breaking removal here.** §4.1 step 6 (bump schema +
  remove Kong/Temporal/REST) and the VIII.1/VIII.2 Constitution amendment
  are **B.8.14**. B.8.10 applies the parallel overlays (Envoy ∥ Kong,
  Connect ∥ REST, etc.) and leaves the old components in place. This keeps
  the brick constitution-compliant pre-amendment: VIII.1 (Kong SHALL) +
  VIII.2 (Temporal SHALL) stay satisfied because the migration target is an
  **opt-in candidate** (`scaffoldable: false`) and the scaffolded default
  is never flipped off Kong/Temporal until B.8.14.
- **Rollback target is the byte-frozen 1.0.0 snapshot.** B.8.2 froze
  `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` (+
  `1.0.0.sha256`, `b8-2.test.sh` guard). The script's rollback restores
  from that exact file and MUST NOT rebuild/overwrite it.
- **Rollback criteria (B.8.13) are post-B8O**: p99 +>20% after Envoy →
  rollback Kong; traceparent errors >1% → rollback OTel SDK only. The
  DBOS-Postgres-CPU criterion is **REMOVED per B8O** (no DBOS leg).
  B.8.10 references these; the full runbook is B.8.13.
- **Pure tooling — no standard bump** (T5.1 precedent): no
  `.forge/standards/*.yaml` edit; `constitution_version: 1.1.0` unchanged.
- **Plan-doc drift flagged, not this brick's job to fix**: §4.1 step 2
  (L2262 "Ajouter DBOS embedded ∥ Temporal") and the standalone rollback
  section (L2619-2623, un-struck DBOS-CPU line) are stale vs B8O — flag for
  a doc pass, out of scope here. Also: live `1.0.0.tar.gz` is 656.5 KB vs
  the 422 KB figure in NFR-UP-003 (under the 1 MB budget; drift noted).
- **Phases 3 & 4 are forward-references only.** Phase 3 (new archetypes,
  T7) and Phase 4 (deprecation, T8) are documented as future stages in the
  script's `--help` + MIGRATIONS.md, not executed by this brick. B.8.10
  delivers the Phase 0/1/2 orchestration for the flagship only.

## Solution

When built, the B.8.10 brick MUST:

1. Create `bin/forge-migrate-flagship.sh` (bash thin + Python 3 inline,
   `set -uo pipefail`, zero new dep — mirrors `bin/forge-sbom.sh` /
   `.forge/scripts/compliance/bundle.sh`), a **phased orchestrator** over
   `--target <dir>`:
   - **Phase 0 — audit/preflight**: assert target is a scaffolded 1.0.0
     full-stack-monorepo (read `.forge/scaffold-manifest.yaml`
     `archetype_version: 1.0.0`), Git-clean gate (mirror A.7 `--force`),
     verify the frozen 1.0.0 snapshot sha256 (b8-2 guard reuse).
   - **Phase 1 — observability + contracts**: assert/idempotently apply the
     already-shipped obs trio + Connect codegen overlays (no-op if present).
   - **Phase 2 — structural overlay (additive, canary-documented)**: apply
     the 2.0.0 template overlays — Envoy Gateway ∥ Kong, Connect-RPC ∥
     REST-bridge, Zitadel, Qwik web-public, Postgres 17+pgvector image —
     into the target **without removing** Kong/Temporal/REST (those are
     B.8.14). **NO DBOS leg.**
   - **Phase 3 / Phase 4**: forward-reference stubs (print the T7/T8 plan,
     exit informational) — not executed.
   - exit-code envelope (lean `0` success / `1` migration error / `2` usage
     / `7` precondition-not-met mirroring A.7 — final values Q-002).
2. Ship `--dry-run` (default-safe: print the plan + per-phase file actions,
   mutate nothing) + `--phase <0|1|2|all>` selection + `--force`
   (Git-clean override) + `--rollback` (restore from the frozen 1.0.0
   snapshot, never rebuild it).
3. Hook into `forge upgrade`: the exit-7 `[NEEDS MIGRATION:]` message +
   `docs/MIGRATIONS.md` 1.0.0→2.0.0 section point the adopter at
   `forge migrate-flagship --target . --dry-run` (wiring exact: a CLI
   subcommand `forge migrate-flagship` thin TS wrapper vs doc-only
   invocation — Q-001).
4. Write the `docs/MIGRATIONS.md` 1.0.0→2.0.0 section (the A.7 deferred
   stub fill): the 4-phase walkthrough, additive-first posture, the
   B8O no-DBOS note, rollback criteria cross-ref (B.8.13), the
   "stay-on-1.0.0-until-T8" legacy option, and the
   `scaffoldable:false`-until-B.8.14 caveat.
5. Append a migration record to the target's `upgrade_history` ledger
   (reuse A.7 `_a7_append_upgrade_history` shape) — or a parallel
   `migration_history` (Q-003); SOURCE_DATE_EPOCH-deterministic where a
   timestamp is emitted.
6. Ship harness `.forge/scripts/tests/b8-10.test.sh` (~12 L1 hermetic
   ≤2 s: script exists + executable + header/usage, `--dry-run` mutates
   nothing on a fixture, phase selection, exit-code envelope, no-DBOS
   guard (grep: script never references `dbos`/`dbos-embedded` as an
   applied delta), additive-only guard (never deletes Kong/Temporal/REST
   paths), rollback targets the frozen snapshot path, MIGRATIONS.md
   section present, CHANGELOG anchored `b8-10-migrate-flagship`, forge-ci
   registration, frozen-1.0.0 guard, b8-2/b8-3 coupling guard) + an
   **L2 opt-in** (`FORGE_B8_10_LIVE=1`) that runs the script `--dry-run`
   (and, if a scaffolded fixture is available, a real Phase 2 overlay)
   against an actual `forge init` 1.0.0 tree.
7. Register `b8-10.test.sh` in `forge-ci.yml`; CHANGELOG `[Unreleased]`
   entry.
8. Run the full ~49-harness suite + gates before push; gates re-run
   POST-flip; independent review at design and pre-archive.

Decisions reserved for `/forge:design` (ADRs), leanings stated:

- **ADR-B810-001 — overlay mechanism.** Reuse `forge-upgrade.sh`'s 3-way
  merge + `framework-owned-paths.yml` + snapshot recovery vs a dedicated
  overlay-render. **Lean:** delegate the file-merge to the existing
  `forge-upgrade.sh` machinery where possible (the migration script
  orchestrates phases + preconditions + the 2.0.0 template-set selection;
  forge-upgrade does the actual 3-way merge), avoiding a second merge
  engine.
- **ADR-B810-002 — exit-code envelope + flags.** **Lean:** `0/1/2/7`
  (7 = precondition mirroring A.7's exit-7); `--dry-run` default-safe;
  `--phase`, `--force`, `--rollback`, `--target`, `--help`.
- **ADR-B810-003 — CLI surface (Q-001).** **Lean:** doc-only invocation
  in MIGRATIONS.md for B.8.10 (adopter runs `bash bin/forge-migrate-flagship.sh`);
  a `forge migrate-flagship` TS subcommand is a nice-to-have deferred to
  B.8.14/B.8.15 unless trivial — decide at design.
- **ADR-B810-004 — ledger (Q-003).** **Lean:** reuse `upgrade_history`
  (single ledger, A.7 shape) with a `kind: flagship-migration` marker
  rather than a parallel ledger.
- **ADR-B810-005 — Phase 1 idempotency.** **Lean:** Phase 1 is an
  assert-or-apply no-op when the obs/contract overlays already exist
  (the flagship 1.0.0 already ships the obs trio post-B.8.8); document
  that Phase 1 is mostly a verification gate on the flagship.

Release vehicle: **v0.4.0-rc.12**.

## Scope In

- `bin/forge-migrate-flagship.sh` — 4-phase orchestrator (Phases 0/1/2
  executable, 3/4 forward-ref), `--dry-run`/`--phase`/`--force`/
  `--rollback`/`--target`.
- `docs/MIGRATIONS.md` 1.0.0→2.0.0 section (A.7 stub fill).
- `upgrade_history` migration-record append (reuse A.7 shape).
- Harness `b8-10.test.sh` (L1 + opt-in L2) + forge-ci.yml + CHANGELOG.

## Scope Out (Explicit Exclusions)

- **Breaking removal** of Kong/Temporal/REST-bridge — B.8.14 (with the
  schema 1.0.0→2.0.0 bump + Constitution VIII.1/VIII.2 amendment).
- **DBOS anything** — cancelled for Rust (B8O); no scaffold, no crate, no
  dual-run, no rollback leg.
- **Rollback runbook authoring** (the full criteria doc) — B.8.13;
  B.8.10 only references + wires the rollback restore mechanic.
- **`forge upgrade` matrix test** — B.8.15.
- **Envoy SecurityPolicy/JWT OIDC wiring + backend auth middleware** —
  B.8.12 (E2E migration) / deferred from B.8.7.
- **Phase 3 (new archetypes T7) + Phase 4 (deprecation T8) execution** —
  forward-reference stubs only.
- **Schema promotion to stable / scaffoldable:true** — B.8.14.
- **Any 1.0.0 template / schema.yaml / snapshot mutation** — frozen
  (B.8.2); the script READS the snapshot, never rewrites it.
- **Standard bump** — pure tooling, no `.forge/standards/*` edit.

## Impact

- **Users affected**: none until B.8.14 — 2.0.0 stays not-scaffoldable;
  the migration is an opt-in tool. 1.0.0 adopters keep working unchanged.
- **Technical impact**: 1 new `bin/` script, 1 doc section, 1 ledger-append
  helper (reused), 1 new harness. No production code, no template/standard/
  schema mutation (the script consumes the 2.0.0 templates as inputs).
- **Dependencies**: A.7 (forge-upgrade machinery + exit-7 abort), B.8.2
  (frozen snapshot rollback target), B.8.4/5/6/7/9 (the 2.0.0 overlays
  applied), B8O (no-DBOS constraint).

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: proposal precedes specs;
  no script before specs.md + design.md + tasks.md.
- **Article III.4 (Anti-Hallucination) — CENTRAL**: the exit-7 abort was
  re-read as already-built (not re-implemented); the no-DBOS constraint is
  carried from B8O; plan-doc drift (stale §4.1 step 2, stale rollback
  section, snapshot-size figure) surfaced explicitly rather than
  propagated.
- **Article IV (Delta-based)**: ADDED FRs; MIGRATIONS.md gets a new
  section; no spec rewrite.
- **Article V (Compliance gate)**: harness + gates before status flips;
  full suite before push; POST-flip re-run (b8-coroot lesson).
- **Article VIII.1 (Kong SHALL — IN FORCE, PRESERVED)**: the script adds
  Envoy in parallel and never removes Kong; the scaffolded default stays
  Kong until B.8.14. No violation.
- **Article VIII.2 (Temporal SHALL — IN FORCE, PRESERVED)**: Temporal
  retained; no DBOS leg; orchestration untouched.
- **Article VIII.5 (IaC)**: the overlays applied are declarative
  templates already under version control.
- **Article XII (Governance)**: no governance change; the breaking
  bump/amendment is explicitly B.8.14.

## Open Questions (seed)

- **Q-001** — CLI surface: doc-only `bash bin/forge-migrate-flagship.sh`
  invocation vs a `forge migrate-flagship` TS subcommand wired in
  commander (→ ADR-B810-003; open, lean doc-only for B.8.10).
- **Q-002** — exit-code envelope + flag set final values (→ ADR-B810-002;
  open, lean 0/1/2/7).
- **Q-003** — ledger: reuse `upgrade_history` with a migration marker vs a
  parallel `migration_history` block (→ ADR-B810-004; open, lean reuse).
- **Q-004** — overlay engine: delegate file-merge to `forge-upgrade.sh`
  vs a dedicated render path; how the script selects the 2.0.0 template
  set as the merge RIGHT (→ ADR-B810-001; open).
- **Q-005** — Phase 2 canary: does the script emit canary-by-route Envoy
  config guidance (per-route Kong→Envoy cutover) or document it only
  (→ ADR-B810-005; open, lean document-only — wiring is B.8.12).
