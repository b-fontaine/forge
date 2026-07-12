# Flutter Testing Standard

## Testing Pyramid

| Layer | Target | Scope |
|---|---|---|
| Unit | 70% | Pure functions, BLoCs, repositories, use cases |
| Widget | 20% | Individual widgets, screens, UI logic |
| Integration | 10% | Full user flows, end-to-end scenarios |

Every feature must have tests at every applicable layer before merging.

---

## Unit Tests

Unit tests cover domain logic, BLoCs, use cases, and utilities without rendering any UI.

```dart
// test/domain/use_cases/sign_in_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInUseCase(mockRepository);
  });

  group('SignInUseCase', () {
    test('returns Right(user) on valid credentials', () async {
      when(() => mockRepository.signIn(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => Right(fakeUser));

      final result = await useCase(email: 'user@example.com', password: 's3cr3t');

      expect(result, equals(Right(fakeUser)));
    });

    test('returns Left(Failure) when repository throws', () async {
      when(() => mockRepository.signIn(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => Left(AuthFailure.invalidCredentials()));

      final result = await useCase(email: 'bad@example.com', password: 'wrong');

      expect(result.isLeft(), isTrue);
    });
  });
}
```

---

## BLoC Testing with bloc_test

Use `blocTest<B, S>()` for all BLoC tests. Never test BLoCs through widgets.

```dart
// test/blocs/sign_in/sign_in_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}

void main() {
  late SignInBloc bloc;
  late MockSignInUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockSignInUseCase();
    bloc = SignInBloc(signInUseCase: mockUseCase);
  });

  tearDown(() => bloc.close());

  group('SignInBloc', () {
    blocTest<SignInBloc, SignInState>(
      'emits [loading, success] when credentials are valid',
      build: () {
        when(() => mockUseCase(email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async => Right(fakeUser));
        return bloc;
      },
      act: (bloc) => bloc.add(SignInSubmitted(email: 'user@example.com', password: 's3cr3t')),
      expect: () => [
        SignInState.loading(),
        SignInState.success(user: fakeUser),
      ],
      verify: (_) {
        verify(() => mockUseCase(email: 'user@example.com', password: 's3cr3t')).called(1);
      },
    );

    blocTest<SignInBloc, SignInState>(
      'emits [loading, failure] when credentials are invalid',
      build: () {
        when(() => mockUseCase(email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async => Left(AuthFailure.invalidCredentials()));
        return bloc;
      },
      act: (bloc) => bloc.add(SignInSubmitted(email: 'bad@example.com', password: 'wrong')),
      expect: () => [
        SignInState.loading(),
        isA<SignInState>().having((s) => s.isFailure, 'isFailure', isTrue),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'emits nothing on EmailChanged without submit',
      build: () => bloc,
      act: (bloc) => bloc.add(EmailChanged('typing...')),
      expect: () => [],
    );
  });
}
```

---

## Widget Tests

Use `pumpApp` helpers to inject theme, localizations, and router dependencies.

```dart
// test/helpers/pump_app.dart
extension WidgetTesterX on WidgetTester {
  Future<void> pumpApp(Widget widget, {List<BlocProvider>? providers}) async {
    await pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>(create: (_) => MockAuthRepository()),
        ],
        child: MultiBlocProvider(
          providers: providers ?? [],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: widget,
          ),
        ),
      ),
    );
  }
}
```

```dart
// test/features/sign_in/sign_in_page_test.dart
void main() {
  late MockSignInBloc mockBloc;

  setUp(() {
    mockBloc = MockSignInBloc();
    when(() => mockBloc.state).thenReturn(SignInState.initial());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('shows email and password fields', (tester) async {
    await tester.pumpApp(
      const SignInPage(),
      providers: [BlocProvider<SignInBloc>.value(value: mockBloc)],
    );

    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('shows loading indicator when state is loading', (tester) async {
    when(() => mockBloc.state).thenReturn(SignInState.loading());

    await tester.pumpApp(
      const SignInPage(),
      providers: [BlocProvider<SignInBloc>.value(value: mockBloc)],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
```

---

## BDD with bdd_widget_test

Feature files live in `test/features/<feature>/`. Step definitions live alongside them.

```gherkin
# test/features/sign_in/sign_in.feature
Feature: Sign In

  Scenario: Successful sign in with valid credentials
    Given I am on the sign in page
    When I enter "user@example.com" in the email field
    And I enter "password123" in the password field
    And I tap the sign in button
    Then I see the home page

  Scenario: Failed sign in shows error message
    Given I am on the sign in page
    When I enter "bad@example.com" in the email field
    And I enter "wrong" in the password field
    And I tap the sign in button
    Then I see an error message "Invalid credentials"
```

```dart
// test/features/sign_in/sign_in_test.dart
import 'package:bdd_widget_test/bdd_widget_test.dart';
import 'package:flutter_test/flutter_test.dart';

part 'sign_in_test.gen.dart'; // generated

void main() {
  group('Sign In', () {
    testWidgets('Successful sign in', (tester) async {
      await tester.pumpApp(const AppWrapper());
      // BDD steps injected by generator
    });
  });
}
```

```dart
// test/features/sign_in/steps/sign_in_steps.dart
Future<void> iAmOnTheSignInPage(WidgetTester tester) async {
  await tester.pumpApp(const SignInPage());
  await tester.pumpAndSettle();
}

Future<void> iEnterInTheEmailField(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('email_field')), email);
  await tester.pumpAndSettle();
}

Future<void> iEnterInThePasswordField(WidgetTester tester, String password) async {
  await tester.enterText(find.byKey(const Key('password_field')), password);
  await tester.pumpAndSettle();
}

Future<void> iTapTheSignInButton(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('sign_in_button')));
  await tester.pumpAndSettle();
}

Future<void> iSeeTheHomePage(WidgetTester tester) async {
  expect(find.byType(HomePage), findsOneWidget);
}

Future<void> iSeeAnErrorMessage(WidgetTester tester, String message) async {
  expect(find.text(message), findsOneWidget);
}
```

---

## Mocking with mocktail

```dart
// Prefer fakes for value objects, mocks for repositories/services
class FakeUser extends Fake implements User {}

class MockUserRepository extends Mock implements UserRepository {}

setUpAll(() {
  registerFallbackValue(FakeUser());
});

// Stub a method
when(() => mockRepo.getUser(any())).thenAnswer((_) async => Right(fakeUser));

// Stub to throw
when(() => mockRepo.getUser(any())).thenThrow(NetworkException());

// Verify call count
verify(() => mockRepo.getUser('uid-123')).called(1);

// Verify no interaction
verifyNever(() => mockRepo.deleteUser(any()));

// Capture arguments
final captured = verify(() => mockRepo.saveUser(captureAny())).captured;
expect(captured.last, fakeUser);
```

---

## Golden Tests with golden_toolkit

```dart
// test/widgets/user_avatar_golden_test.dart
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('UserAvatar renders correctly', (tester) async {
    await loadAppFonts();

    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
      ..addScenario(widget: const UserAvatar(name: 'Alice'), name: 'with name')
      ..addScenario(widget: const UserAvatar(imageUrl: 'https://...'), name: 'with image')
      ..addScenario(widget: const UserAvatar(), name: 'empty fallback');

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'user_avatar');
  });
}
```

Run `flutter test --update-goldens` to regenerate baseline images. Commit golden files.

---

## Test Data Builders

```dart
// test/helpers/builders/user_builder.dart
class UserBuilder {
  String _id = 'default-id';
  String _email = 'test@example.com';
  String _name = 'Test User';
  UserRole _role = UserRole.member;

  UserBuilder withId(String id) => this.._id = id;
  UserBuilder withEmail(String email) => this.._email = email;
  UserBuilder withName(String name) => this.._name = name;
  UserBuilder withRole(UserRole role) => this.._role = role;
  UserBuilder asAdmin() => withRole(UserRole.admin);

  User build() => User(id: _id, email: _email, name: _name, role: _role);
}

// Usage
final adminUser = UserBuilder().asAdmin().withName('Admin Alice').build();
final guestUser = UserBuilder().withRole(UserRole.guest).build();
```

---

## Mock Factories

Centralize mock creation to avoid duplication.

```dart
// test/helpers/mocks.dart
class Mocks {
  static MockAuthRepository authRepository() {
    final mock = MockAuthRepository();
    when(() => mock.currentUser).thenReturn(null);
    return mock;
  }

  static MockUserRepository userRepository() {
    final mock = MockUserRepository();
    when(() => mock.getUser(any())).thenAnswer((_) async => Right(UserBuilder().build()));
    return mock;
  }
}
```

---

## Integration Tests

```dart
// integration_test/sign_in_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full sign in flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email_field')), 'user@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byType(HomePage), findsOneWidget);
  });
}
```

---

## Rules

- **No `skip` without a linked issue**: `// TODO(issue/123): unskip when X is fixed`
- **Test behavior, not implementation**: assert on state/output, not internal method calls
- **No `sleep()` in tests**: use `pumpAndSettle()` or explicit pump durations
- **One logical assertion per test**: multiple `expect()` calls are fine if they assert the same behavior
- **Name tests as sentences**: `'returns Left when repository fails'`, not `'test1'`
- **BLoC mocks must stub `.state` and `.stream`** before `pumpApp`
- **Golden tests run on CI with fixed font rendering**: use `loadAppFonts()` and a consistent device
- **Integration tests run against a real or emulated backend**: use `--dart-define=ENV=test`
