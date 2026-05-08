# Open Questions — j7-validate-standards-yaml

<!--
Tracking file per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`).
Q-NNN is sequential per change, zero-padded to 3 digits, never reused.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: Should the linter validate `index.yml` triggers reference existing standards?

- **Status**: answered
- **Raised in**: proposal.md (Open Questions)
- **Raised on**: 2026-05-07
- **Raised by**: @bfontaine

### Question

`.forge/standards/index.yml` is the JIT-injection registry that points
the runtime to standards via `path:` fields. A typo or a deleted file
would silently produce orphan triggers (no error at runtime, the
standard just never injects). Should `validate-standards-yaml.sh`
check trigger → file existence as part of its scope, or leave that
to a separate concern (e.g. the JIT injector itself) ?

### Resolution

- **Resolved on**: 2026-05-07
- **Decision**: **YES** — captured as Cluster 5 (FR-J7-050 +
  FR-J7-051) in `specs.md`.
- **Rationale**: One-line yq lookup per trigger ; cost is negligible
  ; closes a real gap (the JIT injector silently no-ops on missing
  files today). Reverse coverage (orphan standards) is informational
  only (`[STD-INFO]`, not blocking) since legacy / pre-T4 files are
  legitimately unindexed.

---

## Q-002: Tolerance window for `expires_at > last_reviewed + 12 months`?

- **Status**: answered
- **Raised in**: proposal.md (Open Questions)
- **Raised on**: 2026-05-07
- **Raised by**: @bfontaine

### Question

`global/standards-lifecycle.md` mandates a 12-month review cycle.
Should the linter enforce **strict 12 months** between `last_reviewed`
and `expires_at`, or allow a `± 30 days` boundary tolerance to avoid
noisy renewals on edge dates ? And how do structural exceptions
(`transport.yaml`, `state-management.yaml`) escape ?

### Resolution

- **Resolved on**: 2026-05-07
- **Decision**: **Strict — `expires_at` MUST be strictly greater
  than `last_reviewed`** (FR-J7-021). No 30-day tolerance. The
  ≥ 12-month invariant is informational only (`[STD-INFO]`,
  FR-J7-022) — emitted but non-blocking, since cycle drift is a
  governance concern, not a syntactic one. Structural exceptions
  use `expires_at: never` paired with `exception_constitutional:
  true` (FR-J7-020 bidirectional coupling).
- **Rationale**: Strict beats loose for invariants enforced by a
  linter ; a tolerance window invites debate on its width and
  ambiguity at the boundary. The opt-out path (`never` +
  constitutional flag) is explicit and already in use by
  `transport.yaml` and `state-management.yaml`.

---

## Q-003: Exact regex for the `constitution-linter.sh` section anchor used by FR-J7-030

- **Status**: answered
- **Raised in**: specs.md FR-J7-030
- **Raised on**: 2026-05-07
- **Raised by**: @bfontaine

### Question

FR-J7-030 says : if `linter_rule` is a non-null string, the validator
verifies that `constitution-linter.sh` contains a matching section
anchor. What pattern locks down "matching section anchor" ?

Candidates :

- **A** : `^# === ${rule} ===` — purely cosmetic header.
- **B** : `^# Rule: ${rule}$` — explicit "Rule:" prefix.
- **C** : function-name pattern `^${rule_underscored}() {` —
  binds to the bash function that implements the check.
- **D** : grep for the literal `${rule}` string anywhere in the
  file (loose) — risk of false positives.

The choice depends on the live convention in `constitution-linter.sh`
which already ships F.4-extended sections (Article V.1, X.3, XI.3,
XI.5). Resolve at `/forge:design` time after grep on the live linter.

### Resolution

- **Resolved on**: 2026-05-07 (via `design.md` ADR-J7-002)
- **Decision**: **Option E (combined)** — structured grep
  `^\s*(echo|#).*\b{rule}\b` (Python regex, multiline). Match a line
  whose first non-space token is `echo` or `#`, ensuring the rule name
  is part of a section header or comment header rather than incidental
  body code (e.g. an argument to `fail "..."`).
- **Rationale**: A live grep on `.forge/scripts/constitution-linter.sh`
  on 2026-05-07 surfaced that the only non-null `linter_rule:` in
  production today (`no-state-management-alternatives`, in
  `state-management.yaml`) is anchored on **two** lines that the
  linter ships with :
  - line 665 : `# ── ADR-006: State Management Discipline (no-state-management-alternatives) — T.4 ──`
  - line 672 : `echo "ADR-006 (State Management Discipline — no-state-management-alternatives):"`
  Candidates A and B do not exist in the live convention. Candidate C
  (function-name) would force a refactor. Candidate D (loose grep)
  matches body code — false positive risk. The combined `(echo|#)`
  anchor matches the actual convention while excluding `fail`/`warn`
  arguments. Robust enough for the kebab-case rule namespace.

---

---

## Q-004: REVIEW.md drift detection scope (FR-J7-023)

- **Status**: answered
- **Raised in**: specs.md FR-J7-023
- **Raised on**: 2026-05-07
- **Raised by**: @bfontaine

### Question

FR-J7-023 mandates that the `version` declared in a standard's
frontmatter MUST appear in the `.forge/standards/REVIEW.md` ledger
for that file. Two reading scopes :

- **A** : Check only the **most recent** entry per standard. Cheap,
  but misses version-rollback accidents (e.g. someone reverts a
  YAML to v1.0.0 while ledger latest is v1.1.0).
- **B** : Scan the **full append-only ledger** for any historical
  mention. More expensive (linear in ledger length) but robust to
  rollback.

Lean toward **B** : the ledger is small (one entry per
standard×review event, currently ≈ 7 entries total), the linear
scan is sub-millisecond, and rollback detection is exactly the
case the linter should catch.

Resolve at `/forge:design` time once the REVIEW.md actual shape
(table vs. heading-based) is read.

### Resolution

- **Resolved on**: 2026-05-07 (via `design.md` ADR-J7-003)
- **Decision**: **Option B — full ledger scan**. The validator parses
  REVIEW.md as plain text and matches a markdown table row regex
  `\|\s*{file_basename}\s*\|\s*{version}\s*\|` (Python multiline).
  Multi-entry per `(file, version)` pair is accepted (N ≥ 1).
- **Rationale**: A live read of `.forge/standards/REVIEW.md`
  (109 lines, 3 entries) on 2026-05-07 confirmed (1) the H2 +
  body-table shape declared in the file's own header schema and
  (2) that `transport.yaml v1.1.0` is intentionally mentioned twice
  (initial bump entry + post-pivot correction entry). Option A
  ("latest entry only") would have rejected the second mention as
  drift, breaking real-world maintenance flows. Option B catches
  the actual failure mode that matters — a version that has *never*
  been recorded — while remaining tolerant of legitimate multi-
  entry maintenance. Sub-millisecond cost on a small ledger.
  Append-only invariant preserved : the validator is read-only on
  REVIEW.md.

---
