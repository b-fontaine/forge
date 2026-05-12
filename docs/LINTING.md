# Linting Rules

<!-- Audit: F.4 (f4-linter-extension, FR-LE-020) -->

This guide complements the standard
[`global/linting-rules.md`](../.forge/standards/global/linting-rules.md)
and covers practical concerns — how to run the linter, how to
debug a FAIL, how to opt out of a rule, and the heuristic
limitations adopters should be aware of.

## Running the linter

```bash
bash .forge/scripts/constitution-linter.sh
```

Exit codes :

- `0` : OVERALL PASS (no FAIL emitted ; warnings tolerated).
- `1` : OVERALL FAIL (one or more FAIL emitted).

The linter is also wired into the `forge-ci.yml` `gates` job,
so every PR passes through it.

## Rules covered

The linter currently enforces (post F.4) :

| Article                                  | Rule                                                      | Source change |
|------------------------------------------|-----------------------------------------------------------|---------------|
| Article I (TDD)                          | partial — test files presence                             | foundations   |
| Article II (BDD)                         | partial — AC count in changes                             | foundations   |
| Article III (Specs Before Code)          | artifact completeness                                     | foundations   |
| Article III.4 (Anti-Hallucination)       | no `[NEEDS CLARIFICATION:` inline in implemented/archived | F.1           |
| Article IV (Delta Format)                | ADDED/MODIFIED/REMOVED markers                            | foundations   |
| **Article V.1 (Compliance Gate)**        | task ↔ FR linkage                                         | **F.4**       |
| Article VI / VII (Flutter / Rust)        | partial — module structure                                | foundations   |
| Article VIII (Infra)                     | Dockerfile multi-stage                                    | foundations   |
| Article IX (Observability)               | partial — OTel imports                                    | foundations   |
| Article X.1 / X.2 (Modules + boundaries) | partial — heuristic                                       | foundations   |
| **Article X.3 (Public API doc)**         | ratio ≥ 80% (default)                                     | **F.4**       |
| Article X.4 (No unresolved TODOs)        | TODO format check                                         | foundations   |
| Article X.5 (Static analysis)            | analyze / clippy presence                                 | foundations   |
| **Article XI.3 (GenUI)**                 | warning heuristic                                         | **F.4**       |
| **Article XI.5 (Fallback tested)**       | name-based pair                                           | **F.4**       |

## Common errors

### `Article V: <change>: tasks.md missing [Story: FR-XXX] audit trail`

Your change has `status: planned` (or later) but `tasks.md` does
not contain any `[Story: FR-XXX]` reference. Forge requires every
implementation task to be traceable to a functional requirement.

**Fix** : annotate at least one task with the related FR :

```markdown
- [ ] **T001** Implement the authentication flow [Story: FR-001]
```

You don't need to annotate EVERY task (admin tasks like "commit"
or "push" don't need an FR), but at least one must show the
audit trail.

### `Article X.3: doc ratio 60% (12/20) below threshold 80%`

Your Dart or Rust source has too many undocumented public symbols.
The linter lists the first 5 missing-doc symbols. Add `///` doc
comments above each :

```dart
/// Validates the user input and returns true if valid.
bool validate(String input) {
  ...
}
```

```rust
/// Validates the user input and returns Ok(()) if valid.
pub fn validate(input: &str) -> Result<(), Error> { ... }
```

If you're in a migration phase, lower the threshold temporarily :

```bash
FORGE_LINTER_X3_THRESHOLD=50 bash .forge/scripts/constitution-linter.sh
```

### `Article XI.3 heuristic warning: AI features + UI rendering...`

The linter detected AI imports (`anthropic`, `openai`, `claude`,
etc.) AND UI rendering code (`Widget`, `render`) WITHOUT a
referenced `*.schema.json`. This is a **warning**, not a fail —
manually audit whether your AI generates UI directly (a XI.3
violation) or goes through a schema (compliant).

If your project has compliant XI.3 but uses naming the heuristic
can't detect, opt out :

```bash
FORGE_LINTER_SKIP_XI_3=1 bash .forge/scripts/constitution-linter.sh
```

### `Article XI.5: lib/foo_fallback.dart has no matching *fallback*_test*`

You have a fallback implementation but no test pair. Article XI.5
requires fallbacks to be tested.

**Fix** : create `test/foo_fallback_test.dart` with `bloc_test`
or equivalent, exercising the fallback path.

If your project uses different naming (`*_offline*`, `*_degraded*`),
either rename to follow the `*fallback*` convention or opt out :

```bash
FORGE_LINTER_SKIP_XI_5=1 bash .forge/scripts/constitution-linter.sh
```

## Opt-out env vars

| Env var                         | Effect                                |
|---------------------------------|---------------------------------------|
| `FORGE_LINTER_SKIP_V_1=1`       | Skip Article V.1                      |
| `FORGE_LINTER_SKIP_X_3=1`       | Skip Article X.3                      |
| `FORGE_LINTER_SKIP_XI_3=1`      | Skip Article XI.3                     |
| `FORGE_LINTER_SKIP_XI_5=1`      | Skip Article XI.5                     |
| `FORGE_LINTER_X3_THRESHOLD=<n>` | Override X.3 ratio threshold (0..100) |

These are intended for **incremental migration** or **non-applicable
contexts**. Document the rationale in your project's CLAUDE.md.

## Heuristic limitations

The four F.4 rules use grep + python heuristics, not full AST
parsing. Known limitations :

- **X.3** : multi-line declarations (e.g. generic parameters split
  across lines) may be missed by the regex.
- **XI.3** : warning-only by design ; cannot prove a violation
  statically.
- **XI.5** : convention-based ; non-`fallback` naming requires
  rename or opt-out.
- **V.1** : doesn't cross-validate that referenced FR-XXX exist in
  specs.md (a future F.5+ rule).

## ADR-I3-001 — T3-Forbidden Components

The T3-Forbidden section of `constitution-linter.sh` walks every
`.forge/standards/*.yaml` manifest and parses the optional
`forbidden:` list in the frontmatter. Each forbidden token is
matched against the manifest body, every other standard's body,
and ADR text. Violations are reported with rule IDs
`T3-RULE-001..NNN` documented in
[`forbidden-components-rules.md`](../.forge/standards/global/forbidden-components-rules.md).

**Severity scaling** (resolved by ADR-I3-002 — see
`design.md` in the i3 change archive) :

| Tier (from `.forge/.forge-tier`) | Severity         |
|----------------------------------|------------------|
| absent / N/A                     | skipped          |
| T1                               | `WARN` (Phase A) |
| T2                               | `WARN` (Phase A) |
| T3                               | `FAIL` (immediate, no rollout) |

The Phase A → B flip will happen at the B.8 / T6 milestone via a
SemVer minor bump of `forbidden-components-rules.md`
(`1.0.0 → 1.1.0`). T3 is `FAIL` from day one because the tier
declares 100 % EU jurisdiction — a forbidden component is by
definition unacceptable in that context.

**Opt-out** : `FORGE_LINTER_SKIP_T3_FORBIDDEN=1` skips the entire
section. Intended for incremental adoption only ; document the
rationale in your project's `CLAUDE.md`.

## See also

- Standard : [`linting-rules.md`](../.forge/standards/global/linting-rules.md)
- Constitution : [`constitution.md`](../.forge/constitution.md)
- Linter source : [`.forge/scripts/constitution-linter.sh`](../.forge/scripts/constitution-linter.sh)
