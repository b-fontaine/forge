# Specifications: i3-t3-forbidden-linter
<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-I3-T3F-*` / `NFR-I3-T3F-*`. **Constitution** :
v1.1.0. Pas d'amendement requis (I.3 introduces a new linter
rule + sibling standard ; existing articles unchanged).

## Source Documents

| Field             | Value                                                                                                                                                                                |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Audit base**    | `I.3` (`new-archetypes-plan` §7.1 lines 727-731 ; §10 timeline T5)                                                                                                                    |
| **ADR base**      | `t4-adr-ratification` archived 2026-05-04 (frontmatter contract) ; `j8-janus-rules` archived 2026-05-10 (ADR-J8-004 rule-ID format ; ADR-J8-006 plain-text ledger) ; `i2-compliance-tiers` archived 2026-05-12 (`linter_rule: t3-forbidden-components` forward-pointer) ; `k3-demeter` archived 2026-05-12 (K3-RULE-NNN precedent) ; `f4-linter-extension` archived 2026-05-01 (FORGE_LINTER_SKIP_* + warn helper) |
| **Plan ref**      | `docs/new-archetypes-plan.md` §7.1 row I.3 + §10 T5                                                                                                                                   |
| **Roadmap ref**   | `.forge/product/roadmap.md` T5 row ("I.3 T3-forbidden linter rule — Pending T5")                                                                                                       |
| **Schema reuse** | `.forge/schemas/compliance-tier.schema.json` v1.0.0 (T.4 — enum `[T1, T2, T3]`)                                                                                                       |
| **Pattern reuse** | `constitution-linter.sh::ADR-006 (State Management Discipline — no-state-management-alternatives)` section already shipped by T.4 — the new generic section **supersets** that block without breaking it |
| **Standard refs** | `identity.yaml` (`forbidden: [firebase-auth, auth0-saas-us]`) ; `observability.yaml` (`forbidden: [datadog]`) ; `orchestration.yaml` (`forbidden: [inngest]`) ; `state-management.yaml` (`forbidden: [riverpod, ...]`) ; `transport.yaml` (`forbidden: []`) ; `persistence.yaml` (`forbidden: []` + `forbidden_for_eu_strict: [...]` deferred per Q-002) ; `global/compliance-tiers.md` v1.0.0 (`linter_rule: t3-forbidden-components` forward-pointer, frontmatter `forbidden: []`) |
| **Constitution**  | Article XII §enforce (programmatic enforcement of constitutional boundaries) ; Article III.4 (no guessing — `T3-RULE-007` ambiguity warning) ; Article V.1 (rule IDs are audit-trail glue, machine-parseable) |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Constitution-linter section (FR-I3-T3F-001 → 008)

##### FR-I3-T3F-001 — Section anchor

`.forge/scripts/constitution-linter.sh` MUST gain a new section
delimited by the comment header
`# ── ADR-I3-001: T3-Forbidden Components — generic forbidden discovery ──`
and announced by an `echo` line
`"T3-Forbidden Components (I.3 — generic forbidden enforcement):"`.
The section MUST be placed **after** the existing ADR-006
state-management section (lines 665-730 in v0.3.0) and **before**
the Article III.4 NEEDS CLARIFICATION section.

##### FR-I3-T3F-002 — Opt-out env var

The section MUST honour the env var
`FORGE_LINTER_SKIP_T3_FORBIDDEN`. When set to `1` the section
emits `not_applicable "  skipped via FORGE_LINTER_SKIP_T3_FORBIDDEN"`
and returns. Convention identical to `FORGE_LINTER_SKIP_V_1` /
`FORGE_LINTER_SKIP_X_3` / `FORGE_LINTER_SKIP_NSMA` (F.4).

##### FR-I3-T3F-003 — Tier discovery

The section MUST read the declared tier from :
1. `${FORGE_ROOT}/.forge/.forge-tier` plain-text ledger (J.8
   ADR-J8-006) — single line, value in `{T1, T2, T3}`,
   trailing newline.
2. Failing that, the `FORGE_EU_TIER` env var (when the J.8
   CLI plumbing exports it).
3. Failing both, emit
   `not_applicable "  no compliance tier declared (set .forge/.forge-tier or export FORGE_EU_TIER)"`
   and return. **No default tier is inferred** per
   Article III.4.

##### FR-I3-T3F-004 — Standards discovery

The section MUST discover, recursively under
`${FORGE_ROOT}/.forge/standards/`, every file matching
`**/*.yaml` OR `**/*.md` that declares a top-level
`forbidden:` block. The discovery MUST :
- Accept both YAML and MD-with-YAML-frontmatter shapes
  (the MD form mirrors `compliance-tiers.md` v1.0.0).
- Skip any file declaring `forbidden: []` (empty list — no
  tokens to scan).
- Respect the `${FORGE_LINTER_SKIP_NSMA:-0}` env var by
  **excluding** `state-management.yaml` when the existing
  ADR-006 section is opted-out, preventing double-fire
  (NFR-I3-T3F-001).

##### FR-I3-T3F-005 — Forbidden-token parsing

For each discovered standard, the section MUST parse the
`forbidden:` block into a flat list of string tokens. The
parser MUST handle :
- YAML list-of-strings : `forbidden: [tokenA, tokenB]`.
- YAML block-list : `forbidden:\n  - tokenA\n  - tokenB`
  (with optional `# comment` trailing each token).
- Empty list : `forbidden: []` → 0 tokens (standard skipped).

##### FR-I3-T3F-006 — Severity scaling per tier

For each `(standard, token)` pair where the token is
detected in the working tree, the section MUST scale
severity by the declared tier per the gradient that
mirrors Demeter's FR-K3-DEM-068 :
- **T1** → `warn` (Informational ; documents residual
  CLOUD Act / posture risk acknowledged at T1).
- **T2** → `warn` (High Phase A — Q-001 Option A ; will
  flip to `fail` at B.8 / T6 per the
  `state-management.yaml::ci_blocking` Phase A → B pattern).
- **T3** → `fail` (Critical ; T3 declares "100% EU
  jurisdiction" — forbidden component is a hard refusal).

##### FR-I3-T3F-007 — Violation message format

Each violation MUST emit a line in the format :
```
[REFUSAL: T3-RULE-NNN: <token> forbidden at <tier> (<standard>::forbidden) ; remediation: <one-line>]
```
where :
- `NNN` is the rule ID from the seed catalogue (Cluster 9).
- `<token>` is the literal forbidden token (verbatim from
  the standard's list).
- `<tier>` is `T1` / `T2` / `T3`.
- `<standard>` is the relative path under `.forge/standards/`
  (e.g. `identity.yaml`).
- `<one-line>` is a single-line remediation hint from
  the seed catalogue.

The format is identical in shape to the J.8 `[REFUSAL: ...]`
emission per ADR-J8-003 and to Demeter's K3-RULE-NNN
findings per FR-K3-DEM-005.

##### FR-I3-T3F-008 — Clean-tree outcome

When **zero** tokens match, the section MUST emit
`pass "  no forbidden components detected at <tier> across <N> standards / <M> scanned files"`
where `N` is the number of standards inspected and `M` is
the number of files scanned in the working tree.

---

#### Cluster 2 — Working-tree scan surface (FR-I3-T3F-020 → 026)

##### FR-I3-T3F-020 — Manifest scan

For each forbidden token, the section MUST scan, under
`${FORGE_ROOT}` (excluding `.forge/`, `.git/`, `node_modules/`,
`target/`, `build/`, `.dart_tool/`, `examples/`) :
- `pubspec.yaml` files — token match against the
  `dependencies:` and `dev_dependencies:` keys.
- `package.json` files — token match against
  `dependencies` / `devDependencies` JSON map keys.
- `Cargo.toml` files — token match against
  `[dependencies]` and `[dev-dependencies]` keys.
- `requirements.txt` files — token match against
  per-line package names (PEP 508 prefix).
- `go.mod` files — token match against `require` block.

Manifest matches use **exact key match** (no substring) to
avoid false positives.

##### FR-I3-T3F-021 — Doc-body scan

For each forbidden token, the section MUST scan
`docs/**/*.md` AND `.forge/changes/**/*.md` (excluding
`.forge/changes/i3-t3-forbidden-linter/` — the change
authoring this rule legitimately mentions the tokens in
its body as documentation, NFR-I3-T3F-006).

Doc-body matches use **whole-word boundary matching**
(`grep -wE`) to avoid substring false positives (e.g.
`inngest` would otherwise match "inngest-like" in a
narrative paragraph).

##### FR-I3-T3F-022 — Self-exclusion of the I.3 change

The linter MUST exclude `.forge/changes/i3-t3-forbidden-linter/`
from the doc-body scan. Rationale : the change body
documents the forbidden tokens as part of the rule
catalogue ; treating them as violations would be a
self-referential false positive. The exclusion is
hard-coded by basename in the section.

##### FR-I3-T3F-023 — Standards self-scan

The linter MUST scan `.forge/standards/**/*.md`
(EXCLUDING the standard owning the `forbidden:` block
that declared the token, and EXCLUDING
`forbidden-components-rules.md` which catalogues the
tokens by design). Cross-references to forbidden tokens
in OTHER standards' `rationale:` blocks emit findings.

##### FR-I3-T3F-024 — Tokens as words

For each forbidden token, the section MUST normalise the
token to a literal grep pattern using `grep -wF`
(whole-word, fixed-string, no regex interpretation).
Tokens containing hyphens (e.g. `firebase-auth`) require
`grep -E` with explicit boundary `(^|[^a-zA-Z0-9_-])` /
`($|[^a-zA-Z0-9_-])` because `\b` does not respect hyphens.

##### FR-I3-T3F-025 — Performance budget

The full T3-forbidden section MUST complete in ≤ 3 s on
the Forge repository (≈ 6 standards × ≈ 8 tokens
average × ≈ 50 manifest + 100 doc files = ≈ 24k grep
invocations worst case ; realised < 3 s by batching grep
per token across pre-aggregated file lists).

##### FR-I3-T3F-026 — Examples subtree exclusion

When the framework signature is detected (existing
`FORGE_REPO_DETECTED=1` guard in `constitution-linter.sh`),
the section MUST exclude `${FORGE_ROOT}/examples/` from
its tree walks (each example tree owns its own linter
invocation per FR-GL-027).

---

#### Cluster 3 — Rule-catalogue standard (FR-I3-T3F-040 → 046)

##### FR-I3-T3F-040 — Standard file location

`.forge/standards/global/forbidden-components-rules.md` MUST
exist as a new MD standard sibling to
`janus-orchestration-rules.md` (J.8) and
`data-stewardship-rules.md` (K.3). Plain MD with YAML
frontmatter (mirrors `compliance-tiers.md` shape).

##### FR-I3-T3F-041 — Frontmatter contract

The frontmatter MUST declare :
```yaml
version: 1.0.0
last_reviewed: 2026-05-12
expires_at: 2027-05-12
exception_constitutional: false
linter_rule: t3-forbidden-components
enforcement: ci
forbidden: []              # this standard CATALOGUES — does not declare
rationale: >-
  Codifies the T3-RULE-NNN catalogue enforced by
  constitution-linter.sh ADR-I3-001 section. Severity scales
  per tier per FR-I3-T3F-006.
```

##### FR-I3-T3F-042 — H2 sections

The standard MUST have ≥ 6 H2 sections :
- `## Purpose`
- `## Rule catalogue` (T3-RULE-001..007 table)
- `## Severity scaling` (tier matrix)
- `## Adoption path`
- `## Extending the catalogue`
- `## Opt-out env vars`

##### FR-I3-T3F-043 — Rule catalogue table

The `## Rule catalogue` H2 MUST contain a table enumerating
T3-RULE-001..007 with columns : `Rule ID`, `Token source`,
`Severity (T1/T2/T3)`, `Remediation`, `ADR / standard
cross-link`. Each rule row is greppable for its `T3-RULE-NNN`
ID.

##### FR-I3-T3F-044 — Standards index registration

`.forge/standards/index.yml` MUST gain a new entry :
```yaml
- id: global/forbidden-components-rules
  path: standards/global/forbidden-components-rules.md
  triggers: [forbidden, t3-forbidden, t3-rule, linter, t1, t2, t3, eu-tier, ci-enforcement, forbidden-components]
  scope: all
  priority: high
```

##### FR-I3-T3F-045 — REVIEW.md birth entry

`.forge/standards/REVIEW.md` MUST gain an append-only H2
entry dated 2026-05-12 titled
`## 2026-05-12 — Initial ratification (i3-t3-forbidden-linter)`
with Decision: KEEP and Next review due: 2027-05-12.

##### FR-I3-T3F-046 — compliance-tiers.md cross-link

`.forge/standards/global/compliance-tiers.md` MUST gain :
- Frontmatter flip `enforcement: review` → `enforcement: ci`
  per the existing "Status note" §line 20-26 prose.
- A new section / paragraph cross-linking
  `forbidden-components-rules.md` as the resolved rule
  catalogue (the existing `## Status note` paragraph is
  modified delta-per Article IV.1 — the "I.3 linter rule that
  has not shipped yet" wording is updated to "I.3 linter rule
  shipped 2026-05-12 via i3-t3-forbidden-linter").

---

#### Cluster 4 — Test harness `i3.test.sh` (FR-I3-T3F-060 → 062)

##### FR-I3-T3F-060 — Harness exists

`.forge/scripts/tests/i3.test.sh` MUST exist mirroring the
J.7 / J.8 / K.3 / I.2 layout : bash header, `_helpers.sh`
source, PASS/FAIL counters, `--level 1,2` parsing,
`print_summary` close-out.

##### FR-I3-T3F-061 — L1 coverage ≥ 14 tests

Minimum 14 L1 tests covering :
- 2 linter section anchor (`# ── ADR-I3-001` comment +
  `echo "T3-Forbidden Components"` line).
- 1 opt-out env var (`FORGE_LINTER_SKIP_T3_FORBIDDEN`
  honoured — section emits N/A when set).
- 2 tier discovery (`.forge/.forge-tier` ledger + N/A
  when absent).
- 2 standards discovery (≥ 4 standards with `forbidden:`
  detected ; `forbidden: []` standards skipped).
- 1 violation format (`[REFUSAL: T3-RULE-NNN: ...]`
  emission shape).
- 1 standard file existence + frontmatter (
  `forbidden-components-rules.md` exists with required
  frontmatter keys).
- 2 standard H2 anchors (≥ 6 H2 sections + Rule
  catalogue table with T3-RULE-001..007 rows).
- 1 standards index entry (id `global/forbidden-components-rules`).
- 1 REVIEW.md entry (`Initial ratification (i3-t3-forbidden-linter)`).
- 1 compliance-tiers.md flip (`enforcement: ci` +
  delta paragraph mentions `i3-t3-forbidden-linter`).

##### FR-I3-T3F-062 — L2 coverage ≥ 4 fixture tests

Minimum 4 L2 fixtures :
- **L2-T3-pubspec-forbidden** : tmpdir with synthetic
  `pubspec.yaml` declaring `firebase_auth:` + `.forge/.forge-tier`
  set to `T3` ; assert constitution-linter exits 1 with
  `[REFUSAL: T3-RULE-001:` line in stderr/stdout.
- **L2-T3-cargo-forbidden** : tmpdir with synthetic
  `Cargo.toml` declaring `inngest` + `.forge/.forge-tier`
  set to `T3` ; assert exits 1 with
  `[REFUSAL: T3-RULE-003: inngest` line.
- **L2-T1-warn-only** : tmpdir with synthetic
  `pubspec.yaml` declaring `firebase_auth:` + `.forge/.forge-tier`
  set to `T1` ; assert exits 0 (WARN counted, FAIL = 0).
- **L2-no-tier-na** : tmpdir with no `.forge/.forge-tier`
  + no `FORGE_EU_TIER` env ; assert exits 0 with
  `N/A` line `no compliance tier declared`.

---

#### Cluster 5 — Documentation (FR-I3-T3F-080 → 084)

##### FR-I3-T3F-080 — `docs/LINTING.md` H2

`docs/LINTING.md` MUST gain a new H2 section
`## ADR-I3-001 — T3-Forbidden Components (I.3)` summarising :
- What the rule enforces.
- The 7-rule seed catalogue (cross-link to
  `forbidden-components-rules.md`).
- The `FORGE_LINTER_SKIP_T3_FORBIDDEN` opt-out.
- The severity scaling table (T1/T2/T3 → WARN/WARN/FAIL).
- The Article XII §enforce cross-reference.

##### FR-I3-T3F-081 — `CHANGELOG.md` entry

A new entry under `## [Unreleased]` summarising the linter
section + the new standard + CI registration.

##### FR-I3-T3F-082 — Audit cross-references

The new standard `forbidden-components-rules.md` footer
MUST cite the upstream sources :
- `docs/new-archetypes-plan.md` §7.1 row I.3.
- `.forge/standards/global/compliance-tiers.md` (sibling,
  shipped by I.2).
- `.forge/standards/global/janus-orchestration-rules.md`
  (sibling rule-catalogue pattern, J.8).
- `.forge/standards/global/data-stewardship-rules.md`
  (sibling rule-catalogue pattern, K.3).
- `.forge/scripts/constitution-linter.sh::ADR-I3-001`
  section anchor.

##### FR-I3-T3F-083 — `docs/new-archetypes-plan.md` row I.3

The row I.3 in `docs/new-archetypes-plan.md` §7.1 MUST be
updated with a "Done 2026-05-12 via i3-t3-forbidden-linter"
marker mirroring the I.2 row pattern.

##### FR-I3-T3F-084 — `.forge/product/roadmap.md` update

The roadmap T5 row MUST be updated to reflect I.3 as
"Done 2026-05-12 via i3-t3-forbidden-linter" (mirrors the
I.2 line pattern shipped by `i2-compliance-tiers`).

---

#### Cluster 6 — CI registration (FR-I3-T3F-100 → 101)

##### FR-I3-T3F-100 — `forge-ci.yml` harness entry

`.github/workflows/forge-ci.yml` MUST gain a new harness
matrix entry immediately after `i2.test.sh` :
```yaml
      - name: i3.test.sh
        run: bash .forge/scripts/tests/i3.test.sh --level 1,2
```
The two-line addition keeps the file ≤ 300 lines per
NFR-CI-002.

##### FR-I3-T3F-101 — Size budget preserved

`.github/workflows/forge-ci.yml` MUST remain ≤ 300 lines
after the addition. Pre-change baseline : 269 lines.
Post-change ceiling : 272 lines (2 added + 1
section-header comment optional).

---

#### Cluster 9 — Seed T3-RULE catalogue (FR-I3-T3F-120 → 126)

The 7 seed rules ship under T3-RULE-001..007 per
ADR-I3-002 (design phase, resolves Q-003 — 7 rules covering
the 4 EU-strict surfaces today + 3 operational guardrails).

##### FR-I3-T3F-120 — T3-RULE-001 — Identity forbidden token

**Trigger** : a token in `identity.yaml::forbidden:` (e.g.
`firebase-auth`, `auth0-saas-us`) detected in a working-tree
manifest or doc body. **Severity** : tier-scaled per
FR-I3-T3F-006. **Remediation** : replace with `zitadel`
(default per `identity.yaml::default:`) OR downgrade
declared tier.

##### FR-I3-T3F-121 — T3-RULE-002 — Observability forbidden token

**Trigger** : a token in `observability.yaml::forbidden:`
(e.g. `datadog`) detected. **Severity** : tier-scaled.
**Remediation** : replace with `signoz` (default per
`observability.yaml::backend:`) OR downgrade tier.

##### FR-I3-T3F-122 — T3-RULE-003 — Orchestration forbidden token

**Trigger** : a token in `orchestration.yaml::forbidden:`
(e.g. `inngest`) detected. **Severity** : tier-scaled.
**Remediation** : replace with `dbos` (default) OR
`temporal` (fallback) OR downgrade tier.

##### FR-I3-T3F-123 — T3-RULE-004 — State management forbidden token

**Trigger** : a token in
`state-management.yaml::forbidden:` (e.g. `riverpod`,
`provider`, `getx`, `mobx`) detected. **Severity** :
tier-scaled, BUT honours the existing
`FORGE_LINTER_SKIP_NSMA` env var (the ADR-006 section
already enforces this at warn-only Phase A ; I.3 generic
section defers to ADR-006 when NSMA opt-out is OFF to
avoid double-fire). **Remediation** : adopt `flutter_bloc`
(ADR-006 default) OR Article XII amendment.

##### FR-I3-T3F-124 — T3-RULE-005 — Compliance-tier matrix forbidden token

**Trigger** : a token detected in the working tree that
matches a `❌`-flagged row of the §10.2 matrix in
`global/compliance-tiers.md` at the declared tier (e.g.
`firebase` at T2/T3, `datadog` at any tier, `aws-sdk`
at T2/T3). This rule reads the matrix narratively (no YAML
list — the matrix lives in MD table rows). **Severity** :
tier-scaled. **Remediation** : replace with the matrix's
T3 equivalent OR downgrade tier.

This is a **deliberately narrow** matrix-row enforcement —
the I.3 scope is bounded by the **literal** matrix rows
that intersect declared-forbidden tokens, NOT a full
re-parse of the MD matrix. Full matrix-row enforcement is
deferred to a future change (T6) to keep I.3 scoped.

In v1.0.0, T3-RULE-005 is implemented by **the same
generic forbidden-discovery** : `compliance-tiers.md`
declares `forbidden: []` in its frontmatter (per its v1.0.0
ship) — when adopters extend the frontmatter to declare
matrix-row tokens (e.g.
`forbidden: [firebase, aws-managed]`), the generic linter
picks them up. The standard's section "Extending the
matrix" documents the convention.

##### FR-I3-T3F-125 — T3-RULE-006 — Cross-standard forbidden mention

**Trigger** : a forbidden token from ANY discovered
standard's `forbidden:` block detected in ANOTHER
standard's body (the standards corpus is the
canonical-reference layer ; mentioning a forbidden token
in another standard's `rationale:` block creates an
authoritativeness conflict). **Severity** : tier-scaled,
but capped at `warn` (Informational) at all tiers — this
rule documents intra-standards drift, not deployment risk.
**Remediation** : refactor the cross-reference to cite the
standard ID instead of the token, OR remove the mention.

##### FR-I3-T3F-126 — T3-RULE-007 — Tier ledger absent / ambiguous

**Trigger** : the linter runs but `.forge/.forge-tier` is
absent AND `FORGE_EU_TIER` env var is unset. **Severity** :
N/A (the section emits `not_applicable` and skips ;
NOT a violation — Article III.4 forbids guessing a default
tier). **Remediation** : declare a tier via the ledger or
the env var.

Per FR-I3-T3F-007 the rule ID is still emitted in the N/A
message so operators see the convention.

---

### Non-Functional Requirements

#### NFR-I3-T3F-001 — NSMA section interlock

The new generic T3-forbidden section MUST NOT double-fire
with the existing
`ADR-006 (State Management Discipline — no-state-management-alternatives)`
section already in `constitution-linter.sh`. The interlock
is :
- When `FORGE_LINTER_SKIP_NSMA` is unset (default), the
  ADR-006 section enforces `state-management.yaml` and the
  generic section EXCLUDES `state-management.yaml` from
  its standards walk (avoiding duplicate findings).
- When `FORGE_LINTER_SKIP_NSMA=1`, the ADR-006 section is
  skipped AND the generic section ALSO excludes
  `state-management.yaml` (the opt-out applies to both).
- When `FORGE_LINTER_SKIP_T3_FORBIDDEN=1`, only the
  generic section is skipped ; ADR-006 still fires.

#### NFR-I3-T3F-002 — Backward compatibility

Adopters not declaring a tier observe ZERO behavioural
change. The section emits `not_applicable` and increments
the `NA` counter only.

#### NFR-I3-T3F-003 — Article V audit trail

Every task tagged `[Story: FR-I3-T3F-XXX]`. Every
violation carries `T3-RULE-NNN` + standard reference +
remediation, machine-parseable per Article V.1.

#### NFR-I3-T3F-004 — F.4 pattern alignment

The new section follows the existing
`constitution-linter.sh` `FORGE_LINTER_SKIP_*` env-var
convention shipped by `f4-linter-extension` :
- Opt-out env var named consistent with siblings.
- `not_applicable "  skipped via FORGE_LINTER_SKIP_T3_FORBIDDEN"`
  format byte-identical to F.4.
- `pass` / `fail` / `warn` / `not_applicable` helpers
  reused verbatim.

#### NFR-I3-T3F-005 — Determinism

Two consecutive linter runs against the same target tree
MUST produce identical violation lines (sorted by
`(standard, rule_id, token, location)` lexicographic key).
Reproducible-build convention preserved.

#### NFR-I3-T3F-006 — Self-exclusion

`.forge/changes/i3-t3-forbidden-linter/**` MUST be
excluded from the doc-body scan to avoid self-referential
false positives (the change body legitimately enumerates
forbidden tokens in its `specs.md` BDD scenarios).

#### NFR-I3-T3F-007 — Whole-word matching

Doc-body token matching uses whole-word boundary regex
(`(^|[^a-zA-Z0-9_-])<token>($|[^a-zA-Z0-9_-])`) to avoid
substring false positives. Manifest matches use exact-key
match per ecosystem grammar.

#### NFR-I3-T3F-008 — Performance budget

Full linter run (with the new section) MUST complete in
≤ 5 s on the Forge repository (existing perf budget per
`f4-linter-extension` is 3 s ; new section adds ≤ 2 s
headroom).

#### NFR-I3-T3F-009 — CI size budget

`.github/workflows/forge-ci.yml` MUST remain ≤ 300 lines
after the harness entry addition (NFR-CI-002 from G.1).

---

## BDD Acceptance Criteria

### Scenario 1 — T3 + forbidden in pubspec → FAIL

```gherkin
Given an adopter has declared compliance_tier T3 via .forge/.forge-tier
And the project's pubspec.yaml declares dependency "firebase_auth: ^1.0.0"
And identity.yaml declares forbidden: [firebase-auth]
When bash .forge/scripts/constitution-linter.sh runs
Then exit code is 1
And output contains "[REFUSAL: T3-RULE-001: firebase-auth forbidden at T3 (identity.yaml::forbidden) ; remediation: replace with Zitadel or downgrade tier]"
And the OVERALL line reads "FAIL"
```

### Scenario 2 — T1 + forbidden → WARN only

```gherkin
Given an adopter has declared compliance_tier T1 via .forge/.forge-tier
And the project's package.json declares "datadog-browser-rum"
And observability.yaml declares forbidden: [datadog]
When bash .forge/scripts/constitution-linter.sh runs
Then exit code is 0
And output contains "WARN  T3-RULE-002: datadog forbidden at T1"
And the OVERALL line reads "PASS"
```

### Scenario 3 — Tier ledger absent → N/A

```gherkin
Given the project has no .forge/.forge-tier file
And no FORGE_EU_TIER environment variable is set
When bash .forge/scripts/constitution-linter.sh runs
Then exit code is 0
And output contains "N/A   no compliance tier declared"
And the OVERALL line reads "PASS"
```

### Scenario 4 — Opt-out env var skips the section

```gherkin
Given FORGE_LINTER_SKIP_T3_FORBIDDEN=1 is set
And the project declares compliance_tier T3
And the project has a forbidden token in its tree
When bash .forge/scripts/constitution-linter.sh runs
Then the T3-Forbidden section emits "N/A   skipped via FORGE_LINTER_SKIP_T3_FORBIDDEN"
And no T3-RULE-NNN violations are emitted
```

---

## Anti-Hallucination Pass

For each FR :

- **Testable** : every FR is asserted by at least one test
  in `i3.test.sh` (mapping captured in `tasks.md`
  `[Story: FR-I3-T3F-XXX]` tags during `/forge:plan`).
- **Unambiguous** : 3 ambiguities flagged in proposal, all
  resolvable at design time :
  - Q-001 — T2 severity : `warn` Phase A mirrors
    `state-management.yaml::ci_blocking: false` until
    B.8 / T6 ; documented in ADR-I3-003.
  - Q-002 — `forbidden_for_eu_strict:` block in
    `persistence.yaml` deferred to T6 standards refactor ;
    documented in ADR-I3-004.
  - Q-003 — 7 seed rules (5 from existing standards +
    matrix-row hook + tier-ledger guardrail) ; documented
    in ADR-I3-002.
- **Constitution-compliant** : Articles I (TDD), II (BDD),
  III + III.4 (specs first + ambiguity protocol), IV
  (delta — `compliance-tiers.md` Status note paragraph
  modified per Article IV.1), V (audit trail), XI
  (AI-First — deterministic, schema-driven), XII
  (governance — EXECUTES §enforce for the first time on
  generic `forbidden:` tokens).

---

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`specs.md`. Three open questions Q-001 + Q-002 + Q-003 raised
at the proposal phase, tracked in `open-questions.md`,
slated for resolution during `/forge:design` via
ADR-I3-001..004.

## Counts

- **FR-I3-T3F-***: 32 (001-008 linter section, 020-026
  scan surface, 040-046 rule-catalogue standard, 060-062
  harness, 080-084 docs, 100-101 CI, 120-126 seed rules)
- **NFR-I3-T3F-***: 9 (001-009)
- **BDD Scenarios** : 4
- **Open Questions** : 3 (Q-001..Q-003, all status `open`)
