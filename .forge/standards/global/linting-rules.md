# Standard: Linting Rules

<!-- Audit: F.4 (f4-linter-extension, FR-LE-018) -->

This standard documents the rules implemented in
`.forge/scripts/constitution-linter.sh`. It complements the
Constitution by specifying the **static-checkable subset** of each
constitutional article. Runtime-only behaviors (e.g. Article V.2
violation handling) are explicitly excluded from static linting.

Activated by `.forge/standards/index.yml` triggers on `linting`,
`constitution-linter`, `linter rules`, `public API doc`, `fallback
test`, `GenUI schema`, `audit trail`.

---

## Purpose

The Constitution declares process and quality rules ; the linter
mechanises a subset of them. F.4 added 4 new rules covering V.1,
X.3, XI.3, XI.5 — articles previously not enforced. This standard
records :

- Which articles are statically checked (with their FR-LE-NNN
  references).
- The heuristics each rule uses (and their known limitations).
- The opt-out mechanism (env vars) for adopters with specific
  constraints.
- The procedure for adding a new rule (Article XII governance
  amendment process).

---

## Article V.1 — Task ↔ FR Linkage

**FR-LE-001..003.** For each change with `status` ∈ {`planned`,
`implemented`, `archived`}, `tasks.md` MUST contain at least one
`[Story: FR-XXX]` reference. This proves an audit trail exists
between implementation tasks and functional requirements.

**Heuristic** : `grep -qE '\[Story: FR-' tasks.md`. Strict
1-per-task is intentionally NOT enforced — admin tasks (commit,
push, etc.) may legitimately not map to a single FR.

**Limitations** : the rule does not verify that referenced FR-XXX
identifiers actually exist in `specs.md`. A future F.5+ rule could
cross-validate.

**Opt-out** : `FORGE_LINTER_SKIP_V_1=1`.

**Skip-guard** : `examples/` subtrees (FR-GL-026 cohérent).

---

## Article X.3 — Public API Documentation

**FR-LE-004..009.** Each public symbol declaration in Dart (`lib/`)
or Rust (`src/`) MUST be preceded by a `///` (or `//!` for Rust)
documentation comment. The aggregate ratio
`documented / total` MUST be ≥ `FORGE_LINTER_X3_THRESHOLD` (default
80%).

**Heuristic — Dart** : grep at start-of-line for
- `class [A-Z]` (top-level class)
- `abstract class [A-Z]`
- `enum [A-Z]`
- `mixin [A-Z]`
- `[A-Z][...] [a-z][...]\(` (top-level typed function)

For each match, walk back through blank lines and `@`-attribute
lines ; check whether the preceding non-blank, non-attribute line
matches `^\s*///`.

**Heuristic — Rust** : grep `^pub\s+(fn|struct|enum|trait|const|static|type|impl)\b`.
Walk back through blank lines and `#[...]` attributes ; check
preceding line for `^\s*(///|//!)`.

**Limitations** :
- Multi-line declarations (e.g. generic parameters split across
  lines) may be missed.
- The 80% threshold tolerates incremental migration.

**Opt-out** :
- `FORGE_LINTER_SKIP_X_3=1` disables the rule entirely.
- `FORGE_LINTER_X3_THRESHOLD=<n>` overrides the default ratio (e.g.
  `FORGE_LINTER_X3_THRESHOLD=50` during early migration).

**Skip-guard** : if no `lib/**/*.dart` or `src/**/*.rs` files
exist, the rule emits `not_applicable` (no source dirs found).

---

## Article XI.3 — Generative UI Schema (Warning)

**FR-LE-010..013.** Detects co-presence of AI features and UI
rendering without a referenced `*.schema.json`, indicating a
potential XI.3 violation (direct AI-generated UI code instead of
schema-driven rendering).

**Heuristic** :
1. AI presence = `schema: ai-first` in root `.forge.yaml` OR grep
   `anthropic|openai|gpt-|claude|@google/genai|llm|langchain` in
   `lib/`, `src/`, `pubspec.yaml`, `Cargo.toml`, `package.json`.
2. UI rendering = grep `class .*Widget|extends Widget|render *\(`
   in `lib/` or `src/`.
3. Schema reference = exists `*.schema.json` file OR grep
   `\.schema\.json` in source.

**Output** :
- AI absent → `not_applicable`.
- AI + no UI → `pass`.
- AI + UI + schema → `pass`.
- AI + UI + no schema → **WARN** (not FAIL).

**Limitations** : XI.3 is fundamentally dynamic. The static
heuristic produces a warning that prompts manual audit ; it does
not prove a violation. A FAIL would create too many false
positives.

**Opt-out** : `FORGE_LINTER_SKIP_XI_3=1`.

---

## Article XI.5 — Fallback Testing

**FR-LE-014..017.** Article XI.5 requires every AI-powered feature
to have a tested fallback. The static check : every file matching
`lib/**/*[fF]allback*.dart` or `src/**/*[fF]allback*.rs` MUST have
a corresponding test pair.

**Pair detection** :
- Dart : `test/**/*[fF]allback*_test*.dart` OR
  `test/**/*[fF]allback*.dart` (any test naming containing
  "fallback").
- Rust : `tests/**/*[fF]allback*.rs` OR the source file itself
  contains `#[cfg(test)]` or `#[test]` (in-file unit tests).

**Output** :
- No fallback files + non-`ai-first` schema → `not_applicable`.
- No fallback files + `ai-first` schema → **FAIL** (Article XI.5
  requires a fallback implementation).
- Fallback file with pair → `pass`.
- Fallback file without pair → **FAIL** with file path.

**Limitations** : the rule is convention-based. Adopters using
non-`fallback` naming (e.g. `*_offline*`, `*_degraded*`) are not
detected — they should rename or opt-out.

**Opt-out** : `FORGE_LINTER_SKIP_XI_5=1`.

---

## Opt-Out Mechanism

All four F.4 rules support per-rule opt-out via environment
variables. Setting any variable to `1` skips the corresponding
rule entirely (the section emits `skipped via <VAR>` and contributes
neither pass nor fail to the summary).

| Env var | Effect |
| --- | --- |
| `FORGE_LINTER_SKIP_V_1=1` | Skip Article V.1 (task ↔ FR linkage) |
| `FORGE_LINTER_SKIP_X_3=1` | Skip Article X.3 (public API doc) |
| `FORGE_LINTER_SKIP_XI_3=1` | Skip Article XI.3 (GenUI warning) |
| `FORGE_LINTER_SKIP_XI_5=1` | Skip Article XI.5 (fallback test) |
| `FORGE_LINTER_X3_THRESHOLD=<0..100>` | Override X.3 ratio threshold (default 80) |

Adopters SHOULD use opt-outs sparingly and document the rationale
in their project's `CLAUDE.md` or equivalent. The opt-out is for
**incremental migration** or **non-applicable contexts**, not for
permanent disable.

### Adding a new rule

Adding a new rule to `constitution-linter.sh` is a structural
change to the framework's quality gates. It requires :

1. **Constitution amendment** (Article XII Governance amendment
   process) — public 7-day discussion + BDFL ratification.
2. **F.x change** (e.g. F.5+) implementing the rule with full
   spec / design / plan / harness pipeline.
3. **Backward compatibility audit** — the new rule MUST NOT cause
   any existing change archived under prior Constitution versions
   to FAIL the linter retroactively (or, if it does, those changes
   need a change-amendment via the standard process).
4. **Update of this standard** — new section + opt-out env var
   listed above.

A rule MUST NOT be tightened (lower threshold, stricter heuristic)
without going through the same process.
