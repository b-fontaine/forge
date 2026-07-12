# Tasks: <!-- change-name -->
<!-- TDD order is mandatory: tests before implementation, always -->
<!-- Format: - [ ] Task [Story: FR-XXX] [P] -->
<!-- [P] = parallelizable with other [P] tasks in same phase -->

## Phase 1: Foundation

### Test Infrastructure
- [ ] Set up test fixtures and mock factories [Story: FR-001]
- [ ] Create test data builders [Story: FR-001]
- [ ] Write BDD feature file for primary scenario [Story: FR-001]

### Domain Layer (RED phase)
- [ ] Write failing unit test for <!-- entity/value object --> [Story: FR-001]
- [ ] Write failing unit test for <!-- use case --> [Story: FR-001]
- [ ] Write failing unit test for <!-- repository interface --> [Story: FR-001]

## Phase 2: Core Implementation (GREEN phase)

### Domain Layer
- [ ] Implement <!-- entity/value object --> to pass unit tests [Story: FR-001]
- [ ] Implement <!-- use case --> to pass unit tests [Story: FR-001]
- [ ] Verify: run tests → ALL GREEN

### Data Layer (RED → GREEN)
- [ ] Write failing test for <!-- repository implementation --> [Story: FR-001] [P]
- [ ] Write failing test for <!-- data source --> [Story: FR-001] [P]
- [ ] Implement <!-- repository --> [Story: FR-001]
- [ ] Implement <!-- data source --> [Story: FR-001]
- [ ] Verify: run tests → ALL GREEN

### State Management (RED → GREEN)
- [ ] Write failing BLoC test with bloc_test [Story: FR-001]
- [ ] Implement <!-- BLoC/Cubit --> [Story: FR-001]
- [ ] Verify: run tests → ALL GREEN

## Phase 3: Presentation (RED → GREEN)

- [ ] Write failing widget test for <!-- Page --> [Story: FR-001]
- [ ] Write failing golden test for <!-- Widget --> [Story: FR-001] [P]
- [ ] Implement <!-- Page --> with BLoC integration [Story: FR-001]
- [ ] Implement <!-- Widget --> [Story: FR-001]
- [ ] Register route in router [Story: FR-001]
- [ ] Verify: run all tests → ALL GREEN

## Phase 4: Quality

- [ ] Accessibility: verify semantic labels, contrast, focus order [Story: FR-001]
- [ ] i18n: add all strings to ARB files [Story: FR-001]
- [ ] Performance: profile with DevTools, check rebuild count [Story: FR-001]
- [ ] OpenTelemetry: add instrumentation spans [Story: FR-001]
- [ ] Run `flutter analyze` → zero warnings [Story: FR-001]
- [ ] Run `flutter test --coverage` → ≥80% [Story: FR-001]
- [ ] BDD scenarios: all pass [Story: FR-001]
- [ ] Golden tests: all pass [Story: FR-001]

## REFACTOR Phase
- [ ] Review: extract any duplication
- [ ] Review: ensure naming follows conventions
- [ ] Run full test suite → ALL GREEN

---
<!-- Progress: 0/N tasks complete -->
<!-- Last updated: YYYY-MM-DD -->
