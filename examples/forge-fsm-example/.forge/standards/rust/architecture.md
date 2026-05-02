# Rust Hexagonal Architecture Standard

## Directory Structure

```
src/
├── domain/
│   ├── entities/          # Core business objects (no external deps)
│   │   ├── mod.rs
│   │   ├── user.rs
│   │   └── order.rs
│   ├── value_objects/     # Immutable typed values
│   │   ├── mod.rs
│   │   ├── email.rs
│   │   └── money.rs
│   ├── events/            # Domain events
│   │   ├── mod.rs
│   │   └── order_events.rs
│   ├── errors/            # Domain-specific error types
│   │   ├── mod.rs
│   │   └── auth_errors.rs
│   └── ports/
│       ├── inbound/       # Use case interfaces (driven by application)
│       │   ├── mod.rs
│       │   └── sign_in_port.rs
│       └── outbound/      # Repository/service interfaces (drive adapters)
│           ├── mod.rs
│           ├── user_repository.rs
│           └── email_service.rs
├── application/
│   └── services/          # Orchestrates domain; implements inbound ports
│       ├── mod.rs
│       └── auth_service.rs
├── adapters/
│   ├── inbound/
│   │   ├── grpc/          # tonic gRPC handlers
│   │   │   ├── mod.rs
│   │   │   └── auth_handler.rs
│   │   └── cli/           # clap CLI commands
│   │       ├── mod.rs
│   │       └── commands.rs
│   └── outbound/
│       ├── persistence/   # sqlx, diesel, redis adapters
│       │   ├── mod.rs
│       │   └── postgres_user_repository.rs
│       └── external/      # HTTP clients, queue publishers
│           ├── mod.rs
│           └── sendgrid_email_service.rs
└── infrastructure/
    ├── config/            # Environment config loading
    │   ├── mod.rs
    │   └── app_config.rs
    ├── telemetry/         # Tracing, metrics, logging setup
    │   ├── mod.rs
    │   └── setup.rs
    └── server/            # Runtime wiring (DI, startup, shutdown)
        ├── mod.rs
        └── grpc_server.rs
```

---

## Cargo Workspace (Large Projects)

For large projects, split into multiple crates:

```toml
# Cargo.toml (workspace root)
[workspace]
members = [
    "crates/domain",
    "crates/application",
    "crates/adapter-grpc",
    "crates/adapter-postgres",
    "crates/infrastructure",
    "bin/server",
    "bin/cli",
]
resolver = "2"

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }
tonic = "0.12"
sqlx = { version = "0.8", features = ["postgres", "runtime-tokio", "macros"] }
serde = { version = "1", features = ["derive"] }
thiserror = "2"
anyhow = "1"
tracing = "0.1"
uuid = { version = "1", features = ["v4", "serde"] }
```

```toml
# crates/domain/Cargo.toml
[package]
name = "domain"
version.workspace = true
edition = "2021"

[dependencies]
# ZERO external dependencies — only std and workspace-shared pure types
thiserror.workspace = true
serde.workspace = true
uuid.workspace = true
```

---

## Domain Layer

```rust
// src/domain/entities/user.rs
use crate::domain::value_objects::{Email, UserId};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct User {
    pub id: UserId,
    pub email: Email,
    pub name: String,
    pub role: UserRole,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

impl User {
    pub fn new(id: UserId, email: Email, name: String) -> Self {
        Self {
            id,
            email,
            name,
            role: UserRole::Member,
            created_at: chrono::Utc::now(),
        }
    }

    pub fn promote_to_admin(&mut self) {
        self.role = UserRole::Admin;
    }

    pub fn is_admin(&self) -> bool {
        matches!(self.role, UserRole::Admin)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum UserRole {
    Member,
    Admin,
}
```

```rust
// src/domain/value_objects/email.rs
use crate::domain::errors::DomainError;
use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Email(String);

impl Email {
    pub fn new(value: impl Into<String>) -> Result<Self, DomainError> {
        let value = value.into();
        if value.contains('@') && value.contains('.') {
            Ok(Self(value))
        } else {
            Err(DomainError::InvalidEmail { value })
        }
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for Email {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
```

---

## Port Traits (Interfaces)

```rust
// src/domain/ports/outbound/user_repository.rs
use crate::domain::entities::{User, UserId};
use crate::domain::errors::DomainError;
use crate::domain::value_objects::Email;
use async_trait::async_trait;

#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: &UserId) -> Result<Option<User>, DomainError>;
    async fn find_by_email(&self, email: &Email) -> Result<Option<User>, DomainError>;
    async fn save(&self, user: &User) -> Result<(), DomainError>;
    async fn delete(&self, id: &UserId) -> Result<(), DomainError>;
}

// src/domain/ports/inbound/sign_in_port.rs
use crate::domain::entities::User;
use crate::domain::errors::DomainError;
use async_trait::async_trait;

#[async_trait]
pub trait SignInPort: Send + Sync {
    async fn sign_in(&self, email: &str, password: &str) -> Result<User, DomainError>;
}
```

---

## Application Service

```rust
// src/application/services/auth_service.rs
use crate::domain::errors::DomainError;
use crate::domain::ports::inbound::SignInPort;
use crate::domain::ports::outbound::{PasswordHasher, UserRepository};
use async_trait::async_trait;
use std::sync::Arc;

pub struct AuthService {
    user_repo: Arc<dyn UserRepository>,
    password_hasher: Arc<dyn PasswordHasher>,
}

impl AuthService {
    pub fn new(
        user_repo: Arc<dyn UserRepository>,
        password_hasher: Arc<dyn PasswordHasher>,
    ) -> Self {
        Self { user_repo, password_hasher }
    }
}

#[async_trait]
impl SignInPort for AuthService {
    async fn sign_in(&self, email: &str, password: &str) -> Result<User, DomainError> {
        let email = Email::new(email)?;
        let user = self
            .user_repo
            .find_by_email(&email)
            .await?
            .ok_or(DomainError::UserNotFound)?;

        if !self.password_hasher.verify(password, &user.password_hash)? {
            return Err(DomainError::InvalidCredentials);
        }

        Ok(user)
    }
}
```

---

## Adapter Implementation

```rust
// src/adapters/outbound/persistence/postgres_user_repository.rs
use crate::domain::entities::{User, UserId};
use crate::domain::errors::DomainError;
use crate::domain::ports::outbound::UserRepository;
use async_trait::async_trait;
use sqlx::PgPool;

pub struct PostgresUserRepository {
    pool: PgPool,
}

impl PostgresUserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl UserRepository for PostgresUserRepository {
    async fn find_by_id(&self, id: &UserId) -> Result<Option<User>, DomainError> {
        let row = sqlx::query_as::<_, UserRow>(
            "SELECT id, email, name, role, created_at FROM users WHERE id = $1",
        )
        .bind(id.as_uuid())
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| DomainError::Repository(e.to_string()))?;

        Ok(row.map(UserRow::into_domain))
    }

    async fn save(&self, user: &User) -> Result<(), DomainError> {
        sqlx::query(
            "INSERT INTO users (id, email, name, role, created_at)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (id) DO UPDATE SET email = $2, name = $3, role = $4",
        )
        .bind(user.id.as_uuid())
        .bind(user.email.as_str())
        .bind(&user.name)
        .bind(user.role.to_string())
        .bind(user.created_at)
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::Repository(e.to_string()))?;

        Ok(())
    }

    // ... other methods
}
```

---

## Infrastructure Wiring

```rust
// src/infrastructure/server/grpc_server.rs
use std::sync::Arc;

pub async fn build_and_run() -> anyhow::Result<()> {
    let config = AppConfig::from_env()?;
    let pool = PgPool::connect(&config.database_url).await?;

    // Wire adapters
    let user_repo: Arc<dyn UserRepository> = Arc::new(PostgresUserRepository::new(pool.clone()));
    let password_hasher: Arc<dyn PasswordHasher> = Arc::new(BcryptPasswordHasher::new());
    let email_service: Arc<dyn EmailService> = Arc::new(SendGridEmailService::new(&config.sendgrid_key));

    // Wire application services
    let auth_service: Arc<dyn SignInPort> = Arc::new(AuthService::new(
        Arc::clone(&user_repo),
        Arc::clone(&password_hasher),
    ));

    // Wire inbound adapters
    let auth_handler = AuthGrpcHandler::new(Arc::clone(&auth_service));

    tonic::transport::Server::builder()
        .add_service(AuthServiceServer::new(auth_handler))
        .serve(config.grpc_address.parse()?)
        .await?;

    Ok(())
}
```

---

## Rules

- **Domain crate has zero external dependencies**: no tokio, sqlx, tonic, reqwest — only `std`, `thiserror`, `serde`, `uuid`, `chrono`
- **Ports are traits only**: no implementations in the ports module
- **All wiring happens in `infrastructure/`**: application and domain never construct their own adapters
- **`pub(crate)` by default**: only expose across crate boundaries what is genuinely needed
- **Application services take `Arc<dyn Trait>`**: never concrete adapter types
- **Inbound adapters call application ports, not domain directly**: the gRPC handler calls `SignInPort`, not `User::authenticate()`
- **Domain events are emitted from domain methods**: services collect and publish them
- **No `async_trait` in domain when avoidable**: prefer sync domain logic, push async to application layer
