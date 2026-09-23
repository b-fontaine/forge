# Open questions — `t8-upgrade-flagship-noop`

## Q-001: a conflicted run stamps the new version over files it did not change

- **Status**: answered
- **Raised in**: `evidence.md § P-5`
- **Raised on**: 2026-09-23
- **Raised by**: @bfontaine

### Question

A real upgrade that ends in conflicts, run without `--force`, returns exit 8 but still
writes `archetype_version: <to>` and a new `template_set_sha`. This was measured on fresh
`ai-native-rag` and `event-driven-eu` renders: exit 8, version stamped `1.0.1`. A
`conflict_2way` leaves the file **untouched** and only lists it in `.merge-conflicts`, so
the manifest says `<to>` while the file still holds `<from>`. As first raised, the
question asked whether a conflicted run should stamp at all, and treated that as a design
decision about A.7's ledger.

### Resolution

- **Resolved on**: 2026-09-23
- **Resolved by**: independent review of this brick (evidence P-8), confirmed by three
  adversarial votes
- **Decision**: No design decision was needed. The behaviour contradicted an existing
  requirement. FR-UP-007 (`.forge/changes/a7-forge-upgrade/specs.md`) lets the manifest
  record a run only when it succeeds: "exit 0 or 8 with `--force`". The driver violated
  it, and the fix is FR-T8UFN-008. A conflicted run without `--force` now leaves the
  manifest untouched and says so on stderr.
- **Rationale**: The consequence was also worse than first stated. The first version of
  this question predicted that the next run "would classify the file `preserved`". The
  review measured instead that the next run finds no snapshot for the stamped version
  (`BASE unavailable for 1.0.1`), drops into the 2-way fallback, and turns the whole
  surface into conflicts: 556 conflicts, where there had been 326 preserved and 230
  conflicted.
- **Resolved in**: `specs.md § FR-T8UFN-008`; `a7.test.sh ::
  test_conflicted_run_does_not_stamp_manifest`
