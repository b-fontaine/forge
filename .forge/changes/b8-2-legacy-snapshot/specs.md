# Specifications: b8-2-legacy-snapshot

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.2 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0 legacy snapshot freeze) -->

**Namespace** : `FR-B8-2-*` / `NFR-B8-2-*` / `ADR-B8-2-*`.
**Constitution** : v1.1.0, unchanged. This change **freezes** the 1.0.0
reverse-target snapshot and makes drift tamper-evident. It authors no
migration code and does NOT rebuild or modify the tarball. Per ADR-3 it DOES
touch one standard (`global/upgrade-policy.md`, additive freeze section +
REVIEW.md ledger) — so it is **not** zero-standard like B.8.1.
**Governing articles** : III.4 (Anti-Hallucination), IV/V (audit trail).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4.2 B.8.2 (+ §4.1 additive-first) |
| **BASE-recovery mechanism (observed)** | `bin/forge-upgrade.sh:279` — `BASE = .forge/scaffold-snapshots/<archetype>/<from_version>.tar.gz`. Version-keyed, **not** a `legacy/` dir. |
| **Frozen artifact (observed)** | `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`, 650.8 KB, reflects 1.0.0-final templates (post-B.8.8 obs trio, rc.6) |
| **Frozen sha256 (observed 2026-05-30)** | `1d0b05cd57598ac6b11e7c07b36f4f94f3c5e08303f93bac18332aa7efabcd45` |
| **Snapshot builder** | `bin/forge-snapshot.sh build <archetype> <version>` → `<version>.tar.gz` ; SOURCE_DATE_EPOCH = HEAD timestamp (rebuild churns bytes) |
| **Existing coverage** | `a7.test.sh` FR-UP-008 (present/extractable/BASE-recovery), NFR-UP-003 (size budget) |
| **Standard touched (ADR-3)** | `global/upgrade-policy.md` — markdown standard, **no `version:` frontmatter** (stage: stable). "Bump" = append a maintenance-freeze section + REVIEW.md ledger entry. No semver to increment. |
| **REVIEW ledger** | `.forge/standards/REVIEW.md` (append-only) |
| **Harness frame** | `--level` + `_helpers.sh` (per `b8-1.test.sh` / `b8-coroot.test.sh`) |
| **CI budget** | `forge-ci.yml` 300/300 (NFR-CI-002) — registration needs 3-comment compression (ADR-T533-002) |
| **Sibling** | `b8-1-audit-baseline` (baseline doc) — B.8.1 + B.8.2 jointly pin 1.0.0 |
| **Downstream** | B.8.15 (upgrade matrix relies on frozen 1.0.0 BASE), B.8.12/B.8.13 (rollback) |
| **Release target** | v0.4.0-rc.7 |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Integrity manifest (FR-B8-2-001 → 010)

##### FR-B8-2-001 — sha256 manifest committed
A manifest `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` MUST
be committed, containing the sha256 of the frozen `1.0.0.tar.gz` in a format
parseable by `shasum -a 256 -c` (i.e. `<hex>  1.0.0.tar.gz`).

##### FR-B8-2-002 — manifest matches the live tarball at authoring time
The committed sha256 MUST equal the sha256 of the committed tarball
(`1d0b05cd…cd45` as observed 2026-05-30). Computed from the live file, never
transcribed (Article III.4).

##### FR-B8-2-003 — tarball is NOT rebuilt
The change MUST NOT run `forge-snapshot.sh build` for 1.0.0 nor otherwise
mutate `1.0.0.tar.gz`. The artifact is frozen as-is. (Rebuild would change
bytes via SOURCE_DATE_EPOCH for no semantic gain.)

#### Cluster 2 — Immutability guard (FR-B8-2-010 → 030)

##### FR-B8-2-010 — guard harness exists
`.forge/scripts/tests/b8-2.test.sh` MUST exist, follow the `--level`
convention, emit the standard summary, exit non-zero on failure.

##### FR-B8-2-011 — sha guard (the point-of-no-return protection)
L1 MUST assert the committed `1.0.0.tar.gz` sha256 equals the committed
`1.0.0.sha256` manifest. This FAILS if the tarball is ever rebuilt or
corrupted (e.g. accidentally rebuilt with 2.0.0 templates after they land).

##### FR-B8-2-012 — tarball present + extractable (re-assert)
L1 MUST assert the frozen tarball is present and extractable via
`forge-snapshot.sh extract full-stack-monorepo 1.0.0 <tmp>` (re-asserting the
A.7 reverse path independently of `a7.test.sh`).

##### FR-B8-2-013 — negative: corrupted tarball fails the guard
The guard MUST be proven to FAIL on a corrupted/rebuilt copy (verified at
implement by mutating a temp copy + pointing the check at it, then restoring).

##### FR-B8-2-014 — freeze-policy reachability
L1 MUST assert the maintenance-freeze section exists in
`global/upgrade-policy.md` and the REVIEW.md ledger entry is present + dated.

#### Cluster 3 — Freeze policy (FR-B8-2-020 → 030)

##### FR-B8-2-020 — maintenance-freeze section in upgrade-policy.md
`global/upgrade-policy.md` MUST gain a section stating: (a) `full-stack-monorepo
/ 1.0.0` is in maintenance-freeze as of B.8.2; (b) no further 1.0.0 template
edits — all changes target 2.0.0; (c) the 2.0.0 snapshot MUST build to
`2.0.0.tar.gz` (a new file), never overwriting `1.0.0.tar.gz`; (d) a
deliberate, audited 1.0.0 patch updates tarball + manifest together (the guard
catches accidental drift, not audited bumps).

##### FR-B8-2-021 — REVIEW.md ledger entry
`.forge/standards/REVIEW.md` MUST gain an append-only entry dated 2026-05-30
recording the `upgrade-policy.md` freeze-section addition (B.8.2).

##### FR-B8-2-022 — version-keyed path preserved (NOT legacy/)
The reverse target MUST remain `.forge/scaffold-snapshots/full-stack-monorepo/
1.0.0.tar.gz` (the path `forge-upgrade.sh:279` reads). No `legacy/` directory
is introduced (ADR-B8-2-001); the plan's `legacy/` wording is reconciled in
the doc/standard.

#### Cluster 4 — Integration (FR-B8-2-040 → 050)

##### FR-B8-2-040 — CI registration ≤ 300 lines
`b8-2.test.sh` MUST be registered in `forge-ci.yml::harness`; total ≤ 300
lines (3-comment compression per ADR-T533-002 as needed).

##### FR-B8-2-041 — CHANGELOG entry
A `[Unreleased]` CHANGELOG entry MUST cite `b8-2-legacy-snapshot` + B.8.2
(grep whole file per the changelog-test lesson — see [[changelog_test_unreleased_coupling]]).

##### FR-B8-2-042 — consolidated spec
`.forge/specs/b8-legacy-snapshot.md` MUST be created for `FR-B8-2-*`.

### Non-Functional Requirements

##### NFR-B8-2-001 — hermetic + fast L1
`b8-2.test.sh --level 1` MUST run with zero network/Docker, ≤ 5 s.

##### NFR-B8-2-002 — no migration code, no template/schema mutation
The change MUST NOT edit `.forge/templates/**` or `.forge/schemas/**`. It DOES
touch `.forge/standards/global/upgrade-policy.md` + `REVIEW.md` (ADR-3) — the
only standard surface. `git diff --name-only` verified in review.

##### NFR-B8-2-003 — tarball byte-identity preserved
`1.0.0.tar.gz` sha256 MUST be unchanged by this change (FR-B8-2-003).

##### NFR-B8-2-004 — backward compatibility
`a7.test.sh` MUST stay GREEN (snapshot present/extractable/BASE-recovery
unaffected; the frozen artifact is the same one a7 already exercises).

## BDD Acceptance Criteria

```gherkin
Scenario: The 1.0.0 reverse target is tamper-evident after 2.0.0 templates land
  Given the frozen full-stack-monorepo/1.0.0.tar.gz and its committed sha256 manifest
  When the immutability guard runs in CI
  Then it passes while the tarball matches the manifest
  And it fails if the tarball is rebuilt or corrupted (e.g. overwritten with 2.0.0 content)
  And forge upgrade can still recover the 1.0.0 BASE from the version-keyed path
```

## Anti-Hallucination Pass

- **`legacy/` reconciliation** — the plan's `legacy/` dir does not match the
  live `forge-upgrade.sh:279` version-keyed BASE path; spec keeps the
  version-keyed path (FR-B8-2-022). Grounded, not assumed.
- **upgrade-policy.md has no `version:` field** — verified; the "bump" is a
  section + REVIEW.md ledger, not a semver increment. No fabricated version.
- **sha256** — computed from the live committed tarball, not transcribed.
- **[NEEDS CLARIFICATION]** — none inline; ADRs 1-4 resolve the open
  questions at design.

## Open Questions

Tracked in `open-questions.md`: Q-001 (legacy/ vs version-keyed → ADR-B8-2-001,
leaning version-keyed), Q-002 (manifest format → ADR-B8-2-002, leaning sibling
`.sha256`), Q-003 (freeze-policy home → **answered: upgrade-policy.md section +
REVIEW ledger**, maintainer decision 2026-05-30), Q-004 (flagship-only vs
mobile → ADR-B8-2-004, leaning flagship-only).
