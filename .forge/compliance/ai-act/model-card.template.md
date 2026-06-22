<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->
# AI Act — Model Card (template)
<!--
Adopter-fillable skeleton. This template provides the STRUCTURE of a model
card; it does NOT assert a specific legal duty. Fill it before build and ship
it alongside the deployment.

[NEEDS CLARIFICATION: the specific AI Act bias-evaluation obligation and which
deployments it binds — Themis (K.5) to supply; this template provides the
structure, not the legal trigger.]

Pattern: mirrors `.forge/templates/compliance/forge-dpa-declared.template`
(header-comment → instructions → fillable skeleton → commented example).
-->

## Instructions

1. Copy this template, remove the `<FILL: ...>` placeholders, and complete each
   field with your model's details.
2. Keep the card current as the model behind the gateway changes (re-issue on a
   model swap).
3. The "Known-bias notes" + "Evaluation method" fields are where a deployer
   records the bias-evaluation evidence; the binding legal duty is a Themis
   Phase-B determination (see the header marker).

## Model identity & provenance

- Model name / version: `<FILL: e.g. mistral-large-2411>`
- Provider / hosting: `<FILL: e.g. Mistral on Scaleway (EU) / vLLM self-host>`
- Gateway routing tier: `<FILL: T1 | T2 | T3>`

## Intended use

- Primary use case: `<FILL: e.g. retrieval-augmented Q&A over tenant documents>`
- Out-of-scope uses: `<FILL: uses the deployer explicitly does not support>`

## Limitations

- Known limitations: `<FILL: hallucination risk, context-window limits, language coverage>`

## Known-bias notes

- `<FILL: documented bias observations + mitigations>`

## Evaluation method

- `<FILL: how the model was evaluated (datasets, metrics, reviewers)>`

<!--
Canonical example (commented — delete when filling):

## Model identity & provenance
- Model name / version: mistral-large-2411
- Provider / hosting: Mistral on Scaleway (EU)
- Gateway routing tier: T3
-->
