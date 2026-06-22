# Specifications: b7-5-ai-act

<!-- Status: planned (pre-implementation) -->
<!-- Schema: default -->

**Namespace** : `FR-B75-AA-*` (AI-Act artefacts) / `FR-B75-DO-*` (DORA
artefacts) / `FR-B75-BD-*` (bundle wiring + standard + index + harness + docs) /
`NFR-B75-*`. **Constitution** : v2.0.0 — no amendment (this brick ships
spec-time artefacts + a standard + an additive bundle extension; no Article
touched).

## Source Documents

| Field                | Value                                                                                                                                                                  |
|----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**         | `docs/new-archetypes-plan.md` §6.2 lines 2587-2589 (B.7.5) + 2594-2595 (B.7.8) ; §0.12 line 2024 (brick #6) ; §10.3 line 783 (`ai-native-rag` profile) ; §10.4 (deadlines) |
| **Bundle src**       | `i6-compliance-artefacts` archived 2026-05-12 — `.forge/scripts/compliance/bundle.sh` (`members` dict `:358`, MANIFEST `:368`) + ADR-I6-CA-002 `regulatory/` reservation + FR-I6-CA-053 forward-compat note |
| **Bundle std**       | `.forge/standards/global/compliance-artefacts-bundle.md` v1.0.0 — `## Bundle content schema` table + "adding a member = SemVer minor" rule |
| **Tier src**         | `i2-compliance-tiers` archived 2026-05-12 — `global/compliance-tiers.md` v1.0.0 (T1/T2/T3 gradient + §"Governance — two phases" Phase A BDFL / Phase B Themis precedent) |
| **AI hooks src**     | `b7-standards` archived 2026-06-13 — `global/llm-gateway.md` ("AI Act transparency obligations (B.7.5 territory)", prompt-audit IX.6) + `global/rag-patterns.md` |
| **Runtime evidence** | `b7-2-scaffolder` archived 2026-06-21 — prompt-audit span (IX.6), Qwik `fallbackUsed` indicator (FR-B7-2-020), tier-aware refusal hooks |
| **Regulatory ground**| `docs/ARCHITECTURE-TARGET.md` §10.3 (archetype profiles) + §10.4 (DORA RoI 30 avr 2026 ESA, NIS2 24h/72h, AI Act phases 2025-2027) + §9.2 line 735 (Themis charter "incident reporting < 24h") |
| **DPA template prec**| `i6-compliance-artefacts` — `.forge/templates/compliance/forge-dpa-declared.template` (header-comment + canonical-example + remediation-notes pattern the model/dataset-card templates mirror) |
| **Standard frame**   | `global/standards-lifecycle.md` (frontmatter contract, REVIEW.md append-only) ; `global/compliance-artefacts-bundle.md` + `global/sbom-policy.md` (sibling MD-standard pattern) |
| **Anti-hallucination**| Article III.4 ; `open-questions.md` Q-001..Q-005 (legal: grounded-or-deferred) ; `compliance-tiers.md` §"Interdictions" precedent (MUST NOT paraphrase the source) |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — AI-Act artefacts `.forge/compliance/ai-act/` (FR-B75-AA-001 → 030)

##### FR-B75-AA-001 — Directory presence

The directory `.forge/compliance/ai-act/` MUST exist and MUST contain the
members enumerated in FR-B75-AA-010..025. The layout mirrors the I.6
forward-declared `.forge/compliance/{nis2,dora,cra,ai-act}/` reservation
(ADR-B75-001 / ADR-I6-CA-002).

##### FR-B75-AA-002 — Audit comment on every member

Every file under `.forge/compliance/ai-act/` MUST carry an audit anchor
`<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->` (or the `#`-comment form for YAML)
within its first 5 lines.

##### FR-B75-AA-010 — `risk-classification.md` presence + grounded posture

A file `.forge/compliance/ai-act/risk-classification.md` MUST exist. It MUST
state the **grounded** posture (the `ai-native-rag` archetype carries AI-Act
**transparency obligations**, citing `ARCHITECTURE-TARGET.md` §10.3 line 783 +
`global/llm-gateway.md`). It MUST NOT assert a precise AI-Act risk category or
Article number (Q-001 DEFERRED).

##### FR-B75-AA-011 — `risk-classification.md` escalation triggers + NEEDS-CLARIFICATION markers

`risk-classification.md` MUST list the escalation triggers a deployer must
self-assess (incl. "deployed in a regulated/finance context", Q-003) and MUST
carry the literal `[NEEDS CLARIFICATION: …]` markers from Q-001 + Q-003
verbatim (the AI-Act risk-category mapping + the finance high-risk
determination), each tagged "Themis (K.5) to supply". (Article III.4.)

##### FR-B75-AA-012 — `transparency-obligations.md` presence + evidence linkage

A file `.forge/compliance/ai-act/transparency-obligations.md` MUST exist
describing the transparency duties the posture triggers (users informed they
interact with an AI system; AI output identifiable), each linked to the Forge
evidence surface that produces it : the Qwik `fallbackUsed` indicator
(`b7-2-scaffolder` FR-B7-2-020) and the IX.6 prompt-audit record
(`global/llm-gateway.md` §"Prompt audit"). (Q-005 GROUNDED.)

##### FR-B75-AA-020 — `model-card.template.md` presence + skeleton

A file `.forge/compliance/ai-act/model-card.template.md` MUST exist as an
adopter-fillable skeleton (model identity/provenance, intended use, limitations,
known-bias notes, evaluation method) mirroring the `forge-dpa-declared.template`
header/example/remediation structure. It MUST NOT assert a specific legal duty;
its header MUST carry the Q-004 `[NEEDS CLARIFICATION]` marker for the bias-eval
Article. (B.7.5 "model card jointe au build".)

##### FR-B75-AA-021 — `dataset-card.template.md` presence + skeleton

A file `.forge/compliance/ai-act/dataset-card.template.md` MUST exist as an
adopter-fillable skeleton (dataset identity, source/licence, training-data
description, known-bias notes, evaluation method). Same structure + same
no-legal-assertion constraint as FR-B75-AA-020. (B.7.5 "dataset cards / évaluation
biais".)

##### FR-B75-AA-025 — `obligations-index.yaml` presence + obligation→evidence map

A file `.forge/compliance/ai-act/obligations-index.yaml` MUST exist mapping each
**grounded** AI-Act obligation class → the Forge evidence surface satisfying it.
It MUST contain exactly the two grounded obligation classes (`transparency`,
`logging-record-keeping` — Q-005), each with a `satisfied_by:` list of evidence
surfaces. Obligation classes the repo does NOT ground (conformity assessment, CE
marking, post-market monitoring) MUST appear as entries with
`status: needs-clarification` + a `themis_owner: K.5` field, NOT as `satisfied`.

##### FR-B75-AA-026 — `obligations-index.yaml` schema shape

`obligations-index.yaml` MUST be valid YAML with a top-level
`schema_version: "1.0.0"`, `regulation: ai-act`, and an `obligations:` list
where each item carries `id`, `title`, `status` (`satisfied` |
`needs-clarification` | `deployer-assessed`), `satisfied_by` (list, possibly
empty), and an optional `source` citation field. Deterministic key order.

##### FR-B75-AA-030 — No fabricated legal citation

No file under `.forge/compliance/ai-act/` MUST contain an AI-Act Article number,
recital number, or precise date that is NOT either (a) traceable to a cited repo
source or (b) inside a `[NEEDS CLARIFICATION]` marker. (Article III.4 — asserted
by the harness negative-grep test, see FR-B75-BD-102.)

#### Cluster 2 — DORA artefacts `.forge/compliance/dora/` (FR-B75-DO-001 → 020)

##### FR-B75-DO-001 — Directory presence

The directory `.forge/compliance/dora/` MUST exist with the members
FR-B75-DO-010..015. Mirrors the I.6 reservation (ADR-B75-001).

##### FR-B75-DO-002 — Audit comment on every member

Same as FR-B75-AA-002 for every file under `.forge/compliance/dora/`.

##### FR-B75-DO-010 — `incident-reporting.md` presence + grounded obligation

A file `.forge/compliance/dora/incident-reporting.md` MUST exist describing the
DORA major-ICT-incident reporting obligation, citing the **grounded** figures
verbatim : the "< 24h" charter figure (`ARCHITECTURE-TARGET.md` §9.2 line 735)
and the DORA RoI ESA submission deadline "30 avr 2026" (§10.4 line 789-790 with
its `[source: …]` footnote). It MUST link the obligation to the Forge evidence
surface (the I.6 audit-ledger snapshot + the IX.6 prompt-audit span).

##### FR-B75-DO-011 — `incident-reporting.md` NEEDS-CLARIFICATION markers

`incident-reporting.md` MUST carry the Q-002 `[NEEDS CLARIFICATION]` marker for
the precise DORA notification windows (initial/intermediate/final), tagged
"Themis (K.5) to supply from the official DORA RTS". It MUST NOT invent any
notification-window figure beyond the grounded "< 24h".

##### FR-B75-DO-015 — `roi-register.template.yaml` presence + skeleton

A file `.forge/compliance/dora/roi-register.template.yaml` MUST exist as an
adopter-fillable skeleton for the DORA Register of Information referenced by the
§10.4 deadline. Adopter-fillable structure only; no fabricated mandatory-field
list beyond what the repo grounds (header carries a `[NEEDS CLARIFICATION]` for
the authoritative RoI field schema — Themis K.5).

##### FR-B75-DO-016 — `obligations-index.yaml` presence + shape

A file `.forge/compliance/dora/obligations-index.yaml` MUST exist with the same
schema shape as FR-B75-AA-026 (`regulation: dora`), mapping the grounded DORA
obligations (incident-reporting → audit-ledger + prompt-audit evidence;
RoI → the RoI template) and flagging ungrounded ones `needs-clarification` /
`themis_owner: K.5`.

##### FR-B75-DO-020 — No fabricated legal citation

Same as FR-B75-AA-030 for `.forge/compliance/dora/`.

#### Cluster 3 — Bundle wiring (FR-B75-BD-001 → 015)

##### FR-B75-BD-001 — `bundle.sh` collects regulatory members

`.forge/scripts/compliance/bundle.sh` MUST be extended so its `members` dict
(currently `bundle.sh:358`) additionally includes every file under
`<target>/.forge/compliance/ai-act/` and `<target>/.forge/compliance/dora/`,
keyed at bundle-relative path `regulatory/ai-act/<file>` and
`regulatory/dora/<file>` respectively (ADR-B75-001 / ADR-I6-CA-002
`regulatory/` layout).

##### FR-B75-BD-002 — Additive only — existing members unchanged

The extension MUST NOT rename, remove, or reorder any of the 6 existing bundle
members (tier-matrix, DPA template, audit-ledger ×2, SBOM, MANIFEST). The new
members are added to the same dict; the MANIFEST (computed over
`sorted(members.keys())`, `bundle.sh:368`) absorbs them automatically.

##### FR-B75-BD-003 — Determinism preserved

The extended bundle MUST remain byte-identical across two runs with
`SOURCE_DATE_EPOCH` set (the ADR-I6-CA-001 two-step gzip idiom is untouched).
Asserted by re-running the I.6 L2 determinism test against the extended member
set (FR-B75-BD-110).

##### FR-B75-BD-004 — Graceful absence

If `.forge/compliance/ai-act/` or `.forge/compliance/dora/` is absent at the
target (e.g. an adopter project without the AI archetype), `bundle.sh` MUST
treat the regulatory members as **empty** (zero added) and exit 0 — it MUST NOT
fail. (Backward-compat : the I.6 4-canonical-surface validation FR-I6-CA-007 is
unchanged; regulatory members are optional.)

##### FR-B75-BD-010 — I.6 standard bundle-schema table updated

`.forge/standards/global/compliance-artefacts-bundle.md` `## Bundle content
schema` table MUST gain rows for the `regulatory/ai-act/*` + `regulatory/dora/*`
members, and its member-count prose (currently "exactly 6 members") MUST be
amended to reflect the now-variable member count (6 base + N regulatory). The
standard's `version:` MUST bump (1.0.0 → 1.1.0, additive/minor) with
`last_reviewed`/`expires_at` refreshed and a REVIEW.md entry (FR-B75-BD-031).

##### FR-B75-BD-011 — I.6 standard forward-compat note realised

The I.6 standard's FR-I6-CA-053 forward-compatibility sentence ("the bundle
schema v1.0.0 will expand to include Themis-territory artefacts … without a
major SemVer bump") MUST be updated to record that B.7.5/B.7.8 realised the
AI-Act + DORA expansion at v1.1.0 (with NIS2/CRA still reserved).

##### FR-B75-BD-015 — `forge-compliance.yml` unchanged

`.github/workflows/forge-compliance.yml` MUST NOT gain a new step (ADR-B75-005);
the regulatory members ride the existing `bundle` step. This requirement is a
**negative assertion** verified by the harness (the workflow's 4-step contract
`demeter`/`linter`/`sbom`/`bundle` is preserved).

#### Cluster 4 — Standard `global/ai-act-dora-artefacts.md` (FR-B75-BD-020 → 030)

##### FR-B75-BD-020 — Standard file presence + H1 + anchors

A new file `.forge/standards/global/ai-act-dora-artefacts.md` MUST exist with
H1 `# Standard — AI Act + DORA Regulatory Artefacts`, an audit comment
`<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->` and a trigger comment
`<!-- Trigger: ai-act, dora, compliance, regulatory, model-card, dataset-card, transparency, incident-reporting, themis -->`
within the first 5 lines.

##### FR-B75-BD-021 — Frontmatter narrative block

A frontmatter narrative block under H1 carrying `version: 1.0.0`,
`last_reviewed: 2026-06-22`, `expires_at: 2027-06-22`,
`exception_constitutional: false`, `linter_rule: null`,
`enforcement: {ci_blocking: false, pre_commit_hook: false}`, and a `rationale:`
one-liner. (Mirrors `compliance-artefacts-bundle.md` frontmatter.)

##### FR-B75-BD-022 — H2 section count + names

The standard MUST contain ≥ 6 H2 sections, named exactly :
- `## Purpose & EU regulatory scope`
- `## Artefact content schema`
- `## Obligation → evidence traceability`
- `## Governance — two phases (BDFL → Themis)`
- `## Consumption protocol`
- `## Interdictions`

##### FR-B75-BD-023 — Artefact content schema table

The `## Artefact content schema` H2 MUST contain a Markdown table listing every
`.forge/compliance/{ai-act,dora}/*` member + its purpose + its
`satisfied`/`deferred` status.

##### FR-B75-BD-024 — Governance two-phase section

The `## Governance — two phases (BDFL → Themis)` H2 MUST state that the artefacts
are **content-frozen at v1.0.0 under BDFL (Phase A)** and become
**Themis-maintained (Phase B, K.5, T7+)** on a rolling cadence, mirroring
`compliance-tiers.md` §"Governance — two phases". It MUST state that all
`[NEEDS CLARIFICATION]` markers in the artefacts are **Themis Phase B work
items**, not framework defects.

##### FR-B75-BD-025 — Consumption protocol cites the I.6 bundle

The `## Consumption protocol` H2 MUST cite the I.6 bundle's `regulatory/`
subdirectory as the hand-off surface and cross-link
`compliance-artefacts-bundle.md`.

##### FR-B75-BD-026 — Interdictions ≥ 3 MUST NOT

The `## Interdictions` H2 MUST contain ≥ 3 RFC-2119 "MUST NOT" clauses,
including verbatim :
1. MUST NOT fabricate an AI-Act / DORA Article number, recital, or precise
   deadline absent from the repo's cited grounded sources — flag
   `[NEEDS CLARIFICATION]` instead (Article III.4).
2. MUST NOT mark an obligation `satisfied` in an `obligations-index.yaml`
   without naming a concrete Forge evidence surface.
3. MUST NOT modify the artefacts' frozen content outside the Themis (K.5)
   Phase-B cadence once Themis ships, except via an explicit BDFL Phase-A
   amendment with a REVIEW.md entry.

##### FR-B75-BD-027 — RFC-2119 vocabulary + Themis cross-link + Constitutional Compliance

The standard MUST use RFC-2119 keywords ≥ 5 times, MUST cross-link Themis (K.5)
as the Phase-B maintainer, and SHOULD carry a `## Constitutional Compliance` H2
listing Articles III.4 / V / IX.6 / XI / XII.

##### FR-B75-BD-030 — Index entry

`.forge/standards/index.yml` MUST gain an entry under a new section header
`# ─── B.7.5/B.7.8 — AI Act + DORA regulatory artefacts (b7-5-ai-act) ───`,
`id: global/ai-act-dora-artefacts`, `path:
standards/global/ai-act-dora-artefacts.md`, `triggers: [ai-act, dora,
compliance, regulatory, model-card, dataset-card, transparency,
incident-reporting, themis]`, `scope: all`, `priority: high`.

##### FR-B75-BD-031 — REVIEW.md birth + I.6 amendment entry

`.forge/standards/REVIEW.md` MUST gain a new H2
`## 2026-06-22 — Initial ratification (b7-5-ai-act, B.7.5 + B.7.8)` recording
the new standard `1.0.0 KEEP` next-review `2027-06-22` AND the
`compliance-artefacts-bundle.md` `1.0.0 → 1.1.0` amendment (additive bundle
members).

#### Cluster 5 — Test harness (FR-B75-BD-100 → 115)

##### FR-B75-BD-100 — Harness file presence + skeleton

`.forge/scripts/tests/b7-5.test.sh` MUST exist as executable bash with the
`#!/usr/bin/env bash` + `set -uo pipefail` header, sourcing `_helpers.sh`, with
`--level 1|2|1,2|all` parsing (default 1), an audit comment
`# Audit: B.7.5+B.7.8 (b7-5-ai-act)`, and a `print_summary` close-out. Mirrors
`i6.test.sh` layout.

##### FR-B75-BD-101 — L1 test count + coverage

The harness MUST run ≥ 12 L1 hermetic tests covering :
1. `.forge/compliance/ai-act/` + `dora/` directory presence + audit comments
2. `risk-classification.md` presence + grounded posture string + NEEDS-CLARIF markers
3. `transparency-obligations.md` presence + evidence-surface cross-links
4. `model-card.template.md` + `dataset-card.template.md` presence + skeleton headers
5. ai-act `obligations-index.yaml` valid YAML + two grounded obligations + needs-clarif entries
6. `incident-reporting.md` presence + grounded "< 24h" + RoI "30 avr 2026" strings + NEEDS-CLARIF marker
7. `roi-register.template.yaml` presence + skeleton
8. dora `obligations-index.yaml` valid YAML + shape
9. Standard presence + H1 + frontmatter + version 1.0.0
10. Standard ≥ 6 H2 + ≥ 3 MUST NOT + governance two-phase section
11. Index entry + REVIEW.md birth + I.6 amendment entry
12. I.6 standard bundle-schema table gained regulatory rows + version bumped to 1.1.0
13. `docs/COMPLIANCE.md` new H2 `## Regulatory artefacts (AI Act + DORA)`
14. CHANGELOG entry

##### FR-B75-BD-102 — L1 anti-hallucination negative-grep test

The harness MUST run an L1 test that greps every file under
`.forge/compliance/{ai-act,dora}/` for any "Article \d+" / "Art. \d+" /
"recital" pattern OUTSIDE a `[NEEDS CLARIFICATION` marker and FAILS if any is
found (enforces FR-B75-AA-030 / FR-B75-DO-020 / Interdiction 1). Mirrors the
b7-3 T-007 no-inline-pin negative-grep guard.

##### FR-B75-BD-110 — L2 bundle-integration + determinism test

The harness MUST run ≥ 2 L2 fixture tests :
1. **Bundle integration** — synthetic target tree with the 4 I.6 canonical
   surfaces + the new `.forge/compliance/{ai-act,dora}/*` artefacts; run
   `bundle.sh`; assert the `.tgz` contains the `regulatory/ai-act/*` +
   `regulatory/dora/*` members AND still the 6 base members AND a MANIFEST
   listing all of them sorted.
2. **Determinism with regulatory members** — run the extended bundle twice with
   `SOURCE_DATE_EPOCH=0`; assert `diff -q` byte-identical (FR-B75-BD-003).

##### FR-B75-BD-111 — L2 graceful-absence test

An L2 test MUST run `bundle.sh` against a target tree WITHOUT
`.forge/compliance/{ai-act,dora}/` and assert exit 0 with the base 6 members
only (FR-B75-BD-004).

##### FR-B75-BD-112 — CI registration

`.github/workflows/forge-ci.yml` `harness` job MUST gain a matrix row
`bash .forge/scripts/tests/b7-5.test.sh --level 1,2` immediately after the
`i5.test.sh` row (ADR-B75-004). File MUST stay under 300 lines (NFR-CI-002).

##### FR-B75-BD-113 — Exit codes + per-test FR citation

The harness MUST exit 0 when all tests GREEN, 1 otherwise, and MUST cite at
least one `FR-B75-*` identifier per test function (mirrors `i6.test.sh`).

#### Cluster 6 — Docs / inventory (FR-B75-BD-120 → 125)

##### FR-B75-BD-120 — `docs/COMPLIANCE.md` H2

`docs/COMPLIANCE.md` MUST gain a new H2 `## Regulatory artefacts (AI Act + DORA)`
(after `## Auditor hand-off bundle`) cross-linking the artefacts dir, the new
standard, and the bundle's `regulatory/` subdirectory, and noting the
Themis-Phase-B governance for the `[NEEDS CLARIFICATION]` items.

##### FR-B75-BD-121 — Plan rows B.7.5 + B.7.8 + brick #6

`docs/new-archetypes-plan.md` rows B.7.5 + B.7.8 (§6.2) MUST be marked Done, and
§0.12 line 2024 brick #6 status flipped from `⏳ pending` to done, all citing
`b7-5-ai-act`. The §2760 T7 progress line MUST move the brick from "⏳ pending"
to "livrées".

##### FR-B75-BD-122 — roadmap + CHANGELOG

`.forge/product/roadmap.md` MUST gain an inventory line; `CHANGELOG.md`
`[Unreleased]` MUST gain an `### Added — B.7.5 + B.7.8 AI-Act + DORA regulatory
artefacts (b7-5-ai-act)` entry. Since this adds an archetype-compliance surface,
VERSIONING.md MINOR applies (a `since: 0.5.0` consistent with `b7-2a`); the exact
version-bump decision is deferred to the maintainer at release (NFR-B75-005).

---

### Non-Functional Requirements

#### NFR-B75-001 — Additive / backward compatibility

No existing artefact, change, schema, standard (other than the I.6 bundle
standard's additive table rows + version bump), CLI surface, or other archetype
MUST regress. `verify.sh` overall PASS MUST be preserved (Passed total
monotonically increases or stays equal; Failed = 0). The I.6 `i6.test.sh` suite
MUST stay GREEN (its member-count assertions are updated in lock-step — see
FR-B75-BD-010 + the design's I.6 cross-impact note).

#### NFR-B75-002 — Determinism

The extended bundle MUST preserve byte-identical output under `SOURCE_DATE_EPOCH`
(NFR-I6-CA-005 invariant inherited). No new determinism knob introduced.

#### NFR-B75-003 — No external dependency

The bundle extension MUST use only the `python3` stdlib + PyYAML already required
by I.6 (`os`, `pathlib`, `tarfile`, `gzip`, `hashlib`, `json`, `yaml`). No
`pip install`, no network, no legal-text fetch.

#### NFR-B75-004 — Anti-hallucination (Article III.4) — LOAD-BEARING

Every regulatory specific in every artefact MUST be either traceable to a cited
repo source (`ARCHITECTURE-TARGET.md` §10.3/§10.4 + footnotes,
`compliance-tiers.md`, `llm-gateway.md`, the Themis charter §9.2) OR inside a
`[NEEDS CLARIFICATION]` marker. Enforced by FR-B75-BD-102 negative-grep + a
human Aegis/Demeter review pass at implementation. Context7 MUST NOT be used for
legal text.

#### NFR-B75-005 — Release-version deferral

The VERSION bump (0.4.0 → 0.5.0 MINOR per VERSIONING.md, consistent with the
`b7-2a` `since: 0.5.0`) is recorded as the expected bump but the actual VERSION
file edit is a maintainer release task, NOT part of this change's
implementation (mirrors how prior B.7 bricks left VERSION to the release).

#### NFR-B75-006 — Standard file size

`global/ai-act-dora-artefacts.md` SHOULD remain under 300 lines of Markdown.

#### NFR-B75-007 — CI line budget

The added `forge-ci.yml` matrix row MUST keep the file under the NFR-CI-002
300-line budget (current 293 → ~294).

#### NFR-B75-008 — Harness performance budget

`b7-5.test.sh --level 1` MUST complete in ≤ 5 s wall-clock; L2 fixtures ≤ 10 s
additional (mirrors `i6.test.sh` NFR-I6-CA-001 budget).

---

## ADRs (locked at design time, see `design.md`)

- **ADR-B75-001** — Layout : per-regulation `.forge/compliance/{ai-act,dora}/`
  subdirectories (I.6 forward-declared) — resolves Q-010.
- **ADR-B75-002** — Wire into the I.6 bundle now via a `regulatory/`
  subdirectory; SemVer-minor bump of the bundle contract; I.6 standard + tests
  updated in lock-step — resolves Q-011.
- **ADR-B75-003** — New standard `global/ai-act-dora-artefacts.md` (separate from
  the I.6 bundle standard) — resolves Q-012.
- **ADR-B75-004** — Harness placed after `i5.test.sh` in the compliance family —
  resolves Q-013.
- **ADR-B75-005** — No new `forge-compliance.yml` step; artefacts ride the
  existing `bundle` step — resolves Q-014.

(Legal questions Q-001..Q-005 are resolved in `open-questions.md` as
grounded-or-deferred, NOT as ADRs — they are not design decisions but
anti-hallucination determinations.)

---

## Constitutional Compliance summary

- **Article I (TDD)** — RED → GREEN → REFACTOR; Phase 1 full RED harness.
- **Article II (BDD)** — Gherkin in `proposal.md` / `design.md` (auditor-receives
  + adopter-fills flows).
- **Article III.4 (anti-hallucination)** — LOAD-BEARING; Q-001..Q-005
  grounded-or-deferred; FR-B75-BD-102 negative-grep guard; NFR-B75-004.
- **Article V (audit trail)** — every task `[Story: FR-B75-*]`; every artefact +
  standard + harness carry the audit anchor.
- **Article IX.6 / XI.5 / XI.6 (AI hooks)** — artefacts LINK to the scaffolded
  runtime evidence surfaces; do not re-implement.
- **Article XII (governance)** — standard ENFORCES content schema + Phase A/B
  governance; bundle contract extension follows
  `compliance-artefacts-bundle.md` SemVer; REVIEW.md append-only. No amendment.

No constitutional amendment required.
