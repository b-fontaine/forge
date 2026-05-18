# Proposal: t5-otel-dartastic-realign
<!-- Created: 2026-05-18 -->
<!-- Schema: default -->
<!-- Audit: T5.3 (docs/new-archetypes-plan.md §0.3) -->

## Problem

The Forge Flutter OpenTelemetry standard `.forge/standards/flutter/opentelemetry.md`
v1.1.0 pins the **Workiva `opentelemetry: 0.18.11`** package. Two
incidents have exposed structural problems with that choice :

1. **Q-004 (resolved 2026-05-12)** — the v1.0.0 standard had been
   authored by cross-language transposition from JS/Java/Python OTel
   conventions and documented **9 fabricated symbols** that did not
   exist in the Workiva package. Resolved by realigning v1.0.0 → v1.1.0
   on the actual symbols exposed by Workiva `0.18.11`.
2. **Q-006 (discovered 2026-05-16, opened by `cli-trust-harness`
   Option B validation)** — the Workiva package is **web-only** on
   pub.dev (`Platforms: Web`). The consuming archetypes — `mobile-only`
   (Android+iOS first class) and `full-stack-monorepo` frontend (Flutter
   mobile + web) — require platform support that Workiva does not
   declare. The mismatch survived Q-004's API-surface realign because
   the ratification procedure verified existence + symbols but NOT
   platform compatibility.

T5.2 (`t5-2-platform-verification`, archived 2026-05-18) shipped the
**3-axis platform-verification checklist** that institutionally
prevents the recurrence. T5.3 (this change) is the **first consumer**
of that checklist : it must architecturally resolve Q-006 by
substituting a package whose declared platform support matches the
consuming archetypes.

The technical consequences of Q-006 currently observable :

- `cli/test/e2e/archetypes-smoke.test.ts` mobile-only run with
  `FORGE_E2E_TOOLCHAINS=1` → `flutter pub get` fails on the phantom
  `opentelemetry_sdk` reference (introduced by an unrelated
  `b4-mobile-only` typo) AND `flutter analyze` RED on Workiva
  platform mismatch when the phantom is removed.
- FSM example frontend `examples/forge-fsm-example/frontend/`
  imports Workiva `opentelemetry` in 5 Dart files ; the example
  scaffolds but does not actually run end-to-end on mobile targets.
- v0.3.3 / v0.3.4 release notes documented `flutter analyze` as
  "RED, deferred to T5.3" in the post-release ledger.

T5.3 closes the loop.

## Solution

Replace Workiva `opentelemetry` with the **Dartastic ecosystem**
(verified publisher `mindfulsoftware.com` on pub.dev) which is
spec-aligned and supports all 6 Flutter platforms :

| Package | Version pin | Role |
|---|---|---|
| `dartastic_opentelemetry_api` | `^1.0.0-beta.2` (transitive, latest stable line is 0.9.0 but SDK requires beta) | No-op OpenTelemetry API |
| `dartastic_opentelemetry` | `^1.1.0-beta.6` (latest) | Dart SDK backend |
| `flutterrific_opentelemetry` | `^0.4.0` (latest) | Flutter integration shim (auto-instrumentation, navigation observer, lifecycle) |

**Why Dartastic** :
- Spec-aligned : implements OTel spec 1.31.0 for the 3 signals (Traces,
  Metrics, Logs).
- Verified publisher on pub.dev (`mindfulsoftware.com`) — same trust
  level as Workiva (`workiva.com`) and `bloclibrary.dev`.
- **All 6 Flutter platforms declared** (Android, iOS, Linux, macOS,
  Web, Windows). Mobile (Android/iOS) and Web carry "Full"/"Complete"
  support ; desktop carries "beta" — out of scope for current Forge
  archetypes (no archetype targets desktop).
- 3-package separation (`_api` no-op / SDK / Flutter shim) matches
  the upstream OTel split and gives adopters flexibility.
- Active maintenance : `dartastic_opentelemetry 1.1.0-beta.6` published 9
  days ago.

**Standard bump** : `flutter/opentelemetry.md` v1.1.0 → **v2.0.0**
(`breaking_change: true` per ADR-T52-001 lifecycle rules + Article XII
governance). The 3-axis checklist (T5.2.A) is **ticked inline** in
this proposal's "Source Documents" table (see Impact section below)
— T5.3 is the inaugural application of the T5.2 procedure.

## Scope In

### Standard rewrite
- `.forge/standards/flutter/opentelemetry.md` v1.1.0 → v2.0.0 :
  - Frontmatter `version: 2.0.0`, `last_reviewed: 2026-05-18`,
    `breaking_change: true`, `pkg_*` pins refreshed.
  - 11 H2 sections rewritten against Dartastic API surface verified
    via Context7 + pub.dev WebFetch (Sampling, HTTP Instrumentation
    via Dio, Navigation Observer, BLoC Observer, User Interaction
    Spans, Error Instrumentation, Custom Spans, Context Propagation).
  - **Inline 3-axis checklist** for the 3 Dartastic packages
    (existence ✅ pub.dev + API surface ✅ verified via Context7 +
    platform compatibility ✅ all 6 platforms declared).
  - REVIEW.md ledger entry with `breaking_change: true`.

### FSM example frontend rewrite (5 Dart files)
- `examples/forge-fsm-example/frontend/pubspec.yaml` — replace
  `opentelemetry: ^0.18.0` with `flutterrific_opentelemetry: ^0.4.0`
  + `dartastic_opentelemetry: ^1.1.0-beta.6`.
- `lib/core/telemetry/telemetry_setup.dart` — replace Workiva
  `OTel` provider init with Flutterrific `OTel.initialize(...)` +
  route observer registration.
- `lib/core/telemetry/error_reporter.dart` — rewrite span error
  recording on Dartastic `Status.error`.
- `lib/core/telemetry/interceptors/tracing_interceptor.dart` — Dio
  interceptor against Dartastic `Tracer`/`Span`/W3C propagator.
- `lib/core/telemetry/observers/tracing_navigation_observer.dart` —
  use Flutterrific's auto-instrumentation or wrap go_router observer.
- `lib/core/telemetry/observers/tracing_bloc_observer.dart` —
  BLoC observer against Dartastic `Tracer`.

### Mobile-only template rewrite
- `.forge/templates/archetypes/mobile-only/pubspec.yaml.tmpl` —
  remove phantom `opentelemetry_sdk` ; add `flutterrific_opentelemetry`
  + `dartastic_opentelemetry`.
- `.forge/templates/archetypes/mobile-only/lib/observability/otel_init.dart.tmpl`
  — replace Workiva import + init with Flutterrific.
- Mirror both in `cli/assets/.forge/templates/archetypes/mobile-only/`.

### Forward-pointers in archived changes
Per Article V audit-trail immutability, the affected archived changes
(`b4-mobile-only`, `t5-otel-app`, `t5-otel-dart-api-realign`) MUST
NOT be modified in place. T5.3 adds a `.forge-update-notes` file in
each, documenting that the underlying Workiva pin has been replaced
by Dartastic in T5.3 and pointing to the new standard v2.0.0.

### Harness
- New `.forge/scripts/tests/t5-otel-dartastic.test.sh` — ≥ 12 L1
  grep + 1 L2 opt-in (`FORGE_T53_LIVE=1`) running `flutter pub get` +
  `flutter analyze` on a scaffolded mobile-only target. Pattern
  mirrors I.5 / K.3 / T5.2.
- Registered in `.github/workflows/forge-ci.yml` matrix.

### Documentation
- `CHANGELOG.md [Unreleased]` entry under `### Changed` (breaking).
- Targeting **v0.4.0-rc.1** release (pre-GA minor bump per
  `docs/VERSIONING.md` because the standard breaks).

## Scope Out (Explicit Exclusions)

- **Snapshot tarball regeneration** — the
  `full-stack-monorepo/1.0.0.tar.gz` snapshot is NOT regenerated
  by T5.3. Legacy compat for adopters who pinned 1.0.0 stays
  stable. Next tree bump (post-T5.3 archive) regenerates via
  `npm run bundle`.
- **Modifying archived changes** — `b4-mobile-only`,
  `t5-otel-app`, `t5-otel-dart-api-realign` STAY ARCHIVED
  (Article V immutability). Forward-pointers via `.forge-update-notes`
  only.
- **B.8 flagship migration `1.0.0 → 2.0.0`** — that is T6 scope ;
  T5.3 only touches the standards layer + reference example +
  mobile-only template. The flagship Kong → Envoy / DBOS /
  Connect-RPC migration stays out.
- **Desktop platform support (Linux/macOS/Windows) in archetypes** —
  out of scope ; flutterrific declares "beta" support there but no
  current archetype targets desktop. T8+ may revisit if
  `rust-cli-tui` gets a Flutter desktop variant.
- **Metrics + Logs signals end-to-end wire-up** — T5.3 ratifies
  Dartastic's API surface for all 3 signals (Traces, Metrics, Logs)
  in the standard, but only Traces gets concrete Dart wiring in
  the FSM example and mobile-only template. Metrics/Logs wiring
  is post-archive follow-up (covered by spec ; not by code).
- **OMC upstream PR** — the T5.2 checklist's upstream OMC
  contribution is still deferred (Option C of ADR-T52-001).

## Impact

- **Users affected** : every Forge adopter currently using the
  `flutter/opentelemetry.md` standard (i.e. every `full-stack-monorepo`
  frontend and `mobile-only` adopter). Migration path documented in
  the v2.0.0 standard + CHANGELOG.
- **Technical impact** :
  - 1 standard (breaking bump v1.1.0 → v2.0.0).
  - 5 Dart files in `examples/forge-fsm-example/frontend/`.
  - 2 template files in `.forge/templates/archetypes/mobile-only/`
    + their cli/assets/ mirrors.
  - 3 `.forge-update-notes` forward-pointers in archived changes.
  - 1 new harness `t5-otel-dartastic.test.sh`.
  - REVIEW.md ledger entry (`breaking_change: true`).
  - `.github/workflows/forge-ci.yml` matrix entry (line-budget
    constrained — may need to compact a neighbouring comment).
- **Dependencies** :
  - **Hard prerequisites** : T5.2 archived (3-axis checklist
    available for inline ticking) ; v0.3.4 released so the
    checklist convention is shipped publicly.
  - **Downstream** : B.8 (T6) flagship migration may revisit the
    OTel stack ; T5.3 keeps the collector contract (OTLP HTTP
    `:4318`) unchanged so B.8 isn't blocked.
- **Risk** : **MEDIUM**.
  - Dartastic SDK 0.9.5 is actively maintained but the `_api`
    constraint `^1.0.0-beta.2` is on a beta line — pre-GA risk
    accepted given Workiva's web-only is a hard blocker.
  - `flutterrific_opentelemetry 0.4.0` is younger / less battle-tested
    than Workiva. **Mitigation** : design phase will evaluate
    `dartastic_opentelemetry` (Dart SDK pure) as a fallback if
    `flutterrific` blocks integration. Choice deferred to ADR-T53-001
    after design-phase prototyping.
  - Breaking standard bump (v2.0.0) forces every adopter to migrate.
    Bench tested on FSM frontend + mobile-only ; documented in
    CHANGELOG + standard's "Migration from v1.1.0" section.
- **Release target** : **v0.4.0-rc.1** (pre-GA minor bump per
  VERSIONING.md). T5.3 archived = release candidate cut.
  v0.3.4 patch (T5.2) stays separate and unblocked.

### Source Documents — 3-axis verification (T5.2 inaugural application)

| Dependency | Existence (pub.dev) | API surface | Platform compatibility | Notes |
|---|---|---|---|---|
| `dartastic_opentelemetry_api @ ^1.0.0-beta.2` | [x] verified-publisher mindfulsoftware.com | [x] OTelAPI / Tracer / Span / Context / Baggage / Attributes / Status / SpanKind — verified via Context7 + pub.dev | [x] Android, iOS, Linux, macOS, Web, Windows declared | beta line accepted (stable 0.9.0 incompatible with SDK 0.9.5's `^1.0.0-beta.2` constraint) |
| `dartastic_opentelemetry @ ^1.1.0-beta.6` | [x] verified-publisher mindfulsoftware.com | [x] OTel.initialize / OtlpGrpcSpanExporter / OtlpHttpSpanExporter / Tracer / Span / Sampler / Meter / Counter / Histogram / OTelLogger / W3CTraceContextPropagator — verified | [x] All Dart/Flutter targets declared | Active maintenance, last published 9 days ago |
| `flutterrific_opentelemetry @ ^0.4.0` | [x] verified-publisher mindfulsoftware.com | [x] OTel-init helper / route observer / lifecycle / error+navigation auto-instrumentation — verified | [x] Android, iOS "Full" ; Web "Complete OTLP/HTTP" ; desktop "Beta" | Desktop "beta" not a blocker — no current archetype targets desktop. FSM (web+mobile) + mobile-only (Android+iOS) covered by "Full"/"Complete" |

No `[PLATFORM MISMATCH:]` markers raised — the substitution
satisfies all 3 axes for every consuming archetype.

## Constitution Compliance

- **Article I (TDD)** : harness `t5-otel-dartastic.test.sh` written
  RED first (assertions against absent Dart files + non-bumped
  standard). Flipped GREEN as artefacts ship.
- **Article II (BDD)** : Dart code is observability plumbing
  (no user-facing UI). One end-to-end BDD scenario for traceparent
  round-trip via FSM demo (mirrors the T.5 Phase D pattern).
- **Article III (Specs Before Code)** : `/forge:specify` writes
  `specs.md` with FRs/NFRs before any Dart rewrite begins.
- **Article III.4 (Ambiguity Protocol)** : the 3-axis checklist
  applied inline in this proposal IS the Article III.4 procedural
  reinforcement T5.2 codified. No `[NEEDS CLARIFICATION:]` inline
  in this proposal ; 3 open questions deferred to `open-questions.md`
  for `/forge:design` resolution.
- **Article V (Constitutional Compliance Gate)** : archived changes
  (b4-mobile-only, t5-otel-app, t5-otel-dart-api-realign) stay
  byte-identical ; forward-pointers via `.forge-update-notes` only.
- **Article VI (Flutter Architecture)** : Clean Architecture + FSD
  preserved ; observability layer stays a side concern wired via
  `core/telemetry/` (FSM) or `lib/observability/` (mobile-only) per
  existing convention. No Cubit/BLoC changes — only the observer
  implementations.
- **Article VIII (Infrastructure)** : N/A — no infra change.
  Collector contract (OTLP HTTP `:4318`) unchanged from `t5-otel-stack`.
- **Article IX (Observability)** : reinforced — the standard now
  matches a package whose 3 signals are actually implementable on
  the target platforms.
- **Article XII (Governance / Standards Lifecycle)** : breaking
  bump v1.1.0 → v2.0.0 is documented in REVIEW.md ledger with
  `breaking_change: true` per `global/standards-lifecycle.md` v1.1.0
  (which T5.2 just shipped). 12-month review window applies to the
  new v2.0.0.

## Open Questions

Three questions recorded in `open-questions.md` ; MUST be resolved
(`answered` / `wontfix`) before `/forge:plan` per Open Questions Gate :

- **Q-001** — Choice between `flutterrific_opentelemetry` shim vs
  pure `dartastic_opentelemetry` Dart SDK with custom Flutter
  wiring (resolves in `/forge:design` via ADR-T53-001).
- **Q-002** — Whether to pin the API at stable `0.9.0` (with SDK
  downgrade) or beta `^1.0.0-beta.2` (with current SDK 0.9.5) —
  the dependency graph forces the latter but the design pass
  should formally ratify the beta-line acceptance.
- **Q-003** — Forward-pointer convention in archived changes :
  `.forge-update-notes` file (proposed) vs new `open-questions.md`
  Q-NNN entries (alternative). Article V immutability preserved
  in both cases.

---

> **Mentor note** : T5.3 is the inaugural exercise of the T5.2
> 3-axis checklist. The change MUST go through an **independent
> code-reviewer pass** before `/forge:archive` per the T5.2
> self-validation lesson captured in `t5_2_self_validation_lesson`
> memory — the methodology demands separation of authoring and
> reviewing contexts. Skipping this step would forfeit the
> learning that motivated T5.2 itself.

— *Proposal authored 2026-05-18. Ready for `/forge:specify` once
Q-001 + Q-002 + Q-003 are resolved (design phase).*
