# Open Questions: t5-2-platform-verification
<!-- Created: 2026-05-17 -->
<!-- Audit: T5.2 (docs/new-archetypes-plan.md §0.2) -->

Questions raised during `/forge:propose`. All MUST be resolved
(status `answered` or `wontfix`) before `/forge:plan` runs, per
`verify.sh` Open Questions Gate (Article III.4 /
`global/open-questions.md`).

---

## Q-001 — Override-vs-extend strategy for the OMC `document-specialist` agent

**Status** : answered (ADR-T52-001)

**Raised by** : proposal.md § Solution + § Scope In

**Question** : the `document-specialist` agent referenced in
`docs/new-archetypes-plan.md` §0.2 line 764-766 lives at
`~/.claude/plugins/cache/omc/oh-my-claudecode/4.13.5/agents/document-specialist.md`
— it is an **OMC plugin asset**, not a file in the Forge repo.
The plan instructs « Mettre à jour `.claude/agents/document-specialist.md` »
but this path does not exist in the Forge tree today (compare
`ls .claude/agents/` : no `document-specialist.md` — only
`demeter.md`, `spec-writer.md`, `forge-master.md`, etc.).

Three options on the table :

- **A. Create a Forge-local extension at `.claude/agents/document-specialist.md`
  (proposed)** — a thin Forge-owned agent file that
  scopes the OMC behaviour with the 3-axis checklist. Precedent :
  `demeter.md` in this same directory is a Forge-owned persona, not
  an OMC plugin asset. Pro : keeps the checklist auditable in the
  Forge repo ; survives OMC upgrades ; reviewers can grep
  `.claude/agents/` for the procedure. Con : two `document-specialist`
  files exist at runtime (OMC default + Forge override) ; OMC's
  agent-resolution precedence must be confirmed.
- **B. Codify the checklist in a Forge standard, not in an agent
  file** — add a new H2 to an existing `.forge/standards/global/`
  standard (e.g. `standards-lifecycle.md`) or ship a new
  `global/external-dependency-ratification.md` standard. Pro :
  auditable as a Forge standard with REVIEW.md ledger ; survives
  OMC removal ; constitution-linter can later enforce it. Con :
  the OMC `document-specialist` agent itself does not read
  `.forge/standards/` automatically — adopters must wire the
  checklist into their workflow manually.
- **C. Upstream PR to OMC** — submit the checklist as an upstream
  change to `oh-my-claudecode/agents/document-specialist.md`. Pro :
  benefits every OMC user, not just Forge. Con : OMC upgrade cadence
  is external ; benefits only land once accepted + released ; Forge
  cannot guarantee adopters run the new OMC version ; high coupling
  to external maintainers.

**Affects** : FR-T52-A-* (checklist deliverable), NFR-T52-001
(auditability), test surface of `t5-2.test.sh`.

**Likely resolution** : **Option A + Option B combined**, in that
order. Ship a Forge-local `.claude/agents/document-specialist.md`
that names the checklist as the procedure (A) AND embed the
checklist verbatim inside the `standards-lifecycle.md` v1.1.0 bump
that the proposal already ships (B). This gives two reinforcing
surfaces : adopters running OMC + Forge see the checklist
referenced in the agent ; auditors reviewing the standards index
see it codified in the standard. Option C deferred — only worth
filing once T5.2 has produced a stable, battle-tested checklist.

**Resolution** (2026-05-17, `design.md::ADR-T52-001`) : **Option A
+ Option B combined, Option C deferred**. The Forge-local agent
file at `.claude/agents/document-specialist.md` carries the
canonical procedural surface (H2 `## Platform Verification
Checklist (3-axis)`) — body of the checklist. The
`standards-lifecycle.md` v1.1.0 bump carries the
**re-verification cadence** rules (H2
`## Platform compatibility re-verification`) and a bidirectional
cross-reference to the agent file. Drift between the two
surfaces is prevented by ADR-T52-003 (verbatim H2 cross-referencing
enforced by the harness L1 assertions FR-T52-D-004..010). OMC
agent-resolution precedence verified empirically via the K.3
Demeter persona precedent : `.claude/` project-level files
beat plugin cache files without warnings. Option C (upstream
OMC PR) deferred to post-T5.3 once the checklist is
battle-tested.

---

## Q-002 — Scope of L2 opt-in sanity-check live-run (`FORGE_T52_LIVE=1`)

**Status** : answered (ADR-T52-002)

**Raised by** : proposal.md § Scope In (harness L2)

**Question** : the harness `t5-2.test.sh` is mostly L1 grep
assertions. The proposal mentions one L2 opt-in
(`FORGE_T52_LIVE=1`) that "exécute la checklist sur un pkg pub.dev
arbitraire (sanity check de l'outillage Context7 + WebFetch)".

What exactly does the live-run verify ?

- **A. Tooling smoke (proposed)** — pick one well-known stable
  package (e.g. `flutter_bloc` on pub.dev, declared `flutter`
  platform) and assert that `mcp__context7__query-docs` returns
  a non-empty response AND that a `WebFetch` against the pub.dev
  page returns the expected `Platforms` chip. Validates that the
  tooling required for the checklist exists and responds. Does
  not validate any actual standard. Wall-clock ≤ 10 s.
- **B. Re-ratification of a shipped standard** — apply the
  3-axis checklist to one of the already-shipped Forge standards
  (e.g. the legacy `flutter/opentelemetry.md` v1.1.0 still in tree)
  and assert that Q-006 would now be caught. This validates the
  checklist itself, not just the tooling. Wall-clock ≤ 30 s.
  Risk : creates flakes if pub.dev rate-limits or if Context7
  caches go stale.
- **C. No live-run at all** — skip the L2 layer entirely. The L1
  grep assertions cover the deliverables ; live behaviour is
  T5.3's burden (it will tick the checklist for real on Dartastic).
  Pro : zero flake surface. Con : the harness ships dark — no
  evidence the tooling chain works end-to-end.

**Affects** : NFR-T52-002 (CI wall-clock budget), flake rate,
ratification confidence.

**Likely resolution** : **Option A**. Tooling smoke gives a
positive signal that Context7 + WebFetch are still reachable
without overloading the harness with re-ratification logic. Skip-pass
if either tool returns a transport error (mirrors the network-isolation
pattern from `t5-otel-live-run`). The L2 leg stays opt-in via
env-var.

**Resolution** (2026-05-17, `design.md::ADR-T52-002`) : **Option A
— pub.dev tooling smoke on `flutter_bloc`**. The L2 test fetches
`https://pub.dev/packages/flutter_bloc` with `curl --max-time 10`,
asserts the response is 2xx, and greps the HTML body for the
literal substring `Platforms` plus at least one platform token
(`Android` / `iOS` / `Linux` / `macOS` / `Web` / `Windows`).
Skip-pass on network unreachability mirrors
`t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1` precedent. Target
package `flutter_bloc` was chosen because (a) it is already
ratified as the canonical Flutter state-management dependency by
`.forge/standards/state-management.yaml`, so any change to its
pub.dev presence is something Forge wants to detect anyway, and
(b) it is a verified-publisher package supporting all six
Flutter platforms, providing a stable smoke target. Wall-clock
budget NFR-T52-002 preserved (≤ 10 s for L2, ≤ 5 s for L1).
