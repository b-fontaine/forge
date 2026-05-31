<!-- Audit: B.8.5 (b8-5-postgres-pgvector) — verify-then-pin evidence ledger -->
# Verify-then-pin Evidence — b8-5-postgres-pgvector

This file records the LIVE-verified facts consumed by the
`2.0.0/infra/postgres/` datastore template tree and the `orchestration.yaml`
1.1.0 DBOS-deferral bump. Verified at `/forge:implement` per ADR-B85-003 (Q-004)
and the kong / b8-coroot / b8-signoz verify-then-pin lesson (pins are resolved
live on the registry, never fabricated upstream of implement).
Verification date: **2026-05-31**.

The single carried `[NEEDS CLARIFICATION]` from design (the concrete
`pgvector/pgvector:pg17`-family tag, distro suffix + exact pgvector minor) is
resolved below.

---

## Pin 1 — pgvector image tag: `pgvector/pgvector:0.8.2-pg17`

- **Value**: `pgvector/pgvector:0.8.2-pg17`.
- **Repository**: Docker Hub `pgvector/pgvector` (the official pgvector image
  family, `pgvector/pgvector:<pgvector-minor>-pg<MAJOR>` + the rolling
  `pg<MAJOR>` tags).
- **Source**: Docker Hub tag listing for `pgvector/pgvector` — `0.8.2-pg17` is
  the latest pgvector 0.8.x release built on Postgres 17. Chosen as a
  **deterministic explicit tag** (the immutable `0.8.2-pg17`), NOT the rolling
  `pg17` alias, so the pin is reproducible (verify-then-pin discipline).
- **Satisfies policy** (`.forge/standards/persistence.yaml` v1.0.0):
  - `default: postgres-17` — the `-pg17` suffix pins Postgres major 17 (the
    2.0.0 delta over the frozen 1.0.0 `postgres:16-alpine` baseline).
  - `extensions: [pgvector-0.8, …]` — the `0.8.2-` prefix pins pgvector 0.8.x
    (≥ 0.8, satisfies the `pgvector-0.8` extension target).
- **Consumed by**:
  `2.0.0/infra/postgres/docker-compose.fragment.yml.tmpl`
  `image: pgvector/pgvector:0.8.2-pg17`.
- **Extension enable**: the image ships the pgvector extension *files*; the
  extension is `CREATE EXTENSION IF NOT EXISTS vector;`-d in the target database
  by `init-pgvector.sql`, mounted into `docker-entrypoint-initdb.d` (runs once
  on first DB init). FR-B85-012.

## Finding 2 — DBOS has NO Rust SDK (DBOS deferred; Temporal retained)

- **Finding**: there is **no `dbos` crate** on crates.io (`cargo add dbos`
  → 404; crates.io has no `dbos` package). DBOS Transact ships SDKs for
  **Python, TypeScript, Go, Java (and Kotlin)** only — there is no Rust SDK.
- **Sources**:
  - crates.io: `dbos` package does not exist (404).
  - Context7 `docs.dbos.dev` (DBOS Transact quickstart + portable-workflows
    explanations) — the supported-language list is Python / TypeScript / Go /
    Java/Kotlin; no Rust.
- **Consequence (Article III.4 — Anti-Hallucination)**: this brick ships **NO**
  `dbos` crate pin, **NO** `Cargo.toml dbos = 0.x`, and **NO** DBOSContext
  boilerplate anywhere. The plan's B.8.5 DBOS-embedded premise is FALSIFIED.
  DBOS is **DEFERRED**; **Temporal is RETAINED** as the 2.0.0 orchestrator for
  the Rust flagship (Constitution Article VIII.2 PRESERVED — no amendment).
- **Recorded in**:
  - `orchestration.yaml` v1.1.0 `rust_sdk_status.dbos.available: false`
    (`rust_flagship_orchestrator: temporal`,
    `default_is_language_conditional: true`). `default: dbos` is left UNCHANGED
    but recorded as a LANGUAGE-CONDITIONAL aspirational non-Rust target, not a
    deployed Rust selection.
  - `2.0.0.yaml` `dbos-embedded` component `status: deferred` + `note:`; the
    `temporal-intent → dbos-embedded` migration_delta `note:` (DEFERRED).

## Policy source — `persistence.yaml` v1.0.0 (CONSUMED, not authored)

- `.forge/standards/persistence.yaml` v1.0.0 (ADR-010, T.4) is the **policy
  source** for the Postgres-17 default (`default: postgres-17`) + the pgvector
  extension target (`extensions: [pgvector-0.8, …]`). B.8.5 **CONSUMES** it
  as-is: it creates NO new persistence standard and does NOT bump
  `persistence.yaml` (ADR-B85-004). The concrete image *tag* (Pin 1) lives in
  the verify-then-pin compose fragment; the *policy* lives in
  `persistence.yaml`; NEITHER is an inline scalar in `2.0.0.yaml`.
