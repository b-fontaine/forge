# CLAUDE.md — forge-rag-example/frontend/web-public

<!-- Audit: B.7.2 (b7-2-scaffolder, Phase 1) — ai-native-rag web-public nested CLAUDE.md -->
<!-- Scope: frontend/web-public/ subtree only — Qwik / web-frontend standards -->

## Scope

This file is loaded automatically by Claude Code when working anywhere inside
`frontend/web-public/`. It scopes which standards apply and which orchestrator
owns the work. The root `CLAUDE.md` carries cross-cutting policy only.

This archetype's only frontend surface is the **Qwik `web-public`** UI. There is
**no Flutter mobile app** in `ai-native-rag` (`ADR-B7-2-006`, Q-5): the schema's
`frontend.standards_scope: [flutter, all]` is inherited layer-template
boilerplate and is an accepted known-gap, not a surface that ships here. A
future Flutter surface, if ever wanted, is a separate change.

## Load These Standards

- `global/tdd-rules` — always active (Article I).
- `global/bdd-rules` — Given/When/Then for every user-facing behavior.
- `web-frontend.yaml` — Qwik City conventions (B.8.9): SSR, routing, Connect-ES.

## DO NOT Load

- `rust/*` — backend concern; route to `backend/CLAUDE.md` and Vulcan.
- `infra/*` — infra concern; route to `infra/CLAUDE.md` and Atlas.

## Primary Agent

**Hera** orchestrates this surface. Apollo (UX/UI) and Iris (a11y/i18n) assist;
**Nemesis** is the quality gate.

## Non-Negotiables

- The frontend talks to the backend ONLY through the generated Connect-ES v2
  client (`src/lib/connect-client.ts`), itself generated from `shared/protos/`.
  No hand-written protocol code, no direct DB access.
- Streaming transport (SSE / WebTransport) is **out of scope** here — it ships
  in B.7.10 (`b7-10-streaming`). The baseline is non-streaming request/response.
