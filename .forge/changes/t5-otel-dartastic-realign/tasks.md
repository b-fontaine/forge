# Tasks: t5-otel-dartastic-realign
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order immutable : RED → GREEN → REFACTOR.
- `[Story: FR-T53-XXX]` tag per task (Article V.1).
- `[P]` parallelizable with other `[P]` in the same phase.
- Each phase ends with a gate task running `t5-otel-dartastic.test.sh`
  + verify.sh as relevant.
- ADRs T53-001..006 honored verbatim ; deviations require new ADR.

---

## Phase 1 — Foundation : RED harness + CI registration

### T-HAR — `t5-otel-dartastic.test.sh` skeleton

- [ ] **T-HAR-001** : Create `.forge/scripts/tests/t5-otel-dartastic.test.sh`
      with bash header (`set -uo pipefail`), source `_helpers.sh`,
      audit comment, `--level` parser, path variables (STD_FILE,
      REVIEW_MD, FSM_FRONTEND_DIR, MOBILE_ONLY_TMPL_DIR,
      CLI_ASSETS_DIR, CHANGELOG_MD, FORGE_CI_YML, ARCHIVED_DIRS).
      [Story: FR-T53-E-001 / FR-T53-E-002 / FR-T53-E-003]
- [ ] **T-HAR-002** : Add 13 L1 test stubs (`_test_t53_l1_001..013`)
      returning `_not_implemented`. Each maps 1:1 to FR-T53-E-004..016.
      [Story: FR-T53-E-004..016]
- [ ] **T-HAR-003** [P] : Add 2 L2 test stubs (`_test_t53_l2_001_fsm_flutter_pubget_analyze`,
      `_test_t53_l2_002_mobile_only_fresh_scaffold`) gated by
      `FORGE_T53_LIVE=1`, skip-pass otherwise.
      [Story: FR-T53-E-017 / FR-T53-E-018]
- [ ] **T-HAR-004** : Add main runner + `print_summary` ; exit 0 if
      `FAIL == 0`. Failure messages cite `[FR-T53-*]` first.
      [Story: NFR-T53-007]
- [ ] **T-HAR-005** [P] : Register `t5-otel-dartastic.test.sh` in
      `.github/workflows/forge-ci.yml` matrix immediately after
      `t5-2.test.sh` with `--level 1`. Keep file ≤ 300 lines
      (NFR-CI-002 / `t5-1.test.sh::_l1_017`). Compact one
      neighbouring comment if needed.
      [Story: FR-T53-F-001 / FR-T53-F-002]
- [ ] **T-HAR-006** : RED gate — confirm
      `bash .forge/scripts/tests/t5-otel-dartastic.test.sh --level 1`
      exits 1 with `Failed: 13 / Passed: 0`.
      [Story: NFR-T53-007]

### Phase 1 exit gate

13 L1 FAIL ; `t5-1.test.sh::_l1_017_ci_line_budget` still PASS ;
`verify.sh` overall PASS unchanged.

---

## Phase 2 — Standard rewrite v1.1.0 → v2.0.0

### T-STD — `flutter/opentelemetry.md` v2.0.0

- [ ] **T-STD-001** : Read current `flutter/opentelemetry.md` v1.1.0
      to inventory existing H2 sections + frontmatter ; identify
      what stays / what changes for v2.0.0.
      [Story: FR-T53-A-009]
- [ ] **T-STD-002** : Rewrite frontmatter — `version: 2.0.0`,
      `breaking_change: true`, `last_reviewed: 2026-05-18`,
      `pkg_*` pins refreshed (3 Dartastic packages),
      `forbidden:` block lists Workiva + phantom, `rationale`
      includes WAIVER block per ADR-T53-002.
      [Story: FR-T53-A-002 / -003 / -004 / -005 / -027 / NFR-T53-006]
- [ ] **T-STD-003** [P] : Update audit comment to `<!-- Audit: T.5.3 (t5-otel-dartastic-realign) ; supersedes Workiva pin from t5-otel-dart-api-realign -->`.
      [Story: FR-T53-A-006]
- [ ] **T-STD-004** : Add Status banner (Traces / Metrics / Logs —
      all 3 signals spec-aligned per OTel 1.31.0).
      [Story: FR-T53-A-007]
- [ ] **T-STD-005** : Insert "Source Documents — 3-axis verification"
      H2 with the 3-axis table verbatim from specs.md.
      [Story: FR-T53-A-008 / FR-T53-G-003]
- [ ] **T-STD-006** : Rewrite "Technology Stack" H2 — name the 3
      Dartastic packages, pub.dev publisher, OTel spec 1.31.0
      alignment.
      [Story: FR-T53-A-009 / FR-T53-A-010]
- [ ] **T-STD-007** : Rewrite "SDK Initialization" H2 — flutterrific
      `OTel.initialize(serviceName: ...)` + route observer
      registration pattern. Verified imports (FR-T53-A-010).
      [Story: FR-T53-A-009 / FR-T53-A-011]
- [ ] **T-STD-008** : Rewrite "Sampling" H2 — Dartastic
      `ParentBasedSampler(AlwaysOnSampler())` ; mention
      `TraceIdRatioBasedSampler` as available but discouraged ;
      preserve Phase A collector contract per ADR-T53-004 / ADR-OTEL-001.
      [Story: FR-T53-A-009 / FR-T53-A-012]
- [ ] **T-STD-009** : Rewrite "HTTP Instrumentation via Dio Interceptor"
      H2 with Dartastic-based interceptor + W3C propagator.
      [Story: FR-T53-A-009 / FR-T53-A-016]
- [ ] **T-STD-010** [P] : Rewrite "Navigation Observer" H2 —
      flutterrific auto-observer + Navigator 1.0 manual fallback.
      [Story: FR-T53-A-009 / FR-T53-A-017]
- [ ] **T-STD-011** [P] : Rewrite "BLoC Observer" H2 — Dartastic
      `Tracer` against `BlocObserver`.
      [Story: FR-T53-A-009 / FR-T53-A-018]
- [ ] **T-STD-012** [P] : Rewrite "User Interaction Spans" H2.
      [Story: FR-T53-A-009 / FR-T53-A-019]
- [ ] **T-STD-013** [P] : Rewrite "Error Instrumentation" H2 —
      `FlutterError.onError` + `runZonedGuarded` + Dartastic
      `Status.error` + `recordException`.
      [Story: FR-T53-A-009 / FR-T53-A-020]
- [ ] **T-STD-014** [P] : Rewrite "Custom Spans" H2 — semantic
      attribute conventions.
      [Story: FR-T53-A-009 / FR-T53-A-021]
- [ ] **T-STD-015** [P] : Rewrite "Context Propagation (W3C
      traceparent)" H2 — Dartastic `W3CTraceContextPropagator`.
      [Story: FR-T53-A-009 / FR-T53-A-022]
- [ ] **T-STD-016** : Add NEW H2 "Migration from v1.1.0 (Workiva → Dartastic)"
      with from→to symbol substitution table.
      [Story: FR-T53-A-013 / FR-T53-A-014 / FR-T53-A-015]
- [ ] **T-STD-017** : Update "Rules" H2 — add MUST NOT clauses for
      Workiva + phantom + skip-3-axis.
      [Story: FR-T53-A-023]
- [ ] **T-STD-018** [P] : Update "References" H2 — Dartastic
      pub.dev pages, OTel 1.31.0, ADR-OTEL-001.
      [Story: FR-T53-A-024]
- [ ] **T-STD-019** [P] : Add "Anti-patterns" subsection with Q-004
      + Q-006 worked examples.
      [Story: FR-T53-A-029]
- [ ] **T-STD-020** : Add Constitution xref — Article III.4 + IX
      (literal strings `Article III.4` + `Article IX` for harness
      grep).
      [Story: FR-T53-A-030 / NFR-T53-009]
- [ ] **T-STD-021** : Update `.forge/standards/index.yml` entry for
      `flutter/opentelemetry` — refresh triggers (add `dartastic`,
      `flutterrific`, `otlp-http`).
      [Story: FR-T53-A-026]
- [ ] **T-STD-022** : Append REVIEW.md ledger entry
      `## 2026-05-18 — Updated flutter/opentelemetry.md to v2.0.0 (t5-otel-dartastic-realign)`
      with breaking_change: true + Q-006 trigger + 3-axis
      checklist applied.
      [Story: FR-T53-A-025 / NFR-T53-003]
- [ ] **T-STD-023** : GREEN witness Phase 2 — run harness ; expect
      ~6/13 GREEN (FR-T53-E-004..010 + 016 ; FSM + mobile-only +
      forward-pointers still FAIL).
      [Story: FR-T53-E-004..016 partial]

### Phase 2 exit gate

~6 L1 GREEN ; standard v2.0.0 shipped ; `j7.test.sh` validates the
new frontmatter ; REVIEW.md entry asserted.

---

## Phase 3 — FSM frontend rewrite (5 Dart files)

### T-FSM — `examples/forge-fsm-example/frontend/`

- [ ] **T-FSM-001** : Update `pubspec.yaml` — replace
      `opentelemetry: ^0.18.x` with `dartastic_opentelemetry: ^1.1.0-beta.6`
      + `flutterrific_opentelemetry: ^0.4.0`.
      [Story: FR-T53-B-001]
- [ ] **T-FSM-002** : Read current `lib/core/telemetry/telemetry_setup.dart`
      to identify Workiva symbol usage ; map to Dartastic equivalents.
      [Story: FR-T53-B-003]
- [ ] **T-FSM-003** : Rewrite `lib/core/telemetry/telemetry_setup.dart`
      on Dartastic + flutterrific — `OTel.initialize(...)` +
      ParentBasedSampler(AlwaysOnSampler()) + endpoint env.
      [Story: FR-T53-B-003 / FR-T53-B-012 / FR-T53-B-013]
- [ ] **T-FSM-004** [P] : Rewrite `lib/core/telemetry/error_reporter.dart`
      on Dartastic `Status.error` + `recordException`.
      [Story: FR-T53-B-004]
- [ ] **T-FSM-005** [P] : Rewrite `lib/core/telemetry/interceptors/tracing_interceptor.dart`
      on Dartastic `Tracer` + `W3CTraceContextPropagator`.
      [Story: FR-T53-B-005 / FR-T53-B-010]
- [ ] **T-FSM-006** [P] : Rewrite `lib/core/telemetry/observers/tracing_navigation_observer.dart`
      on flutterrific built-in observer OR custom Dartastic wiring.
      [Story: FR-T53-B-006]
- [ ] **T-FSM-007** [P] : Rewrite `lib/core/telemetry/observers/tracing_bloc_observer.dart`
      on Dartastic `Tracer` against `BlocObserver`.
      [Story: FR-T53-B-007]
- [ ] **T-FSM-008** : Verify `lib/main.dart` still calls
      `await setupTelemetry()` before `runApp` ; update if function
      signature changed.
      [Story: FR-T53-B-008]
- [ ] **T-FSM-009** : Grep `examples/forge-fsm-example/frontend/lib/`
      for any remaining `package:opentelemetry/` (Workiva) import
      ; remove or rewrite each occurrence.
      [Story: FR-T53-B-009]
- [ ] **T-FSM-010** : Run `flutter pub get` in FSM frontend ;
      commit regenerated `pubspec.lock`.
      [Story: FR-T53-B-002 / FR-T53-B-014]
- [ ] **T-FSM-011** : Run `flutter analyze` in FSM frontend ;
      confirm exit 0 with zero warnings. **If any warning** :
      iterate on T-FSM-003..007 until clean.
      [Story: FR-T53-B-015]
- [ ] **T-FSM-012** : GREEN witness Phase 3 — run harness ;
      FR-T53-E-012 should flip GREEN.
      [Story: FR-T53-E-012]

### Phase 3 exit gate

~8 L1 GREEN ; FSM frontend `flutter pub get` + `flutter analyze`
both exit 0 (Toolchains required ; if `flutter` absent, defer to
Phase 7 L2 leg).

---

## Phase 4 — Mobile-only template rewrite

### T-MOB — `.forge/templates/archetypes/mobile-only/`

- [ ] **T-MOB-001** : Read current `pubspec.yaml.tmpl` to confirm
      Workiva `opentelemetry: ^0.18` + phantom `opentelemetry_sdk`
      presence.
      [Story: FR-T53-C-001]
- [ ] **T-MOB-002** : Rewrite `pubspec.yaml.tmpl` — remove Workiva
      + phantom, add Dartastic + flutterrific.
      [Story: FR-T53-C-001]
- [ ] **T-MOB-003** : Rewrite `lib/observability/otel_init.dart.tmpl`
      on flutterrific (or Dartastic SDK pure with custom wiring per
      ADR-T53-001 fallback if applicable).
      [Story: FR-T53-C-002]
- [ ] **T-MOB-004** [P] : Mirror `pubspec.yaml.tmpl` to
      `cli/assets/.forge/templates/archetypes/mobile-only/pubspec.yaml.tmpl`.
      `diff -q` must return zero.
      [Story: FR-T53-C-003 / NFR-T53-005]
- [ ] **T-MOB-005** [P] : Mirror `otel_init.dart.tmpl` to
      `cli/assets/.forge/templates/archetypes/mobile-only/lib/observability/otel_init.dart.tmpl`.
      [Story: FR-T53-C-004 / NFR-T53-005]
- [ ] **T-MOB-006** : Grep `.forge/templates/archetypes/mobile-only/lib/`
      AND `cli/assets/.forge/templates/archetypes/mobile-only/lib/`
      for any remaining Workiva or phantom import ; remove.
      [Story: FR-T53-C-005]
- [ ] **T-MOB-007** [P] : Update `README.md.tmpl` if it cites the
      observability stack — replace Workiva mention with Dartastic.
      [Story: FR-T53-C-006]
- [ ] **T-MOB-008** [P] : Check test templates under
      `mobile-only/test/` and `integration_test/` for observability
      references — rewrite or tag "not affected".
      [Story: FR-T53-C-009]
- [ ] **T-MOB-009** : GREEN witness Phase 4 — run harness ;
      FR-T53-E-013 + FR-T53-E-014 should flip GREEN.
      [Story: FR-T53-E-013 / FR-T53-E-014]

### Phase 4 exit gate

~10 L1 GREEN ; mobile-only template + cli/assets mirror in sync ;
no Workiva / phantom remaining in template tree.

---

## Phase 5 — Forward-pointers in archived changes

### T-FWD — `.forge-update-notes` files

- [ ] **T-FWD-001** : Create
      `.forge/changes/b4-mobile-only/.forge-update-notes` with
      canonical H1 + H2 "Superseded standard pin (T5.3, 2026-05-18)"
      + body referencing T5.3 + v2.0.0 standard.
      [Story: FR-T53-D-001]
- [ ] **T-FWD-002** [P] : Create
      `.forge/changes/t5-otel-app/.forge-update-notes` ; same
      structure.
      [Story: FR-T53-D-002]
- [ ] **T-FWD-003** [P] : Create
      `.forge/changes/t5-otel-dart-api-realign/.forge-update-notes` ;
      same structure.
      [Story: FR-T53-D-003]
- [ ] **T-FWD-004** : Verify archived files byte-identical to pre-T5.3
      state via `git diff origin/main -- .forge/changes/{b4-mobile-only,t5-otel-app,t5-otel-dart-api-realign}/`
      excluding the new `.forge-update-notes`. Diff must be empty.
      [Story: FR-T53-D-004 / NFR-T53-008]
- [ ] **T-FWD-005** : GREEN witness Phase 5 — FR-T53-E-015 should
      flip GREEN.
      [Story: FR-T53-E-015]

### Phase 5 exit gate

~11 L1 GREEN ; 3 forward-pointer files present ; archives
byte-identical.

---

## Phase 6 — CHANGELOG + final L1 confirmation

### T-CHG — CHANGELOG + final gate

- [ ] **T-CHG-001** : Add CHANGELOG.md [Unreleased] entry under
      `### Changed (BREAKING)` citing change name + bump + 3-axis
      checklist inaugural + Q-006 + v0.4.0-rc.1 target.
      [Story: FR-T53-F-003]
- [ ] **T-CHG-002** : Run `bash .forge/scripts/tests/t5-otel-dartastic.test.sh --level 1` ;
      confirm **13/13 GREEN, 0 FAIL**.
      [Story: FR-T53-E-004..016]
- [ ] **T-CHG-003** [P] : Run `bash .forge/scripts/verify.sh` ;
      confirm overall PASS.
      [Story: NFR-T53-004]
- [ ] **T-CHG-004** [P] : Run `bash .forge/scripts/constitution-linter.sh` ;
      confirm overall PASS.
      [Story: NFR-T53-004]
- [ ] **T-CHG-005** [P] : Run `bash .forge/scripts/tests/t5-1.test.sh --level 1` ;
      confirm 17/17 GREEN incl. CI line budget.
      [Story: FR-T53-F-002]
- [ ] **T-CHG-006** [P] : Run `bash .forge/scripts/tests/t5-2.test.sh --level 1` ;
      confirm 8/8 GREEN (T5.2 unbroken by T5.3).
      [Story: NFR-T53-004]
- [ ] **T-CHG-007** [P] : Run `bash bin/validate-standards-yaml.sh` ;
      all 6 YAML standards STD-PASS (J.7 validator).
      [Story: NFR-T53-004]

### Phase 6 exit gate

ALL L1 GREEN ; ALL framework gates PASS ; no regression.

---

## Phase 7 — L2 live validation (`FORGE_T53_LIVE=1`)

### T-L2 — flutter pub get + analyze opt-in

- [ ] **T-L2-001** : Run
      `FORGE_T53_LIVE=1 bash .forge/scripts/tests/t5-otel-dartastic.test.sh --level 1,2` ;
      L2.001 must run `flutter pub get` on FSM frontend (exit 0).
      Capture output for archive.
      [Story: FR-T53-E-017]
- [ ] **T-L2-002** [P] : L2.002 must scaffold mobile-only into
      `mkdtemp` via `forge init --archetype mobile-only --target <tmp>`
      then `flutter pub get` + `flutter analyze` (both exit 0).
      [Story: FR-T53-E-018 / FR-T53-C-007 / FR-T53-C-008]
- [ ] **T-L2-003** : Wall-clock benchmark — L1 ≤ 5 s, L2 ≤ 120 s
      per leg ; total ≤ 250 s with FORGE_T53_LIVE=1.
      [Story: NFR-T53-002]

### Phase 7 exit gate

L1+L2 GREEN locally with FORGE_T53_LIVE=1 ; output captured.

---

## Phase 8 — Independent code-reviewer pre-archive + flip status

### T-REV — independent review (MANDATORY per T5.2 self-validation lesson)

- [ ] **T-REV-001** : Delegate to `oh-my-claudecode:code-reviewer`
      with full context (proposal + specs + design + tasks + delta
      vs main). Reviewer MUST verify : (a) 3-axis checklist
      application across the standard / FSM / mobile-only ; (b)
      Dartastic symbol accuracy via Context7 ; (c) NO fabricated
      constitutional references ; (d) Article V immutability of
      the 3 archived changes ; (e) drift guard ADR-T52-003
      preserved (literal `Article III.4` + canonical H2 titles).
      [Story: NFR-T53-010]
- [ ] **T-REV-002** : Process review findings. CRITICAL / HIGH
      findings MUST be fixed before archive. MEDIUM / LOW findings
      either fixed or deferred with documented rationale.
      [Story: NFR-T53-010]
- [ ] **T-REV-003** : Re-run all gates (L1 + L2 + verify.sh +
      linter + t5-1 + t5-2) after fix-forward iterations.
      [Story: NFR-T53-004]

### T-FLIP — status `implemented`

- [ ] **T-FLIP-001** : Update `.forge.yaml` :
      `status: implemented`, `timeline.implemented: 2026-05-18`.
      [Story: process]
- [ ] **T-FLIP-002** : `git status --short` ; confirm diff scope :
      ~12-15 files all T5.3-related (1 standard + 1 index +
      1 REVIEW + 8 mobile-only/FSM + 3 forward-pointers + 1
      harness + 1 CI + 1 CHANGELOG + 5 change docs).
      [Story: NFR-T53-005]

### Phase 8 exit gate

`status: implemented` ; ALL gates GREEN ; independent reviewer
verdict captured ; ready for `/forge:review` user-driven gate +
`/forge:archive`.

---

> **STOP at Phase 8 exit.** Per user instruction : T5.3 stops at
> `implemented` for user verification, BEFORE push + PR + archive.

---

## Constitutional Compliance Gate (per phase)

| Phase | Article I (TDD) | Article III.4 | Article V (Audit) | Article VI (Flutter) | Article XII (Lifecycle) | Verdict |
|---|---|---|---|---|---|---|
| Phase 1 | RED 0/13 | N/A | Harness audit comment | N/A | N/A | ✅ |
| Phase 2 | GREEN ~6/13 | 3-axis embedded in standard | REVIEW append | N/A | Breaking bump documented | ✅ |
| Phase 3 | GREEN ~8/13 (Dart files compile) | Symbols verified via Context7 | N/A | Clean Arch preserved | N/A | ✅ |
| Phase 4 | GREEN ~10/13 | Symbols verified | mirror discipline | Clean Arch preserved | N/A | ✅ |
| Phase 5 | GREEN ~11/13 | N/A | Article V archives unchanged | N/A | N/A | ✅ |
| Phase 6 | GREEN 13/13 | All checklist surfaces grep-verified | N/A | N/A | N/A | ✅ |
| Phase 7 | L2 captured | `flutter analyze` GREEN = symbol accuracy | N/A | N/A | N/A | ✅ |
| Phase 8 | Independent reviewer | Reviewer caught any drift | Reviewer verified | N/A | N/A | ✅ |

No BLOCK conditions raised.

---

> **Next step (autonomous)** : `/forge:implement t5-otel-dartastic-realign`
> in TDD order. After Phase 8 → STOP for user verification before
> push + PR.
