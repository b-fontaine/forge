# Spec: governance

<!-- Audit: Module D.5 — operational governance model. -->
<!-- This file accumulates archived requirements for the project's      -->
<!-- governance, code of conduct, amendment process, and release        -->
<!-- ownership.                                                         -->
<!--                                                                    -->
<!-- Audience here : Forge maintainers + external contributors who      -->
<!-- need to know who decides what, how amendments work, and how        -->
<!-- to escalate Code-of-Conduct issues. Distinct from                  -->
<!-- forge-ci.md (CI plumbing) and upgrade.md (CLI command).            -->
<!--                                                                    -->
<!-- Source change : `.forge/changes/d5-governance/` (archived          -->
<!-- 2026-04-30). Constitution amendment : v1.0.0 → v1.1.0,             -->
<!-- amendment row #1, ratified by Benoit Fontaine (BDFL).              -->

**Namespace** : `FR-GOV-*`, `NFR-GOV-*`.

**Constitution amendment** : v1.0.0 → v1.1.0 (added Article XII —
Governance, delegating operational rules to `GOVERNANCE.md`).

---

## Functional Requirements

### FR-GOV-001 — Existence of `GOVERNANCE.md` at repo root

A `GOVERNANCE.md` file MUST exist at the root of the Forge repository, in
Markdown format, version-controlled, and at least 50 lines long (proof of
substantive content, not a placeholder).

### FR-GOV-002 — Required H2 sections of `GOVERNANCE.md`

`GOVERNANCE.md` MUST contain the following H2 sections (exact titles) :
`## Maintainers`, `## Roles and Responsibilities`, `## Decision Making`,
`## Amendment Process`, `## Release Process`, `## Code of Conduct`,
`## Contact`. The order SHOULD be the one listed for OSS consistency.

### FR-GOV-003 — Maintainers section content

The `## Maintainers` section MUST list nominatively the current BDFL
(`Benoit Fontaine`, GitHub `@bfontaine`, role `BDFL (current phase
≤ 1.0)`), and MUST include a structurally-present co-maintainers table
(empty until first appointment).

### FR-GOV-004 — Roles and Responsibilities content

The `## Roles and Responsibilities` section MUST explicitly define : who
merges PRs to `main`, who publishes releases, who ratifies Constitution
amendments, who moderates the Code of Conduct. Each responsibility MUST
appear as a bullet or table row (≥ 4 entries total).

### FR-GOV-005 — Decision Making model (BDFL-with-fallback)

The `## Decision Making` section MUST document both the **current phase**
(BDFL) and the **mature phase** (committee). Both phrases (or French
equivalents `phase actuelle` / `phase mature`) MUST appear.

### FR-GOV-006 — Amendment Process pas-à-pas

The `## Amendment Process` section MUST document the Constitution
amendment workflow as ≥ 4 numbered steps, including a minimum public
discussion window of **7 days** (or `7 jours`).

### FR-GOV-007 — Release Process pas-à-pas

The `## Release Process` section MUST document release publication as
≥ 4 numbered steps, mentioning the `vX.Y.Z` (or concrete `v[0-9]+.[0-9]+.[0-9]+`)
tag pattern.

### FR-GOV-008 — Code of Conduct delegation

The `## Code of Conduct` section MUST link to
`./CODE_OF_CONDUCT.md` and name the underlying base `Contributor
Covenant` (with version 2.1).

### FR-GOV-009 — Contact email

The `## Contact` section MUST publish in plain text the email
`contact@benoitfontaine.fr` for governance and CoC reports, plus
pointers to GitHub Discussions (non-confidential) and Issues (bugs).

### FR-GOV-010 — `CODE_OF_CONDUCT.md` Contributor Covenant 2.1 verbatim

A `CODE_OF_CONDUCT.md` file MUST exist at the repo root, based on the
verbatim **Contributor Covenant v2.1** text. It MUST contain the strings
`Contributor Covenant`, `2.1`, and `contact@benoitfontaine.fr` (the
latter substituting the official `[INSERT CONTACT METHOD]` placeholder).

### FR-GOV-011 — Constitution Article XII

`.forge/constitution.md` MUST receive a new Article XII placed after
Article XI and before the `## Amendments` section. Article XII MUST
reference `GOVERNANCE.md` as the operational source of truth and clarify
the principles-vs-procedures delimitation.

### FR-GOV-012 — Constitution version bump and templates

`.forge/constitution.md` MUST :
- Show `**Version**: v1.1.0` in the header block.
- Have at least one row in the `## Amendments` table (numbered `1`,
  dated `2026-04-30`, ratified by `Benoit Fontaine (BDFL)`).

`.forge/templates/change.yaml` MUST have **2 occurrences** of
`constitution_version: "1.1.0"` (the active line + the example block).

`.forge/templates/archetypes/full-stack-monorepo/.forge.yaml.tmpl` MUST
have `constitution_version: "1.1.0"`.

The `.forge.yaml` of the `d5-governance` change itself MUST stay at
`"1.0.0"` — it was ratified UNDER `1.0.0` and CREATED `1.1.0`. This is
the canonical precedent for all future amendment changes (ADR-006).

Archived changes from prior changes MUST NOT be modified — they keep
`"1.0.0"` for historical traceability.

### FR-GOV-013 — README links

`README.md` MUST link to both `GOVERNANCE.md` and `CODE_OF_CONDUCT.md`.
References live in the `## Governance` section (existing).

### FR-GOV-014 — Test harness `d5.test.sh`

A test harness `.forge/scripts/tests/d5.test.sh` MUST exist, follow the
manifest pattern (one `_test_d5_NNN` function per FR-GOV-* requirement,
≥ 15 tests), be discovered by `verify.sh`, and be registered in
`.github/workflows/forge-ci.yml` under the `harness` job.

### FR-GOV-015 — Negative scope

The d5-governance change NE DOIT PAS modify `cli/src/**`,
`cli/package.json`, `cli/package-lock.json`, archetype schemas
(`.forge/schemas/*/schema.yaml`), or archetype templates other than the
`.forge.yaml.tmpl` listed in FR-GOV-012. Verified manually at the
`/forge:archive` gate.

---

## Non-Functional Requirements

### NFR-GOV-001 — Readability

`GOVERNANCE.md` SHOULD be readable cold by a third-party developer in
**under 5 minutes**. Target : 100-250 Markdown lines, scannable
structure (H2 + bullets), zero unexplained Forge jargon.

### NFR-GOV-002 — Documentary stability

Once D.5 is archived, `GOVERNANCE.md` AND the Article XII section of the
Constitution MUST NOT be modified outside the formal amendment process
defined in FR-GOV-006. This is a human discipline, not an automated
test, but the Constitution Article XII delegates this rule explicitly.

### NFR-GOV-003 — No PII excess

Only `contact@benoitfontaine.fr` is published. No phone number, postal
address, or other personal PII appears in `GOVERNANCE.md` or
`CODE_OF_CONDUCT.md`. The GitHub handle `@bfontaine` is public and
non-sensitive.

### NFR-GOV-004 — GitHub Community Standards detection

Presence of `GOVERNANCE.md` + `CODE_OF_CONDUCT.md` at repo root MUST
trigger automatic detection by GitHub Community Standards. Target :
completeness indicator ≥ 80 % (manual verification post-push, no test
automation).

---

## Acceptance Criteria (BDD)

### Scenario 1 — A new contributor discovers the governance

```gherkin
Given an external contributor lands on the Forge GitHub repository
When they browse the repo home page
Then GOVERNANCE.md is listed as a community file (sidebar)
And "Code of conduct" is shown as detected by GitHub
And README.md § "## Governance" links to GOVERNANCE.md and CODE_OF_CONDUCT.md
And the contributor identifies, in under 30 seconds :
  - the BDFL (Benoit Fontaine, @bfontaine)
  - how to propose an amendment (Amendment Process, 4 steps)
  - the contact email (contact@benoitfontaine.fr)
```

### Scenario 2 — A maintainer wants to publish a release

```gherkin
Given a maintainer just archived a Forge change on main
When they want to publish a release
Then they read GOVERNANCE.md § "Release Process"
And they follow the 4 steps in order :
  1. archive change (already done)
  2. update CHANGELOG.md (verify Calliope did the job)
  3. tag git "vX.Y.Z"
  4. publish to npm + GitHub Releases
And no step is ambiguous or left to interpretation
```

### Scenario 3 — A contributor wants to amend the Constitution

```gherkin
Given a contributor wants to add or modify a Constitution article
When they read GOVERNANCE.md § "Amendment Process"
Then they know they MUST :
  1. open a Forge change via /forge:propose
  2. discuss publicly for ≥ 7 days
  3. obtain BDFL ratification (current phase) or committee majority (mature phase)
  4. wait for the Amendments table + Version bump
And they know nothing is binding until those steps complete
```

### Scenario 4 — CI validates governance

```gherkin
Given d5-governance is merged to optim
When the CI workflow runs the "harness" job
Then d5.test.sh runs with ≥ 15 tests
And every test passes (exit 0)
And the global verify.sh stays green (9 harnesses total, ≥ 187 tests)
```

### Scenario 5 — A reporter signals a Code of Conduct violation

```gherkin
Given a participant observes a CoC violation
When they read CODE_OF_CONDUCT.md
Then "Enforcement" section lists :
  - the contact email contact@benoitfontaine.fr
  - confidentiality of reports
  - acknowledgement timeline (up to 7 days per GOVERNANCE.md)
And the email is plain-text (not obfuscated, not an image)
```

---

## Constitution Compliance Summary

- **Article I (TDD)** : harness `d5.test.sh` follows RED→GREEN. ✅
- **Article II (BDD)** : 5 documented scenarios above. ✅
- **Article III (Specs Before Code)** : full pipeline (proposal → specify
  → design → plan → implement → archive) executed. ✅
- **Article III.4 (Anti-hallucination)** : zero `[NEEDS CLARIFICATION:]`
  reached the implementation phase ; 3 design questions resolved at
  the proposal gate. ✅
- **Article IV (Delta-based)** : new namespace, ADDED-only ; the
  Constitution amendment uses the official Amendments table
  mechanism. ✅
- **Article V (Process Gates)** : pipeline complete + Article XII now
  formally delegates Process Gate ownership to roles defined in
  `GOVERNANCE.md`. ✅
- **Article XII (Governance)** : self-bootstrapping — this change
  creates the article it complies with, exactly as the Constitution's
  amendment paragraph allows. ✅
- **Articles VI–XI** : NA (no Flutter/Rust/Infra/Observability/Quality
  in the runtime sense/AI). ✅
