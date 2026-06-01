# Open Questions — b8-orchestration-temporal-realign

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
AUTHOR phase (propose/specify): leanings recorded only. Resolutions are made at
/forge:design by an INDEPENDENT reviewer + the maintainer, NOT self-approved here
(constitutional citation — VIII.2 + ADR-002 cancellation — makes independent
review non-negotiable; lesson t5_2_self_validation_lesson). The concrete
`temporalio-sdk` crate version is verify-then-pin at /forge:implement.
-->

## Resolution Log (/forge:design, 2026-06-01)

All six questions resolved at `/forge:design` (maintainer decisions + design-time
live-source re-read, encoded in `design.md` ADR-B8O-001..005). The author flips
them to answered here; an **INDEPENDENT reviewer ratifies before `/forge:plan`**
(NOT self-approved — constitutional citation). The `temporalio-*` crate version
stays verify-then-pin at `/forge:implement`.

| Q | Decision | ADR |
|---|----------|-----|
| Q-001 | **record-only** supersession of ADR-002 in design.md + specs MODIFIED entry; NO edit to sha256-pinned `ARCHITECTURE-TARGET.md` (would cascade `t4.test.sh` hash re-pin) | ADR-B8O-001 |
| Q-002 | `default_by_language: { rust: temporal }` + `dbos:` future-option block; flat `default:`/`fallback:`/`fallback_trigger:` **dropped**; consumers updated in-change: `b8-5.test.sh` **T-006 + T-010**, `constitution-linter.sh:802`, **`forbidden-components-rules.md:62`**, `2.0.0.yaml:76` comment (consumer set completed by independent review) | ADR-B8O-002 |
| Q-003 | `dbos-embedded` → `status: future-option`; `temporal-intent → dbos-embedded` delta **reclassified in place** `cancelled: true` (not deleted — keeps T-013 count, auditable); b8-3 17/17 + b8-3b 12/12 + **b8-5 T-006/T-010 repurposed** re-run | ADR-B8O-003 |
| Q-004 | `temporal.md` full code-sample rewrite to real closure API; pin home = template `Cargo.toml` (verify-then-pin at implement); orchestration.yaml records crate FAMILY only | ADR-B8O-004 |
| Q-005 | roadmap deltas land in **THIS** change | ADR-B8O-005 |
| Q-006 | **(a)** prototype `temporalio-sdk` (maintainer 2026-06-01) — closure API, pinned + pre-alpha caveat, Rust-only | ADR-B8O-004 |

## Q-001: ADR-002 annotation mechanism (edit source doc vs record-only)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B8O-001 seed)
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-orchestration-temporal-realign propose pass)

### Question

ADR-002 (*"Temporal → DBOS par défaut"*) lives in the planning document
`docs/ARCHITECTURE-TARGET.md:328` (which "ratifies 10 ADRs"). This change cancels
ADR-002's Temporal→DBOS swap for Rust and reconciles the standard with
Constitution §VIII.2 (Temporal). `global/source-document-pinning.md` governs how
source documents are treated.

`[NEEDS CLARIFICATION: How is ADR-002 recorded as not-proceeding — (a) edit
docs/ARCHITECTURE-TARGET.md to annotate ADR-002 as SUPERSEDED by ADR-B8O-001
(under source-document-pinning.md rules); (b) record-only in this change's
design.md ADR-B8O-001, leaving ARCHITECTURE-TARGET.md as a historical artifact;
or (c) both — a one-line superseded-by pointer in the source doc + the full
rationale in design.md?]`

- (a) **Edit the source doc** — single source of truth, but mutates a ratified
  architecture document (source-document-pinning.md constraints apply).
- (b) **Record-only in design.md** — keeps the source doc immutable as a
  point-in-time artifact; the supersession lives in the change trail.
- (c) **Both (pointer + full rationale)** — source doc gets a minimal
  `superseded by ADR-B8O-001 (b8-orchestration-temporal-realign)` pointer, the
  reasoning lives in design.md. **Lean here** (discoverable + immutable-friendly),
  pending source-document-pinning.md review.

### Resolution

- **Resolved 2026-06-01** (/forge:design — author; INDEPENDENT reviewer ratifies before /forge:plan). See Resolution Log + `design.md` ADRs.

---

## Q-002: orchestration.yaml shape — default_by_language map + legacy keys

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B8O-002 seed)
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-orchestration-temporal-realign propose pass)

### Question

`orchestration.yaml` v1.1.0 has flat `default: dbos` / `fallback: temporal` /
`fallback_trigger:` + the B.8.5 `rust_sdk_status.dbos` body block. C-map promotes
`rust_flagship_orchestrator: temporal` into the real default semantics. The bump
must keep `bin/validate-standards-yaml.sh` (J.7) GREEN (frontmatter contract,
mandatory REVIEW.md row, `expires_at > last_reviewed`).

`[NEEDS CLARIFICATION: What is the v1.2.0 shape — (a) add default_by_language: {
rust: temporal } + a dbos: { status: future-option, requires, revisit } block,
and KEEP the legacy default:/fallback:/fallback_trigger: keys for reader
back-compat; (b) same but REPLACE default: with default_by_language: (drop the
flat key); or (c) something else? Which keys does validate-standards-yaml.sh /
any consumer hard-read, so dropping them is safe?]`

- (a) **Add map + dbos block, keep legacy keys** — most back-compat, but two
  sources of "default" truth coexist (smell).
- (b) **Add map + dbos block, replace flat `default:`** — single source of
  truth, honest; requires confirming no consumer hard-reads `default:`. **Lean
  here**, pending a grep of consumers (`index.yml`, linter, schema `standard:`
  resolvers, validate-standards-yaml.sh).
- (c) other.

> NOTE: `default_by_language` / `dbos` are body fields under root
> `additionalProperties: true` (gateway.yaml/observability.yaml precedent). The
> 1.1.0 → 1.2.0 bump MUST add a REVIEW.md `| orchestration.yaml | 1.2.0 |`
> KEEP-WITH-CHANGES row (FR-J7-023) and reset `last_reviewed`/`expires_at`
> (FR-J7-021), keeping `exception_constitutional: false` (FR-J7-020).

### Resolution

- **Resolved 2026-06-01** (/forge:design — author; INDEPENDENT reviewer ratifies before /forge:plan). See Resolution Log + `design.md` ADRs.

---

## Q-003: 2.0.0.yaml reclassify + temporal-intent→dbos-embedded delta cancellation (b8-3/b8-3b coupling)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B8O-003 seed)
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-orchestration-temporal-realign propose pass)

### Question

`2.0.0.yaml` `dbos-embedded` is `status: deferred` (B.8.5); C-map reclassifies it
to Temporal-retained / future-option and CANCELS the `temporal-intent →
dbos-embedded` migration_delta. `b8-3.test.sh` (17 L1) + `b8-3b.test.sh` (12 L1)
are tightly coupled: forbidden component keys `{version, pin, image}` (T-012); no
component direct scalar matching `^\d+\.\d+` (T-015); `standard:` refs resolve
(T-011); every component needs `name` (T-010); the postgres component +
`migration_note` + postgres delta intact (T-016).

`[NEEDS CLARIFICATION: (1) What annotation marks dbos-embedded as
future-option-not-deferred — reuse status: future-option + note:, or a different
key — without entering {version,pin,image} or a ^\d+\.\d+ scalar? (2) Can the
temporal-intent → dbos-embedded migration_delta be REMOVED outright, or does
b8-3.test.sh positively assert its existence (forcing a reclassify-in-place
instead of deletion)? Must verify against b8-3.test.sh source, not assume.]`

- **(1) Lean:** `status: future-option` + free-text `note:` on the component
  (keys ∉ {version,pin,image}; prose not starting with `^\d+\.\d+`) — smallest
  additive candidate-shape change, mirrors the b8-5 `status: deferred` precedent.
- **(2)** MUST re-read `b8-3.test.sh` lines that walk `migration_deltas` before
  deciding delete-vs-reclassify; if the delta is asserted, reclassify it in place
  (e.g. `to:` stays but a `cancelled: true` / `note:` records the cancellation)
  rather than removing it. **No assumption** — verify at design.

> NOTE: FR-B8O-* MUST re-run b8-3 (17/17) + b8-3b (12/12) after the edit
> (exit-code coupling guard, b8-5 T-009 precedent). Full harness suite before
> push (shared_standard_sibling_harness_coupling).

### Resolution

- **Resolved 2026-06-01** (ADR-B8O-003): `dbos-embedded` → `status: future-option`; `temporal-intent → dbos-embedded` delta reclassified in place with `cancelled: true` (not deleted). Verified against `b8-3.test.sh` source: T-013 asserts only delta-count non-empty, T-016 only the postgres-16 delta, T-012 forbids `{version,pin,image}` — chosen shape keeps b8-3 17/17 + b8-3b 12/12 GREEN (re-run as exit-code guard). INDEPENDENT reviewer ratifies.

---

## Q-004: temporal.md realign scope + pin policy (community crate → official temporalio-sdk 0.4.0)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B8O-004 seed)
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-orchestration-temporal-realign propose pass)

### Question

`temporal.md` code samples use the community crate API `temporal_sdk::{WfContext,
workflow}` / `temporal_client`. The official SDK is `temporalio-sdk` (0.4.0 line,
**Public Preview**, `github.com/temporalio/sdk-core`). This is the same fabricated/
drifted-API class as `t5-otel-dartastic-realign` and the `t5-connect-codegen`
Rust pivot.

`[NEEDS CLARIFICATION: (a) Full rewrite of temporal.md code samples to the real
temporalio-sdk 0.4.0 API, or (b) targeted import/crate-name realign only? Does a
versions: pin block get added to the markdown standard, or does the temporalio-sdk
pin live in template Cargo.toml only (markdown standards historically carry no
versions: map — orchestration.yaml is the YAML pin home)? Where is the
Public-Preview/pre-GA caveat recorded?]`

- **Lean:** realign the API to the **real** `temporalio-sdk` 0.4.0 surface
  (verified via Context7 / docs.rs at implement, NOT fabricated — Article III.4);
  scope = whatever the live API actually requires (could be full rewrite if the
  community API differs structurally). The **crate version is verify-then-pin at
  `/forge:implement`** (crates.io / docs.rs live check, recorded in
  `evidence.md`); the Public-Preview caveat goes in the standard's "When to Use"
  / a frontmatter-adjacent note. Whether `orchestration.yaml` (the YAML pin home)
  or template `Cargo.toml` carries the version pin is a design call.

> NOTE: if the live registry lacks a usable `temporalio-sdk` release at implement,
> the impl surfaces `[NEEDS CLARIFICATION]` rather than guessing (b8-5 Q-004
> precedent).

### Resolution

- **Resolved 2026-06-01** (ADR-B8O-004): full `temporal.md` code-sample rewrite to the real closure API; crate version pin home = template `Cargo.toml`; `orchestration.yaml` records the crate FAMILY (`temporalio-sdk`) + `stability: pre-alpha` only. Concrete version + exact crate name = verify-then-pin at `/forge:implement` (crates.io/docs.rs live, digest in evidence.md).

---

## Q-005: roadmap doc deltas — this change vs sibling doc-only change

- **Status**: answered
- **Raised in**: `proposal.md` (Solution §6)
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-orchestration-temporal-realign propose pass)

### Question

The decision implies edits to `docs/new-archetypes-plan.md`: strike the dead
B.8.5 "Templates DBOS embedded" premise (already re-scoped); drop the DBOS leg of
B.8.10 Phase-2 (`:2288`); drop the B.8.13 "DBOS Postgres saturé > 70 % → fallback
Temporal" rollback criterion (`:2300`, moot); add a B.6.2 (`:2377`) note that the
native Rust `temporalio-sdk` replaces the planned "Temporal Go SDK via FFI ou
client REST".

`[NEEDS CLARIFICATION: Do these roadmap doc edits land in THIS change's
implementation, or in a separate doc-only sibling change to keep the
standard/schema change surgically scoped?]`

- **Lean:** include them in THIS change (they are the direct documentary
  consequence of the same decision; splitting risks a dangling roadmap that still
  advertises DBOS). Confirm at design.

### Resolution

- **Resolved 2026-06-01** (ADR-B8O-005): roadmap deltas (B.8.5 strike / B.8.10 Phase-2 / B.8.13 rollback / B.6.2 FFI→native note) land in THIS change's implementation.

---

## Q-006: Rust integration path for Temporal (raised by the pre-alpha Context7 finding)

- **Status**: answered
- **Raised in**: `specs.md` Context7 Evidence + FR-B8O-022 / ADR-B8O-004
- **Raised on**: 2026-06-01
- **Raised by**: author (b8-orchestration-temporal-realign specify pass — Context7 `/temporalio/sdk-core`)

### Question

Context7 (`temporalio/sdk-core` README, verbatim) establishes that the high-level
native `temporalio-sdk` crate is a **pre-alpha prototype** — *"API may change at
any time without warning... no support guarantees... no firm plans to
productionize"* — while the **Core** crates (`temporalio-sdk-core`,
`temporalio-client`) are production-grade (they power the TS/Python/.NET/Ruby
SDKs). Constitution §VIII.2 mandates Temporal regardless. The flagship must pick a
Rust integration path.

`[NEEDS CLARIFICATION: Which Rust integration path does the 2.0.0 flagship adopt —
(a) the prototype temporalio-sdk crate (ergonomic closure API, but pre-alpha, may
break without warning); (b) the production temporalio-sdk-core + temporalio-client
crates with a hand-rolled worker (stable Core, more boilerplate); or (c) a Go-SDK
sidecar worker the Rust services call (the original B.6.2 "Temporal Go SDK via FFI
ou client REST" idea — most mature, but +1 process/language)? This drives the
temporal.md realign target (FR-B8O-020) and the B.6.2 note (FR-B8O-043).]`

- (a) **prototype `temporalio-sdk`** — best DX, matches the closure API in
  temporal.md realign; risk = pre-alpha churn. Acceptable for a `scaffoldable:
  false` 2.0.0 candidate / template, with a pinned version + caveat; re-evaluated
  at review cadence.
- (b) **Core crates + hand-rolled worker** — production stability, more
  boilerplate; the template carries the worker scaffolding.
- (c) **Go-SDK sidecar** — most battle-tested, but reintroduces a Go process and
  contradicts the "Rust end-to-end" framing; mirrors B.6.2's original idea.
- **No lean at specify** — this is a genuine architecture decision for design +
  the maintainer; the pre-alpha caveat (FR-B8O-021) is recorded either way, and
  the concrete crate/version is verify-then-pin at implement (couples to Q-004).

### Resolution

- **Resolved 2026-06-01** (ADR-B8O-004, **maintainer decision**): **(a) prototype `temporalio-sdk`** — ergonomic closure API, pinned + pre-alpha caveat in temporal.md, Rust-only backend preserved; re-evaluate at review cadence. Drives the temporal.md realign target (FR-B8O-020) + the B.6.2 note (FR-B8O-043). INDEPENDENT reviewer ratifies before /forge:plan.
