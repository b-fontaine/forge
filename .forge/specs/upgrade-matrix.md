# Spec: forge-upgrade Matrix (T5.1 Layer D)

Canonical requirements for the upgrade-matrix gate. Source change:
`b8-15-upgrade-matrix` (archived 2026-06-04, audit B.8.15). Harness:
`.forge/scripts/tests/b8-15.test.sh`. The v0.4.0-stable publish gate.

## Requirements

### FR-UM-001: Matrix as harness cells (no GA matrix file)
The N-1→N upgrade matrix MUST be realised as cells in
`.forge/scripts/tests/b8-15.test.sh` registered in `forge-ci.yml` (forge-ci has no
GitHub Actions `strategy.matrix`). Hermetic L1 (git/python3/tar) + opt-in L2
(`FORGE_B8_15_LIVE`). Exports `GIT_AUTHOR_*`/`GIT_COMMITTER_*` (b8-12 lesson).

### FR-UM-002: Cross-major negative gate (e2e binary)
A cell MUST drive `bin/forge-upgrade.sh` as a subprocess on a synthesized 1.x.y
project and assert a cross-major target (→2.0.0) ⇒ exit 7 + literal
`[NEEDS MIGRATION: from … to …]`.

### FR-UM-003: --force clean-git gate (e2e binary)
A cell MUST assert `--force` on a **dirty** tree with a **same-major** target ⇒
exit 7 + the clean-git refusal message (same-major so the exit is the force-clean
gate, not version-compat which runs first).

### FR-UM-004: Flagship 1.0.0→2.0.0 via migrate-flagship (not the front door)
The positive flagship cell MUST drive `bin/forge-migrate-flagship.sh` against a
copy of the c1 example (`examples/forge-fsm-example/`, a scaffolded 1.0.0 project).
The `forge upgrade` front-door auto-resolve to 2.0.0 is **flip-gated**
(`schema.yaml`=1.0.0; 2.0.0 candidate/`scaffoldable:false`) and MUST NOT be
asserted as passing until the B.8.14 flip. L1: dry-run plan (1.0.0→2.0.0) + no
mutation. L2: real overlay asserting the `upgrade_history` flagship entry
(from=1.0.0/to=2.0.0 + `kind: flagship-migration`), the additive invariant (Kong
still present), and the T5.1.B fixture matrix on the overlaid tree.

### FR-UM-005: Additive invariant + flip-not-leaked guard
A static guard MUST assert `migrate-flagship` removes no Kong/REST/Temporal path
(additive-only). A flip-gated guard MUST assert 2.0.0 is still `scaffoldable:false`
and skip-pass the flip-gated cells, FAILING (to prompt re-activation) once the flip
promotes 2.0.0.

### FR-UM-006: Coupling, no fixture duplication, strict scope
The same-major / ledger-shape / `.merge-conflicts` machinery MUST be gated via the
`a7` coupling guard (a7 is authoritative); B.8.15 MUST NOT duplicate a7's fixtures.
Coupling also re-runs b8-10 + b8-14. The brick MUST NOT depend on a 2.0.0 snapshot
tarball (none exists; BASE = `1.0.0.tar.gz`, RIGHT = the live 2.0.0 template-set).
No standard/schema/constitution/scaffolder/template/frozen-snapshot mutation;
`constitution_version` stays 1.1.0.

<!-- Added in b8-15-upgrade-matrix change, 2026-06-04 -->
