# Spec: qwik-frontend

<!-- Audit: K.4 (k4-iris-web) — Iris-Web persona, Qwik/SvelteKit web-frontend conventions standard, standards+dispatch integration. -->
<!-- Source change : `.forge/changes/k4-iris-web/` (archived 2026-07-10). -->

**Namespace** : `FR-K4-IW-*` / `NFR-K4-IW-*`. **Constitution** : v2.0.0.
No amendment required (K.4 introduces a new agent + conventions standard ;
existing articles unchanged).

**Four physical deliverables** (per `tasks.md`) :

- **K.4.a** — `.claude/agents/iris-web.md` persona file (9 H2 sections —
  Persona, Purpose, Checklists, Output: Web Frontend Readiness Report,
  Rule Catalogue, Integration, Anti-Hallucination Protocol, Audit
  cross-references + H1). Frontend web specialist for the Qwik/SvelteKit
  `frontend/web-public/` surface, distinct from Hera (Flutter). Advisory
  ladder (`Advisory` < `Concern` < `Blocking`) with a single Blocking rule
  (K4-RULE-005, client-bundle secret leak). Sibling to Hera with a
  disjoint, additive scope boundary ratified by ADR-005.
- **K.4.b** — `.forge/standards/global/qwik-frontend-patterns.md`
  conventions standard (Purpose + Resumability & rendering + routes/
  conventions + SSR/SSG boundaries + Connect-ES client usage + Streaming
  UI + Component conventions + Vitest testing conventions + Rule
  catalogue + Adoption path & forward stability + Constitutional
  Compliance). References `web-frontend.yaml` for version pins as the
  single source of truth ; reproduces NO version number.
- **K.4.c** — standards + dispatch integration : `.forge/standards/index.yml`
  registration (`id: global/qwik-frontend-patterns`, 13 triggers, scope
  `frontend`) ; an **additive** Janus dispatch-table row in
  `.claude/agents/cross-layer-orchestrator.md` (Hera's Flutter row
  untouched) ; a repo `CLAUDE.md` agent-delegation row ; a `docs/GUIDE.md`
  agent-catalogue row ; a `CHANGELOG.md` `[Unreleased]` entry.
- **K.4.d** (test harness) — `.forge/scripts/tests/k4.test.sh` (20 L1 +
  2 L2 cross-surface = 22 tests) registered in `forge-ci.yml`.

## Source Documents

- `docs/ARCHITECTURE-TARGET.md` §9.2 line 734 — Iris-Web agent introduction
  ("Frontend Web spécialisé — maintains Qwik / SvelteKit standards, distinct
  de Hera" ; archetype scope `full-stack-monorepo`, `mobile-pwa-first`).
- `docs/ARCHITECTURE-TARGET.md` §9.2 line 743 — Janus as the arbitration
  point between Iris-Web (Qwik) and Hera (Flutter) on the flagship.
- `docs/ARCHITECTURE-TARGET.md` §5 ADR-005 lines 365-374 — KEEP Flutter
  mobile + desktop + Web back-office ; REPLACE the public web surface →
  Qwik City (SEO + resumability + LCP/TTI).
- `docs/new-archetypes-plan.md` §9 line 2671 — K.4 row (Iris-Web,
  Qwik/SvelteKit standards, effort M).
- `docs/new-archetypes-plan.md` §0.13 line 2845 — `.claude/agents/{...,iris-web,...}.md`.
- Precedent surfaces : `b8-9-qwik-web-public` (B.8.9 — `web-frontend.yaml`
  v1.0.0 + the 10-file Qwik City skeleton) ; `b7-10-streaming` (B.7.10 —
  Connect-ES streaming client, progressive render, cancel-on-unmount) ;
  `t5-3-3-vitest-bundle-preflight` (Vitest wiring).

## Requirements summary

### Functional (FR-K4-IW-*) — 26

- **001-009** — persona file : location, Persona/Purpose sections,
  Checklists (4 H3), Output report, Rule Catalogue, Integration,
  Anti-Hallucination, archetype scope.
- **010-011** — audit comment + audit cross-references footer.
- **020-026** — conventions codified in the standard : resumability (020),
  routes/ (021), SSR/SSG boundaries (022), Connect-ES client (023),
  streaming UI + cancel-on-unmount (024), component conventions (025),
  Vitest testing (026).
- **080-085** — standard file existence, single-source-of-truth for pins,
  index registration, additive Janus dispatch row, CLAUDE.md trigger,
  namespace + Hera-scope-intact guard.
- **100-102** — harness `k4.test.sh` (≥ 20 L1 + 2 L2).
- **110-111** — CHANGELOG + GUIDE documentation.
- **120-125** — seed K4-RULE catalogue (K4-RULE-001..006).

### Non-Functional (NFR-K4-IW-*) — 6

- **001** — backward compatibility (purely additive).
- **002** — Article V audit trail (`[Story: FR-K4-IW-XXX]` + `K4-RULE-NNN`).
- **003** — single source of truth (no version-pin duplication ; harness
  asserts the exact vite pin literal is absent from the standard).
- **004** — no TypeScript / no scanner / no data file (persona + MD only).
- **005** — forward stability for `mobile-pwa-first` (B.9, Pending T8).
- **006** — Hera scope preserved (Flutter mobile + desktop + Web back-office).

### Architecture decisions (ADR-K4-*) — 4

- **ADR-K4-001** — advisory severity ladder (Advisory/Concern/Blocking),
  one Blocking rule (K4-RULE-005 client-bundle secret leak).
- **ADR-K4-002** — the conventions standard is reference-only against
  `web-frontend.yaml` (no pin reproduced).
- **ADR-K4-003** — `K4-RULE-NNN` namespace, 6 seed rules, incremental
  growth, IDs never reused (ADR-J8-004 inheritance).
- **ADR-K4-004** — additive Janus dispatch row ; Hera's Flutter row is
  never modified or narrowed.

## Seed K4-RULE catalogue

| Rule ID | Title | Severity |
|---|---|---|
| K4-RULE-001 | Eager hydration instead of resumability | Concern |
| K4-RULE-002 | Business logic outside route loaders/actions | Concern |
| K4-RULE-003 | Connect transport re-instantiated per call | Advisory |
| K4-RULE-004 | Streaming without cancel-on-unmount | Concern |
| K4-RULE-005 | Server-only secret leaks into client bundle | Blocking |
| K4-RULE-006 | Web-public route/component missing Vitest coverage | Advisory |

The `K4-RULE-*` namespace is syntactically disjoint from the Janus (J.8)
and Demeter (K.3) catalogues per the `<MODULE>-RULE-NNN` format ratified by
`j8-janus-rules` (ADR-J8-004). Future extensions append `K4-RULE-007..` ;
IDs are never reused (decommissioned rules carry `DEPRECATED`).

## BDD acceptance criteria (3 scenarios)

1. A streaming route with `for await` but no cancel-on-unmount → K4-RULE-004
   (Concern).
2. A component referencing a server-only secret from the eager client path →
   K4-RULE-005 (Blocking), report status BLOCKED.
3. Ambiguous pin ownership → `[NEEDS CLARIFICATION:]`, no guessed version.

## Forward stability

The persona + standard are scoped to "the Qwik web surface", not to one
archetype's directory. When `mobile-pwa-first` (B.9, Pending T8) ships its
PWA Qwik channel, it adopts `qwik-frontend-patterns.md` additively — the
same resumability, routing, Connect-ES, streaming, component, and Vitest
conventions apply, plus PWA-specific concerns layer on top. Iris-Web's scope
widens to include the PWA surface without a rewrite (NFR-K4-IW-005).
