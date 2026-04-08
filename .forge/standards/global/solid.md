# SOLID Principles

SOLID is not a checklist — it is a design compass. Apply it when complexity warrants abstraction. Never apply it to produce ceremony without benefit.

---

## S — Single Responsibility Principle

**A class should have one reason to change.**

In Flutter, responsibilities are clearly separated:
- **BLoC**: Manages state and processes events. No UI. No data access.
- **Repository**: Fetches and persists data. No state management. No UI.
- **Use Case**: Orchestrates domain objects for one business operation. No UI. No direct data access.
- **Widget**: Displays data and captures user input. No business logic. No data access.

**Dart — Violation:**
```dart
// WRONG — widget does too many things
class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    // Fetching data directly in the widget — WRONG
    DioClient.instance.get('/products').then((response) {
      final products = (response.data as List)
          .map((json) => Product.fromJson(json))
          .toList();
      setState(() => _products = products);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (_, index) => ProductTile(product: _products[index]),
    );
  }
}
```

**Dart — Correct:**
```dart
// ProductRepository — fetches data
abstract interface class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
}

// GetProductsUseCase — orchestrates
@injectable
class GetProductsUseCase {
  final ProductRepository _repository;
  const GetProductsUseCase(this._repository);
  Future<Either<Failure, List<Product>>> call() => _repository.getProducts();
}

// ProductBloc — manages state
@injectable
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase _getProducts;

  ProductBloc({required GetProductsUseCase getProducts})
      : _getProducts = getProducts,
        super(const ProductState.initial()) {
    on<ProductsRequested>(_onProductsRequested);
  }

  Future<void> _onProductsRequested(
    ProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductState.loading());
    final result = await _getProducts();
    result.fold(
      (failure) => emit(ProductState.error(failure)),
      (products) => emit(ProductState.loaded(products)),
    );
  }
}

// ProductListPage — displays only
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) => state.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const LoadingIndicator(),
        loaded: (products) => ProductListView(products: products),
        error: (failure) => ErrorView(failure: failure),
      ),
    );
  }
}
```

**Rust — SRP:**
```rust
// Each struct has one job

// Repository trait — data access only
#[async_trait]
pub trait ProductRepository: Send + Sync {
    async fn find_all(&self) -> Result<Vec<Product>, DomainError>;
    async fn find_by_id(&self, id: &ProductId) -> Result<Option<Product>, DomainError>;
    async fn save(&self, product: Product) -> Result<Product, DomainError>;
}

// Service — orchestration only
pub struct GetProductsService {
    repository: Arc<dyn ProductRepository>,
}

impl GetProductsService {
    pub fn new(repository: Arc<dyn ProductRepository>) -> Self {
        Self { repository }
    }

    pub async fn execute(&self) -> Result<Vec<Product>, DomainError> {
        self.repository.find_all().await
    }
}

// gRPC Handler — transport only
pub struct ProductGrpcHandler {
    get_products: Arc<GetProductsService>,
}
```

---

## O — Open/Closed Principle

**Open for extension, closed for modification.**

New behavior is added by extending through abstractions, not by modifying existing code.

**Dart — Violation:**
```dart
// WRONG — adding a new payment method requires modifying this class
class PaymentProcessor {
  Future<void> process(Payment payment) async {
    if (payment.method == 'stripe') {
      await StripeClient.charge(payment);
    } else if (payment.method == 'paypal') {
      await PayPalClient.charge(payment);
    }
    // Every new payment method requires touching this file
  }
}
```

**Dart — Correct:**
```dart
// Define the abstraction
abstract interface class PaymentGateway {
  Future<Either<PaymentFailure, PaymentReceipt>> charge(Payment payment);
}

// Implementations — extend without modifying PaymentGateway
@injectable
@Named('stripe')
class StripeGateway implements PaymentGateway {
  @override
  Future<Either<PaymentFailure, PaymentReceipt>> charge(Payment payment) async {
    // Stripe-specific logic
  }
}

@injectable
@Named('paypal')
class PayPalGateway implements PaymentGateway {
  @override
  Future<Either<PaymentFailure, PaymentReceipt>> charge(Payment payment) async {
    // PayPal-specific logic
  }
}

// The use case never changes when a new gateway is added
@injectable
class ProcessPaymentUseCase {
  final PaymentGateway _gateway; // receives the right implementation via DI

  const ProcessPaymentUseCase(this._gateway);
}
```

**Rust — Correct:**
```rust
#[async_trait]
pub trait PaymentGateway: Send + Sync {
    async fn charge(&self, payment: &Payment) -> Result<PaymentReceipt, PaymentError>;
}

// New payment providers are added as new structs, existing code unchanged
pub struct StripeGateway { api_key: String }
pub struct PayPalGateway { client_id: String, secret: String }
pub struct ApplePayGateway { merchant_id: String }

#[async_trait]
impl PaymentGateway for StripeGateway { /* ... */ }
#[async_trait]
impl PaymentGateway for PayPalGateway { /* ... */ }
#[async_trait]
impl PaymentGateway for ApplePayGateway { /* ... */ }
```

---

## L — Liskov Substitution Principle

**Subtypes must be substitutable for their base types.**

Any implementation of an interface must honor the full contract: preconditions, postconditions, and invariants.

**Dart — Violation:**
```dart
abstract interface class UserRepository {
  Future<User> findById(String id);
  // Contract: returns the user or throws UserNotFoundException
}

// WRONG — this implementation violates the contract
class CachedUserRepository implements UserRepository {
  @override
  Future<User> findById(String id) async {
    // Returns null instead of throwing — breaks contract
    return cache[id]; // null if not found — caller expects User or exception
  }
}
```

**Dart — Correct:**
```dart
class CachedUserRepository implements UserRepository {
  @override
  Future<User> findById(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;

    final user = await _remoteSource.findById(id);
    // Honors contract: throws UserNotFoundException if not found
    _cache[id] = user;
    return user;
  }
}
```

**Rust — LSP through traits:**
```rust
// The trait defines the contract
#[async_trait]
pub trait Cache<K, V>: Send + Sync {
    /// Returns the value if found. Never panics.
    async fn get(&self, key: &K) -> Option<V>;
    /// Stores the value. Returns error only on storage failure.
    async fn set(&self, key: K, value: V) -> Result<(), CacheError>;
}

// All implementations must honor: get returns None (not panics) when missing
pub struct RedisCache { /* ... */ }
pub struct InMemoryCache { /* ... */ }
pub struct NoOpCache;  // useful in tests, still honors contract

#[async_trait]
impl<K, V> Cache<K, V> for NoOpCache
where K: Send + Sync, V: Send + Sync
{
    async fn get(&self, _key: &K) -> Option<V> { None }
    async fn set(&self, _key: K, _value: V) -> Result<(), CacheError> { Ok(()) }
}
```

---

## I — Interface Segregation Principle

**Clients should not be forced to depend on interfaces they do not use.**

Keep interfaces small and focused. A read-only use case should not depend on a write interface.

**Dart — Violation:**
```dart
// WRONG — one fat interface
abstract interface class UserRepository {
  Future<User> findById(String id);
  Future<List<User>> findAll();
  Future<User> save(User user);
  Future<void> delete(String id);
  Future<void> updatePassword(String id, String hash);
  Future<void> sendVerificationEmail(String id); // Not a repository concern!
  Future<List<AuditLog>> getAuditLogs(String id); // Not a repository concern!
}
```

**Dart — Correct:**
```dart
abstract interface class UserReadRepository {
  Future<Either<Failure, User>> findById(UserId id);
  Future<Either<Failure, List<User>>> findAll();
}

abstract interface class UserWriteRepository {
  Future<Either<Failure, User>> save(User user);
  Future<Either<Failure, Unit>> delete(UserId id);
}

abstract interface class UserAuthRepository {
  Future<Either<Failure, Unit>> updatePasswordHash(UserId id, PasswordHash hash);
}

// Use cases depend only on what they need
@injectable
class GetUserUseCase {
  final UserReadRepository _repository; // Only read — no write dependency
  const GetUserUseCase(this._repository);
}
```

**Rust — Correct:**
```rust
#[async_trait]
pub trait ReadOrderPort: Send + Sync {
    async fn find_by_id(&self, id: &OrderId) -> Result<Option<Order>, DomainError>;
    async fn find_by_customer(&self, customer_id: &CustomerId) -> Result<Vec<Order>, DomainError>;
}

#[async_trait]
pub trait WriteOrderPort: Send + Sync {
    async fn save(&self, order: Order) -> Result<Order, DomainError>;
    async fn delete(&self, id: &OrderId) -> Result<(), DomainError>;
}

// Query service needs only read
pub struct GetOrderService {
    repository: Arc<dyn ReadOrderPort>,
}

// Command service needs only write
pub struct CreateOrderService {
    repository: Arc<dyn WriteOrderPort>,
}
```

---

## D — Dependency Inversion Principle

**High-level modules should not depend on low-level modules. Both should depend on abstractions.**

The domain layer defines interfaces. The data layer implements them. Dependency injection wires them together.

**Dart — Violation:**
```dart
// WRONG — use case directly depends on concrete implementation
class GetOrderUseCase {
  final OrderRepositoryImpl _repository; // Concrete! Wrong!

  GetOrderUseCase() : _repository = OrderRepositoryImpl(
    DioClient(), HiveBox('orders'),  // Constructing infrastructure here
  );
}
```

**Dart — Correct:**
```dart
// Domain defines the interface
abstract interface class OrderRepository {
  Future<Either<Failure, Order>> findById(OrderId id);
}

// Use case depends on abstraction
@injectable
class GetOrderUseCase {
  final OrderRepository _repository;
  const GetOrderUseCase(this._repository); // Injected — no concrete type known
}

// Data layer implements the interface
@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remote;
  final OrderLocalDataSource _local;

  const OrderRepositoryImpl({
    required OrderRemoteDataSource remote,
    required OrderLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<Either<Failure, Order>> findById(OrderId id) async { /* ... */ }
}

// DI wires everything in injection.dart — nothing else knows about it
```

**Rust — Correct:**
```rust
// Domain defines the port (abstraction)
#[async_trait]
pub trait OrderRepository: Send + Sync {
    async fn find_by_id(&self, id: &OrderId) -> Result<Option<Order>, DomainError>;
}

// Application service depends on abstraction
pub struct GetOrderService {
    repository: Arc<dyn OrderRepository>,  // trait object, not concrete type
}

impl GetOrderService {
    pub fn new(repository: Arc<dyn OrderRepository>) -> Self {
        Self { repository }
    }
}

// Infrastructure wires it together (main.rs / infrastructure/server.rs)
let pool = PgPool::connect(&config.database_url).await?;
let order_repository = Arc::new(PostgresOrderRepository::new(pool.clone()));
let get_order_service = Arc::new(GetOrderService::new(order_repository));
```
