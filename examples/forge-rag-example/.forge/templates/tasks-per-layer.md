<!-- Audit: B.1.6 (part of b1-workflow, per-layer tasks template) -->
<!-- Layer: <layer-id> — replace <layer-id> with backend / frontend / infra when copying -->
<!-- TDD order mandatory: tests BEFORE implementation, always (Article I) -->
<!-- Format: - [ ] Task [Story: FR-<PFX>-XXX] [P] -->
<!-- Phase headings use the layer prefix convention (ADR-010): `<Layer> Phase N`. -->

# Tasks: <change-name> (<layer-id>)

## Cross-Layer References

<!-- FIRST section, consistent with design-per-layer.md (FR-GL-020).
     List the FR-GL-* requirements this layer's slice addresses and link
     to the sibling design file for context. -->

- This task file covers the `<layer-id>` slice of **FR-GL-XXX** (see `specs.md`).
- Sibling design file: `design-<layer-id>.md` (or as declared in `.forge.yaml tasks_per_layer`).
- Other layer task files: <!-- e.g. tasks-backend.md, tasks-frontend.md -->

---

## <Layer> Phase 1 — Foundation (RED tests + port definitions)

<!-- Write ALL failing tests before any implementation code.
     Verify each test is actually RED before proceeding to Phase 2. -->

### 1.1 Domain model

- [ ] RED: add failing unit test for `<!-- entity or value object -->` [Story: FR-<PFX>-XXX]
- [ ] Verify RED: run test suite, confirm failure [Story: FR-<PFX>-XXX]
- [ ] GREEN: minimal implementation to pass the test [Story: FR-<PFX>-XXX]
- [ ] REFACTOR: ensure naming, extract duplication [Story: FR-<PFX>-XXX]
- [ ] Verify: tests PASS [Story: FR-<PFX>-XXX]

### 1.2 Port / interface definitions

- [ ] RED: add failing test for `<!-- repository interface or port -->` [Story: FR-<PFX>-XXX]
- [ ] Verify RED [Story: FR-<PFX>-XXX]
- [ ] GREEN: define interface / port contract [Story: FR-<PFX>-XXX]
- [ ] Verify: tests PASS [Story: FR-<PFX>-XXX]

### 1.3 BDD feature file

- [ ] Write BDD feature file for primary scenario (Given/When/Then) [Story: FR-<PFX>-XXX]
- [ ] Verify: step definitions compile, scenario tagged as @wip [Story: FR-<PFX>-XXX]

---

## <Layer> Phase 2 — Core Implementation (GREEN)

<!-- Implement the minimal code required to turn all RED tests GREEN.
     No gold-plating; stay within this layer's boundary. -->

### 2.1 Application use-cases

- [ ] RED: add failing test for `<!-- use case -->` [Story: FR-<PFX>-XXX]
- [ ] Verify RED [Story: FR-<PFX>-XXX]
- [ ] GREEN: implement use case [Story: FR-<PFX>-XXX]
- [ ] REFACTOR: remove duplication, align naming [Story: FR-<PFX>-XXX]
- [ ] Verify: tests PASS [Story: FR-<PFX>-XXX]

### 2.2 Adapter / data layer

- [ ] RED: add failing test for `<!-- adapter or repository impl -->` [Story: FR-<PFX>-XXX] [P]
- [ ] Verify RED [Story: FR-<PFX>-XXX]
- [ ] GREEN: implement adapter [Story: FR-<PFX>-XXX]
- [ ] Verify: tests PASS [Story: FR-<PFX>-XXX]

### 2.3 Cross-layer contract alignment check

- [ ] Confirm shared interface / proto shape matches sibling layer expectations [Story: FR-GL-XXX]
- [ ] If mismatch: emit `[NEEDS CLARIFICATION: ...]` and STOP — do not silently resolve

---

## <Layer> Phase 3 — Integration + Quality

<!-- Wire everything together, run quality gates, verify BDD scenarios pass. -->

### 3.1 Integration

- [ ] Write failing integration test covering the end-to-end path within this layer [Story: FR-<PFX>-XXX]
- [ ] Verify RED [Story: FR-<PFX>-XXX]
- [ ] Implement integration wiring [Story: FR-<PFX>-XXX]
- [ ] Verify: integration tests PASS [Story: FR-<PFX>-XXX]

### 3.2 BDD scenarios

- [ ] Remove @wip tag; run BDD suite [Story: FR-<PFX>-XXX]
- [ ] Verify: all scenarios PASS [Story: FR-<PFX>-XXX]

### 3.3 Quality gates

- [ ] Run layer linter / static analysis → zero warnings [Story: FR-<PFX>-XXX]
- [ ] Run test suite with coverage → meet threshold (see `design-<layer-id>.md` Testing Strategy) [Story: FR-<PFX>-XXX]
- [ ] Observability: add instrumentation spans per Observability Plan [Story: FR-<PFX>-XXX]
- [ ] Run full layer test suite → ALL GREEN [Story: FR-<PFX>-XXX]

## REFACTOR Phase

- [ ] Review: extract any duplication across phases
- [ ] Review: ensure naming follows layer conventions
- [ ] Run full layer test suite → ALL GREEN

---

<!-- Progress: 0/N tasks complete -->
<!-- Last updated: YYYY-MM-DD -->
