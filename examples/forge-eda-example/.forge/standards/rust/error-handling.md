# Rust Error Handling Standard

## Technology Stack

| Crate | Layer | Purpose |
|---|---|---|
| `thiserror` | Domain, adapters | Structured, typed error enums |
| `anyhow` | Application, infrastructure | Ergonomic error propagation with context |

---

## Domain Errors with thiserror

Domain errors are exhaustive enums. Every variant represents a business rule violation or infrastructure failure that the caller may handle differently.

```rust
// src/domain/errors/mod.rs
use thiserror::Error;
use uuid::Uuid;

#[derive(Debug, Error)]
pub enum DomainError {
    // Business rule violations
    #[error("Invalid email address: {value}")]
    InvalidEmail { value: String },

    #[error("Password must be at least 8 characters")]
    PasswordTooShort,

    #[error("User not found")]
    UserNotFound,

    #[error("Invalid credentials")]
    InvalidCredentials,

    #[error("User {id} is already active")]
    UserAlreadyActive { id: Uuid },

    #[error("Insufficient permissions: required {required}, got {actual}")]
    InsufficientPermissions { required: String, actual: String },

    // Infrastructure failures surfaced to domain
    #[error("Repository error: {0}")]
    Repository(String),

    #[error("External service unavailable: {service}")]
    ServiceUnavailable { service: String },
}

// Feature-specific errors can be sub-enums
#[derive(Debug, Error)]
pub enum OrderError {
    #[error("Order {id} not found")]
    NotFound { id: Uuid },

    #[error("Order {id} is already in status {status}")]
    InvalidStatusTransition { id: Uuid, status: String },

    #[error("Insufficient inventory for product {product_id}: requested {requested}, available {available}")]
    InsufficientInventory {
        product_id: Uuid,
        requested: u32,
        available: u32,
    },

    #[error(transparent)]
    Domain(#[from] DomainError),
}
```

---

## Application Errors with anyhow

At the application layer, use `anyhow::Result<T>` for orchestration code. Add context at every boundary crossing.

```rust
// src/application/services/auth_service.rs
use anyhow::{Context, Result};
use crate::domain::errors::DomainError;

pub struct AuthService { /* ... */ }

impl AuthService {
    pub async fn sign_in(&self, email: &str, password: &str) -> Result<AuthToken> {
        let email = Email::new(email)
            .context("Parsing sign-in email")?;

        let user = self
            .user_repo
            .find_by_email(&email)
            .await
            .with_context(|| format!("Looking up user by email {email}"))?
            .ok_or(DomainError::UserNotFound)
            .context("User not found during sign-in")?;

        let is_valid = self
            .password_hasher
            .verify(password, &user.password_hash)
            .context("Verifying password hash")?;

        if !is_valid {
            return Err(DomainError::InvalidCredentials.into());
        }

        let token = self
            .token_service
            .generate(&user)
            .await
            .context("Generating auth token")?;

        Ok(token)
    }

    pub async fn register(&self, req: RegisterRequest) -> Result<User> {
        // ? operator propagates anyhow errors with full context chain
        let email = Email::new(&req.email)?;
        let hash = self.password_hasher.hash(&req.password)?;
        let user = User::new(UserId::new(), email, req.name, hash);
        self.user_repo.save(&user).await?;
        Ok(user)
    }
}
```

---

## Adapter Error Mapping

At the inbound adapter boundary (gRPC, HTTP, CLI), convert `anyhow::Error` or domain errors to the protocol's error type.

```rust
// src/adapters/inbound/grpc/error_mapping.rs
use crate::domain::errors::DomainError;
use tonic::{Code, Status};

pub fn to_status(err: anyhow::Error) -> Status {
    // Try to downcast to known domain error
    if let Some(domain_err) = err.downcast_ref::<DomainError>() {
        return domain_error_to_status(domain_err);
    }

    tracing::error!(error = %err, "Unhandled error");
    Status::internal("Internal server error")
}

fn domain_error_to_status(err: &DomainError) -> Status {
    match err {
        DomainError::UserNotFound => Status::not_found("User not found"),
        DomainError::InvalidCredentials => Status::unauthenticated("Invalid credentials"),
        DomainError::InsufficientPermissions { .. } => Status::permission_denied(err.to_string()),
        DomainError::InvalidEmail { .. } | DomainError::PasswordTooShort => {
            Status::invalid_argument(err.to_string())
        }
        DomainError::Repository(_) | DomainError::ServiceUnavailable { .. } => {
            tracing::error!(error = %err, "Infrastructure error");
            Status::unavailable("Service temporarily unavailable")
        }
        _ => {
            tracing::error!(error = %err, "Unexpected domain error");
            Status::internal("Internal error")
        }
    }
}
```

---

## Outbound Adapter Error Conversion

Convert third-party errors to domain errors at the outbound adapter boundary.

```rust
// src/adapters/outbound/persistence/postgres_user_repository.rs
use sqlx::Error as SqlxError;
use crate::domain::errors::DomainError;

fn map_sqlx_error(err: SqlxError) -> DomainError {
    match &err {
        SqlxError::RowNotFound => DomainError::UserNotFound,
        SqlxError::Database(db_err) if db_err.is_unique_violation() => {
            DomainError::Repository(format!("Unique constraint violation: {db_err}"))
        }
        _ => DomainError::Repository(err.to_string()),
    }
}

// Use #[from] for automatic conversion in thiserror
#[derive(Debug, Error)]
pub enum RepositoryError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

impl From<RepositoryError> for DomainError {
    fn from(err: RepositoryError) -> Self {
        DomainError::Repository(err.to_string())
    }
}
```

---

## Error Logging Rules

Log errors **only at the handling point**, not at the propagation point.

```rust
// Bad: logs at every level, produces duplicate log entries
async fn handler(&self, req: Request) -> Result<Response, Status> {
    let result = self.service.do_thing().await;
    if let Err(ref e) = result {
        tracing::error!("Error in do_thing: {e}"); // <- don't log here
    }
    result.map_err(|e| {
        tracing::error!("Error converting: {e}"); // <- or here
        to_status(e)
    })
}

// Good: log once at the boundary where you handle and convert
async fn handler(&self, req: Request) -> Result<Response, Status> {
    self.service
        .do_thing()
        .await
        .map(build_response)
        .map_err(|err| {
            tracing::error!(error = %err, "Request failed");
            to_status(err)
        })
}
```

---

## Complete Example

```rust
// Domain value object returning domain error
pub fn new_positive(value: i64) -> Result<Money, DomainError> {
    if value <= 0 {
        return Err(DomainError::InvalidAmount { value });
    }
    Ok(Self(value))
}

// Application service using anyhow
pub async fn transfer(&self, from: Uuid, to: Uuid, amount: i64) -> anyhow::Result<()> {
    let amount = Money::new_positive(amount)
        .context("Validating transfer amount")?;

    let from_account = self.accounts.find(from).await
        .with_context(|| format!("Loading source account {from}"))?;

    let to_account = self.accounts.find(to).await
        .with_context(|| format!("Loading destination account {to}"))?;

    let (updated_from, updated_to) = from_account
        .transfer_to(to_account, amount)
        .context("Executing transfer")?;

    self.accounts.save(&updated_from).await
        .context("Saving source account after transfer")?;
    self.accounts.save(&updated_to).await
        .context("Saving destination account after transfer")?;

    Ok(())
}

// gRPC handler converting to Status
async fn transfer(
    &self,
    request: Request<TransferRequest>,
) -> Result<Response<TransferResponse>, Status> {
    let req = request.into_inner();
    self.service
        .transfer(req.from_id.parse()?, req.to_id.parse()?, req.amount)
        .await
        .map(|_| Response::new(TransferResponse { success: true }))
        .map_err(|err| {
            tracing::error!(error = %err, from = %req.from_id, to = %req.to_id, "Transfer failed");
            to_status(err)
        })
}
```

---

## Rules

- **Zero `unwrap()` in production code**: use `?`, `map_err`, or explicit `match`
- **Zero `panic!()` in production code**: return an error instead
- **`.expect()` only in initialization code** (e.g., parsing a compile-time constant): add a message explaining what invariant was violated
- **Domain errors use `thiserror`**: typed, exhaustive, matchable
- **Application layer uses `anyhow`**: ergonomic propagation with `context()`/`with_context()`
- **Map third-party errors to domain errors at adapter boundaries**: `sqlx::Error` → `DomainError::Repository`
- **Log errors once, at the handling point**: not at every propagation step
- **Never expose internal error details to external callers**: map to generic messages at inbound adapter boundary
- **Use `#[from]` in `thiserror` to auto-implement `From`**: reduces boilerplate at conversion points
