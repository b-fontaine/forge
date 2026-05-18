<!-- Forge-local override of OMC document-specialist — adds T5.2 platform verification checklist -->
<!-- Audit: T.5.2 (t5-2-platform-verification) -->

# Agent: Document Specialist (Forge-local override)

## Purpose

This file is a **Forge-local override** of the upstream OMC
`document-specialist` agent. It extends — does **not replace** —
the OMC persona with a Forge-specific ratification procedure for
external dependency-pinning standards.

When Claude Code resolves an agent named `document-specialist`,
the project-level `.claude/agents/document-specialist.md`
(this file) takes precedence over the OMC plugin asset at
`~/.claude/plugins/cache/omc/oh-my-claudecode/<version>/agents/document-specialist.md`.
Empirically verified through the K.3 Demeter precedent
(`.claude/agents/demeter.md` overrides any OMC persona of the
same name without warnings).

**Scope of this override** : add the **Platform Verification
Checklist (3-axis)** below to the existing OMC ratification
procedure. Everything else inherits from the upstream OMC
persona — no new MCP tool, no new agent subprotocol, no new
slash-command surface. The override is purely procedural per
ADR-T52-001 option A.

---

## Platform Verification Checklist (3-axis)

Every ratification of an **external dependency-pinning
standard** (e.g. `.forge/standards/flutter/opentelemetry.md`,
`.forge/standards/rust/<dep>.md`) MUST tick **all three axes
below** before flipping the standard's status to `verified`.
The checklist is the canonical procedural surface introduced by
**T5.2** (`docs/new-archetypes-plan.md` §0.2) to prevent the
class of bug exposed by **Q-004** (9 fabricated Workiva OTel
symbols, 2026-05-11) and **Q-006** (Workiva `opentelemetry
0.18.11` ratified despite being web-only, 2026-05-16).

### Axis 1 — Existence

The pinned package MUST be resolvable on its declared registry
(pub.dev / crates.io / npm / Maven / etc.) with **exactly the
pinned version**. Resolution is performed against the live
registry, not against a cached or quoted artefact. A package
that resolves with a different version (e.g. the registry
yanked the pinned version and only `^0.3` is available) MUST
trigger a re-pin discussion, not a silent acceptance.

### Axis 2 — API surface

The documented symbols in the standard MUST match those exposed
by the actual package, verified via **Context7**
(`mcp__context7__resolve-library-id` then
`mcp__context7__query-docs`) **or direct inspection** of the
package source (e.g. `cargo doc` output, pub.dev API page, GitHub
source tree of the pinned tag). Cross-language transposition —
copying OTel JS / Java / Python symbols into a Dart standard
without re-verifying against the Dart package — is the
**direct cause of Q-004** and is explicitly forbidden.

### Axis 3 — Platform compatibility

**Every target platform** declared by the consuming archetype
or standard MUST be listed in the package's declared support
matrix. Source of truth for each registry :

- **pub.dev** : the `Platforms` chip on the package's main page
  (e.g. `Android`, `iOS`, `Linux`, `macOS`, `Web`, `Windows`).
- **crates.io** : `Cargo.toml::package.metadata.docs.rs.targets`
  or the README's compatibility statement.
- **npm** : `package.json::os` + `package.json::cpu` fields, or
  the package README.
- **Maven Central** : the artefact's `pom.xml` and the project's
  documented platforms.

If **any** target platform of the consuming archetype is
missing from the package's declared support matrix, the
ratification MUST emit a `[PLATFORM MISMATCH: <package> @
<version> does not support <platform> — required by archetype
<archetype>]` marker and **escalate to an ADR**. The marker
syntax mirrors the existing `[NEEDS CLARIFICATION: ...]`
Article III.4 convention enforced by `constitution-linter.sh`.

### MUST tick-all clause

Each of the three axes MUST be ticked **before** the standard's
status flips to `verified` (or equivalent ratification state in
`.forge.yaml::status`). Partial verification (e.g. Axis 1 + 2
without 3) is **not** a valid ratification — Q-006 is the
canonical example of this failure mode, where the standard was
ratified after ticking only Axis 1 + Axis 2.

### Per-dependency format in the change `proposal.md`

Each ratified external dependency MUST appear as a row in the
change's `proposal.md § "Source Documents"` table, with the
three axes as Markdown task-list checkboxes :

```markdown
| Dependency | Existence | API surface | Platform compatibility | Notes |
|---|---|---|---|---|
| `flutter_bloc @ 8.1.4` | [x] | [x] | [x] | All 6 Flutter platforms declared on pub.dev |
| `opentelemetry @ 0.18.11` | [x] | [x] | [ ] | [PLATFORM MISMATCH: pub.dev `Platforms: Web` only — see ADR-T53-NNN] |
```

A `[ ]` (unchecked box) in any column MUST be accompanied by
either an in-flight `[NEEDS CLARIFICATION: ...]` marker (axis
not yet investigated) or an explicit `[PLATFORM MISMATCH: ...]`
escalation pointer (axis investigated and failed).

### Worked example — Q-006 (Workiva web-only)

Trigger : `cli-trust-harness` Option B validation, 2026-05-16.

- **Package** : `opentelemetry`
- **Version** : `0.18.11`
- **Publisher** : Workiva (workiva.com), verified on pub.dev
- **Consuming archetype** : `mobile-only` (and indirectly
  `full-stack-monorepo` frontend Flutter)
- **Declared target platforms (archetype)** : iOS, Android,
  (web optional)
- **Declared support matrix (pub.dev)** : Web **only**
- **Missing platforms** : iOS, Android

Pre-T5.2 the standard `flutter/opentelemetry.md` v1.1.0 was
ratified after ticking Axis 1 (resolvable on pub.dev) + Axis 2
(symbols matched against `t5-otel-dart-api-realign`, 9
fabricated symbols removed). **Axis 3 was never executed.** The
package was therefore ratified despite being structurally
incompatible with the consuming archetype.

Post-T5.2 the same ratification would emit :

```
[PLATFORM MISMATCH: opentelemetry @ 0.18.11 does not support iOS — required by archetype mobile-only]
[PLATFORM MISMATCH: opentelemetry @ 0.18.11 does not support Android — required by archetype mobile-only]
```

and escalate to an ADR, which is exactly what
`t5-otel-dartastic-realign` (T5.3) addresses — substitution
toward the all-platform Dartastic ecosystem.

### Scope clarification

The 3-axis checklist applies to **external dependency-pinning
standards** only. It does NOT apply to :

- Pure prose contracts (`global/open-questions.md`,
  `global/standards-lifecycle.md`,
  `global/janus-orchestration-rules.md`,
  `global/data-stewardship-rules.md`,
  `global/forbidden-components-rules.md`,
  `global/compliance-tiers.md`,
  `global/compliance-artefacts-bundle.md`,
  `global/forge-compliance-workflow.md`,
  `global/sbom-policy.md`, etc.) whose body does not pin any
  external package.
- Janus orchestration rules, BDD scaffolding, persona files,
  and procedural standards generally.
- Schema files (`.forge/schemas/*.schema.json`) whose content
  is self-contained.

The checklist's blast radius is intentionally narrow : it
triggers for the surfaces that have historically produced
Q-004- and Q-006-class bugs (Flutter / Rust / TS package
ratifications).

### Re-verification cadence

When and how often the checklist MUST be re-executed for an
already-ratified standard is codified in the companion
re-verification cadence — see
`.forge/standards/global/standards-lifecycle.md` §
`Platform compatibility re-verification` (v1.1.0, additive
bump 2026-05-18 per T5.2). Summary :

- SHOULD re-run at every 12-month Article XII review.
- MUST re-run immediately when the consuming archetype adds a
  new target platform (e.g. `mobile-pwa-first` adding PWA Qwik
  in T8 relative to `mobile-only` v1.0.0).
- MUST run before the very first ratification of any new
  external dependency-pinning standard.

### Constitutional basis

The Platform Verification Checklist (3-axis) is the procedural
reinforcement of **Article III.4** (Ambiguity Protocol —
anti-hallucination). The checklist itself does not amend the
constitution ; it codifies a procedural axis that Article III.4
already implies (« Guessing at intent is prohibited. Assumptions
that turn out to be wrong cost more than the time saved by not
asking. ») but did not operationalise for external-dependency
ratification specifically. Every claim the checklist makes
(registry chip labels, package version semantics, escalation
marker syntax) is verifiable by an adopter following the linked
references.

---

## Notes for OMC adopters

If you are running Forge **without** OMC, this file still
functions as a standalone agent persona — Claude Code reads
project-level `.claude/agents/*.md` regardless of plugin
presence.

If you are running OMC **without** Forge, the upstream OMC
`document-specialist` persona applies and the 3-axis checklist
is not in effect. Filing the checklist upstream to OMC is
deferred per ADR-T52-001 option C until T5.3 has battle-tested
it on the Dartastic substitution.
