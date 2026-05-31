<!-- Audit: B.8.5 (b8-5-postgres-pgvector) -->
# Tasks: b8-5-postgres-pgvector

TDD-ordered. Re-scoped (DBOS-Rust phantom → deferred). Concrete pgvector image
verify-then-pin done LIVE: **`pgvector/pgvector:0.8.2-pg17`** (Docker Hub, latest
pgvector 0.8.x on pg17; satisfies persistence.yaml postgres-17 + pgvector-0.8).
2.0.0.yaml + orchestration.yaml edits keep b8-3 17/17 + b8-3b 12/12 green.

## Phase 0 — Verify-then-pin (LIVE) — DONE
- [ ] **T001** Record evidence.md: pgvector image `pgvector/pgvector:0.8.2-pg17`
  (Docker Hub tag list); DBOS-Rust-absent (crates.io 404 + Context7); persistence.yaml
  is the policy source (postgres-17, pgvector-0.8). [Story: FR-B85-030, NFR-B85-005]

## Phase 1 — Harness RED
- [ ] **T002** Author `.forge/scripts/tests/b8-5.test.sh` (12 L1 per design), run → RED.
  [Story: FR-B85-050..056]

## Phase 2 — Datastore templates GREEN
- [ ] **T003** Create `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/postgres/`:
  `docker-compose.fragment.yml.tmpl` (fsm-db `pgvector/pgvector:0.8.2-pg17`, init-SQL
  mount, pg_isready healthcheck), `init-pgvector.sql.tmpl` (`CREATE EXTENSION IF NOT
  EXISTS vector;`), `README.md.tmpl`. Additive — flat 1.0.0 docker-compose.dev.yml
  (postgres:16-alpine) byte-untouched. [Story: FR-B85-010..014, 020..021]

## Phase 3 — orchestration.yaml DBOS-deferral
- [ ] **T004** Bump `.forge/standards/orchestration.yaml` 1.0.0 → 1.1.0 (additive
  `rust_sdk_status:` body field — DBOS no Rust SDK, Temporal retained, default:dbos
  language-conditional; last_reviewed/expires_at → 2026-05-31/2027-05-31) + REVIEW.md
  KEEP-WITH-CHANGES row `| orchestration.yaml | 1.1.0 |`. Validate dir-mode:
  `validate-standards-yaml.sh .forge/standards/` exit 0. [Story: FR-B85-002..004]

## Phase 4 — 2.0.0.yaml dbos-deferred
- [ ] **T005** Edit `2.0.0.yaml`: dbos-embedded component += `status: deferred` + `note:`;
  temporal→dbos migration_delta += `note:` deferred. postgres delta + persistence ref
  INTACT. Re-run b8-3 (17/17) + b8-3b (12/12) — MUST stay GREEN. [Story: FR-B85-006]

## Phase 5 — GREEN + Integration
- [ ] **T006** Run b8-5.test.sh → 12/12 GREEN. [Story: FR-B85-*]
- [ ] **T007** Register `b8-5.test.sh` one-line in forge-ci.yml harness loop (after b8-4).
  [Story: FR-B85-050]
- [ ] **T008** CHANGELOG `[Unreleased]` entry.

## Phase 6 — Verification
- [ ] **T009** FULL gate sweep (lesson: run all ~43 harnesses, not just the brick):
  verify.sh PASS, constitution-linter PASS, b8-3/b8-3b/b8-4/b8-5 green, delivery green
  (versioned-tree scan), 1.0.0 postgres:16 + schema.yaml byte-untouched.
- [ ] **T010** Independent reviewer validates impl before archive.
