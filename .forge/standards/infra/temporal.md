# Temporal Workflow Standard

<!-- Realigned to the published `temporalio-sdk` API by b8-orchestration-temporal-realign
     (B.8.5 follow-on, 2026-06-01). Prior samples used a fabricated/community crate (wrong
     crate name, wrong context types, singular activity macro). The real crate is
     `temporalio-sdk` (repo github.com/temporalio/sdk-rust). API + stability below are
     quoted from the authoritative, reproducible source
     https://raw.githubusercontent.com/temporalio/sdk-rust/main/crates/sdk/README.md
     (evidence.md §2b), NOT fabricated. Temporal is the Rust default orchestrator per
     Constitution §VIII.2 + orchestration.yaml v1.2.0 `default_by_language.rust`. -->

## Stability — read first (Public Preview)

The official native Rust SDK (`temporalio-sdk`, repo `temporalio/sdk-rust`) is in
**Public Preview**. Verbatim from its README:

> "⚠️ The SDK is in **Public Preview** and under active development. The API can and
> will continue to evolve."

Consequences for Forge:
- Treat the API as **unstable across versions** — pin the crate exactly and re-verify
  on every bump (the API "will continue to evolve"). The SDK is built on top of
  **Temporal Core** (`temporalio-sdk-core`), the production Rust engine that powers
  Temporal's TS/Python/.NET/Ruby SDKs.
- **Crate versions are pinned in the consuming project's `Cargo.toml`** via
  verify-then-pin (LIVE crates.io at scaffold/implement time) — NOT hardcoded in this
  standard. The concrete versions observed 2026-06-01 are recorded in
  `.forge/changes/b8-orchestration-temporal-realign/evidence.md §1`.

## When to Use Temporal

Use Temporal when you need:
- **Multi-step processes** with multiple services or side effects
- **Long-running operations** spanning hours, days, or weeks
- **Human approval flows** (wait for a signal)
- **Complex retry logic** with backoff and failure compensation
- **Exactly-once semantics** for operations that must not be duplicated
- **Audit trail** of every step in a business process

Do NOT use Temporal for: simple request/response API calls, real-time streaming, or
simple queue consumers without orchestration.

Constitution §VIII.2: long-running, multi-step workflows that span microservices SHALL
use Temporal. No ad-hoc saga implementations in application code.

---

## Crates

| Crate | Role |
|-------|------|
| `temporalio-sdk` | high-level native Rust SDK (`temporalio_sdk`) — workflows, activities, worker |
| `temporalio-macros` | the `#[workflow]` / `#[workflow_methods]` / `#[activities]` / `#[activity]` / `#[run]` attribute macros |
| `temporalio-client` | client for starting/signalling workflows (`temporalio_client`) |
| `temporalio-sdk-core` | the production Rust Core engine the SDK is built on |

Add `temporalio-sdk` + `temporalio-client` to the consuming project's `Cargo.toml`.
**Pin the exact versions via verify-then-pin (crates.io) at scaffold time** — this
standard intentionally records no concrete version (the API is Public Preview and
evolving; see Stability + evidence.md §1).

---

## Activities

Activities hold the side effects (DB, HTTP, email). Defined with the `#[activities]`
macro on an `impl` block, `#[activity]` on each method, taking an `ActivityContext` and
returning `Result<T, ActivityError>`.

```rust
use temporalio_sdk::{ActivityContext, ActivityError};
use temporalio_macros::{activities, activity};

pub struct OrderActivities;

#[activities]
impl OrderActivities {
    #[activity]
    pub async fn charge_payment(
        _ctx: ActivityContext,
        input: ChargePaymentInput,
    ) -> Result<PaymentResult, ActivityError> {
        // Idempotency key = order_id ensures retries never double-charge.
        let result = PaymentClient::new()
            .charge(input.order_id.clone(), input.amount_cents)
            .await
            .map_err(|e| ActivityError::from(anyhow::anyhow!("charge failed: {e}")))?;
        Ok(PaymentResult { payment_id: result.id })
    }

    #[activity]
    pub async fn reserve_inventory(
        _ctx: ActivityContext,
        input: ReserveInventoryInput,
    ) -> Result<(), ActivityError> {
        // Idempotent on retry via the unique constraint on order_id.
        sqlx::query("INSERT INTO inventory_reservations (order_id, items) \
                     VALUES ($1, $2) ON CONFLICT (order_id) DO NOTHING")
            .bind(&input.order_id)
            .bind(serde_json::to_value(&input.items)?)
            .execute(&get_db().await)
            .await
            .map_err(|e| ActivityError::from(anyhow::anyhow!("reserve failed: {e}")))?;
        Ok(())
    }
}
```

> NOTE: `ActivityError` conversion is shown illustratively; consult the pinned version's
> docs (crate `temporalio-sdk`) for the exact retryable vs non-retryable constructors.
> Do not invent error variants.

---

## Workflows

A workflow is a `#[workflow]` struct + a `#[workflow_methods]` impl with a `#[run]`
entry method taking `&mut WorkflowContext<Self>` and returning `WorkflowResult<T>`.
Workflows MUST be **deterministic**: no `rand`, no `SystemTime::now()`, no direct I/O —
every side effect goes through an activity.

```rust
use temporalio_sdk::{WorkflowContext, WorkflowResult};
use temporalio_macros::{workflow, workflow_methods, run};

#[workflow]
pub struct OrderWorkflow {
    order_id: String,
}

#[workflow_methods]
impl OrderWorkflow {
    #[run]
    async fn run(ctx: &mut WorkflowContext<Self>) -> WorkflowResult<OrderOutput> {
        // Orchestrate activities deterministically via ctx; compensate on failure.
        // Exact activity-invocation + signal/timer API: see the pinned crate's docs
        // (Public Preview — the API evolves between versions; re-verify on bump).
        todo!("call reserve_inventory, charge_payment, fulfil — with compensation")
    }
}
```

> The exact `WorkflowContext` method surface (activity calls, timers, signals, queries)
> is Public Preview and changes between versions — take it from the pinned crate's docs,
> not from memory. The macro/struct shape above is from the authoritative repo README
> (evidence.md §2b).

---

## Worker setup

A worker registers activities + workflows and polls a task queue.

```rust
use temporalio_sdk::{Worker, WorkerOptions};

pub async fn run_order_worker(
    runtime: &CoreRuntime,
    client: TemporalClient,
) -> Result<(), anyhow::Error> {
    let worker_options = WorkerOptions::new("order-processing")   // task queue
        .register_activities(OrderActivities)
        .register_workflow::<OrderWorkflow>()?
        .build();

    Worker::new(runtime, client, worker_options)?.run().await?;
    Ok(())
}
```

---

## Client (start / signal workflows)

Use `temporalio-client` (`temporalio_client`) to connect and to start workflows with a
**business key** as the workflow ID (e.g. `order-<id>`) for idempotency — never a random
UUID. The connected client is passed to `Worker::new(runtime, client, options)`. Consult
the pinned `temporalio-client` docs for the exact options builder; do not fabricate TLS /
retry field names.

---

## Rules (Temporal semantics — language-agnostic, in force)

- **Workflows must be deterministic**: no I/O, no `rand`, no `SystemTime::now()`, no
  mutable global state. Side effects only via activities.
- **Activities must be idempotent**: retries must be safe; use idempotency keys for
  payments and writes.
- **Retry policy + non-retryable errors** on activities: distinguish retryable from
  terminal failures (`ActivityError`).
- **Workflow ID is the business key**: order ID, request ID — never a random UUID.
- **Compensating activities for rollback**: define a compensation for each reversible
  side effect.
- **Signals for human interaction**: wait on a signal with a timeout; never poll.
- **Heartbeat long-running activities**: activities running > 30s heartbeat periodically.
- **Bounded execution timeout** on every workflow.
- **Separate task queues per concern**: `order-processing`, `onboarding`,
  `notifications` — never one shared queue for everything.
- **Pin the SDK exactly + re-verify on bump** (Public Preview; the API evolves).
