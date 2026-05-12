# Proposal: i6-compliance-artefacts
<!-- Created: 2026-05-12 -->
<!-- Schema: default -->

## Problem

`docs/new-archetypes-plan.md` §7.1 lines 738-743 lists item **I.6** as
the *regulatory artefacts bundle* — the deliverable that gives Forge
adopters a single, downloadable, byte-stable archive of every
compliance-relevant artefact the framework already carries, so that
adopters can hand the archive to internal audit, external auditors, or
regulator counter-parties without manually re-assembling the surface
each time.

Today the compliance surface is **fully shipped but scattered** :

1. **Tier matrix** — `.forge/standards/global/compliance-tiers.md`
   v1.0.0 (I.2, archived 2026-05-12) carries the 15-row Component
   Eligibility Matrix verbatim from
   `docs/ARCHITECTURE-TARGET.md` §10.2. The matrix is the canonical
   reference an auditor consults to verify a project's tier posture.
2. **DPA declaration ledger format** — K.3 (`k3-demeter` archived
   2026-05-12) defined the `.forge/.forge-dpa-declared` ledger
   (ADR-K3-002), but no **template** ships at the framework level.
   Adopters reading the K.3 standard learn the format ; nothing
   gives them a ready-to-fill file with the canonical comment header
   + an example line + remediation notes.
3. **Audit ledger snapshot** — Forge's audit trail is structurally
   distributed across :
   - `.forge/changes/*/.forge.yaml` (one file per archived change,
     carrying `status: archived` + ISO-8601 timeline + parent audit
     items).
   - `.forge/standards/REVIEW.md` (append-only standards review
     ledger).
   - `.forge/standards/global/data-stewardship-rules.md` +
     `janus-orchestration-rules.md` (rule catalogues).
   - The git commit history.
   An auditor receiving the *current state* of a Forge project needs
   a **point-in-time snapshot** of all four surfaces collapsed into
   a single machine-parseable JSON document plus a human-readable
   Markdown summary, both reproducible byte-for-byte when
   `SOURCE_DATE_EPOCH` is set.
4. **SBOM** — `bin/forge-sbom.sh` (J.8.d, archived 2026-05-10) already
   produces a CycloneDX 1.5 SBOM. The SBOM is regulatory-relevant
   (NIS2 / DORA / CRA per `global/sbom-policy.md`) and belongs in
   the same hand-off package as the DPA template + audit ledger +
   tier matrix.

The pattern auditors expect — a single `.tgz` with everything in it,
checksummed, reproducible — does not exist today. Adopters tar things
up by hand each time, with no guarantee of byte-stability or
content-completeness.

This change closes the gap by shipping :

- A new script `.forge/scripts/compliance/bundle.sh` that produces
  a deterministic `forge-compliance-artefacts.tgz` containing the
  four artefacts above (DPA template + audit ledger snapshot + tier
  matrix + SBOM) plus a `MANIFEST` listing every member + their
  SHA-256 checksums.
- A new DPA template file
  `.forge/templates/compliance/forge-dpa-declared.template` that
  ships the canonical comment header + example line + remediation
  notes, mirroring the J.8 `.forge/.forge-tier` template precedent.
- A new audit ledger snapshot generator (inline inside
  `bundle.sh`) that reads the four existing surfaces (no
  duplication of the underlying data) and emits a snapshot.
- A new test harness `.forge/scripts/tests/i6.test.sh` with ≥ 14
  L1 hermetic tests + 2 L2 fixture-based determinism tests.
- A new standard
  `.forge/standards/global/compliance-artefacts-bundle.md`
  documenting the bundle's purpose, content schema, determinism
  guarantee, and consumption protocol downstream (I.5
  `forge-compliance.yml` will eventually consume this bundle ; the
  standard scopes the contract).
- Updates to `docs/new-archetypes-plan.md` row I.6 and
  `.forge/product/roadmap.md` inventory to record the delivery.

The scope is deliberately **narrower** than the original I.6 plan
(NIS2 / DORA / CRA / AI Act deadlines artefacts under
`.forge/compliance/`). Those deadlines artefacts require **Themis**
(K.5, T7+) to maintain — the dates change every quarter and a BDFL
manual-curation regime is not sustainable. This change ships the
**bundle generator + content schema** so the moment Themis ships, the
NIS2 / DORA / CRA / AI Act files drop into the same bundle without a
bundle-format change.

## Solution

A single Bash + Python 3 inline script under `.forge/scripts/compliance/`
that walks the framework tree, collects the four artefacts, normalises
them into a deterministic directory layout, and emits a `.tgz`. Five
coordinated sub-modules :

### I.6.a — Bundle generator (`.forge/scripts/compliance/bundle.sh`)

Pattern : bash thin + Python 3 inline. Mirrors `bin/forge-sbom.sh`
(F.2 / J.7 / J.8.d) verbatim per NFR-I6-CA-004.

Signature :

```
bash .forge/scripts/compliance/bundle.sh \
  [--output <path>] \
  [--target <dir>] \
  [--help|-h]
```

Defaults : `--output forge-compliance-artefacts.tgz`,
`--target $(pwd)`.

Exit codes :
- `0` — bundle written successfully.
- `1` — missing source artefact (e.g.
  `.forge/standards/global/compliance-tiers.md` absent at target).
- `2` — usage error (bad args, target not a directory).

Determinism : when `SOURCE_DATE_EPOCH` is set (POSIX env var, integer
Unix timestamp), the tar entries' mtime, the bundle's internal
`MANIFEST` timestamps, and the gzip header MUST be set so that two
consecutive runs produce byte-identical `.tgz` files. The harness
asserts this via two runs with `SOURCE_DATE_EPOCH=0` + `diff -q`.

### I.6.b — DPA template

A new file
`.forge/templates/compliance/forge-dpa-declared.template` with :

- Comment header citing K.3 ADR-K3-002 (DPA ledger format) +
  `global/data-stewardship-rules.md` (§ "DPA declaration semantics")
  + RGPD Article 28 (data processing agreement).
- An example line in the canonical format
  `T1: 2026-04-15 LegalOps-Confluence-DPA-2026-Q2`.
- Remediation notes : staleness check (13-month RGPD review +
  1-month grace), what Demeter parses vs what it doesn't, the
  K3-RULE-002 trigger condition.

The bundle copies this file into the `.tgz` at path
`templates/forge-dpa-declared.template`.

### I.6.c — Audit ledger snapshot

Inline Python inside `bundle.sh` reads the four audit-trail surfaces
listed in the Problem section and emits :

- `audit-ledger.json` — machine-parseable, sorted keys, `indent=2`
  + trailing newline. Schema :
  ```json
  {
    "schema_version": "1.0.0",
    "generated_at": "<ISO-8601 UTC>",
    "framework_version": "<from VERSION file>",
    "archived_changes": [{"name": "...", "archived": "...", "parent_audit_items": [...]}, ...],
    "standards_reviews": [{"date": "...", "title": "..."}, ...],
    "active_rule_catalogues": ["K3-RULE-001..006", "J8-RULE-001..003"]
  }
  ```
- `audit-ledger.md` — human-readable Markdown summary with three
  H2 sections : "Archived changes", "Standards reviews", "Active
  rule catalogues".

The snapshot is **read-only over the four existing surfaces** — no
duplication of the underlying data into a new persistent file.

### I.6.d — Standard
`.forge/standards/global/compliance-artefacts-bundle.md`

New Markdown standard documenting :

- Bundle purpose (auditor hand-off, regulator counter-party).
- Content schema (the six bundle members + their paths inside the
  `.tgz`).
- Determinism guarantee + how to verify (the
  `SOURCE_DATE_EPOCH` invariant).
- Consumption protocol downstream (I.5
  `forge-compliance.yml` will consume ; the bundle is a stable
  contract surface).
- Regeneration cadence (per release + on-demand + reproducibly).
- Interdictions (≥ 3 RFC-2119 MUST NOT clauses).

Frontmatter narrative block per the existing MD standards pattern
(`global/sbom-policy.md`, `global/janus-orchestration-rules.md`,
`global/data-stewardship-rules.md`, `global/compliance-tiers.md`).

### I.6.e — Standards index + REVIEW + docs

- `.forge/standards/index.yml` gains a new entry for the bundle
  standard.
- `.forge/standards/REVIEW.md` gains an append-only birth entry.
- `docs/COMPLIANCE.md` gains a fourth H2 section
  `## Auditor hand-off bundle` cross-linking the standard + the
  script + the test harness.
- `docs/new-archetypes-plan.md` row I.6 updated to record delivery.
- `.forge/product/roadmap.md` inventory updated.
- `CHANGELOG.md` `[Unreleased]` entry.

## Scope In

- New script `.forge/scripts/compliance/bundle.sh` (bash thin +
  Python 3 inline, deterministic `.tgz` emission).
- New template
  `.forge/templates/compliance/forge-dpa-declared.template`.
- New standard
  `.forge/standards/global/compliance-artefacts-bundle.md` v1.0.0
  (≥ 6 H2 sections, ≥ 3 MUST NOT clauses).
- New test harness `.forge/scripts/tests/i6.test.sh` (≥ 14 L1 +
  2 L2).
- New `.forge/standards/index.yml` entry.
- New `.forge/standards/REVIEW.md` append-only entry.
- `docs/COMPLIANCE.md` fourth H2 + cross-links.
- `docs/new-archetypes-plan.md` row I.6 status update.
- `.forge/product/roadmap.md` inventory delta.
- `CHANGELOG.md` `[Unreleased]` entry.
- `forge-ci.yml` matrix row registering `i6.test.sh` after `i2.test.sh`.

## Scope Out (Explicit Exclusions)

- **NOT** the I.3 T3-forbidden linter rule — separate parallel
  change (`i3-t3-forbidden-linter`).
- **NOT** the I.5 `forge-compliance.yml` GitHub workflow —
  separate change ; will consume this bundle later.
- **NOT** NIS2 / DORA / CRA / AI Act regulatory deadline artefacts
  under `.forge/compliance/{nis2,dora,cra,ai-act}/`. Those require
  Themis (K.5, T7+) to maintain ; deferred. The bundle SCHEMA in
  this change SHOULD accommodate them additively when Themis ships,
  but no Themis-territory file ships here.
- **NOT** any modification to J.8 `.forge-tier`, K.3
  `.forge-dpa-declared` parser semantics, or the
  `compliance-tier.schema.json`. Read-only consumption.
- **NOT** SBOM signing (Sigstore cosign), transparency-log upload
  (Rekor), vulnerability cross-references, or license enrichment.
  Out of scope per `global/sbom-policy.md::Out-of-scope`.
- **NOT** any constitutional amendment. Articles III.4, V, XI, XII
  preserved.
- **NOT** any new CLI surface in `cli/src/`. The bundle is invoked
  via `bash` ; no TypeScript plumbing.
- **NOT** any rewrite of the existing audit-trail surfaces. The
  snapshot is read-only over the four canonical sources.

## Impact

- **Users affected** :
  - Adopters handing a Forge project to auditors or regulator
    counter-parties get a single deterministic `.tgz` to ship.
  - I.5 `forge-compliance.yml` future workflow gets a stable
    contract surface to consume.
  - Themis (K.5, T7+) when it ships will append NIS2 / DORA / CRA /
    AI Act artefacts into the same bundle layout without a
    breaking change.
  - No change at all for adopters not running the bundle script
    (NFR-I6-CA-002 backward compat).
- **Technical impact** : ≈ 4 new files (script, template,
  standard, harness) + ≈ 5 modified (index.yml, REVIEW.md,
  COMPLIANCE.md, new-archetypes-plan.md, roadmap.md, CHANGELOG.md,
  forge-ci.yml). Test harness ≥ 14 L1 + 2 L2. **Effort `M`** per
  `new-archetypes-plan` §7.1 line 738.
- **Dependencies** :
  - **I.2** `i2-compliance-tiers` archived 2026-05-12 — ships the
    tier matrix the bundle copies.
  - **K.3** `k3-demeter` archived 2026-05-12 — ships the DPA
    ledger format the template mirrors.
  - **J.8** `j8-janus-rules` archived 2026-05-10 — ships
    `bin/forge-sbom.sh` whose F.2 / J.7 / J.8.d pattern this
    script reuses verbatim ; ships the SBOM the bundle copies.
  - No new external dependency. Bundle script uses `python3`
    stdlib `tarfile` + `hashlib` (already required by F.2 / J.7 /
    J.8.d).
- **Risk level** : **Low**. The script is read-only over the
  four existing artefact surfaces ; no schema bump, no
  CLI flag plumbing, no API. The only real risk is determinism
  drift — mitigated by the L2 fixture test that runs the bundle
  twice with `SOURCE_DATE_EPOCH=0` and asserts byte-identity.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`i6.test.sh` with ≥ 14 L1 + 2 L2 stubs all returning
`_not_implemented` (full RED witness). Phase 2 ships the script +
template. Phase 3 ships the standard. Phase 4 ships the index +
REVIEW + docs + CHANGELOG + CI. Phase 5 runs final gates.

### Article II — BDD

User-facing flows get Gherkin scenarios in `specs.md` :

```gherkin
Given a Forge project tree with the four canonical compliance artefacts
When the adopter runs bash .forge/scripts/compliance/bundle.sh
Then a forge-compliance-artefacts.tgz file is created at the project root
  And it contains the tier matrix, DPA template, audit ledger snapshot, and SBOM
  And it includes a MANIFEST listing every member with SHA-256 checksums

Given the same project tree
When the adopter runs the bundle script twice with SOURCE_DATE_EPOCH=0
Then both invocations produce byte-identical .tgz outputs

Given a project tree missing the compliance-tiers.md standard
When the adopter runs the bundle script
Then it exits 1 with "missing source artefact" on stderr

Given no arguments
When the adopter runs the bundle script with --help
Then it prints a usage block and exits 0
```

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-I6-CA-*` +
`NFR-I6-CA-*` namespace before any script authoring.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Three open questions Q-001 / Q-002 / Q-003 raised at this phase,
all tracked in `open-questions.md` and resolved during
`/forge:design`.

### Article V — Audit Trail

Each task tagged `[Story: FR-I6-CA-XXX]` (Article V.1, enforced by
`f4-linter-extension`). The standard file carries
`<!-- Audit: I.6 (i6-compliance-artefacts) -->`. The bundle script
header carries the same audit comment.

### Article VIII — Infrastructure

The script is a one-shot bash + Python 3 inline. No service, no
daemon, no privileged ops. The standard documents the regeneration
cadence.

### Article IX — Observability

N/A directly. The bundle is a spec-time / audit-time artefact, not
a runtime component. If a future CI workflow (I.5) wraps the
bundle, that workflow instruments itself per `observability.yaml`.

### Article XI — AI-First Design

The bundle is consumed by Demeter (XI.1 agent-native — Demeter
reads the audit ledger snapshot when classifying historical
posture) and by future Themis (K.5, T7+). The schemas are
deterministic structured documents (JSON + Markdown) — no opaque
LLM-generated content (XI.3 schema-driven preserved).

### Article XII — Governance

The standard ENFORCES the contract for the bundle's content schema
+ determinism guarantee. It does **not amend** any constitutional
article. Extensions (additional bundle members) follow
`global/standards-lifecycle.md` SemVer rules under BDFL governance
(Phase A) and Themis (Phase B, T7+).

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none in this `proposal.md`.

Three open questions Q-001 + Q-002 + Q-003 raised at this phase,
all tracked in `open-questions.md` and resolved during
`/forge:design` :

- **Q-001** — Bundle archive format : `.tgz` (gzip-compressed
  tarball) vs `.tar` (uncompressed) vs `.zip` ? Determinism
  considerations differ across formats.
- **Q-002** — Audit ledger snapshot location inside the bundle :
  flat (`audit-ledger.{json,md}` at bundle root) vs subdirectory
  (`audit/ledger.{json,md}`) ?
- **Q-003** — Bundle script location : `.forge/scripts/compliance/`
  vs `bin/forge-compliance-bundle.sh` (sibling of
  `bin/forge-sbom.sh`) ?
