# Design: i2-compliance-tiers
<!-- Status: designed -->
<!-- Schema: default -->

> Read alongside `specs.md` (FR-I2-CT-* / NFR-I2-CT-*) and
> `open-questions.md` (Q-001..Q-003). This document locks the
> implementation strategy and resolves Q-001 / Q-002 / Q-003 via
> ADR-I2-CT-001..003.

## Architecture Decisions

### ADR-I2-CT-001 — `linter_rule:` value : kebab-case forward-pointer (resolves Q-001)

**Context** : Q-001 weighed two candidate frontmatter values for
`linter_rule:` :

- **Option A — kebab-case forward-pointer** :
  `linter_rule: t3-forbidden-components`. Pre-allocates the I.3
  linter rule's identity ; avoids a version bump when I.3 ships.
- **Option B — null** : `linter_rule: null` until I.3 ships.
  Strictly J.7-compliant (FR-J7-030 — the kebab-case string MUST
  be referenced as a section anchor in `constitution-linter.sh`).

**Decision** : **Option A — kebab-case forward-pointer
`t3-forbidden-components`**. Two arguments :

1. **J.7 scope** : `validate-standards-yaml.sh` scans
   `.forge/standards/*.yaml` only. The compliance-tiers standard
   ships as **Markdown** (mirroring `data-stewardship-rules.md`,
   `janus-orchestration-rules.md`, `sbom-policy.md`). The
   J.7 FR-J7-030 cross-reference invariant does **not** apply to
   MD standards — the frontmatter block in MD is narrative, not
   parsed.
2. **Reviewer intent** : the forward-pointer signals to reviewers
   what rule will enforce the constraint. A `null` value invites
   the question "is this standard ever enforced?" — the
   forward-pointer answers it.

**Consequences** :
- ✅ I.3 ships without a version bump on
  `compliance-tiers.md` (the I.3 change only edits
  `constitution-linter.sh` to add the matching section anchor).
- ✅ Adopters reading the standard's frontmatter understand the
  enforcement pipeline.
- ⚠️ Until I.3 ships, the kebab-case string is an unbound
  symbol. The standard's body explicitly notes "enforcement
  becomes ci when I.3 lands" to flag the pending state.

**Constitution Compliance** : Article III.4 (anti-hallucination)
— the forward-pointer is declarative, not predictive. Article XII
(governance) — locking the kebab-case name now does not amend any
Constitution Article ; the name lives in the standard's
frontmatter, not in the Constitution.

---

### ADR-I2-CT-002 — Matrix encoding : verbatim 15 rows (resolves Q-002)

**Context** : Q-002 weighed two encodings of the §10.2 component
matrix :

- **Option A — verbatim 15 rows** : reproduce the matrix
  byte-for-byte from `docs/ARCHITECTURE-TARGET.md §10.2`.
- **Option B — condensed** : group "compatible everywhere" rows
  into one line ; detail the 7 tier-sensitive rows individually.

**Decision** : **Option A — verbatim 15 rows**. The K.3
Anti-Hallucination Protocol (FR-K3-DEM-020) precedent forces
this : Demeter MUST cite the matrix verbatim ; any condensation
introduces a paraphrase surface that K.3 forbids.

**The 15 rows reproduced** (cells locked at impl time per the
source) :

| Row # | Component                        | T1                  | T2                | T3                            | Forçage tier                                                |
|-------|----------------------------------|---------------------|-------------------|-------------------------------|-------------------------------------------------------------|
| 1     | Flutter / Qwik (binaires client) | ✅                  | ✅                | ✅                            | aucun                                                       |
| 2     | Rust + tonic + axum              | ✅                  | ✅                | ✅                            | aucun                                                       |
| 3     | Envoy Gateway                    | ✅                  | ✅                | ✅                            | aucun (CNCF)                                                |
| 4     | Postgres 17 + pgvector           | ✅                  | ✅                | ✅                            | aucun                                                       |
| 5     | DBOS (embedded library)          | ✅                  | ✅                | ✅                            | aucun                                                       |
| 6     | Zitadel                          | ⚠️ Cloud SaaS T1   | ✅ self-host T2  | ✅ self-host EU+SecNumCloud   | T3 = self-host obligatoire                                  |
| 7     | SigNoz                           | ⚠️ Cloud SaaS T1   | ✅ self-host T2  | ✅ self-host EU              | T3 = self-host obligatoire                                  |
| 8     | Coroot                           | ✅ self-host        | ✅                | ✅                            | —                                                           |
| 9     | OTel Collector / OBI             | ✅                  | ✅                | ✅                            | —                                                           |
| 10    | OVHcloud / Scaleway / Outscale   | —                   | —                 | ✅                            | T3 obligatoire = SecNumCloud Outscale                       |
| 11    | AWS / GCP / Azure                | ⚠️ T1 only         | ❌                | ❌                            | **CLOUD Act** force max T1                                  |
| 12    | Firebase                         | ❌                  | ❌                | ❌                            | Disqualifié pour archétype EU strict                        |
| 13    | Temporal Cloud                   | ⚠️ T1              | ✅ self-host T2  | ✅ self-host EU              | self-host pour T3                                           |
| 14    | LLM Gateway (OpenAI/Anthropic)   | ⚠️ T1 max          | ❌                | ❌                            | Pour T3 : Mistral on Scaleway ou vLLM self-host             |
| 15    | NATS JetStream                   | ✅                  | ✅                | ✅                            | self-host T2/T3                                             |

**Source citations** (footnote-level, included in the standard
under each tier-sensitive row) :
- Row 5 : `[source: dbos.dev, accessed 2026-04]`
- Row 6 : `[source: zitadel.com/blog/zitadel-vs-keycloak, accessed 2026-04]`
- Row 10 : `[source: 3ds.com/newsroom/press-releases/outscale-enhances-outscale-kubernetes-service, accessed 2026-04]`
- Row 11 : `[source: spreecommerce.org/gdpr-schrems-ii-ecommerce-compliance, accessed 2026-04]`

**Rejected — Option B** : groups "✅ ✅ ✅ aucun" rows into one
line. While saves ~6 lines of Markdown, breaks the byte-identical
mirror of §10.2 that Demeter's checklist relies on. Adopters
reading the standard and the architecture document side-by-side
would have to mentally reconcile the difference. Not worth the
six lines.

**Consequences** :
- ✅ Demeter can cite any matrix row verbatim against the
  standard.
- ✅ Reviewers cross-reading the standard and §10.2 see identical
  tables.
- ⚠️ The standard duplicates §10.2. When §10.2 evolves (component
  shift, tier downgrade), both surfaces MUST update synchronously
  — captured as an Interdiction in `compliance-tiers.md` and
  enforced by a future drift-detector (out of scope here ;
  potential J.X follow-up).

**Constitution Compliance** : Article III.4 (anti-hallucination,
verbatim citation). Article V (audit trail — the source-citation
footnotes preserve traceability). Article XII (governance —
matrix shifts require a SemVer minor bump documented in REVIEW.md).

---

### ADR-I2-CT-003 — `docs/COMPLIANCE.md` placement : root (resolves Q-003)

**Context** : Q-003 weighed root vs subdirectory placement for the
adopter-facing intro doc.

**Decision** : **Option A — root `docs/COMPLIANCE.md`**. Sibling
to existing `docs/ARCHITECTURE-TARGET.md`, `docs/GUIDE.md`,
`docs/CLI.md`, `docs/SCHEMA.md`, `docs/VERSIONING.md`.

**Rejected — Option B** : `docs/compliance/README.md`
subdirectory. The grouping is speculative — Themis (K.5) artefacts
ship T7+ ; the I.6 regulatory deadlines artefacts have no shipped
home yet. Pre-allocating a subdirectory for one file creates
inconsistency with the flat `docs/` layout.

**Migration path** : when I.6 actually ships and a `docs/compliance/`
subdirectory makes sense, a follow-up change moves
`docs/COMPLIANCE.md → docs/compliance/README.md` with a stub
redirect file at the old path. Today, flat layout = consistency.

**Consequences** :
- ✅ Flat `ls docs/` shows the new file alongside existing
  top-level docs.
- ✅ Cross-references from external sources (web search, internal
  wiki) survive future subdirectory moves via stub redirects.
- ⚠️ The eventual `docs/compliance/` regroup is a known future
  migration. Noted in the standard's "Adoption path" H2 so
  adopters don't bookmark a doomed URL.

**Constitution Compliance** : N/A directly (docs placement is not
constitutional matter). Mirrors the existing `docs/` flat layout
convention preserved across all prior Forge changes.

---

## Implementation strategy

The change has 4 phases, mirroring the proposal's TDD discipline
and the K.3 / J.8 pattern.

### Phase 1 — RED foundation

- Write `.forge/scripts/tests/i2.test.sh` with **12 L1 stubs**
  all returning `_not_implemented`. Mirror the K.3 / J.8 harness
  layout (set -uo pipefail ; `--level 1` parsing ; source
  `_helpers.sh` ; PASS/FAIL counters reset ; `print_summary`
  close-out).
- Register `i2.test.sh` in `.github/workflows/forge-ci.yml`
  `harness` job matrix immediately after `k3.test.sh`.
- Phase 1 exit gate : `bash i2.test.sh --level 1` exits 1 with
  `FAIL = 12 / PASS = 0`. `verify.sh` overall PASS unchanged.
  `constitution-linter.sh` overall PASS unchanged.

### Phase 2 — Standard file authoring

- Create `.forge/standards/global/compliance-tiers.md` v1.0.0
  with all required H2 sections + frontmatter + matrix +
  Interdictions.
- Phase 2 exit gate : 10 of 12 L1 tests flip GREEN
  (everything except index-entry and REVIEW-entry tests).

### Phase 3 — Standards index + REVIEW + docs

- Edit `.forge/standards/index.yml` to add the new entry under
  the K.3 cross-cutting section.
- Edit `.forge/standards/REVIEW.md` with the append-only birth
  entry dated 2026-05-11.
- Create `docs/COMPLIANCE.md` adopter intro with 3 H2 sections.
- Phase 3 exit gate : all 12 L1 tests flip GREEN. `verify.sh`
  overall PASS (the new index.yml entry must still point to a
  valid file). `constitution-linter.sh` overall PASS.

### Phase 4 — CHANGELOG + verify

- Edit `CHANGELOG.md` `[Unreleased]` to add the I.2 entry.
- Run all three gates : `verify.sh` PASS, `constitution-linter.sh`
  PASS, `bash bin/validate-standards-yaml.sh` GREEN.
- Run `bash .forge/scripts/tests/i2.test.sh --level 1` — all
  12 L1 tests GREEN.
- Status flips to `implemented`.

---

## Test taxonomy

### L1 unit-level (12 tests, hermetic, grep-based)

| Test ID                             | FR ref         | What it asserts                                                                 |
|-------------------------------------|----------------|---------------------------------------------------------------------------------|
| `_test_i2_001_standard_exists`      | FR-I2-CT-001   | `compliance-tiers.md` file exists                                               |
| `_test_i2_002_audit_comment`        | FR-I2-CT-002   | `<!-- Audit: I.2 (i2-compliance-tiers) -->` in first 5 lines                    |
| `_test_i2_003_trigger_comment`      | FR-I2-CT-003   | `<!-- Trigger: ... -->` carrying ≥ 9 keywords in first 5 lines                  |
| `_test_i2_004_h1_anchor`            | FR-I2-CT-004   | H1 starts with `# Standard — Compliance Tiers`                                  |
| `_test_i2_005_frontmatter_version`  | FR-I2-CT-005/006 | `version: 1.0.0` + `last_reviewed: 2026-05-11` + `expires_at: 2027-05-11`     |
| `_test_i2_006_h2_sections`          | FR-I2-CT-020   | ≥ 6 `^## ` H2 anchors                                                           |
| `_test_i2_007_tier_definitions_verbatim` | FR-I2-CT-022 | T1/T2/T3 substrings reproduced byte-identical to schema (grep -F)              |
| `_test_i2_008_matrix_rows`          | FR-I2-CT-023   | ≥ 15 `|` table rows under `## Component eligibility matrix`                     |
| `_test_i2_009_demeter_crosslink`    | FR-I2-CT-024   | At least one `demeter` cross-link + reference to FR-K3-DEM-068                  |
| `_test_i2_010_interdictions`        | FR-I2-CT-027   | ≥ 3 `MUST NOT` occurrences under `## Interdictions`                             |
| `_test_i2_011_index_entry`          | FR-I2-CT-040   | `id: global/compliance-tiers` line in `.forge/standards/index.yml`              |
| `_test_i2_012_review_entry`         | FR-I2-CT-050   | `## 2026-05-11 — Initial ratification (i2-compliance-tiers)` in `REVIEW.md`     |

Additionally (optional L1 — already in the harness if budget
permits) :
- `_test_i2_013_compliance_doc` — FR-I2-CT-090..092 docs/COMPLIANCE.md presence + H1 + 3 H2s.
- `_test_i2_014_changelog_entry` — FR-I2-CT-080 CHANGELOG.md entry.

The 12 minimum + 2 optional = 14 total when budget allows.

### L2 fixture-based (deferred)

No L2 tier in this initial release. The standard is documentation —
no fixture tree exercises a runtime surface. If future I.3 / I.5
work introduces enforcement that touches the standard's
forward-pointer, an L2 tier may follow.

---

## Verbatim citation pin

The schema source-of-truth pin :

```
file: .forge/schemas/compliance-tier.schema.json
version: 1.0.0
field: x-tier-descriptions
```

The three T1 / T2 / T3 strings pinned at design time (exact bytes
match required by NFR-I2-CT-004) :

- **T1** : `"RGPD-compliant via DPA — SaaS hors EU acceptable si DPA + SCC + protections complémentaires (chiffrement, BYOK), assume risque résiduel CLOUD Act."`
- **T2** : `"Self-hostable — déployable sur n'importe quel K8s EU, contrôle technique mais pas qualification sovereign."`
- **T3** : `"Hébergement EU strict — SecNumCloud / HDS / EUCS High, 100% EU jurisdiction, immune CLOUD Act."`

The harness asserts each string is present via `grep -F` (fixed
string match, no regex interpretation). If the schema bumps
version (e.g. T.X follow-up amends a description), the standard's
prose MUST update synchronously — captured as an Interdiction +
locked by a future drift-detector.

---

## Cross-references

- **Constitution** : v1.1.0 (Articles III.4, V, XI, XII —
  preserved, not amended).
- **Schema** : `compliance-tier.schema.json` v1.0.0 (T.4) — single
  source of truth ; the standard mirrors it verbatim.
- **Demeter** : `.claude/agents/demeter.md` (K.3) — primary
  consumer of the standard.
- **Janus** : `.claude/agents/cross-layer-orchestrator.md` (J.8) —
  refusal rules J8-RULE-002 / J8-RULE-003 enforce against T3
  declarations.
- **Architecture** : `docs/ARCHITECTURE-TARGET.md` §10 + §10.2 +
  §10.3 — narrative source the standard mirrors.
- **Lifecycle** : `global/standards-lifecycle.md` (T.4) — 12-month
  review cadence + frontmatter contract.

## Out-of-scope reaffirmations

- **I.3 T3-forbidden linter rule** : ships in a separate change.
  This standard's `linter_rule: t3-forbidden-components` is a
  forward-pointer ; the matching section anchor in
  `constitution-linter.sh` is I.3's job.
- **I.5 forge-compliance.yml workflow** : ships in a separate
  change. This standard provides the citation anchor.
- **I.6 regulatory deadlines artefacts** : ships in a separate
  change (Themis K.5 territory, T7+). This standard documents the
  tier gradient ; regulatory artefacts cite the standard but live
  in `.forge/compliance/` (not yet created).
- **K.3 deliverables** : already shipped 2026-05-10. No edit.
- **Constitution** : no amendment. No Article touched.
