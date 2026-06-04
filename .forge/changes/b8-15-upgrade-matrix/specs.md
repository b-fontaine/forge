# Specs: b8-15-upgrade-matrix

**Audit item**: B.8.15 · **Effort**: M · **Status**: specified → 2026-06-04
**Constitution**: 1.1.0 · **Type**: E2E upgrade-matrix harness + CI registration

> T5.1 Layer D — the v0.4.0-stable publish gate. Every FR is verifiable by the
> hermetic harness (git/python3/tar, no cargo/flutter/docker). No
> `[NEEDS CLARIFICATION]` — driver + scope resolved by ADR-B815-001 + the
> `wf_3b8aeb15` grounding workflow.

---

## Anti-hallucination pass (CLAUDE.md ANTI-HALLUCINATION PROTOCOL)

| Claim | Ground truth (verified live) |
|-------|------------------------------|
| exit-7 + `[NEEDS MIGRATION: from X to Y]` marker | `forge-upgrade.sh:128-142` `_a7_check_version_compat`; `a7.test.sh:451-470` |
| same-major upgrades proceed | `a7.test.sh` `test_minor_patch_bumps_proceed` |
| `.merge-conflicts` = `[CONFLICT] <relpath>` + cleanup | `forge-upgrade.sh:96-102, 342-345` |
| `upgrade_history` in scaffold-manifest.yaml, append-only | `forge-upgrade.sh:144-187`; `a7.test.sh` append-only test |
| migrate-flagship bypasses version guard, 1.0.0→2.0.0 | `forge-migrate-flagship.sh:54-57` (no `_a7_check_version_compat`), ledger `:322-324` + `kind:` `:347` |
| flagship PROJECT base = c1 example (not the framework tarball) | `examples/forge-fsm-example/` (scaffolded 1.0.0 project; has `docker-compose.dev.yml`/`fsm-kong`); b8-12 copied it to tmpdir. `1.0.0.tar.gz` = migrate's internal merge BASE only (extracting it yields the framework repo, NO project files) |
| no 2.0.0 tarball; RIGHT = live 2.0.0 template-set dir | snapshot `1.0.0.tar.gz` only; `TPL_20` dir present |
| front-door resolves only schema.yaml = 1.0.0 (2.0.0 flip-gated) | `cli/src/commands/upgrade.ts` resolveFrameworkVersion; `2.0.0.yaml` candidate/false; `b8-14.test.sh _test_b814_003` |
| smoke fixture matrix (required/forbidden paths) | `cli/test/e2e/archetype-fixtures/full-stack-monorepo.yml`; `cli/test/e2e/archetypes-smoke.test.ts` (fresh-scaffold-only → re-implement standalone) |
| CI has no GA matrix; hand-rolled array | `forge-ci.yml:68-121` |

No `[NEEDS CLARIFICATION]` markers.

---

## ADDED Requirements

### Group 0 — harness hermeticity
#### FR-B815-001: Hermetic harness + git identity
`.forge/scripts/tests/b8-15.test.sh` MUST be L1-hermetic (git/python3/tar only,
no cargo/flutter/docker), audit-stamped B.8.15, and MUST export
`GIT_AUTHOR_*`/`GIT_COMMITTER_*` at the top (the fixtures `git init`+`commit`
tmpdir projects; CI runners lack identity — b8-12 lesson).

### Group 1 — negative governance path
#### FR-B815-010: Major-bump abort
A cell MUST scaffold/synthesize a 1.x.y baseline project and invoke
`forge-upgrade.sh --to-version 2.0.0` (front door), asserting **exit 7** and a
literal stderr marker `[NEEDS MIGRATION: from <1.x.y> to 2.0.0]`.

#### FR-B815-011: `--force` on a dirty git tree refused (same-major target)
A cell MUST assert `--force` on a baseline whose git working tree is dirty is
**refused** (exit 7). The target MUST be **same-major** (e.g. 1.0.0→1.0.1) so the
exit-7 is attributable to the force-clean gate, NOT the version-compat guard
(which runs first, `forge-upgrade.sh:272` before `:273-275`). The cell MUST
assert the dirty-git stderr message (`forge-upgrade.sh:117`), not just the code.

### Group 2 — same-major positive upgrades (a7-authoritative, coupling-backed)
> `a7.test.sh` is the authoritative harness that scaffolds same-major fixtures and
> exercises the 3-way merge + manifest bump end-to-end. B.8.15 does NOT duplicate
> a7's fixture scaffolding; it gates these invariants via the **a7 coupling guard**
> (FR-B815-062) and directly implements only the genuinely-new matrix cells (the
> cross-major negative cell + the flagship-on-c1 cell).

#### FR-B815-020: Same-major upgrades proceed (via a7 coupling)
The same-major 1.0.0→1.0.1 / 1.0.0→1.1.0 proceed-and-merge invariant MUST be gated
by re-running `a7.test.sh` (FR-B815-062, which exercises
`test_minor_patch_bumps_proceed` + the merge/history e2e). B.8.15 MUST NOT
re-implement a7's framework-version fixtures.

#### FR-B815-021: Manifest bump (via a7 coupling)
The `archetype_version` bump after a successful upgrade is gated by the a7 coupling
(a7's history-append e2e asserts the canonical-field mutation).

### Group 3 — ledger + conflicts invariants (a7-authoritative, coupling-backed)
#### FR-B815-030: upgrade_history shape + append-only (a7 coupling) + flagship entry (direct, L2)
The GENERIC `upgrade_history` shape
(`date`/`from_version`/`to_version`/`from_template_set_sha`/`to_template_set_sha`/
`counts{unchanged,upgraded,preserved,conflicted,skipped}`/`cli_version`) +
append-only invariant is gated by the **a7 coupling** (a7 asserts it on its
fixtures). B.8.15 DIRECTLY asserts (L2, on the c1 overlay) that the **flagship**
entry exists with `from_version: 1.0.0` / `to_version: 2.0.0` and the ADDITIONAL
`kind: flagship-migration` field (`forge-migrate-flagship.sh:347`); the assertion
tolerates the live `cli_version` ("dev") + ISO date and greps the whole manifest.

#### FR-B815-031: `.merge-conflicts` format + cleanup (a7 coupling)
The `[CONFLICT] <relpath>` format + zero-conflict cleanup invariant is gated by the
a7 coupling (`forge-upgrade.sh:96-102, 342-345`; a7 exercises it). B.8.15 does not
re-scaffold a conflicting fixture.

### Group 4 — positive flagship 1.0.0 → 2.0.0 (via migrate-flagship)

> **PROJECT BASE = the c1 example, NOT the framework tarball.** Extracting
> `1.0.0.tar.gz` yields the framework repo (`.forge/`, `bin/`, …) — it has NO
> `backend/`/`docker-compose.dev.yml`/`fsm-kong`/`scaffold-manifest.yaml`. The
> migrate target is a **scaffolded project**, so the flagship cell copies
> `examples/forge-fsm-example/` (the committed scaffolded 1.0.0 full-stack-monorepo
> project — exactly the b8-12 precedent) to a tmpdir, git-init+commits it, and runs
> `migrate-flagship --target` there. (`1.0.0.tar.gz` is migrate-flagship's
> INTERNAL 3-way-merge BASE, consumed by the script, not the project base.)

#### FR-B815-040: Flagship migration plan + ledger
**L1**: a cell MUST run `bin/forge-migrate-flagship.sh --target <c1-copy> --dry-run`
and assert it targets **1.0.0→2.0.0** + the dry-run plan is emitted + the c1 copy
is **unmutated** (dry-run is no-op). **L2** (`FORGE_B8_15_LIVE`): the real overlay
MUST write an `upgrade_history` entry from=1.0.0/to=2.0.0 with `kind:
flagship-migration` (FR-B815-030 shape). The dry-run counts are estimates, NOT the
real-run counts (do not cross-assert them).

#### FR-B815-041: Additive invariant (removal is flip-gated)
The migrate-flagship overlay MUST be **additive** — it has no delete path. **L1**:
a static guard MUST assert `bin/forge-migrate-flagship.sh` contains no
`rm`/`rmdir`/delete operating on Kong/REST/Temporal tokens (mirrors/​re-runs
b8-10's additive-only static guard; also covered transitively by the b8-10
coupling FR-B815-062). **L2** (real overlay on the c1 copy): the overlaid tree
MUST **still contain Kong** — `fsm-kong` in `docker-compose.dev.yml` and the REST↔
gRPC transcoding routes in `infra/kong/kong.yml` (the "REST-bridge" is those routes
inside the Kong declarative config, per the b8-14 removal-manifest, not a separate
artifact). A premature Kong removal MUST fail this cell (a flip-not-leaked guard,
complementing `b8-14.test.sh`).

#### FR-B815-042: Smoke fixture-matrix re-run on the upgraded tree
**L2** (real overlay on the c1 copy): the cell MUST re-run the T5.1.B fixture
matrix — `required_paths` present + `forbidden_paths` absent per
`cli/test/e2e/archetype-fixtures/full-stack-monorepo.yml` — against the
**overlaid c1 tree** (re-implemented standalone in the harness, since
`cli/test/e2e/archetypes-smoke.test.ts` is fresh-scaffold-only). Skip-passes when
the c1 example or required fixture is absent.

### Group 5 — flip-gated cells (deferred, documented)
#### FR-B815-050: Flip-gated skip-pass guard
The harness MUST include a guard cell that documents + **skip-passes** the
flip-gated cells (front-door `forge upgrade` auto-resolving to 2.0.0; Kong→Envoy
removal assertions on the upgraded tree), to be activated by the
`b8-14-promotion-flip` follow-up. It MUST NOT fail while 2.0.0 is `candidate`.

### Group 6 — CI + coupling
#### FR-B815-060: forge-ci registration
`.github/workflows/forge-ci.yml` MUST register `b8-15.test.sh --level 1`.

#### FR-B815-061: CHANGELOG anchor
`CHANGELOG.md` MUST carry a `b8-15` `[Unreleased]` entry (whole-file anchor).

#### FR-B815-062: Coupling guards
`b8-15.test.sh` MUST re-run, by exit code, the engines it exercises: `a7`,
`b8-10`, and `b8-14`.

#### FR-B815-063: No standard/schema/constitution/template mutation
No `.forge/standards/`, schema, `.forge/constitution.md`, scaffolder, or frozen
1.0.0 template file may change. `constitution_version` stays `1.1.0`; the frozen
snapshot sha (b8-2) MUST match its `.sha256`.

---

## Non-functional requirements
- **NFR-001**: L1 ≤ a few seconds; heavy real-overlay + smoke is L2 opt-in
  (`FORGE_B8_15_LIVE`), skip-passing by default on the node+python+shellcheck CI.
- **NFR-002**: Every L1 FR verifiable hermetically (no toolchain beyond git/python3/tar).
- **NFR-003**: Pure test brick — only `forge-ci.yml` + `CHANGELOG.md` pre-existing
  files touched; everything else new (change dir + harness).
- **NFR-004**: No fabricated external version/API; no committed latency/number.

---

## BDD acceptance criteria

```gherkin
Feature: forge upgrade matrix (T5.1 Layer D)

  Scenario: Cross-major upgrade demands migration
    Given a 1.5.2 baseline project scaffolded from the framework
    When `forge-upgrade.sh --to-version 2.0.0` runs
    Then it exits 7
    And stderr contains "[NEEDS MIGRATION: from 1.5.2 to 2.0.0]"

  Scenario: Same-major upgrade proceeds and records history
    Given a 1.0.0 baseline project
    When it is upgraded to 1.1.0
    Then it exits 0
    And .forge/scaffold-manifest.yaml archetype_version is 1.1.0
    And upgrade_history has one more append-only entry with the full shape

  Scenario: Flagship 1.0.0 -> 2.0.0 is additive (pre-flip)
    Given a 1.0.0 flagship tree materialized from 1.0.0.tar.gz
    When bin/forge-migrate-flagship.sh applies the 2.0.0 overlay (L2)
    Then the upgraded tree still contains Kong (fsm-kong) and the REST bridge
    And the T5.1.B required/forbidden path matrix passes on the upgraded tree
    And an upgrade_history entry from 1.0.0 to 2.0.0 is recorded

  Scenario: Flip-gated cells are skipped, not failed
    Given 2.0.0 is still stage:candidate / scaffoldable:false
    When the harness reaches the front-door-auto-resolve + Kong-removal cells
    Then they skip-pass (pending b8-14-promotion-flip), the harness stays green
```
