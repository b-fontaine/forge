# Open Questions — f4-linter-extension

<!--
Per the Forge convention defined in
`.forge/standards/global/open-questions.md` (F.1 mechanisation of
Article III.4).
-->

## Q-001: How to enforce Article V (Constitutional Compliance Gate) statically?

- **Status**: answered
- **Raised in**: proposal.md § "Solution"
- **Raised on**: 2026-05-01
- **Raised by**: clio (spec writer)

### Question

Article V.1 lists 5 pre-implementation checks. V.2/V.3 runtime, not
static-checkable. The most actionable V.1 sub-check at lint time is
**task ↔ FR linkage** : every task in `tasks.md` should reference a
`[Story: FR-XXX]` marker.

Trade-off : strict 1-per-task risks blocking admin tasks (commit, push)
that don't map to a single FR.

Recommendation : check that `tasks.md` (when status ≥ planned) contains
AT LEAST 1 `[Story: FR-` reference (proves audit trail exists).

### Resolution

- **Resolved on**: 2026-05-01
- **Resolved by**: user (Benoit Fontaine, BDFL)
- **Decision**: ≥ 1 `[Story: FR-` reference in tasks.md when status ≥ planned.
- **Rationale**: balanced — proves audit trail without blocking admin tasks. Stricter 1-per-task could be added in F.5+ if false-negatives are spotted.
- **Resolved in**: proposal.md § "Décisions ouvertes — résolues"

## Q-002: X.3 doc-comment heuristic strictness?

- **Status**: answered
- **Raised in**: proposal.md § "Solution"
- **Raised on**: 2026-05-01
- **Raised by**: clio

### Question

Detect "public API" with grep is fragile. Three strategies considered:
heuristic FAIL, threshold ratio, skip-on-no-language.

Recommendation : skip when no source dirs found (Forge framework repo
itself has no Dart/Rust source), then ratio threshold 80% when source
exists. Configurable via env var.

### Resolution

- **Resolved on**: 2026-05-01
- **Resolved by**: user
- **Decision**: ratio threshold 80%, skip if no Dart/Rust source dir.
- **Rationale**: tolerates incremental migration ; the framework repo
  itself returns `not_applicable` (no source). Adopters with stricter
  needs can lower the threshold via env var or PR.
- **Resolved in**: proposal.md

## Q-003: XI.3 GenUI schema-driven detection?

- **Status**: answered
- **Raised in**: proposal.md § "Solution"
- **Raised on**: 2026-05-01
- **Raised by**: clio

### Question

XI.3 is dynamic. Static linting has 3 options : pattern-grep AI imports,
defer to runtime, declarative manifest in .forge.yaml.

Recommendation : warning heuristic only (no FAIL). Document the
limitation in the standard.

### Resolution

- **Resolved on**: 2026-05-01
- **Resolved by**: user
- **Decision**: warning-only heuristic. Active when schema=ai-first OR
  AI imports detected ; emits warning if Widget/render code present
  without coexisting `*.schema.json` references.
- **Rationale**: avoids false-positive FAIL on legitimate AI features
  with non-grep-detectable schemas. Adopters audit manually based on
  the warning.
- **Resolved in**: proposal.md

## Q-004: XI.5 fallback testing — name-based heuristic?

- **Status**: answered
- **Raised in**: proposal.md § "Solution"
- **Raised on**: 2026-05-01
- **Raised by**: clio

### Question

Three options : (a) name-based pair, (b) annotation-based,
(c) defer to BDD.

Recommendation : (a) name-based with FAIL on missing test pair, document
the naming convention in the AI-First standard.

### Resolution

- **Resolved on**: 2026-05-01
- **Resolved by**: user
- **Decision**: (a) name-based pair `*fallback*` ↔ `*fallback*_test*`,
  FAIL if source exists without test pair. Skip if schema != ai-first
  AND no `*fallback*` files at all.
- **Rationale**: enforces XI.5 "fallback MUST be tested" with minimal
  adopter friction (just a naming convention). Adopters who can't
  follow naming use opt-out env var. Documented.
- **Resolved in**: proposal.md
