# Standard — Forbidden Components Rules (T3-RULE-NNN catalogue)

<!-- Audit: I.3 (i3-t3-forbidden-linter) -->
<!-- Trigger: forbidden, t3-forbidden, t3-rule, linter, t1, t2, t3, eu-tier, ci-enforcement, forbidden-components -->

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
  constitution-linter.sh ADR-I3-001 section. Severity scales per
  declared compliance tier per FR-I3-T3F-006 (T1/T2 warn Phase A,
  T3 fail). This standard is the sibling rule-catalogue surface
  to global/janus-orchestration-rules.md (J.8) and
  global/data-stewardship-rules.md (K.3).
```

---

## Purpose

This standard catalogues the **T3-RULE-NNN rules** enforced by the
generic forbidden-components linter section
(`.forge/scripts/constitution-linter.sh::ADR-I3-001`, shipped by
`i3-t3-forbidden-linter`, 2026-05-12). The linter section is the
**first** Forge implementation of Article XII §enforce on **generic
`forbidden:` tokens** declared in standards frontmatter, beyond the
hard-coded `state-management.yaml` enforcement already shipped by
`f4-linter-extension` (ADR-006 NSMA section).

The catalogue is the **deterministic enforcement surface** ; this
standard is its **human-readable canon**. Adopters reading the
standards index for `[forbidden, t3-forbidden, t3-rule, linter,
ci-enforcement]` triggers MUST find a canonical reference here.

Source audit item : **I.3** from `docs/new-archetypes-plan.md`
§7.1 lines 727-731.

Constitution cross-references :

- **Article XII §enforce** — programmatic enforcement of
  constitutional boundaries.
- **Article III.4** — anti-hallucination on tier discovery
  (T3-RULE-007 emits N/A when no tier declared, never guesses a
  default).
- **Article V.1** — `T3-RULE-NNN` IDs are audit-trail glue,
  machine-parseable.

---

## Rule catalogue

| Rule ID         | Token source                                  | Severity (T1 / T2 / T3) | Remediation                                                                              | Cross-link                              |
|-----------------|-----------------------------------------------|-------------------------|------------------------------------------------------------------------------------------|-----------------------------------------|
| **T3-RULE-001** | `identity.yaml::forbidden`                    | WARN / WARN / FAIL      | Replace with `zitadel` (`identity.yaml::default`) OR downgrade tier                       | ADR-007 (`t4-adr-ratification`)         |
| **T3-RULE-002** | `observability.yaml::forbidden`               | WARN / WARN / FAIL      | Replace with `signoz` + OBI eBPF (`observability.yaml::backend`) OR downgrade tier        | ADR-008 (`t4-adr-ratification`)         |
| **T3-RULE-003** | `orchestration.yaml::forbidden`               | WARN / WARN / FAIL      | Replace with `temporal` (`orchestration.yaml::default_by_language.rust`, §VIII.2) OR downgrade tier ; `dbos` is a future-option pending a Rust SDK (ADR-B8O-001)                  | ADR-002 (`t4-adr-ratification`)         |
| **T3-RULE-004** | `state-management.yaml::forbidden` (NSMA)     | (handled by ADR-006)    | Adopt `flutter_bloc` (ADR-006 default) OR Article XII amendment                           | ADR-006 (NSMA) ; NFR-I3-T3F-001 interlock |
| **T3-RULE-005** | `global/compliance-tiers.md::forbidden`       | WARN / WARN / FAIL      | Replace per the §10.2 matrix OR downgrade tier                                            | ADR-I2-CT-002 (`i2-compliance-tiers`)   |
| **T3-RULE-006** | cross-standard mention of any forbidden token | WARN / WARN / WARN      | Refactor cross-reference to cite the standard ID instead of the token, OR remove mention  | ADR-I3-002 (`i3-t3-forbidden-linter`)   |
| **T3-RULE-007** | tier ledger absent / ambiguous                | N/A                     | Declare a tier via `.forge/.forge-tier` ledger OR `FORGE_EU_TIER` env var                 | Article III.4 ; FR-I3-T3F-126           |

**Numbering invariant** — per ADR-J8-004 inheritance, IDs are NEVER
reused. Decommissioned rules carry `DEPRECATED` ; slots are not
recycled. Future T3-RULE-008+ are documented in
`.forge/changes/i3-t3-forbidden-linter/design.md::ADR-I3-002::Future T3-RULE-008+`.

---

## Severity scaling

Severity scales by declared compliance tier per ADR-I3-003 :

| Declared tier | Severity | Linter action | Rationale                                                                                              |
|--------------:|----------|---------------|--------------------------------------------------------------------------------------------------------|
| **T1**        | WARN     | Informational | T1 declares "RGPD via DPA acceptable" ; residual CLOUD Act risk is acknowledged. Adopter awareness.   |
| **T2**        | WARN     | Phase A       | T2 declares "self-hostable" but warn-only Phase A mirrors the `state-management.yaml::ci_blocking: false` pattern. Flips to FAIL at B.8 (T6).   |
| **T3**        | FAIL     | BLOCKED       | T3 declares "100% EU jurisdiction" — forbidden component is a hard refusal.                            |

### Phase A → B transition

The T2-severity flip from `WARN` to `FAIL` is **automatic at B.8 (T6)**
via a SemVer minor bump of this standard (1.0.0 → 1.1.0) ; no schema
break. Mirrors the
`state-management.yaml::activation_planned: "B.8 (T6)"` precedent.

Encoded :

- `constitution-linter.sh::ADR-I3-001` section — per-tier branch
  (T1/T2 → `warn` helper ; T3 → `fail` helper).
- `forbidden-components-rules.md` (this standard) — Severity scaling
  matrix above.
- `i3.test.sh::_test_i3_l2_t1_warn_only` — L2 fixture confirming the
  WARN-only outcome at T1.

---

## Adoption path

Adopters can opt in incrementally. Mirrors the
`data-stewardship-rules.md::Adoption path` and
`compliance-tiers.md::Adoption path` shapes.

### Minimum viable adoption (T2 / T3 projects)

1. Declare the compliance tier in `.forge/.forge-tier` :
   ```bash
   echo "T3" > .forge/.forge-tier
   ```
2. Run `bash .forge/scripts/constitution-linter.sh` at PR time. The
   `T3-Forbidden Components` section automatically discovers every
   standard declaring a `forbidden:` block and scans the working
   tree for matches.
3. Address findings : replace the forbidden component with the
   standard's `default:` OR downgrade the declared tier with an
   audit trail.

### Full adoption (regulated workloads)

1. Steps 1-3 above.
2. Wire the linter into CI via the I.5 reusable workflow (shipping
   in a follow-up change ; until then, adopters invoke
   `constitution-linter.sh` directly from their CI script).
3. Pair with Demeter (`bin/forge-demeter-scan.sh`, K.3) — the two
   surfaces are **complementary** :
   - T3-forbidden (this rule) reads **`forbidden:` declarations in
     standards** ↔ architectural posture at component level.
   - Demeter reads **dependency lockfiles** ↔ data-stewardship
     posture at jurisdiction level.

### Opt-out

Set the env var `FORGE_LINTER_SKIP_T3_FORBIDDEN=1` to disable the
T3-Forbidden Components section without disabling the rest of
`constitution-linter.sh`. The env var follows the F.4
`FORGE_LINTER_SKIP_*` convention.

---

## Extending the catalogue

The seed catalogue (T3-RULE-001..007) ships in v1.0.0. New rules MAY
be added per the ADR-J8-004 extension protocol :

1. **Add a new rule ID** — sequentially after T3-RULE-007. IDs are
   NEVER reused (per ADR-J8-004 numbering invariant).
2. **Document the trigger** — token source, severity scaling, and
   remediation hint. Add a row to the table above.
3. **Encode the mapping** in
   `constitution-linter.sh::ADR-I3-001::RULE_ID_BY_STANDARD` (when
   the new rule maps to a standard not already enumerated).
4. **Cite the ADR / standard** in the cross-link column.
5. **Add a harness test** under `i3.test.sh` covering the new
   anchor.
6. **Bump the standard version** per SemVer :
   - Minor bump (1.0.0 → 1.1.0) — additive : new rule, new
     remediation hint, severity Phase A → B flip.
   - Major bump (1.0.0 → 2.0.0) — breaking : rule removal,
     remediation semantics change (rare).

### Future T3-RULE-008+ slots (informational)

Three candidate rules are deferred and documented in
`.forge/changes/i3-t3-forbidden-linter/design.md::ADR-I3-002` :

- **T3-RULE-008** — Persistence `forbidden_for_eu_strict:` block
  enforcement (depends on T6 standards refactor normalising
  `forbidden_for_eu_strict:` → `forbidden:` ; out of scope
  v1.0.0 per ADR-I3-004).
- **T3-RULE-009** — Transport `forbidden:` enforcement
  (currently empty list ; structural exception per Article XII —
  will fire if the list is ever populated).
- **T3-RULE-010** — Per-change override of the tier ledger
  (forward-pointer to I.5 / `forge-compliance.yml` workflow).

### Persistence `forbidden_for_eu_strict:` gap (interim)

Adopters who want immediate `dynamodb` / `firestore` / `cosmosdb`
enforcement at T3 can extend
`.forge/standards/global/compliance-tiers.md::forbidden:`
(currently `[]`) with the tokens — the generic linter picks them
up via T3-RULE-005 (matrix-row enforcement). The proper resolution
is a future T6 standards refactor normalising the
`persistence.yaml::forbidden_for_eu_strict:` block into the
generic `forbidden:` convention.

---

## Opt-out env vars

| Env var                              | Behaviour                                                                                              | Convention reference                  |
|--------------------------------------|--------------------------------------------------------------------------------------------------------|---------------------------------------|
| `FORGE_LINTER_SKIP_T3_FORBIDDEN`     | Skip the T3-Forbidden Components section entirely. The linter emits `N/A  skipped via …` and returns.   | F.4 (`f4-linter-extension`)           |
| `FORGE_LINTER_SKIP_NSMA`             | Skip the ADR-006 NSMA section. **Interlock** — the generic T3-Forbidden section always excludes `state-management.yaml` from its walk (NFR-I3-T3F-001) regardless of this var, so the two sections never double-fire.   | F.4 (`f4-linter-extension`)           |
| `FORGE_EU_TIER`                      | Override the `.forge/.forge-tier` ledger when set. Value in `{T1, T2, T3}`.                              | J.8 (`j8-janus-rules`) ADR-J8-006     |

### Interlock matrix (NFR-I3-T3F-001)

|                                | NSMA skipped (`SKIP_NSMA=1`) | NSMA active (default) |
|--------------------------------|------------------------------|------------------------|
| **T3-Forbidden skipped**       | both skip ; no enforcement   | NSMA only              |
| **T3-Forbidden active (default)** | T3-Forbidden enforces all standards except `state-management.yaml`  | NSMA enforces `state-management.yaml` ; T3-Forbidden enforces everything else  |

---

## Audit cross-references

This standard is justified by the following upstream sources :

- `docs/new-archetypes-plan.md` §7.1 row I.3 (lines 727-731).
- `.forge/standards/global/compliance-tiers.md` (sibling, I.2 —
  `linter_rule: t3-forbidden-components` forward-pointer
  resolved by this change).
- `.forge/standards/global/janus-orchestration-rules.md` (sibling
  rule-catalogue pattern, J.8).
- `.forge/standards/global/data-stewardship-rules.md` (sibling
  rule-catalogue pattern, K.3).
- `.forge/scripts/constitution-linter.sh::ADR-I3-001` section
  anchor (the enforcement surface).
- `.forge/changes/i3-t3-forbidden-linter/design.md::ADR-I3-001..004`
  (the four ADRs locking this standard's contracts).

---

## Constitutional Compliance

This standard ENFORCES the architectural-posture constraint
encoded in standards' `forbidden:` blocks. It does **not amend**
any constitutional article. The T3-RULE-NNN namespace inherits
the `<MODULE>-RULE-NNN` format from ADR-J8-004 and co-exists with
J8-RULE-NNN (J.8) + K3-RULE-NNN (K.3) without collision.

Per Article XII §enforce, this is the **first** generic surface
of Article XII enforcement on `forbidden:` tokens beyond the
hard-coded `state-management.yaml` block.
