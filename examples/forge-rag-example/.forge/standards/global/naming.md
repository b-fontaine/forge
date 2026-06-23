# Naming Conventions

Good names communicate intent. A name that requires a comment to explain it is a bad name. Names are the most read thing in code — spend the time to get them right.

---

## Dart / Flutter

### Files

All Dart files use `snake_case`.

```
# Correct
sign_in_page.dart
auth_bloc.dart
user_repository.dart
email_value_object.dart
product_tile.dart
app_router.dart
di_module.dart

# Wrong
SignInPage.dart
authBloc.dart
UserRepository.dart
```

### Classes

All Dart classes, enums, and type aliases use `PascalCase`.

```dart
// Entities
class User { }
class OrderItem { }

// Value Objects — name the concept, not that it's a VO
class Email { }
class PhoneNumber { }
class Money { }

// Repositories — interface name is the concept
abstract interface class AuthRepository { }
abstract interface class OrderRepository { }

// Implementations — suffix Impl
class AuthRepositoryImpl implements AuthRepository { }

// Use Cases — verb + noun + UseCase
class SignInUseCase { }
class CreateOrderUseCase { }
class GetUserProfileUseCase { }

// Do NOT use: CreateOrderInteractor, OrderCreator, OrderCreationHandler (pick one style)
```

### BLoC Naming

```dart
// BLoC class — noun + Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> { }
class ProductBloc extends Bloc<ProductEvent, ProductState> { }
class CartBloc extends Bloc<CartEvent, CartState> { }

// Cubit — noun + Cubit (only when no events needed)
class ThemeCubit extends Cubit<ThemeState> { }
class LocaleCubit extends Cubit<LocaleState> { }

// Events — past tense (things that happened / were requested)
// Pattern: NounVerbPast or NounActionRequested
abstract class AuthEvent { }
class SignInRequested extends AuthEvent { }
class SignOutRequested extends AuthEvent { }
class AuthTokenRefreshed extends AuthEvent { }

// NOT: AuthSignIn, AuthDoSignIn, OnSignIn

// States — sealed classes with descriptive constructors
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.authenticated({required User user}) = AuthStateAuthenticated;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  const factory AuthState.error({required String message}) = AuthStateError;
}
```

### Variables and Functions

All variables, function parameters, and local functions use `camelCase`.

```dart
// Variables
final currentUser = await repository.getCurrentUser();
final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);
int itemCount = 0;

// Private fields — prefix underscore
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase _getProducts;
  final CreateOrderUseCase _createOrder;
}

// Functions / methods — verb first
Future<void> loadProducts() async { }
Either<Failure, User> validateCredentials(String email, String password) { }
bool isEmailValid(String email) { }

// Booleans — is/has/can/should prefix
bool isLoggedIn = false;
bool hasItems = cart.items.isNotEmpty;
bool canCheckout = cart.total > Money.zero();
bool shouldRefresh = token.isExpired;
```

### Constants

```dart
// Top-level constants — camelCase in Dart (exception to the "all-caps" rule)
const double kAnimationDuration = 300.0;
const int kMaxRetries = 3;
const String kAuthTokenKey = 'auth_token';

// Enum values — camelCase
enum UserStatus {
  active,
  inactive,
  suspended,
  pendingVerification,
}
```

### Widget Keys

Keys embedded in widgets use consistent, descriptive names:

```dart
// Pattern: featureName_widgetType
const Key('signIn_emailField')
const Key('signIn_passwordField')
const Key('signIn_submitButton')
const Key('productList_emptyState')
const Key('cart_checkoutButton')
```

---

## Rust

### Files and Modules

All Rust files and module names use `snake_case`.

```
src/
  domain/
    entities/
      user.rs
      order.rs
      order_item.rs
    value_objects/
      email.rs
      money.rs
      phone_number.rs
    ports/
      inbound/
        create_order_port.rs
      outbound/
        order_repository.rs
  application/
    services/
      create_order_service.rs
      get_order_service.rs
```

### Types

All types (structs, enums, traits, type aliases) use `PascalCase`.

```rust
// Entities
pub struct User { }
pub struct Order { }
pub struct OrderItem { }

// Value Objects
pub struct Email(String);
pub struct Money { amount: Decimal, currency: Currency }
pub struct OrderId(Uuid);

// Traits (ports)
pub trait OrderRepository { }
pub trait EventPublisher { }
pub trait PaymentGateway { }

// Enums
pub enum OrderStatus {
    Pending,
    Confirmed,
    Shipped,
    Delivered,
    Cancelled,
}

pub enum DomainError {
    NotFound(String),
    InvalidInput(String),
    Unauthorized,
    Conflict(String),
}
```

### Functions and Methods

All functions and methods use `snake_case`.

```rust
// Functions
pub fn create_order(command: CreateOrderCommand) -> Result<Order, DomainError> { }
pub async fn find_by_id(id: &OrderId) -> Result<Option<Order>, DomainError> { }
pub fn is_valid_email(email: &str) -> bool { }

// Builder methods — conventional patterns
pub fn new(/* required args */) -> Self { }
pub fn builder() -> OrderBuilder { }
pub fn with_item(mut self, item: OrderItem) -> Self { self.items.push(item); self }

// Getters — no get_ prefix in Rust (idiomatic)
pub fn id(&self) -> &OrderId { &self.id }
pub fn status(&self) -> &OrderStatus { &self.status }
pub fn total(&self) -> &Money { &self.total }

// Booleans — is_/has_/can_ prefix
pub fn is_empty(&self) -> bool { self.items.is_empty() }
pub fn has_pending_items(&self) -> bool { self.items.iter().any(|i| i.is_pending()) }
pub fn can_be_cancelled(&self) -> bool { self.status == OrderStatus::Pending }
```

### Constants

```rust
// Constants — SCREAMING_SNAKE_CASE
const MAX_ORDER_ITEMS: usize = 100;
const MIN_ORDER_AMOUNT_CENTS: i64 = 100;
const DEFAULT_PAGE_SIZE: u32 = 20;
const AUTH_TOKEN_EXPIRY_SECS: u64 = 3600;

// Static strings
const HEADER_AUTHORIZATION: &str = "Authorization";
const QUEUE_NAME_ORDERS: &str = "orders.created";
```

### Error Variants

```rust
// thiserror errors — PascalCase variants, descriptive messages
#[derive(Debug, thiserror::Error)]
pub enum DomainError {
    #[error("Order {0} not found")]
    OrderNotFound(OrderId),

    #[error("Insufficient stock for product {product_id}: requested {requested}, available {available}")]
    InsufficientStock {
        product_id: ProductId,
        requested: u32,
        available: u32,
    },

    #[error("Order cannot be modified in status {0:?}")]
    InvalidStatusTransition(OrderStatus),
}
```

---

## BDD Naming

### Feature Files

Feature files are named after the feature in `snake_case`:

```
test/features/
  auth/
    sign_in.feature
    sign_up.feature
    password_reset.feature
  cart/
    add_to_cart.feature
    remove_from_cart.feature
    checkout.feature
  order/
    create_order.feature
    cancel_order.feature
    track_order.feature
```

### Scenario Names

Scenarios are named in plain English, describing behavior from the user's perspective. Use the format: **[context/actor] [action] [outcome]**.

```gherkin
# Good scenario names
Scenario: Authenticated user signs out successfully
Scenario: Guest user is redirected to sign in when accessing dashboard
Scenario: Order is confirmed when payment succeeds
Scenario: Cart total updates when item quantity changes
Scenario: Sign in fails when email is not registered

# Bad scenario names
Scenario: Test sign in
Scenario: Auth flow
Scenario: Happy path
Scenario: Sad path
```

---

## Git

### Branches

Format: `type/short-description`

```
feat/user-authentication
feat/product-search
fix/cart-total-calculation
fix/auth-token-refresh
refactor/order-domain-cleanup
chore/upgrade-flutter-3-19
docs/api-authentication
test/order-integration-tests
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style`

### Conventional Commits

Format: `type(scope): description`

```
feat(auth): add sign in with Apple
fix(cart): correct total calculation when discount applied
refactor(order): extract OrderItem into separate entity
test(auth): add BDD scenarios for password reset
docs(api): document authentication endpoints
chore(deps): upgrade flutter to 3.19.0
perf(products): add pagination to product list query
style(lint): fix analysis warnings in auth feature
```

Rules:
- **type**: lowercase, from the list above
- **scope**: optional, the feature or module affected, in parentheses
- **description**: lowercase, imperative mood ("add" not "added" or "adding"), no period
- **body**: optional, separated by blank line, explains WHY (not what)
- **breaking change**: `feat!:` or `BREAKING CHANGE:` in footer

```
feat(order)!: change order ID from int to UUID

BREAKING CHANGE: OrderId is now a UUID string instead of an integer.
All API consumers must update their order ID handling.

Closes FORGE-142
```

### Forge Task References

When working within Forge, commits reference the task ID:

```
feat(auth): implement biometric sign in

Implements FORGE-89. Adds FaceID/TouchID support using
local_auth package. Falls back to PIN on unsupported devices.
```
