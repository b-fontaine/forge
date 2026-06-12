# Proposal: b7-2a-dispatch-register

<!-- Created: 2026-06-12 -->
<!-- Schema: default -->
<!-- Audit: B.7.2 (docs/new-archetypes-plan.md §6.2 — ai-native-rag scaffolder; first slice: dispatch registration) -->

## Problem

B.7.1 shipped `.forge/schemas/ai-native-rag/1.0.0.yaml` (candidate,
scaffoldable:false) but **did not register the archetype in the CLI dispatch
table**. The independent review of `b7-1-schema` (Q-005) found that
`forge init --archetype ai-native-rag` therefore refuses with **exit 2**
("unknown archetype") at the dispatch-table gate (`init.ts:210`), never reaching
the intended schema-version refusal (exit 3). Both are clean refusals, but exit 3
is the canonical "registered archetype with no scaffoldable schema version"
state (the deferred B.8.3.b guard). This change is the first additive slice of
B.7.2: register the archetype so the refusal becomes exit 3, resolving Q-005. It
ships **no templates, no scaffold-plan, no standards, no pins** — the archetype
stays non-scaffoldable.

**Ground truth (re-read 2026-06-12, Article III.4):**

- **dispatch-table entry schema** (`.forge/scaffolding/dispatch-table.yml`,
  FR-IW-002): `name` (== map key), `scaffolder` (`<built-in>` | repo-relative
  shell path), `description`, `signals` (list), `since` (SemVer). The parser
  (`cli/src/domain/dispatch-table.ts`) also tolerates `status`. `ai-native-rag`
  is absent; `default` / `full-stack-monorepo` / `mobile-only` / `flutter-firebase`
  are present.
- **The unknown-archetype gate** `init.ts:210-216` returns **exit 2** for any
  archetype not in `dispatchTable.archetypes`. Registering ai-native-rag removes
  this gate for it, so control reaches the versioned-schema layer.
- **The refusal path** `init.ts:225-238` → `resolveScaffolder`
  (`init-archetype.ts:128-154`): with `metas.length > 0` and
  `selectScaffoldableVersion(metas) === null` it returns `{kind:"refuse"}` →
  **exit 3**, *without touching the scaffolder path*. `readArchetypeSchemas`
  (`cli.ts:135-156`) is **generic** — it reads `<assets>/.forge/schemas/
  <archetype>/*.yaml` for any archetype via `parseSchemaMeta`. So for
  ai-native-rag it returns `[{1.0.0, candidate, scaffoldable:false}]` (non-empty)
  → `selectScaffoldableVersion` null → exit 3. **Verified by reading the code.**
  (If `metas` were empty — e.g. schema not bundled — line 137 falls back to legacy
  `kind:"ok"` and would try to run the wrapper; hence the schema MUST be bundled
  into `cli/assets` alongside the dispatch entry, which `npm run bundle` does.)
- **The scaffolder-exists gate** `b5.test.sh::test_dispatch_scaffolders_exist`
  (FR-IW-002, lines 142-165) statically requires every entry's `scaffolder` to be
  a real file, OR the sentinel `<built-in>`/`<removed>`, OR `status:
  removed_from_roadmap`. So a registered ai-native-rag entry pointing at a
  non-existent script would FAIL this gate.
- **The documented ABI** (dispatch-table.yml header): "Adding a new archetype =
  (1) appending one entry here + (2) writing the corresponding
  `bin/forge-init-<archetype>.sh` wrapper following the stable ABI declared in
  `global/scaffolding.md`."
- **Framework version** is `0.4.0` (`cli/package.json`, `cli/VERSION`); the
  `[Unreleased]` CHANGELOG section is the next cut (→ ADR-B7-2A / Q-001 for the
  `since:` value).

## Solution

Register `ai-native-rag` and ship a **refusing wrapper** so the refusal flips to
exit 3 cleanly, with no scaffold capability added.

1. **Dispatch entry** in `.forge/scaffolding/dispatch-table.yml`:
   `name: ai-native-rag`, `scaffolder: bin/forge-init-ai-native-rag.sh`,
   `description` (one-line), `signals: []` (no `--auto` detection yet),
   `since:` (the next framework version). Optional `status:` marker documenting
   not-yet-scaffoldable.
2. **`bin/forge-init-ai-native-rag.sh`** — a thin wrapper that **refuses**
   (exit 3) with a clear "ai-native-rag is not yet scaffoldable (candidate
   schema; the B.7.2 scaffolder + templates are not shipped yet)". This satisfies
   `test_dispatch_scaffolders_exist` (real file), follows the documented
   entry+wrapper ABI, and is the wrapper-side defense-in-depth layer (mirroring
   `_refuse_if_forbidden`, J.8) for the case where the CLI guard is bypassed. The
   CLI's own `resolveScaffolder` refusal (exit 3) fires *first*, so the wrapper
   is belt-and-suspenders today; B.7.2-full replaces its body with the real
   scaffold logic.
3. **Flip `b7-1.test.sh` L2** (`_test_b71_l2_001_init_refuses`): the verified
   live exit is now **3** (registered + non-scaffoldable), not 2. Update the
   assertion + docstring (the prior code already flagged this flip "once B.7.2
   registers it").
4. **Harness `b7-2a.test.sh`**: dispatch entry present & well-formed; wrapper
   exists/executable/refuses exit 3 when invoked directly; (opt-in live) the CLI
   refuses ai-native-rag with exit 3.

Decisions reserved for `/forge:design` (ADRs), leanings stated:

- **ADR-B7-2A-001 — refusing wrapper vs sentinel scaffolder.** Lean: **refusing
  wrapper** (option above). Alternative — `scaffolder: "<pending>"` sentinel +
  teaching `b5.test.sh` to skip it — is rejected: it edits an existing test and
  diverges from the documented entry+wrapper ABI.
- **ADR-B7-2A-002 — refusal exit code = 3.** Lean: exit 3 (the B.8.3.b
  not-scaffoldable refusal + the J.8 policy-refusal convention), consistent
  between the CLI guard and the wrapper.
- **ADR-B7-2A-003 — wrapper message + non-destructiveness.** Lean: structured
  stderr (`[REFUSAL: ai-native-rag: not-yet-scaffoldable ...]`), exit 3, zero
  filesystem writes.

## Scope In

- `.forge/scaffolding/dispatch-table.yml` — one `ai-native-rag` entry.
- `bin/forge-init-ai-native-rag.sh` — refusing wrapper (exit 3, no writes).
- `.forge/scripts/tests/b7-1.test.sh` — L2 assertion flip (exit 2 → exit 3).
- `.forge/scripts/tests/b7-2a.test.sh` — new harness; registered in `forge-ci.yml`.
- Change artifacts (`proposal/specs/design/tasks/open-questions`).

## Scope Out (Explicit Exclusions)

- **Templates / scaffold-plan** `templates/archetypes/ai-native-rag/**` — B.7.2-full.
- **Standards** llm-gateway/mcp-servers/rag-patterns — B.7.3.
- **Version pins** (`rmcp`, pgvector crate) — verify-then-pin in B.7.2-full/B.7.3.
- **Promotion to stable/scaffoldable** — the schema stays candidate; promotion is
  the B.7 scaffolder-completion brick (gated on a green b7-6 harness, ADR-B7-1-002).
- **The real scaffold body** of the wrapper — B.7.2-full.
- **`--auto` signals** — left empty (no detection heuristics for ai-native-rag yet).

## Impact

- **Users**: `forge init --archetype ai-native-rag` now refuses with exit 3 (was
  exit 2). Still no scaffold produced — the archetype is announced as "known but
  not yet available". No other archetype's behaviour changes.
- **Technical**: one dispatch entry + one refusing wrapper + test updates. The
  runtime flip relies on the schema being bundled into `cli/assets` (done by
  `npm run bundle` at build, as for every archetype).
- **Dependencies**: B.7.1 (the schema) + B.8.14 (the CLI refusal path). Unblocks
  the full B.7.2 scaffolder + B.7.3 standards (which flesh out the wrapper).

## Constitution Compliance

- **III.1/III.2 (Specs before code)**: propose+specify first; TDD at impl
  (b7-2a harness RED before the entry/wrapper).
- **III.4 (Anti-Hallucination)**: every claim (refusal precedence, generic
  readArchetypeSchemas, the b5 scaffolder-exists gate, the ABI) re-read from live
  code; the `since:` value is flagged as an open question, not guessed.
- **IV (Delta-based)**: additive — the dispatch entry + wrapper are new; the only
  existing-file edits are the dispatch table (append), the b7-1 L2 assertion
  (reflecting verified new behaviour), and the CI matrix (harness registration).
- **V (Compliance gate)**: ADRs map to design resolutions; independent review +
  maintainer ratification before archive.
- **XII (Governance)**: no Constitution amendment.

## Open Questions (seed)

- **Q-001** — `since:` value for the dispatch entry (0.5.0 next-minor vs 0.4.1
  patch) — verify against `docs/VERSIONING.md` at design.
- **Q-002** — does the entry carry a `status:` marker (e.g. `candidate` /
  `not_scaffoldable`) for human clarity, and if so should `b5.test.sh` treat it
  specially? (Leaning: a documentary `status:` is harmless; no b5 change needed
  because the wrapper file exists.)
