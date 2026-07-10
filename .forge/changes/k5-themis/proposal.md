# Proposal: k5-themis
<!-- Created: 2026-07-10 -->
<!-- Schema: default -->

## Problem

`docs/ARCHITECTURE-TARGET.md` §9.2 (table line 735) and
`docs/new-archetypes-plan.md` §9 line 2672 (Module K table) mandate a
new Forge agent **Themis** — *compliance officer EU* — whose
responsibilities are "Compliance officer NIS2/DORA/CRA + cycle
review-standards", archetype scope "tous EU" (every EU-tier
archetype). The plan doc pins the automation Themis owns as **`forge
review-standards`** (§9 line 2672 + §11.2 T7-recap lines 2224-2237 +
§2.3 P-3 lines 2220-2238).

The groundwork Themis builds ON TOP OF is **already shipped and
forward-stable**:

- **P-3 / T.4** shipped `.forge/standards/global/standards-lifecycle.md`
  (the 12-month `expires_at` review cadence) + `.forge/standards/REVIEW.md`
  (append-only ledger). The plan doc says the cadence *itself* is
  delivered (P-3) but the **automation** (`forge review-standards`) is
  "Pending (T7)" and "n'est pas automatisé — le mainteneur tient le
  calendrier manuellement jusqu'à K.5 livré" (§11.2 line 2236-2238).
- **I.2** shipped `global/compliance-tiers.md` (T1/T2/T3 gradient).
- **I.5** shipped `.github/workflows/forge-compliance.yml` — the plan
  says this workflow is "forward-stable pour les artefacts
  réglementaires Themis-territory … lorsque K.5 (T7+) livrera —
  additive step additions per FR-I5-CW-083" (§0.11 lines 449-451).
- **I.6** shipped `.forge/scripts/compliance/bundle.sh` — "Bundle
  layout is forward-stable for Themis-territory artefacts (NIS2 / DORA
  / CRA / AI Act regulatory deadlines) … additive expansion when
  Themis (K.5, T7+) ships, no breaking schema change" (§0.11 lines
  417-423).
- **K.3** shipped Demeter (`.claude/agents/demeter.md`) — the *sibling*
  data-steward agent. Demeter's persona already forward-declares the
  Themis relationship and reserves the `K5-RULE-NNN` namespace ("future
  audit modules use their own prefix (e.g. `K5-RULE-NNN` for Themis
  when K.5 ships)").

Today none of the Themis surface exists:

- The Themis persona file (`.claude/agents/themis.md`) is **not** on
  disk. The agent is referenced by name across the repo
  (`standards-lifecycle.md` "Themis hook (deferred — T7)",
  `compliance-tiers.md` Phase B governance, `demeter.md` "Relationship
  to Themis", `ai-act-dora-artefacts.md` Phase-B work items,
  `docs/GUIDE.md`, `docs/COMPLIANCE.md`) but no persona backs the prose.
- No `forge review-standards` automation ships in `bin/`. The 12-month
  cadence is tracked manually — a maintainer scans `verify.sh` for the
  `expires_at`-arrival WARN and opens review changes by hand.
- No `K5-RULE-NNN` namespace exists (reserved by Demeter's ADR-K3-005,
  never consumed).

## Solution

Three coordinated sub-modules under one umbrella change, mirroring the
K.3 (`k3-demeter`) shape:

### K.5.a — Themis persona (`.claude/agents/themis.md`)

A new agent file authored in the existing Forge agent style (mirrors
`demeter.md` / K.3 depth — ~9 H2 sections). The file declares Persona,
Purpose, an explicit **Boundary vs Demeter** section, Checklists (one
per responsibility), the output report shape, the `K5-RULE-NNN`
catalogue, Integration, the Anti-Hallucination Protocol, and audit
cross-references.

The boundary is load-bearing and MUST be explicit in the persona
itself: **Demeter** is the data steward — CLOUD Act detection, DPA
validation, tier classification at **SCAFFOLD-TIME / review-time** (when
a project is created or a PR is reviewed). **Themis** is the compliance
officer — regulatory-deadline tracking + standards review cadence at
**REPO-LIFECYCLE-TIME** (ongoing, ambient, time-triggered). The two
never overlap: Demeter answers "is this dependency US-jurisdiction at
severity X?"; Themis answers "which standards are past their review
window, and which NIS2/DORA/CRA/AI-Act deadlines are on the horizon?".

### K.5.b — `forge review-standards` CLI automation

A new script `bin/forge-review-standards.sh` (bash thin + Python 3
inline, mirrors the F.2 / J.7 / J.8.d / K.3 pattern verbatim). It
walks `.forge/standards/` for `last_reviewed` / `expires_at`
frontmatter (both top-level YAML in `*.yaml` standards and fenced
```yaml frontmatter blocks in `*.md` standards), classifies each
standard FRESH / DUE-SOON / EXPIRED against a configurable review
window, and emits a deterministic Standards Review Report (JSON or
Markdown). It carries a verbatim regulatory-deadline calendar
(NIS2 / DORA / CRA / AI Act) copied from `new-archetypes-plan.md`
§7.1's I.6 bullet, and OPTIONALLY (`--bundle`) drives the I.6
`bundle.sh` after emitting the regulatory-deadline summary. The tool
is **WARN-only** by default (a review debt never freezes the pipeline
— `standards-lifecycle.md` "WARN n'est jamais bloquant"); a `--strict`
opt-in flips expired standards to a blocking exit for adopters who
want a hard gate.

### K.5.c — Standards + workflow + dispatch integration

- New standard `.forge/standards/global/standards-review-rules.md`
  codifies the `K5-RULE-NNN` catalogue + the regulatory-deadline
  calendar + the review-cadence automation (mirrors K.3's
  `data-stewardship-rules.md`).
- `.forge/standards/index.yml` gains an entry with `themis` /
  `review-standards` / `nis2` / `dora` / `cra` / `ai-act` triggers.
- `.forge/standards/global/standards-lifecycle.md` "Themis hook
  (deferred — T7)" section is updated (delta, Article IV.1) to reflect
  that Themis has now shipped and `forge review-standards` is
  automated.
- New sibling CI workflow `.github/workflows/forge-standards-review.yml`
  (scheduled monthly + `workflow_call`) runs the cadence check
  ambiently — deliberately NOT bolted onto the per-PR blocking
  `forge-compliance.yml` gate (rationale in `design.md`).
- Registration parity with Demeter: `CLAUDE.md` agent-delegation row,
  `docs/GUIDE.md` transversal-agents table row, `docs/COMPLIANCE.md`
  Themis section (extends, does not fork).

## Scope In

- New persona file `.claude/agents/themis.md` (≈ 250–320 LOC, same
  density as `demeter.md`).
- New CLI `bin/forge-review-standards.sh` (bash thin + Python 3
  inline, mirrors `forge-demeter-scan.sh` per NFR-K5-THE-004).
- New standard `.forge/standards/global/standards-review-rules.md`.
- New `.forge/standards/index.yml` entry.
- New sibling workflow `.github/workflows/forge-standards-review.yml`.
- New `K5-RULE-NNN` rule catalogue (5 seed rules), namespace allocation
  per ADR-J8-004 extension.
- Test harness `.forge/scripts/tests/k5.test.sh` (≥ 20 L1 + 2 L2).
- Delta edits: `standards-lifecycle.md` Themis section, `CLAUDE.md`
  agent table, `docs/GUIDE.md` agent table, `docs/COMPLIANCE.md`,
  `CHANGELOG.md`, `.github/workflows/forge-ci.yml` harness matrix,
  `.forge/standards/REVIEW.md` birth entry.

## Scope Out (Explicit Exclusions)

- **NOT** a fork of `.forge/scripts/compliance/bundle.sh`. Themis
  **drives** the I.6 bundle (invokes it) — it does not replace or
  re-implement it. The bundle standard `compliance-artefacts-bundle.md`
  stays at v1.1.0 (its frontmatter is exact-pinned by
  `i6.test.sh::_test_i6_021`; a bump would break a sibling harness).
- **NOT** an edit to `.github/workflows/forge-compliance.yml` (I.5).
  Its step structure is pinned by `i5.test.sh::_test_i5_007`; the
  cadence check lives in a sibling workflow instead (design.md
  tradeoff).
- **NOT** authoring the full NIS2 / CRA regulatory artefact bodies.
  Themis emits a deterministic *deadline summary*; the deep legal
  determinations remain `[NEEDS CLARIFICATION]` Phase-B work per
  `ai-act-dora-artefacts.md` (Article III.4 — Forge does not invent
  legal specifics).
- **NOT** a change to Demeter's `K3-RULE-*` catalogue, the
  `.forge/data/cloud-act-publishers.yml` list, or `demeter.md`.
  Themis owns `K5-RULE-*`; the two namespaces never collide
  (ADR-J8-004).
- **NOT** a new compliance tier. `compliance-tier.schema.json` v1.0.0
  is consumed verbatim.
- **NOT** modifications to `cli/src/**.ts`. Themis is a
  `.claude/agents/` persona + a bash/Python CLI — no TypeScript
  surface.
- **NOT** a runtime OTel-emitting component. Themis is a
  repo-lifecycle-time / CI-time agent.

## Impact

- **Users affected**:
  - Maintainers of EU-tier Forge projects get an automated,
    scriptable standards-review cadence + a regulatory-deadline
    calendar — replacing the manual `verify.sh`-WARN scan documented
    as the interim in `standards-lifecycle.md`.
  - Adopters gain a CI-schedulable `forge-standards-review.yml` that
    surfaces review debt ambiently without blocking PRs.
  - No change for adopters who do not invoke `forge review-standards`
    or wire the new workflow (NFR-K5-THE-002 backward compat).
- **Technical impact**: ≈ 5 new files (persona, CLI, standard,
  workflow, harness) + ≈ 7 modified (standards-lifecycle, index,
  CLAUDE.md, GUIDE.md, COMPLIANCE.md, CHANGELOG, forge-ci, REVIEW.md).
  Test harness ≥ 20 L1 + 2 L2. **Effort `M`** per `new-archetypes-plan`
  §9 row K.5.
- **Dependencies**: all shipped to `main` (see `.forge.yaml`
  `depends_on`). No new external dependency — CLI uses `python3`
  stdlib + PyYAML (already required by F.2 / J.7 / J.8.d / K.3).
- **Risk level**: **Low**. The persona is documentation; the CLI is a
  bounded deterministic frontmatter walk (proven viable by
  `forge-sbom.sh` / `bundle.sh` / `forge-demeter-scan.sh`); the
  workflow is a sibling (no edit to the pinned I.5 gate); the bundle
  is driven, not forked (no edit to the pinned I.6 artefact).

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`k5.test.sh` with ≥ 20 L1 + 2 L2 stubs all FAIL (full RED witness).
Phase 2+ implements one cluster at a time.

### Article II — BDD

User-facing flows get Gherkin scenarios in `specs.md`:

```gherkin
Given a standards tree with one standard whose expires_at is in the past
When `bash bin/forge-review-standards.sh --target <tree>` runs
Then the report flags it K5-RULE-001 at severity Medium (WARN)
  and the overall status is REVIEW-DUE

Given a standards tree where every non-structural standard is fresh
When the CLI runs
Then it exits 0 with overall status CLEARED

Given SOURCE_DATE_EPOCH is exported
When the CLI runs twice in succession with --format json
Then both reports are byte-identical
```

### Article III — Specs Before Code

Confirmed: `/forge:specify` writes `specs.md` with `FR-K5-THE-*` /
`NFR-K5-THE-*` namespace before any implementation.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Open questions captured in `open-questions.md`; resolved before status
flips to `implemented`. Regulatory dates are copied VERBATIM from the
plan doc — never invented (see `open-questions.md` Q-K5-002).

### Article IV — Delta-Based Change Management

The `standards-lifecycle.md` "Themis hook" edit and the `CLAUDE.md` /
`docs/GUIDE.md` / `docs/COMPLIANCE.md` edits are additive deltas — no
wholesale rewrite (Article IV.1).

### Article V — Audit Trail

Each task tagged `[Story: FR-K5-THE-XXX]` (Article V.1, enforced by
`f4-linter-extension`). Themis findings reference `K5-RULE-NNN`
machine-parseable IDs.

### Article VIII — Infrastructure

The CLI is a one-shot bash + Python 3 inline script. No service, no
daemon, no privileged ops. The sibling workflow uses
`permissions: contents: read`.

### Article IX — Observability

N/A directly. Themis is a repo-lifecycle-time / CI-time agent, not a
runtime component — no OTel emission.

### Article XI — AI-First Design

Themis is a Claude-Code agent persona (XI.1 agent-native). Its outputs
are deterministic structured documents (JSON report + Markdown
summary) — no opaque LLM-generated content consumed downstream (XI.3).

### Article XII — Governance

Themis ENFORCES the review-cadence + regulatory posture encoded in P-3
(`standards-lifecycle.md`) and I.2/I.5/I.6. It does **not amend** any
constitutional article. It picks up the Phase-B maintainer role that
`compliance-tiers.md` and `ai-act-dora-artefacts.md` reserved for it.
Structural standards (`transport.yaml`, `state-management.yaml`,
`expires_at: never`) are NEVER flagged by the cadence check — an
Article XII amendment remains their only mutation path.

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers: none in this
`proposal.md`. Three open questions Q-K5-001 + Q-K5-002 + Q-K5-003
raised at this phase, tracked in `open-questions.md`, slated for
resolution during `/forge:design`:

- **Q-K5-001** — workflow placement: additive step in
  `forge-compliance.yml` vs sibling `forge-standards-review.yml`?
- **Q-K5-002** — regulatory-deadline source of truth: copy verbatim
  from `new-archetypes-plan.md` §7.1 I.6 bullet vs re-derive from
  primary regulatory texts?
- **Q-K5-003** — CLI blocking posture: hard-fail on expiry vs WARN-only
  (aligned with `standards-lifecycle.md` "WARN n'est jamais bloquant")?
