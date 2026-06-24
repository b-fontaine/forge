# Open Questions: b7-6-harness

<!-- Anti-hallucination ledger (Constitution Article III.4). Items here are NOT -->
<!-- guessed in the spec/design; they are surfaced for maintainer resolution, each -->
<!-- with a recommended resolution grounded in a cited file read 2026-06-23. -->

<!-- MAINTAINER RESOLUTION (2026-06-23): all open questions resolved. Q-A=single
     change; Q-B=ADD a harness-rust CI job (option b, NOT the option-a skip-in-CI);
     Q-C=aggregate 8 siblings + net-new e2e (≥35); Q-D=SHIP the deterministic
     SOURCE_DATE_EPOCH .tgz snapshot; Q-E=npm run bundle (gitignored/CI-fresh).
     Each item below carries its RESOLVED block. -->

## Q-A — Single change vs split `b7-6-prep` + `b7-6-flip`?  ✅ RESOLVED (single change)

**RESOLVED (maintainer, 2026-06-23): SINGLE change** (ADR-B7-6-001 as written). One
change; the flip is the last, suite-gated task. No prep/flip split — no constitution
amendment forces an Article XII window here (unlike B.8.14).

**Question**: B.8.14 promoted the flagship via a two-brick split
(`b8-14-promotion-prep` then `b8-14-promotion-flip`). Should b7-6 mirror the split,
or be a single change?

- **Why it's open / why B.8.14 split**: the B.8.14 split was forced by a
  Constitution amendment. Promoting the flagship required amending §VIII.1
  (Kong→Envoy), and `Article XII` + GOVERNANCE.md mandate a **≥7-day public
  discussion window** before ratification ("a single-session ratify+apply would
  violate the very process the constitution requires" —
  `b8-14-promotion-prep/design.md:11-15`; "calendar-gated" — roadmap line 183). The
  prep brick = Amendment-Process step 1 + staged bundle; the flip brick = steps 3-4
  after the window.
- **Why b7-6 is different**: this promotion amends **nothing** in
  `.forge/constitution.md`. It edits one schema file
  (`ai-native-rag/1.0.0.yaml` stage/scaffoldable) and regenerates one gitignored
  bundle (`cli/assets/`). No Article changes, no standard bump, no other-archetype
  edit. There is no Article XII window and no forcing function for a split.
- **Recommendation**: **single change** (ADR-B7-6-001). Keep the b8-14
  "suite-gates-the-flip; flip is last" *ordering* (ADR-B7-6-006) without the
  two-brick overhead. The only safety the split bought — preventing an
  out-of-process constitutional amendment — is irrelevant here; the pre-flip
  held-guard (Tier D) provides the equivalent "can't flip out of order" safety in
  one change.
- **Impact if split anyway**: a `b7-6-prep` would ship the suite + live-codegen
  wiring + held-guards; a `b7-6-flip` would do only the schema flip + bundle. Pure
  overhead absent an amendment; not recommended.

## Q-B — How is the flip justified given buf is absent in CI AND locally, and cargo is absent in CI?  ✅ RESOLVED (option b — add a `harness-rust` CI job)

**RESOLVED (maintainer, 2026-06-23): OPTION B — add a permanent `harness-rust` CI
job.** ADR-B7-6-005 flips from the proposed option-a (SKIP-in-CI + one-time recorded
local run) to **option b**: a NEW job in `.github/workflows/forge-ci.yml` that installs
`buf` (`bufbuild/buf-setup-action`, pinned tag), a Rust toolchain
(`dtolnay/rust-toolchain`, pinned), and node, then runs the b7-6 live path
(`buf generate` → Rust+TS codegen → Connect handler registration → `cargo build`/`test`
→ Qwik `tsc`) as a **permanent per-PR gate**. The flip is justified by THIS job going
green in CI — not by an un-rechecked local run. The `summary` job's `needs:` list MUST
include `harness-rust`. Note: this makes the live legs a permanent gate (re-run every
PR), the rigorous long-term posture; the L2 legs still SKIP gracefully on a buf-less
host (this dev host, where `which buf` is absent) so the suite stays runnable locally.

**Original question (retained for the ledger)**: the promotion's whole point is that
the archetype builds end-to-end (proto → codegen → Connect handler → cargo build →
Qwik build). That live path has **never run**. Where does the green live run happen,
and does CI need to gain a buf + cargo job, or is the flip justified by a recorded
local/manual run?

- **Why it's open (cited facts, 2026-06-23)**:
  - `buf generate` uses **remote BSR plugins** (`buf.gen.yaml.tmpl:20,27,31,37` —
    `buf.build/community/neoeinstein-tonic`, `.../neoeinstein-prost`,
    `buf.build/connectrpc/go`, `buf.build/bufbuild/es`), so it needs the `buf` CLI
    **and BSR network access**.
  - **CI has no buf and no Rust toolchain.** All six `forge-ci.yml` jobs
    (`harness`/`gates`/`cli`/`lint`/`example`/`summary`, lines
    33,150,170,193,214,261) install python + node only.
    The harness array (lines 69-134) runs b7-* harnesses at `--level 1` (b7-2,
    b7-3, b7-10) or `--level 1,2` (b7-1, b7-2a, b7-9, b7-pythia) — the b7-2/b7-10
    L2 cargo/buf legs SKIP in CI because the toolchain is absent.
  - **buf is absent on this dev host too** (`which buf` = not found); cargo IS
    present locally; `tsc` lives in `node_modules` (not on PATH).
  - b7-10's L2 buf/tsc legs SKIP and explicitly say "rides b7-6"
    (`b7-10.test.sh:32-37,332,335`) — i.e. b7-6 was always the brick expected to
    run them live.
- **Recommendation (ADR-B7-6-005, option a)**: the L2 live-codegen legs **SKIP in
  the buf-less CI** (the b7-10 precedent), the CI-registered level is L1 +
  aggregation + held/post-flip guards (CI-safe, NFR-B7-6-003), and **the flip is
  justified by a green run on a host where buf + BSR + cargo + node are present**,
  recorded honestly in `.forge/research/b7-6-live-codegen.md` (real commands +
  output + tool versions — NFR-B7-6-006). To do this run, `buf` must be installed
  and BSR reachable (cargo + node are already available locally).
- **Alternative (option b)**: add a dedicated `harness-rust` CI job that installs
  buf (`bufbuild/buf-setup-action`) + Rust (`dtolnay/rust-toolchain`) + node and
  runs `b7-6.test.sh --level 1,2`, making the live path a **permanent CI gate**.
  Heavier (BSR network + a Rust toolchain + longer job in CI) but the rigorous
  long-term posture — and it would also flip b7-2/b7-3/b7-10 to run their L2 legs
  in CI.
- **Why this is the genuine decision**: option a unblocks the flip today but leans
  on a one-time human-run gate (the live legs aren't re-checked on every PR);
  option b is durable but a CI infrastructure change. **Do NOT flip the schema on
  un-exercised live legs** — whichever option, the live buf/cargo/tsc path MUST be
  green *somewhere* before T-041. The maintainer should also confirm whether buf
  should be installed on the dev host (so the planning agent / implementer can run
  option a locally) or whether option b is preferred.

## Q-C — Exact ≥35-test composition: aggregate the siblings or only net-new e2e?  ✅ RESOLVED (aggregate + net-new)

**RESOLVED (maintainer, 2026-06-23): aggregate the 8 sibling harnesses + net-new
e2e ⇒ ≥35** (ADR-B7-6-002 as written). Tier A re-runs b7-1/2/2a/3/5/9/10/pythia
(superset gate), Tier B adds net-new L1 e2e, Tier C adds L2 live legs, Tier D adds
held/post-flip guards.

**Question**: should the suite re-run the sibling per-brick harnesses, or only add
net-new end-to-end tests?

- **Grounding**: the 8 landed B.7 harnesses already total **102 `run_test`s**
    (live-counted 2026-06-23: b7-1 18, b7-2 10, b7-2a 3, b7-3 7, b7-5 19, b7-9 15,
    b7-10 11, b7-pythia 19).
- **Recommendation (ADR-B7-6-002)**: **both** — Tier A aggregates the 8 siblings
  (re-run + assert exit 0 → superset gate; absent sibling = clean SKIP), Tier B
  adds ~18-22 net-new L1 e2e (codegen-manifest targets, Connect-handler seam,
  scaffold-plan↔tree full coverage, proto coexistence, conformance), Tier C adds
  ~5-7 L2 live legs, Tier D adds ~2-3 held/post-flip guards. Total ≈ **37+** ≥ 35.
  This makes the ≥35 figure *justified*, not a number invented to hit a target.
- **Impact if net-new only**: still reaches ~25-30; would need padding to hit 35
  and would NOT be a true superset gate. Aggregation is the honest interpretation
  of "validating the whole archetype end-to-end".

## Q-D — Snapshot tarball: necessary now, and what format?  ✅ RESOLVED (ship the deterministic .tgz)

**RESOLVED (maintainer, 2026-06-23): SHIP the deterministic `SOURCE_DATE_EPOCH`
`.tgz` snapshot** (FR-B7-6-010 stays IN, not dropped). A scaffoldable archetype
conventionally ships a snapshot so adopters can `forge upgrade`; b7-6 generates a
byte-stable `.tgz` of the rendered ai-native-rag tree and asserts determinism + a
size budget at L2.

**Question**: the brief lists "possibly ship a snapshot tarball". Is one required
at promotion, and in what format?

- **Grounding**: `forge upgrade` recovers BASE from a committed per-archetype
  snapshot tarball (roadmap line 100; flagship 1.0.0 = 422 KB gzipped, 41% of the
  1 MB budget). A scaffoldable archetype conventionally ships one so adopters can
  later `forge upgrade`. It is **NOT** required by `validate-foundations.sh` or by
  the CLI scaffoldable gate.
- **Recommendation (ADR-B7-6-004)**: ship a **`SOURCE_DATE_EPOCH`-deterministic
  `.tgz`** of the rendered ai-native-rag tree (the `forge-sbom.sh`/compliance-bundle
  determinism pattern, NFR-B7-6-004), with its generation + byte-stability asserted
  at L2 — **IF** the maintainer wants `forge upgrade` supported for ai-native-rag
  at promotion. If "not now", drop FR-B7-6-010 and record that
  upgrade-from-ai-native-rag is unsupported until a later brick ships the snapshot.
- **Why flagged**: shipping a snapshot is real, sized work (generate, size-budget,
  determinism-assert, possibly a new `forge upgrade` matrix cell à la b8-15) — it
  shouldn't be silently assumed into the promotion.

## Q-E — `cli/assets` bundle regen mechanics for scaffoldable:true  ✅ RESOLVED (`npm run bundle`)

**RESOLVED (maintainer, 2026-06-23): `npm run bundle`** (ADR-B7-6-003 as written).
`cli/assets/` is gitignored + rebuilt fresh by CI; nothing to commit. The implementer
re-runs `npm run bundle` to confirm `forge init --archetype ai-native-rag` stops
refusing locally.

**Question**: how does `forge init` stop refusing once the schema is flipped?

- **Grounding**: the CLI reads schemas from `cli/assets/` (a mirror of `.forge/`).
  `cli/assets/` is **gitignored** (`cli/.gitignore:3`). `npm run bundle` =
  `npm run build && node scripts/bundle-assets.mjs` (`cli/package.json:28`)
  rebuilds it. CI runs `npm run bundle` fresh every run (`forge-ci.yml:52-56`), so
  the schema flip propagates to the CLI automatically in CI. This is exactly how
  b8-14-flip handled it (FR-FLIP-025: "bundle regenerated via `npm run bundle`
  (gitignored build artifact)").
- **Recommendation (ADR-B7-6-003)**: regenerate via `npm run bundle` at the flip
  (FR-B7-6-022); the committed source-of-truth edit is the schema flip, NOT the
  bundle bytes (nothing to commit — it's gitignored). No further mechanism needed.
- **Why flagged**: only to confirm no committed bundle artifact is expected (it
  isn't) and that the local implementer re-runs `npm run bundle` to see the live
  CLI stop refusing.

---

## Summary for the orchestrator — ALL RESOLVED (2026-06-23)

| Q | Decision needed | RESOLUTION (maintainer, 2026-06-23) |
|---|-----------------|-------------------------------------|
| **Q-A** | single change vs prep/flip split | **single change** (no amendment forces a split) |
| **Q-B** | where the live buf/cargo/tsc legs run + how the flip is justified | **option b**: ADD a permanent `harness-rust` CI job (buf + Rust toolchain + node) running `b7-6.test.sh --level 1,2`; flip justified by THIS job green in CI |
| **Q-C** | suite composition | aggregate 8 siblings + net-new e2e (≥ 35) |
| **Q-D** | snapshot tarball | **ship** the deterministic `SOURCE_DATE_EPOCH` `.tgz` (FR-B7-6-010 IN) |
| **Q-E** | bundle regen | `npm run bundle` (gitignored, CI-fresh) |

**Resolution note (Q-B option b consequences)**: the new `harness-rust` job makes
`forge-ci.yml` grow to **7 jobs** (from 6: harness/gates/cli/lint/example/summary)
and pushes the line count past the current 340-line budget. Both cascades are
handled in lock-step at the flip phase (job-count assertions in g1/c1/specs/standard;
the size budget in g1/c1/t5-1/t5-otel-live-run + forge-ci.md + forge-self-ci.md).
