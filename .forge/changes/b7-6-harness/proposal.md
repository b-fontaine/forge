# Proposal: b7-6-harness

<!-- Created: 2026-06-23 -->
<!-- Schema: default -->
<!-- Audit: B.7.6 (docs/new-archetypes-plan.md §0.12 table row 9 + §6.2 — b7.test.sh ≥35 + snapshot tarball ; THE PROMOTION GATE candidate→stable/scaffoldable:true, ADR-B7-1-002, patron B.8.14-C2) -->
<!-- Input: b7-2-scaffolder (the gated scaffolder body + the b7-6 TODOs) + b7-10-streaming (its buf/tsc L2 legs "ride b7-6") + b8-14-promotion-prep/-flip (the promotion precedent to mirror) -->

## Problem

The `ai-native-rag` archetype is **fully scaffolded but inert**. As of B.7.10
(2026-06-23) the chain has shipped: the candidate schema (b7-1), the standards
(b7-3), the dispatch entry + refusing wrapper (b7-2a), the complete template tree
+ gated scaffolder body (b7-2, 56 templates, rendered `cargo test` 35/0), and the
streaming surface (b7-10). Yet `forge init --archetype ai-native-rag` still
**refuses with exit 3** because the schema is `stage: candidate` /
`scaffoldable: false`.

That refusal is by design and gated on this brick. Three concrete facts make
b7-6 the gate:

1. **The schema is candidate.** `.forge/schemas/ai-native-rag/1.0.0.yaml:33-34`
   declares `stage: candidate` + `scaffoldable: false`. The CLI's
   `selectScaffoldableVersion` returns null for it, so `resolveScaffolder`
   refuses (`b7-1.test.sh:335-336` records this; `b7-2a.test.sh:91-106` asserts
   the live `forge init … exit 3`). The schema header
   (`1.0.0.yaml:14-18`) states promotion "happens in the B.7 scaffolder-completion
   brick, gated on a green b7-6 harness (ADR-B7-1-002, mirroring the B.8.14-C2
   flip)."

2. **The scaffolder body is already built and gated — not missing.**
   `bin/forge-init-ai-native-rag.sh:71-102` reads the schema's
   `stage`/`scaffoldable` itself: while candidate it refuses (exit 3, structured
   `[REFUSAL …]`, zero writes); "the moment the schema is promoted to `stable` /
   `scaffoldable: true` … the gate opens and this same body renders the scaffold
   with NO further edits to this file" (lines 17-19). b7-2's L2 already proves the
   render path works under the `FORGE_AINR_FORCE_SCAFFOLD=1` override
   (`b7-2.test.sh:276-278`). So promotion is a **schema flip + bundle regen**, not
   a new scaffolder.

3. **The live codegen + build was explicitly deferred to b7-6.**
   `bin/forge-init-ai-native-rag.sh:170-180` carries the exact deferred TODOs:
   `TODO(b7-6): … buf generate` (materialises the Rust tonic/prost stubs + the TS
   Connect `rag_pb` descriptor the Qwik web-public surface imports) and
   `TODO(b7-6): … cargo fetch`. The Connect handler registration is deferred at
   `backend/bin-server/src/main.rs.tmpl:11-13,38-39` ("the RAG `rag.v1.RagService`
   handler is registered there once codegen runs (`task proto`)"). b7-10's L2
   `buf`/`tsc` legs SKIP and say "rides b7-6" (`b7-10.test.sh:32-37,332,335`). The
   Qwik client imports an un-generated descriptor:
   `frontend/web-public/src/lib/connect-client.ts.tmpl:30`
   (`import { RagService } from "./generated/connect/rag_pb"`) with the comment
   "won't type-check / build until you run `task proto`"
   (`frontend/web-public/README.md.tmpl:70`).

So the archetype's end-to-end build path (proto → Rust + TS codegen → Connect
handler wired → `cargo build` → Qwik `tsc`/build) has **never been run live** —
only the hermetic render + offline `cargo test`/`cargo check` (which compile the
hand-written backbone that does not depend on the generated stubs). Promoting the
archetype to `scaffoldable: true` without first proving that path is exactly the
"broken scaffold" the candidate gate exists to prevent (`1.0.0.yaml:14-18`).

**This brick is the promotion gate.** It ships a comprehensive promotion test
suite (≥35 tests) that proves the whole archetype end-to-end, wires + verifies
the deferred live codegen/build, and — only once that suite is green — flips the
schema to `stable` / `scaffoldable: true` and regenerates the CLI bundle so
`forge init --archetype ai-native-rag` stops refusing and renders the tree.

**Ground truth (re-read 2026-06-23, Article III.4):**

- **No constitution amendment is required.** Unlike B.8.14 (which split into
  prep + flip *because* §VIII.1 Kong→Envoy was a constitution amendment requiring
  a ≥7-day Article XII window — `b8-14-promotion-prep/proposal.md:9-33`,
  roadmap line 183 "calendar-gated"), this promotion touches only the archetype
  schema + the CLI bundle. It amends nothing in `.forge/constitution.md`, no
  standard, and no other archetype. The B.8.14 *split* was forced by the
  amendment; ai-native-rag has no such forcing function (Q-A).
- **The validator's invariant is one-directional.**
  `validate-foundations.sh::check_versioned_schema_siblings` (lines 397-469)
  enforces `candidate ⇒ scaffoldable: false` (line 453) and `stage=stable
  requires version ≥ 1.0.0 without prerelease` (lines 448-451). There is **no**
  `stable ⇒ scaffoldable:true` clause in the validator. ai-native-rag `1.0.0`
  satisfies the version floor; flipping to `stable` + `scaffoldable:true` clears
  the candidate clause and stays valid. The `stable ⇒ scaffoldable:true`
  *semantic* requirement is enforced by the wrapper's `is_scaffoldable()` (both
  `stage==stable` AND `scaffoldable==true` — `forge-init-ai-native-rag.sh:81-97`)
  and is what makes the CLI stop refusing; it is NOT a validate-foundations hard
  check, and the plan does not claim it is.
- **`buf` is absent locally AND in CI; CI has no Rust toolchain.**
  `which buf` = absent on this dev host; `.github/workflows/forge-ci.yml` installs
  python (`:38`) + node (`:44`) + `npm ci`/`npm run bundle` (`:49-56`) but **no
  `buf` and no cargo/rust** in any of its six jobs (`harness`/`gates`/`cli`/`lint`/
  `example`/`summary`, lines 33,150,170,193,214,261). The buf codegen plugins are
  **remote BSR plugins**
  (`buf.gen.yaml.tmpl:20-41` — `buf.build/community/neoeinstein-tonic`,
  `buf.build/bufbuild/es`, …), so `buf generate` needs buf **and BSR network
  access**. The live codegen/build therefore cannot run in the existing CI matrix
  job — exactly like b7-10's SKIP legs. WHERE the green live run happens, and
  whether CI must gain a buf+cargo+node job, is the central decision (Q-B).
- **Pins are already LIVE.** b7-2 + b7-10 already pinned the workspace LIVE
  (`backend/Cargo.toml.tmpl`: rmcp 1.7.0, pgvector 0.4.2, async-openai 0.41.1,
  fastembed 5.17.2, sqlx 0.9, tokio-stream 0.1.18 — lines 76,78,82,86,60,39).
  "Re-pin LIVE" for b7-6 is therefore **verification that they resolve + build
  under live codegen**, not new pinning. Any pin that genuinely fails to resolve
  live is a verify-then-pin LIVE fix recorded here (Article III.4), pinned only in
  the consuming `Cargo.toml.tmpl`.
- **The bundle is a gitignored build artifact.** `cli/assets/` is gitignored
  (`cli/.gitignore:3`); `npm run bundle` = `npm run build && node
  scripts/bundle-assets.mjs` (`cli/package.json:28`) mirrors `.forge/` into
  `cli/assets/`. CI runs `npm run bundle` fresh every run (`forge-ci.yml:52-56`),
  so the schema flip propagates to the CLI automatically in CI; locally the
  adopter rebuilds. This is exactly how B.8.14-flip handled it
  (`b8-14-promotion-flip/specs.md:78-79`, FR-FLIP-025).

## Solution

Mirror the B.8.14 promotion shape (suite-gates-the-flip; flip is last, only if
green), adapted to a **single change** because no constitution amendment forces a
split. Concretely:

1. **Promotion test suite `.forge/scripts/tests/b7-6.test.sh` (≥35 tests).**
   Three test tiers (mirroring the b7-* harness `--level` convention):
   - **L1 (hermetic, grep/structure, CI-safe):** end-to-end *structural* proof
     that the full archetype is coherent — every layer root, the proto contract
     (unary + streaming), the codegen manifest targets, the Connect-handler
     registration seam, the scaffold-plan ↔ tree coverage, the gated wrapper, the
     dispatch entry, the standards-conformance markers, and the snapshot artifact.
     Plus an **aggregation tier** that re-runs the sibling per-brick harnesses
     (b7-1, b7-2, b7-2a, b7-3, b7-5, b7-9, b7-10, b7-pythia) and asserts each
     exits 0 — so the promotion suite is a true superset gate (Q-C).
   - **L2 (toolchain-gated, SKIP-when-absent):** render the plan via `overlay.sh`
     (b7-2/b7-10 convention), then run the **live** path: `buf generate` (proto →
     Rust + TS), `cargo build`/`cargo test` of the rendered workspace *including*
     the generated stubs, the Connect handler registration compiling, and Qwik
     `tsc --noEmit`/build. These SKIP gracefully when buf/cargo/tsc/BSR are absent
     (the b7-10 precedent) and are the legs that MUST run green where the
     toolchain IS present (Q-B).
   - **A promotion-readiness / post-flip tier:** before the flip, assert the
     schema is still candidate + the CLI still refuses (negative held-guard,
     b8-14-prep pattern); the flip task inverts these to assert stable +
     scaffoldable:true + the CLI renders (b8-15 "fails-loud once promotes"
     pattern, `b8-15.test.sh` precedent).
2. **Wire + verify the deferred live codegen/build.** Implement the
   `forge-init-ai-native-rag.sh:170-180` TODOs as a verified path: confirm
   `task proto` (`buf generate`) materialises the Rust stubs +
   `frontend/web-public/src/lib/generated/connect/rag_pb` descriptor; wire the
   Connect `rag.v1.RagService` handler registration in
   `backend/bin-server/src/main.rs.tmpl` (the seam at lines 38-39) against the
   generated `grpc-api` stubs; run `cargo build` on the rendered workspace; run
   Qwik `tsc`/build. The *mechanism* is template-level (the Taskfile `proto`/build
   targets already exist — `Taskfile.yml.tmpl:97-100`); b7-6's job is to make the
   end-to-end run green and assert it in L2.
3. **Re-pin LIVE = verify the existing pins build live.** Run the live cargo
   build of the rendered+generated workspace; record the result in a research
   file. Fix only pins that genuinely fail to resolve (verify-then-pin LIVE,
   recorded; pinned only in `Cargo.toml.tmpl`).
4. **Snapshot tarball (decision pending, Q-D).** The `forge upgrade` substrate
   recovers BASE from a committed snapshot tarball per archetype
   (roadmap line 100; full-stack 1.0.0 snapshot 422 KB). A scaffoldable archetype
   conventionally ships one. b7-6 proposes generating a deterministic
   (`SOURCE_DATE_EPOCH`) snapshot of the rendered ai-native-rag tree — pending
   maintainer confirmation of necessity/format (Q-D).
5. **The flip (FINAL, gated).** Only after the suite is green: edit
   `.forge/schemas/ai-native-rag/1.0.0.yaml` `stage: candidate → stable`,
   `scaffoldable: false → true`, reword the candidate-semantics header block;
   invert `b7-1.test.sh` T-005/T-006 (now stable/scaffoldable:true) +
   `b7-2.test.sh` T-006 (wrapper no longer refuses) + `b7-2a.test.sh` L2 (CLI no
   longer exit 3) in lockstep; `npm run bundle` regen (Q-E); register
   `b7-6.test.sh` in `forge-ci.yml`. Full suite + `verify.sh` +
   `constitution-linter.sh` + `validate-foundations.sh` green.

## Scope In

- `.forge/scripts/tests/b7-6.test.sh` — the ≥35-test promotion suite (L1 + L2 +
  aggregation + held/post-flip guards) + registration in
  `.github/workflows/forge-ci.yml`.
- Wiring + live verification of the b7-2 deferred TODOs (`buf generate`, Connect
  handler registration in `bin-server/src/main.rs.tmpl`, `cargo fetch`/build,
  Qwik `tsc`/build), template-level only.
- A research file recording the live cargo/buf/tsc run + any verify-then-pin LIVE
  fix (no new pin invented at planning).
- **The schema flip** (`ai-native-rag/1.0.0.yaml` stage/scaffoldable) — the FINAL,
  suite-gated task.
- The lockstep harness inversions (b7-1 T-005/006, b7-2 T-006, b7-2a L2) in the
  SAME commit as the flip (b8-14-flip break-cascade pattern).
- `npm run bundle` regen so the CLI stops refusing (gitignored artifact; the
  source-of-truth change is the schema flip).
- The snapshot tarball (pending Q-D).

## Scope Out (Explicit Exclusions)

- **No constitution amendment, no standard bump, no other-archetype edit.** This
  promotion is schema + bundle only (contrast B.8.14 which amended §VIII.1).
- **No new scaffolder body.** `forge-init-ai-native-rag.sh` auto-opens on the
  flip with no edit (lines 17-19, 77-80); b7-6 does not rewrite it (it may
  implement the post-render `buf generate`/`cargo fetch` steps the file marks
  TODO, if the maintainer wants them in the wrapper vs documented as `task proto`
  — see Q-B/design).
- **No new RAG feature.** Streaming (b7-10), AI-Act (b7-5), Janus AI rules (b7-9),
  Pythia (b7-pythia), the example tree (b7-7) are separate bricks; b7-6
  *aggregates* their harnesses, it does not re-implement them.
- **No `examples/forge-rag-example/`** — that is b7-7 (which should follow this
  flip so its example renders from a stable archetype; soft relation, not a hard
  dependency).
- **No edit to the frozen full-stack 1.0.0/2.0.0 trees, no `archetype.schema.json`
  change.**

## Impact

- **Users**: after this brick, `forge init --archetype ai-native-rag` STOPS
  refusing (exit 3) and renders a Kong-less Envoy/Connect RAG tree that builds
  end-to-end (`task proto` → `cargo build` → Qwik build). This is the first time
  the archetype is usable.
- **Technical**: the schema flips candidate→stable/scaffoldable:true (the
  single source-of-truth edit); the wrapper auto-activates; the bundle re-mirrors
  the schema; the CLI's `selectScaffoldableVersion` now returns 1.0.0. The
  deferred live codegen/build path is proven green (where the toolchain runs).
- **Dependencies**: B.7.1/2/2a/3/5/9/10 archived; b7-7 soft-follows. Reuses the
  2.0.0 substrate by reference exactly as b7-2 does.

## Constitution Compliance (v2.0.0)

- **Article I (TDD)**: `b7-6.test.sh` is authored RED-first (the suite fails
  before the live codegen wiring + the flip); the live legs prove the rendered
  tree compiles + its tests pass.
- **Article III (Specs Before Code)**: proposal → specs → design → tasks before
  any harness/schema edit. **III.4 anti-hallucination**: every claim about the
  schema, the validator, the wrapper TODOs, CI toolchains, and B.8.14 is grounded
  in a cited file read 2026-06-23; the genuine decisions (Q-A…Q-E) are surfaced as
  `[NEEDS CLARIFICATION]` with a recommendation, not guessed. No version pin is
  invented.
- **Article XI (AI-First)**: the suite asserts the rendered RAG tree preserves the
  mandatory non-AI fallback (XI.5), prompt-audit (IX.6), and PII redaction (XI.6)
  markers under live build (b7-2 T-007 conformance, carried).
- **Promotion discipline (ADR-B7-1-002)**: the suite GATES the flip — the flip is
  the last task, performed only after the suite is green (mirrors b8-14
  prep→flip ordering, collapsed into one change).

## Open Questions (to resolve at specify/design)

- **Q-A** — Single change vs split `b7-6-prep` + `b7-6-flip`? Recommended: **single
  change** (B.8.14 split *only* because of the constitution-amendment window;
  none here). See `open-questions.md`.
- **Q-B** — How is the flip justified given `buf` is absent locally AND in CI, and
  cargo is absent in CI? Does CI gain a buf+cargo+node job, or is the flip
  justified by a recorded local/manual green run (which still needs buf + BSR
  network)? `[NEEDS CLARIFICATION]`.
- **Q-C** — Exact ≥35-test composition: aggregate the 8 sibling harnesses (re-run
  + assert exit 0) PLUS net-new e2e tests? Recommended: yes (the siblings already
  total 102 `run_test`s; b7-6 adds ~15-20 net-new e2e/flip tests). See
  `open-questions.md`.
- **Q-D** — Snapshot tarball: necessary now, and what format? Recommended:
  deterministic `SOURCE_DATE_EPOCH` `.tgz` mirroring the flagship snapshot
  convention. `[NEEDS CLARIFICATION]`.
- **Q-E** — `cli/assets` bundle regen mechanics for scaffoldable:true — confirmed
  `npm run bundle` (gitignored, CI-fresh); flagged only to confirm no committed
  artifact is expected.

---

**Gate**: Proposal created at `.forge/changes/b7-6-harness/proposal.md`. Review and
confirm (esp. Q-A single-vs-split + Q-B the buf/CI justification) before
proceeding to → `/forge:specify b7-6-harness`.
