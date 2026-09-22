# Specs — `t8-example-tree-pins`

**Namespace** : `FR-T8ETP-*`, `NFR-T8ETP-*`, `ADR-T8ETP-*`.

---

## Functional Requirements

### FR-T8ETP-001 — the shipped example carries the framework's pins

`examples/forge-rag-example/frontend/web-public/package.json` MUST equal the rendered
`ai-native-rag/1.0.0` template manifest: `overrides.sharp` per `web-frontend.yaml`
`versions.sharp`, `vite` = `=` + `versions.vite`, the `ignore` devDependency at
`versions.ignore`, and the same `typescript` / `@types/node` / `vite-tsconfig-paths`
pins. `npm audit --audit-level=high` on that manifest MUST exit 0.

### FR-T8ETP-002 — the example's other drifted files follow the template

`README.md` (pin table, including the `sharp` row) and `vite.config.ts` (the pin comment)
MUST equal their rendered templates. No other file in that subtree changes: the
render-vs-example diff is exactly these three files.

### FR-T8ETP-003 — the guards discover example surfaces

`b8-9::T-013` and `::T-014` MUST discover Qwik surfaces from **two** roots:
`.forge/templates/**/package.json.tmpl` and `examples/**/package.json` (excluding
`node_modules`). Every discovered surface is held to the same standard values; T-014's
README sibling is derived from the discovered path (`.tmpl` suffix only where the source
has one), never hardcoded.

### FR-T8ETP-004 — the widened discovery cannot pass vacuously

Each test MUST fail when it discovers zero surfaces under `examples/`, not only when it
discovers zero surfaces overall: a floor that a template surface can satisfy would hide
exactly the blind spot this brick closes.

### FR-T8ETP-005 — the sentences that claimed "every surface" become true or go

`web-frontend.yaml`'s `versions` comments and `b8-9`'s T-013/T-014 headers MUST describe
the two roots they now sweep. `t7-qwik-deps-refresh` Q-004 is resolved and the records
that said the example was "still affected" (CHANGELOG Security entry, roadmap) are
corrected in the same commit.

---

## Non-Functional Requirements

### NFR-T8ETP-001 — no forge-ci.yml line

The widening lives in `b8-9.test.sh`, already registered. `forge-ci.yml` stays at 421 of
the 440 `NFR-CI-002` budget; the ~19 remaining lines stay reserved for B.3.

### NFR-T8ETP-002 — guards mutation-proven

Every new failure path RED before GREEN, each probe naming the offending file, every file
restored byte-identical.

### NFR-T8ETP-003 — the example is a render, not an edit

The three files are produced by substituting the template, not hand-patched, so the tree
stays what `examples/README.md` says it is.

---

## ADRs

### ADR-T8ETP-001 — widen the discovery root rather than enumerate the examples

**Context.** Three ways to stop example drift: patch the files and move on; list the
example manifests in the guards; or widen the discovery root.

**Decision.** Widen the root: `.forge/templates/**/package.json.tmpl` ∪
`examples/**/package.json`.

**Rationale.** ADR-T5QCI-002 already chose discovery over enumeration for T-013, and for
the same reason: a fourth surface added later inherits the guard with no edit. An
enumeration would have to be remembered exactly when it is forgotten — which is how this
defect survived two sweeps. The framework standard owns the pin for every surface that
ships, and an example ships.

**Consequence.** Any example added later is held to the framework pins from its first
commit, and an example that legitimately must diverge has to say so by failing the guard
and being argued about — not by being invisible.
