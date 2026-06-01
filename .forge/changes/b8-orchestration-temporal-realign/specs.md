# Specifications: b8-orchestration-temporal-realign

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.5 follow-on (docs/new-archetypes-plan.md §4.2) — orchestration default reconciled with Constitution Article VIII.2; ADR-002 Temporal→DBOS swap cancelled for Rust -->

**Namespace** : `FR-B8O-*` / `NFR-B8O-*` / `ADR-B8O-*`.
**Constitution** : v1.1.0, **unchanged (NO amendment)**. Article VIII.2 (Temporal
SHALL) is the *anchor*: this change brings `orchestration.yaml` into **alignment**
with VIII.2 — it does not amend it. (Contrast B.8.4, where Envoy *replaces* Kong
and a VIII.1 amendment is deferred to B.8.14.)
This change is **propose + specify** here; the standard/candidate/markdown edits
and the roadmap deltas land in design → plan → implement. It ships **no concrete
crate version pin** — the `temporalio-*` crate version is **verify-then-pin LIVE
at `/forge:implement`** (crates.io / docs.rs), never fabricated.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-
Hallucination — DBOS-Rust-absent + Temporal-native-Rust-SDK-pre-alpha recorded;
never invent versions/APIs), IV (delta-based: additive standard bump + candidate
edit; frozen 1.0.0 surface untouched), V (compliance gate; INDEPENDENT reviewer
for the constitutional citation), VIII.2 (Temporal SHALL — ALIGNED), X (J.7
standard contract), XII (governance — ADR-002 is a planning-doc ADR; no
Constitution amendment).

## CENTRAL FINDING — `default: dbos` is unbuildable; Temporal is mandated and buildable (Article III.4)

Two prongs, both verified 2026-05-31 / 2026-06-01:

| # | Evidence | Finding |
|---|----------|---------|
| 1 | crates.io (`cargo add dbos` → 404); DBOS Transact SDKs = Python/TS/Go/Java/Kotlin only (`docs.dbos.dev`, Context7) | **DBOS has NO Rust SDK.** Forge backends are Rust end-to-end (`full-stack-monorepo` = tonic+axum+tokio; `ai-native-rag`/B.7 = axum+…). So `default: dbos` delivers **none** of its rationale (embedded lib / your-Postgres / −1 control plane) to ANY Forge archetype — it is **unbuildable**, not merely "deferred". |
| 2 | `constitution.md` §VIII.2 (v1.1.0): *"Long-running, multi-step workflows that span microservices **SHALL use Temporal** for orchestration."* | The Constitution **already mandates Temporal**. `default: dbos` in `orchestration.yaml` is the deviation; aligning the default to Temporal **needs no amendment**. |
| 3 | Context7 `/temporalio/sdk-core`; `github.com/temporalio/sdk-core` | **Temporal IS buildable in Rust today** via the production **Core** crates (`temporalio-sdk-core`, `temporalio-client` — the same Core that powers the TS/Python/.NET/Ruby SDKs). The **high-level native `temporalio-sdk` crate is a pre-alpha prototype** (see Context7 Evidence below) — generally functional, but unstable. **pre-alpha SDK > no SDK.** |

**Conclusion (maintainer decision, C-map + DBOS watch-list, 2026-05-31):**
make Temporal the **default-by-language for Rust** in `orchestration.yaml`; demote
DBOS from `default` to a **watch-list `future-option`** (NOT deleted — re-evaluated
if a production-grade Rust DBOS SDK ships); cancel ADR-002's Temporal→DBOS swap for
Rust; realign `temporal.md` to the real Temporal Rust API (verify-then-pin), with
the native-SDK stability caveat recorded.

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4.6 (orchestration matrix), ADR-002 (`docs/ARCHITECTURE-TARGET.md:328`, *Temporal→DBOS par défaut*), §4.2 B.8.5/B.8.10/B.8.13, §6.1 B.6.2 (`Temporal Go SDK via FFI ou client REST`) |
| **orchestration.yaml (observed)** | `.forge/standards/orchestration.yaml` **v1.1.0** (B.8.5): `default: dbos` (line 20, annotated "language-conditional"), `fallback: temporal` (21), `fallback_trigger` (22), `forbidden: [inngest]`, + `rust_sdk_status.dbos` body block (28–47: `available:false`, `rust_flagship_orchestrator: temporal`, `default_is_language_conditional: true`). J.7-validated by `bin/validate-standards-yaml.sh`. NOT covered by b8-3 tests |
| **2.0.0.yaml (observed)** | `.forge/schemas/full-stack-monorepo/2.0.0.yaml` (candidate, `scaffoldable:false`): header line 19 cites *"Constitution v1.1.0 §VIII.2 mandates Temporal"*; component `dbos-embedded` (72–81: `role: workflow-orchestration`, `replaces: temporal-intent`, `standard: orchestration.yaml`, `status: deferred`, `note:`); migration_delta `temporal-intent → dbos-embedded` (120–127, `note:`) |
| **temporal.md (observed)** | `.forge/standards/infra/temporal.md` (markdown; `index.yml` id `infra/temporal`). Code samples use a **fabricated/drifted API**: `#[workflow]` / `#[activity]` attribute macros + `temporal_sdk::{WfContext, workflow}` — does NOT match the real closure-registration API (`worker.register_wf(name, closure)` / `worker.register_activity(name, closure)`) — see Context7 Evidence |
| **adr-ratification.md (observed)** | `.forge/specs/adr-ratification.md:47` lists *"ADR-002 (DBOS default)"* among the 10 ratified ADRs; the consolidated spec carries NO hard "MUST be dbos" operational FR (that lived in the archived `t4-adr-ratification` change specs) — MODIFIED entry below records the supersession |
| **Standard additive-bump precedent** | `transport.yaml` 1.0.0→1.1.0→1.2.0, `observability.yaml`→v2.1.0 (KEEP-WITH-CHANGES body fields + REVIEW.md rows). REVIEW.md append-only (Article XII); J.7 = `bin/validate-standards-yaml.sh` |
| **Test harness coupling** | `b8-3.test.sh` (17 L1): forbids component keys `{version,pin,image}` (T-012), forbids component direct scalar `^\d+\.\d+` (T-015), `standard:` refs resolve (T-011), every component has `name` (T-010), postgres `migration_note` + postgres delta intact (T-016). `b8-3b.test.sh` (12 L1). Editing 2.0.0.yaml MUST keep both GREEN |
| **External research** | Context7 `/temporalio/sdk-core` (Rust API + pre-alpha status), `docs.dbos.dev` (DBOS languages — no Rust). Crate version + exact crate name **verify-then-pin at implement** |
| **Downstream** | B.6 (event-driven-eu — native Rust SDK supersedes planned FFI/REST-to-Go), B.7 (ai-native-rag — inherits corrected Rust default), B.8.10/B.8.12/B.8.14 |
| **Release target** | maintainer-set |

## Context7 Evidence (Article III.4 — verbatim, accessed 2026-06-01)

**Source: `github.com/temporalio/sdk-core` README (via Context7 `/temporalio/sdk-core`):**

> "This repo contains a *prototype* Rust sdk in the `sdk/` directory. This SDK
> should be considered **pre-alpha** in terms of its API surface. Since it's still
> using Core underneath, it is generally functional. **We do not currently have
> any firm plans to productionize this SDK.** If you want to write workflows and
> activities in Rust, feel free to use it - but be aware that the API may change at
> any time without warning and we do not provide any support guarantees."

> "Core is composed of multiple crates: **temporalio-client** for gRPC
> communication, **temporalio-common** for shared types and protobuf definitions,
> **temporalio-sdk-core** for the workflow execution engine,
> **temporalio-sdk-core-c-bridge** for FFI bindings, and a **prototype
> temporalio-sdk** for native Rust workflows."

**Real native Rust API shape (Context7 snippet) — closure registration, NOT attribute macros:**

```rust
let mut worker = Worker::new_from_core(Arc::new(core_worker), "order-processing");
worker.register_activity("process_payment", |_ctx: ActContext, input: OrderInput| async move { /* … */ });
worker.register_wf("OrderWorkflow", |ctx: WfContext| async move {
    let input: OrderInput = ctx.get_args()?;
    let valid: bool = ctx.activity("validate_inventory").start_with_args(&input).await?;
    Ok(WfExitValue::Normal(/* … */))
});
worker.run().await?;
```

→ confirms `temporal.md`'s `#[workflow]`/`#[activity]` macro samples are drifted/
fabricated. **The exact crate name (`temporalio-sdk` vs import `temporal_sdk`), version,
and whether to consume the prototype `temporalio-sdk` or the production
`temporalio-sdk-core` + `temporalio-client` directly are VERIFY-THEN-PIN at
`/forge:implement`** (Q-004 + Q-006). No version is asserted here.

---

## ADDED Requirements

### Cluster 1 — `orchestration.yaml` C-map bump (FR-B8O-001 → 008)

##### FR-B8O-001 — Temporal is the default orchestrator for Rust
`orchestration.yaml` MUST express Temporal as the **default** workflow
orchestrator for Rust archetypes (`full-stack-monorepo`, `ai-native-rag`), not a
"fallback". The shape SHOULD be a `default_by_language` map with `rust: temporal`
(ADR-B8O-002 / Q-002), promoting the B.8.5 `rust_flagship_orchestrator: temporal`
field into first-class default semantics.

##### FR-B8O-002 — DBOS demoted to watch-list future-option (NOT deleted)
`orchestration.yaml` MUST retain DBOS as a **`future-option`** block recording at
minimum: `status: future-option`, a `requires:` gate (production-grade Rust DBOS
SDK GA), and a `revisit:` cadence. DBOS MUST NOT be deleted (the architecture
analysis + the door for a future Rust SDK are preserved). The `default: dbos`
fiction MUST NOT remain the headline default for Rust.

##### FR-B8O-003 — additive version bump 1.1.0 → 1.2.0
The edit MUST be an additive bump `1.1.0 → 1.2.0` (no `breaking_change: true`),
mirroring `transport.yaml`'s additive-bump precedent. The new keys
(`default_by_language`, `dbos` block) are body fields permitted by root
`additionalProperties: true` (gateway.yaml/observability.yaml precedent).

##### FR-B8O-004 — J.7 frontmatter contract preserved
After the bump, `bin/validate-standards-yaml.sh` MUST stay GREEN (dir-mode and
file-mode): `last_reviewed`/`expires_at` reset with `expires_at > last_reviewed`
(FR-J7-021), `exception_constitutional: false` preserved (dated expiry ⇒ false,
FR-J7-020), `linter_rule: null` unchanged.

##### FR-B8O-005 — REVIEW.md KEEP-WITH-CHANGES row (mandatory)
A `| orchestration.yaml | 1.2.0 | …` KEEP-WITH-CHANGES row MUST be appended to
`.forge/standards/REVIEW.md` (append-only, Article XII). Its absence FAILs J.7
(FR-J7-023). The row MUST cite the C-map realign + ADR-B8O-001.

##### FR-B8O-006 — `rust_sdk_status` block reconciled, not contradicted
The B.8.5 `rust_sdk_status.dbos` block MUST be reconciled with the new shape (the
v1.2.0 default-by-language map makes `rust_flagship_orchestrator: temporal`
authoritative). The block MUST NOT be left asserting a "language-conditional
`default: dbos`" that the new `default_by_language` contradicts. The folded `dbos:`
block MUST retain the **`available: false`** fact (DBOS still has no Rust SDK), so
the repurposed `b8-5.test.sh` T-006 can keep asserting it (FR-B8O-017).

##### FR-B8O-007 — `index.yml` triggers remain valid
`.forge/standards/index.yml` entry `standards/orchestration` (triggers include
`orchestration, dbos, temporal, durable execution, …`) MUST remain reachable
(FR-J7-050) and SHOULD keep `temporal` + `dbos` as triggers (both are still
referenced by the standard).

##### FR-B8O-008 — legacy `default:`/`fallback:` key disposition recorded
Whether the flat `default:` / `fallback:` / `fallback_trigger:` keys are kept,
rewritten, or dropped MUST be an explicit ADR decision (ADR-B8O-002 / Q-002),
verified against any consumer that hard-reads them (grep `index.yml`, linters,
schema `standard:` resolvers, `validate-standards-yaml.sh`). No silent removal.

##### FR-B8O-017 — sibling harness `b8-5.test.sh` T-006 AND T-010 repurposed (CRITICAL coupling)
Two `b8-5.test.sh` tests (both registered in CI, `forge-ci.yml`) hard-read state
this change flips — found by INDEPENDENT review 2026-06-01 (lesson
`shared_standard_sibling_harness_coupling`):

- **T-006** (`_test_b85_l1_006_dbos_deferral_recorded`, lines 148-181) asserts
  (a) `^default:\s*dbos$` (line 158), (b) `2.0.0.yaml` `dbos-embedded`
  `status == deferred` (lines 170-178), plus `rust_sdk_status` + `available:
  false` greps (151-154).
- **T-010** (`_test_b85_l1_010_deltas_deferred_and_intact`, lines 252-285) selects
  the migration_delta with `to == 'dbos-embedded'` (line 262) and **requires its
  `note` to match `*DEFERRED*` / `*no Rust SDK*`** (lines 277-281); else FAIL. The
  postgres-16 delta intact check (line 283) is unaffected.

Both flip under this change ⇒ RED on `main` if not retargeted. This change MUST
**repurpose** both (NOT delete — guards retained, retargeted; FR/ADR comments
record the ADR-B8O-002/003 supersession):
- **T-006**: keep the `available: false` assertion (whole-file grep, satisfied by
  the folded `dbos:` block, `:153`); REPLACE `^default: dbos` with
  `default_by_language.rust == temporal`; REPLACE `dbos-embedded status ==
  deferred` with `status == future-option`. **WATCH (implement):** T-006 also
  whole-file-greps the literal token `rust_sdk_status` (`:151`); the fold
  (FR-B8O-006) moves that data into `dbos:`, so the repurpose MUST retarget that
  grep (assert the `dbos:` block) — do NOT leave a dangling `rust_sdk_status`
  literal assertion.
- **T-010**: REPLACE the `note` `*DEFERRED*`/`*no Rust SDK*` assertion with the new
  cancelled-state invariant — the `temporal-intent → dbos-embedded` delta carries
  `cancelled: true` (and a note recording the no-Rust-SDK cancellation reason).
  KEEP the postgres-16-delta-intact assertion (line 283) unchanged.

##### FR-B8O-018 — stale "dbos (default)" remediation text updated (TWO sites)
Two remediation hints advertise DBOS as the orchestration default and go stale
after the flip (the second was found by INDEPENDENT review 2026-06-01):

- **`.forge/scripts/constitution-linter.sh:802`** — Python `REMEDIATION` dict
  string `"inngest": "replace with DBOS (orchestration.yaml::default) or Temporal
  fallback"`. Update to point at Temporal as default (e.g. `"replace with Temporal
  (orchestration.yaml::default_by_language) — DBOS is a future-option pending a
  Rust SDK"`). String-only; the T3-RULE-003 mapping (line 790) and the `forbidden:
  [inngest]` rule are unchanged.
- **`.forge/standards/global/forbidden-components-rules.md:62`** — the T3-RULE-003
  table Remediation cell `Replace with \`dbos\` (default) OR \`temporal\`
  (fallback) OR downgrade tier` (Cross-link ADR-002). Update to
  `Replace with \`temporal\` (\`orchestration.yaml::default_by_language\`, §VIII.2)
  OR downgrade tier; \`dbos\` is a future-option pending a Rust SDK`, cross-link →
  ADR-B8O-001 inline. NOT CI-content-asserted (i3 checks only the T3-RULE-003
  anchor + frontmatter). **LIVE-corrected (evidence.md §3):** `i3.test.sh:169`
  hard-pins `version: 1.0.0` on this file ⇒ a version bump would turn i3 RED, and
  the file is OUT of J.7 scope (`*.yaml` only). So the edit is **text-only, NO
  version bump, NO REVIEW row** (overrides the bump-if-versioned note). Cross-link
  stays `ADR-002` (rule provenance; `inngest` still forbidden). MUST NOT introduce
  a forbidden-token cross-mention that trips T3-RULE-006 (`temporal`/`dbos` are not
  forbidden tokens — only `inngest` is).

##### FR-B8O-019 — `2.0.0.yaml` stale inline comment corrected (MINOR)
The `2.0.0.yaml` `dbos-embedded` `standard:` line inline comment (line 76)
`# default: dbos (language-conditional; see orchestration.yaml…)` MUST be corrected
to reflect the Temporal default when the component is reclassified (FR-B8O-010).
Comment-only; not test-coupled.

### Cluster 2 — `2.0.0.yaml` candidate reclassify, b8-3/b8-3b-safe (FR-B8O-010 → 016)

##### FR-B8O-010 — `dbos-embedded` reclassified deferred → future-option
The `dbos-embedded` component MUST be reclassified from `status: deferred`
(waiting on DBOS) to a **future-option / Temporal-retained** annotation reflecting
that Temporal is NOT being replaced. The annotation MUST use keys ∉
`{version, pin, image}` and MUST NOT carry a direct scalar matching `^\d+\.\d+`.

##### FR-B8O-011 — `temporal-intent → dbos-embedded` migration_delta cancelled
The `temporal-intent → dbos-embedded` migration_delta MUST be **cancelled** (the
swap is not happening), NOT left as "deferred/pending". The mechanism (delete the
delta vs reclassify in place with a `cancelled:`/`note:` marker) is ADR-B8O-003 /
Q-003 and MUST be chosen by reading `b8-3.test.sh` source first.

##### FR-B8O-012 — b8-3 stays 17/17 GREEN
After the 2.0.0.yaml edit, `b8-3.test.sh --level 1` MUST stay 17/17: T-010
(`name` present), T-011 (`standard:` refs resolve — `orchestration.yaml` still
exists), T-012 (no `{version,pin,image}` keys), T-015 (no `^\d+\.\d+` component
scalar), T-016 (postgres `migration_note` + postgres-16 delta intact — untouched).

##### FR-B8O-013 — b8-3b stays 12/12 GREEN
`b8-3b.test.sh --level 1` MUST stay 12/12 (versioned-schema discovery unaffected).

##### FR-B8O-014 — exit-code coupling guard
The change's own harness MUST re-run b8-3 + b8-3b (exit-code-only coupling guard,
b8-5 T-009 precedent) and assert both exit 0 after the candidate edit.

##### FR-B8O-015 — 2.0.0.yaml header VIII.2 note preserved/strengthened
The 2.0.0.yaml header (line 19) note that VIII.2 mandates Temporal MUST be
preserved and MAY be strengthened to record that `dbos-embedded` is a
future-option, not a pending replacement.

##### FR-B8O-016 — frozen 1.0.0 `schema.yaml` untouched
The frozen 1.0.0 `schema.yaml` and the flat 1.0.0 template tree MUST NOT be edited
(Article IV; candidate-only edits).

### Cluster 3 — `temporal.md` API realign, verify-then-pin (FR-B8O-020 → 026)

##### FR-B8O-020 — realign to the real Temporal Rust API (LIVE-corrected, evidence.md §2)
`temporal.md` code samples MUST be realigned to the **real published
`temporalio-sdk` 0.4.0 API** (docs.rs, evidence.md §2): crate `temporalio_sdk`
(NOT `temporal_sdk`), `temporalio_sdk::workflows` + attribute macro
`temporalio_macros::workflow` + **`WorkflowContext`** + `WorkflowResult`;
`temporalio_sdk::activities` + `temporalio_macros::activities` + **`ActivityContext`**
+ `ActExitValue`; `Worker` / `WorkerOptionsBuilder` (`.register_activities()` /
`.build()` / `.run()`). It MUST remove the OLD fabricated symbols
`temporal_sdk::` / `temporal_client` / `WfContext` / `ActContext` / `#[activity]`
(singular). **NOTE:** attribute macros (`#[workflow]`) are CORRECT for this crate —
the fabrication was the wrong crate/context names, NOT the use of macros. The API
MUST be sourced from docs.rs at implement, NOT fabricated (Article III.4).

##### FR-B8O-021 — Public-Preview stability caveat recorded (authoritative wording)
`temporal.md` MUST record the native Rust SDK stability caveat from the
**authoritative repo** (`github.com/temporalio/sdk-rust`, evidence.md §2b),
verbatim-faithful: the `temporalio-sdk` crate is in **Public Preview, under active
development — "the API can and will continue to evolve"**; treat it as unstable
across versions, pin exactly, re-verify on bump. The SDK is built on the production
**Temporal Core** (`temporalio-sdk-core`). (The harsher "pre-alpha / no
productionization" wording belongs to the separate `sdk-core` prototype, NOT the
published crate — do not conflate the two repos.)

##### FR-B8O-022 — Rust integration path is an explicit decision
`temporal.md` (and ADR-B8O-004 / Q-006) MUST state which Rust integration path the
flagship uses: (a) prototype `temporalio-sdk`, (b) production
`temporalio-sdk-core` + `temporalio-client` with hand-rolled worker, or (c) a
Go-SDK sidecar worker (the B.6.2 FFI/REST idea). MUST NOT silently assume.

##### FR-B8O-023 — crate version NOT pinned in propose/specify/design
No `temporalio-*` crate version may be written as a concrete pin before
`/forge:implement`. Design records the crate FAMILY + API shape + the verify
procedure; implement performs the live crates.io/docs.rs check, records the
digest/version in `evidence.md`, then pins.

##### FR-B8O-024 — version-pin home decided
Whether the crate version pin lives in `orchestration.yaml` (the YAML pin home),
a new `versions:` block, or template `Cargo.toml` only MUST be an ADR decision
(ADR-B8O-004). Markdown standards historically carry no `versions:` map.

##### FR-B8O-025 — `temporal.md` rules stay coherent
The standard's existing "Rules" section (determinism, retry policies, idempotent
activities, business-key workflow IDs, signals, heartbeats, execution timeouts,
queries, per-concern task queues) MUST be preserved where still API-accurate, and
corrected where the realigned API changes the call shape.

##### FR-B8O-026 — `index.yml infra/temporal` entry remains valid
The `infra/temporal` index entry MUST stay reachable; triggers unchanged.

### Cluster 4 — ADR-002 reconciliation, NO Constitution amendment (FR-B8O-030 → 033)

##### FR-B8O-030 — ADR-B8O-001 reconciles default with VIII.2
Design MUST author `ADR-B8O-001` recording that the orchestration default is
reconciled with Constitution §VIII.2 (Temporal), that ADR-002's Temporal→DBOS swap
is **CANCELLED for Rust** (DBOS demoted to future-option), and that **no
Constitution amendment is required**.

##### FR-B8O-031 — ADR-002 marked superseded (mechanism = ADR/Q-001)
ADR-002 in `docs/ARCHITECTURE-TARGET.md` MUST be recorded as superseded-by
`ADR-B8O-001`. The mechanism (edit the source doc under
`global/source-document-pinning.md` vs record-only in design.md vs both) is
ADR-B8O-001 / Q-001.

##### FR-B8O-032 — INDEPENDENT reviewer for the constitutional citation
Because this change cites the Constitution (VIII.2) and supersedes a ratified ADR,
an INDEPENDENT reviewer (NOT the author, NOT this session's transcript) MUST
ratify design before `/forge:plan` (lesson `t5_2_self_validation_lesson`).

##### FR-B8O-033 — NO Constitution edit
`.forge/constitution.md` MUST NOT be edited (VIII.2 already mandates Temporal;
alignment, not amendment). Article XII governance amendment process is NOT invoked.

### Cluster 5 — roadmap doc deltas (FR-B8O-040 → 043)

##### FR-B8O-040 — B.8.5 DBOS-templates premise struck
`docs/new-archetypes-plan.md` §4.2 B.8.5 ("Templates DBOS embedded — Cargo.toml
`dbos = 0.x`…") MUST be recorded as struck/obsolete (already re-scoped by the
archived b8-5).

##### FR-B8O-041 — B.8.10 Phase-2 DBOS leg dropped
The B.8.10 migration-script Phase-2 "bascule Envoy/**DBOS**/Bloc" MUST drop the
DBOS leg (Temporal stays; nothing to bascule).

##### FR-B8O-042 — B.8.13 DBOS-saturation rollback dropped
The B.8.13 rollback criterion "DBOS Postgres saturé > 70 % CPU → fallback
Temporal" MUST be removed (moot — Temporal is the engine).

##### FR-B8O-043 — B.6.2 FFI→native note added
A note MUST be added at §6.1 B.6.2 that the native Temporal Rust SDK supersedes
the planned "Temporal Go SDK via FFI ou client REST" (subject to the Q-006 path
decision + the pre-alpha caveat).

> Scope: whether FR-B8O-040..043 land in THIS change or a sibling doc-only change
> is Q-005 (resolved at design).

### Cluster 6 — gates & harness (FR-B8O-050 → 053)

##### FR-B8O-050 — change harness `b8o.test.sh`
A new `.forge/scripts/tests/b8o.test.sh` MUST assert: orchestration.yaml at 1.2.0
with `default_by_language.rust == temporal` + a `dbos.status == future-option`
block; the REVIEW.md row present; 2.0.0.yaml `dbos-embedded` future-option +
migration_delta `cancelled: true`; `temporal.md` free of the OLD fabricated
symbols (`temporal_sdk::` / `temporal_client` / `WfContext` / `ActContext`) AND
referencing `temporalio` + `WorkflowContext`/`ActivityContext` + the alpha
"workflow API unstable" caveat (evidence.md §2 — do NOT ban `#[workflow]`, the
real API uses it); NO concrete `temporalio-*` version pinned outside evidence.

##### FR-B8O-051 — registered in CI matrix
`b8o.test.sh` MUST be registered in `.github/workflows/forge-ci.yml`.

##### FR-B8O-052 — full harness suite before push
The FULL harness suite (mirror forge-ci loop, ~42 harnesses) MUST run GREEN before
any push (lesson `full_harness_suite_before_push`); partial gate-sweep = false
green. `validate-standards-yaml.sh` + `verify.sh` + `constitution-linter.sh` MUST
be GREEN.

##### FR-B8O-053 — gates re-run POST status-flip
Gates MUST be re-run AFTER the `planned → implemented` flip, not only before
(lesson `b8_coroot_inversion_lessons`).

---

## MODIFIED Requirements

### ADR-002 "DBOS default" ratification — SUPERSEDED for Rust
- **Previously** (`.forge/specs/adr-ratification.md:47`, ADR-002): DBOS is the
  default orchestrator for `full-stack-monorepo` and `ai-native-rag`; Temporal
  reserved for `event-driven-eu`.
- **Now**: For Rust archetypes the default orchestrator is **Temporal** (aligned
  with Constitution §VIII.2). DBOS is a **watch-list future-option** pending a
  production-grade Rust DBOS SDK. `event-driven-eu` is unchanged (already
  Temporal). Recorded via `ADR-B8O-001` (supersession mechanism = Q-001).

---

## Non-Functional Requirements

##### NFR-B8O-001 — additive-only, zero impact on 1.0.0 adopters
All edits are additive (standard bump) or candidate-only (2.0.0.yaml).
`orchestration.yaml` stays `ci_blocking: false`; the 2.0.0 candidate stays
`scaffoldable: false`; no worker is deployed. Current 1.0.0 adopters see no
behavior change.

##### NFR-B8O-002 — no fabricated versions/APIs (Article III.4)
No `temporalio-*` or `dbos` version is written before live verification. The
realigned `temporal.md` API is sourced from Context7/docs.rs, with `[NEEDS
CLARIFICATION]` surfaced at implement if the live registry contradicts the design
shape (b8-5 Q-004 precedent).

##### NFR-B8O-003 — harness budget
`b8o.test.sh --level 1` SHOULD complete ≤ 5 s wall-clock without toolchains
(NFR-J7-001 / NFR-K3-DEM-005 precedent); zero new external dependency.

##### NFR-B8O-004 — back-compat of standard consumers
Any consumer reading `orchestration.yaml` `default:`/`fallback:` keys MUST be
enumerated before those keys are dropped (FR-B8O-008); if any hard-reads them, the
keys are retained or the consumer updated in the same change (no silent break).

##### NFR-B8O-005 — independent review + full-suite ordering
Design ratified by an INDEPENDENT reviewer (FR-B8O-032); full harness suite + J.7
+ verify + linter GREEN both pre- and post-status-flip (FR-B8O-052/053).

---

## BDD Acceptance Criteria

### Standard reader resolves the Rust orchestrator (FR-B8O-001/002)
```gherkin
Given orchestration.yaml at v1.2.0
When a developer (or Janus) resolves the workflow orchestrator for a Rust archetype
Then the resolved default is "temporal"
And DBOS is presented as a "future-option" gated on a production-grade Rust DBOS SDK
And no reading of the file yields "dbos" as the active Rust default
```

### J.7 validator stays green after the bump (FR-B8O-004/005)
```gherkin
Given orchestration.yaml bumped 1.1.0 -> 1.2.0 with the default_by_language map and the dbos future-option block
And a "| orchestration.yaml | 1.2.0 |" KEEP-WITH-CHANGES row appended to REVIEW.md
When bin/validate-standards-yaml.sh runs in dir-mode and file-mode
Then it exits 0 (frontmatter contract + REVIEW.md row + expires_at > last_reviewed satisfied)
```

### Candidate schema edit keeps b8-3/b8-3b green (FR-B8O-012/013/014)
```gherkin
Given 2.0.0.yaml with dbos-embedded reclassified to future-option and the temporal-intent->dbos-embedded delta cancelled
When b8-3.test.sh --level 1 and b8-3b.test.sh --level 1 run
Then b8-3 is 17/17 and b8-3b is 12/12
And the b8o.test.sh exit-code coupling guard asserts both exit 0
```

### temporal.md carries the real API + the pre-alpha caveat (FR-B8O-020/021)
```gherkin
Given temporal.md realigned to the real published temporalio-sdk 0.4.0 API (evidence.md §2)
When the standard is read
Then no OLD fabricated symbol remains (temporal_sdk::, temporal_client, WfContext, ActContext)
And the samples use temporalio_sdk + WorkflowContext/ActivityContext (attribute macros are correct here)
And the alpha caveat is stated verbatim-faithful ("activity-only worker most stable; workflow worker API still very unstable"; no support guarantees)
And no concrete temporalio-* version is pinned outside evidence.md
```

---

## Anti-Hallucination Pass

- **DBOS-no-Rust-SDK**: verified (crates.io 404; DBOS docs list Python/TS/Go/Java/
  Kotlin only). Recorded, not assumed.
- **Temporal native Rust SDK = pre-alpha prototype**: verified verbatim from the
  `temporalio/sdk-core` README (Context7). The decision is NOT weakened — pre-alpha
  > nonexistent, Core is production, VIII.2 mandates Temporal — but the caveat +
  the integration-path question (Q-006) are recorded honestly, NOT glossed.
- **temporal.md API drift**: the live standard uses `#[workflow]`/`#[activity]`
  macros that do NOT exist in the real closure-registration API — recorded as a
  fabricated-API finding to correct, not propagated.
- **No version pins**: every `temporalio-*` crate version is verify-then-pin at
  implement; design records shape + procedure only.
- **b8-3/b8-3b coupling**: the forbidden-key/scalar constraints are quoted from the
  b8-5 record + to be re-confirmed against `b8-3.test.sh` source at design before
  the delta-cancellation mechanism is chosen (Q-003).
- **No Constitution edit**: VIII.2 already mandates Temporal; this is alignment.

---

## Open Questions

See `open-questions.md` — Q-001 (ADR-002 annotation mechanism), Q-002
(orchestration.yaml shape + legacy keys), Q-003 (2.0.0.yaml reclassify + delta
cancellation, b8-3-safe), Q-004 (temporal.md realign scope + pin home), Q-005
(roadmap deltas this-change-vs-sibling), **Q-006 (NEW — Rust integration path:
prototype `temporalio-sdk` vs production Core crates vs Go-SDK sidecar, raised by
the pre-alpha Context7 finding)**. All `open`; resolved at `/forge:design` by an
INDEPENDENT reviewer + maintainer.
