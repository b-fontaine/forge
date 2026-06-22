<!-- Audit: B.7.5+B.7.8 (b7-5-ai-act) -->
# AI Act — Dataset Card (template)
<!--
Adopter-fillable skeleton for a dataset / knowledge-base card. This template
provides the STRUCTURE of a dataset card; it does NOT assert a specific legal
duty. Fill it before build and ship it alongside the deployment.

[NEEDS CLARIFICATION: the specific AI Act bias-evaluation obligation for
training / retrieval data and which deployments it binds — Themis (K.5) to
supply; this template provides the structure, not the legal trigger.]

Pattern: mirrors `.forge/templates/compliance/forge-dpa-declared.template`.
-->

## Instructions

1. Copy this template, remove the `<FILL: ...>` placeholders, and complete each
   field for the dataset / knowledge base your RAG deployment indexes.
2. Re-issue when the dataset materially changes (new sources, re-ingestion).
3. The "Known-bias notes" + "Evaluation method" fields are where a deployer
   records dataset-bias evidence; the binding legal duty is a Themis Phase-B
   determination (see the header marker).

## Dataset identity

- Dataset / knowledge-base name: `<FILL: e.g. tenant-policy-corpus-2026>`
- Version / snapshot date: `<FILL: ISO-8601 date>`

## Source & licence

- Source(s): `<FILL: where the data came from>`
- Licence / usage rights: `<FILL: licence terms governing the data>`

## Training-data / retrieval-data description

- Composition: `<FILL: document types, languages, volume>`
- Preprocessing: `<FILL: chunking, embedding model, redaction steps>`

## Known-bias notes

- `<FILL: documented dataset bias observations + mitigations>`

## Evaluation method

- `<FILL: how dataset quality / bias was evaluated>`

<!--
Canonical example (commented — delete when filling):

## Dataset identity
- Dataset / knowledge-base name: tenant-policy-corpus-2026
- Version / snapshot date: 2026-06-01
-->
