# Spec: janus-rules

<!-- Audit: J.8 (j8-janus-rules) — Janus orchestrator forbidden-list rules + --eu-tier flag + CycloneDX SBOM. -->
<!-- Source change : `.forge/changes/j8-janus-rules/` (archived 2026-05-10). -->

**Namespace** : `FR-J8-*` / `NFR-J8-*`. **Constitution** : v1.1.0.
Pas d'amendement requis (J.8 enforces, ne modifie pas).

**Three sub-modules** :
- **J.8.a** Janus refusal rules (FR-J8-001..030).
- **J.8.b** `--eu-tier` flag + T3 enforcement + ledger (FR-J8-040..060).
- **J.8.d** CycloneDX 1.5 SBOM (FR-J8-070..090).

**Note** : J.8.c (`ai-native-rag` LLM gateway rules) is NOT in this
change — depends on T7 ai-native-rag archetype not yet shipped.
A follow-up change extends the rule catalogue when that archetype
lands.

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
