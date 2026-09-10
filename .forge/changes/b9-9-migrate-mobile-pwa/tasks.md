# Tasks — `b9-9-migrate-mobile-pwa`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — establish the contract

- [x] **T1.1** Render both archetypes from identical inputs and diff.
      **26 additions, 0 modifications** — ADR-B9-1-004 confirmed by measurement.
      [Story: FR-B99-005]
- [x] **T1.2** Establish that a mobile-only install has **no** scaffold manifest, so
      the substitution values must be derived from the project.
      [Story: FR-B99-003]

## T2 — RED

- [x] **T2.1** Four guards in `b9-2.test.sh` (it owns the scaffold-plan and provides
      `_render_legacy`; `forge-ci.yml` is at 419/420 and B.9.11 needs the last line).
      [Story: FR-B99-001, FR-B99-006, FR-B99-005, FR-B99-007]
- [x] **T2.2** Run with no script. **RED**, naming the absent script.
      [Story: FR-B99-001]

## T3 — GREEN

- [x] **T3.1** `bin/forge-migrate-mobile-pwa.sh`: preflight, derivation, filtered
      plan with absolutized sources, staged render, collision check, additive copy.
      [Story: FR-B99-001..008]
- [x] **T3.2** Run the guards. **GREEN 27/27.**
      [Story: FR-B99-001]

## T4 — prove it

- [x] **T4.1** Migrate a real `mobile-only` render; compare against a native
      `mobile-pwa-first` render. **Byte-identical except `.forge/scaffold-manifest.yaml`.**
      [Story: FR-B99-004, FR-B99-005]
- [x] **T4.2** Confirm the manifest differs only in `scaffold_date`,
      `scaffold_plan_sha`, `template_set_sha` — not in archetype, version, or the
      derived values.
      [Story: FR-B99-008]
- [x] **T4.3** `--dry-run` writes nothing; a re-run exits 7 on the `web-pwa/`
      preflight.
      [Story: FR-B99-007, NFR-B99-003]

## T5 — records

- [x] **T5.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-B99-009]
- [x] **T5.2** Plan §5.2 / §0.14 / §11 and roadmap: B.9 5/11 → 6/11.
      [Story: FR-B99-009]

## T6 — regression

- [x] **T6.1** `b9-2`, `b9-1`, `b9-3`, `b4` (mobile-only), `b8-2` GREEN.
      [Story: NFR-B99-001]
- [x] **T6.2** Full 80-entry CI matrix sweep + shellcheck.
      [Story: NFR-B99-002]
- [x] **T6.3** `verify.sh` + `constitution-linter.sh` after the status flip.
      [Story: NFR-B99-001]

## Negative scope guard

- [x] **T7.1** No edit to `overlay.sh`, the archetype scaffold-plan, the frozen
      `mobile-only/1.0.0` snapshot, or any template.
      [Story: NFR-B99-001]
