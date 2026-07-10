# Proposal: k4-iris-web
<!-- Created: 2026-07-10 -->
<!-- Schema: default -->

## Problem

`docs/ARCHITECTURE-TARGET.md` §9.2 line 734 and
`docs/new-archetypes-plan.md` §9 line 2671 (K-modules table) +
§0.13 line 2845 (`.claude/agents/{...,iris-web,...}.md`) mandate a
new Forge agent **Iris-Web** — the *frontend web specialist* — whose
mandate is to **maintain the Qwik / SvelteKit web-frontend standards,
distinct from Hera (which owns Flutter)**. The architecture is explicit
that this is a two-owner split on the flagship :

> **Janus** : doit devenir le **point d'arbitrage** entre Iris-Web
> (Qwik) et Hera (Flutter) sur la flagship.
> — `docs/ARCHITECTURE-TARGET.md` §9.2 line 743.

The split is ratified by **ADR-005**
(`docs/ARCHITECTURE-TARGET.md` §5 lines 365-374) : KEEP Flutter for
mobile + desktop + the web back-office ; REPLACE the public web
surface (SEO-sensitive) with Qwik City. Iris-Web owns the Qwik side ;
Hera keeps 100% of its Flutter scope.

The Qwik surface Iris-Web must own conventions for **already exists** :

- `b8-9-qwik-web-public` (B.8.9, archived 2026-06-03) shipped the
  `2.0.0/frontend/web-public/` 10-file Qwik City skeleton
  (`package.json`, `.nvmrc`, `vite.config.ts`, `tsconfig.json`,
  `qwik.env.d.ts`, `src/entry.ssr.tsx`, `src/root.tsx`,
  `src/routes/index.tsx`, `src/lib/connect-client.ts`, `README.md`)
  and the **NEW `web-frontend.yaml` v1.0.0** version-pin standard
  (qwik / qwik-city `^1.20.0`, vite `=7.3.5`, `@connectrpc/connect`
  `^2.0.0` via `transport.yaml`).
- `b7-10-streaming` (B.7.10) shipped the Connect-ES streaming client
  precedent : `connect-client.ts` `query()` + `queryStream()`
  consumed with `for await (const res of client.method(req))` over a
  `@connectrpc/connect-web` transport ; progressive render via a
  `useSignal` mutated inside the `for await` loop ;
  `useVisibleTask$` / component cleanup for **cancel-on-unmount** ;
  exponential-backoff retry → unary degrade.

Today none of the following exists :

- The Iris-Web persona file (`.claude/agents/iris-web.md`) is **not**
  on disk. `web-frontend.yaml` explicitly defers governance to it :
  *"Janus arbitrates the web-public + web-backoffice surfaces until
  the Iris-Web agent ships (K.4, T7). Machine enforcement
  (ci_blocking / linter_rule) stays OFF at birth — that is
  Iris-Web/K.4 territory."* Sibyl's persona (K.2) already names
  *"Hera (Qwik frontend)"* as a placeholder owner pending this agent.
- No **conventions** standard codifies HOW to build on the shipped
  Qwik surface. `web-frontend.yaml` owns the version PINS ; it does
  NOT document resumability patterns, `routes/` conventions,
  SSR/SSG boundaries, Connect-ES client usage, streaming UI patterns,
  component conventions, or Vitest testing conventions. Adopters and
  the layer orchestrators have no single reference for "the Forge way
  to write a Qwik web-public surface".
- No `K4-RULE-NNN` namespace exists. The `<MODULE>-RULE-NNN` format
  (`J8-RULE-*` per `j8-janus-rules` ADR-J8-004, extended by
  `K3-RULE-*` for Demeter) is designed to be extensible per audit
  module ; K.4 consumes the next prefix.

This change closes the gap : the Iris-Web persona + a Qwik/SvelteKit
conventions standard + the standards-and-dispatch integration, scoped
to the **already-shipped** Qwik surface in `full-stack-monorepo`'s
2.0.0 schema and designed to be **forward-stable / additive** for
`mobile-pwa-first` (B.9, Pending T8) to adopt later without rework.

## Solution

Three coordinated sub-modules under one umbrella change :

### K.4.a — Iris-Web persona (`.claude/agents/iris-web.md`)

A new agent file authored in the existing Forge specialist style
(compare `demeter.md` / Demeter, `sibyl.md` / Sibyl). The file
declares :

- **Persona** : name, role, style ; sibling relationship to Hera
  (Flutter) with an explicit, non-overlapping scope boundary ;
  archetype scope (`full-stack-monorepo` now ; `mobile-pwa-first`
  forward) ; anti-hallucination protocol.
- **Purpose** : maintain the Qwik/SvelteKit web-frontend conventions
  and review the `frontend/web-public/` surface for adherence.
- **Checklists** : one H3 per convention area (Resumability &
  Rendering / Routing & SSR-SSG Boundaries / Connect-ES & Streaming /
  Components & Vitest Testing), mirroring the Aegis/Demeter/Sibyl
  greppable `[ ]` bullet format. Output is a **Web Frontend Readiness
  Report** with severity, evidence, and an actionable recommendation.
- **Rule catalogue** : `K4-RULE-001..006` namespace, allocated by this
  spec.
- **Integration** : how Janus arbitrates between Iris-Web (Qwik) and
  Hera (Flutter) on the flagship ; the relationship to Apollo
  (Flutter UX/UI — never touches the Qwik surface) and Sibyl (the
  `ai-native-rag` Qwik streaming UI Sibyl advises, whose conventions
  Iris-Web owns).
- **Anti-hallucination protocol** : `[NEEDS CLARIFICATION:]` emission
  rules consistent with Article III.4.

### K.4.b — Qwik frontend patterns standard

A new standard `.forge/standards/global/qwik-frontend-patterns.md`
codifies the CONVENTIONS (not the pins) of the shipped Qwik surface :
resumability patterns, `routes/` conventions, SSR/SSG boundaries,
Connect-ES client usage (per the B.7.10 precedent), streaming UI
patterns, component conventions, and Vitest testing conventions. It
consumes `web-frontend.yaml` v1.0.0 as the single source of truth for
version pins **by reference** — it never reproduces a version number
(single-source-of-truth per the `b8-9` reference-only annotation
pattern). Markdown, not YAML — so J.7 frontmatter validation is
informational not blocking (mirrors `data-stewardship-rules.md`).

### K.4.c — Standards + dispatch integration

- `.forge/standards/index.yml` gains a new entry pointing at the
  standard with triggers like `[iris-web, qwik, qwik-city, sveltekit,
  resumability, routes, ssr, ssg, connect-es, streaming-ui,
  vitest, web-frontend-patterns, k4-rule]`.
- `.claude/agents/cross-layer-orchestrator.md` (Janus) gains **one
  additive** dispatch-table row for Iris-Web (Qwik/SvelteKit
  web-public work). Hera's existing Flutter row is **NOT** modified or
  narrowed (ADR-005 gives Hera the back-office web + all mobile/desktop;
  Iris-Web only claims the Qwik public web surface Hera never owned).
- The repo-level `CLAUDE.md` agent-delegation table gains one row for
  Iris-Web.
- `.forge/scaffolding/dispatch-table.yml` is **NOT** edited — Iris-Web
  is invoked by Janus at design/review time, not by the CLI's
  scaffold-time init dispatcher.

## Scope In

- New persona file `.claude/agents/iris-web.md` (≈ 250-320 LOC, same
  density as `demeter.md` / `sibyl.md`).
- New standard `.forge/standards/global/qwik-frontend-patterns.md`
  (7 convention H2 sections + rule catalogue + adoption path +
  forward-stability note).
- New `.forge/standards/index.yml` entry registering the standard.
- One additive row to `.claude/agents/cross-layer-orchestrator.md`
  Dispatch Table for Iris-Web (Hera's row untouched).
- One additive row to the repo `CLAUDE.md` agent-delegation table.
- New `K4-RULE-NNN` rule catalogue (6 seed rules), namespace
  allocation per ADR-J8-004 extension.
- Test harness `.forge/scripts/tests/k4.test.sh` (≥ 20 L1 + 2 L2
  cross-surface tests, mirrors `k3.test.sh` layout).
- CI registration of `k4.test.sh` in `.github/workflows/forge-ci.yml`.
- Doc updates : `CHANGELOG.md` `## [Unreleased]` entry + a
  `docs/GUIDE.md` agent-catalogue line.

## Scope Out (Explicit Exclusions)

- **NOT** any narrowing of Hera's Flutter scope. Hera keeps mobile +
  desktop + the Flutter Web back-office (ADR-005). Iris-Web only owns
  the Qwik/SvelteKit **public** web surface.
- **NOT** any modification of `web-frontend.yaml` (the version-pin
  standard). Iris-Web consumes it by reference. Version pins are its
  single source of truth ; the conventions standard never reproduces a
  version number.
- **NOT** the `mobile-pwa-first` (B.9) archetype itself. B.9 is Pending
  T8 and does not exist in this repo. The persona + standard are
  designed forward-stable so B.9 adopts them additively — but no B.9
  schema, template, or migration script is created here.
- **NOT** any executable scanner or data file. Unlike Demeter (K.3),
  Iris-Web ships NO `bin/*.sh` scanner and NO `.forge/data/*.yml`
  deny-list. It is a `.claude/agents/` persona + a markdown standard
  reviewed by a human/agent at design/review time.
- **NOT** turning on machine enforcement (`ci_blocking` / `linter_rule`)
  in `web-frontend.yaml`. That flip is a deliberate follow-up decision;
  this change ships the standard + persona as documentation-first.
- **NOT** any change to the B.7.10 streaming templates or the B.8.9
  Qwik skeleton templates themselves — they are consumed as the
  precedent the standard codifies, not rewritten.
- **NOT** any change to the J8-RULE-* / K3-RULE-* catalogues. Iris-Web
  rules use the `K4-RULE-*` prefix per ADR-J8-004 extension protocol.
- **NOT** modifications to `cli/src/**.ts` or any TypeScript surface.
- **NOT** anything under `.forge/schemas/event-driven-eu/` or any
  B.6-specific surface (a sibling build owns that in parallel).

## Impact

- **Users affected** :
  - Adopters of `full-stack-monorepo` gain a single reference for the
    Forge way to build the Qwik web-public surface, and a named
    specialist that reviews it.
  - Janus gains a second frontend owner : it now arbitrates between
    Iris-Web (Qwik) and Hera (Flutter) on the flagship instead of
    arbitrating the web surface directly (the interim posture
    `web-frontend.yaml` documented).
  - No change at all for adopters not using the Qwik web-public
    surface (backward compatible — additive only).
- **Technical impact** : ≈ 4 new files (persona, standard, harness,
  + the change spec set) + ≈ 4 modified (standards index, Janus agent,
  CLAUDE.md, CI workflow, CHANGELOG, GUIDE). **Effort `M`** per
  `new-archetypes-plan` §9 row K.4.
- **Dependencies** :
  - B.8.9 `b8-9-qwik-web-public` archived 2026-06-03 — ships
    `web-frontend.yaml` v1.0.0 + the `frontend/web-public/` surface.
  - B.7.10 `b7-10-streaming` — ships the Connect-ES streaming client
    precedent the standard codifies.
  - J.8 `j8-janus-rules` — ships the `<MODULE>-RULE-NNN` format
    `K4-RULE-*` extends.
  - No new external dependency. The harness is bash + grep only.
- **Risk level** : **Low**. The persona + standard are pure
  documentation ; the only wiring edits are additive rows. The main
  risk is **drift against `web-frontend.yaml`** — mitigated by the
  single-source-of-truth reference discipline (the standard never
  reproduces a version number ; the harness asserts no pin
  duplication).

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`k4.test.sh` with ≥ 20 L1 + 2 L2 stubs all returning
`_not_implemented` (full RED witness). Phase 2+ implements one
cluster at a time.

### Article II — BDD

User-facing flows get Gherkin scenarios in `specs.md` :

```gherkin
Given a frontend/web-public/ Qwik surface consuming a server-streaming Connect method
When Iris-Web reviews the route component
Then it verifies a for-await progressive render + cancel-on-unmount cleanup are present
  and flags K4-RULE-004 when the stream has no cancel-on-unmount

Given a Qwik component that eagerly hydrates instead of resuming
When Iris-Web reviews the component
Then it emits a K4-RULE-001 finding citing the resumability contract

Given a proposed convention change with no matching web-frontend.yaml pin owner
When Iris-Web cannot resolve which surface owns the pin
Then it emits [NEEDS CLARIFICATION: ...] and STOPS rather than guessing
```

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-K4-IW-*`
namespace before any implementation.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Open questions captured in `open-questions.md` ; resolved before
status flips to `implemented`.

### Article IV — Delta-Based Change Management

The only MODIFIED surfaces are additive rows to
`cross-layer-orchestrator.md` (Janus dispatch table), `CLAUDE.md`, and
`standards/index.yml`. Hera's row is untouched — no REMOVED or narrowed
requirement. ADDED requirements predominate.

### Article V — Audit Trail

Each task tagged `[Story: FR-K4-IW-XXX]` (Article V.1, enforced by
`f4-linter-extension`). Iris-Web findings reference rule IDs in the
`K4-RULE-NNN` format, consistent with the K.3 / J.8 catalogues.

### Article VIII — Infrastructure

N/A — no service, no daemon, no scanner. The persona is invoked by
Janus at design/review time.

### Article IX — Observability

N/A directly. Iris-Web reviews the web surface's structure at
design/review time ; it emits no runtime telemetry. The Qwik surface
it reviews wires OTLP per `observability.yaml` (out of scope here).

### Article XI — AI-First Design

Iris-Web is a Claude-Code agent persona (Article XI.1 agent-native).
Its output is a deterministic structured report (the Web Frontend
Readiness Report) — no opaque LLM-generated text consumed downstream
without human review.

### Article XII — Governance

Iris-Web ENFORCES the Qwik/SvelteKit conventions ratified by ADR-005
and the `web-frontend.yaml` standard ; it does **not amend** any
constitutional article. The new standard is MD, not YAML ; it does not
carry the J.7 frontmatter contract.

## Open Questions

Inline `` `[NEEDS CLARIFICATION:]` `` markers : none in this
`proposal.md`. Three open questions Q-001 + Q-002 + Q-003 raised at
this phase, all tracked in `open-questions.md` and slated for
resolution during `/forge:design` :

- **Q-001** — Iris-Web severity ladder : adopt Demeter's
  Critical/High/Medium/Low/Informational refusal ladder, or Sibyl's
  advisory Advisory/Concern/Blocking ladder?
- **Q-002** — the standard's relationship to `web-frontend.yaml` :
  reference-only (no pins reproduced), reproduce-and-sync, or merge?
- **Q-003** — K4-RULE namespace allocation : pre-allocate 10 now, or
  grow incrementally from a 6-rule seed?
