# Proposal: j8-janus-rules
<!-- Created: 2026-05-10 -->
<!-- Schema: default -->

## Problem

`docs/ARCHITECTURE-TARGET.md` §12.5 mandates that the **Janus**
cross-layer orchestrator agent ship a set of **refusal rules** that
enforce Forge's EU-strict / premium positioning at scaffolding time.
Today these rules exist in **prose only** — captured in
`docs/new-archetypes-plan.md` §1.3 (e.g. "B.2 `flutter-firebase`
ANNULÉ — Schrems II + CLOUD Act incompatibles") and in
`docs/ARCHITECTURE-TARGET.md` ADR-007 / ADR-008 / ADR-010 — but the
agent **does not actually refuse** when an adopter requests a
forbidden combination. Concrete gaps observed today :

1. **`flutter-firebase` archetype is removed** from
   `.forge/schemas/archetype.schema.json` v2 (T.4 ratification),
   but `.forge/scaffolding/dispatch-table.yml` carries no explicit
   `forbidden:` marker. An adopter passing `--archetype flutter-firebase`
   gets a generic "unknown archetype" error, not a Schrems II /
   CLOUD Act explanation. Janus can't redirect to alternatives.
2. **No `--eu-tier` flag** on `forge init`. Adopters cannot signal
   their compliance posture (T1 RGPD-via-DPA / T2 self-hostable /
   T3 SecNumCloud / EUCS High strict) at scaffold time. Without
   the signal, the standards (`identity.yaml`, `observability.yaml`)
   cannot enforce their tier-specific constraints (e.g. self-host
   Zitadel mandatory at T3, no Datadog at T2+).
3. **No SBOM** shipped with scaffolded projects. Adopters in
   regulated industries (NIS2, DORA, CRA) need a CycloneDX
   software bill-of-materials at deploy time. Forge currently has
   none — adopters must hand-roll their own SBOM tooling.

The first two gaps are **scaffold-time decisions** (Janus
orchestration). The third is a **build-time artefact** (one-shot
script + CI workflow). All three were planned together as J.8 in
the audit roadmap because they form the EU-compliance "first line"
of the Forge offering.

This change closes the three gaps.

## Solution

Three coordinated sub-modules under one umbrella change :

### J.8.a — Janus refusal rules

- **`.claude/agents/cross-layer-orchestrator.md`** gains a new H2
  section "Forbidden archetypes & combinations" enumerating the
  refusal rules (Schrems II + CLOUD Act + Article XII coupling).
- **`.forge/scaffolding/dispatch-table.yml`** gains a top-level
  `forbidden_archetypes:` list with `name`, `reason`, `since`,
  `alternative` fields. `flutter-firebase` is the seed entry.
- **`bin/forge-init-*.sh`** wrappers honor the forbidden-list :
  if the requested archetype is on it, the wrapper exits 3 with a
  human-readable refusal message pointing to the alternative.
- **New standard** `.forge/standards/global/janus-orchestration-rules.md`
  codifies the rule set + the Schrems II / CLOUD Act rationale.

### J.8.b — `--eu-tier T1|T2|T3` flag plumbing

- **`cli/src/commands/init.ts`** gains a `--eu-tier <tier>` flag
  validated against `.forge/schemas/compliance-tier.schema.json`
  (T.4-shipped enum `[T1, T2, T3]`).
- The TS dispatcher passes the validated tier to wrapper scripts
  via an env var `FORGE_EU_TIER=<tier>`.
- **`bin/forge-init-fsm.sh`** wrapper applies tier-specific rules
  when `FORGE_EU_TIER=T3` :
  - Force `identity.yaml` self-host Zitadel (refuse Keycloak-cloud
    or Auth0).
  - Force `observability.yaml` self-host SigNoz (refuse the
    SigNoz Cloud SaaS).
  - Refuse Datadog (already in `forbidden:` of `observability.yaml`,
    but the wrapper now surfaces this at scaffold time).
  - Annotate the scaffolded `.forge/.forge-tier` ledger file with
    the chosen tier for downstream tooling.
- T1 and T2 ship with informational notes only — no refusals
  (T1 RGPD-via-DPA accepts cloud SaaS ; T2 self-hostable is a
  recommendation not a hard refusal).

### J.8.d — SBOM CycloneDX generation

- **`bin/forge-sbom.sh`** : new script generating a CycloneDX 1.5
  JSON SBOM from any combination of `Cargo.lock`, `package-lock.json`,
  and `pubspec.lock` present in the target tree. Supports
  `--output <path>` (default `sbom.cdx.json`) and
  `--format json|xml` (default JSON).
- Pure shell + Python 3 inline (mirrors F.2 / J.7 pattern, no new
  external deps — `cargo-cyclonedx` and `npm sbom` are wrapped
  rather than re-implemented).
- New CI workflow step (job `sbom` in `forge-ci.yml`) that runs
  `forge-sbom.sh` against `examples/forge-fsm-example/` and uploads
  the SBOM as a build artefact.
- New standard `.forge/standards/global/sbom-policy.md` documenting
  what the SBOM covers, format choice (CycloneDX 1.5 over SPDX 2.3
  per current EU compliance guidance), and the regeneration cadence
  (every release).

## Scope In

- Janus agent edit (1 new H2 section + cross-link to dispatch-table).
- `dispatch-table.yml` `forbidden_archetypes:` list (seeded with
  `flutter-firebase`).
- Wrapper script refusal logic in `bin/forge-init-*.sh`.
- New standard `global/janus-orchestration-rules.md`.
- `cli/src/commands/init.ts` `--eu-tier` flag + validation.
- `bin/forge-init-fsm.sh` tier-specific enforcement (T3 case).
- `.forge/.forge-tier` ledger file convention (one-line text).
- New `bin/forge-sbom.sh` + new standard `global/sbom-policy.md`.
- New `forge-ci.yml` `sbom` job.
- New consolidated spec `.forge/specs/janus-rules.md`.
- Test harness `.forge/scripts/tests/j8.test.sh` (≥ 18 L1 + 2 L2).
- Doc updates : `docs/ARCHETYPES.md` (refusal table) + `docs/CLI.md`
  (or equivalent) for the new flag + `CHANGELOG.md`.

## Scope Out (Explicit Exclusions)

- **NOT** the `ai-native-rag` LLM gateway rules (J.8.c) — that
  archetype doesn't exist yet (T7 work). When `ai-native-rag` ships,
  a follow-up change extends the Janus rules to force Mistral-EU /
  vLLM at T3.
- **NOT** automated SBOM upload to a transparency log (Sigstore /
  in-toto) — adopter concern, deferred.
- **NOT** SBOM signing or attestation — same.
- **NOT** the J.8 Janus rules for `mobile-only` / `mobile-pwa-first`
  archetypes — covered when those archetypes graduate to T3
  posture in T8 (B.9 work).
- **NOT** automatic compliance-tier detection from cluster
  topology — Janus enforces what the user *declares*, not what the
  cluster *is*. Detection is a Demeter (K.3) concern.
- **NOT** modifying the existing standards
  (`identity.yaml` / `observability.yaml`) — only the wrappers
  cross-reference them. Standards stay at their current versions.
- **NOT** retroactive SBOM for already-archived changes — SBOM
  generation starts shipping at this change's archive date.

## Impact

- **Users affected** :
  - Adopters running `forge init --archetype flutter-firebase`
    today get a generic error → after this, a clear Schrems II /
    CLOUD Act refusal pointing to the `default` archetype +
    documented Firebase-overlay path.
  - Adopters running `forge init --eu-tier T3` get tier-specific
    refusals + the `.forge-tier` ledger for downstream tooling.
  - All adopters can now generate a CycloneDX SBOM via
    `forge sbom` (or `bin/forge-sbom.sh` directly).
- **Technical impact** : ≈ 6 new files (Janus rules section,
  dispatch-table forbidden list, wrapper refusal logic, sbom
  script, sbom workflow, sbom standard) + ≈ 5 modified
  (init.ts CLI, fsm wrapper, ARCHETYPES.md, CHANGELOG.md, the
  Janus agent). Test harness ≥ 18 L1 + 2 L2. **Effort `L`**.
- **Dependencies** :
  - T.4 `compliance-tier.schema.json` v1.0.0 ✅ shipped.
  - T.4 `archetype.schema.json` v2 ✅ shipped (5-archetype enum +
    `mobile-only` legacy alias).
  - J.7 `j7-validate-standards-yaml` ✅ shipped (validates the new
    `janus-orchestration-rules.md` + `sbom-policy.md` if added as
    YAML — they're MD, so J.7 is informational not blocking).
  - Independent of T5-OTEL (just merged) and any T6+ work.
  - No new external dependency. SBOM generation uses existing
    `cargo`, `npm`, `flutter` toolchain only ; CycloneDX format
    handcrafted via Python 3 inline (no `cyclonedx-cli` dep).
- **Risk level** : **Medium**. The CLI flag plumbing
  (`--eu-tier`) crosses CLI/wrapper/dispatcher seams ; bug here
  could impact `forge init` for ALL adopters, not just T3. Mitigated
  by NFR-J8-002 (backward compat — the flag is optional, default
  is "no tier declared" which behaves identically to today).

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 writes
`j8.test.sh` with ~18 L1 + 2 L2 stubs returning `_not_implemented`
(full RED witness). Phase 2 implements one cluster at a time.

### Article II — BDD

User-facing CLI behaviors (the `--eu-tier` flag, the refusal
errors) get Gherkin scenarios in `specs.md` :
- `Given a forbidden archetype request, When forge init runs, Then it exits 3 with the Schrems II rationale and the alternative path.`
- `Given --eu-tier T3 + --archetype full-stack-monorepo, When the wrapper runs, Then it forces self-host Zitadel + self-host SigNoz.`
- `Given a target tree with Cargo.lock + package-lock.json, When bin/forge-sbom.sh runs, Then a valid CycloneDX 1.5 JSON is produced.`

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-J8-*`
namespace before any implementation.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Open questions captured below ; resolved before status flips to
`implemented`.

### Article V — Audit Trail

Each task tagged `[Story: FR-J8-XXX]`. Refusal error messages
reference the rule ID + the standard (e.g.
`[J8-RULE-001: flutter-firebase forbidden — see standards/global/janus-orchestration-rules.md]`),
machine-parseable.

### Article VIII — Infrastructure

The SBOM workflow is an Article VIII concern (CI artefact). The
job is `runs-on: ubuntu-latest`, no privileged steps, no secrets.

### Article XII — Governance

The Janus refusal rules ENFORCE the Schrems II / CLOUD Act
positioning encoded in ADR-007 / ADR-008 / ADR-010 of
`docs/ARCHITECTURE-TARGET.md`. They do **not amend** any
constitutional article. The new standards
(`janus-orchestration-rules.md` + `sbom-policy.md`) are MD, not
YAML — they don't carry the J.7 frontmatter contract, so J.7
validation does not apply (J.7 is YAML-only).

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`proposal.md`. Three open questions Q-001 + Q-002 + Q-003 raised
at this phase, all tracked in `open-questions.md` and resolved
during `/forge:design` :

- **Q-001** → ADR-J8-001 locks **handcraft Python 3 inline** for
  SBOM generation, after Context7 review of
  `/cyclonedx/cyclonedx-python-lib` confirmed the minimum-viable
  CycloneDX 1.5 fits in handcraft territory (NFR-J8-005 zero
  new deps preserved).
- **Q-002** → ADR-J8-002 locks **no default** for `--eu-tier`
  with a soft `[INFO: --eu-tier not set ...]` warning, suppressible
  via `FORGE_EU_TIER_QUIET=1`. Backward compat preserved
  (NFR-J8-002).
- **Q-003** → ADR-J8-003 locks **exit code 3** for policy
  refusals, distinct from 1 (invalid) / 2 (usage). A future
  `global/cli-exit-codes.md` standard will lock the convention
  repo-wide ; out of scope here.
