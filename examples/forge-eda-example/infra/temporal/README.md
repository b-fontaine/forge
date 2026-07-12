# Temporal (optional local-dev overlay)

`docker-compose.temporal.yml` runs a **dev-only** Temporal server + Web UI
(`task temporal:up`; UI at http://localhost:${TEMPORAL_UI_PORT:-8233}).

- **Address**: `${TEMPORAL_ADDRESS:-localhost:7233}`
- **Task queue**: `${TEMPORAL_TASK_QUEUE}` (see `.env`)

The backend `saga` crate targets the **native Rust SDK** (`temporalio-sdk` /
`temporalio-client`, pinned in `backend/Cargo.toml`). That SDK is **Public Preview
/ pre-alpha** — the workflow API "will continue to evolve" (infra/temporal.md), so
the backend:

1. runs saga side effects as Temporal **activities only** (no `#[workflow]`
   definitions — see `backend/saga/src/activity.rs`); and
2. keeps the SDK behind the OFF-by-default `temporal-sdk` Cargo feature, so default
   `cargo build`/`test` never compiles the unstable API.

Enable the real worker with `cargo build --features temporal-sdk` and wire it per
the pinned crate's docs (do NOT invent the worker/client builder API — it changes
between versions).

> The production Temporal cluster (history/matching/frontend/worker + Postgres,
> Helm) is B.6.6 — NOT this overlay.
