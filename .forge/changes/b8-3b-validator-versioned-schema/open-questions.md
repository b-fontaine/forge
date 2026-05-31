# Open Questions — b8-3b-validator-versioned-schema

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
Author phase: leanings recorded; resolutions made at /forge:design by an
INDEPENDENT reviewer + the maintainer.

## Resolution log

- **Q-001** resolved by maintainer 2026-05-31 → option (b) generic discovery.
  ADR-B83B-001 finalized at /forge:design.
- **Q-002** resolved by maintainer 2026-05-31 → localize in validate-foundations.sh
  only (verify.sh and constitution-linter.sh unchanged — they do not deep-validate).
  ADR-B83B-002 finalized at /forge:design.
- **Q-003** resolved by independent reviewer 2026-05-31 → option (a) deferral holds.
  Reviewer confirmed via live code: cli.ts:213-226 hard-codes "schema.yaml";
  init-archetype.ts reads NO schema file. ADR-B83B-004 finalized at /forge:design.
- Specify artifacts passed independent review APPROVE (no CRITICAL/HIGH/MEDIUM
  findings) 2026-05-31.
-->

## Q-001: Discovery scope — all archetype dirs vs only `full-stack-monorepo/`

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B83B-001 seed), `specs.md` FR-B83B-001/003 + NFR-B83B-005
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-3b specify pass)

### Question

The three shared validators only ever validate `full-stack-monorepo/` today
(`verify.sh:379` gates the Monorepo Foundations section on that directory
existing; `validate-foundations.sh:92` and `constitution-linter.sh:69` hard-code
that archetype). Only `full-stack-monorepo/2.0.0.yaml` exists as a versioned
sibling on disk. Should B.8.3.b discover versioned siblings **only** under
`full-stack-monorepo/` (matching the current validator scope), or **generically
across all archetype dirs** (forward-ready for B.9.1 `mobile-pwa-first/2.0.0.yaml`)?

- (a) **Scoped to `full-stack-monorepo/`** — minimal blast radius; matches the
  current validator scope exactly. B.9.1 widens scope when
  `mobile-pwa-first/2.0.0.yaml` lands.
- (b) **Generic across all archetype dirs** — forward-ready; discovery globs
  all archetype dirs for `<X.Y.Z>.yaml` siblings; since only
  `full-stack-monorepo/2.0.0.yaml` exists today, it is a genuine no-op everywhere
  else; avoids a second validator edit at B.9.1.

### Resolution

- **Resolved on**: 2026-05-31 (maintainer decision, finalized at /forge:design)
- **Decision**: Option (b) — generic discovery across all `.forge/schemas/<archetype>/`
  dirs. The new `check_versioned_schema_siblings()` function globs every archetype
  dir for files matching `^[0-9]+\.[0-9]+\.[0-9]+\.yaml$`. Since only
  `full-stack-monorepo/2.0.0.yaml` matches today, discovery is a genuine no-op in
  the other six dirs. The `mobile-only/schema.yaml` heterogeneous shape
  (`archetype:`/`schema_version:`) is never touched — it has no versioned sibling.
  Validated by T-011 (no PASS/FAIL emitted for a fresh archetype dir with no
  versioned sibling).
- **Rationale**: Avoids a second validator edit at B.9.1; the strict-superset
  backward-compat guarantee holds because the glob finds nothing in dirs with no
  versioned sibling. The "how to avoid validating heterogeneous `schema.yaml`
  shapes" concern is moot — discovery only adds validation for `<X.Y.Z>.yaml`
  files, which mobile-only (and all other single-`schema.yaml` dirs) does not have.

---

## Q-002: Shared discovery helper vs duplicated inline `python3` across three validators

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B83B-002 seed), `specs.md` FR-B83B-013/020 + NFR-B83B-002
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-3b specify pass)

### Question

Should the versioned-schema discovery + per-file validation logic be factored into
a single shared sourced helper (used by all three validators) or duplicated inline
per validator?

Context added at design: re-reading all three validators reveals that only
`validate-foundations.sh:91-153` performs **deep validation** (name/SemVer/stage/
triple/phases). `verify.sh:83-98` (`resolve_layer_path`) and
`constitution-linter.sh:67-83` (`resolve_monorepo_path`) use the schema file
solely for **layer-path resolution** — they read `schema.yaml` to extract a layer's
`path` field and emit a bare path string; they make no `pass`/`fail` calls and do
no schema validation whatsoever.

- (a) **Single shared helper** — single source of truth; but adds a new sourced
  dependency across three scripts that do not share a validation concern.
- (b) **Localize in `validate-foundations.sh` only; leave `verify.sh` and
  `constitution-linter.sh` byte-unchanged** — only one script has deep-validation
  logic to extend; a shared helper for a single consumer is over-abstraction; zero
  new dependency; the sibling-harness coupling lesson is satisfied by not
  duplicating logic at all, not by adding a shared file.

### Resolution

- **Resolved on**: 2026-05-31 (maintainer decision, finalized at /forge:design)
- **Decision**: Option (b) — localize discovery + invariant logic in
  `validate-foundations.sh` only, as a new `check_versioned_schema_siblings()`
  function called from `main()`. `verify.sh` and `constitution-linter.sh` are
  **byte-unchanged**. The new PASS/FAIL lines emitted by the function flow
  automatically into `verify.sh`'s existing aggregation loop (`verify.sh:385-391`)
  without any change to `verify.sh`.
- **Rationale**: `verify.sh` and `constitution-linter.sh` are path-resolution
  helpers, not validators. Extending them would add blast radius without adding
  gate coverage. One file changed → one file to review → minimal coupling.

---

## Q-003: Confirm the scaffolder cannot select a versioned schema (justifying the B.8.14 deferral)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B83B-004 seed), `specs.md` FR-B83B-040/041
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-3b specify pass)

### Question

Does any scaffolder entry point (init, upgrade, wizard, auto-detect) read a
versioned `<X.Y.Z>.yaml` or honor a `scaffoldable: false` flag at runtime today?
If yes, a runtime guard must be in B.8.3.b scope.

- (a) **Deferral holds** — scaffolder selects by archetype name; no versioned-file
  selection; enforcement in B.8.3.b is the validator invariant.
- (b) **A scaffolder path can already reach a versioned schema** — runtime guard
  must be pulled into B.8.3.b scope.

### Resolution

- **Resolved on**: 2026-05-31 (independent reviewer confirmation)
- **Decision**: Option (a) — deferral holds. Closing evidence confirmed by
  independent reviewer via live code:
  - `cli/src/cli.ts:213-226` — `resolveFrameworkVersion()` constructs the path
    `resolve(assets, ".forge/schemas", archetype, "schema.yaml")` with the literal
    string `"schema.yaml"` hard-coded. It reads this file only to extract the
    `version:` field for upgrade tracking. It never constructs a versioned path.
  - `cli/src/commands/init-archetype.ts` — dispatches by archetype name to a
    per-archetype wrapper shell script via the dispatch table (`dispatch-table.yml`).
    Reads **no** schema YAML file at all. The dispatch table contains archetype
    names and wrapper script paths; it does not reference `schema.yaml` or any
    versioned schema.
  - No scaffolder entry point (init, init-archetype, upgrade, wizard, auto-detect)
    reads `<X.Y.Z>.yaml` or checks `scaffoldable:`.
- **Rationale**: The scaffolder selects what to scaffold by archetype name →
  dispatch table → wrapper script → snapshot. The `schema.yaml` file is consulted
  only by `resolveFrameworkVersion` (upgrade path) and by `validate-foundations.sh`
  (validator). Runtime selection of a versioned or non-scaffoldable schema cannot
  occur before B.8.14 adds that capability. Enforcement in B.8.3.b is therefore
  the validator invariant (`stage: candidate ⇒ scaffoldable: false`); the runtime
  guard lands at B.8.14.
