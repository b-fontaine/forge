# Tasks: c1-reference-project

<!-- Audit: Module C.1. Each phase = one commit cluster per ADR-010.        -->
<!-- TDD ordering is per-FR : RED test before GREEN implementation.         -->
<!-- Parallel-eligible tasks marked [P]. External-tool tasks (flutter,      -->
<!-- cargo, buf) are flagged [REQUIRES-TOOLS].                              -->

Implementation is split into **3 commit clusters** matching ADR-010 :

| Phase | Cluster | Coverage |
|---|---|---|
| 1 | **scaffold** | Skip-guards + example tree + READMEs |
| 2 | **demos** | 4 demo changes + their application code |
| 3 | **CI + docs + baselines** | forge-ci.yml example job + measured baselines + spec consolidation |

Each phase ends with a RED→GREEN→REFACTOR closure on its own subset of
`c1.test.sh`. The harness grows phase-by-phase ; only at the end of
Phase 3 is the full manifest enforced.

---

## Phase 0: Bootstrap test harness

These tasks set up the `c1.test.sh` skeleton and its manifest pattern
before any phase-specific tests are added.

- [x] Create `.forge/scripts/tests/c1.test.sh` skeleton — sources
  `_helpers.sh`, declares the `# MANIFEST: ...` comment block (empty
  initially), implements `test_manifest_self_consistency` as the first
  test, exits 0 with empty manifest.
  [Story: FR-EX-009]
- [x] Make `c1.test.sh` executable (`chmod +x`).
  [Story: FR-EX-009]
- [x] Run `bash .forge/scripts/tests/c1.test.sh` once : confirm exits 0
  with "1/1 PASS" (just the meta-test). This is the GREEN baseline.
  [Story: FR-EX-009]

---

## Phase 1: Scaffold cluster

### Phase 1 — RED

Write failing tests for the skip-guard FRs, the .gitignore extension,
and the example-tree structural FRs **before** any implementation.

- [x] Add `test_verify_skips_examples_tree` to `c1.test.sh` MANIFEST :
  fixture creates a tmpdir mimicking the Forge framework repo signature
  (an `examples/forge-fsm-example/` subtree + a
  `.forge/specs/full-stack-monorepo.md` file), then runs `bash
  $REPO/.forge/scripts/verify.sh` with `FORGE_ROOT=$tmpdir`. Assert :
  output contains `[skipped: examples]` lines AND no walk into
  `examples/` content. [Story: FR-GL-026] [P]
- [x] Add `test_verify_runs_inside_example_tree` : fixture is a plain
  `full-stack-monorepo` tree (no `examples/` subdir). Assert : no
  `[skipped: examples]` line emitted. [Story: FR-GL-026] [P]
- [x] Add `test_verify_no_skip_when_no_examples_dir` : fixture is the
  Forge repo signature WITHOUT an `examples/` subdir. Assert :
  byte-identical stdout to a baseline reference (NFR-EX-006 regression
  fixture). [Story: NFR-EX-006] [P]
- [x] Add `test_constitution_linter_skips_examples_tree` : same shape
  as `test_verify_skips_examples_tree` but for
  `constitution-linter.sh`. [Story: FR-GL-027] [P]
- [x] Add `test_gitignore_covers_example_artefacts` : grep the Forge
  repo's root `.gitignore` for `examples/*/build/`,
  `examples/*/target/`, `examples/*/.dart_tool/`, etc. (per ADR-003
  list). [Story: FR-GL-028] [P]
- [x] Add `test_example_tree_canonical_structure` : assert
  `examples/forge-fsm-example/` exists with frontend/, backend/,
  infra/, shared/protos/, .forge/, .claude/, .mcp.json, .github/
  workflows, Taskfile.yml, docker-compose.dev.yml, .env.example,
  .gitignore, CLAUDE.md, .forge.yaml. [Story: FR-EX-001]
- [x] Add `test_example_scaffold_manifest_complete` : parse
  `examples/forge-fsm-example/.forge/scaffold-manifest.yaml` ; assert
  required keys present (archetype, archetype_version,
  scaffold_plan_sha, template_set_sha, scaffold_date, project_name,
  reverse_domain, root_module, flutter_version, cargo_version,
  buf_version) AND `archetype_version == "1.0.0"`. [Story: FR-EX-001]
- [x] Add `test_example_readme_has_required_sections` : check
  `examples/forge-fsm-example/README.md` contains the 4 H2 sections
  (How this example was built, What's in here, Demo changes,
  Reproducing this example). [Story: FR-EX-002]
- [x] Add `test_examples_meta_readme_present` : check `examples/README.md`
  exists, lists `forge-fsm-example` as one entry, mentions skip-guards.
  [Story: FR-EX-003]
- [x] Run `c1.test.sh` once → confirm all 9 new tests FAIL (RED).
  [Story: TDD discipline per Article I]

### Phase 1 — GREEN

Implement the skip-guards, run the scaffolder, write the READMEs.

- [x] Implement skip-guard detection block at the top of
  `.forge/scripts/verify.sh` (signature check : both
  `.forge/specs/full-stack-monorepo.md` AND `examples/` exist →
  `FORGE_REPO_DETECTED=1`). [Story: FR-GL-026]
- [x] Add the per-section guard in `verify.sh`'s "Change Artifact
  Completeness" loop : prefix-check `$change_dir` vs `$FORGE_ROOT/examples/`
  → `[skipped: examples] $change_dir` and `continue`. [Story: FR-GL-026]
- [x] Add the same prefix-check guard in any layer-scoped section that
  walks the file tree (backend/frontend/infra resolvers in `verify.sh`).
  [Story: FR-GL-026]
- [x] Implement skip-guard detection block at the top of
  `.forge/scripts/constitution-linter.sh` (mirror of verify.sh).
  [Story: FR-GL-027]
- [x] Add per-loop prefix-check guards in each section of
  `constitution-linter.sh` that walks the tree. [Story: FR-GL-027]
- [x] Append to root `.gitignore` :
  `examples/*/build/`, `examples/*/target/`, `examples/*/cli/`,
  `examples/*/node_modules/`, `examples/*/.dart_tool/`,
  `examples/*/.cargo/`, `examples/*/coverage/`. Group under a comment
  `# c1-reference-project — example tree build artefacts`.
  [Story: FR-GL-028]
- [x] Run the scaffolder against a tmpdir to produce the example tree :
  `forge init --archetype full-stack-monorepo forge-fsm-example
  --org io.forge.example`. Use the Forge CLI's actual binary as built
  by `cli/`. [REQUIRES-TOOLS: flutter, cargo, buf, node]
  [Story: FR-EX-001]
- [x] Copy the scaffolded tree to
  `examples/forge-fsm-example/` in the Forge repo. Verify
  `.forge/scaffold-manifest.yaml` is present and correct.
  [Story: FR-EX-001]
- [x] Drop into `examples/forge-fsm-example/` and run
  `bash .forge/scripts/verify.sh` once to confirm the example's own
  gates pass (FR-EX-007 sanity check, full check happens in Phase 3).
  [REQUIRES-TOOLS: python3, yaml]
- [x] Write `examples/forge-fsm-example/README.md` with the 4 H2
  sections (How this example was built, What's in here, Demo changes,
  Reproducing this example). The "Demo changes" section is empty for
  Phase 1 ; it will be populated by Phase 2. [Story: FR-EX-002]
- [x] Write `examples/README.md` (meta-doc) listing
  `forge-fsm-example` and explaining `examples/` purpose +
  skip-guards reference. [Story: FR-EX-003]
- [x] Run `c1.test.sh` → confirm all 9 Phase 1 tests now PASS (GREEN).
  [Story: TDD]

### Phase 1 — REFACTOR

- [x] Run `bash .forge/scripts/verify.sh` from the Forge repo root :
  confirm new `[skipped: examples]` lines emitted AND existing
  PASS/FAIL counts unchanged for non-example sections (NFR-EX-006).
  [Story: NFR-EX-006]
- [x] Run all existing harnesses (`foundations.test.sh`,
  `scaffolder.test.sh --level 1,2`, `workflow.test.sh --level 1,2`,
  `delivery.test.sh`, `g1.test.sh`) : confirm zero regression.
  [Story: backwards compatibility]
- [x] Commit Phase 1 cluster : `feat(forge): c1-reference-project Phase 1
  — scaffold + skip-guards + readmes`.

---

## Phase 2: Demos cluster

### Phase 2 — RED

- [x] Add `test_archived_demos_count_and_status` : list
  `examples/forge-fsm-example/.forge/changes/demo-*/` ; assert exactly
  4 demos exist ; assert demo-001/002/003 declare
  `status: archived` ; demo-004 declares `status: specified`.
  [Story: FR-EX-004 + FR-EX-005] [P]
- [x] Add `test_each_archived_demo_has_five_artefacts` : for each of
  demo-001/002/003, assert presence of proposal.md, specs.md,
  design.md or designs_per_layer files, tasks.md or tasks_per_layer
  files, features/<demo>.feature with at least one Gherkin scenario.
  [Story: FR-EX-004] [P]
- [x] Add `test_demo_003_is_multi_layer` : parse `demo-003-rate-limit/.forge.yaml` ;
  assert `layers: [backend, infra]` (length ≥ 2), assert
  `designs_per_layer:` and `tasks_per_layer:` present and non-empty,
  every referenced filename exists. [Story: FR-EX-004 + FR-GL-016] [P]
- [x] Add `test_demo_004_is_specified_only` : parse
  `demo-004-user-onboarding/.forge.yaml` ; assert `status: specified`,
  `timeline.specified` populated, `timeline.designed/planned/implemented/archived`
  absent or commented out ; demo-004 dir contains proposal.md +
  specs.md only (no design.md, no tasks.md, no features/).
  [Story: FR-EX-005] [P]
- [x] Add `test_demo_004_has_needs_clarification_marker` : grep
  `demo-004-user-onboarding/specs.md` for `[NEEDS CLARIFICATION:` ;
  assert at least one occurrence. [Story: FR-EX-005] [P]
- [x] Add `test_demos_manifest_present_and_lists_four_demos` :
  parse `examples/forge-fsm-example/.forge/changes/MANIFEST.md` ;
  assert table with 4 rows referencing each demo by name. [Story: FR-EX-006] [P]
- [x] Add `test_each_demo_proposal_under_size_budget` : for each demo,
  assert `proposal.md` ≤ 200 lines. [Story: NFR-EX-004] [P]
- [x] Add `test_demos_cover_distinct_layer_combinations` : parse each
  demo's `.forge.yaml` `layers:` field ; assert the 4 combinations
  are distinct (backend / frontend / [backend, infra] / [backend,
  frontend, protos]). [Story: NFR-EX-005] [P]
- [x] Run `c1.test.sh` → confirm 8 new tests FAIL (no demos yet — RED).

### Phase 2 — GREEN (chronological order per ADR-013)

#### Demo-001-greeting-service (single-layer backend)

- [x] Inside the example tree, run `forge new demo-001-greeting-service`
  to bootstrap the change skeleton. Edit `.forge.yaml` to declare
  `layers: [backend]`. [Story: FR-EX-004]
- [x] Write `proposal.md` (≤ 200 lines per NFR-EX-004) describing
  a minimal gRPC `Greeter` service. Run `forge specify`. [Story: FR-EX-004]
- [x] Write `specs.md` with FR-BE-001 (Greeter domain entity) and
  FR-IN-001 (proto contract `shared/protos/v1/greeting/greeting.proto`).
  [Story: FR-EX-004]
- [x] Write `design.md` with one ADR (use cucumber-rs, hexagonal
  layering, in-process tonic test server). Run `forge design`.
  [Story: FR-EX-004]
- [x] Write `tasks.md` (TDD-ordered : RED test for Greeter domain →
  GREEN domain → RED grpc-api integration test → GREEN handler).
  Run `forge plan`. [Story: FR-EX-004]
- [x] Add `shared/protos/v1/greeting/greeting.proto` declaring
  `service GreeterService { rpc Greet(GreetRequest) returns (GreetResponse); }`.
  Run `task proto` to regenerate stubs. [REQUIRES-TOOLS: buf]
  [Story: FR-EX-004]
- [x] Implement TDD : RED unit test in `backend/crates/domain/`
  for `Greeter::greet(name)` → empty `Greeting`. Confirm it
  fails to compile (no Greeter type yet). [Story: Article I]
  [REQUIRES-TOOLS: cargo]
- [x] Implement `Greeter` domain entity (pure, no deps) → confirm
  unit test passes. [REQUIRES-TOOLS: cargo] [Story: Article I, VII]
- [x] RED integration test in `backend/crates/grpc-api/` for the
  `GreeterService` tonic handler. Confirm it fails. [REQUIRES-TOOLS: cargo]
- [x] Implement the tonic handler delegating to `application::greet_use_case`
  → integration test passes. [REQUIRES-TOOLS: cargo]
- [x] Write `features/greeter.feature` with a Greet happy-path scenario
  (`Given the Greeter is running, When I call Greet with "world", Then
  I receive "Hello, world"`). Implement via cucumber-rs steps in
  `backend/tests/`. [REQUIRES-TOOLS: cargo]
- [x] Run `task test` from inside the example → all backend tests
  PASS. [REQUIRES-TOOLS: cargo, flutter (skipped)]
- [x] Run `forge implement` to mark all tasks `[x]`, then `forge archive`
  to set `status: archived`, populate `timeline.archived`. [Story: FR-EX-004]

#### Demo-002-greeting-screen (single-layer frontend)

- [x] Bootstrap via `forge new demo-002-greeting-screen`. Set
  `layers: [frontend]`. [Story: FR-EX-004]
- [x] Write `proposal.md` (≤ 200 lines) for a Flutter screen consuming
  the `Greet` RPC. [Story: FR-EX-004]
- [x] Write `specs.md` with FR-FE-001 (GreetingScreen widget),
  FR-FE-002 (GreetingCubit), FR-FE-003 (a11y semantic labels).
  [Story: FR-EX-004]
- [x] Write `design.md` with ADR-001 (Cubit not Bloc — simple state),
  ADR-002 (golden test against MaterialApp dark + light themes).
  [Story: FR-EX-004]
- [x] Write `tasks.md` TDD-ordered. [Story: FR-EX-004]
- [x] Run `task proto` again to ensure Flutter generated stubs are
  fresh (consume demo-001's proto). [REQUIRES-TOOLS: buf, dart]
- [x] RED widget test in `frontend/test/features/greeting/`. Confirm
  it fails. [REQUIRES-TOOLS: flutter]
- [x] Implement `GreetingCubit` + `GreetingScreen` widget. Confirm
  widget test passes. [REQUIRES-TOOLS: flutter]
- [x] Add golden test against MaterialApp in light + dark themes.
  Generate goldens. Commit golden files. [REQUIRES-TOOLS: flutter]
- [x] Write `features/greeting_screen.feature` for bdd_widget_test.
  [REQUIRES-TOOLS: flutter]
- [x] Run `flutter test` from inside the example → all PASS.
  [REQUIRES-TOOLS: flutter]
- [x] `forge implement` + `forge archive`. [Story: FR-EX-004]

#### Demo-003-rate-limit (multi-layer backend + infra)

- [x] Bootstrap via `forge new demo-003-rate-limit`. Set
  `layers: [backend, infra]`. Declare `designs_per_layer:` and
  `tasks_per_layer:` per FR-GL-016. [Story: FR-EX-004]
- [x] Write `proposal.md` (≤ 200 lines) describing rate-limiting via
  Kong plugin on the Greeter service. [Story: FR-EX-004]
- [x] Write `specs.md` using per-layer delta semantics : `FR-IN-001`
  (Kong plugin config), `FR-BE-001` (handler is rate-limit-aware).
  [Story: FR-EX-004]
- [x] Write `designs/design-backend.md` and
  `designs/design-infra.md`. Each has a header `<!-- Layer: <id> -->`.
  Run `forge design` (Janus-orchestrated since 2 layers).
  [Story: FR-EX-004 + FR-GL-015]
- [x] Write `tasks/tasks-backend.md` and `tasks/tasks-infra.md`.
  [Story: FR-EX-004]
- [x] Add `infra/kong/kong.yml` declaration : a `rate-limiting`
  plugin on the `/greeter.GreeterService/Greet` route, 10 RPS per
  consumer. [Story: FR-EX-004]
- [x] Update `examples/forge-fsm-example/docker-compose.dev.yml`
  if Kong needs to be added (it should already be there from
  `b1-foundations`). [Story: FR-EX-004]
- [x] No backend code change — the demo's interest is the
  multi-layer per-layer delta + Janus orchestration.
- [x] `forge implement` + `forge archive`. [Story: FR-EX-004]

#### Demo-004-user-onboarding (specified only)

- [x] Bootstrap via `forge new demo-004-user-onboarding`. Set
  `layers: [backend, frontend, protos]`. [Story: FR-EX-005]
- [x] Write `proposal.md` (≤ 200 lines) for user onboarding flow.
  [Story: FR-EX-005]
- [x] Write `specs.md` with FR-BE-/FR-FE-/FR-IN- requirements
  AND at least one realistic `[NEEDS CLARIFICATION: <question>]`
  marker. Common clarification : "Should the email verification be
  synchronous (block onboarding) or asynchronous (allow access,
  verify later)?". [Story: FR-EX-005]
- [x] Run `forge specify`. STOP — do NOT run `forge design`. The demo
  stays at `status: specified`. [Story: FR-EX-005]
- [x] Confirm `.forge.yaml` declares `status: specified`,
  `timeline.specified` populated, later timeline fields commented out.
  [Story: FR-EX-005]

#### Manifest + Phase 2 GREEN closure

- [x] Write `examples/forge-fsm-example/.forge/changes/MANIFEST.md` :
  table with 4 rows (one per demo) — id, status, one-sentence summary.
  [Story: FR-EX-006]
- [x] Update `examples/forge-fsm-example/README.md` § Demo changes :
  populate the bullet list with the 4 demos and one-line summaries.
  [Story: FR-EX-002]
- [x] Run `c1.test.sh` → confirm Phase 2 tests now PASS (GREEN).
  [Story: TDD]

### Phase 2 — REFACTOR

- [x] Run all existing harnesses : confirm zero regression.
- [x] Run `bash .forge/scripts/verify.sh` (Forge root) and confirm
  the new `[skipped: examples]` lines cover demo-* paths inside
  the example tree.
- [x] Commit Phase 2 cluster : `feat(examples): c1-reference-project
  Phase 2 — 4 demo changes (3 archived + 1 specified)`.

---

## Phase 3: CI + docs + baselines cluster

### Phase 3 — RED

- [x] Add `test_forge_ci_workflow_shape_six_jobs` to `c1.test.sh` :
  parse `.github/workflows/forge-ci.yml` ; assert exactly 6 top-level
  jobs (harness, gates, cli, lint, example, summary). [Story: MODIFIED FR-CI-001] [P]
- [x] Add `test_forge_ci_example_job_present` : assert
  `jobs.example` exists, `runs-on: ubuntu-latest`,
  `permissions: contents: read`. [Story: FR-CI-012] [P]
- [x] Add `test_forge_ci_example_job_paths_filter` : assert the
  `dorny/paths-filter@v3` step has `examples/**` filter. [Story: FR-CI-012] [P]
- [x] Add `test_forge_ci_example_job_steps` : assert the conditional
  step block runs `cd examples/forge-fsm-example && bash .forge/scripts/verify.sh`,
  `bash .forge/scripts/constitution-linter.sh`, and a Python
  yaml.safe_load over `.github/workflows/*.yml.tmpl`. [Story: FR-CI-012] [P]
- [x] Add `test_forge_ci_summary_aggregates_five_needs` : parse
  `jobs.summary.needs:` ; assert exactly the list `[harness, gates,
  cli, lint, example]`. [Story: MODIFIED FR-CI-006] [P]
- [x] Add `test_forge_ci_summary_treats_example_skip_as_success` :
  inspect summary's bash step ; assert the example branch checks
  `'success'` OR `'skipped'`. [Story: MODIFIED FR-CI-006] [P]
- [x] Add `test_forge_ci_under_size_budget` : assert `forge-ci.yml`
  ≤ 250 lines. [Story: NFR-CI-002 + FR-CI-013] [P]
- [x] Add `test_nfr_baselines_recorded` : grep the 4 NFR target
  standards (ci-workflows.md, observability-local.md, k8s-overlays.md)
  for `Baseline at archive time of c1-reference-project:` lines.
  [Story: FR-EX-008] [P]
- [x] Add `test_nfr_013_baseline_recorded` : in
  `.forge/specs/full-stack-monorepo.md` NFR-013 section, grep for
  `Baseline at archive time of c1-reference-project:`. [Story: FR-EX-008] [P]
- [x] Add `test_nfr_014_baseline_recorded` : same pattern for NFR-014.
  [Story: FR-EX-008] [P]
- [x] Add `test_nfr_015_baseline_recorded` : same pattern for NFR-015.
  [Story: FR-EX-008] [P]
- [x] Add `test_nfr_017_baseline_recorded` : same pattern for NFR-017.
  [Story: FR-EX-008] [P]
- [x] Add `test_example_reference_spec_present_post_archive` : gated
  on the c1's own `.forge.yaml` being `status: archived`. Skip
  otherwise. When triggered, assert `.forge/specs/example-reference.md`
  exists with the canonical sections. [Story: FR-EX-010]
- [x] Add `test_example_tree_byte_budget` : sum of bytes under
  `examples/forge-fsm-example/` (excluding ignored paths from
  FR-GL-028) ≤ 5 MB. [Story: NFR-EX-002]
- [x] Add L2 (opt-in) tests : `test_example_tree_verify_exits_zero`,
  `test_example_tree_constitution_linter_exits_zero`,
  `test_example_workflows_parse`. Gated behind
  `--require-example-tools` flag. [Story: FR-EX-007]
- [x] Add L3 (opt-in) test : `test_example_reproducible_from_scaffolder`
  — re-run the scaffolder against a tmpdir with pinned
  `SOURCE_DATE_EPOCH`, diff against the committed example for
  overlay-owned files only. Gated behind `--require-external-tools`.
  [Story: NFR-EX-001]
- [x] Run `c1.test.sh` → confirm Phase 3 RED tests FAIL.

### Phase 3 — GREEN

- [x] Edit `.github/workflows/forge-ci.yml` : add the new `example`
  job after the `lint` job. [Story: FR-CI-012]
- [x] In the new `example` job : declare `runs-on: ubuntu-latest`,
  `permissions: contents: read`, `dorny/paths-filter@v3` step with
  `examples/**` filter (id: `examples-filter`).
  [Story: FR-CI-012]
- [x] Add the conditional step block (`if: steps.examples-filter.outputs.changed
  == 'true'`) running, in order : (1) `cd examples/forge-fsm-example`,
  (2) `bash .forge/scripts/verify.sh`, (3)
  `bash .forge/scripts/constitution-linter.sh`, (4) Python yaml.safe_load
  over `*.yml.tmpl`. [Story: FR-CI-012]
- [x] Update `jobs.summary.needs:` from
  `[harness, gates, cli, lint]` to `[harness, gates, cli, lint, example]`.
  [Story: MODIFIED FR-CI-006]
- [x] Update `jobs.summary` bash step : extend the env: indirection
  block with `EXAMPLE_RESULT: ${{ needs.example.result }}` and the
  pass/fail logic to treat `EXAMPLE_RESULT == 'success'` OR
  `EXAMPLE_RESULT == 'skipped'` as success.
  [Story: MODIFIED FR-CI-006]
- [x] Update the summary's success message from `4/4 jobs PASS` to
  `5/5 jobs PASS` (count includes example, regardless of skip vs
  success). Update the failure message format. [Story: MODIFIED FR-CI-006]
- [x] Verify `forge-ci.yml` ≤ 250 lines (NFR-CI-002 + FR-CI-013).
  [Story: NFR-CI-002]
- [x] Measure NFR-013 baseline : pull the most recent successful
  `forge-backend.yml` / `forge-frontend.yml` / `forge-infra.yml`
  warm-cache run for the example (or simulate locally with
  `act` if available, else use the documented thresholds as a
  placeholder until first PR). Record baseline in
  `standards/infra/ci-workflows.md` § Performance Baselines (new H2).
  [Story: FR-EX-008 + ADR-007]
- [x] Measure NFR-014 baseline (integration workflow runtime) and
  record alongside NFR-013 in
  `standards/infra/ci-workflows.md` § Performance Baselines.
  [Story: FR-EX-008]
- [x] Measure NFR-015 baseline : run
  `docker compose -f examples/forge-fsm-example/docker-compose.dev.yml
  up -d --wait` and record the wall-clock time in
  `standards/infra/observability-local.md` § Startup Baselines (new H2).
  [REQUIRES-TOOLS: docker] [Story: FR-EX-008]
- [x] Measure NFR-017 baseline : run `kustomize build` against
  examples's `infra/k8s/overlays/{dev,prod}` and diff. Record byte
  count in `standards/infra/k8s-overlays.md` § Diff Budget (new H2).
  [REQUIRES-TOOLS: kustomize] [Story: FR-EX-008]
- [x] Append "Baseline at archive time of c1-reference-project:
  see standards/infra/<file>.md § <section>" lines to the 4 affected
  NFRs in `.forge/specs/full-stack-monorepo.md`.
  [Story: FR-EX-008 + MODIFIED NFR-013/014/015/017]
- [x] Run `c1.test.sh` → confirm Phase 3 tests now PASS (excluding
  `test_example_reference_spec_present_post_archive` which is
  archive-gated). [Story: TDD]

### Phase 3 — REFACTOR

- [x] Run all 6 harnesses + verify.sh + constitution-linter.sh on
  the Forge repo : confirm zero regression and the example skip-
  guards behave as expected.
- [x] Run `c1.test.sh --require-example-tools` (L2) : confirm L2
  tests PASS on the example tree (which is now fully populated).
  [Story: FR-EX-007]
- [x] *(opt-in, pre-release)* Run `c1.test.sh
  --require-external-tools` (L3) : confirm reproducibility check
  passes. [Story: NFR-EX-001]
- [x] Commit Phase 3 cluster : `feat(forge): c1-reference-project
  Phase 3 — example CI job + measured baselines + spec consolidation`.

---

## Phase 4: Quality

These tasks happen post-implementation, before archive.

- [x] Verify Article VI compliance for demo-002 : run
  `flutter analyze --fatal-infos` from inside the example. Zero
  warnings expected. [REQUIRES-TOOLS: flutter] [Story: Article VI]
- [x] Verify Article VII compliance for demo-001 : run
  `cargo clippy --workspace --all-targets -- -D warnings` from
  inside the example. Zero warnings expected. [REQUIRES-TOOLS: cargo]
  [Story: Article VII]
- [x] Verify the example's coverage (Article X.1 ≥ 80%) : run
  `cargo tarpaulin` for backend, `flutter test --coverage` for
  frontend. [REQUIRES-TOOLS: cargo, flutter] [Story: Article X.1]
- [x] *(post-merge)* On first push to main with the new `example` job,
  observe the GitHub Actions run and capture the actual NFR-013 +
  NFR-014 measured values. Update the standards baselines if the
  recorded placeholders differed by ≥ 10%. [Story: FR-EX-008]

---

## Phase 5: Documentation (handled by /forge:archive)

- [x] /forge:archive will merge the delta from `specs.md` into
  `.forge/specs/full-stack-monorepo.md` (FR-GL-026..028 added to
  the existing spec ; the 4 NFRs gain Baseline lines).
- [x] /forge:archive will merge into `.forge/specs/forge-ci.md`
  (MODIFIED FR-CI-001 + FR-CI-006 + new FR-CI-012/013).
- [x] /forge:archive will create `.forge/specs/example-reference.md`
  consolidating the FR-EX-* namespace (FR-EX-010).
- [x] /forge:archive will update `CHANGELOG.md` with the
  `c1-reference-project` entry under [Unreleased].
- [x] /forge:archive will update `.forge/product/roadmap.md` :
  mark C.1 done.

---

## Phase 6: Constitutional gate (handled by /forge:archive)

- [x] /forge:archive will run all 6 harnesses + verify.sh +
  constitution-linter.sh + L2 of c1.test.sh : confirm green.
- [x] /forge:archive will set `.forge.yaml` to `status: archived`
  with `timeline.archived` populated.
- [x] /forge:archive will run a final repository-wide check : every
  `[ ]` task in this file is now `[x]`.
