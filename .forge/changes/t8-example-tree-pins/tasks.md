# Tasks — `t8-example-tree-pins`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — measure before touching

- [x] **T1.1** Render every `web-public` template with `<project-name>` substituted and
      diff against the committed example; record the exact drift set.
      [Story: FR-T8ETP-002, NFR-T8ETP-003]

## T2 — RED (guard half first)

- [x] **T2.1** Widen `b8-9::T-013`/`::T-014` discovery to the second root, derive the
      README sibling from the discovered path, add the scoped `examples/` floor. Run
      against the UNFIXED example: it must fail, naming the example files.
      [Story: FR-T8ETP-003, FR-T8ETP-004]

## T3 — GREEN

- [x] **T3.1** Write the three rendered files into the example.
      [Story: FR-T8ETP-001, FR-T8ETP-002]
- [x] **T3.2** `b8-9` 14/14.
      [Story: FR-T8ETP-003]

## T4 — prove the guard

- [x] **T4.1** Mutation probes: example pin reverted; example README sharp row deleted;
      `examples/` root matching nothing (scoped floor); a `node_modules` manifest present
      (must NOT be discovered). Files restored byte-identical.
      [Story: NFR-T8ETP-002, FR-T8ETP-004]
- [x] **T4.2** `npm install` + `npm audit --audit-level=high` on the fixed example
      manifest in a scratch dir: 0 high.
      [Story: FR-T8ETP-001]

## T5 — records

- [x] **T5.1** `web-frontend.yaml` + `b8-9` headers say two roots; `t7-qwik-deps-refresh`
      Q-004 resolved; CHANGELOG, roadmap, plan §0.N resynced in the same commit.
      [Story: FR-T8ETP-005]

## T6 — regression

- [x] **T6.1** Full `forge-ci` replay on the committed tree (82 entries, `example` job
      included), `verify.sh`, `constitution-linter.sh`, shellcheck, `forge-ci.yml` still
      421 lines.
      [Story: NFR-T8ETP-001, NFR-T8ETP-002]

## Review round 1 (2026-09-17) — independent guard lane: CHANGES REQUIRED, 1 major

- [x] **T8.1** RED first: reproduce the reviewer's scenario (Qwik out of both dependency
      maps, `_audit` prose kept, pins rotted) — GREEN against the round-0 floor.
      [Story: FR-T8ETP-004, NFR-T8ETP-002]
- [x] **T8.2** GREEN: floor moved into python, counting CHECKED surfaces under
      `examples/`; shell-side T-014 floor removed with a comment saying why. Probe RED;
      the six earlier probes unchanged; `b8-9` 14/14; shellcheck clean.
      [Story: FR-T8ETP-003, FR-T8ETP-004]

## Review round 2 (2026-09-22) — independent lane: CHANGES REQUIRED, 2 findings

- [x] **T9.1** RED first: reproduce both escapes (npm-workspaces hoist; example README
      table stripped, then renamed away) — all three GREEN against the round-1 guard.
      [Story: FR-T8ETP-004, NFR-T8ETP-002]
- [x] **T9.2** GREEN: the declares-neither skip is FATAL under `examples/`; a checked
      example surface must have a sibling README exposing a pin table. All three RED;
      the seven earlier probes unchanged; `b8-9` 14/14; shellcheck clean.
      [Story: FR-T8ETP-002, FR-T8ETP-003, FR-T8ETP-004]
- [x] **T9.3** Correct evidence P-8, which claimed round 1 had closed the workspaces
      variant it names. It had not.
      [Story: FR-T8ETP-005]
- [x] **T9.4** Claims lane nits: probe counts (10, 9 RED + 1 deliberately GREEN) in the
      CHANGELOG and plan; the eda parity figure (48 files, 47 identical); the whole-tree
      drift inventory in P-1 and Q-003; `examples/README.md`'s "Last updated" cell; the
      Q-004 Resolution reshaped to the five mandated fields, which surfaced Q-006.
      [Story: FR-T8ETP-005, NFR-T8ETP-003]

## Negative scope guard

- [x] **T7.1** No pin moved; only the three drifted files written; `connect-client.ts`
      untouched (Q-006 belongs to the codegen brick); no `forge-ci.yml` line added.
      [Story: NFR-T8ETP-003, NFR-T8ETP-001]
