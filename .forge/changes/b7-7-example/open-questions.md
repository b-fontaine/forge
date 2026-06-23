# Open Questions: b7-7-example

<!-- Article III.4 anti-hallucination protocol. Genuine ambiguities are -->
<!-- recorded here rather than guessed. Resolved questions move to the    -->
<!-- design ADRs; unresolved ones BLOCK implementation per CLAUDE.md.     -->

## Q-1 — Build the example now via `overlay.sh`, or sequence after `b7-6` promotion? (RESOLVED at design → ADR-B7-7-001)

**Context.** `ai-native-rag` is `stage: candidate` / `scaffoldable: false`
(`b7-1-schema`, ADR-B7-1-002). `forge init --archetype ai-native-rag`
therefore **refuses cleanly with exit 3** (registered, no scaffoldable
version — `b7-2a-dispatch-register`). Promotion to `stable` /
`scaffoldable: true` is gated on a green `b7-6-harness`. So the example
**cannot** be generated through the public `forge init` CLI path until
b7-6 lands.

Two options:
- **(A) Build now via `overlay.sh`.** `b7-2-scaffolder` established that
  the RAG archetype renders through `overlay.sh` directly (ADR-B7-2-007:
  the wrapper renders via `overlay.sh`, not `init.sh`; the b7-2 L2
  harness renders the plan via `overlay.sh` into a tmpdir). The templates
  are self-contained (full `Cargo.toml`s, no `cargo new`; Qwik, no
  `flutter create`), so `overlay.sh` alone produces a complete tree.
- **(B) Sequence b7-7 AFTER b7-6 promotion** and scaffold through the
  promoted `forge init` CLI.

**Resolution (recommended → ADR-B7-7-001): Option A — build now via
`overlay.sh`.** Rationale: (1) it does not block b7-7 behind b7-6, which
the §0.12 dependency graph lists as parallelisable (#4–#9 "largement
parallélisables"); (2) it exactly mirrors how `b7-2` itself validated
the templates, so the rendered tree is provably the templates' output;
(3) `c1-reference-project` set the precedent of rendering the example
through the scaffolder of record at the time (c1 used `init.sh` because
that was the flagship renderer; b7-7 uses `overlay.sh` because that is
the RAG renderer of record per ADR-B7-2-007). The example's
`scaffold-manifest.yaml` records `archetype_version: "1.0.0"` +
`stage: candidate` so adopters know precisely what they are looking at;
b7-6 promotion does not invalidate the committed tree.

## Q-2 — Ship 3 archived demos, or 3 archived + 1 `specified`-only? (RESOLVED at design → ADR-B7-7-003)

**Context.** The §0.12 brick line for b7-7 says **"3 demos"**.
`c1-reference-project` shipped **3 archived + 1 `specified`** (demo-004)
specifically to demonstrate the in-flight `[NEEDS CLARIFICATION]` state
(FR-EX-005). Mirroring c1 verbatim would mean a 4th demo, contradicting
the brick spec's count.

**Resolution (recommended → ADR-B7-7-003): ship exactly 3 archived
demos** to honour the brick spec literally. The in-flight `specified`
state is already demonstrated for adopters by `forge-fsm-example`'s
demo-004 (the example-tree machinery is shared; an adopter learning the
in-flight workflow reads it once, in either tree). `[NEEDS CLARIFICATION]`
markers still appear inside the 3 archived demos' historical specs where
genuine ambiguities were resolved. A future `b7-7-followup` may add a
`specified`-only RAG demo if adopters request a RAG-specific in-flight
illustration.

## Q-3 — Which demo carries the multi-layer (Janus) shape? (RESOLVED at design → ADR-B7-7-002)

**Context.** NFR-EX-005 (mirrored) requires the demos to cover distinct
layer combinations, and the c1 precedent shipped at least one multi-layer
demo to exercise Janus (≥ 2 layers → FR-GL-015). The RAG archetype's
layers are `{backend, frontend, infra}`.

**Resolution (recommended → ADR-B7-7-002): demo-003-rag-query-ui is
`layers: [backend, frontend]`.** The Qwik query UI (frontend) naturally
spans the LLM gateway (backend) it calls through Connect; this is the
honest multi-layer surface. demo-001 + demo-002 stay single-layer
backend (distinct sub-surfaces: `rag/` pipeline vs `mcp/` server).
`infra` is reused-by-reference (the pgvector/Temporal/Zitadel substrate
is B.8's, consumed not re-decided — memo §3) so no demo is
infra-primary; this is documented, not a gap.

## Q-4 — demo-003 streaming + b7-10 dependency + `forge-ci.yml` coordination (RESOLVED — maintainer option (b), 2026-06-22 → ADR-B7-7-002)

**Context.** This question started as a pure CI-coordination concern
(b7-7 extends the `example` job in `.github/workflows/forge-ci.yml` to
gate a second tree, touching regions `b7-10-streaming` may also edit).
The maintainer's ratification of **option (b)** subsumed it into a
substantive design decision: **demo-003 IS the streaming rag-query-UI
demo**, consuming `b7-10-streaming`'s `RagService.QueryStream` /
`queryStream` contract, with the XI.5 fallback degrading to the unary
`RagService.Query` path (b7-10's ADR-B7-10-001, "unary retained as
degradation target").

**Resolution (RESOLVED — option (b), maintainer-ratified 2026-06-22):**
1. **Hard dependency**: demo-003 consumes b7-10's streaming contract and
   the example tree is rendered from the **b7-10-extended templates**, so
   **b7-7 lands AFTER b7-10**. `.forge.yaml depends_on` lists `B.7.10`;
   ADR-B7-7-002 records the decision; proposal Scope + specs
   FR-RAGEX-004/005 updated.
2. **CI merge order is now deterministic**: because b7-10 is a hard
   predecessor, **b7-10 merges first** and b7-7 rebases its `example`-job
   edit (one RAG gate block + one harness-loop entry) onto b7-10's. No
   guess about b7-10's CI footprint is needed (Article III.4) — b7-7
   simply rebases onto whatever b7-10 lands. The orchestrator owns the
   rebase, but the order is no longer ambiguous.

No open spec ambiguity remains for b7-7.

## Q-5 — Should the rendered tree's demo product code actually build in CI? (RESOLVED at design → ADR-B7-7-004)

**Context.** The RAG backend requires `cargo build` (heavy: ONNX for the
local embedder, rmcp, async-openai) and the Qwik UI requires `npm` +
`buf generate`. Running these in the Forge repo's `example` CI job would
require Rust + Node + buf toolchains + network, which the existing
`example` job (parse-only, c1 ADR-006) deliberately avoids.

**Resolution (recommended → ADR-B7-7-004): parse-only / own-gates-only
in CI**, mirroring c1 ADR-006. The `example` job runs the RAG tree's own
`verify.sh` + `constitution-linter.sh` + a structural YAML/template
parse — **no `cargo build`, no `npm`, no `buf generate`, no network**.
The demos' code is TDD-conformant and reviewable; the toolchain-gated
build/test is exercised by `b7-2-scaffolder`'s L2 harness (which already
`cargo check`s the rendered workspace) and by `b7-6-harness`'s ≥35-test
promotion suite. b7-7's own harness `b7-7.test.sh` keeps an opt-in L2
(`--require-example-tools`) that runs the RAG tree's gates, matching
c1.test.sh's L2.
