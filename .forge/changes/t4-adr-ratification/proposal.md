# Proposal: t4-adr-ratification
<!-- Created: 2026-05-04 -->
<!-- Schema: default -->

## Problem

`docs/ARCHITECTURE-TARGET.md` (2026-04-29, rev v1.1) ratifies **ten Architecture
Decision Records** that define the Forge 2026 target stack and re-organise the
archetype taxonomy from 4 to 5. The document is canonical from the architect's
perspective, but it lives **outside the Forge framework's own discipline** — no
`.forge/changes/` folder, no Constitution gate, no `forge upgrade` reachability.

At the same time, `docs/new-archetypes-plan.md` (2026-05-04) lists four
**methodological pre-requisites** (P-1 through P-4) that must ship before any
new archetype work can begin in T5+. Without them:

- The 10 ADRs are **floating decisions** outside Constitution v1.1.0 — adopters
  can't know what's binding vs. opinion.
- The six target standards (transport, state-management, observability,
  orchestration, identity, persistence) are **prose only** in the architecture
  document — there is no machine-readable enforcement, no linter rule, no
  `forbidden:` list, no expiry policy.
- The 12-month review cycle (anti-fossilisation guarantee) is **announced
  but not implemented**.
- The compliance EU graded T1/T2/T3 dimension has **no schema** to validate
  per-change `compliance_tier` declarations.

This change closes the gap. It is a **methodology change**, not a feature
change : zero runtime code is touched, only specs / schemas / standards /
agents-prompt instructions.

## Solution

Single archived Forge change `t4-adr-ratification` that ships **four atomic
deliverables** :

1. **ADR ratification** — `specs.md` carries 10 H2 sections (one per ADR)
   with the `Decision / Context / Consequences` triplet from the architecture
   document, each cross-referenced to its `docs/ARCHITECTURE-TARGET.md` line
   range. The ADRs become **Constitution v1.1.0 ratified decisions** through
   this Forge change, traceable via `forge upgrade` and the `upgrade_history`
   ledger.
2. **Six versioned standards** — `.forge/standards/{transport, state-management,
   observability, orchestration, identity, persistence}.yaml` with a uniform
   YAML frontmatter (`version`, `last_reviewed`, `expires_at`, `forbidden:`,
   `linter_rule:`, `enforcement:`, `exception_constitutional:`).
3. **Standards lifecycle** — `.forge/standards/REVIEW.md` (canonical review
   ledger) + `.forge/standards/global/standards-lifecycle.md` (the rules) ship
   the 12-month review cycle, with the structural exception list (state-management
   and transport are not subject to the 12-month window per ADR-006 and
   ADR-009 — only Constitution amendment can change them).
4. **Compliance schemas** — `.forge/schemas/compliance-tier.schema.json`
   (T1/T2/T3 enum) + bump `.forge/schemas/archetype.schema.json` to v2 with
   the 5-archetype enum (`full-stack-monorepo`, `mobile-pwa-first`,
   `event-driven-eu`, `ai-native-rag`, `rust-cli-tui`) **plus** the legacy
   alias `mobile-only` (rétrocompat for adopters of v0.3.0's B.4 archetype).

The change is then archived and becomes the **anchor** for T5–T8 work
(every subsequent module B.6/B.7/B.8/B.9/I/J/K/etc. references back to this
ratification).

## Scope In

- 10 ADRs captured as `specs.md` H2 sections (Decision/Context/Consequences),
  cross-referenced to `docs/ARCHITECTURE-TARGET.md` line ranges.
- 6 versioned `.forge/standards/*.yaml` files with uniform frontmatter and
  the `forbidden:` lists explicit (Riverpod/Provider/GetX/MobX/states_rebuilder/
  flutter_mobx for state-management, Datadog/Firebase Auth for identity,
  DynamoDB/Firestore/Cosmos for persistence in T2/T3 strict).
- 1 `.forge/standards/REVIEW.md` ledger (initial entries: 6 standards
  reviewed 2026-05-04, expires 2027-05-04, except the two structural
  exceptions).
- 1 standard `.forge/standards/global/standards-lifecycle.md` documenting
  the 12-month rule, the structural-exception escape, and the
  Themis-monthly-review hook (Themis agent itself is **not** delivered in
  this change — deferred to T7 K.5).
- 1 schema `.forge/schemas/compliance-tier.schema.json` (Draft 2020-12,
  T1/T2/T3 enum + matcher composant→tier).
- Bump `.forge/schemas/archetype.schema.json` to v2 (5-archetype enum +
  `mobile-only` legacy alias documented).
- Test harness `t4.test.sh` (≥ 25 tests L1 hermetic + L2 fixture) :
  validates each YAML standard parses, `forbidden:` lists not empty for the
  three relevant standards, schemas valid against their meta-schemas,
  `mobile-only` legacy alias resolves to `mobile-pwa-first` schema.
- Update `docs/STANDARDS-LIFECYCLE.md` (new) — public-facing doc on how
  standards age and expire.
- Update `CHANGELOG.md` with a `0.4.0-rc.1` entry (or whatever the
  release-script convention picks) flagging the policy shift.
- Update `.forge/standards/index.yml` to register the 6 new standards
  with `scope: all`, appropriate triggers, and priority.

## Scope Out (Explicit Exclusions)

- **No archetype implementation** — no edit to `templates/`, no new
  `bin/forge-init-*.sh`, no `dispatch-table.yml` change beyond schema enum.
  Modules B.6 (event-driven-eu) and B.7 (ai-native-rag) ship in T7,
  B.8 (flagship 1.0.0 → 2.0.0) in T6, B.9 (mobile-only → mobile-pwa-first)
  in T8.
- **No agent refactor** — P-5 (Hera 9 → 5 sub-agents) is explicitly
  **deferred to last** per user decision 2026-05-04. No `.claude/agents/`
  modification in this change.
- **No new agent** — Themis (K.5), Demeter (K.3), Hermes-Async (K.1),
  Pythia (K.2), Iris-Web (K.4) all ship in T5–T7. The standards-lifecycle
  doc references Themis as the future review automator but does not
  ship the agent.
- **No runtime code edit** — no Rust crate, no Dart package, no Helm
  chart, no Docker image, no CI workflow modification (beyond the harness
  registration).
- **No Constitution amendment** — Constitution v1.1.0 already supports
  all the ADR ratifications via Article XII (delegation to standards).
  No bump to v1.2.0 in this change.
- **No `forge upgrade` migration script** — `bin/forge-migrate-flagship.sh`
  ships in B.8 (T6). This change establishes the *target standards* but
  does not migrate any existing scaffolded project.
- **No Connect-Dart / DBOS / Envoy template** — those land with the B.8
  flagship migration in T6.
- **No B.2 `flutter-firebase` deletion from `dispatch-table.yml`** — the
  archetype was a placeholder, never implemented ; the public removal
  goes via a CHANGELOG note + roadmap update (already shipped in
  `.forge/product/roadmap.md` 2026-05-04). The dispatch table change is
  trivial and bundled here for atomicity.

## Impact

- **Users affected** : all current adopters of `@sdd-forge/cli@0.3.0`
  who will receive the new standards via `forge upgrade`. Linter
  output may newly flag `forbidden:` library imports (state-management
  alternatives) — but the linter rule itself ships **disabled by default**
  in this change ; activation lands with B.8 (flagship migration), so no
  surprise breakage at upgrade time.
- **Technical impact** : 6 new YAML standards + 2 new JSON schemas + 1
  meta-spec + 1 test harness + 2 docs (`STANDARDS-LIFECYCLE.md`,
  `LINTING.md` extension). No production code, no build pipeline, no
  Dockerfile, no Helm chart. **Complexity : M.**
- **Dependencies** : Constitution v1.1.0 (already in place since D.5).
  No external service, no third-party library added. Test harness uses
  `python3` + `bash` + `yq` (already required by F.2 / F.4).
- **Risk level** : **Low**. The change is purely declarative ; it
  formalises decisions already taken. The only real risk is **drift
  between `docs/ARCHITECTURE-TARGET.md` line ranges and `specs.md`
  cross-references** if the architecture doc is later edited — mitigated
  by storing the architecture doc's content hash in
  `specs.md` frontmatter and adding a `t4.test.sh` test that rejects a
  drifted hash.

## Constitution Compliance

### Article I — TDD

Every shipped artefact has a corresponding test : `t4.test.sh` validates
each YAML standard parses with `yq`, each JSON schema validates with
`python3 -c "import jsonschema; jsonschema.Draft202012Validator.check_schema(...)"`,
the `archetype.schema.json` v2 accepts the 5 canonical names + `mobile-only`,
the `compliance-tier.schema.json` accepts T1/T2/T3 only, the
`forbidden:` lists are non-empty for the three concerned standards, and
the architecture-doc content hash matches. RED-GREEN-REFACTOR : tests
written first (failing), then standards/schemas implemented (passing),
then refactored for consistency.

### Article II — BDD

This is a methodology change with no user-facing UI behavior. No BDD
scenario applicable. The test harness covers the deterministic pass/fail
gates ; behaviour-driven coverage is not relevant for declarative YAML/JSON
artefacts.

### Article III — Specs Before Code

Confirmed : `specs.md` ships 10 ADR sections with explicit
`FR-T4-001..FR-T4-NN` IDs, plus NFR-T4-* for budgets (e.g. `t4.test.sh`
runtime ≤ 3 s, total YAML/JSON file count budget). Implementation
(`tasks.md` execution) starts only after `specs.md` and `design.md` are
gate-cleared.

### Article IV — Delta Specifications

`specs.md` opens with `## ADDED` (the 6 standards, 2 schemas, 1
lifecycle doc), `## MODIFIED` (`archetype.schema.json` v2), and
`## REMOVED` (none). Linter validates via F.4's existing rules.

### Article V — Constitution Gate

`/forge:design` and `/forge:review` re-run the gate. The change does
not introduce any Article violation by construction (it ships *standards*,
not *implementations*).

### Article VI / VII — Flutter / Rust Architecture

No Flutter, no Rust code touched. Article VI/VII inapplicable.

### Article VIII — Infrastructure

No K8s, Helm, Docker change. Article VIII inapplicable.

### Article IX — Security

`identity.yaml` ships with `forbidden: [firebase-auth]` and
`compliance-tier-aware: true` flag for T3 strict. No secret material
introduced. Aegis review optional (recommended but not blocking for a
declarative change).

### Article X — Quality

`tasks.md` ships with explicit task ↔ FR-T4-* linkage (Article V.1
verified by F.4 linter). Public API doc ratio (Article X.3) inapplicable
(no public API in this change).

### Article XI — AI-First

This change is not an AI feature. Article XI inapplicable.

### Article XII — Governance

This change ratifies decisions (the 10 ADRs) under Constitution v1.1.0
without amending the Constitution itself. Per ADR-006 of `d5-governance`
(canonical precedent), the change stays at `constitution_version:
"1.1.0"` and does NOT bump to v1.2.0. Public discussion **already happened**
via `docs/ARCHITECTURE-TARGET.md` review (commissioned 2026-04-29,
revised 2026-04-29 v1.1) — equivalent to the 7-day discussion window
required by `GOVERNANCE.md` § Amendment Process for non-Constitution
amendments.

## Open Questions

See `open-questions.md`.
