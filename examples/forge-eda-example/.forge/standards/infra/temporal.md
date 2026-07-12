# Temporal Workflow Standard

## When to Use Temporal

Use Temporal when you need:
- **Multi-step processes** with multiple services or side effects
- **Long-running operations** that span hours, days, or weeks
- **Human approval flows** (wait for a signal indefinitely)
- **Complex retry logic** with exponential backoff and failure compensation
- **Exactly-once semantics** for operations that must not be duplicated
- **Audit trail** of every step in a business process

Do NOT use Temporal for:
- Simple request/response API calls
- Real-time data streaming
- Simple queue consumers without complex orchestration

---

## Architecture

```
Client (Starter)
    │ StartWorkflowExecution
    ▼
Temporal Server
    │ Task Queue
    ▼
Worker (hosts Workflow + Activities)
    ├── Workflow (deterministic orchestration)
    └── Activities (side-effects: DB, HTTP, email)
```

```
crate/
├── workflows/
│   ├── mod.rs
│   ├── order_workflow.rs       # deterministic logic only
│   └── onboarding_workflow.rs
├── activities/
│   ├── mod.rs
│   ├── payment_activities.rs   # side effects
│   ├── inventory_activities.rs
│   └── notification_activities.rs
└── worker.rs                   # wires workflows + activities to a task queue
```

---

## Workflow (Deterministic)

Workflows must be **deterministic**: the same inputs always produce the same sequence of activity calls. No random numbers, no system clock calls, no I/O.

```rust
// src/workflows/order_workflow.rs
use temporal_sdk::{WfContext, WfExitValue, workflow};
use std::time::Duration;

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct OrderInput {
    pub order_id: String,
    pub user_id: String,
    pub items: Vec<OrderItem>,
    pub total_cents: i64,
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct OrderOutput {
    pub confirmation_number: String,
}

#[workflow]
pub async fn order_workflow(ctx: WfContext, input: OrderInput) -> Result<OrderOutput, anyhow::Error> {
    // Step 1: Reserve inventory
    ctx.activity(ActivityOptions {
        activity_type: "reserve_inventory".to_string(),
        schedule_to_close_timeout: Some(Duration::from_secs(30)),
        retry_policy: Some(RetryPolicy {
            maximum_attempts: 3,
            initial_interval: Duration::from_secs(1),
            backoff_coefficient: 2.0,
            maximum_interval: Duration::from_secs(10),
            non_retryable_error_types: vec!["InsufficientInventoryError".to_string()],
        }),
        ..Default::default()
    })
    .execute::<(), _>(ReserveInventoryInput {
        order_id: input.order_id.clone(),
        items: input.items.clone(),
    })
    .await
    .map_err(|e| compensate_inventory(&ctx, &input, e))?;

    // Step 2: Charge payment
    let payment_result = ctx.activity(ActivityOptions {
        activity_type: "charge_payment".to_string(),
        schedule_to_close_timeout: Some(Duration::from_secs(60)),
        retry_policy: Some(RetryPolicy {
            maximum_attempts: 5,
            non_retryable_error_types: vec!["CardDeclinedError".to_string()],
            ..Default::default()
        }),
        ..Default::default()
    })
    .execute::<PaymentResult, _>(ChargePaymentInput {
        order_id: input.order_id.clone(),
        amount_cents: input.total_cents,
        user_id: input.user_id.clone(),
    })
    .await;

    let payment = match payment_result {
        Ok(p) => p,
        Err(e) => {
            // Compensate: release inventory
            ctx.activity(simple_activity_options("release_inventory", 30))
                .execute::<(), _>(ReleaseInventoryInput { order_id: input.order_id.clone() })
                .await
                .ok(); // best-effort compensation
            return Err(anyhow::anyhow!("Payment failed: {e}"));
        }
    };

    // Step 3: Fulfill order
    ctx.activity(simple_activity_options("fulfill_order", 300))
        .execute::<(), _>(FulfillOrderInput {
            order_id: input.order_id.clone(),
            payment_id: payment.payment_id,
        })
        .await?;

    // Step 4: Send confirmation (non-blocking — fire and forget)
    ctx.activity(simple_activity_options("send_confirmation_email", 60))
        .execute::<(), _>(SendEmailInput { user_id: input.user_id.clone(), order_id: input.order_id.clone() })
        .await
        .ok(); // email failure should not fail the workflow

    Ok(OrderOutput {
        confirmation_number: format!("ORD-{}", &input.order_id[..8].to_uppercase()),
    })
}
```

---

## Human Approval Flow with Signals

```rust
// src/workflows/approval_workflow.rs
use temporal_sdk::{WfContext, workflow};

#[workflow]
pub async fn approval_workflow(ctx: WfContext, input: ApprovalInput) -> Result<bool, anyhow::Error> {
    // Notify approver
    ctx.activity(simple_activity_options("send_approval_request", 30))
        .execute::<(), _>(SendApprovalInput {
            approver_id: input.approver_id.clone(),
            request_id: input.request_id.clone(),
        })
        .await?;

    // Wait for signal (up to 7 days)
    let decision = ctx.make_signal_channel::<ApprovalDecision>("approval-decision");

    let result = tokio::select! {
        signal = decision.recv() => {
            match signal {
                Some(ApprovalDecision::Approved) => true,
                Some(ApprovalDecision::Rejected) => false,
                None => false,
            }
        }
        _ = ctx.timer(Duration::from_secs(7 * 24 * 3600)) => {
            // Auto-reject after 7 days
            false
        }
    };

    // Notify requester of outcome
    ctx.activity(simple_activity_options("send_approval_outcome", 30))
        .execute::<(), _>(OutcomeInput { request_id: input.request_id, approved: result })
        .await
        .ok();

    Ok(result)
}

// Client sends signal when human approves
async fn approve_request(client: &Client, workflow_id: &str, run_id: &str) -> anyhow::Result<()> {
    client
        .signal_workflow_execution(workflow_id, run_id, "approval-decision", ApprovalDecision::Approved)
        .await
}
```

---

## Activities (Side Effects)

```rust
// src/activities/payment_activities.rs
use temporal_sdk::{ActContext, activity};

#[activity]
pub async fn charge_payment(ctx: ActContext, input: ChargePaymentInput) -> Result<PaymentResult, anyhow::Error> {
    // Heartbeat for long-running activities
    ctx.heartbeat(serde_json::json!({ "progress": "starting" }));

    let client = PaymentClient::new();

    // Idempotency key = order_id ensures no double charges on retry
    let result = client
        .charge(ChargeRequest {
            idempotency_key: input.order_id.clone(),
            amount_cents: input.amount_cents,
            customer_id: input.user_id,
        })
        .await
        .map_err(|e| match e {
            PaymentError::CardDeclined => {
                // Non-retryable — wrap with ApplicationError
                anyhow::anyhow!("CardDeclinedError: {e}")
            }
            _ => anyhow::anyhow!("Payment failed: {e}"),
        })?;

    Ok(PaymentResult {
        payment_id: result.id,
        charged_at: result.timestamp,
    })
}

#[activity]
pub async fn reserve_inventory(_ctx: ActContext, input: ReserveInventoryInput) -> Result<(), anyhow::Error> {
    let db = get_db().await;

    // Use a database transaction — idempotent on retry due to unique constraint on order_id
    sqlx::query(
        "INSERT INTO inventory_reservations (order_id, items) VALUES ($1, $2)
         ON CONFLICT (order_id) DO NOTHING"
    )
    .bind(&input.order_id)
    .bind(serde_json::to_value(&input.items)?)
    .execute(&db)
    .await
    .map_err(|e| anyhow::anyhow!("InsufficientInventoryError: {e}"))?;

    Ok(())
}
```

---

## Worker Setup

```rust
// src/worker.rs
use temporal_sdk::{Worker, WorkerConfig};

pub async fn run_worker(temporal_host: &str) -> anyhow::Result<()> {
    let client = temporal_client::ClientOptions::default()
        .with_target_url(temporal_host)
        .build()
        .await?;

    let mut worker = Worker::new(
        WorkerConfig {
            task_queue: "order-processing".to_string(),
            max_concurrent_activity_task_executions: 20,
            max_concurrent_workflow_task_executions: 10,
            ..Default::default()
        },
        &client,
    );

    // Register workflows
    worker.register_wf(order_workflow::order_workflow);
    worker.register_wf(approval_workflow::approval_workflow);

    // Register activities
    worker.register_activity(payment_activities::charge_payment);
    worker.register_activity(payment_activities::refund_payment);
    worker.register_activity(inventory_activities::reserve_inventory);
    worker.register_activity(inventory_activities::release_inventory);
    worker.register_activity(notification_activities::send_email);

    tracing::info!("Worker started on task queue: order-processing");
    worker.run().await?;

    Ok(())
}
```

---

## Starting Workflows

```rust
// Start with a deterministic business key as workflow ID
async fn place_order(order: Order) -> anyhow::Result<()> {
    let workflow_id = format!("order-{}", order.id); // business key — idempotent

    client
        .start_workflow(
            vec![OrderInput::from(&order)],
            "order-processing",     // task queue
            workflow_id,
            "order_workflow",       // workflow type
            None,
            WorkflowOptions {
                execution_timeout: Some(Duration::from_secs(24 * 3600)), // 24h max
                ..Default::default()
            },
        )
        .await?;

    Ok(())
}
```

---

## Queries (Read Current State)

```rust
#[workflow]
pub async fn order_workflow(ctx: WfContext, input: OrderInput) -> Result<OrderOutput, anyhow::Error> {
    let mut current_step = "initializing".to_string();

    // Register query handler
    ctx.query_handler("get-status", |_: ()| {
        Ok(OrderStatus { step: current_step.clone() })
    });

    current_step = "reserving_inventory".to_string();
    // ... activity calls
}
```

---

## Rules

- **Workflows must be deterministic**: no I/O, no `rand`, no `SystemTime::now()`, no mutable global state
- **Retry policies are mandatory on all activities**: always specify `maximum_attempts` and `non_retryable_error_types`
- **Activities must be idempotent**: retries must be safe; use idempotency keys for payment and write operations
- **Workflow ID is the business key**: use the order ID, request ID, or other business entity ID; never a random UUID
- **Compensating activities for rollback**: always define a compensation activity for each reversible side effect
- **Signals for human interaction**: never poll for external input; use `make_signal_channel` and `timer` for timeouts
- **Heartbeat long-running activities**: activities running > 30s must call `ctx.heartbeat()` periodically
- **Execution timeout on every workflow**: maximum workflow duration must be bounded
- **Queries for status inspection**: expose `get-status` query on all workflows with meaningful state
- **Separate task queues per concern**: `order-processing`, `onboarding`, `notifications` — never share one task queue across all workflows
