# Proposal: t5-cargo-pin-refresh
<!-- Created: 2026-05-16 -->
<!-- Schema: default -->
<!-- Audit: T5.1.E (docs/new-archetypes-plan.md §0.1 extension — Option B) -->

## Problem

The first run of `task validate` (2026-05-16, immediately after
`cli-trust-harness` landed) surfaced a Cargo dependency-resolution
failure on every fresh scaffold of the `full-stack-monorepo`
archetype :

```
error: failed to select a version for the requirement `buffa = "=0.3.3"`
candidate versions found which didn't match: 0.6.0, 0.5.2, 0.5.1, ...
location searched: crates.io index
required by package `grpc-api v0.1.0 (.../backend/crates/grpc-api)`
```

### Root cause — fact-checked against crates.io API (2026-05-16)

Direct query of the crates.io API at `https://crates.io/api/v1/crates/...`
confirms :

- **`buffa` published versions** : `0.6.0`, `0.5.2`, `0.5.1`, `0.5.0`,
  `0.4.0`, `0.3.0`, `0.2.0`, `0.1.0`. **Series 0.3.x stops at 0.3.0** ;
  `0.3.1`, `0.3.2`, `0.3.3` were **never published**.
- **`buffa-types` published versions** : same shape ; `0.6.0` … `0.3.0`,
  no 0.3.x past 0.3.0.
- **`connectrpc` published versions** : `0.4.2`, `0.4.1`, `0.4.0`,
  **`0.3.3` exists (non-yanked)**, `0.3.2`, `0.3.1`, `0.3.0`, etc.
- **`connectrpc-build` published versions** : `0.4.2` … **`0.3.3`
  exists**, full 0.3.x series.
- **`connectrpc 0.3.3` declares `buffa = "^0.3"`** as a normal
  dependency and `buffa-types = "^0.3"` as a dev dependency
  (verified via `https://crates.io/api/v1/crates/connectrpc/0.3.3/dependencies`).

### What `t5-connect-codegen` (2026-05-06) actually did

The archived change `t5-connect-codegen` pinned **four** crates at
`=0.3.3` in `transport.yaml` v1.1.0 + the `grpc-api/Cargo.toml.tmpl`
template, under the assumption that the four crates ship together
on a single release cadence. That assumption is wrong : `buffa` and
`buffa-types` have their own release cadence and topped out at 0.3.0
in their 0.3 line. The `=0.3.3` pins for those two crates have
**never resolved** on any fresh Cargo invocation.

The change was archived GREEN because :

- The example tree `examples/forge-fsm-example/backend/crates/grpc-api/Cargo.toml`
  was **not regenerated** from the template — it never included
  `buffa` / `buffa-types` deps.
- The test harness `t5.test.sh` was grep-only (no `cargo check`).
- `forge-ci.yml` did not install the Cargo toolchain.

So : the pins lived in the template + snapshot tarball + standard for
**10 days** (2026-05-06 → 2026-05-16) without any test exercising
them. T5.1 `archetypes-smoke.test.ts` with `FORGE_E2E_TOOLCHAINS=1`
exposed the bug on its first run.

### Scope of the bug

| File                                                                                                                  | Line | Pin                          | Status                                                              |
|-----------------------------------------------------------------------------------------------------------------------|------|------------------------------|---------------------------------------------------------------------|
| `.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/Cargo.toml.tmpl`                              | 26   | `connectrpc = "=0.3.3"`      | ✓ valid (no change)                                                  |
| same file                                                                                                             | 27   | `buffa = "=0.3.3"`           | **✗ INVALID — never published** ; fix `=0.3.0`                       |
| same file                                                                                                             | 28   | `buffa-types = "=0.3.3"`     | **✗ INVALID** ; fix `=0.3.0`                                         |
| same file                                                                                                             | 60   | `connectrpc-build = "=0.3.3"`| ✓ valid (no change)                                                  |
| `cli/assets/.forge/templates/.../Cargo.toml.tmpl`                                                                      | 27-28 | mirror                      | mirror fix                                                           |
| `.forge/standards/transport.yaml` v1.1.0                                                                               | 71-72 | `buffa: "=0.3.3"` + `buffa-types: "=0.3.3"` | **✗ INVALID** ; fix `=0.3.0`                |
| `.forge/standards/transport.yaml` lines 55-63                                                                          | —    | WAIVER comment block         | Comment justifies the (invalid) `=0.3.3` pin via fabricated pedigree arguments ; needs rewrite per ADR-T5CPR-003 |
| `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`                                                           | —    | contains buggy template       | regenerate                                                           |
| `cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`                                                | —    | mirror                       | regenerate                                                           |
| `examples/forge-fsm-example/backend/crates/grpc-api/Cargo.toml`                                                        | —    | absent (never regenerated)    | no change required                                                   |

## Solution

A single tactical change that :

1. **Corrects the two dead pins** (`buffa` + `buffa-types`) to `=0.3.0`
   — the unique version of their 0.3.x series that actually exists.
   `connectrpc 0.3.3` declares `buffa = "^0.3"`, so `=0.3.0`
   satisfies the constraint exactly.
2. **Keeps `connectrpc = "=0.3.3"` and `connectrpc-build = "=0.3.3"`
   unchanged** — both pins point at versions that exist. ADR-T5-001
   (Anthropic OSS pedigree) remains in force for those two.
3. **Bumps `transport.yaml` v1.1.0 → v1.2.0** (additive correction).
   Bump justified by the fact that the published pinned-versions
   contract of the standard has changed in observable ways
   (two pins moved). REVIEW.md ledger gains an `Updated` entry.
4. **Rewrites the WAIVER comment block** in `transport.yaml` (lines
   55-63) per ADR-T5CPR-003 : remove the fabricated pedigree-style
   justification for `=0.3.3` ; document the actual reason for the
   amended pin (`=0.3.0` is the only resolvable version of the 0.3
   series for `buffa` / `buffa-types` ; `connectrpc 0.3.3` declares
   `buffa = "^0.3"`).
5. **Regenerates the snapshot tarballs** (`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
   + bundled mirror in `cli/assets/`) so `forge upgrade` and
   fresh scaffolds both see the fixed template.
6. **Ships a test harness** `.forge/scripts/tests/t5-cargo.test.sh`
   with ≥ 8 L1 grep + 1 L2 opt-in that asserts the pins are
   valid against crates.io (skip-pass when offline / `FORGE_T5C_LIVE=1`).
7. Registers the harness in `forge-ci.yml`.
8. CHANGELOG `[Unreleased]` entry + plan/roadmap inventory rows.

### Out of scope

- **Modernising to `connectrpc 0.4.x` or `buffa 0.5.x` / 0.6.x.**
  This change is a **minimum-edit correction** of an invalid pin,
  not a modernisation. The whole `connectrpc` family modernisation
  belongs to B.8 (T6 flagship migration) where the broader Connect
  story is re-evaluated alongside Kong → Envoy.
- **Re-snapshotting `mobile-only`** — `mobile-only` does not consume
  `buffa` / `connectrpc`. Its snapshot is unaffected.
- **Constitution amendment.** No Article touched.
- **Bumping `connectrpc-build` separately.** It exists as `=0.3.3` ;
  no fix needed.
- **Bumping the `transport.yaml` `breaking_change` flag.** The pin
  refresh is **corrective** not breaking — `connectrpc 0.3.3` was
  always meant to consume `buffa` series 0.3, and `=0.3.0` is the
  only resolvable concrete value of that series.

## Scope In

- Edit `.forge/standards/transport.yaml` :
  - bump `version: "1.1.0"` → `"1.2.0"`
  - patch lines 71-72 : `buffa: "=0.3.0"` + `buffa-types: "=0.3.0"`
  - rewrite the WAIVER comment block per ADR-T5CPR-003
- Append entry to `.forge/standards/REVIEW.md` ledger.
- Edit `.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/Cargo.toml.tmpl`
  lines 27-28 : same pin fixes.
- Mirror the template fix in
  `cli/assets/.forge/templates/.../Cargo.toml.tmpl`.
- Regenerate snapshot tarballs
  `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
  + `cli/assets/.forge/scaffold-snapshots/.../1.0.0.tar.gz`.
- New harness `.forge/scripts/tests/t5-cargo.test.sh` (≥ 8 L1 + 1 L2
  opt-in `FORGE_T5C_LIVE=1`).
- Register `t5-cargo.test.sh` in `.github/workflows/forge-ci.yml`
  matrix (after `t5-1.test.sh`).
- CHANGELOG `[Unreleased]` entry.
- Plan §0.1 + §1.4 + §11 + Inventory : flip T5.1.E Planned → Done.
- Roadmap : flip T5.1 row from `**Partial**` to `**Done**` once both
  `cli-trust-harness` AND `t5-cargo-pin-refresh` are archived ;
  inventory row added.

## Scope Out (Explicit Exclusions)

- **Bump `connectrpc` or `connectrpc-build` past 0.3.3.** They
  resolve correctly today. Modernisation is B.8 territory.
- **Touch `flutter/opentelemetry.md` or the OTel Dart pkg fantôme.**
  That is **T5.3** (`t5-otel-dartastic-realign`), explicitly scoped
  separately.
- **Re-snapshot `mobile-only` / 1.0.0.** Not affected by the buffa
  pin.
- **Constitution amendment.** No Article touched.
- **Live `cargo check --workspace` execution on CI matrix by default.**
  The harness L1 stays grep-only ; live Cargo execution belongs to
  the existing `task smoke-with-toolchains` flow + the T5.1.B
  opt-in `FORGE_E2E_TOOLCHAINS=1`. CI matrix gain is limited to L1
  grep checks.

## Impact

- **Users affected** :
  - **Forge adopters who scaffold `full-stack-monorepo` after
    2026-05-06 and run `cargo build`** : the failure they see today
    disappears. Pre-2026-05-06 adopters are unaffected (they
    scaffolded before the bug landed in `t5-connect-codegen`).
  - **Forge maintainer** : `task smoke-with-toolchains` and
    `task validate` both flip GREEN for full-stack-monorepo's
    `cargo check --workspace` leg.
- **Technical impact** : 2 standards files touched
  (`transport.yaml` + `REVIEW.md`) ; 2 template files touched
  (`Cargo.toml.tmpl` + mirror) ; 2 snapshot tarballs regenerated ;
  1 new harness file (~150 LOC) ; 1 CI matrix row added
  (forge-ci.yml stays under NFR-CI-002 300-line budget — currently
  292, gains ~5 lines).
- **Dependencies** : depends on `cli-trust-harness` being merged
  first (the smoke detection mechanism that exposes the bug lives
  there). If `cli-trust-harness` is archived as part of the same
  PR sequence, this change can land immediately after.
- **Risk level** : **Low**. The fix is a 2-line pin update from a
  version that doesn't exist to a version that does. Local
  validation via `task smoke-with-toolchains` provides immediate
  GREEN confirmation.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`t5-cargo.test.sh` with **≥ 8 L1 stubs all returning
`_not_implemented`** (full RED witness). Phase 2 ships the template
+ standard fix ; Phase 3 the snapshot regen ; Phase 4 the
documentation. RED witness via `task smoke-with-toolchains` was
**already acquired** by the first `task validate` run on 2026-05-16
— this change closes that pre-existing RED.

### Article II — BDD

The adopter-facing flow (scaffold `full-stack-monorepo` → `cargo
build` → exits 0) gets a Gherkin scenario in `specs.md`. The
maintainer-facing flow (template edit → snapshot regen via
`npm run bundle`) does not — it's plumbing.

### Article III — Specs Before Code

Confirmed : `specs.md` written before any pin is touched.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Three open questions raised, all resolved during `/forge:design`
by ADR-T5CPR-001..003.

### Article V — Audit Trail

Each task tagged `[Story: FR-T5CPR-XXX]`. The harness file carries
`# Audit: T5.1.E (t5-cargo-pin-refresh)` in its header. The
amended `transport.yaml` WAIVER block carries a `# 2026-05-16
amend (t5-cargo-pin-refresh)` line per ADR-T5CPR-003.

### Article XII — Governance

The change uses the standard re-revue procedure documented in
`global/standards-lifecycle.md` — bump `transport.yaml` to v1.2.0
(additive), REVIEW.md ledger entry. Article XII not amended.

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none.
Three open questions Q-001 / Q-002 / Q-003 raised in
`open-questions.md`, all resolved by ADR-T5CPR-001..003 in
`design.md`.
