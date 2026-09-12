# Design — `b9-5-bloc-generator`

## The boundary, drawn once

```
adopter's information system            Forge
───────────────────────────             ─────────────────────────────────
Keycloak / Auth0 / Cognito   ←──────→   oidc-provider.json   (a config corner)
  (Forge never sees it)                 oauth4webapi + flutter_appauth clients

the app's own features       ←──────→   <feature>.bloc.yaml  (a config corner)
  (Forge never sees them)               bin/forge-gen-bloc.sh
```

The left column is the adopter's. Forge owns a declaration format and a
standards-conformant implementation on the right, and nothing across the line. B.9.3
drew that boundary for identity; this brick draws the same one for state, which is why
the descriptor replaces the protos §5.2 assumed.

## Shape of the generator

`bin/forge-gen-bloc.sh --target <dir> --feature <name> [--dry-run] [--force]`

Phases, mirroring the sibling migration script so the three read alike:

| phase | does |
|---|---|
| 0 · preflight | target is a dir, has `pubspec.yaml`, pubspec declares `flutter_bloc`, descriptor exists and parses, `events`/`states` non-empty, first state is field-less — each failure exit 7, named |
| 1 · parse | normalise the descriptor into `(class, [(field, type)])` lists for events and states |
| 2 · render | build the four files in memory |
| 3 · collide-then-write | any target present ⇒ exit 8 unless `--force`; `--dry-run` prints and stops |

Python3 does the YAML read and the code assembly; bash owns the ABI and the file
writes. Same split as `forge-migrate-mobile-pwa.sh`.

## Why the first state must be field-less

The bloc's constructor is `super(const <Name><First>())`, copying
`AuthBloc`'s `super(const AuthInitial())`. A first state with fields has no
zero-argument const constructor, so the generated bloc would not compile. Refusing at
preflight with a named message beats emitting Dart that fails at `dart analyze`, and
beats silently picking a different initial state the descriptor did not ask for.

## The tripwire, and what it is not

```dart
blocTest<CartBloc, CartState>(
  'CartItemAdded is not implemented yet',
  build: () => CartBloc(repository: _MockCartRepository()),
  act: (bloc) => bloc.add(const CartItemAdded(...)),
  errors: () => [isA<UnimplementedError>()],
);
```

It is **green on generation and red on implementation**. That inversion is the design:
the moment the adopter writes `_onItemAdded`, this test fails and tells them a real
assertion is owed. A skipped test, an empty body, or a `expect(true, isTrue)` would all
be green forever and measure nothing.

The header comment says this in the generated file, because a reader counting green
tests as coverage would otherwise be wrong — and a test suite that lies about coverage
is the same failure as a scaffold that lies about being implemented.

`mocktail` supplies the double. It is already a declared dev-dependency
(`pubspec.yaml.tmpl:45`), so the generated test adds nothing to the project.

## Guards

Hosted in `b9-2.test.sh` as `T-032`/`T-033`, for the B.9.9/B.9.10/B.9.4 reason:
`forge-ci.yml` is at 419/420 and the last line is B.9.11's.

| test | asserts | fails when |
|---|---|---|
| `T-032` | shape and exit envelope — executable, `set -euo pipefail`, `--help` documents the descriptor keys, missing `--feature` exits 2, a non-Flutter target exits 7 | the ABI drifts from the siblings |
| `T-033` | **the output** — generate a fixture feature into a temp tree, then assert the four files exist and carry the reference idiom, the `UnimplementedError` per event, and one `blocTest` per event | the generator emits something other than what it claims |

`T-033` is the load-bearing one. `b8-10b` shipped 36 raw `.tmpl` files into adopters'
projects because no test ever looked at generator output; this one looks.

No `dart analyze` in L1 — the Flutter toolchain is not a CI dependency of this
repository. The structural assertions stand in for it, and their limit is recorded
(Q-002) rather than hidden.

## Traps carried forward

- **Needles unique within their region.** `b9-4`'s `client-only` needle was correctly
  scoped and still survived a mutation, because the word recurred. Every needle here is
  a full class declaration or a full call, and the probe checks it.
- **Run each harness the way CI runs it.** `b9-2` takes `--level 1`; nine other entries
  take no argument at all and exit 2 if given one.
- **No pipe into an early-exiting reader.** Here-strings and process substitution only.
