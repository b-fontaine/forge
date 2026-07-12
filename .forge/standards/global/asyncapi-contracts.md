# Standard — AsyncAPI contracts

<!-- Audit: B.6.3 (b6-3-standards) — event-driven-eu archetype. -->
<!-- Schema mapping: documents the `asyncapi` component of -->
<!-- `.forge/schemas/event-driven-eu/1.0.0.yaml` (delivered_by: B.6.3). -->
<!-- Tooling verified LIVE on npm 2026-07-10: @asyncapi/cli 6.0.2, -->
<!-- @asyncapi/diff 0.5.0, @asyncapi/parser 3.6.0. NO tool version pinned inline. -->

> **Status**: pattern guidance for the `event-driven-eu` archetype (T7).
> **Schema component mapping**: `asyncapi` (role `event-contracts`, in
> `event-driven-eu/1.0.0.yaml`) ↔ this standard (1:1). The schema references it as
> `delivered_by: B.6.3`; the `event-design` phase (AsyncAPI contracts specified
> before design) is governed here.

## Schema mapping & scope

The archetype ships `shared/asyncapi/asyncapi.yaml` as the **event single source of
truth** and wires `task asyncapi:validate`. This standard governs the AsyncAPI 3.1
versioning discipline and the contract-validation / breaking-change gates. It pins
NO tool version (npx-resolved); the crate pins for the Rust side live in B.6.2's
`Cargo.toml.tmpl`.

Sibling standards: `global/event-driven.md` (the envelope/versioning this contract
mirrors) and `infra/nats-jetstream.md` (the broker the channels ride).

## AsyncAPI 3.1 as the event single source of truth

`shared/asyncapi/asyncapi.yaml` declares `asyncapi: 3.1.0` (the latest released 3.x
spec, verified LIVE 2026-07-10). Its shape:

- **`info.version`** — the semver of the contract document as a whole.
- **`channels`** — one per event subject; the scaffolder seeds `orderPlaced` at
  address `events.v1.OrderPlaced` (matching `EventEnvelope::subject()`).
- **`operations`** — `send` / `receive` actions referencing a channel (AsyncAPI 3.x
  moved operations to the top level and made them reference channels).
- **`components.messages` / `components.schemas`** — the message payloads + the
  shared `EventHeaders` (with the required `Nats-Msg-Id` idempotency header).

The contract mirrors the Rust envelope (`backend/events/src/envelope.rs`): subjects
are `events.v<version>.<EventType>`, and `Nats-Msg-Id` is the idempotency key. The
two are a matched pair — a change on one side is a change on the other.

## Versioning discipline

Three distinct version axes, do not conflate them:

1. **Document `info.version`** (semver) — bump on every published change to the
   contract. MINOR for additive/back-compatible changes, MAJOR when the document
   contains a breaking message change (see below).
2. **Per-event `event_version`** — carried in the envelope and the subject
   (`events.v<n>.<Type>`). This is the wire-compat axis (see `global/event-driven.md`).
3. **Message schema evolution** — additive OPTIONAL fields are back-compatible and
   keep the event on its current subject/`event_version`; a **breaking** payload
   change (remove/rename a field, change a type, tighten a constraint, add a required
   field) MUST introduce a new message on a new `events.v<n+1>....` channel rather
   than mutating the shape a consumer already depends on. Old and new channels
   coexist until consumers migrate.

Rule of thumb: **never edit a published message shape in place** if the edit is
breaking — add a new versioned channel. The `asyncapi diff` gate below is what
catches an accidental in-place breaking edit.

## Contract validation

Structural + semantic validation of the document:

```bash
task asyncapi:validate
# → npx -y @asyncapi/cli validate asyncapi.yaml   (run in shared/asyncapi/)
```

`asyncapi validate [SPEC]` (from `@asyncapi/cli`, verified LIVE 6.0.2 on npm
2026-07-10) parses and validates the document (via `@asyncapi/parser` 3.6.0). For CI,
gate on severity:

```bash
npx -y @asyncapi/cli validate asyncapi.yaml --fail-severity error
```

`--fail-severity error|warn|info|hint` sets the threshold at which the command exits
non-zero. This is the always-on gate (the scaffolder's `Taskfile` wires exactly this
`validate` step).

## Breaking-change detection

The AsyncAPI analogue of `buf breaking` is **`asyncapi diff`** (from the same
`@asyncapi/cli`, backed by the `@asyncapi/diff` library — verified LIVE 0.5.0 on npm
2026-07-10: "compares two AsyncAPI Documents … pointing out … breaking changes").
Compare the proposed contract against the merged baseline:

```bash
# Fail CI when the change introduces a breaking change vs the baseline:
npx -y @asyncapi/cli diff baseline/asyncapi.yaml asyncapi.yaml --type breaking
```

Key flags (LIVE-verified):

- `-t, --type breaking|non-breaking|unclassified|all` — which change classes to
  report.
- `--no-error` — do NOT exit non-zero on breaking changes (report-only mode); omit it
  in CI so a breaking change fails the build.
- `-o, --overrides <file>` — a JSON file that re-classifies specific changes (the
  escape hatch for an intentional, coordinated breaking change).
- `-f, --format json|yaml|yml|md` — output format for the report.

Semantics: without `--no-error`, `asyncapi diff` exits non-zero when it finds a
breaking change — the enforcement primitive. A genuinely breaking event change is
only allowed via the versioning discipline above (new `events.v<n+1>` channel), so a
`diff --type breaking` hit means "you mutated a published shape — add a new version
instead", exactly like `buf breaking`.

> **First-cut gap (Article III.4):** the B.6.2 `Taskfile` wires `asyncapi:validate`
> only — it does NOT yet wire `asyncapi diff` against a stored baseline. Wiring the
> diff gate into the Taskfile + the per-layer CI workflow is a follow-up owned by
> Hermes-Async (B.6.4) / the CI templates (B.6.5). This section is the ratified
> pattern that follow-up implements; it is not claimed to be wired today.

## Constitutional Compliance

- **III.1 / event-design phase** — AsyncAPI contracts are specified before design
  (schema `event-design` phase); the contract is the source of truth, code follows.
- **III.4** — the AsyncAPI CLI + diff tooling is verified LIVE (npm 2026-07-10), not
  assumed; the un-wired `asyncapi diff` gate is recorded as a follow-up, not claimed;
  no tool version is pinned inline.
- **IV** — breaking event changes are additive (a new versioned channel), never an
  in-place rewrite of a published message — mirrors the delta-based change rule.
- **IX** — channel/message names align with the traced subjects
  (`events.v<n>.<Type>`) so telemetry and contract share one vocabulary.

## Out-of-scope

- **Tool version pins** (`@asyncapi/cli`, `@asyncapi/diff`, `@asyncapi/parser`) — the
  versions above are LIVE-verified facts, not pins; a concrete npx/CI pin, if wanted,
  is Taskfile/CI territory (B.6.5).
- **Rust crate pins** (`async-nats`, `sqlx`, `temporalio-sdk`) — B.6.2 `Cargo.toml.tmpl`.
- **Bindings + code generation from the contract** — Hermes-Async (B.6.4).
- **Wiring `asyncapi diff` into the Taskfile/CI** — B.6.4 / B.6.5 (follow-up).
- **The envelope/versioning semantics the contract mirrors** — `global/event-driven.md`.
- **Broker topology** — `infra/nats-jetstream.md`.
