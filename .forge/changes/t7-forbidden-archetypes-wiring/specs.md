# Specs — `t7-forbidden-archetypes-wiring`

**Namespace** : `FR-T7FA-*`, `NFR-T7FA-*`, `ADR-T7FA-*`.

---

## Functional Requirements

### FR-T7FA-001 — the parser reads `forbidden_archetypes:`

`parseDispatchTable` MUST return the top-level `forbidden_archetypes:` list, each entry
carrying `name`, `reason`, `since`, `alternative`, `rule_id` — the five keys
`ForbiddenArchetypeEntry` already declares.

Grammar, matching the file it parses: a top-level `forbidden_archetypes:` key, then
`  - name: <scalar>` at two-space indent, then `    <key>: <scalar>` at four. Parsing
MUST stop at the next top-level key (`forbidden_combinations:` follows immediately).

### FR-T7FA-002 — the refusal fires, unchanged

`forge init --archetype flutter-firebase` MUST exit **3** and print
`[REFUSAL: flutter-firebase: J8-RULE-001: <reason> ; alternative: <alternative>]` on
stderr.

Exit code, message shape and the check's position before any wrapper invocation are
`ADR-J8-003`'s contract. This change makes them reachable; it does not alter them.

### FR-T7FA-003 — nothing is rendered on refusal

The refusal already precedes every filesystem effect. A test MUST assert no directory
is created, because "refuses cleanly" is the property, not "exits 3".

### FR-T7FA-004 — the refusal is covered end to end

A Vitest case in `cli/test/` MUST drive the built CLI and assert FR-T7FA-002 and
FR-T7FA-003. J.8 shipped this path with no test that runs it; the parse fix without
that test would leave the next regression equally invisible.

### FR-T7FA-005 — parsed set matches the YAML

A shell guard MUST assert that every `forbidden_archetypes` entry in
`.forge/scaffolding/dispatch-table.yml` is reachable through the parser, keyed on
`name` and `rule_id`. This is the drift guard: a sixth key added to the YAML, or a new
forbidden archetype, must not silently fail to parse.

### FR-T7FA-006 — CHANGELOG

`[Unreleased]` entry.

---

## Non-Functional Requirements

### NFR-T7FA-001 — no third-party YAML dependency

`parseDispatchTable` is a hand-rolled subset parser by `NFR-IW-002`. The addition stays
inside that constraint — no `js-yaml`, no new package.

### NFR-T7FA-002 — the archetype grammar is untouched

Parsing `forbidden_archetypes:` MUST NOT change how any `archetypes:` entry parses. The
four-space field matcher currently fires whenever `currentName` is set; the new block
MUST clear that state rather than compete with it.

Asserted by the existing suite staying green, not by inspection.

### NFR-T7FA-003 — the `--help` goldens do not move

`cli/test/e2e/__snapshots__/help/*.snap.txt` are the CLI surface contract (`NFR-T51-010`).
This change adds no flag and no usage text.

---

## ADRs

### ADR-T7FA-001 — fix the parser, not the caller

**Context.** The refusal could also be made reachable by reading the YAML again at the
call site, or by hard-coding the one forbidden archetype.

**Decision.** Teach `parseDispatchTable` the block it already has a type for.

**Rationale.** `DispatchTable` declares `forbidden_archetypes?: ForbiddenArchetypeEntry[]`
and `runArchetypeInit` consumes it. The type, the caller and the data all exist and
agree; only the producer is missing. Anything else adds a second reader of the same
file — the shape that lets two sources of truth drift.

**Consequence.** Every consumer of `parseDispatchTable` sees the field, including
`cli/test/e2e/archetypes-smoke.test.ts`, which reads the same table. That is desirable:
a future smoke test can exclude forbidden archetypes from its matrix without re-reading
the file.

### ADR-T7FA-002 — `forbidden_combinations:` stays out

**Context.** The sibling list sits directly below and has the same shape problem on its
face.

**Decision.** Not parsed here.

**Rationale.** It is **not** dead code: `_refuse_if_forbidden_combination` in
`bin/_forge-init-helpers.sh` reads the YAML wrapper-side and fires. Adding a second,
CLI-side reader would create two implementations of `ai-native-rag`'s provider × tier
refusals, which is another module's contract and a different decision.

**Consequence.** The CLI refuses forbidden *archetypes* and the wrappers refuse
forbidden *combinations*. Asymmetric, and worth revisiting — recorded as Q-001 rather
than resolved by a parser change nobody asked for.
