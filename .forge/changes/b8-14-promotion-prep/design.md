# Design: b8-14-promotion-prep

**Status**: designed → 2026-06-04 · **Constitution**: 1.1.0
**Architects**: Atlas (governance/infra), Eris (test strategy)
Prepare-only governance brick — applies nothing breaking.

---

## Architecture Decisions

### ADR-B814-001: Split B.8.14 into prepare (now) + flip (post-window)
**Context**: B.8.14 amends Constitution §VIII.1. `Article XII` + `GOVERNANCE.md
§"Amendment Process"` mandate a ≥7-day public discussion window before
ratification ("Closed-door amendments are not allowed"). A single-session
ratify+apply would violate the very process the constitution requires.
**Decision**: This brick performs **Amendment-Process step 1** (a Forge change
targeting `.forge/constitution.md`, opening the public window) and ships a
**staged bundle**; a **follow-up brick** (`b8-14-promotion-flip`, after the
window) performs steps 3–4 (ratify + apply + flip + remove). Maintainer
decision 2026-06-04: *prepare-only, hold the flip*.
**Consequences**: Zero breaking change this session; the constitution, the
2.0.0 schema, and the frozen templates are byte-unchanged.
**Constitution**: Article XII (honors the Amendment Process); constitution-is-law.

### ADR-B814-002: Stage the Kong/REST removal as a manifest, don't execute
**Context**: Maintainer chose *stage removal, don't execute*. Three live facts:
(a) removing Kong before VIII.1 ratifies = a violation, verbatim in
`2.0.0.yaml:17-31`; (b) the 2.0.0 subtree is an additive overlay with **no Kong**
to delete; (c) Kong lives only in the **byte-frozen** 1.0.0 base (b8-2).
**Decision**: Capture the removal as a declarative **`removal-manifest.yaml`** —
the exact 1.0.0-base paths/anchors (`infra/kong/`, `fsm-kong` service,
`FSM_KONG_ADMIN_PORT`, the `scaffold-plan.yaml` kong entry, REST routes) the 2.0.0
scaffold composition will exclude at flip. Nothing is deleted now; the follow-up
applies the manifest. Each enumerated target is verified to exist (anti-fabrication).
**Consequences**: No frozen-1.0.0 edit; no premature removal; the removal design
is review-able now and mechanically applied later.
**Constitution**: VIII.1 (Kong SHALL) stays satisfied — 1.0.0 keeps Kong; the
inert candidate is neither scaffolded nor deployed.

### ADR-B814-003: Negative held-state guards are the harness's load-bearing assertions
**Context**: The biggest risk of a prepare-only brick is that a later careless
edit silently lands the breaking flip without going through the follow-up's
ratification.
**Decision**: `b8-14.test.sh`'s primary tests are **negative**: constitution
still `v1.1.0` + §VIII.1 still "Kong SHALL"; Amendments table has no
gateway/Envoy row; `2.0.0.yaml` still `stage: candidate` + `scaffoldable: false`;
`fsm-kong` + `infra/kong/` still present; frozen snapshot sha intact. A premature
flip fails these → cannot merge green.
**Consequences**: The brick actively *prevents* an out-of-process flip, not just
documents intent.
**Constitution**: Article I (tests precede/guard); III (specs before code).

### ADR-B814-004: Amend VIII.1 only; MAJOR bump v1.1.0 → v2.0.0 (held)
**Context**: B8O retained Temporal (VIII.2 unchanged). VIII.1 Kong→Envoy is a
"breaking modification of an existing article" (VERSIONING MAJOR criterion).
**Decision**: The drafted amendment targets **§VIII.1 only**; declares the
target Constitution `Version` **v2.0.0** (MAJOR per the real `VERSIONING.md:15-17`
criterion — a new Envoy-SHALL §VIII.1 tightens a normative requirement existing
1.0.0 Kong projects would fail; the matching step-4 semver phrase is
`GOVERNANCE.md:124-125`). Pre-GA, the framework version stays on the `0.4.0` MINOR
line with a `### BREAKING` CHANGELOG note (per the pre-1.0 carve-out
`VERSIONING.md:70-73` — NOT the post-GA lockstep table at `:48-56`); the
framework MAJOR follows at GA. All held (not applied this brick).
**Consequences**: VIII.2 untouched; the amendment scope is minimal + auditable.
**Constitution**: VERSIONING coupling; Article XII.

### ADR-B814-005: Don't touch ARCHITECTURE-TARGET.md — record the t4 material-path for the follow-up
**Context**: B.8.13 established `ARCHITECTURE-TARGET.md` is sha256-pinned by
`t4.test.sh::_test_t4_023`; §11/§12.1 still describe the pre-amendment model.
**Decision**: This brick does **not** edit the arch doc (harness asserts its sha
unchanged via the t4 coupling guard). The flip-runbook records that the follow-up,
if it updates §11/§12.1, MUST take the **material-path** (rehash +
t4 re-ratification per the REHASH-LOG), not record-only.
**Consequences**: t4 stays green; the eventual in-place arch cleanup is tracked.
**Constitution**: III (no silent pinned-doc break).

---

## Component / artifact map

```
.forge/changes/b8-14-promotion-prep/
  amendment-viii-1.md     # staged §VIII.1 draft (Envoy SHALL) + Amendments row + v2.0.0
  removal-manifest.yaml   # exact 1.0.0-base Kong/REST targets (verified real)
  flip-runbook.md         # ordered post-window ratify→apply→flip→remove→deprecate steps
.forge/scripts/tests/b8-14.test.sh   # negative held-guards + positive staged-artifact checks
CHANGELOG.md (+entry) · forge-ci.yml (+registration)   # the only pre-existing files touched
```

## Testing strategy
- **L1 hermetic** (grep/diff/stat/shasum): negative guards (Group 4 FRs) +
  positive staged-artifact checks (Groups 1–3) + manifest-targets-are-real +
  CHANGELOG/CI + coupling (b8-13, t4, b8-3). RED-first: write the harness, confirm
  it fails before the staged artifacts exist, then author them to GREEN.
- **No L2** — nothing toolchain-dependent.
- **Full suite + verify.sh + constitution-linter** before flip
  (full-suite-before-push lesson); confirm `t4.test.sh` green (arch doc untouched).

## Standards applied
- None bumped (FR-B814-031). Documents existing GOVERNANCE Amendment Process,
  VERSIONING coupling, 2.0.0.yaml candidate, B.8.4 Envoy, B.8.6 Connect.

---

## Constitutional Compliance Gate
- **Article XII (Amendment Process)**: ✓ this brick is step 1 + opens the window;
  ratification/apply held for the follow-up (no closed-door amendment).
- **§VIII.1 (Kong SHALL) / §VIII.2 (Temporal SHALL)**: ✓ both remain in force,
  byte-unchanged; nothing scaffolded/deployed against the candidate.
- **Article I (TDD)**: ✓ harness RED-first.
- **Anti-fabrication (CLAUDE.md)**: ✓ amendment cites real GOVERNANCE steps +
  d5-governance; manifest targets verified to exist; no fabricated article/version.
- **t4 pin / frozen 1.0.0 / no standard·schema·scaffolder mutation**: ✓
  (FR-031/032 + t4 coupling).
- **No BLOCK conditions.** Design APPROVED for planning pending independent review.
