# Specifications: k4-iris-web
<!-- Status: specified -->
<!-- Schema: default -->

**Namespace** : `FR-K4-IW-*` / `NFR-K4-IW-*` (matches the `FR-K4-*`
umbrella ; `IW` = Iris-Web, mirroring the `FR-K3-DEM-*` sub-token
style). **Constitution** : v2.0.0. No amendment required (K.4
introduces a new agent + conventions standard ; existing articles
unchanged).

## Source Documents

| Field             | Value                                                                                                                                                        |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Audit base**    | `K.4` (`new-archetypes-plan` §9 line 2671 — K-modules table ; §0.13 line 2845 — agent file list)                                                              |
| **ADR base**      | `b8-9-qwik-web-public` archived 2026-06-03 (ADR-005 KEEP-Flutter/REPLACE-web→Qwik ; ships `web-frontend.yaml` v1.0.0 + the `frontend/web-public/` surface) ; `b7-10-streaming` (Connect-ES streaming client precedent) ; `j8-janus-rules` (ADR-J8-004 `<MODULE>-RULE-NNN` format) |
| **Plan ref**      | `docs/new-archetypes-plan.md` §9 line 2671 (K.4 row) + §0.13 line 2845 ; `docs/ARCHITECTURE-TARGET.md` §9.2 lines 734 + 743 + §5 ADR-005 lines 365-374        |
| **Standard reuse**| `.forge/standards/web-frontend.yaml` v1.0.0 (version pins — single source of truth, consumed by reference) ; `transport.yaml` v1.3.0 (`@connectrpc/connect` `^2.0.0` codegen pins) |
| **Pattern reuse** | `k3-demeter` (persona H2 structure ; standard MD shape ; `<MODULE>-RULE-NNN` catalogue ; k3.test.sh harness layout) ; `b7-pythia`/`sibyl.md` (advisory readiness-report specialist shape) |
| **Precedent refs**| B.8.9 `2.0.0/frontend/web-public/` 10-file Qwik City skeleton (`entry.ssr.tsx`, `root.tsx`, `routes/index.tsx`, `lib/connect-client.ts`) ; B.7.10 `connect-client.ts` `queryStream()` `for await` + `useVisibleTask$` cancel-on-unmount ; T5.3.3 `t5-3-3-vitest-bundle-preflight` Vitest wiring |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Iris-Web persona file (FR-K4-IW-001 → 009)

##### FR-K4-IW-001 — Persona file location

`.claude/agents/iris-web.md` MUST exist as the canonical Iris-Web
persona file at the flat `.claude/agents/<name>.md` path used by all
top-level Forge specialists (e.g. `demeter.md`, `sibyl.md`).

##### FR-K4-IW-002 — Persona section

The file MUST start with an H1 `# Agent: Frontend Web Specialist
(Iris-Web)` and a `## Persona` H2 declaring :
- **Name** : Iris-Web (the messenger who carries content to the open
  web — the natural patron of the public-facing, SEO-visible surface).
- **Role** : frontend web specialist — maintains the Qwik / SvelteKit
  web-frontend conventions for the `frontend/web-public/` surface,
  distinct from Hera (Flutter).
- **Style** : convention-first, evidence-driven, resumability-biased.
  Mirrors the Demeter/Sibyl stylistic pattern — every finding carries
  a severity, specific evidence, and an actionable recommendation.

##### FR-K4-IW-003 — Purpose section

A `## Purpose` H2 MUST describe Iris-Web's responsibilities and
explicitly cite the source audit items (K.4) and the upstream surfaces
it consumes (`web-frontend.yaml`, the B.8.9 skeleton, the B.7.10
streaming precedent).

##### FR-K4-IW-004 — Checklists section

A `## Checklists` H2 MUST host at least four sub-sections (H3) :
- **Resumability & Rendering**
- **Routing & SSR-SSG Boundaries**
- **Connect-ES & Streaming**
- **Components & Vitest Testing**

Each sub-section MUST follow the Aegis/Demeter bullet-checklist style :
`[ ] item` lines with `Verify:` / `Check:` / `Exception:` annotations,
greppable for `[ ]` markers (≥ 5 items per sub-section).

##### FR-K4-IW-005 — Output report format

An `## Output: Web Frontend Readiness Report` H2 MUST declare the
report shape :
- A `Summary` table with severity counts (`| Severity | Count |`).
- A `Findings` section with per-finding entries citing
  `[SEVERITY] <K4-RULE-NNN>: <title>`, `Category`, `Location`,
  `Evidence`, `Recommendation`, `Verification`.
- A `Cleared Items` section.
- An overall status line : `BLOCKED` / `CONCERNS` / `READY`.

##### FR-K4-IW-006 — Rule catalogue section

A `## Rule Catalogue` H2 MUST enumerate the seed `K4-RULE-*` rules
(≥ 6 rules, see Cluster 7). Each rule MUST cite : (a) trigger, (b)
severity, (c) evidence pattern, (d) recommendation, (e) cross-link to
the standard or a source ADR.

##### FR-K4-IW-007 — Integration section

A `## Integration` H2 MUST describe :
- How Janus arbitrates between Iris-Web (Qwik) and Hera (Flutter) on
  the flagship (cross-link to `cross-layer-orchestrator.md`), per
  `ARCHITECTURE-TARGET` §9.2 line 743.
- The scope boundary vs **Hera** (Hera owns Flutter mobile + desktop +
  Flutter Web back-office per ADR-005 ; Iris-Web owns the Qwik public
  web surface only — disjoint).
- The relationship to **Apollo** (Hera's Flutter UX/UI sub-agent —
  never touches the Qwik surface).
- The relationship to **Sibyl** (K.2) — Sibyl advises the
  `ai-native-rag` Qwik streaming UI ; Iris-Web owns the Qwik
  conventions that streaming UI follows.

##### FR-K4-IW-008 — Anti-hallucination protocol

A `## Anti-Hallucination Protocol` H2 MUST state that when the owning
surface of a pin/convention is ambiguous, or when a proposed pattern
is unverifiable against the shipped surface, Iris-Web MUST emit
`[NEEDS CLARIFICATION: <specific question>]` and STOP — never guess.

##### FR-K4-IW-009 — Archetype scope declaration

The persona MUST declare its archetype scope : `full-stack-monorepo`
(the shipped Qwik web-public surface) today, forward-stable for
`mobile-pwa-first` (B.9, Pending T8) to adopt additively when it
ships. Iris-Web MUST NOT be dispatched on archetypes with no Qwik
surface.

---

#### Cluster 2 — Audit-comment header anchors (FR-K4-IW-010 → 011)

##### FR-K4-IW-010 — Audit comment

The persona file MUST carry a top-of-file
`<!-- Audit: K.4 (k4-iris-web) -->` HTML comment per the Forge
audit-trail convention.

##### FR-K4-IW-011 — Source citations + audit cross-references

The persona file MUST carry an `## Audit cross-references` H2 footer
citing the upstream sources that justify Iris-Web's existence, with
section + line refs : `ARCHITECTURE-TARGET` §9.2 lines 734 + 743, §5
ADR-005 lines 365-374 ; `new-archetypes-plan` §9 line 2671 + §0.13
line 2845.

---

#### Cluster 3 — Qwik/SvelteKit conventions codified (FR-K4-IW-020 → 026)

The conventions below are codified in BOTH the standard
(`qwik-frontend-patterns.md`) and operationalised as persona
checklists. They CODIFY the already-shipped B.8.9 + B.7.10 surface —
they do not invent new patterns.

##### FR-K4-IW-020 — Resumability conventions

The standard MUST document Qwik **resumability** (serialize-once,
resume-on-interaction, ~2 KiB eager JS per ADR-005) as the default and
MUST state that eager client hydration (React-style) is a
non-conformance. Components are authored with `component$()`, reactive
state with `useSignal()` / `useStore()`.

##### FR-K4-IW-021 — `routes/` conventions

The standard MUST document Qwik City file-based routing under
`src/routes/` : `index.tsx` route components, `routeLoader$` for
server-side data loading, `routeAction$` for mutations, `server$` for
server-only functions. Business logic in route loaders/actions, not in
the eager client path.

##### FR-K4-IW-022 — SSR/SSG boundaries

The standard MUST document the SSR/SSG boundary : `src/entry.ssr.tsx`
is the required SSR entry ; `src/root.tsx` + `routes/` render server-
side to HTML + a resumable payload ; static generation (SSG) is the
alternative for non-dynamic routes. Server-only secrets/imports MUST
NOT leak into the client bundle.

##### FR-K4-IW-023 — Connect-ES client usage

The standard MUST document the Connect-ES client per the B.7.10
precedent : a shared transport via `createConnectTransport` from
`@connectrpc/connect-web`, `createClient(Service, transport)` for the
typed client, in `src/lib/connect-client.ts`. The transport is created
once and reused — not re-instantiated per call.

##### FR-K4-IW-024 — Streaming UI conventions

The standard MUST document server-streaming consumption per B.7.10 :
`for await (const res of client.method(req))`, progressive render via a
`useSignal` mutated inside the loop, a Stop/cancel control that aborts
the stream, **cancel-on-unmount** via `useVisibleTask$` cleanup, and
exponential-backoff retry degrading to the unary path.

##### FR-K4-IW-025 — Component conventions

The standard MUST document component conventions : `component$()`
factory, `useSignal()` for local reactive state, `useVisibleTask$()`
for client-side effects with cleanup, lazy boundaries via `$()`, and
props typing. No business logic in presentational components.

##### FR-K4-IW-026 — Vitest testing conventions

The standard MUST document the Vitest testing conventions per the
T5.3.3 precedent : `vitest.config.ts`, `test/` (or co-located
`*.test.ts` / `*.spec.ts`) files, a `globalSetup` for any bundle/
preflight step, and route/component coverage expectations aligned with
the Article X 80% threshold.

---

#### Cluster 4 — Standard + dispatch integration (FR-K4-IW-080 → 085)

##### FR-K4-IW-080 — Standard file existence

`.forge/standards/global/qwik-frontend-patterns.md` MUST exist with at
least 5 H2 sections covering (at minimum) resumability, routes, SSR/SSG,
Connect-ES + streaming, components, and Vitest. Markdown only — no YAML
frontmatter (J.7 validation informational, mirrors
`data-stewardship-rules.md`).

##### FR-K4-IW-081 — Single-source-of-truth for pins

The standard MUST consume `web-frontend.yaml` v1.0.0 **by reference**
for all version pins and MUST NOT reproduce a version number (no
`^1.20.0`, no `7.3.5`, etc.). This preserves the single-source-of-truth
discipline established by the B.8.9 reference-only annotation.

##### FR-K4-IW-082 — Standards index registration

`.forge/standards/index.yml` MUST gain a new entry :
```yaml
- id: global/qwik-frontend-patterns
  path: standards/global/qwik-frontend-patterns.md
  triggers: [iris-web, qwik, qwik-city, sveltekit, resumability, routes, ssr, ssg, connect-es, streaming-ui, vitest, web-frontend-patterns, k4-rule]
  scope: frontend
  priority: high
```

##### FR-K4-IW-083 — Janus dispatch-table row (additive)

`.claude/agents/cross-layer-orchestrator.md` MUST gain a single new
row in its Dispatch Table for Iris-Web
(`frontend/web-public/` Qwik/SvelteKit work → **Iris-Web**). The row
MUST be additive : Hera's existing Flutter `frontend/` row MUST NOT be
modified, narrowed, or removed.

##### FR-K4-IW-084 — CLAUDE.md trigger registration

The repo-level `CLAUDE.md` agent-delegation table MUST gain a new row :

| Qwik / SvelteKit web frontend | **Iris-Web** | Frontend Web Specialist |

Placed additively ; Hera's `Flutter code → Hera` row MUST remain
unchanged.

##### FR-K4-IW-085 — No K4-RULE collision + Hera scope intact

The `K4-RULE-*` namespace MUST NOT collide with `J8-RULE-*` /
`K3-RULE-*` (syntactically impossible per ADR-J8-004 format, asserted
explicitly). Hera's Flutter scope MUST remain intact — the harness
asserts Hera's row still names Flutter and Iris-Web's addition is
additive.

---

#### Cluster 5 — Test harness `k4.test.sh` (FR-K4-IW-100 → 102)

##### FR-K4-IW-100 — Harness exists

`.forge/scripts/tests/k4.test.sh` MUST exist mirroring the K.3 / J.8
layout : bash header, `_helpers.sh` source, PASS/FAIL counters,
`--level 1,2` parsing, `print_summary` close-out. Registered in
`.github/workflows/forge-ci.yml` `harness` matrix.

##### FR-K4-IW-101 — L1 coverage ≥ 20 tests

Minimum 20 L1 tests covering : persona structure (exists + audit
comment + Persona/Purpose/Checklists/Output/Rule Catalogue/Integration/
Anti-Hallucination/Audit-cross-references anchors), checklist H3s with
≥ 5 `[ ]` items each, K4-RULE-001..006 anchors, the standard's
convention sections, single-source-of-truth reference, index
registration, Janus dispatch row, CLAUDE.md trigger row, Hera scope
intact, namespace separation.

##### FR-K4-IW-102 — L2 coverage ≥ 2 cross-surface tests

Minimum 2 L2 tests : (a) **catalogue-sync** — every `K4-RULE-NNN` in
the persona also appears in the standard's rule table ; (b)
**no-pin-duplication** — the standard references `web-frontend.yaml`
and does NOT contain the exact vite pin literal.

---

#### Cluster 6 — Documentation (FR-K4-IW-110 → 111)

##### FR-K4-IW-110 — `CHANGELOG.md` entry

A new entry under `## [Unreleased]` summarising the three sub-modules
(K.4.a persona, K.4.b standard, K.4.c integration).

##### FR-K4-IW-111 — `docs/GUIDE.md` agent-catalogue line

`docs/GUIDE.md` MUST gain a one-line Iris-Web mention in its agent
catalogue (mirrors the K.3 GUIDE touch).

---

#### Cluster 7 — Seed K4-RULE catalogue (FR-K4-IW-120 → 125)

The seed K.4 rule catalogue per ADR-K4-003 (6 seed rules, incremental
growth). Severity uses the advisory ladder per ADR-K4-001
(`Advisory` < `Concern` < `Blocking`).

##### FR-K4-IW-120 — K4-RULE-001 — Eager hydration instead of resumability

**Trigger** : a Qwik component eagerly hydrates client state
(React-style) instead of resuming. **Severity** : `Concern`.
**Recommendation** : refactor to `component$()` + `useSignal()`
resumability ; keep eager JS minimal per ADR-005.

##### FR-K4-IW-121 — K4-RULE-002 — Business logic outside route loaders/actions

**Trigger** : data-loading or mutation logic in the eager client path
instead of `routeLoader$` / `routeAction$` / `server$`. **Severity** :
`Concern`. **Recommendation** : move to the server-side route API.

##### FR-K4-IW-122 — K4-RULE-003 — Connect transport re-instantiated per call

**Trigger** : `createConnectTransport` / `createClient` called
per-request instead of a shared client in `lib/connect-client.ts`.
**Severity** : `Advisory`. **Recommendation** : create the transport
once and reuse it (B.7.10 precedent).

##### FR-K4-IW-123 — K4-RULE-004 — Streaming without cancel-on-unmount

**Trigger** : a server-streaming consumer (`for await`) with no
`useVisibleTask$` cleanup / AbortController — the stream leaks on
unmount. **Severity** : `Concern`. **Recommendation** : add
cancel-on-unmount per the B.7.10 precedent.

##### FR-K4-IW-124 — K4-RULE-005 — Server-only secret leaks into client bundle

**Trigger** : a server-only import/secret is referenced from the eager
client path and ships in the client bundle. **Severity** : `Blocking`
(a public web surface must never leak secrets — the single
report-status-blocking rule Iris-Web owns). **Recommendation** : move
behind `routeLoader$` / `server$` ; keep the SSR/SSG boundary clean.

##### FR-K4-IW-125 — K4-RULE-006 — Web-public route/component missing Vitest coverage

**Trigger** : a `routes/` route or shared component with no Vitest
test. **Severity** : `Advisory`. **Recommendation** : add a
`*.test.ts` per the T5.3.3 Vitest convention ; meet the Article X 80%
threshold.

---

### Non-Functional Requirements

#### NFR-K4-IW-001 — Backward compatibility

This change is purely additive. Adopters not using the Qwik
web-public surface (and Hera's Flutter scope) observe ZERO behavioural
change.

#### NFR-K4-IW-002 — Article V audit trail

Every task tagged `[Story: FR-K4-IW-XXX]`. Every Iris-Web finding
carries `K4-RULE-NNN`, machine-parseable per Article V.1.

#### NFR-K4-IW-003 — Single source of truth (no pin duplication)

The conventions standard MUST NOT reproduce any version number owned by
`web-frontend.yaml` / `transport.yaml`. Pins are referenced, never
copied. The harness asserts the exact vite pin literal is absent from
the standard.

#### NFR-K4-IW-004 — No TypeScript / no scanner / no data file

This change touches NO `cli/src/**.ts`, ships NO `bin/*.sh` scanner,
and ships NO `.forge/data/*.yml`. Iris-Web is a persona + a markdown
standard only (contrast with Demeter's scanner).

#### NFR-K4-IW-005 — Forward stability for `mobile-pwa-first`

The persona + standard MUST be written so `mobile-pwa-first` (B.9,
Pending T8) can adopt them additively without rework — e.g. by scoping
conventions to "the Qwik web surface" not "the full-stack-monorepo
web-public directory only", and by naming the PWA channel as a forward
consumer.

#### NFR-K4-IW-006 — Hera scope preserved

Hera's Flutter scope (mobile + desktop + Flutter Web back-office per
ADR-005) MUST remain intact. This change adds an owner for the Qwik
public web surface Hera never owned ; it removes nothing from Hera.

---

## BDD Acceptance Criteria

### Scenario 1 — Streaming route missing cancel-on-unmount

```gherkin
Given a frontend/web-public/ route consumes a server-streaming Connect method with `for await`
And the route has no useVisibleTask$ cleanup / AbortController
When Iris-Web reviews the route
Then the report contains 1 finding with rule_id "K4-RULE-004" and severity "Concern"
And the recommendation cites cancel-on-unmount per the B.7.10 precedent
```

### Scenario 2 — Server-only secret leaks into the client bundle

```gherkin
Given a Qwik component references a server-only secret from the eager client path
When Iris-Web reviews the SSR/SSG boundary
Then the report contains 1 finding with rule_id "K4-RULE-005" and severity "Blocking"
And the overall status is "BLOCKED"
```

### Scenario 3 — Pin ownership ambiguous

```gherkin
Given a proposed convention references a package version whose owning standard is unclear
When Iris-Web cannot resolve whether web-frontend.yaml or transport.yaml owns the pin
Then Iris-Web emits [NEEDS CLARIFICATION: pin ownership ambiguous — which standard owns <pkg>?]
And Iris-Web does not reproduce a guessed version number
```

---

## Anti-Hallucination Pass

For each FR :

- **Testable** : every FR is asserted by at least one test in
  `k4.test.sh` (mapping captured in `tasks.md` `[Story: FR-K4-IW-XXX]`
  tags during `/forge:plan`).
- **Unambiguous** : 3 open questions flagged in the proposal, all
  resolvable at design time via ADR-K4-001..003. The Hera/Apollo scope
  boundary is NOT ambiguous — it is ratified by ADR-005 +
  `ARCHITECTURE-TARGET` §9.2 line 743.
- **Constitution-compliant** : Articles I (TDD), II (BDD), III + III.4,
  IV (delta — additive rows only), V (audit trail), XI (AI-First —
  agent-native, structured report), XII (governance — enforces, does
  not amend).

---

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`specs.md`. Three open questions Q-001 + Q-002 + Q-003 raised at the
proposal phase, tracked in `open-questions.md`, slated for resolution
during `/forge:design` via ADR-K4-001..003.

## Counts

- **FR-K4-IW-***: 26 (001-009 persona, 010-011 audit/cross-refs,
  020-026 conventions, 080-085 standard+integration, 100-102 harness,
  110-111 docs, 120-125 seed rules)
- **NFR-K4-IW-***: 6 (001-006)
- **BDD Scenarios** : 3
- **Open Questions** : 3 (Q-001..Q-003, all status `open` at spec time)
