# DDD Rules

## Why DDD

Domain-Driven Design is not about folder structure. It is a way of building software where the code reflects the business domain so accurately that business experts and engineers can talk using the same words. The model is the code. The code is the model.

Applied correctly, DDD produces systems where:
- Business rules live in the domain, not in controllers or repositories
- Changes to requirements map naturally to changes in code
- The domain is independently testable with zero infrastructure
- Engineers can reason about business rules without reading database schemas

---

## Strategic Design

### Bounded Contexts

A Bounded Context is an explicit boundary within which a Domain Model is defined and applicable. The same word can mean different things in different contexts — and that is correct.

```
[Catalog Context]          [Order Context]           [Shipping Context]
   Product                    Product (stub)            Package
   Category                   Order                     Shipment
   Price                      OrderItem                 Carrier
   Inventory                  Customer (ref)            TrackingNumber
```

- Each bounded context has its own codebase / module / package.
- Cross-context communication happens through well-defined interfaces (APIs, events), never through shared domain models.
- A context owns its data. No other context writes to it directly.

### Ubiquitous Language

The language of the business IS the language of the code. No translation layer.

```
# WRONG — technical language that hides intent
user_record.status = 2
save_to_db(user_record)

# RIGHT — domain language that reveals intent
customer.activate()
customer_repository.save(customer)
```

Rules:
- Terms come from conversations with domain experts, not from the engineer's preferences.
- Every team member uses the same terms: product manager, designer, engineer, QA.
- The glossary lives in the repository (`docs/ubiquitous-language.md`).
- Rename code when the business renames a concept.

### Context Map

Document how bounded contexts relate to each other:

- **Partnership**: Two contexts evolve together, teams coordinate.
- **Shared Kernel**: A small shared model both contexts depend on. Change by mutual consent only.
- **Customer/Supplier**: Downstream context depends on upstream. Upstream team provides stable API.
- **Conformist**: Downstream adapts to upstream model without negotiation power.
- **Anti-Corruption Layer (ACL)**: Downstream translates upstream model to its own, protecting the domain.
- **Open Host Service**: Upstream publishes a well-defined protocol (REST API, gRPC).
- **Published Language**: A shared formal language (protobuf, JSON schema).

---

## Tactical Patterns

### Entity

An object with a unique identity that persists over time. Two entities with the same identity are the same entity, regardless of attribute values.

**Dart:**
```dart
// lib/features/auth/domain/entities/user.dart

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final UserId id;
  final Email email;
  final UserName name;
  final UserStatus status;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.status,
  });

  // Identity is the id — other fields can change
  @override
  List<Object?> get props => [id];

  // Domain behavior lives here, not in a service
  User activate() {
    if (status == UserStatus.active) {
      throw DomainException('User is already active');
    }
    return User(id: id, email: email, name: name, status: UserStatus.active);
  }

  User deactivate() => User(
    id: id, email: email, name: name, status: UserStatus.inactive,
  );
}
```

**Rust:**
```rust
// src/domain/entities/user.rs

use std::hash::{Hash, Hasher};

#[derive(Debug, Clone)]
pub struct User {
    id: UserId,
    email: Email,
    name: UserName,
    status: UserStatus,
}

// Entity equality is identity-based
impl PartialEq for User {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Eq for User {}

impl Hash for User {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.id.hash(state);
    }
}

impl User {
    pub fn activate(&self) -> Result<User, DomainError> {
        if self.status == UserStatus::Active {
            return Err(DomainError::AlreadyActive);
        }
        Ok(User {
            status: UserStatus::Active,
            ..self.clone()
        })
    }

    pub fn id(&self) -> &UserId { &self.id }
    pub fn email(&self) -> &Email { &self.email }
    pub fn status(&self) -> &UserStatus { &self.status }
}
```

### Value Object

An immutable object defined entirely by its attributes. Two value objects with the same attributes are identical. No identity.

**Dart (with freezed):**
```dart
// lib/features/auth/domain/value_objects/email.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'email.freezed.dart';

@freezed
class Email with _$Email {
  const Email._();

  const factory Email._(String value) = _Email;

  static Either<ValidationFailure, Email> create(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (!_emailRegex.hasMatch(normalized)) {
      return Left(ValidationFailure.invalidEmail(raw));
    }
    return Right(Email._(normalized));
  }

  static final _emailRegex = RegExp(r'^[\w\-\.]+@[\w\-\.]+\.\w{2,}$');
}
```

**Rust:**
```rust
// src/domain/value_objects/email.rs

use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Email(String);

impl Email {
    pub fn new(raw: &str) -> Result<Self, DomainError> {
        let normalized = raw.trim().to_lowercase();
        if !Self::is_valid(&normalized) {
            return Err(DomainError::InvalidEmail(raw.to_string()));
        }
        Ok(Email(normalized))
    }

    fn is_valid(email: &str) -> bool {
        let parts: Vec<&str> = email.split('@').collect();
        parts.len() == 2 && !parts[0].is_empty() && parts[1].contains('.')
    }

    pub fn value(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for Email {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
```

### Aggregate

A cluster of domain objects treated as a single unit. The Aggregate Root is the only entry point for all operations on the cluster.

Rules:
- Only the root has a global identity.
- External objects hold references to the root, never to internal entities.
- All invariants are enforced by the root.
- One transaction = one aggregate.

**Dart:**
```dart
// lib/features/order/domain/entities/order.dart

class Order extends Equatable {
  final OrderId id;
  final CustomerId customerId;
  final List<OrderItem> _items; // Encapsulated — no direct access
  final OrderStatus status;
  final Money total;

  const Order._({
    required this.id,
    required this.customerId,
    required List<OrderItem> items,
    required this.status,
    required this.total,
  }) : _items = items;

  factory Order.create({
    required OrderId id,
    required CustomerId customerId,
    required List<OrderItem> items,
  }) {
    if (items.isEmpty) throw DomainException('Order must have at least one item');

    final total = items.fold(
      Money.zero(),
      (acc, item) => acc + item.subtotal,
    );

    return Order._(
      id: id,
      customerId: customerId,
      items: List.unmodifiable(items),
      status: OrderStatus.pending,
      total: total,
    );
  }

  List<OrderItem> get items => List.unmodifiable(_items);

  Order confirm() {
    if (status != OrderStatus.pending) {
      throw DomainException('Only pending orders can be confirmed');
    }
    return Order._(
      id: id, customerId: customerId, items: _items,
      status: OrderStatus.confirmed, total: total,
    );
  }

  @override
  List<Object?> get props => [id];
}
```

### Repository Interface

The repository is defined in the domain. Its implementation lives in the data layer. The domain never imports infrastructure.

**Dart:**
```dart
// lib/features/order/domain/repositories/order_repository.dart

import 'package:fpdart/fpdart.dart';

abstract interface class OrderRepository {
  Future<Either<Failure, Order>> findById(OrderId id);
  Future<Either<Failure, List<Order>>> findByCustomer(CustomerId customerId);
  Future<Either<Failure, Order>> save(Order order);
  Future<Either<Failure, Unit>> delete(OrderId id);
}
```

**Rust:**
```rust
// src/domain/ports/outbound/order_repository.rs

use async_trait::async_trait;

#[async_trait]
pub trait OrderRepository: Send + Sync {
    async fn find_by_id(&self, id: &OrderId) -> Result<Option<Order>, DomainError>;
    async fn find_by_customer(&self, customer_id: &CustomerId) -> Result<Vec<Order>, DomainError>;
    async fn save(&self, order: Order) -> Result<Order, DomainError>;
    async fn delete(&self, id: &OrderId) -> Result<(), DomainError>;
}
```

### Domain Events

Domain Events capture something that happened in the domain. They are facts, not commands. Named in past tense.

**Dart:**
```dart
// lib/features/order/domain/events/order_confirmed.dart

abstract class DomainEvent {
  final DateTime occurredAt;
  const DomainEvent({required this.occurredAt});
}

class OrderConfirmed extends DomainEvent {
  final OrderId orderId;
  final CustomerId customerId;
  final Money total;

  const OrderConfirmed({
    required this.orderId,
    required this.customerId,
    required this.total,
    required super.occurredAt,
  });
}
```

**Rust:**
```rust
// src/domain/events/order_confirmed.rs

use chrono::{DateTime, Utc};

#[derive(Debug, Clone)]
pub enum DomainEvent {
    OrderConfirmed(OrderConfirmed),
    OrderCancelled(OrderCancelled),
    UserActivated(UserActivated),
}

#[derive(Debug, Clone)]
pub struct OrderConfirmed {
    pub order_id: OrderId,
    pub customer_id: CustomerId,
    pub total: Money,
    pub occurred_at: DateTime<Utc>,
}
```

### Use Cases

Use Cases (Application Services) orchestrate domain objects to fulfill a business requirement. They do not contain domain logic — they delegate to entities and domain services.

**Dart:**
```dart
// lib/features/order/domain/usecases/confirm_order.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class ConfirmOrderUseCase {
  final OrderRepository _orderRepository;
  final DomainEventBus _eventBus;

  const ConfirmOrderUseCase({
    required OrderRepository orderRepository,
    required DomainEventBus eventBus,
  })  : _orderRepository = orderRepository,
        _eventBus = eventBus;

  Future<Either<Failure, Order>> call(ConfirmOrderParams params) async {
    // 1. Load the aggregate
    final orderResult = await _orderRepository.findById(params.orderId);

    return orderResult.flatMap((order) async {
      // 2. Execute domain logic (on the entity, not here)
      final confirmedOrder = order.confirm();

      // 3. Persist
      final savedResult = await _orderRepository.save(confirmedOrder);

      // 4. Emit domain events
      await _eventBus.publish(OrderConfirmed(
        orderId: confirmedOrder.id,
        customerId: confirmedOrder.customerId,
        total: confirmedOrder.total,
        occurredAt: DateTime.now(),
      ));

      return savedResult;
    });
  }
}
```

---

## Anti-Patterns

### Anemic Domain Model

The domain model has no behavior — it is just a data container. Business logic bleeds into services, controllers, or use cases.

```dart
// WRONG — anemic entity, logic in service
class Order {
  String id;
  String status;
  double total; // mutable, no encapsulation
}

class OrderService {
  void confirm(Order order) {
    if (order.status == 'pending') { // business rule in service
      order.status = 'confirmed';   // direct mutation
    }
  }
}

// RIGHT — entity encapsulates its own invariants
class Order {
  Order confirm() {
    if (status != OrderStatus.pending) throw DomainException('...');
    return Order._(/* ... */ status: OrderStatus.confirmed);
  }
}
```

### God Aggregate

An aggregate that tries to own everything. An `Order` that contains the full `Customer`, the full `Product` catalog, shipping history, payment history, and promotional codes — all in one object.

Fix: aggregates reference other aggregates by ID only.

```dart
// WRONG
class Order {
  final Customer customer;        // full object — wrong
  final List<Product> products;   // full objects — wrong
}

// RIGHT
class Order {
  final CustomerId customerId;    // reference by ID only
  final List<OrderItem> items;    // items own their product reference by ID
}
```

### Leaking Domain Logic

Infrastructure or presentation concerns leak into the domain layer.

```dart
// WRONG — domain entity imports Flutter/Hive/JSON
import 'package:hive/hive.dart';
import 'dart:convert';

@HiveType(typeId: 1)
class User {
  Map<String, dynamic> toJson() => {...}; // serialization in domain
}

// RIGHT — domain entity is pure Dart, no framework imports
class User extends Equatable {
  // Pure domain, no annotations, no serialization
  User activate() { ... }
}

// Serialization belongs in the data layer
class UserModel {
  final User user;
  Map<String, dynamic> toJson() => {...};
  static User fromJson(Map<String, dynamic> json) => ...;
}
```
