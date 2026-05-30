# Spec: b8-legacy-snapshot

<!-- Audit: B.8.2 (b8-2-legacy-snapshot) — flagship 1.0.0 reverse-target freeze. -->
<!-- Source change : `.forge/changes/b8-2-legacy-snapshot/` (delta specs.md authoritative). -->

**Namespace** : `FR-B8-2-*` / `NFR-B8-2-*` / `ADR-B8-2-*`.
**Constitution** : v1.1.0. No amendment. Touches one standard
(`global/upgrade-policy.md` freeze section + REVIEW.md ledger, ADR-3).
**Governing articles** : III.4 (anti-hallucination), IV/V (audit trail).

## Purpose

Second item of Module B.8. Freezes `full-stack-monorepo / 1.0.0` as the
immutable reverse target for `forge upgrade` before the 1.0.0 → 2.0.0 point of
no return. Pairs with B.8.1 (baseline doc) to pin 1.0.0.

## Deliverables

| Artifact | Path | FR |
|----------|------|----|
| Integrity manifest | `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` | FR-B8-2-001/002 |
| Immutability guard harness | `.forge/scripts/tests/b8-2.test.sh` (4 L1) | FR-B8-2-010/011/012/013/014 |
| Freeze policy | `global/upgrade-policy.md` § Snapshot maintenance-freeze + REVIEW.md | FR-B8-2-020/021/022 |
| CI registration | `forge-ci.yml::harness` (300/300) | FR-B8-2-040 |
| CHANGELOG | `[Unreleased]` entry | FR-B8-2-041 |
| Consolidated spec | this file | FR-B8-2-042 |

## Key decisions (ADRs)

- **ADR-B8-2-001** — keep version-keyed `<archetype>/<from_version>.tar.gz`
  (the path `forge-upgrade.sh` reads); **no `legacy/` dir** (reconciles plan
  §4.2 wording with the live mechanism).
- **ADR-B8-2-002** — manifest is a sibling `1.0.0.sha256` (`shasum -c` format).
- **ADR-B8-2-003** — freeze policy lives in `global/upgrade-policy.md`
  (section) + REVIEW.md ledger (maintainer decision; standard has no `version:`
  → no semver increment).
- **ADR-B8-2-004** — flagship-only; `mobile-only/1.0.0` freeze is B.9.
- **ADR-B8-2-005** — freeze the existing bytes; do NOT rebuild
  (SOURCE_DATE_EPOCH would churn bytes; frozen sha `1d0b05cd…cd45`).

## Anti-hallucination findings (Article III.4)

1. Plan's `legacy/` dir ≠ live mechanism — `forge-upgrade.sh:279` reads the
   version-keyed path. Kept version-keyed (FR-B8-2-022).
2. `upgrade-policy.md` has no `version:` frontmatter — "bump" = section
   addition, not a semver increment. No fabricated version.
3. sha256 computed from the live committed tarball, never transcribed.

## Constitutional compliance

Article I (TDD RED-first guard + negative proof), II (BDD scenario), III.4
(3 findings), IV/V (audit-trail freeze), XII (additive standard amendment,
ledgered). No violations.
