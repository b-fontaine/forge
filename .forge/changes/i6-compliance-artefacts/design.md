# Design: i6-compliance-artefacts
<!-- Status: designed -->
<!-- Schema: default -->

> Read alongside `specs.md` (FR-I6-CA-* / NFR-I6-CA-*) and
> `open-questions.md` (Q-001..Q-003). This document locks the
> implementation strategy and resolves Q-001 / Q-002 / Q-003 via
> ADR-I6-CA-001..003.

## Architecture Decisions

### ADR-I6-CA-001 — Bundle archive format : `.tgz` (gzip POSIX tar) (resolves Q-001)

**Context** : Q-001 weighed three candidate archive formats :

- **Option A — `.tgz`** : gzip-compressed POSIX tar. Python stdlib
  `tarfile.open(..., "w:gz")`. Determinism requires :
  - Per-member `mtime` pinned to `SOURCE_DATE_EPOCH` (or 0).
  - Per-member `uid/gid/uname/gname` normalised (set to 0 / "root"
    or empty).
  - Per-member `mode` normalised (typical 0o644 for files).
  - Gzip header `mtime` field set to 0 (Python `gzip.GzipFile`
    sub-handle).
- **Option B — `.tar`** : uncompressed POSIX tar. Same determinism
  pins as Option A minus the gzip header. Bigger output but simpler
  to reason about.
- **Option C — `.zip`** : ZIP archive. Python stdlib `zipfile`.
  Determinism is HARDER : per-member `date_time` is a tuple, not a
  POSIX timestamp ; the `ZipInfo.compress_type` default is
  `ZIP_STORED` which is reproducible, but `ZIP_DEFLATED` deflate
  level is implementation-defined and can drift across Python
  versions.

**Decision** : **Option A — `.tgz` (gzip POSIX tar)**. Two
arguments :

1. **Precedent** : the J.8.d SBOM ships as JSON (no archive) but the
   pattern across Forge artefacts that DO bundle (e.g. the future I.5
   workflow upload-artifact step) is `.tgz`. Auditors expect a
   `.tgz` from the regulatory-compliance niche (NIS2 / DORA / CRA
   guidance regularly cites `.tgz` as the canonical hand-off format).
2. **Determinism feasibility** : Python `tarfile` + `gzip` ship the
   knobs needed to pin every relevant byte. The
   `Reproducible-Builds project` documents the recipe precisely
   ; the Forge script applies it verbatim. ZIP requires hand-rolling
   `ZipInfo` per-member which is brittle.

**Consequences** :
- ✅ Auditors get a familiar `.tgz`.
- ✅ Python stdlib only ; no external dependency.
- ✅ Byte-identical output reproducible with `SOURCE_DATE_EPOCH=0`.
- ⚠️ `tarfile.open(mode="w:gz")` defaults set the gzip header
  `mtime` to the current time. The bundle script MUST use the
  two-step idiom :
  ```python
  buf = io.BytesIO()
  with tarfile.open(fileobj=buf, mode="w") as tar: ...
  with open(output_path, "wb") as out:
      with gzip.GzipFile(fileobj=out, mode="wb", mtime=epoch) as gz:
          gz.write(buf.getvalue())
  ```
  to control the gzip `mtime` explicitly.

**Constitution Compliance** : Article III.4 (anti-hallucination —
the Reproducible-Builds recipe is well-documented and not invented
here). Article XI.3 (schema-driven — `.tgz` is a well-defined
schema with stable interop).

---

### ADR-I6-CA-002 — Audit ledger snapshot location : `audit/` subdirectory at bundle root (resolves Q-002)

**Context** : Q-002 weighed two locations for the audit ledger
snapshot files inside the bundle :

- **Option A — flat at bundle root** :
  `audit-ledger.json` + `audit-ledger.md` next to `MANIFEST` and
  the `sbom.cdx.json`.
- **Option B — subdirectory** :
  `audit/audit-ledger.json` + `audit/audit-ledger.md` grouped
  inside an `audit/` folder.

**Decision** : **Option B — subdirectory** `audit/`. The bundle
already organises members by domain :

- `tier-matrix/compliance-tiers.md`
- `templates/forge-dpa-declared.template`
- `audit/audit-ledger.{json,md}` ← (this ADR)
- `sbom/sbom.cdx.json`
- `MANIFEST`

The `MANIFEST` stays at root (it's the index, not a domain
member). Five domain-grouped subdirectories + the index follows
the same pattern as how `examples/` is laid out in the Forge repo
itself : every domain has its own folder.

**Consequences** :
- ✅ Bundle structure self-documents.
- ✅ Adding Themis-territory artefacts (T7+) drops them into a new
  `regulatory/` subdirectory without renaming existing members.
- ✅ Mirrors auditor-side tooling conventions (auditors `cd audit/`
  to inspect the ledger separately from the SBOM).

**Constitution Compliance** : Article V (audit trail —
domain-grouped layout aids traceability). Article XI.3
(schema-driven — content schema lives at directory + filename level).

---

### ADR-I6-CA-003 — Script location : `.forge/scripts/compliance/bundle.sh` (resolves Q-003)

**Context** : Q-003 weighed two script locations :

- **Option A — `.forge/scripts/compliance/bundle.sh`** : nested
  under `.forge/scripts/` (sibling of `verify.sh`,
  `constitution-linter.sh`, `validate-foundations.sh`). New
  `compliance/` subdirectory.
- **Option B — `bin/forge-compliance-bundle.sh`** : sibling of
  `bin/forge-sbom.sh`, `bin/forge-demeter-scan.sh`,
  `bin/forge-snapshot.sh`. Flat layout matches the existing `bin/`
  directory.

**Decision** : **Option A —
`.forge/scripts/compliance/bundle.sh`**. Two arguments :

1. **The script's purpose is framework-internal orchestration**, not
   an adopter-facing CLI. `bin/forge-*.sh` scripts are invoked by
   adopters directly against their own project trees
   (`forge-sbom.sh`, `forge-demeter-scan.sh`, `forge-snapshot.sh`).
   The bundle script primarily ships as part of Forge's own
   regulatory hand-off ; adopters who consume it transparently invoke
   it via the future I.5 workflow. Putting it under
   `.forge/scripts/compliance/` signals "framework internal,
   not part of the adopter CLI surface" — same way
   `verify.sh` lives there.
2. **The mission brief explicitly suggests this path**
   (`.forge/scripts/compliance/bundle.sh`). Honouring the brief.

**Consequences** :
- ✅ Clear separation between adopter-facing CLI (`bin/`) and
  framework-internal scripts (`.forge/scripts/`).
- ✅ Future siblings (e.g. `.forge/scripts/compliance/sign.sh` for
  Sigstore signing) drop into the same subdirectory.
- ⚠️ The path is one level deeper than `bin/`. Documentation MUST
  spell it out (the standard's `## Consumption protocol` H2 + the
  `docs/COMPLIANCE.md` H2 both quote the full path).

**Constitution Compliance** : Article XII (governance — the
adopter CLI vs framework-internal split is a structural decision
preserved across the corpus).

---

## Implementation strategy

### Phase 1 — RED harness (foundation)

Create `.forge/scripts/tests/i6.test.sh` with 14 L1 + 2 L2 stubs
all returning `_not_implemented`. Register in `forge-ci.yml`
matrix immediately after `i2.test.sh`.

Exit gate : `bash .forge/scripts/tests/i6.test.sh --level 1,2`
exits 1 with `Failed: 16 / Passed: 0`. `verify.sh` overall PASS
unchanged.

### Phase 2 — Script + template (production code)

Author `.forge/scripts/compliance/bundle.sh` per FR-I6-CA-001..020 +
NFR-I6-CA-004..006. Author
`.forge/templates/compliance/forge-dpa-declared.template` per
FR-I6-CA-030..035.

Exit gate : 6 of 16 tests flip GREEN (script-presence /
help / args / template tests).

### Phase 3 — Standard + index + REVIEW + docs

Author `.forge/standards/global/compliance-artefacts-bundle.md`
per FR-I6-CA-040..055. Register in `index.yml` per
FR-I6-CA-060..064. Append entry to `REVIEW.md` per
FR-I6-CA-070..071. Extend `docs/COMPLIANCE.md` per
FR-I6-CA-080..082.

Exit gate : 12 of 16 tests GREEN (standard + index + REVIEW +
docs/COMPLIANCE).

### Phase 4 — Roadmap + plan + CHANGELOG

Update `docs/new-archetypes-plan.md` row I.6 per FR-I6-CA-090.
Update `.forge/product/roadmap.md` per FR-I6-CA-091. Update
`CHANGELOG.md [Unreleased]` per FR-I6-CA-092.

Exit gate : 14 of 16 tests GREEN. Two remaining tests are the
L2 fixtures.

### Phase 5 — L2 fixtures + final gates

L2 tests run against the worktree itself (real
`.forge/standards/global/compliance-tiers.md`, real
`bin/forge-sbom.sh`). The determinism test runs the bundle twice
with `SOURCE_DATE_EPOCH=0` on a tmpdir copy of a minimal source
tree, then `diff -q`s the two outputs.

Exit gate : all 16 tests GREEN. `verify.sh` overall PASS
(no FAIL ; Passed total ≥ 185). `constitution-linter.sh` OVERALL
PASS. Status flipped to `implemented`. Ready for `/forge:archive`.

---

## L1 / L2 test catalogue

### L1 (14 tests — hermetic, ≤ 5 s total)

| # | Test name                              | FR/NFR ID                                              |
|---|----------------------------------------|--------------------------------------------------------|
| 1 | `_test_i6_001_script_presence`         | FR-I6-CA-001                                           |
| 2 | `_test_i6_002_script_help_exit_zero`   | FR-I6-CA-004                                           |
| 3 | `_test_i6_003_script_audit_comment`    | FR-I6-CA-002                                           |
| 4 | `_test_i6_004_script_bogus_arg_exit_2` | FR-I6-CA-005                                           |
| 5 | `_test_i6_010_template_presence`       | FR-I6-CA-030                                           |
| 6 | `_test_i6_011_template_example`        | FR-I6-CA-032 / FR-I6-CA-031 / FR-I6-CA-033 / FR-I6-CA-034 |
| 7 | `_test_i6_020_standard_presence`       | FR-I6-CA-040 / FR-I6-CA-043                            |
| 8 | `_test_i6_021_standard_frontmatter`    | FR-I6-CA-044                                           |
| 9 | `_test_i6_022_standard_h2_sections`    | FR-I6-CA-045                                           |
|10 | `_test_i6_023_standard_must_not`       | FR-I6-CA-050                                           |
|11 | `_test_i6_030_index_entry`             | FR-I6-CA-060 / FR-I6-CA-061 / FR-I6-CA-062 / FR-I6-CA-063 |
|12 | `_test_i6_031_review_entry`            | FR-I6-CA-070                                           |
|13 | `_test_i6_040_compliance_doc_h2`       | FR-I6-CA-080 / FR-I6-CA-081                            |
|14 | `_test_i6_041_changelog_entry`         | FR-I6-CA-092                                           |

### L2 (2 fixture-based tests)

| # | Test name                          | FR/NFR ID                          |
|---|------------------------------------|------------------------------------|
| 1 | `_test_i6_l2_bundle_good`          | FR-I6-CA-008 / FR-I6-CA-009 / FR-I6-CA-013 / FR-I6-CA-014 |
| 2 | `_test_i6_l2_bundle_determinism`   | NFR-I6-CA-005                      |

The L2 good-bundle test :
1. Creates a tmpdir.
2. Copies the necessary source artefacts (compliance-tiers.md,
   the DPA template, two minimal `.forge.yaml` change files
   with `status: archived`, a minimal REVIEW.md) plus a minimal
   `bin/forge-sbom.sh` stub OR the real script.
3. Runs `bash .forge/scripts/compliance/bundle.sh --target <tmpdir>
   --output <tmpdir>/bundle.tgz`.
4. Asserts exit 0 + `bundle.tgz` present.
5. Asserts the tarball contains the 6 expected members.
6. Asserts `MANIFEST` is sorted + has 5 non-MANIFEST entries.

The L2 determinism test :
1. Same source tree as the good test.
2. Runs the bundle twice with `SOURCE_DATE_EPOCH=0`, output to
   `bundle1.tgz` and `bundle2.tgz`.
3. Asserts both runs exit 0.
4. Asserts `diff -q bundle1.tgz bundle2.tgz` exits 0
   (byte-identical).

---

## Dependencies on shipped state

| Dep                                     | Version / archive date           | Bundle consumes                                                       |
|-----------------------------------------|----------------------------------|-----------------------------------------------------------------------|
| `i2-compliance-tiers`                   | archived 2026-05-12              | `.forge/standards/global/compliance-tiers.md` v1.0.0 (tier matrix)    |
| `k3-demeter`                            | archived 2026-05-12              | `.forge/.forge-dpa-declared` format (ADR-K3-002) mirrored in template |
| `j8-janus-rules`                        | archived 2026-05-10              | `bin/forge-sbom.sh` invoked by bundle for SBOM member ; pattern reuse |
| `t4-adr-ratification`                   | archived 2026-05-04              | `compliance-tier.schema.json` v1.0.0 transitively via I.2             |

No new external dependency.

---

## Out of scope (deferred)

- **NIS2 / DORA / CRA / AI Act regulatory deadlines** under
  `.forge/compliance/{nis2,dora,cra,ai-act}/*`. These need
  Themis (K.5, T7+) to maintain ; deferred. The bundle schema
  v1.0.0 will absorb them additively when Themis ships (no major
  bump — covered by FR-I6-CA-053 forward-compatibility note).
- **SBOM signing** (Sigstore cosign), transparency-log upload
  (Rekor), vulnerability cross-references. Out of scope per
  `global/sbom-policy.md::Out-of-scope`.
- **Multi-archetype variants** of the bundle. For now, a single
  invariant bundle ships. Future archetype-aware variants are a
  potential J-module extension.
- **Adopter project-level bundles** at I.6 v1.0.0 the bundle
  targets the **framework's own posture** (Forge as a project).
  Adopter projects can run the same script against their own
  trees, but the bundle layout is identical — no per-project
  customisation surface.

---

## Constitutional Compliance per Article

- **Article I (TDD)** — Phase 1 captures full RED witness (16
  tests FAIL) before any production code.
- **Article II (BDD)** — Gherkin scenarios in `proposal.md` cover
  the four user-facing flows (bundle good-path, determinism,
  missing artefact, `--help`).
- **Article III.4 (anti-hallucination)** — Three Q-NNN tracked
  and resolved at design time ; no inline `[NEEDS CLARIFICATION:]`
  marker in `proposal.md` / `specs.md` / this file.
- **Article V (audit trail)** — every task tagged
  `[Story: FR-I6-CA-XXX]` in `tasks.md` ; script + template +
  standard + harness all carry the `<!-- Audit: I.6 (...) -->`
  anchor.
- **Article VIII (infrastructure)** — script is one-shot bash +
  Python 3 inline ; no service / daemon / privileged ops.
- **Article XI (AI-first)** — Demeter consumes audit ledger
  snapshot ; structured JSON ; no opaque LLM content.
- **Article XII (governance)** — the standard ENFORCES the bundle
  content schema + determinism guarantee ; does NOT amend any
  Article. Extensions follow `global/standards-lifecycle.md`
  SemVer.

No constitutional amendment required.
