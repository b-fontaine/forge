# Evidence — b8-2-legacy-snapshot

<!-- Article V audit trail. Captured 2026-05-30. -->

## TDD RED → GREEN

- **RED**: `b8-2.test.sh --level 1` → Passed 1 / Failed 3 (manifest absent,
  freeze-section absent, REVIEW entry absent; extractable passed — frozen
  tarball already present).
- **GREEN**: after authoring the `1.0.0.sha256` manifest, the
  `upgrade-policy.md` freeze section, and the REVIEW.md ledger entry →
  Passed 4 / Failed 0, wall-clock 0.45 s (NFR-B8-2-001 ≤ 5 s).

## Immutability guard — negative proof (FR-B8-2-013)

Appended `corrupt` to a copy-protected `1.0.0.tar.gz`:
- `_test_b82_l1_001_sha_guard` → **✗ FAIL** (Failed: 1).
Restored from backup:
- sha256 == `1d0b05cd57598ac6b11e7c07b36f4f94f3c5e08303f93bac18332aa7efabcd45` (unchanged).
- guard → **✓ PASS** (Failed: 0).
The point-of-no-return drift guard fires as designed.

## Byte-identity (NFR-B8-2-003)

`1.0.0.tar.gz` sha256 = `1d0b05cd…cd45`, **unchanged** by this change (the
tarball is not in `git diff`; only the new sibling `1.0.0.sha256` manifest is
added). ADR-B8-2-005 honored — not rebuilt.

## Scope (NFR-B8-2-002)

`git diff` + untracked filtered on `.forge/(templates|schemas)/` → **none**.
The only standard surface touched: `.forge/standards/global/upgrade-policy.md`
(freeze section) + `.forge/standards/REVIEW.md` (ledger) — per ADR-3.

## Regression + gates

- `a7.test.sh` → **29 / 0** (frozen artifact is the one a7 already exercises).
- `b8-2.test.sh --level 1` → **4 / 0**.
- `forge-ci.yml` → **300 lines** (b8-2 registered; 2 inline comments trimmed
  to stay ≤ 300, ADR-T533-002).
- `verify.sh` → **RESULT: PASS** (Open Questions gate — Q-001..004 all
  answered).
- `constitution-linter.sh` → **OVERALL PASS** (46 PASS / 0 FAIL / 5 WARN).
- `validate-standards-yaml.sh` → STD-PASS (YAML standards unaffected;
  `upgrade-policy.md` is a markdown standard, not YAML).

## Ground-truth provenance (Article III.4)

- BASE-recovery path: `forge-upgrade.sh:279` reads
  `.forge/scaffold-snapshots/<archetype>/<from_version>.tar.gz` — version-keyed,
  no `legacy/`. Kept (ADR-B8-2-001).
- `upgrade-policy.md` has no `version:` frontmatter (markdown standard,
  stage: stable) — "bump" = section addition, no semver. No fabricated version.
- sha256 computed live (`shasum -a 256 1.0.0.tar.gz`), `shasum -c` → OK.

## Independent review — APPROVE (2026-05-30)

Separate-context `code-reviewer` (opus) re-derived all 10 falsification
targets from live files/commands (no transcript trust): recomputed sha ==
manifest (`1d0b05cd…cd45`, `shasum -c` OK); immutability guard genuinely
FAILS on a corrupted copy and recovers byte-identical (`git status` clean
after restore); tarball NOT rebuilt (only the `.sha256` is added); no
`legacy/` dir; `forge-upgrade.sh:279` version-keyed path untouched; extract
test non-vacuous (290 files); sha guard portable (`shasum`/`sha256sum`) and
non-tautological; freeze section + dated REVIEW ledger contain every required
invariant; zero templates/schemas touched; CI 300/300 with b8-2 registered.
**VERDICT: APPROVE.** Two LOW notes — (1) flip `status: planned→implemented`
post-approval + re-run gates (done: verify PASS + linter PASS + b8-2 4/0 +
a7 29/0 re-run post-flip); (2) `.omc/project-memory.json` churn excluded from
this change's commit. Neither is a deliverable defect.

T19 complete. Implemented + independently approved; ready for `/forge:archive`.
