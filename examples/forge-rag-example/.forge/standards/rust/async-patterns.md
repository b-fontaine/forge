# Rust Async Patterns Standard

## Tokio Runtime Setup

```rust
// bin/server/src/main.rs
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    infrastructure::telemetry::setup()?;
    infrastructure::server::run().await
}

// For fine-grained control (e.g., setting worker threads):
fn main() -> anyhow::Result<()> {
    tokio::runtime::Builder::new_multi_thread()
        .worker_threads(num_cpus::get())
        .enable_all()
        .build()?
        .block_on(async_main())
}
```

---

## Structured Concurrency

### spawn — Independent Background Tasks

```rust
use tokio::task::JoinHandle;

// Fire and forget with error logging
tokio::spawn(async move {
    if let Err(e) = send_welcome_email(user).await {
        tracing::error!(error = %e, "Failed to send welcome email");
    }
});

// Collect results with JoinHandle
async fn process_all(items: Vec<Item>) -> anyhow::Result<Vec<Result>> {
    let handles: Vec<JoinHandle<anyhow::Result<ProcessedItem>>> = items
        .into_iter()
        .map(|item| tokio::spawn(async move { process(item).await }))
        .collect();

    let mut results = Vec::with_capacity(handles.len());
    for handle in handles {
        results.push(handle.await??); // outer ? = JoinError, inner ? = task error
    }
    Ok(results)
}
```

### join! — Concurrent Independent Futures

```rust
// Run concurrently, fail fast if any fails
async fn load_dashboard(user_id: Uuid) -> anyhow::Result<Dashboard> {
    let (profile, orders, notifications) = tokio::try_join!(
        user_service.get_profile(user_id),
        order_service.get_recent(user_id, limit: 10),
        notification_service.get_unread(user_id),
    )?;

    Ok(Dashboard { profile, orders, notifications })
}

// Run all even if some fail
let (profile_result, orders_result) = tokio::join!(
    user_service.get_profile(user_id),
    order_service.get_recent(user_id, 10),
);
```

### select! — Race Futures

```rust
use tokio::select;
use tokio_util::sync::CancellationToken;

async fn run_with_cancellation(
    token: CancellationToken,
) -> anyhow::Result<()> {
    select! {
        result = do_work() => {
            result.context("Work failed")?;
        }
        _ = token.cancelled() => {
            tracing::info!("Task cancelled, shutting down");
        }
    }
    Ok(())
}

// Race a future against a timeout
async fn with_timeout<T>(
    duration: Duration,
    fut: impl Future<Output = anyhow::Result<T>>,
) -> anyhow::Result<T> {
    select! {
        result = fut => result,
        _ = tokio::time::sleep(duration) => {
            Err(anyhow::anyhow!("Operation timed out after {duration:?}"))
        }
    }
}
```

---

## Channels

### mpsc — Multiple Producers, Single Consumer

Use for: work queues, event pipelines, task submission.

```rust
use tokio::sync::mpsc;

let (tx, mut rx) = mpsc::channel::<Task>(256); // bounded — always prefer bounded

// Producer (can be cloned and sent across threads)
let tx_clone = tx.clone();
tokio::spawn(async move {
    tx_clone.send(task).await.expect("receiver dropped");
});

// Consumer
tokio::spawn(async move {
    while let Some(task) = rx.recv().await {
        process(task).await;
    }
    tracing::info!("Channel closed, consumer exiting");
});
```

### broadcast — Single Producer, Multiple Consumers

Use for: pub/sub, event notifications, cache invalidation signals.

```rust
use tokio::sync::broadcast;

let (tx, _) = broadcast::channel::<Event>(1024);

// Each subscriber gets its own receiver
let mut rx1 = tx.subscribe();
let mut rx2 = tx.subscribe();

// Publisher
tx.send(Event::UserUpdated { id }).ok(); // ok() ignores "no receivers" error

// Subscriber
tokio::spawn(async move {
    loop {
        match rx1.recv().await {
            Ok(event) => handle_event(event).await,
            Err(broadcast::error::RecvError::Lagged(n)) => {
                tracing::warn!("Subscriber lagged, missed {n} events");
            }
            Err(broadcast::error::RecvError::Closed) => break,
        }
    }
});
```

### oneshot — Single Message, Single Response

Use for: request-response patterns, completing a pending operation.

```rust
use tokio::sync::oneshot;

async fn submit_and_await(task: Task) -> anyhow::Result<TaskResult> {
    let (tx, rx) = oneshot::channel();
    worker_tx.send((task, tx)).await?;
    rx.await.context("Worker dropped without responding")
}

// Worker side
while let Some((task, reply_tx)) = rx.recv().await {
    let result = process(task).await;
    reply_tx.send(result).ok(); // caller may have timed out
}
```

### watch — Latest Value Broadcast

Use for: configuration updates, health state, shared mutable observable.

```rust
use tokio::sync::watch;

let (tx, rx) = watch::channel(AppConfig::default());

// Update from one place
tx.send(new_config).ok();

// Multiple readers get the latest value
let mut rx_clone = rx.clone();
tokio::spawn(async move {
    loop {
        rx_clone.changed().await.expect("sender dropped");
        let config = rx_clone.borrow().clone();
        reconfigure(config).await;
    }
});
```

---

## Stream Processing

```rust
use tokio_stream::{Stream, StreamExt};
use futures::TryStreamExt;

// Process items as they arrive
async fn process_stream(
    mut stream: impl Stream<Item = anyhow::Result<Record>> + Unpin,
) -> anyhow::Result<()> {
    while let Some(record) = stream.try_next().await? {
        handle_record(record).await?;
    }
    Ok(())
}

// Buffered concurrent processing (up to N concurrent)
async fn process_buffered(records: Vec<Record>) -> anyhow::Result<Vec<Processed>> {
    tokio_stream::iter(records)
        .map(|r| async move { process_one(r).await })
        .buffered(10) // at most 10 concurrent
        .try_collect()
        .await
}

// Batch processing with chunks
async fn process_in_batches(
    mut stream: impl Stream<Item = Record> + Unpin,
    batch_size: usize,
) -> anyhow::Result<()> {
    let mut batch = Vec::with_capacity(batch_size);

    while let Some(record) = stream.next().await {
        batch.push(record);
        if batch.len() >= batch_size {
            flush_batch(&batch).await?;
            batch.clear();
        }
    }

    if !batch.is_empty() {
        flush_batch(&batch).await?;
    }

    Ok(())
}
```

---

## Graceful Shutdown

```rust
// src/infrastructure/server/shutdown.rs
use tokio_util::sync::CancellationToken;
use tokio::signal;

pub async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("Failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("Failed to install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }

    tracing::info!("Shutdown signal received");
}

pub async fn run_with_graceful_shutdown(token: CancellationToken) -> anyhow::Result<()> {
    tokio::select! {
        _ = shutdown_signal() => {
            tracing::info!("Initiating graceful shutdown");
            token.cancel();
        }
        result = run_server(token.clone()) => {
            return result;
        }
    }

    // Wait for in-flight requests to complete
    tokio::time::timeout(Duration::from_secs(30), drain_connections()).await
        .context("Graceful shutdown timed out")?;

    Ok(())
}
```

---

## Timeouts

```rust
use tokio::time::{timeout, Duration};

// Timeout a single operation
async fn fetch_with_timeout(url: &str) -> anyhow::Result<String> {
    timeout(Duration::from_secs(10), http_get(url))
        .await
        .context("Request timed out")?
        .context("Request failed")
}

// Retry with exponential backoff
async fn retry_with_backoff<T, Fut, F>(
    mut f: F,
    max_attempts: u32,
) -> anyhow::Result<T>
where
    F: FnMut() -> Fut,
    Fut: Future<Output = anyhow::Result<T>>,
{
    let mut delay = Duration::from_millis(100);

    for attempt in 1..=max_attempts {
        match f().await {
            Ok(result) => return Ok(result),
            Err(e) if attempt == max_attempts => return Err(e),
            Err(e) => {
                tracing::warn!(attempt, error = %e, "Attempt failed, retrying in {delay:?}");
                tokio::time::sleep(delay).await;
                delay = (delay * 2).min(Duration::from_secs(30));
            }
        }
    }

    unreachable!()
}
```

---

## Rules

- **All I/O is async**: no `std::thread::sleep`, no blocking file I/O on async tasks
- **Never block in an async context**: use `tokio::task::spawn_blocking` for CPU-bound or blocking I/O
- **All channels are bounded**: never use `unbounded_channel` — it hides backpressure problems
- **Graceful shutdown uses `CancellationToken`**: every long-running task accepts a token and checks it
- **Every async operation has a timeout**: use `tokio::time::timeout` at the service boundary
- **Use `try_join!` for concurrent fetches that must all succeed**
- **Use `select!` to race against cancellation**: never `tokio::time::sleep` in a loop without cancellation
- **Streams are processed with backpressure**: use `buffered(N)` with a bounded N
- **`JoinHandle` errors are never silently dropped**: always `.await` handles or log errors
- **`spawn_blocking` for CPU work > 1ms**: JSON parsing of large payloads, image processing, encryption
