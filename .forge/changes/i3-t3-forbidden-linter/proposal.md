# Proposal: i3-t3-forbidden-linter
<!-- Created: 2026-05-12 -->
<!-- Schema: default -->

## Problem

`docs/new-archetypes-plan.md` §7.1 lines 727-731 row **I.3** and
`.forge/product/roadmap.md` (T5 row) mandate a **T3-forbidden
linter rule** — a deterministic, programmatic surface that
refuses any project declared at compliance tier `T3` (per the
`.forge/.forge-tier` ledger shipped by `j8-janus-rules`
ADR-J8-006 or the `--eu-tier` CLI flag) when its scaffold or
working tree references a component flagged as forbidden by the
`compliance-tiers.md` standard's §10.2 matrix.

Constitution **Article XII** §enforce mandates programmatic
enforcement of `forbidden:` tokens declared in standards
frontmatter (e.g. a standard whose YAML carries `forbidden:
[firebase-auth, auth0-saas-us]`). Today this is
**documentation-only** — the standards files declare the lists,
the human reviewer is supposed to spot violations, and the
`constitution-linter.sh` already enforces ONE such standard
(`state-management.yaml` via the existing
`ADR-006 — no-state-management-alternatives` section, shipped
by T.4) as a per-standard hard-coded block. There is **no
general mechanism** that picks up newly-declared `forbidden:`
blocks across the standards corpus.

I.3 closes the gap by shipping a **generic linter rule** that :

1. **Discovers** all `.forge/standards/**/*.yaml` (and
   `.forge/standards/**/*.md` with frontmatter) files declaring
   a `forbidden:` block.
2. **Parses** the `forbidden:` list (one string token per item,
   per the existing convention — see
   `observability.yaml::forbidden: [datadog]`,
   `identity.yaml::forbidden: [firebase-auth, auth0-saas-us]`,
   `orchestration.yaml::forbidden: [inngest]`,
   `state-management.yaml::forbidden: [riverpod, provider, ...]`).
3. **Reads** the declared compliance tier from
   `.forge/.forge-tier` (J.8 ADR-J8-006 ledger) and/or the
   `--eu-tier` flag plumbed by J.8.
4. **Scans** the live tree for token occurrences in
   ecosystem-appropriate manifest files
   (`pubspec.yaml`, `package.json`, `Cargo.toml`, `requirements.txt`),
   in ADR / design documents (`.forge/changes/**/design.md`,
   `docs/**/*.md`), and in additional standards bodies referenced
   from the same standard's `rationale:` block.
5. **Emits** structured violation lines tagged
   `[REFUSAL: T3-RULE-NNN: <reason> ; remediation: <path>]` per
   the J.8 ADR-J8-003 / K.3 protocol, with **tier-scaled severity**
   per the same gradient Demeter uses for K3-RULE-001
   (T1 → Informational/WARN, T2 → High/FAIL, T3 → Critical/FAIL).

The new rule namespace is **T3-RULE-NNN** per ADR-J8-004
inheritance (J.8 = J8-RULE-NNN, K.3 = K3-RULE-NNN, I.3 =
T3-RULE-NNN). The prefix encodes the audit-module origin and
keeps numbering invariants (never reused) per the same
constitution.

The downstream items I.5 (`forge-compliance.yml` reusable
workflow) and I.6 (regulatory artefacts — NIS2 / DORA / CRA /
AI Act under `.forge/compliance/`) **depend on this linter
rule** shipping first : I.5 wires the rule into a reusable CI
workflow ; I.6 attaches regulatory artefacts that cite the
rule's evidence shape.

## Solution

A **single coordinated change** layering on top of the existing
`constitution-linter.sh` :

### I.3.a — Generic `forbidden:` discovery + scanning logic

A new section in `.forge/scripts/constitution-linter.sh` titled
`ADR-I3-001 (T3-Forbidden Components — generic forbidden discovery)`
that :

- Walks `.forge/standards/**/*.yaml` for any file declaring a
  top-level `forbidden:` block (and respects the existing
  `state-management.yaml`'s `no-state-management-alternatives`
  hard-coded section — the new generic rule **superset**s the
  existing rule without breaking it).
- Walks `.forge/standards/**/*.md` for any standard whose
  YAML frontmatter declares `forbidden:` (the
  `compliance-tiers.md` shipped by I.2 declares
  `forbidden: []` — DOCUMENTS, I.3 ENFORCES — and is the
  intended adopter-facing surface for the §10.2 matrix).
- Parses the declared tier from `.forge/.forge-tier` (J.8
  ledger) ; emits a `T3-RULE-007` warning if absent
  (no default tier inferred — Anti-Hallucination Protocol
  per Article III.4, mirrors K3-RULE behaviour).
- For each forbidden token, deterministically scans :
  - **Manifest files** : `pubspec.yaml`, `package.json`,
    `Cargo.toml`, `requirements.txt`, `go.mod`.
  - **Change bodies** : `.forge/changes/**/design.md`,
    `.forge/changes/**/specs.md`, `.forge/changes/**/proposal.md`.
  - **Standards bodies** : `.forge/standards/**/*.md` (e.g.
    a forbidden token mentioned in a `rationale:` of another
    standard).
  - **ADR / docs corpus** : `docs/**/*.md`.
- Emits structured `[REFUSAL: T3-RULE-NNN: ...]` lines via the
  same `fail` / `warn` helpers already in
  `constitution-linter.sh`. Tier-scaling :
  - **T1** → `warn` (Informational ; documents residual risk).
  - **T2** → `warn` (High ; documents posture violation —
    flipped to `fail` post-B.8 / T6, mirrors the
    `state-management.yaml::ci_blocking` Phase B pattern).
  - **T3** → `fail` (Critical ; T3 = 100% EU jurisdiction,
    forbidden component is a hard refusal).

### I.3.b — Standards index registration + rule catalogue

- A new section in
  `.forge/standards/global/compliance-tiers.md` titled
  `T3-Forbidden Linter Rule (I.3)` that documents :
  - The rule namespace `T3-RULE-NNN`.
  - The 7 seed rules T3-RULE-001..007 (see Cluster 9 in
    `specs.md`).
  - The opt-out env var `FORGE_LINTER_SKIP_T3_FORBIDDEN`.
  - The tier-scaling severity matrix.
- A `linter_rule:` frontmatter pin flip in
  `compliance-tiers.md` : the existing
  `linter_rule: t3-forbidden-components` forward-pointer
  becomes a **resolved** pointer — the standard's
  enforcement frontmatter flips from `enforcement: review` to
  `enforcement: ci`.

### I.3.c — Test harness + CI registration

- A new test harness
  `.forge/scripts/tests/i3.test.sh` mirroring the J.7 / J.8 /
  K.3 / I.2 layout : `_helpers.sh` source, `--level 1,2`
  parsing, `print_summary` close-out.
- 14 L1 hermetic grep-based + linter-output assertions.
- 4 L2 fixture tests (tmpdir-based : T3 + forbidden in
  pubspec.yaml, T2 + forbidden in Cargo.toml, T1 + forbidden
  emit WARN only, tier ledger absent emits T3-RULE-007).
- CI registration in `.github/workflows/forge-ci.yml`
  `harness` job matrix immediately after `i2.test.sh` with
  `--level 1,2`.

## Scope In

- New linter section in `.forge/scripts/constitution-linter.sh`
  (≈ 120-150 LOC ; sits between the existing ADR-006
  state-management section and the Article III.4 section).
- New section in `.forge/standards/global/compliance-tiers.md`
  documenting the T3-RULE-NNN catalogue + opt-out env var.
- Edit `.forge/standards/global/compliance-tiers.md`
  frontmatter : `enforcement: review` → `enforcement: ci`
  (now that the linter rule ships).
- New test harness `.forge/scripts/tests/i3.test.sh` (≥ 14 L1
  + 4 L2 tests).
- CI registration in `.github/workflows/forge-ci.yml`
  (single new row, ≤ 3 lines added — keeps the file ≤ 300
  per NFR-CI-002).
- New `T3-RULE-NNN` rule catalogue, namespace allocation per
  ADR-J8-004 extension protocol.
- New standard `.forge/standards/global/forbidden-components-rules.md`
  (sibling to `janus-orchestration-rules.md` /
  `data-stewardship-rules.md`) — the **rule catalogue
  standard** for T3-RULE-* identical in shape to J.8's and
  K.3's per-module catalogues.
- `.forge/standards/index.yml` entry for the new standard.
- `.forge/standards/REVIEW.md` append-only birth entry dated
  2026-05-12.
- `docs/LINTING.md` H2 update documenting the new rule + the
  new `FORGE_LINTER_SKIP_T3_FORBIDDEN` env var.
- Doc updates in `docs/new-archetypes-plan.md` row I.3 +
  `.forge/product/roadmap.md` T5 / status block (mark I.3 done
  with the standard "Done YYYY-MM-DD via i3-t3-forbidden-linter"
  pattern).
- `CHANGELOG.md` `## [Unreleased]` entry.

## Scope Out (Explicit Exclusions)

- **NOT** the `forge-compliance.yml` reusable workflow
  (I.5). I.5 ships in a separate change after this one ; it
  consumes the linter rule as a CI step.
- **NOT** the regulatory-deadlines artefacts under
  `.forge/compliance/` (I.6 — NIS2 / DORA / CRA / AI Act
  schedules). Themis (K.5) is the agent for those, scheduled
  T7.
- **NOT** any new standards file beyond
  `forbidden-components-rules.md` ; existing standards (
  `identity.yaml`, `observability.yaml`, `orchestration.yaml`,
  `state-management.yaml`, `persistence.yaml`,
  `compliance-tiers.md`) are **read** by the linter, not
  modified by it (except the
  `compliance-tiers.md::enforcement: review → ci` frontmatter
  flip captured in `tasks.md`).
- **NOT** retroactive enforcement on already-archived changes.
  The linter operates on the live tree at invocation time.
- **NOT** any change to the J8-RULE-* or K3-RULE-* catalogues.
  T3-RULE-* uses its own prefix per ADR-J8-004 extension
  protocol.
- **NOT** modifications to `cli/src/commands/init.ts` or any
  TypeScript surface — the `--eu-tier` flag is already
  plumbed by J.8.
- **NOT** modifications to the Demeter scanner
  `bin/forge-demeter-scan.sh` — Demeter operates on
  dependency lockfiles (CLOUD Act jurisdiction),
  T3-forbidden-components operates on the `forbidden:`
  lists declared in standards (architectural eligibility).
  The two surfaces are **complementary** (Demeter ⊆
  data-stewardship ; T3-forbidden ⊆ architectural posture)
  and both run independently — neither overrides the other.
- **NOT** the `persistence.yaml::forbidden_for_eu_strict:`
  block (a structural variant predating the generic
  `forbidden:` convention). I.3 reads only `forbidden:` ;
  the `forbidden_for_eu_strict:` block is documented as a
  forward-pointer to be normalised in a future T6 standards
  refactor (out of scope, captured in `open-questions.md` as
  Q-002).

## Impact

- **Users affected** :
  - Adopters running EU-aware Forge projects (declaring
    `.forge/.forge-tier` or `--eu-tier`) get **automatic
    architectural posture enforcement** at CI time for any
    component declared forbidden in the standards corpus.
  - Adopters not declaring a tier observe **ZERO behavioural
    change** (the linter section becomes `N/A` per
    NFR-I3-CT-002 backward-compat).
  - Reviewers gain a single deterministic surface that
    enumerates and enforces every `forbidden:` token across
    the standards corpus, instead of relying on per-standard
    human spot-checks.
- **Technical impact** : ≈ 4 new files (linter section,
  test harness, standard, REVIEW birth entry edits) + ≈ 4
  modified (constitution-linter.sh extension,
  compliance-tiers.md update, standards/index.yml entry,
  CHANGELOG.md). Test harness ≥ 14 L1 + 4 L2. **Effort `S`**
  per `new-archetypes-plan` §1.4 row I.3.
- **Dependencies** :
  - I.2 `i2-compliance-tiers` archived 2026-05-12 — ships
    `global/compliance-tiers.md::frontmatter::linter_rule:
    t3-forbidden-components` forward-pointer that this
    change resolves.
  - J.8 `j8-janus-rules` archived 2026-05-10 — ships the
    `.forge/.forge-tier` plain-text ledger pattern
    (ADR-J8-006) + the `J8-RULE-NNN` format that
    `T3-RULE-NNN` extends per ADR-J8-004.
  - K.3 `k3-demeter` archived 2026-05-12 — establishes the
    `K3-RULE-NNN` precedent for module-prefixed rule
    namespaces. The `T3-RULE-NNN` namespace inherits the
    same protocol.
  - T.4 `t4-adr-ratification` archived 2026-05-04 — ships
    the standards YAML frontmatter contract that the linter
    parses.
  - F.4 `f4-linter-extension` archived 2026-05-01 — ships
    the `FORGE_LINTER_SKIP_*` env-var convention + `warn`
    helper that this section reuses.
  - No new external dependency. Linter uses `python3` +
    `awk` already required by F.2 / J.7 / J.8.d (PyYAML
    already declared).
- **Risk level** : **Low**. The linter is a one-shot
  read-only walk of the standards corpus + the working tree.
  No mutation. Existing hard-coded `state-management.yaml`
  section is **preserved verbatim** (the new generic section
  treats `state-management.yaml` as a regular standard with
  a `forbidden:` block, but skips it when
  `FORGE_LINTER_SKIP_NSMA` is set — the two interlock).
  The only meaningful risk is **false positives on substring
  matches** (e.g. a token `inngest` matching the literal
  string "inngest-like" in a doc paragraph) — mitigated by
  exact-token matching in manifest files (per-ecosystem
  parsing) and whole-word boundary matching in doc bodies
  (NFR-I3-CT-007).

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`i3.test.sh` with 14 L1 + 4 L2 stubs all returning
`_not_implemented` (full RED witness). Phase 2 implements the
linter section ; Phase 3 ships the rule-catalogue standard ;
Phase 4 wires CI ; Phase 5 does doc + archive.

### Article II — BDD

User-facing flows get Gherkin scenarios in `specs.md` :

```gherkin
Given a project declares compliance_tier T3 via .forge/.forge-tier
And the project's pubspec.yaml declares "firebase-auth: ^1.0.0"
And identity.yaml declares "forbidden: [firebase-auth]"
When constitution-linter.sh runs
Then exit code is 1
And stderr contains "[REFUSAL: T3-RULE-001: firebase-auth forbidden at T3 (identity.yaml::forbidden) ; remediation: replace with Zitadel or downgrade tier]"

Given a project declares compliance_tier T1 via .forge/.forge-tier
And the project's package.json declares "datadog-browser-rum"
And observability.yaml declares "forbidden: [datadog]"
When constitution-linter.sh runs
Then exit code is 0
And stdout contains "WARN  T3-RULE-001: datadog forbidden token detected (informational at T1)"

Given a project's .forge/.forge-tier ledger is absent
And the project's .forge.yaml declares schema: default (no tier)
When constitution-linter.sh runs
Then the T3-forbidden section emits "N/A  no compliance tier declared (set .forge/.forge-tier or pass --eu-tier)"
And the OVERALL: PASS status is preserved
```

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with
`FR-I3-T3F-*` namespace before any implementation.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Open questions captured in `open-questions.md` ; resolved
before status flips to `implemented`. The linter emits
`T3-RULE-007 — tier ledger ambiguous / absent` warnings
instead of guessing a default tier (mirrors K3-RULE behaviour).

### Article V — Audit Trail

Each task tagged `[Story: FR-I3-T3F-XXX]` (Article V.1,
enforced by `f4-linter-extension`). T3-forbidden findings
reference rule IDs in the format `T3-RULE-NNN: <reason> ;
remediation: <path>`, machine-parseable and consistent with
the `j8-janus-rules` `[REFUSAL: ...]` + Demeter
`K3-RULE-NNN: ...` formats.

### Article VIII — Infrastructure

The linter is a one-shot bash + Python 3 inline section in
the existing `constitution-linter.sh`. No new service, no
new daemon, no privileged ops.

### Article IX — Observability

N/A directly. The linter does not emit OTel telemetry —
it is a CI-time review surface, not a runtime component.
When I.5 ships the `forge-compliance.yml` workflow that
wraps this linter, the workflow MAY emit job-level metrics
per `observability.yaml`.

### Article X — Code Quality

Linter section follows the existing
`constitution-linter.sh` style (bash `case` blocks, `pass`
/ `fail` / `warn` / `not_applicable` helpers, opt-out
env vars). No new external dependency. Shellcheck-clean.

### Article XI — AI-First Design

The linter is a deterministic surface (no LLM call) — the
T3-RULE-* findings are produced by exact-string matching
against the standards' `forbidden:` lists. Article XI.3
schema-driven principle preserved (the `forbidden:` list
is a schema-bound input).

### Article XII — Governance

This change **EXECUTES** Article XII §enforce :

> "Module and layer boundaries defined in Articles VI and
> VII MUST be enforced by automated tooling"

extended by analogy to Article XII §forbidden : the
`forbidden:` tokens declared in standards frontmatter
become **programmatically enforced** by the
`constitution-linter.sh` instead of relying on human
review. This is the **first** generic surface of Article
XII enforcement ; previously only ADR-006
(`state-management.yaml`) had a hard-coded per-standard
block in the linter.

The new standard `forbidden-components-rules.md` is MD,
not YAML ; it does not carry the J.7 frontmatter
contract.

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`proposal.md`. Three open questions Q-001 + Q-002 + Q-003
raised at this phase, all tracked in `open-questions.md` and
slated for resolution during `/forge:design` :

- **Q-001** — Tier scaling at T2 : `warn` (Informational
  Phase A — mirror `state-management.yaml::ci_blocking:
  false`) vs `fail` (block from day 1)?
- **Q-002** — Should the linter ALSO read the
  `forbidden_for_eu_strict:` block in `persistence.yaml`,
  or should that block be deferred to a future T6
  standards-refactor that normalises it into `forbidden:`?
- **Q-003** — T3-RULE namespace seed size : pre-allocate
  10 rules now (T3-RULE-001..010) or grow incrementally
  (5 rules now, 6+ later — mirrors K.3's ADR-K3-005)?
