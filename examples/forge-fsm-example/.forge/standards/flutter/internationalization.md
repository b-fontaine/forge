# Flutter Internationalization Standard

## Technology Stack

| Package | Role |
|---|---|
| `flutter_localizations` | Flutter's built-in localization delegates |
| `intl` | Date/number/plural formatting |
| `intl_utils` / gen-l10n | ARB → Dart class code generation |

---

## Project Setup

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true
```

### l10n.yaml

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/generated/l10n
nullable-getter: false
use-deferred-loading: false
```

Run `flutter gen-l10n` or `flutter pub get` (generate: true triggers automatically).

### MaterialApp Setup

```dart
// lib/app/app.dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/generated/l10n/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: context.watch<LocaleBloc>().state.locale,
      routerConfig: AppRouter.router,
    );
  }
}
```

---

## ARB File Format

### Template: lib/l10n/app_en.arb

```json
{
  "@@locale": "en",
  "@@last_modified": "2025-01-01",

  "appTitle": "My App",
  "@appTitle": {
    "description": "The title of the application shown in the toolbar and app launcher"
  },

  "welcomeMessage": "Welcome, {name}!",
  "@welcomeMessage": {
    "description": "Greeting displayed on the home screen after the user logs in",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "Alice"
      }
    }
  },

  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Number of items in the list",
    "placeholders": {
      "count": {
        "type": "int",
        "example": "5"
      }
    }
  },

  "lastUpdated": "Last updated {date}",
  "@lastUpdated": {
    "description": "Shows when the content was last refreshed",
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "yMMMd",
        "isCustomDateFormat": false
      }
    }
  },

  "price": "Price: {amount}",
  "@price": {
    "description": "Formatted price with currency",
    "placeholders": {
      "amount": {
        "type": "double",
        "format": "currency",
        "optionalParameters": {
          "symbol": "$",
          "decimalDigits": 2
        }
      }
    }
  },

  "signInButton": "Sign In",
  "@signInButton": {
    "description": "Label for the sign-in button on the authentication screen"
  },

  "errorInvalidEmail": "Please enter a valid email address",
  "@errorInvalidEmail": {
    "description": "Validation error shown when email format is incorrect"
  },

  "genderGreeting": "{gender, select, male{Welcome, sir!} female{Welcome, ma'am!} other{Welcome!}}",
  "@genderGreeting": {
    "description": "Gender-sensitive greeting",
    "placeholders": {
      "gender": {
        "type": "String"
      }
    }
  }
}
```

### French Translation: lib/l10n/app_fr.arb

```json
{
  "@@locale": "fr",

  "appTitle": "Mon Application",
  "welcomeMessage": "Bienvenue, {name} !",
  "itemCount": "{count, plural, =0{Aucun élément} =1{1 élément} other{{count} éléments}}",
  "lastUpdated": "Dernière mise à jour {date}",
  "price": "Prix : {amount}",
  "signInButton": "Se connecter",
  "errorInvalidEmail": "Veuillez entrer une adresse e-mail valide",
  "genderGreeting": "{gender, select, male{Bienvenue, monsieur !} female{Bienvenue, madame !} other{Bienvenue !}}"
}
```

---

## Usage in Widgets

```dart
// Access via context extension
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return Column(
    children: [
      Text(l10n.appTitle),
      Text(l10n.welcomeMessage('Alice')),
      Text(l10n.itemCount(42)),
      Text(l10n.lastUpdated(DateTime.now())),
      Text(l10n.price(9.99)),
    ],
  );
}
```

### Context Extension (Convenience)

```dart
// lib/core/extensions/localization_extension.dart
extension LocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// Usage
Text(context.l10n.signInButton)
```

---

## Date and Number Formatting

```dart
import 'package:intl/intl.dart';

// Date formatting
final formatter = DateFormat.yMMMd(Localizations.localeOf(context).toString());
final formatted = formatter.format(DateTime.now()); // "Jan 1, 2025" in en

// Number formatting
final numFormatter = NumberFormat.decimalPattern(locale);
final formatted = numFormatter.format(1234567.89); // "1,234,567.89" in en

// Currency
final currencyFormatter = NumberFormat.currency(locale: locale, symbol: '€', decimalDigits: 2);
final price = currencyFormatter.format(9.99); // "€9.99"

// Relative time (use timeago package)
timeago.format(DateTime.now().subtract(const Duration(hours: 2))); // "2 hours ago"
```

---

## RTL Support

```dart
// Test RTL by setting locale to 'ar' or 'he'
// Never hardcode Alignment.left/right — use start/end variants

// Bad
Align(alignment: Alignment.centerLeft, child: ...)
EdgeInsets.only(left: 16)

// Good
Align(alignment: AlignmentDirectional.centerStart, child: ...)
EdgeInsetsDirectional.only(start: 16)

// Icons that have directional meaning
Icon(
  Directionality.of(context) == TextDirection.ltr
    ? Icons.arrow_forward
    : Icons.arrow_back,
)
// Or use the auto-mirroring approach:
Directionality(
  textDirection: Directionality.of(context),
  child: const Icon(Icons.arrow_forward),
)
```

---

## Locale Detection and Switching

```dart
// lib/core/locale/locale_bloc.dart
@injectable
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc(this._storage) : super(LocaleState.system()) {
    on<LocaleChanged>(_onChanged);
    on<LocaleLoaded>(_onLoaded);
    add(LocaleLoaded());
  }

  final LocaleStorage _storage;

  Future<void> _onLoaded(LocaleLoaded event, Emitter<LocaleState> emit) async {
    final saved = await _storage.get();
    if (saved != null) emit(LocaleState.specific(saved));
  }

  Future<void> _onChanged(LocaleChanged event, Emitter<LocaleState> emit) async {
    await _storage.save(event.locale);
    emit(LocaleState.specific(event.locale));
  }
}
```

---

## Testing

```dart
// Widget test with specific locale
testWidgets('displays item count in French', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ItemListPage(items: [item1, item2]),
    ),
  );

  expect(find.text('2 éléments'), findsOneWidget);
});

// RTL layout test
testWidgets('renders correctly in RTL', (tester) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const SignInPage(),
      ),
    ),
  );
  // Verify no overflow errors
  expect(tester.takeException(), isNull);
});
```

---

## Rules

- **Zero hardcoded strings in widget code**: every user-visible string comes from ARB
- **Every ARB key has a `@key` description block**: no exceptions — descriptions are mandatory for translators
- **Use plurals for all count-dependent text**: `{count, plural, ...}` — never `'$count items'`
- **Use `select` for gender/categorical text**: never concatenate strings
- **Date and number formatting always uses `intl`**: no `.toString()` for values shown to users
- **Test RTL on every screen**: add RTL golden test for each new screen
- **All supported locales listed in `pubspec.yaml`**: do not add a locale ARB file without listing it
- **Never call `AppLocalizations.of(context)!` with `!`**: `nullable-getter: false` makes it non-nullable
- **Locale switching persists**: save to `SharedPreferences`, not just in-memory
