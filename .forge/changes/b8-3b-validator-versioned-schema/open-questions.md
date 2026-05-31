# Open Questions — b8-3b-validator-versioned-schema

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
Author phase: leanings recorded; resolutions are made at /forge:design by an
INDEPENDENT reviewer + the maintainer, NOT self-approved here.

## Resolution log

- (none yet — author-only propose + specify pass; awaiting independent review
  before /forge:design. Q-001..Q-003 open.)
-->

## Q-001: Discovery scope — all archetype dirs vs only `full-stack-monorepo/`

- **Status**: open
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

`[NEEDS CLARIFICATION: Should versioned-schema discovery be scoped to
full-stack-monorepo/ (the only archetype the three validators currently touch),
or applied generically to every .forge/schemas/<archetype>/ dir? If generic, how
do we avoid validating archetypes whose schema.yaml uses a different shape — e.g.
mobile-only/schema.yaml uses archetype:/schema_version:, not name/version/stage —
when no versioned sibling exists there yet?]`

- (a) **Scoped to `full-stack-monorepo/`** — minimal blast radius; matches the
  current validator scope exactly; discovery is a strict superset within that
  one dir. B.9.1 widens scope when `mobile-pwa-first/2.0.0.yaml` lands. Lean
  here for the smallest safe change.
- (b) **Generic across all archetype dirs** — forward-ready; but must only
  validate `<X.Y.Z>.yaml` siblings (which only exist under `full-stack-monorepo/`
  today), never the heterogeneous `schema.yaml` files of the other dirs, so it
  stays a no-op everywhere except `full-stack-monorepo/` until a new versioned
  sibling is authored. More general but larger surface to reason about.

### Resolution

- _Pending — resolved at `/forge:design` by independent reviewer + maintainer._

---

## Q-002: Shared discovery helper vs duplicated inline `python3` across three validators

- **Status**: open
- **Raised in**: `proposal.md` (ADR-B83B-002 seed), `specs.md` FR-B83B-013/020 + NFR-B83B-002
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-3b specify pass)

### Question

The same discovery + per-file validation logic must land in three scripts
(`validate-foundations.sh`, `verify.sh`, `constitution-linter.sh`). Each uses
its own embedded `python3` heredoc today (ADR-002 parsing strategy). Should
B.8.3.b factor a single sourced discovery/validation helper, or duplicate the
discovery inline in each validator?

`[NEEDS CLARIFICATION: Should the versioned-schema discovery + per-file
validation be factored into one shared sourced helper (single source of truth,
but a new shared dependency across three scripts), or duplicated inline per
validator (no new dependency, but three copies that can drift)?]`

- (a) **Single shared helper** — one source of truth, avoids the
  shared-standard/sibling drift the lesson warns about. But introduces a new
  sourced dependency the three scripts must all `source` correctly. Lean here.
- (b) **Duplicated inline `python3`** — matches the current per-function heredoc
  style (ADR-002); no new dependency; but three copies that can diverge over
  time (exactly the drift risk NFR-B83B-002 calls out).

### Resolution

- _Pending — resolved at `/forge:design` by independent reviewer + maintainer._

---

## Q-003: Confirm the scaffolder cannot select a versioned schema (justifying the B.8.14 deferral)

- **Status**: open (author-grounded; maintainer to ratify)
- **Raised in**: `proposal.md` (ADR-B83B-004 seed), `specs.md` FR-B83B-040/041
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-3b specify pass)

### Question

ADR-B83B-004 defers the runtime non-scaffoldability guard to B.8.14 on the
premise that the scaffolder cannot select a versioned schema today. Author
re-read: `cli/src/commands/init.ts` dispatches by archetype **name** via the
dispatch-table + snapshot tarball and does not read
`schemas/<archetype>/schema.yaml`; only `cli/src/commands/upgrade.ts:32`
references the canonical `schema.yaml` path, never a versioned `X.Y.Z.yaml`. This
supports the deferral. The maintainer should ratify that no current or in-flight
scaffolder path (init, upgrade, wizard, auto-detect) can materialize a versioned
or `scaffoldable: false` schema before B.8.14.

`[NEEDS CLARIFICATION: Does any scaffolder entry point (init --archetype / --auto
/ --wizard, or forge upgrade) read a versioned <X.Y.Z>.yaml or honor a
scaffoldable: false flag at runtime today? If yes, a runtime guard cannot be
deferred to B.8.14 and must be in B.8.3.b scope.]`

- (a) **Deferral holds** — scaffolder selects by archetype name + snapshot
  tarball; no versioned-file selection; enforcement in B.8.3.b is the validator
  invariant (`candidate ⇒ scaffoldable: false`), runtime guard at B.8.14. Author
  evidence supports this; lean here.
- (b) **A scaffolder path can already reach a versioned/non-scaffoldable schema**
  — then a minimal runtime guard must be pulled into B.8.3.b scope (would expand
  the brick beyond pure validator rewiring).

### Resolution

- _Pending — resolved at `/forge:design` by independent reviewer + maintainer._
