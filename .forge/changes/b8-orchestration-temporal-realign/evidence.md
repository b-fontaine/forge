# Evidence — b8-orchestration-temporal-realign

Verify-then-pin LIVE record (Article III.4; lessons `t5_2`, `t5-otel-dartastic-realign`,
`b8-coroot`). Concrete pins/APIs here are from LIVE registry/docs, not fabricated.

## §1 — Temporal Rust crate names + versions (crates.io, accessed 2026-06-01)

| Crate | Exists? | max_version | Description | Verdict |
|-------|---------|-------------|-------------|---------|
| `temporalio-sdk` | YES | **0.4.0** (updated 2026-04-29) | "Temporal Rust SDK" | ✅ the published native SDK (imports `temporalio_sdk`) |
| `temporalio-client` | YES | **0.4.0** | "Clients for interacting with Temporal" | ✅ client crate |
| `temporal-sdk-core` | YES | 0.1.0-alpha.1 (2021-04-22) | "Library for building new Temporal SDKs" | ✖ stale/abandoned naming — NOT used |
| `temporal-client` | NO (404) | — | — | ✖ does not exist (real = `temporalio-client`) |

**Pin (for the future Temporal-worker-template brick; NOT created in this change):**
`temporalio-sdk = "0.4.0"`, `temporalio-client = "0.4.0"`. This change records the
crate FAMILY (`temporalio-sdk`) in `orchestration.yaml`; no `Cargo.toml` is created
here (worker template is downstream — see proposal Scope Out).

## §2 — Published `temporalio-sdk` 0.4.0 API (docs.rs, accessed 2026-06-01)

**CORRECTION to the design's API-shape assumption (ADR-B8O-004).** Design ADR-B8O-004
described a *closure-registration* API (`worker.register_wf(name, |ctx: WfContext|…)`)
sourced from the GitHub `sdk-core` **master/prototype** snippet (Context7). The
**published `temporalio-sdk` 0.4.0** crate API is **attribute-macro based** and uses
different context type names. This is a verify-then-pin correction within ADR-B8O-004's
explicit mandate ("realigned API MUST be sourced … at implement, NOT fabricated"); the
DECISION (Q-006 path a: prototype crate, pinned, caveat) is unchanged.

Real 0.4.0 surface (docs.rs `temporalio_sdk`):
- **Workflow:** module `temporalio_sdk::workflows`; attribute macro `temporalio_macros::workflow`;
  context **`WorkflowContext`**; result alias `WorkflowResult`.
- **Activity:** module `temporalio_sdk::activities`; attribute macro `temporalio_macros::activities`;
  context **`ActivityContext`**; `ActivityError`; `ActExitValue`.
- **Worker:** `Worker`, `WorkerOptions`, `WorkerOptionsBuilder` (`.register_activities()`,
  `.build()`, `.run()`).
- Errors: `ActivityExecutionError`, `ChildWorkflowExecutionError`, `OutgoingError`.

**Stability (verbatim, docs.rs 0.4.0):** *"alpha-stage … Currently defining activities and
running an activity-only worker is the most stable code. Workflow definitions exist and
running a workflow worker works, but the API is still very unstable."* Plus
`github.com/temporalio/sdk-core` README: native Rust SDK is *"pre-alpha … API may change at
any time without warning … no support guarantees … no firm plans to productionize."*

**Drift in the OLD `temporal.md` to FIX:** uses `temporal_sdk::{WfContext, workflow}` /
`temporal_client` + `#[workflow]`/`#[activity]` (singular). Wrong: crate `temporal_sdk`
(→ `temporalio_sdk`), `WfContext`/`ActContext` (→ `WorkflowContext`/`ActivityContext`),
`#[activity]` singular (→ `temporalio_macros::activities`). The realign target is the §2
published API above.

**b8o assertion correction:** do NOT assert "temporal.md free of `#[workflow]`" (the real
API USES attribute macros). Assert instead: temporal.md contains NO `temporal_sdk::` /
`temporal_client` / `WfContext` / `ActContext` (the OLD fabricated symbols), DOES reference
`temporalio` + `WorkflowContext`/`ActivityContext`, and carries the alpha/"workflow API
unstable" caveat. (Amends FR-B8O-020/050 + T002/T011/T015.)

**Verified worker/activity API (docs.rs `temporalio-sdk` 0.4.0, accessed 2026-06-01):**
activities via `#[activities]` on an impl block + `#[activity]` methods
(`ActivityContext`, `Result<T, ActivityError>`); worker via
`WorkerOptions::new("queue").task_types(WorkerTaskTypes::activity_only())
.register_activities(MyActivities).build()` + `Worker::new(&runtime, client, opts)?` +
`worker.run().await?`. **Workflow example: NONE shown upstream + "API still very
unstable"** → temporal.md does NOT fabricate a workflow code sample (Article III.4);
it documents the stable activity-only path + flags the workflow API as churning.

## §2b — AUTHORITATIVE API resolution (reproducible; resolves round-1 review CRITICAL-1)

The published crate `temporalio-sdk` ships from **`github.com/temporalio/sdk-rust`**
(crates.io `repository` field), a SEPARATE repo from `temporalio/sdk-core` (the Core
engine + an older closure-API prototype in `sdk/`). The independent reviewer's
Context7 source indexed `sdk-core` (closure API) — NOT the published crate. The
authoritative, reproducible source for the published crate's API is:

**`https://raw.githubusercontent.com/temporalio/sdk-rust/main/crates/sdk/README.md`**
(accessed 2026-06-01). Verbatim API (quoted):

```rust
// Activity
#[activities]
impl MyActivities {
    #[activity]
    pub async fn greet(_ctx: ActivityContext, name: String) -> Result<String, ActivityError> { Ok(format!("Hello, {}!", name)) }
}
// Workflow
#[workflow]
pub struct GreetingWorkflow { name: String }
#[workflow_methods]
impl GreetingWorkflow {
    #[run]
    async fn run(ctx: &mut WorkflowContext<Self>) -> WorkflowResult<String> { /* ... */ }
}
// Worker
let worker_options = WorkerOptions::new("my-task-queue")
    .register_activities(MyActivities { /* ... */ })
    .register_workflow::<GreetingWorkflow>()?
    .build();
Worker::new(&runtime, client, worker_options)?.run().await?;
```

**Stability (verbatim, authoritative):** "⚠️ The SDK is in **Public Preview** and
under active development. The API can and will continue to evolve."

**CORRECTIONS to §2 (which used the less-reliable docs.rs summary):**
- Macro API CONFIRMED (resolves CRITICAL-1): `#[activities]`/`#[activity]`,
  `#[workflow]`/`#[workflow_methods]`/`#[run]`, `WorkflowContext<Self>` /
  `ActivityContext`, `WorkflowResult`, `ActivityError`.
- Worker API: `WorkerOptions::new(q).register_activities(..).register_workflow::<T>()?.build()`
  + `Worker::new(&runtime, client, opts)?.run().await?`. **`WorkerTaskTypes::activity_only()`
  is NOT in the authoritative README — REMOVED from temporal.md** (it was a docs.rs-summary
  artifact, unverified).
- Stability wording corrected from "pre-alpha / activity-only most stable / workflow API
  very unstable" (that was the `sdk-core` prototype's wording) to the authoritative
  **"Public Preview … API can and will continue to evolve."**
- **CRITICAL-2 fix:** temporal.md carries NO concrete `temporalio-* = "x.y.z"` pin
  (family-only + verify-then-pin pointer). `b8o.test.sh` T-009 extended to scan
  `temporal.md` too (was orchestration.yaml-only → false-green). Concrete versions
  (crates.io 2026-06-01: `temporalio-sdk 0.4.0`, `temporalio-client 0.4.0`) live ONLY
  here in evidence + the downstream worker-template `Cargo.toml`, never in the standard.

## §3 — Sibling-harness coupling: `forbidden-components-rules.md` version pin (T013)

`i3.test.sh:169` **hard-asserts** `grep -Fq "version: 1.0.0"` on
`.forge/standards/global/forbidden-components-rules.md` (FR-I3-T3F-040). Therefore
bumping that file's version (the design's FR-B8O-018 "bump + REVIEW row if versioned"
contingency) would turn **i3 RED**. The file is also OUT of J.7 scope
(`validate-standards-yaml.sh` processes `*.yaml`, not `global/*.md` — verified: 0
hits). i3 asserts only the T3-RULE-NNN anchors + frontmatter (`version: 1.0.0`,
`linter_rule`, `enforcement`) + index entry — NOT the remediation cell text.
**Decision:** T013 edits the T3-RULE-003 remediation cell text ONLY, **no version
bump** (keeps i3:169 GREEN). The cross-link stays `ADR-002` (the rule's true
provenance; `inngest` remains forbidden — only the remediation *guidance* changed).
This OVERRIDES the design's bump-if-versioned note — a verify-then-edit correction.
