# Tasks: b9-1-schema

<!-- Status: implemented -->
<!-- Schema: default -->
<!-- Audit: B.9.1 (docs/new-archetypes-plan.md §5.2 — mobile-pwa-first/2.0.0 archetype scaffold schema) -->

TDD-ordered (Article I — RED before GREEN, always). Two deliverables: a narrow,
default-preserving patch to `check_versioned_schema_siblings` (ADR-B9-1-001) and the
declarative schema file, plus their shared harness. Per design.md the harness is
authored FIRST and must fail before either is written.

**Ordering constraint (load-bearing).** The validator patch MUST land **before** the
schema file. A `client-only` schema authored against the unpatched validator would KO
on the `{backend, frontend, infra}` invariant and turn `verify.sh` RED mid-change.
Phase 2 therefore precedes Phase 3 and the two must not be reordered.

## Phase 1: RED — failing harness

- [x] **T1.1** Author `.forge/scripts/tests/b9-1.test.sh` (bash + Python3 inline
  PyYAML, mirroring `b6-1.test.sh` / `b7-1.test.sh`). Delivered as **23 L1 + 1 L2
  opt-in** — T-024 became T-L2-001 because asserting the `forge init` exit code needs a
  built+bundled CLI, which L1 must not depend on.
  [Story: FR-B9-1-001..042, NFR-B9-1-002/004]
- [x] **T1.2** Run `bash .forge/scripts/tests/b9-1.test.sh --level 1` → **verify RED**.
  Expected failure set: every schema assertion (file absent) **plus** T-014
  (unknown-`layer_profile` KO does not exist yet). T-012/T-013 (backward-compat +
  triple-still-enforced) MUST already be GREEN — they describe today's behaviour, and
  a RED there means the harness is wrong, not the code. Capture RED evidence.
  [Gate: Article I]

## Phase 2: GREEN part A — validator patch (ADR-B9-1-001)

- [x] **T2.1** Patch `.forge/scripts/validate-foundations.sh` inside the
  versioned-sibling Python heredoc, replacing the `required = {...}` block at
  `:436-438` with the `layer_profile` gate from design.md. Default `multi-layer`;
  reject unknown values; leave the per-layer field loop (`:439-445`) untouched.
  **Do NOT touch the canonical `FR-GL-001` check at `:125`** — different check,
  different family, asserted by `foundations.test.sh:140`.
  [Story: FR-B9-1-014, ADR-B9-1-001]
- [x] **T2.2** Append `profile={layer_profile}` to the versioned OK line. Safe because
  `b8-3b.test.sh::_test_b83b_l1_004` matches the line **prefix** with `grep -qF`
  (verified 2026-07-27). [Story: ADR-B9-1-001]
- [x] **T2.3** Run `bash .forge/scripts/tests/b9-1.test.sh --level 1` → T-012/T-013/T-014
  **GREEN**; all schema assertions still RED (file absent). [Gate: Article I]
- [x] **T2.4** Run `bash .forge/scripts/validate-foundations.sh` → the three existing
  versioned schemas (`full-stack-monorepo/2.0.0`, `ai-native-rag/1.0.0`,
  `event-driven-eu/1.0.0`) still PASS **with no edit to any of them**.
  [Story: FR-B9-1-014]
- [x] **T2.5** Run `bash .forge/scripts/tests/b8-3b.test.sh --level 1` (12 L1) and
  `foundations.test.sh` → **GREEN**. These own the patched function and the untouched
  canonical check respectively. [Story: FR-B9-1-013]

## Phase 3: GREEN part B — author the schema file

- [x] **T3.1** Create `.forge/schemas/mobile-pwa-first/2.0.0.yaml` with the candidate
  header block + identity fields (`name`/`version: "2.0.0"`/`stage: candidate`/
  `scaffoldable: false`). [Story: FR-B9-1-002/003/005]
- [x] **T3.2** Add `description` + `tdd_enforced` / `bdd_required_for_user_facing` /
  `coverage_threshold: 80` / `golden_tests_required`. [Story: FR-B9-1-004/006] [P]
- [x] **T3.3** Add `layer_profile: client-only` + `layers`: `app` (path `.`,
  `FR-APP-`, Hera) and `web-pwa` (path `web-pwa/`, `FR-PWA-`, Iris-Web). No third
  layer — FR-B9-1-012 forbids declaring a layer that scaffolds nothing.
  [Story: FR-B9-1-010/011/012, ADR-B9-1-004] [P]
- [x] **T3.4** Add the **inlined** `phases` — proposal → specs → `channel-decision` →
  features → design → tasks → implementation → review → archive — plus the
  `pwa_specifics` block (installability, offline shell, Web Push/VAPID, iOS fallback
  rule as contract text, no pins). No `extends:` key.
  [Story: FR-B9-1-020..023, ADR-B9-1-003] [P]
- [x] **T3.5** Add `components` reference-only: qwik-city→`web-frontend.yaml`,
  oidc→`identity.yaml`, state-management→`state-management.yaml`,
  observability→`observability.yaml`; service-worker / web-push / offline-shell /
  manifest → `delivered_by: B.9.2`, **no inline pin, no invented standard name**.
  [Story: FR-B9-1-030/031/032, ADR-B9-1-005] [P]
- [x] **T3.6** Run `b9-1.test.sh --level 1` → **verify GREEN (23/23 L1)**; the L2 leg is
  run separately at T5.2. [Gate: Article I]

## Phase 4: Mirror sync + CI registration

- [x] **T4.1** ~~Sync across 7 copies~~ — **design claim corrected at impl**: only
  **1 committed file** changes. `cli/assets/` is gitignored (`npm run bundle` output,
  regenerated — verified by running the real bundler: zero drift vs. the manual copy);
  the 5 copies under `examples/` are 396-line B.1-baseline scaffolded artefacts that
  never contained `check_versioned_schema_siblings` and MUST NOT be synced. T-023 was
  rewritten to assert consistency of the bundled copy **only when present** (a fresh
  CI checkout has no `cli/assets/`) plus the non-leak invariant on the 5 artefacts.
  [Story: ADR-B9-1-001]
- [x] **T4.2** Register `"b9-1.test.sh --level 1"` in the `.github/workflows/forge-ci.yml`
  harness matrix. **Budget check**: the file is at 409 lines against the NFR-CI-002
  ceiling of **420** (set by `b6-8`). Measured after the edit: **412** (the entry plus
  two explanatory comment lines), so it fits with 8 lines of headroom. If
  it ever overflowed, the ceiling is asserted in **four** harnesses
  (`b6-8`, `c1`, `t5-1`, `t5-otel-live-run`) plus docs and they bump in **lockstep**.
  [Story: NFR-B9-1-003]

## Phase 5: Integration

- [x] **T5.1** Run `bash .forge/scripts/validate-foundations.sh` → confirm
  `FR-GL-001-versioned:mobile-pwa-first/2.0.0.yaml` **PASS** with
  `profile=client-only layers=['app', 'web-pwa']`. [Story: FR-B9-1-013]
- [x] **T5.2** Confirm `forge init <name> --archetype mobile-pwa-first --org <org>`
  refuses cleanly and renders nothing. **CORRECTED after the independent review (F1)**:
  the code is **exit 2** (dispatch gate, `init.ts:210-217`), NOT 3 — T.4 registered
  `mobile-pwa-first` only as the `target:` of the `mobile-only` alias, so no
  `mobile-pwa-first:` key exists and `selectScaffoldableVersion` is never reached.
  This task was originally ticked **without running its verifier**, which is precisely
  the fake-completion failure mode; T-L2-001 has now been executed
  (`FORGE_B9_1_LIVE=1`, 24/24 GREEN) and asserts exit 2 + an empty target dir.
  [Story: NFR-B9-1-002]
- [x] **T5.3** Run the sibling harnesses that own adjacent contracts:
  `b6-1`, `b7-1`, `b8-3` (`--level 1`) → **GREEN**, proving the T-008 triple
  assertions on their own schemas are unaffected. [Story: FR-B9-1-014]
- [x] **T5.4** Confirm `mobile-only` is untouched: `git diff --stat` shows no change
  under `.forge/schemas/mobile-only/`, `bin/forge-init-mobile-only.sh`,
  `.forge/templates/archetypes/mobile-only/`, nor `dispatch-table.yml`.
  [Story: FR-B9-1-040/041]

## Phase 6: Quality

- [x] **T6.1** Run `verify.sh` + `constitution-linter.sh` → **no new FAIL**
  (baseline before this change, measured by stashing it: **564** PASS / 0 FAIL / 1 WARN;
  after: 571 / 0 / 1. Linter OVERALL PASS both sides).
  [Story: NFR-B9-1-003]
- [x] **T6.2** `git diff --name-only` → only the new schema file, the new harness, the
  **one** committed validator file and the CI matrix line (plus the separate roadmap
  resync). Nothing else. [Story: NFR-B9-1-001]
- [x] **T6.3** Assert no resolved pin. A bare `\d+\.\d+` grep over the whole file is
  NOT the check (the file legitimately contains `2.0.0`, `1.0.0`, `3.1` in its own
  identity fields and prose): T-019 walks `components[]` values and asserts no
  forbidden key, no `\d+\.\d+` scalar, and that every `standard:` ref resolves.
  [Story: NFR-B9-1-005, Article III.4]
- [x] **T6.4** REFACTOR: tidy header comments / section anchors; re-run `b9-1.test.sh`
  + `validate-foundations.sh` + `b8-3b.test.sh` → still GREEN.
  [Gate: behavior unchanged]
- [x] **T6.5** **Independent review pass — DONE 2026-07-27, verdict CHANGES REQUIRED.**
  Ran in a separate reviewer lane (Article V). Engineering approved: the `layer_profile`
  design was judged the right call over stub layers, backward-compat confirmed
  independently, and the harness survived **21 mutation tests with zero vacuous passes**.
  Two BLOCKING findings, both in the *record* rather than the code:
  **F1** — `exit 3` was false (it is **2**), asserted as observed fact in 10 places
  including the shipped schema header, with T5.2 ticked without ever running its
  verifier. **F2** — the roadmap row landed stale, calling Q-001 unresolved.
  Five non-blocking findings (F3 b8-3b 13→12 L1; F4 residual "7 copies"; F5 three wrong
  numbers; F6 four overstated test descriptions; F7 an over-broad state-management
  clause). **All seven applied.** [Gate: Article V]
- [x] **T6.6** **Re-review of the applied fixes — DONE 2026-07-27, verdict CHANGES
  REQUIRED → resolved.** Independent lane (did not author the fixes). Confirmed 6/7
  findings fully fixed with no new technical errors introduced, and independently
  re-verified every `init.ts:210-217` reference, the T.4/`target:` explanation and the
  `b7-2a` citation as exact. Two residuals found:
  **R1 (blocking)** — `design.md:106-107`, ADR-B9-1-002 §Consequences still asserted
  `exits **3**` *and explicitly denied exit 2*. Missed because my sweep grepped
  `exit 3` and the text reads `exits **3**`. Worst possible site: the ADR is what
  B.9.2's author would consult for the refusal contract. **Fixed**, now naming the
  full call chain (`init.ts:219-240` → `resolveScaffolder` `init-archetype.ts:128` →
  `selectScaffoldableVersion` `schema-version.ts:68`).
  **R2 (nit)** — `b9-1.test.sh:32` header index still said "all 7 copies byte-identical",
  contradicting T-023's own body 418 lines below. Neither of us cited it originally;
  it was the most durable surviving instance since the harness ships. **Fixed.**
  Also added: a recorded-decision row for **FR-B9-1-032** (no dedicated test — negative-prose
  property; substantively covered by T-019 + the repo-wide NSMA linter), converting a
  silent traceability gap into an explicit one. Reviewer mutation-proved both new
  T-L2-001 assertions are load-bearing.
  **SIGN-OFF 2026-07-27: APPROVE-WITH-NITS — Article V satisfied, change is archivable.**
  One nit **N1** raised and fixed without a further round: `design.md:108` claimed the
  B.8.14 block was "the only exit-3 path" — false. There are three
  (`init.ts:206` invalid reverse domain, which fires *before* the dispatch gate;
  `init.ts:238` the B.8.14 guard; `init-archetype.ts:170` forbidden-archetype refusal),
  and `mobile-pwa-first` does exit 3 today with an invalid `--org`. Verified live and
  reworded to "the exit-3 path this ADR is about". [Gate: Article V]

## Constitution Gate (per task) — summary

- TDD order enforced: harness RED (T1.2) precedes validator GREEN (T2.3) which
  precedes schema GREEN (T3.6). ✓
- No spec bypass: every task cites its FR/NFR/ADR. ✓
- Article IV: the validator patch defaults to today's behaviour, so no existing schema
  changes meaning; everything else is a new file. ✓
- Article III.4: no pin resolved; the two-layer-check distinction and the `grep -qF`
  prefix-safety were verified live, not assumed. ✓
- Article V: T6.5 defers approval to an independent lane. ✓
- **No [TASK VIOLATION].**

## Follow-up left open (later B.9 bricks — NOT this change)

- `web-pwa/` Qwik tree + Service Worker + Web Push + manifest + offline shell → B.9.2.
- Shared OIDC templates (Flutter `AuthGateway` + TS Connect-ES client) → B.9.3.
- Decision-tree prose in `docs/ARCHETYPES.md` → B.9.4.
- Hera bloc/`bloc_test` generators from proto messages → B.9.5.
- **B.9.6 is a no-op** — NSMA linter already activated repo-wide by B.8.11.
- CI `pwa-deploy` job → B.9.7. Snapshot tarball → B.9.8.
- `bin/forge-migrate-mobile-pwa.sh` (purely additive per ADR-B9-1-004) → B.9.9.
- `docs/MIGRATION-PATHS.md` entry → B.9.10.
- **Dispatch-table registration** of a `mobile-pwa-first:` key → B.9.2 (mirrors
  `b7-2a-dispatch-register`). Until then `forge init` refuses at exit 2, not 3.
  Whichever brick adds it MUST flip **both** `b9-1.test.sh` T-022 (key absent) and
  T-L2-001 (expected exit code) in the same change — they are coupled.
- Promotion candidate→stable/scaffoldable + ≥25-test gate → B.9.11.
