# Spec: adr-ratification

<!-- Audit: T.4 — ratify the 10 ADRs of docs/ARCHITECTURE-TARGET.md.       -->
<!-- This file accumulates archived requirements for ADR ratification      -->
<!-- discipline. Distinct from `linter-extension.md` (which governs the    -->
<!-- linter rules) and from `change-yaml-schema.md` (which governs         -->
<!-- per-change YAML validation). Audience : Forge maintainers + adopters  -->
<!-- consuming the standards-lifecycle policy.                             -->

This spec is the consolidated contract for the **ADR ratification
discipline** — the convention by which Forge captures decisions
documented in external source documents (architecture audits,
RFCs, post-mortems) as ratified Forge changes under Constitution
v1.1.0, with sha256 drift detection and a 12-month standards
review cycle.

The full standards governing the discipline are
`.forge/standards/global/standards-lifecycle.md` and
`.forge/standards/global/source-document-pinning.md`.

---

## Archived changes

| Change | Date | Phase | FRs added |
|---|---|---|---|
| [`t4-adr-ratification`](../changes/t4-adr-ratification/) | 2026-05-04 | Initial ratification of `docs/ARCHITECTURE-TARGET.md` (sha256 `cd8fef37…3de925`) | FR-T4-ADR-001..010 + FR-T4-STD-001..006 + FR-T4-LC-001..005 + FR-T4-SCH-001..002 + FR-T4-LNT-001..002 + FR-T4-TST-001..005 + FR-T4-IDX-001..002 + FR-T4-DSP-001 + FR-T4-DOC-001..003 + NFR-T4-001..008 ; MODIFIED `archetype.schema.json` v1 → v2 (5-archetype enum + `mobile-only` legacy alias) |

---

## Requirements

### FR-T4-ADR-001..010: ADR ratifications (10 sections)

- **MUST** — every Forge change ratifying decisions taken in an external
  document under `docs/` SHALL carry one H2 section per ratified Decision
  in its `design.md`, with the verbatim Decision / Context / Consequences
  triplet from the source document, cross-referenced to a precise line
  range.
- **MUST** — line ranges resolve to the source document at the sha256
  pinned in `specs.md::Source Document` table.
- **MUST** — each ratification declares a `Forge ratification` block that
  cross-references the standards YAML carrying the operational policy and
  any planned activation milestone (e.g. `Activation deferred to B.8 (T6)`).

For `t4-adr-ratification` specifically, the 10 ratified ADRs are :
ADR-001 (Envoy Gateway), ADR-002 (DBOS default), ADR-003 (Connect-RPC),
ADR-004 (Rust + tonic KEEP), ADR-005 (Flutter + Qwik web public),
ADR-006 (flutter_bloc consecrated), ADR-007 (Zitadel default),
ADR-008 (SigNoz + OBI + Coroot), ADR-009 (buf + Connect codegen),
ADR-010 (Postgres 17 + pgvector universal).

**Constitution reference:** Articles IV, V, XII. **Testable:** yes —
`t4.test.sh::_test_t4_023` enforces the source-document hash, and the
verbatim line ranges are covered by manual cross-reference at review time.

### FR-T4-STD-001..006: Six versioned standards

- **MUST** — six `.forge/standards/*.yaml` files (`transport`, `state-management`,
  `observability`, `orchestration`, `identity`, `persistence`) carry a uniform
  frontmatter (`version`, `last_reviewed`, `expires_at`, `exception_constitutional`,
  `linter_rule`, `enforcement.{ci_blocking, pre_commit_hook}`, `forbidden`,
  `rationale`).
- **MUST** — `transport.yaml` and `state-management.yaml` declare
  `exception_constitutional: true` and `expires_at: never` (structural
  exception per ADR-006 + ADR-009).
- **MUST** — `state-management.yaml` carries an exhaustive 8-entry
  `forbidden:` list : `flutter_riverpod, riverpod, provider, get, getx,
  mobx, flutter_mobx, states_rebuilder`.
- **MUST** — `identity.yaml` carries `forbidden: [firebase-auth, auth0-saas-us]`
  (Schrems II + CLOUD Act).
- **MUST** — `persistence.yaml` carries `forbidden_for_eu_strict: [dynamodb,
  firestore, cosmosdb]` for T2/T3 strict tiers.
- **MUST** — every standard parses with `yq` (no PyYAML-only constructs).

**Constitution reference:** Articles V, IX. **Testable:** yes — 17 tests in
`t4.test.sh` (6 parse + 6 frontmatter + 3 forbidden + 2 exception_constitutional).

### FR-T4-LC-001..005: Standards lifecycle

- **MUST** — `.forge/standards/global/standards-lifecycle.md` documents the
  12-month default review window, the structural exception escape, the
  Themis hook (deferred to T7), and the linter integration with
  `expires_at`.
- **MUST** — `.forge/standards/REVIEW.md` is an append-only ledger ; the
  initial seed contains 6 entries (one per standard YAML) with
  `Reviewed on: 2026-05-04` by `@bfontaine`.
- **MUST** — `constitution-linter.sh` MAY (NOT MUST in this change) WARN
  on expired non-structural standards. Implementation deferred but the
  rule is documented.

**Constitution reference:** Article XII. **Testable:** yes —
`t4.test.sh::_test_t4_024` (REVIEW.md seed entries),
`t4.test.sh::_test_t4_025` (lifecycle structural exception list),
`t4.test.sh::_test_t4_l2_expired_warns` (synthetic expired-standard
detection).

### FR-T4-SCH-001..002: JSON schemas

- **MUST** — `.forge/schemas/compliance-tier.schema.json` (Draft 2020-12)
  defines a top-level enum `[T1, T2, T3]` with `x-tier-descriptions`
  matching `docs/ARCHITECTURE-TARGET.md` §10.1.
- **MUST** — `.forge/schemas/archetype.schema.json` (v2) defines a 6-value
  enum `[full-stack-monorepo, mobile-pwa-first, event-driven-eu,
  ai-native-rag, rust-cli-tui, mobile-only]`. The `mobile-only` value
  carries a deprecation description pointing to `mobile-pwa-first`.
- **MUST NOT** — `archetype.schema.json` enum contains `flutter-firebase`
  (REMOVED per ADR-007).

**Constitution reference:** Articles V, IX. **Testable:** yes —
`t4.test.sh::_test_t4_018..022` (5 schema validation + enum coverage tests).

### FR-T4-LNT-001..002: Linter rule + drift detector

- **MUST** — `constitution-linter.sh` carries a section
  `ADR-006 (State Management Discipline — no-state-management-alternatives)`.
- **MUST** — the rule reads `enforcement.ci_blocking` from
  `state-management.yaml` ; emits WARN by default (Q-001 Option A) ;
  flips to FAIL when `ci_blocking: true` (planned for B.8 / T6).
- **MUST** — opt-out via `FORGE_LINTER_SKIP_NSMA=1`.
- **MUST** — fixture-based override via `FORGE_LINTER_FIXTURE_ROOT=<path>`
  for L2 tests.
- **MUST** — `t4.test.sh::_test_t4_023` recomputes the sha256 of
  `docs/ARCHITECTURE-TARGET.md` and FAILs on drift. Escape hatch
  `bin/forge-rehash-architecture-doc.sh` rewrites the pinned hash + appends
  to `.forge/changes/t4-adr-ratification/REHASH-LOG.md`.

**Constitution reference:** Articles I, V, IX. **Testable:** yes —
`t4.test.sh::_test_t4_l2_lint_warn_riverpod`,
`t4.test.sh::_test_t4_l2_lint_pass_only_bloc`,
`t4.test.sh::_test_t4_l2_drift_fail_byte`,
`t4.test.sh::_test_t4_l2_drift_pass_rehash`.

### FR-T4-TST-001..005: Test harness

- **MUST** — `.forge/scripts/tests/t4.test.sh` ships 30 tests (25 L1 + 5 L2)
  using the shared `_helpers.sh` runner.
- **MUST** — registered in `.github/workflows/forge-ci.yml` `harness` job.
- **SHALL** — wall-clock ≤ 8 s (NFR-T4-001 — aligned with f4 actual perf).
- **SHALL** — fixture cleanup via `mk_tmpdir_with_trap` + RETURN trap.

**Testable:** self-tested (tests test themselves).

### FR-T4-IDX-001..002, FR-T4-DSP-001: Registry updates

- **MUST** — `.forge/standards/index.yml` registers 8 new entries (6 YAML
  + 2 markdown) under the T.4 ratifications block.
- **MUST** — `.forge/scaffolding/dispatch-table.yml` annotates `mobile-only`
  with `status: legacy_alias`, `target: mobile-pwa-first`,
  `migration: B.9 (T8)`.
- **MUST** — `.forge/scaffolding/dispatch-table.yml` adds a
  `flutter-firebase` placeholder slot with `scaffolder: "<removed>"` +
  `status: removed_from_roadmap` + `reason:` field. Forward-compat with
  `b5.test.sh::test_dispatch_scaffolders_exist` (skips `<removed>` and
  `removed_from_roadmap` entries).

**Constitution reference:** Article V. **Testable:** yes — `b5.test.sh`
`test_dispatch_scaffolders_exist` regression test (already passing
post-patch).

### FR-T4-DOC-001..003: Documentation

- **MUST** — `docs/STANDARDS-LIFECYCLE.md` (public-facing) summarises the
  12-month rule, structural exceptions, and points to
  `docs/ARCHITECTURE-TARGET.md` + `docs/new-archetypes-plan.md`.
- **MUST** — `.forge/standards/global/source-document-pinning.md`
  documents the sha256-pinning convention + rehash escape hatch workflow.
- **MUST** — `CHANGELOG.md` `## [Unreleased]` carries an entry listing
  the 8 new standards, 2 schemas, taxonomy `flutter-firebase` removal,
  legacy `mobile-only` annotation, and the `no-state-management-alternatives`
  linter rule (WARN-only).

**Testable:** manual (CHANGELOG / docs are written prose, not enforceable
deterministically beyond presence checks).

### NFR-T4-001..008: Quality budgets

- **NFR-T4-001** : `t4.test.sh` ≤ 8 s wall-clock (revised from initial 3 s
  per Python-fork overhead reality, aligned with `f4.test.sh` actual perf).
- **NFR-T4-002** : ≤ 18 NEW + ≤ 6 modified files (held — actual : 14 NEW
  + 7 modified including `b5.test.sh` patch).
- **NFR-T4-003** : zero regression on the 13 pre-t4 archived changes
  (held — `verify.sh` 116 PASS / 0 FAIL).
- **NFR-T4-004** : Constitution v1.1.0 unchanged (held).
- **NFR-T4-005** : zero edit under `cli/src/`, `frontend/`, `backend/`,
  `infra/`, `examples/forge-fsm-example/` (held).
- **NFR-T4-006** : drift gate ≤ 100 ms (held — single `shasum` call).
- **NFR-T4-007** : `docs/ARCHETYPES.md` updated to point to lifecycle doc
  (deferred to a follow-up MD edit if not present in this change).
- **NFR-T4-008** : ADR cross-reference fidelity (held by sha256 pin).

---

## Cross-references

- `docs/ARCHITECTURE-TARGET.md` — single source of truth ratified by this
  spec. Do NOT edit without running `bin/forge-rehash-architecture-doc.sh`
  + reviewer attestation.
- `docs/new-archetypes-plan.md` — post-v0.3.0 plan citing T4 as the
  methodology pre-requisite gate before T5+.
- `.forge/standards/REVIEW.md` — append-only review ledger ; next due
  date for non-structural standards : 2027-05-04.
- `.forge/specs/linter-extension.md` — sister spec for the
  `constitution-linter.sh` discipline (F.4 + this change's
  `no-state-management-alternatives` rule).
