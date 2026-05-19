# Design: t5-otel-dartastic-realign
<!-- Status: designed -->
<!-- Schema: default -->

> Read alongside `specs.md` (FR-T53-* / NFR-T53-*) and
> `open-questions.md` (Q-001..Q-003). This document locks the
> implementation strategy and resolves Q-001 / Q-002 / Q-003 via
> ADR-T53-001..003, plus three supporting ADRs (004 sampling
> dual-stage preservation, 005 harness pattern, 006 cli/assets
> mirror discipline).

T5.3 is the **inaugural application** of T5.2's 3-axis platform
verification checklist (T5.2 was archived 2026-05-18, just before
this change). The design therefore carries an explicit "checklist
applied inline" surface (`design.md::Source Documents`) that future
T5.x / T6 ratifications will mirror.

---

## Architecture Decisions

### ADR-T53-001 — `flutterrific_opentelemetry` shim (Option A) with documented SDK fallback (resolves Q-001)

**Context** : Dartastic offers two integration paths for Flutter
applications :
- **Option A** : `flutterrific_opentelemetry 0.4.0` Flutter shim
  with pre-wired auto-instrumentation (lifecycle / go_router /
  errors). 42 days old, less battle-tested.
- **Option B** : `dartastic_opentelemetry 1.1.0-beta.6` Dart SDK pure
  with adopter-authored Flutter wiring. 9 days since last release,
  more active maintenance.

**Decision** : **Option A as primary path** for the v2.0.0 standard,
FSM frontend, and mobile-only template. **Option B documented as
fallback** in a "Migration off flutterrific" subsection of the
standard.

Rationale :
- Plan §0.3 explicitly cites flutterrific as the proposed integration.
- Adopter DX : auto-instrumentation captures app lifecycle / nav /
  errors that custom wiring routinely omits.
- The standard makes the fallback discoverable (Option B path),
  so adopters who hit a flutterrific blocker have a documented
  exit ramp.
- During implementation, if `flutterrific 0.4.0` blocks the FSM
  frontend build (compile error, API mismatch, runtime crash),
  the design phase prototyping result triggers a fallback to
  Option B without re-running `/forge:design`. The fallback is
  captured in `design.md` not the standard, so adopter docs stay
  stable.

**Implementation contract** :
- Standard v2.0.0 documents flutterrific imports + init as
  primary ; Option B as fallback subsection.
- FSM `pubspec.yaml` declares both `flutterrific_opentelemetry: ^0.4.0`
  AND `dartastic_opentelemetry: ^1.1.0-beta.6` (SDK transitive but
  explicit for adopter visibility).
- Mobile-only template same pattern.

**Consequences** :
- ✅ Less Dart code in FSM (~30-50 LOC) vs Option B.
- ✅ Auto-instrumentation of go_router / lifecycle / errors via
  flutterrific.
- ⚠️ Flutterrific is younger ; risk mitigated by SDK fallback
  documentation + 3-axis checklist ratification.
- ⚠️ The transitive `_api: ^1.0.0-alpha` of flutterrific conflicts
  with SDK's `_api: ^1.0.0-beta.2` — pub solver resolves to
  beta.2+ (alpha range subsumed by beta). Tested empirically during
  implementation L2 leg.

**Constitution Compliance** : Article III.4 (no fabricated symbols
— flutterrific API verified via pub.dev README + Context7).
Article VI (Flutter Arch — shim sits in the observability side
concern layer, doesn't pollute application code).

---

### ADR-T53-002 — Beta-line API waiver formally ratified (resolves Q-002)

**Context** : the dependency graph forces `dartastic_opentelemetry_api`
to resolve at `^1.0.0-beta.2` (transitive via SDK 0.9.5's
constraint). Pinning the stable `0.9.0` line is impossible without
downgrading the SDK to an older incompatible version.

**Decision** : **accept the beta API pin with a WAIVER block** in
the v2.0.0 standard frontmatter `rationale`.

Pattern verbatim from `transport.yaml v1.2.0` WAIVER comment
(`t5-cargo-pin-refresh` 2026-05-16) :

```yaml
rationale: >-
  Flutter OTel observability via Dartastic ecosystem.
  WAIVER (T5.3) : dartastic_opentelemetry_api pins at
  ^1.0.0-beta.2 — the only resolvable version given
  dartastic_opentelemetry 1.1.0-beta.6's dependency constraint.
  Stable line 0.9.0 incompatible. Upgrade trigger : when
  dartastic_opentelemetry_api 1.0.0 GA ships, file a follow-up
  patch change (target naming : t5-3-1-dartastic-api-ga-refresh).
  3-axis checklist re-verification cadence (T5.2.B SHOULD at
  12-month review) catches any post-GA drift independently.
```

**Why not Option B (downgrade SDK)** :
- The older SDK lacks 9 days of upstream fixes.
- The OTel spec 1.31.0 alignment is on the latest SDK ; downgrading
  forfeits that.
- Beta lines for OTel implementations are routinely production-grade
  given the spec is moving (the Workiva pkg itself was "Beta /
  Alpha / Unimplemented" — same risk class).

**Consequences** :
- ✅ Standard ships with the actually-resolvable version graph.
- ✅ WAIVER pattern matches existing transport.yaml precedent ;
  reviewers know the convention.
- ⚠️ Production code depends on a `-beta.N` API. **Mitigation** :
  the 3-axis checklist + REVIEW.md cadence + named upgrade trigger
  (`t5-3-1-dartastic-api-ga-refresh`) document the watch point.

**Constitution Compliance** : Article XII (Standards Lifecycle —
the WAIVER follows the standards-lifecycle.md v1.1.0 rules for
breaking bumps + REVIEW ledger). Article III.4 (the WAIVER itself
is the absence-of-hallucination — it transparently documents the
beta acceptance instead of pretending the API is stable).

---

### ADR-T53-003 — Forward-pointer convention = `.forge-update-notes` file + global graph (resolves Q-003)

**Context** : T5.3 supersedes the Workiva pin shipped by 3 archived
changes. Article V immutability forbids modifying the archives in
place.

**Decision** : **Option A + Option C combined** :

1. **Option A (per-archive crumb)** : add a new file
   `.forge-update-notes` at the root of each affected archive
   directory. Format :
   ```markdown
   # Update Notes — <archive-name>

   <!-- Audit: T.5.3 (t5-otel-dartastic-realign, 2026-05-18) -->

   ## Superseded standard pin (T5.3, 2026-05-18)

   The Workiva `opentelemetry: ^0.18` pin shipped by this archive's
   [proposal.md / specs.md / template] has been superseded by the
   Dartastic ecosystem in T5.3. See
   `.forge/standards/flutter/opentelemetry.md` v2.0.0 and
   `.forge/changes/t5-otel-dartastic-realign/` for the new pin
   + 3-axis verification.

   This file is the only addition to this archived change since
   its archive date — all other files (`.forge.yaml`,
   `proposal.md`, etc.) remain byte-identical per Article V
   immutability.
   ```
2. **Option C (global graph)** : the T5.3 `.forge.yaml::depends_on`
   already lists the 3 archives ; an additional comment block
   names them as "superseded" explicitly.

**Implementation contract** :
- 3 new files created : `b4-mobile-only/.forge-update-notes`,
  `t5-otel-app/.forge-update-notes`,
  `t5-otel-dart-api-realign/.forge-update-notes`.
- Existing files in those 3 directories remain byte-identical
  (verified by diff during L1 harness run).
- T5.3 `.forge.yaml` keeps the existing comment block (no schema
  change to introduce a `supersedes:` field — defer to a future
  schema bump if the supersession graph becomes a first-class
  query target).

**Consequences** :
- ✅ Local discoverability : an engineer reading any of the 3
  archives sees the `.forge-update-notes` and immediately knows
  the standard has moved.
- ✅ Global discoverability : the T5.3 spec + depends_on edges
  capture the supersession.
- ✅ Article V preserved : no archived file modified.
- ⚠️ Adds a new file convention (`.forge-update-notes`). Pattern
  documented in T5.3 itself ; future changes that supersede
  existing pins can copy the pattern.

**Constitution Compliance** : Article V.1 / V.2 (audit trail
preserved — the new file is additive, not retroactive). Article
III (specs before code — the convention is specified by
FR-T53-D-001..006).

---

### ADR-T53-004 — Sampling dual-stage preserved across the substitution

**Context** : ADR-OTEL-001 (from `t5-otel-stack`, 2026-05-10)
established a dual-stage sampling model :
- **Phase A (collector)** : `processors.probabilistic_sampler`
  applies env-tier overlays at the collector level (OTel Collector
  config).
- **Phase B (SDK)** : the SDK uses `ParentBasedSampler(AlwaysOnSampler())`
  so every span produced by the app is **always emitted** (Phase A
  decides post-hoc).

Workiva `opentelemetry 0.18.11` lacked `TraceIdRatioBasedSampler` ;
the v1.1.0 standard documented the dual-stage rationale.

**Decision** : Dartastic preserves the dual-stage model verbatim.
The v2.0.0 standard documents :
- Phase A unchanged (collector contract per ADR-OTEL-001).
- Phase B SDK init uses Dartastic's `ParentBasedSampler(AlwaysOnSampler())`
  pattern :
  ```dart
  await OTel.initialize(
    serviceName: 'forge-fsm-frontend',
    endpoint: 'http://localhost:4318',
    sampler: ParentBasedSampler(AlwaysOnSampler()),
  );
  ```
- Dartastic ALSO exposes `TraceIdRatioBasedSampler` (unlike Workiva)
  — documented for adopters who want pure SDK-side sampling, but
  the Forge standard recommends Phase A + Phase B `AlwaysOn` as
  default.

**Constitution Compliance** : Article IX (Observability —
collector contract preserved means downstream stacks unaffected by
the substitution).

---

### ADR-T53-005 — Harness structure mirrors T5.2 / I.5 / K.3 pattern

**Context** : Forge has converged on a stable harness pattern.

**Decision** : `t5-otel-dartastic.test.sh` follows :
- `#!/usr/bin/env bash` + `set -uo pipefail` + `_helpers.sh` source.
- Path variables block at top (STD_FILE, REVIEW_MD, FSM_FRONTEND_DIR,
  MOBILE_ONLY_DIR, CLI_ASSETS_DIR, CHANGELOG_MD, FORGE_CI_YML,
  ARCHIVED_DIRS).
- 13 L1 test functions (FR-T53-E-004..016 mapped 1:1).
- 2 L2 test functions opt-in via `FORGE_T53_LIVE=1`.
- Failure messages cite `[FR-T53-*]` first.

**Consequences** : zero new convention to learn ; reuses J.7 /
I.5 / K.3 / T5.2 wiring.

---

### ADR-T53-006 — cli/assets mirror discipline asserted by L1

**Context** : Forge's cli/assets directory must stay byte-identical
to source templates so the published npm tarball includes the
real templates. Existing tests (T5.1 archetypes-smoke) assume this.

**Decision** : two L1 assertions in `t5-otel-dartastic.test.sh`
diff-check the cli/assets mirrors :
- `cli/assets/.forge/templates/archetypes/mobile-only/pubspec.yaml.tmpl`
  vs source via `diff -q`.
- `cli/assets/.forge/templates/archetypes/mobile-only/lib/observability/otel_init.dart.tmpl`
  vs source via `diff -q`.

Failure on any mismatch (non-zero exit code from `diff -q`) fails
the test. This guards against forgotten mirror updates — a
historically tricky bug class in Forge releases.

---

## Component Design

```mermaid
flowchart LR
    A[.forge/standards/flutter/<br/>opentelemetry.md v2.0.0<br/><i>breaking bump</i>]
    B[examples/forge-fsm-example/<br/>frontend/<br/><i>5 .dart files + pubspec</i>]
    C[.forge/templates/archetypes/<br/>mobile-only/<br/><i>pubspec.yaml.tmpl + otel_init.dart.tmpl</i>]
    D[cli/assets/.forge/templates/<br/>archetypes/mobile-only/<br/><i>mirror</i>]
    E[.forge/changes/{b4-mobile-only,<br/>t5-otel-app, t5-otel-dart-api-realign}/<br/>.forge-update-notes]
    F[.forge/standards/REVIEW.md<br/><i>append-only ledger entry</i>]
    G[.forge/scripts/tests/<br/>t5-otel-dartastic.test.sh<br/><i>13 L1 + 2 L2 opt-in</i>]
    H[.github/workflows/forge-ci.yml<br/><i>matrix entry</i>]
    I[CHANGELOG.md<br/><i>[Unreleased] BREAKING</i>]

    A -- "embeds 3-axis<br/>checklist verbatim" --> A
    A -- "supersedes Workiva pin in" --> E
    B -- "rewritten on" --> A
    C -- "rewritten on" --> A
    D -- "byte-identical mirror" --> C
    A -- "Article XII<br/>append-only" --> F
    G -- "asserts content of" --> A
    G -- "asserts content of" --> B
    G -- "asserts content of" --> C
    G -- "asserts diff" --> D
    G -- "asserts presence of" --> E
    G -- "asserts entry of" --> F
    H -- "registers" --> G
    I -- "documents bump from" --> A
```

---

## Authoring Strategy

Standard TDD : RED harness first, then deliverables, GREEN
witness at each phase boundary.

1. **Phase 1 (Foundation)** — Create harness skeleton with 13 L1 +
   2 L2 stubs all FAILING. Confirm RED witness 0/13.
2. **Phase 2 (Standard)** — Rewrite `flutter/opentelemetry.md`
   v2.0.0. Most L1 (frontmatter, imports, no-Workiva, 3-axis, etc.)
   flip GREEN.
3. **Phase 3 (FSM frontend)** — Rewrite 5 Dart files + pubspec ;
   regenerate pubspec.lock. FSM-related L1 GREEN.
4. **Phase 4 (Mobile-only template)** — Rewrite pubspec.yaml.tmpl
   + otel_init.dart.tmpl ; mirror in cli/assets. Mobile-related L1
   GREEN.
5. **Phase 5 (Forward-pointers)** — Add 3 `.forge-update-notes`
   files. Forward-pointer L1 GREEN.
6. **Phase 6 (REVIEW + CHANGELOG + CI)** — Append REVIEW.md ledger,
   CHANGELOG `[Unreleased]` BREAKING entry, register harness in
   forge-ci.yml (compact a neighbouring comment if line budget
   tight).
7. **Phase 7 (L2 validation)** — Run `FORGE_T53_LIVE=1` locally
   (requires `flutter` on PATH). Confirm `flutter pub get` +
   `flutter analyze` GREEN on FSM frontend AND on fresh mobile-only
   scaffold.
8. **Phase 8 (QA gate + independent review)** — Run all gates
   (verify.sh + linter + t5-1 line budget + t5-2 harness +
   t5-otel-dartastic.test.sh) ; delegate to independent
   `code-reviewer` agent per NFR-T53-010.

---

## Testing Strategy

| Layer | Coverage | Tool |
|---|---|---|
| L1 grep | FR-T53-A (standard) + FR-T53-B (FSM pubspec) + FR-T53-C (mobile-only tmpl) + FR-T53-D (forward-pointers) + FR-T53-G (3-axis embed) | `grep` / `bash` |
| L1 diff | FR-T53-E-014 (cli/assets mirror) | `diff -q` |
| L1 grep | FR-T53-F-001 (CI registration) + FR-T53-F-003 (CHANGELOG entry) | `grep` |
| L2 opt-in (`FORGE_T53_LIVE=1`) | FR-T53-B-014 / B-015 / C-007 / C-008 (real Flutter compile) | `flutter pub get` + `flutter analyze` |
| Manual review | FR-T53-A H2 prose quality, Dart code correctness | PR review + independent code-reviewer pass per NFR-T53-010 |
| BDD scenarios | BDD-T53-001..003 | Reviewed at archive time ; not auto-executed (no end-to-end runtime harness for FSM/mobile in CI today) |

---

## Standards Applied

- `.forge/standards/flutter/opentelemetry.md` — bumped v1.1.0 →
  v2.0.0 (this change is the bumper).
- `.forge/standards/global/standards-lifecycle.md` v1.1.0
  (T5.2) — drives the breaking bump procedure (REVIEW.md
  append-only, frontmatter `breaking_change: true`, 3-axis
  re-verification cadence).
- `.forge/standards/global/open-questions.md` (F.1) — drives the
  Q-001..Q-003 lifecycle.
- `.forge/standards/global/janus-orchestration-rules.md` (J.8) —
  Janus refusal rules unaffected (no archetype change).
- `.forge/standards/observability.yaml` (T4) — collector contract
  per ADR-OTEL-001 preserved.

No new standard introduced. The bumped standard's content is
within `flutter/opentelemetry.md`'s existing scope.

---

## Constitution Compliance Gate

| Article | Risk | Verdict |
|---|---|---|
| I (TDD) | Harness RED first ; flipped GREEN cluster-by-cluster. | ✅ |
| II (BDD) | 3 BDD scenarios in specs.md ; reviewed at archive (not auto-executed). | ✅ |
| III (Specs before code) | proposal → specs → design → tasks pipeline followed. | ✅ |
| III.4 (Ambiguity Protocol) | 3-axis checklist applied inline ; no fabricated symbols (Context7-verified) ; no fabricated constitutional refs (verified against `.forge/constitution.md`). | ✅ Reinforced |
| V (Compliance Gate / audit trail) | Archived changes byte-identical ; new `.forge-update-notes` files only ; REVIEW.md append-only. | ✅ |
| VI (Flutter Arch) | Clean Architecture preserved ; observability stays in `core/telemetry/` (FSM) / `lib/observability/` (mobile). | ✅ |
| VIII (Infrastructure) | N/A — no infra change. Collector contract unchanged. | ✅ N/A |
| IX (Observability) | Reinforced — 3 signals now implementable on the consuming archetypes' target platforms. | ✅ Reinforced |
| XII (Governance / Standards Lifecycle) | Breaking bump documented per standards-lifecycle.md v1.1.0 ; WAIVER block for beta API per ADR-T53-002 ; REVIEW.md ledger. | ✅ |

**No BLOCK conditions raised.** Design ratified.

---

## Open Questions resolution

- **Q-001** : resolved by ADR-T53-001 — Option A (flutterrific
  shim) primary, Option B (SDK pure) documented fallback.
- **Q-002** : resolved by ADR-T53-002 — Beta API pin accepted via
  WAIVER block, upgrade trigger named.
- **Q-003** : resolved by ADR-T53-003 — `.forge-update-notes` file
  per archive (Option A) + global graph via T5.3 spec
  `depends_on` (Option C).

`open-questions.md` Status fields will be flipped to `answered`
referencing the respective ADRs.

---

> **Next step** : `/forge:plan t5-otel-dartastic-realign` to
> derive `tasks.md` from this design + specs. Open Questions Gate
> requires Q-001 / Q-002 / Q-003 = `answered` before plan can
> run.
