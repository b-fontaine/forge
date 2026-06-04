# Specs: b8-14-promotion-prep

**Audit item**: B.8.14 · **Effort**: S · **Status**: specified → 2026-06-04
**Constitution**: 1.1.0 · **Type**: governance prep (staged artifacts + L1 harness)

> Prepare-only brick. Every FR is grep/diff/shasum-checkable hermetically.
> The harness's load-bearing assertions are **negative held-state guards** —
> they prove the breaking flip was NOT applied. No `[NEEDS CLARIFICATION]`.

---

## Anti-hallucination pass (CLAUDE.md ANTI-HALLUCINATION PROTOCOL)

| Claim | Ground truth (verified live) |
|-------|------------------------------|
| §VIII.1 mandates Kong | `.forge/constitution.md:308` "Kong SHALL be used as the API gateway…" ✓ |
| §VIII.2 (Temporal) needs no amendment | B8O retained Temporal; orchestration.yaml v1.2.0 ✓ |
| Constitution is v1.1.0 | `.forge/constitution.md:3` "**Version**: v1.1.0" ✓ |
| Amendment requires ≥7-day public window + 4 steps | `GOVERNANCE.md:105-130` ✓ ; constitution:449-450 ✓ |
| Removing Kong before ratification = violation | `2.0.0.yaml:17-31` (verbatim) ✓ |
| 2.0.0 is candidate / not scaffoldable | `2.0.0.yaml:44-46` `stage: candidate` / `scaffoldable: false` ✓ |
| No Kong in 2.0.0 subtree | `find 2.0.0/ -iname "*kong*"` = 0 ✓ |
| Kong in 1.0.0 base | `docker-compose.dev.yml:92` `fsm-kong`; `infra/kong/kong.yml.example.tmpl`; `.env:18` `FSM_KONG_ADMIN_PORT`; `scaffold-plan.yaml:156-157` ✓ |
| MAJOR bump for breaking article change | `VERSIONING.md:13-17` ✓ → v1.1.0→v2.0.0 |
| Amendment-Process precedent | `d5-governance` (→1.1.0), GOVERNANCE.md:129-130 ✓ |
| Kong standard exists (removal target) | `.forge/standards/infra/kong.md` (in b8-2 frozen snapshot) ✓ |

---

## ADDED Requirements

### Group 1 — Drafted VIII.1 amendment (staged, NOT applied)

#### FR-B814-001: Amendment draft exists
`.forge/changes/b8-14-promotion-prep/amendment-viii-1.md` MUST exist, audit-stamped
B.8.14, presenting the proposed §VIII.1 replacement (Envoy Gateway SHALL; gateway
REST↔gRPC transcoding replaced by Connect-RPC), the motivation, the impact on
existing 1.0.0 (Kong) projects, the exact `## Amendments`-table row to add, and
the target Constitution `Version` bump **v1.1.0 → v2.0.0**.

#### FR-B814-002: Amendment cites the real process
The draft MUST cite the `GOVERNANCE.md §"Amendment Process"` steps (Forge change →
≥7-day public window → BDFL ratification → apply) and the `d5-governance`
precedent. It MUST NOT invent an article number or process.

#### FR-B814-003: Amendment is NOT applied
`.forge/constitution.md` MUST be byte-unchanged: still `**Version**: v1.1.0`;
§VIII.1 still contains "Kong SHALL be used as the API gateway"; the `## Amendments`
table MUST NOT contain a gateway/Envoy/VIII.1 row.

### Group 2 — Staged removal manifest (NOT executed)

#### FR-B814-010: Removal manifest exists + enumerates real targets
`.forge/changes/b8-14-promotion-prep/removal-manifest.yaml` MUST exist and
enumerate the Kong/REST removal targets: at minimum the template
`infra/kong/` dir, the `fsm-kong` compose service, `FSM_KONG_ADMIN_PORT`, the
`scaffold-plan.yaml` kong entry, the REST-bridge route anchors in
`infra/kong/kong.yml.example.tmpl`, AND the live framework standard
`.forge/standards/infra/kong.md` (superseded by B.8.4's `gateway.yaml`). Each
MUST be a path/anchor that currently exists. The manifest MUST distinguish
**scaffold-composition targets** (excluded from a 2.0.0 scaffold) from the
**framework-standard target** (`kong.md`, removed/superseded at flip).

#### FR-B814-011: Removal NOT executed (targets intact)
All removal targets MUST still be present (nothing removed this brick):
`fsm-kong` still in `docker-compose.dev.yml.tmpl`;
`infra/kong/kong.yml.example.tmpl` still present; the live standard
`.forge/standards/infra/kong.md` still present; the frozen 1.0.0 snapshot sha
(b8-2) MUST match its `.sha256`.

### Group 3 — Flip runbook + deprecation draft (staged)

#### FR-B814-020: Flip / ratification runbook exists
`.forge/changes/b8-14-promotion-prep/flip-runbook.md` MUST exist with the ordered
post-window steps: ratify → apply amendment (Amendments row + `v2.0.0` +
`change.yaml` + archetype `.forge.yaml.tmpl`) → flip `2.0.0.yaml` `stage: stable` +
`scaffoldable: true` → execute the removal manifest in the 2.0.0 composition →
land the B.8.3.b scaffolder versioned-selection guard → activate 1.0.0 deprecation.
It MUST note the t4 material-path if `ARCHITECTURE-TARGET.md` is touched.

#### FR-B814-021: 1.0.0 deprecation announcement draft
The brick MUST stage the 1.0.0 deprecation announcement (T+6-month window) as a
draft (in the runbook or a dedicated section) destined for `CHANGELOG.md` +
the `VERSIONING.md`/`GOVERNANCE.md` support policy — NOT yet activated.

### Group 4 — Held-state guards (negative; the load-bearing safety)

#### FR-B814-030: 2.0.0 schema NOT promoted
`.forge/schemas/full-stack-monorepo/2.0.0.yaml` MUST still be `stage: candidate`
and `scaffoldable: false`.

#### FR-B814-031: No standard / schema / scaffolder mutation
No file under `.forge/standards/`, no schema version change, and no
`cli/src/**`/`.forge/scripts/scaffolder/**` behavioral change may land in this
brick. `constitution_version` stays `1.1.0`.

#### FR-B814-032: Frozen 1.0.0 + 2.0.0 overlay byte-identity
No `.forge/templates/archetypes/full-stack-monorepo/` file (1.0.0 base or 2.0.0
overlay) and no snapshot/`.sha256` may change (b8-2 guard).

### Group 5 — Harness + CI

#### FR-B814-040: forge-ci registration
`.github/workflows/forge-ci.yml` MUST register `b8-14.test.sh --level 1`.

#### FR-B814-041: CHANGELOG anchor
`CHANGELOG.md` MUST carry a `b8-14` / B.8.14 `[Unreleased]` entry (whole-file
grep anchor) describing the **prepare-only** scope (no breaking change applied).

#### FR-B814-042: Coupling guards
`b8-14.test.sh` MUST re-run, by exit code, the siblings whose subjects it depends
on/guards: at minimum `b8-13`, `t4` (arch-doc pin), and `b8-3` (2.0.0 candidate).

---

## Non-functional requirements

- **NFR-001**: L1 hermetic (grep/diff/stat/shasum), no toolchain, ≤ a few seconds.
- **NFR-002**: Every FR individually grep/diff/shasum-checkable.
- **NFR-003**: Applies NOTHING breaking — the only mutated pre-existing files are
  `CHANGELOG.md` + `.github/workflows/forge-ci.yml`; everything else is new (the
  change dir's staged artifacts + `b8-14.test.sh`).
- **NFR-004**: No fabricated external version/API/article.

---

## BDD acceptance criteria

```gherkin
Feature: B.8.14 promotion prepare-only bundle

  Scenario: The breaking flip is held, not applied
    Given the VIII.1 amendment requires a 7-day public discussion window
    When the b8-14 prepare bundle lands
    Then .forge/constitution.md is still v1.1.0 with "Kong SHALL" in §VIII.1
    And the Amendments table has no gateway/Envoy row
    And 2.0.0.yaml is still stage: candidate / scaffoldable: false
    And fsm-kong + infra/kong/ are still present in the 1.0.0 base

  Scenario: The amendment and removal are staged, ready to apply
    Given the maintainer chose prepare-only + stage-removal-don't-execute
    When the staged artifacts are read
    Then amendment-viii-1.md proposes Envoy SHALL + target Version v2.0.0
    And removal-manifest.yaml enumerates real 1.0.0 Kong/REST targets
    And flip-runbook.md lists the ordered post-window ratify+apply+flip steps
    And the 1.0.0 deprecation announcement is drafted but not activated

  Scenario: A premature flip cannot merge green
    Given the harness encodes negative held-state guards
    When someone edits the constitution or flips 2.0.0 scaffoldable before the window
    Then b8-14.test.sh fails (the guard catches the premature breaking change)
```
