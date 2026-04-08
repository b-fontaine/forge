# Rust Testing Standard

## Testing Pyramid

| Layer | Mechanism | Location |
|---|---|---|
| Unit | `#[cfg(test)]` in-module | `src/**/*.rs` |
| Integration | Separate test crate | `tests/` |
| BDD | `cucumber-rs` | `tests/bdd/` |
| Property-based | `proptest` | Unit or integration |

---

## Unit Tests

Unit tests live in the same file as the code they test, inside a `#[cfg(test)]` module.

```rust
// src/domain/value_objects/email.rs
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Email(String);

impl Email {
    pub fn new(value: impl Into<String>) -> Result<Self, DomainError> {
        let value = value.into();
        if value.contains('@') && value.len() > 3 {
            Ok(Self(value))
        } else {
            Err(DomainError::InvalidEmail { value })
        }
    }

    pub fn as_str(&self) -> &str { &self.0 }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn valid_email_is_accepted() {
        let email = Email::new("user@example.com").unwrap();
        assert_eq!(email.as_str(), "user@example.com");
    }

    #[test]
    fn email_without_at_is_rejected() {
        let result = Email::new("not-an-email");
        assert!(matches!(result, Err(DomainError::InvalidEmail { .. })));
    }

    #[test]
    fn email_is_case_sensitive() {
        let a = Email::new("User@Example.com").unwrap();
        let b = Email::new("user@example.com").unwrap();
        assert_ne!(a, b);
    }

    #[tokio::test]
    async fn async_domain_method_works() {
        // Use tokio::test for async unit tests
        let result = async_validate("user@example.com").await;
        assert!(result.is_ok());
    }
}
```

---

## Integration Tests

Integration tests live in `tests/` and test the system through its public API.

```
tests/
├── auth/
│   ├── mod.rs
│   └── sign_in_test.rs
├── orders/
│   └── place_order_test.rs
└── common/
    ├── mod.rs
    └── test_app.rs   ← shared test setup
```

```rust
// tests/common/test_app.rs
use sqlx::PgPool;
use uuid::Uuid;

pub struct TestApp {
    pub pool: PgPool,
    pub user_repo: PostgresUserRepository,
    pub auth_service: AuthService,
}

impl TestApp {
    pub async fn new() -> Self {
        let database_url = std::env::var("TEST_DATABASE_URL")
            .unwrap_or_else(|_| "postgres://postgres:postgres@localhost:5432/test".into());

        let pool = PgPool::connect(&database_url).await.expect("Failed to connect to test DB");
        sqlx::migrate!("./migrations").run(&pool).await.expect("Migrations failed");

        let user_repo = PostgresUserRepository::new(pool.clone());
        let password_hasher = BcryptPasswordHasher::new();
        let auth_service = AuthService::new(Arc::new(user_repo.clone()), Arc::new(password_hasher));

        Self { pool, user_repo, auth_service }
    }

    pub async fn create_user(&self) -> User {
        let user = User::new(
            UserId::new(),
            Email::new("test@example.com").unwrap(),
            "Test User".to_string(),
        );
        self.user_repo.save(&user).await.unwrap();
        user
    }

    pub async fn cleanup(&self) {
        sqlx::query("TRUNCATE users, orders RESTART IDENTITY CASCADE")
            .execute(&self.pool)
            .await
            .unwrap();
    }
}
```

```rust
// tests/auth/sign_in_test.rs
mod common;
use common::TestApp;

#[tokio::test]
async fn sign_in_with_valid_credentials_returns_token() {
    let app = TestApp::new().await;
    let user = app.create_user().await;

    let token = app.auth_service.sign_in("test@example.com", "password").await;

    assert!(token.is_ok());
    app.cleanup().await;
}

#[tokio::test]
async fn sign_in_with_wrong_password_returns_error() {
    let app = TestApp::new().await;
    app.create_user().await;

    let result = app.auth_service.sign_in("test@example.com", "wrong").await;

    assert!(matches!(result.unwrap_err().downcast::<DomainError>().unwrap(), DomainError::InvalidCredentials));
    app.cleanup().await;
}
```

---

## Mocking with mockall

```rust
use mockall::{automock, predicate::*};

#[automock]
#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_email(&self, email: &Email) -> Result<Option<User>, DomainError>;
    async fn save(&self, user: &User) -> Result<(), DomainError>;
}

#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::eq;

    #[tokio::test]
    async fn auth_service_returns_user_on_valid_credentials() {
        let expected_user = make_test_user();
        let mut mock_repo = MockUserRepository::new();

        mock_repo
            .expect_find_by_email()
            .with(eq(Email::new("user@example.com").unwrap()))
            .times(1)
            .returning(move |_| Ok(Some(expected_user.clone())));

        let service = AuthService::new(Arc::new(mock_repo), Arc::new(FakePasswordHasher::correct()));
        let result = service.sign_in("user@example.com", "correct").await;

        assert!(result.is_ok());
    }
}
```

---

## BDD with cucumber-rs

```
tests/bdd/
├── features/
│   └── auth/
│       └── sign_in.feature
├── steps/
│   └── auth_steps.rs
└── world.rs
```

```gherkin
# tests/bdd/features/auth/sign_in.feature
Feature: Sign In

  Scenario: Successful sign in
    Given a user exists with email "user@example.com" and password "secret"
    When they sign in with email "user@example.com" and password "secret"
    Then they receive a valid auth token

  Scenario: Failed sign in with wrong password
    Given a user exists with email "user@example.com" and password "secret"
    When they sign in with email "user@example.com" and password "wrong"
    Then sign in fails with InvalidCredentials
```

```rust
// tests/bdd/world.rs
use cucumber::World;

#[derive(Debug, World)]
pub struct AuthWorld {
    pub app: Option<TestApp>,
    pub sign_in_result: Option<anyhow::Result<AuthToken>>,
}

impl Default for AuthWorld {
    fn default() -> Self {
        Self { app: None, sign_in_result: None }
    }
}
```

```rust
// tests/bdd/steps/auth_steps.rs
use cucumber::{given, then, when};
use super::world::AuthWorld;

#[given(expr = "a user exists with email {string} and password {string}")]
async fn user_exists(world: &mut AuthWorld, email: String, password: String) {
    let app = TestApp::new().await;
    app.create_user_with_credentials(&email, &password).await;
    world.app = Some(app);
}

#[when(expr = "they sign in with email {string} and password {string}")]
async fn sign_in(world: &mut AuthWorld, email: String, password: String) {
    let app = world.app.as_ref().expect("app not initialized");
    world.sign_in_result = Some(app.auth_service.sign_in(&email, &password).await);
}

#[then("they receive a valid auth token")]
async fn valid_token(world: &mut AuthWorld) {
    let result = world.sign_in_result.as_ref().expect("no result");
    assert!(result.is_ok(), "expected Ok but got: {:?}", result);
}

#[then("sign in fails with InvalidCredentials")]
async fn invalid_credentials(world: &mut AuthWorld) {
    let result = world.sign_in_result.as_ref().expect("no result");
    let err = result.as_ref().unwrap_err();
    let domain_err = err.downcast_ref::<DomainError>().expect("expected DomainError");
    assert!(matches!(domain_err, DomainError::InvalidCredentials));
}
```

```rust
// tests/bdd/main.rs
mod steps;
mod world;

use world::AuthWorld;

#[tokio::main]
async fn main() {
    AuthWorld::run("tests/bdd/features").await;
}
```

```toml
# Cargo.toml
[[test]]
name = "bdd"
harness = false
```

---

## Property-Based Testing with proptest

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn email_round_trips_through_serialization(
        local in "[a-z]{1,20}",
        domain in "[a-z]{2,10}",
        tld in "[a-z]{2,4}",
    ) {
        let raw = format!("{local}@{domain}.{tld}");
        let email = Email::new(&raw).unwrap();
        let serialized = serde_json::to_string(&email).unwrap();
        let deserialized: Email = serde_json::from_str(&serialized).unwrap();
        prop_assert_eq!(email, deserialized);
    }

    #[test]
    fn money_addition_is_commutative(a in 0i64..1_000_000, b in 0i64..1_000_000) {
        let m1 = Money::new(a);
        let m2 = Money::new(b);
        prop_assert_eq!(m1.add(&m2), m2.add(&m1));
    }

    #[test]
    fn transfer_never_creates_money(
        balance in 1i64..10_000,
        transfer in 1i64..5_000,
    ) {
        let account = Account::new_with_balance(balance);
        let result = account.debit(transfer);
        match result {
            Ok(updated) => prop_assert!(updated.balance() + transfer == balance),
            Err(_) => prop_assert!(transfer > balance),
        }
    }
}
```

---

## Rules

- **`cargo test` produces zero warnings**: treat warnings as errors in CI with `RUSTFLAGS="-D warnings"`
- **No `#[ignore]` without a linked issue**: `// TODO(#123): re-enable when X is fixed`
- **Test private behavior through the public API**: do not `pub` items only to test them
- **Mock traits with `mockall`**: never create hand-written mocks unless `mockall` cannot cover the case
- **Integration tests use a dedicated test database**: set `TEST_DATABASE_URL` in CI
- **BDD feature files are the acceptance criteria**: written with the domain expert, not after the fact
- **Property tests run 256 cases by default**: increase with `ProptestConfig::with_cases(1000)` for critical invariants
- **Test helpers live in `tests/common/`**: never duplicate setup code across test files
- **Each test cleans up its own data**: use `cleanup()` in teardown or run each test in a transaction
