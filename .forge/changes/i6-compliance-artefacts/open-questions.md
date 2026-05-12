# Open Questions — i6-compliance-artefacts

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: Bundle archive format — `.tgz` vs `.tar` vs `.zip`?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I6-CA-012
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The bundle ships in one of three candidate archive formats. Each
has different determinism characteristics under Python stdlib :

- **Option A — `.tgz`** : `tarfile.open(mode="w:gz")`. Determinism
  requires pinning per-member `mtime`, `uid/gid`, `mode`, and the
  gzip header `mtime`. Well-documented recipe via
  Reproducible-Builds project.
- **Option B — `.tar`** : uncompressed POSIX tar. Same pins minus
  gzip header. Bigger output but simpler.
- **Option C — `.zip`** : `zipfile.ZipFile`. `ZIP_STORED` is
  reproducible ; `ZIP_DEFLATED` introduces implementation-defined
  compression-level drift across Python versions.

Trade-off : A is the EU regulator-common format (NIS2 / DORA / CRA
guidance regularly references `.tgz`). B is simpler but doubles
the size. C is the most Windows-friendly but harder to make
deterministic in stdlib.

Lean **A** because regulators expect `.tgz` and the
Reproducible-Builds recipe is well-known.

### Resolution

**Resolved by ADR-I6-CA-001** in `design.md`. Decision :
**Option A — `.tgz` (gzip POSIX tar)**. Python stdlib `tarfile` +
`gzip` ship the knobs to pin every relevant byte. The bundle
script uses the two-step idiom (`tarfile.open(fileobj=BytesIO,
mode="w")` then `gzip.GzipFile(..., mtime=epoch)`) to control the
gzip header `mtime` explicitly.

---

## Q-002: Audit ledger snapshot location inside the bundle — flat vs subdirectory?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I6-CA-008
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The bundle carries `audit-ledger.json` + `audit-ledger.md`. They
live at one of :

- **Option A — flat at bundle root** :
  `audit-ledger.json` + `audit-ledger.md` next to `MANIFEST` /
  `sbom.cdx.json`.
- **Option B — subdirectory** :
  `audit/audit-ledger.{json,md}` inside an `audit/` folder.

Trade-off : A is fewer paths but mixes domains at root. B
self-documents but introduces a directory layer.

Lean **B** because the bundle already has four other domains
(tier-matrix, templates, sbom, audit) — grouping them per domain
mirrors the Forge repo's own layout and aids auditor-side tooling
that `cd`s into specific subdirectories.

### Resolution

**Resolved by ADR-I6-CA-002** in `design.md`. Decision :
**Option B — subdirectory** `audit/`. Final bundle layout :

```
forge-compliance-artefacts.tgz
├── MANIFEST
├── tier-matrix/compliance-tiers.md
├── templates/forge-dpa-declared.template
├── audit/audit-ledger.json
├── audit/audit-ledger.md
└── sbom/sbom.cdx.json
```

Six members. Domain-grouped. `MANIFEST` stays at root as the
index. Future Themis-territory artefacts drop into a new
`regulatory/` subdirectory without renaming existing members.

---

## Q-003: Script location — `.forge/scripts/compliance/` vs `bin/`?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I6-CA-001
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The bundle script ships at one of :

- **Option A — `.forge/scripts/compliance/bundle.sh`** : nested
  under `.forge/scripts/` (sibling of `verify.sh`,
  `constitution-linter.sh`, `validate-foundations.sh`). New
  `compliance/` subdirectory.
- **Option B — `bin/forge-compliance-bundle.sh`** : sibling of
  `bin/forge-sbom.sh`, `bin/forge-demeter-scan.sh`,
  `bin/forge-snapshot.sh`. Flat under `bin/`.

Trade-off : A signals "framework-internal orchestration". B
matches the existing adopter-CLI surface convention (every script
under `bin/` is one of the adopter-facing `forge-*.sh` family).

Lean **A** because the bundle is primarily consumed by
framework-internal orchestration (the future I.5 workflow). It is
not a primary adopter-CLI entry point in the way
`forge-sbom.sh` / `forge-demeter-scan.sh` are.

### Resolution

**Resolved by ADR-I6-CA-003** in `design.md`. Decision :
**Option A — `.forge/scripts/compliance/bundle.sh`**.

The mission brief explicitly suggests this path (`.forge/scripts/compliance/bundle.sh`).
The `.forge/scripts/` directory is reserved for framework-internal
orchestration (`verify.sh`, `constitution-linter.sh`,
`validate-foundations.sh`, `validate-change-yaml.sh`). The bundle
script joins them under a new `compliance/` subdirectory. Future
siblings (e.g. a Sigstore-signing wrapper) drop into the same
subdirectory without polluting `bin/`.
