# Tasks — `t7-forbidden-archetypes-wiring`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — establish the chain

- [x] **T1.1** Confirm the refusal code at `init-archetype.ts:159-171` is correct and
      that `parseDispatchTable` returns `{ archetypes }` only.
      [Story: FR-T7FA-001]
- [x] **T1.2** Measure the real behaviour: exit 127 with a shell path error.
      [Story: FR-T7FA-002]
- [x] **T1.3** Probe the parser's output against the YAML. Found a second defect —
      `flutter-firebase.since` parses as `"0.5.0"   # realigned…`, wrong value plus a
      trailing comment, because nothing stops later blocks leaking into the last
      archetype. Blast radius measured: that one field, six others correct.
      [Story: FR-T7FA-001, NFR-T7FA-002]

## T2 — RED

- [x] **T2.1** `cli/test/e2e/forbidden-archetype.test.ts` — parser shape, the five
      keys, and the end-to-end refusal.
      [Story: FR-T7FA-001, FR-T7FA-002, FR-T7FA-003, FR-T7FA-004]
- [x] **T2.2** Run. **RED 3/4**, including `expected 3, received 127`.
      [Story: FR-T7FA-002]

## T3 — GREEN

- [x] **T3.1** `parseDispatchTable`: block tracking, the `forbidden_archetypes` branch,
      `stripComment`.
      [Story: FR-T7FA-001, NFR-T7FA-001, NFR-T7FA-002]
- [x] **T3.2** Run again. The refusal fires with the exact structured line — and the
      process exits **1**. Third link found: `cli.ts`'s catch discarded the `exitCode`
      carried on the error.
      [Story: FR-T7FA-002]
- [x] **T3.3** `cli.ts`: honour a carried exit code, default 1 unchanged.
      [Story: FR-T7FA-002]
- [x] **T3.4** `j8.test.sh` T-090 (data) + T-L2-090 (behaviour).
      [Story: FR-T7FA-005]
- [x] **T3.5** Correct `docs/ARCHETYPES.md`'s `flutter-firebase` row, which `b9-4`
      wrote stating the refusal does not fire.
      [Story: FR-T7FA-002]

## T4 — prove it

- [x] **T4.1** Live, unpiped: exit **3**, `[REFUSAL: flutter-firebase: J8-RULE-001: …]`,
      no tree created.
      [Story: FR-T7FA-002, FR-T7FA-003]
- [x] **T4.2** `flutter-firebase.since` now parses as `"0.0.0"` — the leak is closed.
      [Story: NFR-T7FA-002]
- [x] **T4.3** Mutation-probe T-090: empty a key, undocument a `rule_id`. Both RED.
      [Story: FR-T7FA-005]

## T5 — records

- [x] **T5.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-T7FA-006]

## T6 — regression

- [x] **T6.1** `cd cli && npm test` — 17 files, 94 tests.
      [Story: FR-T7FA-004, NFR-T7FA-003]
- [x] **T6.2** Full 81-entry CI matrix sweep + shellcheck.
      [Story: NFR-T7FA-002]
- [x] **T6.3** `verify.sh` + `constitution-linter.sh` **after** the status flip.
      [Story: NFR-T7FA-002]

## Negative scope guard

- [x] **T7.1** No change to the refusal's exit code, message format or position; no
      change to `dispatch-table.yml`'s data; `forbidden_combinations:` untouched; the
      `--help` goldens unmoved.
      [Story: NFR-T7FA-003, ADR-T7FA-002]
