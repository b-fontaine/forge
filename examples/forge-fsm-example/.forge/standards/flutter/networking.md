# Flutter Networking Standard

## Technology Stack

| Package | Role |
|---|---|
| `dio` | HTTP client |
| `retrofit` | Type-safe API client code generation |
| `retrofit_generator` | Build runner generator |
| `fpdart` | `Either<L, R>` for typed error handling |

---

## API Interface Definition

```dart
// lib/features/users/adapters/users_api_client.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'users_api_client.g.dart';

@RestApi()
abstract class UsersApiClient {
  factory UsersApiClient(Dio dio, {String baseUrl}) = _UsersApiClient;

  @GET('/users')
  Future<PaginatedResponse<UserDto>> getUsers(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET('/users/{id}')
  Future<UserDto> getUserById(@Path('id') String id);

  @POST('/users')
  @Headers({'Content-Type': 'application/json'})
  Future<UserDto> createUser(@Body() CreateUserRequest request);

  @PATCH('/users/{id}')
  Future<UserDto> updateUser(
    @Path('id') String id,
    @Body() UpdateUserRequest request,
  );

  @DELETE('/users/{id}')
  @DioResponseType(ResponseType.bytes)
  Future<void> deleteUser(@Path('id') String id);

  @GET('/users/{id}/avatar')
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> downloadAvatar(@Path('id') String id);
}
```

---

## Error Handling: DioException → Failure → Either

### Failure Types

```dart
// lib/core/errors/failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.network({required String message}) = NetworkFailure;
  const factory Failure.unauthorized() = UnauthorizedFailure;
  const factory Failure.forbidden() = ForbiddenFailure;
  const factory Failure.notFound({required String resource}) = NotFoundFailure;
  const factory Failure.conflict({required String message}) = ConflictFailure;
  const factory Failure.validation({required Map<String, List<String>> errors}) = ValidationFailure;
  const factory Failure.serverError({required int statusCode, required String message}) = ServerErrorFailure;
  const factory Failure.timeout() = TimeoutFailure;
  const factory Failure.cancelled() = CancelledFailure;
  const factory Failure.unknown({required Object error}) = UnknownFailure;
}
```

### DioException Mapper

```dart
// lib/core/errors/dio_exception_mapper.dart
extension DioExceptionMapper on DioException {
  Failure toFailure() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const Failure.timeout();

      case DioExceptionType.cancel:
        return const Failure.cancelled();

      case DioExceptionType.connectionError:
        return Failure.network(message: message ?? 'No internet connection');

      case DioExceptionType.badResponse:
        return _mapStatusCode(response?.statusCode, response?.data);

      case DioExceptionType.unknown:
        return Failure.unknown(error: error ?? this);

      default:
        return Failure.unknown(error: this);
    }
  }

  Failure _mapStatusCode(int? statusCode, dynamic data) {
    return switch (statusCode) {
      400 => Failure.validation(errors: _parseValidationErrors(data)),
      401 => const Failure.unauthorized(),
      403 => const Failure.forbidden(),
      404 => Failure.notFound(resource: _parseResource(data)),
      409 => Failure.conflict(message: _parseMessage(data)),
      >= 500 => Failure.serverError(
          statusCode: statusCode!,
          message: _parseMessage(data),
        ),
      _ => Failure.serverError(statusCode: statusCode ?? 0, message: 'Unexpected error'),
    };
  }

  Map<String, List<String>> _parseValidationErrors(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('errors')) {
      return (data['errors'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );
    }
    return {};
  }

  String _parseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String? ?? 'Unknown error';
    }
    return 'Unknown error';
  }

  String _parseResource(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['resource'] as String? ?? 'resource';
    }
    return 'resource';
  }
}
```

### Repository Pattern with Either

```dart
// lib/features/users/adapters/user_repository_impl.dart
@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._apiClient);

  final UsersApiClient _apiClient;

  @override
  Future<Either<Failure, List<User>>> getUsers({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.getUsers(page, limit);
      return Right(response.items.map((dto) => dto.toDomain()).toList());
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(Failure.unknown(error: e));
    }
  }

  @override
  Future<Either<Failure, User>> getUserById(String id) async {
    try {
      final dto = await _apiClient.getUserById(id);
      return Right(dto.toDomain());
    } on DioException catch (e) {
      return Left(e.toFailure());
    }
  }
}
```

---

## Interceptors

### Auth Interceptor (Token Injection + Refresh)

```dart
// lib/core/network/interceptors/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage, this._authApiClient);

  final TokenStorage _tokenStorage;
  final AuthApiClient _authApiClient;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          handler.next(err);
          return;
        }

        final newToken = await _authApiClient.refresh(RefreshRequest(token: refreshToken));
        await _tokenStorage.save(newToken);

        // Retry original request with new token
        final retryOptions = err.requestOptions
          ..headers['Authorization'] = 'Bearer ${newToken.accessToken}';
        final retryResponse = await Dio().fetch(retryOptions);
        handler.resolve(retryResponse);
      } on DioException catch (_) {
        await _tokenStorage.clear();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
```

### Log Interceptor

```dart
// lib/core/network/interceptors/log_interceptor.dart
class AppLogInterceptor extends Interceptor {
  AppLogInterceptor(this._logger);

  final Logger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('✗ ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}
```

### Retry Interceptor

```dart
// lib/core/network/interceptors/retry_interceptor.dart
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, this.retries = 3, this.retryDelays = const [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ]});

  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final currentRetry = extra['retry_count'] as int? ?? 0;

    final shouldRetry = _isRetryable(err) && currentRetry < retries;

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    final delay = retryDelays.length > currentRetry
        ? retryDelays[currentRetry]
        : retryDelays.last;

    await Future.delayed(delay);

    err.requestOptions.extra['retry_count'] = currentRetry + 1;

    try {
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }

  bool _isRetryable(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.response?.statusCode != null && e.response!.statusCode! >= 500);
  }
}
```

### Cache Interceptor

```dart
// lib/core/network/interceptors/cache_interceptor.dart
class CacheInterceptor extends Interceptor {
  CacheInterceptor(this._cache);

  final Map<String, CachedResponse> _cache;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET') {
      handler.next(options);
      return;
    }

    final cacheKey = options.uri.toString();
    final cached = _cache[cacheKey];

    if (cached != null && !cached.isExpired) {
      handler.resolve(cached.toResponse(options));
      return;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      _cache[response.requestOptions.uri.toString()] = CachedResponse(
        data: response.data,
        cachedAt: DateTime.now(),
        ttl: const Duration(minutes: 5),
      );
    }
    handler.next(response);
  }
}
```

---

## Complete API Client Setup

```dart
// lib/core/network/dio_factory.dart
@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio(
    AppConfig config,
    TokenStorage tokenStorage,
    Logger logger,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'X-App-Version': config.appVersion,
          'X-Platform': Platform.operatingSystem,
        },
      ),
    );

    // Order matters: Auth → Log → Retry → Cache
    dio.interceptors.addAll([
      AuthInterceptor(tokenStorage, getIt<AuthApiClient>()),
      AppLogInterceptor(logger),
      RetryInterceptor(dio: Dio(BaseOptions(baseUrl: config.apiBaseUrl)), retries: 3),
      CacheInterceptor({}),
    ]);

    return dio;
  }
}
```

---

## Rules

- **All network calls return `Either<Failure, T>`**: never throw from a repository
- **Map `DioException` at the repository boundary**: use the `toFailure()` extension
- **Set explicit timeouts**: connect 10s, receive 30s, send 30s
- **Retry on 5xx and connection errors only**: never retry 4xx responses
- **Inject auth token in interceptor, not in call sites**: no `Authorization` header in feature code
- **Token refresh retries the original request transparently**
- **Log requests and responses at debug level only**: never log tokens or passwords
- **Cache GET requests with a TTL**: default 5 minutes, configurable per endpoint via `extra`
- **All DTOs have `toDomain()` methods**: no Retrofit-generated types leak into the domain layer
- **Cancellation tokens for long-running requests**: store `CancelToken` in BLoC and cancel on `close()`
