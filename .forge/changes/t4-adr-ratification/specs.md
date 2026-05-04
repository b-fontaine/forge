# Specifications: t4-adr-ratification
<!-- Status: specified -->
<!-- Schema: default -->

## Source Document

This change ratifies decisions from a single source document.

| Field                  | Value                                                              |
|------------------------|--------------------------------------------------------------------|
| **Path**               | `docs/ARCHITECTURE-TARGET.md`                                      |
| **Line count**         | 1116                                                               |
| **sha256**             | `cd8fef37ed01de981c8779a79d40234a70a4411387235dd990a86b705f3de925` |
| **Last verified**      | 2026-05-04                                                         |
| **Drift gate**         | `t4.test.sh::test_architecture_doc_hash_unchanged`                 |
| **Rehash escape hatch**| `bin/forge-rehash-architecture-doc.sh` (creates a new t4 hash entry, not a Forge re-archival) |

If the hash drifts, `t4.test.sh` FAILs. Trivial edits (typos, formatting) follow
the rehash workflow documented in
`.forge/standards/global/source-document-pinning.md` (FR-T4-DOC-002 below).
Material edits trigger a new Forge change that supersedes parts of this one.

---

## ADDED Requirements

### Functional Requirements

#### Group 1 — ADR ratification (FR-T4-ADR-001 → 010)

Each ADR ratification ships as one H2 section in `design.md` (Decision /
Context / Consequences) cross-referenced to a precise line range in
`docs/ARCHITECTURE-TARGET.md`. The specs below establish the *contract* that
each ratification MUST satisfy.

##### FR-T4-ADR-001: ADR-001 Envoy Gateway ratification
- **MUST** carry the verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 315–326.
- **MUST** declare `replaces: kong` and `target_archetype: full-stack-monorepo, mobile-pwa-first, event-driven-eu, ai-native-rag`.
- **MUST** be referenced from `transport.yaml` (FR-T4-STD-001).

##### FR-T4-ADR-002: ADR-002 DBOS default ratification
- **MUST** carry verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 328–340.
- **MUST** declare `temporal_fallback_trigger: workflow_volume_per_day_gt_10000 OR cross_service_count_gt_10`.
- **MUST** be referenced from `orchestration.yaml` (FR-T4-STD-004).

##### FR-T4-ADR-003: ADR-003 Connect-RPC ratification
- **MUST** carry verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 342–354.
- **MUST** declare `replaces: rest_via_kong_bridge` and `compat: grpc, grpc-web`.
- **MUST** be referenced from `transport.yaml` (FR-T4-STD-001).

##### FR-T4-ADR-004: ADR-004 Rust + tonic KEEP
- **MUST** carry verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 356–364.
- **MUST** declare `pinned_versions: tonic=^0.14, axum=^0.8` with expiry
  2027-05-04 (12-month review per FR-T4-LC-001).

##### FR-T4-ADR-005: ADR-005 Flutter + Qwik web public ratification
- **MUST** carry verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 366–375.
- **MUST** declare `web_public: qwik`, `web_backoffice: flutter`, `mobile_desktop: flutter`.
- **MUST NOT** introduce any template change (templates ship in B.8 / B.9).

##### FR-T4-ADR-006: ADR-006 flutter_bloc consecrated
- **MUST** carry verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 377–398.
- **MUST** declare `exception_constitutional: true` (not subject to 12-month review).
- **MUST** be referenced from `state-management.yaml` (FR-T4-STD-002).

##### FR-T4-ADR-007: ADR-007 Zitadel default ratification
- **MUST** carry verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 399–407.
- **MUST** declare `replaces: firebase_auth_implicit` and `forbidden: [firebase-auth, auth0-saas-us]`.
- **MUST** be referenced from `identity.yaml` (FR-T4-STD-005).

##### FR-T4-ADR-008: ADR-008 SigNoz + OBI + Coroot ratification
- **MUST** carry verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 409–419.
- **MUST** declare `kernel_min: 5.8` (OBI eBPF requirement) and
  `audit_required: aegis (privileged DaemonSet)`.
- **MUST** be referenced from `observability.yaml` (FR-T4-STD-003).

##### FR-T4-ADR-009: ADR-009 buf + Connect codegen ratification
- **MUST** carry verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 421–431.
- **MUST** declare `derived_outputs: [openapi-3.1, asyncapi-3.1]`.
- **MUST** declare `exception_constitutional: true` (transport contracts not
  subject to 12-month review per ADR-006 + ADR-009 jointly).
- **MUST** be referenced from `transport.yaml` (FR-T4-STD-001).

##### FR-T4-ADR-010: ADR-010 Postgres 17 + pgvector universal default
- **MUST** carry verbatim Decision/Context/Consequences from
  `docs/ARCHITECTURE-TARGET.md` lines 433–445.
- **MUST** declare `extensions: [pgvector-0.8, postgis, timescaledb]` and
  `sharding: citus`.
- **MUST** declare `forbidden_for_t2_t3_strict: [dynamodb, firestore, cosmosdb]`.
- **MUST** be referenced from `persistence.yaml` (FR-T4-STD-006).

#### Group 2 — Versioned standards YAML (FR-T4-STD-001 → 006)

##### FR-T4-STD-001: `transport.yaml`
- **MUST** be created at `.forge/standards/transport.yaml`.
- **MUST** carry uniform frontmatter : `version`, `last_reviewed`, `expires_at`,
  `forbidden:`, `linter_rule:`, `enforcement:`, `exception_constitutional:`.
- **MUST** set `version: "1.0.0"`, `last_reviewed: 2026-05-04`,
  `exception_constitutional: true`, `expires_at: never` (structural exception
  per ADR-006 + ADR-009 + Q-001 resolution).
- **MUST** declare `protocol: connect-rpc`, `fallback: grpc-web`,
  `http_versions: [http/1.1, http/2, http/3-experimental]`.
- **MUST** declare `codegen.source_of_truth: protobuf`,
  `codegen.tools: [buf, protoc-gen-connect-go, protoc-gen-connect-es, protoc-gen-connect-dart-community, tonic-build]`,
  `codegen.derived_outputs: [openapi-3.1, asyncapi-3.1]`.
- **MUST** declare `breaking_change_check: buf breaking --against '.git#branch=main'`.
- **MUST** parse cleanly with `yq` (`yq eval '.' transport.yaml > /dev/null`).

##### FR-T4-STD-002: `state-management.yaml`
- **MUST** be created at `.forge/standards/state-management.yaml`.
- **MUST** set `exception_constitutional: true`, `expires_at: never`.
- **MUST** declare `flutter.standard: flutter_bloc` with `version_pinned: ^9.0.0`.
- **MUST** declare `flutter.companions: [bloc_test, hydrated_bloc, replay_bloc]`.
- **MUST** declare `flutter.forbidden: [flutter_riverpod, riverpod, provider, get, getx, mobx, flutter_mobx, states_rebuilder]` — exhaustive list per ADR-006.
- **MUST** declare `enforcement.linter_rule: no-state-management-alternatives`,
  `enforcement.ci_blocking: false` (per Q-001 resolution — `warn` mode in this
  change),  `enforcement.pre_commit_hook: false`,
  `enforcement.activation_planned: B.8 (T6)` — documented warn-to-error
  transition.
- **MUST** carry the verbatim `rationale:` block from
  `docs/ARCHITECTURE-TARGET.md` lines 379–397 (ADR-006 Decision + Context).

##### FR-T4-STD-003: `observability.yaml`
- **MUST** be created at `.forge/standards/observability.yaml`.
- **MUST** set `version: "1.0.0"`, `last_reviewed: 2026-05-04`,
  `expires_at: 2027-05-04` (subject to 12-month review).
- **MUST** declare `sdk: opentelemetry`, `ebpf_complement: opentelemetry-obi`,
  `service_map: coroot`, `backend: signoz`.
- **MUST** declare `sampler: parentbased_traceidratio`, `prod_ratio: 0.1`,
  `staging_ratio: 1.0`, `dev_ratio: 1.0`.
- **MUST** declare `kernel_min: 5.8` (OBI requirement).
- **MUST** declare `forbidden: [datadog]` with rationale `cloud-act-non-eu`.
- **MUST** parse cleanly with `yq`.

##### FR-T4-STD-004: `orchestration.yaml`
- **MUST** be created at `.forge/standards/orchestration.yaml`.
- **MUST** set `version: "1.0.0"`, `last_reviewed: 2026-05-04`,
  `expires_at: 2027-05-04`.
- **MUST** declare `default: dbos`, `fallback: temporal`.
- **MUST** declare `fallback_trigger: workflow_volume_per_day_gt_10000 OR cross_service_count_gt_10`.
- **MUST** declare `forbidden: [inngest]` with rationale `saas-first-eu-sovereignty-low`.
- **MUST** parse cleanly with `yq`.

##### FR-T4-STD-005: `identity.yaml`
- **MUST** be created at `.forge/standards/identity.yaml`.
- **MUST** set `version: "1.0.0"`, `last_reviewed: 2026-05-04`,
  `expires_at: 2027-05-04`.
- **MUST** declare `default: zitadel`, `alternatives: [keycloak, authentik]`.
- **MUST** declare `forbidden: [firebase-auth, auth0-saas-us]` with
  rationale `cloud-act-non-eu` and `schrems-ii-disqualified`.
- **MUST** declare `compliance_tier_aware: true` (T3 requires self-host).
- **MUST** parse cleanly with `yq`.

##### FR-T4-STD-006: `persistence.yaml`
- **MUST** be created at `.forge/standards/persistence.yaml`.
- **MUST** set `version: "1.0.0"`, `last_reviewed: 2026-05-04`,
  `expires_at: 2027-05-04`.
- **MUST** declare `default: postgres-17`,
  `extensions: [pgvector-0.8, postgis, timescaledb]`,
  `sharding: citus`.
- **MUST** declare `forbidden_for_eu_strict: [dynamodb, firestore, cosmosdb]`
  (T2/T3 only ; T1 acceptable with DPA).
- **MUST** parse cleanly with `yq`.

#### Group 3 — Standards lifecycle (FR-T4-LC-001 → 005)

##### FR-T4-LC-001: 12-month review window default
- **MUST** be documented in `.forge/standards/global/standards-lifecycle.md`.
- **MUST** state : every `.forge/standards/*.yaml` carries `last_reviewed` and
  `expires_at` in YYYY-MM-DD format ; default delta is 365 days ; expiry
  triggers a review event in `REVIEW.md`.

##### FR-T4-LC-002: Structural exception list
- **MUST** be documented in `.forge/standards/global/standards-lifecycle.md`.
- **MUST** list `transport.yaml` and `state-management.yaml` as structural
  exceptions (`exception_constitutional: true`, `expires_at: never`).
- **MUST** state : amending a structural exception requires Constitution
  amendment (Article XII process) — no expiry-driven review.

##### FR-T4-LC-003: `REVIEW.md` ledger format
- **MUST** be created at `.forge/standards/REVIEW.md`.
- **MUST** open with the canonical schema (one H2 per review event, fields
  `Standard`, `Reviewed on`, `Reviewer`, `Decision`, `Next review due`).
- **MUST** seed with 6 entries (one per standard FR-T4-STD-001..006), all
  reviewed 2026-05-04 by `@bfontaine` (initial ratification).

##### FR-T4-LC-004: Themis hook reference (deferred agent)
- **MUST** state in `standards-lifecycle.md` that monthly review automation
  is the Themis agent's responsibility (K.5, deferred to T7).
- **MUST NOT** ship the Themis agent in this change.

##### FR-T4-LC-005: Linter integration with `expires_at`
- **MUST** be tested by `t4.test.sh::test_no_expired_standards` :
  `constitution-linter.sh` (extended in F.4) gains a non-blocking WARN if
  any standard's `expires_at` is in the past, ignoring entries with
  `exception_constitutional: true`.

#### Group 4 — JSON schemas (FR-T4-SCH-001 → 002)

##### FR-T4-SCH-001: `compliance-tier.schema.json`
- **MUST** be created at `.forge/schemas/compliance-tier.schema.json` (Draft 2020-12).
- **MUST** define a top-level enum `[T1, T2, T3]` with verbatim definitions
  from `docs/ARCHITECTURE-TARGET.md` lines 735–738.
- **MUST** declare `description:` strings for each tier (RGPD-via-DPA /
  self-hostable / EU strict).
- **MUST** validate against itself via the JSON Schema meta-schema
  (`python3 -c "import jsonschema; jsonschema.Draft202012Validator.check_schema(...)"`).

##### FR-T4-SCH-002: `archetype.schema.json` v2
- **MUST** modify `.forge/schemas/archetype.schema.json` to declare
  `enum: [full-stack-monorepo, mobile-pwa-first, event-driven-eu, ai-native-rag, rust-cli-tui, mobile-only]`.
- **MUST** annotate `mobile-only` with `description: "DEPRECATED — alias for mobile-pwa-first ; legacy compat only ; see B.9 (T8)."` (per Q-002 resolution).
- **MUST** validate against the JSON Schema meta-schema.
- **MUST** preserve the existing schema's other constraints (no widening).

#### Group 5 — Linter rule (FR-T4-LNT-001 → 002)

##### FR-T4-LNT-001: `no-state-management-alternatives` (warn-only)
- **MUST** be implemented as a new section in `constitution-linter.sh` or
  a dedicated `.forge/scripts/lint-state-management.sh` invoked from
  `verify.sh`.
- **MUST** scan all Flutter `pubspec.yaml` files in the repo (excluding
  `examples/` per F.4 conventions) for any of the forbidden dependencies
  in FR-T4-STD-002.
- **MUST** emit `WARN` (non-blocking) on detection. **MUST NOT** emit `FAIL`.
- **MUST** read `enforcement.ci_blocking` from `state-management.yaml` ;
  flip to `FAIL` if the YAML's `enforcement.ci_blocking` becomes `true`
  (forward-compat for B.8 activation).

##### FR-T4-LNT-002: Drift detector for `docs/ARCHITECTURE-TARGET.md`
- **MUST** be implemented as `t4.test.sh::test_architecture_doc_hash_unchanged`.
- **MUST** recompute `shasum -a 256 docs/ARCHITECTURE-TARGET.md`.
- **MUST** FAIL if the hash differs from the value in `specs.md` Source
  Document table.

#### Group 6 — Test harness (FR-T4-TST-001 → 005)

##### FR-T4-TST-001: Harness file location
- **MUST** be created at `.forge/scripts/harnesses/t4.test.sh`.
- **MUST** be registered in `.github/workflows/forge-ci.yml` under the
  `harness` job matrix.
- **MUST** be registered in `verify.sh` aggregated pass count.

##### FR-T4-TST-002: Harness coverage (≥ 25 tests)
- **MUST** include at least :
  - 6 tests : each `*.yaml` standard parses with `yq` (1 per FR-T4-STD-NNN).
  - 6 tests : each `*.yaml` standard has the required uniform frontmatter
    keys (1 per FR-T4-STD-NNN).
  - 3 tests : `state-management.yaml`, `identity.yaml`, `persistence.yaml`
    have non-empty `forbidden:` arrays.
  - 2 tests : `transport.yaml` and `state-management.yaml` declare
    `exception_constitutional: true`.
  - 2 tests : `compliance-tier.schema.json` validates with the meta-schema
    AND accepts only T1/T2/T3.
  - 2 tests : `archetype.schema.json` v2 validates with the meta-schema
    AND accepts the 6 enum values (5 canonical + `mobile-only` legacy).
  - 1 test : `archetype.schema.json` v2 rejects `flutter-firebase`
    (deprecated taxonomy).
  - 1 test : drift detector (FR-T4-LNT-002).
  - 1 test : `REVIEW.md` has 6 seed entries.
  - 1 test : `standards-lifecycle.md` lists structural exceptions.

##### FR-T4-TST-003: Harness performance budget
- **MUST** complete in ≤ 3 seconds wall-clock on a baseline laptop
  (verified via `time bash t4.test.sh`).

##### FR-T4-TST-004: Harness output format
- **MUST** match the L1/L2 convention used by `f1.test.sh`/`f2.test.sh`/
  `f4.test.sh` (PASS/FAIL/SKIP per test, total at the end).

##### FR-T4-TST-005: L2 fixture coverage
- **MUST** include at least 5 L2 fixture-based tests using a temporary
  `tmp/t4-fixtures/` directory (created and torn down by the harness).

#### Group 7 — Index registration & dispatch table (FR-T4-IDX-001 → 002, FR-T4-DSP-001)

##### FR-T4-IDX-001: Standards index registration
- **MUST** add 6 entries to `.forge/standards/index.yml` (one per
  FR-T4-STD-NNN), each with `path:`, `scope: all`, `priority: high`,
  `triggers: [<contextual list>]`.

##### FR-T4-IDX-002: `standards-lifecycle.md` registration
- **MUST** add an entry pointing to `global/standards-lifecycle.md` with
  `scope: all`, `priority: medium`, `triggers: [standards, review, lifecycle]`.

##### FR-T4-DSP-001: Dispatch-table annotation
- **MUST** annotate (NOT remove) the existing `flutter-firebase` placeholder
  in `.forge/scaffolding/dispatch-table.yml` with `status: removed_from_roadmap`
  + `reason: "Schrems II + CLOUD Act per ADR-007 (t4-adr-ratification, 2026-05-04)"`.
- **MUST** annotate `mobile-only` with `status: legacy_alias` +
  `target: mobile-pwa-first` + `migration: B.9 (T8)`.

#### Group 8 — Documentation (FR-T4-DOC-001 → 003)

##### FR-T4-DOC-001: Public `docs/STANDARDS-LIFECYCLE.md`
- **MUST** be created at the repo root `docs/` directory.
- **MUST** explain the 12-month review cycle to public adopters.
- **MUST** list the 6 standards with their `expires_at`.

##### FR-T4-DOC-002: Standard `global/source-document-pinning.md`
- **MUST** be created at `.forge/standards/global/source-document-pinning.md`.
- **MUST** document the sha256-pinning convention used by FR-T4-LNT-002.
- **MUST** document the `bin/forge-rehash-architecture-doc.sh` escape hatch
  (Q-003 resolution).

##### FR-T4-DOC-003: CHANGELOG entry
- **MUST** add an entry under `## [Unreleased]` in `CHANGELOG.md`
  flagging :
  - 6 new standards `.forge/standards/*.yaml`.
  - 2 new schemas `.forge/schemas/{compliance-tier,archetype}.schema.json`.
  - `flutter-firebase` archetype removed from roadmap.
  - `mobile-only` declared legacy alias for upcoming `mobile-pwa-first`.
  - `no-state-management-alternatives` linter rule introduced as **WARN-only**
    ; transition to ERROR planned for B.8 (T6).

### Non-Functional Requirements

##### NFR-T4-001: Harness performance
- `t4.test.sh` ≤ 8 seconds wall-clock on baseline laptop. Verified by
  `time bash` invocation in CI. Budget aligned with `f4.test.sh` actual
  performance (3.97 s / 23 tests = 173 ms/test) ; t4 has 30 tests and
  Python-fork overhead (PyYAML + jsonschema imports) dominates per-test
  cost. Original 3 s estimate was naïve. Future optimisation lever : batch
  schema validations into a single python invocation (deferred — not in
  this change's scope).

##### NFR-T4-002: File-count budget
- Total NEW files ≤ 18 :
  - 6 standards YAML
  - 2 JSON schemas (1 new + 1 modified — modification doesn't count)
  - 1 lifecycle doc
  - 1 REVIEW.md ledger
  - 1 source-document-pinning standard
  - 1 public STANDARDS-LIFECYCLE.md
  - 1 t4.test.sh
  - 1 forge-rehash-architecture-doc.sh
  - 4 budget files (e.g. `tmp/t4-fixtures/*` for L2 tests)
- Modified files ≤ 6 : `archetype.schema.json`, `index.yml`,
  `dispatch-table.yml`, `forge-ci.yml`, `verify.sh`, `CHANGELOG.md`.

##### NFR-T4-003: Backward compatibility
- **MUST NOT** break any of the 13 archived changes' validation. Verified
  by `f2.test.sh` continuing to pass against all archived `.forge.yaml`
  files. Verified by `verify.sh` aggregate `108 PASS / 0 FAIL` counter
  remaining stable (or growing only through new t4 tests).

##### NFR-T4-004: Constitution unchanged
- Constitution `.forge/constitution.md` MUST remain at v1.1.0 in this
  change. No bump to v1.2.0. Per ADR-006 of d5-governance, the
  ratification stays at the version under which it is ratified.

##### NFR-T4-005: Zero runtime code touched
- **MUST NOT** modify any file under `cli/src/`, `frontend/`, `backend/`,
  `infra/`, `examples/forge-fsm-example/`. The only allowed additions are
  declarative artefacts (YAML / JSON / Markdown) and harness scripts.

##### NFR-T4-006: Drift gate cost
- The drift gate `t4.test.sh::test_architecture_doc_hash_unchanged` MUST
  complete in ≤ 100 ms (one `shasum` call) so it remains acceptable on
  every CI run.

##### NFR-T4-007: Public discoverability
- The public `docs/ARCHETYPES.md` MUST be updated with a note pointing
  adopters to `docs/STANDARDS-LIFECYCLE.md` for the review cycle, and
  to `docs/new-archetypes-plan.md` for the post-v0.3.0 roadmap context.

##### NFR-T4-008: ADR cross-reference fidelity
- Each FR-T4-ADR-NNN line range cited above MUST resolve to the exact
  H2 section in `docs/ARCHITECTURE-TARGET.md` at the time of ratification
  (verified at hash time : if the hash matches, the line ranges are
  authoritative).

---

## MODIFIED Requirements

### `archetype.schema.json` v1 → v2

Previously :
```
enum: [default, full-stack-monorepo, mobile-only]   (or similar v1 set)
```

Now :
```
enum: [full-stack-monorepo, mobile-pwa-first, event-driven-eu, ai-native-rag, rust-cli-tui, mobile-only]
description map:
  mobile-only: "DEPRECATED — alias for mobile-pwa-first ; legacy compat only ; see B.9 (T8)."
  full-stack-monorepo: "Premium SaaS flagship — Flutter + Rust + Envoy + DBOS + Connect + Postgres."
  mobile-pwa-first: "Public-app archetype — Qwik PWA default + Flutter native iOS fallback."
  event-driven-eu: "EDA archetype — NATS JetStream + Temporal + AsyncAPI 3.1 ; NIS2/DORA-aware."
  ai-native-rag: "AI-first archetype — pgvector + LLM gateway + MCP + Qwik streaming UI."
  rust-cli-tui: "Devtools archetype — clap + ratatui + cargo-dist signed releases."
```

Reason : taxonomy revised from 4 → 5 archetypes per
`docs/ARCHITECTURE-TARGET.md` §3 and `docs/new-archetypes-plan.md` §3.7.
`mobile-only` retained as deprecation alias per Q-002 resolution.
`flutter-firebase` deliberately omitted (per ADR-007 + Schrems II + CLOUD Act
incompatibility with Forge brand positioning).

---

## REMOVED Requirements

None.

The placeholder line for `flutter-firebase` in `dispatch-table.yml` is **annotated**, not removed (FR-T4-DSP-001), to preserve the `forge upgrade` history of any adopter who already ran `forge init --archetype flutter-firebase` (no scaffold ever produced — the placeholder was inactive — but the history slot is reserved for a clean upgrade trace).

---

## Acceptance Criteria (BDD)

### Scenario: Adopter upgrades from v0.3.0 to v0.4.0-rc.1 (post-t4)

```gherkin
Given a project scaffolded via `@sdd-forge/cli@0.3.0` with archetype `mobile-only`
And the project's `.forge/scaffold-manifest.yaml` declares `framework_version: 0.3.0`
When the adopter runs `npx @sdd-forge/cli@latest upgrade`
Then `forge upgrade` reports 6 new standards files added under `.forge/standards/*.yaml`
And `forge upgrade` reports `archetype.schema.json` modified (v1 → v2)
And `forge upgrade` does NOT remove `bin/forge-init-mobile-only.sh`
And `forge upgrade` exit code is 0
```

### Scenario: Adopter runs `forge verify` after upgrade and uses Riverpod in pubspec.yaml

```gherkin
Given an upgraded project with `.forge/standards/state-management.yaml` shipped
And the project's `frontend/pubspec.yaml` lists `flutter_riverpod: ^2.5.0`
When the adopter runs `bash .forge/scripts/verify.sh`
Then `verify.sh` emits exactly one WARN line referring to `no-state-management-alternatives`
And `verify.sh` exit code is 0 (warn does not fail per FR-T4-LNT-001 / Q-001 Option A)
And `verify.sh` final report shows `WARN: 1` in addition to the existing PASS counter
```

### Scenario: Architecture document is edited (e.g. typo fix) without rehash

```gherkin
Given `docs/ARCHITECTURE-TARGET.md` is edited (any byte change)
And `bin/forge-rehash-architecture-doc.sh` has NOT been run
When `t4.test.sh::test_architecture_doc_hash_unchanged` runs in CI
Then the test FAILs with message "ARCHITECTURE-TARGET.md drift detected ; expected sha256 cd8fef… ; actual sha256 <new>"
And the harness exit code is non-zero
And the CI gate `forge-ci / harness` blocks the PR
```

### Scenario: Maintainer rehashes after a reviewed edit

```gherkin
Given `docs/ARCHITECTURE-TARGET.md` was edited and the maintainer reviewed the diff
When the maintainer runs `bash bin/forge-rehash-architecture-doc.sh`
Then the script computes a fresh sha256 of the document
And updates the Source Document table in `.forge/changes/t4-adr-ratification/specs.md`
And prints the old and new hash for audit trail
And appends an entry to `.forge/changes/t4-adr-ratification/REHASH-LOG.md` (created on demand)
```

### Scenario: New standard reaches `expires_at`

```gherkin
Given `observability.yaml` declares `expires_at: 2027-05-04`
And the system date is 2027-05-05
When the constitution-linter runs (or `t4.test.sh::test_no_expired_standards`)
Then the linter emits a WARN line "Standard observability.yaml expired on 2027-05-04 ; review required"
And the WARN does not fail CI (review is a Themis-driven monthly cadence ; not blocking)
And the WARN points the maintainer to `.forge/standards/REVIEW.md` for action
```

### Scenario: Architect attempts to set `mobile-only` as the value of `archetype` in a fresh `.forge/changes/<X>/.forge.yaml`

```gherkin
Given `archetype.schema.json` v2 is shipped
And a maintainer creates a new change with `archetype: mobile-only` in the .forge.yaml
When `f2.test.sh` validates the change
Then validation PASSES (legacy alias accepted)
And the description field surfaces "DEPRECATED — alias for mobile-pwa-first" via the schema validator
And no migration is forced at this stage (B.9 in T8 will issue an active deprecation warning)
```

---

## Anti-hallucination pass

- Every FR is testable via `t4.test.sh`. Tests are listed inline in
  Group 6.
- No FR depends on un-shipped agents (Themis is referenced as a future
  hook, never as a precondition for a test in this change).
- Constitution articles I, III, IV, V, IX, X, XII are explicitly
  addressed in `proposal.md::Constitution Compliance` ; II, VI, VII,
  VIII, XI are inapplicable and that inapplicability is justified.
- The 10 ADR line ranges cited above were extracted from the live
  `docs/ARCHITECTURE-TARGET.md` at sha256 `cd8fef37…3de925` (1116 lines).
  Any future drift triggers FR-T4-LNT-002 / NFR-T4-006.
- `[NEEDS CLARIFICATION:]` markers : none in this `specs.md` ; all
  ambiguities were resolved as Q-001 / Q-002 / Q-003 in `open-questions.md`
  (status `answered`).
