# Tasks: b6-4-hermes-async

<!-- Status: implemented -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED), write the
  artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-B6-HA-XXX]` (Article V.1) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the **same phase**.
- ADRs from `design.md` (ADR-K1-001..003) are honored verbatim.
- **DIVERGENCE FROM b7-pythia** : this brick edits NO Janus file and NO standards
  index (task-boundary, FR-B6-HA-083) ; ships NO scanner / data file / new standard
  (ADR-K1-003 / FR-B6-HA-082/084). Guarded by negative tests
  `_test_b64_014..016`.

---

## Phase 1 — Foundation : RED harness (name-agnostic)

Goal : `b6-4.test.sh` exists with 18 L1 + 1 L2 tests carrying real assertions ; run
confirms full RED (persona + doc rows absent) ; CI registration done.

- [x] **T-PHA-001** : Create `.forge/scripts/tests/b6-4.test.sh` with bash header
      (`#!/usr/bin/env bash`, `set -uo pipefail`), source `_helpers.sh`, PASS/FAIL
      counters, `--level 1,2` parsing, `print_summary`. Resolve `HERMES_AGENT` from a
      single variable defaulting to `.claude/agents/hermes-async.md`, overridable by
      env. Mirror the `b7-pythia.test.sh` layout. [Story: FR-B6-HA-001 / NFR-B6-HA-007]
- [x] **T-PHA-002** : Add the 18 L1 tests (real assertions) covering the anchor IDs
      in `design.md` § "L1 anchor-level" table. [Story: FR-B6-HA-001..086]
- [x] **T-PHA-003** [P] : Add the 1 L2 fixture (`_test_b64_l2_anchor_integrity`)
      using `mk_tmpdir_with_trap`. [Story: NFR-B6-HA-007]
- [x] **T-PHA-004** [P] : Register `b6-4.test.sh --level 1,2` in
      `.github/workflows/forge-ci.yml` `harnesses=(...)` immediately after
      `"b6-2.test.sh --level 1"`. [Story: NFR-B6-HA-005]
- [x] **T-PHA-005** : RED gate confirmed — `bash .forge/scripts/tests/b6-4.test.sh
      --level 1,2` exits 1 with the persona/doc-row tests failing. [Story: Article I]

**Phase 1 exit gate** : `b6-4.test.sh --level 1,2` exits 1 (persona + rows absent),
`forge-ci.yml` matrix updated.

---

## Phase 2 — K.1.a : Hermes-Async persona file

Goal : `.claude/agents/hermes-async.md` ships with all mandatory H2 sections + audit
comments + 4 checklist H3 + 6 K1-RULE entries + real code-shape references.

- [x] **T-PER-001** : Create `.claude/agents/hermes-async.md` with the audit comments
      (`K.1` + `B.6.4`), H1 `# Agent: Event-Driven Messenger (Hermes-Async)`, and the
      `## Persona` + `## Purpose` H2 (cite K.1 + B.6.4 + the 3 B.6.3 standards ; state
      `event-driven-eu`-scoped ; disambiguate Hermes / Hermes-API).
      [Story: FR-B6-HA-001..003 / 010 / ADR-K1-001]
- [x] **T-PER-002** : Add `## Checklists` H2 with 4 H3 (≥ 5 `[ ]` items each,
      Verify/Check/Exception) — AsyncAPI Contract Maintenance / NATS/Kafka Binding
      Generation / Idempotency-Key Enforcement / Event Versioning & Compatibility.
      Cite the consumed B.6.3 standard in each H3 ; reference the real code shapes
      (`EventEnvelope`, `Nats-Msg-Id`, `idempotency_key`, `events.v<n>.` subject,
      `InboxDedup`, `SagaStep`). [Story: FR-B6-HA-004 / 020..027 / 085]
- [x] **T-PER-003** : Add `## Output: Event Contract Readiness Report` H2 (Summary
      table + Findings template + Cleared Items + status BLOCKED/NEEDS-REVISION/READY).
      [Story: FR-B6-HA-005]
- [x] **T-PER-004** : Add `## Recommendation Catalogue` H2 with K1-RULE-001..006 per
      FR-B6-HA-120..125. K1-RULE-006 MUST be `Blocking` + cite `VIII.2`. Document the
      severity vocabulary + the ADR-J8-004 numbering invariant. [Story: FR-B6-HA-006 /
      120..125 / ADR-K1-002]
- [x] **T-PER-005** : Add `## Integration` H2 (Janus routing + Hermes-API + Vulcan +
      Atlas) + `## Anti-Hallucination Protocol` H2 (III.4 + LIVE-verify via Context7)
      + `## Audit cross-references` footer per FR-B6-HA-011. [Story: FR-B6-HA-007 / 008
      / 011]
- [x] **T-PER-006** : Run harness ; expect the 11 persona-anchor L1 tests + real-code
      + anti-halluc + standards-consumed GREEN. [Story: FR-B6-HA-001..027]

---

## Phase 3 — K.1.b : CLAUDE.md + GUIDE.md registration

- [x] **T-DOC-001** : Edit repo `CLAUDE.md` "Agent Delegation System" table — insert
      `| Event-driven / AsyncAPI | **Hermes-Async** | Event-Driven Messenger |` after
      the `AI/RAG tuning | Sibyl` row. No other row touched. [Story: FR-B6-HA-080]
- [x] **T-DOC-002** : Edit `docs/GUIDE.md` "Agents Transversaux" table — insert a
      Hermes-Async row (same pattern as Iris-Web / Themis), disambiguating from Hermes
      (Flutter perf). [Story: FR-B6-HA-081]
- [x] **T-DOC-003** : Run harness ; expect CLAUDE.md + GUIDE.md L1 tests GREEN, and
      the no-Janus/index-edit + no-new-standard + no-scanner + no-collision guards
      GREEN. [Story: FR-B6-HA-080..086]

---

## Phase 4 — Quality : CHANGELOG + open-questions flip + verify

- [x] **T-OQ-001** : Flip Q-001 + Q-002 + Q-003 in `open-questions.md` to
      `Status: answered` with `### Resolution` blocks citing ADR-K1-001..003.
      [Story: Article III.4]
- [x] **T-CL-001** [P] : Add a `## [Unreleased]` entry in `CHANGELOG.md` covering the
      K.1 Hermes-Async event-driven specialist (persona + CLAUDE.md/GUIDE.md rows +
      harness). [Story: docs]
- [x] **T-REV-001** : Run full `b6-4.test.sh --level 1,2` → 19/19 GREEN ≤ 5 s ; run
      `verify.sh` / `constitution-linter.sh` / sibling harnesses (`b6-1`, `b6-2`,
      `b7-pythia`, `k3`, `k5`) → no regression. [Story: NFR-B6-HA-005]
- [x] **T-REV-002** : Smoke the 3 BDD scenarios as a reviewer read-through (Janus
      routing / K1-RULE-006 Blocking gate / NEEDS-CLARIFICATION on unverified binding)
      — no executable to run (advisory agent). [Story: Article II]

**Phase 4 exit gate (= archival readiness)** :

- `b6-4.test.sh --level 1,2` 19/19 PASS / 0 FAIL / ≤ 5 s.
- `verify.sh` + `constitution-linter.sh` no regression.
- `b6-1` / `b6-2` / `b7-pythia` / `k3` / `k5` unchanged.
- Q-001 + Q-002 + Q-003 `answered` (none blocking).
- All FR-B6-HA-001..125 + NFR-B6-HA-001..007 tasks checked.
- `CHANGELOG.md` `## [Unreleased]` entry.

---

## Constitutional task review (per Article V)

| Task family | TDD order                                | Spec link                      | Architecture              |
|-------------|------------------------------------------|--------------------------------|---------------------------|
| T-PHA-*     | RED harness (real assertions)            | FR-B6-HA-001..086              | name-agnostic harness     |
| T-PER-*     | Persona (flips L1 GREEN)                  | FR-B6-HA-001..027 / 120..125   | ADR-K1-001 / 002          |
| T-DOC-*     | Doc rows (flip GREEN)                     | FR-B6-HA-080..086              | Forge agent-dispatch conv |
| T-OQ/CL/REV | Validation only                          | Article III.4 / II / V         | ADR-K1-003 (no scanner)   |

No `[TASK VIOLATION]` detected.

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` |
|-------|-------|----------------------|
| 1     | 5     | 2                    |
| 2     | 6     | 0                    |
| 3     | 3     | 0                    |
| 4     | 4     | 1                    |
| **Total** | **18** | **3** |
