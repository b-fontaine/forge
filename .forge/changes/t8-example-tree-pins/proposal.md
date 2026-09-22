# Proposal — `t8-example-tree-pins`

`t7-qwik-deps-refresh` Q-004: the shipped reference tree
`examples/forge-rag-example/frontend/web-public/` still resolves the vulnerable `sharp`,
still lacks the `ignore` devDependency its Qwik CLI needs, and still pins `vite =7.3.5`.
It ships inside `@sdd-forge/cli` under `assets/examples/`, so an adopter who copies the
reference gets the defects the templates no longer have.

## Why it was missed twice

Not an oversight — a structural blind spot. Both guards that own those pins discover
their surfaces the same way:

```
find "$FORGE_ROOT/.forge/templates" -name 'package.json.tmpl'
```

A rendered example lives under `examples/` and is named `package.json`. It is invisible
to that root twice over, so `t5-qwik-cli-ignore-dep` (2026-09-09) and both passes of
`t7-qwik-deps-refresh` swept "every Qwik surface" and never saw it. The standard says
`web-frontend.yaml:76` "Every surface writes ..." and the harness header says T-014
"holds every surface" — both false as written while the discovery root excludes
`examples/`.

## Measured drift

Rendering `ai-native-rag/1.0.0/frontend/web-public/**.tmpl` with `<project-name>` =
`forge-rag-example` and diffing against the committed example: **exactly three files
differ** — `package.json`, `README.md`, `vite.config.ts` — and no file is missing or
extra. So "re-render the subtree" and "replace those three files" are the same change.

`examples/forge-eda-example` is in template parity (47 files, zero drift). The rag tree
is the outlier, not a systemic example problem.

## Scope

**In:** the three drifted files; widening `b8-9::T-013` and `::T-014` discovery to a
second root (`examples/**/package.json`) with a scoped anti-vacuity floor, so the next
pin move cannot skip the examples again; the records (CHANGELOG, roadmap, plan) and the
standard/harness sentences that claim "every surface".

**Out:** `examples/forge-rag-example`'s `connect-client.ts` import defect (Q-006) — it is
byte-identical to the template, so it belongs to the codegen brick that fixes both;
`examples/forge-fsm-example`'s ten-file drift from a 1.0.0 render and its
`clients/connect-client.ts` (recorded here as open questions); a generic
example↔template parity guard (NFR-EX-001, never implemented); an `npm audit` step in
CI (`t7-qwik-deps-refresh` Q-001, a CI-policy call).

## Negative scope

MUST NOT move any pin: the example follows the templates, it does not lead them. MUST
NOT re-render files that do not drift. MUST NOT let the widened discovery pass
vacuously if `examples/` stops matching.
