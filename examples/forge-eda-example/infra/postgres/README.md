# Postgres event store (dev)

PostgreSQL 17 (persistence.yaml). `init-eventstore.sql` creates the append-only
`events` log + the `inbox` dedup table on first boot (`task dev:up`).

- **DSN**: `${DATABASE_URL}` (see `.env`)
- **Schema**: mirrors `backend/eventstore/src/store.rs` (`PgEventStore`).

Appends are idempotent (`ON CONFLICT (idempotency_key) DO NOTHING`); `seq` gives a
global order for projection rebuilds. Real migrations (sqlx-migrate / refinery) are
an adopter choice; this seed file is the initial schema.
