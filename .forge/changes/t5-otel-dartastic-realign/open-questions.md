# Open Questions: t5-otel-dartastic-realign
<!-- Created: 2026-05-18 -->
<!-- Audit: T5.3 (docs/new-archetypes-plan.md §0.3) -->

Questions raised during `/forge:propose`. All MUST be resolved
(status `answered` or `wontfix`) before `/forge:plan` runs, per
`verify.sh` Open Questions Gate (Article III.4 /
`global/open-questions.md`).

---

## Q-001 — flutterrific_opentelemetry shim vs pure dartastic_opentelemetry Dart SDK

**Status** : answered (ADR-T53-001)

**Raised by** : proposal.md § Solution + § Risk

**Question** : the Dartastic ecosystem offers two integration
paths for Flutter applications :

- **Option A. `flutterrific_opentelemetry` (Flutter shim)** — pre-wired
  auto-instrumentation (app lifecycle, navigation via go_router,
  errors, user interactions). Less code in adopter projects, but
  introduces a thin layer on top of the SDK. v0.4.0, 42 days old.
- **Option B. `dartastic_opentelemetry` (Dart SDK) + custom Flutter wiring**
  — adopters write their own `NavigatorObserver`, BlocObserver,
  FlutterError.onError glue. More code but no shim dependency.
  v0.9.5, 9 days old (more battle-tested).

Which option does the FSM example + mobile-only template use ?

**Affects** : FR-T53-* (number of Dart files / wiring complexity),
NFR-T53-001 (zero new transitive dep budget), risk profile.

**Likely resolution** : **Option A** for the standard's primary
documented path AND for both FSM frontend + mobile-only template.
Rationale :
- Plan §0.3 explicitly cites flutterrific as the proposed integration.
- Less code for adopters = better DX.
- Shim's auto-instrumentation captures app lifecycle / nav / errors
  that adopter custom wiring routinely omits.
- The standard documents the Option B fallback in a "Migration off
  flutterrific" subsection for adopters who want the SDK directly.

If during design-phase prototyping (or implement-phase build)
flutterrific blocks integration (compile error, API mismatch,
runtime crash), fallback path is to swap pubspec to
`dartastic_opentelemetry` only and rewrite the navigation/bloc/error
observers from spec. The fallback adds ~50-80 LOC and is documented.

**Resolution** : <!-- to be filled by /forge:design via ADR-T53-001 -->

---

## Q-002 — Pin API on stable `0.9.0` vs beta `^1.0.0-beta.2`

**Status** : answered (ADR-T53-002)

**Raised by** : proposal.md § Source Documents table

**Question** : the Dartastic ecosystem has version skew between
its three packages :

| Package | Latest version | Depends on `_api` |
|---|---|---|
| `dartastic_opentelemetry_api` | 0.9.0 (stable) + 1.0.0-beta.x (unstable) | — |
| `dartastic_opentelemetry 1.1.0-beta.6` | latest | `^1.0.0-beta.2` |
| `flutterrific_opentelemetry 0.4.0` | latest | `^1.0.0-alpha` |

Pinning `dartastic_opentelemetry_api 0.9.0` stable creates a
constraint conflict with the SDK 0.9.5's `^1.0.0-beta.2` requirement.
Two paths :

- **Option A. Accept the beta `_api` line** — pin transitively via
  `dartastic_opentelemetry ^1.1.0-beta.6` ; `_api` resolves to
  `1.0.0-beta.2` (or later beta) per Dart pub solver. **Proposed.**
- **Option B. Downgrade SDK to a `_api 0.9.0`-compatible version** —
  find an older `dartastic_opentelemetry` that depends on `_api ^0.9.0`.
  Sacrifices recent SDK fixes for stable-line API.

**Affects** : NFR-T53-006 (no beta dep ratified) — Option A
formally accepts a beta dep in production.

**Likely resolution** : **Option A**, with a `WAIVER` comment block
in the standard's frontmatter rationale documenting :
- Beta line is the only resolvable path given current pub.dev state.
- Upgrade trigger : when `_api 1.0.0` GA ships, file a follow-up
  patch change to refresh the pin.
- Mitigation : the 3-axis checklist re-verification cadence
  (T5.2.B) catches downstream API drift at the 12-month review.

Pattern mirrors the `t5-cargo-pin-refresh::transport.yaml`
WAIVER comment for `connectrpc 0.3.3` (legitimate beta dependency
with documented upgrade trigger).

**Resolution** : <!-- to be filled by /forge:design via ADR-T53-002 -->

---

## Q-003 — Forward-pointer convention in affected archived changes

**Status** : answered (ADR-T53-003)

**Raised by** : proposal.md § Scope In — "Forward-pointers in
archived changes"

**Question** : T5.3 supersedes the Workiva pin shipped by 3 archived
changes (`b4-mobile-only`, `t5-otel-app`,
`t5-otel-dart-api-realign`). Per Article V audit-trail
immutability, the archived files MUST NOT be modified in place.
But a forward pointer is needed so a future reader of any of these
archives understands the standard has been superseded.

Two conventions on the table :

- **Option A. New `.forge-update-notes` file at the root of each
  archive directory** — single file with a "Superseded by:" line
  + change name + standard version. Proposed.
- **Option B. Append a new Q-NNN entry in each archive's
  `open-questions.md` with `Status: superseded-by-t5-3-otel-dartastic-realign`**
  — uses existing F.1 convention but the questions surface is
  closed-by-archive ; reopening Status feels semantically off.
- **Option C. Single forward-pointer in the T5.3 spec
  `archived_to:` field listing all 3 successor pointers** — no
  new files in the archived dirs ; only the new change's spec
  surface records the supersession.

**Affects** : auditability when an engineer inspects a single
archived change without consulting the T5.3 spec ; discoverability
without grep.

**Likely resolution** : **Option A** + **Option C combined**.
- A `.forge-update-notes` file in each of the 3 affected archives
  carries a single H2 "Superseded standard pin" with a one-paragraph
  notice + pointer to T5.3 (Option A — local discoverability).
- The T5.3 `.forge.yaml::depends_on` already lists the 3 archives ;
  a new `supersedes:` field (or comment) names them explicitly
  (Option C — global graph).
- Existing archived files (`.forge.yaml`, `proposal.md`, etc.)
  remain byte-identical.

This is the same pattern `t5-otel-dart-api-realign` could have used
for `t5-otel-app`'s Q-004 — minimal local crumb + global graph
edge.

**Resolution** : <!-- to be filled by /forge:design via ADR-T53-003 -->
