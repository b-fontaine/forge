# Verify-then-pin — b7-10-streaming (B.7.10)

> **Type** : research note (Phase 0, `/forge:implement b7-10-streaming`)
> **Date** : 2026-06-23
> **Method** : `cargo add --dry-run` in a throwaway scratch crate (no repo mutation),
>   toolchain `cargo 1.96.0 / rustc 1.96.0`. Article III.4 — pins resolved LIVE,
>   never copied from a note. Connect-ES streaming API re-confirmed via Context7
>   (`/connectrpc/connect-es`, 2026-06-23).
> **Consumes** : `.forge/changes/b7-10-streaming/specs.md` FR-B7-10-010..015 /
>   NFR-B7-10-005, `design.md` ADR-B7-10-001..006 (Q-3 backend stream seam,
>   Q-4 buf-breaking).

## Q-3 — backend streaming seam + whether a new crate is needed

The b7-2 backend ledger (`backend/Cargo.toml.tmpl`) already carries:

- `tokio = { version = "1", features = ["full"] }` — `tokio::sync::mpsc` (bounded
  channel) + `tokio::task` (spawn/`JoinHandle::abort`) are in `full`.
- `futures = "0.3"` — the `Stream` trait + combinators.
- `async-openai = "0.41.1"` (the unary upstream client; exposes a streaming
  chat-completions API the real `generate_stream` impl will wrap at b7-6 live wiring).
- `async-trait = "0.1"` — async trait methods (the streaming `Upstream` port).

### Seam decision (ADR-B7-10-001 / design §Component Design)

- **Backpressure (FR-B7-10-012)** — a **bounded `tokio::sync::mpsc` channel** with a
  named, documented capacity constant `STREAM_CHANNEL_CAPACITY` (NOT a magic literal).
  The producer task `send().await`s into the bounded channel, so a slow consumer
  applies natural backpressure (the producer suspends when the channel is full).
- **Stream surface** — the gateway returns `impl Stream<Item = QueryChunk>` to the
  Connect server-streaming handler. The idiomatic, allocation-free `Receiver →
  Stream` adapter is **`tokio_stream::wrappers::ReceiverStream`**. This is the ONE
  new crate.
- **Cancellation (FR-B7-10-013)** — kept dependency-light, NO `tokio-util`
  `CancellationToken`: the producer runs in a spawned task; the streaming entrypoint
  holds its `tokio::task::JoinHandle`, whose `.abort()` is the cooperative-cancel
  primitive (client Stop / unmount → handler drops the stream → entrypoint aborts the
  producer). The bounded channel ALSO provides client-disconnect cancellation for
  free: when the consumer drops the `Receiver`, the producer's `send().await` returns
  `Err(SendError)`, which the producer treats as "consumer gone → stop + emit the
  close audit". Both paths emit the close-time prompt-audit (FR-B7-10-015).

### New crate (verify-then-pin LIVE, 2026-06-23)

| Crate | `cargo add --dry-run` LIVE | Decision |
|---|---|---|
| `tokio-stream` | **`v0.1.18`** | **PIN** — `wrappers::ReceiverStream` adapter |
| `async-stream` | `v0.3.6` (resolved) | NOT used — `ReceiverStream` + a spawned producer covers the seam without a `stream!` macro |
| `tokio-util` | `v0.7.18` (resolved) | NOT used — `JoinHandle::abort` + closed-channel signal replace `CancellationToken`, avoiding a 2nd new crate |

**Resolved pin (PIN AT IMPLEMENT, this brick):**

```toml
# backend/Cargo.toml.tmpl [workspace.dependencies] — pins live HERE only
# (ADR-B7-10-004 / NFR-B7-10-005); never in a global/*.md standard or a frontend file.
tokio-stream = "0.1.18"   # wrappers::ReceiverStream → bounded mpsc Receiver as a Stream
```

Consumed by `llm_gateway` only (`tokio-stream.workspace = true` in
`backend/llm_gateway/Cargo.toml.tmpl`). `rag` and `mcp` are unchanged.

## Q-4 — `buf breaking` config tolerates adding `QueryStream` + `QueryChunk`

The archetype's `shared/protos/buf.yaml.tmpl` uses `breaking: use: [FILE]`. Adding a
**new RPC** to an existing service and a **new message** are backward-compatible
changes — the `FILE` rule set flags wire/source-incompatible changes (deleted/renamed
fields, changed field types, deleted RPCs), NOT additions. So `buf breaking` against
the b7-2 baseline reports **no breaking change** (FR-B7-10-003). `buf lint` STANDARD
(with the existing `PACKAGE_DIRECTORY_MATCH` exception) is satisfied: the new RPC
follows `service_suffix: Service` (still on `RagService`), and the streamed message
`QueryChunk` follows message-naming. The unary `Query` RPC + `QueryResponse` /
`SourceChunk` are retained unchanged, so no field is removed/renumbered.

> `buf` is ABSENT in this environment, so the L2 `buf lint`/`buf breaking` legs
> SKIP gracefully (b7-2 L2 convention). The structural assertion is made at L1; the
> live buf verification rides `b7-6-harness` (which ships the toolchain).

## Frontend pins — NOT re-pinned (NFR-B7-10-005)

Connect-ES (`@connectrpc/connect` / `@connectrpc/connect-web` `^2.0.0`),
Qwik (`^1.20.0`), Vite (`=7.3.5`), protobuf-es (`^2.2.0`) stay owned by
`transport.yaml` / `web-frontend.yaml`. The streaming UI (`queryStream` `for await`,
`AbortController` cancel) uses ONLY APIs already provided by those pinned versions —
Context7 `/connectrpc/connect-es` (2026-06-23) confirms `for await (const res of
client.method(req, { signal }))` server-streaming consumption with an `AbortSignal`
call option. No new frontend dependency.

## Re-verification note

`tokio-stream` resolved to `0.1.18` LIVE on 2026-06-23. The pin is placed in the
consuming `backend/Cargo.toml.tmpl` only, re-verified by the L2 `cargo check` leg on
the rendered tree (cargo present here). `b7-6-harness` re-verifies LIVE at promotion.
