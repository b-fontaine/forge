# Evidence — `b9-5-bloc-generator`

All probes 2026-09-12.

---

## P-1 — the re-scope is forced, not preferred

```
grep -rn "shared/protos"  .forge/templates/archetypes/mobile-pwa-first/  → nothing
.forge/schemas/mobile-pwa-first/2.0.0.yaml                               → layer_profile: client-only
```

Two layers, `app` and `web-pwa`. No backend layer, no infra layer, no contract of any
kind under Forge's control. §5.2's "from the proto messages" has no input on this
archetype, and cannot acquire one without contradicting `ADR-B9-1-001`.

The maintainer stated the principle the same day: the archetype does not manage the
server. The IdP is in the adopter's information system; Forge supplies a config corner
(`oidc-provider.json`) and a conformant client, and nothing across the line. Apply that
boundary to state management and the source of truth must be a local declaration —
`ADR-B95-001`.

## P-2 — what the archetype already had, and had not

| | |
|---|---|
| `flutter_bloc: ^8.1.6`, `equatable: ^2.0.5` | `pubspec.yaml.tmpl:15-16`, used by the one scaffolded bloc |
| `bloc_test: ^9.1.7`, `mocktail: ^1.0.4` | `:44-45` — **declared, used by nothing** |
| `test/` | one file, `widget_test.dart.tmpl` |
| `lib/presentation/`, `domain/`, `data/` | `auth_bloc.dart` plus `.gitkeep` |

The test-discipline dependencies for Bloc shipped without a single `blocTest`. The
generator uses both, and adds neither.

## P-3 — the idiom is copied, not invented

Read off `lib/presentation/auth/auth_bloc.dart` (116 lines): `abstract class AuthEvent
extends Equatable`, `const` constructors, `List<Object?> get props`,
`AuthBloc({required AuthRepository repository})`, `super(const AuthInitial())`,
`on<AuthLoginRequested>(_onLogin)`.

Generated for a `Cart` fixture — the same shapes, same order:

```dart
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({required CartRepository repository})
      : _repository = repository,
        super(const CartInitial()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartCleared>(_onCleared);
  }
```

## P-4 — RED before GREEN

`T-032`/`T-033` against no generator: **RED**, naming the absent script. After
`bin/forge-gen-bloc.sh`: `b9-2` **33/33**.

## P-5 — the exit envelope, every branch provoked

```
  --help                                 -> 0      --dry-run (files 2 -> 2)   -> 0
  no --feature                           -> 2      first real run             -> 0
  no --target                            -> 2      re-run (collision)         -> 8
  unknown flag                           -> 2      re-run --force             -> 0
  --target missing dir                   -> 7      python3 absent from PATH   -> 5
  no pubspec.yaml                        -> 7
  pubspec without flutter_bloc           -> 7
  descriptor missing                     -> 7
  first state declares fields            -> 7
  no events:                             -> 7
  name not PascalCase                    -> 7
```

`--dry-run` left the fixture at 2 files. The exit-5 probe used an absolute interpreter
— `env -i PATH=/nonexistent bash …` resolves `bash` through the new PATH and returns
127 without running the script, the mistake `b9-10` P-3 recorded.

## P-6 — a gap the first version shipped

The generated `cart_event.dart` declared `final CartItem item;` with **no import for
`CartItem`**. The generator cannot guess where an adopter's domain types live, so any
event with a non-primitive field produced code that does not compile — which would make
the generator a nuisance rather than a shortcut.

Fixed by an optional `imports:` list in the descriptor, emitted verbatim into all three
generated sources. Verified:

```
import 'package:shop/domain/cart/cart_item.dart';

abstract class CartEvent extends Equatable {
```

Found by reading the output, not by a test. `T-033` asserts the field declaration and
would not have caught a missing import — recorded as Q-002.

## P-7 — mutation probes, and the one that failed

| probe | result |
|---|---|
| handlers `return;` instead of throwing | RED |
| only the first event registered | RED |
| tripwire asserts `expect: () => []` instead of the error | RED |
| mocktail double dropped | RED |
| only the first `blocTest` emitted | RED |
| field types erased to `dynamic` | RED |
| **`Equatable` props dropped from the base classes** | **STILL GREEN** |

The needle was `List<Object?> get props`, and the generator emits that string from
**two** code paths — the base-class block and the field-carrying branch. Breaking one
left the other, and the needle was satisfied by the site it was not testing.

Split into `List<Object?> get props => [];` (bases) and `… => [item];` (field-carrying).
Re-probed: **both RED**, 8/8 overall.

Fourth instance in three days of a needle satisfied by something other than what it
names — `b9-2::T-029` (whole file), `b5`'s FR-IW-009 guard (whole file), `b9-4`'s
`client-only` (recurring word), and now a second emission site inside the same output.
Scoping the region was not enough; the needle also has to be unique **and** anchored to
the code path it claims to protect.

## P-8 — a spec corrected against its own implementation

`FR-B95-006` as first written said the generated test is green on generation. Writing
the generator showed that is only true for field-less events: an event with fields gets
`/* TODO: item (CartItem) */` in its constructor call, and that test does not compile
until the adopter fills it in.

Fabricating a value instead would make the suite green on data nobody chose — worse
than not compiling. The requirement was narrowed to match what the code does rather
than the code bent to match the requirement.

## P-9 — negative scope

`git status` shows nothing under `.forge/templates/`, `.forge/scaffold-snapshots/`,
`.forge/schemas/`; no `pubspec.yaml.tmpl` touched. The generator adds no dependency on
either side: `bash` + `python3` for itself, and the four Dart packages it emits against
were already declared.

## P-10 — regression

`b9-2` 33/33 · `b9-1` · `b4` and `b8-2` (frozen trees) · full 80-entry CI matrix ·
`shellcheck --severity=warning` · `verify.sh` + `constitution-linter.sh` after the
status flip: `tasks.md` T6.
