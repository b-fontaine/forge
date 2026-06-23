# Specs: b7-6-harness

<!-- Specified: 2026-06-23 -->
<!-- Namespace: FR-B7-6-* / NFR-B7-6-* / ADR-B7-6-* -->
<!-- Source: proposal.md + bin/forge-init-ai-native-rag.sh (the gated body + b7-6 TODOs) -->
<!--         + .forge/schemas/ai-native-rag/1.0.0.yaml (the schema flipped) -->
<!--         + validate-foundations.sh::check_versioned_schema_siblings (the invariant) -->
<!--         + .forge/changes/b8-14-promotion-{prep,flip}/** (the promotion precedent) -->
<!--         + b7-{1,2,2a,3,5,9,10,pythia}.test.sh (the aggregated sibling harnesses) -->

**Constitution** : v2.0.0 (no bump — this brick amends NO constitution article,
NO standard, NO other archetype; contrast B.8.14 which amended §VIII.1).

**Format** : mostly ADDED (a new promotion suite + the live-codegen wiring), with
TWO **MODIFIED** items that are the promotion itself — the schema's
`stage`/`scaffoldable` fields and the sibling harness assertions that encode the
candidate precondition. On archive these requirements consolidate into
`.forge/specs/ai-native-rag.md` (B.7 spec-accumulation convention; b7-10
`.forge.yaml:3-4` precedent).

**Ground truth (re-read 2026-06-23, Article III.4)** — see `proposal.md` Problem
+ `open-questions.md`. Load-bearing facts each spec depends on, cited:
- Schema candidate: `ai-native-rag/1.0.0.yaml:33-34` (`stage: candidate` /
  `scaffoldable: false`).
- Validator invariant ONE-directional: `validate-foundations.sh:453`
  (`candidate ⇒ scaffoldable: false`); `:448-451` (`stable ⇒ version ≥ 1.0.0,
  no prerelease`); NO `stable ⇒ scaffoldable:true` clause.
- Wrapper auto-opens on flip: `forge-init-ai-native-rag.sh:81-102` (`is_scaffoldable`
  needs stage==stable AND scaffoldable==true).
- Deferred TODOs: `forge-init-ai-native-rag.sh:170-180` (`buf generate`,
  `cargo fetch`); Connect handler registration `bin-server/src/main.rs.tmpl:11-13,38-39`.
- buf = remote BSR plugins: `buf.gen.yaml.tmpl:20-41`; CI has no buf/cargo:
  `forge-ci.yml` (six jobs `harness`/`gates`/`cli`/`lint`/`example`/`summary`,
  lines 33,150,170,193,214,261 — none installs buf/cargo); bundle gitignored +
  CI-fresh: `cli/.gitignore:3`,
  `cli/package.json:28`, `forge-ci.yml:52-56`.

---

## Resolved scope decisions (from proposal open questions)

- **Q-A (single change vs split)** → ADR-B7-6-001 proposes **single change** (no
  amendment window forces a split); `[NEEDS CLARIFICATION]` for maintainer confirm.
- **Q-B (buf/CI justification of the flip)** → ADR-B7-6-005 proposes the live L2
  legs SKIP in the buf-less CI and the flip is justified by a recorded green
  local/manual run where buf+BSR+cargo+node are present (option a), with adding a
  CI buf+cargo job as option b; `[NEEDS CLARIFICATION]` — the genuine decision.
- **Q-C (suite composition)** → ADR-B7-6-002 (aggregate siblings + add e2e).
- **Q-D (snapshot tarball)** → ADR-B7-6-004 proposes a deterministic snapshot;
  `[NEEDS CLARIFICATION]` for necessity.
- **Q-E (bundle regen)** → ADR-B7-6-003 (`npm run bundle`, gitignored, CI-fresh).

---

## ADDED Requirements

### Promotion test suite (`FR-B7-6-0xx`)

- **FR-B7-6-001** — A dedicated harness `.forge/scripts/tests/b7-6.test.sh` MUST
  be added with **≥35 tests** (`run_test` invocations) covering the archetype
  end-to-end, arg-parsed `--level` + `_helpers.sh` source + `run_test`/
  `print_summary` (mirroring `b7-2.test.sh`/`b7-10.test.sh`). It MUST be
  registered in `.github/workflows/forge-ci.yml`'s hardcoded harness array
  (`forge-ci.yml:69-134`) at the level whose legs are CI-runnable (see
  ADR-B7-6-005 / Q-B).
- **FR-B7-6-002** — **L1 end-to-end structural tier (hermetic, CI-safe).** The
  suite MUST assert, by grep/structure over the committed template tree (no
  toolchain): the layer-root triple (backend/frontend/infra/shared) present
  (b7-2 T-001); the proto contract carries BOTH the unary `Query` and the
  streaming `QueryStream`/`QueryChunk` (b7-2 + b7-10 surfaces coexist); the
  codegen manifest (`buf.gen.yaml.tmpl`) declares the Rust (tonic+prost) and TS
  (bufbuild/es) outputs to the real target dirs; the Connect-handler registration
  seam exists in `bin-server/src/main.rs.tmpl`; the scaffold-plan references only
  existing tree files with no orphan/dangling (b7-2 T-002); the standards-
  conformance markers (RRF/rerank/HNSW, prompt-audit/redact_pii/non-AI-fallback,
  tool_router/schemars/StreamableHttp) are present (b7-2 T-007); pins live only in
  `Cargo.toml.tmpl` (b7-2 T-004); the gated wrapper + dispatch entry exist.
- **FR-B7-6-003** — **Aggregation tier.** The suite MUST re-run each sibling
  per-brick harness — `b7-1`, `b7-2`, `b7-2a`, `b7-3`, `b7-5`, `b7-9`, `b7-10`,
  `b7-pythia` (the archived/landed B.7 bricks at plan time) — at its CI level and
  assert each exits 0, so the promotion suite is a genuine superset gate. A
  sibling harness absent from the tree at run time MUST be a clean SKIP (so the
  suite stays runnable if a sibling is renamed/retired), not a hard FAIL.
- **FR-B7-6-004** — **L2 live-codegen tier (toolchain-gated, SKIP-when-absent).**
  When `buf`, BSR network, `cargo`, and `tsc`/`node_modules` are present, the
  suite MUST: render the plan via `overlay.sh` (the b7-2/b7-10 absolutize-temp-plan
  convention); run `buf generate` (or `task proto`) and assert the Rust
  `grpc-api` stubs + the TS `generated/connect/rag_pb` descriptor are
  materialised; run `cargo build`/`cargo test` on the rendered workspace
  **including** the generated stubs + the Connect handler registration (proving
  the deferred wiring compiles); run Qwik `tsc --noEmit`/build clean (the
  previously-un-generated `rag_pb` import now resolves). Each leg MUST SKIP
  gracefully (echo `SKIP …`, return 0) when its toolchain or BSR network is
  absent — the b7-10 `T-L2-003`/`T-L2-004` precedent (`b7-10.test.sh:311,332`).
- **FR-B7-6-005** — **Live codegen wiring (the b7-2 deferral).** The deferred
  `forge-init-ai-native-rag.sh:170-180` TODOs (`buf generate`, `cargo fetch`) and
  the Connect handler registration seam (`bin-server/src/main.rs.tmpl:38-39`)
  MUST be realised as a verified path: either implemented as post-render wrapper
  steps OR confirmed-and-documented as `task proto` first-build steps (per Q-B/
  design), AND asserted green by FR-B7-6-004's L2 legs. The Connect
  `rag.v1.RagService` handler MUST be registered against the generated `grpc-api`
  stubs and compile.

### Snapshot tarball (`FR-B7-6-01x`)

- **FR-B7-6-010** — A deterministic snapshot tarball of the rendered
  ai-native-rag tree SHOULD be generated (pending Q-D), byte-identical across runs
  via `SOURCE_DATE_EPOCH` (the `forge-sbom.sh`/compliance-bundle determinism
  precedent), mirroring the flagship snapshot convention used by `forge upgrade`
  BASE recovery (roadmap line 100). If shipped, its L2 generation+determinism MUST
  be asserted; if Q-D resolves "not now", the requirement is dropped and recorded.

## MODIFIED Requirements (the promotion — the FINAL, suite-gated edits)

- **FR-B7-6-020 (MODIFIED schema)** — `.forge/schemas/ai-native-rag/1.0.0.yaml`
  MUST change `stage: candidate → stable` and `scaffoldable: false → true`, and
  the candidate-semantics header block (`1.0.0.yaml:10-18`) MUST be reworded to
  describe the promoted state. This is the SOLE source-of-truth promotion edit. It
  MUST satisfy `validate-foundations.sh::check_versioned_schema_siblings`
  (the candidate clause no longer applies; version 1.0.0 clears the stable floor).
  This edit MUST be the LAST substantive task, performed only after FR-B7-6-001..005
  are green (ADR-B7-6-006).
- **FR-B7-6-021 (MODIFIED sibling guards, lockstep)** — In the SAME commit as
  FR-B7-6-020, the candidate-precondition assertions in the sibling harnesses MUST
  be inverted (the b8-14-flip break-cascade pattern):
  - `b7-1.test.sh` T-005 (`stage == 'candidate'`, line 223) → `stable`;
    T-006 (`scaffoldable == False`, line 229) → `True`; the L2 exit-3 refusal
    (line 351) → success/scaffold.
  - `b7-2.test.sh` T-006 (wrapper refuses while candidate, lines 114-130) → the
    NOTE branch already self-inverts when the schema is no longer candidate
    (line 118); the assertion MUST be updated to positively require the promoted
    state.
  - `b7-2a.test.sh` L2 (`forge init … exit 3`, lines 91-106) → no longer exit 3
    (renders / succeeds).
- **FR-B7-6-022 (bundle regen)** — `cli/assets/` MUST be regenerated via
  `npm run bundle` (`cli/package.json:28`) so the CLI's `selectScaffoldableVersion`
  returns the now-scaffoldable 1.0.0 and `forge init --archetype ai-native-rag`
  STOPS refusing. `cli/assets/` is a gitignored build artifact (`cli/.gitignore:3`)
  rebuilt fresh by CI (`forge-ci.yml:52-56`); the committed change is the schema
  flip (FR-B7-6-020), not the bundle bytes (b8-14-flip FR-FLIP-025 precedent).

### forge-ci line-budget lock-step (`FR-B7-6-03x`)

- **FR-B7-6-030 (MODIFIED, lock-step)** — Registering `b7-6.test.sh` in the
  `forge-ci.yml` harness array (FR-B7-6-001) — and, if Q-B resolves option b, also
  adding a `harness-rust` buf+cargo+node job — GROWS the workflow past its current
  size budget. `forge-ci.yml` is **300 lines today** (live-counted 2026-06-23) and
  the budget is asserted in **four** places that MUST move in lock-step (a lesson:
  b7-7 bumped one and missed a sibling assertion):
  1. `.forge/scripts/tests/g1.test.sh::test_forge_ci_under_size_budget`
     (line 343: `[ "$lines" -gt 300 ]`).
  2. `.forge/scripts/tests/c1.test.sh::test_forge_ci_under_size_budget`
     (line 738: `[ "$lines" -gt 300 ]`).
  3. `.forge/specs/forge-ci.md` FR-CI-013 (line 298: "≤ 300 lines").
  4. `.forge/standards/global/forge-self-ci.md` (line 43: "≤ 300 lines").
  b7-6 MUST bump all four to b7-6's final line count (in the SAME commit that grows
  the workflow), and re-run `g1.test.sh` + `c1.test.sh` to confirm GREEN.
  **Reconciliation note (Article III.4):** a teammate reported these are "now 340",
  but on the `b7-6-harness` branch all four read **300** and no `340` exists in any
  of the four files (live-grepped 2026-06-23). The 340 bump presumably lives on the
  b7-7 branch and has not merged to this base. b7-6 MUST re-read the LIVE numbers at
  implement time (they may be 340 by then) and bump from whatever is current — NOT
  from a hard-coded 300 — to avoid a stale-baseline conflict.
- **FR-B7-6-031 (MODIFIED, forge-self-ci.md staleness refresh)** —
  `.forge/standards/global/forge-self-ci.md` carries two stale narrative claims
  that b7-6 (the right place, since it edits the CI workflow) MUST refresh:
  - line 16 "`forge-ci.yml` declares **five jobs**" → **six** (`harness`, `gates`,
    `cli`, `lint`, `example`, `summary` — `forge-ci.yml:33,150,170,193,214,261`,
    live-counted; `example` was added by c1, `summary` aggregates them).
  - line 43 the line budget → b7-6's final number (FR-B7-6-030).
  forge-self-ci.md has NO SemVer frontmatter (HTML-comment metadata only) and no
  harness pins its content, so this is a narrative refresh (no version bump, no
  REVIEW.md ledger entry required) — but it MUST be done so the meta-CI standard
  stops lying about the job count + budget.

## Non-Functional

- **NFR-B7-6-001** — **Suite GATES the flip.** The promotion edit (FR-B7-6-020)
  MUST NOT land before the suite (FR-B7-6-001..005) is green. A pre-flip held-guard
  (the schema is still candidate + the CLI still refuses) MUST be present before
  the flip and inverted by the flip task (b8-14-prep negative-guard +
  b8-15 "fails-loud once promotes" pattern).
- **NFR-B7-6-002** — **No regression.** The full harness suite, `verify.sh`,
  `constitution-linter.sh`, and `validate-foundations.sh` MUST be GREEN after the
  flip. The frozen full-stack 1.0.0/2.0.0 trees, `archetype.schema.json`, the
  constitution, and all standards MUST be byte-unchanged (asserted by `git status`
  + the b8-2/t4 coupling guards staying green).
- **NFR-B7-6-003** — **CI-safe by default.** The CI-registered level of
  `b7-6.test.sh` MUST pass in the buf-less, cargo-less CI matrix job
  (the `harness` job, `forge-ci.yml:33-147`) — i.e. its CI level is L1 +
  aggregation + held/post-flip
  guards; the live-codegen L2 legs SKIP there (NFR mirrors b7-2's
  `b7-2.test.sh:7-11` "L1 is the CI level … L2 stays local/opt-in").
- **NFR-B7-6-004** — **Determinism.** Any rendered-tree artifact the suite
  produces (snapshot tarball, double-render diff) MUST be byte-stable across runs
  (b7-10 NFR-B7-10-004 precedent).
- **NFR-B7-6-005** — **Pin discipline.** No new version pin is invented at
  planning. The live cargo build VERIFIES the existing LIVE pins
  (`Cargo.toml.tmpl`); any genuine resolution failure is a verify-then-pin LIVE
  fix pinned ONLY in `Cargo.toml.tmpl` and recorded in the research file
  (Article III.4 / b7-2 ADR-B7-2-003).
- **NFR-B7-6-006** — **Honest justification.** If the flip is justified by a
  local/manual green run rather than CI (ADR-B7-6-005 option a), the run MUST be
  recorded honestly (real command + real output + real toolchain versions) — no
  fabricated "CI green with buf" claim (the B.8.14-flip honest-waiver discipline,
  `b8-14-promotion-flip/specs.md:12-16`).

## BDD Acceptance Criteria

```gherkin
Feature: ai-native-rag promotion gate (b7-6 — candidate → stable/scaffoldable)

  Scenario: the promotion suite proves the archetype end-to-end before the flip
    Given the ai-native-rag archetype is stage:candidate / scaffoldable:false
    When b7-6.test.sh runs at its CI level
    Then ≥35 tests pass: layer roots, unary+streaming proto, codegen manifest,
         Connect-handler seam, scaffold-plan coverage, standards conformance,
         and every sibling B.7 harness (b7-1/2/2a/3/5/9/10/pythia) exits 0
    And the pre-flip held-guard confirms the schema is still candidate and the CLI still refuses

  Scenario: the live codegen + build path is green where the toolchain is present
    Given a rendered ai-native-rag tree and buf + BSR + cargo + node available
    When buf generate (task proto) runs
    Then the Rust grpc-api stubs and the TS generated/connect/rag_pb descriptor are materialised
    And cargo build/test on the rendered workspace (with the generated stubs and the
        registered Connect rag.v1.RagService handler) succeeds
    And Qwik tsc --noEmit on the rendered web-public surface is clean (rag_pb now resolves)

  Scenario: the live legs SKIP cleanly where buf/cargo/tsc are absent (CI, this dev host)
    Given the CI matrix job (python + node, no buf, no cargo) or a buf-less dev host
    When b7-6.test.sh runs
    Then the live-codegen L2 legs echo SKIP and return 0
    And the L1 + aggregation + held/post-flip guards still pass

  Scenario: the flip promotes the archetype only after the suite is green
    Given b7-6.test.sh is green
    When the schema is flipped to stage:stable / scaffoldable:true and the bundle regenerated
    Then validate-foundations.sh check_versioned_schema_siblings stays green
    And b7-1 T-005/T-006, b7-2 T-006, b7-2a L2 are inverted in the same commit
    And forge init --archetype ai-native-rag STOPS refusing and renders the tree

  Scenario: no constitution amendment, no standard bump, no other-archetype edit
    Given the promotion change
    Then .forge/constitution.md, all .forge/standards/*, archetype.schema.json,
         and the frozen full-stack 1.0.0/2.0.0 trees are byte-unchanged
    And the full suite + verify.sh + constitution-linter.sh stay green
```

## ADRs (proposed — to ratify at design)

- **ADR-B7-6-001** — **Single change, not a prep/flip split.** B.8.14 split into
  prep + flip *only because* §VIII.1 Kong→Envoy was a constitution amendment
  requiring a ≥7-day Article XII window (`b8-14-promotion-prep/design.md:11-23`).
  This promotion amends nothing in the constitution — it edits one schema + regens
  one gitignored bundle — so no window forces a split. One change, with the flip as
  the suite-gated final task. (Q-A; maintainer confirm.)
- **ADR-B7-6-002** — **Suite = aggregate siblings + net-new e2e.** The 8 sibling
  harnesses already total 102 `run_test`s and each proves one brick; the promotion
  suite re-runs them (superset gate) and adds ~15-20 net-new end-to-end/flip tests
  (codegen manifest, Connect-handler seam, live buf/cargo/tsc, snapshot, held/
  post-flip guards) → comfortably ≥35. (Q-C.)
- **ADR-B7-6-003** — **Bundle regen = `npm run bundle`, gitignored, CI-fresh.**
  `cli/assets/` is a build artifact (`cli/.gitignore:3`); the source-of-truth edit
  is the schema flip; CI rebuilds the bundle every run (`forge-ci.yml:52-56`).
  Mirrors b8-14-flip FR-FLIP-025. (Q-E.)
- **ADR-B7-6-004** — **Snapshot tarball = deterministic, pending necessity.**
  Propose a `SOURCE_DATE_EPOCH` `.tgz` of the rendered tree (flagship convention);
  defer the necessity decision to the maintainer (Q-D) — a scaffoldable archetype
  conventionally ships one for `forge upgrade` BASE recovery, but it is not
  required by the validator or the CLI gate.
- **ADR-B7-6-005** — **Live legs SKIP in CI; flip justified by a recorded green
  run.** buf is absent in CI and locally, cargo is absent in CI, and buf needs BSR
  network (`buf.gen.yaml.tmpl:20-41`). Proposed (option a): the L2 live-codegen
  legs SKIP in the buf-less CI (b7-10 precedent) and the flip is justified by a
  green run on a host where buf+BSR+cargo+node are present, recorded honestly
  (NFR-B7-6-006). Option b: add a buf+cargo+node CI job. `[NEEDS CLARIFICATION]`
  — the genuine decision; do NOT flip on un-exercised live legs.
- **ADR-B7-6-006** — **Flip is the LAST task, only if green.** The promotion edit
  (FR-B7-6-020) + the lockstep inversions (FR-B7-6-021) land after the suite is
  green (NFR-B7-6-001). Mirrors the b8-14 prep→flip ordering, collapsed into one
  change. ADR-B7-1-002 promotion-gate honored.
- **ADR-B7-6-007** — **The forge-ci size budget lives in 4 places; bump all in
  lock-step.** Registering `b7-6.test.sh` (and any new CI job) grows
  `forge-ci.yml` past its 300-line budget, asserted in `g1.test.sh:343`,
  `c1.test.sh:738`, `forge-ci.md:298`, and `forge-self-ci.md:43`. All four MUST be
  bumped together in the same commit (b7-7's miss is the cautionary precedent);
  re-run `g1`+`c1` to confirm. Also refresh `forge-self-ci.md`'s stale "five jobs"
  → "six" (FR-B7-6-031). Re-read LIVE numbers at implement (may be 340 by then;
  bump from current, not a hard-coded 300). (FR-B7-6-030/031.)

## Anti-Hallucination Pass

- The single most consequential claim — **"the scaffolder is already built; the
  flip auto-opens it"** — is grounded verbatim in
  `forge-init-ai-native-rag.sh:17-19,77-80,99-102` (read 2026-06-23), not inferred.
- The **deferred TODOs** are quoted from `forge-init-ai-native-rag.sh:170-180` and
  `bin-server/src/main.rs.tmpl:11-13,38-39`; the un-generated import from
  `connect-client.ts.tmpl:30` + `web-public/README.md.tmpl:70`.
- The **validator invariant is one-directional** — asserted only because
  `validate-foundations.sh:445-454` was read; the plan explicitly does NOT claim
  the validator enforces `stable ⇒ scaffoldable:true`.
- **CI has no buf and no cargo** — asserted only from reading the six jobs of
  `forge-ci.yml` (`harness`/`gates`/`cli`/`lint`/`example`/`summary`,
  lines 33,150,170,193,214,261); none installs buf or a Rust toolchain.
  buf-as-remote-BSR-plugins from `buf.gen.yaml.tmpl:20-41`;
  `which buf` = absent on this host (live-checked).
- **The B.8.14 split rationale** (amendment window) is quoted from
  `b8-14-promotion-prep/proposal.md:9-33` + `design.md:11-23`; the "calendar-gated"
  framing from roadmap line 183.
- **`[NEEDS CLARIFICATION]`**: Q-A (single vs split), Q-B (the buf/CI flip
  justification — the genuine decision), Q-D (snapshot necessity). No test count,
  pin, or API is fabricated; the ≥35 figure is justified by the 102 sibling
  `run_test`s + ~15-20 net-new (ADR-B7-6-002).

---

**Gate**: Specs written. Review `specs.md` (esp. the MODIFIED schema flip + Q-B).
Next: `/forge:design b7-6-harness`.
