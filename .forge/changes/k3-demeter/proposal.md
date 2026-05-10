# Proposal: k3-demeter
<!-- Created: 2026-05-10 -->
<!-- Schema: default -->

## Problem

`docs/ARCHITECTURE-TARGET.md` §9.2 (table line 717) and
`docs/new-archetypes-plan.md` §1.4 line 353 + §7.1 line 733 + §9
lines 779 mandate a new Forge agent **Demeter** — *data steward
EU* — whose responsibilities are :

1. **Classify data** flows and persistence boundaries against the
   compliance tier ladder T1 / T2 / T3 already encoded in
   `.forge/schemas/compliance-tier.schema.json` v1.0.0 (shipped by
   `t4-adr-ratification`).
2. **Validate Data Processing Agreements (DPA)** at tier T1, where
   non-EU SaaS components remain acceptable provided a DPA + SCC +
   complementary protections (encryption, BYOK) are in place
   (per `compliance-tier.schema.json::x-tier-descriptions.T1`).
3. **Detect CLOUD Act exposure** in dependency manifests across the
   three Forge-supported package ecosystems : `Cargo.toml` (Rust),
   `pubspec.yaml` (Dart / Flutter), `package.json` (Node / TS / JS).
   The detection MUST be deterministic, offline-friendly, and
   require no paid scanning service.
4. **Plug into Janus** — the cross-layer orchestrator that already
   ships J8-RULE-001..003 refusal rules via `j8-janus-rules`
   (archived 2026-05-10). Demeter contributes `K3-RULE-*` findings
   that Janus can surface at scaffold time and at review time.
5. **Be discoverable** through the standards-injection mechanism
   (`.forge/standards/index.yml` triggers) and the Forge agent
   dispatch table (`CLAUDE.md` triggers + `dispatch-table.yml`).

Today none of this exists :

- The Demeter persona file (`.claude/agents/demeter.md`) is **not**
  on disk. The agent is referenced by name in
  `docs/ARCHITECTURE-TARGET.md` §9.2 + §11.2 line 800 ("Inventaire
  dépendances pour conformité CLOUD Act (agent Demeter, K.3)") and
  in `docs/new-archetypes-plan.md` §1.4 line 353 + §7.1 line 733,
  but no agent file backs the prose.
- No deterministic dependency scanner ships in `bin/` for CLOUD
  Act exposure. Adopters who want to pre-flight a project for T2 /
  T3 posture must hand-roll their own detection logic.
- No DPA-validation rule lives in any standard. The flag
  `--eu-tier T1` (shipped by `j8-janus-rules` FR-J8-040..043) is
  accepted by the CLI but no agent currently asserts that the
  adopter has a DPA on file for the SaaS components their tier
  permits.
- No `K3-RULE-NNN` namespace exists. The Janus rule format
  (`J8-RULE-NNN` per `j8-janus-rules` ADR-J8-004) was designed to
  be extensible per-audit-module ; this change consumes the next
  prefix.

The first three gaps are **agent-shape** decisions (persona file
+ dependency scanner + DPA-validation logic). The fourth is a
**standards-and-dispatch** integration concern. They were planned
together as K.3 in the audit roadmap because they form the EU
data-stewardship "first responder" of the Forge offering, and
because none of the downstream items I.2 / I.3 / I.5 / I.6 — which
schedule themselves *after* K.3 in the new-archetypes-plan §10 (T5
through T7 phases) — can ship without a Demeter persona to wire
them to.

This change closes the four gaps **at the spec layer only**. The
implementation (the agent file itself, the scanner script, the
dispatch-table edits, the test harness) is reserved for the
follow-up `/forge:implement k3-demeter` invocation.

## Solution

Three coordinated sub-modules under one umbrella change :

### K.3.a — Demeter persona (`.claude/agents/demeter.md`)

A new agent file authored in the existing Forge agent style
(compare `security-auditor.md` / Aegis, `observability-specialist.md`
/ Panoptes). The file declares :

- **Persona** : name, role, style.
- **Purpose** : data classification + DPA validation + CLOUD Act
  exposure detection.
- **Checklists** : one per responsibility, mirroring the Aegis
  severity-first format. Output of a Demeter audit is a
  **Data Stewardship Report** with severity, evidence, and
  remediation.
- **Rule catalogue** : `K3-RULE-001..NNN` namespace, allocated by
  this spec.
- **Integration** : how Demeter is invoked (Janus dispatches at
  step 9 alongside Aegis ; CLI dispatches via
  `forge audit --compliance` when shipped per ARCHITECTURE-TARGET
  §12.4 line 952).
- **Anti-hallucination protocol** : `[NEEDS CLARIFICATION:]`
  emission rules consistent with Article III.4.

### K.3.b — Deterministic dependency scanner

A new script `bin/forge-demeter-scan.sh` (one-shot, offline,
no paid services) that walks a target tree for the three lockfile
formats Forge supports :

- `Cargo.lock` (Rust)
- `package-lock.json` OR `pnpm-lock.yaml` OR `yarn.lock` (npm
  family)
- `pubspec.lock` (Dart / Flutter)

For each detected dependency, the scanner classifies the package
**publisher jurisdiction** against a built-in deny-list of known
US-jurisdiction publishers (the `forge-demeter-cloud-act-list.yml`
data file). The classification is deterministic, reproducible,
byte-stable when `SOURCE_DATE_EPOCH` is set (NFR-K3-DEM-005,
mirrors `forge-sbom.sh` from J.8.d).

The output is a **Data Stewardship Report** in JSON format
(machine-parseable) and a human-readable Markdown summary.

### K.3.c — Standards + dispatch integration

- New standard
  `.forge/standards/global/data-stewardship-rules.md` codifies
  the K3-RULE-* catalogue + the Schrems II / CLOUD Act / RGPD
  rationale at the standards layer (mirrors
  `global/janus-orchestration-rules.md` shipped by J.8).
- `.forge/standards/index.yml` gains a new entry pointing at the
  standard with triggers like `[demeter, data-steward, dpa,
  cloud-act, t1, t2, t3, dependency-jurisdiction]`.
- `.forge/scaffolding/dispatch-table.yml` is **NOT** edited by
  this change — Demeter is invoked by Janus, not by the CLI's
  init dispatcher. The dispatch surface for Demeter is
  documented in the standard above.
- `.claude/agents/cross-layer-orchestrator.md` (Janus) gains a
  one-line cross-link to Demeter in its dispatch table (Step 9
  mirror — Aegis + Demeter run in parallel as the security /
  data-stewardship pass). This edit is **implementation** not
  spec ; it is captured in `tasks.md` not `proposal.md`.

## Scope In

- New persona file `.claude/agents/demeter.md` (≈ 250–350 LOC,
  same density as `security-auditor.md`).
- New scanner `bin/forge-demeter-scan.sh` (bash thin + Python 3
  inline, mirrors F.2 / J.7 / J.8.d pattern verbatim per
  NFR-K3-DEM-004).
- New data file
  `.forge/data/cloud-act-publishers.yml` — curated, dated,
  versioned list of known US-jurisdiction publishers per
  ecosystem (cargo / npm / pub).
- New standard `.forge/standards/global/data-stewardship-rules.md`.
- New `.forge/standards/index.yml` entry registering the standard.
- One-line edit to `.claude/agents/cross-layer-orchestrator.md`
  cross-linking Demeter from the Janus dispatch table.
- New `K3-RULE-NNN` rule catalogue, namespace allocation per
  ADR-J8-004 extension.
- Test harness `.forge/scripts/tests/k3.test.sh` (≥ 18 L1 tests
  + 2 L2 fixture tests, mirrors j8.test.sh layout).
- Doc updates : new H2 in `docs/AGENTS.md` (or wherever the
  agent catalogue currently lives — locked at design time) +
  `CHANGELOG.md` `## [Unreleased]` entry.

## Scope Out (Explicit Exclusions)

- **NOT** the `global/compliance-tiers.md` standard (item I.2
  in `new-archetypes-plan` §7.1). That standard documents the
  T1/T2/T3 matrix in narrative form and is scheduled for a
  later T5 change.
- **NOT** the T3-specific linter rule that refuses Firebase /
  Datadog / AWS-managed in `compliance_tier: T3` changes (item
  I.3). That ships as a follow-up after `compliance-tiers.md`
  lands.
- **NOT** the `forge-compliance.yml` GitHub workflow (item I.5).
  It depends on Demeter + the CycloneDX SBOM (J.8.d, already
  shipped) + license scanners (deferred). Workflow ships in a
  later T5 / T6 change.
- **NOT** the regulatory-deadlines artefacts under
  `.forge/compliance/` (item I.6 — NIS2 / DORA / CRA / AI Act
  schedules). Themis (K.5) is the agent for those, scheduled
  T7.
- **NOT** any new compliance tier beyond T1 / T2 / T3.
  `compliance-tier.schema.json` v1.0.0 is consumed verbatim ;
  no schema bump.
- **NOT** an automated DPA-document parser. Demeter validates
  that the adopter has *declared* DPA presence (e.g. via a
  `.forge/.forge-dpa-declared` ledger or a `dpa:` block in
  `.forge.yaml`). Document-level DPA verification (legal-text
  parsing, signature checking) is out of scope.
- **NOT** any change to the J8-RULE-* catalogue. Demeter rules
  use the K3-RULE-* prefix per ADR-J8-004 extension protocol.
- **NOT** modifications to `cli/src/commands/init.ts` or any
  TypeScript surface. Demeter is a `.claude/agents/` persona +
  a bash/Python scanner — no CLI flag plumbing.
- **NOT** retroactive scanning of already-archived changes.
  Demeter operates on the live tree at invocation time.
- **NOT** the `.claude/agents/demeter.md` file itself in this
  PR. **This change is spec-only**. The persona file is the
  GREEN state of `/forge:implement k3-demeter`, not of
  `/forge:specify` / `/forge:design` / `/forge:plan`.

## Impact

- **Users affected** :
  - Adopters running EU-aware Forge projects gain an
    auditable, scriptable T1/T2/T3 classification + CLOUD Act
    exposure scan.
  - Adopters at T1 (RGPD-via-DPA) get a clear declaration
    surface for their DPA posture.
  - Janus (orchestrator) gains a sibling agent at Step 9
    alongside Aegis ; cross-layer reviews now cover
    data-stewardship as a first-class concern.
  - No change at all for adopters not declaring `--eu-tier`
    (NFR-K3-DEM-002 backward compat).
- **Technical impact** : ≈ 5 new files (persona, scanner,
  cloud-act publisher list, standard, harness) + ≈ 3 modified
  (Janus agent cross-link, standards index, CHANGELOG). Test
  harness ≥ 18 L1 + 2 L2. **Effort `M`** per
  `new-archetypes-plan` §1.4 row K.3.
- **Dependencies** :
  - T.4 `compliance-tier.schema.json` v1.0.0 — shipped 2026-05-04.
  - T.4 `archetype.schema.json` v2 — shipped 2026-05-04.
  - J.8 `j8-janus-rules` archived 2026-05-10 — ships
    `J8-RULE-NNN` format that K3-RULE-* extends ; ships
    `bin/forge-sbom.sh` whose F.2/J.7/J.8.d pattern Demeter's
    scanner reuses verbatim (NFR-K3-DEM-004).
  - No new external dependency. Scanner uses `python3` stdlib
    + PyYAML (already required by F.2 / J.7 / J.8.d).
- **Risk level** : **Low → Medium**. The persona file is pure
  documentation ; the scanner is bounded by deterministic
  parsing of three lockfile formats (already proven viable by
  `forge-sbom.sh` in J.8.d). The only meaningful risk is
  **maintaining the cloud-act publisher list** — false
  negatives understate exposure, false positives annoy
  adopters. Mitigated by NFR-K3-DEM-008 (versioned data file
  + a `last_reviewed` timestamp + a published review cadence
  in the standard).

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`k3.test.sh` with ≥ 18 L1 + 2 L2 stubs all returning
`_not_implemented` (full RED witness). Phase 2 implements one
cluster at a time.

### Article II — BDD

User-facing flows get Gherkin scenarios in `specs.md` :

- `Given a target tree at compliance_tier T2, When the scanner
  runs, Then any us-jurisdiction publisher in Cargo.lock is
  flagged with severity HIGH.`
- `Given a project declaring --eu-tier T1 without a
  .forge/.forge-dpa-declared marker, When Demeter is invoked,
  Then it emits a [NEEDS CLARIFICATION: DPA declaration missing]
  marker.`
- `Given a clean target tree (no US-jurisdiction publishers,
  T3 declared), When the scanner runs, Then it exits 0 with a
  CLEARED verdict in the JSON report.`

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with
`FR-K3-DEM-*` namespace before any implementation.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Open questions captured in `open-questions.md` ; resolved before
status flips to `implemented`.

### Article V — Audit Trail

Each task tagged `[Story: FR-K3-DEM-XXX]` (Article V.1, enforced
by `f4-linter-extension`). Demeter findings reference rule IDs
in the format `K3-RULE-NNN: <reason> ; remediation: <path>`,
machine-parseable and consistent with the `j8-janus-rules`
`[REFUSAL: ...]` format.

### Article VIII — Infrastructure

The scanner is a one-shot bash + Python 3 inline script. No
service, no daemon, no privileged ops. The standard documents
the regeneration cadence for the cloud-act publisher list
(NFR-K3-DEM-008).

### Article IX — Observability

N/A directly. Demeter does not emit OTel telemetry — it is a
spec-time / review-time agent, not a runtime component. If a
future change wraps Demeter in a CI workflow (item I.5), that
workflow will instrument itself per `observability.yaml`.

### Article XI — AI-First Design

Demeter is a Claude-Code agent persona (Article XI.1
agent-native architecture compliant). Its outputs are
deterministic structured documents (the JSON report + the
markdown summary) — no opaque LLM-generated text consumed
downstream without human review (XI.3 schema-driven principle
preserved).

### Article XII — Governance

Demeter ENFORCES the EU compliance posture encoded in T.4 ADRs
(ADR-007 / ADR-008 / ADR-010 of `t4-adr-ratification`). It does
**not amend** any constitutional article. The new standard
(`global/data-stewardship-rules.md`) is MD, not YAML ; it does
not carry the J.7 frontmatter contract.

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`proposal.md`. Three open questions Q-001 + Q-002 + Q-003
raised at this phase, all tracked in `open-questions.md` and
slated for resolution during `/forge:design` :

- **Q-001** — DPA declaration surface : `.forge/.forge-dpa-declared`
  ledger file (mirrors `.forge-tier` from J.8) vs a `dpa:` block
  in the change `.forge.yaml` vs both?
- **Q-002** — cloud-act-publishers.yml maintenance cadence : who
  curates, on what frequency, what triggers a refresh?
- **Q-003** — K3-RULE namespace allocation : do we pre-allocate
  10 rules now (K3-RULE-001..010) or grow the catalogue
  incrementally as findings emerge?
