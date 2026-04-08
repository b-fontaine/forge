# Flutter Dependency Injection Standard

## Technology Stack

| Package | Role |
|---|---|
| `get_it` | Service locator / IoC container |
| `injectable` | Code generation for DI annotations |
| `injectable_generator` | Build runner generator |

---

## Annotations Reference

| Annotation | When to use |
|---|---|
| `@injectable` | Transient: new instance every time it is requested |
| `@singleton` | Eager singleton: created at startup |
| `@lazySingleton` | Lazy singleton: created on first access |
| `@module` | Third-party registrations that cannot use annotations directly |
| `@Named('name')` | Disambiguate multiple implementations of the same interface |
| `@Environment('env')` | Register only in a specific environment (dev, prod, test) |
| `@preResolve` | Await async factory before the container is ready |

---

## Project Setup

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart'; // generated

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'configureDependencies',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies(String environment) async =>
    getIt.configureDependencies(environment: environment);
```

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(Environment.prod);
  runApp(const App());
}
```

Generate: `dart run build_runner build --delete-conflicting-outputs`

---

## Domain & Application Layer

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<Either<AuthFailure, User>> signIn({required String email, required String password});
  Future<Either<AuthFailure, Unit>> signOut();
}
```

```dart
// lib/features/auth/application/use_cases/sign_in_use_case.dart
@injectable
class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AuthFailure, User>> call({
    required String email,
    required String password,
  }) =>
      _repository.signIn(email: email, password: password);
}
```

---

## Adapter Layer

```dart
// lib/features/auth/adapters/auth_repository_impl.dart
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._apiClient, this._tokenStorage);

  final AuthApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<Either<AuthFailure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.signIn(SignInRequest(email: email, password: password));
      await _tokenStorage.save(response.token);
      return Right(response.user.toDomain());
    } on DioException catch (e) {
      return Left(AuthFailure.fromDioException(e));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    await _tokenStorage.clear();
    return const Right(unit);
  }
}
```

---

## Module for Third-Party Dependencies

```dart
// lib/core/di/network_module.dart
@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio(AppConfig config) {
    return Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    )
      ..interceptors.add(AuthInterceptor(getIt<TokenStorage>()))
      ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true))
      ..interceptors.add(RetryInterceptor(dio: Dio(), retries: 3));
  }

  @lazySingleton
  AppConfig appConfig() => AppConfig.fromEnv();
}
```

```dart
// lib/core/di/storage_module.dart
@module
abstract class StorageModule {
  @preResolve
  @lazySingleton
  Future<SharedPreferences> sharedPreferences() => SharedPreferences.getInstance();

  @lazySingleton
  HiveInterface hive() => Hive;
}
```

---

## Retrofit Integration

```dart
// lib/features/auth/adapters/auth_api_client.dart
@RestApi()
@injectable
abstract class AuthApiClient {
  @factoryMethod
  factory AuthApiClient(Dio dio, @Named('baseUrl') String baseUrl) =>
      _AuthApiClient(dio, baseUrl: baseUrl);

  @POST('/auth/sign-in')
  Future<SignInResponse> signIn(@Body() SignInRequest request);

  @POST('/auth/sign-out')
  Future<void> signOut();

  @GET('/auth/me')
  Future<UserResponse> me();
}
```

```dart
// lib/core/di/api_module.dart
@module
abstract class ApiModule {
  @Named('baseUrl')
  String get baseUrl => const String.fromEnvironment('API_BASE_URL');
}
```

---

## Named Registrations

```dart
// Multiple implementations of the same interface
@Named('remote')
@LazySingleton(as: UserRepository)
class RemoteUserRepository implements UserRepository { ... }

@Named('local')
@LazySingleton(as: UserRepository)
class LocalUserRepository implements UserRepository { ... }

// Inject by name
@injectable
class SyncService {
  const SyncService(
    @Named('remote') this._remote,
    @Named('local') this._local,
  );

  final UserRepository _remote;
  final UserRepository _local;
}
```

---

## Environment-Specific Registrations

```dart
@LazySingleton(as: AuthRepository, env: [Environment.prod])
class AuthRepositoryImpl implements AuthRepository { ... }

@LazySingleton(as: AuthRepository, env: [Environment.test])
class FakeAuthRepository implements AuthRepository { ... }
```

```dart
// test/helpers/test_injection.dart
Future<void> configureTestDependencies() async {
  await configureDependencies(Environment.test);
  // Override specific registrations for tests
  getIt.allowReassignment = true;
  getIt.registerLazySingleton<AuthRepository>(() => FakeAuthRepository());
}
```

---

## Feature-Level Modules

Large features should isolate their own module.

```dart
// lib/features/checkout/di/checkout_module.dart
@module
abstract class CheckoutModule {
  @lazySingleton
  CheckoutCart cart() => CheckoutCart();

  @injectable
  PlaceOrderUseCase placeOrder(
    OrderRepository orderRepository,
    PaymentRepository paymentRepository,
    CartRepository cartRepository,
  ) => PlaceOrderUseCase(orderRepository, paymentRepository, cartRepository);
}
```

---

## BLoC Registration

BLoCs are transient (new instance per route/screen). Register with `@injectable`.

```dart
@injectable
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc(this._signIn) : super(SignInState.initial()) {
    on<SignInSubmitted>(_onSubmitted);
  }

  final SignInUseCase _signIn;
}
```

Provide in the widget tree, never pull from `getIt` inside a widget:

```dart
// In router or screen factory
BlocProvider(
  create: (context) => getIt<SignInBloc>(),
  child: const SignInPage(),
)
```

---

## Rules

- **Never call `getIt<T>()` directly inside a widget**: use `BlocProvider`, `RepositoryProvider`, or constructor injection
- **Constructor injection always**: every dependency appears in the constructor, never in a field initializer using `getIt`
- **One `@module` per concern**: separate network, storage, analytics, and feature modules
- **`@lazySingleton` by default for services**: only use `@singleton` if eager initialization is genuinely required
- **`@injectable` for BLoCs**: BLoCs are never singletons
- **`@preResolve` for async setup**: `SharedPreferences`, `Hive.initFlutter()`, `FirebaseApp`
- **Feature modules register only feature-level types**: core singletons belong in core modules
- **Test environment uses `FakeX` implementations**: never mock `getIt` itself
