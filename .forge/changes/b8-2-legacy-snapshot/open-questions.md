# Open Questions — b8-2-legacy-snapshot

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
-->

## Q-001: `legacy/` directory vs version-keyed snapshot path

- **Status**: answered
- **Raised in**: `specs.md` FR-B8-2-022
- **Raised on**: 2026-05-30
- **Raised by**: maintainer (b8-2 specify pass)

### Question

Plan §4.2 says archive to `.forge/scaffold-snapshots/legacy/`. But
`forge-upgrade.sh:279` reads BASE from `<archetype>/<from_version>.tar.gz`.
Introduce `legacy/`, or keep the version-keyed path?

- (a) **Keep version-keyed** `full-stack-monorepo/1.0.0.tar.gz` — forge-upgrade
  already reads it; no A.7 change. Lean here.
- (b) **Add `legacy/`** — requires a forge-upgrade.sh change to look there;
  scope creep + breaks the established BASE-recovery contract.

### Resolution

- **Resolved on**: 2026-05-30 (`/forge:design` → ADR-B8-2-001)
- **Decision**: Option (a) — keep version-keyed `full-stack-monorepo/1.0.0.tar.gz`. No `legacy/` dir.
- **Rationale**: `forge-upgrade.sh:279` already reads this path; `legacy/` would force an A.7 change + break the BASE-recovery contract.

---

## Q-002: Integrity manifest format

- **Status**: answered
- **Raised in**: `specs.md` FR-B8-2-001
- **Raised on**: 2026-05-30
- **Raised by**: maintainer (b8-2 specify pass)

### Question

- (a) **Sibling `1.0.0.sha256`** in `shasum -c` format. Simplest, greppable,
  re-checkable with stock tooling. Lean here.
- (b) **Richer `1.0.0.manifest.yaml`** (sha + byte size + frozen-at commit +
  source schema). More metadata, more surface.

### Resolution

- **Resolved on**: 2026-05-30 (`/forge:design` → ADR-B8-2-002)
- **Decision**: Option (a) — sibling `1.0.0.sha256` in `shasum -c` format.
- **Rationale**: stock-tooling verifiable, greppable, minimal surface; richer YAML deferred (YAGNI).

---

## Q-003: Freeze-policy home

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-3 seed)
- **Raised on**: 2026-05-30
- **Raised by**: maintainer (b8-2 propose pass)

### Question

Doc-only (`docs/B8-BASELINE.md`) vs bump `global/upgrade-policy.md`?

### Resolution

- **Resolved on**: 2026-05-30 (maintainer decision)
- **Decision**: **Bump `global/upgrade-policy.md`** — append a maintenance-freeze
  section + REVIEW.md ledger entry. (Note: that standard has no `version:`
  frontmatter, so no semver increment — section addition only.)
- **Rationale**: The freeze rule is normative for `forge upgrade`, so it
  belongs in the A.7-owned standard, enforced rather than merely documented.

---

## Q-004: Flagship-only vs also freeze mobile-only/1.0.0

- **Status**: answered
- **Raised in**: `proposal.md` (Scope)
- **Raised on**: 2026-05-30
- **Raised by**: maintainer (b8-2 propose pass)

### Question

Also freeze `mobile-only/1.0.0.tar.gz` (454.2 KB, exists)?

- (a) **Flagship-only** — matches plan §4.2; mobile freeze is B.9 territory.
  Lean here. Harness parameterized so B.9 adds a sibling manifest.
- (b) **Both** — pre-freeze mobile now. Scope creep; B.9 is T8.

### Resolution

- **Resolved on**: 2026-05-30 (`/forge:design` → ADR-B8-2-004)
- **Decision**: Option (a) — flagship-only; mobile-only freeze is B.9.
- **Rationale**: matches plan §4.2; harness keyed by archetype/version so B.9 adds a sibling manifest, no new harness.
