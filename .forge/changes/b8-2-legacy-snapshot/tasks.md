# Tasks: b8-2-legacy-snapshot

<!-- Status: archived -->
<!-- Schema: default -->
<!-- Audit: B.8.2 (docs/new-archetypes-plan.md §4.2) -->

TDD order mandatory (Article I). The harness drives the manifest + standard
section to GREEN.

## Phase 1: Harness RED

- [x] T01 — Scaffold `.forge/scripts/tests/b8-2.test.sh` from the `b8-1.test.sh` frame (`--level`, `_helpers.sh`, summary, non-zero exit). [Story: FR-B8-2-010]
- [x] T02 — Write L1 RED: sha guard (committed tarball sha256 == committed manifest). [Story: FR-B8-2-011] [P]
- [x] T03 — Write L1 RED: tarball present + extractable via `forge-snapshot.sh extract full-stack-monorepo 1.0.0 <tmp>`. [Story: FR-B8-2-012] [P]
- [x] T04 — Write L1 RED: freeze-section reachability in `upgrade-policy.md` + REVIEW.md ledger entry present + dated. [Story: FR-B8-2-014] [P]
- [x] T05 — Run `b8-2.test.sh --level 1` → confirm RED (manifest + section absent). [Story: Article I — verify RED]

## Phase 2: Author deliverables to GREEN

- [x] T06 — Compute sha256 of the **already-committed** `1.0.0.tar.gz` (do NOT rebuild) and commit `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` in `shasum -c` format. [Story: FR-B8-2-001/002, ADR-B8-2-002/005]
- [x] T07 — Append the "1.0.0 maintenance-freeze" section to `global/upgrade-policy.md` (freeze + all-changes-go-to-2.0.0 + 2.0.0→new file + audited-patch carve-out + version-keyed-not-legacy reconciliation). [Story: FR-B8-2-020/022, ADR-B8-2-001/003]
- [x] T08 — Append the REVIEW.md ledger entry dated 2026-05-30 (upgrade-policy freeze section, B.8.2). [Story: FR-B8-2-021, ADR-B8-2-003]
- [x] T09 — Run `b8-2.test.sh --level 1` → confirm GREEN. [Story: Article I — verify GREEN]
- [x] T10 — Negative proof: copy tarball to tmp, flip a byte, point the sha check at the copy → confirm FAIL; restore; confirm GREEN. [Story: FR-B8-2-013]

## Phase 3: Integration

- [x] T11 — Register `b8-2.test.sh` in `forge-ci.yml::harness`; 3-comment compression if needed; assert ≤ 300 lines. [Story: FR-B8-2-040, ADR-T533-002]
- [x] T12 — CHANGELOG `[Unreleased]` entry citing `b8-2-legacy-snapshot` + B.8.2. [Story: FR-B8-2-041]
- [x] T13 — Create consolidated spec `.forge/specs/b8-legacy-snapshot.md` (`FR-B8-2-*`). [Story: FR-B8-2-042] [P]

## Phase 4: Quality & Verification

- [x] T14 — Byte-identity: confirm `1.0.0.tar.gz` sha256 unchanged (`1d0b05cd…cd45`); `git diff` shows tarball NOT modified. [Story: NFR-B8-2-003]
- [x] T15 — Scope: `git diff --name-only` — no `.forge/templates/**` or `.forge/schemas/**`; only standard touch = `upgrade-policy.md` + `REVIEW.md`. [Story: NFR-B8-2-002]
- [x] T16 — Regression: `a7.test.sh` GREEN. [Story: NFR-B8-2-004] [P]
- [x] T17 — Perf: `b8-2.test.sh --level 1` ≤ 5 s, zero net/Docker. [Story: NFR-B8-2-001] [P]
- [x] T18 — Gates: `verify.sh` 0 FAIL (Open Questions gate — all answered) + `constitution-linter.sh` OVERALL PASS + `validate-standards-yaml.sh` unaffected (markdown standard, not YAML). [Story: Article V gate]
- [x] T19 — Independent reviewer pass (separate context, no transcript trust): re-run harness matrix + a7 + verify + linter; re-derive the sha256 from the live tarball; confirm guard FAILS on corruption; confirm no `legacy/` dir introduced; confirm version-keyed BASE path intact. [Story: Author/Reviewer separation]
- [x] T20 — Populate `evidence.md` (RED→GREEN, negative proof, scope, gates). [Story: Article V audit trail]

## Constitutional Compliance Gate (per task)

Phase 1 precedes Phase 2 (TDD); every task carries an FR/NFR/ADR story; no
runtime architecture article touched. No `[TASK VIOLATION]`. Gate PASS.
