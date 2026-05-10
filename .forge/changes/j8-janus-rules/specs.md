# Specifications: j8-janus-rules
<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-J8-*` / `NFR-J8-*`. **Constitution** : v1.1.0.
Pas d'amendement requis (J.8 enforces, ne modifie pas).

## Source Documents

| Field             | Value                                                                                                                                                                                |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **ADR base**      | `t4-adr-ratification` archived 2026-05-04 (FR-T4-ADR-007 + ADR-008 + ADR-010 ratifying Schrems II + CLOUD Act + EU compliance positioning ; FR-T4-SCH-001..002 ratifying compliance-tier + archetype.schema v2) |
| **Plan ref**      | `docs/new-archetypes-plan.md` §1.4 J.7/J.8 row + §15 item #4 ; `docs/ARCHITECTURE-TARGET.md` §12.5                                                                                   |
| **Roadmap ref**   | `.forge/product/roadmap.md` Phase 3 / T5 row ("Still pending in T5 : J.8 Janus forbidden-list rules")                                                                                 |
| **Schema reuse**  | `.forge/schemas/compliance-tier.schema.json` v1.0.0 (T.4 — enum `[T1, T2, T3]`) ; `.forge/schemas/archetype.schema.json` v2 (5-archetype enum + `mobile-only` legacy alias)         |
| **Pattern reuse** | `b5-1-init-wizard` archived 2026-04-30 (CLI flag dispatching pattern, env-var ABI to wrappers) ; `j7-validate-standards-yaml` (bash thin + Python 3 inline pattern for SBOM script)  |
| **Standard refs** | `identity.yaml` v1.0.0 (Zitadel default + forbidden Firebase Auth) ; `observability.yaml` v1.1.0 (forbidden Datadog ; `aegis_audit_required_for_prod`)                              |
| **CycloneDX**     | CycloneDX 1.5 JSON spec (https://cyclonedx.org/specification/overview/) — pinned at design time per ADR-J8-001                                                                       |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Janus agent forbidden-archetypes section (FR-J8-001 → 005)

##### FR-J8-001 — `cross-layer-orchestrator.md` H2 section

`.claude/agents/cross-layer-orchestrator.md` MUST gain a new H2
section "Forbidden archetypes & combinations" placed between the
existing "Dispatch Table" and "12-Step Workflow" sections.

##### FR-J8-002 — Rule enumeration

The new section MUST enumerate at least 3 numbered rules covering :
- **J8-RULE-001** : `flutter-firebase` archetype refused (Schrems II
  + CLOUD Act ; ADR-007).
- **J8-RULE-002** : `--eu-tier T3` requires self-host Zitadel +
  self-host SigNoz (ADR-007 + ADR-008 ; `identity.yaml` +
  `observability.yaml`).
- **J8-RULE-003** : `--eu-tier T3` refuses Datadog as observability
  backend (already encoded in `observability.yaml::forbidden:` —
  Janus surfaces at scaffold time).

Each rule MUST cite : (a) the rationale in one sentence, (b) the
ADR / standard reference, (c) the alternative path the adopter
should take.

##### FR-J8-003 — Cross-link to dispatch-table

The section MUST cross-link to
`.forge/scaffolding/dispatch-table.yml::forbidden_archetypes` and
to the new standard `global/janus-orchestration-rules.md`.

##### FR-J8-004 — Routing duty surface

The section MUST state that Janus invokes the dispatcher's refusal
logic before any layer-specific routing (Atlas / Vulcan / Hera).
Refusals are terminal — no override.

##### FR-J8-005 — Header audit trail

A `<!-- Audit: J.8 (j8-janus-rules) -->` HTML comment MUST anchor
the section per the existing audit-trail convention.

---

#### Cluster 2 — `dispatch-table.yml` forbidden list (FR-J8-010 → 013)

##### FR-J8-010 — Top-level `forbidden_archetypes:` list

`.forge/scaffolding/dispatch-table.yml` MUST gain a top-level key
`forbidden_archetypes:` (list of objects).

##### FR-J8-011 — Entry shape

Each entry MUST carry the keys :
- `name` (string, the forbidden archetype name)
- `reason` (string, one-line human-readable refusal cause)
- `since` (SemVer, framework version that introduced the refusal)
- `alternative` (string, suggested path forward — archetype name
  OR free-form path like "stay on `default` + add Firebase as
  overlay").
- `rule_id` (string, kebab-case anchor matching the Janus rule —
  e.g. `J8-RULE-001`).

##### FR-J8-012 — Seed entry `flutter-firebase`

The seed entry MUST be `flutter-firebase` with :
- `reason: "Schrems II + CLOUD Act incompatibles avec positionnement EU/premium Forge"`
- `since: "0.4.0-rc.1"`
- `alternative: "default archetype + add Firebase as adopter-managed overlay (out of Forge scope)"`
- `rule_id: J8-RULE-001`.

##### FR-J8-013 — Schema regression

`.forge/schemas/archetype.schema.json` v2 already declared
`x-removed-from-taxonomy.flutter-firebase` (T.4). This change is
**additive** — the schema is unchanged ; the dispatch-table gains
the runtime enforcement leg.

---

#### Cluster 3 — Wrapper refusal logic (FR-J8-020 → 023)

##### FR-J8-020 — TS dispatcher refusal check

`cli/src/commands/init-archetype.ts` (or the dispatcher entry-point
locked at design time) MUST check the requested archetype name
against `dispatch-table.yml::forbidden_archetypes[*].name` BEFORE
invoking any wrapper. On match → exit 3 + structured error to
stderr.

##### FR-J8-021 — Refusal error format

Refusal stderr line MUST follow the format :
```
[REFUSAL: <archetype>: <rule_id>: <reason> ; alternative: <alternative>]
```
Single-line, machine-parseable.

##### FR-J8-022 — Wrapper-side defense in depth

Each `bin/forge-init-<archetype>.sh` wrapper MUST also check (in
case the dispatcher is bypassed) and refuse with the same exit 3
+ error format. Implemented as a shared helper sourced from a new
`bin/_forge-init-helpers.sh`.

##### FR-J8-023 — Exit code locking

Refusal exit code is **3** (policy violation), distinct from exit
2 (usage error) and exit 4 (I/O collision per `forge-snapshot.sh`).
Resolves Q-003.

---

#### Cluster 4 — `janus-orchestration-rules.md` standard (FR-J8-030)

##### FR-J8-030 — New global standard

`.forge/standards/global/janus-orchestration-rules.md` MUST exist
with at least 5 H2 sections : Purpose, Rule catalogue (J8-RULE-XXX
table), Adoption path, Refusal vs warning semantics, Extending the
catalogue. Markdown only — no YAML frontmatter, so J.7 validation
is informational not blocking.

---

#### Cluster 5 — `--eu-tier` CLI flag (FR-J8-040 → 045)

##### FR-J8-040 — New flag declaration

`cli/src/commands/init.ts` MUST gain a `--eu-tier <tier>` flag
declared via the existing flag-parsing infrastructure (mirror the
`--archetype` shape).

##### FR-J8-041 — Validation

The flag value MUST be validated against
`.forge/schemas/compliance-tier.schema.json` enum `[T1, T2, T3]`
(case-sensitive). Invalid value → exit 2 + usage error pointing to
the schema.

##### FR-J8-042 — Default behaviour

If the flag is absent, behaviour is **identical to today** (no tier
declared). NFR-J8-002 backward compat. Resolves Q-002.

##### FR-J8-043 — Env-var ABI to wrappers

Validated tier MUST be passed to wrapper scripts via env var
`FORGE_EU_TIER=<tier>`. Wrappers consume this env var per the
stable ABI declared in `global/scaffolding.md` (B.5.1).

##### FR-J8-044 — Mutual exclusion

The `--eu-tier` flag is **independent** of the `--archetype` /
`--auto` / `--wizard` mutually-exclusive trio (FR-IW-002 of B.5.1).
Tier may be combined with any of the three (e.g.
`forge init --archetype full-stack-monorepo --eu-tier T3`).

##### FR-J8-045 — Wizard prompt

When `--wizard` is invoked, the interactive prompt MUST ask for
the EU tier as one of its questions. Default answer is "skip"
(no tier declared, FR-J8-042).

---

#### Cluster 6 — T3 enforcement in `forge-init-fsm.sh` (FR-J8-050 → 054)

##### FR-J8-050 — T3 detection

`bin/forge-init-fsm.sh` MUST read `$FORGE_EU_TIER` and apply
T3-specific rules when the value equals `T3`.

##### FR-J8-051 — Self-host Zitadel forced

When T3, the wrapper MUST refuse any
`identity_provider != zitadel-self-hosted` opt that would otherwise
be selectable. The default `zitadel` per `identity.yaml` is
already self-hostable, so the rule is a hard block on cloud-Zitadel
or Auth0/Keycloak-cloud variants. Refusal exit 3 + format per
FR-J8-021.

##### FR-J8-052 — Self-host SigNoz forced

When T3, the wrapper MUST refuse the SigNoz Cloud SaaS endpoint
in any rendered template. The shipped `signoz-config.yaml.tmpl`
already targets local-dev (B.1.14) so this is a future-proofing
guard ; the wrapper greps the rendered output for any `signoz.io`
SaaS endpoint and exits 3 if found.

##### FR-J8-053 — Datadog absence enforced

When T3, the wrapper MUST verify that the rendered
`infra/observability/otel-collector-config.yaml` does NOT export
to Datadog. Per `observability.yaml::forbidden: [datadog]` —
already enforced at standard level ; this is the runtime surface.

##### FR-J8-054 — T1 / T2 informational

When `$FORGE_EU_TIER=T1` or `T2`, the wrapper emits an
informational stdout line per FR-J8-021's format prefix
`[INFO: <tier>: ...]` but does NOT refuse anything. T1 RGPD-via-DPA
accepts cloud SaaS ; T2 self-hostable is a recommendation.

---

#### Cluster 7 — `.forge-tier` ledger (FR-J8-060)

##### FR-J8-060 — One-line text ledger

When `$FORGE_EU_TIER` is set (any tier), the scaffolded project
gets a `.forge/.forge-tier` file containing exactly one line :
`<tier>` (e.g. `T3`). The file is written by the wrapper post-
scaffold, NOT by the TS dispatcher (per the wrapper-owns-target-tree
ABI). Adopter-side downstream tooling consumes this for
deployment-time gating.

---

#### Cluster 8 — `forge-sbom.sh` script (FR-J8-070 → 076)

##### FR-J8-070 — Script exists + signature

`bin/forge-sbom.sh` MUST exist as executable bash. Signature :
```
bin/forge-sbom.sh [--output <path>] [--format json|xml] [--target <dir>]
```
Defaults : `--output sbom.cdx.json`, `--format json`,
`--target $(pwd)`. Exit codes 0 (PASS) / 1 (no lockfiles found
or format error) / 2 (usage).

##### FR-J8-071 — Lockfile detection

The script MUST detect, in `--target`, the presence of any of :
- `Cargo.lock` (Rust)
- `package-lock.json` OR `pnpm-lock.yaml` OR `yarn.lock` (npm
  family — at least one accepted)
- `pubspec.lock` (Dart / Flutter)

At least one must be present, else exit 1 with diagnostic.

##### FR-J8-072 — CycloneDX 1.5 JSON output

Output MUST conform to the CycloneDX 1.5 JSON spec — minimum
mandatory fields : `bomFormat: "CycloneDX"`, `specVersion: "1.5"`,
`serialNumber: "urn:uuid:<v4>"`, `version: 1`, `metadata.timestamp`
(ISO 8601), `components` (list with at least `type`, `name`,
`version`, `purl` per component).

##### FR-J8-073 — Component aggregation

For each detected lockfile, the script MUST emit one component per
locked dependency :
- Cargo : `purl = pkg:cargo/<name>@<version>`
- npm : `purl = pkg:npm/<name>@<version>`
- pubspec : `purl = pkg:pub/<name>@<version>`

Implementation : Python 3 inline parses each lockfile (TOML for
Cargo, JSON for npm, YAML for pubspec — all stdlib + already
present PyYAML). No external CycloneDX lib.

##### FR-J8-074 — XML output (optional)

When `--format xml`, output MUST be CycloneDX 1.5 XML conforming
to the upstream XSD. Minimal handcrafted XML (Python `xml.etree`)
covering the same components.

##### FR-J8-075 — Determinism

Two consecutive runs against the same target tree MUST produce
**identical output bytes** — components sorted by `purl`, timestamps
fixed via `SOURCE_DATE_EPOCH` env var when set (reproducible-build
convention).

##### FR-J8-076 — Validation

Output JSON validates against the upstream CycloneDX 1.5 JSON
schema. Validation is not bundled (schema is large) ; instead, the
harness L2 fixture asserts the mandatory fields are present.

---

#### Cluster 9 — `sbom-policy.md` standard (FR-J8-080)

##### FR-J8-080 — New global standard

`.forge/standards/global/sbom-policy.md` MUST exist with at least
4 H2 sections : Purpose & EU compliance rationale (NIS2 / DORA /
CRA), Format choice (CycloneDX 1.5 over SPDX 2.3 — sourced),
Regeneration cadence (every release + on-demand), Out-of-scope
(no signing / no transparency log this change). Markdown only.

---

#### Cluster 10 — CI workflow (FR-J8-090)

##### FR-J8-090 — `sbom` job in `forge-ci.yml`

`.github/workflows/forge-ci.yml` MUST gain a new job `sbom` that :
- runs after the `harness` job (depends-on)
- checks out the repo
- runs `bash bin/forge-sbom.sh --target examples/forge-fsm-example/`
- uploads the resulting `sbom.cdx.json` as a build artefact via
  `actions/upload-artifact@v4`
- runs on PR + main pushes (matching the existing trigger matrix)

---

#### Cluster 11 — Test harness `j8.test.sh` (FR-J8-100 → 102)

##### FR-J8-100 — Harness exists

`.forge/scripts/tests/j8.test.sh` mirrors the J.7 / T.5 layout.

##### FR-J8-101 — L1 coverage ≥ 18 tests

Minimum 18 L1 tests covering :
- 3 Janus agent rules (section presence + 3 rule anchors).
- 4 dispatch-table forbidden-list (top-level key + entry shape +
  seed entry + rule_id back-ref).
- 4 wrapper refusal logic (TS dispatcher exit 3 + format + helper
  sourced + 1 wrapper smoke).
- 3 `--eu-tier` flag (declared + validated + env-var ABI).
- 3 SBOM script (signature + lockfile detection + JSON minimum
  fields).
- 1 sbom-policy standard exists.

##### FR-J8-102 — L2 coverage ≥ 2 fixture tests

Minimum 2 L2 fixtures :
- **L2-good** : fixture target dir with a synthetic `Cargo.lock` +
  `package-lock.json` ; assert `forge-sbom.sh` produces valid
  CycloneDX 1.5 JSON with N components.
- **L2-determinism** : run the script twice with `SOURCE_DATE_EPOCH=0`
  ; assert byte-identical output.

---

#### Cluster 12 — Documentation (FR-J8-110 → 112)

##### FR-J8-110 — `docs/ARCHETYPES.md` refusal table

`docs/ARCHETYPES.md` MUST gain a new H2 section "Forbidden
combinations" listing the J8-RULE-* table with cross-links to the
standard.

##### FR-J8-111 — `docs/CLI.md` (or new `docs/CLI-FLAGS.md`)

`--eu-tier` flag documented with semantics, example invocation,
backward-compat note, and pointer to `compliance-tier.schema.json`.
File location locked at design time (existing `docs/CLI.md` if
present, else new `docs/CLI-FLAGS.md`).

##### FR-J8-112 — `CHANGELOG.md` entry

Entry under `## [Unreleased]` summarising the 3 sub-modules.

---

### Non-Functional Requirements

#### NFR-J8-001 — Performance budget

`bin/forge-sbom.sh` MUST complete in ≤ 5 s on
`examples/forge-fsm-example/` (small lockfiles). Harness
`j8.test.sh --level 1` ≤ 5 s ; full `--level 1,2` ≤ 15 s.

#### NFR-J8-002 — Backward compatibility

Existing `forge init` invocations (no `--eu-tier`) MUST behave
identically to today. The flag is optional and additive ;
absence = no behavioural change.

#### NFR-J8-003 — Article V audit trail

Every task tagged `[Story: FR-J8-XXX]`. Refusal error messages
carry the rule ID + standard reference, machine-parseable.

#### NFR-J8-004 — F.2 / J.7 pattern alignment

`forge-sbom.sh` follows the bash + Python 3 inline pattern
verbatim where applicable.

#### NFR-J8-005 — No new external dependency

No `cargo-cyclonedx`, no `cyclonedx-npm`, no `cyclonedx-cli`.
Standard library + PyYAML (already required) only. Resolves
Q-001 in favor of handcrafted minimum-viable SBOM.

#### NFR-J8-006 — TypeScript strict mode preserved

The `cli/src/commands/init.ts` edit MUST preserve the existing
`strict: true` tsconfig posture. No `any`, no `@ts-ignore`.

---

## BDD Acceptance Criteria

### Scenario 1 — flutter-firebase refusal

```gherkin
Given an adopter runs `forge init --archetype flutter-firebase`
When the dispatcher reads the dispatch-table forbidden_archetypes list
Then the process exits with code 3
And stderr contains exactly "[REFUSAL: flutter-firebase: J8-RULE-001: Schrems II + CLOUD Act incompatibles avec positionnement EU/premium Forge ; alternative: default archetype + add Firebase as adopter-managed overlay (out of Forge scope)]"
And no scaffolding side-effect occurs in the target dir
```

### Scenario 2 — `--eu-tier T3` enforcement

```gherkin
Given an adopter runs `forge init --archetype full-stack-monorepo --eu-tier T3`
And the wrapper bin/forge-init-fsm.sh runs with FORGE_EU_TIER=T3
When the wrapper completes scaffolding
Then the file <target>/.forge/.forge-tier exists with content "T3"
And the rendered observability config exports do not contain "datadog"
And no SigNoz Cloud SaaS endpoint is rendered
```

### Scenario 3 — SBOM generation deterministic

```gherkin
Given a target tree with Cargo.lock, package-lock.json, and pubspec.lock
And SOURCE_DATE_EPOCH is exported as 0
When `bash bin/forge-sbom.sh --target <tree>` runs twice in succession
Then both runs produce byte-identical sbom.cdx.json
And the JSON has bomFormat: "CycloneDX", specVersion: "1.5"
And components are sorted by purl
```

---

## Anti-Hallucination Pass

For each FR :

- **Testable** : every FR is asserted by at least one test in
  `j8.test.sh` (mapping captured in `tasks.md` `[Story: FR-J8-XXX]`
  tags during `/forge:plan`).
- **Unambiguous** : 3 ambiguities flagged in proposal, all
  resolvable at design time after Context7 review of CycloneDX
  spec + the existing CLI exit-code conventions.
- **Constitution-compliant** : Articles I (TDD), II (BDD), III
  (specs first), IV (delta), V (audit trail), VIII (CI), XII
  (governance — enforces, does not amend).

---

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`specs.md`. Three open questions Q-001 + Q-002 + Q-003 raised at
the proposal phase, tracked in `open-questions.md`, to be resolved
during `/forge:design`.
