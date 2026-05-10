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

The full rule body (rationale, alternative, reference) lives in
the runtime registry (`dispatch-table.yml::forbidden_archetypes`)
and is mirrored verbatim in the agent file's "Forbidden archetypes
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
which are **warnings**. As of v0.4.0, all three seed rules
(`J8-RULE-001..003`) are refusals.

## Extending the catalogue

Adding a new rule requires :

1. **Append a new entry** to
   `.forge/scaffolding/dispatch-table.yml::forbidden_archetypes`
   (or to a sibling `forbidden_combinations:` list when the future
   J.8 extension lands non-archetype refusals like
   "T3 + ai-native-rag forces Mistral-EU"). Entry MUST carry
   `name` / `reason` / `since` / `alternative` / `rule_id` keys.
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
