# Evidence Ledger — b1-1-dev-up-matrix-fixes
<!-- Created: 2026-05-19 -->
<!-- Audit: T5.3.1 — Phase 5 T-VAL-007 evidence collection -->

> Captures numeric verification results for the T-VAL-001..006
> gate. Reviewed by independent code-reviewer at archive time.

## Pre-edit baseline (RED witness, T-HAR-008)

```
── T5.3.1 — b1-1-dev-up-matrix-fixes — level 1 ──
    canonical template still declares 'image: scratch' (ADR-B1-DUM-001 violated)
  ✗ _test_b1dum_l1_001_canonical_no_scratch
    canonical template still declares top-level 'version:' key (ADR-B1-DUM-002 violated)
  ✗ _test_b1dum_l1_002_canonical_no_version_key
    canonical template missing audit comment 'T5.3.1 (b1-1-dev-up-matrix-fixes)' (FR-B1-DUM-005)
  ✗ _test_b1dum_l1_003_audit_comment_present
  ✓ _test_b1dum_l1_004_mirror_example_byte_identity
  ✓ _test_b1dum_l1_005_mirror_cli_assets_byte_identity
  ✓ _test_b1dum_l1_006_mirror_cli_assets_example_byte_identity
  ✓ _test_b1dum_l1_007_four_copies_only
  ✓ _test_b1dum_l1_008_adopter_comment_preserved
    CHANGELOG.md does not mention b1-1-dev-up-matrix-fixes (FR-B1-DUM-110)
  ✗ _test_b1dum_l1_009_changelog_entry

── Summary ──
  Passed:  5    Failed:  4    wall-clock 0.499 s
```

4 FAIL / 5 PASS — matches T-HAR-008 ≥ 4 FAIL exit gate.

## Post-edit final state (Phase 5, T-VAL-001)

```
── T5.3.1 — b1-1-dev-up-matrix-fixes — level 1 ──
  ✓ _test_b1dum_l1_001_canonical_no_scratch
  ✓ _test_b1dum_l1_002_canonical_no_version_key
  ✓ _test_b1dum_l1_003_audit_comment_present
  ✓ _test_b1dum_l1_004_mirror_example_byte_identity
  ✓ _test_b1dum_l1_005_mirror_cli_assets_byte_identity
  ✓ _test_b1dum_l1_006_mirror_cli_assets_example_byte_identity
  ✓ _test_b1dum_l1_007_four_copies_only
  ✓ _test_b1dum_l1_008_adopter_comment_preserved
  ✓ _test_b1dum_l1_009_changelog_entry

── Summary ──
  Passed:  9    Failed:  0    wall-clock 0.531 s   (≤ 2 s NFR-B1-DUM-002 ✓)
```

## T-VAL-002 — constitution-linter.sh

```
PASS: 40 | FAIL: 0 | WARN: 5 | N/A: 11
OVERALL: PASS
```

5 WARN are pre-existing (`T.5 transport-codegen-coverage`, T6/B.8
territory). 0 FAIL, 0 new WARN — NFR-B1-DUM-004 satisfied.

## T-VAL-003 — verify.sh

```
  Warnings: 1
RESULT: PASS
```

PASS preserved.

## T-VAL-004 — prior harness regression check

| Harness                       | L1 PASS | L1 FAIL |
|-------------------------------|---------|---------|
| `t5-1.test.sh`                | 17      | 0       |
| `t5-2.test.sh`                | 8       | 0       |
| `t5-otel-dartastic.test.sh`   | 13      | 0       |
| `i2.test.sh`                  | 14      | 0       |
| `i3.test.sh`                  | 14      | 0       |
| `i5.test.sh`                  | 16      | 0       |
| `i6.test.sh`                  | 14      | 0       |
| `j7.test.sh`                  | 17      | 0       |
| `j8.test.sh`                  | 18      | 0       |
| `k3.test.sh`                  | 20      | 0       |
| **Totals**                    | **151** | **0**   |

Zero regression. NFR-B1-DUM-004 satisfied across the full prior
harness surface.

## T-VAL-005 — L2 dry-run (`FORGE_B1DUM_DOCKER=1`)

First attempt (2026-05-19, harness as-shipped) :

```
Phase 2: L2 — live task dev:up cycle (opt-in FORGE_B1DUM_DOCKER=1)
    task dev:up failed on fresh scaffold (FR-B1-DUM-060)
  ✗ _test_b1dum_l2_dev_up_cycle
```

Root cause : `env file /tmp/.../.env not found`. The rendered
`docker-compose.dev.yml::env_file: .env` requires `.env` to exist
locally, but `forge init` only ships `.env.example`. Root
Taskfile.yml `dev-up-matrix` smoke driver
(`Taskfile.yml:160-162`) bootstraps `.env` from `.env.example`
before invoking `task dev:up`. The L2 harness did not mirror
that step — surfaced bug **in the harness**, not in the
template under test.

Fix : added the same `.env` bootstrap to
`_test_b1dum_l2_dev_up_cycle` after `forge init` and before
`task dev:up` (mirrors `Taskfile.yml:160-162` verbatim
semantics). No template change ; the contract surface remains
T5.3.1's narrow hygiene scope.

Re-run after `.env` bootstrap fix : **still FAIL** — but for a
**different, out-of-scope reason** :

```
 Image signoz/frontend:0.55.1 Pulling
 Image signoz/frontend:0.55.1 Error manifest for signoz/frontend:0.55.1
   not found: manifest unknown: manifest unknown
Error response from daemon: manifest for signoz/frontend:0.55.1 not found
task: Failed to run task "dev:up": exit status 1
```

`traefik/whoami:latest` (ADR-B1-DUM-001 placeholder) **was
successfully pulled** before the signoz failure interrupted the
stack. The T5.3.1 hygiene fix itself is sound ; the L2 cycle is
blocked by **upstream image rot in `signoz/frontend:0.55.1`**, an
image pinned by `t5-otel-stack` (archived 2026-05-10) and
**explicitly scope-out** of T5.3.1 per the proposal :

> "No structural rewrite of `docker-compose.dev.yml.tmpl`. Kong /
>  SigNoz / OBI / Coroot / OTel-collector layout stays as shipped
>  by T5 (`t5-otel-stack`, archived 2026-05-10). T5.3.1 = template
>  hygiene, not re-architecture B.8."

Tracked as Q-005 in `open-questions.md` (status `wontfix-here`)
and surfaced as a follow-up change candidate
`t5-otel-stack-image-refresh` in `docs/new-archetypes-plan.md`
§0.5. T5.3.1 L1 contract remains fully met (9/9 L1 GREEN).

**L2 verdict** : L2 is opt-in (`--level 1,2` + `FORGE_B1DUM_DOCKER=1`),
designed as a deep-coverage check that **does not gate CI** (per
ADR-B1-DUM-003 / precedent ADR-T5-OLR-005). It correctly captured
a real upstream blocker — that is exactly the value the L2 was
designed to provide. The blocker is logged as a follow-up.

## T-VAL-006 — `task validate` end-to-end

> Pending : `task validate` invokes the full Forge validate
> pipeline (build → gates → harness → vitest →
> smoke-with-toolchains → dev-up-matrix). Heavy run ; documented
> as a manual pre-release gate. Captured here as a deferred
> observation rather than blocking T5.3.1.

## T-REL-001 — Release vehicle decision

- `git tag v0.4.0-rc.1` : **exists** (commit `67a35bd` 2026-05-19).
- `npm view @sdd-forge/cli@0.4.0-rc.1 version` : **returns `0.4.0-rc.1`** (published on npm).

**Decision** : T5.3.1 cannot piggyback on rc.1 (already
published). Ship as **`v0.4.0-rc.2`** patch :

- CHANGELOG entry currently under `[Unreleased]` ; the next
  `scripts/release.sh --version 0.4.0-rc.2` invocation will seal
  it under the new versioned heading.
- `VERSION` + `cli/package.json` bumps deferred to release time
  (not part of T5.3.1's diff).

## T-REL-002 — Atomic revert dry-run

Pending — to be exercised in a separate `git worktree` once
T5.3.1 lands on `main`. Expected behaviour : single `git revert
<merge-sha>` restores all 4 mirror copies + harness + CHANGELOG
+ plan + roadmap + snapshot tarball atomically, and
`t5-3-1.test.sh --level 1` returns to the RED state captured at
the top of this ledger (4 FAIL / 5 PASS).

---

*Captured 2026-05-19 during the Phase 5 verification pass. To be
re-reviewed by the code-reviewer pass before `/forge:archive`.*
