# Standard: API Design

## Scope
All API design work: REST endpoints, gRPC services, event-driven APIs, API versioning, contract testing. Applies whenever services communicate over a network boundary.

## Rules

### REST API Design
- **Resource naming**: plural nouns — `/users`, `/orders`, `/products`
- **Path parameters**: resource identifiers only — `/users/{userId}`
- **Query parameters**: filtering, sorting, pagination — `?status=active&sort=-created_at`
- **Pagination**: cursor-based (`?cursor=abc&limit=20`) — never offset-based
- **Error format**: RFC 7807 Problem Details (`application/problem+json`)
- **Versioning**: URL path — `/v1/`, `/v2/`
- **Idempotency**: PUT and DELETE are idempotent; POST uses `Idempotency-Key` header

### gRPC Design (Article VII.2)
- Proto files are the source of truth for service contracts
- One service per bounded context
- Package includes version: `myapp.user.v1`
- Field numbers never reused — use `reserved` for removed fields
- Validate with `buf lint`

### Contract-First
- API contract MUST exist before implementation begins (Article III)
- Every endpoint maps to at least one FR-XXX
- Breaking changes require versioning plan + migration guide
- Consumer team validates contract before finalization

### Event-Driven APIs
- AsyncAPI spec for all event channels
- Schema versioning with backward-compatible evolution
- Domain events follow Socrates' event catalog naming

## Anti-patterns
- **Offset-based pagination**: breaks under concurrent writes, O(n) for deep pages. Use cursors.
- **Custom error formats**: inconsistent error handling across services. Use RFC 7807.
- **Hand-written gRPC code without proto**: violates Article VII.2, creates contract drift.
- **Breaking changes without migration**: consumers break silently. Always version + document.
- **God endpoints**: `/api/do-everything` that accept action parameters. One endpoint = one operation.
- **Leaking internal IDs**: exposing database auto-increment IDs. Use UUIDs or opaque tokens.
