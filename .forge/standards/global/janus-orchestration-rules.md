# Standard — Janus Orchestration Rules

<!-- Audit: J.8 (j8-janus-rules) -->
<!-- Trigger: scaffolding, refusal, forbidden, schrems, cloud-act, eu-tier -->

## Purpose

The Janus cross-layer orchestrator agent
(`.claude/agents/cross-layer-orchestrator.md`) carries a set of
**refusal rules** that enforce Forge's EU-strict / premium
positioning at scaffolding time. This standard documents the rule
catalogue, the refusal semantics, the relationship between the
catalogue and the runtime registry
(`.forge/scaffolding/dispatch-table.yml::forbidden_archetypes`),
and the process for extending the catalogue.

The runtime registry is the **single source of truth** consulted
at scaffold time. The agent file is the **narrative documentation**
that surfaces the rules to humans (and to AI agents reading the
repo). Both MUST stay in sync — extension procedure below.

## Rule catalogue

| Rule ID       | Trigger                                | Refusal target                                  | Reference                              |
|---------------|----------------------------------------|-------------------------------------------------|----------------------------------------|
| `J8-RULE-001` | `--archetype flutter-firebase`         | scaffold of flutter-firebase                    | ADR-007 ; archetype.schema.json v2     |
| `J8-RULE-002` | `--eu-tier T3` + non-self-host Zitadel | cloud-Zitadel + Auth0 + Keycloak-cloud variants | ADR-007 ; identity.yaml                |
| `J8-RULE-003` | `--eu-tier T3` + Datadog or SigNoz Cloud SaaS | Datadog exporter + signoz.io endpoints   | ADR-008 ; observability.yaml           |
| `J8-RULE-004` | `ai-native-rag` + Vertex AI default LLM provider | Vertex AI (GCP-managed inference) as default | compliance-tiers.md §10.2 (`AWS / GCP / Azure` + `LLM Gateway`) ; llm-gateway.md ; ADR-B7-9-001 |
| `J8-RULE-005` | `ai-native-rag` + AWS Bedrock default LLM provider | Bedrock (AWS-managed inference) as default | compliance-tiers.md §10.2 (`AWS / GCP / Azure` + `LLM Gateway`) ; llm-gateway.md ; ADR-B7-9-001 |
| `J8-RULE-006` | `ai-native-rag` + `--eu-tier T3` + US-managed inference | US-managed inference endpoints at T3 | compliance-tiers.md §10.2 (`LLM Gateway` → `Pour T3 : Mistral on Scaleway ou vLLM self-host`) ; ADR-B7-9-001/006 |

The full rule body (rationale, alternative, reference) lives in
the runtime registry — `dispatch-table.yml::forbidden_archetypes`
for whole-archetype refusals (`J8-RULE-001`), and the sibling
`dispatch-table.yml::forbidden_combinations` for provider × tier
refusals (`J8-RULE-004..006`, J.8.c `b7-9-janus-ai`) — and is
mirrored verbatim in the agent file's "Forbidden archetypes
& combinations" section.

## Adoption path

When an adopter hits a refusal, the wrapper exits with code **3**
and emits a structured stderr line :

```
[REFUSAL: <archetype>: <rule_id>: <reason> ; alternative: <alt>]
```

The `alternative` field is mandatory in every rule entry — every
refusal MUST point to an actionable next step. Adopters reading
the line know :
- which archetype was refused (`<archetype>`),
- which rule fired (`<rule_id>`, kebab-case anchor matching the
  agent file + this standard),
- why (`<reason>`, one-line rationale),
- what to do instead (`<alternative>`).

For `J8-RULE-001` (flutter-firebase) : the `default` archetype is
the alternative, with adopter-managed Firebase overlays (out of
Forge scope).

For `J8-RULE-002` / `J8-RULE-003` (T3 enforcement) : the
alternative is to deploy the underlying service (Zitadel / SigNoz)
on EU-jurisdiction infrastructure self-hosted.

## Refusal vs warning semantics

J.8 distinguishes **refusal** from **warning** :

- **Refusal** (exit 3, blocking) — the request is syntactically
  valid but the policy refuses it. No scaffolding side-effect
  occurs in the target tree. Used when the requested combination
  cannot be reconciled with the EU compliance posture (e.g.
  cloud Zitadel at T3).

- **Warning** (exit 0, non-blocking) — the request proceeds but
  emits a single-line `[INFO: ...]` stderr message advising
  caution or signaling future deprecation. Used for soft signals
  (e.g. `--eu-tier` flag missing on production-bound projects).

The Janus rule catalogue documents which rules are **refusals** and
which are **warnings**. The seed rules (`J8-RULE-001..003`) are all
refusals. J.8.c (`b7-9-janus-ai`) adds three more refusals for the
`ai-native-rag` LLM gateway : `J8-RULE-004` (Vertex AI) and
`J8-RULE-005` (AWS Bedrock) are **default-provider** refusals that
fire regardless of declared tier ; `J8-RULE-006` is a **T3-only**
refusal of US-managed inference. All six rules (`J8-RULE-001..006`)
are refusals — no warning-class rule has shipped yet.

## Extending the catalogue

Adding a new rule requires :

1. **Append a new entry** to
   `.forge/scaffolding/dispatch-table.yml::forbidden_archetypes`
   (for whole-archetype refusals — entry MUST carry
   `name` / `reason` / `since` / `alternative` / `rule_id` keys), OR
   to the sibling `forbidden_combinations:` list for non-archetype
   provider × tier refusals. That sibling list **now exists** — it
   landed with J.8.c (`b7-9-janus-ai`, the "T3 + ai-native-rag forces
   Mistral-EU" case foreseen here) and carries a 7-key shape
   (`archetype` / `provider` / `tier` / `reason` / `since` /
   `alternative` / `rule_id`), consumed by
   `_refuse_if_forbidden_combination` (`bin/_forge-init-helpers.sh`).
2. **Mirror the entry** in the agent file's "Forbidden archetypes
   & combinations" section under a new `J8-RULE-NNN` H4 sub-heading.
   Use the next available sequential ID.
3. **Mirror the row** in the rule catalogue table of this standard.
4. **Add a test** in `.forge/scripts/tests/j8.test.sh` (or its
   successor) asserting the refusal fires for the targeted
   request.
5. **Reference the motivating source** — every rule MUST cite
   either an ADR from `docs/ARCHITECTURE-TARGET.md` OR a Forge
   standard (`.forge/standards/*.yaml` or
   `.forge/standards/global/*.md`). Free-form rules without a
   sourced rationale are rejected (Article XII governance).
6. **Document the alternative** — adopters MUST have a clear
   actionable next step. Refusals without alternatives are
   anti-patterns.

For non-J.8 audit modules (e.g. K.3 Demeter agent rules when that
ships), use the audit-prefix convention `K3-RULE-NNN`,
`I2-RULE-NNN`, etc.

## Governance

This standard is `.forge/standards/global/janus-orchestration-rules.md`
— governed by `global/standards-lifecycle.md` (T.4) like every
other Forge standard. The 12-month review cycle applies. Amendments
to the rule catalogue follow Article XII (Constitution) governance
when they alter the refusal semantics ; new rule additions per the
extension process above are not amendments and proceed via the
normal change pipeline.
