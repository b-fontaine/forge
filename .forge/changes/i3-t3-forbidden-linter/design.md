# Design: i3-t3-forbidden-linter
<!-- Status: designed -->
<!-- Schema: default -->

> Read alongside `specs.md` (FR-I3-T3F-* / NFR-I3-T3F-*) and
> `open-questions.md` (Q-001..Q-003). This document locks the
> implementation strategy and resolves Q-001 + Q-002 + Q-003
> via ADR-I3-001..004.

## Architecture Decisions

### ADR-I3-001 — Linter section placement : extension of `constitution-linter.sh`

**Context** : FR-I3-T3F-001 requires a new section in
`.forge/scripts/constitution-linter.sh`. Three placement
candidates were considered :

- **Option A** — extend `constitution-linter.sh` with a new
  section (same pattern as the existing ADR-006 NSMA section,
  which lives lines 665-730 in the current file).
- **Option B** — new standalone script
  `.forge/scripts/forbidden-linter.sh`, called from `verify.sh`.
- **Option C** — extend `bin/forge-demeter-scan.sh` (Demeter
  already enforces compliance posture at lockfile level).

**Decision** : **Option A — extend `constitution-linter.sh`**.

**Rationale** :
- The existing ADR-006 section already demonstrates the
  pattern : per-standard YAML walk + forbidden-list parse +
  tier-aware severity (warn-only Phase A → fail Phase B). The
  generic T3-forbidden section is a natural superset.
- `verify.sh` invokes `constitution-linter.sh` already (its
  output is folded into the OVERALL aggregate) ; new
  violations surface uniformly.
- NFR-CI-002 size budget — adding a 120-line section to a
  835-line linter keeps everything in one file vs. spawning a
  new top-level script which would need its own CI matrix
  entry (and consume part of the 300-line forge-ci.yml budget).
- Demeter (Option C) is a complementary surface : Demeter
  reads lockfiles for CLOUD Act jurisdiction at dependency
  level ; T3-forbidden reads manifests + doc bodies for
  architectural posture at component level. The two surfaces
  cross-validate but neither subsumes the other.

**Consequences** :
- ✅ Pattern parity with ADR-006 NSMA — reviewers learn one
  shape.
- ✅ Single CI entry for `constitution-linter.sh` already
  exists ; no new job needed (just a harness entry for
  `i3.test.sh` validating the section's behaviour).
- ⚠️ `constitution-linter.sh` grows from 835 → ≈ 960 LOC.
  Still well below any hard cap. If it crosses 1200 LOC
  later, a refactor into a `linter/sections/*.sh` modular
  layout is documented as a future option in `open-questions.md`
  (deferred Q-004).

**Constitution Compliance** : Article XII §enforce —
EXECUTED for the first time on generic `forbidden:` tokens.
No new constitutional article required.

---

### ADR-I3-002 — Seed rule catalogue : 7 rules T3-RULE-001..007 (resolves Q-003)

**Context** : Q-003 weighed pre-allocation (Option A — 10
rules) vs incremental (Option B — 5 rules now). ADR-J8-004
already locks the `<MODULE>-RULE-NNN` format ; ADR-K3-005
(K.3) chose Option B with 5 seed rules.

**Decision** : **Option B + 2 — 7 seed rules** :

- **T3-RULE-001** — Identity forbidden token (FR-I3-T3F-120).
  Token source : `identity.yaml::forbidden`.
- **T3-RULE-002** — Observability forbidden token
  (FR-I3-T3F-121). Token source : `observability.yaml::forbidden`.
- **T3-RULE-003** — Orchestration forbidden token
  (FR-I3-T3F-122). Token source : `orchestration.yaml::forbidden`.
- **T3-RULE-004** — State management forbidden token
  (FR-I3-T3F-123). Token source :
  `state-management.yaml::forbidden`. Interlocks with
  existing ADR-006 NSMA section per NFR-I3-T3F-001.
- **T3-RULE-005** — Compliance-tier matrix forbidden token
  (FR-I3-T3F-124). Token source : `compliance-tiers.md::forbidden`
  (when the v1.0.0 empty list is later extended to encode
  matrix-row tokens).
- **T3-RULE-006** — Cross-standard forbidden mention
  (FR-I3-T3F-125). Capped at WARN at all tiers (intra-standards
  drift, not deployment risk).
- **T3-RULE-007** — Tier ledger absent / ambiguous
  (FR-I3-T3F-126). Not a violation ; emits N/A.

**Rejected alternative** : Option A (pre-allocate 10) would
couple I.3 to scope explicitly excluded by the proposal (I.5 /
I.6) ; spec discipline preserved.

**Numbering invariant** : per ADR-J8-004 inheritance, IDs are
NEVER reused. If T3-RULE-008 is decommissioned in a future
change, the catalogue marks it `DEPRECATED` ; the slot is
not recycled.

**Future T3-RULE-008+** : 3 candidate rules deferred to
follow-up changes :
- T3-RULE-008 — Persistence `forbidden_for_eu_strict:` block
  enforcement (depends on Q-002 resolution = T6 refactor).
- T3-RULE-009 — Transport `forbidden:` enforcement
  (currently empty list ; structural exception per Article
  XII — will fire if list ever populated).
- T3-RULE-010 — Per-change override of the tier ledger
  (when a `.forge/changes/<name>/.forge.yaml` declares its
  own `compliance_tier: T3`, that wins over the root
  ledger). Documented as a forward-pointer to I.5 /
  forge-compliance.yml workflow.

**Consequences** :
- ✅ Each of the 4 existing standards with non-empty
  `forbidden:` lists gets a dedicated rule (1:1 mapping
  T3-RULE-001..004 ↔ identity/observability/orchestration/
  state-management).
- ✅ T3-RULE-005 reserves the matrix-row enforcement slot
  for compliance-tiers.md extension (future minor bump of
  the standard adds tokens ; no new rule ID needed).
- ✅ T3-RULE-006 catches cross-standards drift (a forbidden
  token cited in another standard's `rationale:` is an
  authoritativeness conflict).
- ✅ T3-RULE-007 documents the tier-discovery anti-hallucination
  surface explicitly (operators see the convention).

**Constitution Compliance** : Articles V (audit trail),
III.4 (anti-hallucination on tier discovery). No violation.

---

### ADR-I3-003 — Severity scaling : warn-only T1+T2 Phase A, fail-only T3 (resolves Q-001)

**Context** : Q-001 weighed two options for T2 severity :
- **Option A** — `warn` Phase A (mirror
  `state-management.yaml::ci_blocking: false` until B.8 / T6).
- **Option B** — `fail` from day 1 (block T2 immediately).

The Demeter precedent (FR-K3-DEM-068) scales severity by tier
per the gradient `T1 → Informational, T2 → High, T3 →
Critical`. Demeter findings emit at the corresponding severity
labels in its JSON report ; the report's overall_status is
`BLOCKED` only at High or Critical. So Demeter at T2 IS
already a hard block when severity scales naturally.

The linter is a different surface — it is invoked at every
local `verify.sh` run, every CI run, every PR. Blocking T2
adopters from day 1 risks adopter friction during the
graduated rollout (the same friction that motivated the
ADR-006 NSMA Phase A → B pattern).

**Decision** : **Option A — warn-only at T1 + T2 Phase A**,
**fail at T3** :

- **T1** → `warn` (Informational ; documents residual
  CLOUD Act / posture risk acknowledged at T1).
- **T2** → `warn` (Phase A — will flip to `fail` at B.8 /
  T6 per the `state-management.yaml::ci_blocking` Phase A → B
  pattern documented in
  `.forge/standards/global/standards-lifecycle.md`).
- **T3** → `fail` (Critical ; T3 declares 100% EU
  jurisdiction — forbidden component is a hard refusal).

The Phase A → B transition is captured in the new standard's
"Severity scaling" H2 with an explicit `activation_planned:
"B.8 (T6)"` marker mirroring the existing
`state-management.yaml::activation_planned` field. The flip
is a SemVer minor bump of the new standard
(`forbidden-components-rules.md` 1.0.0 → 1.1.0) ; no schema
break.

**Why the asymmetric T2 vs Demeter** : Demeter operates on
**dependency lockfiles** — a US-jurisdiction crate at T2 is a
deliberate vendor choice the adopter made. The linter
operates on **standards declarations** — a forbidden token
detected in a manifest typically means the adopter forgot to
audit, not a deliberate choice. Warn-first nudges remediation
without breaking builds during rollout.

**Rejected alternative** : Option B (fail T2 day 1) was
rejected for the rollout-friction reason. The flip to fail
is automatic at B.8 ; no follow-up change needed beyond the
1.0.0 → 1.1.0 standards bump.

**Encoded in** :
- `constitution-linter.sh::ADR-I3-001 section` — per-tier
  branch (T1/T2 → warn ; T3 → fail).
- `forbidden-components-rules.md::Severity scaling` — H2
  table.
- `i3.test.sh::_test_i3_l2_t1_warn_only` — L2 fixture.

**Consequences** :
- ✅ Adopter friction minimised during rollout.
- ✅ T3 enforcement is **immediate** (no graduated rollout
  — T3 declares "100% EU jurisdiction", forbidden component
  is by definition unacceptable).
- ⚠️ T2 adopters may slip forbidden tokens past CI until the
  flip. Mitigated by the `WARN` count in the OVERALL line
  being visible at every run + reviewer human-readable
  signal.

**Constitution Compliance** : Articles III.4 (graduated
rollout documented explicitly), V (audit trail via the
T3-RULE-* IDs).

---

### ADR-I3-004 — `persistence.yaml::forbidden_for_eu_strict:` deferred (resolves Q-002)

**Context** : Q-002 — should the linter ALSO read the
`forbidden_for_eu_strict:` block in `persistence.yaml`
(`dynamodb`, `firestore`, `cosmosdb`) ?

`persistence.yaml` is the **only** standard using the
`forbidden_for_eu_strict:` key shape (a T.4-era variant
predating the generic `forbidden:` convention). All other
standards use `forbidden:`.

**Decision** : **Defer — read only `forbidden:` in v1.0.0**.

**Rationale** :
- I.3 scope is bounded by the existing `forbidden:` convention.
- Normalising `forbidden_for_eu_strict:` → `forbidden:` is a
  standards-corpus refactor (touches the
  `persistence.yaml::forbidden_for_eu_strict:` semantics,
  potentially the YAML schema, downstream consumers). That
  refactor is documented as a future T6 standards-refactor
  change.
- The semantics of `forbidden_for_eu_strict:` ARE captured
  by the matrix-row mechanism (T3-RULE-005). When
  `compliance-tiers.md::forbidden:` is later extended to
  encode `[dynamodb, firestore, cosmosdb]`, the generic
  linter picks them up via T3-RULE-005.

**Rejected alternative** : read both `forbidden:` AND
`forbidden_for_eu_strict:` in v1.0.0. Rejected because :
- Doubles the parser surface.
- Couples I.3 to a standards-schema variant that may be
  removed.
- The standards-refactor work belongs to T6, not T5.

**Encoded in** :
- `proposal.md::Scope Out` — explicit out-of-scope.
- `forbidden-components-rules.md::Adoption path` — forward-
  pointer to the T6 refactor.

**Consequences** :
- ✅ I.3 scope preserved.
- ✅ No surprise behaviour for adopters who rely on the
  current `persistence.yaml::forbidden_for_eu_strict:` shape.
- ⚠️ Adopters who want immediate `dynamodb` enforcement at
  T3 can manually copy the tokens into a
  `compliance-tiers.md::forbidden:` extension until T6.
  Documented in the new standard's "Extending the catalogue"
  H2.

**Constitution Compliance** : Article IV.1 (delta-based —
no breaking change to `persistence.yaml`). No violation.

---

## Component Design

```mermaid
classDiagram
    class constitution_linter_sh {
        +existing sections preserved
        +ADR-I3-001 T3-Forbidden Components section
        -read_forge_tier()
        -discover_forbidden_standards()
        -parse_forbidden_block(standard_path)
        -scan_manifests(token)
        -scan_doc_bodies(token)
        -emit_violation(rule_id, token, tier, standard)
    }
    class compliance_tiers_md {
        +existing 7 H2 sections preserved
        +frontmatter enforcement: review→ci (delta)
        +Status note paragraph delta (Article IV.1)
    }
    class forbidden_components_rules_md {
        +Purpose
        +Rule catalogue (T3-RULE-001..007 table)
        +Severity scaling (T1/T2/T3 matrix)
        +Adoption path
        +Extending the catalogue
        +Opt-out env vars
    }
    class standards_index_yml {
        +new forbidden-components-rules entry
    }
    class review_md {
        +append-only birth entry 2026-05-12
    }
    class i3_test_sh {
        +L1 tests[14+]
        +L2 t3_pubspec_forbidden_fixture()
        +L2 t3_cargo_forbidden_fixture()
        +L2 t1_warn_only_fixture()
        +L2 no_tier_na_fixture()
    }
    class forge_ci_yml {
        +existing matrix preserved
        +i3.test.sh entry after i2.test.sh
    }
    class linting_md {
        +existing sections preserved
        +ADR-I3-001 H2 section
    }
    class forge_tier {
        +T1|T2|T3
    }

    constitution_linter_sh --> forge_tier : reads
    constitution_linter_sh --> compliance_tiers_md : reads forbidden:
    constitution_linter_sh --> forbidden_components_rules_md : seed catalogue
    forbidden_components_rules_md --> compliance_tiers_md : sibling
    standards_index_yml --> forbidden_components_rules_md : registers
    review_md --> forbidden_components_rules_md : birth entry
    i3_test_sh --> constitution_linter_sh : black-box tests
    i3_test_sh --> forbidden_components_rules_md : anchor tests
    forge_ci_yml --> i3_test_sh : harness entry
    linting_md --> forbidden_components_rules_md : doc cross-link
```

## Data Flow — T3 project with forbidden pubspec dependency

```mermaid
sequenceDiagram
    participant U as Adopter / CI
    participant CL as constitution-linter.sh
    participant FT as .forge/.forge-tier
    participant ST as .forge/standards/
    participant TR as working tree
    participant OUT as stdout / stderr

    U->>CL: bash .forge/scripts/constitution-linter.sh
    CL->>FT: read tier (T3)
    FT-->>CL: T3
    CL->>ST: discover standards with forbidden:
    ST-->>CL: [identity.yaml, observability.yaml, orchestration.yaml, state-management.yaml]
    CL->>CL: state-management.yaml -> ADR-006 section already enforces (skip in generic)
    CL->>ST: read forbidden: from identity.yaml
    ST-->>CL: [firebase-auth, auth0-saas-us]
    CL->>TR: scan pubspec.yaml for "firebase-auth"
    TR-->>CL: match at pubspec.yaml:14
    CL->>OUT: fail "  [REFUSAL: T3-RULE-001: firebase-auth forbidden at T3 (identity.yaml::forbidden) ; remediation: replace with Zitadel or downgrade tier]"
    CL->>ST: read forbidden: from observability.yaml
    ST-->>CL: [datadog]
    CL->>TR: scan working tree
    TR-->>CL: no match
    CL->>OUT: PASS / FAIL counters aggregated
    CL-->>U: exit 1 (1 FAIL)
```

## Data Flow — Tier ledger absent → N/A

```mermaid
sequenceDiagram
    participant U as Adopter
    participant CL as constitution-linter.sh
    participant FT as .forge/.forge-tier
    participant OUT as stdout

    U->>CL: bash .forge/scripts/constitution-linter.sh
    CL->>FT: read tier
    FT-->>CL: file missing
    CL->>CL: check FORGE_EU_TIER env
    Note over CL: env unset
    CL->>OUT: not_applicable "  no compliance tier declared"
    Note over CL: section ends ; rest of linter continues
    CL-->>U: exit 0 (no FAIL added)
```

## Test Harness Design

### L1 — unit-level (≥ 14 tests, FR-I3-T3F-061)

The L1 layer treats each artefact as a black box and asserts
file presence + key anchors via grep on the linter source +
the new standard.

| Test ID                                  | FR covered                     | Anchor asserted                                                                                  |
|------------------------------------------|--------------------------------|--------------------------------------------------------------------------------------------------|
| `_test_i3_001_linter_section_anchor`     | FR-I3-T3F-001                  | `# ── ADR-I3-001: T3-Forbidden Components` comment in `constitution-linter.sh`                  |
| `_test_i3_002_linter_section_echo`       | FR-I3-T3F-001                  | `echo "T3-Forbidden Components (I.3` line in `constitution-linter.sh`                            |
| `_test_i3_003_opt_out_env_var`           | FR-I3-T3F-002 / NFR-I3-T3F-004 | `FORGE_LINTER_SKIP_T3_FORBIDDEN` keyword present in section ; opt-out branch runs                |
| `_test_i3_004_tier_discovery_ledger`     | FR-I3-T3F-003                  | section reads `.forge/.forge-tier`                                                               |
| `_test_i3_005_tier_discovery_na`         | FR-I3-T3F-003 / FR-I3-T3F-126  | section emits `not_applicable.*no compliance tier declared` when no tier                         |
| `_test_i3_006_standards_discovery`       | FR-I3-T3F-004                  | section walks `.forge/standards/**/*.yaml` and `**/*.md`                                          |
| `_test_i3_007_violation_format`          | FR-I3-T3F-007 / FR-I3-T3F-120  | section emits `[REFUSAL: T3-RULE-NNN: <token> forbidden at <tier> (<std>::forbidden)` shape      |
| `_test_i3_008_standard_exists`           | FR-I3-T3F-040 / 041            | `forbidden-components-rules.md` exists + frontmatter `linter_rule: t3-forbidden-components`     |
| `_test_i3_009_standard_h2_sections`      | FR-I3-T3F-042                  | new standard has ≥ 6 H2 sections                                                                 |
| `_test_i3_010_rule_catalogue_anchors`    | FR-I3-T3F-043 / 120..126       | T3-RULE-001..007 anchors present in the standard's rule-catalogue table                          |
| `_test_i3_011_index_entry`               | FR-I3-T3F-044                  | `id: global/forbidden-components-rules` entry in `standards/index.yml`                           |
| `_test_i3_012_review_entry`              | FR-I3-T3F-045                  | `## 2026-05-12 — Initial ratification (i3-t3-forbidden-linter)` in `REVIEW.md`                    |
| `_test_i3_013_compliance_tiers_flip`     | FR-I3-T3F-046                  | `enforcement: ci` in `compliance-tiers.md` frontmatter ; "shipped 2026-05-12" delta in Status   |
| `_test_i3_014_linting_md_section`        | FR-I3-T3F-080                  | `## ADR-I3-001 — T3-Forbidden Components` H2 in `docs/LINTING.md`                                |

**14 L1 tests** — meets the FR-I3-T3F-061 ≥ 14 minimum.

### L2 — fixture-level (4 tests, FR-I3-T3F-062)

| Fixture                          | Coverage                                                                                          | Expected                                                                                  |
|----------------------------------|---------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| `_test_i3_l2_t3_pubspec`         | tmpdir : `.forge/.forge-tier`=T3 + `pubspec.yaml` declaring `firebase_auth:` + mirror of `.forge/standards/identity.yaml` | linter exits 1 with `[REFUSAL: T3-RULE-001: firebase-auth` line in output                  |
| `_test_i3_l2_t3_cargo`           | tmpdir : `.forge/.forge-tier`=T3 + `Cargo.toml` declaring `inngest` + mirror of `orchestration.yaml`                       | linter exits 1 with `[REFUSAL: T3-RULE-003: inngest` line                                  |
| `_test_i3_l2_t1_warn_only`       | tmpdir : `.forge/.forge-tier`=T1 + `pubspec.yaml` declaring `firebase_auth:` + mirror of `identity.yaml`                   | linter exits 0 ; WARN counter ≥ 1 ; FAIL counter = 0                                       |
| `_test_i3_l2_no_tier_na`         | tmpdir : no `.forge/.forge-tier` + no `FORGE_EU_TIER` env                                                                  | linter exits 0 with `N/A` line containing `no compliance tier declared`                    |

### Performance (NFR-I3-T3F-008)

Full linter run (with the new section) ≤ 5 s on the Forge
repository. Harness `i3.test.sh --level 1` ≤ 3 s ;
`--level 1,2` ≤ 15 s.

## Standards Applied

- **`global/standards-lifecycle.md`** (T.4) — the new
  standard declares `expires_at: 2027-05-12` per the
  12-month cadence.
- **`global/janus-orchestration-rules.md`** (J.8) —
  sibling rule-catalogue pattern. T3-RULE-NNN extends
  J8-RULE-NNN per ADR-J8-004.
- **`global/data-stewardship-rules.md`** (K.3) — sibling
  rule-catalogue pattern. T3-RULE-NNN co-exists with
  K3-RULE-NNN (different audit modules, distinct prefixes,
  zero collision per ADR-J8-004 inheritance).
- **`global/compliance-tiers.md`** (I.2) — direct consumer
  of the I.3 enforcement surface ; the frontmatter flip
  `enforcement: review → ci` lands in `tasks.md` Phase 4.
- **`global/linting-rules.md`** (F.4) — the
  `FORGE_LINTER_SKIP_*` env-var convention + the
  `warn` helper are reused verbatim.
- **`compliance-tier.schema.json`** (T.4) — consumed
  verbatim ; no schema bump.

## Constitutional Compliance Gate

- **Article I (TDD)** : ✅ enforced via `i3.test.sh` RED →
  GREEN cadence ; tasks.md Phase 1 writes 14+ L1 stubs all
  FAIL.
- **Article II (BDD)** : ✅ 4 Gherkin scenarios in
  specs.md cover the 4 user-facing flows (T3+FAIL,
  T1+WARN, no-tier+N/A, opt-out+SKIP).
- **Article III (Specs Before Code)** : ✅ specs.md +
  design.md precede any implementation.
- **Article III.4** : ✅ Q-001/Q-002/Q-003 answered via
  ADR-I3-002/003/004. Open-questions.md flips to
  `answered` in `/forge:plan`.
- **Article IV (Delta-Based Changes)** : ✅ ADDED
  Requirements predominate ; the MODIFIED entries are
  `compliance-tiers.md` frontmatter (1-char `review →
  ci`) + Status note paragraph (1-line addition of "I.3
  shipped 2026-05-12 via i3-t3-forbidden-linter"). Per
  Article IV.1.
- **Article V (Audit Trail)** : ✅ FR-I3-T3F-* tags +
  `T3-RULE-NNN` IDs jointly machine-parseable.
- **Article VI (Flutter)** : N/A.
- **Article VII (Rust)** : N/A.
- **Article VIII (Infra)** : ✅ linter is one-shot bash +
  Python 3 inline ; no service / daemon / privileged ops.
- **Article IX (Sec/Obs)** : ✅ N/A directly (linter is a
  CI-time review surface).
- **Article X (Code Quality)** : ✅ NFR-I3-T3F-004
  preserves F.4 conventions ; section is shellcheck-clean.
- **Article XI (AI-First Design)** : ✅ deterministic
  surface (no LLM call) ; XI.3 schema-driven preserved
  (forbidden: lists are schema-bound inputs).
- **Article XII (Governance)** : ✅ EXECUTES §enforce for
  the first time on generic `forbidden:` tokens. Does NOT
  amend any constitutional article.

**No constitutional violation detected. Design proceeds to
`/forge:plan`.**

## Open Questions remaining post-design

- Q-001 → **answered by ADR-I3-003** (warn-only T1+T2
  Phase A, fail-only T3, flip at B.8 / T6).
- Q-002 → **answered by ADR-I3-004**
  (`persistence.yaml::forbidden_for_eu_strict:` deferred
  to T6 standards refactor ; T3-RULE-005 matrix-row hook
  covers the gap until then).
- Q-003 → **answered by ADR-I3-002** (7 seed rules
  T3-RULE-001..007).

`open-questions.md` flips Q-001..Q-003 to `Status: answered`
during `/forge:plan` per the J.8 / K.3 precedent.
