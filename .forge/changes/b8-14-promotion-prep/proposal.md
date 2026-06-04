# Proposal: b8-14-promotion-prep

**Audit item**: B.8.14 (docs/new-archetypes-plan.md §4.2, lines 2355-2357)
**Effort**: S (this prepare brick) · **Status**: proposed → 2026-06-04
**Type**: governance prep — staged artifacts + L1 harness. **Applies NOTHING
breaking** (no constitution edit, no schema flip, no Kong removal).

## Why

B.8.14 is the **point of no return**: promote the flagship to 2.0.0 (Envoy /
Connect / Zitadel / Qwik / pg17, Kong & REST-bridge removed) and amend
Constitution §VIII.1 (Kong SHALL → Envoy). But that amendment is **process-gated**.

`Article XII` + `GOVERNANCE.md §"Amendment Process"` (steps 1–4) require, in order:
1. a Forge change targeting `.forge/constitution.md` (**this brick**);
2. a **≥ 7-day public discussion window** ("Closed-door amendments are not
   allowed");
3. BDFL ratification;
4. apply (Amendments-table row + Version bump + downstream `change.yaml` /
   archetype `.forge.yaml.tmpl`).

The 2.0.0 schema header says this verbatim (`.forge/schemas/full-stack-monorepo/2.0.0.yaml:17-31`):

> *Both SHALL clauses remain binding until B.8.14 completes the GOVERNANCE.md
> Amendment Process (7-day window, ## Amendments table). Scaffolding or deploying
> this candidate before that amendment would constitute a constitutional
> violation.*

So the breaking work **cannot** land in one session without violating the
constitution it amends. **Maintainer decisions (2026-06-04):** *prepare-only,
hold the flip* + *stage the removal, don't execute it*. This brick therefore
ships the **prepare bundle** (step 1 + staged artifacts); a follow-up brick
performs steps 3–4 after the window closes.

## Scope reality (Ground-Truth)

- **VIII.2 (Temporal) is NOT amended** — B8O retained Temporal. Only **VIII.1**
  (gateway) changes.
- **There is no Kong in the 2.0.0 subtree** — it is an additive overlay
  (`find 2.0.0/ -iname "*kong*"` = 0). Kong lives only in the **frozen 1.0.0
  base** (`docker-compose.dev.yml` `fsm-kong`, `infra/kong/`, `.env`
  `FSM_KONG_ADMIN_PORT`, `scaffold-plan.yaml:156-157`). 1.0.0 is byte-frozen
  (b8-2). So removal is neither a delete-from-2.0.0 nor a frozen-1.0.0 edit — it
  is captured as a **staged removal manifest** the follow-up applies to the 2.0.0
  scaffold composition.
- The VIII.1 amendment is a **MAJOR** constitution change — per the real
  `VERSIONING.md:15-17` MAJOR criterion ("the Constitution is amended in a way
  that breaks compatibility… its normative requirements are tightened in a way
  that existing projects would fail to satisfy": existing 1.0.0 Kong projects
  would fail a new Envoy-SHALL §VIII.1) → `v1.1.0 → v2.0.0` (held). (`GOVERNANCE.md:124-125`
  gives the matching step-4 semver guidance — "major for removal or breaking
  modification of an existing article".)

## What ships (this brick — all inert)

1. **Drafted VIII.1 amendment** — `amendment-viii-1.md` in the change dir: the
   proposed new §VIII.1 text (Envoy Gateway SHALL replace Kong; Connect-RPC
   replaces gateway REST↔gRPC transcoding), motivation, impact on existing 1.0.0
   projects, the exact `## Amendments`-table row to add, and the `Version`
   bump `v1.1.0 → v2.0.0`. **Not applied** to `.forge/constitution.md`. This file
   + this change *are* step 1 of the Amendment Process and open the public
   discussion window.
2. **Staged removal manifest** — `removal-manifest.yaml`: enumerates the exact
   1.0.0-base Kong/REST paths/anchors the 2.0.0 scaffold composition will exclude
   at flip (`infra/kong/`, `fsm-kong` compose service, `FSM_KONG_ADMIN_PORT`,
   scaffold-plan kong entry, REST routes). Each enumerated target is verified to
   currently exist (no fabricated paths). **Not executed.**
3. **Flip / ratification runbook** — `flip-runbook.md`: the ordered post-window
   follow-up (close discussion → ratify → apply amendment [Amendments row +
   `v2.0.0` + `change.yaml` + archetype `.forge.yaml.tmpl`] → flip `2.0.0.yaml`
   `stage: stable` + `scaffoldable: true` → execute removal manifest in the 2.0.0
   composition → land the deferred B.8.3.b scaffolder versioned-selection guard →
   activate 1.0.0 deprecation). Notes the t4 material-path if it touches
   `ARCHITECTURE-TARGET.md` (B.8.13 lesson).
4. **1.0.0 deprecation announcement (draft)** — staged text for `CHANGELOG.md` +
   the `VERSIONING.md`/`GOVERNANCE.md` support policy (T+6-month window),
   activating on flip.
5. **`.forge/scripts/tests/b8-14.test.sh`** — L1 hermetic harness whose KEY
   assertions are **NEGATIVE held-state guards**: constitution still `v1.1.0` +
   §VIII.1 still "Kong SHALL"; no gateway/Envoy row in the Amendments table;
   `2.0.0.yaml` still `scaffoldable: false` + `stage: candidate`; frozen 1.0.0
   snapshot byte-unchanged + `fsm-kong` + `infra/kong/` still present (removal NOT
   executed). **Positive**: the four staged artifacts exist + are well-formed +
   the manifest's targets are real. Plus CHANGELOG/CI + coupling (b8-13, t4, b8-3).
6. **`.github/workflows/forge-ci.yml`** — register `b8-14.test.sh --level 1`.

## Out of scope (the follow-up flip brick owns these)

- Editing `.forge/constitution.md` (§VIII.1 text, Amendments table, Version).
- Flipping `2.0.0.yaml` `stage`/`scaffoldable`.
- Removing Kong/REST (executing the manifest); scaffolder versioned-selection +
  the B.8.3.b guard; activating the 1.0.0 deprecation.
- Any `forge upgrade` matrix test (that is **B.8.15**).
- Editing `ARCHITECTURE-TARGET.md` (t4-pinned; material-path deferred).

## Risks

| Risk | Mitigation |
|------|------------|
| The flip leaks in prematurely (constitution edited / 2.0.0 flipped before the window) | The harness's **negative guards** fail if constitution ≠ v1.1.0, VIII.1 ≠ Kong SHALL, 2.0.0 ≠ scaffoldable:false, or Kong is removed — making a premature flip impossible to merge green. |
| Removal manifest fabricates paths | Harness asserts every enumerated target currently exists in the 1.0.0 base. |
| Fabricated amendment/constitutional citation | Amendment draft cites the real GOVERNANCE Amendment Process steps + d5-governance precedent; independent review re-verifies VIII.1 text + GOVERNANCE steps live (t5.2 lesson). |
| Scope creep into the flip | constitution_version stays 1.1.0; no standard/schema mutation; asserted by harness + git-diff review. |
