# Standard — Qwik Frontend Patterns

<!-- Audit: K.4 (k4-iris-web, FR-K4-IW-080) -->
<!-- Trigger: iris-web, qwik, qwik-city, sveltekit, resumability, routes, ssr, ssg, connect-es, streaming-ui, vitest, web-frontend-patterns, k4-rule -->

## Purpose

This standard documents the **conventions** for building the
`frontend/web-public/` Qwik City (or SvelteKit) public web surface of
`full-stack-monorepo`. It is the reference the **Iris-Web** agent
(`.claude/agents/iris-web.md`, K.4) operationalises as review-time
checks.

It codifies the **already-shipped** surface — it does not invent new
patterns. The two upstream changes it consumes as precedent:

- `b8-9-qwik-web-public` (B.8.9) — the `2.0.0/frontend/web-public/`
  10-file Qwik City skeleton and the `web-frontend.yaml` v1.0.0
  version-pin standard.
- `b7-10-streaming` (B.7.10) — the Connect-ES streaming client
  precedent (`connect-client.ts`, progressive render, cancel-on-unmount).

**Version pins are OUT of scope for this standard.** All package
versions (qwik, qwik-city, vite, `@connectrpc/connect`,
`@connectrpc/connect-web`, the `.nvmrc` Node line) are owned by
`.forge/standards/web-frontend.yaml` (and `transport.yaml` for the
Connect packages) as the **single source of truth**. This standard
references those pins by name and NEVER reproduces a version number —
so a pin bump in `web-frontend.yaml` never drifts against this prose
(the `b8-9` reference-only annotation discipline).

**Scope**: `full-stack-monorepo`'s `frontend/web-public/` surface
today. The conventions are written framework-surface-first (not
directory-first) so `mobile-pwa-first` (B.9, Pending T8) adopts them
additively when it ships a PWA Qwik channel — no rewrite required.

**Framework**: Qwik City is the default per ADR-005
(`docs/ARCHITECTURE-TARGET.md` §5 lines 365-374); SvelteKit is the
ratified alternative (`web-frontend.yaml`). The conventions below are
written for Qwik City; the SvelteKit equivalents (load functions,
`+page.server.ts`, form actions) map one-to-one and are called out
where they differ.

## Resumability & rendering

Qwik's defining property is **resumability**: the server serializes the
application state and event wiring into the HTML once, and the client
**resumes** on the first interaction instead of re-executing the whole
component tree (hydration). This keeps eager client JS minimal (the
~2 KiB eager-JS rationale in ADR-005) and is the reason the public,
SEO-sensitive surface is Qwik rather than a hydration framework.

Conventions:

- Author components with `component$()`. Reactive state uses
  `useSignal()` / `useStore()`; derived state uses `useComputed$()`.
- Wrap event handlers and heavy closures in `$()` so they lazy-load on
  interaction — this is what preserves resumability at the component
  level.
- Only serializable values may cross the resume boundary. Non-serializable
  handles (sockets, timers, streams) live inside `useVisibleTask$()`
  with a cleanup return.
- Do NOT eagerly hydrate the tree React-style. Eager hydration in the
  Qwik surface is a non-conformance (**K4-RULE-001**, Concern).

## routes/ conventions

Routing is Qwik City file-based under `src/routes/`:

- `src/routes/index.tsx` is the landing route; nested directories map
  to URL segments; `layout.tsx` wraps a segment.
- **Server data-loading** uses `routeLoader$` (runs on the server,
  serialized to the client). **Mutations** use `routeAction$` +
  `Form`. **Server-only functions** use `server$`.
- Business logic belongs in the route server API (`routeLoader$` /
  `routeAction$` / `server$`), NOT in the eager client path. Business
  logic in the eager path is **K4-RULE-002** (Concern).
- SvelteKit equivalent: `+page.server.ts` `load` / form `actions`.

## SSR/SSG boundaries

The shipped skeleton renders server-side:

- `src/entry.ssr.tsx` is the required SSR entry; `src/root.tsx` +
  `src/routes/` render to HTML + a resumable payload
  (`b8-9-qwik-web-public` design §component layout).
- **SSG** (static generation) is the alternative for non-dynamic
  routes where it improves TTI; the Qwik City static adapter
  pre-renders those routes at build time.
- SEO-critical public routes MUST be server-rendered (not client-only)
  so crawlers and LCP see meaningful content — the whole point of
  ADR-005.
- **Server-only imports MUST NOT reach the client bundle.** Secrets and
  server-only modules are referenced only from `routeLoader$` /
  `routeAction$` / `server$`. A server-only secret leaking into the
  client bundle is **K4-RULE-005** (Blocking) — the single blocking
  rule, because a public web surface must never ship a secret.

## Connect-ES client usage

Backend RPC uses Connect-ES (the B.7.10 + B.8.9 precedent), pinned in
`web-frontend.yaml` / `transport.yaml` (referenced, never reproduced):

- A single **shared transport** via `createConnectTransport` (from
  `@connectrpc/connect-web`) and a typed client via
  `createClient(Service, transport)`, both in
  `src/lib/connect-client.ts`.
- The transport is created **once and reused** — not re-instantiated
  per call. Per-call transport/client creation is **K4-RULE-003**
  (Advisory).
- Unary calls (`query()`) and server-streaming calls (`queryStream()`)
  share the same transport (B.7.10 `connect-client.ts`).

## Streaming UI

Server-streaming is consumed per the B.7.10 precedent
(`connect-client.ts` `queryStream()` + `routes/index.tsx` progressive
render):

- Consume a server-streaming method with
  `for await (const res of client.method(req)) { … }`.
- **Progressive render** by mutating a `useSignal` inside the
  `for await` loop so the UI updates as chunks arrive.
- **cancel-on-unmount**: a `useVisibleTask$` cleanup (or an
  `AbortController` wired to the request) cancels the in-flight stream
  when the component unmounts, and a Stop/cancel control aborts it on
  demand. A streaming consumer with no cancel-on-unmount is
  **K4-RULE-004** (Concern).
- **Graceful degradation**: exponential-backoff retry on transient
  failure, degrading to the unary path; mid-stream failure terminates
  with a marker rather than hanging (B.7.10 fallback design).
- WebTransport is documented as the forward-alternative transport in
  the surface's README (B.7.10 FR-B7-10-030), not the default.

## Component conventions

- `component$()` factories are presentational: they render props and
  signals. Data-fetching and business logic are lifted into
  `routeLoader$` / `server$`, not embedded in presentational
  components.
- Side effects (subscriptions, streams, timers) live in
  `useVisibleTask$()` with a cleanup return.
- Component props carry explicit TypeScript types; `tsconfig` strict
  mode is honoured (`qwik.env.d.ts` present in the skeleton).
- Lazy boundaries via `$()` keep the eager bundle small.

## Vitest testing conventions

Frontend tests use Vitest (the `t5-3-3-vitest-bundle-preflight`
precedent):

- `vitest.config.ts` at the surface root; tests as co-located
  `*.test.ts` / `*.spec.ts` or under `test/`.
- Any bundle/preflight step runs in a Vitest `globalSetup` (the
  T5.3.3 `spawnSync` bundle-preflight pattern) so it executes serially
  before tests.
- Each `src/routes/` route and shared component SHOULD have a Vitest
  test; coverage meets the Article X **80%** threshold. A web-public
  route/component with no test is **K4-RULE-006** (Advisory).
- The test command is documented in the surface's `README.md`.

## Rule catalogue

Iris-Web is advisory (severity ladder `Advisory` < `Concern` <
`Blocking`); the full rule body (evidence pattern + recommendation)
lives in `.claude/agents/iris-web.md` § Rule Catalogue. Both surfaces
stay in sync (the K.4 harness asserts it).

| Rule ID | Trigger | Severity | Reference |
|---|---|---|---|
| `K4-RULE-001` | Eager hydration instead of resumability | `Concern` | FR-K4-IW-120 ; § Resumability & rendering |
| `K4-RULE-002` | Business logic outside `routeLoader$` / `routeAction$` / `server$` | `Concern` | FR-K4-IW-121 ; § routes/ conventions |
| `K4-RULE-003` | Connect transport re-instantiated per call | `Advisory` | FR-K4-IW-122 ; § Connect-ES client usage |
| `K4-RULE-004` | Streaming consumer without cancel-on-unmount | `Concern` | FR-K4-IW-123 ; § Streaming UI |
| `K4-RULE-005` | Server-only secret leaks into the client bundle | `Blocking` | FR-K4-IW-124 ; § SSR/SSG boundaries |
| `K4-RULE-006` | Web-public route/component missing Vitest coverage | `Advisory` | FR-K4-IW-125 ; § Vitest testing conventions |

The catalogue is **incremental**: new `K4-RULE-NNN` entries append in
monotonic order; IDs are NEVER reused (decommissioned rules carry
`DEPRECATED`). The `K4-RULE-*` namespace inherits the
`<MODULE>-RULE-NNN` format ratified by `j8-janus-rules` (ADR-J8-004)
and is syntactically disjoint from the Janus (J.8) and Demeter (K.3)
namespaces.

## Adoption path & forward stability

**Minimum viable adoption** (`full-stack-monorepo` web-public):

1. Scaffold the `frontend/web-public/` surface (the B.8.9 skeleton).
2. Keep version pins in `web-frontend.yaml`; never hardcode them in
   app code or docs.
3. Follow the resumability + routes + SSR/SSG + Connect-ES + streaming
   + Vitest conventions above.
4. At design/review time, Janus dispatches **Iris-Web** to review the
   surface against this standard and return a Web Frontend Readiness
   Report.

**Forward stability — `mobile-pwa-first` (B.9, Pending T8)**: the
conventions are scoped to "the Qwik web surface", not to the
`full-stack-monorepo` directory. When B.9 ships its PWA Qwik channel,
it adopts this standard additively — the same resumability, routing,
Connect-ES, streaming, component, and Vitest conventions apply, plus
the PWA-specific concerns (service worker, web push, installability)
layer on top. No rewrite of this standard is required; Iris-Web's
scope widens to include the PWA surface.

## Constitutional Compliance

This standard implements (does not amend):

- **Article III.4** (anti-hallucination) — Iris-Web emits
  `[NEEDS CLARIFICATION:]` instead of guessing on ambiguous pin
  ownership or unverifiable API shapes (see
  `.claude/agents/iris-web.md` § Anti-Hallucination Protocol).
- **Article IV.1** (delta-based) — this is an additive standard; it
  does not rewrite `web-frontend.yaml` (which keeps owning the pins).
- **Article V** (audit trail) — every finding carries `K4-RULE-NNN`.
- **Article IX** (security surface) — K4-RULE-005 (client-bundle
  secret leak) protects the public web surface.
- **Article X** (code quality) — Vitest coverage targets the 80%
  threshold.
- **Article XI.1** (agent-native) + **XI.3** (schema-driven) —
  Iris-Web is a first-class persona emitting a structured report.
- **Article XII** (governance) — amendments follow
  `global/standards-lifecycle.md`; version pins remain governed by
  `web-frontend.yaml`'s own review cadence.
