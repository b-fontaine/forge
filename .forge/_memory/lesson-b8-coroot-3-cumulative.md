# Lesson capture — 3 cumulative process drifts caught during b8-coroot-rehost (2026-05-24 → 2026-05-25)

> **Type** : process lesson (output `/forge:review` third pass, 2026-05-25)
> **Origin** : `b8-coroot-rehost` (pilot of `b8-observability-rearch` trio, B.8.8)
> **Author / Reviewer separation** : 3 successive review passes — each one caught
> a class of drift the previous had missed. Lessons stack.

## Lesson 1 — Verify-then-pin discipline applies at `/forge:implement` time, not at `/forge:explore` time

**What happened.** During `/forge:explore b8-observability-rearch`, two
`docker manifest inspect` background-task outputs were captured in parallel
(one for `ghcr.io/coroot/coroot:v1.20.2`, one for the unprefixed form). The
outputs were **mis-labelled at synthesis time** — the author read the OCI
multi-arch index as the v-prefix output and the `manifest unknown` as the
unprefixed output. The mis-read propagated through `proposal.md` → `specs.md`
→ `design.md::ADR-B8-COR-001` → `tasks.md` → CHANGELOG / REVIEW / plan §0.7 /
roadmap T6, asserting "v-prefix mandatory per GHCR" everywhere as a
verified fact.

**How it was caught.** Phase 6 of `/forge:implement` ran the L2 manifest-pull
fixture (FR-B8-COR-072) for the first time. The fixture **failed against
`v1.20.2`** ("manifest unknown") and **passed against `1.20.2`**, exposing
the inversion. The L2 fixture's `--config` flag check per ADR-B8-COR-003 was
the verify-then-pin invariant doing its job.

**Why the early evidence was wrong.** The `/forge:explore` synthesis step
combined background-task results from memory without re-checking the
correspondence between command and output. The mental model was set
before the evidence was authoritatively re-confirmed.

**Rule.** **Verify-then-pin assertions made at `/forge:explore` time MUST
be re-asserted at `/forge:implement` time via an automated L2 fixture
that exercises the assertion as a runtime check** — `grep` of the pin
string in the standard or template is NOT sufficient ; a live `docker
manifest inspect` (or equivalent) must run. The L2 fixture is the
verify-then-pin authoritative surface, not the proposal narrative.

**Standards-lifecycle implication.** A future `standards-lifecycle.md`
v1.2.0 (or new sub-section) MAY codify : "any standard frontmatter that
declares an external image / package / artefact MUST have an L2 fixture
in some harness exercising the pin against the upstream registry, gated
by an opt-in env-var."

## Lesson 2 — Constitution-linter Article III.4 must re-run POST `status: planned → implemented` flip, not pre-flip

**What happened.** `/forge:implement` Phase 6 ran `verify.sh` and
`constitution-linter.sh` to check the change passed all gates, then
flipped `status: planned → implemented` via the `.forge.yaml` Edit. The
ordering was **pre-flip verification → post-flip status update**.

**Article III.4's hidden conditional.** The Article III.4 rule (`f4-linter-extension`)
only fires on changes in `status: implemented` or `archived`. While the
change was at `status: planned`, the linter excluded it from the scan
and reported PASS. The 3 `[NEEDS CLARIFICATION:]` markers in
`proposal.md::## Open Questions` (lines 230, 240, 251) survived the
Phase 6 check undetected.

**How it was caught.** Maintainer ran `task validate` after the archive-
readiness review was already complete and signed off. `task validate`
re-ran constitution-linter.sh, which this time saw `status: implemented`
and fired the rule → 3 FAIL.

**The reviewer also missed it.** The independent code-reviewer agent ran
its first pass on the change content but trusted the author's Phase 6
gate transcript without re-running `constitution-linter.sh` in its own
context post-flip. The reviewer caught 6 issues (CRITICAL/HIGH/MEDIUM/LOW)
but not this one.

**Rule.** **The author MUST re-run `verify.sh` + `constitution-linter.sh`
+ all change-specific harnesses AFTER the `status: planned → implemented`
status flip, not before.** The pre-flip run is a sanity check ; the
post-flip run is the authoritative gate. The `.forge.yaml` status flip
materially changes what some rules cover.

**Process implication.** `/forge:implement` Phase 6 should be split into
two sub-phases :
- **Phase 6a** (pre-flip) — sanity gate, may report PASS with hidden
  conditional rules silently excluded.
- **Phase 6b** (post-flip) — authoritative gate, runs the **same**
  scripts a second time to assert no new violations emerged from the
  status transition.

The `/forge:implement` skill MAY ratify this split explicitly in its
contract.

## Lesson 3 — Reviewer independence requires re-running gates in own context, not trusting author transcripts

**What happened.** The independent code-reviewer agent (spawned via
`oh-my-claudecode:code-reviewer`) was briefed with the author's Phase 6
verification transcript. On both its first review pass (6 findings) and
its remediation re-pass (all 6 resolved), the reviewer **trusted the
author's gate output verbatim** instead of re-running the gates in its
own session context.

**Why this matters.** The author's Phase 6 transcript was generated
**pre-flip**, before Article III.4 fired. The reviewer had read-only
tool access and could have spent <30 s running
`bash .forge/scripts/constitution-linter.sh` itself ; it didn't, because
the author's transcript appeared comprehensive. This is exactly the
"Author/Reviewer separation must be operational, not declarative" lesson
already captured in T5.2 self-validation memory — but here the lesson
gets a new sub-rule.

**Rule.** **An independent reviewer MUST re-execute every gate from its
own session context, not import the author's transcript.** The brief
the author hands the reviewer is one input ; the gate transcripts are
another input ; but the reviewer's own re-run is the only authoritative
input the reviewer can rely on. Trust but verify.

**Forge skill implication.** `/forge:review` SHOULD include an explicit
instruction to the reviewer agent : "Re-run `verify.sh` +
`constitution-linter.sh` + the change-specific harness in your own
session context. Do not accept the author's transcripts as gate
evidence. Report any discrepancy between your re-run and the author's
report as a finding (probable cause : pre-flip-vs-post-flip drift)."

## Cross-reference

- Sibling auto-memory entry : `~/.claude/projects/-Users-bfontaine-git-github-forge/memory/b8_coroot_inversion_lessons.md`
- Existing precedent on Author/Reviewer separation : `t5_2_self_validation_lesson` (auto-memory) — Article VIII fabricated citation caught by independent reviewer pre-archive.
- Existing precedent on cascade drift : `t5_connect_codegen_lesson` (auto-memory) — 7 layers of latent bugs from grep-only ratification without build.
- This change : `.forge/changes/b8-coroot-rehost/` — pilot of `b8-observability-rearch` trio (B.8.8 of `docs/new-archetypes-plan.md` §4.2).

## Adoption candidates (deferred — out of scope for b8-coroot-rehost)

1. **`standards-lifecycle.md` v1.2.0** — codify Lesson 1 (L2 fixture
   mandatory for external pins).
2. **`/forge:implement` skill contract** — codify Lesson 2 (pre-flip vs
   post-flip gate split).
3. **`/forge:review` skill contract** — codify Lesson 3 (reviewer MUST
   re-run, not trust transcript).
4. **`global/forge-self-ci.md` subsection** — add "post-flip gate"
   subsection citing Lesson 2 + 3.

Each adoption is a candidate for a future small change (probably part
of `t5-2-platform-verification` v1.2.0 or a sub-change of the trio
sibling work). Pattern : codify after recurrence is observed in two or
more changes ; b8-coroot-rehost is the first observation, b8-signoz-
unified or b8-obi-refresh may trigger the second.

## Three lessons in one sentence

**Verify-then-pin must run live at impl-time, gate transcripts must be
post-flip, reviewers must re-execute — anything else is theater.**
