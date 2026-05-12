# Spec: data-stewardship

<!-- Audit: K.3 + I.4 (k3-demeter) — Demeter persona, T1/T2/T3 classification, DPA validation, CLOUD Act dependency scanner. -->
<!-- Source change : `.forge/changes/k3-demeter/` (archived 2026-05-12). -->

**Namespace** : `FR-K3-DEM-*` / `NFR-K3-DEM-*`. **Constitution** : v1.1.0.
Pas d'amendement requis (K.3 introduces a new agent + scanner + standard ;
existing articles unchanged).

**Six physical deliverables** (per `tasks.md`) :

- **K.3.a** — `.claude/agents/demeter.md` persona file (7 H2 sections —
  Persona, Purpose, Checklists, Output, Rule Catalogue, Integration,
  Anti-Hallucination Protocol). Sibling to Aegis ; Aegis owns
  vulnerability posture, Demeter owns data-stewardship posture
  (jurisdiction, DPA, PII classification).
- **K.3.b** — `bin/forge-demeter-scan.sh` deterministic dependency
  scanner (F.2 / J.7 / J.8.d pattern verbatim). Walks
  Cargo / npm / pubspec lockfiles under `--target` and matches each
  dependency's publisher against the curated deny-list. Tier-scaled
  severity. Bash thin + Python 3 inline. `SOURCE_DATE_EPOCH` reproducible.
- **K.3.c** — `.forge/data/cloud-act-publishers.yml` deny-list (4
  cargo + 4 npm + 2 pub publisher patterns covering
  AWS / Google Cloud / Azure / Firebase ecosystems, with citable
  evidence URLs).
- **K.3.d** — `.forge/standards/global/data-stewardship-rules.md`
  authoritative standard (7 H2 sections — rule catalogue, adoption
  path, DPA declaration semantics, extending the catalogue,
  regeneration cadence, constitutional compliance).
- **K.3.e** — `.forge/scripts/tests/k3.test.sh` test harness (20 L1 + 2
  L2 tests, registered in `forge-ci.yml` matrix after `j8.test.sh`).
- **K.3.f** — Janus delta integration (cross-layer-orchestrator.md
  dispatch row + Step 9 rename + Quality Gates bullet, per ADR-K3-007).

**Note** : The persona file (K.3.a) + Janus delta (K.3.f) were
authored under a manual handoff after the K.3.b/K.3.c/K.3.d/K.3.e
machinery shipped. The harness asserts both surfaces at L1 ; 22/22
tests GREEN at archive time.

**Manual user follow-ups (out of K.3 scope)** :
- **I.2–I.6** : `global/compliance-tiers.md` standard, T3-forbidden
  linter rule, `forge-compliance.yml` workflow, NIS2 / DORA / CRA /
  AI Act artefacts in `.forge/compliance/` (beyond the CycloneDX
  piece shipped in J.8.d).
- **K.3-RULE-006+** : incremental rule growth — `K3-RULE-NNN`
  namespace per ADR-K3-005 ; future rules append, IDs never reused.
- **Themis hand-over (Phase B)** : at T7 K.5 ship,
  `.forge/data/cloud-act-publishers.yml::maintained_by` flips from
  BDFL to Themis ; cadence tightens 12-month → 6-month per
  ADR-K3-003.

---

## Functional Requirements

### Cluster 1 — Demeter persona file (FR-K3-DEM-001..008)

#### FR-K3-DEM-001 — Persona file location

`.claude/agents/demeter.md` exists as the canonical Demeter persona
file at the path locked by ADR-K3-001. The file follows the
`.claude/agents/<name>.md` convention used by all 16 existing Forge
agents (e.g. `security-auditor.md`, `observability-specialist.md`).

#### FR-K3-DEM-002 — Persona section

The file starts with an H1 `# Agent: Data Steward EU (Demeter)` and
a `## Persona` H2 declaring Name (Demeter), Role (data steward EU),
and Style (methodical, severity-first, evidence-driven, mirroring
Aegis).

#### FR-K3-DEM-003 — Purpose section

A `## Purpose` H2 describes Demeter's three responsibilities and
cites the source audit items (K.3 + I.4) and the upstream T.4 schema
consumed (`compliance-tier.schema.json`).

#### FR-K3-DEM-004 — Checklists section (3 H3 sub-sections, ≥ 5 `[ ]` items each)

A `## Checklists` H2 hosts Data Classification + DPA Validation +
CLOUD Act Exposure H3 sub-sections, each greppable for `[ ]` markers
in the Aegis bullet-checklist style.

#### FR-K3-DEM-005 — Output report format

An `## Output: Data Stewardship Report` H2 declares the report shape
(Summary severity counts, Findings entries, Cleared Items, overall
status `BLOCKED` / `CONCERNS` / `CLEARED`).

#### FR-K3-DEM-006 — Rule catalogue section

A `## Rule Catalogue` H2 enumerates the seed `K3-RULE-*` rules (5
seed rules + 1 operational guardrail per ADR-K3-005).

#### FR-K3-DEM-007 — Integration section

A `## Integration` H2 describes Janus Step 9 dispatch + the
`forge audit --compliance` invocation path + the relationship to
Aegis (parallel passes, no overlap).

#### FR-K3-DEM-008 — Anti-Hallucination Protocol

An `## Anti-Hallucination Protocol` H2 explicitly states Demeter
MUST emit `[NEEDS CLARIFICATION:]` rather than guess on ambiguous
classification (mirroring Aegis + Atlas patterns).

---

### Cluster 2 — Audit-comment header anchors (FR-K3-DEM-010..011)

#### FR-K3-DEM-010 — Persona audit anchor

`.claude/agents/demeter.md` carries a `<!-- Audit: K.3 + I.4 ... -->`
HTML comment at the top of the file (Article V audit trail).

#### FR-K3-DEM-011 — Standard audit anchor

`.forge/standards/global/data-stewardship-rules.md` carries a
`<!-- Audit: K.3 (k3-demeter) -->` HTML comment.

---

### Cluster 3 — T1 / T2 / T3 classification logic (FR-K3-DEM-020..026)

Tier-scaled severity matrix per FR-K3-DEM-068 :

| Detection                  | T1 (RGPD-DPA)       | T2 (self-host)      | T3 (SecNumCloud)    |
|----------------------------|---------------------|---------------------|---------------------|
| US-jurisdiction publisher  | Informational       | High                | Critical            |
| DPA missing                | High                | N/A (informational) | N/A (informational) |
| Tier-inconsistent component| Informational       | High                | Critical            |

Reads `.forge/.forge-tier` ledger (FR-K3-DEM-021 — J.8 ADR-J8-006
plain-text 1-line). Absence falls back to **T1 default**
(FR-K3-DEM-022) ; emits `[INFO]` only.

---

### Cluster 4 — DPA validation (FR-K3-DEM-040..044)

Reads `.forge/.forge-dpa-declared` plain-text ledger (resolved by
ADR-K3-002, Q-001). Content shape `T1: <ISO-8601-date>
<free-form-ref>` (FR-K3-DEM-041). Mirrors J.8 ADR-J8-006 ledger
pattern verbatim.

Demeter does **NOT** parse legal documents (FR-K3-DEM-044 — out of
scope per proposal). It only verifies declaration presence ;
schema-validatable structured DPA metadata explicitly rejected (would
creep toward legal parsing).

---

### Cluster 5 — CLOUD Act dependency detection (FR-K3-DEM-060..074)

`bin/forge-demeter-scan.sh` walks `Cargo.lock` + `package-lock.json` /
`pnpm-lock.yaml` / `yarn.lock` + `pubspec.lock` recursively (depth
≤ 3) under `--target`. Each dependency's publisher (cargo `[[package]]`
publisher field, npm `homepage` + `repository` URL host, pubspec
`description.repository`) is matched against the deny-list at
`.forge/data/cloud-act-publishers.yml::ecosystems.{cargo,npm,pub}`.

Each match emits a JSON finding with `rule_id` `K3-RULE-001` and
tier-scaled severity per FR-K3-DEM-068. Cumulative result :
overall status `BLOCKED` (any Critical or High) / `CONCERNS` (any
Medium) / `CLEARED` (only Informational or no findings).

Exit code envelope mirrors J.8 ADR-J8-003 : `0` CLEARED, `1`
CONCERNS, `2` usage error, `3` BLOCKED (policy refusal).

Deny-list (FR-K3-DEM-073) seeds :
- **Cargo** : `aws-*` (Amazon), `azure-*` (Microsoft Azure),
  `google-cloud-*` (Google), `firebase-*` (Google Firebase).
- **npm** : `@aws-sdk/*`, `@azure/*`, `@google-cloud/*`,
  `firebase-*`.
- **pubspec** : `firebase_*`, `google_cloud_*`.

Each entry carries `evidence_url:` + `jurisdiction: US` + free-form
`rationale:`.

---

### Cluster 6 — Constitution-linter / Janus / dispatch-table integration (FR-K3-DEM-080..086)

#### FR-K3-DEM-080 — Janus dispatch row

`.claude/agents/cross-layer-orchestrator.md` Dispatch Table gains
the Demeter row (one new row, inserted after the Aegis row).
Delta-based modification per Article IV.1 ; ADR-K3-007 locks the
shape.

#### FR-K3-DEM-081 — Step 9 rename

`.claude/agents/cross-layer-orchestrator.md` H3
`### Step 9 — Security Pass (Aegis)` is renamed to
`### Step 9 — Security & Data-Stewardship Pass (Aegis + Demeter)` ;
the existing Aegis paragraph is preserved unchanged ; a new Demeter
paragraph is appended describing the parallel data-stewardship
review.

#### FR-K3-DEM-082 — Quality Gates bullet

The `Quality Gates` H2 of `cross-layer-orchestrator.md` gains a
"Data-stewardship gate — dispatched to Demeter at step 9 alongside
Aegis" bullet.

#### FR-K3-DEM-083 — Constitution Compliance bullet

The `Constitution Compliance` H2 gains an Article IX.X /
Article XII reference for cross-layer data stewardship.

#### FR-K3-DEM-084 — Repository CLAUDE.md trigger

The repository-level `CLAUDE.md` agent-table gains the Demeter
trigger row, inserted alphabetically between Oracle and Clio.

#### FR-K3-DEM-085 — Standards index registration

`.forge/standards/index.yml` registers
`global/data-stewardship-rules.md` under the "Cross-Cutting
Standards" section.

#### FR-K3-DEM-086 — Namespace collision guard

`K3-RULE-*` namespace MUST NOT collide with `J8-RULE-*` (per
ADR-J8-004 inheritance). Asserted by harness test 020 (greps
both catalogues + verifies disjoint prefix sets).

---

### Cluster 7 — Test harness `k3.test.sh` (FR-K3-DEM-100..102)

#### FR-K3-DEM-100 — Harness location

`.forge/scripts/tests/k3.test.sh` exists, follows the F.2 / J.7 /
J.8 pattern (bash test runner + Python 3 inline assertions).

#### FR-K3-DEM-101 — L1 unit-level (≥ 18 tests)

L1 phase covers the persona file (9 tests : exists, audit comment,
H2 sections × 6, anti-hallucination), the scanner (4 tests :
signature, exits, no-lockfile, publisher-list metadata), the
standard (2 tests), the index registration (1 test), the Janus
dispatch row + Step 9 modification (2 tests), CLAUDE.md trigger
(1 test), namespace collision guard (1 test). Total **20 L1
tests**, all GREEN at archive time.

#### FR-K3-DEM-102 — L2 fixture-based (2 tests)

L2 phase exercises the scanner end-to-end against fixture trees :
**(a)** deny-list-hit at T3 → exit 3 BLOCKED + Critical K3-RULE-001
finding ; **(b)** clean-tree at T2 → exit 0 CLEARED + byte-identical
re-run with `SOURCE_DATE_EPOCH=0` (reproducibility per
NFR-K3-DEM-005). Both GREEN at archive time.

---

### Cluster 8 — Documentation (FR-K3-DEM-110..112)

CHANGELOG `[Unreleased]` entry (FR-K3-DEM-110), repository
`CLAUDE.md` Demeter trigger row (FR-K3-DEM-111 = FR-K3-DEM-084
re-pointer), and the new standard
`global/data-stewardship-rules.md` (FR-K3-DEM-112) jointly cover
the documentation surface.

---

### Cluster 9 — Seed K3-RULE catalogue (FR-K3-DEM-120..124)

Per ADR-K3-005 (resolves Q-003 — incremental growth, 5 seed rules
+ 1 operational guardrail).

| Rule        | Trigger                                                                          | Severity                              | FR ref       |
|-------------|----------------------------------------------------------------------------------|---------------------------------------|--------------|
| K3-RULE-001 | Dependency publisher in `cloud-act-publishers.yml` deny-list                     | Tier-scaled (T1 Info / T2 High / T3 Crit) | FR-K3-DEM-120 |
| K3-RULE-002 | `compliance_tier: T1` + ⚠️-T1 component used + `.forge-dpa-declared` absent       | High                                  | FR-K3-DEM-121 |
| K3-RULE-003 | New US-jurisdiction dependency introduced in T2/T3 project (diff-based, future I.5) | T2 High / T3 Critical                 | FR-K3-DEM-122 |
| K3-RULE-004 | Domain entity carries PII (heuristic field-name list per ADR-K3-006) without `data_classification:` block | Medium                                | FR-K3-DEM-123 |
| K3-RULE-005 | Cargo workspace drift — `Cargo.toml` declares dep missing from `Cargo.lock`      | Medium                                | FR-K3-DEM-124 |
| K3-RULE-006 | Publisher list staleness — `expires_at < today`                                  | Medium (operational guardrail)        | NFR-K3-DEM-008 |

Future K.3 extensions append `K3-RULE-007+`. Future audit modules
use their own prefix (`K5-RULE-NNN` for Themis at T7+). Per
ADR-J8-004 inheritance, IDs are NEVER reused — decommissioned
rules carry `DEPRECATED`, the slot is not recycled.

---

## Non-Functional Requirements

### NFR-K3-DEM-001 — Performance budget

`bin/forge-demeter-scan.sh` MUST complete in ≤ 8 s on
`examples/forge-fsm-example/` (small monorepo, ≈ 50 deps across
the three lockfiles). Harness `--level 1` ≤ 5 s ; full
`--level 1,2` ≤ 20 s. **Measured** : harness `--level 1,2`
≈ 2 s.

### NFR-K3-DEM-002 — Backward compatibility

Purely additive. Adopters not invoking Demeter (no
`forge audit --compliance` call, no Janus cross-layer review)
observe ZERO behavioural change.

### NFR-K3-DEM-003 — Article V audit trail

Every task tagged `[Story: FR-K3-DEM-XXX]`. Every Demeter finding
carries `K3-RULE-NNN` + structured JSON shape, machine-parseable
per Article V.1 (enforced by `f4-linter-extension`).

### NFR-K3-DEM-004 — F.2 / J.7 / J.8 pattern alignment

`bin/forge-demeter-scan.sh` follows the bash + Python 3 inline
pattern of `forge-sbom.sh` (J.8.d), `validate-standards-yaml.sh`
(J.7), `validate-change-yaml.sh` (F.2). No new external dependency
(PyYAML already required).

### NFR-K3-DEM-005 — Reproducibility

Scanner output byte-identical across consecutive runs when
`SOURCE_DATE_EPOCH` is set (mirrors `forge-sbom.sh` NFR-J8-005).
Reproducible-build convention preserved.

### NFR-K3-DEM-006 — No paid scanning service

Demeter MUST NOT depend on Snyk / Sonatype / JFrog Xray / GitHub
Advanced Security or any paid scanning service. Deny-list
approach curated in-repo (governance per NFR-K3-DEM-008).

### NFR-K3-DEM-007 — TypeScript strict mode preserved

This change does NOT touch any `cli/src/**.ts` file — Demeter is
bash + Python + Markdown only. Asserted as a structural guard so
future task-creep is caught at review.

### NFR-K3-DEM-008 — Publisher list governance

`.forge/data/cloud-act-publishers.yml` carries `version:` (SemVer,
bumped on any deny-list edit), `last_reviewed:` (ISO-8601),
`expires_at:` (12-month default in interim, 6-month post-Themis
per ADR-K3-003), `maintained_by:` (BDFL interim → Themis post-T7).

### NFR-K3-DEM-009 — Anti-hallucination on classification

When a publisher's jurisdiction is ambiguous (multinational, recent
acquisition not reflected in deny-list), the scanner emits a
`[NEEDS CLARIFICATION:]` JSON entry instead of a finding. The
adopter (or Themis at review time) resolves upstream, not the
scanner.

---

## ADRs (K.3 design)

| ID         | Decision                                                                                                                                                                |
|------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ADR-K3-001 | Persona file path = `.claude/agents/demeter.md` (matches all 16 existing agents). H1 = `# Agent: Data Steward EU (Demeter)`.                                            |
| ADR-K3-002 | DPA declaration surface = `.forge/.forge-dpa-declared` plain text (mirrors J.8 ADR-J8-006 `.forge-tier` ledger verbatim). Rejects YAML-structured DPA block (legal creep). Resolves Q-001. |
| ADR-K3-003 | Publisher list governance = two-phase. **Phase A (interim T5 → T7)** BDFL curates, 12-month default per `global/standards-lifecycle.md`. **Phase B (post-K.5 / Themis T7+)** Themis curates, 6-month rolling. Resolves Q-002. |
| ADR-K3-004 | Scanner architecture = F.2 / J.7 / J.8.d pattern verbatim. Bash thin + Python 3 inline. Zero new external dep (PyYAML already required).                                |
| ADR-K3-005 | Rule-ID namespace = `K3-RULE-NNN` (audit-prefix + sequential, inherits J.8 ADR-J8-004 format). 5 seed rules + 1 operational guardrail. Incremental growth. IDs never reused. Resolves Q-003. |
| ADR-K3-006 | PII heuristic for K3-RULE-004 = explicit field-name list (`email`, `phone`, `ssn`, `iban`, `dob`, …). Conservative scope ; deferred extensions in future K3-RULE-007+.    |
| ADR-K3-007 | Janus integration = delta MODIFICATION to Step 9, no full rewrite. Dispatch row + H3 rename + Demeter paragraph appended ; Article IV.1 compliance.                     |

Full design rationale + Mermaid diagrams + Open Questions resolution :
`.forge/changes/k3-demeter/design.md`.
