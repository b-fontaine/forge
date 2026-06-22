# Spec: b7-9-janus-ai

<!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) — Janus refusal rules for the -->
<!-- ai-native-rag archetype : refuse Vertex AI / AWS Bedrock as default  -->
<!-- LLM providers (CLOUD Act) ; at --eu-tier T3 force Mistral-EU / vLLM   -->
<!-- self-host (refuse US-managed inference).                              -->
<!-- Source plan : docs/new-archetypes-plan.md §6.2 (B.7.9) + §8 (J.8.c). -->

**Namespace** : `FR-B7-9-*` / `NFR-B7-9-*` / `ADR-B7-9-*`.
**Constitution** : v2.0.0. No amendment required (J.8.c ENFORCES the
EU-sovereign LLM-provider posture already encoded in `compliance-tiers.md`
§10.2 ; it does not modify any article).

**Rule-ID allocation** : NEW `J8-RULE-NNN` entries in the existing J.8
namespace (ADR-J8-004 — IDs NEVER reused). The live catalogue ends at
`J8-RULE-003` (`janus-orchestration-rules.md` rule table) ; this change
allocates the next sequential block **`J8-RULE-004` / `J8-RULE-005` /
`J8-RULE-006`** (Q-001, confirmed at design).

**Relationship to J.8** : this is the **J.8.c** sub-module pre-announced
in `.forge/specs/janus-rules.md` lines 14-17 ("J.8.c (`ai-native-rag` LLM
gateway rules) is NOT in this change … A follow-up change extends the
rule catalogue when that archetype lands") and forward-pointed by
`global/llm-gateway.md` (ADR-B7-3-002). At archive time, the ADDED block
below is APPENDED to `.forge/specs/janus-rules.md`.

---

## Functional Requirements

### Cluster 1 — Janus agent new rules (`J8-RULE-004..006`)

#### FR-B7-9-001 — Rules land in the existing H2 section

The new rules are authored **inside** the existing
`.claude/agents/cross-layer-orchestrator.md` H2 section "Forbidden
archetypes & combinations" (shipped by J.8 / FR-J8-001), under a new H3
sub-section "LLM-provider rules (`ai-native-rag`)" placed AFTER the
existing `J8-RULE-003` H4 and BEFORE the "Refusal semantics" H3. No new
H2 section is created (collision avoidance with `b7-pythia` — see
ADR-B7-9-004).

#### FR-B7-9-002 — `J8-RULE-004` (Vertex AI default refusal)

H4 sub-heading `#### J8-RULE-004 — Vertex AI refused as default LLM
provider (ai-native-rag)`. Cites : CLOUD Act (GCP-managed inference) ;
`compliance-tiers.md` §10.2 rows `AWS / GCP / Azure` (`CLOUD Act force
max T1`) + `LLM Gateway (OpenAI/Anthropic)` ; `global/llm-gateway.md`.
Alternative : Mistral-EU (Mistral on Scaleway) or self-hosted vLLM, or
OpenAI/Anthropic-via-EU-gateway at T1 (`⚠️ T1 max`).

#### FR-B7-9-003 — `J8-RULE-005` (AWS Bedrock default refusal)

H4 sub-heading `#### J8-RULE-005 — AWS Bedrock refused as default LLM
provider (ai-native-rag)`. Same rationale family (CLOUD Act, AWS-managed
inference) + same matrix rows + same alternative as FR-B7-9-002.

#### FR-B7-9-004 — `J8-RULE-006` (T3 US-managed inference refusal)

H4 sub-heading `#### J8-RULE-006 — \`--eu-tier T3\` ⇒ Mistral-EU / vLLM
self-host (US-managed inference refused)`. At T3, any US-managed
inference endpoint (Vertex / Bedrock / OpenAI-direct / Anthropic-direct
without an EU-jurisdiction gateway) is refused. Cites `compliance-tiers.md`
§10.2 forcing note `Pour T3 : Mistral on Scaleway ou vLLM self-host`.
Mirrors the `J8-RULE-002` / `J8-RULE-003` T3-enforcement shape.

#### FR-B7-9-005 — Rule body shape parity

Each new rule carries the same four sub-bullets as `J8-RULE-001..003` :
**Rationale**, **Reference** (ADR / standard / matrix row), **Alternative**
(actionable next step — mandatory per `janus-orchestration-rules.md`),
and the tier applicability (`J8-RULE-004/005` = default-refusal any tier ;
`J8-RULE-006` = T3 only).

#### FR-B7-9-006 — Audit anchor

The new H3 sub-section carries
`<!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) -->` so the J.8.c deltas are
traceable separately from the J.8.a `<!-- Audit: J.8 -->` anchor.

---

### Cluster 2 — `forbidden_combinations:` registry

#### FR-B7-9-020 — New top-level list

`.forge/scaffolding/dispatch-table.yml` gains a NEW top-level
`forbidden_combinations:` list, sibling to `forbidden_archetypes:`. The
key name matches the one foreseen in
`janus-orchestration-rules.md` "Extending the catalogue" step 1.

#### FR-B7-9-021 — Entry shape

Each entry has 7 keys : `archetype`, `provider`, `tier`, `reason`,
`since`, `alternative`, `rule_id`. `tier: any` marks a default-refusal
that fires regardless of declared tier ; `tier: T3` marks a
tier-conditional refusal. (Superset of the `forbidden_archetypes:`
5-key shape, adding `archetype` + `provider` + replacing implicit-all
with explicit `tier`.)

#### FR-B7-9-022 — Seed entries

Three seed entries :
- `archetype: ai-native-rag` / `provider: vertex-ai` / `tier: any` /
  `rule_id: J8-RULE-004`.
- `archetype: ai-native-rag` / `provider: bedrock` / `tier: any` /
  `rule_id: J8-RULE-005`.
- `archetype: ai-native-rag` / `provider: us-managed-inference` /
  `tier: T3` / `rule_id: J8-RULE-006`.
`since: "0.5.0"` on each (the ai-native-rag MINOR per VERSIONING.md /
ADR-B7-2A-004 ; confirmed Q-002).

#### FR-B7-9-023 — Header documentation block

A YAML comment block above `forbidden_combinations:` documents its
consumers (the new helper + the CLI dispatcher if extended), the
refusal exit code (3), and the `[REFUSAL:]` format — mirroring the
existing `forbidden_archetypes:` header block.

---

### Cluster 3 — Combination-refusal wrapper helper

#### FR-B7-9-040 — New helper function

`bin/_forge-init-helpers.sh` gains
`_refuse_if_forbidden_combination "<archetype>" "<provider>"`. The
existing `_refuse_if_forbidden` (FR-J8-022) is NOT modified — the new
function is additive and shares the same forge-root discovery + PyYAML
inline parse pattern (ADR-J8-005).

#### FR-B7-9-041 — Tier resolution

The helper resolves the declared tier from `$FORGE_EU_TIER`, falling
back to the `.forge/.forge-tier` ledger first line (J.8 ADR-J8-006),
else empty. Empty tier ⇒ only `tier: any` entries can match (the T3
rule does not fire without a declared tier — Article III.4, no guessed
default, mirroring `T3-RULE-007` / `constitution-linter.sh` tier
discovery).

#### FR-B7-9-042 — Match + refuse

For the given `<archetype>` + `<provider>`, the helper matches a
`forbidden_combinations:` entry when `archetype` matches AND `provider`
matches AND (`tier: any` OR `tier` equals the resolved tier). On match
it emits the structured `[REFUSAL: …]` line to stderr and exits **3**
(ADR-J8-003 reused).

#### FR-B7-9-043 — Refusal stderr format

Single-line, machine-parseable, mirroring FR-J8-021 with the provider
added :
```
[REFUSAL: <archetype>/<provider>@<tier>: <rule_id>: <reason> ; alternative: <alternative>]
```

#### FR-B7-9-044 — Fail-open on unreachable table

If `dispatch-table.yml` is unreachable (no forge root found), the
helper returns 0 (fail-open — the CLI dispatcher is the canonical
refusal point ; the helper is best-effort defense in depth, verbatim
`_refuse_if_forbidden` behaviour, lines 43-48).

#### FR-B7-9-045 — Wrapper sources + invokes the helper

`bin/forge-init-ai-native-rag.sh` sources `_forge-init-helpers.sh` and
invokes `_refuse_if_forbidden_combination "ai-native-rag"
"<configured-provider>"` for its scaffold's LLM-gateway provider, as a
defense-in-depth check (the wrapper is still gated exit-3-while-candidate
per ADR-B7-2-001 ; the combination check is positioned so it fires when
the archetype promotes). The existing
`_refuse_if_forbidden "ai-native-rag"` call (if present) is left intact.

---

### Cluster 4 — Standards updates

#### FR-B7-9-060 — `janus-orchestration-rules.md` catalogue rows

The rule-catalogue table gains three rows for `J8-RULE-004` /
`J8-RULE-005` / `J8-RULE-006` (Trigger / Refusal target / Reference
columns) consistent with the existing `J8-RULE-001..003` rows.

#### FR-B7-9-061 — `janus-orchestration-rules.md` prose update

The "Extending the catalogue" step 1 prose is updated from "or to a
sibling `forbidden_combinations:` list **when the future J.8 extension
lands**" to record that the sibling list **now exists** (this change
landed it). The "Refusal vs warning semantics" section notes
`J8-RULE-004..006` are refusals (`J8-RULE-004/005` default-provider any
tier ; `J8-RULE-006` T3). The standard `version:` is bumped per SemVer
(minor — additive rules) with a `REVIEW.md` entry.

#### FR-B7-9-062 — `compliance-tiers.md::forbidden:` token additions

`global/compliance-tiers.md` frontmatter `forbidden:` (currently `[]`)
gains the LLM-provider tokens (`vertex-ai`, `bedrock`) so the generic
I.3 T3-forbidden linter (`T3-RULE-005`, review-time) catches them in
working-tree manifests — complementary to the scaffold-time Janus
refusal. SemVer minor bump + `REVIEW.md` entry. **Gated on Q-003** (the
I.3-coupling scope) ; if deferred, this FR moves to a follow-up change.

#### FR-B7-9-063 — `constitution-linter.sh` REMEDIATION entries

`constitution-linter.sh::ADR-I3-001` `REMEDIATION` map gains entries for
the new tokens (`vertex-ai` → "replace with Mistral-EU (Mistral on
Scaleway) or self-hosted vLLM ; OpenAI/Anthropic-via-EU-gateway at T1
only" ; `bedrock` → same). Same Q-003 gate as FR-B7-9-062.

#### FR-B7-9-064 — `forbidden-components-rules.md` interim-gap note

`global/forbidden-components-rules.md` §"Persistence
`forbidden_for_eu_strict:` gap (interim)" pattern is extended with an
analogous note for LLM providers documenting the `compliance-tiers.md::
forbidden:` token approach + the `J8-RULE-004..006` scaffold-time
cross-reference. Same Q-003 gate.

---

### Cluster 5 — Test harness

#### FR-B7-9-080 — Harness exists

`.forge/scripts/tests/b7-9.test.sh` mirrors `j8.test.sh` + `i3.test.sh`
layout (`--level` parse, `_helpers.sh` source, MANIFEST block,
`_not_implemented` RED stub, PASS/FAIL counters).

#### FR-B7-9-081 — L1 grep coverage

L1 hermetic grep tests assert : new `J8-RULE-004/005/006` anchors in the
agent file ; the new H3 sub-section + audit anchor ;
`forbidden_combinations:` top-level key + 7-key entry shape + three seed
`rule_id`s in `dispatch-table.yml` ;
`_refuse_if_forbidden_combination` function in the helper ; wrapper
sources + invokes it ; `[REFUSAL:` format in the helper ; the three new
catalogue rows in `janus-orchestration-rules.md` ; (Q-003-gated) the new
tokens in `compliance-tiers.md::forbidden:` + the `REMEDIATION` map.

#### FR-B7-9-082 — L2 fixture coverage

Two L2 fixtures :
- **refuse** : synthetic target tree with `.forge/.forge-tier`=`T3` +
  invoking the wrapper/helper with a `us-managed-inference` (or
  `vertex-ai`) provider → asserts exit 3 + a `[REFUSAL:` line carrying
  the correct `J8-RULE-NNN`.
- **tier-scaled** : `.forge/.forge-tier`=`T1` + OpenAI-via-gateway
  provider → asserts NO refusal (only the default-provider Vertex/Bedrock
  rules would refuse ; the T3 rule does not fire at T1). Mirrors
  `i3.test.sh::_test_i3_l2_t1_warn_only`.

#### FR-B7-9-083 — CI registration

`b7-9.test.sh --level 1,2` is appended to the `harnesses=( … )` array in
`.github/workflows/forge-ci.yml`, after the existing `b7-2.test.sh` entry.

---

### Cluster 6 — Documentation

#### FR-B7-9-100 — `docs/ARCHETYPES.md`

The `ai-native-rag` archetype doc (or the J.8 "Forbidden combinations"
section) gains an "LLM-provider refusals" note enumerating
`J8-RULE-004..006` + the Mistral-EU / vLLM alternative.

#### FR-B7-9-101 — `CHANGELOG.md`

Entry under `## [Unreleased]` summarising the J.8.c sub-module (new
Janus rules `J8-RULE-004..006` for `ai-native-rag` LLM providers).

---

## Non-Functional Requirements

### NFR-B7-9-001 — Additive only

No existing `J8-RULE-NNN` renumbered or removed ; `_refuse_if_forbidden`
unchanged ; the `ai-native-rag` schema / templates / scaffolder backbone
untouched. Existing-file edits confined to : the agent file (new H3
sub-section), dispatch-table (new top-level list), the helper (new
function), the wrapper (source + one call), two standards + the linter
token map (Q-003-gated), CI matrix, CHANGELOG, ARCHETYPES.md, and the
consolidated-spec append.

### NFR-B7-9-002 — No regression

`verify.sh` / `constitution-linter.sh` / `validate-standards-yaml.sh` /
`j7` / `j8.test.sh` / `i3.test.sh` / `b5` / `b7-1` / `b7-2a` / `b7-2` /
`b7-3` GREEN after the change. The candidate `ai-native-rag` keeps
refusing `forge init` with exit 3 (no behaviour change for a fresh init —
the combination check is dormant until promotion + a real provider config).

### NFR-B7-9-003 — Rule-ID numbering invariant

`J8-RULE-004..006` allocated sequentially after the live `J8-RULE-003` ;
IDs never reused (ADR-J8-004). A grep asserting `J8-RULE-004` is the
next free ID guards against collision with any concurrently-landed J.8
rule.

### NFR-B7-9-004 — Pattern alignment

The new helper follows the `_refuse_if_forbidden` bash + PyYAML inline
pattern verbatim (ADR-J8-005). Harness layout mirrors `j8.test.sh` /
`i3.test.sh`. No new external dependency (NFR-J8-005 preserved — PyYAML
already required).

### NFR-B7-9-005 — Tier-scaled severity coherence

The scaffold-time refusal (Janus, exit 3, blocking, T3 + default-provider)
and the review-time linter finding (I.3 `T3-RULE-005`, WARN at T1/T2,
FAIL at T3) MUST quote the same `compliance-tiers.md` §10.2 gradient —
the two surfaces never contradict (NFR-I3-T3F-001-style coherence with
the J.8 / Demeter surfaces).

### NFR-B7-9-006 — Article V audit trail

Every task tagged `[Story: FR-B7-9-XXX]` ; refusal stderr lines carry
`J8-RULE-NNN` IDs (ADR-J8-004) ; the J.8.c spec block is APPENDED to
`.forge/specs/janus-rules.md` at archive (no overwrite of the J.8.a/b/d
blocks).

---

## BDD Scenarios (Article II)

```gherkin
Feature: Janus refuses non-sovereign LLM providers for ai-native-rag (J.8.c)

  Scenario: Vertex AI refused as default LLM provider
    Given an ai-native-rag scaffold configured with Vertex AI as the default LLM provider
    When the forge-init-ai-native-rag.sh wrapper runs the combination check
    Then it exits 3
    And stderr carries "[REFUSAL: ai-native-rag/vertex-ai@..." with rule_id J8-RULE-004
    And the message names the Mistral-EU / vLLM alternative

  Scenario: AWS Bedrock refused as default LLM provider
    Given an ai-native-rag scaffold configured with AWS Bedrock as the default LLM provider
    When the wrapper runs the combination check
    Then it exits 3
    And stderr carries rule_id J8-RULE-005

  Scenario: T3 refuses US-managed inference
    Given .forge/.forge-tier declares T3
    And the scaffold points the LLM gateway at a US-managed inference endpoint
    When the wrapper runs the combination check
    Then it exits 3 with rule_id J8-RULE-006
    And the message forces Mistral-EU (Mistral on Scaleway) or self-hosted vLLM

  Scenario: T1 OpenAI-via-gateway is not refused
    Given .forge/.forge-tier declares T1
    And the scaffold points the LLM gateway at OpenAI via an EU-jurisdiction gateway
    When the wrapper runs the combination check
    Then no refusal fires
    And the exit code is 0
```

---

## ADRs (b7-9-janus-ai design)

| ID          | Decision                                                                                                                                                                          |
|-------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ADR-B7-9-001 | Reuse the `J8-RULE-NNN` namespace (ADR-J8-004) — J.8.c is a J.8 extension, not a new audit module. Allocate the next free block `J8-RULE-004..006` ; never reuse IDs.            |
| ADR-B7-9-002 | New `forbidden_combinations:` sibling registry (NOT a `forbidden_archetypes:` extension) — the refusals are provider×tier combinations, not whole-archetype refusals. Pre-foreseen by `janus-orchestration-rules.md` "Extending the catalogue" step 1. |
| ADR-B7-9-003 | New additive `_refuse_if_forbidden_combination` helper (NOT a modification of `_refuse_if_forbidden`) — the existing helper's archetype-only contract is preserved. Same bash + PyYAML pattern (ADR-J8-005), exit 3 (ADR-J8-003). |
| ADR-B7-9-004 | Collision avoidance with `b7-pythia` : all J.8.c deltas to `cross-layer-orchestrator.md` land INSIDE the existing "Forbidden archetypes & combinations" H2 (new H3 sub-section) ; Pythia edits the "Dispatch Table" rows. Distinct sections, no merge conflict. |
| ADR-B7-9-005 | Two complementary enforcement surfaces : scaffold-time Janus refusal (exit 3, blocking) + review-time I.3 linter finding (`T3-RULE-005`, tier-scaled WARN/FAIL). Both quote `compliance-tiers.md` §10.2 ; the I.3 coupling is Q-003-gated (may ship as a follow-up). |
| ADR-B7-9-006 | Mistral-EU (Mistral on Scaleway) + self-hosted vLLM are the sanctioned EU alternatives — VERIFIED verbatim against `compliance-tiers.md` §10.2 `LLM Gateway` row forcing note ; no provider specifics fabricated (Article III.4). |

Full design rationale + collision analysis + Open Questions resolution :
`.forge/changes/b7-9-janus-ai/design.md`.
