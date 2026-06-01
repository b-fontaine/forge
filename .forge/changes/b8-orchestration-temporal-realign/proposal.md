# Proposal: b8-orchestration-temporal-realign

<!-- Created: 2026-05-31 -->
<!-- Schema: default -->
<!-- Audit: B.8.5 follow-on (docs/new-archetypes-plan.md §4.2) — orchestration default reconciliation with Constitution Article VIII.2; ADR-002 (ARCHITECTURE-TARGET.md) fate finalised -->

## Problem

`b8-5-postgres-pgvector` (archived 2026-05-31) discovered that **DBOS has no
Rust SDK** (`cargo add dbos` → 404; DBOS Transact ships Python / TypeScript /
Go / Java / Kotlin only — `docs.dbos.dev`, verified 2026-05-31) and, under time
pressure with another session in flight, took an **interim** position rather
than resolve the orchestration default:

- `orchestration.yaml` bumped 1.0.0 → **1.1.0**, but `default: dbos` left
  **UNCHANGED** and annotated *"language-conditional aspirational target"* via a
  new `rust_sdk_status.dbos` body field (`available: false`,
  `rust_flagship_orchestrator: temporal`, `default_is_language_conditional:
  true`).
- `2.0.0.yaml` `dbos-embedded` component → `status: deferred` + note; the
  `temporal-intent → dbos-embedded` migration_delta → `note:` (kept, marked
  pending a future Rust DBOS SDK).

This interim leaves a **latent contradiction the maintainer has now decided to
close** (C-map + DBOS watch-list, 2026-05-31):

1. **`default: dbos` is unbuildable across the entire Forge surface, not merely
   "deferred".** DBOS's whole value (embedded library, your-existing-Postgres,
   −1 control plane) **only exists if there is a library in your language**.
   Forge backends are **Rust end-to-end** — `full-stack-monorepo` is
   `tonic + axum + tokio`, and `ai-native-rag` (B.7) is also planned as
   `axum + DBOS` (plan §3.6). There is no `dbos` Rust crate, so DBOS delivers
   **none** of its advertised benefits to **any** Forge archetype today. This is
   "the SDK for our language never existed", not "wait for it to mature".
2. **Constitution Article VIII.2 ALREADY mandates Temporal.** `constitution.md`
   §VIII.2 (v1.1.0): *"Long-running, multi-step workflows that span microservices
   **SHALL use Temporal** for orchestration."* `default: dbos` in the standard is
   therefore in tension with the Constitution. **ADR-002** (`Temporal → DBOS par
   défaut`, `docs/ARCHITECTURE-TARGET.md:328`) was a *KEEP-WITH-CHANGES* proposal
   that would have required **amending VIII.2** — an amendment that **never
   happened**. With DBOS-no-Rust-SDK, that amendment **must not** happen.
3. **Temporal is the buildable incumbent.** It has an **official Rust SDK**
   (`temporalio-sdk`, version line 0.4.0, **Public Preview** per
   `github.com/temporalio/sdk-core`), Forge already ships a `temporal.md`
   standard, `full-stack-monorepo / 1.0.0` already named Temporal
   (`ARCHITECTURE-TARGET.md:103` + C4 `Rel(rust, temporal, "gRPC")`), and
   `event-driven-eu` (B.6) is specified on Temporal. The B.8.1 baseline found
   **no orchestration worker deployed** (doc-only) → **migration cost ≈ 0**; the
   choice is purely which orchestrator we *name as default* and *write templates
   for*.

**Ground truth (re-read 2026-05-31, Article III.4):**

- `orchestration.yaml` is **v1.1.0**: frontmatter `default: dbos` (line 20,
  annotated "UNCHANGED — language-conditional"), `fallback: temporal` (21),
  `fallback_trigger` (22), plus the B.8.5 `rust_sdk_status.dbos` body block
  (28–47) recording DBOS-Rust-absence + `rust_flagship_orchestrator: temporal`.
  It is a J.7 standard validated by `bin/validate-standards-yaml.sh`
  (frontmatter contract + REVIEW.md row + `expires_at > last_reviewed`), **not**
  by the b8-3 schema tests.
- `2.0.0.yaml` `dbos-embedded` (lines 72–81): `role: workflow-orchestration`,
  `replaces: temporal-intent`, `standard: orchestration.yaml`,
  `status: deferred`, `note:` (DBOS-no-Rust-crate). The header (line 19) cites
  *"Constitution v1.1.0 §VIII.2 mandates Temporal for workflow orchestration."*
  The `temporal-intent → dbos-embedded` migration_delta (lines 120–127) carries
  a `note:` deferring to a future Rust DBOS SDK. Editing `2.0.0.yaml` is
  permitted (it is the **candidate**, not the frozen 1.0.0 `schema.yaml`) but is
  tightly coupled to `b8-3.test.sh` (17 L1) + `b8-3b.test.sh` (12 L1): forbidden
  component keys `{version, pin, image}`, no component direct scalar matching
  `^\d+\.\d+`, `standard:` refs must resolve, every component needs `name`, the
  `postgres-17-pgvector` component + its `migration_note` + the postgres delta
  must stay intact.
- `temporal.md` (markdown standard, `index.yml` id `infra/temporal`) uses the
  **community** crate API `temporal_sdk::{WfContext, workflow}` /
  `temporal_client` — **not** the official `temporalio-sdk` 0.4.0 API. **API
  drift**, same class as `t5-otel-dartastic-realign` (Workiva fabricated API)
  and the `t5-connect-codegen` Rust pivot.
- **No Constitution amendment is needed.** Contrast B.8.4: VIII.1 (Kong SHALL)
  required a deferred amendment because Envoy *replaces* Kong. Here VIII.2
  **already says Temporal** — making Temporal the real default *aligns* the
  standard with the Constitution; it does not amend it.

## Solution

Author the **specification** for reconciling the workflow-orchestration default
with Constitution Article VIII.2 under the maintainer's **C-map + watch-list**
decision. This change is **propose + specify** (then design / plan / implement):
it ships **no concrete version pins as code** — the `temporalio-sdk` crate
version is **verify-then-pin LIVE at `/forge:implement`** (Context7 +
crates.io/docs.rs), never fabricated.

When built, the reconciliation MUST:

1. **`orchestration.yaml` additive bump 1.1.0 → 1.2.0 — `default_by_language`
   map (C-map).** Replace the flat `default: dbos` semantics with an explicit
   language-keyed default whose Rust entry is **Temporal**
   (`default_by_language: { rust: temporal }`), promoting the B.8.5
   `rust_flagship_orchestrator: temporal` field from a buried note to the real
   default semantics. `fallback` / `fallback_trigger` semantics revisited for
   coherence (Temporal is no longer a "fallback" for Rust — it is the default).
   The exact retention/removal of the old `default:` / `fallback:` keys for
   back-compat is a design call (→ Q-002).
2. **Demote DBOS to a WATCH-LIST FUTURE-OPTION (NOT deleted).** A `dbos:` block
   recording `status: future-option`, `requires: <rust SDK GA>`,
   `revisit: <standard review cadence>` — door open if a production-grade Rust
   DBOS SDK ever ships, re-evaluated at the J.7 review cadence. The architecture
   analysis is preserved; only the *default* claim is withdrawn.
3. **Reconcile, don't amend.** A new ADR (`ADR-B8O-001`) records that the
   orchestration default is realigned with Constitution VIII.2 (Temporal), that
   **ADR-002's Temporal→DBOS swap is CANCELLED** (not merely deferred) for Rust,
   and that **no Constitution amendment is required** (VIII.2 already mandates
   Temporal). Because this cites the Constitution, it requires an **INDEPENDENT
   reviewer** — author/reviewer separation is non-negotiable, no self-approval
   (lesson `t5_2_self_validation_lesson`).
4. **`2.0.0.yaml` reclassify (candidate edit).** `dbos-embedded` moves from
   `status: deferred` (waiting on DBOS) to **Temporal-retained / future-option**
   (no replacement of Temporal); the `temporal-intent → dbos-embedded`
   migration_delta is **CANCELLED**, not deferred. The exact shape MUST keep
   `b8-3.test.sh` (17/17) + `b8-3b.test.sh` (12/12) GREEN; the b8-5 exit-code
   coupling-guard pattern re-runs both. Whether removing/altering the
   `temporal-intent → dbos-embedded` delta trips any b8-3 positive assertion is
   verified against `b8-3.test.sh` source at design, not assumed (→ Q-003).
5. **`temporal.md` API realign (verify-then-pin).** Realign the code samples and
   any `versions:` pin to the **official `temporalio-sdk` 0.4.0 API**, with the
   crate version **verified live at `/forge:implement`** and the
   **Public-Preview / pre-GA caveat recorded** in the standard. Do NOT fabricate
   the API surface (Article III.4). Scope of the realign (full rewrite vs
   targeted import/crate-name fix) is a design call (→ Q-004).
6. **Roadmap deltas (`docs/new-archetypes-plan.md`).** Strike the dead B.8.5
   "Templates DBOS embedded" premise (already re-scoped); drop the DBOS leg of
   B.8.10 Phase-2; drop the B.8.13 "DBOS Postgres saturé > 70 % → fallback
   Temporal" rollback criterion (moot); add a B.6.2 simplification note that the
   **native Rust `temporalio-sdk`** replaces the planned "Temporal Go SDK via FFI
   ou client REST". Whether these doc edits land in THIS change or a sibling
   doc-only change is a scope call (→ Q-005).

Decisions reserved for `/forge:design` (ADRs), leanings stated, open where
genuinely undecided (see `open-questions.md`):

- **ADR-B8O-001 — orchestration default reconciled with VIII.2 (Temporal);
  ADR-002 Temporal→DBOS swap cancelled for Rust; no Constitution amendment.**
  **Lean:** as stated above — VIII.2 already mandates Temporal, so this aligns
  the standard with the Constitution. ADR-002 in `ARCHITECTURE-TARGET.md` is a
  planning-doc ADR; how it is annotated as "not-proceeding" (edit the source doc
  under `source-document-pinning.md` vs record-only in this change's design) is
  itself open (→ Q-001).
- **ADR-B8O-002 — `orchestration.yaml` shape: `default_by_language` map +
  `dbos:` future-option block.** **Lean:** add `default_by_language: { rust:
  temporal }` + a `dbos: { status: future-option, requires, revisit }` block;
  decide whether to keep, rewrite, or drop the legacy flat `default:` /
  `fallback:` keys for reader back-compat (→ Q-002).
- **ADR-B8O-003 — `2.0.0.yaml` reclassify + migration_delta cancellation,
  b8-3/b8-3b-safe.** **Lean:** `dbos-embedded` → future-option annotation
  (keys ∉ {version,pin,image}, no `^\d+\.\d+` scalar); cancel the
  `temporal-intent → dbos-embedded` delta; verify against `b8-3.test.sh` source
  whether the delta is positively asserted (→ Q-003).
- **ADR-B8O-004 — `temporal.md` realign scope + pin policy.** **Lean:** realign
  to `temporalio-sdk` 0.4.0, verify-then-pin at implement, Public-Preview caveat
  in frontmatter; full-rewrite vs targeted-fix decided at design (→ Q-004).

Release vehicle: maintainer-set (additive standards bump + candidate-schema edit
+ markdown-standard realign; no change to default 1.0.0 scaffolding behaviour;
2.0.0 candidate stays `scaffoldable: false`).

## Scope In

- `proposal.md`, `specs.md`, `design.md`, `tasks.md`, `.forge.yaml`,
  `open-questions.md` for `b8-orchestration-temporal-realign`.
- Requirement set (`FR-B8O-*` / `NFR-B8O-*`) defining WHAT the reconciliation
  touches: the `orchestration.yaml` 1.1.0 → 1.2.0 additive bump
  (`default_by_language` map + `dbos:` future-option block + REVIEW.md
  KEEP-WITH-CHANGES row + `index.yml` triggers refresh), the `2.0.0.yaml`
  candidate reclassification + migration_delta cancellation, the `temporal.md`
  API realign, and the roadmap deltas.
- ADRs `ADR-B8O-001..004` (orchestration-default reconciliation, standard shape,
  schema-candidate reclassify, temporal.md realign).
- Identification (via Context7) of the official `temporalio-sdk` crate
  coordinates + Public-Preview status, with the **concrete version pin deferred
  to verify-then-pin at `/forge:implement`**.
- Re-run guards: `b8-3.test.sh` (17/17) + `b8-3b.test.sh` (12/12) +
  `j7`/`validate-standards-yaml.sh` GREEN after the standard + candidate edits;
  FULL harness suite before any push (shared-standard sibling coupling).

## Scope Out (Explicit Exclusions)

- **Concrete `temporalio-sdk` version pin** — verify-then-pin LIVE at
  `/forge:implement` (Context7 + crates.io/docs.rs), never fabricated in
  propose/specify/design.
- **Deploying / scaffolding a Temporal worker or cluster** — `full-stack-
  monorepo` Temporal worker templates (`worker.rs` boilerplate, workflows/
  activities) are downstream template work (the old B.8.5 "DBOS embedded
  templates" slot, now a Temporal-worker slot), NOT this reconciliation.
- **Removing DBOS from the architecture analysis** — DBOS stays as a
  **watch-list future-option**; this change withdraws only the *default* claim.
- **Amending the Constitution** — none needed; VIII.2 already mandates Temporal.
  (Contrast B.8.4's VIII.1 amendment, deferred to B.8.14.)
- **`event-driven-eu` (B.6) build-out** — B.6 already specs Temporal; this
  change only adds a forward note that the native Rust SDK supersedes the planned
  FFI/REST-to-Go approach.
- **Schema bump 1.0.0 → 2.0.0 / Kong-Temporal-REST removal** — B.8.14 territory.
- **Editing the frozen 1.0.0 `schema.yaml` or 1.0.0 template tree** — additive /
  candidate-only edits.

## Impact

- **Users affected**: B.8 migration architects + B.7 (`ai-native-rag`, which
  inherits the corrected Rust-orchestrator default before it hits the same DBOS
  wall) + B.6 (`event-driven-eu`, simplified to the native Rust SDK). **No effect
  on current 1.0.0 adopters** — `orchestration.yaml` is `ci_blocking: false`, the
  2.0.0 candidate is `scaffoldable: false`, and no worker is deployed today.
- **Technical impact**: `orchestration.yaml` 1.1.0 → 1.2.0 (additive body shape);
  `2.0.0.yaml` candidate reclassify + delta cancellation; `temporal.md` API
  realign; `REVIEW.md` + `index.yml` ledger updates; roadmap doc deltas.
  **Net architectural effect: one fewer breaking swap in B.8** (2.0.0 = Envoy +
  Connect + Zitadel + obs, no DBOS), and the **B.8.13 DBOS-saturation rollback
  path removed** → T6 de-risked.
- **Dependencies**: depends on B.8.5 (the v1.1.0 standard + the 2.0.0.yaml
  dbos-embedded state this change reclassifies), B.8.3 + B.8.3.b (the candidate
  schema + its test coupling). Sequenced **after** B.8.5 archive (done) to avoid
  collision on `orchestration.yaml` / `2.0.0.yaml`.

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: propose+specify gate; no
  implementation precedes it. The standard/candidate/temporal.md edits are made
  only after design from these specs.
- **Article III.4 (Anti-Hallucination)**: the live `orchestration.yaml` v1.1.0
  state, the `2.0.0.yaml` dbos-embedded block + migration_delta, the b8-3/b8-3b
  coupling, the `temporal.md` community-crate drift, and Constitution §VIII.2 are
  re-read from live files. DBOS-no-Rust-SDK is verified (crates.io 404 + DBOS
  docs). The `temporalio-sdk` version + API are sourced from Context7 with the
  **concrete pin deferred to verify-then-pin at implement** (kong/b8-coroot/
  b8-signoz lesson + `t5-otel-dartastic-realign`).
- **Article IV (Delta-based)**: additive standard bump (root
  `additionalProperties: true` permits the new body fields); candidate-schema
  edit only (the candidate is editable; the frozen 1.0.0 surface is not touched).
- **Article V (Compliance gate)**: ADRs map each open question to a design-phase
  resolution; the constitutional citation (VIII.2 + ADR-002 cancellation)
  requires an **INDEPENDENT reviewer** (author/reviewer separation,
  `t5_2_self_validation_lesson`), and the standard + candidate edits re-run the
  full harness suite before push (`full_harness_suite_before_push`,
  `shared_standard_sibling_harness_coupling`).
- **Article VIII.2 (Temporal SHALL — IN FORCE, and this change ALIGNS with it)**:
  Constitution v1.1.0 §VIII.2 mandates Temporal for workflow orchestration.
  Making Temporal the real default-by-language for Rust **brings the
  `orchestration.yaml` standard into alignment** with VIII.2 (the v1.1.0
  "language-conditional `default: dbos`" was the deviation). **No amendment is
  required** — contrast Article VIII.1 (Kong), where Envoy *replaces* Kong and an
  amendment is deferred to B.8.14.
- **Article XII (Governance)**: no Constitution amendment here. ADR-002 lives in
  the planning doc `ARCHITECTURE-TARGET.md`; its Temporal→DBOS swap is recorded
  as cancelled-for-Rust via this change's `ADR-B8O-001` (annotation mechanism →
  Q-001).

## Open Questions (seed)

- **Q-001** — ADR-002 annotation mechanism: edit `docs/ARCHITECTURE-TARGET.md`
  (under `global/source-document-pinning.md`) to mark ADR-002 superseded, vs
  record-only in this change's `design.md` ADR-B8O-001 (→ ADR-B8O-001; open).
- **Q-002** — `orchestration.yaml` shape: `default_by_language: { rust: temporal
  }` + `dbos:` future-option block; keep vs rewrite vs drop the legacy flat
  `default:` / `fallback:` / `fallback_trigger:` keys for reader back-compat,
  while keeping `validate-standards-yaml.sh` (J.7) GREEN (→ ADR-B8O-002; open).
- **Q-003** — `2.0.0.yaml` reclassify + `temporal-intent → dbos-embedded` delta
  cancellation: verify against `b8-3.test.sh` source whether the delta is
  positively asserted; choose a future-option annotation that keeps b8-3 (17/17)
  + b8-3b (12/12) GREEN (keys ∉ {version,pin,image}; no `^\d+\.\d+`) (→
  ADR-B8O-003; open).
- **Q-004** — `temporal.md` realign scope: full rewrite to `temporalio-sdk` 0.4.0
  vs targeted import/crate-name fix; whether a `versions:` pin block is added to
  the markdown standard or the pin lives in template `Cargo.toml` only;
  Public-Preview/pre-GA caveat placement — **crate version verify-then-pin at
  `/forge:implement`** (→ ADR-B8O-004; open).
- **Q-005** — roadmap doc deltas (B.8.5 strike / B.8.10 Phase-2 / B.8.13
  rollback / B.6.2 FFI→native note): land in THIS change vs a sibling doc-only
  change (→ scope call at design; open).
