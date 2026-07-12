# Spec: janus-rules

<!-- Audit: J.8 (j8-janus-rules) — Janus orchestrator forbidden-list rules + --eu-tier flag + CycloneDX SBOM. -->
<!-- Source change : `.forge/changes/j8-janus-rules/` (archived 2026-05-10). -->

**Namespace** : `FR-J8-*` / `NFR-J8-*`. **Constitution** : v1.1.0.
Pas d'amendement requis (J.8 enforces, ne modifie pas).

**Three sub-modules** :
- **J.8.a** Janus refusal rules (FR-J8-001..030).
- **J.8.b** `--eu-tier` flag + T3 enforcement + ledger (FR-J8-040..060).
- **J.8.d** CycloneDX 1.5 SBOM (FR-J8-070..090).

**Note** : J.8.c (`ai-native-rag` LLM gateway rules) **shipped 2026-06-22**
via `b7-9-janus-ai` (T7 / B.7.9). Its ADDED block (`FR-B7-9-*` / `NFR-B7-9-*`
/ `ADR-B7-9-*`) is appended at the END of this spec — it adds
`J8-RULE-004..006` (Vertex / Bedrock default refusal ; `--eu-tier T3` ⇒
Mistral-EU / vLLM). The J.8.a/b/d blocks below are unchanged.

---

## Functional Requirements

### Cluster 1 — Janus agent forbidden-archetypes section

#### FR-J8-001 — H2 section in agent file

`.claude/agents/cross-layer-orchestrator.md` carries an H2 section
"Forbidden archetypes & combinations" between "Dispatch Table" and
"12-Step Workflow".

#### FR-J8-002 — Rule enumeration (≥ 3 rules)

Section enumerates `J8-RULE-001` (flutter-firebase Schrems II +
CLOUD Act), `J8-RULE-002` (T3 ⇒ self-host Zitadel), and
`J8-RULE-003` (T3 ⇒ self-host SigNoz + no Datadog). Each rule
cites rationale + ADR/standard reference + alternative path.

#### FR-J8-003 — Cross-link to dispatch-table

Section cross-links to
`.forge/scaffolding/dispatch-table.yml::forbidden_archetypes` and
to `.forge/standards/global/janus-orchestration-rules.md`.

#### FR-J8-004 — Routing duty surface

Section states Janus invokes the dispatcher's refusal logic
**before any layer-specific routing**. Refusals are terminal — no
override.

#### FR-J8-005 — Header audit anchor

`<!-- Audit: J.8 (j8-janus-rules) -->` HTML comment anchors the
section.

---

### Cluster 2 — `dispatch-table.yml` forbidden-archetypes list

#### FR-J8-010 — Top-level list

`.forge/scaffolding/dispatch-table.yml` carries a top-level
`forbidden_archetypes:` list.

#### FR-J8-011 — Entry shape

Each entry has 5 keys : `name`, `reason`, `since`, `alternative`,
`rule_id`.

#### FR-J8-012 — Seed entry `flutter-firebase`

Seed entry name = `flutter-firebase`, rule_id = `J8-RULE-001`,
reason cites Schrems II + CLOUD Act, alternative points to the
`default` archetype + adopter-managed Firebase overlay.

---

### Cluster 3 — Wrapper refusal logic + TS dispatcher

#### FR-J8-020 — TS dispatcher refusal check

`cli/src/commands/init-archetype.ts` checks the requested
archetype against `forbidden_archetypes` BEFORE invoking any
wrapper. New `ForbiddenArchetypeEntry` interface + extended
`DispatchTable` type. On match → throw Error with structured
`[REFUSAL: ...]` prefix + `exitCode: 3` marker.

#### FR-J8-021 — Refusal stderr format

Single-line, machine-parseable :
```
[REFUSAL: <archetype>: <rule_id>: <reason> ; alternative: <alternative>]
```

#### FR-J8-022 — Wrapper-side defense in depth

Each `bin/forge-init-<archetype>.sh` wrapper sources
`bin/_forge-init-helpers.sh` and invokes
`_refuse_if_forbidden "<archetype-name>"` as the first action.
PyYAML used to parse the dispatch-table inline.

#### FR-J8-023 — Exit code 3

Refusal exit code is `3` (policy violation), distinct from `1`
(invalid input) and `2` (usage error). ADR-J8-003.

---

### Cluster 4 — `janus-orchestration-rules.md` standard

#### FR-J8-030 — New standard

`.forge/standards/global/janus-orchestration-rules.md` exists with
≥ 5 H2 sections : Purpose, Rule catalogue, Adoption path, Refusal
vs warning semantics, Extending the catalogue + Governance.

---

### Cluster 5 — `--eu-tier` CLI flag

#### FR-J8-040 — Optional `euTier?:` field

`cli/src/commands/init.ts` `InitOptions` interface gains
`euTier?: string` optional field.

#### FR-J8-041 — Validation against compliance-tier schema

`EU_TIER_ENUM = ["T1", "T2", "T3"]` validated against
`.forge/schemas/compliance-tier.schema.json` (T.4). Invalid value
→ exit 2 + usage error referencing the schema.

#### FR-J8-042 — No default

Flag absence preserves backward compat (no tier-specific behavior
fires). NFR-J8-002 + ADR-J8-002.

#### FR-J8-043 — Env-var ABI

Validated tier passed to wrapper scripts via
`process.env.FORGE_EU_TIER = options.euTier`.

#### FR-J8-044 — Mutual independence

`--eu-tier` is independent of the
`--archetype` / `--auto` / `--wizard` mutually-exclusive trio
(B.5.1 ABI preserved).

#### FR-J8-045 — Wizard prompt (deferred)

Wizard prompt for EU tier scoped out of this change (default
behaviour : skip, no tier).

---

### Cluster 6 — T3 enforcement in `forge-init-fsm.sh`

#### FR-J8-050 — T3 detection

Wrapper reads `$FORGE_EU_TIER` post-scaffold. T3 case-block applies
guards.

#### FR-J8-051 — Self-host Zitadel forced

T3 + non-self-host Zitadel (Auth0 / Okta / Keycloak-cloud) →
exit 3 with `J8-RULE-002` refusal.

#### FR-J8-052 — Self-host SigNoz forced

T3 + SigNoz Cloud SaaS endpoint (`signoz.io`) → exit 3 with
`J8-RULE-003` refusal.

#### FR-J8-053 — Datadog absence enforced

T3 + Datadog exporter detected → exit 3 with `J8-RULE-003`
refusal.

#### FR-J8-054 — T1 / T2 informational

`FORGE_EU_TIER=T1` or `T2` → emits `[INFO: <tier>: ...]` stdout
line. No refusal at T1 / T2.

---

### Cluster 7 — `.forge-tier` ledger

#### FR-J8-060 — One-line plain-text ledger

When `$FORGE_EU_TIER` is non-empty, the wrapper writes
`<target>/.forge/.forge-tier` containing exactly one line `<tier>`
+ trailing newline. ADR-J8-006 (plain text, not YAML, for
adopter-side downstream simplicity).

---

### Cluster 8 — `forge-sbom.sh` script

#### FR-J8-070 — Script signature

`bin/forge-sbom.sh [--output <path>] [--format json|xml] [--target <dir>]`.
Defaults : `sbom.cdx.json`, `json`, `$(pwd)`. Exit 0 (success) /
1 (no lockfiles) / 2 (usage).

#### FR-J8-071 — Recursive lockfile detection

Walks `--target` (max depth 4) skipping common build/cache dirs
(`node_modules`, `target`, `.dart_tool`, `.git`, `.gradle`,
`build`, `Pods`, `.next`, `dist`, `.cache`, `vendor`). Detects
Cargo.lock, npm-family lockfiles
(`package-lock.json` / `pnpm-lock.yaml` / `yarn.lock`), pubspec.lock.

#### FR-J8-072 — CycloneDX 1.5 JSON output

Output conforms to CycloneDX 1.5 mandatory fields :
`bomFormat: "CycloneDX"`, `specVersion: "1.5"`,
`serialNumber: "urn:uuid:<v4|v5>"`, `version: 1`,
`metadata.timestamp` (ISO 8601), `metadata.tools` (forge-sbom.sh
self-attribution), `metadata.component` (target app),
`components[]` with `type` / `name` / `version` / `purl`.

#### FR-J8-073 — Component aggregation per ecosystem

Cargo : `purl = pkg:cargo/<name>@<version>`.
npm : `purl = pkg:npm/<name>@<version>`.
pubspec : `purl = pkg:pub/<name>@<version>`.

Python 3 inline parsers : `tomllib` (Cargo), `json` stdlib (npm),
PyYAML (pubspec). No external CycloneDX library.

#### FR-J8-074 — XML output (optional)

`--format xml` emits CycloneDX 1.5 XML via `xml.etree.ElementTree`
covering same components.

#### FR-J8-075 — Determinism

Two runs with same `SOURCE_DATE_EPOCH` produce byte-identical
output. Components sorted by `purl`. JSON via
`json.dumps(..., sort_keys=True, indent=2)`. SerialNumber derives
from `uuid.uuid5(NAMESPACE_URL, target+components-purls)` when
SOURCE_DATE_EPOCH set, else `uuid.uuid4()`.

---

### Cluster 9 — `sbom-policy.md` standard

#### FR-J8-080 — New standard

`.forge/standards/global/sbom-policy.md` exists with ≥ 4 H2
sections : Purpose & EU compliance rationale (NIS2 / DORA / CRA),
Format choice (CycloneDX 1.5 over SPDX 2.3), Regeneration cadence,
Out-of-scope.

---

### Cluster 10 — CI workflow

#### FR-J8-090 — `sbom` job in `forge-ci.yml`

New job `sbom` after `harness` :
- `runs-on: ubuntu-latest`
- `needs: [harness]`
- runs `bash bin/forge-sbom.sh --target examples/forge-fsm-example/
  --output sbom.cdx.json`
- uploads `sbom.cdx.json` via `actions/upload-artifact@v4`
  with `name: sbom-cyclonedx`, `if-no-files-found: error`.

---

### Cluster 11 — Test harness

#### FR-J8-100 — Harness exists

`.forge/scripts/tests/j8.test.sh` mirrors J.7 / T.5-OTel layout.

#### FR-J8-101 — L1 coverage = 18 tests

18 L1 tests covering 3 Janus + 3 dispatch-table + 4 helper /
dispatcher + 1 standard + 3 flag + 1 T3 + 1 ledger + 1 sbom
signature + 1 sbom-policy.

#### FR-J8-102 — L2 coverage = 2 fixtures

2 L2 fixtures : good-fixture (synthetic Cargo.lock +
package-lock.json producing valid CycloneDX 1.5 with components)
+ determinism (byte-identical output with `SOURCE_DATE_EPOCH=0`).

---

### Cluster 12 — Documentation

#### FR-J8-110 — `docs/ARCHETYPES.md`

New "Forbidden combinations" + "EU compliance tier (`--eu-tier`)"
H2 sections.

#### FR-J8-111 — CLI flag doc

`--eu-tier` flag documented in `docs/ARCHETYPES.md` "EU
compliance tier" section (no separate `docs/CLI-FLAGS.md` created
— existing structure preserved).

#### FR-J8-112 — `CHANGELOG.md` entry

Entry under `## [Unreleased]` summarising the 3 sub-modules.

---

## Non-Functional Requirements

### NFR-J8-001 — Performance budget

`bin/forge-sbom.sh` against `examples/forge-fsm-example/` ≤ 5 s.
**Measured** : ≈ 1 s (74 components in JSON).
Harness `--level 1,2` ≤ 15 s. **Measured** : ≈ 2 s.

### NFR-J8-002 — Backward compatibility

`forge init` invocations without `--eu-tier` behave identically to
pre-J.8. **Confirmed** : flag is optional, default-empty
`process.env.FORGE_EU_TIER` ; wrappers gate tier blocks on
`[ -n "$FORGE_EU_TIER" ]`.

### NFR-J8-003 — Article V audit trail

Every task tagged `[Story: FR-J8-XXX]` ; refusal stderr lines
carry `J8-RULE-NNN` IDs (ADR-J8-004) machine-parseable.

### NFR-J8-004 — F.2 / J.7 pattern alignment

`forge-sbom.sh` follows the bash + Python 3 inline pattern
verbatim. Harness layout mirrors `j7.test.sh` + `t5-otel.test.sh`.

### NFR-J8-005 — No new external dependency

No `cargo-cyclonedx`, no `cyclonedx-npm`, no `cyclonedx-cli`.
Python stdlib (`tomllib` ≥ 3.11, `json`, `xml.etree`, `uuid`,
`datetime`) + PyYAML (already required).

### NFR-J8-006 — TypeScript strict mode preserved

`init.ts` + `init-archetype.ts` edits preserve `strict: true` ;
no `any`, no `@ts-ignore`. New `ForbiddenArchetypeEntry`
interface + `EU_TIER_ENUM` typed `readonly ["T1", "T2", "T3"]`.

---

## ADRs (J.8 design)

| ID         | Decision                                                                                                                                                                |
|------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ADR-J8-001 | SBOM tooling : handcrafted Python 3 inline (Context7-verified CycloneDX 1.5 mandatory fields). Zero new external dep. Bash thin + Python inline mirroring F.2 / J.7.    |
| ADR-J8-002 | `--eu-tier` no default. Soft `[INFO: --eu-tier not set ...]` warning suppressible via `FORGE_EU_TIER_QUIET=1`. Backward compat preserved.                              |
| ADR-J8-003 | Refusal exit code = 3 (policy violation), distinct from 1 (invalid) / 2 (usage). Future `global/cli-exit-codes.md` standard locks the convention repo-wide.            |
| ADR-J8-004 | Janus rule ID format = `J8-RULE-NNN` (audit-prefix + sequential). Greppable, cross-referenceable. Future audit modules use their own prefix (`K3-RULE-NNN`, etc.).      |
| ADR-J8-005 | Wrapper refusal helper = shared bash sourced from `bin/_forge-init-helpers.sh`. DRY across wrappers ; PyYAML used inline for dispatch-table read.                       |
| ADR-J8-006 | `.forge-tier` ledger = plain text 1-line (not YAML). Adopter-side downstream tooling stays simple. Future SemVer for extensibility.                                     |
| ADR-J8-007 | `forge-sbom.sh` architecture : bash thin + Python 3 inline (F.2/J.7 pattern verbatim). 3-phase engine : detect → parse → emit (JSON or XML).                          |

Full design rationale + Mermaid diagrams + Open Questions resolution :
`.forge/changes/j8-janus-rules/design.md`.

---

## J.8.c — Janus LLM-provider rules for `ai-native-rag` (b7-9-janus-ai)

<!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) — archived 2026-06-22. -->
<!-- ADDED block ; the J.8.a / J.8.b / J.8.d blocks above are preserved unchanged. -->

**Namespace** : `FR-B7-9-*` / `NFR-B7-9-*` / `ADR-B7-9-*`. **Constitution** :
v2.0.0 (no amendment — J.8.c ENFORCES the EU-sovereign LLM-provider posture
already encoded in `compliance-tiers.md` §10.2). Rule IDs
`J8-RULE-004/005/006` allocated sequentially after `J8-RULE-003` (ADR-J8-004 ;
never reused). Refuse Vertex AI / AWS Bedrock as default LLM providers
(CLOUD Act) ; at `--eu-tier T3` force Mistral-EU (Mistral on Scaleway) /
self-hosted vLLM.

### Functional Requirements (J.8.c)

**Cluster 1 — Janus agent new rules (`J8-RULE-004..006`)**
- **FR-B7-9-001** — New rules land INSIDE the existing `cross-layer-orchestrator.md` H2 "Forbidden archetypes & combinations", under a new H3 "LLM-provider rules (`ai-native-rag`)" after the `J8-RULE-003` H4 and before "Refusal semantics" (no new H2 — collision avoidance with `b7-pythia`, ADR-B7-9-004).
- **FR-B7-9-002** — `J8-RULE-004` Vertex AI refused as default LLM provider (CLOUD Act / GCP-managed) ; cites §10.2 `AWS/GCP/Azure` + `LLM Gateway` rows ; alternative Mistral-EU / vLLM / OpenAI-via-EU-gateway@T1.
- **FR-B7-9-003** — `J8-RULE-005` AWS Bedrock refused as default (same rationale family + alternative).
- **FR-B7-9-004** — `J8-RULE-006` `--eu-tier T3` ⇒ Mistral-EU / vLLM ; any US-managed inference refused at T3 (cites §10.2 forcing note).
- **FR-B7-9-005** — Each rule carries the four sub-bullets of `J8-RULE-001..003` (Rationale / Reference / Alternative / tier applicability).
- **FR-B7-9-006** — The H3 carries `<!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) -->`.

**Cluster 2 — `forbidden_combinations:` registry**
- **FR-B7-9-020** — New top-level `forbidden_combinations:` list in `dispatch-table.yml`, sibling to `forbidden_archetypes:`.
- **FR-B7-9-021** — 7-key entry shape (archetype/provider/tier/reason/since/alternative/rule_id) ; `tier: any` = default-refusal, `tier: T3` = tier-conditional.
- **FR-B7-9-022** — Three seed entries (vertex-ai/any/J8-RULE-004 ; bedrock/any/J8-RULE-005 ; us-managed-inference/T3/J8-RULE-006), `since: "0.5.0"`.
- **FR-B7-9-023** — YAML comment header documenting consumers + exit-3 + the `[REFUSAL:]` format.

**Cluster 3 — Combination-refusal helper**
- **FR-B7-9-040** — New additive `_refuse_if_forbidden_combination "<archetype>" "<provider>"` in `bin/_forge-init-helpers.sh` ; `_refuse_if_forbidden` unchanged (ADR-J8-005 pattern).
- **FR-B7-9-041** — Tier resolved `$FORGE_EU_TIER` → `.forge/.forge-tier` first line → empty (empty ⇒ only `tier: any` matches ; no guessed default, Article III.4).
- **FR-B7-9-042** — Match (archetype ∧ provider ∧ (`tier: any` ∨ tier == resolved)) ⇒ `[REFUSAL:]` to stderr + exit 3 (ADR-J8-003).
- **FR-B7-9-043** — Refusal format `[REFUSAL: <archetype>/<provider>@<tier>: <rule_id>: <reason> ; alternative: <alternative>]`.
- **FR-B7-9-044** — Fail-open (return 0) on unreachable dispatch-table.
- **FR-B7-9-045** — `bin/forge-init-ai-native-rag.sh` sources + invokes the helper for its LLM-gateway provider (existing candidate exit-3 gate intact).

**Cluster 4 — Standards updates**
- **FR-B7-9-060** — `janus-orchestration-rules.md` rule catalogue gains 3 rows.
- **FR-B7-9-061** — "Extending the catalogue" prose updated ("sibling list now exists") ; SemVer + `REVIEW.md` entry.
- **FR-B7-9-062** — `compliance-tiers.md::forbidden:` += `vertex-ai`, `bedrock` (review-time I.3 `T3-RULE-005`) ; **SemVer-minor bump 1.0.0 → 1.1.0, shipped in-brick** (maintainer "Option B", 2026-06-22 ; the over-strict `i2.test.sh` pin was relaxed in lock-step).
- **FR-B7-9-063** — `constitution-linter.sh::ADR-I3-001` REMEDIATION entries for `vertex-ai` / `bedrock`.
- **FR-B7-9-064** — `forbidden-components-rules.md` LLM-provider interim-gap note (bumped 1.0.0 → 1.1.0 ; `i3.test.sh` pin relaxed in lock-step).

**Cluster 5 — Test harness**
- **FR-B7-9-080/081/082** — `b7-9.test.sh` (j8 / i3 layout) ; 13 L1 grep tests + 2 L2 fixtures (T3 refuse → exit 3 ; T1 no-refuse → exit 0).
- **FR-B7-9-083** — `b7-9.test.sh --level 1,2` registered in `forge-ci.yml` after `b7-2.test.sh`.

**Cluster 6 — Documentation**
- **FR-B7-9-100** — `docs/ARCHETYPES.md` LLM-provider-refusals note (`J8-RULE-004..006` + Mistral-EU / vLLM).
- **FR-B7-9-101** — `CHANGELOG.md [Unreleased]` entry.

### Non-Functional Requirements (J.8.c)
- **NFR-B7-9-001** — Additive only (no rule renumber ; `_refuse_if_forbidden` + ai-native-rag schema/templates untouched).
- **NFR-B7-9-002** — No regression (verify.sh / linters / j7 / j8 / i3 / b7-* GREEN ; candidate `ai-native-rag` init still exit 3).
- **NFR-B7-9-003** — Rule-ID numbering invariant (`J8-RULE-004..006` sequential after `J8-RULE-003` ; grep guards collision).
- **NFR-B7-9-004** — Pattern alignment (bash + PyYAML inline ; no new external dep).
- **NFR-B7-9-005** — Tier-scaled severity coherence (scaffold-time exit 3 + review-time WARN/FAIL quote the same §10.2 gradient ; never contradict).
- **NFR-B7-9-006** — Article V audit trail (`[Story: FR-B7-9-XXX]` task tags ; `J8-RULE-NNN` stderr IDs ; this appended block, J.8.a/b/d preserved).

### ADRs (J.8.c design)

| ID | Decision |
|----|----------|
| ADR-B7-9-001 | Reuse the `J8-RULE-NNN` namespace ; allocate the next free block `J8-RULE-004..006` ; never reuse. |
| ADR-B7-9-002 | New `forbidden_combinations:` sibling registry (NOT a `forbidden_archetypes:` extension) — provider×tier combinations, pre-foreseen by `janus-orchestration-rules.md` "Extending the catalogue" step 1. |
| ADR-B7-9-003 | New additive `_refuse_if_forbidden_combination` helper (existing helper's archetype-only contract preserved) ; exit 3 (ADR-J8-003). |
| ADR-B7-9-004 | Collision avoidance with `b7-pythia` : all J.8.c deltas to `cross-layer-orchestrator.md` stay INSIDE the "Forbidden archetypes & combinations" H2 ; Pythia edits the "Dispatch Table" H2. |
| ADR-B7-9-005 | Two complementary enforcement surfaces : scaffold-time Janus refusal (exit 3) + review-time I.3 `T3-RULE-005` (tier-scaled WARN/FAIL) ; the I.3 coupling shipped in-brick (maintainer "Option B"). |
| ADR-B7-9-006 | Mistral-EU (Mistral on Scaleway) + self-hosted vLLM VERIFIED verbatim against `compliance-tiers.md` §10.2 ; no provider specifics fabricated (Article III.4). |

Full design rationale + collision analysis + Open Questions resolution :
`.forge/changes/b7-9-janus-ai/design.md` + `open-questions.md`.

## B.6.10 — Janus event-broker rules for `event-driven-eu` (b6-10-janus-rule)

<!-- Audit: B.6.10 (b6-10-janus-rule) — archived 2026-07-10. -->
<!-- ADDED block ; the J.8.a / J.8.b / J.8.c / J.8.d blocks above are preserved unchanged. -->

Constitution v2.0.0 (no amendment — B.6.10 ENFORCES the EU-sovereign
event-broker posture already encoded in the `event-driven-eu` schema
`event_specifics.eu_sovereignty` + `compliance-tiers.md` §10.2). The direct
sibling of J.8.c : same `forbidden_combinations:` registry, same
`_refuse_if_forbidden_combination` helper (REUSED, not re-created), same
exit-3 / `[REFUSAL:]` convention, same I.3 review-time token coupling. Source
plan : `docs/new-archetypes-plan.md` §6.1 (B.6.10).

### Functional Requirements (B.6.10)

- **FR-B6-JR-001** — New H3 `### Event-broker rules (\`event-driven-eu\`)` INSIDE the existing "Forbidden archetypes & combinations" H2 of `cross-layer-orchestrator.md`, after the J.8.c LLM-provider H3, before "Refusal semantics".
- **FR-B6-JR-002** — `J8-RULE-007` : Confluent Cloud refused as event broker (any tier ; named US-managed Kafka SaaS, never a valid default).
- **FR-B6-JR-003** — `J8-RULE-008` : `--eu-tier T3` ⇒ any US-managed Kafka SaaS refused (NATS JetStream / Redpanda self-host forced).
- **FR-B6-JR-004** — Rule-body parity with `J8-RULE-004..006` (Rationale / Reference / Alternative / tier applicability).
- **FR-B6-JR-005** — Audit anchor `<!-- Audit: B.6.10 (b6-10-janus-rule) -->` on the new H3.
- **FR-B6-JR-020/021** — Two entries appended to the EXISTING `dispatch-table.yml::forbidden_combinations:` (confluent-cloud/any/J8-RULE-007 ; us-managed-kafka/T3/J8-RULE-008), `since: "0.6.0"`.
- **FR-B6-JR-040/041** — The `_refuse_if_forbidden_combination` helper is REUSED (not modified/duplicated) ; `bin/forge-init-event-driven-eu.sh` invokes it (`"${FORGE_EDE_EVENT_BROKER:-nats-jetstream}"`) after the scaffoldability gate.
- **FR-B6-JR-060/061** — `janus-orchestration-rules.md` catalogue += 2 rows ; "Refusal vs warning semantics" + "full rule body" prose updated.
- **FR-B6-JR-062/063/064** — `compliance-tiers.md::forbidden:` += `confluent-cloud` (v1.1.0 → v1.2.0) ; `constitution-linter.sh` `REMEDIATION` += `confluent-cloud` ; `forbidden-components-rules.md` event-broker coupling subsection (v1.1.0 → v1.2.0). Reuses generic `T3-RULE-005` — NO new `T3-RULE-NNN` (reserved `T3-RULE-008` Persistence slot untouched).
- **FR-B6-JR-080..083** — `.forge/scripts/tests/b6-10.test.sh` (9 L1 + 3 L2) registered in `forge-ci.yml`.
- **FR-B6-JR-090** — `b7-9.test.sh::_test_b7_9_005` numbering guard relaxed to permit the newly-allocated 007/008 (sibling-harness coupling).
- **FR-B6-JR-100/101** — `docs/ARCHETYPES.md` rows + note ; `CHANGELOG.md` entry.

### Non-Functional Requirements (B.6.10)

- **NFR-B6-JR-001** — Additive only ; `_refuse_if_forbidden_combination` + `_refuse_if_forbidden` unchanged (reuse) ; no `J8-RULE-001..006` renumber ; schema/templates/scaffolder untouched.
- **NFR-B6-JR-002** — No regression (verify.sh / constitution-linter / validate-standards-yaml / j7 / j8 / b7-9 / i2 / i3 GREEN) ; fresh `event-driven-eu` init still refuses exit 3 (candidate) with the combination check dormant.
- **NFR-B6-JR-003** — `J8-RULE-007..008` allocated sequentially after 006 (never reused, ADR-J8-004).
- **NFR-B6-JR-004** — Harness mirrors `b7-9.test.sh` ; no new helper / external dependency.
- **NFR-B6-JR-005** — Scaffold-time (Janus, exit 3) + review-time (I.3 `T3-RULE-005`) surfaces quote the same §10.2 gradient + schema `no_kafka_saas_us` posture.
- **NFR-B6-JR-006** — Article V audit trail (`[Story: FR-B6-JR-XXX]` task tags ; `J8-RULE-NNN` stderr IDs ; this appended block, J.8.a/b/c/d preserved).

### ADRs (B.6.10 design)

| ID | Decision |
|----|----------|
| ADR-B6-JR-001 | Reuse the `J8-RULE-NNN` namespace ; allocate the next free block `J8-RULE-007..008` ; never reuse. |
| ADR-B6-JR-002 | REUSE the `forbidden_combinations:` registry + `_refuse_if_forbidden_combination` helper (b7-9-janus-ai) — append entries + a wrapper call site only ; no new registry/helper. |
| ADR-B6-JR-003 | Tier-scoping follows J.8.c : Confluent Cloud (named US SaaS) = `tier: any` (mirrors J8-RULE-004/005) ; `us-managed-kafka` (generic category) = `tier: T3` (mirrors J8-RULE-006). |
| ADR-B6-JR-004 | I.3 coupling reuses generic `T3-RULE-005` via a `confluent-cloud` token — NO new `T3-RULE-NNN` (reserved `T3-RULE-008` Persistence slot untouched) ; only the named any-tier token added (parity with b7-9 not adding `us-managed-inference`). |
| ADR-B6-JR-005 | Forward-looking guard grounded in the schema flag `event_specifics.eu_sovereignty.no_kafka_saas_us: true` ; NATS JetStream sovereign default, Redpanda sanctioned alternative, Confluent Cloud forbidden (Article III.4 — verified, no `[NEEDS CLARIFICATION]`). |
| ADR-B6-JR-006 | Relax `b7-9.test.sh::_test_b7_9_005` numbering guard to permit 007/008 (sibling-harness coupling — same discipline b7-9 applied to i2/i3). |

Full design rationale + tier-scoping analysis + Open Questions resolution :
`.forge/changes/b6-10-janus-rule/design.md` + `open-questions.md`.
