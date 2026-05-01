# Open Questions — f2-yaml-schema

<!--
This file tracks unresolved questions for the change `f2-yaml-schema`,
per the Forge convention defined in
`.forge/standards/global/open-questions.md` (Article III.4
mechanisation, F.1).

Q-NNN is sequential per change, zero-padded to 3 digits, never reused.
Resolved questions are KEPT indefinitely (immutable history).
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: Use Python `jsonschema` library or pure-bash validation?

- **Status**: answered
- **Raised in**: proposal.md § "Solution"
- **Raised on**: 2026-05-01
- **Raised by**: clio (spec writer)

### Question

The existing `verify.sh` uses Python 3 inline (`python3 - <<PY ... PY`)
for YAML parsing via PyYAML. F.2 needs structural validation : either
add the `jsonschema` library (one more pip dep, but standard / mature)
or hand-roll the checks in pure shell + python.

Trade-offs :
- **`jsonschema`** : JSON Schema Draft 2020-12 expressive, library-grade
  error messages, additional CI dependency (`pip install jsonschema`),
  ~5 MB on disk.
- **Pure shell + python** : zero new dep, faster cold-start, but
  re-implements basic schema checks manually (enum, required keys,
  pattern, conditional via `if status == archived then ...`).

Recommendation : start with **pure shell + python inline** (consistent
with existing verify.sh pattern), defer `jsonschema` to F.5+ when
schema complexity outgrows manual checks.

### Resolution

- **Resolved on**: 2026-05-01
- **Resolved by**: user (Benoit Fontaine, BDFL)
- **Decision**: pure shell + Python inline (no new dependency).
- **Rationale**: zero new pip install in CI Forge core ; consistent with
  the existing `verify.sh` pattern of `python3 - <<PY ... PY` blocks ;
  schema complexity stays manageable for F.2's scope (enum + regex +
  conditional). If complexity grows in F.5+, jsonschema can be added
  later as an additive change.
- **Resolved in**: proposal.md § "Décisions ouvertes — résolues"

## Q-002: Strict timeline coherence enforcement?

- **Status**: answered
- **Raised in**: proposal.md § "Solution"
- **Raised on**: 2026-05-01
- **Raised by**: clio

### Question

The `.forge.yaml` `timeline.*` fields document when each pipeline
phase completed. Should F.2 enforce that :
(a) `timeline.<phase>` is present iff status is `>= <phase>` ?
(b) the dates are monotonically increasing across phases ?
(c) all phases are populated when status is `archived` ?

Strict (a+b+c) catches more inconsistencies but rejects minor edits.
Lax (a only) is forgiving but lets typos through.

Recommendation : strict (a+c), permissive on (b) — date order is
hard to enforce when a maintainer manually edits a date. Date format
(`YYYY-MM-DD`) IS enforced.

### Resolution

- **Resolved on**: 2026-05-01
- **Resolved by**: user (Benoit Fontaine, BDFL)
- **Decision**: strict (a + c), permissive on (b).
- **Rationale**: (a) `timeline.<phase>` MUST be present when `status
  >= phase` — catches "implemented but no implemented timestamp" typo.
  (c) All phases populated when archived — guarantees full audit trail.
  (b) Date monotonicity NOT enforced — manual edits often correct
  timestamps after the fact. Date format `YYYY-MM-DD` IS enforced via
  pattern.
- **Resolved in**: proposal.md § "Décisions ouvertes — résolues"

## Q-003: Validate b1-workflow multi-layer extra fields?

- **Status**: answered
- **Raised in**: proposal.md § "Solution"
- **Raised on**: 2026-05-01
- **Raised by**: clio

### Question

`b1-workflow` (✅ archived) added optional fields to `.forge.yaml` :
`layers:`, `designs_per_layer:`, `tasks_per_layer:`. F.2 schema
should cover them too — but they're optional and only relevant when
the root `.forge.yaml` declares `schema: full-stack-monorepo`.

Should F.2 :
(a) enforce shape if present (not required) ?
(b) cross-validate `designs_per_layer` keys ⊆ `layers` ?
(c) defer multi-layer validation to a separate check (b1-workflow
    already has its own shell validator) ?

Recommendation : (a) — F.2 does shape validation only ; existing
b1-workflow validator stays for cross-layer semantics.

### Resolution

- **Resolved on**: 2026-05-01
- **Resolved by**: user (Benoit Fontaine, BDFL)
- **Decision**: (a) — shape validation only.
- **Rationale**: F.2's role is structural (does the YAML conform to a
  type ?). Cross-layer semantic checks (`designs_per_layer ⊆ layers`)
  are better-served by `b1-workflow`'s existing shell validator
  (`validate-foundations.sh`), which has the right context. Avoid
  duplicating validation logic across two scripts. F.2 ensures the
  fields, when present, are well-typed maps with string keys/values.
- **Resolved in**: proposal.md § "Décisions ouvertes — résolues"
