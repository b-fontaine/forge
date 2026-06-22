# Proposal: b7-9-janus-ai
<!-- Created: 2026-06-22 -->
<!-- Schema: default -->

## Problem

`docs/new-archetypes-plan.md` §6.2 row **B.7.9** and §8 row **J.8**
(deferred sub-item **J.8.c**, explicitly retired from the T5 scope at
§0.0 line 207-210) mandate a set of **Janus refusal rules specific to
the `ai-native-rag` archetype** : refuse Vertex AI / AWS Bedrock as
default LLM providers (CLOUD Act), and at compliance tier **T3** force
Mistral-EU / self-hosted vLLM by refusing US-managed inference.

Today these rules exist in **prose + matrix only** :

1. `.forge/standards/global/compliance-tiers.md` (I.2) carries the
   §10.2 component-eligibility matrix whose **`LLM Gateway
   (OpenAI/Anthropic)`** row reads `⚠️ T1 max | ❌ | ❌` with the
   forcing note `Pour T3 : Mistral on Scaleway ou vLLM self-host`, and
   whose **`AWS / GCP / Azure`** row reads `⚠️ T1 only | ❌ | ❌` with
   `CLOUD Act force max T1`. Vertex AI (GCP-managed) and AWS Bedrock
   (AWS-managed) inherit both rows — but **no Janus rule refuses them
   at scaffold time**. An adopter scaffolding `ai-native-rag` and
   pointing the LLM gateway at Vertex / Bedrock gets no refusal.
2. `j8-janus-rules` (J.8.a) shipped the `J8-RULE-NNN` refusal namespace
   with `J8-RULE-001` (flutter-firebase), `J8-RULE-002` (T3 ⇒ self-host
   Zitadel), `J8-RULE-003` (T3 ⇒ self-host SigNoz / no Datadog) — but
   **explicitly scoped J.8.c OUT** (proposal.md "Scope Out" : "NOT the
   `ai-native-rag` LLM gateway rules (J.8.c) — that archetype doesn't
   exist yet"). The archetype now exists (B.7.1 schema, B.7.2 templates,
   B.7.3 standards all archived), so J.8.c can land.
3. The `j8-janus-rules` runtime registry
   (`dispatch-table.yml::forbidden_archetypes`) only models
   **whole-archetype** refusals keyed by `name:`. The Vertex / Bedrock
   refusals are **not** archetype refusals — `ai-native-rag` itself is
   permitted — they are **provider × tier combination** refusals. The
   J.8 standard (`janus-orchestration-rules.md` "Extending the
   catalogue" step 1) already foresaw exactly this case : "or to a
   sibling `forbidden_combinations:` list when the future J.8 extension
   lands non-archetype refusals **like 'T3 + ai-native-rag forces
   Mistral-EU'**". This change lands that sibling list.
4. The `b7-standards` LLM-gateway standard (`global/llm-gateway.md`,
   FR-B7-3-010..014) documents the tier-aware refusal as **guidance**
   and forward-points the runtime Janus rules to `b7-9` (ADR-B7-3-002 :
   "runtime Janus AI rules (J.8.c) → `b7-9-janus-ai`"). This change
   honours that forward-pointer.

The gap is a **scaffold-time decision** (Janus orchestration). It
closes by extending the existing `J8-RULE-NNN` catalogue with new,
never-reused rule IDs scoped to `ai-native-rag` LLM-provider choices,
wired into the agent file, a new `forbidden_combinations:` sibling
registry, the standard, a new combination-refusal helper, and a
grep-based harness registered in `forge-ci.yml`.

## Solution

One coordinated change extending the J.8 Janus refusal machinery to
the `ai-native-rag` archetype — the **J.8.c** sub-module deferred from
T5.

### J.8.c.1 — New Janus rules for `ai-native-rag` LLM providers

- **`.claude/agents/cross-layer-orchestrator.md`** "Forbidden
  archetypes & combinations" section gains **new `J8-RULE-NNN`
  sub-headings** (next sequential IDs after the live `J8-RULE-003`) :
  - one rule refusing **Vertex AI** as the default LLM provider for
    `ai-native-rag` (CLOUD Act — GCP-managed inference) ;
  - one rule refusing **AWS Bedrock** as the default LLM provider for
    `ai-native-rag` (CLOUD Act — AWS-managed inference) ;
  - one rule that, at **`--eu-tier T3`**, refuses **any US-managed
    inference endpoint** (Vertex / Bedrock / OpenAI-direct /
    Anthropic-direct without an EU-jurisdiction gateway) and forces
    **Mistral-EU (Mistral on Scaleway) or self-hosted vLLM**.
  Each rule cites its rationale + the `compliance-tiers.md` §10.2
  matrix row + the `llm-gateway.md` standard + an actionable
  alternative, mirroring the `J8-RULE-001..003` shape verbatim.
- The new rules sit in their **own** sub-section of "Forbidden
  archetypes & combinations" so they do not collide with the sibling
  `b7-pythia` brick (see Scope Out / collision note).

### J.8.c.2 — `forbidden_combinations:` sibling registry

- **`.forge/scaffolding/dispatch-table.yml`** gains a NEW top-level
  `forbidden_combinations:` list (sibling to the existing
  `forbidden_archetypes:`), per `janus-orchestration-rules.md`
  "Extending the catalogue" step 1. Each entry carries
  `archetype` / `provider` / `tier` (or `tier: any`) / `reason` /
  `since` / `alternative` / `rule_id` — a superset of the
  `forbidden_archetypes:` 5-key shape adding the combination keys.
- Seed entries are the new `J8-RULE-NNN` rules : Vertex (any tier as a
  default), Bedrock (any tier as a default), and US-managed inference
  at T3.

### J.8.c.3 — Combination-refusal wrapper helper

- **`bin/_forge-init-helpers.sh`** gains a new
  `_refuse_if_forbidden_combination "<archetype>" "<provider>"`
  function alongside the existing `_refuse_if_forbidden` (J.8.a /
  FR-J8-022). It reads the declared tier from `$FORGE_EU_TIER` (or the
  `.forge/.forge-tier` ledger, J.8 ADR-J8-006), consults the new
  `forbidden_combinations:` list, and on a match emits the structured
  `[REFUSAL: ...]` line and exits **3** (ADR-J8-003 exit code reused).
- **`bin/forge-init-ai-native-rag.sh`** (the gated wrapper shipped by
  B.7.2 / b7-2a) sources the helper and invokes the combination check
  for its configured LLM provider — defense in depth behind the CLI
  dispatcher, mirroring FR-J8-022.
- The existing `_refuse_if_forbidden` is **NOT modified** ; the new
  function is additive (the existing helper only models archetype
  refusals and must keep its contract).

### J.8.c.4 — Standards updates

- **`.forge/standards/global/janus-orchestration-rules.md`** — the
  rule-catalogue table gains the new `J8-RULE-NNN` rows ; the
  "Extending the catalogue" prose is updated to record that the
  `forbidden_combinations:` sibling list now exists (it was previously
  described as a future possibility) ; the "Refusal vs warning
  semantics" section notes the new rules are refusals at T3 and
  default-provider refusals regardless of tier.
- **`.forge/standards/global/forbidden-components-rules.md`** (I.3) —
  the §"Persistence `forbidden_for_eu_strict:` gap (interim)" pattern
  is extended : the new LLM-provider tokens (`vertex-ai`, `bedrock`)
  are added to `global/compliance-tiers.md::forbidden:` (currently
  `[]`) so the generic T3-forbidden linter (`T3-RULE-005`,
  review-time, tier-scaled WARN/FAIL) catches them in working-tree
  manifests — **complementary** to the scaffold-time Janus refusal
  (exit 3). A `REMEDIATION` map entry for the new tokens is added in
  `constitution-linter.sh::ADR-I3-001`. This ties the two surfaces
  together exactly as `compliance-tiers.md` already does for
  J8-RULE-002/003 ↔ K3 ↔ T3-RULE.
  `[NEEDS CLARIFICATION]` if the maintainer prefers to keep I.3
  untouched and ship the linter coupling as a separate follow-up —
  tracked in `open-questions.md`.

### J.8.c.5 — Test harness

- New **`.forge/scripts/tests/b7-9.test.sh`** (grep-based, mirroring
  `j8.test.sh` + `i3.test.sh` layout) :
  - **L1 (hermetic grep)** : new `J8-RULE-NNN` anchors present in the
    agent file ; `forbidden_combinations:` top-level key + entry shape
    in `dispatch-table.yml` ; `_refuse_if_forbidden_combination`
    function in the helper ; wrapper sources + invokes it ;
    `[REFUSAL:` format present ; the new catalogue rows in the J.8
    standard ; the new tokens in `compliance-tiers.md::forbidden:` +
    `REMEDIATION` map.
  - **L2 (fixture)** : a synthetic target tree declaring an
    `ai-native-rag` scaffold with a Vertex/Bedrock provider at T3 →
    asserts exit 3 + `[REFUSAL:` ; and a T1/T2 informational path that
    does NOT refuse the default-provider check beyond the
    always-refused default (tier-scaled severity, mirroring
    `i3.test.sh::_test_i3_l2_t1_warn_only`).
- Registered in `.github/workflows/forge-ci.yml` `harnesses=( … )`
  array as `"b7-9.test.sh --level 1,2"`.

## Scope In

- New `J8-RULE-NNN` entries (Vertex default-refusal, Bedrock
  default-refusal, T3 US-managed-inference refusal) in
  `.claude/agents/cross-layer-orchestrator.md`.
- New `forbidden_combinations:` top-level list in
  `.forge/scaffolding/dispatch-table.yml`.
- New `_refuse_if_forbidden_combination` helper in
  `bin/_forge-init-helpers.sh` (additive ; existing
  `_refuse_if_forbidden` untouched).
- `bin/forge-init-ai-native-rag.sh` sources + invokes the new helper.
- `.forge/standards/global/janus-orchestration-rules.md` catalogue +
  prose updates.
- `.forge/standards/global/forbidden-components-rules.md` interim-gap
  extension + `compliance-tiers.md::forbidden:` token additions +
  `constitution-linter.sh::ADR-I3-001` `REMEDIATION` entries
  (pending Q on coupling, see open-questions.md).
- New consolidated-spec append : the J.8.c block APPENDED to the
  existing `.forge/specs/janus-rules.md` (precedent : `ai-native-rag.md`
  accumulates per-brick blocks ; the J.8.c sub-module was explicitly
  pre-announced in `janus-rules.md` lines 14-17 as a follow-up).
- New harness `.forge/scripts/tests/b7-9.test.sh` (≥ N L1 + 2 L2) +
  `forge-ci.yml` registration.
- Doc updates : `docs/ARCHETYPES.md` (LLM-provider refusal note) +
  `CHANGELOG.md`.

## Scope Out (Explicit Exclusions)

- **NOT** the Pythia agent (`b7-pythia`, K.2) — that brick ships the
  embeddings/pgvector/MCP/prompt-audit *agent persona*. **COLLISION
  NOTE** : Pythia and this brick both edit
  `.claude/agents/cross-layer-orchestrator.md`. This brick keeps all
  deltas inside the existing **"Forbidden archetypes & combinations"**
  H2 section (new `J8-RULE-NNN` sub-headings only) ; Pythia's deltas
  land in the **"Dispatch Table"** rows (new Pythia routing row).
  Distinct sections, no overlap — flagged explicitly in design.md.
- **NOT** the AI Act / DORA compliance templates (`b7-5-ai-act`,
  B.7.5 + B.7.8) — model cards, risk classification, opt-out training
  are a separate brick.
- **NOT** any change to the `ai-native-rag` schema, templates, or the
  scaffolder backbone (B.7.1 / B.7.2 / B.7.2a already archived) — this
  brick only adds refusal rules + the wrapper hook.
- **NOT** promotion of `ai-native-rag` to `stable` / `scaffoldable:
  true` — that is gated on `b7-6-harness` (ADR-B7-1-002). The wrapper
  stays gated (exit 3 while candidate) ; the combination check is
  additive defense-in-depth for when it promotes.
- **NOT** runtime enforcement of the LLM provider at *application
  runtime* (the gateway's own kill-switch / budget logic shipped by
  B.7.2 FR-B7-2-014) — this brick is **scaffold-time** refusal only.
- **NOT** automatic detection of the provider from a deployed cluster
  — Janus refuses what the user *declares*, not what the cluster *is*
  (Demeter K.3 concern, mirroring `j8-janus-rules` Scope Out).
- **NOT** a new compliance tier or any amendment to the `[T1, T2, T3]`
  enum (`compliance-tiers.md` Interdiction 2 — Article XII).

## Impact

- **Users affected** :
  - Adopters scaffolding `ai-native-rag` with a Vertex AI / Bedrock
    LLM provider get a clear CLOUD Act refusal pointing to Mistral-EU
    / vLLM, instead of a silently-accepted US-managed inference path.
  - Adopters at `--eu-tier T3` get a hard refusal on any US-managed
    inference endpoint at scaffold time + a complementary review-time
    linter finding (T3-RULE-005) on working-tree manifests.
  - T1 / T2 adopters keep the OpenAI/Anthropic-via-gateway path
    (matrix `⚠️ T1 max`) ; only the **default-provider** Vertex /
    Bedrock refusals fire regardless of tier (they are never an
    acceptable *default*), with the T3 rule adding the strict refusal.
- **Technical impact** : ≈ 1 new file (the harness) + ≈ 6 modified
  (agent file, dispatch-table, helper, ai-native-rag wrapper, two
  standards, the linter token map, the consolidated spec, CHANGELOG,
  ARCHETYPES.md). All additive ; no existing rule renumbered or
  removed (ADR-J8-004 numbering invariant). **Effort `S`** (plan §6.2
  B.7.9 = `S`).
- **Dependencies** :
  - `j8-janus-rules` ✅ archived — `J8-RULE-NNN` namespace, exit-3 /
    `[REFUSAL:]` convention, `_refuse_if_forbidden`,
    `janus-orchestration-rules.md`, `.forge/.forge-tier` ledger.
  - `i2-compliance-tiers` ✅ archived — §10.2 matrix (verified source
    of the Vertex/Bedrock/LLM-gateway rows), tier-severity gradient.
  - `i3-t3-forbidden-linter` ✅ archived — `T3-RULE-NNN` + generic
    `forbidden:` token enforcement + tier-scaled WARN/FAIL severity +
    `REMEDIATION` map in `constitution-linter.sh`.
  - `b7-1-schema` / `b7-2a-dispatch-register` / `b7-2-scaffolder` /
    `b7-standards` ✅ archived — the `ai-native-rag` archetype + its
    `bin/forge-init-ai-native-rag.sh` wrapper + `llm-gateway.md`
    forward-pointer (ADR-B7-3-002).
  - Independent of sibling bricks `b7-pythia`, `b7-5-ai-act`,
    `b7-10-streaming`, `b7-7-example`, `b7-6-harness` except for the
    flagged `cross-layer-orchestrator.md` co-edit collision.
  - No new external dependency. Helper uses the same bash + PyYAML
    inline pattern as `_refuse_if_forbidden` (ADR-J8-005).
- **Risk level** : **Low**. All deltas additive ; the existing
  `_refuse_if_forbidden` contract is preserved (new function, not a
  modification) ; the wrapper is already gated (exit 3 while
  candidate) so the combination check has no behaviour-changing effect
  on a fresh `forge init` today. The one cross-cutting edit
  (`compliance-tiers.md::forbidden:` + linter `REMEDIATION`) is gated
  behind an open question and can be deferred without blocking the
  core J.8.c refusal rules.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 writes `b7-9.test.sh` with the
L1 grep stubs + L2 fixtures returning `_not_implemented` (full RED
witness). Phase 2 implements one cluster at a time. (Planning brick
stops before any test body or production code is written.)

### Article II — BDD

User-facing CLI behaviours (the new scaffold-time refusals) get
Gherkin scenarios in `specs.md` / `features/` :
- `Given an ai-native-rag scaffold requesting Vertex AI as default LLM provider, When the wrapper runs, Then it exits 3 with the CLOUD Act rationale and the Mistral-EU / vLLM alternative.`
- `Given --eu-tier T3 + a US-managed inference endpoint, When the wrapper runs, Then it exits 3 forcing Mistral-EU or self-hosted vLLM.`
- `Given --eu-tier T1 + OpenAI-via-gateway, When the wrapper runs, Then no refusal fires (matrix ⚠️ T1 max).`

### Article III — Specs Before Code

`/forge:specify` writes the `FR-B7-9-*` namespace into `specs.md`
before any implementation ; the J.8.c block is APPENDED to
`.forge/specs/janus-rules.md` at archive time.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Mistral-EU / vLLM are **verified** against `compliance-tiers.md` §10.2
(matrix row `LLM Gateway`, forcing note `Pour T3 : Mistral on Scaleway
ou vLLM self-host`) — no fabrication. Genuine open questions (rule-ID
allocation count, the I.3 linter-coupling scope, the precise provider
token strings) are tracked in `open-questions.md` and resolved at
`/forge:design`.

### Article V — Constitutional Compliance Gate

Each task tagged `[Story: FR-B7-9-XXX]`. Refusal stderr lines carry
the new `J8-RULE-NNN` IDs (ADR-J8-004 namespace), machine-parseable.

### Article XI — AI-First Design

The new rules ENFORCE the EU-sovereign LLM-provider posture for
AI-first archetypes : XI.5 (mandatory fallback — Mistral-EU / vLLM is
the sovereign fallback to US-managed inference) and XI.6 (PII /
data-minimisation — refusing US-managed inference at T3 keeps prompt
PII inside EU jurisdiction). The rules do NOT alter the AI-first
*process* (B.7.1 phases) ; they constrain the *provider choice*.

### Article XII — Governance

The new Janus rules ENFORCE the Schrems II / CLOUD Act positioning
encoded in `compliance-tiers.md` §10.2 + `docs/ARCHITECTURE-TARGET.md`.
They do **not amend** any constitutional article. The
`forbidden_combinations:` sibling list + the new rule IDs proceed via
the normal change pipeline per `janus-orchestration-rules.md`
"Extending the catalogue" (additions are not amendments). Adding the
LLM-provider tokens to `compliance-tiers.md::forbidden:` is a SemVer
minor bump of that standard (additive matrix-token enforcement) with a
`REVIEW.md` entry — pending the open-question resolution.

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : one (the I.3 linter
coupling scope, in J.8.c.4). Open questions Q-001..Q-004 raised at this
phase, all tracked in `open-questions.md` and resolved during
`/forge:design`.
