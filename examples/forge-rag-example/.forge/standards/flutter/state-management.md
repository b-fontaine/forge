# Flutter State Management

## flutter_bloc — The Only Choice

This project uses `flutter_bloc` exclusively. Why:

1. **Explicit state machines.** Every state is named, typed, and documented. No implicit state hidden in booleans.
2. **Testable by design.** `bloc_test` provides first-class testing for state transitions. Zero widget setup required.
3. **Predictable.** Events in → states out. One-directional data flow. No side effects in builders.
4. **Observable.** `BlocObserver` provides centralized logging and telemetry for all state changes.
5. **Separation of concerns enforced.** BLoC cannot import widgets. Widgets cannot call repositories.
6. **Large ecosystem.** Mature, battle-tested, excellent documentation.

Do not introduce: `Provider` (for state), `Riverpod`, `GetX`, `MobX`, `setState` for shared state. `setState` is acceptable only for purely local, non-shared, ephemeral widget state (e.g., animation controller state, focus management).

---

## Cubit vs Bloc Decision Guide

| Use Cubit when | Use Bloc when |
|---------------|--------------|
| State transitions are simple (no complex event handling) | Events need to be queued, debounced, or transformed |
| No event-driven logic required | You need `on<Event>()` with `EventTransformer` |
| Simple counter, toggle, locale change, theme switch | Complex async workflows |
| The state change is triggered directly by UI interaction | Multiple events can trigger the same state |
| No need to log event → state mappings | Full auditability of event → state pairs required |

**Rule of thumb:** Start with Cubit. Upgrade to Bloc when you need event transformers (`debounce`, `throttle`, `restartable`) or when multiple UI actions map to the same state transition.

---

## Full Structure with freezed

### Events

```dart
// lib/features/products/presentation/bloc/product_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_event.freezed.dart';

@freezed
sealed class ProductEvent with _$ProductEvent {
  // Load initial list
  const factory ProductEvent.productsRequested() = ProductsRequested;

  // Pagination
  const factory ProductEvent.nextPageRequested() = NextPageRequested;

  // Search — will be debounced
  const factory ProductEvent.searchQueryChanged(String query) = SearchQueryChanged;

  // Filter
  const factory ProductEvent.categoryFilterApplied(String? categoryId) =
      CategoryFilterApplied;

  // Refresh
  const factory ProductEvent.refreshRequested() = RefreshRequested;
}
```

### States

```dart
// lib/features/products/presentation/bloc/product_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_state.freezed.dart';

@freezed
sealed class ProductState with _$ProductState {
  const factory ProductState.initial() = ProductStateInitial;

  const factory ProductState.loading() = ProductStateLoading;

  const factory ProductState.loaded({
    required List<Product> products,
    required bool hasNextPage,
    required String? currentQuery,
    required String? currentCategoryId,
    @Default(false) bool isLoadingMore,
  }) = ProductStateLoaded;

  const factory ProductState.error({
    required Failure failure,
  }) = ProductStateError;

  const factory ProductState.empty({
    required String? currentQuery,
  }) = ProductStateEmpty;
}
```

### BLoC

```dart
// lib/features/products/presentation/bloc/product_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

part 'product_event.dart';
part 'product_state.dart';

@injectable
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase _getProducts;
  final SearchProductsUseCase _searchProducts;

  ProductBloc({
    required GetProductsUseCase getProducts,
    required SearchProductsUseCase searchProducts,
  })  : _getProducts = getProducts,
        _searchProducts = searchProducts,
        super(const ProductState.initial()) {
    on<ProductsRequested>(_onProductsRequested);
    on<NextPageRequested>(_onNextPageRequested, transformer: droppable());
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 350))
          .asyncExpand(mapper),
    );
    on<CategoryFilterApplied>(_onCategoryFilterApplied, transformer: restartable());
    on<RefreshRequested>(_onRefreshRequested, transformer: restartable());
  }

  Future<void> _onProductsRequested(
    ProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductState.loading());
    final result = await _getProducts(const GetProductsParams(page: 1));

    result.fold(
      (failure) => emit(ProductState.error(failure: failure)),
      (page) => page.items.isEmpty
          ? emit(const ProductState.empty(currentQuery: null))
          : emit(ProductState.loaded(
              products: page.items,
              hasNextPage: page.hasNext,
              currentQuery: null,
              currentCategoryId: null,
            )),
    );
  }

  Future<void> _onNextPageRequested(
    NextPageRequested event,
    Emitter<ProductState> emit,
  ) async {
    final current = state;
    if (current is! ProductStateLoaded || !current.hasNextPage) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = (current.products.length ~/ 20) + 1;
    final result = await _getProducts(GetProductsParams(
      page: nextPage,
      query: current.currentQuery,
      categoryId: current.currentCategoryId,
    ));

    result.fold(
      (failure) => emit(ProductState.error(failure: failure)),
      (page) => emit(current.copyWith(
        products: [...current.products, ...page.items],
        hasNextPage: page.hasNext,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<ProductState> emit,
  ) async {
    if (event.query.isEmpty) {
      return _onProductsRequested(const ProductsRequested(), emit);
    }

    emit(const ProductState.loading());
    final result = await _searchProducts(SearchProductsParams(query: event.query));

    result.fold(
      (failure) => emit(ProductState.error(failure: failure)),
      (products) => products.isEmpty
          ? emit(ProductState.empty(currentQuery: event.query))
          : emit(ProductState.loaded(
              products: products,
              hasNextPage: false,
              currentQuery: event.query,
              currentCategoryId: null,
            )),
    );
  }

  Future<void> _onCategoryFilterApplied(
    CategoryFilterApplied event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductState.loading());
    final result = await _getProducts(GetProductsParams(
      page: 1,
      categoryId: event.categoryId,
    ));

    result.fold(
      (failure) => emit(ProductState.error(failure: failure)),
      (page) => emit(ProductState.loaded(
        products: page.items,
        hasNextPage: page.hasNext,
        currentQuery: null,
        currentCategoryId: event.categoryId,
      )),
    );
  }

  Future<void> _onRefreshRequested(
    RefreshRequested event,
    Emitter<ProductState> emit,
  ) => _onProductsRequested(const ProductsRequested(), emit);
}
```

### Cubit Example

```dart
// lib/features/theme/presentation/cubit/theme_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

// No freezed needed for simple state
enum AppThemeMode { light, dark, system }

@singleton
class ThemeCubit extends Cubit<AppThemeMode> {
  final ThemePreferencesRepository _preferences;

  ThemeCubit(this._preferences)
      : super(AppThemeMode.system);

  Future<void> loadSavedTheme() async {
    final saved = await _preferences.getThemeMode();
    emit(saved);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    await _preferences.saveThemeMode(mode);
    emit(mode);
  }
}
```

---

## Rules

### BLoC is Injectable

Every BLoC and Cubit is registered with `injectable`. They are never constructed manually in widgets.

```dart
// CORRECT
@injectable  // or @singleton, @lazySingleton
class ProductBloc extends Bloc<ProductEvent, ProductState> { }

// In widget
BlocProvider(
  create: (_) => getIt<ProductBloc>()..add(const ProductsRequested()),
  child: ...,
)

// WRONG — manual construction in widget
BlocProvider(
  create: (_) => ProductBloc(
    getProducts: GetProductsUseCase(ProductRepositoryImpl(...)),
    searchProducts: SearchProductsUseCase(...),
  ),
  child: ...,
)
```

### States are Immutable

States use `freezed` for immutability and `copyWith`. Never mutate state in place.

```dart
// CORRECT
emit(current.copyWith(isLoadingMore: true));

// WRONG
current.isLoadingMore = true; // mutation — won't trigger rebuild, error-prone
emit(current);
```

### No UI Imports in BLoC

BLoC files must not import `flutter/material.dart` or any widget.

```dart
// WRONG — importing Flutter in BLoC
import 'package:flutter/material.dart'; // Never in bloc files

// CORRECT — BLoC imports only domain and bloc packages
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/get_products_use_case.dart';
import '../../../domain/entities/product.dart';
```

### BlocListener vs BlocBuilder vs BlocSelector

| Widget | Use when |
|--------|---------|
| `BlocBuilder` | Widget must rebuild when state changes |
| `BlocListener` | Side effects: navigation, snackbar, dialog — no rebuild needed |
| `BlocConsumer` | Both rebuild AND side effects needed (use sparingly) |
| `BlocSelector` | Widget rebuilds only when a specific field changes — performance optimization |

```dart
// BlocListener — for side effects only
BlocListener<AuthBloc, AuthState>(
  listenWhen: (previous, current) => current is AuthStateAuthenticated,
  listener: (context, state) {
    context.go('/home');
  },
  child: const SignInForm(),
)

// BlocBuilder — for UI rebuild
BlocBuilder<ProductBloc, ProductState>(
  builder: (context, state) => switch (state) {
    ProductStateLoading() => const LoadingIndicator(),
    ProductStateLoaded(:final products) => ProductListView(products: products),
    ProductStateError(:final failure) => ErrorView(failure: failure),
    ProductStateEmpty(:final currentQuery) => EmptyStateView(query: currentQuery),
    ProductStateInitial() => const SizedBox.shrink(),
  },
)

// BlocSelector — rebuild only when specific field changes
BlocSelector<ProductBloc, ProductState, bool>(
  selector: (state) => state.maybeWhen(
    loaded: (_, __, ___, ____, isLoadingMore) => isLoadingMore,
    orElse: () => false,
  ),
  builder: (context, isLoadingMore) =>
      isLoadingMore ? const LinearProgressIndicator() : const SizedBox.shrink(),
)
```

### Stream Management

BLoC automatically cancels subscriptions when `close()` is called. Use `emit.onEach` or `emit.forEach` for stream subscriptions within event handlers.

```dart
// CORRECT — BLoC manages the subscription
Future<void> _onAuthStateWatchRequested(
  AuthStateWatchRequested event,
  Emitter<AuthState> emit,
) async {
  await emit.forEach<User?>(
    _authRepository.authStateChanges,
    onData: (user) => user != null
        ? AuthState.authenticated(user: user)
        : const AuthState.unauthenticated(),
    onError: (_, __) => const AuthState.unauthenticated(),
  );
}

// WRONG — manual subscription management, leaks if not disposed
StreamSubscription? _subscription;

void _onAuthStateWatchRequested(...) {
  _subscription = _authRepository.authStateChanges.listen((user) {
    emit(user != null ? AuthState.authenticated(user: user) : ...);
  });
}

@override
Future<void> close() {
  _subscription?.cancel(); // Easy to forget
  return super.close();
}
```

### close() Cleanup

Blocs provided via `BlocProvider` are automatically closed when the widget is removed from the tree. For manually-managed blocs (rare), always call `close()`.

```dart
// BlocProvider handles close() automatically
BlocProvider(
  create: (_) => getIt<ProductBloc>(),
  child: ...,
)

// For page-level blocs with navigation
// BlocProvider on the page widget + GoRouter handles disposal automatically
```

### Global BLoC Observer

Register a global observer for logging and telemetry:

```dart
// lib/core/di/bloc_observer.dart
import 'package:bloc/bloc.dart';

class AppBlocObserver extends BlocObserver {
  final Logger _logger;

  AppBlocObserver(this._logger);

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.d('${bloc.runtimeType} ← $event');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _logger.d(
      '${bloc.runtimeType}: ${transition.currentState.runtimeType} '
      '→ ${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.e('${bloc.runtimeType} error', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}

// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(Environment.prod);
  Bloc.observer = getIt<AppBlocObserver>();
  runApp(const App());
}
```
