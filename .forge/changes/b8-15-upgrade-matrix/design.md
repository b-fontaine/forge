# Design: b8-15-upgrade-matrix

**Status**: designed → 2026-06-04 · **Constitution**: 1.1.0
**Architects**: Eris (test strategy), Atlas (upgrade/infra) — E2E test harness brick
Grounded by the `wf_3b8aeb15` 6-mapper + critic workflow.

---

## Architecture Decisions

### ADR-B815-001: Positive flagship cell drives migrate-flagship; front-door 2.0.0 is flip-gated
**Context**: The plan says "forge upgrade matrix … starting with the critical
1.0.0→2.0.0 flagship". Two code paths reach 2.0.0: the `forge upgrade` front door
(`resolveFrameworkVersion` reads only `schema.yaml`=1.0.0 → cannot auto-discover
2.0.0 while it is `candidate`/`scaffoldable:false`) and the dedicated
`bin/forge-migrate-flagship.sh` (bypasses `_a7_check_version_compat:54`,
hard-codes 1.0.0→2.0.0, BASE=frozen 1.0.0 snapshot, RIGHT=live 2.0.0 template-set).
**Decision**: The **positive** 1.0.0→2.0.0 cell drives **migrate-flagship**
(runnable today). The **front-door auto-resolve to 2.0.0** is a **flip-gated
skip-pass** cell (FR-B815-050), activated by `b8-14-promotion-flip`. The front
door is still exercised today for its **negative** path (exit-7 on the major bump).
**Consequences**: B.8.15 ships green now without waiting on the 7-day window; the
front-door positive path completes post-flip.
**Constitution**: III.4 anti-fabrication (don't assert a flip-gated path passes).

### ADR-B815-002: Deliverable = a harness with cells, not a GitHub Actions matrix file
**Context**: `forge-ci.yml` has no GA `strategy.matrix`; the suite is a hand-rolled
bash array (`:68-121`), every sibling a one-line entry.
**Decision**: Implement the "matrix" as **cells = test functions** in
`.forge/scripts/tests/b8-15.test.sh`, registered with one line
(`"b8-15.test.sh --level 1"`) near the b8-* block. No new workflow file.
**Consequences**: Consistent with the established forge-self-ci pattern; entry
order is load-bearing (sibling grep-adjacency) — append after `b8-14`.
**Constitution**: VIII.5 (CI as code, existing pattern).

### ADR-B815-003: Flagship PROJECT base = the c1 example (not the framework tarball); no 2.0.0 tarball
**Context**: Independent review caught that `1.0.0.tar.gz` is the **framework-repo**
snapshot (`.forge/`, `bin/`, …) — extracting it yields NO `backend/`,
`docker-compose.dev.yml`, `fsm-kong`, or `scaffold-manifest.yaml`. migrate-flagship's
`--target` is a **scaffolded project**, not the framework. And the plan's "2.0.0
snapshot tarball" is stale — only `1.0.0.tar.gz` exists.
**Decision**: The flagship cell copies **`examples/forge-fsm-example/`** (the
committed scaffolded 1.0.0 full-stack-monorepo project — the b8-12 precedent) to a
tmpdir, git-init+commits, and runs `migrate-flagship --target` there. `1.0.0.tar.gz`
is migrate-flagship's **internal 3-way-merge BASE** (consumed by the script), and
the **live 2.0.0 template-set dir** is RIGHT — neither is the project base. The
Kong-present (FR-041) + fixture-matrix (FR-042) assertions run on the **overlaid c1
tree** (L2), because only a real scaffolded project has those files.
**Consequences**: No dependency on a non-existent 2.0.0 tarball nor on the framework
snapshot containing project files; adds a `C.1` dependency (the c1 example).
**Constitution**: III.4 (don't depend on a fabricated/mis-described prerequisite).

### ADR-B815-004: L1 cheap structural; L2 opt-in real overlay + smoke
**Context**: The full migrate-flagship real overlay + smoke-matrix on a
materialized tree is heavier than the ≤-few-seconds L1 budget.
**Decision**: **L1** = negative exit-7, `--force`-dirty refusal, same-major real
upgrades + ledger/manifest assertions, `.merge-conflicts` format/cleanup, flagship
**dry-run** plan + the additive invariant, ledger shape/append-only. **L2**
(`FORGE_B8_15_LIVE`) = the full flagship real overlay + the T5.1.B fixture matrix
on the materialized upgraded tree. L2 skip-passes by default (CI node+python).
**Consequences**: L1 stays green + fast on CI; deep coverage opt-in.
**Constitution**: Article I; the t5-otel-live-run L1/L2 precedent.

### ADR-B815-005: Additive invariant — L1 static no-`rm` guard + L2 tree-present
**Context**: Removal of Kong/REST is gated on the B.8.14 flip; migrate-flagship is
copy-only (no delete path). A tree-level "Kong present" assertion needs a
materialized overlaid tree, which a **dry-run** does NOT produce — so it cannot be
an L1 dry-run assertion (independent-review HIGH-1).
**Decision**: Split the additive invariant. **L1**: a STATIC guard asserts
`forge-migrate-flagship.sh` has no `rm`/`rmdir`/delete on Kong/REST/Temporal tokens
(mirrors b8-10's additive-only static guard; also re-run by the b8-10 coupling
FR-062). **L2** (real overlay on the c1 copy): assert the overlaid tree still
contains `fsm-kong` (`docker-compose.dev.yml`) + the REST↔gRPC routes in
`infra/kong/kong.yml` (the "REST-bridge" = those routes, per the b8-14
removal-manifest — not a separate artifact). The L2 tree-present is the
flip-not-leaked guard at the tree level.
**Consequences**: L1 stays coherent (no tree needed); L2 enforces the real
additive contract; jointly with b8-14's negative guards, fences the point of no
return.
**Constitution**: VIII.1 (Kong SHALL — still in force).

### ADR-B815-006: Hermetic ledger assertions (shape, not value) + git identity
**Context**: `upgrade_history` carries a live `cli_version` ("dev") + ISO date;
the fixtures `git init`+`commit`.
**Decision**: Assert entry **keys/shape** + append-only count, not exact
value-bytes; tolerate "dev". Export `GIT_AUTHOR_*`/`GIT_COMMITTER_*` at the top
(b8-12 CI lesson). Whole-manifest grep (changelog-coupling lesson).
**Consequences**: Green on any runner regardless of identity / cli_version.
**Constitution**: Article I (hermetic).

---

## Cell map (b8-15.test.sh)

| Cell | Driver | Level | FR |
|------|--------|-------|----|
| negative major-bump exit-7 `[NEEDS MIGRATION:]` (synth 1.5.2 manifest) | forge-upgrade.sh front door | L1 | 010 | direct |
| `--force` dirty-git refused (same-major target → exit-7 is force-clean, not compat) | forge-upgrade.sh | L1 | 011 | direct |
| same-major proceed/merge + manifest bump | a7 coupling | L1 | 020/021 | a7-authoritative |
| upgrade_history generic shape + append-only | a7 coupling | L1 | 030 | a7-authoritative |
| `.merge-conflicts` format + cleanup | a7 coupling | L1 | 031 | a7-authoritative |
| flagship dry-run plan on c1 copy (no-op) | migrate-flagship | L1 | 040 | direct |
| additive static no-`rm` guard (Kong/REST/Temporal) | static grep | L1 | 041 | direct |
| flagship real overlay on c1 + ledger(`kind`,1.0.0→2.0.0) + Kong-present tree + T5.1.B matrix | migrate-flagship | L2 | 040/041/042 | direct |
| flip-gated skip-pass guard (front-door 2.0.0 + Kong removal) | — | L1 | 050 | direct |
| CI reg / CHANGELOG / coupling (a7,b8-10,b8-14) / frozen | — | L1 | 060/061/062/063 | direct |

The same-major / ledger-generic / `.merge-conflicts` invariants are **gated via the
a7 coupling** (a7 is their authoritative harness); B.8.15 does not duplicate a7's
fixtures. B.8.15's genuinely-new direct cells are the cross-major negative, the
`--force`-dirty refusal, and the flagship-on-c1 cells.

## Testing strategy
- RED-first: harness before it can pass; confirm the not-yet-wired cells fail,
  then wire fixtures to GREEN.
- Reuse the a7.test.sh fixture-setup pattern for baseline projects (scaffold from
  snapshot, synthesize manifest at from_version, git init+commit).
- Full suite + verify.sh + constitution-linter before flip; confirm a7 + b8-10 +
  b8-14 coupling green.

## Standards applied
- None bumped (FR-B815-063). Exercises A.7 upgrade-policy, B.8.2 snapshot,
  B.8.10 migrate, T5.1 smoke fixtures.

---

## Constitutional Compliance Gate
- **Article I (TDD)**: ✓ RED-first.
- **Article III.4 (anti-fabrication)**: ✓ front-door 2.0.0 flip-gated (not asserted
  passing); no dependency on a non-existent 2.0.0 tarball; ledger shape-not-value.
- **§VIII.1 (Kong SHALL)**: ✓ additive invariant asserts Kong still present (removal
  flip-gated).
- **No standard/schema/constitution/template mutation**: ✓ (FR-B815-063); frozen
  1.0.0 byte-identical.
- **No BLOCK conditions.** Design APPROVED for planning pending independent review.
