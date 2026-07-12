# Specifications: b6-9-compliance

<!-- Status: planned (pre-implementation) -->
<!-- Schema: default -->

**Namespace** : `FR-B69-NIS2-*` (NIS2 artefacts) / `FR-B69-DORA-*` (DORA RoI
helper) / `FR-B69-SBOM-*` (SBOM wiring) / `FR-B69-BD-*` (bundle + standard +
index + harness + docs + lock-step) / `NFR-B69-*`. **Constitution** : v2.0.0 —
no amendment (spec-time artefacts + a helper script + a standard + an additive
bundle extension ; no Article touched).

## Source Documents

| Field                 | Value                                                                                                                                              |
|-----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**          | `docs/new-archetypes-plan.md` §6.1 line 2565-2566 (B.6.9) ; §7.1 line 2630-2631 (I.6 NIS2/DORA deadlines) ; §10.3 line 782 (`event-driven-eu` profile) |
| **Regulatory ground** | `docs/ARCHITECTURE-TARGET.md` §10.4 line 788-789 (NIS2 reporting 24h/72h ; DORA RoI 30 avr 2026 ESA) + §9.2 line 735 (Themis charter "incident reporting < 24h") + §10.3 line 782 (profile "NIS2 + DORA (si finance) + CRA") |
| **Archetype ground**  | `.forge/schemas/event-driven-eu/1.0.0.yaml` — `components:` (nats-jetstream / temporal / postgres / observability) + `event_specifics.eu_sovereignty` |
| **Bundle src**        | `i6-compliance-artefacts` — `.forge/scripts/compliance/bundle.sh` (walk tuple `("ai-act","dora")` `:381`, MANIFEST `:393`) + ADR-I6-CA-002 `regulatory/` reservation |
| **Bundle std**        | `.forge/standards/global/compliance-artefacts-bundle.md` v1.1.0 — `## Bundle content schema` table + "6 base + N regulatory members" + Interdiction #3 (NIS2/CRA reserved) + § Purpose (NIS2 supply-chain transparency) |
| **SBOM src**          | `bin/forge-sbom.sh` (J.8.d) — `_parse_cargo_lock` → CycloneDX 1.5 `pkg:cargo/...` purls ; the I.6 bundle `sbom/sbom.cdx.json` member |
| **Template prec**     | `b7-5-ai-act` — `.forge/compliance/{ai-act,dora}/*` artefacts + `ai-act-dora-artefacts.md` standard + `b7-5.test.sh` (structural mirror ; its `_test_b75_001` nis2-reserved assertion is amended in lock-step) |
| **DORA base**         | `.forge/compliance/dora/roi-register.template.yaml` (b7-5) — the RoI base the helper DRIVES (reads, never forks) |
| **Themis src**        | `k5-themis` — `.claude/agents/themis.md` + `bin/forge-review-standards.sh` (Phase-B maintainer ; already carries the NIS2/DORA calendar verbatim) |
| **Anti-hallucination**| Article III.4 ; `open-questions.md` Q-001..Q-005 ; `_test_b69_030` negative-grep (mirrors `b7-5.test.sh::_test_b75_030`) |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — NIS2 artefacts `.forge/compliance/nis2/` (FR-B69-NIS2-001 → 030)

##### FR-B69-NIS2-001 — Directory presence

The directory `.forge/compliance/nis2/` MUST exist and MUST contain the members
`incident-reporting.md`, `incident-report.template.yaml`,
`obligations-index.yaml`. The layout fills the I.6 forward-declared
`.forge/compliance/{nis2,dora,cra,ai-act}/` reservation (ADR-B69-001). The
`cra/` sibling MUST NOT be created (stays reserved).

##### FR-B69-NIS2-002 — Audit comment on every member

Every file under `.forge/compliance/nis2/` MUST carry an audit anchor
`<!-- Audit: B.6.9 (b6-9-compliance) -->` (or the `#`-comment form for YAML)
within its first 5 lines.

##### FR-B69-NIS2-010 — `incident-reporting.md` presence + grounded windows

A file `.forge/compliance/nis2/incident-reporting.md` MUST exist stating the
NIS2 major-incident reporting obligation. It MUST cite the **grounded**
reporting windows verbatim — **"24h/72h"** (`ARCHITECTURE-TARGET.md` §10.4 +
§7.1 I.6 bullet) — and the "< 24h" charter figure (§9.2). It MUST NOT invent any
other window figure.

##### FR-B69-NIS2-011 — `incident-reporting.md` operational-surface scoping + evidence linkage

`incident-reporting.md` MUST scope the obligation to the archetype's operational
surface — **NATS JetStream / Temporal / Postgres event-store** outage or breach
scenarios (grounded in `event-driven-eu/1.0.0.yaml` `components:`) — and MUST
link the obligation to the Forge evidence surfaces : the I.6 audit-ledger
snapshot + the IX.4 Rust OTel tracing spans (the archetype's SigNoz/OBI/Coroot
observability). It MUST carry a `[NEEDS CLARIFICATION]` marker for the precise
NIS2 reporting-stage breakdown (Q-001), tagged "Themis (K.5) to supply".

##### FR-B69-NIS2-012 — `incident-report.template.yaml` presence + skeleton

A file `.forge/compliance/nis2/incident-report.template.yaml` MUST exist as
valid YAML — an adopter-fillable NIS2 incident-notification skeleton (24h
early-warning + 72h notification fields) with `<FILL: ...>` placeholders scoped
to the event stack, and a `[NEEDS CLARIFICATION]` for the authoritative CSIRT
field schema (Q-001).

##### FR-B69-NIS2-013 — `obligations-index.yaml` presence + shape

A file `.forge/compliance/nis2/obligations-index.yaml` MUST exist as valid YAML
with `schema_version: "1.0.0"`, `regulation: nis2`, and an `obligations:` list
where each item carries `id`, `title`, `status`
(`satisfied` | `needs-clarification` | `deployer-assessed`), `satisfied_by`
(list, possibly empty), and an optional `source`. It MUST contain ≥ 2 grounded
`satisfied` obligations (`incident-reporting`, `supply-chain-security` — Q-003),
each with a non-empty `satisfied_by`, and ≥ 1 `needs-clarification` obligation
with `themis_owner: K.5`.

##### FR-B69-NIS2-030 — No fabricated legal citation

No file under `.forge/compliance/nis2/` MUST contain a NIS2/DORA Article number,
recital number, or precise date that is NOT either (a) traceable to a cited repo
source or (b) inside a `[NEEDS CLARIFICATION]` marker (Article III.4 — asserted
by the harness negative-grep test FR-B69-BD-102).

#### Cluster 2 — DORA RoI submission helper (FR-B69-DORA-001 → 020)

##### FR-B69-DORA-001 — Helper script presence + header

A file `.forge/scripts/compliance/dora-roi-helper.sh` MUST exist as executable
bash with the `#!/usr/bin/env bash` + `set -uo pipefail` header, an audit
comment `# Audit: B.6.9 (b6-9-compliance)` within its first 5 lines, a `usage()`
and `--help`/`-h` exit-0 path, and `--target` / `--output` argument parsing.

##### FR-B69-DORA-010 — Helper drives the b7-5 RoI base + specialises for the stack

Running `dora-roi-helper.sh` MUST read the b7-5
`.forge/compliance/dora/roi-register.template.yaml` base (DRIVE, never fork) and
emit an adopter-fillable RoI skeleton that enumerates the archetype's ICT
third-party provider categories grounded in `event-driven-eu/1.0.0.yaml` —
**NATS JetStream** (event-backbone), **Temporal** (orchestration), **Postgres**
(event-store) — as `<FILL: ...>` entries. It MUST carry a `[NEEDS CLARIFICATION]`
for the authoritative DORA RoI field schema (Q-002) and MUST cite the grounded
"30 avr 2026" ESA deadline. It MUST exit 0 on success, 1 on a missing base
template, 2 on usage error.

##### FR-B69-DORA-020 — No fabricated legal citation in helper output

The helper output MUST NOT contain a DORA article number or precise date beyond
the grounded "30 avr 2026" ESA deadline OR inside a `[NEEDS CLARIFICATION]`
marker (Article III.4).

#### Cluster 3 — SBOM wiring (FR-B69-SBOM-001 → 010)

##### FR-B69-SBOM-001 — SBOM rides the existing generator (grounded, no new code)

The new standard `global/nis2-dora-eda-artefacts.md` MUST document that
event-driven-eu SBOM CycloneDX auto-generation rides the existing
`bin/forge-sbom.sh` (Rust `Cargo.lock` → CycloneDX 1.5) + the I.6 bundle's
`sbom/sbom.cdx.json` member. `bin/forge-sbom.sh` MUST NOT be modified (Q-004).

##### FR-B69-SBOM-010 — SBOM mapped as the NIS2 supply-chain evidence surface

`nis2/obligations-index.yaml` MUST map the `supply-chain-security` obligation →
the CycloneDX SBOM evidence surface (`bin/forge-sbom.sh` + the I.6 bundle SBOM
member), grounded in `compliance-artefacts-bundle.md` § Purpose (NIS2
supply-chain transparency). No NIS2 Article number is written in the artefact
(the grounding is cited by document section).

#### Cluster 4 — Bundle wiring (FR-B69-BD-001 → 015)

##### FR-B69-BD-001 — `bundle.sh` collects nis2 members

`.forge/scripts/compliance/bundle.sh` MUST be extended so its regulatory
directory-walk tuple additionally includes `"nis2"` (`("ai-act", "dora",
"nis2")`), collecting every file under `<target>/.forge/compliance/nis2/` keyed
at bundle-relative path `regulatory/nis2/<file>`.

##### FR-B69-BD-002 — Additive only — existing members unchanged

The extension MUST NOT rename, remove, or reorder the 6 base members or the
existing `regulatory/{ai-act,dora}/*` members. The MANIFEST (over
`sorted(members.keys())`) and the tar loop absorb the new members automatically.

##### FR-B69-BD-003 — Determinism preserved

The extended bundle MUST remain byte-identical across two runs with
`SOURCE_DATE_EPOCH` set (the ADR-I6-CA-001 two-step gzip idiom untouched).
Asserted by FR-B69-BD-110.

##### FR-B69-BD-004 — Graceful absence

If `.forge/compliance/nis2/` is absent at the target, `bundle.sh` MUST treat the
nis2 members as **empty** (zero added) and exit 0 — it MUST NOT fail.

##### FR-B69-BD-010 — I.6 standard bundle-schema table updated + version bumped

`.forge/standards/global/compliance-artefacts-bundle.md` `## Bundle content
schema` MUST gain a `regulatory/nis2/*` row ; its `version:` MUST bump
`1.1.0 → 1.2.0` (additive/minor) with `last_reviewed`/`expires_at` refreshed ;
and its reserved-siblings prose MUST record NIS2 as shipped (CRA still reserved).

##### FR-B69-BD-011 — I.6 standard Interdiction #3 amended

The I.6 standard's Interdiction #3 ("Adopters MUST NOT add the still-reserved
**NIS2 / CRA** regulatory artefacts to the bundle") MUST be amended to remove
NIS2 (now shipped via B.6.9) while keeping CRA reserved.

##### FR-B69-BD-015 — `forge-compliance.yml` unchanged

`.github/workflows/forge-compliance.yml` MUST NOT gain a new step (ADR-B69-007) ;
the nis2 members ride the existing `bundle` step.

#### Cluster 5 — Standard `global/nis2-dora-eda-artefacts.md` (FR-B69-BD-020 → 031)

##### FR-B69-BD-020 — Standard file presence + H1 + anchors

A new file `.forge/standards/global/nis2-dora-eda-artefacts.md` MUST exist with
H1 `# Standard — NIS2 + DORA Event-Driven Regulatory Artefacts`, an audit comment
`<!-- Audit: B.6.9 (b6-9-compliance) -->` and a trigger comment
`<!-- Trigger: nis2, dora, event-driven-eu, compliance, regulatory, incident-reporting, roi, sbom, supply-chain, themis -->`
within the first 5 lines.

##### FR-B69-BD-021 — Frontmatter narrative block

A frontmatter narrative block carrying `version: 1.0.0`,
`last_reviewed: 2026-07-10`, `expires_at: 2027-07-10`,
`exception_constitutional: false`, `linter_rule: null`,
`enforcement: {ci_blocking: false, pre_commit_hook: false}`, `forbidden: []`, and
a `rationale:` one-liner. (Mirrors `ai-act-dora-artefacts.md`.)

##### FR-B69-BD-022 — H2 section count + names

The standard MUST contain ≥ 6 H2 sections, named exactly :
- `## Purpose & EU regulatory scope`
- `## Artefact content schema`
- `## Obligation → evidence traceability`
- `## Governance — two phases (BDFL → Themis)`
- `## Consumption protocol`
- `## Interdictions`

##### FR-B69-BD-023 — Artefact content schema table

The `## Artefact content schema` H2 MUST contain a Markdown table listing every
`.forge/compliance/nis2/*` member + the DORA RoI helper + its purpose + its
`satisfied`/`deferred` status.

##### FR-B69-BD-024 — Governance two-phase section

The `## Governance — two phases (BDFL → Themis)` H2 MUST state that the artefacts
are **content-frozen at v1.0.0 under BDFL (Phase A)** and become
**Themis-maintained (Phase B, K.5)** on a rolling cadence, and that all
`[NEEDS CLARIFICATION]` markers are **Themis Phase-B work items**, not defects.

##### FR-B69-BD-025 — Consumption protocol cites the I.6 bundle

The `## Consumption protocol` H2 MUST cite the I.6 bundle's `regulatory/nis2/`
subdirectory as the hand-off surface and cross-link
`compliance-artefacts-bundle.md`.

##### FR-B69-BD-026 — Interdictions ≥ 3 MUST NOT

The `## Interdictions` H2 MUST contain ≥ 3 RFC-2119 "MUST NOT" clauses,
including verbatim a no-fabrication clause (MUST NOT fabricate a NIS2/DORA
Article number, recital, or precise deadline absent from the repo's cited
sources — flag `[NEEDS CLARIFICATION]` instead) and a no-unsupported-satisfied
clause (MUST NOT mark an obligation `satisfied` without naming a concrete Forge
evidence surface).

##### FR-B69-BD-027 — RFC-2119 vocabulary + Themis cross-link + Constitutional Compliance

The standard MUST use RFC-2119 keywords ≥ 5 times, MUST cross-link Themis (K.5)
as the Phase-B maintainer, and SHOULD carry a `## Constitutional Compliance` H2
listing Articles III.4 / V / VIII.2 / IX.4 / XII.

##### FR-B69-BD-030 — Index entry

`.forge/standards/index.yml` MUST gain an entry under a new section header
`# ─── B.6.9 — NIS2 + DORA event-driven regulatory artefacts (b6-9-compliance) ───`,
`id: global/nis2-dora-eda-artefacts`, `path:
standards/global/nis2-dora-eda-artefacts.md`, `triggers: [nis2, dora,
event-driven-eu, compliance, regulatory, incident-reporting, roi, sbom,
supply-chain, themis]`, `scope: all`, `priority: high`.

##### FR-B69-BD-031 — REVIEW.md birth + I.6 amendment entry

`.forge/standards/REVIEW.md` MUST gain a new H2
`## 2026-07-10 — Initial ratification (b6-9-compliance, B.6.9)` recording the new
standard `1.0.0 KEEP` next-review `2027-07-10` AND the
`compliance-artefacts-bundle.md` `1.1.0 → 1.2.0` amendment (additive nis2 bundle
members).

#### Cluster 6 — Test harness (FR-B69-BD-100 → 113)

##### FR-B69-BD-100 — Harness file presence + skeleton

`.forge/scripts/tests/b6-9.test.sh` MUST exist as executable bash with the
`#!/usr/bin/env bash` + `set -uo pipefail` header, sourcing `_helpers.sh`, with
`--level 1|2|1,2|all` parsing (default 1), an audit comment
`# Audit: B.6.9 (b6-9-compliance)`, and a `print_summary` close-out. Mirrors
`b7-5.test.sh` layout.

##### FR-B69-BD-101 — L1 test count + coverage

The harness MUST run ≥ 14 L1 hermetic tests covering : nis2 dir + members +
audit comments ; incident-reporting grounded windows + operational scenarios +
evidence + marker ; incident-report template ; nis2 obligations-index shape ;
DORA RoI helper presence + run + stack providers ; SBOM wiring documented ;
standard presence + frontmatter + H2 + MUST NOT + governance ; index + REVIEW +
I.6 amendment ; bundle.sh walks nis2 ; b7-5 lock-step present ; COMPLIANCE.md
H2 ; CHANGELOG.

##### FR-B69-BD-102 — L1 anti-hallucination negative-grep test

The harness MUST run an L1 test that greps every file under
`.forge/compliance/nis2/` for any `Article \d+` / `Art. \d+` / `recital` pattern
OUTSIDE a `[NEEDS CLARIFICATION` marker and FAILS if any is found (mirrors
`b7-5.test.sh::_test_b75_030`).

##### FR-B69-BD-103 — L1 b7-5 lock-step guard

The harness MUST run an L1 test asserting `b7-5.test.sh` no longer contains the
`nis2/`-reserved assertion (the lock-step edit is present) AND still contains the
`cra/`-reserved assertion (cra untouched).

##### FR-B69-BD-110 — L2 bundle-integration + determinism test

The harness MUST run ≥ 2 L2 fixture tests : (1) **bundle integration** —
synthetic target tree with the 4 I.6 canonical surfaces + the live
`.forge/compliance/nis2/*` artefacts ; run `bundle.sh` ; assert the `.tgz`
contains the `regulatory/nis2/*` members AND the 6 base members AND a sorted
MANIFEST ; (2) **determinism** — run the extended bundle twice with
`SOURCE_DATE_EPOCH=0` ; assert `diff -q` byte-identical.

##### FR-B69-BD-111 — L2 graceful-absence test

An L2 test MUST run `bundle.sh` against a target tree WITHOUT
`.forge/compliance/nis2/` and assert exit 0 with the base 6 members only and no
`regulatory/nis2/` members.

##### FR-B69-BD-112 — CI registration

`.github/workflows/forge-ci.yml` `harness` job MUST gain a matrix row
`bash .forge/scripts/tests/b6-9.test.sh --level 1,2` immediately after the
`b7-5.test.sh` row (ADR-B69-005). File MUST stay under 400 lines (current 371).

##### FR-B69-BD-113 — Exit codes + per-test FR citation

The harness MUST exit 0 when all tests GREEN, 1 otherwise, and MUST cite at
least one `FR-B69-*` identifier per test function.

#### Cluster 7 — Docs + lock-step (FR-B69-BD-120 → 131)

##### FR-B69-BD-120 — `docs/COMPLIANCE.md` H2

`docs/COMPLIANCE.md` MUST gain a new H2 `## Regulatory artefacts (NIS2 + DORA
event-driven)` cross-linking the `nis2/` artefacts dir, the DORA RoI helper, the
new standard, and the bundle's `regulatory/nis2/` subdirectory, noting the
Themis-Phase-B governance.

##### FR-B69-BD-121 — CHANGELOG entry

`CHANGELOG.md` `[Unreleased]` MUST gain an `### Added` entry referencing
`b6-9-compliance` and the NIS2 + DORA event-driven compliance hooks.

##### FR-B69-BD-130 — b7-5 harness lock-step amendment

`b7-5.test.sh::_test_b75_001` MUST be amended to drop the `nis2/`-reserved
assertion (B.6.9 now creates it) while keeping the `cra/`-reserved assertion.
After the amendment `b7-5.test.sh --level 1,2` MUST stay GREEN.

##### FR-B69-BD-131 — stale-prose lock-step fixes

The stale "NIS2 reserved" statements in `ai-act-dora-artefacts.md` (§ Purpose +
§ Themis cross-link) and `docs/COMPLIANCE.md` (b7-5 section) MUST be updated to
record NIS2 as shipped by B.6.9 (CRA still reserved).

---

### Non-Functional Requirements

#### NFR-B69-001 — Additive / backward compatibility

No existing artefact, change, schema, standard (other than the I.6 bundle
standard's additive nis2 row + version bump), CLI surface, or other archetype
MUST regress. `verify.sh` overall PASS MUST be preserved (Failed = 0). `i6.test.sh`
and `b7-5.test.sh` suites MUST stay GREEN (b7-5 via the lock-step amendment).

#### NFR-B69-002 — Determinism

The extended bundle MUST preserve byte-identical output under `SOURCE_DATE_EPOCH`
(NFR-I6-CA-005 inherited). No new determinism knob.

#### NFR-B69-003 — No external dependency

The bundle extension + the helper MUST use only the `python3` stdlib + PyYAML
already required by I.6. No `pip install`, no network, no legal-text fetch.

#### NFR-B69-004 — Anti-hallucination (Article III.4) — LOAD-BEARING

Every regulatory specific in every artefact + the helper output MUST be either
traceable to a cited repo source OR inside a `[NEEDS CLARIFICATION]` marker.
Enforced by FR-B69-BD-102 negative-grep + a human Aegis/Demeter review pass.
Context7 MUST NOT be used for legal text.

#### NFR-B69-005 — Release-version deferral

The VERSION bump (MINOR per VERSIONING.md) is recorded as expected but the actual
VERSION file edit is a maintainer release task, NOT part of this change.

#### NFR-B69-006 — Standard file size

`global/nis2-dora-eda-artefacts.md` SHOULD remain under 300 lines of Markdown.

#### NFR-B69-007 — CI line budget

The added `forge-ci.yml` matrix row MUST keep the file under 400 lines.

#### NFR-B69-008 — Harness performance budget

`b6-9.test.sh --level 1` MUST complete in ≤ 5 s wall-clock ; L2 fixtures ≤ 10 s
additional (mirrors `b7-5.test.sh` NFR-B75-008).

---

## ADRs (locked at design time, see `design.md`)

- **ADR-B69-001** — Create `.forge/compliance/nis2/` (I.6 forward-declared) ;
  `cra/` stays reserved — resolves Q-010.
- **ADR-B69-002** — Wire nis2 into the I.6 bundle now ; SemVer-minor bump
  1.1.0 → 1.2.0 ; I.6 standard + Interdiction #3 updated in lock-step — Q-011.
- **ADR-B69-003** — New standard `global/nis2-dora-eda-artefacts.md` — Q-012.
- **ADR-B69-004** — DORA RoI helper is a script that DRIVES the b7-5
  `dora/roi-register.template.yaml` base, NOT a new `dora/` file — Q-005.
- **ADR-B69-005** — Harness after `b7-5.test.sh` (compliance family) — Q-013.
- **ADR-B69-006** — b7-5 `_test_b75_001` nis2-reserved assertion amended in
  lock-step (cra reservation kept) — Q-015.
- **ADR-B69-007** — No new `forge-compliance.yml` step — Q-014.

(Legal questions Q-001..Q-005 are resolved in `open-questions.md` as
grounded-or-deferred, NOT as ADRs.)

---

## Constitutional Compliance summary

- **Article I (TDD)** — RED → GREEN → REFACTOR ; Phase 1 full RED harness.
- **Article II (BDD)** — Gherkin in `design.md` (auditor-receives-bundle +
  adopter-fills-incident-report flows).
- **Article III.4 (anti-hallucination)** — LOAD-BEARING ; Q-001..Q-005
  grounded-or-deferred ; FR-B69-BD-102 negative-grep guard ; NFR-B69-004.
- **Article V (audit trail)** — every task `[Story: FR-B69-*]` ; audit anchors ;
  I.6 amendment in REVIEW.md.
- **Article VIII.2 / IX.4** — artefacts LINK to grounded Temporal + Rust OTel
  evidence surfaces ; do not re-implement.
- **Article XII (governance)** — standard ENFORCES content schema + Phase A/B ;
  bundle SemVer-minor per the bundle standard ; REVIEW.md append-only. No
  amendment.

No constitutional amendment required.
