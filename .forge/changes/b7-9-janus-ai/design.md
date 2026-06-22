# Design: b7-9-janus-ai

<!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) -->

J.8.c — Janus refusal rules for the `ai-native-rag` archetype. Refuse
Vertex AI / AWS Bedrock as default LLM providers (CLOUD Act) ; at
`--eu-tier T3` force Mistral-EU (Mistral on Scaleway) / self-hosted
vLLM by refusing US-managed inference. Extends the J.8 machinery
(`j8-janus-rules`) — same `J8-RULE-NNN` namespace, same exit-3 /
`[REFUSAL:]` convention, same bash + PyYAML helper pattern.

This design covers the four resolved Open Questions (Q-001..Q-004),
the component design, the data flows, the testing strategy, and the
**shared-file collision analysis** with the sibling brick `b7-pythia`.

---

## Architecture Decisions

### ADR-B7-9-001 — Rule-ID namespace : reuse `J8-RULE-NNN` (resolves Q-001)

J.8.c is an **extension of J.8**, not a new audit module. ADR-J8-004
fixed the `<MODULE>-RULE-NNN` format and stated "Future audit modules
use their own prefix (`K3-RULE-NNN`, etc.)". J.8.c is the *same* module
(J.8) landing its pre-announced sub-item — so it stays in the
`J8-RULE-NNN` namespace rather than minting a `B79-RULE-NNN` prefix.

The live catalogue ends at `J8-RULE-003` (verified : grep of
`.claude/`, `.forge/standards/`, `.forge/scaffolding/` returns exactly
`J8-RULE-001..003`). This change allocates the next free sequential
block :

- `J8-RULE-004` — Vertex AI refused as default LLM provider.
- `J8-RULE-005` — AWS Bedrock refused as default LLM provider.
- `J8-RULE-006` — `--eu-tier T3` ⇒ Mistral-EU / vLLM (US-managed
  inference refused).

IDs are NEVER reused (ADR-J8-004 numbering invariant, re-affirmed by
`forbidden-components-rules.md` line 68). A harness grep
(NFR-B7-9-003) asserts `J8-RULE-004` is allocated, guarding against a
collision with any concurrently-landing J.8 rule.

**Q-001 RESOLVED** : three rules, IDs `J8-RULE-004/005/006`.

### ADR-B7-9-002 — Registry : new `forbidden_combinations:` sibling list (resolves Q-001 placement)

The existing `forbidden_archetypes:` list (J.8.a) models **whole-archetype**
refusals keyed by `name:` — consumed by `_refuse_if_forbidden` and the
TS dispatcher. The J.8.c refusals are **not** archetype refusals :
`ai-native-rag` itself is permitted ; what is refused is a *provider ×
tier* combination *within* that archetype.

`janus-orchestration-rules.md` "Extending the catalogue" step 1 already
foresaw exactly this : *"or to a sibling `forbidden_combinations:` list
when the future J.8 extension lands non-archetype refusals like 'T3 +
ai-native-rag forces Mistral-EU'"*. This design lands that sibling
list rather than overloading `forbidden_archetypes:` with optional
`provider`/`tier` keys (which would break the 5-key shape asserted by
`j8.test.sh::_test_j8_011_entry_shape`).

Entry shape (7 keys) :
```yaml
forbidden_combinations:
  - archetype: ai-native-rag
    provider: vertex-ai
    tier: any            # fires regardless of declared tier (never a valid default)
    reason: "Vertex AI = GCP-managed inference ; CLOUD Act incompatible with EU/premium positioning"
    since: "0.5.0"
    alternative: "Mistral-EU (Mistral on Scaleway) or self-hosted vLLM ; OpenAI/Anthropic via EU-jurisdiction gateway at T1 only"
    rule_id: J8-RULE-004
  - archetype: ai-native-rag
    provider: bedrock
    tier: any
    reason: "AWS Bedrock = AWS-managed inference ; CLOUD Act incompatible with EU/premium positioning"
    since: "0.5.0"
    alternative: "Mistral-EU (Mistral on Scaleway) or self-hosted vLLM ; OpenAI/Anthropic via EU-jurisdiction gateway at T1 only"
    rule_id: J8-RULE-005
  - archetype: ai-native-rag
    provider: us-managed-inference
    tier: T3
    reason: "T3 (SecNumCloud / EUCS High) requires 100% EU jurisdiction ; US-managed inference is CLOUD Act exposure"
    since: "0.5.0"
    alternative: "Mistral on Scaleway (SecNumCloud) or self-hosted vLLM on EU infrastructure"
    rule_id: J8-RULE-006
```
The `provider:` token strings (`vertex-ai`, `bedrock`,
`us-managed-inference`) are the canonical refusal keys ; they double as
the I.3 `compliance-tiers.md::forbidden:` tokens (FR-B7-9-062, Q-003).

**Q-002 RESOLVED** : `since: "0.5.0"` (ai-native-rag MINOR per
VERSIONING.md / ADR-B7-2A-004).

### ADR-B7-9-003 — Helper : additive `_refuse_if_forbidden_combination` (resolves Q-004)

The existing `_refuse_if_forbidden "<archetype>"` (FR-J8-022) reads only
`forbidden_archetypes:` and must keep its single-arg, archetype-only
contract (`j8.test.sh` asserts its signature). J.8.c adds a **new**
function `_refuse_if_forbidden_combination "<archetype>" "<provider>"`
to the same `bin/_forge-init-helpers.sh`, sharing the forge-root
discovery + PyYAML inline parse pattern verbatim (ADR-J8-005).

Tier resolution order (FR-B7-9-041) : `$FORGE_EU_TIER` → first line of
`<forge_root>/.forge/.forge-tier` (J.8 ADR-J8-006 ledger) → empty. With
an empty tier, only `tier: any` entries can match — the T3 rule does
NOT fire on an undeclared tier (Article III.4 — no guessed default,
mirroring `constitution-linter.sh` tier discovery / `T3-RULE-007`).

Match predicate : `archetype == arg1 AND provider == arg2 AND (tier ==
"any" OR tier == resolved_tier)`. On match → emit `[REFUSAL:]` +
`exit 3`. On no-match or unreachable table → return 0 (fail-open,
verbatim `_refuse_if_forbidden` behaviour).

**Q-004 RESOLVED** : new additive function, existing helper untouched.

### ADR-B7-9-004 — Collision avoidance with `b7-pythia` (resolves Q of co-edit)

`b7-pythia` (K.2 agent) and this brick BOTH edit
`.claude/agents/cross-layer-orchestrator.md`. To avoid a merge conflict
when the two land independently :

| Brick | Section edited | Delta |
|-------|----------------|-------|
| `b7-9-janus-ai` (this) | `## Forbidden archetypes & combinations` H2 (J.8) | NEW H3 sub-section "LLM-provider rules (`ai-native-rag`)" with `J8-RULE-004..006` H4s, inserted between the `J8-RULE-003` H4 and the "Refusal semantics" H3. |
| `b7-pythia` (sibling) | `## Dispatch Table` H2 (B.1.7) | NEW table row routing `ai-native-rag` embeddings/pgvector/MCP work to Pythia. |

The two H2 sections are non-adjacent (Dispatch Table precedes Forbidden
archetypes). Each brick touches a distinct, non-overlapping region of
the file. **Residual risk** : if both PRs land in the same window, git
3-way merge resolves cleanly (disjoint hunks) ; if a reviewer rebases
one onto the other, no textual conflict arises. This is flagged
explicitly per the brick assignment so the maintainer sequences or
merges with awareness. No coordination lock is required.

### ADR-B7-9-005 — Two complementary enforcement surfaces (resolves Q-003)

The J.8.c refusal exists on two surfaces, deliberately :

1. **Scaffold-time (Janus, this brick's core)** — `J8-RULE-004..006`,
   exit 3, blocking, fired by `_refuse_if_forbidden_combination` from
   the wrapper. Refuses the *declared* provider before scaffolding.
2. **Review-time (I.3 linter, the Q-003-gated extension)** —
   `T3-RULE-005` (generic `forbidden:` token enforcement), tier-scaled
   WARN at T1/T2, FAIL at T3, fired by `constitution-linter.sh` against
   working-tree manifests. Catches a provider that slipped past the
   scaffold-time gate (e.g. an adopter who hand-edited the gateway
   config post-scaffold).

Both surfaces quote the SAME `compliance-tiers.md` §10.2 gradient
(NFR-B7-9-005) — they never contradict. This mirrors how `J8-RULE-002/003`
(scaffold-time) and `T3-RULE-001/002` (review-time) already co-exist for
Zitadel/SigNoz.

**Q-003** — whether to ship the I.3 coupling (FR-B7-9-062..064) IN this
brick or as a follow-up — is left as a maintainer decision in
`open-questions.md`. **Default (this design)** : ship it in-brick (the
coupling is small : two tokens in `compliance-tiers.md::forbidden:` +
two `REMEDIATION` map entries + one interim-gap note), because shipping
the scaffold-time rules without the review-time net leaves the
post-scaffold hand-edit case uncovered. If the maintainer prefers the
core J.8.c rules to land first, FR-B7-9-062..064 split to a follow-up
without blocking FR-B7-9-001..045.

### ADR-B7-9-006 — EU alternatives VERIFIED, not invented (Article III.4)

Mistral-EU (Mistral on Scaleway) + self-hosted vLLM are cited verbatim
from `compliance-tiers.md` §10.2 :

> `LLM Gateway (OpenAI/Anthropic) | ⚠️ T1 max | ❌ | ❌ | Pour T3 : Mistral on Scaleway ou vLLM self-host`

and the CLOUD Act forcing from the same matrix :

> `AWS / GCP / Azure | ⚠️ T1 only | ❌ | ❌ | CLOUD Act force max T1`

Vertex AI is GCP-managed inference (inherits the `AWS / GCP / Azure`
row) ; AWS Bedrock is AWS-managed inference (same row). Both also fail
the `LLM Gateway` row at T2/T3. No provider specifics are fabricated.
The §10.2 matrix is itself byte-identical to
`docs/ARCHITECTURE-TARGET.md` §10.2 (`compliance-tiers.md` Interdiction
5), so the rationale traces to the ratified architecture document.

---

## Component Design

```
                    forge init --archetype ai-native-rag [--eu-tier T3]
                                       │
                                       ▼
          ┌────────────────────────────────────────────────────────┐
          │ cli/src/commands/init-archetype.ts (TS dispatcher)       │
          │  1. forbidden_archetypes check (J.8.a) — ai-native-rag   │
          │     is NOT forbidden ⇒ proceeds                          │
          │  2. versioned-schema gate — candidate/scaffoldable:false │
          │     ⇒ exit 3 (B.7.1/B.7.2a) WHILE CANDIDATE              │
          └────────────────────────────────────────────────────────┘
                                       │ (post-promotion : reaches wrapper)
                                       ▼
          ┌────────────────────────────────────────────────────────┐
          │ bin/forge-init-ai-native-rag.sh (gated wrapper, B.7.2)   │
          │  source bin/_forge-init-helpers.sh                       │
          │  _refuse_if_forbidden            "ai-native-rag"   (J.8.a)│
          │  _refuse_if_forbidden_combination "ai-native-rag" \      │
          │                                   "$LLM_PROVIDER"  (J.8.c)│ ◀── NEW
          └────────────────────────────────────────────────────────┘
                                       │
                                       ▼
          ┌────────────────────────────────────────────────────────┐
          │ _refuse_if_forbidden_combination (NEW, _forge-init-      │
          │  helpers.sh)                                             │
          │  • resolve tier : $FORGE_EU_TIER → .forge/.forge-tier → ∅│
          │  • PyYAML parse dispatch-table.yml::forbidden_combinations│
          │  • match archetype+provider+(tier==any|tier==resolved)   │
          │  • on match → stderr [REFUSAL: …] + exit 3 (ADR-J8-003)  │
          │  • else / unreachable table → return 0 (fail-open)       │
          └────────────────────────────────────────────────────────┘

   Registry        .forge/scaffolding/dispatch-table.yml
                     forbidden_archetypes:   (J.8.a — unchanged)
                     forbidden_combinations: (J.8.c — NEW, 3 seed entries) ◀── NEW

   Narrative       .claude/agents/cross-layer-orchestrator.md
                     ## Forbidden archetypes & combinations (J.8)
                       #### J8-RULE-001..003           (unchanged)
                       ### LLM-provider rules (ai-native-rag)  ◀── NEW H3
                         #### J8-RULE-004 / 005 / 006

   Standard        .forge/standards/global/janus-orchestration-rules.md
                     rule-catalogue table += 3 rows ; "Extending" prose updated ◀── EDIT

   Review-time     .forge/standards/global/compliance-tiers.md::forbidden: += vertex-ai, bedrock ◀── EDIT (Q-003)
   (I.3 coupling)  .forge/scripts/constitution-linter.sh::REMEDIATION += 2 entries           ◀── EDIT (Q-003)
                     ⇒ generic T3-RULE-005 catches the tokens in working-tree manifests
```

---

## Data Flow — `ai-native-rag` + Vertex AI default provider (any tier)

```mermaid
sequenceDiagram
    participant U as Adopter
    participant W as forge-init-ai-native-rag.sh
    participant H as _refuse_if_forbidden_combination
    participant T as dispatch-table.yml
    U->>W: scaffold ai-native-rag, LLM_PROVIDER=vertex-ai
    W->>H: _refuse_if_forbidden_combination("ai-native-rag","vertex-ai")
    H->>H: resolve tier (FORGE_EU_TIER / .forge-tier / ∅)
    H->>T: parse forbidden_combinations
    T-->>H: {ai-native-rag, vertex-ai, tier:any, J8-RULE-004}
    H->>H: archetype✓ provider✓ tier:any✓ ⇒ MATCH
    H-->>U: stderr [REFUSAL: ai-native-rag/vertex-ai@<tier>: J8-RULE-004: … ; alternative: Mistral-EU / vLLM]
    H->>W: exit 3
    Note over W: no scaffold side-effect
```

## Data Flow — `ai-native-rag` + `--eu-tier T3` + US-managed inference

```mermaid
sequenceDiagram
    participant U as Adopter
    participant W as forge-init-ai-native-rag.sh
    participant H as _refuse_if_forbidden_combination
    participant T as dispatch-table.yml
    U->>W: --eu-tier T3 ; LLM_PROVIDER=us-managed-inference
    W->>H: _refuse_if_forbidden_combination("ai-native-rag","us-managed-inference")
    H->>H: tier = T3 (from FORGE_EU_TIER / ledger)
    H->>T: parse forbidden_combinations
    T-->>H: {ai-native-rag, us-managed-inference, tier:T3, J8-RULE-006}
    H->>H: archetype✓ provider✓ tier T3 == T3 ✓ ⇒ MATCH
    H-->>U: stderr [REFUSAL: …@T3: J8-RULE-006: … ; alternative: Mistral on Scaleway / vLLM self-host]
    H->>W: exit 3
```

## Data Flow — `--eu-tier T1` + OpenAI-via-gateway (NOT refused)

```mermaid
sequenceDiagram
    participant U as Adopter
    participant W as forge-init-ai-native-rag.sh
    participant H as _refuse_if_forbidden_combination
    participant T as dispatch-table.yml
    U->>W: --eu-tier T1 ; LLM_PROVIDER=openai-via-eu-gateway
    W->>H: _refuse_if_forbidden_combination("ai-native-rag","openai-via-eu-gateway")
    H->>H: tier = T1
    H->>T: parse forbidden_combinations
    T-->>H: no entry matches provider=openai-via-eu-gateway
    H->>W: return 0 (no refusal — matrix ⚠️ T1 max)
    Note over W: scaffold proceeds
```

---

## Testing Strategy

`.forge/scripts/tests/b7-9.test.sh` mirrors `j8.test.sh` + `i3.test.sh`
(`--level` parse, `_helpers.sh` source, MANIFEST block, `_not_implemented`
RED stub, PASS/FAIL counters, `--level 1,2` registration in `forge-ci.yml`).

### L1 — grep-level (hermetic, ≥ 11 tests, FR-B7-9-081)

| Test | Asserts | FR |
|------|---------|----|
| `_test_b7_9_001_agent_h3_section` | new H3 "LLM-provider rules" + `<!-- Audit: B.7.9 + J.8.c …-->` in the agent file | FR-B7-9-001/006 |
| `_test_b7_9_002_rule_004` | `J8-RULE-004` anchor in agent file | FR-B7-9-002 |
| `_test_b7_9_003_rule_005` | `J8-RULE-005` anchor | FR-B7-9-003 |
| `_test_b7_9_004_rule_006` | `J8-RULE-006` anchor | FR-B7-9-004 |
| `_test_b7_9_005_rule_004_is_next_free` | no `J8-RULE-004` collision (numbering invariant) | NFR-B7-9-003 |
| `_test_b7_9_020_combinations_key` | `^forbidden_combinations:` top-level key in dispatch-table | FR-B7-9-020 |
| `_test_b7_9_021_entry_shape` | entry has the 7 keys (archetype/provider/tier/reason/since/alternative/rule_id) | FR-B7-9-021 |
| `_test_b7_9_022_seed_entries` | three seed `rule_id`s J8-RULE-004/005/006 present | FR-B7-9-022 |
| `_test_b7_9_040_helper_fn` | `_refuse_if_forbidden_combination()` defined ; `_refuse_if_forbidden` still present | FR-B7-9-040 |
| `_test_b7_9_045_wrapper_invokes` | wrapper sources helper + calls `_refuse_if_forbidden_combination` | FR-B7-9-045 |
| `_test_b7_9_043_refusal_format` | `[REFUSAL:` format in helper | FR-B7-9-043 |
| `_test_b7_9_060_std_rows` | three new rows in `janus-orchestration-rules.md` catalogue | FR-B7-9-060 |
| `_test_b7_9_062_tokens` (Q-003) | `vertex-ai` + `bedrock` in `compliance-tiers.md::forbidden:` + `REMEDIATION` | FR-B7-9-062/063 |

### L2 — fixture-level (2 tests, FR-B7-9-082)

- `_test_b7_9_l2_refuse_t3` — synthetic target tree with
  `.forge/.forge-tier`=`T3` ; invoke `_refuse_if_forbidden_combination
  "ai-native-rag" "us-managed-inference"` ⇒ exit 3 + `[REFUSAL:` with
  `J8-RULE-006`.
- `_test_b7_9_l2_t1_no_refuse` — `.forge/.forge-tier`=`T1` ; invoke with
  `openai-via-eu-gateway` ⇒ exit 0, no `[REFUSAL:`. Mirrors
  `i3.test.sh::_test_i3_l2_t1_warn_only`.

### Performance (NFR-B7-9-002)

L1 ≤ 5 s (pure grep) ; full `--level 1,2` ≤ 15 s (two `mktemp` fixtures
+ one PyYAML parse each), within the j8/i3 envelope.

---

## Standards Applied

- `global/janus-orchestration-rules.md` (J.8) — the rule catalogue +
  extension protocol this change follows (and updates).
- `global/compliance-tiers.md` (I.2) — §10.2 matrix : the VERIFIED
  source of the LLM-provider + CLOUD Act rows + the tier gradient.
- `global/forbidden-components-rules.md` (I.3) — the `T3-RULE-NNN`
  catalogue + tier-scaled severity + the `forbidden:` token enforcement
  the review-time coupling reuses.
- `global/llm-gateway.md` (B.7.3) — the forward-pointer (ADR-B7-3-002)
  this change honours ; the provider taxonomy reference.
- `global/standards-lifecycle.md` (T.4) — the SemVer + `REVIEW.md`
  append-only discipline for the standard edits.

---

## Constitutional Compliance Gate

- **Article I (TDD)** — `b7-9.test.sh` written RED first (Phase 1) ;
  implementation Phase 2 turns each green one cluster at a time.
- **Article II (BDD)** — Gherkin scenarios (specs.md / `features/`)
  cover the four scaffold-time behaviours.
- **Article III / III.4** — `FR-B7-9-*` specs precede code ; EU
  alternatives verified verbatim (ADR-B7-9-006), genuine ambiguities in
  `open-questions.md`.
- **Article V (compliance gate)** — `[Story: FR-B7-9-XXX]` task tags ;
  `J8-RULE-NNN` machine-parseable stderr.
- **Article XI (AI-First)** — XI.5 (Mistral-EU / vLLM is the sovereign
  fallback) + XI.6 (T3 refusal keeps prompt PII in EU jurisdiction).
- **Article XII (governance)** — additions per `janus-orchestration-rules.md`
  "Extending the catalogue" are NOT amendments ; the standard edits are
  SemVer-minor with `REVIEW.md` entries ; no `[T1,T2,T3]` enum change.

---

## Open Questions remaining post-design

All four design-phase questions resolved (Q-001 → ADR-B7-9-001/002,
Q-002 → ADR-B7-9-002, Q-003 → ADR-B7-9-005 with a maintainer-decision
default, Q-004 → ADR-B7-9-003). The single inline `[NEEDS CLARIFICATION]`
(I.3-coupling scope) is captured in `open-questions.md` as Q-003 with the
in-brick default recorded ; it does not block the core J.8.c rules. See
`open-questions.md`.
