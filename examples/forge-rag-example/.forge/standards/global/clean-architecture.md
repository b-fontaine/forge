# Clean Architecture

## The Core Principle

Dependencies point inward. The domain layer knows nothing about the outside world. The outside world knows everything about the domain.

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│        (BLoC, Widgets, Pages, ViewModels)   │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │           Data Layer                  │  │
│  │   (Repositories, DataSources, Models) │  │
│  │                                       │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │        Domain Layer             │  │  │
│  │  │  (Entities, Use Cases,          │  │  │
│  │  │   Repositories [interfaces],    │  │  │
│  │  │   Value Objects, Events)        │  │  │
│  │  │                                 │  │  │
│  │  │  NO EXTERNAL DEPENDENCIES       │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## The Three Layers

### Domain Layer — Zero Dependencies

The domain layer contains the business rules. It is pure Dart or pure Rust. No Flutter imports. No Hive imports. No HTTP imports. No JSON serialization. Nothing.

What belongs here:
- **Entities**: Objects with identity and behavior
- **Value Objects**: Immutable, self-validating objects
- **Aggregates**: Clusters of entities with a root
- **Repository interfaces**: Contracts, not implementations
- **Use Cases**: Orchestration of domain objects
- **Domain Events**: Facts that happened in the domain
- **Domain Exceptions / Errors**: Domain-specific error types
- **Domain Services**: Stateless operations that don't belong on an entity

What does NOT belong here:
- `import 'package:flutter/material.dart'`
- `import 'package:hive/hive.dart'`
- `import 'package:dio/dio.dart'`
- `import 'dart:convert'` (serialization is a data concern)
- Any `@HiveType`, `@JsonSerializable`, or similar annotation

### Data Layer — Implements Domain Interfaces

The data layer implements the contracts defined by the domain. It knows about databases, HTTP APIs, and serialization. It does NOT know about Flutter widgets or BLoC.

What belongs here:
- **Repository implementations**: Implement domain repository interfaces
- **Data Sources**: Remote (API) and local (database/cache) abstractions
- **Models**: Data transfer objects with serialization (fromJson/toJson, fromHive)
- **Mappers**: Convert between models (data) and entities (domain)
- **Interceptors**: HTTP interceptors, auth token injection

### Presentation Layer — Flutter + State Management

The presentation layer handles what the user sees and does. It knows about Flutter, BLoC, and routing. It does NOT directly use repositories or data sources — it goes through use cases.

What belongs here:
- **BLoC / Cubit**: State management, event handling
- **Pages**: Full-screen routed widgets
- **Widgets**: Reusable UI components
- **Mappers**: Convert domain entities to UI models (view models)

---

## The Dependency Rule

```
Presentation → Domain ← Data
              (Domain defines interfaces that Data implements)

Presentation → Use Cases → Entities
Presentation → Use Cases → Repository [interface]
                                 ↑ implemented by
                           RepositoryImpl (Data layer)
```

Allowed imports:
- Domain imports nothing external
- Data imports Domain (for interfaces and entities)
- Presentation imports Domain (for use cases and entities)
- Presentation does NOT import Data directly — DI wires them

Forbidden imports:
- Domain importing from Data or Presentation
- Data importing from Presentation
- Use cases importing specific repository implementations

---

## FSD Flutter Structure

Feature-Sliced Design maps cleanly onto Clean Architecture. Each feature is a vertical slice containing all three layers.

```
lib/
├── core/
│   ├── di/
│   │   ├── injection.dart               # get_it + injectable setup
│   │   └── injection.config.dart        # generated
│   ├── router/
│   │   ├── app_router.dart              # go_router / auto_route setup
│   │   └── route_guards.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── auth_interceptor.dart
│   ├── error/
│   │   ├── failure.dart                 # shared Failure types
│   │   └── exceptions.dart
│   └── extensions/
│       └── either_extensions.dart
│
├── shared/
│   ├── domain/
│   │   └── value_objects/
│   │       ├── email.dart
│   │       └── phone_number.dart
│   ├── presentation/
│   │   └── widgets/
│   │       ├── loading_indicator.dart
│   │       ├── error_view.dart
│   │       └── primary_button.dart
│   └── data/
│       └── local/
│           └── secure_storage.dart
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── value_objects/
│   │   │   │   ├── email.dart           # feature-specific VO
│   │   │   │   └── password.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart # INTERFACE only
│   │   │   └── usecases/
│   │   │       ├── sign_in_use_case.dart
│   │   │       ├── sign_out_use_case.dart
│   │   │       └── get_current_user_use_case.dart
│   │   │
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart      # JSON/Hive serialization
│   │   │   ├── mappers/
│   │   │   │   └── user_mapper.dart     # UserModel → User
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   │
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   ├── sign_in_page.dart
│   │       │   └── sign_up_page.dart
│   │       └── widgets/
│   │           ├── sign_in_form.dart
│   │           └── social_sign_in_button.dart
│   │
│   ├── home/
│   │   └── ...
│   │
│   └── profile/
│       └── ...
│
└── main.dart
```

### Per-Feature Rules

1. Features do not import from other features directly.
2. Shared code lives in `core/` (infrastructure) or `shared/` (domain/UI primitives).
3. Cross-feature navigation uses the router, not widget-to-widget imports.
4. Each feature's domain layer is independently testable.

---

## Hexagonal Rust Structure

Hexagonal architecture (Ports and Adapters) for Rust services:

```
src/
├── domain/
│   ├── entities/
│   │   ├── mod.rs
│   │   ├── order.rs
│   │   └── user.rs
│   ├── value_objects/
│   │   ├── mod.rs
│   │   ├── email.rs
│   │   ├── money.rs
│   │   └── order_id.rs
│   ├── events/
│   │   ├── mod.rs
│   │   └── order_confirmed.rs
│   ├── errors/
│   │   ├── mod.rs
│   │   └── domain_error.rs
│   └── ports/
│       ├── inbound/                     # Use case interfaces (driven ports)
│       │   ├── mod.rs
│       │   ├── create_order_port.rs     # trait CreateOrderPort
│       │   └── get_order_port.rs
│       └── outbound/                    # Repository/service interfaces (driving ports)
│           ├── mod.rs
│           ├── order_repository.rs      # trait OrderRepository
│           ├── event_publisher.rs       # trait EventPublisher
│           └── payment_gateway.rs       # trait PaymentGateway
│
├── application/
│   └── services/
│       ├── mod.rs
│       ├── create_order_service.rs      # implements CreateOrderPort
│       └── get_order_service.rs         # implements GetOrderPort
│
├── adapters/
│   ├── inbound/                         # Driving adapters (they drive the app)
│   │   ├── grpc/
│   │   │   ├── mod.rs
│   │   │   ├── order_grpc_handler.rs    # tonic service
│   │   │   └── proto_mappers.rs
│   │   └── http/
│   │       ├── mod.rs
│   │       └── order_http_handler.rs    # axum handlers
│   └── outbound/                        # Driven adapters (the app drives them)
│       ├── postgres/
│       │   ├── mod.rs
│       │   ├── order_pg_repository.rs   # implements OrderRepository
│       │   └── models.rs
│       ├── redis/
│       │   └── cache_adapter.rs
│       └── kafka/
│           └── kafka_event_publisher.rs # implements EventPublisher
│
├── infrastructure/
│   ├── config.rs
│   ├── database.rs                      # connection pool setup
│   ├── telemetry.rs                     # OpenTelemetry setup
│   └── server.rs                        # tonic/axum server bootstrap
│
└── main.rs
```

### Cargo Workspace Structure (Multi-Crate)

```
[workspace]
members = [
  "crates/domain",
  "crates/application",
  "crates/adapters",
  "crates/infrastructure",
  "crates/grpc-server",
]

# Dependency flow:
# domain has NO external dependencies
# application depends on domain
# adapters depends on domain + application
# infrastructure depends on adapters
# grpc-server wires everything together
```

---

## Flutter Lazy Loading (Web)

For Flutter Web, lazy load feature modules to reduce initial bundle size. Use Dart's `deferred` imports.

```dart
// lib/core/router/app_router.dart

import 'package:go_router/go_router.dart';

// Deferred imports — only loaded when navigated to
import 'package:myapp/features/home/presentation/pages/home_page.dart'
    deferred as home;
import 'package:myapp/features/profile/presentation/pages/profile_page.dart'
    deferred as profile;
import 'package:myapp/features/settings/presentation/pages/settings_page.dart'
    deferred as settings;

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => NoTransitionPage(
        child: FutureBuilder(
          future: home.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AppLoadingScreen();
            }
            return home.HomePage();
          },
        ),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => NoTransitionPage(
        child: DeferredWidget(
          loader: profile.loadLibrary,
          child: () => profile.ProfilePage(),
        ),
      ),
    ),
  ],
);

// Reusable deferred widget wrapper
class DeferredWidget extends StatefulWidget {
  final Future<void> Function() loader;
  final Widget Function() child;

  const DeferredWidget({
    super.key,
    required this.loader,
    required this.child,
  });

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load module'));
        }
        return widget.child();
      },
    );
  }
}
```
