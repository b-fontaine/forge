# Open Questions — i2-compliance-tiers

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: `linter_rule:` value — kebab-case forward-pointer or null?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I2-CT-001 (frontmatter)
- **Raised on**: 2026-05-11
- **Raised by**: @bfontaine

### Question

The standard's frontmatter declares `linter_rule:` per
`.forge/schemas/standard.schema.json` (J.7) — either a non-null
kebab-case string referenced as a section anchor in
`constitution-linter.sh`, or explicit `null`. Two candidates :

- **Option A — kebab-case forward-pointer** :
  `linter_rule: t3-forbidden-components`. The actual linter
  function ships in I.3, but the standard already declares its
  future identity. Adopters reading the frontmatter learn what
  rule will enforce the constraint.
- **Option B — null** : `linter_rule: null` until I.3 ships,
  then bump v1.0.0 → v1.1.0 with the populated value.

Trade-off : A pre-allocates the kebab-case name and avoids a
version bump when I.3 ships, but creates a J.7 validator
violation (FR-J7-030 requires the kebab-case string to be
referenced as a section anchor in `constitution-linter.sh` —
the I.2 standard is MD not YAML so J.7 does not apply, but
the convention is mirrored). B is safer but doubles work.

Lean **A** because the standard file is MD (not YAML), so J.7
FR-J7-030 does not strictly apply ; the frontmatter is a
narrative block at the top of the file rather than parsed by
the validator. A clear forward-pointer is more informative for
reviewers than a null waiting to be populated.

### Resolution

**Resolved by ADR-I2-CT-001** in `design.md`. Decision :
**Option A — kebab-case forward-pointer**
`linter_rule: t3-forbidden-components`. The standard file is
Markdown, not YAML — J.7 `validate-standards-yaml.sh` does not
scan it. The frontmatter is narrative (not parsed). The
forward-pointer signals intent to reviewers and avoids a
version bump when I.3 ships. I.3's `tasks.md` will append the
matching section anchor in `constitution-linter.sh` to satisfy
the convention.

---

## Q-002: Matrix encoding — verbatim or condensed?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I2-CT-040 (matrix)
- **Raised on**: 2026-05-11
- **Raised by**: @bfontaine

### Question

`docs/ARCHITECTURE-TARGET.md` §10.2 carries a 15-row × 5-column
matrix : `Composant | T1 | T2 | T3 | Forçage tier | Source`.
Eight rows are "self-host compatible across all tiers" (Flutter,
Rust, Envoy, Postgres, DBOS, Coroot, OTel Collector, NATS),
seven rows carry tier-specific constraints (Zitadel, SigNoz,
OVH/Scaleway/Outscale, AWS/GCP/Azure, Firebase, Temporal,
LLM Gateway).

Two candidates :

- **Option A — verbatim 15 rows** : reproduce the matrix
  exactly as in `ARCHITECTURE-TARGET §10.2`. Adopters reading
  the standard see the full eligibility surface in one place.
  ≈ 15 lines of Markdown table.
- **Option B — condensed** : group the "compatible everywhere"
  rows into a single line ("All tiers : Flutter / Rust / Envoy
  / Postgres / DBOS / Coroot / OTel Collector / NATS"), then
  detail the 7 tier-sensitive rows individually. ≈ 9 lines.

Trade-off : A is the safer faithful-reproduction path (Demeter's
checklist cross-references the row count). B is more readable
but introduces a deviation from the architecture document that
adopters must mentally reconcile.

Lean **A** because the K.3 anti-hallucination protocol explicitly
requires Demeter to cite the matrix verbatim — any condensing
introduces a paraphrase surface that the K.3 standard forbids
(`FR-K3-DEM-020 precedent`). The standard's job is to be the
canonical narrative ; faithful reproduction beats condensation.

### Resolution

**Resolved by ADR-I2-CT-002** in `design.md`. Decision :
**Option A — verbatim 15 rows**. All 15 rows of
`ARCHITECTURE-TARGET §10.2` reproduced in the standard's
"Component eligibility matrix" H2 section. Each cell preserves
the exact emoji + text from the source (✅, ⚠️ T1 only, ❌,
⚠️ Cloud SaaS T1, etc.). The standard becomes a faithful mirror
of the architecture-document section, citable by Demeter and
Janus without paraphrase risk.

---

## Q-003: `docs/COMPLIANCE.md` placement — root or subdirectory?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I2-CT-090 (adopter doc)
- **Raised on**: 2026-05-11
- **Raised by**: @bfontaine

### Question

The new adopter-facing intro ships at one of two paths :

- **Option A — root `docs/COMPLIANCE.md`** : sibling to existing
  `docs/ARCHITECTURE-TARGET.md`, `docs/GUIDE.md`, `docs/CLI.md`,
  `docs/SCHEMA.md`, `docs/VERSIONING.md`. Discoverable via a
  flat `ls docs/`.
- **Option B — subdirectory `docs/compliance/README.md`** :
  groups with future I.6 regulatory artefacts (NIS2 / DORA /
  CRA / AI Act schedules) and future Themis (K.5) outputs.

Trade-off : A is the simpler shipping path, mirroring the existing
flat layout of `docs/`. B pre-allocates a grouping for future
artefacts but creates an inconsistency (one top-level doc moved
into a subdirectory while siblings stay flat).

Lean **A** because the I.6 grouping is speculative (Themis ships
T7+). When that grouping crystallises (I.6 actually ships), a
follow-up change can move `docs/COMPLIANCE.md → docs/compliance/`
with backward-compat redirects. Today, flat layout matches the
rest of `docs/`.

### Resolution

**Resolved by ADR-I2-CT-003** in `design.md`. Decision :
**Option A — root `docs/COMPLIANCE.md`**. Sibling to existing
top-level Forge docs. When I.6 ships and a `docs/compliance/`
subdirectory makes sense, a follow-up change moves the file
with stub redirects. Today, flat layout = consistency with
`docs/GUIDE.md`, `docs/CLI.md`, `docs/SCHEMA.md`,
`docs/VERSIONING.md`, `docs/ARCHITECTURE-TARGET.md`.
