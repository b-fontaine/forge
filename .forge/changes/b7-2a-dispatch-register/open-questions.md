# Open Questions — b7-2a-dispatch-register

<!--
Q-NNN sequential, never reused. Author-phase leanings recorded; resolutions at
/forge:design by an independent reviewer + maintainer (Article V).

## Resolution log
- **Q-001** resolved at /forge:design 2026-06-12 → (a) `since: "0.5.0"` (VERSIONING.md:31 — new archetypes ⇒ MINOR). ADR-B7-2A-004.
- **Q-002** resolved at /forge:design 2026-06-12 → (a) documentary `status: candidate`, no b5.test.sh change. ADR-B7-2A-005.
- Resolutions authored at design; independent reviewer + maintainer ratification pending at /forge:review (Article V).
-->

## Q-001: `since:` value for the ai-native-rag dispatch entry

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-12)
- **Raised in**: proposal.md (Ground truth), specs.md FR-B7-2A-001
- **Raised on**: 2026-06-12

### Question

The dispatch `since:` field is the framework version that registered the
archetype. The framework is at 0.4.0 (released); this change lands in
`[Unreleased]`. Is the next cut 0.5.0 (minor — a new archetype is a feature) or
0.4.1 (patch)?

`[NEEDS CLARIFICATION: confirm against docs/VERSIONING.md whether registering a
new (non-scaffoldable) archetype is a minor (0.5.0) or patch (0.4.1) on the 0.y
pre-GA track.]`

- (a) **`since: "0.5.0"`** *(leaning)* — a new archetype is an additive feature;
  minor bump on the 0.y track. Most consistent with full-stack (1.0.0) /
  mobile-only (1.2.0) being feature-introducing versions.
- (b) `since: "0.4.1"` — treat a not-yet-scaffoldable registration as a patch.
  Weaker: it still adds a user-visible archetype to `forge init`.

Resolve by reading `docs/VERSIONING.md` at design; non-blocking for the logic.

## Q-002: does the entry carry a `status:` marker?

- **Status**: answered → option (a) (ADR finalized at /forge:design 2026-06-12)
- **Raised in**: proposal.md (Solution step 1), specs.md FR-B7-2A-001
- **Raised on**: 2026-06-12

### Question

`mobile-only` carries `status: legacy_alias`; `flutter-firebase` carries
`status: removed_from_roadmap`. Should ai-native-rag carry a documentary
`status:` (e.g. `candidate` / `not_scaffoldable`) for human clarity?

`[NEEDS CLARIFICATION: add a documentary status: marker, or keep the entry plain
and let the candidate/scaffoldable:false schema + the refusing wrapper speak for
themselves?]`

- (a) **Add `status: candidate`** *(leaning)* — cheap human signal that the
  archetype is registered-but-not-scaffoldable. The dispatch parser tolerates
  `status`. **No `b5.test.sh` change needed** (the wrapper file exists, so the
  scaffolder-exists gate passes regardless of status). If chosen, a b7-2a L1 test
  asserts the marker.
- (b) Keep plain — the schema stage + the wrapper already encode the state.
  Avoids inventing a status enum value not used elsewhere.
