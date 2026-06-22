# Open Questions — b7-9-janus-ai

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: Rule-ID allocation — how many rules, which IDs?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md "Rule-ID allocation"
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

J.8.c must allocate NEW `J8-RULE-NNN` IDs (ADR-J8-004 — never reuse).
The brick covers three distinct refusals (Vertex default / Bedrock
default / T3 US-managed inference). Should each get its own rule ID, or
should they collapse into one "non-sovereign LLM provider" rule? And
which IDs?

### Resolution

- **Resolved on**: 2026-06-22 (via `design.md` ADR-B7-9-001)
- **Decision**: **three rules**, IDs **`J8-RULE-004` / `J8-RULE-005` /
  `J8-RULE-006`** — the next free sequential block (verified : the live
  catalogue ends at `J8-RULE-003`). Three separate IDs because the
  refusals have distinct triggers/tiers (Vertex any-tier-default,
  Bedrock any-tier-default, US-managed-inference T3-only) and distinct
  remediation framing ; collapsing them would lose the
  machine-parseable specificity the `[REFUSAL:]` line provides.

---

## Q-002: Registry placement — extend `forbidden_archetypes:` or add a sibling list?

- **Status**: answered
- **Raised in**: proposal.md J.8.c.2 ; specs.md FR-B7-9-020
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

The J.8.a runtime registry is `dispatch-table.yml::forbidden_archetypes`,
a list keyed by `name:` with a fixed 5-key shape (asserted by
`j8.test.sh::_test_j8_011_entry_shape`). The J.8.c refusals are
provider×tier combinations within a *permitted* archetype, not
whole-archetype refusals. Overload `forbidden_archetypes:` with optional
`provider`/`tier` keys, or add a new sibling list?

### Resolution

- **Resolved on**: 2026-06-22 (via `design.md` ADR-B7-9-002)
- **Decision**: **new sibling `forbidden_combinations:` list**. This is
  the exact case `janus-orchestration-rules.md` "Extending the
  catalogue" step 1 already foresaw ("or to a sibling
  `forbidden_combinations:` list … like 'T3 + ai-native-rag forces
  Mistral-EU'"). Overloading `forbidden_archetypes:` would break the
  5-key shape asserted by the existing J.8 harness. The sibling list
  carries 7 keys (archetype/provider/tier/reason/since/alternative/
  rule_id). `since: "0.5.0"` (ai-native-rag MINOR per VERSIONING.md /
  ADR-B7-2A-004).

---

## Q-003: I.3 review-time linter coupling — ship in-brick or as a follow-up?

- **Status**: answered (maintainer-ratified in-brick + Option B)
- **Raised in**: proposal.md J.8.c.4 (inline `[NEEDS CLARIFICATION]`) ;
  specs.md FR-B7-9-062..064
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

The scaffold-time Janus refusal (`J8-RULE-004..006`, exit 3) refuses the
*declared* LLM provider. An adopter who hand-edits the gateway config
post-scaffold bypasses it. The I.3 generic T3-forbidden linter
(`T3-RULE-005`, review-time, tier-scaled WARN/FAIL) catches `forbidden:`
tokens in working-tree manifests — but only if `vertex-ai` / `bedrock`
are added to `global/compliance-tiers.md::forbidden:` (currently `[]`)
with matching `REMEDIATION` map entries in `constitution-linter.sh`.

Should that I.3 coupling (FR-B7-9-062..064) ship IN this brick, or as a
separate follow-up change so the core J.8.c scaffold-time rules land
first?

`[NEEDS CLARIFICATION: ship the I.3 compliance-tiers.md::forbidden token
coupling + linter REMEDIATION entries inside b7-9-janus-ai, or defer to
a follow-up change?]`

### Resolution

- **Resolved on**: 2026-06-22 (via `design.md` ADR-B7-9-005, **default**)
- **Decision (default — pending maintainer confirmation at implement)**:
  **ship in-brick**. The coupling is small (two tokens in
  `compliance-tiers.md::forbidden:` + two `REMEDIATION` entries + one
  interim-gap note in `forbidden-components-rules.md`) and closes the
  post-scaffold hand-edit gap that the scaffold-time rule alone leaves
  open. Both surfaces quote the same §10.2 gradient (NFR-B7-9-005), so
  they cannot contradict. **Override path** : if the maintainer prefers
  the core J.8.c rules to land standalone, FR-B7-9-062..064 (and the
  `_test_b7_9_062_tokens` test + task T-STD-I3) split cleanly to a
  follow-up change without blocking FR-B7-9-001..045/060/061. This is a
  scope preference, not a technical blocker.
- **Maintainer ratification + version handling (Deviation #9, 2026-06-22)**:
  the I.3 coupling is **confirmed in-brick**. During implementation the
  additive `forbidden:` token edit collided with two *archived* sibling
  gates that exact-pinned the standard versions
  (`i2.test.sh::_test_i2_005` on `compliance-tiers.md`,
  `i3.test.sh::_test_i3_008` on `forbidden-components-rules.md`). Maintainer
  chose **"Option B"**: do the proper SemVer-minor bumps
  (`compliance-tiers.md` + `forbidden-components-rules.md` `1.0.0` → `1.1.0`,
  lifecycle dates → 2026-06-22 / 2027-06-22) per the standards-lifecycle
  discipline, AND relax the two over-strict sibling pins to
  frontmatter-validity checks (a versioned, mutable field must not be
  exact-pinned by a sibling change's gate). The scope expansion to the
  archived `i2`/`i3` test files is maintainer-ratified. All gates re-verified
  GREEN (i2 14/0, i3 18/0, b7-9 15/0, j7 21/0, verify.sh + constitution-linter
  PASS).

---

## Q-004: Helper — modify `_refuse_if_forbidden` or add a new function?

- **Status**: answered
- **Raised in**: proposal.md J.8.c.3 ; specs.md FR-B7-9-040
- **Raised on**: 2026-06-22
- **Raised by**: @bfontaine

### Question

`_refuse_if_forbidden "<archetype>"` (J.8.a, FR-J8-022) reads only
`forbidden_archetypes:` and has a single-arg, archetype-only contract
asserted by the J.8 harness. The combination check needs a second
argument (provider) and reads a different list. Extend the existing
function (risking the J.8 contract) or add a new one?

### Resolution

- **Resolved on**: 2026-06-22 (via `design.md` ADR-B7-9-003)
- **Decision**: **add a NEW additive function**
  `_refuse_if_forbidden_combination "<archetype>" "<provider>"` to the
  same `bin/_forge-init-helpers.sh`, leaving `_refuse_if_forbidden`
  byte-unchanged. Preserves the J.8 contract (NFR-B7-9-001) ; shares the
  forge-root discovery + PyYAML inline pattern (ADR-J8-005) ; reuses
  exit 3 (ADR-J8-003). Tier resolved from `$FORGE_EU_TIER` → `.forge/
  .forge-tier` ledger → empty (empty ⇒ only `tier: any` matches ; no
  guessed default, Article III.4).

---

## Verified (no clarification needed)

- **Mistral-EU (Mistral on Scaleway) + self-hosted vLLM** are the
  sanctioned EU alternatives — confirmed verbatim against
  `global/compliance-tiers.md` §10.2 `LLM Gateway (OpenAI/Anthropic)`
  row forcing note (`Pour T3 : Mistral on Scaleway ou vLLM self-host`)
  and the `AWS / GCP / Azure` row (`CLOUD Act force max T1`). The matrix
  is byte-identical to `docs/ARCHITECTURE-TARGET.md` §10.2 (Interdiction
  5). No provider specifics fabricated (Article III.4 / ADR-B7-9-006).
- **`ai-native-rag` archetype + wrapper** exist (B.7.1 schema, B.7.2a
  dispatch entry + refusing wrapper, B.7.2 scaffolder backbone, B.7.3
  standards — all archived). The wrapper
  `bin/forge-init-ai-native-rag.sh` is the hook point.
- **Exit code 3 + `[REFUSAL:]` stderr format** — inherited verbatim from
  J.8 (ADR-J8-003 / FR-J8-021). No new convention invented.
